import 'package:flutter/material.dart';

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
      _results = items;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(AuctionItem item) async {
    await _repo.toggleFavorite(item.id);
    await _load();
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
