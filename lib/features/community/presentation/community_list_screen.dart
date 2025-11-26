// lib/features/community/presentation/community_list_screen.dart
import 'package:flutter/material.dart';

// 💡 Firestore 기반의 CommunityRepository 인터페이스 또는 구현체를 import
import '../repository/community_repository.dart';
import '../model/community_post.dart';

// 앱 공통 디자인
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// 커스텀 검색 필드
import '../../../core/widgets/custom_text_field.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 💡 Firestore 기반의 CommunityRepository를 사용하도록 타입 수정
  late final CommunityRepository _repo;

  List<CommunityPost> _allPosts = [];
  List<CommunityPost> _filteredPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // 💡 Repository 초기화: Firestore 구현체 인스턴스를 생성하거나 주입받아야 합니다.
    // 임시로 CommunityRepository의 Firestore 구현체라고 가정하겠습니다.
    _repo =
        FirestoreCommunityRepository(); // 실제 Firestore 구현체 인스턴스 (예: FirestoreCommunityRepository())

    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // 🔹 1) Firestore에서 모든 게시글을 가져옵니다. (Firestore 연동 가정)
    final data = await _repo.fetchPosts();

    setState(() {
      _allPosts = data;
      _applyFilter(); // 초기 필터 적용
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      // 💡 최신 게시글이 가장 위에 오도록 정렬 (createdAt 내림차순)
      _allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _filteredPosts = List.of(_allPosts));
      return;
    }

    setState(() {
      _filteredPosts = _allPosts.where((p) {
        final t = p.title.toLowerCase();
        final c = p.content.toLowerCase();
        return t.contains(q) || c.contains(q);
      }).toList();

      // 검색 결과도 최신 순으로 정렬
      _filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // 🔎 검색 필드 영역 배경색
              Container(
                color: const Color(0xFFF7F7F7),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: CustomTextField(
                  hintText: '제목/내용 검색',
                  controller: _searchController,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 제목
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '커뮤니티',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFFEAEAEA)),

                      // 리스트 영역
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredPosts.isEmpty
                            ? Center(
                                child: Text(
                                  '게시글이 없습니다.',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.primaryText,
                                backgroundColor: Colors.white,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filteredPosts.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final p = _filteredPosts[index];
                                    return _buildPostRow(context, p);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔹 오른쪽 하단 "글 작성" 버튼
          Positioned(right: 24, bottom: 24, child: _buildWriteButton(context)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 게시글 한 줄 UI

  Widget _buildPostRow(BuildContext context, CommunityPost p) {
    return InkWell(
      onTap: () async {
        // 💡 상세 화면으로 이동 시 Post 객체와 Firestore 기반 Repository 객체를 Map으로 전달
        final result = await Navigator.pushNamed(
          context,
          '/community_detail',
          arguments: {'post': p, 'repo': _repo},
        );

        // 상세 화면에서 돌아왔을 때, 게시글이 수정/삭제되었을 경우 목록 새로고침
        if (result == true) {
          _load();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              p.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),

            // 글쓴이 · 시간 · 조회 · 댓글 · 좋아요
            Text(
              '${p.author} · ${_fmtDate(p.createdAt)} · 조회 ${p.views} · 댓글 ${p.commentCount} · 좋아요 ${p.likes}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 글 작성 버튼

  Widget _buildWriteButton(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () async {
          // 글 작성 화면으로 이동
          final created = await Navigator.pushNamed(
            context,
            '/community_post_write',
            arguments: _repo,
          );

          // 새 글이 작성되어 돌아왔다면 목록을 다시 로드하여 Firestore 최신 상태 반영
          if (created != null && created is CommunityPost) {
            _load();
            // 💡 새 글을 목록에 추가하는 대신, _load()를 통해 Firestore에서 최신 데이터를 가져오는 것이 더 확실합니다.
          }
        },
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('글 작성'),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16),
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryText.withOpacity(0.9);
            }
            if (states.contains(MaterialState.hovered)) {
              return AppColors.secondaryText;
            }
            return AppColors.primaryText;
          }),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          textStyle: MaterialStateProperty.all(
            AppTextStyles.body2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: MaterialStateProperty.all(0),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
