is import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/models/device_model.dart';
import '../../shared/providers/device_provider.dart';
import '../../core/discovery/discovery_provider.dart';
import '../../core/discovery/discovery_models.dart';
import '../../core/discovery/discovery_manager.dart';
import '../../core/services/device_pairing_service.dart';
import '../../shared/providers/platform_providers.dart';
import '../../core/services/logging_service.dart';
import '../../core/services/connection_manager.dart';
import 'device_details_screen.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '8321');
  final TextEditingController _pairCodeController = TextEditingController();
  final Set<String> _shownDialogDeviceIds = {};
  final Map<String, BuildContext> _activeDialogContexts = {};

  @override
  void dispose() {
    _renameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _pairCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<PendingPairingRequest>>>(
      pendingRequestsStreamProvider,
      (previous, next) {
        next.whenData((requests) {
          final activeIds = requests.map((r) => r.device.id).toSet();

          // Auto-dismiss dialogs for requests that are no longer in the active list
          final idsToDismiss = _shownDialogDeviceIds.difference(activeIds);
          for (final id in idsToDismiss) {
            final dialogCtx = _activeDialogContexts[id];
            if (dialogCtx != null && dialogCtx.mounted) {
              Navigator.pop(dialogCtx);
            }
          }

          if (requests.isNotEmpty) {
            for (final r in requests) {
              if (r.isIncoming && !r.isExpired) {
                if (!_shownDialogDeviceIds.contains(r.device.id) && context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      _showApprovalDialog(context, r);
                    }
                  });
                }
              }
            }
          }
        });
      },
    );

    ref.listen<ConnectionNotification?>(
      manualConnectionEventProvider,
      (previous, next) {
        if (next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${next.deviceName} is now ${next.message}!'),
              backgroundColor: Colors.green,
            ),
          );
          Future.microtask(() {
            ref.read(manualConnectionEventProvider.notifier).reset();
          });
        }
      },
    );

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
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Paired Devices',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                      label: const Text('Scan QR'),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showPairDeviceDialog(context),
                                      icon: const Icon(Icons.add_link_rounded, size: 18),
                                      label: const Text('Pair Device'),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Paired Devices',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                    label: const Text('Scan QR'),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showPairDeviceDialog(context),
                                    icon: const Icon(Icons.add_link_rounded, size: 18),
                                    label: const Text('Pair Device'),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              )
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
                          key: const Key('discovery_refresh_button'),
                          onPressed: () => discoveryManager.refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    void onPairPressed() async {
      final ip = _ipController.text.trim();
      final code = _pairCodeController.text.trim();
      final portVal = int.tryParse(_portController.text.trim()) ?? 8321;
      if (ip.isNotEmpty && code.isNotEmpty) {
        BuildContext? dialogContext;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const PopScope(
              canPop: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );
        
        bool success = false;
        try {
          final pairing = ref.read(devicePairingServiceProvider);
          success = await pairing.initiatePairing(ip, code, port: portVal);
        } catch (_) {
          success = false;
        } finally {
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.pop(dialogContext!); // Close progress dialog
          }
        }
        
        if (context.mounted) {
          if (success) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Pairing Success'),
                  ],
                ),
                content: const Text('Your device has been successfully paired and trusted!'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Pairing Failed'),
                  ],
                ),
                content: const Text('Could not pair with the device. Please verify the IP, Port, and Pairing Code.'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter IP, Port, and 6-digit Pairing Code'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    void onConnectPressed() async {
      final ip = _ipController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 8321;
      if (ip.isNotEmpty) {
        BuildContext? dialogContext;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const PopScope(
              canPop: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        );

        String? errorMessage;
        try {
          final devManager = ref.read(deviceManagerProvider);
          await devManager.connectManualIP(ip, port);
        } catch (e) {
          errorMessage = e.toString();
        } finally {
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.pop(dialogContext!);
          }
        }

        if (context.mounted) {
          if (errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to device at $ip:$port successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection Failed: $errorMessage'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid IP address'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

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
            'Manual Device Connection & Pairing',
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
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            TextField(
              controller: _pairCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pairing Code (6-digit)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.link_rounded),
                    onPressed: onPairPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text('Pair'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConnectPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pairCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pairing Code (6-digit)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.link_rounded),
                  onPressed: onPairPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  label: const Text('Pair'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConnectPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: const Text('Connect'),
                ),
              ],
            ),
          ],
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
    DiscoveryManager discoveryManager,
  ) {
    final isOnline = dev.isOnline;
    final platformIcon = dev.device.platform.toLowerCase().contains('android')
        ? Icons.phone_android_rounded
        : Icons.laptop_windows_rounded;
    final manager = ref.read(deviceManagerProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Status avatar widget
    final avatarWidget = Stack(
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
    );

    // Middle info widget
    final middleInfoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dev.device.name,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${dev.device.platform} • ${dev.device.ipAddress}:${dev.device.port} • ${dev.connectionType}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildOnlineOfflineBadge(theme, isOnline),
            _buildStatusBadge(theme, dev.device.trustStatus),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildQualityBadge(theme, dev.connectionQuality),
            if (dev.latencyMs != null)
              Text(
                'Latency: ${dev.latencyMs}ms',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );

    // Action buttons widgets
    final List<Widget> actionButtons = [
      if (dev.device.trustStatus != 'Trusted')
        ElevatedButton.icon(
          key: Key('pair_btn_${dev.device.id}'),
          icon: const Icon(Icons.link_rounded, size: 16),
          label: const Text('Pair'),
          onPressed: () async {
            final codeController = TextEditingController();
            final enteredCode = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Pair with ${dev.device.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Please enter the 6-digit Pair Code displayed on ${dev.device.name}.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pair Code',
                        hintText: 'e.g., 123456',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, codeController.text.trim()),
                    child: const Text('Pair'),
                  ),
                ],
              ),
            );

            if (enteredCode == null || enteredCode.isEmpty) return;
            if (!context.mounted) return;

            BuildContext? dialogContext;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                dialogContext = ctx;
                return const PopScope(
                  canPop: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );

            bool success = false;
            ref.read(loggingServiceProvider).info('DiscoveryService', 'Connection Requested');
            try {
              success = await ref.read(devicePairingServiceProvider).initiatePairing(
                dev.device.ipAddress,
                enteredCode,
                port: dev.device.port,
              );
            } catch (_) {
              success = false;
            } finally {
              if (dialogContext != null && dialogContext!.mounted) {
                Navigator.pop(dialogContext!);
              }
            }

            if (success) {
              ref.read(loggingServiceProvider).info('DiscoveryService', 'Connection Success');
            } else {
              ref.read(loggingServiceProvider).warning('DiscoveryService', 'Connection Failed');
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? 'Device paired successfully!' 
                      : 'Pairing failed. Make sure the other device is online and the Pair Code is correct.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
            await discoveryManager.refresh();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
        )
      else ...[
        ElevatedButton.icon(
          key: Key('connect_btn_${dev.device.id}'),
          icon: Icon(isOnline ? Icons.link_off_rounded : Icons.link_rounded, size: 16),
          label: Text(isOnline ? 'Disconnect' : 'Connect'),
          onPressed: () async {
            if (isOnline) {
              await discoveryManager.disconnectDevice(dev.device.id);
            } else {
              await discoveryManager.connectDevice(dev.device.id);
            }
            await discoveryManager.refresh();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
            backgroundColor: isOnline ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
            foregroundColor: isOnline ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: Key('remove_btn_${dev.device.id}'),
          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
          tooltip: 'Remove Device',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove Device'),
                content: Text('Are you sure you want to untrust and remove "${dev.device.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Remove', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await manager.removeDevice(dev.device.id);
              await discoveryManager.refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device removed successfully.')),
                );
              }
            }
          },
        ),
      ],
      const SizedBox(width: 4),
      IconButton(
        icon: const Icon(Icons.bolt_rounded, size: 20),
        tooltip: 'Ping Device',
        onPressed: () async {
          final ok = await discoveryManager.pingDevice(dev.device.id);
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
    ];

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
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatarWidget,
                      const SizedBox(width: 16),
                      Expanded(child: middleInfoWidget),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actionButtons,
                  ),
                ],
              )
            : Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: 16),
                  Expanded(child: middleInfoWidget),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actionButtons,
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
            'Signal Strength: ${quality.name.toUpperCase()}',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineOfflineBadge(ThemeData theme, bool isOnline) {
    final color = isOnline ? Colors.green : Colors.grey;
    final label = isOnline ? 'Online' : 'Offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
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
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailsScreen(device: device),
              ),
            );
          },
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
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color = Colors.orange;
    String label = status;
    if (status == 'Trusted') {
      color = Colors.green;
    } else if (status == 'Blocked') {
      color = Colors.red;
    } else if (status == 'Pending') {
      label = 'Unpaired';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
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
    showDialog(
      context: context,
      builder: (context) => const _PairingCodeDialog(),
    );
  }

  void _showApprovalDialog(BuildContext context, PendingPairingRequest request) {
    final deviceId = request.device.id;
    if (_shownDialogDeviceIds.contains(deviceId)) return;
    _shownDialogDeviceIds.add(deviceId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _activeDialogContexts[deviceId] = dialogContext;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Pairing Request Received'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A device named "${request.device.name}" wants to pair with you.', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Platform: ${request.device.platform}'),
                Text('Model: ${request.device.deviceModel}'),
                Text('OS Version: ${request.device.osVersion}'),
                const SizedBox(height: 16),
                const Text('Do you trust this device and want to connect?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  Navigator.pop(dialogContext);
                  await ref.read(devicePairingServiceProvider).blockRequest(deviceId);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Device Blocked.')),
                  );
                },
                child: Text('Block', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  Navigator.pop(dialogContext);
                  await ref.read(devicePairingServiceProvider).rejectRequest(deviceId);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Request Rejected.')),
                  );
                },
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  Navigator.pop(dialogContext);
                  await ref.read(devicePairingServiceProvider).approveRequest(deviceId);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Device Approved & Trusted!')),
                  );
                },
                child: const Text('Approve & Trust'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _activeDialogContexts.remove(deviceId);
      _shownDialogDeviceIds.remove(deviceId);
    });
  }
}

