import 'package:intl/intl.dart';

String formatCurrency(double value) => 'Rp ${value.toStringAsFixed(2)}';

String formatShortDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;
  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Yesterday';
  }
  return DateFormat('dd-MMM').format(date);
}

String formatLongDate(DateTime date) => DateFormat('dd-MMM-yyyy').format(date);
