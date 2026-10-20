import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/shushou.dart'; // 主将の印(「4年・主将」)

// ------------------------------------------------------------
// 対校戦の入賞のお知らせ(2.1.0)
// ・対校戦の種目(5000m・1万m・ハーフ)の結果画面の一番上に、自分の大学の選手が個人8位以内に
//   入ったことを枠で知らせる(ダイアログではないので、押さなくても進める)。1位がいれば見出しは「優勝！」
// ・セーブ済みの順位(kukanjuni_race)から画面を描くたびに作る(セーブデータは増やさない)
// ・入賞者がいないときと、スキップ中は出さない
// ・名声の量は KirokuKousin.dart の対校戦の個人の名声と同じ(結果画面の説明文・shiyou_text.dart とも同じ値)
// ------------------------------------------------------------

/// 対校戦の個人の順位ごとの名声(1位から8位。KirokuKousin.dart と同じ)
const List<int> _kojinMeisei = [100, 50, 40, 18, 16, 14, 12, 10];

/// 枠と、自分の大学の選手の色(情報集約パネルの自分の大学と同じ)
const Color taikousenJibunIro = Colors.orangeAccent;

/// 対校戦の入賞のお知らせの枠(入賞者がいなければ何も出さない)
class TaikousenNyuushouOshirase extends StatelessWidget {
  const TaikousenNyuushouOshirase({
    super.key,
    required this.gh,
    required this.senshu,
  });

  final Ghensuu gh;

  /// 全大学の選手
  final List<SenshuData> senshu;

  @override
  Widget build(BuildContext context) {
    final int race = gh.hyojiracebangou;
    if (race < 6 || race > 8) return const SizedBox.shrink();
    if (Hive.isBoxOpen('skipBox')) {
      final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
      if (skip != null && skip.skipflag != 0) return const SizedBox.shrink();
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
    if (nyuushou.isEmpty) return const SizedBox.shrink();
    nyuushou.sort((a, b) => a.juni.compareTo(b.juni));
    final bool yuushou = nyuushou.first.juni == 0;
    const TextStyle honbun = TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: taikousenJibunIro, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            yuushou ? '優勝！' : '入賞！',
            style: const TextStyle(
              color: taikousenJibunIro,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('自分の大学から${nyuushou.length}人が、個人8位以内に入りました。', style: honbun),
          for (final ({SenshuData s, int juni}) x in nyuushou) ...[
            const SizedBox(height: 6),
            Text(
              '${x.juni + 1}位　${x.s.name}(${x.s.gakunen}年${shushouShirushi(x.s)})　'
              '${TimeDate.timeToFunByouString(x.s.kukantime_race[race][x.s.gakunen - 1])}',
              style: honbun,
            ),
            Text(
              '大学の名声+${_kojinMeisei[x.juni]}',
              style: TextStyle(
                color: HENSUU.textcolor.withOpacity(0.75),
                fontSize: HENSUU.fontsize_honbun,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
