import 'project.dart';
import 'equipment.dart';
import 'operator.dart';

class SummaryLog {
  final int? summaryId;
  final int projectId;
  final Project? project;
  final DateTime date;
  final String shift;
  final int equipmentId;
  final Equipment? equipment;
  final int operatorId;
  final Operator? operator;
  final DateTime startTimestamp;
  final DateTime endTimestamp;
  final double startHmr;
  final double endHmr;
  final double? totalHmr;
  final double? clockHours;
  final String activityType;
  final String? workDone;
  final String? location;
  final double diesel;
  final double hydraulicOil;
  final double engineOil;
  final double transmissionOil;
  final double gearOil;
  final String? remarks;
  final String? createdBy;
  final DateTime? createdDate;

  SummaryLog({
    this.summaryId,
    required this.projectId,
    this.project,
    required this.date,
    required this.shift,
    required this.equipmentId,
    this.equipment,
    required this.operatorId,
    this.operator,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.startHmr,
    required this.endHmr,
    this.totalHmr,
    this.clockHours,
    required this.activityType,
    this.workDone,
    this.location,
    this.diesel = 0.0,
    this.hydraulicOil = 0.0,
    this.engineOil = 0.0,
    this.transmissionOil = 0.0,
    this.gearOil = 0.0,
    this.remarks,
    this.createdBy,
    this.createdDate,
  });

  factory SummaryLog.fromJson(Map<String, dynamic> json) {
    return SummaryLog(
      summaryId: json['summaryId'] as int?,
      projectId: json['projectId'] as int,
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      date: DateTime.parse(json['date'] as String),
      shift: json['shift'] as String,
      equipmentId: json['equipmentId'] as int,
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      operatorId: json['operatorId'] as int,
      operator: json['operator'] != null ? Operator.fromJson(json['operator']) : null,
      startTimestamp: DateTime.parse(json['startTimestamp'] as String),
      endTimestamp: DateTime.parse(json['endTimestamp'] as String),
      startHmr: (json['startHmr'] as num).toDouble(),
      endHmr: (json['endHmr'] as num).toDouble(),
      totalHmr: (json['totalHmr'] as num?)?.toDouble(),
      clockHours: (json['clockHours'] as num?)?.toDouble(),
      activityType: json['activityType'] as String,
      workDone: json['workDone'] as String?,
      location: json['location'] as String?,
      diesel: (json['diesel'] as num? ?? 0.0).toDouble(),
      hydraulicOil: (json['hydraulicOil'] as num? ?? 0.0).toDouble(),
      engineOil: (json['engineOil'] as num? ?? 0.0).toDouble(),
      transmissionOil: (json['transmissionOil'] as num? ?? 0.0).toDouble(),
      gearOil: (json['gearOil'] as num? ?? 0.0).toDouble(),
      remarks: json['remarks'] as String?,
      createdBy: json['createdBy'] as String?,
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summaryId': summaryId ?? 0,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'shift': shift,
      'equipmentId': equipmentId,
      'operatorId': operatorId,
      'startTimestamp': startTimestamp.toIso8601String(),
      'endTimestamp': endTimestamp.toIso8601String(),
      'startHmr': startHmr,
      'endHmr': endHmr,
      'activityType': activityType,
      'workDone': workDone,
      'location': location,
      'diesel': diesel,
      'hydraulicOil': hydraulicOil,
      'engineOil': engineOil,
      'transmissionOil': transmissionOil,
      'gearOil': gearOil,
      'remarks': remarks,
    };
  }
}
