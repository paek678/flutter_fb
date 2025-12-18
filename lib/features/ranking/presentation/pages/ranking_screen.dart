import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/job_data.dart';
import '../../widgets/awakening_selector.dart';
import '../../widgets/job_selector.dart';
import '../../widgets/ranking_list.dart';
import '../../widgets/server_selector.dart';
import '../../../character/presentation/pages/character_detail_page.dart';
import '../../../character/models/domain/character.dart';
import '../../../character/models/domain/ranking_row.dart';
import '../../repository/ranking_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

enum DfServer { all, cain, diregie, siroco, prey, casyas, hilder, anton, bakal }

extension DfServerX on DfServer {
  String get label => switch (this) {
        DfServer.all => '전체',
        DfServer.cain => '카인',
        DfServer.diregie => '디레지에',
        DfServer.siroco => '시로코',
        DfServer.prey => '프레이',
        DfServer.casyas => '카시야스',
        DfServer.hilder => '힐더',
        DfServer.anton => '안톤',
        DfServer.bakal => '바칼',
      };

  String? get id => switch (this) {
        DfServer.all => null,
        DfServer.cain => 'cain',
        DfServer.diregie => 'diregie',
        DfServer.siroco => 'siroco',
        DfServer.prey => 'prey',
        DfServer.casyas => 'casyas',
        DfServer.hilder => 'hilder',
        DfServer.anton => 'anton',
        DfServer.bakal => 'bakal',
      };
}

DfServer serverFromLabel(String label) {
  return DfServer.values.firstWhere(
    (s) => s.label == label,
    orElse: () => DfServer.all,
  );
}

String serverLabelFromId(String id) {
  return DfServer.values
      .firstWhere((s) => s.id == id, orElse: () => DfServer.all)
      .label;
}

class RankingScreen extends StatefulWidget {
  final RankingRepository? repository;
  const RankingScreen({super.key, this.repository});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final RankingRepository _repo;

  DfServer _selectedServer = DfServer.all;
  String? _selectedJob;
  String? _selectedAwakening;

  bool _loading = false;
  String? _error;
  List<RankingRow> _rankingRows = [];

  List<String> get _serverLabels =>
      DfServer.values.map((e) => e.label).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? const FirestoreRankingRepository();
    _fetchRankingRows();
  }

  Future<void> _fetchRankingRows() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _repo.fetchRankingRows(serverId: _selectedServer.id);
      final sortedByFame = List<RankingRow>.from(rows)
        ..sort((a, b) => b.fame.compareTo(a.fame));
      final ranked = List<RankingRow>.generate(
        sortedByFame.length,
        (i) => sortedByFame[i].copyWith(rank: i + 1),
      );

      if (kDebugMode) {
        debugPrint(
            '[RankingScreen] fetched ${ranked.length} rows (server=${_selectedServer.label})');
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
              servers: _serverLabels,
              selectedServer: _selectedServer.label,
              onServerSelected: (server) {
                setState(() => _selectedServer = serverFromLabel(server));
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

    final selectedServerId = _selectedServer.id;
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
        'rank': i + 1,
        'name': row.name,
        'class': row.jobGrowName.isNotEmpty ? row.jobGrowName : row.job,
        'server': serverLabelFromId(row.serverId),
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
        final fameRaw = characterMap['power'] ?? characterMap['score'] ?? '0';
        final fame = int.tryParse('$fameRaw') ?? 0;

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
      _selectedJob = job == '전체' ? null : job;
      _selectedAwakening = null;
    });
  }

  void _onAwakeningSelected(String aw) {
    setState(() => _selectedAwakening = aw == '전체' ? null : aw);
  }
}
