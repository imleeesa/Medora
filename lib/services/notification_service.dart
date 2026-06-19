import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servizio per gestire le notifiche locali.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _plugin;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    await _requestAndroidPermissions();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Il payload contiene il nome della medicina. Il routing profondo potra'
    // essere aggiunto quando saranno presenti rotte nominate.
  }

  Future<void> _requestAndroidPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMedicineNotification({
    required int id,
    required String medicineName,
    required String dose,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
  }) async {
    for (final day in daysOfWeek) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (!scheduledDate.isAfter(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _plugin.zonedSchedule(
        _notificationId(id, day),
        '\u00C8 ora di prendere $medicineName',
        'Dose: $dose',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meditrack_medicine_reminders',
            'Promemoria medicine',
            channelDescription: 'Notifiche per l assunzione delle medicine',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            ongoing: true,
            autoCancel: false,
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
        payload: medicineName,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelMedicineNotifications(int medicineId) async {
    for (var timeIndex = 0; timeIndex < 12; timeIndex++) {
      for (var day = 1; day <= 7; day++) {
        await _plugin.cancel(_notificationId(medicineId + timeIndex, day));
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meditrack_medicine_reminders',
        'Promemoria medicine',
        channelDescription: 'Notifiche per l assunzione delle medicine',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        ongoing: true,
        autoCancel: false,
      ),
    );

    await _plugin.show(0, title, body, details);
  }

  int _notificationId(int baseId, int day) => (baseId.abs() % 100000) + day;
}
