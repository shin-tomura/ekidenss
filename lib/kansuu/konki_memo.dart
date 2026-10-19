// ------------------------------------------------------------
// 今季タイム一覧表のメモ(2.1.0)
//
// 今季タイム一覧表の名前の右の「メモ」の列に、選手ごとに印か数字を1つ付けられる
// (誰をどの区間に置くかを考えるときのメモ。区間配置とは連動しない。Modal_matrix.dart)。
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

/// 選べるメモ(先頭の空はメモなし。印のあとに数字)
const List<String> konkiMemoSentakushi = [
  '',
  '✓',
  '○',
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
