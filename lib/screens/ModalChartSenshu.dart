import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ekiden/screens/ModalAverageTop10TimeRankingView.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

/// 選手個人のスコアを保持するクラス
class SenshuScoreData {
  final SenshuData senshu;
  final Map<String, double> scores;
  final double averageScore;

  SenshuScoreData({
    required this.senshu,
    required this.scores,
    required this.averageScore,
  });
}

class SenshuRadarAnalysisView extends StatefulWidget {
  const SenshuRadarAnalysisView({super.key});

  @override
  State<SenshuRadarAnalysisView> createState() =>
      _SenshuRadarAnalysisViewState();
}

class _SenshuRadarAnalysisViewState extends State<SenshuRadarAnalysisView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  int? _selectedSenshuId;
  bool _isLoading = false;
  // 並び替え順の状態管理
  bool _sortByAverage = false;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSenshuDetail(int id) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '詳細',
      pageBuilder: (_, __, ___) => ModalSenshuDetailView(senshuId: id),
    );
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

  List<SenshuScoreData> _calculateSenshuScores(
    List<SenshuData> allSenshu,
    int targetUnivId,
  ) {
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

    List<SenshuScoreData> results = [];
    final targetSenshus = allSenshu
        .where((s) => s.univid == targetUnivId)
        .toList();

    for (var s in targetSenshus) {
      double sc(int idx) {
        double t = s.time_bestkiroku[idx];
        if (t <= 0 || t >= TEISUU.DEFAULTTIME) return 1.0;
        double tScore = _calcT(t, pools[idx]!);
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
      results.add(
        SenshuScoreData(senshu: s, scores: scores, averageScore: avg),
      );
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final senshuBox = Hive.box<SenshuData>('senshuBox');
    final univBox = Hive.box<UnivData>('univBox');
    final targetUniv = univBox.get(gh.hyojiunivnum);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${targetUniv?.name ?? "所属"} 選手AI分析',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : ValueListenableBuilder(
              valueListenable: senshuBox.listenable(),
              builder: (context, Box<SenshuData> sBox, _) {
                final rawList = _calculateSenshuScores(
                  sBox.values.toList(),
                  gh.hyojiunivnum,
                );

                if (rawList.isEmpty)
                  return const Center(
                    child: Text(
                      "選手データがありません",
                      style: TextStyle(color: Colors.white),
                    ),
                  );

                // 指定されたソート順でリストを作成（ドロップダウンとタイルリスト共通）
                final sortedList = List<SenshuScoreData>.from(rawList);
                if (_sortByAverage) {
                  sortedList.sort((a, b) {
                    // 1. まずは総合評価で比較
                    int cmp = b.averageScore.compareTo(a.averageScore);
                    if (cmp != 0) return cmp;

                    // 2. 評価が同じなら学年で比較（降順）
                    int gakunenCmp = b.senshu.gakunen.compareTo(
                      a.senshu.gakunen,
                    );
                    if (gakunenCmp != 0) return gakunenCmp;

                    // 3. 学年も同じならIDで比較（昇順）で一意に確定させる
                    return a.senshu.id.compareTo(b.senshu.id);
                  });
                } else {
                  sortedList.sort((a, b) {
                    int cmp = b.senshu.gakunen.compareTo(a.senshu.gakunen);
                    if (cmp != 0) return cmp;
                    return a.senshu.id.compareTo(b.senshu.id);
                  });
                }

                _selectedSenshuId ??= sortedList.first.senshu.id;
                final selectedData = sortedList.firstWhere(
                  (e) => e.senshu.id == _selectedSenshuId,
                  orElse: () => sortedList.first,
                );

                return Column(
                  children: [
                    _buildTopToolbar(sortedList, selectedData),
                    _buildSenshuSelector(sortedList),
                    Expanded(
                      child: ListView(
                        children: [
                          Screenshot(
                            controller: _screenshotController,
                            child: _buildAnalysisPanel(selectedData),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              _sortByAverage
                                  ? "チーム内能力順リスト（総合評価順）"
                                  : "チーム内能力順リスト（学年順）",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          // 下部のリストも sortedList を使用して連動させる
                          ...sortedList.map((item) => _buildSenshuTile(item)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTopToolbar(
    List<SenshuScoreData> list,
    SenshuScoreData currentData,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // 若干明るいグレーで視認性確保
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          const Text(
            "並び替え：",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          _sortChip(
            "学年順",
            !_sortByAverage,
            () => setState(() => _sortByAverage = false),
          ),
          const SizedBox(width: 4),
          _sortChip(
            "評価順",
            _sortByAverage,
            () => setState(() => _sortByAverage = true),
          ),

          const Spacer(),

          IconButton(
            icon: const Icon(Icons.image, color: Colors.white, size: 20),
            onPressed: () => _shareSenshuAnalysis(selectedData: currentData),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: () => _shareTextAnalysis(currentData),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? null : Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSenshuSelector(List<SenshuScoreData> list) {
    final currentIndex = list.indexWhere(
      (e) => e.senshu.id == _selectedSenshuId,
    );

    void moveStep(int step) {
      int nextIndex = (currentIndex + step) % list.length;
      if (nextIndex < 0) nextIndex = list.length - 1;
      setState(() => _selectedSenshuId = list[nextIndex].senshu.id);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.cyanAccent,
              size: 20,
            ),
            onPressed: () => moveStep(-1),
          ),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedSenshuId,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              underline: Container(height: 1, color: Colors.white24),
              items: list
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.senshu.id,
                      child: Text("${s.senshu.name} (${s.senshu.gakunen}年)"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedSenshuId = val),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.cyanAccent,
              size: 20,
            ),
            onPressed: () => moveStep(1),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel(SenshuScoreData data) {
    return Container(
      color: Colors.black,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.senshu.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${data.senshu.gakunen}年生",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showSenshuDetail(data.senshu.id),
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
            SizedBox(
              //height: 250,
              height: 320,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: RadarChartPainter(data.scores),
                    ),
                  ),
                  const SizedBox(width: 10), // 間隔を少し詰めました
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, // 左右パディングを調整
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // ★ スクロール可能に修正
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "総合評価",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              data.averageScore.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 16),
                            ...data.scores.entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4, // タップしやすさと視認性のために微増
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // ★ 項目名の自動改行対応
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // 数値は改行させない
                                        Text(
                                          e.value.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildSenshuTile(SenshuScoreData item) {
    final isSelected = item.senshu.id == _selectedSenshuId;
    return ListTile(
      onTap: () => setState(() => _selectedSenshuId = item.senshu.id),
      tileColor: isSelected ? Colors.white10 : Colors.transparent,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: Text(
          "${item.senshu.gakunen}",
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text(
        item.senshu.name,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Text(
        "AVG: ${item.averageScore.toStringAsFixed(1)}",
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _shareTextAnalysis(SenshuScoreData data) {
    String scoreText = data.scores.entries
        .map((e) => "・${e.key}: ${e.value.toStringAsFixed(1)}")
        .join("\n");
    String shareContent =
        "【選手能力分析報告】\n"
        "氏名：${data.senshu.name} (${data.senshu.gakunen}年)\n"
        "総合評価：${data.averageScore.toStringAsFixed(1)}\n"
        "--- 指標詳細 ---\n"
        "$scoreText\n\n"
        "#箱庭小駅伝SS";
    Share.share(shareContent);
  }

  Future<void> _shareSenshuAnalysis({
    required SenshuScoreData selectedData,
  }) async {
    final Uint8List? imageBytes = await _screenshotController.capture(
      pixelRatio: 2.5,
    );
    if (imageBytes == null) return;
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/senshu_analysis.png').create();
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: "【選手能力分析】${selectedData.senshu.name} 選手のレーダーチャートレポート #箱庭小駅伝SS");
  }
}
