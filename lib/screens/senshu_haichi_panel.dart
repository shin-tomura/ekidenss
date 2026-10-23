// ------------------------------------------------------------
// 区間配置確認の選手のカードの部品(2.0.7で Modal_kukanhaiti2.dart から切り出した。中身と見た目は同じ)
// ・カードの上の行(区間の札・名前・学年・「詳細」)と、カードを開いたときの中身(駅伝男・平常心・調子・
//   この区間の経験回数と、持ちタイムの行)。大学の選手と学連選抜(OP)の選手の2つの形がある
// ・区間配置確認のカードと画像の書き出し、区間終了時点の位置関係(Modal_ichiKankei.dart)の
//   「次の区間を走る選手」で使う
// ・2.1.0から、情報集約パネルで大学の四角を2回押したときの、走り終わった選手の能力の行
//   (senshuNouryokuZenbu・gakurenNouryokuZenbu)もここに置く
// ・大会は区間配置確認と同じく gh.hyojiracebangou。持ちタイムを今季ベストで表示しているときは、
//   [konki] に今季ベストの順位表を渡す(自己ベストのときはnull)
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/kukannai_juni.dart'; // 持ちタイムの区間内順位(1.8.8)
import 'package:ekiden/kansuu/konki_best.dart'; // 今季ベスト(1.9.1)
import 'package:ekiden/screens/Modal_senshu.dart';

/// カードの上の行(区間の札・名前・学年・「詳細」。「詳細」を押すと選手の詳細の画面を開く)
Widget senshuHaichiTitle(
  BuildContext context, {
  required String fuda,
  required Color fudaIro,
  required String mei,
  required int gakunen,
  required int shousaiId,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: fudaIro.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          fuda,
          style: TextStyle(
            color: fudaIro,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          mei,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Text(
        "$gakunen年",
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      TextButton(
        onPressed: () => senshuShousaiHiraku(context, shousaiId),
        child: Text(
          '詳細',
          style: TextStyle(color: HENSUU.LinkColor, fontSize: 15),
        ),
      ),
    ],
  );
}

/// 学連選抜(OP)の選手の能力の行(駅伝男・平常心・調子・この区間の経験回数。[kukanIdx]はその選手の区間)
Widget gakurenNouryokuRan(Ghensuu gh, Senshu_Gakuren_Data g, int kukanIdx) {
  // 前の学年までに正月駅伝の同じ区間を走った回数(所属大学で走ったもの)
  int keikenkaisuu = 0;
  for (int i_gakunen = 0; i_gakunen < g.gakunen - 1; i_gakunen++) {
    if (g.entrykukan_race[gh.hyojiracebangou][i_gakunen] == kukanIdx) {
      keikenkaisuu++;
    }
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _nouryokuKoumoku(
          "駅伝男",
          gh.nouryokumieruflag[0] == 1 ? "${g.konjou}" : "??",
        ),
        _nouryokuKoumoku(
          "平常心",
          gh.nouryokumieruflag[1] == 1 ? "${g.heijousin}" : "??",
        ),
        _nouryokuKoumoku("調子", "${g.chousi}"),
        if (keikenkaisuu > 0)
          _nouryokuKoumoku("この区間の経験回数", "$keikenkaisuu"),
      ],
    ),
  );
}

/// 学連選抜(OP)の選手の持ちタイムの行([konki] は今季ベストで表示しているときの順位表。自己ベストのときはnull)
Widget gakurenKirokuRan(Ghensuu gh, Senshu_Gakuren_Data g, KonkiBestJuni? konki) {
  final List<Map<String, dynamic>> records = [
    {'label': '5千best', 'idx': 0, 'showRank': true},
    {'label': '1万', 'idx': 1, 'showRank': true},
    {'label': 'ハーフ', 'idx': 2, 'showRank': true},
    {'label': '登り1万', 'idx': 4, 'showRank': false},
    {'label': '下り1万', 'idx': 5, 'showRank': false},
    {'label': 'ロード1万', 'idx': 6, 'showRank': false},
    {'label': 'クロカン1万', 'idx': 7, 'showRank': false},
  ];
  return Column(
    children: records
        .map(
          (r) => _gakurenKirokuGyou(
            gh,
            g,
            konki,
            r['label'],
            r['idx'],
            r['showRank'],
          ),
        )
        .toList(),
  );
}

