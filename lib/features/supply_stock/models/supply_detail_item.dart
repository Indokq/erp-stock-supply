class SupplyDetailItem {
  String itemCode;
  String itemName;
  double qty;
  String unit;
  String lotNumber;
  String heatNumber;
  String description;
  String size;
  int? itemId;
  String seqId;
  int? unitId;
  Map<String, dynamic>? raw;

  SupplyDetailItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.lotNumber,
    required this.heatNumber,
    required this.description,
    this.size = '',
    this.itemId,
    this.seqId = '0',
    this.unitId,
    this.raw,
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
    int? itemId,
    String? seqId,
    int? unitId,
    Map<String, dynamic>? raw,
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
      itemId: itemId ?? this.itemId,
      seqId: seqId ?? this.seqId,
      unitId: unitId ?? this.unitId,
      raw: raw ?? this.raw,
    );
  }
}
