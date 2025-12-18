import 'package:flutter/foundation.dart';

/// 경매 아이템 등급
enum RarityCode { legendary, unique, rare }

RarityCode rarityCodeFrom(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('legendary') || lower.contains('레전더리')) {
    return RarityCode.legendary;
  }
  if (lower.contains('unique') || lower.contains('유니크')) {
    return RarityCode.unique;
  }
  return RarityCode.rare;
}

/// 시세 범위(일 단위)
enum PriceRange { d7, d14, d30, d90, d365 }

extension PriceRangeX on PriceRange {
  String get key => switch (this) {
        PriceRange.d7 => 'd7',
        PriceRange.d14 => 'd14',
        PriceRange.d30 => 'd30',
        PriceRange.d90 => 'd90',
        PriceRange.d365 => 'd365',
      };

  /// UI 노출용 라벨
  String get label => switch (this) {
        PriceRange.d7 => '7일',
        PriceRange.d14 => '14일',
        PriceRange.d30 => '30일',
        PriceRange.d90 => '90일',
        PriceRange.d365 => '1년',
      };
}

@immutable
class AttackStats {
  final int physical;
  final int magical;
  final int independent;
  const AttackStats({
    required this.physical,
    required this.magical,
    required this.independent,
  });
}

@immutable
class AuctionItem {
  final String name;
  final String rarity; // 예: 레전더리, 유니크, 레어
  final RarityCode rarityCode;
  final String type; // 예: 무기
  final String subType; // 예: 창, 소드
  final int levelLimit;
  final AttackStats attack;
  final int intelligence;
  final int combatPower;
  final List<String> options;
  final double? weightKg; // null 허용
  final String? durability; // 예: 45/45
  final String imagePath; // Image.asset() 경로

  /// 시세 구간별 시리즈 데이터(뒤가 최신)
  final Map<PriceRange, List<double>> history;

  const AuctionItem({
    required this.name,
    required this.rarity,
    required this.rarityCode,
    required this.type,
    required this.subType,
    required this.levelLimit,
    required this.attack,
    required this.intelligence,
    required this.combatPower,
    required this.options,
    required this.imagePath,
    this.weightKg,
    this.durability,
    this.history = const {},
  });
}

/// 정적 시세 데이터 (Firestore 미연결 시 샘플로 사용)
const List<AuctionItem> kAuctionItems = [
  AuctionItem(
    name: '검은별 창',
    rarity: '레전더리',
    rarityCode: RarityCode.legendary,
    type: '무기',
    subType: '창',
    levelLimit: 100,
    attack: AttackStats(physical: 1113, magical: 1348, independent: 719),
    intelligence: 78,
    combatPower: 920,
    options: [
      '치명타 피해 2% 증가',
      '캐스팅 속도 +2%',
      '마법 크리티컬 히트 +2%',
      '모든 공격력 30% 증가',
      '스킬 공격력 52% 증가',
    ],
    weightKg: 3.1,
    durability: '45/45',
    imagePath: 'assets/images/items/item_01.png',
    history: {
      PriceRange.d7: [8120, 8200, 8250, 8230, 8300, 8380, 8450],
      PriceRange.d14: [
        7900,
        7980,
        8050,
        8120,
        8200,
        8250,
        8230,
        8300,
        8380,
        8450,
        8430,
        8460,
        8520,
        8580
      ],
      PriceRange.d30: [
        7600,
        7650,
        7700,
        7780,
        7800,
        7880,
        7920,
        7990,
        8050,
        8120,
        8200,
        8250,
        8230,
        8300,
        8380,
        8450,
        8430,
        8460,
        8520,
        8580,
        8600,
        8650,
        8700,
        8720,
        8750,
        8780,
        8800,
        8830,
        8850,
        8880
      ],
      PriceRange.d90: [8250],
      PriceRange.d365: [7900],
    },
  ),
  AuctionItem(
    name: '리컨스트럭티드 소드',
    rarity: '유니크',
    rarityCode: RarityCode.unique,
    type: '무기',
    subType: '소드',
    levelLimit: 90,
    attack: AttackStats(physical: 945, magical: 1144, independent: 595),
    intelligence: 67,
    combatPower: 672,
    options: [
      '캐스팅 속도 +2%',
      '물리 크리티컬 히트 +10%',
      '마법 크리티컬 히트 +12%',
      '모든 직업 1~50 레벨 모든 스킬 Lv +1 (패시브 제외)',
    ],
    weightKg: 3.1,
    durability: '45/45',
    imagePath: 'assets/images/items/item_02.png',
    history: {},
  ),
  AuctionItem(
    name: '사파이어 스태프',
    rarity: '레어',
    rarityCode: RarityCode.rare,
    type: '무기',
    subType: '스태프',
    levelLimit: 90,
    attack: AttackStats(physical: 882, magical: 1068, independent: 452),
    intelligence: 63,
    combatPower: 640,
    options: [
      '캐스팅 속도 +2%',
      '마법 크리티컬 히트 +2%',
    ],
    weightKg: null,
    durability: null,
    imagePath: 'assets/images/items/item_03.png',
    history: {
      PriceRange.d7: [4200, 4220, 4230, 4250, 4270, 4280, 4300],
      PriceRange.d14: [
        4100,
        4120,
        4140,
        4160,
        4180,
        4200,
        4220,
        4230,
        4250,
        4270,
        4280,
        4300,
        4310,
        4320
      ],
      PriceRange.d30: [
        3950,
        3980,
        4000,
        4020,
        4040,
        4050,
        4070,
        4090,
        4100,
        4120,
        4140,
        4160,
        4180,
        4200,
        4220,
        4230,
        4250,
        4270,
        4280,
        4300,
        4310,
        4320,
        4330,
        4340,
        4350,
        4360,
        4370,
        4380,
        4390,
        4400
      ],
      PriceRange.d90: [4180],
      PriceRange.d365: [4370],
    },
  ),
  AuctionItem(
    name: '진혼의 검',
    rarity: '레전더리',
    rarityCode: RarityCode.legendary,
    type: '무기',
    subType: '소드',
    levelLimit: 85,
    attack: AttackStats(physical: 952, magical: 1152, independent: 607),
    intelligence: 101,
    combatPower: 736,
    options: [
      '이동속도 +1.5%',
      '캐스팅 속도 +4%',
      '물리 크리티컬 히트 +4%',
      '마법 크리티컬 히트 +6%',
      '공격속도 +1.5%',
      '공격 시 11% 추가 데미지',
    ],
    weightKg: 3.1,
    durability: '45/45',
    imagePath: 'assets/images/items/item_04.png',
    history: {
      PriceRange.d7: [7300, 7320, 7340, 7330, 7360, 7390, 7420],
      PriceRange.d14: [
        7150,
        7180,
        7200,
        7230,
        7260,
        7290,
        7300,
        7320,
        7340,
        7330,
        7360,
        7390,
        7420,
        7440
      ],
      PriceRange.d30: [
        6900,
        6930,
        6950,
        6980,
        7000,
        7030,
        7060,
        7090,
        7120,
        7150,
        7180,
        7200,
        7230,
        7260,
        7290,
        7300,
        7320,
        7340,
        7330,
        7360,
        7390,
        7420,
        7440,
        7450,
        7470,
        7490,
        7500,
        7520,
        7530,
        7550
      ],
      PriceRange.d90: [7290],
      PriceRange.d365: [7520],
    },
  ),
];

