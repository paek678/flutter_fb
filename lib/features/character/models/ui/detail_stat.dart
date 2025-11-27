// lib/features/character/models/ui/detail_stat.dart
class DetailStat {
  final String name;
  final String value;

  const DetailStat({required this.name, required this.value});

  factory DetailStat.fromJson(Map<String, dynamic> json) {
    return DetailStat(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }
}
