import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../shared/models/stock_models.dart';
import '../shared/widgets/shared_cards.dart';
import 'stock_detail_page.dart';
import 'widgets/stock_card.dart';

class StockListScreen extends StatelessWidget {
  const StockListScreen({super.key, required this.items});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search SKU, item, or warehouse',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E5ED)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                FilterChipWidget(label: 'All Warehouses', selected: true),
                SizedBox(width: 8),
                FilterChipWidget(label: 'Low Stock'),
                SizedBox(width: 8),
                FilterChipWidget(label: 'Expiring'),
                SizedBox(width: 8),
                FilterChipWidget(label: 'Category'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = Responsive.columnsForWidth(
                  constraints.maxWidth,
                  compact: 1,
                  medium: 2,
                  expanded: 3,
                );
                final aspectRatio = columns == 1
                    ? 1.8
                    : columns == 2
                        ? 1.6
                        : 1.5;
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return StockCard(
                      item: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StockDetailPage(item: item),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      selectedColor: AppColors.primaryBlue.withOpacity(0.12),
      side: const BorderSide(color: Color(0xFFD5DAE3)),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryBlue : Colors.grey[700],
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
