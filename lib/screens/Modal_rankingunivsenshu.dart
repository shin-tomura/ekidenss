import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
// ModalSenshuDetailView を使用するため、インポートを有効にします
import 'package:ekiden/screens/Modal_senshu.dart';

// ------------------------------------------------
// 新しい種目定義: timeIndex 0から7に対応
// ------------------------------------------------
enum DisplayEvent {
  best5000m, // 0
  best10000m, // 1
  bestHalf, // 2
  bestFull, // 3
  bestUp10000m, // 4 (登り10000)
  bestDown10000m, // 5 (下り10000)
  bestRoad10000m, // 6 (ロード10000)
  bestXC10000m, // 7 (クロカン10000)
}

// ------------------------------------------------
// 選手のタイムとソートに必要な情報を保持する構造体
// ------------------------------------------------
class SenshuTime {
  final SenshuData senshu;
  final double bestTime;
  final int timeIndex;

  SenshuTime(this.senshu, this.bestTime, this.timeIndex);

  // TEISUU.DEFAULTTIMEを考慮したソートキー
  // DEFAULTTIME以上の場合は最下位に、それ以外はタイムをそのまま使用
  double get sortableTime =>
      bestTime >= TEISUU.DEFAULTTIME ? double.infinity : bestTime;
}

// ------------------------------------------------
// 大学内選手ランキング画面
// ------------------------------------------------
class ModalUnivSenshuRankingView extends StatefulWidget {
  const ModalUnivSenshuRankingView({super.key});

  @override
  State<ModalUnivSenshuRankingView> createState() =>
      _ModalUnivSenshuRankingViewState();
}

