import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/ModalAverageTimeRankingView.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_kukanentry.dart';
//import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_TodayChangeList.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_kukanresult350.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';

class Mode0280Content extends StatefulWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0280Content({super.key, required this.ghensuu, this.onAdvanceMode});

  @override
  State<Mode0280Content> createState() => _Mode0280Content();
}

class _Mode0280Content extends State<Mode0280Content> {
  int _selectedRank = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialRank();
  }

  int _kakutokugoldsilver() {
    int _getMaxRank(int raceIdx) {
      switch (raceIdx) {
        case 0:
          return 8;
        case 1:
          return 13;
        case 2:
          return 18;
        case 5:
          return 28;
        default:
          return 19;
      }
    }

    int _getSeedRank(int raceIdx) {
      switch (raceIdx) {
        case 0:
          return 4;
        case 1:
          return 7;
        case 2:
          return 9;
        case 5:
          return 9;
        default:
          return 4;
      }
    }

    int kotae = 0;
    int r = 0;
    int racebangou = widget.ghensuu.hyojiracebangou;
    int maxrank = _getMaxRank(racebangou);
    int seedrank = _getSeedRank(racebangou);
    //final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    //final List<UnivData> sortedUnivData = univBox.values.toList()
    //  ..sort((a, b) => a.id.compareTo(b.id));
    int targetrank = _selectedRank - 1;
    //sortedUnivData[widget.ghensuu.MYunivid].mokuhyojuni[racebangou];
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    if (kantoku.yobiint2[0] == 0) {
      int rYuushou = 0;
      int rSeed = 0;
      if (widget.ghensuu.kazeflag == 0) {
        //r = 30;
        rSeed = 30;
        rYuushou = 50;
      }
      if (widget.ghensuu.kazeflag == 1) {
        //r = 50;
        rSeed = 50;
        rYuushou = 100;
      }
      if (widget.ghensuu.kazeflag == 2) {
        //r = 100;
        rSeed = 100;
        rYuushou = 200;
      }
      if (widget.ghensuu.kazeflag == 3) {
        //r = 200;
        rSeed = 200;
        rYuushou = 300;
      }

      if (targetrank == 0) {
        r = rYuushou;
        //何もしない
        /*} else if ((racebangou == 0 && targetrank >= 5) ||
                  (racebangou == 1 && targetrank >= 8) ||
                  (racebangou == 2 && targetrank >= 10) ||
                  (racebangou == 5 && targetrank >= 10)) {*/
      } else if (targetrank == maxrank) {
        r = 10;
      } else {
        int sa = 0;
        double persa = 0.0;
        int ryou_koujousin = 0;
        int plusryou = 0;
        if (targetrank <= seedrank) {
          sa = rYuushou - rSeed;
          persa = sa / (seedrank - 0);
          ryou_koujousin = seedrank - targetrank;
          plusryou = (persa * ryou_koujousin).toInt();
          r = rSeed + plusryou;
        } else {
          sa = rSeed - 10;
          persa = sa / (maxrank - seedrank);
          ryou_koujousin = maxrank - targetrank;
          plusryou = (persa * ryou_koujousin).toInt();
          r = 10 + plusryou;
        }
      }
    }
    r *= kantoku.yobiint2[12];
    if (targetrank == 0) {
      r *= 2;
    }
    kotae = r;
    return kotae;
  }

  /// 初期値の読み込み
  void _loadInitialRank() {
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final List<UnivData> sortedUnivData = univBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (widget.ghensuu.MYunivid < sortedUnivData.length) {
      final int savedRankValue = sortedUnivData[widget.ghensuu.MYunivid]
          .mokuhyojuni[widget.ghensuu.hyojiracebangou];
      int rank = (savedRankValue >= 0) ? savedRankValue + 1 : 1;

      int maxRank = _getMaxRank(widget.ghensuu.hyojiracebangou);
      if (rank > maxRank) rank = maxRank;

      _selectedRank = rank;
    }
  }

  /// レース番号に応じた最大順位を返す
  int _getMaxRank(int raceIdx) {
    switch (raceIdx) {
      case 0:
        return 9;
      case 1:
        return 14;
      case 2:
        return 19;
      case 5:
        return 29;
      default:
        return 20;
    }
  }

  // 選手詳細モーダルを表示
  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '詳細',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, _, __) =>
              ModalSenshuDetailView(senshuId: senshu.id),
          transitionBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
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

  // 確認ダイアログを表示して保存・進行
  Future<void> _handleSaveAndAdvance(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('目標順位の確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '目標順位を「$_selectedRank位」に設定します。\nよろしいですか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('はい、決定します'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
      final List<UnivData> sortedUnivData = univBox.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      if (widget.ghensuu.MYunivid < sortedUnivData.length) {
        final myUniv = sortedUnivData[widget.ghensuu.MYunivid];
        // 1位なら0で格納
        myUniv.mokuhyojuni[widget.ghensuu.hyojiracebangou] = _selectedRank - 1;

        await myUniv.save();
      }

      widget.onAdvanceMode?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int raceIdx = widget.ghensuu.hyojiracebangou;

    if (![0, 1, 2, 5].contains(raceIdx)) {
      return const Center(
        child: Text("設定対象外の画面です", style: TextStyle(color: Colors.white)),
      );
    }

    final int maxRankLimit = _getMaxRank(raceIdx);
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    // 大会名の判定ロジック
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final List<UnivData> allUnivData = univBox.values.toList();
    allUnivData.sort((a, b) => a.id.compareTo(b.id));

    String raceName = "";
    switch (raceIdx) {
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
        raceName = allUnivData.isNotEmpty ? allUnivData[0].name_tanshuku : "";
    }

    String timesastr = "";
    String rankText = "";

    if (widget.ghensuu.nowracecalckukan > 0) {
      final univDataBox = Hive.box<UnivData>('univBox');
      List<UnivData> idjununivdata = univDataBox.values.toList();
      idjununivdata.sort((a, b) => a.id.compareTo(b.id));
      List<UnivData> timejununivdata = idjununivdata.toList()
        ..sort(
          (a, b) => a.time_taikai_total[widget.ghensuu.nowracecalckukan - 1]
              .compareTo(
                b.time_taikai_total[widget.ghensuu.nowracecalckukan - 1],
              ),
        );

      if (widget.ghensuu.nowracecalckukan > 0) {
        // ヘルパー関数: 秒数を分と秒にフォーマットし、小数点以下を切り捨てて表示する
        String formatTimeDifference(double difference) {
          // 符号を保持
          String sign = difference.isNegative ? '-' : '+';

          // 絶対値（秒）を整数として取得（小数点以下四捨五入）
          int absoluteSeconds = difference.abs().round();

          if (absoluteSeconds < 60) {
            // 1分未満の場合: 秒で表示
            return "$sign$absoluteSeconds秒";
          } else {
            // 1分以上の場合: 分と秒で表示
            int minutes = absoluteSeconds ~/ 60; // 分
            int remainingSeconds = absoluteSeconds % 60; // 残りの秒
            return "$sign${minutes}分${remainingSeconds}秒";
          }
        }

        int mokuhyojuni = idjununivdata[widget.ghensuu.MYunivid]
            .mokuhyojuni[widget.ghensuu.hyojiracebangou];
        int seedjuni = 0;
        if (widget.ghensuu.hyojiracebangou == 1) seedjuni = 7;
        if (widget.ghensuu.hyojiracebangou == 2) seedjuni = 9;
        int myunivjuni = idjununivdata[widget.ghensuu.MYunivid]
            .tuukajuni_taikai[widget.ghensuu.nowracecalckukan - 1];
        double time_top = timejununivdata[0]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_rank2 = timejununivdata[1]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_mokuhyojuni = timejununivdata[mokuhyojuni]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_mokuhyojuniplus1 = timejununivdata[mokuhyojuni + 1]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_seedjuni = timejununivdata[seedjuni]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_seedjuniplus1 = timejununivdata[seedjuni + 1]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        double time_myuniv = timejununivdata[myunivjuni]
            .time_taikai_total[widget.ghensuu.nowracecalckukan - 1];
        int hyojizumijuni = 0;
        timesastr += "\n";
        if (widget.ghensuu.nowracecalckukan > 1) {
          if (widget.ghensuu.hyojiracebangou == 3) {
            timesastr += "合計(組)順位経過:";
          } else {
            timesastr += "通過(区間)順位経過:";
          }
          for (
            int i_kukan = 0;
            i_kukan < widget.ghensuu.nowracecalckukan;
            i_kukan++
          ) {
            timesastr +=
                "${idjununivdata[widget.ghensuu.MYunivid].tuukajuni_taikai[i_kukan] + 1}(${idjununivdata[widget.ghensuu.MYunivid].kukanjuni_taikai[i_kukan] + 1})-";
          }
          timesastr += "\n";
        }
        if (myunivjuni == 0) {
          timesastr +=
              "2位との差:${formatTimeDifference(time_myuniv - time_rank2)}\n";
        } else {
          timesastr +=
              "トップとの差:${formatTimeDifference(time_myuniv - time_top)}\n";
        }
        if (myunivjuni > mokuhyojuni) {
          timesastr +=
              "目標順位との差:${formatTimeDifference(time_myuniv - time_mokuhyojuni)}\n";
        } else {
          if (!(myunivjuni == 0 && mokuhyojuni == 0)) {
            hyojizumijuni = mokuhyojuni + 1;
            timesastr +=
                "${mokuhyojuni + 2}位との差:${formatTimeDifference(time_myuniv - time_mokuhyojuniplus1)}\n";
          }
        }
        if (widget.ghensuu.hyojiracebangou == 1 ||
            widget.ghensuu.hyojiracebangou == 2) {
          if (myunivjuni > seedjuni) {
            timesastr +=
                "シード権との差:${formatTimeDifference(time_myuniv - time_seedjuni)}\n";
          } else {
            if (hyojizumijuni != seedjuni + 1) {
              timesastr +=
                  "${seedjuni + 2}位との差:${formatTimeDifference(time_myuniv - time_seedjuniplus1)}\n";
            }
          }
        }
      }

      if (widget.ghensuu.nowracecalckukan == 0) {
        rankText =
            "スタート前 (目標順位:${idjununivdata[widget.ghensuu.MYunivid].mokuhyojuni[widget.ghensuu.hyojiracebangou] + 1}位)";
      } else {
        int currentRank = idjununivdata[widget.ghensuu.MYunivid]
            .tuukajuni_taikai[widget.ghensuu.nowracecalckukan - 1];
        String raceUnit = widget.ghensuu.hyojiracebangou == 3 ? "組目" : "区";
        if (widget.ghensuu.nowracecalckukan > 1) {
          int prevRank = idjununivdata[widget.ghensuu.MYunivid]
              .tuukajuni_taikai[widget.ghensuu.nowracecalckukan - 2];
          int diff = currentRank - prevRank;
          String arrow = diff > 0
              ? "↓ $diff"
              : (diff < 0 ? "↑ ${diff.abs()}" : "→");
          rankText =
              "${widget.ghensuu.nowracecalckukan}$raceUnit終了時点 ${currentRank + 1}位 $arrow";
        } else {
          rankText =
              "${widget.ghensuu.nowracecalckukan}$raceUnit終了時点 ${currentRank + 1}位";
        }
      }
    }

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body: Column(
        children: [
          // 目標設定エリア（上部に固定）
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.black26,
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$raceNameの目標順位を設定してください",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "目標：",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(canvasColor: Colors.grey[900]),
                      child: DropdownButton<int>(
                        value: _selectedRank,
                        onChanged: (int? newValue) {
                          if (newValue != null)
                            setState(() => _selectedRank = newValue);
                        },
                        style: const TextStyle(
                          color: HENSUU.LinkColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        items: List.generate(maxRankLimit, (index) => index + 1)
                            .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text("$value位"),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _handleSaveAndAdvance(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HENSUU.buttonColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "決定",
                        style: TextStyle(
                          color: HENSUU.buttonTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // スクロール可能な領域
          Expanded(
            child: ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),
              builder: (context, box, _) {
                List<SenshuData> entrySenshu = box.values.where((s) {
                  final int gIdx = s.gakunen - 1;
                  return s.univid == widget.ghensuu.MYunivid &&
                      raceIdx < s.entrykukan_race.length &&
                      gIdx < s.entrykukan_race[raceIdx].length &&
                      s.entrykukan_race[raceIdx][gIdx] >= -1;
                }).toList();

                entrySenshu.sort((a, b) {
                  int gakunenComp = b.gakunen.compareTo(a.gakunen);
                  return (gakunenComp != 0)
                      ? gakunenComp
                      : a.id.compareTo(b.id);
                });

                String kakutokustr = "";
                kakutokustr = "${_kakutokugoldsilver()}";

                // ListViewの中に説明文と見出しを組み込む
                return ListView(
                  children: [
                    Text("目標達成時獲得金銀 $kakutokustr"),
                    if (widget.ghensuu.hyojiracebangou == 2 &&
                        widget.ghensuu.nowracecalckukan == 5) ...[
                      const SizedBox(height: 20),
                      Text(rankText),
                      //const SizedBox(height: 20),
                      Text(timesastr),
                      const SizedBox(height: 20),
                    ],
                    if (widget.ghensuu.hyojiracebangou == 2 &&
                        widget.ghensuu.nowracecalckukan == 5)
                      TextButton(
                        onPressed: () {
                          // ★こちらも showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '個人順位速報', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder: (context, animation, secondaryAnimation) {
                              // ここに表示したいモーダルのウィジェットを指定
                              return ModalKukanResultListView350(); // const を追加
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
                          "個人順位速報",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),
                    if (widget.ghensuu.hyojiracebangou == 2 &&
                        widget.ghensuu.nowracecalckukan == 5)
                      TextButton(
                        onPressed: () {
                          // ★こちらも showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '通過順位速報', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder: (context, animation, secondaryAnimation) {
                              // ここに表示したいモーダルのウィジェットを指定
                              return ModalKukanResultListViewPass(); // const を追加
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
                          "通過順位速報",
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
                          barrierColor: Colors.black.withOpacity(0.8),
                          barrierDismissible: true,
                          barrierLabel: 'エントリー選手持ちタイム大学ランキング',
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                // ModalKukanEntryListViewはimportされていると仮定
                                // ignore: unnecessary_cast
                                return (const ModalAverageTimeRankingView())
                                    as Widget;
                              },
                          transitionBuilder:
                              (context, animation, secondaryAnimation, child) {
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
                        "エントリー選手持ちタイム大学ランキング",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 255, 0),
                          decoration: TextDecoration.underline,
                          decorationColor: HENSUU.textcolor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // ★ここを showGeneralDialog に変更★
                        showGeneralDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(
                            0.8,
                          ), // モーダルの背景色
                          barrierDismissible: true, // 背景タップで閉じられるようにする
                          barrierLabel: '区間コース確認', // アクセシビリティ用ラベル
                          transitionDuration: const Duration(
                            milliseconds: 300,
                          ), // アニメーション時間
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                // ここに表示したいモーダルのウィジェットを指定
                                return ModalCourseshoukaiView(
                                  racebangou: widget.ghensuu.hyojiracebangou,
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
                        "区間コース確認",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 255, 0),
                          decoration: TextDecoration.underline,
                          decorationColor: HENSUU.textcolor,
                        ),
                      ),
                    ),

                    if (widget.ghensuu.hyojiracebangou != 4)
                      TextButton(
                        onPressed: () {
                          // ★こちらも showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '区間配置確認', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  // ここに表示したいモーダルのウィジェットを指定
                                  return ModalKukanHaitiView(
                                    targetUnivid: widget.ghensuu.MYunivid,
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
                          "区間配置確認",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),
                    if (widget.ghensuu.hyojiracebangou <= 2 ||
                        widget.ghensuu.hyojiracebangou == 5 ||
                        widget.ghensuu.hyojiracebangou == 3)
                      TextButton(
                        onPressed: () {
                          // ★こちらも showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: 'エントリー選手一覧', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  // ここに表示したいモーダルのウィジェットを指定
                                  return ModalKukanEntryListView(); // const を追加
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
                          "エントリー選手一覧",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),
                    if (widget.ghensuu.hyojiracebangou <= 2 ||
                        widget.ghensuu.hyojiracebangou == 5)
                      TextButton(
                        onPressed: () {
                          // ★こちらも showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '当日変更一覧', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  // ここに表示したいモーダルのウィジェットを指定
                                  return ModalTodayChangeListView(); // const を追加
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
                          "当日変更一覧",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),
                    // 説明文
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        "チームの目標順位を決定してください\n\n・目標順位が高いほど目標達成時の金銀獲得量が多くなります。\n・目標順位を下回った位置で襷を受けると、前半無理して突っ込んでのタイム悪化があります(一つだけ下回っても大きく下回っても同じ計算方法で、下回った順位数に関係なくタイム悪化量は決まります。)\n・目標順位を上回った位置で襷を受けると、ほっと一息ついてしまってのタイム悪化があります(上回る順位数が大きいほどタイム悪化量は大きくなります)\n・目標順位が低いほど駅伝の結果順位で得られる名声は小さくなります(ある結果順位で得られる目標順位1位の時の名声を100とすると、目標順位2位の時に得られる名声は1位の1/2である50、目標順位3位の時に得られる名声は1位の1/3である33といった感じで減っていきます)。なお、区間賞で得られる名声は目標順位とは無関係です。",
                        style: TextStyle(
                          color: Colors.orangeAccent.shade100,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // エントリー選手一覧の見出し
                    if (widget.ghensuu.hyojiracebangou == 2)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        color: Colors.white.withOpacity(0.05),
                        child: const Text(
                          "エントリー選手一覧（参考）",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // 選手リスト本体
                    if (widget.ghensuu.hyojiracebangou == 2)
                      if (entrySenshu.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              "エントリー選手データが見つかりません",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      else
                        ...entrySenshu.asMap().entries.map((entry) {
                          final index = entry.key;
                          final senshu = entry.value;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            senshu.name,
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                              fontSize: HENSUU.fontsize_honbun,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "${senshu.gakunen}年生",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: senshu.chousi == 0
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  "体調不良",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                "調子: ${senshu.chousi}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                      ),
                                    ),
                                    _buildDetailButton(senshu),
                                  ],
                                ),
                              ),
                              if (index < entrySenshu.length - 1)
                                const Divider(color: Colors.white12, height: 1),
                            ],
                          );
                        }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
