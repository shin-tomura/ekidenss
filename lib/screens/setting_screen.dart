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
import 'package:ekiden/screens/Modal_koukouMeikan.dart'; // 高校名鑑(1.9.5)
import 'package:ekiden/screens/konki_best_parts.dart'; // 持ちタイムの表示設定(1.9.1)
import 'package:ekiden/screens/shuudan_settei.dart'; // 集団走設定(1.9.2)
import 'package:ekiden/screens/seichou_type_settei.dart'; // 成長タイプ設定(1.9.3)
import 'package:ekiden/screens/senryaku_entry_settei.dart'; // 戦略的エントリー確率設定(1.9.4)
import 'package:ekiden/screens/yosen_com_siji_settei.dart'; // 正月駅伝予選の指示と集団走(1.9.9)
import 'package:ekiden/screens/kyouka_project_settei.dart'; // 強化プロジェクト設定(2.0.1)
import 'package:ekiden/screens/bokou_pipe_settei.dart'; // 監督の母校パイプ設定(2.0.1)
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku; // リセット・ロード・QRで残るもの・変わるもの(2.0.3)
import 'package:ekiden/screens/meisei_yokonarabi_settei.dart'
    show meiseiYokonarabiSetteiHiraku; // 名声の横並び設定(2.0.3)
import 'package:ekiden/screens/Modal_TrainingEffect.dart';
import 'package:ekiden/screens/Modal_TimeChousei.dart';
import 'package:ekiden/settings_qr_page.dart';
import 'package:ekiden/screens/HenkouRireki_screen.dart';
import 'package:ekiden/screens/Modal_courseshoukai_kiten.dart';
import 'package:ekiden/screens/Modal_custom.dart';
import 'package:ekiden/screens/Modal_courseedit_kiten.dart';
import 'package:ekiden/screens/55fromNormal.dart';
import 'package:ekiden/screens/Modal_Skip.dart';
import 'package:ekiden/share_exporter.dart';
import 'package:ekiden/screens/Modal_memo.dart';
import 'package:ekiden/screens/setsumeisho_tab.dart'; // 説明書タブ(折りたたみ)
// 全大学共通の設定の画面(1.9.1で大学画面から設定タブに移した)
import 'package:ekiden/screens/univ_screen.dart'
    show
        ModalEkidenFameSettings,
        ModalSpurtryokuseichousisuu3,
        ModalSpurtryokuseichousisuu2,
        ModalGakurenHosei,
        // 1.9.8で大学画面から移した、全大学の一覧・総監督と難易度・やり直しの画面
        ModalIkuseiryokuHenkou,
        ModalRyugakuseiNinzu,
        ModalKantokuUnivHenkou,
        ModalNanidoHenkou,
        ModalOndoHenkou,
        ModalKiwameHosei,
        ModalMieruNouryokuReset,
        ModalMeiseiHenkou,
        ModalAllReset;
