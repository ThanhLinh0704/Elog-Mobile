/// Mirrors backend TripStopResponse DTO exactly.
/// Note: actualArrivalTime, actualDepartureTime, delayMinutes,
/// hasException are NOT in the base TripStopResponse — they are returned
/// by the arrive/complete action responses and can be tracked locally
/// after actions.
class TripStopModel {
  final int tripStopId;
  final int? routeStopId;
  final int? tripDraftStopId;
  final int? sequenceOrder;
  final String? storeCode;
  final String? storeName;
  final String? plannedEta; // ISO datetime string from backend
  final String status;
  final double? stopWeightKg;
  final double? stopVolumeM3;
  final String? notes;

  // Fields populated from arrive/complete responses (not in list endpoint)
  final String? actualArrivalTime;
  final String? actualDepartureTime;
  final int? delayMinutes;
  final bool? hasException;

  const TripStopModel({
    required this.tripStopId,
    this.routeStopId,
    this.tripDraftStopId,
    this.sequenceOrder,
    this.storeCode,
    this.storeName,
    this.plannedEta,
    required this.status,
    this.stopWeightKg,
    this.stopVolumeM3,
    this.notes,
    this.actualArrivalTime,
    this.actualDepartureTime,
    this.delayMinutes,
    this.hasException,
  });

  factory TripStopModel.fromJson(Map<String, dynamic> json) => TripStopModel(
        tripStopId: json['tripStopId'] as int,
        routeStopId: json['routeStopId'] as int?,
        tripDraftStopId: json['tripDraftStopId'] as int?,
        sequenceOrder: json['sequenceOrder'] as int?,
        storeCode: json['storeCode'] as String?,
        storeName: json['storeName'] as String?,
        plannedEta: json['plannedEta'] as String?,
        status: json['status'] as String? ?? 'PENDING',
        stopWeightKg: _toDouble(json['stopWeightKg']),
        stopVolumeM3: _toDouble(json['stopVolumeM3']),
        notes: json['notes'] as String?,
        actualArrivalTime: json['actualArrivalTime'] as String?,
        actualDepartureTime: json['actualDepartureTime'] as String?,
        delayMinutes: json['delayMinutes'] as int?,
        hasException: json['hasException'] as bool?,
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Create a copy of this stop with updated fields (from action responses)
  TripStopModel copyWith({
    String? status,
    String? actualArrivalTime,
    String? actualDepartureTime,
    int? delayMinutes,
    bool? hasException,
  }) {
    return TripStopModel(
      tripStopId: tripStopId,
      routeStopId: routeStopId,
      tripDraftStopId: tripDraftStopId,
      sequenceOrder: sequenceOrder,
      storeCode: storeCode,
      storeName: storeName,
      plannedEta: plannedEta,
      status: status ?? this.status,
      stopWeightKg: stopWeightKg,
      stopVolumeM3: stopVolumeM3,
      notes: notes,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      hasException: hasException ?? this.hasException,
    );
  }
}
