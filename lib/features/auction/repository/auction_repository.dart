import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../core/services/firebase_service.dart';
import '../models/auction_item.dart';
import '../models/item_price.dart';

// ✅ 하드코딩 데이터(Dart) - kAuctionItems, RarityCode 등
import '../models/auction_item_data.dart' as data;

/// ─────────────────────────────────────────────────────────────────
/// 레포지토리 인터페이스
/// ─────────────────────────────────────────────────────────────────
abstract class AuctionRepository {
  Future<List<AuctionItem>> fetchItems({String query});
  Future<AuctionItem?> getItemById(int id);

  Future<List<ItemPrice>> fetchPrices();

  Future<void> toggleFavorite(int itemId);
  Future<List<AuctionItem>> fetchFavorites();
  Future<bool> isFavorite(int itemId);

  /// 📈 아이템 이름 기준 시세(가격) 시리즈를 구간별로 반환 (y값 리스트)
  /// - data.kAuctionItems 의 history[range] 를 우선 사용
  /// - 없으면 길이만 맞춰 랜덤 워크로 보완
  Future<List<double>> fetchPriceSeries(
    String itemName, {
    required data.PriceRange range,
  });

  /// (옵션) 아이템 id 기준 헬퍼
  Future<List<double>> fetchPriceSeriesById(
    int itemId, {
    required data.PriceRange range,
  });
}

/// ─────────────────────────────────────────────────────────────────
/// 메모리 기반 구현체 (data → 화면 모델 매핑) - ✅ 싱글톤 적용
/// ─────────────────────────────────────────────────────────────────
class InMemoryAuctionRepository implements AuctionRepository {
  // ✅ 1) private 생성자
  InMemoryAuctionRepository._internal() {
    _items = _buildItemsFromData();
    _prices = _buildPricesFromItems(_items);
  }

  // ✅ 2) static 인스턴스
  static final InMemoryAuctionRepository _instance =
      InMemoryAuctionRepository._internal();

  // ✅ 3) factory 생성자: 어디서든 InMemoryAuctionRepository() 호출하면 이 인스턴스 반환
  factory InMemoryAuctionRepository() => _instance;

  late final List<AuctionItem> _items;
  late final List<ItemPrice> _prices;
  final Set<int> _favorites = <int>{};

  // ----------------- 내부: data → 화면 모델 매핑 -----------------

  List<AuctionItem> _buildItemsFromData() {
    // data.kAuctionItems 를 화면에서 쓰는 AuctionItem(id, name, price, seller, imagePath)로 변환
    final rnd = Random(7); // deterministic (앱 재시작해도 동일)
    return List.generate(data.kAuctionItems.length, (i) {
      final src = data.kAuctionItems[i];

      // 간단한 가격 산식(임의): 공격스탯 합 × 등급계수 × (레벨/100)
      final atkSum =
          src.attack.physical + src.attack.magical + src.attack.independent;

      final rarityMul = switch (src.rarityCode) {
        data.RarityCode.legendary => 20,
        data.RarityCode.unique => 12,
        data.RarityCode.rare => 8,
      };

      final estPrice =
          (atkSum * rarityMul * (src.levelLimit / 100)).round() * 10;

      // 가짜 판매자 (deterministic)
      final seller =
          'Seller${(i + 1).toString().padLeft(2, '0')} • Lv.${src.levelLimit}';

      return AuctionItem(
        id: i + 1,
        name: src.name,
        price: estPrice + rnd.nextInt(500), // 약간 가감
        seller: seller,
        imagePath: src.imagePath, // ✅ 썸네일 경로 전달
        rarity: src.rarity,
        rarityCode: src.rarityCode,
        type: src.type,
        subType: src.subType,
        levelLimit: src.levelLimit,
        attack: src.attack,
        intelligence: src.intelligence,
        combatPower: src.combatPower,
        options: src.options,
        weightKg: src.weightKg,
        durability: src.durability,
        history: src.history,
      );
    });
  }

  List<ItemPrice> _buildPricesFromItems(List<AuctionItem> items) {
    // 평균가/변동률을 간단히 생성(아이디 기반 결정적)
    String trendFor(int id) {
      final k = id % 3;
      if (k == 0) return '-0.8%';
      if (k == 1) return '+0.6%';
      return '+1.5%';
    }

    return items
        .map((e) => ItemPrice(
              itemId: e.id.toString(),
              name: e.name,
              avgPrice: (e.price * 0.97).round(),
              trend: trendFor(e.id),
            ))
        .toList();
  }

  // ----------------- 인터페이스 구현 -----------------

