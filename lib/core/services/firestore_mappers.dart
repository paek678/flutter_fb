// lib/core/services/firestore_mappers.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── board 쪽 공지 모델 ──
import '../../features/board/model/notice.dart';
import '../../features/board/model/notice_category.dart';

// ── community 쪽 게시글 모델 ──
import '../../features/community/model/community_post.dart';
import '../../features/community/model/post_category.dart';
import '../../features/community/model/community_comment.dart';

// ── auth 쪽 유저 모델 ──
import '../../features/auth/model/app_user.dart';

// ── character 랭킹 모델 ──
import '../../features/character/models/domain/ranking_row.dart';

// ── auction(경매) 관련 모델 ──
import '../../features/auction/models/auction_item.dart' as auction_simple;
import '../../features/auction/models/auction_item_data.dart' as auction_detail;
import 'package:flutter_fb/features/auction/models/item_price.dart';

// PriceRange 문자열을 enum으로 변환
auction_detail.PriceRange? _rangeFromKey(String key) {
  switch (key) {
    case 'd7':
      return auction_detail.PriceRange.d7;
    case 'd14':
      return auction_detail.PriceRange.d14;
    case 'd30':
      return auction_detail.PriceRange.d30;
    case 'd90':
      return auction_detail.PriceRange.d90;
    case 'd365':
      return auction_detail.PriceRange.d365;
  }
  return null;
}

// history 배열을 우선순위(긴 구간 우선)대로 최대 5개까지 매핑
Map<auction_detail.PriceRange, List<double>> _historyFromArray(
  List<dynamic>? raw,
) {
  if (raw == null) return const {};

  const order = <auction_detail.PriceRange>[
    auction_detail.PriceRange.d365,
    auction_detail.PriceRange.d90,
    auction_detail.PriceRange.d30,
    auction_detail.PriceRange.d14,
    auction_detail.PriceRange.d7,
  ];

  final temp = <auction_detail.PriceRange, List<double>>{};
  for (final e in raw) {
    if (e is! Map) continue;
    final key = e['range']?.toString() ?? '';
    final range = _rangeFromKey(key);
    if (range == null) continue;

    final list = (e['values'] as List?)
            ?.map((v) => (v as num).toDouble())
            .toList() ??
        const <double>[];

    temp[range] = list;
  }

  final entries = order
      .where(temp.containsKey)
      .take(5)
      .map((r) => MapEntry(r, temp[r]!));

  return Map<auction_detail.PriceRange, List<double>>.fromEntries(entries);
}

// 최근 가격 리스트(최신순 가정)을 PriceRange 순서(d7 -> d365)로 최대 5개까지 매핑
Map<auction_detail.PriceRange, List<double>> _historyFromRecentPrices(
  List<dynamic>? raw,
) {
  if (raw == null) return const {};

  final values = raw
      .map((e) {
        if (e is num) return e.toDouble();
        return double.tryParse(e.toString());
      })
      .whereType<double>()
      .toList();

  if (values.isEmpty) return const {};

  const ranges = <auction_detail.PriceRange>[
    auction_detail.PriceRange.d7,
    auction_detail.PriceRange.d14,
    auction_detail.PriceRange.d30,
    auction_detail.PriceRange.d90,
    auction_detail.PriceRange.d365,
  ];

  final count = min(values.length, ranges.length);
  final entries = List.generate(
    count,
    (i) => MapEntry(ranges[i], <double>[values[i]]),
  );

  return Map<auction_detail.PriceRange, List<double>>.fromEntries(entries);
}

// ─────────────────────────────────────────────
// 1) Notice(공지) 매퍼
// ─────────────────────────────────────────────

/// Map Firestore data for `notices` collection to Notice model.
Notice noticeFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final int id = (data['notice_no'] ?? 0) as int;

  final String title = (data['title'] ?? '') as String;
  final String content = (data['content'] ?? '') as String;

  final String author =
      (data['author_name'] ?? data['author'] ?? '운영팀') as String;

  final Timestamp? tsCreated = data['created_at'] as Timestamp?;
  final DateTime createdAt =
      tsCreated != null ? tsCreated.toDate() : DateTime.now();

  final String rawCategory =
      (data['notice_type'] ?? data['category'] ?? 'general') as String;
  final NoticeCategory category = noticeCategoryFromString(rawCategory);

  final bool pinned =
      (data['pinned'] ?? data['is_pinned'] ?? false) as bool;

  final int views = (data['view_count'] ?? data['views'] ?? 0) as int;

  final int commentCount = (data['comment_count'] ?? 0) as int;

  return Notice(
    id: id,
    title: title,
    content: content,
    author: author,
    createdAt: createdAt,
    category: category,
    pinned: pinned,
    views: views,
    commentCount: commentCount,
  );
}

