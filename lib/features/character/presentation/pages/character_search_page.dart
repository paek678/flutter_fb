import 'package:flutter/material.dart';

import '../../models/domain/character.dart';
import '../../models/domain/ranking_row.dart';

import '../../repository/firebase_character_repository.dart';
import '../../../../core/services/firebase_service.dart';
// 추가: Firebase 연동용 import

import '../widgets/page_ranking_row.dart';
import '../widgets/page_character_search_input.dart';
import 'character_search_result.dart';
import 'character_detail_page.dart';

class CharacterSearchTab extends StatefulWidget {
  final void Function(int)? onTabChange;

  /// 필요하면 부모 위젯에서 직접 레포지토리를 주입해서 사용할 수 있도록 함
  final FirebaseCharacterRepository? repository;

  /// 추가 옵션: 초기 검색어
  final String? initialQuery;

  const CharacterSearchTab({
    super.key,
    this.onTabChange,
    this.repository,
    this.initialQuery,
  });

  @override
  State<CharacterSearchTab> createState() => _CharacterSearchTabState();
}

class _CharacterSearchTabState extends State<CharacterSearchTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  String _selectedServer = '전체';
  bool _isSearching = false;

  // 검색 결과
  List<Character> _searchResults = [];

  // 랭킹 표시용 데이터
  List<RankingRow> _rankingRows = [];
  bool _isRankingLoading = true;

  TabController? _tabController;

  late final FirebaseCharacterRepository _repository;

  @override
  bool get wantKeepAlive => false;

  final List<String> _servers = const [
    '전체',
    '카인',
    '디레지에',
    '시로코',
    '프레이',
    '힐더',
    '바칼',
    '안톤',
    '카시아스',
  ];

  @override
  void initState() {
    super.initState();

    // 기본 레포지토리는 InMemory가 아닌 Firebase 레포지토리 사용
    _repository = widget.repository ?? FirebaseCharacterRepository();

    // initialQuery가 있으면 검색창 기본값으로 세팅
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!.trim();
      // 필요하면 자동 검색까지 수행하고 싶을 때 아래 주석 해제
      // _searchCharacter();
    }

    _loadRanking(); // 초기 진입 시 랭킹 프리뷰 불러오기
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 상위의 DefaultTabController가 있으면 같은 컨트롤러를 사용
    final controller = DefaultTabController.maybeOf(context);
    if (controller != null && controller != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    const myIndex = 0; // 이 탭의 인덱스가 0번이라고 가정

    if (_tabController == null) return;

    if (_tabController!.index != myIndex) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _controller.clear();
        });
      }
    }
  }

  Future<void> _loadRanking() async {
    setState(() {
      _isRankingLoading = true;
    });

    try {
      final server = _selectedServer == '전체' ? null : _selectedServer;

      // 1) ranking_entries 프리뷰에서 상위 3개
      List<RankingRow> rows =
          await _repository.fetchRankingPreview(server: server);
      rows = rows.take(3).toList();

      // 2) 프리뷰가 비어 있으면 collectionGroup에서 상위 3개 fallback
      if (rows.isEmpty) {
        final fromAll = await FirestoreService.fetchAllRankingRows(
          serverId: server,
          limit: 3,
        );
        fromAll.sort((a, b) => b.fame.compareTo(a.fame));
        rows = fromAll.take(3).toList();
      }

      if (!mounted) return;
      setState(() {
        _rankingRows = rows; // 상위 3개만 표시
        _isRankingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rankingRows = [];
        _isRankingLoading = false;
      });
      // 필요하면 스낵바 등으로 에러 메시지 출력
    }
  }

  Future<void> _searchCharacter() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('캐릭터 이름을 입력해주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final server = _selectedServer == '전체' ? null : _selectedServer;

      final results = await _repository.searchCharacters(
        name: query,
        server: server,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
      });
      // 에러 로그만 찍고, 필요하면 추가 예외 처리
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 검색 결과 화면
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: CharacterSearchResult(
                query: _controller.text,
                results: _searchResults,
                onCharacterSelected: (character) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharacterDetailView(character: character),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // 기본 검색 + 랭킹 프리뷰 화면
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CharacterSearchInputFull(
                selectedServer: _selectedServer,
                servers: _servers,
                controller: _controller,
                onServerChanged: (value) {
                  setState(() {
                    _selectedServer = value;
                  });
                  _loadRanking();
                },
                onSearch: _searchCharacter,
              ),
              const SizedBox(height: 24),
              _isRankingLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RankingTableContainer(
                      titleDate: '11월 9일 기준',
                      serverName: _selectedServer,
                      rows: _rankingRows,
                      onMoreTap: () {
                        widget.onTabChange?.call(1);
                      },
                      // 추가: 랭킹 row를 탭하면 characterId로 상세 조회 화면으로 이동
                      onRowTap: (row) async {
                        final character = await _repository.getCharacterById(
                          row.characterId,
                        );
                        if (!mounted || character == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CharacterDetailView(character: character),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
