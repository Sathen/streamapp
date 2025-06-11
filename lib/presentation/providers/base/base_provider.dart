import 'package:flutter/foundation.dart';

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
