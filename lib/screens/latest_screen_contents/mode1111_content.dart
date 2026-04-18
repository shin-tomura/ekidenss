import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
//import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

/// mode==1111の強化練習メニュー決定画面
class Mode1111Content extends StatefulWidget {
  final Ghensuu ghensuu; // 親から渡される Ghensuu オブジェクト
  final VoidCallback? onAdvanceMode; // 親から渡されるコールバック

  const Mode1111Content({
    super.key,
    required this.ghensuu, // ghensuu は必須
    this.onAdvanceMode, // onAdvanceMode はオプション
  });

  @override
  State<Mode1111Content> createState() => _Mode1111ContentState();
}

class _Mode1111ContentState extends State<Mode1111Content> {
  // 強化練習メニューの選択肢 (kaifukuryokuの値と対応)
  final Map<int, String> _trainingOptions = {
    0: 'バランス (平均的)',
    1: 'スピード (スパート/ペース変動)',
    2: '距離走 (長距離粘り/ロード)',
    3: '登り (登り適正)',
    4: '下り (下り適正)',
    5: 'アップダウン (対応力)',
  };

  // ドロップダウンに使用する明るい緑色を定義
  static const Color _brightGreen = Color.fromARGB(255, 0, 255, 0);

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

  /// 選手の kaifukuryoku をHiveに更新する
  Future<void> _updateKaifukuryoku(SenshuData senshu, int newValue) async {
    // 値を更新してHiveに保存
    senshu.kaifukuryoku = newValue;
    await senshu.save(); // Hiveに永続化
  }

  /// kaifukuryoku の初期値をチェックし、範囲外なら0に設定して保存する
  void _initializeKaifukuryoku(List<SenshuData> senshuList) async {
    bool needsSave = false;
    for (var senshu in senshuList) {
      if (senshu.kaifukuryoku < 0 || senshu.kaifukuryoku > 5) {
        senshu.kaifukuryoku = 0; // 範囲外なら0に初期化
        await senshu.save();
        needsSave = true;
      }
    }
    if (needsSave) {
      // 選手データが更新されたら再描画
      setState(() {});
    }
  }

  // ゲームを進めるボタンのアクションとチェック処理
  void _handleAdvanceButton(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ゲーム進行の確認', style: TextStyle(color: Colors.black)),
          content: const Text(
            '年間強化練習メニューを決定します。1年後まで変更できません。\nこのままゲームを進めてよろしいですか？',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('はい、進めます'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onAdvanceMode?.call(); // 親の進む処理を実行
    }
  }

  // --------------------------------------------------------------------------
  // メインのBuildメソッド
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return const Center(
            child: CircularProgressIndicator(color: HENSUU.textcolor),
          );
        }

        final int myUnivId = currentGhensuu.MYunivid;

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

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeKaifukuryoku(myTeamSenshu);
            });

            // ListViewのアイテム数: 選手の数 + 1 (補足説明用)
            final int itemCountWithNote = myTeamSenshu.length + 1;

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              body: Column(
                children: [
                  // ヘッダー情報と進むボタン
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '年間強化メニュー決定',
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 進むボタン
                        ElevatedButton(
                          onPressed: () => _handleAdvanceButton(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HENSUU.buttonColor,
                            foregroundColor: HENSUU.buttonTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("進む＞＞"),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: HENSUU.textcolor, height: 1),

                  // 選手一覧 (補足説明を含む)
                  Expanded(
                    child: ListView.builder(
                      itemCount: itemCountWithNote, // 補足説明のために +1
                      itemBuilder: (context, index) {
                        // 最後のインデックスの場合、補足説明を表示
                        if (index == myTeamSenshu.length) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              '補足説明\n強化練習は見た目の能力値の数値は変わりませんが、レースの計算中に対象能力をブーストさせるものになります。ですので、たとえば、登りを強化しても選手画面の登り適正の見た目の能力値は上昇しません。',
                              style: TextStyle(
                                color: HENSUU.textcolor.withOpacity(
                                  0.7,
                                ), // 少し薄い色で表示
                                fontSize:
                                    HENSUU.fontsize_honbun * 0.9, // 少し小さめの文字サイズ
                                //fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        // それ以外のインデックスの場合、選手情報を表示
                        final senshu = myTeamSenshu[index];
                        final int currentKaifukuryoku = senshu.kaifukuryoku;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: HENSUU.textcolor.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. 氏名(学年)と詳細ボタンの行
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 選手名と学年
                                    Expanded(
                                      child: Text(
                                        '${senshu.name} (${senshu.gakunen}年)',
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // 詳細ボタン
                                    _buildDetailButton(senshu),
                                  ],
                                ),

                                const SizedBox(height: 8.0),
                                // 2. 練習メニューのドロップダウンリストの行
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButton<int>(
                                        value: currentKaifukuryoku,
                                        dropdownColor: HENSUU.backgroundcolor,
                                        isExpanded: true,
                                        iconEnabledColor: _brightGreen,
                                        items: _trainingOptions.entries
                                            .map(
                                              (entry) => DropdownMenuItem<int>(
                                                value: entry.key,
                                                child: Text(
                                                  entry.value,
                                                  style: const TextStyle(
                                                    color: HENSUU.textcolor,
                                                    fontSize:
                                                        HENSUU.fontsize_honbun,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (int? newValue) async {
                                          if (newValue != null) {
                                            await _updateKaifukuryoku(
                                              senshu,
                                              newValue,
                                            );
                                          }
                                        },
                                        selectedItemBuilder:
                                            (BuildContext context) {
                                              return _trainingOptions.entries
                                                  .map((entry) {
                                                    return Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                        color: _brightGreen,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    );
                                                  })
                                                  .toList();
                                            },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
}
