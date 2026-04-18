import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/TrialTime.dart';

/// 駅伝のルール設定クラス
class EkidenRuleConfig {
  final int totalSections; // 総区間数
  final int maxChangeTotal; // 合計当日変更可能人数

  final bool isTwoDays; // 2日間にわたるか
  final int day1SectionCount; // 1日目の区間数
  final int day1ChangeLimit; // 1日目の変更可能人数上限
  final int day2ChangeLimit; // 2日目の変更可能人数上限

  const EkidenRuleConfig({
    required this.totalSections,
    required this.maxChangeTotal,
    this.isTwoDays = false,
    this.day1SectionCount = 0,
    this.day1ChangeLimit = 0,
    this.day2ChangeLimit = 0,
  });

  factory EkidenRuleConfig.izumo() {
    return const EkidenRuleConfig(
      totalSections: 6,
      maxChangeTotal: 2,
      isTwoDays: false,
    );
  }
  factory EkidenRuleConfig.allJapan() {
    return const EkidenRuleConfig(
      totalSections: 8,
      maxChangeTotal: 5,
      isTwoDays: false,
    );
  }
  factory EkidenRuleConfig.hakone() {
    return const EkidenRuleConfig(
      totalSections: 10,
      maxChangeTotal: 6,
      isTwoDays: true,
      day1SectionCount: 5,
      day1ChangeLimit: 4,
      day2ChangeLimit: 4,
    );
  }
}

// --- ヘルパー関数 ---

/// kazetaiseiに理想区間(Pattern 0)のみを保存する
/// ※当日変更ロジックで「本来のエース」を識別するために使用
void _setIdealKukanToKazetaisei(SenshuData senshu, int kukanValue) {
  // -1を保存できないため +2 して保存
  int valueToStore = kukanValue + 2;
  // Pattern 0 の位置(最初の4bit)に保存
  senshu.kazetaisei &= ~0xF;
  senshu.kazetaisei |= valueToStore;
}

/// 区間適性スコアを計算する（コースデータ依存・固定概念排除版）
double _calculateSectionScore(
  SenshuData senshu,
  int kukanIndex,
  int racebangou,
  Ghensuu gh,
) {
  // 距離スコア
  double kukanKyoriScore =
      0.15 * gh.kyori_taikai_kukangoto[racebangou][kukanIndex];

  // 距離補正ロジック（旧コード準拠）
  double senshuKyoriScore = 0;
  double kukanbetuhosei = 0.0;
  double hosei_tani = 0.0;
  double hosei_time = 0.0;
  double temp_time = 0.0;

  if (senshu.time_bestkiroku.length > 2 &&
      gh.kyori_taikai_kukangoto[racebangou][kukanIndex] > 15000) {
    temp_time = senshu.time_bestkiroku[2];
    hosei_tani = 105.4875 / 100.0;
    if (kukanIndex == 0) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani;
      temp_time = temp_time + hosei_time;
    } else if (kukanIndex == 1 || kukanIndex == 2) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani * 0.5;
      temp_time = temp_time + hosei_time;
    }
    senshuKyoriScore = (-5 / 12) * temp_time + 1625;
  } else if (senshu.time_bestkiroku.length > 1 &&
      gh.kyori_taikai_kukangoto[racebangou][kukanIndex] > 7500) {
    temp_time = senshu.time_bestkiroku[1];
    hosei_tani = 50.0 / 100.0;
    if (kukanIndex == 1 || kukanIndex == 2) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani * 0.5;
      temp_time = temp_time - hosei_time;
    } else if (kukanIndex > 2) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani;
      temp_time = temp_time - hosei_time;
    }
    senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
  } else if (senshu.time_bestkiroku.isNotEmpty) {
    temp_time = senshu.time_bestkiroku[0];
    hosei_tani = 25.0 / 100.0;
    if (kukanIndex == 1 || kukanIndex == 2) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani * 0.5;
      temp_time = temp_time - hosei_time;
    } else if (kukanIndex > 2) {
      kukanbetuhosei =
          senshu.tandokusou.toDouble() -
          senshu.paceagesagetaiouryoku.toDouble();
      hosei_time = kukanbetuhosei * hosei_tani;
      temp_time = temp_time - hosei_time;
    }
    senshuKyoriScore = (-10 / 3) * temp_time + 2850;
  }
  senshuKyoriScore *= 7;

  // 登り・下り・切り替え適性（固定概念を排除し、ghデータのみで判定）
  double kukanNoboriScore =
      2 *
      7500.0 *
      gh.kyoriwariainobori_taikai_kukangoto[racebangou][kukanIndex] *
      gh.heikinkoubainobori_taikai_kukangoto[racebangou][kukanIndex];
  double kukanKudariScore =
      2 *
      7500.0 *
      gh.kyoriwariaikudari_taikai_kukangoto[racebangou][kukanIndex] *
      gh.heikinkoubaikudari_taikai_kukangoto[racebangou][kukanIndex];
  double kukanKirikaeScore =
      4.0 *
      gh.noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][kukanIndex]
          .toDouble();
  kukanKudariScore = kukanKudariScore.abs();

  double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
  double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
  double senshuKirikaeScore = 3 * senshu.noborikudarikirikaenouryoku.toDouble();

  double totalScore =
      (kukanKyoriScore * senshuKyoriScore) +
      (kukanNoboriScore * senshuNoboriScore) +
      (kukanKudariScore * senshuKudariScore) +
      (kukanKirikaeScore * senshuKirikaeScore);

  if (totalScore.isNaN) return -99999.0;
  return totalScore;
}

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) return '記録無';
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

