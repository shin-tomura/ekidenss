import 'dart:math';
import 'package:ekiden/fastest_filteredghensuu.dart'; // 新DTO
import 'package:ekiden/fastest_filteredplayer.dart'; // DTOのみ

/// compute() 専用：100%純粋関数（Hiveなし、Futureなし、DTOのみ）
Map<String, dynamic> findFastestTeamPure(List<dynamic> args) {
  print("findFastestTeamPure 開始 (Isolate内)");

  final List<FilteredGhensuu> gh = args[0] as List<FilteredGhensuu>; // DTOリスト
  final List<FilteredPlayer> filteredPlayers = args[1] as List<FilteredPlayer>;
  final int targetunivid = args[2] as int;
  final int numberOfKukan = args[3] as int;
  final Map<int, Map<int, double>> trialTimesCache =
      args[4] as Map<int, Map<int, double>>;

  final FilteredGhensuu currentGhensuu = gh[0]; // DTO使用
  final int playerCount = filteredPlayers.length;

  if (playerCount < numberOfKukan) {
    throw Exception('区間数分の選手がいません。($playerCount人)');
  }

  final List<int> playerIds = filteredPlayers.map((p) => p.id).toList();

  // 1. キャッシュは既に渡されているのでそのまま使用（再計算なし）

  // 2. 動的計画法（ビットDP、変更なし）
  final List<Map<int, double>> dp = List.generate(
    numberOfKukan + 1,
    (_) => <int, double>{},
  );
  final List<Map<int, int>> parent = List.generate(
    numberOfKukan + 1,
    (_) => <int, int>{},
  );

  dp[0][0] = 0.0;

  for (int kukan = 1; kukan <= numberOfKukan; kukan++) {
    for (final prevMask in dp[kukan - 1].keys) {
      final double prevTime = dp[kukan - 1][prevMask]!;

      for (int idx = 0; idx < playerCount; idx++) {
        final int bit = 1 << idx;
        if ((prevMask & bit) != 0) continue;

        final int playerId = playerIds[idx];
        final double sectionTime = trialTimesCache[playerId]![kukan - 1]!;
        final double newTime = prevTime + sectionTime;
        final int newMask = prevMask | bit;

        final currentBest = dp[kukan][newMask];
        if (currentBest == null || newTime < currentBest) {
          dp[kukan][newMask] = newTime;
          parent[kukan][newMask] = idx;
        }
      }
    }
  }

  // 3. 最良マスク探索（変更なし）
  double fastestTotalTime = double.infinity;
  int finalMask = -1;
  for (final mask in dp[numberOfKukan].keys) {
    final time = dp[numberOfKukan][mask]!;
    if (time < fastestTotalTime) {
      fastestTotalTime = time;
      finalMask = mask;
    }
  }

  // 4. 経路復元（変更なし）
  final List<int> fastestPlayerIds = [];
  int currentMask = finalMask;
  for (int kukan = numberOfKukan; kukan >= 1; kukan--) {
    final int playerIdx = parent[kukan][currentMask]!;
    fastestPlayerIds.insert(0, playerIds[playerIdx]);
    currentMask ^= (1 << playerIdx);
  }

  print("findFastestTeamPure 完了！ 最速タイム = $fastestTotalTime");

  return {
    'fastestTotalTime': fastestTotalTime,
    'fastestPlayerIds': fastestPlayerIds,
  };
}
