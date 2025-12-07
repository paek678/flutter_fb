import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/auction_item.dart';
import '../repository/auction_repository.dart';
import 'widgets/auction_item_tile.dart';

/// 즐겨찾기 목록 화면
class AuctionFavoriteScreen extends StatefulWidget {
  const AuctionFavoriteScreen({super.key});

  @override
  State<AuctionFavoriteScreen> createState() => _AuctionFavoriteScreenState();
}

class _AuctionFavoriteScreenState extends State<AuctionFavoriteScreen> {
  /// Firestore 기반 리포지토리 (내부에서 데이터가 없으면 인메모리 fallback)
  final FirestoreAuctionRepository _repo = FirestoreAuctionRepository();

  List<AuctionItem> _favorites = [];
  bool _loading = true;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);

    final currentUser = FirestoreService.currentUser;
    if (currentUser == null) {
      setState(() {
        _favorites = const [];
        _loading = false;
        _infoMessage = '로그인 후 즐겨찾기를 확인할 수 있습니다.';
      });
      return;
    }

    final favIds = currentUser.favorites;
    if (favIds.isEmpty) {
      setState(() {
        _favorites = const [];
        _loading = false;
        _infoMessage = '즐겨찾기한 아이템이 없습니다.';
      });
      return;
    }

    final allItems = await _repo.fetchItems();
    final favs = allItems
        .where((e) => favIds.contains(e.id))
        .map((e) => e.copyWith(isFavorite: true))
        .toList();

    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _loading = false;
      _infoMessage = null;
    });
  }

  Future<void> _toggleFavorite(int itemId) async {
    final currentUser = FirestoreService.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 즐겨찾기를 사용할 수 있습니다.')),
      );
      return;
    }

    final updatedFavorites = Set<int>.from(currentUser.favorites);
    final wasFavorite = updatedFavorites.contains(itemId);
    if (wasFavorite) {
      updatedFavorites.remove(itemId);
    } else {
      updatedFavorites.add(itemId);
    }

    final updatedUser = currentUser.copyWith(
      favorites: updatedFavorites,
      lastActionAt: DateTime.now(),
    );

    await FirestoreService.updateUser(updatedUser);
    FirestoreService.setCurrentUser(updatedUser);

    // 로컬 Repo 캐시도 동기화
    await _repo.toggleFavorite(itemId);
    await _loadFavorites();
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
          '즐겨찾기',
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
      return Center(
        child: Text(
          _infoMessage ?? '즐겨찾기한 아이템이 없습니다.',
          style: const TextStyle(color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
