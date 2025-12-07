import 'item_price.dart';
import 'auction_item_data.dart' as detail;

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

  // 상세 필드 (있을 때만 채움)
  final String? rarity;
  final detail.RarityCode? rarityCode;
  final String? type;
  final String? subType;
  final int? levelLimit;
  final detail.AttackStats? attack;
  final int? intelligence;
  final int? combatPower;
  final List<String>? options;
  final double? weightKg;
  final String? durability;
  final Map<detail.PriceRange, List<double>>? history;

  const AuctionItem({
    required this.id,
    required this.name,
    required this.price,
    this.seller,
    this.imagePath,
    this.isFavorite = false,
    this.itemPrice,
    this.rarity,
    this.rarityCode,
    this.type,
    this.subType,
    this.levelLimit,
    this.attack,
    this.intelligence,
    this.combatPower,
    this.options,
    this.weightKg,
    this.durability,
    this.history,
  });

  AuctionItem copyWith({
    int? id,
    String? name,
    int? price,
    String? seller,
    String? imagePath,
    bool? isFavorite,
    ItemPrice? itemPrice,
    String? rarity,
    detail.RarityCode? rarityCode,
    String? type,
    String? subType,
    int? levelLimit,
    detail.AttackStats? attack,
    int? intelligence,
    int? combatPower,
    List<String>? options,
    double? weightKg,
    String? durability,
    Map<detail.PriceRange, List<double>>? history,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      seller: seller ?? this.seller,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      itemPrice: itemPrice ?? this.itemPrice,
      rarity: rarity ?? this.rarity,
      rarityCode: rarityCode ?? this.rarityCode,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      levelLimit: levelLimit ?? this.levelLimit,
      attack: attack ?? this.attack,
      intelligence: intelligence ?? this.intelligence,
      combatPower: combatPower ?? this.combatPower,
      options: options ?? this.options,
      weightKg: weightKg ?? this.weightKg,
      durability: durability ?? this.durability,
      history: history ?? this.history,
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
        rarity: j['rarity'] as String?,
        rarityCode: j['rarityCode'] != null
            ? detail.RarityCode.values
                .firstWhere((e) => e.name == j['rarityCode'])
            : null,
        type: j['type'] as String?,
        subType: j['subType'] as String?,
        levelLimit: j['levelLimit'] as int?,
        attack: j['attack'] != null
            ? detail.AttackStatsJsonX.fromJson(
                Map<String, dynamic>.from(j['attack'] as Map))
            : null,
        intelligence: j['intelligence'] as int?,
        combatPower: j['combatPower'] as int?,
        options: (j['options'] as List?)?.map((e) => e.toString()).toList(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        durability: j['durability'] as String?,
        history: j['history'] != null
            ? (j['history'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(
                  detail.PriceRange.values
                      .firstWhere((e) => e.name == k, orElse: () => detail.PriceRange.d7),
                  (v as List).map((e) => (e as num).toDouble()).toList(),
                ),
              )
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
        'rarity': rarity,
        'rarityCode': rarityCode?.name,
        'type': type,
        'subType': subType,
        'levelLimit': levelLimit,
        'attack': attack?.toJson(),
        'intelligence': intelligence,
        'combatPower': combatPower,
        'options': options,
        'weightKg': weightKg,
        'durability': durability,
        'history': history?.map(
          (k, v) => MapEntry(k.name, v),
        ),
      };
}
