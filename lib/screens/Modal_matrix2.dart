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

class ModalEkidenHistoryMatrixView extends StatefulWidget {
  final int targetUnivId;
  const ModalEkidenHistoryMatrixView({super.key, required this.targetUnivId});

  @override
  State<ModalEkidenHistoryMatrixView> createState() =>
      _ModalEkidenHistoryMatrixViewState();
}

class _ModalEkidenHistoryMatrixViewState
    extends State<ModalEkidenHistoryMatrixView> {
  final ScreenshotController _screenshotController = ScreenshotController();

  late List<SenshuData> _sortedSenshu;
  String _univName = "";
  bool _isInitialized = false;
  bool _isExporting = false;

  final List<int> _targetRaceIndices = [0, 1, 2, 3, 4, 5];
  final List<String> _raceNames = ['10月', '11月', '正月', '11予', '正予', 'ｶｽﾀﾑ'];
  final List<String> _headerLabels = ['選手名'];
  final List<Map<String, int>> _columnConfigs = [];

  final double _rowHeight = 90.0;

  @override
  void initState() {
    super.initState();
    _prepareHeaderConfigs();
    _prepareData();
  }

  void _prepareHeaderConfigs() {
    for (int i = 0; i < _targetRaceIndices.length; i++) {
      for (int grade = 1; grade <= 4; grade++) {
        _headerLabels.add('${_raceNames[i]}\n${grade}年生');
        _columnConfigs.add({
          'raceIdx': _targetRaceIndices[i],
          'gradeIdx': grade - 1,
          'raceGroup': i,
        });
      }
    }
  }

  void _prepareData() {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');

    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
    if (currentGhensuu == null) return;

    //final int targetUnivId = currentGhensuu.hyojiunivnum;
    _univName = univBox.get(widget.targetUnivId)?.name ?? "";

    _sortedSenshu = senshuBox.values
        .where((s) => s.univid == widget.targetUnivId)
        .toList();

    _sortedSenshu.sort((a, b) {
      int gradeComp = b.gakunen.compareTo(a.gakunen);
      return gradeComp != 0 ? gradeComp : a.id.compareTo(b.id);
    });

    _isInitialized = true;
  }

  // --- CSV出力機能 ---
  Future<void> _exportAndShareCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      List<dynamic> header = ['選手名'];
      for (int i = 1; i < _headerLabels.length; i++) {
        header.add(_headerLabels[i].replaceAll('\n', ' '));
      }

      List<List<dynamic>> rows = [header];

      for (var senshu in _sortedSenshu) {
        List<dynamic> row = ['${senshu.name}(${senshu.gakunen}年)'];
        for (var config in _columnConfigs) {
          final int rIdx = config['raceIdx']!;
          final int gIdx = config['gradeIdx']!;
          final int kukan = senshu.entrykukan_race[rIdx][gIdx];
          final int rank = senshu.kukanjuni_race[rIdx][gIdx];
          final double time = senshu.kukantime_race[rIdx][gIdx];

          if (kukan >= 0) {
            String timeStr = (time > 0 && time < TEISUU.DEFAULTTIME)
                ? "${(time / 60).floor()}:${(time % 60).floor().toString().padLeft(2, '0')}"
                : "---";
            row.add("${kukan + 1}区(${rank + 1}位) $timeStr");
          } else if (kukan <= -100) {
            row.add("補員");
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
      final File file = File("${directory.path}/${_univName}_history.csv");
      await file.writeAsBytes(combinedBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '$_univName 駅伝成績履歴',
          text: '$_univName の駅伝全成績表(CSV)を共有します。',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      debugPrint('CSV出力エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- 画像出力機能 ---
  Future<void> _showRaceSelectionForImage() async {
    final String? selectedRace = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('出力する駅伝を選択'),
        children: _raceNames
            .asMap()
            .entries
            .map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.value),
                child: Text(
                  entry.value,
                  style: const TextStyle(color: Colors.black),
                ),
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

    final int raceGroupIdx = _raceNames.indexOf(raceName);
    final filteredConfigs = _columnConfigs
        .where((c) => c['raceGroup'] == raceGroupIdx)
        .toList();
    final List<String> filteredHeaders = ['選手名', '1年生', '2年生', '3年生', '4年生'];

    double totalHeight = 130.0;
    for (var senshu in _sortedSenshu) {
      totalHeight += (senshu.name.length > 9) ? 100.0 : 85.0;
    }

    Widget captureWidget = Container(
      width: 750,
      color: HENSUU.backgroundcolor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_univName $raceName 成績推移',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
            columnWidths: const {0: FixedColumnWidth(130)},
            defaultColumnWidth: const FixedColumnWidth(140),
            children: [
              TableRow(
                children: filteredHeaders.asMap().entries.map((entry) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    color: entry.key == 0
                        ? Colors.white24
                        : Colors.indigo.withOpacity(0.4),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ..._sortedSenshu.map((senshu) {
                final int rowIndex = _sortedSenshu.indexOf(senshu) + 1;
                final Color rowBg = rowIndex.isEven
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent;

                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minHeight: 70),
                      alignment: Alignment.centerLeft,
                      color: rowBg,
                      child: Text(
                        '${senshu.name}\n(${senshu.gakunen}年)',
                        style: TextStyle(
                          color: HENSUU.LinkColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    ...filteredConfigs.map((config) {
                      return _buildHistoryCellForImage(
                        senshu,
                        config['raceIdx']!,
                        config['gradeIdx']!,
                        config['raceGroup']!,
                        rowBg,
                      );
                    }).toList(),
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
                fontSize: 12,
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
        targetSize: Size(750, totalHeight),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final File file = File(
        '${directory.path}/ekiden_${raceName}_history.png',
      );
      await file.writeAsBytes(image!);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$_univName $raceName の成績推移です。 #箱庭小駅伝SS',
        ),
      );
    } catch (e) {
      debugPrint('画像共有エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- 画像用履歴セルの装飾強化 ---
  Widget _buildHistoryCellForImage(
    SenshuData p,
    int raceIdx,
    int gradeIdx,
    int raceGroup,
    Color rowBaseColor,
  ) {
    final int kukanVal = p.entrykukan_race[raceIdx][gradeIdx];
    final int rankVal = p.kukanjuni_race[raceIdx][gradeIdx];
    final double timeVal = p.kukantime_race[raceIdx][gradeIdx];

    String topText = "";
    String bottomText = "";
    Color textColor = Colors.white;
    Color cellBgColor = rowBaseColor;
    BoxBorder? cellBorder;
    BorderRadius? borderRadius;

    if (kukanVal >= 0) {
      String rankStr = (raceIdx == 2 && rankVal >= 100)
          ? "${rankVal - 100 + 1}位相当"
          : "${rankVal + 1}位";
      topText = (raceIdx == 3)
          ? "${kukanVal + 1}組 $rankStr"
          : (raceIdx == 4)
          ? rankStr
          : "${kukanVal + 1}区 $rankStr";

      if (timeVal > 0 && timeVal < TEISUU.DEFAULTTIME) {
        final int m = (timeVal / 60).floor();
        final int s = (timeVal % 60).floor();
        bottomText = "$m'${s.toString().padLeft(2, '0')}\"";
      }

      int effectiveRank = (raceIdx == 2 && rankVal >= 100)
          ? rankVal - 100
          : rankVal;

      // 1位〜3位の装飾差別化
      if (effectiveRank == 0) {
        // 1位: 金
        cellBgColor = Colors.amber.withOpacity(0.3);
        textColor = Colors.amberAccent;
        cellBorder = Border.all(color: Colors.amberAccent, width: 3.0);
        borderRadius = BorderRadius.circular(4);
      } else if (effectiveRank == 1) {
        // 2位: 銀
        cellBgColor = Colors.blueGrey.withOpacity(0.3);
        textColor = const Color(0xFFE0F7FA);
        cellBorder = Border.all(color: const Color(0xFFB2EBF2), width: 2.5);
        borderRadius = BorderRadius.circular(4);
      } else if (effectiveRank == 2) {
        // 3位: 銅
        cellBgColor = Colors.orange.withOpacity(0.25);
        textColor = const Color(0xFFFFCC80);
        cellBorder = Border.all(color: Colors.orange.shade700, width: 2.0);
        borderRadius = BorderRadius.circular(4);
      }
    } else if (kukanVal <= -100) {
      topText = "補員";
      textColor = Colors.grey;
    } else {
      topText = "---";
    }

    return Container(
      margin: const EdgeInsets.all(2), // 枠線を見せるためのマージン
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: cellBgColor,
        border:
            cellBorder ??
            Border(
              right: BorderSide(color: Colors.white.withOpacity(0.1)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            topText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: (rankVal >= 0 && rankVal <= 2)
                  ? FontWeight.bold
                  : FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          if (bottomText.isNotEmpty)
            Text(
              bottomText,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: (rankVal >= 0 && rankVal <= 2)
                    ? FontWeight.bold
                    : FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
        ],
      ),
    );
  }

  // --- UIビルド部分 ---
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
              '$_univName 駅伝成績一覧',
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
              columnCount: _headerLabels.length,
              rowCount: _sortedSenshu.length + 1,
              columnBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 100 : 88),
              ),
              rowBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 55 : _rowHeight),
              ),
              cellBuilder: (context, vicinity) {
                if (vicinity.row == 0) return _buildHeaderCell(vicinity.column);
                final senshu = _sortedSenshu[vicinity.row - 1];
                if (vicinity.column == 0)
                  return _buildNameCell(senshu, vicinity.row);
                final config = _columnConfigs[vicinity.column - 1];
                return _buildHistoryCell(
                  senshu,
                  config['raceIdx']!,
                  config['gradeIdx']!,
                  config['raceGroup']!,
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

  TableViewCell _buildHeaderCell(int colIdx) {
    int raceGroup = colIdx == 0 ? -1 : _columnConfigs[colIdx - 1]['raceGroup']!;
    List<Color> groupColors = [
      Colors.blueGrey.withOpacity(0.3),
      Colors.indigo.withOpacity(0.3),
      Colors.deepPurple.withOpacity(0.3),
      Colors.brown.withOpacity(0.3),
      const Color.fromARGB(255, 84, 57, 5).withOpacity(0.3),
      Colors.teal.withOpacity(0.3),
    ];
    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          color: colIdx == 0
              ? Colors.white24
              : groupColors[raceGroup % groupColors.length],
          border: colIdx > 0 && colIdx % 4 == 0
              ? const Border(right: BorderSide(color: Colors.white, width: 2.0))
              : null,
        ),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: AutoSizeText(
          _headerLabels[colIdx],
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 8,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  TableViewCell _buildNameCell(SenshuData p, int rowIdx) {
    return TableViewCell(
      child: GestureDetector(
        onTap: () => _showSenshuDetail(context, p.id),
        child: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: rowIdx.isEven
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.15)),
              right: const BorderSide(color: Colors.white, width: 0.8),
            ),
          ),
          child: AutoSizeText(
            '${p.name}\n(${p.gakunen}年)',
            maxLines: 2,
            minFontSize: 8,
            style: TextStyle(
              color: HENSUU.LinkColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  TableViewCell _buildHistoryCell(
    SenshuData p,
    int raceIdx,
    int gradeIdx,
    int raceGroup,
    int rowIdx,
  ) {
    final int kukanVal = p.entrykukan_race[raceIdx][gradeIdx];
    final int rankVal = p.kukanjuni_race[raceIdx][gradeIdx];
    final double timeVal = p.kukantime_race[raceIdx][gradeIdx];
    String topText = "";
    String bottomText = "";
    Color? borderColor;
    double borderWidth = 0.5;
    Color textColor = Colors.white;
    Color rowBaseColor = rowIdx.isEven
        ? Colors.white.withOpacity(0.05)
        : Colors.transparent;
    final List<Color> groupTints = [
      Colors.transparent,
      Colors.blue.withOpacity(0.04),
      Colors.transparent,
      Colors.brown.withOpacity(0.04),
      Colors.orange.withOpacity(0.04),
      Colors.teal.withOpacity(0.04),
    ];
    Color cellBgColor = Color.alphaBlend(
      groupTints[raceGroup % groupTints.length],
      rowBaseColor,
    );
    bool isInvalidPeriod = gradeIdx >= p.gakunen;
    bool isVisible = false;

    if (kukanVal >= 0) {
      isVisible = true;
      String rankStr = (raceIdx == 2 && rankVal >= 100)
          ? "${rankVal - 100 + 1}位相当"
          : "${rankVal + 1}位";
      topText = (raceIdx == 3)
          ? "${kukanVal + 1}組 $rankStr"
          : (raceIdx == 4)
          ? rankStr
          : "${kukanVal + 1}区 $rankStr";
      if (timeVal > 0 && timeVal < TEISUU.DEFAULTTIME) {
        final int m = (timeVal / 60).floor();
        final int s = (timeVal % 60).floor();
        bottomText = "$m'${s.toString().padLeft(2, '0')}\"";
      } else {
        bottomText = "---";
      }

      int effectiveRank = (raceIdx == 2 && rankVal >= 100)
          ? rankVal - 100
          : rankVal;
      if (effectiveRank == 0) {
        borderColor = Colors.amberAccent;
        cellBgColor = Colors.amber.withOpacity(0.25);
        borderWidth = 2.5;
        textColor = Colors.amberAccent;
      } else if (effectiveRank == 1) {
        borderColor = const Color(0xFFE0F7FA);
        cellBgColor = Colors.white.withOpacity(0.18);
        borderWidth = 2.0;
        textColor = const Color(0xFFB2EBF2);
      } else if (effectiveRank == 2) {
        borderColor = Colors.orange.shade800;
        cellBgColor = Colors.orange.withOpacity(0.15);
        borderWidth = 2.0;
        textColor = const Color(0xFFFFCC80);
      }
    } else if (kukanVal <= -100) {
      isVisible = true;
      int changedFrom = (kukanVal.abs() - 100) + 1;
      String unit = (raceIdx == 3) ? "組" : "区";
      topText = (raceIdx == 4) ? "変更→補員" : "$changedFrom$unit→補員";
      textColor = Colors.grey.shade400;
    }
    if (isInvalidPeriod && !isVisible) {
      isVisible = true;
      topText = "---";
      bottomText = "---";
    }
    BorderSide rightSide = BorderSide(
      color: (gradeIdx == 3) ? Colors.white54 : Colors.white.withOpacity(0.08),
      width: (gradeIdx == 3) ? 1.5 : 0.5,
    );

    return TableViewCell(
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cellBgColor,
          border: borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.15)),
                  right: rightSide,
                ),
          borderRadius: borderColor != null ? BorderRadius.circular(4) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                topText,
                maxLines: 1,
                minFontSize: 6,
                style: TextStyle(
                  color: textColor,
                  fontSize: raceIdx == 2 && rankVal >= 100 ? 9 : 10,
                  fontWeight: (rankVal <= 2 && kukanVal >= 0)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (bottomText.isNotEmpty) ...[
                const SizedBox(height: 1),
                AutoSizeText(
                  bottomText,
                  maxLines: 1,
                  minFontSize: 8,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
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
