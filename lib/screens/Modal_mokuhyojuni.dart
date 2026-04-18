import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';

// ソート種別
enum UnivSortType { univId, rank }

class ModalTargetRankSettingView extends StatefulWidget {
  const ModalTargetRankSettingView({super.key});

  @override
  State<ModalTargetRankSettingView> createState() =>
      _ModalTargetRankSettingViewState();
}

class _ModalTargetRankSettingViewState
    extends State<ModalTargetRankSettingView> {
  UnivSortType _sortType = UnivSortType.univId;

  // タイム差整形関数
  String _formatTimeDifference(double diffTime) {
    if (diffTime <= 0) return 'トップ';
    final int totalSeconds = diffTime.round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (minutes >= 1) {
      return '+${minutes}分${seconds}秒';
    } else {
      return '+${seconds}秒';
    }
  }

  // レース番号に応じた最大順位を取得
  int _getMaxRank(int raceBangou) {
    switch (raceBangou) {
      case 0:
        return 9; // 10月：1-9位
      case 1:
        return 14; // 11月：1-14位
      case 2:
        return 19; // 正月：1-19位
      case 5:
        return 29; // カスタム：1-29位
      default:
        return 19;
    }
  }

  // 確認ダイアログを表示する関数
  Future<void> _showSyncConfirmDialog(
    List<UnivData> entryUnivs,
    int raceBangou,
    int kukanIndex,
    int maxRank,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('目標順位の一括更新', style: TextStyle(color: Colors.white)),
          content: const Text(
            '全大学の目標順位を現在の順位に書き換えます。よろしいですか？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '更新',
                style: TextStyle(color: Colors.amberAccent),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _syncAllTargetRanks(entryUnivs, raceBangou, kukanIndex, maxRank);
    }
  }

  // 全大学の目標順位を現在の順位に一括設定する
  Future<void> _syncAllTargetRanks(
    List<UnivData> entryUnivs,
    int raceBangou,
    int kukanIndex,
    int maxRank,
  ) async {
    if (kukanIndex == 0) return; // 1区では実行不可

    for (var univ in entryUnivs) {
      int currentRank0Base = univ.tuukajuni_taikai[kukanIndex - 1];
      if (currentRank0Base >= maxRank) {
        currentRank0Base = maxRank - 1;
      }
      univ.mokuhyojuni[raceBangou] = currentRank0Base;
      await univ.save();
    }
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全大学の目標順位を現在の順位に合わせて更新しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    final int kukanIndex = currentGhensuu.nowracecalckukan;
    final int raceBangou = currentGhensuu.hyojiracebangou;
    final int maxRank = _getMaxRank(raceBangou);

    return ValueListenableBuilder(
      valueListenable: univdataBox.listenable(),
      builder: (context, Box<UnivData> uBox, _) {
        List<UnivData> entryUnivs = uBox.values
            .where((u) => u.taikaientryflag[raceBangou] == 1)
            .toList();

        double topTime = 0;
        if (kukanIndex > 0 && entryUnivs.isNotEmpty) {
          topTime = entryUnivs
              .map((u) => u.time_taikai_total[kukanIndex - 1])
              .reduce((a, b) => a < b ? a : b);
        }

        if (kukanIndex == 0 || _sortType == UnivSortType.univId) {
          entryUnivs.sort((a, b) => a.id.compareTo(b.id));
        } else {
          entryUnivs.sort((a, b) {
            int rankA = a.tuukajuni_taikai[kukanIndex - 1];
            int rankB = b.tuukajuni_taikai[kukanIndex - 1];
            return rankA.compareTo(rankB);
          });
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text('目標順位', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            actions: [
              if (kukanIndex > 0)
                TextButton.icon(
                  onPressed: () => _showSyncConfirmDialog(
                    entryUnivs,
                    raceBangou,
                    kukanIndex,
                    maxRank,
                  ),
                  icon: const Icon(
                    Icons.auto_fix_high,
                    color: Colors.amberAccent,
                    size: 18,
                  ),
                  label: const Text(
                    "現順位を目標に",
                    style: TextStyle(color: HENSUU.LinkColor, fontSize: 12),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              if (kukanIndex > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _sortButton('大学ID順', UnivSortType.univId),
                      const SizedBox(width: 10),
                      _sortButton('現順位順', UnivSortType.rank),
                    ],
                  ),
                ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  // 最後に注意書きを追加するため +1 する
                  itemCount: entryUnivs.length + 1,
                  itemBuilder: (context, index) {
                    // 最後の要素の場合
                    if (index == entryUnivs.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Text(
                          "※ここで設定できる目標順位は今から走る選手が走り終わった時点でのものです。今から走る選手に目標順位を下回っての突っ込み補正や上回っての一息補正がかかってしまうかどうかはすでに判断済みで修正できません。",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }

                    final univ = entryUnivs[index];
                    final int targetRank = univ.mokuhyojuni[raceBangou];

                    int currentRank = -1;
                    Color rankColor = Colors.white;
                    String diffText = "";

                    if (kukanIndex > 0) {
                      currentRank = univ.tuukajuni_taikai[kukanIndex - 1];
                      double myTime = univ.time_taikai_total[kukanIndex - 1];
                      diffText = _formatTimeDifference(myTime - topTime);

                      if (currentRank < targetRank) {
                        rankColor = Colors.cyanAccent;
                      } else if (currentRank > targetRank) {
                        rankColor = Colors.redAccent;
                      } else {
                        rankColor = Colors.amber;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                univ.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (kukanIndex > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "現在 ${currentRank + 1}位",
                                      style: TextStyle(
                                        color: rankColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      diffText,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 253, 2, 2),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flag,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "目標順位:",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                              Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blueGrey),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: targetRank,
                                    dropdownColor: Colors.grey[900],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    items: List.generate(maxRank, (i) {
                                      return DropdownMenuItem(
                                        value: i,
                                        child: Text('${i + 1}位'),
                                      );
                                    }),
                                    onChanged: (int? newValue) async {
                                      if (newValue != null) {
                                        univ.mokuhyojuni[raceBangou] = newValue;
                                        await univ.save();
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortButton(String label, UnivSortType type) {
    bool isSelected = _sortType == type;
    return ElevatedButton(
      onPressed: () => setState(() => _sortType = type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}
