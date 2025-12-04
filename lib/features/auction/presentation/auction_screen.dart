import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';

import '../models/auction_item.dart';
import '../repository/auction_repository.dart';
import 'widgets/auction_table_container.dart';
import 'widgets/auction_search_content.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Firestore 기반 레포지토리 (내부에서 필요한 경우 메모리 fallback 처리)
  final FirestoreAuctionRepository _repo = FirestoreAuctionRepository();

  // 상승 / 하락 리스트
  List<AuctionPriceRow> _increaseRows = [];
  List<AuctionPriceRow> _decreaseRows = [];
  bool _loadingTable = true;

  // 검색 결과 전환용
  bool _showSearchResult = false;
  String _currentQuery = '';
  bool _preloadedRepo = false;

  @override
  void initState() {
    super.initState();
    _preloadRepo();
    _loadPriceRows(); // ✅ 레포는 이미 필드에서 생성, 여기서는 데이터만 로딩
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _preloadRepo() async {
    if (_preloadedRepo) return;
    _preloadedRepo = true;
    try {
      final items = await _repo.fetchItems();
      debugPrint(
        '[AuctionScreen] Firestore repo preloaded, count=${items.length}',
      );
    } catch (e) {
      debugPrint('[AuctionScreen] Firestore preload failed: $e');
    }
  }

  Future<void> _loadPriceRows() async {
    setState(() => _loadingTable = true);

    final items = await _repo.fetchItems();
    if (!mounted) return;

    if (items.isEmpty) {
      setState(() {
        _increaseRows = [];
        _decreaseRows = [];
        _loadingTable = false;
      });
      return;
    }

    final limited = items.take(5).toList();
    final n = limited.length;

    final rand = Random();

    setState(() {
      _increaseRows = [
        for (int i = 0; i < n; i++)
          AuctionPriceRow(
            rank: i + 1,
            item: limited[i],
            // 1.0 ~ 7.0% 사이 랜덤 상승률
            changePercent: 1 + rand.nextDouble() * 6,
          ),
      ];

      _decreaseRows = [
        for (int i = 0; i < n; i++)
          AuctionPriceRow(
            rank: i + 1,
            item: limited.reversed.toList()[i],
            // -1.0 ~ -7.0% 사이 랜덤 하락률
            changePercent: -(1 + rand.nextDouble() * 6),
          ),
      ];

      _loadingTable = false;
    });
  }

  // 검색 엔터시 검색 결과 모드로 전환
  void _openSearchPage(String value) {
    final q = value.trim();
    if (q.isEmpty) return;

    setState(() {
      _currentQuery = q;
      _showSearchResult = true;
    });
  }

  void _openFavoriteList() {
    Navigator.pushNamed(context, '/auction_favorites');
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
    final Widget body = _showSearchResult
        ? AuctionSearchContent(query: _currentQuery)
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색창
                CustomTextField(
                  hintText: '아이템 이름을 검색하세요',
                  controller: _searchController,
                  onSubmitted: _openSearchPage,
                ),
                const SizedBox(height: 16),

                if (_loadingTable)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // 금일 시세 상승률 TOP
                  AuctionPriceTableContainer(
                    title: '금일 시세 상승률 TOP',
                    rows: _increaseRows,
                    isIncrease: true,
                    onRowTap: (row) => _openDetail(row.item),
                  ),
                  const SizedBox(height: 16),

                  // 금일 시세 하락률 TOP
                  AuctionPriceTableContainer(
                    title: '금일 시세 하락률 TOP',
                    rows: _decreaseRows,
                    isIncrease: false,
                    onRowTap: (row) => _openDetail(row.item),
                  ),
                ],
              ],
            ),
          );

    return Stack(
      children: [
        body,

        // 오른쪽 아래 찜목록 버튼
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: _openFavoriteList,
            child: const Icon(Icons.favorite, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
