import 'dart:math';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart'; // 名前の名字と名前の一覧
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/RironTime_Nyuugakuji.dart';
import 'package:ekiden/kansuu/joukai.dart'; // 13分台の新入生の入学時5000m

// ------------------------------------------------------------
// 新入生の土台(2.0.4)
// ・新入生を作るときに引く値のうち、高校の大会の計算に使うものを、まとめて引く
//   (名前・出身地と趣味・素質の引き方・入学時5000m・スパート力・ペース変動対応力・登り適性・下り適性・
//   アップダウン対応力・ロード適性・長距離粘り)
// ・4月5日の新入生の作り方(SenshuShokiti.dart)と、7月下旬に来年の新入生を先に決めるとき(koukou.dart の
//   高校の大会)の両方で、この同じ引き方を使う(どちらで引いても、新入生の分布は2.0.3までと変わらない)
// ・成長タイプ・隠れた逸材・安定感・素質が1600を超える選手の追加処理など、ほかの値は今まで通り4月5日に引く
//   (設定を変えたら、4月の新入生に効くように)
// ・引き方は、2.0.3までの SenshuShokiti.dart の計算をそのまま移したもの
// ------------------------------------------------------------

/// 素質の引き方: ふつうの選手(素質1601〜1680)
const int dodaiKujiFutsuu = 0;

/// 素質の引き方: 13分台の新入生(素質1550〜1600。入学時5000mは13分35秒〜13分59秒)
const int dodaiKujiJuusan = 1;

/// 素質の引き方: 特別な選手(hirou=2。素質1500〜1550。特別指数0〜50)
const int dodaiKujiTokubetu = 2;

/// 新入生1人分の土台
class ShinnyuuseiDodai {
  /// 名前(名前の一覧の外を引いたとき(普通は起きない)はnull。そのときは選手の今の名前のまま)
  final String? name;

  /// SenshuData.samusataisei に入れる値(出身地と趣味。7月下旬に決めた土台は、高校の情報も入れる)
  final int samusataisei;

  /// 素質の引き方(dodaiKujiFutsuu・dodaiKujiJuusan・dodaiKujiTokubetu)
  final int kuji;

  /// 引いた素質(ふつう・13分台は1550〜1680。特別な選手は特別指数0〜50)
  final int sositu;

  /// 入学時5000m(秒)
  final double t5;
  final int spurt;
  final int pace;
  final int nobori;
  final int kudari;
  final int updown;
  final int road;
  final int nebari;

  const ShinnyuuseiDodai({
    required this.name,
    required this.samusataisei,
    required this.kuji,
    required this.sositu,
    required this.t5,
    required this.spurt,
    required this.pace,
    required this.nobori,
    required this.kudari,
    required this.updown,
    required this.road,
    required this.nebari,
  });

  /// samusataisei だけを変えたもの(高校の情報を入れるとき)
  ShinnyuuseiDodai samusataiseiKae(int v) => ShinnyuuseiDodai(
        name: name,
        samusataisei: v,
        kuji: kuji,
        sositu: sositu,
        t5: t5,
        spurt: spurt,
        pace: pace,
        nobori: nobori,
        kudari: kudari,
        updown: updown,
        road: road,
        nebari: nebari,
      );

  /// 保存の形(JSONの一覧。並びを変えない)
  List<dynamic> toJson() => [
        name ?? '',
        samusataisei,
        kuji,
        sositu,
        t5,
        spurt,
        pace,
        nobori,
        kudari,
        updown,
        road,
        nebari,
      ];

  /// 保存の形から読む(形が違えばnull)
  static ShinnyuuseiDodai? fromJson(dynamic a) {
    if (a is! List || a.length < 12) return null;
    for (int i = 1; i < 12; i++) {
      if (a[i] is! num) return null;
    }
    int n(int i) => (a[i] as num).toInt();
    final String mei = a[0] is String ? a[0] as String : '';
    return ShinnyuuseiDodai(
      name: mei.isEmpty ? null : mei,
      samusataisei: n(1),
      kuji: n(2),
      sositu: n(3),
      t5: (a[4] as num).toDouble(),
      spurt: n(5),
      pace: n(6),
      nobori: n(7),
      kudari: n(8),
      updown: n(9),
      road: n(10),
      nebari: n(11),
    );
  }
}

