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
import 'package:ekiden/screens/Modal_hoseiTsuyosa.dart';
import 'package:ekiden/screens/Modal_nouryokuEikyodo.dart';
import 'package:ekiden/screens/Modal_bairitu_goldsilver.dart';
import 'package:ekiden/screens/Modal_racejiki.dart';
import 'package:ekiden/screens/Modal_shumihihyouji.dart';
import 'package:ekiden/screens/Modal_TrainingEffect.dart';
import 'package:ekiden/screens/Modal_TimeChousei.dart';
import 'package:ekiden/settings_qr_page.dart';
import 'package:ekiden/screens/HenkouRireki_screen.dart';
import 'package:ekiden/screens/Modal_courseshoukai_kiten.dart';
import 'package:ekiden/screens/Modal_custom.dart';
import 'package:ekiden/screens/Modal_courseedit_kiten.dart';
import 'package:ekiden/screens/55fromNormal.dart';
import 'package:ekiden/screens/Modal_TTmode.dart';
import 'package:ekiden/screens/Modal_Skip.dart';
import 'package:ekiden/share_exporter.dart';
import 'package:ekiden/screens/Modal_memo.dart';
import 'package:ekiden/kansuu/shiyou_text.dart'; // 説明書の見出し1つ分(ShiyouSetsu)
import 'package:ekiden/kansuu/setsumeisho_text.dart'; // 説明書の本文

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  // 開いているタブ(0: 設定、1: 説明書)。アプリを起動している間だけ覚える
  // (ほかの画面に移って戻ってきても同じタブを開く。セーブデータには保存しない)
  static int _hirakiTabIndex = 0;
  late TabController _tabController;

  // Hive Boxの参照を保持
  //late Box<Ghensuu> _ghensuuBox;
  //late Box<SenshuData> _senshuBox; // 表示には直接使用しませんが、完全性のために保持
  //late Box<UnivData> _univBox;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _hirakiTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _hirakiTabIndex = _tabController.index;
      }
    });
    // initStateでHive Boxの参照を取得
    //_ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    //_senshuBox = Hive.box<SenshuData>('senshuBox');
    //_univBox = Hive.box<UnivData>('univBox');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('設定・説明書', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: true, // タイトルを中央に配置
        // 設定タブと説明書タブ
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '設定'),
            Tab(text: '説明書'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _setteiTab(context, ghensuu),
          _setsumeishoTab(context),
        ],
      ),
    );
  }

  // 設定タブ(各種設定・データ・コースなどの画面へのボタン)
  // 慣れてからもよく使うので、折りたたまずに並べる
  Widget _setteiTab(BuildContext context, Ghensuu ghensuu) {
    return SingleChildScrollView(
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
          // 目標順位・指示の補正の強さの設定(1.8.2)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '目標順位・指示の補正設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalHoseiTsuyosa();
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
            },
            child: Text(
              "目標順位・指示の補正設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 能力のタイムへの影響度の設定(1.8.2)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '能力のタイムへの影響度設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalNouryokuEikyodo();
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
            },
            child: Text(
              "能力のタイムへの影響度設定",
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
          const SizedBox(height: 60), // 下部の余白
        ],
      ),
    );
  }

  // 説明書タブ(版・変更履歴と説明書の本文)
  Widget _setsumeishoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0), // 全体にパディング
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // テキストを左寄せにする
        children: [
          const SizedBox(height: 20),
          // constを削除して、可変的なウィジェットを追加できるようにする
          const Text(
            "SS 1.8.4 (21840)",
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
          // 変更履歴(ToDo.txtの箱庭小駅伝SSの部分を表示)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HenkouRirekiScreen(),
                ),
              );
            },
            child: const Text(
              '変更履歴',
              style: TextStyle(
                color: Colors.blue, // リンクの色
                decoration: TextDecoration.underline, // 下線
              ),
            ),
          ),
          const SizedBox(height: 8), // 適度な余白
          // 説明書の本文(仕様の部分は生成AI向けの「ゲームの仕様」と共通。
          // 並びと説明書だけの部分は lib/kansuu/setsumeisho_text.dart、仕様の部分は lib/kansuu/shiyou_text.dart)
          for (final ShiyouSetsu setsu in setsumeishoSetsuList())
            ..._setsuWidgets(setsu),
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
          _midashiWidget('プライバシーポリシー'),
          const SizedBox(height: 8),
          const Text("""1. 利用者情報の取り扱いについて
情報の取得・利用: 当アプリは、ユーザーの氏名、連絡先、位置情報などの個人情報を取得・利用することはありません。

第三者への提供: 当アプリが、ユーザーの許可なく情報を第三者に提供することはありません。

2. カメラおよび写真へのアクセスについて
カメラ機能: QRコードを読み取るために、ユーザーの許可を得てカメラ機能を使用します。

写真ライブラリ: 画像ファイルからQRコードを読み取るために、ユーザーの許可を得て端末内の写真へのアクセスを行います。

取得データの扱い: 読み取った画像およびデータは、QRコードの解析処理にのみ使用され、アプリ外部のサーバーへ送信・保存されることはありません。

3. データの共有（CSV/画像出力）機能について
外部出力: ユーザー自身の操作により、選手データ等をCSV/画像ファイルとして書き出し、外部（メール、SNS、ストレージサービス等）へ共有する機能を提供しています。

一時ファイルの保存: CSV/画像作成時、共有のために端末内の一時フォルダにファイルを保存しますが、このファイルは共有処理以外の目的で使用されることはありません。

共有先管理: データの送信先（共有先）はユーザー自身が選択・管理するものとし、アプリが自動的に情報を外部送信することはありません。""", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 24),
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
                      applicationVersion: '1.8.4',
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
          const SizedBox(height: 60), // 下部の余白
        ],
      ),
    );
  }

  // 説明書の見出し1つ分(見出しと、1行に1つのことを書いた本文)
  List<Widget> _setsuWidgets(ShiyouSetsu setsu) {
    return [
      _midashiWidget(setsu.midashi),
      const SizedBox(height: 8),
      for (final String gyou in setsu.gyou) _gyouWidget(gyou),
      const SizedBox(height: 24),
    ];
  }

  // 説明書の見出し
  Widget _midashiWidget(String midashi) {
    return Text(
      '⭐️$midashi',
      style: const TextStyle(
        color: Colors.white,
        fontSize: HENSUU.fontsize_honbun,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 説明書の本文の1行
  // 「・」で始まる行は、折り返した2行目以降が「・」の後ろにそろうようにする。
  // 「　・」で始まる行は1段下げる。「・」で始まらない行は、そのままの文として出す
  Widget _gyouWidget(String gyou) {
    const TextStyle style = TextStyle(color: Colors.white);
    double sage = 0;
    String bun = gyou;
    if (bun.startsWith('　・')) {
      sage = 16;
      bun = bun.substring(1);
    }
    if (!bun.startsWith('・')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(bun, style: style),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: sage, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・', style: style),
          Expanded(child: Text(bun.substring(1), style: style)),
        ],
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
