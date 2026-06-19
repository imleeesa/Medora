/// Modello per il profilo utente
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.isDarkMode = false,
    this.language = 'it',
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'isDarkMode': isDarkMode ? 1 : 0,
    'language': language,
    'notificationsEnabled': notificationsEnabled ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Crea da JSON del database
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    photoUrl: json['photoUrl'],
    isDarkMode: json['isDarkMode'] == 1,
    language: json['language'] ?? 'it',
    notificationsEnabled: json['notificationsEnabled'] == 1,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  /// Copia con modifiche
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    language: language ?? this.language,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => 'UserProfile(id: $id, name: $name)';
}
