// ------------------------------------------------------------
// 生成AIに渡すテキストの説明文に、補正の損得と指示の成否を言葉で書き足す(1.8.8)
//
// 説明文(SenshuData.string_racesetumei など)の補正の秒数は「+19.3秒」のような符号だけなので、
// 性能の低い生成AIが、プラスを良い意味に読み違えることがある
// (「指示(前半抑え)補正:+19.3秒」を、指示が成功して19秒得したと読むなど)。
// そこで、コピーするときに、符号のついた秒数のすぐ後に「(タイム損)」「(タイム得)」「(損得なし)」を、
// 指示の行には「指示成功」「指示失敗」も書き足す。
// ・保存してある説明文は変えない(これまでに走ったレースの分にも付く)。画面の表示も変えない
// ・指示(前半突っ込み・前半抑え・スタート直後の飛び出し)の補正は、成功すると必ずマイナス、
//   失敗すると必ずプラスになる(mokuhyou_hosei.dartとRaceCalc.dart)ので、符号から成否が分かる
//   (補正の強さを0%にしていて0.0秒のときは成否が分からないので、「損得なし」だけにする)
// ・「→タイム損(+3.2秒)」のように、もともと損得が書いてある行には書き足さない
// ・「基本走力差」「トータル」の行は、区間(組)で一番の選手との差で、補正ではないので書き足さない
// ------------------------------------------------------------

/// 符号のついた秒数(「+19.3秒」「-8.2秒」)
final RegExp _fugouByou = RegExp(r'([+\-])(\d+(?:\.\d+)?)秒');

/// 指示の補正の行か(成否も書き足す)
bool _sijiGyou(String gyou) {
  return gyou.contains('指示(前半突っ込み)') ||
      gyou.contains('指示(前半抑え)') ||
      gyou.contains('指示(スタート直後飛び出し)') ||
      gyou.startsWith('スタート直後飛び出し補正');
}

/// 補正ではない行か(区間(組)で一番の選手との差)
bool _hoseiIgai(String gyou) {
  return gyou.startsWith('基本走力差') || gyou.startsWith('トータル');
}

/// もともと損得が書いてある行か
bool _sontokuKakiari(String gyou) {
  return gyou.contains('タイム損') ||
      gyou.contains('タイム得') ||
      gyou.contains('損得なし') ||
      gyou.contains('成功') ||
      gyou.contains('失敗');
}

/// 説明文の1行に、損得(と指示の成否)を書き足す
String _gyouSontokuTsuki(String gyou) {
  if (_hoseiIgai(gyou) || _sontokuKakiari(gyou)) return gyou;
  final bool siji = _sijiGyou(gyou);
  return gyou.replaceAllMapped(_fugouByou, (Match m) {
    final double atai = double.tryParse(m.group(2)!) ?? 0.0;
    final String label;
    if (atai < 0.05) {
      label = '損得なし';
    } else if (m.group(1) == '+') {
      label = siji ? '指示失敗・タイム損' : 'タイム損';
    } else {
      label = siji ? '指示成功・タイム得' : 'タイム得';
    }
    return '${m.group(0)}($label)';
  });
}

/// 説明文全体に、損得(と指示の成否)を書き足す(生成AIに渡すテキスト用)
String setsumeiSontokuTsuki(String setumei) {
  return setumei.split('\n').map(_gyouSontokuTsuki).join('\n');
}

/// 説明文の損得の書き足しの説明(説明文が入るコピーの注意書きに足す)
const String setsumeiSontokuChuui =
    '※説明文の秒数の後ろの(タイム損)(タイム得)は、その補正でタイムが遅くなったか速くなったかを表します。'
    '例:「指示(前半抑え)補正:+19.3秒(指示失敗・タイム損)」は、前半抑えの指示が失敗して19.3秒遅くなった(損した)という意味です。\n';
