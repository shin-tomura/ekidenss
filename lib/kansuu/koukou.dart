import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/koukou_meibo.dart';

// ------------------------------------------------------------
// 出身校と高校時代の実績(1.9.5)
//
// 日本人の選手に、出身校(架空。koukou_meibo.dart)と、高校時代の経歴・実績を付ける。
// ゲーム本体の計算(大学のレース・育成)には一切使わない。表示と記事のためだけのもの
//
// 実績は、入学する年の新入生全員(高校3年生)と、名前のない高校生(同じ高校の1・2年生や、
// 大学に来ない3年生、その他の高校の選手。保存しない)で、全国高校駅伝と高校総体を実際に計算して決める
// ・力の土台は入学時の5000mの記録(持ちタイム)。基本走力は使わない(隠れた逸材は入学時の基本走力が
//   持ちタイムより速いので、基本走力で計算すると高校の結果で分かってしまう。サプライズなので使わない)
// ・登り・下り・アップダウン・ロード・ペース変動・スパートの補正には、入学時の能力値(見抜く力に
//   関係なく全部)を使う。あとで能力が見えるようになったときに、高校の結果と答え合わせができるように
// ・全国高校駅伝: 7区間42.195km(1区10km・2区3km・3区8.1075km・4区8.0875km・5区3km・6区5km・7区5km)。
//   都道府県予選(名簿の5校と名前のない高校)の1位47校と、11地区の代表(各地区の予選2位の高校のうち、
//   予選のタイムが一番良い高校)の58校が走る。区間の起伏は実在の男子のコースの特徴に合わせた
//   (1区は前半上り・後半下り、3区は登りが多くアップダウン、4区は下りが多い、5区は前半上り・後半下り)。
//   区間は高校の監督が決める(エースを1区、2番手を3区、3番手を4区…。中距離出身は3kmの区間へ)。
//   留学生は2区か5区だけ(2024年からの実在の決まり)
// ・高校総体: 1500m・5000m・3000m障害。県大会の上位6人が地区大会、地区大会の上位6人が全国大会。
//   全国大会は予選3組(各組4着とタイムで3人)のあと、15人の決勝。選手は1人1種目
// ・タイムの目安(数年分を試した平均): 全国高校駅伝の優勝は2時間2〜4分、1区の区間賞は29分台前半、
//   高校総体5000mの日本人トップは13分50秒前後(優勝は留学生が多い)。
//   新入生150人のうち、全国高校駅伝を走るのは毎年60人前後、区間賞は2〜3人、高校総体の決勝は18人前後
// ・新入生をどの高校に入れるか: 出身地の県の5校から、速い選手ほど名門に入りやすく選ぶ。
//   速い選手は県外の名門に入ることもある(13分台は35%、14分20秒より速いと20%、ほかは5%)
// ・経歴: 長距離ひと筋・中距離出身・ほかの競技の出身(遅めの選手ほど多い)。隠れた逸材かどうかとは無関係
//
// 保存(SenshuData.samusataisei の、出身地と趣味(下の17ビット)より上。数で詰めるので2の49乗未満)
//   samusataisei = 下の17ビット + 131072 × 上の値
//   上の値 = 高校(番号+1、0は未設定。256通り) + 256 × (経歴(4通り) + 4 × (全国か(2通り) + 2 × (区間(8通り。
//   0は出走なし) + 8 × (区間順位(32通り。1〜31、31は31位以下、0はなし) + 32 × (チーム順位(32通り) +
//   32 × (総体の種目(4通り。0なし・1=1500m・2=5000m・3=3000m障害) + 4 × (段階(4通り。0県・1地区・
//   2全国予選・3全国決勝) + 4 × 順位(16通り。1〜15、0は16位以下)))))))
//   (Webでも正しく動くように、ビット演算ではなく掛け算と割り算で詰める)
// ・高校が未設定(0)の日本人選手には、起動時・セーブデータの読み込み時・年度替わり・新しいゲームの開始時に、
//   学年ごとにまとめて付ける(koukouJouhouFuyo)。版の番号では判定しない(1.9.5testで開いたデータにも付くように)
// ・表示しない設定: KantokuData.yobiint2[86](0=表示(初期値)・1=表示しない。趣味・高校時代の表示設定の画面)
// ------------------------------------------------------------

const int _shitaBit = 131072; // 2の17乗(出身地と趣味の分)

/// 高校の情報を表示しないか(KantokuData.yobiint2[86]=1)
bool koukouHyoujiNashi(KantokuData kantoku) =>
    kantoku.yobiint2.length > 86 && kantoku.yobiint2[86] == 1;

/// 1人分の高校の情報(samusataisei の上の値)
class KoukouJouhou {
  /// 高校の番号+1(0は未設定)
  final int koukou;

  /// 経歴(0長距離ひと筋 1中距離出身 2ほかの競技の出身)
  final int keireki;

  /// 全国高校駅伝を走ったか(falseなら都道府県予選の結果)
  final bool ekidenZenkoku;

  /// 走った区間(1〜7。0は出走なし(補欠や、ほかの競技))
  final int ekidenKukan;

