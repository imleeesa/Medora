import 'dart:convert';

class MedicineNotificationPayload {
  const MedicineNotificationPayload({
    required this.medicineId,
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
  });

  static const version = 1;

  final String medicineId;
  final int dayOfWeek;
  final int hour;
  final int minute;

  String encode() {
    return jsonEncode({
      'v': version,
      'medicineId': medicineId,
      'dayOfWeek': dayOfWeek,
      'hour': hour,
      'minute': minute,
    });
  }

  static MedicineNotificationPayload? tryDecode(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final medicineId = decoded['medicineId'];
      final dayOfWeek = decoded['dayOfWeek'];
      final hour = decoded['hour'];
      final minute = decoded['minute'];
      if (medicineId is! String ||
          dayOfWeek is! int ||
          hour is! int ||
          minute is! int) {
        return null;
      }
      if (dayOfWeek < DateTime.monday ||
          dayOfWeek > DateTime.sunday ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }
      return MedicineNotificationPayload(
        medicineId: medicineId,
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime scheduledDateTime({DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    var scheduled = DateTime(
      reference.year,
      reference.month,
      reference.day,
      hour,
      minute,
    );

    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.subtract(const Duration(days: 1));
    }
    if (scheduled.isAfter(reference)) {
      scheduled = scheduled.subtract(const Duration(days: 7));
    }
    return scheduled;
  }
}
