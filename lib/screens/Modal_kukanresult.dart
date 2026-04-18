import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:ekiden/ghensuu.dart';

import 'package:ekiden/constants.dart';

import 'package:ekiden/univ_data.dart';

import 'package:ekiden/senshu_data.dart';

import 'package:ekiden/kansuu/time_date.dart';

import 'package:ekiden/screens/Modal_senshu.dart';

import 'package:ekiden/kantoku_data.dart';

import 'package:screenshot/screenshot.dart';

import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

import 'package:flutter/services.dart';

// --------------------------------------------------

// ★ 追加: 表示モードを管理する列挙型 ★

// --------------------------------------------------

enum ViewMode { time, description, analysis }

class ModalKukanResultListView extends StatefulWidget {
  const ModalKukanResultListView({super.key});

  @override
  State<ModalKukanResultListView> createState() =>
      _ModalKukanResultListViewState();
}

class _ModalKukanResultListViewState extends State<ModalKukanResultListView> {
  int? _displayKukan;

  // ★ 変更: bool _showSetumei から列挙型に変更 ★

  ViewMode _viewMode = ViewMode.time;

  bool _isExporting = false;

  final ScreenshotController _screenshotController = ScreenshotController();

  // ★ 追加: 分析項目の名称リスト ★

  final List<String> _parameterNames = [
    '調子',

    'メンタル',

    '集団走(1区)',

    '基本走力',

    '登り',

    '下り',

    'アップダウン',

    '経験',

    'ロード適性',

    'ペース変動',

    '長距離粘り',

    'スパート力',
  ];

  // ★ 変更: 圧縮フラグから影響度（-7〜+7）を取り出すメソッド（4ビット版） ★

  int _getImpactScore(int compressedFlag, int type) {
    if (compressedFlag == 0) return 0; // データがない場合のフェイルセーフ

    // 4ビットずつシフト

    int shift = type * 4;

    // 0xF (2進数で1111) で4ビット分だけを切り取る

    int storedValue = (compressedFlag >> shift) & 0xF;

    // 0〜14 の値を -7〜+7 に戻して返す (2倍はしない)

    return storedValue - 7;
  }

  // 選手のリストを区間順位に基づいて並べ替える

  List<SenshuData> _sortSenshuListByKukanJuni(
    List<SenshuData> list,

    int raceBangou,
  ) {
    list.sort((a, b) {
      final int junibA =
          (a.gakunen > 0 && a.gakunen <= a.kukanjuni_race[raceBangou].length)
          ? a.kukanjuni_race[raceBangou][a.gakunen - 1]
          : TEISUU.DEFAULTJUNI;

      final int junibB =
          (b.gakunen > 0 && b.gakunen <= b.kukanjuni_race[raceBangou].length)
          ? b.kukanjuni_race[raceBangou][b.gakunen - 1]
          : TEISUU.DEFAULTJUNI;

      if (junibA == TEISUU.DEFAULTJUNI && junibB == TEISUU.DEFAULTJUNI)
        return 0;

      if (junibA == TEISUU.DEFAULTJUNI) return 1;

      if (junibB == TEISUU.DEFAULTJUNI) return -1;

      return junibA.compareTo(junibB);
    });

    return list;
  }

  // 区間を移動する処理

  Future<void> _changeKukan(Ghensuu currentGhensuu, int delta) async {
    if (_displayKukan == null) return;

    final int raceBangou = currentGhensuu.hyojiracebangou;

    final int maxKukan = currentGhensuu.kukansuu_taikaigoto[raceBangou];

    int newKukan = _displayKukan! + delta;

    if (newKukan < 0) {
      newKukan = maxKukan - 1;
    } else if (newKukan >= maxKukan) {
      newKukan = 0;
    }

    setState(() {
      _displayKukan = newKukan;
    });
  }

  // 画像出力機能

