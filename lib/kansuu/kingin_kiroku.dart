import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou; // 選手画面などの表

// ------------------------------------------------------------
// 金銀の記録(1.9.9)
//
// 夏合宿の金特訓・銀特訓で、誰のどの能力を何回(1回+10)上げたかを、選手ごとに学年ごとに記録する。
// プレイヤーの大学(選手画面と夏合宿の画面の金特訓・銀特訓)も、コンピュータの大学(goldsilver_com.dart)も記録する。
// 選手画面・他大学の選手の詳細・卒業生の画面に学年ごと能力ごとの表(kinginKirokuHyou)で出し、
// 夏合宿の日の結果画面(mode0700_content.dart)に、自分の大学の選手の一覧表(kinginIchiranHyou)で出す。
// 大学画面(univ_screen.dart)の一番下にも、表示している大学の選手の一覧表を常に出す(2.0.0)。
// (夏合宿の画面 9100Gashuku.dart の「これまで」の行は、その画面が今は使われていないので表示されない)
//
// ・保存場所は SenshuData.name_tanshuku(選手の短縮名)。選手を作ったときの「短縮」のままで、
//   画面にも計算にも使っていなかったことを確かめた(大学の短縮名 UnivData.name_tanshuku とは別)。
//   項目の型も番号も変えずに中身の文字を使うだけなので、今までのセーブデータもそのまま読める
// ・卒業のときに卒業生のデータ(Senshu_R_Data.name_tanshuku)へそのまま写るので、卒業生の画面でも読める。
//   学連選抜のデータ(Senshu_Gakuren_Data)にも写るが、そちらでは使わない
// ・選手のデータは、卒業した4年生の枠を次の新入生に作り直して使い回すので、作り直すとき
//   (SenshuShokiti.dart)と、選手のQRコードで別の選手に置き換えたときに、記録を消す(kinginKirokuNashi に戻す)
// ・書き方: 1行目は見出し「#金銀」、2行目から1学年1行で「学年:能力の番号=回数,能力の番号=回数」
//   (例「#金銀\n2:0=2,3=1\n3:1=1」)。見出しのない文字列(初期値の「短縮」など)は、記録なしとみなす
// ・能力の番号は Ghensuu.nouryokumieruflag と同じ(0駅伝男 1平常心 2長距離粘り 3スパート力 4カリスマ
//   5登り適性 6下り適性 7アップダウン対応力 8ロード適性 9ペース変動対応力)で、10を安定感にした
// ・この版より前に使った金銀は記録がないので分からない
// ------------------------------------------------------------

/// 記録がないときの値(選手を作ったときの短縮名と同じ)
const String kinginKirokuNashi = '短縮';

/// 記録の見出し(この文字列で始まるものだけを記録とみなす)
const String _midashi = '#金銀';

/// 安定感の番号(nouryokumieruflag にない番号を使う)
const int kinginAnteikan = 10;

/// 表示する能力の並び(金の駅伝男・平常心・安定感、銀の長距離粘り〜ペース変動対応力)
const List<int> kinginNouryokuNarabi = [0, 1, kinginAnteikan, 2, 3, 4, 5, 6, 7, 8, 9];

/// 金特訓で上げる能力か(駅伝男・平常心・安定感。ほかは銀特訓)
bool kinginKinNouryoku(int bangou) =>
    bangou == 0 || bangou == 1 || bangou == kinginAnteikan;

/// 能力の名前(番号は上の決まり)
String kinginNouryokuMei(int bangou) {
  switch (bangou) {
    case 0:
      return '駅伝男';
    case 1:
      return '平常心';
    case 2:
      return '長距離粘り';
    case 3:
      return 'スパート力';
    case 4:
      return 'カリスマ';
    case 5:
      return '登り適性';
    case 6:
      return '下り適性';
    case 7:
      return 'アップダウン対応力';
    case 8:
      return 'ロード適性';
    case 9:
      return 'ペース変動対応力';
    case kinginAnteikan:
      return '安定感';
    default:
      return '';
  }
}

/// 金銀で上がる能力の値(番号順。0〜10。上がった能力を見分けるのに使う)
List<int> kinginNouryokuAtai(SenshuData s) => [
  s.konjou,
  s.heijousin,
  s.choukyorinebari,
  s.spurtryoku,
  s.karisuma,
  s.noboritekisei,
  s.kudaritekisei,
  s.noborikudarikirikaenouryoku,
  s.tandokusou,
  s.paceagesagetaiouryoku,
  s.anteikan,
];

