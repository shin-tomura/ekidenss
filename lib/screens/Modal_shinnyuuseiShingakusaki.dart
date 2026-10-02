import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/scout_com.dart';

// ------------------------------------------------------------
// 「新入生の進学先(全大学)」の画面(1.8.0)
//
// ・今年の新入生(1年生)が、どの大学にどう決まったか(交渉で確定・自ら志望・留学生)を全大学分出す
// ・スカウト終了時のダイアログ(「全大学の新入生を見る」)と、大学画面のリンクから開く
// ・保存されているデータ(選手の大学と、確定・志望の目印)から作るので、スカウトのあと
//   翌年のスカウトまで見られる(スキップ中にスカウトが済んだ年も見られる)
// ・表示は「大学ごと」(初期値)と「選手ごと(タイム順)」を切り替えられる
//   大学ごとは、あなたの大学を先頭に、あとは名声の高い順(初期値)か大学ID順
// ・コンピュータスカウトONでスカウトの途中のときは、進路未定の選手の仮の振り分けの大学は
//   見せない(進学先が決まった選手だけを大学ごとに出し、進路未定の人数を添える)
// ・コンピュータスカウトOFFで入学した年は、確定・志望の区別なしで出す
// ------------------------------------------------------------

/// 表示の種類
enum _HyoujiShurui {
  daigakuGoto, // 大学ごと
  senshuGoto, // 選手ごと(タイム順)
}

/// 大学の並び順(大学ごとのとき。あなたの大学はいつも先頭)
enum _UnivNarabi {
  meiseiJun, // 名声の高い順
  idJun, // 大学ID順
}

/// 新入生の進学先の状態
enum _Joutai {
  kakutei, // 交渉で確定
  shigan, // 自ら志望して入学
  nyuugaku, // 入学(確定・志望の区別なし。OFFで入学した年など)
  ryuugakusei, // 留学生
  mitei, // 進路未定(ONでスカウトの途中)
}

class ModalShinnyuuseiShingakusaki extends StatefulWidget {
  const ModalShinnyuuseiShingakusaki({super.key});

  @override
  State<ModalShinnyuuseiShingakusaki> createState() =>
      _ModalShinnyuuseiShingakusakiState();
}

