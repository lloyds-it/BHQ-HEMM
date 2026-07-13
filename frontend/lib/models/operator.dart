class Operator {
  final int? operatorId;
  final String operatorName;
  final String? mobile;
  final bool isActive;

  Operator({
    this.operatorId,
    required this.operatorName,
    this.mobile,
    this.isActive = true,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      operatorId: json['operatorId'] as int?,
      operatorName: json['operatorName'] as String,
      mobile: json['mobile'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operatorId': operatorId,
      'operatorName': operatorName,
      'mobile': mobile,
      'isActive': isActive,
    };
  }
}
