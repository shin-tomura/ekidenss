import 'dart:async' show unawaited;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/meisei_rireki.dart'; // 置き場所(名声の履歴と同じ文字)
import 'package:ekiden/kansuu/goldsilver_com.dart' show comKinHoyuu, comGinHoyuu; // コンピュータの大学の保有

// ------------------------------------------------------------
// 金銀の内訳(2.1.1)
//
// 全大学の金銀の出入りを、名声の履歴と同じく過去10年分記録する(Modal_kinginRireki.dart で見る)。
// ・自分の大学: 受け取った金銀(大学理事会からの支援・目標順位クリア・学連選抜の目標順位クリア・
//   大学当局からの支援)、特訓で使った金銀(日ごと・金銀ごとにまとめる)、金銀の交換
// ・コンピュータの大学(goldsilver_com.dart): 春の支援・目標順位クリア、夏合宿の金特訓・銀特訓・
//   使えなかった金の交換・使い切れなかった銀、金銀の使用がオフのときに0にした分
//   (支給がなかったときは書かない。プレイヤーの大学になった大学の保有を0にした分も書かない)
// ・年度替わり(RetireNew の名声の履歴をずらすところ)で、全大学の年度初めの保有を書く。
//   新しいゲームとリセットのときは、年度初めを0として書く(金銀はどちらのリセットでも0に戻るため)
//
// ・保存場所は、名声の履歴(meisei_rireki.dart)と同じ、大学id 18〜27 の UnivData.name_tanshuku。
//   Hiveの項目は増やさず、同じ文字に行を混ぜる。行の頭を「金銀」にするので、名声の履歴を読むところ
//   (頭が数字の行だけを読む。1.8.8から)には混ざらない。年度替わりで名声の履歴と一緒に1年ずつずれ、
//   10年で消える。新しいゲームと「名声は初期値に戻す」では名声の履歴と一緒に消え、
//   「名声・育成力と設定を残してやり直す」では金銀の行だけ消す(kinginRirekiReset)
// ・1行の書き方: 「金銀<TAB>大学id<TAB>種類<TAB>金の増減<TAB>銀の増減<TAB>月<TAB>日<TAB>回数<TAB>内容」
//   (年度初めの行は、金・銀の欄が保有。回数は特訓をまとめた行だけで、ほかは0)
// ・量は実際に増えた・減った量(保有の上限9999で止まった分は入らない)
// ・この版より前の金銀は記録がないので、画面では年度初めと年度末(今)の保有との差を
//   「記録のない増減」として出す
// ------------------------------------------------------------

/// 行の頭(名声の履歴の行と見分ける)
const String _atama = '金銀';

/// 種類(行に書く番号。変えない)
const int kinginUketotta = 0; // 受け取った
const int kinginTsukatta = 1; // 使った
const int kinginKoukan = 2; // 交換
const int kinginSonohoka = 3; // そのほか(使わずに0にした・使い切れなかった銀など)
const int _kinginNendoHajime = 9; // 年度初めの保有

/// 金銀の内訳の1行
class KinginRirekiGyou {
  final int univid;
  final int shurui;

  /// 金・銀の増減(年度初めの行は保有)
  final int kin;
  final int gin;

  final int tsuki;
  final int hi;

  /// 特訓の回数(日ごとにまとめた行だけ。ほかは0)
  final int kaisuu;

  final String naiyou;

  const KinginRirekiGyou({
    required this.univid,
    required this.shurui,
    required this.kin,
    required this.gin,
    required this.tsuki,
    required this.hi,
    this.kaisuu = 0,
    required this.naiyou,
  });

  /// 保存する1行(タブと改行は空白にする)
  String get moji {
    final String bun = naiyou.replaceAll('\t', ' ').replaceAll('\n', ' ');
    return '$_atama\t$univid\t$shurui\t$kin\t$gin\t$tsuki\t$hi\t$kaisuu\t$bun';
  }

