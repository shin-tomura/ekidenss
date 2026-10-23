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
import 'package:ekiden/album.dart';
//import 'package:ekiden/save_load_screen.dart';
import 'package:ekiden/screens/Modal_kaisuu_juni.dart';
import 'package:ekiden/screens/Modal_rankingunivsenshu.dart';
import 'package:ekiden/screens/Modal_rankingunivsenshunouryoku.dart';
import 'package:ekiden/screens/Modal_rankingall.dart';
import 'package:ekiden/screens/Modal_daigakuKosei.dart'; // 大学の個性(大学ごとの設定をまとめた画面。1.9.1)
import 'package:ekiden/screens/Modal_TrainingList.dart';
import 'package:ekiden/screens/Modal_meiseiitiran.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';
import 'package:ekiden/screens/ModalAverageTop10TimeRankingView.dart';
import 'package:ekiden/screens/ModalChartSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';
import 'package:ekiden/screens/Modal_ChartHyojiHijyojiKirikae.dart'; // レーダーチャートのパネルの表示・非表示(2.0.3)
import 'package:ekiden/kansuu/meisei_rireki.dart'; // 名声の履歴(1.8.8)
import 'package:ekiden/kansuu/meisei_kotei.dart'
    show meiseiKotei; // 名声設定の画面の説明に、コンピュータの大学の名声を固定中であることを添える(2.1.1)
import 'package:ekiden/kansuu/ShokitiUnivdata.dart'
    show meiseiShokitiModosu, shokiMeiseiGoukei; // 名声設定の画面の「全大学の名声を初期値に戻す」(2.1.1)
import 'package:ekiden/kansuu/shiyou_text.dart'; // 留学生の入学の決まり(1.8.9)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show KijiHyou, univSandaiHyou, konkiKaisaiZumi; // 三大駅伝の成績の表(1.9.8)
import 'package:ekiden/screens/kiji_hyou_view.dart'; // 表の部品(1.9.8)
import 'package:ekiden/screens/kukan_haiti_button.dart'; // 今季タイム一覧表を開くボタン(1.9.9)
import 'package:ekiden/kansuu/kyouka_project.dart'
    show KyoukaProject, kyoukaProjectHyouji, kyoukaKikanMoji; // 強化プロジェクト(2.0.1)
import 'package:ekiden/kansuu/koukou.dart'
    show koukouIchiranMoji, koukouHyoujiJouhou, KoukouJouhou; // 監督の出身校(2.0.1。監督の母校パイプ)
import 'package:ekiden/screens/Modal_koukouMeikan.dart'
    show koukouPageHirakuBan; // 監督の出身校から高校名鑑の高校のページを開く(2.0.1)
import 'package:ekiden/kansuu/shushou.dart' show shushouIdUniv; // 主将(2.0.1)
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku, resetSaiKakunin; // リセット・ロード・QRで残るもの・変わるもの(2.0.3。全てリセットの確認の画面から)。もう一度確かめるダイアログ(2.0.4)
import 'package:ekiden/screens/Modal_reset_IkuseiryokuMeiseiIji.dart'
    show ModalReset_IkuseiryokuMeiseiIji; // 設定を残してやり直す方に切り替える(2.0.3)
import 'package:ekiden/screens/meisei_yokonarabi_settei.dart'
    show meiseiYokonarabiSetteiHiraku; // 名声の横並び設定を開く(2.0.3。入学時名声影響度設定の画面の案内から)
import 'package:ekiden/screens/setsumei_mado.dart'; // 主将・母校パイプの説明のリンク(2.0.1)
import 'package:ekiden/screens/Modal_kinginRireki.dart'; // 金銀の内訳(2.1.1)
import 'package:ekiden/kansuu/univ_rekidai.dart' show univTaikaiKirokuGyou; // 大会記録の1行(2.1.4)
import 'package:ekiden/screens/univ_rekidai_mado.dart' show univRekidaiHiraku; // この大学の歴代記録(2.1.4)
import 'package:ekiden/kansuu/mokuhyou_kimekata.dart'
    show
        mokuhyouKimekataKoujoushin,
        mokuhyouKimekataTaikousen,
        mokuhyouKimekataKoujoushinKa; // 目標順位決め方設定の値(2.0.1)
import 'package:ekiden/kansuu/kingin_kiroku.dart'
    show
        kinginIchiranHyou,
        kinginIchiranChuu,
        kinginNatsuNen,
        kinginNatsuMaeNendo,
        kinginNatsuHyou,
        kinginNatsuChuu,
        kinginNatsuNashi; // 金特訓・銀特訓の記録の一覧表(2.0.0)と、直近の夏合宿の分(2.1.3)
