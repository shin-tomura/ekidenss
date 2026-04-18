// lib/screens/latest_screen_contents/mode0700_content.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart'; // 時間・日付ユーティリティをインポート
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_kukanresult.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';
import 'package:ekiden/screens/Modal_TodayChangeList.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:ekiden/screens/Modal_kekkagaiyou.dart';
import 'package:ekiden/screens/Modal_kukanhaitiANDresult.dart';
import 'package:ekiden/screens/Modal_GakurenKukan.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_tuukajunisuii.dart';
import 'package:ekiden/screens/Modal_timesasuii.dart';

// モーダルビューのプレースホルダー
// 実際にはこれらのファイルを別途作成する必要があります
//import 'package:your_project_name/modals/modal_zenhan_kekka_view.dart';
//import 'package:your_project_name/modals/modal_kouhan_kekka_view.dart';
//import 'package:your_project_name/modals/modal_kukanshou_view.dart';

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

// ModalZenhanKekkaView.dart の例
class ModalZenhanKekkaView extends StatelessWidget {
  const ModalZenhanKekkaView({super.key}); // const コンストラクタ

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    // SenshuDataはここでは直接使われていないが、SwiftUIコードに合わせてインポートは残す
    // final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          // データがまだロードされていないか、存在しない場合の表示
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '前半区間成績',
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

        // Swiftの @State private var racebangou:Int=2 に相当
        // このモーダルではracebangouが常に2なので、定数として直接使用
        const int racebangou = 2;

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();

            // データのindexとidは一致していない問題なので (idjununivdata)
            final List<UnivData> idJunUnivData = allUnivData
              ..sort((a, b) => a.id.compareTo(b.id));