// 学連選抜(OP)の選手の持ちタイムの行(「区」は○位相当。1.8.2)
Widget _gakurenKirokuGyou(
  Ghensuu gh,
  Senshu_Gakuren_Data g,
  KonkiBestJuni? konki,
  String label,
  int idx,
  bool showRank,
) {
  // 今季ベストで表示しているときは、タイムも順位も今季ベスト(1.9.1)
  final double jikoBest = g.time_bestkiroku.length > idx
      ? g.time_bestkiroku[idx]
      : TEISUU.DEFAULTTIME;
  final double time = konki != null ? konkiBestGakuren(g, idx) : jikoBest;
  final bool hasRecord = time < TEISUU.DEFAULTTIME;
  final int kukanJuni = gakurenKukanJuniSoutou(g, idx, gh, konki: konki);
  // 学連選抜の選手の中での順位(所属大学の中の順位の「学」の代わりに出す。1.8.8)
  final int renJuni = gakurenNaiJuni(g, idx, konki: konki != null);
  final int zentaiJuni = !hasRecord
      ? 0
      : (konki != null
            ? konki.zentai(time, idx)
            : g.zentaijuni_bestkiroku[idx] + 1);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        if (!hasRecord)
          _kirokuNashi(konki != null, jikoBest, idx)
        else ...[
          Text(
            TimeDate.timeToFunByouString(time),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                // タイムトライアルの4種目も、区間を走る大学の選手全員に記録があれば出す(1.8.8)
                if (kukanJuni > 0) _juniFudaBun("区", "$kukanJuni相当"),
                if (renJuni > 0) _juniFuda("連", renJuni),
                // 夏の学内タイムトライアルの4種目も、全選手の中での順位を出す(2.1.4。どの大学も同じ条件で走るため)
                _juniFuda("全", zentaiJuni),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// 順位のタグ(数字の代わりに文を出す。学連選抜の「○相当」で使う。1.8.2)
Widget _juniFudaBun(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white30),
      borderRadius: BorderRadius.circular(5),
      color: Colors.white.withOpacity(0.05),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    ),
  );
}

/// 選手の詳細の画面を開く
void senshuShousaiHiraku(BuildContext context, int senshuId) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    barrierDismissible: true,
    barrierLabel: '詳細',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ModalSenshuDetailView(senshuId: senshuId),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// 大学の選手の能力の行(駅伝男・平常心・調子・この区間の経験回数)
/// [kukanAri]がfalse(補欠など)なら、この区間の経験回数は出さない(1.9.9)
Widget senshuNouryokuRan(
  Ghensuu gh,
  SenshuData s, {
  bool kukanAri = true,
}) {
  //過去に同じ区間を走ったことがあるかどうかの表示
  int keikenkaisuu = 0;
  for (
    int i_gakunen = 0;
    kukanAri && i_gakunen < s.gakunen - 1;
    i_gakunen++
  ) {
    if (s.entrykukan_race[gh.hyojiracebangou][i_gakunen] ==
        s.entrykukan_race[gh.hyojiracebangou][s.gakunen - 1]) {
      keikenkaisuu++;
    }
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12, // アイテム間の横の隙間
      runSpacing: 8, // 折り返した時の行間の隙間
      children: [
        _nouryokuKoumoku(
          "駅伝男",
          gh.nouryokumieruflag[0] == 1 ? "${s.konjou}" : "??",
        ),
        _nouryokuKoumoku(
          "平常心",
          gh.nouryokumieruflag[1] == 1 ? "${s.heijousin}" : "??",
        ),
        _nouryokuKoumoku("調子", "${s.chousi}"),
        if (keikenkaisuu > 0) _nouryokuKoumoku("この区間の経験回数", "$keikenkaisuu"),
      ],
    ),
  );
}

/// 能力の名前(番号は Ghensuu.nouryokumieruflag と同じ。0駅伝男 1平常心 2長距離粘り 3スパート力 4カリスマ
/// 5登り適性 6下り適性 7アップダウン対応力 8ロード適性 9ペース変動対応力。2.1.0)
const List<String> _nouryokuMei = [
  '駅伝男',
  '平常心',
  '長距離粘り',
  'スパート力',
  'カリスマ',
  '登り適性',
  '下り適性',
  'アップダウン対応力',
  'ロード適性',
  'ペース変動対応力',
];

/// 走り終わった大学の選手の能力の行(2.1.0。情報集約パネルで、大学の四角を2回押したときに説明文の下に出す)
/// 区間配置確認の能力の行(駅伝男・平常心・調子)に、今季タイム一覧表の右の走りの能力(安定感・長距離粘り〜
/// ペース変動対応力)を足したもの。まだ見抜いていない能力は「??」(調子と安定感はいつも出す)。
/// 大会[race]の[kukanIdx]区を走った選手で、それより前の学年に同じ区間を走ったことがあれば、その回数も出す
Widget senshuNouryokuZenbu(
  Ghensuu gh,
  SenshuData s, {
  required int race,
  required int kukanIdx,
}) {
  return _nouryokuZenbu(
    gh,
    [
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
    ],
    chousi: s.chousi,
    anteikan: s.anteikan,
    keiken: _maeKeikenKaisuu(s.entrykukan_race, s.gakunen, race, kukanIdx),
  );
}

