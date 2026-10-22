// ------------------------------------------------------------
// 今季タイム一覧表のメモ(2.1.0)
//
// 今季タイム一覧表の名前の右の「メモ」の列に、選手ごとに印か数字を1つ付けられる
// (誰をどの区間に置くかを考えるときのメモ。Modal_matrix.dart)。
// ・区間配置とは連動しないが、区間エントリーの画面から開いた自分の大学の表では、見出しの「メモ」を押して
//   「メモどおり配置する」を選ぶと、数字のメモ(1〜10)をその区間に配置できる(2.1.2。memoHaichiKeikaku)
// ・保存場所は SenshuData.name_tanshuku(金銀の記録と同じ欄。kingin_kiroku.dart)の最後の行。
//   「#メモ:○」の形で、メモがなければ行を付けない。金銀の記録は「#金銀」で始まる文字の
//   「学年:」で始まる行だけを読むので、この行は読み飛ばされる。金銀の記録を書き直すとき
//   (kinginKirokuTsuika)は、この行を残す
// ・項目の型も番号も変えずに中身の文字を使うだけなので、今までのセーブデータもそのまま読める
// ・選手についていく(どの大学の表でも、学連選抜の表でも、同じ選手なら同じメモ)。
//   選手のデータを新入生に作り直すとき(SenshuShokiti.dart)と、選手のQRコードで置き換えたときは、
//   金銀の記録と一緒に消える。卒業生のデータ(Senshu_R_Data)と学連選抜のデータにも写るが、使わない
// ・画面の表だけに出し、画像・テキストのコピー・CSVには入れない
// ------------------------------------------------------------

import 'package:ekiden/senshu_data.dart';

/// 選べるメモ(先頭の空はメモなし。印のあとに数字)
const List<String> konkiMemoSentakushi = [
  '',
  '✓',
  '○',
  '△',
  '×',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
];

/// メモの行の見出し(この文字で始まる行がメモ)
const String _midashi = '#メモ:';

/// [text](選手の短縮名)からメモを読む(なければ空)
String konkiMemoYomu(String text) {
  for (final String gyou in text.split('\n')) {
    if (gyou.startsWith(_midashi)) return gyou.substring(_midashi.length);
  }
  return '';
}

/// [text](選手の短縮名)のメモを[memo]にした文字を返す
/// (空ならメモの行を消す。金銀の記録などのほかの行はそのまま)
String konkiMemoIreru(String text, String memo) {
  final List<String> gyou = [
    for (final String g in text.split('\n'))
      if (!g.startsWith(_midashi)) g,
  ];
  if (memo.isNotEmpty) gyou.add('$_midashi$memo');
  return gyou.join('\n');
}

// ------------------------------------------------------------
// メモどおり配置する(2.1.2)
// 区間エントリーの画面(mode0300_content.dart)から開いた今季タイム一覧表で、自分の大学を表示しているときに、
// 見出しの「メモ」から選べる。数字のメモの選手を、その番号の区間に選ぶ(区間エントリーの画面の選択
// (Ghensuu.SenshuSelectedOption)を書き換えるだけで、エントリーを決めるのは今まで通り「進む」)。
// ・メモのない区間は今のまま(区間エントリーの画面は、空いた区間を作れないため)
// ・同じ数字が2人以上・区間の数より大きい数字・一次エントリーで選んでいない選手は、その区間を変えず、
//   確かめる窓に理由を出す(✓・○・△・×は使わない)
// ・メモで動かした選手が、メモのない区間などにも残るときは、そのまま残し(区間エントリーの画面に赤字の重複で出る)、
//   確かめる窓にも書く(押し出された選手を自動で入れ替えると、思わぬ配置になりやすいため)
// ・メモは配置しても消さない
// ------------------------------------------------------------

