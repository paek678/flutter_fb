// lib/features/home/widgets/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface, // ✅ 배경색 통일
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1), // ✅ 위쪽 구분선
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // ✅ 부모 컨테이너 색상 그대로 사용
          selectedItemColor: AppColors.primaryText, // ✅ 선택된 탭 색
          unselectedItemColor: AppColors.secondaryText, // ✅ 비활성 탭 색
          selectedLabelStyle: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTextStyles.body2,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          currentIndex: currentIndex,
          onTap: onTabChanged,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              label: '알림',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