/// 走り終わった学連選抜(OP)の選手の能力の行(senshuNouryokuZenbu と同じ中身。調子は学連選抜で走ったときの調子)
Widget gakurenNouryokuZenbu(
  Ghensuu gh,
  Senshu_Gakuren_Data g, {
  required int race,
  required int kukanIdx,
}) {
  return _nouryokuZenbu(
    gh,
    [
      g.konjou,
      g.heijousin,
      g.choukyorinebari,
      g.spurtryoku,
      g.karisuma,
      g.noboritekisei,
      g.kudaritekisei,
      g.noborikudarikirikaenouryoku,
      g.tandokusou,
      g.paceagesagetaiouryoku,
    ],
    chousi: g.chousi,
    anteikan: g.anteikan,
    keiken: _maeKeikenKaisuu(g.entrykukan_race, g.gakunen, race, kukanIdx),
  );
}

/// 今の学年より前に、大会[race]の[kukanIdx]区を走った回数
int _maeKeikenKaisuu(List<List<int>> entry, int gakunen, int race, int kukanIdx) {
  if (race < 0 || race >= entry.length || kukanIdx < 0) return 0;
  int kaisuu = 0;
  for (int i = 0; i < gakunen - 1 && i < entry[race].length; i++) {
    if (entry[race][i] == kukanIdx) kaisuu++;
  }
  return kaisuu;
}

/// 能力の行の中身([atai] は _nouryokuMei の順の値)
/// 1行に1つずつ縦に並べ、数字は名前のすぐ右(スペース1つ)に出す(どの能力の数字か分かりやすいように。2.1.0)。
/// 名前と数字が1行に入らなければ、数字を次の行に回す(_nouryokuGyou)
Widget _nouryokuZenbu(
  Ghensuu gh,
  List<int> atai, {
  required int chousi,
  required int anteikan,
  required int keiken,
}) {
  String mieru(int b) =>
      (b < gh.nouryokumieruflag.length && gh.nouryokumieruflag[b] == 1) ? '${atai[b]}' : '??';
  final List<Widget> gyou = [
    // この区間の経験回数は一番上に出す(前に走ったことがあるかが、まず目に入るように。2.1.0)
    if (keiken > 0) _nouryokuGyou('この区間の経験回数', '$keiken'),
    _nouryokuGyou(_nouryokuMei[0], mieru(0)),
    _nouryokuGyou(_nouryokuMei[1], mieru(1)),
    _nouryokuGyou('調子', '$chousi'),
    _nouryokuGyou('安定感', '$anteikan'),
    for (int b = 2; b < _nouryokuMei.length; b++) _nouryokuGyou(_nouryokuMei[b], mieru(b)),
  ];
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < gyou.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          gyou[i],
        ],
      ],
    ),
  );
}

