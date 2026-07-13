import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/live_entry.dart';
import '../models/summary_log.dart';
import '../models/operator.dart';

class EntryProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<LiveEntry> _liveEntries = [];
  List<LiveEntry> get liveEntries => _liveEntries;

  List<SummaryLog> _summaryLogs = [];
  List<SummaryLog> get summaryLogs => _summaryLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Live Entries
  Future<void> fetchLiveEntries() async {
    _isLoading = true;
    try {
      final response = await _apiClient.get('/LiveEntry');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _liveEntries = data.map((json) => LiveEntry.fromJson(json)).toList();
      } else {
        debugPrint('[EntryProvider] fetchLiveEntries failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[EntryProvider] fetchLiveEntries error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Operator?> getLastOperatorForEquipment(int equipmentId) async {
    try {
      final response = await _apiClient.get('/LiveEntry/last-operator/$equipmentId');
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return Operator.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[EntryProvider] getLastOperator error: $e');
    }
    return null;
  }

  Future<bool> addLiveEntry(LiveEntry entry) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('[EntryProvider] Posting LiveEntry: ${jsonEncode(entry.toJson())}');
      final response = await _apiClient.post('/LiveEntry', entry.toJson());
      debugPrint('[EntryProvider] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        await fetchLiveEntries();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      debugPrint('[EntryProvider] addLiveEntry error: $e');
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Summary Logs
  Future<void> fetchSummaryLogs() async {
    _isLoading = true;
    try {
      final response = await _apiClient.get('/SummaryLog');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _summaryLogs = data.map((json) => SummaryLog.fromJson(json)).toList();
      } else {
        debugPrint('[EntryProvider] fetchSummaryLogs failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[EntryProvider] fetchSummaryLogs error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSummaryLog(SummaryLog log) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('[EntryProvider] Posting SummaryLog: ${jsonEncode(log.toJson())}');
      final response = await _apiClient.post('/SummaryLog', log.toJson());
      debugPrint('[EntryProvider] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        await fetchSummaryLogs();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      debugPrint('[EntryProvider] addSummaryLog error: $e');
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  String _parseErrorMessage(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'];
        if (data.containsKey('error')) return data['error'];
        // ModelState errors
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map;
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.cast<String>());
            } else if (value is String) {
              messages.add(value);
            }
          });
          if (messages.isNotEmpty) {
            final joinedErrors = messages.join('\n');
            if (data.containsKey('title')) {
              return '${data['title']}\n$joinedErrors';
            }
            return joinedErrors;
          }
        }
        if (data.containsKey('title')) return data['title'];
      }
      if (data is String) return data;
    } catch (_) {}
    return 'Server error ($statusCode). Please try again.';
  }
}
