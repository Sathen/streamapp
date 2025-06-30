import 'package:flutter/foundation.dart';

import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';

abstract class BaseProvider extends ChangeNotifier {
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
  Future<Result<T>> executeOperation<T>(
    Future<T> Function() operation, {
    String? errorPrefix,
  }) async {
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

  @protected
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
