import 'package:flutter/material.dart';

import '../../data/job_data.dart';
import '../../widgets/awakening_selector.dart';
import '../../widgets/job_selector.dart';
import '../../widgets/ranking_list.dart';
import '../../widgets/server_selector.dart';
import '../../../character/presentation/pages/character_detail_page.dart';
import '../../../character/models/domain/character.dart';
import '../../../character/models/domain/ranking_row.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _selectedServer = '전체';
  String? _selectedJob;
  String? _selectedAwakening;

  bool _loading = false;
  String? _error;
  List<RankingRow> _rankingRows = [];

  final List<String> _servers = [
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
    _fetchRankingRows();
  }

  Future<void> _fetchRankingRows() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await FirestoreService.fetchAllRankingRows(
        serverId: _serverIdFromName(_selectedServer),
      );
      final sortedByFame = List<RankingRow>.from(rows)
        ..sort((a, b) => b.fame.compareTo(a.fame));
      final ranked = List<RankingRow>.generate(
        sortedByFame.length,
        (i) => sortedByFame[i].copyWith(rank: i + 1),
      );
      // Debug: incoming ranking rows snapshot (전체 출력)
      debugPrint('[RankingScreen] fetched ${ranked.length} rows (server=$_selectedServer)');
      for (final row in ranked) {
        debugPrint(
          ' - #${row.rank} ${row.name} / ${row.jobGrowName} / ${row.serverId} fame=${row.fame} level=${row.level} image=${row.imagePath}',
        );
      }
      if (!mounted) return;
      setState(() {
        _rankingRows = ranked;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '랭킹 데이터를 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = JobData.getJobs();
    final awakenings = JobData.getAwakenings(_selectedJob);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServerSelector(
              servers: _servers,
              selectedServer: _selectedServer,
              onServerSelected: (server) {
                setState(() => _selectedServer = server);
                _fetchRankingRows();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            JobSelector(
              jobs: jobs,
              selectedJob: _selectedJob,
              onJobSelected: _onJobSelected,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedJob != null)
              AwakeningSelector(
                job: _selectedJob!,
                awakenings: awakenings,
                selectedAwakening: _selectedAwakening,
                onAwakeningSelected: _onAwakeningSelected,
              ),
            const SizedBox(height: AppSpacing.md),
            _buildRankingSection(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingSection() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 선택된 서버/직업/각성에 맞춰 필터링 (선택 안 하면 전체 표시)
    final selectedServerId = _serverIdFromName(_selectedServer);
    final filteredRows = _rankingRows.where((row) {
      if (selectedServerId != null && row.serverId != selectedServerId) {
        return false;
      }
      if (_selectedJob != null && row.job != _selectedJob) {
        return false;
      }
      if (_selectedAwakening != null &&
          _selectedAwakening!.isNotEmpty &&
          row.jobGrowName != _selectedAwakening) {
        return false;
      }
      return true;
    }).toList();

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    if (filteredRows.isEmpty) {
      return const Center(
        child: Text(
          '랭킹 데이터가 없습니다.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    final rankingData = List.generate(filteredRows.length, (i) {
      final row = filteredRows[i];
      return {
        'rank': i + 1, // 화면에는 순차 번호로 표시
        'name': row.name,
        'class': row.jobGrowName.isNotEmpty ? row.jobGrowName : row.job,
        'server': _serverNameFromId(row.serverId),
        'serverId': row.serverId,
        'level': row.level,
        'power': row.fame.toString(),
        'image': row.imagePath.isNotEmpty
            ? row.imagePath
            : 'assets/images/character1.png',
        'characterId': row.characterId,
        'id': row.id,
      };
    });

    return RankingList(
      job: _selectedJob ?? '전체',
      awakening: _selectedAwakening ?? '전체',
      rankingData: rankingData,
      onTapCharacter: (characterMap) {
        debugPrint('[RankingScreen] onTapCharacter raw=$characterMap');
        final fameRaw = characterMap['power'] ?? characterMap['score'] ?? '0';
        final fame = int.tryParse('$fameRaw') ?? 0;

        // 랭킹 → 상세: 서버 코드 접두사를 항상 붙여 전달
        final serverId = characterMap['serverId'] as String? ?? '';
        String characterId = characterMap['characterId'] as String? ??
            characterMap['id'] as String? ??
            '';
        if (serverId.isNotEmpty &&
            characterId.isNotEmpty &&
            !characterId.startsWith('${serverId}_')) {
          characterId = '${serverId}_$characterId';
        }

        final character = Character(
          id: characterId,
          name: characterMap['name'] as String? ?? 'Unknown',
          job: characterMap['class'] as String? ?? '',
          level: characterMap['level'] as int? ?? 0,
          server: characterMap['server'] as String? ?? '',
          imagePath: characterMap['image'] as String? ??
              'assets/images/character1.png',
          fame: fame,
        );

        debugPrint(
          '[RankingScreen] onTapCharacter -> Character(id=${character.id}, name=${character.name}, server=${character.server}, job=${character.job}, fame=${character.fame}, level=${character.level})',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CharacterDetailView(character: character, fromRanking: true),
          ),
        );
      },
    );
  }

  void _onJobSelected(String job) {
    setState(() {
      // "전체" 선택 시 필터 해제
      _selectedJob = job == '전체' ? null : job;
      _selectedAwakening = null;
    });
  }

  void _onAwakeningSelected(String aw) {
    // "전체" 선택 시 필터 해제
    setState(() => _selectedAwakening = aw == '전체' ? null : aw);
  }

  String? _serverIdFromName(String name) {
    if (name == '전체') return null;

    const map = <String, String>{
      '카인': 'cain',
      '디레지에': 'diregie',
      '시로코': 'siroco',
      '프레이': 'prey',
      '카시야스': 'casyas',
      '힐더': 'hilder',
      '안톤': 'anton',
      '바칼': 'bakal',
    };

    return map[name];
  }

  String _serverNameFromId(String id) {
    const map = <String, String>{
      'cain': '카인',
      'diregie': '디레지에',
      'siroco': '시로코',
      'prey': '프레이',
      'casyas': '카시야스',
      'hilder': '힐더',
      'anton': '안톤',
      'bakal': '바칼',
    };
    if (id.isEmpty) return '';
    return map[id] ?? id;
  }
}
