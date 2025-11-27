// lib/features/character/models/domain/character.dart
import 'package:meta/meta.dart';

@immutable
class Character {
  final String id; // 캐릭터 고유 ID
  final String name; // 이름
  final String server; // 서버명
  final String job; // 직업명
  final int level; // 레벨
  final int fame; // 명성 (숫자로 보관)
  final String imagePath; // 프로필 이미지 URL (없으면 빈 문자열)

  const Character({
    required this.id,
    required this.name,
    required this.server,
    required this.job,
    required this.level,
    required this.fame,
    required this.imagePath,
  });

  Character copyWith({
    String? id,
    String? name,
    String? server,
    String? job,
    int? level,
    int? fame,
    String? imagePath,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      server: server ?? this.server,
      job: job ?? this.job,
      level: level ?? this.level,
      fame: fame ?? this.fame,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory Character.fromJson(Map<String, dynamic> json, {String? id}) {
    return Character(
      id: id ?? (json['id'] as String? ?? ''),

      name: json['name'] as String? ?? '',

      // Firestore에는 server가 아니라 serverId만 있음
      // 일단 내부에는 serverId 그대로 저장해 두고,
      // 한글 서버명은 나중에 맵핑해서 쓰는 게 깔끔함
      server: json['server'] as String? ?? json['serverId'] as String? ?? '',

      // Firestore에는 job이 아니라 jobName 사용
      job: json['job'] as String? ?? json['jobName'] as String? ?? '',

      level: (json['level'] as num?)?.toInt() ?? 0,
      fame: (json['fame'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'job': job,
      'level': level,
      'fame': fame,
      'imagePath': imagePath,
    };
  }
}
