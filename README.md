# BackupVault

[![Flutter CI](https://github.com/BackupVault/BackupVault/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/BackupVault/BackupVault/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release Version](https://img.shields.io/badge/Release-v1.0.0-blue.svg)](https://github.com/BackupVault/BackupVault/releases)

BackupVault is an enterprise-grade, secure, and cross-platform backup automation application designed to safeguard your local folder and file systems. Built on Flutter, BackupVault offers optional zero-knowledge encryption, scheduled automation, real-time file system watchdogs, system health monitoring, and self-healing recovery systems.

---

## Features

- ⚙️ **Smart Scheduler & Automation**: Schedule backups using standard intervals (Hourly, Daily, Weekly, Monthly) or custom Cron expressions.
- 🔌 **Removable Storage Trigger**: Automatically initiate backups when a designated USB or external hard drive is connected.
- 🔒 **Zero-Knowledge Encryption**: Secure files with optional AES-256-GCM authenticated encryption. Your keys, your data.
- 🛡️ **Area Security Locks**: Protect settings, restoration interfaces, and configuration exports behind a master password gate.
- 📊 **Self-Diagnostics**: Live monitors tracking CPU, RAM, Disk I/O speed, and database latency.
- ⚡ **Stress Benchmarks**: Built-in benchmark suite to evaluate your storage drive write/read speeds under load.
- 🩹 **Self-Healing Recovery**: Automated database validation and restoration from shadow copies in case of unexpected crashes.
- ✈️ **Config Import/Export**: Bundle settings, rules, and schedules (excluding files) into a signed package for migration.
- 📦 **Packaging & Portability**: Build portable zero-install versions or compile setup installers for Windows via Inno Setup.

---

## Requirements

### Windows
- **OS**: Windows 10 (1607+) / 11
- **Architecture**: x86_64 or ARM64

### Android
- **OS**: Android 8.0 (API 26) or newer

---

## Quick Start

1. **Add a Watched Directory**: Navigate to the **Folder Manager** page, choose your source folder and destination backup directory, and click **Create Folder**.
2. **Execute Backup**: Go to the **Dashboard** page and click **Run Backup** to start the sync instantly.
3. **Automate**: Open the **Scheduler** page to link folders to timer intervals or USB attachment triggers.
4. **Encrypt**: Under the **Security** tab, generate an encryption key and check **Enable File Encryption**.

---

## Folder Structure

```text
BackupVault/
├── .github/              # Issue templates, PR templates, and CI/CD GitHub Actions
├── assets/               # Application icons, fonts, and theme configs
├── lib/
│   ├── core/             # Relational SQLite database, restoration engine, copy engine
│   └── features/         # Diagnostics, Security, Release, Scheduler modules
├── test/                 # 100+ comprehensive unit, widget, and mock integration tests
└── windows/ & android/   # Native platform runner configs
```

---

## Architecture Overview

BackupVault separates responsibilities into clear domains. Drift provides the SQLite storage context, Riverpod handles state bindings, and custom services isolate I/O tasks:

- **Presentation**: Flutter UI responding to state changes.
- **Controllers**: Riverpod `StateNotifier` classes controlling async UI updates.
- **Engine Core**: Native Dart file management, hashing (SHA-256), and encryption (AES-256-GCM).
- **Diagnostics**: Platform-specific performance metric trackers.

For full architectural blueprints, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Compilation & Building

### Prerequisites
- Install [Flutter SDK (v3.22.x stable)](https://docs.flutter.dev/get-started/install)
- Ensure desktop workload dependencies are installed (e.g. Visual Studio with C++ tools for Windows development).

### Windows Build
To build a release binary:
```bash
flutter config --enable-windows-desktop
flutter build windows --release
```
To bundle a portable zip package:
```powershell
Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath build\windows\x64\runner\backup-vault-windows-portable.zip
```

### Android Build
To build a release APK package:
```bash
flutter build apk --release
```

---

## Documentation Index

- [Architecture Design](ARCHITECTURE.md)
- [Developer Guide](DEVELOPER_GUIDE.md)
- [User Guide](USER_GUIDE.md)
- [Frequently Asked Questions (FAQ)](FAQ.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

---

## Troubleshooting & FAQ

Refer to the [FAQ.md](FAQ.md) for solutions to common configuration problems, key management questions, and system recovery procedures.

---

## License

BackupVault is licensed under the [MIT License](LICENSE).

---

## Contributing

We welcome contributions from the community! Please read [CONTRIBUTING.md](CONTRIBUTING.md) to learn how to get involved.

---

## Acknowledgements

- **Drift**: For outstanding SQLite bindings.
- **Riverpod**: For reactive and testable state management.
- **Inno Setup**: For reliable Windows installer generation.
