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
//   高校総体の優勝(簡単な試算の中央): 1500mは3分48秒前後、3000m障害は8分49秒前後(留学生を含む)。
//   5000mは持ちタイムより速くならない(_trackTime)。
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

  /// 名前のない高校生の、大会の記録の中だけの番号(-2から下へ。その回の記録の中で同じ選手を見分ける。
  /// 翌年以降の新入生に引き継いだときに、記録のその選手に名前を付けるのに使う。1.9.5)
  int kirokuId = -1;

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
/// 1500mは駅伝の区間と同じ換算(距離の比の1.06乗)。3000m障害は、障害の分を11.5%遅くする
/// (実際のインターハイの優勝タイム(1500mの日本人の優勝は3分41〜51秒、障害は8分21秒〜9分04秒)に合わせた。1.9.5)
double _trackMikomi(_Kousei k, int shumoku) {
  double t;
  if (shumoku == 1) {
    t = k.t5 * pow(0.3, 1.06).toDouble() * (k.keireki == 1 ? 0.98 : 1.0);
    t += -0.3265 * 0.15 * (k.spurt - 50);
  } else if (shumoku == 3) {
    t = k.t5 * pow(0.6, 1.06).toDouble() * 1.115;
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
/// 5000mは、入学時の持ちタイム(自己ベスト)より速くならない(1.9.5)。速くなりそうなときは、
/// 速くなりそうだった分だけ(0.1〜3秒)持ちタイムより遅くする(持ちタイムに迫る走り。同じタイムに集まらないように。
/// 記録は0.1秒に丸めて残すので、0.1秒は空ける)。
/// 持ちタイムが画面に出ない名前のない選手と留学生も、内部の持ちタイムで同じにする(誰かだけが得をしないように)
double _trackTime(_Kousei k, int shumoku, Random r) {
  double t = _trackMikomi(k, shumoku);
  t *= 1.0 + _gauss(r) * 0.011;
  if (r.nextInt(100) < 8) t *= 1.02 + r.nextDouble() * 0.04; // 暑さで崩れる
  if (shumoku == 2 && t < k.t5 + 0.1) t = k.t5 + 0.1 + min(2.9, max(0.0, k.t5 - t));
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

/// 並べる前のチームの順(同じタイムのときの最後の決め手。1.9.5)
Map<_Team, int> _motoJun(List<_Team> teams) => {for (int i = 0; i < teams.length; i++) teams[i]: i};

/// 同じタイムのときのチームの順(1.9.5): 高校の番号の小さい順。それも同じ(同じ都道府県のその他の高校)なら、
/// 並べる前の順([motoJun]。名簿と都道府県の順なので毎回同じ)。順位が必ず1つに決まるようにする
int _onajiTimeJun(_Team a, _Team b, Map<_Team, int> motoJun) {
  final int c = _teamCode(a).compareTo(_teamCode(b));
  if (c != 0) return c;
  return (motoJun[a] ?? 0).compareTo(motoJun[b] ?? 0);
}

/// 駅伝を走らせる(チームの順に並べ替え、区間ごとの順位を返す。区間順位は[kukan][チームの並び])
/// 同じタイムのときは _onajiTimeJun の順(チームの順位も区間順位も。1.9.5)
List<List<int>> _ekiden(List<_Team> teams, List<_Kukan> kukan, Random r) {
  for (final _Team t in teams) {
    t.times = [for (int kk = 0; kk < t.ku.length; kk++) _kukanTime(t.ku[kk], kk, kukan, r)];
    t.goukei = t.times.fold<double>(0, (a, b) => a + b);
    // 7人そろわないチーム(普通は起きない)は最後にする
    if (t.ku.length < 7) t.goukei += 99999;
  }
  final Map<_Team, int> motoJun = _motoJun(teams);
  teams.sort((a, b) {
    final int c = a.goukei.compareTo(b.goukei);
    return c != 0 ? c : _onajiTimeJun(a, b, motoJun);
  });
  final List<List<int>> kj = [];
  for (int kk = 0; kk < 7; kk++) {
    final List<int> idx = [
      for (int i = 0; i < teams.length; i++)
        if (teams[i].ku.length > kk) i,
    ]..sort((a, b) {
        final int c = teams[a].times[kk].compareTo(teams[b].times[kk]);
        return c != 0 ? c : _onajiTimeJun(teams[a], teams[b], motoJun);
      });
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
/// [hikitsugi] は、去年・2年前の大会で目立った名前のない下級生。力の合う新入生をその高校に入れ、
/// 引き継いだ組などを [hikitsugiOut] に入れて返す(記録のその選手に名前を付けるため。1.9.5)
Map<int, KoukouJouhou> _nendoKeisan(
  List<SenshuData> shinnyuusei,
  Random r, [
  Map<String, dynamic>? kirokuOut,
  List<_Hikitsugi>? hikitsugi,
  _HikitsugiOut? hikitsugiOut,
]) {
  // 今の名簿を一度だけ読む(getter の koukouMeibo を、この中だけ同じ名前で置き換える。1.9.5)
  final List<KoukouMei> koukouMeibo = koukouMeiboGenzai();
  final Map<int, KoukouJouhou> kekka = {};
  final int kenSuu = LocationDatabase.allPrefectures.length;
  final List<_Kousei> jitsuzai = []; // 走る新入生
  final List<List<_Kousei>> bu = [for (int i = 0; i < koukouMeibo.length; i++) <_Kousei>[]];
  // 大会の記録に目立って残った選手(区間の上位3人・8位までの走者・高校総体の決勝。1.9.5)
  // 名前のない下級生を、翌年以降の新入生に引き継ぐ候補として記録に残すのに使う
  final Set<_Kousei> medatsu = {};

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

  // 新入生の経歴(1.9.5: 高校を決める前に全員分を決め、目立った名前のない下級生を引き継ぐ新入生を選ぶ)
  final List<_Junbi> junbi = [];
  for (final SenshuData s in shinnyuusei) {
    if (s.hirou == 1) continue; // 留学生は上で決めた
    int ken = PackedIndexHelper.unpackIndices(s.samusataisei)['prefectureIndex'] ?? -1;
    if (ken < 0 || ken >= kenSuu) ken = r.nextInt(kenSuu);
    final double t5 = s.kiroku_nyuugakuji_5000;
    final bool kirokuAri = t5 > 0 && t5 < 1200;
    final int keireki = kirokuAri ? _keirekiKimeru(t5, s.spurtryoku, s.paceagesagetaiouryoku, r) : 2;
    junbi.add(_Junbi(s, ken, keireki, keireki == 2 ? null : _shinnyuusei(s, keireki)));
  }
  // 引き継ぐ新入生の高校(選手のid → 高校)
  final Map<int, int> kotei = (hikitsugi == null || hikitsugi.isEmpty)
      ? <int, int>{}
      : _hikitsugiKimeru(hikitsugi, junbi, koukouMeibo, hikitsugiOut);

  // 新入生の高校
  for (final _Junbi jb in junbi) {
    final SenshuData s = jb.s;
    final int ken = jb.ken;
    final int keireki = jb.keireki;
    final _Kousei? k = jb.k;
    int koukou;
    if (k != null) {
      koukou = kotei[s.id] ?? _koukouErabu(k, ken, r);
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
  // 大会の記録の中だけの番号を、-2から下へ付ける(1.9.5)
  int nanashiBan = -2;
  for (int i = 0; i < koukouMeibo.length; i++) {
    for (final int g in const [3, 3, 3, 2, 2, 2, 1, 1, 1]) {
      final _Kousei n = _nanashi(koukouMeibo[i].meimon, g, r);
      n.koukou = i;
      n.ken = koukouMeibo[i].ken;
      n.kirokuId = nanashiBan--;
      bu[i].add(n);
    }
    // 大学に来る留学生がいる高校には、名前のない留学生を入れない(1.9.5)
    if (koukouMeibo[i].ryuugakusei && !ryuugakuseiKoukou.contains(i)) {
      final _Kousei n = _nanashiRyuugakusei(r);
      n.koukou = i;
      n.ken = koukouMeibo[i].ken;
      n.kirokuId = nanashiBan--;
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
    // 同じタイムなら _onajiTimeJun の順(1.9.5)
    final Map<_Team, int> chikuJun = _motoJun(chikuNi[c]);
    chikuNi[c].sort((a, b) {
      final int s = a.goukei.compareTo(b.goukei);
      return s != 0 ? s : _onajiTimeJun(a, b, chikuJun);
    });
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
    // 区間の上位3人は、区間順位(zkj)の順に選ぶ(同じタイムのときも、区間順位と同じ順になる。1.9.5)
    kirokuOut['k'] = [
      for (int kk = 0; kk < _zenkokuKukan.length && kk < zkj.length; kk++)
        [
          for (final int ti in ([
            for (int i = 0; i < zenkokuTeams.length; i++)
              if (zenkokuTeams[i].ku.length > kk) i,
          ]..sort((a, b) => zkj[kk][a].compareTo(zkj[kk][b])))
              .take(3))
            _soushaKiroku(zenkokuTeams[ti].ku[kk], zenkokuTeams[ti].times[kk]),
        ],
    ];
    kirokuOut['ky'] = kenYuushou;
    // 各チームの走者(1.9.5): 8位までは7人全員、9位以下は大学に入った選手だけ。
    // 選手の後ろに区間(1〜7。補欠は0)を付ける。大学に入った補欠も入れる。
    // 走った選手は、その後ろに区間順位(zkj から。選手の高校時代の実績と同じ順位)も付ける(1.9.5)
    kirokuOut['m'] = [
      for (int j = 0; j < zenkokuTeams.length; j++)
        [
          for (int kk = 0; kk < zenkokuTeams[j].ku.length; kk++)
            if (j < 8 || zenkokuTeams[j].ku[kk].s != null)
              [
                ..._soushaKiroku(zenkokuTeams[j].ku[kk], zenkokuTeams[j].times[kk]),
                kk + 1,
                kk < zkj.length ? zkj[kk][j] + 1 : 0,
              ],
          for (final _Kousei h in zenkokuTeams[j].hoketsu)
            if (h.s != null) [..._soushaKiroku(h, 0), 0],
        ],
    ];
    // 目立って残った選手(区間の上位3人と、8位までの高校の走者。1.9.5)
    for (int kk = 0; kk < _zenkokuKukan.length && kk < zkj.length; kk++) {
      for (int ti = 0; ti < zenkokuTeams.length; ti++) {
        if (zenkokuTeams[ti].ku.length > kk && zkj[kk][ti] < 3) medatsu.add(zenkokuTeams[ti].ku[kk]);
      }
    }
    for (int j = 0; j < zenkokuTeams.length && j < 8; j++) {
      medatsu.addAll(zenkokuTeams[j].ku);
    }
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
      medatsu.addAll(fin); // 決勝の全員も目立って残った選手(1.9.5)
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
  // 目立って残った名前のない下級生(名簿の高校の日本人の1・2年生)を、翌年以降の新入生に引き継ぐ候補として
  // 記録に残す([記録の中だけの番号, 高校, 学年, 内部の持ちタイム(0.1秒)]。1.9.5)
  if (kirokuOut != null) {
    kirokuOut['nn'] = [
      for (final _Kousei k in medatsu)
        if (k.s == null && !k.ryuugakusei && k.gakunen <= 2 && k.koukou >= 0 && k.kirokuId <= -2)
          <dynamic>[k.kirokuId, k.koukou, k.gakunen, (k.t5 * 10).round()],
    ];
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
/// [shusshinHenkou] は、名前のない下級生を引き継いで、名門でない高校に県外から入れた新入生の出身地を、
/// その高校の都道府県に変えてよいか(1.9.5)。まだだれにも見せていない選手だけのとき(4月5日の新入生・
/// 新しいゲームの開始時)にtrueにする。起動時・セーブデータの読み込み時は、選手をもう見ているので変えない
Future<int> koukouJouhouFuyo({bool shusshinHenkou = false}) async {
  try {
    return await _koukouJouhouFuyoHontai(shusshinHenkou);
  } catch (e, st) {
    print('出身校と高校時代の実績の計算でエラー(ゲームはそのまま続ける): $e\n$st');
    return 0;
  }
}

Future<int> _koukouJouhouFuyoHontai(bool shusshinHenkou) async {
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
    // この世代が大学に入る年度と、去年・2年前の大会で目立った名前のない下級生(引き継ぐ候補。1.9.5)
    final int? sedaiNendo = nendo == null ? null : nendo - (gakunen - 1);
    final List<_Hikitsugi> hikitsugi = (kiroku != null && sedaiNendo != null)
        ? _hikitsugiKouho(sedaiNendo)
        : <_Hikitsugi>[];
    final _HikitsugiOut hikitsugiOut = _HikitsugiOut();
    final Map<int, KoukouJouhou> kekka = _nendoKeisan(list, r, kiroku, hikitsugi, hikitsugiOut);
    int shusshinKazu = 0;
    for (final SenshuData s in list) {
      final KoukouJouhou? j = kekka[s.id];
      if (j == null) continue;
      // 名門でない高校に県外から入れた新入生は、出身地をその高校の都道府県にする(見せる前だけ。1.9.5)
      int moto = s.samusataisei;
      final int? ken = shusshinHenkou ? hikitsugiOut.ekkyou[s.id] : null;
      if (ken != null) {
        moto = _shusshinKaeru(moto, ken);
        shusshinKazu++;
      }
      s.samusataisei = j.kakikomi(moto);
      await s.save();
      kazu++;
    }
    if (hikitsugi.isNotEmpty) {
      // 確認用(1.9.5)
      print(
        '下級生の引き継ぎ: 候補${hikitsugi.length}人・引き継ぎ${hikitsugiOut.kekka.length}人'
        '(越境${hikitsugiOut.ekkyou.length}人・伸び悩み${hikitsugiOut.nobinayami}人)・出身地を変えた$shusshinKazu人',
      );
    }
    // この学年が大学に入った年度(1年生なら今年度、2年生なら1年前…)
    if (kiroku != null && nendo != null) await _kirokuHozon(nendo - (gakunen - 1), kiroku);
    // 引き継いだ名前のない下級生に、去年・2年前の大会の記録で名前を付ける(1.9.5)
    if (hikitsugiOut.kekka.isNotEmpty) {
      await _hikitsugiKakikomi(hikitsugiOut.kekka, {for (final SenshuData s in list) s.id: s});
    }
  }
  print('出身校と高校時代の実績を付けた選手: $kazu人'); // 確認用(1.9.5)
  return kazu;
}

// ------------------------------------------------------------
// 名前のない下級生の引き継ぎ(1.9.5)
// ・大会の記録に目立って残った名前のない1・2年生(区間の上位3人・8位までの高校の走者・高校総体の決勝)を、
//   記録の nn に残しておく(高校・学年・内部の持ちタイム)
// ・翌年(2年生)・2年後(1年生)の新入生の高校を決めるときに、持ちタイムがその選手の伸びた力に合う新入生を、
//   その高校に入れる(高校の都道府県の出身から。名門なら県外からも)。合う新入生がいなければ引き継がない
//   (ゲームの大学には来なかった選手のまま)。力は入学時の5000mの記録で見る(基本走力は使わない)
// ・同じ高校の「2年前の1年生」と「去年の2年生」は、1年生のときのほうが遅ければ同じ選手とみなす
// ・引き継いだら、その回の記録のその選手に名前を付ける(学年はそのまま残し、画面では「(当時2年)」と出す)
// ・説明書や画面には書かない(気づいた人へのお楽しみ)
// ------------------------------------------------------------

/// 引き継ぐ候補の、名前のない下級生
class _Hikitsugi {
  /// その記録の世代が大学に入った年度
  final int kirokuNendo;

  /// 記録の中だけの番号(負の数)
  final int kirokuId;

  /// 名簿の高校の番号
  final int koukou;

  /// その大会のときの学年(1か2)
  final int gakunen;

  /// 内部の持ちタイム(秒。その大会のときの力)
  final double t5;

  const _Hikitsugi(this.kirokuNendo, this.kirokuId, this.koukou, this.gakunen, this.t5);
}

/// 引き継いだ組(記録の書き換えに使う)
class _HikitsugiKekka {
  final int kirokuNendo;
  final int kirokuId;
  final int senshuId;

  const _HikitsugiKekka(this.kirokuNendo, this.kirokuId, this.senshuId);
}

/// 引き継ぎの結果(1.9.5)
class _HikitsugiOut {
  /// 引き継いだ組(記録の書き換えに使う。同じ新入生に1年生と2年生の2組が付くこともある)
  final List<_HikitsugiKekka> kekka = [];

  /// 名門でない高校に、県外から入れた新入生(選手のid → その高校の都道府県。出身地を変えるのに使う)
  final Map<int, int> ekkyou = {};

  /// 当時より少し遅い新入生にした数(伸び悩み。確認用のログ)
  int nobinayami = 0;
}

/// 出身地を[ken]に変えた、下の17ビット(出身地と趣味)の値(趣味はそのまま。1.9.5)
int _shusshinKaeru(int samusataisei, int ken) {
  final Map<String, int> m = PackedIndexHelper.unpackIndices((samusataisei < 0 ? 0 : samusataisei) % _shitaBit);
  return PackedIndexHelper.packIndices(hobbyIndex: m['hobbyIndex'] ?? 0, prefectureIndex: ken);
}

/// 新入生1人分の、高校を決める前の情報
class _Junbi {
  final SenshuData s;
  final int ken;
  final int keireki;

  /// 走る選手(ほかの競技の出身はnull)
  final _Kousei? k;

  const _Junbi(this.s, this.ken, this.keireki, this.k);
}

/// [sedaiNendo] に大学に入る世代へ引き継ぐ候補(去年の回の2年生と、2年前の回の1年生)。
/// この世代の回がもうあれば(計算し直し)、引き継がない
List<_Hikitsugi> _hikitsugiKouho(int sedaiNendo) {
  final List<_Hikitsugi> l = [];
  final List<dynamic> kiroku = _kirokuYomuMoto();
  for (final dynamic d in kiroku) {
    if (_kirokuNen(d) == sedaiNendo) return <_Hikitsugi>[];
  }
  for (final dynamic d in kiroku) {
    if (d is! Map) continue;
    final int nen = _kirokuNen(d);
    final int gakunen = sedaiNendo - nen == 1 ? 2 : (sedaiNendo - nen == 2 ? 1 : 0);
    if (gakunen == 0) continue;
    final dynamic nn = d['nn'];
    if (nn is! List) continue;
    for (final dynamic e in nn) {
      if (e is! List || e.length < 4) continue;
      if (e[0] is! num || e[1] is! num || e[2] is! num || e[3] is! num) continue;
      if ((e[2] as num).toInt() != gakunen) continue;
      l.add(_Hikitsugi(nen, (e[0] as num).toInt(), (e[1] as num).toInt(), gakunen, (e[3] as num).toDouble() / 10.0));
    }
  }
  return l;
}

/// 引き継ぐ新入生を選ぶ。戻り値は、選手のid → 入れる高校。引き継いだ組などは [out] に入れる
/// 去年の2年生から、力の高い順に選ぶ(そのあと2年前の1年生)。3年生のときの力の見込み(1年に12秒伸びる)に
/// 近い持ちタイムの新入生にする。見られる記録に載った下級生がなるべく全員出てくるように、合う新入生が
/// いなければ、条件を段階的にゆるめる(1.9.5):
///   1. 高校の都道府県の出身(名門は県外からも)で、当時より遅くない選手
///   2. 県外から(越境。名門でない高校の新入生は、見せる前なら出身地をその高校の都道府県に変える)
///   3. 当時より15秒遅いまでの選手(伸び悩み)
Map<int, int> _hikitsugiKimeru(
  List<_Hikitsugi> kouho,
  List<_Junbi> junbi,
  List<KoukouMei> meibo,
  _HikitsugiOut? out,
) {
  final Map<int, int> kotei = {};
  final Map<int, double> niNen = {}; // 2年生のときに引き継いだ選手の、2年生のときの力
  final Set<int> ichiNen = {}; // 1年生のときも引き継いだ選手
  final List<_Hikitsugi> jun = List<_Hikitsugi>.of(kouho)
    ..sort((a, b) {
      if (a.gakunen != b.gakunen) return b.gakunen.compareTo(a.gakunen);
      final int c = a.t5.compareTo(b.t5);
      return c != 0 ? c : b.kirokuId.compareTo(a.kirokuId);
    });
  for (final _Hikitsugi h in jun) {
    if (h.koukou < 0 || h.koukou >= meibo.length) continue;
    // 1年生は、同じ高校で2年生のときに引き継いだ選手がいて、1年生のときのほうが遅ければ、同じ選手にする
    if (h.gakunen == 1) {
      int? onaji;
      for (final MapEntry<int, int> e in kotei.entries) {
        if (e.value != h.koukou || ichiNen.contains(e.key)) continue;
        final double? t2 = niNen[e.key];
        if (t2 != null && t2 <= h.t5 + 3.0) {
          onaji = e.key;
          break;
        }
      }
      if (onaji != null) {
        ichiNen.add(onaji);
        out?.kekka.add(_HikitsugiKekka(h.kirokuNendo, h.kirokuId, onaji));
        continue;
      }
    }
    final int nen = 3 - h.gakunen; // 3年生になるまでの年数
    final double mikomi = h.t5 - 12.0 * nen; // 3年生のときの力の見込み
    final double haba = 15.0 + 5.0 * nen;
    final KoukouMei m = meibo[h.koukou];
    _Junbi? yoi;
    // 条件を段階的にゆるめる(0: 同じ県か名門・当時より遅くない、1: 県外からも、2: 当時より15秒遅いまで)
    for (int dan = 0; dan < 3 && yoi == null; dan++) {
      double yoiTen = double.infinity;
      for (final _Junbi j in junbi) {
        final _Kousei? k = j.k;
        if (k == null || kotei.containsKey(j.s.id)) continue;
        final bool kenOnaji = j.ken == m.ken;
        if (dan == 0 && !kenOnaji && m.meimon != 3) continue; // 県外からは名門だけ
        final double sa = (k.t5 - mikomi).abs();
        if (dan < 2) {
          if (k.t5 > h.t5 + 3.0) continue; // 当時より遅い選手にはしない
          if (sa > haba) continue;
        } else {
          if (k.t5 > h.t5 + 15.0) continue; // 伸び悩みは15秒遅いまで
        }
        final double ten = sa + (kenOnaji ? 0.0 : 5.0); // 同じ県の出身を少し優先する
        if (ten < yoiTen) {
          yoi = j;
          yoiTen = ten;
        }
      }
    }
    if (yoi == null) continue; // 合う新入生がいない(ゲームの大学には来なかった)
    kotei[yoi.s.id] = h.koukou;
    if (h.gakunen == 2) {
      niNen[yoi.s.id] = h.t5;
    } else {
      ichiNen.add(yoi.s.id);
    }
    if (out != null) {
      out.kekka.add(_HikitsugiKekka(h.kirokuNendo, h.kirokuId, yoi.s.id));
      // 名門でない高校に県外から入れた新入生(見せる前なら、出身地をその高校の都道府県に変える)
      if (yoi.ken != m.ken && m.meimon != 3) out.ekkyou[yoi.s.id] = m.ken;
      final _Kousei? k = yoi.k;
      if (k != null && k.t5 > h.t5 + 3.0) out.nobinayami++;
    }
  }
  return kotei;
}

/// 引き継いだ名前のない下級生に、その回の記録で名前を付ける(種類・大学・名前・選手のidを書き換える。
/// 学年はそのまま残す)。引き継いだ選手は、その回の候補(nn)から外す
Future<void> _hikitsugiKakikomi(List<_HikitsugiKekka> l, Map<int, SenshuData> senshu) async {
  final UnivData? u = _kirokuUniv(_kirokuUnivId);
  if (u == null) return;
  final List<dynamic> kiroku = _kirokuYomuMoto();
  bool kaeta = false;
  for (final dynamic d in kiroku) {
    if (d is! Map) continue;
    final int nen = _kirokuNen(d);
    final Map<int, SenshuData> kono = {};
    for (final _HikitsugiKekka h in l) {
      final SenshuData? s = senshu[h.senshuId];
      if (h.kirokuNendo == nen && s != null) kono[h.kirokuId] = s;
    }
    if (kono.isEmpty) continue;
    void naosu(dynamic a) {
      if (a is! List || a.length < 7 || a[6] is! num) return;
      final SenshuData? s = kono[(a[6] as num).toInt()];
      if (s == null) return;
      a[0] = 0;
      a[1] = s.univid;
      a[3] = s.name;
      a[6] = s.id;
      kaeta = true;
    }

    for (final String kagi in const ['k', 's', 'm']) {
      final dynamic g = d[kagi];
      if (g is! List) continue;
      for (final dynamic l2 in g) {
        if (l2 is! List) continue;
        for (final dynamic a in l2) {
          naosu(a);
        }
      }
    }
    final dynamic nn = d['nn'];
    if (nn is List) {
      nn.removeWhere((dynamic e) => e is List && e.isNotEmpty && e.first is num && kono.containsKey((e.first as num).toInt()));
    }
  }
  if (!kaeta) return;
  u.name_tanshuku = '$_kirokuMidashi\n${jsonEncode(kiroku)}';
  await u.save();
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
//     m: [チームごとに[選手 + 区間(1〜7。補欠は0) + 区間順位(走った選手だけ)]...](z と同じ並び)。
//     区間順位は、順位を残す前の記録にはない(画面では上位3人の記録から分かる分だけ出す)
//     選手のidは、名前のない高校生では記録の中だけの番号(-2から下。それより前の記録は-1)。
//     nn: [[記録の中だけの番号, 名簿の高校の番号, 学年, 内部の持ちタイム(0.1秒)]...]
//     (目立って残った名前のない1・2年生。翌年以降の新入生に引き継ぐ候補。引き継いだら、その選手の
//     種類・大学id・名前・選手のidを書き換え、学年はそのまま残す(画面で「(当時2年)」)。1.9.5)
//     z の優勝校(1位)だけ、出場の回数目と連続出場の後ろに、その時点の優勝の回数目・連続優勝の年数・
//     何年ぶり(連続でない2回目以上の優勝のとき。ほかは0)を書き足す(1.9.5。書き足す前の記録にはない)
//   ・優勝回数: {z: [全国高校駅伝の優勝回数(名簿の並び)], k: [都道府県予選の優勝回数],
//     d: [出場回数], rn: [連続出場], ln: [最後に出た年度], lz: [最後に優勝した年度], h: 名簿の編集}
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
  final String maeMei = koukouCodeMei(i);
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
  // 校名か都道府県が変わったら、それまでの大会の記録には当時の名前で出す
  if (koukouCodeMei(i) != maeMei) await _kirokuNiKyuumeiNokosu({i: maeMei});
}

/// 高校の名簿を、すべて初期値に戻す
Future<void> koukouHenkouZenbuModosu() async {
  final List<KoukouMei> mae = koukouMeiboGenzai();
  final Map<int, String> maeMei = {
    for (int i = 0; i < mae.length; i++)
      if (!identical(mae[i], koukouMeiboShoki[i])) i: koukouCodeMei(i),
  };
  final Map<String, dynamic> d = _kaisuuJsonYomu();
  d.remove('h');
  await _kaisuuJsonKaku(d);
  await _kirokuNiKyuumeiNokosu({
    for (final MapEntry<int, String> e in maeMei.entries)
      if (koukouCodeMei(e.key) != e.value) e.key: e.value,
  });
}

/// 大会の記録に、校名か都道府県を変えた高校の当時の名前を残す(1.9.5。kn に {"高校の番号": 名前})
/// もっと前の名前が残っている回は、そちらのままにする(その回の当時の名前なので)
Future<void> _kirokuNiKyuumeiNokosu(Map<int, String> kyuumei) async {
  if (kyuumei.isEmpty) return;
  final List<dynamic> kiroku = _kirokuYomuMoto();
  if (kiroku.isEmpty) return;
  bool kawatta = false;
  for (final dynamic r in kiroku) {
    if (r is! Map) continue;
    final Map<String, dynamic> kn = r['kn'] is Map ? Map<String, dynamic>.from(r['kn'] as Map) : <String, dynamic>{};
    for (final MapEntry<int, String> e in kyuumei.entries) {
      if (kn.containsKey('${e.key}')) continue;
      kn['${e.key}'] = e.value;
      kawatta = true;
    }
    r['kn'] = kn;
  }
  if (!kawatta) return;
  final UnivData? u = _kirokuUniv(_kirokuUnivId);
  if (u == null) return;
  u.name_tanshuku = '$_kirokuMidashi\n${jsonEncode(kiroku)}';
  await u.save();
}

/// 高校[i]の全国高校駅伝の出場回数・優勝回数・連続出場と、都道府県予選の優勝回数を0に戻す(1.9.5。
/// 高校名鑑の編集の画面。大会の記録はそのまま残す)
Future<void> koukouKaisuuReset(int i) async {
  if (i < 0 || i >= koukouMeiboShoki.length) return;
  final Map<String, dynamic> kaisuuJson = _kaisuuJsonYomu();
  final List<int> z = _kaisuuList(kaisuuJson, 'z', 0);
  final List<int> k = _kaisuuList(kaisuuJson, 'k', 0);
  final List<int> d = _kaisuuList(kaisuuJson, 'd', 0);
  final List<int> rn = _kaisuuList(kaisuuJson, 'rn', 0);
  final List<int> ln = _kaisuuList(kaisuuJson, 'ln', _mishutsujou);
  final List<int> lz = _kaisuuList(kaisuuJson, 'lz', _mishutsujou);
  z[i] = 0;
  k[i] = 0;
  d[i] = 0;
  rn[i] = 0;
  ln[i] = _mishutsujou;
  lz[i] = _mishutsujou;
  kaisuuJson['z'] = z;
  kaisuuJson['k'] = k;
  kaisuuJson['d'] = d;
  kaisuuJson['rn'] = rn;
  kaisuuJson['ln'] = ln;
  kaisuuJson['lz'] = lz;
  await _kaisuuJsonKaku(kaisuuJson);
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
    s?.id ?? k.kirokuId, // 名前のない高校生は、記録の中だけの番号(負の数。1.9.5)
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
  // 優勝回数(記録を保存する前に足し、優勝校に、その時点の優勝の回数目・連続・何年ぶりを書き足す。1.9.5)
  final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
  final List<int> saigoYuushou = _kaisuuList(kaisuuJson, 'lz', _mishutsujou);
  if (zKonkai is List && zKonkai.isNotEmpty && zKonkai.first is List && (zKonkai.first as List).isNotEmpty) {
    final dynamic code = (zKonkai.first as List).first;
    if (code is num && code.toInt() >= 0 && code.toInt() < kai.zenkoku.length) {
      kai.zenkoku[code.toInt()]++;
      _yuushouKakitasu(nyuugakuNendo, zKonkai, kai.zenkoku, saigoYuushou, mae);
    }
  }
  final List<dynamic> l = [
    {
      'y': nyuugakuNendo,
      'z': kiroku['z'] ?? [],
      'k': kiroku['k'] ?? [],
      's': kiroku['s'] ?? [],
      'm': kiroku['m'] ?? [],
      'nn': kiroku['nn'] ?? [], // 目立った名前のない下級生(翌年以降の新入生に引き継ぐ候補。1.9.5)
    },
    ...mae,
  ]..sort((a, b) => _kirokuNen(b).compareTo(_kirokuNen(a)));
  u.name_tanshuku = '$_kirokuMidashi\n${jsonEncode(l.take(_kirokuHozonSuu).toList())}';
  await u.save();
  // 都道府県予選の優勝回数
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
  kaisuuJson['lz'] = saigoYuushou;
  await _kaisuuJsonKaku(kaisuuJson);
}

/// まだ全国高校駅伝に出ていない(優勝していない)高校の、最後に出た(優勝した)年度
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
    // t は数だけの一覧(List<int>)のこともあるので、1つずつ足す(型の決まらない一覧を addAll すると型のエラーになる)。
    // 優勝校の後ろ(5番目から)にある優勝の回数目などは消さない(数え直すときのため。1.9.5)
    if (t.length >= 5) {
      t[3] = shutsujou[code];
      t[4] = renzoku[code];
    } else {
      t.removeRange(3, t.length);
      t.add(shutsujou[code]);
      t.add(renzoku[code]);
    }
  }
}

/// 全国高校駅伝の優勝校に、その時点の優勝の回数目・連続優勝の年数・何年ぶりかを書き足す(1.9.5)
/// [yuushou] は優勝回数(この回の分を足したあと)、[saigoYuushou] は高校ごとの最後に優勝した年度(この回の年度に進める)。
/// [mae] はこれまでの記録(前の年度の回の優勝校が同じなら、その連続に1を足す。連続は優勝回数を超えない
/// ので、回数を0に戻したあとは1から数え直す)。何年ぶりは、連続でない2回目以上の優勝のとき(ほかは0)
void _yuushouKakitasu(int nendo, List<dynamic> z, List<int> yuushou, List<int> saigoYuushou, List<dynamic> mae) {
  if (z.isEmpty || z.first is! List) return;
  final List<dynamic> t = z.first as List<dynamic>;
  if (t.isEmpty || t.first is! num) return;
  final int code = (t.first as num).toInt();
  if (code < 0 || code >= yuushou.length || code >= saigoYuushou.length) return;
  final int kaime = yuushou[code];
  int renzoku = 1;
  for (final dynamic d in mae) {
    if (_kirokuNen(d) != nendo - 1 || d is! Map) continue;
    final dynamic zMae = d['z'];
    if (zMae is! List || zMae.isEmpty || zMae.first is! List) break;
    final List<dynamic> tMae = zMae.first as List<dynamic>;
    if (tMae.isEmpty || tMae.first is! num || (tMae.first as num).toInt() != code) break;
    // 前の回に連続の年数がなければ(書き足す前の記録)、前の回の1年分だけ数える
    final int maeRenzoku = (tMae.length >= 7 && tMae[6] is num) ? (tMae[6] as num).toInt() : 1;
    renzoku = min(maeRenzoku + 1, kaime);
    break;
  }
  if (renzoku < 1) renzoku = 1;
  final int saigo = saigoYuushou[code];
  final int buri = (renzoku == 1 && kaime >= 2 && saigo != _mishutsujou && nendo - saigo >= 2) ? nendo - saigo : 0;
  saigoYuushou[code] = nendo;
  while (t.length < 5) {
    t.add(0);
  }
  t.removeRange(5, t.length);
  t.add(kaime);
  t.add(renzoku);
  t.add(buri);
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
    for (final String kagi in const ['z', 'k', 'd', 'rn', 'ln', 'lz']) {
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

  /// 区間順位(1〜。補欠や、順位を残す前の記録は0。チームの走者のとき。1.9.5)
  final int kukanJuni;

  const KoukouKirokuSousha({
    required this.shurui,
    required this.univid,
    required this.gakunen,
    required this.name,
    required this.kouCode,
    required this.time,
    required this.id,
    this.kukan = 0,
    this.kukanJuni = 0,
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

  /// 優勝校の、その時点の優勝の回数目・連続優勝の年数・何年ぶり(記録を残し始めてから。分からなければ0。1.9.5)
  final int yuushouKaime;
  final int yuushouRenzoku;
  final int yuushouBuri;

  const KoukouKirokuTeam(
    this.kouCode,
    this.daihyou,
    this.time, {
    this.member,
    this.kaime = 0,
    this.renzoku = 0,
    this.yuushouKaime = 0,
    this.yuushouRenzoku = 0,
    this.yuushouBuri = 0,
  });
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

  /// この回のあとに校名や都道府県を変えた高校の、当時の名前(「天馬学園高(栃木)」。高校の番号から。1.9.5)
  final Map<int, String> kyuumei;

  const KoukouTaikaiKiroku(this.nyuugakuNendo, this.zenkoku, this.kukan, this.soutai, [this.kyuumei = const {}]);

  /// この回の高校の名前(当時の名前が残っていればそちら)
  String kouMei(int code) => kyuumei[code] ?? koukouCodeMei(code);
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
    kukanJuni: a.length >= 9 && a[8] is num ? (a[8] as num).toInt() : 0,
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

Map<int, String> _kyuumeiYomu(dynamic kn) {
  final Map<int, String> m = {};
  if (kn is! Map) return m;
  for (final MapEntry<dynamic, dynamic> e in kn.entries) {
    final int? i = int.tryParse('${e.key}');
    if (i != null && e.value is String) m[i] = e.value as String;
  }
  return m;
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
              yuushouKaime: t.length >= 8 && t[5] is num ? (t[5] as num).toInt() : 0,
              yuushouRenzoku: t.length >= 8 && t[6] is num ? (t[6] as num).toInt() : 0,
              yuushouBuri: t.length >= 8 && t[7] is num ? (t[7] as num).toInt() : 0,
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
          _kyuumeiYomu(d['kn']),
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

  /// 地区代表として全国高校駅伝に出た回数(1.9.5。都道府県予選で優勝すれば必ず全国に出るので、出場回数から
  /// 都道府県予選の優勝回数を引いた残り。どちらも同じ回から数え、新しいゲームと0に戻すときに一緒に消す)
  int chikuDaihyou(int i) => (i < shutsujou.length && i < ken.length) ? max(0, shutsujou[i] - ken[i]) : 0;
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

// ------------------------------------------------------------
// スカウト画面の、高校時代(直近の大会)のフィルターと大会の結果(1.9.5)
// ・スカウトの候補は4月5日に入った新入生で、その世代の大会の記録は同じ日に保存してある(一番新しい回)
// ・所属高校の全国高校駅伝の順位(走っていない部員も)、区間順位、高校総体の決勝の順位(掛け持ちの種目も)を、
//   今年度に大学に入った世代の回から読む。その回がなければ(古いデータ)、選手の高校時代の実績から分かる分だけ
// ------------------------------------------------------------

/// 今の年度(スカウト画面から、今年の新入生の世代の回を探すのに使う。1.9.5)
int? koukouImaNoNendo() => _imaNoNendo();

/// 高校名のフィルター(1.9.5): 校名か都道府県に[moji]が入っているか(空なら当たり)
/// (校名は「高」の付いた名前で、都道府県は「県」「府」「都」の付いた名前で見るので、どちらの書き方でも当たる)
bool koukouMeiAtaru(KoukouJouhou j, String moji) {
  final String k = moji.trim();
  if (k.isEmpty) return true;
  final KoukouMei? m = j.mei;
  if (m == null) return false;
  final String ken = (m.ken >= 0 && m.ken < LocationDatabase.allPrefectures.length)
      ? LocationDatabase.allPrefectures[m.ken]
      : '';
  return '${m.mei}高'.contains(k) || ken.contains(k);
}

/// 今年度に大学に入った世代(スカウトの候補)の、直近の大会の成績(1.9.5)
class KoukouSaishinSeiseki {
  /// 今年度の世代の大会の記録があるか
  final bool kirokuAri;

  /// 全国高校駅伝の高校の順位(名簿の高校の番号 → 順位)
  final Map<int, int> _teamJuni;

  /// 全国高校駅伝の区間順位(選手id → 順位。区間順位を残す前の記録にはない)
  final Map<int, int> _kukanJuni;

  /// 高校総体の決勝の順位(種目(0=1500m・1=5000m・2=3000m障害)ごとに、選手id → 順位)
  final List<Map<int, int>> _soutaiJuni;

  /// 記録の選手の名前(選手id → 名前。別の選手とidが重ならないように、名前も合わせて見る)
  final Map<int, String> _namae;

  KoukouSaishinSeiseki._(this.kirokuAri, this._teamJuni, this._kukanJuni, this._soutaiJuni, this._namae);

  bool _onaji(SenshuData s) => _namae[s.id] == s.name;

  /// 所属高校の全国高校駅伝の順位(0は出ていない)。
  /// 記録がなければ、選手がチームにいたときのチームの順位(31位以下は99)
  int teamJuni(SenshuData s) {
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (j.koukou < 1) return 0;
    if (kirokuAri) return _teamJuni[j.koukou - 1] ?? 0;
    if (!j.ekidenZenkoku || j.ekidenJuni < 1) return 0;
    return j.ekidenJuni >= 31 ? 99 : j.ekidenJuni;
  }

  /// 全国高校駅伝の区間順位(0は走っていない)。
  /// 記録に区間順位がなければ、選手の高校時代の実績から(31位以下は99)
  int kukanJuni(SenshuData s) {
    if (kirokuAri && _onaji(s)) {
      final int? v = _kukanJuni[s.id];
      if (v != null) return v;
    }
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (!j.ekidenZenkoku || j.ekidenKukan < 1 || j.ekidenKukanJuni < 1) return 0;
    return j.ekidenKukanJuni >= 31 ? 99 : j.ekidenKukanJuni;
  }

  /// 高校総体の決勝の順位([shumoku] 0=1500m・1=5000m・2=3000m障害。0は決勝に出ていない)。
  /// 記録がなければ、選手の高校時代の実績(一番良い種目だけ)から
  int soutaiJuni(SenshuData s, int shumoku) {
    if (kirokuAri) {
      if (!_onaji(s) || shumoku < 0 || shumoku >= _soutaiJuni.length) return 0;
      return _soutaiJuni[shumoku][s.id] ?? 0;
    }
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (j.soutaiShumoku == shumoku + 1 && j.soutaiDankai == 3 && j.soutaiJuni >= 1) return j.soutaiJuni;
    return 0;
  }
}

/// 今年度に大学に入った世代の、直近の大会の成績を読む(1.9.5。スカウト画面のフィルター)
KoukouSaishinSeiseki koukouSaishinSeisekiYomu() {
  final int? nendo = _imaNoNendo();
  KoukouTaikaiKiroku? k;
  if (nendo != null) {
    for (final KoukouTaikaiKiroku r in koukouTaikaiKirokuYomu()) {
      if (r.nyuugakuNendo == nendo) {
        k = r;
        break;
      }
    }
  }
  final Map<int, int> team = {};
  final Map<int, int> kukan = {};
  final List<Map<int, int>> soutai = [<int, int>{}, <int, int>{}, <int, int>{}];
  final Map<int, String> namae = {};
  if (k != null) {
    for (int i = 0; i < k.zenkoku.length; i++) {
      final int code = k.zenkoku[i].kouCode;
      if (code >= 0 && code < 1000) team.putIfAbsent(code, () => i + 1);
      final List<KoukouKirokuSousha>? m = k.zenkoku[i].member;
      if (m == null) continue;
      for (final KoukouKirokuSousha s in m) {
        if (!s.namaeAri || s.id < 0) continue;
        namae[s.id] = s.name;
        if (s.kukan >= 1 && s.kukanJuni >= 1) kukan[s.id] = s.kukanJuni;
      }
    }
    for (int sh = 0; sh < k.soutai.length && sh < soutai.length; sh++) {
      for (int j = 0; j < k.soutai[sh].length; j++) {
        final KoukouKirokuSousha s = k.soutai[sh][j];
        if (!s.namaeAri || s.id < 0) continue;
        namae[s.id] = s.name;
        soutai[sh].putIfAbsent(s.id, () => j + 1);
      }
    }
  }
  return KoukouSaishinSeiseki._(k != null, team, kukan, soutai, namae);
}