  /// 区間順位(1〜31。31は31位以下。0はなし)
  final int ekidenKukanJuni;

  /// チームの順位(1〜31。31は31位以下。0はなし)
  final int ekidenJuni;

  /// 高校総体の種目(0なし・1=1500m・2=5000m・3=3000m障害)
  final int soutaiShumoku;

  /// 高校総体の一番上の段階(0県大会・1地区大会・2全国予選・3全国決勝)
  final int soutaiDankai;

  /// その段階の順位(1〜15。0は16位以下か、全国予選)
  final int soutaiJuni;

  /// 下の17ビット(出身地と趣味。ほかの競技の名前を決めるのに使う)
  final int shita;

  const KoukouJouhou({
    required this.koukou,
    this.keireki = 0,
    this.ekidenZenkoku = false,
    this.ekidenKukan = 0,
    this.ekidenKukanJuni = 0,
    this.ekidenJuni = 0,
    this.soutaiShumoku = 0,
    this.soutaiDankai = 0,
    this.soutaiJuni = 0,
    this.shita = 0,
  });

  /// samusataisei から読む
  static KoukouJouhou yomu(int samusataisei) {
    final int v = samusataisei < 0 ? 0 : samusataisei;
    int ue = v ~/ _shitaBit;
    final int shita = v % _shitaBit;
    final int koukou = ue % 256;
    ue ~/= 256;
    final int keireki = ue % 4;
    ue ~/= 4;
    final bool zenkoku = ue % 2 == 1;
    ue ~/= 2;
    final int kukan = ue % 8;
    ue ~/= 8;
    final int kukanJuni = ue % 32;
    ue ~/= 32;
    final int juni = ue % 32;
    ue ~/= 32;
    final int shumoku = ue % 4;
    ue ~/= 4;
    final int dankai = ue % 4;
    ue ~/= 4;
    final int sJuni = ue % 16;
    return KoukouJouhou(
      koukou: koukou,
      keireki: keireki,
      ekidenZenkoku: zenkoku,
      ekidenKukan: kukan,
      ekidenKukanJuni: kukanJuni,
      ekidenJuni: juni,
      soutaiShumoku: shumoku,
      soutaiDankai: dankai,
      soutaiJuni: sJuni,
      shita: shita,
    );
  }

  /// samusataisei の下の17ビット(出身地と趣味)はそのままにして、この情報を書き込んだ値
  int kakikomi(int samusataisei) {
    final int shitaNoAtai = (samusataisei < 0 ? 0 : samusataisei) % _shitaBit;
    int ue = soutaiJuni.clamp(0, 15).toInt();
    ue = ue * 4 + soutaiDankai.clamp(0, 3).toInt();
    ue = ue * 4 + soutaiShumoku.clamp(0, 3).toInt();
    ue = ue * 32 + ekidenJuni.clamp(0, 31).toInt();
    ue = ue * 32 + ekidenKukanJuni.clamp(0, 31).toInt();
    ue = ue * 8 + ekidenKukan.clamp(0, 7).toInt();
    ue = ue * 2 + (ekidenZenkoku ? 1 : 0);
    ue = ue * 4 + keireki.clamp(0, 3).toInt();
    ue = ue * 256 + koukou.clamp(0, 255).toInt();
    return shitaNoAtai + ue * _shitaBit;
  }

  /// 名簿の高校(未設定ならnull)
  KoukouMei? get mei =>
      (koukou >= 1 && koukou <= koukouMeibo.length) ? koukouMeibo[koukou - 1] : null;
}

// ------------------------------------------------------------
// 文(選手画面・記事)
// ------------------------------------------------------------

/// 高校総体の種目の名前(1〜3)
const List<String> koukouShumokuMei = ['', '1500m', '5000m', '3000m障害'];

/// ほかの競技の出身のときの、部活の名前
const List<String> _hokaKyougi = [
  'サッカー部',
  '野球部',
  'バスケットボール部',
  '水泳部',
  'ハンドボール部',
  'スキー部',
  'ラグビー部',
  'バドミントン部',
];

/// 都道府県の短い名前(「長野県」→「長野」。北海道はそのまま)
String _kenMijikai(int ken) {
  if (ken < 0 || ken >= LocationDatabase.allPrefectures.length) return '';
  final String n = LocationDatabase.allPrefectures[ken];
  if (n == '北海道') return n;
  return n.substring(0, n.length - 1);
}

/// 校名(「青嶺学院高」)
String koukouMeiMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  return m == null ? '' : '${m.mei}高';
}

/// 校名と都道府県(「青嶺学院高(長野)」)
String koukouMeiKenMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  return m == null ? '' : '${m.mei}高(${_kenMijikai(m.ken)})';
}

/// 経歴の文(長距離ひと筋なら空)
String koukouKeirekiMoji(KoukouJouhou j) {
  switch (j.keireki) {
    case 1:
      return '高校では中距離が専門';
    case 2:
      return '高校までは${_hokaKyougi[(j.koukou * 31 + j.shita) % _hokaKyougi.length]}';
    default:
      return '';
  }
}

