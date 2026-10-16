import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';

/// レーダーチャートのパネル(分析パネル)を出すか(kantoku.yobiint2[20])
/// ・一の位(奇数か)が選手画面(他大学の選手の詳細の小窓も)、2の位が大学画面(2.0.3)。どちらも0なら表示(初期値)
/// ・2.0.2までは選手画面だけで、0=表示・1=非表示だったので、今までのデータもそのまま読める
bool chartPanelHyouji(KantokuData kantoku, {bool daigaku = false}) {
  final int v = kantoku.yobiint2[20];
  return daigaku ? (v ~/ 2) % 2 == 0 : v % 2 == 0;
}

class AnalysisPanelConfigScreen extends StatefulWidget {
  const AnalysisPanelConfigScreen({super.key, this.daigaku = false});

  /// 大学画面のパネルの切り替えか(false なら選手画面。2.0.3)
  final bool daigaku;

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
      // yobiint2[20] のその画面の位だけを反転する(一の位が選手画面、2の位が大学画面。2.0.3)
      // その位が 0: 表示, 1: 非表示
      final int kurai = widget.daigaku ? 2 : 1;
      final bool imaHyouji = chartPanelHyouji(k, daigaku: widget.daigaku);
      k.yobiint2[20] = imaHyouji ? k.yobiint2[20] + kurai : k.yobiint2[20] - kurai;
      final bool newHyouji = !imaHyouji;

      // Hiveのデータ保存
      await k.save();

      if (mounted) {
        final String gamen = widget.daigaku ? '大学画面' : '選手画面';
        final message = newHyouji
            ? '$gamenの分析パネルを表示に設定しました'
            : '$gamenの分析パネルを非表示に設定しました';

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
    final KantokuData? kd = _kantoku;
    final bool isPanelVisible = kd == null || chartPanelHyouji(kd, daigaku: widget.daigaku);

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
                  Text(
                    widget.daigaku ? '大学画面：分析パネル設定' : '選手詳細画面：分析パネル設定',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
                    if (widget.daigaku)
                      _buildDescriptionText(
                        '各種目の上位10人の平均タイムから、大学の力を「スピード」「スタミナ」「山適性」「ロード」「起伏耐性」の5つの指標でレーダーチャート化し、総合評価と二つ名・分析文を添えたパネルです。',
                      )
                    else
                      _buildDescriptionText(
                        '各選手の能力を「スピード」「スタミナ」「ロード」「山適性」「起伏耐性」の5つの指標でレーダーチャート化し、総合評価を算出したパネルです。',
                      ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('非表示にするメリット'),
                    if (widget.daigaku) ...[
                      _buildDescriptionText(
                        '● 画面のスクロール量を減らし、監督や大会の成績などの確認を優先できます。',
                      ),
                      _buildDescriptionText(
                        '● パネルの中の「自己ベスト/今季ベスト」の切り替えも一緒に隠れます(ほかの画面の切り替えと同じ設定です)。',
                      ),
                    ] else
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