  Future<void> _exportAsImage(
    String title,

    List<SenshuData> filteredSenshu,

    Map<int, UnivData> univDataMap,

    int kukanBangou,

    int raceBangou,

    Ghensuu currentGhensuu,

    KantokuData kantoku,
  ) async {
    setState(() => _isExporting = true);

    try {
      final List<SenshuData> exportTarget = filteredSenshu.length > 50
          ? filteredSenshu.sublist(0, 50)
          : filteredSenshu;

      const int itemsPerColumn = 10;

      List<List<SenshuData>> chunks = [];

      for (var i = 0; i < exportTarget.length; i += itemsPerColumn) {
        chunks.add(
          exportTarget.sublist(
            i,

            i + itemsPerColumn > exportTarget.length
                ? exportTarget.length
                : i + itemsPerColumn,
          ),
        );
      }

      int count_kukansin = 0;

      for (var senshu in exportTarget) {
        if (senshu.chokuzentaikai_zentaikukansinflag == 1) {
          count_kukansin++;
        }
      }

      if (count_kukansin > 10) {
        count_kukansin = 10;
      }

      final double exportWidth = 60 + (chunks.length * 260.0);

      final double exportHeight =
          220.0 + (itemsPerColumn * 100.0) + (count_kukansin * 60);

      Widget captureContent = Container(
        padding: const EdgeInsets.all(28),

        color: HENSUU.backgroundcolor,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: const TextStyle(
                color: Colors.white,

                fontSize: 28,

                fontWeight: FontWeight.bold,

                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 10),

            Container(height: 3, color: Colors.white),

            const SizedBox(height: 28),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: chunks.map((chunk) {
                return Padding(
                  padding: const EdgeInsets.only(right: 35),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: chunk.map((senshu) {
                      final UnivData? univ = univDataMap[senshu.univid];

                      final int idx = senshu.gakunen - 1;

                      final int kukanJuni =
                          senshu.kukanjuni_race[raceBangou][idx] + 1;

                      final double kukanTime =
                          senshu.kukantime_race[raceBangou][idx];

                      final List<Widget> recordDiffWidgets =
                          _calculateAndFormatRecordDifference(
                            kukanTime,

                            kukanBangou,

                            kukanJuni - 1,

                            senshu.univid,

                            currentGhensuu,

                            kantoku,

                            senshu.chokuzentaikai_zentaikukansinflag,
                          );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 28),

                        child: SizedBox(
                          width: 225,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                '$kukanJuni位 ${senshu.name}',

                                style: const TextStyle(
                                  color: Colors.white,

                                  fontSize: 17,

                                  fontWeight: FontWeight.bold,

                                  decoration: TextDecoration.none,
                                ),

                                overflow: TextOverflow.ellipsis,
                              ),

                              Text(
                                '${univ?.name ?? '不明'} (${senshu.gakunen}年)',

                                style: const TextStyle(
                                  color: Colors.white,

                                  fontSize: 15,

                                  fontWeight: FontWeight.bold,

                                  decoration: TextDecoration.none,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'タイム: ${TimeDate.timeToFunByouString(kukanTime)}',

                                style: const TextStyle(
                                  color: Colors.yellowAccent,

                                  fontSize: 16,

                                  fontWeight: FontWeight.w900,

                                  decoration: TextDecoration.none,
                                ),
                              ),

                              ...recordDiffWidgets.map(
                                (w) => DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 12,

                                    color: Colors.white,

                                    decoration: TextDecoration.none,
                                  ),

                                  child: w,
                                ),
                              ),

                              if (raceBangou != 3 &&
                                  raceBangou != 4 &&
                                  senshu.chokuzentaikai_zentaikukansinflag == 1)
                                const Text(
                                  '*区間新',

                                  style: TextStyle(
                                    color: Colors.redAccent,

                                    fontSize: 12,

                                    fontWeight: FontWeight.bold,

                                    decoration: TextDecoration.none,
                                  ),
                                )
                              else if (raceBangou != 3 &&
                                  raceBangou != 4 &&
                                  senshu.chokuzentaikai_univkukansinflag == 1)
                                const Text(
                                  '*学内新',

                                  style: TextStyle(
                                    color: Colors.yellowAccent,

                                    fontSize: 12,

                                    fontWeight: FontWeight.bold,

                                    decoration: TextDecoration.none,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,

              child: Text(
                "----- Generated by 箱庭小駅伝SS -----",

                style: const TextStyle(
                  color: Colors.white38,

                  fontSize: 12,

                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      );

      final Uint8List? image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,

          child: Material(
            child: Container(
              width: exportWidth,

              height: exportHeight,

              color: HENSUU.backgroundcolor,

              child: captureContent,
            ),
          ),
        ),

        targetSize: Size(exportWidth, exportHeight),

        pixelRatio: 2.0,

        delay: const Duration(milliseconds: 500),
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();

        final String path =
            '${directory.path}/kukan_result_${DateTime.now().millisecondsSinceEpoch}.png';

        final File file = File(path);

        await file.writeAsBytes(image);

        await Share.shareXFiles([XFile(path)], text: '$title 個人成績 #箱庭小駅伝SS');
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');

    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),

      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null)
          return const Center(child: Text('データがありません'));

        if (_displayKukan == null) _displayKukan = 0;

        final int raceBangou = currentGhensuu.hyojiracebangou;

        final int kukanBangou = _displayKukan!;

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),

          builder: (context, univdataBox, _) {
            final Map<int, UnivData> univDataMap = {
              for (var univ in univdataBox.values) univ.id: univ,
            };

            return ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),

              builder: (context, senshudataBox, _) {
                final List<SenshuData> allSenshuData = senshudataBox.values
                    .toList();

                List<SenshuData> filteredSenshuData = allSenshuData.where((s) {
                  final UnivData? univ = univDataMap[s.univid];

                  if (univ == null) return false;

                  final bool isUnivEntry =
                      univ.taikaientryflag[raceBangou] == 1;

                  final bool isSenshuEntry =
                      s.gakunen > 0 &&
                      s.gakunen <= 4 &&
                      s.entrykukan_race.length > raceBangou &&
                      s.entrykukan_race[raceBangou].length > s.gakunen - 1 &&
                      s.entrykukan_race[raceBangou][s.gakunen - 1] ==
                          kukanBangou;

                  final bool hasKukanTime =
                      s.gakunen > 0 &&
                      s.gakunen <= 4 &&
                      s.kukantime_race.length > raceBangou &&
                      s.kukantime_race[raceBangou].length > s.gakunen - 1 &&
                      s.kukantime_race[raceBangou][s.gakunen - 1] <
                          TEISUU.DEFAULTTIME;

                  return isUnivEntry && isSenshuEntry && hasKukanTime;
                }).toList();

                filteredSenshuData = _sortSenshuListByKukanJuni(
                  filteredSenshuData,

                  raceBangou,
                );

                final bool isTopRunnerPresent = filteredSenshuData.isNotEmpty;

                final SenshuData? topRunner = isTopRunnerPresent
                    ? filteredSenshuData.first
                    : null;

                final int kukanKyoriRoundedM =
                    (currentGhensuu
                            .kyori_taikai_kukangoto[raceBangou][kukanBangou])
                        .round();

                String kukantext =
                    '第${kukanBangou + 1}区 ${kukanKyoriRoundedM}m';

                if (raceBangou == 3) kukantext = '第${kukanBangou + 1}組 10000m';

                if (raceBangou == 4)
                  kukantext = '正月駅伝予選 ${kukanKyoriRoundedM}m';

                return Stack(
                  children: [
                    Scaffold(
                      backgroundColor: HENSUU.backgroundcolor,

                      appBar: AppBar(
                        title: Text(
                          kukantext,

                          style: const TextStyle(color: Colors.white),
                        ),

                        backgroundColor: HENSUU.backgroundcolor,

                        foregroundColor: Colors.white,

                        actions: [
                          IconButton(
                            icon: const Icon(Icons.image),

                            // ★ 変更: 分析モード時は画像コピーボタンを無効化 ★
                            onPressed:
                                (_isExporting || _viewMode == ViewMode.analysis)
                                ? null
                                : () => _exportAsImage(
                                    kukantext,

                                    filteredSenshuData,

                                    univDataMap,

                                    kukanBangou,

                                    raceBangou,

                                    currentGhensuu,

                                    kantoku,
                                  ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.copy),

                            onPressed: () => _exportAsText(
                              kukantext,

                              filteredSenshuData,

                              univDataMap,

                              kukanBangou,

                              raceBangou,

                              currentGhensuu,

                              kantoku,
                            ),
                          ),
                        ],
                      ),

                      body: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,

                              horizontal: 16.0,
                            ),

                            // ★ 変更: ボタンを3つ（走破タイム/説明文/分析）に拡張 ★
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => setState(
                                      () => _viewMode = ViewMode.time,
                                    ),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _viewMode == ViewMode.time
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,

                                      foregroundColor: Colors.white,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),

                                    child: const Text(
                                      '走破タイム',

                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => setState(
                                      () => _viewMode = ViewMode.description,
                                    ),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _viewMode == ViewMode.description
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,

                                      foregroundColor: Colors.white,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),

                                    child: const Text(
                                      '説明文',

                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => setState(
                                      () => _viewMode = ViewMode.analysis,
                                    ),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _viewMode == ViewMode.analysis
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,

                                      foregroundColor: Colors.white,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),

                                    child: const Text(
                                      '分析',

                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(color: Colors.grey),

                          Expanded(
                            child: filteredSenshuData.isEmpty
                                ? Center(
                                    child: Text(
                                      '結果が記録された選手はいません',

                                      style: TextStyle(color: HENSUU.textcolor),
                                    ),
                                  )
                                : ListView.builder(
                                    // ★変更: 分析モードの時は要素数を1つ増やす（一番下に説明文を入れるため）
                                    itemCount:
                                        filteredSenshuData.length +
                                        (_viewMode == ViewMode.analysis
                                            ? 1
                                            : 0),

                                    itemBuilder: (context, index) {
                                      // ★追加: リストの最後尾に到達したら説明文を表示する

                                      if (_viewMode == ViewMode.analysis &&
                                          index == filteredSenshuData.length) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,

                                            vertical: 24.0,
                                          ),

                                          child: Text(
                                            '【分析データの見方】\nマイナスの数値（緑）は平均よりタイムを短縮させた好影響を、プラスの数値（赤）はタイムを悪化させた悪影響を表しています。',

                                            style: TextStyle(
                                              color: Colors.white70,

                                              fontSize:
                                                  HENSUU.fontsize_honbun * 0.8,
                                            ),
                                          ),
                                        );
                                      }

                                      final SenshuData senshu =
                                          filteredSenshuData[index];

                                      final UnivData? univ =
                                          univDataMap[senshu.univid];

                                      final int gIdx = senshu.gakunen - 1;

                                      final int kjZero =
                                          (senshu.gakunen > 0 &&
                                              gIdx <
                                                  senshu
                                                      .kukanjuni_race[raceBangou]
                                                      .length)
                                          ? senshu
                                                .kukanjuni_race[raceBangou][gIdx]
                                          : TEISUU.DEFAULTJUNI;

                                      final int kukanJuni =
                                          kjZero == TEISUU.DEFAULTJUNI
                                          ? TEISUU.DEFAULTJUNI
                                          : kjZero + 1;

                                      final double kukanTime =
                                          (senshu.gakunen > 0 &&
                                              gIdx <
                                                  senshu
                                                      .kukantime_race[raceBangou]
                                                      .length)
                                          ? senshu
                                                .kukantime_race[raceBangou][gIdx]
                                          : TEISUU.DEFAULTTIME;

                                      final String junistr =
                                          kukanJuni == TEISUU.DEFAULTJUNI
                                          ? '---'
                                          : '$kukanJuni位';

                                      final bool isThisTopRunner =
                                          isTopRunnerPresent &&
                                          senshu.id == topRunner!.id;

                                      final List<Widget> recordDiffWidgets =
                                          _calculateAndFormatRecordDifference(
                                            kukanTime,

                                            kukanBangou,

                                            isThisTopRunner
                                                ? 0
                                                : TEISUU.DEFAULTJUNI,

                                            senshu.univid,

                                            currentGhensuu,

                                            kantoku,

                                            senshu
                                                .chokuzentaikai_zentaikukansinflag,
                                          );

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,

                                          horizontal: 16.0,
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,

                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '$junistr ${senshu.name}\n (${senshu.gakunen}年 / ${univ?.name ?? '不明'})',

                                                    style: TextStyle(
                                                      color: HENSUU.textcolor,

                                                      fontSize:
                                                          HENSUU
                                                              .fontsize_honbun +
                                                          2,

                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),

                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                TextButton(
                                                  onPressed: () {
                                                    showGeneralDialog(
                                                      context: context,

                                                      barrierColor: Colors.black
                                                          .withOpacity(0.8),

                                                      barrierDismissible: true,

                                                      barrierLabel: '詳細',

                                                      pageBuilder:
                                                          (context, _, __) =>
                                                              ModalSenshuDetailView(
                                                                senshuId:
                                                                    senshu.id,
                                                              ),
                                                    );
                                                  },

                                                  child: Text(
                                                    '詳細',

                                                    style: TextStyle(
                                                      color: HENSUU.LinkColor,

                                                      fontSize: HENSUU
                                                          .fontsize_honbun,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16.0,
                                              ),

                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  _buildKukanTimeRow(
                                                    kukanTime,

                                                    recordDiffWidgets,
                                                  ),

                                                  if (raceBangou != 3 &&
                                                      raceBangou != 4 &&
                                                      senshu.chokuzentaikai_zentaikukansinflag ==
                                                          1)
                                                    _buildShinKirokuRow(
                                                      '*区間新',

                                                      Colors.redAccent,
                                                    )
                                                  else if (raceBangou != 3 &&
                                                      raceBangou != 4 &&
                                                      senshu.chokuzentaikai_univkukansinflag ==
                                                          1)
                                                    _buildShinKirokuRow(
                                                      '*学内新',

                                                      Colors.yellowAccent,
                                                    ),

                                                  // ★ 変更: モード別の表示切り替え ★
                                                  if (_viewMode ==
                                                      ViewMode.description) ...[
                                                    const SizedBox(height: 8),

                                                    Text(
                                                      senshu
                                                              .string_racesetumei
                                                              .isEmpty
                                                          ? '説明文はありません'
                                                          : senshu
                                                                .string_racesetumei,

                                                      style: TextStyle(
                                                        color: HENSUU.textcolor
                                                            .withOpacity(0.9),

                                                        fontSize:
                                                            HENSUU
                                                                .fontsize_honbun *
                                                            1.1,
                                                      ),
                                                    ),
                                                  ] else if (_viewMode ==
                                                      ViewMode.analysis) ...[
                                                    const SizedBox(height: 12),

                                                    _buildAnalysisGraph(
                                                      senshu
                                                          .racechuukakuseiflag,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            const Divider(
                                              color: Colors.white12,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          if (raceBangou != 4)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom,
                              ),

                              child: _buildKukanNavigation(currentGhensuu),
                            ),
                        ],
                      ),
                    ),

                    if (_isExporting)
                      Container(
                        color: Colors.black54,

                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ★ 変更: 分析用のグラフを描画するウィジェット ★

  Widget _buildAnalysisGraph(int compressedFlag) {
    if (compressedFlag == 0) {
      return Text(
        '分析データがありません',

        style: TextStyle(color: Colors.grey, fontSize: HENSUU.fontsize_honbun),
      );
    }

    return Column(
      children: List.generate(12, (index) {
        int score = _getImpactScore(compressedFlag, index);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),

          child: Row(
            children: [
              // 項目名
              SizedBox(
                width: 85,

                child: Text(
                  _parameterNames[index],

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: HENSUU.fontsize_honbun * 0.65,
                  ),

                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // グラフ描画エリア
              Expanded(
                child: Row(
                  children: [
                    // マイナス側 (左に伸びる緑のバー = タイム短縮・好影響)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,

                        child: score < 0
                            ? FractionallySizedBox(
                                // ★変更: スケールが-7〜+7になったので、分母を 7.0 にする
                                widthFactor: (score.abs() / 7.0).clamp(
                                  0.0,

                                  1.0,
                                ),

                                child: Container(
                                  height: 6,

                                  color: Colors.greenAccent,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),

                    // センターライン
                    Container(width: 2, height: 14, color: Colors.white38),

                    // プラス側 (右に伸びる赤のバー = タイム悪化・悪影響)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,

                        child: score > 0
                            ? FractionallySizedBox(
                                // ★変更: スケールが-7〜+7になったので、分母を 7.0 にする
                                widthFactor: (score / 7.0).clamp(0.0, 1.0),

                                child: Container(
                                  height: 6,

                                  color: Colors.redAccent,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),

              // スコア数値表示
              SizedBox(
                width: 40,

                child: Text(
                  score > 0 ? '+$score' : '$score',

                  textAlign: TextAlign.right,

                  style: TextStyle(
                    color: score < 0
                        ? Colors.greenAccent
                        : (score > 0 ? Colors.redAccent : Colors.white70),

                    fontSize: HENSUU.fontsize_honbun * 0.8,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _calculateAndFormatRecordDifference(
    double kukanTime,

    int kukanBangou,

    int kukanJuni,

    int univId,

    Ghensuu currentGhensuu,

    KantokuData kantoku,

    int kukansinflag,
  ) {
    if (kukanTime >= TEISUU.DEFAULTTIME) return [];

    final List<Widget> diffWidgets = [];

    final bool isTopRunner = kukanJuni == 0;

    final bool isMyUniv = univId == currentGhensuu.MYunivid;

    if ((kukansinflag == 1 || isTopRunner) && kukanBangou < 10) {
      final int zenntaiKukanRecordInt = kantoku.yobiint4[kukanBangou];

      final double zenntaiKukanRecord = zenntaiKukanRecordInt.toDouble();

      if (zenntaiKukanRecord != 0 && zenntaiKukanRecord != TEISUU.DEFAULTTIME) {
        final double diffTime = kukanTime - zenntaiKukanRecord;

        diffWidgets.add(
          Text(
            '区間記録比: ${_formatTimeDifference(diffTime)}',

            style: TextStyle(
              color: diffTime < 0 ? Colors.greenAccent : Colors.redAccent,

              fontSize: HENSUU.fontsize_honbun * 0.9,

              fontWeight: FontWeight.bold,

              decoration: TextDecoration.none,
            ),
          ),
        );
      }
    }

    if (isMyUniv && kukanBangou + 10 < 20) {
      final int gakunaiKukanRecordInt = kantoku.yobiint4[kukanBangou + 10];

      final double gakunaiKukanRecord = gakunaiKukanRecordInt.toDouble();

      if (gakunaiKukanRecord != 0 && gakunaiKukanRecord != TEISUU.DEFAULTTIME) {
        final double diffTime = kukanTime - gakunaiKukanRecord;

        diffWidgets.add(
          Text(
            '学内記録比: ${_formatTimeDifference(diffTime)}',

            style: TextStyle(
              color: diffTime < 0 ? Colors.greenAccent : Colors.redAccent,

              fontSize: HENSUU.fontsize_honbun * 0.9,

              fontWeight: FontWeight.bold,

              decoration: TextDecoration.none,
            ),
          ),
        );
      }
    }

    return diffWidgets;
  }

  String _formatTimeDifference(double diffTime) {
    final bool isNegative = diffTime < 0;

    final int totalSeconds = diffTime.abs().round();

    final int minutes = (totalSeconds / 60).floor();

    final int seconds = totalSeconds % 60;

    final String sign = isNegative ? '-' : '+';

    return totalSeconds < 60
        ? '$sign${seconds}秒'
        : '$sign${minutes}分${seconds}秒';
  }

  Widget _buildShinKirokuRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),

      child: Text(
        label,

        style: TextStyle(
          color: color,

          fontSize: HENSUU.fontsize_honbun,

          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKukanTimeRow(double time, List<Widget> recordDiffWidgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            SizedBox(
              width: 100,

              child: Text(
                '走破タイム:',

                style: TextStyle(
                  color: HENSUU.textcolor.withOpacity(0.7),

                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),

            Text(
              TimeDate.timeToFunByouString(time),

              style: TextStyle(
                color: time < TEISUU.DEFAULTTIME
                    ? Colors.yellowAccent
                    : HENSUU.textcolor.withOpacity(0.7),

                fontSize: HENSUU.fontsize_honbun * 1.2,

                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        ...recordDiffWidgets.map(
          (widget) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),

            child: widget,
          ),
        ),
      ],
    );
  }

  Widget _buildKukanNavigation(Ghensuu currentGhensuu) {
    return Container(
      padding: const EdgeInsets.all(12.0),

      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,

        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 1.0),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changeKukan(currentGhensuu, -1),

              icon: const Icon(Icons.arrow_back),

              label: const Text('前'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,

                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changeKukan(currentGhensuu, 1),

              icon: const Text('次'),

              label: const Icon(Icons.arrow_forward),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,

                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeDifference_copy(double diffTime) {
    final int totalSeconds = diffTime.abs().round();

    final int minutes = (totalSeconds / 60).floor();

    final int seconds = totalSeconds % 60;

    return totalSeconds < 60 ? '${seconds}秒' : '${minutes}分${seconds}秒';
  }

  // テキスト出力・共有機能

  Future<void> _exportAsText(
    String title,

    List<SenshuData> filteredSenshu,

    Map<int, UnivData> univDataMap,

    int kukanBangou,

    int raceBangou,

    Ghensuu currentGhensuu,

    KantokuData kantoku,
  ) async {
    String shareText = "";

    // ★ここから追加: 生成AI等へのコピペ用補足説明★

    if (_viewMode == ViewMode.analysis) {
      shareText +=
          '※分析データの補足：各項目が走破タイムに与えた影響度を相対値で示しています。マイナスの数値は平均よりタイムを短縮させた好影響、プラスの数値はタイムを悪化させた悪影響を表します。\n';
    }
    shareText +=
        '※区間記録比や学内記録比のタイムがプラスの場合は新記録に届かなかったことを表し、マイナスの場合には新記録を表します。ただし、速報値なので誤差がありますことをご了承ください\n';
    shareText +=
        '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n';
    // ★ここまで追加★
    shareText += '【$title 個人成績】\n';
    for (var senshu in filteredSenshu) {
      final UnivData? univ = univDataMap[senshu.univid];

      final int idx = senshu.gakunen - 1;

      final int kukanJuni = senshu.kukanjuni_race[raceBangou][idx] + 1;

      final double kukanTime = senshu.kukantime_race[raceBangou][idx];

      shareText +=
          '$kukanJuni位 ${TimeDate.timeToFunByouString(kukanTime)} '
          '${senshu.name}(${senshu.gakunen}年) ${univ?.name ?? '不明'}';

      if (raceBangou != 3 && raceBangou != 4) {
        if (senshu.chokuzentaikai_zentaikukansinflag == 1) {
          shareText += ' ★区間新';
        } else if (senshu.chokuzentaikai_univkukansinflag == 1) {
          shareText += ' ☆学内新';
        }
      }

      final bool isTopRunner = (kukanJuni == 1);

      final bool isMyUniv = senshu.univid == currentGhensuu.MYunivid;

      if ((senshu.chokuzentaikai_zentaikukansinflag == 1 || isTopRunner) &&
          kukanBangou < 10) {
        final double zenntaiKukanRecord = kantoku.yobiint4[kukanBangou]
            .toDouble();

        if (zenntaiKukanRecord != 0 &&
            zenntaiKukanRecord != TEISUU.DEFAULTTIME) {
          final double diffTime = kukanTime - zenntaiKukanRecord;

          if (diffTime < 0) {
            shareText +=
                ' [区間記録比:${_formatTimeDifference(diffTime)}(速報値では区間記録を${_formatTimeDifference_copy(diffTime.abs())}更新)]';
          } else {
            shareText +=
                ' [区間記録比:${_formatTimeDifference(diffTime)}(速報値では区間記録には${_formatTimeDifference_copy(diffTime.abs())}及ばず)]';
          }
        }
      }

      if (isMyUniv && kukanBangou + 10 < 20) {
        final double gakunaiKukanRecord = kantoku.yobiint4[kukanBangou + 10]
            .toDouble();

        if (gakunaiKukanRecord != 0 &&
            gakunaiKukanRecord != TEISUU.DEFAULTTIME) {
          final double diffTime = kukanTime - gakunaiKukanRecord;

          if (diffTime < 0) {
            shareText +=
                ' [学内記録比:${_formatTimeDifference(diffTime)}(速報値では学内記録を${_formatTimeDifference_copy(diffTime.abs())}更新)]';
          } else {
            shareText +=
                ' [学内記録比:${_formatTimeDifference(diffTime)}(速報値では学内記録には${_formatTimeDifference_copy(diffTime.abs())}及ばず)]';
          }
        }
      }

      // ★ 変更: モードに応じて出力するテキストを切り替え ★

      if (_viewMode == ViewMode.description) {
        final String setumei = senshu.string_racesetumei.isEmpty
            ? '(説明文なし)'
            : senshu.string_racesetumei;

        shareText += '\n $setumei\n';
      } else if (_viewMode == ViewMode.analysis) {
        if (senshu.racechuukakuseiflag == 0) {
          shareText += '\n [分析] データなし\n';
        } else {
          shareText += '\n [分析] ';

          for (int i = 0; i < 12; i++) {
            int score = _getImpactScore(senshu.racechuukakuseiflag, i);

            String sign = score > 0 ? '+' : '';

            shareText += '${_parameterNames[i]}:$sign$score ';
          }

          shareText += '\n';
        }
      } else {
        shareText += '\n'; // 通常タイムのみの場合
      }
    }

    shareText += '\n#箱庭小駅伝SS';

    await Clipboard.setData(ClipboardData(text: shareText));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('個人成績をコピーしました')));
    }
  }
}