            // timejununivdata: [UnivData]
            // time_taikai_total[4] でソート
            final List<UnivData> timeJunUnivData = idJunUnivData
              ..sort(
                (a, b) =>
                    a.time_taikai_total[4].compareTo(b.time_taikai_total[4]),
              );

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
              appBar: AppBar(
                title: const Text(
                  '前半区間成績',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
                foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  // SwiftのSpacer() に相当するが、ここでは画面上部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey), // Divider

                  Expanded(
                    // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0), // 全体的なパディング
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          Text(
                            "前半区間成績",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16), // スペース
                          // ForEach(0..<timejununivdata.count, id: \.self) に相当
                          for (
                            int i_timejun = 0;
                            i_timejun < timeJunUnivData.length;
                            i_timejun++
                          )
                            if (timeJunUnivData[i_timejun]
                                    .taikaientryflag[racebangou] ==
                                1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Text(
                                  "${i_timejun + 1}位 ${timeJunUnivData[i_timejun].name} ${TimeDate.timeToJikanFunByouString(timeJunUnivData[i_timejun].time_taikai_total[4])}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                  // SwiftのSpacer() に相当するが、ここでは画面下部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey), // Divider
                  // 戻るボタン (HStackに相当)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // モーダルを閉じる
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue, // Swiftの.background(.blue)
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
                        "戻る",
                        style: TextStyle(
                          fontSize: HENSUU
                              .fontsize_honbun, // Swiftの.font(.headline)に相当
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

class ModalKouhanKekkaView extends StatelessWidget {
  const ModalKouhanKekkaView({super.key}); // const コンストラクタ

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    // SenshuDataはここでは直接使われていないが、SwiftUIコードに合わせてインポートは残す
    // final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          // データがまだロードされていないか、存在しない場合の表示
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '後半区間成績',
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

        // Swiftの @State private var racebangou:Int=2 に相当
        // このモーダルではracebangouが常に2なので、定数として直接使用
        const int racebangou = 2;

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();

            // データのindexとidは一致していない問題なので (idjununivdata)
            final List<UnivData> idJunUnivData = allUnivData
              ..sort((a, b) => a.id.compareTo(b.id));

            // timejununivdata: [UnivData]
            // Swift: $0.time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou]-1] - $0.time_taikai_total[4] でソート
            final List<UnivData> timeJunUnivData = idJunUnivData
              ..sort((a, b) {
                final double aKouhanTime =
                    a.time_taikai_total[currentGhensuu
                            .kukansuu_taikaigoto[racebangou] -
                        1] -
                    a.time_taikai_total[4];
                final double bKouhanTime =
                    b.time_taikai_total[currentGhensuu
                            .kukansuu_taikaigoto[racebangou] -
                        1] -
                    b.time_taikai_total[4];
                return aKouhanTime.compareTo(bKouhanTime);
              });

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
              appBar: AppBar(
                title: const Text(
                  '後半区間成績',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
                foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  // SwiftのSpacer() に相当するが、ここでは画面上部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey), // Divider

                  Expanded(
                    // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0), // 全体的なパディング
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          Text(
                            "後半区間成績",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16), // スペース
                          // ForEach(0..<timejununivdata.count, id: \.self) に相当
                          for (
                            int i_timejun = 0;
                            i_timejun < timeJunUnivData.length;
                            i_timejun++
                          )
                            if (timeJunUnivData[i_timejun]
                                    .taikaientryflag[racebangou] ==
                                1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Text(
                                  // Swift: timejununivdata[i_timejun].time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou]-1] - timejununivdata[i_timejun].time_taikai_total[4]
                                  "${i_timejun + 1}位 ${timeJunUnivData[i_timejun].name} ${TimeDate.timeToJikanFunByouString(timeJunUnivData[i_timejun].time_taikai_total[currentGhensuu.kukansuu_taikaigoto[racebangou] - 1] - timeJunUnivData[i_timejun].time_taikai_total[4])}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                  // SwiftのSpacer() に相当するが、ここでは画面下部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey), // Divider
                  // 戻るボタン (HStackに相当)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // モーダルを閉じる
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue, // Swiftの.background(.blue)
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
                        "戻る",
                        style: TextStyle(
                          fontSize: HENSUU
                              .fontsize_honbun, // Swiftの.font(.headline)に相当
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

class ModalKukanshouView extends StatelessWidget {
  const ModalKukanshouView({super.key}); // const コンストラクタ

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          // データがまだロードされていないか、存在しない場合の表示
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '各区間上位5名',
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
            final List<UnivData> idJunUnivData = univdataBox.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id));

            return ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),
              builder: (context, senshudataBox, _) {
                final List<SenshuData> allSenshuData = senshudataBox.values
                    .toList();

                // 各順位ごとの選手データをフィルタリング
                // Swiftの kukanshoufilteredsenshudata, kukanshoufilteredsenshudata2... に相当
                List<List<SenshuData>> filteredSenshuByRank = List.generate(5, (
                  index,
                ) {
                  return allSenshuData.where((senshu) {
                    // gakunen-1 のインデックスが有効かチェック
                    if (senshu.gakunen - 1 < 0 ||
                        senshu.gakunen - 1 >=
                            senshu
                                .kukanjuni_race[currentGhensuu.hyojiracebangou]
                                .length) {
                      return false; // 無効なインデックスは除外
                    }
                    return senshu.kukanjuni_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1] ==
                        index;
                  }).toList();
                });

                // 各区間の順位リストを生成するヘルパー関数
                Widget _buildKukanRankList(int kukanIndex) {
                  List<Widget> rankWidgets = [];
                  rankWidgets.add(const SizedBox(height: 16)); // 区間間のスペース
                  rankWidgets.add(
                    Text(
                      "${kukanIndex + 1}区",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                  rankWidgets.add(const SizedBox(height: 8)); // 区間タイトルと内容のスペース

                  for (int rank = 0; rank < 5; rank++) {
                    // 1位から5位まで
                    final List<SenshuData> senshuListForRank =
                        filteredSenshuByRank[rank];

                    // 当該区間、当該順位の選手をフィルタリング
                    final List<SenshuData> currentKukanRankSenshu =
                        senshuListForRank.where((senshu) {
                          // entrykukan_race のインデックスが有効かチェック
                          if (senshu.gakunen - 1 < 0 ||
                              senshu.gakunen - 1 >=
                                  senshu
                                      .entrykukan_race[currentGhensuu
                                          .hyojiracebangou]
                                      .length) {
                            return false; // 無効なインデックスは除外
                          }
                          return senshu.entrykukan_race[currentGhensuu
                                  .hyojiracebangou][senshu.gakunen - 1] ==
                              kukanIndex;
                        }).toList();

                    for (var senshu in currentKukanRankSenshu) {
                      rankWidgets.add(
                        const SizedBox(height: 4),
                      ); // 各選手の情報の上のスペース
                      rankWidgets.add(
                        Wrap(
                          // SwiftUIのHStackに相当
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            Text(
                              "${rank + 1}位 ",
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                            Text(
                              TimeDate.timeToFunByouString(
                                senshu.kukantime_race[currentGhensuu
                                    .hyojiracebangou][senshu.gakunen - 1],
                              ),
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                            Text(
                              senshu.name,
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                            Text(
                              "(${senshu.gakunen}年)",
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                            Text(
                              idJunUnivData[senshu.univid].name,
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: HENSUU.fontsize_honbun,
                              ),
                            ),
                            // 区間新の表示
                            if ((currentGhensuu.year > 2 ||
                                    (currentGhensuu.year == 2 &&
                                        currentGhensuu.month >= 4)) &&
                                ((currentGhensuu.hyojiracebangou >= 0 &&
                                        currentGhensuu.hyojiracebangou <= 2) ||
                                    currentGhensuu.hyojiracebangou == 5) &&
                                senshu.chokuzentaikai_zentaikukansinflag == 1)
                              Text(
                                "*区間新",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rankWidgets,
                  );
                }

                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
                  appBar: AppBar(
                    title: const Text(
                      '各区間上位5名',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
                    foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
                  ),
                  body: Column(
                    // SwiftUIのVStackに相当
                    children: <Widget>[
                      const Divider(color: Colors.grey), // Divider

                      Expanded(
                        // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0), // 全体的なパディング
                          child: Column(
                            // LazyVStackに相当
                            crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                            children: <Widget>[
                              Text(
                                "区間上位5名",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16), // スペース
                              // ForEach(100000..<gh[0].kukansuu_taikaigoto[gh[0].hyojiracebangou]+100000, id: \.self) に相当
                              for (
                                int i_kukan_offset = 100000;
                                i_kukan_offset <
                                    currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou] +
                                        100000;
                                i_kukan_offset++
                              )
                                _buildKukanRankList(
                                  i_kukan_offset - 100000,
                                ), // オフセットを戻して実際の区間インデックスを渡す
                            ],
                          ),
                        ),
                      ),

                      const Divider(color: Colors.grey), // Divider
                      // 戻るボタン (HStackに相当)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // モーダルを閉じる
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue, // Swiftの.background(.blue)
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
                            "戻る",
                            style: TextStyle(
                              fontSize: HENSUU
                                  .fontsize_honbun, // Swiftの.font(.headline)に相当
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
      },
    );
  }
}

class Mode0700Content extends StatefulWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0700Content({super.key, required this.ghensuu, this.onAdvanceMode});

  @override
  State<Mode0700Content> createState() => _Mode0700ContentState();
}

class _Mode0700ContentState extends State<Mode0700Content> {
  // モーダルの表示状態を管理するState
  //bool _isShowingModalZenhanKukan = false;
  //bool _isShowingModalKouhanKukan = false;
  //bool _isShowingModalKukanshou = false;

  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
  }

  // MARK: - 計算プロパティに相当するヘルパー関数

  List<SenshuData> _getIdJunSenshuData(List<SenshuData> allSenshuData) {
    return allSenshuData.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  List<UnivData> _getIdJunUnivData(List<UnivData> allUnivData) {
    return allUnivData.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  List<SenshuData> _getUnivFilteredSenshuData(
    List<SenshuData> allSenshuData,
    int myUnivId,
  ) {
    return allSenshuData.where((s) => s.univid == myUnivId).toList();
  }

  List<SenshuData> _getGakunenJunUnivFilteredSenshuData(
    List<SenshuData> univFilteredSenshuData,
  ) {
    return univFilteredSenshuData.toList()..sort(
      (a, b) => (b.gakunen * 10000 + b.id).compareTo(a.gakunen * 10000 + a.id),
    );
  }

  List<SenshuData> _getTimeJunUnivFilteredSenshuData(
    List<SenshuData> univFilteredSenshuData,
  ) {
    return univFilteredSenshuData.toList()
      ..sort((a, b) => a.time_taikai_total.compareTo(b.time_taikai_total));
  }

  /*List<UnivData> _getInkarePointTotalJunUnivData(List<UnivData> idJunUnivData) {
    return idJunUnivData.toList()..sort((a, b) {
      final totalPointA = a.inkarepoint.fold(
        0,
        (sum, element) => sum + element,
      );
      final totalPointB = b.inkarepoint.fold(
        0,
        (sum, element) => sum + element,
      );
      if (totalPointA == totalPointB) {
        return b.r.compareTo(a.r); // rが大きい方が上位 (Swiftの > に対応)
      } else {
        return totalPointB.compareTo(totalPointA); // ポイントが高い方が上位
      }
    });
  }*/
  List<UnivData> _getInkarePointTotalJunUnivData(List<UnivData> idJunUnivData) {
    // リストをコピーし、sortメソッドを適用
    return idJunUnivData.toList()..sort((a, b) {
      // a.juni_race[9][0]とb.juni_race[9][0]を直接比較してソート
      // 小さい値が上位になるように並べ替える
      return a.juni_race[9][0].compareTo(b.juni_race[9][0]);
    });
  }

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  // ★ テキストデータを画像化して共有するメソッド ★
  Future<void> _exportTextAsImage(String reportText, String title) async {
    setState(() => _isExporting = true);

    try {
      // 1. ウィジェットの定義
      final exportWidget = MediaQuery(
        // ★重要：端末のフォントサイズ設定を無視して1.0倍に固定する
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling, // Flutter 3.16以降
          // もし古いバージョンの場合は textScaleFactor: 1.0 を使用
        ),
        child: Material(
          color: HENSUU.backgroundcolor,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white54, thickness: 1),
                const SizedBox(height: 15),
                Text(
                  reportText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white24, thickness: 1),
                const Text(
                  "Generated by 箱庭小駅伝SS",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

      // 2. キャプチャ設定
      // 文字サイズが固定されたので、高さの計算も安定します
      double calculatedHeight = (reportText.split('\n').length * 40.0) + 300;

      final image = await _screenshotController.captureFromWidget(
        exportWidget,
        pixelRatio: 2.0,
        context: context,
        targetSize: Size(400, calculatedHeight),
        delay: const Duration(milliseconds: 200),
      );

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(imagePath);
      await file.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(imagePath)], text: '大会報告 #箱庭小駅伝SS'),
      );
    } catch (e) {
      debugPrint("Text Export Error: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          body: ValueListenableBuilder<Box<Ghensuu>>(
            valueListenable: _ghensuuBox.listenable(),
            builder: (context, ghensuuBox, _) {
              final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');

              if (currentGhensuu == null) {
                return const Center(
                  child: CircularProgressIndicator(color: HENSUU.textcolor),
                );
              }

              return ValueListenableBuilder<Box<SenshuData>>(
                valueListenable: _senshuBox.listenable(),
                builder: (context, senshuDataBox, _) {
                  final List<SenshuData> allSenshuData = senshuDataBox.values
                      .toList();
                  final List<SenshuData> idJunSenshuData = _getIdJunSenshuData(
                    allSenshuData,
                  );

                  return ValueListenableBuilder<Box<UnivData>>(
                    valueListenable: _univBox.listenable(),
                    builder: (context, univDataBox, _) {
                      final List<UnivData> allUnivData = univDataBox.values
                          .toList();
                      final List<UnivData> idJunUnivData = _getIdJunUnivData(
                        allUnivData,
                      );

                      final List<SenshuData> univFilteredSenshuData =
                          _getUnivFilteredSenshuData(
                            allSenshuData,
                            currentGhensuu.MYunivid,
                          );
                      final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                          _getGakunenJunUnivFilteredSenshuData(
                            univFilteredSenshuData,
                          );
                      final List<SenshuData> timeJunUnivFilteredSenshuData =
                          _getTimeJunUnivFilteredSenshuData(
                            univFilteredSenshuData,
                          );

                      final List<UnivData> inkarepointTotalJunUnivData =
                          _getInkarePointTotalJunUnivData(idJunUnivData);

                      // 進むボタンのアクション
                      void advanceGameMode() async {
                        widget.onAdvanceMode?.call(); // 親のコールバックを呼び出す
                        // ここでのcurrentGhensuu.save()は、親のonAdvanceModeがモード変更後に保存すると仮定
                      }

                      void _showConfirmationDialog(BuildContext context) {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text("合宿終了確認"),
                              content: const Text(
                                "本当に合宿を終了しますか？",
                                style: const TextStyle(color: Colors.black),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("キャンセル"),
                                  onPressed: () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(); // ダイアログを閉じる
                                  },
                                ),
                                TextButton(
                                  child: const Text("終了する"),
                                  onPressed: () {
                                    // ここで合宿終了の処理を実行
                                    // 例: advanceGameMode(); や navigator.pushReplacementNamed(...); など
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(); // ダイアログを閉じる
                                    // 実際の終了処理をここに記述
                                    print("合宿が終了しました。");
                                    advanceGameMode();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }

                      final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>(
                        'gakurenSenshuBox',
                      );
                      final gakurensenshudata = gakurensenshuBox.values
                          .toList();
                      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
                      final KantokuData kantoku = kantokuBox.get(
                        'KantokuData',
                      )!;

                      return Column(
                        children: [
                          // MARK: ヘッダー部分
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              // 全体を左右に配置するためにRowを使用
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween, // 両端に要素を配置
                              children: [
                                // ここをExpandedで囲むことで、残りのスペースをテキスト群が利用
                                Expanded(
                                  child: Column(
                                    // テキスト群を左寄せで2行にまとめるためのColumn
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // Column内の要素を左寄せ
                                    children: [
                                      Row(
                                        // 1行目のテキスト
                                        children: [
                                          Text(
                                            _getCombinedDifficultyText(
                                              kantoku,
                                              currentGhensuu,
                                            ), // `易` の条件が明示的になりました
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ), // テキスト間のスペース
                                          // テキストが長い場合のはみ出し対策
                                          Flexible(
                                            // テキストが長くなったら折り返すか、省略する
                                            child: Text(
                                              "${currentGhensuu.year}年${currentGhensuu.month}月${TimeDate.dayToString(currentGhensuu.day)}",
                                              style: const TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                              overflow: TextOverflow
                                                  .ellipsis, // はみ出す場合は「...」
                                              maxLines: 1, // 1行に制限
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ), // 1行目と2行目の間のスペース
                                      Row(
                                        // 2行目のテキスト
                                        children: [
                                          Expanded(
                                            // 追加: テキストが利用可能なスペースを占有し、省略表示を可能にする
                                            child: Text(
                                              "金${currentGhensuu.goldenballsuu} 銀${currentGhensuu.silverballsuu}", // 金と銀のテキストを結合
                                              style: const TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                              maxLines: 1, // 追加: テキストを1行に制限
                                              overflow: TextOverflow
                                                  .ellipsis, // 追加: 1行に収まらない場合に"..."で省略
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // ボタンは変わらず右端に配置
                                ElevatedButton(
                                  onPressed: () {
                                    // 日付の条件をチェック
                                    if ((currentGhensuu.month == 7 &&
                                            currentGhensuu.day == 15) &&
                                        (currentGhensuu.goldenballsuu >= 10 ||
                                            currentGhensuu.silverballsuu >=
                                                10)) {
                                      // 7月15日の場合、確認ダイアログを表示
                                      _showConfirmationDialog(
                                        context,
                                      ); // contextを渡す必要があります
                                    } else {
                                      // それ以外の場合は通常通りゲームを進める
                                      advanceGameMode();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HENSUU.buttonColor,
                                    foregroundColor: HENSUU.buttonTextColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize:
                                        Size.zero, // サイズが自動調整されるように最小サイズを0に
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: HENSUU.fontsize_honbun,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: Text(
                                    ((currentGhensuu.month == 7 &&
                                                currentGhensuu.day == 15) &&
                                            (currentGhensuu.goldenballsuu >=
                                                    10 ||
                                                currentGhensuu.silverballsuu >=
                                                    10))
                                        ? "合宿終了"
                                        : "進む＞＞",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: HENSUU.textcolor),

                          // MARK: メインコンテンツ (ScrollView)
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 春の成長 / 夏合宿 の結果表示
                                    if (currentGhensuu.month == 4 &&
                                        currentGhensuu.day == 25)
                                      const Text(
                                        "選手が成長しました。選手は春と夏の２回成長します。\n\n来月は対校戦が開催されます。なお、対校戦の総合ポイント(5千・1万・ハーフの合計得点)の目標順位は全大学とも常に8位です。",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      )
                                    else if ((currentGhensuu.month == 7 &&
                                            currentGhensuu.day == 15) &&
                                        (currentGhensuu.goldenballsuu >= 10 ||
                                            currentGhensuu.silverballsuu >= 10))
                                      const Text(
                                        "夏合宿です！！\n\n選手画面下部の「金特訓」「銀特訓」から各選手の個性を伸ばしましょう！\n\n「金特訓」「銀特訓」はこの時期にしかできません。",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      )
                                    else if (currentGhensuu.year == 1 &&
                                        currentGhensuu.month == 7 &&
                                        currentGhensuu.day == 15)
                                      const Text(
                                        "選手が成長しました。選手は春と夏の２回成長します。\nなお、金か銀が10以上あれば、この時期は夏合宿になります。",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      )
                                    else if (currentGhensuu.month == 7 &&
                                        currentGhensuu.day == 15)
                                      const Text(
                                        "金銀の量が足りません。合宿は終了です。お疲れ様でした。",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      )
                                    // レース結果表示
                                    else ...[
                                      // 各種記録会・トライアルの結果タイトル
                                      if (currentGhensuu.hyojiracebangou >=
                                              10 &&
                                          currentGhensuu.hyojiracebangou <= 17)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRaceTitle(
                                              currentGhensuu.hyojiracebangou,
                                            ),
                                            // 個人順位 (非学内・非個人記録会)
                                            if (!(currentGhensuu
                                                        .hyojiracebangou >=
                                                    13 &&
                                                currentGhensuu
                                                        .hyojiracebangou <=
                                                    16))
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "個人順位",
                                                    style: TextStyle(
                                                      color: HENSUU.textcolor,
                                                      //fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  _buildIndividualRankList(
                                                    idJunSenshuData,
                                                    currentGhensuu,
                                                    idJunUnivData,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ), // ★コンマを追加★
                                      // 対校戦結果 (hyojiracebangou 6-8)
                                      if (currentGhensuu.hyojiracebangou >= 6 &&
                                          currentGhensuu.hyojiracebangou <= 8)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRaceTitle(
                                              currentGhensuu.hyojiracebangou,
                                            ),
                                            const Text(
                                              "個人順位",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            _buildIndividualRankList(
                                              idJunSenshuData,
                                              currentGhensuu,
                                              idJunUnivData,
                                              limit: 8,
                                            ), // 上位8名表示
                                            const Text(
                                              "個人8位までの所属大学にポイントが与えられました(1位360p、2位359p、3位358p...360位1p)",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                            ),
                                            const Text(
                                              "個人8位までの所属大学の名声が高まりました",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              currentGhensuu.hyojiracebangou ==
                                                      8
                                                  ? "最終ポイント総合順位"
                                                  : "ここまでのポイント総合順位",
                                              style: const TextStyle(
                                                color: HENSUU.textcolor,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "同点の場合には抽選で順位を決定しました",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                            ),
                                            _buildUniversityRankList(
                                              inkarepointTotalJunUnivData,
                                              currentGhensuu,
                                            ),
                                            if (currentGhensuu
                                                    .hyojiracebangou ==
                                                8)
                                              const Text(
                                                "上位８大学の名声が高まりました",
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              ),
                                          ],
                                        ), // ★コンマを追加★
                                      // 学内個人順位 (非学内・非個人記録会)
                                      if ((currentGhensuu.hyojiracebangou >=
                                                  6 &&
                                              currentGhensuu.hyojiracebangou <=
                                                  17) &&
                                          currentGhensuu.hyojiracebangou != 9)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "\n自分の大学の個人の成績",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            _buildIndividualRankListMYuniv(
                                              timeJunUnivFilteredSenshuData,
                                              currentGhensuu,
                                              idJunUnivData,
                                            ),
                                          ],
                                        ), // ★コンマを追加★
                                      // 駅伝結果 (hyojiracebangou 0-4)
                                      if (currentGhensuu.hyojiracebangou >= 0 &&
                                          currentGhensuu.hyojiracebangou <= 5)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRaceTitle(
                                              currentGhensuu.hyojiracebangou,
                                            ),
                                            // 「不出場です」メッセージは条件付きで表示
                                            if (idJunUnivData[currentGhensuu
                                                        .MYunivid]
                                                    .taikaientryflag[currentGhensuu
                                                    .hyojiracebangou] ==
                                                0)
                                              Text(
                                                "${idJunUnivData[currentGhensuu.MYunivid].name}大学は不出場です",
                                                style: const TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              ), // ★コンマを追加★

                                            if (currentGhensuu
                                                    .hyojiracebangou <=
                                                5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '全大学結果概要', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalEkidenResultListView(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "全大学結果概要",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    2 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '区間コース確認', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return ModalCourseshoukaiView(
                                                            racebangou:
                                                                currentGhensuu
                                                                    .hyojiracebangou,
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "区間コース確認",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    2 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '区間配置確認', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return ModalKukanHaitiView(
                                                            targetUnivid:
                                                                currentGhensuu
                                                                    .MYunivid,
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "区間配置確認",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    4 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '区間配置結果', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalKukanHaitiResultView(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "区間配置結果",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    3 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '順位推移表', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalRankTransitionView(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "順位推移表",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),
                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    3 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        'レース分析チャート', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalTimeDifferenceGraph(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "レース分析チャート",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (idJunUnivData[currentGhensuu
                                                            .MYunivid]
                                                        .taikaientryflag[currentGhensuu
                                                        .hyojiracebangou] ==
                                                    1 &&
                                                currentGhensuu
                                                        .hyojiracebangou !=
                                                    4)
                                              // ★ ここに画像出力ボタンを追加 ★
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _exportTextAsImage(
                                                      idJunUnivData[10]
                                                          .name_tanshuku,
                                                      "大会結果報告",
                                                    ),
                                                icon: const Icon(
                                                  Icons.image_outlined,
                                                  color: Colors.blue,
                                                ),
                                                label: const Text(
                                                  "自大学の結果を画像出力",
                                                  style: TextStyle(
                                                    color: HENSUU.LinkColor,
                                                  ),
                                                ),
                                              ),

                                            if (idJunUnivData[currentGhensuu
                                                            .MYunivid]
                                                        .taikaientryflag[currentGhensuu
                                                        .hyojiracebangou] ==
                                                    1 &&
                                                currentGhensuu
                                                        .hyojiracebangou !=
                                                    4)
                                              Text(
                                                "${idJunUnivData[10].name_tanshuku}",
                                                style: const TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              ),

                                            // ここから、常に表示される「総合成績」関連のウィジェット
                                            const Text(
                                              "総合成績",
                                              style: TextStyle(
                                                color: HENSUU.textcolor,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (currentGhensuu
                                                        .hyojiracebangou ==
                                                    2 &&
                                                gakurensenshudata.isNotEmpty)
                                              _buildTotalRankList_shougatu(
                                                idJunUnivData,
                                                currentGhensuu,
                                              )
                                            else
                                              _buildTotalRankList(
                                                idJunUnivData,
                                                currentGhensuu,
                                              ),
                                            // ここから、hyojiracebangou に応じて表示されるメッセージ
                                            // 各条件のTextウィジェットの後にコンマを付けて、リストの要素として認識させます。
                                            if (currentGhensuu
                                                    .hyojiracebangou ==
                                                1)
                                              const Text(
                                                "8位以内の大学は来年のシード権を獲得しました",
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              )
                                            else if (currentGhensuu
                                                    .hyojiracebangou ==
                                                2)
                                              const Text(
                                                "10位以内の大学は来年のシード権と10月駅伝出場権を獲得しました",
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              )
                                            else if (currentGhensuu
                                                    .hyojiracebangou ==
                                                3)
                                              const Text(
                                                "7位以内の大学は11月駅伝出場権を獲得しました",
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              )
                                            else if (currentGhensuu
                                                    .hyojiracebangou ==
                                                4)
                                              const Text(
                                                "各チーム上位10名のタイムの合計です。\n10位以内の大学は正月駅伝出場権を獲得しました",
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              ), // ★コンマを追加★

                                            const SizedBox(height: 10), // スペース
                                            // 駅伝のみ表示されるモーダルボタン
                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    2 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  LinkButtons(
                                                    context,
                                                    currentGhensuu,
                                                  ),
                                                ],
                                              ),
                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    4 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '個人順位タイム表示', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalKukanResultListView(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "個人順位タイム表示",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),

                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    4 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '通過順位タイム表示', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return const ModalKukanResultListViewPass(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "通過順位タイム表示",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ),
                                            if (currentGhensuu
                                                        .hyojiracebangou <=
                                                    2 ||
                                                currentGhensuu
                                                        .hyojiracebangou ==
                                                    5)
                                              TextButton(
                                                onPressed: () {
                                                  // ★こちらも showGeneralDialog に変更★
                                                  showGeneralDialog(
                                                    context: context,
                                                    barrierColor: Colors.black
                                                        .withOpacity(
                                                          0.8,
                                                        ), // モーダルの背景色
                                                    barrierDismissible:
                                                        true, // 背景タップで閉じられるようにする
                                                    barrierLabel:
                                                        '当日変更一覧', // アクセシビリティ用ラベル
                                                    transitionDuration:
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ), // アニメーション時間
                                                    pageBuilder:
                                                        (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                        ) {
                                                          // ここに表示したいモーダルのウィジェットを指定
                                                          return ModalTodayChangeListView(); // const を追加
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
                                                            opacity:
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeOut,
                                                                ),
                                                            child: child,
                                                          );
                                                        },
                                                  );
                                                },
                                                child: Text(
                                                  "当日変更一覧",
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      0,
                                                      255,
                                                      0,
                                                    ),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        HENSUU.textcolor,
                                                  ),
                                                ),
                                              ), // ★コンマを追加★
                                            // 自分の大学のここまでの区間ごとの成績
                                            if (currentGhensuu
                                                    .hyojiracebangou ==
                                                4) // 正月駅伝予選
                                              if (idJunUnivData[currentGhensuu
                                                          .MYunivid]
                                                      .taikaientryflag[currentGhensuu
                                                      .hyojiracebangou] ==
                                                  1)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${idJunUnivData[currentGhensuu.MYunivid].name}大学の選手の成績",
                                                      style: const TextStyle(
                                                        color: HENSUU.textcolor,
                                                      ),
                                                    ),
                                                    Text(
                                                      "簡略版",
                                                      style: const TextStyle(
                                                        color: HENSUU.textcolor,
                                                      ),
                                                    ),
                                                    _buildMyUnivSenshuResults_kanryaku(
                                                      gakunenJunUnivFilteredSenshuData,
                                                      currentGhensuu,
                                                      idJunUnivData,
                                                    ),
                                                    Text(''),
                                                    Text(
                                                      "詳細版",
                                                      style: const TextStyle(
                                                        color: HENSUU.textcolor,
                                                      ),
                                                    ),
                                                    _buildMyUnivSenshuResults(
                                                      gakunenJunUnivFilteredSenshuData,
                                                      currentGhensuu,
                                                      idJunUnivData,
                                                    ),
                                                    /*
                                                Text(
                                                  "※「[参考]ペース変動対応力とロード適性について、フリー走行と比べてのタイム得」が、集団のペースによるタイム損よりも大きければ、その選手についてはフリー走行でなくて集団走をして結果的によかったということになります",
                                                  style: const TextStyle(
                                                    color: HENSUU.textcolor,
                                                  ),
                                                ),
                                                Text(
                                                  "\n※「[参考]ペース変動対応力とロード適性について、フリー走行と比べてのタイム得」は、計算上は基本走力差の方に含まれていて、補正計には含まれていません。",
                                                  style: const TextStyle(
                                                    color: HENSUU.textcolor,
                                                  ),
                                                ),*/
                                                  ],
                                                ), // ★コンマを追加★
                                            if (currentGhensuu
                                                    .hyojiracebangou !=
                                                4) // 正月駅伝予選以外
                                              if (idJunUnivData[currentGhensuu
                                                          .MYunivid]
                                                      .taikaientryflag[currentGhensuu
                                                      .hyojiracebangou] ==
                                                  1)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "\n\n${idJunUnivData[currentGhensuu.MYunivid].name}大学の選手の成績\n",
                                                      style: const TextStyle(
                                                        color: HENSUU.textcolor,
                                                      ),
                                                    ),
                                                    _buildMyUnivSectionResults(
                                                      gakunenJunUnivFilteredSenshuData,
                                                      currentGhensuu,
                                                      idJunUnivData,
                                                    ),
                                                  ],
                                                ), // ★コンマを追加★
                                          ],
                                        ),
                                      // ★このColumnの閉じ括弧の直後にコンマを追加★
                                      if (gakurensenshudata.isNotEmpty &&
                                          currentGhensuu.hyojiracebangou == 2)
                                        _buildGakurenResults(
                                          currentGhensuu,
                                          idJunUnivData,
                                        ),
                                    ], // ★この閉じ角括弧（else ...[ の終わり）の直後にコンマを追加★
                                  ], // ★この閉じ角括弧（Columnのchildrenの終わり）の直後にコンマを追加★
                                ), // Column の終わり
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          // MARK: モーダルシート
          //bottomSheet: _isShowingModalZenhanKukan ? ModalZenhanKekkaView() : null,
          // ...他のモーダルも同様に制御
          // もし複数のモーダルを同時に表示する可能性があるなら、Navigator.push を使うべきです
          // ここではsetStateで表示を切り替えるため、同時に一つだけ表示される想定
        ),
        // ★ 保存処理中に画面を暗くしてぐるぐるを出す
        if (_isExporting)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // MARK: - ヘルパーウィジェットの作成

  Widget _buildRaceTitle(int raceBangou) {
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    String title = "";
    if (raceBangou == 10) {
      title = "5000mトラック記録会結果";
    } else if (raceBangou == 11) {
      title = "10000mトラック記録会結果";
    } else if (raceBangou == 12) {
      title = "市民ハーフマラソン大会結果";
    } else if (raceBangou == 13) {
      title = "【学内】登り10kmトライアル結果";
    } else if (raceBangou == 14) {
      title = "【学内】下り10kmトライアル結果";
    } else if (raceBangou == 15) {
      title = "【学内】ロード10km結果";
    } else if (raceBangou == 16) {
      title = "【学内】クロスカントリーコース10km結果";
    } else if (raceBangou == 17) {
      title = "フルマラソン大会結果";
    } else if (raceBangou == 6) {
      title = "対校戦5000m結果";
    } else if (raceBangou == 7) {
      title = "対校戦10000m結果";
    } else if (raceBangou == 8) {
      title = "対校戦ハーフマラソン結果";
    } else if (raceBangou == 0) {
      title = "10月駅伝結果";
    } else if (raceBangou == 1) {
      title = "11月駅伝結果";
    } else if (raceBangou == 2) {
      title = "正月駅伝結果";
    } else if (raceBangou == 3) {
      title = "11月駅伝予選結果";
    } else if (raceBangou == 4) {
      title = "正月駅伝予選結果";
    } else if (raceBangou == 5) {
      title = sortedUnivData[0].name_tanshuku;
    }
    return Text(
      title,
      style: TextStyle(
        color: HENSUU.textcolor,
        //fontWeight: FontWeight.bold,
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  Widget _buildIndividualRankListMYuniv(
    List<SenshuData> timeJunSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData, {
    int? limit,
  }) {
    final displayLimit = limit ?? TEISUU.SENSHUSUU_UNIV; // デフォルトは上位10名

    // 順位でソート
    final sortedByKukanJuni = timeJunSenshuData.toList()
      ..sort((a, b) {
        final aJuni =
            a.kukanjuni_race[currentGhensuu.hyojiracebangou][a.gakunen - 1];
        final bJuni =
            b.kukanjuni_race[currentGhensuu.hyojiracebangou][b.gakunen - 1];
        return aJuni.compareTo(bJuni);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displayLimit, (i) {
        if (i >= sortedByKukanJuni.length)
          return const SizedBox.shrink(); // 範囲外の選手は表示しない

        final senshu = sortedByKukanJuni[i];
        if (senshu.kukanjuni_race[currentGhensuu
                .hyojiracebangou][senshu.gakunen - 1] ==
            TEISUU.DEFAULTJUNI)
          return const SizedBox.shrink(); // デフォルト順位は表示しない

        if (senshu.univid != currentGhensuu.MYunivid)
          return const SizedBox.shrink(); // 自分の大学以外は表示しない

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Wrap(
            children: [
              Text(
                "${senshu.kukanjuni_race[currentGhensuu.hyojiracebangou][senshu.gakunen - 1] + 1}位 ",
                style: TextStyle(color: HENSUU.textcolor),
              ),
              Text(senshu.name, style: TextStyle(color: HENSUU.textcolor)),
              Text(
                "(${senshu.gakunen}年)",
                style: TextStyle(color: HENSUU.textcolor),
              ),
              //Text("$univName ", style: TextStyle(color: HENSUU.textcolor)),
              /*if (currentGhensuu.hyojiracebangou==17)
              Text(
                TimeDate.timeToJikanFunByouString(
                  senshu.kukantime_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1],
                ),
                style: TextStyle(color: HENSUU.textcolor),
              ),
              else
              Text(
                TimeDate.timeToFunByouString(
                  senshu.kukantime_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1],
                ),
                style: TextStyle(color: HENSUU.textcolor),
              ),*/
              currentGhensuu.hyojiracebangou == 17
                  ? Text(
                      TimeDate.timeToJikanFunByouString(
                        senshu.kukantime_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    )
                  : Text(
                      TimeDate.timeToFunByouString(
                        senshu.kukantime_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
              if ((currentGhensuu.hyojiracebangou >= 6 &&
                      currentGhensuu.hyojiracebangou <= 8 &&
                      currentGhensuu.year != 1) ||
                  (currentGhensuu.hyojiracebangou >= 10 &&
                      currentGhensuu.hyojiracebangou <= 12) ||
                  currentGhensuu.hyojiracebangou == 17) ...[
                if (senshu.chokuzentaikai_pbflag == 1)
                  Text(
                    " PB", // 先頭にスペースを入れて、他のテキストと区切る
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                // ここで三項演算子を使って条件分岐
                senshu.chokuzentaikai_kojinrekidaisinflag == 1
                    ? Text(
                        // 条件が真の場合
                        " 歴代新",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      )
                    : senshu.chokuzentaikai_kojinunivsinflag ==
                          1 // 条件が偽の場合の次の条件
                    ? Text(
                        // 次の条件が真の場合
                        " 学内新",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      )
                    : SizedBox.shrink(), // どちらの条件も偽の場合（何も表示しない場合はSizedBox.shrink()が便利）
              ],
            ],
          ),
        );
      }).where((widget) => widget != const SizedBox.shrink()).toList(),
    );
  }

  Widget _buildIndividualRankList(
    List<SenshuData> timeJunSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData, {
    int? limit,
  }) {
    final displayLimit = limit ?? 10; // デフォルトは上位10名

    // 順位でソート
    final sortedByKukanJuni = timeJunSenshuData.toList()
      ..sort((a, b) {
        final aJuni =
            a.kukanjuni_race[currentGhensuu.hyojiracebangou][a.gakunen - 1];
        final bJuni =
            b.kukanjuni_race[currentGhensuu.hyojiracebangou][b.gakunen - 1];
        return aJuni.compareTo(bJuni);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displayLimit, (i) {
        if (i >= sortedByKukanJuni.length)
          return const SizedBox.shrink(); // 範囲外の選手は表示しない

        final senshu = sortedByKukanJuni[i];
        if (senshu.kukanjuni_race[currentGhensuu
                .hyojiracebangou][senshu.gakunen - 1] ==
            TEISUU.DEFAULTJUNI)
          return const SizedBox.shrink(); // デフォルト順位は表示しない

        // ユニバーシティ名が範囲内かチェック
        final univName = (senshu.univid < idJunUnivData.length)
            ? idJunUnivData[senshu.univid].name
            : "不明な大学";

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Wrap(
            children: [
              Text(
                "${senshu.kukanjuni_race[currentGhensuu.hyojiracebangou][senshu.gakunen - 1] + 1}位 ",
                style: TextStyle(color: HENSUU.textcolor),
              ),
              Text(senshu.name, style: TextStyle(color: HENSUU.textcolor)),
              Text(
                "(${senshu.gakunen}年)",
                style: TextStyle(color: HENSUU.textcolor),
              ),
              Text("$univName ", style: TextStyle(color: HENSUU.textcolor)),
              /*if (currentGhensuu.hyojiracebangou==17)
              Text(
                TimeDate.timeToJikanFunByouString(
                  senshu.kukantime_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1],
                ),
                style: TextStyle(color: HENSUU.textcolor),
              ),
              else
              Text(
                TimeDate.timeToFunByouString(
                  senshu.kukantime_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1],
                ),
                style: TextStyle(color: HENSUU.textcolor),
              ),*/
              currentGhensuu.hyojiracebangou == 17
                  ? Text(
                      TimeDate.timeToJikanFunByouString(
                        senshu.kukantime_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    )
                  : Text(
                      TimeDate.timeToFunByouString(
                        senshu.kukantime_race[currentGhensuu
                            .hyojiracebangou][senshu.gakunen - 1],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
              if ((currentGhensuu.hyojiracebangou >= 6 &&
                      currentGhensuu.hyojiracebangou <= 8 &&
                      currentGhensuu.year != 1) ||
                  (currentGhensuu.hyojiracebangou >= 10 &&
                      currentGhensuu.hyojiracebangou <= 12) ||
                  currentGhensuu.hyojiracebangou == 17) ...[
                if (senshu.chokuzentaikai_kojinrekidaisinflag == 1)
                  Text(
                    " 歴代新",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ],
          ),
        );
      }).where((widget) => widget != const SizedBox.shrink()).toList(),
    );
  }

  Widget _buildUniversityRankList(
    List<UnivData> inkarePointTotalJunUnivData,
    Ghensuu currentGhensuu,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(inkarePointTotalJunUnivData.length, (i) {
        final univ = inkarePointTotalJunUnivData[i];
        final totalPoints = univ.inkarepoint.fold(
          0,
          (sum, element) => sum + element,
        ); // Assuming inkarepoint is List<int>
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            "${i + 1}位 ${univ.name} $totalPoints点",
            style: TextStyle(color: HENSUU.textcolor),
          ),
        );
      }),
    );
  }

  Widget _buildTotalRankList_shougatu(
    List<UnivData> idJunUnivData,
    Ghensuu currentGhensuu,
  ) {
    final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
    final gakurenunivdata = gakurenunivBox.values.toList();

    // 取得した学連選抜の順位 (tuukajuni_taikai)
    // jun_gakurenは0から始まるインデックスの順位（例：1位なら0）
    final int juni_gakuren = gakurenunivdata[0]
        .tuukajuni_taikai[currentGhensuu.nowracecalckukan - 1]; //←この順位を挿入したい
    print("juni_gakuren=${juni_gakuren}");
    // 総合成績はgh[0].juni_race[hyojiracebangou][0]でソートされた順
    final sortedByOverallRank = idJunUnivData.toList()
      ..sort((a, b) {
        final aRank = a.juni_race[currentGhensuu.hyojiracebangou][0];
        final bRank = b.juni_race[currentGhensuu.hyojiracebangou][0];
        return aRank.compareTo(bRank);
      });

    // 順位表のウィジェットリストを格納する
    final List<Widget> rankListWidgets = [];

    // 正式参加の大学のみを抽出したリスト
    final officialEntries = sortedByOverallRank
        .where(
          (univ) => univ.taikaientryflag[currentGhensuu.hyojiracebangou] == 1,
        )
        .toList();

    // オープン参加の大学のデータ
    final gakurenUniv = gakurenunivdata[0];
    final gakurenTotalTime =
        gakurenUniv.time_taikai_total[currentGhensuu
                .kukansuu_taikaigoto[currentGhensuu.hyojiracebangou] -
            1];

    // オープン参加のウィジェットを生成
    final openEntryWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Wrap(
        children: [
          Text(
            // 順位は「OP」として表示
            "OP ${gakurenUniv.name} ${TimeDate.timeToJikanFunByouString(gakurenTotalTime)}",
            style: TextStyle(color: HENSUU.textcolor),
          ),
          // 必要に応じて、オープン参加の大学の新記録表示ロジックも追加可能
        ],
      ),
    );

    // 総合順位リストを生成
    for (int i = 0; i < officialEntries.length; i++) {
      final univ = officialEntries[i];

      // オープン参加の順位（juni_gakuren）の直前（i）に挿入
      // juni_gakurenは0-indexedの順位で、iはofficialEntriesの0-indexedのインデックス
      if (i == juni_gakuren) {
        rankListWidgets.add(openEntryWidget);
      }

      // 正式参加の大学の表示
      final totalTime =
          univ.time_taikai_total[currentGhensuu
                  .kukansuu_taikaigoto[currentGhensuu.hyojiracebangou] -
              1];

      // univ.juni_race[currentGhensuu.hyojiracebangou][0]は0-indexedの順位
      final rankDisplay = univ.juni_race[currentGhensuu.hyojiracebangou][0] + 1;

      rankListWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Wrap(
            children: [
              Text(
                // 順位は+1して表示 (1-indexed)
                "${rankDisplay}位 ${univ.name} ${TimeDate.timeToJikanFunByouString(totalTime)}",
                style: TextStyle(color: HENSUU.textcolor),
              ),
              if (currentGhensuu.year > 2 ||
                  (currentGhensuu.year == 2 && currentGhensuu.month >= 2)) ...[
                // Swiftの!=1年目を考慮
                if ((currentGhensuu.hyojiracebangou >= 0 &&
                        currentGhensuu.hyojiracebangou <= 2) ||
                    currentGhensuu.hyojiracebangou == 5) ...[
                  if (univ.chokuzentaikai_zentaitaikaisinflag == 1)
                    Text(
                      " *大会新",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        //fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (univ.chokuzentaikai_univtaikaisinflag == 1)
                    Text(
                      " *学内新",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ],
            ],
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
      children: rankListWidgets,
    );
  }

  Widget _buildTotalRankList(
    List<UnivData> idJunUnivData,
    Ghensuu currentGhensuu,
  ) {
    // 総合成績はgh[0].juni_race[hyojiracebangou][0]でソートされた順
    final sortedByOverallRank = idJunUnivData.toList()
      ..sort((a, b) {
        final aRank = a.juni_race[currentGhensuu.hyojiracebangou][0];
        final bRank = b.juni_race[currentGhensuu.hyojiracebangou][0];
        return aRank.compareTo(bRank);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sortedByOverallRank.length, (i) {
        final univ = sortedByOverallRank[i];
        if (univ.taikaientryflag[currentGhensuu.hyojiracebangou] == 1) {
          final totalTime =
              univ.time_taikai_total[currentGhensuu
                      .kukansuu_taikaigoto[currentGhensuu.hyojiracebangou] -
                  1];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Wrap(
              children: [
                Text(
                  "${univ.juni_race[currentGhensuu.hyojiracebangou][0] + 1}位 ${univ.name} ${TimeDate.timeToJikanFunByouString(totalTime)}",
                  style: TextStyle(color: HENSUU.textcolor),
                ),
                if (currentGhensuu.year > 2 ||
                    (currentGhensuu.year == 2 &&
                        currentGhensuu.month >= 2)) ...[
                  // Swiftの!=1年目を考慮
                  if ((currentGhensuu.hyojiracebangou >= 0 &&
                          currentGhensuu.hyojiracebangou <= 2) ||
                      currentGhensuu.hyojiracebangou == 5) ...[
                    if (univ.chokuzentaikai_zentaitaikaisinflag == 1)
                      Text(
                        " *大会新",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (univ.chokuzentaikai_univtaikaisinflag == 1)
                      Text(
                        " *学内新",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ],
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).where((widget) => widget != const SizedBox.shrink()).toList(),
    );
  }

  // 自分の大学の選手結果リスト (正月駅伝予選用)
  Widget _buildMyUnivSenshuResults_kanryaku(
    List<SenshuData> gakunenJunUnivFilteredSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData,
  ) {
    // 順位でソート
    final sortedByKukanJuni = gakunenJunUnivFilteredSenshuData.toList()
      ..sort((a, b) {
        final aJuni =
            a.kukanjuni_race[currentGhensuu.hyojiracebangou][a.gakunen - 1];
        final bJuni =
            b.kukanjuni_race[currentGhensuu.hyojiracebangou][b.gakunen - 1];
        return aJuni.compareTo(bJuni);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sortedByKukanJuni.length, (i) {
        final senshu = sortedByKukanJuni[i];
        final iKukanOffset = currentGhensuu
            .hyojiracebangou; // racebangou==4の場合はi_kukan-100000が0になることを考慮

        // チーム目標順位を下回っているかのフラグ (i_kukan-100000-1) のインデックス調整
        // Swiftコードのi_kukan-100000はループ変数なので、ここではiKukanOffsetを使用
        final mokuhyoJuniFlagIndex =
            iKukanOffset - 1; // Swiftコードのi_kukan-100000-1

        // isShowingModalは直接ここでセットせず、ボタンのonPressedでsetStateを呼ぶ
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senshu.entrykukan_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1] ==
                  0)
                Wrap(
                  children: [
                    Text(
                      "${senshu.kukanjuni_race[currentGhensuu.hyojiracebangou][senshu.gakunen - 1] + 1}位 ",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      senshu.name,
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      "(${senshu.gakunen}年)",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      TimeDate.timeToFunByouString(senshu.time_taikai_total),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                  ],
                ),
              /*if (senshu.string_racesetumei.isNotEmpty)
                Text(
                  senshu.string_racesetumei,
                  style: TextStyle(color: HENSUU.textcolor),
                ),*/
              //const Text(""), // Swiftの空のText()に対応
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMyUnivSenshuResults(
    List<SenshuData> gakunenJunUnivFilteredSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData,
  ) {
    // 順位でソート
    final sortedByKukanJuni = gakunenJunUnivFilteredSenshuData.toList()
      ..sort((a, b) {
        final aJuni =
            a.kukanjuni_race[currentGhensuu.hyojiracebangou][a.gakunen - 1];
        final bJuni =
            b.kukanjuni_race[currentGhensuu.hyojiracebangou][b.gakunen - 1];
        return aJuni.compareTo(bJuni);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(sortedByKukanJuni.length, (i) {
        final senshu = sortedByKukanJuni[i];
        final iKukanOffset = currentGhensuu
            .hyojiracebangou; // racebangou==4の場合はi_kukan-100000が0になることを考慮

        // チーム目標順位を下回っているかのフラグ (i_kukan-100000-1) のインデックス調整
        // Swiftコードのi_kukan-100000はループ変数なので、ここではiKukanOffsetを使用
        final mokuhyoJuniFlagIndex =
            iKukanOffset - 1; // Swiftコードのi_kukan-100000-1

        // isShowingModalは直接ここでセットせず、ボタンのonPressedでsetStateを呼ぶ
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senshu.entrykukan_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1] ==
                  0)
                Wrap(
                  children: [
                    Text(
                      "${senshu.kukanjuni_race[currentGhensuu.hyojiracebangou][senshu.gakunen - 1] + 1}位 ",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      senshu.name,
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      "(${senshu.gakunen}年)",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                    Text(
                      TimeDate.timeToFunByouString(senshu.time_taikai_total),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                  ],
                ),
              if (senshu.entrykukan_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1] ==
                  0)
                _buildInstructionResultText(
                  senshu,
                  currentGhensuu,
                  0,
                  idJunUnivData,
                ),
              if (senshu.entrykukan_race[currentGhensuu
                      .hyojiracebangou][senshu.gakunen - 1] ==
                  0)
                if (senshu.string_racesetumei.isNotEmpty)
                  Text(
                    senshu.string_racesetumei,
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
              const Text(""), // Swiftの空のText()に対応
            ],
          ),
        );
      }),
    );
  }

  // 自分の大学の区間ごとの成績 (正月駅伝予選以外)
  Widget _buildMyUnivSectionResults(
    List<SenshuData> gakunenJunUnivFilteredSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ForEachのi_kukanループに相当
        for (
          int iKukan = 0;
          iKukan <
              currentGhensuu.kukansuu_taikaigoto[currentGhensuu
                  .hyojiracebangou];
          iKukan++
        )
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentGhensuu.hyojiracebangou == 3) // 11月駅伝予選は「組目」
                Text(
                  "${iKukan + 1}組目",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    //fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  "${iKukan + 1}区",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              Wrap(
                children: [
                  const Text("通過順位", style: TextStyle(color: HENSUU.textcolor)),
                  if (idJunUnivData[currentGhensuu.MYunivid]
                          .tuukajuni_taikai
                          .length >
                      iKukan) // 範囲チェック
                    Text(
                      "${idJunUnivData[currentGhensuu.MYunivid].tuukajuni_taikai[iKukan] + 1}位",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                  if (idJunUnivData[currentGhensuu.MYunivid]
                          .time_taikai_total
                          .length >
                      iKukan) // 範囲チェック
                    Text(
                      TimeDate.timeToJikanFunByouString(
                        idJunUnivData[currentGhensuu.MYunivid]
                            .time_taikai_total[iKukan],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                ],
              ),
              if (iKukan > 0) // 2区以降
                Wrap(
                  children: [
                    if (currentGhensuu.hyojiracebangou == 3)
                      const Text(
                        "組順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      )
                    else
                      const Text(
                        "区間順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (idJunUnivData[currentGhensuu.MYunivid]
                            .kukanjuni_taikai
                            .length >
                        iKukan) // 範囲チェック
                      Text(
                        "${idJunUnivData[currentGhensuu.MYunivid].kukanjuni_taikai[iKukan] + 1}位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (idJunUnivData[currentGhensuu.MYunivid]
                                .time_taikai_total
                                .length >
                            iKukan &&
                        idJunUnivData[currentGhensuu.MYunivid]
                                .time_taikai_total
                                .length >
                            iKukan - 1) // 範囲チェック
                      Text(
                        TimeDate.timeToFunByouString(
                          idJunUnivData[currentGhensuu.MYunivid]
                                  .time_taikai_total[iKukan] -
                              idJunUnivData[currentGhensuu.MYunivid]
                                  .time_taikai_total[iKukan - 1],
                        ),
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                  ],
                )
              else ...[
                // 1区
                Wrap(
                  children: [
                    if (currentGhensuu.hyojiracebangou == 3)
                      const Text(
                        "組順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      )
                    else
                      const Text(
                        "区間順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (idJunUnivData[currentGhensuu.MYunivid]
                            .kukanjuni_taikai
                            .length >
                        iKukan) // 範囲チェック
                      Text(
                        "${idJunUnivData[currentGhensuu.MYunivid].kukanjuni_taikai[iKukan] + 1}位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (idJunUnivData[currentGhensuu.MYunivid]
                            .time_taikai_total
                            .length >
                        iKukan) // 範囲チェック
                      Text(
                        TimeDate.timeToFunByouString(
                          idJunUnivData[currentGhensuu.MYunivid]
                              .time_taikai_total[iKukan],
                        ),
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                  ],
                ),
              ],
              const Text(""), // スペース
              // 自分の大学の区間内の選手詳細
              for (
                int number = 0;
                number < gakunenJunUnivFilteredSenshuData.length;
                number++
              )
                if (gakunenJunUnivFilteredSenshuData[number]
                        .entrykukan_race[currentGhensuu
                        .hyojiracebangou][gakunenJunUnivFilteredSenshuData[number]
                            .gakunen -
                        1] ==
                    iKukan)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        children: [
                          if (currentGhensuu.year > 2 ||
                              (currentGhensuu.year == 2 &&
                                  currentGhensuu.month >= 4)) ...[
                            if ((currentGhensuu.hyojiracebangou >= 0 &&
                                    currentGhensuu.hyojiracebangou <= 2) ||
                                currentGhensuu.hyojiracebangou == 5) ...[
                              if (gakunenJunUnivFilteredSenshuData[number]
                                      .chokuzentaikai_zentaikukansinflag ==
                                  1)
                                Text(
                                  "*区間新",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (gakunenJunUnivFilteredSenshuData[number]
                                      .chokuzentaikai_univkukansinflag ==
                                  1)
                                Text(
                                  "*学内新",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                      Wrap(
                        children: [
                          Text(
                            "${gakunenJunUnivFilteredSenshuData[number].name} (${gakunenJunUnivFilteredSenshuData[number].gakunen}年)",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (currentGhensuu.hyojiracebangou == 3) // 11月駅伝予選
                        Text(
                          "組内個人順位:${gakunenJunUnivFilteredSenshuData[number].temp_juni + 1}位 ${TimeDate.timeToFunByouString(gakunenJunUnivFilteredSenshuData[number].time_taikai_total)}",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),

                      // 指示内容と結果表示（重複部分はヘルパー関数化）
                      _buildInstructionResultText(
                        gakunenJunUnivFilteredSenshuData[number],
                        currentGhensuu,
                        iKukan,
                        idJunUnivData,
                      ),
                      if (gakunenJunUnivFilteredSenshuData[number]
                          .string_racesetumei
                          .isNotEmpty)
                        Text(
                          gakunenJunUnivFilteredSenshuData[number]
                              .string_racesetumei,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      const Text(""), // スペース
                    ],
                  ),
            ],
          ),
        const Text(""), // スペース
      ],
    );
  }

  // MARK: - モーダルリンクボタンのヘルパー
  Widget _buildModalLinkButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: () {
        onPressed(); // 渡されたonPressedを呼び出す
        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => SomeModalView())); // もし直接ページ遷移なら
        // showModalBottomSheet(context: context, builder: (_) => SomeModalView()); // もしモーダル表示なら
      },
      child: Text(
        text,
        style: TextStyle(
          color: HENSUU.buttonColor, // 緑色
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // MARK: - 指示結果表示のヘルパー関数
  String _getShougatuEkidenYosenInstructionOptions(int flag) {
    final options = [
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
    return options[flag];
  }

  String _getStartInstructionOptions(int flag) {
    final options = ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"];
    return options[flag];
  }

  String _getMidInstructionOptions(int flag) {
    final options = ["指示なし", "前半から突っ込む", "前半は抑える"];
    return options[flag];
  }

  String _getInstructionResult(int flag) {
    final kekka = ["失敗", "成功"];
    return kekka[flag];
  }

  Widget _buildInstructionResultText(
    SenshuData senshu,
    Ghensuu ghensuu,
    int iKukan,
    List<UnivData> idJunUnivData,
  ) {
    // iKukan-100000-1 のようなインデックス計算はSwiftのForEach由来なので、iKukanを直接使用
    final mokuhyoJuniFlagIndex = iKukan - 1; // 1つ前の区間フラグを指す
    if (ghensuu.hyojiracebangou == 4) {
      // 正月駅伝予選
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "指示内容: ${_getShougatuEkidenYosenInstructionOptions(senshu.sijiflag)}",
            style: TextStyle(color: HENSUU.textcolor),
          ),
        ],
      );
    } else if (ghensuu.hyojiracebangou == 3 || iKukan == 0) {
      // 11月駅伝予選
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "指示内容: ${_getStartInstructionOptions(senshu.sijiflag)}",
            style: TextStyle(color: HENSUU.textcolor),
          ),
          if (senshu.startchokugotobidasiflag == 1)
            Text(
              "スタート直後飛び出して: ${_getInstructionResult(senshu.startchokugotobidasiseikouflag)}",
              style: TextStyle(color: HENSUU.textcolor),
            ),
        ],
      );
    } else {
      // その他の区間
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "指示内容: ${_getMidInstructionOptions(senshu.sijiflag)}",
            style: TextStyle(color: HENSUU.textcolor),
          ),
          if (senshu.sijiflag >= 1)
            Text(
              "結果: ${_getInstructionResult(senshu.sijiseikouflag)}",
              style: TextStyle(color: HENSUU.textcolor),
            )
          else if (mokuhyoJuniFlagIndex >= 0 &&
              idJunUnivData.length > senshu.univid &&
              idJunUnivData[senshu.univid]
                      .mokuhyojuniwositamawatteruflag
                      .length >
                  mokuhyoJuniFlagIndex &&
              idJunUnivData[senshu.univid]
                      .mokuhyojuniwositamawatteruflag[mokuhyoJuniFlagIndex] ==
                  1)
            const Text(
              "チーム目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり",
              style: TextStyle(color: HENSUU.textcolor),
            )
          else if (mokuhyoJuniFlagIndex >= 0 &&
              idJunUnivData.length > senshu.univid &&
              idJunUnivData[senshu.univid]
                      .mokuhyojuniwositamawatteruflag
                      .length >
                  mokuhyoJuniFlagIndex &&
              idJunUnivData[senshu.univid]
                      .mokuhyojuniwositamawatteruflag[mokuhyoJuniFlagIndex] <
                  0)
            const Text(
              "チーム目標順位を上回っていたことによるほっと一息でのタイム悪化あり",
              style: TextStyle(color: HENSUU.textcolor),
            ),
        ],
      );
    }
  }

  // リンクボタンをWidgetに分離
  // currentGhensuu を引数として受け取るように変更
  Widget LinkButtons(BuildContext context, Ghensuu currentGhensuu) {
    return Column(
      children: [
        // ModalZenhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        if (currentGhensuu.hyojiracebangou == 2)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '前半区間成績表示', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalZenhanKekkaView(); // const を追加
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
              "前半区間成績表示",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        // ModalKouhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        if (currentGhensuu.hyojiracebangou == 2)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '後半区間成績表示', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalKouhanKekkaView(); // const を追加
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
              "後半区間成績表示",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        // ModalKukanshouView は currentGhensuu.hyojiracebangou が 2 以下の時だけ表示
        if (currentGhensuu.hyojiracebangou <= 2 ||
            currentGhensuu.hyojiracebangou == 5)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '区間賞表示', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalKukanshouView(); // const を追加
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
              "区間賞表示",
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

  Widget _buildGakurenResults(
    //List<Senshu_Gakuren_Data> gakunenJunUnivFilteredSenshuData,
    Ghensuu currentGhensuu,
    List<UnivData> idJunUnivData,
  ) {
    final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
    final gakurenunivdata = gakurenunivBox.values.toList();
    final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
    final gakurensenshudata = gakurensenshuBox.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "\n学連選抜参考記録\n",
          style: TextStyle(
            color: HENSUU.textcolor,
            //fontWeight: FontWeight.bold,
          ),
        ),

        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8),
              barrierDismissible: true,
              barrierLabel: '学連選抜区間配置',
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, _, __) => const ModalGakurenKukanView(),
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
        // ForEachのi_kukanループに相当
        for (
          int iKukan = 0;
          iKukan <
              currentGhensuu.kukansuu_taikaigoto[currentGhensuu
                  .hyojiracebangou];
          iKukan++
        )
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentGhensuu.hyojiracebangou == 3) // 11月駅伝予選は「組目」
                Text(
                  "${iKukan + 1}組目",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    //fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  "${iKukan + 1}区",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              Wrap(
                children: [
                  const Text("通過順位", style: TextStyle(color: HENSUU.textcolor)),
                  if (gakurenunivdata[0].tuukajuni_taikai.length >
                      iKukan) // 範囲チェック
                    Text(
                      "${gakurenunivdata[0].tuukajuni_taikai[iKukan] + 1}位相当 ",
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                  if (gakurenunivdata[0].time_taikai_total.length >
                      iKukan) // 範囲チェック
                    Text(
                      TimeDate.timeToJikanFunByouString(
                        gakurenunivdata[0].time_taikai_total[iKukan],
                      ),
                      style: TextStyle(color: HENSUU.textcolor),
                    ),
                ],
              ),
              if (iKukan > 0) // 2区以降
                Wrap(
                  children: [
                    if (currentGhensuu.hyojiracebangou == 3)
                      const Text(
                        "組順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      )
                    else
                      const Text(
                        "区間順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (gakurenunivdata[0].kukanjuni_taikai.length >
                        iKukan) // 範囲チェック
                      Text(
                        "${gakurenunivdata[0].kukanjuni_taikai[iKukan] + 1}位相当 ",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (gakurenunivdata[0].time_taikai_total.length > iKukan &&
                        gakurenunivdata[0].time_taikai_total.length >
                            iKukan - 1) // 範囲チェック
                      Text(
                        TimeDate.timeToFunByouString(
                          gakurenunivdata[0].time_taikai_total[iKukan] -
                              gakurenunivdata[0].time_taikai_total[iKukan - 1],
                        ),
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                  ],
                )
              else ...[
                // 1区
                Wrap(
                  children: [
                    if (currentGhensuu.hyojiracebangou == 3)
                      const Text(
                        "組順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      )
                    else
                      const Text(
                        "区間順位",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (gakurenunivdata[0].kukanjuni_taikai.length >
                        iKukan) // 範囲チェック
                      Text(
                        "${gakurenunivdata[0].kukanjuni_taikai[iKukan] + 1}位相当 ",
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    if (gakurenunivdata[0].time_taikai_total.length >
                        iKukan) // 範囲チェック
                      Text(
                        TimeDate.timeToFunByouString(
                          gakurenunivdata[0].time_taikai_total[iKukan],
                        ),
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                  ],
                ),
              ],
              //const Text(""), // スペース
              // 自分の大学の区間内の選手詳細
              for (int number = 0; number < gakurensenshudata.length; number++)
                if (gakurensenshudata[number].entrykukan_race[currentGhensuu
                        .hyojiracebangou][gakurensenshudata[number].gakunen -
                        1] ==
                    iKukan)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /*Wrap(
                        children: [
                          if (currentGhensuu.year > 2 ||
                              (currentGhensuu.year == 2 &&
                                  currentGhensuu.month >= 4)) ...[
                            if ((currentGhensuu.hyojiracebangou >= 0 &&
                                    currentGhensuu.hyojiracebangou <= 2) ||
                                currentGhensuu.hyojiracebangou == 5) ...[
                              if (gakurensenshudata[number]
                                      .chokuzentaikai_zentaikukansinflag ==
                                  1)
                                Text(
                                  "*区間新",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (gakurensenshudata[number]
                                      .chokuzentaikai_univkukansinflag ==
                                  1)
                                Text(
                                  "*学内新",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),*/
                      Wrap(
                        children: [
                          Text(
                            "${gakurensenshudata[number].name} (${gakurensenshudata[number].gakunen}年) ${idJunUnivData[gakurensenshudata[number].univid].name}",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (currentGhensuu.hyojiracebangou == 3) // 11月駅伝予選
                        Text(
                          "組内個人順位:${gakurensenshudata[number].temp_juni + 1}位 ${TimeDate.timeToFunByouString(gakurensenshudata[number].time_taikai_total)}",
                          style: TextStyle(color: HENSUU.textcolor),
                        ),

                      // 指示内容と結果表示（重複部分はヘルパー関数化）
                      /*_buildInstructionResultText(
                        gakunenJunUnivFilteredSenshuData[number],
                        currentGhensuu,
                        iKukan,
                        idJunUnivData,
                      ),
                      if (gakunenJunUnivFilteredSenshuData[number]
                          .string_racesetumei
                          .isNotEmpty)
                        Text(
                          gakunenJunUnivFilteredSenshuData[number]
                              .string_racesetumei,
                          style: TextStyle(color: HENSUU.textcolor),
                        ),*/
                      const Text(""), // スペース
                    ],
                  ),
            ],
          ),
        const Text(""), // スペース
      ],
    );
  }
}
