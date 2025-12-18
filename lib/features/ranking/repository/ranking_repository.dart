import '../../character/models/domain/ranking_row.dart';
import '../../../core/services/firebase_service.dart';

abstract class RankingRepository {
  Future<List<RankingRow>> fetchRankingRows({String? serverId});
}

class FirestoreRankingRepository implements RankingRepository {
  const FirestoreRankingRepository();

  @override
  Future<List<RankingRow>> fetchRankingRows({String? serverId}) async {
    final rows = await FirestoreService.fetchAllRankingRows(serverId: serverId);
    return rows;
  }
}
