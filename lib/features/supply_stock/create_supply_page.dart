import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../shared/widgets/shared_cards.dart';
import '../shared/utils/formatters.dart';
import '../shared/services/api_service.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/barcode_scanner_service.dart';
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
  bool _isScanning = false;
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
    // Ensure key order fields remain visible even if metadata missing/mismatched
    'Unit',
    'Size',
    'Lot No',
  };

  bool _isVisible(String colName) {
    // Normalize for robust matching (e.g., 'Lot No', 'Lot_No', 'LOT NO')
    String key = colName.trim();
    final normalized = _normalizeKey(key);

    // Map common aliases to canonical keys used in UI
    String canonical = colName;
    if (normalized.contains('lot') && normalized.contains('no')) {
      canonical = 'Lot No';
    } else if (normalized == 'unit' || normalized.contains('uom')) {
      canonical = 'Unit';
    } else if (normalized == 'size' || normalized.contains('dimension')) {
      canonical = 'Size';
    }

    final m = _columnMeta[canonical] ?? _columnMeta[colName];
    if (m == null) {
      return _fallbackVisibleCols.contains(canonical);
    }
    if (m.colVisible == 1) {
      return true;
    }
    return _fallbackVisibleCols.contains(canonical);
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

  int? _findDuplicateItem(SupplyDetailItem item, {int? excludeIndex}) {
    for (int i = 0; i < _detailItems.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;
      
      final existing = _detailItems[i];
      if (_areItemsIdentical(existing, item)) {
        return i;
      }
    }
    return null;
  }

  bool _areItemsIdentical(SupplyDetailItem item1, SupplyDetailItem item2) {
    // Jangan consider sebagai duplicate kalau itemCode kosong (item masih baru/kosong)
    final code1 = item1.itemCode.trim();
    final code2 = item2.itemCode.trim();
    if (code1.isEmpty || code2.isEmpty) return false;
    
    return code1.toLowerCase() == code2.toLowerCase() &&
           item1.lotNumber.trim().toLowerCase() == item2.lotNumber.trim().toLowerCase() &&
           item1.heatNumber.trim().toLowerCase() == item2.heatNumber.trim().toLowerCase() &&
           item1.size.trim().toLowerCase() == item2.size.trim().toLowerCase();
  }

  void _removeDetailItem(int index) {
    if (index < 0 || index >= _detailItems.length) return;
    setState(() {
      _detailItems.removeAt(index);
      if (_detailItems.isEmpty) {
        // Langsung navigate ke halaman blank baru tanpa save
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToBlankPage();
        });
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

    // Validasi awal: Cek apakah ada detail items dan valid
    if (_detailItems.isEmpty) {
      _showErrorMessage('Tidak ada detail item. Header tidak akan disimpan.');
      return;
    }

    // Cek apakah ada detail item yang benar-benar valid
    final validItems = _detailItems.where((item) {
      final code = item.itemCode.trim();
      final qty = item.qty;
      return code.isNotEmpty && qty > 0; // qty harus > 0
    }).toList();

    debugPrint('🔍 Detail validation: Total items: ${_detailItems.length}, Valid items: ${validItems.length}');
    for (var i = 0; i < _detailItems.length; i++) {
      final item = _detailItems[i];
      debugPrint('  Item $i: code="${item.itemCode.trim()}", qty=${item.qty}');
    }

    if (validItems.isEmpty) {
      debugPrint('❌ NO VALID DETAILS - BLOCKING SAVE');
      _showErrorMessage('Semua detail item tidak valid (item code kosong atau qty = 0). Header tidak akan disimpan.');
      return;
    }

    debugPrint('✅ VALID DETAILS FOUND - PROCEEDING WITH SAVE');

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
        debugPrint('🔍 Processing item: code="$code", qty=$qty');

        // Skip invalid items (same condition as validation)
        if (code.isEmpty || qty <= 0) { // qty harus > 0, jadi skip jika <= 0
          debugPrint('⚠️ Skipping invalid item: code="$code", qty=$qty');
          continue;
        }

        int? resolveInt(dynamic value) => _parseIntValue(value);

        int? resolvedItemId = item.itemId;
        int? resolvedUnitId = item.unitId;
        if (resolvedItemId == null || resolvedItemId <= 0) {
          // Only trust explicit item id fields, don't use generic 'ID' or code
          resolvedItemId = resolveInt(item.raw?['Item_ID']) ??
              resolveInt(item.raw?['ItemId']) ??
              resolveInt(item.raw?['ItemID']) ??
              resolveInt(item.raw?['Item_Id']);
        }

        if (resolvedUnitId == null || resolvedUnitId <= 0) {
          resolvedUnitId = resolveInt(item.raw?['Unit_ID']) ??
              resolveInt(item.raw?['UnitId']) ??
              resolveInt(item.raw?['UnitID']) ??
              resolveInt(item.raw?['UOM_ID']) ??
              resolveInt(item.raw?['UomId']) ??
              resolveInt(item.raw?['Item_Unit_ID']) ??
              resolveInt(item.raw?['Unit_Stock']);
        }

        // Validasi setiap detail item sebelum masuk payload
        if (resolvedItemId == null || resolvedItemId <= 0) {
          debugPrint('❌ Invalid itemId for code: $code');
          _showErrorMessage('Item "$code" tidak memiliki ID yang valid. Header tidak akan disimpan.');
          return;
        }


        final seqId = _resolveSeqIdForDetail(item);

        detailsPayload.add({
          'itemId': resolvedItemId,
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

      // Validasi: Jika tidak ada detail yang valid, jangan save header
      debugPrint('🔍 Payload validation: detailsPayload.length = ${detailsPayload.length}');
      if (detailsPayload.isEmpty) {
        debugPrint('❌ EMPTY PAYLOAD - BLOCKING SAVE');
        _showErrorMessage('Tidak ada detail item yang valid untuk disimpan. Header tidak akan disimpan.');
        return;
      }

      // Validasi final: Pastikan semua detail dalam payload valid
      for (int i = 0; i < detailsPayload.length; i++) {
        final detail = detailsPayload[i];
        final itemId = detail['itemId'];
        final qty = detail['qty'];

        if (itemId == null || itemId <= 0) {
          debugPrint('❌ Payload item $i has invalid itemId: $itemId');
          _showErrorMessage('Detail item ke-${i+1} memiliki ID item yang tidak valid. Header tidak akan disimpan.');
          return;
        }

        if (qty == null || qty <= 0) {
          debugPrint('❌ Payload item $i has invalid qty: $qty');
          _showErrorMessage('Detail item ke-${i+1} memiliki quantity yang tidak valid. Header tidak akan disimpan.');
          return;
        }
      }

      debugPrint('✅ ALL PAYLOAD ITEMS VALIDATED - SKIPPING STOCK CHECK');

      // VALIDASI STOCK AVAILABILITY DI-DISABLE
      // Biar bisa save tanpa cek lot/heat
      // try {
      //   await _validateStockAvailability(detailsPayload);
      // } catch (e) {
      //   debugPrint('❌ Stock validation failed: $e');
      //   return;
      // }

      debugPrint('⚠️ STOCK VALIDATION SKIPPED - PROCEEDING WITH API CALL');

      Map<String, dynamic> result;
      // If we already have a Supply_ID (saved before), update header and only add new details.
      final existingId = int.tryParse(_supplyIdController.text.trim());
      if (existingId != null && existingId > 0) {
        result = await ApiService.updateSupplyWithNewDetails(
          supplyId: existingId,
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
      } else {
        result = await ApiService.createSupplyWithDetails(
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
      }

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
        // After updating, reload details so the form reflects server state
        await _loadSupplyDetails();
        // Tetap di halaman Create setelah save sukses
        // Opsional: scroll ke atas atau highlight nomor dokumen baru
        // Tidak melakukan Navigator.pop agar tetap di halaman ini
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

      final List<Map<String, dynamic>> rows = [];
      // Collect rows from typical tbl buckets
      for (var i = 0; i < 10; i++) {
        final key = 'tbl$i';
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
        _showErrorMessage('Data gudang tidak tersedia');
        return;
      }

      final items = rows;

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
          return _WarehousePickerSheet(
            title: isFrom ? 'Pilih Supply From' : 'Pilih Supply To',
            items: items,
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
    final name = (data['Org_Name'] ?? data['_displayName'] ?? '').toString();
    final code = (data['Org_Code'] ?? data['_displayCode'] ?? '').toString();
    final id = (data['ID'] ?? '').toString();

    final idInt = _parseIntValue(id);
    if (isFrom) {
      _fromWarehouseId = idInt;
    } else {
      _toWarehouseId = idInt;
    }
    
    // Build display text with Name only (user request)
    final chosen = name.isNotEmpty ? name : code;
    
    debugPrint('Warehouse selection (${isFrom ? 'from' : 'to'}): id=$id, display=$chosen');
    if (chosen.isNotEmpty && controller.text.trim() != chosen.trim()) {
      controller.text = chosen.trim();
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
    return targets.contains(key);
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
          String? selectedOrderId;
          Map<String, dynamic>? selectedItem;
          return StatefulBuilder(
            builder: (context, setModal) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) => Container(
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
                      controller: scrollController,
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
                        final orderId = _getStringValue(
                          row,
                          const [
                            'Order_ID',
                            'OrderId',
                            'ID_Order',
                            'ID',
                          ],
                          partialMatches: const ['orderid', 'idorder'],
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

                        // Use unique identifier for comparison
                        final itemId = orderId ?? orderNo ?? index.toString();
                        final isSelected = selectedOrderId == itemId;

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
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : const Icon(Icons.chevron_right, color: Colors.grey),
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryBlue.withOpacity(0.1),
                          onTap: () {
                            debugPrint('🔘 Order Entry item tapped: $itemId');
                            setModal(() {
                              selectedOrderId = itemId;
                              selectedItem = selection;
                              debugPrint('✅ Order Entry selection state updated: $selectedOrderId');
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedItem == null
                                ? null
                                : () => Navigator.of(sheetContext).pop(selectedItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirm Selection'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                ),
              );
            },
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
    );
    final heatNo = _getStringValue(
      data,
      const ['Heat_No', 'HeatNo', 'Heat_Number'],
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
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          String? selectedEmployeeId;
          Map<String, dynamic>? selectedItem;
          return StatefulBuilder(
            builder: (context, setModal) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) => Container(
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
                          controller: scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: visibleItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final row = visibleItems[index];
                            final employeeId = _getStringValue(
                              row,
                              const [
                                'Employee_ID',
                                'EmployeeId',
                                'ID',
                              ],
                              partialMatches: const ['employeeid', 'id'],
                            );
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
                                'colCode',
                                'colcode',
                              ],
                              partialMatches: const ['employeecode', 'karyawan', 'code'],
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

                            final itemId = employeeId ?? code ?? index.toString();
                            final isSelected = selectedEmployeeId == itemId;

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
                              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : const Icon(Icons.chevron_right, color: Colors.grey),
                              selected: isSelected,
                              selectedTileColor: AppColors.primaryBlue.withOpacity(0.1),
                              onTap: () {
                                debugPrint('👤 Employee item tapped: $itemId');
                                setModal(() {
                                  selectedEmployeeId = itemId;
                                  selectedItem = selection;
                                  debugPrint('✅ Employee selection state updated: $selectedEmployeeId');
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(sheetContext).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedItem == null
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(selectedItem),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Confirm Selection'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
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

  Future<void> _validateStockAvailability(List<Map<String, dynamic>> detailsPayload) async {
    final fromId = _fromWarehouseId ?? _parseIntValue(_supplyFromController.text) ?? 0;
    if (fromId == 0) {
      _showErrorMessage('Warehouse From tidak valid untuk validasi stock.');
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
        // Ambil data stock dari warehouse untuk item ini
        final dateStr = _supplyDate.toIso8601String().split('T').first;
        final stockResult = await ApiService.browseItemStockByLot(
          id: fromId,
          companyId: 1,
          dateStart: dateStr,
          dateEnd: dateStr,
        );

        if (stockResult['success'] != true) {
          _showErrorMessage('Gagal mengecek stock untuk item ke-${i+1}. Header tidak akan disimpan.');
          throw Exception('Stock check failed');
        }

        final stockData = stockResult['data'];
        if (stockData is! Map<String, dynamic>) {
          _showErrorMessage('Data stock tidak tersedia untuk validasi item ke-${i+1}. Header tidak akan disimpan.');
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
            final siLot = _getStringValue(si, const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot']) ?? '';
            final siHeat = _getStringValue(si, const ['Heat_No', 'HeatNo', 'Heat_Number']) ?? '';
            final siCode = _getStringValue(si, const ['Item_Code', 'ItemCode', 'Code'], partialMatches: const ['itemcode', 'code']) ?? '';
            debugPrint('  [$idx] ID=$siId, Code="$siCode", Lot="$siLot", Heat="$siHeat"');
          }
          if (stockItems.length > 5) {
            debugPrint('  ... and ${stockItems.length - 5} more items');
          }
        }

        // Cari item yang sesuai berdasarkan itemId ONLY (lot/heat diabaikan)
        final matchingStock = stockItems.where((stockItem) {
          final stockItemId = _parseIntValue(_getFirstValue(
            stockItem,
            const ['Item_ID', 'ItemId', 'ID'],
            partialMatches: const ['itemid', 'stockid', 'id'],
          ));

          final itemIdMatches = stockItemId == itemId;
          
          debugPrint('  🔍 Item: stockId=$stockItemId vs $itemId → ${itemIdMatches ? "✓ MATCH" : "✗ NO MATCH"}');

          // SIMPLE MATCH: Hanya cek itemId, lot dan heat DIABAIKAN
          return itemIdMatches;
        }).toList();

        debugPrint('🎯 Matching stock items found: ${matchingStock.length}');

        if (matchingStock.isEmpty) {
          _showErrorMessage(
            'Item ke-${i+1} tidak ditemukan di warehouse atau lot/heat tidak sesuai.\n'
            'Dicari: ItemID=$itemId, Lot="$lotNumber", Heat="$heatNumber"\n'
            'Pastikan item dengan lot/heat tersebut ada di warehouse yang dipilih.\n'
            'Header tidak akan disimpan.'
          );
          throw Exception('Item not found in stock');
        }

        // Ambil available quantity
        final stockItem = matchingStock.first;
        final availableQty = double.tryParse(
          _getStringValue(
            stockItem,
            const ['Qty', 'Quantity', 'Qty_Available', 'Balance', 'Stock'],
            partialMatches: const ['qty', 'quantity', 'balance', 'stock'],
          )?.replaceAll(',', '.') ?? '0'
        ) ?? 0.0;

        debugPrint('📦 Available stock: $availableQty, Requested: $requestedQty');

        if (availableQty < requestedQty) {
          final itemCode = _getStringValue(
            stockItem,
            const ['Item_Code', 'ItemCode', 'Code'],
            partialMatches: const ['itemcode', 'code'],
          ) ?? 'Item-$itemId';

          _showErrorMessage(
            'Stock tidak cukup untuk item "$itemCode":\n'
            'Available: ${availableQty.toStringAsFixed(2)}\n'
            'Requested: ${requestedQty.toStringAsFixed(2)}\n'
            'Header tidak akan disimpan.'
          );
          throw Exception('Insufficient stock');
        }

      } catch (e) {
        if (e.toString().contains('Insufficient stock') ||
            e.toString().contains('Stock check failed') ||
            e.toString().contains('Item not found') ||
            e.toString().contains('Invalid warehouse')) {
          rethrow;
        }
        debugPrint('❌ Error checking stock: $e');
        _showErrorMessage('Error saat mengecek stock item ke-${i+1}: $e. Header tidak akan disimpan.');
        throw Exception('Stock validation error: $e');
      }
    }
  }

  Future<void> _loadSupplyDetails() async {
    final idText = _supplyIdController.text.trim();
    final supplyId = int.tryParse(idText);
    if (supplyId == null || supplyId <= 0) {
      return;
    }

    try {
      final res = await ApiService.getSupplyDetail(
        supplyCls: 1,
        supplyId: supplyId,
        userEntry: 'admin',
        companyId: 1,
      );

      if (res['success'] == true) {
        final data = res['data'];
        final rows = (data is Map<String, dynamic>) ? data['tbl1'] : null;
        final items = <SupplyDetailItem>[];
        if (rows is List) {
          for (final r in rows.whereType<Map>()) {
            final m = r.cast<String, dynamic>();
            final itemCode = _getStringValue(m, const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'ColCode'], partialMatches: const ['itemcode', 'code']);
            final itemName = _getStringValue(m, const ['Item_Name', 'ItemName', 'Name', 'Description', 'Column1', 'Column_1'], partialMatches: const ['itemname', 'description']);
            final lot = _getStringValue(m, const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot']);
            final heat = _getStringValue(m, const ['Heat_No', 'HeatNo', 'Heat_Number']);
            final unit = _getStringValue(m, const ['Unit', 'Item_Unit', 'UOM', 'Unit_Stock'], partialMatches: const ['unit', 'uom']);
            final size = _getStringValue(m, const ['Size', 'Item_Size', 'colSize', 'ColSize'], partialMatches: const ['size', 'dimension']);
            final qtyString = _getStringValue(m, const ['Qty', 'Quantity', 'Qty_Order']);
            final qty = qtyString != null ? double.tryParse(qtyString.replaceAll(',', '')) ?? 0.0 : 0.0;
            final itemId = _parseIntValue(_getFirstValue(m, const ['Item_ID', 'ItemId', 'ID'], partialMatches: const ['itemid', 'id']));
            final unitId = _parseIntValue(_getFirstValue(m, const ['Unit_ID', 'UnitId', 'UOM_ID', 'Unit_Stock'], partialMatches: const ['unitid', 'uomid']));
            final seqId = _getStringValue(m, const ['Seq_ID', 'SeqId', 'Seq', 'Seq_ID_Detail'], partialMatches: const ['seq']) ?? '0';
            final desc = _getStringValue(m, const ['Description', 'Desc', 'Remark', 'Remarks', 'Notes'], partialMatches: const ['desc', 'remark', 'notes']) ?? '';

            items.add(
              SupplyDetailItem(
                itemCode: itemCode ?? '',
                itemName: itemName ?? '',
                qty: qty,
                unit: unit ?? '',
                lotNumber: lot ?? '',
                heatNumber: heat ?? '',
                description: desc,
                size: size ?? '',
                itemId: itemId,
                seqId: seqId,
                unitId: unitId,
                raw: m,
              ),
            );
          }
        }

        setState(() {
          _detailItems = items.isNotEmpty ? items : [_createEmptyDetailItem()];
        });
      }
    } catch (_) {
      // Ignore load errors silently
    }
  }

  void _navigateToBlankPage() {
    // Langsung ke halaman create supply baru yang blank
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSupplyPage(),
      ),
    );
  }

  Future<void> _deleteHeaderAndNavigateBack() async {
    if (!widget.isEdit) {
      _navigateToNewSupplyPage();
      return;
    }

    final supplyId = int.tryParse(_supplyIdController.text.trim()) ?? 0;
    if (supplyId == 0) {
      _navigateToNewSupplyPage();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.deleteSupply(supplyId: supplyId);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Header deleted: All detail items were removed'),
            backgroundColor: AppColors.success,
          ),
        );
        _navigateToNewSupplyPage();
      } else {
        final message = result['message']?.toString() ?? 'Failed to delete header';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
        _navigateToNewSupplyPage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting header: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      _navigateToNewSupplyPage();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToNewSupplyPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSupplyPage(),
      ),
    );
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
      ),
    );
    setValue(
      _heatNoController,
      _getStringValue(
        data,
        const ['Heat_No', 'HeatNo', 'Heat_Number'],
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

  SupplyDetailItem _mergeDetailItemFromStock({
    required SupplyDetailItem current,
    required Map<String, dynamic> primaryData,
    Map<String, dynamic>? fallbackRaw,
  }) {
    String? resolveValue(List<String> keys, {List<String> partialMatches = const []}) {
      final primary = _getStringValue(
        primaryData,
        keys,
        partialMatches: partialMatches,
      );
      if (primary != null && primary.trim().isNotEmpty) {
        return primary.trim();
      }
      if (fallbackRaw == null) return null;
      final fallback = _getStringValue(
        fallbackRaw!,
        keys,
        partialMatches: partialMatches,
      );
      if (fallback == null) return null;
      final trimmedFallback = fallback.trim();
      return trimmedFallback.isNotEmpty ? trimmedFallback : null;
    }

    final combinedRaw = <String, dynamic>{};
    if (fallbackRaw != null) {
      combinedRaw.addAll(fallbackRaw);
    }
    combinedRaw.addAll(primaryData);

    final itemCode = resolveValue(
      const ['Item_Code', 'ItemCode', 'Code', 'colCode', 'colcode', 'ColCode'],
      partialMatches: const ['itemcode', 'kode', 'code'],
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
        'colName1',
        'colname1',
      ],
      partialMatches: const ['itemname', 'description', 'colname', 'namestock', 'namabarang'],
    );
    final lot = resolveValue(
      const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
    );
    final heat = resolveValue(
      const ['Heat_No', 'HeatNo', 'Heat_Number'],
    );
    String? unit = resolveValue(
      const ['OrderUnit', 'Unit', 'UOM', 'Unit_Stock'],
      partialMatches: const ['orderunit', 'unit', 'uom', 'stockunit'],
    );
    if (unit != null) {
      final ut = unit.trim();
      // If the picked unit looks numeric (likely an ID), try to prefer a textual unit name
      final isNumeric = RegExp(r'^-?\d+(\.0+)?$').hasMatch(ut);
      if (isNumeric) {
        unit = resolveValue(
              const ['OrderUnit', 'UOM', 'Unit', 'Unit_Name', 'UOM_Name'],
              partialMatches: const ['orderunit', 'uom', 'unit', 'unitname', 'uomname'],
            ) ?? ut;
      }
    }
    final size = resolveValue(
      const ['Size', 'Item_Size', 'colSize', 'colsize', 'ColSize'],
      partialMatches: const ['size', 'dimension'],
    );
    final qtyString = resolveValue(
      const ['Qty', 'Quantity', 'Qty_Available', 'Qty_Order', 'Balance', 'Unit_Stock', 'Stock'],
      partialMatches: const ['qty', 'quantity', 'jumlah', 'balance', 'stock'],
    );
    final description = resolveValue(
      const ['Description', 'Desc', 'Remark', 'Remarks', 'Notes'],
      partialMatches: const ['desc', 'remark', 'remarks', 'notes', 'keterangan'],
    );
    final parsedQty = qtyString != null
        ? double.tryParse(qtyString.replaceAll(',', '.'))
        : null;

    // Resolve itemId only from explicit item-id fields; avoid generic 'ID' which is often a row index
    final itemId = _parseIntValue(
      _getFirstValue(
        combinedRaw,
        const ['Item_ID', 'ItemId', 'ItemID', 'Item_Id'],
        partialMatches: const ['itemid'],
      ),
    );
    final unitId = _parseIntValue(
      _getFirstValue(
        combinedRaw,
        const ['Unit_ID', 'UnitId', 'UnitID', 'UOM_ID', 'Unit_Stock'],
        partialMatches: const ['unitid', 'uomid', 'unitstock'],
      ),
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
    final numericCode = _parseIntValue(code);

    var matches = rows.where((row) {
      final rowCode = _getStringValue(
        row,
        const ['Item_Code', 'ItemCode', 'Code', 'SKU', 'Barcode', 'Bar_Code'],
        partialMatches: const ['itemcode', 'kode', 'barcode', 'code', 'sku'],
      );
      final lot = _getStringValue(
        row,
        const ['Lot_No', 'LotNo', 'Lot_Number', 'Lot'],
      );
      final numericId = _parseIntValue(
        _getFirstValue(
          row,
          const ['Item_ID', 'ItemId', 'ID'],
          partialMatches: const ['itemid', 'stockid', 'id'],
        ),
      );

      final codeMatches = rowCode != null && rowCode.trim().toLowerCase() == normalized;
      final lotMatches = lot != null && lot.trim().toLowerCase() == normalized;
      final idMatches = numericCode != null && numericId != null && numericCode == numericId;

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
                      final code = _getStringValue(
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
                          name?.isNotEmpty == true ? name! : (code ?? 'Item ${index + 1}'),
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

  Future<void> _scanQRForDetailItem(int rowIndex) async {
    if (_isScanning) {
      // Prevent concurrent scanner launches; allow next tap after current finishes
      return;
    }
    _isScanning = true;
    final fromId = _fromWarehouseId ?? _parseIntValue(_supplyFromController.text) ?? 0;
    if (fromId == 0) {
      _showErrorMessage('Pilih gudang From terlebih dahulu sebelum scan barcode');
      _isScanning = false;
      return;
    }

    final scanResult = await BarcodeScannerService.instance.scanBarcode();
    if (scanResult.isCanceled) {
      _isScanning = false;
      return;
    }
    if (!scanResult.isSuccess) {
      if (scanResult.message != null && scanResult.message!.trim().isNotEmpty) {
        _showErrorMessage(scanResult.message!);
      }
      _isScanning = false;
      return;
    }

    final scannedCode = scanResult.barcode!.trim();
    if (scannedCode.isEmpty) {
      _showErrorMessage('Barcode tidak terbaca.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final matches = await _fetchStockMatchesByBarcode(
        warehouseId: fromId,
        code: scannedCode,
      );

      if (matches.isEmpty) {
        _showErrorMessage('Barang dengan barcode "$scannedCode" tidak ditemukan di gudang ini.');
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
      final detail = await _fetchItemDetail(selectionRaw);
      final source = detail ?? selectionRaw;
      _applyItemSelection(source);
      final updated = _mergeDetailItemFromStock(
        current: _detailItems[rowIndex],
        primaryData: source,
        fallbackRaw: selectionRaw,
      );
      
      // Check for duplicates and merge if found
      final duplicateIndex = _findDuplicateItem(updated, excludeIndex: rowIndex);
      if (duplicateIndex != null) {
        // Merge with existing item
        final existingItem = _detailItems[duplicateIndex];
        final mergedItem = existingItem.copyWith(
          qty: existingItem.qty + updated.qty,
        );
        setState(() {
          _detailItems[duplicateIndex] = mergedItem;
          _detailItems.removeAt(rowIndex);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${updated.itemCode}" digabung. Qty total: ${mergedItem.qty}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // No duplicate, update current row
        _updateDetailItem(rowIndex, updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${updated.itemCode}" berhasil diisi dari barcode.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Gagal memproses barcode: $e');
    } finally {
      _isScanning = false;
      if (mounted) setState(() => _isLoading = false);
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Item Stock',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                                ),
                                // Match Edit style: no extra subtitle line here
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _scanQRForDetailItem(rowIndex);
                              },
                              tooltip: 'Scan QR Code',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                onSubmitted: (v) => setModalState(() { applyFilter(v); }),
                                decoration: InputDecoration(
                                  hintText: 'Cari berdasarkan Item Code...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            searchCtrl.clear();
                                            setModalState(() { applyFilter(''); });
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => setModalState(() { applyFilter(searchCtrl.text); }),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
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
                            final code = _getStringValue(
                              row,
                              const ['Item_Code','ItemCode','Code','SKU','colCode','ColCode'],
                              partialMatches: const ['itemcode','code','sku'],
                            ) ?? '';
                            final name = _getStringValue(
                              row,
                              const ['Item_Name','ItemName','Name','Title','Description','colName','colname','ColName','Colname','colName1','colname1','Column1','Column_1'],
                              partialMatches: const ['itemname','name','title','desc','colname','namestock','namabarang'],
                            ) ?? '';
                            final lotRaw = _getStringValue(row, const ['Lot_No','LotNo','Lot_Number','Lot']);
                            final lot = (lotRaw == null || lotRaw.trim().isEmpty) ? '-' : lotRaw.trim();
                            final heat = _getStringValue(row, const ['Heat_No','HeatNo','Heat_Number','Heat']) ?? '';
                            final qtyNum = double.tryParse((
                              _getStringValue(row, const ['Qty','Quantity','Qty_Available','Qty_Order','Balance','Unit_Stock','Stock'], partialMatches: const ['qty','quantity','jumlah','balance','stock'])
                              ?? ''
                            ).replaceAll(',', '')) ?? 0.0;

                            final primaryTitle = (name.isNotEmpty ? name : code).isNotEmpty
                                ? (name.isNotEmpty ? name : code)
                                : 'Item ${index + 1}';

                            final infoParts = <String>[];
                            if (code.isNotEmpty) infoParts.add('Code: $code');
                            // Always show Lot label; if missing, show '-'
                            infoParts.add('Lot: $lot');
                            if (heat.isNotEmpty) infoParts.add('Heat: $heat');

                            return ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(primaryTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (infoParts.isNotEmpty)
                                    Text(
                                      infoParts.join(' • '),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock: ${qtyNum.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: qtyNum > 0 ? AppColors.success : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
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

      final selectionRaw = Map<String, dynamic>.from(selected);
      final detail = await _fetchItemDetail(selectionRaw);
      final source = detail ?? selectionRaw;
      _applyItemSelection(source);
      final updated = _mergeDetailItemFromStock(
        current: _detailItems[rowIndex],
        primaryData: source,
        fallbackRaw: selectionRaw,
      );
      
      // Check for duplicates and merge if found
      final duplicateIndex = _findDuplicateItem(updated, excludeIndex: rowIndex);
      if (duplicateIndex != null) {
        // Merge with existing item
        final existingItem = _detailItems[duplicateIndex];
        final mergedItem = existingItem.copyWith(
          qty: existingItem.qty + updated.qty,
        );
        setState(() {
          _detailItems[duplicateIndex] = mergedItem;
          _detailItems.removeAt(rowIndex);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item digabung dengan yang sudah ada. Qty total: ${mergedItem.qty}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // No duplicate, update current row
        _updateDetailItem(rowIndex, updated);
      }
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
                            if (_isVisible('Supply Number'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Supply Number')) const SizedBox(height: 16),
                            if (_isVisible('Supply Date'))
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _isReadOnly('Supply Date') ? null : _selectDate,
                                      child: InputDecorator(
                                        decoration: _inputDecoration(
                                          'Supply Date',
                                          readOnly: _isReadOnly('Supply Date'),
                                        ).copyWith(
                                          suffixIcon: const Icon(Icons.calendar_today, size: 20),
                                        ),
                                        child: Text(
                                          formatLongDate(_supplyDate),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (_isVisible('Supply Date')) const SizedBox(height: 16),
                            if (_isVisible('Supply From'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Supply From')) const SizedBox(height: 16),
                            if (_isVisible('Supply To'))
                              Row(
                                children: [
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
                    key: const PageStorageKey<String>('order_information_tile'),
                    title: const Text(
                      'Order Information',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded: true,
                    maintainState: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_isVisible('Order No.'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Order No.')) const SizedBox(height: 16),
                            if (_isVisible('Project No.'))
                              Row(
                                children: [
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
                            if (_isVisible('Project No.')) const SizedBox(height: 16),
                            // Removed Order ID / Seq ID to follow Edit page
                            const SizedBox(height: 16),
                            if (_isVisible('Item Code'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Item Code')) const SizedBox(height: 16),
                            if (_isVisible('Item Name'))
                              Row(
                                children: [
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
                            if (_isVisible('Item Name')) const SizedBox(height: 16),
                            if (_isVisible('Qty Order'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Qty Order')) const SizedBox(height: 16),
                            if (_isVisible('Heat No'))
                              Row(
                                children: [
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
                            if (_isVisible('Unit'))
                              Row(
                                children: [
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
                                ],
                              ),
                            if (_isVisible('Unit')) const SizedBox(height: 16),
                            if (_isVisible('Size'))
                              Row(
                                children: [
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
                            if (_isVisible('Size')) const SizedBox(height: 16),
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
                      key: const PageStorageKey<String>('signature_information_tile'),
                      title: const Text(
                        'Signature Information',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      initiallyExpanded: true,
                      maintainState: true,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Detail'),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ExpansionTile(
                  title: const Text(
                    'Item',
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

class _WarehousePickerSheet extends StatefulWidget {
  const _WarehousePickerSheet({
    required this.title,
    required this.items,
  });

  final String title;
  final List<Map<String, dynamic>> items;

  @override
  State<_WarehousePickerSheet> createState() => _WarehousePickerSheetState();
}

class _WarehousePickerSheetState extends State<_WarehousePickerSheet> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;
  late List<Map<String, dynamic>> _filtered;
  String? _selectedWarehouseId;
  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchFocusNode = FocusNode();
    _filtered = List.of(widget.items);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applyFilter(String q) {
    final qq = q.trim().toLowerCase();
    setState(() {
      _filtered = qq.isEmpty
          ? List.of(widget.items)
          : widget.items.where((raw) {
              final name = (raw['Org_Name'] ?? '').toString().toLowerCase();
              final code = (raw['Org_Code'] ?? '').toString().toLowerCase();
              return name.contains(qq) || code.contains(qq);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                onChanged: _applyFilter,
                decoration: InputDecoration(
                  hintText: 'Cari gudang by nama atau kode...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = _filtered[index];
                  final name = (m['Org_Name'] ?? '').toString();
                  final code = (m['Org_Code'] ?? '').toString();
                  final id = (m['ID'] ?? '').toString();

                  final selection = Map<String, dynamic>.from(m)
                    ..putIfAbsent('_displayName', () => name)
                    ..putIfAbsent('_displayCode', () => code);

                  final details = <String>[];
                  if (code.isNotEmpty) details.add(code);
                  final isSelected = _selectedWarehouseId == id;

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      child: Icon(Icons.store, color: Color(0xFF7B1FA2)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: details.isEmpty ? null : Text(details.join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : const Icon(Icons.chevron_right, color: Colors.grey),
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryBlue.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedWarehouseId = id;
                        _selectedItem = selection;
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedItem == null
                          ? null
                          : () => Navigator.of(context).pop(_selectedItem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Selection'),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    this.onEdit,
    this.readOnly = false,
  });

  final SupplyDetailItem item;
  final ValueChanged<SupplyDetailItem> onChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onBrowse;
  final VoidCallback? onEdit;
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
      fillColor: AppColors.readOnlyYellow,
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
            readOnly: true,
            decoration: _decoration('Item Code').copyWith(
              suffixIcon: IconButton(
                tooltip: 'Browse Item Stock',
                icon: const Icon(Icons.inventory),
                onPressed: widget.onBrowse,
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
            readOnly: true,
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
            decoration: _decoration('Qty').copyWith(
              fillColor: widget.readOnly ? AppColors.readOnlyYellow : Colors.white,
            ),
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
            readOnly: true,
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
            readOnly: true,
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
            readOnly: true,
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
            decoration: _decoration('Description').copyWith(
              fillColor: widget.readOnly ? AppColors.readOnlyYellow : Colors.white,
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _emitChange(),
          ),
        ),
        const SizedBox(width: 8),
        if (widget.onEdit != null)
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primaryBlue,
              tooltip: 'Edit item',
            ),
          ),
        if (widget.onEdit != null) const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: IconButton(
            onPressed: widget.onDelete,
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
