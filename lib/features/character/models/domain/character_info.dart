// lib/features/character/models/domain/character_info.dart
import 'character.dart';
import 'equipment_item.dart';
import 'avatar_item.dart';
import 'buff_item.dart';
import 'character_stats.dart';
import 'character_detail_stats.dart';

import '../ui/detail_stat.dart';

class CharacterInfo {
  /// 상단 프로필
  final Character summary;

  /// 기본 스탯 탭 (도메인 숫자)
  final CharacterStats stats;

  /// 세부 스탯 탭 메인
  final CharacterDetailStats detailStats;

  /// 세부 스탯 탭 추가 라인
  final List<DetailStat> extraDetailStats;

  /// 장비
  final List<EquipmentItem> equipments;

  /// 아바타 / 크리쳐
  final List<AvatarItem> avatars;

  /// 버프 강화
  final List<BuffItem> buffItems;

  const CharacterInfo({
    required this.summary,
    required this.stats,
    required this.detailStats,
    required this.extraDetailStats,
    required this.equipments,
    required this.avatars,
    required this.buffItems,
  });

  factory CharacterInfo.fromJson(Map<String, dynamic> json) {
    List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) mapper) {
      if (v == null) return const [];
      return (v as List<dynamic>)
          .map((e) => mapper(e as Map<String, dynamic>))
          .toList();
    }

    return CharacterInfo(
      summary: Character.fromJson(
        (json['summary'] as Map<String, dynamic>? ?? const {}),
      ),
      stats: CharacterStats.fromStatusList(
        (json['stats'] as List<dynamic>? ?? const []),
      ),
      detailStats: CharacterDetailStats.fromJson(
        (json['detailStats'] as Map<String, dynamic>? ?? const {}),
      ),
      extraDetailStats: _list(json['extraDetailStats'], DetailStat.fromJson),
      equipments: _list(json['equipments'], EquipmentItem.fromJson),
      avatars: _list(json['avatars'], AvatarItem.fromJson),
      buffItems: _list(json['buffItems'], BuffItem.fromJson),
    );
  }
}
