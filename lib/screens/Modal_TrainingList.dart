import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// 以下のインポートは、元のコードから推測されるものです。実際のプロジェクト構造に合わせて調整してください。
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/constants.dart';
// 選手詳細モーダルを呼び出すために必要
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuu も必要

/// 選手ごとの強化練習メニューの一覧をモーダルで表示する画面
class ModalTrainingListView extends StatefulWidget {
  const ModalTrainingListView({super.key});

  @override
  State<ModalTrainingListView> createState() => _ModalTrainingListViewState();
}

class _ModalTrainingListViewState extends State<ModalTrainingListView> {
  final Map<int, String> _trainingOptions = {
    -1: 'すべて',
    0: 'バランス',
    1: 'スピード',
    2: '距離走',
    3: '登り',
    4: '下り',
    5: 'アップダウン',
  };

  int _selectedFilterId = -1;

  /// 選手詳細モーダルを呼び出す共通関数
  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '詳細',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            // ModalSenshuDetailViewはimportされていると仮定
            // ignore: unnecessary_cast
            return (ModalSenshuDetailView(senshuId: senshu.id)) as Widget;
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
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
          color: HENSUU.LinkColor, // リンクカラーを維持
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // メインのBuildメソッド
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return const Center(
            child: CircularProgressIndicator(color: HENSUU.textcolor),
          );
        }

        final int myUnivId = currentGhensuu.hyojiunivnum;

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            List<SenshuData> allSenshu = senshudataBox.values.toList();
            List<SenshuData> myTeamSenshu = allSenshu
                .where((s) => s.univid == myUnivId)
                .toList();

            myTeamSenshu.sort((a, b) {
              int gakunenCompare = b.gakunen.compareTo(a.gakunen);
              if (gakunenCompare != 0) {
                return gakunenCompare;
              }
              return a.id.compareTo(b.id);
            });

            // フィルター適用
            List<SenshuData> filteredSenshu = myTeamSenshu.where((senshu) {
              return _selectedFilterId == -1 ||
                  senshu.kaifukuryoku == _selectedFilterId;
            }).toList();

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: HENSUU.textcolor,
                title: const Text(
                  '強化練習メニュー 一覧',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 🌟 ここでSafeAreaウィジェットをbodyに追加します
              body: SafeArea(
                child: Column(
                  children: [
                    // フィルターのドロップダウン
                    _buildFilterDropdown(),

                    const Divider(color: HENSUU.textcolor, height: 1),

                    // 2. 選手一覧 (ListView)
                    Expanded(
                      child: filteredSenshu.isEmpty
                          ? Center(
                              child: Text(
                                '該当する選手はいません',
                                style: TextStyle(
                                  color: HENSUU.textcolor.withOpacity(0.7),
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredSenshu.length,
                              itemBuilder: (context, index) {
                                final senshu = filteredSenshu[index];
                                return _buildSenshuRow(senshu);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ... ( _buildFilterDropdown の部分は変更なし)
  Widget _buildFilterDropdown() {
    final Map<int, String> filterOptions = Map.from(_trainingOptions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            'フィルター:',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: DropdownButton<int>(
              value: _selectedFilterId,
              dropdownColor: HENSUU.backgroundcolor,
              isExpanded: true,
              iconEnabledColor: HENSUU.LinkColor,
              items: filterOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: HENSUU.fontsize_honbun,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilterId = newValue;
                  });
                }
              },
              selectedItemBuilder: (BuildContext context) {
                return filterOptions.entries.map((entry) {
                  return Text(
                    entry.value,
                    style: const TextStyle(
                      color: HENSUU.LinkColor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 選手ごとの行を作成（詳細ボタンを追加）
  Widget _buildSenshuRow(SenshuData senshu) {
    final String trainingName =
        _trainingOptions[senshu.kaifukuryoku] ?? '未設定/エラー';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 4.0,
      ), // 縦パディングを少し減らして密に
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HENSUU.textcolor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 氏名(学年)
          Expanded(
            flex: 3,
            child: Text(
              '${senshu.name} (${senshu.gakunen}年)',
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun * 1.05,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          // 練習メニュー名
          Expanded(
            flex: 2,
            child: Text(
              trainingName,
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun * 1.05,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.left,
            ),
          ),
          // 詳細ボタン
          SizedBox(
            width: 50, // ボタンを収めるための固定幅
            child: _buildDetailButton(senshu),
          ),
        ],
      ),
    );
  }
}
