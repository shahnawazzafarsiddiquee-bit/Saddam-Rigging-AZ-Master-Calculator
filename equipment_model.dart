class EquipmentModel {
  final int? id;
  final String equipmentId;
  final String type;
  final String serialNumber;
  final String manufacturer;
  final double wll; // tonnes
  final String inspectionDate; // ISO yyyy-MM-dd
  final String expiryDate; // ISO yyyy-MM-dd
  final String status; // Active / Quarantine / Expired / Scrapped

  EquipmentModel({
    this.id,
    required this.equipmentId,
    required this.type,
    required this.serialNumber,
    required this.manufacturer,
    required this.wll,
    required this.inspectionDate,
    required this.expiryDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'type': type,
      'serialNumber': serialNumber,
      'manufacturer': manufacturer,
      'wll': wll,
      'inspectionDate': inspectionDate,
      'expiryDate': expiryDate,
      'status': status,
    };
  }

  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map['id'] as int?,
      equipmentId: map['equipmentId'] as String,
      type: map['type'] as String,
      serialNumber: map['serialNumber'] as String,
      manufacturer: map['manufacturer'] as String,
      wll: (map['wll'] as num).toDouble(),
      inspectionDate: map['inspectionDate'] as String,
      expiryDate: map['expiryDate'] as String,
      status: map['status'] as String,
    );
  }

  bool get isExpired {
    try {
      final expiry = DateTime.parse(expiryDate);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }
}
