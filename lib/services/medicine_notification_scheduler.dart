import '../models/medicine.dart';
import '../models/notification_permission_status.dart';

abstract interface class MedicineNotificationScheduler {
  Future<void> initialize();

  Future<NotificationPermissionStatus> getPermissionStatus();

  Future<NotificationPermissionStatus> requestNotificationPermission();

  Future<NotificationPermissionStatus> requestExactAlarmPermission();

  Future<void> rescheduleActiveMedicines(Iterable<Medicine> medicines);

  Future<void> scheduleMedicineNotifications(Medicine medicine);

  Future<void> cancelMedicineNotifications(Medicine medicine);

  Future<void> showLowStockNotification(Medicine medicine);

  Future<void> cancelAllNotifications();
}
