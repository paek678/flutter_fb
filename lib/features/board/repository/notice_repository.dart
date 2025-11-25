import '../../../core/services/firebase_service.dart';
import '../model/notice.dart';
import '../model/notice_category.dart';

/// 공지 레포지토리 인터페이스
abstract class NoticeRepository {
/// 공지 목록 조회
Future<List<Notice>> fetchNotices({
NoticeCategory? category, // null이면 전체
String query, // 제목/내용 검색어(선택)
bool onlyPinned,  // 상단 고정만
});

/// 단건 조회 (Notice Number 기준)
Future<Notice?> getNoticeById(int id);

/// 생성
Future<Notice> createNotice(Notice notice);

/// 수정
Future<Notice> updateNotice(Notice notice);

/// 삭제 (Notice Number 기준)
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
// 1. FirestoreService의 static 메서드를 직접 호출합니다.
// 💡 카테고리 복합 색인 문제 해결을 위해, Firestore 호출 시 category를 null로 전달하여
//    모든 카테고리의 데이터를 가져오도록 합니다.
final List<Notice> notices = await FirestoreService.fetchNotices(
category: null, // 👈 수정: 카테고리 필터링을 메모리에서 하기 위해 null 전달
// onlyPinned가 true면 pinned: true로 필터링, 아니면 null을 넘겨 전체를 가져옵니다.
pinned: onlyPinned ? true : null, 
limit: 50, // 충분한 기본 제한 설정
);

Iterable<Notice> res = notices;

// 2. 메모리 내에서 카테고리 필터링 (추가된 로직)
if (category != null) {
res = res.where((n) => n.category == category);
}

// 3. 메모리 내에서 쿼리 필터링 (제목/내용 검색)
if (query.trim().isNotEmpty) {
final q = query.toLowerCase();
res = res.where((n) =>
n.title.toLowerCase().contains(q) ||
n.content.toLowerCase().contains(q));
}

// 4. 정렬 (Firestore에서 created_at 내림차순으로 정렬된 상태이므로, pinned만 우선 처리)
final list = res.toList()
..sort((a, b) {
// 상단 고정 우선 → 최신순
if (a.pinned != b.pinned) return (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0);
return b.createdAt.compareTo(a.createdAt);
});

return list;
}

@override
Future<Notice?> getNoticeById(int id) async {
// Notice Number(id)를 기준으로 문서를 조회합니다.
return await FirestoreService.getNoticeByNo(id);
}

@override
Future<Notice> createNotice(Notice notice) async {
// 1. 공지 생성 요청 후 문서 ID를 받습니다.
final String docId = await FirestoreService.createNotice(notice);

// 2. 생성된 문서 ID(docId)를 포함하여 Notice 객체를 반환합니다.
return notice.copyWith(docId: docId);
}

@override
Future<Notice> updateNotice(Notice notice) async {
// 1. docId가 없으면 업데이트 불가
final docId = notice.docId;
if (docId == null) {
throw StateError(
'Cannot update notice: docId is missing for notice ${notice.id}');
}

// 2. 공지 업데이트 요청
await FirestoreService.updateNotice(docId, notice);

// 3. 업데이트된 Notice 객체를 그대로 반환
return notice;
}

@override
Future<void> deleteNotice(int id) async {
// 1. Notice Number로 문서를 찾아 docId를 얻습니다.
final noticeToDelete = await FirestoreService.getNoticeByNo(id);

if (noticeToDelete == null) {
// 삭제하려는 공지가 없는 경우, 오류 대신 조용히 종료합니다.
return; 
}

final docId = noticeToDelete.docId;
if (docId == null) {
throw StateError(
'Notice found but docId is missing for id $id. Cannot delete.');
}

// 2. 문서 ID로 삭제 요청
await FirestoreService.deleteNotice(docId);
}
}