import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/save_load_screen.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreen();
}

class _FirstScreen extends State<FirstScreen> {
  // 新規ゲーム開始の確認ダイアログを表示する関数
  Future<void> _showNewGameConfirmDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ダイアログ外をタップしても閉じない
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            '新規ゲーム開始の確認',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '現在の進行データを破棄して、新しくゲームを開始しますか？\nこの操作は取り消せません。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                '新規開始する',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                // ダイアログを閉じる
                Navigator.of(context).pop();

                // 新規開始処理を実行
                final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
                final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
                currentGhensuu.mode = 10;
                await currentGhensuu.save();

                // 必要に応じてここで画面遷移などの処理を追加
                /*ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('新規ゲームを開始しました')));*/
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
