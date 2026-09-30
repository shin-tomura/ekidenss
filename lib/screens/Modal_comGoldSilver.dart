import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/kansuu/goldsilver_com.dart';

/// コンピュータ大学の金銀使用 ON/OFF 設定画面
/// KantokuData.yobiint2[33] (0=ON(初期値)、1=OFF)
class ModalComGoldSilver extends StatefulWidget {
  const ModalComGoldSilver({super.key});

  @override
  State<ModalComGoldSilver> createState() => _ModalComGoldSilverState();
}

class _ModalComGoldSilverState extends State<ModalComGoldSilver> {
  late Box<KantokuData> _kantokuBox;

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // ON/OFFを切り替え、Hiveに保存する関数
  Future<void> _updateFlag(KantokuData kantoku, bool on) async {
    // 変更をHiveに保存するために、List全体を更新（リストの参照変更）
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= comGoldSilverFlagIndex) {
      return;
    }
    updatedYobiint2[comGoldSilverFlagIndex] = on ? 0 : 1;
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: _kantokuBox.listenable(keys: ['KantokuData']),
      builder: (context, box, _) {
        if (!box.containsKey('KantokuData')) {
          return Scaffold(
            appBar: AppBar(title: const Text('コンピュータ金銀使用')),
            body: const Center(child: Text('設定データがありません')),
          );
        }

        final KantokuData currentKantoku = box.get('KantokuData')!;
        final bool isOn = isComGoldSilverOn(currentKantoku);

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              'コンピュータ金銀使用',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "【コンピュータ大学の金銀使用】\n\nONにすると、コンピュータの大学も金銀を獲得し、選手の能力強化に使うようになります。\n\n獲得量はプレイヤーと同じ式で、春の定期支給(4月中旬)と目標順位達成時に獲得します。「難易度変更」の設定や金銀支給量倍率も同じように適用されます。なお、難易度モードの「極」「天」の場合でも、コンピュータの大学への支給は制限されません。\n\n金銀は、留学生を除く各大学の選手10人(基本走力の上位7人と、それ以外の1・2年生のうち基本走力の上位3人)に順番に使われます。夏合宿より後に獲得した分は、4年生には使われません。金は駅伝男、次に平常心に使われ、銀は各選手の年間強化練習メニューに対応する能力に使われます。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  RadioListTile<bool>(
                    title: Text(
                      "ON(使用する)",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: true,
                    groupValue: isOn,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _updateFlag(currentKantoku, value);
                      }
                    },
                    activeColor: Colors.blue,
                    tileColor: isOn
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      "OFF(使用しない)",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: false,
                    groupValue: isOn,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _updateFlag(currentKantoku, value);
                      }
                    },
                    activeColor: Colors.blue,
                    tileColor: !isOn
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(200, 48),
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: Text(
                      "戻る",
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
