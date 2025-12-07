// lib/features/character/presentation/views/character_detail_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_fb/core/theme/app_colors.dart';
import 'package:flutter_fb/core/theme/app_text_styles.dart';

// 기본 캐릭터 정보
import 'package:flutter_fb/features/character/models/domain/character.dart';
import 'package:flutter_fb/features/character/models/domain/character_info.dart';
import 'package:flutter_fb/features/character/models/domain/character_detail_stats.dart';
import 'package:flutter_fb/features/character/models/domain/character_stats.dart';

// 레포지토리
import 'package:flutter_fb/features/character/repository/firebase_character_repository.dart';

// 슬롯 모델
import 'package:flutter_fb/features/character/models/ui/equipment_slot.dart';
import 'package:flutter_fb/features/character/models/ui/avatar_creature_slot.dart';
import 'package:flutter_fb/features/character/models/ui/buff_slot.dart';

// 탭들
import 'package:flutter_fb/features/character/presentation/widgets/detail_buff_tab.dart';
import '../widgets/detail_equipment_tab.dart';
import '../widgets/detail_basic_stat_tab.dart';
import '../widgets/detail_detail_stat_tab.dart';
import '../widgets/detail_avatar_creature_tab.dart';

class CharacterDetailView extends StatefulWidget {
  final Character character;
  final bool fromRanking;

  const CharacterDetailView({
    super.key,
    required this.character,
    this.fromRanking = false,
  });

  @override
  State<CharacterDetailView> createState() => _CharacterDetailViewState();
}

class _CharacterDetailViewState extends State<CharacterDetailView>
    with AutomaticKeepAliveClientMixin {
  int _selectedTabIndex = 0;

  final List<String> tabs = const [
    '장착장비',
    '스탯',
    '세부스탯',
    '아바타&크리쳐',
    '버프강화',
  ];

  late final FirebaseCharacterRepository _repository;

  /// 상세 정보가 채워진 Character
  CharacterInfo? _detail;
  bool _loading = true;
  String? _error;

  final List<Widget?> _builtTabs = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _repository = const FirebaseCharacterRepository();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint(
        '[CharacterDetailView] fetch detail id=${widget.character.id} name=${widget.character.name}',
      );
      final info = await _repository.getCharacterInfoById(widget.character.id);

      if (!mounted) return;

      // ✅ 상세가 없더라도, 최소한 빈 CharacterInfo 만들어서 탭은 뜨게 하기
      final fallback = CharacterInfo(
        summary: widget.character,
        stats: const CharacterStats.empty(), // ✅ 이제 됨
        detailStats: const CharacterDetailStats.empty(), // 이건 이미 있음
        extraDetailStats: const [],
        equipments: const [],
        avatars: const [],
        buffItems: const [],
      );

      if (info != null) {
        debugPrint(
          '[CharacterDetailView] detail loaded id=${widget.character.id} stats=${info.stats} detailStats=${info.detailStats} '
          'equipments=${info.equipments.length} avatars=${info.avatars.length} buffItems=${info.buffItems.length}',
        );
        for (final b in info.buffItems) {
          debugPrint(
            '[CharacterDetailView] buffItem category=${b.category} name=${b.name} grade=${b.grade} option=${b.option} imagePath=${b.imagePath}',
          );
        }
      } else {
        debugPrint(
          '[CharacterDetailView] detail null, using fallback for id=${widget.character.id}',
        );
      }

      setState(() {
        _detail = info ?? fallback;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '캐릭터 정보를 불러오는 데 실패했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 상단 프로필은 상세가 있으면 그걸, 아니면 기존 character 사용
    final c = _detail?.summary ?? widget.character;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(c.name, style: AppTextStyles.subtitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          iconSize: 18,
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildCharacterInfo(c),
          Divider(height: 1, color: AppColors.border),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null || _detail == null)
            Expanded(
              child: Center(
                child: Text(
                  _error ?? '캐릭터 정보를 불러올 수 없습니다.',
                  style: AppTextStyles.body2,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  _buildTabSelector(),
                  Divider(height: 1, color: AppColors.border),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo(Character c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: c.imagePath.isNotEmpty
                ? Image.network(
                    c.imagePath,
                    width: 216,
                    height: 216,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/no_image.png',
                        width: 216,
                        height: 216,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/no_image.png',
                    width: 216,
                    height: 216,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text('${c.job} | ${c.server}', style: AppTextStyles.body2),
                const SizedBox(height: 4),
                Text('Lv.${c.level}', style: AppTextStyles.body2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/fame.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${c.fame}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTabIndex == index;
        return SizedBox(
          width: MediaQuery.of(context).size.width / 4 - 1,
          height: 40,
          child: InkWell(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              color: isSelected ? AppColors.primaryText : AppColors.surface,
              alignment: Alignment.center,
              child: Text(
                tabs[index],
                style: isSelected
                    ? AppTextStyles.body1.copyWith(color: Colors.white)
                    : AppTextStyles.body2.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: List.generate(tabs.length, (i) => _getTab(i)),
    );
  }

  Widget _getTab(int i) {
    if (_builtTabs[i] != null) return _builtTabs[i]!;

    final info = _detail!; // CharacterInfo

    switch (i) {
      case 0:
        final slots = buildSlotsFromItems(info.equipments);
        _builtTabs[i] = EquipmentTab(slots: slots);
        break;
      case 1:
        _builtTabs[i] = StatTab(stats: info.stats); // CharacterStats
        break;

      case 2:
        _builtTabs[i] = DetailStatTab(
          detailStats: info.detailStats,
          extraStats: info.extraDetailStats,
        );
        break;
      case 3:
        final avatarSlots = buildAvatarSlotsFromItems(info.avatars);
        _builtTabs[i] = AvatarCreatureTab(slots: avatarSlots);
        break;

      case 4:
        final buffSlots = buildBuffSlotsFromItems(info.buffItems);
        _builtTabs[i] = BuffTab(slots: buffSlots);
        break;

      default:
        _builtTabs[i] = Center(
          child: Text(
            '탭 데이터가 없습니다.',
            style: AppTextStyles.body1,
          ),
        );
    }

    return _builtTabs[i]!;
  }

  @override
  bool get wantKeepAlive => true;
}
