import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QrBottomNav extends StatelessWidget {
  final VoidCallback? onQrPressed;

  const QrBottomNav({
    super.key,
    this.onQrPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: AppColors.borderLight,
          width: 0.2,
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: onQrPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceCard,
              border: Border.all(
                color: AppColors.borderLight,
                width: 0.2,
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner_outlined,
              size: 28,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
