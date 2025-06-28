abstract class Result<T> {
  const Result();

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Returns the data if success, null if failure
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// Returns the error if failure, null if success
  String? get error => isFailure ? (this as Failure<T>).error : null;

  /// Returns the exception if failure, null if success
  Exception? get exception => isFailure ? (this as Failure<T>).exception : null;

  /// Transform the result using the provided function
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      try {
        return Success(transform((this as Success<T>).data));
      } catch (e) {
        return Failure(
          'Transform failed: ${e.toString()}',
          e is Exception ? e : Exception(e.toString()),
        );
      }
    }
    return Failure((this as Failure<T>).error, (this as Failure<T>).exception);
  }

  /// Execute a function if the result is successful
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// Execute a function if the result is a failure
  Result<T> onFailure(
    void Function(String error, Exception? exception) action,
  ) {
    if (isFailure) {
      final failure = this as Failure<T>;
      action(failure.error, failure.exception);
    }
    return this;
  }

  /// Fold the result into a single value
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(String error, Exception? exception) onFailure,
  ) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).data);
    } else {
      final failure = this as Failure<T>;
      return onFailure(failure.error, failure.exception);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class Failure<T> extends Result<T> {
  final String error;
  final Exception? exception;
  final StackTrace? stackTrace;

  const Failure(this.error, [this.exception, this.stackTrace]);

  @override
  String toString() => 'Failure(error: $error, exception: $exception)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          exception == other.exception;

  @override
  int get hashCode => error.hashCode ^ exception.hashCode;
}

// Extension methods for easier usage
extension ResultExtensions<T> on Result<T> {
  /// Get data or throw exception
  T getOrThrow() {
    if (isSuccess) {
      return (this as Success<T>).data;
    } else {
      final failure = this as Failure<T>;
      throw failure.exception ?? Exception(failure.error);
    }
  }

  /// Get data or return default value
  T getOrElse(T defaultValue) {
    return isSuccess ? (this as Success<T>).data : defaultValue;
  }

  /// Get data or compute default value
  T getOrCompute(T Function() computeDefault) {
    return isSuccess ? (this as Success<T>).data : computeDefault();
  }
}

// Helper functions for creating results
Result<T> success<T>(T data) => Success(data);

Result<T> failure<T>(
  String error, [
  Exception? exception,
  StackTrace? stackTrace,
]) => Failure(error, exception, stackTrace);

// Async result helpers
Future<Result<T>> asyncResult<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return Success(result);
  } catch (e, stackTrace) {
    return Failure(
      e.toString(),
      e is Exception ? e : Exception(e.toString()),
      stackTrace,
    );
  }
}

// Multiple results handling
Result<List<T>> combineResults<T>(List<Result<T>> results) {
  final List<T> successData = [];

  for (final result in results) {
    if (result.isFailure) {
      final failure = result as Failure<T>;
      return Failure(
        'One or more operations failed: ${failure.error}',
        failure.exception,
      );
    }
    successData.add((result as Success<T>).data);
  }

  return Success(successData);
}
