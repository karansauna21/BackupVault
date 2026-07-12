import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
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
  final TextEditingController _ipController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '8321');

  @override
  void dispose() {
    _renameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairedAsync = ref.watch(pairedDevicesStreamProvider);
    final manager = ref.watch(deviceManagerProvider);
    final identity = ref.watch(deviceIdentityProvider);
    
    // Discovery providers
    final discoveryManager = ref.watch(discoveryManagerProvider);
    final discoveredAsync = ref.watch(discoveredDevicesListStreamProvider);
    final historyAsync = ref.watch(discoveryHistoryStreamProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Devices Hub',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(
                icon: Icon(Icons.link_rounded),
                text: 'Paired Devices',
              ),
              Tab(
                icon: Icon(Icons.radar_rounded),
                text: 'Local Discovery',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Devices',
              onPressed: () async {
                await manager.loadDevices();
                await discoveryManager.refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Devices and Discovery refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerLowest,
              ],
            ),
          ),
          child: TabBarView(
            children: [
              // Tab 1: Paired Devices
              SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocalIdentityCard(context, theme, identity),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Paired Devices',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showPairDeviceDialog(context),
                          icon: const Icon(Icons.add_link_rounded, size: 18),
                          label: const Text('Pair Device'),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    pairedAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Error loading devices: $err'),
                        ),
                      ),
                      data: (devices) {
                        if (devices.isEmpty) {
                          return _buildEmptyState(context, theme);
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return _buildDeviceCard(context, theme, device, manager);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Tab 2: Local Discovery Screen
              SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manual connection entry card
                    _buildManualEntryCard(context, theme, discoveryManager),
                    const SizedBox(height: 24),

                    // Header for nearby devices
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Devices',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => discoveryManager.refresh(),
                          icon: const Icon(Icons.radar_rounded, size: 18),
                          label: const Text('Scan Subnet'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of discovered devices
                    discoveredAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Error searching nearby devices: $err'),
                        ),
                      ),
                      data: (discoveredList) {
                        if (discoveredList.isEmpty) {
                          return _buildDiscoveryEmptyState(context, theme, discoveryManager);
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: discoveredList.length,
                          itemBuilder: (context, index) {
                            final dev = discoveredList[index];
                            return _buildDiscoveredDeviceCard(context, theme, dev, discoveryManager);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Discovery history logs panel
                    _buildHistoryPanel(context, theme, historyAsync, discoveryManager),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalIdentityCard(BuildContext context, ThemeData theme, dynamic identity) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        identity.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      tooltip: 'Rename Self',
                      onPressed: () => _showRenameSelfDialog(context, identity),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'UUID: ${identity.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Platform: ${identity.platform} • Model: ${identity.deviceModel} • OS: ${identity.osVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryCard(BuildContext context, ThemeData theme, DiscoveryManager discoveryManager) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Device Connection',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final ip = _ipController.text.trim();
                  final port = int.tryParse(_portController.text.trim()) ?? 8321;
                  if (ip.isNotEmpty) {
                    final success = await discoveryManager.addManualDevice(ip, port);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? 'Device at $ip:$port added successfully' 
                              : 'Could not connect to device at $ip:$port'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: const Text('Connect'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryEmptyState(BuildContext context, ThemeData theme, DiscoveryManager manager) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning Local Network...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'mDNS, Bonjour and UDP broadcasts are actively searching for other paired devices on your network.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredDeviceCard(
    BuildContext context,
    ThemeData theme,
    DiscoveredDevice dev,
    DiscoveryManager manager,
  ) {
    final isOnline = dev.isOnline;
    final platformIcon = dev.device.platform.toLowerCase().contains('android')
        ? Icons.phone_android_rounded
        : Icons.laptop_windows_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  child: Icon(platformIcon, color: theme.colorScheme.primary),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev.device.name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dev.device.ipAddress}:${dev.device.port} • ${dev.connectionType}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildQualityBadge(theme, dev.connectionQuality),
                      const SizedBox(width: 8),
                      if (dev.latencyMs != null)
                        Text(
                          'Latency: ${dev.latencyMs}ms',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last seen: ${_formatLastSeen(dev.lastSeen)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (isOnline) {
                          await manager.disconnectDevice(dev.device.id);
                        } else {
                          await manager.connectDevice(dev.device.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isOnline ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                        foregroundColor: isOnline ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                      ),
                      child: Text(isOnline ? 'Disconnect' : 'Connect'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      tooltip: 'Ping Device',
                      onPressed: () async {
                        final ok = await manager.pingDevice(dev.device.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Ping response received!' : 'Device ping timed out!'),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityBadge(ThemeData theme, ConnectionQuality quality) {
    Color color;
    IconData icon;
    switch (quality) {
      case ConnectionQuality.excellent:
        color = Colors.green;
        icon = Icons.signal_wifi_4_bar_rounded;
        break;
      case ConnectionQuality.good:
        color = Colors.lightGreen;
        icon = Icons.network_wifi_3_bar_rounded;
        break;
      case ConnectionQuality.poor:
        color = Colors.orange;
        icon = Icons.network_wifi_1_bar_rounded;
        break;
      case ConnectionQuality.highLatency:
        color = Colors.amber;
        icon = Icons.network_wifi_2_bar_rounded;
        break;
      case ConnectionQuality.unreachable:
        color = Colors.red;
        icon = Icons.signal_wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            quality.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<DiscoveryHistoryEntry>> historyAsync,
    DiscoveryManager manager,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          'Discovery History Logs',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.list_alt_rounded, color: theme.colorScheme.primary),
        trailing: TextButton(
          onPressed: () => manager.clearHistory(),
          child: const Text('Clear'),
        ),
        children: [
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading history: $err'),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No network scan logs recorded.'),
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    IconData icon = Icons.info_outline;
                    Color color = theme.colorScheme.primary;
                    if (log.eventType == 'Device Lost') {
                      icon = Icons.wifi_off_rounded;
                      color = Colors.red;
                    } else if (log.eventType == 'Device Found') {
                      icon = Icons.wifi_rounded;
                      color = Colors.green;
                    } else if (log.eventType == 'Network Changed') {
                      icon = Icons.sync_alt_rounded;
                      color = Colors.blue;
                    }

                    return ListTile(
                      leading: Icon(icon, color: color, size: 20),
                      title: Text(
                        '${log.deviceName} (${log.ipAddress})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${log.details}\n${log.timestamp.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      isThreeLine: true,
                      dense: true,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    ThemeData theme,
    DeviceModel device,
    dynamic manager,
  ) {
    final isOnline = device.connectionStatus == 'Online';
    final platformIcon = device.platform.toLowerCase().contains('android')
        ? Icons.phone_android_rounded
        : Icons.laptop_windows_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Platform Icon with connection state ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      platformIcon,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Device details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${device.platform} • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        _buildStatusBadge(theme, device.trustStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last seen: ${_formatLastSeen(device.lastSeen)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Rename and Remove buttons directly on the Card
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Rename Device',
                    onPressed: () => _showRenameDeviceDialog(context, device, manager),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Remove Device',
                    onPressed: () => _showRemoveConfirmationDialog(context, device, manager),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color = Colors.orange;
    if (status == 'Trusted') {
      color = Colors.green;
    } else if (status == 'Blocked') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.devices_other_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Paired Devices Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your phones, tablets, or computers to start sharing and backing up data securely.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showPairDeviceDialog(context),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Pair a New Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
              identity.rename(_renameController.text.trim());
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRenameDeviceDialog(BuildContext context, DeviceModel device, dynamic manager) {
    _renameController.text = device.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Device'),
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
            onPressed: () async {
              final newName = _renameController.text.trim();
              if (newName.isNotEmpty) {
                await manager.renameDevice(device.id, newName);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmationDialog(BuildContext context, DeviceModel device, dynamic manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "${device.name}"? This will unpair the device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await manager.removeDevice(device.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showPairDeviceDialog(BuildContext context) {
    final randCode = (100000 + Random().nextInt(900000)).toString();
    showDialog(
      context: context,
      builder: (context) => _PairingCodeDialog(code: randCode),
    );
  }
}

class _PairingCodeDialog extends StatefulWidget {
  final String code;

  const _PairingCodeDialog({required this.code});

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Pair Device',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scan the QR code or enter the pairing code on the other device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Simulated QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: QrCodeSimulatedPainter(widget.code),
            ),
          ),
          const SizedBox(height: 20),

          // Pair Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.code,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expiry Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 6),
              Text(
                'Expires in $_secondsRemaining seconds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
    
    // Top-left finder pattern
    canvas.drawRect(Rect.fromLTWH(0, 0, blockSize * 4, blockSize * 4), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(blockSize, blockSize, blockSize * 2, blockSize * 2), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(blockSize * 1.5, blockSize * 1.5, blockSize, blockSize), paint);
    
    // Top-right finder pattern
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 4, 0, blockSize * 4, blockSize * 4), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 3, blockSize, blockSize * 2, blockSize * 2), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(size.width - blockSize * 2.5, blockSize * 1.5, blockSize, blockSize), paint);

    // Bottom-left finder pattern
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
