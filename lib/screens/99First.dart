import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/save_load_screen.dart';
import 'package:ekiden/kansuu/ShoriGuard.dart';
import 'package:ekiden/kansuu/mokuhyou_kimekata.dart'; // 目標順位の決め方を変えたお知らせ(2.0.1)
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku, resetSaiKakunin; // 残るもの・戻るものの一覧と、もう一度確かめるダイアログ(2.0.6)

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  @override
  void initState() {
    super.initState();
    // 起動時の移行で、コンピュータの大学の目標順位の決め方を変えていれば、一度だけお知らせを出す
    // (2.0.1。mokuhyou_kimekata.dart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mokuhyouKimekataOshiraseDialog(context);
    });
  }

  // 新規ゲームを始める(main.dart の mode。101010=名声・育成力と設定を残すリセット、10=全てリセット)
  Future<void> _shinkiKaishi(int mode) async {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    currentGhensuu.mode = mode;
    currentGhensuu.gamenflag = 0; // 最新の画面にしておく(1.9.5)
    await currentGhensuu.save();
  }

  // 新規ゲーム開始の確認ダイアログを表示する関数
  // 2.0.6から、設定タブの「名声・育成力と設定を残してやり直す」と同じリセットで始める
  // (2.0.5までは「全てリセットしてやり直す」と同じで、変えていた設定が黙って初期値に戻っていたため)。
  // 全て初期値に戻すほうも、ダイアログの中に小さく残す(残した設定がもとで新規ゲームの処理が
  // 止まったときも、設定タブを開かずに全てリセットを選べるように)
  Future<void> _showNewGameConfirmDialog(BuildContext context) async {
    const TextStyle honbun = TextStyle(color: Colors.white70, height: 1.6);
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ダイアログ外をタップしても閉じない
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          // 文字を大きくしても、本文をスクロールで読めるようにする
          scrollable: true,
          title: const Text(
            '新規ゲーム開始の確認',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '選手・記録・年月日などのゲームの進み具合を消して、1年目から始めます。'
                'アルバムも消去されます。',
                style: honbun,
              ),
              const SizedBox(height: 8),
              const Text(
                '名声・育成力と、レースや育成などの設定、表示の好みはそのまま残ります。'
                '元には戻せません。',
                style: honbun,
              ),
              // 残るもの・戻るものの一覧(reset_ichiran_gamen.dart。閉じると、このダイアログに戻る)
              TextButton(
                onPressed: () => resetIchiranGamenHiraku(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  '残るもの・戻るものの一覧',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00FF00),
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              const Text(
                '名声・育成力と設定も初期値に戻したいときだけ',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              // 全てリセット(設定タブの「全てリセットしてやり直す」と同じ。
              // もう一度確かめ、やめたら、このダイアログに戻る)
              TextButton(
                onPressed: () async {
                  if (!await resetSaiKakunin(dialogContext, zenbu: true)) {
                    return;
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  await _shinkiKaishi(10);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  '全て初期値に戻して始める',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.orange.shade300,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                '設定を残して始める',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                // ダイアログを閉じて、名声・育成力と設定を残すリセットで始める
                Navigator.of(dialogContext).pop();
                await _shinkiKaishi(101010);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF00FF00).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '箱庭小駅伝SS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '続きから再開 または 保存ゲームの読み込み を選択できます。\n'
                      '通常は『続きから再開』を選択してください。データが正しく読み込めない場合のみ、保存データ読み込みをお試しください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    // 前回、処理の途中で終了していた場合のお知らせ
                    if (ShoriGuard.restoredLabel != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        '前回は「${ShoriGuard.restoredLabel}」の処理中にアプリが終了したため、'
                        '処理前の状態に戻しました。『続きから再開』を選ぶと、その処理からやり直します。',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                    // 起動時の巻き戻しに失敗した場合のお知らせ
                    if (ShoriGuard.restoreErrorMessage != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        '前回、処理の途中でアプリが終了していたため処理前の状態に戻そうとしましたが、'
                        '失敗しました。お手数ですが、アプリを一度終了してから、もう一度起動してください'
                        '(起動時にもう一度戻します)。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),

                    // メイン：続きから再開
                    _buildMainButton(
                      context: context,
                      label: '続きから再開',
                      icon: Icons.play_arrow_rounded,
                      onTap: () async {
                        final Box<KantokuData> kantokuBox =
                            Hive.box<KantokuData>('kantokuBox');
                        final KantokuData? kantoku = kantokuBox.get(
                          'KantokuData',
                        );

                        if (kantoku != null) {
                          final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>(
                            'ghensuuBox',
                          );
                          final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;

                          if (kantoku.yobiint2[18] == 0) {
                            kantoku.yobiint2[18] = 10;
                          }
                          currentGhensuu.mode = kantoku.yobiint2[18];

                          await currentGhensuu.save();
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // サブ：保存データ読み込み
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SaveLoadScreen(hozonmosuruflag: false),
                          ),
                        );
                        // 読み込んだ保存データで目標順位の決め方を変えていて、読み込みの画面で
                        // お知らせを出せなかったときは、ここで出す(2.0.1。mokuhyou_kimekata.dart)
                        if (!mounted) return;
                        await mokuhyouKimekataOshiraseDialog(context);
                      },
                      icon: const Icon(
                        Icons.folder_open,
                        color: Color(0xFF00FF00),
                        size: 18,
                      ),
                      label: const Text(
                        "保存ゲーム読み込み画面へ",
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // サブ：新規ゲーム開始（確認ダイアログ付き）
                    TextButton.icon(
                      onPressed: () => _showNewGameConfirmDialog(context),
                      // アイコンを新規作成に適した「fiber_new」に変更
                      icon: const Icon(
                        Icons.fiber_new_rounded,
                        color: Color(0xFF00FF00),
                        size: 22,
                      ),
                      label: const Text(
                        "現在のゲームを破棄して新規ゲーム開始",
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF00).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00FF00), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF00).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00FF00)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
