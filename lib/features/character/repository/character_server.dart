// import 'package:flutter_fb/features/character/models/domain/character.dart';
// import 'package:flutter_fb/features/character/models/domain/character_stats.dart';
// import 'package:flutter_fb/features/character/models/domain/ranking_row.dart';
// import 'package:flutter_fb/features/character/models/ui/detail_stat.dart';

// import '../models/domain/avatar_item.dart';
// import '../models/domain/buff_item.dart';
// import '../models/domain/equipment_item.dart';
// import '../models/domain/character_detail_stats.dart';


// Future<Character> getCharacter() async {
//   // 스텁/더미 데이터 사용 또는 실제 API 호출 가능
//   // 예: 리포지토리 호출
//   return dummyCharacter;
// }


// final Character dummyCharacter = Character(
//   id: 'char_laDogker',
//   name: '라독커',
//   server: '바칼',
//   job: '진 웨펀마스터',
//   level: 100,
//   fame: '82370',
//   imagePath: '',

//   stats:dummyCharacterStats,
//   detailStats: dummyDetailStats,
//   equipments: dummyEquipmentItems,
//   avatars: dummyAvatarItems,
//   buffItems: dummyBuffItems,
//   rankingHistory: const [],

//   // 만약 Character 클래스에 basicStats, extraDetailStats 필드가 있다면
//   // basicStats: dummyBasicStats,
//   // extraDetailStats: dummyExtraDetailStats,
// );


// final List<EquipmentItem> dummyEquipmentItems = [
//   EquipmentItem(
//     category: '무기',
//     imagePath: '',
//     name: '멸룡검 발뭉',
//     grade: '',
//     option: '모속강 +15, 공격력 +30',
//     desc: '0 / 0+15증폭',
//   ),
//   EquipmentItem(
//     category: '칭호',
//     imagePath: '',
//     name: '순백의 눈꽃 결정[30Lv]',
//     grade: '',
//     option: '명속강 +6, 스탯 +25',
//     desc: '+0강화',
//   ),
//   EquipmentItem(
//     category: '상의',
//     imagePath: '',
//     name: '고위 여우의 상의',
//     grade: 'Ⅲ',
//     option: '스증 +2%, 스탯 +90, 공격력 +110',
//     desc: '욕망+13증폭',
//   ),
//   EquipmentItem(
//     category: '머리어깨',
//     imagePath: '',
//     name: '고위 여우의 보호 어깨',
//     grade: 'Ⅲ',
//     option: '스증 +3%, 스탯 +40, 공격력 +10, 크리 +5%',
//     desc: '영원+13증폭',
//   ),
//   EquipmentItem(
//     category: '하의',
//     imagePath: '',
//     name: '고위 여우의 그림자 하의',
//     grade: 'Ⅲ',
//     option: '스증 +2%, 스탯 +90, 공격력 +110',
//     desc: '욕망+13증폭',
//   ),
//   EquipmentItem(
//     category: '신발',
//     imagePath: '',
//     name: '고위 여우의 은빛 신발',
//     grade: 'Ⅲ',
//     option: '스증 +2%, 스탯 +40, 공격력 +10, 크리 +3%',
//     desc: '영원+13증폭',
//   ),
//   EquipmentItem(
//     category: '벨트',
//     imagePath: '',
//     name: '고위 여우의 비밀 벨트',
//     grade: 'Ⅲ',
//     option: '스증 +3%, 스탯 +50, 공격력 +15, 크리 +3%',
//     desc: '영원+13증폭',
//   ),
//   EquipmentItem(
//     category: '목걸이',
//     imagePath: '',
//     name: '흑아 : 대 여우의 영혼 목걸이',
//     grade: '',
//     option: '모속강 +35, 스증 +1%',
//     desc: '테아+13증폭',
//   ),
//   EquipmentItem(
//     category: '팔찌',
//     imagePath: '',
//     name: '대 여우의 지혜 팔찌',
//     grade: '',
//     option: '모속강 +35, 스증 +2%',
//     desc: '테아+13증폭',
//   ),
//   EquipmentItem(
//     category: '반지',
//     imagePath: '',
//     name: '흑아 : 대 여우의 매혹 반지',
//     grade: '',
//     option: '모속강 +35, 스증 +2%',
//     desc: '테아+13증폭',
//   ),
//   EquipmentItem(
//     category: '보조장비',
//     imagePath: '',
//     name: '고위 여우의 숨결 부적 보조장비',
//     grade: 'Ⅲ',
//     option: '모속강 +12, 공격력 증폭 +3%, 크리 +3.0%',
//     desc: '영원+14증폭',
//   ),
//   EquipmentItem(
//     category: '마법석',
//     imagePath: '',
//     name: '우아한 기품의 향수',
//     grade: '',
//     option: '모속강 +40',
//     desc: '영원+14증폭',
//   ),
//   EquipmentItem(
//     category: '귀걸이',
//     imagePath: '',
//     name: '영롱한 날씨의 큐브',
//     grade: '',
//     option: '모속강 +25, 스탯 +100',
//     desc: '영원+14증폭',
//   ),
// ];

