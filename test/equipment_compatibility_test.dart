import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/models/equipment_model.dart';
import 'package:saddam_rigging_az_master_calculator/services/qr_service.dart';

void main() {
  Map<String, dynamic> row({
    String expiry = '2026-10-18',
    String inspection = '2026-10-17',
    String status = 'Active',
  }) => {
    'id': 42,
    'equipmentId': 'SL-42',
    'type': 'Web Sling',
    'serialNumber': 'SER-42',
    'manufacturer': 'TEST',
    'wll': 2.0,
    'inspectionDate': inspection,
    'expiryDate': expiry,
    'status': status,
  };
  final today = DateTime(2026, 10, 18, 18);
  test(
    'nullable optional released columns remain readable without changing IDs',
    () {
      final record = row();
      for (final name in [
        'serialNumber',
        'manufacturer',
        'inspectionDate',
        'expiryDate',
      ]) {
        record[name] = null;
      }
      final equipment = EquipmentModel.fromMap(record);
      expect(equipment.id, 42);
      expect(equipment.equipmentId, 'SL-42');
      expect(equipment.serialNumber, '');
      expect(equipment.isExpiredAt(today), isTrue);
      expect(equipment.registrationCurrentAt(today), isFalse);
    },
  );
  test('date-only expiry includes its calendar day and excludes the next', () {
    final equipment = EquipmentModel.fromMap(row());
    expect(equipment.isExpiredAt(today), isFalse);
    expect(equipment.registrationCurrentAt(today), isTrue);
    expect(equipment.isExpiredAt(DateTime(2026, 10, 19)), isTrue);
  });
  test('missing and impossible dates never appear current', () {
    for (final invalid in ['', 'bad', '2026-02-30', '2026-13-01']) {
      expect(
        EquipmentModel.fromMap(row(expiry: invalid))
            .registrationCurrentAt(today),
        isFalse,
      );
      expect(
        EquipmentModel.fromMap(row(inspection: invalid))
            .registrationCurrentAt(today),
        isFalse,
      );
    }
    expect(
      EquipmentModel.fromMap(row(inspection: '2026-10-19'))
          .registrationCurrentAt(today),
      isFalse,
    );
  });
  test('all legacy restricted status aliases are excluded', () {
    for (final status in [
      'Quarantine',
      'Quarantined',
      'HOLD',
      'Reject',
      'REJECTED',
      'Scrapped',
      'Scrap pending',
      'Destroyed',
    ]) {
      final equipment = EquipmentModel.fromMap(row(status: status));
      expect(equipment.isRestricted, isTrue, reason: status);
      expect(equipment.registrationCurrentAt(today), isFalse, reason: status);
    }
  });
  test('legacy invalid WLL remains readable but cannot look current', () {
    for (final value in [
      null,
      0,
      -1,
      'not-a-number',
      double.nan,
      double.infinity,
    ]) {
      final record = row()..['wll'] = value;
      expect(
        EquipmentModel.fromMap(record).registrationCurrentAt(today),
        isFalse,
      );
    }
  });
  test('QR supports existing labels and rejects empty IDs', () {
    expect(
      QrService.parseEquipmentId(QrService.buildPayload('SL-42')),
      'SL-42',
    );
    expect(QrService.parseEquipmentId('  SADDAM-RIG: SL-42\n'), 'SL-42');
    expect(QrService.parseEquipmentId('SL-42'), 'SL-42');
    expect(QrService.parseEquipmentId(' SADDAM-RIG: '), isNull);
    expect(QrService.parseEquipmentId(' '), isNull);
  });
}
