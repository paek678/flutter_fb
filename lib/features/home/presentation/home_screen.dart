import 'package:flutter/material.dart';
import 'package:flutter_fb/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:flutter_fb/features/home/presentation/widgets/top_app_bar.dart';
import 'package:flutter_fb/features/home/presentation/widgets/tab_bar.dart';
import '../../character/presentation/pages/character_search_page.dart';
import '../../auction/presentation/auction_screen.dart';
import '../../board/presentation/board_list_screen.dart';
import '../../community/presentation/community_list_screen.dart';
import '../../ranking/presentation/pages/ranking_screen.dart';
import '../../../core/theme/app_colors.dart';

class BaseScreen extends StatelessWidget {
  final Widget child;
  const BaseScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // ✅ 모든 탭에 동일 패딩 적용
      child: child,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomIndex = 1;

  void _handleBottomTab(BuildContext context, int index) {
    setState(() => _bottomIndex = index);

    if (index == 1) {
      // Home 탭과 동일한 첫 번째 TabBar 탭으로 이동
      DefaultTabController.of(context)?.animateTo(0);
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomTopAppBar(showTabBar: false),
            const CustomTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  // 🔥 여기: CharacterSearchTab은 BaseScreen 안 씌운다
                  Builder(
                    builder: (innerContext) => CharacterSearchTab(
                      onTabChange: (index) {
                        DefaultTabController.of(innerContext)?.animateTo(index);
                      },
                    ),
                  ),

                  // 나머지 탭은 그대로 BaseScreen 써도 됨
                  const BaseScreen(child: RankingScreen()),
                  const AuctionScreen(),
                  const CommunityListScreen(),
                  const BoardListScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (bottomNavContext) => CustomBottomNavBar(
            currentIndex: _bottomIndex,
            onTabChanged: (index) => _handleBottomTab(bottomNavContext, index),
          ),
        ),
      ),
    );
  }
}
