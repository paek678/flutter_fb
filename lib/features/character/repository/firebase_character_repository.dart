// lib/features/character/repository/firebase_character_repository.dart

import '../models/domain/character.dart';
import '../models/domain/ranking_row.dart';
import '../models/domain/character_info.dart';
import 'character_repository.dart';
import '../../../core/services/firebase_service.dart';

class FirebaseCharacterRepository implements CharacterRepository {
  const FirebaseCharacterRepository();

  @override
  Future<List<RankingRow>> fetchRankingPreview({String? server}) {
    return FirestoreService.fetchRankingPreview(server: server);
  }

  @override
  Future<List<Character>> searchCharacters({
    required String name,
    String? server,
  }) {
    return FirestoreService.searchCharacters(name: name, serverId: server);
  }

  @override
  Future<Character?> getCharacterById(String characterId) {
    return FirestoreService.fetchCharacterById(characterId);
  }

  @override
  Future<CharacterInfo?> getCharacterInfoById(String characterId) {
    return FirestoreService.fetchCharacterInfoById(characterId);
  }
}
