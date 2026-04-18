import 'package:ekiden/screens/99First.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kansuu/kyouka_com.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/screens/0009updatefailed.dart';
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ekiden/screens/9080GashukuOK.dart';
import 'package:ekiden/screens/9100Gashuku.dart';
import 'package:flutter/services.dart'; // これを追加！
import 'package:ekiden/kansuu/GhensuuShokika.dart';
import 'package:ekiden/kansuu/ShokitiUnivdata.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/RetireNew.dart';
import 'package:ekiden/kansuu/goldsilverTeikiKakutoku.dart';
import 'package:ekiden/kansuu/SenshuShokiti.dart';
import 'package:ekiden/kansuu/asset_loader.dart';
import 'package:ekiden/kansuu/ShozokusakiKettei_By_Univmeisei.dart';
import 'package:ekiden/kansuu/Ikusei_Com.dart';
import 'package:ekiden/kansuu/EntryCalc.dart';
import 'package:ekiden/kansuu/Entry1Calc.dart';
import 'package:ekiden/kansuu/RaceCalc.dart';
import 'package:ekiden/kansuu/KirokuKousin.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/0015NanidoSelectionScreen.dart';
import 'package:ekiden/screens/0020UnivsentakuView.dart';
import 'package:ekiden/screens/0025UnivsentakukakuninView.dart';
import 'package:ekiden/screens/0027UnivnameKakunin.dart';
import 'package:ekiden/screens/0030UnivnameInput.dart';
import 'package:ekiden/screens/0035InputUnivnameKakunin.dart';
import 'package:ekiden/screens/8888GoldenKakutosuuView.dart';
import 'package:ekiden/screens/8890MierukaNouryokuView.dart';
import 'package:ekiden/screens/9000Freshmankakutoku.dart';
import 'package:ekiden/screens/latest_screen.dart';
import 'package:ekiden/screens/univ_screen.dart'; // 新しく作ったUnivScreenをインポート
import 'package:ekiden/screens/senshu_screen.dart'; // 新しく作ったUnivScreenをインポート
import 'package:ekiden/screens/record_screen.dart'; // 新しく作ったUnivScreenをインポート
import 'package:ekiden/screens/setting_screen.dart'; // 新しく作ったUnivScreenをインポート
import 'package:ekiden/screens/error_screen.dart';
import 'package:ekiden/toukei.dart';
import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/screens/Toujituhenkou.dart';
import 'package:ekiden/screens/ToujitsuAhenkou.dart';
import 'package:ekiden/screens/ToujitsuBhenkou.dart';
import 'package:ekiden/kansuu/univkosei.dart';
import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
import 'package:ekiden/screens/9003FreshHoushutu.dart';
//import 'package:ekiden/save_load_screen.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ★ここに buildAppTheme() 関数を記述する★
ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: HENSUU.backgroundcolor,
    canvasColor: HENSUU.backgroundcolor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: HENSUU.fontsize_honbun,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: HENSUU.fontsize_honbun,
      ),
      // ... その他のtextThemeスタイル ...
    ),

    // Flutter 3.0以降: DropdownMenuThemeData を設定する
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(
        fontSize: HENSUU.fontsize_honbun, // ドロップダウンメニューのテキストのデフォルトサイズ
        color: Colors.white,
      ),
      // 必要に応じて他のプロパティも設定 (例: surfaceTintColor)
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    primarySwatch: Colors.blue,
  );
}

// --- 仮の画面ウィジェット ---

