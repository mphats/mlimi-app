import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ErrorHandler {
  /// Show a standardized error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Show a standardized success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Show a standardized info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Show a standardized warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// Show a standardized error dialog
  static Future<void> showErrorDialog(BuildContext context, String title, String message) async {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Show a standardized confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Parse and format API error messages
  static String formatApiErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    // If it's already a string, return it
    if (error is String) return error;

    // Handle map-based error responses
    if (error is Map<String, dynamic>) {
      // Check for common error response formats
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      if (error.containsKey('detail')) {
        return error['detail'].toString();
      }
      if (error.containsKey('error')) {
        return error['error'].toString();
      }

      // Handle validation errors
      if (error.containsKey('errors') && error['errors'] is Map) {
        final errors = error['errors'] as Map;
        final messages = <String>[];
        errors.forEach((key, value) {
          if (value is List) {
            messages.add('$key: ${value.join(', ')}');
          } else {
            messages.add('$key: $value');
          }
        });
        return messages.join('\n');
      }

      // Handle field-specific errors
      final messages = <String>[];
      error.forEach((key, value) {
        if (value is List) {
          messages.add('$key: ${value.join(', ')}');
        } else {
          messages.add('$key: $value');
        }
      });
      return messages.join('\n');
    }

    // Handle list-based error responses
    if (error is List) {
      return error.join('\n');
    }

    // Default fallback
    return error.toString();
  }

  /// Handle common exception types
  static String handleException(Object exception) {
    // Handle network-related exceptions
    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('Network')) {
      return 'Network error. Please check your internet connection.';
    }

    // Handle timeout exceptions
    if (exception.toString().contains('Timeout')) {
      return 'Request timeout. Please try again.';
    }

    // Handle unauthorized exceptions
    if (exception.toString().contains('401') ||
        exception.toString().contains('Unauthorized')) {
      return 'Your session has expired. Please log in again.';
    }

    // Handle forbidden exceptions
    if (exception.toString().contains('403') ||
        exception.toString().contains('Forbidden')) {
      return 'You do not have permission to perform this action.';
    }

    // Handle not found exceptions
    if (exception.toString().contains('404') ||
        exception.toString().contains('Not Found')) {
      return 'The requested resource was not found.';
    }

    // Handle server exceptions
    if (exception.toString().contains('500') ||
        exception.toString().contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    }

    // Default error message
    return 'An error occurred. Please try again.';
  }
}