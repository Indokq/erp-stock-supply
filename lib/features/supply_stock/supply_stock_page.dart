import 'package:flutter/material.dart';
import '../shared/models/stock_models.dart';
import '../shared/services/api_service.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/utils/formatters.dart';
import 'create_supply_page.dart';
import 'edit_supply_page.dart';
import 'models/supply_header.dart';
import 'models/supply_detail_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';

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
            _supplyStocks =
                tbl1.map((json) => SupplyStock.fromJson(json)).toList();
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

  Widget _buildCreateButton({bool fillWidth = false}) {
    final button = ElevatedButton.icon(
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
    );

    if (fillWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }

  Widget _buildDateFilterFields(bool isCompact) {
    Widget buildField({
      required String label,
      required DateTime value,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
          ),
          child: Text(
            formatLongDate(value),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final startField = buildField(
      label: 'Start Date',
      value: _startDate,
      onTap: _selectStartDate,
    );
    final endField = buildField(
      label: 'End Date',
      value: _endDate,
      onTap: _selectEndDate,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          startField,
          const SizedBox(height: 12),
          endField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: startField),
        const SizedBox(width: 16),
        Expanded(child: endField),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = Responsive.isCompact(context);
    final horizontalPadding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Stock Supply'),
        actions: [
          IconButton(
            icon: Icon(
              _showDateFilter ? Icons.filter_list : Icons.filter_list_outlined,
            ),
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
            if (_showDateFilter)
              Container(
                color: AppColors.surfaceCard,
                padding: EdgeInsets.all(isCompact ? 16 : 20),
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
                    _buildDateFilterFields(isCompact),
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
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 16 : 20,
                horizontalPadding,
                isCompact ? 12 : 20,
              ),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 16 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(title: 'Stock Supply List'),
                                const SizedBox(height: 8),
                                Text(
                                  'Total: ${_supplyStocks.length} supply records',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCompact) _buildCreateButton(),
                        ],
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 12),
                        _buildCreateButton(fillWidth: true),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildContent(horizontalPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double horizontalPadding) {
    final isCompact = Responsive.isCompact(context);

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
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isCompact ? 12 : 20,
        horizontalPadding,
        isCompact ? 24 : 32,
      ),
      itemCount: _supplyStocks.length,
      itemBuilder: (context, index) {
        final supply = _supplyStocks[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
          child: SupplyStockCard(
            supply: supply,
            onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // Get the full supply header and detail data from API
                final result = await ApiService.getSupplyHeader(
                  supplyCls: 1, // Assuming supply class 1
                  supplyId: supply.supplyId,
                  userEntry: 'admin', // Using default user
                  companyId: 1, // Default company
                );

                if (result['success'] == true) {
                  final data = result['data'];
                  Navigator.of(context).pop(); // Close loading indicator

                  // Get the header row from the response
                  final List? tbl1 = data['tbl1'] as List?;
                  final Map<String, dynamic>? headerJson = (tbl1 != null && tbl1.isNotEmpty)
                      ? (tbl1.first as Map).cast<String, dynamic>()
                      : null;

                  if (headerJson != null) {
                    // We'll pass an empty list since SupplyDetailItem doesn't have fromJson
                  final List<SupplyDetailItem> detailItems = [];

                    // Navigate to the edit supply page with full data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSupplyPage(
                          header: SupplyHeader.fromJson(headerJson),
                          initialItems: detailItems,
                          // Add any additional parameters as needed
                        ),
                      ),
                    ).then((_) {
                      // Refresh the list when returning from edit page
                      _loadSupplyStocks();
                    });
                  } else {
                    Navigator.of(context).pop(); // Close loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to load supply data'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.of(context).pop(); // Close loading indicator
                  final message = result['message'] ?? 'Failed to load supply data';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop(); // Close loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading supply: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
    );
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
    final isCompact = Responsive.isCompact(context);
    final isMedium = Responsive.isMedium(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    tone:
                        supply.stsEdit == 1 ? AppColors.success : AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.warehouse_outlined,
                      label: 'From',
                      value: supply.fromId,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_outlined,
                      label: 'To',
                      value: supply.toId,
                    ),
                  ],
                )
              else
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
                    SizedBox(width: isMedium ? 12 : 16),
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

  Widget _buildInfoRow(
    BuildContext context, {
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
