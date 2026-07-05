# BackupVault Product Roadmap

This document outlines the planned developmental path for BackupVault, detailing completed achievements and upcoming milestones.

---

## Milestone 1: Core Backup & SQLite Engine (Completed)
- [x] High-performance chunked file copying.
- [x] SQLite integration via Drift ORM database layer.
- [x] Folder Manager dashboard interface (CRUD).
- [x] Notification Center alerts (DND, Priority logs).

## Milestone 2: Smart Scheduler & Background Services (Completed)
- [x] Windows Tray and System Tray notifications.
- [x] Periodic Cron scheduling and filesystem watcher trigger hooks.
- [x] External USB/Removable Storage automatic device backup trigger.
- [x] Background Daemon queue resilience surviving computer restart events.

## Milestone 3: Security & Self-Diagnostics (Completed)
- [x] Zero-knowledge optional AES-256-GCM file encryption.
- [x] Cryptographic key import/export profiles.
- [x] Password locks protecting critical panels.
- [x] Automated sqlite integrity audits and self-healing DB recovery.
- [x] Live stress benchmark performance analyser tool.

## Milestone 4: Production Release & CI/CD (Current)
- [x] Windows portable and Inno Setup installer generator scripts.
- [x] Android release APK compilation pipeline.
- [x] Automated lint, analyze, format, and unit test suites on GitHub Actions.
- [x] Open-source documentation packages.

## Milestone 5: Remote Cloud & Network Integrations (Future)
- [ ] Network Attached Storage (NAS) support via SMB/SFTP protocols.
- [ ] S3-Compatible Cloud Storage integration (AWS S3, Backblaze B2, Wasabi).
- [ ] WebDAV remote mount support.
- [ ] Compression ratios configuration (Gzip, Brotli, Zstd).
