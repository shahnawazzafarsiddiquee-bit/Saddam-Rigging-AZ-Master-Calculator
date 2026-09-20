class LiftModel {
  final int? id;
  final String projectName;
  final String client;
  final String location;
  final String date;
  final String loadDescription;
  final double loadWeight;
  final String craneDetails;
  final String riggingArrangement;
  final String liftingSequence;
  final String personnel;
  final String safetyRequirements;

  LiftModel({
    this.id,
    required this.projectName,
    required this.client,
    required this.location,
    required this.date,
    required this.loadDescription,
    required this.loadWeight,
    required this.craneDetails,
    required this.riggingArrangement,
    required this.liftingSequence,
    required this.personnel,
    required this.safetyRequirements,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectName': projectName,
      'client': client,
      'location': location,
      'date': date,
      'loadDescription': loadDescription,
      'loadWeight': loadWeight,
      'craneDetails': craneDetails,
      'riggingArrangement': riggingArrangement,
      'liftingSequence': liftingSequence,
      'personnel': personnel,
      'safetyRequirements': safetyRequirements,
    };
  }

  factory LiftModel.fromMap(Map<String, dynamic> map) {
    return LiftModel(
      id: map['id'] as int?,
      projectName: map['projectName'] as String,
      client: map['client'] as String,
      location: map['location'] as String,
      date: map['date'] as String,
      loadDescription: map['loadDescription'] as String,
      loadWeight: (map['loadWeight'] as num).toDouble(),
      craneDetails: map['craneDetails'] as String,
      riggingArrangement: map['riggingArrangement'] as String,
      liftingSequence: map['liftingSequence'] as String,
      personnel: map['personnel'] as String,
      safetyRequirements: map['safetyRequirements'] as String,
    );
  }
}
