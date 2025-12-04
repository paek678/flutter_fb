import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/auction_item.dart';
import '../../repository/auction_repository.dart';
import 'auction_item_tile.dart';

class AuctionSearchContent extends StatefulWidget {
  final String query;

  const AuctionSearchContent({super.key, required this.query});

  @override
  State<AuctionSearchContent> createState() => _AuctionSearchContentState();
}

class _AuctionSearchContentState extends State<AuctionSearchContent> {
  final FirestoreAuctionRepository _repo = FirestoreAuctionRepository();

  List<AuctionItem> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuctionSearchContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _load();
    }
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '\'${widget.query}\' 검색결과',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _buildBody()),
      ],
    );
  }
}
