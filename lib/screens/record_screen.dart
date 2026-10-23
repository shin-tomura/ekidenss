// lib/screens/record_screen.dart
//import 'dart:math';
import 'package:ekiden/album.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/rekidai_kiroku.dart'; // 歴代10位までの記録(1.8.8)
import 'package:ekiden/kansuu/taikai_chouki.dart'
    show ouroRace, fukuroRace, choukiOufukuKaishi; // 正月駅伝の往路記録・復路記録(2.0.0)
import 'package:ekiden/screens/kiroku_link.dart'; // 選手名のリンク(2.1.4)

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

// SwiftのKANSUUにあるTimeToFunByouString関数を模倣（ここでは簡易版）
String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

// SwiftのKANSUUにあるTimeToJikanFunByouString関数を模倣（ここでは簡易版）
String _timeToHourMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int hours = time ~/ 3600;
  final int minutes = (time % 3600) ~/ 60;
  final int seconds = (time % 60).toInt();
  return '${hours}時間${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
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

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox; // SenshuData Boxの参照を追加
  late Box<UnivData> _univBox; // UnivData Boxの参照を追加
  late Box<Kiroku> _kirokuBox;
  late Box<Album> _albumBox;
  // ★ 追加するコード
  late TabController _tabController;

  // ★ 2. 現在選択されている記録の種類を保持する変数
  // 　　 初期値はリストの最初の要素とする
  late String _selectedUnivRecordType;
  late String _selectedOverallRecordType; // 全体記録タブ用

  // 5. _recordTypes をインスタンス変数として定義
  late List<String> _recordTypes; // late で宣言し、initState で初期化する
  // sortedUnivData のデータが Hive から取得されることを前提
  late final UnivData tempUnivData;
  late final String _customEkidenName;
  // 2位以下を開いている記録の行(1.8.8。画面を閉じると、また閉じた状態に戻る)
  final Set<String> _hiraitaKiroku = <String>{};
  // 選手名から開く選手を引く一覧(2.1.4。記録の中身を描くたびに作り直す)
  KirokuLinkJisho? _linkJisho;

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _kirokuBox = Hive.box<Kiroku>('kirokuBox');
    _albumBox = Hive.box<Album>('albumBox');

    // 1. Boxからすべてのデータを取得し、リストに変換
    final List<UnivData> allUnivData = _univBox.values.toList();

    // 2. ID順にソート（a.id は UnivData 内のIDフィールド名に置き換えてください）
    allUnivData.sort((a, b) => a.id.compareTo(b.id));

    // 4. myUnivData には、あなたが後で使うであろう、このStateが扱う単一の大学データを割り当てる
    //    (もしこのRecordScreenが特定の大学データを扱うなら、そのIDで改めて取得する必要がある)

    // 5. 動的なカスタム駅伝の名前を取得
    _customEkidenName = allUnivData[0].name_tanshuku;

    // 6. _recordTypes に組み込む
    // (番号は監督データではなくアルバムの yobiint0・yobiint1 に保存している番号。2.1.4で足した
    // 「夏のTTの記録」は5番にし、選択肢の並び(_hyojiJun)だけ個人記録のすぐ下にする)
    _recordTypes = [
      '個人記録',
      '10月駅伝の記録',
      '11月駅伝の記録',
      '正月駅伝の記録',
      _customEkidenName,
      '夏のTTの記録',
    ];

    // 2. 前回保存されたタブインデックスを取得。
    //    値がない場合はデフォルトで0を使用します。
    final Album album = _albumBox.get('AlbumData')!;
    final int initialTabIndex = album.yobiint2 ?? 0;

    // 3. TabControllerの初期化に initialIndex を使用
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTabIndex, // ★ 保存されたインデックスを使用
    );

    // 4. ★ リスナーを追加し、タブ切り替えを監視
    _tabController.addListener(_handleTabChange);

    // 4. 初期値の設定（最初の要素または動的に変更した要素を初期値とする）
    //_selectedUnivRecordType = _recordTypes.first;
    //_selectedOverallRecordType = _recordTypes.first;

    _selectedUnivRecordType = _recordTypes[_bangouNaiHani(album.yobiint0)];
    _selectedOverallRecordType = _recordTypes[_bangouNaiHani(album.yobiint1)];
  }

  /// 保存してある選択肢の番号(範囲の外なら個人記録)
  int _bangouNaiHani(int bangou) =>
      (bangou >= 0 && bangou < _recordTypes.length) ? bangou : 0;

  /// 選択肢に並べる順(番号は _recordTypes の番号。2.1.4)
  static const List<int> _hyojiJun = [0, 5, 1, 2, 3, 4];

  /// 選択肢の項目
  List<DropdownMenuItem<String>> _sentakushi() {
    return [
      for (final int i in _hyojiJun)
        if (i < _recordTypes.length)
          DropdownMenuItem<String>(
            value: _recordTypes[i],
            child: Text(_recordTypes[i]),
          ),
    ];
  }

  @override
  void dispose() {
    // ★ リスナーを解除
    _tabController.removeListener(_handleTabChange);
    // ScrollControllerの代わりにTabControllerを解放
    _tabController.dispose(); // ★ disposeを修正
    super.dispose();
  }

  // MARK: - タブ切り替えのハンドラ
  void _handleTabChange() async {
    // アニメーション中ではなく、ユーザーがタブを完全に切り替えたことを確認
    if (!_tabController.indexIsChanging) {
      final int currentTabIndex = _tabController.index;

      // データベースに新しいインデックスを保存
      final Album album = _albumBox.get('AlbumData')!;
      album.yobiint2 = currentTabIndex; // ★ インデックスを保存

      // await で非同期保存を実行
      await album.save();

      //print('デバッグ: タブインデックスを $currentTabIndex に保存しました。');

      // UIを更新する必要はありませんが、もしタブの内容にsetStateが必要な場合はここで行います
      // setState(() {});
    }
  }

  // MARK: - リセット処理を管理するヘルパー関数
  // 記録は歴代10位まで残すので(1.8.8)、リセットはその行の歴代をまとめて消す。
  // 日本人と留学生を分けない行の2位以下は、日本人・留学生の行の記録を合わせて作るため、次のようにそろえる。
  // ・日本人と留学生を分けない行: その行と、日本人・留学生の行の記録を、まとめて消す
  // ・日本人(留学生)の行: その行の記録を消し、分けない行の1位を、留学生(日本人)の行の1位で作り直す
  // [shurui] 0:日本人と留学生を分けない行、1:日本人、2:留学生

  /// 分けない行([ichii])と、日本人・留学生の行の記録を、[shurui]に応じて消す
  void _resetAwase({
    required RekidaiOkiba ichii,
    required RekidaiOkiba nihonjin,
    required RekidaiOkiba ryuugakusei,
    required int shurui,
  }) {
    if (shurui == 0) {
      ichii.kaku([]);
      nihonjin.kaku([]);
      ryuugakusei.kaku([]);
      return;
    }
    final RekidaiOkiba kesu = shurui == 1 ? nihonjin : ryuugakusei;
    final RekidaiOkiba nokosu = shurui == 1 ? ryuugakusei : nihonjin;
    kesu.kaku([]);
    final List<RekidaiKiroku> l = nokosu.yomu();
    ichii.kaku(l.isEmpty ? [] : [l.first]);
  }

  /// 学内記録のリセット
  /// [recordType] 0:個人, 1:大会記録, 2:区間
  Future<void> _resetUnivRekidai({
    required int recordType,
    required int shurui,
    required int index1,
    required int index2,
  }) async {
    final ghensuu = _ghensuuBox.get('global_ghensuu');
    final Kiroku? kiroku = _kirokuBox.get('KirokuData');
    if (ghensuu == null || kiroku == null) return;
    final int myUnivId = ghensuu.MYunivid;
    final UnivData? univData = _univBox.get(myUnivId);
    if (univData == null) return;

    if (recordType == 1) {
      // 大会総合記録
      rekidaiUnivTaikai(univData, index1).kaku([]);
      await univData.save();
    } else if (recordType == 0) {
      // 個人記録
      _resetAwase(
        ichii: ichiiUnivKojin(univData, index1),
        nihonjin: rekidaiUnivKojin(kiroku, false, myUnivId, index1),
        ryuugakusei: rekidaiUnivKojin(kiroku, true, myUnivId, index1),
        shurui: shurui,
      );
      await univData.save();
      await kiroku.save();
    } else if (recordType == 2) {
      // 区間記録
      _resetAwase(
        ichii: ichiiUnivKukan(univData, index1, index2),
        nihonjin: rekidaiUnivKukan(kiroku, false, myUnivId, index1, index2),
        ryuugakusei: rekidaiUnivKukan(kiroku, true, myUnivId, index1, index2),
        shurui: shurui,
      );
      await univData.save();
      await kiroku.save();
    }
    // setState を呼び出してUIを更新
    setState(() {});
  }

  /// 全体記録のリセット
  /// [recordType] 0:個人, 1:大会記録, 2:区間
  Future<void> _resetOverallRekidai({
    required int recordType,
    required int shurui,
    required int index1,
    required int index2,
  }) async {
    final ghensuu = _ghensuuBox.get('global_ghensuu');
    final Kiroku? kiroku = _kirokuBox.get('KirokuData');
    if (ghensuu == null || kiroku == null) return;

    if (recordType == 1) {
      // 全体大会総合記録
      rekidaiZentaiTaikai(ghensuu, index1).kaku([]);
      await ghensuu.save();
    } else if (recordType == 0) {
      // 全体個人記録
      _resetAwase(
        ichii: ichiiZentaiKojin(ghensuu, index1),
        nihonjin: rekidaiZentaiKojin(kiroku, false, index1),
        ryuugakusei: rekidaiZentaiKojin(kiroku, true, index1),
        shurui: shurui,
      );
      await ghensuu.save();
      await kiroku.save();
    } else if (recordType == 2) {
      // 全体区間記録
      _resetAwase(
        ichii: ichiiZentaiKukan(ghensuu, index1, index2),
        nihonjin: rekidaiZentaiKukan(kiroku, false, index1, index2),
        ryuugakusei: rekidaiZentaiKukan(kiroku, true, index1, index2),
        shurui: shurui,
      );
      await ghensuu.save();
      await kiroku.save();
    }
    // setState を呼び出してUIを更新
    setState(() {});
  }

  /// リセットの確認ダイアログに出す補足([shurui]は上と同じ。大会記録はnull)
  String _resetHosoku(int? shurui) {
    switch (shurui) {
      case 0:
        return '歴代10位までの記録が、日本人・留学生の行の記録もあわせて、まとめて消えます。';
      case 1:
        return '歴代10位までの記録がまとめて消えます。日本人と留学生を分けない行の記録は、留学生の記録だけで作り直します。';
      case 2:
        return '歴代10位までの記録がまとめて消えます。日本人と留学生を分けない行の記録は、日本人の記録だけで作り直します。';
      default:
        return '歴代10位までの記録がまとめて消えます。';
    }
  }

  // MARK: - 確認ダイアログを表示するヘルパー関数
  // [hosoku] 何が消えるかの補足(1.8.8)
  Future<void> _showResetConfirmationDialog(
    String title,
    VoidCallback onConfirm, {
    String? hosoku,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ユーザーがダイアログの外をタップして閉じないようにする
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('この$titleの記録をリセットしますか？'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (hosoku != null)
                  Text(hosoku, style: const TextStyle(color: Colors.black)),
                const Text(
                  'この操作は元に戻せません。',
                  style: TextStyle(color: Colors.black),
                ),
                const Text(
                  '本当にリセットしてもよろしいですか？',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('リセットする'),
              onPressed: () {
                onConfirm(); // 確定した場合のみリセット処理を実行
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final ghensuu = ghensuuBox.get(
          'global_ghensuu',
          defaultValue: Ghensuu.initial(),
        )!;
        final myUnivId = ghensuu.MYunivid;

        final univDataBox = Hive.box<UnivData>('univBox');
        List<UnivData> sortedUnivData = univDataBox.values.toList();
        sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
        final Kiroku kiroku = _kirokuBox.get('KirokuData')!;
        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: _univBox.listenable(),
          builder: (context, univBox, _) {
            final UnivData? myUnivData = univBox.get(myUnivId);

            if (myUnivData == null) {
              return const Center(
                child: Text(
                  '大学データが見つかりません。',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            final KantokuData kantoku = kantokuBox.get('KantokuData')!;

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
                              overflow:
                                  TextOverflow.ellipsis, // はみ出す場合に"..."で省略
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
                              overflow: TextOverflow
                                  .ellipsis, // 追加: 1行に収まらない場合に"..."で省略
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
                // ★ AppBarの最下部にTabBarを追加
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '大学記録'),
                    Tab(text: '全体記録'),
                  ],
                  // タブのスタイルを適宜調整
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  indicatorColor: Colors.white,
                ),
              ),
              backgroundColor: HENSUU.backgroundcolor,

              // ★ bodyにTabBarViewを設定
              body: TabBarView(
                controller: _tabController,
                children: [
                  // 1. 大学記録タブの内容
                  _buildUnivRecordTab(context),
                  // 2. 全体記録タブの内容
                  _buildOverallRecordTab(context),
                ],
              ),

              /*body: Column(
                children: [
                  const SizedBox(height: 8), // スペースを確保
                  // 記録表示部分
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        // リンクボタン
                        //LinkButtons(context, ghensuu),

                        //const SizedBox(height: 32),
                        Text(
                          '${myUnivData.name}大学学内記録',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 5000m
                        _buildKojinKirokuSection(
                          title: '5000m',
                          time: myUnivData.time_univkojinkiroku[0][0],
                          year: myUnivData.year_univkojinkiroku[0][0],
                          month: myUnivData.month_univkojinkiroku[0][0],
                          name: myUnivData.name_univkojinkiroku[0][0],
                          gakunen: myUnivData.gakunen_univkojinkiroku[0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: '5000m日本人',
                          time:
                              kiroku.time_univ_jap_kojinkiroku[myUnivId][0][0],
                          year:
                              kiroku.year_univ_jap_kojinkiroku[myUnivId][0][0],
                          month:
                              kiroku.month_univ_jap_kojinkiroku[myUnivId][0][0],
                          name:
                              kiroku.name_univ_jap_kojinkiroku[myUnivId][0][0],
                          gakunen: kiroku
                              .gakunen_univ_jap_kojinkiroku[myUnivId][0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m日本人',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: false,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: '5000m留学生',
                          time: kiroku
                              .time_univ_ryuugakusei_kojinkiroku[myUnivId][0][0],
                          year: kiroku
                              .year_univ_ryuugakusei_kojinkiroku[myUnivId][0][0],
                          month: kiroku
                              .month_univ_ryuugakusei_kojinkiroku[myUnivId][0][0],
                          name: kiroku
                              .name_univ_ryuugakusei_kojinkiroku[myUnivId][0][0],
                          gakunen: kiroku
                              .gakunen_univ_ryuugakusei_kojinkiroku[myUnivId][0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m留学生',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: true,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 10000m
                        _buildKojinKirokuSection(
                          title: '10000m',
                          time: myUnivData.time_univkojinkiroku[1][0],
                          year: myUnivData.year_univkojinkiroku[1][0],
                          month: myUnivData.month_univkojinkiroku[1][0],
                          name: myUnivData.name_univkojinkiroku[1][0],
                          gakunen: myUnivData.gakunen_univkojinkiroku[1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: '10000m日本人',
                          time:
                              kiroku.time_univ_jap_kojinkiroku[myUnivId][1][0],
                          year:
                              kiroku.year_univ_jap_kojinkiroku[myUnivId][1][0],
                          month:
                              kiroku.month_univ_jap_kojinkiroku[myUnivId][1][0],
                          name:
                              kiroku.name_univ_jap_kojinkiroku[myUnivId][1][0],
                          gakunen: kiroku
                              .gakunen_univ_jap_kojinkiroku[myUnivId][1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m日本人',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: false,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: '10000m留学生',
                          time: kiroku
                              .time_univ_ryuugakusei_kojinkiroku[myUnivId][1][0],
                          year: kiroku
                              .year_univ_ryuugakusei_kojinkiroku[myUnivId][1][0],
                          month: kiroku
                              .month_univ_ryuugakusei_kojinkiroku[myUnivId][1][0],
                          name: kiroku
                              .name_univ_ryuugakusei_kojinkiroku[myUnivId][1][0],
                          gakunen: kiroku
                              .gakunen_univ_ryuugakusei_kojinkiroku[myUnivId][1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m留学生',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: true,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ハーフマラソン
                        _buildKojinKirokuSection(
                          title: 'ハーフマラソン',
                          time: myUnivData.time_univkojinkiroku[2][0],
                          year: myUnivData.year_univkojinkiroku[2][0],
                          month: myUnivData.month_univkojinkiroku[2][0],
                          name: myUnivData.name_univkojinkiroku[2][0],
                          gakunen: myUnivData.gakunen_univkojinkiroku[2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフマラソン',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: 'ハーフ日本人',
                          time:
                              kiroku.time_univ_jap_kojinkiroku[myUnivId][2][0],
                          year:
                              kiroku.year_univ_jap_kojinkiroku[myUnivId][2][0],
                          month:
                              kiroku.month_univ_jap_kojinkiroku[myUnivId][2][0],
                          name:
                              kiroku.name_univ_jap_kojinkiroku[myUnivId][2][0],
                          gakunen: kiroku
                              .gakunen_univ_jap_kojinkiroku[myUnivId][2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフ日本人',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: false,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: 'ハーフ留学生',
                          time: kiroku
                              .time_univ_ryuugakusei_kojinkiroku[myUnivId][2][0],
                          year: kiroku
                              .year_univ_ryuugakusei_kojinkiroku[myUnivId][2][0],
                          month: kiroku
                              .month_univ_ryuugakusei_kojinkiroku[myUnivId][2][0],
                          name: kiroku
                              .name_univ_ryuugakusei_kojinkiroku[myUnivId][2][0],
                          gakunen: kiroku
                              .gakunen_univ_ryuugakusei_kojinkiroku[myUnivId][2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフ留学生',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: true,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // フルマラソン
                        _buildKojinKirokuSection(
                          title: 'フルマラソン',
                          time: myUnivData.time_univkojinkiroku[3][0],
                          year: myUnivData.year_univkojinkiroku[3][0],
                          month: myUnivData.month_univkojinkiroku[3][0],
                          name: myUnivData.name_univkojinkiroku[3][0],
                          gakunen: myUnivData.gakunen_univkojinkiroku[3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フルマラソン',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: 'フル日本人',
                          time:
                              kiroku.time_univ_jap_kojinkiroku[myUnivId][3][0],
                          year:
                              kiroku.year_univ_jap_kojinkiroku[myUnivId][3][0],
                          month:
                              kiroku.month_univ_jap_kojinkiroku[myUnivId][3][0],
                          name:
                              kiroku.name_univ_jap_kojinkiroku[myUnivId][3][0],
                          gakunen: kiroku
                              .gakunen_univ_jap_kojinkiroku[myUnivId][3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フル日本人',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: false,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildKojinKirokuSection(
                          title: 'フル留学生',
                          time: kiroku
                              .time_univ_ryuugakusei_kojinkiroku[myUnivId][3][0],
                          year: kiroku
                              .year_univ_ryuugakusei_kojinkiroku[myUnivId][3][0],
                          month: kiroku
                              .month_univ_ryuugakusei_kojinkiroku[myUnivId][3][0],
                          name: kiroku
                              .name_univ_ryuugakusei_kojinkiroku[myUnivId][3][0],
                          gakunen: kiroku
                              .gakunen_univ_ryuugakusei_kojinkiroku[myUnivId][3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フル留学生',
                            () => _resetUnivRecord_kiroku(
                              ryuugakuseiflag: true,
                              myUnivId: myUnivId,
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Text(
                          '10月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 10月駅伝 総合記録
                        _buildOverallRecordSection(
                          title: '総合記録',
                          time: myUnivData.time_univtaikaikiroku[0][0],
                          year: myUnivData.year_univtaikaikiroku[0][0],
                          month: myUnivData.month_univtaikaikiroku[0][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 1,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 10月駅伝 区間記録 (1区〜6区)
                        ...List.generate(6, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKojinKirokuSection(
                                title: '${index + 1}区',
                                time: myUnivData
                                    .time_univkukankiroku[0][index][0],
                                year: myUnivData
                                    .year_univkukankiroku[0][index][0],
                                month: myUnivData
                                    .month_univkukankiroku[0][index][0],
                                name: myUnivData
                                    .name_univkukankiroku[0][index][0],
                                gakunen: myUnivData
                                    .gakunen_univkukankiroku[0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetUnivRecord(
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_univ_jap_kukankiroku[myUnivId][0][index][0],
                                year: kiroku
                                    .year_univ_jap_kukankiroku[myUnivId][0][index][0],
                                month: kiroku
                                    .month_univ_jap_kukankiroku[myUnivId][0][index][0],
                                name: kiroku
                                    .name_univ_jap_kukankiroku[myUnivId][0][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_jap_kukankiroku[myUnivId][0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_univ_ryuugakusei_kukankiroku[myUnivId][0][index][0],
                                year: kiroku
                                    .year_univ_ryuugakusei_kukankiroku[myUnivId][0][index][0],
                                month: kiroku
                                    .month_univ_ryuugakusei_kukankiroku[myUnivId][0][index][0],
                                name: kiroku
                                    .name_univ_ryuugakusei_kukankiroku[myUnivId][0][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_ryuugakusei_kukankiroku[myUnivId][0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),

                        const SizedBox(height: 10),
                        Text(
                          '11月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 11月駅伝 総合記録
                        _buildOverallRecordSection(
                          title: '総合記録',
                          time: myUnivData.time_univtaikaikiroku[1][0],
                          year: myUnivData.year_univtaikaikiroku[1][0],
                          month: myUnivData.month_univtaikaikiroku[1][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 1,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 11月駅伝 区間記録 (1区〜8区)
                        ...List.generate(8, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKojinKirokuSection(
                                title: '${index + 1}区',
                                time: myUnivData
                                    .time_univkukankiroku[1][index][0],
                                year: myUnivData
                                    .year_univkukankiroku[1][index][0],
                                month: myUnivData
                                    .month_univkukankiroku[1][index][0],
                                name: myUnivData
                                    .name_univkukankiroku[1][index][0],
                                gakunen: myUnivData
                                    .gakunen_univkukankiroku[1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetUnivRecord(
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_univ_jap_kukankiroku[myUnivId][1][index][0],
                                year: kiroku
                                    .year_univ_jap_kukankiroku[myUnivId][1][index][0],
                                month: kiroku
                                    .month_univ_jap_kukankiroku[myUnivId][1][index][0],
                                name: kiroku
                                    .name_univ_jap_kukankiroku[myUnivId][1][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_jap_kukankiroku[myUnivId][1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_univ_ryuugakusei_kukankiroku[myUnivId][1][index][0],
                                year: kiroku
                                    .year_univ_ryuugakusei_kukankiroku[myUnivId][1][index][0],
                                month: kiroku
                                    .month_univ_ryuugakusei_kukankiroku[myUnivId][1][index][0],
                                name: kiroku
                                    .name_univ_ryuugakusei_kukankiroku[myUnivId][1][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_ryuugakusei_kukankiroku[myUnivId][1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),

                        const SizedBox(height: 10),
                        Text(
                          '正月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 正月駅伝 総合記録
                        _buildOverallRecordSection(
                          title: '総合記録',
                          time: myUnivData.time_univtaikaikiroku[2][0],
                          year: myUnivData.year_univtaikaikiroku[2][0],
                          month: myUnivData.month_univtaikaikiroku[2][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 1,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 正月駅伝 区間記録 (1区〜10区)
                        ...List.generate(10, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKojinKirokuSection(
                                title: '${index + 1}区',
                                time: myUnivData
                                    .time_univkukankiroku[2][index][0],
                                year: myUnivData
                                    .year_univkukankiroku[2][index][0],
                                month: myUnivData
                                    .month_univkukankiroku[2][index][0],
                                name: myUnivData
                                    .name_univkukankiroku[2][index][0],
                                gakunen: myUnivData
                                    .gakunen_univkukankiroku[2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetUnivRecord(
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_univ_jap_kukankiroku[myUnivId][2][index][0],
                                year: kiroku
                                    .year_univ_jap_kukankiroku[myUnivId][2][index][0],
                                month: kiroku
                                    .month_univ_jap_kukankiroku[myUnivId][2][index][0],
                                name: kiroku
                                    .name_univ_jap_kukankiroku[myUnivId][2][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_jap_kukankiroku[myUnivId][2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_univ_ryuugakusei_kukankiroku[myUnivId][2][index][0],
                                year: kiroku
                                    .year_univ_ryuugakusei_kukankiroku[myUnivId][2][index][0],
                                month: kiroku
                                    .month_univ_ryuugakusei_kukankiroku[myUnivId][2][index][0],
                                name: kiroku
                                    .name_univ_ryuugakusei_kukankiroku[myUnivId][2][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_ryuugakusei_kukankiroku[myUnivId][2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),

                        const SizedBox(height: 10),
                        //カスタム駅伝
                        Text(
                          sortedUnivData[0].name_tanshuku,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // カスタム駅伝 総合記録
                        _buildOverallRecordSection(
                          title: '総合記録',
                          time: myUnivData.time_univtaikaikiroku[5][0],
                          year: myUnivData.year_univtaikaikiroku[5][0],
                          month: myUnivData.month_univtaikaikiroku[5][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetUnivRecord(
                              myUnivId: myUnivId,
                              recordType: 1,
                              index1: 5,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // カスタム駅伝 区間記録 (1区〜10区)
                        ...List.generate(ghensuu.kukansuu_taikaigoto[5], (
                          index,
                        ) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKojinKirokuSection(
                                title: '${index + 1}区',
                                time: myUnivData
                                    .time_univkukankiroku[5][index][0],
                                year: myUnivData
                                    .year_univkukankiroku[5][index][0],
                                month: myUnivData
                                    .month_univkukankiroku[5][index][0],
                                name: myUnivData
                                    .name_univkukankiroku[5][index][0],
                                gakunen: myUnivData
                                    .gakunen_univkukankiroku[5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetUnivRecord(
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_univ_jap_kukankiroku[myUnivId][5][index][0],
                                year: kiroku
                                    .year_univ_jap_kukankiroku[myUnivId][5][index][0],
                                month: kiroku
                                    .month_univ_jap_kukankiroku[myUnivId][5][index][0],
                                name: kiroku
                                    .name_univ_jap_kukankiroku[myUnivId][5][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_jap_kukankiroku[myUnivId][5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_univ_ryuugakusei_kukankiroku[myUnivId][5][index][0],
                                year: kiroku
                                    .year_univ_ryuugakusei_kukankiroku[myUnivId][5][index][0],
                                month: kiroku
                                    .month_univ_ryuugakusei_kukankiroku[myUnivId][5][index][0],
                                name: kiroku
                                    .name_univ_ryuugakusei_kukankiroku[myUnivId][5][index][0],
                                gakunen: kiroku
                                    .gakunen_univ_ryuugakusei_kukankiroku[myUnivId][5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetUnivRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    myUnivId: myUnivId,
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        // --- 全体歴代記録の追加 ---
                        const Divider(color: Colors.white54),
                        const SizedBox(height: 10),
                        Text(
                          '全体歴代記録',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 5000m
                        _buildOverallKojinKirokuSection(
                          title: '5000m',
                          time: ghensuu.time_zentaikojinkiroku[0][0],
                          year: ghensuu.year_zentaikojinkiroku[0][0],
                          month: ghensuu.month_zentaikojinkiroku[0][0],
                          name: ghensuu.name_zentaikojinkiroku[0][0],
                          gakunen: ghensuu.gakunen_zentaikojinkiroku[0][0],
                          univName: ghensuu.univname_zentaikojinkiroku[0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m',
                            () => _resetOverallRecord(
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: '5000m日本人',
                          time: kiroku.time_zentai_jap_kojinkiroku[0][0],
                          year: kiroku.year_zentai_jap_kojinkiroku[0][0],
                          month: kiroku.month_zentai_jap_kojinkiroku[0][0],
                          name: kiroku.name_zentai_jap_kojinkiroku[0][0],
                          gakunen: kiroku.gakunen_zentai_jap_kojinkiroku[0][0],
                          univName:
                              kiroku.univname_zentai_jap_kojinkiroku[0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m日本人',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: false,
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: '5000m留学生',
                          time:
                              kiroku.time_zentai_ryuugakusei_kojinkiroku[0][0],
                          year:
                              kiroku.year_zentai_ryuugakusei_kojinkiroku[0][0],
                          month:
                              kiroku.month_zentai_ryuugakusei_kojinkiroku[0][0],
                          name:
                              kiroku.name_zentai_ryuugakusei_kojinkiroku[0][0],
                          gakunen: kiroku
                              .gakunen_zentai_ryuugakusei_kojinkiroku[0][0],
                          univName: kiroku
                              .univname_zentai_ryuugakusei_kojinkiroku[0][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '5000m留学生',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: true,
                              recordType: 0,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 10000m
                        _buildOverallKojinKirokuSection(
                          title: '10000m',
                          time: ghensuu.time_zentaikojinkiroku[1][0],
                          year: ghensuu.year_zentaikojinkiroku[1][0],
                          month: ghensuu.month_zentaikojinkiroku[1][0],
                          name: ghensuu.name_zentaikojinkiroku[1][0],
                          gakunen: ghensuu.gakunen_zentaikojinkiroku[1][0],
                          univName: ghensuu.univname_zentaikojinkiroku[1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m',
                            () => _resetOverallRecord(
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: '10000m日本人',
                          time: kiroku.time_zentai_jap_kojinkiroku[1][0],
                          year: kiroku.year_zentai_jap_kojinkiroku[1][0],
                          month: kiroku.month_zentai_jap_kojinkiroku[1][0],
                          name: kiroku.name_zentai_jap_kojinkiroku[1][0],
                          gakunen: kiroku.gakunen_zentai_jap_kojinkiroku[1][0],
                          univName:
                              kiroku.univname_zentai_jap_kojinkiroku[1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m日本人',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: false,
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: '10000m留学生',
                          time:
                              kiroku.time_zentai_ryuugakusei_kojinkiroku[1][0],
                          year:
                              kiroku.year_zentai_ryuugakusei_kojinkiroku[1][0],
                          month:
                              kiroku.month_zentai_ryuugakusei_kojinkiroku[1][0],
                          name:
                              kiroku.name_zentai_ryuugakusei_kojinkiroku[1][0],
                          gakunen: kiroku
                              .gakunen_zentai_ryuugakusei_kojinkiroku[1][0],
                          univName: kiroku
                              .univname_zentai_ryuugakusei_kojinkiroku[1][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            '10000m留学生',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: true,
                              recordType: 0,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ハーフマラソン
                        _buildOverallKojinKirokuSection(
                          title: 'ハーフマラソン',
                          time: ghensuu.time_zentaikojinkiroku[2][0],
                          year: ghensuu.year_zentaikojinkiroku[2][0],
                          month: ghensuu.month_zentaikojinkiroku[2][0],
                          name: ghensuu.name_zentaikojinkiroku[2][0],
                          gakunen: ghensuu.gakunen_zentaikojinkiroku[2][0],
                          univName: ghensuu.univname_zentaikojinkiroku[2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフマラソン',
                            () => _resetOverallRecord(
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: 'ハーフ日本人',
                          time: kiroku.time_zentai_jap_kojinkiroku[2][0],
                          year: kiroku.year_zentai_jap_kojinkiroku[2][0],
                          month: kiroku.month_zentai_jap_kojinkiroku[2][0],
                          name: kiroku.name_zentai_jap_kojinkiroku[2][0],
                          gakunen: kiroku.gakunen_zentai_jap_kojinkiroku[2][0],
                          univName:
                              kiroku.univname_zentai_jap_kojinkiroku[2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフ日本人',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: false,
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: 'ハーフ留学生',
                          time:
                              kiroku.time_zentai_ryuugakusei_kojinkiroku[2][0],
                          year:
                              kiroku.year_zentai_ryuugakusei_kojinkiroku[2][0],
                          month:
                              kiroku.month_zentai_ryuugakusei_kojinkiroku[2][0],
                          name:
                              kiroku.name_zentai_ryuugakusei_kojinkiroku[2][0],
                          gakunen: kiroku
                              .gakunen_zentai_ryuugakusei_kojinkiroku[2][0],
                          univName: kiroku
                              .univname_zentai_ryuugakusei_kojinkiroku[2][0],
                          isOverallTime: false,
                          onReset: () => _showResetConfirmationDialog(
                            'ハーフ留学生',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: true,
                              recordType: 0,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // フルマラソン
                        _buildOverallKojinKirokuSection(
                          title: 'フルマラソン',
                          time: ghensuu.time_zentaikojinkiroku[3][0],
                          year: ghensuu.year_zentaikojinkiroku[3][0],
                          month: ghensuu.month_zentaikojinkiroku[3][0],
                          name: ghensuu.name_zentaikojinkiroku[3][0],
                          gakunen: ghensuu.gakunen_zentaikojinkiroku[3][0],
                          univName: ghensuu.univname_zentaikojinkiroku[3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フルマラソン',
                            () => _resetOverallRecord(
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: 'フル日本人',
                          time: kiroku.time_zentai_jap_kojinkiroku[3][0],
                          year: kiroku.year_zentai_jap_kojinkiroku[3][0],
                          month: kiroku.month_zentai_jap_kojinkiroku[3][0],
                          name: kiroku.name_zentai_jap_kojinkiroku[3][0],
                          gakunen: kiroku.gakunen_zentai_jap_kojinkiroku[3][0],
                          univName:
                              kiroku.univname_zentai_jap_kojinkiroku[3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フル日本人',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: false,
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        _buildOverallKojinKirokuSection(
                          title: 'フル留学生',
                          time:
                              kiroku.time_zentai_ryuugakusei_kojinkiroku[3][0],
                          year:
                              kiroku.year_zentai_ryuugakusei_kojinkiroku[3][0],
                          month:
                              kiroku.month_zentai_ryuugakusei_kojinkiroku[3][0],
                          name:
                              kiroku.name_zentai_ryuugakusei_kojinkiroku[3][0],
                          gakunen: kiroku
                              .gakunen_zentai_ryuugakusei_kojinkiroku[3][0],
                          univName: kiroku
                              .univname_zentai_ryuugakusei_kojinkiroku[3][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            'フル留学生',
                            () => _resetOverallRecord_kiroku(
                              ryuugakuseiflag: true,
                              recordType: 0,
                              index1: 3,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),

                        Text(
                          '10月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 10月駅伝 総合記録
                        _buildOverallEkidenKirokuSection(
                          title: '総合記録',
                          time: ghensuu.time_zentaitaikaikiroku[0][0],
                          year: ghensuu.year_zentaitaikaikiroku[0][0],
                          month: ghensuu.month_zentaitaikaikiroku[0][0],
                          univName: ghensuu.univname_zentaitaikaikiroku[0][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetOverallRecord(
                              recordType: 1,
                              index1: 0,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 10月駅伝 区間記録 (1区〜6区)
                        ...List.generate(6, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区',
                                time:
                                    ghensuu.time_zentaikukankiroku[0][index][0],
                                year:
                                    ghensuu.year_zentaikukankiroku[0][index][0],
                                month: ghensuu
                                    .month_zentaikukankiroku[0][index][0],
                                name:
                                    ghensuu.name_zentaikukankiroku[0][index][0],
                                gakunen: ghensuu
                                    .gakunen_zentaikukankiroku[0][index][0],
                                univName: ghensuu
                                    .univname_zentaikukankiroku[0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetOverallRecord(
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_zentai_jap_kukankiroku[0][index][0],
                                year: kiroku
                                    .year_zentai_jap_kukankiroku[0][index][0],
                                month: kiroku
                                    .month_zentai_jap_kukankiroku[0][index][0],
                                name: kiroku
                                    .name_zentai_jap_kukankiroku[0][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_jap_kukankiroku[0][index][0],
                                univName: kiroku
                                    .univname_zentai_jap_kukankiroku[0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_zentai_ryuugakusei_kukankiroku[0][index][0],
                                year: kiroku
                                    .year_zentai_ryuugakusei_kukankiroku[0][index][0],
                                month: kiroku
                                    .month_zentai_ryuugakusei_kukankiroku[0][index][0],
                                name: kiroku
                                    .name_zentai_ryuugakusei_kukankiroku[0][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_ryuugakusei_kukankiroku[0][index][0],
                                univName: kiroku
                                    .univname_zentai_ryuugakusei_kukankiroku[0][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    recordType: 2,
                                    index1: 0,
                                    index2: index,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),

                        Text(
                          '11月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 11月駅伝 総合記録
                        _buildOverallEkidenKirokuSection(
                          title: '総合記録',
                          time: ghensuu.time_zentaitaikaikiroku[1][0],
                          year: ghensuu.year_zentaitaikaikiroku[1][0],
                          month: ghensuu.month_zentaitaikaikiroku[1][0],
                          univName: ghensuu.univname_zentaitaikaikiroku[1][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetOverallRecord(
                              recordType: 1,
                              index1: 1,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 11月駅伝 区間記録 (1区〜8区)
                        ...List.generate(8, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区',
                                time:
                                    ghensuu.time_zentaikukankiroku[1][index][0],
                                year:
                                    ghensuu.year_zentaikukankiroku[1][index][0],
                                month: ghensuu
                                    .month_zentaikukankiroku[1][index][0],
                                name:
                                    ghensuu.name_zentaikukankiroku[1][index][0],
                                gakunen: ghensuu
                                    .gakunen_zentaikukankiroku[1][index][0],
                                univName: ghensuu
                                    .univname_zentaikukankiroku[1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetOverallRecord(
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_zentai_jap_kukankiroku[1][index][0],
                                year: kiroku
                                    .year_zentai_jap_kukankiroku[1][index][0],
                                month: kiroku
                                    .month_zentai_jap_kukankiroku[1][index][0],
                                name: kiroku
                                    .name_zentai_jap_kukankiroku[1][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_jap_kukankiroku[1][index][0],
                                univName: kiroku
                                    .univname_zentai_jap_kukankiroku[1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_zentai_ryuugakusei_kukankiroku[1][index][0],
                                year: kiroku
                                    .year_zentai_ryuugakusei_kukankiroku[1][index][0],
                                month: kiroku
                                    .month_zentai_ryuugakusei_kukankiroku[1][index][0],
                                name: kiroku
                                    .name_zentai_ryuugakusei_kukankiroku[1][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_ryuugakusei_kukankiroku[1][index][0],
                                univName: kiroku
                                    .univname_zentai_ryuugakusei_kukankiroku[1][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    recordType: 2,
                                    index1: 1,
                                    index2: index,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),

                        Text(
                          '正月駅伝',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 正月駅伝 総合記録
                        _buildOverallEkidenKirokuSection(
                          title: '総合記録',
                          time: ghensuu.time_zentaitaikaikiroku[2][0],
                          year: ghensuu.year_zentaitaikaikiroku[2][0],
                          month: ghensuu.month_zentaitaikaikiroku[2][0],
                          univName: ghensuu.univname_zentaitaikaikiroku[2][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetOverallRecord(
                              recordType: 1,
                              index1: 2,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // 正月駅伝 区間記録 (1区〜10区)
                        ...List.generate(10, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区',
                                time:
                                    ghensuu.time_zentaikukankiroku[2][index][0],
                                year:
                                    ghensuu.year_zentaikukankiroku[2][index][0],
                                month: ghensuu
                                    .month_zentaikukankiroku[2][index][0],
                                name:
                                    ghensuu.name_zentaikukankiroku[2][index][0],
                                gakunen: ghensuu
                                    .gakunen_zentaikukankiroku[2][index][0],
                                univName: ghensuu
                                    .univname_zentaikukankiroku[2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetOverallRecord(
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_zentai_jap_kukankiroku[2][index][0],
                                year: kiroku
                                    .year_zentai_jap_kukankiroku[2][index][0],
                                month: kiroku
                                    .month_zentai_jap_kukankiroku[2][index][0],
                                name: kiroku
                                    .name_zentai_jap_kukankiroku[2][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_jap_kukankiroku[2][index][0],
                                univName: kiroku
                                    .univname_zentai_jap_kukankiroku[2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_zentai_ryuugakusei_kukankiroku[2][index][0],
                                year: kiroku
                                    .year_zentai_ryuugakusei_kukankiroku[2][index][0],
                                month: kiroku
                                    .month_zentai_ryuugakusei_kukankiroku[2][index][0],
                                name: kiroku
                                    .name_zentai_ryuugakusei_kukankiroku[2][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_ryuugakusei_kukankiroku[2][index][0],
                                univName: kiroku
                                    .univname_zentai_ryuugakusei_kukankiroku[2][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    recordType: 2,
                                    index1: 2,
                                    index2: index,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          );
                        }),

                        const SizedBox(height: 10),

                        Text(
                          sortedUnivData[0].name_tanshuku,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // カスタム駅伝 総合記録
                        _buildOverallEkidenKirokuSection(
                          title: '総合記録',
                          time: ghensuu.time_zentaitaikaikiroku[5][0],
                          year: ghensuu.year_zentaitaikaikiroku[5][0],
                          month: ghensuu.month_zentaitaikaikiroku[5][0],
                          univName: ghensuu.univname_zentaitaikaikiroku[5][0],
                          isOverallTime: true,
                          onReset: () => _showResetConfirmationDialog(
                            '総合記録',
                            () => _resetOverallRecord(
                              recordType: 1,
                              index1: 5,
                              index2: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // カスタム駅伝 区間記録 (1区〜10区)
                        ...List.generate(ghensuu.kukansuu_taikaigoto[5], (
                          index,
                        ) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区',
                                time:
                                    ghensuu.time_zentaikukankiroku[5][index][0],
                                year:
                                    ghensuu.year_zentaikukankiroku[5][index][0],
                                month: ghensuu
                                    .month_zentaikukankiroku[5][index][0],
                                name:
                                    ghensuu.name_zentaikukankiroku[5][index][0],
                                gakunen: ghensuu
                                    .gakunen_zentaikukankiroku[5][index][0],
                                univName: ghensuu
                                    .univname_zentaikukankiroku[5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区',
                                  () => _resetOverallRecord(
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区日本人',
                                time: kiroku
                                    .time_zentai_jap_kukankiroku[5][index][0],
                                year: kiroku
                                    .year_zentai_jap_kukankiroku[5][index][0],
                                month: kiroku
                                    .month_zentai_jap_kukankiroku[5][index][0],
                                name: kiroku
                                    .name_zentai_jap_kukankiroku[5][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_jap_kukankiroku[5][index][0],
                                univName: kiroku
                                    .univname_zentai_jap_kukankiroku[5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区日本人',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: false,
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),
                              _buildOverallKojinKirokuSection(
                                title: '${index + 1}区留学生',
                                time: kiroku
                                    .time_zentai_ryuugakusei_kukankiroku[5][index][0],
                                year: kiroku
                                    .year_zentai_ryuugakusei_kukankiroku[5][index][0],
                                month: kiroku
                                    .month_zentai_ryuugakusei_kukankiroku[5][index][0],
                                name: kiroku
                                    .name_zentai_ryuugakusei_kukankiroku[5][index][0],
                                gakunen: kiroku
                                    .gakunen_zentai_ryuugakusei_kukankiroku[5][index][0],
                                univName: kiroku
                                    .univname_zentai_ryuugakusei_kukankiroku[5][index][0],
                                isOverallTime: false,
                                onReset: () => _showResetConfirmationDialog(
                                  '${index + 1}区留学生',
                                  () => _resetOverallRecord_kiroku(
                                    ryuugakuseiflag: true,
                                    recordType: 2,
                                    index1: 5,
                                    index2: index,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          );
                        }),

                        const SizedBox(
                          height: 60,
                        ), // bottomNavigationBar の高さの分を確保
                      ],
                    ),
                  ),
                ],
              ),
              */
            );
          },
        );
      },
    );
  }

  // 風フラグのテキストを返すヘルパー関数
  String _getKazeflagText(int flag) {
    switch (flag) {
      case 0:
        return '鬼';
      case 1:
        return '難';
      case 2:
        return '普';
      case 3:
        return '易';
      default:
        return '';
    }
  }

  // 正月駅伝の往路記録・復路記録の欄(全体と学内。歴代10位まで。2.0.0。kansuu/oufuku_kiroku.dart)
  // ・[zentai] 全体の記録か(falseなら総監督をしている大学の学内記録。[kijunUniv]はその大学)
  // ・往路・復路の記録は2.0.0から取り始めたので、それより前から遊んでいるデータは、記録を始めた年度を添える
  //   (年度はどの大学も同じなので、全体の記録では[kijunUniv]にどの大学を渡してもよい)
  // ・2.1.4から、往路・復路をそれぞれ1枚の枠にし、上の札から移れるようにした(_tobuKagiNamae)
  List<Widget> _buildOufukuSections({
    required bool zentai,
    required Ghensuu ghensuu,
    required UnivData kijunUniv,
  }) {
    const TextStyle chuu = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    Widget ran(int race, String title, String tobu) {
      return _buildRekidaiSection(
        key: _tobuKagi(_tobuKagiNamae(zentai, 2, tobu)),
        kagi: '${zentai ? 'zentai' : 'univ'}_taikai_$race',
        title: title,
        rekidai: zentai
            ? rekidaiZentaiTaikai(ghensuu, race).yomu()
            : rekidaiUnivTaikai(kijunUniv, race).yomu(),
        isOverallTime: true,
        senshu: false,
        daigaku: zentai,
        onReset: () => _showResetConfirmationDialog(
          title,
          () => zentai
              ? _resetOverallRekidai(
                  recordType: 1,
                  shurui: 0,
                  index1: race,
                  index2: 0,
                )
              : _resetUnivRekidai(
                  recordType: 1,
                  shurui: 0,
                  index1: race,
                  index2: 0,
                ),
          hosoku: _resetHosoku(null),
        ),
      );
    }

    final int kaishi = choukiOufukuKaishi(kijunUniv);
    return [
      ran(ouroRace, '往路記録(1〜5区)', 'ouro'),
      ran(fukuroRace, '復路記録(6〜10区)', 'fukuro'),
      if (kaishi > 1) ...[
        Text('(往路記録・復路記録は$kaishi年度から記録しています)', style: chuu),
        const SizedBox(height: 10),
      ],
    ];
  }

  // ---- 記録の欄の見た目(2.1.4。種目・区間ごとの区切りを分かりやすくした) ----
  // ・種目(駅伝は区間・総合・往路・復路)ごとに、少し明るい枠(_kirokuWaku)に1枚ずつまとめ、見出しは枠の上に1回だけ書く
  // ・個人記録と区間記録は、枠の中を「すべて」(日本人と留学生を合わせた並び)・「日本人」・「留学生」の3行に分け、
  //   行の頭に札を付ける(_fudaGyou。学内記録の画面で「全体」と書くと全体記録と紛らわしいので「すべて」にした)
  // ・リセットは、目立ちすぎないように、1位の記録のタイムの横の小さな文字にした(押したあとの確かめ方は今までどおり)
  // ・駅伝の記録は、上に総合・往路・復路・各区間の札(_tobuFuda)を並べ、押すとその枠まで移る

  // 「すべて」「日本人」「留学生」の札の文字(_buildAwaseSections の行の順)
  static const List<String> _awaseFuda = ['すべて', '日本人', '留学生'];

  // 札から移る先の枠の目印(大学記録と全体記録のタブ、大会ごとに分ける。同じ目印を2つの枠に付けないため)
  final Map<String, GlobalKey> _tobuKagiIchiran = <String, GlobalKey>{};
  GlobalKey _tobuKagi(String namae) =>
      _tobuKagiIchiran.putIfAbsent(namae, () => GlobalKey());
  static String _tobuKagiNamae(bool zentai, int race, String basho) =>
      '${zentai ? 'zentai' : 'univ'}_${race}_$basho';

  // 記録の枠(見出しと中身)
  Widget _kirokuWaku({
    Key? key,
    required String title,
    required List<Widget> naka,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...naka,
        ],
      ),
    );
  }

  // 行の頭に札を付けた行(文字を大きくしても入るように、札の幅は決めず、中身は残りの幅で折り返す)
  Widget _fudaGyou(String fuda, Widget naka) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          margin: const EdgeInsets.only(right: 8, top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2B3B52),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            fuda,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB8CCE8), fontSize: 12),
          ),
        ),
        Expanded(child: naka),
      ],
    );
  }

  // 1位の記録のタイムの横に置く「リセット」(小さな灰色の文字)
  Widget _resetMoji(VoidCallback onReset) {
    return InkWell(
      onTap: onReset,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          'リセット',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white54,
          ),
        ),
      ),
    );
  }

  // 駅伝の記録の上に並べる札(押すと、その枠まで移る)。[l] は札の文字と、移る先の目印の名前
  Widget _tobuFuda(List<(String, String)> l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (String, String) x in l)
            InkWell(
              onTap: () {
                final BuildContext? c = _tobuKagi(x.$2).currentContext;
                if (c == null) return;
                Scrollable.ensureVisible(
                  c,
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38, width: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  x.$1,
                  style: const TextStyle(
                    color: HENSUU.LinkColor,
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 駅伝の記録の札の並び(総合・往路・復路・各区間)
  List<(String, String)> _ekidenTobu(bool zentai, int race, int kukansuu, bool oufuku) {
    return [
      ('総合', _tobuKagiNamae(zentai, race, 'sougou')),
      if (oufuku) ('往路', _tobuKagiNamae(zentai, race, 'ouro')),
      if (oufuku) ('復路', _tobuKagiNamae(zentai, race, 'fukuro')),
      for (int i = 0; i < kukansuu; i++)
        ('${i + 1}区', _tobuKagiNamae(zentai, race, 'ku$i')),
    ];
  }

  // 記録の行のヘルパーウィジェット(歴代10位まで。1.8.8で、学内・全体の個人記録・区間記録・総合記録の4つをまとめた)
  // ・ふだんは1位だけを出し、2位以下があるときは、記録の下の「2位以下を見る」「閉じる」で開いたり閉じたりする
  // ・[senshu] 選手名と学年を出すか(総合記録は出さない)
  // ・[daigaku] 大学名を出すか(学内記録は出さない)
  // ・選手名は、開ける選手(現役の選手・残っている卒業生)ならリンクにする(2.1.4。screens/kiroku_link.dart。
  //   記録と選手は通算の番号だけで結びつけるので、2.1.4より前に出た記録はリンクにしない)
  // ・2.1.4から、見出しは枠(_kirokuWaku)の側で書き、ここは記録の並びだけにした。リセットは1位のタイムの横
  Widget _buildRekidaiNaka({
    required String kagi,
    required List<RekidaiKiroku> rekidai,
    required bool isOverallTime,
    required bool senshu,
    required bool daigaku,
    required VoidCallback onReset,
  }) {
    const TextStyle moji = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    );
    final bool aru = rekidai.isNotEmpty;
    final bool hirakeru = rekidai.length >= 2;
    final bool hiraiteru = hirakeru && _hiraitaKiroku.contains(kagi);
    final KirokuLinkJisho jisho = _linkJisho ??= KirokuLinkJisho();

    // 年月(灰色の小さな文字。タイムと名前が目立つように。2.1.4)
    const TextStyle usui = TextStyle(color: Colors.white60, fontSize: 12);

    // r位の記録(0が1位)
    // ・2.1.4から、順位を左の列に出し(閉じているときも「1」)、2位からは1件ごとに細い線で区切る。
    //   年月は2行目の後ろ(2行目がない学内の総合記録などは、タイムの後ろ)に灰色の小さな文字で書く
    // ・文字を大きくしても入るように、順位の列の幅は決めず、中身は残りの幅で折り返す
    Widget ikken(int r) {
      final RekidaiKiroku k = rekidai[r];
      final String timeString = isOverallTime
          ? _timeToHourMinuteSecondString(k.time)
          : _timeToMinuteSecondString(k.time);
      final Widget nengetsu = Text(' ${k.year}年${k.month}月', style: usui);
      // 2行目(選手名と学年・大学名。総合記録は大学名だけ。学内の総合記録はなし)
      final bool nigyoume = senshu || daigaku;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r > 0)
            const Divider(color: Colors.white12, height: 9, thickness: 0.5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                margin: const EdgeInsets.only(right: 10),
                child: Text(
                  '${r + 1}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(timeString, style: moji),
                        if (!nigyoume) nengetsu,
                        // リセットは、その行の歴代10位までをまとめて消すので、1位の記録の横に1つだけ置く
                        if (r == 0) _resetMoji(onReset),
                      ],
                    ),
                    if (nigyoume)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (senshu) ...[
                            jisho.namae(context, k.name, k.bangou, moji),
                            Text(' ${k.gakunen}年', style: moji),
                            if (daigaku) Text(' ${k.univname}', style: moji),
                          ] else
                            Text(k.univname, style: moji),
                          nengetsu,
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (!aru) return const Text('記録なし', style: moji);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int r = 0; r < (hiraiteru ? rekidai.length : 1); r++) ikken(r),
        // 開いたり閉じたりするのは、この文字を押したときだけ
        // (記録の部分は押しても反応しない。スクロールのつもりで触れたときに開閉しないように)
        if (hirakeru)
          InkWell(
            onTap: () {
              setState(() {
                if (!_hiraitaKiroku.remove(kagi)) {
                  _hiraitaKiroku.add(kagi);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                hiraiteru ? '▲ 閉じる' : '▼ 2位以下を見る',
                style: const TextStyle(
                  color: HENSUU.LinkColor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 1つの並びを1枚の枠で出す(総合記録・往路記録・復路記録)
  Widget _buildRekidaiSection({
    Key? key,
    required String kagi,
    required String title,
    required List<RekidaiKiroku> rekidai,
    required bool isOverallTime,
    required bool senshu,
    required bool daigaku,
    required VoidCallback onReset,
  }) {
    return _kirokuWaku(
      key: key,
      title: title,
      naka: [
        _buildRekidaiNaka(
          kagi: kagi,
          rekidai: rekidai,
          isOverallTime: isOverallTime,
          senshu: senshu,
          daigaku: daigaku,
          onReset: onReset,
        ),
      ],
    );
  }

  // 日本人と留学生を分けない行・日本人・留学生の3行(個人記録・区間記録。1.8.8)
  // 2.1.4から、3行を1枚の枠にまとめ、見出しは[titles]の1つ目(「5000m」「1区」)を枠の上に1回だけ書き、
  // 行の頭に「すべて」「日本人」「留学生」の札を付ける([titles]はリセットの確かめの画面に出す名前)
  // [titles] 3行の名前(分けない行、日本人、留学生の順)
  // [ichii] 分けない行の1位の置き場所(区間新などの判定に使う記録)
  // [onReset] 押したリセットの行(_resetAwase の shurui)と名前を受け取る
  // [hitoriIkken] 一人につき一番速い記録だけを出すか(個人記録)
  Widget _buildAwaseSections({
    Key? key,
    required String kagi,
    required List<String> titles,
    required RekidaiOkiba ichii,
    required RekidaiOkiba nihonjin,
    required RekidaiOkiba ryuugakusei,
    required bool isOverallTime,
    required bool daigaku,
    required bool hitoriIkken,
    required void Function(int shurui, String title) onReset,
  }) {
    List<RekidaiKiroku> j = nihonjin.yomu();
    List<RekidaiKiroku> r = ryuugakusei.yomu();
    if (hitoriIkken) {
      // 前から同じ選手の記録が重なって残っていても、一番速い記録だけを出す
      j = rekidaiHitoriIkken(j);
      r = rekidaiHitoriIkken(r);
    }
    final List<List<RekidaiKiroku>> gyou = [
      rekidaiAwaseru(
        ichii: ichii.yomu(),
        nihonjin: j,
        ryuugakusei: r,
        hitoriIkken: hitoriIkken,
      ),
      j,
      r,
    ];
    return _kirokuWaku(
      key: key,
      title: titles[0],
      naka: [
        for (int shurui = 0; shurui < 3; shurui++) ...[
          if (shurui > 0)
            const Divider(color: Colors.white24, height: 13, thickness: 0.5),
          _fudaGyou(
            _awaseFuda[shurui],
            _buildRekidaiNaka(
              kagi: '${kagi}_$shurui',
              rekidai: gyou[shurui],
              isOverallTime: isOverallTime,
              senshu: true,
              daigaku: daigaku,
              onReset: () => onReset(shurui, titles[shurui]),
            ),
          ),
        ],
      ],
    );
  }

  // MARK: - 大学記録タブのコンテンツ
  Widget _buildUnivRecordTab(BuildContext context) {
    /*final ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;*/
    //final myUnivId = ghensuu.MYunivid;
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    //final Kiroku kiroku = _kirokuBox.get('KirokuData')!;
    //final UnivData myUnivData = _univBox.get(myUnivId)!;
    // ★ ここでListViewを使い、大学記録関連のウィジェットのみを配置
    return Column(
      children: [
        const SizedBox(height: 8), // スペースを確保
        // ★ 1. ドロップダウンボタンの設置
        DropdownButton<String>(
          value: _selectedUnivRecordType, // 現在の選択値
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: TextStyle(
            color: HENSUU.LinkColor,
            fontSize: HENSUU.fontsize_honbun,
          ),
          underline: Container(
            height: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              final Album album = _albumBox.get('AlbumData')!;
              album.yobiint0 = _bangouNaiHani(_recordTypes.indexOf(newValue));
              await album.save();
              setState(() {
                _selectedUnivRecordType = newValue; // 選択されたらStateを更新
              });
            }
          },
          items: _sentakushi(),
        ),

        const SizedBox(height: 20),

        // 記録表示部分
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ★ 2. 選択された種類に応じて表示するウィジェットを切り替える
              _buildUnivRecordContent(_selectedUnivRecordType),
            ],
          ),
        ),
      ],
    );
  }

  // MARK: - 全体記録タブのコンテンツ
  Widget _buildOverallRecordTab(BuildContext context) {
    /*final ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;*/
    //final myUnivId = ghensuu.MYunivid;
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    //final Kiroku kiroku = _kirokuBox.get('KirokuData')!;
    //final UnivData myUnivData = _univBox.get(myUnivId)!;
    // ★ ここでListViewを使い、全体記録関連のウィジェットのみを配置
    return Column(
      children: [
        const SizedBox(height: 8), // スペースを確保
        // ★ 1. ドロップダウンボタンの設置
        DropdownButton<String>(
          value: _selectedOverallRecordType, // 現在の選択値
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: TextStyle(color: HENSUU.LinkColor, fontSize: 18),
          underline: Container(
            height: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              final Album album = _albumBox.get('AlbumData')!;
              album.yobiint1 = _bangouNaiHani(_recordTypes.indexOf(newValue));
              await album.save();
              setState(() {
                _selectedOverallRecordType = newValue; // 選択されたらStateを更新
              });
            }
          },
          items: _sentakushi(),
        ),

        const SizedBox(height: 20),

        // 記録表示部分
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ★ 2. 選択された種類に応じて表示するウィジェットを切り替える
              _buildOverallRecordContent(_selectedOverallRecordType),
            ],
          ),
        ),
      ],
    );
  }

  // 記録画面に出す個人記録の種目の名前(番号は個人記録の番号。1.8.8でまとめた。2.1.4から夏のTTの4種目も)
  static const List<String> _kojinShumoku = [
    '5000m',
    '10000m',
    'ハーフマラソン',
    'フルマラソン',
    '登り1万',
    '下り1万',
    'ロード1万',
    'クロカン1万',
  ];
  static const List<String> _kojinShumokuRyaku = [
    '5000m',
    '10000m',
    'ハーフ',
    'フル',
    '登り1万',
    '下り1万',
    'ロード1万',
    'クロカン1万',
  ];

  // 「個人記録」に出す種目の番号
  static const List<int> _kojinBangou = [0, 1, 2, 3];

  // 「夏のTTの記録」に出す種目の番号(2.1.4。学内TT特集と同じく、ロード・登り・下り・クロカンの順)
  static const List<int> _ttBangou = [6, 4, 5, 7];

  /// 選択肢[sentaku]で出す個人記録の種目の番号(個人記録・夏のTTの記録でなければ空)
  static List<int> _kojinSentakuBangou(int sentaku) {
    if (sentaku == 0) return _kojinBangou;
    if (sentaku == 5) return _ttBangou;
    return const [];
  }

  /// 夏のTTの記録の見出しの下に添える文(2.1.4)
  static const String _ttSetsumei =
      'どの大学も同じコース・同じ条件で走る、夏の学内タイムトライアルの記録です。';

  // 駅伝の記録の選択肢(_recordTypes の1〜4)の大会番号
  static const List<int> _ekidenRacebangou = [0, 1, 2, 5];

  // 駅伝の記録の見出しと区間数
  String _ekidenMidashi(int sentaku, List<UnivData> sortedUnivData) {
    if (sentaku == 4) return sortedUnivData[0].name_tanshuku; // カスタム駅伝
    return const ['10月駅伝', '11月駅伝', '正月駅伝'][sentaku - 1];
  }

  int _ekidenKukansuu(int sentaku, Ghensuu ghensuu) {
    if (sentaku == 4) return ghensuu.kukansuu_taikaigoto[5]; // カスタム駅伝
    return const [6, 8, 10][sentaku - 1];
  }

  // MARK: - 大学記録のコンテンツ切り替えヘルパー関数
  Widget _buildUnivRecordContent(String recordType) {
    final ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final myUnivId = ghensuu.MYunivid;
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    final Kiroku kiroku = _kirokuBox.get('KirokuData')!;
    final UnivData myUnivData = _univBox.get(myUnivId)!;
    const TextStyle moji = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    );
    _linkJisho = KirokuLinkJisho(); // 選手名のリンク(2.1.4)
    final int sentaku = _recordTypes.indexOf(recordType);

    if (sentaku == 0 || sentaku == 5) {
      // 個人記録・夏のTTの記録(2.1.4)
      final List<int> shumoku = _kojinSentakuBangou(sentaku);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せを維持
        children: [
          Text('${myUnivData.name}大学学内記録', style: moji),
          if (sentaku == 5) const Text(_ttSetsumei, style: moji),
          const SizedBox(height: 10),
          // 種目ごとに1枚の枠(2.1.4)
          for (final int k in shumoku)
            _buildAwaseSections(
              kagi: 'univ_kojin_$k',
              titles: [
                _kojinShumoku[k],
                '${_kojinShumokuRyaku[k]}日本人',
                '${_kojinShumokuRyaku[k]}留学生',
              ],
              ichii: ichiiUnivKojin(myUnivData, k),
              nihonjin: rekidaiUnivKojin(kiroku, false, myUnivId, k),
              ryuugakusei: rekidaiUnivKojin(kiroku, true, myUnivId, k),
              isOverallTime: k == 3, // フルマラソンは時間で表示
              daigaku: false,
              hitoriIkken: true, // 個人記録は一人につき一番速い記録だけ
              onReset: (shurui, title) => _showResetConfirmationDialog(
                title,
                () => _resetUnivRekidai(
                  recordType: 0,
                  shurui: shurui,
                  index1: k,
                  index2: 0,
                ),
                hosoku: _resetHosoku(shurui),
              ),
            ),
        ],
      );
    } else if (sentaku >= 1 && sentaku <= 4) {
      // 駅伝の記録
      final int race = _ekidenRacebangou[sentaku - 1];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せを維持
        children: [
          Text(_ekidenMidashi(sentaku, sortedUnivData), style: moji),
          const SizedBox(height: 5),
          // 総合・往路・復路・各区間へ移る札(2.1.4)
          _tobuFuda(
            _ekidenTobu(false, race, _ekidenKukansuu(sentaku, ghensuu), race == 2),
          ),
          // 総合記録
          _buildRekidaiSection(
            key: _tobuKagi(_tobuKagiNamae(false, race, 'sougou')),
            kagi: 'univ_taikai_$race',
            title: '総合記録',
            rekidai: rekidaiUnivTaikai(myUnivData, race).yomu(),
            isOverallTime: true,
            senshu: false,
            daigaku: false,
            onReset: () => _showResetConfirmationDialog(
              '総合記録',
              () => _resetUnivRekidai(
                recordType: 1,
                shurui: 0,
                index1: race,
                index2: 0,
              ),
              hosoku: _resetHosoku(null),
            ),
          ),
          // 正月駅伝の往路記録・復路記録(2.0.0。kansuu/oufuku_kiroku.dart)
          if (race == 2)
            ..._buildOufukuSections(
              zentai: false,
              ghensuu: ghensuu,
              kijunUniv: myUnivData,
            ),
          // 区間記録
          for (
            int index = 0;
            index < _ekidenKukansuu(sentaku, ghensuu);
            index++
          )
            // 区間ごとに1枚の枠(2.1.4。上の札から移れる)
            _buildAwaseSections(
                  key: _tobuKagi(_tobuKagiNamae(false, race, 'ku$index')),
                  kagi: 'univ_kukan_${race}_$index',
                  titles: [
                    '${index + 1}区',
                    '${index + 1}区日本人',
                    '${index + 1}区留学生',
                  ],
                  ichii: ichiiUnivKukan(myUnivData, race, index),
                  nihonjin: rekidaiUnivKukan(
                    kiroku,
                    false,
                    myUnivId,
                    race,
                    index,
                  ),
                  ryuugakusei: rekidaiUnivKukan(
                    kiroku,
                    true,
                    myUnivId,
                    race,
                    index,
                  ),
                  isOverallTime: false,
                  daigaku: false,
                  hitoriIkken: false,
                  onReset: (shurui, title) => _showResetConfirmationDialog(
                    title,
                    () => _resetUnivRekidai(
                      recordType: 2,
                      shurui: shurui,
                      index1: race,
                      index2: index,
                    ),
                    hosoku: _resetHosoku(shurui),
                  ),
                ),
        ],
      );
    } else {
      return const Text('コンテンツがありません', style: TextStyle(color: Colors.white));
    }
  }

  Widget _buildOverallRecordContent(String recordType) {
    final ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    final Kiroku kiroku = _kirokuBox.get('KirokuData')!;
    const TextStyle moji = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    );
    _linkJisho = KirokuLinkJisho(); // 選手名のリンク(2.1.4)
    final int sentaku = _recordTypes.indexOf(recordType);

    if (sentaku == 0 || sentaku == 5) {
      // 個人記録・夏のTTの記録(2.1.4)
      final List<int> shumoku = _kojinSentakuBangou(sentaku);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せを維持
        children: [
          const Text('全体歴代記録', style: moji),
          if (sentaku == 5) const Text(_ttSetsumei, style: moji),
          const SizedBox(height: 15),
          // 種目ごとに1枚の枠(2.1.4)
          for (final int k in shumoku)
            _buildAwaseSections(
              kagi: 'zentai_kojin_$k',
              titles: [
                _kojinShumoku[k],
                '${_kojinShumokuRyaku[k]}日本人',
                '${_kojinShumokuRyaku[k]}留学生',
              ],
              ichii: ichiiZentaiKojin(ghensuu, k),
              nihonjin: rekidaiZentaiKojin(kiroku, false, k),
              ryuugakusei: rekidaiZentaiKojin(kiroku, true, k),
              isOverallTime: k == 3, // フルマラソンは時間で表示
              daigaku: true,
              hitoriIkken: true, // 個人記録は一人につき一番速い記録だけ
              onReset: (shurui, title) => _showResetConfirmationDialog(
                title,
                () => _resetOverallRekidai(
                  recordType: 0,
                  shurui: shurui,
                  index1: k,
                  index2: 0,
                ),
                hosoku: _resetHosoku(shurui),
              ),
            ),
        ],
      );
    } else if (sentaku >= 1 && sentaku <= 4) {
      // 駅伝の記録
      final int race = _ekidenRacebangou[sentaku - 1];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せを維持
        children: [
          Text(_ekidenMidashi(sentaku, sortedUnivData), style: moji),
          const SizedBox(height: 5),
          // 総合・往路・復路・各区間へ移る札(2.1.4)
          _tobuFuda(
            _ekidenTobu(
              true,
              race,
              _ekidenKukansuu(sentaku, ghensuu),
              race == 2 && sortedUnivData.isNotEmpty,
            ),
          ),
          // 総合記録
          _buildRekidaiSection(
            key: _tobuKagi(_tobuKagiNamae(true, race, 'sougou')),
            kagi: 'zentai_taikai_$race',
            title: '総合記録',
            rekidai: rekidaiZentaiTaikai(ghensuu, race).yomu(),
            isOverallTime: true,
            senshu: false,
            daigaku: true,
            onReset: () => _showResetConfirmationDialog(
              '総合記録',
              () => _resetOverallRekidai(
                recordType: 1,
                shurui: 0,
                index1: race,
                index2: 0,
              ),
              hosoku: _resetHosoku(null),
            ),
          ),
          // 正月駅伝の往路記録・復路記録(2.0.0。kansuu/oufuku_kiroku.dart)
          if (race == 2 && sortedUnivData.isNotEmpty)
            ..._buildOufukuSections(
              zentai: true,
              ghensuu: ghensuu,
              kijunUniv: sortedUnivData[0],
            ),
          // 区間記録
          for (
            int index = 0;
            index < _ekidenKukansuu(sentaku, ghensuu);
            index++
          )
            // 区間ごとに1枚の枠(2.1.4。上の札から移れる)
            _buildAwaseSections(
                  key: _tobuKagi(_tobuKagiNamae(true, race, 'ku$index')),
                  kagi: 'zentai_kukan_${race}_$index',
                  titles: [
                    '${index + 1}区',
                    '${index + 1}区日本人',
                    '${index + 1}区留学生',
                  ],
                  ichii: ichiiZentaiKukan(ghensuu, race, index),
                  nihonjin: rekidaiZentaiKukan(kiroku, false, race, index),
                  ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, index),
                  isOverallTime: false,
                  daigaku: true,
                  hitoriIkken: false,
                  onReset: (shurui, title) => _showResetConfirmationDialog(
                    title,
                    () => _resetOverallRekidai(
                      recordType: 2,
                      shurui: shurui,
                      index1: race,
                      index2: index,
                    ),
                    hosoku: _resetHosoku(shurui),
                  ),
                ),
        ],
      );
    } else {
      return const Text('コンテンツがありません', style: TextStyle(color: Colors.white));
    }
  }
}
