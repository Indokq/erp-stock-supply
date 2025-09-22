import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../shared/models/mock_data.dart';
import '../shared/models/stock_models.dart';
import '../shared/utils/formatters.dart';
import '../shared/widgets/shared_cards.dart';
import 'widgets/dashboard_cards.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.items,
    required this.warehouses,
    required this.transfers,
  });

  final List<StockItem> items;
  final List<WarehouseCapacity> warehouses;
  final List<StockTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    final lowStock = items.where((item) => item.quantity <= item.reorderPoint).toList();
    final expiringLots = items.fold<int>(0, (prev, item) => prev + item.expiringLots);
    final stockValue = items.fold<double>(0, (prev, item) => prev + item.valuation);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Quick Access',
                          trailing: TextButton(onPressed: () {}, child: const Text('View all')),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = Responsive.columnsForWidth(
                              constraints.maxWidth,
                              compact: 2,
                              medium: 3,
                              expanded: 4,
                            );
                            final aspectRatio = columns >= 4 ? 1.0 : 0.95;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: quickActions.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (_, index) {
                                final action = quickActions[index];
                                return QuickActionTile(
                                  label: action.label,
                                  icon: action.icon,
                                  color: action.color,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Today\'s Snapshot'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = Responsive.columnsForWidth(
                      constraints.maxWidth,
                      compact: 1,
                      medium: 2,
                      expanded: 4,
                    );
                    final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        KpiCard(
                          label: 'Stock Value',
                          value: formatCurrency(stockValue),
                          icon: Icons.pie_chart_rounded,
                          width: itemWidth,
                        ),
                        KpiCard(
                          label: 'Low Stock',
                          value: lowStock.length.toString(),
                          icon: Icons.trending_down_rounded,
                          tone: Colors.redAccent,
                          width: itemWidth,
                        ),
                        KpiCard(
                          label: 'Pending Transfers',
                          value: transfers.length.toString(),
                          icon: Icons.local_shipping_rounded,
                          tone: Colors.deepPurpleAccent,
                          width: itemWidth,
                        ),
                        KpiCard(
                          label: 'Expiring Lots',
                          value: expiringLots.toString(),
                          icon: Icons.schedule_rounded,
                          tone: Colors.orangeAccent,
                          width: itemWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Reorder Soon'),
                const SizedBox(height: 12),
                if (lowStock.isEmpty)
                  const EmptyStateCard(
                    title: 'All stock is healthy',
                    subtitle: 'We\'ll alert you when anything dips below threshold.',
                  )
                else
                  LayoutBuilder(
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
                        children: lowStock
                            .map(
                              (item) => SizedBox(
                                width: itemWidth,
                                child: LowStockCard(item: item),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Warehouse Capacity'),
                const SizedBox(height: 12),
                WarehouseOverview(warehouses: warehouses),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Recent Movements'),
                const SizedBox(height: 12),
                _MovementsSection(items: items),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Transfers In Flight'),
                const SizedBox(height: 12),
                _TransfersList(transfers: transfers),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementsSection extends StatelessWidget {
  const _MovementsSection({required this.items});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    final movements = items.expand((item) => item.movements.map((m) => (item, m))).toList()
      ..sort((a, b) => b.$2.date.compareTo(a.$2.date));

    if (movements.isEmpty) {
      return const EmptyStateCard(
        title: 'No movements yet',
        subtitle: 'New activity will appear here once inventory flows start.',
      );
    }

    final itemsToShow = movements.take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          final columns = Responsive.columnsForWidth(
            constraints.maxWidth,
            compact: 2,
            medium: 3,
            expanded: 4,
          );
          final aspectRatio = columns >= 4 ? 1.9 : 2.2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsToShow.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final (item, movement) = itemsToShow[index];
              return MovementCard(item: item, movement: movement);
            },
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemsToShow.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final (item, movement) = itemsToShow[index];
              return SizedBox(
                width: 240,
                child: MovementCard(item: item, movement: movement),
              );
            },
          ),
        );
      },
    );
  }
}

class _TransfersList extends StatelessWidget {
  const _TransfersList({required this.transfers});

  final List<StockTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const EmptyStateCard(
        title: 'No transfers pending',
        subtitle: 'All internal movements are completed.',
      );
    }

    return Column(
      children: transfers
          .map(
            (transfer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text('${transfer.itemName} · ${transfer.quantity} units'),
                  subtitle: Text('${transfer.source} → ${transfer.destination}'),
                  trailing: StatusChip(label: transfer.status, tone: Colors.blueAccent),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