/// 全国高校駅伝・都道府県予選の文(目立たない結果なら空)
String koukouEkidenMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  if (m == null) return '';
  final int kukan = j.ekidenKukan;
  final int kj = j.ekidenKukanJuni;
  final int tj = j.ekidenJuni;
  if (j.ekidenZenkoku) {
    final String team = tj == 1 ? '(優勝)' : ((tj >= 2 && tj <= 8) ? '(チーム$tj位)' : '');
    if (kukan == 0) {
      // 補欠は、8位までに入ったときだけ
      return (tj >= 1 && tj <= 8) ? '全国高校駅伝 ${tj == 1 ? '優勝' : '$tj位'}(補欠)' : '';
    }
    final String kjMoji = kj == 1 ? ' 区間賞' : ((kj >= 2 && kj <= 30) ? ' 区間$kj位' : '');
    return '全国高校駅伝 $kukan区$kjMoji$team';
  }
  // 都道府県予選は、区間5位以内か、チームが3位以内のときだけ
  if (kukan == 0) return '';
  if (!((kj >= 1 && kj <= 5) || (tj >= 1 && tj <= 3))) return '';
  final String ken = (m.ken >= 0 && m.ken < LocationDatabase.allPrefectures.length)
      ? LocationDatabase.allPrefectures[m.ken]
      : '';
  final String kjMoji = kj == 1 ? ' 区間賞' : ((kj >= 2 && kj <= 30) ? ' 区間$kj位' : '');
  final String team = tj == 1 ? '(優勝)' : ((tj >= 2 && tj <= 3) ? '(チーム$tj位)' : '');
  return '$ken高校駅伝 $kukan区$kjMoji$team';
}

/// 高校総体の文(目立たない結果なら空)
String koukouSoutaiMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  if (m == null) return '';
  final int sh = j.soutaiShumoku;
  if (sh < 1 || sh > 3) return '';
  final String sm = koukouShumokuMei[sh];
  final int r = j.soutaiJuni;
  switch (j.soutaiDankai) {
    case 3:
      if (r == 1) return '高校総体$sm 優勝';
      return r >= 2 ? '高校総体$sm $r位' : '高校総体$sm 決勝';
    case 2:
      return '高校総体$sm 出場';
    case 1:
      // 地区大会は10位まで
      if (r < 1 || r > 10) return '';
      final int c = (m.ken >= 0 && m.ken < koukouKenChiku.length) ? koukouKenChiku[m.ken] : 0;
      return '${koukouChikuMei[c]}大会$sm ${r == 1 ? '優勝' : '$r位'}';
    default:
      // 県大会は3位まで
      if (r < 1 || r > 3) return '';
      final String ken = (m.ken >= 0 && m.ken < LocationDatabase.allPrefectures.length)
          ? LocationDatabase.allPrefectures[m.ken]
          : '';
      return '$ken大会$sm ${r == 1 ? '優勝' : '$r位'}';
  }
}

/// 高校時代の実績の文の一覧(経歴・駅伝・総体の順。目立たないものは入らない)
List<String> koukouJissekiList(KoukouJouhou j) {
  return [
    for (final String s in [
      koukouKeirekiMoji(j),
      koukouEkidenMoji(j),
      koukouSoutaiMoji(j),
    ])
      if (s.isNotEmpty) s,
  ];
}

/// 選手画面に出す、出身校と高校時代の文(出さないときは空)
/// [hirou] 留学生(1)には出さない
String koukouProfileMoji(int samusataisei, int hirou, KantokuData kantoku) {
  if (hirou == 1) return '';
  if (koukouHyoujiNashi(kantoku)) return '';
  final KoukouJouhou j = KoukouJouhou.yomu(samusataisei);
  if (j.mei == null) return '';
  final List<String> jisseki = koukouJissekiList(j);
  return '出身校: ${koukouMeiKenMoji(j)}'
      '${jisseki.isEmpty ? '' : '\n高校時代: ${jisseki.join('、')}'}';
}

// ------------------------------------------------------------
// 計算
// ------------------------------------------------------------

/// 高校生1人(新入生か、名前のない高校生)
class _Kousei {
  /// 新入生(名前のない高校生はnull)
  final SenshuData? s;
  final double t5;
  final int nobori;
  final int kudari;
  final int updown;
  final int road;
  final int pace;
  final int spurt;
  final bool ryuugakusei;
  final int keireki;

  // 結果(新入生だけ使う)
  bool ekidenAri = false;
  bool ekidenZenkoku = false;
  int ekidenKukan = 0;
  int ekidenKukanJuni = 0;
  int ekidenJuni = 0;
  int soutaiShumoku = 0;
  int soutaiDankai = 0;
  int soutaiJuni = 0;

  _Kousei({
    required this.s,
    required this.t5,
    required this.nobori,
    required this.kudari,
    required this.updown,
    required this.road,
    required this.pace,
    required this.spurt,
    required this.ryuugakusei,
    required this.keireki,
  });
}

/// 正規分布の乱数(平均0、標準偏差1)
double _gauss(Random r) {
  double u1 = r.nextDouble();
  if (u1 < 1e-12) u1 = 1e-12;
  final double u2 = r.nextDouble();
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
}

