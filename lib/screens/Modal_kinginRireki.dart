import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/kingin_rireki.dart';
import 'package:ekiden/kansuu/goldsilver_com.dart' show comKinHoyuu, comGinHoyuu;

// ------------------------------------------------------------
// 金銀の内訳(2.1.1。記録は lib/kansuu/kingin_rireki.dart)
// 大学画面の「金銀の内訳」から開く。表示している大学の金銀の出入りを、年度ごとに過去10年分出す。
// ・年度のボタンで年度を選ぶ(名声の履歴と同じく、今年度から9年前まで)
// ・年度初めの保有と、年度末(今年度は今)の保有。年度末は翌年度の年度初めの保有で出す
// ・受け取った・使った・交換・そのほかに分けて、記録した順に並べる
// ・年度初めと年度末が分かる年は、記録の合計との差を「記録のない増減」として出す
//   (記録を始める前の分など)
// ・文字を大きくしてもはみ出さないように、内容の文は折り返し、量は右に短く出す
// ------------------------------------------------------------

/// 金銀の内訳を開く([univId] 表示している大学)
void kinginRirekiHiraku(BuildContext context, int univId) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    barrierDismissible: true,
    barrierLabel: '金銀の内訳',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => ModalKinginRireki(univId: univId),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class ModalKinginRireki extends StatefulWidget {
  final int univId;

  const ModalKinginRireki({super.key, required this.univId});

  @override
  State<ModalKinginRireki> createState() => _ModalKinginRirekiState();
}

class _ModalKinginRirekiState extends State<ModalKinginRireki> {
  /// 選んでいる年度(0が今年度)
  int _nenmae = 0;

  static const TextStyle _futsuu = TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);
  static const TextStyle _chuui = TextStyle(color: Colors.grey, fontSize: 13);
  static const TextStyle _midashi = TextStyle(
    color: Colors.orangeAccent,
    fontSize: HENSUU.fontsize_honbun,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    UnivData? univ;
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == widget.univId) univ = u;
    }
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: Text(
          univ == null ? '金銀の内訳' : '${univ.name}大学 金銀の内訳',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: univ == null
                  ? const Center(child: Text('データがありません', style: _futsuu))
                  : ListView(padding: const EdgeInsets.all(16), children: _naiyou()),
            ),
            // 閉じるボタン(名声の履歴と同じ)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text("閉じる"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _naiyou() {
    final int univId = widget.univId;
    final Box<Ghensuu> gb = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu? gh = gb.isEmpty ? null : gb.getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');

    // 年度初めと年度末(今年度は今)の保有
    final ({int kin, int gin})? hajime = kinginNendoHajime(_nenmae, univId);
    ({int kin, int gin})? owari;
    if (_nenmae > 0) {
      owari = kinginNendoHajime(_nenmae - 1, univId);
    } else if (gh != null && univId == gh.MYunivid) {
      owari = (kin: gh.goldenballsuu, gin: gh.silverballsuu);
    } else if (kantoku != null) {
      owari = (kin: comKinHoyuu(kantoku, univId), gin: comGinHoyuu(kantoku, univId));
    }

    final List<KinginRirekiGyou> rireki = kinginRirekiYomu(_nenmae, univId);
    // 記録のない増減(年度初めと年度末が分かるときだけ)
    int saKin = 0;
    int saGin = 0;
    if (hajime != null && owari != null) {
      saKin = owari.kin - hajime.kin;
      saGin = owari.gin - hajime.gin;
      for (final KinginRirekiGyou g in rireki) {
        saKin -= g.kin;
        saGin -= g.gin;
      }
    }

    final List<Widget> list = [
      const Text('・受け取った金銀、特訓で使った金銀、交換を、年度ごとに記録しています(この版より前の分はありません)。', style: _chuui),
      const Text('・自分の大学の特訓は日ごとにまとめています。コンピュータの大学は、夏合宿でまとめて使います。', style: _chuui),
      const Text('・「記録のない増減」は、記録を始める前の分などです。', style: _chuui),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (int n = 0; n < TEISUU.MEISEIHOZONNENSUU; n++)
            _nendoBotan(n == 0 ? '今年度' : '$n年前', n == _nenmae, () => setState(() => _nenmae = n)),
        ],
      ),
      const SizedBox(height: 8),
      Text('年度初め  ${_hoyuuMoji(hajime)}', style: _futsuu),
      Text('${_nenmae == 0 ? '今' : '年度末'}  ${_hoyuuMoji(owari)}', style: _futsuu),
    ];

    const List<(int, String)> kubun = [
      (kinginUketotta, '受け取った'),
      (kinginTsukatta, '使った'),
      (kinginKoukan, '交換'),
      (kinginSonohoka, 'そのほか'),
    ];
    bool nanimonai = true;
    for (final (int shurui, String mei) in kubun) {
      final List<KinginRirekiGyou> naka = [
        for (final KinginRirekiGyou g in rireki)
          if (g.shurui == shurui) g,
      ];
      final bool sa = shurui == kinginSonohoka && (saKin != 0 || saGin != 0);
      if (naka.isEmpty && !sa) continue;
      nanimonai = false;
      list.add(const Divider(color: Colors.grey));
      list.add(Text(mei, style: _midashi));
      for (final KinginRirekiGyou g in naka) {
        final String hiduke = g.tsuki > 0 ? '${g.tsuki}月${g.hi}日 ' : '';
        final String bun = g.kaisuu > 0 ? '${g.naiyou} ${g.kaisuu}回' : g.naiyou;
        list.add(_gyou('$hiduke$bun', g.kin, g.gin));
      }
      if (sa) list.add(_gyou('記録のない増減', saKin, saGin));
    }
    if (nanimonai) {
      list.add(const Divider(color: Colors.grey));
      list.add(const Text('この年度の金銀の出入りの記録はありません。', style: _futsuu));
    }
    return list;
  }

  /// 保有の文(「金35 銀420」。分からなければ「記録がありません」)
  String _hoyuuMoji(({int kin, int gin})? h) => h == null ? '記録がありません' : '金${h.kin} 銀${h.gin}';

  /// 増減の文(「+120」「−330」)
  String _zougen(int v) => v > 0 ? '+$v' : '−${-v}';

  /// 1行(内容の文は折り返し、量は右に短く出す)
  Widget _gyou(String bun, int kin, int gin) {
    // 金と銀の両方が動いた行(交換など)は2行にする(文字を大きくしても横に長くならないように)
    final String ryou = [
      if (kin != 0) '金 ${_zougen(kin)}',
      if (gin != 0) '銀 ${_zougen(gin)}',
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text('・$bun', style: _futsuu)),
          const SizedBox(width: 8),
          Text(ryou, style: _futsuu, textAlign: TextAlign.right),
        ],
      ),
    );
  }

  /// 年度を選ぶボタン(選んでいる年度は緑で塗る)
  Widget _nendoBotan(String moji, bool erabu, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: erabu ? const Color(0xFF1B5E20) : Colors.transparent,
        foregroundColor: erabu ? Colors.white : HENSUU.LinkColor,
        side: BorderSide(color: erabu ? Colors.greenAccent : Colors.white38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(44, 36),
      ),
      child: Text(moji, style: const TextStyle(fontSize: HENSUU.fontsize_honbun - 1)),
    );
  }
}
