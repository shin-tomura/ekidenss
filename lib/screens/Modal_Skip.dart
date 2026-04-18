import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // クリップボード操作に必要
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/toukei.dart';

class StatisticsSimulationScreen extends StatefulWidget {
  const StatisticsSimulationScreen({super.key});

  @override
  State<StatisticsSimulationScreen> createState() =>
      _StatisticsSimulationScreenState();
}

class _StatisticsSimulationScreenState
    extends State<StatisticsSimulationScreen> {
  bool _isProcessing = false;
  double _selectedYears = 1.0; // デフォルトのスキップ年数

  late Box<Skip> _skipBox;
  late Box<UnivData> _univBox;
  late Box<Ghensuu> _ghensuuBox;

  @override
  void initState() {
    super.initState();
    _skipBox = Hive.box<Skip>('skipBox');
    _univBox = Hive.box<UnivData>('univBox');
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  }

  /// テキストをクリップボードにコピーする
  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('統計データをクリップボードにコピーしました'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  /// 通常モードに戻す処理
  Future<void> _resetToNormalMode() async {
    setState(() => _isProcessing = true);
    try {
      final Skip skip = _skipBox.get('SkipData')!;
      skip.skipflag = 0;
      await skip.save();
      await WakelockPlus.disable();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('通常モードに戻しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('設定の変更に失敗しました')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// スキップ設定を保存して閉じる（確認ダイアログ付き）
  Future<void> _confirmAndSetup() async {
    final int years = _selectedYears.toInt();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C313C),
          title: const Text('⚠️ 実行確認', style: TextStyle(color: Colors.white)),
          content: Text(
            '現在の統計をリセットし、$years年後の3月下旬までのスキップを予約します。\n\n'
            '【重要】スキップ開始後は、計算が完了するまでアプリ内での中断はできません。'
            '（中断するにはアプリの強制終了が必要になります）',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '了解して予約',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      EkidenStatistics.instance.resetAllStats();
      await WakelockPlus.enable();

      final Ghensuu ghensuu = _ghensuuBox.get('global_ghensuu')!;
      final Skip skip = _skipBox.get('SkipData')!;
      skip.skipflag = 3;
      skip.skipyear = ghensuu.year + years; // 選択された年数を加算
      // すべての統計フィールドを初期値で上書き（冗長版）
      skip.totaltime_jap_all = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_13pundai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun00dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun10dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun20dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun30dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun40dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_14pun50dai = [0.0, 0.0, 0.0, 0.0];
      skip.totaltime_jap_15pundai = [0.0, 0.0, 0.0, 0.0];
      skip.count_jap_all = [0, 0, 0, 0];
      skip.count_jap_13pundai = [0, 0, 0, 0];
      skip.count_jap_14pun00dai = [0, 0, 0, 0];
      skip.count_jap_14pun10dai = [0, 0, 0, 0];
      skip.count_jap_14pun20dai = [0, 0, 0, 0];
      skip.count_jap_14pun30dai = [0, 0, 0, 0];
      skip.count_jap_14pun40dai = [0, 0, 0, 0];
      skip.count_jap_14pun50dai = [0, 0, 0, 0];
      skip.count_jap_15pundai = [0, 0, 0, 0];
      skip.totaltime_ryuugakusei = [0.0, 0.0, 0.0, 0.0];
      skip.count_ryuugakusei = [0, 0, 0, 0];
      // ベストタイム系は定義通りの定数で初期化
      skip.besttime_ryuugakusei = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_all = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_13pundai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun00dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun10dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun20dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun30dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun40dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_14pun50dai = List.filled(4, TEISUU.DEFAULTTIME);
      skip.besttime_jap_15pundai = List.filled(4, TEISUU.DEFAULTTIME);
      await skip.save();
      final List<UnivData> sortedUnivData = _univBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      sortedUnivData[12].name_tanshuku = "";
      await sortedUnivData[12].save();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$years年スキップの準備が完了しました。最新画面で進むを押下すればスキップが開始されます。'),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存エラーが発生しました')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Skip? skipData = _skipBox.get('SkipData');
    final bool isSkipMode = skipData?.skipflag == 3;

    final List<UnivData> sortedUnivData = _univBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    final String statsResult = sortedUnivData.length > 12
        ? sortedUnivData[12].name_tanshuku
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F26),
      appBar: AppBar(
        title: const Text('統計・長期スキップ設定'),
        backgroundColor: Colors.black26,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 説明文と結果表示
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: const Border(
                          bottom: BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 現在の状態表示
                          _buildStatusBadge(isSkipMode),
                          const SizedBox(height: 20),

                          // 年数選択スライダー
                          Text(
                            "スキップ年数: ${_selectedYears.toInt()} 年",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: _selectedYears,
                            min: 1,
                            max: 30,
                            divisions: 29,
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.white10,
                            label: "${_selectedYears.toInt()}年",
                            onChanged: isSkipMode
                                ? null
                                : (value) {
                                    setState(() => _selectedYears = value);
                                  },
                          ),
                          const SizedBox(height: 10),

                          // メインボタン
                          SizedBox(
                            width: double.infinity,
                            height: 100,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.analytics),
                              label: Text(
                                '${_selectedYears.toInt()}年スキップ統計を予約する',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isProcessing || isSkipMode
                                  ? null
                                  : _confirmAndSetup,
                            ),
                          ),

                          // キャンセルボタン
                          if (isSkipMode) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 100,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('スキップ予約を解除（通常に戻す）'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isProcessing
                                    ? null
                                    : _resetToNormalMode,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    _buildSectionTitle('⚠️ 注意事項'),
                    _buildDescriptionText_strong(
                      '・端末を充電しながら実行することを強く推奨します。\n'
                      '・計算開始後は、指定した年数が経過するまでアプリ内から中断することはできません。\n'
                      '・スマホの負荷を抑える設定で実行しますが、スキップ予約後は画面が表示されたままになり、長時間点灯と計算により端末が熱くなる場合があります。\n'
                      '・前回の統計データはスキップ予約でリセットされます。',
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildSectionTitle('この機能の目的'),
                    _buildDescriptionText(
                      'コース編集や各種設定の下で、どの程度のタイムが出るのかを確認できるようにするために実装しました。スキップ後、この画面下部の統計データ欄にスキップ中に集計したデータが表示されます。',
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildSectionTitle('スキップ予約をしたら'),
                    _buildDescriptionText(
                      '最新画面に戻り、進むボタンを押下してください。スキップが始まります。\n指定年数後の3月下旬までスキップします。',
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildSectionTitle('スキップが終了したら'),
                    _buildDescriptionText('この画面に戻り、画面下部の最新の統計データをご確認ください。'),

                    const Divider(color: Colors.white24, height: 40),

                    // 統計データヘッダー（タイトルとコピーボタン）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('最新の統計データ'),
                        if (statsResult.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(statsResult),
                            icon: const Icon(
                              Icons.copy,
                              size: 18,
                              color: Colors.cyanAccent,
                            ),
                            label: const Text(
                              'コピー',
                              style: TextStyle(color: Colors.cyanAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 統計データ表示エリア
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        statsResult.isEmpty ? "（データなし）" : statsResult,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
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

  Widget _buildStatusBadge(bool isSkipMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSkipMode
            ? Colors.orangeAccent.withOpacity(0.1)
            : Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSkipMode ? Colors.orangeAccent : Colors.greenAccent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSkipMode ? Icons.pause_circle_filled : Icons.check_circle,
            color: isSkipMode ? Colors.orangeAccent : Colors.greenAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isSkipMode ? "長期スキップ予約中" : "現在通常モード",
            style: TextStyle(
              color: isSkipMode ? Colors.orangeAccent : Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.zero, // Rowの中で調整するためゼロに
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionText_strong(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
    );
  }

  Widget _buildDescriptionText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
    );
  }
}
