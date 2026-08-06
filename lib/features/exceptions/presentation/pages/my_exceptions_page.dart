import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../driver_trips/presentation/widgets/shared_widgets.dart';
import '../../data/models/exception_item_model.dart';
import '../state/exception_state.dart';

class MyExceptionsPage extends ConsumerStatefulWidget {
  const MyExceptionsPage({super.key});

  @override
  ConsumerState<MyExceptionsPage> createState() => _MyExceptionsPageState();
}

class _MyExceptionsPageState extends ConsumerState<MyExceptionsPage> {
  bool _isToday(String apiDate) {
    return apiDate == todayForApi();
  }

  DateTime _parseApiDate(String apiDate) {
    final parts = apiDate.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  String _toApiDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(String apiDate) {
    final dt = _parseApiDate(apiDate);
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    if (_isToday(apiDate)) return '$dateStr (Hôm nay)';
    return dateStr;
  }

  Future<void> _pickDate(BuildContext context, String currentApiDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseApiDate(currentApiDate),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(exceptionsProvider.notifier).changeDate(_toApiDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exceptionsProvider);
    final notifier = ref.read(exceptionsProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ngoại lệ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: notifier.load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date navigation bar (đồng bộ với MyTripsPage) ─────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Ngày trước',
                  onPressed: () => notifier.changeDate(_toApiDate(
                      _parseApiDate(state.date).subtract(const Duration(days: 1)))),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context, state.date),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _formatDisplayDate(state.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              size: 20, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Ngày sau',
                  onPressed: () => notifier.changeDate(_toApiDate(
                      _parseApiDate(state.date).add(const Duration(days: 1)))),
                ),
                if (!_isToday(state.date))
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => notifier.changeDate(todayForApi()),
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Hôm nay'),
                  ),
              ],
            ),
          ),

          // ── Filters: loại ngoại lệ + trạng thái xử lý ─────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterDropdown(
                  label: 'Loại ngoại lệ',
                  options: const {
                    'ALL': 'Tất cả loại',
                    'TIME_EXCEPTION': 'Trễ ETA',
                    'DELIVERY_REJECTION': 'Giao thất bại',
                  },
                  value: state.typeFilter,
                  onChanged: notifier.changeTypeFilter,
                ),
                const SizedBox(height: 10),
                _FilterDropdown(
                  label: 'Trạng thái xử lý',
                  options: const {
                    'all': 'Tất cả trạng thái',
                    'false': 'Chưa xử lý',
                    'true': 'Đã xử lý',
                  },
                  value: state.resolvedFilter,
                  onChanged: notifier.changeResolvedFilter,
                ),
              ],
            ),
          ),

          // ── Summary ────────────────────────────────────────────────────────
          if (!state.isLoading && state.errorMessage == null)
            Container(
              width: double.infinity,
              color: AppTheme.surfaceVariant.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${state.totalCount} ngoại lệ · ${state.unresolvedCount} chưa xử lý',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.load,
              child: _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExceptionsState state) {
    if (state.isLoading && state.exceptions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorBanner(
            message: state.errorMessage!,
            onRetry: () => ref.read(exceptionsProvider.notifier).load(),
          ),
        ],
      );
    }

    if (state.exceptions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.statusCompleted.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 48, color: AppTheme.statusCompleted),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có ngoại lệ nào khớp bộ lọc này.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.exceptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _ExceptionCard(item: state.exceptions[i]),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      items: options.entries
          .map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ExceptionCard extends StatelessWidget {
  final ExceptionItemModel item;

  const _ExceptionCard({required this.item});

  Color get _typeColor {
    switch (item.exceptionType) {
      case ExceptionType.timeException:
        return AppTheme.warning;
      case ExceptionType.deliveryRejection:
        return AppTheme.statusException;
      case ExceptionType.unknown:
        return AppTheme.textMuted;
    }
  }

  IconData get _typeIcon {
    switch (item.exceptionType) {
      case ExceptionType.timeException:
        return Icons.timer_off_outlined;
      case ExceptionType.deliveryRejection:
        return Icons.report_problem_outlined;
      case ExceptionType.unknown:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type + resolved status
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_typeIcon, size: 16, color: _typeColor),
                ),
                const SizedBox(width: 8),
                Text(
                  item.exceptionType.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _typeColor,
                  ),
                ),
                const Spacer(),
                _StatusPill(resolved: item.isResolved),
              ],
            ),
            const SizedBox(height: 8),

            // Store / route
            if (item.storeName != null || item.fixedRouteCode != null)
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        if (item.storeName != null) item.storeName!,
                        if (item.fixedRouteCode != null) item.fixedRouteCode!,
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

            // Timing detail for TIME_EXCEPTION
            if (item.exceptionType == ExceptionType.timeException) ...[
              const SizedBox(height: 6),
              Text(
                'ETA dự kiến: ${formatTime(item.plannedEta)} · Đến thực tế: ${formatTime(item.actualArrivalTime)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (item.delayMinutes != null)
                Text(
                  formatDelay(item.delayMinutes),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
            ],

            // Description for DELIVERY_REJECTION
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Ghi nhận lúc ${formatDateTime(item.createdAt)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),

            // Resolution box
            if (item.isResolved) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.statusCompleted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.statusCompleted.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: AppTheme.statusCompleted),
                        const SizedBox(width: 6),
                        Text(
                          'Đã xử lý lúc ${formatDateTime(item.resolvedAt)}'
                          '${item.resolvedBy != null ? ' bởi ${item.resolvedBy}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.statusCompleted,
                          ),
                        ),
                      ],
                    ),
                    if (item.resolutionNotes != null &&
                        item.resolutionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.resolutionNotes!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool resolved;

  const _StatusPill({required this.resolved});

  @override
  Widget build(BuildContext context) {
    final color = resolved ? AppTheme.statusCompleted : AppTheme.statusException;
    final label = resolved ? 'Đã xử lý' : 'Chưa xử lý';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
