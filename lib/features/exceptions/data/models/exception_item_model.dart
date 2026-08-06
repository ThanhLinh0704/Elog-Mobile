enum ExceptionType { timeException, deliveryRejection, unknown }

extension ExceptionTypeX on ExceptionType {
  static ExceptionType fromRaw(String? raw) {
    switch (raw) {
      case 'TIME_EXCEPTION':
        return ExceptionType.timeException;
      case 'DELIVERY_REJECTION':
        return ExceptionType.deliveryRejection;
      default:
        return ExceptionType.unknown;
    }
  }

  String get label {
    switch (this) {
      case ExceptionType.timeException:
        return 'Trễ ETA';
      case ExceptionType.deliveryRejection:
        return 'Giao hàng thất bại';
      case ExceptionType.unknown:
        return 'Khác';
    }
  }
}

class ExceptionItemModel {
  final int exceptionId;
  final ExceptionType exceptionType;
  final String? rejectionType;

  final int? tripId;
  final String? fixedRouteCode;
  final String? vehicleCode;

  final int? tripStopId;
  final String? storeCode;
  final String? storeName;

  final String? plannedEta;
  final String? actualArrivalTime;
  final int? delayMinutes;

  final String? description;
  final String? reportedBy;
  final String createdAt;

  final String? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  const ExceptionItemModel({
    required this.exceptionId,
    required this.exceptionType,
    this.rejectionType,
    this.tripId,
    this.fixedRouteCode,
    this.vehicleCode,
    this.tripStopId,
    this.storeCode,
    this.storeName,
    this.plannedEta,
    this.actualArrivalTime,
    this.delayMinutes,
    this.description,
    this.reportedBy,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  bool get isResolved => resolvedAt != null;

  factory ExceptionItemModel.fromJson(Map<String, dynamic> json) {
    return ExceptionItemModel(
      exceptionId: json['exceptionId'] as int,
      exceptionType: ExceptionTypeX.fromRaw(json['exceptionType'] as String?),
      rejectionType: json['rejectionType'] as String?,
      tripId: json['tripId'] as int?,
      fixedRouteCode: json['fixedRouteCode'] as String?,
      vehicleCode: json['vehicleCode'] as String?,
      tripStopId: json['tripStopId'] as int?,
      storeCode: json['storeCode'] as String?,
      storeName: json['storeName'] as String?,
      plannedEta: json['plannedEta'] as String?,
      actualArrivalTime: json['actualArrivalTime'] as String?,
      delayMinutes: json['delayMinutes'] as int?,
      description: json['description'] as String?,
      reportedBy: json['reportedBy'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      resolvedAt: json['resolvedAt'] as String?,
      resolvedBy: json['resolvedBy'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
    );
  }
}

class ExceptionListModel {
  final String date;
  final int totalCount;
  final int unresolvedCount;
  final List<ExceptionItemModel> exceptions;

  const ExceptionListModel({
    required this.date,
    required this.totalCount,
    required this.unresolvedCount,
    required this.exceptions,
  });

  factory ExceptionListModel.fromJson(Map<String, dynamic> json) {
    final list = json['exceptions'] as List<dynamic>? ?? [];
    return ExceptionListModel(
      date: json['date'] as String? ?? '',
      totalCount: json['totalCount'] as int? ?? 0,
      unresolvedCount: json['unresolvedCount'] as int? ?? 0,
      exceptions: list
          .map((j) => ExceptionItemModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}
