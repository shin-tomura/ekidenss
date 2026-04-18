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

class ModalUnivSenshuMatrixView extends StatefulWidget {
  final int targetUnivId;
  const ModalUnivSenshuMatrixView({super.key, required this.targetUnivId});

  @override
  State<ModalUnivSenshuMatrixView> createState() =>
      _ModalUnivSenshuMatrixViewState();
}

class _ModalUnivSenshuMatrixViewState extends State<ModalUnivSenshuMatrixView> {
  final ScreenshotController _screenshotController = ScreenshotController();

  late List<SenshuData> _sortedSenshu;
  String _univName = "";
  bool _isInitialized = false;
  bool _isExporting = false;

  final List<String> _eventLabels = [
    '選手名',
    '駅伝男',
    '平常心',
    '対校5千',
    '対校1万',
    '対校ハーフ',
    '記録5千',
    '記録1万',
    '市民ハーフ',
    '登り10k',
    '下り10k',
    'ロード10k',
    'クロカン10k',
  ];

  final List<int> _raceIndices = [6, 7, 8, 10, 11, 12, 13, 14, 15, 16];
  final Map<int, Map<int, int>> _rankMap = {};

  final double _rowHeight = 75.0;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  // シリーズの境界線（右側）を引くべきカラムインデックスを定義
  bool _shouldHasSeriesBorder(int colIdx) {
    return colIdx == 2 || colIdx == 5 || colIdx == 8;
  }

  final Color _seriesBorderColor = Colors.white.withOpacity(0.5);
  final double _seriesBorderWidth = 2.0;

  // --- CSV出力機能 ---
  Future<void> _exportAndShareCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      List<dynamic> header = ['選手名', '駅伝男', '平常心'];
      for (int i = 3; i < _eventLabels.length; i++) {
        header.add('${_eventLabels[i]}(順位)');
        header.add(_eventLabels[i]);
      }

      List<List<dynamic>> rows = [header];

