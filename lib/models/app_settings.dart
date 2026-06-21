class AppSettings {
  final String id;
  final String profileId;
  final String themeMode;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    required this.profileId,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDarkMode => themeMode == 'dark';

  AppSettings copyWith({
    String? id,
    String? profileId,
    String? themeMode,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
