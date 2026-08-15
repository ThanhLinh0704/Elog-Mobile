/// Mirrors backend DriverTripResponse and all nested DTOs.
/// Source: com.elog.controller.DriverTripController / DriverTripResponse

// ── Enums (from BE DTO comments) ─────────────────────────────────────────────

/// TripExecution.status
enum ExecutionStatus {
  assigned,
  inProgress,
  completed,
  completedWithExceptions;

  static ExecutionStatus fromJson(String s) {
    switch (s.toUpperCase()) {
      case 'ASSIGNED':
        return ExecutionStatus.assigned;
      case 'IN_PROGRESS':
        return ExecutionStatus.inProgress;
      case 'COMPLETED':
        return ExecutionStatus.completed;
      case 'COMPLETED_WITH_EXCEPTIONS':
        return ExecutionStatus.completedWithExceptions;
      default:
        return ExecutionStatus.assigned;
    }
  }

  String get label {
    switch (this) {
      case ExecutionStatus.assigned:
        return 'Đã phân công';
      case ExecutionStatus.inProgress:
        return 'Đang giao';
      case ExecutionStatus.completed:
        return 'Hoàn thành';
      case ExecutionStatus.completedWithExceptions:
        return 'Hoàn thành (có ngoại lệ)';
    }
  }
}

/// Order.deliveryStatus
enum OrderDeliveryStatus {
  pending,
  delivered,
  partiallyDelivered,
  failed,
  cancelled;

  static OrderDeliveryStatus fromJson(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return OrderDeliveryStatus.pending;
      case 'DELIVERED':
        return OrderDeliveryStatus.delivered;
      case 'PARTIALLY_DELIVERED':
        return OrderDeliveryStatus.partiallyDelivered;
      case 'FAILED':
        return OrderDeliveryStatus.failed;
      case 'CANCELLED':
        return OrderDeliveryStatus.cancelled;
      default:
        return OrderDeliveryStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case OrderDeliveryStatus.pending:
        return 'PENDING';
      case OrderDeliveryStatus.delivered:
        return 'DELIVERED';
      case OrderDeliveryStatus.partiallyDelivered:
        return 'PARTIALLY_DELIVERED';
      case OrderDeliveryStatus.failed:
        return 'FAILED';
      case OrderDeliveryStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OrderDeliveryStatus.pending:
        return 'Chờ giao';
      case OrderDeliveryStatus.delivered:
        return 'Đã giao';
      case OrderDeliveryStatus.partiallyDelivered:
        return 'Giao một phần';
      case OrderDeliveryStatus.failed:
        return 'Thất bại';
      case OrderDeliveryStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get needsReason =>
      this == OrderDeliveryStatus.partiallyDelivered ||
      this == OrderDeliveryStatus.failed;
}

/// Stop.aggregatedStatus
/// NOTE: BE uses "PARTIAL" (not "PARTIALLY_DELIVERED")
enum StopAggregatedStatus {
  pending,
  delivered,
  partial,
  failed;

  static StopAggregatedStatus fromJson(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return StopAggregatedStatus.pending;
      case 'DELIVERED':
        return StopAggregatedStatus.delivered;
      case 'PARTIAL':
        return StopAggregatedStatus.partial;
      case 'FAILED':
        return StopAggregatedStatus.failed;
      default:
        return StopAggregatedStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case StopAggregatedStatus.pending:
        return 'Chờ giao';
      case StopAggregatedStatus.delivered:
        return 'Đã giao';
      case StopAggregatedStatus.partial:
        return 'Giao một phần';
      case StopAggregatedStatus.failed:
        return 'Thất bại';
    }
  }
}

// ── reasonCode options ────────────────────────────────────────────────────────

class ReasonCodeOption {
  final String code;
  final String label;
  const ReasonCodeOption({required this.code, required this.label});
}

