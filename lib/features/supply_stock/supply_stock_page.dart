import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../shared/models/stock_models.dart';
import '../shared/services/api_service.dart';
import '../shared/services/auth_service.dart';
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

  String? _extractSeqId(Map<String, dynamic> row) {
    for (final key in const ['Seq_ID', 'SeqId', 'Seq', 'SEQ_ID', 'Seq_ID_Detail']) {
      final value = row[key];
      if (value == null) continue;
      final seq = value.toString().trim();
      if (seq.isNotEmpty) {
        return seq;
      }
    }
    return null;
  }

  Future<void> _confirmDeleteSupply(SupplyStock supply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Supply'),
          content: Text(
            'Supply ${supply.supplyNo} akan dihapus beserta detailnya. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('HAPUS'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    var progressShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final messenger = ScaffoldMessenger.of(context);
    final currentUser = AuthService.currentUser;
    final userEntry = (currentUser != null && currentUser.trim().isNotEmpty)
        ? currentUser.trim()
        : 'admin';

    try {
      final detailSeqIds = <String>[];
      const companyId = 1;
      final detailResult = await ApiService.getSupplyDetail(
        supplyCls: 1,
        supplyId: supply.supplyId,
        userEntry: userEntry,
        companyId: companyId,
      );

      if (detailResult['success'] == true) {
        final data = detailResult['data'];
        if (data is Map<String, dynamic>) {
          final list = data['tbl1'];
          if (list is List) {
            for (final row in list.whereType<Map>()) {
              final seq = _extractSeqId(row.cast<String, dynamic>());
              if (seq != null && seq.isNotEmpty) {
                debugPrint('Deleting detail seq $seq for supply ${supply.supplyId}');
                detailSeqIds.add(seq);
              }
            }
          }
        }
      }

      // Track deletion results
      int deletedCount = 0;
      int alreadyDeletedCount = 0;
      final List<String> errors = [];

      // Delete details - continue even if some fail
      for (final seq in detailSeqIds.toSet()) {
        final deleteDetail = await ApiService.deleteSupply(
          supplyId: supply.supplyId,
          seqId: seq,
        );
        
        if (deleteDetail['success'] == true) {
          if (deleteDetail['alreadyDeleted'] == true) {
            alreadyDeletedCount++;
            debugPrint('Detail seq $seq already deleted');
          } else if (deleteDetail['warning'] == true) {
            deletedCount++;
            debugPrint('Detail seq $seq deleted with warning: ${deleteDetail['message']}');
          } else {
            deletedCount++;
            debugPrint('Detail seq $seq deleted successfully');
          }
        } else {
          final message = deleteDetail['message']?.toString() ?? 'Unknown error';
          errors.add('Detail $seq: $message');
          debugPrint('Failed to delete detail seq $seq: $message');
        }
      }

      // Delete header
      final deleteHeader = await ApiService.deleteSupply(
        supplyId: supply.supplyId,
        seqId: '0',
      );

      bool headerDeleted = false;
      if (deleteHeader['success'] == true) {
        if (deleteHeader['alreadyDeleted'] == true) {
          headerDeleted = true;
          debugPrint('Supply header ${supply.supplyId} was already deleted');
        } else if (deleteHeader['warning'] == true) {
          headerDeleted = true;
          debugPrint('Supply header ${supply.supplyId} deleted with warning: ${deleteHeader['message']}');
        } else {
          headerDeleted = true;
          debugPrint('Supply header ${supply.supplyId} deleted successfully');
        }
      } else {
        final message = deleteHeader['message']?.toString() ?? 'Unknown error';
        errors.add('Header: $message');
      }

      if (progressShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressShown = false;
      }

      // Show appropriate message based on results
      if (headerDeleted && errors.isEmpty) {
        String message = 'Supply ${supply.supplyNo} berhasil dihapus';
        if (alreadyDeletedCount > 0) {
          message += ' ($alreadyDeletedCount item sudah dihapus sebelumnya)';
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (headerDeleted && errors.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Supply dihapus dengan peringatan: ${errors.join(', ')}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus supply: ${errors.join(', ')}',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      _loadSupplyStocks();
    } catch (e) {
      if (progressShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressShown = false;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error menghapus supply: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
            onDelete: () => _confirmDeleteSupply(supply),
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
    this.onDelete,
  });

  final SupplyStock supply;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(
                        label: supply.stsEdit == 1 ? 'Edit' : 'Locked',
                        tone: supply.stsEdit == 1
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: onDelete,
                        ),
                      ],
                    ],
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
