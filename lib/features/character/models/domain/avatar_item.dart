  // lib/features/character/models/avatar_item.dart
  class AvatarItem {
    final String category; // 모자 아바타, 크리쳐 등
    final List<String> images; // 아바타/크리쳐 이미지들 (url 또는 asset 경로)
    final String name; // 아바타/크리쳐 이름
    final String option; // 옵션 (없으면 "" 로 내려옴)
    final String desc; // 엠블렘 설명 등

    const AvatarItem({
      required this.category,
      required this.images,
      required this.name,
      required this.option,
      required this.desc,
    });

    factory AvatarItem.fromJson(Map<String, dynamic> json) {
      return AvatarItem(
        category: json['category'] as String? ?? '',
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        name: json['name'] as String? ?? '',
        option: json['option'] as String? ?? '',
        desc: json['desc'] as String? ?? '',
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'category': category,
        'images': images,
        'name': name,
        'option': option,
        'desc': desc,
      };
    }
  }
