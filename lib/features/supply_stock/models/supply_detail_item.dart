class SupplyDetailItem {
  String itemCode;
  String itemName;
  double qty;
  String unit;
  String lotNumber;
  String heatNumber;
  String description;
  String size;

  SupplyDetailItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.lotNumber,
    required this.heatNumber,
    required this.description,
    this.size = '',
  });

  SupplyDetailItem copyWith({
    String? itemCode,
    String? itemName,
    double? qty,
    String? unit,
    String? lotNumber,
    String? heatNumber,
    String? description,
    String? size,
  }) {
    return SupplyDetailItem(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      lotNumber: lotNumber ?? this.lotNumber,
      heatNumber: heatNumber ?? this.heatNumber,
      description: description ?? this.description,
      size: size ?? this.size,
    );
  }
}
