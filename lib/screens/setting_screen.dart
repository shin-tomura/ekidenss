// lib/screens/setting_screen.dart
//import 'dart:math';
import 'package:ekiden/saitekikai.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
//import 'package:ekiden/senshu_data.dart';
//import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Platform.isIOS, Platform.isAndroidを使用するために必要
import 'package:ekiden/save_load_screen.dart';
import 'package:ekiden/screens/Modal_choukyoritimehosei.dart';
import 'package:ekiden/screens/Modal_ayumi.dart';
import 'package:ekiden/screens/Modal_chousi.dart';
import 'package:ekiden/screens/Modal_bairitu_goldsilver.dart';
import 'package:ekiden/screens/Modal_racejiki.dart';
import 'package:ekiden/screens/Modal_shumihihyouji.dart';
import 'package:ekiden/screens/Modal_TrainingEffect.dart';
import 'package:ekiden/screens/Modal_TimeChousei.dart';
import 'package:ekiden/settings_qr_page.dart';
import 'package:ekiden/screens/Modal_courseshoukai_kiten.dart';
import 'package:ekiden/screens/Modal_custom.dart';
import 'package:ekiden/screens/Modal_courseedit_kiten.dart';
import 'package:ekiden/screens/55fromNormal.dart';
import 'package:ekiden/screens/Modal_TTmode.dart';
import 'package:ekiden/screens/Modal_Skip.dart';
import 'package:ekiden/share_exporter.dart';
import 'package:ekiden/screens/Modal_memo.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // Hive Boxの参照を保持
  //late Box<Ghensuu> _ghensuuBox;
  //late Box<SenshuData> _senshuBox; // 表示には直接使用しませんが、完全性のために保持
  //late Box<UnivData> _univBox;

  @override
  void initState() {
    super.initState();
    // initStateでHive Boxの参照を取得
    //_ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    //_senshuBox = Hive.box<SenshuData>('senshuBox');
    //_univBox = Hive.box<UnivData>('univBox');
  }

  // App StoreのURL（TODO: ご自身のApp IDに置き換えてください）
  //final String appStoreUrl =
  //  'https://apps.apple.com/jp/app/%E7%AE%B1%E5%BA%AD%E5%B0%8F%E9%A7%85%E4%BC%9Ds/id6749337543';
  //final String appStoreUrl = 'itms-apps://itunes.apple.com/jp/app/id6749337543';
  // ブラウザで開くためのApp StoreのURL
  final String appStoreWebUrl =
      'https://apps.apple.com/app/%E7%AE%B1%E5%BA%AD%E5%B0%8F%E9%A7%85%E4%BC%9Dss/id6755650757';

  // Google PlayのURL（TODO: ご自身のパッケージ名に置き換えてください）
  final String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=jp.littlestar.hakoniwa.ekidenSS';

  // URLを起動するメソッド
  Future<void> _launchUrl() async {
    if (Platform.isIOS) {
      // iOSの場合
      final Uri appStoreWebUri = Uri.parse(appStoreWebUrl);
      if (await canLaunchUrl(appStoreWebUri)) {
        await launchUrl(appStoreWebUri);
      } else {
        throw 'Could not launch $appStoreWebUrl';
      }
    } else if (Platform.isAndroid) {
      // Androidの場合
      final Uri googlePlayUri = Uri.parse(googlePlayUrl);
      if (await canLaunchUrl(googlePlayUri)) {
        await launchUrl(googlePlayUri);
      } else {
        throw 'Could not launch $googlePlayUrl';
      }
    } else {
      // その他のプラットフォームでは何もせず終了
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu ghensuu = _ghensuuBox.getAt(0)!;
    return Scaffold(
      // Scaffoldを追加してAppBarなどを配置できるようにする
      appBar: AppBar(
        title: const Text('説明書', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: true, // タイトルを中央に配置
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // 全体にパディング
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // テキストを左寄せにする
          children: [
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                // Navigator.push を使用して Senshu_R_Screen へ遷移
                await Navigator.push(
                  context,
                  // MaterialPageRoute を使用して新しい画面を定義
                  MaterialPageRoute(builder: (context) => const MemoScreen()),
                );
              },
              child: Text(
                "フリーメモ",
                style: TextStyle(
                  color: HENSUU.LinkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                  //fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                // Navigator.push を使用して Senshu_R_Screen へ遷移
                await Navigator.push(
                  context,
                  // MaterialPageRoute を使用して新しい画面を定義
                  MaterialPageRoute(
                    builder: (context) =>
                        const SaveLoadScreen(hozonmosuruflag: true),
                  ),
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
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                // Navigator.push を使用して Senshu_R_Screen へ遷移
                await Navigator.push(
                  context,
                  // MaterialPageRoute を使用して新しい画面を定義
                  MaterialPageRoute(
                    builder: (context) => const ShareWorldScreen(),
                  ),
                );
              },
              child: Text(
                "データ共有(世界を共有)",
                style: TextStyle(
                  color: HENSUU.LinkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                  //fontSize: HENSUU.fontsize_honbun,
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
                  barrierLabel: '夏TT開催大学変更', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const SummerTTModeSelectScreen(); // const を追加
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
                "夏TT開催大学変更",
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
                  barrierLabel: '箱庭モード/通常モード切替', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const SimulationModeSelectScreen(); // const を追加
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
                "箱庭モード/通常モード切替",
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
                  barrierLabel: '最適解区間配置確率設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalComputerTeamProb(); // const を追加
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
                "最適解区間配置確率設定",
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
                  barrierLabel: '全体・区間ごとタイム調整', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalTimeAdjustmentSettings(); // const を追加
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
                "全体・区間ごとタイム調整",
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
                  barrierLabel: '長距離タイム抑制設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalPaceAdjustment(); // const を追加
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
                "長距離タイム抑制設定",
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
                  barrierLabel: '調子関連設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalConditionSettings(); // const を追加
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
                "調子関連設定",
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
                  barrierLabel: '金銀支給量倍率設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalMoneySettings(); // const を追加
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
                "金銀支給量倍率設定",
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
                  barrierLabel: '記録会時期設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalRaceTimeSettings(); // const を追加
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
                "記録会時期設定",
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
                  barrierLabel: '趣味非表示設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalHobbyDisplaySettings(); // const を追加
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
                "趣味非表示設定",
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
                  barrierLabel: '年間強化練習効果設定', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalTrainingEffectSettings(); // const を追加
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
                "年間強化練習効果設定",
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
                  barrierLabel: '自分のチームの歩み', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const ModalTeamHistoryView(); // const を追加
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
                "自分のチームの歩み",
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
                  barrierLabel: 'スキップして統計データ取得', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const StatisticsSimulationScreen();
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
                "スキップして統計データ取得",
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
                  barrierLabel: '駅伝コース紹介', // アクセシビリティ用ラベル
                  transitionDuration: const Duration(
                    milliseconds: 300,
                  ), // アニメーション時間
                  pageBuilder: (context, animation, secondaryAnimation) {
                    // ここに表示したいモーダルのウィジェットを指定
                    return const RaceCourseSelectionView();
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
                "駅伝コース紹介",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (ghensuu.mode == 110 ||
                (!(ghensuu.month == 2 && ghensuu.day == 25)))
              TextButton(
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                    barrierDismissible: true, // 背景タップで閉じられるようにする
                    barrierLabel: 'カスタム駅伝設定', // アクセシビリティ用ラベル
                    transitionDuration: const Duration(
                      milliseconds: 300,
                    ), // アニメーション時間
                    pageBuilder: (context, animation, secondaryAnimation) {
                      // ここに表示したいモーダルのウィジェットを指定
                      return const ModalCustomEkidenSettings(); // const を追加
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
                  "カスタム駅伝設定",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 255, 0),
                    decoration: TextDecoration.underline,
                    decorationColor: HENSUU.textcolor,
                  ),
                ),
              ),
            if (ghensuu.mode != 110 &&
                (ghensuu.month == 2 && ghensuu.day == 25))
              Text("(カスタム駅伝当日にはカスタム駅伝設定はできません)"),

            const SizedBox(height: 20),
            if (ghensuu.mode == 110 ||
                (!(ghensuu.month == 10 && ghensuu.day == 5) &&
                    !(ghensuu.month == 11 && ghensuu.day == 5) &&
                    !(ghensuu.month == 1 && ghensuu.day == 5) &&
                    !(ghensuu.month == 2 && ghensuu.day == 25)))
              TextButton(
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                    barrierDismissible: true, // 背景タップで閉じられるようにする
                    barrierLabel: '駅伝コース編集', // アクセシビリティ用ラベル
                    transitionDuration: const Duration(
                      milliseconds: 300,
                    ), // アニメーション時間
                    pageBuilder: (context, animation, secondaryAnimation) {
                      // ここに表示したいモーダルのウィジェットを指定
                      return const RaceCourseEditSelectionView(); // const を追加
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
                  "駅伝コース編集",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 255, 0),
                    decoration: TextDecoration.underline,
                    decorationColor: HENSUU.textcolor,
                  ),
                ),
              ),
            if (!(ghensuu.mode == 110 ||
                (!(ghensuu.month == 10 && ghensuu.day == 5) &&
                    !(ghensuu.month == 11 && ghensuu.day == 5) &&
                    !(ghensuu.month == 1 && ghensuu.day == 5) &&
                    !(ghensuu.month == 2 && ghensuu.day == 25))))
              Text("(駅伝開催日には駅伝コース編集はできません)"),

            const SizedBox(height: 20),
            if (ghensuu.mode == 110 ||
                (!(ghensuu.month == 6 && ghensuu.day == 15) &&
                    !(ghensuu.month == 10 && ghensuu.day == 5) &&
                    !(ghensuu.month == 10 && ghensuu.day == 15) &&
                    !(ghensuu.month == 11 && ghensuu.day == 5) &&
                    !(ghensuu.month == 1 && ghensuu.day == 5) &&
                    !(ghensuu.month == 2 && ghensuu.day == 25)))
              TextButton(
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                    barrierDismissible: true, // 背景タップで閉じられるようにする
                    barrierLabel: 'QRコードで設定入出力', // アクセシビリティ用ラベル
                    transitionDuration: const Duration(
                      milliseconds: 300,
                    ), // アニメーション時間
                    pageBuilder: (context, animation, secondaryAnimation) {
                      // ここに表示したいモーダルのウィジェットを指定
                      return const SettingsQrPage(); // const を追加
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
                  "QRコードで設定入出力",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 255, 0),
                    decoration: TextDecoration.underline,
                    decorationColor: HENSUU.textcolor,
                  ),
                ),
              ),
            if (!(ghensuu.mode == 110 ||
                (!(ghensuu.month == 6 && ghensuu.day == 15) &&
                    !(ghensuu.month == 10 && ghensuu.day == 5) &&
                    !(ghensuu.month == 10 && ghensuu.day == 15) &&
                    !(ghensuu.month == 11 && ghensuu.day == 5) &&
                    !(ghensuu.month == 1 && ghensuu.day == 5) &&
                    !(ghensuu.month == 2 && ghensuu.day == 25))))
              Text("(駅伝・駅伝予選開催日にはQRコード設定入出力はできません)"),

            const SizedBox(height: 40),
            // リンクボタン
            //LinkButtons(context, ghensuu!),

            //const SizedBox(height: 32),

            // 💡 ------------------ ここから追加 ------------------
            TextButton(
              onPressed: () {
                // ⬇︎ showLicensePage() の代わりにこちらを使います
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Theme(
                      // ⬇︎ ここで「ライセンス画面の中だけ」で有効になる色を指定します
                      data: Theme.of(context).copyWith(
                        // 画面全体の背景色を指定（例として白にしています）
                        scaffoldBackgroundColor: Colors.white,
                        // パッケージ名などが載るカードの背景色
                        cardColor: Colors.white,
                        // 文字色を黒（見やすい色）に強制的に上書きします
                        textTheme: Theme.of(context).textTheme.copyWith(
                          // ライセンス詳細の本文（ここが一番重要です）
                          bodySmall: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14.0,
                          ),
                          // パッケージ名などの文字
                          bodyMedium: const TextStyle(color: Colors.black87),
                          titleLarge: const TextStyle(color: Colors.black),
                          titleMedium: const TextStyle(color: Colors.black),
                        ),
                        // 上部のヘッダー（AppBar）の色も指定しておくと安心です
                        appBarTheme: const AppBarTheme(
                          backgroundColor: Colors.white, // ヘッダーの背景色
                          foregroundColor: Colors.black, // ヘッダーの文字・戻るボタンの色
                        ),
                      ),
                      // 実際のライセンス画面の表示部分
                      child: const LicensePage(
                        applicationName: '箱庭小駅伝SS',
                        applicationVersion: '1.7.6',
                        // applicationIcon: Image.asset('lib/assets/icon/icon_ss1024.png', width: 48, height: 48),
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                "ライセンス",
                style: TextStyle(
                  color: HENSUU.LinkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 💡 ------------------ ここまで追加 ------------------

            // constを削除して、可変的なウィジェットを追加できるようにする
            const Text(
              "SS 1.7.6 (21760)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8), // 適度な余白
            InkWell(
              onTap: _launchUrl,
              /*child: Text(
                // iOSの場合のみApp Storeへのリンクを表示
                'App Storeでアップデートを確認',
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),*/
              child: Text(
                // 実行中のOSによって表示テキストを切り替える
                Platform.isIOS
                    ? 'App Storeでアップデートを確認'
                    : 'Google Playでアップデートを確認',
                style: const TextStyle(
                  color: Colors.blue, // リンクの色
                  decoration: TextDecoration.underline, // 下線
                ),
              ),
            ),
            const SizedBox(height: 8), // 適度な余白
            const Text(
              "⭐️はじめに",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // 適度な余白
            const Text(
              "箱庭小駅伝SSをダウンロードしていただき誠にありがとうございます。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "このゲームは文字情報だけの駅伝シミュレーションゲームです。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "総監督(あなた)ができることは、選手の区間配置とレース中の指示だけです。選手は勝手に成長します。(金特訓と銀特訓で少し手助けできることもあるかもしれませんが)",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "肩の力を抜いて、ご自身のペースでお付き合いいただければ幸いです。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "なお、このゲームに登場する団体名・個人名は実在する団体・個人とは一切関係ありません。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(""),
            const Text("""⭐️プライバシーポリシー
1. 利用者情報の取り扱いについて
情報の取得・利用: 当アプリは、ユーザーの氏名、連絡先、位置情報などの個人情報を取得・利用することはありません。

第三者への提供: 当アプリが、ユーザーの許可なく情報を第三者に提供することはありません。

2. カメラおよび写真へのアクセスについて
カメラ機能: QRコードを読み取るために、ユーザーの許可を得てカメラ機能を使用します。

写真ライブラリ: 画像ファイルからQRコードを読み取るために、ユーザーの許可を得て端末内の写真へのアクセスを行います。

取得データの扱い: 読み取った画像およびデータは、QRコードの解析処理にのみ使用され、アプリ外部のサーバーへ送信・保存されることはありません。

3. データの共有（CSV/画像出力）機能について
外部出力: ユーザー自身の操作により、選手データ等をCSV/画像ファイルとして書き出し、外部（メール、SNS、ストレージサービス等）へ共有する機能を提供しています。

一時ファイルの保存: CSV/画像作成時、共有のために端末内の一時フォルダにファイルを保存しますが、このファイルは共有処理以外の目的で使用されることはありません。

共有先管理: データの送信先（共有先）はユーザー自身が選択・管理するものとし、アプリが自動的に情報を外部送信することはありません。

""", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 24),

            const Text(
              "⭐️名声について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "各大学は過去10年の成績に基づいて名声という値を保持しています。名声が高いほど有力な新入生が入学しやすくなります。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️チームの目標順位について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "駅伝の目標順位は総監督(あなた)が決定します。ただ、対校戦は常に8位、11月駅伝予選は常に7位、正月駅伝予選は常に10位が目標順位になります。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "このゲームの駅伝の2区以降では、目標順位を下回った順位でタスキを受けると、前半無理に突っ込んで入ってしまいタイムが悪化するという現象が起きます。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "一方、この目標順位をクリアすると、金または銀を獲得できたり、総監督が選手の能力を見抜くことができるようになったりします。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️金と銀について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "夏合宿で各選手の個性を伸ばす金特訓と銀特訓を行うことができます。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "春の定期支給と、チームの目標順位を達成した場合の支給があります。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "春の定期支給の支給額の多少は以下の基準に基づいています。（上の方が支給額が多い）。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "・三冠\n・駅伝か対校戦優勝\n・駅伝すべて3位以内\n・駅伝か対校戦どれか３位以内\n・対校戦8位以内もしくは10月駅伝5位以内もしくは11月駅伝8位以内もしくは正月駅伝10位以内\n・11月駅伝予選突破もしくは正月駅伝予選突破\n・上記のどれも未達成(最低額)",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️レース中の指示について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "駅伝と11月駅伝予選では、レース中走り出す直前に選手に指示を出すことができます。「スタート直後飛び出し」と「前半突っ込み」の成功確率は駅伝男の能力と、「前半抑え」の成功確率は平常心の能力と直結します。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "駅伝の2区以降での指示である「前半突っ込み」と「前半抑え」では「前半突っ込み」の方が効果は大きいです。ただ、その分失敗した時のタイム損も大きいです。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "正月駅伝予選では、各選手ごとにフリー走か集団走を選べます。集団走は最大6つの集団を作れます。集団走には設定タイムを指示しなくてはなりません。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️経験補正について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "同じ駅伝の同じ区間を過去に走ったことがあると、経験からタイムが少し良くなります。回数が増えるほど良くなります。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️選手の能力について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "【基本走力】　走力の基本となる能力。全てのタイム計算のもとになる。成長とともに変化する。春と夏の2回成長する。なお、選手の能力を見抜く総監督の能力を持ってしてもこの数値は見抜けませんし、金銀も使えません。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【調子】　駅伝(駅伝予選は除く)で影響する能力で、調子の数値が低いほどタイムが悪くなります。ただ、駅伝男の能力や平常心の能力には影響を与えませんので、飛び出しや突っ込み、抑えといった指示の成否には影響を与えません。なお、この画面の上部の「調子関連設定」で調子のタイムへの影響度などを設定できます。そのほか、コース編集画面での試走やコンピュータが区間配置を決める際のタイムの見積もりには調子の影響は入っていません。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【安定感】　調子を決定する際に参照する能力です。調子の最低保証値となります(当日の突発的体調不良を除く)。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "***この後説明するすべての能力の値は、金銀を使わない限り入学から卒業まで変わりません。***",
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ), // イタリック体を適用
            ),

            const Text(
              "【駅伝男】　ゾーンへの入りやすさです。スタート直後の飛び出しや前半突っ込みの成功確率と直結します。この能力の値については、値が低い選手が多くなるような調整を加えている点をご了承ください。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【平常心】　常に冷静でいられるかの能力です。前半抑えの成功確率と直結します。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【長距離粘り】　長い距離を走る際に必要になる能力。15km以上の距離から影響が出ます。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【スパート力】　フィニッシュの直前の走力。この能力が高いと短い距離の方が得意になる傾向。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【カリスマ】　11月駅伝予選の全組と駅伝1区で、ペースメーカーになれる能力。走る選手の中で一番この能力が高い選手がペースメークする仕様になっています。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【登り適性】　登り坂を走る能力。登りの多い区間や登り1万、クロカン1万に関係。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【下り適性】　下り坂を走る能力。下りの多い区間や下り1万、クロカン1万に関係。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【アップダウン対応力】　アップダウンが多い道を走る能力。アップダウンの多い区間やクロカン1万に関係。\nなお、このゲームでは、登り適正・下り適性・アップダウン対応力は全く無関係に値を設定しています。現実世界だと、クロカンが強ければ登りも強そうな気もするのですが、このゲームではそうはなっていません。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【ロード適性】　駅伝の2区以降および正月駅伝予選、対校戦ハーフ、市民ハーフ、ロード1万に関係する能力。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "【ペース変動対応力】　5千・1万のトラックレース、駅伝の1区から3区までと11月駅伝予選、正月駅伝予選、クロカン1万に関係する能力。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️総監督の能力について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "チーム目標順位をクリアすると、総監督(あなた)の能力が覚醒し、選手の能力を見抜く力がつくことがあります。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "なお、選手の能力を見抜く力がつくと、駅伝や11月駅伝予選に出場した場合の各選手の結果表示に各種能力のタイム補正値も表示されるようになりますが、マイナス表記はタイム良化、プラス表記はタイム悪化をあらわしています。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️学内記録・学内順位について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "学内記録と学内順位は、処理の軽量化のため、プレイヤーが総監督をしている大学のみ計算・記録しています。ですので、もし、別の大学の総監督になる場合には、移籍先の大学の学内記録・学内順位については、就任時から計算・記録を取り始めることになりますのでご了承ください。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️正月駅伝予選について",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "チーム全員が完全にフラットなコースのハーフマラソンを走り、各大学上位10名のタイムの合計で争います。\n選手ごとにフリー走かチーム内で集団走をするかを選べます。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️監督とコーチについて",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "ゲーム内の計算には一切影響を与えません。OBが就任します。30歳以上でないと就任しない仕様なので、最初の10年くらいは不在が続きます。また、はじめのうちは若い監督・コーチばかりになります。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️PC版(箱庭小駅伝・箱庭小駅伝2)のプレイ経験のある方へ",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "似ている部分もありますが、異なる部分もあります。先入観を持たずに全く別のゲームだと思ってプレイしていただいた方が混乱しないかもしれません。",
              style: TextStyle(color: Colors.white),
            ),
            const Text(
              "主な相違点としては、天候や疲労・怪我はありません。距離適性は自動で合わせるようになったので、ゲーム中に意識する必要はなくなりました。\n一方で、チームの目標順位をクリアすると、ポイントのようなものを獲得でき、そのポイントを使用して選手の能力を上げられる機能が追加されました。\nまた、初期状態では選手の能力を見ることはできず、タイムから推測するしかないようにしてみました。\nその他、駅伝の経験補正は、同じ駅伝の同じ区間を走ったことがある場合のみになりました。\n２までは100ｍ単位で計算を行っていたので区間途中での集団走も考慮に入れていて、その集団走のペースをカリスマが一番高い選手が決める、というのがありましたが、今作では１区間まるごと一つの計算で行なっているので、カリスマが影響するのは11月駅伝予選の全組と駅伝1区だけです。",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            const Text(
              "⭐️最後に",
              style: TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "攻略法がどうのこうのというより、ただの運ゲーかもしれません。電車での移動時間などのちょっとした暇つぶしにでもなれば幸いです。",
              style: TextStyle(color: Colors.white),
            ),
            // ここからモーダルではなく、直接画像を配置するコード
            const SizedBox(height: 24),
            const Text(
              "[参考資料]\nロード適性・ペース変動対応力と各競技との関係性",
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/nouryoku.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "[参考資料]\n各大会での獲得名声初期値一覧(目標順位1位の場合)",
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/meisei_10.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/meisei_11.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/meisei_01.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/meisei_custom.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // 横長の画像を画面幅に合わせて表示
            Center(
              child: Image.asset(
                'lib/assets/gazou/meisei_taikousen.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 60), // 下部の余白
          ],
        ),
      ),
    );
  }

  // リンクボタンをWidgetに分離
  // currentGhensuu を引数として受け取るように変更
  /*Widget LinkButtons(BuildContext context, Ghensuu currentGhensuu) {
    return Column(
      children: [
        // ModalZenhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        //if (currentGhensuu.hyojiracebangou == 2)
        /*TextButton(
          onPressed: () {
            showGeneralDialog(
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
        if (currentGhensuu.mode != 300 && currentGhensuu.mode != 350)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '監督する大学を変更', // アクセシビリティ用ラベル
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
              "監督する大学を変更",
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
              "(エントリー画面や指示画面では監督する大学を変更できません)",
              style: TextStyle(
                color: HENSUU.textcolor, // テキストの色
                fontSize: HENSUU.fontsize_honbun, // フォントサイズ
              ),
              textAlign: TextAlign.center, // テキストを中央寄せ
            ),
          ),*/
        // ModalKukanshouView は currentGhensuu.hyojiracebangou が 2 以下の時だけ表示
        //if (currentGhensuu.hyojiracebangou <= 2)
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '選手の能力を見抜く監督の能力をリセット', // アクセシビリティ用ラベル
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
            "選手の能力を見抜く監督の能力をリセット",
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
        //if (currentGhensuu.hyojiracebangou <= 2)
        TextButton(
          onPressed: () {
            showGeneralDialog(
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
              barrierLabel: '目標順位決め方設定(全大学共通)', // アクセシビリティ用ラベル
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
            "目標順位決め方設定(全大学共通)",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        if (currentGhensuu.mode != 300 && currentGhensuu.mode != 350)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: 'カスタム駅伝設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalCustomEkidenSettings(); // const を追加
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
              "カスタム駅伝設定",
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
              "(エントリー画面や指示画面ではカスタム駅伝設定はできません)",
              style: TextStyle(
                color: HENSUU.textcolor, // テキストの色
                fontSize: HENSUU.fontsize_honbun, // フォントサイズ
              ),
              textAlign: TextAlign.center, // テキストを中央寄せ
            ),
          ),
      ],
    );
  }*/
}
