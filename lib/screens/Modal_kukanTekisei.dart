import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/shushou.dart' show shushouShirushi; // 主将の印
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiKankyou, kmMoji, kukanKihonShumoku;
import 'package:ekiden/kansuu/kiji/kiji_tokuchou.dart' show MochiHyou;
import 'package:ekiden/kansuu/kukan_tekisei.dart';

// ------------------------------------------------------------
// 区間適性の見立て(2.1.1。中身は kukan_tekisei.dart)
// 区間エントリー・当日変更・学連選抜編成(監督をしている年)の画面の緑のリンクから開く。
// ・区間ごと: 区間を選ぶと、出せる選手を区間の距離に合う種目の持ちタイム順に並べ、印と一言を出す
//   (合う度合いの順にすると、遅い選手が上に来てしまうため)
// ・選手ごと: 選手を選ぶと、出す区間ごとの印と一言を出す
// ・名前の横に、画面で選んでいる区間(「1区にエントリー中」「1区に出走予定」)・補欠・体調不良の印を出す
// ・言葉は自分の大学のコーチ(長距離)→コーチ(トラック)→監督の順に、いる人が言う(計算には影響しない)
// ------------------------------------------------------------

/// 見立てに渡すもの(開く画面で作る)
class KukanTekiseiNaiyou {
  /// 大会(学連選抜は正月駅伝の2)
  final int race;

  /// 見立てる大学の選手(選手ごとの一覧は、この並び)
  final List<SenshuData> senshu;

  /// 見立てる学連選抜の選手(学連選抜の監督のとき)
  final List<Senshu_Gakuren_Data> gakuren;

  /// 選手id → 画面で選んでいる区間(0始まり。2つの区間に選んでいることもある)
  final Map<int, List<int>> kukanOf;

  /// 出す区間(0始まり。当日変更では変えられる区間だけ)
  final List<int> kukanList;

  /// 選んでいる区間に添える言葉(「エントリー中」「出走予定」「配置中」)
  final String kukanKotoba;

  /// 区間を選んでいない選手に「補欠」と出すか(当日変更)
  final bool hoketsuHyouji;

  const KukanTekiseiNaiyou({
    required this.race,
    this.senshu = const [],
    this.gakuren = const [],
    required this.kukanOf,
    required this.kukanList,
    required this.kukanKotoba,
    this.hoketsuHyouji = false,
  });
}

/// 区間適性の見立てを開く
void kukanTekiseiHiraku(BuildContext context, KukanTekiseiNaiyou naiyou) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    barrierDismissible: true,
    barrierLabel: '区間適性の見立て',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => ModalKukanTekisei(naiyou: naiyou),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// 「区間適性の見立て」の緑の下線のリンク(ほかのリンクと同じ見た目)
/// [naiyou] 押したときに、見立てに渡すものを作る(画面で選んでいる区間を、押したときの状態で渡すため)
class KukanTekiseiLink extends StatelessWidget {
  final KukanTekiseiNaiyou Function() naiyou;

  const KukanTekiseiLink({super.key, required this.naiyou});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => kukanTekiseiHiraku(context, naiyou()),
      child: const Text(
        "区間適性の見立て",
        style: TextStyle(
          color: Color.fromARGB(255, 0, 255, 0),
          decoration: TextDecoration.underline,
          decorationColor: HENSUU.textcolor,
        ),
      ),
    );
  }
}

class ModalKukanTekisei extends StatefulWidget {
  final KukanTekiseiNaiyou naiyou;

  const ModalKukanTekisei({super.key, required this.naiyou});

  @override
  State<ModalKukanTekisei> createState() => _ModalKukanTekiseiState();
}

class _ModalKukanTekiseiState extends State<ModalKukanTekisei> {
  Ghensuu? _gh;
  MochiHyou? _hyou;
  List<TekiseiSenshu> _senshu = [];
  List<int> _kukanList = [];

  /// 見立てを言う人(「コーチ(長距離)藤巻」など)
  String _kataribe = 'スタッフ';

  /// 区間ごとか(falseなら選手ごと)
  bool _kukanGoto = true;

  /// 区間ごとで選んでいる区間(0始まり)
  int _kukan = 0;

  /// 選手ごとで選んでいる選手のid
  int _senshuId = -1;

  /// 見立ての控え(「選手id-区間」→見立て)
  final Map<String, KukanTekisei> _kekka = {};

  int get _race => widget.naiyou.race;

