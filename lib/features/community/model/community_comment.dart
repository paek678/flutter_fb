// lib/features/community/model/community_comment.dart

class CommunityComment {
  final int id; // 기존 필드 (Firestore의 'id'와 매핑될 수 있음)
  final String? docId; // 💡 댓글의 Firestore 문서 ID 저장을 위해 추가
  final int postId; // 기존 필드 (Firestore의 'post_id'와 매핑될 수 있음)
  final String? postDocId; // 💡 상위 게시물의 Firestore 문서 ID 저장을 위해 추가
  final String author;
  final String content;
  final DateTime createdAt;
  final int likes;

  CommunityComment({
    required this.id,
    this.docId, // 추가: nullable String
    required this.postId,
    this.postDocId, // 추가: nullable String
    required this.author,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });

  CommunityComment copyWith({
    int? id,
    String? docId, // 추가
    int? postId,
    String? postDocId, // 추가
    String? author,
    String? content,
    DateTime? createdAt,
    int? likes,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      docId: docId ?? this.docId, // docId 복사
      postId: postId ?? this.postId,
      postDocId: postDocId ?? this.postDocId, // postDocId 복사
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }

  // Firestore에서 docId, postDocId는 Map에 포함되지 않으므로 fromJson/toJson 로직에서 제외합니다.
  factory CommunityComment.fromJson(Map<String, dynamic> j) => CommunityComment(
        id: j['id'] as int,
        postId: j['postId'] as int,
        author: j['author'] as String? ?? '익명',
        content: j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        likes: j['likes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'author': author,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
      };
}