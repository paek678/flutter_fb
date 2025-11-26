import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../models/auction_item.dart';
import '../models/auction_item_data.dart' as src;
import '../repository/auction_repository.dart';
import 'widgets/price_line_chart.dart';

class AuctionItemDetailScreen extends StatefulWidget {
  const AuctionItemDetailScreen({super.key});

  @override
  State<AuctionItemDetailScreen> createState() =>
      _AuctionItemDetailScreenState();
}

class _AuctionItemDetailScreenState extends State<AuctionItemDetailScreen> {
  bool _isFavorite = false;
  bool _initializedFavorite = false; // ✅ item.isFavorite에서 한 번만 복사하기 위한 플래그

  // 싱글톤 레포 인스턴스 (factory InMemoryAuctionRepository() 사용)
  final InMemoryAuctionRepository _repo = InMemoryAuctionRepository();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> j =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        {};

    final item = AuctionItem.fromJson(j);

    // ✅ 첫 빌드에서만 item.isFavorite 값을 내부 state로 복사
    if (!_initializedFavorite) {
      _isFavorite = item.isFavorite;
      _initializedFavorite = true;
    }

    // 이름으로 상세 데이터(레벨/공격/옵션/시세 등) 매칭
    final srcItem = src.kAuctionItems.cast<src.AuctionItem?>().firstWhere(
      (e) => e?.name == item.name,
      orElse: () => null,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            item.name,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: AppColors.primaryText),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── 상단 헤더: 이미지 + 기본 정보 + 좋아요
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _thumb(item.imagePath),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BasicInfo(
                        name: item.name,
                        price: item.price,
                        rarityLabel: srcItem?.rarity,
                        isFavorite: _isFavorite,
                        onFavoriteToggle: () async {
                          // 싱글톤 레포로 찜 토글 + 로컬 UI 상태 토글
                          await _repo.toggleFavorite(item.id);
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // ── 탭바 (시세 / 상세정보)
              Container(
                color: AppColors.surface,
                child: const TabBar(
                  isScrollable: false,
                  indicatorColor: AppColors.primaryText,
                  indicatorWeight: 2,
                  labelColor: AppColors.primaryText,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: '시세'),
                    Tab(text: '상세정보'),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // ── 탭 내용
              Expanded(
                child: TabBarView(
                  children: [
                    // 1) 시세 탭
                    _PriceTab(srcItem: srcItem),

                    // 2) 상세정보 탭
                    _DetailTab(item: item, srcItem: srcItem),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.15),
        ),
        child: const Icon(Icons.image_not_supported, size: 28),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          color: Colors.grey.withOpacity(0.15),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// 시세 탭: 차트 + 최종 판매가 리스트
/// ─────────────────────────────────────────────
class _PriceTab extends StatelessWidget {
  final src.AuctionItem? srcItem;

  const _PriceTab({required this.srcItem});

  // data의 d7 시리즈를 "최근 7일"로 매핑
  List<(DateTime date, double price)> _buildWeekPoints(src.AuctionItem s) {
    final series = src.fullSeriesOf(s, src.PriceRange.d7);
    if (series.isEmpty) return const [];

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final len = series.length;

    return List.generate(len, (i) {
      final offset = len - 1 - i; // 오래된 값이 과거 날짜
      final date = base.subtract(Duration(days: offset));
      return (date, series[i].toDouble());
    });
  }

  String _formatDate(DateTime d) {
    final yy = (d.year % 100).toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yy.$mm.$dd';
  }

  @override
  Widget build(BuildContext context) {
    if (srcItem == null) {
      return const Center(
        child: Text('시세 데이터가 없습니다.', style: AppTextStyles.body2),
      );
    }

    final weekPoints = _buildWeekPoints(srcItem!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아이템 시세',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '최근 7일 기준 시세',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),

          // 차트 카드
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: weekPoints.isEmpty
                ? const Center(
                    child: Text(
                      '시세 기록이 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  )
                : PriceLineChartFirst5(
                    points: weekPoints, // 여기서 points 전달
                    backgroundColor: AppColors.surface,
                  ),
          ),

          const SizedBox(height: 16),

          // 최종 판매가 리스트
          Text(
            '최종 판매가',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: weekPoints
                  .reversed // 최근 날짜부터
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              _formatDate(p.$1),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${p.$2.toStringAsFixed(0)} G',
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// 상세정보 탭
/// ─────────────────────────────────────────────
class _DetailTab extends StatelessWidget {
  final AuctionItem item;
  final src.AuctionItem? srcItem;

  const _DetailTab({required this.item, required this.srcItem});

  @override
  Widget build(BuildContext context) {
    if (srcItem != null) {
      final s = srcItem!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionTitle('세부 정보'),
          const SizedBox(height: 8),
          _KeyValueCard(
            entries: [
              if (s.type.isNotEmpty) ('종류', '${s.type} / ${s.subType}'),
              ('등급', s.rarity),
              ('요구 레벨', '${s.levelLimit}'),
              ('지능', '${s.intelligence}'),
              ('전투력', '${s.combatPower}'),
              if (s.weightKg != null) ('무게(kg)', '${s.weightKg}'),
              if (s.durability != null) ('내구도', s.durability!),
            ],
          ),

          const SizedBox(height: 16),
          _SectionTitle('공격력'),
          const SizedBox(height: 8),
          _KeyValueCard(
            entries: [
              ('물리', '${s.attack.physical}'),
              ('마법', '${s.attack.magical}'),
              ('독립', '${s.attack.independent}'),
            ],
          ),

          if (s.options.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('옵션'),
            const SizedBox(height: 8),
            _OptionList(options: s.options),
          ],
        ],
      );
    }

    // srcItem 없을 때: 최소 정보만
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionTitle('세부 정보'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '추가 상세 데이터가 없어 기본 정보만 표시합니다.\n'
              '이름: ${item.name}\n가격: ${item.price} G',
              style: AppTextStyles.body2.copyWith(height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────
/// 서브 위젯들
/// ─────────────────────────────────────────────
class _BasicInfo extends StatelessWidget {
  final String name;
  final int price;
  final String? rarityLabel;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _BasicInfo({
    required this.name,
    required this.price,
    required this.rarityLabel,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  Color _rarityColor(String label) {
    if (label.contains('레전더리')) return const Color(0xFFFF9800);
    if (label.contains('유니크')) return const Color(0xFFAB47BC);
    if (label.contains('레어')) return const Color(0xFF42A5F5);
    return AppColors.secondaryText;
  }

  @override
  Widget build(BuildContext context) {
    Widget? rarityChip;
    if (rarityLabel != null && rarityLabel!.isNotEmpty) {
      final c = _rarityColor(rarityLabel!);
      rarityChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(0.9), width: 1),
          color: c.withOpacity(0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 14, color: c.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              rarityLabel!,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 왼쪽: 텍스트 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              if (rarityChip != null) ...[
                rarityChip,
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$price G',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 오른쪽: 좋아요 하트
        IconButton(
          onPressed: onFavoriteToggle,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body1.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final List<(String, String)> entries;
  const _KeyValueCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: entries
              .map((e) => _OneRow(label: e.$1, value: e.$2))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _OneRow extends StatelessWidget {
  final String label;
  final String value;
  const _OneRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  final List<String> options;
  const _OptionList({required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options
              .map(
                (o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•  ',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      Expanded(
                        child: Text(
                          o,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
