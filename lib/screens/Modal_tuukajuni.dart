import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kantoku_data.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
//import 'dart:typed_data';
import 'package:flutter/services.dart';

class ModalKukanResultListViewPass extends StatefulWidget {
  const ModalKukanResultListViewPass({super.key});

  @override
  State<ModalKukanResultListViewPass> createState() =>
      _ModalKukanResultListViewPassState();
}

class _ModalKukanResultListViewPassState
    extends State<ModalKukanResultListViewPass> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;
  int? _displayKukan;

  List<UnivData> _sortUnivListByTsuukaJuni(
    List<UnivData> list,
    int raceBangou,
    int kukanBangou,
  ) {
    list.sort((a, b) {
      final bool isAValid = a.tuukajuni_taikai.length > kukanBangou;
      final bool isBValid = b.tuukajuni_taikai.length > kukanBangou;
      final int junibA = isAValid
          ? a.tuukajuni_taikai[kukanBangou]
          : TEISUU.DEFAULTJUNI;
      final int junibB = isBValid
          ? b.tuukajuni_taikai[kukanBangou]
          : TEISUU.DEFAULTJUNI;
      if (junibA == TEISUU.DEFAULTJUNI && junibB == TEISUU.DEFAULTJUNI)
        return 0;
      if (junibA == TEISUU.DEFAULTJUNI) return 1;
      if (junibB == TEISUU.DEFAULTJUNI) return -1;
      return junibA.compareTo(junibB);
    });
    return list;
  }

  Future<void> _changeKukan(Ghensuu currentGhensuu, int delta) async {
    if (_displayKukan == null) return;
    final int maxDisplayKukanIndex = currentGhensuu.nowracecalckukan > 0
        ? currentGhensuu.nowracecalckukan - 1
        : 0;
    if (maxDisplayKukanIndex == 0 && currentGhensuu.nowracecalckukan == 0)
      return;
    int newKukan = _displayKukan! + delta;
    if (newKukan < 0) {
      newKukan = maxDisplayKukanIndex;
    } else if (newKukan > maxDisplayKukanIndex) {
      newKukan = 0;
    }
    setState(() => _displayKukan = newKukan);
  }

  Future<void> _exportAsImage(
    String title,
    List<UnivData> filteredData,
    int kukanBangou,
    int raceBangou,
    int lastKukanIndex,
    Ghensuu currentGhensuu,
    KantokuData kantoku,
    double topTimeTotal,
    bool isTopTimeValid,
    bool isEkidenRace,
  ) async {
    setState(() => _isExporting = true);
    try {
      // --- 1. データの分割（10校ずつ） ---
      const int itemsPerColumn = 10;
      List<List<UnivData>> chunks = [];
      for (var i = 0; i < filteredData.length; i += itemsPerColumn) {
        chunks.add(
          filteredData.sublist(
            i,
            i + itemsPerColumn > filteredData.length
                ? filteredData.length
                : i + itemsPerColumn,
          ),
        );
      }
      int count_taikaisin = 0;
      if (kukanBangou == lastKukanIndex) {
        for (var univ in filteredData) {
          if (univ.chokuzentaikai_zentaitaikaisinflag == 1) {
            count_taikaisin++;
          }
        }
      }

      // --- 2. レイアウト計算 ---
      // 列数に応じて幅を動的に変更（1列あたり約230px）
      double exportWidth = 50 + (chunks.length * 230.0);
      // 高さは10校分（115px × 10校 + ヘッダー・フッター分）で余裕を持って固定
      double calculatedHeight =
          220.0 + (itemsPerColumn * 85.0) + (count_taikaisin * 55);

      // --- 3. ウィジェット構築 ---
      Widget captureContent = Container(
        padding: const EdgeInsets.all(24),
        color: HENSUU.backgroundcolor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 2, color: Colors.white),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: chunks.map((chunk) {
                return Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chunk.map((univ) {
                      final int tsuukaJuni = univ.tuukajuni_taikai[kukanBangou];
                      final double tsuukaTimeTotal =
                          univ.time_taikai_total[kukanBangou];
                      final String junistr = tsuukaJuni == TEISUU.DEFAULTJUNI
                          ? '---'
                          : '${tsuukaJuni + 1}位';

                      final int rankDiff = _calculateRankDifference(
                        univ,
                        kukanBangou,
                      );
                      final Map<String, dynamic> rankDiffData =
                          _getRankDifferenceText(rankDiff);

                      String timeDifferenceStr = '';
                      if (tsuukaJuni != 0 &&
                          isTopTimeValid &&
                          tsuukaTimeTotal != TEISUU.DEFAULTTIME) {
                        final double diff = tsuukaTimeTotal - topTimeTotal;
                        if (diff > 0)
                          timeDifferenceStr = _formatTimeDifference(diff);
                      }

                      List<Widget> raceRecordDiffWidgets = isEkidenRace
                          ? _calculateAndFormatRaceRecordDifference(
                              tsuukaTimeTotal,
                              univ.id,
                              tsuukaJuni == 0,
                              raceBangou,
                              kukanBangou,
                              lastKukanIndex,
                              currentGhensuu,
                              kantoku,
                            )
                          : [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$junistr ${univ.name}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    TimeDate.timeToJikanFunByouString(
                                      tsuukaTimeTotal,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (kukanBangou > 0 &&
                                      tsuukaJuni != TEISUU.DEFAULTJUNI)
                                    Text(
                                      rankDiffData['text'],
                                      style: TextStyle(
                                        color: rankDiffData['color'] as Color,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                ],
                              ),
                              if (timeDifferenceStr.isNotEmpty)
                                Text(
                                  '1位差:$timeDifferenceStr',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ...raceRecordDiffWidgets.map(
                                (w) => DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                  child: w,
                                ),
                              ),
                              if (kukanBangou == lastKukanIndex &&
                                  (raceBangou <= 2 || raceBangou == 5)) ...[
                                if (univ.chokuzentaikai_zentaitaikaisinflag ==
                                    1)
                                  const Text(
                                    ' ※大会新',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                if (univ.chokuzentaikai_zentaitaikaisinflag ==
                                        0 &&
                                    univ.chokuzentaikai_univtaikaisinflag ==
                                        1 &&
                                    univ.id == currentGhensuu.MYunivid)
                                  const Text(
                                    ' ※学内新',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: const Text(
                "----- Generated by 箱庭小駅伝SS -----",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      );

      // --- 4. キャプチャ実行（ここが修正の肝です） ---
      final Uint8List? image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              width: exportWidth,
              height: calculatedHeight, // ここで指定した高さが適用されます
              color: HENSUU.backgroundcolor,
              child: captureContent,
            ),
          ),
        ),
        targetSize: Size(exportWidth, calculatedHeight),
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 500),
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final String imagePath =
            '${directory.path}/result_${DateTime.now().millisecondsSinceEpoch}.png';
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await SharePlus.instance.share(
          ShareParams(
            text: '$title 駅伝通過順位リザルト #箱庭小駅伝SS',
            files: <XFile>[XFile(imagePath)],
          ),
        );
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
  // --- ロジック部分は変更なし ---

  String _formatTimeDifference(double diffTime) {
    if (diffTime < 0) return '';
    final int totalSeconds = diffTime.round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return minutes >= 1 ? '+$minutes分$seconds秒' : '+$seconds秒';
  }

  String _formatTimeDifferenceForRecordDiff(double diffTime) {
    final bool isNegative = diffTime < 0;
    final double absTime = diffTime.abs();
    final int totalSeconds = absTime.round();
    final int minutes = (totalSeconds / 60).floor();
    final int seconds = totalSeconds % 60;
    final String sign = isNegative ? '-' : '+';
    return absTime < 60 ? '$sign${seconds}秒' : '$sign${minutes}分${seconds}秒';
  }

  String _formatTimeDifferenceForRecordDiff_copy(double diffTime) {
    //final bool isNegative = diffTime < 0;
    final double absTime = diffTime.abs();
    final int totalSeconds = absTime.round();
    final int minutes = (totalSeconds / 60).floor();
    final int seconds = totalSeconds % 60;
    //final String sign = isNegative ? '-' : '+';
    return absTime < 60 ? '${seconds}秒' : '${minutes}分${seconds}秒';
  }

  List<Widget> _calculateAndFormatRaceRecordDifference(
    double totalTime,
    int univId,
    bool isTopRunner,
    int raceBangou,
    int kukanBangou,
    int lastKukanIndex,
    Ghensuu currentGhensuu,
    KantokuData kantoku,
  ) {
    if (totalTime >= TEISUU.DEFAULTTIME) return [];
    final List<Widget> diffWidgets = [];
    final bool isMyUniv = univId == currentGhensuu.MYunivid;
    final bool isLastKukan = kukanBangou == lastKukanIndex;
    final univDataBox = Hive.box<UnivData>('univBox');
    final univ = univDataBox.get(univId);

    if (isTopRunner ||
        (isLastKukan && univ?.chokuzentaikai_zentaitaikaisinflag == 1)) {
      final int recInt = isLastKukan
          ? kantoku.yobiint4[20]
          : kantoku.yobiint3[kukanBangou];
      if (recInt != 0 && recInt != TEISUU.DEFAULTTIME) {
        final double diff = totalTime - recInt.toDouble();
        diffWidgets.add(
          Text(
            '大会記録比: ${_formatTimeDifferenceForRecordDiff(diff)}',
            style: TextStyle(
              color: diff < 0 ? Colors.lightGreenAccent : Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }
    if (isMyUniv && isLastKukan) {
      final double gakunaiRec = kantoku.yobiint4[21].toDouble();
      if (gakunaiRec != 0 && gakunaiRec != TEISUU.DEFAULTTIME) {
        final double diff = totalTime - gakunaiRec;
        diffWidgets.add(
          Text(
            '学内記録比: ${_formatTimeDifferenceForRecordDiff(diff)}',
            style: TextStyle(
              color: diff < 0 ? Colors.lightGreenAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        );
      }
    }
    return diffWidgets;
  }

  int _calculateRankDifference(UnivData univ, int currentKukanBangou) {
    if (currentKukanBangou == 0) return 0;
    final int currentRank = univ.tuukajuni_taikai.length > currentKukanBangou
        ? univ.tuukajuni_taikai[currentKukanBangou]
        : TEISUU.DEFAULTJUNI;
    final int previousRank =
        univ.tuukajuni_taikai.length > (currentKukanBangou - 1)
        ? univ.tuukajuni_taikai[currentKukanBangou - 1]
        : TEISUU.DEFAULTJUNI;
    if (currentRank == TEISUU.DEFAULTJUNI || previousRank == TEISUU.DEFAULTJUNI)
      return 0;
    return previousRank - currentRank;
  }

  Map<String, dynamic> _getRankDifferenceText(int difference) {
    if (difference > 0)
      return {'text': '↑$difference', 'color': Colors.lightGreenAccent};
    if (difference < 0)
      return {'text': '↓${difference.abs()}', 'color': Colors.redAccent};
    return {'text': '→', 'color': Colors.white};
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
        if (currentGhensuu == null)
          return const Center(child: Text('データがありません'));

        final int raceBangou = currentGhensuu.hyojiracebangou;
        final int maxDisplayKukanIndex = currentGhensuu.nowracecalckukan > 0
            ? currentGhensuu.nowracecalckukan - 1
            : -1;
        final int lastKukanIndex =
            currentGhensuu.kukansuu_taikaigoto.length > raceBangou
            ? currentGhensuu.kukansuu_taikaigoto[raceBangou] - 1
            : -1;

        if (_displayKukan == null)
          _displayKukan = maxDisplayKukanIndex >= 0 ? maxDisplayKukanIndex : 0;
        final int kukanBangou = _displayKukan!;
        if (maxDisplayKukanIndex < 0)
          return const Center(child: Text('表示可能な区間がありません'));
        final bool isEkidenRace = raceBangou != 3 && raceBangou != 4;

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();
            List<UnivData> filteredUnivData = allUnivData.where((univ) {
              return univ.taikaientryflag.length > raceBangou &&
                  univ.taikaientryflag[raceBangou] == 1 &&
                  univ.tuukajuni_taikai.length > kukanBangou &&
                  univ.time_taikai_total.length > kukanBangou;
            }).toList();
            filteredUnivData = _sortUnivListByTsuukaJuni(
              filteredUnivData,
              raceBangou,
              kukanBangou,
            );

            double topTimeTotal = filteredUnivData.isNotEmpty
                ? filteredUnivData.first.time_taikai_total[kukanBangou]
                : TEISUU.DEFAULTTIME;
            final bool isTopTimeValid = topTimeTotal != TEISUU.DEFAULTTIME;

            final int kukanKyori =
                (currentGhensuu.kyori_taikai_kukangoto[raceBangou][kukanBangou])
                    .round();
            String kukantext = '第${kukanBangou + 1}区 ${kukanKyori}m';
            if (raceBangou == 3) kukantext = '第${kukanBangou + 1}組 1万ｍ';
            if (raceBangou == 4) kukantext = '予選会 ${kukanKyori}m';

            return Stack(
              children: [
                Scaffold(
                  backgroundColor: HENSUU.backgroundcolor,
                  appBar: AppBar(
                    title: Text(
                      '$kukantext (通過順位)',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: HENSUU.backgroundcolor,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: filteredUnivData.isEmpty
                            ? null
                            : () => _exportAsImage(
                                kukantext,
                                filteredUnivData,
                                kukanBangou,
                                raceBangou,
                                lastKukanIndex,
                                currentGhensuu,
                                kantoku,
                                topTimeTotal,
                                isTopTimeValid,
                                isEkidenRace,
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: filteredUnivData.isEmpty
                            ? null
                            : () => _exportAsText(
                                kukantext,
                                filteredUnivData,
                                kukanBangou,
                                raceBangou,
                                lastKukanIndex,
                                currentGhensuu,
                                kantoku,
                                topTimeTotal,
                                isTopTimeValid,
                                isEkidenRace,
                              ),
                      ),
                    ],
                  ),
                  body: Column(
                    children: <Widget>[
                      const Divider(color: Colors.grey),
                      Expanded(
                        child: filteredUnivData.isEmpty
                            ? Center(
                                child: Text(
                                  '結果がありません',
                                  style: TextStyle(color: HENSUU.textcolor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredUnivData.length,
                                itemBuilder: (context, index) {
                                  final univ = filteredUnivData[index];
                                  final tsuukaJuni =
                                      univ.tuukajuni_taikai[kukanBangou];
                                  final tsuukaTime =
                                      univ.time_taikai_total[kukanBangou];
                                  final String junistr =
                                      tsuukaJuni == TEISUU.DEFAULTJUNI
                                      ? '---'
                                      : '${tsuukaJuni + 1}位';
                                  final int rankDiff = _calculateRankDifference(
                                    univ,
                                    kukanBangou,
                                  );
                                  final Map<String, dynamic> rankDiffData =
                                      _getRankDifferenceText(rankDiff);

                                  String timeDiffStr = '';
                                  if (tsuukaJuni != 0 &&
                                      isTopTimeValid &&
                                      tsuukaTime != TEISUU.DEFAULTTIME) {
                                    final double diff =
                                        tsuukaTime - topTimeTotal;
                                    if (diff > 0)
                                      timeDiffStr = _formatTimeDifference(diff);
                                  }

                                  List<Widget> raceDiffWidgets = isEkidenRace
                                      ? _calculateAndFormatRaceRecordDifference(
                                          tsuukaTime,
                                          univ.id,
                                          tsuukaJuni == 0,
                                          raceBangou,
                                          kukanBangou,
                                          lastKukanIndex,
                                          currentGhensuu,
                                          kantoku,
                                        )
                                      : [];

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
                                          children: [
                                            Text(
                                              '$junistr ${univ.name}',
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                                fontSize:
                                                    HENSUU.fontsize_honbun,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (kukanBangou > 0 &&
                                                tsuukaJuni !=
                                                    TEISUU.DEFAULTJUNI)
                                              Text(
                                                rankDiffData['text'],
                                                style: TextStyle(
                                                  color:
                                                      rankDiffData['color']
                                                          as Color,
                                                  fontSize:
                                                      HENSUU.fontsize_honbun *
                                                      0.9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16.0,
                                          ),
                                          child: _buildTimeDisplay(tsuukaTime),
                                        ),
                                        if (timeDiffStr.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              '1位との差: $timeDiffStr',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize:
                                                    HENSUU.fontsize_honbun *
                                                    0.9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ...raceDiffWidgets.map(
                                          (w) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                              top: 4.0,
                                            ),
                                            child: w,
                                          ),
                                        ),
                                        if (kukanBangou == lastKukanIndex &&
                                            (raceBangou <= 2 ||
                                                raceBangou == 5)) ...[
                                          if (univ.chokuzentaikai_zentaitaikaisinflag ==
                                              1)
                                            Text(
                                              '  ※大会新',
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  248,
                                                  244,
                                                  6,
                                                ),
                                                fontSize:
                                                    HENSUU.fontsize_honbun,
                                              ),
                                            ),
                                          if (univ.chokuzentaikai_zentaitaikaisinflag ==
                                                  0 &&
                                              univ.chokuzentaikai_univtaikaisinflag ==
                                                  1 &&
                                              univ.id ==
                                                  currentGhensuu.MYunivid)
                                            Text(
                                              '  ※学内新',
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  248,
                                                  244,
                                                  6,
                                                ),
                                                fontSize:
                                                    HENSUU.fontsize_honbun,
                                              ),
                                            ),
                                        ],
                                        const Divider(color: Colors.white12),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (maxDisplayKukanIndex > 0)
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
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDisplay(double time) {
    return Text(
      TimeDate.timeToJikanFunByouString(time),
      style: TextStyle(
        color: time < TEISUU.DEFAULTTIME
            ? HENSUU.textcolor
            : HENSUU.textcolor.withOpacity(0.7),
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  Widget _buildKukanNavigation(Ghensuu currentGhensuu) {
    final bool canMove = currentGhensuu.nowracecalckukan > 1;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        border: Border(top: BorderSide(color: Colors.grey, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navButton(
            canMove ? () => _changeKukan(currentGhensuu, -1) : null,
            Icons.arrow_back,
            '前',
          ),
          const SizedBox(width: 16),
          _navButton(
            canMove ? () => _changeKukan(currentGhensuu, 1) : null,
            Icons.arrow_forward,
            '次',
            isTrailingIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    VoidCallback? onPressed,
    IconData icon,
    String label, {
    bool isTrailingIcon = false,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isTrailingIcon ? Text(label) : Icon(icon),
        label: isTrailingIcon ? Icon(icon) : Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ★ 追加：テキスト出力・共有機能（通過順位・順位変動・記録比対応） ★
  Future<void> _exportAsText(
    String title,
    List<UnivData> filteredData,
    int kukanBangou,
    int raceBangou,
    int lastKukanIndex,
    Ghensuu currentGhensuu,
    KantokuData kantoku,
    double topTimeTotal,
    bool isTopTimeValid,
    bool isEkidenRace,
  ) async {
    String shareText = "";

    shareText +=
        '※大会記録比や学内記録比のタイムがプラスの場合は新記録に届かなかったことを表し、マイナスの場合には新記録を表します。ただし、速報値なので誤差がありますことをご了承ください\n';
    shareText +=
        '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n';
    shareText += '【$title 通過順位】\n';
    for (var univ in filteredData) {
      final int tsuukaJuni = univ.tuukajuni_taikai[kukanBangou];
      final double tsuukaTimeTotal = univ.time_taikai_total[kukanBangou];
      final String junistr = tsuukaJuni == TEISUU.DEFAULTJUNI
          ? '---'
          : '${tsuukaJuni + 1}位';

      // 1. 基本情報（順位・大学名・通過タイム）
      shareText +=
          '$junistr ${univ.name} ${TimeDate.timeToJikanFunByouString(tsuukaTimeTotal)}';

      // 2. 順位変動（2区以降）
      if (kukanBangou > 0 && tsuukaJuni != TEISUU.DEFAULTJUNI) {
        final int rankDiff = _calculateRankDifference(univ, kukanBangou);
        final Map<String, dynamic> rankDiffData = _getRankDifferenceText(
          rankDiff,
        );
        shareText += ' ${rankDiffData['text']}';
      }
      shareText += '\n';

      // 3. 1位との差
      if (tsuukaJuni != 0 &&
          isTopTimeValid &&
          tsuukaTimeTotal != TEISUU.DEFAULTTIME) {
        final double diff = tsuukaTimeTotal - topTimeTotal;
        if (diff > 0) {
          shareText += '   (1位差: ${_formatTimeDifference(diff)})\n';
        }
      }

      // 4. 大会新・学内新（総合）の判定
      if (kukanBangou == lastKukanIndex &&
          (raceBangou <= 2 || raceBangou == 5)) {
        if (univ.chokuzentaikai_zentaitaikaisinflag == 1) {
          shareText += '   ★大会新更新\n';
        } else if (univ.chokuzentaikai_univtaikaisinflag == 1 &&
            univ.id == currentGhensuu.MYunivid) {
          shareText += '   ☆学内新更新\n';
        }
      }

      // 5. 大会記録比・学内記録比（画面に表示がある場合）
      if (isEkidenRace && tsuukaTimeTotal < TEISUU.DEFAULTTIME) {
        final bool isTop = (tsuukaJuni == 0);
        final bool isMyUniv = (univ.id == currentGhensuu.MYunivid);
        final bool isLast = (kukanBangou == lastKukanIndex);

        // 大会記録比（1位または大会新達成時）
        if (isTop || (isLast && univ.chokuzentaikai_zentaitaikaisinflag == 1)) {
          final int recInt = isLast
              ? kantoku.yobiint4[20]
              : kantoku.yobiint3[kukanBangou];
          if (recInt != 0 && recInt != TEISUU.DEFAULTTIME) {
            final double diff = tsuukaTimeTotal - recInt.toDouble();
            if (isLast) {
              if (diff < 0) {
                shareText +=
                    '   [大会記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(速報値では大会記録を${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}更新)]\n';
              } else {
                shareText +=
                    '   [大会記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(速報値では大会記録には${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}及ばず)]\n';
              }
            } else {
              if (diff < 0) {
                shareText +=
                    '   [大会記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(大会記録ペースを${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}上回っている)]\n';
              } else {
                shareText +=
                    '   [大会記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(大会記録ペースには${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}及ばず)]\n';
              }
            }
          }
        }
        // 学内記録比（自校かつ最終区）
        if (isMyUniv && isLast) {
          final double gakunaiRec = kantoku.yobiint4[21].toDouble();
          if (gakunaiRec != 0 && gakunaiRec != TEISUU.DEFAULTTIME) {
            final double diff = tsuukaTimeTotal - gakunaiRec;
            if (isLast) {
              if (diff < 0) {
                shareText +=
                    '   [学内記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(速報値では学内記録を${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}更新)]\n';
              } else {
                shareText +=
                    '   [学内記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(速報値では学内記録には${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}及ばず)]\n';
              }
            } else {
              if (diff < 0) {
                shareText +=
                    '   [学内記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(学内記録ペースを${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}上回っている)]\n';
              } else {
                shareText +=
                    '   [学内記録比: ${_formatTimeDifferenceForRecordDiff(diff)}(学内記録ペースには${_formatTimeDifferenceForRecordDiff_copy(diff.abs())}及ばず)]\n';
              }
            }
          }
        }
      }
    }
    //shareText +=
    //    '\n※大会記録比や学内記録比のタイムがプラスの場合は新記録に届かなかったことを表し。マイナスの場合には新記録を表します。ただし、速報値なので誤差がありますことをご了承ください\n';

    shareText += '\n#箱庭小駅伝SS';

    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('チーム結果をコピーしました')));
    }
    //await Share.share(shareText);
  }
}
