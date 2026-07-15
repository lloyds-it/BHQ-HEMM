import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/project.dart';
import '../models/equipment.dart';
import '../models/operator.dart';

class MasterProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Project> _projects = [];
  List<Project> get projects => _projects;

  List<Equipment> _equipment = [];
  List<Equipment> get equipment => _equipment;

  List<Operator> _operators = [];
  List<Operator> get operators => _operators;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

  // Projects
  Future<void> fetchProjects() async {
    _isLoading = true;
    try {
      final response = await _apiClient.get('/Project');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _projects = data.map((json) => Project.fromJson(json)).toList();
      }
    } catch (e) {
      // error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProject(String name) async {
    clearError();
    try {
      final response = await _apiClient.post('/Project', {'projectName': name});
      if (response.statusCode == 201) {
        await fetchProjects();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateProject(int id, String name) async {
    clearError();
    try {
      final response = await _apiClient.put('/Project/$id', {'projectId': id, 'projectName': name});
      if (response.statusCode == 204) {
        await fetchProjects();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteProject(int id) async {
    clearError();
    try {
      final response = await _apiClient.delete('/Project/$id');
      if (response.statusCode == 204) {
        await fetchProjects();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  // Equipment
  Future<void> fetchEquipment({String? searchQuery}) async {
    _isLoading = true;
    try {
      final queryParam = searchQuery != null ? '?search=$searchQuery' : '';
      final response = await _apiClient.get('/Equipment$queryParam');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _equipment = data.map((json) => Equipment.fromJson(json)).toList();
      }
    } catch (e) {
      // error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEquipment(String number, int projectId) async {
    clearError();
    try {
      final response = await _apiClient.post('/Equipment', {
        'equipmentNumber': number,
        'projectId': projectId,
        'isActive': true,
      });
      if (response.statusCode == 201) {
        await fetchEquipment();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateEquipment(int id, String number, int projectId, bool isActive) async {
    clearError();
    try {
      final response = await _apiClient.put('/Equipment/$id', {
        'equipmentId': id,
        'equipmentNumber': number,
        'projectId': projectId,
        'isActive': isActive,
      });
      if (response.statusCode == 204) {
        await fetchEquipment();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteEquipment(int id) async {
    clearError();
    try {
      final response = await _apiClient.delete('/Equipment/$id');
      if (response.statusCode == 204) {
        await fetchEquipment();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  // Operators
  Future<void> fetchOperators({String? searchQuery}) async {
    _isLoading = true;
    try {
      final queryParam = searchQuery != null ? '?search=$searchQuery' : '';
      final response = await _apiClient.get('/Operator$queryParam');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _operators = data.map((json) => Operator.fromJson(json)).toList();
      }
    } catch (e) {
      // error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addOperator({
    required String name,
    String? mobile,
    String? employeeCode,
    String? department,
    String? designation,
    String? company,
  }) async {
    clearError();
    try {
      final response = await _apiClient.post('/Operator', {
        'operatorName': name,
        'mobile': mobile,
        'employeeCode': employeeCode,
        'department': department,
        'designation': designation,
        'company': company,
        'isActive': true,
      });
      if (response.statusCode == 201) {
        await fetchOperators();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateOperator({
    required int id,
    required String name,
    String? mobile,
    String? employeeCode,
    String? department,
    String? designation,
    String? company,
    required bool isActive,
  }) async {
    clearError();
    try {
      final response = await _apiClient.put('/Operator/$id', {
        'operatorId': id,
        'operatorName': name,
        'mobile': mobile,
        'employeeCode': employeeCode,
        'department': department,
        'designation': designation,
        'company': company,
        'isActive': isActive,
      });
      if (response.statusCode == 204) {
        await fetchOperators();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteOperator(int id) async {
    clearError();
    try {
      final response = await _apiClient.delete('/Operator/$id');
      if (response.statusCode == 204) {
        await fetchOperators();
        return true;
      } else {
        _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }
    notifyListeners();
    return false;
  }
}