// ─────────────────────────────────────────────
// 2) CommunityPost(boards 컬렉션) 매퍼
// ─────────────────────────────────────────────

/// Map Firestore data for `boards` collection to CommunityPost model.
CommunityPost communityPostFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final int id = (data['post_no'] ?? 0) as int;

  final String title = (data['title'] ?? '') as String;
  final String content = (data['content'] ?? '') as String;

  final String author =
      (data['author_name'] ?? data['author'] ?? '익명') as String;

  final Timestamp? tsCreated = data['created_at'] as Timestamp?;
  final DateTime createdAt =
      tsCreated != null ? tsCreated.toDate() : DateTime.now();

  final String rawCategory = (data['category'] ?? 'general') as String;
  final PostCategory category = categoryFromString(rawCategory);

  final int views = (data['view_count'] ?? data['views'] ?? 0) as int;
  final int commentCount = (data['comment_count'] ?? 0) as int;
  final int likes = (data['like_count'] ?? data['likes'] ?? 0) as int;

  return CommunityPost(
    id: id,
    docId: doc.id, // Firestore 문서 ID
    title: title,
    content: content,
    author: author,
    createdAt: createdAt,
    category: category,
    views: views,
    commentCount: commentCount,
    likes: likes,
  );
}

// ─────────────────────────────────────────────
// 3) CommunityComment 매퍼
// ─────────────────────────────────────────────

CommunityComment commentFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  return CommunityComment(
    id: (data['id'] ?? 0) as int,
    postId: (data['post_id'] ?? 0) as int,
    author: (data['author'] ?? '익명') as String,
    content: (data['content'] ?? '') as String,
    createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    likes: (data['likes'] ?? 0) as int,
  );
}

// ─────────────────────────────────────────────
// 4) AppUser 매퍼
// ─────────────────────────────────────────────

/// Map Firestore data for `users` collection to AppUser model.
AppUser appUserFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final String uid = (data['uid'] ?? doc.id) as String;
  final String? email = data['email'] as String?;

  final String displayName =
      (data['display_name'] ?? data['displayName'] ?? 'User') as String;

  final String provider = (data['provider'] ?? 'unknown') as String;
  final String role = (data['role'] ?? 'user') as String;

  final Timestamp? tsCreated = data['created_at'] as Timestamp?;
  final Timestamp? tsLastLogin = data['last_login_at'] as Timestamp?;
  final Timestamp? tsLastAction = data['last_action_at'] as Timestamp?;
  final List<dynamic> favRaw = data['favorites'] as List<dynamic>? ?? const [];
  final Set<int> favorites = favRaw
      .whereType<num>()
      .map((e) => e.toInt())
      .toSet();

  final DateTime createdAt =
      tsCreated != null ? tsCreated.toDate() : DateTime.now();
  final DateTime? lastLoginAt = tsLastLogin?.toDate();
  final DateTime? lastActionAt = tsLastAction?.toDate();

  return AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    provider: provider,
    role: role,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
    lastActionAt: lastActionAt,
    favorites: favorites,
  );
}

// ---------------------------------------------------------------------------
// 5) Character RankingRow 매퍼
// ---------------------------------------------------------------------------

RankingRow rankingRowFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  return RankingRow(
    id: (data['id'] ?? doc.id) as String,
    characterId: (data['characterId'] ?? '') as String,
    serverId: (data['serverId'] ?? data['server'] ?? '') as String,
    rank: (data['rank'] as num?)?.toInt() ?? 0,
    name: (data['name'] ?? '') as String,
    fame: (data['fame'] as num?)?.toInt() ?? 0,
    job: (data['job'] ?? '') as String,
    jobGrowName: (data['jobGrowName'] ?? '') as String,
    level: (data['level'] as num?)?.toInt() ?? 0,
    imagePath: (data['imagePath'] ?? '') as String,
  );
}

List<RankingRow> rankingRowsFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(rankingRowFromFirestoreDoc).toList();
}

// ─────────────────────────────────────────────
// 6) QuerySnapshot → List<모델> 헬퍼들
// ─────────────────────────────────────────────

/// QuerySnapshot → List<Notice>
List<Notice> noticesFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(noticeFromFirestoreDoc).toList();
}

