// lib/features/board/presentation/board_list_screen.dart
import 'package:flutter/material.dart';

import '../model/notice.dart';
import '../model/notice_category.dart';
import '../repository/notice_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum NoticeFilter { all, event, maintenance }

extension NoticeFilterX on NoticeFilter {
  NoticeCategory? get category => switch (this) {
        NoticeFilter.all => null,
        NoticeFilter.event => NoticeCategory.event,
        NoticeFilter.maintenance => NoticeCategory.maintenance,
      };

  String get label => switch (this) {
        NoticeFilter.all => '전체',
        NoticeFilter.event => '이벤트',
        NoticeFilter.maintenance => '점검',
      };
}

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final NoticeRepository _repo = FirestoreNoticeRepository();

  NoticeFilter _selectedFilter = NoticeFilter.all;
  List<Notice> _notices = [];
  bool _loading = true;
  Notice? _selectedNotice;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices([NoticeFilter? filter]) async {
    final nextFilter = filter ?? _selectedFilter;
    setState(() => _loading = true);

    final data = await _repo.fetchNotices(category: nextFilter.category);

    if (!mounted) return;
    setState(() {
      _selectedFilter = nextFilter;
      _notices = data;
      _loading = false;
      _selectedNotice = null;
    });
  }

  void _openDetail(Notice notice) {
    setState(() => _selectedNotice = notice);
  }

  Future<void> _openWrite() async {
    final result = await Navigator.pushNamed(
      context,
      '/notice_write',
      arguments: _repo,
    );
    if (result is Notice) {
      await _loadNotices(_selectedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDetail = _selectedNotice != null;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                margin: isDetail
                    ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
                    : const EdgeInsets.only(top: 16),
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
                    if (!isDetail) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '공지사항',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _NoticeFilterBar(
                        selected: _selectedFilter,
                        onChanged: _loadNotices,
                      ),
                      const _NoticeHeader(),
                    ],
                    Expanded(
                      child: isDetail && _selectedNotice != null
                          ? _NoticeDetailView(
                              notice: _selectedNotice!,
                              onBack: () => setState(() {
                                _selectedNotice = null;
                              }),
                            )
                          : _NoticeListView(
                              notices: _notices,
                              loading: _loading,
                              onRefresh: () => _loadNotices(_selectedFilter),
                              onSelect: _openDetail,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!isDetail)
          Positioned(
            right: 24,
            bottom: 24,
            child: _WriteButton(onTap: _openWrite),
          ),
      ],
    );
  }
}

class _NoticeFilterBar extends StatelessWidget {
  final NoticeFilter selected;
  final ValueChanged<NoticeFilter> onChanged;

  const _NoticeFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in NoticeFilter.values) ...[
              _FilterPill(
                filter: filter,
                isSelected: filter == selected,
                onTap: () => onChanged(filter),
              ),
              if (filter != NoticeFilter.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final NoticeFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          filter.label,
          style: AppTextStyles.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NoticeHeader extends StatelessWidget {
  const _NoticeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
    );
  }
}

class _NoticeListView extends StatelessWidget {
  final List<Notice> notices;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<Notice> onSelect;

  const _NoticeListView({
    required this.notices,
    required this.loading,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (notices.isEmpty) {
      return Center(
        child: Text(
          '공지사항이 없습니다.',
          style: AppTextStyles.body2.copyWith(color: AppColors.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryText,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return _NoticeRow(
            notice: notice,
            onTap: () => onSelect(notice),
          );
        },
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeRow({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding,
          vertical: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 72, child: _NoticeCategoryBadge(notice)),
            const SizedBox(width: _badgeContentGap),
            Expanded(
              child: Text(
                notice.title,
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
}

class _NoticeCategoryBadge extends StatelessWidget {
  final Notice notice;
  const _NoticeCategoryBadge(this.notice);

  @override
  Widget build(BuildContext context) {
    final c = notice.category;

    String label = '공지';
    Color bg = const Color(0xFFE9F5EE);
    Color textColor = const Color(0xFF208C4E);

    switch (c) {
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
      case NoticeCategory.general:
      default:
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
}

class _NoticeDetailView extends StatelessWidget {
  final Notice notice;
  final VoidCallback onBack;

  const _NoticeDetailView({
    required this.notice,
    required this.onBack,
  });

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = notice.title;
    final date = _fmtDate(notice.createdAt);
    final content = notice.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  _NoticeCategoryBadge(notice),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBack,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (states) {
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
                  },
                ),
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
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

class _WriteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WriteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('공지 작성'),
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
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.primaryText,
);
const double _rowHorizontalPadding = 10;
const double _badgeContentGap = 24;
