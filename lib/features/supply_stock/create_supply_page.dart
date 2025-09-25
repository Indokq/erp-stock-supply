import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'supply_detail_page.dart';

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
  bool _isBrowsingItems = false;
  bool _isBrowsingWarehouses = false;
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

  // Column metadata from API (tbl0)
  final Map<String, _ColumnMeta> _columnMeta = {};

  // State to keep track of expansion tiles
  bool _signatureInfoExpanded = false;

  bool _isVisible(String colName) {
    final m = _columnMeta[colName];
    if (m == null) return false; // strict: only show when meta says visible
    return m.colVisible == 1;
  }

  void _hydrateFromHeader(SupplyHeader header) {
    _supplyIdController.text = header.supplyId.toString();
    _supplyNumberController.text = header.supplyNo;
    _supplyDate = header.supplyDate;
    _supplyFromController.text = header.fromId;
    _supplyToController.text = header.toId;
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
    _preparedByController.text = header.preparedBy.toString();
    _preparedController.text = header.prepared;
    _approvedByController.text = header.approvedBy.toString();
    _approvedController.text = header.approved;
    _receivedByController.text = header.receivedBy.toString();
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
    _signatureInfoExpanded = false; // Default to collapsed
    
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
  }

  @override
  void dispose() {
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
      final result = await ApiService.createNewSupply(
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
            _preparedByController.text = header.preparedBy.toString();
            _preparedController.text = header.prepared;
            _approvedByController.text = header.approvedBy.toString();
            _approvedController.text = header.approved;
            _receivedByController.text = header.receivedBy.toString();
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

    setState(() => _isLoading = true);
    try {
      // Optionally call an API to persist header first (if needed).
      // For now we proceed to detail page, carrying header data object.

      final header = SupplyHeader(
        supplyId: widget.isEdit
            ? int.tryParse(_supplyIdController.text.trim()) ?? 0
            : 0, // Still use the ID if in edit mode, otherwise 0 for new record
        supplyNo: _supplyNumberController.text.trim(),
        supplyDate: _supplyDate,
        fromId: _supplyFromController.text.trim(),
        // From Org / To Org removed from UI
        toId: _supplyToController.text.trim(),
        orderId: int.tryParse(_orderIdController.text.trim()) ?? 0,
        orderNo: _orderNoController.text.trim(),
        projectNo: _projectNoController.text.trim(),
        orderSeqId: int.tryParse(_orderSeqIdController.text.trim()) ?? 0,
        itemCode: _itemCodeController.text.trim(),
        itemName: _itemNameController.text.trim(),
        qty: double.tryParse(_qtyOrderController.text.trim().replaceAll(',', '.')),
        orderUnit: _orderUnitController.text.trim(),
        lotNumber: _lotNumberController.text.trim(),
        heatNumber: _heatNoController.text.trim(),
        size: _sizeController.text.trim(),
        refNo: _refNoController.text.trim(),
        remarks: _remarksController.text.trim(),
        templateSts: _templateSts,
        templateName: _templateNameController.text.trim().isNotEmpty
            ? _templateNameController.text.trim()
            : _templateName,
        preparedBy: _preparedById,  // Use the stored ID instead of parsing from controller
        prepared: _preparedController.text.trim(),
        approvedBy: _approvedById,  // Use the stored ID instead of parsing from controller
        approved: _approvedController.text.trim(),
        receivedBy: _receivedById,  // Use the stored ID instead of parsing from controller
        received: _receivedController.text.trim(),
        column1: int.tryParse(_column1Controller.text.trim()) ?? 0,
      );

      // Navigate to detail page and replace current header page
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SupplyDetailPage(
            header: header,
            initialItems: widget.initialDetailItems,
          ),
        ),
      );
    } catch (e) {
      _showErrorMessage('Failed to proceed to detail: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (_isBrowsingWarehouses) return;
    FocusScope.of(context).unfocus();
    setState(() => _isBrowsingWarehouses = true);

    bool overlayShown = false;
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      overlayShown = true;

      final browseResult = await ApiService.browseWarehouses(companyId: 1);

      if (!mounted) {
        if (overlayShown) {
          try {
            navigator.pop();
          } catch (_) {}
        }
        return;
      }

      if (overlayShown) {
        navigator.pop();
        overlayShown = false;
      }

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
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.7,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFrom ? 'Pilih Supply From' : 'Pilih Supply To',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = visibleItems[index];
                        final title = _getStringValue(
                              row,
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
                            ) ??
                            'Warehouse ${index + 1}';
                        final code = _getStringValue(
                          row,
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
                        final location = _getStringValue(
                          row,
                          const [
                            'Location',
                            'Address',
                            'City',
                            'colLocation',
                            'collocation',
                            'colAddr',
                          ],
                          partialMatches: const ['lokasi', 'location', 'address', 'city'],
                        );

                        final selection = Map<String, dynamic>.from(row)
                          ..putIfAbsent('_displayName', () => title)
                          ..putIfAbsent('_displayCode', () => code);

                        final details = <String>[];
                        if (code != null) details.add(code);
                        if (location != null) details.add(location);

                        return ListTile(
                          title: Text(title),
                          subtitle: details.isEmpty ? null : Text(details.join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
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

      _applyWarehouseSelection(selected, isFrom: isFrom);
    } catch (e) {
      if (!mounted) return;
      if (overlayShown) {
        try {
          navigator.pop();
        } catch (_) {}
        overlayShown = false;
      }
      _showErrorMessage('Gagal membuka data gudang: $e');
    } finally {
      if (mounted) {
        if (overlayShown) {
          try {
            navigator.pop();
          } catch (_) {}
        }
        setState(() => _isBrowsingWarehouses = false);
      } else {
        _isBrowsingWarehouses = false;
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

    final chosen = code ?? name ?? _stringifyValue(data['_displayName']);
    final trimmed = chosen?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    if (controller.text.trim() == trimmed) return;

    controller.text = trimmed;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _browseItemName() async {
    if (_isBrowsingItems) return;
    FocusScope.of(context).unfocus();
    setState(() => _isBrowsingItems = true);

    bool overlayShown = false;
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      overlayShown = true;

      final browseResult = await ApiService.browseItemStockByLot(id: 12, companyId: 1);

      if (!mounted) return;

      if (overlayShown) {
        navigator.pop();
        overlayShown = false;
      }

      if (browseResult['success'] != true) {
        final message = browseResult['message'] as String? ?? 'Tidak dapat memuat data item';
        _showErrorMessage(message);
        return;
      }

      final data = browseResult['data'];
      if (data is! Map<String, dynamic>) {
        _showErrorMessage('Data item tidak tersedia');
        return;
      }

      final items = _extractRows(data);
      if (items.isEmpty) {
        _showErrorMessage('Data item tidak tersedia');
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
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.85,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Browse Item Stock',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
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
                        final selection = Map<String, dynamic>.from(row)
                          ..putIfAbsent('_displayName', () => title);

                        final details = <String>[];
                        if (code != null) details.add(code);
                        if (lot != null) details.add('Lot: $lot');
                        if (qty != null) details.add('Qty: $qty');
                        if (unit != null) details.add(unit);

                        return ListTile(
                          title: Text(title),
                          subtitle: details.isEmpty ? null : Text(details.join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
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
      if (overlayShown) {
        try {
          navigator.pop();
        } catch (_) {}
        overlayShown = false;
      }
      _showErrorMessage('Gagal membuka data item: $e');
    } finally {
      if (mounted) {
        if (overlayShown) {
          try {
            navigator.pop();
          } catch (_) {}
        }
        setState(() => _isBrowsingItems = false);
      } else {
        _isBrowsingItems = false;
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

  List<Map<String, dynamic>> _extractRows(Map<String, dynamic> payload) {
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
            if (normalizedKey == 'tbl0' || normalizedKey.contains('field')) {
              final parsed = parseFieldDefinitions(value);
              if (parsed != null) {
                localFields = {
                  if (localFields != null) ...localFields,
                  ...parsed,
                };
              }
              if (normalizedKey == 'tbl0') {
                continue;
              }
            }
          }
        }

        for (final entry in node.entries) {
          final value = entry.value;
          if (value is List) {
            final normalizedKey = _normalizeKey(entry.key);
            if (normalizedKey == 'tbl0' || normalizedKey.contains('field')) {
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

  Map<String, dynamic>? _extractFirstRow(Map<String, dynamic> payload) {
    final rows = _extractRows(payload);
    return rows.isNotEmpty ? rows.first : null;
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

  void _applyItemSelection(Map<String, dynamic> data) {
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
        partialMatches: const ['heat'],
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
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.7,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilih $field',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
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
                          title: Text(name),
                          subtitle: details.isEmpty ? null : Text(details.join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
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
      case 'Prepared By':
        if (_preparedByController.text.trim() != trimmedDisplay) {
          _preparedByController.text = trimmedDisplay;
          _preparedById = idValue != null ? int.tryParse(idValue) ?? 0 : 0;
          if (mounted) setState(() {});
        }
        break;
      case 'Approved By':
        if (_approvedByController.text.trim() != trimmedDisplay) {
          _approvedByController.text = trimmedDisplay;
          _approvedById = idValue ?? '';
          if (mounted) setState(() {});
        }
        break;
      case 'Received By':
        if (_receivedByController.text.trim() != trimmedDisplay) {
          _receivedByController.text = trimmedDisplay;
          _receivedById = idValue ?? '';
          if (mounted) setState(() {});
        }
        break;
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
                            
                            const SizedBox(height: 16),
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
                                          suffixIcon: const Icon(Icons.search),
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
                                          suffixIcon: const Icon(Icons.search),
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
                                        decoration: _inputDecoration(
                                          'Order No.',
                                          readOnly: true,
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
                                        onTap: _browseItemName,
                                        decoration: _inputDecoration(
                                          'Item Name',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: const Icon(Icons.search),
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
                            if (_isVisible('Lot No') || _isVisible('Reference No.'))
                              Row(
                                children: [
                                  if (_isVisible('Lot No'))
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
                                  if (_isVisible('Lot No') && _isVisible('Reference No.')) const SizedBox(width: 16),
                                  if (_isVisible('Reference No.'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _refNoController,
                                        readOnly: true,
                                        decoration: _inputDecoration(
                                          'Reference No.',
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
                      initiallyExpanded: _signatureInfoExpanded,
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _signatureInfoExpanded = expanded;
                        });
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_isVisible('Prepared By'))
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _preparedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: () => _browseEmployee(field: 'Prepared By'),
                                        decoration: _inputDecoration(
                                          'Prepared By',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: const Icon(Icons.search),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_isVisible('Prepared By')) const SizedBox(height: 16),
                              if (_isVisible('Approved By'))
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _approvedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: () => _browseEmployee(field: 'Approved By'),
                                        decoration: _inputDecoration(
                                          'Approved By',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: const Icon(Icons.search),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_isVisible('Approved By')) const SizedBox(height: 16),
                              if (_isVisible('Received By'))
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _receivedByController,
                                        readOnly: true,
                                        showCursor: false,
                                        enableInteractiveSelection: false,
                                        onTap: () => _browseEmployee(field: 'Received By'),
                                        decoration: _inputDecoration(
                                          'Received By',
                                          readOnly: true,
                                        ).copyWith(
                                          suffixIcon: const Icon(Icons.search),
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
            // Optional info note under the header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'After saving the header, you will be redirected to the Detail page.',
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
