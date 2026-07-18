package com.backupvault.backup_vault

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap

object EngineManager {
    private const val WATCHER_CHANNEL = "com.backupvault.backup_vault/file_watcher"
    private const val SERVICE_CHANNEL = "com.backupvault.backup_vault/foreground_service"
    
    private val watchers = ConcurrentHashMap<Int, RecursiveFileObserver>()
    private var methodChannel: MethodChannel? = null

    fun init(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, WATCHER_CHANNEL)
        methodChannel = channel
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startWatching" -> {
                    val path = call.argument<String>("path")
                    val folderId = call.argument<Int>("folderId")
                    if (path != null && folderId != null) {
                        try {
                            watchers[folderId]?.stopWatching()
                            
                            val observer = RecursiveFileObserver(path, folderId) { type, filePath, destPath, isDir ->
                                android.os.Handler(context.mainLooper).post {
                                    channel.invokeMethod(
                                        "onFileEvent",
                                        mapOf(
                                            "folderId" to folderId,
                                            "type" to type,
                                            "path" to filePath,
                                            "destinationPath" to destPath,
                                            "isDir" to isDir
                                        )
                                    )
                                }
                            }
                            watchers[folderId] = observer
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path or folderId is null", null)
                    }
                }
                "stopWatching" -> {
                    val folderId = call.argument<Int>("folderId")
                    if (folderId != null) {
                        watchers.remove(folderId)?.stopWatching()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "folderId is null", null)
                    }
                }
                "stopAll" -> {
                    for (watcher in watchers.values) {
                        watcher.stopWatching()
                    }
                    watchers.clear()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val serviceChannel = MethodChannel(messenger, SERVICE_CHANNEL)
        serviceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val message = call.argument<String>("message") ?: "Auto backup active"
                    val serviceIntent = Intent(context, BackupForegroundService::class.java).apply {
                        putExtra("message", message)
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_FAILED", e.message, null)
                    }
                }
                "stopService" -> {
                    val serviceIntent = Intent(context, BackupForegroundService::class.java)
                    context.stopService(serviceIntent)
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(BackupForegroundService.isRunning)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
