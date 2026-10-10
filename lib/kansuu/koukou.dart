import 'dart:convert'; // 高校の大会の記録(1.9.5)
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart'; // 高校の大会の記録の年度(1.9.5)
import 'package:ekiden/univ_data.dart'; // 高校の大会の記録の保存場所(1.9.5)
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/koukou_meibo.dart';
import 'package:ekiden/kansuu/joukai.dart'; // 留学生の入学時の優秀度(1.9.5)

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
//   区間は高校の監督が決める。留学生は2区か5区だけ(2024年からの実在の決まり)。中距離出身の選手は
//   空いている3kmの区間(2区・5区。最初の1人は7割が2区)へ、入りきらなければ5kmの7区・6区へ。
//   長距離の選手は、力の順に1区・3区・4区・7区・6区・(空いていれば)2区・5区へ。
//   中距離出身の選手は、3kmの区間では1%速く、8km以上の区間では1.5%遅く走る
// ・高校総体: 1500m・5000m・3000m障害。県大会の上位6人が地区大会、地区大会の上位6人が全国大会。
//   全国大会は予選3組(各組4着とタイムで3人)のあと、15人の決勝。
//   種目は、中距離出身は1500m、長距離の選手は障害への向き(_shougaiMuki)が高いほど3000m障害、
//   ペース変動対応力が高いほど1500m、ほかは5000m。各校の上位2人は掛け持ちし(1500mと5000mなど)、
//   保存するのは一番良い種目の結果。1校1種目3人の枠からあふれた選手は、空いている種目に回す
// ・タイムの目安(数年分を試した平均): 全国高校駅伝の優勝は2時間2〜4分、1区の区間賞は29分台前半、
//   高校総体5000mの日本人トップは13分50秒前後(優勝は留学生が多い)。
//   新入生150人のうち、全国高校駅伝を走るのは毎年60人前後、区間賞は2〜3人、高校総体の決勝は18人前後
// ・新入生をどの高校に入れるか: 出身地の県の5校から、速い選手ほど名門に入りやすく選ぶ。
//   速い選手は県外の名門に入ることもある(13分台は35%、14分20秒より速いと20%、ほかは5%)
// ・経歴: 長距離ひと筋・中距離出身・ほかの競技の出身。隠れた逸材かどうかとは無関係
//   ・ほかの競技の出身: 入学時の持ちタイムが遅めの選手ほど多い(14分40秒以上8%、14分15秒以上3%、ほか1%)
//   ・中距離出身: スパート力とペース変動対応力の平均が高い選手ほど多い(4〜30%。全体で約14%。
//     スパート力は入学時の持ちタイムで決まるので、速い選手ほど多くなる。13分台は約28%)
//   ・ほかの競技の部活は、その部活に合った能力が高い選手ほど選ばれやすい(_bukatsuNouryoku。ほのかな手がかり)
//
// 保存(SenshuData.samusataisei の、出身地と趣味(下の17ビット)より上。数で詰めるので2の49乗未満)
//   samusataisei = 下の17ビット + 131072 × 上の値
//   上の値 = 高校(番号+1、0は未設定。256通り) + 256 × (経歴(4通り) + 4 × (全国か(2通り) + 2 × (区間(8通り。
//   0は出走なし。ほかの競技の出身の選手は駅伝を走らないので、ここに部活の番号を入れる) + 8 × (区間順位(32通り。1〜31、31は31位以下、0はなし) + 32 × (チーム順位(32通り) +
//   32 × (総体の種目(4通り。0なし・1=1500m・2=5000m・3=3000m障害) + 4 × (段階(4通り。0県・1地区・
//   2全国予選・3全国決勝) + 4 × 順位(16通り。1〜15、0は16位以下)))))))
//   (Webでも正しく動くように、ビット演算ではなく掛け算と割り算で詰める)
// ・高校が未設定(0)の日本人選手には、起動時・セーブデータの読み込み時・年度替わり・新しいゲームの開始時に、
//   学年ごとにまとめて付ける(koukouJouhouFuyo)。版の番号では判定しない(1.9.5testで開いたデータにも付くように)
// ・大学に来た留学生(1.9.5): 約半分(_ryuugakuseiKoukouWariai)に、名簿の留学生のいる高校のどれかを付ける
//   (名門の高校ほど選ばれやすい。1校から同じ年に大学へ来る留学生は1人まで)。その年は、その高校の名前のない
//   留学生の代わりに、その選手が日本人の新入生と一緒に走る。力の土台は入学時の5000mの記録がないので、
//   大学の留学生の優秀度(入学時の基本走力を決めたもの。magicnumberに残っている)から決める(_ryuugakuseiKousei)。
//   登り・下りなどの補正は、その選手の能力値を使う。残りの留学生は日本の高校に通っていない(出身校なし)。
//   どちらも経歴を3(koukouKeirekiRyuugakusei)にして「決めた」しるしにする(起動のたびに抽選し直さないように。
//   経歴が3でない留学生は、日本人だったころの古い情報が入っていても、決め直す)
// ・表示しない設定: KantokuData.yobiint2[86](0=表示(初期値)・1=表示しない。趣味・高校時代の表示設定の画面)
// ------------------------------------------------------------

const int _shitaBit = 131072; // 2の17乗(出身地と趣味の分)

/// 経歴の3: 大学に来た留学生の高校を決めたしるし(高校が0なら、日本の高校に通っていない。1.9.5)
const int koukouKeirekiRyuugakusei = 3;

/// 大学に来た留学生のうち、日本の高校の出身にする割合(1.9.5)
const double _ryuugakuseiKoukouWariai = 0.5;

/// 高校の情報を表示しないか(KantokuData.yobiint2[86]=1)
bool koukouHyoujiNashi(KantokuData kantoku) =>
    kantoku.yobiint2.length > 86 && kantoku.yobiint2[86] == 1;

/// 画面や記事に出してよい高校の情報(1.9.5。出さないときはnull)
/// 表示しない設定のときと、高校が未設定・なしのときはnull。
/// 留学生([hirou]が1)は、高校を決めたあと(経歴が3)のときだけ(日本人だったころの古い情報は出さない)
KoukouJouhou? koukouHyoujiJouhou(int samusataisei, int hirou, KantokuData kantoku) {
  if (koukouHyoujiNashi(kantoku)) return null;
  final KoukouJouhou j = KoukouJouhou.yomu(samusataisei);
  if (j.mei == null) return null;
  if (hirou == 1 && j.keireki != koukouKeirekiRyuugakusei) return null;
  return j;
}

/// 1人分の高校の情報(samusataisei の上の値)
class KoukouJouhou {
  /// 高校の番号+1(0は未設定)
  final int koukou;

  /// 経歴(0長距離ひと筋 1中距離出身 2ほかの競技の出身 3大学に来た留学生(高校を決めたしるし。1.9.5))
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

  /// 下の17ビット(出身地と趣味。1.9.5の開発中は部活の名前を決めるのに使っていたが、今は部活の番号を保存する)
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

/// ほかの競技の出身のときの、部活の名前(番号を保存するので、並びを変えない。8つまで)
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

/// 都道府県の短い名前(ほかの画面で使う。高校名鑑。1.9.5)
String koukouKenMijikai(int ken) => _kenMijikai(ken);

/// 校名(「雷鳥館高」)
String koukouMeiMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  return m == null ? '' : '${m.mei}高';
}

/// 校名と都道府県(「雷鳥館高(長野)」)
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
      return '高校までは${koukouHokaKyougi(j)}';
    default:
      return '';
  }
}