/// [text](選手の短縮名)から、学年ごとの、能力ごとの回数を読む(記録がなければ空)
Map<int, Map<int, int>> kinginKirokuYomu(String text) {
  final Map<int, Map<int, int>> kiroku = {};
  if (!text.startsWith(_midashi)) return kiroku;
  for (final String gyou in text.split('\n').skip(1)) {
    final int koron = gyou.indexOf(':');
    if (koron <= 0) continue;
    final int? gakunen = int.tryParse(gyou.substring(0, koron));
    if (gakunen == null) continue;
    for (final String kou in gyou.substring(koron + 1).split(',')) {
      final List<String> p = kou.split('=');
      if (p.length != 2) continue;
      final int? bangou = int.tryParse(p[0]);
      final int? kaisuu = int.tryParse(p[1]);
      if (bangou == null || kaisuu == null || kaisuu <= 0) continue;
      final Map<int, int> m = kiroku.putIfAbsent(gakunen, () => {});
      m[bangou] = (m[bangou] ?? 0) + kaisuu;
    }
  }
  return kiroku;
}

/// [text](選手の短縮名)の記録を学年を合わせて、能力ごとの回数にする(記録がなければ空)
Map<int, int> kinginKirokuGoukei(String text) {
  final Map<int, int> goukei = {};
  for (final Map<int, int> m in kinginKirokuYomu(text).values) {
    m.forEach((b, k) {
      if (k > 0) goukei[b] = (goukei[b] ?? 0) + k;
    });
  }
  return goukei;
}

/// 記録を短縮名の文字にする
String _kaku(Map<int, Map<int, int>> kiroku) {
  final List<int> gakunenNarabi = kiroku.keys.toList()..sort();
  final StringBuffer sb = StringBuffer(_midashi);
  for (final int g in gakunenNarabi) {
    final Map<int, int> m = kiroku[g]!;
    final List<int> bangouNarabi = m.keys.toList()..sort();
    final List<String> kou = [
      for (final int b in bangouNarabi)
        if ((m[b] ?? 0) > 0) '$b=${m[b]}',
    ];
    if (kou.isEmpty) continue;
    sb.write('\n$g:${kou.join(',')}');
  }
  return sb.toString();
}

/// 選手[s]の今の学年に、能力[bangou]を金銀で[kaisuu]回(1回+10)上げたことを記録する
/// (選手の保存は呼び出し側で行う。学年が1〜4でなければ記録しない)
void kinginKirokuTsuika(SenshuData s, int bangou, {int kaisuu = 1}) {
  if (s.gakunen < 1 || s.gakunen > 4 || kaisuu <= 0) return;
  if (kinginNouryokuMei(bangou).isEmpty) return;
  final Map<int, Map<int, int>> kiroku = kinginKirokuYomu(s.name_tanshuku);
  final Map<int, int> m = kiroku.putIfAbsent(s.gakunen, () => {});
  m[bangou] = (m[bangou] ?? 0) + kaisuu;
  s.name_tanshuku = _kaku(kiroku);
}

/// [mae](金銀を使う前の kinginNouryokuAtai)と比べて上がった能力を、10上がるごとに1回として記録する
/// (コンピュータの大学の金銀。どの能力が上がるかは使う処理の中で決まるので、前後の値で見分ける)
void kinginKirokuSabun(SenshuData s, List<int> mae) {
  final List<int> ato = kinginNouryokuAtai(s);
  for (int b = 0; b < ato.length && b < mae.length; b++) {
    final int kaisuu = (ato[b] - mae[b]) ~/ 10;
    if (kaisuu > 0) kinginKirokuTsuika(s, b, kaisuu: kaisuu);
  }
}

/// 記録の文(「2年 駅伝男+20、スパート力+10 / 3年 平常心+10」。記録がなければ空)
String kinginKirokuBun(String text) {
  final Map<int, Map<int, int>> kiroku = kinginKirokuYomu(text);
  final List<int> gakunenNarabi = kiroku.keys.toList()..sort();
  final List<String> gyou = [];
  for (final int g in gakunenNarabi) {
    final Map<int, int> m = kiroku[g]!;
    final List<String> kou = [
      for (final int b in kinginNouryokuNarabi)
        if ((m[b] ?? 0) > 0) '${kinginNouryokuMei(b)}+${m[b]! * 10}',
    ];
    if (kou.isNotEmpty) gyou.add('$g年 ${kou.join('、')}');
  }
  return gyou.join(' / ');
}

