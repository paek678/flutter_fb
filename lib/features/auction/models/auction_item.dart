import 'item_price.dart';

class AuctionItem {
  final int id;
  final String name;
  final int price;

  // 판매자는 선택 항목(UI 표시용)
  final String? seller;

  // 썸네일(리소스) 경로
  final String? imagePath;

  // 즐겨찾기 여부 (기본값 false)
  final bool isFavorite;

  // item_prices 컬렉션에서 가져온 가격 정보
  final ItemPrice? itemPrice;

  const AuctionItem({
    required this.id,
    required this.name,
    required this.price,
    this.seller,
    this.imagePath,
    this.isFavorite = false,
    this.itemPrice,
  });

  AuctionItem copyWith({
    int? id,
    String? name,
    int? price,
    String? seller,
    String? imagePath,
    bool? isFavorite,
    ItemPrice? itemPrice,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      seller: seller ?? this.seller,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      itemPrice: itemPrice ?? this.itemPrice,
    );
  }

  factory AuctionItem.fromJson(Map<String, dynamic> j) => AuctionItem(
        id: j['id'] as int,
        name: j['name'] as String,
        price: j['price'] as int,
        seller: j['seller'] as String?,
        imagePath: j['imagePath'] as String?,
        isFavorite: j['isFavorite'] as bool? ?? false,
        itemPrice: j['itemPrice'] != null
            ? ItemPrice.fromJson(j['itemPrice'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'seller': seller,
        'imagePath': imagePath,
        'isFavorite': isFavorite,
        'itemPrice': itemPrice?.toJson(),
      };
}
