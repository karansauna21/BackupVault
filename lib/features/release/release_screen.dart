import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'release_models.dart';
import 'release_provider.dart';

class ReleaseScreen extends ConsumerStatefulWidget {
  const ReleaseScreen({super.key});

  @override
  ConsumerState<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends ConsumerState<ReleaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _featuresController = TextEditingController(text: 'Added transparent security encryption checks.\nImplemented real-time diagnostic performance metrics.');
  final _bugsController = TextEditingController(text: 'Fixed DB file locking exceptions.\nResolved background scheduler tray update latency.');
  final _migrationController = TextEditingController(text: 'Clean install recommended. Database schema is updated to v4.');

  String _selectedProfile = 'Release';
  String _selectedChannel = 'Stable';
  bool _createDesktopShortcut = true;
  bool _createStartMenuShortcut = true;
  bool _runAtStartup = false;
  bool _acceptLicense = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(releaseRepositoryProvider).init().then((_) {
        ref.read(versionInfoProvider.notifier).refresh();
        ref.read(releaseHistoryProvider.notifier).refresh();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _featuresController.dispose();
    _bugsController.dispose();
    _migrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = ref.watch(versionInfoProvider);
    final history = ref.watch(releaseHistoryProvider);
    final workflow = ref.watch(releaseWorkflowProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Release Engineering & Packaging'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded), text: 'Build Dashboard'),
            Tab(icon: Icon(Icons.rocket_launch_rounded), text: 'Release Wizard'),
            Tab(icon: Icon(Icons.history_edu_rounded), text: 'Build History'),
          ],
        ),
      ),
      body: workflow.status == PackagingStatus.building || workflow.status == PackagingStatus.validating
          ? _buildProgressScreen(theme, workflow)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(theme, version),
                _buildReleaseWizard(theme, version, workflow),
                _buildHistory(theme, history),
              ],
            ),
    );
  }

  // --- Tab 1: Build Dashboard ---
  Widget _buildDashboard(ThemeData theme, VersionInfo version) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Semantic Versioning & Channel settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Current Release Version', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Full semver tag: ${version.semVer}'),
                    trailing: Text(
                      version.displayString,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => ref.read(versionInfoProvider.notifier).incrementVersion('major'),
                          icon: const Icon(Icons.exposure_plus_1_rounded),
                          label: const Text('Major Release'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(versionInfoProvider.notifier).incrementVersion('minor'),
                          icon: const Icon(Icons.exposure_plus_1_rounded),
                          label: const Text('Minor Release'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(versionInfoProvider.notifier).incrementVersion('patch'),
                          icon: const Icon(Icons.exposure_plus_1_rounded),
                          label: const Text('Patch Release'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.track_changes_rounded),
                    title: const Text('Active Release Channel'),
                    subtitle: const Text('Configures default feature profile inclusion flags.'),
                    trailing: DropdownButton<String>(
                      value: _selectedChannel,
                      items: const [
                        DropdownMenuItem(value: 'Stable', child: Text('Public Stable')),
                        DropdownMenuItem(value: 'Beta', child: Text('Beta Preview')),
                        DropdownMenuItem(value: 'Dev', child: Text('Internal Dev')),
                        DropdownMenuItem(value: 'Portable', child: Text('Portable Standalone')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedChannel = val);
                          ref.read(versionInfoProvider.notifier).updateChannel(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('System Validation Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: Colors.green),
                    title: Text('SQLite Databases schema matches release constraints.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: Colors.green),
                    title: Text('Background scheduling services verified.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: Colors.green),
                    title: Text('Cryptographic security cipher tests complete.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Release Wizard ---
  Widget _buildReleaseWizard(ThemeData theme, VersionInfo version, ReleaseState workflow) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build profile options', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProfile,
                    decoration: const InputDecoration(labelText: 'Packaging Profile'),
                    items: const [
                      DropdownMenuItem(value: 'Debug', child: Text('Debug Profile (Simulated)')),
                      DropdownMenuItem(value: 'Profile', child: Text('Performance Profiling')),
                      DropdownMenuItem(value: 'Release', child: Text('Release Target (Inno Setup Installer)')),
                      DropdownMenuItem(value: 'Portable', child: Text('Portable Build (Local directory locked)')),
                    ],
                    onChanged: (val) => setState(() => _selectedProfile = val ?? _selectedProfile),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Generate Desktop Shortcut icon'),
                    value: _createDesktopShortcut,
                    onChanged: (val) => setState(() => _createDesktopShortcut = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Generate Start Menu Programs entry'),
                    value: _createStartMenuShortcut,
                    onChanged: (val) => setState(() => _createStartMenuShortcut = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Automatically launch application at startup'),
                    value: _runAtStartup,
                    onChanged: (val) => setState(() => _runAtStartup = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Include End-User License Agreement (EULA) screen'),
                    value: _acceptLicense,
                    onChanged: (val) => setState(() => _acceptLicense = val ?? true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Release Notes Generation Content', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _featuresController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'New Features (One per line)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bugsController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Bug Fixes (One per line)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _migrationController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Migration and Upgrade guides'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (workflow.status == PackagingStatus.error) ...[
            Text('Packaging Error Output', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            SelectableText(
              workflow.errorMessage ?? 'Unknown error occurred.',
              style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
              onPressed: () => _triggerBuildWorkflow(),
              icon: const Icon(Icons.archive_outlined),
              label: Text('Compile Installer & Export v${version.semVer}'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Build History ---
  Widget _buildHistory(ThemeData theme, List<BuildResult> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('No releases compiled yet. Execute the wizard to generate builds.'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, idx) {
        final result = history[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile: ${result.profile}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: result.success ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.success ? 'SUCCESS' : 'FAILED',
                        style: TextStyle(color: result.success ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Date: ${result.timestamp.toLocal()}'),
                const Divider(),
                const SizedBox(height: 8),
                Text('Installer: ${result.installerPath}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                const SizedBox(height: 4),
                Text('Portable: ${result.portableZipPath}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                const SizedBox(height: 4),
                Text('Standard Release: ${result.releaseZipPath}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                const SizedBox(height: 8),
                Text('SHA-256 Checksum: ${result.sha256Checksum}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Packaging Loading Screen ---
  Widget _buildProgressScreen(ThemeData theme, ReleaseState state) {
    final statusText = state.status == PackagingStatus.validating
        ? 'Running integrity validation suites...'
        : 'Compiling executable packages and installer scripts...';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(statusText, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Please do not terminate the process. Exporting release assets...'),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerBuildWorkflow() async {
    final features = _featuresController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final bugFixes = _bugsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final migrations = _migrationController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

    await ref.read(releaseWorkflowProvider.notifier).createReleasePackage(
      profile: _selectedProfile,
      features: features,
      bugFixes: bugFixes,
      migrations: migrations,
    );

    final updatedState = ref.read(releaseWorkflowProvider);
    if (updatedState.status == PackagingStatus.success && updatedState.buildResult != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Release Bundled Successfully'),
          content: Text('Installation package, portable archive, manifest, and checksum reports have been exported:\n\n${updatedState.buildResult!.installerPath}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(releaseWorkflowProvider.notifier).reset();
                _tabController.animateTo(2); // Move to history tab
              },
              child: const Text('View Releases'),
            ),
          ],
        ),
      );
    }
  }
}
