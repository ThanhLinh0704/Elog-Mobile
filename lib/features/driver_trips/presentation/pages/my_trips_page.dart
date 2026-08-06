import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers.dart';
import '../state/trip_state.dart';
import '../../data/models/driver_trip_model.dart';
import '../../data/models/trip_model.dart';
import '../widgets/order_result_bottom_sheet.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/trip_calendar_dialog.dart';
import 'trip_map_page.dart';
import 'trip_detail_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../exceptions/presentation/pages/my_exceptions_page.dart';

class MyTripsPage extends ConsumerStatefulWidget {
  const MyTripsPage({super.key});

  @override
  ConsumerState<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends ConsumerState<MyTripsPage> {
  DateTime _selectedDate = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _apiDate {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime dt) {
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    if (_isToday) return '$dateStr (Hôm nay)';
    return dateStr;
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    if (!_isToday) {
      ref.read(myTripsProvider.notifier).loadTrips(date: _apiDate);
    } else {
      ref.read(activeTripProvider.notifier).loadActiveTrip();
      ref.read(myTripsProvider.notifier).loadTrips(date: _apiDate);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => TripCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null && picked != _selectedDate) {
      _onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeTripProvider);
    final activeNotifier = ref.read(activeTripProvider.notifier);
    final myTripsState = ref.watch(myTripsProvider);
    final myTripsNotifier = ref.read(myTripsProvider.notifier);
    final session = ref.watch(authNotifierProvider);

    // Action errors (start/complete/update/return) surface as a SnackBar so the
    // trip card stays visible — a failed action should never blank the screen.
    // A load failure (no trip in state yet) is left in state instead, so it
    // renders as the full-screen retry banner below.
    ref.listen(
      activeTripProvider.select((s) => s.errorMessage),
      (previous, next) {
        if (next == null || !context.mounted) return;
        final hasTripOnScreen = ref.read(activeTripProvider).trip != null;
        if (hasTripOnScreen) {
          showSnackBar(context, next, isError: true);
          activeNotifier.clearError();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến hàng của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              if (_isToday) {
                activeNotifier.loadActiveTrip();
              }
              myTripsNotifier.loadTrips(date: _apiDate);
            },
          ),
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'Ngoại lệ của tôi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyExceptionsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Thông tin cá nhân',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date Navigation Bar ───────────────────────────────────────────
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
                  onPressed: () => _onDateChanged(
                    _selectedDate.subtract(const Duration(days: 1)),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
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
                            _formatDisplayDate(_selectedDate),
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
                  onPressed: () => _onDateChanged(
                    _selectedDate.add(const Duration(days: 1)),
                  ),
                ),
                if (!_isToday)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _onDateChanged(DateTime.now()),
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Hôm nay'),
                  ),
              ],
            ),
          ),

          // ── Main Content Area ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_isToday) {
                  await activeNotifier.loadActiveTrip();
                }
                await myTripsNotifier.loadTrips(date: _apiDate);
              },
              child: _isToday
                  ? _buildTodayContent(context, activeState, activeNotifier,
                      myTripsState, session.username)
                  : _buildHistoricalContent(context, myTripsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayContent(
    BuildContext context,
    ActiveTripState state,
    ActiveTripNotifier notifier,
    MyTripsState myTripsState,
    String? username,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Outcome just completed
    if (state.outcome != null) {
      final o = state.outcome!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.statusCompleted.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 56, color: AppTheme.statusCompleted),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chuyến đã hoàn thành!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.statusCompleted),
              ),
              const SizedBox(height: 8),
              Text('Mã chuyến: ${o.tripCode}',
                  style: const TextStyle(
                      fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'Đã giao: ${o.deliveredCount}/${o.totalOrders} đơn',
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textPrimary),
              ),
              if (o.failedCount > 0)
                Text(
                  'Thất bại: ${o.failedCount} đơn',
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.statusException),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.loadActiveTrip(),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Xem chuyến tiếp theo'),
              ),
            ],
          ),
        ),
      );
    }

    // Active trip exists for today — keep it on screen even if a later action
    // (start/complete/update) fails; that error surfaces via SnackBar instead.
    final trip = state.trip;
    if (trip != null) {
      return _buildActiveTripView(context, trip, state, notifier);
    }

    // No trip loaded at all — this is a genuine load failure, show full-screen retry.
    if (state.errorMessage != null) {
      return ErrorBanner(
        message: state.errorMessage!,
        onRetry: () => notifier.loadActiveTrip(),
      );
    }

    // If activeTrip is null, check if myTrips has any trips for today
    if (myTripsState.trips.isNotEmpty) {
      return _buildTripListView(context, myTripsState.trips);
    }

    // No active trip today
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
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_outlined,
                    size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 18),
              Text(
                'Xin chào ${username ?? 'tài xế'}!',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn chưa có chuyến xe nào được phân công hôm nay.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: OutlinedButton.icon(
                  onPressed: () {
                    notifier.loadActiveTrip();
                    ref
                        .read(myTripsProvider.notifier)
                        .loadTrips(date: _apiDate);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tải lại'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalContent(BuildContext context, MyTripsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.statusException.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 44, color: AppTheme.statusException),
              ),
              const SizedBox(height: 16),
              Text(state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(myTripsProvider.notifier)
                      .loadTrips(date: _apiDate),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.trips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_today_outlined,
                        size: 40, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có chuyến xe nào vào ngày ${_formatDisplayDate(_selectedDate)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildTripListView(context, state.trips);
  }

  Widget _buildTripListView(BuildContext context, List<TripModel> trips) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final t = trips[i];
        final statusColor = _getTripStatusBgColor(t.status);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripDetailPage(tripId: t.tripId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppTheme.tripStatusIcon(t.status),
                        color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.fixedRouteCode ?? 'TRIP-${t.tripId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: t.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(t.vehicle?.plateNumber ?? 'Chưa gán xe',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text('${t.tripStopCount} điểm dừng',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        if (t.plannedDepartureTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_outlined,
                                  size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('Xuất phát: ${t.plannedDepartureTime}',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTripView(
    BuildContext context,
    DriverTripModel trip,
    ActiveTripState state,
    ActiveTripNotifier notifier,
  ) {
    final progress = trip.totalOrders > 0
        ? trip.completedOrdersCount / trip.totalOrders
        : 0.0;
    final canComplete = trip.status == ExecutionStatus.inProgress &&
        trip.pendingOrdersCount == 0;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Trip Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.tripCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: Colors.white),
                      tooltip: 'Bản đồ tuyến đường',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TripMapPage(tripId: trip.tripId),
                          ),
                        );
                      },
                    ),
                    _StatusPill(
                      label: trip.status.label,
                      color: _statusColor(trip.status),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      trip.plateNumber ?? 'Chưa gán xe',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.event_outlined,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      trip.deliveryDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tiến độ giao',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${trip.completedOrdersCount}/${trip.totalOrders} đơn',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons (Start / Complete)
          if (trip.status == ExecutionStatus.assigned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isStarting
                    ? null
                    : () => _startTrip(context, notifier),
                icon: state.isStarting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  state.isStarting ? 'Đang xử lý...' : 'Bắt đầu chuyến',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusInProgress,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

          if (canComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isCompleting
                    ? null
                    : () => _completeTrip(context, notifier),
                icon: state.isCompleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 24),
                label: Text(
                  state.isCompleting ? 'Đang xử lý...' : 'Hoàn thành chuyến',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusCompleted,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

          if (trip.status == ExecutionStatus.completed ||
              trip.status == ExecutionStatus.completedWithExceptions)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: trip.returnedToWarehouseAt != null
                    ? AppTheme.statusCompleted.withOpacity(0.08)
                    : AppTheme.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: trip.returnedToWarehouseAt != null
                      ? AppTheme.statusCompleted.withOpacity(0.35)
                      : AppTheme.warning.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        trip.returnedToWarehouseAt != null
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: trip.returnedToWarehouseAt != null
                            ? AppTheme.statusCompleted
                            : AppTheme.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          trip.returnedToWarehouseAt != null
                              ? 'Đã xác nhận xe về kho lúc ${trip.returnedToWarehouseAt}'
                              : 'Chuyến giao hàng đã hoàn tất. Xe vẫn đang trong trạng thái trở về kho.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: trip.returnedToWarehouseAt != null
                                ? AppTheme.textPrimary
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (trip.returnedToWarehouseAt == null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.isReturningToWarehouse
                            ? null
                            : () => _returnToWarehouse(context, notifier),
                        icon: state.isReturningToWarehouse
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.local_shipping),
                        label: Text(
                          state.isReturningToWarehouse
                              ? 'Đang xử lý...'
                              : 'Xác nhận xe đã về kho',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Tab Bar
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.swap_vert), text: 'Hướng dẫn LIFO'),
              Tab(icon: Icon(Icons.list_alt), text: 'Lịch giao hàng'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildLifoTab(trip),
                _buildScheduleTab(context, trip, state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifoTab(DriverTripModel trip) {
    if (trip.lifoLoadingGuidance.isEmpty) {
      return const Center(child: Text('Không có thông tin xếp hàng LIFO.'));
    }
    final items = [...trip.lifoLoadingGuidance]
      ..sort((a, b) => a.loadingOrder.compareTo(b.loadingOrder));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text('${item.loadingOrder}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text('${item.storeName} (${item.orderRef})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
                'SKU: ${item.sku} - ${item.productName}\nSL: ${item.quantity} | ${item.instruction}'),
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab(
    BuildContext context,
    DriverTripModel trip,
    ActiveTripState state,
    ActiveTripNotifier notifier,
  ) {
    if (trip.stops.isEmpty) {
      return const Center(child: Text('Chưa có điểm dừng nào.'));
    }
    final sortedStops = [...trip.stops]
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedStops.length,
      itemBuilder: (ctx, i) {
        final stop = sortedStops[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text('${stop.sequenceNo}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${stop.storeCode} - ${stop.storeName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    _OutlinePill(
                      label: stop.aggregatedStatus.label,
                      color: _stopStatusColor(stop.aggregatedStatus),
                    ),
                  ],
                ),
                if (stop.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(stop.address,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 20),

                // Orders
                ...stop.orders.map((order) {
                  final isPending =
                      order.deliveryStatus == OrderDeliveryStatus.pending &&
                          trip.status == ExecutionStatus.inProgress;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getOrderBgColor(order.deliveryStatus),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _getOrderBorderColor(order.deliveryStatus)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order.orderRef,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            _OutlinePill(
                              label: order.deliveryStatus.label,
                              color: _getOrderBorderColor(
                                  order.deliveryStatus, solid: true),
                              dense: true,
                            ),
                          ],
                        ),
                        if (order.exceptionReason != null)
                          Text('Lý do: ${order.exceptionReason}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red)),
                        if (isPending) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: state.updatingOrderId == order.orderId
                                  ? null
                                  : () {
                                      OrderResultBottomSheet.show(
                                        context: context,
                                        executionId: trip.executionId,
                                        orderId: order.orderId,
                                        orderRef: order.orderRef,
                                        currentStatus: order.deliveryStatus,
                                        onSubmit: (req) =>
                                            notifier.updateOrderResult(
                                                order.orderId, req),
                                      );
                                    },
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: const Text('Cập nhật kết quả'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Action handlers (confirm dialog + snackbar, consistent with TripDetailPage) ──

  Future<void> _startTrip(
      BuildContext context, ActiveTripNotifier notifier) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Bắt đầu chuyến',
      content: 'Bạn có muốn bắt đầu chuyến này không?',
      confirmLabel: 'Bắt đầu',
      confirmColor: AppTheme.statusInProgress,
    );
    if (!confirmed) return;
    try {
      await notifier.startTrip();
      if (context.mounted) {
        showSnackBar(context, 'Chuyến đã bắt đầu. Chúc bạn giao hàng an toàn!');
      }
    } catch (_) {
      // Error already surfaced via the ref.listen SnackBar in build().
    }
  }

  Future<void> _completeTrip(
      BuildContext context, ActiveTripNotifier notifier) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hoàn thành chuyến',
      content:
          'Xác nhận tất cả đơn hàng đã được xử lý và hoàn thành chuyến này?',
      confirmLabel: 'Hoàn thành',
      confirmColor: AppTheme.statusCompleted,
    );
    if (!confirmed) return;
    try {
      await notifier.completeTrip();
    } catch (_) {
      // Error already surfaced via the ref.listen SnackBar in build().
    }
  }

  Future<void> _returnToWarehouse(
      BuildContext context, ActiveTripNotifier notifier) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xác nhận xe đã về kho',
      content: 'Bạn có chắc chắn xe đã về đến kho?\n\n'
          'Sau khi xác nhận, xe sẽ được chuyển sang trạng thái sẵn sàng để phân cho chuyến mới.',
      confirmLabel: 'Xác nhận',
      confirmColor: Colors.orange[800],
    );
    if (!confirmed) return;
    try {
      await notifier.returnToWarehouse();
      if (context.mounted) {
        showSnackBar(context, 'Đã xác nhận xe về tới kho thành công!');
      }
    } catch (_) {
      // Error already surfaced via the ref.listen SnackBar in build().
    }
  }

  // ── Status color helpers (aligned with AppTheme so trip/stop/order badges
  // read consistently across the whole app) ──────────────────────────────────

  Color _statusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.assigned:
        return AppTheme.statusDispatched;
      case ExecutionStatus.inProgress:
        return AppTheme.statusInProgress;
      case ExecutionStatus.completed:
        return AppTheme.statusCompleted;
      case ExecutionStatus.completedWithExceptions:
        return AppTheme.warning;
    }
  }

  Color _getTripStatusBgColor(String status) => AppTheme.tripStatusColor(status);

  Color _getOrderBgColor(OrderDeliveryStatus status) {
    switch (status) {
      case OrderDeliveryStatus.delivered:
        return AppTheme.statusCompleted.withOpacity(0.08);
      case OrderDeliveryStatus.failed:
        return AppTheme.statusException.withOpacity(0.08);
      case OrderDeliveryStatus.partiallyDelivered:
        return AppTheme.warning.withOpacity(0.1);
      default:
        return AppTheme.surfaceVariant.withOpacity(0.5);
    }
  }

  Color _getOrderBorderColor(OrderDeliveryStatus status, {bool solid = false}) {
    switch (status) {
      case OrderDeliveryStatus.delivered:
        return solid
            ? AppTheme.statusCompleted
            : AppTheme.statusCompleted.withOpacity(0.35);
      case OrderDeliveryStatus.failed:
        return solid
            ? AppTheme.statusException
            : AppTheme.statusException.withOpacity(0.35);
      case OrderDeliveryStatus.partiallyDelivered:
        return solid ? AppTheme.warning : AppTheme.warning.withOpacity(0.4);
      default:
        return solid ? AppTheme.textMuted : AppTheme.surfaceVariant;
    }
  }

  Color _stopStatusColor(StopAggregatedStatus status) {
    switch (status) {
      case StopAggregatedStatus.pending:
        return AppTheme.statusPending;
      case StopAggregatedStatus.delivered:
        return AppTheme.statusCompleted;
      case StopAggregatedStatus.partial:
        return AppTheme.warning;
      case StopAggregatedStatus.failed:
        return AppTheme.statusException;
    }
  }
}

/// Small pill badge used in the active-trip header (dark background, so it
/// needs its own light-on-dark styling instead of [StatusBadge]).
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Light-background, colored-border pill for status labels on light card
/// backgrounds (stop / order status) — mirrors [StatusBadge]'s look.
class _OutlinePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dense;

  const _OutlinePill({
    required this.label,
    required this.color,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
