import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainNavigationShell({
    super.key,
    required this.child,
    required this.state,
  });

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/backup')) return 1;
    if (location.startsWith('/restore')) return 2;
    if (location.startsWith('/folders')) return 3;
    if (location.startsWith('/statistics')) return 4;
    if (location.startsWith('/logs')) return 5;
    if (location.startsWith('/settings')) return 6;
    if (location.startsWith('/search')) return 7;
    if (location.startsWith('/versions')) return 8;
    if (location.startsWith('/notifications')) return 9;
    if (location.startsWith('/scheduler')) return 10;
    if (location.startsWith('/devices')) return 11;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/backup');
        break;
      case 2:
        context.go('/restore');
        break;
      case 3:
        context.go('/folders');
        break;
      case 4:
        context.go('/statistics');
        break;
      case 5:
        context.go('/logs');
        break;
      case 6:
        context.go('/settings');
        break;
      case 7:
        context.go('/search');
        break;
      case 8:
        context.go('/versions');
        break;
      case 9:
        context.go('/notifications');
        break;
      case 10:
        context.go('/scheduler');
        break;
      case 11:
        context.go('/devices');
        break;
    }
  }

  List<Widget> _buildDrawerItems(BuildContext context, int selectedIndex) {
    final destinations = [
      const _DrawerItemData(Icons.grid_view_rounded, 'Dashboard', 0),
      const _DrawerItemData(Icons.backup_rounded, 'Backup', 1),
      const _DrawerItemData(Icons.restore_rounded, 'Restore', 2),
      const _DrawerItemData(Icons.folder_shared_rounded, 'Folders', 3),
      const _DrawerItemData(Icons.analytics_rounded, 'Stats', 4),
      const _DrawerItemData(Icons.receipt_long_rounded, 'Logs', 5),
      const _DrawerItemData(Icons.settings_rounded, 'Settings', 6),
      const _DrawerItemData(Icons.search_rounded, 'Search', 7),
      const _DrawerItemData(Icons.history_rounded, 'History', 8),
      const _DrawerItemData(Icons.notifications_rounded, 'Alerts', 9),
      const _DrawerItemData(Icons.auto_awesome_rounded, 'Scheduler', 10),
      const _DrawerItemData(Icons.devices_other_rounded, 'Devices', 11),
    ];

    return destinations.map((d) {
      final isSelected = selectedIndex == d.index;
      return ListTile(
        leading: Icon(d.icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
        title: Text(
          d.title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        onTap: () {
          Navigator.pop(context); // Close drawer
          _onItemTapped(d.index, context);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final width = MediaQuery.of(context).size.width;

    // Breakpoints
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1000;

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.cloud_sync_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'BackupVault',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildDrawerItems(context, selectedIndex),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (index) => _onItemTapped(index, context),
                        labelType: isTablet
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_sync_rounded,
                                size: isTablet ? 32 : 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              if (!isTablet) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'BackupVault',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.grid_view_rounded),
                            selectedIcon: Icon(Icons.grid_view_rounded),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.backup_rounded),
                            selectedIcon: Icon(Icons.backup_rounded),
                            label: Text('Backup'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.restore_rounded),
                            selectedIcon: Icon(Icons.restore_rounded),
                            label: Text('Restore'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.folder_shared_rounded),
                            selectedIcon: Icon(Icons.folder_shared_rounded),
                            label: Text('Folders'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_rounded),
                            selectedIcon: Icon(Icons.analytics_rounded),
                            label: Text('Stats'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.receipt_long_rounded),
                            selectedIcon: Icon(Icons.receipt_long_rounded),
                            label: Text('Logs'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_rounded),
                            selectedIcon: Icon(Icons.settings_rounded),
                            label: Text('Settings'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search_rounded),
                            selectedIcon: Icon(Icons.search_rounded),
                            label: Text('Search'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.history_rounded),
                            selectedIcon: Icon(Icons.history_rounded),
                            label: Text('History'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.notifications_rounded),
                            selectedIcon: Icon(Icons.notifications_active_rounded),
                            label: Text('Alerts'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.auto_awesome_rounded),
                            selectedIcon: Icon(Icons.auto_awesome_rounded),
                            label: Text('Scheduler'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.devices_other_rounded),
                            selectedIcon: Icon(Icons.devices_other_rounded),
                            label: Text('Devices'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: child,
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Builder(
              builder: (context) {
                final displayIndex = selectedIndex < 4 ? selectedIndex : 4;
                return NavigationBar(
                  selectedIndex: displayIndex,
                  onDestinationSelected: (index) {
                    if (index == 4) {
                      Scaffold.of(context).openDrawer();
                    } else {
                      _onItemTapped(index, context);
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.backup_rounded),
                      label: 'Backup',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.restore_rounded),
                      label: 'Restore',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.folder_shared_rounded),
                      label: 'Folders',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_rounded),
                      label: 'More',
                    ),
                  ],
                );
              },
            )
          : null,
    );
  }
}

class _DrawerItemData {
  final IconData icon;
  final String title;
  final int index;
  const _DrawerItemData(this.icon, this.title, this.index);
}
