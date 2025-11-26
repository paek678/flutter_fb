import 'package:flutter/material.dart';

import '../../models/domain/character.dart';
import '../../models/domain/ranking_row.dart';

import '../../repository/character_repository.dart';
// ⭐ 추가: Firebase 구현체 import
import '../../repository/firebase_character_repository.dart'; // ★ NEW

import '../widgets/page_ranking_row.dart';
import '../widgets/page_character_search_input.dart';
import 'character_search_result.dart';
import 'character_detail_page.dart';

class CharacterSearchTab extends StatefulWidget {
  final void Function(int)? onTabChange;
  final CharacterRepository? repository;

  // ✅ 추가: 초기 검색어
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

  List<Character> _searchResults = [];
  List<RankingRow> _rankingRows = [];
  bool _isRankingLoading = true;

  TabController? _tabController;
  late final CharacterRepository _repository;

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
    _repository = widget.repository ?? FirebaseCharacterRepository();
    _loadRanking();

    // ✅ TopAppBar에서 넘어온 초기 검색어 처리
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      Future.microtask(_searchCharacter);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ 탭 컨트롤러가 없을 수도 있으니 maybeOf 사용
    final controller = DefaultTabController.maybeOf(context);

    if (controller == null) {
      // 이전에 다른 탭에서 쓰다가 이제 단독 화면에서 쓸 수도 있으니까 정리
      if (_tabController != null) {
        _tabController!.removeListener(_onTabChanged);
        _tabController = null;
      }
      return;
    }

    if (controller != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    const myIndex = 0;

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rankingRows = [];
        _isRankingLoading = false;
      });
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
      });
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

    // ✅ Expanded 중첩 제거: 바깥 Expanded 삭제
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
      );
    }

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
