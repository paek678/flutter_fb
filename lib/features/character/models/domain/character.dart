import 'avatar_item.dart';
import 'buff_item.dart';
import 'character_stats.dart';
import 'equipment_item.dart';
import 'ranking_row.dart';
import 'character_detail_stats.dart';

class Character {
  final String id;
  final String name;
  final String server;
  final String job;
  final int level;
  final String fame;
  final String imagePath;

  final CharacterStats? stats;
  final CharacterDetailStats? detailStats;
  final List<EquipmentItem> equipments;
  final List<AvatarItem> avatars;
  final List<BuffItem> buffItems;
  final List<RankingRow> rankingHistory; // 필요하면 추가

  const Character({
    required this.id,
    required this.name,
    required this.server,
    required this.job,
    required this.level,
    required this.fame,
    required this.imagePath,
    required this.stats,
    required this.detailStats,
    required this.equipments,
    required this.avatars,
    required this.buffItems,
    required this.rankingHistory,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    final serverCode = json['serverCode'] as String;
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      job: json['job'] as String,
      level: json['level'] as int,
      server: _mapServerCodeToLabel(serverCode), // 👈 여기서 한 번 변환
      imagePath: json['imageUrl'] as String,
      fame: json['fame'].toString(),
       stats: null, detailStats: null,
        equipments: [],
         avatars: [],
          buffItems: [],
           rankingHistory: [],
    );
  }
}

String _mapServerCodeToLabel(String code) {
  switch (code) {
    case 'kain':
      return '카인';
    case 'siroco':
      return '시로코';
    // ...
    default:
      return code;
  }
}
