import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'create_supply_page.dart' as create_supply;
import 'models/supply_detail_item.dart';
import '../shared/widgets/shared_cards.dart';

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
    _supplyFromController.text = header.fromId;
    _supplyToController.text = header.toId;
    _refNoController.text = header.refNo;
    _remarksController.text = header.remarks;
    _templateNameController.text = header.templateName;
    setState(() {});
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
                                      if (_isVisible('Unit') || _isVisible('Size')) const SizedBox(height: 16),
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
                                            if (_isVisible('Unit') && _isVisible('Size'))
                                              const SizedBox(width: 16),
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
