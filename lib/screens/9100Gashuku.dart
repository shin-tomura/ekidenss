import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_gold.dart';
import 'package:ekiden/screens/Modal_silver.dart';
import 'package:ekiden/screens/Modal_koukan.dart'; // ModalBallExchange をインポート
import 'package:ekiden/kansuu/time_date.dart';

class GashukuScreen extends StatefulWidget {
  const GashukuScreen({super.key});

  @override
  State<GashukuScreen> createState() => _GashukuScreenState();
}

class _GashukuScreenState extends State<GashukuScreen> {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;

  Ghensuu? _ghensuu;
  late List<SenshuData> _myUnivmen;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _ghensuu = _ghensuuBox.getAt(0);

    if (_ghensuu != null) {
      final myUnivId = _ghensuu!.MYunivid;
      _myUnivmen = _senshuBox.values.where((s) => s.univid == myUnivId).toList()
        ..sort((a, b) {
          final gakunenComparison = b.gakunen.compareTo(a.gakunen);
          if (gakunenComparison != 0) {
            return gakunenComparison;
          }
          return a.id.compareTo(b.id);
        });
    } else {
      _myUnivmen = [];
    }
    setState(() {});
  }

  String _timeToMinuteSecondString(double time) {
    if (time == TEISUU.DEFAULTTIME) return '記録無';
    final int minutes = (time / 60).floor();
    final double remainingSeconds = time % 60;
    return '$minutes:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
  }

  void _showTokkunModal(SenshuData player, String type) {
    print('$type 特訓ボタンが押されました: ${player.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$type 特訓', style: const TextStyle(color: Colors.black)),
          content: Text(
            '${player.name}選手の$type 特訓画面です。\n（後で実装します）',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('合宿終了の確認', style: TextStyle(color: Colors.black)),
          content: const Text(
            '本当に合宿を終了しますか？',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _ghensuu!.mode = 700; // 合宿終了モード
                });
                await _ghensuu!.save();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ボール交換モーダルを表示するダイアログ
  void _showBallExchangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ModalBallExchange(); // ModalBallExchange ウィジェットを返します
      },
    ).then((_) {
      // モーダルが閉じられた後にsetStateを呼び出して画面を更新
      setState(() {});
    });
  }

  Widget _buildAbilityRow(String label, int flag, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          Text(
            flag == 1 ? value.toString() : '??',
            style: TextStyle(
              color: flag == 1 ? Colors.white : Colors.grey,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestRecordRow(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time != TEISUU.DEFAULTTIME
                ? '$label: ${TimeDate.timeToFunByouString(time)}'
                : '$label: 記録なし',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          if (time != TEISUU.DEFAULTTIME)
            Row(
              children: [
                Text(
                  '学内: ${gakunaiJuni + 1}位',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
                if (zentaiJuni != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    '全体: ${zentaiJuni + 1}位',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBestRecordRow_full(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time != TEISUU.DEFAULTTIME
                ? '$label: ${TimeDate.timeToJikanFunByouString(time)}'
                : '$label: 記録なし',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          if (time != TEISUU.DEFAULTTIME)
            Row(
              children: [
                Text(
                  '学内: ${gakunaiJuni + 1}位',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
                if (zentaiJuni != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    '全体: ${zentaiJuni + 1}位',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ghensuu == null || _myUnivmen == null) {
      return const Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myUniv = _univBox.get(_ghensuu!.MYunivid);

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: Text('夏合宿', style: const TextStyle(color: HENSUU.textcolor)),
        backgroundColor: Colors.grey[900],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '金：${_ghensuu?.goldenballsuu ?? 0} 銀：${_ghensuu?.silverballsuu ?? 0}',
                style: const TextStyle(color: HENSUU.textcolor, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _myUnivmen.length,
                itemBuilder: (context, index) {
                  final player = _myUnivmen[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 選手名と学年
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: HENSUU.fontsize_honbun,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      '(${player.gakunen}年)',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: HENSUU.fontsize_honbun - 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 金特訓・銀特訓ボタン
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_ghensuu != null) {
                                        _ghensuu!.hyojisenshunum = index;
                                        await _ghensuu!.save();
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return const ModalTokkunGold();
                                        },
                                      ).then((_) {
                                        setState(() {});
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('金特訓'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_ghensuu != null) {
                                        _ghensuu!.hyojisenshunum = index;
                                        await _ghensuu!.save();
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return const ModalTokkunSilver();
                                        },
                                      ).then((_) {
                                        setState(() {});
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('銀特訓'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 各種ベスト記録
                          _buildBestRecordRow(
                            '5千best',
                            player.time_bestkiroku[0],
                            player.gakunaijuni_bestkiroku[0],
                            player.zentaijuni_bestkiroku.length > 0
                                ? player.zentaijuni_bestkiroku[0]
                                : null,
                          ),
                          _buildBestRecordRow(
                            '1万best',
                            player.time_bestkiroku[1],
                            player.gakunaijuni_bestkiroku[1],
                            player.zentaijuni_bestkiroku.length > 1
                                ? player.zentaijuni_bestkiroku[1]
                                : null,
                          ),
                          _buildBestRecordRow(
                            'ハーフbest',
                            player.time_bestkiroku[2],
                            player.gakunaijuni_bestkiroku[2],
                            player.zentaijuni_bestkiroku.length > 2
                                ? player.zentaijuni_bestkiroku[2]
                                : null,
                          ),
                          _buildBestRecordRow_full(
                            'フルbest',
                            player.time_bestkiroku[3],
                            player.gakunaijuni_bestkiroku[3],
                            player.zentaijuni_bestkiroku.length > 3
                                ? player.zentaijuni_bestkiroku[3]
                                : null,
                          ),
                          _buildBestRecordRow(
                            '登り1万best',
                            player.time_bestkiroku[4],
                            player.gakunaijuni_bestkiroku[4],
                            null,
                          ),
                          _buildBestRecordRow(
                            '下り1万best',
                            player.time_bestkiroku[5],
                            player.gakunaijuni_bestkiroku[5],
                            null,
                          ),
                          _buildBestRecordRow(
                            'ロード1万best',
                            player.time_bestkiroku[6],
                            player.gakunaijuni_bestkiroku[6],
                            null,
                          ),
                          _buildBestRecordRow(
                            'クロカン1万best',
                            player.time_bestkiroku[7],
                            player.gakunaijuni_bestkiroku[7],
                            null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '能力',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 各種能力値
                          _buildAbilityRow(
                            '駅伝男',
                            _ghensuu!.nouryokumieruflag.length > 0
                                ? _ghensuu!.nouryokumieruflag[0]
                                : 0,
                            player.konjou,
                          ),
                          _buildAbilityRow(
                            '平常心',
                            _ghensuu!.nouryokumieruflag.length > 1
                                ? _ghensuu!.nouryokumieruflag[1]
                                : 0,
                            player.heijousin,
                          ),
                          _buildAbilityRow(
                            '長距離粘り',
                            _ghensuu!.nouryokumieruflag.length > 2
                                ? _ghensuu!.nouryokumieruflag[2]
                                : 0,
                            player.choukyorinebari,
                          ),
                          _buildAbilityRow(
                            'スパート力',
                            _ghensuu!.nouryokumieruflag.length > 3
                                ? _ghensuu!.nouryokumieruflag[3]
                                : 0,
                            player.spurtryoku,
                          ),
                          _buildAbilityRow(
                            'カリスマ',
                            _ghensuu!.nouryokumieruflag.length > 4
                                ? _ghensuu!.nouryokumieruflag[4]
                                : 0,
                            player.karisuma,
                          ),
                          _buildAbilityRow(
                            '登り適性',
                            _ghensuu!.nouryokumieruflag.length > 5
                                ? _ghensuu!.nouryokumieruflag[5]
                                : 0,
                            player.noboritekisei,
                          ),
                          _buildAbilityRow(
                            '下り適性',
                            _ghensuu!.nouryokumieruflag.length > 6
                                ? _ghensuu!.nouryokumieruflag[6]
                                : 0,
                            player.kudaritekisei,
                          ),
                          _buildAbilityRow(
                            'アップダウン対応力',
                            _ghensuu!.nouryokumieruflag.length > 7
                                ? _ghensuu!.nouryokumieruflag[7]
                                : 0,
                            player.noborikudarikirikaenouryoku,
                          ),
                          _buildAbilityRow(
                            'ロード適性',
                            _ghensuu!.nouryokumieruflag.length > 8
                                ? _ghensuu!.nouryokumieruflag[8]
                                : 0,
                            player.tandokusou,
                          ),
                          _buildAbilityRow(
                            'ペース変動対応力',
                            _ghensuu!.nouryokumieruflag.length > 9
                                ? _ghensuu!.nouryokumieruflag[9]
                                : 0,
                            player.paceagesagetaiouryoku,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(color: HENSUU.textcolor),
          // ボール交換と合宿終了ボタンを画面下部に配置
          // Row全体をPaddingで囲み、上部の余白を調整します。
          Padding(
            padding: const EdgeInsets.only(
              bottom: 30.0,
              left: 8.0,
              right: 8.0,
            ), // 下部、左右のパディングのみ適用
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // ボタンを等間隔に配置
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                    ), // ボタン間の横パディング
                    child: ElevatedButton(
                      onPressed: _showBallExchangeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "金銀交換",
                        style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // ボタン間のスペース
                // 修正後のExpandedウィジェット
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // ここに条件分岐を追加
                        if (_ghensuu!.goldenballsuu < 10 &&
                            _ghensuu!.silverballsuu < 10) {
                          // 両方とも10未満の場合、確認ダイアログをスキップして直接終了処理へ
                          setState(() {
                            _ghensuu!.mode = 700; // 合宿終了モード
                          });
                          await _ghensuu!.save();
                        } else {
                          // どちらか、または両方が10以上の場合、確認ダイアログを表示
                          _showExitConfirmationDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "合宿終了",
                        style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
