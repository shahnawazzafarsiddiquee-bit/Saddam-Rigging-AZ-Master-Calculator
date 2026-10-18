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
      serialNumber: (map['serialNumber'] as String?) ?? '',
      manufacturer: (map['manufacturer'] as String?) ?? '',
      wll: double.tryParse('${map['wll'] ?? ''}') ?? 0,
      inspectionDate: (map['inspectionDate'] as String?) ?? '',
      expiryDate: (map['expiryDate'] as String?) ?? '',
      status: map['status'] as String,
    );
  }

  /// Date-only expiry remains valid through the recorded local calendar day.
  /// A missing/invalid date is never treated as evidence of current inspection.
  bool get isExpired => isExpiredAt(DateTime.now());
  bool isExpiredAt(DateTime now) {
    final expiry = validDate(expiryDate);
    if (expiry == null) return true;
    return DateTime(now.year, now.month, now.day).isAfter(expiry);
  }

  static DateTime? validDate(String text) {
    final value = text.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        parsed.year.toString().padLeft(4, '0') != value.substring(0, 4) ||
        parsed.month.toString().padLeft(2, '0') != value.substring(5, 7) ||
        parsed.day.toString().padLeft(2, '0') != value.substring(8, 10))
      return null;
    return parsed;
  }

  bool get isRestricted => restrictedStatus(status);
  static bool restrictedStatus(String value) => const {
    'quarantine',
    'quarantined',
    'hold',
    'reject',
    'rejected',
    'scrapped',
    'scrap',
    'scrap pending',
    'destroyed',
  }.contains(value.trim().toLowerCase());

  bool get hasCurrentRegistration => registrationCurrentAt(DateTime.now());
  bool registrationCurrentAt(DateTime now) {
    final inspected = validDate(inspectionDate);
    final today = DateTime(now.year, now.month, now.day);
    return status == 'Active' &&
        !isRestricted &&
        !isExpiredAt(now) &&
        wll.isFinite &&
        wll > 0 &&
        equipmentId.trim().isNotEmpty &&
        serialNumber.trim().isNotEmpty &&
        manufacturer.trim().isNotEmpty &&
        inspected != null &&
        !inspected.isAfter(today);
  }
}
