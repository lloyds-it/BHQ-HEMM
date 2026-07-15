class Operator {
  final int? operatorId;
  final String operatorName;
  final String? mobile;
  final String? employeeCode;
  final String? department;
  final String? designation;
  final String? company;
  final bool isActive;

  Operator({
    this.operatorId,
    required this.operatorName,
    this.mobile,
    this.employeeCode,
    this.department,
    this.designation,
    this.company,
    this.isActive = true,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      operatorId: json['operatorId'] as int?,
      operatorName: json['operatorName'] as String,
      mobile: json['mobile'] as String?,
      employeeCode: json['employeeCode'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      company: json['company'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operatorId': operatorId,
      'operatorName': operatorName,
      'mobile': mobile,
      'employeeCode': employeeCode,
      'department': department,
      'designation': designation,
      'company': company,
      'isActive': isActive,
    };
  }
}
