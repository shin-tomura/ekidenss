import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // ※fl_chartパッケージが必要です
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart'; // ★ 追加

class ModalTimeDifferenceGraph extends StatefulWidget {
  const ModalTimeDifferenceGraph({super.key});

  @override
  State<ModalTimeDifferenceGraph> createState() =>
      _ModalTimeDifferenceGraphState();
}

class _ModalTimeDifferenceGraphState extends State<ModalTimeDifferenceGraph> {
  // --- モード切替 ---
  bool _isRankMode = false; // false: タイム差推移モード, true: 順位推移モード

  // --- タイム差モード用の設定 ---
  bool _isCompareByRank = true;
  int _targetRankIndex = 0; // -1: 全大学平均, -2: 大会記録, 0以上: 指定順位
  int? _targetUnivId; // -1: 全大学平均, -2: 大会記録, その他: 大学ID

  // --- 共通: 表示する大学（最大4つ） ---
  final List<int?> _selectedUnivIds = [null, null, null, null];
  final List<Color> _lineColors = [
    Colors.cyanAccent,
    Colors.yellowAccent,
    Colors.pinkAccent,
    Colors.lightGreenAccent,
  ];

  String kustring = "";

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  // ★ 追加：Hiveから保存された設定を読み込む
  void _loadSavedSettings() {
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData? kantoku = kantokuBox.get('KantokuData');
    if (kantoku != null) {
      // yobiint2[24] を初期化済みフラグとして使用 (1なら保存データあり)
      if (kantoku.yobiint2[24] == 1) {
        _isRankMode = kantoku.yobiint2[25] == 1;
        _isCompareByRank = kantoku.yobiint2[26] == 1;
        _targetRankIndex = kantoku.yobiint2[27];
        _targetUnivId = kantoku.yobiint2[28] == -999
            ? null
            : kantoku.yobiint2[28];
        _selectedUnivIds[0] = kantoku.yobiint2[29] == -999
            ? null
            : kantoku.yobiint2[29];
        _selectedUnivIds[1] = kantoku.yobiint2[30] == -999
            ? null
            : kantoku.yobiint2[30];
        _selectedUnivIds[2] = kantoku.yobiint2[31] == -999
            ? null
            : kantoku.yobiint2[31];
        _selectedUnivIds[3] = kantoku.yobiint2[32] == -999
            ? null
            : kantoku.yobiint2[32];
      }
    }
  }

  // ★ 追加：現在の設定をHiveに保存する
  Future<void> _saveSettings() async {
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData? kantoku = kantokuBox.get('KantokuData');
    if (kantoku != null) {
      kantoku.yobiint2[24] = 1; // 保存済みフラグ
      kantoku.yobiint2[25] = _isRankMode ? 1 : 0;
      kantoku.yobiint2[26] = _isCompareByRank ? 1 : 0;
      kantoku.yobiint2[27] = _targetRankIndex;
      kantoku.yobiint2[28] = _targetUnivId ?? -999;
      kantoku.yobiint2[29] = _selectedUnivIds[0] ?? -999;
      kantoku.yobiint2[30] = _selectedUnivIds[1] ?? -999;
      kantoku.yobiint2[31] = _selectedUnivIds[2] ?? -999;
      kantoku.yobiint2[32] = _selectedUnivIds[3] ?? -999;
      await kantoku.save();
    }
  }

