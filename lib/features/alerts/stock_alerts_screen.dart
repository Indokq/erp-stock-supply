import 'package:flutter/material.dart';

import '../shared/models/stock_models.dart';
import '../shared/widgets/shared_cards.dart';

class StockAlertsScreen extends StatelessWidget {
  const StockAlertsScreen({super.key, required this.items});

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    final lowStock = items.where((item) => item.quantity <= item.reorderPoint).toList();
    final expiring = items.where((item) => item.expiringLots > 0).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const SectionHeader(title: 'Low Stock Alerts'),
        const SizedBox(height: 12),
        if (lowStock.isEmpty)
          const EmptyStateCard(
            title: 'No low stock items',
            subtitle: 'Great job keeping inventory healthy.',
          )
        else
          ...lowStock.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AlertCard(
                title: item.name,
                subtitle: 'On hand ${item.quantity}, reorder at ${item.reorderPoint}',
                tone: Colors.redAccent,
              ),
            ),
          ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Expiring Lots'),
        const SizedBox(height: 12),
        if (expiring.isEmpty)
          const EmptyStateCard(
            title: 'No expiring lots',
            subtitle: 'You\'re all set for now.',
          )
        else
          ...expiring.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AlertCard(
                title: item.name,
                subtitle: '${item.expiringLots} lots expiring within 14 days',
                tone: Colors.orangeAccent,
              ),
            ),
          ),
      ],
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.title, required this.subtitle, required this.tone});

  final String title;
  final String subtitle;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tone.withOpacity(0.12),
          foregroundColor: tone,
          child: const Icon(Icons.notifications_active_rounded),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: () {},
          child: const Text('Review'),
        ),
      ),
    );
  }
}
