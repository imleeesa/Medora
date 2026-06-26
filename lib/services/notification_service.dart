import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';

abstract interface class MedicineNotificationScheduler {
  Future<void> initialize();

  Future<void> rescheduleActiveMedicines(Iterable<Medicine> medicines);

  Future<void> scheduleMedicineNotifications(Medicine medicine);

  Future<void> cancelMedicineNotifications(Medicine medicine);

  Future<void> cancelAllNotifications();
}

/// Gestisce i promemoria locali delle medicine senza esporre dettagli plugin al
/// Provider o alla UI.
class NotificationService implements MedicineNotificationScheduler {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;
  Future<void>? _initialization;

  static const _channelId = 'meditrack_medicine_reminders';
  static const _channelName = 'Promemoria medicine';
  static const _channelDescription =
      'Promemoria per l assunzione delle medicine';

  bool get _supportsLocalNotifications =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> initialize() async {
    if (!_supportsLocalNotifications) return;
    await (_initialization ??= _initializePlugin());
  }

  Future<void> _initializePlugin() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    final plugin = FlutterLocalNotificationsPlugin();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    _plugin = plugin;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Le azioni rapide e il deep link allo storico saranno uno sprint futuro.
  }

  @override
  Future<void> rescheduleActiveMedicines(Iterable<Medicine> medicines) async {
    if (!await _canScheduleNotifications()) return;

    final plugin = _plugin!;
    await plugin.cancelAll();
    for (final medicine in medicines.where((medicine) => medicine.isActive)) {
      await _scheduleMedicine(plugin, medicine);
    }
  }

  @override
  Future<void> scheduleMedicineNotifications(Medicine medicine) async {
    if (!medicine.isActive || !await _canScheduleNotifications()) return;

    final plugin = _plugin!;
    await cancelMedicineNotifications(medicine);
    await _scheduleMedicine(plugin, medicine);
  }

  @override
  Future<void> cancelMedicineNotifications(Medicine medicine) async {
    if (!_supportsLocalNotifications) return;
    await initialize();

    final plugin = _plugin;
    if (plugin == null) return;
    for (final schedule in medicine.schedules) {
      for (final dayOfWeek in schedule.daysOfWeek.toSet()) {
        await plugin.cancel(
          notificationIdFor(
            medicineId: medicine.id,
            dayOfWeek: dayOfWeek,
            hour: schedule.time.hour,
            minute: schedule.time.minute,
          ),
        );
      }
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_supportsLocalNotifications) return;
    await initialize();
    await _plugin?.cancelAll();
  }

  Future<bool> _canScheduleNotifications() async {
    if (!_supportsLocalNotifications) return false;
    await initialize();

    try {
      final plugin = _plugin!;
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final iosPlugin = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      final androidGranted = await androidPlugin
          ?.requestNotificationsPermission();
      var exactAlarmGranted = await androidPlugin
          ?.canScheduleExactNotifications();
      if (exactAlarmGranted == false) {
        exactAlarmGranted = await androidPlugin?.requestExactAlarmsPermission();
      }
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? true) &&
          (exactAlarmGranted ?? true) &&
          (iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  Future<void> _scheduleMedicine(
    FlutterLocalNotificationsPlugin plugin,
    Medicine medicine,
  ) async {
    for (final schedule in medicine.schedules.where(
      (schedule) => schedule.isActive,
    )) {
      for (final dayOfWeek in schedule.daysOfWeek.toSet()) {
        if (dayOfWeek < DateTime.monday || dayOfWeek > DateTime.sunday) {
          continue;
        }

        await plugin.zonedSchedule(
          notificationIdFor(
            medicineId: medicine.id,
            dayOfWeek: dayOfWeek,
            hour: schedule.time.hour,
            minute: schedule.time.minute,
          ),
          'Promemoria medicina',
          reminderBody(medicine),
          _nextInstanceOfWeekdayAndTime(
            dayOfWeek: dayOfWeek,
            hour: schedule.time.hour,
            minute: schedule.time.minute,
          ),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              visibility: NotificationVisibility.public,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: medicine.id,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekdayAndTime({
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDateTime.weekday != dayOfWeek) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    if (!scheduledDateTime.isAfter(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 7));
    }
    return scheduledDateTime;
  }

  /// Identificativo stabile per una singola combinazione medicina-giorno-orario.
  static int notificationIdFor({
    required String medicineId,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final value = '$medicineId|$dayOfWeek|$hour|$minute';
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String reminderBody(Medicine medicine) {
    final dose = medicine.dose.trim();
    return dose.isEmpty
        ? 'E ora di prendere ${medicine.name}'
        : 'E ora di prendere ${medicine.name} - $dose';
  }
}
