import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/koukou.dart' show koukouIchiranMoji; // 監督の出身校
import 'package:ekiden/kansuu/bokou_pipe.dart'
    show bokouPipeNashi, bokouPipeJibunKiku; // 監督の母校パイプ(2.0.1)
import 'package:ekiden/kansuu/scout_com.dart' show isComScoutOn;

// ------------------------------------------------------------
// 監督・コーチの交代予定(2.0.6。4月5日、新入生のスカウトの前に出す画面。mode 8990)
//
// ・監督・コーチは今まで通り年度替わり(RetireNew.dart)で選び直し、スカウトにはもう新しい監督の
//   母校が効く。プレイヤーにとってスカウトまでは3月なので、この画面では「4月から代わる予定」
//   として知らせ、母校パイプはこのスカウトから新しい監督の母校で効くことを短く書く
//   (卒業生の履歴欄の「4月 就任」とも合う)。日付は出さない
// ・出すのは、スキップしていないとき(main.dart の mode 2000 で、スカウトの画面(mode 9000)の前)で、
//   自分の大学の席か、ほかの大学の監督の席に変更があった年だけ(kantokuKoutaiYoteiAri)。
//   席が代わった印は KantokuData.yobiint1(年度替わりで立てる。4月5日の画面のお知らせと同じ印)
// ・下の画面切り替えは出さない(スカウトの画面と同じく、この画面だけの MaterialApp で出す)
// ・ほかの大学は、母校パイプで取り合いに関わる監督だけを出す(コーチは出さない)
// ・この画面で終了しても、起動し直して「続きから再開」を選ぶと、この画面に戻る
// ・「スカウトへ進む」は画面の一番下に固定し、上の中身だけをスクロールする(2.1.0。交代が多いと、
//   ボタンがスクロールしないと見えず、迷わせそうだったため)。中身が続くと分かるように、右端に
//   白っぽいスクロールバーを出す(情報集約パネルと同じ。黒い背景で見えるように)
// ------------------------------------------------------------

/// 交代予定の画面のモード
const int kantokuKoutaiYoteiMode = 8990;

/// 交代予定の画面を出す年か(自分の大学の3つの席か、ほかの大学の監督の席に変更があった)
bool kantokuKoutaiYoteiAri(KantokuData k, int myUnivid) {
  const int n = TEISUU.UNIVSUU;
  if (k.yobiint1.length < n * 3 || k.rid.length < n * 3) return false;
  if (myUnivid >= 0 && myUnivid < n) {
    for (int seki = 0; seki < 3; seki++) {
      if (k.yobiint1[myUnivid + n * seki] == 1) return true;
    }
  }
  for (int u = 0; u < n; u++) {
    if (u != myUnivid && k.yobiint1[u] == 1 && k.rid[u] > 0) return true;
  }
  return false;
}

class KantokuKoutaiYoteiView extends StatefulWidget {
  const KantokuKoutaiYoteiView({super.key});

  @override
  State<KantokuKoutaiYoteiView> createState() => _KantokuKoutaiYoteiViewState();
}

/// 自分の大学の席1つ分
class _Seki {
  final String sekiMei;
  final String mei; // 空なら不在
  final int nenrei;
  final String koukou; // 監督の出身校(監督の席だけ。分からないとき・出さない設定のときは空)
  final bool kawaru;
  const _Seki(this.sekiMei, this.mei, this.nenrei, this.koukou, this.kawaru);
}

/// ほかの大学の新しい監督1人分
class _Hoka {
  final String univMei;
  final String mei;
  final int nenrei;
  final String koukou;
  const _Hoka(this.univMei, this.mei, this.nenrei, this.koukou);
}

class _KantokuKoutaiYoteiViewState extends State<KantokuKoutaiYoteiView> {
  static const List<String> _sekiMei = ['監督', 'コーチ(トラック)', 'コーチ(長距離)'];
  static const TextStyle _honbun = TextStyle(
    color: HENSUU.textcolor,
    fontSize: HENSUU.fontsize_honbun,
  );
  static const TextStyle _hosoku = TextStyle(
    color: Colors.white70,
    fontSize: HENSUU.fontsize_honbun - 2,
  );

  Ghensuu? _ghensuu;
  String _myUnivMei = '';
  List<_Seki> _jibun = const [];
  List<_Hoka> _hoka = const [];
  bool _pipeKiku = false;
  bool _pipeJibunKiku = true;
  bool _susunda = false; // ボタンの二度押しを防ぐ

