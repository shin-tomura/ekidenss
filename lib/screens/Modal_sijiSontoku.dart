import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/siji_sontoku.dart';
import 'package:ekiden/kansuu/siji_sontoku_text.dart'; // 画面と生成AI向けで同じ文(1.8.8)

/// 「指示ごとの損得予測」の画面(1.8.1)
/// 駅伝の2区以降で、走り出す直前の選手の、指示なし・前半突っ込み・前半抑えそれぞれの
/// タイムの損得(成功時・失敗時)を「約○秒」で出す。計算は siji_sontoku.dart
/// 各指示の枠の「この指示にする」で、この画面から指示を選べる(1.8.8)
class ModalSijiSontokuView extends StatefulWidget {
  final int senshuId;

  /// レース画面で選んでいる指示(0指示なし、1前半突っ込み、2前半抑え。それ以外は印を付けない)
  final int sentakuchuu;

  /// 学連選抜の選手か(学連選抜の監督をしているとき。1.8.2)
  final bool gakuren;

  /// 「この指示にする」を押したときに呼ぶ処理(0指示なし、1前半突っ込み、2前半抑え。1.8.8)
  /// 保存先が大学(Ghensuu.SijiSelectedOption)と学連選抜(選手のsijiflag)で違うので、
  /// 開く側(レース画面)がドロップダウンと同じ保存の処理を渡す。渡さないときは見るだけの画面
  final Future<void> Function(int bangou)? onSijiSentaku;

  const ModalSijiSontokuView({
    super.key,
    required this.senshuId,
    this.sentakuchuu = -1,
    this.gakuren = false,
    this.onSijiSentaku,
  });

  @override
  State<ModalSijiSontokuView> createState() => _ModalSijiSontokuViewState();
}

class _ModalSijiSontokuViewState extends State<ModalSijiSontokuView> {
  late final Future<SijiSontoku?> _keisan;

  /// 今選んでいる指示(この画面で選び直すと変わる。1.8.8)
  late int _sentakuchuu;

  /// 指示を保存している間(ボタンを続けて押せないようにする)
  bool _hozonChuu = false;

  static const Color _sonColor = Colors.redAccent;
  static const Color _tokuColor = Colors.lightBlueAccent;

  @override
  void initState() {
    super.initState();
    _sentakuchuu = widget.sentakuchuu;
    // 乱数を使わない計算なので、開いたときに1回だけ計算する
    _keisan = widget.gakuren
        ? sijiSontokuKeisanGakuren(widget.senshuId)
        : sijiSontokuKeisan(widget.senshuId);
  }

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final int kukan = gh?.nowracecalckukan ?? 0;
    final SenshuData? senshu = Hive.box<SenshuData>('senshuBox').values
        .where((s) => s.id == widget.senshuId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: Text(
          '${kukan + 1}区 指示ごとの損得予測',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<SijiSontoku?>(
        future: _keisan,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final SijiSontoku? sontoku = snapshot.data;
          if (snapshot.hasError || sontoku == null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '損得を計算できませんでした。',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senshu != null)
                  Text(
                    '${senshu.name}(${senshu.gakunen}年)',
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  sijiSontokuJoukyouBun(sontoku, gakuren: widget.gakuren),
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
                const SizedBox(height: 16),
                _sijiCard(
                  bangou: 0,
                  midashi: '指示なし',
                  gyou: [_nashiGyou(sontoku)],
                ),
                _sijiCard(
                  bangou: 1,
                  midashi: '前半から突っ込む',
                  seikouritsu: '成功率${sontoku.tsukkomiSeikouritsu}%(駅伝男)',
                  gyou: [
                    _sontokuGyou('成功', sontoku.tsukkomiSeikou),
                    _sontokuGyou('失敗', sontoku.tsukkomiShippai),
                  ],
                ),
                _sijiCard(
                  bangou: 2,
                  midashi: '前半は抑える',
                  seikouritsu: '成功率${sontoku.osaeSeikouritsu}%(平常心)',
                  gyou: [
                    _sontokuGyou('成功', sontoku.osaeSeikou),
                    _sontokuGyou('失敗', sontoku.osaeShippai),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$sijiSontokuChuuiByousuu\n'
                  '$sijiSontokuChuuiSeikouritsu\n'
                  '$sijiSontokuChuuiHosei',
                  style: TextStyle(
                    color: HENSUU.textcolor.withOpacity(0.8),
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
                // この画面から指示を選べるとき(1.8.8)
                if (widget.onSijiSentaku != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '・「この指示にする」を押すと、レース画面の指示の欄も同じ指示に変わります。',
                      style: TextStyle(
                        color: HENSUU.textcolor.withOpacity(0.8),
                        fontSize: HENSUU.fontsize_honbun - 2,
                      ),
                    ),
                  ),
                // 学連選抜の選手には、指示の補正のあとにモチベーション低下補正がかかる(1.8.2)
                if (widget.gakuren && sijiSontokuMotivationHoseiAri())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sijiSontokuChuuiMotivation,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: HENSUU.fontsize_honbun - 2,
                      ),
                    ),
                  ),
                // 補正の強さを初期値から変えているときは、数字が違う理由が分かるように一言出す(1.8.2)
                if (sontoku.tsuyosaHenkouChuu)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sijiSontokuChuuiTsuyosa,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: HENSUU.fontsize_honbun - 2,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 指示なしの行(理由も付ける。補正の強さが0%で損得がないときは理由を出さない)
  Widget _nashiGyou(SijiSontoku s) {
    final String riyuu = sijiSontokuNashiRiyuu(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sontokuGyou('', s.nashi),
        if (riyuu.isNotEmpty)
          Text(
            riyuu,
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.7),
              fontSize: HENSUU.fontsize_honbun - 3,
            ),
          ),
      ],
    );
  }

