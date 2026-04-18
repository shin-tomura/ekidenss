import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';

// --- EkidenRuleConfig (EntryCalc_2と同じ定義) ---
class EkidenRuleConfig {
  final int totalSections;
  final int maxChangeTotal;
  final bool isTwoDays;
  final int day1SectionCount;
  final int day1ChangeLimit;
  final int day2ChangeLimit;

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

// --- ChangeRequest クラス ---
class ChangeRequest {
  SenshuData outPlayer;
  SenshuData inPlayer;
  int targetKukan;
  double gain;
  bool isMust;

  ChangeRequest({
    required this.outPlayer,
    required this.inPlayer,
    required this.targetKukan,
    required this.gain,
    this.isMust = false,
  });
}

// --- ヘルパー関数 ---

/// kazetaiseiから理想区間(Pattern 0)を取り出す
/// ※EntryCalc_2で保存した「本来走るべき区間」
int _getIdealKukanFromKazetaisei(SenshuData senshu) {
  int mask = 0xF;
  int val = senshu.kazetaisei & mask;
  if (val == 0) return -1;
  return val - 2;
}

/// 区間適性スコア計算 (EntryCalc_2と同じロジック)
double _calculateSectionScore(
  SenshuData senshu,
  int kukanIndex,
  int racebangou,
  Ghensuu gh,
) {
  // 距離スコア
  double kukanKyoriScore =
      0.15 * gh.kyori_taikai_kukangoto[racebangou][kukanIndex];

  // 距離補正
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

  // 登り・下り・切り替え適性
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

/// 当日変更を実行する関数 (Gainロジック実装版)
/// day: 0=通常, 1=1日目(往路), 2=2日目(復路)
Future<void> EntryToujituHenkou({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
  int day = 0,
}) async {
  print("EntryToujituHenkou (Gain Logic, Day=$day) 開始");

  // 設定取得
  EkidenRuleConfig config;
  if (racebangou == 0)
    config = EkidenRuleConfig.izumo();
  else if (racebangou == 1 || racebangou == 3)
    config = EkidenRuleConfig.allJapan();
  else if (racebangou == 2 || racebangou == 4 || racebangou == 5)
    config = EkidenRuleConfig.hakone();
  else
    config = const EkidenRuleConfig(totalSections: 0, maxChangeTotal: 0);

  // 対象となる大学
  List<int> entryUnivids = sortedUnivData
      .where((u) => u.taikaientryflag[racebangou] == 1)
      .map((u) => u.id)
      .toList();

  for (int univid in entryUnivids) {
    List<SenshuData> team = sortedSenshuData
        .where((s) => s.univid == univid)
        .toList();

    // 1. 現在の状態把握 & 過去の変更数カウント
    Map<int, SenshuData?> currentMap = {}; // 区間 -> 走者
    List<SenshuData> availableSubs = [];
    int alreadyChangedCount = 0; // 既にOUTになった人数（＝過去の変更数）

    for (var p in team) {
      int kukan = p.entrykukan_race[racebangou][p.gakunen - 1];

      if (kukan >= 0) {
        // 区間エントリー中
        if (p.chousi == 0) {
          // 体調不良 -> 穴が開く
          // ※ただし、今回のdayの対象区間のみ穴とみなす
          bool isTargetDay = true;
          if (config.isTwoDays) {
            if (day == 1 && kukan >= config.day1SectionCount)
              isTargetDay = false;
            if (day == 2 && kukan < config.day1SectionCount)
              isTargetDay = false;
          }

          if (isTargetDay) {
            currentMap[kukan] = null; // 穴埋め必須
            print("大学ID $univid: 区間$kukan ${p.name} 体調不良");
          } else {
            currentMap[kukan] = p; // 対象日じゃないのでそのまま
          }
        } else {
          currentMap[kukan] = p;
        }
      } else if (kukan == -1) {
        // 補欠
        availableSubs.add(p);
      } else if (kukan <= -2) {
        // -2以下、特に -(100+k) は当日変更OUTの選手
        // 過去の変更数としてカウント
        if (kukan <= -100) {
          alreadyChangedCount++;
        }
      }
    }

    // 2. 交代リクエストの作成
    List<ChangeRequest> allRequests = [];

    // A. 必須対応（穴埋め）
    // currentMapのkeyでループせず、全区間チェック
    for (int k = 0; k < config.totalSections; k++) {
      // 対象日チェック
      if (config.isTwoDays) {
        if (day == 1 && k >= config.day1SectionCount) continue;
        if (day == 2 && k < config.day1SectionCount) continue;
      }

      if (currentMap.containsKey(k) && currentMap[k] == null) {
        // 穴が開いている -> 最適な補欠で埋める
        if (availableSubs.isEmpty) break;

        SenshuData bestSub = availableSubs.reduce(
          (a, b) =>
              _calculateSectionScore(a, k, racebangou, gh[0]) >
                  _calculateSectionScore(b, k, racebangou, gh[0])
              ? a
              : b,
        );

        // Gainは最大値
        allRequests.add(
          ChangeRequest(
            outPlayer: SenshuData(
              name: "dummy",
              //baseSpeed: 0,
              id: -999,
              univid: 0,
              gakunen: 0,
            ),
            inPlayer: bestSub,
            targetKukan: k,
            gain: 9999999.0,
            isMust: true,
          ),
        );

        availableSubs.remove(bestSub);
      }
    }

    // B. 戦略的交代（Gain）
    for (int k = 0; k < config.totalSections; k++) {
      // 対象日チェック
      if (config.isTwoDays) {
        if (day == 1 && k >= config.day1SectionCount) continue;
        if (day == 2 && k < config.day1SectionCount) continue;
      }

      if (!currentMap.containsKey(k) || currentMap[k] == null)
        continue; // 穴埋め対象などはスキップ

      SenshuData currentRunner = currentMap[k]!;
      // もし既に体調不良で穴埋め対象になっていたらスキップ (念のため)
      if (currentRunner.chousi == 0) continue;

      double currentScore = _calculateSectionScore(
        currentRunner,
        k,
        racebangou,
        gh[0],
      );

      for (var sub in availableSubs) {
        double subScore = _calculateSectionScore(sub, k, racebangou, gh[0]);
        double gain = subScore - currentScore;

        if (gain > 0) {
          // EntryCalc_2で保存した「理想区間」に戻るならボーナス
          int idealKukan = _getIdealKukanFromKazetaisei(sub);
          if (idealKukan == k) gain += 500.0;

          allRequests.add(
            ChangeRequest(
              outPlayer: currentRunner,
              inPlayer: sub,
              targetKukan: k,
              gain: gain,
              isMust: false,
            ),
          );
        }
      }
    }

    // 3. ソート (Gain順)
    // これにより、効果の高い交代が優先され、枠が少なければ効果の低い交代は切り捨てられる（温存）
    allRequests.sort((a, b) => b.gain.compareTo(a.gain));

    // 4. 適用と制限チェック
    int currentChanges = 0; // 今回(このday)に行う変更数
    // dayごとのカウント（箱根の場合）
    // ※alreadyChangedCountは合計制限のチェックに使用する

    Set<int> usedSubIds = {};
    Map<int, SenshuData> finalAllocation = {}; // 二重割り当て防止用チェック
    currentMap.forEach((k, v) {
      if (v != null) finalAllocation[k] = v;
    });

    for (var req in allRequests) {
      SenshuData inPlayer = req.inPlayer;
      if (usedSubIds.contains(inPlayer.id)) continue;

      bool isMust = req.isMust;
      int kukan = req.targetKukan;

      // 既に埋まった必須枠などはスキップ
      if (isMust &&
          finalAllocation.containsKey(kukan) &&
          finalAllocation[kukan] != null)
        continue;

      // --- 制限チェック ---

      // 合計制限: (過去の変更 + 今回の変更) < Max
      if ((alreadyChangedCount + currentChanges) >= config.maxChangeTotal)
        continue;

      // 日別制限 (箱根のみ)
      if (config.isTwoDays) {
        if (day == 1) {
          // 1日目の制限チェック (過去にDay1で何人変えたかは本来追跡必要だが、
          // EntryCalc_2直後のDay1実行なら alreadyChangedCountは0のはず。
          // Day2実行時はDay1の変更分がalreadyに含まれるが、Day2のLimitはDay2の変更数のみにかかる)
          // 簡易的に currentChanges (今回の変更数) が dayLimitを超えないかチェック
          if (currentChanges >= config.day1ChangeLimit) continue;
        } else if (day == 2) {
          // 2日目の制限チェック
          if (currentChanges >= config.day2ChangeLimit) continue;
        }
      }

      // 適用
      // 1. IN処理
      inPlayer.entrykukan_race[racebangou][inPlayer.gakunen - 1] = kukan;
      inPlayer.string_racesetumei = "当日変更IN\n";
      usedSubIds.add(inPlayer.id);

      // 2. OUT処理 (Mustの場合はoutPlayerはダミーなので処理しない)
      if (!isMust) {
        SenshuData outP = req.outPlayer;
        outP.entrykukan_race[racebangou][outP.gakunen - 1] = -(100 + kukan);
        outP.string_racesetumei = "当日変更OUT\n";
      }

      finalAllocation[kukan] = inPlayer;
      currentChanges++;

      await inPlayer.save();
      if (!isMust) await req.outPlayer.save();
    }
  } // univ loop

  print("EntryToujituHenkou 終了");
}
