import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
//import 'package:ekiden/ghensuu.dart';

class SummerTTModeSelectScreen extends StatefulWidget {
  const SummerTTModeSelectScreen({super.key});

  @override
  State<SummerTTModeSelectScreen> createState() =>
      _SummerTTModeSelectScreenState();
}

class _SummerTTModeSelectScreenState extends State<SummerTTModeSelectScreen> {
  late Box<KantokuData> _kantokuBox;
  KantokuData? _kantoku;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Hiveから監督データを取得
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _kantoku = _kantokuBox.get('KantokuData');
  }

  /// 夏の学内タイムトライアルモードの切り替え実行
  Future<void> _toggleSummerTTMode() async {
    final k = _kantoku;
    if (k == null) return;

    setState(() => _isProcessing = true);

    try {
      // yobiint2[19] を反転 (1なら0、0なら1)
      final int currentMode = k.yobiint2[19];
      final int newMode = currentMode == 1 ? 0 : 1;

      k.yobiint2[19] = newMode;

      // Hiveのデータ保存
      await k.save();

      if (mounted) {
        final message = newMode == 1
            ? '全大学でのタイムトライアル開催に設定しました'
            : '自大学のみのタイムトライアル開催に設定しました';

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.greenAccent.shade700,
            duration: const Duration(seconds: 2),
          ),
        );

        // 成功後、少し待ってから前の画面に戻る
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('設定の保存中にエラーが発生しました。')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 現在のモード判定（1:全大学, 0:自大学のみ）
    final bool isAllUniversity = _kantoku?.yobiint2[19] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F26),
      appBar: AppBar(
        title: const Text('タイムトライアル設定'),
        backgroundColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 上部：ステータスおよび切り替えボタン
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  const Text(
                    '夏の学内タイムトライアル設定',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAllUniversity ? '【全大学開催】' : '【プレイヤー大学のみ】',
                    style: TextStyle(
                      color: isAllUniversity
                          ? Colors.orangeAccent
                          : Colors.cyanAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAllUniversity
                            ? Colors.blueGrey.shade700
                            : Colors.deepOrangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isProcessing ? null : _toggleSummerTTMode,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAllUniversity ? '自大学のみ開催に変更' : '全大学開催に変更',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 下部：説明エリア
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('モードの詳細説明'),
                    _buildDescriptionText(
                      '● 全大学開催モード\n'
                      'ライバル大学を含むすべての大学で夏の学内タイムトライアル（登り・下り・ロード・クロカン）が実行されます。ゲーム全体の戦力把握やリアリティを重視する場合に適しています。',
                    ),
                    const SizedBox(height: 20),
                    _buildDescriptionText(
                      '● プレイヤー大学のみモード（初期値）\n'
                      '操作している大学のみタイムトライアルを行います。シミュレーション時間を短縮したい場合に適しています。',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: HENSUU.textcolor,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }
}