  /// 「成功:約38秒の得」のような1行
  Widget _sontokuGyou(String label, double byou) {
    final String atai = sijiSontokuAtai(byou);
    Color iro = HENSUU.textcolor;
    if (byou != 0.0) {
      iro = byou > 0 ? _sonColor : _tokuColor;
    }
    return Text.rich(
      TextSpan(
        children: [
          if (label.isNotEmpty)
            TextSpan(
              text: '$label:',
              style: TextStyle(color: HENSUU.textcolor),
            ),
          TextSpan(
            text: atai,
            style: TextStyle(color: iro, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      style: const TextStyle(fontSize: HENSUU.fontsize_honbun),
    );
  }

  /// 指示1つ分の枠(選んでいる指示は枠の色を変えて「選択中」と出す)
  /// この画面から指示を選べるときは、選んでいない枠に「この指示にする」ボタンを出す(1.8.8)
  Widget _sijiCard({
    required int bangou,
    required String midashi,
    String seikouritsu = '',
    required List<Widget> gyou,
  }) {
    final bool sentakuchuu = _sentakuchuu == bangou;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sentakuchuu ? Colors.amber : Colors.white24,
          width: sentakuchuu ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                midashi,
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (seikouritsu.isNotEmpty)
                Text(
                  seikouritsu,
                  style: TextStyle(
                    color: HENSUU.textcolor.withOpacity(0.8),
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
              if (sentakuchuu)
                const Text(
                  '選択中',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...gyou,
          if (widget.onSijiSentaku != null && !sentakuchuu)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _hozonChuu ? null : () => _sijiSentaku(bangou),
                child: Text(
                  'この指示にする',
                  style: TextStyle(
                    color: HENSUU.LinkColor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 「この指示にする」を押したとき(1.8.8)
  /// 開く側から渡された処理で保存し、画面は開いたまま「選択中」の印を移す
  Future<void> _sijiSentaku(int bangou) async {
    final Future<void> Function(int)? hozon = widget.onSijiSentaku;
    if (hozon == null) return;
    setState(() => _hozonChuu = true);
    try {
      await hozon(bangou);
      if (mounted) setState(() => _sentakuchuu = bangou);
    } finally {
      if (mounted) setState(() => _hozonChuu = false);
    }
  }
}
