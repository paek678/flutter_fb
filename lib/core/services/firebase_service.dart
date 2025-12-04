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
  static AppUser? _currentUser;

  /// 캐싱된 현재 AppUser (Auth 연동 시 세팅).
  static AppUser? get currentUser => _currentUser;

  /// 로그인/로그아웃 시점에 현재 AppUser를 기록/해제한다.
  static void setCurrentUser(AppUser? user) {
    _currentUser = user;
  }

  /// 🔗 네오플 아이템 이미지 URL 생성 헬퍼
  static String _neopleItemImageUrl(String? itemId) {
    if (itemId == null || itemId.isEmpty) return '';
    return 'https://img-api.neople.co.kr/df/items/$itemId';
  }

  // ---------------------------------------------------------------------------
  // 1) Notice
  // ---------------------------------------------------------------------------

  static Future<List<Notice>> fetchNotices({
    NoticeCategory? category,
    bool? pinned,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q =
        _db.collection('notices').orderBy('created_at', descending: true);

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
    Query<Map<String, dynamic>> q =
        _db.collection('boards').orderBy('created_at', descending: true);

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
    return snap.docs
        .map(
          (doc) => commentFromFirestoreDoc(doc)
              .copyWith(docId: doc.id, postDocId: postDocId),
        )
        .toList();
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

  static Future<List<ItemPrice>> fetchAllItemPrices({
    int limit = 500,
  }) async {
    final snap = await _db
        .collection('item_prices')
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
  // 1) 랭킹 미리보기 (1번 코드 버전 유지)
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
        serverId: (data['serverId'] ?? data['server'] ?? '') as String,
        rank: (data['rank'] as num?)?.toInt() ?? i + 1,
        name: data['name'] as String,
        fame: (data['fame'] as num).toInt(),
        job: data['job'] as String,
        jobGrowName: (data['jobGrowName'] ?? data['job'] ?? '') as String,
        level: (data['level'] as num?)?.toInt() ?? 0,
        imagePath: (data['imagePath'] ?? '') as String,
      );
    });
  }

  // --------------------------------------------------
  // 1-1) 랭킹 전체 조회 (collectionGroup: ranking_rows)
  // --------------------------------------------------
  static Future<List<RankingRow>> fetchAllRankingRows({
    String? serverId,
    int? limit,
  }) async {
    // ranking_rows 문서에 serverId가 없는 경우가 있어 부모 캐릭터에서 보충해야 하므로
    // collectionGroup where 필터를 걸지 않고 전부 가져온 뒤 애플리케이션 레벨에서 필터링한다.
    Query<Map<String, dynamic>> query = _db.collectionGroup('ranking_rows');

    if (limit != null) {
      query = query.limit(limit);
    }

    final snap = await query.get();
    final docs = snap.docs;

    // ranking_rows 서브컬렉션에 imagePath가 없을 수 있어서
    // 부모 character 문서의 imagePath를 fallback으로 가져온다.
    final rows = await Future.wait(docs.map((doc) async {
      final base = rankingRowFromFirestoreDoc(doc);

      String imagePath = base.imagePath;
      String jobGrowName = base.jobGrowName;
      String job = base.job;
      int level = base.level;
      String server = base.serverId;

      // ranking_rows에 없으면 부모 character 문서/서브컬렉션에서 보충
      if (imagePath.isEmpty ||
          jobGrowName.isEmpty ||
          job.isEmpty ||
          level == 0 ||
          server.isEmpty) {
        final parentCharacter = doc.reference.parent.parent;
        if (parentCharacter != null) {
          final parentSnap = await parentCharacter.get();
          final parentData = parentSnap.data() as Map<String, dynamic>?;
          if (imagePath.isEmpty) {
            imagePath = parentData?['imagePath'] as String? ?? '';
          }
          if (server.isEmpty) {
            server = parentData?['serverId'] as String? ??
                parentData?['server'] as String? ??
                server;
          }
          if (jobGrowName.isEmpty) {
            jobGrowName = parentData?['jobGrowName'] as String? ??
                parentData?['jobName'] as String? ??
                jobGrowName;
          }
          if (job.isEmpty) {
            job = parentData?['job'] as String? ??
                parentData?['jobName'] as String? ??
                job;
          }
          if (level == 0) {
            level = (parentData?['level'] as num?)?.toInt() ?? level;
          }

          if (jobGrowName.isEmpty) {
            final basicStatSnap =
                await parentCharacter.collection('basic_stat').limit(1).get();
            if (basicStatSnap.docs.isNotEmpty) {
              final statData =
                  basicStatSnap.docs.first.data() as Map<String, dynamic>?;
              jobGrowName = statData?['jobGrowName'] as String? ?? jobGrowName;
            }
          }
        }
      }

      if (imagePath == base.imagePath &&
          jobGrowName == base.jobGrowName &&
          job == base.job &&
          level == base.level &&
          server == base.serverId) {
        return base;
      }

      return base.copyWith(
        imagePath: imagePath,
        jobGrowName: jobGrowName,
        job: job,
        level: level,
        serverId: server,
      );
    }));

    // 서버 선택이 있는 경우 애플리케이션 레벨에서 필터링
    if (serverId != null && serverId.isNotEmpty) {
      return rows.where((row) => row.serverId == serverId).toList();
    }
    return rows;
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
  //   → 2번 코드의 character_info + fallback 로직 통합
  // --------------------------------------------------
  static Future<CharacterInfo?> fetchCharacterInfoById(
    String characterId,
  ) async {
    final charRef = _db.collection('characters').doc(characterId);
    final charDoc = await charRef.get();

    if (!charDoc.exists) return null;

    // 1) 먼저 character_info/latest 문서가 있으면 거기서 전부 읽는다.
    final infoDoc =
        await charRef.collection('character_info').doc('latest').get();

    if (infoDoc.exists) {
      final info = infoDoc.data() ?? <String, dynamic>{};

      // summary → Character
      Character summary;
      final summaryMap = info['summary'] as Map<String, dynamic>?;

      if (summaryMap != null) {
        summary = Character.fromJson(summaryMap, id: charDoc.id);
      } else {
        summary = Character.fromJson(charDoc.data()!, id: charDoc.id);
      }

      // stats → CharacterStats.fromStatusList
      final statusList = info['stats'] as List<dynamic>? ?? const [];
      final CharacterStats stats = CharacterStats.fromStatusList(statusList);

      // detailStats → CharacterDetailStats.fromJson
      final detailMap =
          info['detailStats'] as Map<String, dynamic>? ?? const {};
      final CharacterDetailStats detailStats =
          CharacterDetailStats.fromJson(detailMap);

      // extraDetailStats → List<DetailStat>
      final extraRaw = info['extraDetailStats'] as List<dynamic>? ?? const [];
      final List<DetailStat> extraDetailStats = extraRaw.map((e) {
        final m = e as Map<String, dynamic>;
        return DetailStat(
          name: m['name']?.toString() ?? '',
          value: m['value']?.toString() ?? '',
        );
      }).toList();

      // equipments → List<EquipmentItem>
      final equipRaw = info['equipments'] as List<dynamic>? ?? const [];
      final List<EquipmentItem> equipments =
          equipRaw.whereType<Map<String, dynamic>>().map((m) {
        return EquipmentItem(
          category: m['category']?.toString() ?? '',
          imagePath: m['imagePath']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          grade: m['grade']?.toString() ?? '',
          option: m['option']?.toString() ?? '',
          desc: m['desc']?.toString() ?? '',
        );
      }).toList();

      // avatars → List<AvatarItem>
      final avatarRaw = info['avatars'] as List<dynamic>? ?? const [];
      final List<AvatarItem> avatars =
          avatarRaw.whereType<Map<String, dynamic>>().map((m) {
        final imagesAny = m['images'];
        List<String> images;
        if (imagesAny is List) {
          images = imagesAny.map((e) => e.toString()).toList();
        } else {
          images = const <String>[];
        }

        return AvatarItem(
          category: m['category']?.toString() ?? '',
          images: images,
          name: m['name']?.toString() ?? '',
          option: m['option']?.toString() ?? '',
          desc: m['desc']?.toString() ?? '',
        );
      }).toList();

      // buffItems → List<BuffItem>
      final buffRaw = info['buffItems'] as List<dynamic>? ?? const [];
      final List<BuffItem> buffItems =
          buffRaw.whereType<Map<String, dynamic>>().map((m) {
        return BuffItem(
          category: m['category']?.toString() ?? '',
          imagePath: m['imagePath']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          grade: m['grade']?.toString() ?? '',
          option: m['option']?.toString() ?? '',
        );
      }).toList();

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

    // 2) character_info 가 없는 옛날 데이터용 Fallback (기존 raw 기반 로직)
    // ───────────────────────────── stats / detail_stat ─────────────────────────────
    final basicStatDoc =
        await charRef.collection('basic_stat').doc('latest').get();
    final detailStatDoc =
        await charRef.collection('detail_stat').doc('latest').get();

    CharacterStats stats = const CharacterStats.empty();
    if (basicStatDoc.exists) {
      final data = basicStatDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      final statusList = raw['status'] as List<dynamic>? ?? [];
      stats = CharacterStats.fromStatusList(statusList);
    }

    CharacterDetailStats detailStats = const CharacterDetailStats.empty();
    List<DetailStat> extraDetailStats = const [];

    if (detailStatDoc.exists) {
      final data = detailStatDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      detailStats = CharacterDetailStats.fromJson(raw);

      final extra = raw['extra'] as List<dynamic>? ?? [];
      extraDetailStats = extra.map((e) {
        final m = e as Map<String, dynamic>;
        return DetailStat(
          name: m['name'] as String? ?? '',
          value: m['value'] as String? ?? '',
        );
      }).toList();
    }

    // ───────────────────────────── equip ─────────────────────────────
    final equipDoc = await charRef.collection('equip').doc('latest').get();
    List<EquipmentItem> equipments = const [];

    if (equipDoc.exists) {
      final data = equipDoc.data()!;
      final raw = data['raw'] as Map<String, dynamic>? ?? {};

      final list = raw['equipment'] as List<dynamic>? ?? [];

      equipments = list.map((e) {
        final m = e as Map<String, dynamic>;

        final String? itemId = m['itemId'] as String?;
        final String imageUrl = _neopleItemImageUrl(itemId);

        return EquipmentItem(
          category: m['slotName'] as String? ?? '',
          imagePath: imageUrl,
          name: m['itemName'] as String? ?? '',
          grade: m['itemRarity'] as String? ?? '',
          option: (m['reinforce'] != null) ? '+${m['reinforce']} 강화' : '',
          desc: m['explain'] as String? ?? '',
        );
      }).toList();
    }

    // ───────────────────────────── avatar + creature ─────────────────────────────
    final avatarDoc = await charRef.collection('avatar').doc('latest').get();
    final creatureDoc =
        await charRef.collection('creature').doc('latest').get();

    List<AvatarItem> avatars = [];

    if (avatarDoc.exists) {
      final raw = avatarDoc.data()?['raw'] as Map<String, dynamic>? ?? {};
      final list = raw['avatar'] as List<dynamic>? ?? [];

      avatars.addAll(
        list.map((e) {
          final m = e as Map<String, dynamic>;

          final String? itemId = m['itemId'] as String?;
          final String imageUrl = _neopleItemImageUrl(itemId);

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
            images: [imageUrl],
            name: m['itemName'] as String? ?? '',
            option: m['optionAbility'] as String? ?? '',
            desc: emblemText,
          );
        }),
      );
    }

    if (creatureDoc.exists) {
      final raw = creatureDoc.data()?['raw'] as Map<String, dynamic>? ?? {};
      final creature = raw['creature'] as Map<String, dynamic>?;

      if (creature != null) {
        final String? creatureItemId = creature['itemId'] as String?;
        final String imageUrl = _neopleItemImageUrl(creatureItemId);

        avatars.add(
          AvatarItem(
            category: '크리쳐',
            images: [imageUrl],
            name: creature['itemName'] as String? ?? '',
            desc: creature['itemRarity'] as String? ?? '',
            option: creature['optionAbility'] as String? ?? '',
          ),
        );
      }
    }

    // ───────────────────────────── buff_* ─────────────────────────────
    final buffAvatarDoc =
        await charRef.collection('buff_avatar').doc('latest').get();
    final buffEquipDoc =
        await charRef.collection('buff_equip').doc('latest').get();
    final buffCreatureDoc =
        await charRef.collection('buff_creature').doc('latest').get();

    List<BuffItem> buffItems = [];

    // 공통 버프 아이템 추가 헬퍼
    void _addBuffItemFromMap(
      Map<String, dynamic> m, {
      String? fallbackCategory,
    }) {
      final String slotName = m['slotName'] as String? ?? '';
      final String category =
          slotName.isNotEmpty ? slotName : (fallbackCategory ?? '');

      final String? itemId = m['itemId'] as String?;
      final String imageUrl = _neopleItemImageUrl(itemId);

      buffItems.add(
        BuffItem(
          category: category, // 상의 아바타 / 하의 아바타 / 크리쳐 등
          imagePath: imageUrl,
          name: m['itemName'] as String? ?? '',
          grade: m['itemRarity'] as String? ?? '',
          option: m['optionAbility']?.toString() ?? '',
        ),
      );
    }

    // 각 문서에서 equipment / avatar / creature를 다 훑으면서 BuffItem으로 변환
    void _addBuffFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
      String? creatureFallbackCategory,
    }) {
      if (!doc.exists) return;
      final raw = doc.data()?['raw'] as Map<String, dynamic>? ?? {};

      // 1) 버프 장비
      final equipList = raw['equipment'];
      if (equipList is List) {
        for (final e in equipList.whereType<Map<String, dynamic>>()) {
          _addBuffItemFromMap(e);
        }
      }

      // 2) 버프 아바타
      final avatarList = raw['avatar'];
      if (avatarList is List) {
        for (final a in avatarList.whereType<Map<String, dynamic>>()) {
          _addBuffItemFromMap(a);
        }
      }

      // 3) 버프 크리쳐
      final creature = raw['creature'];
      if (creature is Map<String, dynamic>) {
        _addBuffItemFromMap(
          creature,
          fallbackCategory: creatureFallbackCategory ?? '크리쳐',
        );
      }
    }

    // 실제로 세 문서를 모두 처리
    _addBuffFromDoc(buffEquipDoc);
    _addBuffFromDoc(buffAvatarDoc);
    _addBuffFromDoc(
      buffCreatureDoc,
      creatureFallbackCategory: '크리쳐',
    );

    // ───────────────────────────── summary (Character) ─────────────────────────────
    final summary = Character.fromJson(charDoc.data()!, id: charDoc.id);

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
