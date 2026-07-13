import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class DashboardProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  int _todayLiveEntriesCount = 0;
  int get todayLiveEntriesCount => _todayLiveEntriesCount;

  int _runningEquipmentCount = 0;
  int get runningEquipmentCount => _runningEquipmentCount;

  int _idleEquipmentCount = 0;
  int get idleEquipmentCount => _idleEquipmentCount;

  int _breakdownEquipmentCount = 0;
  int get breakdownEquipmentCount => _breakdownEquipmentCount;

  int _stoppageEquipmentCount = 0;
  int get stoppageEquipmentCount => _stoppageEquipmentCount;

  List<dynamic> _recentEntries = [];
  List<dynamic> get recentEntries => _recentEntries;

  List<dynamic> _operatorStats = [];
  List<dynamic> get operatorStats => _operatorStats;

  List<dynamic> _shiftStats = [];
  List<dynamic> get shiftStats => _shiftStats;

  List<dynamic> _weeklyTrends = [];
  List<dynamic> get weeklyTrends => _weeklyTrends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/Dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _todayLiveEntriesCount = data['todayLiveEntriesCount'] as int? ?? 0;
        _runningEquipmentCount = data['runningEquipmentCount'] as int? ?? 0;
        _idleEquipmentCount = data['idleEquipmentCount'] as int? ?? 0;
        _breakdownEquipmentCount = data['breakdownEquipmentCount'] as int? ?? 0;
        _stoppageEquipmentCount = data['stoppageEquipmentCount'] as int? ?? 0;
        _recentEntries = data['recentEntries'] as List<dynamic>? ?? [];
        _operatorStats = data['operatorStats'] as List<dynamic>? ?? [];
        _shiftStats = data['shiftStats'] as List<dynamic>? ?? [];
        _weeklyTrends = data['weeklyTrends'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      // error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
