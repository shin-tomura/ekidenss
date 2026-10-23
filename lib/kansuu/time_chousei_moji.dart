import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 全体・区間ごとタイム調整と長距離タイム抑制設定を、1本の行で写す・読む(2.1.4)
// (画面は screens/Modal_TimeChousei.dart の「今の調整値をコピー」「貼り付けて設定」)
//
// 行の形(区間は1区から順に。値は画面と同じ「%」):
//   タイム調整(TC1) 全体+2.0 10月+3.0,-0.5,… 11月… 正月… カスタム… 長距離抑制オン 抑制値0
// ・「TC1」は行の形の印(あとで形を変えても、古い行を見分けられるように)
// ・Xの数え方(日本語は1字を2字)で、一番長くなる場合(全部が−10.0%・カスタム駅伝10区間・抑制値50)でも
//   280字に収まるように、見出しを短くしてある(カスタム駅伝は名前の長さで変わらないように「カスタム」と書く)
// ・読むときは、文の中から「タイム調整(TC1)」の行を探す(前後に感想などの文が付いていてもよい)
//   ・全体と4つの駅伝の並びは必ず要る。値が−10.0〜+10.0の0.5刻みでない、数字が読めない、などのときは
//     読み取れないとして何も変えない
//   ・区間の数が今の区間数と違う駅伝は、その駅伝だけ変えない(画面で知らせる)
//   ・長距離抑制(オン・オフ)と抑制値は、なければその設定を変えない(Xに貼るときに手で削った行も読めるように)
// 保存場所: タイム調整は KantokuData.yobiint5([60]全体、[30〜39]10月・[40〜49]11月・[50〜59]正月・
// [80〜89]カスタム。値は0.5%を1とする整数で−20〜20)、長距離タイム抑制は KantokuData.yobiint2[13](抑制値。
// −18〜50)と大学データ[9]の略称の欄(「1」ならオン)
// ------------------------------------------------------------

/// 行の形の印
const String timeChouseiAtama = 'タイム調整(TC1)';

/// 駅伝の並び(10月・11月・正月・カスタム)の、行の見出しと KantokuData.yobiint5 のはじめの番号
const List<String> timeChouseiRaceMidashi = ['10月', '11月', '正月', 'カスタム'];
const List<int> timeChouseiRaceHajime = [30, 40, 50, 80];

/// 全体タイム調整の KantokuData.yobiint5 の番号
const int timeChouseiZentaiBangou = 60;

/// 長距離全体タイム抑制値の範囲(長距離タイム抑制設定の画面と同じ)
const int choukyoriYokuseiSaishou = -18;
const int choukyoriYokuseiSaidai = 50;

/// 値(0.5%を1とする整数)の「%」の文字(「+3.0」「-0.5」「0.0」)
String timeChouseiAtaiMoji(int v) {
  final String s = (v.abs() / 2.0).toStringAsFixed(1);
  if (v > 0) return '+$s';
  if (v < 0) return '-$s';
  return s;
}

/// 今の設定の行を作る([kukansuu] は駅伝ごとの今の区間数、[yokuseiOn] は長距離タイム抑制補正がオンか)
String timeChouseiMoji(KantokuData k, List<int> kukansuu, bool yokuseiOn) {
  final StringBuffer sb = StringBuffer(timeChouseiAtama);
  sb.write(' 全体${timeChouseiAtaiMoji(k.yobiint5[timeChouseiZentaiBangou])}');
  for (int r = 0; r < timeChouseiRaceMidashi.length; r++) {
    final int n = r < kukansuu.length ? kukansuu[r] : 0;
    sb.write(' ${timeChouseiRaceMidashi[r]}');
    sb.write([
      for (int i = 0; i < n; i++) timeChouseiAtaiMoji(k.yobiint5[timeChouseiRaceHajime[r] + i]),
    ].join(','));
  }
  sb.write(' 長距離抑制${yokuseiOn ? 'オン' : 'オフ'} 抑制値${k.yobiint2[13]}');
  return sb.toString();
}

