/// Thin wrapper describing what data goes into an equipment QR code.
/// Kept simple/offline: the QR just encodes the equipment ID, which the
/// app looks up in the local SQLite database when scanned.
class QrService {
  static String buildPayload(String equipmentId) {
    return 'SADDAM-RIG:$equipmentId';
  }

  static String? parseEquipmentId(String scanned) {
    if (scanned.startsWith('SADDAM-RIG:')) {
      return scanned.substring('SADDAM-RIG:'.length);
    }
    // Fall back to treating the raw scanned text as the equipment ID,
    // in case an older / plain QR label is scanned.
    if (scanned.trim().isNotEmpty) return scanned.trim();
    return null;
  }
}
