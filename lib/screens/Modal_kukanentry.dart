import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

// 並べ替えの種類を定義
enum SortType { univId, best5000m, best10000m, bestHalf }

class ModalKukanEntryListView extends StatefulWidget {
  const ModalKukanEntryListView({super.key});

  @override
  State<ModalKukanEntryListView> createState() =>
      _ModalKukanEntryListViewState();
}

class _ModalKukanEntryListViewState extends State<ModalKukanEntryListView> {
  SortType _currentSortType = SortType.univId;
  // ★ 画面専用の表示区間を保持するローカル状態変数 ★
  int? _displayKukan;

  // 選手のリストを現在のソートタイプに基づいて並べ替える
  List<SenshuData> _sortSenshuList(List<SenshuData> list) {
    list.sort((a, b) {
      switch (_currentSortType) {
        case SortType.univId:
          // 所属大学IDでソート
          return a.univid.compareTo(b.univid);
        case SortType.best5000m:
          // 5000mベストタイムでソート (短い方が先)
          return _compareTime(a.time_bestkiroku[0], b.time_bestkiroku[0]);
        case SortType.best10000m:
          // 10000mベストタイムでソート (短い方が先)
          return _compareTime(a.time_bestkiroku[1], b.time_bestkiroku[1]);
        case SortType.bestHalf:
          // ハーフマラソンベストタイムでソート (短い方が先)
          return _compareTime(a.time_bestkiroku[2], b.time_bestkiroku[2]);
      }
    });
    return list;
  }

  // タイムの比較ロジック (TEISUU.DEFAULTTIMEを最後に持ってくる)
  int _compareTime(double timeA, double timeB) {
    final bool isADefault = timeA >= TEISUU.DEFAULTTIME;
    final bool isBDefault = timeB >= TEISUU.DEFAULTTIME;

    if (isADefault && isBDefault) return 0; // 両方記録なしなら同じ
    if (isADefault) return 1; // Aが記録なしならAを後
    if (isBDefault) return -1; // Bが記録なしならBを後

    // 記録がある場合は時間が短い方が先
    return timeA.compareTo(timeB);
  }

