import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'result.dart';

class ErrorHandler {
  static Result<T> handleError<T>(dynamic error, [StackTrace? stackTrace]) {
    String message;
    Exception? exception;

    if (error is DioException) {
      message = _handleDioError(error);
      exception = error;
    } else if (error is SocketException) {
      message = 'No internet connection. Please check your network.';
      exception = error;
    } else if (error is FormatException) {
      message = 'Invalid data format received from server.';
      exception = error;
    } else if (error is TimeoutException) {
      message = 'Request timeout. Please try again.';
      exception = error;
    } else if (error is Exception) {
      message = error.toString();
      exception = error;
    } else {
      message = 'An unexpected error occurred: ${error.toString()}';
      exception = Exception(error.toString());
    }

    // Log error in debug mode
    if (kDebugMode) {
      debugPrint('Error: $message');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    return Failure<T>(message, exception, stackTrace);
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please check your connection security.';
      case DioExceptionType.unknown:
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Server error (${statusCode ?? 'Unknown'}). Please try again.';
    }
  }
}
