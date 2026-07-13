import 'project.dart';

class Equipment {
  final int? equipmentId;
  final String equipmentNumber;
  final int projectId;
  final Project? project;
  final bool isActive;

  Equipment({
    this.equipmentId,
    required this.equipmentNumber,
    required this.projectId,
    this.project,
    this.isActive = true,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      equipmentId: json['equipmentId'] as int?,
      equipmentNumber: json['equipmentNumber'] as String,
      projectId: json['projectId'] as int,
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'equipmentNumber': equipmentNumber,
      'projectId': projectId,
      'isActive': isActive,
    };
  }
}