/// 選手画面・他大学の選手の詳細・卒業生の画面の表(行は上げた能力、列は記録のある学年と合計。
/// 合計の列は学年が2つ以上のときだけ。記録がなければnull)
KijiHyou? kinginKirokuHyou(String text) {
  final Map<int, Map<int, int>> kiroku = kinginKirokuYomu(text);
  final List<int> gakunenNarabi = kiroku.keys
      .where((g) => kiroku[g]!.values.any((k) => k > 0))
      .toList()
    ..sort();
  if (gakunenNarabi.isEmpty) return null;
  final Map<int, int> goukei = kinginKirokuGoukei(text);
  final bool goukeiAri = gakunenNarabi.length >= 2;
  final List<List<String>> gyou = [
    for (final int b in kinginNouryokuNarabi)
      if ((goukei[b] ?? 0) > 0)
        [
          kinginNouryokuMei(b),
          for (final int g in gakunenNarabi)
            (kiroku[g]![b] ?? 0) > 0 ? '+${kiroku[g]![b]! * 10}' : '',
          if (goukeiAri) '+${goukei[b]! * 10}',
        ],
  ];
  return KijiHyou('金銀で伸ばした能力', [
    '能力',
    for (final int g in gakunenNarabi) '$g年',
    if (goukeiAri) '合計',
  ], gyou);
}

/// 1つの大学の選手の一覧表(夏合宿の日の結果画面と大学画面。2.0.0で結果画面の中から移した)
/// [senshuList](1つの大学の選手)のうち、金特訓・銀特訓をしたことのある選手を、選手画面と同じ並び
/// (学年の高い順、同じならidの順)で並べ、使った金・銀の量と、能力ごとの合計を出す
/// (列は、誰かが上げたことのある能力だけ。学年ごとの内訳は kinginKirokuHyou の表に出る)。
/// 記録のある選手がいなければnull
KijiHyou? kinginIchiranHyou(Iterable<SenshuData> senshuList) {
  final List<SenshuData> narabi = senshuList.toList()
    ..sort((a, b) {
      final int g = b.gakunen.compareTo(a.gakunen);
      return g != 0 ? g : a.id.compareTo(b.id);
    });
  final List<SenshuData> kirokuAri = [];
  final List<Map<int, int>> goukeiList = [];
  final Set<int> agetaNouryoku = {};
  for (final SenshuData s in narabi) {
    final Map<int, int> goukei = kinginKirokuGoukei(s.name_tanshuku);
    if (goukei.isEmpty) continue;
    kirokuAri.add(s);
    goukeiList.add(goukei);
    agetaNouryoku.addAll(goukei.keys);
  }
  if (kirokuAri.isEmpty) return null;
  final List<int> retsu = [
    for (final int b in kinginNouryokuNarabi)
      if (agetaNouryoku.contains(b)) b,
  ];
  final List<List<String>> gyou = [];
  for (int i = 0; i < kirokuAri.length; i++) {
    final SenshuData s = kirokuAri[i];
    final Map<int, int> goukei = goukeiList[i];
    int kin = 0;
    int gin = 0;
    goukei.forEach((b, k) {
      if (kinginKinNouryoku(b)) {
        kin += k;
      } else {
        gin += k;
      }
    });
    gyou.add([
      '${s.name}(${s.gakunen})',
      kin > 0 ? '${kin * 10}' : '-',
      gin > 0 ? '${gin * 10}' : '-',
      for (final int b in retsu)
        (goukei[b] ?? 0) > 0 ? '+${goukei[b]! * 10}' : '',
    ]);
  }
  return KijiHyou('金特訓・銀特訓の記録', [
    '選手',
    '金',
    '銀',
    for (final int b in retsu) kinginNouryokuMei(b),
  ], gyou);
}

/// 一覧表の下の注記([jibun]は自分の大学の表か。ほかの大学の選手の内訳は、選手の詳細で見る)
String kinginIchiranChuu({required bool jibun}) =>
    '能力ごとの合計です。学年ごとの内訳は、${jibun ? '選手画面' : '選手の詳細'}の「金銀で伸ばした能力」で見られます。';
