class ItemPrice {
  final String itemId;
  final String name; // 아이템 이름
  final int avgPrice; // 평균가
  final String trend; // "+2.1%"
  final int? lastPrice;
  final int? prevPrice;
  final List<int> recentUnitPrices;
  final DateTime? latestSoldAt;
  final DateTime? updatedAt;

  const ItemPrice({
    required this.itemId,
    required this.name,
    required this.avgPrice,
    required this.trend,
    this.lastPrice,
    this.prevPrice,
    this.recentUnitPrices = const <int>[],
    this.latestSoldAt,
    this.updatedAt,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory ItemPrice.fromJson(Map<String, dynamic> json) {
    return ItemPrice(
      itemId: json['itemId'] as String? ?? '',
      name: (json['name'] ?? json['itemName'] ?? '') as String,
      avgPrice: (json['avgPrice'] as num?)?.toInt() ?? 0,
      trend: json['trend'] as String? ?? '0.0%',
      lastPrice: (json['lastPrice'] as num?)?.toInt(),
      prevPrice: (json['prevPrice'] as num?)?.toInt(),
      recentUnitPrices: (json['recentUnitPrices'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      latestSoldAt: _parseDate(json['latestSoldAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'avgPrice': avgPrice,
        'trend': trend,
        'lastPrice': lastPrice,
        'prevPrice': prevPrice,
        'recentUnitPrices': recentUnitPrices,
        'latestSoldAt': latestSoldAt,
        'updatedAt': updatedAt,
      };
}
