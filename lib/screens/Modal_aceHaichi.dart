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
import 'package:ekiden/screens/Modal_senshu.dart' show ModalSenshuDetailView; // 選手の詳細の小窓(2.1.3)

// ------------------------------------------------------------
// エースの配置(2.1.3。集計は kansuu/ace_haichi.dart)
// 駅伝のレース前の画面(直前順位予想・当日変更・スタート前)と、レースの指示の画面(2.1.3)で、各大学のエース・準エースと、
// 全体の上位10人が、どの区間(と補欠など)に入っているかの人数を出す。
// ・開いた時点の配置で数える(保存はしない)。当日変更の画面で選んでいる途中の変更は入らない
//   (確定した区間エントリーで数える)
// ・ボタンは KakuninButtons(kukan_haiti_button.dart)の aceBamen を渡した画面にだけ出る(10月・11月・正月・
//   カスタム駅伝だけ。予選では出さない)
// ・エースの決め方は、スキップして統計データ取得の統計(toukei_ace.dart)と、展望記事・スタート直前号・
//   学連選抜通信の展望号の「エース」(kiji_tenbou.dart・kiji_gakuren.dart)と同じ。記事は走る予定の選手の中から
//   選ぶので、この表のエースが補欠のときは違う選手になる。そう添える
// ・一番下に、出場した大学ごとのエース・準エースの区間の一覧を出す(大学のidの順。区間配置確認と同じ並び)
// ・全体の上位10人と大学ごとの一覧の選手の名前のマスを押すと、選手の詳細の小窓を開く(区間適性の見立ての
//   「詳細」と同じ開き方。小窓で名前や能力を変えられるので、閉じたら表を作り直す)
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

  /// レースの指示の画面(各区間のスタート前。2.1.3。学連選抜の監督の年は、目標もこの画面で決める)
  race,
}

/// エースの配置を出す駅伝か(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)
bool aceHaichiTaishou(int race) => race == 0 || race == 1 || race == 2 || race == 5;

const TextStyle _futsuu = TextStyle(color: HENSUU.textcolor);
const TextStyle _chuu = TextStyle(
  color: Colors.white70,
  fontSize: HENSUU.fontsize_honbun - 3,
);

class ModalAceHaichi extends StatefulWidget {
  final AceBamen bamen;
  const ModalAceHaichi({super.key, required this.bamen});

  @override
  State<ModalAceHaichi> createState() => _ModalAceHaichiState();
}

class _ModalAceHaichiState extends State<ModalAceHaichi> {
  /// 選手の詳細の小窓を開く(区間適性の見立ての「詳細」と同じ開き方。閉じたら表を作り直す)
  void _shousaiHiraku(int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => ModalSenshuDetailView(senshuId: senshuId),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

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
      kukanKyori: race < gh.kyori_taikai_kukangoto.length
          ? gh.kyori_taikai_kukangoto[race]
          : const <double>[],
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
    final AceBamen bamen = widget.bamen;
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
      case AceBamen.race:
        // これから走る区間(nowracecalckukan は0が1区)
        bamenMei = gh.nowracecalckukan >= 0 && gh.nowracecalckukan < k.kukansuu
            ? '${gh.nowracecalckukan + 1}区のスタート前'
            : 'レース中';
        bamenChuu = fukuroAri && !fukuroStart
            ? '当日変更のあとの配置です。復路(6〜10区)は、復路の当日変更の前の配置です。'
            : '当日変更のあとの配置です。';
        break;
    }

    // 区間ごとの人数の表(当日変更で外れた選手の行は、当日変更のあとの画面か、外れた選手がいるときだけ)
    final bool hazuretaGyou = bamen == AceBamen.start ||
        bamen == AceBamen.race ||
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

    // 上位10人の選手の名前のマスを押すと、選手の詳細(2.1.3)
    final Map<(int, int), VoidCallback> jouiLink = {
      for (int i = 0; i < k.joui.length; i++) (i, 1): () => _shousaiHiraku(k.joui[i].id),
    };

    // 大学ごとのエース・準エースの一覧(マスは「2区 山田 健太(4年)」。区間を先に書いて左にそろえる。2.1.3)
    String aceMoji(AceSenshu s) =>
        '${aceBashoMoji(s.code, k.kukansuu)} ${s.name}(${s.gakunen}年)';
    final KijiHyou univHyou = KijiHyou('各大学のエース・準エース', ['大学', 'エース', '準エース'], [
      for (final AceUniv u in k.univAce)
        [
          u.daigaku,
          u.ace.isNotEmpty ? aceMoji(u.ace[0]) : '-',
          u.ace.length >= 2 ? aceMoji(u.ace[1]) : '-',
        ],
    ]);
    final Map<(int, int), VoidCallback> univLink = {
      for (int r = 0; r < k.univAce.length; r++)
        for (int j = 0; j < 2 && j < k.univAce[r].ace.length; j++)
          (r, j + 1): () => _shousaiHiraku(k.univAce[r].ace[j].id),
    };

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
        'この駅伝の区間の距離に合う種目の持ちタイムを全選手の中での偏差値にし、区間の距離で重み付けした平均が'
        '学内で一番高い選手をエース、2番目を準エースとしています。'
        '展望記事のエースも同じ決め方です(記事は走る予定の選手の中から選びます)。',
        style: _chuu,
      ),
      const Text(
        '1〜3区は5000m・1万m・ハーフのうち距離に合う種目、4区以降は15km以下ならロード1万、15km超ならハーフで見ます。'
        '持ちタイムは今季ベスト(なければ自己ベスト)です。',
        style: _chuu,
      ),
      // この駅伝の物差しの重み(2.1.3)
      Text('この駅伝の物差し: ${k.omomi.moji()}', style: _chuu),
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
      if (k.joui.isNotEmpty || k.univAce.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('選手の名前(緑の下線)を押すと、選手の詳細を見られます。', style: _chuu),
      ],
      if (k.joui.isNotEmpty) KijiHyouView(jouiHyou, ue: 8, link: jouiLink),
      // 大学ごとのエース・準エース(一番下。2.1.3)
      if (k.univAce.isNotEmpty) KijiHyouView(univHyou, ue: 16, link: univLink),
    ];
  }
}
