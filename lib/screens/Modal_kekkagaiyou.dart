import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:share_plus/share_plus.dart';

class ModalEkidenResultListView extends StatefulWidget {
  const ModalEkidenResultListView({super.key});

  @override
  State<ModalEkidenResultListView> createState() =>
      _ModalEkidenResultListViewState();
}

class _ModalEkidenResultListViewState extends State<ModalEkidenResultListView> {
  List<Map<String, dynamic>> _calculatedResults = [];
  List<UnivData> _sortedByOverallRank = [];
  String _totalRankText = ""; // 総合順位一覧のテキスト版
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndGenerateResults();
  }

  Future<void> _loadAndGenerateResults() async {
    setState(() => _isLoading = true);

    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');

    final gh = ghensuuBox.getAt(0)!;
    final int raceIdx = gh.hyojiracebangou;

    // 出場大学のみを抽出
    final List<UnivData> entryUnivs = univBox.values
        .where((u) => u.taikaientryflag[raceIdx] == 1 || raceIdx == 5)
        .toList();

    final List<SenshuData> allSenshus = senshuBox.values.toList();

    // 1. 各大学の詳細テキスト生成
    List<Map<String, dynamic>> results = [];
    // 大学ID順にソートして処理
    final sortedUnivsForText = entryUnivs.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var univ in sortedUnivsForText) {
      String text = _generateUnivResultText(gh, univ, allSenshus, raceIdx);
      results.add({'univName': univ.name, 'resultText': text});
    }

    // 2. 総合順位表用のソートとテキスト生成
    final overallRankList = entryUnivs.toList()
      ..sort((a, b) {
        final aRank = a.juni_race[raceIdx][0];
        final bRank = b.juni_race[raceIdx][0];
        return aRank.compareTo(bRank);
      });

    String rankText = "【総合順位一覧】\n";
    for (var univ in overallRankList) {
      final lastKukanIdx = gh.kukansuu_taikaigoto[raceIdx] - 1;
      // 予選会等の特殊な集計があるため time_race[raceIdx][0] を優先使用
      final totalTime = univ.time_race[raceIdx][0];
      rankText +=
          "${univ.juni_race[raceIdx][0] + 1}位 ${univ.name} ${TimeDate.timeToJikanFunByouString(totalTime)}";
      if (raceIdx != 3 && raceIdx != 4) {
        if (univ.chokuzentaikai_zentaitaikaisinflag == 1) {
          rankText += " ※大会新";
        } else if (univ.chokuzentaikai_univtaikaisinflag == 1) {
          rankText += " ※学内新";
        }
      }
      rankText += "\n";
    }

    if (mounted) {
      setState(() {
        _calculatedResults = results;
        _sortedByOverallRank = overallRankList;
        _totalRankText = rankText;
        _isLoading = false;
      });
    }
  }

  String _generateUnivResultText(
    Ghensuu gh,
    UnivData univ,
    List<SenshuData> allSenshuData,
    int racebangou,
  ) {
    String tempstr = "";
    String eventname = "";
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    // イベント名の決定
    if (racebangou == 0)
      eventname = "10月駅伝";
    else if (racebangou == 1)
      eventname = "11月駅伝";
    else if (racebangou == 2)
      eventname = "正月駅伝";
    else if (racebangou == 3)
      eventname = "11月駅伝予選";
    else if (racebangou == 4)
      eventname = "正月駅伝予選";
    else
      eventname = sortedUnivData[0].name_tanshuku;

    tempstr += "#${gh.year}年${gh.month}月 ${eventname}\n";

    // 出場チェック
    if (univ.taikaientryflag[racebangou] == 0 && racebangou != 5) {
      tempstr += "${univ.name}大学は不出場\n";
      return tempstr;
    }

    tempstr += "${univ.name}大学の結果\n";

    // --- racebangou == 3 (11月駅伝予選) のロジック ---
    if (racebangou == 3) {
      tempstr += "------\n";
      tempstr +=
          "総合 ${univ.juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(univ.time_race[racebangou][0])}\n";
      tempstr += "------\n";

      var filteredSenshuData = allSenshuData
          .where(
            (s) =>
                s.univid == univ.id &&
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1,
          )
          .toList();

      for (
        int i_kukan = 0;
        i_kukan < gh.kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        tempstr +=
            "◆${i_kukan + 1}組目終了時点 ${univ.tuukajuni_taikai[i_kukan] + 1}位\n";
        for (var senshu in filteredSenshuData) {
          if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] ==
              i_kukan) {
            tempstr += "${i_kukan + 1}組目 ${senshu.name} ${senshu.gakunen}年\n";
            tempstr +=
                "個人${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])}\n";
            tempstr += "------\n";
          }
        }
      }
    }
    // --- racebangou == 4 (正月駅伝予選) のロジック ---
    else if (racebangou == 4) {
      tempstr +=
          "総合 ${univ.juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(univ.time_race[racebangou][0])}\n";

      var filteredSenshuData = allSenshuData
          .where(
            (s) =>
                s.univid == univ.id &&
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1,
          )
          .toList();

      // 正月予選はタイム順にソート
      filteredSenshuData.sort((a, b) {
        return a.kukantime_race[racebangou][a.gakunen - 1].compareTo(
          b.kukantime_race[racebangou][b.gakunen - 1],
        );
      });

      for (var senshu in filteredSenshuData) {
        tempstr +=
            "${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${senshu.name}(${senshu.gakunen}) ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])}\n";
      }
    }
    // --- 通常の大会 (0, 1, 2, 5など) のロジック ---
    else {
      tempstr += "------\n";
      tempstr +=
          "総合 ${univ.juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(univ.time_race[racebangou][0])}\n";
      if (univ.chokuzentaikai_zentaitaikaisinflag == 1) {
        tempstr += "※大会新\n";
      } else if (univ.chokuzentaikai_univtaikaisinflag == 1) {
        tempstr += "※学内新\n";
      }
      tempstr += "------\n";

      var filteredSenshuData = allSenshuData
          .where(
            (s) =>
                s.univid == univ.id &&
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1,
          )
          .toList();

      for (
        int i_kukan = 0;
        i_kukan < gh.kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        for (var senshu in filteredSenshuData) {
          if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] ==
              i_kukan) {
            tempstr += "◆${i_kukan + 1}区 ${senshu.name} ${senshu.gakunen}年\n";
            tempstr +=
                "区間${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])} ${univ.tuukajuni_taikai[i_kukan] + 1}位通過\n";
            if (senshu.chokuzentaikai_zentaikukansinflag == 1) {
              tempstr += "※区間新\n";
            } else if (senshu.chokuzentaikai_univkukansinflag == 1) {
              tempstr += "※学内新\n";
            }
            tempstr += "------\n";
          }
        }
      }
    }

    return tempstr;
  }

  @override
  Widget build(BuildContext context) {
    final gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '駅伝結果要約',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 16),
                  Text("データを集計中...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildTotalRankExpansionTile(gh),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    "大学別詳細",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._calculatedResults
                    .map((item) => _buildUnivDetailCard(item))
                    .toList(),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildTotalRankExpansionTile(Ghensuu gh) {
    return Card(
      color: Colors.blueGrey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white24),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        iconColor: Colors.orangeAccent,
        collapsedIconColor: Colors.orangeAccent,
        title: const Text(
          "総合順位一覧",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _totalRankText));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('順位一覧をコピーしました')));
                },
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Colors.orangeAccent,
                ),
                label: const Text(
                  "コピー",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
              TextButton.icon(
                onPressed: () => Share.share(_totalRankText),
                icon: const Icon(
                  Icons.share,
                  size: 18,
                  color: Colors.orangeAccent,
                ),
                label: const Text(
                  "共有",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
          ..._sortedByOverallRank.map((univ) {
            final raceIdx = gh.hyojiracebangou;
            final totalTime = univ.time_race[raceIdx][0];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      "${univ.juni_race[raceIdx][0] + 1}位",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      univ.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    TimeDate.timeToJikanFunByouString(totalTime),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (raceIdx != 3 && raceIdx != 4)
                    if (univ.chokuzentaikai_zentaitaikaisinflag == 1)
                      const Text(
                        " *大会新",
                        style: TextStyle(
                          color: Color.fromARGB(252, 251, 170, 163),
                          fontSize: 11,
                        ),
                      )
                    else if (univ.chokuzentaikai_univtaikaisinflag == 1)
                      const Text(
                        " *学内新",
                        style: TextStyle(
                          color: Color.fromARGB(255, 226, 251, 2),
                          fontSize: 11,
                        ),
                      ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUnivDetailCard(Map<String, dynamic> item) {
    final String univName = item['univName'];
    final String resultText = item['resultText'];
    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        iconColor: Colors.cyanAccent,
        collapsedIconColor: Colors.white70,
        title: Text(
          univName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: resultText));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('コピーしました')));
                },
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Colors.cyanAccent,
                ),
                label: const Text(
                  "コピー",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
              TextButton.icon(
                onPressed: () => Share.share(resultText),
                icon: const Icon(
                  Icons.share,
                  size: 18,
                  color: Colors.cyanAccent,
                ),
                label: const Text(
                  "共有",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              resultText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: HENSUU.backgroundcolor,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text("戻る", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