int _nouryoku(int v) => v.clamp(1, 99).toInt();

/// 入学時の5000mから決める、名前のない高校生のスパート力(新入生の作り方と同じ形)
int _spurtFromT5(double t5, Random r) {
  if (t5 < 840) return 70 + r.nextInt(30);
  final double sositu = 1601 + (t5 - 840) / 0.9375;
  return _nouryoku((100 * (1680 - sositu) / 130).toInt());
}

/// 名前のない高校生([level] 名門度。-1はその他の高校。[gakunen] 1〜3)
_Kousei _nanashi(int level, int gakunen, Random r) {
  const List<double> heikin = [935, 912, 896, 880, 866]; // 3年生の5000mの平均(その他・普通・中堅・強豪・名門)
  final double t5 =
      heikin[(level + 1).clamp(0, 4).toInt()] + (gakunen == 3 ? 0 : (gakunen == 2 ? 12 : 25)) + _gauss(r) * 16;
  final int spurt = _spurtFromT5(t5, r);
  return _Kousei(
    s: null,
    t5: t5,
    nobori: 1 + r.nextInt(99),
    kudari: 1 + r.nextInt(99),
    updown: 1 + r.nextInt(99),
    road: 1 + r.nextInt(99),
    pace: _nouryoku(spurt - 10 + r.nextInt(21) - 10),
    spurt: spurt,
    ryuugakusei: false,
    keireki: r.nextInt(100) < 15 ? 1 : 0,
  );
}

/// 名前のない留学生
_Kousei _nanashiRyuugakusei(Random r) {
  return _Kousei(
    s: null,
    t5: 800 + r.nextDouble() * 35,
    nobori: 1 + r.nextInt(99),
    kudari: 1 + r.nextInt(99),
    updown: 1 + r.nextInt(99),
    road: 1 + r.nextInt(99),
    pace: 1 + r.nextInt(89),
    spurt: 60 + r.nextInt(40),
    ryuugakusei: true,
    keireki: 0,
  );
}

/// 新入生を高校生にする(入学時の5000mの記録がなければnull)
_Kousei? _shinnyuusei(SenshuData s, int keireki) {
  final double t5 = s.kiroku_nyuugakuji_5000;
  if (t5 <= 0 || t5 >= 1200) return null;
  return _Kousei(
    s: s,
    t5: t5,
    nobori: _nouryoku(s.noboritekisei),
    kudari: _nouryoku(s.kudaritekisei),
    updown: _nouryoku(s.noborikudarikirikaenouryoku),
    road: _nouryoku(s.tandokusou),
    pace: _nouryoku(s.paceagesagetaiouryoku),
    spurt: _nouryoku(s.spurtryoku),
    ryuugakusei: false,
    keireki: keireki,
  );
}

/// 駅伝の区間(距離m、記録の係数、登りの強さ(登りの割合×勾配)、下りの強さ、登り下りの切り替えの回数)
class _Kukan {
  final double kyori;
  final double keisuu;
  final double nobori;
  final double kudari;
  final int kirikae;
  const _Kukan(this.kyori, this.keisuu, this.nobori, this.kudari, this.kirikae);
}

/// 冬のロードの係数(トラックの持ちタイムより遅い)
const double _road = 1.02;

/// 全国高校駅伝の区間(実在の男子のコースの距離と、起伏の特徴を数にしたもの)
const List<_Kukan> _zenkokuKukan = [
  _Kukan(10000, 1.022, 0.0045, 0.0020, 2), // 1区: 前半は上り、7.5km付近から下り
  _Kukan(3000, 0.990, 0.0005, 0.0005, 0), // 2区: 最短区間。ほぼ平ら
  _Kukan(8107.5, 1.008, 0.0040, 0.0010, 6), // 3区: 登りが多く、跨線橋でアップダウン
  _Kukan(8087.5, 0.997, 0.0010, 0.0040, 4), // 4区: 3区をほぼ逆に走り、下りが多い
  _Kukan(3000, 1.004, 0.0030, 0.0020, 1), // 5区: 前半上り、後半下り
  _Kukan(5000, 1.003, 0.0010, 0.0010, 1), // 6区
  _Kukan(5000, 1.003, 0.0010, 0.0010, 1), // 7区
];

/// 都道府県予選の区間(距離は全国と同じ。起伏はなし)
const List<_Kukan> _yosenKukan = [
  _Kukan(10000, 1.0, 0, 0, 0),
  _Kukan(3000, 1.0, 0, 0, 0),
  _Kukan(8107.5, 1.0, 0, 0, 0),
  _Kukan(8087.5, 1.0, 0, 0, 0),
  _Kukan(3000, 1.0, 0, 0, 0),
  _Kukan(5000, 1.0, 0, 0, 0),
  _Kukan(5000, 1.0, 0, 0, 0),
];

