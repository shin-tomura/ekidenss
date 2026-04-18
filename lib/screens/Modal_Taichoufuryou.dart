import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';

// 体調不良者（調子が0）の選手一覧を表示するウィジェット
class ModalIllnessSenshuListView extends StatefulWidget {
  const ModalIllnessSenshuListView({super.key});

  @override
  State<ModalIllnessSenshuListView> createState() =>
      _ModalIllnessSenshuListViewState();
}

class _ModalIllnessSenshuListViewState
    extends State<ModalIllnessSenshuListView> {
  // 大学IDをキー、体調不良選手のリストを値とするマップ
  Map<int, List<SenshuData>> _illnessSenshuMap = {};

  @override
  void initState() {
    super.initState();
    _calculateIllnessSenshu();
  }

  /// 体調不良選手を抽出し、大学ごとに分類・ソートする
  void _calculateIllnessSenshu() {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
    if (currentGhensuu == null) return;

    final int raceBangou = currentGhensuu.hyojiracebangou;

    // 出場大学のIDリストを取得 (UnivDataのtaikaientryflagが1であること)
    final Set<int> participatingUnivIds = univdataBox.values
        .where((u) => u.taikaientryflag[raceBangou] == 1)
        .map((u) => u.id)
        .toSet();

    Map<int, List<SenshuData>> illnessMap = {};

    for (final senshu in senshudataBox.values) {
      if (!participatingUnivIds.contains(senshu.univid)) continue;
      if (senshu.chousi != 0) continue;

      final int entryValue =
          senshu.entrykukan_race.length > raceBangou &&
              senshu.entrykukan_race[raceBangou].length > senshu.gakunen - 1
          ? senshu.entrykukan_race[raceBangou][senshu.gakunen - 1]
          : -2;

      // 条件：0以上（区間エントリー中） または 負の数で-2以外（補欠・当日変更等）
      bool isTarget = (entryValue >= 0) || (entryValue < 0 && entryValue != -2);

      if (isTarget) {
        if (!illnessMap.containsKey(senshu.univid)) {
          illnessMap[senshu.univid] = [];
        }
        illnessMap[senshu.univid]!.add(senshu);
      }
    }

    // 大学ID順にソートしたMapを作成
    final sortedKeys = illnessMap.keys.toList()..sort();
    Map<int, List<SenshuData>> sortedMap = {};

    for (var key in sortedKeys) {
      final List<SenshuData> senshuList = illnessMap[key]!;

      // --- 各大学内の選手ソートロジックの改良 ---
      senshuList.sort((a, b) {
        final int valA = a.entrykukan_race[raceBangou][a.gakunen - 1];
        final int valB = b.entrykukan_race[raceBangou][b.gakunen - 1];

        // 1. 区間エントリー(>=0) か 補欠(<0) かを判定
        bool isRunnerA = valA >= 0;
        bool isRunnerB = valB >= 0;

        if (isRunnerA && !isRunnerB) return -1; // Aが走者、Bが補欠ならAが先
        if (!isRunnerA && isRunnerB) return 1; // Aが補欠、Bが走者ならBが先

        if (isRunnerA && isRunnerB) {
          // 両方走者の場合：区間番号(val)の昇順
          return valA.compareTo(valB);
        } else {
          // 両方補欠の場合
          // ①学年(gakunen)の降順
          if (a.gakunen != b.gakunen) {
            return b.gakunen.compareTo(a.gakunen);
          }
          // ②学年が同じならIDの昇順
          return a.id.compareTo(b.id);
        }
      });

      sortedMap[key] = senshuList;
    }

    setState(() {
      _illnessSenshuMap = sortedMap;
    });
  }

  // 選手の表示を整形するヘルパー関数
  String _formatSenshu(SenshuData senshu, int raceBangou) {
    final int entryValue =
        senshu.entrykukan_race[raceBangou][senshu.gakunen - 1];
    String status = "";
    if (entryValue >= 0) {
      status = "[${entryValue + 1}区]";
    } else {
      status = "[補欠]";
    }
    return '$status ${senshu.name} (${senshu.gakunen}年)';
  }

  @override
  Widget build(BuildContext context) {
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final int raceBangou = ghensuuBox.getAt(0)?.hyojiracebangou ?? 0;

    final Map<int, UnivData> univDataMap = {
      for (var univ in univdataBox.values) univ.id: univ,
    };

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('🤒 体調不良選手一覧', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: _illnessSenshuMap.isEmpty
          ? Center(
              child: Text(
                '現在、体調不良の選手はいません。',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _illnessSenshuMap.keys.length,
              itemBuilder: (context, index) {
                final int univid = _illnessSenshuMap.keys.elementAt(index);
                final UnivData? univ = univDataMap[univid];
                final List<SenshuData> senshuList = _illnessSenshuMap[univid]!;

                if (univ == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 大学名
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${univ.name}',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: HENSUU.fontsize_honbun + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 体調不良選手のリスト
                      ...senshuList.map((senshu) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 28.0,
                            bottom: 4.0,
                          ),
                          child: Text(
                            _formatSenshu(senshu, raceBangou),
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        );
                      }).toList(),

                      // 大学ごとの区切り
                      const Divider(
                        color: Colors.white24,
                        height: 20,
                        thickness: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