/// QuerySnapshot → List<CommunityPost>
List<CommunityPost> communityPostsFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(communityPostFromFirestoreDoc).toList();
}

List<CommunityComment> commentsFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(commentFromFirestoreDoc).toList();
}

/// QuerySnapshot → List<AppUser>
List<AppUser> appUsersFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(appUserFromFirestoreDoc).toList();
}

// ─────────────────────────────────────────────
// 7) 🔽 경매 관련 매퍼들
// ─────────────────────────────────────────────

String? _extractStringStatus(
  List<dynamic>? statuses,
  String keyword,
) {
  if (statuses == null) return null;

  for (final dynamic e in statuses) {
    if (e is Map<String, dynamic>) {
      final String name = (e['name'] ?? '') as String;
      if (name.contains(keyword)) {
        final dynamic v = e['value'];
        return v?.toString();
      }
    }
  }
  return null;
}

double? _parseWeightKg(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.\\-]'), '');
  return double.tryParse(cleaned);
}

/// Firestore auction_items/{itemId}/listings/{auctionNo}
/// → 간단 리스트용 AuctionItem (id, name, price, seller?, imagePath?)
auction_simple.AuctionItem auctionSimpleItemFromListingDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final int id = (data['auctionId'] ?? 0) as int;
  final String name = (data['itemName'] ?? '') as String;

  // unitPrice가 단가이므로 이것을 price로 사용
  final int price = (data['unitPrice'] ?? data['price'] ?? 0) as int;

  final String? seller = data['seller'] as String?;
  final String? imagePath = data['imagePath'] as String?;

  return auction_simple.AuctionItem(
    id: id,
    name: name,
    price: price,
    seller: seller,
    imagePath: imagePath,
  );
}

/// QuerySnapshot → List<간단 AuctionItem>
List<auction_simple.AuctionItem> auctionSimpleItemsFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(auctionSimpleItemFromListingDoc).toList();
}

/// itemStatus 리스트에서 특정 스탯 추출용 헬퍼
int _extractStatusValue(
  List<dynamic>? statuses,
  String keyword,
) {
  if (statuses == null) return 0;

  for (final dynamic e in statuses) {
    if (e is Map<String, dynamic>) {
      final String name = (e['name'] ?? '') as String;
      if (name.contains(keyword)) {
        final num? v = e['value'] as num?;
        if (v != null) {
          return v.toInt();
        }
      }
    }
  }
  return 0;
}

/// itemRarity(예: '레전더리', '유니크', '레어') → RarityCode
auction_detail.RarityCode _rarityCodeFromRaw(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('레전더리') || s.contains('legendary')) {
    return auction_detail.RarityCode.legendary;
  }
  if (s.contains('유니크') || s.contains('unique')) {
    return auction_detail.RarityCode.unique;
  }
  return auction_detail.RarityCode.rare;
}

/// itemExplainDetail을 줄바꿈 기준으로 옵션 리스트로 분해
List<String> _extractOptions(dynamic rawExplainDetail) {
  if (rawExplainDetail == null) return const <String>[];
  final text = rawExplainDetail.toString().trim();
  if (text.isEmpty) return const <String>[];

  final lines = text.split('\n');
  return lines
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Firestore auction_items/{itemId}/listings/{auctionNo}
/// → 상세 화면용 AuctionItem (AttackStats, 옵션 포함, history는 빈 {}로)
auction_detail.AuctionItem auctionDetailItemFromListingDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final String name = (data['itemName'] ?? '') as String;
  final String rarity = (data['itemRarity'] ?? '') as String;
  final auction_detail.RarityCode rarityCode = _rarityCodeFromRaw(rarity);

  final String type = (data['itemType'] ?? '') as String;
  final String subType = (data['itemTypeDetail'] ?? '') as String;
  final int levelLimit =
      (data['itemAvailableLevel'] ?? 0) as int;

  // itemStatus에서 공격력/지능 값 추출
  final List<dynamic>? itemStatus =
      data['itemStatus'] as List<dynamic>?;

  final int physical = _extractStatusValue(itemStatus, '물리');
  final int magical = _extractStatusValue(itemStatus, '마법');
  final int independent = _extractStatusValue(itemStatus, '독립');
  final int intelligence = _extractStatusValue(itemStatus, '지능');

  final attack = auction_detail.AttackStats(
    physical: physical,
    magical: magical,
    independent: independent,
  );

  // 전투력은 일단 fame을 그대로 사용
  final int combatPower = (data['fame'] ?? 0) as int;

  // 옵션은 itemExplainDetail에서 줄바꿈 기준으로 나누기
  final List<String> options =
      _extractOptions(data['itemExplainDetail'] ?? data['itemExplain']);

  final String imagePath = (data['imagePath'] ?? '') as String;

  final String? durability = _extractStringStatus(itemStatus, '내구도');
  final double? weightKg =
      _parseWeightKg(_extractStringStatus(itemStatus, '무게'));

  final Map<auction_detail.PriceRange, List<double>> historyFromDoc =
      _historyFromArray(data['history'] as List<dynamic>?);
  final dynamic recentRaw = data['recentPrices'] ?? data['recentUnitPrices'];

  // history 배열을 우선순위대로 최대 5개까지 매핑
  final Map<auction_detail.PriceRange, List<double>> history =
      historyFromDoc.isNotEmpty
          ? historyFromDoc
          : _historyFromRecentPrices(
              recentRaw is List ? recentRaw : null,
            );

  return auction_detail.AuctionItem(
    name: name,
    rarity: rarity,
    rarityCode: rarityCode,
    type: type,
    subType: subType,
    levelLimit: levelLimit,
    attack: attack,
    intelligence: intelligence,
    combatPower: combatPower,
    options: options,
    imagePath: imagePath,
    weightKg: weightKg,
    durability: durability,
    history: history,
  );
}