class _PairingCodeDialog extends ConsumerStatefulWidget {
  const _PairingCodeDialog();

  @override
  ConsumerState<_PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends ConsumerState<_PairingCodeDialog> {
  int _secondsRemaining = 300;
  Timer? _timer;
  String _code = '';
  String _qrPayload = '';
  bool _isLoading = true;
  int? _initialPairedCount;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  void _initPairing() async {
    final initialDevices = ref.read(pairedDevicesStreamProvider).value ?? [];
    _initialPairedCount = initialDevices.length;
    _refreshCode();
  }

  void _refreshCode() async {
    final pairing = ref.read(devicePairingServiceProvider);
    final code = pairing.startHostingPairing();
    final payload = await pairing.getPairingQrPayload();
    
    _timer?.cancel();
    
    if (mounted) {
      setState(() {
        _code = code;
        _qrPayload = payload;
        _secondsRemaining = 300;
        _isLoading = false;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _refreshCode(); // Automatically regenerate after expiration
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(devicePairingServiceProvider).stopHostingPairing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DeviceModel>>>(
      pairedDevicesStreamProvider,
      (previous, next) {
        next.whenData((pairedList) {
          if (_initialPairedCount != null && pairedList.length > _initialPairedCount!) {
            Navigator.pop(context);
          }
        });
      },
    );

    final theme = Theme.of(context);
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Pair Device',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
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

            // Real QR Code using qr_flutter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              width: 180,
              height: 180,
              child: QrImageView(
                data: _qrPayload,
                version: QrVersions.auto,
                size: 160,
              ),
            ),
            const SizedBox(height: 8),
            // Copy Payload Button for simulation testing
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy QR Payload'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _qrPayload));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR Payload copied to clipboard!')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Pair Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _code,
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
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh Code'),
          onPressed: _refreshCode,
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pasteController = TextEditingController();
  bool _isProcessing = false;
  
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoStart: false,
  );

  bool _hasPermission = false;
  bool _cameraInitialized = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _laserPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _laserPosition = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCameraFlow();
    });
  }

  Future<void> _initCameraFlow() async {
    final logger = ref.read(loggingServiceProvider);
    await logger.info('QrScanner', 'Starting camera permission initialization flow');

    if (!Platform.isAndroid) {
      setState(() {
        _hasPermission = true;
        _cameraInitialized = true;
      });
      return;
    }

    try {
      final permManager = ref.read(permissionManagerProvider);
      bool hasCam = await permManager.hasPermission('camera');
      await logger.info('QrScanner', 'Initial camera permission status: $hasCam');
      
      if (!hasCam) {
        await logger.info('QrScanner', 'Camera permission not granted, requesting automatically');
        hasCam = await permManager.requestPermission('camera');
        await logger.info('QrScanner', 'Camera permission request result: $hasCam');
      }

      if (hasCam) {
        setState(() {
          _hasPermission = true;
          _errorMessage = null;
        });
        await _startCamera();
      } else {
        await logger.warning('QrScanner', 'Camera permission denied by user');
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      await logger.error('QrScanner', 'Failed during permission/camera flow: $e');
      setState(() {
        _errorMessage = 'Error checking camera permissions: $e';
      });
    }
  }

  Future<void> _startCamera() async {
    final logger = ref.read(loggingServiceProvider);
    try {
      await logger.info('QrScanner', 'Setting camera initialized flag to true...');
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
          _errorMessage = null;
        });
      }
      
      // Allow a brief frame delay so MobileScanner widget is mounted & texture registered
      await Future.delayed(const Duration(milliseconds: 250));
      
      await logger.info('QrScanner', 'Initializing mobile scanner camera...');
      await cameraController.start();
      await logger.info('QrScanner', 'Camera started and live preview initialized successfully');
    } catch (e) {
      await logger.error('QrScanner', 'Failed to start camera preview: $e');
      if (mounted) {
        setState(() {
          _cameraInitialized = false;
          _errorMessage = 'Failed to start camera. Please verify camera permissions or restart the app.';
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'BackupVault needs access to your camera to scan pairing QR codes. '
            'Please grant camera permission in the next prompt, or enable it in App Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                if (mounted) {
                  Navigator.pop(context); // Close QrScannerScreen
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _initCameraFlow();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pasteController.dispose();
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _processPayload(String payload) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final logger = ref.read(loggingServiceProvider);
    
    // Log: QR Scanned
    await logger.info('PairCode', 'QR Scanned: $payload');

    try {
      await cameraController.stop();
      await logger.info('QrScanner', 'Camera stopped successfully after detection');
    } catch (e) {
      await logger.warning('QrScanner', 'Failed to stop camera: $e');
    }

    try {
      Map<String, dynamic> data;
      try {
        data = json.decode(payload) as Map<String, dynamic>;
        // Log: QR Parsed
        await logger.info('PairCode', 'QR Parsed');
      } catch (e) {
        throw const FormatException('Invalid JSON format');
      }

      final pairCode = data['pairCode'] as String? ?? '';
      final deviceUuid = data['deviceUuid'] as String? ?? '';
      final deviceName = data['deviceName'] as String? ?? '';
      final localIp = data['localIp'] as String? ?? '';
      final tcpPort = data['tcpPort'] as int? ?? ConnectionManager.tcpPort;
      final appVersion = data['appVersion'] as String? ?? '';
      final expirationStr = data['expirationTime'] as String? ?? '';

      // 1. Invalid QR
      if (localIp.isEmpty || pairCode.isEmpty) {
        _showErrorDialog('Invalid QR', 'The QR code format is invalid or missing pairing information.');
        return;
      }

      // 2. Expired QR
      if (expirationStr.isNotEmpty) {
        final expiry = DateTime.tryParse(expirationStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          _showErrorDialog('Expired QR', 'The pairing session has expired. Please refresh the QR code on the host.');
          return;
        }
      }

      // 3. Wrong Version
      final pairingService = ref.read(devicePairingServiceProvider);
      final selfModel = await pairingService.identity.toModel();
      if (appVersion.isNotEmpty && selfModel.appVersion != appVersion) {
        _showErrorDialog('Wrong Version', 'Host app version ($appVersion) is incompatible with client app version (${selfModel.appVersion}).');
        return;
      }

      // 4. Already Paired
      final existingDevice = await pairingService.repository.getDeviceById(deviceUuid);
      if (existingDevice != null && existingDevice.trustStatus == 'Trusted') {
        _showErrorDialog('Already Paired', 'This device is already paired and trusted.');
        return;
      }

      // 5. Connect and Handshake
      BuildContext? dialogContext;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const PopScope(
              canPop: false,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        );
      }

      bool success = false;
      try {
        await logger.info('QrScanner', 'Starting pairing handshake automatically...');
        success = await pairingService.initiatePairing(
          localIp,
          pairCode,
          port: tcpPort,
        );
        await logger.info('QrScanner', 'Pairing handshake finished. Success: $success');
      } catch (err) {
        await logger.error('QrScanner', 'Error during automatic pairing: $err');
        success = false;
      } finally {
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.pop(dialogContext!);
        }
      }

      if (mounted) {
        if (success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Pairing Success'),
                ],
              ),
              content: Text('Successfully paired and trusted with $deviceName!'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close success dialog
                    Navigator.pop(this.context, true); // Close QrScannerScreen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Network Failure / Connection Timeout
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Connection Failed'),
                ],
              ),
              content: const Text('Could not establish manual connection. Please check network connectivity and try again.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    setState(() {
                      _isProcessing = false;
                    });
                    _startCamera();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      await logger.error('QrScanner', 'Failed to process pairing payload: $e');
      _showErrorDialog('Invalid QR', 'The QR code payload is invalid or corrupted.');
    }
  }

  void _showErrorDialog(String title, String message) {
    setState(() {
      _isProcessing = false;
    });
    _startCamera();
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWidget(BuildContext context, ThemeData theme) {
    if (_errorMessage != null) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.error, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initCameraFlow();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Camera'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Requesting camera permission...'),
            ],
          ),
        ),
      );
    }

    if (!_cameraInitialized) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Starting camera preview...'),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null) {
                  _processPayload(rawValue);
                  break;
                }
              }
            },
          ),
          // Laser Scanning Animation
          AnimatedBuilder(
            animation: _laserPosition,
            builder: (context, child) {
              return Positioned(
                top: _laserPosition.value * 300,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Camera Control Overlays (Torch & Camera Switch)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash Toggle Button
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: cameraController,
                  builder: (context, state, child) {
                    final isFlashOn = state.torchState == TorchState.on;
                    return IconButton.filledTonal(
                      icon: Icon(isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                      onPressed: () => cameraController.toggleTorch(),
                    );
                  },
                ),
                // Camera Switch Button
                IconButton.filledTonal(
                  icon: const Icon(Icons.cameraswitch_rounded),
                  onPressed: () => cameraController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pairing QR Code'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (isMobile) ...[
                _buildCameraWidget(context, theme),
                const SizedBox(height: 16),
                const Text('Point camera at the QR code on the other device'),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],
              
              Text(
                'Simulate QR Scan (For Desktop/Testing)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'If camera scanning is not supported on this platform, copy the QR payload JSON from the other device and paste it below:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pasteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'QR Code JSON Payload',
                  border: OutlineInputBorder(),
                  hintText: '{"ip":"...","port":...,"code":"...","id":"...","name":"..."}',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final text = _pasteController.text.trim();
                  if (text.isNotEmpty) {
                    _processPayload(text);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Simulate Scan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