class _ModalUnivSenshuRankingViewState
    extends State<ModalUnivSenshuRankingView> {
  // ★ 表示する種目 (timeIndex 0-7) を保持するローカル状態変数 ★
  DisplayEvent _displayEvent = DisplayEvent.best5000m;

  // 種目に対応する timeIndex を取得
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

  // 表示種目の日本語名を取得
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
      case DisplayEvent.bestUp10000m:
        return '登り10km';
      case DisplayEvent.bestDown10000m:
        return '下り10km';
      case DisplayEvent.bestRoad10000m:
        return 'ロード10km';
      case DisplayEvent.bestXC10000m:
        return 'クロカン10km';
    }
  }

  // 大学内の選手ランキングリストを作成
  List<SenshuTime> _createUnivSenshuRanking(
    List<SenshuData> allSenshuData,
    int targetUnivId,
    DisplayEvent event,
  ) {
    final int timeIndex = _getTimeIndex(event);
    List<SenshuTime> rankingList = [];

    for (final senshu in allSenshuData) {
      // --- currentGhensuu.hyojiunivnum==senshu.univid の選手のみを対象とする ---
      if (senshu.univid != targetUnivId) {
        continue;
      }

      // time_bestkirokuの境界チェック（念のため）
      if (senshu.time_bestkiroku.length <= timeIndex) {
        // データ構造が不完全な場合はスキップ
        continue;
      }

      final double senshuTime = senshu.time_bestkiroku[timeIndex];

      rankingList.add(SenshuTime(senshu, senshuTime, timeIndex));
    }

    // ------------------------------------------------
    // タイムの良い順に並べ替え（ソートロジック）
    // ------------------------------------------------
    rankingList.sort((a, b) {
      // 1. タイム昇順 (DEFAULTTIMEは最下位)
      final int timeCompare = a.sortableTime.compareTo(b.sortableTime);
      if (timeCompare != 0) return timeCompare;

      // 2. 学年降順 (高学年が上)
      final int gakunenCompare = b.senshu.gakunen.compareTo(a.senshu.gakunen);
      if (gakunenCompare != 0) return gakunenCompare;

      // 3. senshu.id昇順 (idが小さい方が上)
      return a.senshu.id.compareTo(b.senshu.id);
    });

    return rankingList;
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return const Center(child: Text('データがありません'));
        }

        // --- 現在表示対象の大学IDと大学データ ---
        final int targetUnivId = currentGhensuu.hyojiunivnum;
        final UnivData? targetUniv = univdataBox.get(targetUnivId);
        final String univName = targetUniv?.name ?? '不明な大学';

        final String currentEventLabel = _getEventLabel(_displayEvent);

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            final List<SenshuData> allSenshuData = senshudataBox.values
                .toList();

            // 1. 大学内の選手ランキングを計算
            final List<SenshuTime> ranking = _createUnivSenshuRanking(
              allSenshuData,
              targetUnivId,
              _displayEvent,
            );

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: Text(
                  '$univName 選手別 ${currentEventLabel}ランキング',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                children: <Widget>[
                  // --- ランキング一覧リスト ---
                  Expanded(
                    child: ranking.isEmpty
                        ? Center(
                            child: Text(
                              'ランキング対象の選手がいません',
                              style: TextStyle(color: HENSUU.textcolor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: ranking.length,
                            itemBuilder: (context, index) {
                              final SenshuTime senshuTime = ranking[index];
                              final SenshuData senshu = senshuTime.senshu;
                              String timeString = "";

                              // タイム表示: フルマラソン(timeIndex 3)は時間分秒、他は分秒
                              if (senshuTime.timeIndex == 3) {
                                timeString =
                                    senshuTime.bestTime >= TEISUU.DEFAULTTIME
                                    ? '---' // 記録なしの場合
                                    : TimeDate.timeToJikanFunByouString(
                                        senshuTime.bestTime,
                                      );
                              } else {
                                timeString =
                                    senshuTime.bestTime >= TEISUU.DEFAULTTIME
                                    ? '---' // 記録なしの場合
                                    : TimeDate.timeToFunByouString(
                                        senshuTime.bestTime,
                                      );
                              }

                              // ★★★ 1行おきに背景色を切り替えるロジック ★★★
                              final Color bgColor = index.isEven
                                  ? Colors
                                        .transparent // 偶数行は透明
                                  : Colors.white.withOpacity(0.05); // 奇数行は少し濃い色

                              final Color rankColor = HENSUU.textcolor;

                              return Container(
                                // 背景色を設定
                                color: bgColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1行目: ランキング、選手名(学年)、詳細ボタン
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ランキングと選手名(学年)
                                        Flexible(
                                          child: Text(
                                            // 選手名 (学年) の形式に変更
                                            '${index + 1}位 ${senshu.name} (${senshu.gakunen})',
                                            style: TextStyle(
                                              color: rankColor,
                                              fontSize:
                                                  HENSUU.fontsize_honbun *
                                                  1.1, // 選手名を強調
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        // 詳細ボタン
                                        TextButton(
                                          onPressed: () {
                                            showGeneralDialog(
                                              context: context,
                                              barrierColor: Colors.black
                                                  .withOpacity(0.8),
                                              barrierDismissible: true,
                                              barrierLabel: '詳細',
                                              transitionDuration:
                                                  const Duration(
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
                                    // 2行目: 種目名とベストタイム
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 種目名
                                        Text(
                                          currentEventLabel,
                                          style: TextStyle(
                                            color: rankColor.withOpacity(0.7),
                                            fontSize: HENSUU.fontsize_honbun,
                                          ),
                                        ),
                                        // ベストタイム
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            color: rankColor,
                                            fontSize:
                                                HENSUU.fontsize_honbun *
                                                1.1, // タイムを強調
                                            fontWeight:
                                                senshuTime.bestTime <
                                                    TEISUU.DEFAULTTIME
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // 区切り線
                                    const Divider(
                                      color: Color.fromARGB(76, 255, 255, 255),
                                      height: 8,
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
      },
    );
  }

  // 種目切り替えナビゲーションバー
  Widget _buildEventNavigation() {
    return Container(
      padding: EdgeInsets.only(
        top: 12.0,
        left: 12.0,
        right: 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 12.0,
      ),
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // 0-3行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DisplayEvent.values
                .take(4)
                .map((event) => _buildEventButton(event))
                .toList(),
          ),
          const SizedBox(height: 8.0),
          // 4-7行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DisplayEvent.values
                .skip(4)
                .take(4)
                .map((event) => _buildEventButton(event))
                .toList(),
          ),
        ],
      ),
    );
  }

  // イベント切り替えボタンの共通ウィジェット
  Widget _buildEventButton(DisplayEvent event) {
    final bool isSelected = _displayEvent == event;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _displayEvent = event;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.lightBlue.shade700
                : Colors.grey.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            minimumSize: const Size(0, 40), // 高さ調整
          ),
          child: Text(
            _getEventLabel(event),
            style: TextStyle(fontSize: HENSUU.fontsize_honbun * 0.7),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
