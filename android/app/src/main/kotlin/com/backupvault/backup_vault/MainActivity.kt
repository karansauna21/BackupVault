package com.backupvault.backup_vault

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.backupvault.backup_vault/storage"
    private val PICK_DIR_REQUEST_CODE = 4122
    private val MANAGE_STORAGE_REQUEST_CODE = 4123
    private val RUNTIME_PERMISSIONS_REQUEST_CODE = 4124
    
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    startActivityForResult(intent, PICK_DIR_REQUEST_CODE)
                }
                "hasStoragePermission" -> {
                    result.success(hasStoragePermission())
                }
                "requestStoragePermission" -> {
                    pendingResult = result
                    requestStoragePermission()
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
            val readPerm = checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE)
            val writePerm = checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
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
                        android.Manifest.permission.READ_EXTERNAL_STORAGE,
                        android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                    ),
                    RUNTIME_PERMISSIONS_REQUEST_CODE
                )
            } else {
                pendingResult?.success(true)
                pendingResult = null
            }
        }
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
                        // Safe ignore if take permission fails (e.g. not persistable uri)
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
