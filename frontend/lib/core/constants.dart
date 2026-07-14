import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class AppConstants {
  /// Determines the correct API base URL based on platform:
  /// - Web / Windows: localhost
  /// - Android Emulator: 10.0.2.2 (maps to host machine's localhost)
  /// - Real Android Device / iOS on real device: your PC's local IP
  static String get apiBaseUrl {
    if (kIsWeb) {
      if (kDebugMode) {
        return 'http://localhost:5000/api';
      }
      return 'https://taskai.lloyds.in/hemm/api';
    }
    if (Platform.isAndroid) {
      // Now points to the production Linux server
      return realDeviceApiUrl;
    }
    if (Platform.isIOS) {
      return realDeviceApiUrl;
    }
    return 'http://localhost:5100/api';
  }

  /// Production server URL - works from anywhere with internet access.
  static const String realDeviceIp = 'taskai.lloyds.in';
  static const String realDeviceApiUrl = 'https://taskai.lloyds.in/hemm/api';

  static const String roleAdmin = 'Admin';
  static const String roleSupervisor = 'Supervisor';
  static const String roleOperator = 'Operator';

  static const String activityRunning = 'Running';
  static const String activityIdle = 'Idle';
  static const String activityBreakdown = 'Breakdown';
  static const String activityStoppage = 'Stoppage';

  static const List<String> activities = [
    activityRunning,
    activityIdle,
    activityBreakdown,
    activityStoppage,
  ];

  static const List<String> shifts = [
    'Day',
    'Night',
  ];
}
