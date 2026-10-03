import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/screens/Modal_GakurenKukan.dart';
import 'package:ekiden/screens/Modal_GakurenKukanHenshuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/screens/gakuren_copy_button.dart';
import 'package:ekiden/screens/ai_copy_matome.dart';

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

  // 学連選抜の監督をするかの設定(yobiint2[75]、0=する・1=しない)を保存する
  // (変更をHiveに保存するために、List全体を更新)
  Future<void> _gakurenKantokuHozon(KantokuData kantoku, bool suru) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= gakurenKantokuIndex) return;
    updatedYobiint2[gakurenKantokuIndex] = suru ? 0 : 1;
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 自分の大学が正月駅伝に出場できない年に出す、学連選抜の監督の部分(1.8.2)
  List<Widget> _gakurenKantokuBubun() {
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    UnivData? myUniv;
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == widget.ghensuu.MYunivid) myUniv = u;
    }
    if (kantoku == null ||
        myUniv == null ||
        myUniv.taikaientryflag.length <= 2 ||
        myUniv.taikaientryflag[2] != 0) {
      return const [];
    }
    final bool suru = gakurenKantokuSettei(kantoku);
    // 学連選抜の目標順位(0が1位。初期値は10位。6区のスタート前にも決め直せる。1.8.2)
    final int mokuhyou = gakurenMokuhyouSettei(kantoku);
    // 正月駅伝に出場している大学の数(目標順位に選べる順位の数)
    final int shutsujouSuu = Hive.box<UnivData>('univBox').values
        .where((u) => u.taikaientryflag.length > 2 && u.taikaientryflag[2] == 1)
        .length;
    return [
      Text(
        "${myUniv.name}大学は正月駅伝に出場できませんが、学連選抜の監督として区間配置を決めることができます。",
        style: const TextStyle(
          fontSize: HENSUU.fontsize_honbun,
          color: HENSUU.textcolor,
        ),
        softWrap: true,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          "学連選抜の監督をする",
          style: TextStyle(color: HENSUU.textcolor),
        ),
        subtitle: Text(
          suru
              ? "監督をする(初期値)。区間配置を決められます"
              : "監督をしない。区間配置はコンピュータが決めたままになります",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        value: suru,
        onChanged: (bool v) => _gakurenKantokuHozon(kantoku, v),
        activeColor: Colors.blue,
      ),
      if (suru && shutsujouSuu > 0) ...[
        Row(
          children: [
            const Text(
              "学連選抜の目標順位:",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: mokuhyou.clamp(0, shutsujouSuu - 1).toInt(),
              dropdownColor: const Color.fromARGB(255, 30, 30, 30),
              iconEnabledColor: HENSUU.textcolor,
              onChanged: (int? v) async {
                if (v == null) return;
                await gakurenMokuhyouHozon(kantoku, v);
                if (mounted) setState(() {});
              },
              items: [
                for (int i = 0; i < shutsujouSuu; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      "${i + 1}位",
                      style: const TextStyle(color: HENSUU.LinkColor),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Text(
          "大学の目標順位と同じく、目標を下回った位置で襷を受けると前半無理して突っ込んでのタイム悪化が、上回った位置で受けるとほっと一息ついてのタイム悪化があります(1区と6区は判定しません)。学連選抜には金銀や名声はないので、実力に見合った目標を選ぶのがおすすめです。正月駅伝の6区のスタート前に、復路の目標順位を決め直せます。",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
      ],
      if (suru)
        ElevatedButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8),
              barrierDismissible: true,
              barrierLabel: '学連選抜の区間配置',
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, _, __) =>
                  const ModalGakurenKukanHenshuu(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text("学連選抜の区間配置を決める"),
        ),
      const SizedBox(height: 20),
    ];
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

                        // 自分の大学が正月駅伝に出場できない年は、学連選抜の監督ができる(1.8.2)
                        ..._gakurenKantokuBubun(),

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
                        // 学連選抜のメンバーの今季タイム一覧表(1.8.2)
                        const GakurenKonkiTimeLink(),
                        // 生成AIに渡すテキストのまとめボタン(1.8.2。区間エントリーの前の場面なので、
                        // ほかの大学の区間エントリーが分かってしまうものは出さない)
                        const AiCopyMatomeButton(entryAri: false),
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
