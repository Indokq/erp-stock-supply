import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
import '../shared/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'models/supply_detail_item.dart';

class CreateSupplyPage extends StatefulWidget {
  const CreateSupplyPage({
    super.key,
    this.isEdit = false,
    this.initialHeader,
    this.columnMetaRows,
    this.initialDetailItems = const [],
  });

  final bool isEdit;
  final SupplyHeader? initialHeader;
  final List<Map<String, dynamic>>? columnMetaRows;
  final List<SupplyDetailItem> initialDetailItems;

  @override
  State<CreateSupplyPage> createState() => _CreateSupplyPageState();
}

class _CreateSupplyPageState extends State<CreateSupplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Header - General Information
  final _supplyIdController = TextEditingController();
  final _supplyNumberController = TextEditingController();
  final _supplyFromController = TextEditingController();
  final _supplyToController = TextEditingController();
  int? _fromWarehouseId;
  int? _toWarehouseId;
  // Removed From Org / To Org per requirement
  DateTime _supplyDate = DateTime.now();

  // Order Information
  final _orderIdController = TextEditingController();
  final _orderNoController = TextEditingController();
  final _projectNoController = TextEditingController();
  final _orderSeqIdController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyOrderController = TextEditingController();
  final _orderUnitController = TextEditingController();
  final _lotNumberController = TextEditingController();
  final _heatNoController = TextEditingController();
  final _sizeController = TextEditingController();

  // References/Notes
  final _refNoController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _useTemplate = false;
  String _templateName = '';
  final _templateNameController = TextEditingController();
  int _templateSts = 0;

  // Audit
  final _preparedByController = TextEditingController();
  final _preparedController = TextEditingController();
  final _approvedByController = TextEditingController();
  final _approvedController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _receivedController = TextEditingController();
  final _column1Controller = TextEditingController();

  // Employee IDs (for API submission)
  int _preparedById = 0;
  String _approvedById = '';
  String _receivedById = '';

  String _formatDateDdMmmYyyy(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dd = d.day.toString().padLeft(2, '0');
    final mmm = months[d.month - 1];
    final yyyy = d.year.toString();
    return '$dd-$mmm-$yyyy';
  }

  // Column metadata from API (tbl0)
  final Map<String, _ColumnMeta> _columnMeta = {};

  // Detail items maintained on the same page as the header
  List<SupplyDetailItem> _detailItems = [];

  // Some nested sections are expected to stay visible even when backend metadata is missing
  static const Set<String> _fallbackVisibleCols = {
    'Signature Information',
    'Prepared',
    'Approved',
    'Received',
  };

  bool _isVisible(String colName) {
    final m = _columnMeta[colName];
    if (m == null) {
      return _fallbackVisibleCols.contains(colName);
    }
    if (m.colVisible == 1) {
      return true;
    }
    return _fallbackVisibleCols.contains(colName);
  }

  SupplyDetailItem _cloneDetailItem(SupplyDetailItem item) {
    return SupplyDetailItem(
      itemCode: item.itemCode,
      itemName: item.itemName,
      qty: item.qty,
      unit: item.unit,
      lotNumber: item.lotNumber,
      heatNumber: item.heatNumber,
      description: item.description,
      size: item.size,
      itemId: item.itemId,
      seqId: item.seqId,
      unitId: item.unitId,
      raw: item.raw,
    );
  }

  SupplyDetailItem _createEmptyDetailItem() {
    return SupplyDetailItem(
      itemCode: '',
      itemName: '',
      qty: 0,
      unit: '',
      lotNumber: '',
      heatNumber: '',
      description: '',
      size: '',
      seqId: '0',
    );
  }

  void _addDetailItem() {
    setState(() {
      _detailItems = [..._detailItems, _createEmptyDetailItem()];
    });
  }

  void _updateDetailItem(int index, SupplyDetailItem updated) {
    if (index < 0 || index >= _detailItems.length) return;
    setState(() {
      _detailItems[index] = updated;
    });
  }

  void _removeDetailItem(int index) {
    if (index < 0 || index >= _detailItems.length) return;
    setState(() {
      _detailItems.removeAt(index);
      if (_detailItems.isEmpty) {
        _detailItems = [_createEmptyDetailItem()];
      }
    });
  }

  int get _totalDetailItemCount => _detailItems.length;

  double get _totalDetailQty => _detailItems.fold<double>(0, (sum, item) => sum + item.qty);

    void _hydrateFromHeader(SupplyHeader header) {
    _supplyIdController.text = header.supplyId.toString();
    _supplyNumberController.text = header.supplyNo;
    _supplyDate = header.supplyDate;
    _supplyFromController.text = header.fromId;
    _supplyToController.text = header.toId;
    _fromWarehouseId = int.tryParse(header.fromId);
    _toWarehouseId = int.tryParse(header.toId);
    _orderIdController.text = header.orderId.toString();
    _orderNoController.text = header.orderNo;
    _projectNoController.text = header.projectNo;
    _orderSeqIdController.text = header.orderSeqId.toString();
    _itemCodeController.text = header.itemCode;
    _itemNameController.text = header.itemName;
    _qtyOrderController.text = header.qty?.toString() ?? '';
    _orderUnitController.text = header.orderUnit;
    _lotNumberController.text = header.lotNumber;
    _heatNoController.text = header.heatNumber;
    _sizeController.text = header.size;
    _refNoController.text = header.refNo;
    _remarksController.text = header.remarks;
    _templateSts = header.templateSts;
    _templateName = header.templateName;
    _templateNameController.text = header.templateName;
    // Display employee names (not IDs) in Signature Information
    _preparedByController.text = header.prepared;
    _preparedController.text = header.prepared;
    _approvedByController.text = header.approved;
    _approvedController.text = header.approved;
    _receivedByController.text = header.received;
    _receivedController.text = header.received;
    _column1Controller.text = header.column1.toString();
    
    // Set the employee IDs when in edit mode
    _preparedById = header.preparedBy;
    _approvedById = header.approvedBy;
    _receivedById = header.receivedBy;
    
    setState(() {});
  }

  bool _isReadOnly(String colName) {
    final m = _columnMeta[colName];
    if (m == null) return false; // default editable
    final edit = m.colEdit.trim();
    if (edit.isEmpty) return false; // empty edit means editable
    if (edit.startsWith('Text*@')) return true; // generated text e.g., STOCKSUPPLY
    // In edit mode, allow manual typing for list-driven fields until dropdowns implemented
    if (edit.startsWith('List@') || edit.startsWith('List*@')) {
      return !widget.isEdit;
    }
    return false;
  }

  InputDecoration _inputDecoration(String label, {required bool readOnly}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      filled: true,
      fillColor: readOnly ? AppColors.readOnlyYellow : AppColors.surfaceCard,
    );
  }

  @override
  void initState() {
    super.initState();
    _preparedById = 0;
    _approvedById = '';
    _receivedById = '';
    
    _detailItems = widget.initialDetailItems.isNotEmpty
        ? widget.initialDetailItems.map(_cloneDetailItem).toList()
        : [_createEmptyDetailItem()];
    if (widget.isEdit) {
      if (widget.columnMetaRows != null) {
        _columnMeta
          ..clear()
          ..addEntries(
            widget.columnMetaRows!
                .map((m) => _ColumnMeta.fromJson(m))
                .map((m) => MapEntry(m.colName, m)),
          );
      }
      if (widget.initialHeader != null) {
        _hydrateFromHeader(widget.initialHeader!);
      }
    } else {
      _initializeNewSupply();
    }

    // After initial load, set Prepared display to current user if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = AuthService.currentUser?.trim();
      if (current != null && current.isNotEmpty) {
        if (_preparedByController.text.trim().isEmpty) {
          _preparedByController.text = current;
          _preparedController.text = current;
        }
      }
    });
  }

  @override
  void dispose() {
    _supplyIdController.dispose();
    _supplyNumberController.dispose();
    _supplyFromController.dispose();
    _supplyToController.dispose();
    // Removed From Org / To Org controllers
    _orderNoController.dispose();
    _projectNoController.dispose();
    _orderIdController.dispose();
    _orderSeqIdController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _qtyOrderController.dispose();
    _orderUnitController.dispose();
    _lotNumberController.dispose();
    _heatNoController.dispose();
    _sizeController.dispose();
    _refNoController.dispose();
    _remarksController.dispose();
    _templateNameController.dispose();
    _preparedByController.dispose();
    _preparedController.dispose();
    _approvedByController.dispose();
    _approvedController.dispose();
    _receivedByController.dispose();
    _receivedController.dispose();
    _column1Controller.dispose();
    super.dispose();
  }

  Future<void> _initializeNewSupply() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createSupplyDraft(
        supplyCls: 1,
        userEntry: 'admin',
        supplyDate: _supplyDate.toIso8601String().split('T')[0],
        useTemplate: _useTemplate,
        companyId: 1,
      );

      if (result['success'] == true) {
        // Try hydrate defaults if API returns template/header
        final data = result['data'];
        // Decode and log executed statement if present
        final String? dataencdec = data['dataencdec'] as String?;
        if (dataencdec != null && dataencdec.isNotEmpty) {
          try {
            final decoded = utf8.decode(base64.decode(dataencdec));
            debugPrint('🔎 API apidata decoded: $decoded');
          } catch (e) {
            debugPrint('⚠️ Failed to decode dataencdec: $e');
          }
        }
        // Common patterns: tbl1 carry header row; tbl0 is column metadata
        final List? tbl0 = data['tbl0'] as List?;
        if (tbl0 != null) {
          _columnMeta
            ..clear()
            ..addEntries(
              tbl0
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .map((m) => _ColumnMeta.fromJson(m))
                  .map((m) => MapEntry(m.colName, m)),
            );
        }
        final List? tbl1 = data['tbl1'] as List?;
        final Map<String, dynamic>? headerJson = (tbl1 != null && tbl1.isNotEmpty)
            ? (tbl1.first as Map).cast<String, dynamic>()
            : null;

        if (headerJson != null) {
            // Be defensive, fill only when present
            final header = SupplyHeader.fromJson(headerJson);
            _supplyIdController.text = header.supplyId.toString();
            _supplyNumberController.text = header.supplyNo;
            _supplyDate = header.supplyDate;
            _supplyFromController.text = header.fromId;
            _supplyToController.text = header.toId;
            _fromWarehouseId = int.tryParse(header.fromId);
            _toWarehouseId = int.tryParse(header.toId);
            // From Org / To Org removed from UI
            _orderIdController.text = header.orderId.toString();
            _orderNoController.text = header.orderNo;
            _projectNoController.text = header.projectNo;
            _orderSeqIdController.text = header.orderSeqId.toString();
            _itemCodeController.text = header.itemCode;
            _itemNameController.text = header.itemName;
            _qtyOrderController.text = header.qty?.toString() ?? '';
            _orderUnitController.text = header.orderUnit;
            _lotNumberController.text = header.lotNumber;
            _heatNoController.text = header.heatNumber;
            _sizeController.text = header.size;
            _refNoController.text = header.refNo;
            _remarksController.text = header.remarks;
            _templateSts = header.templateSts;
            _templateName = header.templateName;
            _templateNameController.text = header.templateName;
            // Display employee names (not IDs) in Signature Information
            _preparedByController.text = header.prepared;
            _preparedController.text = header.prepared;
            _approvedByController.text = header.approved;
            _approvedController.text = header.approved;
            _receivedByController.text = header.received;
            _receivedController.text = header.received;
            _column1Controller.text = header.column1.toString();
            
            // Set the employee IDs when initializing with a header
            _preparedById = header.preparedBy;
            _approvedById = header.approvedBy;
            _receivedById = header.receivedBy;
            
            setState(() {});
          }
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to initialize new supply');
      }
    } catch (e) {
      _showErrorMessage('Failed to initialize new supply: $e');
    } finally {
      setState(() => _isLoading = false);
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
      setState(() {
        _supplyDate = picked;
      });
    }
  }

  Future<void> _saveHeaderAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    // Allow manual numeric entry by falling back to text field parsing
    final resolvedFromId =
        _fromWarehouseId ?? _parseIntValue(_supplyFromController.text);
    final resolvedToId =
        _toWarehouseId ?? _parseIntValue(_supplyToController.text);

    if (resolvedFromId == null || resolvedToId == null) {
      _showErrorMessage('Pilih gudang From dan To terlebih dahulu.');
      return;
    }

    _fromWarehouseId ??= resolvedFromId;
    _toWarehouseId ??= resolvedToId;

    setState(() => _isLoading = true);
    try {
      final isEdit = widget.isEdit;
      final supplyId = isEdit ? int.tryParse(_supplyIdController.text.trim()) ?? 0 : 0;
      final supplyNo = _supplyNumberController.text.trim();
      final supplyDateFmt = _formatDateDdMmmYyyy(_supplyDate); // e.g. 04-Mar-2025
      final fromId = _fromWarehouseId!;
      final toId = _toWarehouseId!;
      final orderId = int.tryParse(_orderIdController.text.trim()) ?? 0;
      final orderSeq = (_orderSeqIdController.text.trim().isEmpty)
          ? '0'
          : _orderSeqIdController.text.trim();
      final refNo = _refNoController.text.trim();
      final remarks = _remarksController.text.trim();
      final templateSts = _templateSts;
      final templateName = _templateNameController.text.trim().isNotEmpty
          ? _templateNameController.text.trim()
          : _templateName;

      var preparedBy = _preparedById == 0 ? null : _preparedById;
      if (preparedBy == null && (AuthService.currentUser?.toLowerCase() == 'admin')) {
        preparedBy = 1; // default admin employee ID fallback
      }
      // If no preparedBy selected, default to current user (if numeric known)
      if (preparedBy == null) {
        final user = AuthService.currentUser;
        // if backend requires ID, we leave NULL; otherwise name used in header already
        // keep preparedBy as null to avoid wrong ID
      }
      final approvedBy = _approvedById.isEmpty ? null : int.tryParse(_approvedById);
      final receivedBy = _receivedById.isEmpty ? null : int.tryParse(_receivedById);

      final detailsPayload = <Map<String, dynamic>>[];
      for (final item in _detailItems) {
        final code = item.itemCode.trim();
        final qty = item.qty;
        if (code.isEmpty || qty == 0) continue;

        int? resolveInt(dynamic value) => _parseIntValue(value);

        int? resolvedItemId = item.itemId;
        int? resolvedUnitId = item.unitId;
        if (resolvedItemId == null || resolvedItemId <= 0) {
          resolvedItemId = resolveInt(item.raw?['Item_ID']) ??
              resolveInt(item.raw?['ItemId']) ??
              resolveInt(item.raw?['ID']) ??
              int.tryParse(code);
        }

        if (resolvedUnitId == null || resolvedUnitId <= 0) {
          resolvedUnitId = resolveInt(item.raw?['Unit_ID']) ??
              resolveInt(item.raw?['UnitId']) ??
              resolveInt(item.raw?['UOM_ID']) ??
              resolveInt(item.raw?['UomId']) ??
              resolveInt(item.raw?['Item_Unit_ID']) ??
              resolveInt(item.raw?['Unit_Stock']);
        }

        final seqId = _resolveSeqIdForDetail(item);

        detailsPayload.add({
          'itemId': resolvedItemId ?? 0,
          'qty': qty,
          'unitId': resolvedUnitId,
          'lotNumber': item.lotNumber.trim(),
          'heatNumber': item.heatNumber.trim(),
          'size': item.size.trim(),
          'description': item.description.trim(),
          'seqId': seqId,
          'raw': item.raw,
        });
      }

      final result = await ApiService.createSupplyWithDetails(
        supplyCls: 1,
        supplyNo: supplyNo.isEmpty ? 'AUTO' : supplyNo,
        supplyDateDdMmmYyyy: supplyDateFmt,
        fromId: fromId,
        toId: toId,
        orderId: orderId,
        orderSeq: orderSeq,
        refNo: refNo,
        remarks: remarks.isEmpty ? '' : remarks,
        templateSts: templateSts,
        templateName: templateName,
        preparedBy: preparedBy,
        approvedBy: approvedBy,
        receivedBy: receivedBy,
        companyId: 1,
        userEntry: 'admin',
        details: detailsPayload,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final newId = result['headerId'] as int?;
        if (newId != null) {
          _supplyIdController.text = newId.toString();
        }
        final msg = result['message']?.toString() ?? (newId != null ? 'Saved. Header ID: $newId' : 'Header and details saved');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to save header/details');
      }
    } catch (e) {
      _showErrorMessage('Failed to save supply header: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _browseWarehouse({required bool isFrom}) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final browseResult = await ApiService.browseWarehouses(companyId: 1);

      if (!mounted) return;

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Tidak dapat memuat data gudang';
        _showErrorMessage(message);
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data gudang tidak tersedia');
        return;
      }

      final items = _extractRows(data);
      if (items.isEmpty) {
        _showErrorMessage('Data gudang tidak tersedia');
        return;
      }

      // Extract column metadata if available in the response
      final columnMeta = <String, _ColumnMeta>{};
      final List? tbl0 = data['tbl0'] as List?;
      if (tbl0 != null) {
        columnMeta
          ..clear()
          ..addEntries(
            tbl0
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .map((m) => _ColumnMeta.fromJson(m))
                .map((m) => MapEntry(m.colName, m)),
          );
      }

      // Filter items based on column visibility (excluding tb10 data as requested)
      final visibleItems = items.map((item) {
        final filteredItem = <String, dynamic>{};
        for (final entry in item.entries) {
          final colName = entry.key;
          final colMeta = columnMeta[colName];
          // Only include the field if it's visible (ColVisible == 1) or if there's no metadata for it
          if (colMeta == null || colMeta.colVisible == 1) {
            filteredItem[colName] = entry.value;
          }
        }
        return filteredItem;
      }).toList();

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final TextEditingController searchCtrl = TextEditingController();
          List<Map<String, dynamic>> filteredRaw = List.of(items);

          void applyFilter(String q) {
            final qq = q.trim().toLowerCase();
            filteredRaw = qq.isEmpty
                ? List.of(items)
                : items.where((raw) {
                    final name = _getStringValue(
                      raw,
                      const ['Warehouse_Name','WarehouseName','Org_Name','Name','Description','colName','colname','ColName','Colname','colName1','colname1'],
                      partialMatches: const ['warehouse','gudang','orgname','name'],
                    ) ?? '';
                    final code = _getStringValue(
                      raw,
                      const ['Warehouse_Code','WarehouseCode','Org_Code','Code','ID','Warehouse_ID','WarehouseId','colCode','colcode'],
                      partialMatches: const ['warehousecode','gudang','orgcode','code','id'],
                    ) ?? '';
                    return name.toLowerCase().contains(qq) || code.toLowerCase().contains(qq);
                  }).toList();
          }

          return StatefulBuilder(
            builder: (context, setModal) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SafeArea(
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
                            Text(
                              isFrom ? 'Pilih Supply From' : 'Pilih Supply To',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(sheetContext).pop(),
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
                            hintText: 'Cari gudang by nama atau kode...',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredRaw.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final rawRow = filteredRaw[index];
                            // Build visible subset based on metadata
                            final row = <String, dynamic>{};
                            for (final entry in rawRow.entries) {
                              final colName = entry.key;
                              final colMeta = columnMeta[colName];
                              if (colMeta == null || colMeta.colVisible == 1) {
                                row[colName] = entry.value;
                              }
                            }
                            final title = _getStringValue(
                                  row.isNotEmpty ? row : rawRow,
                                  const [
                                    'Warehouse_Name','WarehouseName','Org_Name','Name','Description','colName','colname','ColName','Colname','colName1','colname1',
                                  ],
                                  partialMatches: const ['warehouse','gudang','orgname','name'],
                                ) ?? 'Warehouse ${index + 1}';
                            final code = _getStringValue(
                              rawRow,
                              const ['Warehouse_Code','WarehouseCode','Org_Code','Code','ID','Warehouse_ID','WarehouseId','colCode','colcode'],
                              partialMatches: const ['warehousecode','gudang','orgcode','code','id'],
                            );
                            final location = _getStringValue(
                              rawRow,
                              const ['Location','Address','City','colLocation','collocation','colAddr'],
                              partialMatches: const ['lokasi','location','address','city'],
                            );

                            final selection = Map<String, dynamic>.from(rawRow)
                              ..putIfAbsent('_displayName', () => title)
                              ..putIfAbsent('_displayCode', () => code);

                            final details = <String>[];
                            if (code != null) details.add(code);
                            if (location != null) details.add(location);

                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF3E5F5),
                                child: Icon(Icons.store, color: Color(0xFF7B1FA2)),
                              ),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: details.isEmpty ? null : Text(details.join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => Navigator.of(sheetContext).pop(selection),
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

      if (!mounted || selected == null) return;

      _applyWarehouseSelection(selected, isFrom: isFrom);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Gagal membuka data gudang: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  void _applyWarehouseSelection(Map<String, dynamic> data, {required bool isFrom}) {
    final controller = isFrom ? _supplyFromController : _supplyToController;
    final code = _getStringValue(
      data,
      const [
        'Warehouse_Code',
        'WarehouseCode',
        'Code',
        'Warehouse_ID',
        'WarehouseId',
        'ID',
        'colCode',
        'colcode',
      ],
      partialMatches: const ['warehousecode', 'gudang', 'code'],
    );
    final name = _getStringValue(
      data,
      const [
        'Warehouse_Name',
        'WarehouseName',
        'Name',
        'Description',
        'colName',
        'colname',
        'ColName',
        'Colname',
        'colName1',
        'colname1',
      ],
      partialMatches: const ['warehouse', 'gudang', 'colname', 'name'],
    );

    final chosen = name ?? code ?? _stringifyValue(data['_displayName']);
    final trimmed = chosen?.trim();
    final id = _getFirstValue(
      data,
      const [
        'Warehouse_ID', 'WarehouseId', 'WH_ID', 'ID'
      ],
      partialMatches: const ['warehouseid', 'whid', 'id'],
    );
    final idInt = _parseIntValue(id);
    if (isFrom) {
      _fromWarehouseId = idInt;
    } else {
      _toWarehouseId = idInt;
    }
    debugPrint('Warehouse selection (${isFrom ? 'from' : 'to'}): raw id=$id parsed=$idInt');
    if (trimmed != null && trimmed.isNotEmpty && controller.text.trim() != trimmed) {
      controller.text = trimmed;
    }
    if (idInt == null) {
      debugPrint('⚠️ Warehouse selection is missing numeric ID. Raw value: $id');
    }
    if (mounted) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _extractRows(
    Map<String, dynamic> payload, {
    Set<String> excludeTables = const <String>{},
  }) {
    final rows = <Map<String, dynamic>>[];

    Map<int, String>? parseFieldDefinitions(List<dynamic> fields) {
      final mapping = <int, String>{};

      for (var index = 0; index < fields.length; index++) {
        final entry = fields[index];
        String? fieldName;

        if (entry is Map) {
          for (final element in entry.entries) {
            final normalized = _normalizeKey(element.key);
            if (normalized == 'colname' ||
                normalized == 'columnname' ||
                normalized == 'fieldname' ||
                normalized == 'name' ||
                normalized == 'caption' ||
                normalized == 'colcaption') {
              fieldName = _stringifyValue(element.value);
              if (fieldName != null) break;
            }
          }

          fieldName ??= _stringifyValue(entry['title']);
        } else if (entry is String) {
          fieldName = _stringifyValue(entry);
        }

        if (fieldName != null && fieldName.isNotEmpty) {
          mapping[index] = fieldName;
        }
      }

      return mapping.isEmpty ? null : mapping;
    }

    void walk(dynamic node, {Map<int, String>? activeFields}) {
      if (node is Map) {
        Map<int, String>? localFields = activeFields;

        for (final entry in node.entries) {
          final value = entry.value;
          if (value is List) {
            final normalizedKey = _normalizeKey(entry.key);
            // Skip field definitions (tbl0) and any excluded tables
            if (normalizedKey == 'tbl0' || excludeTables.contains(normalizedKey) || normalizedKey.contains('field')) {
              final parsed = parseFieldDefinitions(value);
              if (parsed != null) {
                localFields = {
                  if (localFields != null) ...localFields,
                  ...parsed,
                };
              }
              if (normalizedKey == 'tbl0' || excludeTables.contains(normalizedKey)) {
                continue;
              }
            }
          }
        }

        for (final entry in node.entries) {
          final value = entry.value;
          if (value is List) {
            final normalizedKey = _normalizeKey(entry.key);
            // Skip traversing into tbl0 (fields) and any excluded tables
            if (normalizedKey == 'tbl0' || excludeTables.contains(normalizedKey) || normalizedKey.contains('field')) {
              continue;
            }
          }
          walk(entry.value, activeFields: localFields);
        }

        return;
      }

      if (node is List) {
        if (node.isEmpty) return;

        for (final element in node) {
          if (element is Map) {
            rows.add(element.map((key, value) => MapEntry(key.toString(), value)));
          } else if (element is List) {
            final mapped = <String, dynamic>{};
            for (var index = 0; index < element.length; index++) {
              final key = activeFields != null && activeFields.containsKey(index)
                  ? activeFields[index]!
                  : 'col${index + 1}';
              mapped[key] = element[index];
            }
            rows.add(mapped);
          }
        }
      }
    }

    walk(payload);
    return rows;
  }

  String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  bool _matchesNormalizedKey(String key, Set<String> targets) {
    if (targets.contains(key)) return true;
    for (final target in targets) {
      if (target.length > 2 && key.endsWith(target)) {
        return true;
      }
    }
    return false;
  }

  String? _stringifyValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    final stringified = value.toString().trim();
    return stringified.isEmpty ? null : stringified;
  }

  dynamic _getFirstValue(
    Map<String, dynamic> data,
    List<String> keys, {
    List<String> partialMatches = const [],
  }) {
    if (data.isEmpty) return null;

    final normalizedTargets =
        keys.map(_normalizeKey).where((element) => element.isNotEmpty).toSet();

    for (final entry in data.entries) {
      final normalizedKey = _normalizeKey(entry.key);
      if (!_matchesNormalizedKey(normalizedKey, normalizedTargets)) continue;
      final value = entry.value;
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) continue;
      return value;
    }

    if (partialMatches.isNotEmpty) {
      final partialTargets = partialMatches
          .map(_normalizeKey)
          .where((element) => element.isNotEmpty)
          .toList();

      for (final entry in data.entries) {
        final normalizedKey = _normalizeKey(entry.key);
        final matches = partialTargets
            .any((target) => target.isNotEmpty && normalizedKey.contains(target));
        if (!matches) continue;
        final value = entry.value;
        if (value == null) continue;
        final stringValue = value.toString().trim();
        if (stringValue.isEmpty) continue;
        return value;
      }
    }

    return null;
  }

  String? _getStringValue(
    Map<String, dynamic> data,
    List<String> keys, {
    List<String> partialMatches = const [],
  }) {
    final value = _getFirstValue(
      data,
      keys,
      partialMatches: partialMatches,
    );
    return _stringifyValue(value);
  }

  int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    const decimalPattern = r'^-?\d+(\.0+)?$';
    if (RegExp(decimalPattern).hasMatch(text)) {
      final integerPortion = text.split('.').first;
      return int.tryParse(integerPortion);
    }

    if (RegExp(r'^-?\d+$').hasMatch(text)) {
      return int.tryParse(text);
    }

    return null;
  }

  bool _rawHasSupplyContext(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return false;
    }
    for (final key in raw.keys) {
      final normalized = key.toString().toLowerCase();
      if (normalized.contains('supply_id') || normalized.contains('supplydetail')) {
        return true;
      }
    }
    return false;
  }

  String _resolveSeqIdForDetail(SupplyDetailItem item) {
    final seq = item.seqId.trim();
    if (seq.isNotEmpty && seq != '0') {
      return seq;
    }

    if (_rawHasSupplyContext(item.raw)) {
      final fromRaw = _getStringValue(
        item.raw!,
        const ['Seq_ID', 'SeqId', 'Sequence', 'Seq', 'Seq_ID_Detail'],
        partialMatches: const ['seq'],
      );
      if (fromRaw != null) {
        final trimmed = fromRaw.trim();
        if (trimmed.isNotEmpty && trimmed != '0') {
          return trimmed;
        }
      }
    }

    return '0';
  }

  Map<String, dynamic>? _extractFirstRow(Map<String, dynamic> payload) {
    final rows = _extractRows(payload);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> _browseOrderEntryItem() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final browseResult = await ApiService.browseOrderEntryItems(
        dateStart: '2020-01-01',
        dateEnd: '2025-02-28',
        companyId: 1,
      );

      if (!mounted) return;

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Tidak dapat memuat data order entry';
        _showErrorMessage(message);
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data order entry tidak tersedia');
        return;
      }

      final items = _extractRows(data, excludeTables: {'tb10'});
      if (items.isEmpty) {
        _showErrorMessage('Data order entry tidak tersedia');
        return;
      }

      // Extract column metadata if available in the response
      final columnMeta = <String, _ColumnMeta>{};
      final List? tbl0 = data['tbl0'] as List?;
      if (tbl0 != null) {
        columnMeta
          ..clear()
          ..addEntries(
            tbl0
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .map((m) => _ColumnMeta.fromJson(m))
                .map((m) => MapEntry(m.colName, m)),
          );
      }

      // Filter items based on column visibility (excluding tb10 data as requested)
      final visibleItems = items.map((item) {
        final filteredItem = <String, dynamic>{};
        for (final entry in item.entries) {
          final colName = entry.key;
          final colMeta = columnMeta[colName];
          // Only include the field if it's visible (ColVisible == 1) or if there's no metadata for it
          if (colMeta == null || colMeta.colVisible == 1) {
            filteredItem[colName] = entry.value;
          }
        }
        return filteredItem;
      }).toList();

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
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
                        const Text(
                          'Pilih Order Entry',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = visibleItems[index];
                        final orderNo = _getStringValue(
                          row,
                          const [
                            'Order_No',
                            'OrderNo',
                            'No_Order',
                            'Order_Number',
                          ],
                          partialMatches: const ['orderno', 'noorder', 'order', 'number'],
                        );
                        final projectNo = _getStringValue(
                          row,
                          const [
                            'Project_No',
                            'ProjectNo',
                            'No_Project',
                            'Project_Number',
                          ],
                          partialMatches: const ['projectno', 'noproject', 'project', 'number'],
                        );
                        final description = _getStringValue(
                          row,
                          const [
                            'Description',
                            'Remark',
                            'Notes',
                          ],
                          partialMatches: const ['description', 'remark', 'notes', 'desc'],
                        );

                        final selection = Map<String, dynamic>.from(row)
                          ..putIfAbsent('_displayOrderNo', () => orderNo ?? 'Order ${index + 1}')
                          ..putIfAbsent('_displayProjectNo', () => projectNo ?? '');

                        final details = <String>[];
                        if (projectNo != null) details.add('Project: $projectNo');
                        if (description != null) details.add(description);

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E8),
                            child: Icon(Icons.assignment, color: Color(0xFF388E3C)),
                          ),
                          title: Text(
                            orderNo ?? 'Order ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: details.isEmpty ? null : Text(
                            details.join(' • '),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => Navigator.of(sheetContext).pop(selection),
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

      if (!mounted || selected == null) return;

      _applyOrderEntrySelection(selected);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Gagal membuka data order entry: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  void _applyOrderEntrySelection(Map<String, dynamic> data) {
    final orderNo = _getStringValue(
      data,
      const [
        'Order_No',
        'OrderNo',
        'No_Order',
        'Order_Number',
      ],
      partialMatches: const ['orderno', 'noorder', 'order', 'number'],
    );
    final projectNo = _getStringValue(
      data,
      const [
        'Project_No',
        'ProjectNo',
        'No_Project',
        'Project_Number',
      ],
      partialMatches: const ['projectno', 'noproject', 'project', 'number'],
    );
    final orderId = _getStringValue(
      data,
      const [
        'Order_ID',
        'OrderId',
        'ID_Order',
        'ID',
      ],
      partialMatches: const ['orderid', 'idorder'],
    );
    final seqId = _getStringValue(
      data,
      const [
        'Seq_ID',
        'SeqId',
        'Sequence',
        'Order_Seq',
        'Item_Seq',
      ],
      partialMatches: const ['seq', 'sequence', 'orderseq', 'itemseq'],
    );
    final itemCode = _getStringValue(
      data,
      const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'colcode', 'ColCode'],
      partialMatches: const ['itemcode', 'kode', 'code'],
    );
    final itemName = _getStringValue(
      data,
      const [
        'Item_Name',
        'ItemName',
        'Name',
        'Description',
        'colName',
        'colname',
        'ColName',
        'Colname',
        'colName1',
        'colname1',
      ],
      partialMatches: const ['itemname', 'description', 'colname', 'namestock', 'namabarang'],
    );
    final qtyOrder = _getStringValue(
      data,
      const [
        'Qty_Order',
        'Qty',
        'Quantity',
      ],
      partialMatches: const ['qty', 'quantity', 'jumlah'],
    );
    final unit = _getStringValue(
      data,
      const ['Unit', 'UOM', 'Order_Unit', 'Unit_Stock'],
      partialMatches: const ['unit', 'uom', 'orderunit'],
    );
    final lotNumber = _getStringValue(
      data,
      const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
      partialMatches: const ['lot', 'batch'],
    );
    final heatNo = _getStringValue(
      data,
      const ['Heat_No', 'HeatNo', 'Heat_Number'],
      partialMatches: const ['heat', 'heatno'],
    );
    final size = _getStringValue(
      data,
      const ['Size', 'Item_Size', 'colSize', 'colsize', 'ColSize'],
      partialMatches: const ['size', 'dimension'],
    );

    if (orderNo != null && orderNo.isNotEmpty) {
      _orderNoController.text = orderNo;
    }
    
    if (projectNo != null && projectNo.isNotEmpty) {
      _projectNoController.text = projectNo;
    }

    if (orderId != null && orderId.isNotEmpty) {
      _orderIdController.text = orderId;
    }
    if (seqId != null && seqId.isNotEmpty) {
      _orderSeqIdController.text = seqId;
    }
    if (itemCode != null && itemCode.isNotEmpty) {
      _itemCodeController.text = itemCode;
    }
    if (itemName != null && itemName.isNotEmpty) {
      _itemNameController.text = itemName;
    }
    if (qtyOrder != null && qtyOrder.isNotEmpty) {
      _qtyOrderController.text = qtyOrder;
    }
    if (unit != null && unit.isNotEmpty) {
      _orderUnitController.text = unit;
    }
    if (lotNumber != null && lotNumber.isNotEmpty) {
      _lotNumberController.text = lotNumber;
    }
    if (heatNo != null && heatNo.isNotEmpty) {
      _heatNoController.text = heatNo;
    }
    if (size != null && size.isNotEmpty) {
      _sizeController.text = size;
    }

    if (orderNo != null ||
        projectNo != null ||
        orderId != null ||
        seqId != null ||
        itemCode != null ||
        itemName != null ||
        qtyOrder != null ||
        unit != null ||
        lotNumber != null ||
        heatNo != null ||
        size != null) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _browseEmployee({required String field}) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final browseResult = await ApiService.browseEmployees(companyId: 1);

      if (!mounted) return;

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Tidak dapat memuat data karyawan';
        _showErrorMessage(message);
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data karyawan tidak tersedia');
        return;
      }

      final items = _extractRows(data);
      if (items.isEmpty) {
        _showErrorMessage('Data karyawan tidak tersedia');
        return;
      }

      // Extract column metadata if available in the response
      final columnMeta = <String, _ColumnMeta>{};
      final List? tbl0 = data['tbl0'] as List?;
      if (tbl0 != null) {
        columnMeta
          ..clear()
          ..addEntries(
            tbl0
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .map((m) => _ColumnMeta.fromJson(m))
                .map((m) => MapEntry(m.colName, m)),
          );
      }

      // Filter items based on column visibility (excluding tb10 data as requested)
      final visibleItems = items.map((item) {
        final filteredItem = <String, dynamic>{};
        for (final entry in item.entries) {
          final colName = entry.key;
          final colMeta = columnMeta[colName];
          // Only include the field if it's visible (ColVisible == 1) or if there's no metadata for it
          if (colMeta == null || colMeta.colVisible == 1) {
            filteredItem[colName] = entry.value;
          }
        }
        return filteredItem;
      }).toList();

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // Make background transparent
        builder: (sheetContext) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
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
                        Text(
                          'Pilih $field',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = visibleItems[index];
                        final name = _getStringValue(
                              row,
                              const [
                                'Employee_Name',
                                'EmployeeName',
                                'Name',
                                'Description',
                                'colName',
                                'colname',
                                'ColName',
                                'Colname',
                                'colName1',
                                'colname1',
                              ],
                              partialMatches: const ['employee', 'name', 'colname', 'nama'],
                            ) ??
                            'Karyawan ${index + 1}';
                        final code = _getStringValue(
                          row,
                          const [
                            'Employee_Code',
                            'EmployeeCode',
                            'Code',
                            'Employee_ID',
                            'EmployeeId',
                            'ID',
                            'colCode',
                            'colcode',
                          ],
                          partialMatches: const ['employeecode', 'karyawan', 'code', 'id'],
                        );
                        final position = _getStringValue(
                          row,
                          const [
                            'Position',
                            'Job_Position',
                            'JobPosition',
                            'Department',
                            'Dept',
                          ],
                          partialMatches: const ['position', 'job', 'dept', 'departemen'],
                        );

                        final selection = Map<String, dynamic>.from(row)
                          ..putIfAbsent('_displayName', () => name)
                          ..putIfAbsent('_displayCode', () => code);

                        final details = <String>[];
                        if (code != null) details.add(code);
                        if (position != null) details.add(position);

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.person, color: Color(0xFF1976D2)),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: details.isEmpty ? null : Text(
                            details.join(' • '),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => Navigator.of(sheetContext).pop(selection),
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

      if (!mounted || selected == null) return;

      _applyEmployeeSelection(selected, field: field);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Gagal membuka data karyawan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  void _applyEmployeeSelection(Map<String, dynamic> data, {required String field}) {
    final id = _getFirstValue(
      data,
      const [
        'Employee_ID',
        'EmployeeId',
        'ID',
      ],
      partialMatches: const ['employeeid', 'id', 'identifier'],
    );
    final code = _getStringValue(
      data,
      const [
        'Employee_Code',
        'EmployeeCode',
        'Code',
        'colCode',
        'colcode',
      ],
      partialMatches: const ['employeecode', 'karyawan', 'code'],
    );
    final name = _getStringValue(
      data,
      const [
        'Employee_Name',
        'EmployeeName',
        'Name',
        'Description',
        'colName',
        'colname',
        'ColName',
        'Colname',
        'colName1',
        'colname1',
      ],
      partialMatches: const ['employee', 'name', 'colname', 'nama'],
    );

    // Use name for display, but ID for API submission
    final displayValue = name ?? code ?? _stringifyValue(data['_displayName']);
    final idValue = id?.toString();
    
    final trimmedDisplay = displayValue?.trim();
    if (trimmedDisplay == null || trimmedDisplay.isEmpty) return;

    switch(field) {
      case 'Prepared':
        if (_preparedByController.text.trim() != trimmedDisplay) {
          _preparedByController.text = trimmedDisplay;
          _preparedById = idValue != null ? int.tryParse(idValue) ?? 0 : 0;
          if (mounted) setState(() {});
        }
        break;
      case 'Approved':
        if (_approvedByController.text.trim() != trimmedDisplay) {
          _approvedByController.text = trimmedDisplay;
          _approvedById = idValue ?? '';
          if (mounted) setState(() {});
        }
        break;
      case 'Received':
        if (_receivedByController.text.trim() != trimmedDisplay) {
          _receivedByController.text = trimmedDisplay;
          _receivedById = idValue ?? '';
          if (mounted) setState(() {});
        }
        break;
    }
  }

  Future<void> _browseItemStockByLot() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final fromId = _fromWarehouseId ?? _parseIntValue(_supplyFromController.text) ?? 0;
      if (fromId == 0) {
        if (!mounted) return;
        _showErrorMessage('Pilih gudang From terlebih dahulu');
        return;
      }
      final dateStr = _supplyDate.toIso8601String().split('T').first;
      final browseResult = await ApiService.browseItemStockByLot(
        id: fromId,
        companyId: 1,
        dateStart: dateStr,
        dateEnd: dateStr,
      );

      if (!mounted) return;

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Tidak dapat memuat data item stock';
        _showErrorMessage(message);
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data item stock tidak tersedia');
        return;
      }

      final items = _extractRows(data);
      if (items.isEmpty) {
        _showErrorMessage('Data item stock tidak tersedia');
        return;
      }

      // Extract column metadata if available in the response
      final columnMeta = <String, _ColumnMeta>{};
      final List? tbl0 = data['tbl0'] as List?;
      if (tbl0 != null) {
        columnMeta
          ..clear()
          ..addEntries(
            tbl0
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .map((m) => _ColumnMeta.fromJson(m))
                .map((m) => MapEntry(m.colName, m)),
          );
      }

      // Filter items based on column visibility (excluding tb10 data as requested)
      final visibleItems = items.map((item) {
        final filteredItem = <String, dynamic>{};
        for (final entry in item.entries) {
          final colName = entry.key;
          final colMeta = columnMeta[colName];
          // Only include the field if it's visible (ColVisible == 1) or if there's no metadata for it
          if (colMeta == null || colMeta.colVisible == 1) {
            filteredItem[colName] = entry.value;
          }
        }
        return filteredItem;
      }).toList();

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
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
                        const Text(
                          'Browse Item Stock',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = visibleItems[index];
                        final title = _getStringValue(
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
                                'colName1',
                                'colname1',
                                'Column1',
                                'Column_1',
                              ],
                              partialMatches: const ['itemname', 'description', 'colname', 'namestock', 'namabarang'],
                            ) ??
                            _getStringValue(
                              row,
                              const [],
                              partialMatches: const ['name', 'desc', 'barang', 'produk'],
                            ) ??
                            'Item ${index + 1}';
                        final code = _getStringValue(
                          row,
                          const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'colcode', 'ColCode'],
                          partialMatches: const ['itemcode', 'kode', 'code'],
                        );
                        final lot = _getStringValue(
                          row,
                          const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
                          partialMatches: const ['lot', 'batch'],
                        );
                        final qty = _getStringValue(
                          row,
                          const [
                            'Qty',
                            'Quantity',
                            'Qty_Available',
                            'Qty_Order',
                            'Balance',
                            'Unit_Stock',
                            'Stock',
                          ],
                          partialMatches: const ['qty', 'quantity', 'jumlah', 'balance', 'stock'],
                        );
                        final unit = _getStringValue(
                          row,
                          const ['Unit', 'Unit_Stock', 'UOM'],
                          partialMatches: const ['unit', 'uom', 'stockunit'],
                        );
                        final heat = _getStringValue(
                          row,
                          const ['Heat_No', 'HeatNo', 'Heat_Number'],
                          partialMatches: const ['heat', 'heatno', 'heattreatment'],
                        );
                        final size = _getStringValue(
                          row,
                          const ['Size', 'Item_Size', 'colSize', 'colsize', 'ColSize'],
                          partialMatches: const ['size', 'dimension'],
                        );

                        final selection = Map<String, dynamic>.from(row)
                          ..putIfAbsent('_displayName', () => title);

                        final details = <String>[];
                        if (code != null) details.add(code);
                        if (lot != null) details.add('Lot: $lot');
                        if (qty != null) details.add('Qty: $qty');
                        if (unit != null) details.add(unit);
                        if (heat != null) details.add('Heat: $heat');
                        if (size != null) details.add('Size: $size');

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF3E0),
                            child: Icon(Icons.inventory, color: Color(0xFFFF9800)),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: details.isEmpty ? null : Text(
                            details.join(' • '),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () => Navigator.of(sheetContext).pop(selection),
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

      if (!mounted || selected == null) return;

      final detail = await _fetchItemDetail(selected);
      final dataToApply = detail ?? selected;
      _applyItemSelection(dataToApply);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Gagal membuka data item stock: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchItemDetail(Map<String, dynamic> selected) async {
    dynamic id = _getFirstValue(
      selected,
      const ['ID', 'Id', 'Item_ID', 'ItemId'],
      partialMatches: const ['itemid', 'stockid', 'browseid'],
    );
    dynamic seq = _getFirstValue(
      selected,
      const ['Seq', 'SEQ', 'Sequence', 'Lot_Seq'],
      partialMatches: const ['seq', 'sequence', 'lotseq'],
    );

    final idAsString = _stringifyValue(id);
    final seqAsString = _stringifyValue(seq);

    var normalizedId = idAsString;
    var normalizedSeq = seqAsString;

    if (normalizedSeq == null && normalizedId != null && normalizedId.contains('@')) {
      final parts = normalizedId
          .split('@')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        normalizedId = parts.first;
        normalizedSeq = parts.last;
      }
    }

    normalizedSeq ??= _stringifyValue(
      _getFirstValue(
        selected,
        const ['WH_ID', 'Warehouse_ID', 'WarehouseId'],
        partialMatches: const ['warehouseid', 'whid'],
      ),
    );

    normalizedId ??= _stringifyValue(
      _getFirstValue(
        selected,
        const ['ItemIdx', 'Idx', 'Row_ID', 'RowId'],
        partialMatches: const ['itemidx', 'rowid', 'idx'],
      ),
    );

    normalizedId ??= idAsString;

    if (normalizedId == null || normalizedSeq == null) {
      return null;
    }

    try {
      final result = await ApiService.showItemStockByLot(
        id: normalizedId,
        seq: normalizedSeq,
        companyId: 1,
      );

      if (result['success'] != true) {
        final message = result['message'] as String?;
        if (message != null) {
          _showErrorMessage(message);
        }
        return null;
      }

      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return _extractFirstRow(data);
      }
    } catch (e) {
      _showErrorMessage('Gagal memuat detail item: $e');
    }

    return null;
  }

  void _applyItemSelection(Map<String, dynamic> data) {
    // Apply selection to header hint fields
    var changed = false;

    void setValue(TextEditingController controller, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      if (controller.text == trimmed) return;
      controller.text = trimmed;
      changed = true;
    }

    setValue(
      _itemNameController,
      _getStringValue(
            data,
            const [
              'Item_Name',
              'ItemName',
              'Name',
              'Description',
              'colName',
              'colname',
              'ColName',
              'Colname',
              'colName1',
              'colname1',
              'Column1',
              'Column_1',
            ],
            partialMatches: const ['itemname', 'description', 'colname', 'namestock', 'namabarang'],
          ) ??
          _stringifyValue(data['_displayName']),
    );
    setValue(
      _itemCodeController,
      _getStringValue(
        data,
        const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'colcode', 'ColCode'],
        partialMatches: const ['itemcode', 'kode', 'code'],
      ),
    );
    setValue(
      _lotNumberController,
      _getStringValue(
        data,
        const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
        partialMatches: const ['lot', 'batch'],
      ),
    );
    setValue(
      _heatNoController,
      _getStringValue(
        data,
        const ['Heat_No', 'HeatNo', 'Heat_Number'],
        partialMatches: const ['heat', 'heatno', 'heattreatment'],
      ),
    );
    setValue(
      _sizeController,
      _getStringValue(
        data,
        const ['Size', 'Item_Size', 'colSize', 'colsize', 'ColSize'],
        partialMatches: const ['size', 'dimension'],
      ),
    );
    setValue(
      _orderUnitController,
      _getStringValue(
        data,
        const ['Unit', 'Item_Unit', 'UOM'],
        partialMatches: const ['unit', 'uom'],
      ),
    );
    setValue(
      _qtyOrderController,
      _getStringValue(
        data,
        const [
          'Qty',
          'Quantity',
          'Qty_Available',
          'Qty_Order',
          'Balance',
          'Unit_Stock',
          'Stock',
        ],
        partialMatches: const ['qty', 'quantity', 'jumlah', 'balance', 'stock'],
      ),
    );

    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _browseItemStockByLotForRow(int rowIndex) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final fromId = _fromWarehouseId ?? _parseIntValue(_supplyFromController.text) ?? 0;
      if (fromId == 0) {
        if (!mounted) return;
        _showErrorMessage('Pilih gudang From terlebih dahulu');
        return;
      }
      final dateStr = _supplyDate.toIso8601String().split('T').first;
      final result = await ApiService.browseItemStockByLot(
        id: fromId,
        companyId: 1,
        dateStart: dateStr,
        dateEnd: dateStr,
      );
      if (!mounted) return;
      if (result['success'] != true) {
        _showErrorMessage(result['message'] ?? 'Tidak dapat memuat data item stock');
        return;
      }
      final data = result['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data item stock tidak tersedia');
        return;
      }
      final items = _extractRows(data);
      if (items.isEmpty) {
        _showErrorMessage('Data item stock tidak tersedia');
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final TextEditingController searchCtrl = TextEditingController();
          List<Map<String, dynamic>> filtered = List.of(items);

          void applyFilter(String q) {
            final query = q.trim().toLowerCase();
            filtered = query.isEmpty
                ? List.of(items)
                : items.where((row) {
                    final code = _getStringValue(
                      row,
                      const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'colcode', 'ColCode', 'SKU'],
                      partialMatches: const ['itemcode', 'kode', 'code', 'sku'],
                    );
                    final name = _getStringValue(
                      row,
                      const ['Item_Name','ItemName','Name','Description','colName','colname','ColName','Colname','colName1','colname1','Column1','Column_1'],
                      partialMatches: const ['itemname','description','colname','namestock','namabarang'],
                    );
                    final lot = _getStringValue(
                      row,
                      const ['Lot_No','LotNo','Lot_Number','Lot'],
                      partialMatches: const ['lot','batch'],
                    );
                    final codeLc = (code ?? '').toLowerCase();
                    final nameLc = (name ?? '').toLowerCase();
                    final lotLc = (lot ?? '').toLowerCase();
                    return codeLc.contains(query) || nameLc.contains(query) || lotLc.contains(query);
                  }).toList();
          }

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SafeArea(
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Browse Item Stock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => setModalState(() { applyFilter(v); }),
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
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            final title = _getStringValue(
                                  row,
                                  const ['Item_Name','ItemName','Name','Description','colName','colname','ColName','Colname','colName1','colname1','Column1','Column_1'],
                                  partialMatches: const ['itemname','description','colname','namestock','namabarang'],
                                ) ?? 'Item ${index + 1}';
                            final code = _getStringValue(row, const ['Item_Code','ItemCode','Code','colCode','colcode','ColCode','SKU'], partialMatches: const ['itemcode','kode','code','sku']);
                            final lot = _getStringValue(row, const ['Lot_No','LotNo','Lot_Number','Lot'], partialMatches: const ['lot','batch']);
                            final unit = _getStringValue(row, const ['Unit','Unit_Stock','UOM'], partialMatches: const ['unit','uom','stockunit']);
                            final qty = _getStringValue(row, const ['Qty','Quantity','Qty_Available','Qty_Order','Balance','Unit_Stock','Stock'], partialMatches: const ['qty','quantity','jumlah','balance','stock']);
                            final heat = _getStringValue(row, const ['Heat_No','HeatNo','Heat_Number'], partialMatches: const ['heat','heatno','heattreatment']);

                            final details = <String>[];
                            if (code != null) details.add(code);
                            if (lot != null) details.add('Lot: $lot');
                            if (unit != null) details.add(unit);
                            if (qty != null) details.add('Qty: $qty');
                            if (heat != null) details.add('Heat: $heat');

                            return ListTile(
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: details.isEmpty ? null : Text(details.join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => Navigator.of(sheetContext).pop(row),
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

      if (!mounted || selected == null) return;

      final currentDetail = _detailItems[rowIndex];
      final selectionRaw = Map<String, dynamic>.from(selected);
      final hasSupplyContext = _rawHasSupplyContext(selectionRaw);
      final resolvedSeqId = hasSupplyContext
          ? (_getStringValue(selectionRaw, const ['Seq_ID','SeqId','SEQ','Seq'], partialMatches: const ['seq','sequence']) ?? currentDetail.seqId)
          : currentDetail.seqId;

      // Map selection into the target row
      final updated = currentDetail.copyWith(
        itemCode: _getStringValue(selectionRaw, const ['Item_Code','ItemCode','Code','colCode','colcode','ColCode'], partialMatches: const ['itemcode','kode','code']) ?? currentDetail.itemCode,
        itemName: _getStringValue(selectionRaw, const ['Item_Name','ItemName','Name','Description','colName','colname','ColName','Colname','colName1','colname1','Column1','Column_1'], partialMatches: const ['itemname','description','colname','namestock','namabarang']) ?? currentDetail.itemName,
        lotNumber: _getStringValue(selectionRaw, const ['Lot_No','LotNo','Lot_Number','Lot'], partialMatches: const ['lot','batch']) ?? currentDetail.lotNumber,
        heatNumber: _getStringValue(selectionRaw, const ['Heat_No','HeatNo','Heat_Number'], partialMatches: const ['heat','heatno','heattreatment']) ?? currentDetail.heatNumber,
        unit: _getStringValue(selectionRaw, const ['Unit','Item_Unit','UOM','Unit_Stock'], partialMatches: const ['unit','uom','stockunit']) ?? currentDetail.unit,
        qty: double.tryParse((_getStringValue(selectionRaw, const ['Qty','Quantity','Qty_Available','Qty_Order','Balance','Unit_Stock','Stock'], partialMatches: const ['qty','quantity','jumlah','balance','stock']) ?? '').replaceAll(',', '.')) ?? currentDetail.qty,
        description: _getStringValue(selectionRaw, const ['Description','Desc','Remark','Remarks'], partialMatches: const ['desc','remark','remarks','keterangan']) ?? currentDetail.description,
        size: _getStringValue(selectionRaw, const ['Size','Item_Size','colSize','colsize','ColSize'], partialMatches: const ['size','dimension']) ?? currentDetail.size,
        itemId: _parseIntValue(_getFirstValue(selectionRaw, const ['Item_ID','ItemId','ID'], partialMatches: const ['itemid','stockid','id'])) ?? currentDetail.itemId,
        unitId: _parseIntValue(_getFirstValue(selectionRaw, const ['Unit_ID','UnitId','UOM_ID','UomId','Item_Unit_ID','Unit_Stock'], partialMatches: const ['unitid','uomid','unitstock'])) ?? currentDetail.unitId,
        seqId: resolvedSeqId,
        raw: selectionRaw,
      );
      _updateDetailItem(rowIndex, updated);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Gagal membuka data item stock: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Supply' : 'Create New Supply')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Stock Supply - Edit Header' : 'Stock Supply - Header'),
        actions: [
          TextButton(
            onPressed: _saveHeaderAndProceed,
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // Header Section
              Container(
                color: AppColors.surfaceCard,
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
                            'Template: \u201c$_templateName\u201d',
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
                                        onTap: () => _browseWarehouse(isFrom: true),
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
                                        onTap: () => _browseWarehouse(isFrom: false),
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
                            if (_isVisible('Order ID') || _isVisible('Seq ID'))
                              Row(
                                children: [
                                  if (_isVisible('Order ID'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _orderIdController,
                                        readOnly: true,
                                        decoration: _inputDecoration(
                                          'Order ID',
                                          readOnly: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  if (_isVisible('Order ID') && _isVisible('Seq ID')) const SizedBox(width: 16),
                                  if (_isVisible('Seq ID'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _orderSeqIdController,
                                        readOnly: true,
                                        decoration: _inputDecoration(
                                          'Seq ID',
                                          readOnly: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                ],
                              ),
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
                                        showCursor: false,
                                        enableInteractiveSelection: false,
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
                            if (_isVisible('Unit') || _isVisible('Size'))
                              const SizedBox(height: 16),
                            if (_isVisible('Unit') || _isVisible('Size'))
                              Row(
                                children: [
                                  if (_isVisible('Unit'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _orderUnitController,
                                        readOnly: true,
                                        decoration: _inputDecoration(
                                          'Unit',
                                          readOnly: true,
                                        ),
                                      ),
                                    ),
                                  if (_isVisible('Unit') && _isVisible('Size')) const SizedBox(width: 16),
                                  if (_isVisible('Size'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _sizeController,
                                        readOnly: true,
                                        decoration: _inputDecoration(
                                          'Size',
                                          readOnly: true,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            if (_isVisible('Unit') || _isVisible('Size')) const SizedBox(height: 16),
                            if (_isVisible('Lot No'))
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lotNumberController,
                                      readOnly: true,
                                      decoration: _inputDecoration(
                                        'Lot No',
                                        readOnly: true,
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

                  // Other Information
                  if (_isVisible('Other Information'))
                    ExpansionTile(
                      title: const Text(
                        'Other Information',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_isVisible('Reference No.'))
                                TextFormField(
                                  controller: _refNoController,
                                  readOnly: _isReadOnly('Reference No.'),
                                  decoration: _inputDecoration(
                                    'Reference No.',
                                    readOnly: _isReadOnly('Reference No.'),
                                  ),
                                ),
                              if (_isVisible('Reference No.')) const SizedBox(height: 16),
                              if (_isVisible('Remarks'))
                                TextFormField(
                                  controller: _remarksController,
                                  readOnly: _isReadOnly('Remarks'),
                                  decoration: _inputDecoration(
                                    'Remarks',
                                    readOnly: _isReadOnly('Remarks'),
                                  ),
                                  maxLines: 2,
                                ),
                              if (_isVisible('Save by template'))
                                CheckboxListTile(
                                  value: _useTemplate,
                                  onChanged: (v) async {
                                    setState(() => _useTemplate = v ?? false);
                                    await _initializeNewSupply();
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
                                        controller: _preparedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: (AuthService.currentUser?.toLowerCase() == 'admin')
                                            ? () => _browseEmployee(field: 'Prepared')
                                            : null,
                                        decoration: _inputDecoration(
                                          'Prepared',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: Icon(
                                            Icons.person_outline,
                                            color: (AuthService.currentUser?.toLowerCase() == 'admin')
                                                ? null
                                                : Colors.grey,
                                          ),
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
                                        controller: _approvedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: (AuthService.currentUser?.toLowerCase() == 'admin')
                                            ? () => _browseEmployee(field: 'Approved')
                                            : null,
                                        decoration: _inputDecoration(
                                          'Approved',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: Icon(
                                            Icons.person_outline,
                                            color: (AuthService.currentUser?.toLowerCase() == 'admin')
                                                ? null
                                                : Colors.grey,
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
                                        controller: _receivedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: (AuthService.currentUser?.toLowerCase() == 'admin')
                                            ? () => _browseEmployee(field: 'Received')
                                            : null,
                                        decoration: _inputDecoration(
                                          'Received',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: Icon(
                                            Icons.person_outline,
                                            color: (AuthService.currentUser?.toLowerCase() == 'admin')
                                                ? null
                                                : Colors.grey,
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

                  // Column1 display moved out; show only if present
                  if (_isVisible('Column1'))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _column1Controller,
                              readOnly: _isReadOnly('Column1'),
                              decoration: _inputDecoration(
                                'Column1',
                                readOnly: _isReadOnly('Column1'),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ExpansionTile(
                  title: const Text(
                    'Detail Items',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _addDetailItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
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
                                  for (final entry in _detailItems.asMap().entries) ...[
                                    if (entry.key != 0) const SizedBox(height: 12),
                                    SizedBox(
                                      width: 1200,
                                      child: DetailItemRow(
                                        key: ValueKey('detail_row_${entry.key}'),
                                        item: entry.value,
                                        onChanged: (updated) => _updateDetailItem(entry.key, updated),
                                        onDelete: _isLoading ? null : () => _removeDetailItem(entry.key),
                                        onBrowse: _isLoading ? null : () => _browseItemStockByLotForRow(entry.key),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        'Total Item: $_totalDetailItemCount',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Total Qty: ${_totalDetailQty.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Fill the header and detail information, then tap SAVE to submit.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class DetailItemRow extends StatefulWidget {
  const DetailItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    this.onDelete,
    this.onBrowse,
    this.readOnly = false,
  });

  final SupplyDetailItem item;
  final ValueChanged<SupplyDetailItem> onChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onBrowse;
  final bool readOnly;

  @override
  State<DetailItemRow> createState() => _DetailItemRowState();
}

class _DetailItemRowState extends State<DetailItemRow> {
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
    _itemCodeController = TextEditingController(text: widget.item.itemCode);
    _itemNameController = TextEditingController(text: widget.item.itemName);
    _qtyController = TextEditingController(text: _formatQty(widget.item.qty));
    _unitController = TextEditingController(text: widget.item.unit);
    _lotNumberController = TextEditingController(text: widget.item.lotNumber);
    _heatNumberController = TextEditingController(text: widget.item.heatNumber);
    _descriptionController = TextEditingController(text: widget.item.description);
  }

  @override
  void didUpdateWidget(covariant DetailItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _itemCodeController.text = widget.item.itemCode;
      _itemNameController.text = widget.item.itemName;
      _qtyController.text = _formatQty(widget.item.qty);
      _unitController.text = widget.item.unit;
      _lotNumberController.text = widget.item.lotNumber;
      _heatNumberController.text = widget.item.heatNumber;
      _descriptionController.text = widget.item.description;
    }
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

  void _emitChange() {
    widget.onChanged(
      widget.item.copyWith(
        itemCode: _itemCodeController.text.trim(),
        itemName: _itemNameController.text.trim(),
        qty: double.tryParse(_qtyController.text.trim().replaceAll(',', '.')) ?? 0,
        unit: _unitController.text.trim(),
        lotNumber: _lotNumberController.text.trim(),
        heatNumber: _heatNumberController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      filled: true,
      fillColor: widget.readOnly ? AppColors.readOnlyYellow : AppColors.surfaceCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _itemCodeController,
            readOnly: widget.readOnly,
            decoration: _decoration('Item Code').copyWith(
              suffixIcon: IconButton(
                tooltip: 'Browse Item Stock',
                icon: const Icon(Icons.inventory),
                onPressed: widget.readOnly ? null : widget.onBrowse,
              ),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _itemNameController,
            readOnly: widget.readOnly,
            decoration: _decoration('Item Name'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _qtyController,
            readOnly: widget.readOnly,
            decoration: _decoration('Qty'),
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _unitController,
            readOnly: widget.readOnly,
            decoration: _decoration('Unit'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _lotNumberController,
            readOnly: widget.readOnly,
            decoration: _decoration('Lot Number'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _heatNumberController,
            readOnly: widget.readOnly,
            decoration: _decoration('Heat Number'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _descriptionController,
            readOnly: widget.readOnly,
            decoration: _decoration('Description'),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: IconButton(
            onPressed: widget.readOnly ? null : widget.onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            tooltip: 'Remove item',
          ),
        ),
      ],
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

