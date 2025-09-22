String formatCurrency(double value) => 'Rp ${value.toStringAsFixed(2)}';

String formatShortDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;
  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Yesterday';
  }
  return '${date.day}/${date.month}';
}

String formatLongDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
