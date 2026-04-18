import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';
import 'package:ekiden/screens/Modal_Taichoufuryou.dart';

class AllToujitsuHenkouScreen extends StatefulWidget {
  // targetGroup: 0 = 通常 または 正月駅伝(往路1-5区), 1 = 正月駅伝(復路6-10区)
  final int targetGroup;
  const AllToujitsuHenkouScreen({super.key, this.targetGroup = 0});

  @override
  State<AllToujitsuHenkouScreen> createState() =>
      _AllToujitsuHenkouScreenState();
}

class _AllToujitsuHenkouScreenState extends State<AllToujitsuHenkouScreen> {
  late final Box<Ghensuu> ghensuuBox;
  late final Box<SenshuData> senshudataBox;
  late final Box<UnivData> univBox;

  Ghensuu? currentGhensuu;
  int? selectedUnivId;
  List<UnivData> entryUnivList = [];

  List<SenshuData> myTeamSenshu = [];
  List<SenshuData> hokenSenshu = [];
  Map<int, int> changeMap = {};

  int kukansuu = 0;
  int koutaikanouninzuu = 0;
  bool _isProcessing = false;

  bool _isAlreadyFixed = false;
  bool _isMyUniv = false;

  @override
  void initState() {
    super.initState();
    _initializeAllData();
  }

  void _initializeAllData() {
    ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    senshudataBox = Hive.box<SenshuData>('senshuBox');
    univBox = Hive.box<UnivData>('univBox');

    currentGhensuu = ghensuuBox.getAt(0);
    if (currentGhensuu == null) return;

    final int raceIndex = currentGhensuu!.hyojiracebangou;
    entryUnivList = univBox.values
        .where((u) => u.taikaientryflag[raceIndex] == 1)
        .toList();
    entryUnivList.sort((a, b) => a.id.compareTo(b.id));

    if (entryUnivList.isNotEmpty) {
      selectedUnivId = entryUnivList[0].id;
      _refreshSenshuData(selectedUnivId!);
    }
  }

  void _refreshSenshuData(int univId) {
    if (currentGhensuu == null) return;
    final int raceIndex = currentGhensuu!.hyojiracebangou;

    bool isMy = (univId == currentGhensuu!.MYunivid);

    List<SenshuData> allSenshu = senshudataBox.values
        .where((s) => s.univid == univId)
        .toList();

    bool isWithinTargetKukan(int kukan) {
      if (raceIndex == 2) {
        if (widget.targetGroup == 0) return kukan < 5;
        if (widget.targetGroup == 1) return kukan >= 5;
      }
      return true;
    }

    bool fixed = allSenshu.any((s) {
      final int val = s.entrykukan_race[raceIndex][s.gakunen - 1];
      if (val <= -100) {
        int originalKukan = (val * -1) - 100;
        return isWithinTargetKukan(originalKukan);
      }
      return false;
    });

    List<SenshuData> entryList = [];
    List<SenshuData> hokenList = [];

    for (var s in allSenshu) {
      final int kukan = s.entrykukan_race[raceIndex][s.gakunen - 1];
      if (kukan == -2) continue;

      if (kukan >= 0) {
        if (isWithinTargetKukan(kukan)) {
          entryList.add(s);
        }
      } else if (kukan == -1) {
        hokenList.add(s);
      }
    }

    entryList.sort((a, b) {
      final int ak = a.entrykukan_race[raceIndex][a.gakunen - 1];
      final int bk = b.entrykukan_race[raceIndex][b.gakunen - 1];
      return ak.compareTo(bk);
    });

    hokenList.sort((a, b) {
      int g = b.gakunen.compareTo(a.gakunen);
      return g != 0 ? g : a.id.compareTo(b.id);
    });

    kukansuu = currentGhensuu!.kukansuu_taikaigoto[raceIndex];
    if (raceIndex == 2) {
      koutaikanouninzuu = 4;
    } else {
      if (kukansuu <= 6)
        koutaikanouninzuu = 2;
      else if (kukansuu <= 8)
        koutaikanouninzuu = 3;
      else
        koutaikanouninzuu = 6;
    }

    setState(() {
      _isMyUniv = isMy;
      _isAlreadyFixed = fixed;
      myTeamSenshu = entryList;
      hokenSenshu = hokenList;
      changeMap = {for (var s in myTeamSenshu) s.id: s.id};
    });
  }

