import 'package:intl/intl.dart';

/// Format a nullable DateTime-like string from backend to Vietnamese display
String formatDateTime(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) return fallback;
  try {
    final dt = DateTime.parse(raw);
    return DateFormat('HH:mm dd/MM/yyyy').format(dt);
  } catch (_) {
    return raw;
  }
}

/// Format time only (HH:mm)
String formatTime(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) return fallback;
  try {
    final dt = DateTime.parse(raw);
    return DateFormat('HH:mm').format(dt);
  } catch (_) {
    return raw;
  }
}

/// Format date (dd/MM/yyyy)
String formatDate(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) return fallback;
  try {
    final dt = DateTime.parse(raw);
    return DateFormat('dd/MM/yyyy').format(dt);
  } catch (_) {
    return raw;
  }
}

/// Format delay minutes
String formatDelay(int? delayMinutes) {
  if (delayMinutes == null) return '';
  if (delayMinutes <= 0) return 'Đúng giờ';
  return 'Trễ $delayMinutes phút';
}

/// Today's date as yyyy-MM-dd for API
String todayForApi() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}
