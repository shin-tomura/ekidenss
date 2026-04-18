import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
//import 'package:ekiden/kansuu/time_date.dart';
import 'dart:math' as math;
import 'package:ekiden/screens/ModalAverageTop10TimeRankingView.dart';

class UnivAnalysisEngine {
  static const List<String> scoreKeys = ['スピード', 'スタミナ', '山適性', 'ロード', '起伏耐性'];
  static const String unitSeparator = "||"; // 大学ごとの区切り
  static const String fieldSeparator = "@@"; // 二つ名と分析文の区切り

  /// スコアと平均値を1つのintにパッキング
  static int compressScores(Map<String, double> scores, double average) {
    int packed = 0;
    List<double> values = [
      scores['スピード'] ?? 1.0,
      scores['スタミナ'] ?? 1.0,
      scores['山適性'] ?? 1.0,
      scores['ロード'] ?? 1.0,
      scores['起伏耐性'] ?? 1.0,
      average,
    ];
    for (int i = 0; i < values.length; i++) {
      int val = (values[i] * 10).round().clamp(0, 127);
      packed |= (val << (i * 7));
    }
    return packed;
  }

  /// 圧縮intからスコアを復元
  static Map<String, dynamic> decompressScores(int packed) {
    Map<String, double> scores = {};
    for (int i = 0; i < scoreKeys.length; i++) {
      int val = (packed >> (i * 7)) & 0x7F;
      scores[scoreKeys[i]] = val / 10.0;
    }
    double average = ((packed >> (5 * 7)) & 0x7F) / 10.0;
    return {'scores': scores, 'average': average};
  }

