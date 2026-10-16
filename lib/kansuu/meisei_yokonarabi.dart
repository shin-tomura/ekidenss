import 'dart:math';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 名声の横並び(スカウトのとき)(2.0.2。2.0.3から、名声の順位のブロックを複数決められる)
//
// 名声1位の大学がスカウトで抜け出して独走しやすいので、設定で、名声の順位のブロック(例えば1〜3位・4〜8位)ごとに、
// 新入生のスカウトの計算では同じ名声として扱えるようにする(入学時名声影響度設定の画面の、別の項目)。
// ・2.0.2は「名声上位の横並び」で、名声の上位K校(2〜29校)の1ブロックだけだった。2.0.3からは、
//   隣り合う順位を同じブロックにするかを29か所(1位と2位、…、29位と30位)で決め、ブロックをいくつでも作れる
//   (2校以上のブロックは最大15個。1校だけのブロックは横並びなしと同じ)
// ・ブロックは名声の順位で決まる(名声の順が入れ替わると、ブロックに入る大学も入れ替わる)
// ・2.0.3から、名声の順位で区切るかわりに、大学を決めてグループ(1〜9)にまとめる形も選べる(どちらか一方だけが効く)。
//   グループは大学idで持つので、名声の順位が変わっても同じ顔ぶれのまま(大学の名前を変えても崩れない)。
//   1校だけのグループは効かない。あなたの大学も入れられる。順位で区切る形にしたときのブロックは、大学の形のあいだも残す
// ・そろえ方は2つ(全部のブロック・グループで共通。どちらもブロックの中は横並びになる):
//   ・平均(初期値): ブロックの平均にそろえる。ブロックの合計の取り分は変わらず、ほかの大学には影響しない
//   ・一番上: ブロックの一番上(名声が一番高い大学)の値にそろえる。ブロックの大学がみな一番上並みに強くなり、
//     その分、ほかの大学は選ばれにくくなる(2.0.2の「名声1位にそろえる」)
// ・30校(全校)を1つのブロックにはできない(平均にそろえると、抽選の重みはレベル0(完全ランダム)と同じになるため)
// ・効かせるところ(スカウトの計算だけ。名声の表示・目標順位・獲得名声などは変えない):
//   ・抽選の重み(ShozokusakiKettei_By_Univmeisei.dart の shozokuChuusenOmomi。コンピュータスカウトOFFの振り分け・
//     最後の志望・地区めぐり(声かけ)の争奪戦・地区めぐりの成功率の下限): 名声の順位ごとの倍率を掛けたあとの重みを
//     ブロックごとにそろえる(yokonarabiOmomi)
//   ・名声そのもの(scout_com.dart の交渉の成功率と、全国一斉・地区めぐり(交渉)の争奪戦。コンピュータスカウトOFFの
//     交渉の成功率(9000Freshmankakutoku.dart)): ブロックごとに名声をそろえる(scoutMeiseiMap)
//   ・強化プロジェクト・監督の母校パイプの「名声N位並み」は、そろえたあとの値で見る
// ・順位の並びは、名声の高い順(同じなら大学idの小さい順)。グループの「一番上」も、この並びで一番上の大学
// ・保存: KantokuData.yobiint3[86]
//   ・0: なし(初期値。新しいゲームでは0に戻る)
//   ・1000未満: 2.0.2の形(校数 + 100×そろえ方。校数は0=なし・2〜29)。1〜K位のブロック1つとして読む
//   ・1000以上: 2.0.3の形(1000 + そろえ方 + 10×形 + 100×つなぎ)。そろえ方は0=平均(初期値)・1=一番上、
//     形は0=名声の順位で区切る・1=大学を決めてまとめる、つなぎはビットi(0〜28)が1なら(i+1)位と(i+2)位が同じブロック
//     (最大で約5.4×10の10乗なので、15桁に収まる)
// ・保存(大学のグループ): KantokuData.yobiint3[87](大学0〜14)・[88](大学15〜29)。1大学1桁(大学id%15の位)で、
//   0=なし(初期値)・1〜9=グループ。新しいゲームでは0に戻る
// ・各種設定のQRコードに含める(大学のグループも。古いQRコードに含まれていなければ、今の設定のまま。2.0.2のアプリは、
//   2.0.3の形の値を正しくない値として読まず、今の設定のままにする)
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: 名声の横並び(上の説明の形)
const int yokonarabiIndex = 86;

