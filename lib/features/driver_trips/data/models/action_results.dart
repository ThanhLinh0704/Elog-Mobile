/// Mirrors backend TripStartResponse
class StartTripResult {
  final int tripId;
  final String status;
  final String? actualDepartureTime;
  final String? firstStopCode;
  final String? firstStopEta;
  final String? message;

  const StartTripResult({
    required this.tripId,
    required this.status,
    this.actualDepartureTime,
    this.firstStopCode,
    this.firstStopEta,
    this.message,
  });

  factory StartTripResult.fromJson(Map<String, dynamic> json) =>
      StartTripResult(
        tripId: json['tripId'] as int,
        status: json['status'] as String? ?? 'IN_PROGRESS',
        actualDepartureTime: json['actualDepartureTime'] as String?,
        firstStopCode: json['firstStopCode'] as String?,
        firstStopEta: json['firstStopEta'] as String?,
        message: json['message'] as String?,
      );
}

/// Mirrors backend StopArriveResponse
class ArriveStopResult {
  final int tripStopId;
  final String? storeCode;
  final String status;
  final String? actualArrivalTime;
  final String? plannedEta;
  final int? delayMinutes;
  final bool timeExceptionFlagged;
  final int? exceptionId;
  final String? message;

  const ArriveStopResult({
    required this.tripStopId,
    this.storeCode,
    required this.status,
    this.actualArrivalTime,
    this.plannedEta,
    this.delayMinutes,
    this.timeExceptionFlagged = false,
    this.exceptionId,
    this.message,
  });

  factory ArriveStopResult.fromJson(Map<String, dynamic> json) =>
      ArriveStopResult(
        tripStopId: json['tripStopId'] as int,
        storeCode: json['storeCode'] as String?,
        status: json['status'] as String? ?? 'IN_PROGRESS',
        actualArrivalTime: json['actualArrivalTime'] as String?,
        plannedEta: json['plannedEta'] as String?,
        delayMinutes: json['delayMinutes'] as int?,
        timeExceptionFlagged: json['timeExceptionFlagged'] as bool? ?? false,
        exceptionId: json['exceptionId'] as int?,
        message: json['message'] as String?,
      );
}

/// Mirrors backend StopCompleteResponse
class CompleteStopResult {
  final int tripStopId;
  final String? storeCode;
  final String status;
  final String? actualDepartureTime;
  final bool tripCompleted;
  final String? tripStatus;
  final NextStopSummary? nextStop;
  final String? message;

  const CompleteStopResult({
    required this.tripStopId,
    this.storeCode,
    required this.status,
    this.actualDepartureTime,
    this.tripCompleted = false,
    this.tripStatus,
    this.nextStop,
    this.message,
  });

  factory CompleteStopResult.fromJson(Map<String, dynamic> json) =>
      CompleteStopResult(
        tripStopId: json['tripStopId'] as int,
        storeCode: json['storeCode'] as String?,
        status: json['status'] as String? ?? 'COMPLETED',
        actualDepartureTime: json['actualDepartureTime'] as String?,
        tripCompleted: json['tripCompleted'] as bool? ?? false,
        tripStatus: json['tripStatus'] as String?,
        nextStop: json['nextStop'] != null
            ? NextStopSummary.fromJson(json['nextStop'] as Map<String, dynamic>)
            : null,
        message: json['message'] as String?,
      );
}

class NextStopSummary {
  final int? tripStopId;
  final String? storeCode;
  final String? plannedEta;
  final int? sequenceOrder;

  const NextStopSummary({
    this.tripStopId,
    this.storeCode,
    this.plannedEta,
    this.sequenceOrder,
  });

  factory NextStopSummary.fromJson(Map<String, dynamic> json) =>
      NextStopSummary(
        tripStopId: json['tripStopId'] as int?,
        storeCode: json['storeCode'] as String?,
        plannedEta: json['plannedEta'] as String?,
        sequenceOrder: json['sequenceOrder'] as int?,
      );
}

/// Mirrors backend DeliveryExceptionResponse (used for reject)
class RejectDeliveryResult {
  final int exceptionId;
  final int tripStopId;
  final String? storeCode;
  final String? storeName;
  final String exceptionType;
  final String? rejectionType;
  final String? description;
  final String tripStopStatus;
  final bool? tripCompleted;
  final String? tripStatus;
  final String? message;

  const RejectDeliveryResult({
    required this.exceptionId,
    required this.tripStopId,
    this.storeCode,
    this.storeName,
    required this.exceptionType,
    this.rejectionType,
    this.description,
    required this.tripStopStatus,
    this.tripCompleted,
    this.tripStatus,
    this.message,
  });

  factory RejectDeliveryResult.fromJson(Map<String, dynamic> json) =>
      RejectDeliveryResult(
        exceptionId: json['exceptionId'] as int,
        tripStopId: json['tripStopId'] as int,
        storeCode: json['storeCode'] as String?,
        storeName: json['storeName'] as String?,
        exceptionType: json['exceptionType'] as String? ?? 'DELIVERY_REJECTION',
        rejectionType: json['rejectionType'] as String?,
        description: json['description'] as String?,
        tripStopStatus: json['tripStopStatus'] as String? ?? 'EXCEPTION',
        tripCompleted: json['tripCompleted'] as bool?,
        tripStatus: json['tripStatus'] as String?,
        message: json['message'] as String?,
      );
}
