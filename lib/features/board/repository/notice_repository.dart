import '../../../core/services/firebase_service.dart';
import '../model/notice.dart';
import '../model/notice_category.dart';

/// 공지 레포지토리 인터페이스
abstract class NoticeRepository {
  /// 공지 목록 조회
  Future<List<Notice>> fetchNotices({
    NoticeCategory? category, // null이면 전체
    String query,
    bool onlyPinned,
  });

  /// 단건 조회 (notice_no 기준)
  Future<Notice?> getNoticeById(int id);

  /// 생성
  Future<Notice> createNotice(Notice notice);

  /// 수정
  Future<Notice> updateNotice(Notice notice);

  /// 삭제 (notice_no 기준)
  Future<void> deleteNotice(int id);
}

/// Firestore 기반 공지 레포지토리 구현
class FirestoreNoticeRepository implements NoticeRepository {
  @override
  Future<List<Notice>> fetchNotices({
    NoticeCategory? category,
    String query = '',
    bool onlyPinned = false,
  }) async {
    // Firestore에서 넉넉히 가져온 뒤 메모리 필터링
    final List<Notice> notices = await FirestoreService.fetchNotices(
      category: null,
      pinned: onlyPinned ? true : null,
      limit: 50,
    );

    Iterable<Notice> filtered = notices;

    if (category != null) {
      filtered = filtered.where((n) => n.category == category);
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where(
        (n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q),
      );
    }

    final list = filtered.toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return list;
  }

  @override
  Future<Notice?> getNoticeById(int id) async {
    return FirestoreService.getNoticeByNo(id);
  }

  @override
  Future<Notice> createNotice(Notice notice) async {
    final String docId = await FirestoreService.createNotice(notice);
    return notice.copyWith(docId: docId);
  }

  @override
  Future<Notice> updateNotice(Notice notice) async {
    final docId = notice.docId;
    if (docId == null) {
      throw StateError(
        'Cannot update notice: docId is missing for notice ${notice.id}',
      );
    }
    await FirestoreService.updateNotice(docId, notice);
    return notice;
  }

  @override
  Future<void> deleteNotice(int id) async {
    final noticeToDelete = await FirestoreService.getNoticeByNo(id);
    if (noticeToDelete == null) return;

    final docId = noticeToDelete.docId;
    if (docId == null) {
      throw StateError(
        'Notice found but docId is missing for id $id. Cannot delete.',
      );
    }

    await FirestoreService.deleteNotice(docId);
  }
}
