import 'notice_category.dart';

class Notice {
  // Firestore 문서 ID. 업데이트/삭제 시 필요합니다.
  final String? docId; 
  final int id; // Corresponds to 'notice_no' in Firestore
  final String title;
  final String content;
  final String author; // 작성자 (예: '운영팀')
  final DateTime createdAt;
  final NoticeCategory category;
  final bool pinned; // 상단 고정 여부
  final int views; // 조회수
  final int commentCount;  // 댓글 수(필요 없으면 0 유지)

  const Notice({
    this.docId, // docId 추가
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.category,
    this.pinned = false,
    this.views = 0,
    this.commentCount = 0,
  });

  Notice copyWith({
    String? docId,
    int? id,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    NoticeCategory? category,
    bool? pinned,
    int? views,
    int? commentCount,
  }) {
    return Notice(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      pinned: pinned ?? this.pinned,
      views: views ?? this.views,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      docId: json['docId'] as String?, // FromJson에 docId 추가
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String? ?? '운영팀',
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: noticeCategoryFromString(json['category'] as String? ?? 'general'),
      pinned: json['pinned'] as bool? ?? false,
      views: json['views'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'docId': docId, // ToJson에 docId 추가
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        'category': noticeCategoryToString(category),
        'pinned': pinned,
        'views': views,
        'commentCount': commentCount,
 };
}