class _ModalShinnyuuseiShingakusakiState
    extends State<ModalShinnyuuseiShingakusaki> {
  _HyoujiShurui _hyouji = _HyoujiShurui.daigakuGoto;
  _UnivNarabi _narabi = _UnivNarabi.meiseiJun;

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final int myUnivid = gh?.MYunivid ?? -1;

    final List<UnivData> univs = Hive.box<UnivData>('univBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final Map<int, UnivData> univMap = {for (final UnivData u in univs) u.id: u};

    final List<SenshuData> shinnyuusei = Hive.box<SenshuData>(
      'senshuBox',
    ).values.where((s) => s.gakunen == 1).toList();

    // 確定・志望の区別があるか(ONでスカウトの途中か、ONで進学先が決まった選手がいる年)
    final bool scoutChuuOn =
        gh != null &&
        gh.mode == 9000 &&
        kantoku != null &&
        isComScoutOn(kantoku);
    final bool kubetsuAri =
        scoutChuuOn ||
        shinnyuusei.any(
          (s) =>
              s.hirou != 1 && (comScoutKettei(s) || comScoutKotowarareta(s)),
        );

    final Map<int, int> timeJuni = comScoutTimeJuni(shinnyuusei);
    final Map<int, int> meiseiJuni = _meiseiJuniTsukuru(univs);

    // 選手ごとの状態
    final Map<int, _Joutai> joutai = {
      for (final SenshuData s in shinnyuusei)
        s.id: _joutaiKimeru(s, kubetsuAri: kubetsuAri, scoutChuu: scoutChuuOn),
    };
    final int miteiSuu = joutai.values.where((j) => j == _Joutai.mitei).length;

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '新入生の進学先(全大学)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: shinnyuusei.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '新入生のデータがありません。',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            )
          : Column(
              children: [
                _kirikae(),
                Expanded(
                  child: _hyouji == _HyoujiShurui.daigakuGoto
                      ? _daigakuGotoIchiran(
                          univs: univs,
                          shinnyuusei: shinnyuusei,
                          joutai: joutai,
                          timeJuni: timeJuni,
                          meiseiJuni: meiseiJuni,
                          myUnivid: myUnivid,
                          kubetsuAri: kubetsuAri,
                          miteiSuu: miteiSuu,
                        )
                      : _senshuGotoIchiran(
                          univMap: univMap,
                          shinnyuusei: shinnyuusei,
                          joutai: joutai,
                          timeJuni: timeJuni,
                          myUnivid: myUnivid,
                          kubetsuAri: kubetsuAri,
                        ),
                ),
              ],
            ),
    );
  }

  /// 選手の進学先の状態を決める
  /// [kubetsuAri] 確定・志望の区別があるか(ONの年)
  /// [scoutChuu] ONでスカウトの途中か(決まっていない選手は進路未定として、大学を見せない)
  _Joutai _joutaiKimeru(
    SenshuData s, {
    required bool kubetsuAri,
    required bool scoutChuu,
  }) {
    if (s.hirou == 1) return _Joutai.ryuugakusei;
    if (!kubetsuAri) return _Joutai.nyuugaku;
    if (comScoutKakutei(s)) return _Joutai.kakutei;
    if (s.kegaflag == comScoutShiganFlag) return _Joutai.shigan;
    // スカウトの途中で決まっていない選手の大学は、仮の振り分けなので見せない
    if (scoutChuu) return _Joutai.mitei;
    return _Joutai.nyuugaku;
  }

  /// 名声の順位(大学id → 1から。同じ名声は同じ順位。全大学名声一覧と同じ数え方)
  Map<int, int> _meiseiJuniTsukuru(List<UnivData> univs) {
    final List<UnivData> narabi = List.of(univs)
      ..sort((a, b) => b.meisei_total.compareTo(a.meisei_total));
    final Map<int, int> juni = {};
    for (int i = 0; i < narabi.length; i++) {
      if (i > 0 && narabi[i].meisei_total == narabi[i - 1].meisei_total) {
        juni[narabi[i].id] = juni[narabi[i - 1].id]!;
      } else {
        juni[narabi[i].id] = i + 1;
      }
    }
    return juni;
  }

  /// 5000m持ちタイムの良い順(同じなら選手id順)
  int _timeJun(SenshuData a, SenshuData b) {
    final int c = a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  /// 状態の見出し(【確定】など。区別がないときは空)
  String _joutaiMei(_Joutai j) {
    switch (j) {
      case _Joutai.kakutei:
        return '確定';
      case _Joutai.shigan:
        return '志望';
      case _Joutai.ryuugakusei:
        return '留学生';
      case _Joutai.mitei:
        return '進路未定';
      case _Joutai.nyuugaku:
        return '';
    }
  }

  /// 状態ごとの文字の色
  Color _joutaiIro(_Joutai j) {
    switch (j) {
      case _Joutai.kakutei:
        return Colors.cyanAccent;
      case _Joutai.ryuugakusei:
      case _Joutai.mitei:
        return HENSUU.textcolor.withOpacity(0.7);
      case _Joutai.shigan:
      case _Joutai.nyuugaku:
        return HENSUU.textcolor;
    }
  }

  // ------------------------------------------------------------
  // 上部の切り替え
  // ------------------------------------------------------------

  Widget _kirikae() {
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip(
                '大学ごと',
                _hyouji == _HyoujiShurui.daigakuGoto,
                () => setState(() => _hyouji = _HyoujiShurui.daigakuGoto),
              ),
              _chip(
                '選手ごと(タイム順)',
                _hyouji == _HyoujiShurui.senshuGoto,
                () => setState(() => _hyouji = _HyoujiShurui.senshuGoto),
              ),
            ],
          ),
          if (_hyouji == _HyoujiShurui.daigakuGoto)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(
                  '名声の高い順',
                  _narabi == _UnivNarabi.meiseiJun,
                  () => setState(() => _narabi = _UnivNarabi.meiseiJun),
                ),
                _chip(
                  '大学ID順',
                  _narabi == _UnivNarabi.idJun,
                  () => setState(() => _narabi = _UnivNarabi.idJun),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool erabi, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: erabi,
      onSelected: (selected) {
        if (selected) onTap();
      },
      selectedColor: Colors.orange.shade700,
      backgroundColor: Colors.grey.shade800,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  /// 一覧の先頭に出す注意書き(ONでスカウトの途中、またはOFFで入学した年)
  Widget? _chuuiGaki({required bool kubetsuAri, required int miteiSuu}) {
    String? bun;
    if (!kubetsuAri) {
      bun = 'この年の新入生は、コンピュータスカウトOFFで入学したため、確定・志望の区別はありません。';
    } else if (miteiSuu > 0) {
      bun =
          'スカウトの途中です。進学先が決まっていない新入生(進路未定 $miteiSuu人)は、'
          '大学ごとの表示には出していません。';
    }
    if (bun == null) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        bun,
        style: TextStyle(
          color: HENSUU.textcolor.withOpacity(0.7),
          fontSize: HENSUU.fontsize_honbun - 2,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 大学ごと
  // ------------------------------------------------------------

  Widget _daigakuGotoIchiran({
    required List<UnivData> univs,
    required List<SenshuData> shinnyuusei,
    required Map<int, _Joutai> joutai,
    required Map<int, int> timeJuni,
    required Map<int, int> meiseiJuni,
    required int myUnivid,
    required bool kubetsuAri,
    required int miteiSuu,
  }) {
    // あなたの大学を先頭に、あとは名声の高い順(同じ名声は大学ID順)か大学ID順
    final List<UnivData> hoka = univs.where((u) => u.id != myUnivid).toList();
    if (_narabi == _UnivNarabi.meiseiJun) {
      hoka.sort((a, b) {
        final int c = b.meisei_total.compareTo(a.meisei_total);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    }
    final List<UnivData> narabi = [
      ...univs.where((u) => u.id == myUnivid),
      ...hoka,
    ];
    final Widget? chuui = _chuuiGaki(
      kubetsuAri: kubetsuAri,
      miteiSuu: miteiSuu,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: narabi.length + (chuui == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (chuui != null && index == 0) return chuui;
        final UnivData u = narabi[chuui == null ? index : index - 1];
        // この大学の新入生(進路未定の選手は出さない)を、確定→志望→入学→留学生の順に、それぞれタイム順で
        final List<SenshuData> senshu =
            shinnyuusei
                .where((s) => s.univid == u.id && joutai[s.id] != _Joutai.mitei)
                .toList()
              ..sort((a, b) {
                final int c = joutai[a.id]!.index.compareTo(
                  joutai[b.id]!.index,
                );
                return c != 0 ? c : _timeJun(a, b);
              });
        return _univCard(
          u: u,
          senshu: senshu,
          joutai: joutai,
          timeJuni: timeJuni,
          meiseiJuni: meiseiJuni,
          jibun: u.id == myUnivid,
          kubetsuAri: kubetsuAri,
        );
      },
    );
  }

  Widget _univCard({
    required UnivData u,
    required List<SenshuData> senshu,
    required Map<int, _Joutai> joutai,
    required Map<int, int> timeJuni,
    required Map<int, int> meiseiJuni,
    required bool jibun,
    required bool kubetsuAri,
  }) {
    final int kakutei = senshu
        .where((s) => joutai[s.id] == _Joutai.kakutei)
        .length;
    final int shigan = senshu
        .where((s) => joutai[s.id] == _Joutai.shigan)
        .length;
    final int ryuugakusei = senshu
        .where((s) => joutai[s.id] == _Joutai.ryuugakusei)
        .length;
    final String ninzuu = kubetsuAri
        ? '確定$kakutei 志望$shigan${ryuugakusei > 0 ? ' 留学生$ryuugakusei' : ''}'
        : '新入生${senshu.length}人${ryuugakusei > 0 ? '(留学生$ryuugakusei人)' : ''}';

    return Card(
      color: jibun ? const Color(0xFF1A1F26) : const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: jibun ? Colors.amber : Colors.white12,
          width: jibun ? 2.0 : 1.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 大学名と名声の順位・人数(入りきらなければ折り返す)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  jibun ? '${u.name}大学(あなたの大学)' : '${u.name}大学',
                  style: TextStyle(
                    color: jibun ? Colors.amber : HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '名声${meiseiJuni[u.id] ?? '-'}位  $ninzuu',
                  style: TextStyle(
                    color: HENSUU.textcolor.withOpacity(0.7),
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (senshu.isEmpty)
              Text(
                '(まだ進学先が決まった新入生はいません)',
                style: TextStyle(
                  color: HENSUU.textcolor.withOpacity(0.6),
                  fontSize: HENSUU.fontsize_honbun - 2,
                ),
              ),
            for (final SenshuData s in senshu)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _senshuGyou(s, joutai[s.id]!, timeJuni),
                  style: TextStyle(
                    color: _joutaiIro(joutai[s.id]!),
                    fontSize: HENSUU.fontsize_honbun - 1,
                    fontWeight: joutai[s.id] == _Joutai.kakutei
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 大学ごとの表示の、選手の1行(例: 【確定】○○選手(5000m 14分05秒・新入生の中で3位))
  String _senshuGyou(SenshuData s, _Joutai j, Map<int, int> timeJuni) {
    final String mei = _joutaiMei(j);
    final String time = comScoutTimeMoji(s.kiroku_nyuugakuji_5000);
    final int? juni = timeJuni[s.id]; // 留学生は順位なし
    return '${mei.isEmpty ? '' : '【$mei】'}${s.name}選手'
        '(5000m $time${juni == null ? '' : '・新入生の中で$juni位'})';
  }

  // ------------------------------------------------------------
  // 選手ごと(タイム順)
  // ------------------------------------------------------------

  Widget _senshuGotoIchiran({
    required Map<int, UnivData> univMap,
    required List<SenshuData> shinnyuusei,
    required Map<int, _Joutai> joutai,
    required Map<int, int> timeJuni,
    required int myUnivid,
    required bool kubetsuAri,
  }) {
    // 日本人の新入生をタイム順に、そのあとに留学生をタイム順に
    final List<SenshuData> narabi = [
      ...(shinnyuusei.where((s) => s.hirou != 1).toList()..sort(_timeJun)),
      ...(shinnyuusei.where((s) => s.hirou == 1).toList()..sort(_timeJun)),
    ];
    final Widget? chuui = _chuuiGaki(kubetsuAri: kubetsuAri, miteiSuu: 0);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: narabi.length + (chuui == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (chuui != null && index == 0) return chuui;
        final SenshuData s = narabi[chuui == null ? index : index - 1];
        final _Joutai j = joutai[s.id]!;
        // 進路未定の選手は、仮の振り分けの大学を見せない
        final bool jibun = j != _Joutai.mitei && s.univid == myUnivid;
        final int? juni = timeJuni[s.id];
        final String mei = _joutaiMei(j);
        final String shingakusaki;
        if (j == _Joutai.mitei) {
          shingakusaki = '進路未定';
        } else {
          final String univMei = univMap[s.univid]?.name ?? '不明';
          shingakusaki =
              '$univMei大学${jibun ? '(あなたの大学)' : ''}'
              '${mei.isEmpty ? '' : '【$mei】'}';
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  juni == null ? '留学生' : '$juni位',
                  style: TextStyle(
                    color: HENSUU.textcolor.withOpacity(0.7),
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.name}選手(5000m ${comScoutTimeMoji(s.kiroku_nyuugakuji_5000)})',
                      style: TextStyle(
                        color: jibun ? Colors.amber : HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun - 1,
                        fontWeight: jibun ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '→ $shingakusaki',
                      style: TextStyle(
                        color: jibun ? Colors.amber : _joutaiIro(j),
                        fontSize: HENSUU.fontsize_honbun - 2,
                        fontWeight: j == _Joutai.kakutei
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
