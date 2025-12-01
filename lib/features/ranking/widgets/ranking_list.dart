import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_container_with_subtitle.dart';

class RankingList extends StatelessWidget {
  final String job;
  final String awakening;
  final List<Map<String, dynamic>> rankingData;
  final Function(Map<String, dynamic>) onTapCharacter;

  const RankingList({
    super.key,
    required this.job,
    required this.awakening,
    required this.rankingData,
    required this.onTapCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainerWithSubtitle(
      header: const Text(
        '순위표',
        style: TextStyle(fontSize: 14, color: AppColors.primaryText),
      ),
      subtitle: const Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: _subtitleStyle)),
          Expanded(child: Text('캐릭터', style: _subtitleStyle)),
        ],
      ),
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rankingData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final character = rankingData[index];
            return InkWell(
              onTap: () => onTapCharacter(character),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 순위
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          '${character['rank']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 🔹 캐릭터 정보
                    Expanded(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildCharacterImage(
                              character['image'] as String?,
                              size: 44,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  character['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lv.${character['level']} | ${character['server']} | ${character['class']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                _buildCharacterImage(
                                  character['image'] as String?,
                                  size: 16,
                                ),
                                    const SizedBox(width: 4),
                                    Text(
                                      character['power'] ?? '-',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCharacterImage(String? imagePath, {double size = 44}) {
    final fallback = Image.asset(
      'assets/images/no_image.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (imagePath == null || imagePath.isEmpty) return fallback;

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}

const _subtitleStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 13,
  color: AppColors.secondaryText,
);