/// 区間のタイム(秒)。補正の形は試走の計算(TrialTime.dart)と同じで、能力50を基準にした差だけをかける
double _kukanTime(_Kousei k, int kk, List<_Kukan> kukan, Random r) {
  final _Kukan c = kukan[kk];
  double t = k.t5 * pow(c.kyori / 5000.0, 1.06).toDouble() * c.keisuu * _road;
  final double m = 1.0 +
      0.00017 * 0.65 * (k.nobori - 50) * (c.nobori / 0.01) +
      0.00018 * 0.58 * (k.kudari - 50) * (c.kudari / 0.01) +
      0.000005 * c.kirikae * (k.updown - 50);
  t /= m;
  t *= 1.0 + (50 - k.road) * 0.0003 * 0.5;
  if (kk == 0) t *= 1.0 + (50 - k.pace) * 0.0003; // 1区は集団の中のペースの上げ下げ
  t += -0.3265 * 0.15 * (k.spurt - 50);
  t *= 1.0 + _gauss(r) * 0.009;
  if (r.nextInt(100) < 3) t *= 1.02 + r.nextDouble() * 0.04; // ブレーキ
  return t;
}

/// 高校総体のタイム(秒)。[shumoku] 1=1500m・2=5000m・3=3000m障害
double _trackTime(_Kousei k, int shumoku, Random r) {
  double t;
  if (shumoku == 1) {
    t = k.t5 * pow(0.3, 1.08).toDouble() * (k.keireki == 1 ? 0.98 : 1.0);
    t += -0.3265 * 0.15 * (k.spurt - 50);
  } else if (shumoku == 3) {
    t = k.t5 * pow(0.6, 1.06).toDouble() * 1.075;
    t *= 1.0 - 0.0004 * (k.updown - 50); // 障害はアップダウンへの対応で
    t += -0.3265 * 0.25 * (k.spurt - 50);
  } else {
    t = k.t5;
    t += -0.3265 * 0.4 * (k.spurt - 50);
    t *= 1.0 + (50 - k.pace) * 0.0003 * 0.5;
  }
  t *= 1.03; // 夏の大会(持ちタイムより遅い)
  t *= 1.0 + _gauss(r) * 0.011;
  if (r.nextInt(100) < 8) t *= 1.02 + r.nextDouble() * 0.04; // 暑さで崩れる
  return t;
}

/// 駅伝のチーム(区間ごとの選手)
class _Team {
  /// 名簿の高校の番号(その他の高校は-1)
  final int koukou;
  final List<_Kousei> ku;
  final List<_Kousei> hoketsu;
  double goukei = 0;
  List<double> times = [];
  _Team(this.koukou, this.ku, this.hoketsu);
}

/// 部員から7人を選んで区間に並べる(高校の監督の考え方。エース1区・2番手3区・3番手4区・…)
_Team _haichi(int koukou, List<_Kousei> bu, Random r) {
  final List<_Kousei> kouho = List<_Kousei>.of(bu);
  final Map<_Kousei, double> mikomi = {for (final _Kousei k in kouho) k: k.t5 * (1.0 + _gauss(r) * 0.004)};
  kouho.sort((a, b) => mikomi[a]!.compareTo(mikomi[b]!));
  final List<_Kousei> ryu = [for (final _Kousei k in kouho) if (k.ryuugakusei) k];
  final List<_Kousei> jp = [for (final _Kousei k in kouho) if (!k.ryuugakusei) k];
  final List<int> jun = [0, 2, 3, 6, 5, 1, 4]; // 力の順に置く区間
  final List<_Kousei?> ku = List<_Kousei?>.filled(7, null);
  if (ryu.isNotEmpty) {
    final int ryuKukan = r.nextBool() ? 1 : 4; // 留学生は2区か5区
    ku[ryuKukan] = ryu.first;
    jun.remove(ryuKukan);
  }
  for (int i = 0; i < jun.length && i < jp.length; i++) {
    ku[jun[i]] = jp[i];
  }
  // 中距離出身の選手を3kmの区間へ(4区・6区・7区にいれば入れ替える)
  for (final int sk in const [1, 4]) {
    final _Kousei? a = ku[sk];
    if (a == null || a.ryuugakusei || a.keireki == 1) continue;
    for (final int j in const [3, 5, 6]) {
      final _Kousei? b = ku[j];
      if (b != null && b.keireki == 1) {
        ku[sk] = b;
        ku[j] = a;
        break;
      }
    }
  }
  final List<_Kousei> hashiru = [for (final _Kousei? k in ku) if (k != null) k];
  final List<_Kousei> hoketsu = [for (final _Kousei k in bu) if (!hashiru.contains(k)) k];
  return _Team(koukou, hashiru, hoketsu);
}

