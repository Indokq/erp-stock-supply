import 'package:flutter/material.dart';
import '../shared/models/stock_models.dart';
import '../shared/services/api_service.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/utils/formatters.dart';
import 'create_supply_page.dart';
import 'supply_detail_page.dart';
import 'models/supply_header.dart';
import 'edit_supply_page.dart';
import '../../core/theme/app_colors.dart';

class SupplyStockPage extends StatefulWidget {
  const SupplyStockPage({super.key});

  @override
  State<SupplyStockPage> createState() => _SupplyStockPageState();
}

class _SupplyStockPageState extends State<SupplyStockPage> {
  List<SupplyStock> _supplyStocks = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Date filter state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _showDateFilter = false;

  @override
  void initState() {
    super.initState();
    _loadSupplyStocks();
  }

  Future<void> _loadSupplyStocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getSupplyStock(
        dateStart: _startDate,
        dateEnd: _endDate,
      );

      if (result['success']) {
        final data = result['data'];
        final tbl1 = data['tbl1'] as List?;

        if (tbl1 != null) {
          setState(() {
            _supplyStocks = tbl1.map((json) => SupplyStock.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load supply stocks: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToCreateSupply() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSupplyPage()),
    ).then((_) {
      // Refresh the list when returning from create page
      _loadSupplyStocks();
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _loadSupplyStocks();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _loadSupplyStocks();
    }
  }

  void _toggleDateFilter() {
    setState(() {
      _showDateFilter = !_showDateFilter;
    });
  }

  void _resetDateFilter() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
    _loadSupplyStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Stock Supply'),
        actions: [
          IconButton(
            icon: Icon(_showDateFilter ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: _toggleDateFilter,
            tooltip: 'Date Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupplyStocks,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Filter Section
            if (_showDateFilter)
              Container(
                color: AppColors.surfaceCard,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Date Filter',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _resetDateFilter,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 20),
                              ),
                              child: Text(
                                formatLongDate(_startDate),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 20),
                              ),
                              child: Text(
                                formatLongDate(_endDate),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Showing data from ${formatLongDate(_startDate)} to ${formatLongDate(_endDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SectionHeader(title: 'Stock Supply List'),
                                ElevatedButton.icon(
                                  onPressed: _navigateToCreateSupply,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Create New'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: ${_supplyStocks.length} supply records',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
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
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSupplyStocks,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_supplyStocks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyStateCard(
            title: 'No Supply Stock Found',
            subtitle: 'Create your first supply record to get started',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _supplyStocks.length,
      itemBuilder: (context, index) {
        final supply = _supplyStocks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SupplyStockCard(
            supply: supply,
            onTap: () {
              _openSupplyForEdit(supply);
            },
          ),
        );
      },
    );
  }

  Future<void> _openSupplyForEdit(SupplyStock supply) async {
    // Fetch header and detail via API using provided apidata formats
    try {
      String _formatDdMmmYyyy(DateTime d) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final dd = d.day.toString().padLeft(2, '0');
        final mmm = months[d.month - 1];
        final yyyy = d.year.toString();
        return '$dd-$mmm-$yyyy';
      }

      final headerRes = await ApiService.getSupplyHeader(
        supplyCls: 1,
        supplyId: supply.supplyId,
        userEntry: 'admin',
        companyId: 1,
        // Pass date string per backend format e.g., 04-Mar-2025
        supplyDateStr: _formatDdMmmYyyy(supply.supplyDate),
      );

      final detailRes = await ApiService.getSupplyDetail(
        supplyCls: 1,
        supplyId: supply.supplyId,
        userEntry: 'admin',
        companyId: 1,
      );

      if (headerRes['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(headerRes['message'] ?? 'Failed to fetch header')),
        );
        return;
      }
      if (detailRes['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detailRes['message'] ?? 'Failed to fetch detail')),
        );
        return;
      }

      final headerData = headerRes['data'];
      final headerTbl1 = headerData['tbl1'] as List?;
      final headerJson = (headerTbl1 != null && headerTbl1.isNotEmpty)
          ? (headerTbl1.first as Map).cast<String, dynamic>()
          : <String, dynamic>{};

      final detailData = detailRes['data'];
      final detailTbl1 = detailData['tbl1'] as List?;

      final header = SupplyHeader.fromJson(headerJson);

      // Map detail rows into editable items; be tolerant of missing fields
      final List<SupplyDetailItem> items = (detailTbl1 ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map((m) => SupplyDetailItem(
                itemCode: (m['Item_Code'] ?? m['ItemCode'] ?? '').toString(),
                itemName: (m['Item_Name'] ?? m['ItemName'] ?? '').toString(),
                qty: () {
                  final v = m['Qty'] ?? m['Quantity'];
                  final s = v?.toString() ?? '';
                  return double.tryParse(s) ?? 0;
                }(),
                unit: (m['OrderUnit'] ?? m['Unit'] ?? '').toString(),
                lotNumber: (m['Lot_Number'] ?? m['LotNo'] ?? '').toString(),
                heatNumber: (m['Heat_Number'] ?? m['HeatNo'] ?? '').toString(),
                description: (m['Description'] ?? m['Desc'] ?? '').toString(),
              ))
          .toList();

      if (!mounted) return;
      // If header is editable, open full header-edit page first; otherwise go straight to detail view
      if (supply.stsEdit == 1) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditSupplyPage(
              header: header,
              initialItems: items,
              columnMetaRows: (headerData['tbl0'] as List?)
                  ?.whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList(),
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupplyDetailPage(
              header: header,
              initialItems: items,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open supply: $e')),
      );
    }
  }
}

class SupplyStockCard extends StatelessWidget {
  const SupplyStockCard({
    super.key,
    required this.supply,
    required this.onTap,
  });

  final SupplyStock supply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supply.supplyNo,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatLongDate(supply.supplyDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: supply.stsEdit == 1 ? 'Editable' : 'Locked',
                    tone: supply.stsEdit == 1 ? AppColors.success : AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      context,
                      icon: Icons.warehouse_outlined,
                      label: 'From',
                      value: supply.fromId,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoRow(
                      context,
                      icon: Icons.location_on_outlined,
                      label: 'To',
                      value: supply.toId,
                    ),
                  ),
                ],
              ),
              if (supply.remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.notes_outlined,
                  label: 'Remarks',
                  value: supply.remarks,
                ),
              ],
              if (supply.templateName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Template',
                  value: supply.templateName,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.isNotEmpty ? value : '-',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
