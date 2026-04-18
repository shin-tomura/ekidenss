import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hive/hive.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';

class ModalEkidenKukanHistoryMatrixView extends StatefulWidget {
  final int targetUnivId;
  const ModalEkidenKukanHistoryMatrixView({
    super.key,
    required this.targetUnivId,
  });

  @override
  State<ModalEkidenKukanHistoryMatrixView> createState() =>
      _ModalEkidenKukanHistoryMatrixViewState();
}

class _ModalEkidenKukanHistoryMatrixViewState
    extends State<ModalEkidenKukanHistoryMatrixView> {
  final ScreenshotController _screenshotController = ScreenshotController();

  late List<SenshuData> _allSenshu;
  String _univName = "";
  bool _isInitialized = false;
  bool _isExporting = false;
  final bool _isJumpEnabled = true;

  final List<Map<String, dynamic>> _rowConfigs = [
    ...List.generate(
      6,
      (i) => {
        'name': '10月駅伝',
        'kukan': '${i + 1}区',
        'raceIdx': 0,
        'kukanIdx': i,
        'isLast': i == 5,
      },
    ),
    ...List.generate(
      8,
      (i) => {
        'name': '11月駅伝',
        'kukan': '${i + 1}区',
        'raceIdx': 1,
        'kukanIdx': i,
        'isLast': i == 7,
      },
    ),
    ...List.generate(
      10,
      (i) => {
        'name': '正月駅伝',
        'kukan': '${i + 1}区',
        'raceIdx': 2,
        'kukanIdx': i,
        'isLast': i == 9,
      },
    ),
    ...List.generate(
      10,
      (i) => {
        'name': 'カスタム',
        'kukan': '${i + 1}区',
        'raceIdx': 5,
        'kukanIdx': i,
        'isLast': i == 9,
      },
    ),
  ];

  final List<String> _colLabels = ['駅伝 / 区間', '3年前', '2年前', '前年度', '今年度'];

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  // --- CSV出力機能 ---
  Future<void> _exportAndShareCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      List<List<dynamic>> rows = [_colLabels];
      for (var config in _rowConfigs) {
        List<dynamic> row = ['${config['name']} ${config['kukan']}'];
        for (int i = 1; i < _colLabels.length; i++) {
          int timesAgo = 5 - i;
          final s = _findSenshuByHistory(
            config['raceIdx'],
            config['kukanIdx'],
            timesAgo,
          );
          if (s != null) {
            int targetGakunen = s.gakunen - (timesAgo - 1);
            int rankVal =
                s.kukanjuni_race[config['raceIdx']][targetGakunen - 1];
            double timeVal =
                s.kukantime_race[config['raceIdx']][targetGakunen - 1];
            String timeStr = (timeVal > 0 && timeVal < TEISUU.DEFAULTTIME)
                ? "${(timeVal / 60).floor()}:${(timeVal % 60).floor().toString().padLeft(2, '0')}"
                : "---";
            row.add("${s.name}($targetGakunen年) ${rankVal + 1}位 $timeStr");
          } else {
            row.add("---");
          }
        }
        rows.add(row);
      }
      String csvData = const ListToCsvConverter().convert(rows);
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      final List<int> csvBytes = utf8.encode(csvData);
      final Uint8List combinedBytes = Uint8List.fromList([...bom, ...csvBytes]);
      final directory = await getTemporaryDirectory();
      final File file = File(
        "${directory.path}/${_univName}_kukan_history.csv",
      );
      await file.writeAsBytes(combinedBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: '$_univName 駅伝区間別履歴'),
      );
    } catch (e) {
      debugPrint('CSV出力エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- 画像出力機能 ---
  Future<void> _showRaceSelectionForImage() async {
    final List<String> raceNames = ['10月駅伝', '11月駅伝', '正月駅伝', 'カスタム'];
    final String? selectedRace = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('出力する駅伝を選択'),
        children: raceNames
            .map(
              (name) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, name),
                child: Text(name, style: const TextStyle(color: Colors.black)),
              ),
            )
            .toList(),
      ),
    );
    if (selectedRace != null) {
      _shareSelectedRaceImage(selectedRace);
    }
  }

  Future<void> _shareSelectedRaceImage(String raceName) async {
    setState(() => _isExporting = true);
    final filteredConfigs = _rowConfigs
        .where((c) => c['name'] == raceName)
        .toList();

    // 1. 高さを自動計算する
    // 基本要素の高さ（タイトル、余白、ヘッダー、フッター）
    double totalHeight = 24 + 16 + 50 + 16 + 20 + 40;

    // 各行の高さを計算
    for (var config in filteredConfigs) {
      double rowMaxHeight = 120.0; // 最低高さ
      for (int i = 1; i < 5; i++) {
        int timesAgo = 5 - i;
        final s = _findSenshuByHistory(
          config['raceIdx'],
          config['kukanIdx'],
          timesAgo,
        );
        if (s != null && s.name.length > 8) {
          // 名前が長い場合に高さが増える分を加算（概算）
          rowMaxHeight = 140.0;
        }
      }
      totalHeight += rowMaxHeight;
    }

    Widget captureWidget = Container(
      width: 800,
      color: HENSUU.backgroundcolor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_univName $raceName 近年成績(在学中選手のみ)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {0: FixedColumnWidth(110)},
            defaultColumnWidth: const FixedColumnWidth(160),
            border: TableBorder.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
            children: [
              TableRow(
                children: _colLabels
                    .map(
                      (label) => Container(
                        height: 50,
                        alignment: Alignment.center,
                        color: Colors.indigo.withOpacity(0.6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...filteredConfigs.map((config) {
                final int rowIndex = filteredConfigs.indexOf(config) + 1;
                return TableRow(
                  children: [
                    _buildImageRowHeader(config),
                    ...List.generate(4, (i) {
                      int timesAgo = 4 - i;
                      final s = _findSenshuByHistory(
                        config['raceIdx'],
                        config['kukanIdx'],
                        timesAgo,
                      );
                      return _buildImageDataCell(s, config, timesAgo, rowIndex);
                    }),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '----- Generated by 箱庭小駅伝SS -----',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );

    try {
      final image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(child: captureWidget),
        ),
        // 計算した高さを指定し、少し余裕(pixelRatio)を持たせる
        targetSize: Size(800, totalHeight + 100),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/kukan_history_${raceName}.png');
      await file.writeAsBytes(image);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$_univName $raceName の区間別履歴です。 #箱庭小駅伝SS',
        ),
      );
    } catch (e) {
      debugPrint('画像共有エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Widget _buildImageRowHeader(Map<String, dynamic> config) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08)),
      child: Text(
        config['kukan'],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildImageDataCell(
    SenshuData? s,
    Map<String, dynamic> config,
    int timesAgo,
    int rowIdx,
  ) {
    if (s == null)
      return Container(constraints: const BoxConstraints(minHeight: 120));

    int targetGakunen = s.gakunen - (timesAgo - 1);
    int gradeIdx = targetGakunen - 1;
    int rankVal = s.kukanjuni_race[config['raceIdx']][gradeIdx];
    double timeVal = s.kukantime_race[config['raceIdx']][gradeIdx];
    int effectiveRank = (config['raceIdx'] == 2 && rankVal >= 100)
        ? rankVal - 100
        : rankVal;
    String rankStr = (config['raceIdx'] == 2 && rankVal >= 100)
        ? "${effectiveRank + 1}位相当"
        : "${rankVal + 1}位";
    String timeStr = (timeVal > 0 && timeVal < TEISUU.DEFAULTTIME)
        ? "${(timeVal / 60).floor()}'${(timeVal % 60).floor().toString().padLeft(2, '0')}\""
        : "---";

    Color cellBgColor = rowIdx.isEven
        ? Colors.white.withOpacity(0.04)
        : Colors.transparent;
    Color? borderColor;
    double borderWidth = 0.5;
    Color textColor = Colors.white;

    if (effectiveRank == 0) {
      borderColor = Colors.amberAccent;
      cellBgColor = Colors.amber.withOpacity(0.2);
      borderWidth = 2.5;
      textColor = const Color(0xFFFFE082);
    } else if (effectiveRank == 1) {
      borderColor = Colors.blueGrey.shade100;
      cellBgColor = Colors.blueGrey.withOpacity(0.15);
      borderWidth = 2.0;
      textColor = const Color(0xFFE0F2F1);
    } else if (effectiveRank == 2) {
      borderColor = Colors.orange.shade700;
      cellBgColor = Colors.orange.withOpacity(0.15);
      borderWidth = 2.0;
      textColor = const Color(0xFFFFE0B2);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: cellBgColor,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        borderRadius: borderColor != null ? BorderRadius.circular(6) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$targetGakunen年生',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rankStr,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  void _prepareData() {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
    if (currentGhensuu == null) return;
    //final int targetUnivId = currentGhensuu.hyojiunivnum;
    _univName = univBox.get(widget.targetUnivId)?.name ?? "";
    _allSenshu = senshuBox.values
        .where((s) => s.univid == widget.targetUnivId)
        .toList();
    _isInitialized = true;
  }

  SenshuData? _findSenshuByHistory(int raceIdx, int kukanIdx, int timesAgo) {
    for (var senshu in _allSenshu) {
      int targetGakunen = senshu.gakunen - (timesAgo - 1);
      if (targetGakunen < 1 || targetGakunen > 4) continue;
      if (senshu.entrykukan_race[raceIdx][targetGakunen - 1] == kukanIdx)
        return senshu;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Stack(
      children: [
        Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: Text(
              '$_univName 駅伝履歴(区間別)',
              style: const TextStyle(fontSize: 15),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _isExporting ? null : _showRaceSelectionForImage,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _isExporting ? null : _exportAndShareCsv,
              ),
            ],
          ),
          body: SafeArea(
            child: TableView.builder(
              pinnedColumnCount: 1,
              pinnedRowCount: 1,
              columnCount: _colLabels.length,
              rowCount: _rowConfigs.length + 1,
              columnBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 100 : 95),
              ),
              rowBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 45 : 120),
              ),
              cellBuilder: (context, vicinity) {
                if (vicinity.row == 0)
                  return _buildHeaderCell(_colLabels[vicinity.column]);
                final rowConfig = _rowConfigs[vicinity.row - 1];
                if (vicinity.column == 0) return _buildRowHeaderCell(rowConfig);
                int timesAgo = 5 - vicinity.column;
                final senshu = _findSenshuByHistory(
                  rowConfig['raceIdx'],
                  rowConfig['kukanIdx'],
                  timesAgo,
                );
                return _buildDataCell(
                  senshu,
                  rowConfig,
                  timesAgo,
                  vicinity.row,
                );
              },
            ),
          ),
        ),
        if (_isExporting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    '処理中...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  TableViewCell _buildHeaderCell(String label) {
    return TableViewCell(
      child: Container(
        color: Colors.indigo.withOpacity(0.6),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  TableViewCell _buildRowHeaderCell(Map<String, dynamic> config) {
    final bool isLast = config['isLast'];
    return TableViewCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          border: Border(
            right: const BorderSide(color: Colors.white54, width: 1),
            bottom: BorderSide(
              color: isLast ? Colors.white : Colors.white.withOpacity(0.1),
              width: isLast ? 2.0 : 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              config['name'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config['kukan'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableViewCell _buildDataCell(
    SenshuData? s,
    Map<String, dynamic> rowConfig,
    int timesAgo,
    int rowIdx,
  ) {
    final bool isLast = rowConfig['isLast'];
    if (s == null)
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.white : Colors.white.withOpacity(0.05),
                width: isLast ? 2.0 : 0.5,
              ),
              right: BorderSide(color: Colors.white.withOpacity(0.02)),
            ),
          ),
        ),
      );
    int targetGakunen = s.gakunen - (timesAgo - 1);
    int gradeIdx = targetGakunen - 1;
    int rankVal = s.kukanjuni_race[rowConfig['raceIdx']][gradeIdx];
    double timeVal = s.kukantime_race[rowConfig['raceIdx']][gradeIdx];
    int effectiveRank = (rowConfig['raceIdx'] == 2 && rankVal >= 100)
        ? rankVal - 100
        : rankVal;
    String rankStr = (rowConfig['raceIdx'] == 2 && rankVal >= 100)
        ? "${effectiveRank + 1}位相当"
        : "${rankVal + 1}位";
    Color cellBgColor = rowIdx.isEven
        ? Colors.white.withOpacity(0.04)
        : Colors.transparent;
    Color? borderColor;
    double borderWidth = 0.5;
    Color displayTextColor = Colors.white;
    if (effectiveRank == 0) {
      borderColor = Colors.amberAccent;
      cellBgColor = Colors.amber.withOpacity(0.15);
      borderWidth = 2.0;
      displayTextColor = const Color(0xFFFFE082);
    } else if (effectiveRank == 1) {
      borderColor = Colors.blueGrey.shade100;
      cellBgColor = Colors.blueGrey.withOpacity(0.12);
      borderWidth = 1.5;
      displayTextColor = const Color(0xFFE0F2F1);
    } else if (effectiveRank == 2) {
      borderColor = Colors.orange.shade700;
      cellBgColor = Colors.orange.withOpacity(0.1);
      borderWidth = 1.5;
      displayTextColor = const Color(0xFFFFE0B2);
    }
    String timeStr = (timeVal > 0 && timeVal < TEISUU.DEFAULTTIME)
        ? "${(timeVal / 60).floor()}'${(timeVal % 60).floor().toString().padLeft(2, '0')}\""
        : "---";
    return TableViewCell(
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellBgColor,
          border: borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : Border(
                  bottom: BorderSide(
                    color: isLast
                        ? Colors.white
                        : Colors.white.withOpacity(0.1),
                    width: isLast ? 2.0 : 0.5,
                  ),
                  right: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
          borderRadius: borderColor != null ? BorderRadius.circular(4) : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isJumpEnabled
                        ? () => _showSenshuDetail(context, s.id)
                        : null,
                    child: Text(
                      s.name,
                      style: TextStyle(
                        color: _isJumpEnabled
                            ? HENSUU.LinkColor
                            : displayTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: _isJumpEnabled
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$targetGakunen年生',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rankStr,
                    style: TextStyle(
                      color: displayTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSenshuDetail(BuildContext context, int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, __) =>
          ModalSenshuDetailView(senshuId: senshuId),
    );
  }
}
