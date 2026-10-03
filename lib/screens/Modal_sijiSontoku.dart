import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/siji_sontoku.dart';
import 'package:ekiden/album.dart';

/// 「指示ごとの損得予測」の画面(1.8.1)
/// 駅伝の2区以降で、走り出す直前の選手の、指示なし・前半突っ込み・前半抑えそれぞれの
/// タイムの損得(成功時・失敗時)を「約○秒」で出す。計算は siji_sontoku.dart
class ModalSijiSontokuView extends StatefulWidget {
  final int senshuId;

  /// レース画面で選んでいる指示(0指示なし、1前半突っ込み、2前半抑え。それ以外は印を付けない)
  final int sentakuchuu;

  /// 学連選抜の選手か(学連選抜の監督をしているとき。1.8.2)
  final bool gakuren;

  const ModalSijiSontokuView({
    super.key,
    required this.senshuId,
    this.sentakuchuu = -1,
    this.gakuren = false,
  });

  @override
  State<ModalSijiSontokuView> createState() => _ModalSijiSontokuViewState();
}

class _ModalSijiSontokuViewState extends State<ModalSijiSontokuView> {
  late final Future<SijiSontoku?> _keisan;

  static const Color _sonColor = Colors.redAccent;
  static const Color _tokuColor = Colors.lightBlueAccent;

  @override
  void initState() {
    super.initState();
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
                  _joukyouBun(sontoku),
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
                  '・秒数は、この選手のこの区間の見込みタイムから計算したものです。実際の補正とは1秒ほどずれることがあります。\n'
                  '・成功率は、前半突っ込みは駅伝男、前半抑えは平常心の値と同じです。\n'
                  '・前半突っ込みか前半抑えの指示を出すと、目標順位による補正(下回ったときの前半の突っ込み、上回ったときのほっと一息)はかからず、代わりに指示の成否による補正がかかります。',
                  style: TextStyle(
                    color: HENSUU.textcolor.withOpacity(0.8),
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
                // 学連選抜の選手には、指示の補正のあとにモチベーション低下補正がかかる(1.8.2)
                if (widget.gakuren && _motivationHoseiAri())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '・学連選抜の選手には、2区以降で「学連選抜モチベーション設定」のモチベーション低下補正もかかります。この補正は指示の補正のあとにかかるので、ここの秒数には入っていません。走ったあとの補正の説明では、指示の補正の秒数とは別に「モチベーション低下補正」として出ます(区間タイムはその分さらに遅くなります)。',
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
                      '・補正の強さを設定で変更しています(説明画面の設定タブの「目標順位・指示の補正設定」)。',
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

  /// 学連選抜のモチベーション低下補正をかける設定か(Album.yobiint4が1以上)
  bool _motivationHoseiAri() {
    final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
    return album != null && album.yobiint4 > 0;
  }

  /// 襷を受けた時点の状況の文
  String _joukyouBun(SijiSontoku s) {
    final int juni = s.juni + 1;
    final int mokuhyou = s.mokuhyou + 1;
    if (s.joukyou == SijiSontokuJoukyou.gakurenMokuhyouNai) {
      return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位以内。学連選抜にはほっと一息はありません)';
    }
    if (widget.gakuren && s.joukyou == SijiSontokuJoukyou.shitamawari) {
      final double? sa = s.timeSa;
      final String saBun = sa == null
          ? ''
          : '・$mokuhyou位と${sa.toStringAsFixed(1)}秒差';
      return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位を下回っています$saBun)';
    }
    if (widget.gakuren && s.joukyou == SijiSontokuJoukyou.uwamawari) {
      return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位を${mokuhyou - juni}つ上回っています)';
    }
    if (widget.gakuren && s.joukyou == SijiSontokuJoukyou.choudo) {
      return '襷を受けた時点で$juni位相当(学連選抜の目標順位ちょうど)';
    }
    if (s.joukyou == SijiSontokuJoukyou.fukuroStart) {
      return '6区は復路のスタートなので、往路の順位による目標順位の補正はありません';
    }
    if (s.joukyou == SijiSontokuJoukyou.shitamawari) {
      final double? sa = s.timeSa;
      final String saBun = sa == null
          ? ''
          : '・$mokuhyou位と${sa.toStringAsFixed(1)}秒差';
      return '襷を受けた時点で$juni位(目標$mokuhyou位を下回っています$saBun)';
    }
    if (s.joukyou == SijiSontokuJoukyou.uwamawari) {
      return '襷を受けた時点で$juni位(目標$mokuhyou位を${mokuhyou - juni}つ上回っています)';
    }
    return '襷を受けた時点で$juni位(目標順位ちょうど)';
  }

  /// 指示なしの行(理由も付ける。補正の強さが0%で損得がないときは理由を出さない)
  Widget _nashiGyou(SijiSontoku s) {
    String riyuu = '';
    if (s.nashi == 0.0) {
      riyuu = '';
    } else if (s.joukyou == SijiSontokuJoukyou.shitamawari) {
      riyuu = '目標順位を下回ったため、前半無理に突っ込んでしまう分';
    } else if (s.joukyou == SijiSontokuJoukyou.uwamawari) {
      riyuu = '目標順位を上回ったため、ほっと一息ついてしまう分';
    }
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
    final String atai;
    Color iro = HENSUU.textcolor;
    if (byou == 0.0) {
      atai = '損得なし';
    } else if (byou.abs() < 0.5) {
      atai = byou > 0 ? '1秒未満の損' : '1秒未満の得';
      iro = byou > 0 ? _sonColor : _tokuColor;
    } else {
      final int maru = byou.abs().round();
      atai = byou > 0 ? '約$maru秒の損' : '約$maru秒の得';
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

  /// 指示1つ分の枠(レース画面で選んでいる指示は枠の色を変えて「選択中」と出す)
  Widget _sijiCard({
    required int bangou,
    required String midashi,
    String seikouritsu = '',
    required List<Widget> gyou,
  }) {
    final bool sentakuchuu = widget.sentakuchuu == bangou;
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
        ],
      ),
    );
  }
}
