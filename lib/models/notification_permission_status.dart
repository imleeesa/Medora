class NotificationPermissionStatus {
  final bool localNotificationsSupported;
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
  final bool exactAlarmsCanBeChecked;

  const NotificationPermissionStatus({
    required this.localNotificationsSupported,
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    required this.exactAlarmsCanBeChecked,
  });

  const NotificationPermissionStatus.unknown()
    : localNotificationsSupported = true,
      notificationsAllowed = true,
      exactAlarmsAllowed = true,
      exactAlarmsCanBeChecked = false;

  const NotificationPermissionStatus.unsupported()
    : localNotificationsSupported = false,
      notificationsAllowed = false,
      exactAlarmsAllowed = false,
      exactAlarmsCanBeChecked = false;

  bool get remindersCanBeScheduled =>
      localNotificationsSupported && notificationsAllowed && exactAlarmsAllowed;

  NotificationPermissionStatus copyWith({
    bool? localNotificationsSupported,
    bool? notificationsAllowed,
    bool? exactAlarmsAllowed,
    bool? exactAlarmsCanBeChecked,
  }) {
    return NotificationPermissionStatus(
      localNotificationsSupported:
          localNotificationsSupported ?? this.localNotificationsSupported,
      notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
      exactAlarmsCanBeChecked:
          exactAlarmsCanBeChecked ?? this.exactAlarmsCanBeChecked,
    );
  }
}
