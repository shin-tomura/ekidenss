import 'package:ekiden/kantoku_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'dart:math';

/*Future<Map<String, dynamic>> findFastestTeam(List<dynamic> args) async {
  print("findFastestTeamに入った (修正版)");
  final String path = args[0] as String;
  final int targetunivid = args[1] as int;
  final int numberOfKukan = args[2] as int;

  Hive.init(path);
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(GhensuuAdapter());
  }
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SenshuDataAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UnivDataAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(KantokuDataAdapter());
  }
  await Hive.openBox<Ghensuu>('ghensuuBox');
  await Hive.openBox<SenshuData>('senshuBox');
  await Hive.openBox<UnivData>('univBox');
  await Hive.openBox<KantokuData>('kantokuBox');

  final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final List<Ghensuu> gh = [ghensuuBox.getAt(0)!]; // gh[0]としてアクセスするためにリストに入れる
  final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
  final List<SenshuData> univFilteredSenshuData = senshudataBox.values
      .where(
        (s) =>
            s.univid == targetunivid &&
            s.entrykukan_race[gh[0].hyojiracebangou][s.gakunen - 1] >= -1,
      )
      .toList();
  if (univFilteredSenshuData.length < numberOfKukan) {
    throw Exception('区間数分の選手がいません。');
  }

  final List<int> playerIds = univFilteredSenshuData.map((s) => s.id).toList();
  final int playerCount = playerIds.length;

  // 1. 試走タイムを事前に計算してキャッシュ
  final Map<int, Map<int, double>> trialTimesCache = {};
  for (final int playerId in playerIds) {
    trialTimesCache[playerId] = {};
    for (int kukanIndex = 0; kukanIndex < numberOfKukan; kukanIndex++) {
      final double time = await runTrialCalculation(playerId, kukanIndex);
      trialTimesCache[playerId]![kukanIndex] = time;
    }
  }

  // 2. 動的計画法による最適配置の探索（ビットマスクを使用）
  // dp[k][mask] = k区間目までで、選手集合maskを使用したときの最小タイム
  final List<Map<int, double>> dp = List.generate(numberOfKukan + 1, (_) => {});
  // parent[k][mask] = k区間目で配置した選手インデックス
  final List<Map<int, int>> parent = List.generate(
    numberOfKukan + 1,
    (_) => {},
  );

  // 初期化: 0区間目、選手不使用のマスク
  dp[0][0] = 0.0;

  // ループでDPテーブルを埋めていく
  for (int kukan = 1; kukan <= numberOfKukan; kukan++) {
    final int prevKukan = kukan - 1;
    for (final prevMask in dp[prevKukan].keys) {
      // 過去に使用した選手を特定
      for (
        int currentPlayerIdx = 0;
        currentPlayerIdx < playerCount;
        currentPlayerIdx++
      ) {
        // currentPlayerIdx (選手インデックス)に対応するビット
        final int currentMaskBit = 1 << currentPlayerIdx;

        // 選手が既に使用されているかチェック
        if ((prevMask & currentMaskBit) == 0) {
          // 未使用の場合、選手を配置可能
          final int newMask = prevMask | currentMaskBit;
          final double currentTime =
              trialTimesCache[playerIds[currentPlayerIdx]]![kukan - 1]!;
          final double totalTime = dp[prevKukan][prevMask]! + currentTime;

          // 新しいマスクでの最小タイムを更新
          if (totalTime < (dp[kukan][newMask] ?? double.infinity)) {
            dp[kukan][newMask] = totalTime;
            parent[kukan][newMask] = currentPlayerIdx;
          }
        }
      }
    }
  }

  // 3. 最後の区間までの最適な合計タイムと組み合わせを逆順でたどる
  double fastestTotalTime = double.infinity;
  int finalMask = -1;
  final int finalKukan = numberOfKukan;

  for (final mask in dp[finalKukan].keys) {
    if (dp[finalKukan][mask]! < fastestTotalTime) {
      fastestTotalTime = dp[finalKukan][mask]!;
      finalMask = mask;
    }
  }

  final List<int> fastestPlayerIds = [];
  int currentMask = finalMask;
  for (int kukan = numberOfKukan; kukan >= 1; kukan--) {
    final int currentPlayerIdx = parent[kukan][currentMask]!;
    final int currentPlayerId = playerIds[currentPlayerIdx];
    fastestPlayerIds.insert(0, currentPlayerId);

    // 現在の選手をマスクから外して、前の状態のマスクを計算
    currentMask = currentMask ^ (1 << currentPlayerIdx);
  }

  print("findFastestTeam 最速の組み合わせ探索終了！！(修正版)");

  // Isolate内で開いた全てのBoxを確実に閉じる（メインIsolateには影響なし）
  await Hive.close();

  return {
    'fastestTotalTime': fastestTotalTime,
    'fastestPlayerIds': fastestPlayerIds,
  };
}
*/
