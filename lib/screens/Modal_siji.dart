import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'dart:math';

// ソート種別
enum InstructionSortType { univId, rank }

class ModalKukanInstructionView extends StatefulWidget {
  const ModalKukanInstructionView({super.key});

  @override
  State<ModalKukanInstructionView> createState() =>
      _ModalKukanInstructionViewState();
}

class _ModalKukanInstructionViewState extends State<ModalKukanInstructionView> {
  InstructionSortType _sortType = InstructionSortType.univId;

  // タイム差を「+○秒」または「+○分○秒」で整形する関数
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

  @override
  void initState() {
    super.initState();
    _setupInitialSiji();
  }

  // 非同期処理用のメソッド
  Future<void> _setupInitialSiji() async {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final List<SenshuData> allSenshuData = senshudataBox.values.toList();

    final List<SenshuData> univFilteredSenshuData = allSenshuData
        .where((s) => s.univid == currentGhensuu.MYunivid)
        .toList();

    final List<SenshuData> gakunenJunUnivFilteredSenshuData =
        univFilteredSenshuData.toList()..sort((a, b) {
          int gakunenCompare = b.gakunen.compareTo(a.gakunen);
          if (gakunenCompare != 0) {
            return gakunenCompare;
          }
          return a.id.compareTo(b.id);
        });

    bool isChanged = false;
    for (int i_id = 0; i_id < gakunenJunUnivFilteredSenshuData.length; i_id++) {
      if (gakunenJunUnivFilteredSenshuData[i_id].entrykukan_race[currentGhensuu
              .hyojiracebangou][gakunenJunUnivFilteredSenshuData[i_id].gakunen -
              1] ==
          currentGhensuu.nowracecalckukan) {
        final senshu = gakunenJunUnivFilteredSenshuData[i_id];
        senshu.sijiflag = currentGhensuu.SijiSelectedOption[i_id];
        await senshu.save();
        isChanged = true;
      }
    }

    if (isChanged && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    final int kukanIndex = currentGhensuu.nowracecalckukan;
    final int raceBangou = currentGhensuu.hyojiracebangou;

    return ValueListenableBuilder(
      valueListenable: senshudataBox.listenable(),
      builder: (context, Box<SenshuData> sBox, _) {
        return ValueListenableBuilder(
          valueListenable: univdataBox.listenable(),
          builder: (context, Box<UnivData> uBox, _) {
            final Map<int, UnivData> univMap = {
              for (var u in uBox.values) u.id: u,
            };

            double topTime = 0;
            if (kukanIndex > 0) {
              topTime = uBox.values
                  .map((u) => u.time_taikai_total[kukanIndex - 1])
                  .reduce((a, b) => a < b ? a : b);
            }

            List<SenshuData> targetSenshu = sBox.values.where((s) {
              final univ = univMap[s.univid];
              if (univ == null || univ.taikaientryflag[raceBangou] != 1) {
                return false;
              }
              return s.entrykukan_race[raceBangou][s.gakunen - 1] == kukanIndex;
            }).toList();

            if (kukanIndex == 0) {
              targetSenshu.sort((a, b) => a.univid.compareTo(b.univid));
            } else {
              if (_sortType == InstructionSortType.univId) {
                targetSenshu.sort((a, b) => a.univid.compareTo(b.univid));
              } else {
                targetSenshu.sort((a, b) {
                  int rankA =
                      univMap[a.univid]?.tuukajuni_taikai[kukanIndex - 1] ?? 99;
                  int rankB =
                      univMap[b.univid]?.tuukajuni_taikai[kukanIndex - 1] ?? 99;
                  return rankA.compareTo(rankB);
                });
              }
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: Text(
                  '${kukanIndex + 1}区 出走前指示',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              body: Column(
                children: [
                  if (kukanIndex > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _sortButton('大学ID順', InstructionSortType.univId),
                          const SizedBox(width: 10),
                          _sortButton('現順位順', InstructionSortType.rank),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: targetSenshu.length,
                      itemBuilder: (context, index) {
                        final senshu = targetSenshu[index];
                        final univ = univMap[senshu.univid]!;

                        String rankText = "";
                        String diffText = "";
                        if (kukanIndex > 0) {
                          int rank = univ.tuukajuni_taikai[kukanIndex - 1] + 1;
                          double myTime =
                              univ.time_taikai_total[kukanIndex - 1];
                          rankText = "現在 $rank位";
                          diffText = _formatTimeDifference(myTime - topTime);
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${univ.name}\n${senshu.name} (${senshu.gakunen}年)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (kukanIndex > 0)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          rankText,
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          diffText,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              255,
                                              1,
                                              1,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _infoChip(
                                    "駅伝男",
                                    senshu.konjou.toString(),
                                    const Color.fromARGB(255, 250, 139, 230),
                                  ),
                                  const SizedBox(width: 8),
                                  if (kukanIndex > 0)
                                    _infoChip(
                                      "平常心",
                                      senshu.heijousin.toString(),
                                      const Color.fromARGB(255, 130, 241, 251),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 【指示】と 詳細ボタンの並び
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "【指示】",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  // 詳細ボタンをここに組み込み
                                  TextButton(
                                    onPressed: () {
                                      showGeneralDialog(
                                        context: context,
                                        barrierColor: Colors.black.withOpacity(
                                          0.8,
                                        ),
                                        barrierDismissible: true,
                                        barrierLabel: '詳細',
                                        transitionDuration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) {
                                              return ModalSenshuDetailView(
                                                senshuId: senshu.id,
                                              );
                                            },
                                        transitionBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _buildInstructionRadio(senshu, kukanIndex),
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

  // ソートボタン
  Widget _sortButton(String label, InstructionSortType type) {
    bool isSelected = _sortType == type;
    return ElevatedButton(
      onPressed: () => setState(() => _sortType = type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  // 特徴チップ
  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: HENSUU.fontsize_honbun),
      ),
    );
  }

  // 指示選択ラジオボタン
  Widget _buildInstructionRadio(SenshuData senshu, int kukanIndex) {
    List<String> labels = kukanIndex == 0
        ? ["なし", "飛出", "待機"]
        : ["なし", "突込", "抑え"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return Flexible(
          child: InkWell(
            onTap: () async {
              senshu.sijiflag = index;
              if (kukanIndex == 0) {
                if (senshu.sijiflag == 0) {
                  senshu.startchokugotobidasiflag = 0;
                  if (senshu.konjou >= 85) {
                    if (Random().nextInt(100) < TEISUU.STARTTOBIDASIKAKURITU) {
                      senshu.startchokugotobidasiflag = 1;
                    }
                  }
                } else if (senshu.sijiflag == 1) {
                  senshu.startchokugotobidasiflag = 1;
                } else if (senshu.sijiflag == 2) {
                  senshu.startchokugotobidasiflag = 0;
                }
              }
              await senshu.save();
              setState(() {});
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<int>(
                  value: index,
                  groupValue: senshu.sijiflag,
                  onChanged: (val) async {
                    senshu.sijiflag = val!;
                    if (kukanIndex == 0) {
                      if (senshu.sijiflag == 0) {
                        senshu.startchokugotobidasiflag = 0;
                        if (senshu.konjou >= 85) {
                          if (Random().nextInt(100) <
                              TEISUU.STARTTOBIDASIKAKURITU) {
                            senshu.startchokugotobidasiflag = 1;
                          }
                        }
                      } else if (senshu.sijiflag == 1) {
                        senshu.startchokugotobidasiflag = 1;
                      } else if (senshu.sijiflag == 2) {
                        senshu.startchokugotobidasiflag = 0;
                      }
                    }
                    await senshu.save();
                    setState(() {});
                  },
                  activeColor: Colors.lightBlueAccent,
                ),
                Expanded(
                  child: Text(
                    labels[index],
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
