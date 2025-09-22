import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum MovementType { inbound, outbound, transfer }

extension MovementTypeX on MovementType {
  String get label => switch (this) {
        MovementType.inbound => 'Inbound',
        MovementType.outbound => 'Outbound',
        MovementType.transfer => 'Transfer',
      };

  IconData get icon => switch (this) {
        MovementType.inbound => Icons.call_received_rounded,
        MovementType.outbound => Icons.call_made_rounded,
        MovementType.transfer => Icons.sync_alt_rounded,
      };

  Color get color => switch (this) {
        MovementType.inbound => Colors.green,
        MovementType.outbound => Colors.redAccent,
        MovementType.transfer => AppColors.primaryBlue,
      };
}