/// 読み取った行
class TimeChouseiYomi {
  TimeChouseiYomi({
    required this.zentai,
    required this.race,
    required this.yokuseiOn,
    required this.yokuseiAtai,
  });

  /// 全体タイム調整(0.5%を1とする整数)
  final int zentai;

  /// 駅伝ごと(10月・11月・正月・カスタム)の区間の値
  final List<List<int>> race;

  /// 長距離タイム抑制補正のオン・オフ(行になければnull)
  final bool? yokuseiOn;

  /// 長距離全体タイム抑制値(行になければnull)
  final int? yokuseiAtai;
}

/// 「%」の文字を、0.5%を1とする整数にする(−10.0〜+10.0の0.5刻みでなければnull)
int? _atai(String s) {
  final double? d = double.tryParse(s.trim());
  if (d == null) return null;
  final double x = d * 2.0;
  final int v = x.round();
  if ((x - v).abs() > 0.001) return null;
  if (v < -20 || v > 20) return null;
  return v;
}

/// 行の印のあとを読む字数の上限(本物の行は一番長くても300字ほど。とても長い文を貼られても、
/// 読むのに時間やメモリを使いすぎないように、ここまでしか見ない)
const int _gyouSaidai = 500;

/// 文[text]の中の「タイム調整(TC1)」の行を読む(読み取れなければnull。思わぬ失敗もnullにする)
TimeChouseiYomi? timeChouseiYomu(String text) {
  try {
    return _yomu(text);
  } catch (_) {
    return null;
  }
}

TimeChouseiYomi? _yomu(String text) {
  final int a = text.indexOf(timeChouseiAtama);
  if (a < 0) return null;
  final int hajime = a + timeChouseiAtama.length;
  int b = text.indexOf('\n', hajime);
  if (b < 0) b = text.length;
  // 行の印のあとは、上限の字数までしか見ない
  if (b > hajime + _gyouSaidai) b = hajime + _gyouSaidai;
  final String gyou = text.substring(hajime, b);

  // 全体
  final RegExpMatch? z = RegExp(r'全体\s*([+\-]?\d+(?:\.\d+)?)').firstMatch(gyou);
  if (z == null) return null;
  final int? zentai = _atai(z.group(1)!);
  if (zentai == null) return null;

  // 駅伝ごと(「10月」と「11月」を取り違えないように、見出しのすぐ後ろの数字の並びを読む)
  final List<List<int>> race = [];
  for (final String m in timeChouseiRaceMidashi) {
    // (区間が0の駅伝は数字がないこともあるので、空の並びも読む。区間の数は画面の側で今の区間数と比べる)
    final RegExpMatch? g = RegExp('${RegExp.escape(m)}\\s*([+\\-0-9.,]*)').firstMatch(gyou);
    if (g == null) return null;
    final List<int> l = [];
    for (final String t in g.group(1)!.split(',')) {
      if (t.trim().isEmpty) continue;
      // 区間は10まで(11個目が出たら、その時点で読み取れないとする)
      if (l.length >= 10) return null;
      final int? v = _atai(t);
      if (v == null) return null;
      l.add(v);
    }
    race.add(l);
  }

  // 長距離タイム抑制(なければ変えない)
  bool? yokuseiOn;
  final RegExpMatch? y = RegExp(r'長距離抑制\s*(オン|オフ)').firstMatch(gyou);
  if (y != null) yokuseiOn = y.group(1) == 'オン';
  int? yokuseiAtai;
  final RegExpMatch? ya = RegExp(r'抑制値\s*([+\-]?\d+)').firstMatch(gyou);
  if (ya != null) {
    final int? v = int.tryParse(ya.group(1)!);
    if (v == null || v < choukyoriYokuseiSaishou || v > choukyoriYokuseiSaidai) return null;
    yokuseiAtai = v;
  }
  return TimeChouseiYomi(
    zentai: zentai,
    race: race,
    yokuseiOn: yokuseiOn,
    yokuseiAtai: yokuseiAtai,
  );
}
