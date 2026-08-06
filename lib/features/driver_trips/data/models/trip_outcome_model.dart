/// Mirrors backend TripOutcomeResponse DTO (TripOutcomeController)

enum TripOutcomeStatus {
  submitted,
  validated,
  needsCorrection;

  static TripOutcomeStatus fromJson(String s) {
    switch (s.toUpperCase()) {
      case 'SUBMITTED':
        return TripOutcomeStatus.submitted;
      case 'VALIDATED':
        return TripOutcomeStatus.validated;
      case 'NEEDS_CORRECTION':
        return TripOutcomeStatus.needsCorrection;
      default:
        return TripOutcomeStatus.submitted;
    }
  }

  String get label {
    switch (this) {
      case TripOutcomeStatus.submitted:
        return 'Chờ nghiệm thu';
      case TripOutcomeStatus.validated:
        return 'Đã nghiệm thu';
      case TripOutcomeStatus.needsCorrection:
        return 'Cần điều chỉnh';
    }
  }
}

class TripOutcomeModel {
  final int id;
  final int executionId;
  final int tripId;
  final String tripCode;
  final String? driverName;
  final String? vehiclePlate;
  final TripOutcomeStatus status;
  final int totalOrders;
  final int deliveredCount;
  final int failedCount;
  final int partialCount;
  final String? submittedAt; // ISO datetime
  final String? validatedAt;
  final String? validatedBy;
  final String? amendmentReason;
  final int version;

  const TripOutcomeModel({
    required this.id,
    required this.executionId,
    required this.tripId,
    required this.tripCode,
    this.driverName,
    this.vehiclePlate,
    required this.status,
    this.totalOrders = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.partialCount = 0,
    this.submittedAt,
    this.validatedAt,
    this.validatedBy,
    this.amendmentReason,
    this.version = 0,
  });

  factory TripOutcomeModel.fromJson(Map<String, dynamic> json) =>
      TripOutcomeModel(
        id: json['id'] as int,
        executionId: json['executionId'] as int? ?? 0,
        tripId: json['tripId'] as int? ?? 0,
        tripCode: json['tripCode'] as String? ?? '',
        driverName: json['driverName'] as String?,
        vehiclePlate: json['vehiclePlate'] as String?,
        status: TripOutcomeStatus.fromJson(
            json['status'] as String? ?? 'SUBMITTED'),
        totalOrders: json['totalOrders'] as int? ?? 0,
        deliveredCount: json['deliveredCount'] as int? ?? 0,
        failedCount: json['failedCount'] as int? ?? 0,
        partialCount: json['partialCount'] as int? ?? 0,
        submittedAt: json['submittedAt'] as String?,
        validatedAt: json['validatedAt'] as String?,
        validatedBy: json['validatedBy'] as String?,
        amendmentReason: json['amendmentReason'] as String?,
        version: json['version'] as int? ?? 0,
      );
}
