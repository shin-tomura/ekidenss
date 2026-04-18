import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_editSenshu.dart';
import 'package:ekiden/screens/Modal_nameedit.dart';
import 'package:ekiden/qr_modal.dart';
//import 'package:ekiden/qr_scanner_screen.dart';
import 'package:ekiden/qr_camera_scanner_screen.dart';
import 'package:ekiden/qr_gallery_scanner_screen.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/screens/Modal_ChartHyojiHijyojiKirikae.dart';

// タイムを「分秒」形式の文字列に変換するヘルパー関数
String _timeToMinuteSecondString(double time) {
  if (time >= TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

// 選手詳細を表示するモーダルウィジェット
class ModalSenshuDetailView extends StatefulWidget {
  // 外部から表示したい選手のIDを受け取る
  final int senshuId;

  const ModalSenshuDetailView({super.key, required this.senshuId});

  @override
  State<ModalSenshuDetailView> createState() => _ModalSenshuDetailViewState();
}

class _ModalSenshuDetailViewState extends State<ModalSenshuDetailView> {
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

  // ベスト記録表示用のヘルパーウィジェット（フルマラソン用）
  Widget _buildBestRecordRow_full(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    if (time >= TEISUU.DEFAULTTIME) {
      return Text(
        '$label 記録無',
        style: const TextStyle(
          color: Colors.white,
          fontSize: HENSUU.fontsize_honbun,
        ),
      );
    }
    return Wrap(
      children: [
        Text(
          '$label: ${TimeDate.timeToJikanFunByouString(time)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        if (gakunaiJuni < 100)
          Text(
            '学内${gakunaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        if (zentaiJuni != null) ...[
          const SizedBox(width: 8),
          Text(
            '全体${zentaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ],
      ],
    );
  }

  // ベスト記録表示用のヘルパーウィジェット（分秒形式のタイム用）
  Widget _buildBestRecordRow(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    if (time >= TEISUU.DEFAULTTIME) {
      return Text(
        '$label 記録無',
        style: const TextStyle(
          color: Colors.white,
          fontSize: HENSUU.fontsize_honbun,
        ),
      );
    }
    return Wrap(
      children: [
        Text(
          '$label: ${_timeToMinuteSecondString(time)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        if (gakunaiJuni < 100)
          Text(
            '学内${gakunaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        if (zentaiJuni != null) ...[
          const SizedBox(width: 8),
          Text(
            '全体${zentaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        ],
      ],
    );
  }

  // 能力値表示用のヘルパーウィジェット
  Widget _buildAbilityRow(String label, int flag, int value) {
    return Text(
      '$label: ${flag == 1 ? value.toString() : '??'}',
      style: TextStyle(
        color: flag == 1 ? Colors.white : Colors.grey,
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組なし、フルマラソン)
  Widget _buildRaceRecordRow_full(String label, int juni, double time) {
    if (juni == TEISUU.DEFAULTJUNI) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Text(
          '$label: ${juni + 1}位',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          TimeDate.timeToJikanFunByouString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
      ],
    );
  }

  Widget _buildRaceRecordRow_gakunai(String label, int juni, double time) {
    if (juni == TEISUU.DEFAULTJUNI) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Text(
          '$label: 学内${juni + 1}位',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _timeToMinuteSecondString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
      ],
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組なし)
  Widget _buildRaceRecordRow(String label, int juni, double time) {
    if (juni == TEISUU.DEFAULTJUNI) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Text(
          '$label: ${juni + 1}位',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _timeToMinuteSecondString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
      ],
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組あり)
  Widget _buildRaceRecordRowWithKumi(
    String label,
    int kumi,
    int juni,
    double time,
    int racebangou,
  ) {
    String kumistring = "";
    if (kumi <= -1) {
      return const SizedBox.shrink();
    }
    if (racebangou == 3) {
      kumistring = "組";
    } else {
      kumistring = "区";
    }

    // 順位が100未満（=通常の順位）か、100以上（=相当順位）かを判定
    final String juniText = juni < 100
        ? '${juni + 1}位'
        : '${juni + 1 - 100}位相当';

    return Wrap(
      children: [
        Text(
          '$label: ${kumi + 1}' + kumistring + juniText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _timeToMinuteSecondString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
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

        // SenshuDataのValueListenableBuilder
        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: _senshuBox.listenable(),
          builder: (context, senshuBox, _) {
            // IDで選手データを直接取得
            final SenshuData? currentSenshu = senshuBox.get(widget.senshuId);

            if (currentSenshu == null) {
              return Center(
                child: Text(
                  '選手データ (ID: ${widget.senshuId}) が見つかりません。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
              );
            }

            // 大学名を取得
            final UnivData? currentUnivData = _univBox.get(
              currentSenshu.univid,
            );
            final String univName = currentUnivData?.name ?? '大学名不明';

            // 大学データリストをソート（駅伝成績表示で使用）
            final univDataBox = Hive.box<UnivData>('univBox');
            List<UnivData> sortedUnivData = univDataBox.values.toList();
            sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

            final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            final KantokuData kantoku = kantokuBox.get('KantokuData')!;
            // ⭐ アンパック（取り出し）
            final Map<String, int> extracted = PackedIndexHelper.unpackIndices(
              currentSenshu.samusataisei,
            );
            // 確認
            final int extractedHobbyIndex = extracted['hobbyIndex']!;
            final int extractedPrefectureIndex = extracted['prefectureIndex']!;
            String shumi_str = "";
            if (extractedPrefectureIndex >=
                    LocationDatabase.allPrefectures.length ||
                extractedPrefectureIndex < 0 ||
                extractedHobbyIndex >= HobbyDatabase.allHobbies.length ||
                extractedHobbyIndex < 0) {
              shumi_str = "";
            } else {
              if (kantoku.yobiint2[15] == 1) {
                if (currentSenshu.hirou == 1) {
                  shumi_str = '出身: ?';
                } else {
                  shumi_str =
                      '出身: ${LocationDatabase.allPrefectures[extractedPrefectureIndex]}';
                }
              } else {
                if (currentSenshu.hirou == 1) {
                  shumi_str =
                      '出身: ?\n趣味: ${HobbyDatabase.allHobbies[extractedHobbyIndex]}';
                } else {
                  shumi_str =
                      '出身: ${LocationDatabase.allPrefectures[extractedPrefectureIndex]}\n趣味: ${HobbyDatabase.allHobbies[extractedHobbyIndex]}';
                }
              }
            }
            final String menuName = TrainingMenu.getMenuString(
              currentSenshu.kaifukuryoku,
            );
            // 提示されたコードに基づき、表示用の基本走力(aInt)を計算
            int newbint = 1550;
            int b_int = (currentSenshu.b * 10000.0).toInt();
            int a_int = (currentSenshu.a * 1000000000.0).toInt();
            int a_min_int =
                (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER)
                    //(b_int * b_int * 0.0333 - b_int * 114.25 + senshu.magicnumber)
                    .toInt();
            int sa = a_int - a_min_int;
            int new_a_min_int =
                (newbint * newbint * 0.0333 -
                        newbint * 114.25 +
                        TEISUU.MAGICNUMBER)
                    //(newbint * newbint * 0.0333 - newbint * 114.25 + senshu.magicnumber)
                    .toInt();

            int aInt = new_a_min_int + sa;
            //final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            //final KantokuData kantoku = kantokuBox.get('KantokuData')!;
            return Container(
              height: MediaQuery.of(context).size.height * 0.9, // 画面の90%を占める
              decoration: BoxDecoration(
                color: HENSUU.backgroundcolor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
              ),
              child: Scaffold(
                backgroundColor:
                    Colors.transparent, // 背景色を透明にしてContainerの背景色を活かす
                appBar: AppBar(
                  // モーダル内でAppBarのタイトルを選手名に変更
                  title: Text(
                    '選手データ',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                  //automaticallyImplyLeading: false, // 戻るボタンを非表示
                  /*actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(), // モーダルを閉じる
                      child: const Text(
                        '閉じる',
                        style: TextStyle(
                          color: HENSUU.LinkColor, // テキストの色を白に設定
                          fontSize: HENSUU.fontsize_honbun,
                        ),
                      ),
                    ),
                  ],*/
                ),
                body: Column(
                  children: [
                    const SizedBox(height: 8),
                    // 大学名と選手名
                    Text(
                      '$univName大学',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSenshu.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun + 4, // 少し大きく
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${currentSenshu.gakunen}年)',
                          style: const TextStyle(
                            color: Colors.white70, // 選手名より少し目立たない色
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
                          if (kantoku.yobiint2[20] == 0)
                            // 共通パネルを呼び出すだけ！
                            buildSenshuAnalysisPanel(
                              currentSenshu,
                              //onDetailTap: () {
                              /* すでに詳細画面ならnullでもOK */
                              //},
                            ),
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
                                      // ここに表示したいモーダルのウィジェットを指定
                                      return const AnalysisPanelConfigScreen(); // const を追加
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
                              setState(() {});
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

                          if (kantoku.yobiint2[17] == 1)
                            TextButton(
                              onPressed: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(
                                    0.8,
                                  ), // モーダルの背景色
                                  barrierDismissible: true, // 背景タップで閉じられるようにする
                                  barrierLabel: '能力編集', // アクセシビリティ用ラベル
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ), // アニメーション時間
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                        // ここに表示したいモーダルのウィジェットを指定
                                        return SenshuEditView(
                                          senshuId: widget.senshuId,
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
                                "能力編集",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 255, 0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: HENSUU.textcolor,
                                ),
                              ),
                            ),
                          if (kantoku.yobiint2[17] == 1)
                            TextButton(
                              onPressed: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(
                                    0.8,
                                  ), // モーダルの背景色
                                  barrierDismissible: true, // 背景タップで閉じられるようにする
                                  barrierLabel: '選手名変更', // アクセシビリティ用ラベル
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ), // アニメーション時間
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                        // ここに表示したいモーダルのウィジェットを指定
                                        return ModalSenshuNameHenkou_modalsenshugamen(
                                          senshuId: widget.senshuId,
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
                                "選手名変更",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 255, 0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: HENSUU.textcolor,
                                ),
                              ),
                            ),

                          Text(
                            "年間強化: $menuName",
                            style: const TextStyle(
                              color: Colors.white, // 白色に変更
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shumi_str,
                            style: const TextStyle(
                              color: Colors.white, // 白色に変更
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 入学時5000m記録
                          Text(
                            '入学時5千: ${_timeToMinuteSecondString(currentSenshu.kiroku_nyuugakuji_5000)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 各種ベスト記録
                          _buildBestRecordRow(
                            '5千best',
                            currentSenshu.time_bestkiroku[0],
                            currentSenshu.gakunaijuni_bestkiroku[0],
                            currentSenshu.zentaijuni_bestkiroku[0],
                          ),
                          _buildBestRecordRow(
                            '1万best',
                            currentSenshu.time_bestkiroku[1],
                            currentSenshu.gakunaijuni_bestkiroku[1],
                            currentSenshu.zentaijuni_bestkiroku[1],
                          ),
                          _buildBestRecordRow(
                            'ハーフbest',
                            currentSenshu.time_bestkiroku[2],
                            currentSenshu.gakunaijuni_bestkiroku[2],
                            currentSenshu.zentaijuni_bestkiroku[2],
                          ),
                          _buildBestRecordRow_full(
                            'フルbest',
                            currentSenshu.time_bestkiroku[3],
                            currentSenshu.gakunaijuni_bestkiroku[3],
                            currentSenshu.zentaijuni_bestkiroku[3],
                          ),
                          _buildBestRecordRow(
                            '登り1万best',
                            currentSenshu.time_bestkiroku[4],
                            currentSenshu.gakunaijuni_bestkiroku[4],
                            null,
                          ),
                          _buildBestRecordRow(
                            '下り1万best',
                            currentSenshu.time_bestkiroku[5],
                            currentSenshu.gakunaijuni_bestkiroku[5],
                            null,
                          ),
                          _buildBestRecordRow(
                            'ロード1万best',
                            currentSenshu.time_bestkiroku[6],
                            currentSenshu.gakunaijuni_bestkiroku[6],
                            null,
                          ),
                          _buildBestRecordRow(
                            'クロカン1万best',
                            currentSenshu.time_bestkiroku[7],
                            currentSenshu.gakunaijuni_bestkiroku[7],
                            null,
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            '能力',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold, // 強調
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 各種能力値
                          if (kantoku.yobiint2[17] == 1)
                            _buildAbilityRow(
                              '動作検証用',
                              1,
                              currentSenshu.seichoukaisuu,
                            ),
                          if (kantoku.yobiint2[17] == 1)
                            _buildAbilityRow('基本走力', 1, aInt + 300),
                          if (kantoku.yobiint2[17] == 1)
                            _buildAbilityRow(
                              '素質',
                              1,
                              currentSenshu.sositu - 1500,
                            ),
                          if (((ghensuu.month == 10 && ghensuu.day == 5) ||
                                  (ghensuu.month == 11 && ghensuu.day == 5) ||
                                  (ghensuu.month == 1 && ghensuu.day == 5) ||
                                  (ghensuu.month == 2 && ghensuu.day == 25)) &&
                              ghensuu.mode > 150)
                            _buildAbilityRow('調子', 1, currentSenshu.chousi),
                          _buildAbilityRow('安定感', 1, currentSenshu.anteikan),
                          _buildAbilityRow(
                            '駅伝男',
                            ghensuu.nouryokumieruflag[0],
                            currentSenshu.konjou,
                          ),
                          _buildAbilityRow(
                            '平常心',
                            ghensuu.nouryokumieruflag[1],
                            currentSenshu.heijousin,
                          ),
                          _buildAbilityRow(
                            '長距離粘り',
                            ghensuu.nouryokumieruflag[2],
                            currentSenshu.choukyorinebari,
                          ),
                          _buildAbilityRow(
                            'スパート力',
                            ghensuu.nouryokumieruflag[3],
                            currentSenshu.spurtryoku,
                          ),
                          _buildAbilityRow(
                            'カリスマ',
                            ghensuu.nouryokumieruflag[4],
                            currentSenshu.karisuma,
                          ),
                          _buildAbilityRow(
                            '登り適性',
                            ghensuu.nouryokumieruflag[5],
                            currentSenshu.noboritekisei,
                          ),
                          _buildAbilityRow(
                            '下り適性',
                            ghensuu.nouryokumieruflag[6],
                            currentSenshu.kudaritekisei,
                          ),
                          _buildAbilityRow(
                            'アップダウン対応力',
                            ghensuu.nouryokumieruflag[7],
                            currentSenshu.noborikudarikirikaenouryoku,
                          ),
                          _buildAbilityRow(
                            'ロード適性',
                            ghensuu.nouryokumieruflag[8],
                            currentSenshu.tandokusou,
                          ),
                          _buildAbilityRow(
                            'ペース変動対応力',
                            ghensuu.nouryokumieruflag[9],
                            currentSenshu.paceagesagetaiouryoku,
                          ),
                          _buildAbilityRow(
                            '能力計(安定感・基本走力を除く)',
                            1,
                            currentSenshu.konjou +
                                currentSenshu.heijousin +
                                currentSenshu.choukyorinebari +
                                currentSenshu.spurtryoku +
                                currentSenshu.karisuma +
                                currentSenshu.noboritekisei +
                                currentSenshu.kudaritekisei +
                                currentSenshu.noborikudarikirikaenouryoku +
                                currentSenshu.tandokusou +
                                currentSenshu.paceagesagetaiouryoku,
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            '駅伝・対校戦成績',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold, // 強調
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 駅伝・対校戦成績 (学年ループ)
                          ...List.generate(currentSenshu.gakunen, (
                            gakunenIndex,
                          ) {
                            // 選手が4年までしか存在しない前提
                            if (gakunenIndex >= 4)
                              return const SizedBox.shrink();

                            // 配列の境界チェックを行う
                            if (currentSenshu.entrykukan_race.length <= 8 ||
                                currentSenshu.kukanjuni_race.length <= 8 ||
                                currentSenshu.kukantime_race.length <= 8) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${gakunenIndex + 1}年時成績',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold, // 年時成績を強調
                                  ),
                                ),
                                _buildRaceRecordRow(
                                  '対校戦5千',
                                  currentSenshu.kukanjuni_race[6][gakunenIndex],
                                  currentSenshu.kukantime_race[6][gakunenIndex],
                                ),
                                _buildRaceRecordRow(
                                  '対校戦1万',
                                  currentSenshu.kukanjuni_race[7][gakunenIndex],
                                  currentSenshu.kukantime_race[7][gakunenIndex],
                                ),
                                _buildRaceRecordRow(
                                  '対校戦ハーフ',
                                  currentSenshu.kukanjuni_race[8][gakunenIndex],
                                  currentSenshu.kukantime_race[8][gakunenIndex],
                                ),
                                _buildRaceRecordRowWithKumi(
                                  '11月駅伝予選',
                                  currentSenshu
                                      .entrykukan_race[3][gakunenIndex],
                                  currentSenshu.kukanjuni_race[3][gakunenIndex],
                                  currentSenshu.kukantime_race[3][gakunenIndex],
                                  3,
                                ),
                                _buildRaceRecordRowWithKumi(
                                  '10月駅伝',
                                  currentSenshu
                                      .entrykukan_race[0][gakunenIndex],
                                  currentSenshu.kukanjuni_race[0][gakunenIndex],
                                  currentSenshu.kukantime_race[0][gakunenIndex],
                                  0,
                                ),
                                // 正月駅伝予選のデータは racebangou 4
                                _buildRaceRecordRow(
                                  '正月駅伝予選',
                                  currentSenshu.kukanjuni_race[4][gakunenIndex],
                                  currentSenshu.kukantime_race[4][gakunenIndex],
                                ),
                                _buildRaceRecordRowWithKumi(
                                  '11月駅伝',
                                  currentSenshu
                                      .entrykukan_race[1][gakunenIndex],
                                  currentSenshu.kukanjuni_race[1][gakunenIndex],
                                  currentSenshu.kukantime_race[1][gakunenIndex],
                                  1,
                                ),

                                _buildRaceRecordRowWithKumi(
                                  '正月駅伝',
                                  currentSenshu
                                      .entrykukan_race[2][gakunenIndex],
                                  currentSenshu.kukanjuni_race[2][gakunenIndex],
                                  currentSenshu.kukantime_race[2][gakunenIndex],
                                  2,
                                ),

                                // sortedUnivDataの0番目が常に存在することを前提としている
                                _buildRaceRecordRowWithKumi(
                                  sortedUnivData.isNotEmpty
                                      ? sortedUnivData[0].name_tanshuku
                                      : '他駅伝',
                                  currentSenshu
                                      .entrykukan_race[5][gakunenIndex],
                                  currentSenshu.kukanjuni_race[5][gakunenIndex],
                                  currentSenshu.kukantime_race[5][gakunenIndex],
                                  2,
                                ),

                                _buildRaceRecordRow(
                                  '秋記録会5千',
                                  currentSenshu
                                      .kukanjuni_race[10][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[10][gakunenIndex],
                                ),
                                _buildRaceRecordRow(
                                  '秋記録会1万',
                                  currentSenshu
                                      .kukanjuni_race[11][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[11][gakunenIndex],
                                ),
                                _buildRaceRecordRow(
                                  '秋市民ハーフ',
                                  currentSenshu
                                      .kukanjuni_race[12][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[12][gakunenIndex],
                                ),
                                _buildRaceRecordRow_gakunai(
                                  '登り10km',
                                  currentSenshu
                                      .kukanjuni_race[13][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[13][gakunenIndex],
                                ),
                                _buildRaceRecordRow_gakunai(
                                  '下り10km',
                                  currentSenshu
                                      .kukanjuni_race[14][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[14][gakunenIndex],
                                ),
                                _buildRaceRecordRow_gakunai(
                                  'ロード10km',
                                  currentSenshu
                                      .kukanjuni_race[15][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[15][gakunenIndex],
                                ),
                                _buildRaceRecordRow_gakunai(
                                  'クロカン10km',
                                  currentSenshu
                                      .kukanjuni_race[16][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[16][gakunenIndex],
                                ),

                                // フルマラソン成績のデータは racebangou 17
                                _buildRaceRecordRow_full(
                                  'フルマラソン',
                                  currentSenshu
                                      .kukanjuni_race[17][gakunenIndex],
                                  currentSenshu
                                      .kukantime_race[17][gakunenIndex],
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),

                          const SizedBox(height: 30),
                          TextButton(
                            onPressed: () async {
                              // IDで選手データを直接取得
                              final SenshuData currentSenshu = senshuBox.get(
                                widget.senshuId,
                              )!;

                              showGeneralDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(
                                  0.8,
                                ), // モーダルの背景色
                                barrierDismissible: true, // 背景タップで閉じられるようにする
                                barrierLabel: 'この選手のQRコードを表示', // アクセシビリティ用ラベル
                                transitionDuration: const Duration(
                                  milliseconds: 300,
                                ), // アニメーション時間
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                      // ここに表示したいモーダルのウィジェットを指定
                                      return QrModal(
                                        senshu: currentSenshu,
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
                              "この選手のQRコードを表示",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 255, 0),
                                decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QrGalleryScannerScreen(
                                    senshuIdToUpdate: widget.senshuId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "QRコードを画像ファイルから読込",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 255, 0),
                                decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QrCameraScannerScreen(
                                    senshuIdToUpdate: widget.senshuId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "QRコードをカメラで読込",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 255, 0),
                                decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
