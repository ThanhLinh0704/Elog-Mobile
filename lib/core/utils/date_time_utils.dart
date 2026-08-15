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

/// Format time (HH:mm), appending a short "dd/MM" date suffix when [raw]
/// isn't today. A trip execution can now legitimately span a day boundary
/// (driver starts on day 1, finishes on day 2), so a bare "HH:mm" on an
/// actual arrival/departure timestamp can silently read as "just now" when
/// it actually happened the day before. Use this instead of [formatTime]
/// for any *actual* (not planned-only-by-time-of-day) timestamp.
String formatTimeSmart(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) return fallback;
  try {
    final dt = DateTime.parse(raw);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return isToday
        ? DateFormat('HH:mm').format(dt)
        : DateFormat('HH:mm dd/MM').format(dt);
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
