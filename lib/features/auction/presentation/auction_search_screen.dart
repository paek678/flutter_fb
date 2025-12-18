import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'widgets/auction_search_content.dart';

/// 별도 라우팅 시 사용되는 검색 화면.
/// 실제 로직은 `AuctionSearchContent`에 모아 두어 중복을 제거했다.
class AuctionSearchScreen extends StatelessWidget {
  final String query;

  const AuctionSearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "'$query' 검색결과",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: AuctionSearchContent(query: query),
    );
  }
}
