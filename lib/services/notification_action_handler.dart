import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/intake_record.dart';
import 'intake_action_service.dart';
import 'notification_payload.dart';

class NotificationActionEvents {
  NotificationActionEvents._();

  static final instance = NotificationActionEvents._();
  static const _portName = 'meditrack_notification_action_events';

  final _controller = StreamController<void>.broadcast();
  ReceivePort? _receivePort;

  Stream<void> get completed {
    ensureMainIsolatePort();
    return _controller.stream;
  }

  void notifyCompleted() {
    if (_receivePort != null) {
      _emit();
      return;
    }

    final mainPort = IsolateNameServer.lookupPortByName(_portName);
    if (mainPort != null) {
      mainPort.send(null);
      return;
    }

    _emit();
  }

  void ensureMainIsolatePort() {
    if (_receivePort != null) return;

    IsolateNameServer.removePortNameMapping(_portName);
    _receivePort = ReceivePort()
      ..listen((_) {
        _emit();
      });
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);
  }

  void disposeMainIsolatePort() {
    if (_receivePort == null) return;

    IsolateNameServer.removePortNameMapping(_portName);
    _receivePort?.close();
    _receivePort = null;
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}

class NotificationActionHandler {
  NotificationActionHandler({IntakeActionService? intakeActionService})
    : _intakeActionService = intakeActionService ?? IntakeActionService();

  final IntakeActionService _intakeActionService;

  Future<bool> handleResponse(
    NotificationResponse response, {
    DateTime? referenceDate,
  }) {
    return handle(
      actionId: response.actionId,
      payload: response.payload,
      referenceDate: referenceDate,
    );
  }

  Future<bool> handle({
    required String? actionId,
    required String? payload,
    DateTime? referenceDate,
  }) async {
    final status = statusForActionId(actionId);
    final decodedPayload = MedicineNotificationPayload.tryDecode(payload);
    if (status == null || decodedPayload == null) return false;

    try {
      final scheduledDateTime = decodedPayload.scheduledDateTime(
        referenceDate: referenceDate,
      );
      if (status == IntakeStatus.taken) {
        await _intakeActionService.markTaken(
          medicineId: decodedPayload.medicineId,
          scheduledDateTime: scheduledDateTime,
        );
      } else {
        await _intakeActionService.markSkipped(
          medicineId: decodedPayload.medicineId,
          scheduledDateTime: scheduledDateTime,
        );
      }
      NotificationActionEvents.instance.notifyCompleted();
      return true;
    } catch (_) {
      return false;
    }
  }

  static IntakeStatus? statusForActionId(String? actionId) {
    return switch (actionId) {
      NotificationActionIds.taken => IntakeStatus.taken,
      NotificationActionIds.skipped => IntakeStatus.skipped,
      _ => null,
    };
  }
}

class NotificationActionIds {
  static const taken = 'meditrack_action_taken';
  static const skipped = 'meditrack_action_skipped';
}
