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

class All0300 extends StatefulWidget {
  final Ghensuu ghensuu;

  const All0300({super.key, required this.ghensuu});

  @override
  State<All0300> createState() => _All0300();
}

class _All0300 extends State<All0300> {
  int? selectedUnivId;

  @override
  void initState() {
    super.initState();
    // 初期値として自大学を設定
    selectedUnivId = widget.ghensuu.MYunivid;
    _init();
  }

  void _init() async {
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final int raceIndex = widget.ghensuu.hyojiracebangou;

    // 1. 対象選手の抽出とソート
    List<SenshuData> myUnivSenshu = senshudataBox.values.where((s) {
      final int gakunenIdx = s.gakunen - 1;
      return s.univid == widget.ghensuu.MYunivid &&
          s.entrykukan_race[raceIndex][gakunenIdx] >= -1;
    }).toList();

    myUnivSenshu.sort((a, b) {
      int gakunenCompare = b.gakunen.compareTo(a.gakunen);
      return (gakunenCompare != 0) ? gakunenCompare : a.id.compareTo(b.id);
    });

    // 2. 一旦全員を補欠(-1)にリセット
    for (var senshu in myUnivSenshu) {
      senshu.entrykukan_race[raceIndex][senshu.gakunen - 1] = -1;
    }

    // 3. SenshuSelectedOptionに基づき区間(0〜)を割り当て
    final int totalKukan = widget.ghensuu.kukansuu_taikaigoto[raceIndex];
    for (int i = 0; i < totalKukan; i++) {
      int selectedIdx = widget.ghensuu.SenshuSelectedOption[i];

      // 範囲チェック: 選手リストのサイズ内であることを確認
      if (selectedIdx >= 0 && selectedIdx < myUnivSenshu.length) {
        var senshu = myUnivSenshu[selectedIdx];
        senshu.entrykukan_race[raceIndex][senshu.gakunen - 1] = i;
      }
    }

    // 4. まとめて保存
    for (var senshu in myUnivSenshu) {
      await senshu.save();
    }

    // 5. データの更新を画面に通知
    if (mounted) {
      setState(() {
        // これにより、ValueListenableBuilderなどが最新の保存データを読み込みます
      });
    }
  }

  // スクロール領域の最上部に表示するボタン群を作成
  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        //spacing: 8.0, // 横の間隔
        //runSpacing: 0.0, // 縦の間隔
        children: [
          // 1. 区間コース確認ボタン
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8),
                barrierDismissible: true,
                barrierLabel: '区間コース確認',
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, _, __) => ModalCourseshoukaiView(
                  racebangou: widget.ghensuu.hyojiracebangou,
                ),
                transitionBuilder: (context, animation, _, child) {
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
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '今季タイム一覧表', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalUnivSenshuMatrixView(
                    targetUnivId: selectedUnivId!,
                  ); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '駅伝出場履歴一覧(選手ごと)', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalEkidenHistoryMatrixView(
                    targetUnivId: selectedUnivId!,
                  ); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '駅伝出場履歴一覧(区間ごと)', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalEkidenKukanHistoryMatrixView(
                    targetUnivId: selectedUnivId!,
                  ); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // 必要に応じてここに TextButton を追加できます
        ],
      ),
    );
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

  // 区間エントリー（または補欠）を更新
  Future<void> _updateKukanStatus(
    SenshuData senshu,
    int raceIndex,
    int kukanValue,
  ) async {
    final int gakunenIndex = senshu.gakunen - 1;
    if (raceIndex >= senshu.entrykukan_race.length ||
        gakunenIndex >= senshu.entrykukan_race[raceIndex].length) {
      return;
    }
    senshu.entrykukan_race[raceIndex][gakunenIndex] = kukanValue;
    await senshu.save();
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
        final int totalKukan = currentGhensuu.kukansuu_taikaigoto[raceIndex];

        List<UnivData> entryUnivList = univBox.values
            .where((u) => u.taikaientryflag[raceIndex] == 1)
            .toList();
        entryUnivList.sort((a, b) => a.id.compareTo(b.id));

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            title: const Text(
              "区間エントリー決定",
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

              // メインコンテンツ
              Expanded(
                child: ValueListenableBuilder<Box<SenshuData>>(
                  valueListenable: senshudataBox.listenable(),
                  builder: (context, sBox, _) {
                    List<SenshuData> displaySenshu = sBox.values.where((s) {
                      final int gakunenIdx = s.gakunen - 1;
                      return s.univid == selectedUnivId &&
                          s.entrykukan_race[raceIndex][gakunenIdx] >= -1;
                    }).toList();

                    displaySenshu.sort((a, b) {
                      int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                      return (gakunenCompare != 0)
                          ? gakunenCompare
                          : a.id.compareTo(b.id);
                    });

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '選手一覧',
                                style: TextStyle(
                                  color: Colors.white,
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
                            // 選手数 + ヘッダー分(1)
                            itemCount: displaySenshu.length + 1,
                            itemBuilder: (context, index) {
                              // 一番上の要素にボタンを表示
                              if (index == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTopButtons(),
                                    const Divider(color: Colors.white10),
                                  ],
                                );
                              }

                              // 選手データ（indexを調整）
                              final senshu = displaySenshu[index - 1];
                              final int gakunenIndex = senshu.gakunen - 1;
                              final int currentKukan = senshu
                                  .entrykukan_race[raceIndex][gakunenIndex];

                              return Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white10),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${senshu.name} (${senshu.gakunen}年) 調子${senshu.chousi}',
                                    style: const TextStyle(
                                      color: HENSUU.textcolor,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      const Text(
                                        "配置: ",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      DropdownButton<int>(
                                        value: currentKukan,
                                        dropdownColor: Colors.grey[850],
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 14,
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                            value: -1,
                                            child: Text("補欠"),
                                          ),
                                          ...List.generate(totalKukan, (i) {
                                            return DropdownMenuItem(
                                              value: i,
                                              child: Text("${i + 1}区"),
                                            );
                                          }),
                                        ],
                                        onChanged: (newVal) async {
                                          if (newVal != null) {
                                            await _updateKukanStatus(
                                              senshu,
                                              raceIndex,
                                              newVal,
                                            );
                                          }
                                        },
                                      ),
                                    ],
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
