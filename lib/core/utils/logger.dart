import 'package:flutter/foundation.dart';

class Logger {
  static void debug(String message) {
    // In a real implementation, this would log to a file or remote service
    // For now, we'll just log to console in debug mode
    assert(() {
      debugPrint('DEBUG: $message');
      return true;
    }());
  }

  static void info(String message) {
    debugPrint('INFO: $message');
  }

  static void warn(String message) {
    debugPrint('WARN: $message');
  }

  static void error(String message) {
    debugPrint('ERROR: $message');
  }

  static void fatal(String message) {
    debugPrint('FATAL: $message');
  }
}