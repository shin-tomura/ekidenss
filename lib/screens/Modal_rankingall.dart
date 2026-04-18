import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

// ------------------------------------------------
// 新しい種目定義: timeIndex 0から7に対応
// ------------------------------------------------
enum DisplayEvent {
  best5000m, // 0
  best10000m, // 1
  bestHalf, // 2
  bestFull, // 3
  bestUp10000m, // 4
  bestDown10000m, // 5
  bestRoad10000m, // 6
  bestXC10000m, // 7
}

// ------------------------------------------------
// 選手のタイムとソートに必要な情報を保持する構造体
// ------------------------------------------------
class SenshuTime {
  final SenshuData senshu;
  final double bestTime;
  final int timeIndex;

  SenshuTime(this.senshu, this.bestTime, this.timeIndex);

  double get sortableTime =>
      bestTime >= TEISUU.DEFAULTTIME ? double.infinity : bestTime;
}

// ------------------------------------------------
// 全大学選手ランキング画面 (TOP30)
// ------------------------------------------------
class ModalAllUnivSenshuRankingView extends StatefulWidget {
  const ModalAllUnivSenshuRankingView({super.key});

  @override
  State<ModalAllUnivSenshuRankingView> createState() =>
      _ModalAllUnivSenshuRankingViewState();
}

class _ModalAllUnivSenshuRankingViewState
    extends State<ModalAllUnivSenshuRankingView> {
  // 表示する種目
  DisplayEvent _displayEvent = DisplayEvent.best5000m;

  // ★ 追加：選択されている学年 (0:全学年, 1, 2, 3, 4)
  int _selectedGakunen = 0;

  // 表示対象の種目リスト
  static const List<DisplayEvent> _availableEvents = [
    DisplayEvent.best5000m,
    DisplayEvent.best10000m,
    DisplayEvent.bestHalf,
  ];

  // 学年のラベル取得
  String _getGakunenLabel(int gakunen) {
    if (gakunen == 0) return '全学年';
    return '$gakunen年生';
  }

  int _getTimeIndex(DisplayEvent event) {
    switch (event) {
      case DisplayEvent.best5000m:
        return 0;
      case DisplayEvent.best10000m:
        return 1;
      case DisplayEvent.bestHalf:
        return 2;
      case DisplayEvent.bestFull:
        return 3;
      case DisplayEvent.bestUp10000m:
        return 4;
      case DisplayEvent.bestDown10000m:
        return 5;
      case DisplayEvent.bestRoad10000m:
        return 6;
      case DisplayEvent.bestXC10000m:
        return 7;
    }
  }

  String _getEventLabel(DisplayEvent event) {
    switch (event) {
      case DisplayEvent.best5000m:
        return '5千m';
      case DisplayEvent.best10000m:
        return '1万m';
      case DisplayEvent.bestHalf:
        return 'ハーフ';
      case DisplayEvent.bestFull:
        return 'フル';
      default:
        return 'その他';
    }
  }

  // ★ 改良：ランキング作成ロジックに学年フィルタを追加
  List<SenshuTime> _createAllUnivSenshuRanking(
    List<SenshuData> allSenshuData,
    DisplayEvent event,
    int filterGakunen,
  ) {
    final int timeIndex = _getTimeIndex(event);
    List<SenshuTime> rankingList = [];

    for (final senshu in allSenshuData) {
      // 学年フィルタリング
      if (filterGakunen != 0 && senshu.gakunen != filterGakunen) {
        continue;
      }

      if (senshu.time_bestkiroku.length <= timeIndex) continue;

      final double senshuTime = senshu.time_bestkiroku[timeIndex];
      rankingList.add(SenshuTime(senshu, senshuTime, timeIndex));
    }

    rankingList.sort((a, b) {
      final int timeCompare = a.sortableTime.compareTo(b.sortableTime);
      if (timeCompare != 0) return timeCompare;
      final int gakunenCompare = b.senshu.gakunen.compareTo(a.senshu.gakunen);
      if (gakunenCompare != 0) return gakunenCompare;
      return a.senshu.id.compareTo(b.senshu.id);
    });

    return rankingList.take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<SenshuData>>(
      valueListenable: senshudataBox.listenable(),
      builder: (context, box, _) {
        final List<SenshuData> allSenshuData = box.values.toList();
        final List<SenshuTime> ranking = _createAllUnivSenshuRanking(
          allSenshuData,
          _displayEvent,
          _selectedGakunen,
        );

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: Text(
              '${_getGakunenLabel(_selectedGakunen)} ${_getEventLabel(_displayEvent)} TOP30',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: <Widget>[
              // --- 学年切り替えタブ ---
              _buildGakunenSelector(),

              // --- ランキング一覧リスト ---
              Expanded(
                child: ranking.isEmpty
                    ? Center(
                        child: Text(
                          '該当する選手がいません',
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: ranking.length,
                        itemBuilder: (context, index) {
                          final st = ranking[index];
                          final senshu = st.senshu;
                          final univ = univdataBox.get(senshu.univid);

                          String timeStr = st.timeIndex == 3
                              ? (st.bestTime >= TEISUU.DEFAULTTIME
                                    ? '---'
                                    : TimeDate.timeToJikanFunByouString(
                                        st.bestTime,
                                      ))
                              : (st.bestTime >= TEISUU.DEFAULTTIME
                                    ? '---'
                                    : TimeDate.timeToFunByouString(
                                        st.bestTime,
                                      ));

                          return Container(
                            color: index.isEven
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.05),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${index + 1}位 ${senshu.name} (${senshu.gakunen}年)',
                                            style: TextStyle(
                                              color: HENSUU.textcolor,
                                              fontSize:
                                                  HENSUU.fontsize_honbun * 1.1,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            univ?.name ?? '不明',
                                            style: TextStyle(
                                              color: HENSUU.textcolor
                                                  .withOpacity(0.8),
                                              fontSize:
                                                  HENSUU.fontsize_honbun * 0.9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _showDetail(senshu.id),
                                      child: Text(
                                        '詳細',
                                        style: TextStyle(
                                          color: HENSUU.LinkColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getEventLabel(_displayEvent),
                                      style: TextStyle(
                                        color: HENSUU.textcolor.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun * 1.1,
                                        fontWeight:
                                            st.bestTime < TEISUU.DEFAULTTIME
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  color: Color.fromARGB(76, 255, 255, 255),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              // --- 種目切り替えボタン ---
              _buildEventNavigation(),
            ],
          ),
        );
      },
    );
  }

  // ★ 追加：学年選択用ウィジェット
  Widget _buildGakunenSelector() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // 全学年 + 1~4年
        itemBuilder: (context, index) {
          final isSelected = _selectedGakunen == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_getGakunenLabel(index)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedGakunen = index);
              },
              selectedColor: Colors.orange.shade700,
              backgroundColor: Colors.grey.shade800,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventNavigation() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _availableEvents.map((e) => _buildEventButton(e)).toList(),
      ),
    );
  }

  Widget _buildEventButton(DisplayEvent event) {
    final isSelected = _displayEvent == event;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => setState(() => _displayEvent = event),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.lightBlue.shade700
                : Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            _getEventLabel(event),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showDetail(int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) =>
          ModalSenshuDetailView(senshuId: senshuId),
    );
  }
}
