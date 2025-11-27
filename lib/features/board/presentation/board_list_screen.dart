// lib/features/board/presentation/board_list_screen.dart
import 'package:flutter/material.dart';
import '../model/notice.dart';
import '../model/notice_category.dart';
import '../repository/notice_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  // 🔹 1. InMemoryNoticeRepository 대신 인터페이스 NoticeRepository 사용
  // 실제 구현체는 FirestoreNoticeRepository로 인스턴스화
  late final NoticeRepository _repo;

  int _selectedFilter = 0; // 0: 전체, 1: 이벤트, 2: 점검
  List<Notice> _notices = [];
  bool _loading = true;

  Notice? _selectedNotice; // 디테일에서 보여줄 선택된 공지

  @override
  void initState() {
    super.initState();
    // 🔹 2. FirestoreNoticeRepository로 인스턴스 교체
    _repo = FirestoreNoticeRepository();
    _loadForFilter(_selectedFilter);
  }

  Future<void> _loadForFilter(int index) async {
    setState(() => _loading = true);

    NoticeCategory? category;
    switch (index) {
      case 1:
        category = NoticeCategory.event;
        break;
      case 2:
        category = NoticeCategory.maintenance;
        break;
      case 0:
      default:
        category = null; // 전체
    }

    // Firestore에서 데이터를 불러옵니다.
    final data = await _repo.fetchNotices(
      category: category,
      onlyPinned: false,
      query: '',
    );

    if (!mounted) return;
    setState(() {
      _notices = data;
      _loading = false;
      _selectedNotice = null; // 필터 바꾸면 상세에서 다시 리스트로
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDetail = _selectedNotice != null;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                // 🔹 리스트/디테일에 따라 margin 분기
                margin: isDetail
                    ? const EdgeInsets.fromLTRB(16, 16, 16, 0) // 디테일: 좌우 여백 O
                    : const EdgeInsets.only(top: 16), // 리스트: 위만 여백
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
                    // 리스트 모드일 때만 상단 제목 / 필터 / 헤더 노출
                    if (!isDetail) ...[
                      // 상단 제목
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '공지사항',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // 필터 버튼 영역
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterPill(0, '전체'),
                              const SizedBox(width: 8),
                              _buildFilterPill(1, '이벤트'),
                              const SizedBox(width: 8),
                              _buildFilterPill(2, '점검'),
                            ],
                          ),
                        ),
                      ),

                      // 테이블 헤더
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF7F7F7),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 72,
                              child: Text('카테고리', style: _headerStyle),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: Text('제목', style: _headerStyle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 리스트 / 디테일 토글 영역
                    Expanded(
                      child: isDetail
                          ? _buildDetailScreen(context, _selectedNotice!)
                          : _buildNoticeList(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 🔹 오른쪽 하단 "공지 작성" 버튼 (디테일에서는 감춤)
        if (!isDetail)
          Positioned(right: 24, bottom: 24, child: _buildWriteButton(context)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 공지 작성 버튼

  Widget _buildWriteButton(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/notice_write',
            arguments: _repo, // NoticeWriteScreen에서 repo 받도록 설계
          );

          // 작성 후 돌아왔을 때 목록 갱신 (성공 시 Notice 돌려주는 구조 기준)
          if (result is Notice) {
            _loadForFilter(_selectedFilter);
          }
        },
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('공지 작성'),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16),
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.border; // Disabled
            }
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryText.withOpacity(0.9); // Pressed
            }
            if (states.contains(MaterialState.hovered)) {
              return AppColors.secondaryText; // Hover
            }
            return AppColors.primaryText; // Default
          }),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          shape: MaterialStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
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

  // ---------------------------------------------------------------------------
  // 필터 버튼

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;

    return GestureDetector(
      onTap: () {
        if (_selectedFilter == index) return;
        setState(() {
          _selectedFilter = index;
        });
        _loadForFilter(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryText.withOpacity(0.9)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryText.withOpacity(0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 리스트 본문

  Widget _buildNoticeList(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notices.isEmpty) {
      return Center(
        child: Text(
          '공지사항이 없습니다.',
          style: AppTextStyles.body2.copyWith(color: AppColors.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      // 🔹 당겨서 새로고침 시 현재 필터 기준으로 다시 불러오기
      onRefresh: () => _loadForFilter(_selectedFilter),
      color: AppColors.primaryText, // 인디케이터 색상 (디자인 맞춤)
      backgroundColor: Colors.white, // 배경색 (카드 배경과 맞춤)
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        physics: const AlwaysScrollableScrollPhysics(), // 🔹 아이템 적어도 당길 수 있게
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final n = _notices[index];
          return _buildNoticeRow(context, n);
        },
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildNoticeRow(BuildContext context, Notice n) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedNotice = n;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding,
          vertical: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 72, child: _buildCategoryBadge(n)),
            const SizedBox(width: _badgeContentGap),
            Expanded(
              child: Text(
                n.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Notice n) {
    final NoticeCategory c =
        n.category; // NoticeCategory? -> NoticeCategory로 수정

    String label = '공지';
    Color bg = const Color(0xFFE9F5EE);
    Color textColor = const Color(0xFF208C4E);

    switch (c) {
      // c가 NoticeCategory 타입이므로, case null:은 제거해야 합니다.
      case NoticeCategory.event:
        label = '이벤트';
        bg = const Color(0xFFFFE2D2);
        textColor = const Color(0xFF5A3C2A);
        break;
      case NoticeCategory.maintenance:
        label = '점검';
        bg = const Color(0xFFE3ECF5);
        textColor = const Color(0xFF344055);
        break;
      case NoticeCategory.general: // general 케이스 명시 추가
      default: // general이 아니거나 새로운 카테고리가 추가될 경우 대비
        label = '공지';
        bg = const Color(0xFFD6EFE8);
        textColor = const Color(0xFF208C4E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // 상세 화면

  Widget _buildDetailScreen(BuildContext context, Notice n) {
    final title = n.title;
    final date = _fmtDate(n.createdAt);
    final content = n.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단: 제목 + 배지 + 날짜
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildCategoryBadge(n),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEAEAEA)),

        // 본문 스크롤 영역
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Text(
              content.isEmpty ? '내용이 없습니다.' : content,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primaryText,
                height: 1.5,
              ),
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEAEAEA)),

        // 하단: 목록으로 이동 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedNotice = null;
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return AppColors.border; // Disabled
                  }
                  if (states.contains(MaterialState.pressed)) {
                    return AppColors.primaryText.withOpacity(0.9); // Pressed
                  }
                  if (states.contains(MaterialState.hovered)) {
                    return AppColors.secondaryText; // Hover
                  }
                  return AppColors.primaryText; // Default
                }),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.primaryText,
);
const double _rowHorizontalPadding = 10;
const double _badgeContentGap = 24;
