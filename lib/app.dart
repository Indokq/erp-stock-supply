import 'package:flutter/material.dart';

import 'core/responsive/responsive.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/alerts/stock_alerts_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/shared/models/mock_data.dart';
import 'features/shared/widgets/shared_cards.dart';
import 'features/stock/stock_list_screen.dart';

class RemoteErpStockApp extends StatelessWidget {
  const RemoteErpStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EOS - Stock Supply',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RemoteErpShell(),
    );
  }
}

class RemoteErpShell extends StatefulWidget {
  const RemoteErpShell({super.key});

  @override
  State<RemoteErpShell> createState() => _RemoteErpShellState();
}

class _RemoteErpShellState extends State<RemoteErpShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final bool isWide = Responsive.isExpanded(context);
    final destinations = _NavDestination.values;

    final body = IndexedStack(
      index: _index,
      children: [
        DashboardScreen(
          items: mockStockItems,
          warehouses: warehouseCapacities,
          transfers: openTransfers,
        ),
        StockListScreen(items: mockStockItems),
        StockAlertsScreen(items: mockStockItems),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'EOS ERP',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          const AvatarChip(),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const _AppDrawer(),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddStockSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Stock Item'),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) => setState(() => _index = value),
                    extended: Responsive.isExpanded(context) && MediaQuery.of(context).size.width > 1280,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );

    return scaffold;
  }
}

enum _NavDestination {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  stock(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  alerts(
    label: 'Alerts',
    icon: Icons.notification_important_outlined,
    selectedIcon: Icons.notification_important_rounded,
  );

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'Robert Fox',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            accountEmail: const Text(
              'robert.fox@remoteerp.com',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                child: Text(
                  'RF',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _DrawerTile(
                  icon: Icons.badge_outlined,
                  label: 'Profile Details',
                ),
                const _DrawerTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                ),
                const _DrawerTile(
                  icon: Icons.lock_reset_rounded,
                  label: 'Change Password',
                ),
                const _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
                const Divider(height: 32),
                _DrawerTile(
                  icon: Icons.logout_rounded,
                  label: 'Log out',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textSecondary;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap ?? () {},
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 4,
      ),
    );
  }
}

void _showAddStockSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_box_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Stock Item',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a new item to your inventory',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Form fields
            const _BottomSheetField(
              label: 'Item name',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),
            const _BottomSheetField(
              label: 'SKU',
              icon: Icons.qr_code_rounded,
            ),
            const SizedBox(height: 16),
            const _BottomSheetField(
              label: 'Quantity',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const _BottomSheetField(
              label: 'Warehouse',
              icon: Icons.warehouse_outlined,
            ),
            const SizedBox(height: 32),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _BottomSheetField extends StatelessWidget {
  const _BottomSheetField({
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
