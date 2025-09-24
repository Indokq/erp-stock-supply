import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';
import 'supply_detail_page.dart';
import '../shared/widgets/shared_cards.dart';

class EditSupplyPage extends StatefulWidget {
  const EditSupplyPage({
    super.key,
    required this.header,
    required this.initialItems,
    this.columnMetaRows,
  });

  final SupplyHeader header;
  final List<SupplyDetailItem> initialItems;
  final List<Map<String, dynamic>>? columnMetaRows;

  @override
  State<EditSupplyPage> createState() => _EditSupplyPageState();
}

class _EditSupplyPageState extends State<EditSupplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Header controllers
  final _supplyIdController = TextEditingController();
  final _supplyNumberController = TextEditingController();
  final _supplyFromController = TextEditingController();
  final _supplyToController = TextEditingController();
  DateTime _supplyDate = DateTime.now();

  final _refNoController = TextEditingController();
  final _remarksController = TextEditingController();
  final _templateNameController = TextEditingController();

  // Detail state
  final TextEditingController _searchController = TextEditingController();
  List<SupplyDetailItem> _detailItems = [];

  // Column meta (optional)
  final Map<String, _ColumnMeta> _columnMeta = {};

  bool _isVisible(String colName, {bool defaultVisible = true}) {
    final m = _columnMeta[colName];
    if (m == null) return defaultVisible;
    return m.colVisible == 1;
    }

  bool _isReadOnly(String colName, {bool defaultReadOnly = false}) {
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
    setState(() => _detailItems.removeAt(index));
  }

  Future<void> _saveAll() async {
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
        title: const Text('Edit Stock Supply'),
        actions: [
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
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Header'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplyNumberController,
                                    readOnly: _isReadOnly('Supply Number', defaultReadOnly: false),
                                    decoration: _inputDecoration(
                                      'Supply Number',
                                      readOnly: _isReadOnly('Supply Number', defaultReadOnly: false),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _isReadOnly('Supply Date') ? null : _selectDate,
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        'Supply Date',
                                        readOnly: _isReadOnly('Supply Date'),
                                      ),
                                      child: Text(
                                        '${_supplyDate.day.toString().padLeft(2, '0')}-${_supplyDate.month.toString().padLeft(2, '0')}-${_supplyDate.year}',
                                      ),
                                    ),
                                  ),
                                ),
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
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 16),
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
                    ),
                    const SizedBox(height: 20),
                    // Detail card
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SectionHeader(title: 'Detail'),
                                IconButton(
                                  onPressed: _addDetailItem,
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Add Item',
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Item Code', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text('Lot Number', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text('Heat Number', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600))),
                                SizedBox(width: 48),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _detailItems.length,
                            itemBuilder: (context, index) {
                              return DetailItemRow(
                                item: _detailItems[index],
                                onChanged: (updatedItem) {
                                  setState(() {
                                    _detailItems[index] = updatedItem;
                                  });
                                },
                                onDelete: () => _removeDetailItem(index),
                              );
                            },
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

