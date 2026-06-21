/// Custom exception hierarchy for FlockSense
///
/// Provides categorized exceptions for better error handling and user feedback
import 'package:flutter/foundation.dart';

/// Base exception class for all FlockSense exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException(this.message, {this.code, this.originalException});

  @override
  String toString() => message;
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(String message, {String? code, Exception? originalException})
    : super(message, code: code, originalException: originalException);
}

/// Firestore/Database exceptions
class FirestoreException extends AppException {
  FirestoreException(
    String message, {
    String? code,
    Exception? originalException,
  }) : super(message, code: code, originalException: originalException);
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(String message, {String? code, Exception? originalException})
    : super(message, code: code, originalException: originalException);
}

/// Validation exceptions (input validation, business logic validation)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    String message, {
    String? code,
    Exception? originalException,
    this.fieldErrors,
  }) : super(message, code: code, originalException: originalException);
}

/// Permission/Authorization exceptions
class PermissionException extends AppException {
  PermissionException(
    String message, {
    String? code,
    Exception? originalException,
  }) : super(message, code: code, originalException: originalException);
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  NotFoundException(
    String message, {
    String? code,
    Exception? originalException,
  }) : super(message, code: code, originalException: originalException);
}

/// Cache/Local storage exceptions
class CacheException extends AppException {
  CacheException(String message, {String? code, Exception? originalException})
    : super(message, code: code, originalException: originalException);
}

/// Sync/Offline exceptions
class SyncException extends AppException {
  final int? failedOperations;
  final DateTime? lastSyncTime;

  SyncException(
    String message, {
    String? code,
    Exception? originalException,
    this.failedOperations,
    this.lastSyncTime,
  }) : super(message, code: code, originalException: originalException);
}

/// Unexpected/Unknown exceptions
class UnknownException extends AppException {
  UnknownException(String message, {String? code, Exception? originalException})
    : super(message, code: code, originalException: originalException);
}

/// Exception mapper - converts Firebase exceptions to custom exceptions
class ExceptionMapper {
  static AppException mapException(dynamic exception) {
    debugPrint('[ExceptionMapper] Mapping exception: ${exception.runtimeType}');

    if (exception is AppException) {
      return exception;
    }

    if (exception is FormatException) {
      return ValidationException('Invalid input format: ${exception.message}');
    }

    // Safe cast helper
    Exception? asException(dynamic e) => e is Exception ? e : null;

    final errorString = exception.toString().toLowerCase();

    if (errorString.contains('authentication') ||
        errorString.contains('auth/')) {
      return AuthException(
        _extractFirebaseMessage(exception) ?? 'Authentication failed',
        code: _extractFirebaseCode(exception),
        originalException: asException(exception),
      );
    }

    if (errorString.contains('firestore') ||
        errorString.contains('permission-denied')) {
      final code = _extractFirebaseCode(exception);
      final message = _extractFirebaseMessage(exception);

      if (code == 'permission-denied') {
        return PermissionException(
          message ?? 'Permission denied. Check your Firestore rules.',
          code: code,
          originalException: asException(exception),
        );
      }

      if (code == 'not-found') {
        return NotFoundException(
          message ?? 'Resource not found',
          code: code,
          originalException: asException(exception),
        );
      }

      return FirestoreException(
        message ?? 'Database error occurred',
        code: code,
        originalException: asException(exception),
      );
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return NetworkException(
        _extractFirebaseMessage(exception) ??
            'Network error. Check your connection.',
        code: _extractFirebaseCode(exception),
        originalException: asException(exception),
      );
    }

    return UnknownException(
      exception.toString(),
      originalException: asException(exception),
    );
  }

  static String? _extractFirebaseCode(dynamic exception) {
    try {
      if (exception.code != null) {
        return exception.code as String?;
      }
    } catch (_) {}
    return null;
  }

  static String? _extractFirebaseMessage(dynamic exception) {
    try {
      if (exception.message != null) {
        return exception.message as String?;
      }
    } catch (_) {}
    return null;
  }
}

/// User-friendly error messages
class ErrorMessages {
  static String getDisplayMessage(AppException exception) {
    if (exception is AuthException) {
      return exception.code == 'user-not-found'
          ? 'No account found with this email'
          : exception.code == 'wrong-password'
          ? 'Incorrect password'
          : exception.code == 'weak-password'
          ? 'Password must be at least 6 characters'
          : exception.code == 'email-already-in-use'
          ? 'This email is already registered'
          : exception.message;
    }

    if (exception is NetworkException) {
      return 'No internet connection. Please check your network.';
    }

    if (exception is PermissionException) {
      return 'You do not have permission to perform this action.';
    }

    if (exception is NotFoundException) {
      return 'The requested resource was not found.';
    }

    if (exception is ValidationException) {
      return exception.message;
    }

    if (exception is FirestoreException) {
      return exception.code == 'unavailable'
          ? 'Service temporarily unavailable. Please try again.'
          : exception.code == 'deadline-exceeded'
          ? 'Request timeout. Please check your connection.'
          : exception.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
