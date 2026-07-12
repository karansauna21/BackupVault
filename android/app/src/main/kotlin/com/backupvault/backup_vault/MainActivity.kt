package com.backupvault.backup_vault

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.wifi.WifiManager
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.backupvault.backup_vault/storage"
    private val PICK_DIR_REQUEST_CODE = 4122
    private val MANAGE_STORAGE_REQUEST_CODE = 4123
    private val RUNTIME_PERMISSIONS_REQUEST_CODE = 4124
    
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifi.createMulticastLock("BackupVaultMulticastLock").apply {
                setReferenceCounted(true)
                acquire()
            }
        } catch (e: Exception) {
            // Safe ignore
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            multicastLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (e: Exception) {
            // Safe ignore
        }
    }
    
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    pendingResult = result
                    val initialUriString = call.argument<String>("initialUri")
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    if (initialUriString != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val initialUri = Uri.parse(initialUriString)
                            intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
                        } catch (e: Exception) {
                            // Safe ignore
                        }
                    }
                    startActivityForResult(intent, PICK_DIR_REQUEST_CODE)
                }
                "hasStoragePermission" -> {
                    result.success(hasStoragePermission())
                }
                "requestStoragePermission" -> {
                    pendingResult = result
                    requestStoragePermission()
                }
                "resolvePath" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val uri = Uri.parse(uriString)
                        val resolved = resolveTreeUriToPath(uri)
                        result.success(resolved)
                    } else {
                        result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    }
                }
                "hasPermission" -> {
                    val perm = call.argument<String>("permission")
                    if (perm != null) {
                        result.success(hasPermission(perm))
                    } else {
                        result.error("INVALID_ARGUMENT", "Permission cannot be null", null)
                    }
                }
                "requestPermission" -> {
                    val perm = call.argument<String>("permission")
                    if (perm != null) {
                        pendingResult = result
                        requestPermission(perm)
                    } else {
                        result.error("INVALID_ARGUMENT", "Permission cannot be null", null)
                    }
                }
                "isUriPermissionPersisted" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        result.success(isUriPermissionPersisted(uriString))
                    } else {
                        result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    }
                }
                "getPersistedUriPermissions" -> {
                    val list = contentResolver.persistedUriPermissions.map { it.uri.toString() }
                    result.success(list)
                }
                "getStorageVolumes" -> {
                    result.success(getStorageVolumesInfo())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            val readPerm = checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
            val writePerm = checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            readPerm == PackageManager.PERMISSION_GRANTED && writePerm == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivityForResult(intent, MANAGE_STORAGE_REQUEST_CODE)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                startActivityForResult(intent, MANAGE_STORAGE_REQUEST_CODE)
            }
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestPermissions(
                    arrayOf(
                        Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE
                    ),
                    RUNTIME_PERMISSIONS_REQUEST_CODE
                )
            } else {
                pendingResult?.success(true)
                pendingResult = null
            }
        }
    }

    private fun getAndroidPermissionString(permissionName: String): String? {
        return when (permissionName) {
            "readMediaImages" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.READ_MEDIA_IMAGES else null
            "readMediaVideo" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.READ_MEDIA_VIDEO else null
            "readMediaAudio" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.READ_MEDIA_AUDIO else null
            "postNotifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.POST_NOTIFICATIONS else null
            "foregroundService" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) Manifest.permission.FOREGROUND_SERVICE else null
            else -> null
        }
    }

    private fun hasPermission(permissionName: String): Boolean {
        if (permissionName == "storage") {
            return hasStoragePermission()
        }
        val androidPerm = getAndroidPermissionString(permissionName)
        return if (androidPerm != null) {
            checkSelfPermission(androidPerm) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestPermission(permissionName: String) {
        if (permissionName == "storage") {
            requestStoragePermission()
            return
        }
        val androidPerm = getAndroidPermissionString(permissionName)
        if (androidPerm != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestPermissions(arrayOf(androidPerm), RUNTIME_PERMISSIONS_REQUEST_CODE)
            } else {
                pendingResult?.success(true)
                pendingResult = null
            }
        } else {
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    private fun isUriPermissionPersisted(uriString: String): Boolean {
        try {
            val uri = Uri.parse(uriString)
            val persistedUriPermissions = contentResolver.persistedUriPermissions
            for (permission in persistedUriPermissions) {
                if (permission.uri == uri && permission.isReadPermission) {
                    return true
                }
            }
        } catch (e: Exception) {
            // ignore
        }
        return false
    }

    private fun getStorageVolumesInfo(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        
        // Primary external storage (Internal Storage)
        val internalDir = Environment.getExternalStorageDirectory()
        val internalTotal = internalDir.totalSpace
        val internalFree = internalDir.freeSpace
        list.add(mapOf(
            "name" to "Internal Storage",
            "uuid" to "primary",
            "path" to internalDir.absolutePath,
            "isPrimary" to true,
            "totalSpace" to internalTotal,
            "freeSpace" to internalFree
        ))

        // Query other volumes
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val sm = getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            if (sm != null) {
                for (volume in sm.storageVolumes) {
                    val uuid = volume.uuid
                    if (uuid != null) {
                        val volumeName = volume.getDescription(this) ?: "SD Card"
                        var totalSpace: Long = 0
                        var freeSpace: Long = 0
                        var path = ""
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            volume.directory?.let { dir ->
                                totalSpace = dir.totalSpace
                                freeSpace = dir.freeSpace
                                path = dir.absolutePath
                            }
                        } else {
                            try {
                                val getPathMethod = volume.javaClass.getMethod("getPath")
                                val pathStr = getPathMethod.invoke(volume) as? String
                                if (pathStr != null) {
                                    val dir = File(pathStr)
                                    totalSpace = dir.totalSpace
                                    freeSpace = dir.freeSpace
                                    path = pathStr
                                }
                            } catch (e: Exception) {
                                // fallback
                            }
                        }
                        
                        list.add(mapOf(
                            "name" to volumeName,
                            "uuid" to uuid,
                            "path" to path,
                            "isPrimary" to false,
                            "totalSpace" to totalSpace,
                            "freeSpace" to freeSpace
                        ))
                    }
                }
            }
        } else {
            try {
                val files = getExternalFilesDirs(null)
                for (f in files) {
                    if (f != null && !Environment.isExternalStorageEmulated(f)) {
                        val path = f.absolutePath.split("/Android/data")[0]
                        val dir = File(path)
                        if (dir.exists()) {
                            val name = if (path.contains("emulated")) "Internal Storage" else "SD Card"
                            val uuid = if (path.contains("emulated")) "primary" else path.split("/").last()
                            list.add(mapOf(
                                "name" to name,
                                "uuid" to uuid,
                                "path" to path,
                                "isPrimary" to false,
                                "totalSpace" to dir.totalSpace,
                                "freeSpace" to dir.freeSpace
                            ))
                        }
                    }
                }
            } catch (e: Exception) {
                // ignore
            }
        }
        return list
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RUNTIME_PERMISSIONS_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(granted)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_DIR_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                    } catch (e: Exception) {
                        // ignore
                    }
                    
                    val resolvedPath = resolveTreeUriToPath(uri)
                    val resultData = mapOf(
                        "uri" to uri.toString(),
                        "path" to (resolvedPath ?: "")
                    )
                    pendingResult?.success(resultData)
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        } else if (requestCode == MANAGE_STORAGE_REQUEST_CODE) {
            pendingResult?.success(hasStoragePermission())
            pendingResult = null
        }
    }

    private fun resolveTreeUriToPath(uri: Uri): String? {
        try {
            val treeId = DocumentsContract.getTreeDocumentId(uri) ?: return null
            val split = treeId.split(":")
            if (split.isEmpty()) return null
            val type = split[0]
            val relativePath = if (split.size > 1) split[1] else ""

            return if ("primary".equals(type, ignoreCase = true)) {
                val base = Environment.getExternalStorageDirectory().toString()
                if (relativePath.isNotEmpty()) "$base/$relativePath" else base
            } else {
                val base = "/storage/$type"
                val path = if (relativePath.isNotEmpty()) "$base/$relativePath" else base
                if (File(path).exists()) {
                    path
                } else {
                    val storageDir = File("/storage")
                    if (storageDir.exists() && storageDir.isDirectory) {
                        val files = storageDir.listFiles()
                        if (files != null) {
                            for (file in files) {
                                if (file.name.equals(type, ignoreCase = true)) {
                                    return if (relativePath.isNotEmpty()) "${file.absolutePath}/$relativePath" else file.absolutePath
                                }
                            }
                        }
                    }
                    path
                }
            }
        } catch (e: Exception) {
            return null
        }
    }
}
