package com.backupvault.backup_vault

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class BackupForegroundService : Service() {
    private var flutterEngine: FlutterEngine? = null

    companion object {
        const val CHANNEL_ID = "BackupVault_Background_Service"
        const val NOTIFICATION_ID = 8821
        var isRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        val notification = createNotification("BackupVault service is running")
        startForeground(NOTIFICATION_ID, notification)

        if (flutterEngine == null) {
            val cached = FlutterEngineCache.getInstance().get("backup_vault_engine")
            if (cached != null) {
                flutterEngine = cached
            } else {
                val engine = FlutterEngine(this)
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                // Register plugins on manual instantiation
                io.flutter.plugins.GeneratedPluginRegistrant.registerWith(engine)
                FlutterEngineCache.getInstance().put("backup_vault_engine", engine)
                flutterEngine = engine
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val message = intent?.getStringExtra("message") ?: "Auto backup active"
        val notification = createNotification(message)
        val mNotificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mNotificationManager.notify(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        // Avoid destroying engine if the app is still active, but if it is standalone we can clean it up
        val cached = FlutterEngineCache.getInstance().get("backup_vault_engine")
        if (cached == flutterEngine) {
            FlutterEngineCache.getInstance().remove("backup_vault_engine")
            flutterEngine?.destroy()
        }
        flutterEngine = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "BackupVault Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps BackupVault running in background for real-time backup"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(message: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BackupVault Auto Backup")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_menu_save)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