  @override
  Future<List<AuctionItem>> fetchItems({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (query.trim().isEmpty) return List<AuctionItem>.from(_items);
    final q = query.toLowerCase();
    return _items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<AuctionItem?> getItemById(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ItemPrice>> fetchPrices() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<ItemPrice>.from(_prices);
  }

  @override
  Future<void> toggleFavorite(int itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // 현재 찜 상태
    final wasFavorite = _favorites.contains(itemId);

    // 1) 찜 Set 갱신
    if (wasFavorite) {
      _favorites.remove(itemId);
    } else {
      _favorites.add(itemId);
    }

    // 2) _items 리스트 안 실제 아이템의 isFavorite 값도 동기화
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      final oldItem = _items[index];
      _items[index] = oldItem.copyWith(
        isFavorite: !wasFavorite, // true <-> false 토글
      );
    }
  }

  @override
  Future<List<AuctionItem>> fetchFavorites() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _items.where((e) => _favorites.contains(e.id)).toList();
  }

  @override
  Future<bool> isFavorite(int itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _favorites.contains(itemId);
  }

  // ----------------- 📈 시세 시리즈 -----------------

  @override
  Future<List<double>> fetchPriceSeries(
    String itemName, {
    required data.PriceRange range,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    // 1) 데이터에서 이름으로 매칭
    final src = data.kAuctionItems.cast<data.AuctionItem?>().firstWhere(
      (e) => e?.name == itemName,
      orElse: () => null,
    );

    List<double> series = const [];

    // 2) 있으면 history에서 꺼냄
    if (src != null && src.history.containsKey(range)) {
      series = src.history[range]!;
    }

    // 3) 없으면 fallback: 구간 길이에 맞춰 랜덤 워크 생성(결정적)
    if (series.isEmpty) {
      final length = switch (range) {
        data.PriceRange.d7 => 7,
        data.PriceRange.d14 => 14,
        data.PriceRange.d30 => 30,
        data.PriceRange.d90 => 45, // 성능 고려 샘플
        data.PriceRange.d365 => 90, // 성능 고려 샘플
      };

      final seed =
          itemName.codeUnits.fold<int>(0, (a, b) => a + b) + range.index;
      final rnd = Random(seed);

      // 대략 기준가(이름 기반 고정) + 소폭 변동
      final base = 6000 + rnd.nextInt(4000); // 6000~9999
      double cur = base * (0.95 + rnd.nextDouble() * 0.1);
      final List<double> gen = [];
      for (int i = 0; i < length; i++) {
        final drift = (rnd.nextDouble() * 0.06) - 0.03; // -3% ~ +3%
        cur = (cur * (1 + drift)).clamp(base * 0.6, base * 1.4);
        gen.add(cur.roundToDouble());
      }
      series = gen;
    }

    return series;
  }

  @override
  Future<List<double>> fetchPriceSeriesById(
    int itemId, {
    required data.PriceRange range,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) return const [];
    return fetchPriceSeries(item.name, range: range);
  }
}

/// Firestore 데이터를 가져와 캐싱하는 구현체 (없을 경우 인메모리 fallback)
class FirestoreAuctionRepository implements AuctionRepository {
  FirestoreAuctionRepository._internal({int perItemLimit = 30})
      : _perItemLimit = perItemLimit;

  static final FirestoreAuctionRepository _instance =
      FirestoreAuctionRepository._internal();

  factory FirestoreAuctionRepository({int perItemLimit = 30}) {
    _instance._perItemLimit = perItemLimit;
    return _instance;
  }

  final InMemoryAuctionRepository _fallback = InMemoryAuctionRepository();

  List<AuctionItem> _items = <AuctionItem>[];
  final Map<String, Map<data.PriceRange, List<double>>> _historyByName = {};
  final Map<String, ItemPrice> _priceByItemId = {};
  final Set<int> _favorites = <int>{};
  bool _loaded = false;
  int _perItemLimit;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    debugPrint('[AuctionRepo] Loading auction listings from Firestore...');

    // item_prices 전체 로드
    final prices = await FirestoreService.fetchAllItemPrices();
    _priceByItemId
      ..clear()
      ..addEntries(prices.map((p) => MapEntry(p.itemId, p)));

    // 전체 auction_items/{itemId}/listings 로드 (unitPrice 오름차순)
    final allSimple =
        await FirestoreService.fetchAllAuctionListingsSimple(
      perItemLimit: _perItemLimit,
    );
    final allDetail =
        await FirestoreService.fetchAllAuctionListingsDetail(
      perItemLimit: _perItemLimit,
    );