// final CharacterStats dummyCharacterStats = CharacterStats(
//   physicalDefenseRate: 47.3,
//   magicDefenseRate: 48.7,
//   str: 8144,
//   intStat: 4524,
//   vit: 4481,
//   spi: 4341,
//   physicalAttack: 5887,
//   magicAttack: 5276,
//   physicalCrit: 82.5,    // “(122.5%)” 부분은 별도 필드 없으므로 기본값만 사용
//   magicCrit: 72.5,
//   independentAttack: 3381,
//   adventureFame: 82370,
//   attackSpeed: 94.5,
//   castSpeed: 89.5,
//   fireElement: 301,
//   waterElement: 301,
//   lightElement: 311,
//   darkElement: 301,
// );


// // 3. 세부 스탯 및 추가 스탯
// final CharacterDetailStats dummyDetailStats = CharacterDetailStats(
//   attackIncreaseFlat: 71104.5,
//   attackIncreasePercent: 58.0,
//   buffPower: 272601,
//   buffPowerPercent: 13.0,
//   finalDamagePercent: 4002143.0,
//   elementStackPercent: 203.0,
//   cooldownReductionPercent: 43.2,
//   cooldownRecoveryPercent: 0.0,
//   totalCooldownReductionPercent: 43.2,
// );


// // 4. 아바타/크리쳐 리스트
// final List<AvatarItem> dummyAvatarItems = [
//   AvatarItem(
//     category: '모자 아바타',
//     images: [''],
//     name: '바니바니 아라드 타투 [D타입]',
//     option: '캐스팅 속도 14.0% 증가',
//     desc: '찬란한 붉은빛 엠블렘[힘]',
//   ),
//   AvatarItem(
//     category: '머리 아바타',
//     images: [''],
//     name: '바니바니 아라드 리프펌 헤어 [D타입]',
//     option: '캐스팅 속도 14.0% 증가',
//     desc: '찬란한 붉은빛 엠블렘[힘]',
//   ),
//   AvatarItem(
//     category: '얼굴 아바타',
//     images: [''],
//     name: '눈동자 [D타입]',
//     option: '공격 속도 6.0% 증가',
//     desc: '찬란한 노란빛 엠블렘[공격속도]',
//   ),
//   AvatarItem(
//     category: '상의 아바타',
//     images: [''],
//     name: '플레이아데스 상의 검기상인',
//     option: '스킬Lv +1',
//     desc: '플래티넘 엠블렘[검기상인]',
//   ),
//   AvatarItem(
//     category: '하의 아바타',
//     images: [''],
//     name: '만월무사의 하의 [C타입]',
//     option: 'HP MAX 400 증가',
//     desc: '플래티넘 엠블렘[검기상인]',
//   ),
//   AvatarItem(
//     category: '신발 아바타',
//     images: [''],
//     name: '만월무사의 신발 [C타입]',
//     option: '힘 55 증가',
//     desc: '찬란한 푸른빛 엠블렘[이동속도]',
//   ),
//   AvatarItem(
//     category: '목가슴 아바타',
//     images: [''],
//     name: '다크로드의 털 장식 [C타입]',
//     option: '공격 속도 6.0% 증가',
//     desc: '찬란한 노란빛 엠블렘[공격속도]',
//   ),
//   AvatarItem(
//     category: '허리 아바타',
//     images: [''],
//     name: '악귀나찰의 검과 가면 [D타입]',
//     option: '회피율 5.5% 증가',
//     desc: '찬란한 푸른빛 엠블렘[이동속도]',
//   ),
//   AvatarItem(
//     category: '스킨 아바타',
//     images: [''],
//     name: '진 웨펀마스터의 진줏빛 피부 [실버]',
//     option: '물리 방어력 1000 증가',
//     desc: '찬란한 붉은빛 엠블렘[힘]',
//   ),
//   AvatarItem(
//     category: '오라 아바타',
//     images: [''],
//     name: '루미너스 게이트',
//     option: '',
//     desc: '찬란한 붉은빛 엠블렘[힘]',
//   ),
//   AvatarItem(
//     category: '무기 아바타',
//     images: [''],
//     name: '신검 경힘 55 증가',
//     option: '힘 55 증가',
//     desc: '찬란한 붉은빛 엠블렘[힘]',
//   ),
//   AvatarItem(
//     category: '오라 스킨 아바타',
//     images: [''],
//     name: '[M]어워즈 패셔니스타',
//     option: '',
//     desc: '',
//   ),
//   AvatarItem(
//     category: '크리쳐',
//     images: [''],
//     name: '순백의 옵타티오 / 눈부신 황혼의 공명 / 눈부신 영원의 달빛 / 빛을 머금은 이슬',
//     option: '',
//     desc: '',
//   ),
// ];

