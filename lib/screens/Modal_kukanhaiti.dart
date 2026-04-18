import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // TEISUU, HENSUU
import 'package:ekiden/kansuu/time_date.dart'; // KANSUU

String _formatDoubleToFixed(double value, int fractionDigits) {
  return value.toStringAsFixed(fractionDigits);
}

class ModalKukanHaitiView extends StatelessWidget {
  const ModalKukanHaitiView({super.key});

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
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '区間配置確認',
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

                // unividが特定のものだけ抽出 (myunivfilteredsenshudata)
                final List<SenshuData> myUnivFilteredSenshuData;
                if (currentGhensuu.hyojiracebangou == 4) {
                  myUnivFilteredSenshuData =
                      allSenshuData
                          .where((s) => s.univid == currentGhensuu.MYunivid)
                          .toList()
                        ..sort((a, b) {
                          // 学年を比較
                          final int gakunenComparison = b.gakunen.compareTo(
                            a.gakunen,
                          );
                          // 学年が同じ場合はidを比較
                          if (gakunenComparison == 0) {
                            return a.id.compareTo(b.id);
                          }
                          return gakunenComparison;
                        });
                } else {
                  myUnivFilteredSenshuData = allSenshuData
                      .where((s) => s.univid == currentGhensuu.MYunivid)
                      .toList();
                }

                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
                  appBar: AppBar(
                    title: const Text(
                      '区間配置確認',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
                    foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
                  ),
                  body: Column(
                    // SwiftUIのVStackに相当
                    children: <Widget>[
                      Text(
                        "区間配置",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: HENSUU.fontsize_honbun,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.grey), // Divider

                      Expanded(
                        // ScrollView に相当する SingleChildScrollView を Expanded で囲む
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0), // 全体的なパディング
                          child: Column(
                            // LazyVStackに相当
                            crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                            children: <Widget>[
                              // ForEach(0..<gh[0].kukansuu_taikaigoto[gh[0].hyojiracebangou], id: \.self) に相当
                              for (
                                int i_kukan = 0;
                                i_kukan <
                                    currentGhensuu
                                        .kukansuu_taikaigoto[currentGhensuu
                                        .hyojiracebangou];
                                i_kukan++
                              )
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // gakunenjunmyunivfilteredsenshudata の計算
                                    // ループ内で定義するとパフォーマンスに影響する可能性があるので注意
                                    // 必要に応じて、このリストはループの外で一度計算し、フィルタリングする方が良いかもしれません
                                    ...myUnivFilteredSenshuData
                                        .where(
                                          (senshu) =>
                                              senshu
                                                  .entrykukan_race[currentGhensuu
                                                  .hyojiracebangou][senshu
                                                      .gakunen -
                                                  1] ==
                                              i_kukan,
                                        )
                                        .map((senshu) {
                                          // 各選手の情報表示
                                          return Column(
                                            // HStackの代わりにColumnで縦に並べるか、Wrapを使う
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 区間情報と選手名（hyojiracebangouによる分岐）
                                              if (currentGhensuu
                                                      .hyojiracebangou ==
                                                  3)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "${i_kukan + 1}組目",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${_formatDoubleToFixed(currentGhensuu.kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][i_kukan], 0)}m",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      senshu.name,
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "(${senshu.gakunen}年)",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else if (currentGhensuu
                                                      .hyojiracebangou ==
                                                  4)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "${_formatDoubleToFixed(currentGhensuu.kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][i_kukan], 0)}m",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      senshu.name,
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "(${senshu.gakunen}年)",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    if (currentGhensuu
                                                            .nouryokumieruflag[0] ==
                                                        1)
                                                      Text(
                                                        "駅伝男 ${senshu.konjou}",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    if (currentGhensuu
                                                            .nouryokumieruflag[0] ==
                                                        0)
                                                      Text(
                                                        "駅伝男 ??",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    if (currentGhensuu
                                                            .nouryokumieruflag[1] ==
                                                        1)
                                                      Text(
                                                        "平常心 ${senshu.heijousin}",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    if (currentGhensuu
                                                            .nouryokumieruflag[1] ==
                                                        0)
                                                      Text(
                                                        "平常心 ??",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              else
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "${i_kukan + 1}区",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${_formatDoubleToFixed(currentGhensuu.kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][i_kukan], 0)}m",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      senshu.name,
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "(${senshu.gakunen}年)",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                        //fontWeight:
                                                        //FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                              // 5千best
                                              if (currentGhensuu
                                                      .hyojiracebangou !=
                                                  4)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "5千best",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),

                                                    if (senshu
                                                            .time_bestkiroku[0] !=
                                                        TEISUU.DEFAULTTIME) ...[
                                                      Text(
                                                        TimeDate.timeToFunByouString(
                                                          senshu
                                                              .time_bestkiroku[0],
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "区間内${senshu.kukannaijuni[0] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "学内${senshu.gakunaijuni_bestkiroku[0] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "全体${senshu.zentaijuni_bestkiroku[0] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    ] else
                                                      Text(
                                                        "記録無",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                  ],
                                                ),

                                              // 1万
                                              Wrap(
                                                // HStackに相当
                                                spacing: 8.0,
                                                runSpacing: 4.0,
                                                children: [
                                                  Text(
                                                    "1万",
                                                    style: TextStyle(
                                                      color: HENSUU.textcolor,
                                                      fontSize: HENSUU
                                                          .fontsize_honbun,
                                                    ),
                                                  ),
                                                  if (senshu
                                                          .time_bestkiroku[1] !=
                                                      TEISUU.DEFAULTTIME) ...[
                                                    Text(
                                                      TimeDate.timeToFunByouString(
                                                        senshu
                                                            .time_bestkiroku[1],
                                                      ),
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "区間内${senshu.kukannaijuni[1] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "学内${senshu.gakunaijuni_bestkiroku[1] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "全体${senshu.zentaijuni_bestkiroku[1] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                  ] else
                                                    Text(
                                                      "記録無",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              // ハーフ
                                              Wrap(
                                                // HStackに相当
                                                spacing: 8.0,
                                                runSpacing: 4.0,
                                                children: [
                                                  Text(
                                                    "ハーフ",
                                                    style: TextStyle(
                                                      color: HENSUU.textcolor,
                                                      fontSize: HENSUU
                                                          .fontsize_honbun,
                                                    ),
                                                  ),
                                                  if (senshu
                                                          .time_bestkiroku[2] !=
                                                      TEISUU.DEFAULTTIME) ...[
                                                    Text(
                                                      TimeDate.timeToFunByouString(
                                                        senshu
                                                            .time_bestkiroku[2],
                                                      ),
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "区間内${senshu.kukannaijuni[2] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "学内${senshu.gakunaijuni_bestkiroku[2] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "全体${senshu.zentaijuni_bestkiroku[2] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                  ] else
                                                    Text(
                                                      "記録無",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              // 登り1万
                                              if (currentGhensuu
                                                      .hyojiracebangou !=
                                                  4)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "登り1万",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    if (senshu
                                                            .time_bestkiroku[4] !=
                                                        TEISUU.DEFAULTTIME) ...[
                                                      Text(
                                                        TimeDate.timeToFunByouString(
                                                          senshu
                                                              .time_bestkiroku[4],
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "学内${senshu.gakunaijuni_bestkiroku[4] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    ] else
                                                      Text(
                                                        "記録無",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              // 下り1万
                                              if (currentGhensuu
                                                      .hyojiracebangou !=
                                                  4)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "下り1万",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    if (senshu
                                                            .time_bestkiroku[5] !=
                                                        TEISUU.DEFAULTTIME) ...[
                                                      Text(
                                                        TimeDate.timeToFunByouString(
                                                          senshu
                                                              .time_bestkiroku[5],
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "学内${senshu.gakunaijuni_bestkiroku[5] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    ] else
                                                      Text(
                                                        "記録無",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              // ロード1万
                                              Wrap(
                                                // HStackに相当
                                                spacing: 8.0,
                                                runSpacing: 4.0,
                                                children: [
                                                  Text(
                                                    "ロード1万",
                                                    style: TextStyle(
                                                      color: HENSUU.textcolor,
                                                      fontSize: HENSUU
                                                          .fontsize_honbun,
                                                    ),
                                                  ),
                                                  if (senshu
                                                          .time_bestkiroku[6] !=
                                                      TEISUU.DEFAULTTIME) ...[
                                                    Text(
                                                      TimeDate.timeToFunByouString(
                                                        senshu
                                                            .time_bestkiroku[6],
                                                      ),
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    Text(
                                                      "学内${senshu.gakunaijuni_bestkiroku[6] + 1}位",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                  ] else
                                                    Text(
                                                      "記録無",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              // クロカン1万
                                              if (currentGhensuu
                                                      .hyojiracebangou !=
                                                  4)
                                                Wrap(
                                                  // HStackに相当
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: [
                                                    Text(
                                                      "クロカン1万",
                                                      style: TextStyle(
                                                        color: HENSUU.textcolor,
                                                        fontSize: HENSUU
                                                            .fontsize_honbun,
                                                      ),
                                                    ),
                                                    if (senshu
                                                            .time_bestkiroku[7] !=
                                                        TEISUU.DEFAULTTIME) ...[
                                                      Text(
                                                        TimeDate.timeToFunByouString(
                                                          senshu
                                                              .time_bestkiroku[7],
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                      Text(
                                                        "学内${senshu.gakunaijuni_bestkiroku[7] + 1}位",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                    ] else
                                                      Text(
                                                        "記録無",
                                                        style: TextStyle(
                                                          color:
                                                              HENSUU.textcolor,
                                                          fontSize: HENSUU
                                                              .fontsize_honbun,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              const SizedBox(
                                                height: 16,
                                              ), // 各選手情報の区切り
                                            ],
                                          );
                                        })
                                        .toList(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Colors.grey), // Divider
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
      },
    );
  }
}
