import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/ace_haichi.dart';
import 'package:ekiden/kansuu/gakuren_text.dart' show gakurenKonnenAri;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou, daigakuMei;
import 'package:ekiden/screens/kiji_hyou_view.dart';

// ------------------------------------------------------------
// エースの配置(2.1.3。集計は kansuu/ace_haichi.dart)
// 駅伝のレース前の画面(直前順位予想・当日変更・スタート前)で、各大学のエース・準エースと、
// 全体の上位10人が、どの区間(と補欠など)に入っているかの人数を出す。
// ・開いた時点の配置で数える(保存はしない)。当日変更の画面で選んでいる途中の変更は入らない
//   (確定した区間エントリーで数える)
// ・ボタンは KakuninButtons(kukan_haiti_button.dart)の aceBamen を渡した画面にだけ出る(10月・11月・正月・
//   カスタム駅伝だけ。予選では出さない)
// ・エースの決め方は、スキップして統計データ取得の統計(toukei_ace.dart)と同じ。記事の「エース」(走る予定の
//   選手のうち、区間の距離に合わせた持ちタイムが一番いい選手)とは違うことがあるので、そう添える
// ------------------------------------------------------------

/// どの画面から開いたか
enum AceBamen {
  /// 直前順位予想(区間エントリーのあと)
  kukanEntry,

  /// 当日変更の画面(1日開催の駅伝と、正月駅伝の往路)
  toujitsu,

  /// 正月駅伝の復路の当日変更の画面
  fukuroToujitsu,

  /// スタート前(当日変更のあと)
  start,
}

/// エースの配置を出す駅伝か(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)
bool aceHaichiTaishou(int race) => race == 0 || race == 1 || race == 2 || race == 5;

const TextStyle _futsuu = TextStyle(color: HENSUU.textcolor);
const TextStyle _chuu = TextStyle(
  color: Colors.white70,
  fontSize: HENSUU.fontsize_honbun - 3,
);