  @override
  void initState() {
    super.initState();
    final KukanTekiseiNaiyou n = widget.naiyou;
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KijiKankyou? k = KijiKankyou.yomuRace(n.race);
    if (gh == null || k == null) return;
    if (gh.kukansuu_taikaigoto.length <= n.race || gh.kyori_taikai_kukangoto.length <= n.race) return;
    final int kukansuu = gh.kukansuu_taikaigoto[n.race];
    final int kyoriSuu = gh.kyori_taikai_kukangoto[n.race].length;
    final MochiHyou hyou = MochiHyou(k);
    final Map<int, String> univMei = {for (final UnivData u in k.univ) u.id: u.name};
    _gh = gh;
    _hyou = hyou;
    _senshu = [
      for (final SenshuData s in n.senshu) TekiseiSenshu.senshu(s, hyou, soe: shushouShirushi(s)),
      for (final Senshu_Gakuren_Data g in n.gakuren) TekiseiSenshu.gakuren(g, univMei[g.univid] ?? ''),
    ];
    _kukanList = [
      for (final int kk in n.kukanList)
        if (kk >= 0 && kk < kukansuu && kk < kyoriSuu) kk,
    ];
    _kataribe = tekiseiKataribe(k, gh.MYunivid);
    if (_kukanList.isNotEmpty) _kukan = _kukanList.first;
    if (_senshu.isNotEmpty) _senshuId = _senshu.first.id;
  }

