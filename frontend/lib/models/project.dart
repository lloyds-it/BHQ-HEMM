class Project {
  final int? projectId;
  final String projectName;

  Project({this.projectId, required this.projectName});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          projectName == other.projectName;

  @override
  int get hashCode => projectId.hashCode ^ projectName.hashCode;
}
