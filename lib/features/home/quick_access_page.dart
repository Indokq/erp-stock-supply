import 'package:flutter/material.dart';
import '../shared/models/mock_data.dart';
import '../shared/widgets/shared_cards.dart';
import '../shared/widgets/qr_bottom_nav.dart';
import '../shared/services/auth_service.dart';
import '../../core/theme/app_colors.dart';

class QuickAccessPage extends StatelessWidget {
  const QuickAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'EOS ERP',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
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
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth < 600 ? 2 : 3;
                                final aspectRatio = constraints.maxWidth < 600 ? 0.95 : 1.0;
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: QrBottomNav(
        onQrPressed: () {
          // Handle QR scanner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Scanner pressed')),
          );
        },
      ),
    );
  }
}