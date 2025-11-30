// lib/features/community/presentation/community_detail_screen.dart
import 'package:flutter/material.dart';

import '../model/community_post.dart';
import '../repository/community_repository.dart';
import '../model/community_comment.dart';

// 공통 테마
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final CommunityRepository repo;

  const CommunityDetailScreen({
    super.key,
    required this.post,
    required this.repo,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CommunityDetailScreenState createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with TickerProviderStateMixin {
  late CommunityPost _post;
  final TextEditingController _commentCtrl = TextEditingController();

  List<CommunityComment> _comments = [];
  bool _loading = true;
  bool _commentsCollapsed = false;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load(initial: true);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    final docId = _post.docId;
    if (docId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    // 1. 최초 진입 시 조회수 +1
    if (initial && !_viewCounted) {
      final v = await widget.repo.incrementViews(docId);
      if (mounted && v != null) {
        _post = v;
        _viewCounted = true;
      }
    }

    // 2. 게시글 및 댓글 로드
    final loaded = await widget.repo.getPostById(docId);
    final cmts = await widget.repo.fetchComments(docId);
    if (!mounted) return;

    setState(() {
      _post = loaded ?? _post;
      _comments = cmts;
      _loading = false;
    });
  }

  void _replaceComment(CommunityComment c) {
    final i = _comments.indexWhere((e) => e.docId == c.docId);
    if (i >= 0) {
      setState(() {
        _comments[i] = c;
      });
    }
  }

  Future<void> _toggleLike(CommunityComment c, {required bool inc}) async {
    final postDocId = _post.docId;
    final commentDocId = c.docId;

    if (postDocId == null || commentDocId == null) return;

    final updated = await widget.repo.likeComment(
      postDocId,
      commentDocId,
      increment: inc,
    );
    if (updated != null) _replaceComment(updated);
  }

  Future<void> _editComment(CommunityComment c) async {
    if (c.docId == null) return;

    final ctrl = TextEditingController(text: c.content);
    final done = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: ctrl,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '내용을 수정하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (done == null || done.isEmpty) return;
    final saved = await widget.repo
        .updateComment(c.copyWith(content: done, docId: c.docId, postDocId: c.postDocId));
    if (saved != null) _replaceComment(saved);
  }

  void _togglePostLike() {
    // Post 좋아요 API 구현 예정 (현재는 미구현)
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _fmtDate(_post.createdAt);

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 상세')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      children: [
                        // 본문 + 댓글 카드
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            // 카드 내부
                            child: Column(
                              children: [
                                // 스크롤 영역: 제목, 본문, 댓글까지
                                Expanded(
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                      // 1) 제목 + 메타
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _post.title,
                                              style: AppTextStyles.body1
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 18,
                                                    color:
                                                        AppColors.primaryText,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_post.author} · $dateStr · 조회 ${_post.views} · 댓글 ${_comments.length} · 좋아요 ${_post.likes}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.secondaryText,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 내용 위/아래 디바이더
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: AppColors.border,
                                      ),

                                      // 2) 본문 + 중앙 좋아요
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _post.content,
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                    color:
                                                        AppColors.primaryText,
                                                    height: 1.6,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            Center(
                                              child: IconButton(
                                                onPressed: _togglePostLike,
                                                icon: Icon(
                                                  Icons.thumb_up_outlined,
                                                  size: 24,
                                                  color: AppColors.secondaryText,
                                                ),
                                                splashRadius: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 내용 / 댓글 사이 디바이더
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: AppColors.border,
                                      ),

                                      // 3) 댓글 섹션
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          16,
                                        ),
                                        // 💡 오류 지점: _buildCommentSection 메서드 호출
                                        child: _buildCommentSection(context),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔻 카드 맨 아래 고정 디바이더
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.border,
                                ),

                                // 🔻 '목록으로' 버튼 (카드 하단 고정)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    12,
                                  ),
                                  child: SizedBox(
                                    height: 48,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.resolveWith<
                                                Color>(
                                          (states) {
                                            if (states.contains(
                                              MaterialState.disabled,
                                            )) {
                                              return AppColors.border;
                                            }
                                            if (states.contains(
                                              MaterialState.pressed,
                                            )) {
                                              return AppColors.primaryText
                                                  .withOpacity(0.9);
                                            }
                                            if (states.contains(
                                              MaterialState.hovered,
                                            )) {
                                              return AppColors.secondaryText;
                                            }
                                            return AppColors.primaryText;
                                          },
                                        ),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Colors.white,
                                        ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        textStyle: MaterialStateProperty.all(
                                          AppTextStyles.body1.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        elevation: MaterialStateProperty.all(0),
                                      ),
                                      child: const Text('목록으로'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 6) 하단 고정 댓글 입력 바
                        _buildBottomBar(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ===== 댓글 섹션 =====
  Widget _buildCommentSection(BuildContext context) {
    final count = _comments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 헤더
        Row(
          children: [
            Text(
              '댓글 ($count)',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1, color: AppColors.border),

        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _commentsCollapsed
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    if (count == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '첫 댓글을 남겨보세요!',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 12,
                          thickness: 1,
                          color: AppColors.border,
                        ), // 각 댓글 간 Divider (간격 줄임)
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          return _buildCommentTile(context, c);
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(BuildContext context, CommunityComment c) {
    final isLiked = false; // TODO: 좋아요 상태 API 연동 필요

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단: 작성자/시간 + 우측 수정/삭제 pill들
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    c.author,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtDateTime(c.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCommentActionPill(
                  label: '삭제',
                  icon: Icons.delete_outline,
                  onTap: () async {
                    if (_post.docId == null || c.docId == null) return;
                    await widget.repo.deleteComment(_post.docId!, c.docId!);
                    await _load();
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 내용
        Text(
          c.content,
          style: AppTextStyles.body2.copyWith(color: AppColors.primaryText),
        ),

        const SizedBox(height: 4),

        // 우측 하단 좋아요 (pill 스타일로 통일)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildCommentActionPill(
              label: '좋아요 ${c.likes}',
              icon: isLiked
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              onTap: () => _toggleLike(c, inc: !isLiked),
            ),
          ],
        ),
      ],
    );
  }

  // board_list의 필터 pill 느낌을 작게 만든 버전
  Widget _buildCommentActionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 하단 고정 댓글 입력 바 =====
  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요',
                hintStyle: AppTextStyles.body2.copyWith(
                  color: AppColors.secondaryText,
                ),
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryText,
                    width: 1.2,
                  ),
                ),
              ),
              style: AppTextStyles.body1.copyWith(color: AppColors.primaryText),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final text = _commentCtrl.text.trim();
              if (text.isEmpty) return;
              
              final postDocId = _post.docId;
              if (postDocId == null) return;

              await widget.repo.addComment(postDocId, '익명', text);

              _commentCtrl.clear();
              await _load();
              if (_commentsCollapsed) {
                setState(() => _commentsCollapsed = false);
              }
            },
            icon: const Icon(
              Icons.send_rounded,
              size: 22,
              color: AppColors.primaryText,
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  // ===== utils =====
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
