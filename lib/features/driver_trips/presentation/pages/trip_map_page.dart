import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../../../providers.dart';
import '../../data/models/trip_progress_model.dart';
import '../widgets/shared_widgets.dart';

/// Route map for 1 trip — warehouse + destination points (stops) plus the
/// road-following route, built entirely from data the backend already
/// computes (TripProgressResponse.routePolyline + per-stop coordinates).
/// No live GPS tracking here — this only plots the planned route.
class TripMapPage extends ConsumerStatefulWidget {
  final int tripId;

  const TripMapPage({super.key, required this.tripId});

  @override
  ConsumerState<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends ConsumerState<TripMapPage> {
  final _mapController = MapController();
  late Future<TripProgressModel> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future =
        ref.read(tripRepositoryProvider).getTripProgress(widget.tripId);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length == 1) {
        _mapController.move(points.first, 14);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ tuyến đường'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_load),
          ),
        ],
      ),
      body: FutureBuilder<TripProgressModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorBanner(
              message: 'Không tải được dữ liệu bản đồ: ${snapshot.error}',
              onRetry: () => setState(_load),
            );
          }
          final trip = snapshot.data!;
          return _buildMap(trip);
        },
      ),
    );
  }

  Widget _buildMap(TripProgressModel trip) {
    final routePoints = decodeMultiLegPolyline(trip.routePolyline);
    final stopsWithCoords =
        trip.stops.where((s) => s.hasCoordinates).toList()
          ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    // Warehouse sits at the start of the road route when we have one — the
    // route is always built starting from the warehouse (see BE
    // TripMonitoringServiceImpl.getTripProgress).
    final warehousePos = routePoints.isNotEmpty ? routePoints.first : null;

    final linePoints = routePoints.isNotEmpty
        ? routePoints
        : stopsWithCoords.map((s) => LatLng(s.latitude!, s.longitude!)).toList();

    final allPoints = <LatLng>[
      ...linePoints,
      ...stopsWithCoords.map((s) => LatLng(s.latitude!, s.longitude!)),
    ];

    if (allPoints.isEmpty) {
      return const ErrorBanner(
        message: 'Chuyến xe này chưa có tọa độ điểm giao nào để hiện trên bản đồ.',
      );
    }

    _fitBounds(allPoints);

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: allPoints.first,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.elog.driver',
              ),
              if (linePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: linePoints,
                      strokeWidth: 5,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (warehousePos != null)
                    Marker(
                      point: warehousePos,
                      width: 130,
                      height: 34,
                      alignment: Alignment.center,
                      child: _WarehouseMarker(),
                    ),
                  for (final stop in stopsWithCoords)
                    Marker(
                      point: LatLng(stop.latitude!, stop.longitude!),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: _StopMarker(stop: stop),
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _legendDot(AppTheme.stopStatusColor('PENDING'), 'Chờ đến'),
          _legendDot(AppTheme.stopStatusColor('IN_PROGRESS'), 'Đang giao'),
          _legendDot(AppTheme.stopStatusColor('COMPLETED'), 'Đã hoàn thành'),
          _legendDot(AppTheme.stopStatusColor('EXCEPTION'), 'Có ngoại lệ'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _StopMarker extends StatelessWidget {
  final StopProgressModel stop;

  const _StopMarker({required this.stop});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.stopStatusColor(stop.status);
    return GestureDetector(
      onTap: () => _showStopInfo(context),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '${stop.sequenceOrder}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showStopInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${stop.sequenceOrder} — ${stop.storeCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (stop.storeName != null && stop.storeName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(stop.storeName!,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 10),
            StatusBadge(status: stop.status, isStop: true),
          ],
        ),
      ),
    );
  }
}

class _WarehouseMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warehouse, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'KHO XUẤT HÀNG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
