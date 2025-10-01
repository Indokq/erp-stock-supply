import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'movement_type.dart';
import 'stock_models.dart';

/// Mock data generator for large dataset testing
class MockDataGenerator {
  static final List<String> _productNames = [
    'HDPE Pipe', 'Steel Fastener', 'Sealant Cartridge', 'Industrial Gloves',
    'Copper Wire', 'PVC Fitting', 'Safety Helmet', 'Welding Rod',
    'Drill Bit Set', 'Measuring Tape', 'Cable Tie', 'Junction Box',
    'Motor Oil', 'Bearing Unit', 'Gasket Ring', 'Filter Element',
    'Pressure Gauge', 'Control Valve', 'Hose Assembly', 'Pump Impeller',
    'Electrical Switch', 'Transformer', 'Circuit Breaker', 'Conduit Pipe',
    'Insulation Material', 'Adhesive Tape', 'Cleaning Solvent', 'Lubricant Spray',
    'Safety Goggles', 'Work Boots', 'Coveralls', 'Hard Hat',
    'Fire Extinguisher', 'First Aid Kit', 'Warning Sign', 'Traffic Cone',
    'Tool Box', 'Wrench Set', 'Screwdriver Kit', 'Pliers Set',
  ];

  static final List<String> _categories = [
    'Pipes', 'Hardware', 'Chemicals', 'Safety', 'Electrical',
    'Tools', 'Maintenance', 'PPE', 'Automotive', 'Construction'
  ];

  static final List<String> _warehouses = [
    'Central Depot', 'North Hub', 'Assembly Hub', 'South Branch',
    'East Facility', 'West Storage', 'Downtown Center', 'Industrial Park'
  ];

  static final List<String> _suppliers = [
    'Blue River Plastics', 'PolySupply Co.', 'Axis Metals', 'Bolt & Nut Co.',
    'Bonding Solutions Ltd.', 'ShieldPro Gear', 'Northline PPE', 'TechFlow Industries',
    'Precision Parts Inc.', 'Global Components', 'Prime Materials', 'Elite Supplies',
    'Advanced Systems', 'Quality First', 'Reliable Resources', 'Premier Products'
  ];

  /// Generates a list of mock stock items for big data testing
  static List<StockItem> generateBigDataSet({int count = 10000}) {
    final items = <StockItem>[];
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < count; i++) {
      final productIndex = (i * 7 + random) % _productNames.length;
      final categoryIndex = (i * 11 + random) % _categories.length;
      final warehouseIndex = (i * 13 + random) % _warehouses.length;

      final baseQuantity = 50 + (i * 17 + random) % 500;
      final reserved = (i * 3 + random) % 50;
      final available = baseQuantity - reserved;
      final reorderPoint = (baseQuantity * 0.3).round() + (i * 5 + random) % 50;

      items.add(StockItem(
        name: '${_productNames[productIndex]} ${_generateSize(i)}',
        sku: _generateSKU(productIndex, i),
        category: _categories[categoryIndex],
        warehouse: _warehouses[warehouseIndex],
        quantity: baseQuantity,
        available: available,
        reserved: reserved,
        reorderPoint: reorderPoint,
        leadTimeDays: 3 + (i * 7 + random) % 15,
        expiringLots: (i * 19 + random) % 4,
        averageCost: (5.0 + (i * 23 + random) % 200) / 10.0,
        suppliers: _generateSuppliers(i),
        movements: _generateMovements(i),
      ));
    }

    return items;
  }

  static String _generateSize(int index) {
    final sizes = ['XS', 'S', 'M', 'L', 'XL', '1"', '2"', '3"', '4"', '6"', '8mm', '12mm', '16mm', '20mm', '25mm'];
    return sizes[(index * 31) % sizes.length];
  }

  static String _generateSKU(int productIndex, int itemIndex) {
    final prefix = _productNames[productIndex].split(' ').map((word) => word.substring(0, 2).toUpperCase()).join('');
    return '$prefix-${(itemIndex + 1000).toString().padLeft(4, '0')}';
  }

  static List<String> _generateSuppliers(int index) {
    final count = 1 + (index * 7) % 3; // 1-3 suppliers
    final suppliers = <String>[];
    for (int i = 0; i < count; i++) {
      suppliers.add(_suppliers[(index * 11 + i * 13) % _suppliers.length]);
    }
    return suppliers.toSet().toList(); // Remove duplicates
  }

  static List<StockMovement> _generateMovements(int index) {
    final count = (index * 5) % 4; // 0-3 movements
    final movements = <StockMovement>[];
    final types = MovementType.values;

    for (int i = 0; i < count; i++) {
      movements.add(StockMovement(
        date: DateTime.now().subtract(Duration(days: 1 + (index * 7 + i * 3) % 30)),
        type: types[(index * 13 + i * 7) % types.length],
        reference: _generateReference(index, i),
        quantity: 10 + (index * 17 + i * 11) % 100,
      ));
    }

    return movements;
  }

  static String _generateReference(int index, int movementIndex) {
    final prefixes = ['SO', 'PO', 'WO', 'TR', 'ADJ', 'RET'];
    final prefix = prefixes[(index * 7 + movementIndex * 11) % prefixes.length];
    final number = (index * 23 + movementIndex * 31 + 1000) % 9999;
    return '$prefix-${number.toString().padLeft(4, '0')}';
  }
}

final List<QuickAction> quickActions = const [
  QuickAction(
    label: 'STOCK SUPPLY',
    icon: Icons.inventory_2_rounded,
    color: AppColors.primaryBlue,
  ),
  QuickAction(
    label: 'STOCK ADJUSTMENT',
    icon: Icons.sync_alt_rounded,
    color: AppColors.primaryBlue,
  ),
  QuickAction(
    label: 'STOCK LIST',
    icon: Icons.list_alt_rounded,
    color: AppColors.primaryBlue,
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

// Generate big dataset for testing
final List<StockItem> bigDataStockItems = MockDataGenerator.generateBigDataSet(count: 10000);

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
