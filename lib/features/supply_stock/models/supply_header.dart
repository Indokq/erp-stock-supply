import 'package:flutter/foundation.dart';

class SupplyHeader {
  final int supplyId;
  final String supplyNo;
  final DateTime supplyDate;

  // Parties
  final String fromId;
  final String fromOrg;
  final String toId;
  final String toOrg;

  // Order/Project
  final int orderId;
  final String orderNo;
  final String projectNo;
  final int orderSeqId;

  // Item summary (optional header-level hints)
  final String itemCode;
  final String itemName;
  final double? qty;
  final String orderUnit;
  final String lotNumber;
  final String heatNumber;
  final String size;

  // References/Notes
  final String refNo;
  final String remarks;

  // Template
  final int templateSts;
  final String templateName;

  // Audit
  final int preparedBy;
  final String prepared;
  final String approvedBy;
  final String approved;
  final String receivedBy;
  final String received;

  // Extra
  final int column1;

  const SupplyHeader({
    required this.supplyId,
    required this.supplyNo,
    required this.supplyDate,
    this.fromId = '',
    this.fromOrg = '',
    this.toId = '',
    this.toOrg = '',
    this.orderId = 0,
    this.orderNo = '',
    this.projectNo = '',
    this.orderSeqId = 0,
    this.itemCode = '',
    this.itemName = '',
    this.qty,
    this.orderUnit = '',
    this.lotNumber = '',
    this.heatNumber = '',
    this.size = '',
    this.refNo = '',
    this.remarks = '',
    this.templateSts = 0,
    this.templateName = '',
    this.preparedBy = 0,
    this.prepared = '',
    this.approvedBy = '',
    this.approved = '',
    this.receivedBy = '',
    this.received = '',
    this.column1 = 0,
  });

  SupplyHeader copyWith({
    int? supplyId,
    String? supplyNo,
    DateTime? supplyDate,
    String? fromId,
    String? fromOrg,
    String? toId,
    String? toOrg,
    int? orderId,
    String? orderNo,
    String? projectNo,
    int? orderSeqId,
    String? itemCode,
    String? itemName,
    double? qty,
    String? orderUnit,
    String? lotNumber,
    String? heatNumber,
    String? size,
    String? refNo,
    String? remarks,
    int? templateSts,
    String? templateName,
    int? preparedBy,
    String? prepared,
    String? approvedBy,
    String? approved,
    String? receivedBy,
    String? received,
    int? column1,
  }) {
    return SupplyHeader(
      supplyId: supplyId ?? this.supplyId,
      supplyNo: supplyNo ?? this.supplyNo,
      supplyDate: supplyDate ?? this.supplyDate,
      fromId: fromId ?? this.fromId,
      fromOrg: fromOrg ?? this.fromOrg,
      toId: toId ?? this.toId,
      toOrg: toOrg ?? this.toOrg,
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      projectNo: projectNo ?? this.projectNo,
      orderSeqId: orderSeqId ?? this.orderSeqId,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      orderUnit: orderUnit ?? this.orderUnit,
      lotNumber: lotNumber ?? this.lotNumber,
      heatNumber: heatNumber ?? this.heatNumber,
      size: size ?? this.size,
      refNo: refNo ?? this.refNo,
      remarks: remarks ?? this.remarks,
      templateSts: templateSts ?? this.templateSts,
      templateName: templateName ?? this.templateName,
      preparedBy: preparedBy ?? this.preparedBy,
      prepared: prepared ?? this.prepared,
      approvedBy: approvedBy ?? this.approvedBy,
      approved: approved ?? this.approved,
      receivedBy: receivedBy ?? this.receivedBy,
      received: received ?? this.received,
      column1: column1 ?? this.column1,
    );
  }

  factory SupplyHeader.fromJson(Map<String, dynamic> json) {
    // Accept both API variants: From_ID vs FromID, To_ID vs ToID, etc.
    String _str(dynamic v) => (v ?? '').toString();
    int _int(dynamic v) => v is int ? v : int.tryParse(_str(v)) ?? 0;
    double? _dblN(dynamic v) {
      final s = _str(v);
      if (s.isEmpty) return null;
      return double.tryParse(s);
    }

    return SupplyHeader(
      supplyId: _int(json['Supply_ID']),
      supplyNo: _str(json['Supply_No']),
      supplyDate: DateTime.tryParse(_str(json['Supply_Date'])) ?? DateTime.now(),
      fromId: _str(json['From_ID'] ?? json['FromID']),
      fromOrg: _str(json['From_Org']),
      toId: _str(json['To_ID'] ?? json['ToID']),
      toOrg: _str(json['To_Org']),
      orderId: _int(json['Order_ID']),
      orderNo: _str(json['Order_No']),
      projectNo: _str(json['Project_No']),
      orderSeqId: _int(json['OrderSeq_ID']),
      itemCode: _str(json['Item_Code']),
      itemName: _str(json['Item_Name']),
      qty: _dblN(json['Qty']),
      orderUnit: _str(json['OrderUnit']),
      lotNumber: _str(json['Lot_Number']),
      heatNumber: _str(json['Heat_Number']),
      size: _str(json['Size']),
      refNo: _str(json['Ref_No']),
      remarks: _str(json['Remarks']),
      templateSts: _int(json['Template_Sts']),
      templateName: _str(json['Template_Name']),
      preparedBy: _int(json['Prepared_By']),
      prepared: _str(json['Prepared']),
      approvedBy: _str(json['Approved_By']),
      approved: _str(json['Approved']),
      receivedBy: _str(json['Received_By']),
      received: _str(json['Received']),
      column1: _int(json['Column1']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Supply_ID": supplyId,
      "Supply_No": supplyNo,
      "Supply_Date": supplyDate.toIso8601String(),
      "From_ID": fromId,
      "From_Org": fromOrg,
      "To_ID": toId,
      "To_Org": toOrg,
      "Order_ID": orderId,
      "Order_No": orderNo,
      "Project_No": projectNo,
      "OrderSeq_ID": orderSeqId,
      "Item_Code": itemCode,
      "Item_Name": itemName,
      "Qty": qty,
      "OrderUnit": orderUnit,
      "Lot_Number": lotNumber,
      "Heat_Number": heatNumber,
      "Size": size,
      "Ref_No": refNo,
      "Remarks": remarks,
      "Template_Sts": templateSts,
      "Template_Name": templateName,
      "Prepared_By": preparedBy,
      "Prepared": prepared,
      "Approved_By": approvedBy,
      "Approved": approved,
      "Received_By": receivedBy,
      "Received": received,
      "Column1": column1,
    };
  }

  @override
  String toString() {
    return 'SupplyHeader(supplyId: $supplyId, supplyNo: $supplyNo, date: $supplyDate, from: $fromId, to: $toId)';
  }
}