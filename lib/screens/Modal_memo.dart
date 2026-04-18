import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // クリップボード操作に必要
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/univ_data.dart'; // UnivDataクラスの定義が必要
// KantokuDataクラスの定義があるファイルをインポートしてください
import 'package:ekiden/kantoku_data.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  // 5つのメモ用コントローラー
  final List<TextEditingController> _memoControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  // 現在選択されているメモのインデックス (0=メモ1, 1=メモ2, ... 4=メモ5)
  int _currentIndex = 0;

  late Box<UnivData> _univBox;
  // 何度もgetしないようにメンバ変数として保持
  KantokuData? _myKantokuData;

  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMemoData();
  }

  @override
  void dispose() {
    // 全てのコントローラーを破棄
    for (var controller in _memoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// データの読み込み処理
  Future<void> _loadMemoData() async {
    // ボックスが開いているか確認
    if (!Hive.isBoxOpen('univBox')) {
      return;
    }
    _univBox = Hive.box<UnivData>('univBox');

    // KantokuBoxの取得とデータのキャッシュ
    if (Hive.isBoxOpen('kantokuBox')) {
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      // ここで一度だけ取得してメンバ変数に入れる
      _myKantokuData = kantokuBox.get('KantokuData');
    }

    final List<UnivData> sortedUnivData = _univBox.values.toList();
    // ID順にソート
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    // 1. 初期表示するメモ番号を保持データから取得
    if (_myKantokuData != null) {
      // yobiint2[23]の値を取得（範囲外チェック含む）
      int savedIndex = 0;
      if (_myKantokuData!.yobiint2.length > 23) {
        savedIndex = _myKantokuData!.yobiint2[23];
      }
      // 0〜4の範囲に収める
      if (savedIndex >= 0 && savedIndex < 5) {
        _currentIndex = savedIndex;
      }
    }

    // 2. 各メモデータをコントローラーにセット
    // sortedUnivData[13] -> メモ1 ... sortedUnivData[17] -> メモ5
    for (int i = 0; i < 5; i++) {
      int dataIndex = 13 + i;
      if (sortedUnivData.length > dataIndex) {
        _memoControllers[i].text = sortedUnivData[dataIndex].name_tanshuku;
      } else {
        _memoControllers[i].text = "";
      }
    }

    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  /// メモタブ切り替え時の処理
  /// 画面上の表示を切り替え、即座にその番号を保存する
  Future<void> _switchMemo(int index) async {
    // UIを即座に更新
    setState(() {
      _currentIndex = index;
    });

    // 保持しているデータを使って保存
    if (_myKantokuData != null && _myKantokuData!.yobiint2.length > 23) {
      try {
        _myKantokuData!.yobiint2[23] = _currentIndex;
        await _myKantokuData!.save(); // HiveObjectを継承していればこれで保存可能
      } catch (e) {
        debugPrint('インデックス保存エラー: $e');
      }
    }
  }

  /// データの保存処理（テキスト内容の保存）
  /// 現在のタブの内容を sortedUnivData[13 + index] に保存する
  Future<void> _saveMemo() async {
    try {
      final List<UnivData> sortedUnivData = _univBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

      int dataIndex = 13 + _currentIndex; // 保存先のインデックス

      if (sortedUnivData.length > dataIndex) {
        // 1. メモの内容を格納
        sortedUnivData[dataIndex].name_tanshuku =
            _memoControllers[_currentIndex].text;
        await sortedUnivData[dataIndex].save();

        // 2. 現在のタブ番号も念のため保存（_switchMemoで保存済みだが念のため）
        if (_myKantokuData != null && _myKantokuData!.yobiint2.length > 23) {
          _myKantokuData!.yobiint2[23] = _currentIndex;
          await _myKantokuData!.save();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('メモ${_currentIndex + 1}を保存しました'),
              backgroundColor: Colors.blueAccent,
              duration: const Duration(seconds: 1),
            ),
          );
          // キーボードを閉じる
          FocusScope.of(context).unfocus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データ保存先が見つかりません（データ不足）')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存中にエラーが発生しました: $e')));
      }
    }
  }

  /// クリップボードにコピーする処理
  void _copyToClipboard() {
    final String text = _memoControllers[_currentIndex].text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('コピーする内容がありません')));
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メモの内容をコピーしました'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  /// メモ切り替えタブのボタンウィジェット
  Widget _buildTabButton(int index) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMemo(index), // ここで保存処理付きの切り替えメソッドを呼ぶ
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyanAccent.withOpacity(0.3)
                : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              'メモ${index + 1}',
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F26),
      appBar: AppBar(
        title: const Text('フリーメモ'),
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: _copyToClipboard,
            tooltip: 'コピー',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.cyanAccent),
            onPressed: _saveMemo,
            tooltip: '保存',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // メモ切り替えタブエリア
                Row(
                  children: List.generate(5, (index) => _buildTabButton(index)),
                ),
                const SizedBox(height: 10),

                /*// 現在のメモの説明
                Text(
                  'メモ${_currentIndex + 1} を編集中',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),*/
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _isLoaded
                        ? TextField(
                            // 現在選択中のインデックスに対応するコントローラーを使用
                            controller: _memoControllers[_currentIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                              hintText: 'メモ${_currentIndex + 1}を入力...',
                              hintStyle: const TextStyle(color: Colors.white30),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),

                // 【変更点】余白を少し削って警告文のスペースを作る
                const SizedBox(height: 8),

                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  height: 44, // 【変更点】高さを50から44に少し削る
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: Text('メモ${_currentIndex + 1}を保存する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      foregroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveMemo,
                  ),
                ),

                // 【追加点】ボタンとテキストの間の微小な余白
                const SizedBox(height: 4),

                // 【追加点】警告メッセージ
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '※このメモもセーブデータに含まれますので、共有される場合には、個人情報の漏洩や権利侵害にご注意ください',
                    style: TextStyle(color: Colors.yellowAccent, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