/// 駅伝を走らせる(チームの順に並べ替え、区間ごとの順位を返す。区間順位は[kukan][チームの並び])
List<List<int>> _ekiden(List<_Team> teams, List<_Kukan> kukan, Random r) {
  for (final _Team t in teams) {
    t.times = [for (int kk = 0; kk < t.ku.length; kk++) _kukanTime(t.ku[kk], kk, kukan, r)];
    t.goukei = t.times.fold<double>(0, (a, b) => a + b);
    // 7人そろわないチーム(普通は起きない)は最後にする
    if (t.ku.length < 7) t.goukei += 99999;
  }
  teams.sort((a, b) => a.goukei.compareTo(b.goukei));
  final List<List<int>> kj = [];
  for (int kk = 0; kk < 7; kk++) {
    final List<int> idx = [
      for (int i = 0; i < teams.length; i++)
        if (teams[i].ku.length > kk) i,
    ]..sort((a, b) => teams[a].times[kk].compareTo(teams[b].times[kk]));
    final List<int> juni = List<int>.filled(teams.length, 0);
    for (int j = 0; j < idx.length; j++) {
      juni[idx[j]] = j;
    }
    kj.add(juni);
  }
  return kj;
}

/// 駅伝の結果を新入生に書く
void _ekidenKekka(List<_Team> teams, List<List<int>> kj, {required bool zenkoku}) {
  for (int ti = 0; ti < teams.length; ti++) {
    final _Team t = teams[ti];
    for (int kk = 0; kk < t.ku.length; kk++) {
      final _Kousei k = t.ku[kk];
      if (k.s == null) continue;
      k.ekidenAri = true;
      k.ekidenZenkoku = zenkoku;
      k.ekidenKukan = kk + 1;
      k.ekidenKukanJuni = min(kj[kk][ti] + 1, 31);
      k.ekidenJuni = min(ti + 1, 31);
    }
    for (final _Kousei k in t.hoketsu) {
      if (k.s == null) continue;
      k.ekidenAri = true;
      k.ekidenZenkoku = zenkoku;
      k.ekidenKukan = 0;
      k.ekidenKukanJuni = 0;
      k.ekidenJuni = min(ti + 1, 31);
    }
  }
}

/// 新入生が得意そうな高校の色(0スピード型 1駅伝型 2起伏型)
int _tokuiIro(_Kousei k) {
  if (k.spurt >= 70) return 0;
  if (max(k.nobori, max(k.kudari, k.updown)) >= 75) return 2;
  return 1;
}

/// 新入生の高校を選ぶ(番号。名簿の並び)
int _koukouErabu(_Kousei k, int ken, Random r) {
  final int ekkyo = k.t5 < 840 ? 35 : (k.t5 < 860 ? 20 : 5);
  final List<int> kouho = [];
  if (r.nextInt(100) < ekkyo) {
    for (int i = 0; i < koukouMeibo.length; i++) {
      if (koukouMeibo[i].meimon == 3) kouho.add(i);
    }
  }
  if (kouho.isEmpty) {
    for (int i = 0; i < koukouMeibo.length; i++) {
      if (koukouMeibo[i].ken == ken) kouho.add(i);
    }
  }
  if (kouho.isEmpty) return r.nextInt(koukouMeibo.length);
  final double z = (880 - k.t5) / 25.0;
  final int tokui = _tokuiIro(k);
  final List<double> omomi = [
    for (final int i in kouho)
      exp(0.9 * koukouMeibo[i].meimon * z) * (koukouMeibo[i].iro == tokui ? 1.5 : 1.0),
  ];
  final double goukei = omomi.fold<double>(0, (a, b) => a + b);
  double x = r.nextDouble() * goukei;
  for (int j = 0; j < kouho.length; j++) {
    x -= omomi[j];
    if (x <= 0) return kouho[j];
  }
  return kouho.last;
}

/// 経歴を決める(遅めの選手ほど、中距離出身・ほかの競技の出身が多い)
int _keirekiKimeru(double t5, Random r) {
  final int x = r.nextInt(100);
  if (t5 >= 880) return x < 8 ? 2 : (x < 23 ? 1 : 0);
  if (t5 >= 855) return x < 3 ? 2 : (x < 18 ? 1 : 0);
  return x < 1 ? 2 : (x < 13 ? 1 : 0);
}

