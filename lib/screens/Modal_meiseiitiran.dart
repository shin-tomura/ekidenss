import 'dart:ui'; // FontFeatureのために必要
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート

// ソート状態を管理するための列挙型
enum UnivSortType {
  idAsc, // ID昇順
  meiseiDesc, // 名声合計降順
}

class ModalMeiseiIchiran extends StatefulWidget {
  const ModalMeiseiIchiran({super.key});

  @override
  State<ModalMeiseiIchiran> createState() => _ModalMeiseiIchiranState();
}

class _ModalMeiseiIchiranState extends State<ModalMeiseiIchiran> {
  late Box<UnivData> _univBox;
  // 初期表示は名声降順
  UnivSortType _currentSortType = UnivSortType.meiseiDesc;

  @override
  void initState() {
    super.initState();
    _univBox = Hive.box<UnivData>('univBox');
  }

  // ソートされたリストを返すメソッド
  List<UnivData> _getSortedUnivs(List<UnivData> allUnivs) {
    List<UnivData> sortedList = List.from(allUnivs);
    if (_currentSortType == UnivSortType.idAsc) {
      // ID順（idフィールドで昇順）
      sortedList.sort((a, b) => a.id.compareTo(b.id));
    } else {
      // 名声降順（meisei_totalで降順）
      sortedList.sort((a, b) => b.meisei_total.compareTo(a.meisei_total));
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UnivData>>(
      valueListenable: _univBox.listenable(),
      builder: (context, univBox, _) {
        final List<UnivData> allUnivs = univBox.values.toList();

        if (allUnivs.isEmpty) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '大学名声一覧',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        final List<UnivData> sortedUnivs = _getSortedUnivs(allUnivs);

        // --- 同着順位の計算ロジック ---
        // 名声順の場合のみ、同値を考慮した順位リストを作成する
        List<int> ranks = [];
        if (_currentSortType == UnivSortType.meiseiDesc) {
          int currentRank = 1;
          for (int i = 0; i < sortedUnivs.length; i++) {
            if (i > 0 &&
                sortedUnivs[i].meisei_total ==
                    sortedUnivs[i - 1].meisei_total) {
              // 前のデータと同じ名声値なら、ランクを据え置く
              ranks.add(ranks[i - 1]);
            } else {
              // 違う値なら、(リストのインデックス + 1) を順位とする
              ranks.add(i + 1);
            }
          }
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text('大学名声一覧', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _currentSortType == UnivSortType.meiseiDesc
                      ? Icons.sort_by_alpha
                      : Icons.trending_down,
                ),
                onPressed: () {
                  setState(() {
                    _currentSortType =
                        (_currentSortType == UnivSortType.meiseiDesc)
                        ? UnivSortType.idAsc
                        : UnivSortType.meiseiDesc;
                  });
                },
                tooltip: 'ソート切り替え',
              ),
            ],
          ),
          body: Column(
            children: [
              // ヘッダーラベル
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.black26,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        _currentSortType == UnivSortType.meiseiDesc
                            ? '順位'
                            : 'ID',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '大学名',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      '名声値',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: sortedUnivs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.grey, height: 1),
                  itemBuilder: (context, index) {
                    final univ = sortedUnivs[index];

                    // 表示テキストの決定
                    final String leadingText =
                        _currentSortType == UnivSortType.meiseiDesc
                        ? '${ranks[index]}' // 同着考慮済みの順位
                        : '${univ.id}'; // 大学ID

                    return ListTile(
                      leading: SizedBox(
                        width: 30,
                        child: Text(
                          leadingText,
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        univ.name,
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        '${univ.meisei_total}',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: HENSUU.fontsize_honbun + 2,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 戻るボタン
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("閉じる"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