/// 上位K校の形(2.0.2の形と、編集の画面の「上位の何校を1つのブロックにする」)の校数の下限と上限
const int yokonarabiSaishou = 2;
const int yokonarabiSaidai = 29;

/// そろえ方: 平均(初期値)・一番上(2.0.2の「名声1位」)
const int yokonarabiHeikin = 0;
const int yokonarabiIchii = 1;

/// 形: 名声の順位で区切る(初期値)・大学を決めてまとめる(2.0.3)
const int yokonarabiKataJuni = 0;
const int yokonarabiKataDaigaku = 1;

/// KantokuData.yobiint3 の使用番号: 大学のグループ([87]に大学0〜14・[88]に大学15〜29。1大学1桁)
const int yokonarabiGroupIndex = 87;

/// グループの数(1〜9。0はなし)
const int yokonarabiGroupSaidai = 9;

/// 1つの番号に入れる大学の数と、その値の上限(10の15乗。15桁)
const int _groupHitotsu = 15;
const int _groupJougen = 1000000000000000;

/// 順位の数(つなぎは、この数−1か所)
const int yokonarabiJuniSuu = 30;

/// つなぎの全部(30校が1つのブロック。これは選べない)
const int _tsunagiZenbu = (1 << (yokonarabiJuniSuu - 1)) - 1;

/// 2.0.2の形と2.0.3の形の境目
const int _atarashiiKata = 1000;

/// 保存してある値を読んだもの
typedef _Yomi = ({int tsunagi, int kata, int houhou});

const _Yomi _nashi = (tsunagi: 0, kata: yokonarabiKataJuni, houhou: yokonarabiHeikin);

/// 保存する値を読む(正しくなければnull)
_Yomi? _yomu(int v) {
  if (v < 0) return null;
  if (v < _atarashiiKata) {
    // 2.0.2の形(校数 + 100×そろえ方)
    final int suu = v % 100;
    final int h = v ~/ 100;
    if (!(suu == 0 || (suu >= yokonarabiSaishou && suu <= yokonarabiSaidai))) return null;
    if (h != yokonarabiHeikin && h != yokonarabiIchii) return null;
    return (tsunagi: yokonarabiJouiTsunagi(suu), kata: yokonarabiKataJuni, houhou: h);
  }
  // 2.0.3の形(1000 + そろえ方 + 10×形 + 100×つなぎ)
  final int w = v - _atarashiiKata;
  final int h = w % 10;
  final int kata = (w ~/ 10) % 10;
  final int tsunagi = w ~/ 100;
  if (h != yokonarabiHeikin && h != yokonarabiIchii) return null;
  if (kata != yokonarabiKataJuni && kata != yokonarabiKataDaigaku) return null;
  if (tsunagi >= _tsunagiZenbu) return null;
  return (tsunagi: tsunagi, kata: kata, houhou: h);
}

/// 保存する値を作る(全部が初期値なら0)
int _tsukuru(int tsunagi, int kata, int houhou) {
  if (tsunagi == 0 && kata == yokonarabiKataJuni && houhou == yokonarabiHeikin) return 0;
  return _atarashiiKata + houhou + 10 * kata + 100 * tsunagi;
}

/// 保存する値として正しいか(QRコードの読み込みで使う)
bool yokonarabiTadashii(int v) => _yomu(v) != null;

/// 保存してある値(正しくなければ0)
int yokonarabiAtai(KantokuData? k) {
  if (k == null || k.yobiint3.length <= yokonarabiIndex) return 0;
  final int v = k.yobiint3[yokonarabiIndex];
  return yokonarabiTadashii(v) ? v : 0;
}

/// 保存する値を入れる(正しくない値は0。保存(save)は呼び出し側で行う)
void yokonarabiAtaiIreru(KantokuData k, int v) {
  if (k.yobiint3.length <= yokonarabiIndex) return;
  k.yobiint3[yokonarabiIndex] = yokonarabiTadashii(v) ? v : 0;
}

/// 今の設定(監督のデータが読めなければなし)
_Yomi _yomuK(KantokuData? k) => _yomu(yokonarabiAtai(k)) ?? _nashi;

/// 名声の順位のつなぎ(0はなし)
int yokonarabiTsunagi(KantokuData? k) => _yomuK(k).tsunagi;