  /// 保存した1行を読む(金銀の行でなければnull)
  static KinginRirekiGyou? yomu(String gyou) {
    final List<String> p = gyou.split('\t');
    if (p.length < 9 || p[0] != _atama) return null;
    final List<int?> n = [for (int i = 1; i <= 7; i++) int.tryParse(p[i])];
    if (n.contains(null)) return null;
    return KinginRirekiGyou(
      univid: n[0]!,
      shurui: n[1]!,
      kin: n[2]!,
      gin: n[3]!,
      tsuki: n[4]!,
      hi: n[5]!,
      kaisuu: n[6]!,
      naiyou: p.sublist(8).join(' '),
    );
  }
}

/// 金銀の行か(リセットで金銀の行だけ消すときに使う)
bool _kinginGyouKa(String gyou) => gyou.startsWith('$_atama\t');

Ghensuu? _gh() {
  final Box<Ghensuu> box = Hive.box<Ghensuu>('ghensuuBox');
  return box.isEmpty ? null : box.getAt(0);
}

/// 大会の名前(目標順位クリアの行に使う。[bangou] 0〜5: 駅伝・予選の番号、9: 対校戦)
String kinginTaikaiMei(int bangou) {
  switch (bangou) {
    case 3:
      return '11月駅伝予選';
    case 4:
      return '正月駅伝予選';
    case 9:
      return '対校戦';
    default:
      return meiseiRirekiEkidenMei(bangou);
  }
}

/// 目標順位クリアの行の内容(「正月駅伝 目標順位クリア(目標3位・結果2位)」。量の違いが分かるように、
/// 目標と結果を添える)。[bangou] 0〜5: 駅伝・予選の番号、9: 対校戦。[mokuhyou]・[kekka] は0が1位。
/// 量の決まりと同じく、駅伝は目標1位で優勝すると「優勝で2倍」、対校戦は優勝すると「優勝で増量」を添える
/// (KirokuKousin.dart の自分の大学の分・goldsilver_com.dart の _mokuhyouTasseiRyou と同じ決まり)
String kinginMokuhyouNaiyou(int bangou, int mokuhyou, int kekka) {
  final bool ekiden = (bangou >= 0 && bangou <= 2) || bangou == 5;
  final List<String> soe = [
    '目標${mokuhyou + 1}位',
    if (ekiden && mokuhyou == 0 && kekka == 0) '優勝で2倍' else '結果${kekka + 1}位',
    if (bangou == 9 && kekka == 0) '優勝で増量',
  ];
  return '${kinginTaikaiMei(bangou)} 目標順位クリア(${soe.join('・')})';
}

/// 春の大学理事会からの支援の行の内容(量を決めた昨年度の成績の区分を添える。
/// 決め方は goldsilverTeikiKakutoku.dart・goldsilver_com.dart の _teikiKakutokusuu と同じで、
/// 言い方は説明書の金銀の一覧(shiyou_text.dart)と同じ)
String kinginTeikiNaiyou(UnivData univ) {
  final List<List<int>> j = univ.juni_race;
  if (j.length < 10) return '大学理事会からの支援';
  final String kubun;
  if (j[0][0] == 0 && j[1][0] == 0 && j[2][0] == 0) {
    kubun = '三冠';
  } else if (j[0][0] == 0 || j[1][0] == 0 || j[2][0] == 0 || j[9][0] == 0) {
    kubun = '駅伝か対校戦で優勝';
  } else if (j[0][0] < 3 && j[1][0] < 3 && j[2][0] < 3) {
    kubun = '駅伝すべてで3位以内';
  } else if (j[0][0] < 3 || j[1][0] < 3 || j[2][0] < 3 || j[9][0] < 3) {
    kubun = '駅伝か対校戦のどれかで3位以内';
  } else if (j[0][0] < 5 || j[1][0] < 8 || j[2][0] < 10 || j[9][0] < 8) {
    kubun = '対校戦8位以内・10月駅伝5位以内・11月駅伝8位以内・正月駅伝10位以内のどれか';
  } else if (j[3][0] < 7 || j[4][0] < 10) {
    kubun = '11月駅伝予選突破か正月駅伝予選突破';
  } else {
    kubun = 'どれも達成していない・最低額';
  }
  return '大学理事会からの支援(昨年度の成績:$kubun)';
}