      for (var senshu in _sortedSenshu) {
        List<dynamic> row = [
          '${senshu.name}(${senshu.gakunen}年)',
          senshu.konjou,
          senshu.heijousin,
        ];
        for (int raceIdx in _raceIndices) {
          final double time =
              senshu.kukantime_race[raceIdx][senshu.gakunen - 1];
          final int? rank = _rankMap[raceIdx]?[senshu.id];
          if (time <= 0 || time >= TEISUU.DEFAULTTIME) {
            row.add("");
            row.add("---");
          } else {
            final int m = (time / 60).floor();
            final int s = (time % 60).floor();
            row.add(rank ?? "");
            row.add("$m:${s.toString().padLeft(2, '0')}");
          }
        }
        rows.add(row);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      final List<int> csvBytes = utf8.encode(csvData);
      final Uint8List combinedBytes = Uint8List.fromList([...bom, ...csvBytes]);
      final directory = await getTemporaryDirectory();
      final String path = "${directory.path}/${_univName}_records.csv";
      final File file = File(path);
      await file.writeAsBytes(combinedBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: '$_univName 選手記録データ',
          text: '$_univName の今季成績表(CSV)を共有します。',
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
  Future<void> _shareFullTableImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    Widget captureWidget = Container(
      color: HENSUU.backgroundcolor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_univName 今季成績一覧',
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
              color: Colors.white.withOpacity(0.3),
              width: 1.0,
            ),
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(50),
              2: FixedColumnWidth(50),
            },
            defaultColumnWidth: const FixedColumnWidth(80),
            children: [
              TableRow(
                children: _eventLabels.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String label = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(4),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: _shouldHasSeriesBorder(idx)
                          ? Border(
                              right: BorderSide(
                                color: _seriesBorderColor,
                                width: _seriesBorderWidth,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
              ..._sortedSenshu.map((senshu) {
                final int rowIndex = _sortedSenshu.indexOf(senshu) + 1;
                final Color rowBg = rowIndex.isEven
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.02);

                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minHeight: 65),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${senshu.name}\n(${senshu.gakunen}年)',
                        style: TextStyle(
                          color: HENSUU.LinkColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    _buildStatCellForImage(senshu.konjou, true, rowBg, 1),
                    _buildStatCellForImage(senshu.heijousin, false, rowBg, 2),
                    ..._raceIndices.asMap().entries.map((entry) {
                      int localIdx = entry.key;
                      int raceIdx = entry.value;
                      int totalColIdx = localIdx + 3; // レース開始列は3から

                      final double time =
                          senshu.kukantime_race[raceIdx][senshu.gakunen - 1];
                      final int? rank = _rankMap[raceIdx]?[senshu.id];

                      Color borderColor = Colors.transparent;
                      Color cellBgColor = rowBg;
                      Color textColor = HENSUU.textcolor;
                      double borderWidth = 1.0;

                      if (rank == 1) {
                        borderColor = Colors.amberAccent;
                        cellBgColor = Colors.amber.withOpacity(0.15);
                        textColor = Colors.amberAccent;
                        borderWidth = 2.0;
                      } else if (rank == 2) {
                        borderColor = const Color(0xFFE0F7FA);
                        cellBgColor = Colors.white.withOpacity(0.1);
                        textColor = const Color(0xFFB2EBF2);
                        borderWidth = 1.5;
                      } else if (rank == 3) {
                        borderColor = Colors.orange.shade800;
                        textColor = Colors.orange.shade200;
                        borderWidth = 1.0;
                      }

                      bool hasRankBorder = rank != null && rank <= 3;
                      bool hasSeriesBorder = _shouldHasSeriesBorder(
                        totalColIdx,
                      );

                      return Container(
                        constraints: const BoxConstraints(minHeight: 65),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: cellBgColor,
                          border: Border(
                            top: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            bottom: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            left: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            right: hasSeriesBorder
                                ? BorderSide(
                                    color: _seriesBorderColor,
                                    width: _seriesBorderWidth,
                                  )
                                : (hasRankBorder
                                      ? BorderSide(
                                          color: borderColor,
                                          width: borderWidth,
                                        )
                                      : BorderSide.none),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (time <= 0 || time >= TEISUU.DEFAULTTIME)
                              const Text(
                                "---",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  decoration: TextDecoration.none,
                                ),
                              )
                            else ...[
                              Text(
                                "${(time / 60).floor()}:${(time % 60).floor().toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: hasRankBorder
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                "${rank}位",
                                style: TextStyle(
                                  color: hasRankBorder
                                      ? borderColor
                                      : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ],
                        ),
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
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );

    try {
      const double targetWidth = 1050;
      final double targetHeight = (_sortedSenshu.length * 70.0) + 200.0;

      final Uint8List? image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              width: targetWidth,
              height: targetHeight,
              color: HENSUU.backgroundcolor,
              child: captureWidget,
            ),
          ),
        ),
        context: context,
        targetSize: Size(targetWidth, targetHeight),
        delay: const Duration(milliseconds: 300),
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final String path = '${directory.path}/full_table_image.png';
        final File file = File(path);
        await file.writeAsBytes(image);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: '$_univName の今季成績表を共有します！ #箱庭小駅伝SS',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('画像共有エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // 画像用のステータスセル構築ヘルパー
  Widget _buildStatCellForImage(
    int value,
    bool isKonjou,
    Color rowBg,
    int colIdx,
  ) {
    Color? bgColor = rowBg;
    Border? border;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    final Color baseColor = isKonjou
        ? Colors.pinkAccent
        : Colors.lightBlueAccent;
    final bool hasSeriesBorder = _shouldHasSeriesBorder(colIdx);

    if (value >= 90) {
      bgColor = baseColor.withOpacity(0.35);
      border = Border(
        top: BorderSide(color: baseColor, width: 3.0),
        left: BorderSide(color: baseColor, width: 3.0),
        bottom: BorderSide(color: baseColor, width: 3.0),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 3.0),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 80) {
      bgColor = baseColor.withOpacity(0.15);
      border = Border(
        top: BorderSide(color: baseColor, width: 1.5),
        left: BorderSide(color: baseColor, width: 1.5),
        bottom: BorderSide(color: baseColor, width: 1.5),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 1.5),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 70) {
      bgColor = baseColor.withOpacity(0.07);
      if (hasSeriesBorder) {
        border = Border(
          right: BorderSide(
            color: _seriesBorderColor,
            width: _seriesBorderWidth,
          ),
        );
      }
      textColor = baseColor.withOpacity(0.9);
      fontWeight = FontWeight.bold;
    } else if (hasSeriesBorder) {
      border = Border(
        right: BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 65),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, border: border),
      child: Text(
        "$value",
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: fontWeight,
          decoration: TextDecoration.none,
        ),
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

    _sortedSenshu = senshuBox.values
        .where((s) => s.univid == widget.targetUnivId)
        .toList();
    _sortedSenshu.sort((a, b) {
      int gradeComp = b.gakunen.compareTo(a.gakunen);
      return gradeComp != 0 ? gradeComp : a.id.compareTo(b.id);
    });

    for (int raceIdx in _raceIndices) {
      List<SenshuData> rankList = _sortedSenshu.where((s) {
        double t = s.kukantime_race[raceIdx][s.gakunen - 1];
        return t > 0 && t < TEISUU.DEFAULTTIME;
      }).toList();
      rankList.sort(
        (a, b) => a.kukantime_race[raceIdx][a.gakunen - 1].compareTo(
          b.kukantime_race[raceIdx][b.gakunen - 1],
        ),
      );
      _rankMap[raceIdx] = {};
      for (int i = 0; i < rankList.length; i++) {
        _rankMap[raceIdx]![rankList[i].id] = i + 1;
      }
    }
    _isInitialized = true;
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
              '$_univName 今季成績',
              style: const TextStyle(fontSize: 15),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _isExporting ? null : _shareFullTableImage,
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
              columnCount: _eventLabels.length,
              rowCount: _sortedSenshu.length + 1,
              columnBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(
                  index == 0 ? 100 : (index == 1 || index == 2 ? 60 : 90),
                ),
              ),
              rowBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 55 : _rowHeight),
              ),
              cellBuilder: (context, vicinity) {
                if (vicinity.row == 0)
                  return _buildHeaderCell(
                    _eventLabels[vicinity.column],
                    vicinity.column,
                  );
                final senshu = _sortedSenshu[vicinity.row - 1];

                if (vicinity.column == 0)
                  return _buildNameCell(senshu, vicinity.row);
                if (vicinity.column == 1)
                  return _buildStatCell(senshu.konjou, true, vicinity.row, 1);
                if (vicinity.column == 2)
                  return _buildStatCell(
                    senshu.heijousin,
                    false,
                    vicinity.row,
                    2,
                  );
                return _buildDataCell(
                  senshu,
                  _raceIndices[vicinity.column - 3],
                  vicinity.row,
                  vicinity.column,
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
                    'データを生成中...',
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

  TableViewCell _buildHeaderCell(String label, int colIdx) {
    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          color: colIdx == 0
              ? Colors.white24
              : (colIdx % 2 == 0
                    ? Colors.white12
                    : Colors.white.withOpacity(0.07)),
          border: _shouldHasSeriesBorder(colIdx)
              ? Border(
                  right: BorderSide(
                    color: _seriesBorderColor,
                    width: _seriesBorderWidth,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: AutoSizeText(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 8,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
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
                ? Colors.transparent
                : Colors.white.withOpacity(0.03),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: BorderSide(color: Colors.white.withOpacity(0.1)),
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

  // ステータスセル (シリーズ境界線対応)
  TableViewCell _buildStatCell(
    int value,
    bool isKonjou,
    int rowIdx,
    int colIdx,
  ) {
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    Color? bgColor = rowBg;
    Border? border;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    final Color baseColor = isKonjou
        ? Colors.pinkAccent
        : Colors.lightBlueAccent;
    final bool hasSeriesBorder = _shouldHasSeriesBorder(colIdx);

    if (value >= 90) {
      bgColor = baseColor.withOpacity(0.35);
      border = Border(
        top: BorderSide(color: baseColor, width: 3.0),
        left: BorderSide(color: baseColor, width: 3.0),
        bottom: BorderSide(color: baseColor, width: 3.0),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 3.0),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 80) {
      bgColor = baseColor.withOpacity(0.15);
      border = Border(
        top: BorderSide(color: baseColor, width: 1.5),
        left: BorderSide(color: baseColor, width: 1.5),
        bottom: BorderSide(color: baseColor, width: 1.5),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 1.5),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 70) {
      bgColor = baseColor.withOpacity(0.07);
      textColor = baseColor.withOpacity(0.9);
      fontWeight = FontWeight.bold;
      if (hasSeriesBorder) {
        border = Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          right: BorderSide(
            color: _seriesBorderColor,
            width: _seriesBorderWidth,
          ),
        );
      }
    }

    if (border == null) {
      border = Border(
        bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide.none,
      );
    }

    return TableViewCell(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgColor, border: border),
        child: Text(
          "$value",
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  TableViewCell _buildDataCell(
    SenshuData p,
    int raceIdx,
    int rowIdx,
    int colIdx,
  ) {
    final double time = p.kukantime_race[raceIdx][p.gakunen - 1];
    final int? rank = _rankMap[raceIdx]?[p.id];
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    final bool hasSeriesBorder = _shouldHasSeriesBorder(colIdx);

    if (time <= 0 || time >= TEISUU.DEFAULTTIME) {
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            color: rowBg,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: hasSeriesBorder
                  ? BorderSide(
                      color: _seriesBorderColor,
                      width: _seriesBorderWidth,
                    )
                  : BorderSide.none,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            "---",
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      );
    }

    final int m = (time / 60).floor();
    final int s = (time % 60).floor();
    final String timeStr = "$m'${s.toString().padLeft(2, '0')}\"";

    Color borderColor = Colors.transparent;
    Color cellBgColor = rowBg;
    Color textColor = HENSUU.textcolor;
    double borderWidth = 2.0;

    if (rank == 1) {
      borderColor = Colors.amberAccent;
      cellBgColor = Colors.amber.withOpacity(0.15);
      textColor = Colors.amberAccent;
      borderWidth = 3.0;
    } else if (rank == 2) {
      borderColor = const Color(0xFFE0F7FA);
      cellBgColor = Colors.white.withOpacity(0.1);
      textColor = const Color(0xFFB2EBF2);
      borderWidth = 2.5;
    } else if (rank == 3) {
      borderColor = Colors.orange.shade800;
      textColor = Colors.orange.shade200;
      borderWidth = 2.0;
    }

    bool hasRankBorder = rank != null && rank <= 3;

    return TableViewCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: cellBgColor,
          border: Border(
            top: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide.none,
            bottom: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide(color: Colors.white.withOpacity(0.05)),
            left: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide.none,
            right: hasSeriesBorder
                ? BorderSide(
                    color: _seriesBorderColor,
                    width: _seriesBorderWidth,
                  )
                : (hasRankBorder
                      ? BorderSide(color: borderColor, width: borderWidth)
                      : BorderSide.none),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AutoSizeText(
                  timeStr,
                  maxLines: 1,
                  minFontSize: 6,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: hasRankBorder
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: AutoSizeText(
                  "$rank位",
                  maxLines: 1,
                  minFontSize: 6,
                  style: TextStyle(
                    color: hasRankBorder ? borderColor : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
