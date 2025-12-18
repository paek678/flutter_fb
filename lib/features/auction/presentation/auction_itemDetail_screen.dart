import 'package:flutter/material.dart';

import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firebase_service.dart';

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
  bool _initializedFavorite = false; // 첫 build 때 한 번만 item.isFavorite 값을 state로 복사하기 위한 플래그
  bool _loggedDebug = false; // 디테일 진입 시 character_info 포함한 전체 데이터 로깅 여부

  // 즐겨찾기 테스트용 인메모리 리포지토리 (factory InMemoryAuctionRepository() 사용)
  final InMemoryAuctionRepository _repo = InMemoryAuctionRepository();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> j =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
            {};

    final item = AuctionItem.fromJson(j);

    // 최초 빌드에서만 item.isFavorite 값을 state로 복사
    if (!_initializedFavorite) {
      final userFav = FirestoreService.currentUser?.favorites ?? const <int>{};
      final isUserFavorite = userFav.contains(item.id);
      _isFavorite = item.isFavorite || isUserFavorite;
      _initializedFavorite = true;
    }

    // 이름 기준으로 정적 소스 아이템 한 번 더 찾아서 (fallback용)
    final srcItem = src.kAuctionItems.cast<src.AuctionItem?>().firstWhere(
      (e) => e?.name == item.name,
      orElse: () => null,
    );

    if (!_loggedDebug) {
      _loggedDebug = true;
      _logDetailDebugData(j, item, srcItem);
    }

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
              // 상단 요약 헤더: 썸네일 + 기본 정보 + 즐겨찾기 버튼
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
                        onFavoriteToggle: () => _toggleFavoriteForUser(item),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // 상단 탭 (시세 / 상세 정보)
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
                    Tab(text: '상세 정보'),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // 탭 내용
              Expanded(
                child: TabBarView(
                  children: [
                    // 1) 시세 탭
                    _PriceTab(item: item, srcItem: srcItem),

                    // 2) 상세 정보 탭
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

  void _logDetailDebugData(
    Map<String, dynamic> rawArgs,
    AuctionItem item,
    src.AuctionItem? srcItem,
  ) {
    const encoder = JsonEncoder.withIndent('  ');

    String _pretty(dynamic v) {
      try {
        return encoder.convert(v);
      } catch (_) {
        return v?.toString() ?? 'null';
      }
    }

    void _logBlock(String title, String body) {
      const chunkSize = 800; // debugPrint 길이 제한 방지
      debugPrint('--- [AuctionDetail] $title ---');
      for (var start = 0; start < body.length; start += chunkSize) {
        final end =
            (start + chunkSize < body.length) ? start + chunkSize : body.length;
        debugPrint(body.substring(start, end));
      }
    }

    _logBlock('raw arguments (ModalRoute.settings.arguments)', _pretty(rawArgs));

    final characterInfo = rawArgs['character_info'];
    _logBlock('character_info', _pretty(characterInfo));

    _logBlock('AuctionItem parsed (toJson)', _pretty(item.toJson()));

    if (srcItem != null) {
      _logBlock(
          'src fallback (auction_item_data.dart)', _pretty(srcItem.toJson()));
    } else {
      debugPrint(
          '--- [AuctionDetail] src fallback (auction_item_data.dart) ---\n<null>');
    }
  }

  Future<void> _toggleFavoriteForUser(AuctionItem item) async {
    final current = FirestoreService.currentUser;
    if (current == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 즐겨찾기를 사용할 수 있습니다.')),
      );
      return;
    }

    final updatedFavorites = Set<int>.from(current.favorites);
    final wasFavorite = updatedFavorites.contains(item.id);
    if (wasFavorite) {
      updatedFavorites.remove(item.id);
    } else {
      updatedFavorites.add(item.id);
    }

    final updatedUser = current.copyWith(
      favorites: updatedFavorites,
      lastActionAt: DateTime.now(),
    );

    try {
      await FirestoreService.updateUser(updatedUser);
      FirestoreService.setCurrentUser(updatedUser);
      await _repo.toggleFavorite(item.id);
      if (!mounted) return;
      setState(() {
        _isFavorite = !wasFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 업데이트 실패: $e')),
      );
    }
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

    Widget image;
    if (path.startsWith('http')) {
      image = Image.network(
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
      );
    } else {
      image = Image.asset(
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
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 시세 탭: 라인 차트 + 최근 일별 내역 리스트
/// ---------------------------------------------------------------------------
class _PriceTab extends StatelessWidget {
  final AuctionItem item;
  final src.AuctionItem? srcItem;

  const _PriceTab({required this.item, required this.srcItem});

  // data에서 최근 7일 시세만 사용 (item.history 우선, 없으면 정적 데이터 fallback)
  List<(DateTime date, double price)> _buildWeekPoints() {
    List<double> series = [];

    // 1) 로드된 상세 history 사용
    final hist = item.history;
    if (hist != null && hist.containsKey(src.PriceRange.d7)) {
      series = hist[src.PriceRange.d7] ?? const [];
    }

    // 2) itemPrice에서 최근 거래가 fallback
    if (series.isEmpty) {
      final recent = item.itemPrice?.recentUnitPrices ?? const <int>[];
      if (recent.isNotEmpty) {
        series = recent
            .take(7)
            .map((e) => e.toDouble())
            .toList(growable: false);
      }
    }

    // 2) 정적 데이터 fallback
    if (series.isEmpty && srcItem != null) {
      series = src.fullSeriesOf(srcItem!, src.PriceRange.d7);
    }

    if (series.isEmpty) return const [];

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final len = series.length;

    return List.generate(len, (i) {
      final offset = len - 1 - i; // 리스트 뒤가 오늘 기준
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
    final weekPoints = _buildWeekPoints();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가격 추이 (시세)',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '최근 7일간 시세',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),

          // 라인 차트 카드
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
                    points: weekPoints,
                    backgroundColor: AppColors.surface,
                  ),
          ),

          const SizedBox(height: 16),

          // 일자별 시세 리스트
          Text(
            '최근 일별 시세',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weekPoints.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border.withOpacity(0.6),
            ),
            itemBuilder: (_, index) {
              final p = weekPoints.reversed.toList()[index];
              return Padding(
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
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 상세 정보 탭
/// ---------------------------------------------------------------------------
class _DetailTab extends StatelessWidget {
  final AuctionItem item;
  final src.AuctionItem? srcItem;

  const _DetailTab({required this.item, required this.srcItem});

  @override
  Widget build(BuildContext context) {
    final rarity = item.rarity ?? srcItem?.rarity ?? '';
    final type = item.type ?? srcItem?.type ?? '';
    final subType = item.subType ?? srcItem?.subType ?? '';
    final levelLimit = item.levelLimit ?? srcItem?.levelLimit;
    final intelligence = item.intelligence ?? srcItem?.intelligence;
    final combatPower = item.combatPower ?? srcItem?.combatPower;
    final weightKg = item.weightKg ?? srcItem?.weightKg;
    final durability = item.durability ?? srcItem?.durability;
    final attack = item.attack ??
        srcItem?.attack ??
        const src.AttackStats(physical: 0, magical: 0, independent: 0);
    final options = item.options ?? srcItem?.options ?? const <String>[];

    final hasDetail = rarity.isNotEmpty || type.isNotEmpty || options.isNotEmpty;

    if (!hasDetail) {
      // 최소 정보 fallback
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionTitle('기본 정보'),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionTitle('기본 정보'),
        const SizedBox(height: 8),
        _KeyValueCard(
          entries: [
            if (type.isNotEmpty) ('장비 종류', '$type / $subType'),
            if (rarity.isNotEmpty) ('등급', rarity),
            if (levelLimit != null) ('착용 레벨', '$levelLimit'),
            if (intelligence != null) ('지능', '$intelligence'),
            if (combatPower != null) ('전투력', '$combatPower'),
            if (weightKg != null) ('무게(kg)', '$weightKg'),
            if (durability != null) ('내구도', '$durability'),
          ],
        ),

        const SizedBox(height: 16),
        _SectionTitle('공격력'),
        const SizedBox(height: 8),
        _KeyValueCard(
          entries: [
            ('물리 공격력', '${attack.physical}'),
            ('마법 공격력', '${attack.magical}'),
            ('독립 공격력', '${attack.independent}'),
          ],
        ),

        if (options.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('옵션'),
          const SizedBox(height: 8),
          _OptionList(options: options),
        ],
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// 상단 기본 정보 카드
/// ---------------------------------------------------------------------------
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
    if (label.contains('에픽')) return const Color(0xFFAB47BC);
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

        // 오른쪽: 즐겨찾기 버튼
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
                        '- ',
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
