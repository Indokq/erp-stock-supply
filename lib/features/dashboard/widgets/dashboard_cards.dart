import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/models/movement_type.dart';
import '../../shared/models/stock_models.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/shared_cards.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tone;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Color color = tone ?? AppColors.primaryBlue;
    return SizedBox(
      width: width ?? 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (tone != null)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LowStockCard extends StatelessWidget {
  const LowStockCard({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final double ratio = item.quantity / (item.reorderPoint == 0 ? 1 : item.reorderPoint);
    final Color tone = ratio < 0.7 ? Colors.redAccent : Colors.orangeAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                StatusChip(
                  label: 'Reorder at ${item.reorderPoint}',
                  tone: tone,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${item.sku}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricChip(
                  label: 'On hand',
                  value: item.quantity.toString(),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Available',
                  value: item.available.toString(),
                  color: AppColors.success,
                ),
                const Spacer(),
                Text(
                  '${item.leadTimeDays}d lead',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WarehouseOverview extends StatelessWidget {
  const WarehouseOverview({super.key, required this.warehouses});

  final List<WarehouseCapacity> warehouses;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = Responsive.columnsForWidth(
              constraints.maxWidth,
              compact: 1,
              medium: 2,
              expanded: 3,
            );
            final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: warehouses
                  .map(
                    (warehouse) => SizedBox(
                      width: itemWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryBlue.withOpacity(0.12),
                                  ),
                                  child: const Icon(Icons.warehouse_rounded, color: AppColors.primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    warehouse.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            LinearProgressIndicator(
                              value: warehouse.capacityUsed,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 8),
                            Text('Capacity used: ${(warehouse.capacityUsed * 100).round()}%'),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class MovementCard extends StatelessWidget {
  const MovementCard({super.key, required this.item, required this.movement});

  final StockItem item;
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(movement.type.icon, color: movement.type.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    movement.type.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(formatShortDate(movement.date)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              movement.reference,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const Spacer(),
            Text(
              'Qty ${movement.quantity}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: movement.type.color),
            ),
          ],
        ),
      ),
    );
  }
}