/// 新入生の名前を引く(在籍中の選手[zaisekiNames]と名字・名前の両方が同じになったら選び直す(最大50回)。
/// 名字が3文字以上の場合は、3文字以上の下の名前にならないよう選び直す(長くなりすぎないように))。
/// 引いた名前は[zaisekiNames]に足す(同じ回に作る他の選手とも重ならないように)。
/// 名前の一覧の外を引いたとき(普通は起きない)はnull
String? shinnyuuseiNameHiku(Random random, Ghensuu ghensuu, Set<String> zaisekiNames) {
  int r_mae = 0;
  int r_ato = 0;
  for (int tries = 0; tries < 50; tries++) {
    r_mae = random.nextInt(TEISUU.SUU_NAMEMAE);
    r_ato = random.nextInt(TEISUU.SUU_NAMEATO);
    if (r_mae < ghensuu.name_mae.length && ghensuu.name_mae[r_mae].runes.length >= 3) {
      for (int i = 0; i < 20 && r_ato < ghensuu.name_ato.length && ghensuu.name_ato[r_ato].runes.length >= 3; i++) {
        r_ato = random.nextInt(TEISUU.SUU_NAMEATO);
      }
    }
    if (r_mae >= ghensuu.name_mae.length || r_ato >= ghensuu.name_ato.length) {
      break; // 範囲外は下のエラー処理に任せる
    }
    if (!zaisekiNames.contains('${ghensuu.name_mae[r_mae]} ${ghensuu.name_ato[r_ato]}')) {
      break;
    }
  }
  if (r_mae < ghensuu.name_mae.length && r_ato < ghensuu.name_ato.length) {
    final String name = '${ghensuu.name_mae[r_mae]} ${ghensuu.name_ato[r_ato]}';
    zaisekiNames.add(name);
    return name;
  }
  return null;
}

/// 素質の引き方[kuji]と素質[sositu]から、選手の a・b・素質・素質ボーナス(と、特別な選手なら hirou=2)を決める
/// (2.0.3までの SenshuShokiti.dart の計算のまま)。呼ぶ前に magicnumber を TEISUU.MAGICNUMBER にしておく。
/// 戻り値は a の整数と、その最小値(素質が1600を超える選手の追加処理に使う)
({int aInt, int aMinInt}) shinnyuuseiSosituSettei(SenshuData senshu, int kuji, int sositu) {
  // a_min_intの計算 (temprand=1550の場合のa_min_int)
  final int aMinInt = (1550.0 * 1550.0 * 0.0333 - 1550.0 * 114.25 + senshu.magicnumber).toInt();
  int aInt;
  int tempRand;
  if (kuji == dodaiKujiTokubetu) {
    senshu.hirou = 2;
    // 13分20・30台大学入学の条件
    senshu.sositu_bonus = TEISUU.SOSITU_BONUS; //-100
    tempRand = sositu + 1500; // 1500から1550まで
    final double tani = 1000.0 / (1680.0 - 1550.0);
    aInt = aMinInt + ((tempRand - 1550) * tani).toInt();
  } else if (kuji == dodaiKujiJuusan) {
    // 13分台大学入学の条件分岐
    senshu.sositu_bonus = TEISUU.SOSITU_BONUS; //-100
    tempRand = sositu; // 1550から1600まで
    final double tani = 1000.0 / (1680.0 - 1550.0);
    aInt = aMinInt + ((tempRand - 1550) * tani).toInt();
  } else {
    senshu.sositu_bonus = 0;
    tempRand = sositu; // 1601から1680まで
    final double tani1 = 1000.0 / (1680.0 - 1550.0); // 最初の区間の単位
    final double tani2 = 3000.0 / (1680.0 - 1600.0); // 次の区間の単位
    aInt = aMinInt + ((1600.0 - 1550.0) * tani1).toInt() + ((tempRand - 1600.0) * tani2).toInt();
  }
  senshu.a = aInt * 0.000000001;
  senshu.b = 1645.0 * 0.0001; // 固定値
  senshu.sositu = tempRand;
  return (aInt: aInt, aMinInt: aMinInt);
}

