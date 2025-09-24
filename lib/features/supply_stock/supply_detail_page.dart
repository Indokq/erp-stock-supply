import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'models/supply_header.dart';

class SupplyDetailPage extends StatefulWidget {
  final SupplyHeader header;
  final List<SupplyDetailItem> initialItems;
  const SupplyDetailPage({super.key, required this.header, this.initialItems = const []});
  @override
  State<SupplyDetailPage> createState() => _SupplyDetailPageState();
}

class _SupplyDetailPageState extends State<SupplyDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SupplyDetailItem> _detailItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _detailItems = List.of(widget.initialItems);
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
    setState(() {
      _detailItems.removeAt(index);
    });
  }

  Future<void> _saveDetails() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Details saved (stub)'),
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
        title: const Text('Supply Detail'),
        actions: [
          TextButton(
            onPressed: _saveDetails,
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
      body: Column(
        children: [
          _HeaderSummaryCard(header: widget.header),
          Expanded(
            child: Container(
              color: AppColors.surfaceLight,
              child: Column(
                children: [
                  Container(
                    color: AppColors.surfaceCard,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Text(
                          'Detail',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _addDetailItem,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Item',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: AppColors.surfaceCard,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Container(
                    color: AppColors.surfaceCard,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  Expanded(
                    child: ListView.builder(
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
                  ),
                  Container(
                    color: AppColors.surfaceCard,
                    padding: const EdgeInsets.all(20),
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
        ],
      ),
    );
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  final SupplyHeader header;
  const _HeaderSummaryCard({required this.header});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header.supplyNo.isNotEmpty ? header.supplyNo : 'New Supply',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                runSpacing: 8,
                spacing: 16,
                children: [
                  _kv(context, 'Date', '${header.supplyDate.day.toString().padLeft(2, '0')}-${header.supplyDate.month.toString().padLeft(2, '0')}-${header.supplyDate.year}'),
                  _kv(context, 'From', header.fromId.isNotEmpty ? header.fromId : '-'),
                  _kv(context, 'To', header.toId.isNotEmpty ? header.toId : '-'),
                  if (header.orderNo.isNotEmpty) _kv(context, 'Order No', header.orderNo),
                  if (header.projectNo.isNotEmpty) _kv(context, 'Project No', header.projectNo),
                  if (header.remarks.isNotEmpty) _kv(context, 'Remarks', header.remarks),
                  if (header.templateName.isNotEmpty) _kv(context, 'Template', header.templateName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$k: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
          Expanded(
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class SupplyDetailItem {
  String itemCode;
  String itemName;
  double qty;
  String unit;
  String lotNumber;
  String heatNumber;
  String description;

  SupplyDetailItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.lotNumber,
    required this.heatNumber,
    required this.description,
  });
}

class DetailItemRow extends StatelessWidget {
  final SupplyDetailItem item;
  final Function(SupplyDetailItem) onChanged;
  final VoidCallback onDelete;

  const DetailItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.itemCode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: value,
                itemName: item.itemName,
                qty: item.qty,
                unit: item.unit,
                lotNumber: item.lotNumber,
                heatNumber: item.heatNumber,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: item.itemName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: value,
                qty: item.qty,
                unit: item.unit,
                lotNumber: item.lotNumber,
                heatNumber: item.heatNumber,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item.qty.toString(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: double.tryParse(value) ?? 0,
                unit: item.unit,
                lotNumber: item.lotNumber,
                heatNumber: item.heatNumber,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item.unit,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: item.qty,
                unit: value,
                lotNumber: item.lotNumber,
                heatNumber: item.heatNumber,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.lotNumber,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: item.qty,
                unit: item.unit,
                lotNumber: value,
                heatNumber: item.heatNumber,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.heatNumber,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: item.qty,
                unit: item.unit,
                lotNumber: item.lotNumber,
                heatNumber: value,
                description: item.description,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: item.description,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => onChanged(SupplyDetailItem(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: item.qty,
                unit: item.unit,
                lotNumber: item.lotNumber,
                heatNumber: item.heatNumber,
                description: value,
              )),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: AppColors.error),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
