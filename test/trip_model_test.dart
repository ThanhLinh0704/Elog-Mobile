import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';

void main() {
  group('TripModel JSON Parsing Tests', () {
    test('should parse valid TripModel JSON successfully', () {
      final json = {
        'tripId': 101,
        'tripDraftId': 5,
        'executionId': 12,
        'status': 'IN_PROGRESS',
        'totalWeightKg': 1500.5,
        'totalVolumeM3': '12.4', // string parsing fallback test
        'vehicle': {
          'vehicleId': 1,
          'plateNumber': '29C-12345',
          'vehicleType': '5-TONS'
        },
        'driver': {
          'userId': 99,
          'fullName': 'Nguyen Van A'
        },
        'tripStops': [
          {
            'tripStopId': 201,
            'sequenceOrder': 1,
            'storeCode': 'STORE001',
            'storeName': 'Store 1',
            'status': 'ARRIVED',
            'stopWeightKg': 500,
            'stopVolumeM3': 4.2
          }
        ]
      };

      final trip = TripModel.fromJson(json);

      expect(trip.tripId, 101);
      expect(trip.status, 'IN_PROGRESS');
      expect(trip.totalWeightKg, 1500.5);
      expect(trip.totalVolumeM3, 12.4); // parsed to double correctly
      expect(trip.vehicle?.plateNumber, '29C-12345');
      expect(trip.driver?.fullName, 'Nguyen Van A');
      expect(trip.tripStops.length, 1);
      expect(trip.tripStops[0].tripStopId, 201);
      expect(trip.tripStops[0].status, 'ARRIVED');
    });

    test('should handle null values in JSON parsing gracefully', () {
      final json = {
        'tripId': 102,
        'status': 'COMPLETED',
        'tripStops': null
      };

      final trip = TripModel.fromJson(json);

      expect(trip.tripId, 102);
      expect(trip.status, 'COMPLETED');
      expect(trip.vehicle, isNull);
      expect(trip.driver, isNull);
      expect(trip.tripStops, isEmpty);
    });
  });
}