// // 5. 버프 강화 아이템 리스트
// final List<BuffItem> dummyBuffItems = [
//   BuffItem(
//     category: '상의 아바타',
//     imagePath: '',
//     name: '레어 상의 클론 아바타 오버드라이브',
//     grade: '레어',
//     option: '스킬Lv +1',
//   ),
//   BuffItem(
//     category: '하의 아바타',
//     imagePath: '',
//     name: '레어 하의 클론 아바타 HP MAX 400 증가',
//     grade: '레어',
//     option: 'HP MAX 400 증가',
//   ),
//   BuffItem(
//     category: '크리쳐',
//     imagePath: '',
//     name: 'SD 검신 [단련된]',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '무기',
//     imagePath: '',
//     name: '짙은 심연의 편린 빔소드 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '칭호',
//     imagePath: '',
//     name: '모험가의 의지 [빛] 오버드라이브 +2',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '상의',
//     imagePath: '',
//     name: '짙은 심연의 편린 상의 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '머리어깨',
//     imagePath: '',
//     name: '짙은 심연의 편린 어깨 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '하의',
//     imagePath: '',
//     name: '짙은 심연의 편린 하의 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '신발',
//     imagePath: '',
//     name: '짙은 심연의 편린 신발 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '벨트',
//     imagePath: '',
//     name: '짙은 심연의 편린 벨트 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '목걸이',
//     imagePath: '',
//     name: '짙은 심연의 편린 목걸이 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '팔찌',
//     imagePath: '',
//     name: '짙은 심연의 편린 팔찌 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '반지',
//     imagePath: '',
//     name: '짙은 심연의 편린 반지 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '보조장비',
//     imagePath: '',
//     name: '짙은 뒤틀린 심연의 완장 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '마법석',
//     imagePath: '',
//     name: '짙은 뒤틀린 심연의 마법석 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
//   BuffItem(
//     category: '귀걸이',
//     imagePath: '',
//     name: '짙은 뒤틀린 심연의 귀걸이 : 오버드라이브 +0강화',
//     grade: '',
//     option: '',
//   ),
// ];
// final List<RankingRow> dummyRankingRows = [
//   RankingRow(
//     rank: 1,
//     characterId: 'char_laDogker',
//     name: '라독커',
//     fame: 82370,
//     job: '진 웨펀마스터',
//   ),
// ];