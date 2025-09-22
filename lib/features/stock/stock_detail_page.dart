import 'package:flutter/material.dart';

import '../shared/models/stock_models.dart';
import 'widgets/stock_detail_tabs.dart';

class StockDetailPage extends StatelessWidget {
  const StockDetailPage({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Movements'),
              Tab(text: 'Suppliers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StockOverviewTab(item: item),
            MovementsTab(movements: item.movements),
            SuppliersTab(suppliers: item.suppliers),
          ],
        ),
      ),
    );
  }
}
