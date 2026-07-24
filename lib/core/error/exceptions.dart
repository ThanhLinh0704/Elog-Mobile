/// Standard API error parsed from backend error envelope:
/// { "success": false, "error": { "code": "...", "message": "..." } }
class ApiBusinessException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;

  const ApiBusinessException({
    this.statusCode,
    this.code,
    required this.message,
  });

  @override
  String toString() => userMessage;

  /// Map backend error codes to user-friendly Vietnamese messages
  String get userMessage {
    switch (code) {
      case 'NOT_YOUR_TRIP':
        return 'Bạn không được phân công cho chuyến này.';
      case 'INVALID_TRIP_TRANSITION':
      case 'INVALID_STATE_TRANSITION':
        return 'Trạng thái chuyến không hợp lệ. Vui lòng tải lại.';
      case 'TRIP_COMPLETED':
        return 'Chuyến này đã hoàn thành.';
      case 'STOP_ALREADY_DONE':
        return 'Điểm giao này đã được xử lý.';
      case 'STOP_NOT_IN_PROGRESS':
        return 'Bạn cần báo đã đến điểm giao trước khi ghi nhận lỗi giao hàng.';
      case 'STOP_NOT_PENDING':
        return 'Điểm giao này không ở trạng thái chờ.';
      case 'REJECTION_ALREADY_RECORDED':
        return 'Điểm giao này đã được ghi nhận từ chối giao hàng.';
      case 'PREVIOUS_STOP_NOT_DONE':
        return 'Vui lòng hoàn thành điểm giao trước đó.';
      case 'TRIP_STOP_NOT_FOUND':
      case 'TRIP_NOT_FOUND':
        return 'Không tìm thấy thông tin. Vui lòng tải lại.';
      case 'ACCESS_DENIED':
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 'VALIDATION_FAILED':
        return message;
      default:
        return message;
    }
  }
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}
