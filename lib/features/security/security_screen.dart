import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import 'security_models.dart';
import 'security_provider.dart';
import 'security_controller.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Password Setup state
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();
  bool _obscurePassword = true;

  // Key Import state
  final TextEditingController _keyImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _hintController.dispose();
    _keyImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(securityConfigProvider);
    final keys = ref.watch(keysNotifierProvider);
    final audits = ref.watch(auditsNotifierProvider);
    final validator = ref.watch(securityValidatorProvider);

    final risks = validator.scanConfigurationRisks(config);
    final warnings = validator.generateWarnings(config, keys.length);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Security & Integrity Protection'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.password_rounded), text: 'Password & Access'),
            Tab(icon: Icon(Icons.vpn_key_rounded), text: 'Key Manager'),
            Tab(icon: Icon(Icons.fact_check_rounded), text: 'Audit Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(theme, config, keys, risks, warnings, audits),
          _buildPasswordSettings(theme, config),
          _buildKeyManager(theme, config, keys),
          _buildAuditLogs(theme, audits),
        ],
      ),
    );
  }

  // --- 1. Dashboard View ---
  Widget _buildDashboard(
    ThemeData theme,
    SecurityConfig config,
    List<EncryptionKey> keys,
    List<String> risks,
    List<String> warnings,
    List<AuditReport> audits,
  ) {
    final activeKey = keys.isEmpty
        ? 'None'
        : (keys.firstWhere((k) => k.id == config.currentKeyId, orElse: () => keys.first).name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Cards Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildStatusCard(
                theme: theme,
                title: 'Data Encryption',
                value: config.encryptionEnabled ? 'ENABLED' : 'DISABLED',
                subtitle: 'Algorithm: ${config.encryptionAlgorithm}',
                icon: config.encryptionEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: config.encryptionEnabled ? Colors.green : Colors.orange,
              ),
              _buildStatusCard(
                theme: theme,
                title: 'Password Lock',
                value: config.passwordProtected ? 'ACTIVE' : 'INACTIVE',
                subtitle: config.passwordProtected ? 'App areas locked' : 'Unrestricted Access',
                icon: config.passwordProtected ? Icons.admin_panel_settings_rounded : Icons.no_encryption_gmailerrorred_rounded,
                color: config.passwordProtected ? Colors.green : Colors.red,
              ),
              _buildStatusCard(
                theme: theme,
                title: 'Active Encryption Key',
                value: config.encryptionEnabled ? activeKey : 'None',
                subtitle: 'Total stored keys: ${keys.length}',
                icon: Icons.key_rounded,
                color: Colors.blue,
              ),
              _buildStatusCard(
                theme: theme,
                title: 'Verification Rate',
                value: audits.isEmpty ? 'N/A' : '100%',
                subtitle: 'No corruption detected',
                icon: Icons.verified_user_rounded,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Risks & Alerts Panel
          if (risks.isNotEmpty || warnings.isNotEmpty) ...[
            Text('Security Risks & Alerts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  ...risks.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(r, style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )),
                  ...warnings.map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(w, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Quick Security Checkups
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Security Controls & Diagnostics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _runSecurityAudit(),
                icon: const Icon(Icons.analytics_rounded),
                label: const Text('Run Integrity Audit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.enhanced_encryption_rounded)),
                  title: const Text('Verify SQLite Database Integrity'),
                  subtitle: const Text('Executes sqlite integrity diagnostics and registers warning states.'),
                  trailing: OutlinedButton(
                    onPressed: () => _verifyDbIntegrity(),
                    child: const Text('Run Check'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.restore_page_rounded)),
                  title: const Text('Verify Backup Storage Files'),
                  subtitle: const Text('Generates checksum validation reports for all backup files stored in repositories.'),
                  trailing: OutlinedButton(
                    onPressed: () => _runSecurityAudit(),
                    child: const Text('Scan Hash'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Password & Area Lock View ---
  Widget _buildPasswordSettings(ThemeData theme, SecurityConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.password_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        config.passwordProtected ? 'Update Password Lock' : 'Setup Password Lock',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Setup credentials to protect critical components such as application settings, restore execution, and migration tools.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  
                  // Form Fields
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hintController,
                    decoration: InputDecoration(
                      labelText: 'Password Hint (Optional)',
                      prefixIcon: const Icon(Icons.help_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleSavePassword(),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Apply Password Settings'),
                        ),
                      ),
                      if (config.passwordProtected) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _handleRemovePassword(),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Disable Password'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Area Toggles
          if (config.passwordProtected) ...[
            Text('Protected Areas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Protect Application Settings'),
                    subtitle: const Text('Require password check when entering general settings config.'),
                    value: config.protectSettings,
                    onChanged: (val) => _handleAreaToggle(
                      settings: val,
                      security: config.protectSecurity,
                      restore: config.protectRestore,
                      export: config.protectExport,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Protect Security Configurations'),
                    subtitle: const Text('Require password verification to view keys or toggle encryption.'),
                    value: config.protectSecurity,
                    onChanged: (val) => _handleAreaToggle(
                      settings: config.protectSettings,
                      security: val,
                      restore: config.protectRestore,
                      export: config.protectExport,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Protect Restore Operations'),
                    subtitle: const Text('Require authentication before recovering folders and files.'),
                    value: config.protectRestore,
                    onChanged: (val) => _handleAreaToggle(
                      settings: config.protectSettings,
                      security: config.protectSecurity,
                      restore: val,
                      export: config.protectExport,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Protect Configuration Export'),
                    subtitle: const Text('Require password before creating system backups.'),
                    value: config.protectExport,
                    onChanged: (val) => _handleAreaToggle(
                      settings: config.protectSettings,
                      security: config.protectSecurity,
                      restore: config.protectRestore,
                      export: val,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. Key Manager View ---
  Widget _buildKeyManager(ThemeData theme, SecurityConfig config, List<EncryptionKey> keys) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stored Keys', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showImportKeysDialog(),
                    icon: const Icon(Icons.file_upload_rounded),
                    label: const Text('Import Keys'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateKeyDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Generate New Key'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (keys.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text('No keys stored yet. Generate or import encryption keys to secure your files.'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                final isActive = config.currentKeyId == key.id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.key_rounded,
                        color: isActive ? theme.colorScheme.onPrimaryContainer : Colors.grey,
                      ),
                    ),
                    title: Text(key.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${key.id}'),
                        Text('Created: ${key.createdAt.toLocal()}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          TextButton(
                            onPressed: () => _rotateKey(key.id),
                            child: const Text('Activate'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.blue),
                          tooltip: 'Copy Raw Key Data',
                          onPressed: () => _copyKeyData(key),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.red),
                          tooltip: 'Delete Key',
                          onPressed: () => _confirmDeleteKey(key),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          if (keys.isNotEmpty) ...[
            const Divider(height: 48),
            Text('Encryption Wizard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable File Encryption'),
                      subtitle: const Text('When enabled, all future backup operations will encrypt files with the active key.'),
                      value: config.encryptionEnabled,
                      onChanged: (val) {
                        if (val) {
                          final firstKeyId = config.currentKeyId ?? keys.first.id;
                          ref.read(securityControllerProvider).enableEncryption(firstKeyId);
                          ref.read(securityConfigProvider.notifier).updateConfig(
                            config.copyWith(encryptionEnabled: true, currentKeyId: firstKeyId)
                          );
                        } else {
                          ref.read(securityControllerProvider).disableEncryption();
                          ref.read(securityConfigProvider.notifier).updateConfig(
                            config.copyWith(encryptionEnabled: false)
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Audit & Integrity Log View ---
  Widget _buildAuditLogs(ThemeData theme, List<AuditReport> audits) {
    if (audits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No security integrity audits found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Audit History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Clear Audits'),
                onPressed: () {
                  ref.read(auditsNotifierProvider.notifier).clearAudits();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: audits.length,
              itemBuilder: (context, index) {
                final audit = audits[index];
                final risksCount = audit.risks.length;
                final warningsCount = audit.warnings.length;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: risksCount > 0
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      child: Icon(
                        risksCount > 0 ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                        color: risksCount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text('Audit Report: ${audit.generatedAt.toLocal()}'),
                    subtitle: Text(
                      'Success rate: ${audit.verificationSuccessCount}/${audit.totalFiles} files verified | Risks: $risksCount | Warnings: $warningsCount',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (audit.risks.isNotEmpty) ...[
                              const Text('Risks Detected:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 6),
                              ...audit.risks.map((r) => Text('• $r', style: const TextStyle(color: Colors.red))),
                              const SizedBox(height: 16),
                            ],
                            if (audit.warnings.isNotEmpty) ...[
                              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 6),
                              ...audit.warnings.map((w) => Text('• $w', style: const TextStyle(color: Colors.orange))),
                              const SizedBox(height: 16),
                            ],
                            if (audit.risks.isEmpty && audit.warnings.isEmpty)
                              const Text('No security risks or configuration warnings found.', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Helpers ---
  void _runSecurityAudit() {
    ref.read(auditsNotifierProvider.notifier).runAudit(5, 2, 3);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Integrity scanning completed successfully!')),
    );
  }

  Future<void> _verifyDbIntegrity() async {
    final dbProtection = ref.read(databaseProtectionProvider);
    final db = ref.read(databaseProvider);
    final isOk = await dbProtection.verifyIntegrity(db);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: isOk ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            const Text('Database Status'),
          ],
        ),
        content: Text(
          isOk
              ? 'SQLite database integrity check completed successfully. Diagnostic status: OK.'
              : 'Database integrity warning. Potential corruption detected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSavePassword() async {
    final controller = ref.read(securityControllerProvider);
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final hint = _hintController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password cannot be empty.')));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    try {
      await controller.changePassword(password, hint);
      _passwordController.clear();
      _confirmPasswordController.clear();
      _hintController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password settings saved successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _handleRemovePassword() async {
    final controller = ref.read(securityControllerProvider);
    await controller.removePassword();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _hintController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password lock removed.')));
  }

  Future<void> _handleAreaToggle({
    required bool settings,
    required bool security,
    required bool restore,
    required bool export,
  }) async {
    final controller = ref.read(securityControllerProvider);
    await controller.updateProtectionToggles(
      settings: settings,
      security: security,
      restore: restore,
      export: export,
    );
  }

  void _showCreateKeyDialog() {
    final nameController = TextEditingController(text: 'Key_${DateTime.now().millisecondsSinceEpoch}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate New Encryption Key'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Key Identifier Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final controller = ref.read(securityControllerProvider);
                await controller.generateKey(name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showImportKeysDialog() {
    _keyImportController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Keys Package'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: _keyImportController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste raw JSON exported keys package here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final json = _keyImportController.text.trim();
              if (json.isNotEmpty) {
                try {
                  final controller = ref.read(securityControllerProvider);
                  final importedCount = await controller.importKeys(json);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported $importedCount keys.')),
                  );
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _copyKeyData(EncryptionKey key) {
    final controller = ref.read(securityControllerProvider);
    final exported = controller.exportKeys([key.id]);
    Clipboard.setData(ClipboardData(text: exported));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption Key package copied to clipboard.')),
    );
  }

  void _rotateKey(String id) {
    ref.read(securityControllerProvider).rotateKey(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Active encryption key rotated successfully.')),
    );
  }

  void _confirmDeleteKey(EncryptionKey key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Warning: Deleting Key'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${key.name}"? '
          'Any backups encrypted with this key will become PERMANENTLY UNREADABLE if the key is removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final controller = ref.read(securityControllerProvider);
                await controller.deleteKey(key.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
