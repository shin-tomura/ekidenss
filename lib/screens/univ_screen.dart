// lib/screens/univ_screen.dart
import 'dart:math';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/screens/senshu_r_screen.dart';
import 'package:ekiden/screens/riji_screen.dart';
import 'package:ekiden/album.dart';
//import 'package:ekiden/save_load_screen.dart';
import 'package:ekiden/screens/Modal_kaisuu_juni.dart';
import 'package:ekiden/screens/Modal_rankingunivsenshu.dart';
import 'package:ekiden/screens/Modal_rankingunivsenshunouryoku.dart';
import 'package:ekiden/screens/Modal_rankingall.dart';
import 'package:ekiden/screens/Modal_univkosei.dart';
import 'package:ekiden/screens/Modal_univkoseiall.dart';
import 'package:ekiden/screens/Modal_TrainingList.dart';
import 'package:ekiden/screens/Modal_reset_IkuseiryokuMeiseiIji.dart';
import 'package:ekiden/screens/Modal_meiseiitiran.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';
import 'package:ekiden/screens/ModalAverageTop10TimeRankingView.dart';
import 'package:ekiden/screens/ModalChartSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';
import 'package:ekiden/screens/tradeScreen.dart';
//import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
// Modal views (placeholders for now, you'll need to create these files)
//import 'package:ekiden/modals/modal_univ_name_henshuu_view.dart';
//import 'package:ekiden/modals/modal_sentaku_univ_view.dart';
//import 'package:ekiden/modals/modal_kantoku_nouryoku_reset_view.dart';
//import 'package:ekiden/modals/modal_all_reset_view.dart';
//import 'package:ekiden/modals/modal_nanido_view.dart';

String _getCombinedDifficultyText(KantokuData kantoku, Ghensuu currentGhensuu) {
  // 難易度モードを取得 (0:通常, 1:極, 2:天)
  final int mode = kantoku.yobiint2[0];
  // 基本難易度を取得 (0:鬼, 1:難, 2:普, 3:易)
  final int baseDifficulty = currentGhensuu.kazeflag;

  // 難易度モードが「天」（mode=2）の場合
  if (mode == 2) {
    return "天";
  }

  // 基本難易度の接尾辞を決定
  String suffix;
  switch (baseDifficulty) {
    case 0:
      suffix = "鬼";
      break;
    case 1:
      suffix = "難";
      break;
    case 2:
      suffix = "普";
      break;
    case 3:
      suffix = "易";
      break;
    default:
      return ""; // 予期せぬ基本難易度
  }

  // 難易度モードが「極」（mode=1）の場合
  if (mode == 1) {
    return "極$suffix";
  }

  // 難易度モードが「通常」（mode=0）の場合
  if (mode == 0) {
    return suffix; // 例: 鬼, 難, 普, 易
  }

  // その他の予期せぬモード値の場合
  return "";
}

// SwiftのKANSUUにあるDayToString関数を模倣（ここでは簡易版）
String _dayToString(int day) {
  switch (day) {
    case 5:
      return '上旬';
    case 15:
      return '中旬';
    case 25:
      return '下旬';
    default:
      return '';
  }
}

// 難易度モードを表すEnumを定義
enum KiwameMode {
  normal(0, '通常モード', '金銀支給は通常通り行われます。'),
  kiwame(1, '極モード', '目標順位達成時の金銀支給が廃止されます。春の定期支給のみとなります。'),
  ten(2, '天モード', '目標順位達成時の金銀支給に加え、春の定期支給も廃止されます（金銀支給なし）。');

  const KiwameMode(this.value, this.title, this.description);
  final int value;
  final String title;
  final String description;

  // int値からEnumを取得するヘルパー関数
  static KiwameMode fromValue(int value) {
    return KiwameMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => KiwameMode.normal, // 該当しない場合は通常モードを返す
    );
  }
}

class ModalKiwameHosei extends StatefulWidget {
  const ModalKiwameHosei({super.key});

  @override
  State<ModalKiwameHosei> createState() => _ModalKiwameHoseiState();
}

