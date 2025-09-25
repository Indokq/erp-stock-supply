class SupplyDetailItem {
  String itemCode;
  String itemName;
  double qty;
  String unit;
  String lotNumber;
  String heatNumber;
  String description;

  SupplyDetailItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.lotNumber,
    required this.heatNumber,
    required this.description,
  });

  SupplyDetailItem copyWith({
    String? itemCode,
    String? itemName,
    double? qty,
    String? unit,
    String? lotNumber,
    String? heatNumber,
    String? description,
  }) {
    return SupplyDetailItem(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      lotNumber: lotNumber ?? this.lotNumber,
      heatNumber: heatNumber ?? this.heatNumber,
      description: description ?? this.description,
    );
  }
}

