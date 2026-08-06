import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/trip_state.dart';

/// Month calendar dialog for picking a delivery date. Days that have at
/// least one trip assigned to the driver show a dot below the day number —
/// red if not all trips that day are COMPLETED yet, green if they all are.
class TripCalendarDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const TripCalendarDialog({super.key, required this.initialDate});

  @override
  ConsumerState<TripCalendarDialog> createState() =>
      _TripCalendarDialogState();
}

class _TripCalendarDialogState extends ConsumerState<TripCalendarDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _monthNames = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  String _monthKey(DateTime m) =>
      '${m.year}-${m.month.toString().padLeft(2, '0')}';

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadMonth() {
    ref.read(tripCalendarProvider.notifier).loadMonth(_monthKey(_visibleMonth));
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    _loadMonth();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(tripCalendarProvider);
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-first grid
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            SizedBox(
              height: 2,
              child: calendarState.isLoading
                  ? const LinearProgressIndicator(minHeight: 2)
                  : null,
            ),
            const SizedBox(height: 6),
            Row(
              children: _weekdayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate(weekCount, (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final cellIndex = week * 7 + weekday;
                  final dayNum = cellIndex - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }
                  final date =
                      DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
                  final dateKey = _dateKey(date);
                  final hasTrip =
                      calendarState.daysWithTrips.containsKey(dateKey);
                  final allCompleted =
                      calendarState.daysWithTrips[dateKey] ?? false;
                  final isSelected = _isSameDay(date, _selected);
                  final isToday = _isSameDay(date, DateTime.now());

                  return Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(date),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? const Color(0xFF1677FF) : null,
                          borderRadius: BorderRadius.circular(20),
                          border: (isToday && !isSelected)
                              ? Border.all(color: const Color(0xFF1677FF))
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: (isToday || isSelected)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 6,
                              width: 6,
                              child: hasTrip
                                  ? DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: allCompleted
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.red, 'Chưa hoàn thành'),
                const SizedBox(width: 16),
                _legendDot(Colors.green, 'Đã hoàn thành'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huỷ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}
