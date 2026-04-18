import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';

class All0150 extends StatefulWidget {
  final Ghensuu ghensuu;

  const All0150({super.key, required this.ghensuu});

  @override
  State<All0150> createState() => _All0150State();
}

class _All0150State extends State<All0150> {
  int? selectedUnivId;
  int MAX_ENTRIES = 0;

  @override
  void initState() {
    super.initState();
    selectedUnivId = widget.ghensuu.MYunivid;
  }

  // 選手詳細モーダルを表示
  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
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
      child: const Text(
        '詳細',
        style: TextStyle(
          color: HENSUU.LinkColor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }

  // 選手の一次エントリー状態を保存
  Future<void> _updateEntryStatus(
    SenshuData senshu,
    int raceIndex,
    bool isEntry,
  ) async {
    final int targetValue = isEntry ? -1 : -2;
    final int gakunenIndex = senshu.gakunen - 1;

    if (raceIndex >= senshu.entrykukan_race.length ||
        gakunenIndex >= senshu.entrykukan_race[raceIndex].length) {
      return;
    }

    senshu.entrykukan_race[raceIndex][gakunenIndex] = targetValue;
    await senshu.save();
  }

  // エントリー済み人数を計算
  int _calculateEntryCount(List<SenshuData> senshuList, int raceIndex) {
    int count = 0;
    for (var senshu in senshuList) {
      final int gakunenIndex = senshu.gakunen - 1;
      if (raceIndex < senshu.entrykukan_race.length &&
          gakunenIndex < senshu.entrykukan_race[raceIndex].length) {
        if (senshu.entrykukan_race[raceIndex][gakunenIndex] == -1) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, gBox, _) {
        final Ghensuu? currentGhensuu = gBox.getAt(0);
        if (currentGhensuu == null) return const SizedBox.shrink();

        final int raceIndex = currentGhensuu.hyojiracebangou;

        // 出走大学リスト
        List<UnivData> entryUnivList = univBox.values
            .where((u) => u.taikaientryflag[raceIndex] == 1)
            .toList();
        entryUnivList.sort((a, b) => a.id.compareTo(b.id));

        // 大会ごとのエントリー上限数設定
        if (raceIndex == 4) {
          MAX_ENTRIES = 12;
        } else {
          int kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];
          if (kukanCount <= 6) {
            MAX_ENTRIES = 8;
          } else if (kukanCount <= 8) {
            MAX_ENTRIES = 13;
          } else {
            MAX_ENTRIES = 16;
          }
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            title: const Text(
              "全校エントリー管理",
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // 大学選択ドロップダウン（固定）
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.black26,
                child: Row(
                  children: [
                    const Text("対象大学: ", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<int>(
                        value: selectedUnivId,
                        dropdownColor: Colors.grey[900],
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: entryUnivList.map((univ) {
                          return DropdownMenuItem<int>(
                            value: univ.id,
                            child: Text(univ.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedUnivId = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ValueListenableBuilder<Box<SenshuData>>(
                  valueListenable: senshudataBox.listenable(),
                  builder: (context, sBox, _) {
                    List<SenshuData> displaySenshu = sBox.values
                        .where((s) => s.univid == selectedUnivId)
                        .toList();

                    // 学年降順 > ID昇順
                    displaySenshu.sort((a, b) {
                      int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                      return (gakunenCompare != 0)
                          ? gakunenCompare
                          : a.id.compareTo(b.id);
                    });

                    final int currentEntryCount = _calculateEntryCount(
                      displaySenshu,
                      raceIndex,
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '登録状況: $currentEntryCount / $MAX_ENTRIES 人',
                                style: TextStyle(
                                  color: currentEntryCount == MAX_ENTRIES
                                      ? HENSUU.LinkColor
                                      : Colors.orange,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HENSUU.buttonColor,
                                ),
                                child: const Text("閉じる"),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),

                        // スクロール可能領域
                        Expanded(
                          child: ListView.builder(
                            itemCount: displaySenshu.length + 1, // ヘッダー分+1
                            itemBuilder: (context, index) {
                              // --- スクロール領域の最上部ユニット ---
                              if (index == 0) {
                                return Column(
                                  children: [
                                    // 1. 区間コース確認ボタン
                                    TextButton(
                                      onPressed: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierColor: Colors.black
                                              .withOpacity(0.8),
                                          barrierDismissible: true,
                                          barrierLabel: '区間コース確認',
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          pageBuilder: (context, _, __) =>
                                              ModalCourseshoukaiView(
                                                racebangou: raceIndex,
                                              ),
                                          transitionBuilder:
                                              (context, animation, _, child) {
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
                                      child: const Text(
                                        "区間コース確認",
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 0, 255, 0),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierColor: Colors.black
                                              .withOpacity(0.8), // モーダルの背景色
                                          barrierDismissible:
                                              true, // 背景タップで閉じられるようにする
                                          barrierLabel:
                                              '今季タイム一覧表', // アクセシビリティ用ラベル
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ), // アニメーション時間
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) {
                                                // ここに表示したいモーダルのウィジェットを指定
                                                return ModalUnivSenshuMatrixView(
                                                  targetUnivId: selectedUnivId!,
                                                ); // const を追加
                                              },
                                          transitionBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                // モーダル表示時のアニメーション (例: フェードイン)
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
                                      child: Text(
                                        "今季タイム一覧表",
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            255,
                                            0,
                                          ),
                                          decoration: TextDecoration.underline,
                                          decorationColor: HENSUU.textcolor,
                                        ),
                                      ),
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierColor: Colors.black
                                              .withOpacity(0.8), // モーダルの背景色
                                          barrierDismissible:
                                              true, // 背景タップで閉じられるようにする
                                          barrierLabel:
                                              '駅伝出場履歴一覧(選手ごと)', // アクセシビリティ用ラベル
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ), // アニメーション時間
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) {
                                                // ここに表示したいモーダルのウィジェットを指定
                                                return ModalEkidenHistoryMatrixView(
                                                  targetUnivId: selectedUnivId!,
                                                ); // const を追加
                                              },
                                          transitionBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                // モーダル表示時のアニメーション (例: フェードイン)
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
                                      child: Text(
                                        "駅伝出場履歴一覧(選手ごと)",
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            255,
                                            0,
                                          ),
                                          decoration: TextDecoration.underline,
                                          decorationColor: HENSUU.textcolor,
                                        ),
                                      ),
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierColor: Colors.black
                                              .withOpacity(0.8), // モーダルの背景色
                                          barrierDismissible:
                                              true, // 背景タップで閉じられるようにする
                                          barrierLabel:
                                              '駅伝出場履歴一覧(区間ごと)', // アクセシビリティ用ラベル
                                          transitionDuration: const Duration(
                                            milliseconds: 300,
                                          ), // アニメーション時間
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) {
                                                // ここに表示したいモーダルのウィジェットを指定
                                                return ModalEkidenKukanHistoryMatrixView(
                                                  targetUnivId: selectedUnivId!,
                                                ); // const を追加
                                              },
                                          transitionBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                // モーダル表示時のアニメーション (例: フェードイン)
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
                                      child: Text(
                                        "駅伝出場履歴一覧(区間ごと)",
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            255,
                                            0,
                                          ),
                                          decoration: TextDecoration.underline,
                                          decorationColor: HENSUU.textcolor,
                                        ),
                                      ),
                                    ),
                                    const Divider(color: Colors.white10),
                                  ],
                                );
                              }

                              // 選手リストの表示（indexを-1して調整）
                              final senshu = displaySenshu[index - 1];
                              final int gakunenIndex = senshu.gakunen - 1;

                              bool isEntry = false;
                              if (raceIndex < senshu.entrykukan_race.length &&
                                  gakunenIndex <
                                      senshu
                                          .entrykukan_race[raceIndex]
                                          .length) {
                                isEntry =
                                    senshu
                                        .entrykukan_race[raceIndex][gakunenIndex] ==
                                    -1;
                              }

                              return Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white10),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Switch(
                                    value: isEntry,
                                    activeColor: Colors.green,
                                    onChanged: (bool newValue) async {
                                      await _updateEntryStatus(
                                        senshu,
                                        raceIndex,
                                        newValue,
                                      );
                                    },
                                  ),
                                  title: Text(
                                    '${senshu.name} (${senshu.gakunen}年)',
                                    style: const TextStyle(
                                      color: HENSUU.textcolor,
                                    ),
                                  ),
                                  trailing: _buildDetailButton(senshu),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
}
