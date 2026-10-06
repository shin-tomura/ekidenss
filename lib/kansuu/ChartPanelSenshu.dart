import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/ModalAverageTop10TimeRankingView.dart';
import 'package:ekiden/kansuu/konki_best.dart'; // 今季ベスト(1.9.1)

class ScoreCompressor {
  static const List<String> keys = ['スピード', 'スタミナ', '山適性', 'ロード', '起伏耐性'];

  /// 5指標のMapと総合評価を1つのintにパッキング
  static int compress(Map<String, double> scores, double average) {
    int packed = 0;
    List<double> values = [
      scores['スピード'] ?? 1.0,
      scores['スタミナ'] ?? 1.0,
      scores['山適性'] ?? 1.0,
      scores['ロード'] ?? 1.0,
      scores['起伏耐性'] ?? 1.0,
      average, // 6番目に総合評価を格納
    ];

    for (int i = 0; i < values.length; i++) {
      int val = (values[i] * 10).round().clamp(0, 127);
      packed |= (val << (i * 7));
    }
    return packed;
  }

  /// 圧縮されたintから {指標名: スコア} のMapと総合評価を復元
  static Map<String, dynamic> decompress(int packed) {
    Map<String, double> scores = {};
    for (int i = 0; i < keys.length; i++) {
      int val = (packed >> (i * 7)) & 0x7F;
      scores[keys[i]] = val / 10.0;
    }
    double average = ((packed >> (5 * 7)) & 0x7F) / 10.0;
    return {'scores': scores, 'average': average};
  }
}

/// 選手データを受け取り、解析パネル（レーダー＋数値）を返す共通関数
Widget buildSenshuAnalysisPanel(
  SenshuData senshu, {
  VoidCallback? onDetailTap,
}) {
  // 保存されている圧縮データ(toriaezu)を解凍
  // ※質問文のコードに合わせてsenshu.atusataisei（toriaezuの別名想定）を使用しています
  // 持ちタイムを今季ベストで表示しているときは、今季ベストでその場で計算する(保存はしない。1.9.1)
  final data = konkiBestHyoujiChuu()
      ? konkiBestSenshuScores(senshu)
      : ScoreCompressor.decompress(senshu.atusataisei);
  final Map<String, double> scores = data['scores'];
  final double average = data['average'];

  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // コンテンツの高さに合わせる
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senshu.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${senshu.gakunen}年生",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            if (onDetailTap != null)
              TextButton(
                onPressed: onDetailTap,
                child: Text(
                  "詳細プロフ",
                  style: TextStyle(
                    color: HENSUU.LinkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const Divider(color: Colors.white24, height: 20),

        // IntrinsicHeightを使用して、左右の高さの高い方に合わせる
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左側：レーダーチャート
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AspectRatio(
                    aspectRatio: 1, // 正方形を維持
                    child: CustomPaint(painter: RadarChartPainter(scores)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 右側：数値パネル（スクロール可能）
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // ★ スクロール可能にすることでOverflowを完全に防止
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "総合評価",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        ...scores.entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 項目名が長い場合に備えてExpandedでラップ
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      e.value.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 16, // 大きくしたフォント
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          "※夏の学内タイムトライアルの記録がない選手(夏より前の1年生など)がいると、正確な分析はできません",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 9,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        // 今季ベストで分析しているときの注意書き(1.9.1)
        if (konkiBestHyoujiChuu())
          const Text(
            "※今季ベスト(今年度のレースでの最高記録)で分析しています。今季の記録がない種目は最低の評価になります",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    ),
  );
}

/// 今季ベストで出した選手[senshu]の解析スコア(保存せず、その場で計算する。1.9.1)
/// 計算は updateAllSenshuChartdata_atusataisei と同じで、母集団は全選手の今季ベスト。
/// 保存したものと同じ目盛りになるよう、いったん圧縮してから解凍して返す
Map<String, dynamic> konkiBestSenshuScores(SenshuData senshu) {
  final List<SenshuData> allSenshu = Hive.box<SenshuData>(
    'senshuBox',
  ).values.toList();
  Map<int, List<double>> pools = {
    0: [],
    1: [],
    2: [],
    4: [],
    5: [],
    6: [],
    7: [],
  };
  for (var s in allSenshu) {
    for (var idx in pools.keys) {
      double t = konkiBest(s, idx);
      if (t > 0 && t < TEISUU.DEFAULTTIME) pools[idx]!.add(t);
    }
  }
  double sc(int idx) {
    double t = konkiBest(senshu, idx);
    if (t <= 0 || t >= TEISUU.DEFAULTTIME || pools[idx]!.isEmpty) return 1.0;
    double mean = pools[idx]!.reduce((a, b) => a + b) / pools[idx]!.length;
    double variance =
        pools[idx]!.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        pools[idx]!.length;
    double stdDev = math.sqrt(variance);
    double tScore = (stdDev == 0) ? 50.0 : 50 + 10 * (mean - t) / stdDev;
    return ((tScore - 30) / 4).clamp(1.0, 10.0);
  }

  Map<String, double> scores = {
    'スピード': (sc(0) + sc(1)) / 2,
    'スタミナ': sc(2),
    '山適性': (sc(4) + sc(5)) / 2,
    'ロード': sc(6),
    '起伏耐性': sc(7),
  };
  double avg = scores.values.reduce((a, b) => a + b) / scores.length;
  return ScoreCompressor.decompress(ScoreCompressor.compress(scores, avg));
}

Future<void> updateAllSenshuChartdata_atusataisei() async {
  final senshuBox = Hive.box<SenshuData>('senshuBox');
  final allSenshu = senshuBox.values.toList();

  // 1. 偏差値計算用の母集団(pools)作成
  Map<int, List<double>> pools = {
    0: [],
    1: [],
    2: [],
    4: [],
    5: [],
    6: [],
    7: [],
  };
  for (var s in allSenshu) {
    for (var idx in pools.keys) {
      double t = s.time_bestkiroku[idx];
      if (t > 0 && t < TEISUU.DEFAULTTIME) pools[idx]!.add(t);
    }
  }

  // 2. 全選手を計算してtorieazuに保存
  for (var s in allSenshu) {
    double sc(int idx) {
      double t = s.time_bestkiroku[idx];
      if (t <= 0 || t >= TEISUU.DEFAULTTIME) return 1.0;

      // --- 偏差値計算ロジック ---
      double mean = pools[idx]!.reduce((a, b) => a + b) / pools[idx]!.length;
      double variance =
          pools[idx]!
              .map((x) => math.pow(x - mean, 2))
              .reduce((a, b) => a + b) /
          pools[idx]!.length;
      double stdDev = math.sqrt(variance);
      double tScore = (stdDev == 0) ? 50.0 : 50 + 10 * (mean - t) / stdDev;
      // ------------------------

      return ((tScore - 30) / 4).clamp(1.0, 10.0);
    }

    Map<String, double> scores = {
      'スピード': (sc(0) + sc(1)) / 2,
      'スタミナ': sc(2),
      '山適性': (sc(4) + sc(5)) / 2,
      'ロード': sc(6),
      '起伏耐性': sc(7),
    };
    double avg = scores.values.reduce((a, b) => a + b) / scores.length;

    // 圧縮保存
    s.atusataisei = ScoreCompressor.compress(scores, avg);
    await s.save();
  }
}
