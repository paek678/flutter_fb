class CharacterDetailStats {
  final double attackIncreaseFlat;
  final double attackIncreasePercent;
  final int buffPower;
  final double buffPowerPercent;
  final double finalDamagePercent;
  final double elementStackPercent;
  final double cooldownReductionPercent;
  final double cooldownRecoveryPercent;
  final double totalCooldownReductionPercent;

  const CharacterDetailStats({
    required this.attackIncreaseFlat,
    required this.attackIncreasePercent,
    required this.buffPower,
    required this.buffPowerPercent,
    required this.finalDamagePercent,
    required this.elementStackPercent,
    required this.cooldownReductionPercent,
    required this.cooldownRecoveryPercent,
    required this.totalCooldownReductionPercent,
  });

  /// 기본값 채운 빈 스탯
  const CharacterDetailStats.empty()
      : attackIncreaseFlat = 0,
        attackIncreasePercent = 0,
        buffPower = 0,
        buffPowerPercent = 0,
        finalDamagePercent = 0,
        elementStackPercent = 0,
        cooldownReductionPercent = 0,
        cooldownRecoveryPercent = 0,
        totalCooldownReductionPercent = 0;

  factory CharacterDetailStats.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int _i(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final List<Map<String, dynamic>> statusList =
        (json['status'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [];

    num _find(String name) {
      final found = statusList.firstWhere(
        (m) => m['name'] == name,
        orElse: () => const {},
      );
      return found['value'] as num? ?? 0;
    }

    double _maxOf(List<String> names) {
      double maxVal = 0;
      for (final n in names) {
        final v = _find(n).toDouble();
        if (v > maxVal) maxVal = v;
      }
      return maxVal;
    }

    final double elementDamageMax = _maxOf([
      '화속성 피해',
      '수속성 피해',
      '명속성 피해',
      '암속성 피해',
    ]);

    final double elementEnhanceMax = _maxOf([
      '화속성 강화',
      '수속성 강화',
      '명속성 강화',
      '암속성 강화',
    ]);

    return CharacterDetailStats(
      // 필드가 직접 있으면 우선 사용, 없으면 status 리스트 이름 기반으로 보충
      attackIncreaseFlat:
          _d(json['attackIncreaseFlat'] ?? _find('공격력 증가')),
      attackIncreasePercent:
          _d(json['attackIncreasePercent'] ?? _find('공격력 증폭')),
      buffPower: _i(json['buffPower'] ?? _find('버프력')),
      buffPowerPercent:
          _d(json['buffPowerPercent'] ?? _find('버프력 증폭')),
      finalDamagePercent:
          _d(json['finalDamagePercent'] ?? _find('최종 데미지 증가')),
      elementStackPercent: _d(
        json['elementStackPercent'] ??
            (elementDamageMax != 0 ? elementDamageMax : elementEnhanceMax),
      ),
      cooldownReductionPercent:
          _d(json['cooldownReductionPercent'] ?? _find('쿨타임 감소')),
      cooldownRecoveryPercent:
          _d(json['cooldownRecoveryPercent'] ?? _find('쿨타임 회복속도')),
      totalCooldownReductionPercent: _d(
        json['totalCooldownReductionPercent'] ??
            _find('최종 쿨타임 감소율'),
      ),
    );
  }
}
