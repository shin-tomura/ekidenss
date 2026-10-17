import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/reset_ichiran.dart';
import 'package:ekiden/qr_processor.dart' show qrKakidashiYobiBangou; // QRコードの印の見張り(開発用。2.0.3)

// ------------------------------------------------------------
// 「リセット・ロード・QRで残るもの・変わるもの」の一覧表の画面(2.0.3。最初は「リセットで残るもの・戻るもの」、
// 次に「リセットとロードで残るもの・戻るもの」)
// 説明画面の設定タブの一番上と、2つのリセットの確認の画面と、QRコードの画面から開く。
// 中身は lib/kansuu/reset_ichiran.dart の一覧から作る(設定を足して一覧に1行書けば、ここにも出る)。
// ・見出しは設定タブの見出しの順(resetMidashiJun)。行ごとに、2つのリセットで残るか戻るかと、
//   セーブデータを読み込んだときにセーブの値になるか今のままか(yomikomiNokosu)と、
//   QRコードを読み込んだときにQRの値になるか今のままか(qr。説明用の印)を出す
// ・スマホで文字を大きくしても横にはみ出さないように、表ではなく、名前の下に4つの札を並べる
// ・開発中のビルドだけ、一番上に赤字で出すもの(書き忘れの見張り):
//   ・一覧に載っていない予備の番号(resetMitourokuBangou)
//   ・QRコードの印と、QRコードに実際に書き出している予備の番号の食い違い(resetQrZure)
// ------------------------------------------------------------

/// 一覧表の画面を開く
Future<void> resetIchiranGamenHiraku(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ResetIchiranGamen()),
  );
}

class ResetIchiranGamen extends StatelessWidget {
  const ResetIchiranGamen({super.key});

  static const TextStyle _honbun = TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);

  /// リセットの札の文字と色(残る・戻る・選び直す)
  static (String, Color) _fuda(ResetBunrui b, {required bool zenbu}) {
    if (b == ResetBunrui.erabinaoshi) return ('選び直す', Colors.lightBlueAccent);
    return resetNokosu(b, zenbu: zenbu)
        ? ('残る', Colors.lightGreenAccent)
        : ('戻る', Colors.orangeAccent);
  }

  /// セーブデータを読み込んだときの札の文字と色(今のまま・セーブの値)
  static (String, Color) _yomikomiFuda(ResetKoumoku k) =>
      k.yomikomiNokosu ? ('今のまま', Colors.lightGreenAccent) : ('セーブの値', Colors.white70);

  /// QRコードを読み込んだときの札の文字と色(QRの値・一部QRの値・今のまま)
  static (String, Color) _qrFuda(ResetKoumoku k) {
    switch (k.qr) {
      case ResetQr.atai:
        return ('QRの値', Colors.white70);
      case ResetQr.ichibu:
        return ('一部QRの値', Colors.yellowAccent);
      case ResetQr.imanomama:
        return ('今のまま', Colors.lightGreenAccent);
    }
  }

  Widget _fudaWidget(String toki, (String, Color) fuda) {
    final (String moji, Color iro) = fuda;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: iro),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$toki: $moji',
        style: TextStyle(color: iro, fontSize: HENSUU.fontsize_honbun - 2),
      ),
    );
  }

  /// (開発用)赤字で出す警告
  static List<String> _kaihatsuKeikoku(BuildContext context) {
    if (!kDebugMode) return const [];
    final List<String> l = [];
    final List<String> mitouroku = resetMitourokuBangou();
    if (mitouroku.isNotEmpty) {
      l.add('reset_ichiran.dart の一覧に載っていない予備の番号があります: ${mitouroku.join('、')}');
    }
    try {
      final List<String> zure = resetQrZure(qrKakidashiYobiBangou(context));
      if (zure.isNotEmpty) {
        l.add('reset_ichiran.dart の一覧のQRコードの印と、qr_processor.dart の書き出しが食い違っています: ${zure.join('、')}');
      }
    } catch (e) {
      l.add('QRコードの印の見張りを確かめられませんでした: $e');
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final List<ResetKoumoku> ichiran = resetIchiran();
    final List<String> keikoku = _kaihatsuKeikoku(context);
    final TextStyle hosoku = TextStyle(
      color: HENSUU.textcolor.withOpacity(0.7),
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        // 名前が長いので、狭い画面では縮めて1行に収める
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('リセット・ロード・QRで残るもの・変わるもの', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final String k in keikoku)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '(開発用)$k',
                  style: const TextStyle(color: Colors.redAccent, fontSize: HENSUU.fontsize_honbun),
                ),
              ),
            const Text(
              '設定タブの2つのリセットと、セーブデータやQRコードの読み込みで、何が残り、何が変わるかの一覧です。',
              style: _honbun,
            ),
            const SizedBox(height: 8),
            const Text(
              '・「名声・育成力と設定を残してやり直す」(おすすめ): 選手・記録・年月日などのゲームの進み具合だけを消して、1年目からやり直します。'
              '名声・育成力・名声の横並びと、レースや育成などの設定は残ります。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・「全てリセットしてやり直す」: 名声・育成力と設定も初期値に戻します。本当に初期値に戻したいときだけ選んでください。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・どちらのリセットでも、表示の好み・大学名・メモなどは残り、アルバム(卒業したOB)は消えます。'
              '難易度と総監督をする大学は、リセットのあとに選び直します。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・セーブデータを読み込むと、ゲームの進み具合・名声・設定・大学名などは、セーブしたときの値になります。'
              '表示の好み・フリーメモ・高校名鑑のお気に入りは、今のままです。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・データ共有(世界を共有)で書き出すときは、フリーメモは入りません。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・各種設定などのQRコードを読み込むと、レースや育成などの設定と、名声・育成力は、QRコードの値になります。'
              '表示の好み・作ったもの・ゲームの進み具合は、今のままです。',
              style: _honbun,
            ),
            for (final String midashi in resetMidashiJun) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Text(
                  midashi,
                  style: const TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun + 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.grey, height: 8),
              for (final ResetKoumoku k in ichiran)
                if (k.midashi == midashi)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.mei, style: _honbun.copyWith(fontWeight: FontWeight.bold)),
                        if (k.hosoku.isNotEmpty) Text(k.hosoku, style: hosoku),
                        if (k.qrHosoku.isNotEmpty) Text('QRコード: ${k.qrHosoku}', style: hosoku),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _fudaWidget('設定を残すリセット', _fuda(k.bunrui, zenbu: false)),
                            _fudaWidget('全てリセット', _fuda(k.bunrui, zenbu: true)),
                            _fudaWidget('セーブを読み込んだとき', _yomikomiFuda(k)),
                            _fudaWidget('QRコードを読み込んだとき', _qrFuda(k)),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