import 'package:ekiden/kansuu/fushime.dart'
    show gakunaiKirokuHajimeNendoKaku; // 学内記録を付け始めた年度(2.1.4)
import 'package:ekiden/kansuu/taikai_chouki.dart'
    show
        ChoukiKiroku,
        choukiYomu,
        choukiTsuusan,
        choukiNendo,
        choukiRaceList,
        choukiYuushou,
        choukiOufukuKaishi,
        ouroRace,
        fukuroRace; // 大会の長い記録(最後の優勝)と、正月駅伝の往路・復路(2.0.0)
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
                      "この設定は、所属大学の一員としての出場が叶わなかったために、どうしても所属大学の一員としての出場よりもモチベーションが低下するのではないか、との制作者の勝手な妄想から設けたものです。\n1区はこちらの世界でもテレビに映るのでモチベーションは低下しないと考え、1区以外の学連選抜の選手に対してモチベーション低下によるタイム悪化の補正を適用します。\n\n補正値が大きいほど、タイムの悪化幅が大きくなります。\n\n・補正なし: タイム悪化補正を適用しない\n・補正（小～大の10段階）: タイム悪化補正を適用する\n\n初期値は「補正なし」です。",
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
                    // 先頭に留学生の入学の決まりの説明を出す(説明書の「留学生」と同じ文。1.8.9)
                    // (一覧と一緒にスクロールするように、一覧の1行目にする)
                    itemCount: allUnivs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                ryuugakuseiSetteiSetsumeiText(),
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.grey),
                            ],
                          ),
                        );
                      }
                      final UnivData univ = allUnivs[index - 1];
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
  // (2.0.1から初期値を対校戦順位追従設定にした。向上心豊かを選んだときは94で保存し、
  //  2.0.0までの初期値のまま(93)と見分ける。mokuhyou_kimekata.dart)
  final List<Map<String, dynamic>> _options = const [
    {
      'value': mokuhyouKimekataKoujoushin,
      'label': '向上心豊か',
      'description': '目標設定の際に、前年の当該駅伝での成績をもとに、上位を目指す傾向があります。',
    },
    {
      'value': mokuhyouKimekataTaikousen,
      'label': '対校戦順位追従設定（初期値）',
      'description': '初期値設定です。\n当年の対校戦の順位を重視します。\n目標設定が現実的になります。',
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

        // 今の設定の値(向上心豊かの初期値のまま(93)は、画面で選んだ向上心豊か(94)と同じに見せる)
        final int genzaiAtai =
            mokuhyouKimekataKoujoushinKa(currentGhensuu.spurtryokuseichousisuu2)
            ? mokuhyouKimekataKoujoushin
            : currentGhensuu.spurtryokuseichousisuu2;

        // 現在の設定名を取得
        String currentLabel = _options.firstWhere(
          (option) => option['value'] == genzaiAtai,
          orElse: () => {'label': '不明な設定'},
        )['label'];

        // 現在の設定の説明を取得
        String currentDescription = _options.firstWhere(
          (option) => option['value'] == genzaiAtai,
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
                        // 名声の横並び(スカウトのとき)(2.0.2はここにあった「名声上位の横並び」。2.0.3から、
                        // 設定タブの「名声の横並び設定」の画面に独立させた。ここで覚えた人が迷わないように、
                        // 案内と開くボタンだけを残す。meisei_yokonarabi_settei.dart)
                        const SizedBox(height: 16),
                        Text(
                          '名声の横並び(スカウトのとき)は、設定タブの「名声の横並び設定」に移りました。'
                          'このレベルと組み合わせて効きます。',
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => meiseiYokonarabiSetteiHiraku(context),
                          child: const Text('名声の横並び設定を開く'),
                        ),
                        const SizedBox(height: 16),
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
                                            // 移った大学の学内記録を付け始めた年度を残す(2.1.4。KantokuData.yobiint4[79]。
                                            // 結果画面の一言と記事で、前の自己ベストが学内記録に載っていたかを見るのに使う。
                                            // kansuu/fushime.dart の gakunaiKirokuHajimeNendoKaku)
                                            if (i != currentGhensuu.MYunivid) {
                                              await gakunaiKirokuHajimeNendoKaku(currentGhensuu);
                                            }
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
                      //駅伝男と平常心は最初から見える能力なので、リセット後も見える状態に戻す
                      currentGhensuu.nouryokumieruflag[0] = 1;
                      currentGhensuu.nouryokumieruflag[1] = 1;
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

/// 「全てリセットしてやり直す」の確認の画面
/// ・はいを押すと mode を10にし、main.dart の _runMode0010Processing でリセットする
/// ・2.0.3から、名声・育成力と設定も初期値に戻す(何を戻すかは lib/kansuu/reset_ichiran.dart の一覧で決める)。
///   基本的には「名声・育成力と設定を残してやり直す」をおすすめし、本当に初期値に戻したいときだけ選んでもらう。
///   「設定を残してやり直す方にする」で、そちらの確認の画面に切り替えられる
/// ・2.0.4から、はいを押したあとに、もう一度確かめるダイアログを出す(reset_ichiran_gamen.dart の resetSaiKakunin)
class ModalAllReset extends StatefulWidget {
  const ModalAllReset({super.key});

  @override
  State<ModalAllReset> createState() => _ModalAllResetState();
}

class _ModalAllResetState extends State<ModalAllReset> {
  ButtonStyle _botan(Color iro, Color moji) => ElevatedButton.styleFrom(
    backgroundColor: iro,
    foregroundColor: moji,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(200, 48),
    padding: const EdgeInsets.all(12.0),
  );

  /// 「名声・育成力と設定を残してやり直す」の確認の画面に切り替える
  /// (その画面を閉じたら、この画面も閉じる。はいを押したときは、リセットの処理の画面に切り替わる)
  Future<void> _nokosuHouNi() async {
    await showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: '名声・育成力と設定を残してやり直す',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ModalReset_IkuseiryokuMeiseiIji();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    const String title = '全てリセットしてやり直す';

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(title, style: TextStyle(color: Colors.white)),
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

        const TextStyle honbun = TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        );
        const TextStyle botanMoji = TextStyle(
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        );
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(title, style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          // 文字を大きくしても、はみ出さずにスクロールできるようにする(2.0.3)
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    '名声・育成力と、すべての設定を初期値に戻して、1年目からやり直します'
                    '(表示の好み・大学名・メモ・カスタム駅伝の名前とコース・高校名鑑の編集は残ります)。'
                    'アルバムも消去されます。\n'
                    '設定を残したままやり直すなら「名声・育成力と設定を残してやり直す」がおすすめです。'
                    '本当に初期値に戻したいときだけ、こちらを選んでください。',
                    style: honbun,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // 残るもの・戻るものの一覧(reset_ichiran_gamen.dart)
                  TextButton(
                    onPressed: () => resetIchiranGamenHiraku(context),
                    child: const Text(
                      '残るもの・戻るものの一覧',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 255, 0),
                        decoration: TextDecoration.underline,
                        decorationColor: HENSUU.textcolor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // おすすめのほう(設定を残す)に切り替える
                  ElevatedButton(
                    onPressed: _nokosuHouNi,
                    style: _botan(Colors.green, Colors.black),
                    child: const Text('設定を残してやり直す方にする', style: botanMoji),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('本当に全て初期値に戻してやり直しますか？', style: honbun, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // もう一度確かめる(2.0.4。やめたら、この画面に戻る)
                      if (!await resetSaiKakunin(context, zenbu: true)) return;
                      if (!context.mounted) return;
                      setState(() {
                        currentGhensuu.mode = 10;
                      });
                      await currentGhensuu.save(); // Hiveに保存
                      if (context.mounted) Navigator.pop(context); // モーダルを閉じる
                    },
                    style: _botan(Colors.orange.shade300, Colors.black),
                    child: const Text('はい、全て初期値に戻してやり直す', style: botanMoji),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // モーダルを閉じる
                    },
                    style: _botan(Colors.green, Colors.black),
                    child: const Text('いいえ、やっぱりリセットしません。', style: botanMoji),
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

  // 画面を開いたときの名声(大学idごと)。閉じるときに比べ、変わった大学だけ名声の履歴に
  // 「名声を編集」を1行書く(2.1.1。スライダーで変えたときも書く。何度変えても1大学1行で、
  // 値が同じなら書かない。2.1.0までは、数字の欄から離れるたびに書き(値が同じでも)、スライダーでは書いていなかった)
  final Map<int, int> _hirakuMaeMeisei = {};
  // 画面を開いたときの年ごとの名声(大学idごと)。閉じるときに名声が開いたときと同じ値に戻っていれば、
  // 年ごとの名声もこの形に戻す(動かしてから元の値に戻したときに、内訳が均等に崩れないように。2.1.1)
  final Map<int, List<int>> _hirakuMaeNengoto = {};
  // 閉じるときの処理を始めたか(戻るボタンと端末の戻るの両方から呼ばれても1回だけにする。2.1.1)
  bool _tojiruShoriZumi = false;
  // 昨年度に全大学が得た名声の合計(説明に出す。記録がなければnull。開いているあいだは変わらない。2.1.1)
  int? _sakunendoGoukei;
  // コンピュータの大学の名声を固定しているか(説明に1行添える。2.1.1)
  bool _kotei = false;
  // 「全大学の名声を初期値に戻す」で戻した大学(大学id)。閉じるときに、名声の履歴に「名声を初期値に戻した」と書く
  // (戻したあとに数字やスライダーで変えた大学は外し、今まで通り「名声を編集」と書く。2.1.1)
  final Set<int> _shokitiModoshita = {};

  @override
  void initState() {
    super.initState();
    _univBox = Hive.box<UnivData>('univBox');
    for (final UnivData u in _univBox.values) {
      _hirakuMaeMeisei[u.id] = u.meisei_total;
      _hirakuMaeNengoto[u.id] = List<int>.of(u.meisei_yeargoto);
    }
    _sakunendoGoukei = meiseiRirekiZenUnivGoukei(1);
    _kotei = meiseiKotei(
      Hive.box<KantokuData>('kantokuBox').get('KantokuData'),
    );
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
    // 今の名声と同じなら、年ごとの名声を作り直さない(欄やスライダーを触っただけで、
    // 内訳が10年に均等に崩れないように。2.1.1。2.1.0までは、同じ値でも作り直していた)
    if (newMeiseiTotal == univ.meisei_total) return;
    // 初期値に戻したあとに変えたときは、「名声を編集」として書く(2.1.1)
    _shokitiModoshita.remove(univ.id);
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
        // 名声の履歴の「名声を編集」は、閉じるときにまとめて書く(_tojiruShori。2.1.1)
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

  /// 閉じるときの処理。名声の順位を付け直し、名声が変わった大学ごとに、名声の履歴に「名声を編集」を書く
  /// (年ごとの名声を作り直すので、内訳と合わなくなるため。1.8.8。2.1.1から、閉じるときにまとめて書く)。
  /// 戻るボタンと端末の戻るの両方から呼ぶので、1回だけ行い、行ったときはtrueを返す
  /// (2回目からはfalse。続けて押されても2回閉じないように)
  Future<bool> _tojiruShori() async {
    if (_tojiruShoriZumi) return false;
    _tojiruShoriZumi = true;
    FocusScope.of(context).unfocus();
    await _updateMeiseiRanking();
    final List<UnivData> univs = _univBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final UnivData u in univs) {
      final int? mae = _hirakuMaeMeisei[u.id];
      if (mae == null) continue;
      final List<int>? maeNengoto = _hirakuMaeNengoto[u.id];
      // 「全大学の名声を初期値に戻す」で戻した大学か(2.1.1)
      final bool modoshita = _shokitiModoshita.contains(u.id);
      if (mae == u.meisei_total && !modoshita) {
        // 開いたときと同じ値に戻っていれば、年ごとの名声も開いたときの形に戻し、履歴には書かない(2.1.1)
        if (maeNengoto != null &&
            !_onajiNengoto(maeNengoto, u.meisei_yeargoto)) {
          u.meisei_yeargoto = List<int>.of(maeNengoto);
          await u.save();
        }
        continue;
      }
      // 初期値に戻しても、年ごとの名声が開いたときと同じなら(もともと初期値のまま)、履歴には書かない(2.1.1)
      if (modoshita &&
          maeNengoto != null &&
          _onajiNengoto(maeNengoto, u.meisei_yeargoto)) {
        continue;
      }
      await meiseiRirekiTsuika(
        u.id,
        modoshita
            ? '名声を初期値に戻した(10年分の合計を${u.meisei_total}にした)'
            : '名声を編集(10年分の合計を${u.meisei_total}にした)',
        0,
      );
    }
    return true;
  }

  /// 全大学の名声を初期値に戻す(確かめてから。2.1.1)
  /// ・過去9年分を新しいゲームの値にし、今年度に得た名声は残す(ShokitiUnivdata.dart の meiseiShokitiModosu)
  /// ・1年あたりは最低1なので、どの大学も合計は9以上になる(名声で割る計算が0にならない)
  /// ・すぐに保存し、名声の順位と名声の履歴は、閉じるときにまとめて直す(_tojiruShori)
  Future<void> _shokitiModosu() async {
    FocusScope.of(context).unfocus();
    final List<UnivData> univs = _univBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (univs.isEmpty) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        // 文字を大きくしても、本文をスクロールで読めるようにする
        scrollable: true,
        title: const Text(
          '名声を初期値に戻しますか',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '全大学の過去9年分の名声を、新しいゲームを始めたときの値に戻します。\n'
          '大学を選ぶ画面の並びで、一番上の大学が${shokiMeiseiGoukei(univs.first.id)}、'
          '一番下の大学が${shokiMeiseiGoukei(univs.last.id)}です。\n'
          '今年度に得た名声は、そのまま残ります。',
          style: const TextStyle(
            color: HENSUU.textcolor,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('やめる', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(
              '戻す',
              style: TextStyle(
                color: Colors.orange.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    for (final UnivData u in univs) {
      meiseiShokitiModosu(u);
      await u.save();
      _shokitiModoshita.add(u.id);
      // 数字の欄も戻した値にする(欄はHiveのキーで持っている)
      _controllers[u.key as int]?.text = '${u.meisei_total}';
    }
    if (mounted) setState(() {});
  }

  /// 年ごとの名声が同じか(2.1.1)
  bool _onajiNengoto(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    return await _tojiruShori();
  }

  /// 上の説明の文(2.1.1から、決まった名声の量(年間獲得総名声12060など)をやめ、このデータの昨年度の実績を出す。
  /// 決まった量は、全大学が目標1位のときの総合順位の名声だけで、目標順位で割る分・区間賞・倍率などを入れていなかったため)
  String _setsumeiBun(int currentMaxMeisei, int univSuu) {
    final List<String> bun = [
      '名声を${minMeisei}から${currentMaxMeisei}の間で設定できます。',
      '名声は、各大学が過去10年に得た名声の合計です。',
    ];
    final int? goukei = _sakunendoGoukei;
    if (goukei == null || univSuu <= 0) {
      bun.add('昨年度の記録はまだありません。');
    } else {
      bun.add(
        'このデータの昨年度、全大学が得た名声は${goukei}でした(1大学あたり${(goukei / univSuu).round()})。',
      );
    }
    if (_kotei) {
      bun.add('コンピュータの大学の名声は固定中です(駅伝などで得ても合計は変わりません)。');
    }
    bun.add('駅伝などで得られる名声の量は、説明書の「名声」に一覧があります。');
    bun.add(
      'また、戻った直後の画面上では名声変更が反映されていないですが、一回自分の大学ボタンをタップしていただければ画面に反映されます。（気にならなければいちいちタップする必要もありません。）',
    );
    return bun.join('\n');
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
          // 今の名声の1位と最下位(平均名声の下に小さく出す。2.1.1)
          final int ichiiMeisei = allUnivs
              .map((e) => e.meisei_total)
              .reduce(max);
          final int saikaiMeisei = allUnivs
              .map((e) => e.meisei_total)
              .reduce(min);
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
                    // 今の名声の1位と最下位(2.1.1)
                    Text(
                      "(1位 $ichiiMeisei・${allUnivs.length}位 $saikaiMeisei)",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun - 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // 全大学の名声を初期値に戻す(2.1.1。1行に1つだけ置き、文字を大きくしても折り返す)
                    TextButton(
                      onPressed: _shokitiModosu,
                      child: const Text(
                        '全大学の名声を初期値に戻す',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 255, 0),
                          decoration: TextDecoration.underline,
                          decorationColor: HENSUU.textcolor,
                        ),
                      ),
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
                                    // 2.1.1から、昨年度の実績などを出す(_setsumeiBun)
                                    _setsumeiBun(
                                      currentMaxMeisei,
                                      allUnivs.length,
                                    ),
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
                        // 名声の順位の付け直しと、名声の履歴の「名声を編集」(2.1.1。続けて押されたときは何もしない)
                        if (!await _tojiruShori()) return;
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
  late Box<SenshuData> _senshuBox; // 金特訓・銀特訓の記録の一覧表で使う(2.0.0)
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
    // 正月駅伝の往路・復路の欄か(2.0.0)
    final bool oufuku = raceIndex == ouroRace || raceIndex == fukuroRace;

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            //fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // 往路・復路は2.0.0から記録している(それより前から遊んでいるデータは、記録を始めた年度を添える)
        if (oufuku && choukiOufukuKaishi(univData) > 1)
          Text(
            '(${choukiOufukuKaishi(univData)}年度から記録)',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),

        Wrap(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 往路・復路の出場回数は正月駅伝と同じなので出さない(2.0.0)
            if (!oufuku)
              Text(
                '出場${univData.taikaibetushutujoukaisuu[raceIndex]}回',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            if (univData.taikaibetujunibetukaisuu[raceIndex][0] > 0)
              Text(
                '${oufuku ? '' : ' '}優勝${univData.taikaibetujunibetukaisuu[raceIndex][0]}回',
                style: TextStyle(color: HENSUU.textcolor),
              )
            else if (univData.taikaibetusaikoujuni[raceIndex] !=
                TEISUU.DEFAULTJUNI)
              Text(
                '${oufuku ? '' : ' '}最高${univData.taikaibetusaikoujuni[raceIndex] + 1}位',
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
        // 最後の優勝(直近5回の欄に優勝がないときだけ。2.0.0)
        _buildSaigoNoYuushou(univData, raceIndex, ghensuu),
        // 一番良い総合記録(全体の歴代10位以内ならその順位、なければ学内記録か直近10回の最高。2.1.4。
        // 駅伝と往路・復路だけ。kansuu/univ_rekidai.dart)
        _buildTaikaiKiroku(univData, raceIndex, ghensuu),
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

  // 一番良い総合記録の行(2.1.4。出せなければ何も出さない。kansuu/univ_rekidai.dart)
  Widget _buildTaikaiKiroku(UnivData univData, int raceIndex, Ghensuu ghensuu) {
    final String? text = univTaikaiKirokuGyou(ghensuu, univData, raceIndex);
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: HENSUU.textcolor),
    );
  }

  // 最後の優勝の行(2.0.0。大会の長い記録 taikai_chouki.dart)
  // 優勝を覚えている大会(三大駅伝・カスタム駅伝・対校戦)で、一度でも優勝していて、
  // 直近5回の欄に優勝がないときだけ「最後の優勝 3年度(102年前)」と出す。
  // 今までのセーブデータで、直近10回より前に優勝していて年度が分からないときは「○年度以前」と出す
  Widget _buildSaigoNoYuushou(UnivData univData, int raceIndex, Ghensuu ghensuu) {
    if (!choukiRaceList.contains(raceIndex) ||
        univData.juni_race.length <= raceIndex ||
        choukiTsuusan(univData, raceIndex, choukiYuushou) <= 0) {
      return const SizedBox.shrink();
    }
    final List<int> juni = univData.juni_race[raceIndex];
    for (int i = 0; i < 5 && i < juni.length; i++) {
      if (juni[i] == 0) return const SizedBox.shrink();
    }
    final ChoukiKiroku? c = choukiYomu(univData, raceIndex, choukiYuushou);
    if (c == null) return const SizedBox.shrink();
    final int ima = choukiNendo(ghensuu);
    final String text;
    if (c.saigo > 0) {
      text = '最後の優勝 ${c.saigo}年度(${ima - c.saigo}年前)';
    } else if (c.mae > 0) {
      text = '最後の優勝 ${c.mae}年度以前(${ima - c.mae}年以上前)';
    } else {
      return const SizedBox.shrink();
    }
    return Text(text, style: const TextStyle(color: HENSUU.textcolor));
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
        // 監督の出身校(2.0.1。監督の母校パイプ。高校の情報を表示しない設定のときと、分からないときは空)
        String koukou_kantoku0 = "";
        // 監督の出身校の名簿の番号(押すと高校名鑑のその高校のページを開く。分からなければ-1。2.0.1)
        int koukouBan_kantoku0 = -1;
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
            koukou_kantoku0 = koukouIchiranMoji(
              rsenshu.samusataisei,
              rsenshu.hirou,
              kantoku,
            );
            final KoukouJouhou? kj = koukouHyoujiJouhou(
              rsenshu.samusataisei,
              rsenshu.hirou,
              kantoku,
            );
            koukouBan_kantoku0 = kj == null ? -1 : kj.koukou - 1;
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

        // 三大駅伝の成績の表(今季と過去5季。今季の大会がもう開かれたかは選手の記録で見る。1.9.8)
        final KijiHyou univHyou = univSandaiHyou(
          currentUnivData,
          sortedUnivData,
          konkiKaisaiZumi(Hive.box<SenshuData>('senshuBox').values),
          ghensuu.year,
          ghensuu.month,
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
                // 強化プロジェクト中の大学(2.0.1。kyouka_project.dart。2.0.2から、強化されるスカウトが
                // 残っている間だけ出し、期間は「8年3月のスカウトまで」と書く)
                if (_kyoukaKikan(kantoku, ghensuu, currentUnivData.id) != null)
                  Text(
                    '強化プロジェクト中(${_kyoukaKikan(kantoku, ghensuu, currentUnivData.id)})',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                    textAlign: TextAlign.center,
                  ),

                // MARK: - レース履歴のScrollView
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // パネルを呼び出す（IDを渡すだけ）
                        // 2.0.3から、選手画面と同じく表示・非表示を切り替えられる(yobiint2[20]の2の位)
                        if (chartPanelHyouji(kantoku, daigaku: true))
                          buildUnivAnalysisPanel(ghensuu.hyojiunivnum),
                        TextButton(
                          onPressed: () async {
                            await showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(
                                0.8,
                              ), // モーダルの背景色
                              barrierDismissible: true, // 背景タップで閉じられるようにする
                              barrierLabel: 'パネル表示非表示切替', // アクセシビリティ用ラベル
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ), // アニメーション時間
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                    return const AnalysisPanelConfigScreen(
                                      daigaku: true,
                                    );
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
                            if (mounted) setState(() {});
                          },
                          child: Text(
                            "パネル表示非表示切替",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),

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
                              "監督: ${name_kantoku0} (${age_kantoku0}歳${_shingenShirushi(kantoku, ghensuu, ghensuu.hyojiunivnum)})",
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
                        // 監督の出身校(2.0.1。監督の母校パイプ。ボタンの文に足さず、別の行にする)。
                        // 押すと高校名鑑のその高校のページを開く(名簿の番号が分からなければ普通の文字)
                        if (kantoku.rid[ghensuu.hyojiunivnum] > 0 &&
                            koukou_kantoku0.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: koukouBan_kantoku0 >= 0
                                ? TextButton(
                                    onPressed: () async {
                                      await koukouPageHirakuBan(
                                        context,
                                        koukouBan_kantoku0,
                                      );
                                      // 高校名鑑で高校名を変えたときに反映する
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                    child: Text(
                                      '監督の出身校: $koukou_kantoku0',
                                      style: TextStyle(
                                        color: HENSUU.LinkColor,
                                        fontSize: HENSUU.fontsize_honbun - 2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Text(
                                    '監督の出身校: $koukou_kantoku0',
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontSize: HENSUU.fontsize_honbun - 2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        // 「母校パイプとは」のリンク(監督がいないときや、出身校を出さない設定のときも出す。
                        // 1行に1つのリンクにして、監督の名前や出身校のリンクと押し間違えないようにする)
                        const BokouPipeSetsumeiLink(
                          fontSize: HENSUU.fontsize_honbun - 2,
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
                              "コーチ(トラック): ${name_kantoku1} (${age_kantoku1}歳${_shingenShirushi(kantoku, ghensuu, ghensuu.hyojiunivnum + TEISUU.UNIVSUU)})",
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
                              "コーチ(長距離): ${name_kantoku2} (${age_kantoku2}歳${_shingenShirushi(kantoku, ghensuu, ghensuu.hyojiunivnum + TEISUU.UNIVSUU * 2)})",
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
                        // 主将(2.0.1。shushou.dart)。そばに「主将とは」のリンクを置く
                        // (文字を大きくしても、はみ出さずに次の行へ回るように Wrap にする)
                        if (_shushouMoji(kantoku, ghensuu, ghensuu.hyojiunivnum)
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  _shushouMoji(
                                    kantoku,
                                    ghensuu,
                                    ghensuu.hyojiunivnum,
                                  ),
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const ShushouSetsumeiLink(),
                              ],
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
                        // 今季タイム一覧表(1.9.9。よく使うので、目立つボタンにしてリンクの列の一番上に置いた。kukan_haiti_button.dart)
                        KakuninButtons(targetUnivid: ghensuu.hyojiunivnum, kukanHaiti: false),
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
                        // 金銀の内訳(2.1.1。表示している大学の分。Modal_kinginRireki.dart)
                        // (上の「金○ 銀○」はヘッダーの中で横に余裕がないので、リンクの列に1行で置く)
                        TextButton(
                          onPressed: () => kinginRirekiHiraku(context, currentUnivData.id),
                          child: const Text(
                            "金銀の内訳",
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        // 全体の歴代10位以内に入っている、この大学の区間記録と個人記録(2.1.4。univ_rekidai_mado.dart)
                        TextButton(
                          onPressed: () => univRekidaiHiraku(context, currentUnivData),
                          child: const Text(
                            "この大学の歴代記録",
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 255, 0),
                              decoration: TextDecoration.underline,
                              decorationColor: HENSUU.textcolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 三大駅伝の成績の表(1.9.8)
                        KijiHyouView(univHyou, ue: 0),
                        const SizedBox(height: 16),
                        _buildRaceHistory('10月駅伝', currentUnivData, 0, ghensuu),
                        _buildRaceHistory('11月駅伝', currentUnivData, 1, ghensuu),
                        _buildRaceHistory('正月駅伝', currentUnivData, 2, ghensuu),
                        // 正月駅伝の往路(1〜5区)・復路(6〜10区)(2.0.0。kansuu/oufuku_kiroku.dart)
                        _buildRaceHistory(
                          '正月駅伝 往路',
                          currentUnivData,
                          ouroRace,
                          ghensuu,
                        ),
                        _buildRaceHistory(
                          '正月駅伝 復路',
                          currentUnivData,
                          fukuroRace,
                          ghensuu,
                        ),
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
                        // 金特訓・銀特訓の記録の一覧表(邪魔にならないように一番下に置く。2.0.0)
                        _buildKinginIchiran(ghensuu),

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
        // ボタンは、表示している大学だけの設定を残す(1.9.8。全大学の一覧で変える設定・総監督と難易度・
        // 選手トレードとやり直し・見るものは、説明画面の設定タブに移した)
        _linkMidashi('この大学の設定'),
        // この大学の設定をまとめた画面(走りの特徴・育て方・スカウト・レース・留学生。1.9.1)
        TextButton(
          onPressed: () async {
            await showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '大学の個性', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                return const ModalDaigakuKosei();
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
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
              // 大学の切り替えや設定の変更を反映する
            });
          },
          child: Text(
            "大学の個性",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
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
        // 全大学共通の設定は、説明画面の設定タブにある(1.9.1で駅伝名声設定など、1.9.8で全大学の一覧で
        // 変える設定・総監督と難易度・選手トレードとやり直し・新入生の進学先などを移した)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "(全大学の一覧で変える設定、難易度、選手トレードとやり直し、新入生の進学先などは、説明画面の設定タブにあります)",
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
            ),
            textAlign: TextAlign.center,
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

  // 金特訓・銀特訓の記録の一覧表(2.0.0。kingin_kiroku.dart)
  // 夏合宿の日の結果画面と同じ表を、表示している大学の選手で出す(コンピュータの大学が使った金銀も記録している)。
  // 記録のある選手がいなければ、1行だけ出す
  // そのすぐ上に、直近の夏合宿の分だけの表を出す(2.1.3。kinginNatsuHyou。通算の記録がないときは出さない)
  Widget _buildKinginIchiran(Ghensuu ghensuu) {
    const TextStyle chuuStyle = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    final int univid = ghensuu.hyojiunivnum;
    final List<SenshuData> univSenshu = _senshuBox.values
        .where((s) => s.univid == univid)
        .toList();
    final KijiHyou? hyou = kinginIchiranHyou(univSenshu);
    // 直近の夏合宿(2.1.3)
    final int natsuNen = kinginNatsuNen(
      year: ghensuu.year,
      month: ghensuu.month,
      day: ghensuu.day,
    );
    final bool natsuMaeNendo = kinginNatsuMaeNendo(
      month: ghensuu.month,
      day: ghensuu.day,
    );
    final KijiHyou? natsuHyou = hyou == null
        ? null
        : kinginNatsuHyou(
            univSenshu,
            nen: natsuNen,
            maeNendo: natsuMaeNendo,
          );
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hyou == null)
            const Text('金特訓・銀特訓の記録はまだありません。', style: chuuStyle)
          else ...[
            // 直近の夏合宿の分(2.1.3)
            if (natsuHyou == null)
              Text(
                kinginNatsuNashi(nen: natsuNen, maeNendo: natsuMaeNendo),
                style: chuuStyle,
              )
            else ...[
              KijiHyouView(natsuHyou, ue: 0),
              const SizedBox(height: 6),
              Text(
                kinginNatsuChuu(nen: natsuNen, maeNendo: natsuMaeNendo),
                style: chuuStyle,
              ),
            ],
            const SizedBox(height: 16),
            // 通算の分
            KijiHyouView(hyou, ue: 0),
            const SizedBox(height: 6),
            Text(
              kinginIchiranChuu(jibun: univid == ghensuu.MYunivid),
              style: chuuStyle,
            ),
          ],
        ],
      ),
    );
  }

  // 大学画面の下のほうのボタンの見出し(1.9.1)
  Widget _linkMidashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 4.0),
      child: Text(
        "■$text",
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 監督・コーチの席[seki](KantokuData.rid の添字)が、あなたの大学の進言で決めた席なら「・進言」(2.0.1)
/// (進言の印は KantokuData.yobiint0。年度替わりでも代わらない席。ほかの大学には印の仕組みがないので出さない)
String _shingenShirushi(KantokuData kantoku, Ghensuu gh, int seki) {
  if (gh.hyojiunivnum != gh.MYunivid) return '';
  if (seki < 0 || seki >= kantoku.yobiint0.length) return '';
  return kantoku.yobiint0[seki] == 1 ? '・進言' : '';
}

/// 大学[univid]の主将の文(「主将: ○○(4年)」。いなければ空。2.0.1。shushou.dart)
String _shushouMoji(KantokuData kantoku, Ghensuu gh, int univid) {
  final Iterable<SenshuData> senshu = Hive.box<SenshuData>('senshuBox').values;
  final int? id = shushouIdUniv(kantoku, gh, senshu, univid);
  if (id == null) return '';
  for (final SenshuData s in senshu) {
    if (s.id == id) return '主将: ${s.name}(${s.gakunen}年)';
  }
  return '';
}

/// 大学[univid]が強化プロジェクト中なら、期間の文(「8年3月のスカウトまで」。でなければnull。2.0.1。
/// kyouka_project.dart。2.0.2から、最後のスカウトが終わったら出さない)
String? _kyoukaKikan(KantokuData kantoku, Ghensuu gh, int univid) {
  final KyoukaProject? p = kyoukaProjectHyouji(kantoku, gh);
  if (p == null || p.univid != univid) return null;
  return kyoukaKikanMoji(p, gh);
}
