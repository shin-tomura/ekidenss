import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
// import 'package:ekiden/screens/Modal_senshu.dart'; // 選手詳細が不要であればコメントアウト

// 表示対象の種目を定義
enum DisplayEvent { best5000m, best10000m, bestHalf }

// 大学の平均タイムとIDを保持する構造体
class UnivAverageTime {
  final int univid;
  final double averageTime;
  final int entryCount; // 集計対象となった選手の人数

  UnivAverageTime(this.univid, this.averageTime, this.entryCount);
}

class ModalAverageTimeRankingView extends StatefulWidget {
  const ModalAverageTimeRankingView({super.key});

  @override
  State<ModalAverageTimeRankingView> createState() =>
      _ModalAverageTimeRankingViewState();
}

class _ModalAverageTimeRankingViewState
    extends State<ModalAverageTimeRankingView> {
  // ★ 表示する種目 (5000m, 10000m, ハーフ) を保持するローカル状態変数 ★
  DisplayEvent _displayEvent = DisplayEvent.best5000m;

  // タイムの比較ロジック (TEISUU.DEFAULTTIMEを最後に持ってくる)
  // このメソッドは現在使用されていませんが、念のためコメントアウトのまま残します。
  /*int _compareTime(double timeA, double timeB) {
    final bool isADefault = timeA >= TEISUU.DEFAULTTIME;
    final bool isBDefault = timeB >= TEISUU.DEFAULTTIME;

    if (isADefault && isBDefault) return 0; // 両方記録なしなら同じ
    if (isADefault) return 1; // Aが記録なしならAを後
    if (isBDefault) return -1; // Bが記録なしならBを後

    // 記録がある場合は時間が短い方が先
    return timeA.compareTo(timeB);
  }*/

  // 大学ごとの平均タイムを計算し、ランキングリストを返す
  List<UnivAverageTime> _calculateUnivAverageTimes(
    List<SenshuData> allSenshuData,
    Map<int, UnivData> univDataMap,
    DisplayEvent event,
    int raceBangou,
    Ghensuu ghensuu,
  ) {
    // 1. 各大学の合計タイムと人数を保持するMap
    final Map<int, List<double>> univTimeData = {}; // {univid: [合計タイム, 人数]}

    // 2. 選手データを処理し、大学ごとの合計タイムと人数を集計
    for (final senshu in allSenshuData) {
      final UnivData? univ = univDataMap[senshu.univid];

      // --- 大会エントリー大学かどうかのチェック ---
      if (univ == null || univ.taikaientryflag[raceBangou] != 1) {
        continue; // 大会にエントリーしていない大学はスキップ
      }

      // --- 選手がその大会に区間エントリーしているかどうかのチェック ---
      final int entryKukanIndex = senshu.gakunen - 1;

      // 配列の境界チェック
      if (senshu.entrykukan_race.length <= raceBangou ||
          senshu.entrykukan_race[raceBangou].length <= entryKukanIndex) {
        // データ構造が不完全な場合はスキップ (念のため)
        continue;
      }

      // 区間エントリー番号を取得
      final int kukanEntryNum =
          senshu.entrykukan_race[raceBangou][entryKukanIndex];

      // 区間エントリー番号が-1 (エントリーなし) の場合はスキップ
      int entrynasisikiiti = 0;
      if (ghensuu.mode == 280) {
        entrynasisikiiti = -2;
      } else {
        entrynasisikiiti = -1;
      }
      if (kukanEntryNum <= entrynasisikiiti) {
        continue;
      }

      // 種目に応じたタイムのインデックス
      int timeIndex = 0;
      switch (event) {
        case DisplayEvent.best5000m:
          timeIndex = 0;
          break;
        case DisplayEvent.best10000m:
          timeIndex = 1;
          break;
        case DisplayEvent.bestHalf:
          timeIndex = 2;
          break;
      }

      final double senshuTime = senshu.time_bestkiroku[timeIndex];

      // 記録がない選手 (TEISUU.DEFAULTTIME以上) は集計から除外
      if (senshuTime >= TEISUU.DEFAULTTIME) {
        continue;
      }

      if (!univTimeData.containsKey(senshu.univid)) {
        // [合計タイム, 人数]
        univTimeData[senshu.univid] = [0.0, 0.0];
      }

      // 合計タイムに追加
      univTimeData[senshu.univid]![0] += senshuTime;
      // 人数を追加
      univTimeData[senshu.univid]![1] += 1.0;
    }

    // 3. 平均タイムを計算
    List<UnivAverageTime> rankingList = [];
    for (final univid in univTimeData.keys) {
      final double totalTime = univTimeData[univid]![0];
      final double count = univTimeData[univid]![1];

      // 1人以上記録がある場合のみ平均を計算
      if (count > 0) {
        final double averageTime = totalTime / count;
        rankingList.add(UnivAverageTime(univid, averageTime, count.toInt()));
      }
    }

    // 4. 平均タイムで並べ替え (短い方が先)
    rankingList.sort((a, b) => a.averageTime.compareTo(b.averageTime));

    return rankingList;
  }

  // 表示種目の日本語名を取得
  String _getEventLabel(DisplayEvent event) {
    switch (event) {
      case DisplayEvent.best5000m:
        return '5000m';
      case DisplayEvent.best10000m:
        return '10000m';
      case DisplayEvent.bestHalf:
        return 'ハーフマラソン';
    }
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

        final int raceBangou = currentGhensuu.hyojiracebangou;
        final String currentEventLabel = _getEventLabel(_displayEvent);

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            // 大学IDをキーにしてUnivDataにアクセスしやすいMapを作成
            final Map<int, UnivData> univDataMap = {
              for (var univ in univdataBox.values) univ.id: univ,
            };

            return ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),
              builder: (context, senshudataBox, _) {
                final List<SenshuData> allSenshuData = senshudataBox.values
                    .toList();

                // 1. 大学ごとの平均タイムランキングを計算
                final List<UnivAverageTime> ranking =
                    _calculateUnivAverageTimes(
                      allSenshuData,
                      univDataMap,
                      _displayEvent,
                      raceBangou,
                      currentGhensuu,
                    );

                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor,
                  appBar: AppBar(
                    title: Text(
                      //'大学別平均${currentEventLabel}タイムランキング',
                      'エントリー選手平均持ちタイム',
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
                                  'ランキング対象の大学がありません',
                                  style: TextStyle(color: HENSUU.textcolor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: ranking.length,
                                itemBuilder: (context, index) {
                                  final UnivAverageTime univAvg =
                                      ranking[index];
                                  final UnivData? univ =
                                      univDataMap[univAvg.univid];

                                  // 分秒文字列に変換
                                  final String timeString =
                                      TimeDate.timeToFunByouString(
                                        univAvg.averageTime,
                                      );

                                  // ★★★ 1行おきに背景色を切り替えるロジック ★★★
                                  final Color bgColor = index.isEven
                                      ? Colors
                                            .transparent // 偶数行は透明 (またはベースの背景色)
                                      : Colors.white.withOpacity(
                                          0.05,
                                        ); // 奇数行は少し濃い色
                                  // ★★★ ランキングの装飾 (元のコードではコメントアウトされていたため、ベースのテキスト色を使用) ★★★
                                  final Color rankColor = HENSUU.textcolor;

                                  return Container(
                                    // 背景色を設定
                                    color: bgColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // ランキングと大学名
                                            Flexible(
                                              child: Text(
                                                //'${index + 1}位 ${univ?.name ?? '不明'} (${univAvg.entryCount}人)', // 人数表示が必要な場合はこちらを使用
                                                '${index + 1}位 ${univ?.name ?? '不明'}',
                                                style: TextStyle(
                                                  color: rankColor,
                                                  fontSize:
                                                      HENSUU.fontsize_honbun,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 平均タイム
                                            Text(
                                              timeString,
                                              style: TextStyle(
                                                color: rankColor,
                                                fontSize:
                                                    HENSUU.fontsize_honbun,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // 区切り線は行の背景色が変わるため、不要であれば削除/コメントアウト
                                        // ただし、リストの区切りとして残す場合は、Containerの外ではなくRowのすぐ下に配置した方が自然です。
                                        const Divider(
                                          color: Color.fromARGB(
                                            76,
                                            255,
                                            255,
                                            255,
                                          ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: DisplayEvent.values.map((event) {
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _getEventLabel(event),
                  style: TextStyle(fontSize: HENSUU.fontsize_honbun * 0.9),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