  /// 二つ名生成ロジック（完全再現）
  static String determineTeamType(Map<String, double> scores) {
    if (scores.isEmpty) return "❔ 謎に包まれた集団";

    final sortedKeys = scores.keys.toList()
      ..sort((a, b) {
        int cmp = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
        if (cmp != 0) return cmp;
        return b.compareTo(a);
      });

    final double top1 = scores[sortedKeys[0]] ?? 0.0;
    final double top2 = sortedKeys.length > 1
        ? (scores[sortedKeys[1]] ?? 0.0)
        : 0.0;
    final double top3 = sortedKeys.length > 2
        ? (scores[sortedKeys[2]] ?? 0.0)
        : 0.0;
    final double worst = scores[sortedKeys.last] ?? 0.0;
    final double secondWorst = sortedKeys.length > 1
        ? (scores[sortedKeys[sortedKeys.length - 2]] ?? 0.0)
        : 0.0;
    final double avg = scores.values.reduce((a, b) => a + b) / scores.length;

    final String s1 = sortedKeys[0];
    final String s2 = sortedKeys.length > 1 ? sortedKeys[1] : "";
    final String s3 = sortedKeys.length > 2 ? sortedKeys[2] : "";

    if (avg >= 9.7) return "🌟【神域】全知全能の守護神";
    if (avg >= 9.2) return "🏆【伝説】古今無双の極致";
    if (top1 >= 9.2 && top2 <= 5.0) return "【唯一神】純粋なる$s1の化身";
    if (top1 >= 8.0 && top2 >= 8.0 && top3 >= 8.0) return "【強三種】不動のトリニティ";

    if (s1 == "山適性" && s2 == "起伏耐性" && (scores["スピード"] ?? 0) <= 3.5)
      return "【修羅】急勾配の狂信者";
    if (s1 == "スピード" && s2 == "ロード" && (scores["スタミナ"] ?? 0) <= 3.5)
      return "【刹那】一撃必殺の特攻隊";

    if (avg <= 1.7) return "【深淵】伸び代しかない未完の器";
    if (avg <= 2.3) return "【奮闘】逆境の挑戦者";
    if (top1 - worst <= 0.5 && avg >= 7.8) return "【究極】五角形の完成者";
    if (top1 - worst <= 1.0 && avg >= 5.5) return "【均衡】調和の探求者";

    String prefix = "";
    if (top1 >= 9.8)
      prefix = "天・";
    else if (top1 >= 9.6)
      prefix = "極・";
    else if (top1 >= 9.0)
      prefix = "至・";
    else if (top1 >= 8.6)
      prefix = "真・";
    else if (top1 >= 7.2)
      prefix = "超・";
    else if (top1 >= 5.5)
      prefix = "準・";
    else if (top1 >= 4.1)
      prefix = "中・";
    else
      prefix = (top1 >= 2.0) ? "凡・" : "微・";

    String base = "";
    bool isLow = (top1 < 5.5);
    final combo = "$s1-$s2";

    switch (combo) {
      case "スピード-スタミナ":
      case "スタミナ-スピード":
        base = isLow ? "王道走者の卵" : "王道走者";
        break;
      case "スピード-山適性":
      case "山適性-スピード":
        base = isLow ? "飛天の隼の雛" : "飛天の隼";
        break;
      case "スピード-ロード":
      case "ロード-スピード":
        base = isLow ? "蒼き流星の志望者" : "蒼き流星";
        break;
      case "スピード-起伏耐性":
      case "起伏耐性-スピード":
        base = isLow ? "荒野の疾走者の芽" : "荒野の疾走者";
        break;
      case "スタミナ-山適性":
      case "山適性-スタミナ":
        base = isLow ? "不落の要塞の基礎" : "不落の要塞";
        break;
      case "スタミナ-ロード":
      case "ロード-スタミナ":
        base = isLow ? "鉄の脚の初心者" : "鉄の脚";
        break;
      case "スタミナ-起伏耐性":
      case "起伏耐性-スタミナ":
        base = isLow ? "野獣の心の種" : "野獣の心";
        break;
      case "山適性-起伏耐性":
      case "起伏耐性-山適性":
        base = isLow ? "絶壁の隠者の見習い" : "絶壁の隠者";
        break;
      case "山適性-ロード":
      case "ロード-山適性":
        base = isLow ? "万能の開拓者の卵" : "万能の開拓者";
        break;
      case "ロード-起伏耐性":
      case "起伏耐性-ロード":
        base = isLow ? "走境無双の覇者の候補" : "走境無双の覇者";
        break;
      default:
        if (s3.isNotEmpty)
          base = isLow ? "$s1-$s3重視の複合卵" : "$s1-$s3重視の複合精鋭";
        else
          base = isLow ? "${s1}重視の精鋭候補" : "${s1}重視の精鋭";
    }

    final Set<String> weaknessSet = {};
    void checkWeak(double val, String key) {
      if (val < 4.0 && (top1 - val) > 4.5) {
        if (key == "スピード") weaknessSet.add("鈍重");
        if (key == "スタミナ") weaknessSet.add("短距離特化");
        if (key == "山適性") weaknessSet.add("平地限定");
        if (key == "ロード") weaknessSet.add("不整地志向");
        if (key == "起伏耐性") weaknessSet.add("舗装路専用");
      }
    }

    checkWeak(worst, sortedKeys.last);
    if (sortedKeys.length > 1)
      checkWeak(secondWorst, sortedKeys[sortedKeys.length - 2]);

    String suffix = weaknessSet.isNotEmpty ? "（${weaknessSet.join('・')}）" : "";
    return "$prefix$base$suffix";
  }