/// 1学年分(その年の高校3年生)を計算して、新入生の高校の情報を決める
/// 戻り値は、選手ごとの新しい情報(選手のidから)
Map<int, KoukouJouhou> _nendoKeisan(List<SenshuData> shinnyuusei, Random r) {
  final Map<int, KoukouJouhou> kekka = {};
  final int kenSuu = LocationDatabase.allPrefectures.length;
  final List<_Kousei> jitsuzai = []; // 走る新入生
  final List<List<_Kousei>> bu = [for (int i = 0; i < koukouMeibo.length; i++) <_Kousei>[]];

  // 新入生の高校と経歴
  for (final SenshuData s in shinnyuusei) {
    int ken = PackedIndexHelper.unpackIndices(s.samusataisei)['prefectureIndex'] ?? -1;
    if (ken < 0 || ken >= kenSuu) ken = r.nextInt(kenSuu);
    final double t5 = s.kiroku_nyuugakuji_5000;
    final bool kirokuAri = t5 > 0 && t5 < 1200;
    final int keireki = kirokuAri ? _keirekiKimeru(t5, r) : 2;
    final _Kousei? k = keireki == 2 ? null : _shinnyuusei(s, keireki);
    int koukou;
    if (k != null) {
      koukou = _koukouErabu(k, ken, r);
      jitsuzai.add(k);
      bu[koukou].add(k);
    } else {
      // ほかの競技の出身(記録がない選手も): 地元の高校
      final List<int> kouho = [
        for (int i = 0; i < koukouMeibo.length; i++)
          if (koukouMeibo[i].ken == ken) i,
      ];
      koukou = kouho.isEmpty ? r.nextInt(koukouMeibo.length) : kouho[r.nextInt(kouho.length)];
    }
    kekka[s.id] = KoukouJouhou(koukou: koukou + 1, keireki: keireki);
  }

  // 名前のない部員(各校9人)と留学生
  for (int i = 0; i < koukouMeibo.length; i++) {
    for (final int g in const [3, 3, 3, 2, 2, 2, 1, 1, 1]) {
      bu[i].add(_nanashi(koukouMeibo[i].meimon, g, r));
    }
    if (koukouMeibo[i].ryuugakusei) bu[i].add(_nanashiRyuugakusei(r));
  }

  // ---- 全国高校駅伝(都道府県予選 → 全国) ----
  final List<_Team> zenkoku = [];
  final List<List<_Team>> chikuNi = [for (int c = 0; c < koukouChikuMei.length; c++) <_Team>[]];
  for (int ken = 0; ken < kenSuu; ken++) {
    final List<_Team> teams = [];
    for (int i = 0; i < koukouMeibo.length; i++) {
      if (koukouMeibo[i].ken == ken) teams.add(_haichi(i, bu[i], r));
    }
    final int sonota = ken < koukouKenSonota.length ? koukouKenSonota[ken] : 6;
    for (int f = 0; f < sonota; f++) {
      teams.add(_haichi(-1, [for (final int g in const [3, 3, 3, 2, 2, 2, 1, 1, 1]) _nanashi(-1, g, r)], r));
    }
    final List<List<int>> kj = _ekiden(teams, _yosenKukan, r);
    _ekidenKekka(teams, kj, zenkoku: false);
    zenkoku.add(teams.first);
    if (teams.length >= 2 && ken < koukouKenChiku.length) chikuNi[koukouKenChiku[ken]].add(teams[1]);
  }
  // 地区代表(各地区の予選2位の高校のうち、予選のタイムが一番良い高校)
  for (final List<_Team> c in chikuNi) {
    if (c.isEmpty) continue;
    c.sort((a, b) => a.goukei.compareTo(b.goukei));
    zenkoku.add(c.first);
  }
  // 全国(予選の区間の並びのまま走る)
  final List<_Team> zenkokuTeams = [for (final _Team t in zenkoku) _Team(t.koukou, t.ku, t.hoketsu)];
  final List<List<int>> zkj = _ekiden(zenkokuTeams, _zenkokuKukan, r);
  _ekidenKekka(zenkokuTeams, zkj, zenkoku: true);

  // ---- 高校総体(県大会 → 地区大会 → 全国大会) ----
  // 種目を選ぶ(中距離出身は1500m。ほかは5000m 70%・3000m障害15%・1500m 15%。留学生は5000mか障害)
  final List<List<List<_Kousei>>> kenEntry = [
    for (int ken = 0; ken < kenSuu; ken++) [<_Kousei>[], <_Kousei>[], <_Kousei>[], <_Kousei>[]],
  ];
  for (int i = 0; i < koukouMeibo.length; i++) {
    final int ken = koukouMeibo[i].ken;
    if (ken < 0 || ken >= kenSuu) continue;
    final List<List<_Kousei>> per = [<_Kousei>[], <_Kousei>[], <_Kousei>[], <_Kousei>[]];
    for (final _Kousei k in bu[i]) {
      int sh;
      if (k.ryuugakusei) {
        sh = r.nextInt(100) < 70 ? 2 : 3;
      } else if (k.keireki == 1) {
        sh = 1;
      } else {
        final int x = r.nextInt(100);
        sh = x < 70 ? 2 : (x < 85 ? 3 : 1);
      }
      per[sh].add(k);
    }
    // 1校1種目3人まで(持ちタイムの順)
    for (int sh = 1; sh <= 3; sh++) {
      per[sh].sort((a, b) => a.t5.compareTo(b.t5));
      for (final _Kousei k in per[sh].take(3)) {
        kenEntry[ken][sh].add(k);
      }
    }
  }
  for (int ken = 0; ken < kenSuu; ken++) {
    final int sonota = ken < koukouKenSonota.length ? koukouKenSonota[ken] : 6;
    for (int sh = 1; sh <= 3; sh++) {
      for (int f = 0; f < sonota; f++) {
        kenEntry[ken][sh].add(_nanashi(-1, 3, r));
      }
    }
  }
  for (int sh = 1; sh <= 3; sh++) {
    final List<List<_Kousei>> chiku = [for (int c = 0; c < koukouChikuMei.length; c++) <_Kousei>[]];
    // 県大会
    for (int ken = 0; ken < kenSuu; ken++) {
      final List<_Kousei> jun = _track(kenEntry[ken][sh], sh, r);
      for (int j = 0; j < jun.length; j++) {
        _soutaiKaku(jun[j], sh, 0, j);
      }
      if (ken < koukouKenChiku.length) chiku[koukouKenChiku[ken]].addAll(jun.take(6));
    }
    // 地区大会
    final List<_Kousei> zen = [];
    for (final List<_Kousei> c in chiku) {
      final List<_Kousei> jun = _track(c, sh, r);
      for (int j = 0; j < jun.length; j++) {
        _soutaiKaku(jun[j], sh, 1, j);
      }
      zen.addAll(jun.take(6));
    }
    // 全国大会(予選3組 → 各組4着とタイムで3人 → 決勝15人)
    zen.shuffle(r);
    final List<_Kousei> kesshou = [];
    final List<MapEntry<_Kousei, double>> nokori = [];
    for (int g = 0; g < 3; g++) {
      final List<MapEntry<_Kousei, double>> kumi = [
        for (int i = g; i < zen.length; i += 3) MapEntry(zen[i], _trackTime(zen[i], sh, r)),
      ]..sort((a, b) => a.value.compareTo(b.value));
      for (int j = 0; j < kumi.length; j++) {
        if (j < 4) {
          kesshou.add(kumi[j].key);
        } else {
          nokori.add(kumi[j]);
        }
      }
    }
    nokori.sort((a, b) => a.value.compareTo(b.value));
    for (int j = 0; j < nokori.length; j++) {
      if (j < 3) {
        kesshou.add(nokori[j].key);
      } else {
        _soutaiKaku(nokori[j].key, sh, 2, -1);
      }
    }
    final List<_Kousei> fin = _track(kesshou, sh, r);
    for (int j = 0; j < fin.length; j++) {
      _soutaiKaku(fin[j], sh, 3, j);
    }
  }

  // 結果をまとめる
  for (final _Kousei k in jitsuzai) {
    final SenshuData? s = k.s;
    if (s == null) continue;
    final KoukouJouhou? mae = kekka[s.id];
    if (mae == null) continue;
    kekka[s.id] = KoukouJouhou(
      koukou: mae.koukou,
      keireki: mae.keireki,
      ekidenZenkoku: k.ekidenZenkoku,
      ekidenKukan: k.ekidenAri ? k.ekidenKukan : 0,
      ekidenKukanJuni: k.ekidenAri ? k.ekidenKukanJuni : 0,
      ekidenJuni: k.ekidenAri ? k.ekidenJuni : 0,
      soutaiShumoku: k.soutaiShumoku,
      soutaiDankai: k.soutaiDankai,
      soutaiJuni: k.soutaiJuni,
    );
  }
  return kekka;
}

