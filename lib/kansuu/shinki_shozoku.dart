import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/ShozokusakiKettei_By_Univmeisei.dart';
import 'package:ekiden/kansuu/Ikusei_Com.dart';
import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';
import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';

// ------------------------------------------------------------
// 新規ゲーム開始時(リセットを含む)の、全選手の所属先の決定と、2〜4年生の初期の育成(1.8.4)
// 1.8.3までは、全学年を入学時5000mの記録の順に名声で振り分けてから2〜4年生を育成していた。
// 初期の育成では成長タイプの倍率が大きく、ほぼ全員が成長の上限まで伸びるため、
// 振り分けた順(入学時の記録)と育成後の強さがほとんど揃わず、大学ごとの差が小さくなって、
// 名声の低い大学でも1年目から駅伝予選を突破することがあった。
// そこで、2〜4年生は先に育成してから(所属先が決まっていないので、育成力は全員150)、
// 育成後の強さの順に、今まで通り名声で振り分ける。
// 1年生は今まで通り入学時5000mの記録の順に振り分ける。
// 毎年4月の新入生の振り分け(RetireNew.dart)は変えていない。
// ------------------------------------------------------------

/// 新規ゲーム開始時の2〜4年生を振り分ける順に使う強さ(秒。小さいほど強い)
/// ハーフマラソンの理論タイム(RironTimeと同じ計算だが、選手のa・bは変えない)に、
/// 正月駅伝予選と同じ効き方(ロード適性とペース変動対応力は半分)で、
/// 長距離粘り・スパート力・ロード適性・ペース変動対応力の補正を足す。
/// 大学の個性・年間強化練習・能力のタイムへの影響度の設定は、所属先が決まる前なので入れない
double shokiTsuyosaTime(SenshuData senshu) {
  const double kyori = 21097.5;
  const int newbint = 1645; // RironTimeでのハーフマラソンの距離のb
  final int bInt = (senshu.b * 10000.0).toInt();
  final int aInt = (senshu.a * 1000000000.0).toInt();
  final int aMinInt =
      (bInt * bInt * 0.0333 - bInt * 114.25 + senshu.magicnumber).toInt();
  final int newAMinInt =
      (newbint * newbint * 0.0333 - newbint * 114.25 + senshu.magicnumber)
          .toInt();
  final double a = (newAMinInt + (aInt - aMinInt)) * 0.000000001;
  final double b = newbint * 0.0001;
  double time = a * kyori * kyori + b * kyori;
  // ロード適性とペース変動対応力(RaceCalcの正月駅伝予選と同じく、それぞれ半分だけ効かせる)
  time += time * (100 - senshu.tandokusou) * (0.03 / 100.0) * 0.5;
  time += time * (100 - senshu.paceagesagetaiouryoku) * (0.03 / 100.0) * 0.5;
  // 長距離粘りとスパート力
  time += ChoukyoriNebariHoseitime(
    kyori: kyori,
    choukyorinebari: senshu.choukyorinebari,
    zentaiyokuseiti: 0,
  );
  time += SpurtRyokuHoseitime(kyori: kyori, spurtRyoku: senshu.spurtryoku);
  return time;
}

/// 新規ゲーム開始時(リセットを含む)に、2〜4年生を育成してから、全選手の所属先を決める
/// (SenshuShokitiSetteiByGakunen(0)で全選手を作り直し、大学の名声を決めたあとに呼ぶ。
///  2〜4年生の成長タイプの付け直しは、呼び出し側で今まで通り行う)
Future<void> shinkiGameShozokuKettei({required Ghensuu ghensuu}) async {
  final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
  final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
  final List<UnivData> sortedUnivsById = univBox.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final List<SenshuData> sortedSenshuById = senshuBox.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  // 1. 2〜4年生を先に育成する(春と夏の分で2回。所属先が決まる前なので、育成力は全員150)
  for (int i = 0; i < 2; i++) {
    for (int gakunen = 2; gakunen <= 4; gakunen++) {
      print('学年 $gakunen の選手を育成中(所属先を決める前)...');
      await Ikusei_Com(
        gh: [ghensuu],
        sortedunivdata: sortedUnivsById,
        sortedsenshudata: sortedSenshuById,
        gakunen: gakunen,
        shozokuKetteiMae: true,
      );
    }
  }

  // 2. 育成後の強さ(2〜4年生の並べ替えに使う。並べ替えの中で何度も計算しないように先に求める)
  final Map<int, double> tsuyosa = {
    for (final SenshuData s in sortedSenshuById) s.id: shokiTsuyosaTime(s),
  };

  // 3. 学年ごとに名声で振り分ける
  //    1年生は入学時5000mの記録の順、2〜4年生は育成後の強さの順
  //    (留学生の受け入れは、今まで通り最初に振り分ける1年生で行われる)
  for (int gakunen = 1; gakunen <= 4; gakunen++) {
    final List<SenshuData> narabi = sortedSenshuById.toList();
    if (gakunen == 1) {
      narabi.sort(
        (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
      );
    } else {
      narabi.sort((a, b) {
        final int hikaku = tsuyosa[a.id]!.compareTo(tsuyosa[b.id]!);
        if (hikaku != 0) return hikaku;
        return a.id.compareTo(b.id);
      });
    }
    await ShozokusakiKettei_By_Univmeisei(
      sortedunivdata: sortedUnivsById,
      nyuugakuji5000_senshudata: narabi,
      gakunen: gakunen,
      ghensuu: ghensuu,
    );
  }

  // 4. 変更した選手データをHiveに保存し直す
  for (final SenshuData s in sortedSenshuById) {
    await senshuBox.put(s.id, s);
  }
}
