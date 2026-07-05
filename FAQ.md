# BackupVault Frequently Asked Questions (FAQ)

Here are the most common questions and troubleshooting steps for BackupVault.

---

### Q1: Where does BackupVault store application settings and metadata?
- **Installed Windows Version**: In `%APPDATA%/backup_vault/`.
- **Portable Windows Version**: In a local `.backup_vault_portable` subfolder in the same directory as the executable.
- **Android**: In the application's secure isolated sandbox database directory.

---

### Q2: What encryption standard is used for secure backups?
BackupVault uses industry-standard **AES-256-GCM** (authenticated encryption) via cryptographic key blocks. Key generation and hashing are performed locally on your device.

---

### Q3: I lost my master password. How can I reset it?
If you set a password hint on the **Security** page, you can reveal the hint on the lock screen. Otherwise, for security reasons, there is no master backdoor. You must delete the local database configuration file to reset the app (note: this will clear application settings but will *not* delete your backed-up files).

---

### Q4: Can I run custom scheduling routines?
Yes. The scheduling engine supports **standard Cron expressions** (e.g., `0 12 * * 1-5` for weekdays at noon). Enter your cron query in the custom schedule field on the **Scheduler** page.

---

### Q5: How do I backup my BackupVault configurations when moving to a new computer?
1. Go to the **Configuration** page.
2. Select the items you want to export (Settings, Folder Config, Automation Rules, Schedules).
3. Click **Export Configuration Package** to save a JSON configuration file.
4. On your new computer, install BackupVault and click **Import Configuration Package** to restore all settings.

---

### Q6: Does BackupVault support incremental backups?
Yes. The backup engine automatically calculates SHA-256 checksums of files and compares modified timestamps. It only copies files that have changed since the last backup run, reducing disk I/O and saving storage space.
