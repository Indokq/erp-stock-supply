import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
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
    _approvedByController.text = header.approvedBy;
    _approvedController.text = header.approved;
    _receivedByController.text = header.receivedBy;
    _receivedController.text = header.received;
    _column1Controller.text = header.column1.toString();
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
          _approvedByController.text = header.approvedBy;
          _approvedController.text = header.approved;
          _receivedByController.text = header.receivedBy;
          _receivedController.text = header.received;
          _column1Controller.text = header.column1.toString();
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

    final detailPayload = _detailItems
        .where((item) =>
            item.itemCode.trim().isNotEmpty ||
            item.itemName.trim().isNotEmpty ||
            item.unit.trim().isNotEmpty ||
            item.lotNumber.trim().isNotEmpty ||
            item.heatNumber.trim().isNotEmpty ||
            item.description.trim().isNotEmpty ||
            item.qty != 0)
        .map(_cloneDetailItem)
        .toList();

    if (detailPayload.isEmpty) {
      _showErrorMessage('Please add at least one detail item.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Optionally call an API to persist header first (if needed).
      // For now we gather header + detail data on the same screen.

      final header = SupplyHeader(
        supplyId: widget.isEdit
            ? int.tryParse(_supplyIdController.text.trim()) ?? 0
            : 0, // replace with returned ID if API call returns it
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
        preparedBy: int.tryParse(_preparedByController.text.trim()) ?? 0,
        prepared: _preparedController.text.trim(),
        approvedBy: _approvedByController.text.trim(),
        approved: _approvedController.text.trim(),
        receivedBy: _receivedByController.text.trim(),
        received: _receivedController.text.trim(),
        column1: int.tryParse(_column1Controller.text.trim()) ?? 0,
      );
      debugPrint('Saving supply with ${detailPayload.length} detail items');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Header & details saved (stub)'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorMessage('Failed to save supply: $e');
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
                                        readOnly: _isReadOnly('Supply From'),
                                        decoration: _inputDecoration(
                                          'Supply From',
                                          readOnly: _isReadOnly('Supply From'),
                                        ),
                                      ),
                                    ),
                                  if (_isVisible('Supply From') && _isVisible('Supply To'))
                                    const SizedBox(width: 16),
                                  if (_isVisible('Supply To'))
                                    Expanded(
                                      child: TextFormField(
                                        controller: _supplyToController,
                                        readOnly: _isReadOnly('Supply To'),
                                        decoration: _inputDecoration(
                                          'Supply To',
                                          readOnly: _isReadOnly('Supply To'),
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
                                        controller: _preparedController,
                                        readOnly: _isReadOnly('Prepared'),
                                        decoration: _inputDecoration(
                                          'Prepared',
                                          readOnly: _isReadOnly('Prepared'),
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
                                        readOnly: _isReadOnly('Approved'),
                                        decoration: _inputDecoration(
                                          'Approved',
                                          readOnly: _isReadOnly('Approved'),
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
                                        readOnly: _isReadOnly('Received'),
                                        decoration: _inputDecoration(
                                          'Received',
                                          readOnly: _isReadOnly('Received'),
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
    this.readOnly = false,
  });

  final SupplyDetailItem item;
  final ValueChanged<SupplyDetailItem> onChanged;
  final VoidCallback? onDelete;
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
      SupplyDetailItem(
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
            decoration: _decoration('Item Code'),
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




