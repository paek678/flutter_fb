import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/auction_item.dart';
import '../repository/auction_repository.dart';
import 'widgets/auction_item_tile.dart';

class AuctionSearchScreen extends StatefulWidget {
  final String query;

  const AuctionSearchScreen({super.key, required this.query});

  @override
  State<AuctionSearchScreen> createState() => _AuctionSearchScreenState();
}

class _AuctionSearchScreenState extends State<AuctionSearchScreen> {
  final FirestoreAuctionRepository _repo = FirestoreAuctionRepository();

  List<AuctionItem> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.fetchItems(query: widget.query);
    if (!mounted) return;
    setState(() {
      _results = _mergeWithUserFavorites(items);
      _loading = false;
    });
  }

  List<AuctionItem> _mergeWithUserFavorites(List<AuctionItem> items) {
    final favorites = FirestoreService.currentUser?.favorites;
    if (favorites == null || favorites.isEmpty) return items;
    return items.map((item) {
      final isUserFavorite = favorites.contains(item.id);
      if (isUserFavorite == item.isFavorite) return item;
      return item.copyWith(isFavorite: item.isFavorite || isUserFavorite);
    }).toList(growable: false);
  }

  Future<bool> _updateUserFavorite(int itemId) async {
    final current = FirestoreService.currentUser;
    if (current == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 즐겨찾기를 사용할 수 있습니다.')),
      );
      return false;
    }

    final updatedFavorites = Set<int>.from(current.favorites);
    final wasFavorite = updatedFavorites.contains(itemId);
    if (wasFavorite) {
      updatedFavorites.remove(itemId);
    } else {
      updatedFavorites.add(itemId);
    }

    final updatedUser = current.copyWith(
      favorites: updatedFavorites,
      lastActionAt: DateTime.now(),
    );

    await FirestoreService.updateUser(updatedUser);
    FirestoreService.setCurrentUser(updatedUser);
    return true;
  }

  Future<void> _toggleFavorite(AuctionItem item) async {
    try {
      final ok = await _updateUserFavorite(item.id);
      if (!ok) return;
      await _repo.toggleFavorite(item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 업데이트 실패: $e')),
      );
    }
  }

  void _openDetail(AuctionItem item) {
    Navigator.pushNamed(
      context,
      '/auction_item_detail',
      arguments: item.toJson(),
    );
  }

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
        "'${widget.query}' 검색결과",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AuctionItemTile(
                        item: item,
                        isFavorite: item.isFavorite,
                        onFavoriteToggle: () => _toggleFavorite(item),
                        onTap: () => _openDetail(item),
                      ),
                    );
                  },
                ),
    );
  }
}
