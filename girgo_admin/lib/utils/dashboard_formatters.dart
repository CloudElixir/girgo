import 'package:intl/intl.dart';

/// SaaS-style counts: small values plain, 1.2K+ compact.
String formatDashboardInteger(int value) {
  if (value < 0) return '0';
  if (value < 1000) {
    return NumberFormat('#,###', 'en_US').format(value);
  }
  return NumberFormat.compact(locale: 'en_US').format(value);
}
