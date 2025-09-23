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

class SupplyStock {
  const SupplyStock({
    required this.supplyId,
    required this.supplyNo,
    required this.supplyDate,
    required this.fromId,
    required this.toId,
    required this.remarks,
    required this.templateName,
    required this.parent,
    required this.level,
    required this.stsEdit,
    required this.stsUpdate,
    required this.selected,
  });

  final int supplyId;
  final String supplyNo;
  final DateTime supplyDate;
  final String fromId;
  final String toId;
  final String remarks;
  final String templateName;
  final int parent;
  final int level;
  final int stsEdit;
  final int stsUpdate;
  final int selected;

  factory SupplyStock.fromJson(Map<String, dynamic> json) {
    return SupplyStock(
      supplyId: json['Supply_ID'] ?? 0,
      supplyNo: json['Supply_No'] ?? '',
      supplyDate: DateTime.tryParse(json['Supply_Date'] ?? '') ?? DateTime.now(),
      fromId: json['FromID'] ?? '',
      toId: json['ToID'] ?? '',
      remarks: json['Remarks'] ?? '',
      templateName: json['Template_Name'] ?? '',
      parent: json['Parent'] ?? 0,
      level: json['Level'] ?? 0,
      stsEdit: json['StsEdit'] ?? 0,
      stsUpdate: json['StsUpdate'] ?? 0,
      selected: json['Selected'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Supply_ID': supplyId,
      'Supply_No': supplyNo,
      'Supply_Date': supplyDate.toIso8601String(),
      'FromID': fromId,
      'ToID': toId,
      'Remarks': remarks,
      'Template_Name': templateName,
      'Parent': parent,
      'Level': level,
      'StsEdit': stsEdit,
      'StsUpdate': stsUpdate,
      'Selected': selected,
    };
  }
}
