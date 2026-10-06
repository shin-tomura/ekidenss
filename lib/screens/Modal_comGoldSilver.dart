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
/// KantokuData.yobiint2[40]・[41] 大学ごとの銀の使い道(1大学1桁)
/// KantokuData.yobiint2[42]〜[57] 大学ごとの金銀の保有量(表示のみ)
class ModalComGoldSilver extends StatefulWidget {
  const ModalComGoldSilver({super.key});

  @override
  State<ModalComGoldSilver> createState() => _ModalComGoldSilverState();
}

class _ModalComGoldSilverState extends State<ModalComGoldSilver> {
  late Box<KantokuData> _kantokuBox;
  int _ikkatsuLevel = 0; // 一括設定で選んでいるレベル
  int _ikkatsuHoushin = 0; // 一括設定で選んでいる銀の使い道

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

  // 画面からはみ出さないプルダウン(番号0〜の項目を表示名の順に並べる)
  // ・入る幅があれば、いちばん長い項目に合わせた幅にする(今までと同じ見た目)
  // ・スマホの文字を大きくしていて入らない場合は、入る幅まで縮め、
  //   選んでいる項目の文字は「…」で省略する(開いた一覧の項目は折り返して全部表示)
  Widget _hamidasanaiDropdown({
    required int value,
    required List<String> hyoujiMei,
    required ValueChanged<int> onChanged,
  }) {
    return IntrinsicWidth(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
        items: [
          for (int i = 0; i < hyoujiMei.length; i++)
            DropdownMenuItem<int>(value: i, child: Text(hyoujiMei[i])),
        ],
        // 選んでいる項目の表示(縦は中央、入らなければ「…」で省略)
        selectedItemBuilder: (context) => [
          for (final String mei in hyoujiMei)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                mei,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (int? v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  // 支給レベルのプルダウン
  Widget _levelDropdown({
    required int value,
    required int playerKazeflag,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      hyoujiMei: List.generate(
        comGoldSilverLevelMei.length,
        (level) => comGoldSilverLevelHyouji(level, playerKazeflag),
      ),
      onChanged: onChanged,
    );
  }

  // 大学ごとの銀の使い道を変更し、Hiveに保存する関数(univids の大学をまとめて変更)
  Future<void> _updateHoushin(
    KantokuData kantoku,
    List<int> univids,
    int houshin,
  ) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= comGinHoushinIndex1) {
      return;
    }
    for (final int id in univids) {
      comGinHoushinSettei(updatedYobiint2, id, houshin);
    }
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 銀の使い道のプルダウン
  Widget _houshinDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      hyoujiMei: List.generate(comGinHoushinMax + 1, comGinHoushinMei),
      onChanged: onChanged,
    );
  }

  // プルダウンの前に付ける小さな見出し
  Widget _komidashi(String text) {
    return Text(
      text,
      style: TextStyle(
        color: HENSUU.textcolor.withOpacity(0.7),
        fontSize: HENSUU.fontsize_honbun - 2,
      ),
    );
  }

  // 一括設定の行(「全大学の○○を [▼] にする」)
  Widget _ikkatsuGyou({
    required String koumoku,
    required Widget dropdown,
    required VoidCallback onPressed,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(
          "全大学の$koumokuを",
          style: TextStyle(
            color: HENSUU.textcolor,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        dropdown,
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("にする"),
        ),
      ],
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
                      "【コンピュータ大学の金銀使用】\n\nONにすると、コンピュータの大学も金銀を獲得し、選手の能力強化に使うようになります。\n\n獲得量はプレイヤーと同じ式で、春の定期支給(4月上旬、プレイヤーと同じ時期)と目標順位達成時に獲得します。支給レベルは下の一覧で大学ごとに設定できます(初期値は鬼)。「極○」は春の定期支給のみ、「天」は支給なしです。「プレイヤーと同じ」はプレイヤーの「難易度変更」の設定(鬼・難しいなど)と同じ支給量で、難易度モードの「極」「天」は適用されません。金銀支給量倍率は全大学に適用されます。説明画面の設定タブの「金銀支給量倍率設定」の難易度ごとの割合は、支給レベルの難易度の割合が適用されます(「プレイヤーと同じ」はプレイヤーの今の難易度の割合)。\n\n獲得した金銀は、プレイヤーと同じく夏合宿まで保有し、夏合宿(夏の成長の直後)にまとめて使います。秋以降に獲得した分は翌年の夏合宿で使います。各大学の保有量は下の一覧に表示されます。夏合宿の時点でOFFの場合、保有していた金銀は使わずに消えます。\n\n金銀は、留学生を除く各大学の選手10人(基本走力の上位7人と、それ以外の1・2年生のうち基本走力の上位3人)に順番に使われます。金は駅伝男、次に平常心に使われます。銀は大学ごとの「銀の使い道」に従って使われます。「個人の練習メニュー通り」(初期値)では各選手の年間強化練習メニューに対応する能力に使われ(「バランス」の選手は、1回ごとに能力が上限でないメニューをランダムに選びます)、スピード・距離走・登り・下り・アップダウンのどれかを選ぶと、10人全員がその練習メニューに対応する能力に使います。対象の能力が全員上限の場合は、使えない金は銀に交換(金1→銀2)され、銀はほかの能力(カリスマ・安定感を除く)に使われます。10未満の端数は、翌年の夏合宿に持ち越します。",
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

                  // 大学ごとの支給レベルと銀の使い道
                  Text(
                    "大学ごとの支給レベルと銀の使い道",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 一括設定
                  _ikkatsuGyou(
                    koumoku: "支給レベル",
                    dropdown: _levelDropdown(
                      value: _ikkatsuLevel,
                      playerKazeflag: playerKazeflag,
                      onChanged: (v) => setState(() => _ikkatsuLevel = v),
                    ),
                    onPressed: () {
                      _updateLevel(
                        currentKantoku,
                        comUnivs.map((u) => u.id).toList(),
                        _ikkatsuLevel,
                      );
                    },
                  ),
                  _ikkatsuGyou(
                    koumoku: "銀の使い道",
                    dropdown: _houshinDropdown(
                      value: _ikkatsuHoushin,
                      onChanged: (v) => setState(() => _ikkatsuHoushin = v),
                    ),
                    onPressed: () {
                      _updateHoushin(
                        currentKantoku,
                        comUnivs.map((u) => u.id).toList(),
                        _ikkatsuHoushin,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // 大学ごとの設定(1行目に大学名、2行目に保有量、3行目に支給レベルと銀の使い道)
                  for (final UnivData univ in comUnivs)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            univ.name,
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // 夏合宿で使うまで保有している金銀
                          _komidashi(
                            "保有 金${comKinHoyuu(currentKantoku, univ.id)} "
                            "銀${comGinHoyuu(currentKantoku, univ.id)}",
                          ),
                          // 見出しとプルダウンは組にして、画面が狭いときは組ごと折り返す
                          // (1組でも入らないときは、プルダウンを縮めて文字を「…」で省略する)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _komidashi("支給レベル"),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _levelDropdown(
                                      value: comGoldSilverLevel(
                                        currentKantoku,
                                        univ.id,
                                      ),
                                      playerKazeflag: playerKazeflag,
                                      onChanged: (v) => _updateLevel(
                                        currentKantoku,
                                        [univ.id],
                                        v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _komidashi("銀の使い道"),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _houshinDropdown(
                                      value: comGinHoushin(
                                        currentKantoku,
                                        univ.id,
                                      ),
                                      onChanged: (v) => _updateHoushin(
                                        currentKantoku,
                                        [univ.id],
                                        v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