  String _formatDiffSeconds(double diffSeconds) {
    if (diffSeconds == 0) return '±0秒';
    final String sign = diffSeconds > 0 ? '+' : '-';
    final int absSeconds = diffSeconds.abs().round();
    final int m = absSeconds ~/ 60;
    final int s = absSeconds % 60;
    if (m > 0) return '$sign$m分$s秒';
    return '$sign$s秒';
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    // KantokuDataボックスの取得
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData? kantoku = kantokuBox.get('KantokuData');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
        if (currentGhensuu == null)
          return const Center(child: Text('データがありません'));

        final int raceBangou = currentGhensuu.hyojiracebangou;
        final int calculatedKukans = currentGhensuu.nowracecalckukan;

        // 最終区のインデックスを計算
        final int lastKukanIndex =
            currentGhensuu.kukansuu_taikaigoto.length > raceBangou
            ? currentGhensuu.kukansuu_taikaigoto[raceBangou] - 1
            : -1;

        _selectedUnivIds[0] ??= currentGhensuu.MYunivid;
        _targetUnivId ??= currentGhensuu.MYunivid;

        final List<UnivData> idjunAllUnivs = univdataBox.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        bool settingsAdjusted = false;

        // ★ フェイルセーフ（「全大学平均(-1)」「大会記録(-2)」の時はスキップする）
        if (_selectedUnivIds[0] != null &&
            _selectedUnivIds[0] != -1 &&
            _selectedUnivIds[0] != -2) {
          if (_selectedUnivIds[0]! >= idjunAllUnivs.length ||
              idjunAllUnivs[_selectedUnivIds[0]!].taikaientryflag[currentGhensuu
                      .hyojiracebangou] !=
                  1) {
            for (int i = 0; i < idjunAllUnivs.length; i++) {
              if (idjunAllUnivs[i].taikaientryflag[currentGhensuu
                      .hyojiracebangou] ==
                  1) {
                _selectedUnivIds[0] = i;
                settingsAdjusted = true;
                break;
              }
            }
          }
        }
        if (_targetUnivId != null &&
            _targetUnivId != -1 &&
            _targetUnivId != -2) {
          if (_targetUnivId! >= idjunAllUnivs.length ||
              idjunAllUnivs[_targetUnivId!].taikaientryflag[currentGhensuu
                      .hyojiracebangou] !=
                  1) {
            for (int i = 0; i < idjunAllUnivs.length; i++) {
              if (idjunAllUnivs[i].taikaientryflag[currentGhensuu
                      .hyojiracebangou] ==
                  1) {
                _targetUnivId = i;
                settingsAdjusted = true;
                break;
              }
            }
          }
        }

        // ★ 追加: 表示大学1〜3についても出場していなければnullにリセットする
        for (int i = 1; i < 4; i++) {
          if (_selectedUnivIds[i] != null &&
              _selectedUnivIds[i] != -1 &&
              _selectedUnivIds[i] != -2) {
            if (_selectedUnivIds[i]! >= idjunAllUnivs.length ||
                idjunAllUnivs[_selectedUnivIds[i]!]
                        .taikaientryflag[currentGhensuu.hyojiracebangou] !=
                    1) {
              _selectedUnivIds[i] = null;
              settingsAdjusted = true;
            }
          }
        }

        // フェイルセーフで補正が入った場合は保存しておく
        if (settingsAdjusted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _saveSettings());
        }

        kustring = (currentGhensuu.hyojiracebangou == 3) ? "組" : "区";

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> participants = univdataBox.values.where((
              univ,
            ) {
              return univ.taikaientryflag.length > raceBangou &&
                  univ.taikaientryflag[raceBangou] == 1;
            }).toList();

