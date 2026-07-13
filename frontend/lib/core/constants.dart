import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  /// Determines the correct API base URL based on platform:
  /// - Web / Windows: localhost
  /// - Android Emulator: 10.0.2.2 (maps to host machine's localhost)
  /// - Real Android Device / iOS on real device: your PC's local IP
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'https://taskai.lloyds.in/hemm/api';
    }
    if (Platform.isAndroid) {
      // Changed to the PC's Wi-Fi IP address so the APK works on a real device
      return realDeviceApiUrl;
    }
    if (Platform.isIOS) {
      return realDeviceApiUrl;
    }
    return 'http://localhost:5100/api';
  }

  /// Use this IP when running on a REAL physical Android/iOS device.
  /// Your PC must be on the same WiFi network as the device.
  static const String realDeviceIp = '172.52.1.1';
  static const String realDeviceApiUrl = 'http://172.52.1.1:5100/api';

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
