import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/features/exceptions/data/models/exception_item_model.dart';

void main() {
  group('ExceptionItemModel JSON Parsing Tests', () {
    test('should parse valid ExceptionItemModel JSON successfully', () {
      final json = {
        'exceptionId': 501,
        'exceptionType': 'TIME_EXCEPTION',
        'rejectionType': null,
        'tripId': 10,
        'fixedRouteCode': 'R-01',
        'vehicleCode': 'V-01',
        'tripStopId': 20,
        'storeCode': 'ST001',
        'storeName': 'Store 1',
        'plannedEta': '2026-08-08T10:00:00',
        'actualArrivalTime': '2026-08-08T10:15:00',
        'delayMinutes': 15,
        'description': 'Late due to traffic',
        'reportedBy': 'driver1',
        'createdAt': '2026-08-08T10:20:00',
        'resolvedAt': '2026-08-08T10:30:00',
        'resolvedBy': 'dispatcher1',
        'resolutionNotes': 'Approved delay'
      };

      final item = ExceptionItemModel.fromJson(json);

      expect(item.exceptionId, 501);
      expect(item.exceptionType, ExceptionType.timeException);
      expect(item.exceptionType.label, 'Trễ ETA');
      expect(item.tripId, 10);
      expect(item.fixedRouteCode, 'R-01');
      expect(item.storeName, 'Store 1');
      expect(item.delayMinutes, 15);
      expect(item.isResolved, isTrue);
    });

    test('should handle unresolved exceptions with resolvedAt null', () {
      final json = {
        'exceptionId': 502,
        'exceptionType': 'DELIVERY_REJECTION',
        'createdAt': '2026-08-08T10:20:00',
        'resolvedAt': null
      };

      final item = ExceptionItemModel.fromJson(json);

      expect(item.exceptionId, 502);
      expect(item.exceptionType, ExceptionType.deliveryRejection);
      expect(item.exceptionType.label, 'Giao hàng thất bại');
      expect(item.isResolved, isFalse);
    });

    test('should parse ExceptionListModel JSON successfully', () {
      final json = {
        'date': '2026-08-08',
        'totalCount': 10,
        'unresolvedCount': 2,
        'exceptions': [
          {
            'exceptionId': 601,
            'exceptionType': 'TIME_EXCEPTION',
            'createdAt': '2026-08-08T10:20:00',
            'resolvedAt': null
          }
        ]
      };

      final list = ExceptionListModel.fromJson(json);

      expect(list.date, '2026-08-08');
      expect(list.totalCount, 10);
      expect(list.unresolvedCount, 2);
      expect(list.exceptions.length, 1);
      expect(list.exceptions[0].exceptionId, 601);
    });
  });
}
