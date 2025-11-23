class AuctionItem {
  final int id;
  final String name;
  final int price;

  // ✅ 판매자는 선택사항으로 변경 (UI에서 안 써도 됨)
  final String? seller;

  // ✅ 썸네일(자산) 경로
  final String? imagePath;

  // ✅ 찜 여부 (기본값 false)
  final bool isFavorite;

  const AuctionItem({
    required this.id,
    required this.name,
    required this.price,
    this.seller,
    this.imagePath,
    this.isFavorite = false, // 기본값
  });

  AuctionItem copyWith({
    int? id,
    String? name,
    int? price,
    String? seller,
    String? imagePath,
    bool? isFavorite,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      seller: seller ?? this.seller,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory AuctionItem.fromJson(Map<String, dynamic> j) => AuctionItem(
        id: j['id'] as int,
        name: j['name'] as String,
        price: j['price'] as int,
        seller: j['seller'] as String?,
        imagePath: j['imagePath'] as String?,
        // ✅ JSON에 없으면 false로
        isFavorite: j['isFavorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'seller': seller,
        'imagePath': imagePath,
        'isFavorite': isFavorite,
      };
}
