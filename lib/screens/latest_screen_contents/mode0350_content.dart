import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // TEISUU, HENSUU
import 'package:ekiden/kansuu/time_date.dart'; // KANSUU
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/screens/Modal_kukanentry.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_kukanresult350.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_TodayChangeList.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_siji.dart';
import 'package:ekiden/screens/Modal_mokuhyojuni.dart';
import 'package:ekiden/screens/Modal_GakurenKukan.dart';
import 'package:ekiden/screens/Modal_tuukajunisuii.dart';
import 'package:ekiden/screens/Modal_timesasuii.dart';
import 'package:ekiden/screens/Modal_senshu_race_bunseki.dart';

String _getCombinedDifficultyText(KantokuData kantoku, Ghensuu currentGhensuu) {
  // 難易度モードを取得 (0:通常, 1:極, 2:天)
  final int mode = kantoku.yobiint2[0];
  // 基本難易度を取得 (0:鬼, 1:難, 2:普, 3:易)
  final int baseDifficulty = currentGhensuu.kazeflag;
  /*if (kantoku.yobiint2[17] == 1) {
    return "箱";
  }*/
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

String _formatDoubleToFixed(double value, int fractionDigits) {
  return value.toStringAsFixed(fractionDigits);
}

class Mode0350Content extends StatefulWidget {
  final VoidCallback? onAdvanceMode; // 親画面へのモード遷移コールバック

  const Mode0350Content({Key? key, this.onAdvanceMode}) : super(key: key);

  @override
  State<Mode0350Content> createState() => _Mode0350ContentState();
}

class _Mode0350ContentState extends State<Mode0350Content> {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;
  late Box<Shuudansou> _shuudansouBox;

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
  }

  // Swiftの @Query private var gh: [Ghensuu] に相当
  Ghensuu? get gh => _ghensuuBox.isNotEmpty ? _ghensuuBox.getAt(0) : null;
  Shuudansou? get shuudansou =>
      _shuudansouBox.isNotEmpty ? _shuudansouBox.getAt(0) : null;

  // Swiftの @Query private var senshudata: [SenshuData] に相当
  List<SenshuData> get senshudata => _senshuBox.values.toList();

  // Swiftの @Query private var univdata: [UnivData] に相当
  List<UnivData> get univdata => _univBox.values.toList();

  // データのindexとidは一致していない問題なので
  List<SenshuData> get idjunsenshudata =>
      senshudata.toList()..sort((a, b) => a.id.compareTo(b.id));

  // データのindexとidは一致していない問題なので
  List<UnivData> get idjununivdata =>
      univdata.toList()..sort((a, b) => a.id.compareTo(b.id));

  // unividが特定のものだけ抽出
  List<SenshuData> get univfilteredsenshudata {
    if (gh == null) return [];
    return senshudata.where((s) => s.univid == gh!.MYunivid).toList();
  }

  List<SenshuData> get gakunenjununivfilteredsenshudata =>
      univfilteredsenshudata.toList()..sort((a, b) {
        if (gh!.hyojiracebangou == 4) {
          // まずハーフのもちタイム順で比較します。
          /*final timeComparison = a.time_bestkiroku[2].compareTo(
            b.time_bestkiroku[2],
          );*/
          final timeComparison = shuudansou!.sisoutime[a.id].compareTo(
            shuudansou!.sisoutime[b.id],
          );
          if (timeComparison != 0) {
            return timeComparison;
          }
          // 同じ場合は、idを昇順で比較します。
          return a.id.compareTo(b.id);
        } else {
          // まず学年（gakunen）を降順で比較します。
          final gakunenComparison = b.gakunen.compareTo(a.gakunen);
          if (gakunenComparison != 0) {
            return gakunenComparison;
          }
          // 学年が同じ場合は、idを昇順で比較します。
          return a.id.compareTo(b.id);
        }
      });

  // 選手詳細モーダルを呼び出す共通関数
  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '選手詳細',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            // ModalSenshuDetailViewはimportされていると仮定
            // ignore: unnecessary_cast
            return (ModalSenshuDetailView(senshuId: senshu.id)) as Widget;
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
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
        '選手詳細',
        style: TextStyle(
          color: HENSUU.LinkColor, // リンクカラーを維持
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final currentGhensuu = ghensuuBox.getAt(0); // gh[0]に相当
        if (currentGhensuu == null) {
          return Center(
            child: Text('データがありません', style: TextStyle(color: HENSUU.textcolor)),
          );
        }
        /*print(
          'currentGhensuu.hyojiracebangou: ${currentGhensuu.hyojiracebangou}',
        );
        print(
          'currentGhensuu.nowracecalckukan: ${currentGhensuu.nowracecalckukan}',
        );*/
        // `hyojijunbi`を一度だけ呼び出すために`FutureBuilder`または`initState`内で`WidgetsBinding.instance.addPostFrameCallback`を使用
        // SwiftUIの.task {} に相当
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _hyojijunbi(currentGhensuu);
        });

        // Swiftのvar nowracekukanfilteredsenshudata: [SenshuData] { ... } に相当
        List<SenshuData> nowracekukanfilteredsenshudata = idjunsenshudata
            .where(
              (s) =>
                  s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                      1] ==
                  currentGhensuu.nowracecalckukan,
            )
            .toList();

        // Swiftのvar timejununivdata: [UnivData] { ... } に相当
        int temp_nowracecalckukan = 0;
        if (currentGhensuu.nowracecalckukan > 0) {
          temp_nowracecalckukan = currentGhensuu.nowracecalckukan;
        } else {
          temp_nowracecalckukan = 1;
        }
        List<UnivData> timejununivdata = idjununivdata.toList()
          ..sort(
            (a, b) => a.time_taikai_total[temp_nowracecalckukan - 1].compareTo(
              b.time_taikai_total[temp_nowracecalckukan - 1],
            ),
          );
        final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>(
          'gakurenSenshuBox',
        );
        final gakurensenshudata = gakurensenshuBox.values.toList();

        String timesastr = "";
        if (currentGhensuu.nowracecalckukan > 0) {
          // ヘルパー関数: 秒数を分と秒にフォーマットし、小数点以下を切り捨てて表示する
          String formatTimeDifference(double difference) {
            // 符号を保持
            String sign = difference.isNegative ? '-' : '+';

            // 絶対値（秒）を整数として取得（小数点以下四捨五入）
            int absoluteSeconds = difference.abs().round();

            if (absoluteSeconds < 60) {
              // 1分未満の場合: 秒で表示
              return "$sign$absoluteSeconds秒";
            } else {
              // 1分以上の場合: 分と秒で表示
              int minutes = absoluteSeconds ~/ 60; // 分
              int remainingSeconds = absoluteSeconds % 60; // 残りの秒
              return "$sign${minutes}分${remainingSeconds}秒";
            }
          }

          int mokuhyojuni = idjununivdata[currentGhensuu.MYunivid]
              .mokuhyojuni[currentGhensuu.hyojiracebangou];
          int seedjuni = 0;
          if (currentGhensuu.hyojiracebangou == 1) seedjuni = 7;
          if (currentGhensuu.hyojiracebangou == 2) seedjuni = 9;
          int myunivjuni = idjununivdata[currentGhensuu.MYunivid]
              .tuukajuni_taikai[currentGhensuu.nowracecalckukan - 1];
          double time_top = timejununivdata[0]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_rank2 = timejununivdata[1]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_mokuhyojuni = timejununivdata[mokuhyojuni]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_mokuhyojuniplus1 = timejununivdata[mokuhyojuni + 1]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_seedjuni = timejununivdata[seedjuni]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_seedjuniplus1 = timejununivdata[seedjuni + 1]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          double time_myuniv = timejununivdata[myunivjuni]
              .time_taikai_total[currentGhensuu.nowracecalckukan - 1];
          int hyojizumijuni = 0;
          timesastr += "\n";
          if (currentGhensuu.nowracecalckukan > 1) {
            if (currentGhensuu.hyojiracebangou == 3) {
              timesastr += "合計(組)順位経過:";
            } else {
              timesastr += "通過(区間)順位経過:";
            }
            for (
              int i_kukan = 0;
              i_kukan < currentGhensuu.nowracecalckukan;
              i_kukan++
            ) {
              timesastr +=
                  "${idjununivdata[currentGhensuu.MYunivid].tuukajuni_taikai[i_kukan] + 1}(${idjununivdata[currentGhensuu.MYunivid].kukanjuni_taikai[i_kukan] + 1})-";
            }
            timesastr += "\n";
          }
          if (myunivjuni == 0) {
            timesastr +=
                "2位との差:${formatTimeDifference(time_myuniv - time_rank2)}\n";
          } else {
            timesastr +=
                "トップとの差:${formatTimeDifference(time_myuniv - time_top)}\n";
          }
          if (myunivjuni > mokuhyojuni) {
            timesastr +=
                "目標順位との差:${formatTimeDifference(time_myuniv - time_mokuhyojuni)}\n";
          } else {
            if (!(myunivjuni == 0 && mokuhyojuni == 0)) {
              hyojizumijuni = mokuhyojuni + 1;
              timesastr +=
                  "${mokuhyojuni + 2}位との差:${formatTimeDifference(time_myuniv - time_mokuhyojuniplus1)}\n";
            }
          }
          if (currentGhensuu.hyojiracebangou == 1 ||
              currentGhensuu.hyojiracebangou == 2) {
            if (myunivjuni > seedjuni) {
              timesastr +=
                  "シード権との差:${formatTimeDifference(time_myuniv - time_seedjuni)}\n";
            } else {
              if (hyojizumijuni != seedjuni + 1) {
                timesastr +=
                    "${seedjuni + 2}位との差:${formatTimeDifference(time_myuniv - time_seedjuniplus1)}\n";
              }
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          color: HENSUU.backgroundcolor,
          child: Column(
            children: [
              HStack(
                currentGhensuu,
                nowracekukanfilteredsenshudata, // ここに引数を追加
              ), // SwiftのHStack部分
              const Divider(color: Colors.grey),
              RaceInfo(currentGhensuu), // 駅伝情報表示部分
              if (idjununivdata[currentGhensuu.MYunivid]
                      .taikaientryflag[currentGhensuu.hyojiracebangou] ==
                  0)
                NoEntrySection(currentGhensuu)
              else
                Expanded(
                  child: Column(
                    children: [
                      CurrentRankSection(currentGhensuu), // 現在順位表示
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(timesastr),
                              // リンクボタン
                              LinkButtons(),
                              // 選手への指示と区間成績表示
                              SenshuSijiSection(
                                currentGhensuu,
                                gakunenjununivfilteredsenshudata,
                                nowracekukanfilteredsenshudata,
                              ),
                              if (currentGhensuu.hyojiracebangou == 4)
                                TimeSijiSection(),
                              const SizedBox(height: 16),

                              // 自分の大学の直近の区間の成績
                              if (currentGhensuu.nowracecalckukan > 0) ...[
                                Text("==直近区間=="),

                                MyUnivRaceResults_lastkukan(
                                  currentGhensuu,
                                  idjununivdata,
                                  gakunenjununivfilteredsenshudata,
                                ),
                              ],

                              // ここまでの全大学の総合成績
                              if (currentGhensuu.nowracecalckukan > 0)
                                if (currentGhensuu.hyojiracebangou == 2 &&
                                    gakurensenshudata.isNotEmpty) ...[
                                  Text("==総合成績=="),
                                  AllUnivOverallResults_shougatu(
                                    currentGhensuu,
                                    timejununivdata,
                                  ),
                                ] else ...[
                                  Text("==総合成績=="),
                                  AllUnivOverallResults(
                                    currentGhensuu,
                                    timejununivdata,
                                  ),
                                ],
                              const SizedBox(height: 16),

                              // 自分の大学のここまでの区間ごとの成績
                              if (currentGhensuu.nowracecalckukan > 0) ...[
                                Text("==ここまでの全区間=="),
                                MyUnivRaceResults(
                                  currentGhensuu,
                                  idjununivdata,
                                  gakunenjununivfilteredsenshudata,
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (currentGhensuu.hyojiracebangou == 4)
                                Text(
                                  "氏名(学年)の横の表示は、試走したタイム、駅伝男、平常心の値の順です。上から試走したタイムの良い順で並んでいます。なお、試走タイムは本番タイムよりも上下に若干振れている可能性があります。",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              if (currentGhensuu.hyojiracebangou == 4)
                                Text(
                                  "\n集団は6つまで作れます。\n設定タイムはその集団の中の1番速い試走タイムよりも速いタイムを設定することはできません。\n設定タイムが速すぎると、集団の中で実力が不足している選手は大失速する恐れがあります。反対にペースが遅すぎると実力よりもタイムが出ない選手が出てきます。\nですので、実力が飛び抜けていそうな選手や大きく実力が不足していそうな選手は、別の集団にするか、フリー走にした方が良いかもしれません。\n",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              if (currentGhensuu.hyojiracebangou == 4)
                                Text(
                                  "\nハーフの持ちタイムはペース変動対応力の影響がない市民ハーフや対校戦ハーフで出したタイムなのに対し、この正月駅伝予選ではペース変動対応力も要求されますのでご留意ください。なお、試走タイムにはペース変動対応力も加味されています。",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              if (currentGhensuu.hyojiracebangou == 2 &&
                                  gakurensenshudata.isNotEmpty)
                                Text(
                                  "\n\n学連選抜参考記録",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              if (currentGhensuu.hyojiracebangou == 2 &&
                                  gakurensenshudata.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.8,
                                      ),
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
                              if (currentGhensuu.hyojiracebangou == 2 &&
                                  gakurensenshudata.isNotEmpty)
                                gakurenRaceResults(
                                  currentGhensuu,
                                  idjununivdata,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  // SwiftのHStack部分をWidgetに分離
  Widget HStack(
    Ghensuu currentGhensuu,
    List<SenshuData> nowracekukanfilteredsenshudata, // ここに引数を追加
  ) {
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 全体を両端揃えにする
      children: [
        // 左側のColumnをExpandedで囲むことで、残りのスペースを柔軟に利用させる
        Expanded(
          child: Column(
            // テキスト群を左寄せで2行にまとめるColumn
            crossAxisAlignment: CrossAxisAlignment.start, // Column内の要素を左寄せに配置
            children: [
              Row(
                // 1行目のテキスト
                children: [
                  Text(
                    _getCombinedDifficultyText(
                      kantoku,
                      currentGhensuu,
                    ), // kazeflagの表示
                    style: const TextStyle(color: HENSUU.textcolor),
                  ),
                  const SizedBox(width: 8), // テキスト間のスペース
                  // ここでTextをFlexibleで囲み、はみ出し対策をする
                  Flexible(
                    child: Text(
                      "${currentGhensuu.year}年${currentGhensuu.month}月${TimeDate.dayToString(currentGhensuu.day)}",
                      style: const TextStyle(color: HENSUU.textcolor),
                      overflow: TextOverflow.ellipsis, // はみ出す場合は「...」で省略
                      maxLines: 1, // 1行に制限
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // 1行目と2行目の間のスペース
              Row(
                // 2行目のテキスト
                children: [
                  Expanded(
                    // 追加: テキストが利用可能なスペースを占有し、省略表示を可能にする
                    child: Text(
                      "金${currentGhensuu.goldenballsuu} 銀${currentGhensuu.silverballsuu}", // 金と銀のテキストを結合
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
        // ボタンはExpandedとAlignで右寄せに配置（変更なし）
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                // ここに条件判定を追加
                if (currentGhensuu.hyojiracebangou == 4) {
                  List<int> shuudannsouninzuu = List.filled(6, 0);
                  //いったんsijiflagに代入
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];

                    senshu.sijiflag = currentGhensuu.SijiSelectedOption[i_id];
                    senshu.sijiseikouflag = 0;
                    await senshu.save(); // Hiveオブジェクトの変更を保存
                  }
                  //前半突っ込み・前半抑え成功抽選
                  final random = Random();
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 1) {
                      if (Random().nextInt(100) < senshu.konjou) {
                        senshu.sijiseikouflag = 1;
                      } else {
                        senshu.sijiseikouflag = 0;
                      }
                      await senshu.save(); // Hiveオブジェクトの変更を保存
                    }
                    if (senshu.sijiflag == 2) {
                      if (Random().nextInt(100) < senshu.heijousin) {
                        senshu.sijiseikouflag = 1;
                      } else {
                        senshu.sijiseikouflag = 0;
                      }
                      await senshu.save(); // Hiveオブジェクトの変更を保存
                    }
                  }
                  //集団走Aの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 3) {
                      shuudannsouninzuu[0]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[0] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Aの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }

                  //集団走Bの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 4) {
                      shuudannsouninzuu[1]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[1] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Bの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }

                  //集団走Cの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 5) {
                      shuudannsouninzuu[2]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[2] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Cの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }

                  //集団走Dの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 6) {
                      shuudannsouninzuu[3]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[3] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Dの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }

                  //集団走Eの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 7) {
                      shuudannsouninzuu[4]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[4] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Eの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }

                  //集団走Fの選手がいるか確認
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag == 8) {
                      shuudannsouninzuu[5]++;
                    }
                  }
                  //集団走の人数が1人だけならダメよ
                  if (shuudannsouninzuu[5] == 1) {
                    // ここにチェックしたい条件を記述
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '集団走Fの選手が一人だけになっています',
                        ), // 任意のメッセージに置き換えてください
                        duration: const Duration(seconds: 2), // メッセージの表示時間
                      ),
                    );
                    return; // 条件が未成就ならここで処理を終了
                  }
                  //設定タイム代入前に集団の中で1番試走タイムが良い選手よりも設定タイムが速い場合はオーバーペースで弾く
                  List<double> minsisoutime = List.filled(
                    6,
                    TEISUU.DEFAULTTIME,
                  );
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.sijiflag >= 3 && senshu.sijiflag <= 8) {
                      if (shuudansou!.sisoutime[senshu.id] <
                          minsisoutime[senshu.sijiflag - 3]) {
                        minsisoutime[senshu.sijiflag - 3] =
                            shuudansou!.sisoutime[senshu.id];
                      }
                    }
                  }
                  for (int i_shuudan = 0; i_shuudan < 6; i_shuudan++) {
                    double tempsetteitime =
                        shuudansou!.sijioption_fun[i_shuudan] * 60.0 +
                        shuudansou!.sijioption_byou[i_shuudan] * 1.0;
                    if (shuudannsouninzuu[i_shuudan] != 0 &&
                        tempsetteitime < minsisoutime[i_shuudan]) {
                      String tempstr = "";
                      if (i_shuudan == 0) {
                        tempstr =
                            "集団走Aの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      if (i_shuudan == 1) {
                        tempstr =
                            "集団走Bの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      if (i_shuudan == 2) {
                        tempstr =
                            "集団走Cの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      if (i_shuudan == 3) {
                        tempstr =
                            "集団走Dの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      if (i_shuudan == 4) {
                        tempstr =
                            "集団走Eの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      if (i_shuudan == 5) {
                        tempstr =
                            "集団走Fの設定タイムがオーバーペースです。設定タイムはその集団の中の1番速い試走タイムよりは遅くしてください。";
                      }
                      // ここにチェックしたい条件を記述
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tempstr), // 任意のメッセージに置き換えてください
                          duration: const Duration(seconds: 2), // メッセージの表示時間
                        ),
                      );
                      return; // 条件が未成就ならここで処理を終了
                    }
                  }
                  //設定タイムを代入
                  for (int i_shuudan = 0; i_shuudan < 6; i_shuudan++) {
                    if (shuudannsouninzuu[i_shuudan] != 0) {
                      shuudansou!.setteitime[i_shuudan] =
                          shuudansou!.sijioption_fun[i_shuudan] * 60.0 +
                          shuudansou!.sijioption_byou[i_shuudan] * 1.0;
                    } else {
                      shuudansou!.setteitime[i_shuudan] = TEISUU.DEFAULTTIME;
                    }
                    await shuudansou!.save();
                  }
                }

                if (currentGhensuu.hyojiracebangou != 4 &&
                    (currentGhensuu.nowracecalckukan == 0 ||
                        currentGhensuu.hyojiracebangou == 3)) {
                  /*for (var senshu in nowracekukanfilteredsenshudata) {
                    if (senshu.sijiflag == 0) {
                      senshu.startchokugotobidasiflag = 0;
                      if (TEISUU.STARTTOBIDASIKAKURITU >
                          (DateTime.now().microsecondsSinceEpoch % 100)) {
                        senshu.startchokugotobidasiflag = 1;
                      }
                    }
                    if (senshu.sijiflag == 1) {
                      senshu.startchokugotobidasiflag = 1;
                    }
                    if (senshu.sijiflag == 2) {
                      senshu.startchokugotobidasiflag = 0;
                    }
                  }*/
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.entrykukan_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1] ==
                        currentGhensuu.nowracecalckukan) {
                      senshu.sijiflag = currentGhensuu.SijiSelectedOption[i_id];
                      if (currentGhensuu.SijiSelectedOption[i_id] == 0) {
                        senshu.startchokugotobidasiflag = 0;
                        if (senshu.konjou >= 85) {
                          if (Random().nextInt(100) <
                              TEISUU.STARTTOBIDASIKAKURITU) {
                            senshu.startchokugotobidasiflag = 1;
                          }
                        }
                      }
                      if (currentGhensuu.SijiSelectedOption[i_id] == 1) {
                        senshu.startchokugotobidasiflag =
                            currentGhensuu.SijiSelectedOption[i_id];
                      }
                      if (currentGhensuu.SijiSelectedOption[i_id] == 2) {
                        senshu.startchokugotobidasiflag = 0;
                      }
                      await senshu.save(); // Hiveオブジェクトの変更を保存
                    }
                  }
                } else if (currentGhensuu.hyojiracebangou != 4) {
                  for (
                    int i_id = 0;
                    i_id < gakunenjununivfilteredsenshudata.length;
                    i_id++
                  ) {
                    final senshu = gakunenjununivfilteredsenshudata[i_id];
                    if (senshu.entrykukan_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1] ==
                        currentGhensuu.nowracecalckukan) {
                      senshu.sijiflag = currentGhensuu.SijiSelectedOption[i_id];
                      await senshu.save(); // Hiveオブジェクトの変更を保存
                    }
                  }
                }

                widget.onAdvanceMode?.call(); // 親画面へのコールバック
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                minimumSize: Size.zero, // サイズが自動調整されるように最小サイズを0に
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "進む＞＞",
                style: TextStyle(
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 駅伝情報表示部分をWidgetに分離
  Widget RaceInfo(Ghensuu currentGhensuu) {
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    String raceName;
    switch (currentGhensuu.hyojiracebangou) {
      case 0:
        raceName = "10月駅伝";
        break;
      case 1:
        raceName = "11月駅伝";
        break;
      case 2:
        raceName = "正月駅伝";
        break;
      case 3:
        raceName = "11月駅伝予選";
        break;
      case 4:
        raceName = "正月駅伝予選";
        break;
      case 5:
        raceName = sortedUnivData[0].name_tanshuku;
        break;
      default:
        raceName = "";
    }
    return Text(raceName, style: TextStyle(color: HENSUU.textcolor));
  }

  // 不出場の場合の表示をWidgetに分離
  Widget NoEntrySection(Ghensuu currentGhensuu) {
    // ColumnをExpandedでラップすることで、親から与えられた空間を全て利用するようにする
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 中央寄せにする場合は追加
        children: [
          Text(
            "${idjununivdata[currentGhensuu.MYunivid].name}大学は不出場です",
            style: TextStyle(color: HENSUU.textcolor),
          ),
          Text(
            "これから${currentGhensuu.nowracecalckukan + 1}区を計算します",
            style: TextStyle(color: HENSUU.textcolor),
          ),
          const ProgressView(), // カスタムProgressViewまたはCircularProgressIndicator
          Spacer(), // これが原因でエラーが出ていたが、Expandedで親が制約を持つため解決
        ],
      ),
    );
  }

  // 現在順位表示をWidgetに分離
  Widget CurrentRankSection(Ghensuu currentGhensuu) {
    String rankText;
    if (currentGhensuu.nowracecalckukan == 0) {
      rankText =
          "スタート前 (目標順位:${idjununivdata[currentGhensuu.MYunivid].mokuhyojuni[currentGhensuu.hyojiracebangou] + 1}位)";
    } else {
      int currentRank = idjununivdata[currentGhensuu.MYunivid]
          .tuukajuni_taikai[currentGhensuu.nowracecalckukan - 1];
      String raceUnit = currentGhensuu.hyojiracebangou == 3 ? "組目" : "区";
      if (currentGhensuu.nowracecalckukan > 1) {
        int prevRank = idjununivdata[currentGhensuu.MYunivid]
            .tuukajuni_taikai[currentGhensuu.nowracecalckukan - 2];
        int diff = currentRank - prevRank;
        String arrow = diff > 0
            ? "↓ $diff"
            : (diff < 0 ? "↑ ${diff.abs()}" : "→");
        rankText =
            "${currentGhensuu.nowracecalckukan}$raceUnit終了時点 ${currentRank + 1}位 $arrow (目標順位:${idjununivdata[currentGhensuu.MYunivid].mokuhyojuni[currentGhensuu.hyojiracebangou] + 1}位)";
      } else {
        rankText =
            "${currentGhensuu.nowracecalckukan}$raceUnit終了時点 ${currentRank + 1}位 (目標順位:${idjununivdata[currentGhensuu.MYunivid].mokuhyojuni[currentGhensuu.hyojiracebangou] + 1}位)";
      }
    }
    return Text(rankText, style: TextStyle(color: HENSUU.textcolor));
  }

  // リンクボタンをWidgetに分離
  Widget LinkButtons() {
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    return Column(
      children: [
        if (kantoku.yobiint2[17] == 1 &&
            (gh!.hyojiracebangou <= 2 || gh!.hyojiracebangou == 5))
          TextButton(
            onPressed: () async {
              // ★こちらも showGeneralDialog に変更★
              await showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '全大学指示画面', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalKukanInstructionView(); // const を追加
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

              //自分の大学の選手の指示表示を変更する処理
              for (
                int i_id = 0;
                i_id < gakunenjununivfilteredsenshudata.length;
                i_id++
              ) {
                if (gakunenjununivfilteredsenshudata[i_id].entrykukan_race[gh!
                        .hyojiracebangou][gakunenjununivfilteredsenshudata[i_id]
                            .gakunen -
                        1] ==
                    gh!.nowracecalckukan) {
                  final senshu = gakunenjununivfilteredsenshudata[i_id];
                  gh!.SijiSelectedOption[i_id] = senshu.sijiflag;
                  await gh!.save();
                }
              }
              setState(() {});
            },
            child: Text(
              "全大学指示画面",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        if (kantoku.yobiint2[17] == 1 &&
            (gh!.hyojiracebangou <= 2 || gh!.hyojiracebangou == 5))
          TextButton(
            onPressed: () async {
              // ★こちらも showGeneralDialog に変更★
              await showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '全大学目標順位画面', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalTargetRankSettingView(); // const を追加
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

              //自分の大学の選手の指示表示を変更する処理
              for (
                int i_id = 0;
                i_id < gakunenjununivfilteredsenshudata.length;
                i_id++
              ) {
                if (gakunenjununivfilteredsenshudata[i_id].entrykukan_race[gh!
                        .hyojiracebangou][gakunenjununivfilteredsenshudata[i_id]
                            .gakunen -
                        1] ==
                    gh!.nowracecalckukan) {
                  final senshu = gakunenjununivfilteredsenshudata[i_id];
                  gh!.SijiSelectedOption[i_id] = senshu.sijiflag;
                  await gh!.save();
                }
              }
              setState(() {});
            },
            child: Text(
              "全大学目標順位画面",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            // ★ここを showGeneralDialog に変更★
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '区間コース確認', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return ModalCourseshoukaiView(
                  racebangou: gh!.hyojiracebangou,
                ); // const を追加
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
            "区間コース確認",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),

        if (gh!.hyojiracebangou != 4)
          TextButton(
            onPressed: () {
              // ★こちらも showGeneralDialog に変更★
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '区間配置確認', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalKukanHaitiView(
                    targetUnivid: gh!.MYunivid,
                  ); // const を追加
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
              "区間配置確認",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        if (gh!.hyojiracebangou <= 2 ||
            gh!.hyojiracebangou == 5 ||
            gh!.hyojiracebangou == 3)
          TextButton(
            onPressed: () {
              // ★こちらも showGeneralDialog に変更★
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: 'エントリー選手一覧', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalKukanEntryListView(); // const を追加
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
              "エントリー選手一覧",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        if (gh!.hyojiracebangou <= 2 || gh!.hyojiracebangou == 5)
          TextButton(
            onPressed: () {
              // ★こちらも showGeneralDialog に変更★
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '当日変更一覧', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return ModalTodayChangeListView(); // const を追加
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
              "当日変更一覧",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        if (gh!.hyojiracebangou <= 2 || gh!.hyojiracebangou == 5)
          if (gh!.nowracecalckukan > 0)
            TextButton(
              onPressed: () {
                // ★こちらも showGeneralDialog に変更★
                showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                  barrierDismissible: true, // 背景タップで閉じられるようにする
                  barrierLabel: '個人順位速報', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return ModalKukanResultListView350(); // const を追加
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
                "個人順位速報",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),

        if (gh!.hyojiracebangou <= 2 || gh!.hyojiracebangou == 5)
          if (gh!.nowracecalckukan > 0)
            TextButton(
              onPressed: () {
                // ★こちらも showGeneralDialog に変更★
                showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                  barrierDismissible: true, // 背景タップで閉じられるようにする
                  barrierLabel: '通過順位速報', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return ModalKukanResultListViewPass(); // const を追加
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
                "通過順位速報",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),

        if (gh!.hyojiracebangou <= 3 || gh!.hyojiracebangou == 5)
          if (gh!.nowracecalckukan > 0)
            TextButton(
              onPressed: () {
                // ★こちらも showGeneralDialog に変更★
                showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                  barrierDismissible: true, // 背景タップで閉じられるようにする
                  barrierLabel: '順位推移表', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return ModalRankTransitionView(); // const を追加
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
                "順位推移表",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),

        if (gh!.hyojiracebangou <= 3 || gh!.hyojiracebangou == 5)
          if (gh!.nowracecalckukan > 0)
            TextButton(
              onPressed: () {
                // ★こちらも showGeneralDialog に変更★
                showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                  barrierDismissible: true, // 背景タップで閉じられるようにする
                  barrierLabel: 'レース分析チャート', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return ModalTimeDifferenceGraph(); // const を追加
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
                "レース分析チャート",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),
      ],
    );
  }

  //設定タイムの指示オプション
  Widget TimeSijiSection(
    //Box<Shuudansou> shuudansouBox,
    //Function(int index, int newValue, bool isFun) onTimeChanged,
  ) {
    final List<String> groups = [
      '集団走A',
      '集団走B',
      '集団走C',
      '集団走D',
      '集団走E',
      '集団走F',
    ];

    final List<int> minutesOptions = [
      55,
      56,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
      77,
      78,
      79,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      89,
      90,
    ];
    final List<int> secondsOptions = [
      0,
      5,
      10,
      15,
      20,
      25,
      30,
      35,
      40,
      45,
      50,
      55,
    ];

    // Hive.box() を使って、既に開いているBoxを取得
    final shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
    // Boxからデータを読み込む
    final Shuudansou? shuudansou = shuudansouBox.get('ShuudansouData');
    /*if (shuudansou != null) {
      // データを使用
      //print(shuudansou.なんちゃら);
    } else {
      //print('データが見つかりません');
    }*/

    return ValueListenableBuilder(
      valueListenable: shuudansouBox.listenable(),
      builder: (context, Box<Shuudansou> box, _) {
        final shuudansou = box.getAt(0) ?? Shuudansou();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '設定タイムの指示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HENSUU.textcolor,
                ),
              ),
            ),
            ...groups.asMap().entries.map((entry) {
              final index = entry.key;
              final groupName = entry.value;

              int currentFun = index < shuudansou.sijioption_fun.length
                  ? shuudansou.sijioption_fun[index]
                  : minutesOptions[0];
              int currentByou = index < shuudansou.sijioption_byou.length
                  ? shuudansou.sijioption_byou[index]
                  : secondsOptions[0];

              // データの有効性をチェック
              if (!minutesOptions.contains(currentFun)) {
                currentFun = minutesOptions[0];
              }
              if (!secondsOptions.contains(currentByou)) {
                currentByou = secondsOptions[0];
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: HENSUU.textcolor,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _buildDropdownButton(
                            value: currentFun,
                            options: minutesOptions,
                            onChanged: (int? newValue) async {
                              if (newValue != null) {
                                //onTimeChanged(index, newValue, true);
                                shuudansou.sijioption_fun[index] = newValue;
                                await shuudansou.save();
                                print(
                                  "分が index=${index} newValue=${newValue} にonChanged",
                                );
                              }
                            },
                          ),
                          Text(
                            ' 分 ',
                            style: TextStyle(color: HENSUU.textcolor),
                          ),
                          _buildDropdownButton(
                            value: currentByou,
                            options: secondsOptions,
                            onChanged: (int? newValue) async {
                              if (newValue != null) {
                                //onTimeChanged(index, newValue, true);
                                shuudansou.sijioption_byou[index] = newValue;
                                await shuudansou.save();
                                print(
                                  "秒が index=${index} newValue=${newValue} にonChanged",
                                );
                              }
                            },
                          ),
                          Text(' 秒', style: TextStyle(color: HENSUU.textcolor)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // 集団走用ドロップダウンボタンを生成するヘルパー関数
  Widget _buildDropdownButton({
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      dropdownColor: const Color.fromARGB(255, 30, 30, 30),
      style: const TextStyle(color: HENSUU.textcolor),
      iconEnabledColor: HENSUU.textcolor,
      items: options.map((int option) {
        return DropdownMenuItem<int>(
          value: option,
          child: Text(
            option.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: HENSUU.fontsize_honbun,
              color: HENSUU.LinkColor,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // 選手への指示と区間成績表示をWidgetに分離
  Widget SenshuSijiSection(
    Ghensuu currentGhensuu,
    List<SenshuData> gakunenjununivfilteredsenshudata,
    List<SenshuData> nowracekukanfilteredsenshudata,
  ) {
    return Column(
      children: gakunenjununivfilteredsenshudata.map((senshu) {
        if (senshu.entrykukan_race[currentGhensuu
                .hyojiracebangou][senshu.gakunen - 1] ==
            currentGhensuu.nowracecalckukan) {
          String playerInfoText = "";
          if (currentGhensuu.hyojiracebangou == 3) {
            playerInfoText =
                "${currentGhensuu.nowracecalckukan + 1}組目の選手(${senshu.name}(${senshu.gakunen}))へ指示をしますか？\n駅伝男${senshu.konjou}";
          } else if (currentGhensuu.hyojiracebangou == 4) {
            if (currentGhensuu.nouryokumieruflag[0] == 1 &&
                currentGhensuu.nouryokumieruflag[1] == 1) {
              playerInfoText =
                  "${senshu.name}(${senshu.gakunen})への指示 試走${TimeDate.timeToFunByouString(shuudansou!.sisoutime[senshu.id])}\n駅伝男${senshu.konjou} 平常心${senshu.heijousin}";
            }
            if (currentGhensuu.nouryokumieruflag[0] == 1 &&
                currentGhensuu.nouryokumieruflag[1] == 0) {
              playerInfoText =
                  "${senshu.name}(${senshu.gakunen})への指示 試走${TimeDate.timeToFunByouString(shuudansou!.sisoutime[senshu.id])}\n駅伝男${senshu.konjou} 平常心??";
            }
            if (currentGhensuu.nouryokumieruflag[0] == 0 &&
                currentGhensuu.nouryokumieruflag[1] == 1) {
              playerInfoText =
                  "${senshu.name}(${senshu.gakunen})への指示 試走${TimeDate.timeToFunByouString(shuudansou!.sisoutime[senshu.id])}\n駅伝男?? 平常心${senshu.heijousin}";
            }
            if (currentGhensuu.nouryokumieruflag[0] == 0 &&
                currentGhensuu.nouryokumieruflag[1] == 0) {
              playerInfoText =
                  "${senshu.name}(${senshu.gakunen})への指示 試走${TimeDate.timeToFunByouString(shuudansou!.sisoutime[senshu.id])}\n駅伝男?? 平常心??";
            }
          } else {
            if (currentGhensuu.nowracecalckukan == 0) {
              playerInfoText =
                  "${currentGhensuu.nowracecalckukan + 1}区の選手(${senshu.name}(${senshu.gakunen}))へ指示をしますか？\n駅伝男${senshu.konjou}";
            } else {
              playerInfoText =
                  "${currentGhensuu.nowracecalckukan + 1}区の選手(${senshu.name}(${senshu.gakunen}))へ指示をしますか？\n駅伝男${senshu.konjou} 平常心${senshu.heijousin}";
            }
          }

          List<String> options;
          if (currentGhensuu.hyojiracebangou == 4) {
            options = [
              "フリー走",
              "フリー走(前半突っ込み)",
              "フリー走(前半抑え)",
              "集団走A",
              "集団走B",
              "集団走C",
              "集団走D",
              "集団走E",
              "集団走F",
            ];
          } else if (currentGhensuu.nowracecalckukan == 0 ||
              currentGhensuu.hyojiracebangou == 3) {
            options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
          } else {
            if (idjununivdata[currentGhensuu.MYunivid]
                    .mokuhyojuniwositamawatteruflag[currentGhensuu
                        .nowracecalckukan -
                    1] ==
                1) {
              options = ["指示なし", "前半から突っ込む", "前半は抑える"];
            } else {
              options = ["指示なし", "前半から突っ込む", "前半は抑える"];
            }
          }

          // SijiSelectedOptionのインデックスが範囲外になるのを防ぐ
          // Swiftの.onAppear()ロジックをここに適用
          int currentSijiOption =
              currentGhensuu.SijiSelectedOption.length >
                  gakunenjununivfilteredsenshudata.indexOf(senshu)
              ? currentGhensuu
                    .SijiSelectedOption[gakunenjununivfilteredsenshudata
                    .indexOf(senshu)]
              : 0; // デフォルト値

          if (currentSijiOption >= options.length) {
            currentSijiOption = 0;
            // 変更をHiveに保存
            currentGhensuu.SijiSelectedOption[gakunenjununivfilteredsenshudata
                    .indexOf(senshu)] =
                0;
            //currentGhensuu.save();ここには来ないはずなのでコメントアウトした
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerInfoText,
                style: TextStyle(color: HENSUU.textcolor),
                // Textウィジェットが長すぎる場合も考慮
                softWrap: true, // 自動折り返しを有効に（長い説明文なので）
                overflow: TextOverflow.ellipsis, // はみ出しを「...」で表示
                maxLines: 3, // 必要に応じて複数行を許可
              ),
              _buildDetailButton(senshu),
              const SizedBox(height: 20),
              // ここでDropdownButtonを修正
              DropdownButton<int>(
                value: currentSijiOption,
                //dropdownColor: HENSUU.backgroundcolor,
                dropdownColor: Color.fromARGB(255, 30, 30, 30),
                style: TextStyle(color: HENSUU.textcolor),
                iconEnabledColor: HENSUU.textcolor,
                isExpanded: true, // ★追加：親の横幅いっぱいに広げる
                onChanged: (int? newValue) async {
                  print('onChanged is called!'); // これが実行されるか確認
                  if (newValue != null) {
                    currentGhensuu
                            .SijiSelectedOption[gakunenjununivfilteredsenshudata
                            .indexOf(senshu)] =
                        newValue;

                    /*print(
                      'indexOf(senshu)=${gakunenjununivfilteredsenshudata.indexOf(senshu)}  SijiSelectedOption=${currentGhensuu.SijiSelectedOption[gakunenjununivfilteredsenshudata.indexOf(senshu)]}',
                    );*/

                    await currentGhensuu.save();
                  }
                },
                items: options.asMap().entries.map((entry) {
                  int index = entry.key;
                  String value = entry.value;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        color: HENSUU.LinkColor,
                      ),
                      maxLines: 1, // ★追加：ドロップダウンアイテムのテキストも1行に制限
                      overflow: TextOverflow.ellipsis, // ★追加：はみ出しを「...」で表示
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget MyUnivRaceResults_lastkukan(
    Ghensuu currentGhensuu,
    List<UnivData> idjununivdata,
    List<SenshuData> gakunenjununivfilteredsenshudata,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(1, (i) {
        int i_kukan = currentGhensuu.nowracecalckukan - 1;
        String kukanLabel = currentGhensuu.hyojiracebangou == 3 ? "組目" : "区";
        String kukanText = "${i_kukan + 1}$kukanLabel";
        String kukanLabel_juni = currentGhensuu.hyojiracebangou == 3
            ? "組内"
            : "区間";
        String totalTime = TimeDate.timeToJikanFunByouString(
          idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan],
        );
        String kukanTime = "";
        if (i_kukan > 0) {
          kukanTime = TimeDate.timeToFunByouString(
            idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan] -
                idjununivdata[currentGhensuu.MYunivid]
                    .time_taikai_total[i_kukan - 1],
          );
        } else {
          kukanTime = TimeDate.timeToFunByouString(
            idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kukanText,
              style: TextStyle(
                color: HENSUU.textcolor,
                //fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "通過順位:${idjununivdata[currentGhensuu.MYunivid].tuukajuni_taikai[i_kukan] + 1}位 $totalTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            Text(
              "${kukanLabel_juni}順位:${idjununivdata[currentGhensuu.MYunivid].kukanjuni_taikai[i_kukan] + 1}位 $kukanTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gakunenjununivfilteredsenshudata.map((senshu) {
                if (senshu.entrykukan_race[currentGhensuu
                        .hyojiracebangou][senshu.gakunen - 1] ==
                    i_kukan) {
                  String sijiContent;
                  String sijiResult = "";
                  List<String> options;
                  List<String> kekka = ["失敗", "成功"];

                  if (i_kukan == 0 || currentGhensuu.hyojiracebangou == 3) {
                    options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.startchokugotobidasiflag == 1) {
                      sijiResult =
                          "スタート直後飛び出して:${kekka[senshu.startchokugotobidasiseikouflag]}";
                    }
                  } else {
                    options = ["指示なし", "前半から突っ込む", "前半は抑える"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.sijiflag >= 1) {
                      sijiResult = "結果:${kekka[senshu.sijiseikouflag]}";
                    } else if (i_kukan > 0 &&
                        idjununivdata[currentGhensuu.MYunivid]
                                .mokuhyojuniwositamawatteruflag[i_kukan - 1] ==
                            1) {
                      sijiResult = "チーム目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり";
                    } else if (i_kukan > 0 &&
                        idjununivdata[currentGhensuu.MYunivid]
                                .mokuhyojuniwositamawatteruflag[i_kukan - 1] <
                            0) {
                      sijiResult = "チーム目標順位を上回っていたことによるほっと一息でのタイム悪化あり";
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          // ★ここを showGeneralDialog に変更★
                          showGeneralDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(
                              0.8,
                            ), // 背景を少し暗くする
                            barrierDismissible: true,
                            barrierLabel: '結果分析',
                            pageBuilder: (context, _, __) =>
                                ModalSenshuAnalysisView(
                                  senshuId: senshu.id, // ここに対象選手のIDを渡す
                                ),
                          );
                        },
                        child: Text(
                          "結果分析",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 255, 0),
                            decoration: TextDecoration.underline,
                            decorationColor: HENSUU.textcolor,
                          ),
                        ),
                      ),

                      Text(
                        "${senshu.name} ${senshu.gakunen}年",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentGhensuu.hyojiracebangou == 3)
                        Text(
                          "組内順位:${senshu.temp_juni + 1}位 ${TimeDate.timeToFunByouString(senshu.time_taikai_total)}",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      Text(
                        sijiContent,
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                      if (sijiResult.isNotEmpty)
                        Text(
                          sijiResult,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      if (senshu.string_racesetumei.isNotEmpty)
                        Text(
                          senshu.string_racesetumei,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      const SizedBox(height: 10),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  // 自分の大学のここまでの区間ごとの成績をWidgetに分離
  Widget MyUnivRaceResults(
    Ghensuu currentGhensuu,
    List<UnivData> idjununivdata,
    List<SenshuData> gakunenjununivfilteredsenshudata,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(currentGhensuu.nowracecalckukan, (i_kukan) {
        String kukanLabel = currentGhensuu.hyojiracebangou == 3 ? "組目" : "区";
        String kukanText = "${i_kukan + 1}$kukanLabel";
        String kukanLabel_juni = currentGhensuu.hyojiracebangou == 3
            ? "組内"
            : "区間";
        String totalTime = TimeDate.timeToJikanFunByouString(
          idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan],
        );
        String kukanTime = "";
        if (i_kukan > 0) {
          kukanTime = TimeDate.timeToFunByouString(
            idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan] -
                idjununivdata[currentGhensuu.MYunivid]
                    .time_taikai_total[i_kukan - 1],
          );
        } else {
          kukanTime = TimeDate.timeToFunByouString(
            idjununivdata[currentGhensuu.MYunivid].time_taikai_total[i_kukan],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kukanText,
              style: TextStyle(
                color: HENSUU.textcolor,
                //fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "通過順位:${idjununivdata[currentGhensuu.MYunivid].tuukajuni_taikai[i_kukan] + 1}位 $totalTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            Text(
              "${kukanLabel_juni}順位:${idjununivdata[currentGhensuu.MYunivid].kukanjuni_taikai[i_kukan] + 1}位 $kukanTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gakunenjununivfilteredsenshudata.map((senshu) {
                if (senshu.entrykukan_race[currentGhensuu
                        .hyojiracebangou][senshu.gakunen - 1] ==
                    i_kukan) {
                  String sijiContent;
                  String sijiResult = "";
                  List<String> options;
                  List<String> kekka = ["失敗", "成功"];

                  if (i_kukan == 0 || currentGhensuu.hyojiracebangou == 3) {
                    options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.startchokugotobidasiflag == 1) {
                      sijiResult =
                          "スタート直後飛び出して:${kekka[senshu.startchokugotobidasiseikouflag]}";
                    }
                  } else {
                    options = ["指示なし", "前半から突っ込む", "前半は抑える"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.sijiflag >= 1) {
                      sijiResult = "結果:${kekka[senshu.sijiseikouflag]}";
                    } else if (i_kukan > 0 &&
                        idjununivdata[currentGhensuu.MYunivid]
                                .mokuhyojuniwositamawatteruflag[i_kukan - 1] ==
                            1) {
                      sijiResult = "チーム目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり";
                    } else if (i_kukan > 0 &&
                        idjununivdata[currentGhensuu.MYunivid]
                                .mokuhyojuniwositamawatteruflag[i_kukan - 1] <
                            0) {
                      sijiResult = "チーム目標順位を上回っていたことによるほっと一息でのタイム悪化あり";
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${senshu.name} ${senshu.gakunen}年",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentGhensuu.hyojiracebangou == 3)
                        Text(
                          "組内順位:${senshu.temp_juni + 1}位 ${TimeDate.timeToFunByouString(senshu.time_taikai_total)}",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      Text(
                        sijiContent,
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                      if (sijiResult.isNotEmpty)
                        Text(
                          sijiResult,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      if (senshu.string_racesetumei.isNotEmpty)
                        Text(
                          senshu.string_racesetumei,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      const SizedBox(height: 10),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget gakurenRaceResults(
    Ghensuu currentGhensuu,
    List<UnivData> idjununivdata,
    //List<SenshuData> gakunenjununivfilteredsenshudata,
  ) {
    final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
    final gakurenunivdata = gakurenunivBox.values.toList();
    final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
    final gakurensenshudata = gakurensenshuBox.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(currentGhensuu.nowracecalckukan, (i_kukan) {
        String kukanLabel = currentGhensuu.hyojiracebangou == 3 ? "組目" : "区";
        String kukanText = "${i_kukan + 1}$kukanLabel";
        String kukanLabel_juni = currentGhensuu.hyojiracebangou == 3
            ? "組内"
            : "区間";
        String totalTime = TimeDate.timeToJikanFunByouString(
          gakurenunivdata[0].time_taikai_total[i_kukan],
        );
        String kukanTime = "";
        if (i_kukan > 0) {
          kukanTime = TimeDate.timeToFunByouString(
            gakurenunivdata[0].time_taikai_total[i_kukan] -
                gakurenunivdata[0].time_taikai_total[i_kukan - 1],
          );
        } else {
          kukanTime = TimeDate.timeToFunByouString(
            gakurenunivdata[0].time_taikai_total[i_kukan],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kukanText,
              style: TextStyle(
                color: HENSUU.textcolor,
                //fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "通過順位:${gakurenunivdata[0].tuukajuni_taikai[i_kukan] + 1}位相当 $totalTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            Text(
              "${kukanLabel_juni}順位:${gakurenunivdata[0].kukanjuni_taikai[i_kukan] + 1}位相当 $kukanTime",
              style: TextStyle(color: HENSUU.textcolor),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gakurensenshudata.map((senshu) {
                if (senshu.entrykukan_race[currentGhensuu
                        .hyojiracebangou][senshu.gakunen - 1] ==
                    i_kukan) {
                  /*String sijiContent;
                  String sijiResult = "";
                  List<String> options;
                  List<String> kekka = ["失敗", "成功"];

                  if (i_kukan == 0 || currentGhensuu.hyojiracebangou == 3) {
                    options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.startchokugotobidasiflag == 1) {
                      sijiResult =
                          "スタート直後飛び出して:${kekka[senshu.startchokugotobidasiseikouflag]}";
                    }
                  } else {
                    options = ["指示なし", "前半から突っ込む", "前半は抑える"];
                    sijiContent = "指示内容:${options[senshu.sijiflag]}";
                    if (senshu.sijiflag >= 1) {
                      sijiResult = "結果:${kekka[senshu.sijiseikouflag]}";
                    } else if (i_kukan > 0 &&
                        idjununivdata[currentGhensuu.MYunivid]
                                .mokuhyojuniwositamawatteruflag[i_kukan - 1] ==
                            1) {
                      sijiResult = "チーム目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり";
                    }
                  }*/

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${senshu.name} ${senshu.gakunen}年  ${idjununivdata[senshu.univid].name}",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentGhensuu.hyojiracebangou == 3)
                        Text(
                          "組内順位:${senshu.temp_juni + 1}位 ${TimeDate.timeToFunByouString(senshu.time_taikai_total)}",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      /*Text(
                        sijiContent,
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                      if (sijiResult.isNotEmpty)
                        Text(
                          sijiResult,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      if (senshu.string_racesetumei.isNotEmpty)
                        Text(
                          senshu.string_racesetumei,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),*/
                      const SizedBox(height: 10),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget AllUnivOverallResults_shougatu(
    Ghensuu currentGhensuu,
    List<UnivData> timejununivdata,
  ) {
    final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
    final gakurenunivdata = gakurenunivBox.values.toList();

    // 取得した学連選抜の順位 (tuukajuni_taikai)
    // jun_gakurenは0から始まるインデックスの順位（例：1位なら0）。
    // totalの結果なので、nowracecalckukan - 1 を使用。
    final int juni_gakuren = gakurenunivdata[0]
        .tuukajuni_taikai[currentGhensuu.nowracecalckukan - 1]; // オープン参加の挿入位置

    // 順位表のウィジェットリストを格納する
    final List<Widget> rankListWidgets = [];

    // 正式参加の大学のみを抽出したリスト
    final officialEntries =
        timejununivdata // timejununivdataは既に時間順にソートされているはず
            .where(
              (univ) =>
                  univ.taikaientryflag[currentGhensuu.hyojiracebangou] == 1,
            )
            .toList();

    // オープン参加の大学のデータ
    final gakurenUniv = gakurenunivdata[0];
    // nowracecalckukan - 1 は最新の合計タイムのインデックス
    final gakurenTotalTime =
        gakurenUniv.time_taikai_total[currentGhensuu.nowracecalckukan - 1];

    // オープン参加のウィジェットを生成
    final openEntryWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        // 順位は「OP」として表示
        "OP ${gakurenUniv.name} ${TimeDate.timeToJikanFunByouString(gakurenTotalTime)}",
        style: TextStyle(color: HENSUU.textcolor),
      ),
    );

    // 総合順位リストを生成
    for (int i = 0; i < officialEntries.length; i++) {
      final univ = officialEntries[i];

      // オープン参加の順位（juni_gakuren）の直前（i）に挿入
      if (i == juni_gakuren) {
        rankListWidgets.add(openEntryWidget);
      }

      // 正式参加の大学の表示
      // 順位は officialEntries のインデックス i に +1 して表示する (1-indexed)
      final rankDisplay = i + 1;
      final totalTime =
          univ.time_taikai_total[currentGhensuu.nowracecalckukan - 1];

      rankListWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            "${rankDisplay}位 ${univ.name} ${TimeDate.timeToJikanFunByouString(totalTime)}",
            style: TextStyle(color: HENSUU.textcolor),
          ),
        ),
      );
    }

    // オープン参加の順位が、正式参加の大学の数と同じかそれ以上の場合、リストの最後に挿入
    if (juni_gakuren >= officialEntries.length) {
      rankListWidgets.add(openEntryWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...rankListWidgets,
        const SizedBox(height: 10),
      ],
    );
  }

  // ここまでの全大学の総合成績をWidgetに分離
  Widget AllUnivOverallResults(
    Ghensuu currentGhensuu,
    List<UnivData> timejununivdata,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...timejununivdata.map((univ) {
          if (univ.taikaientryflag[currentGhensuu.hyojiracebangou] == 1) {
            int rank = timejununivdata.indexOf(univ); // 順位はソート済みリストのインデックス
            return Text(
              "${rank + 1}位 ${univ.name} ${TimeDate.timeToJikanFunByouString(univ.time_taikai_total[currentGhensuu.nowracecalckukan - 1])}",
              style: TextStyle(color: HENSUU.textcolor),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  // Swiftのhyojijunbi() async関数に相当
  Future<void> _hyojijunbi(Ghensuu currentGhensuu) async {
    //print('_hyojijunbi内　現在の表示レース番号: ${currentGhensuu.hyojiracebangou}');
    //print('_hyojijunbi内　MYunivid: ${currentGhensuu.MYunivid}');

    if (idjununivdata[currentGhensuu.MYunivid].taikaientryflag[currentGhensuu
            .hyojiracebangou] ==
        0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 0.5 seconds
      currentGhensuu.mode = 400;
      await currentGhensuu.save(); // 変更を保存
      widget.onAdvanceMode?.call(); // 親画面へのコールバック
    }
  }
}

// SwiftUIのProgressViewに似たシンプルなウィジェット
class ProgressView extends StatelessWidget {
  const ProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("しばらくお待ちください", style: TextStyle(color: HENSUU.textcolor)),
        const SizedBox(height: 10),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          strokeWidth: 4.0,
        ),
      ],
    );
  }
}
