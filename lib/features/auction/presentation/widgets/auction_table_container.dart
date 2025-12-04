import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/auction_item.dart';

/// 테이블 한 줄에 필요한 데이터
class AuctionPriceRow {
  final int rank;
  final AuctionItem item;
  final double changePercent; // +3.2 / -1.5 같은 값

  const AuctionPriceRow({
    required this.rank,
    required this.item,
    required this.changePercent,
  });
}

/// 금일 시세 상승률 / 하락률 TOP 공용 컨테이너
class AuctionPriceTableContainer extends StatelessWidget {
  final String title;
  final List<AuctionPriceRow> rows;

  /// true = 상승, false = 하락 (색만 다르게)
  final bool isIncrease;

  /// 행 클릭 시 호출
  final void Function(AuctionPriceRow row) onRowTap;

  const AuctionPriceTableContainer({
    super.key,
    required this.title,
    required this.rows,
    required this.isIncrease,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget _buildThumb(String? path) {
      final placeholder = const Icon(
        Icons.image_not_supported_outlined,
        size: 18,
        color: AppColors.secondaryText,
      );

      if (path == null || path.isEmpty) {
        return placeholder;
      }
      if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        );
      }
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Text(
              title,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),

          // 헤더 행
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFF7F7F7),
            child: Row(
              children: const [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  child: SizedBox(), // 이미지 자리
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '아이템명',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '변동률',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEAEAEA)),

          // 데이터 행
          Column(
            children: rows.map((row) {
              final item = row.item;
              final change = row.changePercent;
              final isPlus = change >= 0;
              final changeColor = isIncrease
                  ? const Color(0xFFE53935) // 상승: 빨간 톤
                  : const Color(0xFF1E88E5); // 하락: 파란 톤

              final changeText =
                  '${isPlus ? '+' : ''}${change.toStringAsFixed(1)}%';

              return InkWell(
                onTap: () => onRowTap(row),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // 순위 배지
                          SizedBox(
                            width: 24,
                            child: _RankBadge(rank: row.rank),
                          ),
                          const SizedBox(width: 4),

                          // 아이템 이미지
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _buildThumb(item.imagePath),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // 아이템 이름
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 변동률 %
                          SizedBox(
                            width: 60,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                changeText,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: changeColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final bg = isTop3 ? AppColors.secondaryText : Colors.white;
    return Container(
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isTop3 ? Colors.white : AppColors.secondaryText,
        ),
      ),
    );
  }
}
