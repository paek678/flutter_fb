// lib/features/character/models/equipment_slot.dart
import '../domain/equipment_item.dart';

/// UI에서 사용할 고정 장비 카테고리 목록
const List<String> kEquipmentCategories = [
  '무기',
  '칭호',
  '상의',
  '머리어깨',
  '하의',
  '신발',
  '벨트',
  '목걸이',
  '팔찌',
  '반지',
  '보조장비',
  '마법석',
  '귀걸이',
];

/// 화면에 보여줄 "슬롯" 단위
/// - category: 슬롯 이름 (무기, 상의, ...)
/// - item: 실제 장비 (없으면 null)
class EquipmentSlot {
  final String category;
  final EquipmentItem? item;

  const EquipmentSlot({required this.category, this.item});

  bool get isEmpty => item == null;
}

/// Firestore에서 받아온 장비 리스트를
/// 고정 카테고리 기준 슬롯 리스트로 변환
List<EquipmentSlot> buildSlotsFromItems(List<EquipmentItem> items) {
  // 카테고리 → 장비 매핑
  final Map<String, EquipmentItem> mapByCategory = {};

  for (final item in items) {
    if (item.category == '세트') continue;
    // 같은 카테고리 여러 개면 마지막 것이 덮어씀
    mapByCategory[item.category] = item;
  }

  // 고정 카테고리 순서대로 슬롯 생성
  return kEquipmentCategories.map((category) {
    return EquipmentSlot(
      category: category,
      item: mapByCategory[category], // 없으면 null
    );
  }).toList();
}
