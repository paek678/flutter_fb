// lib/core/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fb/features/character/models/ui/detail_stat.dart';

import 'firestore_mappers.dart';

// board
import '../../features/board/model/notice.dart';
import '../../features/board/model/notice_category.dart';

// community
import '../../features/community/model/community_post.dart';
import '../../features/community/model/post_category.dart';
import '../../features/community/model/community_comment.dart';

// auth user
import '../../features/auth/model/app_user.dart';

// auction
import '../../features/auction/models/auction_item.dart' as auction_simple;
import '../../features/auction/models/auction_item_data.dart' as auction_detail;
import 'package:flutter_fb/features/auction/models/item_price.dart';

// character

import '../../features/character/models/domain/character.dart';
import '../../features/character/models/domain/ranking_row.dart';
import '../../features/character/models/domain/character_info.dart';
import '../../features/character/models/domain/character_stats.dart';
import '../../features/character/models/domain/character_detail_stats.dart';
import '../../features/character/models/domain/equipment_item.dart';
import '../../features/character/models/domain/avatar_item.dart';
import '../../features/character/models/domain/buff_item.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1) Notice
  // ---------------------------------------------------------------------------

  static Future<List<Notice>> fetchNotices({
    NoticeCategory? category,
    bool? pinned,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('notices')
        .orderBy('created_at', descending: true);

    if (category != null) {
      q = q.where('notice_type', isEqualTo: noticeCategoryToString(category));
    }
    if (pinned != null) {
      q = q.where('pinned', isEqualTo: pinned);
    }

    final snap = await q.limit(limit).get();
    return noticesFromQuerySnapshot(snap);
  }

  static Future<List<Notice>> searchNoticesByExactTitle(
    String title, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('notices')
        .where('title', isEqualTo: title)
        .limit(limit)
        .get();

    return noticesFromQuerySnapshot(snap);
  }

  static Future<List<Notice>> fetchAllNotices({int limit = 50}) async {
    final snap = await _db
        .collection('notices')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return noticesFromQuerySnapshot(snap);
  }

  static Future<Notice?> getNoticeByNo(int noticeNo) async {
    final snap = await _db
        .collection('notices')
        .where('notice_no', isEqualTo: noticeNo)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return noticeFromFirestoreDoc(snap.docs.first);
  }

  static Future<String> createNotice(Notice notice) async {
    final data = noticeToFirestoreMap(notice);
    final ref = await _db.collection('notices').add(data);
    return ref.id;
  }

  static Future<void> updateNotice(String docId, Notice notice) async {
    final data = noticeToFirestoreMap(notice);
    await _db.collection('notices').doc(docId).update(data);
  }

  static Future<void> deleteNotice(String docId) async {
    await _db.collection('notices').doc(docId).delete();
  }

  // ---------------------------------------------------------------------------
  // 2) CommunityPost / Comment
  // ---------------------------------------------------------------------------

  static Future<List<CommunityPost>> fetchCommunityPosts({
    PostCategory? category,
    String? authorUid,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('boards')
        .orderBy('created_at', descending: true);

    if (category != null) {
      q = q.where('category', isEqualTo: categoryToString(category));
    }
    if (authorUid != null) {
      q = q.where('author_uid', isEqualTo: authorUid);
    }

    final snap = await q.limit(limit).get();
    return communityPostsFromQuerySnapshot(snap);
  }

  static Future<List<CommunityPost>> searchPostsByExactTitle(
    String title, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('boards')
        .where('title', isEqualTo: title)
        .limit(limit)
        .get();

    return communityPostsFromQuerySnapshot(snap);
  }

  static Future<List<CommunityPost>> fetchAllCommunityPosts({
    int limit = 50,
  }) async {
    try {
      final snap = await _db
          .collection('boards')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return communityPostsFromQuerySnapshot(snap);
    } on FirebaseException catch (e, st) {
      print(
        '[fetchAllCommunityPosts] FirebaseException: ${e.code} / ${e.message}',
      );
      print(st);
      rethrow;
    }
  }

  static Future<String> createCommunityPost(CommunityPost post) async {
    final data = communityPostToFirestoreMap(post);
    final ref = await _db.collection('boards').add(data);
    return ref.id;
  }

  static Future<void> updateCommunityPost(
    String docId,
    CommunityPost post,
  ) async {
    final data = communityPostToFirestoreMap(post);
    await _db.collection('boards').doc(docId).update(data);
  }

  static Future<void> deleteCommunityPost(String docId) async {
    await _db.collection('boards').doc(docId).delete();
  }

  static Future<List<CommunityComment>> fetchCommentsForPost(
    String postDocId, {
    int limit = 100,
  }) async {
    final snap = await _db
        .collection('boards')
        .doc(postDocId)
        .collection('comments')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return commentsFromQuerySnapshot(snap);
  }

  static Future<CommunityComment?> getCommentById(
    String postDocId,
    String commentDocId,
  ) async {
    final doc = await _db
        .collection('boards')
        .doc(postDocId)
        .collection('comments')
        .doc(commentDocId)
        .get();

    if (!doc.exists) return null;
    return commentFromFirestoreDoc(doc);
  }

  static Future<String> createCommentForPost(
    String postDocId,
    CommunityComment comment,
  ) async {
    final data = communityCommentToFirestoreMap(comment);
    final ref = await _db
        .collection('boards')
        .doc(postDocId)
        .collection('comments')
        .add(data);
    return ref.id;
  }

  static Future<void> updateCommentForPost(
    String postDocId,
    String commentDocId,
    CommunityComment comment,
  ) async {
    final data = communityCommentToFirestoreMap(comment);
    await _db
        .collection('boards')
        .doc(postDocId)
        .collection('comments')
        .doc(commentDocId)
        .update(data);
  }

  static Future<void> deleteCommentForPost(
    String postDocId,
    String commentDocId,
  ) async {
    await _db
        .collection('boards')
        .doc(postDocId)
        .collection('comments')
        .doc(commentDocId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // 3) AppUser
  // ---------------------------------------------------------------------------

  static Future<AppUser?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return appUserFromFirestoreDoc(doc);
  }

  static Future<List<AppUser>> searchUsersByDisplayName(
    String displayName, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('users')
        .where('display_name', isEqualTo: displayName)
        .limit(limit)
        .get();

    return appUsersFromQuerySnapshot(snap);
  }

  static Future<List<AppUser>> searchUsersByEmail(
    String email, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(limit)
        .get();

    return appUsersFromQuerySnapshot(snap);
  }

  static Future<void> createUser(AppUser user) async {
    final data = appUserToFirestoreMap(user);
    await _db.collection('users').doc(user.uid).set(data);
  }

  static Future<void> updateUser(AppUser user) async {
    final data = appUserToFirestoreMap(user);
    await _db.collection('users').doc(user.uid).update(data);
  }

  static Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ---------------------------------------------------------------------------
  // 4) Auction: listings / item_prices
  // ---------------------------------------------------------------------------

  static Future<List<auction_simple.AuctionItem>> fetchAuctionListingsSimple(
    String itemId, {
    int limit = 50,
  }) async {
    final snap = await _db
        .collection('auction_items')
        .doc(itemId)
        .collection('listings')
        .orderBy('unitPrice')
        .limit(limit)
        .get();

    return auctionSimpleItemsFromQuerySnapshot(snap);
  }

  static Future<List<auction_detail.AuctionItem>> fetchAuctionListingsDetail(
    String itemId, {
    int limit = 50,
  }) async {
    final snap = await _db
        .collection('auction_items')
        .doc(itemId)
        .collection('listings')
        .orderBy('unitPrice')
        .limit(limit)
        .get();

    return auctionDetailItemsFromQuerySnapshot(snap);
  }

  static Future<ItemPrice?> getItemPriceByItemId(String itemId) async {
    final doc = await _db.collection('item_prices').doc(itemId).get();

    if (!doc.exists) return null;
    return itemPriceFromFirestoreDoc(doc);
  }

  static Future<List<ItemPrice>> searchItemPricesByName(
    String name, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('item_prices')
        .where('itemName', isEqualTo: name)
        .limit(limit)
        .get();

    return itemPricesFromQuerySnapshot(snap);
  }

  // ---------------------------------------------------------------------------
  // 4-1) Auction: fetch all auction_items
  // ---------------------------------------------------------------------------

  /// All auction_items with simple listings mapped.
  /// Return: { itemId: List<AuctionItemSimple> }
  static Future<Map<String, List<auction_simple.AuctionItem>>>
  fetchAllAuctionListingsSimple({int perItemLimit = 50}) async {
    final rootSnap = await _db.collection('auction_items').get();

    final Map<String, List<auction_simple.AuctionItem>> result = {};

    for (final doc in rootSnap.docs) {
      final listingsSnap = await doc.reference
          .collection('listings')
          .orderBy('unitPrice')
          .limit(perItemLimit)
          .get();

      result[doc.id] = auctionSimpleItemsFromQuerySnapshot(listingsSnap);
    }

    return result;
  }

  /// All auction_items with detail listings mapped.
  /// Return: { itemId: List<AuctionItemDetail> }
  static Future<Map<String, List<auction_detail.AuctionItem>>>
  fetchAllAuctionListingsDetail({int perItemLimit = 50}) async {
    final rootSnap = await _db.collection('auction_items').get();

    final Map<String, List<auction_detail.AuctionItem>> result = {};

    for (final doc in rootSnap.docs) {
      final listingsSnap = await doc.reference
          .collection('listings')
          .orderBy('unitPrice')
          .limit(perItemLimit)
          .get();

      result[doc.id] = auctionDetailItemsFromQuerySnapshot(listingsSnap);
    }

    return result;
  }

  // --------------------------------------------------
  // 1) 랭킹 미리보기
  // --------------------------------------------------
  static Future<List<RankingRow>> fetchRankingPreview({
    String? server,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('ranking_entries');

    if (server != null) {
      query = query.where('server', isEqualTo: server);
    }

    query = query.orderBy('fame', descending: true).limit(limit);

    final snap = await query.get();
    final docs = snap.docs;

    return List.generate(docs.length, (i) {
      final doc = docs[i];
      final data = doc.data();

      return RankingRow(
        id: doc.id,
        characterId: data['characterId'] as String,
        rank: (data['rank'] as num?)?.toInt() ?? i + 1,
        name: data['name'] as String,
        fame: (data['fame'] as num).toInt(),
        job: data['job'] as String,
      );
    });
  }

  // --------------------------------------------------
  // 2) 캐릭터 검색
  // --------------------------------------------------
  static Future<List<Character>> searchCharacters({
    required String name,
    String? serverId,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('characters');

    query = query.where('name', isEqualTo: name);

    if (serverId != null) {
      query = query.where('serverId', isEqualTo: serverId);
    }

    final snap = await query.get();
    return snap.docs
        .map((doc) => Character.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  // --------------------------------------------------
  // 3) 캐릭터 요약 한 건
  // --------------------------------------------------
  static Future<Character?> fetchCharacterById(String characterId) async {
    final doc = await _db.collection('characters').doc(characterId).get();
    if (!doc.exists) return null;
    return Character.fromJson(doc.data()!, id: doc.id);
  }

  // --------------------------------------------------
  // 4) 캐릭터 상세 (CharacterInfo)
  // --------------------------------------------------
  // core/services/firebase_service.dart

  static Future<CharacterInfo?> fetchCharacterInfoById(
    String characterId,
  ) async {
    final charRef = _db.collection('characters').doc(characterId);
    final charDoc = await charRef.get();

    if (!charDoc.exists) return null;

    final summary = Character.fromJson(charDoc.data()!, id: charDoc.id);

    // ───────────────────────────────── stats / detail_stat ────────────────────────────────

    final basicStatDoc = await charRef
        .collection('basic_stat')
        .doc('latest')
        .get();
    final detailStatDoc = await charRef
        .collection('detail_stat')
        .doc('latest')
        .get();

    CharacterStats stats = const CharacterStats.empty();
    if (basicStatDoc.exists) {
      final data = basicStatDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      final statusList = raw['status'] as List<dynamic>? ?? [];

      stats = CharacterStats.fromStatusList(statusList);
    }

    CharacterDetailStats detailStats = const CharacterDetailStats.empty();
    List<DetailStat> extraDetailStats = const []; // ✅ 타입 수정

    if (detailStatDoc.exists) {
      final data = detailStatDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      // 메인 숫자 세부 스탯
      detailStats = CharacterDetailStats.fromJson(raw);

      // 추가 라인들 (name / value 문자열)
      final extra = raw['extra'] as List<dynamic>? ?? [];
      extraDetailStats = extra.map((e) {
        final m = e as Map<String, dynamic>;
        return DetailStat(
          name: m['name'] as String? ?? '',
          value: m['value'] as String? ?? '',
        );
      }).toList(); // ✅ cast 필요 없음
    }

    // ───────────────────────────────── equip ────────────────────────────────

    final equipDoc = await charRef.collection('equip').doc('latest').get();
    List<EquipmentItem> equipments = const [];

    if (equipDoc.exists) {
      final data = equipDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      // 네플 API 구조가 보통 이런 식이라 가정:
      // raw['equipment'] = [ {...}, {...} ]
      final list = raw['equipment'] as List<dynamic>? ?? [];

      equipments = list.map((e) {
        final m = e as Map<String, dynamic>;
        return EquipmentItem(
          category: m['slotName'] as String? ?? '', // 예: "상의", "무기"
          imagePath: m['itemImage'] as String? ?? '',
          name: m['itemName'] as String? ?? '',
          grade: m['itemRarity'] as String? ?? '',
          option: (m['reinforce'] != null) ? '+${m['reinforce']} 강화' : '',
          desc: m['explain'] as String? ?? '',
        );
      }).toList();
    }

    // ───────────────────────────────── avatar + creature ────────────────────────────────

    final avatarDoc = await charRef.collection('avatar').doc('latest').get();
    final creatureDoc = await charRef
        .collection('creature')
        .doc('latest')
        .get();

    List<AvatarItem> avatars = [];

    if (avatarDoc.exists) {
      final raw = avatarDoc.data()?['raw'] as Map<String, dynamic>? ?? {};
      final list = raw['avatar'] as List<dynamic>? ?? [];

      avatars.addAll(
        list.map((e) {
          final m = e as Map<String, dynamic>;

          // 이미지 한 장만 써도 되니까 List<String>으로 감싸줌
          final image = m['itemImage'] as String? ?? '';

          // 엠블렘 이름들을 desc에 합쳐 넣고 싶으면
          final emblems = m['emblems'] as List<dynamic>? ?? [];
          final emblemText = emblems
              .map(
                (em) =>
                    (em as Map<String, dynamic>)['itemName'] as String? ?? '',
              )
              .where((s) => s.isNotEmpty)
              .join(', ');

          return AvatarItem(
            category: m['slotName'] as String? ?? '',
            images: [image], // ✅ List<String>
            name: m['itemName'] as String? ?? '',
            option: m['optionAbility'] as String? ?? '',
            desc: emblemText, // or itemRarity, 네 맘대로
          );
        }),
      );
    }

    if (creatureDoc.exists) {
      final raw = creatureDoc.data()?['raw'] as Map<String, dynamic>? ?? {};
      final creature = raw['creature'] as Map<String, dynamic>?;

      if (creature != null) {
        avatars.add(
          AvatarItem(
            category: '크리쳐',
            images: [creature['itemImage'] as String? ?? ''], // 있으면 채우고
            name: creature['itemName'] as String? ?? '',
            desc: creature['itemRarity'] as String? ?? '',
            option: creature['optionAbility'] as String? ?? '',
          ),
        );
      }
    }

    // ───────────────────────────────── buff_* ────────────────────────────────

    final buffAvatarDoc = await charRef
        .collection('buff_avatar')
        .doc('latest')
        .get();
    final buffEquipDoc = await charRef
        .collection('buff_equip')
        .doc('latest')
        .get();
    final buffCreatureDoc = await charRef
        .collection('buff_creature')
        .doc('latest')
        .get();

    List<BuffItem> buffItems = [];

    void addBuffFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String categoryLabel,
    ) {
      if (!doc.exists) return;
      final raw = doc.data()?['raw'] as Map<String, dynamic>? ?? {};

      // 예: raw['equipment'], raw['avatar'] 등 각자 구조에 맞게
      final list =
          (raw['equipment'] ?? raw['avatar'] ?? raw['creature'])
              as List<dynamic>? ??
          [];

      buffItems.addAll(
        list.map((e) {
          final m = e as Map<String, dynamic>;
          return BuffItem(
            category: categoryLabel,
            imagePath: '',
            name: m['itemName'] as String? ?? '',
            grade: m['itemRarity'] as String? ?? '',
            option: m['optionAbility'] as String? ?? '',
          );
        }),
      );
    }

    addBuffFromDoc(buffEquipDoc, '버프 장비');
    addBuffFromDoc(buffAvatarDoc, '버프 아바타');
    addBuffFromDoc(buffCreatureDoc, '버프 크리쳐');

    // ───────────────────────────────── CharacterInfo 조립 ────────────────────────────────

    return CharacterInfo(
      summary: summary,
      stats: stats,
      detailStats: detailStats,
      extraDetailStats: extraDetailStats,
      equipments: equipments,
      avatars: avatars,
      buffItems: buffItems,
    );
  }
}