            if (participants.isEmpty || calculatedKukans == 0) {
              return Scaffold(
                backgroundColor: HENSUU.backgroundcolor,
                appBar: AppBar(
                  title: const Text(
                    'レース分析チャート',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                ),
                body: const Center(
                  child: Text(
                    '表示できるデータがありません',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            List<int> activeIds = [];
            List<Color> activeColors = [];
            for (int i = 0; i < 4; i++) {
              if (_selectedUnivIds[i] != null) {
                activeIds.add(_selectedUnivIds[i]!);
                activeColors.add(_lineColors[i]);
              }
            }

            List<List<FlSpot>> allSpots = List.generate(
              activeIds.length,
              (_) => [],
            );
            double maxY = 0;
            double minY = 0;

            // ---------------------------------------------------
            // モードによるデータ生成の分岐
            // ---------------------------------------------------
            if (_isRankMode) {
              // 【順位推移モード】
              for (int k = 0; k < calculatedKukans; k++) {
                // まず区間の平均順位を計算（全大学平均用）
                int totalRank = 0;
                int countRank = 0;
                for (var u in participants) {
                  if (u.tuukajuni_taikai.length > k &&
                      u.tuukajuni_taikai[k] != TEISUU.DEFAULTJUNI) {
                    totalRank += u.tuukajuni_taikai[k] + 1;
                    countRank++;
                  }
                }
                double avgRank = countRank > 0
                    ? totalRank / countRank
                    : TEISUU.DEFAULTJUNI.toDouble();

                for (int i = 0; i < activeIds.length; i++) {
                  int uId = activeIds[i];
                  if (uId == -1) {
                    // 全大学平均の場合
                    if (avgRank != TEISUU.DEFAULTJUNI.toDouble()) {
                      double plotY = -avgRank;
                      allSpots[i].add(FlSpot(k.toDouble(), plotY));
                    }
                  } else if (uId == -2) {
                    // 大会記録の場合は順位がないため描画をスキップする
                    continue;
                  } else {
                    // 特定の大学の場合
                    UnivData? selectedUniv = participants
                        .where((u) => u.id == uId)
                        .firstOrNull;
                    if (selectedUniv != null &&
                        selectedUniv.tuukajuni_taikai.length > k) {
                      int juni = selectedUniv.tuukajuni_taikai[k];
                      if (juni != TEISUU.DEFAULTJUNI) {
                        double plotY = -(juni + 1).toDouble();
                        allSpots[i].add(FlSpot(k.toDouble(), plotY));
                      }
                    }
                  }
                }
              }
              maxY = -0.5;
              minY = -(participants.length.toDouble() + 0.5);
            } else {
              // 【タイム差推移モード】
              for (int k = 0; k < calculatedKukans; k++) {
                // 区間の平均タイムを計算（全大学平均用）
                double totalTime = 0;
                int countTime = 0;
                for (var u in participants) {
                  if (u.time_taikai_total.length > k &&
                      u.time_taikai_total[k] != TEISUU.DEFAULTTIME) {
                    totalTime += u.time_taikai_total[k];
                    countTime++;
                  }
                }
                double avgTime = countTime > 0
                    ? totalTime / countTime
                    : TEISUU.DEFAULTTIME;

                double targetTime = TEISUU.DEFAULTTIME;
                bool hasTargetTime = false;

                // ターゲットタイムの決定
                if (_isCompareByRank) {
                  if (_targetRankIndex == -1) {
                    // 全大学平均
                    targetTime = avgTime;
                    hasTargetTime = countTime > 0;
                  } else if (_targetRankIndex == -2) {
                    // 大会記録
                    if (kantoku != null) {
                      final int recInt = (k == lastKukanIndex)
                          ? kantoku.yobiint4[20]
                          : kantoku.yobiint3[k];
                      if (recInt != 0 && recInt != TEISUU.DEFAULTTIME) {
                        targetTime = recInt.toDouble();
                        hasTargetTime = true;
                      }
                    }
                  } else {
                    // 各順位ライン
                    List<UnivData> sortedForKukan = List.from(participants);
                    sortedForKukan.removeWhere(
                      (u) =>
                          u.time_taikai_total.length <= k ||
                          u.time_taikai_total[k] == TEISUU.DEFAULTTIME,
                    );
                    sortedForKukan.sort(
                      (a, b) => a.time_taikai_total[k].compareTo(
                        b.time_taikai_total[k],
                      ),
                    );

                    if (_targetRankIndex < sortedForKukan.length) {
                      targetTime =
                          sortedForKukan[_targetRankIndex].time_taikai_total[k];
                      hasTargetTime = true;
                    }
                  }
                } else {
                  if (_targetUnivId == -1) {
                    // 全大学平均
                    targetTime = avgTime;
                    hasTargetTime = countTime > 0;
                  } else if (_targetUnivId == -2) {
                    // 比較基準が「大学」の時の「大会記録」
                    if (kantoku != null) {
                      final int recInt = (k == lastKukanIndex)
                          ? kantoku.yobiint4[20]
                          : kantoku.yobiint3[k];
                      if (recInt != 0 && recInt != TEISUU.DEFAULTTIME) {
                        targetTime = recInt.toDouble();
                        hasTargetTime = true;
                      }
                    }
                  } else {
                    // 特定の大学
                    UnivData? targetUniv = participants
                        .where((u) => u.id == _targetUnivId)
                        .firstOrNull;
                    if (targetUniv != null &&
                        targetUniv.time_taikai_total.length > k &&
                        targetUniv.time_taikai_total[k] != TEISUU.DEFAULTTIME) {
                      targetTime = targetUniv.time_taikai_total[k];
                      hasTargetTime = true;
                    }
                  }
                }

                if (hasTargetTime) {
                  for (int i = 0; i < activeIds.length; i++) {
                    int uId = activeIds[i];
                    double myTime = TEISUU.DEFAULTTIME;

                    if (uId == -1) {
                      myTime = avgTime;
                    } else if (uId == -2) {
                      // 比較対象として大会記録が選ばれた場合
                      if (kantoku != null) {
                        final int recInt = (k == lastKukanIndex)
                            ? kantoku.yobiint4[20]
                            : kantoku.yobiint3[k];
                        if (recInt != 0 && recInt != TEISUU.DEFAULTTIME) {
                          myTime = recInt.toDouble();
                        }
                      }
                    } else {
                      UnivData? selectedUniv = participants
                          .where((u) => u.id == uId)
                          .firstOrNull;
                      if (selectedUniv != null &&
                          selectedUniv.time_taikai_total.length > k) {
                        myTime = selectedUniv.time_taikai_total[k];
                      }
                    }

                    if (myTime != TEISUU.DEFAULTTIME) {
                      double diffSeconds = myTime - targetTime;
                      double plotY = -diffSeconds;
                      allSpots[i].add(FlSpot(k.toDouble(), plotY));

                      if (plotY > maxY) maxY = plotY;
                      if (plotY < minY) minY = plotY;
                    }
                  }
                }
              }
              maxY = maxY + 60;
              minY = minY - 60;
            }

            List<LineChartBarData> lineBarsData = [];
            for (int i = 0; i < activeIds.length; i++) {
              lineBarsData.add(
                LineChartBarData(
                  spots: allSpots[i],
                  isCurved: false,
                  color: activeColors[i],
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: activeColors[i],
                          strokeWidth: 1,
                          strokeColor: Colors.black,
                        ),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              );
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  'レース分析チャート',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                children: [
                  // --- コントロールパネル ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        // モード切替ボタン
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isRankMode
                                      ? Colors.blue
                                      : Colors.grey[800],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() => _isRankMode = false);
                                  _saveSettings(); // ★ 追加
                                },
                                child: const Text(
                                  'タイム差推移',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRankMode
                                      ? Colors.blue
                                      : Colors.grey[800],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() => _isRankMode = true);
                                  _saveSettings(); // ★ 追加
                                },
                                child: const Text(
                                  '順位推移',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // タイム差モードの時のみ「比較基準」を表示
                        if (!_isRankMode) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: DropdownButtonFormField<bool>(
                                  isExpanded: true,
                                  dropdownColor: Colors.grey[800],
                                  style: const TextStyle(color: Colors.white),
                                  value: _isCompareByRank,
                                  decoration: const InputDecoration(
                                    labelText: '比較基準',
                                    labelStyle: TextStyle(color: Colors.grey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: true,
                                      child: Text('順位'),
                                    ),
                                    DropdownMenuItem(
                                      value: false,
                                      child: Text('大学'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _isCompareByRank = value);
                                      _saveSettings(); // ★ 追加
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 6,
                                child: _isCompareByRank
                                    ? DropdownButtonFormField<int>(
                                        isExpanded: true,
                                        dropdownColor: Colors.grey[800],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        value: _targetRankIndex,
                                        decoration: const InputDecoration(
                                          labelText: 'ターゲット',
                                          labelStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                            value: -1,
                                            child: Text('全大学平均'),
                                          ),
                                          const DropdownMenuItem(
                                            value: -2,
                                            child: Text(
                                              '大会記録',
                                              style: TextStyle(
                                                color: Colors.yellowAccent,
                                              ),
                                            ),
                                          ),
                                          ...List.generate(
                                            participants.length,
                                            (index) {
                                              return DropdownMenuItem(
                                                value: index,
                                                child: Text('${index + 1}位ライン'),
                                              );
                                            },
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                              () => _targetRankIndex = value,
                                            );
                                            _saveSettings(); // ★ 追加
                                          }
                                        },
                                      )
                                    : DropdownButtonFormField<int>(
                                        isExpanded: true,
                                        dropdownColor: Colors.grey[800],
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        value: _targetUnivId,
                                        decoration: const InputDecoration(
                                          labelText: 'ターゲット大学',
                                          labelStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                            value: -1,
                                            child: Text('全大学平均'),
                                          ),
                                          const DropdownMenuItem(
                                            value: -2,
                                            child: Text(
                                              '大会記録',
                                              style: TextStyle(
                                                color: Colors.yellowAccent,
                                              ),
                                            ),
                                          ),
                                          ...participants.map((univ) {
                                            return DropdownMenuItem(
                                              value: univ.id,
                                              child: Text(
                                                univ.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                              () => _targetUnivId = value,
                                            );
                                            _saveSettings(); // ★ 追加
                                          }
                                        },
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        // 大学1 と 大学2
                        Row(
                          children: [
                            _buildUnivDropdown(0, participants),
                            const SizedBox(width: 8),
                            _buildUnivDropdown(1, participants),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 大学3 と 大学4
                        Row(
                          children: [
                            _buildUnivDropdown(2, participants),
                            const SizedBox(width: 8),
                            _buildUnivDropdown(3, participants),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- グラフ描画エリア ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 24.0,
                        left: 16.0,
                        top: 8.0,
                        bottom: 24.0,
                      ),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (calculatedKukans - 1).toDouble() < 1
                              ? 1
                              : (calculatedKukans - 1).toDouble(),
                          minY: minY,
                          maxY: maxY,
                          // ゼロ地点の強調（タイム差モードのみ表示）
                          extraLinesData: ExtraLinesData(
                            horizontalLines: !_isRankMode
                                ? [
                                    HorizontalLine(
                                      y: 0,
                                      color: Colors.redAccent.withOpacity(0.8),
                                      strokeWidth: 2,
                                      dashArray: [5, 5],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment.topRight,
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                          bottom: 5,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                        ),
                                        labelResolver: (line) {
                                          if (_isCompareByRank) {
                                            if (_targetRankIndex == -1)
                                              return '全大学平均基準';
                                            if (_targetRankIndex == -2)
                                              return '大会記録基準';
                                            return '${_targetRankIndex + 1}位基準';
                                          } else {
                                            if (_targetUnivId == -1)
                                              return '全大学平均基準';
                                            if (_targetUnivId == -2)
                                              return '大会記録基準';
                                            UnivData? tUniv = participants
                                                .where(
                                                  (u) => u.id == _targetUnivId,
                                                )
                                                .firstOrNull;
                                            return tUniv != null
                                                ? '${tUniv.name}基準'
                                                : '基準';
                                          }
                                        },
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: _isRankMode ? 5 : 60,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: Colors.white12, strokeWidth: 1),
                            getDrawingVerticalLine: (value) =>
                                FlLine(color: Colors.white12, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 != 0)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${value.toInt() + 1}$kustring',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                interval: _isRankMode ? 5 : 60,
                                getTitlesWidget: (value, meta) {
                                  final double interval = _isRankMode
                                      ? 5.0
                                      : 60.0;
                                  if ((value % interval).abs() > 0.001)
                                    return const SizedBox.shrink();

                                  if (value == 0 && !_isRankMode)
                                    return const SizedBox.shrink();

                                  if (_isRankMode) {
                                    final int rank = -value.toInt();
                                    if (rank <= 0 || rank > participants.length)
                                      return const SizedBox.shrink();
                                    return Text(
                                      '$rank位',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    );
                                  } else {
                                    final double originalDiff = -value;
                                    final int minutes = (originalDiff / 60)
                                        .round();
                                    return Text(
                                      minutes > 0 ? '+$minutes分' : '$minutes分',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          lineBarsData: lineBarsData,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (LineBarSpot touchedSpot) =>
                                  Colors.blueGrey.withOpacity(0.95),
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final int barIndex = spot.barIndex;
                                      final int univId = activeIds[barIndex];
                                      final Color lineColor =
                                          activeColors[barIndex];

                                      final int kukanIndex = spot.x.toInt();
                                      String univName = '不明';

                                      if (univId == -1) {
                                        univName = '全大学平均';
                                      } else if (univId == -2) {
                                        univName = '大会記録';
                                      } else {
                                        final UnivData? selectedUniv =
                                            participants
                                                .where((u) => u.id == univId)
                                                .firstOrNull;
                                        if (selectedUniv != null) {
                                          univName = selectedUniv.name;
                                        }
                                      }

                                      if (_isRankMode) {
                                        final double rank = -spot.y;
                                        String rankDisplay;
                                        if (univId == -1) {
                                          rankDisplay =
                                              '${rank.toStringAsFixed(1)}位';
                                        } else if (univId == -2) {
                                          rankDisplay = '---';
                                        } else {
                                          rankDisplay = '${rank.toInt()}位';
                                        }
                                        return LineTooltipItem(
                                          '$univName\n$rankDisplay',
                                          TextStyle(
                                            color: lineColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        );
                                      } else {
                                        final String diffStr =
                                            _formatDiffSeconds(-spot.y);
                                        String rankStr = '---';
                                        if (univId == -1) {
                                          rankStr = '平均';
                                        } else if (univId == -2) {
                                          rankStr = '記録';
                                        } else {
                                          final UnivData? selectedUniv =
                                              participants
                                                  .where((u) => u.id == univId)
                                                  .firstOrNull;
                                          if (selectedUniv != null &&
                                              selectedUniv
                                                      .tuukajuni_taikai
                                                      .length >
                                                  kukanIndex) {
                                            final int juni = selectedUniv
                                                .tuukajuni_taikai[kukanIndex];
                                            if (juni != TEISUU.DEFAULTJUNI)
                                              rankStr = '${juni + 1}位';
                                          }
                                        }
                                        return LineTooltipItem(
                                          '$univName\n$rankStr / $diffStr',
                                          TextStyle(
                                            color: lineColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        );
                                      }
                                    }).toList();
                                  },
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildUnivDropdown(int index, List<UnivData> participants) {
    return Expanded(
      child: DropdownButtonFormField<int?>(
        isExpanded: true,
        dropdownColor: Colors.grey[800],
        style: const TextStyle(color: Colors.white, fontSize: 13),
        value: _selectedUnivIds[index],
        decoration: InputDecoration(
          labelText: '表示大学${index + 1}',
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 0,
          ),
          prefixIcon: Icon(Icons.square, color: _lineColors[index], size: 14),
        ),
        items: [
          if (index != 0)
            const DropdownMenuItem(
              value: null,
              child: Text('未選択', style: TextStyle(color: Colors.grey)),
            ),
          const DropdownMenuItem(value: -1, child: Text('全大学平均')),
          const DropdownMenuItem(
            value: -2,
            child: Text('大会記録', style: TextStyle(color: Colors.yellowAccent)),
          ),
          ...participants.map((univ) {
            return DropdownMenuItem(
              value: univ.id,
              child: Text(univ.name, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (value) {
          setState(() => _selectedUnivIds[index] = value);
          _saveSettings(); // ★ 追加
        },
      ),
    );
  }
}