  /// 中身の縦のスクロール(右端のスクロールバーのため。2.1.0)
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    try {
      _yomu();
    } catch (_) {
      // 作れなかったときは、ボタンだけの画面にする(スカウトには進める)
    }
  }

  void _yomu() {
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    _ghensuu = gh;
    final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    if (k == null) return;
    const int n = TEISUU.UNIVSUU;

    final Map<int, String> univMei = {
      for (final UnivData u in Hive.box<UnivData>('univBox').values) u.id: u.name,
    };
    final Map<int, Senshu_R_Data> ob = {
      for (final Senshu_R_Data r in Hive.box<Senshu_R_Data>('retiredSenshuBox').values) r.id: r,
    };
    final int my = gh.MYunivid;
    _myUnivMei = univMei[my] ?? '';

    // 自分の大学の3つの席
    final List<_Seki> jibun = [];
    for (int seki = 0; seki < 3; seki++) {
      final int i = my + n * seki;
      if (my < 0 || i >= k.rid.length || i >= k.yobiint1.length) break;
      final Senshu_R_Data? r = k.rid[i] > 0 ? ob[k.rid[i]] : null;
      if (r == null) {
        jibun.add(_Seki(_sekiMei[seki], '', 0, '', false));
      } else {
        jibun.add(_Seki(
          _sekiMei[seki],
          r.name,
          gh.year - r.sijiflag + 22,
          seki == 0 ? koukouIchiranMoji(r.samusataisei, r.hirou, k) : '',
          k.yobiint1[i] == 1,
        ));
      }
    }
    _jibun = jibun;

    // 監督が代わる予定のほかの大学(大学idの順)
    final List<_Hoka> hoka = [];
    for (int u = 0; u < n && u < k.rid.length && u < k.yobiint1.length; u++) {
      if (u == my || k.yobiint1[u] != 1 || k.rid[u] <= 0) continue;
      final Senshu_R_Data? r = ob[k.rid[u]];
      if (r == null) continue;
      hoka.add(_Hoka(
        univMei[u] ?? '',
        r.name,
        gh.year - r.sijiflag + 22,
        koukouIchiranMoji(r.samusataisei, r.hirou, k),
      ));
    }
    _hoka = hoka;

    // 母校パイプの説明を出すか(コンピュータスカウトONで、設定が「なし」でないとき)
    _pipeKiku = isComScoutOn(k) && !bokouPipeNashi(k);
    _pipeJibunKiku = bokouPipeJibunKiku(k);
  }

  Future<void> _susumu() async {
    if (_susunda) return;
    _susunda = true;
    final Ghensuu? gh = _ghensuu ?? Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return;
    gh.mode = 9000; // 新入生のスカウトの画面へ
    await gh.save();
  }

  // 席の名前・名前と年齢・印のかたまりで折り返す(文字を大きくしても、はみ出さないように)
  Widget _sekiGyou(_Seki s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(s.sekiMei, style: _hosoku),
              if (s.mei.isEmpty)
                const Text('不在', style: _honbun)
              else
                Text('${s.mei}(${s.nenrei}歳)', style: _honbun),
              if (s.mei.isNotEmpty && s.kawaru)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '就任予定',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: HENSUU.fontsize_honbun - 3,
                    ),
                  ),
                )
              else if (s.mei.isNotEmpty)
                const Text(
                  '続投',
                  style: TextStyle(color: Colors.grey, fontSize: HENSUU.fontsize_honbun - 3),
                ),
            ],
          ),
          if (s.koukou.isNotEmpty) Text('出身校: ${s.koukou}', style: _hosoku),
        ],
      ),
    );
  }

  Widget _hokaGyou(_Hoka h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        children: [
          Text('${h.univMei}大学', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
          Text('${h.mei}(${h.nenrei}歳)', style: _honbun),
          if (h.koukou.isNotEmpty) Text('出身校: ${h.koukou}', style: _hosoku),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body: SafeArea(
        child: Column(
          children: [
            // 中身(ここだけスクロールする。2.1.0)
            Expanded(
              child: RawScrollbar(
                controller: _scroll,
                thumbVisibility: true,
                interactive: true,
                thickness: 6,
                radius: const Radius.circular(3),
                thumbColor: Colors.white54,
                minThumbLength: 40,
                child: ScrollConfiguration(
                  // デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '監督・コーチの交代予定',
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun + 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('4月から、次のように監督・コーチが代わる予定です。', style: _honbun),
                        const SizedBox(height: 16),
                        if (_jibun.isNotEmpty) ...[
                          Text('${_myUnivMei}大学(あなたの大学)', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(color: Colors.grey),
                          for (final _Seki s in _jibun) _sekiGyou(s),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 12),
                        ],
                        if (_hoka.isNotEmpty) ...[
                          Text('監督が代わる予定の大学', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(color: Colors.grey),
                          for (final _Hoka h in _hoka) _hokaGyou(h),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 12),
                        ],
                        if (_pipeKiku) ...[
                          Text(
                            _pipeJibunKiku
                                ? '・監督の母校の新入生は、スカウトでその大学を選びやすくなります。'
                                : '・ほかの大学の監督の母校の新入生は、スカウトでその大学を選びやすくなります。',
                            style: _hosoku,
                          ),
                          const Text(
                            '・今回のスカウトから、新しい監督の母校で効きます(去ると決まった監督の母校には効きません)。',
                            style: _hosoku,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 「スカウトへ進む」は一番下に固定する(交代が多くても、いつも見えるように。2.1.0)
            const Divider(height: 1, color: Colors.white24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Center(
                child: ElevatedButton(
                  onPressed: _susumu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HENSUU.buttonColor,
                    foregroundColor: HENSUU.buttonTextColor,
                    minimumSize: const Size(200, 44),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'スカウトへ進む',
                    style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
