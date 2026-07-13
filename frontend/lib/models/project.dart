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
}