/// 전체 시리즈를 복사하여 반환 (불변 리스트 보호용)
List<double> fullSeriesOf(AuctionItem item, PriceRange range) {
  return List<double>.from(item.history[range] ?? const <double>[]);
}

extension AttackStatsJsonX on AttackStats {
  Map<String, dynamic> toJson() {
    return {
      'physical': physical,
      'magical': magical,
      'independent': independent,
    };
  }

  static AttackStats fromJson(Map<String, dynamic> json) {
    return AttackStats(
      physical: json['physical'] as int? ?? 0,
      magical: json['magical'] as int? ?? 0,
      independent: json['independent'] as int? ?? 0,
    );
  }
}

extension AuctionItemJsonX on AuctionItem {
  Map<String, dynamic> toJson() {
    final Map<String, List<double>> historyJson = {};
    for (final entry in history.entries) {
      historyJson[entry.key.key] = entry.value;
    }

    return {
      'name': name,
      'rarity': rarity,
      'rarityCode': rarityCode.name, // 'legendary' / 'unique' / 'rare'
      'type': type,
      'subType': subType,
      'levelLimit': levelLimit,
      'attack': attack.toJson(),
      'intelligence': intelligence,
      'combatPower': combatPower,
      'options': options,
      'weightKg': weightKg,
      'durability': durability,
      'imagePath': imagePath,
      'history': historyJson,
    };
  }

  static AuctionItem fromJson(Map<String, dynamic> json) {
    final String rarityStr = json['rarity'] as String? ?? '';
    final String rarityCodeStr = json['rarityCode'] as String? ?? 'rare';

    final rarityCode = switch (rarityCodeStr) {
      'legendary' => RarityCode.legendary,
      'unique' => RarityCode.unique,
      _ => rarityCodeFrom(rarityStr),
    };

    final attackJson = json['attack'] as Map<String, dynamic>? ?? {};
    final attack = AttackStatsJsonX.fromJson(attackJson);

    final List<String> options = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final Map<PriceRange, List<double>> history = {};
    final historyRaw = json['history'] as Map<String, dynamic>?;

    if (historyRaw != null) {
      historyRaw.forEach((key, value) {
        final List<double> list = (value as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const <double>[];

        switch (key) {
          case 'd7':
            history[PriceRange.d7] = list;
            break;
          case 'd14':
            history[PriceRange.d14] = list;
            break;
          case 'd30':
            history[PriceRange.d30] = list;
            break;
          case 'd90':
            history[PriceRange.d90] = list;
            break;
          case 'd365':
            history[PriceRange.d365] = list;
            break;
        }
      });
    }

    return AuctionItem(
      name: json['name'] as String? ?? '',
      rarity: rarityStr,
      rarityCode: rarityCode,
      type: json['type'] as String? ?? '',
      subType: json['subType'] as String? ?? '',
      levelLimit: json['levelLimit'] as int? ?? 0,
      attack: attack,
      intelligence: json['intelligence'] as int? ?? 0,
      combatPower: json['combatPower'] as int? ?? 0,
      options: options,
      imagePath: json['imagePath'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durability: json['durability'] as String?,
      history: history,
    );
  }
}