/// そろえ方(yokonarabiHeikin・yokonarabiIchii)
int yokonarabiHouhou(KantokuData? k) => _yomuK(k).houhou;

/// 形(yokonarabiKataJuni・yokonarabiKataDaigaku)
int yokonarabiKata(KantokuData? k) => _yomuK(k).kata;

/// 形を変える(つなぎ・そろえ方・大学のグループはそのまま。保存(save)は呼び出し側で行う)
void yokonarabiKataIreru(KantokuData k, int kata) {
  final int ka = kata == yokonarabiKataDaigaku ? yokonarabiKataDaigaku : yokonarabiKataJuni;
  final _Yomi y = _yomuK(k);
  yokonarabiAtaiIreru(k, _tsukuru(y.tsunagi, ka, y.houhou));
}

/// 大学のグループの保存する値として正しいか(QRコードの読み込みで使う)
bool yokonarabiGroupAtaiTadashii(int v) => v >= 0 && v < _groupJougen;

/// 大学のグループの保存してある値([i]は0なら大学0〜14、1なら大学15〜29。正しくなければ0)
int yokonarabiGroupAtai(KantokuData? k, int i) {
  final int ban = yokonarabiGroupIndex + i;
  if (k == null || i < 0 || i > 1 || k.yobiint3.length <= ban) return 0;
  final int v = k.yobiint3[ban];
  return yokonarabiGroupAtaiTadashii(v) ? v : 0;
}

/// 大学のグループの保存する値を入れる(正しくない値は0。保存(save)は呼び出し側で行う)
void yokonarabiGroupAtaiIreru(KantokuData k, int i, int v) {
  final int ban = yokonarabiGroupIndex + i;
  if (i < 0 || i > 1 || k.yobiint3.length <= ban) return;
  k.yobiint3[ban] = yokonarabiGroupAtaiTadashii(v) ? v : 0;
}

/// 大学id%15の位(1, 10, 100, …)
int _groupKurai(int univid) {
  int kurai = 1;
  for (int i = 0; i < univid % _groupHitotsu; i++) {
    kurai *= 10;
  }
  return kurai;
}

/// 大学[univid]のグループ(0はなし。1〜9)
int yokonarabiGroup(KantokuData? k, int univid) {
  if (univid < 0 || univid >= yokonarabiJuniSuu) return 0;
  return (yokonarabiGroupAtai(k, univid ~/ _groupHitotsu) ~/ _groupKurai(univid)) % 10;
}

/// 大学[univid]のグループを変える(0はなし。1〜9。保存(save)は呼び出し側で行う)
void yokonarabiGroupIreru(KantokuData k, int univid, int group) {
  if (univid < 0 || univid >= yokonarabiJuniSuu) return;
  final int g = (group >= 1 && group <= yokonarabiGroupSaidai) ? group : 0;
  final int i = univid ~/ _groupHitotsu;
  final int kurai = _groupKurai(univid);
  final int v = yokonarabiGroupAtai(k, i);
  final int ima = (v ~/ kurai) % 10;
  yokonarabiGroupAtaiIreru(k, i, v + (g - ima) * kurai);
}

/// 大学のグループを全部なしにする(保存(save)は呼び出し側で行う)
void yokonarabiGroupZenbuNashi(KantokuData k) {
  yokonarabiGroupAtaiIreru(k, 0, 0);
  yokonarabiGroupAtaiIreru(k, 1, 0);
}

/// 大学idごとのグループ(長さ30。0はなし)
List<int> yokonarabiGroupRetsu(KantokuData? k) => [
  for (int id = 0; id < yokonarabiJuniSuu; id++) yokonarabiGroup(k, id),
];

/// グループ(1〜9)ごとの大学(名声の高い順、同じなら大学idの小さい順)。大学のいないグループは出さない。
/// 1校だけのグループも出す(画面で「効きません」と添えるため)
List<({int group, List<UnivData> univs})> yokonarabiGroupIchiran(List<int> group, List<UnivData> univs) {
  final List<UnivData> jun = _meiseiJun(univs);
  return [
    for (int g = 1; g <= yokonarabiGroupSaidai; g++)
      if (jun.any((UnivData u) => u.id >= 0 && u.id < group.length && group[u.id] == g))
        (
          group: g,
          univs: [
            for (final UnivData u in jun)
              if (u.id >= 0 && u.id < group.length && group[u.id] == g) u,
          ],
        ),
  ];
}

