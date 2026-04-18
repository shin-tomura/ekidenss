import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

class ModalGakurenKukanView extends StatelessWidget {
  const ModalGakurenKukanView({super.key});

  String _formatTime(double seconds) {
    if (seconds <= 0 || seconds.isNaN) return "-:--";
    int minutes = (seconds / 60).floor();
    int remainingSeconds = (seconds % 60).floor();
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  // 選考基準の説明文ウィジェット
  Widget _buildSelectionRules() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), // 軽く背景色をつけてリストと区別
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "【学連選抜の選考基準】",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "正月駅伝予選において、本大会出場権を得られなかった各大学の中から1名ずつ選出されます。過去の正月駅伝出場回数が1回もしくは出場経験なしの選手の中で、予選会個人順位が一番良い選手が選ばれます。\n※本アプリでは、区間配置は選手の能力を基に自動編成されています。",
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24), // 下部に余白を設けてスクロールしやすくする
        ],
      ),
    );
  }

  Widget _buildDetailButton(BuildContext context, Senshu_Gakuren_Data senshu) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '詳細',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return ModalSenshuDetailView(senshuId: senshu.id);
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
      },
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '詳細',
          style: TextStyle(
            color: HENSUU.LinkColor,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<Senshu_Gakuren_Data> gakurenBox = Hive.box<Senshu_Gakuren_Data>(
      'gakurenSenshuBox',
    );

    const int raceIndex = 2;
    const int yosenIndex = 4;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: HENSUU.backgroundcolor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HENSUU.textcolor, width: 1),
          ),
          child: Column(
            children: [
              // タイトル
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "学連選抜 区間配置",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: HENSUU.textcolor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ヘッダー行
              Container(
                color: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 15,
                      child: Center(
                        child: Text(
                          "区間",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: Text(
                        "氏名/大学",
                        style: TextStyle(color: HENSUU.textcolor, fontSize: 10),
                      ),
                    ),
                    Expanded(
                      flex: 25,
                      child: Text(
                        "予選結果",
                        style: TextStyle(color: HENSUU.textcolor, fontSize: 10),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: Center(
                        child: Text(
                          "詳細",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: gakurenBox.listenable(),
                  builder: (context, Box<Senshu_Gakuren_Data> box, _) {
                    final sortedList = box.values.where((s) {
                      return s.entrykukan_race[raceIndex][s.gakunen - 1] >= 0;
                    }).toList();

                    sortedList.sort(
                      (a, b) =>
                          a.entrykukan_race[raceIndex][a.gakunen - 1].compareTo(
                            b.entrykukan_race[raceIndex][b.gakunen - 1],
                          ),
                    );

                    if (sortedList.isEmpty) {
                      return const Center(
                        child: Text(
                          "データなし",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      // リスト＋説明文の分でカウントを+1する
                      itemCount: sortedList.length + 1,
                      separatorBuilder: (context, index) {
                        // 説明文の前には境界線を表示しない
                        if (index >= sortedList.length - 1)
                          return const SizedBox.shrink();
                        return Divider(
                          color: HENSUU.textcolor.withOpacity(0.2),
                          height: 1,
                        );
                      },
                      itemBuilder: (context, index) {
                        // 最後の要素に到達したら説明文を表示
                        if (index == sortedList.length) {
                          return _buildSelectionRules();
                        }

                        final senshu = sortedList[index];
                        final univ = univBox.get(senshu.univid);
                        final int gakunenIdx = senshu.gakunen - 1;
                        final int kukanNum =
                            senshu.entrykukan_race[raceIndex][gakunenIdx] + 1;
                        final int yosenRank =
                            senshu.kukanjuni_race[yosenIndex][gakunenIdx] + 1;
                        final double yosenTime =
                            senshu.kukantime_race[yosenIndex][gakunenIdx];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 15,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "$kukanNum",
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${senshu.name}(${senshu.gakunen})",
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      univ?.name ?? "---",
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 25,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$yosenRank位",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(yosenTime),
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 20,
                                child: _buildDetailButton(context, senshu),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