/// QuerySnapshot → List<상세 AuctionItem>
List<auction_detail.AuctionItem> auctionDetailItemsFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(auctionDetailItemFromListingDoc).toList();
}

/// Firestore item_prices/{itemId} → ItemPrice
ItemPrice itemPriceFromFirestoreDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? <String, dynamic>{};

  final String itemId = (data['itemId'] ?? doc.id) as String;
  final String name =
      (data['itemName'] ?? data['name'] ?? '') as String;
  final int avgPrice = (data['avgPrice'] as num?)?.toInt() ?? 0;
  final String trend = (data['trend'] ?? '0.0%') as String;
  final int? lastPrice = (data['lastPrice'] as num?)?.toInt();
  final int? prevPrice = (data['prevPrice'] as num?)?.toInt();
  final List<int> recentUnitPrices =
      (data['recentUnitPrices'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[];

  final Timestamp? tsLatestSoldAt = data['latestSoldAt'] as Timestamp?;
  final Timestamp? tsUpdatedAt = data['updatedAt'] as Timestamp?;

  return ItemPrice(
    itemId: itemId,
    name: name,
    avgPrice: avgPrice,
    trend: trend,
    lastPrice: lastPrice,
    prevPrice: prevPrice,
    recentUnitPrices: recentUnitPrices,
    latestSoldAt: tsLatestSoldAt?.toDate(),
    updatedAt: tsUpdatedAt?.toDate(),
  );
}

/// QuerySnapshot → List<ItemPrice>
List<ItemPrice> itemPricesFromQuerySnapshot(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs.map(itemPriceFromFirestoreDoc).toList();
}

// ─────────────────────────────────────────────
// 8) 모델 → Firestore Map (Create / Update 용)
// ─────────────────────────────────────────────

Map<String, dynamic> noticeToFirestoreMap(Notice n) {
  return {
    'notice_no': n.id,
    'title': n.title,
    'content': n.content,
    'author_name': n.author,
    'created_at': n.createdAt,
    'notice_type': noticeCategoryToString(n.category),
    'pinned': n.pinned,
    'view_count': n.views,
    'comment_count': n.commentCount,
  };
}

Map<String, dynamic> communityPostToFirestoreMap(CommunityPost p) {
  return {
    'post_no': p.id,
    'title': p.title,
    'content': p.content,
    'author_name': p.author,
    'created_at': p.createdAt,
    'category': categoryToString(p.category),
    'view_count': p.views,
    'comment_count': p.commentCount,
    'like_count': p.likes,
  };
}

Map<String, dynamic> communityCommentToFirestoreMap(CommunityComment c) {
  return {
    'id': c.id,
    'post_id': c.postId,
    'author': c.author,
    'content': c.content,
    'created_at': c.createdAt,
    'likes': c.likes,
  };
}

Map<String, dynamic> appUserToFirestoreMap(AppUser u) {
  return {
    'uid': u.uid,
    'email': u.email,
    'display_name': u.displayName,
    'provider': u.provider,
    'role': u.role,
    'created_at': u.createdAt,
    'last_login_at': u.lastLoginAt,
    'last_action_at': u.lastActionAt,
    'favorites': u.favorites.toList(),
  };
}
