// lib/features/community/repository/community_repository.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 타입 사용을 위해 추가

import '../model/community_post.dart';
import '../model/post_category.dart';
import '../model/community_comment.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_mappers.dart'; // Firestore 매퍼를 사용하여 CommunityPost에 docId 추가

// ⚠️ 참고: InMemoryCommunityRepository 클래스는 제거하고 FirestoreCommunityRepository로 대체합니다.
// CommunityPost 모델에 docId 필드를 추가하여 Firestore 문서 ID를 저장할 수 있게 해야 합니다.
// (CommunityPost 모델 수정이 필요하지만, 여기서는 docId가 null일 때 임시 ID로 처리하는 방식으로 진행합니다.)

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchPosts({String? query, PostCategory? category});
  Future<CommunityPost?> getPostById(String docId); // id를 int 대신 docId(String)로 변경
  Future<CommunityPost> createPost(CommunityPost post);
  Future<CommunityPost> updatePost(CommunityPost post);
  Future<void> deletePost(String docId); // id를 docId(String)로 변경

  Future<List<CommunityComment>> fetchComments(String postDocId); // postId를 postDocId(String)로 변경
  Future<CommunityComment> addComment(
      String postDocId, String author, String content);
  Future<void> deleteComment(String postDocId, String commentDocId); // id를 docId(String)로 변경

  Future<CommunityPost?> incrementViews(String postDocId);
  Future<CommunityComment?> likeComment(String postDocId, String commentDocId,
      {bool increment = true});
  Future<CommunityComment?> updateComment(CommunityComment comment);
}

/// 🚀 Firestore를 사용하는 CommunityRepository 구현체
class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1) Post
  // ---------------------------------------------------------------------------

  @override
  Future<List<CommunityPost>> fetchPosts(
      {String? query, PostCategory? category}) async {
    if (query != null && query.isNotEmpty) {
      // 쿼리가 있으면 제목으로 검색 (FirestoreService에 이미 구현된 메서드 활용)
      return FirestoreService.searchPostsByExactTitle(query);
    }
    // 쿼리가 없으면 일반 게시물 목록을 가져옴 (카테고리 필터링 포함)
    return FirestoreService.fetchCommunityPosts(category: category);
  }

  @override
  // 기존 int id → String docId로 변경
  Future<CommunityPost?> getPostById(String docId) async {
    try {
      final doc = await _db.collection('boards').doc(docId).get();
      if (!doc.exists) return null;
      // 매퍼를 사용하여 Firestore 문서에서 CommunityPost로 변환
      final post = communityPostFromFirestoreDoc(doc);
      // docId를 저장할 수 있도록 모델을 확장해야 하지만, 현재는 doc.id를 사용하여 docId를 반환
      return post.copyWith(docId: docId);
    } catch (e) {
      print('Error getting post by docId $docId: $e');
      return null;
    }
  }

  @override
  Future<CommunityPost> createPost(CommunityPost post) async {
    // FirestoreService를 사용하여 게시글을 생성하고 docId를 반환받음
    final docId = await FirestoreService.createCommunityPost(post);
    
    // 생성된 post 객체에 실제 docId를 반영하여 반환 (CommunityPost 모델에 docId 필드가 있다고 가정하고 copyWith 사용)
    return post.copyWith(docId: docId);
  }

  @override
  Future<CommunityPost> updatePost(CommunityPost post) async {
    if (post.docId == null) {
      throw Exception('Post document ID is required for update.');
    }
    // FirestoreService를 사용하여 게시글 업데이트
    await FirestoreService.updateCommunityPost(post.docId!, post);
    return post;
  }

  @override
  // 기존 int id → String docId로 변경
  Future<void> deletePost(String docId) async {
    // FirestoreService를 사용하여 게시글 삭제
    await FirestoreService.deleteCommunityPost(docId);
  }

  // ---------------------------------------------------------------------------
  // 2) Comment
  // ---------------------------------------------------------------------------

  @override
  // 기존 int postId → String postDocId로 변경
  Future<List<CommunityComment>> fetchComments(String postDocId) async {
    // FirestoreService를 사용하여 댓글 목록 조회
    return FirestoreService.fetchCommentsForPost(postDocId);
  }

  @override
  Future<CommunityComment> addComment(
      String postDocId, String author, String content) async {
    final newComment = CommunityComment(
      id: 0, // Firestore에서는 실제 ID 대신 docId를 사용하므로 임시 값 0
      postId: 0, // 임시 값
      author: author.isEmpty ? '익명' : author,
      content: content,
      createdAt: DateTime.now(),
    );

    // FirestoreService를 사용하여 댓글 추가하고 docId를 반환받음
    final commentDocId = await FirestoreService.createCommentForPost(
      postDocId,
      newComment,
    );
    
    // 추가된 댓글 객체에 실제 docId를 반영하여 반환 (CommunityComment 모델에 docId 필드가 있다고 가정)
    return newComment.copyWith(docId: commentDocId);
  }

  @override
  Future<void> deleteComment(String postDocId, String commentDocId) async {
    // FirestoreService를 사용하여 댓글 삭제
    await FirestoreService.deleteCommentForPost(postDocId, commentDocId);
  }

  @override
  Future<CommunityComment?> updateComment(CommunityComment comment) async {
    if (comment.postDocId == null || comment.docId == null) {
      throw Exception('Comment document ID and Post document ID are required for update.');
    }
    await FirestoreService.updateCommentForPost(
      comment.postDocId!,
      comment.docId!,
      comment,
    );
    return comment;
  }

  // ---------------------------------------------------------------------------
  // 3) Likes / Views
  // ---------------------------------------------------------------------------

  @override
  Future<CommunityPost?> incrementViews(String postDocId) async {
    try {
      final postRef = _db.collection('boards').doc(postDocId);

      // Firestore 트랜잭션을 사용하여 조회수 1 증가
      await _db.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(postRef);
        if (!docSnapshot.exists) {
          throw Exception("Post not found");
        }
        final currentViews = docSnapshot.data()?['view_count'] as int? ?? 0;
        final newViews = currentViews + 1;

        transaction.update(postRef, {'view_count': newViews});
      });

      // 업데이트된 후의 데이터를 다시 가져와 반환
      final updatedSnap = await postRef.get();
      if (!updatedSnap.exists) return null;
      
      final post = communityPostFromFirestoreDoc(updatedSnap);
      return post.copyWith(docId: postDocId);

    } on Exception catch (e) {
      print('Error incrementing views for $postDocId: $e');
      return null;
    }
  }

  @override
  Future<CommunityComment?> likeComment(
      String postDocId, String commentDocId, {bool increment = true}) async {
    try {
      final commentRef = _db
          .collection('boards')
          .doc(postDocId)
          .collection('comments')
          .doc(commentDocId);

      // Firestore 트랜잭션을 사용하여 좋아요 수 증가/감소
      await _db.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(commentRef);
        if (!docSnapshot.exists) {
          throw Exception("Comment not found");
        }
        final currentLikes = docSnapshot.data()?['likes'] as int? ?? 0;
        final newLikes = increment ? currentLikes + 1 : currentLikes - 1;

        transaction.update(commentRef, {'likes': newLikes < 0 ? 0 : newLikes});
      });

      // 업데이트된 후의 데이터를 다시 가져와 반환
      final updatedSnap = await commentRef.get();
      if (!updatedSnap.exists) return null;
      
      final comment = commentFromFirestoreDoc(updatedSnap);
      return comment.copyWith(docId: commentDocId, postDocId: postDocId);

    } on Exception catch (e) {
      print('Error liking comment $commentDocId in post $postDocId: $e');
      return null;
    }
  }
}