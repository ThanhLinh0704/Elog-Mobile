import 'trip_stop_model.dart';

/// Mirrors backend TripResponse DTO exactly
class TripModel {
  final int tripId;
  final int? tripDraftId;
  final String? fixedRouteCode;
  final String? deliveryDate; // LocalDate serialized as "yyyy-MM-dd"
  final String status;
  final VehicleInfo? vehicle;
  final DriverInfoModel? driver;
  final double? totalWeightKg;
  final double? totalVolumeM3;
  final String? plannedDepartureTime; // LocalTime as "HH:mm:ss"
  final String? lockedAt;
  final String? completedAt;
  final int? tripStopCount;
  final int? manifestId;
  final List<TripStopModel> tripStops;
  final String? message;

  const TripModel({
    required this.tripId,
    this.tripDraftId,
    this.fixedRouteCode,
    this.deliveryDate,
    required this.status,
    this.vehicle,
    this.driver,
    this.totalWeightKg,
    this.totalVolumeM3,
    this.plannedDepartureTime,
    this.lockedAt,
    this.completedAt,
    this.tripStopCount,
    this.manifestId,
    this.tripStops = const [],
    this.message,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['tripStops'] as List<dynamic>? ?? [];
    return TripModel(
      tripId: json['tripId'] as int,
      tripDraftId: json['tripDraftId'] as int?,
      fixedRouteCode: json['fixedRouteCode'] as String?,
      deliveryDate: json['deliveryDate'] as String?,
      status: json['status'] as String? ?? '',
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? DriverInfoModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      totalWeightKg: _toDouble(json['totalWeightKg']),
      totalVolumeM3: _toDouble(json['totalVolumeM3']),
      plannedDepartureTime: json['plannedDepartureTime'] as String?,
      lockedAt: json['lockedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      tripStopCount: json['tripStopCount'] as int?,
      manifestId: json['manifestId'] as int?,
      tripStops: stopsJson
          .map((s) => TripStopModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class VehicleInfo {
  final int? vehicleId;
  final String? plateNumber;
  final String? vehicleType;

  const VehicleInfo({this.vehicleId, this.plateNumber, this.vehicleType});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
        vehicleId: json['vehicleId'] as int?,
        plateNumber: json['plateNumber'] as String?,
        vehicleType: json['vehicleType'] as String?,
      );
}

class DriverInfoModel {
  final int? userId;
  final String? fullName;

  const DriverInfoModel({this.userId, this.fullName});

  factory DriverInfoModel.fromJson(Map<String, dynamic> json) =>
      DriverInfoModel(
        userId: json['userId'] as int?,
        fullName: json['fullName'] as String?,
      );
}
