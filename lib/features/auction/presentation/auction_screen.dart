import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/services/firebase_service.dart';

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

  // Firestore 기반 레포지토리 (추후 필요 시 메모리 fallback 처리 예정)
  final FirestoreAuctionRepository _repo = FirestoreAuctionRepository();

  // 상승 / 하락 리스트
  List<AuctionPriceRow> _increaseRows = [];
  List<AuctionPriceRow> _decreaseRows = [];
  bool _loadingTable = true;

  // 검색 결과 화면 표시 여부
  bool _showSearchResult = false;
  String _currentQuery = '';
  bool _preloadedRepo = false;

  @override
  void initState() {
    super.initState();
    _preloadRepo();
    // 경매 시세 테이블을 미리 로드해서 구성 (초기 진입 시 한 번만 호출)
    _loadPriceRows();
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

  double? _parseTrendToDouble(String? trend) {
    if (trend == null || trend.trim().isEmpty) return null;
    final cleaned = trend.replaceAll('%', '').trim();
    return double.tryParse(cleaned);
  }

  Future<void> _loadPriceRows() async {
    setState(() => _loadingTable = true);

    final items = await _repo.fetchItems();
    final prices = await _repo.fetchPrices();
    if (!mounted) return;

    if (items.isEmpty) {
      setState(() {
        _increaseRows = [];
        _decreaseRows = [];
        _loadingTable = false;
      });
      return;
    }

    final priceMap = {for (final p in prices) p.itemId: p};

    final parsedRows = <AuctionPriceRow>[];
    for (final item in items) {
      final trendString =
          item.itemPrice?.trend ?? priceMap[item.id.toString()]?.trend;
      final trendValue = _parseTrendToDouble(trendString);
      if (trendValue == null) continue;

      parsedRows.add(
        AuctionPriceRow(
          rank: 0,
          item: item,
          changePercent: trendValue,
        ),
      );
    }

    if (parsedRows.isEmpty) {
      setState(() {
        _increaseRows = [];
        _decreaseRows = [];
        _loadingTable = false;
      });
      return;
    }

    final incRows = parsedRows
        .where((row) => row.changePercent >= 0)
        .toList()
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));

    final decRows = parsedRows
        .where((row) => row.changePercent < 0)
        .toList()
      ..sort((a, b) => a.changePercent.compareTo(b.changePercent));

    List<AuctionPriceRow> buildTopFive(List<AuctionPriceRow> source) {
      final limited = source.take(5).toList();
      return [
        for (int i = 0; i < limited.length; i++)
          AuctionPriceRow(
            rank: i + 1,
            item: limited[i].item,
            changePercent: limited[i].changePercent,
          ),
      ];
    }

    setState(() {
      _increaseRows = buildTopFive(incRows);
      _decreaseRows = buildTopFive(decRows);
      _loadingTable = false;
    });
  }

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
    final bool canOpenFavorites = FirestoreService.currentUser != null;
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
                  // 금일 시세 상승 TOP
                  AuctionPriceTableContainer(
                    title: '금일 시세 상승 TOP',
                    rows: _increaseRows,
                    isIncrease: true,
                    onRowTap: (row) => _openDetail(row.item),
                  ),
                  const SizedBox(height: 16),

                  // 금일 시세 하락 TOP
                  AuctionPriceTableContainer(
                    title: '금일 시세 하락 TOP',
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
        if (canOpenFavorites)
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
