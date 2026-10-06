import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/kansuu/scout_com.dart';

/// コンピュータスカウト 設定画面
/// KantokuData.yobiint2[58] ON/OFF・積極性・ラウンド回数
///   (ラウンド回数のコード×10000 + OFFなら1000 + (100−積極性))
/// KantokuData.yobiint2[59]・[60] 大学ごとのスカウト方針(1大学1桁)
/// KantokuData.yobiint2[61]・[62] 大学ごとの性格(1大学1桁)
/// KantokuData.yobiint2[63] 評価の割合(タイム:能力)。全大学共通(1.8.0)
/// KantokuData.yobiint3[40+大学id] 大学ごとの評価の割合と積極性(1.9.1。0なら全大学共通の設定)
class ModalComScout extends StatefulWidget {
  const ModalComScout({super.key});

  @override
  State<ModalComScout> createState() => _ModalComScoutState();
}

class _ModalComScoutState extends State<ModalComScout> {
  late Box<KantokuData> _kantokuBox;
  int _ikkatsuHoushin = 0; // 一括設定で選んでいるスカウト方針
  int _ikkatsuSeikaku = 0; // 一括設定で選んでいる性格
  // 一括設定で選んでいる評価の割合と積極性(-1は「共通」。1.9.1)
  int _ikkatsuWariai = -1;
  int _ikkatsuSekkyokusei = -1;

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // yobiint2を書き換えてHiveに保存する(変更をHiveに保存するために、List全体を更新)
  Future<void> _hozon(
    KantokuData kantoku,
    void Function(List<int> yobiint2) kakikae,
  ) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= comScoutTimeWariaiIndex) {
      return;
    }
    kakikae(updatedYobiint2);
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // yobiint3(大学ごとの評価の割合と積極性。1.9.1)を書き換えてHiveに保存する
  Future<void> _hozon3(
    KantokuData kantoku,
    void Function(List<int> yobiint3) kakikae,
  ) async {
    final List<int> updatedYobiint3 = List.from(kantoku.yobiint3);
    if (updatedYobiint3.length <= comScoutUnivSetteiIndex + TEISUU.UNIVSUU - 1) {
      return;
    }
    kakikae(updatedYobiint3);
    setState(() {
      kantoku.yobiint3 = updatedYobiint3;
    });
    await kantoku.save();
  }

  // 大学ごとの評価の割合のプルダウン(-1は「共通」。共通の値も表示する。1.9.1)
  Widget _wariaiDropdown({
    required int value,
    required int kyoutsuu,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      atai: [-1, for (int w = 100; w >= 0; w -= 10) w],
      hyoujiMei: [
        '共通(${kyoutsuu}:${100 - kyoutsuu})',
        for (int w = 100; w >= 0; w -= 10) '$w:${100 - w}',
      ],
      onChanged: onChanged,
    );
  }

  // 大学ごとの積極性のプルダウン(-1は「共通」。共通の値も表示する。1.9.1)
  Widget _sekkyokuseiUnivDropdown({
    required int value,
    required int kyoutsuu,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      atai: [-1, for (int p = 0; p <= 100; p += 10) p],
      hyoujiMei: [
        '共通($kyoutsuu%)',
        for (int p = 0; p <= 100; p += 10) '$p%',
      ],
      onChanged: onChanged,
    );
  }

  // ON/OFF・積極性・ラウンド回数のどれかを変えて保存する
  Future<void> _updateSettei(
    KantokuData kantoku, {
    bool? on,
    int? sekkyokusei,
    int? kaisuu,
  }) async {
    await _hozon(kantoku, (y) {
      comScoutSetteiKaku(
        y,
        on: on ?? isComScoutOn(kantoku),
        sekkyokusei: sekkyokusei ?? comScoutSekkyokusei(kantoku),
        kaisuu: kaisuu ?? comScoutKaisuu(kantoku),
      );
    });
  }

  // 画面からはみ出さないプルダウン(番号0〜の項目を表示名の順に並べる)
  // ・入る幅があれば、いちばん長い項目に合わせた幅にする
  // ・スマホの文字を大きくしていて入らない場合は、入る幅まで縮め、
  //   選んでいる項目の文字は「…」で省略する(開いた一覧の項目は折り返して全部表示)
  Widget _hamidasanaiDropdown({
    required int value,
    required List<int> atai,
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
          for (int i = 0; i < atai.length; i++)
            DropdownMenuItem<int>(value: atai[i], child: Text(hyoujiMei[i])),
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

  // スカウト方針のプルダウン
  Widget _houshinDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      atai: List.generate(comScoutHoushinMei.length, (i) => i),
      hyoujiMei: comScoutHoushinMei,
      onChanged: onChanged,
    );
  }

  // 性格のプルダウン
  Widget _seikakuDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _hamidasanaiDropdown(
      value: value,
      atai: List.generate(comScoutSeikakuMei.length, (i) => i),
      hyoujiMei: comScoutSeikakuMei,
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

  // 見出しとプルダウンの組(画面が狭いときは、プルダウンを縮めて文字を「…」で省略する)
  Widget _kumi(String midashi, Widget dropdown) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _komidashi(midashi),
        const SizedBox(width: 6),
        Flexible(child: dropdown),
      ],
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: _kantokuBox.listenable(keys: ['KantokuData']),
      builder: (context, box, _) {
        if (!box.containsKey('KantokuData')) {
          return Scaffold(
            appBar: AppBar(title: const Text('コンピュータスカウト')),
            body: const Center(child: Text('設定データがありません')),
          );
        }

        final KantokuData currentKantoku = box.get('KantokuData')!;
        final bool isOn = isComScoutOn(currentKantoku);
        final int sekkyokusei = comScoutSekkyokusei(currentKantoku);
        final int kaisuu = comScoutKaisuu(currentKantoku);
        final int timeWariai = comScoutTimeWariai(currentKantoku);
        final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
        final int myUnivid = gh?.MYunivid ?? -1;
        final List<UnivData> comUnivs =
            Hive.box<UnivData>('univBox').values
                .where((u) => u.id != myUnivid)
                .toList()
              ..sort((a, b) => a.id.compareTo(b.id));

        // 積極性の選択肢(10%刻み。QRコードなどで刻み以外の値になっていれば、その値も加える)
        final List<int> sekkyokuseiAtai = [
          for (int p = 0; p <= 100; p += 10) p,
        ];
        if (!sekkyokuseiAtai.contains(sekkyokusei)) {
          sekkyokuseiAtai
            ..add(sekkyokusei)
            ..sort();
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              'コンピュータスカウト',
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
                      "【コンピュータスカウト】\n\nONにすると、新入生スカウトがコンピュータの大学との取り合いになります。OFFにすると今まで通り(プレイヤーだけが毎年3回交渉できます)です。\n\nONは、コンピュータの大学との真剣勝負です。コンピュータの大学もプレイヤーと同じ条件で新入生を取り合うので、名声の低い大学から這い上がるのは、今まで(OFF)よりずっと難しくなります。金銀の使い方や、駅伝での指示・区間配置など、まさに総監督としての手腕が問われます。名声の低い大学から気軽に這い上がりたい場合は、OFFがおすすめです。\n\nONのときは、新入生は全員「進路未定」です(あなたの大学も含め、どの大学にも分かりません)。プレイヤーが1回交渉するたびに、コンピュータの各大学も同じラウンドで1人ずつ交渉し、結果がまとめて出ます。交渉に成功した大学に確定し、確定した選手はその年はもう交渉に応じません。同じ選手に複数の大学が成功した場合は争奪戦になり、選手が進学先を選びます(名声の高い大学ほど選ばれやすくなります)。まれに、大学の名声をあまり気にしない新入生もいます。交渉に失敗した選手とは、その年はもう交渉できません(コンピュータの大学も同じです)。成功率は、持ちタイムの順位による上限(1位10%〜87位以下75%)に、自校の名声と全大学の平均の名声の比を掛け合わせて決まり、名声の高くない大学ほど持ちタイムの良い選手の成功率が下がります(名声の比が75%以上なら上限のままです)。各大学が確定できるのは、日本人の新入生の枠(5人。留学生が入学する大学は4人)までです。\n\nスカウトを終えたあとの残りのラウンドは、コンピュータの大学だけで行います。そのあと、確定しなかった選手は自ら志望して進学先を選びます(名声の高い大学ほど選ばれやすく、どの大学も枠がちょうど埋まります)。スキップ中も、コンピュータの大学だけで全ラウンドを行います。留学生は交渉の対象外です。全大学の新入生の進学先(交渉・志望・留学生)は、スカウト終了時の「全大学の新入生を見る」、最新画面の「新入生が入りました！」の表示、大学画面の「新入生の進学先(全大学)」で見られます(翌年のスカウトまで)。\n\nコンピュータの大学は、新入生の5000m持ちタイムと能力の値で選手を評価します(大学の個性の設定は関係ありません)。「評価の割合(タイム:能力)」は、その評価で持ちタイムと能力をどの割合で重視するかです(初期値は50:50です。スカウト方針が「タイム重視」の大学は、この設定に関係なく持ちタイムだけで評価します)。\n\n「スカウト方針」は重視する能力です。「自動」(初期値)では長距離粘り・ロード適性を重く、ペース変動対応力を少し見て、来年も残る2・3年生と確定した新入生に登り・下り・アップダウンの得意な選手(70以上)が2人いなければ、その能力も重視します。\n\n「性格」は欲しい選手の基準です。まだ進路未定の新入生の中で、自校のスカウト方針での評価が「大物狙い」は上位5%、「バランス」は上位25%、「堅実」は上位50%以内の選手を欲しがり、その中で成功率の高い選手から交渉します(成功率が同じなら、基準ぎりぎりの、ほかの大学と取り合いになりにくい選手から)。「自動」(初期値)では、名声の順位が1〜5位の大学は大物狙い、6〜15位はバランス、16位以下は堅実になります。\n\n「積極性」は、各大学が1ラウンドで交渉する確率です。積極性を0%にした大学は交渉せず、新入生は最後の志望で入ってきます。「ラウンド回数」は毎年の交渉の回数(1〜10回)で、ONのときだけ使われ、次の新入生スカウトから反映されます。\n\n評価の割合と積極性は、下の大学ごとの設定で、大学ごとに変えることもできます。「共通」(初期値)の大学は、上の全大学共通の設定に従います。",
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
                      "ON(コンピュータもスカウトする)",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: true,
                    groupValue: isOn,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _updateSettei(currentKantoku, on: value);
                      }
                    },
                    activeColor: Colors.blue,
                    tileColor: isOn
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      "OFF(今まで通り)",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: false,
                    groupValue: isOn,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _updateSettei(currentKantoku, on: value);
                      }
                    },
                    activeColor: Colors.blue,
                    tileColor: !isOn
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  const SizedBox(height: 16),

                  // 積極性とラウンド回数と評価の割合(画面が狭いときは組ごと折り返す)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      _kumi(
                        "積極性",
                        _hamidasanaiDropdown(
                          value: sekkyokusei,
                          atai: sekkyokuseiAtai,
                          hyoujiMei: [for (final int p in sekkyokuseiAtai) '$p%'],
                          onChanged: (v) =>
                              _updateSettei(currentKantoku, sekkyokusei: v),
                        ),
                      ),
                      _kumi(
                        "ラウンド回数",
                        _hamidasanaiDropdown(
                          value: kaisuu,
                          atai: [
                            for (int k = 1; k <= comScoutKaisuuMax; k++) k,
                          ],
                          hyoujiMei: [
                            for (int k = 1; k <= comScoutKaisuuMax; k++) '$k回',
                          ],
                          onChanged: (v) =>
                              _updateSettei(currentKantoku, kaisuu: v),
                        ),
                      ),
                      // 評価の割合(タイム:能力)。全大学共通(1.8.0)
                      _kumi(
                        "評価の割合(タイム:能力)",
                        _hamidasanaiDropdown(
                          value: timeWariai,
                          atai: [for (int w = 100; w >= 0; w -= 10) w],
                          hyoujiMei: [
                            for (int w = 100; w >= 0; w -= 10)
                              w == comScoutTimeWariaiShokichi
                                  ? '$w:${100 - w}(初期値)'
                                  : '$w:${100 - w}',
                          ],
                          onChanged: (v) => _hozon(
                            currentKantoku,
                            (y) => comScoutTimeWariaiSettei(y, v),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // 大学ごとのスカウト方針・性格・評価の割合・積極性(割合と積極性は1.9.1)
                  Text(
                    "大学ごとの設定(スカウト方針・性格・評価の割合・積極性)",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 一括設定
                  _ikkatsuGyou(
                    koumoku: "スカウト方針",
                    dropdown: _houshinDropdown(
                      value: _ikkatsuHoushin,
                      onChanged: (v) => setState(() => _ikkatsuHoushin = v),
                    ),
                    onPressed: () {
                      _hozon(currentKantoku, (y) {
                        for (final UnivData u in comUnivs) {
                          comScoutHoushinSettei(y, u.id, _ikkatsuHoushin);
                        }
                      });
                    },
                  ),
                  _ikkatsuGyou(
                    koumoku: "性格",
                    dropdown: _seikakuDropdown(
                      value: _ikkatsuSeikaku,
                      onChanged: (v) => setState(() => _ikkatsuSeikaku = v),
                    ),
                    onPressed: () {
                      _hozon(currentKantoku, (y) {
                        for (final UnivData u in comUnivs) {
                          comScoutSeikakuSettei(y, u.id, _ikkatsuSeikaku);
                        }
                      });
                    },
                  ),
                  _ikkatsuGyou(
                    koumoku: "評価の割合",
                    dropdown: _wariaiDropdown(
                      value: _ikkatsuWariai,
                      kyoutsuu: timeWariai,
                      onChanged: (v) => setState(() => _ikkatsuWariai = v),
                    ),
                    onPressed: () {
                      _hozon3(currentKantoku, (y) {
                        for (final UnivData u in comUnivs) {
                          comScoutTimeWariaiUnivKaku(
                            y,
                            u.id,
                            _ikkatsuWariai < 0 ? null : _ikkatsuWariai,
                          );
                        }
                      });
                    },
                  ),
                  _ikkatsuGyou(
                    koumoku: "積極性",
                    dropdown: _sekkyokuseiUnivDropdown(
                      value: _ikkatsuSekkyokusei,
                      kyoutsuu: sekkyokusei,
                      onChanged: (v) =>
                          setState(() => _ikkatsuSekkyokusei = v),
                    ),
                    onPressed: () {
                      _hozon3(currentKantoku, (y) {
                        for (final UnivData u in comUnivs) {
                          comScoutSekkyokuseiUnivKaku(
                            y,
                            u.id,
                            _ikkatsuSekkyokusei < 0
                                ? null
                                : _ikkatsuSekkyokusei,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // 大学ごとの設定(1段目に大学名、そのあと設定を1つにつき1段。
                  // スマホの文字を大きくしていても読めるように。1.9.1)
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
                          _kumi(
                            "方針",
                            _houshinDropdown(
                              value: comScoutHoushin(currentKantoku, univ.id),
                              onChanged: (v) => _hozon(
                                currentKantoku,
                                (y) => comScoutHoushinSettei(y, univ.id, v),
                              ),
                            ),
                          ),
                          _kumi(
                            "性格",
                            _seikakuDropdown(
                              value: comScoutSeikaku(currentKantoku, univ.id),
                              onChanged: (v) => _hozon(
                                currentKantoku,
                                (y) => comScoutSeikakuSettei(y, univ.id, v),
                              ),
                            ),
                          ),
                          // 評価の割合(タイム重視の大学は持ちタイムだけで評価するので選べない)
                          comScoutHoushin(currentKantoku, univ.id) ==
                                  comScoutHoushinMei.indexOf('タイム重視')
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: _komidashi(
                                    "評価の割合 タイム重視のため、持ちタイムだけで評価",
                                  ),
                                )
                              : _kumi(
                                  "評価の割合",
                                  _wariaiDropdown(
                                    value:
                                        comScoutTimeWariaiUnivSettei(
                                          currentKantoku,
                                          univ.id,
                                        ) ??
                                        -1,
                                    kyoutsuu: timeWariai,
                                    onChanged: (v) => _hozon3(
                                      currentKantoku,
                                      (y) => comScoutTimeWariaiUnivKaku(
                                        y,
                                        univ.id,
                                        v < 0 ? null : v,
                                      ),
                                    ),
                                  ),
                                ),
                          _kumi(
                            "積極性",
                            _sekkyokuseiUnivDropdown(
                              value:
                                  comScoutSekkyokuseiUnivSettei(
                                    currentKantoku,
                                    univ.id,
                                  ) ??
                                  -1,
                              kyoutsuu: sekkyokusei,
                              onChanged: (v) => _hozon3(
                                currentKantoku,
                                (y) => comScoutSekkyokuseiUnivKaku(
                                  y,
                                  univ.id,
                                  v < 0 ? null : v,
                                ),
                              ),
                            ),
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