/// 今年度の金銀の内訳に、[gyou]をまとめて足して保存する(保存は1回だけ)
Future<void> kinginRirekiTsuika(List<KinginRirekiGyou> gyou) async {
  if (gyou.isEmpty) return;
  final UnivData? s = rirekiOkiba(0);
  if (s == null) return;
  final StringBuffer sb = StringBuffer(rirekiMoji(s));
  for (final KinginRirekiGyou g in gyou) {
    sb.write('${g.moji}\n');
  }
  s.name_tanshuku = sb.toString();
  await s.save();
}

/// 今日の日付で1行を作る(大学[univid]、種類[shurui]、金・銀の増減)
KinginRirekiGyou kinginRirekiKyou({
  required int univid,
  required int shurui,
  int kin = 0,
  int gin = 0,
  required String naiyou,
}) {
  final Ghensuu? gh = _gh();
  return KinginRirekiGyou(
    univid: univid,
    shurui: shurui,
    kin: kin,
    gin: gin,
    tsuki: gh?.month ?? 0,
    hi: gh?.day ?? 0,
    naiyou: naiyou,
  );
}

/// 自分の大学の金銀が[maeKin]・[maeGin]から今の保有に変わった分を、1行で足す(変わっていなければ書かない)
/// (受け取ったときと交換のとき。上限9999で止まった分は入らない)
Future<void> kinginRirekiJibun(
  Ghensuu gh, {
  required int maeKin,
  required int maeGin,
  required int shurui,
  required String naiyou,
}) async {
  final int kin = gh.goldenballsuu - maeKin;
  final int gin = gh.silverballsuu - maeGin;
  if (kin == 0 && gin == 0) return;
  await kinginRirekiTsuika([
    kinginRirekiKyou(univid: gh.MYunivid, shurui: shurui, kin: kin, gin: gin, naiyou: naiyou),
  ]);
}

/// 自分の大学の特訓で金銀を[kaisuu]回(1回10)使ったことを、日ごと・金銀ごとに1行にまとめて記録する
/// (kinginKirokuTsuika から呼ぶ。呼び出しが同期なので、文字はすぐに書き換え、保存は待たない。
///  続けて呼ばれても、書き換えは呼んだ順に済んでいるので食い違わない)
void kinginRirekiTokkun({required bool kin, int kaisuu = 1}) {
  final Ghensuu? gh = _gh();
  final UnivData? s = rirekiOkiba(0);
  if (gh == null || s == null || kaisuu <= 0) return;
  final String naiyou = kin ? '金特訓' : '銀特訓';
  final int ryou = -10 * kaisuu;
  final List<String> gyou = rirekiMoji(s).split('\n');
  // 後ろから、同じ日の同じ特訓の行を探して足す
  for (int i = gyou.length - 1; i >= 1; i--) {
    final KinginRirekiGyou? g = KinginRirekiGyou.yomu(gyou[i]);
    if (g == null) continue;
    if (g.univid == gh.MYunivid &&
        g.shurui == kinginTsukatta &&
        g.tsuki == gh.month &&
        g.hi == gh.day &&
        g.naiyou == naiyou) {
      gyou[i] = KinginRirekiGyou(
        univid: g.univid,
        shurui: g.shurui,
        kin: g.kin + (kin ? ryou : 0),
        gin: g.gin + (kin ? 0 : ryou),
        tsuki: g.tsuki,
        hi: g.hi,
        kaisuu: g.kaisuu + kaisuu,
        naiyou: g.naiyou,
      ).moji;
      s.name_tanshuku = gyou.join('\n');
      unawaited(s.save());
      return;
    }
  }
  final KinginRirekiGyou atarashii = KinginRirekiGyou(
    univid: gh.MYunivid,
    shurui: kinginTsukatta,
    kin: kin ? ryou : 0,
    gin: kin ? 0 : ryou,
    tsuki: gh.month,
    hi: gh.day,
    kaisuu: kaisuu,
    naiyou: naiyou,
  );
  s.name_tanshuku = '${rirekiMoji(s)}${atarashii.moji}\n';
  unawaited(s.save());
}

