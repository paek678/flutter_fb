import 'package:meta/meta.dart';

@immutable
class RankingRow {
  /// 랭킹 문서 ID (필요 없으면 그냥 '' 넣어도 됨)
  final String id;

  /// 상세 조회에 사용할 캐릭터 ID
  final String characterId;

  /// 순위
  final int rank;

  /// 캐릭터 이름 (위젯에서 row.name)
  final String name;

  /// 명성 (row.fame)
  final int fame; // 명성이 없을 수 있으면 int? 로 바꾸고 UI도 처리해줘야 함

  /// 직업명 (row.job)
  final String job;

  const RankingRow({
    required this.id,
    required this.characterId,
    required this.rank,
    required this.name,
    required this.fame,
    required this.job,
  });

  RankingRow copyWith({
    String? id,
    String? characterId,
    int? rank,
    String? name,
    int? fame,
    String? job,
  }) {
    return RankingRow(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      rank: rank ?? this.rank,
      name: name ?? this.name,
      fame: fame ?? this.fame,
      job: job ?? this.job,
    );
  }

  factory RankingRow.fromJson(Map<String, dynamic> json, {String? id}) {
    return RankingRow(
      id: id ?? (json['id'] as String? ?? ''),
      characterId: json['characterId'] as String,
      rank: (json['rank'] as num).toInt(),
      name: json['name'] as String,
      fame: (json['fame'] as num).toInt(),
      job: json['job'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'rank': rank,
      'name': name,
      'fame': fame,
      'job': job,
    };
  }
}
