import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'create_supply_page.dart' as create_supply;
import 'models/supply_detail_item.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
import '../shared/services/auth_service.dart';

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
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyOrderController = TextEditingController();
  final _heatNoController = TextEditingController();

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

  // Extra columns
  final _column1Controller = TextEditingController();

  // Detail state
  final TextEditingController _searchController = TextEditingController();
  List<SupplyDetailItem> _detailItems = [];

  // Column meta (optional)
  final Map<String, _ColumnMeta> _columnMeta = {};

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
    // Show names instead of IDs
    _supplyFromId = header.fromId.isNotEmpty ? header.fromId : null;
    _supplyToId = header.toId.isNotEmpty ? header.toId : null;
    _supplyFromController.text = header.fromOrg.isNotEmpty ? header.fromOrg : header.fromId;
    _supplyToController.text = header.toOrg.isNotEmpty ? header.toOrg : header.toId;
    _refNoController.text = header.refNo;
    _remarksController.text = header.remarks;
    _templateNameController.text = header.templateName;
    // Audit
    _preparedByController.text = header.preparedBy.toString();
    _preparedController.text = header.prepared;
    _approvedByController.text = header.approvedBy;
    _approvedController.text = header.approved;
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
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
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
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
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
            _approvedByController.text = selected['id'] ?? '';
            _approvedController.text = selected['name'] ?? '';
          } else if (field == 'Received') {
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

      SupplyDetailItem _mapRow(Map<String, dynamic> r) {
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
          const ['Lot_Number', 'LotNo', 'Lot'],
          partialMatches: const ['lot'],
        ) ?? '';
        final heatNumber = _getStringValue(
          r,
          const ['Heat_Number', 'HeatNo', 'Heat'],
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

        return SupplyDetailItem(
          itemCode: itemCode,
          itemName: itemName,
          qty: _toDouble(qtyStr),
          unit: unit,
          lotNumber: lotNumber,
          heatNumber: heatNumber,
          description: description,
          size: size,
        );
      }

      final items = rows.map(_mapRow).toList();
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
              mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
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
    // Order/project
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

    // Item related
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
    // Omitted OrderUnit and Lot_Number from edit view; keep UI minimal
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

  Future<void> _browseItemStock(int index) async {
    try {
      final result = await ApiService.browseItemStockByLot(id: 12, companyId: 1);
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
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Pilih Item Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      final code = _getStringValue(r, const ['Item_Code', 'Code', 'SKU'], partialMatches: const ['code', 'sku']) ?? '';
                      final name = _getStringValue(r, const ['Item_Name', 'Name', 'Title', 'Description'], partialMatches: const ['name', 'title', 'desc']) ?? '';
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

      if (!mounted || selected == null) return;
      setState(() {
        final code = _getStringValue(selected, const ['Item_Code', 'Code', 'SKU'], partialMatches: const ['code', 'sku']) ?? '';
        final name = _getStringValue(selected, const ['Item_Name', 'Name', 'Title', 'Description'], partialMatches: const ['name', 'title', 'desc']) ?? '';
        final lot = _getStringValue(selected, const ['Lot_Number', 'LotNo', 'Lot'], partialMatches: const ['lot']) ?? '';
        final heat = _getStringValue(selected, const ['Heat_Number', 'HeatNo', 'Heat'], partialMatches: const ['heat']) ?? '';

        final current = _detailItems[index];
        _detailItems[index] = SupplyDetailItem(
          itemCode: code.isNotEmpty ? code : current.itemCode,
          itemName: name.isNotEmpty ? name : current.itemName,
          qty: current.qty,
          unit: current.unit,
          lotNumber: lot.isNotEmpty ? lot : current.lotNumber,
          heatNumber: heat.isNotEmpty ? heat : current.heatNumber,
          description: current.description,
          size: current.size,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error browse item: $e'), backgroundColor: Colors.redAccent),
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
      ));
    });
  }

  void _removeDetailItem(int index) {
    if (widget.readOnly) return;
    setState(() => _detailItems.removeAt(index));
  }

  Future<void> _saveAll() async {
    if (widget.readOnly) {
      Navigator.pop(context);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    // TODO: Call backend save for header + details (update)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Header & Details saved (stub)'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context, true);
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
              onPressed: _saveAll,
              child: const Text(
                'SAVE',
                style: TextStyle(
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
                                                  readOnly: true,
                                                  decoration: _inputDecoration(
                                                    'Supply Number',
                                                    readOnly: true,
                                                  ),
                                                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                                                ),
                                              ),
                                            if (_isVisible('Supply Number') && _isVisible('Supply Date'))
                                              const SizedBox(width: 16),
                                            if (_isVisible('Supply Date'))
                                              Expanded(
                                                child: InkWell(
                                                  onTap: _selectDate,
                                                  child: InputDecorator(
                                                    decoration: _inputDecoration(
                                                      'Supply Date',
                                                      readOnly: true,
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
                                                  onTap: () => _pickWarehouse(isFrom: true),
                                                  decoration: _inputDecoration(
                                                    'Supply From',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.unfold_more_rounded),
                                                      onPressed: () => _pickWarehouse(isFrom: true),
                                                    ),
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
                                                  onTap: () => _pickWarehouse(isFrom: false),
                                                  decoration: _inputDecoration(
                                                    'Supply To',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.unfold_more_rounded),
                                                      onPressed: () => _pickWarehouse(isFrom: false),
                                                    ),
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
                                                  onTap: _browseOrderEntryItem,
                                                  decoration: _inputDecoration(
                                                    'Order No.',
                                                    readOnly: true,
                                                  ).copyWith(
                                                    suffixIcon: IconButton(
                                                      icon: const Icon(Icons.unfold_more_rounded),
                                                      onPressed: _browseOrderEntryItem,
                                                    ),
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
                                      // Removed Unit and Size to match order confirmation
                                      // Removed Lot No to match desired columns
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
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SectionHeader(title: 'Detail'),
                                if (!widget.readOnly)
                                  IconButton(
                                    onPressed: _addDetailItem,
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Add Item',
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                isDense: true,
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
                                    Row(
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
                                              onDelete: widget.readOnly ? null : () => _removeDetailItem(entry.key),
                                              readOnly: widget.readOnly,
                                              onBrowse: widget.readOnly ? null : () => _browseItemStock(entry.key),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Total Item: ${_detailItems.length}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 32),
                                          Text(
                                            'Total Qty: ${_detailItems.fold<double>(0, (sum, item) => sum + item.qty).toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
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
