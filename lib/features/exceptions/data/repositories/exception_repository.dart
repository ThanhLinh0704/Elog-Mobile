import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/exception_item_model.dart';

/// Read-only — driver chỉ xem ngoại lệ của chính mình, không có quyền resolve
/// (BE tự lọc theo tài xế khi role là DRIVER, xem ExceptionServiceImpl.listExceptions).
class ExceptionRepository {
  final Dio _dio;

  const ExceptionRepository(this._dio);

  /// GET /api/v1/exceptions
  /// [type]: ALL | TIME_EXCEPTION | DELIVERY_REJECTION
  /// [resolved]: true | false | all
  Future<ExceptionListModel> getExceptions({
    required String date, // yyyy-MM-dd
    String type = 'ALL',
    String resolved = 'false',
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/exceptions',
        queryParameters: {
          'date': date,
          'type': type,
          'resolved': resolved,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ExceptionListModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
