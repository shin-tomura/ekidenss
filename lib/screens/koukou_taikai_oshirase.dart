import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/kansuu/koukou.dart';
import 'package:ekiden/screens/Modal_koukouMeikan.dart' show KoukouTaikaiShinkouGamen;
import 'package:ekiden/screens/kiji_screen.dart' show KijiLinkCard, kijiKoukouHiraku; // 高校の大会の記事(2.0.4)
import 'package:ekiden/kansuu/kiji/kiji.dart' show kijiKoukouShinkouIchiran;

// ------------------------------------------------------------
// 高校の大会の結果が出た日のお知らせ(2.0.4)
// ・7月下旬(高校総体)・11月中旬(都道府県予選と地区大会)・12月下旬(全国高校駅伝)に、その日の画面に出す
//   (7月下旬と、記録会を11月にしている設定の11月中旬はレースの結果の画面、ほかはその日の画面)
// ・「結果を見る」で、今の高校3年生の世代の回の画面(Modal_koukouMeikan.dart の KoukouTaikaiShinkouGamen)を開く
// ・その日の箱庭スポーツの記事のカードも置く(2.0.4。見出しを予告し、今年度の高校の大会の記事の一覧を開く)
// ・スキップ中・高校の情報を表示しない設定のとき・その世代の回がないとき(7月下旬に計算していない年度)は出さない
// ------------------------------------------------------------

/// お知らせの文(出さないときは空)
String koukouTaikaiOshiraseBun(Ghensuu gh) {
  int dankai = 0;
  if (gh.month == koukouSoutaiMonth && gh.day == koukouSoutaiDay) {
    dankai = 1;
  } else if (gh.month == koukouYosenMonth && gh.day == koukouYosenDay) {
    dankai = 2;
  } else if (gh.month == koukouZenkokuMonth && gh.day == koukouZenkokuDay) {
    dankai = 3;
  }
  if (dankai == 0) return '';
  if (Hive.isBoxOpen('skipBox')) {
    final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
    if (skip != null && skip.skipflag != 0) return '';
  }
  if (Hive.isBoxOpen('kantokuBox')) {
    final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    if (kantoku != null && koukouHyoujiNashi(kantoku)) return '';
  }
  final int nendo = gh.month >= 4 ? gh.year : gh.year - 1;
  KoukouTaikaiKiroku? k;
  for (final KoukouTaikaiKiroku r in koukouTaikaiKirokuYomu()) {
    if (r.nyuugakuNendo == nendo + 1) {
      k = r;
      break;
    }
  }
  if (k == null || k.happyou < dankai) return '';
  switch (dankai) {
    case 1:
      return '今の高校3年生(次の4月に大学に入る世代)の高校総体が行われました。'
          '1500m・5000m・3000m障害の決勝の結果を見られます。';
    case 2:
      return '全国高校駅伝の都道府県予選と地区大会が行われ、12月下旬の全国高校駅伝に出る高校が決まりました。';
    default:
      final String yuushou = k.zenkoku.isEmpty ? '' : k.kouMei(k.zenkoku.first.kouCode);
      return yuushou.isEmpty ? '全国高校駅伝が行われました。' : '全国高校駅伝が行われ、$yuushouが優勝しました。';
  }
}

/// 高校の大会の結果が出た日のお知らせのカード(出さない日は何も出さない)
class KoukouTaikaiOshirase extends StatelessWidget {
  const KoukouTaikaiOshirase({super.key, required this.gh});

  final Ghensuu gh;

  @override
  Widget build(BuildContext context) {
    final String bun = koukouTaikaiOshiraseBun(gh);
    if (bun.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.lightBlueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '高校の大会',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(bun, style: const TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const KoukouTaikaiShinkouGamen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: HENSUU.buttonColor,
              foregroundColor: HENSUU.buttonTextColor,
            ),
            child: const Text('結果を見る'),
          ),
          // 箱庭スポーツの記事(その日の大会の記事が一番上。2.0.4)
          const SizedBox(height: 12),
          KijiLinkCard(
            key: ValueKey('kijiKoukou_${gh.year}_${gh.month}_${gh.day}'),
            namae: 'ニュース記事(箱庭スポーツ)',
            tsukuru: kijiKoukouShinkouIchiran,
            hiraku: kijiKoukouHiraku,
            annai: '高校の大会の記事です。高校名鑑の「大会の記録」からも、次の7月下旬まで読み返せます',
          ),
        ],
      ),
    );
  }
}
