import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_payload.dart';

class NotificationNavigationRequest {
  final String medicineId;

  const NotificationNavigationRequest({required this.medicineId});
}

class NotificationNavigationEvents {
  NotificationNavigationEvents._();

  static final instance = NotificationNavigationEvents._();

  final _controller =
      StreamController<NotificationNavigationRequest>.broadcast();
  NotificationNavigationRequest? _pendingRequest;

  Stream<NotificationNavigationRequest> get requests => _controller.stream;

  NotificationNavigationRequest? takePendingRequest() {
    final request = _pendingRequest;
    _pendingRequest = null;
    return request;
  }

  void clearPendingRequest(NotificationNavigationRequest request) {
    if (_pendingRequest?.medicineId == request.medicineId) {
      _pendingRequest = null;
    }
  }

  bool requestFromResponse(NotificationResponse response) {
    if (response.notificationResponseType !=
        NotificationResponseType.selectedNotification) {
      return false;
    }
    return requestFromPayload(response.payload);
  }

  bool requestFromPayload(String? payload) {
    final medicineId = MedicineNotificationPayload.tryDecodeMedicineId(payload);
    if (medicineId == null) return false;

    requestNavigation(NotificationNavigationRequest(medicineId: medicineId));
    return true;
  }

  void requestNavigation(NotificationNavigationRequest request) {
    _pendingRequest = request;
    if (!_controller.isClosed) {
      _controller.add(request);
    }
  }
}
