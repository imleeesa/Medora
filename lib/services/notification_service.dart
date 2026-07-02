import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';
import '../models/notification_permission_status.dart';
export 'medicine_notification_scheduler.dart';
import 'medicine_notification_scheduler.dart';
import 'notification_action_handler.dart';
import 'notification_navigation_service.dart';
import 'notification_payload.dart';

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
  static const _darwinReminderCategoryId = 'meditrack_medicine_reminder';

  bool get _supportsLocalNotifications =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> initialize() async {
    if (!_supportsLocalNotifications) return;
    await (_initialization ??= _initializePlugin());
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (!_supportsLocalNotifications) {
      return const NotificationPermissionStatus.unsupported();
    }
    await initialize();

    try {
      final plugin = _plugin!;
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final notificationsAllowed =
            await androidPlugin.areNotificationsEnabled() ?? true;
        final exactAlarmsAllowed =
            await androidPlugin.canScheduleExactNotifications() ?? true;
        return NotificationPermissionStatus(
          localNotificationsSupported: true,
          notificationsAllowed: notificationsAllowed,
          exactAlarmsAllowed: exactAlarmsAllowed,
          exactAlarmsCanBeChecked: true,
        );
      }

      return const NotificationPermissionStatus(
        localNotificationsSupported: true,
        notificationsAllowed: true,
        exactAlarmsAllowed: true,
        exactAlarmsCanBeChecked: false,
      );
    } catch (_) {
      return const NotificationPermissionStatus.unknown();
    }
  }

  @override
  Future<NotificationPermissionStatus> requestNotificationPermission() async {
    if (!_supportsLocalNotifications) {
      return const NotificationPermissionStatus.unsupported();
    }
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
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = await getPermissionStatus();
      return status.copyWith(
        notificationsAllowed:
            androidGranted ?? iosGranted ?? status.notificationsAllowed,
      );
    } catch (_) {
      return await getPermissionStatus();
    }
  }

  @override
  Future<NotificationPermissionStatus> requestExactAlarmPermission() async {
    if (!_supportsLocalNotifications) {
      return const NotificationPermissionStatus.unsupported();
    }
    await initialize();

    try {
      final plugin = _plugin!;
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final exactAlarmGranted = await androidPlugin
          ?.requestExactAlarmsPermission();
      final status = await getPermissionStatus();
      return status.copyWith(
        exactAlarmsAllowed: exactAlarmGranted ?? status.exactAlarmsAllowed,
        exactAlarmsCanBeChecked:
            androidPlugin != null || status.exactAlarmsCanBeChecked,
      );
    } catch (_) {
      return await getPermissionStatus();
    }
  }

  Future<void> _initializePlugin() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    final plugin = FlutterLocalNotificationsPlugin();
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            _darwinReminderCategoryId,
            actions: [
              DarwinNotificationAction.plain(
                NotificationActionIds.taken,
                'Assunta',
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.skipped,
                'Saltata',
              ),
            ],
          ),
        ],
      ),
    );

    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          meditrackNotificationTapBackground,
    );
    _plugin = plugin;
    await _handleLaunchNotification(plugin);
  }

  void _onNotificationTapped(NotificationResponse response) async {
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      await NotificationActionHandler().handleResponse(response);
      return;
    }
    NotificationNavigationEvents.instance.requestFromResponse(response);
  }

  Future<void> _handleLaunchNotification(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final details = await plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp == true && response != null) {
      NotificationNavigationEvents.instance.requestFromResponse(response);
    }
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
    await plugin.cancel(lowStockNotificationIdFor(medicine.id));
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_supportsLocalNotifications) return;
    await initialize();
    await _plugin?.cancelAll();
  }

  @override
  Future<void> showLowStockNotification(Medicine medicine) async {
    if (!medicine.isActive ||
        medicine.stockWarningThreshold <= 0 ||
        medicine.stockQuantity > medicine.stockWarningThreshold ||
        !await _canShowNotifications()) {
      return;
    }

    final plugin = _plugin!;
    await plugin.show(
      lowStockNotificationIdFor(medicine.id),
      'Scorta bassa',
      '${medicine.name} e sotto la soglia minima. Scorta attuale: ${Medicine.formatQuantity(medicine.stockQuantity)}',
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
      payload: MedicineNotificationPayload.encodeMedicineOnly(medicine.id),
    );
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

      final permissionStatus = await requestNotificationPermission();
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

      return permissionStatus.notificationsAllowed &&
          (exactAlarmGranted ?? true) &&
          (iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canShowNotifications() async {
    if (!_supportsLocalNotifications) return false;
    await initialize();

    try {
      final permissionStatus = await requestNotificationPermission();
      return permissionStatus.notificationsAllowed;
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
              actions: [
                AndroidNotificationAction(
                  NotificationActionIds.taken,
                  'Assunta',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  NotificationActionIds.skipped,
                  'Saltata',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: _darwinReminderCategoryId,
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payloadFor(
            medicineId: medicine.id,
            dayOfWeek: dayOfWeek,
            hour: schedule.time.hour,
            minute: schedule.time.minute,
          ),
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

  static int lowStockNotificationIdFor(String medicineId) {
    final value = 'low_stock|$medicineId';
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

  static String payloadFor({
    required String medicineId,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    return MedicineNotificationPayload(
      medicineId: medicineId,
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
    ).encode();
  }
}

@pragma('vm:entry-point')
void meditrackNotificationTapBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  if (response.notificationResponseType ==
      NotificationResponseType.selectedNotificationAction) {
    await NotificationActionHandler().handleResponse(response);
    return;
  }
  NotificationNavigationEvents.instance.requestFromResponse(response);
}
