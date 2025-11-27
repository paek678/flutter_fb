import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_container_divided.dart';

// ✅ 도메인 스탯 모델만 사용
import '../../models/domain/character_stats.dart';

class StatTab extends StatelessWidget {
  final CharacterStats stats; // 🔥 여기!

  const StatTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // 화면에 찍을 때 쓸 name/value 문자열 리스트
    final rows = <Map<String, String>>[
      {
        'name': '물리 방어율',
        'value': '${stats.physicalDefenseRate.toStringAsFixed(1)}%',
      },
      {
        'name': '마법 방어율',
        'value': '${stats.magicDefenseRate.toStringAsFixed(1)}%',
      },
      {'name': '힘 / 지능', 'value': '${stats.str} / ${stats.intStat}'},
      {'name': '체력 / 정신력', 'value': '${stats.vit} / ${stats.spi}'},
      {
        'name': '물리 공격력 / 마법 공격력',
        'value': '${stats.physicalAttack} / ${stats.magicAttack}',
      },
      {'name': '독립 공격력', 'value': stats.independentAttack.toString()},
      {
        'name': '공격 속도 / 캐스팅 속도',
        'value':
            '${stats.attackSpeed.toStringAsFixed(1)}% / ${stats.castSpeed.toStringAsFixed(1)}%',
      },
      {
        'name': '크리티컬 (물리 / 마법)',
        'value':
            '${stats.physicalCrit.toStringAsFixed(1)}% / ${stats.magicCrit.toStringAsFixed(1)}%',
      },
      {
        'name': '속성 강화 (화/수/명/암)',
        'value':
            '${stats.fireElement} / ${stats.waterElement} / ${stats.lightElement} / ${stats.darkElement}',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: CustomContainerDivided(
        header: const Text(
          '기본 스탯',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primaryText,
          ),
        ),
        children: rows.map((stat) {
          return Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stat['name']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  stat['value']!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
