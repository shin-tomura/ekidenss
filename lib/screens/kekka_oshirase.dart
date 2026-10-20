import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show juniKaisuu, shutsujouKaisuu;

// ------------------------------------------------------------
// 結果画面のお知らせの枠(2.1.0)
// ・駅伝・駅伝予選・対校戦の結果画面の一番上に、オレンジの枠で良い結果を知らせる
//   (ダイアログではないので、押さなくても進める。対校戦は taikousen_nyuushou_oshirase.dart)
// ・駅伝(10月・11月・正月・カスタム): 優勝・3位以内・シード権獲得(11月駅伝8位以内・正月駅伝10位以内)と、
//   大学の過去最高順位。目標順位を達成したかどうかに関係なく出し、届かなかったときは
//   「目標の○位には届きませんでしたが、」を頭に付ける(達成したときは目標達成の画面で祝っているので、事実だけ)
// ・駅伝予選: 予選突破(11月駅伝予選7位以内・正月駅伝予選10位以内。1位なら「トップ通過」)と、
//   大学の過去最高順位(落ちたときも出す)。予選は目標順位が突破の線と同じなので、目標の一言は付けない
// ・過去最高順位の決め方は、ニュース記事(kiji_kekka.dart の kakoSaikou)と同じ
//   (初めての出場ではなく、この順位は今回が初めてで、これより上の順位を取ったこともない)
// ・セーブ済みの順位と回数(UnivData の juni_race・taikaibetujunibetukaisuu など)から画面を描くたびに作る
//   (セーブデータは増やさない)。自分の大学が走っていない大会と、スキップ中は出さない
// ------------------------------------------------------------

/// お知らせの枠と見出しの色(情報集約パネルの自分の大学と同じ)
const Color oshiraseIro = Colors.orangeAccent;

/// スキップ中か(スキップ中はお知らせを出さない)
bool oshiraseSkipChuu() {
  if (!Hive.isBoxOpen('skipBox')) return false;
  final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
  return skip != null && skip.skipflag != 0;
}

/// お知らせの枠(見出しと中身)
class OshiraseWaku extends StatelessWidget {
  const OshiraseWaku({super.key, required this.midashi, required this.naka});

  final String midashi;
  final List<Widget> naka;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: oshiraseIro, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            midashi,
            style: const TextStyle(
              color: oshiraseIro,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...naka,
        ],
      ),
    );
  }
}

/// お知らせの本文の文字
const TextStyle oshiraseHonbun = TextStyle(
  color: HENSUU.textcolor,
  fontSize: HENSUU.fontsize_honbun,
);

/// 大学[u]の大会[race]の順位[r](0が1位)が、大学の過去最高の順位か(ニュース記事と同じ決め方)
bool _kakoSaikou(UnivData u, int race, int r) {
  if (shutsujouKaisuu(u, race) <= 1) return false;
  if (juniKaisuu(u, race, r) != 1) return false;
  for (int j = 0; j < r; j++) {
    if (juniKaisuu(u, race, j) > 0) return false;
  }
  return true;
}

/// 駅伝・駅伝予選の結果画面のお知らせ(知らせることがなければ何も出さない)
class EkidenKekkaOshirase extends StatelessWidget {
  const EkidenKekkaOshirase({super.key, required this.gh, required this.univ});

  final Ghensuu gh;

  /// 大学(IDの順)
  final List<UnivData> univ;

  @override
  Widget build(BuildContext context) {
    final int race = gh.hyojiracebangou;
    if (race < 0 || race > 5) return const SizedBox.shrink();
    if (gh.MYunivid < 0 || gh.MYunivid >= univ.length) return const SizedBox.shrink();
    final UnivData u = univ[gh.MYunivid];
    if (u.taikaientryflag.length <= race || u.taikaientryflag[race] != 1) {
      return const SizedBox.shrink();
    }
    if (u.juni_race.length <= race || u.juni_race[race].isEmpty) return const SizedBox.shrink();
    final int r = u.juni_race[race][0];
    if (r < 0 || r >= TEISUU.DEFAULTJUNI) return const SizedBox.shrink();
    if (oshiraseSkipChuu()) return const SizedBox.shrink();
    final bool kako = _kakoSaikou(u, race, r);
    final ({String midashi, List<String> bun})? n =
        (race == 3 || race == 4) ? _yosen(race, r, kako) : _ekiden(u, race, r, kako);
    if (n == null) return const SizedBox.shrink();
    return OshiraseWaku(
      midashi: n.midashi,
      naka: [Text(n.bun.join(), style: oshiraseHonbun)],
    );
  }

  /// 駅伝(10月・11月・正月・カスタム)
  ({String midashi, List<String> bun})? _ekiden(UnivData u, int race, int r, bool kako) {
    final bool yuushou = r == 0;
    final bool sanni = r <= 2;
    // シード権(11月駅伝は8位以内、正月駅伝は10位以内。正月駅伝は10月駅伝の出場権も)
    final int? seedSuu = race == 1 ? 8 : (race == 2 ? 10 : null);
    final bool seed = seedSuu != null && r < seedSuu;
    final String seedMoji = race == 2 ? 'シード権と10月駅伝の出場権' : 'シード権';
    if (!sanni && !seed && !kako) return null;
    // 目標順位に届かなかったときの一言(目標達成の画面と同じ決め方)
    final int mokuhyou = u.mokuhyojuni.length > race ? u.mokuhyojuni[race] : -1;
    final String todokazu = (mokuhyou >= 0 && r > mokuhyou)
        ? '目標の${mokuhyou + 1}位には届きませんでしたが、'
        : '';
    final List<String> bun = [];
    final String midashi;
    if (yuushou) {
      midashi = kako ? '初優勝！' : '優勝！';
      bun.add('$todokazu優勝しました。');
    } else if (sanni) {
      midashi = '3位以内';
      bun.add('$todokazu${r + 1}位に入りました。');
    } else if (seed) {
      midashi = 'シード権獲得';
      bun.add('$todokazu${r + 1}位で、来年の$seedMojiを手にしました。');
    } else {
      midashi = '大学の過去最高順位';
      bun.add('$todokazu${r + 1}位は、この大会での大学の過去最高の順位です。');
    }
    if ((yuushou || sanni) && seed) bun.add('来年の$seedMojiも手にしました。');
    if (kako && (yuushou || sanni || seed)) {
      bun.add(yuushou ? 'この大会で、大学として初めての優勝です。' : 'この大会での大学の過去最高の順位です。');
    }
    return (midashi: midashi, bun: bun);
  }

  /// 駅伝予選(11月駅伝予選・正月駅伝予選)
  ({String midashi, List<String> bun})? _yosen(int race, int r, bool kako) {
    final int tsuukaSuu = race == 3 ? 7 : 10;
    final String honsen = race == 3 ? '11月駅伝' : '正月駅伝';
    final bool tsuuka = r < tsuukaSuu;
    if (!tsuuka && !kako) return null;
    if (!tsuuka) {
      return (
        midashi: '大学の過去最高順位',
        bun: ['${r + 1}位は、この予選での大学の過去最高の順位です。'],
      );
    }
    return (
      midashi: r == 0 ? 'トップ通過' : '予選突破',
      bun: [
        '${r + 1}位で、$honsenの出場権を手にしました。',
        if (kako) r == 0 ? 'この予選で、大学として初めてのトップ通過です。' : 'この予選での大学の過去最高の順位です。',
      ],
    );
  }
}