class ModalAceHaichi extends StatelessWidget {
  final AceBamen bamen;
  const ModalAceHaichi({super.key, required this.bamen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('エースの配置', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: _naiyou()),
            ),
            // 閉じるボタン(金銀の内訳と同じ)
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
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
    if (gh == null || !aceHaichiTaishou(gh.hyojiracebangou)) {
      return const [Text('この大会では見られません。', style: _futsuu)];
    }
    final int race = gh.hyojiracebangou;
    final int kukansuu = race < gh.kukansuu_taikaigoto.length ? gh.kukansuu_taikaigoto[race] : 1;
    final List<UnivData> univs = Hive.box<UnivData>('univBox').values.toList();
    final Map<int, String> univMei = {for (final UnivData u in univs) u.id: daigakuMei(u)};
    String customMei = 'カスタム駅伝';
    for (final UnivData u in univs) {
      if (u.id == 0 && u.name_tanshuku.trim().isNotEmpty) customMei = u.name_tanshuku;
    }
    final String raceMei = race == 0
        ? '10月駅伝'
        : race == 1
        ? '11月駅伝'
        : race == 2
        ? '正月駅伝'
        : customMei;
    final Iterable<Senshu_Gakuren_Data> gakuren = race == 2 && gakurenKonnenAri(gh)
        ? Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox').values
        : const <Senshu_Gakuren_Data>[];
    final AceHaichiKekka k = aceHaichiKeisan(
      race: race,
      kukansuu: kukansuu,
      senshu: Hive.box<SenshuData>('senshuBox').values,
      gakuren: gakuren,
      univMei: univMei,
      myUnivid: gh.MYunivid,
    );

    // 正月駅伝の往路・復路
    final bool fukuroAri = race == 2 && k.kukansuu == 10;
    final bool fukuroStart = fukuroAri && gh.nowracecalckukan >= 5;
    final String bamenMei;
    final String bamenChuu;
    switch (bamen) {
      case AceBamen.kukanEntry:
        bamenMei = '区間エントリー';
        bamenChuu = '区間エントリーの配置です(当日変更の前)。';
        break;
      case AceBamen.toujitsu:
        bamenMei = '当日変更の前';
        bamenChuu = '区間エントリーの配置です。この画面で選んでいる当日変更は、まだ入りません。';
        break;
      case AceBamen.fukuroToujitsu:
        bamenMei = '復路の当日変更の前';
        bamenChuu = '往路(1〜5区)は当日変更のあとの配置、復路(6〜10区)は区間エントリーの配置です。'
            'この画面で選んでいる当日変更は、まだ入りません。';
        break;
      case AceBamen.start:
        bamenMei = fukuroStart ? '復路スタート前' : 'スタート前';
        bamenChuu = fukuroAri && !fukuroStart
            ? '当日変更のあとの配置です。復路(6〜10区)は、復路の当日変更の前の配置です。'
            : '当日変更のあとの配置です。';
        break;
    }

    // 区間ごとの人数の表(当日変更で外れた選手の行は、当日変更のあとの画面か、外れた選手がいるときだけ)
    final bool hazuretaGyou = bamen == AceBamen.start ||
        bamen == AceBamen.fukuroToujitsu ||
        k.hazureta.any((n) => n > 0);
    final KijiHyou ninzuuHyou = KijiHyou('区間ごとの人数', [
      '区間',
      'エース',
      '準エース',
      '上位10人',
    ], [
      for (int kk = 0; kk < k.kukansuu; kk++)
        ['${kk + 1}区', '${k.kukan[0][kk]}', '${k.kukan[1][kk]}', '${k.kukan[2][kk]}'],
      ['補欠', '${k.hoketsu[0]}', '${k.hoketsu[1]}', '${k.hoketsu[2]}'],
      if (hazuretaGyou)
        ['当日変更で外れた', '${k.hazureta[0]}', '${k.hazureta[1]}', '${k.hazureta[2]}'],
      ['一次エントリー外', '${k.entryGai[0]}', '${k.entryGai[1]}', '-'],
    ]);

    // 全体の上位10人の表
    final KijiHyou jouiHyou = KijiHyou('全体の上位10人', ['順', '選手', '大学', '区間'], [
      for (int i = 0; i < k.joui.length; i++)
        [
          '${i + 1}',
          '${k.joui[i].name}(${k.joui[i].gakunen}年)',
          k.joui[i].daigaku,
          aceBashoMoji(k.joui[i].code, k.kukansuu),
        ],
    ]);

    String jibunMoji(AceSenshu s) =>
        '${s.name}(${s.gakunen}年)${aceBashoMoji(s.code, k.kukansuu)}';

    return [
      Text(
        '$raceMei・$bamenMei',
        style: const TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(bamenChuu, style: _futsuu),
      const SizedBox(height: 6),
      const Text(
        '各大学の全選手を、5000m・1万m・ハーフ・ロード1万の学内順位の平均で並べた1番手をエース、2番手を準エースとしています'
        '(記事の「エース」とは決め方が違うことがあります)。',
        style: _chuu,
      ),
      const Text(
        '持ちタイムは今季ベスト、なければ自己ベストで、記録のない種目は近い種目から換算します。',
        style: _chuu,
      ),
      KijiHyouView(ninzuuHyou, ue: 12),
      const SizedBox(height: 6),
      Text(
        '${k.univSuu}校のエース・準エースです(学連選抜は数えません)。'
        '上位10人は、区間エントリーされた全選手${race == 2 && gakuren.isNotEmpty ? '(学連選抜の選手も含む)' : ''}の中での、同じ決め方の順位です。',
        style: _chuu,
      ),
      if (k.jibun.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amberAccent.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'あなたの大学 エース ${jibunMoji(k.jibun[0])}'
            '${k.jibun.length >= 2 ? '・準エース ${jibunMoji(k.jibun[1])}' : ''}',
            style: const TextStyle(color: Colors.amberAccent),
          ),
        ),
      ],
      if (k.joui.isNotEmpty) KijiHyouView(jouiHyou, ue: 16),
    ];
  }
}
