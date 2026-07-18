package com.backupvault.backup_vault

import android.os.Build
import android.os.FileObserver
import android.util.Log
import java.io.File
import java.util.concurrent.ConcurrentHashMap

class RecursiveFileObserver(
    val rootPath: String,
    val folderId: Int,
    private val onEvent: (type: String, path: String, destinationPath: String?, isDir: Boolean) -> Unit
) {
    private val observers = ConcurrentHashMap<String, SingleObserver>()
    private var lastMovedFromPath: String? = null
    private var lastMovedFromTime: Long = 0

    init {
        startWatching()
    }

    fun startWatching() {
        watchRecursive(File(rootPath))
    }

    fun stopWatching() {
        for (observer in observers.values) {
            observer.stopWatching()
        }
        observers.clear()
    }

    private fun watchRecursive(dir: File) {
        if (!dir.exists() || !dir.isDirectory) return
        val path = dir.absolutePath
        if (observers.containsKey(path)) return

        try {
            val observer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                SingleObserver(dir)
            } else {
                SingleObserver(path)
            }
            observer.startWatching()
            observers[path] = observer

            val files = dir.listFiles()
            if (files != null) {
                for (file in files) {
                    if (file.isDirectory) {
                        watchRecursive(file)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("RecursiveFileObserver", "Error watching $path: ${e.message}")
        }
    }

    inner class SingleObserver : FileObserver {
        private val dirPath: String

        @Suppress("DEPRECATION")
        constructor(path: String) : super(path, CREATE or MODIFY or DELETE or MOVED_FROM or MOVED_TO) {
            this.dirPath = path
        }

        constructor(file: File) : super(file, CREATE or MODIFY or DELETE or MOVED_FROM or MOVED_TO) {
            this.dirPath = file.absolutePath
        }

        override fun onEvent(event: Int, path: String?) {
            if (path == null) return
            val fullPath = File(dirPath, path).absolutePath
            val mask = event and ALL_EVENTS
            
            // Check if it's a directory
            var isDir = File(fullPath).isDirectory
            
            when (mask) {
                CREATE -> {
                    if (isDir) {
                        watchRecursive(File(fullPath))
                        onEvent("folderCreated", fullPath, null, true)
                    } else {
                        onEvent("newFile", fullPath, null, false)
                    }
                }
                MODIFY -> {
                    if (!isDir) {
                        onEvent("modifiedFile", fullPath, null, false)
                    }
                }
                DELETE -> {
                    val removed = observers.remove(fullPath)
                    removed?.stopWatching()
                    val wasDir = removed != null
                    if (wasDir) {
                        onEvent("folderDeleted", fullPath, null, true)
                    } else {
                        onEvent("deletedFile", fullPath, null, false)
                    }
                }
                MOVED_FROM -> {
                    lastMovedFromPath = fullPath
                    lastMovedFromTime = System.currentTimeMillis()
                }
                MOVED_TO -> {
                    val prevPath = lastMovedFromPath
                    val timeDiff = System.currentTimeMillis() - lastMovedFromTime
                    if (prevPath != null && timeDiff < 200) {
                        if (isDir) {
                            watchRecursive(File(fullPath))
                            onEvent("folderMoved", prevPath, fullPath, true)
                        } else {
                            onEvent("movedFile", prevPath, fullPath, false)
                        }
                    } else {
                        if (isDir) {
                            watchRecursive(File(fullPath))
                            onEvent("folderCreated", fullPath, null, true)
                        } else {
                            onEvent("newFile", fullPath, null, false)
                        }
                    }
                    lastMovedFromPath = null
                }
            }
        }
    }
}
