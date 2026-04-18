import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';

class SimulationModeSelectScreen extends StatefulWidget {
  const SimulationModeSelectScreen({super.key});

  @override
  State<SimulationModeSelectScreen> createState() =>
      _SimulationModeSelectScreenState();
}

class _SimulationModeSelectScreenState
    extends State<SimulationModeSelectScreen> {
  // ボックスと監督データをクラスのプロパティとして定義
  late Box<KantokuData> _kantokuBox;
  KantokuData? _kantoku;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // initStateでボックスを開き、データを取得する
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _kantoku = _kantokuBox.get('KantokuData');
  }

  /// 箱庭モードの切り替え実行
  Future<void> _toggleHakoniwaMode() async {
    // _kantokuがnullの場合は処理しない
    final k = _kantoku;
    if (k == null) return;

    setState(() => _isProcessing = true);

    try {
      // 現在の状態を反転 (1なら0、0なら1)
      final int currentMode = k.yobiint2[17];
      final int newMode = currentMode == 1 ? 0 : 1;

      k.yobiint2[17] = newMode;
      // Hiveのデータ保存
      await k.save();

      if (k.yobiint2[17] == 1) {
        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
        for (int i = 0; i < 10; i++) {
          currentGhensuu.nouryokumieruflag[i] = 1;
        }
        await currentGhensuu.save();
      }

      if (mounted) {
        final message = newMode == 1 ? '箱庭モードをONにしました' : '通常モードに戻しました';
        // 1. 念のため現在出ているスナックバーをすべてクリア
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );

        // 少し待ってから前の画面に戻る
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
    // 現在のモード判定（null安全を考慮）
    final bool isHakoniwa = _kantoku?.yobiint2[17] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F26),
      appBar: AppBar(
        title: const Text('モード設定'),
        backgroundColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 上部：アクションエリア
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  Text(
                    isHakoniwa ? '現在：箱庭モード有効' : '現在：通常モード',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHakoniwa
                            ? Colors.orangeAccent
                            : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isProcessing ? null : _toggleHakoniwaMode,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isHakoniwa ? '通常モードへ戻す' : '箱庭モードに切り替える',
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
                        '変更せずに戻る',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 下部：説明文
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('箱庭モードとは'),
                    _buildDescriptionText(
                      '箱庭モードでは、選手の能力値を自由に編集できるだけでなく、通常は隠されている内部的な基本走力値までカスタマイズ可能になります。 \nそして、最大の特徴は、大会の支配権があなたに委ねられることです。自チームのみならず、全出場校のエントリー、当日変更、さらにはレース中の指示や目標順位までを自在にコントロールできます。 現実の再現か、理想の展開か。あなただけの箱庭小駅伝の世界を、思う存分構築してください。',
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