/// 走り終わった選手の能力の1行(「長距離粘り 81」。2.1.0)
/// 名前は情報集約パネルの説明文と同じ色と大きさ、数字は白の太字(区間配置確認のカードのオレンジの数字
/// (_nouryokuKoumoku)とは分けて、説明文に続けて読みやすい色にする)。入りきらなければ数字を次の行に回す
Widget _nouryokuGyou(String label, String value) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        "$label ",
        style: TextStyle(
          color: HENSUU.textcolor.withOpacity(0.9),
          fontSize: 12.5,
          decoration: TextDecoration.none,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: HENSUU.textcolor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

// --- 各アイテムの定義 ---
Widget _nouryokuKoumoku(String label, String value) {
  // アイテム内も Row ではなく Wrap にすることで、
  // 「ラベル名：値」が1行に収まらないほど長い場合にも対応できます
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        "$label ",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          decoration: TextDecoration.none,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

/// 大学の選手の持ちタイムの行([konki] は今季ベストで表示しているときの順位表。自己ベストのときはnull)
/// [kukanAri]がfalse(補欠など)なら、区間内の順位(「区」)は出さない(1.9.9)
Widget senshuKirokuRan(
  Ghensuu gh,
  SenshuData s,
  KonkiBestJuni? konki, {
  bool kukanAri = true,
}) {
  List<Map<String, dynamic>> records = [
    if (gh.hyojiracebangou != 4)
      {'label': '5千best', 'idx': 0, 'showRank': true},
    {'label': '1万', 'idx': 1, 'showRank': true},
    {'label': 'ハーフ', 'idx': 2, 'showRank': true},
    if (gh.hyojiracebangou != 4)
      {'label': '登り1万', 'idx': 4, 'showRank': false},
    if (gh.hyojiracebangou != 4)
      {'label': '下り1万', 'idx': 5, 'showRank': false},
    {'label': 'ロード1万', 'idx': 6, 'showRank': false},
    if (gh.hyojiracebangou != 4)
      {'label': 'クロカン1万', 'idx': 7, 'showRank': false},
  ];
  return Column(
    children: records
        .map(
          (r) => _kirokuGyou(
            gh,
            s,
            konki,
            r['label'],
            r['idx'],
            r['showRank'],
            kukanAri: kukanAri,
          ),
        )
        .toList(),
  );
}

/// [showRank] がfalseの行は夏の学内タイムトライアルの4種目(「区」は、その区間を走る選手全員に記録があるときだけ
/// 出す)。2.1.3までは「全」も出さなかったが、2.1.4から、どの種目も「全」を出す
Widget _kirokuGyou(
  Ghensuu gh,
  SenshuData s,
  KonkiBestJuni? konki,
  String label,
  int idx,
  bool showRank, {
  bool kukanAri = true,
}) {
  if (konki != null) {
    return _konkiKirokuGyou(gh, s, label, idx, showRank, konki);
  }
  final bool hasRecord = s.time_bestkiroku[idx] != TEISUU.DEFAULTTIME;
  // 夏の学内タイムトライアルの4種目は、その区間を走る選手全員に記録があるときだけ
  // 区間内順位も出す(0なら出さない。1.8.8)
  final int ttKukanJuni = (hasRecord && !showRank && kukanAri)
      ? kukannaiJuni(s, idx, gh.hyojiracebangou)
      : 0;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        if (!hasRecord)
          const Text(
            "記録無",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          )
        else ...[
          Text(
            TimeDate.timeToFunByouString(s.time_bestkiroku[idx]),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (showRank) ...[
                  if (kukanAri) _juniFuda("区", s.kukannaijuni[idx] + 1),
                  _juniFuda("学", s.gakunaijuni_bestkiroku[idx] + 1),
                  _juniFuda("全", s.zentaijuni_bestkiroku[idx] + 1),
                ] else ...[
                  if (ttKukanJuni > 0) _juniFuda("区", ttKukanJuni),
                  _juniFuda("学", s.gakunaijuni_bestkiroku[idx] + 1),
                  // 夏の学内タイムトライアルの4種目も、全選手の中での順位を出す(2.1.4)
                  _juniFuda("全", s.zentaijuni_bestkiroku[idx] + 1),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// 今季ベストで表示しているときの持ちタイムの行(1.9.1)
// 「区」はその区間を走る選手、「学」は大学の選手、「全」は全選手の中での今季ベストの順位
// (夏の学内タイムトライアルの4種目の「区」は、自己ベストのときと同じく、
//  その区間を走る選手全員に今季の記録があるときだけ出す)
Widget _konkiKirokuGyou(
  Ghensuu gh,
  SenshuData s,
  String label,
  int idx,
  bool showRank,
  KonkiBestJuni konki,
) {
  final double time = konki.best(s, idx);
  final bool hasRecord = time < TEISUU.DEFAULTTIME;
  int kukanJuni = 0;
  final int race = gh.hyojiracebangou;
  if (hasRecord &&
      s.gakunen >= 1 &&
      s.entrykukan_race.length > race &&
      s.entrykukan_race[race].length >= s.gakunen) {
    final int kukan = s.entrykukan_race[race][s.gakunen - 1];
    if (kukan >= 0) {
      kukanJuni = konki.hikakuJuni(
        time,
        idx,
        kukanHashiruSenshu(race, kukan),
        zenninHitsuyou: !showRank,
      );
    }
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        if (!hasRecord)
          _kirokuNashi(true, s.time_bestkiroku[idx], idx)
        else ...[
          Text(
            TimeDate.timeToFunByouString(time),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (kukanJuni > 0) _juniFuda("区", kukanJuni),
                _juniFuda("学", konki.gakunai(time, idx, s.univid)),
                // 夏の学内タイムトライアルの4種目も、全選手の中での順位を出す(2.1.4)
                _juniFuda("全", konki.zentai(time, idx)),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// 持ちタイムの記録がないときの文([konki]がtrueなら、今季の記録がないことと参考の自己ベスト。1.9.1)
Widget _kirokuNashi(bool konki, double jikoBest, int idx) {
  return Expanded(
    child: Text(
      konki ? konkiKirokuNashiBun(jikoBest, idx) : "記録無",
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 13,
        decoration: TextDecoration.none,
      ),
    ),
  );
}

Widget _juniFuda(String label, int rank) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white30),
      borderRadius: BorderRadius.circular(5),
      color: Colors.white.withOpacity(0.05),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          "$rank",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    ),
  );
}