    final List<AuctionItem> items = [];
    _historyByName.clear();
    for (final entry in allSimple.entries) {
      final simpleListings = entry.value;
      if (simpleListings.isEmpty) continue;
      final simpleFirst = simpleListings.first; // 최저가

      final detailListings = allDetail[entry.key];
      final data.AuctionItem? detailFirst =
          (detailListings != null && detailListings.isNotEmpty)
              ? detailListings.first
              : null;

      // history 수집
      if (detailFirst != null && detailFirst.history.isNotEmpty) {
        _historyByName[detailFirst.name] = detailFirst.history;
      }

      final isFav = _favorites.contains(simpleFirst.id);
      final itemPrice = _priceByItemId[entry.key];

      items.add(
        simpleFirst.copyWith(
          isFavorite: isFav,
          itemPrice: itemPrice,
          rarity: detailFirst?.rarity,
          rarityCode: detailFirst?.rarityCode,
          type: detailFirst?.type,
          subType: detailFirst?.subType,
          levelLimit: detailFirst?.levelLimit,
          attack: detailFirst?.attack,
          intelligence: detailFirst?.intelligence,
          combatPower: detailFirst?.combatPower,
          options: detailFirst?.options,
          weightKg: detailFirst?.weightKg,
          durability: detailFirst?.durability,
          history: detailFirst?.history,
          imagePath: detailFirst?.imagePath ?? simpleFirst.imagePath,
          // name/price/seller/id는 simpleFirst 기반
        ),
      );
    }
    _items = items;

    _loaded = true;

    debugPrint(
      '[AuctionRepo] Loaded items=${_items.length}, history=${_historyByName.length}',
    );
    if (_items.isNotEmpty) {
      final buf = StringBuffer();
      buf.writeln('[AuctionRepo] Items detail:');
      for (final e in _items) {
        buf.writeln(
          '  - ${e.toJson()}',
        );
      }
      debugPrint(buf.toString());
    }
    if (_historyByName.isNotEmpty) {
      final buf = StringBuffer();
      buf.writeln('[AuctionRepo] History detail:');
      _historyByName.forEach((name, history) {
        buf.writeln('  * $name');
        history.forEach((range, list) {
          buf.writeln('    - ${range.name}: $list');
        });
      });
      debugPrint(buf.toString());
    }
  }

  List<ItemPrice> _buildPricesFromItems(List<AuctionItem> items) {
    String trendFor(int id) {
      final k = id % 3;
      if (k == 0) return '-0.8%';
      if (k == 1) return '+0.6%';
      return '+1.5%';
    }

    return items
        .map((e) => ItemPrice(
              itemId: e.id.toString(),
              name: e.name,
              avgPrice: (e.price * 0.97).round(),
              trend: trendFor(e.id),
            ))
        .toList();
  }

  @override
  Future<List<AuctionItem>> fetchItems({String query = ''}) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.fetchItems(query: query);
    }

    if (_items.isEmpty) {
      return _fallback.fetchItems(query: query);
    }

    if (query.trim().isEmpty) return List<AuctionItem>.from(_items);
    final q = query.toLowerCase();
    return _items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<AuctionItem?> getItemById(int id) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.getItemById(id);
    }

    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return _fallback.getItemById(id);
    }
  }

  @override
  Future<List<ItemPrice>> fetchPrices() async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.fetchPrices();
    }

    if (_priceByItemId.isNotEmpty) {
      return _priceByItemId.values.toList();
    }

    if (_items.isEmpty) return _fallback.fetchPrices();
    return _buildPricesFromItems(_items);
  }

  @override
  Future<void> toggleFavorite(int itemId) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      // fallback에만 토글
      return _fallback.toggleFavorite(itemId);
    }

    final wasFavorite = _favorites.contains(itemId);
    if (wasFavorite) {
      _favorites.remove(itemId);
    } else {
      _favorites.add(itemId);
    }

    final index = _items.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      final oldItem = _items[index];
      _items[index] = oldItem.copyWith(isFavorite: !wasFavorite);
    }
  }

  @override
  Future<List<AuctionItem>> fetchFavorites() async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.fetchFavorites();
    }

    if (_items.isEmpty) return _fallback.fetchFavorites();
    return _items.where((e) => _favorites.contains(e.id)).toList();
  }

  @override
  Future<bool> isFavorite(int itemId) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.isFavorite(itemId);
    }
    return _favorites.contains(itemId);
  }

  @override
  Future<List<double>> fetchPriceSeries(
    String itemName, {
    required data.PriceRange range,
  }) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return _fallback.fetchPriceSeries(itemName, range: range);
    }

    final hist = _historyByName[itemName];
    final series = hist?[range];
    if (series != null && series.isNotEmpty) {
      return List<double>.from(series);
    }

    // history가 없으면 기존 인메모리 로직으로 대체
    return _fallback.fetchPriceSeries(itemName, range: range);
  }

  @override
  Future<List<double>> fetchPriceSeriesById(
    int itemId, {
    required data.PriceRange range,
  }) async {
    try {
      final item = await getItemById(itemId);
      if (item == null) {
        return _fallback.fetchPriceSeriesById(itemId, range: range);
      }
      return fetchPriceSeries(item.name, range: range);
    } catch (_) {
      return _fallback.fetchPriceSeriesById(itemId, range: range);
    }
  }
}
