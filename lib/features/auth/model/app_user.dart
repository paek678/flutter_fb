
class AppUser {
  final String uid;          // Firebase UID
  final String? email;       // nullable
  final String displayName;  // nickname / profile name
  final String provider;     // login provider: "google", "password", ...
  final String role;         // "user", "admin", ...

  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActionAt;
  final Set<int> favorites; // 찜한 auction item ids

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.lastActionAt,
    this.favorites = const <int>{},
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? provider,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastActionAt,
    Set<int>? favorites,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      favorites: favorites ?? this.favorites,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      final raw = json[key];
      if (raw == null) return DateTime.now();
      return DateTime.parse(raw as String);
    }

    DateTime? parseDateOrNull(String key) {
      final raw = json[key];
      if (raw == null) return null;
      return DateTime.tryParse(raw as String);
    }

    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String? ?? 'User',
      provider: json['provider'] as String? ?? 'unknown',
      role: json['role'] as String? ?? 'user',
      createdAt: parseDate('createdAt'),
      lastLoginAt: parseDateOrNull('lastLoginAt'),
      lastActionAt: parseDateOrNull('lastActionAt'),
      favorites: _parseFavorites(json['favorites']),
    );
  }

  static Set<int> _parseFavorites(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();
    }
    return const <int>{};
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'provider': provider,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'lastActionAt': lastActionAt?.toIso8601String(),
        'favorites': favorites.toList(),
      };
}