/// --- メイン関数 EntryCalc_2 ---
Future<List<int>> EntryCalc_2({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  // 休憩処理
  final now = DateTime.now();
  if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
    await Future.delayed(const Duration(milliseconds: 50));
    Chousa.lastGapTime = DateTime.now();
  }

  print("EntryCalc_2 (公式エントリー作成・軽量版) 開始");
  final albumBox = Hive.box<Album>('albumBox');
  final Album album = albumBox.get('AlbumData')!;
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;

  // 1. データ初期化・準備
  if (racebangou <= 2 || racebangou == 5) {
    for (
      int i_kukan = 0;
      i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
      i_kukan++
    ) {
      kantoku.yobiint4[i_kukan] = gh[0]
          .time_zentaikukankiroku[racebangou][i_kukan][0]
          .toInt();
      kantoku.yobiint4[i_kukan + 10] = sortedUnivData[gh[0].MYunivid]
          .time_univkukankiroku[racebangou][i_kukan][0]
          .toInt();
      kantoku.yobiint3[i_kukan] =
          kantoku.yobiint4[racebangou * 10 + 30 + i_kukan];
    }
    kantoku.yobiint4[20] = gh[0].time_zentaitaikaikiroku[racebangou][0].toInt();
    kantoku.yobiint4[21] = sortedUnivData[gh[0].MYunivid]
        .time_univtaikaikiroku[racebangou][0]
        .toInt();
  } else {
    for (int i = 0; i < 22; i++) kantoku.yobiint4[i] = 0;
    for (int i = 0; i < 10; i++) kantoku.yobiint3[i] = 0;
  }
  await kantoku.save();

  // レース種別ごとのエントリーリセット処理
  if ((racebangou >= 6 && racebangou <= 9) ||
      (racebangou >= 10 && racebangou <= 12) ||
      racebangou == 17) {
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
          0;
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
    return [];
  } else if (racebangou >= 13 && racebangou <= 16) {
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      if (kantoku.yobiint2[19] == 1 ||
          sortedSenshuData[i].univid == gh[0].MYunivid) {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            0;
      } else {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            -1;
      }
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
    return [];
  } else if (racebangou <= 2 || racebangou == 5 || racebangou == 4) {
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      if (sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] >
          -2) {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            -1;
        sortedSenshuData[i].kazetaisei = 0; // 圧縮データ初期化
        sortedSenshuData[i].string_racesetumei = "";
        await sortedSenshuData[i].save();
      }
    }
  } else {
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
          -1;
      sortedSenshuData[i].kazetaisei = 0;
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
    return [];
  }

  // --- 大会ルールの設定 ---
  EkidenRuleConfig config;
  if (racebangou == 0)
    config = EkidenRuleConfig.izumo();
  else if (racebangou == 1 || racebangou == 3)
    config = EkidenRuleConfig.allJapan();
  else if (racebangou == 2 || racebangou == 4 || racebangou == 5)
    config = EkidenRuleConfig.hakone();
  else
    config = const EkidenRuleConfig(
      totalSections: 0,
      maxChangeTotal: 0,
    ); // fallback

  int totalSections = config.totalSections;
  int maxChangeTotal = config.maxChangeTotal;

  List<int> kukanIDs = [];

  // --- 駅伝（racebangou 0, 1, 2, 5）の本処理 ---
  if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
    // 区間重要度順の決定（旧コードロジック使用）
    List<Map<String, dynamic>> kukanScores = [];
    for (int i = 0; i < totalSections; i++) {
      double kukanKyoriScore =
          0.15 * gh[0].kyori_taikai_kukangoto[racebangou][i];
      double score = kukanKyoriScore;
      // 区間番号が若いほどボーナス
      if (i == 0)
        score += (totalSections - i) * 150.0;
      else
        score += (totalSections - i) * 150.0;
      kukanScores.add({'kukanIndex': i, 'score': score});
    }
    kukanScores.sort((a, b) => b['score'].compareTo(a['score']));
    kukanIDs = kukanScores.map((k) => k['kukanIndex'] as int).toList();

    // 大学ごとにループ
    for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
      final now = DateTime.now();
      if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
        await Future.delayed(const Duration(milliseconds: 50));
        Chousa.lastGapTime = DateTime.now();
      }

      if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 1) {
        List<SenshuData> team = sortedSenshuData
            .where(
              (s) =>
                  s.univid == id_univ &&
                  s.entrykukan_race[racebangou][s.gakunen - 1] >= -1,
            )
            .toList();

        team.sort((a, b) => a.id.compareTo(b.id)); // 安定ソート

        // -----------------------------------------------------------
        // Step 1: 理想のオーダー (Pattern 0) の計算
        // -----------------------------------------------------------
        Map<int, SenshuData> idealAllocation = {};
        Set<int> assignedIds = {};

        // 最適化フラグチェック（アルバムの登録数確率でDP発動）
        bool useOptimization =
            (Random().nextInt(100) < album.tourokusuu_total) &&
            (id_univ != gh[0].MYunivid);

        if (useOptimization) {
          // --- DPによる最適解探索 (findFastestTeamロジック) ---
          try {
            if (team.length < totalSections) throw Exception("選手不足");
            List<int> playerIds = team.map((s) => s.id).toList();
            int playerCount = playerIds.length;

            // 試走タイム計算キャッシュ
            final Map<int, Map<int, double>> trialTimesCache = {};
            for (int pid in playerIds) {
              trialTimesCache[pid] = {};
              for (int k = 0; k < totalSections; k++) {
                double time = await runTrialCalculation(
                  pid,
                  k,
                  gh[0],
                  sortedSenshuData,
                  sortedUnivData,
                  kantoku,
                );
                trialTimesCache[pid]![k] = time;
              }
            }

            // DPテーブル
            List<Map<int, double>> dp = List.generate(
              totalSections + 1,
              (_) => {},
            );
            List<Map<int, int>> parent = List.generate(
              totalSections + 1,
              (_) => {},
            );
            dp[0][0] = 0.0;

            for (int k = 1; k <= totalSections; k++) {
              int prevK = k - 1;
              for (int prevMask in dp[prevK].keys) {
                for (int i = 0; i < playerCount; i++) {
                  int bit = 1 << i;
                  if ((prevMask & bit) == 0) {
                    int newMask = prevMask | bit;
                    double time = trialTimesCache[playerIds[i]]![k - 1]!;
                    double total = dp[prevK][prevMask]! + time;

                    if (total < (dp[k][newMask] ?? double.infinity)) {
                      dp[k][newMask] = total;
                      parent[k][newMask] = i;
                    }
                  }
                }
              }
            }

            // バックトラック
            double fastestTime = double.infinity;
            int finalMask = -1;
            for (int mask in dp[totalSections].keys) {
              if (dp[totalSections][mask]! < fastestTime) {
                fastestTime = dp[totalSections][mask]!;
                finalMask = mask;
              }
            }

            int currMask = finalMask;
            for (int k = totalSections; k >= 1; k--) {
              int pIdx = parent[k][currMask]!;
              SenshuData p = team.firstWhere((s) => s.id == playerIds[pIdx]);
              idealAllocation[k - 1] = p; // k-1区
              assignedIds.add(p.id);
              currMask ^= (1 << pIdx);
            }
          } catch (e) {
            useOptimization = false; // エラー時はグリーディへフォールバック
          }
        }

        // 最適化を使わない、または失敗した場合はグリーディ法（スコア順）
        if (!useOptimization || idealAllocation.isEmpty) {
          // 走力順に仮ソート
          team.sort(
            (a, b) => b.time_bestkiroku[1].compareTo(a.time_bestkiroku[1]),
          );

          for (int kukanIndex in kukanIDs) {
            SenshuData? bestSenshu;
            double maxScore = -99999999999.0;
            for (SenshuData senshu in team) {
              if (assignedIds.contains(senshu.id)) continue;
              double score = _calculateSectionScore(
                senshu,
                kukanIndex,
                racebangou,
                gh[0],
              );
              if (score > maxScore) {
                maxScore = score;
                bestSenshu = senshu;
              }
            }
            if (bestSenshu != null) {
              idealAllocation[kukanIndex] = bestSenshu;
              assignedIds.add(bestSenshu.id);
            }
          }
        }

        // -----------------------------------------------------------
        // Step 2: 当て馬作戦 (公式発表オーダー) の作成
        // -----------------------------------------------------------

        int hiddenCount = (maxChangeTotal / 2).floor();
        if (hiddenCount < 1 && maxChangeTotal > 0) hiddenCount = 1;
        if (maxChangeTotal == 0) hiddenCount = 0;

        List<SenshuData> idealRegulars = idealAllocation.values.toList();
        List<SenshuData> idealSubs = team
            .where((s) => !assignedIds.contains(s.id))
            .toList();

        // レギュラーはタイムが良い順に（隠しエース候補）
        idealRegulars.sort(
          (a, b) => a.time_bestkiroku[1].compareTo(b.time_bestkiroku[1]),
        );

        // 隠すエースを決定
        List<SenshuData> hiddenAces = idealRegulars.take(hiddenCount).toList();

        // エースが抜けたことによって空く区間のリストを作成
        List<int> vacantKukans = [];
        idealAllocation.forEach((k, v) {
          if (hiddenAces.contains(v)) {
            vacantKukans.add(k);
          }
        });

        // 当て馬の決定ロジック (適性考慮)
        // 空いた区間に対して、補欠(idealSubs)の中から最も適性が高い選手を割り当てる
        Map<int, SenshuData> dummyAllocation = {}; // 区間 -> 当て馬
        List<SenshuData> availableDummies = List.from(idealSubs); // 候補リスト

        for (int kukan in vacantKukans) {
          if (availableDummies.isEmpty) break;

          // その区間のスコアが最も高い補欠を探す
          SenshuData bestDummy = availableDummies.reduce(
            (a, b) =>
                _calculateSectionScore(a, kukan, racebangou, gh[0]) >
                    _calculateSectionScore(b, kukan, racebangou, gh[0])
                ? a
                : b,
          );

          dummyAllocation[kukan] = bestDummy;
          availableDummies.remove(bestDummy);
        }

        // 選ばれた当て馬リスト
        List<SenshuData> dummies = dummyAllocation.values.toList();

        // 発表用区間の設定と保存
        for (var senshu in team) {
          int kukan = -1;
          int idealKukan = -1;
          idealAllocation.forEach((k, v) {
            if (v == senshu) idealKukan = k;
          });

          // 公式発表(entrykukan)の決定
          if (hiddenAces.contains(senshu)) {
            kukan = -1; // エース隠し (補欠へ)
          } else if (dummies.contains(senshu)) {
            // 当て馬配置 (適性を考慮して割り当てられた区間へ)
            int assignedDummyKukan = -1;
            dummyAllocation.forEach((k, v) {
              if (v == senshu) assignedDummyKukan = k;
            });
            kukan = assignedDummyKukan;
          } else {
            // それ以外のレギュラーは理想通り
            kukan = idealKukan;
          }

          // 公式エントリー保存
          senshu.entrykukan_race[racebangou][senshu.gakunen - 1] = kukan;

          // kazetaiseiの初期化と「理想区間(Pattern 0)」の保存
          // 当日変更ロジックで「本来のエース」を識別するために使用
          senshu.kazetaisei = 0;
          _setIdealKukanToKazetaisei(senshu, idealKukan);
        }
        // ※予備パターン(Pattern 1~15)のシミュレーションは削除しました（当日変更ロジックで行うため）

        for (var senshu in team) await senshu.save();
      }
    }
  }

  // --- 学連選抜処理 (Race 2のみ) - 旧コード流用 ---
  if (racebangou == 2) {
    final Box<Senshu_Gakuren_Data> gakurenSenshuBox =
        Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
    await gakurenSenshuBox.clear();

    // 選出ロジック
    for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
      if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 0) {
        List<SenshuData> timejununivfilterdSenshudata = sortedSenshuData
            .where((s) => s.univid == id_univ && s.hirou != 1)
            .toList();
        timejununivfilterdSenshudata.sort(
          (a, b) => a.kukantime_race[4][a.gakunen - 1].compareTo(
            b.kukantime_race[4][b.gakunen - 1],
          ),
        );
        for (int i = 0; i < timejununivfilterdSenshudata.length; i++) {
          int count = 0;
          for (
            int i_gakunen = timejununivfilterdSenshudata[i].gakunen - 1;
            i_gakunen >= 1;
            i_gakunen--
          ) {
            if (timejununivfilterdSenshudata[i]
                    .entrykukan_race[racebangou][i_gakunen - 1] >=
                0) {
              count++;
            }
          }
          if (count <= 1) {
            final Senshu_Gakuren_Data gakurenSenshu =
                Senshu_Gakuren_Data.fromSenshuData(
                  timejununivfilterdSenshudata[i],
                );
            await gakurenSenshuBox.put(gakurenSenshu.id, gakurenSenshu);
            break;
          }
        }
      }
    }

    // 学連区間配置
    List<Map<String, dynamic>> kukanScores = [];
    for (int i = 0; i < gh[0].kukansuu_taikaigoto[racebangou]; i++) {
      double score = 0.15 * gh[0].kyori_taikai_kukangoto[racebangou][i];
      if (i == 0)
        score += (totalSections - i) * 150.0;
      else
        score += (totalSections - i) * 150.0;
      kukanScores.add({'kukanIndex': i, 'score': score});
    }
    kukanScores.sort((a, b) => b['score'].compareTo(a['score']));
    kukanIDs = kukanScores.map((k) => k['kukanIndex'] as int).toList();

    final availableSenshu = gakurenSenshuBox.values.toList();
    Set<int> assignedSenshuIds = {};
    List<Senshu_Gakuren_Data> playersToSave = [];

    for (int kukanIndex in kukanIDs) {
      Senshu_Gakuren_Data? bestSenshu;
      double maxScore = -99999999999.0;
      for (Senshu_Gakuren_Data senshu in availableSenshu) {
        if (assignedSenshuIds.contains(senshu.id)) continue;
        // 学連用の簡易スコア計算
        double score = senshu.time_bestkiroku[1] * -1.0;
        if (kukanIndex == 4) score += senshu.noboritekisei * 10.0;
        if (kukanIndex == 5) score += senshu.kudaritekisei * 10.0;
        if (score > maxScore) {
          maxScore = score;
          bestSenshu = senshu;
        }
      }
      if (bestSenshu != null) {
        bestSenshu.entrykukan_race[racebangou][bestSenshu.gakunen - 1] =
            kukanIndex;
        playersToSave.add(bestSenshu);
        assignedSenshuIds.add(bestSenshu.id);
      }
    }
    for (var senshu in playersToSave) await senshu.save();
  }

  // 予選会等の処理 (省略可だが既存維持)
  if (racebangou == 3 || racebangou == 4) {
    // 必要に応じて既存ロジックをここに記述
  }

  print("EntryCalc_2 終了");
  return kukanIDs;
}
