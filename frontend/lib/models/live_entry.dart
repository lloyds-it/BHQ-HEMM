import 'project.dart';
import 'equipment.dart';
import 'operator.dart';

class LiveEntry {
  final int? entryId;
  final int projectId;
  final Project? project;
  final int equipmentId;
  final Equipment? equipment;
  final int? operatorId;
  final Operator? operator;
  final DateTime entryTimestamp;
  final double hmrValue;
  final String activityType;
  final String? createdBy;
  final DateTime? createdDate;

  LiveEntry({
    this.entryId,
    required this.projectId,
    this.project,
    required this.equipmentId,
    this.equipment,
    this.operatorId,
    this.operator,
    required this.entryTimestamp,
    required this.hmrValue,
    required this.activityType,
    this.createdBy,
    this.createdDate,
  });

  factory LiveEntry.fromJson(Map<String, dynamic> json) {
    return LiveEntry(
      entryId: json['entryId'] as int?,
      projectId: json['projectId'] as int,
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      equipmentId: json['equipmentId'] as int,
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      operatorId: json['operatorId'] as int?,
      operator: json['operator'] != null ? Operator.fromJson(json['operator']) : null,
      entryTimestamp: DateTime.parse(json['entryTimestamp'] as String),
      hmrValue: (json['hmrValue'] as num).toDouble(),
      activityType: json['activityType'] as String,
      createdBy: json['createdBy'] as String?,
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId ?? 0,
      'projectId': projectId,
      'equipmentId': equipmentId,
      'operatorId': operatorId,
      'entryTimestamp': entryTimestamp.toIso8601String(),
      'hmrValue': hmrValue,
      'activityType': activityType,
    };
  }
}
