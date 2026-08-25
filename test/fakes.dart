import 'package:elog_driver/core/storage/secure_storage_service.dart';
import 'package:elog_driver/features/auth/data/auth_service.dart';
import 'package:elog_driver/features/driver_trips/data/repositories/trip_repository.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/driver_trip_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_outcome_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/action_results.dart';
import 'package:elog_driver/features/exceptions/data/repositories/exception_repository.dart';
import 'package:elog_driver/features/exceptions/data/models/exception_item_model.dart';


class FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String roles,
    required String userId,
    required String fullName,
  }) async {
    _data['accessToken'] = accessToken;
    _data['refreshToken'] = refreshToken;
    _data['username'] = username;
    _data['roles'] = roles;
    _data['userId'] = userId;
    _data['fullName'] = fullName;
  }

  @override
  Future<String?> getAccessToken() async => _data['accessToken'];
  @override
  Future<String?> getRefreshToken() async => _data['refreshToken'];
  @override
  Future<String?> getUsername() async => _data['username'];
  @override
  Future<String?> getRoles() async => _data['roles'];
  @override
  Future<String?> getUserId() async => _data['userId'];
  @override
  Future<String?> getFullName() async => _data['fullName'];

  @override
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> isDriver() async {
    final roles = await getRoles();
    return roles != null && roles.contains('DRIVER');
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

class FakeAuthService implements AuthService {
  final FakeSecureStorage _fakeStorage;
  bool shouldFail = false;
  String failMessage = 'Invalid credentials';

  FakeAuthService(this._fakeStorage);

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    final roles = username == 'driver' ? ['DRIVER'] : ['USER'];
    await _fakeStorage.saveTokens(
      accessToken: 'fake_access_token',
      refreshToken: 'fake_refresh_token',
      username: username,
      roles: roles.join(','),
      userId: '123',
      fullName: 'Fake Full Name',
    );
    return {
      'roles': roles,
      'username': username,
      'userId': '123',
      'accessToken': 'fake_access_token',
    };
  }

  @override
  Future<void> logout() async {
    await _fakeStorage.clearAll();
  }
}

class FakeTripRepository implements TripRepository {
  List<TripModel> mockTrips = [];
  bool shouldFail = false;

  @override
  Future<List<TripModel>> getMyTrips({
    required String date,
    String? status,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to load trips');
    }
    return mockTrips;
  }

  @override
  Future<TripModel> getTripDetail(int tripId) async {
    if (shouldFail) {
      throw Exception('Failed to load trip detail');
    }
    return mockTrips.firstWhere((t) => t.tripId == tripId,
        orElse: () => TripModel(tripId: tripId, status: 'DISPATCHED', deliveryDate: '2026-08-15'));
  }

  @override
  Future<StartTripResult> startTrip(int tripId) async {
    if (shouldFail) throw Exception('Failed to start trip');
    return StartTripResult(tripId: tripId, status: 'IN_PROGRESS');
  }

  @override
  Future<ArriveStopResult> arriveAtStop(int tripStopId) async {
    if (shouldFail) throw Exception('Failed to arrive at stop');
    return ArriveStopResult(tripStopId: tripStopId, status: 'IN_PROGRESS');
  }

  @override
  Future<CompleteStopResult> completeStop(int tripStopId) async {
    if (shouldFail) throw Exception('Failed to complete stop');
    return CompleteStopResult(tripStopId: tripStopId, status: 'COMPLETED');
  }

  @override
  Future<RejectDeliveryResult> rejectDelivery(
      int tripStopId, RejectDeliveryRequest request) async {
    if (shouldFail) throw Exception('Failed to reject delivery');
    return RejectDeliveryResult(exceptionId: 1, tripStopId: tripStopId, exceptionType: 'DELIVERY_REJECTION', tripStopStatus: 'EXCEPTION');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDriverTripRepository implements DriverTripRepository {
  DriverTripModel? mockActiveTrip;
  List<DriverTripModel> mockPendingReturnTrips = [];
  bool shouldFail = false;

  @override
  Future<DriverTripModel?> getActiveTrip() async {
    if (shouldFail) throw Exception('Failed to get active trip');
    return mockActiveTrip;
  }

  @override
  Future<List<DriverTripModel>> getPendingReturnTrips() async {
    if (shouldFail) throw Exception('Failed to get pending return trips');
    return mockPendingReturnTrips;
  }

  @override
  Future<DriverTripModel> startExecution(int executionId) async {
    if (shouldFail) throw Exception('Failed to start execution');
    if (mockActiveTrip != null) {
      mockActiveTrip = mockActiveTrip!.copyWith(status: ExecutionStatus.inProgress);
    }
    return mockActiveTrip ?? DriverTripModel(executionId: executionId, tripId: 100, tripCode: 'TRIP-100', deliveryDate: '2026-08-15', status: ExecutionStatus.inProgress);
  }

  @override
  Future<DriverTripModel> arriveAtStop(int executionId, int stopId) async {
    if (shouldFail) throw Exception('Failed to arrive at stop');
    return mockActiveTrip ?? DriverTripModel(executionId: executionId, tripId: 100, tripCode: 'TRIP-100', deliveryDate: '2026-08-15', status: ExecutionStatus.inProgress);
  }

  @override
  Future<DriverTripModel> updateOrderResult(
    int executionId,
    int orderId,
    dynamic request,
  ) async {
    if (shouldFail) throw Exception('Failed to update order result');
    return mockActiveTrip ?? DriverTripModel(executionId: executionId, tripId: 100, tripCode: 'TRIP-100', deliveryDate: '2026-08-15', status: ExecutionStatus.inProgress);
  }

  @override
  Future<TripOutcomeModel> completeExecution(int executionId) async {
    if (shouldFail) throw Exception('Failed to complete execution');
    return TripOutcomeModel(
      id: 1,
      executionId: executionId,
      tripId: 100,
      tripCode: 'TRIP-100',
      totalOrders: 5,
      deliveredCount: 4,
      failedCount: 1,
      partialCount: 0,
      status: TripOutcomeStatus.submitted,
    );
  }

  @override
  Future<DriverTripModel> returnToWarehouse(int executionId) async {
    if (shouldFail) throw Exception('Failed to return to warehouse');
    if (mockActiveTrip != null) {
      mockActiveTrip = mockActiveTrip!.copyWith(status: ExecutionStatus.completed);
    }
    return mockActiveTrip ?? DriverTripModel(executionId: executionId, tripId: 100, tripCode: 'TRIP-100', deliveryDate: '2026-08-15', status: ExecutionStatus.completed);
  }
}

class FakeExceptionRepository implements ExceptionRepository {
  ExceptionListModel? mockResult;
  bool shouldFail = false;

  @override
  Future<ExceptionListModel> getExceptions({
    required String date,
    String type = 'ALL',
    String resolved = 'false',
  }) async {
    if (shouldFail) {
      throw Exception('Failed to get exceptions');
    }
    return mockResult ?? ExceptionListModel(
      date: date,
      totalCount: 0,
      unresolvedCount: 0,
      exceptions: const [],
    );
  }
}