  /// 詳細分析文生成ロジック（完全再現）
  static String generateDetailedAnalysis(
    String univName,
    Map<String, double> scores,
    Ghensuu gh,
  ) {
    final s = scores;
    StringBuffer sb = StringBuffer();

    final sortedStyles = s.keys.toList()
      ..sort((a, b) => (s[b] ?? 0).compareTo(s[a] ?? 0));
    final String t1 = sortedStyles[0];
    final String t2 = sortedStyles[1];
    final double maxV = s[t1] ?? 0.0;
    final double minV = s[sortedStyles.last] ?? 0.1;
    final double ratio = maxV / (minV < 0.5 ? 0.5 : minV);
    final bool isSkewed = ratio >= 1.8 && maxV >= 2.5;

    String teamStyle = "";
    if (ratio >= 2.5) {
      switch (t1) {
        case "スピード":
          teamStyle = "【極光の短距離砲・スピードジャンキー】";
          break;
        case "スタミナ":
          teamStyle = "【不尽のスタミナ・永久機関】";
          break;
        case "山適性":
          teamStyle = "【断崖の覇者・バーティカルマスター】";
          break;
        case "ロード":
          teamStyle = "【舗装路の化身・アスファルトビースト】";
          break;
        case "起伏耐性":
          teamStyle = "【悪路無双・ラフロードハンター】";
          break;
        default:
          teamStyle = "【一点突破・${t1}の求道者】";
      }
    } else if (isSkewed) {
      final combo = "$t1-$t2";
      if (combo.contains("山適性") && combo.contains("起伏耐性"))
        teamStyle = "【不整地特化・ワイルドランナー】";
      else if (combo.contains("スピード") && combo.contains("ロード"))
        teamStyle = "【高速巡航・スプリントスター】";
      else if (combo.contains("スタミナ") && combo.contains("ロード"))
        teamStyle = "【長距離砲・ロードクルーザー】";
      else if (combo.contains("スタミナ") && combo.contains("起伏耐性"))
        teamStyle = "【不撓不屈・タフネスモンスター】";
      else if (sortedStyles.last == "スピード")
        teamStyle = "【超鈍重・安全運転型】";
      else if (sortedStyles.last == "山適性")
        teamStyle = "【平地番長・急勾配アレルギー】";
      else
        teamStyle = "【特化型・${t1}のスペシャリスト】";
    } else if (maxV >= 8.5 && ratio < 1.4) {
      teamStyle = "【完全無欠・パーフェクトオールラウンダー】";
    } else if (maxV >= 7.0 && ratio < 1.5) {
      teamStyle = "【精鋭揃い・戦術均衡型】";
    } else if (maxV < 3.5) {
      teamStyle = ratio >= 1.5 ? "【原石・${t1}特化のプロトタイプ】" : "【再建途上・臥薪嘗胆の志士】";
    } else {
      teamStyle = "【汎用型・マルチロール】";
    }

    sb.writeln("$univName 分析結果");
    sb.writeln(teamStyle);
    sb.writeln("-" * 15);
    sb.writeln("■チーム能力パラメータ (10pt満点)");
    sb.writeln(
      "SP: ${s['スピード']!.toStringAsFixed(1)} / ST: ${s['スタミナ']!.toStringAsFixed(1)} / 山: ${s['山適性']!.toStringAsFixed(1)} / RD: ${s['ロード']!.toStringAsFixed(1)} / 起伏: ${s['起伏耐性']!.toStringAsFixed(1)}",
    );

    return sb.toString();
  }
}

