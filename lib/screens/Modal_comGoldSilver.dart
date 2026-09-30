import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/kansuu/goldsilver_com.dart';

/// コンピュータ大学の金銀使用 設定画面
/// KantokuData.yobiint2[33] (0=ON(初期値)、1=OFF)
/// KantokuData.yobiint2[38]・[39] 大学ごとの金銀支給レベル(1大学1桁)
class ModalComGoldSilver extends StatefulWidget {
  const ModalComGoldSilver({super.key});

  @override
  State<ModalComGoldSilver> createState() => _ModalComGoldSilverState();
}

class _ModalComGoldSilverState extends State<ModalComGoldSilver> {
  late Box<KantokuData> _kantokuBox;
  int _ikkatsuLevel = 0; // 一括設定で選んでいるレベル

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // 大学ごとの支給レベルを変更し、Hiveに保存する関数(univids の大学をまとめて変更)
  Future<void> _updateLevel(
    KantokuData kantoku,
    List<int> univids,
    int level,
  ) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= comGoldSilverLevelIndex1) {
      return;
    }
    for (final int id in univids) {
      comGoldSilverLevelSettei(updatedYobiint2, id, level);
    }
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 支給レベルのプルダウン
  Widget _levelDropdown({
    required int value,
    required int playerKazeflag,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      dropdownColor: Colors.grey[900],
      style: TextStyle(
        color: HENSUU.textcolor,
        fontSize: HENSUU.fontsize_honbun,
      ),
      items: List.generate(comGoldSilverLevelMei.length, (level) {
        return DropdownMenuItem<int>(
          value: level,
          child: Text(comGoldSilverLevelHyouji(level, playerKazeflag)),
        );
      }),
      onChanged: (int? v) {
        if (v != null) onChanged(v);
      },
    );
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
        final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
        final int myUnivid = gh?.MYunivid ?? -1;
        final int playerKazeflag = gh?.kazeflag ?? 0;
        final List<UnivData> comUnivs =
            Hive.box<UnivData>('univBox').values
                .where((u) => u.id != myUnivid)
                .toList()
              ..sort((a, b) => a.id.compareTo(b.id));

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
                      "【コンピュータ大学の金銀使用】\n\nONにすると、コンピュータの大学も金銀を獲得し、選手の能力強化に使うようになります。\n\n獲得量はプレイヤーと同じ式で、春の定期支給(4月中旬)と目標順位達成時に獲得します。支給レベルは下の一覧で大学ごとに設定できます。「標準」はプレイヤーの「難易度変更」の設定(鬼・難しいなど)と同じ支給量で、難易度モードの「極」「天」は適用されません。「極○」は春の定期支給のみ、「天」は支給なしです。金銀支給量倍率は全大学に適用されます。\n\n金銀は、留学生を除く各大学の選手10人(基本走力の上位7人と、それ以外の1・2年生のうち基本走力の上位3人)に順番に使われます。夏合宿より後に獲得した分は、4年生には使われません。金は駅伝男、次に平常心に使われ、銀は各選手の年間強化練習メニューに対応する能力に使われます。対象の能力が全員上限の場合は、使えない金は銀に交換(金1→銀2)され、銀はほかの能力(カリスマ・安定感を除く)に使われます。",
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
                  const SizedBox(height: 16),

                  // 大学ごとの支給レベル
                  Text(
                    "大学ごとの支給レベル",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 一括設定
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        "全大学を",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: HENSUU.fontsize_honbun,
                        ),
                      ),
                      _levelDropdown(
                        value: _ikkatsuLevel,
                        playerKazeflag: playerKazeflag,
                        onChanged: (v) => setState(() => _ikkatsuLevel = v),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _updateLevel(
                            currentKantoku,
                            comUnivs.map((u) => u.id).toList(),
                            _ikkatsuLevel,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("にする"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 大学ごとの設定
                  for (final UnivData univ in comUnivs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              univ.name,
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _levelDropdown(
                            value: comGoldSilverLevel(currentKantoku, univ.id),
                            playerKazeflag: playerKazeflag,
                            onChanged: (v) =>
                                _updateLevel(currentKantoku, [univ.id], v),
                          ),
                        ],
                      ),
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