/// つなぎを変える(そろえ方はそのまま。正しくないつなぎなら変えない。保存(save)は呼び出し側で行う)
void yokonarabiTsunagiIreru(KantokuData k, int tsunagi) {
  if (tsunagi < 0 || tsunagi >= _tsunagiZenbu) return;
  final _Yomi y = _yomuK(k);
  yokonarabiAtaiIreru(k, _tsukuru(tsunagi, y.kata, y.houhou));
}

/// そろえ方を変える(つなぎはそのまま。保存(save)は呼び出し側で行う)
void yokonarabiHouhouIreru(KantokuData k, int houhou) {
  final int h = houhou == yokonarabiIchii ? yokonarabiIchii : yokonarabiHeikin;
  final _Yomi y = _yomuK(k);
  yokonarabiAtaiIreru(k, _tsukuru(y.tsunagi, y.kata, h));
}

/// [juni]位と[juni]+1位が同じブロックか(juniは1〜29)
bool yokonarabiTsunagaru(int tsunagi, int juni) =>
    juni >= 1 && juni < yokonarabiJuniSuu && ((tsunagi >> (juni - 1)) & 1) == 1;

/// [juni]位と[juni]+1位を同じブロックにする(しない)ように変えたつなぎ(juniは1〜29)
int yokonarabiTsunagiKae(int tsunagi, int juni, bool tsunagu) {
  if (juni < 1 || juni >= yokonarabiJuniSuu) return tsunagi;
  final int bit = 1 << (juni - 1);
  return tsunagu ? (tsunagi | bit) : (tsunagi & ~bit);
}

/// 30校が1つのブロックになるつなぎか(これは選べない)
bool yokonarabiTsunagiZenbu(int tsunagi) => tsunagi == _tsunagiZenbu;

/// 上位[suu]校を1つのブロックにするつなぎ(2〜29校。それ以外は0=なし)
int yokonarabiJouiTsunagi(int suu) =>
    (suu >= yokonarabiSaishou && suu <= yokonarabiSaidai) ? (1 << (suu - 1)) - 1 : 0;

/// 上から[n]校ずつのブロックにするつなぎ(最後に1校だけ残ったら、その大学はブロックにしない)
int yokonarabiZutsuTsunagi(int n) {
  if (n < 2 || n >= yokonarabiJuniSuu) return 0;
  int t = 0;
  for (int juni = 1; juni < yokonarabiJuniSuu; juni++) {
    if (juni % n != 0) t |= 1 << (juni - 1);
  }
  return t;
}

/// つなぎから、2校以上のブロック(何位から何位まで)の一覧(上から)
List<({int kara, int made})> yokonarabiBlock(int tsunagi) {
  final List<({int kara, int made})> l = [];
  int kara = 1;
  for (int juni = 1; juni <= yokonarabiJuniSuu; juni++) {
    if (juni == yokonarabiJuniSuu || !yokonarabiTsunagaru(tsunagi, juni)) {
      if (juni > kara) l.add((kara: kara, made: juni));
      kara = juni + 1;
    }
  }
  return l;
}

/// ブロックの文(「1〜3位・4〜8位」。なければ「なし」)
String yokonarabiBlockMoji(int tsunagi) {
  final List<({int kara, int made})> l = yokonarabiBlock(tsunagi);
  if (l.isEmpty) return 'なし';
  return l.map((b) => '${b.kara}〜${b.made}位').join('・');
}

/// 画面に出す名前(上位K校の形の校数。編集の画面の選択肢)
String yokonarabiMei(int suu) {
  if (suu == 2) return '上位2校(一騎打ち)';
  if (suu == 3) return '上位3校(三つ巴)';
  if (suu >= 4) return '上位$suu校';
  return 'なし';
}

/// 画面に出す名前(そろえ方)
String yokonarabiHouhouMei(int houhou) =>
    houhou == yokonarabiIchii ? '一番上にそろえる' : '平均にそろえる';

/// スカウトの計算で使う、名声の横並びの設定(名声の順位のつなぎか大学のグループと、一番上にそろえるか)
class YokonarabiSettei {
  /// 名声の順位のつなぎ(0はなし。大学の形のときは使わない)
  final int tsunagi;

  /// trueならブロック(グループ)の一番上の値にそろえる(falseなら平均)
  final bool ichii;