Future<void> refreshAllUnivAnalysisData() async {
  final univBox = Hive.box<UnivData>('univBox');
  final senshuBox = Hive.box<SenshuData>('senshuBox');
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
  final kantoku = kantokuBox.get('KantokuData')!;

  final sortedUnivs = univBox.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final allSenshu = senshuBox.values.toList();

  // 1. 母集団集計
  Map<int, List<double>> pools = {
    0: [],
    1: [],
    2: [],
    4: [],
    5: [],
    6: [],
    7: [],
  };
  Map<int, Map<int, List<double>>> rawData = {};

  for (var s in allSenshu) {
    for (var idx in pools.keys) {
      double t = s.time_bestkiroku[idx];
      if (t > 0 && t < TEISUU.DEFAULTTIME) {
        rawData
            .putIfAbsent(s.univid, () => {})
            .putIfAbsent(idx, () => [])
            .add(t);
      }
    }
  }

  Map<int, Map<int, double>> univAverages = {};
  rawData.forEach((uid, eventMap) {
    univAverages[uid] = {};
    eventMap.forEach((eIdx, times) {
      times.sort();
      int count = math.min(10, times.length);
      if (count > 0) {
        double avg = times.sublist(0, count).reduce((a, b) => a + b) / count;
        univAverages[uid]![eIdx] = avg;
        pools[eIdx]!.add(avg);
      }
    });
  });

  // 2. 計算とデータ蓄積
  List<String> combinedTexts = [];

  for (var univ in sortedUnivs) {
    double sc(int idx) {
      final val = univAverages[univ.id]?[idx];
      if (val == null || val <= 0) return 1.0;
      final pool = pools[idx]!;
      double mean = pool.reduce((a, b) => a + b) / pool.length;
      double varSum = pool
          .map((x) => math.pow(x - mean, 2).toDouble())
          .reduce((a, b) => a + b);
      double stdDev = math.sqrt(varSum / pool.length);
      double tScore = (stdDev == 0) ? 50 : 50 + 10 * (mean - val) / stdDev;
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

    // テキスト生成
    String type = UnivAnalysisEngine.determineTeamType(scores);
    String analysis = UnivAnalysisEngine.generateDetailedAnalysis(
      univ.name,
      scores,
      gh,
    );

    // 大学ごとのテキストをパック
    combinedTexts.add("$type${UnivAnalysisEngine.fieldSeparator}$analysis");

    // スコアを監督データに保存
    kantoku.yobiint3[10 + univ.id] = UnivAnalysisEngine.compressScores(
      scores,
      avg,
    );
  }

  // 3. 11番目の大学のname_tanshukuに全てを結合して保存
  sortedUnivs[11].name_tanshuku = combinedTexts.join(
    UnivAnalysisEngine.unitSeparator,
  );

  await sortedUnivs[11].save();
  await kantoku.save();
}

/// 大学解析パネルを返す共通Widget
/// 引数が targetUnivId のみの場合は保存データを表示、
/// override... 引数がある場合はその値を優先表示する。
Widget buildUnivAnalysisPanel(
  int targetUnivId, {
  Map<String, double>? overrideScores,
  String? overrideType,
  String? overrideAnalysis,
}) {
  final univBox = Hive.box<UnivData>('univBox');
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final sortedUnivs = univBox.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final kantoku = kantokuBox.get('KantokuData')!;

  // --- データの取得/抽出 ---
  Map<String, double> scores;
  double average;
  String type;
  String analysis;

  if (overrideScores != null &&
      overrideType != null &&
      overrideAnalysis != null) {
    // 【モードA】引数から渡された最新データを使用（ランキング画面用）
    scores = overrideScores;
    average = scores.values.reduce((a, b) => a + b) / scores.length;
    type = overrideType;
    analysis = overrideAnalysis;
  } else {
    // 【モードB】Hiveに保存されているデータを使用（大学詳細画面用）
    final allTexts = sortedUnivs[11].name_tanshuku.split(
      UnivAnalysisEngine.unitSeparator,
    );
    type = "❔ 解析不能";
    analysis = "データがありません。";

    if (targetUnivId >= 0 && targetUnivId < allTexts.length) {
      final fields = allTexts[targetUnivId].split(
        UnivAnalysisEngine.fieldSeparator,
      );
      if (fields.length >= 2) {
        type = fields[0];
        analysis = fields[1];
      }
    }

    final scoreData = UnivAnalysisEngine.decompressScores(
      kantoku.yobiint3[10 + targetUnivId],
    );
    scores = scoreData['scores'];
    average = scoreData['average'];
  }

  final String univName = sortedUnivs
      .firstWhere((u) => u.id == targetUnivId)
      .name;

  // --- UI構築 (デザイン完全再現 & Overflow防止) ---
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    univName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellowAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    "総合",
                    style: TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                  Text(
                    average.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white38, height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左側：レーダーチャート
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(painter: RadarChartPainter(scores)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 右側：分析テキスト
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      analysis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            "SP:スピード  ST:スタミナ  山適:山適性  RD:ロード  起伏:起伏耐性",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "※説明書画面上部の「夏TT開催大学変更」で全大学開催を選択していないと正確な分析はできません",
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