const kReasonCodeOptions = [
  ReasonCodeOption(code: 'STORE_REJECTED', label: 'Cửa hàng từ chối nhận hàng'),
  ReasonCodeOption(code: 'STORE_CLOSED', label: 'Cửa hàng đóng cửa'),
  ReasonCodeOption(code: 'WRONG_ITEMS', label: 'Hàng không đúng đơn'),
  ReasonCodeOption(code: 'DAMAGED_GOODS', label: 'Hàng bị hư hỏng'),
  ReasonCodeOption(code: 'NO_SPACE', label: 'Không có chỗ chứa hàng'),
  ReasonCodeOption(code: 'RECIPIENT_ABSENT', label: 'Người nhận vắng mặt'),
  ReasonCodeOption(code: 'DELIVERY_FAILED_OTHER', label: 'Lý do khác'),
];

// ── Nested models ─────────────────────────────────────────────────────────────

/// Mirrors DriverTripResponse.DriverOrderItemDto
class DriverOrderItemModel {
  final String sku;
  final String productName;
  final int quantity;
  final double? unitWeightKg;
  final double? unitVolumeM3;

  const DriverOrderItemModel({
    required this.sku,
    required this.productName,
    required this.quantity,
    this.unitWeightKg,
    this.unitVolumeM3,
  });

  factory DriverOrderItemModel.fromJson(Map<String, dynamic> json) =>
      DriverOrderItemModel(
        sku: json['sku'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        unitWeightKg: _toDouble(json['unitWeightKg']),
        unitVolumeM3: _toDouble(json['unitVolumeM3']),
      );
}

/// Mirrors DriverTripResponse.DriverOrderDto
class DriverOrderModel {
  final int orderId;
  final String orderRef;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryTimeWindow;
  final String? notes;
  final OrderDeliveryStatus deliveryStatus;
  final String? exceptionReason;
  final List<DriverOrderItemModel> items;

  const DriverOrderModel({
    required this.orderId,
    required this.orderRef,
    this.recipientName,
    this.recipientPhone,
    this.deliveryTimeWindow,
    this.notes,
    required this.deliveryStatus,
    this.exceptionReason,
    this.items = const [],
  });

