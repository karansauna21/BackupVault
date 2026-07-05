# Contributing to BackupVault

First off, thank you for taking the time to contribute! We welcome developers, testers, designers, and documentation writers to help make BackupVault the best open-source backup tool.

The following guidelines outline how to build, test, and submit your code modifications successfully.

---

## 1. Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

---

## 2. Setting Up Your Development Environment

Ensure you have the following prerequisites installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.x or later stable)
- Dart SDK (included in Flutter)
- Windows development tools (Visual Studio with "Desktop development with C++" workload)
- Android Studio / Android SDK (for compiling Android packages)

### Step-by-Step Setup
1. Fork the BackupVault repository and clone it locally:
   ```bash
   git clone https://github.com/your-username/BackupVault.git
   cd BackupVault
   ```
2. Pull required flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Generate DRIFT database database binders (if applicable):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the development server or application:
   ```bash
   flutter run
   ```

---

## 3. Code Standards & Quality Checks

We enforce clean, readable code. Please run the following command suites before submitting any pull requests:

### 3.1 Dart Format
All files must be formatted according to the standard Dart style guide:
```bash
dart format .
```

### 3.2 Flutter Analyze
Ensure there are no compile warnings, lint issues, or deprecations:
```bash
flutter analyze
```

### 3.3 Running Tests
Ensure the entire test suite passes:
```bash
flutter test
```

---

## 4. Submitting a Pull Request (PR)

1. Create a descriptive feature branch from `dev`:
   ```bash
   git checkout -b feature/awesome-backup-scheduler
   ```
2. Make your edits, adhering to test coverage guidelines.
3. Commit with semantic, clear messages:
   ```bash
   git commit -m "feat(scheduler): implement real-time trigger watchdogs"
   ```
4. Push to your fork:
   ```bash
   git push origin feature/awesome-backup-scheduler
   ```
5. Open a Pull Request targeting the base `dev` branch using our Pull Request Template.
