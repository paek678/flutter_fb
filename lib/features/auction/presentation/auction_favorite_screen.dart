import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/auction_item.dart';
import '../repository/auction_repository.dart';
import 'widgets/auction_item_tile.dart';

/// 찜 목록 전체 화면
class AuctionFavoriteScreen extends StatefulWidget {
  const AuctionFavoriteScreen({super.key});

  @override
  State<AuctionFavoriteScreen> createState() => _AuctionFavoriteScreenState();
}

class _AuctionFavoriteScreenState extends State<AuctionFavoriteScreen> {
  //  싱글톤 레포 인스턴스 (factory InMemoryAuctionRepository() 사용)
  final InMemoryAuctionRepository _repo = InMemoryAuctionRepository();

  List<AuctionItem> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites(); //  레포는 이미 필드에서 생성되어 있으니 바로 로드만
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    final favs = await _repo.fetchFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(int itemId) async {
    await _repo.toggleFavorite(itemId);
    await _loadFavorites(); // 토글 후 다시 찜 목록 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        title: Text(
          '찜 목록',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          '찜한 아이템이 없습니다.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return ListView.builder(
      // ✅ 리스트 자체도 양옆 여유 조금 더 줌
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final item = _favorites[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0.5,
            child: Padding(
              // ✅ 카드 안쪽에 가로/세로 패딩 넣어서 내용이 가운데 쪽으로
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AuctionItemTile(
                item: item,
                isFavorite: true,
                onFavoriteToggle: () => _toggleFavorite(item.id),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/auction_item_detail',
                    arguments: item.toJson(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
