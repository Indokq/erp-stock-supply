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

    setState(() => _isLoading = true);
    try {
      // Optionally call an API to persist header first (if needed).
      // For now we proceed to detail page, carrying header data object.

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
                            // Supply ID (read-only)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplyIdController,
                                    readOnly: true,
                                    decoration: _inputDecoration(
                                      'Supply ID',
                                      readOnly: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                        readOnly: _isReadOnly('Prepared By'),
                                        decoration: _inputDecoration(
                                          'Prepared By',
                                          readOnly: _isReadOnly('Prepared By'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
                              if (_isVisible('Prepared By')) const SizedBox(height: 16),
                              if (_isVisible('Approved By'))
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _approvedByController,
                                        readOnly: _isReadOnly('Approved By'),
                                        decoration: _inputDecoration(
                                          'Approved By',
                                          readOnly: _isReadOnly('Approved By'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
                              if (_isVisible('Approved By')) const SizedBox(height: 16),
                              if (_isVisible('Received By'))
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _receivedByController,
                                        readOnly: _isReadOnly('Received By'),
                                        decoration: _inputDecoration(
                                          'Received By',
                                          readOnly: _isReadOnly('Received By'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
