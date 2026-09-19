class InspectionModel {
  final int? id;
  final String equipmentId;
  final String inspectorName;
  final String inspectionDate;
  final String result; // Pass / Fail / Conditional
  final String remarks;

  InspectionModel({
    this.id,
    required this.equipmentId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.result,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'inspectorName': inspectorName,
      'inspectionDate': inspectionDate,
      'result': result,
      'remarks': remarks,
    };
  }

  factory InspectionModel.fromMap(Map<String, dynamic> map) {
    return InspectionModel(
      id: map['id'] as int?,
      equipmentId: map['equipmentId'] as String,
      inspectorName: map['inspectorName'] as String,
      inspectionDate: map['inspectionDate'] as String,
      result: map['result'] as String,
      remarks: map['remarks'] as String,
    );
  }
}
