import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../state/trip_state.dart';
import '../widgets/shared_widgets.dart';
import '../../data/models/trip_stop_model.dart';
import '../../../delivery_rejection/presentation/rejection_bottom_sheet.dart';
import 'trip_map_page.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripDetailProvider(widget.tripId));
    final notifier = ref.read(tripDetailProvider(widget.tripId).notifier);

    // Show TIME_EXCEPTION warning when arrive response comes back
    ref.listen(
      tripDetailProvider(widget.tripId).select((s) => s.lastArriveResult),
      (_, result) {
        if (result != null && result.timeExceptionFlagged && context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 28),
                  SizedBox(width: 8),
                  Text('Cảnh báo Trễ ETA', style: TextStyle(fontSize: 17)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.delayMinutes != null)
                    Text(
                      'Trễ ${result.delayMinutes} phút so với ETA dự kiến.',
                      style: const TextStyle(fontSize: 15),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    result.message ?? 'TIME_EXCEPTION đã được ghi nhận.',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    notifier.clearArriveResult();
                  },
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.trip?.fixedRouteCode ?? 'Chi tiết chuyến',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Bản đồ tuyến đường',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripMapPage(tripId: widget.tripId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadTrip(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadTrip(),
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TripDetailState state,
      TripDetailNotifier notifier) {
    if (state.isLoading && state.trip == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.trip == null) {
      return ErrorBanner(
        message: state.errorMessage!,
        onRetry: () => notifier.loadTrip(),
      );
    }

    final trip = state.trip;
    if (trip == null) return const SizedBox.shrink();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // ── Error banner (non-blocking) ─────────────────────────────
        if (state.errorMessage != null)
          ErrorBanner(
            message: state.errorMessage!,
            onRetry: () => notifier.loadTrip(),
          ),

        // ── Trip header card ────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.fixedRouteCode ?? 'Trip #${trip.tripId}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                InfoRow(
                  icon: Icons.tag,
                  label: 'Trip ID',
                  value: '${trip.tripId}',
                ),
                InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Ngày giao',
                  value: trip.deliveryDate != null
                      ? _formatDateDisplay(trip.deliveryDate!)
                      : null,
                ),
                if (trip.vehicle != null) ...[
                  InfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Xe',
                    value: trip.vehicle!.vehicleType,
                  ),
                  InfoRow(
                    icon: Icons.credit_card_outlined,
                    label: 'Biển số',
                    value: trip.vehicle!.plateNumber,
                  ),
                ],
                InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Giờ xuất phát dự kiến',
                  value: trip.plannedDepartureTime != null
                      ? _formatTimeDisplay(trip.plannedDepartureTime!)
                      : null,
                ),
                InfoRow(
                  icon: Icons.play_circle_outline,
                  label: 'Giờ bắt đầu thực tế',
                  value: trip.lockedAt != null
                      ? formatDateTime(trip.lockedAt)
                      : null,
                ),
                InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Tổng điểm giao',
                  value: '${trip.tripStopCount ?? trip.tripStops.length} điểm',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Start Trip button ────────────────────────────────────────
        if (trip.status.toUpperCase() == 'DISPATCHED')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: state.isStartingTrip
                  ? null
                  : () => _startTrip(context, notifier),
              icon: state.isStartingTrip
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                state.isStartingTrip ? 'Đang xử lý...' : 'Bắt đầu chuyến',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.statusInProgress,
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // ── Trip COMPLETED banner ────────────────────────────────────
        if (trip.status.toUpperCase() == 'COMPLETED')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.statusCompleted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.statusCompleted.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.statusCompleted, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chuyến đã hoàn thành',
                            style: TextStyle(
                              color: AppTheme.statusCompleted,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            trip.returnedToWarehouseAt != null
                                ? 'Đã xác nhận xe về kho lúc ${formatDateTime(trip.returnedToWarehouseAt)}'
                                : 'Tất cả điểm giao đã được xử lý. Xe vẫn đang trong trạng thái trở về kho.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (trip.returnedToWarehouseAt == null &&
                    trip.executionId != null) ...[
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
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.local_shipping),
                      label: const Text('Xác nhận xe đã về kho',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // ── Stops section ────────────────────────────────────────────
        const Text(
          'Danh sách điểm giao',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Timeline of stops
        ...trip.tripStops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final isLast = index == trip.tripStops.length - 1;
          return _StopTimelineItem(
            stop: stop,
            isLast: isLast,
            tripStatus: trip.status,
            isArriving: state.arrivingStops.contains(stop.tripStopId),
            isCompleting: state.completingStops.contains(stop.tripStopId),
            isRejecting: state.rejectingStops.contains(stop.tripStopId),
            onArrive: () => _arriveAtStop(context, stop, notifier),
            onComplete: () => _completeStop(context, stop, notifier),
            onReject: () => _rejectDelivery(context, stop, notifier),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Action handlers ─────────────────────────────────────────────────────

  Future<void> _startTrip(
      BuildContext context, TripDetailNotifier notifier) async {
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
        showSnackBar(
            context, 'Chuyến đã bắt đầu. Tiến hành đến điểm giao đầu tiên.');
      }
    } on ApiBusinessException catch (e) {
      if (context.mounted) showSnackBar(context, e.userMessage, isError: true);
      if (e.code == 'TRIP_COMPLETED') notifier.loadTrip();
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Không thể bắt đầu chuyến. Thử lại.',
            isError: true);
      }
    }
  }

  Future<void> _returnToWarehouse(
      BuildContext context, TripDetailNotifier notifier) async {
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
    } on ApiBusinessException catch (e) {
      if (context.mounted) showSnackBar(context, e.userMessage, isError: true);
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Không thể xác nhận xe về kho. Thử lại.',
            isError: true);
      }
    }
  }

  Future<void> _arriveAtStop(
    BuildContext context,
    TripStopModel stop,
    TripDetailNotifier notifier,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Báo đã đến điểm giao',
      content:
          'Xác nhận đã đến ${stop.storeCode ?? "điểm giao #${stop.tripStopId}"}?',
      confirmLabel: 'Đã đến',
    );
    if (!confirmed) return;
    try {
      await notifier.arriveAtStop(stop.tripStopId);
      // TIME_EXCEPTION dialog is handled by ref.listen
    } on ApiBusinessException catch (e) {
      if (context.mounted) showSnackBar(context, e.userMessage, isError: true);
      if (e.code == 'STOP_ALREADY_DONE' || e.code == 'TRIP_COMPLETED') {
        notifier.loadTrip();
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Không thể báo đã đến. Thử lại.', isError: true);
      }
    }
  }

  Future<void> _completeStop(
    BuildContext context,
    TripStopModel stop,
    TripDetailNotifier notifier,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hoàn thành điểm giao',
      content:
          'Xác nhận đã hoàn thành giao hàng tại ${stop.storeCode ?? "điểm giao"}?',
      confirmLabel: 'Hoàn thành',
      confirmColor: AppTheme.statusCompleted,
    );
    if (!confirmed) return;
    try {
      final result = await notifier.completeStop(stop.tripStopId);
      if (!context.mounted) return;
      if (result.tripCompleted) {
        showSnackBar(
            context, 'Tất cả điểm giao đã hoàn thành. Chuyến đã kết thúc!');
      } else if (result.nextStop != null) {
        showSnackBar(context,
            'Hoàn thành. Tiếp theo: ${result.nextStop!.storeCode ?? "điểm tiếp theo"}');
      } else {
        showSnackBar(context, 'Điểm giao đã hoàn thành.');
      }
    } on ApiBusinessException catch (e) {
      if (context.mounted) showSnackBar(context, e.userMessage, isError: true);
      if (e.code == 'STOP_ALREADY_DONE' || e.code == 'TRIP_COMPLETED') {
        notifier.loadTrip();
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Không thể hoàn thành điểm giao. Thử lại.',
            isError: true);
      }
    }
  }

  Future<void> _rejectDelivery(
    BuildContext context,
    TripStopModel stop,
    TripDetailNotifier notifier,
  ) async {
    final result = await showRejectionBottomSheet(
      context,
      storeCode: stop.storeCode ?? 'Điểm giao',
      storeName: stop.storeName,
    );
    if (result == null) return; // User cancelled
    try {
      await notifier.rejectDelivery(
        stop.tripStopId,
        result.rejectionType,
        result.description,
      );
      if (!context.mounted) return;
      showSnackBar(context, 'Đã ghi nhận lỗi giao hàng. Hàng giữ lại trên xe.');
    } on ApiBusinessException catch (e) {
      if (context.mounted) showSnackBar(context, e.userMessage, isError: true);
      if (['REJECTION_ALREADY_RECORDED', 'STOP_ALREADY_DONE', 'TRIP_COMPLETED']
          .contains(e.code)) {
        notifier.loadTrip();
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Không thể ghi nhận lỗi. Thử lại.',
            isError: true);
      }
    }
  }

  String _formatDateDisplay(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTimeDisplay(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Stop Timeline Item
// ──────────────────────────────────────────────────────────────────────────

class _StopTimelineItem extends StatelessWidget {
  final TripStopModel stop;
  final bool isLast;
  final String tripStatus;
  final bool isArriving;
  final bool isCompleting;
  final bool isRejecting;
  final VoidCallback onArrive;
  final VoidCallback onComplete;
  final VoidCallback onReject;

  const _StopTimelineItem({
    required this.stop,
    required this.isLast,
    required this.tripStatus,
    required this.isArriving,
    required this.isCompleting,
    required this.isRejecting,
    required this.onArrive,
    required this.onComplete,
    required this.onReject,
  });

  bool get _isActive => stop.status.toUpperCase() == 'IN_PROGRESS';
  bool get _isDone =>
      stop.status.toUpperCase() == 'COMPLETED' ||
      stop.status.toUpperCase() == 'EXCEPTION';
  bool get _isInProgress => tripStatus.toUpperCase() == 'IN_PROGRESS';

  Color get _dotColor => AppTheme.stopStatusColor(stop.status);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline dot + line ──────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    boxShadow: _isActive
                        ? [
                            BoxShadow(
                              color: _dotColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${stop.sequenceOrder ?? ""}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.surfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Stop content card ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStopCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            _isActive ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isActive
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.surfaceVariant,
          width: _isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _isDone ? 0.85 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store name + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.storeCode ?? 'Điểm ${stop.sequenceOrder}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (stop.storeName != null)
                          Text(
                            stop.storeName!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(status: stop.status, isStop: true),
                ],
              ),
              const SizedBox(height: 10),

              // ETA, arrival, departure, delay
              if (stop.plannedEta != null)
                _TimeRow(
                  icon: Icons.schedule_outlined,
                  label: 'ETA',
                  value: formatTimeSmart(stop.plannedEta),
                ),
              if (stop.actualArrivalTime != null)
                _TimeRow(
                  icon: Icons.login_rounded,
                  label: 'Đến lúc',
                  value: formatTimeSmart(stop.actualArrivalTime),
                ),
              if (stop.actualDepartureTime != null)
                _TimeRow(
                  icon: Icons.logout_rounded,
                  label: 'Rời lúc',
                  value: formatTimeSmart(stop.actualDepartureTime),
                ),
              if (stop.delayMinutes != null && stop.delayMinutes! > 0)
                _TimeRow(
                  icon: Icons.timer_off_outlined,
                  label: 'Độ trễ',
                  value: 'Trễ ${stop.delayMinutes} phút',
                  color: stop.delayMinutes! > 0 ? AppTheme.warning : null,
                ),

              // EXCEPTION indicator
              if (stop.status.toUpperCase() == 'EXCEPTION') ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusException.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.statusException, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Có ngoại lệ giao hàng',
                        style: TextStyle(
                          color: AppTheme.statusException,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Action buttons ─────────────────────────────────────
              if (_isInProgress) ...[
                const SizedBox(height: 12),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final statusUp = stop.status.toUpperCase();
    final anyBusy = isArriving || isCompleting || isRejecting;

    if (statusUp == 'PENDING') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (anyBusy) ? null : onArrive,
          icon: isArriving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.place_rounded, size: 20),
          label: Text(isArriving ? 'Đang xử lý...' : 'Đã đến điểm giao'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppTheme.primaryLight,
          ),
        ),
      );
    }

    if (statusUp == 'IN_PROGRESS') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: anyBusy ? null : onComplete,
            icon: isCompleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, size: 20),
            label:
                Text(isCompleting ? 'Đang xử lý...' : 'Hoàn thành điểm giao'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppTheme.statusCompleted,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: anyBusy ? null : onReject,
            icon: isRejecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cancel_outlined, size: 20),
            label: Text(isRejecting ? 'Đang xử lý...' : 'Báo lỗi giao hàng'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppTheme.statusException,
              side:
                  const BorderSide(color: AppTheme.statusException, width: 1.5),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
