// lib/features/community/repository/community_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/community_post.dart';
import '../model/community_comment.dart';
import '../model/post_category.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_mappers.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchPosts({
    String? query,
    PostCategory? category,
  });
  Future<CommunityPost?> getPostById(String docId);
  Future<CommunityPost> createPost(CommunityPost post);
  Future<CommunityPost> updatePost(CommunityPost post);
  Future<void> deletePost(String docId);

  Future<List<CommunityComment>> fetchComments(String postDocId);
  Future<CommunityComment> addComment(
    String postDocId,
    String author,
    String content,
  );
  Future<void> deleteComment(String postDocId, String commentDocId);
  Future<CommunityComment?> updateComment(CommunityComment comment);

  Future<CommunityPost?> incrementViews(String postDocId);
  Future<CommunityComment?> likeComment(
    String postDocId,
    String commentDocId, {
    bool increment = true,
  });
}

class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<CommunityPost>> fetchPosts({
    String? query,
    PostCategory? category,
  }) async {
    if (query != null && query.isNotEmpty) {
      return FirestoreService.searchPostsByExactTitle(query);
    }
    return FirestoreService.fetchCommunityPosts(category: category);
  }

  @override
  Future<CommunityPost?> getPostById(String docId) async {
    final doc = await _db.collection('boards').doc(docId).get();
    if (!doc.exists) return null;
    final post = communityPostFromFirestoreDoc(doc);
    return post.copyWith(docId: docId);
  }

  @override
  Future<CommunityPost> createPost(CommunityPost post) async {
    final docId = await FirestoreService.createCommunityPost(post);
    return post.copyWith(docId: docId);
  }

  @override
  Future<CommunityPost> updatePost(CommunityPost post) async {
    final docId = post.docId;
    if (docId == null) {
      throw StateError('Post document ID is required for update.');
    }
    await FirestoreService.updateCommunityPost(docId, post);
    return post;
  }

  @override
  Future<void> deletePost(String docId) async {
    await FirestoreService.deleteCommunityPost(docId);
  }

  @override
  Future<List<CommunityComment>> fetchComments(String postDocId) async {
    return FirestoreService.fetchCommentsForPost(postDocId);
  }

  @override
  Future<CommunityComment> addComment(
    String postDocId,
    String author,
    String content,
  ) async {
    final newComment = CommunityComment(
      id: 0,
      postId: 0,
      author: author.isEmpty ? '익명' : author,
      content: content,
      createdAt: DateTime.now(),
    );

    final commentDocId = await FirestoreService.createCommentForPost(
      postDocId,
      newComment,
    );

    return newComment.copyWith(docId: commentDocId, postDocId: postDocId);
  }

  @override
  Future<void> deleteComment(String postDocId, String commentDocId) async {
    await FirestoreService.deleteCommentForPost(postDocId, commentDocId);
  }

  @override
  Future<CommunityComment?> updateComment(CommunityComment comment) async {
    final postDocId = comment.postDocId;
    final docId = comment.docId;
    if (postDocId == null || docId == null) {
      throw StateError('Comment docId and postDocId are required for update.');
    }
    await FirestoreService.updateCommentForPost(postDocId, docId, comment);
    return comment;
  }

  @override
  Future<CommunityPost?> incrementViews(String postDocId) async {
    try {
      final postRef = _db.collection('boards').doc(postDocId);
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(postRef);
        if (!snap.exists) throw StateError('Post not found');
        final currentViews = snap.data()?['view_count'] as int? ?? 0;
        transaction.update(postRef, {'view_count': currentViews + 1});
      });

      final updatedSnap = await postRef.get();
      if (!updatedSnap.exists) return null;
      final post = communityPostFromFirestoreDoc(updatedSnap);
      return post.copyWith(docId: postDocId);
    } catch (e) {
      debugPrint('Error incrementing views for $postDocId: $e');
      return null;
    }
  }

  @override
  Future<CommunityComment?> likeComment(
    String postDocId,
    String commentDocId, {
    bool increment = true,
  }) async {
    try {
      final commentRef = _db
          .collection('boards')
          .doc(postDocId)
          .collection('comments')
          .doc(commentDocId);

      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(commentRef);
        if (!snap.exists) throw StateError('Comment not found');
        final currentLikes = snap.data()?['likes'] as int? ?? 0;
        final nextLikes = (increment ? currentLikes + 1 : currentLikes - 1)
            .clamp(0, 1 << 31);
        transaction.update(commentRef, {'likes': nextLikes});
      });

      final updated = await commentRef.get();
      if (!updated.exists) return null;
      final comment = commentFromFirestoreDoc(updated);
      return comment.copyWith(docId: commentDocId, postDocId: postDocId);
    } catch (e) {
      debugPrint('Error liking comment $commentDocId in post $postDocId: $e');
      return null;
    }
  }
}