class UnknownScreen extends StatelessWidget {
  final String message;
  const UnknownScreen({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '不明な画面: $message',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("通過1");
  await Hive.initFlutter();
  print("通過2");
  final prefs = await SharedPreferences.getInstance();

  Hive.registerAdapter(SenshuDataAdapter());
  Hive.registerAdapter(UnivDataAdapter());
  print("通過3");
  Hive.registerAdapter(GhensuuAdapter());
  print("通過4");
  Hive.registerAdapter(KirokuAdapter());
  print("通過5");
  Hive.registerAdapter(ShuudansouAdapter());
  print("通過6");
  Hive.registerAdapter(SkipAdapter());
  print("通過7");
  Hive.registerAdapter(SenshuRDataAdapter());
  print("通過8");
  Hive.registerAdapter(AlbumAdapter());
  print("通過9");
  Hive.registerAdapter(KantokuDataAdapter());
  print("通過10");
  Hive.registerAdapter(RijiDataAdapter());
  print("通過11");
  Hive.registerAdapter(SenshuGakurenDataAdapter());
  print("通過12");
  Hive.registerAdapter(UnivGakurenDataAdapter());
  print("通過13");
  //Box<Ghensuu> ghensuuBox;

  try {
    // --- Hive Boxのオープンと初期データ生成 ---
    Box<Ghensuu> ghensuuBox_test;
    // データの読み込みを試行
    ghensuuBox_test = await Hive.openBox<Ghensuu>('ghensuuBox');
    // データが正常に読み込めた場合は、エラーフラグをクリア
    await prefs.setBool('isDataCorrupted', false);
    await prefs.setBool('isUnknownErrorOccurred', false);
    print('Ghensuu Box opened successfully.');
  } catch (e) {
    // エラー文字列を文字列に変換
    final errorMessage = e.toString().toLowerCase();
    print("errorMessage= ${errorMessage}");
    // エラーメッセージに "hive" または "corrupt" など特定のキーワードが含まれているか確認
    if (errorMessage.contains('null') && errorMessage.contains('int')) {
      // データスキーマの問題や破損が原因と判断
      print('Hive data seems to be corrupted. Deleting old data...');

      // データスキーマが変更された場合、エラーをキャッチ
      print('Error: $e. Deleting old data and creating a new box.');
      // 既存のデータをすべて削除
      await Hive.deleteBoxFromDisk('ghensuuBox');
      await Hive.deleteBoxFromDisk('senshuBox');
      await Hive.deleteBoxFromDisk('univBox');
      await prefs.setBool('isDataCorrupted', true);
      await prefs.setBool('isUnknownErrorOccurred', false);
    } else {
      // Handle any other type of error
      print('An unknown error occurred during box opening: $e');
      await prefs.setBool('isDataCorrupted', false); // Ensure this is false
      await prefs.setBool('isUnknownErrorOccurred', true);
      print('Unknown error flag set.');
    }
  }
  final isUnknownErrorOccurred =
      prefs.getBool('isUnknownErrorOccurred') ?? false;
  //final isUnknownErrorOccurred = true;

  if (isUnknownErrorOccurred) {
  } else {
    Box<Ghensuu> ghensuuBox = await Hive.openBox<Ghensuu>('ghensuuBox');
    // Boxが空の場合、初期データを作成
    if (ghensuuBox.isEmpty) {
      print('Ghensuu Box is empty. Creating initial Ghensuu entry...');

      final initialGhensuu = Ghensuu.initial();

      final List<String> nameMaeLines = await loadLinesFromAsset(
        'lib/assets/data/name_mae.txt',
      );
      final List<String> nameAtoLines = await loadLinesFromAsset(
        'lib/assets/data/name_ato.txt',
      );

      for (
        int i = 0;
        i < nameMaeLines.length && i < initialGhensuu.name_mae.length;
        i++
      ) {
        initialGhensuu.name_mae[i] = nameMaeLines[i];
      }
      for (
        int i = 0;
        i < nameAtoLines.length && i < initialGhensuu.name_ato.length;
        i++
      ) {
        initialGhensuu.name_ato[i] = nameAtoLines[i];
      }

      final prefs = await SharedPreferences.getInstance();
      final isCorrupted = prefs.getBool('isDataCorrupted') ?? false;

      if (isCorrupted) {
        initialGhensuu.scoutChances = 9;
      } else {
        initialGhensuu.scoutChances = 7;
      }

      await ghensuuBox.put('global_ghensuu', initialGhensuu);
      print('Initial Ghensuu entry created.');
    } else {
      print('Ghensuu Box already contains data. Skipping initialization.');
    }

    // SenshuData用のBoxを開く
    final senshuBox = await Hive.openBox<SenshuData>('senshuBox');
    if (senshuBox.isEmpty) {
      print(
        'SenshuData Box is empty. Creating initial ${TEISUU.SENSHUSUU_TOTAL} SenshuData entries...',
      );
      for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
        await senshuBox.put(i, SenshuData.initial(id: i));
      }
      print('Initial ${TEISUU.SENSHUSUU_TOTAL} SenshuData entries created.');

      // SenshuShokitiSetteiByGakunenの呼び出しはそのまま残します（もし不要であれば削除してください）
      //await SenshuShokitiSetteiByGakunen(senshuBox); //
    } else {
      print('SenshuData Box already contains data. Skipping initialization.');
    }

    // UnivData用のBoxを開く
    final univBox = await Hive.openBox<UnivData>('univBox');
    if (univBox.isEmpty) {
      print(
        'UnivData Box is empty. Creating initial ${TEISUU.UNIVSUU} UnivData entries...',
      );
      for (int i = 0; i < TEISUU.UNIVSUU; i++) {
        await univBox.put(i, UnivData.initial(id: i));
      }
      print('Initial ${TEISUU.UNIVSUU} UnivData entries created.');

      //大学名読み込み
      final List<String> nameUnivLines = await loadLinesFromAsset(
        'lib/assets/data/name_univ.txt',
      );
      for (int i = 0; i < nameUnivLines.length && i < TEISUU.UNIVSUU; i++) {
        univBox.get(i)!.name = nameUnivLines[i];
      }
      final Ghensuu ghensuu = ghensuuBox.get(
        'global_ghensuu',
        defaultValue: Ghensuu.initial(),
      )!;

      //カスタム駅伝用の変数が実施できる状態じゃない場合は実施できるようにする
      //final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final Ghensuu? gh = ghensuuBox.getAt(0);
      final univDataBox = Hive.box<UnivData>('univBox');
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      if (gh?.kukansuu_taikaigoto[5] == 1) {
        sortedUnivData[0].name_tanshuku = "カスタム駅伝";
        gh?.kukansuu_taikaigoto[5] = 5;
        for (int i = 0; i < TEISUU.SUU_MAXKUKANSUU; i++) {
          gh?.kyori_taikai_kukangoto[5][i] = 10000;
          gh?.heikinkoubainobori_taikai_kukangoto[5][i] = 0.0;
          gh?.heikinkoubaikudari_taikai_kukangoto[5][i] = 0.0;
          gh?.kyoriwariainobori_taikai_kukangoto[5][i] = 0.0;
          gh?.kyoriwariaikudari_taikai_kukangoto[5][i] = 0.0;
          gh?.noborikudarikirikaekaisuu_taikai_kukangoto[5][i] = 0;
        }
        //常に全チーム出場、目標順位は常に10位
        for (int i = 0; i < TEISUU.UNIVSUU; i++) {
          sortedUnivData[i].taikaientryflag[5] = 1;
          sortedUnivData[i].mokuhyojuni[5] = 9;
        }
        if (gh?.spurtryokuseichousisuu1 == 300) {
          gh?.spurtryokuseichousisuu1 = 1;
          gh?.spurtryokuseichousisuu4 = 1;
          gh?.spurtryokuseichousisuu5 = 10;
        }
        await gh?.save();
        await sortedUnivData[0].save();
      }

      //念押しで
      for (int i = 0; i < TEISUU.UNIVSUU; i++) {
        sortedUnivData[i].taikaientryflag[5] = 1;
        sortedUnivData[i].mokuhyojuni[5] = 9;
        await sortedUnivData[i].save();
      }

      //if (ghensuu.scoutChances == 9) {
      ghensuu.mode = 9;
      //} else {
      //  ghensuu.mode = 10;
      //}

      await ghensuu.save(); // ghensuu.mode の変更を保存
    } else {
      print('UnivData Box already contains data. Skipping initialization.');

      //カスタム駅伝用の変数が実施できる状態じゃない場合は実施できるようにする
      //final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final Ghensuu? gh = ghensuuBox.getAt(0);
      final univDataBox = Hive.box<UnivData>('univBox');
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      if (gh?.kukansuu_taikaigoto[5] == 1) {
        sortedUnivData[0].name_tanshuku = "カスタム駅伝";
        gh?.kukansuu_taikaigoto[5] = 5;
        for (int i = 0; i < TEISUU.SUU_MAXKUKANSUU; i++) {
          gh?.kyori_taikai_kukangoto[5][i] = 10000;
          gh?.heikinkoubainobori_taikai_kukangoto[5][i] = 0.0;
          gh?.heikinkoubaikudari_taikai_kukangoto[5][i] = 0.0;
          gh?.kyoriwariainobori_taikai_kukangoto[5][i] = 0.0;
          gh?.kyoriwariaikudari_taikai_kukangoto[5][i] = 0.0;
          gh?.noborikudarikirikaekaisuu_taikai_kukangoto[5][i] = 0;
        }
        //常に全チーム出場、目標順位は常に10位
        for (int i = 0; i < TEISUU.UNIVSUU; i++) {
          sortedUnivData[i].taikaientryflag[5] = 1;
          sortedUnivData[i].mokuhyojuni[5] = 9;
        }
        if (gh?.spurtryokuseichousisuu1 == 300) {
          gh?.spurtryokuseichousisuu1 = 1;
          gh?.spurtryokuseichousisuu4 = 1;
          gh?.spurtryokuseichousisuu5 = 10;
        }
        await gh?.save();
        await sortedUnivData[0].save();
      }
      //念押しで
      for (int i = 0; i < TEISUU.UNIVSUU; i++) {
        sortedUnivData[i].taikaientryflag[5] = 1;
        //sortedUnivData[i].mokuhyojuni[5] = 9;
        await sortedUnivData[i].save();
      }
    }

    //名声編集用変数を1.2.3から導入
    //final Ghensuu? gh = ghensuuBox.getAt(0);
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    final parsedValue = int.tryParse(sortedUnivData[1].name_tanshuku);
    if (parsedValue == null || parsedValue < 1 || parsedValue > 10) {
      sortedUnivData[1].name_tanshuku = "1"; //10月駅伝名声倍率分子
      sortedUnivData[2].name_tanshuku = "1"; //10月駅伝名声倍率分母
      sortedUnivData[3].name_tanshuku = "1"; //11月駅伝名声倍率分子
      sortedUnivData[4].name_tanshuku = "1"; //11月駅伝名声倍率分母
      sortedUnivData[5].name_tanshuku = "1"; //正月駅伝名声倍率分子
      sortedUnivData[6].name_tanshuku = "1"; //正月駅伝名声倍率分母
      await sortedUnivData[1].save();
      await sortedUnivData[2].save();
      await sortedUnivData[3].save();
      await sortedUnivData[4].save();
      await sortedUnivData[5].save();
      await sortedUnivData[6].save();
    }
    //1.3.4からケガフラグをスカウト画面の交渉成功率に流用、アップデート直後に万が一スカウト画面から復帰する場合に備えて
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
    for (int i = 0; i < sortedSenshuData.length; i++) {
      if (sortedSenshuData[i].kegaflag == 0) {
        sortedSenshuData[i].kegaflag = 33;
        await sortedSenshuData[i].save();
      }
    }
    //1.4.3で留学生制度導入
    final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
    if (checkversionValue == null ||
        checkversionValue < 1430 ||
        checkversionValue > 999999999) {
      for (int i = 0; i < sortedUnivData.length; i++) {
        sortedUnivData[i].r = 0;
        //sortedUnivData[i].r = 4;
        await sortedUnivData[i].save();
      }
    }

    //1.4.4でkiroku.dartを追加(留学生記録と日本人記録)
    // 1. Boxを開く
    var kirokubox = await Hive.openBox<Kiroku>('kirokuBox');
    if (kirokubox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialKiroku = Kiroku();
      // 3. Boxに保存
      await kirokubox.put('KirokuData', initialKiroku);
      // Boxを閉じる（任意）
      //await kirokubox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final kirokuBox = Hive.box<Kiroku>('kirokuBox');
    // Boxからデータを読み込む
    final Kiroku? kiroku = kirokuBox.get('KirokuData');
    if (kiroku != null) {
      // データを使用
      print(kiroku.time_zentai_ryuugakusei_kukankiroku);
    } else {
     print('データが見つかりません');
    }
    */

    //1.4.7でshuudansou.dartを追加(正月駅伝予選集団走用)
    // 1. Boxを開く
    var shuudansoubox = await Hive.openBox<Shuudansou>('shuudansouBox');
    if (shuudansoubox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialShuudansou = Shuudansou();
      // 3. Boxに保存
      await shuudansoubox.put('ShuudansouData', initialShuudansou);
      // Boxを閉じる（任意）
      //await shuudansoubox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
    // Boxからデータを読み込む
    final Shuudansou? shuudansou = shuudansouBox.get('ShuudansouData');
    if (shuudansou != null) {
      // データを使用
      print(shuudansou.time_zentai_ryuugakusei_kukankiroku);
    } else {
     print('データが見つかりません');
    }*/

    //1.5.1でskip.dartを追加(100年統計用)
    // 1. Boxを開く
    var skipbox = await Hive.openBox<Skip>('skipBox');
    if (skipbox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialSkip = Skip();
      // 3. Boxに保存
      await skipbox.put('SkipData', initialSkip);
      // Boxを閉じる（任意）
      //await skipbox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final skipBox = Hive.box<Skip>('skipBox');
    // Boxからデータを読み込む
    final Skip? skip = skipBox.get('SkipData');
    if ( skip!= null) {
      // データを使用
      print(skip.averagetime_all_kojinkiroku_jap_yeargoto[0][0]);
    } else {
     print('データが見つかりません');
    }*/

    //1.5.2でalbum.dartを追加(100年統計用)
    // 1. Boxを開く
    var albumbox = await Hive.openBox<Album>('albumBox');
    if (albumbox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialAlbum = Album();
      // 3. Boxに保存
      await albumbox.put('AlbumData', initialAlbum);
      // Boxを閉じる（任意）
      //await albumbox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final albumBox = Hive.box<Album>('albumBox');
    // Boxからデータを読み込む
    final Album? album = albumBox.get('AlbumData');
    if ( album!= null) {
      // データを使用
      print(album.tourokusuu_total);
    } else {
     print('データが見つかりません');
    }*/

    //1.5.2でsenshu_r_data.dartを追加(アルバム表示用)
    // 1. Boxを開く
    var rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
    if (rsenshubox.isEmpty) {}
    //他の場所でアクセスするには
    /*
        final rsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
        // Box内の全ての値をリストとして取得します
        final allRetiredSenshu = rsenshuBox.values.toList();
        // 取得した全ての選手データをループ処理します
        for (var rsenshu in allRetiredSenshu) {
          // string_racesetumeiを""に設定
          rsenshu.string_racesetumei = "";
          await rsenshu.save();
        }
    */

    //1.5.5でkantoku_data.dartを追加(100年統計用)
    // 1. Boxを開く
    var kantokubox = await Hive.openBox<KantokuData>('kantokuBox');
    if (kantokubox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialKantoku = KantokuData();
      // 3. Boxに保存
      await kantokubox.put('KantokuData', initialKantoku);
      // Boxを閉じる（任意）
      //await kantokubox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    // Boxからデータを読み込む
    final KantokuData? kantoku = kantokuBox.get('KantokuData');
    if ( kantoku!= null) {
      // データを使用
      print(kantoku.rid);
    } else {
     print('データが見つかりません');
    }*/

    //1.5.8でriji_data.dartを追加
    // 1. Boxを開く
    var rijibox = await Hive.openBox<RijiData>('rijiBox');
    if (rijibox.isEmpty) {
      // 2. Kirokuのインスタンスを作成
      final initialRiji = RijiData();
      // 3. Boxに保存
      await rijibox.put('RijiData', initialRiji);
      // Boxを閉じる（任意）
      //await kantokubox.close();
    }
    //他の場所でアクセスするには
    /*
    // Hive.box() を使って、既に開いているBoxを取得
    final rijiBox = Hive.box<RijiData>('rijiBox');
    // Boxからデータを読み込む
    final RijiData? riji = rijiBox.get('RijiData');
    if (riji != null) {
      // データを使用
      print(riji.rid_riji[0]);
    } else {
      print('データが見つかりません');
    }*/

    //1.6.4でsenshu_gakuren_data.dartを追加(学連選抜用)
    // 1. Boxを開く
    var gakurensenshubox = await Hive.openBox<Senshu_Gakuren_Data>(
      'gakurenSenshuBox',
    );
    if (gakurensenshubox.isEmpty) {}
    //他の場所でアクセスするには
    /*
        final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
        // Box内の全ての値をリストとして取得します
        final allGakurenSenshu = gakurensenshuBox.values.toList();
        // 取得した全ての選手データをループ処理します
        for (var gakurensenshu in allGakurenSenshu) {
          // string_racesetumeiを""に設定
          gakurensenshu.string_racesetumei = "";
          await gakurensenshu.save();
        }
    */

    //1.6.4でuniv_gakuren_data.dartを追加(学連選抜用)
    // 1. Boxを開く
    var gakurenunivbox = await Hive.openBox<UnivGakurenData>('gakurenUnivBox');
    if (gakurenunivbox.isEmpty) {
      // 学連選抜のIDは、通常の大学IDと競合しないように大きな値（例: 999）を設定することが一般的です。
      // ここではID: 1000 を使用するとしています。
      const int gakurenId = 1000;
      // 1. ファクトリコンストラクタを使用してインスタンスを作成
      final gakurenData = UnivGakurenData.initial(id: gakurenId);
      // 2. 作成したインスタンスをHiveボックスに保存
      // 慣例として、IDフィールドをキーとして使用します。
      await gakurenunivbox.put(gakurenId, gakurenData);
      print("学連選抜 (ID: $gakurenId) の初期データを作成し、Hiveに保存しました。");
    }
    //他の場所でアクセスするには
    /*
        final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
        // Box内の全ての値をリストとして取得します
        final allGakurenUniv = gakurenunivBox.values.toList();
        // 取得した全ての選手データをループ処理します
        for (var gakurenuniv in allGakurenUniv) {
          // string_racesetumeiを""に設定
          gakurenuniv.name = "";
          await gakurenuniv.save();
        }
    */

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1550 ||
          checkversionValue > 999999999) {
        ////この中に付け足したい処理を書く
        final rsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
        // Box内の全ての値をリストとして取得します
        final allRetiredSenshu = rsenshuBox.values.toList();
        // 取得した全ての選手データをループ処理します
        for (var rsenshu in allRetiredSenshu) {
          // string_racesetumeiを""に設定
          rsenshu.string_racesetumei = "";
          rsenshu.sijiseikouflag = 100;
          await rsenshu.save();
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1640 ||
          checkversionValue > 999999999) {
        // Hive.box() を使って、既に開いているBoxを取得
        final albumBox = Hive.box<Album>('albumBox');
        // Boxからデータを読み込む
        final Album album = albumBox.get('AlbumData')!;
        album.yobiint4 = 5; //学連選抜モチベーション低下設定
        await album.save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1660 ||
          checkversionValue > 999999999) {
        // Hive.box() を使って、既に開いているBoxを取得
        final albumBox = Hive.box<Album>('albumBox');
        // Boxからデータを読み込む
        final Album album = albumBox.get('AlbumData')!;
        album.tourokusuu_total = 30; //コンピュータチームの最適解区間配置確率
        await album.save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1730 ||
          checkversionValue > 999999999) {
        sortedUnivData[9].name_tanshuku = "0"; //15000mを超える距離のタイム補正ONなら"1"
        await sortedUnivData[9].save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1760 ||
          checkversionValue > 999999999) {
        sortedUnivData[8].name_tanshuku = ""; //総監督の成績
        await sortedUnivData[8].save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 1790 ||
          checkversionValue > 999999999) {
        final kantokuBox = Hive.box<KantokuData>('kantokuBox');
        final KantokuData? kantoku = kantokuBox.get('KantokuData')!;
        kantoku!.yobiint2[2] = 25;
        kantoku.yobiint2[3] = 80;
        kantoku.yobiint2[4] = 50;
        kantoku.yobiint2[5] = 1;
        kantoku.yobiint2[6] = 1;
        kantoku.yobiint2[7] = 90;
        kantoku.yobiint2[8] = 50;
        kantoku.yobiint2[9] = 30;
        kantoku.yobiint2[10] = 0;
        kantoku.yobiint2[11] = 10;
        await kantoku.save();
        for (int i = 0; i < sortedSenshuData.length; i++) {
          sortedSenshuData[i].chousi = 100;
          await sortedSenshuData[i].save();
        }
        final Random random = Random();
        for (var senshu in sortedSenshuData) {
          if (senshu.gakunen == 4) {
            if (senshu.anteikan < kantoku.yobiint2[7]) {
              senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[7];
              await senshu.save();
            }
          }
          if (senshu.gakunen == 3) {
            if (senshu.anteikan < kantoku.yobiint2[8]) {
              senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[8];
              await senshu.save();
            }
          }
          if (senshu.gakunen == 2) {
            if (senshu.anteikan < kantoku.yobiint2[9]) {
              senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[9];
              await senshu.save();
            }
          }
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21001 ||
          checkversionValue > 999999999) {
        sortedUnivData[9].name_tanshuku = "1"; //長距離タイム抑制ON
        await sortedUnivData[9].save();
        final kantokuBox = Hive.box<KantokuData>('kantokuBox');
        final KantokuData kantoku = kantokuBox.get('KantokuData')!;
        kantoku.yobiint2[13] = 0; //長距離タイム全体抑制値
        await kantoku.save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21004 ||
          checkversionValue > 999999999) {
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
        final Random random = Random();
        for (var senshu in sortedSenshuData) {
          ////出身地+趣味
          int targetHobbyIndex = random.nextInt(
            HobbyDatabase.allHobbies.length,
          );
          // 都道府県: 27番目の要素 ("大阪府"と想定) -> インデックス 26
          int targetPrefectureIndex = random.nextInt(
            LocationDatabase.allPrefectures.length,
          );
          // ⭐ パック（格納）
          final int combinedIndex = PackedIndexHelper.packIndices(
            hobbyIndex: targetHobbyIndex,
            prefectureIndex: targetPrefectureIndex,
          );
          senshu.samusataisei = combinedIndex;
          await senshu.save();
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21090 ||
          checkversionValue > 999999999) {
        final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');
        for (int i_univ = 0; i_univ < TEISUU.UNIVSUU; i_univ++) {
          await resetAbilityTo100Percent(i_univ, kantokuBox);
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21110 ||
          checkversionValue > 999999999) {
        sortedUnivData[10].name_tanshuku = ""; //駅伝結果要約表示用
        await sortedUnivData[10].save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21120 ||
          checkversionValue > 999999999) {
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
        for (var senshu in sortedSenshuData) {
          senshu.kaifukuryoku = 0;
          await senshu.save();
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21140 ||
          checkversionValue > 999999999) {
        final kantokuBox = Hive.box<KantokuData>('kantokuBox');
        final KantokuData kantoku = kantokuBox.get('KantokuData')!;
        kantoku.yobiint2[16] = 4; //強化練習強度
        await kantoku.save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21180 ||
          checkversionValue > 999999999) {
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
        for (var senshu in sortedSenshuData) {
          if (senshu.kaifukuryoku < 0 || senshu.kaifukuryoku > 5) {
            senshu.kaifukuryoku = 0;
            await senshu.save();
          }
        }
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21240 ||
          checkversionValue > 999999999) {
        final Ghensuu gh = ghensuuBox.getAt(0)!;
        gh.nouryokumieruflag[0] = 1;
        gh.nouryokumieruflag[1] = 1;
        await gh.save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21540 ||
          checkversionValue > 999999999) {
        await updateAllSenshuChartdata_atusataisei();
        await refreshAllUnivAnalysisData();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21621 ||
          checkversionValue > 999999999) {
        sortedUnivData[12].name_tanshuku = ""; //統計データ表示用
        await sortedUnivData[12].save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21661 ||
          checkversionValue > 999999999) {
        sortedUnivData[13].name_tanshuku = ""; //メモ用
        await sortedUnivData[13].save();
      }
    }

    {
      //バージョンアップに伴い付け足す処理を書く
      final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (checkversionValue == null ||
          checkversionValue < 21690 ||
          checkversionValue > 999999999) {
        sortedUnivData[14].name_tanshuku = ""; //メモ用
        sortedUnivData[15].name_tanshuku = ""; //メモ用
        sortedUnivData[16].name_tanshuku = ""; //メモ用
        sortedUnivData[17].name_tanshuku = ""; //メモ用
        await sortedUnivData[14].save();
        await sortedUnivData[15].save();
        await sortedUnivData[16].save();
        await sortedUnivData[17].save();
      }
    }

    //1.4.3からバージョン番号保存することにした(この処理は一連の処理の中で1番最後にすること)
    //save_load_screenの中の _importFromSlot の中にもあるので、そちらも変更すること！
    final versionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
    if (versionValue == null ||
        versionValue < 21760 ||
        versionValue > 999999999) {
      sortedUnivData[7].name_tanshuku = "21760"; //バージョン番号
      await sortedUnivData[7].save();
    }

    // Hive.box() を使って、既に開いているBoxを取得
    /*final skipBox = Hive.box<Skip>('skipBox');
    // Boxからデータを読み込む
    final Skip skip = skipBox.get('SkipData')!;
    skip.skipflag = 2; //1は5000・10000・ハーフの記録のみとる、2は駅伝もやる、3はdelayでCPUを休ませながら2を行う
    skip.skipyear = 30;*/

    // システムオーバーレイのスタイルを設定
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // ステータスバーの背景色を黒に
        statusBarIconBrightness:
            Brightness.light, // ステータスバーのアイコン（時計、Wi-Fiなど）を明るい色に
        statusBarBrightness: Brightness.dark, // iOSのステータスバーのアイコンを暗い色に（iOS向け）
        systemNavigationBarColor: Colors.black, // ナビゲーションバーの背景色を黒に (Android)
        systemNavigationBarIconBrightness:
            Brightness.light, // ナビゲーションバーのアイコンを明るい色に (Android)
      ),
    );
  }

  // ★★★ 4. セーブスロット用メタデータ Box の開放 (ここを追加/修正) ★★★
  // kMetaBoxName は 'saveSlotsMetaBox' のはずです。
  // スロット情報は Map<dynamic, dynamic> として保存されます。
  await Hive.openBox<Map<dynamic, dynamic>>('saveSlotsMetaBox');

  //ゲームが続きの場合の初期画面
  final Box<Ghensuu> ghensuuBox_first = Hive.box<Ghensuu>('ghensuuBox');
  final Ghensuu ghensuuFirst = ghensuuBox_first.getAt(0)!;
  if (ghensuuFirst.mode >= 100) {
    //if (ghensuuFirst.mode != 99) {
    final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = _kantokuBox.get('KantokuData')!;
    kantoku.yobiint2[18] = ghensuuFirst.mode;
    await kantoku.save();
    ghensuuFirst.mode = 99;
    await ghensuuFirst.save();
  }

  Chousa.lastGapTime = DateTime.now();

  if (isUnknownErrorOccurred) {
    runApp(const ErrorScreen());
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// WidgetsBindingObserver をミックスイン
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;
  late Box<Kiroku> _kirokuBox;
  late Box<Shuudansou> _shuudansouBox;
  late Box<Skip> _skipBox;
  late Box<Album> _albumBox;
  late Box<Senshu_R_Data> _retiredsenshuBox;
  late Box<KantokuData> _kantokuBox;
  late Box<RijiData> _rijiBox;

  // _isMode10Processing はこのコンテキストでは直接関係しないためコメントアウト
  // bool _isMode10Processing = false; // mode 10 の処理が実行中かどうかのフラグ

  @override
  void initState() {
    super.initState();
    // WidgetsBindingObserver を登録
    WidgetsBinding.instance.addObserver(this);

    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _kirokuBox = Hive.box<Kiroku>('kirokuBox');
    _shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
    _skipBox = Hive.box<Skip>('skipBox');
    _albumBox = Hive.box<Album>('albumBox');
    _retiredsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _rijiBox = Hive.box<RijiData>('rijiBox');
  }

  bool _isMode10Processing = false; // mode 10 の処理が実行中かどうかのフラグ
  // アプリのライフサイクル状態が変更されたときに呼び出される
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('AppLifecycleState: $state'); // デバッグ用に状態を出力

    if (state == AppLifecycleState.paused) {
      // アプリがバックグラウンドに移行したときに保存処理を実行
      print('App is paused. Saving data...');
      _saveAllHiveBoxes();
    } else if (state == AppLifecycleState.detached) {
      // アプリが終了する直前（iOSではあまり発生しないがAndroidではあり得る）
      print('App is detached. Saving data and closing boxes...');
      _saveAllHiveBoxes();
      // Hive Boxを閉じる（通常はアプリ終了時に自動的に行われるが、明示的に行うことも可能）
      // await _ghensuuBox.close(); // 必要であれば
      // await _senshuBox.close();  // 必要であれば
      // await _univBox.close();    // 必要であれば
    }
  }

  // 全てのHive Boxのデータを保存する関数
  Future<void> _saveAllHiveBoxes() async {
    try {
      // Ghensuu Boxの保存
      //final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final Ghensuu? ghensuu = _ghensuuBox.get('global_ghensuu');
      if (ghensuu != null) {
        await ghensuu.save(); // HiveObjectの変更を保存
      }

      // SenshuData Boxの保存 (全てのSenshuDataオブジェクトを保存)
      for (var senshu in _senshuBox.values) {
        await senshu.save();
      }

      // UnivData Boxの保存 (全てのUnivDataオブジェクトを保存)
      for (var univ in _univBox.values) {
        await univ.save();
      }

      final Kiroku? kiroku = _kirokuBox.get('KirokuData');
      if (kiroku != null) {
        await kiroku.save();
      }

      final Shuudansou? shuudansou = _shuudansouBox.get('ShuudansouData');
      if (shuudansou != null) {
        await shuudansou.save();
      }

      final Skip? skip = _skipBox.get('SkipData');
      if (skip != null) {
        await skip.save();
      }

      final Album? album = _albumBox.get('AlbumData');
      if (album != null) {
        await album.save();
      }

      //var open_rsenshubox = await Hive.openBox<Senshu_R_Data>(
      //  'retiredSenshuBox',
      //);
      //if (_retiredsenshuBox != null) {
      for (var rsenshu in _retiredsenshuBox.values) {
        await rsenshu.save();
      }
      //}

      final KantokuData? kantoku = _kantokuBox.get('KantokuData');
      if (kantoku != null) {
        await kantoku.save();
      }

      final RijiData? riji = _rijiBox.get('RijiData');
      if (riji != null) {
        await riji.save();
      }

      print('All Hive boxes data saved successfully.');
    } catch (e) {
      print('Error saving Hive data during lifecycle change: $e');
    }
  }

  @override
  void dispose() {
    // WidgetsBindingObserver の登録を解除
    WidgetsBinding.instance.removeObserver(this);
    // Boxを閉じる（アプリ終了時に自動的に閉じられることが多いですが、明示的に行うことも可能）
    // _ghensuuBox.close();
    // _senshuBox.close();
    // _univBox.close();
    super.dispose();
  }

  /*  @override
  Widget build(BuildContext context) {
    // ここにアプリのメインUIを記述します。
    // 例として、前回のMyMainScreenのbuildメソッドの内容をここに移動できます。
    // または、既存のMyAppのbuildメソッドの内容をそのまま使用してください。

    // 例: Ghensuuデータを表示するシンプルなUI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekiden アプリ'),
      ),
      body: Center(
        child: ValueListenableBuilder<Box<Ghensuu>>(
          valueListenable: _ghensuuBox.listenable(),
          builder: (context, box, _) {
            final Ghensuu? ghensuu = box.get('global_ghensuu');
            if (ghensuu == null) {
              return const Text('Ghensuuデータがありません');
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('現在のモード: ${ghensuu.mode}'),
                Text('ゴールデンボール数: ${ghensuu.goldenballsuu}'),
                ElevatedButton(
                  onPressed: () {
                    // データを変更して保存
                    ghensuu.mode = (ghensuu.mode + 1) % 10;
                    ghensuu.goldenballsuu += 1;
                    ghensuu.save(); // 個々のHiveObjectの変更を保存
                    print('Data updated and saved: Mode=${ghensuu.mode}, GoldenBalls=${ghensuu.goldenballsuu}');
                  },
                  child: const Text('データを更新'),
                ),
                // ここに他のUI要素やナビゲーションを追加
              ],
            );
          },
        ),
      ),
    );
  }*/
  // ★★★ ADD/MODIFY/DELETE START ★★★
  // 例として、非同期で実行されるダミーのゲーム処理関数
  Future<void> _runMode0010Processing(Ghensuu ghensuu) async {
    // ★★★ フラグを設定 START ★★★
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    // ★★★ フラグを設定 END ★★★

    print('現在モード10: 初期処理を実行中...');
    // ここでmode10で実行したい実際の処理を書く

    // Boxからデータを読み込む
    final RijiData? riji = _rijiBox.get('RijiData');
    if (riji != null) {
      for (int i = 0; i < 10; i++) {
        riji.rid_riji[i] = 0;
      }
      await riji.save();
    }

    // Boxからデータを読み込む
    final KantokuData? kantoku = _kantokuBox.get('KantokuData');
    if (kantoku != null) {
      for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
        kantoku.rid[i] = 0;
        kantoku.yobiint0[i] = 0;
        kantoku.yobiint1[i] = 0;
        kantoku.yobiint2[i] = 0;
        kantoku.yobiint3[i] = 0;
        kantoku.yobiint4[i] = 0;
        kantoku.yobiint5[i] = 0;
      }
      kantoku.yobiint2[2] = 25;
      kantoku.yobiint2[3] = 70;
      kantoku.yobiint2[4] = 50;
      kantoku.yobiint2[5] = 1;
      kantoku.yobiint2[6] = 1;
      kantoku.yobiint2[7] = 90;
      kantoku.yobiint2[8] = 50;
      kantoku.yobiint2[9] = 30;
      kantoku.yobiint2[10] = 0;
      kantoku.yobiint2[11] = 10;
      kantoku.yobiint2[12] = 2; //Sと比べての金銀支給量倍率
      kantoku.yobiint2[13] = 0; //長距離タイム全体抑制値
      kantoku.yobiint2[16] = 4; //強化練習強度
      await kantoku.save();

      for (int i_univ = 0; i_univ < TEISUU.UNIVSUU; i_univ++) {
        await resetAbilityTo100Percent(i_univ, _kantokuBox);
      }
    }

    // 1. 卒業選手 (アルバム) のBox内のデータをすべて削除
    // Boxが空でも、エラーにはなりません。
    await _retiredsenshuBox.clear();

    // 2. アルバムの表示番号を0にリセットし、保存
    final Album? album = _albumBox.get('AlbumData');
    if (album != null) {
      album.hyojisenshunum = 0;
      await album.save();
    }
    // album.hyojisenshunum をリセットすることで、次に誰か選手が追加された時に
    // インデックス外のエラーを防ぎ、0番目の選手を正しく表示できます。

    var kirokubox = await Hive.openBox<Kiroku>('kirokuBox');

    // 2. Kirokuのインスタンスを作成
    final initialKiroku = Kiroku();
    // 3. Boxに保存
    await kirokubox.put('KirokuData', initialKiroku);
    // Boxを閉じる（任意）
    //await kirokubox.close();

    // 例: Hiveからデータをロードしたり、計算を行ったり
    //final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    await GhensuuShokika(_ghensuuBox);
    print('GhensuuShokika完了');
    await ShokitiUnivdata(false, _univBox);
    print('ShokitiUnivdata完了');
    await SenshuShokitiSetteiByGakunen(0); //
    print('SenshuShokitiSetteiByGakunen完了');

    // --- 1. sortedUnivData の準備 ---
    List<UnivData> sortedUnivsById = _univBox.toMap().values.toList();
    sortedUnivsById.sort((a, b) => a.id.compareTo(b.id));

    // --- 2. nyuugakuji5000SenshuData の準備 ---
    List<SenshuData> allSenshus = _senshuBox.toMap().values.toList();
    // 例として、入学時の学年である「1」を指定してフィルタリング・ソート
    // この `1` は、ShozokusakiKettei_By_Univmeisei に渡す `gakunen` と一致させる必要があります。

    for (int gakunenToAssign = 1; gakunenToAssign <= 4; gakunenToAssign++) {
      List<SenshuData> nyuugakujiSenshusSortedByRecord = allSenshus
          .toList(); // .toList() をすることで、ソート時に元のリストが変更されないようにする
      nyuugakujiSenshusSortedByRecord.sort(
        (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
      );

      //final List<Ghensuu> gh = [_ghensuuBox.getAt(0)!];
      // --- 3. ShozokusakiKettei_By_Univmeisei の呼び出し ---
      await ShozokusakiKettei_By_Univmeisei(
        sortedunivdata: sortedUnivsById, // 引数名を明示
        nyuugakuji5000_senshudata: nyuugakujiSenshusSortedByRecord, // 引数名を明示
        gakunen: gakunenToAssign,
        ghensuu: ghensuu,
      );

      // --- 4. 変更された選手データをHiveに保存し直す (重要！) ---
      // ShozokusakiKettei_By_Univmeisei 関数は SenshuData の `univid` を変更するため、
      // その変更を永続化するためにHive Boxに保存し直す必要があります。
      for (final senshu in nyuugakujiSenshusSortedByRecord) {
        await _senshuBox.put(senshu.id, senshu);
      }
    }
    // --- gh (Ghensuu) の準備 ---
    // ghensuu オブジェクトは引数として既に渡されていますが、
    // Ikusei_Com が List<Ghensuu> を要求するため、リストに格納します。
    List<Ghensuu> gh_list = [
      ghensuu,
    ]; // あるいは _ghensuuBox.get('global_ghensuu') を取得してリストにする

    // --- sortedunivdata (UnivData) の準備 ---
    List<UnivData> sortedunivdata_ready = _univBox.toMap().values.toList();
    sortedunivdata_ready.sort((a, b) => a.id.compareTo(b.id));

    // --- sortedsenshudata (SenshuData) の準備 ---
    List<SenshuData> sortedsenshudata_ready = _senshuBox
        .toMap()
        .values
        .toList();
    sortedsenshudata_ready.sort((a, b) => a.id.compareTo(b.id));

    // --- ここから Ikusei_Com の呼び出しループ ---
    // 例として、(2年から4年) の選手を育成*2回(春と夏の分)
    for (int i = 0; i < 2; i++) {
      for (
        int gakunen_to_process = 2;
        gakunen_to_process <= 4;
        gakunen_to_process++
      ) {
        print('学年 $gakunen_to_process の選手を育成中...');
        await Ikusei_Com(
          gh: gh_list,
          sortedunivdata: sortedunivdata_ready,
          sortedsenshudata: sortedsenshudata_ready,
          gakunen: gakunen_to_process, // 現在処理する学年を渡す
        );
        // --- 変更された選手データをHiveに保存し直す (重要！) ---
        // Ikusei_Com は sortedsenshudata の内容を変更するため、永続化が必要です。
        // sortedunivdata は変更されないと仮定します。
        for (final senshu in sortedsenshudata_ready) {
          await _senshuBox.put(senshu.id, senshu);
        }
      }
    }
    for (final entry in _senshuBox.toMap().entries) {
      //final int senshuId = entry.key;
      final SenshuData senshu = entry.value;
      if (senshu.gakunen == 2) {
        senshu.seichoutype = 1;
      }
      if (senshu.gakunen == 3) {
        senshu.seichoutype = 2;
      }
      if (senshu.gakunen == 4) {
        senshu.seichoutype = 3;
      }
      await _senshuBox.put(senshu.id, senshu);
    }

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    sortedUnivsById[8].name_tanshuku = ""; //監督の実績表示用
    await sortedUnivsById[8].save();
    //sortedUnivsById[9].name_tanshuku = "0"; //10000mを超える距離のタイム補正
    //await sortedUnivsById[9].save();
    sortedUnivsById[10].name_tanshuku = ""; //駅伝結果要約表示用
    await sortedUnivsById[10].save();

    print('モード10処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // 処理が終わったらモードを15に更新し、UIを更新
    ghensuu.mode = 15;
    ghensuu.gamenflag = 0; // 最新画面を表示
    await _ghensuuBox.put(
      'global_ghensuu',
      ghensuu,
    ); // GhensuuのデータをHiveに保存してUIを更新
  }

  Future<void> _runMode9005Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード9005: 別の処理を実行中...');
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    //final List<Ghensuu> gh = [ghensuuBox.getAt(0)!]; // gh[0]としてアクセスするためにリストに入れる
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    List<SenshuData> sortedSenshuData = _senshuBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

    // 処理のシミュレーション（元のコードから削除）
    // await Future.delayed(const Duration(milliseconds: 3000));

    List<Ghensuu> gh_list = [ghensuu];
    // --- 個人ベスト記録の全体順位・学内順位更新 ---
    for (
      int kirokubangou = 0;
      kirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
      kirokubangou++
    ) {
      // 同期処理
      kojinBestKirokuJuniKettei(kirokubangou, gh_list, sortedSenshuData);
    }

    // 選手データをHiveに保存 (非同期処理)
    for (final senshu in sortedSenshuData) {
      await senshu.save();
    }

    await updateAllSenshuChartdata_atusataisei();
    await refreshAllUnivAnalysisData();

    if (kantoku.yobiint2[0] != 2) {
      ghensuu.mode = 8888;
    } else {
      ghensuu.mode = 100;
    }

    print('モード9005処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await ghensuu.save(); // ghensuuオブジェクトの変更を保存
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode101010Processing(Ghensuu ghensuu) async {
    // ★★★ フラグを設定 START ★★★
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    // ★★★ フラグを設定 END ★★★

    print('現在モード101010: 初期処理を実行中...');
    // ここでmode10で実行したい実際の処理を書く

    // Boxからデータを読み込む
    final RijiData? riji = _rijiBox.get('RijiData');
    if (riji != null) {
      for (int i = 0; i < 10; i++) {
        riji.rid_riji[i] = 0;
      }
      await riji.save();
    }

    // Boxからデータを読み込む
    final KantokuData? kantoku = _kantokuBox.get('KantokuData');
    if (kantoku != null) {
      for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
        kantoku.rid[i] = 0;
        kantoku.yobiint0[i] = 0;
        kantoku.yobiint1[i] = 0;
        kantoku.yobiint2[i] = 0;
        kantoku.yobiint3[i] = 0;
        kantoku.yobiint4[i] = 0;
        kantoku.yobiint5[i] = 0;
      }
      kantoku.yobiint2[2] = 25;
      kantoku.yobiint2[3] = 70;
      kantoku.yobiint2[4] = 50;
      kantoku.yobiint2[5] = 1;
      kantoku.yobiint2[6] = 1;
      kantoku.yobiint2[7] = 90;
      kantoku.yobiint2[8] = 50;
      kantoku.yobiint2[9] = 30;
      kantoku.yobiint2[10] = 0;
      kantoku.yobiint2[11] = 10;
      kantoku.yobiint2[12] = 2; //Sと比べての金銀支給量倍率
      kantoku.yobiint2[13] = 0; //長距離タイム全体抑制値
      kantoku.yobiint2[16] = 4; //強化練習強度
      await kantoku.save();

      for (int i_univ = 0; i_univ < TEISUU.UNIVSUU; i_univ++) {
        await resetAbilityTo100Percent(i_univ, _kantokuBox);
      }
    }

    // 1. 卒業選手 (アルバム) のBox内のデータをすべて削除
    // Boxが空でも、エラーにはなりません。
    await _retiredsenshuBox.clear();

    // 2. アルバムの表示番号を0にリセットし、保存
    final Album? album = _albumBox.get('AlbumData');
    if (album != null) {
      album.hyojisenshunum = 0;
      await album.save();
    }
    // album.hyojisenshunum をリセットすることで、次に誰か選手が追加された時に
    // インデックス外のエラーを防ぎ、0番目の選手を正しく表示できます。

    var kirokubox = await Hive.openBox<Kiroku>('kirokuBox');

    // 2. Kirokuのインスタンスを作成
    final initialKiroku = Kiroku();
    // 3. Boxに保存
    await kirokubox.put('KirokuData', initialKiroku);
    // Boxを閉じる（任意）
    //await kirokubox.close();

    // 例: Hiveからデータをロードしたり、計算を行ったり
    //final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    await GhensuuShokika(_ghensuuBox);
    print('GhensuuShokika完了');
    await ShokitiUnivdata(true, _univBox);
    print('ShokitiUnivdata完了');
    await SenshuShokitiSetteiByGakunen(0); //
    print('SenshuShokitiSetteiByGakunen完了');

    // --- 1. sortedUnivData の準備 ---
    List<UnivData> sortedUnivsById = _univBox.toMap().values.toList();
    sortedUnivsById.sort((a, b) => a.id.compareTo(b.id));

    // --- 2. nyuugakuji5000SenshuData の準備 ---
    List<SenshuData> allSenshus = _senshuBox.toMap().values.toList();
    // 例として、入学時の学年である「1」を指定してフィルタリング・ソート
    // この `1` は、ShozokusakiKettei_By_Univmeisei に渡す `gakunen` と一致させる必要があります。

    for (int gakunenToAssign = 1; gakunenToAssign <= 4; gakunenToAssign++) {
      List<SenshuData> nyuugakujiSenshusSortedByRecord = allSenshus
          .toList(); // .toList() をすることで、ソート時に元のリストが変更されないようにする
      nyuugakujiSenshusSortedByRecord.sort(
        (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
      );

      final List<Ghensuu> gh = [ghensuu];
      // --- 3. ShozokusakiKettei_By_Univmeisei の呼び出し ---
      await ShozokusakiKettei_By_Univmeisei(
        sortedunivdata: sortedUnivsById, // 引数名を明示
        nyuugakuji5000_senshudata: nyuugakujiSenshusSortedByRecord, // 引数名を明示
        gakunen: gakunenToAssign,
        ghensuu: gh[0],
      );

      // --- 4. 変更された選手データをHiveに保存し直す (重要！) ---
      // ShozokusakiKettei_By_Univmeisei 関数は SenshuData の `univid` を変更するため、
      // その変更を永続化するためにHive Boxに保存し直す必要があります。
      for (final senshu in nyuugakujiSenshusSortedByRecord) {
        await _senshuBox.put(senshu.id, senshu);
      }
    }
    // --- gh (Ghensuu) の準備 ---
    // ghensuu オブジェクトは引数として既に渡されていますが、
    // Ikusei_Com が List<Ghensuu> を要求するため、リストに格納します。
    List<Ghensuu> gh_list = [
      ghensuu,
    ]; // あるいは _ghensuuBox.get('global_ghensuu') を取得してリストにする

    // --- sortedunivdata (UnivData) の準備 ---
    List<UnivData> sortedunivdata_ready = _univBox.toMap().values.toList();
    sortedunivdata_ready.sort((a, b) => a.id.compareTo(b.id));

    // --- sortedsenshudata (SenshuData) の準備 ---
    List<SenshuData> sortedsenshudata_ready = _senshuBox
        .toMap()
        .values
        .toList();
    sortedsenshudata_ready.sort((a, b) => a.id.compareTo(b.id));

    // --- ここから Ikusei_Com の呼び出しループ ---
    // 例として、(2年から4年) の選手を育成*2回(春と夏の分)
    for (int i = 0; i < 2; i++) {
      for (
        int gakunen_to_process = 2;
        gakunen_to_process <= 4;
        gakunen_to_process++
      ) {
        print('学年 $gakunen_to_process の選手を育成中...');
        await Ikusei_Com(
          gh: gh_list,
          sortedunivdata: sortedunivdata_ready,
          sortedsenshudata: sortedsenshudata_ready,
          gakunen: gakunen_to_process, // 現在処理する学年を渡す
        );
        // --- 変更された選手データをHiveに保存し直す (重要！) ---
        // Ikusei_Com は sortedsenshudata の内容を変更するため、永続化が必要です。
        // sortedunivdata は変更されないと仮定します。
        for (final senshu in sortedsenshudata_ready) {
          await _senshuBox.put(senshu.id, senshu);
        }
      }
    }
    for (final entry in _senshuBox.toMap().entries) {
      //final int senshuId = entry.key;
      final SenshuData senshu = entry.value;
      if (senshu.gakunen == 2) {
        senshu.seichoutype = 1;
      }
      if (senshu.gakunen == 3) {
        senshu.seichoutype = 2;
      }
      if (senshu.gakunen == 4) {
        senshu.seichoutype = 3;
      }
      await _senshuBox.put(senshu.id, senshu);
    }

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    sortedUnivsById[8].name_tanshuku = ""; //監督の実績表示用
    await sortedUnivsById[8].save();
    //sortedUnivsById[9].name_tanshuku = "0"; //10000mを超える距離のタイム補正
    //await sortedUnivsById[9].save();
    sortedUnivsById[10].name_tanshuku = ""; //駅伝結果要約表示用
    await sortedUnivsById[10].save();

    print('モード101010処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // 処理が終わったらモードを15に更新し、UIを更新
    ghensuu.mode = 15;
    ghensuu.gamenflag = 0; // 最新画面を表示
    await _ghensuuBox.put(
      'global_ghensuu',
      ghensuu,
    ); // GhensuuのデータをHiveに保存してUIを更新
  }

  Future<void> _runMode1100Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード1100: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // Hive Boxのオープンを確認
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final univDataBox = Hive.box<UnivData>('univBox');
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');

    // Ghensuuデータは通常1つだけ存在すると仮定
    /*if (ghensuuBox.isEmpty) {
      print('Ghensuuデータがありません。処理をスキップします。');
      return;
    }*/

    final List<Ghensuu> gh = [ghensuu]; // gh[0]としてアクセスするためにリストに入れる

    // Swiftコードのソート処理をDartで実現
    // データのインデックスとIDが一致しない問題に対応するため、IDでソートしたリストを準備
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    final currentMonth = ghensuu.month;
    final currentDay = ghensuu.day;

    print('Current Date: $currentMonth/$currentDay');

    await Kyouka_com(gh: gh, sortedSenshuData: sortedSenshuData);

    if (skip.skipflag == 0) {
      ghensuu.mode = 1111;
    } else {
      ghensuu.mode = 5555;
    }

    print('モード1100処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await ghensuu.save(); // ghensuuオブジェクトの変更を保存
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode0120Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード0120: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // Hive Boxのオープンを確認
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final univDataBox = Hive.box<UnivData>('univBox');
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');

    // Ghensuuデータは通常1つだけ存在すると仮定
    /*if (ghensuuBox.isEmpty) {
      print('Ghensuuデータがありません。処理をスキップします。');
      return;
    }*/

    final List<Ghensuu> gh = [ghensuu]; // gh[0]としてアクセスするためにリストに入れる

    // Swiftコードのソート処理をDartで実現
    // データのインデックスとIDが一致しない問題に対応するため、IDでソートしたリストを準備
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    final currentMonth = ghensuu.month;
    final currentDay = ghensuu.day;

    print('Current Date: $currentMonth/$currentDay');

    // 日付に応じたEntryCalc関数の呼び出し
    if (currentMonth == 10 && currentDay == 5) {
      // 10月駅伝エントリー選手選考計算
      await Entry1Calc(
        racebangou: 0,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 15) {
      // 正月駅伝予選エントリー選手選考計算
      await Entry1Calc(
        racebangou: 4,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 11 && currentDay == 5) {
      // 11月駅伝エントリー選手選考計算
      await Entry1Calc(
        racebangou: 1,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 1 && currentDay == 5) {
      // 正月駅伝エントリー選手選考計算
      await Entry1Calc(
        racebangou: 2,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 2 && currentDay == 25) {
      // マイ駅伝エントリー選手選考計算
      await Entry1Calc(
        racebangou: 5,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    }
    // 各日付の処理の後、gh[0].mode を適切に設定します。
    if (gh[0].month == 10 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        // 10月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[0] == 1) {
          gh[0].mode = 150;
        } else {
          gh[0].mode = 200;
        }
      } else {
        gh[0].mode = 200;
      }
    } else if (gh[0].month == 10 && gh[0].day == 15) {
      if (skip.skipflag == 0) {
        // 11月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[4] == 1) {
          gh[0].mode = 150;
        } else {
          gh[0].mode = 200;
        }
      } else {
        gh[0].mode = 200;
      }
    } else if (gh[0].month == 11 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        // 11月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[1] == 1) {
          gh[0].mode = 150;
        } else {
          gh[0].mode = 200;
        }
      } else {
        gh[0].mode = 200;
      }
    } else if (gh[0].month == 1 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        // 正月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[2] == 1) {
          gh[0].mode = 150;
        } else {
          gh[0].mode = 200;
        }
      } else {
        gh[0].mode = 200;
      }
    } else if (gh[0].month == 2 && gh[0].day == 25) {
      if (skip.skipflag == 0) {
        gh[0].mode = 150; // マイ駅伝
      } else {
        gh[0].mode = 200;
      }
    }

    print('モード0120処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await gh[0].save(); // ghensuuオブジェクトの変更を保存
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode0200Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード0200: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // Hive Boxのオープンを確認
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final univDataBox = Hive.box<UnivData>('univBox');
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');

    // Ghensuuデータは通常1つだけ存在すると仮定
    /*if (ghensuuBox.isEmpty) {
      print('Ghensuuデータがありません。処理をスキップします。');
      return;
    }*/
    print('現在モード0200: ここは通過1...');
    final List<Ghensuu> gh = [ghensuu]; // gh[0]としてアクセスするためにリストに入れる
    print('現在モード0200: ここは通過2...');
    // Swiftコードのソート処理をDartで実現
    // データのインデックスとIDが一致しない問題に対応するため、IDでソートしたリストを準備
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
    print('現在モード0200: ここは通過3...');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    print('現在モード0200: ここは通過4...');
    final currentMonth = gh[0].month;
    final currentDay = gh[0].day;
    print('現在モード0200: ここは通過5...');
    print('Current Date: $currentMonth/$currentDay');

    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    // 日付に応じたEntryCalc関数の呼び出し
    if (currentMonth == 4 && currentDay == 25) {
      // 春の成長エントリー選手選考計算
    } else if (currentMonth == 5 && currentDay == 5) {
      // インカレ5000エントリー選手選考計算
      await EntryCalc(
        racebangou: 6,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 15) {
      // インカレ10000エントリー選手選考計算
      await EntryCalc(
        racebangou: 7,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 25) {
      // インカレハーフエントリー選手選考計算
      await EntryCalc(
        racebangou: 8,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 6 && currentDay == 15) {
      // 11月駅伝予選エントリー選手選考計算
      await EntryCalc(
        racebangou: 3,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 7 && currentDay == 15) {
      // 夏合宿エントリー選手選考計算
    } else if (currentMonth == 7 && currentDay == 25) {
      // クロカン1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 16,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 5) {
      // 登り1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 13,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 15) {
      // 下り1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 14,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 25) {
      // ロード1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 15,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 5) {
      // 市民ハーフエントリー選手選考計算
      await EntryCalc(
        racebangou: 12,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 15) {
      // トラック1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 11,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 25) {
      // トラック5千エントリー選手選考計算
      await EntryCalc(
        racebangou: 10,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 5) {
      // 10月駅伝エントリー選手選考計算
      await EntryCalc(
        racebangou: 0,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 15) {
      // 正月駅伝予選エントリー選手選考計算
      await EntryCalc(
        racebangou: 4,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 11 && currentDay == 5) {
      // 11月駅伝エントリー選手選考計算
      await EntryCalc(
        racebangou: 1,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 15) {
      // 市民ハーフエントリー選手選考計算
      await EntryCalc(
        racebangou: 12,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 25) {
      // トラック1万エントリー選手選考計算
      await EntryCalc(
        racebangou: 11,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 12 &&
        currentDay == 5) {
      // トラック5千エントリー選手選考計算
      await EntryCalc(
        racebangou: 10,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 1 && currentDay == 5) {
      // 正月駅伝エントリー選手選考計算
      await EntryCalc(
        racebangou: 2,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 2 && currentDay == 25) {
      // マイ駅伝エントリー選手選考計算
      await EntryCalc(
        racebangou: 5,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    } else if (currentMonth == 3 && currentDay == 15) {
      // フルマラソン選手選考計算
      await EntryCalc(
        racebangou: 17,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
    }
    // 各日付の処理の後、gh[0].mode を適切に設定します。
    if (gh[0].month == 4 && gh[0].day == 25) {
      gh[0].mode = 400; // 春の成長
    } else if (gh[0].month == 5 && gh[0].day == 5) {
      gh[0].mode = 400; // インカレ5000
    } else if (gh[0].month == 5 && gh[0].day == 15) {
      gh[0].mode = 400; // インカレ10000
    } else if (gh[0].month == 5 && gh[0].day == 25) {
      gh[0].mode = 400; // インカレハーフ
    } else if (gh[0].month == 6 && gh[0].day == 15) {
      if (skip.skipflag == 0) {
        // 11月駅伝予選
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[3] == 1) {
          gh[0].mode = 300;
        } else {
          gh[0].mode = 350;
        }
      } else {
        gh[0].mode = 400;
      }
    } else if (gh[0].month == 7 && gh[0].day == 15) {
      gh[0].mode = 400; // 夏合宿
    } else if (gh[0].month == 7 && gh[0].day == 25) {
      gh[0].mode = 400; // クロカン1万
    } else if (gh[0].month == 8 && gh[0].day == 5) {
      gh[0].mode = 400; // 登り1万
    } else if (gh[0].month == 8 && gh[0].day == 15) {
      gh[0].mode = 400; // 下り1万
    } else if (gh[0].month == 8 && gh[0].day == 25) {
      gh[0].mode = 400; // ロード1万
    } else if (kantoku.yobiint2[14] == 1 &&
        gh[0].month == 9 &&
        gh[0].day == 5) {
      gh[0].mode = 400; // 市民ハーフ
    } else if (kantoku.yobiint2[14] == 1 &&
        gh[0].month == 9 &&
        gh[0].day == 15) {
      gh[0].mode = 400; // トラック1万
    } else if (kantoku.yobiint2[14] == 1 &&
        gh[0].month == 9 &&
        gh[0].day == 25) {
      gh[0].mode = 400; // トラック5千
    } else if (gh[0].month == 10 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        // 10月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[0] == 1) {
          //gh[0].mode = 280;
          gh[0].mode = 300;
        } else {
          gh[0].mode = 350;
        }
      } else {
        gh[0].mode = 400;
      }
    } else if (gh[0].month == 10 && gh[0].day == 15) {
      if (skip.skipflag == 0) {
        // 正月駅伝予選
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[4] == 1) {
          gh[0].mode = 330;
        } else {
          gh[0].mode = 400;
        }
        //gh[0].mode = 350;
      } else {
        gh[0].mode = 400;
      }
    } else if (gh[0].month == 11 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        // 11月駅伝
        if (sortedUnivData[gh[0].MYunivid].taikaientryflag[1] == 1) {
          //gh[0].mode = 280;
          gh[0].mode = 300;
        } else {
          gh[0].mode = 350;
        }
      } else {
        gh[0].mode = 400;
      }
    } else if (kantoku.yobiint2[14] == 0 &&
        gh[0].month == 11 &&
        gh[0].day == 15) {
      gh[0].mode = 400; // 市民ハーフ
    } else if (kantoku.yobiint2[14] == 0 &&
        gh[0].month == 11 &&
        gh[0].day == 25) {
      gh[0].mode = 400; // トラック1万
    } else if (kantoku.yobiint2[14] == 0 &&
        gh[0].month == 12 &&
        gh[0].day == 5) {
      gh[0].mode = 400; // トラック5千
    } else if (gh[0].month == 1 && gh[0].day == 5) {
      if (skip.skipflag == 0) {
        gh[0].mode = 290;
        // 正月駅伝
        /*if (sortedUnivData[gh[0].MYunivid].taikaientryflag[2] == 1) {
          //gh[0].mode = 280;
          gh[0].mode = 300;
        } else {
          gh[0].mode = 350;
        }*/
      } else {
        gh[0].mode = 400;
      }
    } else if (gh[0].month == 2 && gh[0].day == 25) {
      if (skip.skipflag == 0) {
        //gh[0].mode = 280;
        gh[0].mode = 300; // マイ駅伝
      } else {
        gh[0].mode = 400;
      }
    } else if (gh[0].month == 3 && gh[0].day == 15) {
      gh[0].mode = 400; // フルマラソン
    }

    print('モード0200処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await gh[0].save(); // ghensuuオブジェクトの変更を保存
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode0400Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード0400: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // Hive Boxのオープンを確認
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final univDataBox = Hive.box<UnivData>('univBox');
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');

    // Ghensuuデータは通常1つだけ存在すると仮定
    /*if (ghensuuBox.isEmpty) {
      print('Ghensuuデータがありません。処理をスキップします。');
      return;
    }*/
    final List<Ghensuu> gh = [ghensuu]; // gh[0]としてアクセスするためにリストに入れる

    // Swiftコードのソート処理をDartで実現
    // データのインデックスとIDが一致しない問題に対応するため、IDでソートしたリストを準備
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    final currentMonth = gh[0].month;
    final currentDay = gh[0].day;

    print('Calculating results for date: $currentMonth/$currentDay');

    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    // 日付に応じた結果計算のロジック
    if (currentMonth == 4 && currentDay == 25) {
      // 春の成長結果計算
      for (int gakunen = 1; gakunen <= TEISUU.GAKUNENSUU; gakunen++) {
        await Ikusei_Com(
          gh: gh,
          sortedunivdata: sortedUnivData,
          sortedsenshudata: sortedSenshuData,
          gakunen: gakunen,
        );
      }
    } else if (currentMonth == 5 && currentDay == 5) {
      // インカレ5000結果計算
      await RaceCalc(
        racebangou: 6,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 15) {
      // インカレ10000結果計算
      await RaceCalc(
        racebangou: 7,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 25) {
      // インカレハーフ結果計算
      await RaceCalc(
        racebangou: 8,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 6 && currentDay == 15) {
      // 11月駅伝予選結果計算
      await RaceCalc(
        racebangou: 3,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 7 && currentDay == 15) {
      // 夏合宿結果計算
      for (int gakunen = 1; gakunen <= TEISUU.GAKUNENSUU; gakunen++) {
        await Ikusei_Com(
          gh: gh,
          sortedunivdata: sortedUnivData,
          sortedsenshudata: sortedSenshuData,
          gakunen: gakunen,
        );
      }
    } else if (currentMonth == 7 && currentDay == 25) {
      // クロカン1万結果計算
      await RaceCalc(
        racebangou: 16,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 5) {
      // 登り1万結果計算
      await RaceCalc(
        racebangou: 13,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 15) {
      // 下り1万結果計算
      await RaceCalc(
        racebangou: 14,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 25) {
      // ロード1万結果計算
      await RaceCalc(
        racebangou: 15,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 5) {
      // 市民ハーフ結果計算
      await RaceCalc(
        racebangou: 12,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 15) {
      // トラック1万結果計算
      await RaceCalc(
        racebangou: 11,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 25) {
      // トラック5千結果計算
      await RaceCalc(
        racebangou: 10,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 5) {
      // 10月駅伝結果計算
      await RaceCalc(
        racebangou: 0,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 15) {
      // 正月駅伝予選結果計算
      await RaceCalc(
        racebangou: 4,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 11 && currentDay == 5) {
      // 11月駅伝結果計算
      await RaceCalc(
        racebangou: 1,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 15) {
      // 市民ハーフ結果計算
      await RaceCalc(
        racebangou: 12,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 25) {
      // トラック1万結果計算
      await RaceCalc(
        racebangou: 11,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 12 &&
        currentDay == 5) {
      // トラック5千結果計算
      await RaceCalc(
        racebangou: 10,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 1 && currentDay == 5) {
      // 正月駅伝結果計算
      await RaceCalc(
        racebangou: 2,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 2 && currentDay == 25) {
      // マイ駅伝結果計算
      await RaceCalc(
        racebangou: 5,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 3 && currentDay == 15) {
      // フルマラソン結果計算
      await RaceCalc(
        racebangou: 17,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    }

    // gh[0] の変更はモード変更時に保存されるので、ここでは選手と大学データを保存
    // ただし、gh[0]もRaceCalc内で変更される可能性もあるので、明示的に保存対象に含めます。
    //await gh[0].save(); // ghも変更される可能性があるので保存

    // sortedSenshuData の各要素を保存
    // RaceCalc内で個々の選手データが変更されていると仮定し、全て保存を試みる
    for (var senshu in sortedSenshuData) {
      await senshu.save();
    }

    // sortedUnivData の各要素を保存
    // RaceCalc内で大学データが変更されていると仮定し、全て保存を試みる
    for (var univ in sortedUnivData) {
      await univ.save();
    }

    // Swiftコードの DispatchQueue.main.asyncAfter に相当するモード変更ロジック
    // ここでは遅延を入れずに直接モードを変更します。
    // 必要であれば Future.delayed を使って遅延を導入できますが、
    // UIの応答性のためには可能な限り非同期処理内で完結させる方が望ましいです。
    if (currentMonth == 4 && currentDay == 25) {
      // 春の成長
      gh[0].mode = 600;
    } else if (currentMonth == 5 && currentDay == 5) {
      // インカレ5000
      gh[0].mode = 600;
    } else if (currentMonth == 5 && currentDay == 15) {
      // インカレ10000
      gh[0].mode = 600;
    } else if (currentMonth == 5 && currentDay == 25) {
      // インカレハーフ
      gh[0].mode = 600;
    } else if (currentMonth == 6 && currentDay == 15) {
      // 11月駅伝予選
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[3]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          gh[0].mode = 350;
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (currentMonth == 7 && currentDay == 15) {
      // 夏合宿
      gh[0].mode = 600;
    } else if (currentMonth == 7 && currentDay == 25) {
      // クロカン1万
      gh[0].mode = 600;
    } else if (currentMonth == 8 && currentDay == 5) {
      // 登り1万
      gh[0].mode = 600;
    } else if (currentMonth == 8 && currentDay == 15) {
      // 下り1万
      gh[0].mode = 600;
    } else if (currentMonth == 8 && currentDay == 25) {
      // ロード1万
      gh[0].mode = 600;
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 5) {
      // 市民ハーフ
      gh[0].mode = 600;
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 15) {
      // トラック1万
      gh[0].mode = 600;
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 25) {
      // トラック5千
      gh[0].mode = 600;
    } else if (currentMonth == 10 && currentDay == 5) {
      // 10月駅伝
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[0]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          gh[0].mode = 350;
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (currentMonth == 10 && currentDay == 15) {
      // 正月駅伝予選
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[4]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          gh[0].mode = 350;
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (currentMonth == 11 && currentDay == 5) {
      // 11月駅伝
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[1]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          gh[0].mode = 350;
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 15) {
      // 市民ハーフ
      gh[0].mode = 600;
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 25) {
      // トラック1万
      gh[0].mode = 600;
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 12 &&
        currentDay == 5) {
      // トラック5千
      gh[0].mode = 600;
    } else if (currentMonth == 1 && currentDay == 5) {
      // 正月駅伝
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[2]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          if (gh[0].nowracecalckukan == 5 &&
              sortedUnivData[gh[0].MYunivid].taikaientryflag[gh[0]
                      .hyojiracebangou] ==
                  1) {
            //調子設定
            final Random random = Random();
            final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            final KantokuData kantoku = kantokuBox.get('KantokuData')!;
            final senshuDataBox = Hive.box<SenshuData>('senshuBox');
            List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
            sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
            for (var senshu in sortedSenshuData) {
              if (senshu.chousi < 100) {
                if (random.nextInt(100) < kantoku.yobiint2[4]) {
                  senshu.chousi = 100;
                  await senshu.save();
                }
              }
              if ((senshu.univid == gh[0].MYunivid ||
                      (kantoku.yobiint2[10] == 0 &&
                          kantoku.yobiint2[21] == 1)) &&
                  random.nextInt(100) < kantoku.yobiint2[5]) {
                //当日体調不良
                senshu.chousi = 0;
                await senshu.save();
              }
              if (kantoku.yobiint2[10] == 1 &&
                  senshu.univid != gh[0].MYunivid) {
                //
                senshu.chousi = 100;
                await senshu.save();
              }
            }

            gh[0].mode = 345;
          } else {
            gh[0].mode = 350;
          }
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (currentMonth == 2 && currentDay == 25) {
      // 正月駅伝
      if (gh[0].nowracecalckukan >= gh[0].kukansuu_taikaigoto[5]) {
        gh[0].mode = 600;
      } else {
        if (skip.skipflag == 0) {
          gh[0].mode = 350;
        } else {
          gh[0].mode = 400;
        }
      }
    } else if (currentMonth == 3 && currentDay == 15) {
      // フルマラソン
      gh[0].mode = 600;
    }
    // ※Swiftコードのコメントアウトされたnowracecalckukanの初期化は、
    // Dart側ではRaceCalcやEntryCalc内で適切に行われるべきです。
    // ここで直接変更せず、各計算ロジックに責任を持たせるのが良いでしょう。

    for (int i = 0; i < TEISUU.SENSHUSUU_UNIV; i++) {
      gh[0].SijiSelectedOption[i] = 0;
    }

    print('モード0400処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    // Ghensuuオブジェクトの変更を最後に保存
    await gh[0].save();
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode0600Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード0600: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // Hive Boxのオープンを確認
    //final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final univDataBox = Hive.box<UnivData>('univBox');
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');

    // Ghensuuデータは通常1つだけ存在すると仮定
    /*if (ghensuuBox.isEmpty) {
      print('Ghensuuデータがありません。処理をスキップします。');
      return;
    }*/
    final List<Ghensuu> gh = [ghensuu]; // gh[0]としてアクセスするためにリストに入れる

    // Swiftコードのソート処理をDartで実現
    // データのインデックスとIDが一致しない問題に対応するため、IDでソートしたリストを準備
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    final currentMonth = gh[0].month;
    final currentDay = gh[0].day;

    print('Updating records for date: $currentMonth/$currentDay');

    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    // 日付に応じたKirokuKousin関数の呼び出し
    if (currentMonth == 4 && currentDay == 25) {
      // 春の成長結果計算 (KirokuKousinの呼び出しなし)
      print('春の成長結果計算: KirokuKousinは呼び出されません。');
    } else if (currentMonth == 5 && currentDay == 5) {
      await kirokuKousin(
        racebangou: 6,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 15) {
      await kirokuKousin(
        racebangou: 7,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 5 && currentDay == 25) {
      await kirokuKousin(
        racebangou: 8,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 6 && currentDay == 15) {
      await kirokuKousin(
        racebangou: 3,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 7 && currentDay == 15) {
      // 夏合宿結果計算 (KirokuKousinの呼び出しなし)
      print('夏合宿結果計算: KirokuKousinは呼び出されません。');
    } else if (currentMonth == 7 && currentDay == 25) {
      await kirokuKousin(
        racebangou: 16,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 5) {
      await kirokuKousin(
        racebangou: 13,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 15) {
      await kirokuKousin(
        racebangou: 14,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 8 && currentDay == 25) {
      await kirokuKousin(
        racebangou: 15,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 5) {
      await kirokuKousin(
        racebangou: 12,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 15) {
      await kirokuKousin(
        racebangou: 11,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 1 &&
        currentMonth == 9 &&
        currentDay == 25) {
      await kirokuKousin(
        racebangou: 10,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 5) {
      await kirokuKousin(
        racebangou: 0,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 10 && currentDay == 15) {
      await kirokuKousin(
        racebangou: 4,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 11 && currentDay == 5) {
      await kirokuKousin(
        racebangou: 1,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 15) {
      await kirokuKousin(
        racebangou: 12,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 11 &&
        currentDay == 25) {
      await kirokuKousin(
        racebangou: 11,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (kantoku.yobiint2[14] == 0 &&
        currentMonth == 12 &&
        currentDay == 5) {
      await kirokuKousin(
        racebangou: 10,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 1 && currentDay == 5) {
      await kirokuKousin(
        racebangou: 2,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 2 && currentDay == 25) {
      await kirokuKousin(
        racebangou: 5,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    } else if (currentMonth == 3 && currentDay == 15) {
      await kirokuKousin(
        racebangou: 17,
        gh: gh,
        sortedunivdata: sortedUnivData,
        sortedsenshudata: sortedSenshuData,
      );
    }

    // Swiftの `try? modelContext.save()` に相当する処理は、
    // DartのHiveでは通常、各HiveObjectの `.save()` メソッドを呼び出すことで行います。
    // ここでは `gh[0]` のモード変更があるので、それだけを保存します。
    // KirokuKousin 内部で SenshuData や UnivData が変更された場合も、
    // それぞれのオブジェクトで `await .save();` を呼び出す必要があります。

    // モード変更ロジック
    if (skip.skipflag == 0) {
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      final KantokuData kantoku = kantokuBox.get('KantokuData')!;
      if (gh[0].last_goldenballkakutokusuu != 0 ||
          gh[0].last_silverballkakutokusuu != 0 ||
          kantoku.yobiint2[1] == 1) {
        kantoku.yobiint2[1] = 0;
        await kantoku.save();

        gh[0].mode = 8888;
        /*if (kantoku.yobiint2[0] == 0) {
          gh[0].mode = 8888;
        } else {
          bool allNouryokuFlagsAreOne = true;
          for (int i = 0; i < 10; i++) {
            // Swiftコードの gh[0].nouryokumieruflag[9] までに合わせる
            if (ghensuu.nouryokumieruflag[i] != 1) {
              allNouryokuFlagsAreOne = false;
              break;
            }
          }
          if (allNouryokuFlagsAreOne) {
            ghensuu.mode = 700;
          } else {
            ghensuu.mode = 8890;
          }
        }*/
      } else {
        if ((gh[0].goldenballsuu >= 10 || gh[0].silverballsuu >= 10) &&
            (currentMonth == 7 && currentDay == 15)) {
          gh[0].mode = 9080;
        } else {
          gh[0].mode = 700;
        }
      }
    } else {
      gh[0].mode = 5555;
    }

    print('モード0600処理完了。');

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    // gh[0] の変更を保存
    await gh[0].save();
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode2000Processing(Ghensuu ghensuu) async {
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード2000: 別の処理を実行中...');

    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // 1. SenshuData と UnivData を取得
    // HiveはMapライクなインターフェースを持つため、toList()でListに変換します。
    List<SenshuData> senshudata = _senshuBox.values.toList();
    List<UnivData> univdata = _univBox.values.toList();
    //final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    /*Ghensuu ghensuu = _ghensuuBox.getAt(
      0,
    )!*/
    ; // Ghensuuはシングルトン的に1つだけBoxに保存されていると仮定

    // 2. データのindexとidは一致していない問題なので、idでソートしたリストを作成
    // DartのList.sort()はin-placeでソートしますが、元のリストを変更しないためにtoList()でコピーを作成してからソートします。
    List<SenshuData> sortedSenshuData = senshudata.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    List<UnivData> sortedUnivData = univdata.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // 3. 入学時5000m順でソートしたリストを作成
    /*List<SenshuData> nyuugakuji5000SenshuData = senshudata.toList()
      ..sort(
        (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
      );*/

    // 4. RetireNew 関数を呼び出し
    // RetireNew関数が受け取る引数の型に合わせて変更
    await RetireNew(
      ghensuu: ghensuu,
      sortedUnivData: sortedUnivData,
      sortedSenshuData: sortedSenshuData,
      //nyuugakuji5000_senshudata: nyuugakuji5000SenshuData,
      //senshuBox: _senshuBox, // RetireNew内で選手データの保存が必要な場合
    );

    // 5. 念の為セーブ (RetireNew内でsaveChangesが呼び出される場合は不要な場合もありますが、
    // ここでは明示的に保存することを推奨)
    // HiveObjectの変更は、そのオブジェクトのsave()を呼び出すことで永続化されます。
    // ここではBox全体のsaveは通常行わず、変更されたHiveObjectに対してsave()を呼び出すのが一般的です。
    // RetireNewやgoldsilverTeikiKakutokuの中で各オブジェクトがsave()を呼ぶように設計してください。
    // もし、これらの関数がオブジェクトを更新するだけでsave()を呼ばない場合は、
    // ここで変更された各オブジェクトに対して save() を呼び出す必要があります。

    // 6. 金銀定期給付処理
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    if (kantoku.yobiint2[0] != 2) {
      await goldsilverTeikiKakutoku(ghensuu, sortedUnivData);
    }

    // 7. 念の為セーブ (goldsilverTeikiKakutoku内でsaveChangesが呼び出される場合も同様)
    // ここでも、goldsilverTeikiKakutoku内でghensuuオブジェクトがsave()を呼ぶように設計するのが一般的です。

    print('モード2000処理完了。');
    // 8. gh[0].mode=8888 の設定
    //ghensuu.mode = 8888;
    if (skip.skipflag == 0) {
      ghensuu.scoutChances = 3;
      ghensuu.mode = 9000;
    } else {
      ghensuu.mode = 5555;
    }

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await ghensuu.save(); // ghensuuオブジェクトの変更を保存
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }

  Future<void> _runMode5555Processing(Ghensuu ghensuu) async {
    print("_runMode5555Processing冒頭通過");
    if (_isMode10Processing) return; // 既に実行中なら何もしない
    _isMode10Processing = true; // 実行開始
    print('現在モード5555: 別の処理を実行中...');
    final Skip? skip = _skipBox.get('SkipData');
    if (skip!.skipflag == 0) {
      await Future.delayed(const Duration(milliseconds: 200)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }
    if (skip.skipflag == 3) {
      await Future.delayed(const Duration(milliseconds: 50)); // 処理のシミュレーション
      Chousa.lastGapTime = DateTime.now();
    }

    // もし今の状態を確認してから実行したい場合（必須ではありません）
    bool isWakelockEnabled = await WakelockPlus.enabled;
    if (skip.skipflag == 0) {
      // 通常モードなのに防止が有効なら解除する
      if (isWakelockEnabled) {
        await WakelockPlus.disable();
      }
    } else if (skip.skipflag == 3) {
      // スキップ中（統計収集）なのに防止が無効なら有効にする
      if (!isWakelockEnabled) {
        await WakelockPlus.enable();
      }
    }

    // ここでmode300で実行したい実際の処理を書く
    //await Future.delayed(const Duration(seconds: 1)); // 処理のシミュレーション
    //日付更新
    ghensuu.day += 10;
    if (ghensuu.day > 25) {
      ghensuu.day = 5;
      ghensuu.month += 1;
    }
    if (ghensuu.month > 12) {
      ghensuu.month = 1;
      ghensuu.year += 1;
    }

    //調子設定
    final Random random = Random();
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    final senshuDataBox = Hive.box<SenshuData>('senshuBox');
    List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
    sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
    if (ghensuu.month == 4 && ghensuu.day == 5) {
      for (var senshu in sortedSenshuData) {
        //まだ学年更新処理前なので新4年生は3年
        if (senshu.gakunen == 3) {
          if (senshu.anteikan < kantoku.yobiint2[7]) {
            senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[7];
            await senshu.save();
          }
        }
        //まだ学年更新処理前なので新3年生は2年
        if (senshu.gakunen == 2) {
          if (senshu.anteikan < kantoku.yobiint2[8]) {
            senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[8];
            await senshu.save();
          }
        }
        //まだ学年更新処理前なので新2年生は1年
        if (senshu.gakunen == 1) {
          if (senshu.anteikan < kantoku.yobiint2[9]) {
            senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[9];
            await senshu.save();
          }
        }
      }
    }
    for (var senshu in sortedSenshuData) {
      if (random.nextInt(100) < kantoku.yobiint2[3]) {
        senshu.chousi = 100;
      } else {
        int randmoto = 100 - senshu.anteikan;
        if (randmoto < 1) randmoto = 1;
        senshu.chousi = random.nextInt(randmoto) + senshu.anteikan;
      }
      //if (senshu.univid == ghensuu.MYunivid &&
      //  random.nextInt(100) < kantoku.yobiint2[6]) {
      if ((senshu.univid == ghensuu.MYunivid ||
              (kantoku.yobiint2[10] == 0 && kantoku.yobiint2[21] == 1)) &&
          random.nextInt(100) < kantoku.yobiint2[5]) {
        //区間エントリー時体調不良
        senshu.chousi = 0;
      }
      if (kantoku.yobiint2[10] == 1 && senshu.univid != ghensuu.MYunivid)
        senshu.chousi = 100;
      await senshu.save();
    }

    List<UnivData> sortedUnivsById = _univBox.toMap().values.toList();
    sortedUnivsById.sort((a, b) => a.id.compareTo(b.id));

    //チームの歩み文字数制限
    {
      // 最大文字数。この値を超えた場合、古い記録が削除されます。
      const int MAX_LENGTH = 50000;
      // 既存の文字列をチェックし、最大文字数を超えていたら古い記録を削除する関数
      String truncateOldRecords(String currentString, int maxLength) {
        // 1. 文字数が最大値を超えているかチェック
        if (currentString.length <= maxLength) {
          // 超えていない場合はそのまま返す
          return currentString;
        }
        // 2. 超えている場合、改行コード2つ(\n\n)を区切りとして古い記録(文字列の末尾)から削除
        // 文字列を「\n\n」で分割してリストにする
        List<String> records = currentString.split('\n\n');
        // 古い記録（リストの末尾）から順に削除していく
        String truncatedString = currentString;
        // currentStringは「新しい記録...古い記録」の順で格納されているため、リストの**末尾**が一番古い記録になります。
        while (truncatedString.length > maxLength && records.isNotEmpty) {
          // 一番古い記録（リストの末尾）を削除
          records.removeLast();
          // 残った記録を「\n\n」で再結合する
          truncatedString = records.join('\n\n');
        }
        // 記録を削除した結果、末尾の「\n\n」が失われている場合があるため、
        // 次の追加に備えて、記録が一つでも残っている場合は末尾に「\n\n」を補完します。
        // ただし、truncateOldRecordsの呼び出しは「追加後」であるため、末尾の「\n\n」の有無は
        // 次の追加処理に影響します。ここでは、記録が1つ以上残っている場合は、
        // `\n\n`で終わるようにしておきます。
        /*if (records.isNotEmpty && !truncatedString.endsWith('\n\n')) {
        return truncatedString + '\n\n';
      }*/
        // 記録がすべて削除された、または`\n\n`で終わっている場合
        return truncatedString;
      }

      String currentData = sortedUnivsById[8].name_tanshuku;
      // 文字列をチェックし、必要なら古い記録を削除
      String truncatedData = truncateOldRecords(currentData, MAX_LENGTH);
      sortedUnivsById[8].name_tanshuku = truncatedData;
      await sortedUnivsById[8].save();
    }

    if (skip!.skipflag >= 1) {
      await Future.delayed(const Duration(milliseconds: 200)); // skip処理中の発熱対策
      if (ghensuu.month == 4 && ghensuu.day == 15) {
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
        for (int i = 0; i < sortedSenshuData.length; i++) {
          var senshu = sortedSenshuData[i];
          int newbint = 1550;
          int b_int = (senshu.b * 10000.0).toInt();
          int a_int = (senshu.a * 1000000000.0).toInt();
          int a_min_int =
              (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER)
                  .toInt();
          int sa = a_int - a_min_int;
          int new_a_min_int =
              (newbint * newbint * 0.0333 -
                      newbint * 114.25 +
                      TEISUU.MAGICNUMBER)
                  .toInt();
          int aInt = new_a_min_int + sa;
          int kihonsouryoku_display = (aInt + 300);
          int sositu_display = (senshu.sositu - 1500);
          if (Chousa.a_max < kihonsouryoku_display) {
            Chousa.a_max = kihonsouryoku_display;
          }
          if (Chousa.a_min > kihonsouryoku_display) {
            Chousa.a_min = kihonsouryoku_display;
          }
          if (Chousa.sositu_max < sositu_display) {
            Chousa.sositu_max = sositu_display;
          }
          if (Chousa.sositu_min > sositu_display) {
            Chousa.sositu_min = sositu_display;
          }
        }
      }
      if (ghensuu.month == 3 && ghensuu.day == 25) {
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
        for (int i = 0; i < sortedSenshuData.length; i++) {
          var senshu = sortedSenshuData[i];
          int newbint = 1550;
          int b_int = (senshu.b * 10000.0).toInt();
          int a_int = (senshu.a * 1000000000.0).toInt();
          int a_min_int =
              (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER)
                  .toInt();
          int sa = a_int - a_min_int;
          int new_a_min_int =
              (newbint * newbint * 0.0333 -
                      newbint * 114.25 +
                      TEISUU.MAGICNUMBER)
                  .toInt();
          int aInt = new_a_min_int + sa;
          int kihonsouryoku_display = (aInt + 300);
          double a_chousa = kihonsouryoku_display / 1000000000.0;
          int sositu_display = (senshu.sositu - 1500);

          if (Chousa.a_max < kihonsouryoku_display) {
            Chousa.a_max = kihonsouryoku_display;
          }
          if (Chousa.a_min > kihonsouryoku_display) {
            Chousa.a_min = kihonsouryoku_display;
          }
          if (Chousa.sositu_max < sositu_display) {
            Chousa.sositu_max = sositu_display;
          }
          if (Chousa.sositu_min > sositu_display) {
            Chousa.sositu_min = sositu_display;
          }
          if (senshu.gakunen == 4) {
            if (Chousa.seichoukaisuu_max < senshu.seichoukaisuu) {
              Chousa.seichoukaisuu_max = senshu.seichoukaisuu;
            }
            if (Chousa.seichoukaisuu_min > senshu.seichoukaisuu) {
              Chousa.seichoukaisuu_min = senshu.seichoukaisuu;
            }
            Chousa.aTotal_sositugoto[sositu_display] += a_chousa;
            Chousa.count_sositugoto[sositu_display]++;
            if (sositu_display < 50) {
              Chousa.aTotal_sositugoto_0_49 += a_chousa;
              Chousa.count_sositugoto_0_49++;
            } else if (sositu_display < 100) {
              Chousa.aTotal_sositugoto_50_99 += a_chousa;
              Chousa.count_sositugoto_50_99++;
            } else if (sositu_display < 150) {
              Chousa.aTotal_sositugoto_100_149 += a_chousa;
              Chousa.count_sositugoto_100_149++;
            } else {
              Chousa.aTotal_sositugoto_150_180 += a_chousa;
              Chousa.count_sositugoto_150_180++;
            }
          }
          if (sortedSenshuData[i].gakunen == 4) {
            for (int i_kirokubangou = 0; i_kirokubangou < 4; i_kirokubangou++) {
              if (sortedSenshuData[i].hirou == 1) {
                skip.totaltime_ryuugakusei[i_kirokubangou] +=
                    sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                skip.count_ryuugakusei[i_kirokubangou]++;
                if (skip.besttime_ryuugakusei[i_kirokubangou] >
                    sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                  skip.besttime_ryuugakusei[i_kirokubangou] =
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                }
              } else {
                skip.totaltime_jap_all[i_kirokubangou] +=
                    sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                skip.count_jap_all[i_kirokubangou]++;
                if (skip.besttime_jap_all[i_kirokubangou] >
                    sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                  skip.besttime_jap_all[i_kirokubangou] =
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                }
                if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 840.0) {
                  skip.totaltime_jap_13pundai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_13pundai[i_kirokubangou]++;
                  if (skip.besttime_jap_13pundai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_13pundai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 850.0) {
                  skip.totaltime_jap_14pun00dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun00dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun00dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun00dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 860.0) {
                  skip.totaltime_jap_14pun10dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun10dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun10dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun10dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 870.0) {
                  skip.totaltime_jap_14pun20dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun20dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun20dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun20dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 880.0) {
                  skip.totaltime_jap_14pun30dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun30dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun30dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun30dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 890.0) {
                  skip.totaltime_jap_14pun40dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun40dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun40dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun40dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else if (sortedSenshuData[i].kiroku_nyuugakuji_5000 < 900.0) {
                  skip.totaltime_jap_14pun50dai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_14pun50dai[i_kirokubangou]++;
                  if (skip.besttime_jap_14pun50dai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_14pun50dai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                } else {
                  skip.totaltime_jap_15pundai[i_kirokubangou] +=
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  skip.count_jap_15pundai[i_kirokubangou]++;
                  if (skip.besttime_jap_15pundai[i_kirokubangou] >
                      sortedSenshuData[i].time_bestkiroku[i_kirokubangou]) {
                    skip.besttime_jap_15pundai[i_kirokubangou] =
                        sortedSenshuData[i].time_bestkiroku[i_kirokubangou];
                  }
                }
              }
            }
          }
        }
        if (skip.skipyear <= ghensuu.year &&
            skip.skipmonth <= ghensuu.month &&
            skip.skipday <= ghensuu.day) {
          print("⭐️⭐️統計⭐️⭐️");

          print("留学生${sortedUnivsById[0].r}流の場合");
          print("留学生総数 ${skip.count_ryuugakusei[0]}");
          if (skip.count_ryuugakusei[0] > 0) {
            print(
              "留学生5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_ryuugakusei[0] / skip.count_ryuugakusei[0])}",
            );
            print(
              "留学生10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_ryuugakusei[1] / skip.count_ryuugakusei[1])}",
            );
            print(
              "留学生ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_ryuugakusei[2] / skip.count_ryuugakusei[2])}",
            );
            print(
              "留学生フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_ryuugakusei[3] / skip.count_ryuugakusei[3])}",
            );
            print(
              "留学生5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_ryuugakusei[0])}",
            );
            print(
              "留学生10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_ryuugakusei[1])}",
            );
            print(
              "留学生ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_ryuugakusei[2])}",
            );
            print(
              "留学生フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_ryuugakusei[3])}",
            );
          }

          print("");
          print("日本人総数 ${skip.count_jap_all[0]}");
          sortedUnivsById[12].name_tanshuku += "==4年生卒業直前データ==\n";
          sortedUnivsById[12].name_tanshuku +=
              "日本人総数 ${skip.count_jap_all[0]}\n";
          if (skip.count_jap_all[0] > 0) {
            print(
              "日本人5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[0] / skip.count_jap_all[0])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[0] / skip.count_jap_all[0])}\n";
            print(
              "日本人10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[1] / skip.count_jap_all[1])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[1] / skip.count_jap_all[1])}\n";
            print(
              "日本人ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[2] / skip.count_jap_all[2])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_all[2] / skip.count_jap_all[2])}\n";
            print(
              "日本人フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_all[3] / skip.count_jap_all[3])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_all[3] / skip.count_jap_all[3])}\n";
            print(
              "日本人5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[0])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[0])}\n";
            print(
              "日本人10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[1])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[1])}\n";
            print(
              "日本人ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[2])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_all[2])}\n";
            print(
              "日本人フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_all[3])}",
            );
            sortedUnivsById[12].name_tanshuku +=
                "日本人フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_all[3])}\n";
          }

          print("");
          print("13分台入学サンプル数 ${skip.count_jap_13pundai[0]}");
          if (skip.count_jap_13pundai[0] > 0) {
            print(
              "13分台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_13pundai[0] / skip.count_jap_13pundai[0])}",
            );
            print(
              "13分台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_13pundai[1] / skip.count_jap_13pundai[1])}",
            );
            print(
              "13分台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_13pundai[2] / skip.count_jap_13pundai[2])}",
            );
            print(
              "13分台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_13pundai[3] / skip.count_jap_13pundai[3])}",
            );
            print(
              "13分台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_13pundai[0])}",
            );
            print(
              "13分台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_13pundai[1])}",
            );
            print(
              "13分台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_13pundai[2])}",
            );
            print(
              "13分台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_13pundai[3])}",
            );
          }

          print("");
          print("14分00秒台入学サンプル数 ${skip.count_jap_14pun00dai[0]}");
          if (skip.count_jap_14pun00dai[0] > 0) {
            print(
              "14分00秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun00dai[0] / skip.count_jap_14pun00dai[0])}",
            );
            print(
              "14分00秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun00dai[1] / skip.count_jap_14pun00dai[1])}",
            );
            print(
              "14分00秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun00dai[2] / skip.count_jap_14pun00dai[2])}",
            );
            print(
              "14分00秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun00dai[3] / skip.count_jap_14pun00dai[3])}",
            );
            print(
              "14分00秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun00dai[0])}",
            );
            print(
              "14分00秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun00dai[1])}",
            );
            print(
              "14分00秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun00dai[2])}",
            );
            print(
              "14分00秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun00dai[3])}",
            );
          }

          print("");
          print("14分10秒台入学サンプル数 ${skip.count_jap_14pun10dai[0]}");
          if (skip.count_jap_14pun10dai[0] > 0) {
            print(
              "14分10秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun10dai[0] / skip.count_jap_14pun10dai[0])}",
            );
            print(
              "14分10秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun10dai[1] / skip.count_jap_14pun10dai[1])}",
            );
            print(
              "14分10秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun10dai[2] / skip.count_jap_14pun10dai[2])}",
            );
            print(
              "14分10秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun10dai[3] / skip.count_jap_14pun10dai[3])}",
            );
            print(
              "14分10秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun10dai[0])}",
            );
            print(
              "14分10秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun10dai[1])}",
            );
            print(
              "14分10秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun10dai[2])}",
            );
            print(
              "14分10秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun10dai[3])}",
            );
          }

          print("");
          print("14分20秒台入学サンプル数 ${skip.count_jap_14pun20dai[0]}");
          if (skip.count_jap_14pun20dai[0] > 0) {
            print(
              "14分20秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun20dai[0] / skip.count_jap_14pun20dai[0])}",
            );
            print(
              "14分20秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun20dai[1] / skip.count_jap_14pun20dai[1])}",
            );
            print(
              "14分20秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun20dai[2] / skip.count_jap_14pun20dai[2])}",
            );
            print(
              "14分20秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun20dai[3] / skip.count_jap_14pun20dai[3])}",
            );
            print(
              "14分20秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun20dai[0])}",
            );
            print(
              "14分20秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun20dai[1])}",
            );
            print(
              "14分20秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun20dai[2])}",
            );
            print(
              "14分20秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun20dai[3])}",
            );
          }

          print("");
          print("14分30秒台入学サンプル数 ${skip.count_jap_14pun30dai[0]}");
          if (skip.count_jap_14pun30dai[0] > 0) {
            print(
              "14分30秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun30dai[0] / skip.count_jap_14pun30dai[0])}",
            );
            print(
              "14分30秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun30dai[1] / skip.count_jap_14pun30dai[1])}",
            );
            print(
              "14分30秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun30dai[2] / skip.count_jap_14pun30dai[2])}",
            );
            print(
              "14分30秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun30dai[3] / skip.count_jap_14pun30dai[3])}",
            );
            print(
              "14分30秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun30dai[0])}",
            );
            print(
              "14分30秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun30dai[1])}",
            );
            print(
              "14分30秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun30dai[2])}",
            );
            print(
              "14分30秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun30dai[3])}",
            );
          }

          print("");
          print("14分40秒台入学サンプル数 ${skip.count_jap_14pun40dai[0]}");
          if (skip.count_jap_14pun40dai[0] > 0) {
            print(
              "14分40秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun40dai[0] / skip.count_jap_14pun40dai[0])}",
            );
            print(
              "14分40秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun40dai[1] / skip.count_jap_14pun40dai[1])}",
            );
            print(
              "14分40秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun40dai[2] / skip.count_jap_14pun40dai[2])}",
            );
            print(
              "14分40秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun40dai[3] / skip.count_jap_14pun40dai[3])}",
            );
            print(
              "14分40秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun40dai[0])}",
            );
            print(
              "14分40秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun40dai[1])}",
            );
            print(
              "14分40秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun40dai[2])}",
            );
            print(
              "14分40秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun40dai[3])}",
            );
          }

          print("");
          print("14分50秒台入学サンプル数 ${skip.count_jap_14pun50dai[0]}");
          if (skip.count_jap_14pun50dai[0] > 0) {
            print(
              "14分50秒台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun50dai[0] / skip.count_jap_14pun50dai[0])}",
            );
            print(
              "14分50秒台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun50dai[1] / skip.count_jap_14pun50dai[1])}",
            );
            print(
              "14分50秒台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_14pun50dai[2] / skip.count_jap_14pun50dai[2])}",
            );
            print(
              "14分50秒台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_14pun50dai[3] / skip.count_jap_14pun50dai[3])}",
            );
            print(
              "14分50秒台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun50dai[0])}",
            );
            print(
              "14分50秒台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun50dai[1])}",
            );
            print(
              "14分50秒台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_14pun50dai[2])}",
            );
            print(
              "14分50秒台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_14pun50dai[3])}",
            );
          }

          print("");
          print("15分台入学サンプル数 ${skip.count_jap_15pundai[0]}");
          if (skip.count_jap_15pundai[0] > 0) {
            print(
              "15分台入学5000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_15pundai[0] / skip.count_jap_15pundai[0])}",
            );
            print(
              "15分台入学10000m平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_15pundai[1] / skip.count_jap_15pundai[1])}",
            );
            print(
              "15分台入学ハーフ平均 ${TimeDate.timeToFunByouString(skip.totaltime_jap_15pundai[2] / skip.count_jap_15pundai[2])}",
            );
            print(
              "15分台入学フル平均 ${TimeDate.timeToJikanFunByouString(skip.totaltime_jap_15pundai[3] / skip.count_jap_15pundai[3])}",
            );
            print(
              "15分台入学5000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_15pundai[0])}",
            );
            print(
              "15分台入学10000m最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_15pundai[1])}",
            );
            print(
              "15分台入学ハーフ最速 ${TimeDate.timeToFunByouString(skip.besttime_jap_15pundai[2])}",
            );
            print(
              "15分台入学フル最速 ${TimeDate.timeToJikanFunByouString(skip.besttime_jap_15pundai[3])}",
            );
          }

          //区間別統計データ
          final statsContainer = EkidenStatistics.instance;
          final toukeitest = statsContainer.stats[0][0];
          print("");
          print("");
          print("⭐️区間別タイム差統計⭐️");
          print("長距離タイム抑制補正あり、留学生は含まれません");
          print("試行回数 ${toukeitest.runCount}回");
          sortedUnivsById[12].name_tanshuku +=
              "\n\n\n==区間別タイム統計==\n試行回数 ${toukeitest.runCount}回\n";
          print("");
          for (int i_racebangou = 0; i_racebangou <= 5; i_racebangou++) {
            if (i_racebangou == 3 || i_racebangou == 4) {
              continue;
            }
            if (i_racebangou == 0) {
              print("10月駅伝");
              sortedUnivsById[12].name_tanshuku += "\n10月駅伝\n";
            }
            if (i_racebangou == 1) {
              print("11月駅伝");
              sortedUnivsById[12].name_tanshuku += "\n11月駅伝\n";
            }
            if (i_racebangou == 2) {
              print("正月駅伝");
              sortedUnivsById[12].name_tanshuku += "\n正月駅伝\n";
            }
            if (i_racebangou == 5) {
              print("カスタム駅伝");
              sortedUnivsById[12].name_tanshuku +=
                  "\n" + sortedUnivsById[0].name_tanshuku + "\n";
            }
            print("");
            for (
              int i_kukan = 0;
              i_kukan < ghensuu.kukansuu_taikaigoto[i_racebangou];
              i_kukan++
            ) {
              final toukei = statsContainer.stats[i_racebangou][i_kukan];
              print(
                "${i_kukan + 1}区平均平均タイム ${TimeDate.timeToFunByouString(toukei.averageAverageTime)}",
              );
              sortedUnivsById[12].name_tanshuku +=
                  "${i_kukan + 1}区平均タイム ${TimeDate.timeToFunByouString(toukei.averageAverageTime)}\n";
              print(
                "${i_kukan + 1}区平均最速タイム ${TimeDate.timeToFunByouString(toukei.averageFastestTime)}",
              );
              sortedUnivsById[12].name_tanshuku +=
                  "${i_kukan + 1}区平均最速タイム ${TimeDate.timeToFunByouString(toukei.averageFastestTime)}\n";
              print(
                "${i_kukan + 1}区平均ワーストタイム ${TimeDate.timeToFunByouString(toukei.averageWorstTime)}",
              );
              sortedUnivsById[12].name_tanshuku +=
                  "${i_kukan + 1}区平均ワーストタイム ${TimeDate.timeToFunByouString(toukei.averageWorstTime)}\n";
              print(
                // 小数点以下第一位までの表示に修正
                "${i_kukan + 1}区平均タイム差 ${(toukei.averageWorstTime - toukei.averageFastestTime).toStringAsFixed(1)}秒",
              );
              sortedUnivsById[12].name_tanshuku +=
                  "${i_kukan + 1}区平均タイム差 ${(toukei.averageWorstTime - toukei.averageFastestTime).toStringAsFixed(1)}秒\n";
              print(
                // 小数点以下第一位までの表示に修正
                "${i_kukan + 1}区平均タイム差/区間距離 ${((toukei.averageWorstTime - toukei.averageFastestTime) / ghensuu.kyori_taikai_kukangoto[i_racebangou][i_kukan] * 1000.0).toStringAsFixed(1)}s/km",
              );
              sortedUnivsById[12].name_tanshuku +=
                  "${i_kukan + 1}区平均タイム差/区間距離 ${((toukei.averageWorstTime - toukei.averageFastestTime) / ghensuu.kyori_taikai_kukangoto[i_racebangou][i_kukan] * 1000.0).toStringAsFixed(1)}s/km\n";
              print("");
            }
          }
          await sortedUnivsById[12].save();
          print("");
          print("最大seichoukaisuu_max= ${Chousa.seichoukaisuu_max}");
          print("最小seichoukaisuu_min= ${Chousa.seichoukaisuu_min}");
          print("最大aint= ${Chousa.a_max}");
          print("最小aint= ${Chousa.a_min}");
          print("最大sositu= ${Chousa.sositu_max}");
          print("最小sositu= ${Chousa.sositu_min}");
          for (int i = 0; i < 181; i++) {
            if (Chousa.count_sositugoto[i] > 0) {
              print(
                "素質=${i} count=${Chousa.count_sositugoto[i]} 平均基本走力=${((Chousa.aTotal_sositugoto[i] / Chousa.count_sositugoto[i]) * 1000000000).toInt()}",
              );
            }
          }
          if (Chousa.count_sositugoto_0_49 > 0) {
            print(
              "素質=0_49 count=${Chousa.count_sositugoto_0_49} 平均基本走力=${((Chousa.aTotal_sositugoto_0_49 / Chousa.count_sositugoto_0_49) * 1000000000).toInt()}",
            );
          }
          if (Chousa.count_sositugoto_50_99 > 0) {
            print(
              "素質=50_99 count=${Chousa.count_sositugoto_50_99} 平均基本走力=${((Chousa.aTotal_sositugoto_50_99 / Chousa.count_sositugoto_50_99) * 1000000000).toInt()}",
            );
          }
          if (Chousa.count_sositugoto_100_149 > 0) {
            print(
              "素質=100_149 count=${Chousa.count_sositugoto_100_149} 平均基本走力=${((Chousa.aTotal_sositugoto_100_149 / Chousa.count_sositugoto_100_149) * 1000000000).toInt()}",
            );
          }
          if (Chousa.count_sositugoto_150_180 > 0) {
            print(
              "素質=150_180 count=${Chousa.count_sositugoto_150_180} 平均基本走力=${((Chousa.aTotal_sositugoto_150_180 / Chousa.count_sositugoto_150_180) * 1000000000).toInt()}",
            );
          }
          skip.skipflag = 0;
          await skip.save();
          // スリープ禁止を解除する
          await WakelockPlus.disable();
        }
      }
    }

    if (ghensuu.month == 4 && ghensuu.day == 5) {
      // シード権をもとにエントリーフラグ更新
      // (KirokuKousinルーチンでエントリーフラグを更新してしまうと直後のz0700結果表示でうまくいかないため年度最初にした)

      // 11月駅伝
      for (int i_univ = 0; i_univ < sortedUnivsById.length; i_univ++) {
        // 'juni_race[1][0]'が特定のレースと年度の順位に対応すると仮定します。
        // あなたのDart/Hive構造に合わせて正確なインデックスを確認する必要があるかもしれません。
        if (sortedUnivsById[i_univ].juni_race[1][0] < 8) {
          sortedUnivsById[i_univ].taikaientryflag[1] = 1;
          sortedUnivsById[i_univ].taikaientryflag[3] = 0;
        } else {
          sortedUnivsById[i_univ].taikaientryflag[1] = 0;
          sortedUnivsById[i_univ].taikaientryflag[3] = 1;
        }
        // 各UnivDataオブジェクトを変更後に保存
        await sortedUnivsById[i_univ].save();
      }

      // 正月駅伝
      for (int i_univ = 0; i_univ < sortedUnivsById.length; i_univ++) {
        if (sortedUnivsById[i_univ].juni_race[2][0] < 10) {
          sortedUnivsById[i_univ].taikaientryflag[2] = 1;
          sortedUnivsById[i_univ].taikaientryflag[0] = 1;
          sortedUnivsById[i_univ].taikaientryflag[4] = 0;
        } else {
          sortedUnivsById[i_univ].taikaientryflag[2] = 0;
          sortedUnivsById[i_univ].taikaientryflag[0] = 0;
          sortedUnivsById[i_univ].taikaientryflag[4] = 1;
        }
        // 各UnivDataオブジェクトを変更後に保存
        await sortedUnivsById[i_univ].save();
      }
      ghensuu.mode = 2000; // モードを2000に移行
    } else if (ghensuu.month == 4 && ghensuu.day == 15) {
      //強化練習決定
      //if (skip.skipflag == 0) {
      ghensuu.mode = 1100;
      //} else {
      //  ghensuu.mode = 100;
      //}
    } else if (ghensuu.month == 4 && ghensuu.day == 25) {
      // 春の成長
      ghensuu.mode = 200;
    } else if (ghensuu.month == 5 && ghensuu.day == 5) {
      // インカレ5000
      ghensuu.hyojiracebangou = 6;
      ghensuu.mode = 200;
    } else if (ghensuu.month == 5 && ghensuu.day == 15) {
      // インカレ10000
      ghensuu.hyojiracebangou = 7;
      ghensuu.mode = 200;
    } else if (ghensuu.month == 5 && ghensuu.day == 25) {
      // インカレハーフ
      ghensuu.hyojiracebangou = 8;
      ghensuu.mode = 200;
    } else if (ghensuu.month == 6 && ghensuu.day == 5) {
      // 目標順位設定処理
      for (var iUniv = 0; iUniv < sortedUnivsById.length; iUniv++) {
        if (ghensuu.spurtryokuseichousisuu2 == 93) {
          //デフォルト設定
          //11月駅伝目標順位
          if (sortedUnivsById[iUniv].juni_race[1][0] < 8) {
            sortedUnivsById[iUniv].mokuhyojuni[1] =
                sortedUnivsById[iUniv].juni_race[1][0] -
                (Random().nextInt(3) + 2); // 2...4
            if (sortedUnivsById[iUniv].mokuhyojuni[1] < 0) {
              sortedUnivsById[iUniv].mokuhyojuni[1] = 0;
            }
          } else {
            sortedUnivsById[iUniv].mokuhyojuni[3] = 6;
            sortedUnivsById[iUniv].mokuhyojuni[1] = 7;
          }
          //正月駅伝・10月駅伝目標順位
          if (sortedUnivsById[iUniv].juni_race[2][0] < 10) {
            sortedUnivsById[iUniv].mokuhyojuni[2] =
                sortedUnivsById[iUniv].juni_race[2][0] -
                (Random().nextInt(3) + 2); // 2...4
            if (sortedUnivsById[iUniv].mokuhyojuni[2] < 0) {
              sortedUnivsById[iUniv].mokuhyojuni[2] = 0;
            }
            if (sortedUnivsById[iUniv].juni_race[0][0] <= 9) {
              //出場してるなら
              sortedUnivsById[iUniv].mokuhyojuni[0] =
                  sortedUnivsById[iUniv].juni_race[0][0] -
                  (Random().nextInt(3) + 2); // 2...4
              if (sortedUnivsById[iUniv].mokuhyojuni[0] < 0) {
                sortedUnivsById[iUniv].mokuhyojuni[0] = 0;
              }
              if (sortedUnivsById[iUniv].mokuhyojuni[0] > 4) {
                sortedUnivsById[iUniv].mokuhyojuni[0] = 4;
              }
            } else {
              sortedUnivsById[iUniv].mokuhyojuni[0] = 4;
            }
          } else {
            sortedUnivsById[iUniv].mokuhyojuni[4] = 9;
            sortedUnivsById[iUniv].mokuhyojuni[2] = 9;
          }
          sortedUnivsById[iUniv].mokuhyojuni[5] = 9;
        }
        if (ghensuu.spurtryokuseichousisuu2 == 1) {
          //対校戦基準設定
          sortedUnivsById[iUniv].mokuhyojuni[0] =
              sortedUnivsById[iUniv].juni_race[9][0];
          if (sortedUnivsById[iUniv].mokuhyojuni[0] > 8) {
            sortedUnivsById[iUniv].mokuhyojuni[0] = 8;
          }
          sortedUnivsById[iUniv].mokuhyojuni[1] =
              sortedUnivsById[iUniv].juni_race[9][0];
          if (sortedUnivsById[iUniv].mokuhyojuni[1] > 13) {
            sortedUnivsById[iUniv].mokuhyojuni[1] = 13;
          }
          sortedUnivsById[iUniv].mokuhyojuni[2] =
              sortedUnivsById[iUniv].juni_race[9][0];
          if (sortedUnivsById[iUniv].mokuhyojuni[2] > 18) {
            sortedUnivsById[iUniv].mokuhyojuni[2] = 18;
          }
          sortedUnivsById[iUniv].mokuhyojuni[3] = 6;
          sortedUnivsById[iUniv].mokuhyojuni[4] = 9;
          sortedUnivsById[iUniv].mokuhyojuni[5] =
              sortedUnivsById[iUniv].juni_race[9][0];
          if (sortedUnivsById[iUniv].mokuhyojuni[5] > 28) {
            sortedUnivsById[iUniv].mokuhyojuni[5] = 28;
          }
        }
        if (ghensuu.spurtryokuseichousisuu2 == 2) {
          //常にシード権設定
          sortedUnivsById[iUniv].mokuhyojuni[0] = 4;
          sortedUnivsById[iUniv].mokuhyojuni[1] = 7;
          sortedUnivsById[iUniv].mokuhyojuni[2] = 9;
          sortedUnivsById[iUniv].mokuhyojuni[3] = 6;
          sortedUnivsById[iUniv].mokuhyojuni[4] = 9;
          sortedUnivsById[iUniv].mokuhyojuni[5] = 9;
        }
        /*if (ghensuu.spurtryokuseichousisuu2 == 3) {
          //目標順位無効化設定
          sortedUnivsById[iUniv].mokuhyojuni[0] = 8;
          sortedUnivsById[iUniv].mokuhyojuni[1] = 13;
          sortedUnivsById[iUniv].mokuhyojuni[2] = 18;
          sortedUnivsById[iUniv].mokuhyojuni[3] = 6;
          sortedUnivsById[iUniv].mokuhyojuni[4] = 9;
          sortedUnivsById[iUniv].mokuhyojuni[5] = 28;
        }*/
        await sortedUnivsById[iUniv].save(); // UnivData の変更を保存
      }
    } else if (ghensuu.month == 6 && ghensuu.day == 15) {
      if (skip.skipflag != 1) {
        // 11月駅伝予選
        ghensuu.hyojiracebangou = 3;
        ghensuu.mode = 200;
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 7 && ghensuu.day == 15) {
      // 夏合宿
      ghensuu.mode = 200;
    } else if (ghensuu.month == 7 && ghensuu.day == 25) {
      if (skip.skipflag != 1) {
        // クロカン1万
        ghensuu.hyojiracebangou = 16;
        ghensuu.mode = 200;
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 8 && ghensuu.day == 5) {
      if (skip.skipflag != 1) {
        // 登り1万
        ghensuu.hyojiracebangou = 13;
        ghensuu.mode = 200;
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 8 && ghensuu.day == 15) {
      if (skip.skipflag != 1) {
        // 下り1万
        ghensuu.hyojiracebangou = 14;
        ghensuu.mode = 200;
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 8 && ghensuu.day == 25) {
      if (skip.skipflag != 1) {
        // ロード1万
        ghensuu.hyojiracebangou = 15;
        ghensuu.mode = 200;
      } else {
        ghensuu.mode = 5555;
      }
    } else if (kantoku.yobiint2[14] == 1 &&
        ghensuu.month == 9 &&
        ghensuu.day == 5) {
      // 市民ハーフ
      ghensuu.hyojiracebangou = 12;
      ghensuu.mode = 200;
    } else if (kantoku.yobiint2[14] == 1 &&
        ghensuu.month == 9 &&
        ghensuu.day == 15) {
      // トラック1万
      ghensuu.hyojiracebangou = 11;
      ghensuu.mode = 200;
    } else if (kantoku.yobiint2[14] == 1 &&
        ghensuu.month == 9 &&
        ghensuu.day == 25) {
      // トラック5千
      ghensuu.hyojiracebangou = 10;
      ghensuu.mode = 200;
    } else if (ghensuu.month == 10 && ghensuu.day == 5) {
      if (skip.skipflag != 1) {
        // 10月駅伝
        ghensuu.hyojiracebangou = 0;
        if (skip.skipflag == 0) {
          ghensuu.mode = 110;
        } else {
          ghensuu.mode = 120;
        }
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 10 && ghensuu.day == 15) {
      if (skip.skipflag != 1) {
        // 正月駅伝予選
        ghensuu.hyojiracebangou = 4;
        if (skip.skipflag == 0) {
          ghensuu.mode = 110;
        } else {
          ghensuu.mode = 120;
        }
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 11 && ghensuu.day == 5) {
      if (skip.skipflag != 1) {
        // 11月駅伝
        ghensuu.hyojiracebangou = 1;
        if (skip.skipflag == 0) {
          ghensuu.mode = 110;
        } else {
          ghensuu.mode = 120;
        }
      } else {
        ghensuu.mode = 5555;
      }
    } else if (kantoku.yobiint2[14] == 0 &&
        ghensuu.month == 11 &&
        ghensuu.day == 15) {
      // 市民ハーフ
      ghensuu.hyojiracebangou = 12;
      ghensuu.mode = 200;
    } else if (kantoku.yobiint2[14] == 0 &&
        ghensuu.month == 11 &&
        ghensuu.day == 25) {
      // トラック1万
      ghensuu.hyojiracebangou = 11;
      ghensuu.mode = 200;
    } else if (kantoku.yobiint2[14] == 0 &&
        ghensuu.month == 12 &&
        ghensuu.day == 5) {
      // トラック5千
      ghensuu.hyojiracebangou = 10;
      ghensuu.mode = 200;
    } else if (ghensuu.month == 1 && ghensuu.day == 5) {
      if (skip.skipflag != 1) {
        // 正月駅伝
        ghensuu.hyojiracebangou = 2;
        if (skip.skipflag == 0) {
          ghensuu.mode = 110;
        } else {
          ghensuu.mode = 120;
        }
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 2 && ghensuu.day == 25) {
      if (skip.skipflag != 1) {
        // カスタム駅伝
        ghensuu.hyojiracebangou = 5;
        if (ghensuu.spurtryokuseichousisuu1 == 1) {
          if (skip.skipflag == 0) {
            ghensuu.mode = 110;
          } else {
            ghensuu.mode = 120;
          }
        } else {
          ghensuu.mode = 100;
        }
      } else {
        ghensuu.mode = 5555;
      }
    } else if (ghensuu.month == 3 && ghensuu.day == 15) {
      // フルマラソン
      ghensuu.hyojiracebangou = 17;
      ghensuu.mode = 200;
    }
    // マイ駅伝のコメントアウトされた部分はそのまま無視します。
    // else if (ghensuu.month == 2 && ghensuu.day == 25) {
    //   // マイ駅伝
    //   ghensuu.mode = 200;
    // }
    else {
      if (skip.skipflag == 0) {
        ghensuu.mode = 100; // どの条件にも合致しない場合はモード100
      } else {
        ghensuu.mode = 5555;
      }
    }
    print('モード5555処理完了。');

    for (final univ in sortedUnivsById) {
      await _univBox.put(univ.id, univ);
    }

    // ★★★ フラグをリセット START ★★★
    _isMode10Processing = false; // 処理完了
    // ★★★ フラグをリセット END ★★★

    // ghensuu.gamenflagはそのままか、必要に応じて変更
    await ghensuu.save();
    //await _ghensuuBox.put('global_ghensuu', ghensuu);
  }
  // ★★★ ADD/MODIFY/DELETE END ★★★

  @override
  Widget build(BuildContext context) {
    //final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, box, _) {
        final Ghensuu currentGhensuu = box.get(
          'global_ghensuu',
          defaultValue: Ghensuu.initial(),
        )!;

        // 共通テーマを適用
        final ThemeData appTheme = buildAppTheme(); // ★共通テーマを取得★

        // ★★★ ADD/MODIFY/DELETE START ★★★
        // --- ゲーム進行管理ロジックの開始 ---
        // gamenflagの更新とは独立してmodeをチェックし、処理を実行します。
        // 同じフレーム内でsetStateを複数回呼び出すのを避けるため、
        // addPostFrameCallbackを使って次のフレームでモード更新をトリガーします。
        // これにより、UIの再構築を適切に行えます。
        // --- ゲーム進行管理ロジック ---
        if (currentGhensuu.mode == 9) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: updatefailedOKButtonScreen()),
          );
        } else if (currentGhensuu.mode == 10 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode0010Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme, // ★テーマを適用★
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'お待ちください',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '初期データを処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 9005 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode9005Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme, // ★テーマを適用★
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'お待ちください',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '全選手の各タイムの学内順位を計算中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 101010 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode101010Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme, // ★テーマを適用★
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'お待ちください',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '名声と育成力を維持しつつ初期データを処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 15) {
          // mode 15 で難易度選択画面を表示
          return MaterialApp(
            theme: appTheme, // ★テーマを適用★
            home: Scaffold(body: NanidoSelectionScreen()),
          );
        } else if (currentGhensuu.mode == 20) {
          // mode 20 で大学選択画面を表示
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: UnivSelectionScreen()),
          );
        } else if (currentGhensuu.mode == 25) {
          // mode 25 で大学選択確認画面を表示
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: UnivSelectionConfirmationScreen()),
          );
        } else if (currentGhensuu.mode == 27) {
          // mode 25 で大学選択確認画面を表示
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: UnivNameChangeConfirmationScreen()),
          );
        } else if (currentGhensuu.mode == 30) {
          // mode 25 で大学選択確認画面を表示
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: FirstUnivNameInputScreen()),
          );
        } else if (currentGhensuu.mode == 35) {
          // mode 25 で大学選択確認画面を表示
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: FirstUnivNameConfirmationScreen()),
          );
        } else if (currentGhensuu.mode == 1100 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode1100Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'COMチーム強化練習設定中…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 120 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode0120Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1次エントリー選手選考中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 200 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode0200Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エントリー選手選考処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 400 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode0400Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'レースの計算処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 600 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode0600Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'レース結果から記録更新処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 2000 && !_isMode10Processing) {
          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode2000Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '4年生卒業・新入生入学処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 5555 && !_isMode10Processing) {
          print(
            "else if (currentGhensuu.mode == 5555 && !_isMode10Processing) {に入りました",
          );

          // フラグを追加
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _runMode5555Processing(currentGhensuu);
          });
          return MaterialApp(
            theme: appTheme,
            // const を削除して、動的なプロパティを設定できるようにする
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                  'お待ちください(${currentGhensuu.year}年${currentGhensuu.month}月)',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: true, // タイトルを中央に配置
              ),
              //backgroundColor: HENSUU.backgroundcolor, // 背景全体を黒 (または指定された背景色) に
              body: SafeArea(
                // ★ここにSafeAreaを追加します★
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HENSUU.buttonColor,
                        ), // 渦巻きを緑 (または指定されたボタン色) に
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '日付更新処理中です…',
                        style: TextStyle(
                          color: HENSUU.textcolor, // テキストを白 (または指定されたテキスト色) に
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (currentGhensuu.mode == 8888) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: GoldenAcquisitionView()),
          );
        } else if (currentGhensuu.mode == 8890) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: AbilityVisibilityView()),
          );
        } else if (currentGhensuu.mode == 99) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: FirstScreen()),
          );
        } else if (currentGhensuu.mode == 9000) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: FreshmanScoutView()),
          );
        } else if (currentGhensuu.mode == 9003) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: FreshmanTradeScreen()),
          );
        } else if (currentGhensuu.mode == 9080) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: OKButtonScreen()),
          );
        } else if (currentGhensuu.mode == 9100) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: GashukuScreen()),
          );
        } else if (currentGhensuu.mode == 340 &&
            currentGhensuu.hyojiracebangou != 2) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: ToujitsuHenkouScreen()),
          );
        } else if (currentGhensuu.mode == 340 &&
            currentGhensuu.hyojiracebangou == 2) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: ToujitsuAHenkouScreen()),
          );
        } else if (currentGhensuu.mode == 345) {
          return MaterialApp(
            theme: appTheme,
            home: Scaffold(body: ToujitsuBHenkouScreen()),
          );
        } else {}
        Widget currentScreen;
        int selectedIndex = currentGhensuu.gamenflag;

        switch (currentGhensuu.gamenflag) {
          case 0:
            // ★★★ 変更箇所 START ★★★
            // onAdvanceMode に常に有効なコールバック関数を直接渡す
            currentScreen = LatestScreen(
              ghensuu: currentGhensuu,
              onAdvanceMode: () async {
                // ボタンが押されたときに実行したい処理をここに記述
                // 例: mode を次のステップに進める (仮に +1)
                //currentGhensuu.mode = currentGhensuu.mode + 1;
                if (currentGhensuu.mode == 100) {
                  currentGhensuu.mode = 5555;
                } else if (currentGhensuu.mode == 150) {
                  currentGhensuu.mode = 200;
                } else if (currentGhensuu.mode == 280) {
                  currentGhensuu.mode = 300;
                } else if (currentGhensuu.mode == 290) {
                  final univDataBox = Hive.box<UnivData>('univBox');
                  List<UnivData> sortedUnivData = univDataBox.values.toList();
                  sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
                  if (sortedUnivData[currentGhensuu.MYunivid]
                          .taikaientryflag[2] ==
                      1) {
                    //gh[0].mode = 280;
                    currentGhensuu.mode = 300;
                  } else {
                    currentGhensuu.mode = 350;
                  }
                } else if (currentGhensuu.mode == 343) {
                  currentGhensuu.mode = 350;
                } else if (currentGhensuu.mode == 1111) {
                  currentGhensuu.mode = 5555;
                } else if (currentGhensuu.mode == 110) {
                  /*final univDataBox = Hive.box<UnivData>('univBox');
                  List<UnivData> sortedUnivData = univDataBox.values.toList();
                  sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
                  if (sortedUnivData[currentGhensuu.MYunivid]
                          .taikaientryflag[currentGhensuu.hyojiracebangou] ==
                      1) {
                    currentGhensuu.mode = 330;
                  } else {
                    currentGhensuu.mode = 400;
                  }*/
                  currentGhensuu.mode = 120;
                } else if (currentGhensuu.mode == 300) {
                  currentGhensuu.mode = 330;
                } else if (currentGhensuu.mode == 330) {
                  if (currentGhensuu.hyojiracebangou == 4) {
                    final univDataBox = Hive.box<UnivData>('univBox');
                    List<UnivData> sortedUnivData = univDataBox.values.toList();
                    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
                    if (sortedUnivData[currentGhensuu.MYunivid]
                            .taikaientryflag[currentGhensuu.hyojiracebangou] ==
                        1) {
                      currentGhensuu.mode = 350;
                    } else {
                      currentGhensuu.mode = 400;
                    }
                  } else {
                    if (currentGhensuu.hyojiracebangou <= 2 ||
                        currentGhensuu.hyojiracebangou == 5) {
                      //調子設定
                      final Random random = Random();
                      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
                      final KantokuData kantoku = kantokuBox.get(
                        'KantokuData',
                      )!;
                      final senshuDataBox = Hive.box<SenshuData>('senshuBox');
                      List<SenshuData> sortedSenshuData = senshuDataBox.values
                          .toList();
                      sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
                      for (var senshu in sortedSenshuData) {
                        if (senshu.chousi < 100) {
                          if (random.nextInt(100) < kantoku.yobiint2[4]) {
                            senshu.chousi = 100;
                            await senshu.save();
                          }
                        }
                        //if (senshu.univid == currentGhensuu.MYunivid &&
                        //    random.nextInt(100) < kantoku.yobiint2[5]) {
                        if ((senshu.univid == currentGhensuu.MYunivid ||
                                (kantoku.yobiint2[10] == 0 &&
                                    kantoku.yobiint2[21] == 1)) &&
                            random.nextInt(100) < kantoku.yobiint2[5]) {
                          //当日体調不良
                          senshu.chousi = 0;
                          await senshu.save();
                        }
                        if (kantoku.yobiint2[10] == 1 &&
                            senshu.univid != currentGhensuu.MYunivid) {
                          //
                          senshu.chousi = 100;
                          await senshu.save();
                        }
                      }
                      currentGhensuu.mode = 340; //当日変更画面へ
                    } else {
                      currentGhensuu.mode = 350;
                    }
                  }
                } else if (currentGhensuu.mode == 350) {
                  currentGhensuu.mode = 400;
                } else if (currentGhensuu.mode == 700) {
                  currentGhensuu.mode = 5555;
                }
                print('「進む」ボタンが押されました。現在のモード: ${currentGhensuu.mode}');
                await currentGhensuu.save();

                // 必要であれば、mode の値に応じて別の処理をここに分岐させてもOK
                // if (currentGhensuu.mode == 300) { /* 特定の処理 */ }
              },
            );
            // ★★★ 変更箇所 END ★★★
            break;
          case 1:
            currentScreen = const SenshuScreen();
            break;
          case 2: // gamenflag: 2 → 大学画面
            currentScreen = const UnivScreen(); // ★StatelessからStatefulへの変更を反映
            break;
          case 3:
            currentScreen = const RecordScreen();
            break;
          case 4:
            currentScreen = const SettingScreen();
            break;
          default:
            currentScreen = UnknownScreen(
              message: '不明なgamenflag: ${currentGhensuu.gamenflag}',
            );
            break;
        }

        return MaterialApp(
          title: '箱庭小駅伝SS',
          theme: appTheme,
          home: Scaffold(
            backgroundColor: HENSUU.backgroundcolor, // 画面全体を黒にする
            /*appBar: AppBar(
              // ★AppBarのタイトルを動的に変更: 現在の画面と大学番号を表示
              title: Text(
                selectedIndex ==
                        2 // 大学画面の場合のみ大学番号を表示
                    ? '箱庭小駅伝S'
                    : '箱庭小駅伝S',
              ),
            ),*/
            /*body: SafeArea(
              // ★ここにSafeAreaを追加します★→これやると画面最上部の時刻とかが消えちゃう
              child: currentScreen,
            ),*/
            body: currentScreen,
            bottomNavigationBar:
                (currentGhensuu.mode == 100 ||
                    currentGhensuu.mode == 150 ||
                    currentGhensuu.mode == 280 ||
                    currentGhensuu.mode == 290 ||
                    currentGhensuu.mode == 343 ||
                    currentGhensuu.mode == 1111 ||
                    currentGhensuu.mode == 110 ||
                    currentGhensuu.mode == 300 ||
                    currentGhensuu.mode == 330 ||
                    currentGhensuu.mode == 350 ||
                    currentGhensuu.mode == 700)
                ? BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.flash_on),
                        label: '最新',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: '選手',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.school),
                        label: '大学',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.leaderboard),
                        label: '記録',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.description),
                        label: '説明',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (index) async {
                      /*final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');*/
                      /*final Box<Ghensuu> _ghensuuBox_testdayo =
                          Hive.box<Ghensuu>('ghensuuBox');
                      final Ghensuu ghensuu = _ghensuuBox_testdayo.getAt(0)!;
                      await ghensuu.save();*/
                      await _ghensuuBox.put(
                        'global_ghensuu',
                        currentGhensuu..gamenflag = index,
                      );
                    },
                  )
                : null, // 条件を満たさない場合はナビゲーションバーを非表示にする
            /*bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.flash_on),
                  label: '最新',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: '選手'),
                BottomNavigationBarItem(icon: Icon(Icons.school), label: '大学'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard),
                  label: '記録',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: '説明',
                ),
              ],
              currentIndex: selectedIndex,
              onTap: (index) {
                // ★★★ ADD/MODIFY/DELETE START ★★★
                // ナビゲーションバーがタップされたら、gamenflagを更新
                // ただし、特定のmode中はナビゲーションバーの操作を制限することも検討
                //if (ghensuu.mode == 200 || ghensuu.mode == 400) {
                // 例: 画面表示が許可されているモードの場合のみ操作可能
                _ghensuuBox.put(
                  'global_ghensuu',
                  currentGhensuu..gamenflag = index,
                );
                /*} else {
                  print('処理中は画面遷移できません。'); // ユーザーへのフィードバック
                  // 必要であればSnackBarなどでユーザーに通知
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('現在、処理中です。操作をお待ちください。'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }*/
                // ★★★ ADD/MODIFY/DELETE END ★★★
              },
            ),*/
            // FloatingActionButtonは不要なため削除
          ),
          debugShowCheckedModeBanner: false, // ★この行を追加または変更
        );
      },
    );
  }
}
