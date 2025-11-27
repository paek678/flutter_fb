// lib/features/character/repository/character_repository.dart
import '../models/domain/character.dart';
import '../models/domain/ranking_row.dart';
import '../models/domain/character_info.dart';

abstract class CharacterRepository {
  /// 랭킹 미리보기 (서버별 상위 N명)
  Future<List<RankingRow>> fetchRankingPreview({String? server});

  /// 캐릭터 검색
  Future<List<Character>> searchCharacters({
    required String name,
    String? server,
  });

  /// 캐릭터 단건 조회 (랭킹 → 상세 이동용)
  Future<Character?> getCharacterById(String characterId);

  /// 상세 정보 조회 (상세 페이지 전체 데이터)
  Future<CharacterInfo?> getCharacterInfoById(String characterId);
}