  factory DriverOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return DriverOrderModel(
      orderId: json['orderId'] as int,
      orderRef: json['orderRef'] as String? ?? '',
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      deliveryTimeWindow: json['deliveryTimeWindow'] as String?,
      notes: json['notes'] as String?,
      deliveryStatus: OrderDeliveryStatus.fromJson(
          json['deliveryStatus'] as String? ?? 'PENDING'),
      exceptionReason: json['exceptionReason'] as String?,
      items: itemsJson
          .map((i) => DriverOrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mirrors DriverTripResponse.DriverStopDto
class DriverStopModel {
  final int stopId;
  final int sequenceNo;
  final String storeCode;
  final String storeName;
  final String address;
  final String? plannedEta; // "HH:mm:ss"
  final String? closingTime; // "HH:mm:ss"
  final StopAggregatedStatus aggregatedStatus;
  // "PENDING" | "ARRIVED" — whether the driver has tapped "Đã đến điểm giao"
  // for this stop yet. Order-result updates are locked client-side until this
  // is "ARRIVED" (BUG-STOP-TIME-01: without an explicit arrival marker, the
  // web dispatcher view never got a real "actual arrival time" for the stop).
  final String arrivalStatus;
  final String? actualArrivalTime;
  final List<DriverOrderModel> orders;

  const DriverStopModel({
    required this.stopId,
    required this.sequenceNo,
    required this.storeCode,
    required this.storeName,
    required this.address,
    this.plannedEta,
    this.closingTime,
    required this.aggregatedStatus,
    this.arrivalStatus = 'PENDING',
    this.actualArrivalTime,
    this.orders = const [],
  });

  bool get hasArrived => arrivalStatus == 'ARRIVED';

  factory DriverStopModel.fromJson(Map<String, dynamic> json) {
    final ordersJson = json['orders'] as List<dynamic>? ?? [];
    return DriverStopModel(
      stopId: json['stopId'] as int,
      sequenceNo: json['sequenceNo'] as int? ?? 0,
      storeCode: json['storeCode'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      plannedEta: json['plannedEta'] as String?,
      closingTime: json['closingTime'] as String?,
      aggregatedStatus: StopAggregatedStatus.fromJson(
          json['aggregatedStatus'] as String? ?? 'PENDING'),
      arrivalStatus: json['arrivalStatus'] as String? ?? 'PENDING',
      actualArrivalTime: json['actualArrivalTime'] as String?,
      orders: ordersJson
          .map((o) => DriverOrderModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mirrors DriverTripResponse.LifoLoadingItemDto
class LifoLoadingItemModel {
  final int loadingOrder; // 1 = xếp vào đầu tiên (sâu nhất trong xe)
  final int stopSequenceNo;
  final String storeName;
  final String orderRef;
  final String sku;
  final String productName;
  final int quantity;
  final String instruction;

  const LifoLoadingItemModel({
    required this.loadingOrder,
    required this.stopSequenceNo,
    required this.storeName,
    required this.orderRef,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.instruction,
  });

  factory LifoLoadingItemModel.fromJson(Map<String, dynamic> json) =>
      LifoLoadingItemModel(
        loadingOrder: json['loadingOrder'] as int? ?? 0,
        stopSequenceNo: json['stopSequenceNo'] as int? ?? 0,
        storeName: json['storeName'] as String? ?? '',
        orderRef: json['orderRef'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        instruction: json['instruction'] as String? ?? '',
      );
}

// ── Root model ────────────────────────────────────────────────────────────────

/// Mirrors full DriverTripResponse
class DriverTripModel {
  final int executionId;
  final int tripId;
  final String tripCode;
  final String deliveryDate; // "yyyy-MM-dd"
  final ExecutionStatus status;
  final int? assignmentVersion;
  final String? returnedToWarehouseAt;

  final String? vehicleCode;
  final String? plateNumber;
  final String? driverName;

  final int totalStops;
  final int totalOrders;
  final int completedOrdersCount;
  final int pendingOrdersCount;

  final List<DriverStopModel> stops;
  final List<LifoLoadingItemModel> lifoLoadingGuidance;

  const DriverTripModel({
    required this.executionId,
    required this.tripId,
    required this.tripCode,
    required this.deliveryDate,
    required this.status,
    this.assignmentVersion,
    this.returnedToWarehouseAt,
    this.vehicleCode,
    this.plateNumber,
    this.driverName,
    this.totalStops = 0,
    this.totalOrders = 0,
    this.completedOrdersCount = 0,
    this.pendingOrdersCount = 0,
    this.stops = const [],
    this.lifoLoadingGuidance = const [],
  });

  DriverTripModel copyWith({
    ExecutionStatus? status,
    String? returnedToWarehouseAt,
    int? completedOrdersCount,
    int? pendingOrdersCount,
  }) {
    return DriverTripModel(
      executionId: executionId,
      tripId: tripId,
      tripCode: tripCode,
      deliveryDate: deliveryDate,
      status: status ?? this.status,
      assignmentVersion: assignmentVersion,
      returnedToWarehouseAt:
          returnedToWarehouseAt ?? this.returnedToWarehouseAt,
      vehicleCode: vehicleCode,
      plateNumber: plateNumber,
      driverName: driverName,
      totalStops: totalStops,
      totalOrders: totalOrders,
      completedOrdersCount: completedOrdersCount ?? this.completedOrdersCount,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      stops: stops,
      lifoLoadingGuidance: lifoLoadingGuidance,
    );
  }

  factory DriverTripModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List<dynamic>? ?? [];
    final lifoJson = json['lifoLoadingGuidance'] as List<dynamic>? ?? [];
    return DriverTripModel(
      executionId: json['executionId'] as int,
      tripId: json['tripId'] as int? ?? 0,
      tripCode: json['tripCode'] as String? ?? '',
      deliveryDate: json['deliveryDate'] as String? ?? '',
      status: ExecutionStatus.fromJson(json['status'] as String? ?? 'ASSIGNED'),
      assignmentVersion: json['assignmentVersion'] as int?,
      returnedToWarehouseAt: json['returnedToWarehouseAt'] as String?,
      vehicleCode: json['vehicleCode'] as String?,
      plateNumber: json['plateNumber'] as String?,
      driverName: json['driverName'] as String?,
      totalStops: json['totalStops'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrdersCount: json['completedOrdersCount'] as int? ?? 0,
      pendingOrdersCount: json['pendingOrdersCount'] as int? ?? 0,
      stops: stopsJson
          .map((s) => DriverStopModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      lifoLoadingGuidance: lifoJson
          .map((l) => LifoLoadingItemModel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
