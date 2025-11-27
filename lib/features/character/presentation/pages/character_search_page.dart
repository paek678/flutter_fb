import 'package:flutter/material.dart';

import '../../models/domain/character.dart';
import '../../models/domain/ranking_row.dart';

import '../../repository/firebase_character_repository.dart';
// ⭐ 추가: Firebase 구현체 import

import '../widgets/page_ranking_row.dart';
import '../widgets/page_character_search_input.dart';
import 'character_search_result.dart';
import 'character_detail_page.dart';

class CharacterSearchTab extends StatefulWidget {
  final void Function(int)? onTabChange;

  /// 필요하면 바깥에서 다른 구현체를 주입할 수도 있음
  final FirebaseCharacterRepository? repository;

  /// 🔹 추가: 초기 검색어
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

  // 랭킹 미리보기
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
    '카시야스',
    '힐더',
    '안톤',
    '바칼',
  ];

  @override
  void initState() {
    super.initState();

    // ⭐ 기본 구현체를 InMemory → Firebase로
    _repository = widget.repository ?? FirebaseCharacterRepository();

    // 🔹 initialQuery가 있으면 검색창에 세팅
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!.trim();
      // 필요하면 자동 검색까지 하고 싶으면 주석 해제
      // _searchCharacter();
    }

    _loadRanking(); // 시작 시 랭킹 한 번 불러오기
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = DefaultTabController.maybeOf(context); // ← 이게 되면 제일 깔끔
    if (controller != null && controller != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    const myIndex = 0; // 캐릭터 탭이 0번째라고 가정

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

      final rows = await _repository.fetchRankingPreview(server: server);

      if (!mounted) return;
      setState(() {
        _rankingRows = rows;
        _isRankingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rankingRows = [];
        _isRankingLoading = false;
      });
      // 필요하면 스낵바로 에러 표시
    }
  }

  Future<void> _searchCharacter() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('캐릭터 이름을 입력하세요.')));
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
      // 에러 표현하고 싶으면 여기서 처리
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

    // 🔹 검색 결과 화면
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

    // 🔹 기본 검색 + 랭킹 미리보기 화면
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
                      titleDate: '11월 9일',
                      serverName: _selectedServer,
                      rows: _rankingRows,
                      onMoreTap: () {
                        widget.onTabChange?.call(1);
                      },
                      // ⭐ 추가: 랭킹 row 눌렀을 때 → characterId로 상세 조회 후 이동
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
