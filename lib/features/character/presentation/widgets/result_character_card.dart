// lib/features/character/presentation/widgets/result_character_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/domain/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = character;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.medium,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ✅ 직업 태그
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.3),
                borderRadius: AppRadius.small,
              ),
              child: Text(
                c.job,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ✅ 서버명
            Text(c.server, style: AppTextStyles.body2),

            const SizedBox(height: AppSpacing.sm),

            // ✅ 캐릭터 이미지 (URL 사용으로 변경)
            Expanded(
              child: _buildCharacterImage(c), // ★ CHANGED: 분리
            ),

            const SizedBox(height: AppSpacing.sm),

            // ✅ 닉네임
            Text(c.name, style: AppTextStyles.subtitle),

            const SizedBox(height: 2),

            // ✅ 명성
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/fame.png', width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  '${c.fame}',
                  style: AppTextStyles.body2.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  // ⭐ NEW: 이미지 빌더 함수 (URL + fallback)
  Widget _buildCharacterImage(Character c) {
    // URL이 아예 없으면 바로 플레이스홀더
    if (c.imagePath.isEmpty) {
      return Image.asset('assets/images/no_image.png', fit: BoxFit.contain);
    }

    // URL 있으면 네트워크로 시도 + 실패 시 fallback
    return Image.network(
      c.imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/images/no_image.png', fit: BoxFit.contain);
      },
    );
  }
}
