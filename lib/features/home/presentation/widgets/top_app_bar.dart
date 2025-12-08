import 'package:flutter/material.dart';
import 'package:flutter_fb/features/character/presentation/pages/character_detail_page.dart';
import 'package:flutter_fb/features/character/presentation/pages/character_search_result.dart';
import 'package:flutter_fb/features/character/repository/firebase_character_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_text_styles.dart';

class CustomTopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showTabBar;
  const CustomTopAppBar({super.key, this.showTabBar = true});

  @override
  State<CustomTopAppBar> createState() => _CustomTopAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (showTabBar ? kTextTabBarHeight : 0.0));
}

class _CustomTopAppBarState extends State<CustomTopAppBar> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseCharacterRepository _repository =
      const FirebaseCharacterRepository();
  bool _searching = false;

  Future<void> _onSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (_searching) return;
    setState(() => _searching = true);

    try {
      final results = await _repository.searchCharacters(name: query);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('검색 결과', style: AppTextStyles.subtitle),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryText,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: CharacterSearchResult(
                      query: query,
                      results: results,
                      onCharacterSelected: (character) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CharacterDetailView(character: character),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캐릭터 검색 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleSpacing: AppSpacing.sm,
      title: Row(
        children: [
          // 로고 이미지로 교체 가능
          Image.asset('assets/images/logo_done.png', height: 52),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _onSearch(),
                      decoration: InputDecoration(
                        hintText: '던전앤파이터 캐릭터 검색',
                        hintStyle: AppTextStyles.body2.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    color: AppColors.secondaryText,
                    onPressed: _searching ? null : _onSearch,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