  // 区間を移動する処理 (currentGhensuu.nowracecalckukanは更新しない)
  Future<void> _changeKukan(Ghensuu currentGhensuu, int delta) async {
    // _displayKukanが初期化されていない場合は処理を中断
    if (_displayKukan == null) return;

    final int raceBangou = currentGhensuu.hyojiracebangou;
    final int maxKukan = currentGhensuu.kukansuu_taikaigoto[raceBangou];
    int newKukan = _displayKukan! + delta; // ローカル変数を使用

    // 0区間目から最大区間数の範囲にクランプ (循環)
    if (newKukan < 0) {
      newKukan = maxKukan - 1;
    } else if (newKukan >= maxKukan) {
      newKukan = 0;
    }

    // ローカル状態のみ更新し、画面を再描画
    setState(() {
      _displayKukan = newKukan;
    });
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

        // ★ 画面専用の表示区間の初期化 ★
        // 初回ビルド時のみ、永続データから初期値を取得
        if (_displayKukan == null) {
          _displayKukan = currentGhensuu.nowracecalckukan;
        }

        final int raceBangou = currentGhensuu.hyojiracebangou;
        // ★ 常にローカル変数 _displayKukan を使用する ★
        final int kukanBangou = _displayKukan!;
        final int maxKukan = currentGhensuu.kukansuu_taikaigoto[raceBangou];

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

                // 1. フィルタリング: 現在の区間にエントリーしている選手を抽出
                List<SenshuData> filteredSenshuData = allSenshuData.where((s) {
                  final UnivData? univ = univDataMap[s.univid];

                  if (univ == null) return false;

                  // 1. 大学が大会に出場しているか
                  final bool isUnivEntry =
                      univ.taikaientryflag[raceBangou] == 1;

                  // 2. 選手が現在の区間 (kukanBangou = _displayKukan) にエントリーしているか
                  // 配列の境界チェックを行う (念のため)
                  final bool isSenshuEntry =
                      s.gakunen > 0 &&
                      s.gakunen <= 4 && // 学年が1-4年として
                      s.entrykukan_race.length > raceBangou &&
                      s.entrykukan_race[raceBangou].length > s.gakunen - 1 &&
                      s.entrykukan_race[raceBangou][s.gakunen - 1] ==
                          kukanBangou; // ★ kukanBangou (_displayKukan) を参照 ★

                  return isUnivEntry && isSenshuEntry;
                }).toList();

                // 2. ソート: 現在のソートタイプに基づいて並べ替え
                filteredSenshuData = _sortSenshuList(filteredSenshuData);

                final int kukanKyoriRoundedM =
                    (currentGhensuu.kyori_taikai_kukangoto[currentGhensuu
                            .hyojiracebangou][kukanBangou])
                        .round();
                String kukantext =
                    '第${kukanBangou + 1}区 ${kukanKyoriRoundedM}m';
                if (currentGhensuu.hyojiracebangou == 3) {
                  kukantext = '第${kukanBangou + 1}組 トラック1万ｍ';
                }
                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor,
                  appBar: AppBar(
                    // 区間距離を四捨五入したメートル値で表示
                    title: Text(
                      kukantext,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: HENSUU.backgroundcolor,
                    foregroundColor: Colors.white,
                  ),
                  body: Column(
                    children: <Widget>[
                      // --- ソート選択ボタン ---
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                [
                                      _buildSortButton(
                                        SortType.univId,
                                        '大学ID順',
                                        kukanBangou + 1,
                                      ),
                                      _buildSortButton(
                                        SortType.best5000m,
                                        '5000m順',
                                        kukanBangou + 1,
                                      ),
                                      _buildSortButton(
                                        SortType.best10000m,
                                        '10000m順',
                                        kukanBangou + 1,
                                      ),
                                      _buildSortButton(
                                        SortType.bestHalf,
                                        'ハーフ順',
                                        kukanBangou + 1,
                                      ),
                                    ]
                                    .map(
                                      (widget) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: widget,
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.grey),

                      // --- 選手一覧リスト ---
                      Expanded(
                        child: filteredSenshuData.isEmpty
                            ? Center(
                                child: Text(
                                  'この区間のエントリー選手はいません',
                                  style: TextStyle(color: HENSUU.textcolor),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredSenshuData.length,
                                itemBuilder: (context, index) {
                                  final SenshuData senshu =
                                      filteredSenshuData[index];
                                  final UnivData? univ =
                                      univDataMap[senshu.univid];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 選手名・学年・大学名 と詳細ボタン ★ここを修正★
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // 選手名・学年・大学名
                                            Flexible(
                                              child: Text(
                                                '${index + 1}. ${senshu.name}\n    (${senshu.gakunen}年 / ${univ?.name ?? '不明'})',
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                  fontSize:
                                                      HENSUU.fontsize_honbun +
                                                      2,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis, // 長すぎる場合に省略
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 詳細ボタン
                                            TextButton(
                                              /*onPressed: () {
                                                // 選手IDを渡して詳細モーダルを呼び出す (senshu.id が int であることを想定)
                                                ModalSenshuDetailView(
                                                  senshuId: senshu.id,
                                                );
                                              },*/
                                              onPressed: () {
                                                // ★こちらも showGeneralDialog に変更★
                                                showGeneralDialog(
                                                  context: context,
                                                  barrierColor: Colors.black
                                                      .withOpacity(
                                                        0.8,
                                                      ), // モーダルの背景色
                                                  barrierDismissible:
                                                      true, // 背景タップで閉じられるようにする
                                                  barrierLabel:
                                                      '詳細', // アクセシビリティ用ラベル
                                                  transitionDuration:
                                                      const Duration(
                                                        milliseconds: 300,
                                                      ), // アニメーション時間
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) {
                                                        // ここに表示したいモーダルのウィジェットを指定
                                                        return ModalSenshuDetailView(
                                                          senshuId: senshu.id,
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
                                                          opacity:
                                                              CurvedAnimation(
                                                                parent:
                                                                    animation,
                                                                curve: Curves
                                                                    .easeOut,
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
                                                  fontSize:
                                                      HENSUU.fontsize_honbun,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // 持ちタイム一覧
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (currentGhensuu
                                                          .hyojiracebangou <=
                                                      2 ||
                                                  currentGhensuu
                                                          .hyojiracebangou ==
                                                      5)
                                                Text('調子 ${senshu.chousi}'),
                                              _buildTimeRow(
                                                '5000m',
                                                senshu.time_bestkiroku[0],
                                              ),
                                              _buildTimeRow(
                                                '10000m',
                                                senshu.time_bestkiroku[1],
                                              ),
                                              _buildTimeRow(
                                                'ハーフ',
                                                senshu.time_bestkiroku[2],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(color: Colors.white12),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // --- 区間移動ボタン ---
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom,
                        ),
                        child: _buildKukanNavigation(currentGhensuu),
                      ),
                      //_buildKukanNavigation(currentGhensuu),
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

  // ソートボタンウィジェット
  Widget _buildSortButton(SortType type, String label, int kukanNum) {
    final bool isSelected = _currentSortType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentSortType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.lightBlue.shade700
            : Colors.grey.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: HENSUU.fontsize_honbun * 0.9),
      ),
    );
  }

  // 持ちタイム表示行
  Widget _buildTimeRow(String label, double time) {
    return Row(
      children: [
        SizedBox(
          width: 80, // ラベルの幅を固定
          child: Text(
            '$label:',
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.7),
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ),
        Text(
          TimeDate.timeToFunByouString(time),
          style: TextStyle(
            color: time < TEISUU.DEFAULTTIME
                ? Colors.amberAccent
                : HENSUU.textcolor.withOpacity(0.7),
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 区間移動ナビゲーションバー
  Widget _buildKukanNavigation(Ghensuu currentGhensuu) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changeKukan(currentGhensuu, -1),
              icon: const Icon(Icons.arrow_back),
              label: const Text('前'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changeKukan(currentGhensuu, 1),
              icon: const Text('次'),
              label: const Icon(Icons.arrow_forward),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