/// 区間エントリーの画面(mode0300_content.dart の _getGakunenJunUnivFilteredSenshuData)と同じ選手の並び
/// (大学[univId]の、大会[race]の一次エントリーで選んだ選手(entrykukan_race が-2でない)を、学年の高い順、
/// 同じ学年はidの順)。SenshuSelectedOption はこの並びの番号なので、並べ方を変えるときは両方を直す(2.1.2)
List<SenshuData> kukanEntryNarabi(Iterable<SenshuData> zenbu, int univId, int race) {
  final List<SenshuData> l = [
    for (final SenshuData s in zenbu)
      if (s.univid == univId && s.entrykukan_race[race][s.gakunen - 1] != -2) s,
  ];
  l.sort((a, b) {
    final int c = b.gakunen.compareTo(a.gakunen);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return l;
}

/// メモどおり配置したときの、新しい選択と、確かめる窓に出す行(2.1.2)
class MemoHaichiKeikaku {
  /// 新しい選択(区間ごとに、kukanEntryNarabi の並びの番号。区間の数の分)
  final List<int> atarashii;

  /// 変わる区間(「1区　谷口 陸 → 北村 蒼」)
  final List<String> henkou;

  /// もうメモどおりの区間(「2区は、もう森川 悠斗です」)
  final List<String> sudeni;

  /// 変えない区間の理由と、重複(赤字で出す)
  final List<String> chuui;

  /// メモのない区間(「メモのない区間(4区・6〜10区)は、今のままです」。なければ空)
  final String nashi;

  const MemoHaichiKeikaku(this.atarashii, this.henkou, this.sudeni, this.chuui, this.nashi);
}

/// 区間の番号(0始まり、小さい順)を「4区・6〜10区」の形にする(3つ以上続けば「〜」でまとめる)
String _kukanMatome(List<int> kk) {
  final List<String> bubun = [];
  int i = 0;
  while (i < kk.length) {
    int j = i;
    while (j + 1 < kk.length && kk[j + 1] == kk[j] + 1) {
      j++;
    }
    if (j - i >= 2) {
      bubun.add('${kk[i] + 1}〜${kk[j] + 1}区');
    } else {
      for (int t = i; t <= j; t++) {
        bubun.add('${kk[t] + 1}区');
      }
    }
    i = j + 1;
  }
  return bubun.join('・');
}

/// メモどおり配置したときの選択を作る(2.1.2)
/// [narabi] 区間エントリーの画面の選手の並び(kukanEntryNarabi)、[jibun] 表に出ている自分の大学の選手
/// (一次エントリーで選んでいない選手のメモも見るため)、[ima] 今の選択(SenshuSelectedOption)、[kukansuu] 区間の数
MemoHaichiKeikaku memoHaichiKeikaku({
  required List<SenshuData> narabi,
  required List<SenshuData> jibun,
  required List<int> ima,
  required int kukansuu,
}) {
  int? bangou(SenshuData s) => int.tryParse(konkiMemoYomu(s.name_tanshuku));
  String mei(int ban) => ban >= 0 && ban < narabi.length ? narabi[ban].name : '(なし)';
  final Set<int> narabiId = {for (final SenshuData s in narabi) s.id};
  final List<int> atarashii = [
    for (int kk = 0; kk < kukansuu; kk++) kk < ima.length ? ima[kk] : 0,
  ];
  final List<String> henkou = [];
  final List<String> sudeni = [];
  final List<String> chuui = [];
  final List<int> memoNashi = [];
  final Set<int> kaeta = {};
  // 区間の数より大きい数字と、一次エントリーで選んでいない選手
  for (final SenshuData s in jibun) {
    final int? n = bangou(s);
    if (n == null) continue;
    if (n < 1 || n > kukansuu) {
      chuui.add('${s.name}の「$n」は、この大会に$n区がないので配置しません');
    } else if (!narabiId.contains(s.id)) {
      chuui.add('${s.name}は一次エントリーで選んでいないので、$n区に配置しません');
    }
  }
  for (int kk = 0; kk < kukansuu; kk++) {
    final List<int> kouho = [
      for (int i = 0; i < narabi.length; i++)
        if (bangou(narabi[i]) == kk + 1) i,
    ];
    if (kouho.isEmpty) {
      memoNashi.add(kk);
      continue;
    }
    if (kouho.length >= 2) {
      chuui.add(
        '${kk + 1}区はメモが${kouho.length}人(${kouho.map((i) => narabi[i].name).join('・')})なので、変えません',
      );
      continue;
    }
    final int ban = kouho.first;
    if (atarashii[kk] == ban) {
      sudeni.add('${kk + 1}区は、もう${narabi[ban].name}です');
      continue;
    }
    henkou.add('${kk + 1}区　${mei(atarashii[kk])} → ${narabi[ban].name}');
    atarashii[kk] = ban;
    kaeta.add(kk);
  }
  // メモで動かした選手が、ほかの区間にも残っているか(区間エントリーの画面に赤字の重複で出る)
  for (int kk = 0; kk < kukansuu; kk++) {
    if (!kaeta.contains(kk)) continue;
    final int ban = atarashii[kk];
    final List<int> hoka = [
      for (int k = 0; k < kukansuu; k++)
        if (k != kk && atarashii[k] == ban) k,
    ];
    if (hoka.isNotEmpty) {
      chuui.add('${narabi[ban].name}は${_kukanMatome(hoka)}にも残ります(区間エントリーの画面に赤字で出ます)');
    }
  }
  final String nashi = memoNashi.isEmpty || memoNashi.length >= kukansuu
      ? ''
      : 'メモのない区間(${_kukanMatome(memoNashi)})は、今のままです';
  return MemoHaichiKeikaku(atarashii, henkou, sudeni, chuui, nashi);
}
