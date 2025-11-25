// lib/features/community/model/community_post.dart
import 'post_category.dart';

class CommunityPost {
  final int id; // 기존 필드 (Firestore의 'post_no'와 매핑될 수 있음)
  final String? docId; // 💡 Firestore 문서 ID 저장을 위해 추가 (String 타입)
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final PostCategory category;
  final int views;
  final int commentCount;
  final int likes; // 👍 좋아요 개수

  const CommunityPost({
    required this.id,
    this.docId, // 추가: nullable String
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.category,
    this.views = 0,
    this.commentCount = 0,
    this.likes = 0, // 기본값 0
  });

  CommunityPost copyWith({
    int? id,
    String? docId, // 추가
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    PostCategory? category,
    int? views,
    int? commentCount,
    int? likes,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      docId: docId ?? this.docId, // docId 복사
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      views: views ?? this.views,
      commentCount: commentCount ?? this.commentCount,
      likes: likes ?? this.likes,
    );
  }

  // Firestore에서 docId는 Map에 포함되지 않으므로 fromJson/toJson 로직에서 제외합니다.
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // 참고: json에는 docId가 포함되지 않으며, 매퍼에서 별도로 주입됩니다.
    return CommunityPost(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String? ?? '익명',
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: categoryFromString(json['category'] as String? ?? 'general'),
      views: json['views'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0, // JSON에 없으면 0
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
    'category': categoryToString(category),
    'views': views,
    'commentCount': commentCount,
    'likes': likes, // 직렬화에도 포함
  };
}