  // 【追加】区間内順位を再計算する関数
  Future<void> _kukannaiJunSaikeisan(
    Ghensuu currentGhensuu,
    List<SenshuData> idJunSenshuData,
  ) async {
    for (var senshu in idJunSenshuData) {
      for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
        senshu.kukannaijuni[i] = TEISUU.DEFAULTJUNI;
      }
      await senshu.save();
    }

    final int raceIdx = currentGhensuu.hyojiracebangou;
    for (
      int iKukan = 0;
      iKukan < currentGhensuu.kukansuu_taikaigoto[raceIdx];
      iKukan++
    ) {
      List<SenshuData> entryFilteredSenshuData = idJunSenshuData.where((s) {
        return s.entrykukan_race[raceIdx][s.gakunen - 1] == iKukan;
      }).toList();

      for (
        int iKirokubangou = 0;
        iKirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
        iKirokubangou++
      ) {
        List<SenshuData> timeJunSenshuData = entryFilteredSenshuData.toList()
          ..sort(
            (a, b) => a.time_bestkiroku[iKirokubangou].compareTo(
              b.time_bestkiroku[iKirokubangou],
            ),
          );

        for (int iJuni = 0; iJuni < timeJunSenshuData.length; iJuni++) {
          timeJunSenshuData[iJuni].kukannaijuni[iKirokubangou] = iJuni;
          await timeJunSenshuData[iJuni].save();
        }
      }
    }
  }

  String _getSenshuDisplayName(SenshuData s) {
    if (s.chousi == 0) {
      return '【体調不良】${s.name} (${s.gakunen}年)';
    } else {
      return '${s.name} (${s.gakunen}年) 調子${s.chousi}';
    }
  }

  void _onDropdownChanged(int entrySenshuId, int? newSenshuId) {
    if (newSenshuId == null || _isAlreadyFixed || _isMyUniv) return;
    setState(() => changeMap[entrySenshuId] = newSenshuId);
  }

  void _confirmChanges() async {
    if (_isAlreadyFixed || _isMyUniv || currentGhensuu == null) return;

    setState(() => _isProcessing = true);
    try {
      int changeCount = 0;
      changeMap.forEach((oldId, newId) {
        if (oldId != newId) changeCount++;
      });

      if (changeCount > koutaikanouninzuu) {
        _showSnackBar('当日変更は累計最大$koutaikanouninzuu名までです。');
        setState(() => _isProcessing = false);
        return;
      }

      final substitutedIds = changeMap.entries
          .where((e) => e.key != e.value)
          .map((e) => e.value)
          .toList();
      if (substitutedIds.length > substitutedIds.toSet().length) {
        _showSnackBar('同じ選手が複数の区間に選択されています。');
        setState(() => _isProcessing = false);
        return;
      }

      setState(() => _isProcessing = false);
      final confirm =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.black,
              title: const Text('変更の確定', style: TextStyle(color: Colors.white)),
              content: Text(
                changeCount > 0 ? '$changeCount件の変更を確定しますか？' : '変更なしで確定しますか？',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    '確定',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      setState(() => _isProcessing = true);
      final int raceIdx = currentGhensuu!.hyojiracebangou;

      // 1. 選手の入れ替え保存
      for (var entry in changeMap.entries) {
        if (entry.key == entry.value) continue;
        SenshuData oldS = senshudataBox.values.firstWhere(
          (s) => s.id == entry.key,
        );
        SenshuData newS = senshudataBox.values.firstWhere(
          (s) => s.id == entry.value,
        );
        final int kukan = oldS.entrykukan_race[raceIdx][oldS.gakunen - 1];

        oldS.entrykukan_race[raceIdx][oldS.gakunen - 1] = -(100 + kukan);
        newS.entrykukan_race[raceIdx][newS.gakunen - 1] = kukan;
        await oldS.save();
        await newS.save();
      }

      // 2. 【重要】区間内順位の再計算（全選手対象）
      await _kukannaiJunSaikeisan(
        currentGhensuu!,
        senshudataBox.values.toList(),
      );

      _showSnackBar('保存と順位の再計算が完了しました。');
      _refreshSenshuData(selectedUnivId!);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '詳細',
          pageBuilder: (context, _, __) =>
              ModalSenshuDetailView(senshuId: senshu.id),
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

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    );
    const double bottomButtonHeight = 85.0;

    String statusMessage = "";
    Color statusColor = Colors.transparent;

    if (_isMyUniv) {
      statusMessage = '⚠️ 自大学の変更は前の画面で行ってください。';
      statusColor = Colors.orangeAccent.withOpacity(0.8);
    } else if (_isAlreadyFixed) {
      statusMessage = '⚠️ この大学は確定済みのため、変更できません。';
      statusColor = Colors.redAccent.withOpacity(0.8);
    }

    bool canEdit = !_isProcessing && !_isAlreadyFixed && !_isMyUniv;
    String titleText = '他校当日変更';
    if (currentGhensuu?.hyojiracebangou == 2) {
      titleText += widget.targetGroup == 0 ? '(1-5区)' : '(6-10区)';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey[900],
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedUnivId,
                    dropdownColor: Colors.black,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    items: entryUnivList
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedUnivId = val;
                          _refreshSenshuData(val);
                        });
                      }
                    },
                  ),
                ),
              ),
              if (statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: statusColor,
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    bottomButtonHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          // ★ここを showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // モーダルの背景色
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '体調不良者一覧', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder: (context, animation, secondaryAnimation) {
                              // ここに表示したいモーダルのウィジェットを指定
                              return ModalIllnessSenshuListView(); // const を追加
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
                          "体調不良者一覧",
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
                                    racebangou: currentGhensuu!.hyojiracebangou,
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
                          "区間コース確認",
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
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '今季タイム一覧表', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
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
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '駅伝出場履歴一覧(選手ごと)', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
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
                            barrierDismissible: true, // 背景タップで閉じられるようにする
                            barrierLabel: '駅伝出場履歴一覧(区間ごと)', // アクセシビリティ用ラベル
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ), // アニメーション時間
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
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
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),

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
                                    targetUnivid: selectedUnivId!,
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
                      const SizedBox(height: 20),

                      _buildRuleCard(baseTextStyle),
                      const SizedBox(height: 20),
                      Text(
                        '🏃 区間エントリー選手',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const Divider(color: Colors.white),
                      ...myTeamSenshu.map(
                        (s) => _buildEntrySenshuItem(s, baseTextStyle),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        '📋 補欠選手一覧',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const Divider(color: Colors.white),
                      ...hokenSenshu.map(
                        (h) => _buildHokenSenshuItem(h, baseTextStyle),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: bottomButtonHeight,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canEdit ? _confirmChanges : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canEdit ? Colors.blue[700] : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isMyUniv
                        ? '自大学は変更不可'
                        : (_isAlreadyFixed ? '確定済み' : '確定して保存する'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing) ...[
            const ModalBarrier(color: Colors.black54, dismissible: false),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleCard(TextStyle style) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '✅ 当日変更ルール\n'
        '1. 最大${koutaikanouninzuu}名まで交代可能\n'
        '2. 区間選手と補欠選手の交代のみ',
        style: style.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEntrySenshuItem(SenshuData s, TextStyle baseStyle) {
    final int raceIdx = currentGhensuu!.hyojiracebangou;
    final int kukan = s.entrykukan_race[raceIdx][s.gakunen - 1];
    int currentValue = changeMap[s.id] ?? s.id;
    bool isEditable = !_isProcessing && !_isAlreadyFixed && !_isMyUniv;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${kukan + 1}区',
                style: baseStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSenshuDisplayName(s),
                  style: baseStyle,
                  overflow: TextOverflow.visible,
                ),
              ),
              _buildDetailButton(s),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[900],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentValue,
                isExpanded: true,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                onChanged: isEditable
                    ? (val) => _onDropdownChanged(s.id, val)
                    : null,
                items: [
                  DropdownMenuItem(
                    value: s.id,
                    child: const Text(
                      "変更しない",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...hokenSenshu.map(
                    (h) => DropdownMenuItem(
                      value: h.id,
                      child: Text(
                        _getSenshuDisplayName(h),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHokenSenshuItem(SenshuData h, TextStyle baseStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getSenshuDisplayName(h),
              style: baseStyle,
              overflow: TextOverflow.visible,
            ),
          ),
          _buildDetailButton(h),
        ],
      ),
    );
  }
}
