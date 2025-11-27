// lib/features/character/models/domain/character_stats.dart
class CharacterStats {
  final double physicalDefenseRate;
  final double magicDefenseRate;
  final int str;
  final int intStat;
  final int vit;
  final int spi;
  final int physicalAttack;
  final int magicAttack;
  final double physicalCrit;
  final double magicCrit;
  final int independentAttack;
  final int adventureFame;
  final double attackSpeed;
  final double castSpeed;
  final int fireElement;
  final int waterElement;
  final int lightElement;
  final int darkElement;

  const CharacterStats({
    required this.physicalDefenseRate,
    required this.magicDefenseRate,
    required this.str,
    required this.intStat,
    required this.vit,
    required this.spi,
    required this.physicalAttack,
    required this.magicAttack,
    required this.physicalCrit,
    required this.magicCrit,
    required this.independentAttack,
    required this.adventureFame,
    required this.attackSpeed,
    required this.castSpeed,
    required this.fireElement,
    required this.waterElement,
    required this.lightElement,
    required this.darkElement,
  });

  /// ✅ 빈 값용 기본 생성자
  const CharacterStats.empty()
    : physicalDefenseRate = 0,
      magicDefenseRate = 0,
      str = 0,
      intStat = 0,
      vit = 0,
      spi = 0,
      physicalAttack = 0,
      magicAttack = 0,
      physicalCrit = 0,
      magicCrit = 0,
      independentAttack = 0,
      adventureFame = 0,
      attackSpeed = 0,
      castSpeed = 0,
      fireElement = 0,
      waterElement = 0,
      lightElement = 0,
      darkElement = 0;

  factory CharacterStats.fromStatusList(List<dynamic> statusList) {
    // 이름으로 찾아서 value 꺼내는 헬퍼
    num _find(String name) {
      final found = statusList.cast<Map<String, dynamic>>().firstWhere(
        (m) => m['name'] == name,
        orElse: () => const {},
      );
      return found['value'] as num? ?? 0;
    }

    return CharacterStats(
      physicalDefenseRate: _find('물리 방어율').toDouble(),
      magicDefenseRate: _find('마법 방어율').toDouble(),
      str: _find('힘').toInt(),
      intStat: _find('지능').toInt(),
      vit: _find('체력').toInt(),
      spi: _find('정신력').toInt(),
      physicalAttack: _find('물리 공격력').toInt(),
      magicAttack: _find('마법 공격력').toInt(),
      physicalCrit: _find('물리 크리티컬').toDouble(),
      magicCrit: _find('마법 크리티컬').toDouble(),
      independentAttack: _find('독립 공격력').toInt(),
      adventureFame: _find('모험가 명성').toInt(),
      attackSpeed: _find('공격 속도').toDouble(),
      castSpeed: _find('캐스팅 속도').toDouble(),
      fireElement: _find('화속성 강화').toInt(),
      waterElement: _find('수속성 강화').toInt(),
      lightElement: _find('명속성 강화').toInt(),
      darkElement: _find('암속성 강화').toInt(),
    );
  }
}
