import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/stock_models.dart';
import '../utils/formatters.dart';

/// Infinite scrolling bottom sheet with search functionality for big data
class InfiniteScrollBottomSheet extends StatefulWidget {
  const InfiniteScrollBottomSheet({
    super.key,
    required this.items,
    required this.title,
    this.onItemSelected,
    this.onMultipleItemsSelected,
    this.allowMultiSelect = false,
  });

  final List<StockItem> items;
  final String title;
  final Function(StockItem)? onItemSelected;
  final Function(List<StockItem>)? onMultipleItemsSelected;
  final bool allowMultiSelect;

  @override
  State<InfiniteScrollBottomSheet> createState() => _InfiniteScrollBottomSheetState();

  /// Show the bottom sheet for single selection
  static Future<StockItem?> show(
    BuildContext context, {
    required List<StockItem> items,
    required String title,
  }) {
    return showModalBottomSheet<StockItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InfiniteScrollBottomSheet(
        items: items,
        title: title,
        allowMultiSelect: false,
        onItemSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
  }

  /// Show the bottom sheet for multi-selection
  static Future<List<StockItem>?> showMultiSelect(
    BuildContext context, {
    required List<StockItem> items,
    required String title,
  }) {
    return showModalBottomSheet<List<StockItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InfiniteScrollBottomSheet(
        items: items,
        title: title,
        allowMultiSelect: true,
        onMultipleItemsSelected: (items) => Navigator.of(context).pop(items),
      ),
    );
  }
}

class _InfiniteScrollBottomSheetState extends State<InfiniteScrollBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<StockItem> _filteredItems = [];
  List<StockItem> _displayedItems = [];
  Set<String> _selectedItemSkus = {}; // Track selected items by SKU
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasMore = true;

  static const int _itemsPerPage = 50;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _loadMoreItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _toggleItemSelection(StockItem item) {
    if (!widget.allowMultiSelect) {
      widget.onItemSelected?.call(item);
      return;
    }

    setState(() {
      if (_selectedItemSkus.contains(item.sku)) {
        _selectedItemSkus.remove(item.sku);
      } else {
        _selectedItemSkus.add(item.sku);
      }
    });
  }

  void _selectAllDisplayed() {
    setState(() {
      for (final item in _displayedItems) {
        _selectedItemSkus.add(item.sku);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItemSkus.clear();
    });
  }

  void _onSelectItems() {
    final selectedItems = widget.items
        .where((item) => _selectedItemSkus.contains(item.sku))
        .toList();
    widget.onMultipleItemsSelected?.call(selectedItems);
  }

  List<StockItem> get _selectedItems {
    return widget.items
        .where((item) => _selectedItemSkus.contains(item.sku))
        .toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay for demonstration
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredItems.length);

      if (startIndex >= _filteredItems.length) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      final newItems = _filteredItems.sublist(startIndex, endIndex);

      setState(() {
        _displayedItems.addAll(newItems);
        _currentPage++;
        _isLoading = false;
        _hasMore = endIndex < _filteredItems.length;
      });
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    // Simulate search processing time
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          return item.name.toLowerCase().contains(lowerQuery) ||
                 item.sku.toLowerCase().contains(lowerQuery) ||
                 item.category.toLowerCase().contains(lowerQuery) ||
                 item.warehouse.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      setState(() {
        _displayedItems.clear();
        _currentPage = 0;
        _hasMore = true;
        _isLoading = false;
      });

      _loadMoreItems();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.allowMultiSelect
                            ? Icons.checklist_rounded
                            : Icons.inventory_2_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.allowMultiSelect
                                ? '${_selectedItemSkus.length} selected • ${_filteredItems.length} items available'
                                : '${_filteredItems.length} items available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Multi-select controls
                if (widget.allowMultiSelect && _displayedItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _selectAllDisplayed,
                        icon: const Icon(Icons.select_all_rounded, size: 16),
                        label: const Text('Select All'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedItemSkus.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearSelection,
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, category, or warehouse...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Results Info
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredItems.length} results for "${_searchQuery}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_filteredItems.length != widget.items.length) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Text(
                        'Clear filter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // List
          Expanded(
            child: _displayedItems.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _displayedItems.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _displayedItems.length) {
                        return _buildLoadingIndicator();
                      }

                      final item = _displayedItems[index];
                      return _buildStockItemTile(item);
                    },
                  ),
          ),

          // Select Items Button (for multi-select mode)
          if (widget.allowMultiSelect && _selectedItemSkus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _onSelectItems,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text('Select ${_selectedItemSkus.length} Items'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockItemTile(StockItem item) {
    final isLowStock = item.quantity <= item.reorderPoint;
    final isSelected = _selectedItemSkus.contains(item.sku);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.08) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: widget.allowMultiSelect
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleItemSelection(item),
                activeColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: isLowStock ? AppColors.warning : AppColors.success,
                  size: 20,
                ),
              ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'SKU: ${item.sku}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.chipGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.chipGreyText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warehouse_outlined, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  item.warehouse,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLowStock ? AppColors.warning : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  formatCurrency(item.valuation),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: widget.allowMultiSelect
            ? isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  )
                : const Icon(
                    Icons.circle_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  )
            : const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
        onTap: () => _toggleItemSelection(item),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading more items...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.borderLight.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No stock items available'
                  : 'Try adjusting your search terms',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear search'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}