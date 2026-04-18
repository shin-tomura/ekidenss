import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/All0150.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';

class Mode0150Content extends StatefulWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0150Content({super.key, required this.ghensuu, this.onAdvanceMode});

  @override
  State<Mode0150Content> createState() => _Mode0150ContentState();
}

class _Mode0150ContentState extends State<Mode0150Content> {
  int MAX_ENTRIES = 0;

  // 詳細ボタン（変更なし）
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
      child: Text(
        '詳細',
        style: TextStyle(
          color: HENSUU.LinkColor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }

  /// 選手のエントリー状態を更新する
  Future<void> _updateEntryStatus(
    SenshuData senshu,
    int raceIndex,
    bool isEntry,
  ) async {
    final int targetValue = isEntry ? -1 : -2;
    final int gakunenIndex = senshu.gakunen - 1;

    if (raceIndex >= senshu.entrykukan_race.length ||
        gakunenIndex >= senshu.entrykukan_race[raceIndex].length) {
      debugPrint('Error: SenshuData entrykukan_race bounds check failed.');
      return;
    }

    senshu.entrykukan_race[raceIndex][gakunenIndex] = targetValue;
    await senshu.save();
  }

  /// エントリー人数の「カウントのみ」を行う
  int _calculateEntryCount(List<SenshuData> senshuList, int raceIndex) {
    int count = 0;
    for (var senshu in senshuList) {
      final int gakunenIndex = senshu.gakunen - 1;

      if (raceIndex < senshu.entrykukan_race.length &&
          gakunenIndex < senshu.entrykukan_race[raceIndex].length) {
        int currentValue = senshu.entrykukan_race[raceIndex][gakunenIndex];
        if (currentValue == -1) {
          count++;
        }
      }
    }
    return count;
  }

  // 進むボタンのアクション
  void _handleAdvanceButton(BuildContext context, int currentEntryCount) async {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    String messagestr = currentGhensuu.hyojiracebangou == 4
        ? 'エントリー選手'
        : '一次エントリー選手';

    if (currentEntryCount != MAX_ENTRIES) {
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'エントリー人数の不備',
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              '$messagestrは$MAX_ENTRIES人である必要があります。\n現在：$currentEntryCount人',
              style: const TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('戻る'),
              ),
            ],
          );
        },
      );
      return;
    }

    {
      Future<List<String>> checkAllUniversitiesEntry() async {
        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
        final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

        final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
        final int raceIndex = currentGhensuu.hyojiracebangou;

        int maxEntries = 0;
        if (raceIndex == 4) {
          maxEntries = 12;
        } else {
          int kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];
          if (kukanCount <= 6)
            maxEntries = 8;
          else if (kukanCount <= 8)
            maxEntries = 13;
          else
            maxEntries = 16;
        }

        List<String> errorMessages = [];

        List<UnivData> entryUnivList = univBox.values
            .where((u) => u.taikaientryflag[raceIndex] == 1)
            .toList();

        for (var univ in entryUnivList) {
          List<SenshuData> univSenshu = senshudataBox.values
              .where((s) => s.univid == univ.id)
              .toList();

          int countMinus1 = 0;
          bool hasInvalidValue = false;

          for (var senshu in univSenshu) {
            final int gakunenIndex = senshu.gakunen - 1;
            if (raceIndex < senshu.entrykukan_race.length &&
                gakunenIndex < senshu.entrykukan_race[raceIndex].length) {
              int status = senshu.entrykukan_race[raceIndex][gakunenIndex];
              if (status == -1) {
                countMinus1++;
              } else if (status != -2) {
                hasInvalidValue = true;
              }
            }
          }

          if (countMinus1 != maxEntries) {
            errorMessages.add('${univ.name}: 人数不備($countMinus1人)');
          } else if (hasInvalidValue) {
            errorMessages.add('${univ.name}: 未設定の選手がいます');
          }
        }
        return errorMessages;
      }

      List<String> errors = await checkAllUniversitiesEntry();
      if (errors.isNotEmpty) {
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'エントリー人数の不備',
                style: TextStyle(color: Colors.black),
              ),
              content: Text(
                '${errors.join("\n")}',
                style: const TextStyle(color: Colors.black),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ゲーム進行の確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '$messagestr$MAX_ENTRIES人を登録しました。\nこのままゲームを進めてよろしいですか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('はい、進めます'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onAdvanceMode?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
        if (currentGhensuu == null) {
          return const Center(
            child: CircularProgressIndicator(color: HENSUU.textcolor),
          );
        }

        final int myUnivId = currentGhensuu.MYunivid;
        final int raceIndex = currentGhensuu.hyojiracebangou;

        final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
        final List<UnivData> allUnivData = univBox.values.toList();
        allUnivData.sort((a, b) => a.id.compareTo(b.id));

        String raceName = "";
        switch (raceIndex) {
          case 0:
            raceName = "10月駅伝";
            break;
          case 1:
            raceName = "11月駅伝";
            break;
          case 2:
            raceName = "正月駅伝";
            break;
          case 3:
            raceName = "11月駅伝予選";
            break;
          case 4:
            raceName = "正月駅伝予選";
            break;
          default:
            raceName = allUnivData.isNotEmpty
                ? allUnivData[0].name_tanshuku
                : "";
        }

        String titlestr = (raceIndex == 4) ? "エントリー選手決定" : "一次エントリー選手決定";

        if (raceIndex == 4) {
          MAX_ENTRIES = 12;
        } else {
          int kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];
          if (kukanCount <= 6)
            MAX_ENTRIES = 8;
          else if (kukanCount <= 8)
            MAX_ENTRIES = 13;
          else
            MAX_ENTRIES = 16;
        }

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            List<SenshuData> myTeamSenshu = senshudataBox.values
                .where((s) => s.univid == myUnivId)
                .toList();

            myTeamSenshu.sort((a, b) {
              int gakunenCompare = b.gakunen.compareTo(a.gakunen);
              return (gakunenCompare != 0)
                  ? gakunenCompare
                  : a.id.compareTo(b.id);
            });

            final int currentEntryCount = _calculateEntryCount(
              myTeamSenshu,
              raceIndex,
            );
            final int remainingEntries = MAX_ENTRIES - currentEntryCount;
            final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            final KantokuData kantoku = kantokuBox.get('KantokuData')!;

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$raceName $titlestr',
                                style: const TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  color: HENSUU.textcolor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '登録状況: $currentEntryCount / $MAX_ENTRIES 人 (残り $remainingEntries 人)',
                                style: TextStyle(
                                  color: currentEntryCount == MAX_ENTRIES
                                      ? HENSUU.LinkColor
                                      : Colors.red,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _handleAdvanceButton(context, currentEntryCount),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HENSUU.buttonColor,
                            foregroundColor: HENSUU.buttonTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("進む＞＞"),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: HENSUU.textcolor, height: 1),
                  Expanded(
                    child: ListView.builder(
                      // ボタン用の領域として +1 する
                      itemCount: myTeamSenshu.length + 1,
                      itemBuilder: (context, index) {
                        // --- スクロール領域の最上部にボタンを表示 ---
                        if (index == 0) {
                          return Column(
                            children: [
                              if (kantoku.yobiint2[17] == 1 &&
                                  (raceIndex <= 2 || raceIndex == 5))
                                TextButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.8,
                                      ),
                                      barrierDismissible: true,
                                      barrierLabel: '全大学確認・変更',
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      pageBuilder: (context, _, __) =>
                                          All0150(ghensuu: currentGhensuu),
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
                                    "全大学確認・変更",
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
                                    barrierColor: Colors.black.withOpacity(0.8),
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
                                    barrierColor: Colors.black.withOpacity(
                                      0.8,
                                    ), // モーダルの背景色
                                    barrierDismissible:
                                        true, // 背景タップで閉じられるようにする
                                    barrierLabel: '今季タイム一覧表', // アクセシビリティ用ラベル
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
                                            targetUnivId:
                                                currentGhensuu.MYunivid,
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
                                    barrierColor: Colors.black.withOpacity(
                                      0.8,
                                    ), // モーダルの背景色
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
                                            targetUnivId:
                                                currentGhensuu.MYunivid,
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
                                    barrierColor: Colors.black.withOpacity(
                                      0.8,
                                    ), // モーダルの背景色
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
                                            targetUnivId:
                                                currentGhensuu.MYunivid,
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
                                    color: const Color.fromARGB(255, 0, 255, 0),
                                    decoration: TextDecoration.underline,
                                    decorationColor: HENSUU.textcolor,
                                  ),
                                ),
                              ),
                              const Divider(color: HENSUU.textcolor, height: 1),
                            ],
                          );
                        }

                        // --- それ以降は選手リストを表示 ---
                        final senshu = myTeamSenshu[index - 1];
                        final int gakunenIndex = senshu.gakunen - 1;

                        bool isEntry = false;
                        if (raceIndex < senshu.entrykukan_race.length &&
                            gakunenIndex <
                                senshu.entrykukan_race[raceIndex].length) {
                          isEntry =
                              senshu.entrykukan_race[raceIndex][gakunenIndex] ==
                              -1;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 12.0,
                          ),
                          child: Row(
                            children: [
                              Switch(
                                value: isEntry,
                                onChanged: (bool newValue) async {
                                  await _updateEntryStatus(
                                    senshu,
                                    raceIndex,
                                    newValue,
                                  );
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.grey.shade400,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    '${senshu.name} (${senshu.gakunen}年)',
                                    style: const TextStyle(
                                      color: HENSUU.textcolor,
                                      fontSize: HENSUU.fontsize_honbun,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ),
                              _buildDetailButton(senshu),
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
      },
    );
  }
}
