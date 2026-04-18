import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/screens/ModalAverageTimeRankingView.dart';

// 予想結果を保持するためのクラス
class Prediction {
  final int id;
  final String name;
  final double score;

  Prediction(this.id, this.name, this.score);
}

List<int> kukanshou_bestscore_osshi = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  999999999,
);
List<int> kukanshou_id_osshi = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
List<double> kukanshou_bestscore_tochan = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  -999999999.0,
);
List<int> kukanshou_id_tochan = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
List<double> kukanshou_bestscore_otaro = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  TEISUU.DEFAULTTIME,
);
List<int> kukanshou_id_otaro = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
int temp_osshi_score = 0;
double temp_tochan_score = 0.0;
double temp_otaro_score = 0.0;

class Mode0330Content extends StatelessWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0330Content({super.key, required this.ghensuu, this.onAdvanceMode});

  // ゲームを進めるボタンのアクション
  void _advanceGameMode() {
    onAdvanceMode?.call();
  }

  // 複数の大学の予想結果から順位を決定する関数
  List<Prediction> _getRankedPredictions(
    List<Prediction> predictions,
    bool isAscending, // trueなら昇順、falseなら降順
  ) {
    // スコアでソート
    final sortedPredictions = predictions.toList()
      ..sort((a, b) {
        final comparison = a.score.compareTo(b.score);
        return isAscending ? comparison : -comparison;
      });

    // 順位を計算して新しいリストを作成
    final rankedList = <Prediction>[];
    int currentRank = 1;
    for (int i = 0; i < sortedPredictions.length; i++) {
      final current = sortedPredictions[i];
      if (i > 0 && current.score != sortedPredictions[i - 1].score) {
        currentRank = i + 1;
      }
      rankedList.add(
        Prediction(
          current.id,
          '${currentRank}位 ${current.name}',
          current.score,
        ),
      );
    }
    return rankedList;
  }

  // 各大学の合計スコアを計算する関数
  Map<String, List<Prediction>> _calculateAllPredictions(
    int raceNumber,
    List<UnivData> sortedUnivData,
    List<SenshuData> sortedSenshuData,
  ) {
    // Randomインスタンスを作成
    final random = Random();
    // 予想結果を格納するためのマップ
    final Map<String, List<Prediction>> allPredictions = {
      'osshi': [],
      'tochan': [],
      'otaro': [],
    };
    final gh = Hive.box<Ghensuu>('ghensuuBox').values.toList();
    if (gh.isEmpty) {
      return allPredictions;
    }
    for (int i = 0; i < TEISUU.SUU_MAXKUKANSUU; i++) {
      kukanshou_bestscore_osshi[i] = 999999999;
      kukanshou_bestscore_otaro[i] = TEISUU.DEFAULTTIME;
      kukanshou_bestscore_tochan[i] = -999999999.0;
    }
    // 各大学について計算
    for (final univ in sortedUnivData) {
      if (univ.taikaientryflag.length > raceNumber &&
          univ.taikaientryflag[raceNumber] == 1) {
        // 出場大学のみを対象とする
        double osshiScore = 0.0;
        double tochanScore = 0.0;
        double otaroScore = 0.0;
        int entryCount = 0;
        int max1_osshiscore = -999999999;
        int max2_osshiscore = -999999999;
        double max1_otaroscore = -999999999.0;
        double max2_otaroscore = -999999999.0;
        double min1_tochanscore = 999999999.0;
        double min2_tochanscore = 999999999.0;

        // 出場選手を合計する
        for (final senshu in sortedSenshuData) {
          if (senshu.univid == univ.id) {
            // entrykukan_raceが定義されており、かつレース番号に対応する区間情報があるかを確認
            if (senshu.entrykukan_race.length > raceNumber &&
                senshu.entrykukan_race[raceNumber][senshu.gakunen - 1] >= 0) {
              entryCount++;
              // オッシー：magicnumber（小さい方が良い）
              //osshiScore += senshu.magicnumber;
              temp_osshi_score = _NEWaintFromNewbint(1580, senshu);
              osshiScore += temp_osshi_score;
              if (raceNumber == 4) {
                if (temp_osshi_score > max1_osshiscore) {
                  max2_osshiscore = max1_osshiscore;
                  max1_osshiscore = temp_osshi_score;
                } else if (temp_osshi_score > max2_osshiscore) {
                  max2_osshiscore = temp_osshi_score;
                }
              }
              if (temp_osshi_score <
                  kukanshou_bestscore_osshi[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_osshi[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_osshi_score;
                kukanshou_id_osshi[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }
              // 王太郎：入学時の持ちタイム（小さい方が良い）
              if (senshu.kiroku_nyuugakuji_5000 == TEISUU.DEFAULTTIME) {
                final double originalScore = 60.0 * 13.0; // 780.0
                // ランダムな変動幅を計算 (0.1%)
                final double variation =
                    originalScore * 0.001; // 780.0 * 0.001 = 0.78
                // -variation から +variation の範囲でランダムな値を生成
                // nextDouble() は 0.0 以上 1.0 未満の値を返す
                // 0.0 から 2.0 * variation の範囲の値を生成し、そこから variation を引くことで
                // -variation から +variation の範囲にする
                final double randomOffset =
                    (random.nextDouble() * 2 * variation) - variation;
                // 新しいスコアを計算
                temp_otaro_score = originalScore + randomOffset;
                //temp_otaro_score = 60.0 * 13.0;
              } else {
                temp_otaro_score = senshu.kiroku_nyuugakuji_5000;
              }
              otaroScore += temp_otaro_score;
              if (raceNumber == 4) {
                if (temp_otaro_score > max1_otaroscore) {
                  max2_otaroscore = max1_otaroscore;
                  max1_otaroscore = temp_otaro_score;
                } else if (temp_otaro_score > max2_otaroscore) {
                  max2_otaroscore = temp_otaro_score;
                }
              }
              if (temp_otaro_score <
                  kukanshou_bestscore_otaro[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_otaro[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_otaro_score;
                kukanshou_id_otaro[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }

              // 父ちゃん：合計値（大きい方が良い）
              // --- 父ちゃんの予測精度を向上させるための新しい計算ロジック ---
              // ※ここではgh[0].kyori_taikai_kukangotoなどのデータが
              //   正しく存在することを前提とします。
              // 各区間の合計スコアを計算
              int kukanIndex =
                  senshu.entrykukan_race[raceNumber][senshu.gakunen - 1];
              double kukanKyoriScore =
                  0.01 * gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanNoboriScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariainobori_taikai_kukangoto[raceNumber][kukanIndex] *
                  gh[0]
                      .heikinkoubainobori_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanKudariScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariaikudari_taikai_kukangoto[raceNumber][kukanIndex] *
                  gh[0]
                      .heikinkoubaikudari_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanKirikaeScore =
                  4.0 *
                  gh[0]
                      .noborikudarikirikaekaisuu_taikai_kukangoto[raceNumber][kukanIndex]
                      .toDouble();
              kukanKudariScore = kukanKudariScore.abs();
              double senshuKyoriScore = 0;
              double kukanbetuhosei = 0.0;
              double hosei_tani = 0.0;
              double hosei_time = 0.0;
              double temp_time = 0.0;
              if (senshu.time_bestkiroku.length > 2 &&
                  gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex] >
                      15000) {
                temp_time = senshu.time_bestkiroku[2];
                //temp_time = 1.0;
                hosei_tani = 105.4875 / 100.0;
                if ((kukanIndex == 0 && raceNumber != 4) || raceNumber == 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time + hosei_time;
                }
                if (((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) ||
                    raceNumber == 4) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time + hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  //補正なし
                }
                senshuKyoriScore = (-5 / 12) * temp_time + 1625;
              } else if (senshu.time_bestkiroku.length > 1 &&
                  gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex] > 7500) {
                temp_time = senshu.time_bestkiroku[1];
                //temp_time = 1.0;
                hosei_tani = 50.0 / 100.0;
                if (kukanIndex == 0 || raceNumber == 3) {
                  //補正なし
                }
                if ((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
              } else if (senshu.time_bestkiroku.length > 0) {
                temp_time = senshu.time_bestkiroku[0];
                //temp_time = 1.0;
                hosei_tani = 25.0 / 100.0;
                if (kukanIndex == 0 || raceNumber == 3) {
                  //補正なし
                }
                if ((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 3) * temp_time + 2850;
              }
              senshuKyoriScore *= 7;
              double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
              double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
              double senshuKirikaeScore =
                  3 * senshu.noborikudarikirikaenouryoku.toDouble();
              double specialScore = 0;
              specialScore = 0;
              double totalScore =
                  (kukanKyoriScore * senshuKyoriScore) +
                  (kukanNoboriScore * senshuNoboriScore) +
                  (kukanKudariScore * senshuKudariScore) +
                  (kukanKirikaeScore * senshuKirikaeScore) +
                  specialScore;
              if (totalScore.isNaN) {
                totalScore = -99999.0;
              }
              temp_tochan_score = totalScore;
              if (temp_tochan_score >
                  kukanshou_bestscore_tochan[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_tochan[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_tochan_score;
                kukanshou_id_tochan[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }
              // 各選手の合計スコアを父ちゃんのスコアに加算
              tochanScore += totalScore;
              if (raceNumber == 4) {
                if (temp_tochan_score < min1_tochanscore) {
                  //min2_tochanscore = min1_tochanscore;
                  min1_tochanscore = temp_tochan_score;
                  //} else if (temp_tochan_score < min2_tochanscore) {
                  //  min2_tochanscore = temp_tochan_score;
                }
              }
            }
          }
        }
        if (raceNumber == 4) {
          osshiScore -= (max1_osshiscore + max2_osshiscore);
          otaroScore -= (max1_otaroscore + max2_otaroscore);
          //tochanScore -= (min1_tochanscore + min2_tochanscore);
          tochanScore -= min1_tochanscore;
        }

        // 選手が1人以上エントリーしている場合のみ結果に追加
        if (entryCount > 0) {
          //print("${entryCount}人エントリー");
          allPredictions['osshi']!.add(
            Prediction(univ.id, univ.name, osshiScore),
          );
          allPredictions['tochan']!.add(
            Prediction(univ.id, univ.name, tochanScore),
          );
          allPredictions['otaro']!.add(
            Prediction(univ.id, univ.name, otaroScore),
          );
        }
      }
    }
    return allPredictions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body: ValueListenableBuilder<Box<Ghensuu>>(
        valueListenable: Hive.box<Ghensuu>('ghensuuBox').listenable(),
        builder: (context, ghensuuBox, _) {
          final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');
          if (currentGhensuu == null) {
            return const Center(
              child: CircularProgressIndicator(color: HENSUU.textcolor),
            );
          }
          String racestring = "";
          if (currentGhensuu.hyojiracebangou == 0) {
            racestring = "10月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 1) {
            racestring = "11月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 2) {
            racestring = "正月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 3) {
            racestring = "11月駅伝予選";
          }
          if (currentGhensuu.hyojiracebangou == 4) {
            racestring = "正月駅伝予選";
          }

          return ValueListenableBuilder<Box<UnivData>>(
            valueListenable: Hive.box<UnivData>('univBox').listenable(),
            builder: (context, univdataBox, _) {
              //final List<UnivData> allUnivData = univdataBox.values.toList();
              List<UnivData> sortedUnivData = univdataBox.values.toList();
              sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
              if (currentGhensuu.hyojiracebangou == 5) {
                racestring = sortedUnivData[0].name_tanshuku;
              }
              return ValueListenableBuilder<Box<SenshuData>>(
                valueListenable: Hive.box<SenshuData>('senshuBox').listenable(),
                builder: (context, senshudataBox, _) {
                  //final List<SenshuData> allSenshuData = senshudataBox.values
                  //    .toList();
                  List<SenshuData> sortedSenshuData = senshudataBox.values
                      .toList();
                  sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

                  // 予想を計算
                  final Map<String, List<Prediction>> allPredictions =
                      _calculateAllPredictions(
                        currentGhensuu.hyojiracebangou,
                        sortedUnivData,
                        sortedSenshuData,
                      );

                  // 順位付け
                  final List<Prediction> osshiRanked = _getRankedPredictions(
                    allPredictions['osshi']!,
                    true,
                  );
                  final List<Prediction> tochanRanked = _getRankedPredictions(
                    allPredictions['tochan']!,
                    false,
                  );
                  final List<Prediction> otaroRanked = _getRankedPredictions(
                    allPredictions['otaro']!,
                    true,
                  );

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentGhensuu.hyojiracebangou != 4)
                              ElevatedButton(
                                onPressed: () async {
                                  currentGhensuu.mode = 300;
                                  await currentGhensuu.save();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HENSUU.buttonColor,
                                  foregroundColor: HENSUU.buttonTextColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("戻る"),
                              ),
                            Expanded(
                              child: Text(
                                "  ${racestring}直前順位予想!!",
                                style: const TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: onAdvanceMode != null
                                  ? _advanceGameMode
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HENSUU.buttonColor,
                                foregroundColor: HENSUU.buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("進む＞＞"),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: HENSUU.textcolor),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.8,
                                      ),
                                      barrierDismissible: true,
                                      barrierLabel: '区間エントリー選手持ちタイム大学ランキング',
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) {
                                            // ModalKukanEntryListViewはimportされていると仮定
                                            // ignore: unnecessary_cast
                                            return (const ModalAverageTimeRankingView())
                                                as Widget;
                                          },
                                      transitionBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOut,
                                              ),
                                              child: child,
                                            );
                                          },
                                    );
                                  },
                                  child: Text(
                                    "区間エントリー選手持ちタイム大学ランキング",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        0,
                                        255,
                                        0,
                                      ),
                                      decoration: TextDecoration.underline,
                                      decorationColor: HENSUU.textcolor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // オッシーの予想
                                const Text(
                                  "■ オッシーの予想 (基本走力重視)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in osshiRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 父ちゃんの予想
                                const Text(
                                  "■ 父ちゃんの予想 (持ちタイム+各能力の総合評価)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in tochanRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 王太郎の予想
                                const Text(
                                  "■ 王太郎の予想 (入学時持ちタイム重視)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in otaroRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 区間賞予想
                                if (currentGhensuu.hyojiracebangou <= 2 ||
                                    currentGhensuu.hyojiracebangou == 5)
                                  const Text(
                                    "■ 区間賞予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (currentGhensuu.hyojiracebangou == 3)
                                  const Text(
                                    "■ 各組個人1位予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (currentGhensuu.hyojiracebangou == 4)
                                  const Text(
                                    "■ 個人1位予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                if (currentGhensuu.hyojiracebangou <= 2 ||
                                    currentGhensuu.hyojiracebangou == 5)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        "${i_kukan + 1}区\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                                if (currentGhensuu.hyojiracebangou == 3)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        "${i_kukan + 1}組\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                                if (currentGhensuu.hyojiracebangou == 4)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        //"${i_kukan + 1}組\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  int _NEWaintFromNewbint(int Newbint, SenshuData senshu) {
    // 変数名はSwiftコードの指示通りにしています。
    int b_int = 0;
    int a_int = 0;
    int a_min_int = 0;
    int new_a_int = 0;
    int new_a_min_int = 0;
    int sa = 0;

    // 現在のaとbを整数に変換
    a_int = (senshu.a * 1000000000.0).toInt();
    b_int = (senshu.b * 10000.0).toInt();

    // 既存のb_intに基づいたa_min_intの計算
    a_min_int = (b_int * b_int * 0.0333 - b_int * 114.25 + senshu.magicnumber)
        .toInt();

    // aの差分を計算
    sa = a_int - a_min_int;

    // 新しいNewbintに基づいたnew_a_min_intの計算
    new_a_min_int =
        (Newbint * Newbint * 0.0333 - Newbint * 114.25 + senshu.magicnumber)
            .toInt();

    // 新しいa_intを計算
    new_a_int = new_a_min_int + sa;

    return new_a_int;
  }
}
