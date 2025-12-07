// lib/features/character/models/buff_item.dart
class BuffItem {
  final String category; // 버프 아바타, 크리쳐 무기 ...
  final String imagePath; // 이미지경로 (asset 또는 url)
  final String name; // 아이템 이름
  final String grade; // 등급: 희귀, 에픽, 전설 등
  final String option; // 옵션 텍스트. 없으면 "" (빈문자열)

  const BuffItem({
    required this.category,
    required this.imagePath,
    required this.name,
    required this.grade,
    required this.option,
  });

  factory BuffItem.fromJson(Map<String, dynamic> json) {
    return BuffItem(
      category: json['category'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      name: json['name'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      option: json['option'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'imagePath': imagePath,
      'name': name,
      'grade': grade,
      'option': option,
    };
  }
}
