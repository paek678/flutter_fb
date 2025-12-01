import 'package:meta/meta.dart';

@immutable
class RankingRow {
  final String id;
  final String characterId;
  final String serverId;
  final int rank;
  final String name;
  final int fame;
  final String job;
  final String imagePath;

  const RankingRow({
    required this.id,
    required this.characterId,
    required this.serverId,
    required this.rank,
    required this.name,
    required this.fame,
    required this.job,
    required this.imagePath,
  });

  RankingRow copyWith({
    String? id,
    String? characterId,
    String? serverId,
    int? rank,
    String? name,
    int? fame,
    String? job,
    String? imagePath,
  }) {
    return RankingRow(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      serverId: serverId ?? this.serverId,
      rank: rank ?? this.rank,
      name: name ?? this.name,
      fame: fame ?? this.fame,
      job: job ?? this.job,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory RankingRow.fromJson(Map<String, dynamic> json, {String? id}) {
    return RankingRow(
      id: id ?? (json['id'] as String? ?? ''),
      characterId: json['characterId'] as String? ?? '',
      serverId: json['serverId'] as String? ?? json['server'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      fame: (json['fame'] as num?)?.toInt() ?? 0,
      job: json['job'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'serverId': serverId,
      'rank': rank,
      'name': name,
      'fame': fame,
      'job': job,
      'imagePath': imagePath,
    };
  }
}
