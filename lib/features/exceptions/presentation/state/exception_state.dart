import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../providers.dart';
import '../../data/models/exception_item_model.dart';
import '../../data/repositories/exception_repository.dart';

String _formatError(dynamic e) {
  if (e is ApiBusinessException) return e.userMessage;
  if (e is NetworkException) return e.message;
  return e.toString();
}

class ExceptionsState {
  final bool isLoading;
  final List<ExceptionItemModel> exceptions;
  final int totalCount;
  final int unresolvedCount;
  final String? errorMessage;
  final String date; // yyyy-MM-dd
  final String typeFilter; // ALL | TIME_EXCEPTION | DELIVERY_REJECTION
  final String resolvedFilter; // all | false | true

  const ExceptionsState({
    this.isLoading = false,
    this.exceptions = const [],
    this.totalCount = 0,
    this.unresolvedCount = 0,
    this.errorMessage,
    required this.date,
    this.typeFilter = 'ALL',
    this.resolvedFilter = 'all',
  });

  ExceptionsState copyWith({
    bool? isLoading,
    List<ExceptionItemModel>? exceptions,
    int? totalCount,
    int? unresolvedCount,
    String? errorMessage,
    bool clearError = false,
    String? date,
    String? typeFilter,
    String? resolvedFilter,
  }) {
    return ExceptionsState(
      isLoading: isLoading ?? this.isLoading,
      exceptions: exceptions ?? this.exceptions,
      totalCount: totalCount ?? this.totalCount,
      unresolvedCount: unresolvedCount ?? this.unresolvedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      date: date ?? this.date,
      typeFilter: typeFilter ?? this.typeFilter,
      resolvedFilter: resolvedFilter ?? this.resolvedFilter,
    );
  }
}

class ExceptionsNotifier extends StateNotifier<ExceptionsState> {
  final ExceptionRepository _repo;

  ExceptionsNotifier(this._repo) : super(ExceptionsState(date: todayForApi())) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getExceptions(
        date: state.date,
        type: state.typeFilter,
        resolved: state.resolvedFilter,
      );
      state = state.copyWith(
        isLoading: false,
        exceptions: result.exceptions,
        totalCount: result.totalCount,
        unresolvedCount: result.unresolvedCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
    }
  }

  void changeDate(String date) {
    state = state.copyWith(date: date);
    load();
  }

  void changeTypeFilter(String type) {
    state = state.copyWith(typeFilter: type);
    load();
  }

  void changeResolvedFilter(String resolved) {
    state = state.copyWith(resolvedFilter: resolved);
    load();
  }
}

final exceptionsProvider =
    StateNotifierProvider.autoDispose<ExceptionsNotifier, ExceptionsState>(
        (ref) {
  return ExceptionsNotifier(ref.watch(exceptionRepositoryProvider));
});
