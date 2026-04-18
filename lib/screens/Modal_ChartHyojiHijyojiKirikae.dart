import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';

class AnalysisPanelConfigScreen extends StatefulWidget {
  const AnalysisPanelConfigScreen({super.key});

  @override
  State<AnalysisPanelConfigScreen> createState() =>
      _AnalysisPanelConfigScreenState();
}

class _AnalysisPanelConfigScreenState extends State<AnalysisPanelConfigScreen> {
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

  /// 分析パネル表示設定の切り替え実行
  Future<void> _toggleAnalysisPanelMode() async {
    final k = _kantoku;
    if (k == null) return;

    setState(() => _isProcessing = true);

    try {
      // yobiint2[20] を反転 (0なら1、1なら0)
      // 0: 表示, 1: 非表示
      final int currentMode = k.yobiint2[20];
      final int newMode = currentMode == 0 ? 1 : 0;

      k.yobiint2[20] = newMode;

      // Hiveのデータ保存
      await k.save();

      if (mounted) {
        final message = newMode == 0
            ? '選手画面の分析パネルを表示に設定しました'
            : '選手画面の分析パネルを非表示に設定しました';

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.cyanAccent.shade700,
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
    // 現在のモード判定（0:表示, 1:非表示）
    final bool isPanelVisible = (_kantoku?.yobiint2[20] ?? 0) == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F26),
      appBar: AppBar(
        title: const Text('表示カスタマイズ'),
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
                    '選手詳細画面：分析パネル設定',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPanelVisible ? '【パネルを表示中】' : '【パネルを非表示】',
                    style: TextStyle(
                      color: isPanelVisible ? Colors.cyanAccent : Colors.grey,
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
                        backgroundColor: isPanelVisible
                            ? Colors.redAccent.withOpacity(0.8)
                            : Colors.cyanAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : _toggleAnalysisPanelMode,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isPanelVisible ? 'パネルを非表示にする' : 'パネルを表示する',
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
                    _buildSectionTitle('分析パネルとは'),
                    _buildDescriptionText(
                      '各選手の能力を「スピード」「スタミナ」「ロード」「山適性」「起伏耐性」の5つの指標でレーダーチャート化し、総合評価を算出したパネルです。',
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('非表示にするメリット'),
                    _buildDescriptionText(
                      '● 画面のスクロール量を減らし、基本データ（タイムや学年）の確認を優先できます。',
                    ),
                    /*const SizedBox(height: 20),
                    const Card(
                      color: Colors.white10,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '設定は選手詳細画面を再度開いた際に適用されます。',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),*/
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
    );
  }
}
