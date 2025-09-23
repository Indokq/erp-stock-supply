import 'package:flutter/material.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class CreateSupplyPage extends StatefulWidget {
  const CreateSupplyPage({super.key});

  @override
  State<CreateSupplyPage> createState() => _CreateSupplyPageState();
}

class _CreateSupplyPageState extends State<CreateSupplyPage> {
  final _formKey = GlobalKey<FormState>();

  // Header - General Information
  final _supplyNumberController = TextEditingController();
  final _supplyFromController = TextEditingController();
  final _supplyToController = TextEditingController();
  DateTime _supplyDate = DateTime.now();

  // Order Information
  final _orderNoController = TextEditingController();
  final _projectNoController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyOrderController = TextEditingController();
  final _heatNoController = TextEditingController();

  // Detail Items
  List<SupplyDetailItem> _detailItems = [];
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _useTemplate = false;

  @override
  void initState() {
    super.initState();
    _initializeNewSupply();
  }

  @override
  void dispose() {
    _supplyNumberController.dispose();
    _supplyFromController.dispose();
    _supplyToController.dispose();
    _orderNoController.dispose();
    _projectNoController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _qtyOrderController.dispose();
    _heatNoController.dispose();
    _searchController.dispose();
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

      if (result['success']) {
        // Process the response data to populate the form
        final data = result['data'];
        // You can use this data to populate default values or get available options
      } else {
        _showErrorMessage(result['message']);
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

  Future<void> _saveSupply() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Here you would implement the save API call
        // For now, we'll show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supply stock created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        _showErrorMessage('Failed to save supply: $e');
      } finally {
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
        appBar: AppBar(title: const Text('Create New Supply')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Stock Supply'),
        actions: [
          TextButton(
            onPressed: _saveSupply,
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplyNumberController,
                                    decoration: const InputDecoration(
                                      labelText: 'Supply Number',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Supply Date',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                                      ),
                                      child: Text(
                                        '${_supplyDate.day.toString().padLeft(2, '0')}-${_supplyDate.month.toString().padLeft(2, '0')}-${_supplyDate.year}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplyFromController,
                                    decoration: const InputDecoration(
                                      labelText: 'Supply From',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplyToController,
                                    decoration: const InputDecoration(
                                      labelText: 'Supply To',
                                      border: OutlineInputBorder(),
                                      isDense: true,
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _orderNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Order No.',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _projectNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Project No.',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _itemCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Item Code',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _itemNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Item Name',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _qtyOrderController,
                                    decoration: const InputDecoration(
                                      labelText: 'Qty Order',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heatNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Heat No',
                                      border: OutlineInputBorder(),
                                      isDense: true,
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

            // Detail Section
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
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

                    // Search Bar
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

                    // Detail Items Table Header
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

                    // Detail Items List
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

                    // Summary Section
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