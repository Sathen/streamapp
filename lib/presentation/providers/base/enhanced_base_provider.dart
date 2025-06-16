import 'package:flutter/foundation.dart';

import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';

abstract class EnhancedBaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasError => _error != null;

  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    if (loading) _error = null; // Clear error when starting new operation
    safeNotifyListeners();
  }

  @protected
  void setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    _isLoading = false;
    safeNotifyListeners();
  }

  @protected
  void clearError() {
    if (_isDisposed) return;
    _error = null;
    safeNotifyListeners();
  }

  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Execute an operation with automatic loading state and error handling
  @protected
  Future<Result<T>> executeOperation<T>(
    Future<T> Function() operation, {
    String? errorPrefix,
  }) async {
    if (_isDisposed) return failure('Provider disposed');

    setLoading(true);

    try {
      final result = await operation();
      clearError();
      return success(result);
    } catch (e, stackTrace) {
      final errorMessage =
          errorPrefix != null ? '$errorPrefix: ${e.toString()}' : e.toString();
      setError(errorMessage);
      return ErrorHandler.handleError<T>(e, stackTrace);
    } finally {
      setLoading(false);
    }
  }

  /// Execute multiple operations concurrently
  @protected
  Future<Result<List<T>>> executeOperations<T>(
    List<Future<T> Function()> operations, {
    String? errorPrefix,
  }) async {
    if (_isDisposed) return failure('Provider disposed');

    setLoading(true);

    try {
      final futures = operations.map((op) => op()).toList();
      final results = await Future.wait(futures);
      clearError();
      return success(results);
    } catch (e, stackTrace) {
      final errorMessage =
          errorPrefix != null ? '$errorPrefix: ${e.toString()}' : e.toString();
      setError(errorMessage);
      return ErrorHandler.handleError<List<T>>(e, stackTrace);
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