  /// 大学を決めてまとめる形のときの、大学idごとのグループ(0はなし・1〜9。順位の形ならnull。2.0.3)
  final List<int>? group;

  const YokonarabiSettei(this.tsunagi, this.ichii, {this.group});

  /// 横並びなし
  static const YokonarabiSettei nashi = YokonarabiSettei(0, false);

  /// 監督のデータから読む(読めなければなし)
  static YokonarabiSettei yomu(KantokuData? k) {
    final bool ichii = yokonarabiHouhou(k) == yokonarabiIchii;
    if (yokonarabiKata(k) == yokonarabiKataDaigaku) {
      return YokonarabiSettei(0, ichii, group: yokonarabiGroupRetsu(k));
    }
    return YokonarabiSettei(yokonarabiTsunagi(k), ichii);
  }

  /// 効くか(大学の形なら、2校以上のグループがあるか)
  bool get kiku {
    final List<int>? g = group;
    if (g == null) return tsunagi != 0;
    final Map<int, int> kazu = {};
    for (final int x in g) {
      if (x > 0) kazu[x] = (kazu[x] ?? 0) + 1;
    }
    return kazu.values.any((int n) => n >= 2);
  }
}

/// 名声の高い順(同じなら大学idの小さい順)
List<UnivData> _meiseiJun(List<UnivData> univs) => List<UnivData>.of(univs)
  ..sort((a, b) {
    final int c = b.meisei_total.compareTo(a.meisei_total);
    return c != 0 ? c : a.id.compareTo(b.id);
  });

/// そろえるまとまり(大学idの一覧のリスト。どれも名声の高い順(同じなら大学idの小さい順)で2校以上。重ならない)
List<List<int>> _matomari(List<UnivData> univs, YokonarabiSettei s) {
  final List<UnivData> jun = _meiseiJun(univs);
  final List<int>? group = s.group;
  if (group != null) {
    // 大学を決めてまとめる形(2.0.3): グループごと
    return [
      for (int g = 1; g <= yokonarabiGroupSaidai; g++)
        [
          for (final UnivData u in jun)
            if (u.id >= 0 && u.id < group.length && group[u.id] == g) u.id,
        ],
    ].where((List<int> l) => l.length >= 2).toList();
  }
  final List<List<int>> l = [];
  for (final ({int kara, int made}) b in yokonarabiBlock(s.tsunagi)) {
    final int made = min(b.made, jun.length);
    if (made - b.kara + 1 < 2) continue;
    l.add([for (int i = b.kara - 1; i < made; i++) jun[i].id]);
  }
  return l;
}

/// [ids] の値([atai] の位置)をそろえる値(平均か、最初(一番上)の値)
int _soroeru(List<int> ids, int Function(int id) atai, bool ichii) {
  if (ichii) return atai(ids.first);
  int goukei = 0;
  for (final int id in ids) {
    goukei += atai(id);
  }
  return (goukei / ids.length).round();
}

/// スカウトで使う名声(大学id → 名声)。横並びの設定なら、ブロックごとに、平均か一番上の名声にそろえる
/// (効かない設定なら、どの大学ももとの名声)
Map<int, int> scoutMeiseiMap(List<UnivData> univs, YokonarabiSettei s) {
  final Map<int, int> m = {for (final UnivData u in univs) u.id: u.meisei_total};
  if (!s.kiku || univs.length < 2) return m;
  // ブロックは重ならないので、順にそろえてよい
  for (final List<int> ids in _matomari(univs, s)) {
    final int atai = _soroeru(ids, (int id) => m[id] ?? 0, s.ichii);
    for (final int id in ids) {
      m[id] = atai;
    }
  }
  return m;
}

/// 抽選の重み([omomi] は大学idの位置。shozokuChuusenOmomi)を、ブロックごとに、
/// 平均か一番上の重みにそろえる(効かない設定なら何もしない)
void yokonarabiOmomi(List<int> omomi, List<UnivData> univs, YokonarabiSettei s) {
  if (!s.kiku || univs.length < 2) return;
  for (final List<int> matomari in _matomari(univs, s)) {
    final List<int> ids = [
      for (final int id in matomari)
        if (id >= 0 && id < omomi.length) id,
    ];
    if (ids.length < 2) continue;
    final int atai = _soroeru(ids, (int id) => omomi[id], s.ichii);
    for (final int id in ids) {
      omomi[id] = atai;
    }
  }
}
