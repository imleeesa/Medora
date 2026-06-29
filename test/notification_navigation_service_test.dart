import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/services/notification_action_handler.dart';
import 'package:meditrack/services/notification_navigation_service.dart';
import 'package:meditrack/services/notification_service.dart';

void main() {
  tearDown(() {
    NotificationNavigationEvents.instance.takePendingRequest();
  });

  test('valid notification payload creates a navigation request', () {
    final payload = NotificationService.payloadFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 0,
    );

    final handled = NotificationNavigationEvents.instance.requestFromPayload(
      payload,
    );
    final request = NotificationNavigationEvents.instance.takePendingRequest();

    expect(handled, isTrue);
    expect(request?.medicineId, 'medicine-1');
  });

  test('invalid notification payload is ignored', () {
    final handled = NotificationNavigationEvents.instance.requestFromPayload(
      'not-json',
    );

    expect(handled, isFalse);
    expect(NotificationNavigationEvents.instance.takePendingRequest(), isNull);
  });

  test('normal tap and notification actions are distinguished', () {
    final payload = NotificationService.payloadFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 0,
    );

    final normalTap = NotificationNavigationEvents.instance.requestFromResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      ),
    );
    final request = NotificationNavigationEvents.instance.takePendingRequest();
    final actionTap = NotificationNavigationEvents.instance.requestFromResponse(
      NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: NotificationActionIds.taken,
        payload: payload,
      ),
    );

    expect(normalTap, isTrue);
    expect(request?.medicineId, 'medicine-1');
    expect(actionTap, isFalse);
    expect(NotificationNavigationEvents.instance.takePendingRequest(), isNull);
  });
}
