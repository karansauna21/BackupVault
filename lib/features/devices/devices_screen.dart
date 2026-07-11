import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
import '../../core/services/device_pairing_service.dart';
import '../../shared/providers/device_provider.dart';
import '../../core/discovery/discovery_provider.dart';
import '../../core/discovery/discovery_models.dart';
import '../../core/discovery/discovery_manager.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _pairCodeController = TextEditingController();
  final TextEditingController _targetIpController = TextEditingController();
  final TextEditingController _manualIpController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController(text: '8321');
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _renameController.dispose();
    _pairCodeController.dispose();
    _targetIpController.dispose();
    _manualIpController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Watch state providers
    final pairedAsync = ref.watch(pairedDevicesStreamProvider);
    final discoveredAsync = ref.watch(discoveredDevicesStreamProvider);
    final discoveredDevicesListAsync = ref.watch(discoveredDevicesListStreamProvider);
    final discoveryHistoryAsync = ref.watch(discoveryHistoryStreamProvider);

    // Watch managers/services
    final manager = ref.watch(deviceManagerProvider);
    final pairingService = ref.watch(devicePairingServiceProvider);
    final identity = ref.watch(deviceIdentityProvider);
    final discoveryManager = ref.watch(discoveryManagerProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Listen for incoming requests to show a prompt
    ref.listen(pendingRequestsStreamProvider, (prev, next) {
      final list = next.value ?? [];
      final incoming = list.where((r) => r.isIncoming && !r.isExpired).toList();
      if (incoming.isNotEmpty) {
        final req = incoming.first;
        _showIncomingPairingDialog(context, req);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Devices'),
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : null,
        actions: [
          if (_selectedTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh LAN Devices',
              onPressed: () => manager.refreshDevices(),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add_link_rounded),
              tooltip: 'Add Manual IP',
              onPressed: () => _showManualIpDiscoveryDialog(context, discoveryManager),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Discovery',
              onPressed: () => discoveryManager.refresh(),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Local Device identity section
            _buildLocalIdentityCard(context, theme, identity),
            const SizedBox(height: 24),

            // Tab bar selection segment control
            _buildTabSegments(context, theme),
            const SizedBox(height: 24),

            // Main dashboard sections based on tab selection
            if (_selectedTabIndex == 0) ...[
              if (isMobile) ...[
                _buildPairingPanel(context, theme, pairingService, manager),
                const SizedBox(height: 24),
                _buildPairedListPanel(context, theme, pairedAsync, manager),
                const SizedBox(height: 24),
                _buildDiscoveredListPanel(context, theme, discoveredAsync, pairingService),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPairedListPanel(context, theme, pairedAsync, manager),
                          const SizedBox(height: 24),
                          _buildDiscoveredListPanel(context, theme, discoveredAsync, pairingService),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildPairingPanel(context, theme, pairingService, manager),
                    ),
                  ],
                ),
            ] else
              _buildDiscoveryTabPanel(
                context,
                theme,
                discoveredDevicesListAsync,
                discoveryHistoryAsync,
                discoveryManager,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSegments(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentItem(
              index: 0,
              title: 'Device Pairing',
              icon: Icons.link_rounded,
              theme: theme,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentItem(
              index: 1,
              title: 'Network Discovery',
              icon: Icons.cell_tower_rounded,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required String title,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualIpDiscoveryDialog(BuildContext context, DiscoveryManager discoveryManager) {
    _manualIpController.clear();
    _manualPortController.text = '8321';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Device by IP Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualIpController,
              decoration: const InputDecoration(
                labelText: 'Target IP Address',
                hintText: 'e.g. 192.168.1.100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualPortController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = _manualIpController.text.trim();
              final port = int.tryParse(_manualPortController.text) ?? 8321;
              if (ip.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pinging $ip:$port...')),
                );
                final success = await discoveryManager.addManualDevice(ip, port);
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device discovered and added successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to connect to device at specified IP/Port.')),
                  );
                }
              }
            },
            child: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTabPanel(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<DiscoveredDevice>> discoveredDevicesAsync,
    AsyncValue<List<DiscoveryHistoryEntry>> discoveryHistoryAsync,
    DiscoveryManager discoveryManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discovery Status Banner
        Card(
          elevation: 0,
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.radar_rounded, color: theme.colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatic Discovery Active',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scanning LAN using mDNS / Bonjour (5353) & UDP Broadcast (8323)',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Nearby Devices Card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Paired Devices',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => discoveryManager.refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Now'),
                    ),
                  ],
                ),
                const Divider(height: 16),
                discoveredDevicesAsync.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )),
                  error: (err, _) => Text('Error loading nearby devices: $err'),
                  data: (devices) {
                    if (devices.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No nearby devices detected on this network yet.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: Alignment.center as TextAlign?,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Make sure devices are on the same Wi-Fi/LAN subnet.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final dev = devices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: theme.colorScheme.surfaceContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: dev.isOnline
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      child: Icon(
                                        dev.device.platform == 'Android'
                                            ? Icons.phone_android_rounded
                                            : Icons.laptop_windows_rounded,
                                        color: dev.isOnline ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                dev.device.name,
                                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: dev.isOnline ? Colors.green : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                dev.isOnline ? 'Online' : 'Offline',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: dev.isOnline ? Colors.green : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'IP: ${dev.device.ipAddress}:${dev.device.port} • OS: ${dev.device.osVersion}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Last Seen: ${_formatLastSeen(dev.lastSeen)} • Connection: ${dev.connectionType}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        _buildSignalQualityIcon(dev.connectionQuality),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getQualityLabel(dev.connectionQuality, dev.latencyMs),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getConnectionQualityColor(dev.connectionQuality),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => discoveryManager.pingDevice(dev.device.id),
                                      icon: const Icon(Icons.radar_rounded, size: 14),
                                      label: const Text('Ping'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (dev.isOnline)
                                      ElevatedButton.icon(
                                        onPressed: () => discoveryManager.disconnectDevice(dev.device.id),
                                        icon: const Icon(Icons.link_off_rounded, size: 14),
                                        label: const Text('Disconnect'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final success = await discoveryManager.connectDevice(dev.device.id);
                                          if (!context.mounted) return;
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Connected successfully!')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to connect to device.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.link_rounded, size: 14),
                                        label: const Text('Connect'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Discovery History Logs Panel
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discovery History Logs',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => discoveryManager.clearHistory(),
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear Log'),
                    ),
                  ],
                ),
                const Divider(height: 16),
                discoveryHistoryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading history: $err'),
                  data: (history) {
                    if (history.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No discovery events logged yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length > 20 ? 20 : history.length, // Limit view to top 20
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        return _buildDiscoveryHistoryItem(theme, entry);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignalQualityIcon(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return const Icon(Icons.wifi_rounded, color: Colors.green);
      case ConnectionQuality.good:
        return const Icon(Icons.wifi_2_bar_rounded, color: Colors.blue);
      case ConnectionQuality.poor:
        return const Icon(Icons.wifi_1_bar_rounded, color: Colors.orange);
      case ConnectionQuality.highLatency:
        return const Icon(Icons.wifi_1_bar_rounded, color: Colors.deepOrange);
      case ConnectionQuality.unreachable:
        return const Icon(Icons.wifi_off_rounded, color: Colors.red);
    }
  }

  Color _getConnectionQualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.blue;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.highLatency:
        return Colors.deepOrange;
      case ConnectionQuality.unreachable:
        return Colors.red;
    }
  }

  String _getQualityLabel(ConnectionQuality quality, int? latencyMs) {
    if (quality == ConnectionQuality.unreachable) return 'Unreachable';
    final lat = latencyMs != null ? ' (${latencyMs}ms)' : '';
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent$lat';
      case ConnectionQuality.good:
        return 'Good$lat';
      case ConnectionQuality.poor:
        return 'Poor$lat';
      case ConnectionQuality.highLatency:
        return 'High Latency$lat';
      case ConnectionQuality.unreachable:
        return 'Unreachable';
    }
  }

  Widget _buildDiscoveryHistoryItem(ThemeData theme, DiscoveryHistoryEntry entry) {
    Color iconColor = Colors.grey;
    IconData iconData = Icons.info_outline_rounded;

    if (entry.eventType == 'Device Found') {
      iconColor = Colors.green;
      iconData = Icons.wifi_tethering_rounded;
    } else if (entry.eventType == 'Device Lost') {
      iconColor = Colors.red;
      iconData = Icons.portable_wifi_off_rounded;
    } else if (entry.eventType == 'Network Changed') {
      iconColor = Colors.blue;
      iconData = Icons.alt_route_rounded;
    } else if (entry.eventType == 'Reconnect Event') {
      iconColor = Colors.amber;
      iconData = Icons.sync_disabled_rounded;
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(iconData, color: iconColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${entry.deviceName} - ${entry.eventType}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatLastSeen(entry.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      subtitle: Text(
        'IP: ${entry.ipAddress} • ${entry.details}',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildLocalIdentityCard(BuildContext context, ThemeData theme, dynamic identity) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        identity.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        tooltip: 'Rename Device',
                        onPressed: () => _showRenameSelfDialog(context, identity),
                      ),
                    ],
                  ),
                  Text(
                    'Device ID: ${identity.id}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform: ${identity.platform} (${identity.deviceModel}) • OS: ${identity.osVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairingPanel(
    BuildContext context,
    ThemeData theme,
    DevicePairingService pairingService,
    dynamic manager,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pair New Device',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Text(
              'To connect a new phone or laptop, generate a code on one device and enter it on the other.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPairingCodeGeneratorDialog(context, pairingService),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Generate Pair Code'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showManualPairDialog(context, pairingService),
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Enter Manual Code'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairedListPanel(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<DeviceModel>> pairedAsync,
    dynamic manager,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paired Devices',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => manager.refreshDevices(),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const Divider(height: 16),
            pairedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading paired devices: $err'),
              data: (devices) {
                if (devices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No devices paired yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final dev = devices[index];
                    final isOnline = dev.connectionStatus == 'Online';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: theme.colorScheme.surfaceContainer,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOnline
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          child: Icon(
                            dev.platform == 'Android'
                                ? Icons.phone_android_rounded
                                : Icons.laptop_windows_rounded,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              dev.name,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _buildTrustBadge(theme, dev.trustStatus),
                          ],
                        ),
                        subtitle: Text(
                          '${dev.platform} • Storage: ${dev.storageInfo} • Version: ${dev.appVersion}\nLast seen: ${isOnline ? "Just now" : _formatLastSeen(dev.lastSeen)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'rename') {
                              _showRenameDeviceDialog(context, dev.id, dev.name, manager);
                            } else if (val == 'disconnect') {
                              manager.disconnectDevice(dev.id);
                            } else if (val == 'remove') {
                              manager.removeDevice(dev.id);
                            } else if (val == 'trust') {
                              manager.setTrustStatus(dev.id, 'Trusted');
                            } else if (val == 'block') {
                              manager.setTrustStatus(dev.id, 'Blocked');
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            if (dev.trustStatus != 'Trusted')
                              const PopupMenuItem(
                                value: 'trust',
                                child: Text('Trust Device'),
                              ),
                            if (dev.trustStatus != 'Blocked')
                              const PopupMenuItem(
                                value: 'block',
                                child: Text('Block Device'),
                              ),
                            if (isOnline)
                              const PopupMenuItem(
                                value: 'disconnect',
                                child: Text('Disconnect'),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove Device', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredListPanel(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<DeviceModel>> discoveredAsync,
    DevicePairingService pairingService,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discovered LAN Devices',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            discoveredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error searching devices: $err'),
              data: (devices) {
                if (devices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Searching for nearby devices on LAN...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final dev = devices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        dev.platform == 'Android'
                            ? Icons.phone_android_rounded
                            : Icons.laptop_windows_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        dev.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'IP: ${dev.ipAddress} • OS: ${dev.osVersion}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _showPairingCodeGeneratorDialog(context, pairingService, targetIp: dev.ipAddress),
                        child: const Text('Pair'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(ThemeData theme, String status) {
    Color bg = Colors.grey;
    Color fg = Colors.white;
    if (status == 'Trusted') {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
    } else if (status == 'Blocked') {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.red;
    } else {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _showRenameSelfDialog(BuildContext context, dynamic identity) {
    _renameController.text = identity.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Local Device'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              identity.rename(_renameController.text);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRenameDeviceDialog(BuildContext context, String id, String currentName, dynamic manager) {
    _renameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Connected Device'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              manager.renameDevice(id, _renameController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPairingCodeGeneratorDialog(
    BuildContext context,
    DevicePairingService pairingService, {
    String? targetIp,
  }) {
    final code = pairingService.generatePairCode();
    
    // Automatically trigger pairing listener if target IP is provided
    if (targetIp != null) {
      pairingService.initiatePairing(targetIp, code);
    }

    showDialog(
      context: context,
      builder: (context) {
        return _PairingCodeDialog(
          code: code,
          targetIp: targetIp,
        );
      },
    );
  }

  void _showManualPairDialog(BuildContext context, DevicePairingService pairingService) {
    _pairCodeController.clear();
    _targetIpController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect with Pair Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _targetIpController,
              decoration: const InputDecoration(
                labelText: 'Target Device IP',
                hintText: 'e.g. 192.168.1.50',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.values[0],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pairCodeController,
              decoration: const InputDecoration(
                labelText: '6-Digit Pairing Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = _targetIpController.text;
              final code = _pairCodeController.text;
              if (ip.isNotEmpty && code.length == 6) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sending pairing request...')),
                );
                final success = await pairingService.initiatePairing(ip, code);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device paired successfully!')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pairing failed or rejected.')),
                  );
                }
              }
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  void _showIncomingPairingDialog(BuildContext context, PendingPairingRequest request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Pairing Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${request.device.name}'),
            Text('Platform: ${request.device.platform} (${request.device.deviceModel})'),
            const SizedBox(height: 16),
            const Text('Verify that the code on the other screen matches:'),
            const SizedBox(height: 8),
            Center(
              child: Text(
                request.pairCode,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(devicePairingServiceProvider).rejectRequest(request.device.id);
              Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(devicePairingServiceProvider).approveRequest(request.device.id);
              Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

class _PairingCodeDialog extends StatefulWidget {
  final String code;
  final String? targetIp;

  const _PairingCodeDialog({
    required this.code,
    this.targetIp,
  });

  @override
  State<_PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends State<_PairingCodeDialog> {
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Scan or Enter Pairing Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: QrCodeSimulatedPainter(widget.code),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.code,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 6),
          ),
          const SizedBox(height: 12),
          Text(
            'Expires in $_secondsRemaining seconds',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
          ),
          if (widget.targetIp != null) ...[
            const SizedBox(height: 8),
            Text(
              'Connecting to ${widget.targetIp}...',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class QrCodeSimulatedPainter extends CustomPainter {
  final String code;
  QrCodeSimulatedPainter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final blockSize = size.width / 15;
    
    // Top-left finder
    canvas.drawRect(Rect.fromLTWH(0, 0, blockSize * 4, blockSize * 4), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(blockSize, blockSize, blockSize * 2, blockSize * 2), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(blockSize * 1.5, blockSize * 1.5, blockSize, blockSize), paint);
    
    // Top-right finder
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 4, 0, blockSize * 4, blockSize * 4), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 3, blockSize, blockSize * 2, blockSize * 2), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 2.5, blockSize * 1.5, blockSize, blockSize), paint);

    // Bottom-left finder
    canvas.drawRect(Rect.fromLTWH(0, size.height - blockSize * 4, blockSize * 4, blockSize * 4), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(blockSize, size.height - blockSize * 3, blockSize * 2, blockSize * 2), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(blockSize * 1.5, size.height - blockSize * 2.5, blockSize, blockSize), paint);

    // Seeded random matrix
    final rand = Random(code.hashCode);
    paint.color = Colors.black;
    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        if (r < 5 && c < 5) continue;
        if (r < 5 && c > 9) continue;
        if (r > 9 && c < 5) continue;
        
        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * blockSize, r * blockSize, blockSize + 0.5, blockSize + 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