  /// 選手[s]が区間[kk]を走るときの見立て(一度見たものは控えておく)
  KukanTekisei _mitate(Ghensuu gh, MochiHyou hyou, TekiseiSenshu s, int kk) {
    return _kekka.putIfAbsent('${s.id}-$kk', () => kukanTekiseiMiru(gh, _race, hyou, s, kk));
  }

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = _gh;
    final MochiHyou? hyou = _hyou;
    final Widget naka;
    if (gh == null || hyou == null || _senshu.isEmpty || _kukanList.isEmpty) {
      naka = const Center(
        child: Text(
          '見立てられる選手がいません',
          style: TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun),
        ),
      );
    } else {
      naka = SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_kataribeの見立て',
              style: const TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '持ちタイムの学生全体での順位と、区間の距離・起伏から見た目安です(ほかの大学の区間配置とは比べていません)。'
              '実際の走りは、記録に表れない力や調子でも変わります。',
              style: TextStyle(color: Colors.white70, fontSize: HENSUU.fontsize_honbun - 2),
            ),
            const SizedBox(height: 4),
            const Text(
              '◎ 合う　○ 問題なし　△ 課題あり　− 記録が足りない',
              style: TextStyle(color: Colors.white70, fontSize: HENSUU.fontsize_honbun - 2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _erabiBotan('区間ごと', _kukanGoto, () => setState(() => _kukanGoto = true)),
                _erabiBotan('選手ごと', !_kukanGoto, () => setState(() => _kukanGoto = false)),
              ],
            ),
            const SizedBox(height: 8),
            if (_kukanGoto) ..._kukanGotoBubun(gh, hyou) else ..._senshuGotoBubun(gh, hyou),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('区間適性の見立て', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: naka),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              "戻る",
              style: TextStyle(fontSize: HENSUU.fontsize_honbun, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// 区間ごと(区間を選ぶボタンと、その区間の選手の並び)
  List<Widget> _kukanGotoBubun(Ghensuu gh, MochiHyou hyou) {
    final int kk = _kukan;
    final int kihon = kukanKihonShumoku(gh, _race, kk);
    // 区間の距離に合う種目の持ちタイム順(記録がなければ後ろ。同じなら元の並び)
    final Map<int, int> motoBan = {for (int i = 0; i < _senshu.length; i++) _senshu[i].id: i};
    final List<TekiseiSenshu> narabi = List<TekiseiSenshu>.of(_senshu)
      ..sort((a, b) {
        final int c = a.times[kihon].compareTo(b.times[kihon]);
        return c != 0 ? c : (motoBan[a.id] ?? 0).compareTo(motoBan[b.id] ?? 0);
      });
    return [
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final int k in _kukanList) _erabiBotan('${k + 1}区', k == kk, () => setState(() => _kukan = k)),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _kukanMidashi(gh, kk),
        style: const TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun, fontWeight: FontWeight.bold),
      ),
      Text(
        '並びは${tekiseiShumokuMei[kihon]}の持ちタイム順',
        style: const TextStyle(color: Colors.white70, fontSize: HENSUU.fontsize_honbun - 2),
      ),
      const SizedBox(height: 4),
      for (final TekiseiSenshu s in narabi)
        _gyou(midashi: s.hyoujiMei, shirushi: _senshuShirushi(s), t: _mitate(gh, hyou, s, kk)),
    ];
  }

  /// 選手ごと(選手を選ぶドロップダウンと、区間ごとの見立て)
  List<Widget> _senshuGotoBubun(Ghensuu gh, MochiHyou hyou) {
    final TekiseiSenshu s = _senshu.firstWhere((x) => x.id == _senshuId, orElse: () => _senshu.first);
    final List<int> erandaKukan = widget.naiyou.kukanOf[s.id] ?? const <int>[];
    return [
      DropdownButton<int>(
        isExpanded: true,
        value: s.id,
        dropdownColor: const Color.fromARGB(255, 30, 30, 30),
        iconEnabledColor: HENSUU.textcolor,
        onChanged: (int? v) {
          if (v != null) setState(() => _senshuId = v);
        },
        items: [
          for (final TekiseiSenshu x in _senshu)
            DropdownMenuItem<int>(
              value: x.id,
              child: Text(
                '${x.taichouFuryou ? '【体調不良】' : ''}${x.hyoujiMei}',
                style: const TextStyle(color: HENSUU.LinkColor, fontSize: HENSUU.fontsize_honbun),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      Wrap(spacing: 6, runSpacing: 4, children: _senshuShirushi(s)),
      const SizedBox(height: 4),
      for (final int kk in _kukanList)
        _gyou(
          midashi: _kukanMidashi(gh, kk),
          shirushi: [
            if (erandaKukan.contains(kk)) _fuda(widget.naiyou.kukanKotoba, Colors.lightBlueAccent),
          ],
          t: _mitate(gh, hyou, s, kk),
        ),
    ];
  }

  /// 区間の見出し(「1区 21.3km・平坦」)
  String _kukanMidashi(Ghensuu gh, int kk) =>
      '${kk + 1}区 ${kmMoji(gh.kyori_taikai_kukangoto[_race][kk])}・${kukanKifukuMei(gh, _race, kk)}';

  /// 選手の名前の横の札(選んでいる区間・補欠・体調不良)
  List<Widget> _senshuShirushi(TekiseiSenshu s) {
    final KukanTekiseiNaiyou n = widget.naiyou;
    final List<int> kukan = n.kukanOf[s.id] ?? const <int>[];
    return [
      if (kukan.isNotEmpty)
        _fuda('${kukan.map((k) => '${k + 1}区').join('・')}に${n.kukanKotoba}', Colors.lightBlueAccent),
      if (kukan.isEmpty && n.hoketsuHyouji) _fuda('補欠', Colors.white70),
      if (s.taichouFuryou) _fuda('体調不良', Colors.redAccent),
    ];
  }

  /// 1人分(または1区間分)の行(見出しと札、印、一言)
  Widget _gyou({required String midashi, required List<Widget> shirushi, required KukanTekisei t}) {
    final TekiseiShirushi? saka = t.saka;
    final String keiken = t.keiken <= 0
        ? '経験 なし'
        : '経験 ${t.keiken}回${t.zenkai == null ? '' : '(前回${t.zenkai})'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                midashi,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...shirushi,
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _shirushiFuda('距離', t.kyori, t.kyoriMei),
              _shirushiFuda('型', t.kata, t.kataMei),
              if (saka != null) _shirushiFuda(t.sakaMei, saka, ''),
              _fuda(keiken, Colors.white70),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '「${t.hitokoto}」',
            style: const TextStyle(color: Colors.white70, fontSize: HENSUU.fontsize_honbun - 2),
          ),
        ],
      ),
    );
  }

  /// 印の札(「距離 ◎ 距離型」。◎は緑、△は黄色、−は暗く)
  Widget _shirushiFuda(String mei, TekiseiShirushi sh, String soe) {
    Color haikei = const Color(0xFF303030);
    Color moji = Colors.white;
    if (sh == TekiseiShirushi.au) {
      haikei = const Color(0xFF1B5E20);
      moji = const Color(0xFFB9F6CA);
    } else if (sh == TekiseiShirushi.kadai) {
      haikei = const Color(0xFF5D4000);
      moji = const Color(0xFFFFE082);
    } else if (sh == TekiseiShirushi.fumei) {
      haikei = const Color(0xFF1E1E1E);
      moji = Colors.white60;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: haikei, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '$mei ${sh.moji}${soe.isEmpty ? '' : ' $soe'}',
        style: TextStyle(color: moji, fontSize: HENSUU.fontsize_honbun - 2),
      ),
    );
  }

  /// 枠付きの札(選んでいる区間・補欠・体調不良・経験)
  Widget _fuda(String moji, Color iro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: iro, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(moji, style: TextStyle(color: iro, fontSize: HENSUU.fontsize_honbun - 3)),
    );
  }

  /// 選ぶボタン(区間ごと・選手ごと、区間の番号。選んでいるものは緑で塗る)
  Widget _erabiBotan(String moji, bool erabu, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: erabu ? const Color(0xFF1B5E20) : Colors.transparent,
        foregroundColor: erabu ? Colors.white : HENSUU.LinkColor,
        side: BorderSide(color: erabu ? Colors.greenAccent : Colors.white38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(44, 36),
      ),
      child: Text(moji, style: const TextStyle(fontSize: HENSUU.fontsize_honbun - 1)),
    );
  }
}
