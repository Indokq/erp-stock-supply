import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/models/movement_type.dart';
import '../../shared/models/stock_models.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/shared_cards.dart';

class StockOverviewTab extends StatelessWidget {
  const StockOverviewTab({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantities',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: MetricColumn(label: 'On hand', value: item.quantity.toString())),
                    Expanded(child: MetricColumn(label: 'Available', value: item.available.toString())),
                    Expanded(child: MetricColumn(label: 'Reserved', value: item.reserved.toString())),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Reorder point: ${item.reorderPoint} units'),
                const SizedBox(height: 6),
                Text('Lead time: ${item.leadTimeDays} days'),
                const SizedBox(height: 6),
                Text('Valuation: ${formatCurrency(item.valuation)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehousing',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Text(item.warehouse),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${item.expiringLots} lots expiring soon'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MovementsTab extends StatelessWidget {
  const MovementsTab({super.key, required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const Center(child: Text('No movements recorded yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: movements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final movement = movements[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: movement.type.color.withOpacity(0.15),
              foregroundColor: movement.type.color,
              child: Icon(movement.type.icon),
            ),
            title: Text(movement.reference),
            subtitle: Text(formatLongDate(movement.date)),
            trailing: Text('Qty ${movement.quantity}'),
          ),
        );
      },
    );
  }
}

class SuppliersTab extends StatelessWidget {
  const SuppliersTab({super.key, required this.suppliers});

  final List<String> suppliers;

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) {
      return const Center(child: Text('No suppliers linked.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
              foregroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.store_mall_directory_rounded),
            ),
            title: Text(supplier),
            subtitle: const Text('Preferred vendor'),
            trailing: TextButton(
              onPressed: () {},
              child: const Text('View contracts'),
            ),
          ),
        );
      },
    );
  }
}
