import 'dart:io';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart'; // 忘れずにインポート
import 'package:ekiden/kansuu/ChartPanelUniv.dart';

enum DisplayEvent {
  best5000m,
  best10000m,
  bestHalf,
  nobori10k,
  kudari10k,
  road10k,
  crokan10k,
  totalScore,
}

class UnivAverageTime {
  final int univid;
  final double averageTime;
  final int rank;
  final Map<DisplayEvent, double> allEventTimes;
  final Map<String, double> courseScores;
  UnivAverageTime(
    this.univid,
    this.averageTime,
    this.rank,
    this.allEventTimes,
    this.courseScores,
  );
}

class ModalAverageTop10TimeRankingView extends StatefulWidget {
  const ModalAverageTop10TimeRankingView({super.key});
  @override
  State<ModalAverageTop10TimeRankingView> createState() =>
      _ModalAverageTop10TimeRankingViewState();
}

class _ModalAverageTop10TimeRankingViewState
    extends State<ModalAverageTop10TimeRankingView> {
  DisplayEvent _displayEvent = DisplayEvent.totalScore;
  int? _selectedUnivId;
  int? _targetRaceIdx;
  bool _isLoading = false; // ぐるぐる表示用

  final ScreenshotController _screenshotController = ScreenshotController();

  final List<String> _raceNames = [
    "10月駅伝",
    "11月駅伝",
    "正月駅伝",
    "11月予選",
    "正月予選",
    "カスタム",
  ];

  @override
  void initState() {
    super.initState();
    final gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    _targetRaceIdx = 0;
    // もし現在の設定が予選(3 or 4)なら、強制的に0(10月)にする
    /*if (!(gh.hyojiracebangou <= 2 || gh.hyojiracebangou == 5)) {
      _targetRaceIdx = 0;
    } else {
      _targetRaceIdx = gh.hyojiracebangou;
    }*/
    _initAsync();
  }

  Future<void> _initAsync() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // 計算演出
    if (mounted) setState(() => _isLoading = false);
  }

  int _getTimeIndex(DisplayEvent event) {
    switch (event) {
      case DisplayEvent.best5000m:
        return 0;
      case DisplayEvent.best10000m:
        return 1;
      case DisplayEvent.bestHalf:
        return 2;
      case DisplayEvent.nobori10k:
        return 4;
      case DisplayEvent.kudari10k:
        return 5;
      case DisplayEvent.road10k:
        return 6;
      case DisplayEvent.crokan10k:
        return 7;
      default:
        return 0;
    }
  }

  double _calcT(
    double val,
    Iterable<double> pool, {
    bool lowerIsBetter = true,
  }) {
    if (pool.isEmpty) return 50.0;
    double mean = pool.reduce((a, b) => a + b) / pool.length;
    double variance =
        pool.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        pool.length;
    double stdDev = math.sqrt(variance);
    if (stdDev == 0) return 50.0;
    return lowerIsBetter
        ? 50 + 10 * (mean - val) / stdDev
        : 50 + 10 * (val - mean) / stdDev;
  }

  /*List<UnivAverageTime> _calculateRanking(
    List<SenshuData> allSenshuData,
    Map<int, UnivData> univMap,
    int raceIdx,
  ) {
    final Map<int, Map<DisplayEvent, double>> univAverages = {};
    final Map<DisplayEvent, List<double>> allAvgsPool = {
      for (var e in DisplayEvent.values) e: [],
    };

    // 1. 各大学の種目別生データを収集
    Map<int, Map<DisplayEvent, List<double>>> tempRaw = {};
    for (var s in allSenshuData) {
      if (!univMap.containsKey(s.univid)) continue;
      tempRaw.putIfAbsent(s.univid, () => {});
      for (var e in DisplayEvent.values) {
        if (e == DisplayEvent.totalScore) continue;
        double t = s.time_bestkiroku[_getTimeIndex(e)];
        if (t < TEISUU.DEFAULTTIME && t > 0) {
          tempRaw[s.univid]!.putIfAbsent(e, () => []).add(t);
        }
      }
    }

    // 2. 上位10名の平均タイムを算出
    tempRaw.forEach((uid, eventMap) {
      univAverages[uid] = {};
      eventMap.forEach((event, times) {
        times.sort();
        int count = math.min(10, times.length);
        if (count > 0) {
          double avg = times.sublist(0, count).reduce((a, b) => a + b) / count;
          univAverages[uid]![event] = avg;
          allAvgsPool[event]!.add(avg);
        }
      });
    });

    // 3. 偏差値ベースのスコア計算とリスト化
    List<UnivAverageTime> results = [];
    univAverages.forEach((uid, avgs) {
      // 5指標スコア生成
      double sc(DisplayEvent e) {
        final val = avgs[e];
        // データが存在しない、または 0 や不適切な値の場合は最低点 1.0 を返す
        if (val == null || val <= 0 || val >= TEISUU.DEFAULTTIME) {
          return 1.0;
        }

        // 偏差値を計算し、1.0 〜 10.0 の範囲に変換
        double tScore = _calcT(val, allAvgsPool[e] ?? []);
        return ((tScore - 30) / 4).clamp(1.0, 10.0);
      }

      Map<String, double> scores = {
        'スピード': (sc(DisplayEvent.best5000m) + sc(DisplayEvent.best10000m)) / 2,
        'スタミナ': sc(DisplayEvent.bestHalf),
        '山適性': (sc(DisplayEvent.nobori10k) + sc(DisplayEvent.kudari10k)) / 2,
        'ロード': sc(DisplayEvent.road10k),
        '起伏耐性': sc(DisplayEvent.crokan10k),
      };

      // 並び替え用基準値 (AI分析時は全種目平均、個別種目時はそのタイム)
      double sortVal = (_displayEvent == DisplayEvent.totalScore)
          ? (avgs.values.reduce((a, b) => a + b) / avgs.length)
          : (avgs[_displayEvent] ?? 999999.0);

      results.add(UnivAverageTime(uid, sortVal, 0, avgs, scores));
    });

    // 4. ソートして順位を確定
    results.sort((a, b) {
      // メインの評価（タイム）で比較
      int cmp = a.averageTime.compareTo(b.averageTime);
      if (cmp != 0) return cmp;

      // タイムが全く同じなら、大学IDで一意に確定（安定ソート）
      return a.univid.compareTo(b.univid);
    });
    return List.generate(results.length, (i) {
      return UnivAverageTime(
        results[i].univid,
        results[i].averageTime,
        i + 1,
        results[i].allEventTimes,
        results[i].courseScores,
      );
    });
  }*/

  List<UnivAverageTime> _calculateRanking(
    List<SenshuData> allSenshuData,
    Map<int, UnivData> univMap,
    int raceIdx,
  ) {
    final Map<int, Map<DisplayEvent, double>> univAverages = {};
    final Map<DisplayEvent, List<double>> allAvgsPool = {
      for (var e in DisplayEvent.values) e: [],
    };

    // 1. 各大学の種目別生データを収集
    Map<int, Map<DisplayEvent, List<double>>> tempRaw = {};
    for (var s in allSenshuData) {
      if (!univMap.containsKey(s.univid)) continue;
      tempRaw.putIfAbsent(s.univid, () => {});
      for (var e in DisplayEvent.values) {
        if (e == DisplayEvent.totalScore) continue;
        double t = s.time_bestkiroku[_getTimeIndex(e)];
        if (t < TEISUU.DEFAULTTIME && t > 0) {
          tempRaw[s.univid]!.putIfAbsent(e, () => []).add(t);
        }
      }
    }

    // 2. 上位10名の平均タイムを算出
    tempRaw.forEach((uid, eventMap) {
      univAverages[uid] = {};
      eventMap.forEach((event, times) {
        times.sort();
        int count = math.min(10, times.length);
        if (count > 0) {
          double avg = times.sublist(0, count).reduce((a, b) => a + b) / count;
          univAverages[uid]![event] = avg;
          allAvgsPool[event]!.add(avg);
        }
      });
    });

    // 3. 偏差値ベースのスコア計算とリスト化
    List<UnivAverageTime> results = [];
    univAverages.forEach((uid, avgs) {
      double sc(DisplayEvent e) {
        final val = avgs[e];
        if (val == null || val <= 0 || val >= TEISUU.DEFAULTTIME) {
          return 1.0;
        }
        double tScore = _calcT(val, allAvgsPool[e] ?? []);
        return ((tScore - 30) / 4).clamp(1.0, 10.0);
      }

      Map<String, double> scores = {
        'スピード': (sc(DisplayEvent.best5000m) + sc(DisplayEvent.best10000m)) / 2,
        'スタミナ': sc(DisplayEvent.bestHalf),
        '山適性': (sc(DisplayEvent.nobori10k) + sc(DisplayEvent.kudari10k)) / 2,
        'ロード': sc(DisplayEvent.road10k),
        '起伏耐性': sc(DisplayEvent.crokan10k),
      };

      // 並び替え用基準値
      double sortVal;
      if (_displayEvent == DisplayEvent.totalScore) {
        sortVal = scores.values.reduce((a, b) => a + b) / scores.length;
      } else {
        sortVal = avgs[_displayEvent] ?? 999999.0;
      }

      results.add(UnivAverageTime(uid, sortVal, 0, avgs, scores));
    });

    // 4. ソートして順位を確定
    results.sort((a, b) {
      // メイン評価値での比較
      int cmp;
      if (_displayEvent == DisplayEvent.totalScore) {
        // AI分析（スコア）は大きい順（降順）
        cmp = b.averageTime.compareTo(a.averageTime);
      } else {
        // タイムは小さい順（昇順）
        cmp = a.averageTime.compareTo(b.averageTime);
      }

      // --- 【同値対処】メイン評価が全く同じ場合 ---
      if (cmp != 0) return cmp;

      // 評価が同じなら、大学IDで比較（これで順位が入れ替わらなくなる）
      return a.univid.compareTo(b.univid);
    });

    // 5. 確定した順位を反映させて返却
    return List.generate(results.length, (i) {
      return UnivAverageTime(
        results[i].univid,
        results[i].averageTime,
        i + 1, // ここで 1, 2, 3... と順位を割り振る
        results[i].allEventTimes,
        results[i].courseScores,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
    final Ghensuu gh = ghensuuBox.getAt(0)!;
    // --- 修正：許可されたID以外なら強制的に 0 にする ---
    if (_targetRaceIdx == null) {
      int initialIdx = gh.hyojiracebangou;
      // [0, 1, 2, 5] に含まれていない場合は 0 (10月駅伝) をデフォルトにする
      _targetRaceIdx = [0, 1, 2, 5].contains(initialIdx) ? initialIdx : 0;
    }

    List<UnivData> sortedUnivData = univBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    _raceNames[5] = sortedUnivData[0].name_tanshuku;
    final univMap = {for (var u in univBox.values) u.id: u};

    // ★ ここで定義することで、下のどこからでも参照可能になります
    final List<UnivData> sortedUnivs = univBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '上位10名AI分析',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : ValueListenableBuilder(
              valueListenable: senshuBox.listenable(),
              builder: (context, Box<SenshuData> sBox, _) {
                final ranking = _calculateRanking(
                  sBox.values.toList(),
                  univMap,
                  _targetRaceIdx!,
                );
                _selectedUnivId ??= gh.hyojiunivnum;
                final selectedData = ranking.firstWhere(
                  (e) => e.univid == _selectedUnivId,
                  orElse: () => ranking.first,
                );

                return Column(
                  children: [
                    // ★ ここにドロップダウンを2行で配置
                    if (_displayEvent == DisplayEvent.totalScore)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.black,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                /*const Text(
                                  "対象: ",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),*/
                                // --- 左矢印ボタン ---
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.cyanAccent,
                                  ),
                                  onPressed: () {
                                    final currentIndex = sortedUnivs.indexWhere(
                                      (u) => u.id == _selectedUnivId,
                                    );
                                    if (currentIndex > 0) {
                                      setState(
                                        () => _selectedUnivId =
                                            sortedUnivs[currentIndex - 1].id,
                                      );
                                    } else {
                                      // 最初の要素なら最後にループ
                                      setState(
                                        () => _selectedUnivId =
                                            sortedUnivs.last.id,
                                      );
                                    }
                                  },
                                ),
                                Expanded(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedUnivId,
                                    dropdownColor: Colors.grey[900],
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 14,
                                    ),
                                    items: sortedUnivs
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u.id,
                                            child: Text(
                                              u.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _selectedUnivId = val),
                                  ),
                                ),
                                // --- 右矢印ボタン ---
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.cyanAccent,
                                  ),
                                  onPressed: () {
                                    final currentIndex = sortedUnivs.indexWhere(
                                      (u) => u.id == _selectedUnivId,
                                    );
                                    if (currentIndex != -1 &&
                                        currentIndex < sortedUnivs.length - 1) {
                                      setState(
                                        () => _selectedUnivId =
                                            sortedUnivs[currentIndex + 1].id,
                                      );
                                    } else {
                                      // 最後の要素なら最初にループ
                                      setState(
                                        () => _selectedUnivId =
                                            sortedUnivs.first.id,
                                      );
                                    }
                                  },
                                ),

                                // 2. 画像としてシェアするボタン（新規追加）
                                IconButton(
                                  icon: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  tooltip: '画像でシェア',
                                  onPressed: () async {
                                    // 画面が黒いため、処理中であることを示すスナックバーを出すと親切です
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('画像を生成中...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );

                                    // 画像キャプチャ（pixelRatioを上げると文字がクッキリします）
                                    final Uint8List? imageBytes =
                                        await _screenshotController.capture(
                                          pixelRatio: 2.5,
                                        );

                                    if (imageBytes != null) {
                                      final tempDir =
                                          await getTemporaryDirectory();
                                      final file = await File(
                                        '${tempDir.path}/ekiden_analysis.png',
                                      ).create();
                                      await file.writeAsBytes(imageBytes);

                                      // 画像共有（ハッシュタグなどはキャプションとして付与）
                                      await Share.shareXFiles([
                                        XFile(file.path),
                                      ], text: "#箱庭小駅伝SS");
                                    }
                                  },
                                ),

                                // ★ シェアボタンをここに配置することでrankingエラーを回避
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    final type = _determineTeamType(
                                      selectedData.courseScores,
                                    );

                                    // 安全なインデックスを確定させる
                                    final int safeRaceIdx =
                                        [0, 1, 2, 5].contains(_targetRaceIdx)
                                        ? _targetRaceIdx!
                                        : 0;
                                    final analysis = _generateDetailedAnalysis(
                                      selectedData,
                                      gh,
                                      safeRaceIdx,
                                    );

                                    // 大学名を取得（univMapから）
                                    final String univName =
                                        univMap[selectedData.univid]?.name ??
                                        "分析対象大学";

                                    // 共有するテキスト全体を構築
                                    final String shareText =
                                        """
【上位10名AI分析レポート】
対象：$univName
チームタイプ：$type

$analysis

#箱庭小駅伝SS
""";

                                    // ★ ここでOS標準の共有メニューを呼び出す！
                                    Share.share(
                                      shareText,
                                      subject: '$univName の分析結果',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: ListView(
                        children: [
                          if (_displayEvent == DisplayEvent.totalScore)
                            Screenshot(
                              controller: _screenshotController,
                              child: _buildAnalysisPanel(
                                selectedData,
                                univMap,
                                gh,
                              ),
                            ),
                          ...ranking.map(
                            (item) => _buildListTile(item, univMap),
                          ),
                        ],
                      ),
                    ),
                    _buildScrollableNavigation(),
                  ],
                );
              },
            ),
    );
  }

  // --- AI分析パネルの構築 (共通関数呼び出し版) ---
  Widget _buildAnalysisPanel(
    UnivAverageTime data,
    Map<int, UnivData> univMap,
    Ghensuu gh,
  ) {
    // 1. この画面で計算された最新のスコアを元に、二つ名と分析文をその場で生成
    final String currentType = UnivAnalysisEngine.determineTeamType(
      data.courseScores,
    );
    final String currentAnalysis = UnivAnalysisEngine.generateDetailedAnalysis(
      univMap[data.univid]?.name ?? "分析大学",
      data.courseScores,
      gh,
    );

    // 2. 共通Widgetに最新データを流し込んで表示
    return buildUnivAnalysisPanel(
      data.univid,
      overrideScores: data.courseScores,
      overrideType: currentType,
      overrideAnalysis: currentAnalysis,
    );
  }

  // --- AI分析パネルの構築 ---
  /*Widget _buildAnalysisPanel(
    UnivAverageTime data,
    Map<int, UnivData> univMap,
    Ghensuu gh,
  ) {
    final analysisText = _generateDetailedAnalysis(data, gh, _targetRaceIdx!);
    final teamType = _determineTeamType(data.courseScores);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Wrap(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    univMap[data.univid]?.name ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$teamType",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    //softWrap: true,
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white38),
          SizedBox(
            //height: 280,
            height: 320,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: RadarChartPainter(data.courseScores),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        analysisText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ★ ここに凡例（説明書き）を追加
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "SP:スピード  ST:スタミナ  山適:山適性\nRD:ロード  起伏:起伏耐性\n\n※説明書画面上部の「夏TT開催大学変更」で全大学開催を選択していないと正確な分析はできません",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.4, // 行間を少し広げて読みやすく
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/

  String _determineTeamType(Map<String, double> scores) {
    if (scores.isEmpty) return "❔ 謎に包まれた集団";

    final sortedKeys = scores.keys.toList()
      ..sort((a, b) {
        int cmp = (scores[b] ?? 0).compareTo(scores[a] ?? 0);
        if (cmp != 0) return cmp;
        // スコアが同じなら名前のアルファベット順などで固定
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

    // --- A. 特殊称号判定（最優先） ---
    if (avg >= 9.7) return "🌟【神域】全知全能の守護神";
    if (avg >= 9.2) return "🏆【伝説】古今無双の極致";
    if (top1 >= 9.2 && top2 <= 5.0) return "【唯一神】純粋なる$s1の化身";
    if (top1 >= 8.0 && top2 >= 8.0 && top3 >= 8.0) return "【強三種】不動のトリニティ";

    // 特殊コンボ判定
    if (s1 == "山適性" && s2 == "起伏耐性" && (scores["スピード"] ?? 0) <= 3.5)
      return "【修羅】急勾配の狂信者";
    if (s1 == "スピード" && s2 == "ロード" && (scores["スタミナ"] ?? 0) <= 3.5)
      return "【刹那】一撃必殺の特攻隊";

    if (avg <= 1.7) return "【深淵】伸び代しかない未完の器";
    if (avg <= 2.3) return "【奮闘】逆境の挑戦者";
    if (top1 - worst <= 0.5 && avg >= 7.8) return "【究極】五角形の完成者";
    if (top1 - worst <= 1.0 && avg >= 5.5) return "【均衡】調和の探求者";

    // --- B. ランクプレフィックス ---
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

    // --- C. ベース名の決定（全20パターンの組み合わせを完全網羅 + 低レベル調整） ---
    String base = "";
    bool isLow = (top1 < 5.5);
    final combo = "$s1-$s2";

    switch (combo) {
      // 1. スピード × スタミナ
      case "スピード-スタミナ":
      case "スタミナ-スピード":
        base = isLow ? "王道走者の卵" : "王道走者";
        break;
      // 2. スピード × 山適性
      case "スピード-山適性":
      case "山適性-スピード":
        base = isLow ? "飛天の隼の雛" : "飛天の隼";
        break;
      // 3. スピード × ロード
      case "スピード-ロード":
      case "ロード-スピード":
        base = isLow ? "蒼き流星の志望者" : "蒼き流星";
        break;
      // 4. スピード × 起伏耐性
      case "スピード-起伏耐性":
      case "起伏耐性-スピード":
        base = isLow ? "荒野の疾走者の芽" : "荒野の疾走者";
        break;
      // 5. スタミナ × 山適性
      case "スタミナ-山適性":
      case "山適性-スタミナ":
        base = isLow ? "不落の要塞の基礎" : "不落の要塞";
        break;
      // 6. スタミナ × ロード
      case "スタミナ-ロード":
      case "ロード-スタミナ":
        base = isLow ? "鉄の脚の初心者" : "鉄の脚";
        break;
      // 7. スタミナ × 起伏耐性
      case "スタミナ-起伏耐性":
      case "起伏耐性-スタミナ":
        base = isLow ? "野獣の心の種" : "野獣の心";
        break;
      // 8. 山適性 × 起伏耐性
      case "山適性-起伏耐性":
      case "起伏耐性-山適性":
        base = isLow ? "絶壁の隠者の見習い" : "絶壁の隠者";
        break;
      // 9. 山適性 × ロード
      case "山適性-ロード":
      case "ロード-山適性":
        base = isLow ? "万能の開拓者の卵" : "万能の開拓者";
        break;
      // 10. ロード × 起伏耐性
      case "ロード-起伏耐性":
      case "起伏耐性-ロード":
        base = isLow ? "走境無双の覇者の候補" : "走境無双の覇者";
        break;
      // 例外・単一項目
      default:
        if (s3.isNotEmpty) {
          base = isLow ? "$s1-$s3重視の複合卵" : "$s1-$s3重視の複合精鋭";
        } else if (sortedKeys.length == 1) {
          base = isLow ? "${s1}単独の芽" : "${s1}単独構成";
        } else {
          base = isLow ? "${s1}重視の精鋭候補" : "${s1}重視の精鋭";
        }
    }

    // --- D. サフィックス（Setを使って重複防止） ---
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

    // --- E. 絵文字（2つ表示対応） ---
    String getIcon(String k) {
      if (k == "スピード") return "🐆";
      if (k == "スタミナ") return "🐘";
      if (k == "山適性") return "⛰️";
      if (k == "ロード") return "🛣️";
      if (k == "起伏耐性") return "👺";
      return "";
    }

    String icon = getIcon(s1);
    if (s2.isNotEmpty && (top1 - top2) < 1.2) {
      icon += getIcon(s2);
    }

    //return "${icon.isEmpty ? '👟' : icon} $prefix$base$suffix";
    return "$prefix$base$suffix";
  }

  // --- 超絶・神算鬼謀分析テキスト生成（戦略シミュレーター版） ---
  String _generateDetailedAnalysis(
    UnivAverageTime target,
    Ghensuu gh,
    int raceIdx,
  ) {
    final s = target.courseScores;
    int kukanCount = gh.kukansuu_taikaigoto[raceIdx];
    final String univName =
        Hive.box<UnivData>('univBox').get(target.univid)?.name ?? "貴校";

    // --- 1. 母集団データの集計（絶対評価の基準値構築） ---
    List<double> allDist = [];
    List<double> allClimb = [];
    List<double> allDown = [];
    List<double> allUdDensity = [];

    for (int r = 0; r < 6; r++) {
      if (r == 3 || r == 4) continue;
      int c = gh.kukansuu_taikaigoto[r];
      for (int i = 0; i < c; i++) {
        double dist = gh.kyori_taikai_kukangoto[r][i];
        if (dist <= 0) continue;
        allDist.add(dist);
        allClimb.add(
          gh.kyoriwariainobori_taikai_kukangoto[r][i] *
              gh.heikinkoubainobori_taikai_kukangoto[r][i],
        );
        allDown.add(
          gh.kyoriwariaikudari_taikai_kukangoto[r][i] *
              (-gh.heikinkoubaikudari_taikai_kukangoto[r][i]),
        );
        allUdDensity.add(
          gh.noborikudarikirikaekaisuu_taikai_kukangoto[r][i] / dist,
        );
      }
    }

    StringBuffer sb = StringBuffer();

    // --- 2. チームプロファイリング（倍率判定・歪み検知版） ---
    String teamStyle = "";
    final sortedStyles = s.keys.toList()
      ..sort((a, b) => (s[b] ?? 0).compareTo(s[a] ?? 0));
    final String t1 = sortedStyles[0];
    final String t2 = sortedStyles[1];
    final double maxV = s[t1] ?? 0.0;
    final double minV = s[sortedStyles.last] ?? 0.1; // 0除算防止

    // 最大値が最小値の何倍あるか（比率）で歪みを判定
    final double ratio = maxV / (minV < 0.5 ? 0.5 : minV);
    final bool isSkewed = ratio >= 1.8 && maxV >= 2.5;

    if (ratio >= 2.5) {
      // 超特化型（2.5倍以上の圧倒的突出）
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
      // 歪な形状（比率1.8倍以上）
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
    sb.writeln("-" * 20);
    // ★ 数値指標の表示を追加
    sb.writeln("■チーム能力パラメータ (10点満点)");
    sb.writeln(
      "  スピード: ${s['スピード']!.toStringAsFixed(1)} / スタミナ: ${s['スタミナ']!.toStringAsFixed(1)} / 山適性: ${s['山適性']!.toStringAsFixed(1)} / ロード: ${s['ロード']!.toStringAsFixed(1)} / 起伏耐性: ${s['起伏耐性']!.toStringAsFixed(1)}",
    );

    return sb.toString();
  }

  Widget _buildListTile(UnivAverageTime item, Map<int, UnivData> univMap) {
    final isSelected = item.univid == _selectedUnivId;
    return Container(
      color: isSelected ? Colors.white12 : Colors.transparent,
      child: ListTile(
        onTap: () => setState(() => _selectedUnivId = item.univid),
        leading: Text(
          "${item.rank}",
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        title: Text(
          univMap[item.univid]?.name ?? "不明",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Text(
          // --- ここを修正 ---
          _displayEvent == DisplayEvent.totalScore
              ? item.averageTime.toStringAsFixed(1) // "分析完了" から スコア数値（小数点1桁）に変更
              : TimeDate.timeToFunByouString(item.averageTime),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableNavigation() {
    return Container(
      // 高さを95程度まで確保（SafeArea込みで余裕を持たせる）
      height: 95,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          scrollDirection: Axis.horizontal,
          // 垂直方向のpaddingを最小限にして、チップが潰れるのを防ぐ
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          children: DisplayEvent.values
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    // Centerで囲むことでチップが縦に引き伸ばされるのを防ぐ
                    child: ChoiceChip(
                      label: Text(
                        _getEventLabel(e),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      selected: _displayEvent == e,
                      onSelected: (val) => setState(() => _displayEvent = e),
                      selectedColor: Colors.blue[800],
                      backgroundColor: Colors.grey[850],
                      visualDensity: VisualDensity.compact, // チップを少しスリムにする
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // イベントに応じた日本語ラベル（エラー箇所）
  String _getEventLabel(DisplayEvent event) {
    switch (event) {
      case DisplayEvent.best5000m:
        return '5000m';
      case DisplayEvent.best10000m:
        return '10000m';
      case DisplayEvent.bestHalf:
        return 'ハーフ';
      case DisplayEvent.nobori10k:
        return '登り10k';
      case DisplayEvent.kudari10k:
        return '下り10k';
      case DisplayEvent.road10k:
        return 'ロード10k';
      case DisplayEvent.crokan10k:
        return 'クロカン10k';
      case DisplayEvent.totalScore:
        return 'AI分析';
    }
  }

  // 出力・シェア用ダイアログ
  void _showExportDialog(
    UnivAverageTime data,
    String name,
    String type,
    String analysis,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "分析結果の出力",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "【レポートをコピー】",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  "◆分析対象: $name\n$type\n\n$analysis",
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("閉じる"),
          ),
        ],
      ),
    );
  }
}

// --- レーダーチャートの描画クラス ---
class RadarChartPainter extends CustomPainter {
  final Map<String, double> scores;
  RadarChartPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 半径を少し調整して、文字がはみ出さないように確保
    final radius = math.min(size.width, size.height) / 2 * 0.7;
    final angle = (2 * math.pi) / 5;

    final paintLine = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // --- 1. 背景の五角形（グリッド）を描画 ---
    for (var i = 1; i <= 5; i++) {
      final r = radius * (i / 5);
      final path = Path();
      for (var j = 0; j < 5; j++) {
        double x = center.dx + r * math.cos(angle * j - math.pi / 2);
        double y = center.dy + r * math.sin(angle * j - math.pi / 2);
        if (j == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paintLine);
    }

    // 中心から各頂点へのガイド線
    for (var i = 0; i < 5; i++) {
      double x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      double y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), paintLine);
    }

    // --- 2. スコアエリアの描画 ---
    final scoreKeys = ['スピード', 'スタミナ', '山適性', 'ロード', '起伏耐性'];
    final paintFill = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final scorePath = Path();
    for (var i = 0; i < 5; i++) {
      // スコアは最大10を想定
      double val = (scores[scoreKeys[i]] ?? 0).clamp(0, 10);
      double r = radius * (val / 10);
      double x = center.dx + r * math.cos(angle * i - math.pi / 2);
      double y = center.dy + r * math.sin(angle * i - math.pi / 2);
      if (i == 0)
        scorePath.moveTo(x, y);
      else
        scorePath.lineTo(x, y);
    }
    scorePath.close();
    canvas.drawPath(scorePath, paintFill);
    canvas.drawPath(scorePath, paintStroke);

    // --- 3. ラベル（略称）の描画 ---
    final labels = ['SP', 'ST', '山適', 'RD', '起伏'];
    for (var i = 0; i < 5; i++) {
      // radius + 22 程度に設定して文字を少し外側に
      double x = center.dx + (radius + 22) * math.cos(angle * i - math.pi / 2);
      double y = center.dy + (radius + 22) * math.sin(angle * i - math.pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13, // 視認性を重視して13pxにアップ
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 文字が中心からずれないよう、tpのサイズ分オフセット調整
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter old) => old.scores != scores;
}
