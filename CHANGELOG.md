# Changelog

All notable changes to the BackupVault project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-07-05

### Added
- **Core Engine**: Implemented robust file backup and restore orchestration engines.
- **SQLite Database**: Integrated Drift database schema, caching metadata, paths, files, and rules.
- **Smart Scheduler**: Added periodic interval schedules and custom cron expression parsing.
- **Event Watchdogs**: Added automated directory changes, Windows startup/shutdown hooks, and USB attachment triggers.
- **Zero-Knowledge Security**: Optional file encryption using AES-256-GCM ciphers.
- **Area locks**: Restricted settings, exports, and recovery options behind master passwords.
- **Diagnostics**: Built live resource monitors (CPU, RAM, Disk I/O) and database query speed testers.
- **Stress Benchmarks**: Implemented custom read/write stress testing payload benchmarks.
- **Self-Healing Recovery**: Crash detector lock checks and automated sqlite restoration validator.
- **Config Migration**: Settings JSON export/import packaging and database schema migrations.
- **Release Packaging**: Portable build support and automated Windows Inno Setup script creation.
- **CI/CD Pipeline**: Configured GitHub Actions lint check, test automation, and draft releases.