/// 年度替わりに、全大学の年度初めの保有を今年度に書く(名声の履歴をずらしたあとに呼ぶ。RetireNew)
Future<void> kinginRirekiNendoHajime() async {
  final Ghensuu? gh = _gh();
  if (gh == null) return;
  final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  final List<KinginRirekiGyou> gyou = [];
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    final bool jibun = u.id == gh.MYunivid;
    gyou.add(
      KinginRirekiGyou(
        univid: u.id,
        shurui: _kinginNendoHajime,
        kin: jibun ? gh.goldenballsuu : (kantoku == null ? 0 : comKinHoyuu(kantoku, u.id)),
        gin: jibun ? gh.silverballsuu : (kantoku == null ? 0 : comGinHoyuu(kantoku, u.id)),
        tsuki: gh.month,
        hi: gh.day,
        naiyou: '年度初め',
      ),
    );
  }
  await kinginRirekiTsuika(gyou);
}

/// 新しいゲームとリセットのとき(ShokitiUnivdata)。名声の履歴を残すときも金銀の行だけ消し、
/// 今年度に全大学の年度初めの保有を0として書く(金銀はどちらのリセットでも0に戻るため)
Future<void> kinginRirekiReset() async {
  for (int nenmae = 0; nenmae < TEISUU.MEISEIHOZONNENSUU; nenmae++) {
    final UnivData? s = rirekiOkiba(nenmae);
    if (s == null) continue;
    final String moto = s.name_tanshuku;
    final String ato = [
      for (final String g in moto.split('\n'))
        if (!_kinginGyouKa(g)) g,
    ].join('\n');
    if (ato != moto) {
      s.name_tanshuku = ato;
      await s.save();
    }
  }
  final Ghensuu? gh = _gh();
  await kinginRirekiTsuika([
    for (final UnivData u in Hive.box<UnivData>('univBox').values)
      KinginRirekiGyou(
        univid: u.id,
        shurui: _kinginNendoHajime,
        kin: 0,
        gin: 0,
        tsuki: gh?.month ?? 0,
        hi: gh?.day ?? 0,
        naiyou: '年度初め',
      ),
  ]);
}

/// [nenmae]年前(0が今年度)の、大学[univid]の金銀の出入り(記録した順。年度初めの行は入らない)
List<KinginRirekiGyou> kinginRirekiYomu(int nenmae, int univid) {
  final UnivData? s = rirekiOkiba(nenmae);
  if (s == null) return [];
  final List<KinginRirekiGyou> list = [];
  for (final String gyou in s.name_tanshuku.split('\n')) {
    final KinginRirekiGyou? g = KinginRirekiGyou.yomu(gyou);
    if (g != null && g.univid == univid && g.shurui != _kinginNendoHajime) list.add(g);
  }
  return list;
}

/// [nenmae]年前(0が今年度)の、大学[univid]の年度初めの保有(記録がなければnull)
({int kin, int gin})? kinginNendoHajime(int nenmae, int univid) {
  final UnivData? s = rirekiOkiba(nenmae);
  if (s == null) return null;
  ({int kin, int gin})? kekka;
  for (final String gyou in s.name_tanshuku.split('\n')) {
    final KinginRirekiGyou? g = KinginRirekiGyou.yomu(gyou);
    if (g != null && g.univid == univid && g.shurui == _kinginNendoHajime) {
      kekka = (kin: g.kin, gin: g.gin);
    }
  }
  return kekka;
}
