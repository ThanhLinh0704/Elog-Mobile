import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/features/exceptions/presentation/state/exception_state.dart';
import 'package:elog_driver/features/exceptions/data/models/exception_item_model.dart';
import 'fakes.dart';

void main() {
  group('ExceptionsNotifier Tests', () {
    late FakeExceptionRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeExceptionRepository();
    });

    test('should load exceptions successfully on initialization', () async {
      fakeRepo.mockResult = const ExceptionListModel(
        date: '2026-08-08',
        totalCount: 5,
        unresolvedCount: 1,
        exceptions: [
          ExceptionItemModel(
            exceptionId: 1,
            exceptionType: ExceptionType.timeException,
            createdAt: '2026-08-08T10:00:00',
          )
        ],
      );

      final notifier = ExceptionsNotifier(fakeRepo);
      await Future.value(); // Wait for initialization load() to execute

      expect(notifier.debugState.isLoading, isFalse);
      expect(notifier.debugState.errorMessage, isNull);
      expect(notifier.debugState.totalCount, 5);
      expect(notifier.debugState.unresolvedCount, 1);
      expect(notifier.debugState.exceptions.length, 1);
      expect(notifier.debugState.exceptions[0].exceptionId, 1);
    });

    test('should set errorMessage when repository call fails', () async {
      fakeRepo.shouldFail = true;

      final notifier = ExceptionsNotifier(fakeRepo);
      await Future.value();

      expect(notifier.debugState.isLoading, isFalse);
      expect(notifier.debugState.errorMessage, contains('Failed to get exceptions'));
      expect(notifier.debugState.exceptions, isEmpty);
    });

    test('should reload exceptions when date changes', () async {
      final notifier = ExceptionsNotifier(fakeRepo);
      await Future.value();

      notifier.changeDate('2026-08-09');
      await Future.value();

      expect(notifier.debugState.date, '2026-08-09');
    });

    test('should reload exceptions when filters change', () async {
      final notifier = ExceptionsNotifier(fakeRepo);
      await Future.value();

      notifier.changeTypeFilter('TIME_EXCEPTION');
      await Future.value();
      expect(notifier.debugState.typeFilter, 'TIME_EXCEPTION');

      notifier.changeResolvedFilter('true');
      await Future.value();
      expect(notifier.debugState.resolvedFilter, 'true');
    });
  });
}
