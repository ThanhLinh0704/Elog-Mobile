import 'driver_trip_model.dart';

/// Mirrors UpdateOrderResultRequest DTO
/// PUT /api/v1/driver/trips/{executionId}/orders/{orderId}/result
class UpdateOrderResultRequest {
  final OrderDeliveryStatus status;
  final String? reasonCode; // Required for PARTIALLY_DELIVERED and FAILED
  final String? exceptionText;

  const UpdateOrderResultRequest({
    required this.status,
    this.reasonCode,
    this.exceptionText,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'status': status.toApiString(),
    };
    if (reasonCode != null) map['reasonCode'] = reasonCode;
    if (exceptionText != null && exceptionText!.isNotEmpty) {
      map['exceptionText'] = exceptionText;
    }
    return map;
  }
}