/// トラックのレースを走らせて、着順に並べる
List<_Kousei> _track(List<_Kousei> sousha, int sh, Random r) {
  final List<MapEntry<_Kousei, double>> t = [
    for (final _Kousei k in sousha) MapEntry(k, _trackTime(k, sh, r)),
  ]..sort((a, b) => a.value.compareTo(b.value));
  return [for (final MapEntry<_Kousei, double> e in t) e.key];
}

/// 高校総体の結果を新入生に書く(段階が上がったときだけ上書き)。[juni0] 0が1位、-1は順位なし
void _soutaiKaku(_Kousei k, int sh, int dankai, int juni0) {
  if (k.s == null) return;
  if (k.soutaiShumoku != 0 && dankai < k.soutaiDankai) return;
  k.soutaiShumoku = sh;
  k.soutaiDankai = dankai;
  k.soutaiJuni = (juni0 >= 0 && juni0 < 15) ? juni0 + 1 : 0;
}

/// 高校が未設定の日本人選手に、出身校と高校時代の実績を付けて保存する(学年ごとにまとめて計算)。
/// 起動時・セーブデータの読み込み時・年度替わり(新入生の所属先が決まったあと)・新しいゲームの開始時に呼ぶ。
/// 付けた人数を返す(未設定の選手がいなければ何もしない)
Future<int> koukouJouhouFuyo() async {
  if (!Hive.isBoxOpen('senshuBox')) return 0;
  final Box<SenshuData> box = Hive.box<SenshuData>('senshuBox');
  final Map<int, List<SenshuData>> gakunenGoto = {};
  for (final SenshuData s in box.values) {
    if (s.hirou == 1) continue; // 留学生には付けない
    if (KoukouJouhou.yomu(s.samusataisei).koukou != 0) continue;
    gakunenGoto.putIfAbsent(s.gakunen, () => <SenshuData>[]).add(s);
  }
  if (gakunenGoto.isEmpty) return 0;
  final Random r = Random();
  int kazu = 0;
  for (final List<SenshuData> list in gakunenGoto.values) {
    final Map<int, KoukouJouhou> kekka = _nendoKeisan(list, r);
    for (final SenshuData s in list) {
      final KoukouJouhou? j = kekka[s.id];
      if (j == null) continue;
      s.samusataisei = j.kakikomi(s.samusataisei);
      await s.save();
      kazu++;
    }
  }
  print('出身校と高校時代の実績を付けた選手: $kazu人'); // 確認用(1.9.5)
  return kazu;
}