/// 素質からスパート力(1〜99)
int _spurtFromSositu(int sositu) {
  const int bunbo = 1680 - 1550; // 分母
  final int bunsi = 1680 - sositu; // 分子
  final double ritu = bunsi.toDouble() / bunbo.toDouble(); // 比率を計算
  int kotae = (100 * ritu).toInt(); // 整数に変換して100を掛ける
  if (kotae < 1) kotae = 1; // 最小値を1に制限
  if (kotae > 99) kotae = 99; // 最大値を99に制限
  return kotae;
}

/// 新入生1人分の土台を引く(引き方は2.0.3までの SenshuShokiti.dart と同じ。[zaisekiNames]は名前を引くのに使う)
ShinnyuuseiDodai shinnyuuseiDodaiHiku(Random random, Ghensuu ghensuu, Set<String> zaisekiNames) {
  final String? name = shinnyuuseiNameHiku(random, ghensuu, zaisekiNames);
  // 素質の引き方(特別な選手は1500分の10、13分台は TEISUU.KAKURITU13PUNDAINYUUGAKU %、ほかはふつう)
  int kuji;
  int sositu;
  if (random.nextInt(1500) < 10) {
    kuji = dodaiKujiTokubetu;
    sositu = random.nextInt(51); // 特別指数
  } else if (random.nextInt(100) < TEISUU.KAKURITU13PUNDAINYUUGAKU) {
    kuji = dodaiKujiJuusan;
    sositu = random.nextInt(51) + 1550; // 1550から1600までの乱数
  } else {
    kuji = dodaiKujiFutsuu;
    sositu = random.nextInt(80) + 1601; // 1601から1680までの乱数
  }
  // 入学時5000m(仮の選手で a・b を作って、新入生と同じ計算をする)
  final SenshuData kari = SenshuData(id: -1, univid: -1, gakunen: 0);
  kari.magicnumber = TEISUU.MAGICNUMBER;
  shinnyuuseiSosituSettei(kari, kuji, sositu);
  final bool tokubetu = kuji == dodaiKujiTokubetu;
  double t5 = RironTime_Nyuugakuji(tokubetu, tokubetu ? sositu : 0, 5000.0, kari);
  // 13分台の新入生の入学時5000mは、13分35秒〜13分59秒に広げる(遅いほど多い。1.8.5)
  if (kuji == dodaiKujiJuusan) t5 = nyuugakuji5000Juusanpundai(kari.sositu, random);
  final int nebari = random.nextInt(99) + 1; // 長距離粘り
  // スパート力(素質から)とペース変動対応力(スパート力の近く)
  final int spurt = _spurtFromSositu(kari.sositu);
  int pace = spurt - 10 + (random.nextInt(21) - 10);
  if (pace > 89) pace = 89;
  if (pace < 1) pace = 1;
  final int nobori = random.nextInt(99) + 1;
  final int kudari = random.nextInt(99) + 1;
  final int updown = random.nextInt(99) + 1;
  final int road = random.nextInt(99) + 1;
  // ペース変動対応力は、33%で引き直した値が高ければそちら
  if (random.nextInt(100) < 33) {
    final int temp = random.nextInt(99) + 1;
    if (temp > pace) pace = temp;
  }
  if (tokubetu) pace = 90 + sositu ~/ 5;
  // 出身地と趣味
  final int hobby = random.nextInt(HobbyDatabase.allHobbies.length);
  final int ken = random.nextInt(LocationDatabase.allPrefectures.length);
  return ShinnyuuseiDodai(
    name: name,
    samusataisei: PackedIndexHelper.packIndices(hobbyIndex: hobby, prefectureIndex: ken),
    kuji: kuji,
    sositu: sositu,
    t5: t5,
    spurt: spurt,
    pace: pace,
    nobori: nobori,
    kudari: kudari,
    updown: updown,
    road: road,
    nebari: nebari,
  );
}