// 1.9.8で大学画面から移したボタンが開く画面
import 'package:ekiden/album.dart' show Album;
import 'package:ekiden/screens/Modal_univkoseiall.dart' show ModalAllUnivAbilityBulkSettingView;
import 'package:ekiden/screens/Modal_comGoldSilver.dart' show ModalComGoldSilver;
import 'package:ekiden/screens/Modal_comScout.dart' show ModalComScout;
import 'package:ekiden/screens/Modal_kukanHaichiHoushin.dart' show ModalKukanHaichiHoushin;
import 'package:ekiden/screens/tradeScreen.dart' show TradeScreen;
import 'package:ekiden/screens/Modal_reset_IkuseiryokuMeiseiIji.dart' show ModalReset_IkuseiryokuMeiseiIji;
import 'package:ekiden/screens/Modal_shinnyuuseiShingakusaki.dart' show ModalShinnyuuseiShingakusaki;
import 'package:ekiden/screens/senshu_r_screen.dart' show Senshu_R_Screen;
import 'package:ekiden/screens/riji_screen.dart' show RijiIchiranScreen;

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
  // 慣れてからもよく使うので、折りたたまずに並べる(1.9.4から見出しで分けた)
  Widget _setteiTab(BuildContext context, Ghensuu ghensuu) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0), // 全体にパディング
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // テキストを左寄せにする
        children: [
          // リセット・ロード(セーブデータの読み込み)・QRコードの読み込みで残るもの・変わるものの一覧(2.0.3。reset_ichiran_gamen.dart)
          TextButton(
            onPressed: () => resetIchiranGamenHiraku(context),
            child: Text(
              "リセット・ロード・QRで残るもの・変わるもの",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // ボタンは見出しで分ける(大学画面の下のほうと同じ形。1.9.4)
          _setteiMidashi('メモとデータ'),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          if (!(ghensuu.month == 10 && ghensuu.day == 15) &&
              !(ghensuu.month == 6 && ghensuu.day == 15) &&
              !(ghensuu.month == 10 && ghensuu.day == 5) &&
              !(ghensuu.month == 11 && ghensuu.day == 5) &&
              !(ghensuu.month == 1 && ghensuu.day == 5) &&
              !(ghensuu.month == 2 && ghensuu.day == 25) &&
              ghensuu.mode != 330)
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
          else // if文が成就しない場合（ghensuu.mode が 300 または 350 の場合）
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
          // 2つのリセット(2.0.3から、おすすめの「名声・育成力と設定を残してやり直す」を上にした。
          // 何を残すかは lib/kansuu/reset_ichiran.dart の一覧で決める)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '名声・育成力と設定を残してやり直す', // アクセシビリティ用ラベル
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
              "名声・育成力と設定を残してやり直す(おすすめ)",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          //if (ghensuu.hyojiracebangou <= 2)
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
          _setteiMidashi('モードと大会'),
          // 「夏TT開催大学変更」は1.8.8でなくした(夏の学内タイムトライアルはいつも全大学で行う)
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          _setteiMidashi('総監督と難易度'),
          // ---- 総監督(2.0.3。総監督・難易度ごとにまとめて並べた) ----
          // ModalKouhanKekkaView は ghensuu.hyojiracebangou が 2 の時だけ表示
          //if (ghensuu.mode != 300 && ghensuu.mode != 350)
          if (!(ghensuu.month == 10 && ghensuu.day == 15) &&
              !(ghensuu.month == 6 && ghensuu.day == 15) &&
              !(ghensuu.month == 10 && ghensuu.day == 5) &&
              !(ghensuu.month == 11 && ghensuu.day == 5) &&
              !(ghensuu.month == 1 && ghensuu.day == 5) &&
              !(ghensuu.month == 2 && ghensuu.day == 25) &&
              ghensuu.mode != 330)
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
          else // if文が成就しない場合（ghensuu.mode が 300 または 350 の場合）
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
          // ModalKukanshouView は ghensuu.hyojiracebangou が 2 以下の時だけ表示
          //if (ghensuu.hyojiracebangou <= 2)
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
          const SizedBox(height: 16),
          // ---- 難易度 ----
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
          //if (ghensuu.hyojiracebangou <= 2)
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
          _setteiMidashi('レースのタイム'),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          // 集団走設定(集団を引っ張る選手を決めるときの、その日の勢いの大きさ。1.9.2)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '集団走設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalShuudanSettei();
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
              "集団走設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                  return const ModalGakurenHosei();
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
              "学連選抜モチベーション設定",
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
          _setteiMidashi('コンピュータの大学の作戦'),
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
          const SizedBox(height: 8),
          // 戦略的エントリー確率設定(1.9.3までは調子関連設定の画面の中にあった。1.9.4)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '戦略的エントリー確率設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalSenryakuEntrySettei();
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
              "戦略的エントリー確率設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '目標順位決め方設定(コンピュータの大学)', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalSpurtryokuseichousisuu2();
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
              "目標順位決め方設定(コンピュータの大学)",
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
                barrierLabel: 'コンピュータ金銀使用', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalComGoldSilver();
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
              "コンピュータ金銀使用",
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
                barrierLabel: 'コンピュータスカウト', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalComScout();
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
              "コンピュータスカウト",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // 大学ごとの区間配置の方針(前半重視など。自分の大学は区間エントリーの初期案に使う。1.9.1)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '区間配置の方針', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalKukanHaichiHoushin();
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
              "区間配置の方針",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // コンピュータの大学の正月駅伝予選の指示と集団走(1.9.9。yosen_com_siji.dart)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '正月駅伝予選の指示と集団走', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalYosenComSijiSettei();
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
              "正月駅伝予選の指示と集団走",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // 強化プロジェクト(2.0.1。kyouka_project.dart)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '強化プロジェクト設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalKyoukaProjectSettei();
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
              "強化プロジェクト設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // 監督の母校パイプ(2.0.1。bokou_pipe.dart)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '監督の母校パイプ設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalBokouPipeSettei();
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
              "監督の母校パイプ設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          _setteiMidashi('育成と名声'),
          // ---- 育成(2.0.3。育成・名声ごとにまとめて並べた) ----
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '金銀支給量設定', // アクセシビリティ用ラベル
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
              "金銀支給量設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          // 成長タイプ設定(新入生の成長タイプの割合。1.9.3)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '成長タイプ設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalSeichouTypeSettei();
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
              "成長タイプ設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ---- 名声(名声の値・増え方・新入生のスカウトへの効き方の順) ----
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
          const SizedBox(height: 8),
          if (ghensuu.mode != 300 && ghensuu.mode != 330 && ghensuu.mode != 350)
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
                    return const ModalEkidenFameSettings();
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
                "駅伝名声設定",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 255, 0),
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            )
          else
            Text("(エントリー画面や指示画面では駅伝名声設定はできません)"),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '入学時名声影響度設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalSpurtryokuseichousisuu3();
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
              "入学時名声影響度設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 名声の横並び設定(2.0.3。2.0.2は入学時名声影響度設定の中の「名声上位の横並び」だった。
          // ブロック・グループ・名声の編集まで広がったので独立させた。meisei_yokonarabi_settei.dart)
          TextButton(
            onPressed: () => meiseiYokonarabiSetteiHiraku(context),
            child: Text(
              "名声の横並び設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          // 留学生受け入れ設定は1つだけだが、探しやすいように見出しを分けた(2.0.3)
          _setteiMidashi('留学生'),
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
          _setteiMidashi('表示'),
          // 持ちタイムの表示(自己ベスト/今季ベスト。1.9.1)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '持ちタイムの表示設定', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalKonkiBestSettei();
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
              "持ちタイムの表示設定",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '趣味・高校時代の表示設定', // アクセシビリティ用ラベル
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
              "趣味・高校時代の表示設定", // 1.9.5から出身校と高校時代の実績も切り替える
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          _setteiMidashi('見る・調べる'),
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
          const SizedBox(height: 8),
          // 高校名鑑(名門校の紹介と都道府県別の一覧。1.9.5。高校の情報を表示しない設定のときも開ける)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '高校名鑑', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalKoukouMeikan();
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
              "高校名鑑",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          // 今年の新入生の進学先(交渉・志望・留学生)を全大学分見る(1.8.0)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '新入生の進学先(全大学)', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const ModalShinnyuuseiShingakusaki();
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
              "新入生の進学先(全大学)",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final Album album = Hive.box<Album>('albumBox').get('AlbumData')!;
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
          const SizedBox(height: 60), // 下部の余白
        ],
      ),
    );
  }

  // 設定タブのボタンの見出し(大学画面の下のほうの見出しと同じ形。1.9.4)
  Widget _setteiMidashi(String text) {
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

  // 説明書タブ(版・変更履歴・アップデートの確認と、説明書の本文)
  // 本文の折りたたみは lib/screens/setsumeisho_tab.dart
  Widget _setsumeishoTab(BuildContext context) {
    const TextStyle linkStyle = TextStyle(
      color: Colors.blue, // リンクの色
      decoration: TextDecoration.underline, // 下線
    );
    return SetsumeishoTab(
      // 一番上: 版・変更履歴・アップデートの確認を1行にまとめる
      ueWidget: Wrap(
        spacing: 16,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "SS 2.0.6 (22060)",
            style: TextStyle(color: Colors.white),
          ),
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
            child: const Text('変更履歴', style: linkStyle),
          ),
          InkWell(
            onTap: _launchUrl,
            child: Text(
              // 実行中のOSによって表示テキストを切り替える
              Platform.isIOS
                  ? 'App Storeでアップデートを確認'
                  : 'Google Playでアップデートを確認',
              style: linkStyle,
            ),
          ),
        ],
      ),
      // 「その他」の一番下: ライセンス
      licenseWidget: TextButton(
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
                  applicationVersion: '2.0.6',
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
