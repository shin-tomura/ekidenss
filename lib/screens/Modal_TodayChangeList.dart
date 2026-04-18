import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';

// 当日変更選手一覧を表示するウィジェット
class ModalTodayChangeListView extends StatefulWidget {
  const ModalTodayChangeListView({super.key});

  @override
  State<ModalTodayChangeListView> createState() =>
      _ModalTodayChangeListViewState();
}

class _ModalTodayChangeListViewState extends State<ModalTodayChangeListView> {
  // 当日変更情報を保持するデータ構造
  // Map<大学ID, List<Map<String, dynamic>>>
  // Listの要素: { 'kukan': 1-indexed区間, 'original': SenshuData (変更前), 'new': SenshuData (変更後) }
  Map<int, List<Map<String, dynamic>>> _todayChangeMap = {};

  @override
  void initState() {
    super.initState();
    // データのロードと計算をinitStateで行う
    _calculateTodayChanges();
  }

  // 当日変更された選手情報を計算する
  void _calculateTodayChanges() {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

    if (currentGhensuu == null) return;

    final int raceBangou = currentGhensuu.hyojiracebangou;

    // 当日変更で走れなかった選手（変更前の選手）を抽出
    final List<SenshuData> originalSenshuList = senshudataBox.values.where((s) {
      // 当日変更で走れなかった選手 (entrykukan_race[raceBangou][gakunen-1] <= -100)
      final int kukanEntryValue =
          s.entrykukan_race.length > raceBangou &&
              s.entrykukan_race[raceBangou].length > s.gakunen - 1
          ? s.entrykukan_race[raceBangou][s.gakunen - 1]
          : 9999; // エラー回避のため大きな値を設定

      return kukanEntryValue <= -100;
    }).toList();

    // 走れなかった選手ごとに、区間と交代した選手（変更後の選手）を見つける
    Map<int, List<Map<String, dynamic>>> changes = {};

    for (final originalSenshu in originalSenshuList) {
      final int univid = originalSenshu.univid;

      // -100, -101, ... は 1区, 2区, ... に元々エントリーされていたことを表す
      // 当日変更前の区間 (1-indexed)
      final int originalKukan =
          (originalSenshu
              .entrykukan_race[raceBangou][originalSenshu.gakunen - 1]
              .abs()) -
          99;

      // 変更後の選手を見つける
      // 変更後の選手は、raceBangouにおいて、元の区間(originalKukan - 1)を走る選手 (0-indexed)
      final SenshuData? newSenshu = senshudataBox.values.firstWhere(
        (s) {
          // 同じ大学で、元の区間(originalKukan - 1)を走る選手を見つける
          return s.univid == univid &&
              s.entrykukan_race.length > raceBangou &&
              s.entrykukan_race[raceBangou].length > s.gakunen - 1 &&
              s.entrykukan_race[raceBangou][s.gakunen - 1] ==
                  (originalKukan - 1); // 0-indexed区間
        },
        //orElse: () =>
        //    const SenshuData(), // 見つからなかった場合はデフォルト値を返す (ID=0と想定)
      );

      // 交代した選手がいる場合のみリストに追加
      // newSenshu.id > 0 は SenshuData() ではないことを意味する（IDが1以上と仮定）
      if (newSenshu != null && newSenshu.id >= 0) {
        if (!changes.containsKey(univid)) {
          changes[univid] = [];
        }

        changes[univid]!.add({
          'kukan': originalKukan, // 1-indexed
          'original': originalSenshu,
          'new': newSenshu,
        });
      }
    }

    // --- ここからソート処理の改良 ---

    // 1. 各大学内の変更リストを区間 (kukan: 1-indexed) 順にソートする
    changes.forEach((univid, changeList) {
      changeList.sort((a, b) => a['kukan'].compareTo(b['kukan']));
    });

    // 2. 大学ID順にソート（任意）
    final sortedChanges = Map.fromEntries(
      changes.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    setState(() {
      _todayChangeMap = sortedChanges;
    });
  }
  // --- ソート処理の改良ここまで ---

  // 選手の表示を整形するヘルパー関数
  String _formatSenshu(SenshuData senshu) {
    return '${senshu.name} (${senshu.gakunen})';
  }

  @override
  Widget build(BuildContext context) {
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    // 大学IDをキーにしてUnivDataにアクセスしやすいMapを作成
    final Map<int, UnivData> univDataMap = {
      for (var univ in univdataBox.values) univ.id: univ,
    };

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('🔀 当日変更選手一覧', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: _todayChangeMap.isEmpty
          ? Center(
              child: Text(
                '当日変更された選手はいません。',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            )
          : ListView.builder(
              itemCount: _todayChangeMap.keys.length,
              itemBuilder: (context, index) {
                final int univid = _todayChangeMap.keys.elementAt(index);
                final UnivData? univ = univDataMap[univid];
                final List<Map<String, dynamic>> changes =
                    _todayChangeMap[univid]!; // 区間順にソート済み

                if (univ == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 大学名
                      Text(
                        '${univ.name}',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: HENSUU.fontsize_honbun + 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 当日変更のリスト（区間順に表示される）
                      ...changes.map((change) {
                        final int kukan = change['kukan'];
                        final SenshuData original = change['original'];
                        final SenshuData newSenshu = change['new'];

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            bottom: 4.0,
                          ),
                          child: Text(
                            '${kukan}区　${_formatSenshu(original)} → ${_formatSenshu(newSenshu)}',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        );
                      }).toList(),

                      // 大学ごとの区切り
                      if (index < _todayChangeMap.keys.length - 1)
                        const Divider(
                          color: Colors.white38,
                          height: 24,
                          thickness: 1,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
