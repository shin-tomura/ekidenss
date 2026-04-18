import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_senshu.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;

  // トレード対象として選択された2名の選手
  SenshuData? _selectedSenshu1;
  SenshuData? _selectedSenshu2;

  // リストの表示を絞り込むための選択中の大学ID（nullの場合は全選手表示）
  int? _filterUnivId;

  @override
  void initState() {
    super.initState();
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
  }

  // タイムを「○分○秒」などに整形する簡易メソッド（既存の time_date.dart のものがある場合はそちらに置き換えてください）
  String _formatTime(int timeValue) {
    if (timeValue <= 0 || timeValue >= 9999) return "記録なし";
    int minutes = timeValue ~/ 60;
    int seconds = timeValue % 60;
    return '$minutes分${seconds.toString().padLeft(2, '0')}秒';
  }

  // 選手を選択・解除するロジック
  void _toggleSelection(SenshuData senshu) {
    setState(() {
      if (_selectedSenshu1?.id == senshu.id) {
        _selectedSenshu1 = null;
      } else if (_selectedSenshu2?.id == senshu.id) {
        _selectedSenshu2 = null;
      } else if (_selectedSenshu1 == null) {
        _selectedSenshu1 = senshu;
      } else if (_selectedSenshu2 == null) {
        _selectedSenshu2 = senshu;
      } else {
        // すでに2人選ばれている場合は1人目を上書き
        _selectedSenshu1 = senshu;
      }
    });
  }

  // トレード確認ダイアログを表示する処理
  void _confirmTrade() {
    if (_selectedSenshu1 == null || _selectedSenshu2 == null) return;

    // 制約: 各学年5名ずつを維持するため、同じ学年の選手同士でのみトレード可能とする
    if (_selectedSenshu1!.gakunen != _selectedSenshu2!.gakunen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('各大学の学年人数を維持するため、同じ学年の選手同士を選択してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 同じ学年であることが確認できた場合、確認ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final univ1Name = _univBox.get(_selectedSenshu1!.univid)?.name ?? '不明';
        final univ2Name = _univBox.get(_selectedSenshu2!.univid)?.name ?? '不明';

        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('トレードの確認', style: TextStyle(color: Colors.white)),
          content: Text(
            '$univ1Name (${_selectedSenshu1!.gakunen}年) の ${_selectedSenshu1!.name} 選手と\n'
            '$univ2Name (${_selectedSenshu2!.gakunen}年) の ${_selectedSenshu2!.name} 選手を\n'
            'トレードしますか？',
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ダイアログを閉じる
              },
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(dialogContext); // ダイアログを閉じる
                _executeTrade(); // 実際のトレード処理を実行
              },
              child: const Text('実行する', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 実際にトレードを実行しデータを保存する処理
  void _executeTrade() async {
    // 大学IDを入れ替える
    int tempUnivId = _selectedSenshu1!.univid;
    _selectedSenshu1!.univid = _selectedSenshu2!.univid;
    _selectedSenshu2!.univid = tempUnivId;

    // Hiveに保存
    await _selectedSenshu1!.save();
    await _selectedSenshu2!.save();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedSenshu1!.name} と ${_selectedSenshu2!.name} の所属大学をトレードしました！',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // 選択状態をリセット
    setState(() {
      _selectedSenshu1 = null;
      _selectedSenshu2 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 大学リスト（絞り込みドロップダウン用）
    List<UnivData> univList = _univBox.values.toList();
    univList.sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor:
          HENSUU.backgroundcolor, // 定数から背景色を取得（必要に応じてColors.grey[900]等に変更）
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('選手トレード', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 上部：選択状況とトレード実行ボタン
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[800],
            child: Column(
              children: [
                const Text('同じ学年のみ交換可能', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 横幅を自動調整するために Expanded で包む
                    Expanded(child: _buildSelectedTargetBox(_selectedSenshu1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Expanded(child: _buildSelectedTargetBox(_selectedSenshu2)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      (_selectedSenshu1 != null && _selectedSenshu2 != null)
                      ? _confirmTrade // _executeTrade から _confirmTrade に変更
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'トレード実行',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 大学絞り込みフィルター
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int?>(
              value: _filterUnivId,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              hint: const Text(
                '全大学を表示',
                style: TextStyle(color: Colors.white70),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('全大学を表示'),
                ),
                ...univList.map((univ) {
                  return DropdownMenuItem<int?>(
                    value: univ.id,
                    child: Text(univ.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filterUnivId = value;
                });
              },
            ),
          ),

          // 選手一覧リスト
          Expanded(
            child: ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: _senshuBox.listenable(),
              builder: (context, senshuBox, _) {
                List<SenshuData> senshuList = senshuBox.values.toList();

                // フィルター適用
                if (_filterUnivId != null) {
                  senshuList = senshuList
                      .where((s) => s.univid == _filterUnivId)
                      .toList();
                }

                // 大学ID昇順、学年降順でソート
                senshuList.sort((a, b) {
                  int univCompare = a.univid.compareTo(b.univid);
                  if (univCompare != 0) return univCompare;
                  return b.gakunen.compareTo(a.gakunen);
                });

                return ListView.builder(
                  itemCount: senshuList.length,
                  itemBuilder: (context, index) {
                    final senshu = senshuList[index];
                    final univName = _univBox.get(senshu.univid)?.name ?? '不明';

                    final isSelected =
                        _selectedSenshu1?.id == senshu.id ||
                        _selectedSenshu2?.id == senshu.id;

                    return Card(
                      color: isSelected ? Colors.green[900] : Colors.grey[850],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1行目: 大学名、学年、氏名
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$univName (${senshu.gakunen}年)  ${senshu.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // 選択チェックボックス的なアイコン
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Colors.greenAccent
                                      : Colors.white54,
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            // 2行目: 各種ベスト記録
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRecordText(
                                  '5千',
                                  senshu.time_bestkiroku[0],
                                ),
                                _buildRecordText(
                                  '1万',
                                  senshu.time_bestkiroku[1],
                                ),
                                _buildRecordText(
                                  'ハーフ',
                                  senshu.time_bestkiroku[2],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 3行目: ボタン類
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.8,
                                      ),
                                      barrierDismissible: true,
                                      barrierLabel: '詳細',
                                      transitionDuration: const Duration(
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
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.lightBlueAccent,
                                    side: const BorderSide(
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                  child: const Text('詳細'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _toggleSelection(senshu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.redAccent
                                        : HENSUU.LinkColor,
                                  ),
                                  child: Text(isSelected ? '選択解除' : '選択する'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 上部の選択中選手を表示するボックス
  Widget _buildSelectedTargetBox(SenshuData? senshu) {
    return Container(
      // 固定値（width:140, height:60）を削除し、動的なサイズを許可する
      constraints: const BoxConstraints(minHeight: 60), // 文字が小さい時でも最低限の高さは確保
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ), // 内側に余白を付与
      decoration: BoxDecoration(
        color: Colors.grey[700],
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: senshu == null
          ? const Text('未選択', style: TextStyle(color: Colors.white54))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 要素の高さに合わせてColumnの高さを最小に留める
              children: [
                Text(
                  _univBox.get(senshu.univid)?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2, // 文字拡大時に備えて2行まで許容
                ),
                const SizedBox(height: 4), // 少し間隔を空ける
                Text(
                  '${senshu.gakunen}年 ${senshu.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
    );
  }

  // 記録表示用のテキストウィジェット
  Widget _buildRecordText(String label, double timeValue) {
    String hyojitime;
    if (timeValue == TEISUU.DEFAULTTIME) {
      hyojitime = "記録なし";
    } else {
      hyojitime = TimeDate.timeToFunByouString(timeValue);
    }
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          hyojitime,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
