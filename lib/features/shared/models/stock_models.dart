import 'movement_type.dart';

class StockItem {
  const StockItem({
    required this.name,
    required this.sku,
    required this.category,
    required this.warehouse,
    required this.quantity,
    required this.available,
    required this.reserved,
    required this.reorderPoint,
    required this.leadTimeDays,
    required this.expiringLots,
    required this.movements,
    required this.suppliers,
    required this.averageCost,
  });

  final String name;
  final String sku;
  final String category;
  final String warehouse;
  final int quantity;
  final int available;
  final int reserved;
  final int reorderPoint;
  final int leadTimeDays;
  final int expiringLots;
  final List<StockMovement> movements;
  final List<String> suppliers;
  final double averageCost;

  double get valuation => quantity * averageCost;
}

class StockMovement {
  const StockMovement({
    required this.date,
    required this.type,
    required this.reference,
    required this.quantity,
  });

  final DateTime date;
  final MovementType type;
  final String reference;
  final int quantity;
}

class WarehouseCapacity {
  const WarehouseCapacity({required this.name, required this.capacityUsed});

  final String name;
  final double capacityUsed;
}

class StockTransfer {
  const StockTransfer({
    required this.itemName,
    required this.source,
    required this.destination,
    required this.quantity,
    required this.status,
  });

  final String itemName;
  final String source;
  final String destination;
  final int quantity;
  final String status;
}