/// 全国高校駅伝・都道府県予選の文(目立たない結果なら空)
String koukouEkidenMoji(KoukouJouhou j) {
  final KoukouMei? m = j.mei;
  if (m == null || j.keireki == 2) return ''; // ほかの競技の出身は、駅伝の欄に部活の番号が入っている
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

/// ほかの競技の出身のときの部活の名前(「サッカー部」。ほかの競技の出身でなければ空)
/// (部活の番号は、駅伝の区間の欄に入っている)
String koukouHokaKyougi(KoukouJouhou j) {
  if (j.keireki != 2) return '';
  return _hokaKyougi[j.ekidenKukan.clamp(0, _hokaKyougi.length - 1).toInt()];
}

/// 記事に書く、高校時代の一番の実績の文(過去形。「全国高校駅伝の1区で区間賞を取った」など。
/// 目立つものがなければ、経歴(中距離・ほかの競技)。それもなければ空)
String koukouJissekiBun(KoukouJouhou j) {
  if (j.keireki == 2) return '${koukouHokaKyougi(j)}に所属していた';
  final int ku = j.ekidenKukan;
  final int kj = j.ekidenKukanJuni;
  final int tj = j.ekidenJuni;
  final int sh = j.soutaiShumoku;
  final String sm = (sh >= 1 && sh <= 3) ? koukouShumokuMei[sh] : '';
  final bool ekidenMedatsu = j.ekidenZenkoku && ku > 0 && ((kj >= 1 && kj <= 3) || (tj >= 1 && tj <= 3));
  if (ekidenMedatsu) {
    final String kukanMoji = kj == 1 ? '区間賞' : ((kj >= 2 && kj <= 30) ? '区間$kj位' : '');
    if (tj == 1) {
      return kukanMoji.isEmpty
          ? '全国高校駅伝の優勝メンバーで、$ku区を走った'
          : '全国高校駅伝の優勝メンバーで、$ku区を$kukanMojiで走った';
    }
    if (kj == 1) return '全国高校駅伝の$ku区で区間賞を取った';
    if (kukanMoji.isNotEmpty) return '全国高校駅伝の$ku区で$kukanMojiに入った';
    return '全国高校駅伝の$ku区を走り、チームは$tj位だった';
  }
  if (j.soutaiDankai == 3 && sm.isNotEmpty) {
    final int r = j.soutaiJuni;
    if (r == 1) return '高校総体の$smで優勝した';
    if (r >= 2 && r <= 8) return '高校総体の$smで$r位に入った';
    return '高校総体の$smで決勝に進んだ';
  }
  if (j.ekidenZenkoku && ku > 0) return '全国高校駅伝の$ku区を走った';
  if (j.soutaiDankai == 2 && sm.isNotEmpty) return '高校総体の$smに出場した';
  if (j.keireki == 2) return '${koukouHokaKyougi(j)}に所属していた';
  if (j.keireki == 1) return '中距離が専門だった';
  return '';
}

/// 一覧の画面に出す出身校(「雷鳥館高(長野)」。1.9.5)
/// 表示しない設定のときと、未設定・出身校なし(日本の高校に通っていない留学生)のときは空
String koukouIchiranMoji(int samusataisei, int hirou, KantokuData kantoku) {
  final KoukouJouhou? j = koukouHyoujiJouhou(samusataisei, hirou, kantoku);
  return j == null ? '' : koukouMeiKenMoji(j);
}

/// 一覧の画面に出す、高校時代の一番の実績の短い文(1.9.5。なければ空)
/// 全国高校駅伝 → 高校総体の全国大会 → 都道府県予選 → 地区・県大会 → 経歴の順に、最初に出せるもの
String koukouJissekiHitokoto(int samusataisei, int hirou, KantokuData kantoku) {
  final KoukouJouhou? j = koukouHyoujiJouhou(samusataisei, hirou, kantoku);
  if (j == null) return '';
  final String ekiden = koukouEkidenMoji(j);
  final String soutai = koukouSoutaiMoji(j);
  if (j.ekidenZenkoku && ekiden.isNotEmpty) return ekiden;
  if (j.soutaiDankai >= 2 && soutai.isNotEmpty) return soutai;
  if (ekiden.isNotEmpty) return ekiden;
  if (soutai.isNotEmpty) return soutai;
  return koukouKeirekiMoji(j);
}

/// 選手画面に出す、出身校と高校時代の文(出さないときは空)
/// [hirou] 留学生(1)は、日本の高校の出身のときだけ出す(1.9.5)
String koukouProfileMoji(int samusataisei, int hirou, KantokuData kantoku) {
  final KoukouJouhou? j = koukouHyoujiJouhou(samusataisei, hirou, kantoku);
  if (j == null) return '';
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
  /// 高校総体の種目ごとの一番上の段階(番号は種目。-1は出ていない)と、その段階の順位(1〜15、0は16位以下か全国予選)
  /// (掛け持ちがあるので種目ごとに持ち、最後に一番良い種目を1つ選んで保存する。1.9.5)
  final List<int> sDankai = [-1, -1, -1, -1];
  final List<int> sJuni = [0, 0, 0, 0];

  // 大会の記録に書くための、高校(名簿の番号。その他の高校は-1)・都道府県・学年(1.9.5)
  int koukou = -1;
  int ken = -1;
  int gakunen = 3;

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
  final int pace = _nouryoku(spurt - 10 + r.nextInt(21) - 10);
  final _Kousei k = _Kousei(
    s: null,
    t5: t5,
    nobori: 1 + r.nextInt(99),
    kudari: 1 + r.nextInt(99),
    updown: 1 + r.nextInt(99),
    road: 1 + r.nextInt(99),
    pace: pace,
    spurt: spurt,
    ryuugakusei: false,
    keireki: r.nextDouble() < _chuukyoriKakuritsu(spurt, pace) ? 1 : 0,
  );
  k.gakunen = gakunen;
  return k;
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

/// 大学に来た留学生の、入学時の優秀度(1が一番強い〜4。1.9.5)
/// 入学時に大学の留学生の優秀度で決めた基本走力の上限(magicnumber)から読む(一番近い優秀度)
int _ryuugakuseiYuushuudo(SenshuData s) {
  int yoi = 1;
  double saMin = double.infinity;
  for (int y = 1; y <= 4; y++) {
    final double sa = (s.magicnumber - ryuugakuseiJoukaiMagicnumber(y)).abs();
    if (sa < saMin) {
      saMin = sa;
      yoi = y;
    }
  }
  return yoi;
}

/// 大学に来た留学生を、高校3年生の留学生にする(1.9.5)
/// 入学時の5000mの記録がないので、力の土台は入学時の優秀度から決める(優秀度1は13分18秒前後、
/// 1つ下がるごとに8秒遅く。名前のない留学生は13分20〜55秒)。ほかの能力は、その選手の値を使う
_Kousei _ryuugakuseiKousei(SenshuData s, Random r) {
  final int yuushuudo = _ryuugakuseiYuushuudo(s);
  final double t5 = (798.0 + (yuushuudo - 1) * 8.0 + _gauss(r) * 6.0).clamp(785.0, 845.0).toDouble();
  return _Kousei(
    s: s,
    t5: t5,
    nobori: _nouryoku(s.noboritekisei),
    kudari: _nouryoku(s.kudaritekisei),
    updown: _nouryoku(s.noborikudarikirikaenouryoku),
    road: _nouryoku(s.tandokusou),
    pace: _nouryoku(s.paceagesagetaiouryoku),
    spurt: _nouryoku(s.spurtryoku),
    ryuugakusei: true,
    keireki: 0,
  );
}

/// 大学に来た留学生の高校を選ぶ(名簿の留学生のいる高校のうち、この年にまだ使っていない高校から。
/// 名門ほど選ばれやすい。選べる高校がなければ-1。1.9.5)
int _ryuugakuseiKoukouErabu(Set<int> tsukatta, Random r) {
  // 今の名簿を一度だけ読む(getter の koukouMeibo を、この中だけ同じ名前で置き換える。1.9.5)
  final List<KoukouMei> koukouMeibo = koukouMeiboGenzai();
  final List<int> kouho = [
    for (int i = 0; i < koukouMeibo.length; i++)
      if (koukouMeibo[i].ryuugakusei && !tsukatta.contains(i)) i,
  ];
  if (kouho.isEmpty) return -1;
  final List<double> omomi = [
    for (final int i in kouho) koukouMeibo[i].meimon >= 3 ? 3.0 : (koukouMeibo[i].meimon == 2 ? 2.0 : 1.0),
  ];
  final double goukei = omomi.fold<double>(0, (a, b) => a + b);
  double x = r.nextDouble() * goukei;
  for (int j = 0; j < kouho.length; j++) {
    x -= omomi[j];
    if (x <= 0) return kouho[j];
  }
  return kouho.last;
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
  // 中距離出身の選手は、3kmの区間では速く、8km以上の区間では遅い
  if (k.keireki == 1) {
    if (c.kyori <= 3000) {
      t *= 0.99;
    } else if (c.kyori >= 8000) {
      t *= 1.015;
    }
  }
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

/// 3000m障害への向き(1〜99。アップダウン対応力を強め、ペース変動対応力を中くらい、登り適性を弱めに見る。1.9.5)
/// 障害の前で減速して越え、また加速する繰り返しなので、アップダウンとペースの変化への対応が近い。
/// 登りは脚の筋力を通して少しだけ。下りは根拠が見つからないので使わない。土台は持ちタイム(地力)のまま
double _shougaiMuki(_Kousei k) => 0.5 * k.updown + 0.3 * k.pace + 0.2 * k.nobori;

/// 高校総体の見込みのタイム(秒。ばらつきなし。夏の大会の分は入る)。[shumoku] 1=1500m・2=5000m・3=3000m障害
double _trackMikomi(_Kousei k, int shumoku) {
  double t;
  if (shumoku == 1) {
    t = k.t5 * pow(0.3, 1.08).toDouble() * (k.keireki == 1 ? 0.98 : 1.0);
    t += -0.3265 * 0.15 * (k.spurt - 50);
  } else if (shumoku == 3) {
    t = k.t5 * pow(0.6, 1.06).toDouble() * 1.075;
    t *= 1.0 - 0.0005 * (_shougaiMuki(k) - 50); // 障害への向き
    t += -0.3265 * 0.25 * (k.spurt - 50);
  } else {
    t = k.t5;
    t += -0.3265 * 0.4 * (k.spurt - 50);
    t *= 1.0 + (50 - k.pace) * 0.0003 * 0.5;
  }
  return t * 1.03; // 夏の大会(持ちタイムより遅い)
}

/// 高校総体のタイム(秒。見込みのタイムに、その日のばらつきを入れる)
double _trackTime(_Kousei k, int shumoku, Random r) {
  double t = _trackMikomi(k, shumoku);
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

/// 部員から7人を選んで区間に並べる(高校の監督の考え方。1.9.5)
/// 7人は力の順に選ぶ。留学生は2区か5区。中距離出身は空いている3kmの区間(2区・5区)へ、
/// 入りきらなければ5kmの7区・6区へ。長距離の選手は力の順に1区・3区・4区・7区・6区・2区・5区の空きへ
_Team _haichi(int koukou, List<_Kousei> bu, Random r) {
  final List<_Kousei> kouho = List<_Kousei>.of(bu);
  final Map<_Kousei, double> mikomi = {for (final _Kousei k in kouho) k: k.t5 * (1.0 + _gauss(r) * 0.004)};
  kouho.sort((a, b) => mikomi[a]!.compareTo(mikomi[b]!));
  final List<_Kousei> ryu = [for (final _Kousei k in kouho) if (k.ryuugakusei) k];
  final List<_Kousei> jp = [for (final _Kousei k in kouho) if (!k.ryuugakusei) k];
  final List<_Kousei?> ku = List<_Kousei?>.filled(7, null);
  // 3kmの区間(最初の1人は7割が2区)
  final List<int> sanKiro = r.nextInt(100) < 70 ? [1, 4] : [4, 1];
  if (ryu.isNotEmpty) {
    final int ryuKukan = r.nextBool() ? 1 : 4; // 留学生は2区か5区
    ku[ryuKukan] = ryu.first;
    sanKiro.remove(ryuKukan);
  }
  final List<_Kousei> erabu = jp.take(ryu.isNotEmpty ? 6 : 7).toList();
  // 中距離出身の選手を、3kmの区間 → 7区・6区の順に
  final List<int> chuuKukan = [...sanKiro, 6, 5];
  final Set<_Kousei> oita = {};
  for (final _Kousei k in erabu) {
    if (k.keireki != 1) continue;
    for (final int kk in chuuKukan) {
      if (ku[kk] == null) {
        ku[kk] = k;
        oita.add(k);
        break;
      }
    }
  }
  // 長距離の選手(と、入りきらなかった中距離出身の選手)を、力の順に空いている区間へ
  for (final _Kousei k in erabu) {
    if (oita.contains(k)) continue;
    for (final int kk in const [0, 2, 3, 6, 5, 1, 4]) {
      if (ku[kk] == null) {
        ku[kk] = k;
        oita.add(k);
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
  // 今の名簿を一度だけ読む(getter の koukouMeibo を、この中だけ同じ名前で置き換える。1.9.5)
  final List<KoukouMei> koukouMeibo = koukouMeiboGenzai();
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

/// 中距離出身になる確率(スパート力とペース変動対応力の平均が高いほど高い。4〜30%。1.9.5)
double _chuukyoriKakuritsu(int spurt, int pace) {
  return (0.06 + 0.0045 * ((spurt + pace) / 2.0 - 20)).clamp(0.04, 0.30).toDouble();
}

/// 経歴を決める(ほかの競技の出身は遅めの選手ほど多く、中距離出身はスピード系の能力が高い選手ほど多い)
int _keirekiKimeru(double t5, int spurt, int pace, Random r) {
  final int x = r.nextInt(100);
  final int hoka = t5 >= 880 ? 8 : (t5 >= 855 ? 3 : 1);
  if (x < hoka) return 2;
  return r.nextDouble() < _chuukyoriKakuritsu(spurt, pace) ? 1 : 0;
}

/// ほかの競技の部活に合った能力(1.9.5。その能力が高い選手ほど、その部活が選ばれやすい)
int _bukatsuNouryoku(SenshuData s, int bukatsu) {
  switch (bukatsu) {
    case 1:
      return s.spurtryoku; // 野球部: 瞬発力
    case 3:
      return s.choukyorinebari; // 水泳部: 心肺の強さ
    case 5:
      return s.noboritekisei; // スキー部(クロスカントリー): 登り
    case 6:
      return s.noborikudarikirikaenouryoku; // ラグビー部: 体の強さ(アップダウン)
    default:
      return s.paceagesagetaiouryoku; // サッカー・バスケットボール・ハンドボール・バドミントン: 止まって走っての繰り返し
  }
}

/// ほかの競技の部活を決める(番号。合った能力が高いほど選ばれやすい)
int _bukatsuKimeru(SenshuData s, Random r) {
  final List<double> omomi = [
    for (int i = 0; i < _hokaKyougi.length; i++) exp((_nouryoku(_bukatsuNouryoku(s, i)) - 50) / 15.0),
  ];
  final double goukei = omomi.fold<double>(0, (a, b) => a + b);
  double x = r.nextDouble() * goukei;
  for (int i = 0; i < omomi.length; i++) {
    x -= omomi[i];
    if (x <= 0) return i;
  }
  return omomi.length - 1;
}

/// 1学年分(その年の高校3年生)を計算して、新入生の高校の情報を決める
/// 戻り値は、選手ごとの新しい情報(選手のidから)
/// [kirokuOut] を渡すと、全国大会の結果(大会の記録に書くもの)を入れて返す(1.9.5)
Map<int, KoukouJouhou> _nendoKeisan(List<SenshuData> shinnyuusei, Random r, [Map<String, dynamic>? kirokuOut]) {
  // 今の名簿を一度だけ読む(getter の koukouMeibo を、この中だけ同じ名前で置き換える。1.9.5)
  final List<KoukouMei> koukouMeibo = koukouMeiboGenzai();
  final Map<int, KoukouJouhou> kekka = {};
  final int kenSuu = LocationDatabase.allPrefectures.length;
  final List<_Kousei> jitsuzai = []; // 走る新入生
  final List<List<_Kousei>> bu = [for (int i = 0; i < koukouMeibo.length; i++) <_Kousei>[]];

  // 大学に来た留学生(1.9.5): 約半分を、留学生のいる高校のどれかの出身にする(その高校の名前のない留学生の代わりに走る)。
  // 残りは日本の高校に通っていない。どちらも経歴を3にして、決めたしるしにする
  final Set<int> ryuugakuseiKoukou = {}; // この年に大学へ来る留学生がいる高校(名前のない留学生を入れない)
  for (final SenshuData s in shinnyuusei) {
    if (s.hirou != 1) continue;
    int koukou = -1;
    if (r.nextDouble() < _ryuugakuseiKoukouWariai) {
      koukou = _ryuugakuseiKoukouErabu(ryuugakuseiKoukou, r);
    }
    if (koukou >= 0) {
      final _Kousei k = _ryuugakuseiKousei(s, r);
      k.koukou = koukou;
      k.ken = koukouMeibo[koukou].ken;
      ryuugakuseiKoukou.add(koukou);
      jitsuzai.add(k);
      bu[koukou].add(k);
    }
    kekka[s.id] = KoukouJouhou(koukou: koukou + 1, keireki: koukouKeirekiRyuugakusei);
  }

  // 新入生の高校と経歴
  for (final SenshuData s in shinnyuusei) {
    if (s.hirou == 1) continue; // 留学生は上で決めた
    int ken = PackedIndexHelper.unpackIndices(s.samusataisei)['prefectureIndex'] ?? -1;
    if (ken < 0 || ken >= kenSuu) ken = r.nextInt(kenSuu);
    final double t5 = s.kiroku_nyuugakuji_5000;
    final bool kirokuAri = t5 > 0 && t5 < 1200;
    final int keireki = kirokuAri ? _keirekiKimeru(t5, s.spurtryoku, s.paceagesagetaiouryoku, r) : 2;
    final _Kousei? k = keireki == 2 ? null : _shinnyuusei(s, keireki);
    int koukou;
    if (k != null) {
      koukou = _koukouErabu(k, ken, r);
      k.koukou = koukou;
      k.ken = koukouMeibo[koukou].ken;
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
    // ほかの競技の出身は、駅伝の区間の欄に部活の番号を入れる
    kekka[s.id] = KoukouJouhou(
      koukou: koukou + 1,
      keireki: keireki,
      ekidenKukan: keireki == 2 ? _bukatsuKimeru(s, r) : 0,
    );
  }

  // 名前のない部員(各校9人)と留学生
  for (int i = 0; i < koukouMeibo.length; i++) {
    for (final int g in const [3, 3, 3, 2, 2, 2, 1, 1, 1]) {
      final _Kousei n = _nanashi(koukouMeibo[i].meimon, g, r);
      n.koukou = i;
      n.ken = koukouMeibo[i].ken;
      bu[i].add(n);
    }
    // 大学に来る留学生がいる高校には、名前のない留学生を入れない(1.9.5)
    if (koukouMeibo[i].ryuugakusei && !ryuugakuseiKoukou.contains(i)) {
      final _Kousei n = _nanashiRyuugakusei(r);
      n.koukou = i;
      n.ken = koukouMeibo[i].ken;
      bu[i].add(n);
    }
  }

  // ---- 全国高校駅伝(都道府県予選 → 全国) ----
  final List<_Team> zenkoku = [];
  final List<List<_Team>> chikuNi = [for (int c = 0; c < koukouChikuMei.length; c++) <_Team>[]];
  final List<int> kenYuushou = []; // 都道府県予選で優勝した名簿の高校(大会の記録の優勝回数。1.9.5)
  for (int ken = 0; ken < kenSuu; ken++) {
    final List<_Team> teams = [];
    for (int i = 0; i < koukouMeibo.length; i++) {
      if (koukouMeibo[i].ken == ken) teams.add(_haichi(i, bu[i], r));
    }
    final int sonota = ken < koukouKenSonota.length ? koukouKenSonota[ken] : 6;
    for (int f = 0; f < sonota; f++) {
      final List<_Kousei> sonotaBu = [for (final int g in const [3, 3, 3, 2, 2, 2, 1, 1, 1]) _nanashi(-1, g, r)];
      for (final _Kousei n in sonotaBu) {
        n.ken = ken;
      }
      teams.add(_haichi(-1, sonotaBu, r));
    }
    final List<List<int>> kj = _ekiden(teams, _yosenKukan, r);
    _ekidenKekka(teams, kj, zenkoku: false);
    zenkoku.add(teams.first);
    if (teams.first.koukou >= 0) kenYuushou.add(teams.first.koukou);
    if (teams.length >= 2 && ken < koukouKenChiku.length) chikuNi[koukouKenChiku[ken]].add(teams[1]);
  }
  // 地区代表(各地区の予選2位の高校のうち、予選のタイムが一番良い高校)
  final Map<_Team, int> chikuDaihyou = {}; // 地区代表の地区の番号(大会の記録に書く。1.9.5)
  for (int c = 0; c < chikuNi.length; c++) {
    if (chikuNi[c].isEmpty) continue;
    chikuNi[c].sort((a, b) => a.goukei.compareTo(b.goukei));
    zenkoku.add(chikuNi[c].first);
    chikuDaihyou[chikuNi[c].first] = c;
  }
  // 全国(予選の区間の並びのまま走る)
  final List<_Team> zenkokuTeams = [];
  final Map<_Team, int> daihyou = {}; // 0は都道府県代表、1〜は地区代表(地区の番号+1)
  for (final _Team t in zenkoku) {
    final _Team z = _Team(t.koukou, t.ku, t.hoketsu);
    daihyou[z] = chikuDaihyou.containsKey(t) ? chikuDaihyou[t]! + 1 : 0;
    zenkokuTeams.add(z);
  }
  final List<List<int>> zkj = _ekiden(zenkokuTeams, _zenkokuKukan, r);
  _ekidenKekka(zenkokuTeams, zkj, zenkoku: true);
  // 大会の記録(1.9.5): 全国の全チームの順位とタイム、各区間の上位3人、都道府県予選の優勝校
  if (kirokuOut != null) {
    kirokuOut['z'] = [
      for (final _Team t in zenkokuTeams)
        <dynamic>[_teamCode(t), daihyou[t] ?? 0, t.goukei.round()],
    ];
    kirokuOut['k'] = [
      for (int kk = 0; kk < _zenkokuKukan.length; kk++)
        [
          for (final _Team t in ([
            for (final _Team t2 in zenkokuTeams)
              if (t2.ku.length > kk) t2,
          ]..sort((a, b) => a.times[kk].compareTo(b.times[kk])))
              .take(3))
            _soushaKiroku(t.ku[kk], t.times[kk]),
        ],
    ];
    kirokuOut['ky'] = kenYuushou;
    // 各チームの走者(1.9.5): 8位までは7人全員、9位以下は大学に入った選手だけ。
    // 選手の後ろに区間(1〜7。補欠は0)を付ける。大学に入った補欠も入れる
    kirokuOut['m'] = [
      for (int j = 0; j < zenkokuTeams.length; j++)
        [
          for (int kk = 0; kk < zenkokuTeams[j].ku.length; kk++)
            if (j < 8 || zenkokuTeams[j].ku[kk].s != null)
              [..._soushaKiroku(zenkokuTeams[j].ku[kk], zenkokuTeams[j].times[kk]), kk + 1],
          for (final _Kousei h in zenkokuTeams[j].hoketsu)
            if (h.s != null) [..._soushaKiroku(h, 0), 0],
        ],
    ];
  }

  // ---- 高校総体(県大会 → 地区大会 → 全国大会) ----
  // 種目(1.9.5): 中距離出身は1500m。長距離の選手は、障害への向きが高いほど3000m障害(全体で約15%)、
  // ペース変動対応力が高いほど1500m(約15%)、ほかは5000m。留学生は5000mか障害。
  // 各校の上位2人(持ちタイムの順)は掛け持ちする(中距離出身は5000mにも、5000mの選手でペース変動対応力が
  // 50以上なら1500mにも、障害の選手は5000mにも)。1校1種目3人までを、見込みのタイムの順に選び、
  // どの種目にも入れなかった選手は、空いている種目に回す
  final List<List<List<_Kousei>>> kenEntry = [
    for (int ken = 0; ken < kenSuu; ken++) [<_Kousei>[], <_Kousei>[], <_Kousei>[], <_Kousei>[]],
  ];
  for (int i = 0; i < koukouMeibo.length; i++) {
    final int ken = koukouMeibo[i].ken;
    if (ken < 0 || ken >= kenSuu) continue;
    final List<List<_Kousei>> kouhoSh = [<_Kousei>[], <_Kousei>[], <_Kousei>[], <_Kousei>[]];
    final Map<_Kousei, int> honmei = {};
    for (final _Kousei k in bu[i]) {
      final int sh = _shumokuErabu(k, r);
      honmei[k] = sh;
      kouhoSh[sh].add(k);
    }
    // 掛け持ち(各校の上位2人)
    final List<_Kousei> ue = [for (final _Kousei k in bu[i]) if (!k.ryuugakusei) k]
      ..sort((a, b) => a.t5.compareTo(b.t5));
    for (final _Kousei k in ue.take(2)) {
      final int sh = honmei[k] ?? 2;
      if (k.keireki == 1) {
        kouhoSh[2].add(k);
      } else if (sh == 2 && k.pace >= 50) {
        kouhoSh[1].add(k);
      } else if (sh == 3) {
        kouhoSh[2].add(k);
      }
    }
    // 1校1種目3人まで(見込みのタイムの順)
    final List<List<_Kousei>> erabu = [<_Kousei>[], <_Kousei>[], <_Kousei>[], <_Kousei>[]];
    final Set<_Kousei> deru = {};
    for (int sh = 1; sh <= 3; sh++) {
      final List<_Kousei> l = List<_Kousei>.of(kouhoSh[sh])
        ..sort((a, b) => _trackMikomi(a, sh).compareTo(_trackMikomi(b, sh)));
      for (final _Kousei k in l.take(3)) {
        erabu[sh].add(k);
        deru.add(k);
      }
    }
    // どの種目にも入れなかった選手は、空いている種目へ(本命が1500mなら5000m→障害、5000mなら障害→1500m、障害なら5000m→1500m)
    for (final _Kousei k in bu[i]) {
      if (deru.contains(k)) continue;
      final int sh = honmei[k] ?? 2;
      final List<int> tsugi = sh == 1 ? const [2, 3] : (sh == 2 ? const [3, 1] : const [2, 1]);
      for (final int s2 in tsugi) {
        if (erabu[s2].length < 3) {
          erabu[s2].add(k);
          deru.add(k);
          break;
        }
      }
    }
    for (int sh = 1; sh <= 3; sh++) {
      kenEntry[ken][sh].addAll(erabu[sh]);
    }
  }
  for (int ken = 0; ken < kenSuu; ken++) {
    final int sonota = ken < koukouKenSonota.length ? koukouKenSonota[ken] : 6;
    for (int sh = 1; sh <= 3; sh++) {
      for (int f = 0; f < sonota; f++) {
        final _Kousei n = _nanashi(-1, 3, r);
        n.ken = ken;
        kenEntry[ken][sh].add(n);
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
    final List<MapEntry<_Kousei, double>> finTime = _trackKiroku(kesshou, sh, r);
    final List<_Kousei> fin = [for (final MapEntry<_Kousei, double> e in finTime) e.key];
    for (int j = 0; j < fin.length; j++) {
      _soutaiKaku(fin[j], sh, 3, j);
    }
    // 大会の記録(1.9.5): 決勝の全員の順位とタイム(種目の番号-1の順)
    if (kirokuOut != null) {
      final List<dynamic> s = (kirokuOut['s'] as List<dynamic>?) ?? <dynamic>[];
      s.add([for (final MapEntry<_Kousei, double> e in finTime) _soushaKiroku(e.key, e.value)]);
      kirokuOut['s'] = s;
    }
  }

  // 結果をまとめる(高校総体は、掛け持ちした種目のうち一番良いもの: 段階が上、同じなら順位が上)
  for (final _Kousei k in jitsuzai) {
    final SenshuData? s = k.s;
    if (s == null) continue;
    final KoukouJouhou? mae = kekka[s.id];
    if (mae == null) continue;
    int sShumoku = 0;
    int sDankai = 0;
    int sJuni = 0;
    int sTen = -1;
    for (int sh = 1; sh <= 3; sh++) {
      if (k.sDankai[sh] < 0) continue;
      final int ten = k.sDankai[sh] * 100 + (k.sJuni[sh] >= 1 ? 16 - k.sJuni[sh] : 0);
      if (ten > sTen) {
        sTen = ten;
        sShumoku = sh;
        sDankai = k.sDankai[sh];
        sJuni = k.sJuni[sh];
      }
    }
    kekka[s.id] = KoukouJouhou(
      koukou: mae.koukou,
      keireki: mae.keireki,
      ekidenZenkoku: k.ekidenZenkoku,
      ekidenKukan: k.ekidenAri ? k.ekidenKukan : 0,
      ekidenKukanJuni: k.ekidenAri ? k.ekidenKukanJuni : 0,
      ekidenJuni: k.ekidenAri ? k.ekidenJuni : 0,
      soutaiShumoku: sShumoku,
      soutaiDankai: sDankai,
      soutaiJuni: sJuni,
    );
  }
  return kekka;
}

/// トラックのレースを走らせて、着順に並べる
List<_Kousei> _track(List<_Kousei> sousha, int sh, Random r) {
  return [for (final MapEntry<_Kousei, double> e in _trackKiroku(sousha, sh, r)) e.key];
}

/// トラックのレースを走らせて、着順に並べる(タイムつき。1.9.5)
List<MapEntry<_Kousei, double>> _trackKiroku(List<_Kousei> sousha, int sh, Random r) {
  return [
    for (final _Kousei k in sousha) MapEntry(k, _trackTime(k, sh, r)),
  ]..sort((a, b) => a.value.compareTo(b.value));
}

/// 高校総体の結果を新入生に書く(種目ごとに、段階が上がったときだけ上書き)。[juni0] 0が1位、-1は順位なし
void _soutaiKaku(_Kousei k, int sh, int dankai, int juni0) {
  if (k.s == null || sh < 1 || sh > 3) return;
  if (dankai < k.sDankai[sh]) return;
  k.sDankai[sh] = dankai;
  k.sJuni[sh] = (juni0 >= 0 && juni0 < 15) ? juni0 + 1 : 0;
}

/// 高校総体の本命の種目を選ぶ(1=1500m・2=5000m・3=3000m障害。1.9.5)
/// 中距離出身は1500m。長距離の選手は、障害への向きが高いほど障害、ペース変動対応力が高いほど1500m
int _shumokuErabu(_Kousei k, Random r) {
  if (k.ryuugakusei) return r.nextInt(100) < 70 ? 2 : 3;
  if (k.keireki == 1) return 1;
  final double pShougai = (0.15 + 0.006 * (_shougaiMuki(k) - 50)).clamp(0.03, 0.40).toDouble();
  final double p1500 = (0.15 + 0.004 * (k.pace - 35)).clamp(0.03, 0.35).toDouble();
  final double x = r.nextDouble();
  if (x < pShougai) return 3;
  if (x < pShougai + p1500) return 1;
  return 2;
}

/// 高校が未設定の選手に、出身校と高校時代の実績を付けて保存する(学年ごとにまとめて計算)。
/// 日本人選手は高校が0のとき、留学生は経歴が3(決めたしるし)でないときに決める(1.9.5)。
/// 起動時・セーブデータの読み込み時・年度替わり(新入生の所属先が決まったあと)・新しいゲームの開始時に呼ぶ。
/// 付けた人数を返す(未設定の選手がいなければ何もしない)
/// ゲームの計算には使わない飾りの処理なので、エラーが起きても止めずにログに出すだけにする(1.9.5。
/// 起動時はアプリの画面を出す前に呼ぶので、ここで例外を出すとスプラッシュ画面から進まなくなる)
Future<int> koukouJouhouFuyo() async {
  try {
    return await _koukouJouhouFuyoHontai();
  } catch (e, st) {
    print('出身校と高校時代の実績の計算でエラー(ゲームはそのまま続ける): $e\n$st');
    return 0;
  }
}

Future<int> _koukouJouhouFuyoHontai() async {
  if (!Hive.isBoxOpen('senshuBox')) return 0;
  // 出場回数を足す前に作った大会の記録があれば、そこから数え直す(1.9.5)
  await _shutsujouIkou();
  final Box<SenshuData> box = Hive.box<SenshuData>('senshuBox');
  final Map<int, List<SenshuData>> gakunenGoto = {};
  for (final SenshuData s in box.values) {
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (s.hirou == 1) {
      if (j.keireki == koukouKeirekiRyuugakusei) continue; // 留学生は決めたあと
    } else {
      if (j.koukou != 0) continue;
    }
    gakunenGoto.putIfAbsent(s.gakunen, () => <SenshuData>[]).add(s);
  }
  if (gakunenGoto.isEmpty) return 0;
  final Random r = Random();
  final int? nendo = _imaNoNendo();
  int kazu = 0;
  // 上の学年(古い世代)から順に計算する(大会の記録の連続出場を、年の順に数えるため。1.9.5)
  final List<int> gakunenJun = gakunenGoto.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final int gakunen in gakunenJun) {
    final List<SenshuData> list = gakunenGoto[gakunen]!;
    // 日本人の選手を新しく決める学年だけ、大会の記録に残す(1.9.5。留学生だけを決め直すときは、
    // 日本人の選手の実績を前に別の計算で決めているので、食い違わないように残さない)
    final Map<String, dynamic>? kiroku = list.any((s) => s.hirou != 1) ? <String, dynamic>{} : null;
    final Map<int, KoukouJouhou> kekka = _nendoKeisan(list, r, kiroku);
    for (final SenshuData s in list) {
      final KoukouJouhou? j = kekka[s.id];
      if (j == null) continue;
      s.samusataisei = j.kakikomi(s.samusataisei);
      await s.save();
      kazu++;
    }
    // この学年が大学に入った年度(1年生なら今年度、2年生なら1年前…)
    if (kiroku != null && nendo != null) await _kirokuHozon(nendo - (gakunen - 1), kiroku);
  }
  print('出身校と高校時代の実績を付けた選手: $kazu人'); // 確認用(1.9.5)
  return kazu;
}

// ------------------------------------------------------------
// 高校の大会の記録と優勝回数(1.9.5。高校名鑑の「大会の記録」タブ)
//
// ・毎年の計算(koukouJouhouFuyo)で、全国高校駅伝の全チームの順位とタイム(都道府県代表か地区代表か)、
//   各区間の上位3人、高校総体3種目の決勝の全員を、直近10回分残す。都道府県予選と地区大会は残さない
// ・高校ごとの優勝回数(全国高校駅伝・都道府県予選)は、記録を残し始めてからの回数を数える
// ・保存場所は UnivData.name_tanshuku(短縮名は使っていない。meisei_rireki.dart と同じやり方)。
//   大学id 28 に大会の記録、29 に優勝回数。1行目は見出し、2行目からはJSON
//   ・大会の記録: [{y: 大学に入った年度, z: [[高校の番号, 代表(0都道府県・1〜地区の番号+1), タイム(秒)]...(着順)],
//     k: [区間ごとに[選手...](上位3人)], s: [種目ごとに[選手...](決勝の着順)]}...](新しい順)
//     選手 = [種類(0大学に入った日本人・1大学に入った留学生・2名前のない日本人・3名前のない留学生),
//            大学id, 学年, 名前, 高校の番号, タイム(0.1秒), 選手のid]
//     高校の番号は名簿の番号、その他の高校は1000+都道府県の番号
//   ・優勝回数: {z: [全国高校駅伝の優勝回数(名簿の並び)], k: [都道府県予選の優勝回数]}
// ・大学に入った選手の大学は、見るときに選手のidと名前が合えば今の大学を出す(スカウトで変わるため)。
//   卒業した選手は、毎年の保存のときに直した大学を出す(_kirokuHozon)
// ・新しいゲームの開始時に消す(ShokitiUnivdata.dart。年が1から始まり直すため)
// ------------------------------------------------------------

const int _kirokuUnivId = 28;
const int _kaisuuUnivId = 29;
const int _kirokuHozonSuu = 10;
const String _kirokuMidashi = '#高校の大会の記録';
const String _kaisuuMidashi = '#高校の優勝回数';

// ------------------------------------------------------------
// 高校の名簿の編集(1.9.5。高校名鑑の「都道府県別」で高校を押して変える)
// ・変えた高校の分だけ、優勝回数と同じところ(大学id 29)のJSONの h に
//   {"高校の番号": [校名, 都道府県の番号, 名門度, 留学生(0/1), 色, 紹介文]} で保存する
// ・koukouMeibo(getter)は、初期値(koukou_meibo.dart の koukouMeiboShoki)に変えた分を重ねた今の名簿。
//   保存してある文字列が変わったとき(編集・セーブデータの読み込み)だけ作り直す
// ・高校の数は変えられない(番号で覚えているため)。新しいゲームを始めても、変えた分は残す
// ・校名の変更は、在学中の選手の出身校や大会の記録にもそのまま出る。都道府県・名門度・色・留学生は、
//   次の新入生の計算から効く(今の選手の実績は変えない)
// ------------------------------------------------------------

List<KoukouMei>? _meiboCache;
String? _meiboCacheMoto;

/// 今の高校の名簿(初期値に、高校名鑑で変えた分を重ねたもの。1.9.5)
List<KoukouMei> get koukouMeibo => koukouMeiboGenzai();

/// 今の高校の名簿(初期値に、高校名鑑で変えた分を重ねたもの。1.9.5)
List<KoukouMei> koukouMeiboGenzai() {
  final UnivData? u = _kirokuUniv(_kaisuuUnivId);
  final String moto = u?.name_tanshuku ?? '';
  final List<KoukouMei>? c = _meiboCache;
  if (c != null && identical(moto, _meiboCacheMoto)) return c;
  final Map<int, KoukouMei> h = _henkouYomu(_kaisuuJsonKaidoku(moto));
  final List<KoukouMei> l = [
    for (int i = 0; i < koukouMeiboShoki.length; i++) h[i] ?? koukouMeiboShoki[i],
  ];
  _meiboCache = l;
  _meiboCacheMoto = moto;
  return l;
}

Map<int, KoukouMei> _henkouYomu(Map<String, dynamic> d) {
  final Map<int, KoukouMei> kekka = {};
  final dynamic h = d['h'];
  if (h is! Map) return kekka;
  for (final MapEntry<dynamic, dynamic> e in h.entries) {
    final int? i = int.tryParse('${e.key}');
    final dynamic v = e.value;
    if (i == null || i < 0 || i >= koukouMeiboShoki.length) continue;
    if (v is! List || v.length < 6) continue;
    final KoukouMei moto = koukouMeiboShoki[i];
    final String mei = v[0] is String && (v[0] as String).trim().isNotEmpty ? (v[0] as String).trim() : moto.mei;
    final int ken = v[1] is num ? (v[1] as num).toInt().clamp(0, LocationDatabase.allPrefectures.length - 1).toInt() : moto.ken;
    final int meimon = v[2] is num ? (v[2] as num).toInt().clamp(0, 3).toInt() : moto.meimon;
    final bool ryuu = v[3] is num ? (v[3] as num).toInt() == 1 : moto.ryuugakusei;
    final int iro = v[4] is num ? (v[4] as num).toInt().clamp(0, 2).toInt() : moto.iro;
    final String shoukai = v[5] is String ? v[5] as String : moto.shoukai;
    kekka[i] = KoukouMei(mei, ken, meimon, ryuu, iro, shoukai: shoukai);
  }
  return kekka;
}

/// 高校[i]を変えたか
bool koukouHenkouAri(int i) => _henkouYomu(_kaisuuJsonYomu()).containsKey(i);

/// 高校[i]を[m]に変えて保存する([m]がnullか、初期値と同じなら元に戻す)
Future<void> koukouHenkouHozon(int i, KoukouMei? m) async {
  if (i < 0 || i >= koukouMeiboShoki.length) return;
  final Map<String, dynamic> d = _kaisuuJsonYomu();
  final Map<String, dynamic> h = d['h'] is Map ? Map<String, dynamic>.from(d['h'] as Map) : <String, dynamic>{};
  final KoukouMei moto = koukouMeiboShoki[i];
  final bool onaji = m == null ||
      (m.mei == moto.mei &&
          m.ken == moto.ken &&
          m.meimon == moto.meimon &&
          m.ryuugakusei == moto.ryuugakusei &&
          m.iro == moto.iro &&
          m.shoukai == moto.shoukai);
  if (onaji || m == null) {
    h.remove('$i');
  } else {
    h['$i'] = [m.mei, m.ken, m.meimon, m.ryuugakusei ? 1 : 0, m.iro, m.shoukai];
  }
  if (h.isEmpty) {
    d.remove('h');
  } else {
    d['h'] = h;
  }
  await _kaisuuJsonKaku(d);
}

/// 高校の名簿を、すべて初期値に戻す
Future<void> koukouHenkouZenbuModosu() async {
  final Map<String, dynamic> d = _kaisuuJsonYomu();
  d.remove('h');
  await _kaisuuJsonKaku(d);
}

/// 大学id 29 のJSON(優勝回数と名簿の編集)を読む(読めなければ空)
Map<String, dynamic> _kaisuuJsonYomu() {
  final UnivData? u = _kirokuUniv(_kaisuuUnivId);
  return u == null ? <String, dynamic>{} : _kaisuuJsonKaidoku(u.name_tanshuku);
}

Map<String, dynamic> _kaisuuJsonKaidoku(String t) {
  if (!t.startsWith(_kaisuuMidashi)) return <String, dynamic>{};
  try {
    final dynamic d = jsonDecode(t.substring(_kaisuuMidashi.length).trim());
    if (d is Map) return Map<String, dynamic>.from(d);
  } catch (_) {}
  return <String, dynamic>{};
}

Future<void> _kaisuuJsonKaku(Map<String, dynamic> d) async {
  final UnivData? u = _kirokuUniv(_kaisuuUnivId);
  if (u == null) return;
  u.name_tanshuku = d.isEmpty ? '' : '$_kaisuuMidashi\n${jsonEncode(d)}';
  await u.save();
}

/// 今の年度(4月から翌年3月まで。年の数は4月の年)
int? _imaNoNendo() {
  if (!Hive.isBoxOpen('ghensuuBox')) return null;
  final Box<Ghensuu> b = Hive.box<Ghensuu>('ghensuuBox');
  if (b.isEmpty) return null;
  final Ghensuu? g = b.getAt(0);
  if (g == null) return null;
  return g.month >= 4 ? g.year : g.year - 1;
}

UnivData? _kirokuUniv(int id) {
  if (!Hive.isBoxOpen('univBox')) return null;
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == id) return u;
  }
  return null;
}

/// 大会の記録の高校の番号(名簿の高校は番号、その他の高校は1000+都道府県の番号)
int _kouCode(int koukou, int ken) => koukou >= 0 ? koukou : 1000 + (ken < 0 ? 0 : ken);

int _teamCode(_Team t) => _kouCode(t.koukou, t.ku.isNotEmpty ? t.ku.first.ken : -1);

/// 大会の記録の選手1人
List<dynamic> _soushaKiroku(_Kousei k, double time) {
  final SenshuData? s = k.s;
  return [
    s == null ? (k.ryuugakusei ? 3 : 2) : (s.hirou == 1 ? 1 : 0),
    s?.univid ?? -1,
    s == null ? k.gakunen : 3,
    s?.name ?? '',
    _kouCode(k.koukou, k.ken),
    (time * 10).round(),
    s?.id ?? -1,
  ];
}

/// 保存してある大会の記録(JSONのまま。読めなければ空)
List<dynamic> _kirokuYomuMoto() {
  final UnivData? u = _kirokuUniv(_kirokuUnivId);
  if (u == null || !u.name_tanshuku.startsWith(_kirokuMidashi)) return [];
  try {
    final dynamic d = jsonDecode(u.name_tanshuku.substring(_kirokuMidashi.length).trim());
    if (d is List) return d;
  } catch (_) {}
  return [];
}

int _kirokuNen(dynamic d) => (d is Map && d['y'] is num) ? (d['y'] as num).toInt() : -99999;

/// 1世代分の大会の記録を残し、優勝回数を足す(その世代の記録がもうあれば何もしない)
Future<void> _kirokuHozon(int nyuugakuNendo, Map<String, dynamic> kiroku) async {
  final UnivData? u = _kirokuUniv(_kirokuUnivId);
  final UnivData? uk = _kirokuUniv(_kaisuuUnivId);
  if (u == null || uk == null) return;
  final List<dynamic> mae = _kirokuYomuMoto();
  for (final dynamic d in mae) {
    if (_kirokuNen(d) == nyuugakuNendo) return;
  }
  // 在学中の選手の大学を、今の大学に直しておく(卒業したあとも、最後の大学が出るように)
  final Map<int, SenshuData> zaigaku = {};
  if (Hive.isBoxOpen('senshuBox')) {
    for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
      zaigaku[s.id] = s;
    }
  }
  void naosu(dynamic sousha) {
    if (sousha is! List || sousha.length < 7) return;
    final dynamic id = sousha[6];
    if (id is! num) return;
    final SenshuData? s = zaigaku[id.toInt()];
    if (s != null && s.name == sousha[3]) sousha[1] = s.univid;
  }
  for (final dynamic d in mae) {
    if (d is! Map) continue;
    for (final String kagi in const ['k', 's', 'm']) {
      final dynamic l = d[kagi];
      if (l is! List) continue;
      for (final dynamic g in l) {
        if (g is! List) continue;
        for (final dynamic sousha in g) {
          naosu(sousha);
        }
      }
    }
  }
  // 全国高校駅伝の出場回数・連続出場を進め、この回の各チームに回数目と連続を書き足す(1.9.5)
  final Map<String, dynamic> kaisuuJson = _kaisuuJsonYomu();
  final List<int> shutsujou = _kaisuuList(kaisuuJson, 'd', 0);
  final List<int> renzoku = _kaisuuList(kaisuuJson, 'rn', 0);
  final List<int> saigo = _kaisuuList(kaisuuJson, 'ln', _mishutsujou);
  final dynamic zKonkai = kiroku['z'];
  if (zKonkai is List) _shutsujouSusumeru(nyuugakuNendo, zKonkai, shutsujou, renzoku, saigo);
  final List<dynamic> l = [
    {
      'y': nyuugakuNendo,
      'z': kiroku['z'] ?? [],
      'k': kiroku['k'] ?? [],
      's': kiroku['s'] ?? [],
      'm': kiroku['m'] ?? [],
    },
    ...mae,
  ]..sort((a, b) => _kirokuNen(b).compareTo(_kirokuNen(a)));
  u.name_tanshuku = '$_kirokuMidashi\n${jsonEncode(l.take(_kirokuHozonSuu).toList())}';
  await u.save();
  // 優勝回数
  final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
  final dynamic z = kiroku['z'];
  if (z is List && z.isNotEmpty && z.first is List && (z.first as List).isNotEmpty) {
    final dynamic code = (z.first as List).first;
    if (code is num && code.toInt() >= 0 && code.toInt() < kai.zenkoku.length) kai.zenkoku[code.toInt()]++;
  }
  final dynamic ky = kiroku['ky'];
  if (ky is List) {
    for (final dynamic code in ky) {
      if (code is num && code.toInt() >= 0 && code.toInt() < kai.ken.length) kai.ken[code.toInt()]++;
    }
  }
  // 名簿の編集(h)はそのまま残す
  kaisuuJson['z'] = kai.zenkoku;
  kaisuuJson['k'] = kai.ken;
  kaisuuJson['d'] = shutsujou;
  kaisuuJson['rn'] = renzoku;
  kaisuuJson['ln'] = saigo;
  await _kaisuuJsonKaku(kaisuuJson);
}

/// まだ全国高校駅伝に出ていない高校の、最後に出た年度
const int _mishutsujou = -99999;

/// 大学id 29 のJSONの、高校ごとの数の一覧(名簿の並び。なければ[shoki])
List<int> _kaisuuList(Map<String, dynamic> kaisuuJson, String kagi, int shoki) {
  final List<int> l = List<int>.filled(koukouMeiboShoki.length, shoki);
  final dynamic v = kaisuuJson[kagi];
  if (v is List) {
    for (int i = 0; i < l.length && i < v.length; i++) {
      if (v[i] is num) l[i] = (v[i] as num).toInt();
    }
  }
  return l;
}

/// 全国高校駅伝の1回分の出場校で、出場回数・連続出場・最後に出た年度を進める(1.9.5)
/// [teams] はその回の z(着順の[高校の番号, 代表, タイム])。各チームの後ろに、その時点の回数目と連続を書き足す
void _shutsujouSusumeru(int nendo, List<dynamic> teams, List<int> shutsujou, List<int> renzoku, List<int> saigo) {
  for (final dynamic t in teams) {
    if (t is! List || t.length < 3 || t.first is! num) continue;
    final int code = (t.first as num).toInt();
    if (code < 0 || code >= shutsujou.length) continue;
    shutsujou[code]++;
    renzoku[code] = (saigo[code] == nendo - 1 && renzoku[code] > 0) ? renzoku[code] + 1 : 1;
    saigo[code] = nendo;
    // t は数だけの一覧(List<int>)のこともあるので、1つずつ足す(型の決まらない一覧を addAll すると型のエラーになる)
    t.removeRange(3, t.length);
    t.add(shutsujou[code]);
    t.add(renzoku[code]);
  }
}

/// 出場回数がまだないデータで、残っている大会の記録から数え直す(1.9.5。出場回数を足す前に作った記録のため)
/// 記録の各チームにも、回数目と連続を書き足して保存する
Future<void> _shutsujouIkou() async {
  final Map<String, dynamic> kaisuuJson = _kaisuuJsonYomu();
  if (kaisuuJson['d'] is List) return;
  final List<dynamic> kiroku = _kirokuYomuMoto();
  if (kiroku.isEmpty) return;
  final List<int> shutsujou = List<int>.filled(koukouMeiboShoki.length, 0);
  final List<int> renzoku = List<int>.filled(koukouMeiboShoki.length, 0);
  final List<int> saigo = List<int>.filled(koukouMeiboShoki.length, _mishutsujou);
  final List<dynamic> furuiJun = List<dynamic>.of(kiroku)..sort((a, b) => _kirokuNen(a).compareTo(_kirokuNen(b)));
  for (final dynamic r in furuiJun) {
    if (r is! Map) continue;
    final dynamic z = r['z'];
    if (z is List) _shutsujouSusumeru(_kirokuNen(r), z, shutsujou, renzoku, saigo);
  }
  final UnivData? u = _kirokuUniv(_kirokuUnivId);
  if (u != null) {
    u.name_tanshuku = '$_kirokuMidashi\n${jsonEncode(kiroku)}';
    await u.save();
  }
  kaisuuJson['d'] = shutsujou;
  kaisuuJson['rn'] = renzoku;
  kaisuuJson['ln'] = saigo;
  await _kaisuuJsonKaku(kaisuuJson);
}

/// 大会の記録と優勝回数を消す(新しいゲームの開始時。名簿の編集は残す)
/// エラーが起きても、新しいゲームの処理を止めない
Future<void> koukouKirokuZenbuKesu() async {
  try {
    final UnivData? u = _kirokuUniv(_kirokuUnivId);
    if (u != null) {
      u.name_tanshuku = '';
      await u.save();
    }
    final Map<String, dynamic> d = _kaisuuJsonYomu();
    for (final String kagi in const ['z', 'k', 'd', 'rn', 'ln']) {
      d.remove(kagi);
    }
    await _kaisuuJsonKaku(d);
  } catch (e) {
    print('高校の大会の記録を消すところでエラー(ゲームはそのまま続ける): $e');
  }
}

/// 大会の記録の選手1人(画面用)
class KoukouKirokuSousha {
  /// 0大学に入った日本人 1大学に入った留学生 2名前のない日本人 3名前のない留学生
  final int shurui;
  final int univid;
  final int gakunen;
  final String name;
  final int kouCode;

  /// タイム(秒)
  final double time;
  final int id;

  /// 走った区間(1〜7。補欠や区間のない記録は0。チームの走者のとき)
  final int kukan;

  const KoukouKirokuSousha({
    required this.shurui,
    required this.univid,
    required this.gakunen,
    required this.name,
    required this.kouCode,
    required this.time,
    required this.id,
    this.kukan = 0,
  });

  bool get namaeAri => shurui <= 1;
}

/// 大会の記録の全国高校駅伝の1チーム(画面用)
class KoukouKirokuTeam {
  final int kouCode;

  /// 0は都道府県代表、1〜は地区代表(地区の番号+1)
  final int daihyou;

  /// タイム(秒)
  final double time;

  /// 走者(8位までは7人全員、9位以下は大学に入った選手だけ。大学に入った補欠も入る。
  /// 走者を残す前の記録はnull)
  final List<KoukouKirokuSousha>? member;

  /// その時点の出場の回数目と、連続出場の年数(記録を残し始めてから。分からなければ0)
  final int kaime;
  final int renzoku;

  const KoukouKirokuTeam(this.kouCode, this.daihyou, this.time, {this.member, this.kaime = 0, this.renzoku = 0});
}

/// 1世代分の大会の記録(画面用)
class KoukouTaikaiKiroku {
  /// この世代が大学に入った年度
  final int nyuugakuNendo;

  /// 全国高校駅伝(着順)
  final List<KoukouKirokuTeam> zenkoku;

  /// 区間ごとの上位3人
  final List<List<KoukouKirokuSousha>> kukan;

  /// 高校総体の種目ごとの決勝(着順。0=1500m・1=5000m・2=3000m障害)
  final List<List<KoukouKirokuSousha>> soutai;

  const KoukouTaikaiKiroku(this.nyuugakuNendo, this.zenkoku, this.kukan, this.soutai);
}

KoukouKirokuSousha? _soushaYomu(dynamic a) {
  if (a is! List || a.length < 6) return null;
  return KoukouKirokuSousha(
    shurui: (a[0] as num).toInt(),
    univid: (a[1] as num).toInt(),
    gakunen: (a[2] as num).toInt(),
    name: a[3] is String ? a[3] as String : '',
    kouCode: (a[4] as num).toInt(),
    time: (a[5] as num).toDouble() / 10.0,
    id: a.length >= 7 && a[6] is num ? (a[6] as num).toInt() : -1,
    kukan: a.length >= 8 && a[7] is num ? (a[7] as num).toInt() : 0,
  );
}

List<List<KoukouKirokuSousha>> _soushaListYomu(dynamic l) {
  if (l is! List) return [];
  return [
    for (final dynamic g in l)
      if (g is List)
        [
          for (final dynamic a in g)
            if (_soushaYomu(a) != null) _soushaYomu(a)!,
        ],
  ];
}

/// 保存してある大会の記録(新しい順。なければ空)
List<KoukouTaikaiKiroku> koukouTaikaiKirokuYomu() {
  final List<KoukouTaikaiKiroku> l = [];
  for (final dynamic d in _kirokuYomuMoto()) {
    if (d is! Map) continue;
    try {
      final dynamic z = d['z'];
      // 各チームの走者(1.9.5。z と同じ並び。走者を残す前の記録にはない)
      final List<List<KoukouKirokuSousha>> m = _soushaListYomu(d['m']);
      final List<KoukouKirokuTeam> teams = [];
      if (z is List) {
        for (int j = 0; j < z.length; j++) {
          final dynamic t = z[j];
          if (t is! List || t.length < 3) continue;
          teams.add(
            KoukouKirokuTeam(
              (t[0] as num).toInt(),
              (t[1] as num).toInt(),
              (t[2] as num).toDouble(),
              member: j < m.length ? m[j] : null,
              kaime: t.length >= 5 && t[3] is num ? (t[3] as num).toInt() : 0,
              renzoku: t.length >= 5 && t[4] is num ? (t[4] as num).toInt() : 0,
            ),
          );
        }
      }
      l.add(
        KoukouTaikaiKiroku(
          _kirokuNen(d),
          teams,
          _soushaListYomu(d['k']),
          _soushaListYomu(d['s']),
        ),
      );
    } catch (_) {}
  }
  l.sort((a, b) => b.nyuugakuNendo.compareTo(a.nyuugakuNendo));
  return l;
}

/// 高校ごとの優勝回数(名簿の並び)
class KoukouYuushouKaisuu {
  /// 全国高校駅伝
  final List<int> zenkoku;

  /// 都道府県予選
  final List<int> ken;

  /// 全国高校駅伝の出場回数(1.9.5)
  final List<int> shutsujou;

  const KoukouYuushouKaisuu(this.zenkoku, this.ken, this.shutsujou);
}

/// 保存してある優勝回数(記録を残し始めてからの回数。なければ全部0)
KoukouYuushouKaisuu koukouYuushouKaisuuYomu() {
  final List<int> z = List<int>.filled(koukouMeiboShoki.length, 0);
  final List<int> k = List<int>.filled(koukouMeiboShoki.length, 0);
  final Map<String, dynamic> d = _kaisuuJsonYomu();
  final dynamic dz = d['z'];
  final dynamic dk = d['k'];
  if (dz is List) {
    for (int i = 0; i < z.length && i < dz.length; i++) {
      if (dz[i] is num) z[i] = (dz[i] as num).toInt();
    }
  }
  if (dk is List) {
    for (int i = 0; i < k.length && i < dk.length; i++) {
      if (dk[i] is num) k[i] = (dk[i] as num).toInt();
    }
  }
  return KoukouYuushouKaisuu(z, k, _kaisuuList(d, 'd', 0));
}

/// 大会の記録の高校の名前(「天馬学園高(栃木)」。その他の高校は「栃木県の高校」)
String koukouCodeMei(int code) {
  if (code >= 0 && code < koukouMeibo.length) {
    final KoukouMei m = koukouMeibo[code];
    return '${m.mei}高(${_kenMijikai(m.ken)})';
  }
  final int ken = code - 1000;
  if (ken >= 0 && ken < LocationDatabase.allPrefectures.length) return '${LocationDatabase.allPrefectures[ken]}の高校';
  return '高校';
}

/// 全国高校駅伝の区間の距離(m)
double koukouZenkokuKukanKyori(int kk) => (kk >= 0 && kk < _zenkokuKukan.length) ? _zenkokuKukan[kk].kyori : 0;
