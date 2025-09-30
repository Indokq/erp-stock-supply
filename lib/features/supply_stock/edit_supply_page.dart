import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'create_supply_page.dart' as create_supply;
import 'models/supply_detail_item.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/barcode_scanner_service.dart';

class EditSupplyPage extends StatefulWidget {
  const EditSupplyPage({
    super.key,
    required this.header,
    required this.initialItems,
    this.columnMetaRows,
    this.readOnly = false,
  });

  final SupplyHeader header;
  final List<SupplyDetailItem> initialItems;
  final List<Map<String, dynamic>>? columnMetaRows;
  final bool readOnly;

  @override
  State<EditSupplyPage> createState() => _EditSupplyPageState();
}

class _EditSupplyPageState extends State<EditSupplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Header - General Information
  final _supplyIdController = TextEditingController();
  final _supplyNumberController = TextEditingController();
  final _supplyFromController = TextEditingController();
  final _supplyToController = TextEditingController();
  DateTime _supplyDate = DateTime.now();
  // Track selected warehouse IDs while showing names
  String? _supplyFromId;
  String? _supplyToId;

  // Order Information
  final _orderNoController = TextEditingController();
  final _projectNoController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _orderSeqIdController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyOrderController = TextEditingController();
  final _heatNoController = TextEditingController();
  final _orderUnitController = TextEditingController();
  final _sizeController = TextEditingController();
  final _lotNumberController = TextEditingController();

  // References / Template
  final _refNoController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _useTemplate = false;
  int _templateSts = 0;
  String _templateName = '';
  final _templateNameController = TextEditingController();

  // Audit
  final _preparedController = TextEditingController();
  final _approvedController = TextEditingController();
  final _receivedController = TextEditingController();
  final _preparedByController = TextEditingController();
  final _approvedByController = TextEditingController();
  final _receivedByController = TextEditingController();

  // Detail state
  final TextEditingController _searchController = TextEditingController();
  List<SupplyDetailItem> _detailItems = [];

  // Column meta (optional)
  final Map<String, _ColumnMeta> _columnMeta = {};

  int? _orderId;
  String? _orderSeqId;
  int _preparedById = 0;
  String _approvedById = '';
  String _receivedById = '';
  bool _isSaving = false;
  final Set<int> _deletingDetailIndexes = {};

  // Ensure some nested sections stay visible even when metadata is missing
  static const Set<String> _fallbackVisibleCols = {
    'Signature Information',
    'Prepared',
    'Approved',
    'Received',
  };

  bool _isVisible(String colName, {bool defaultVisible = true}) {
    final m = _columnMeta[colName];
    if (m == null) {
      return defaultVisible || _fallbackVisibleCols.contains(colName);
    }
    if (m.colVisible == 1) {
      return true;
    }
    return _fallbackVisibleCols.contains(colName);
  }

  bool _isReadOnly(String colName, {bool defaultReadOnly = false}) {
    if (widget.readOnly) return true;
    final m = _columnMeta[colName];
    if (m == null) return defaultReadOnly;
    final edit = m.colEdit.trim();
    if (edit.isEmpty) return false;
    if (edit.startsWith('Text*@')) return true;
    if (edit.startsWith('List@') || edit.startsWith('List*@')) return false; // editable in edit mode
    return false;
  }

  InputDecoration _inputDecoration(String label, {required bool readOnly}) {
    return const InputDecoration().copyWith(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: readOnly ? AppColors.readOnlyYellow : AppColors.surfaceCard,
    );
  }

  String _formatDateDdMmmYyyy(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dd = d.day.toString().padLeft(2, '0');
    final mmm = months[d.month - 1];
    final yyyy = d.year.toString();
    return '$dd-$mmm-$yyyy';
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9-]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  dynamic _getFirstValue(
    Map<String, dynamic> data,
    List<String> keys, {
    List<String> partialMatches = const [],
  }) {
    if (data.isEmpty) return null;

    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    for (final partialKey in partialMatches) {
      for (final key in data.keys) {
        if (key.toLowerCase().contains(partialKey.toLowerCase())) {
          return data[key];
        }
      }
    }

    return null;
  }

  int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parsed = int.tryParse(text);
    if (parsed != null) return parsed;

    final doubleVal = double.tryParse(text);
    if (doubleVal != null) return doubleVal.toInt();

    return null;
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromHeader(widget.header);
    _detailItems = List.of(widget.initialItems);
    if (widget.columnMetaRows != null) {
      _columnMeta
        ..clear()
        ..addEntries(
          widget.columnMetaRows!
              .map((e) => _ColumnMeta.fromJson(e))
              .map((m) => MapEntry(m.colName, m)),
        );
    }
    // If no initial details provided, fetch from API
    if (_detailItems.isEmpty) {
      _loadSupplyDetails();
    }
  }

  @override
  void dispose() {
    _supplyIdController.dispose();
    _supplyNumberController.dispose();
    _supplyFromController.dispose();
    _supplyToController.dispose();
    _orderNoController.dispose();
    _projectNoController.dispose();
    _orderIdController.dispose();
    _orderSeqIdController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _qtyOrderController.dispose();
    _heatNoController.dispose();
    _orderUnitController.dispose();
    _sizeController.dispose();
    _lotNumberController.dispose();
    _refNoController.dispose();
    _remarksController.dispose();
    _templateNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _hydrateFromHeader(SupplyHeader header) {
    _supplyIdController.text = header.supplyId.toString();
    _supplyNumberController.text = header.supplyNo;
    _supplyDate = header.supplyDate;

    _supplyFromId = header.fromId.isNotEmpty ? header.fromId : null;
    _supplyToId = header.toId.isNotEmpty ? header.toId : null;
    _supplyFromController.text = header.fromOrg.isNotEmpty ? header.fromOrg : header.fromId;
    _supplyToController.text = header.toOrg.isNotEmpty ? header.toOrg : header.toId;

    _orderId = header.orderId == 0 ? null : header.orderId;
    _orderSeqId = header.orderSeqId == 0 ? null : header.orderSeqId.toString();
    _orderIdController.text = _orderId?.toString() ?? '';
    _orderSeqIdController.text = _orderSeqId ?? '';
    if (header.orderNo.isNotEmpty) _orderNoController.text = header.orderNo;
    if (header.projectNo.isNotEmpty) _projectNoController.text = header.projectNo;
    if (header.itemCode.isNotEmpty) _itemCodeController.text = header.itemCode;
    if (header.itemName.isNotEmpty) _itemNameController.text = header.itemName;
    if (header.qty != null && header.qty! > 0) {
      _qtyOrderController.text = header.qty!.toString();
    }
    if (header.heatNumber.isNotEmpty) _heatNoController.text = header.heatNumber;
    if (header.orderUnit.isNotEmpty) _orderUnitController.text = header.orderUnit;
    if (header.size.isNotEmpty) _sizeController.text = header.size;
    if (header.lotNumber.isNotEmpty) _lotNumberController.text = header.lotNumber;

    _refNoController.text = header.refNo;
    _remarksController.text = header.remarks;
    _templateNameController.text = header.templateName;
    _templateName = header.templateName;
    _templateSts = header.templateSts;
    _useTemplate = header.templateSts == 1;

    _preparedById = header.preparedBy;
    _preparedByController.text = header.preparedBy.toString();
    _preparedController.text = header.prepared;

    _approvedById = header.approvedBy;
    _approvedByController.text = header.approvedBy;
    _approvedController.text = header.approved;

    _receivedById = header.receivedBy;
    _receivedByController.text = header.receivedBy;
    _receivedController.text = header.received;

    setState(() {});
  }

  Future<void> _pickWarehouse({required bool isFrom}) async {
    if (widget.readOnly) return;
    try {
      final result = await ApiService.browseWarehouses(companyId: 1);
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to browse warehouses'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final data = result['data'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> rows = [];

      // Collect rows from typical tbl buckets
      for (var i = 0; i < 10; i++) {
        final key = 'tbl' + i.toString();
        final list = data[key];
        if (list is List) {
          for (final r in list) {
            if (r is Map) {
              final m = r.cast<String, dynamic>();
              if (m.containsKey('Org_Name')) {
                rows.add(m);
              }
            }
          }
        }
      }

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No warehouses found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final TextEditingController searchCtrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.of(rows);
          return StatefulBuilder(
            builder: (context, setModalState) {
              void applyFilter(String q) {
                final query = q.trim().toLowerCase();
                setModalState(() {
                  if (query.isEmpty) {
                    filtered = List.of(rows);
                  } else {
                    filtered = rows.where((m) {
                      final name = (m['Org_Name'] ?? '').toString().toLowerCase();
                      final code = (m['Org_Code'] ?? '').toString().toLowerCase();
                      return name.contains(query) || code.contains(query);
                    }).toList();
                  }
                });
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warehouse_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFrom ? 'Select Supply From' : 'Select Supply To',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        onChanged: applyFilter,
                        decoration: const InputDecoration(
                          hintText: 'Search warehouse by name or code...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final m = filtered[index];
                            final name = (m['Org_Name'] ?? '').toString();
                            final code = (m['Org_Code'] ?? '').toString();
                            final id = (m['ID'] ?? '').toString();
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(name),
                              subtitle: code.isNotEmpty ? Text(code) : null,
                              onTap: () => Navigator.pop<Map<String, dynamic>>(context, {
                                'id': id,
                                'name': name,
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted) return;
      if (selected != null) {
        setState(() {
          if (isFrom) {
            _supplyFromId = selected['id']?.toString();
            _supplyFromController.text = selected['name']?.toString() ?? '';
          } else {
            _supplyToId = selected['id']?.toString();
            _supplyToController.text = selected['name']?.toString() ?? '';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading warehouses: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickEmployee({required String field}) async {
    if (widget.readOnly) return;
    try {
      final result = await ApiService.browseEmployees(companyId: 1);
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to browse employees'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final data = result['data'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> rows = [];

      for (var i = 0; i < 10; i++) {
        final key = 'tbl' + i.toString();
        final list = data[key];
        if (list is List) {
          for (final r in list) {
            if (r is Map) rows.add(r.cast<String, dynamic>());
          }
        }
      }

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No employees found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String _pickName(Map<String, dynamic> m) {
        for (final k in const [
          'Employee_Name', 'EmployeeName', 'Name', 'Description', 'FullName', 'Nama',
        ]) {
          final v = m[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return 'Employee';
      }

      String _pickCode(Map<String, dynamic> m) {
        for (final k in const [
          'Employee_Code', 'EmployeeCode', 'Code', 'NIK', 'EmpCode',
        ]) {
          final v = m[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return '';
      }

      String _pickId(Map<String, dynamic> m) {
        for (final k in const ['Employee_ID', 'EmployeeId', 'ID']) {
          final v = m[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return '';
      }

      final selected = await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final TextEditingController searchCtrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.of(rows);
          void applyFilter(String q) {
            final qq = q.toLowerCase();
            filtered = rows.where((m) {
              final name = _pickName(m).toLowerCase();
              final code = _pickCode(m).toLowerCase();
              return name.contains(qq) || code.contains(qq);
            }).toList();
          }
          return StatefulBuilder(
            builder: (context, setModal) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_search_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select $field',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setModal(() => applyFilter(v)),
                        decoration: const InputDecoration(
                          hintText: 'Search by name or code...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final m = filtered[index];
                            final name = _pickName(m);
                            final code = _pickCode(m);
                            final id = _pickId(m);
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.person_outline_rounded),
                              title: Text(name),
                              subtitle: code.isNotEmpty ? Text(code) : null,
                              onTap: () => Navigator.pop<Map<String, String>>(context, {
                                'id': id,
                                'name': name,
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted) return;
      if (selected != null) {
        setState(() {
          if (field == 'Approved') {
            _approvedById = selected['id'] ?? '';
            _approvedByController.text = selected['id'] ?? '';
            _approvedController.text = selected['name'] ?? '';
          } else if (field == 'Received') {
            _receivedById = selected['id'] ?? '';
            _receivedByController.text = selected['id'] ?? '';
            _receivedController.text = selected['name'] ?? '';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading employees: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loadSupplyDetails() async {
    try {
      final user = AuthService.currentUser ?? 'admin';
      final result = await ApiService.getSupplyDetail(
        supplyCls: 1,
        supplyId: widget.header.supplyId,
        userEntry: user,
        companyId: 1,
      );
      if (result['success'] != true) {
        // Feedback but keep UI usable
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Failed to load details'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final data = result['data'];
      if (data is! Map<String, dynamic>) return;
      // Use tbl1 for detail rows; avoid tbl0 (column metadata)
      final list = data['tbl1'];
      final rows = (list is List)
          ? list
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
          : <Map<String, dynamic>>[];
      if (rows.isEmpty) return;

      double _toDouble(String? s) {
        if (s == null || s.trim().isEmpty) return 0;
        return double.tryParse(s.replaceAll(',', '')) ?? 0;
      }

      SupplyDetailItem _mapRow(Map<String, dynamic> r, int index) {
        final itemCode = _getStringValue(
          r,
          const ['Item_Code', 'ItemCode', 'Code', 'SKU'],
          partialMatches: const ['itemcode', 'code', 'sku'],
        ) ?? '';
        final itemName = _getStringValue(
          r,
          const ['Item_Name', 'ItemName', 'Name', 'Title', 'Description'],
          partialMatches: const ['itemname', 'name', 'title', 'desc'],
        ) ?? '';
        final qtyStr = _getStringValue(
          r,
          const ['Qty', 'Qty_Order', 'Quantity'],
          partialMatches: const ['qty', 'quantity'],
        );
        final unit = _getStringValue(
          r,
          const ['OrderUnit', 'Unit', 'UOM'],
          partialMatches: const ['unit', 'uom'],
        ) ?? '';
        final lotNumber = _getStringValue(
          r,
          const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
          partialMatches: const ['lot'],
        ) ?? '';
        final heatNumber = _getStringValue(
          r,
          const ['Heat_No', 'HeatNo', 'Heat_Number', 'Heat'],
          partialMatches: const ['heat'],
        ) ?? '';
        final size = _getStringValue(
          r,
          const ['Size', 'Item_Size'],
          partialMatches: const ['size'],
        ) ?? '';
        final description = _getStringValue(
          r,
          const ['Description', 'Remark', 'Notes'],
          partialMatches: const ['description', 'remark', 'notes', 'desc'],
        ) ?? '';
        final seqCandidate = _getStringValue(
          r,
          const ['Seq_ID', 'SeqId', 'Sequence', 'Seq'],
          partialMatches: const ['seq'],
        );
        final itemIdValue = _extractIntValue(
          r,
          const ['Item_ID', 'ItemId', 'ItemID', 'Item_Id', 'Item_Index', 'ItemIDX', 'ItemIdx', 'ID'],
          partialMatches: const ['itemid', 'item_idx', 'itemindex'],
        );
        final unitIdValue = _extractIntValue(
          r,
          const ['Unit_ID', 'UnitId', 'UnitID', 'UOM_ID'],
          partialMatches: const ['unitid', 'uomid'],
        );

        return SupplyDetailItem(
          itemCode: itemCode,
          itemName: itemName,
          qty: _toDouble(qtyStr),
          unit: unit,
          lotNumber: lotNumber,
          heatNumber: heatNumber,
          description: description,
          size: size,
          itemId: itemIdValue,
          seqId: (seqCandidate != null && seqCandidate.trim().isNotEmpty)
              ? seqCandidate.trim()
              : (index + 1).toString(),
          unitId: unitIdValue,
          raw: Map<String, dynamic>.from(r),
        );
      }

      final items = <SupplyDetailItem>[];
      for (var i = 0; i < rows.length; i++) {
        items.add(_mapRow(rows[i], i));
      }
      if (!mounted) return;
      setState(() {
        _detailItems = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- ORDER ENTRY PICKER ---
  String _stringifyValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String? _getStringValue(
    Map<String, dynamic> data,
    List<String> keys, {
    List<String> partialMatches = const [],
  }) {
    for (final key in keys) {
      final v = data[key];
      if (v != null && _stringifyValue(v).trim().isNotEmpty) {
        return _stringifyValue(v).trim();
      }
    }
    if (partialMatches.isNotEmpty) {
      for (final entry in data.entries) {
        final k = entry.key.toLowerCase();
        if (partialMatches.any((p) => k.contains(p.toLowerCase()))) {
          final v = entry.value;
          if (v != null && _stringifyValue(v).trim().isNotEmpty) {
            return _stringifyValue(v).trim();
          }
        }
      }
    }
    return null;
  }

  int? _extractIntValue(
    Map<String, dynamic>? data,
    List<String> keys, {
    List<String> partialMatches = const [],
  }) {
    if (data == null) return null;
    final value = _getStringValue(data, keys, partialMatches: partialMatches);
    if (value == null || value.isEmpty) return null;
    return _tryParseInt(value);
  }

  bool _rawHasSupplyContext(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return false;
    for (final key in raw.keys) {
      final normalized = key.toString().toLowerCase();
      if (normalized.contains('supply_id') || normalized.contains('supplydetail')) {
        return true;
      }
    }
    return false;
  }

  String _resolveSeqId(SupplyDetailItem item, int fallbackIndex) {
    final hasSupplyContext = _rawHasSupplyContext(item.raw);
    final seq = item.seqId.trim();
    if (hasSupplyContext) {
      if (seq.isNotEmpty && seq != '0') return seq;
      final fromRaw = _getStringValue(
        item.raw!,
        const ['Seq_ID', 'SeqId', 'Sequence', 'Seq', 'Seq_ID_Detail'],
        partialMatches: const ['seq'],
      );
      if (fromRaw != null && fromRaw.trim().isNotEmpty) {
        return fromRaw.trim();
      }
    }
    // For new rows (no supply context) always use "0" so backend inserts instead of updating
    return '0';
  }

  int? _resolveItemId(SupplyDetailItem item) {
    if (item.itemId != null && item.itemId! > 0) return item.itemId;
    final fromRaw = _extractIntValue(
      item.raw,
      const ['Item_ID', 'ItemId', 'ItemID', 'Item_Id', 'Item_Index', 'ItemIDX', 'ItemIdx'],
      partialMatches: const ['itemid', 'item_idx', 'itemindex'],
    );
    if (fromRaw != null) return fromRaw;
    return _tryParseInt(item.itemCode);
  }

  int? _resolveUnitId(SupplyDetailItem item) {
    if (item.unitId != null && item.unitId! > 0) return item.unitId;
    return _extractIntValue(
      item.raw,
      const ['Unit_ID', 'UnitId', 'UnitID', 'UOM_ID', 'Unit_Index'],
      partialMatches: const ['unitid', 'uomid', 'unit_index'],
    );
  }

  SupplyDetailItem _mergeDetailItemFromStock({
    required SupplyDetailItem current,
    required Map<String, dynamic> primaryData,
    Map<String, dynamic>? fallbackRaw,
  }) {
    String? resolveValue(List<String> keys, {List<String> partialMatches = const []}) {
      final primary = _getStringValue(primaryData, keys, partialMatches: partialMatches);
      if (primary != null && primary.trim().isNotEmpty) {
        return primary.trim();
      }
      if (fallbackRaw == null) return null;
      final fallback = _getStringValue(fallbackRaw!, keys, partialMatches: partialMatches);
      if (fallback == null) return null;
      final trimmed = fallback.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }

    final combinedRaw = <String, dynamic>{};
    if (fallbackRaw != null) {
      combinedRaw.addAll(fallbackRaw);
    }
    combinedRaw.addAll(primaryData);

    final itemCode = resolveValue(
      const ['Item_Code', 'ItemCode', 'Code', 'SKU'],
      partialMatches: const ['itemcode', 'kode', 'code', 'sku'],
    );
    final itemName = resolveValue(
      const [
        'Item_Name',
        'ItemName',
        'Name',
        'Description',
        'colName',
        'colname',
        'ColName',
        'Colname',
      ],
      partialMatches: const ['itemname', 'description', 'colname'],
    );
    final lot = resolveValue(
      const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
      partialMatches: const ['lot', 'batch'],
    );
    final heat = resolveValue(
      const ['Heat_No', 'HeatNo', 'Heat_Number'],
      partialMatches: const ['heat', 'heatno'],
    );
    final unit = resolveValue(
      const ['Unit', 'UOM', 'OrderUnit', 'Unit_Stock'],
      partialMatches: const ['unit', 'uom', 'stockunit'],
    );
    final size = resolveValue(
      const ['Size', 'Item_Size', 'colSize', 'colsize', 'ColSize'],
      partialMatches: const ['size', 'dimension'],
    );
    final qtyString = resolveValue(
      const ['Qty', 'Quantity', 'Qty_Available', 'Qty_Order', 'Balance', 'Stock'],
      partialMatches: const ['qty', 'quantity', 'balance', 'stock'],
    );
    final description = resolveValue(
      const ['Description', 'Desc', 'Remark', 'Remarks', 'Notes'],
      partialMatches: const ['desc', 'remark', 'remarks', 'notes'],
    );
    final parsedQty = qtyString != null
        ? double.tryParse(qtyString.replaceAll(',', '.'))
        : null;

    final itemId = _extractIntValue(
      combinedRaw,
      const ['Item_ID', 'ItemId', 'ItemID', 'Item_Id', 'ID'],
      partialMatches: const ['itemid', 'stockid', 'id'],
    );
    final unitId = _extractIntValue(
      combinedRaw,
      const ['Unit_ID', 'UnitId', 'UnitID', 'UOM_ID', 'Unit_Stock'],
      partialMatches: const ['unitid', 'uomid', 'unitstock'],
    );

    final seqCandidate = _getStringValue(
      combinedRaw,
      const ['Seq_ID', 'SeqId', 'Sequence', 'Seq', 'Seq_ID_Detail'],
      partialMatches: const ['seq'],
    );

    final seqId = _rawHasSupplyContext(combinedRaw)
        ? ((seqCandidate != null && seqCandidate.trim().isNotEmpty) ? seqCandidate.trim() : current.seqId)
        : current.seqId;

    return current.copyWith(
      itemCode: itemCode?.isNotEmpty == true ? itemCode : current.itemCode,
      itemName: itemName?.isNotEmpty == true ? itemName : current.itemName,
      lotNumber: lot?.isNotEmpty == true ? lot : current.lotNumber,
      heatNumber: heat?.isNotEmpty == true ? heat : current.heatNumber,
      unit: unit?.isNotEmpty == true ? unit : current.unit,
      size: size?.isNotEmpty == true ? size : current.size,
      qty: parsedQty ?? current.qty,
      description: description?.isNotEmpty == true ? description : current.description,
      seqId: seqId,
      itemId: itemId ?? current.itemId,
      unitId: unitId ?? current.unitId,
      raw: combinedRaw.isEmpty ? current.raw : combinedRaw,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStockMatchesByBarcode({
    required int warehouseId,
    required String code,
  }) async {
    final dateStr = _supplyDate.toIso8601String().split('T').first;
    final result = await ApiService.browseItemStockByLot(
      id: warehouseId,
      companyId: 1,
      dateStart: dateStr,
      dateEnd: dateStr,
    );

    if (result['success'] != true) {
      final message = result['message']?.toString() ?? 'Tidak dapat memuat data item stock';
      throw Exception(message);
    }

    final data = result['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Data item stock tidak tersedia');
    }

    final rows = _extractRows(data);
    if (rows.isEmpty) {
      return const [];
    }

    final normalized = code.trim().toLowerCase();
    final numericCode = _tryParseInt(code);

    var matches = rows.where((row) {
      final rowCode = _getStringValue(
        row,
        const ['Item_Code', 'ItemCode', 'Code', 'SKU', 'Barcode', 'Bar_Code'],
        partialMatches: const ['itemcode', 'kode', 'barcode', 'code', 'sku'],
      );
      final lot = _getStringValue(
        row,
        const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
        partialMatches: const ['lot', 'batch'],
      );
      final numericId = _extractIntValue(
        row,
        const ['Item_ID', 'ItemId', 'ID'],
        partialMatches: const ['itemid', 'stockid', 'id'],
      );

      final codeMatches = rowCode != null && rowCode.trim().toLowerCase() == normalized;
      final lotMatches = lot != null && lot.trim().toLowerCase() == normalized;
      final idMatches = numericCode != null && numericId != null && numericId == numericCode;

      return codeMatches || lotMatches || idMatches;
    }).map((row) => row.map((key, value) => MapEntry(key.toString(), value))).toList();

    if (matches.isEmpty) {
      matches = rows.where((row) {
        final rowCode = _getStringValue(
          row,
          const ['Item_Code', 'ItemCode', 'Code', 'SKU'],
          partialMatches: const ['itemcode', 'kode', 'code', 'sku'],
        );
        if (rowCode == null) return false;
        return rowCode.trim().toLowerCase().contains(normalized);
      }).map((row) => row.map((key, value) => MapEntry(key.toString(), value))).toList();
    }

    return matches;
  }

  Future<Map<String, dynamic>?> _showScanMatchesSelectionSheet({
    required List<Map<String, dynamic>> matches,
    required String scannedCode,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Hasil scan "$scannedCode"',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final row = matches[index];
                      final codeValue = _getStringValue(
                        row,
                        const ['Item_Code', 'ItemCode', 'Code', 'SKU'],
                        partialMatches: const ['itemcode', 'kode', 'code', 'sku'],
                      );
                      final name = _getStringValue(
                        row,
                        const [
                          'Item_Name',
                          'ItemName',
                          'Name',
                          'Description',
                          'colName',
                          'colname',
                          'ColName',
                          'Colname',
                        ],
                        partialMatches: const ['itemname', 'description', 'colname'],
                      );
                      final lot = _getStringValue(
                        row,
                        const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
                        partialMatches: const ['lot', 'batch'],
                      );
                      final qty = _getStringValue(
                        row,
                        const ['Qty', 'Quantity', 'Qty_Available', 'Qty_Order', 'Balance', 'Stock'],
                        partialMatches: const ['qty', 'quantity', 'balance', 'stock'],
                      );

                      final subtitleParts = <String>[];
                      if (lot != null && lot.isNotEmpty) subtitleParts.add('Lot: $lot');
                      if (qty != null && qty.isNotEmpty) subtitleParts.add('Qty: $qty');

                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryBlue),
                        title: Text(
                          name?.isNotEmpty == true ? name! : (codeValue ?? 'Item ${index + 1}'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(sheetContext).pop(row),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: matches.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _extractSupplyIdFromResponse(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;
    final tbl0 = payload['tbl0'];
    if (tbl0 is List && tbl0.isNotEmpty) {
      final first = tbl0.first;
      if (first is Map) {
        final map = first.cast<String, dynamic>();
        final candidates = [map['Supply_ID'], map['SupplyId'], map['ID']];
        for (final candidate in candidates) {
          final parsed = _tryParseInt(candidate);
          if (parsed != null) return parsed;
        }
        final resultMsg = map['Result']?.toString();
        if (resultMsg != null) {
          final match = RegExp(r'(?:ID|Supply_ID)\s*[:=]\s*(\d+)').firstMatch(resultMsg);
          if (match != null) {
            final parsed = _tryParseInt(match.group(1));
            if (parsed != null) return parsed;
          }
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _extractRows(Map<String, dynamic> payload) {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < 12; i++) {
      final key = 'tbl$i';
      final list = payload[key];
      if (list is List) {
        for (final r in list) {
          if (r is Map) rows.add(r.cast<String, dynamic>());
        }
      }
    }
    return rows;
  }

  Future<void> _browseOrderEntryItem() async {
    try {
      final browseResult = await ApiService.browseOrderEntryItems(
        dateStart: '2020-01-01',
        dateEnd: '2025-12-31',
        companyId: 1,
      );

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Failed to load order entries';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) return;
      final rawItems = _extractRows(data);
      // Only keep entries that have a non-empty Order No
      final items = rawItems.where((row) {
        final orderNo = _getStringValue(
          row,
          const ['Order_No', 'OrderNo', 'No_Order', 'Order_Number'],
          partialMatches: const ['orderno', 'noorder', 'order', 'number'],
        );
        return (orderNo != null && orderNo.isNotEmpty);
      }).toList();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No order entries found'), backgroundColor: Colors.orange),
        );
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.assignment_outlined),
                      SizedBox(width: 8),
                      Text('Select Order Entry', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = items[index];
                      final orderNo = _getStringValue(
                        row,
                        const ['Order_No', 'OrderNo', 'No_Order', 'Order_Number'],
                        partialMatches: const ['orderno', 'noorder', 'order', 'number'],
                      );
                      final projectNo = _getStringValue(
                        row,
                        const ['Project_No', 'ProjectNo', 'No_Project', 'Project_Number'],
                        partialMatches: const ['projectno', 'noproject', 'project', 'number'],
                      );
                      final description = _getStringValue(
                        row,
                        const ['Description', 'Remark', 'Notes'],
                        partialMatches: const ['description', 'remark', 'notes', 'desc'],
                      );
                      final title = orderNo!;
                      final subtitle = [
                        if (projectNo != null && projectNo.isNotEmpty) 'Project: $projectNo',
                        if (description != null && description.isNotEmpty) description,
                      ].join(' • ');

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.assignment), backgroundColor: Color(0xFFEAF2FF)),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle, style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(sheetContext).pop(row),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || selected == null) return;
      _applyOrderEntrySelection(selected);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order entries: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _applyOrderEntrySelection(Map<String, dynamic> data) {
    final orderNo = _getStringValue(
      data,
      const ['Order_No', 'OrderNo', 'No_Order', 'Order_Number'],
      partialMatches: const ['orderno', 'noorder', 'order', 'number'],
    );
    final projectNo = _getStringValue(
      data,
      const ['Project_No', 'ProjectNo', 'No_Project', 'Project_Number'],
      partialMatches: const ['projectno', 'noproject', 'project', 'number'],
    );
    if (orderNo != null) _orderNoController.text = orderNo;
    if (projectNo != null) _projectNoController.text = projectNo;

    final orderIdStr = _getStringValue(
      data,
      const ['Order_ID', 'OrderId', 'ID_Order', 'ID'],
      partialMatches: const ['orderid', 'idorder'],
    );
    final seqIdStr = _getStringValue(
      data,
      const ['Seq_ID', 'SeqId', 'Order_Seq', 'Sequence'],
      partialMatches: const ['seq', 'sequence'],
    );
    final parsedOrderId = _tryParseInt(orderIdStr);
    if (parsedOrderId != null) {
      _orderId = parsedOrderId;
    }
    if (seqIdStr != null && seqIdStr.isNotEmpty) {
      _orderSeqId = seqIdStr;
    }

    final itemCode = _getStringValue(
      data,
      const ['Item_Code', 'ItemCode', 'Code', 'SKU'],
      partialMatches: const ['itemcode', 'code', 'sku'],
    );
    final itemName = _getStringValue(
      data,
      const ['Item_Name', 'ItemName', 'Name', 'Title'],
      partialMatches: const ['itemname', 'name', 'title'],
    );
    final qtyOrder = _getStringValue(
      data,
      const ['Qty', 'Qty_Order', 'Quantity'],
      partialMatches: const ['qty', 'quantity'],
    );
    final heatNumber = _getStringValue(
      data,
      const ['Heat_Number', 'HeatNo', 'Heat'],
      partialMatches: const ['heat'],
    );

    if (itemCode != null) _itemCodeController.text = itemCode;
    if (itemName != null) _itemNameController.text = itemName;
    if (qtyOrder != null) _qtyOrderController.text = qtyOrder;
    if (heatNumber != null) _heatNoController.text = heatNumber;

    setState(() {});
  }

  Future<void> _editDetailItem(int index) async {
    if (widget.readOnly) return;
    if (index < 0 || index >= _detailItems.length) return;

    final currentItem = _detailItems[index];

    final editedItem = await showModalBottomSheet<SupplyDetailItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Edit Detail Item',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: EditDetailForm(
                      initialItem: currentItem,
                      onSave: (editedItem) => Navigator.pop(sheetContext, editedItem),
                      onCancel: () => Navigator.pop(sheetContext),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (editedItem != null) {
      setState(() {
        _detailItems[index] = editedItem;
      });
    }
  }

  Future<void> _browseItemStock(int index) async {
    try {
      final fromId = _tryParseInt(_supplyFromId) ?? _tryParseInt(widget.header.fromId) ?? 0;
      if (fromId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih gudang From terlebih dahulu'), backgroundColor: Colors.orange),
        );
        return;
      }
      final dateStr = _supplyDate.toIso8601String().split('T').first;
      final result = await ApiService.browseItemStockByLot(
        id: fromId,
        companyId: 1,
        dateStart: dateStr,
        dateEnd: dateStr,
      );
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal load item stock'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      final data = result['data'];
      if (data is! Map<String, dynamic>) return;
      final list = data['tbl1'];
      final rows = (list is List)
          ? list
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
          : <Map<String, dynamic>>[];
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data item stock kosong'), backgroundColor: Colors.orange),
        );
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          final TextEditingController searchCtrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.of(rows);

          void applyFilter(String q) {
            final query = q.trim().toLowerCase();
            filtered = query.isEmpty
                ? List.of(rows)
                : rows.where((r) {
                    final code = _getStringValue(
                      r,
                      const ['Item_Code', 'ItemCode', 'Code', 'SKU', 'colCode', 'ColCode'],
                      partialMatches: const ['itemcode', 'code', 'sku'],
                    );
                    final name = _getStringValue(
                      r,
                      const ['Item_Name','ItemName','Name','Description','colName','colname','ColName','Colname','colName1','colname1','Column1','Column_1'],
                      partialMatches: const ['itemname','description','colname','namestock','namabarang'],
                    );
                    final lot = _getStringValue(
                      r,
                      const ['Lot_No','LotNo','Lot_Number','Lot'],
                      partialMatches: const ['lot','batch'],
                    );
                    return (code ?? '').toLowerCase().contains(query) ||
                           (name ?? '').toLowerCase().contains(query) ||
                           (lot ?? '').toLowerCase().contains(query);
                  }).toList();
          }

          return StatefulBuilder(
            builder: (context, setModal) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pilih Item Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                          if (!widget.readOnly)
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              tooltip: 'Scan QR Code',
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _scanQRForDetailItem(index);
                              },
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setModal(() { applyFilter(v); }),
                        decoration: const InputDecoration(
                          hintText: 'Cari berdasarkan Item Code...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = filtered[i];
                          final code = _getStringValue(r, const ['Item_Code', 'ItemCode', 'Code', 'SKU', 'colCode', 'ColCode'], partialMatches: const ['itemcode', 'code', 'sku']) ?? '';
                          final name = _getStringValue(r, const ['Item_Name', 'ItemName', 'Name', 'Title', 'Description'], partialMatches: const ['itemname', 'name', 'title', 'desc']) ?? '';
                          final lot = _getStringValue(r, const ['Lot_Number', 'LotNo', 'Lot'], partialMatches: const ['lot']) ?? '';
                          final heat = _getStringValue(r, const ['Heat_Number', 'HeatNo', 'Heat'], partialMatches: const ['heat']) ?? '';
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(name.isNotEmpty ? name : code),
                            subtitle: [
                              if (code.isNotEmpty) 'Code: $code',
                              if (lot.isNotEmpty) 'Lot: $lot',
                              if (heat.isNotEmpty) 'Heat: $heat',
                            ].join(' • ').isEmpty
                                ? null
                                : Text([
                                    if (code.isNotEmpty) 'Code: $code',
                                    if (lot.isNotEmpty) 'Lot: $lot',
                                    if (heat.isNotEmpty) 'Heat: $heat',
                                  ].join(' • ')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(sheetContext).pop(r),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (!mounted || selected == null) return;
      final selectionRaw = Map<String, dynamic>.from(selected);
      final updated = _mergeDetailItemFromStock(
        current: _detailItems[index],
        primaryData: selectionRaw,
      );
      setState(() {
        _detailItems[index] = updated;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error browse item: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _scanQRForDetailItem(int index) async {
    if (widget.readOnly) return;

    final fromId = _tryParseInt(_supplyFromId) ?? _tryParseInt(widget.header.fromId) ?? 0;
    if (fromId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gudang From terlebih dahulu sebelum scan barcode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scanResult = await BarcodeScannerService.instance.scanBarcode();
    if (scanResult.isCanceled) {
      return;
    }
    if (!scanResult.isSuccess) {
      final message = scanResult.message;
      if (message != null && message.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final scannedCode = scanResult.barcode!.trim();
    if (scannedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode tidak terbaca.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final matches = await _fetchStockMatchesByBarcode(
        warehouseId: fromId,
        code: scannedCode,
      );

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barang dengan barcode "$scannedCode" tidak ditemukan di gudang ini.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Map<String, dynamic>? chosen;
      if (matches.length == 1) {
        chosen = matches.first;
      } else {
        chosen = await _showScanMatchesSelectionSheet(
          matches: matches,
          scannedCode: scannedCode,
        );
        if (!mounted || chosen == null) {
          return;
        }
      }

      final selectionRaw = Map<String, dynamic>.from(chosen!);
      final updated = _mergeDetailItemFromStock(
        current: _detailItems[index],
        primaryData: selectionRaw,
      );
      if (!mounted) return;
      setState(() {
        _detailItems[index] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "${updated.itemCode}" berhasil diisi dari barcode.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses barcode: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _supplyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _supplyDate = picked);
    }
  }

  void _addDetailItem() {
    if (widget.readOnly) return;
    setState(() {
      _detailItems.add(SupplyDetailItem(
        itemCode: '',
        itemName: '',
        qty: 0,
        unit: '',
        lotNumber: '',
        heatNumber: '',
        description: '',
        size: '',
        seqId: '0',
      ));
    });
  }

  Future<void> _removeDetailItem(int index) async {
    if (widget.readOnly) return;
    if (index < 0 || index >= _detailItems.length) return;

    final item = _detailItems[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final title = item.itemName.isNotEmpty ? item.itemName : item.itemCode;
        return AlertDialog(
          title: const Text('Hapus detail?'),
          content: Text(
            title.isNotEmpty
                ? 'Detail "$title" akan dihapus. Lanjutkan?'
                : 'Detail akan dihapus. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('HAPUS'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final supplyIdText = _supplyIdController.text.trim();
    final supplyId = _tryParseInt(supplyIdText) ?? widget.header.supplyId;
    final seqId = item.seqId.trim();

    // Unsaved row (no seq or seq == 0) can be removed locally
    if (seqId.isEmpty || seqId == '0' || supplyId <= 0) {
      setState(() => _detailItems.removeAt(index));

      // Check if all detail items are deleted
      if (_detailItems.isEmpty) {
        // Navigate to blank create supply page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _deleteHeaderAndNavigateToBlank();
        });
        return; // Exit early, don't show success message
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Detail dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    setState(() => _deletingDetailIndexes.add(index));

    final currentUser = AuthService.currentUser;
    final userEntry = (currentUser != null && currentUser.trim().isNotEmpty)
        ? currentUser.trim()
        : 'admin';

    try {
      final result = await ApiService.deleteSupply(
        supplyId: supplyId,
        seqId: seqId,
      );

      if (result['success'] != true) {
        final message = result['message']?.toString() ?? 'Gagal menghapus detail';
        throw Exception(message);
      }

      setState(() => _detailItems.removeAt(index));

      // Check if all detail items are deleted
      if (_detailItems.isEmpty) {
        // Navigate to blank create supply page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _deleteHeaderAndNavigateToBlank();
        });
        return; // Exit early, don't show success message
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Detail berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus detail: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingDetailIndexes.remove(index));
      }
    }
  }

  Future<void> _deleteHeaderAndNavigateToBlank() async {
    final supplyIdText = _supplyIdController.text.trim();
    final supplyId = _tryParseInt(supplyIdText) ?? widget.header.supplyId;

    if (supplyId <= 0) {
      _navigateToBlankCreatePage();
      return;
    }

    try {
      // Delete the header since all details are removed
      final result = await ApiService.deleteSupply(supplyId: supplyId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Header deleted: All detail items were removed'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final message = result['message']?.toString() ?? 'Failed to delete header';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting header: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    // Always navigate to blank page regardless of delete result
    _navigateToBlankCreatePage();
  }

  void _navigateToBlankCreatePage() {
    // Navigate to blank create supply page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const create_supply.CreateSupplyPage(),
      ),
    );
  }

  Future<void> _validateStockAvailability(List<Map<String, dynamic>> detailsPayload, int fromId) async {
    if (fromId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warehouse From tidak valid untuk validasi stock.'),
          backgroundColor: AppColors.error,
        ),
      );
      throw Exception('Invalid warehouse');
    }

    for (int i = 0; i < detailsPayload.length; i++) {
      final detail = detailsPayload[i];
      final itemId = detail['itemId'] as int;
      final requestedQty = detail['qty'] as double;
      final lotNumber = detail['lotNumber'] as String;
      final heatNumber = detail['heatNumber'] as String;

      debugPrint('🔍 Checking stock for itemId: $itemId, lot: "$lotNumber", heat: "$heatNumber", requestedQty: $requestedQty');

      try {
        final dateStr = _supplyDate.toIso8601String().split('T').first;
        final stockResult = await ApiService.browseItemStockByLot(
          id: fromId,
          companyId: 1,
          dateStart: dateStr,
          dateEnd: dateStr,
        );

        if (stockResult['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengecek stock untuk item ke-${i+1}. Header tidak akan disimpan.'),
              backgroundColor: AppColors.error,
            ),
          );
          throw Exception('Stock check failed');
        }

        final stockData = stockResult['data'];
        if (stockData is! Map<String, dynamic>) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data stock tidak tersedia untuk validasi item ke-${i+1}. Header tidak akan disimpan.'),
              backgroundColor: AppColors.error,
            ),
          );
          throw Exception('Stock data unavailable');
        }

        final stockItems = _extractRows(stockData);
        
        debugPrint('📋 Total stock items from API: ${stockItems.length}');
        debugPrint('🔎 Looking for: ItemID=$itemId, Lot="$lotNumber", Heat="$heatNumber"');
        
        // Log all available items for debugging
        if (stockItems.isEmpty) {
          debugPrint('⚠️ WARNING: No stock items returned from API for warehouse $fromId');
        } else {
          debugPrint('📦 Available items in stock:');
          for (var idx = 0; idx < stockItems.length && idx < 5; idx++) {
            final si = stockItems[idx];
            final siId = _parseIntValue(_getFirstValue(si, const ['Item_ID', 'ItemId', 'ID'], partialMatches: const ['itemid', 'stockid', 'id']));
            final siLot = _getStringValue(si, const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'], partialMatches: const ['lot', 'batch']) ?? '';
            final siHeat = _getStringValue(si, const ['Heat_No', 'HeatNo', 'Heat_Number'], partialMatches: const ['heat', 'heatno']) ?? '';
            final siCode = _getStringValue(si, const ['Item_Code', 'ItemCode', 'Code'], partialMatches: const ['itemcode', 'code']) ?? '';
            debugPrint('  [$idx] ID=$siId, Code="$siCode", Lot="$siLot", Heat="$siHeat"');
          }
          if (stockItems.length > 5) {
            debugPrint('  ... and ${stockItems.length - 5} more items');
          }
        }

        final matchingStock = stockItems.where((stockItem) {
          final stockItemId = _parseIntValue(_getFirstValue(
            stockItem,
            const ['Item_ID', 'ItemId', 'ID'],
            partialMatches: const ['itemid', 'stockid', 'id'],
          ));
          final stockLot = (_getStringValue(stockItem, const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'], partialMatches: const ['lot', 'batch']) ?? '').trim();
          final stockHeat = (_getStringValue(stockItem, const ['Heat_No', 'HeatNo', 'Heat_Number'], partialMatches: const ['heat', 'heatno']) ?? '').trim();

          final itemIdMatches = stockItemId == itemId;
          final lotMatches = lotNumber.isEmpty || stockLot.toLowerCase() == lotNumber.toLowerCase();
          final heatMatches = heatNumber.isEmpty || stockHeat.toLowerCase() == heatNumber.toLowerCase();
          
          debugPrint('  🔍 Item: stockId=$stockItemId vs $itemId, lot="$stockLot" vs "$lotNumber", heat="$stockHeat" vs "$heatNumber" → ${(itemIdMatches && lotMatches && heatMatches) ? "✓ MATCH" : "✗ NO MATCH"}');

          return itemIdMatches && lotMatches && heatMatches;
        }).toList();

        debugPrint('🎯 Matching stock items found: ${matchingStock.length}');

        if (matchingStock.isEmpty) {
          final itemCodeForMsg = _getStringValue(
            stockItems.where((si) {
              final sid = _parseIntValue(_getFirstValue(si, const ['Item_ID', 'ItemId', 'ID'], partialMatches: const ['itemid', 'stockid', 'id']));
              return sid == itemId;
            }).firstOrNull ?? {},
            const ['Item_Code', 'ItemCode', 'Code'],
            partialMatches: const ['itemcode', 'code'],
          ) ?? 'Item-$itemId';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item "$itemCodeForMsg" dengan Lot="$lotNumber", Heat="$heatNumber" tidak ditemukan di warehouse ini.\n'
                'Pastikan Lot dan Heat Number sesuai dengan stock yang tersedia.'
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
            ),
          );
          throw Exception('Item with specified lot/heat not found in stock');
        }

        // Calculate total available qty for this itemId + lot + heat combo
        double totalAvailableQty = 0.0;
        debugPrint('💰 Calculating total stock from ${matchingStock.length} matching item(s):');
        for (var idx = 0; idx < matchingStock.length; idx++) {
          final stockItem = matchingStock[idx];
          final qtyString = _getStringValue(
            stockItem,
            const ['Qty', 'Quantity', 'Qty_Available', 'Balance', 'Stock'],
            partialMatches: const ['qty', 'quantity', 'balance', 'stock'],
          );
          final qty = double.tryParse(qtyString?.replaceAll(',', '.') ?? '0') ?? 0.0;
          debugPrint('   [$idx] Raw qty string: "$qtyString" → Parsed: $qty');
          totalAvailableQty += qty;
        }

        debugPrint('📦 Total available stock: $totalAvailableQty, Requested: $requestedQty');
        debugPrint('🔢 Comparison: $totalAvailableQty < $requestedQty = ${totalAvailableQty < requestedQty}');

        if (totalAvailableQty < requestedQty) {
          final itemCode = _getStringValue(
            matchingStock.first,
            const ['Item_Code', 'ItemCode', 'Code'],
            partialMatches: const ['itemcode', 'code'],
          ) ?? 'Item-$itemId';

          final errorMsg = 'Stock tidak cukup untuk "$itemCode":\n'
              'Lot: "$lotNumber", Heat: "$heatNumber"\n'
              'Available: ${totalAvailableQty.toStringAsFixed(2)}\n'
              'Requested: ${requestedQty.toStringAsFixed(2)}';

          debugPrint('🚨 INSUFFICIENT STOCK DETECTED:');
          debugPrint('   Item: $itemCode');
          debugPrint('   Available: $totalAvailableQty');
          debugPrint('   Requested: $requestedQty');
          debugPrint('   Deficit: ${requestedQty - totalAvailableQty}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
            ),
          );
          
          debugPrint('🛑 Throwing exception: Insufficient stock');
          throw Exception('Insufficient stock for item $itemCode (available: $totalAvailableQty, requested: $requestedQty)');
        }

      } catch (e) {
        if (e.toString().contains('Insufficient stock') ||
            e.toString().contains('Stock check failed') ||
            e.toString().contains('Item not found') ||
            e.toString().contains('Invalid warehouse')) {
          rethrow;
        }
        debugPrint('❌ Error checking stock: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mengecek stock item ke-${i+1}: $e. Header tidak akan disimpan.'),
            backgroundColor: AppColors.error,
          ),
        );
        throw Exception('Stock validation error: $e');
      }
    }
  }

  Future<void> _saveAll() async {
    if (widget.readOnly) {
      Navigator.pop(context);
      return;
    }
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final currentUser = AuthService.currentUser;
    final userEntry = (currentUser != null && currentUser.trim().isNotEmpty)
        ? currentUser.trim()
        : 'admin';

    try {
      final supplyIdText = _supplyIdController.text.trim();
      var supplyId = _tryParseInt(supplyIdText) ?? widget.header.supplyId;

      final supplyNoInput = _supplyNumberController.text.trim();
      final supplyNo = supplyNoInput.isNotEmpty ? supplyNoInput : widget.header.supplyNo;
      final supplyDateFmt = _formatDateDdMmmYyyy(_supplyDate);

      final fromId = _tryParseInt(_supplyFromId) ?? _tryParseInt(widget.header.fromId) ?? 0;
      final toId = _tryParseInt(_supplyToId) ?? _tryParseInt(widget.header.toId) ?? 0;
      if (fromId == 0 || toId == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Warehouse asal dan tujuan harus dipilih'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final orderId = _orderId ?? widget.header.orderId;
      final orderSeq = (_orderSeqId != null && _orderSeqId!.trim().isNotEmpty)
          ? _orderSeqId!.trim()
          : (widget.header.orderSeqId == 0 ? '0' : widget.header.orderSeqId.toString());

      final refNo = _refNoController.text.trim();
      final remarks = _remarksController.text.trim();
      final templateNameInput = _templateNameController.text.trim();
      final templateName = templateNameInput.isNotEmpty ? templateNameInput : _templateName;
      final templateSts = _templateSts;

      int? preparedBy = _preparedById != 0 ? _preparedById : null;
      if (preparedBy == null) {
        preparedBy = _tryParseInt(_preparedByController.text.trim());
      }
      if (preparedBy == null && userEntry.toLowerCase() == 'admin') {
        preparedBy = 1;
      }
      final approvedBy = _approvedById.isNotEmpty
          ? _tryParseInt(_approvedById)
          : _tryParseInt(_approvedByController.text.trim());
      final receivedBy = _receivedById.isNotEmpty
          ? _tryParseInt(_receivedById)
          : _tryParseInt(_receivedByController.text.trim());

      // Prepare and validate details before saving
      final detailsToValidate = _detailItems
          .where((item) => item.itemCode.trim().isNotEmpty && item.qty > 0)
          .toList();

      if (detailsToValidate.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Tidak ada detail item yang valid. Header tidak akan disimpan.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final detailsPayload = <Map<String, dynamic>>[];
      for (final item in detailsToValidate) {
        final itemId = _resolveItemId(item);
        if (itemId == null || itemId == 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Item "${item.itemCode}" tidak memiliki ID yang valid. Header tidak akan disimpan.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        detailsPayload.add({
          'itemId': itemId,
          'qty': item.qty,
          'lotNumber': item.lotNumber.trim(),
          'heatNumber': item.heatNumber.trim(),
        });
      }
      // VALIDASI STOCK AVAILABILITY - DISABLED (allow negative stock)
      // debugPrint('🔵 START STOCK VALIDATION - Total items to validate: ${detailsPayload.length}');
      // try {
      //   await _validateStockAvailability(detailsPayload, fromId);
      //   debugPrint("✅ Stock validation passed - Proceeding to save header");
      // } catch (e) {
      //   debugPrint("❌ Stock validation FAILED: $e");
      //   debugPrint("🛑 STOPPING SAVE OPERATION - Header will NOT be saved");
      //   setState(() => _isSaving = false);
      //   return;
      // }
      debugPrint("⚠️ STOCK VALIDATION SKIPPED - Allowing save without stock check");

      final headerResult = await ApiService.saveSupplyHeader(
        supplyCls: 1,
        supplyId: supplyId,
        supplyNo: supplyNo.isNotEmpty ? supplyNo : 'AUTO',
        supplyDateDdMmmYyyy: supplyDateFmt,
        fromId: fromId,
        toId: toId,
        orderId: orderId,
        orderSeq: orderSeq.isNotEmpty ? orderSeq : '0',
        refNo: refNo,
        remarks: remarks,
        templateSts: templateSts,
        templateName: templateName,
        preparedBy: preparedBy,
        approvedBy: approvedBy,
        receivedBy: receivedBy,
        companyId: 1,
        userEntry: userEntry,
      );

      if (headerResult['success'] != true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(headerResult['message']?.toString() ?? 'Gagal menyimpan header'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final newId = _extractSupplyIdFromResponse(headerResult['data']);
      if (newId != null) {
        supplyId = newId;
        _supplyIdController.text = newId.toString();
      }

      final detailsToSave = _detailItems
          .where((item) => item.itemCode.trim().isNotEmpty && item.qty > 0)
          .toList();

      final List<String> detailErrors = [];
      var detailSaved = 0;

      for (var i = 0; i < detailsToSave.length; i++) {
        final item = detailsToSave[i];
        final seqId = _resolveSeqId(item, i);
        final itemId = _resolveItemId(item);
        if (itemId == null || itemId == 0) {
          detailErrors.add('Detail ${i + 1}: Item ID tidak ditemukan');
          continue;
        }
        final unitId = _resolveUnitId(item);

        final lotNumberToSend = item.lotNumber.trim();
        final heatNumberToSend = item.heatNumber.trim();
        
        debugPrint('💾 Saving detail ${i + 1}/${detailsToSave.length}:');
        debugPrint('   ItemCode: "${item.itemCode}"');
        debugPrint('   Qty: ${item.qty}');
        debugPrint('   LotNumber: "$lotNumberToSend" (length: ${lotNumberToSend.length})');
        debugPrint('   HeatNumber: "$heatNumberToSend" (length: ${heatNumberToSend.length})');

        final detailResult = await ApiService.saveSupplyDetail(
          supplyId: supplyId,
          seqId: seqId,
          itemId: itemId,
          qty: item.qty,
          unitId: unitId,
          lotNumber: lotNumberToSend,
          heatNumber: heatNumberToSend,
          size: item.size.trim(),
          description: item.description.trim(),
          userEntry: userEntry,
        );

        if (detailResult['success'] != true) {
          detailErrors.add('Detail ${i + 1}: ' + (detailResult['message']?.toString() ?? 'gagal disimpan'));
        } else {
          detailSaved++;
        }
      }

      if (detailErrors.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(detailErrors.first),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            detailSaved > 0 ? 'Header dan ${detailSaved} detail tersimpan' : 'Header tersimpan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ' + e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepared: use current logged-in user if available
    final currentUser = AuthService.currentUser;
    if (!widget.readOnly && currentUser != null && currentUser.isNotEmpty) {
      if (_preparedController.text != currentUser) {
        // reflect login user as preparer
        _preparedController.text = currentUser;
      }
    }
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(widget.readOnly ? 'View Stock Supply' : 'Edit Stock Supply'),
        actions: [
          if (!widget.readOnly) ...[
            TextButton(
              onPressed: _isSaving ? null : _saveAll,
              child: Text(
                _isSaving ? 'SAVING...' : 'SAVE',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card (mirrors CreateSupplyPage)
                    Card(
                      color: AppColors.surfaceCard,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Header'),
                            const SizedBox(height: 16),
                            if (_templateName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Template: “$_templateName”',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                            // General Information
                            ExpansionTile(
                              title: const Text(
                                'General Information',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              initiallyExpanded: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_isVisible('Supply Number') || _isVisible('Supply Date'))
                                        Row(
                                          children: [
                                            if (_isVisible('Supply Number'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _supplyNumberController,
                                                  readOnly: _isReadOnly('Supply Number'),
                                                  decoration: _inputDecoration(
                                                    'Supply Number',
                                                    readOnly: _isReadOnly('Supply Number'),
                                                  ),
                                                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                                                ),
                                              ),
                                            if (_isVisible('Supply Number') && _isVisible('Supply Date'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Supply Date'))
                                              Expanded(
                                                child: InkWell(
                                                  onTap: _isReadOnly('Supply Date') ? null : _selectDate,
                                                  child: InputDecorator(
                                                    decoration: _inputDecoration(
                                                      'Supply Date',
                                                      readOnly: _isReadOnly('Supply Date'),
                                                    ).copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 20)),
                                                    child: Text(
                                                      '${_supplyDate.day.toString().padLeft(2, '0')}-${_supplyDate.month.toString().padLeft(2, '0')}-${_supplyDate.year}',
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (_isVisible('Supply Number') || _isVisible('Supply Date')) const SizedBox(height: 16),

                                      if (_isVisible('Supply From') || _isVisible('Supply To'))
                                        Row(
                                          children: [
                                            if (_isVisible('Supply From'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _supplyFromController,
                                                  readOnly: true,
                                                  showCursor: false,
                                                  enableInteractiveSelection: false,
                                                  onTap: () => _pickWarehouse(isFrom: true),
                                                  decoration: _inputDecoration(
                                                    'Supply From',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: const Icon(Icons.warehouse_outlined),
                                                  ),
                                                ),
                                              ),
                                            if (_isVisible('Supply From') && _isVisible('Supply To'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Supply To'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _supplyToController,
                                                  readOnly: true,
                                                  showCursor: false,
                                                  enableInteractiveSelection: false,
                                                  onTap: () => _pickWarehouse(isFrom: false),
                                                  decoration: _inputDecoration(
                                                    'Supply To',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: const Icon(Icons.warehouse_outlined),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Order Information
                            ExpansionTile(
                              title: const Text(
                                'Order Information',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_isVisible('Order No.') || _isVisible('Project No.'))
                                        Row(
                                          children: [
                                            if (_isVisible('Order No.'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _orderNoController,
                                                  readOnly: true,
                                                  showCursor: false,
                                                  enableInteractiveSelection: false,
                                                  onTap: _browseOrderEntryItem,
                                                  decoration: _inputDecoration(
                                                    'Order No.',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: const Icon(Icons.assignment_outlined),
                                                  ),
                                                ),
                                              ),
                                            if (_isVisible('Order No.') && _isVisible('Project No.'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Project No.'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _projectNoController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Project No.',
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (_isVisible('Order No.') || _isVisible('Project No.')) const SizedBox(height: 16),
                                      // Removed Order ID / Seq ID to match desired columns
                                      const SizedBox(height: 16),
                                      if (_isVisible('Item Code') || _isVisible('Item Name'))
                                        Row(
                                          children: [
                                            if (_isVisible('Item Code'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _itemCodeController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Item Code',
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                            if (_isVisible('Item Code') && _isVisible('Item Name'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Item Name'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _itemNameController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Item Name',
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (_isVisible('Item Code') || _isVisible('Item Name')) const SizedBox(height: 16),
                                      if (_isVisible('Qty Order') || _isVisible('Heat No'))
                                        Row(
                                          children: [
                                            if (_isVisible('Qty Order'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _qtyOrderController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Qty Order',
                                                    readOnly: true,
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                ),
                                              ),
                                            if (_isVisible('Qty Order') && _isVisible('Heat No'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Heat No'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _heatNoController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Heat No',
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      const SizedBox(height: 16),
                                      if (_isVisible('Unit') || _isVisible('Size'))
                                        Row(
                                          children: [
                                            if (_isVisible('Unit'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _orderUnitController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration('Unit', readOnly: true),
                                                ),
                                              ),
                                            if (_isVisible('Unit') && _isVisible('Size')) const SizedBox(width: 16),
                                            if (_isVisible('Size'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _sizeController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration('Size', readOnly: true),
                                                ),
                                              ),
                                          ],
                                        ),
                                      const SizedBox(height: 16),
                                      if (_isVisible('Lot No'))
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _lotNumberController,
                                                readOnly: true,
                                                decoration: _inputDecoration('Lot No', readOnly: true),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // References / Template
                            ExpansionTile(
                              title: const Text(
                                'References / Template',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_isVisible('Reference No.') || _isVisible('Remarks'))
                                        Row(
                                          children: [
                                            if (_isVisible('Reference No.'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _refNoController,
                                                  readOnly: _isReadOnly('Reference No.'),
                                                  decoration: _inputDecoration(
                                                    'Reference No.',
                                                    readOnly: _isReadOnly('Reference No.'),
                                                  ),
                                                ),
                                              ),
                                            if (_isVisible('Reference No.') && _isVisible('Remarks'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Remarks'))
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _remarksController,
                                                  readOnly: _isReadOnly('Remarks'),
                                                  decoration: _inputDecoration(
                                                    'Remarks',
                                                    readOnly: _isReadOnly('Remarks'),
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (_isVisible('Save by template'))
                                        CheckboxListTile(
                                          value: _useTemplate,
                                          onChanged: _isReadOnly('Save by template')
                                              ? null
                                              : (v) {
                                                  setState(() {
                                                    _useTemplate = v ?? false;
                                                    _templateSts = _useTemplate ? 1 : 0;
                                                  });
                                                },
                                          dense: true,
                                          controlAffinity: ListTileControlAffinity.leading,
                                          title: const Text('Save by template'),
                                        ),
                                      if (_isVisible('Template Name'))
                                        TextFormField(
                                          controller: _templateNameController,
                                          readOnly: _isReadOnly('Template Name'),
                                          decoration: _inputDecoration(
                                            'Template Name',
                                            readOnly: _isReadOnly('Template Name'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Signature Information
                            if (_isVisible('Signature Information'))
                              ExpansionTile(
                                title: const Text(
                                  'Signature Information',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        if (_isVisible('Prepared'))
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _preparedController,
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Prepared',
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_isVisible('Prepared')) const SizedBox(height: 16),
                                        if (_isVisible('Approved'))
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _approvedController,
                                                  readOnly: true,
                                                  onTap: _isReadOnly('Approved') ? null : () => _pickEmployee(field: 'Approved'),
                                                  decoration: _inputDecoration(
                                                    'Approved',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.unfold_more_rounded),
                                                      onPressed: _isReadOnly('Approved')
                                                          ? null
                                                          : () => _pickEmployee(field: 'Approved'),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_isVisible('Approved')) const SizedBox(height: 16),
                                        if (_isVisible('Received'))
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _receivedController,
                                                  readOnly: true,
                                                  onTap: _isReadOnly('Received') ? null : () => _pickEmployee(field: 'Received'),
                                                  decoration: _inputDecoration(
                                                    'Received',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.unfold_more_rounded),
                                                      onPressed: _isReadOnly('Received')
                                                          ? null
                                                          : () => _pickEmployee(field: 'Received'),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Detail card (expandable + horizontal scroll)
                    Card(
                      child: ExpansionTile(
                        title: const Text(
                          'Detail Items',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        initiallyExpanded: true,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: widget.readOnly ? null : _addDetailItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 1224),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: const [
                                          SizedBox(
                                            width: 160,
                                            child: Text('Item Code', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 240,
                                            child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 80,
                                            child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 80,
                                            child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 160,
                                            child: Text('Lot Number', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 160,
                                            child: Text('Heat Number', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 240,
                                            child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          SizedBox(width: 48),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      children: [
                                        for (final entry in _detailItems.asMap().entries) ...[
                                          if (entry.key != 0) const SizedBox(height: 12),
                                          SizedBox(
                                            width: 1200,
                                            child: create_supply.DetailItemRow(
                                              key: ValueKey('detail_row_${entry.key}'),
                                              item: entry.value,
                                              onChanged: (updatedItem) {
                                                setState(() {
                                                  _detailItems[entry.key] = updatedItem;
                                                });
                                              },
                                              onDelete: widget.readOnly || _deletingDetailIndexes.contains(entry.key)
                                                  ? null
                                                  : () => _removeDetailItem(entry.key),
                                              readOnly: widget.readOnly,
                                              onBrowse: widget.readOnly ? null : () => _browseItemStock(entry.key),
                                              onEdit: widget.readOnly ? null : () => _editDetailItem(entry.key),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Text(
                                          'Total Item: ${_detailItems.length}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          'Total Qty: ${_detailItems.fold<double>(0, (sum, item) => sum + item.qty).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditDetailForm extends StatefulWidget {
  const EditDetailForm({
    super.key,
    required this.initialItem,
    required this.onSave,
    required this.onCancel,
  });

  final SupplyDetailItem initialItem;
  final ValueChanged<SupplyDetailItem> onSave;
  final VoidCallback onCancel;

  @override
  State<EditDetailForm> createState() => _EditDetailFormState();
}

class _EditDetailFormState extends State<EditDetailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemCodeController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _lotNumberController;
  late final TextEditingController _heatNumberController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _itemCodeController = TextEditingController(text: widget.initialItem.itemCode);
    _itemNameController = TextEditingController(text: widget.initialItem.itemName);
    _qtyController = TextEditingController(text: _formatQty(widget.initialItem.qty));
    _unitController = TextEditingController(text: widget.initialItem.unit);
    _lotNumberController = TextEditingController(text: widget.initialItem.lotNumber);
    _heatNumberController = TextEditingController(text: widget.initialItem.heatNumber);
    _descriptionController = TextEditingController(text: widget.initialItem.description);
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _lotNumberController.dispose();
    _heatNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == 0) return '';
    if ((qty - qty.roundToDouble()).abs() < 0.0001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceCard,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final editedItem = widget.initialItem.copyWith(
      itemCode: _itemCodeController.text.trim(),
      itemName: _itemNameController.text.trim(),
      qty: double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 0,
      unit: _unitController.text.trim(),
      lotNumber: _lotNumberController.text.trim(),
      heatNumber: _heatNumberController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    widget.onSave(editedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item Code and Item Name
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itemCodeController,
                  decoration: _decoration('Item Code'),
                  validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _itemNameController,
                  decoration: _decoration('Item Name'),
                  validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Qty and Unit
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  decoration: _decoration('Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty == true) return 'Required';
                    if (double.tryParse(value!.replaceAll(',', '.')) == null) {
                      return 'Invalid number';
                    }
                    if ((double.tryParse(value.replaceAll(',', '.')) ?? 0) <= 0) {
                      return 'Must be greater than 0';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _unitController,
                  decoration: _decoration('Unit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lot Number and Heat Number
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lotNumberController,
                  decoration: _decoration('Lot Number'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _heatNumberController,
                  decoration: _decoration('Heat Number'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: _decoration('Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ColumnMeta {
  final String colName;
  final int colVisible;
  final String colAlignment;
  final String colEdit;
  final int stsEdit;
  final int stsUpdate;
  final String colCombo;
  final String colData;

  _ColumnMeta({
    required this.colName,
    required this.colVisible,
    required this.colAlignment,
    required this.colEdit,
    required this.stsEdit,
    required this.stsUpdate,
    required this.colCombo,
    required this.colData,
  });

  factory _ColumnMeta.fromJson(Map<String, dynamic> json) {
    String _s(dynamic v) => (v ?? '').toString();
    int _i(dynamic v) {
      try {
        if (v == null) return 0;
        if (v is int) return v;
        return int.tryParse(v.toString()) ?? 0;
      } catch (_) {
        return 0;
      }
    }

    return _ColumnMeta(
      colName: _s(json['ColName']),
      colVisible: _i(json['ColVisible']),
      colAlignment: _s(json['ColAlignment']),
      colEdit: _s(json['ColEdit']),
      stsEdit: _i(json['StsEdit']),
      stsUpdate: _i(json['StsUpdate']),
      colCombo: _s(json['ColCombo']),
      colData: _s(json['ColData']),
    );
  }
}
