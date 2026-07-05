# BackupVault Developer & Engineering Guide

This guide is designed to help developers understand the architectural codebase, state management flow, and dependency structure of the BackupVault application.

---

## 1. Directory Structure Layout

The project follows a feature-first architectural pattern:

```text
lib/
├── core/
│   ├── database/       # Drift SQLite database definition & providers
│   ├── restore/        # File restoration engine & validation logic
│   └── services/       # File watchers, background tasks, logging, backup engine
├── features/
│   ├── background/     # Native Windows Tray service daemon controllers
│   ├── configuration/  # Export/Import setting backups & db migrations
│   ├── dashboard/      # Main application presentation statistics view
│   ├── diagnostics/    # Live monitors, CPU/RAM charts, write/read benchmarks
│   ├── folder_manager/ # Watched path directory selectors & configuration
│   ├── logs/           # Application logging view
│   ├── notifications/  # Notification history, DND scheduler
│   ├── release/        # Release manifests, versions, Inno Setup script compiler
│   ├── scheduler/      # Cron schedules, USB/folder watcher triggers
│   ├── security/       # Zero-knowledge AES ciphers, key managers, area locks
│   └── statistics/     # Analytics visual charts (files count, storage size)
```

---

## 2. State Management System

BackupVault utilizes **Riverpod** for state injection and reactive controller hooks.

### 2.1 Pattern Structure
Each module generally includes:
1. **Model** (`*_models.dart`): Immutable data representations.
2. **Repository** (`*_repository.dart`): Direct access to DB operations or filesystem.
3. **Provider** (`*_provider.dart`): StateNotifierProviders exposing controllers.
4. **Controller** (`*_controller.dart`): Handles async business logic and side effects.
5. **Screen** (`*_screen.dart`): UI elements.

---

## 3. Database Migration Procedures

SQLite migrations are managed through Drift's schema versioning.
If you update database tables in `lib/core/database/app_database.dart`:
1. Increment `schemaVersion` in `AppDatabase`.
2. Generate Drift binding files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Implement the migration path inside `MigrationManager` (`lib/features/configuration/migration_manager.dart`).

---

## 4. Diagnostic Stress Benchmarks

The benchmark system (`lib/features/diagnostics/benchmark_service.dart`) writes temporary test payload files to standard temp OS directories.
If you need to tweak stress thresholds:
- Modify `batchSize` limits.
- Update `payloadSize` multipliers for high-volume disk speed tests.
- Guard I/O blocks using appropriate file handles cleanups inside `finally` blocks.
