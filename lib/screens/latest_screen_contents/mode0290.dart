import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_GakurenKukan.dart';

class Mode0290Content extends StatefulWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0290Content({super.key, required this.ghensuu, this.onAdvanceMode});

  @override
  State<Mode0290Content> createState() => _Mode0290ContentState();
}

class _Mode0290ContentState extends State<Mode0290Content> {
  // 進むボタンのアクション
  void _handleAdvanceButton() {
    // 後の処理をここに記述
    widget.onAdvanceMode?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Hiveから最新の状態を取得する場合のBuilder
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return SafeArea(
      child: ValueListenableBuilder<Box<Ghensuu>>(
        valueListenable: ghensuuBox.listenable(),
        builder: (context, box, _) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            body: Column(
              children: [
                // --- 上部固定エリア（ヘッダーと進むボタン） ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "学連選抜編成",
                          style: TextStyle(
                            fontSize: HENSUU.fontsize_honbun,
                            color: HENSUU.textcolor,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handleAdvanceButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HENSUU.buttonColor,
                          foregroundColor: HENSUU.buttonTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("進む＞＞"),
                      ),
                    ],
                  ),
                ),
                const Divider(color: HENSUU.textcolor, height: 1),

                // --- スクロール可能な本文エリア ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 長文になっても折り返されるように設定
                        const Text(
                          "学連選抜チームエントリー選手確定",
                          style: TextStyle(
                            fontSize: HENSUU.fontsize_honbun,
                            color: HENSUU.textcolor,
                          ),
                          softWrap: true,
                        ),

                        const SizedBox(height: 20),

                        // TODO: ここに後ほど「学連選抜チームの一覧表を表示させるボタン」を設置
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.8),
                              barrierDismissible: true,
                              barrierLabel: '学連選抜区間配置',
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                              pageBuilder: (context, _, __) =>
                                  const ModalGakurenKukanView(),
                            );
                          },
                          child: const Text(
                            "学連選抜区間配置",
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
