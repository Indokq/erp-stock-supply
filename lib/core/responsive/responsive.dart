import 'package:flutter/widgets.dart';

class Responsive {
  static const double compactMaxWidth = 600;
  static const double mediumMaxWidth = 1024;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < compactMaxWidth;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= compactMaxWidth && width < mediumMaxWidth;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= mediumMaxWidth;

  static T value<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    required T expanded,
  }) {
    if (isExpanded(context)) {
      return expanded;
    }
    if (isMedium(context)) {
      return medium ?? expanded;
    }
    return compact;
  }

  static int columnsForWidth(
    double width, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
  }) {
    if (width >= mediumMaxWidth) {
      return expanded;
    }
    if (width >= compactMaxWidth) {
      return medium;
    }
    return compact;
  }
}
