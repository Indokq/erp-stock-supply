import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'movement_type.dart';
import 'stock_models.dart';

final List<QuickAction> quickActions = const [
  QuickAction(
    label: 'Add Stock',
    icon: Icons.add_box_rounded,
    color: AppColors.primaryBlue,
  ),
  QuickAction(
    label: 'Transfer',
    icon: Icons.sync_alt_rounded,
    color: Colors.deepPurple,
  ),
  QuickAction(
    label: 'Stock Alerts',
    icon: Icons.notifications_active_rounded,
    color: Colors.orangeAccent,
  ),
  QuickAction(
    label: 'Audit Stock',
    icon: Icons.fact_check_rounded,
    color: Colors.green,
  ),
  QuickAction(
    label: 'Receipts',
    icon: Icons.receipt_long_rounded,
    color: Colors.blueGrey,
  ),
  QuickAction(
    label: 'Purchase Orders',
    icon: Icons.assignment_rounded,
    color: Colors.indigo,
  ),
  QuickAction(
    label: 'Suppliers',
    icon: Icons.store_mall_directory_rounded,
    color: Colors.teal,
  ),
  QuickAction(
    label: 'Analytics',
    icon: Icons.analytics_rounded,
    color: Colors.pinkAccent,
  ),
];

final List<StockItem> mockStockItems = [
  StockItem(
    name: 'HDPE Pipe 2"',
    sku: 'HDPE-2001',
    category: 'Pipes',
    warehouse: 'Central Depot',
    quantity: 420,
    available: 380,
    reserved: 40,
    reorderPoint: 300,
    leadTimeDays: 5,
    expiringLots: 1,
    averageCost: 48.50,
    suppliers: ['Blue River Plastics', 'PolySupply Co.'],
    movements: [
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: MovementType.outbound,
        reference: 'Sales Order #5402',
        quantity: 60,
      ),
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: MovementType.inbound,
        reference: 'Purchase Receipt #1821',
        quantity: 120,
      ),
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 6)),
        type: MovementType.transfer,
        reference: 'Transfer to North Hub',
        quantity: 40,
      ),
    ],
  ),
  StockItem(
    name: 'Steel Fastener M8',
    sku: 'FAST-M8-001',
    category: 'Hardware',
    warehouse: 'Assembly Hub',
    quantity: 160,
    available: 120,
    reserved: 40,
    reorderPoint: 180,
    leadTimeDays: 12,
    expiringLots: 0,
    averageCost: 3.40,
    suppliers: ['Axis Metals', 'Bolt & Nut Co.'],
    movements: [
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: MovementType.outbound,
        reference: 'Work Order WO-339',
        quantity: 50,
      ),
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: MovementType.transfer,
        reference: 'Transfer from Central Depot',
        quantity: 80,
      ),
    ],
  ),
  StockItem(
    name: 'Sealant Cartridge 500ml',
    sku: 'SEA-500-CC',
    category: 'Chemicals',
    warehouse: 'North Hub',
    quantity: 90,
    available: 70,
    reserved: 20,
    reorderPoint: 120,
    leadTimeDays: 8,
    expiringLots: 3,
    averageCost: 12.75,
    suppliers: ['Bonding Solutions Ltd.'],
    movements: [
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: MovementType.inbound,
        reference: 'Purchase Receipt #1825',
        quantity: 60,
      ),
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: MovementType.outbound,
        reference: 'Project Site Delivery',
        quantity: 40,
      ),
    ],
  ),
  StockItem(
    name: 'Industrial Gloves L',
    sku: 'PPE-GL-L',
    category: 'Safety',
    warehouse: 'Central Depot',
    quantity: 260,
    available: 240,
    reserved: 20,
    reorderPoint: 200,
    leadTimeDays: 4,
    expiringLots: 0,
    averageCost: 6.20,
    suppliers: ['ShieldPro Gear', 'Northline PPE'],
    movements: [
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: MovementType.outbound,
        reference: 'Dispatch to Warehouse B',
        quantity: 30,
      ),
      StockMovement(
        date: DateTime.now().subtract(const Duration(days: 7)),
        type: MovementType.inbound,
        reference: 'Purchase Receipt #1812',
        quantity: 200,
      ),
    ],
  ),
];

final List<WarehouseCapacity> warehouseCapacities = [
  const WarehouseCapacity(name: 'Central Depot', capacityUsed: 0.68),
  const WarehouseCapacity(name: 'North Hub', capacityUsed: 0.54),
  const WarehouseCapacity(name: 'Assembly Hub', capacityUsed: 0.82),
];

final List<StockTransfer> openTransfers = [
  const StockTransfer(
    itemName: 'HDPE Pipe 2"',
    source: 'Central Depot',
    destination: 'Site 11A',
    quantity: 50,
    status: 'Awaiting pickup',
  ),
  const StockTransfer(
    itemName: 'Sealant Cartridge 500ml',
    source: 'North Hub',
    destination: 'Assembly Hub',
    quantity: 30,
    status: 'Packing',
  ),
];

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
