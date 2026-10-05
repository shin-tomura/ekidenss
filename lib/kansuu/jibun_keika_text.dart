import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/setsumei_sontoku.dart'; // 補正の損得と指示の成否の書き足し(1.8.8)

// ------------------------------------------------------------
// 自分の大学のレース経過のテキスト(1.8.2)
// レース画面の「自分の大学のレース経過をコピー」と、生成AIに渡すテキストのまとめボタンで使う。
// 目標順位による悪化の文には根拠を付けない(1.8.3。根拠は走った時点で記録した補正の説明に出る)
// 結果分析([分析])は出さない(1.8.4。その区間を走った選手の中だけの相対値で、選手全体の評価や
// ほかの区間との比較と読み違えやすく、見抜く力がついていない能力の手がかりにもなるため。
// 秒数での内訳は補正の説明にある)
// ------------------------------------------------------------

/// 自分の大学のレース経過のテキスト(生成AIに渡して実況や相談を楽しむためのコピー用)
/// レース画面の「直近区間」「ここまでの全区間」と同じ内容(指示の内容と結果、補正の説明)に、
/// 順位・タイム差と、まだ走っていない区間の選手を加える
String jibunRaceKeikaText(Ghensuu currentGhensuu) {
  const List<String> kekka = ["失敗", "成功"];
  final int race = currentGhensuu.hyojiracebangou;
  final List<UnivData> univs = Hive.box<UnivData>('univBox').values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final UnivData my = univs[currentGhensuu.MYunivid];
  final int kukansuu = currentGhensuu.kukansuu_taikaigoto[race];
  final int hashitta = min(currentGhensuu.nowracecalckukan, kukansuu);
  final bool kumi = race == 3; // 11月駅伝予選は「組」
  final String kuLabel = kumi ? "組" : "区";
  final String juniLabel = kumi ? "組内" : "区間";
  final int mokuhyou = my.mokuhyojuni[race]; // 0が1位
  int seed = -1; // シード権の最下位(0が1位)
  if (race == 1) seed = 7;
  if (race == 2) seed = 9;
  final List<UnivData> shutsujou = univs
      .where(
        (u) => u.taikaientryflag.length > race && u.taikaientryflag[race] == 1,
      )
      .toList();
  // 自分の大学の選手(レース画面と同じく、学年の高い順・id順)
  final List<SenshuData> senshu =
      Hive.box<SenshuData>('senshuBox').values
          .where((s) => s.univid == currentGhensuu.MYunivid)
          .toList()
        ..sort((a, b) {
          final int gakunenComparison = b.gakunen.compareTo(a.gakunen);
          if (gakunenComparison != 0) return gakunenComparison;
          return a.id.compareTo(b.id);
        });
  String raceMei;
  switch (race) {
    case 0:
      raceMei = "10月駅伝";
      break;
    case 1:
      raceMei = "11月駅伝";
      break;
    case 2:
      raceMei = "正月駅伝";
      break;
    case 3:
      raceMei = "11月駅伝予選";
      break;
    case 5:
      raceMei = univs[0].name_tanshuku;
      break;
    default:
      raceMei = "";
  }
  String saBun(double sa) {
    final String fugou = sa.isNegative ? '-' : '+';
    final int byou = sa.abs().round();
    if (byou < 60) return '$fugou$byou秒';
    return '$fugou${byou ~/ 60}分${byou % 60}秒';
  }

  final StringBuffer sb = StringBuffer();
  sb.write(
    '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n',
  );
  sb.write(setsumeiSontokuChuui);
  sb.write(
    '※[補正の説明]の「○位」は、その${kumi ? '組' : '区間'}を走った選手の中での順位です(選手全体の中での順位ではありません)。\n',
  );
  sb.writeln('【$raceMei ${my.name}大学 レース経過】');
  sb.writeln('目標順位:${mokuhyou + 1}位');
  sb.writeln("-----------------------------------");
  for (int k = 0; k < kukansuu; k++) {
    final int kyori = currentGhensuu.kyori_taikai_kukangoto[race][k].round();
    final List<SenshuData> hashiru = senshu
        .where((x) => x.entrykukan_race[race][x.gakunen - 1] == k)
        .toList();
    final String namae = hashiru.isEmpty
        ? '(選手が決まっていません)'
        : hashiru.map((x) => '${x.name}(${x.gakunen}年)').join('、');
    sb.writeln('${k + 1}$kuLabel(${kyori}m) $namae');
    if (k >= hashitta) {
      sb.writeln('  これから走る');
      sb.writeln("-----------------------------------");
      continue;
    }
    // チームの順位とタイム
    final double tuuka = my.time_taikai_total[k];
    final double kukanTime = k == 0
        ? tuuka
        : tuuka - my.time_taikai_total[k - 1];
    sb.writeln(
      '  $juniLabel順位:${my.kukanjuni_taikai[k] + 1}位 '
      '${TimeDate.timeToFunByouString(kukanTime)}',
    );
    String hendou = '';
    if (k > 0) {
      final int sa = my.tuukajuni_taikai[k - 1] - my.tuukajuni_taikai[k];
      hendou = sa > 0 ? ' ↑$sa' : (sa < 0 ? ' ↓${sa.abs()}' : ' →');
    }
    sb.writeln(
      '  通過順位:${my.tuukajuni_taikai[k] + 1}位 '
      '${TimeDate.timeToJikanFunByouString(tuuka)}$hendou',
    );
    // トップ・目標順位・シード権との差
    final List<double> times =
        shutsujou
            .where((u) => u.time_taikai_total.length > k)
            .map((u) => u.time_taikai_total[k])
            .where((t) => t > 0 && t < TEISUU.DEFAULTTIME)
            .toList()
          ..sort();
    final List<String> saList = [];
    if (times.isNotEmpty) {
      saList.add('トップとの差:${saBun(tuuka - times[0])}');
    }
    if (mokuhyou >= 0 && mokuhyou < times.length) {
      saList.add('目標順位(${mokuhyou + 1}位)との差:${saBun(tuuka - times[mokuhyou])}');
    }
    if (seed >= 0 && seed < times.length) {
      saList.add('シード権(${seed + 1}位)との差:${saBun(tuuka - times[seed])}');
    }
    if (saList.isNotEmpty) sb.writeln('  (${saList.join('、')})');
    // 走った選手ごとの指示の内容と結果、補正の説明(画面と同じ決まり。結果分析は出さない。1.8.4)
    for (final SenshuData x in hashiru) {
      if (hashiru.length > 1 || kumi) sb.writeln('  ${x.name}(${x.gakunen}年)');
      if (kumi) {
        sb.writeln(
          '  組内順位:${x.temp_juni + 1}位 '
          '${TimeDate.timeToFunByouString(x.time_taikai_total)}',
        );
      }
      final int sijiflag = x.sijiflag.clamp(0, 2).toInt();
      String sijiResult = "";
      List<String> options;
      if (k == 0 || kumi) {
        options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
        if (x.startchokugotobidasiflag == 1) {
          sijiResult =
              "スタート直後飛び出して:${kekka[x.startchokugotobidasiseikouflag.clamp(0, 1).toInt()]}";
        }
      } else {
        options = ["指示なし", "前半から突っ込む", "前半は抑える"];
        if (sijiflag >= 1) {
          sijiResult = "結果:${kekka[x.sijiseikouflag.clamp(0, 1).toInt()]}";
        } else if (my.mokuhyojuniwositamawatteruflag[k - 1] == 1) {
          // 根拠(襷を受けた時点の順位・目標順位・差)は、走った時点で記録した補正の説明に出る(1.8.3)
          sijiResult = "チーム目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり";
        } else if (my.mokuhyojuniwositamawatteruflag[k - 1] < 0) {
          sijiResult = "チーム目標順位を上回っていたことによるほっと一息でのタイム悪化あり";
        }
      }
      sb.writeln('  指示内容:${options[sijiflag]}');
      if (sijiResult.isNotEmpty) sb.writeln('  $sijiResult');
      if (x.string_racesetumei.trim().isNotEmpty) {
        sb.writeln('  [補正の説明]');
        // 補正の秒数に損得(指示は成否も)を書き足す(1.8.8)
        for (final String gyou in setsumeiSontokuTsuki(
          x.string_racesetumei.trimRight(),
        ).split('\n')) {
          sb.writeln('   $gyou');
        }
      }
    }
    sb.writeln("-----------------------------------");
  }
  if (hashitta >= kukansuu && kukansuu > 0) {
    final int last = kukansuu - 1;
    sb.writeln(
      '総合:${my.tuukajuni_taikai[last] + 1}位 '
      '${TimeDate.timeToJikanFunByouString(my.time_taikai_total[last])}',
    );
  }
  sb.writeln('');
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}
