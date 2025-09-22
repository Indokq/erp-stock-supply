import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/models/stock_models.dart';
import '../../shared/widgets/shared_cards.dart';

class StockCard extends StatelessWidget {
  const StockCard({super.key, required this.item, required this.onTap});

  final StockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool lowStock = item.quantity <= item.reorderPoint;
    final bool expiring = item.expiringLots > 0;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text(
                          item.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${item.sku}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.chipGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item.category),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricColumn(
                      label: 'On Hand',
                      value: item.quantity.toString(),
                    ),
                  ),
                  Expanded(
                    child: MetricColumn(
                      label: 'Available',
                      value: item.available.toString(),
                    ),
                  ),
                  Expanded(
                    child: MetricColumn(
                      label: 'Reserved',
                      value: item.reserved.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    item.warehouse,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  if (lowStock)
                    const StatusChip(label: 'Low stock', tone: Colors.redAccent),
                  if (expiring) ...[
                    if (lowStock) const SizedBox(width: 6),
                    StatusChip(label: '${item.expiringLots} expiring', tone: Colors.orangeAccent),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
