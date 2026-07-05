# BackupVault User & Operation Manual

Welcome to BackupVault! This manual guides you through setting up, configuring, and operating BackupVault to secure your folders and files.

---

## 1. Installation & Setup

### 1.1 Windows
- **Installed Version**: Run the Inno Setup installer executable (`backup-vault-installer.exe`) and follow the configuration wizard.
- **Portable Version**: Extract the portable zip archive into any directory. BackupVault will run entirely within this local environment (settings are saved to local project files).

### 1.2 Android
- Download and install the release APK on your Android device (ensure "Install from unknown sources" is enabled in settings).

---

## 2. Quick Start: Your First Backup

1. **Launch BackupVault**.
2. Navigate to the **Folder Manager** page from the sidebar menu.
3. Click **Add Folder** to track a directory.
4. Set the **Source Path** (what to copy) and **Destination Path** (where to copy backup archives).
5. Click **Create Folder**.
6. On the Dashboard tab, click **Run Backup** to copy files immediately.

---

## 3. Configuring Auto-Schedules

BackupVault includes a robust scheduler:
1. Navigate to the **Scheduler** page.
2. Select your folder profile.
3. Choose a **Trigger Type**:
   - **Specific Time / Interval**: Run every minute, hourly, daily, or using a custom Cron expression.
   - **Event-Driven**: Run when a USB drive is plugged in, when the application starts, or when files in a watched folder change.
4. Click **Apply Schedule**.

---

## 4. Encryption & Security Lock

To secure your backup data:
1. Go to the **Security** page.
2. Click **Generate New Key** (or import an existing key package).
3. Toggle **Enable File Encryption** to encrypt all future backups using AES-256-GCM.
4. Set a **Password Lock** to require credentials before accessing settings, security configurations, or restoring files.
5. Export your encryption keys and store them in a safe place. **If you lose your keys, you cannot restore encrypted files.**

---

## 5. System Health & Performance

Monitor BackupVault's resource consumption:
1. Go to the **Diagnostics** page.
2. View real-time **CPU**, **RAM**, and **Disk I/O** indicators.
3. Run the **Stress & Benchmark** test to measure your drive's read/write speed under load.
4. If an unexpected crash occurs (e.g. system power outage), the app will detect the crash on startup and prompt you to run its self-healing database recovery checks.