class _ModalKiwameHoseiState extends State<ModalKiwameHosei> {
  late Box<KantokuData> _kantokuBox;
  late KantokuData _kantoku;

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _kantoku = _kantokuBox.get('KantokuData')!;
  }

  // 難易度モードを切り替え、Hiveに保存する関数
  void _updateKiwameMode(KiwameMode newMode) async {
    // 変更をHiveに保存するために、List全体を更新（リストの参照変更）
    final List<int> updatedYobiint2 = List.from(_kantoku.yobiint2);

    // yobiint2[0]を更新
    updatedYobiint2[0] = newMode.value;

    setState(() {
      _kantoku.yobiint2 = updatedYobiint2;
    });

    // Hiveに保存
    await _kantoku.save();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: _kantokuBox.listenable(keys: ['KantokuData']),
      builder: (context, box, _) {
        if (!box.containsKey('KantokuData')) {
          return Scaffold(
            appBar: AppBar(title: const Text('難易度 極 設定')),
            body: const Center(child: Text('設定データがありません')),
          );
        }

        final KantokuData currentKantoku = box.get('KantokuData')!;
        // 現在のyobiint2[0]の値から現在のモードを取得
        final int currentYobiint2Value = currentKantoku.yobiint2[0];
        final KiwameMode currentMode = KiwameMode.fromValue(
          currentYobiint2Value,
        );

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '難易度モード設定',
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
                  // 難易度モードについての説明
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "【難易度モードの説明】\n\nこの設定は、金銀支給を制限することで、難易度を上昇させるためのものです。\n\n「極」の場合には、目標達成時の金銀支給がなくなり、春の定期支給のみになります。春の定期支給金銀量は「難易度変更」で設定した「鬼」「難しい」などの支給量のままです。\n\n「天」の場合には、金銀の支給が一切なくなります。「難易度変更」で設定した「鬼」「難しい」などの難易度は意味をなさなくなります。\n\nなお、この画面で設定できるモード変更は、「難易度変更2」で設定できる他大学の強さのレベルには影響を与えません。他大学の強さのレベルはそのまま適用されます。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // 3つのモードを切り替えるラジオボタンのリスト
                  ...KiwameMode.values.map((mode) {
                    return RadioListTile<KiwameMode>(
                      title: Text(
                        mode.title,
                        style: TextStyle(
                          color: mode == KiwameMode.ten
                              ? Colors.redAccent
                              : (mode == KiwameMode.kiwame
                                    ? Colors.orangeAccent
                                    : HENSUU.textcolor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        mode.description,
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                        ),
                      ),
                      value: mode,
                      groupValue: currentMode, // 現在選択されているモード
                      onChanged: (KiwameMode? newMode) {
                        if (newMode != null) {
                          _updateKiwameMode(newMode);
                        }
                      },
                      activeColor: mode == KiwameMode.ten
                          ? Colors.red
                          : (mode == KiwameMode.kiwame
                                ? Colors.orange
                                : Colors.blue),
                      tileColor: currentMode == mode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                    );
                  }).toList(),

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

class ModalGakurenHosei extends StatefulWidget {
  const ModalGakurenHosei({super.key});

  @override
  State<ModalGakurenHosei> createState() => _ModalGakurenHoseiState();
}

class _ModalGakurenHoseiState extends State<ModalGakurenHosei> {
  late Box<Album> _albumBox;

  @override
  void initState() {
    super.initState();
    // 適切なBox名に変更してください
    _albumBox = Hive.box<Album>('albumBox');
  }

  // yobiint4プロパティの値を変更し、Hiveに保存する関数 (オン/オフ切り替え用)
  // newValueがtrue（補正あり）の場合はyobiint4を1（最低補正）に設定し、false（補正なし）の場合は0に設定
  void _updateHoseiAcceptance(Album album, bool newValue) async {
    setState(() {
      // 補正なし(false) -> 0
      // 補正あり(true) -> 1 (最低補正値)
      album.yobiint4 = newValue ? 5 : 0;
    });
    await album.save();
  }

  // 補正値のスライダー値を変更し、Hiveに保存する関数
  void _updateHoseiValue(Album album, double sliderValue) async {
    // スライダーの値(1.0-3.0)をそのままyobiint4の値(1-3)に変換
    final int newYobiint4Value = sliderValue.toInt();

    setState(() {
      // yobiint4は1から3の範囲で補正値を示す
      album.yobiint4 = newYobiint4Value;
    });
    await album.save();
  }

  // 補正値表示用のテキストを生成
  String _getHoseiText(int yobiint4Value) {
    // 【修正点3】3段階から10段階に対応するようにロジックを変更
    if (yobiint4Value == 0) {
      return '補正なし';
    } else if (yobiint4Value >= 1 && yobiint4Value <= 10) {
      // 1-10の範囲の場合、現在の補正レベルと総段階数を表示
      String levelText;
      if (yobiint4Value <= 3) {
        levelText = '小';
      } else if (yobiint4Value <= 7) {
        levelText = '中';
      } else {
        levelText = '大';
      }
      return '補正（$levelText: $yobiint4Value/10）';
    } else {
      return '設定なし';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Album>>(
      valueListenable: _albumBox.listenable(),
      builder: (context, albumBox, _) {
        final List<Album> allAlbums = albumBox.values.toList();

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '学連選抜 モチベーション低下補正',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            // SingleChildScrollViewで画面全体をスクロール可能にする
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // 補正についての説明
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "この設定は、所属大学の一員としての出場が叶わなかったために、どうしても所属大学の一員としての出場よりもモチベーションが低下するのではないか、との制作者の勝手な妄想から設けたものです。\n1区はこちらの世界でもテレビに映るのでモチベーションは低下しないと考え、1区以外の学連選抜の選手に対してモチベーション低下によるタイム悪化の補正を適用します。\n\n補正値が大きいほど、タイムの悪化幅が大きくなります。\n\n・補正なし: タイム悪化補正を適用しない\n・補正（小～大の10段階）: タイム悪化補正を適用する",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // データがない場合の表示
                  if (allAlbums.isEmpty)
                    Center(
                      child: Text(
                        'アルバムデータがありません',
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    )
                  else
                    // データがある場合のリスト表示
                    ...allAlbums.map((album) {
                      // yobiint4 > 0 なら補正ありと判断
                      final bool isHoseiApplied = album.yobiint4 > 0;

                      // スライダーの表示値はyobiint4の値をそのまま使う
                      final double currentSliderValue = album.yobiint4
                          .toDouble();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 補正のオン/オフのトグルボタン
                          SwitchListTile(
                            title: Text(
                              "補正",
                              style: TextStyle(color: HENSUU.textcolor),
                            ),
                            subtitle: Text(
                              _getHoseiText(album.yobiint4),
                              style: TextStyle(
                                color: isHoseiApplied
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                              ),
                            ),
                            value: isHoseiApplied,
                            onChanged: (bool newValue) {
                              _updateHoseiAcceptance(album, newValue);
                            },
                            activeColor: Colors.blue, // オン時の色
                          ),

                          // 2. 補正値のスライダー
                          if (isHoseiApplied) // 補正ありの場合のみ表示
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                bottom: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Slider(
                                    // yobiint4の値をそのままスライダー値として使う
                                    value: currentSliderValue,
                                    min: 1, // 【修正点5】左端 (小) は 1
                                    max: 10, // 【修正点6】右端 (大) は 10
                                    divisions:
                                        9, // 【修正点7】1, 2, ..., 10の10段階にするため、分割数は 9
                                    // スライダーのラベルは現在の値を表示
                                    label:
                                        '${album.yobiint4}/10', // 【修正点8】ラベルを10段階表示に修正
                                    onChanged: (double newValue) {
                                      // スライダー操作中はsetStateで一時的に表示を更新
                                      final int newYobiint4 = newValue.toInt();
                                      setState(() {
                                        album.yobiint4 = newYobiint4;
                                      });
                                    },
                                    onChangeEnd: (double newValue) {
                                      // 操作終了時にHiveに保存
                                      _updateHoseiValue(album, newValue);
                                    },
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.grey.withOpacity(0.5),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '補正（小）', // 左端: yobiint4=1
                                        style: TextStyle(
                                          color: HENSUU.textcolor.withOpacity(
                                            0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '補正（大）', // 右端: yobiint4=3
                                        style: TextStyle(
                                          color: HENSUU.textcolor.withOpacity(
                                            0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const Divider(color: Colors.grey),
                        ],
                      );
                    }).toList(),

                  const SizedBox(height: 16),
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

class ModalRyugakuseiNinzu extends StatefulWidget {
  const ModalRyugakuseiNinzu({super.key});

  @override
  State<ModalRyugakuseiNinzu> createState() => _ModalRyugakuseiNinzuState();
}

class _ModalRyugakuseiNinzuState extends State<ModalRyugakuseiNinzu> {
  late Box<UnivData> _univBox;

  @override
  void initState() {
    super.initState();
    _univBox = Hive.box<UnivData>('univBox');
  }

  // UnivDataのrプロパティの値を変更し、Hiveに保存する関数
  // newValueがtrue（受け入れる）の場合はrを1（最も優秀）に設定し、false（受け入れない）の場合は0に設定
  void _updateRyugakuseiAcceptance(UnivData univ, bool newValue) async {
    setState(() {
      // 受け入れない(false) -> 0
      // 受け入れる(true) -> 1 (要件により、受け入れに変更した際は最も優秀な1を設定)
      univ.r = newValue ? 1 : 0;
    });
    await univ.save();
  }

  // 優秀度のスライダー値を変更し、Hiveに保存する関数
  void _updateRyugakuseiExcellence(UnivData univ, double sliderValue) async {
    // スライダーの値(1.0-4.0)を反転させてrの値(4-1)に変換
    // スライダー: 1.0 -> r=4 (最低優秀)
    // スライダー: 4.0 -> r=1 (最高優秀)
    // 変換式: r = 5 - sliderValue.toInt()
    final int newRValue = (5 - sliderValue).toInt();

    setState(() {
      // rは1から4の範囲で、受け入れフラグも兼ねている
      univ.r = newRValue;
    });
    await univ.save();
  }

  // 優秀度表示用のテキストを生成
  String _getExcellenceText(int rValue) {
    switch (rValue) {
      case 1:
        return '最高優秀';
      case 2:
        return '優秀';
      case 3:
        return '普通';
      case 4:
        return 'やや優秀でない';
      default:
        return '設定なし'; // rが1-4以外の場合は表示しない想定
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UnivData>>(
      valueListenable: _univBox.listenable(),
      builder: (context, univBox, _) {
        final List<UnivData> allUnivs = univBox.values.toList();

        if (allUnivs.isEmpty) {
          // ... (変更なし)
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '留学生受け入れ設定',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                '大学データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '留学生受け入れ設定',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "留学生の受け入れをオン/オフし、優秀度（1-4）を設定できます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: allUnivs.length,
                    itemBuilder: (context, index) {
                      final UnivData univ = allUnivs[index];
                      // r > 0 なら留学生受け入れ中と判断
                      final bool isRyugakuseiAccepted = univ.r > 0;

                      // r (1-4) をスライダーの表示値 (4.0-1.0) に変換する
                      // r=1 (最高優秀) -> スライダー値 4.0 (右端)
                      // r=4 (最低優秀) -> スライダー値 1.0 (左端)
                      final double currentSliderValue = univ.r > 0
                          ? (5 - univ.r).toDouble()
                          : 4.0; // r=0 (受け入れない)の場合、初期値としてスライダーの最高値(4.0)を使用

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 受け入れ/受け入れないのトグルボタン
                          SwitchListTile(
                            title: Text(
                              univ.name,
                              style: TextStyle(color: HENSUU.textcolor),
                            ),
                            subtitle: Text(
                              isRyugakuseiAccepted
                                  ? '受け入れ中 (${_getExcellenceText(univ.r)})'
                                  : '受け入れない',
                              style: TextStyle(
                                color: isRyugakuseiAccepted
                                    ? Colors.lightGreen
                                    : Colors.grey,
                              ),
                            ),
                            value: isRyugakuseiAccepted,
                            onChanged: (bool newValue) {
                              _updateRyugakuseiAcceptance(univ, newValue);
                            },
                            activeColor: Colors.blue, // オン時の色
                          ),

                          // 2. 優秀度のスライダー
                          if (isRyugakuseiAccepted) // 受け入れ中の場合のみ表示
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                bottom: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Slider(
                                    // 実際のrの値ではなく、反転させたスライダー値を渡す
                                    value: currentSliderValue,
                                    min: 1, // 左端
                                    max: 4, // 右端
                                    divisions: 3, // 1, 2, 3, 4の4段階
                                    // スライダーのラベルも、反転後のrの値を表示する (5 - value)
                                    label:
                                        '${(5 - currentSliderValue).toInt()}',
                                    onChanged: (double newValue) {
                                      // スライダー操作中はsetStateで一時的に表示を更新 (rの値も反転させて更新)
                                      final int newR = (5 - newValue).toInt();
                                      setState(() {
                                        univ.r = newR;
                                      });
                                    },
                                    onChangeEnd: (double newValue) {
                                      // 操作終了時にHiveに保存
                                      _updateRyugakuseiExcellence(
                                        univ,
                                        newValue,
                                      );
                                    },
                                    activeColor: Colors.teal,
                                    inactiveColor: Colors.grey.withOpacity(0.5),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '最低優秀', // 左端: r=4
                                        style: TextStyle(
                                          color: HENSUU.textcolor.withOpacity(
                                            0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '最高優秀', // 右端: r=1
                                        style: TextStyle(
                                          color: HENSUU.textcolor.withOpacity(
                                            0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const Divider(color: Colors.grey),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white, // ボタンの文字色を白に変更
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
        );
      },
    );
  }
}

class ModalEkidenFameSettings extends StatefulWidget {
  const ModalEkidenFameSettings({super.key});

  @override
  State<ModalEkidenFameSettings> createState() =>
      _ModalEkidenFameSettingsState();
}

class _ModalEkidenFameSettingsState extends State<ModalEkidenFameSettings> {
  // 10月駅伝
  final TextEditingController _octoberFameNumeratorController =
      TextEditingController();
  final TextEditingController _octoberFameDenominatorController =
      TextEditingController();
  // 11月駅伝
  final TextEditingController _novemberFameNumeratorController =
      TextEditingController();
  final TextEditingController _novemberFameDenominatorController =
      TextEditingController();
  // 正月駅伝
  final TextEditingController _januaryFameNumeratorController =
      TextEditingController();
  final TextEditingController _januaryFameDenominatorController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  /// 初期値をロードする関数
  Future<void> _loadInitialValues() async {
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final List<UnivData> allUnivData = univdataBox.values.toList();
    final List<UnivData> sortedUnivData = allUnivData
      ..sort((a, b) => a.id.compareTo(b.id));

    // UnivDataのname_tanshukuに保存された文字列から整数値を設定
    _octoberFameNumeratorController.text =
        sortedUnivData[1].name_tanshuku.isNotEmpty
        ? sortedUnivData[1].name_tanshuku
        : '1';
    _octoberFameDenominatorController.text =
        sortedUnivData[2].name_tanshuku.isNotEmpty
        ? sortedUnivData[2].name_tanshuku
        : '1';
    _novemberFameNumeratorController.text =
        sortedUnivData[3].name_tanshuku.isNotEmpty
        ? sortedUnivData[3].name_tanshuku
        : '1';
    _novemberFameDenominatorController.text =
        sortedUnivData[4].name_tanshuku.isNotEmpty
        ? sortedUnivData[4].name_tanshuku
        : '1';
    _januaryFameNumeratorController.text =
        sortedUnivData[5].name_tanshuku.isNotEmpty
        ? sortedUnivData[5].name_tanshuku
        : '1';
    _januaryFameDenominatorController.text =
        sortedUnivData[6].name_tanshuku.isNotEmpty
        ? sortedUnivData[6].name_tanshuku
        : '1';
  }

  @override
  void dispose() {
    _octoberFameNumeratorController.dispose();
    _octoberFameDenominatorController.dispose();
    _novemberFameNumeratorController.dispose();
    _novemberFameDenominatorController.dispose();
    _januaryFameNumeratorController.dispose();
    _januaryFameDenominatorController.dispose();
    super.dispose();
  }

  /// 入力された文字列を1から10の範囲に補正するヘルパー関数
  int _clampValue(String value) {
    int parsedValue = int.tryParse(value) ?? 1;
    return parsedValue.clamp(1, 10);
  }

  /// 名声倍率設定用のWidgetを生成するヘルパー関数
  Widget _buildFameSettings(
    String title,
    TextEditingController numeratorController,
    TextEditingController denominatorController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: HENSUU.textcolor,
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "1から10の整数で設定してください。 y/x の形で名声倍率が決まります。",
          style: TextStyle(color: HENSUU.textcolor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: numeratorController,
                decoration: const InputDecoration(
                  labelText: '分子 (y)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  final int parsedValue = int.tryParse(value) ?? 0;
                  if (parsedValue > 10) {
                    numeratorController.text = '10';
                    numeratorController.selection = TextSelection.fromPosition(
                      TextPosition(offset: numeratorController.text.length),
                    );
                  }
                },
                onSubmitted: (value) {
                  numeratorController.text = _clampValue(value).toString();
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '/',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: denominatorController,
                decoration: const InputDecoration(
                  labelText: '分母 (x)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  final int parsedValue = int.tryParse(value) ?? 0;
                  if (parsedValue > 10) {
                    denominatorController.text = '10';
                    denominatorController
                        .selection = TextSelection.fromPosition(
                      TextPosition(offset: denominatorController.text.length),
                    );
                  }
                },
                onSubmitted: (value) {
                  denominatorController.text = _clampValue(value).toString();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('駅伝名声倍率設定', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Divider(color: Colors.grey),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: <Widget>[
                    _buildFameSettings(
                      '10月駅伝の名声倍率\n(初期値1位:500)',
                      _octoberFameNumeratorController,
                      _octoberFameDenominatorController,
                    ),
                    _buildFameSettings(
                      '11月駅伝の名声倍率\n(初期値1位:500)',
                      _novemberFameNumeratorController,
                      _novemberFameDenominatorController,
                    ),
                    _buildFameSettings(
                      '正月駅伝の名声倍率\n(初期値1位:2000)',
                      _januaryFameNumeratorController,
                      _januaryFameDenominatorController,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      '※参考までに対校戦1位の大学は1000名声が上昇しますが、対校戦での獲得名声は変更できない仕様です。',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final Box<UnivData> univdataBox = Hive.box<UnivData>(
                          'univBox',
                        );
                        final List<UnivData> sortedUnivData =
                            univdataBox.values.toList()
                              ..sort((a, b) => a.id.compareTo(b.id));

                        // 値を補正し、UnivDataに保存
                        if (sortedUnivData.length > 6) {
                          sortedUnivData[1].name_tanshuku = _clampValue(
                            _octoberFameNumeratorController.text,
                          ).toString();
                          sortedUnivData[2].name_tanshuku = _clampValue(
                            _octoberFameDenominatorController.text,
                          ).toString();
                          sortedUnivData[3].name_tanshuku = _clampValue(
                            _novemberFameNumeratorController.text,
                          ).toString();
                          sortedUnivData[4].name_tanshuku = _clampValue(
                            _novemberFameDenominatorController.text,
                          ).toString();
                          sortedUnivData[5].name_tanshuku = _clampValue(
                            _januaryFameNumeratorController.text,
                          ).toString();
                          sortedUnivData[6].name_tanshuku = _clampValue(
                            _januaryFameDenominatorController.text,
                          ).toString();

                          await Future.wait([
                            sortedUnivData[1].save(),
                            sortedUnivData[2].save(),
                            sortedUnivData[3].save(),
                            sortedUnivData[4].save(),
                            sortedUnivData[5].save(),
                            sortedUnivData[6].save(),
                          ]);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12.0),
                      ),
                      child: Text(
                        "決定",
                        style: TextStyle(
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModalSpurtryokuseichousisuu2 extends StatefulWidget {
  const ModalSpurtryokuseichousisuu2({super.key});

  @override
  State<ModalSpurtryokuseichousisuu2> createState() =>
      _ModalSpurtryokuseichousisuu2State();
}

class _ModalSpurtryokuseichousisuu2State
    extends State<ModalSpurtryokuseichousisuu2> {
  // ボタンのデータを定義
  final List<Map<String, dynamic>> _options = const [
    {
      'value': 93,
      'label': '向上心豊か（初期値）',
      'description': '初期値設定です。\n目標設定の際に、前年の当該駅伝での成績をもとに、上位を目指す傾向があります。',
    },
    {
      'value': 1,
      'label': '対校戦順位追従設定',
      'description': '当年の対校戦の順位を重視します。\n目標設定が現実的になります。',
    },
    {
      'value': 2,
      'label': '常にシード権意識設定',
      'description': '常にシード権（特定の順位以上）を意識して目標設定します。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '目標設定意識変更',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        // 現在の設定名を取得
        String currentLabel = _options.firstWhere(
          (option) => option['value'] == currentGhensuu.spurtryokuseichousisuu2,
          orElse: () => {'label': '不明な設定'},
        )['label'];

        // 現在の設定の説明を取得
        String currentDescription = _options.firstWhere(
          (option) => option['value'] == currentGhensuu.spurtryokuseichousisuu2,
          orElse: () => {'description': '現在の設定に関する説明がありません。'},
        )['description'];

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              'COM大学目標設定意識変更',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "現在の設定は\n「$currentLabel」\nです。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          currentDescription,
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 32),
                        // 3つのボタンを動的に生成
                        ..._options.map((option) {
                          return Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    currentGhensuu.spurtryokuseichousisuu2 =
                                        option['value'];
                                  });
                                  await currentGhensuu.save();

                                  // SnackBarを表示
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${option['label']}に設定を変更しました。\n反映は翌年度になる場合があります。",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.green.shade800,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(200, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "${option['label']}にする",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.grey),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
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
        );
      },
    );
  }
}

class ModalSpurtryokuseichousisuu3 extends StatefulWidget {
  const ModalSpurtryokuseichousisuu3({super.key});

  @override
  State<ModalSpurtryokuseichousisuu3> createState() =>
      _ModalSpurtryokuseichousisuu3State();
}

class _ModalSpurtryokuseichousisuu3State
    extends State<ModalSpurtryokuseichousisuu3> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '名声値の影響力変更',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '名声値の影響力変更',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "名声値の影響力を設定できます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "現在の設定は レベル ${currentGhensuu.spurtryokuseichousisuu3} です",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "数字が小さいほど新入生は名声値を気にせずに入学大学を決め、数字が大きいほど名声値を重視します。\nこの設定は次の新入生募集時から影響します。",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 32),
                        // 0から9までの10個のボタンを動的に生成
                        ...List.generate(10, (index) {
                          return Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    currentGhensuu.spurtryokuseichousisuu3 =
                                        index;
                                  });
                                  await currentGhensuu.save();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(200, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "レベル $index にする",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.grey),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
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
        );
      },
    );
  }
}

class ModalUnivNameHenkou extends StatefulWidget {
  const ModalUnivNameHenkou({super.key});

  @override
  State<ModalUnivNameHenkou> createState() => _ModalUnivNameHenkouState();
}

class _ModalUnivNameHenkouState extends State<ModalUnivNameHenkou> {
  // Swiftの @State private var text = "" に相当
  final TextEditingController _universityNameController =
      TextEditingController();
  // Swiftの @State private var text2 = "" に相当 (短縮名用として追加)
  final TextEditingController _abbreviationController = TextEditingController();

  @override
  void dispose() {
    _universityNameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('大学名変更', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();

            // sortedunivdata: [UnivData]
            final List<UnivData> sortedUnivData = allUnivData
              ..sort((a, b) => a.id.compareTo(b.id));

            // 編集対象の大学
            UnivData? targetUniv;
            if (currentGhensuu.hyojiunivnum >= 0 &&
                currentGhensuu.hyojiunivnum < sortedUnivData.length) {
              targetUniv = sortedUnivData[currentGhensuu.hyojiunivnum];
            }

            // targetUniv が null の場合も考慮
            if (targetUniv == null) {
              return Scaffold(
                backgroundColor: HENSUU.backgroundcolor,
                appBar: AppBar(
                  title: const Text(
                    '大学名変更',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Text(
                    '大学データが見つかりません',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              );
            }

            // TextFieldの初期値を設定（初回のみ）
            if (_universityNameController.text.isEmpty &&
                _abbreviationController.text.isEmpty) {
              _universityNameController.text = targetUniv.name;
              _abbreviationController.text = targetUniv.name_tanshuku;
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  '大学名変更',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          Text(
                            "${targetUniv.name}の名称を変更",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize:
                                  HENSUU.fontsize_honbun! *
                                  1.5, // .font(.title) に相当
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "「大学」を除いて入力してください",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          Text(
                            "最大5文字までの入力を推奨\n\n",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          TextField(
                            controller: _universityNameController,
                            decoration: InputDecoration(
                              hintText: "ここに入力",
                              filled: true,
                              fillColor: Colors.white, // TextFieldの背景色を白に
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ), // 角丸
                              ),
                              contentPadding: const EdgeInsets.all(12.0),
                            ),
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              color: Colors.black,
                            ), // 入力文字色を黒に
                            onChanged: (value) {
                              if (value.length > 20) {
                                // Swiftの20文字制限を適用
                                _universityNameController.text = value
                                    .substring(0, 20);
                                // カーソルを末尾に移動
                                _universityNameController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset:
                                        _universityNameController.text.length,
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 24), // ボタンとのスペース

                          Center(
                            // SwiftUIの.frame(maxWidth: .infinity, alignment: .center)に相当
                            child: ElevatedButton(
                              onPressed: () async {
                                // 大学名を更新
                                targetUniv!.name =
                                    _universityNameController.text;
                                //targetUniv.name_tanshuku = _abbreviationController.text; // 短縮名も更新
                                await targetUniv.save(); // Hiveに保存

                                Navigator.pop(context); // モーダルを閉じる
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green, // Swiftの.background(.green)
                                foregroundColor: Colors
                                    .black, // Swiftの.foregroundColor(.black)
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // Swiftの.cornerRadius(8)
                                ),
                                minimumSize: const Size(
                                  200,
                                  48,
                                ), // Swiftの.frame(width: 200)とpadding()を考慮
                                padding: const EdgeInsets.all(12.0),
                              ),
                              child: Text(
                                "決定",
                                style: TextStyle(
                                  fontSize:
                                      HENSUU.fontsize_honbun! *
                                      1.5, // .font(.largeTitle)に相当
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Colors.grey),

                  // 戻るボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // モーダルを閉じる
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ModalKantokuUnivHenkou extends StatefulWidget {
  const ModalKantokuUnivHenkou({super.key});

  @override
  State<ModalKantokuUnivHenkou> createState() => _ModalKantokuUnivHenkouState();
}

class _ModalKantokuUnivHenkouState extends State<ModalKantokuUnivHenkou> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '総監督をする大学変更',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();

            // sortedunivdata: [UnivData]
            final List<UnivData> sortedUnivData = allUnivData
              ..sort((a, b) => a.id.compareTo(b.id));

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
              appBar: AppBar(
                title: const Text(
                  '総監督をする大学変更',
                  style: TextStyle(color: Colors.white),
                ),
                automaticallyImplyLeading: false, // 常に非表示
                backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
                foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  const Divider(color: Colors.grey),

                  Expanded(
                    // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0), // 全体的なパディング
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          Text(
                            "大学選択",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize:
                                  HENSUU.fontsize_honbun! *
                                  1.5, // .font(.title) に相当
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "あなたが総監督をする大学を選択してください。",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          Text(
                            "なお、学内記録や学内順位は、あなたが総監督をしている大学しか計算・記録しませんのでご了承ください。また、移籍先での学内順位表示は不正確な場合があります。",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ForEach(0..<TEISUU.UNIVSUU, id: \.self) に相当
                          for (int i = 0; i < TEISUU.UNIVSUU; i++)
                            Center(
                              // .frame(maxWidth: .infinity, alignment: .center) に相当
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ), // ボタン間のスペース
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isLoading = true; // 2. ローディング開始
                                          });

                                          try {
                                            currentGhensuu.MYunivid = i;
                                            currentGhensuu.hyojiunivnum =
                                                currentGhensuu.MYunivid;

                                            await currentGhensuu
                                                .save(); // Hiveに保存

                                            // --- 個人ベスト記録の全体順位・学内順位更新 ---
                                            /*final Box<SenshuData>
                                            senshudataBox =
                                                Hive.box<SenshuData>(
                                                  'senshuBox',
                                                );
                                            List<SenshuData> sortedsenshudata =
                                                senshudataBox.values.toList();
                                            sortedsenshudata.sort(
                                              (a, b) => a.id.compareTo(b.id),
                                            );
                                            for (
                                              int kirokubangou = 0;
                                              kirokubangou <
                                                  TEISUU
                                                      .SUU_KOJINBESTKIROKUSHURUISUU;
                                              kirokubangou++
                                            ) {
                                              // 同期処理
                                              kojinBestKirokuJuniKettei(
                                                kirokubangou,
                                                [currentGhensuu],
                                                sortedsenshudata,
                                              );
                                            }
                                            // 選手データをHiveに保存 (非同期処理)
                                            for (final senshu
                                                in sortedsenshudata) {
                                              await senshu.save();
                                            }*/

                                            if (mounted) {
                                              Navigator.pop(context);
                                            }
                                          } catch (e) {
                                            // エラーが起きた場合の処理
                                            print(e);
                                            if (mounted) {
                                              setState(() {
                                                _isLoading = false;
                                              });
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .green, // Swiftの.background(.green)
                                    foregroundColor: Colors
                                        .black, // Swiftの.foregroundColor(.black)
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // Swiftの.cornerRadius(8)
                                    ),
                                    minimumSize: const Size(
                                      200,
                                      48,
                                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                                    padding: const EdgeInsets.all(12.0),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.green, // テキスト色に合わせる
                                            strokeWidth: 3.0,
                                          ),
                                        )
                                      : Text(
                                          sortedUnivData[i].name,
                                          style: TextStyle(
                                            fontSize: HENSUU.fontsize_honbun,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Colors.grey),

                  // 戻るボタン (HStackに相当)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context); // モーダルを閉じる
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ModalMieruNouryokuReset extends StatefulWidget {
  const ModalMieruNouryokuReset({super.key});

  @override
  State<ModalMieruNouryokuReset> createState() =>
      _ModalMieruNouryokuResetState();
}

class _ModalMieruNouryokuResetState extends State<ModalMieruNouryokuReset> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '能力リセット',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
          appBar: AppBar(
            title: const Text('能力リセット', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
            foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0), // SwiftUIの.padding()に相当
            child: Column(
              // SwiftUIのVStackに相当
              mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
              crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
              children: <Widget>[
                Text(
                  "本当に選手の能力を見抜く総監督の能力をリセットしますか？",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // テキストを中央寄せ
                ),
                const SizedBox(height: 32), // スペース
                // 「はい」ボタン
                ElevatedButton(
                  onPressed: () async {
                    // gh[0].nouryokumieruflag の全要素を0にリセット
                    // Swift: gh[0].nouryokumieruflag[0]=0; ... gh[0].nouryokumieruflag[19]=0;
                    setState(() {
                      // UIを更新するためsetStateで囲む
                      for (
                        int i = 0;
                        i < currentGhensuu.nouryokumieruflag.length;
                        i++
                      ) {
                        currentGhensuu.nouryokumieruflag[i] = 0;
                      }
                      //currentGhensuu.nouryokumieruflag[4] = 1;
                    });
                    await currentGhensuu.save(); // Hiveに保存
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "はい",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32), // スペース

                const Divider(color: Colors.grey), // Divider
                const SizedBox(height: 32), // スペース
                // 「いいえ、やっぱりリセットしません。」ボタン
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "いいえ、やっぱりリセットしません。",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // SwiftUIのSpacer() に相当するが、ここではColumnのmainAxisAlignment.centerで調整
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModalAllReset extends StatefulWidget {
  const ModalAllReset({super.key});

  @override
  State<ModalAllReset> createState() => _ModalAllResetState();
}

class _ModalAllResetState extends State<ModalAllReset> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('全リセット', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
          appBar: AppBar(
            title: const Text('全リセット', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
            foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0), // SwiftUIの.padding()に相当
            child: Column(
              // SwiftUIのVStackに相当
              mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
              crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
              children: <Widget>[
                Text(
                  "本当に全てリセットしてやり直しますか？\nアルバムも消去されます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // テキストを中央寄せ
                ),
                const SizedBox(height: 32), // スペース
                // 「はい」ボタン
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      // UIを更新するためsetStateで囲む
                      currentGhensuu.mode = 10; // gh[0].mode=10; に相当
                    });
                    await currentGhensuu.save(); // Hiveに保存
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "はい",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32), // スペース

                const Divider(color: Colors.grey), // Divider
                const SizedBox(height: 32), // スペース
                // 「いいえ、やっぱりリセットしません。」ボタン
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "いいえ、やっぱりリセットしません。",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModalNanidoHenkou extends StatefulWidget {
  const ModalNanidoHenkou({super.key});

  @override
  State<ModalNanidoHenkou> createState() => _ModalNanidoHenkouState();
}

class _ModalNanidoHenkouState extends State<ModalNanidoHenkou> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('難易度変更', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        // 現在の難易度を示すテキスト
        String currentDifficultyText;
        switch (currentGhensuu.kazeflag) {
          case 0:
            currentDifficultyText = "現在の難易度は 鬼 です。";
            break;
          case 1:
            currentDifficultyText = "現在の難易度は 難しい です。";
            break;
          case 2:
            currentDifficultyText = "現在の難易度は 普通 です。";
            break;
          case 3:
            currentDifficultyText = "現在の難易度は 易しい です。";
            break;
          default:
            currentDifficultyText = "現在の難易度は不明です。";
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
          appBar: AppBar(
            title: const Text('難易度変更', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
            foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0), // SwiftUIの.padding()に相当
            child: Column(
              // SwiftUIのVStackに相当
              mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
              crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
              children: <Widget>[
                Text(
                  "難易度を変更できます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  currentDifficultyText,
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32), // スペース

                const Divider(color: Colors.grey), // Divider
                const SizedBox(height: 32), // スペース

                Expanded(
                  // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                  child: SingleChildScrollView(
                    child: Column(
                      // LazyVStackに相当
                      crossAxisAlignment: CrossAxisAlignment.center, // ボタンを中央寄せ
                      children: <Widget>[
                        // 「鬼 にする」ボタン
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              currentGhensuu.kazeflag = 0;
                            });
                            await currentGhensuu.save();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 48),
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: Text(
                            "鬼 にする",
                            style: TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // ボタン間のスペース
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),

                        // 「難しい にする」ボタン
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              currentGhensuu.kazeflag = 1;
                            });
                            await currentGhensuu.save();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 48),
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: Text(
                            "難しい にする",
                            style: TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),

                        // 「普通 にする」ボタン
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              currentGhensuu.kazeflag = 2;
                            });
                            await currentGhensuu.save();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 48),
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: Text(
                            "普通 にする",
                            style: TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),

                        // 「易しい にする」ボタン
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              currentGhensuu.kazeflag = 3;
                            });
                            await currentGhensuu.save();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 48),
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: Text(
                            "易しい にする",
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
                const SizedBox(height: 32), // スペース

                const Divider(color: Colors.grey), // Divider
                const SizedBox(height: 32), // スペース
                // 戻るボタン
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
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
        );
      },
    );
  }
}

class ModalOndoHenkou extends StatefulWidget {
  const ModalOndoHenkou({super.key});

  @override
  State<ModalOndoHenkou> createState() => _ModalOndoHenkouState();
}

class _ModalOndoHenkouState extends State<ModalOndoHenkou> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '難易度変更2',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text('難易度変更2', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "他大学の強さを設定できます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "現在は レベル ${currentGhensuu.ondoflag} です",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // 指定されたテキストをスクロール可能な部分に移動
                        Text(
                          "数字が大きいほど他大学が強くなります。\n数字が大きいと難易度易しいでも無理ゲーかもしれないです。\nすぐには変化はなく、春か夏の成長時に変化します。また、レベルを下げる場合は、完全に浸透するまでに4年かかります。\n**個々の大学ごとの設定はできず、自分の大学以外の全ての大学が同じ設定になりますのでご注意ください**",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 32),
                        // 0から7までの8つのボタンを動的に生成
                        ...List.generate(10, (index) {
                          return Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    currentGhensuu.ondoflag = index;
                                  });
                                  await currentGhensuu.save();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(200, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "レベル $index にする",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.grey),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
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
        );
      },
    );
  }
}

class ModalIkuseiryokuHenkou extends StatefulWidget {
  const ModalIkuseiryokuHenkou({super.key});

  @override
  State<ModalIkuseiryokuHenkou> createState() => _ModalIkuseiryokuHenkouState();
}

class _ModalIkuseiryokuHenkouState extends State<ModalIkuseiryokuHenkou> {
  late Box<UnivData> _univBox;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _univBox = Hive.box<UnivData>('univBox');
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  TextEditingController _getController(int key, String initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText);
    }
    return _controllers[key]!;
  }

  FocusNode _getFocusNode(int key, UnivData univ) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() => _onFocusChange(key, univ));
    }
    return _focusNodes[key]!;
  }

  void _onFocusChange(int key, UnivData univ) async {
    if (!_focusNodes[key]!.hasFocus) {
      // フォーカスが外れたときの処理
      final String value = _controllers[key]!.text;
      final int? newValue = int.tryParse(value);

      if (newValue == null || newValue < 10 || newValue > 150) {
        // 無効な値が入力されていた場合、元の有効な値に戻す
        _controllers[key]!.text = univ.ikuseiryoku.toString();
      } else {
        // 有効な値が入力されていた場合、保存する
        setState(() {
          univ.ikuseiryoku = newValue;
        });
        await univ.save();
      }
    }
  }

  void _onTextFieldSubmitted(UnivData univ, String value) async {
    final int? newValue = int.tryParse(value);
    if (newValue != null && newValue >= 10 && newValue <= 150) {
      setState(() {
        univ.ikuseiryoku = newValue;
      });
      await univ.save();
    } else {
      _controllers[univ.key]?.text = univ.ikuseiryoku.toString();
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UnivData>>(
      valueListenable: _univBox.listenable(),
      builder: (context, univBox, _) {
        final List<UnivData> allUnivs = univBox.values.toList();

        if (allUnivs.isEmpty) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('育成力設定', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                '大学データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('育成力設定', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "10から150の間で設定できます。",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allUnivs.length,
                      itemBuilder: (context, index) {
                        final UnivData univ = allUnivs[index];
                        final key = univ.key as int;
                        final controller = _getController(
                          key,
                          univ.ikuseiryoku.toString(),
                        );
                        final focusNode = _getFocusNode(key, univ);

                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                univ.name,
                                style: TextStyle(color: HENSUU.textcolor),
                              ),
                              trailing: SizedBox(
                                width: 80,
                                child: TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: TextStyle(color: HENSUU.textcolor),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final int? newValue = int.tryParse(value);
                                    if (newValue != null &&
                                        newValue >= 10 &&
                                        newValue <= 150) {
                                      setState(() {
                                        univ.ikuseiryoku = newValue;
                                      });
                                    }
                                    // onChangedでは保存せず、フォーカスが外れたときにまとめて処理する
                                  },
                                  onFieldSubmitted: (value) =>
                                      _onTextFieldSubmitted(univ, value),
                                ),
                              ),
                            ),
                            Slider(
                              value: univ.ikuseiryoku.toDouble(),
                              min: 10,
                              max: 150,
                              divisions: 140,
                              label: univ.ikuseiryoku.toString(),
                              onChanged: (double newValue) {
                                setState(() {
                                  univ.ikuseiryoku = newValue.toInt();
                                  controller.text = newValue.toInt().toString();
                                });
                              },
                              onChangeEnd: (double newValue) async {
                                univ.ikuseiryoku = newValue.toInt();
                                await univ.save();
                              },
                            ),
                            const Divider(color: Colors.grey),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.black,
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

class ModalMeiseiHenkou extends StatefulWidget {
  const ModalMeiseiHenkou({super.key});

  @override
  State<ModalMeiseiHenkou> createState() => _ModalMeiseiHenkouState();
}

class _ModalMeiseiHenkouState extends State<ModalMeiseiHenkou> {
  late Box<UnivData> _univBox;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  static const int minMeisei = 9;
  static const int defaultMaxMeisei = 100000;

  @override
  void initState() {
    super.initState();
    _univBox = Hive.box<UnivData>('univBox');
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  TextEditingController _getController(int key, String initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText);
    }
    return _controllers[key]!;
  }

  FocusNode _getFocusNode(int key, UnivData univ) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() => _onFocusChange(key, univ));
    }
    return _focusNodes[key]!;
  }

  void _updateMeiseiValues(UnivData univ, int newMeiseiTotal) {
    univ.meisei_total = newMeiseiTotal;

    final int baseValue = newMeiseiTotal ~/ 10;
    final int remainder = newMeiseiTotal % 10;
    univ.meisei_yeargoto = List.generate(10, (index) {
      if (index < remainder) {
        return baseValue + 1;
      }
      return baseValue;
    });
  }

  void _onFocusChange(int key, UnivData univ) async {
    if (!_focusNodes[key]!.hasFocus) {
      final String value = _controllers[key]!.text;
      final int? newValue = int.tryParse(value);
      final int currentMaxMeisei = _calculateCurrentMaxMeisei();

      if (newValue == null ||
          newValue < minMeisei ||
          newValue > currentMaxMeisei) {
        _controllers[key]!.text = univ.meisei_total.toString();
      } else {
        setState(() {
          _updateMeiseiValues(univ, newValue);
        });
        await univ.save();
      }
    }
  }

  void _onTextFieldSubmitted(UnivData univ, String value) async {
    final int? newValue = int.tryParse(value);
    final int currentMaxMeisei = _calculateCurrentMaxMeisei();
    if (newValue != null &&
        newValue >= minMeisei &&
        newValue <= currentMaxMeisei) {
      setState(() {
        _updateMeiseiValues(univ, newValue);
      });
      await univ.save();
    } else {
      _controllers[univ.key]?.text = univ.meisei_total.toString();
    }
    FocusScope.of(context).unfocus();
  }

  Future<void> _updateMeiseiRanking() async {
    final List<UnivData> allUnivs = _univBox.values.toList();

    allUnivs.sort((a, b) => b.meisei_total.compareTo(a.meisei_total));

    for (int i = 0; i < allUnivs.length; i++) {
      final UnivData univ = allUnivs[i];
      univ.meiseijuni = i;
      await univ.save();
    }
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    await _updateMeiseiRanking();
    return true;
  }

  int _calculateAverageMeisei(List<UnivData> univs) {
    if (univs.isEmpty) return 0;
    final int totalMeisei = univs.fold(
      0,
      (sum, univ) => sum + univ.meisei_total,
    );
    return (totalMeisei / univs.length).round();
  }

  int _calculateCurrentMaxMeisei() {
    final List<UnivData> allUnivs = _univBox.values.toList();
    if (allUnivs.isEmpty) {
      return defaultMaxMeisei;
    }
    final int highestMeisei = allUnivs.map((e) => e.meisei_total).reduce(max);
    return max(highestMeisei, defaultMaxMeisei);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ValueListenableBuilder<Box<UnivData>>(
        valueListenable: _univBox.listenable(),
        builder: (context, univBox, _) {
          final List<UnivData> allUnivs = univBox.values.toList();

          if (allUnivs.isEmpty) {
            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  '名声設定',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Text(
                  '大学データがありません',
                  style: TextStyle(color: HENSUU.textcolor),
                ),
              ),
            );
          }

          final int currentMaxMeisei = _calculateCurrentMaxMeisei();
          final int averageMeisei = _calculateAverageMeisei(allUnivs);
          // itemCountを元に戻す
          final int itemCount = allUnivs.length + 1;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  '名声設定',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "平均名声: $averageMeisei",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun + 2,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: ListView.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          // index == 0 の場合、注意書きを表示
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                children: [
                                  Text(
                                    // 50000の部分をcurrentMaxMeiseiに置き換える
                                    "名声を9から$currentMaxMeiseiの間で設定できます。\nなお、このゲームの年間獲得総名声は12060、過去9年積み上がる+各大学最低1補償で12年以降4月時点での総合計は108570、30大学の平均値は3619になります。\nまた、戻った直後の画面上では名声変更が反映されていないですが、一回自分の大学ボタンをタップしていただければ画面に反映されます。（気にならなければいちいちタップする必要もありません。）",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontSize: HENSUU.fontsize_honbun,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.grey),
                                ],
                              ),
                            );
                          }

                          // 2番目以降のアイテムは大学データリストを表示
                          final UnivData univ = allUnivs[index - 1]; // indexを調整
                          final key = univ.key as int;
                          final controller = _getController(
                            key,
                            univ.meisei_total.toString(),
                          );
                          final focusNode = _getFocusNode(key, univ);

                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  univ.name,
                                  style: TextStyle(color: HENSUU.textcolor),
                                ),
                                trailing: SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: TextStyle(color: HENSUU.textcolor),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final int? newValue = int.tryParse(value);
                                      if (newValue != null &&
                                          newValue >= minMeisei &&
                                          newValue <= currentMaxMeisei) {
                                        setState(() {
                                          _updateMeiseiValues(univ, newValue);
                                        });
                                      }
                                    },
                                    onFieldSubmitted: (value) =>
                                        _onTextFieldSubmitted(univ, value),
                                  ),
                                ),
                              ),
                              Slider(
                                value: univ.meisei_total.toDouble(),
                                min: minMeisei.toDouble(),
                                max: currentMaxMeisei.toDouble(),
                                divisions: currentMaxMeisei - minMeisei,
                                label: univ.meisei_total.toString(),
                                onChanged: (double newValue) {
                                  setState(() {
                                    _updateMeiseiValues(univ, newValue.toInt());
                                    controller.text = newValue
                                        .toInt()
                                        .toString();
                                  });
                                },
                                onChangeEnd: (double newValue) async {
                                  _updateMeiseiValues(univ, newValue.toInt());
                                  await univ.save();
                                },
                              ),
                              const Divider(color: Colors.grey),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await _updateMeiseiRanking();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
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
      ),
    );
  }
}

class UnivScreen extends StatefulWidget {
  const UnivScreen({super.key});

  @override
  State<UnivScreen> createState() => _UnivScreenState();
}

class _UnivScreenState extends State<UnivScreen> {
  // Hive Boxの参照を保持
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox; // 表示には直接使用しませんが、完全性のために保持
  late Box<UnivData> _univBox;
  late Box<KantokuData> _kantokuBox;
  late Box<Senshu_R_Data> _rsenshuBox;
  late Box<Album> _albumBox;
  @override
  void initState() {
    super.initState();
    // initStateでHive Boxの参照を取得
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _rsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
    _albumBox = Hive.box<Album>('albumBox');
  }

  // 表示する大学の番号 (hyojiunivnum) を更新する関数
  void _changeHyojiUnivNum(int delta) async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    int newUnivNum = ghensuu.hyojiunivnum + delta;

    if (newUnivNum < 0) {
      newUnivNum = TEISUU.UNIVSUU - 1;
    } else if (newUnivNum >= TEISUU.UNIVSUU) {
      newUnivNum = 0;
    }

    ghensuu.hyojiunivnum = newUnivNum;
    await ghensuu.save();
  }

  // 自分の大学に切り替える関数
  void _goToMyUniv() async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    ghensuu.hyojiunivnum = ghensuu.MYunivid;
    await ghensuu.save();
  }

  // gamenflag を更新する関数 (ナビゲーションバーに切り替わるため、ここでは「最新画面へ」ボタンのみ)
  void _goToLatestScreen() async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    ghensuu.gamenflag = 0; // 最新画面のフラグが0であると仮定
    await ghensuu.save();
  }

  // 各レースの履歴表示ウィジェットを生成するヘルパー関数
  Widget _buildRaceHistory(
    String title,
    UnivData univData,
    int raceIndex,
    Ghensuu ghensuu,
  ) {
    // raceIndexが有効な範囲にあることを確認
    if (raceIndex < 0 ||
        raceIndex >= univData.juni_race.length ||
        raceIndex >= univData.taikaibetushutujoukaisuu.length ||
        raceIndex >= univData.taikaibetusaikoujuni.length ||
        raceIndex >= univData.taikaibetujunibetukaisuu.length) {
      return const SizedBox.shrink(); // 無効なインデックスの場合は何も表示しない
    }

    // `juni_race`のインデックス範囲をチェック
    //final int juniorRaceLength = univData.juni_race[raceIndex].length;
    final int juniorRaceLength = 5;
    final int displayCount = 5; // 直近5回を表示

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            //fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        Wrap(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '出場${univData.taikaibetushutujoukaisuu[raceIndex]}回',
              style: TextStyle(color: HENSUU.textcolor),
            ),
            if (univData.taikaibetujunibetukaisuu[raceIndex][0] > 0)
              Text(
                ' 優勝${univData.taikaibetujunibetukaisuu[raceIndex][0]}回',
                style: TextStyle(color: HENSUU.textcolor),
              )
            else if (univData.taikaibetusaikoujuni[raceIndex] !=
                TEISUU.DEFAULTJUNI)
              Text(
                ' 最高${univData.taikaibetusaikoujuni[raceIndex] + 1}位',
                style: TextStyle(color: HENSUU.textcolor),
              ),
          ],
        ),
        Wrap(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('直近5回(右ほど最近): ', style: TextStyle(color: HENSUU.textcolor)),
            for (int i = 0; i < displayCount; i++)
              if ((juniorRaceLength - 1 - i) >= 0 &&
                  univData.juni_race[raceIndex][juniorRaceLength - 1 - i] !=
                      TEISUU.DEFAULTJUNI)
                Text(
                  '${univData.juni_race[raceIndex][juniorRaceLength - 1 - i] + 1}位 ',
                  style: TextStyle(color: HENSUU.textcolor),
                )
              else
                Text('無 ', style: TextStyle(color: HENSUU.textcolor)),
          ],
        ),
        TextButton(
          onPressed: () {
            // Navigator.push を使用して Senshu_R_Screen へ遷移
            Navigator.push(
              context,
              // MaterialPageRoute を使用して新しい画面を定義
              MaterialPageRoute(
                builder: (context) => ModalUnivDetailView(
                  univid: ghensuu.hyojiunivnum,
                  racebangou: raceIndex,
                ),
              ),
            );
          },
          child: Text(
            "直近10回成績",
            style: TextStyle(
              color: HENSUU.LinkColor,
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
              //fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ),

        const SizedBox(height: 16), // 各レースの間にスペース
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu ghensuu = ghensuuBox.get(
          'global_ghensuu',
          defaultValue: Ghensuu.initial(),
        )!;
        final KantokuData kantoku = _kantokuBox.get('KantokuData')!;
        final int currentUnivId = ghensuu.hyojiunivnum;

        final univDataBox = Hive.box<UnivData>('univBox');
        List<UnivData> sortedUnivData = univDataBox.values.toList();
        sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

        final Album album = _albumBox.get('AlbumData')!;

        String name_kantoku0 = "";
        int age_kantoku0 = 0;
        String name_kantoku1 = "";
        int age_kantoku1 = 0;
        String name_kantoku2 = "";
        int age_kantoku2 = 0;
        final allRetiredSenshu = _rsenshuBox.values.toList();
        // 取得した全ての選手データをループ処理します
        for (var rsenshu in allRetiredSenshu) {
          if (rsenshu.id == kantoku.rid[ghensuu.hyojiunivnum]) {
            name_kantoku0 = rsenshu.name;
            age_kantoku0 = ghensuu.year - rsenshu.sijiflag + 22;
          }
          if (rsenshu.id ==
              kantoku.rid[ghensuu.hyojiunivnum + TEISUU.UNIVSUU]) {
            name_kantoku1 = rsenshu.name;
            age_kantoku1 = ghensuu.year - rsenshu.sijiflag + 22;
          }
          if (rsenshu.id ==
              kantoku.rid[ghensuu.hyojiunivnum + TEISUU.UNIVSUU * 2]) {
            name_kantoku2 = rsenshu.name;
            age_kantoku2 = ghensuu.year - rsenshu.sijiflag + 22;
          }
        }

        // UnivDataがHiveに存在しない場合のデフォルト値
        final UnivData currentUnivData =
            _univBox.get(currentUnivId) ??
            UnivData(
              id: currentUnivId,
              r: 0, // 仮の値
              name: '不明な大学',
              name_tanshuku: '不明',
              meisei_total: 0,
              meisei_yeargoto: List.filled(TEISUU.MEISEIHOZONNENSUU, 0),
              meiseijuni: TEISUU.DEFAULTJUNI,
              ikuseiryoku: 0,
              mokuhyojuni: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
              inkarepoint: List.filled(3, 0),
              time_taikai_total: List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
              kukanjuni_taikai: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
              tuukajuni_taikai: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
              mokuhyojuniwositamawatteruflag: List.filled(
                TEISUU.SUU_MAXKUKANSUU,
                0,
              ),
              juni_race: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) =>
                    List.filled(TEISUU.KIROKUHOZONNENSUU, TEISUU.DEFAULTJUNI),
              ),
              time_race: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.filled(TEISUU.KIROKUHOZONNENSUU, 0.0),
              ),
              time_univtaikaikiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
              ),
              year_univtaikaikiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
              ),
              month_univtaikaikiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
              ),
              time_univkukankiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.generate(
                  TEISUU.SUU_MAXKUKANSUU,
                  (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
                ),
              ),
              year_univkukankiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.generate(
                  TEISUU.SUU_MAXKUKANSUU,
                  (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
                ),
              ),
              month_univkukankiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.generate(
                  TEISUU.SUU_MAXKUKANSUU,
                  (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
                ),
              ),
              name_univkukankiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.generate(
                  TEISUU.SUU_MAXKUKANSUU,
                  (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ''),
                ),
              ),
              gakunen_univkukankiroku: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.generate(
                  TEISUU.SUU_MAXKUKANSUU,
                  (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
                ),
              ),
              taikaientryflag: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
              taikaiseedflag: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
              taikaibetusaikoujuni: List.filled(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                TEISUU.DEFAULTJUNI,
              ),
              taikaibetushutujoukaisuu: List.filled(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                0,
              ),
              taikaibetujunibetukaisuu: List.generate(
                TEISUU.SUU_MAXRACESUU_1YEAR,
                (_) => List.filled(30, 0),
              ),
              time_univkojinkiroku: List.generate(
                TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
              ),
              year_univkojinkiroku: List.generate(
                TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
              ),
              month_univkojinkiroku: List.generate(
                TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
              ),
              name_univkojinkiroku: List.generate(
                TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ''),
              ),
              gakunen_univkojinkiroku: List.generate(
                TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
                (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
              ),
              chokuzentaikai_zentaitaikaisinflag: 0,
              chokuzentaikai_univtaikaisinflag: 0,
              sankankaisuu: 0,
            );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[900], // AppBarの背景色
            centerTitle: false, // leadingとtitleの配置を調整するためfalseに
            titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
            toolbarHeight: HENSUU.appbar_height, // 例: 高さを80ピクセルに増やす
            // 左側に2つの文字列を縦に並べる
            title: Padding(
              padding: const EdgeInsets.only(left: 16.0), // 左側に少し余白
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 縦方向の中央揃え
                crossAxisAlignment: CrossAxisAlignment.start, // 横方向の左揃え
                children: <Widget>[
                  Row(
                    children: [
                      Text(_getCombinedDifficultyText(kantoku, ghensuu)),

                      // 間隔を空けるためのSizedBox（もし必要なら）
                      SizedBox(width: 8), // 必要に応じて調整または削除
                      // 日付テキストをExpandedで囲み、省略表示を設定
                      Expanded(
                        child: Text(
                          '${ghensuu.year}年${ghensuu.month}月${_dayToString(ghensuu.day)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          maxLines: 1, // 1行に制限
                          overflow: TextOverflow.ellipsis, // はみ出す場合に"..."で省略
                        ),
                      ),
                    ],
                  ),
                  Row(
                    // 2行目のテキスト
                    children: [
                      Expanded(
                        // 追加: テキストが利用可能なスペースを占有し、省略表示を可能にする
                        child: Text(
                          "金${ghensuu.goldenballsuu} 銀${ghensuu.silverballsuu}", // 金と銀のテキストを結合
                          style: const TextStyle(color: HENSUU.textcolor),
                          maxLines: 1, // 追加: テキストを1行に制限
                          overflow:
                              TextOverflow.ellipsis, // 追加: 1行に収まらない場合に"..."で省略
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 右側にボタンを配置
            actions: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  // ここで gamenflag を 0 に変更し、保存する
                  ghensuu.gamenflag = 0;
                  await ghensuu.save();
                  // debugPrint('gamenflag が 0 に設定されました。'); // デバッグ用
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // ボタンの背景色
                  foregroundColor: Colors.black, // ボタンのテキスト色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 角丸
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ), // パディングを調整
                  minimumSize: Size.zero, // サイズが自動調整されるように最小サイズを0に
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // タップ領域をコンテンツに合わせる
                ),
                child: const Text(
                  "最新画面へ", // ボタンのテキスト
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ), // テキストスタイル
                ),
              ),
            ],
          ),
          backgroundColor: HENSUU.backgroundcolor,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 画面上部情報
                //const Divider(color: Colors.grey),

                // MARK: - 大学名と名声、三冠、シード権
                Text(
                  '${currentUnivData.name}大学',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '名声${currentUnivData.meisei_total} ${currentUnivData.meiseijuni + 1}位',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),

                // MARK: - レース履歴のScrollView
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // パネルを呼び出す（IDを渡すだけ）
                        buildUnivAnalysisPanel(ghensuu.hyojiunivnum),

                        if (ghensuu.hyojiunivnum == ghensuu.MYunivid)
                          Text(
                            '総監督: あなた',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (kantoku.rid[ghensuu.hyojiunivnum] > 0)
                          TextButton(
                            onPressed: () async {
                              album.yobiint3 =
                                  kantoku.rid[ghensuu.hyojiunivnum];
                              await album.save();
                              // Navigator.push を使用して Senshu_R_Screen へ遷移
                              await Navigator.push(
                                context,
                                // MaterialPageRoute を使用して新しい画面を定義
                                MaterialPageRoute(
                                  builder: (context) => const Senshu_R_Screen(),
                                ),
                              );
                              setState(() {
                                // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                              });
                            },
                            child: Text(
                              "監督: ${name_kantoku0} (${age_kantoku0}歳)",
                              style: TextStyle(
                                color: HENSUU.LinkColor,
                                //decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                          )
                        /*Text(
                            '監督 ${name_kantoku0}(${age_kantoku0}歳)',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          )*/
                        else
                          Text(
                            '監督 不在',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (kantoku.rid[ghensuu.hyojiunivnum + TEISUU.UNIVSUU] >
                            0)
                          TextButton(
                            onPressed: () async {
                              album.yobiint3 = kantoku
                                  .rid[ghensuu.hyojiunivnum + TEISUU.UNIVSUU];
                              await album.save();
                              // Navigator.push を使用して Senshu_R_Screen へ遷移
                              await Navigator.push(
                                context,
                                // MaterialPageRoute を使用して新しい画面を定義
                                MaterialPageRoute(
                                  builder: (context) => const Senshu_R_Screen(),
                                ),
                              );
                              setState(() {
                                // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                              });
                            },
                            child: Text(
                              "コーチ(トラック): ${name_kantoku1} (${age_kantoku1}歳)",
                              style: TextStyle(
                                color: HENSUU.LinkColor,
                                //decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                          )
                        /*Text(
                            'コーチA ${name_kantoku1}(${age_kantoku1}歳)',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          )*/
                        else
                          Text(
                            'コーチ(トラック) 不在',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (kantoku.rid[ghensuu.hyojiunivnum +
                                TEISUU.UNIVSUU * 2] >
                            0)
                          TextButton(
                            onPressed: () async {
                              album.yobiint3 =
                                  kantoku.rid[ghensuu.hyojiunivnum +
                                      TEISUU.UNIVSUU * 2];
                              await album.save();
                              // Navigator.push を使用して Senshu_R_Screen へ遷移
                              await Navigator.push(
                                context,
                                // MaterialPageRoute を使用して新しい画面を定義
                                MaterialPageRoute(
                                  builder: (context) => const Senshu_R_Screen(),
                                ),
                              );
                              setState(() {
                                // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                              });
                            },
                            child: Text(
                              "コーチ(長距離): ${name_kantoku2} (${age_kantoku2}歳)",
                              style: TextStyle(
                                color: HENSUU.LinkColor,
                                //decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                          )
                        /*Text(
                            'コーチB ${name_kantoku2}(${age_kantoku2}歳)',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          )*/
                        else
                          Text(
                            'コーチ(長距離) 不在\n',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (currentUnivData.sankankaisuu > 0)
                          Text(
                            '駅伝三冠 ${currentUnivData.sankankaisuu}回',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (currentUnivData.taikaiseedflag[1] == 1)
                          Text(
                            '11月駅伝シード権あり',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        if (currentUnivData.taikaiseedflag[2] == 1)
                          Text(
                            '正月駅伝シード権あり',
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel:
                                  '上位10名平均ランキング(AI分析付き)', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return ModalAverageTop10TimeRankingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "上位10名平均ランキング(AI分析付き)",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '所属選手レーダーチャート', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return SenshuRadarAnalysisView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "所属選手レーダーチャート",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () async {
                            await showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '所属選手練習メニュー一覧', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalTrainingListView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                            setState(() {
                              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                            });
                          },
                          child: Text(
                            "所属選手練習メニュー一覧",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () async {
                            await showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '大学の個性(実力発揮度)設定', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalUnivAbilitySettingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                            setState(() {
                              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                            });
                          },
                          child: Text(
                            "大学の個性(実力発揮度)設定",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () async {
                            await showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '実力発揮度全大学一斉変更', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalAllUnivAbilityBulkSettingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                            setState(() {
                              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
                            });
                          },
                          child: Text(
                            "実力発揮度全大学一斉変更",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '今季タイム一覧表', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return ModalUnivSenshuMatrixView(
                                      targetUnivId: ghensuu.hyojiunivnum,
                                    ); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "今季タイム一覧表",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '駅伝出場履歴一覧(選手ごと)', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return ModalEkidenHistoryMatrixView(
                                      targetUnivId: ghensuu.hyojiunivnum,
                                    ); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "駅伝出場履歴一覧(選手ごと)",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel:
                                  '駅伝出場履歴一覧(区間ごと)※卒業生は表示できません', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return ModalEkidenKukanHistoryMatrixView(
                                      targetUnivId: ghensuu.hyojiunivnum,
                                    ); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "駅伝出場履歴一覧(区間ごと)※卒業生は表示できません",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '学内ランキング(タイム)', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalUnivSenshuRankingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "学内ランキング(タイム)",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '学内ランキング(能力値)', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalUnivSenshuAbilityRankingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "学内ランキング(能力値)",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '全選手タイムランキング', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalAllUnivSenshuRankingView(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "全選手タイムランキング",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: '全大学名声一覧', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    // ここに表示したいモーダルのウィジェットを指定
                                    return const ModalMeiseiIchiran(); // const を追加
                                  },
                              transitionBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    // モーダル表示時のアニメーション (例: フェードイン)
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: child,
                                    );
                                  },
                            );
                          },
                          child: Text(
                            "全大学名声一覧",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRaceHistory('10月駅伝', currentUnivData, 0, ghensuu),
                        _buildRaceHistory('11月駅伝', currentUnivData, 1, ghensuu),
                        _buildRaceHistory('正月駅伝', currentUnivData, 2, ghensuu),
                        _buildRaceHistory(
                          '11月駅伝予選',
                          currentUnivData,
                          3,
                          ghensuu,
                        ),
                        _buildRaceHistory(
                          '正月駅伝予選',
                          currentUnivData,
                          4,
                          ghensuu,
                        ),
                        _buildRaceHistory(
                          '対校戦',
                          currentUnivData,
                          9,
                          ghensuu,
                        ), // インカレ総合
                        _buildRaceHistory(
                          sortedUnivData[0].name_tanshuku,
                          currentUnivData,
                          5,
                          ghensuu,
                        ),
                        const SizedBox(height: 32),
                        // リンクボタン
                        LinkButtons(context, ghensuu),

                        const SizedBox(height: 32), // スペースを確保
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.grey),

                // MARK: - 下部大学ナビゲーションボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _changeHyojiUnivNum(-1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            '前の大学',
                            //style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: _goToMyUniv,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            '自分の大学',
                            //style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _changeHyojiUnivNum(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            '次の大学',
                            //style: TextStyle(fontSize: HENSUU.fontsize_honbun),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 画面最下部のナビゲーションボタンは削除しました。
                const SizedBox(height: 30), // bottomNavigationBar の高さの分を確保
              ],
            ),
          ),
        );
      },
    );
  }

  // リンクボタンをWidgetに分離
  // currentGhensuu を引数として受け取るように変更
  Widget LinkButtons(BuildContext context, Ghensuu currentGhensuu) {
    return Column(
      children: [
        // ModalZenhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        //if (currentGhensuu.hyojiracebangou == 2)
        TextButton(
          onPressed: () async {
            await showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '大学名変更', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalUnivNameHenkou(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
            setState(() {
              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
            });
          },
          child: Text(
            "大学名変更",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        // ModalKouhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        //if (currentGhensuu.mode != 300 && currentGhensuu.mode != 350)
        if (!(currentGhensuu.month == 10 && currentGhensuu.day == 15) &&
            !(currentGhensuu.month == 6 && currentGhensuu.day == 15) &&
            !(currentGhensuu.month == 10 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 11 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 1 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 2 && currentGhensuu.day == 25) &&
            currentGhensuu.mode != 330)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '総監督をする大学を変更', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalKantokuUnivHenkou(); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // モーダル表示時のアニメーション (例: フェードイン)
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                        child: child,
                      );
                    },
              );
            },
            child: Text(
              "総監督をする大学を変更",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          )
        else // if文が成就しない場合（currentGhensuu.mode が 300 または 350 の場合）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // 適度な余白を追加
            child: Text(
              "(駅伝・駅伝予選の場面では総監督をする大学を変更できません)",
              style: TextStyle(
                color: HENSUU.textcolor, // テキストの色
                fontSize: HENSUU.fontsize_honbun, // フォントサイズ
              ),
              textAlign: TextAlign.center, // テキストを中央寄せ
            ),
          ),
        // ModalKukanshouView は currentGhensuu.hyojiracebangou が 2 以下の時だけ表示
        //if (currentGhensuu.hyojiracebangou <= 2)
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '選手の能力を見抜く総監督の能力をリセット', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalMieruNouryokuReset(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "選手の能力を見抜く総監督の能力をリセット",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        //if (currentGhensuu.hyojiracebangou <= 2)
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '全てリセットしてやり直す', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalAllReset(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "全てリセットしてやり直す",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '名声と育成力は維持しつつリセットしてやり直す', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalReset_IkuseiryokuMeiseiIji(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "名声と育成力は維持しつつリセットしてやり直す",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        //if (currentGhensuu.hyojiracebangou <= 2)
        TextButton(
          onPressed: () async {
            await showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '難易度「極」「天」設定', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalKiwameHosei(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
            setState(() {
              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
            });
          },
          child: Text(
            "難易度「極」「天」設定",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            await showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '難易度変更', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalNanidoHenkou(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
            setState(() {
              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
            });
          },
          child: Text(
            "難易度変更",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '難易度変更2', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalOndoHenkou(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "難易度変更2",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '育成力変更', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalIkuseiryokuHenkou(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "育成力変更",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '名声変更', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalMeiseiHenkou(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "名声変更",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '入学時名声影響度設定(全大学共通)', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalSpurtryokuseichousisuu3(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "入学時名声影響度設定(全大学共通)",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '目標順位決め方設定(COM大学共通)', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalSpurtryokuseichousisuu2(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "目標順位決め方設定(COM大学共通)",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        Text("(カスタム駅伝設定は説明書画面上部に移動しました)"),

        if (currentGhensuu.mode != 300 &&
            currentGhensuu.mode != 330 &&
            currentGhensuu.mode != 350)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '駅伝名声設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalEkidenFameSettings(); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // モーダル表示時のアニメーション (例: フェードイン)
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                        child: child,
                      );
                    },
              );
            },
            child: Text(
              "駅伝名声設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          )
        else // if文が成就しない場合（currentGhensuu.mode が 300 または 350 の場合）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // 適度な余白を追加
            child: Text(
              "(エントリー画面や指示画面では駅伝名声設定はできません)",
              style: TextStyle(
                color: HENSUU.textcolor, // テキストの色
                fontSize: HENSUU.fontsize_honbun, // フォントサイズ
              ),
              textAlign: TextAlign.center, // テキストを中央寄せ
            ),
          ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '留学生受け入れ設定', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalRyugakuseiNinzu(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "留学生受け入れ設定",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '学連選抜モチベーション設定', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalGakurenHosei(); // const を追加
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // モーダル表示時のアニメーション (例: フェードイン)
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    );
                  },
            );
          },
          child: Text(
            "学連選抜モチベーション設定",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),

        if (!(currentGhensuu.month == 10 && currentGhensuu.day == 15) &&
            !(currentGhensuu.month == 6 && currentGhensuu.day == 15) &&
            !(currentGhensuu.month == 10 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 11 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 1 && currentGhensuu.day == 5) &&
            !(currentGhensuu.month == 2 && currentGhensuu.day == 25) &&
            currentGhensuu.mode != 330)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '選手トレード', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const TradeScreen(); // const を追加
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                      // モーダル表示時のアニメーション (例: フェードイン)
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                        child: child,
                      );
                    },
              );
            },
            child: Text(
              "選手トレード",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          )
        else // if文が成就しない場合（currentGhensuu.mode が 300 または 350 の場合）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // 適度な余白を追加
            child: Text(
              "(駅伝・駅伝予選の場面では選手トレードはできません)",
              style: TextStyle(
                color: HENSUU.textcolor, // テキストの色
                fontSize: HENSUU.fontsize_honbun, // フォントサイズ
              ),
              textAlign: TextAlign.center, // テキストを中央寄せ
            ),
          ),

        TextButton(
          onPressed: () async {
            final Ghensuu currentGhensuu = _ghensuuBox.getAt(0)!;
            final Album album = _albumBox.get('AlbumData')!;
            final KantokuData kantoku = _kantokuBox.get('KantokuData')!;
            album.yobiint3 = 0;
            await album.save();
            // Navigator.push を使用して Senshu_R_Screen へ遷移
            await Navigator.push(
              context,
              // MaterialPageRoute を使用して新しい画面を定義
              MaterialPageRoute(builder: (context) => const Senshu_R_Screen()),
            );
            setState(() {
              // 必要に応じて、ここで最新のデータを再取得する処理などを記述
            });
          },
          child: Text(
            "アルバム表示",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigator.push を使用して Senshu_R_Screen へ遷移
            Navigator.push(
              context,
              // MaterialPageRoute を使用して新しい画面を定義
              MaterialPageRoute(
                builder: (context) => const RijiIchiranScreen(),
              ),
            );
          },
          child: Text(
            "箱庭長距離陸上競技連盟",
            style: TextStyle(
              color: HENSUU.LinkColor,
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
              //fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ),
        const SizedBox(height: 40),
        /*TextButton(
          onPressed: () async {
            // Navigator.push を使用して Senshu_R_Screen へ遷移
            await Navigator.push(
              context,
              // MaterialPageRoute を使用して新しい画面を定義
              MaterialPageRoute(builder: (context) => const SaveLoadScreen()),
            );
          },
          child: Text(
            "データセーブ・ロード",
            style: TextStyle(
              color: HENSUU.LinkColor,
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
              //fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ),*/
      ],
    );
  }
}
