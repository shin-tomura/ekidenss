import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/shushou.dart'; // 主将の印(「4年・主将」)
import 'package:ekiden/screens/kekka_oshirase.dart'; // お知らせの枠(2.1.0)

// ------------------------------------------------------------
// 対校戦の入賞のお知らせ(2.1.0)
// ・対校戦の種目(5000m・1万m・ハーフ)の結果画面の一番上に、自分の大学の選手が個人8位以内に
//   入ったことを枠で知らせる(ダイアログではないので、押さなくても進める)
// ・ハーフのあとは、3種目を合わせた総合で3位以内に入ったことも知らせる(総合8位以内は目標順位で、
//   達成すると目標達成の画面が出るので、それより上の3位以内だけ)
// ・見出しは、総合優勝 > 個人の優勝 > 総合3位以内 > 入賞 の順で、一番大きいもの
// ・セーブ済みの順位(kukanjuni_race・juni_race[9])から画面を描くたびに作る(セーブデータは増やさない)
// ・知らせることがないときと、スキップ中は出さない(kekka_oshirase.dart)
// ・名声の量は KirokuKousin.dart の対校戦の名声と同じ(結果画面の説明文・shiyou_text.dart とも同じ値)
// ------------------------------------------------------------

/// 対校戦の個人の順位ごとの名声(1位から8位。KirokuKousin.dart と同じ)
const List<int> _kojinMeisei = [100, 50, 40, 18, 16, 14, 12, 10];

/// 対校戦の総合の順位ごとの名声(1位から3位。KirokuKousin.dart と同じ)
const List<int> _sougouMeisei = [1000, 500, 400];

/// 自分の大学の選手の色(個人順位の一覧で使う。お知らせの枠と同じ)
const Color taikousenJibunIro = oshiraseIro;

/// 対校戦の入賞のお知らせの枠(知らせることがなければ何も出さない)
class TaikousenNyuushouOshirase extends StatelessWidget {
  const TaikousenNyuushouOshirase({
    super.key,
    required this.gh,
    required this.senshu,
    required this.univ,
  });

  final Ghensuu gh;

  /// 全大学の選手
  final List<SenshuData> senshu;

  /// 大学(IDの順)
  final List<UnivData> univ;

  @override
  Widget build(BuildContext context) {
    final int race = gh.hyojiracebangou;
    if (race < 6 || race > 8) return const SizedBox.shrink();
    if (oshiraseSkipChuu()) return const SizedBox.shrink();
    // 総合の順位(ハーフのあとだけ。0が1位。3位以内でなければnull)
    int? sougou;
    if (race == 8 && gh.MYunivid >= 0 && gh.MYunivid < univ.length) {
      final UnivData u = univ[gh.MYunivid];
      if (u.juni_race.length > 9 && u.juni_race[9].isNotEmpty) {
        final int j = u.juni_race[9][0];
        if (j >= 0 && j < _sougouMeisei.length) sougou = j;
      }
    }
    // 自分の大学の、個人8位以内の選手(順位の順)
    final List<({SenshuData s, int juni})> nyuushou = [];
    for (final SenshuData s in senshu) {
      if (s.univid != gh.MYunivid) continue;
      final int g = s.gakunen - 1;
      if (g < 0 || s.kukanjuni_race.length <= race || s.kukanjuni_race[race].length <= g) continue;
      final int juni = s.kukanjuni_race[race][g];
      if (juni < 0 || juni >= _kojinMeisei.length) continue;
      nyuushou.add((s: s, juni: juni));
    }
    if (nyuushou.isEmpty && sougou == null) return const SizedBox.shrink();
    nyuushou.sort((a, b) => a.juni.compareTo(b.juni));
    final bool kojinYuushou = nyuushou.isNotEmpty && nyuushou.first.juni == 0;
    final String midashi = sougou == 0
        ? '総合優勝！'
        : (kojinYuushou ? '優勝！' : (sougou != null ? '総合3位以内' : '入賞！'));
    final TextStyle usui = TextStyle(
      color: HENSUU.textcolor.withOpacity(0.75),
      fontSize: HENSUU.fontsize_honbun,
    );
    return OshiraseWaku(
      midashi: midashi,
      naka: [
        if (sougou != null) ...[
          Text(
            sougou == 0 ? '3種目を合わせた総合で優勝しました。' : '3種目を合わせた総合で${sougou + 1}位に入りました。',
            style: oshiraseHonbun,
          ),
          Text('大学の名声+${_sougouMeisei[sougou]}', style: usui),
          if (nyuushou.isNotEmpty) const SizedBox(height: 8),
        ],
        if (nyuushou.isNotEmpty)
          Text('自分の大学から${nyuushou.length}人が、個人8位以内に入りました。', style: oshiraseHonbun),
        for (final ({SenshuData s, int juni}) x in nyuushou) ...[
          const SizedBox(height: 6),
          Text(
            '${x.juni + 1}位　${x.s.name}(${x.s.gakunen}年${shushouShirushi(x.s)})　'
            '${TimeDate.timeToFunByouString(x.s.kukantime_race[race][x.s.gakunen - 1])}',
            style: oshiraseHonbun,
          ),
          Text('大学の名声+${_kojinMeisei[x.juni]}', style: usui),
        ],
      ],
    );
  }
}
