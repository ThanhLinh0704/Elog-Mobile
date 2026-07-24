import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers.dart';
import '../state/trip_state.dart';
import '../widgets/shared_widgets.dart';
import '../../data/models/trip_model.dart';
import '../../../../routes/router.dart';

class MyTripsPage extends ConsumerWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTripsProvider);
    final session = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến hàng của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => ref.read(myTripsProvider.notifier).loadTrips(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myTripsProvider.notifier).loadTrips(),
        child: Column(
          children: [
            // ── Driver info + date selector ───────────────────────────
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        session.username ?? 'Driver',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Date selector
                  GestureDetector(
                    onTap: () => _pickDate(context, ref, state.date),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateDisplay(state.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.expand_more,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(child: _buildBody(context, state, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyTripsState state, WidgetRef ref) {
    if (state.isLoading && state.trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.trips.isEmpty) {
      return ErrorBanner(
        message: state.errorMessage!,
        onRetry: () => ref.read(myTripsProvider.notifier).loadTrips(),
      );
    }

    if (state.trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Không có chuyến nào cho ngày này',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(myTripsProvider.notifier).loadTrips(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = state.trips[index];
        return _TripCard(
          trip: trip,
          onTap: () => context.push(
            kTripDetailRoute.replaceAll(':tripId', '${trip.tripId}'),
          ),
        );
      },
    );
  }

  String _formatDateDisplay(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, String currentDate) async {
    DateTime initial;
    try {
      initial = DateTime.parse(currentDate);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(myTripsProvider.notifier).changeDate(formatted);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất',
      content: 'Bạn có chắc chắn muốn đăng xuất không?',
      confirmLabel: 'Đăng xuất',
    );
    if (confirmed && context.mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status.toUpperCase() == 'COMPLETED';

    return Opacity(
      opacity: isCompleted ? 0.75 : 1.0,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: route code + status badge ───────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.fixedRouteCode ?? 'Tuyến #${trip.tripId}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ── Vehicle + driver ─────────────────────────────────
                if (trip.vehicle != null)
                  InfoRow(
                    icon: Icons.directions_car_outlined,
                    label: 'Xe',
                    value: trip.vehicle!.plateNumber ??
                        trip.vehicle!.vehicleType ??
                        '—',
                  ),
                if (trip.plannedDepartureTime != null)
                  InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Giờ xuất phát',
                    value: _formatTime(trip.plannedDepartureTime!),
                  ),
                if (trip.deliveryDate != null)
                  InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Ngày giao',
                    value: _formatDate(trip.deliveryDate!),
                  ),

                const SizedBox(height: 10),

                // ── Stops progress ───────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.tripStopCount ?? trip.tripStops.length} điểm giao',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textMuted, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String raw) {
    // Backend returns LocalTime as HH:mm:ss
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }
}
