import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuモデルのインポート
import 'package:ekiden/constants.dart'; // 定数のインポート
import 'package:ekiden/univ_data.dart'; // 追加: UnivDataも必要なのでインポート
import 'package:ekiden/senshu_data.dart'; // 追加: SenshuDataも必要なのでインポート
import 'package:hive_flutter/hive_flutter.dart'; // Hiveのリスナーを使用 (ここでは直接は使わないが、Boxアクセス用)
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/kantoku_data.dart';
// KANSUUクラスをインポートするか、必要な関数をここに直接定義
// 仮で必要な関数をここに定義します。もし kansuu.dart があるならそちらをインポートしてください。
// import 'package:ekiden/utils/kansuu.dart';

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

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

// Mode0100Content を StatelessWidget に変更し、必要な引数を受け取るようにする
class Mode0100Content extends StatelessWidget {
  final Ghensuu ghensuu; // 親から渡される Ghensuu オブジェクト
  final VoidCallback? onAdvanceMode; // 親から渡されるコールバック

  const Mode0100Content({
    super.key,
    required this.ghensuu, // ghensuu は必須
    this.onAdvanceMode, // onAdvanceMode はオプション
  });

  @override
  Widget build(BuildContext context) {
    // Mode0100Content内でHiveデータを直接listenする場合
    // (LatestScreenからのghensuu引数は、ここでは主にonAdvanceModeのトリガーに使う)

    // Hive Boxへのアクセス
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    // UnivData を ID 順にソート
    List<UnivData> _getSortedUnivData(List<UnivData> allUnivData) {
      return allUnivData.toList()..sort((a, b) => a.id.compareTo(b.id));
    }

    // 1年生選手をフィルタリング
    List<SenshuData> _getIchinenseiFilteredSenshuData(
      List<SenshuData> allSenshuData,
    ) {
      return allSenshuData.where((s) => s.gakunen == 1).toList();
    }

    // 入学時5000mタイム順にソート
    List<SenshuData> _getNyuugakuji5000TimeJunSenshuData(
      List<SenshuData> ichinenseiSenshuData,
    ) {
      return ichinenseiSenshuData.toList()..sort((a, b) {
        // タイムを比較
        final timeComparison = a.kiroku_nyuugakuji_5000.compareTo(
          b.kiroku_nyuugakuji_5000,
        );
        // タイムが異なる場合は、その比較結果を返す
        if (timeComparison != 0) {
          return timeComparison;
        }
        // タイムが同じ場合は、IDで比較して順序を安定化
        return a.id.compareTo(b.id);
      });
    }

    // 特定の大学の1年生選手をフィルタリング
    List<SenshuData> _getUnivFilteredSenshuData(
      List<SenshuData> ichinenseiSenshuData,
      int myUnivId,
    ) {
      return ichinenseiSenshuData.where((s) => s.univid == myUnivId).toList();
    }

    // 特定の大学の入学時5000mタイム順にソート
    List<SenshuData> _getNyuugakuji5000TimeJunUnivFilteredSenshuData(
      List<SenshuData> univFilteredSenshuData,
    ) {
      return univFilteredSenshuData.toList()..sort(
        (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
      );
    }

    // ゲームを進めるボタンのアクション
    void _advanceGameMode() {
      // 親から渡された onAdvanceMode コールバックを呼び出す
      onAdvanceMode?.call();
    }

    // ⚠️ 実際の条件チェックロジックに置き換えてください
    bool _checkAdvanceCondition() {
      // 例: 3月25日かどうかをチェックする
      return ghensuu.month == 3 && ghensuu.day == 25;
      //return false; // デフォルトはfalse（確認なし）
    }

    // State クラス内のどこかにこのメソッドを追加します
    void _handleAdvanceButton(BuildContext context) async {
      // ----------------------------------------------------
      // 1. 確認メッセージを表示するかどうかを判断する条件
      // ----------------------------------------------------
      // ⚠️ ここに「ある条件が成就しているか」をチェックするロジックを記述します
      // 例: 卒業日である場合、重要なイベントがある場合など
      final bool shouldShowConfirmation = _checkAdvanceCondition(); // 判定関数を呼び出し

      if (shouldShowConfirmation) {
        // ----------------------------------------------------
        // 2. 確認ダイアログを表示し、ユーザーの選択を待つ
        // ----------------------------------------------------
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              // ----------------------------------------------------
              // ★ タイトルの文字色を黒に設定
              // ----------------------------------------------------
              title: const Text(
                'ゲーム進行の確認',
                style: TextStyle(color: Colors.black),
              ),
              // ----------------------------------------------------
              // ★ 内容の文字色を黒に設定
              // ----------------------------------------------------
              content: const Text(
                '思い入れのある4年生はアルバムへ追加済みですか？\nこのままゲームを進めてもよろしいですか？\n（キャンセルすると現在の画面に戻ります）',
                style: TextStyle(color: Colors.black),
              ),

              // ダイアログの背景色自体も白になることが多いため、基本的には黒で読みやすくなります
              actions: <Widget>[
                // TextButtonはデフォルトでforegroundColor（文字色）がテーマのPrimaryColorになるため、
                // ここも黒にしたい場合は明示的に設定が必要です。
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'キャンセル',
                    // ★ ボタンの文字色も黒にしたい場合
                    // style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'はい、進めます',
                    // ★ ボタンの文字色も黒にしたい場合
                    // style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );

        // 3. ユーザーが「はい」を選択した場合のみ、ゲーム進行処理を実行
        if (confirmed == true) {
          _advanceGameMode(); // 元の進む処理を実行
        }
      } else {
        // 4. 確認が不要な場合は、そのままゲーム進行処理を実行
        _advanceGameMode();
      }
    }

    // ----------------------------------------------------
    // 補足: 判定関数と元の進む処理（実装は環境に合わせてください）
    // ----------------------------------------------------

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body: // ← ここにSafeAreaを追加します
      ValueListenableBuilder<Box<Ghensuu>>(
        valueListenable: Hive.box<Ghensuu>(
          'ghensuuBox',
        ).listenable(), // ghensuuBoxを直接listen
        builder: (context, ghensuuBox, _) {
          final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');

          if (currentGhensuu == null) {
            return const Center(
              child: CircularProgressIndicator(color: HENSUU.textcolor),
            );
          }

          return ValueListenableBuilder<Box<UnivData>>(
            valueListenable: univdataBox.listenable(),
            builder: (context, univdataBox, _) {
              final List<UnivData> allUnivData = univdataBox.values.toList();
              final List<UnivData> idjununivdata = _getSortedUnivData(
                allUnivData,
              );

              return ValueListenableBuilder<Box<SenshuData>>(
                valueListenable: senshudataBox.listenable(),
                builder: (context, senshudataBox, _) {
                  final List<SenshuData> allSenshuData = senshudataBox.values
                      .toList();

                  final List<SenshuData> ichinenseiFilteredSenshuData =
                      _getIchinenseiFilteredSenshuData(allSenshuData);
                  final List<SenshuData> nyuugakuji5000timejunSenshuData =
                      _getNyuugakuji5000TimeJunSenshuData(
                        ichinenseiFilteredSenshuData,
                      );

                  final List<SenshuData> univFilteredSenshuData =
                      _getUnivFilteredSenshuData(
                        ichinenseiFilteredSenshuData,
                        currentGhensuu.MYunivid,
                      );
                  final List<SenshuData>
                  nyuugakuji5000timejununivfilteredsenshudata =
                      _getNyuugakuji5000TimeJunUnivFilteredSenshuData(
                        univFilteredSenshuData,
                      );
                  // Hive.box() を使って、既に開いているBoxを取得
                  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
                  // Boxからデータを読み込む
                  final KantokuData kantoku = kantokuBox.get('KantokuData')!;

                  final rijiBox = Hive.box<RijiData>('rijiBox');
                  // Boxからデータを読み込む
                  final RijiData riji = rijiBox.get('RijiData')!;
                  int count_riji = 0;
                  for (int i_riji = 0; i_riji < 10; i_riji++) {
                    if (riji.rid_riji[i_riji] != 0) {
                      count_riji++;
                    }
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          // Rowを使って全体を左右に配置
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // 両端に配置
                          children: [
                            // 左側のColumnをExpandedで囲み、残りのスペースを柔軟に利用させる
                            Expanded(
                              child: Column(
                                // テキストを左寄せで2行にまとめる
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // 左寄せ
                                children: [
                                  Row(
                                    // 1行目のテキスト
                                    children: [
                                      Text(
                                        _getCombinedDifficultyText(
                                          kantoku,
                                          currentGhensuu,
                                        ),
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      ),
                                      const SizedBox(width: 8), // テキスト間のスペース
                                      // 日付テキストが長い場合のためにFlexibleで囲む
                                      Flexible(
                                        child: Text(
                                          "${currentGhensuu.year}年${currentGhensuu.month}月${_dayToString(currentGhensuu.day)}",
                                          style: const TextStyle(
                                            color: HENSUU.textcolor,
                                          ),
                                          overflow: TextOverflow
                                              .ellipsis, // はみ出す場合は「...」で省略
                                          maxLines: 1, // 1行に制限
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4), // 行間のスペース
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
                              // ボタンを右に配置
                              onPressed: onAdvanceMode != null
                                  ? () => _handleAdvanceButton(context)
                                  : null, // ★ ラッパー関数に変更
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HENSUU.buttonColor,
                                foregroundColor: HENSUU.buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("進む＞＞"),
                            ),
                            /*ElevatedButton(
                              // ボタンを右に配置
                              onPressed: onAdvanceMode != null
                                  ? _advanceGameMode
                                  : null, // onAdvanceModeがnullでなければボタンを有効化
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HENSUU.buttonColor,
                                foregroundColor: HENSUU.buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize:
                                    Size.zero, // サイズが自動調整されるように最小サイズを0に
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("進む＞＞"),
                            ),*/
                          ],
                        ),
                      ),
                      const Divider(color: HENSUU.textcolor),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (currentGhensuu.mode == 100 &&
                                    currentGhensuu.month == 4 &&
                                    currentGhensuu.day == 5) ...[
                                  if (kantoku.yobiint1[currentGhensuu
                                              .MYunivid] ==
                                          1 ||
                                      kantoku.yobiint1[currentGhensuu.MYunivid +
                                              TEISUU.UNIVSUU] ==
                                          1 ||
                                      kantoku.yobiint1[currentGhensuu.MYunivid +
                                              TEISUU.UNIVSUU * 2] ==
                                          1)
                                    const Text(
                                      "監督・コーチ陣に変更があったようです。大学画面でご確認ください。\n\n\n",
                                      style: TextStyle(color: HENSUU.textcolor),
                                    ),
                                  if (count_riji > 0 &&
                                      currentGhensuu.year % 4 == 0)
                                    const Text(
                                      "箱庭長距離陸上競技連盟の役員の4年に一度の改選が行われました。大学画面下部の「箱庭長距離陸上競技連盟」リンクから確認できます。\n\n\n",
                                      style: TextStyle(color: HENSUU.textcolor),
                                    ),
                                  const Text(
                                    "新入生が入りました！",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "新入生5千m持ちタイムトップ10",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      //fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  for (
                                    int i = 0;
                                    i < 10 &&
                                        i <
                                            nyuugakuji5000timejunSenshuData
                                                .length;
                                    i++
                                  )
                                    if (nyuugakuji5000timejunSenshuData[i]
                                            .gakunen ==
                                        1)
                                      Wrap(
                                        children: [
                                          Text(
                                            _timeToMinuteSecondString(
                                              nyuugakuji5000timejunSenshuData[i]
                                                  .kiroku_nyuugakuji_5000,
                                            ),
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            nyuugakuji5000timejunSenshuData[i]
                                                .name,
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            (nyuugakuji5000timejunSenshuData[i]
                                                        .univid <
                                                    idjununivdata.length)
                                                ? idjununivdata[nyuugakuji5000timejunSenshuData[i]
                                                          .univid]
                                                      .name
                                                : "不明な大学",
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                        ],
                                      ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "${idjununivdata[currentGhensuu.MYunivid].name}大学　新入生",
                                    style: const TextStyle(
                                      color: HENSUU.textcolor,
                                      //fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  for (
                                    int i = 0;
                                    i <
                                        nyuugakuji5000timejununivfilteredsenshudata
                                            .length;
                                    i++
                                  )
                                    if (nyuugakuji5000timejununivfilteredsenshudata[i]
                                            .gakunen ==
                                        1)
                                      Wrap(
                                        children: [
                                          Text(
                                            _timeToMinuteSecondString(
                                              nyuugakuji5000timejununivfilteredsenshudata[i]
                                                  .kiroku_nyuugakuji_5000,
                                            ),
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            nyuugakuji5000timejununivfilteredsenshudata[i]
                                                .name,
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                        ],
                                      ),
                                ] else if (currentGhensuu.mode == 100 &&
                                    currentGhensuu.month == 3 &&
                                    currentGhensuu.day == 25) ...[
                                  const Text(
                                    "今日で4年生が卒業します。\n\n選手画面最下部の「アルバムに追加」リンクから卒業する4年生をアルバムに追加できます。",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold, // ★ 太字に変更
                                    ),
                                  ),
                                ] else if (currentGhensuu.mode == 110 &&
                                    currentGhensuu.month == 10 &&
                                    currentGhensuu.day == 15) ...[
                                  const Text(
                                    "正月駅伝予選が行われます。\nシード権のない20校の各校12名(全員)がハーフマラソン(完全フラットなコース)を走り、各校上位10名の合計タイムで争われます。上位10校が正月に行われる本選へ出場できます。",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const Text(
                                    "\nなお、このレースの記録は個人の記録としては残りません。(レース展開によっては実力以上のタイムが出てしまうことがあり、ハーフマラソンのベスト記録として残してしまうと、選手の実力を見誤る恐れがあるため、やむを得ずそういうことにしました)",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ] else if (currentGhensuu.mode == 110 &&
                                    currentGhensuu.month == 10 &&
                                    currentGhensuu.day == 5) ...[
                                  const Text(
                                    "駅伝シーズンの開幕を告げる10月駅伝が行われます！\nスピード駅伝と呼ばれ、比較的短い距離のコース(初期設定)が中心で、区間数も6区間しかありません。\n",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const Text(
                                    "\nまずは一次エントリーに登録する選手を決定し、その後、一次エントリーに登録した選手で区間エントリーを行い、最後に当日変更を行えます。(現実世界だとそれぞれ期間を空けますが、この世界ではタップ一つで時間が進むものとご想像いただければ幸いです)",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ] else if (currentGhensuu.mode == 110 &&
                                    currentGhensuu.month == 11 &&
                                    currentGhensuu.day == 5) ...[
                                  const Text(
                                    "11月駅伝が行われます！\n総合力が問われる駅伝で、区間数は8区間です。\n",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const Text(
                                    "\nまずは一次エントリーに登録する選手を決定し、その後、一次エントリーに登録した選手で区間エントリーを行い、最後に当日変更を行えます。(現実世界だとそれぞれ期間を空けますが、この世界ではタップ一つで時間が進むものとご想像いただければ幸いです)",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ] else if (currentGhensuu.mode == 110 &&
                                    currentGhensuu.month == 1 &&
                                    currentGhensuu.day == 5) ...[
                                  const Text(
                                    "国民的一大イベントとなった正月駅伝です！\n真の駅伝王者を決める10区間です！\n",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const Text(
                                    "\nまずは一次エントリーに登録する選手を決定し、その後、一次エントリーに登録した選手で区間エントリーを行い、最後に当日変更を行えます。当日変更は1区スタート前と6区のスタート前の2回行えます。(現実世界だとそれぞれ期間を空けますが、この世界ではタップ一つで時間が進むものとご想像いただければ幸いです)",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ] else if (currentGhensuu.mode == 110 &&
                                    currentGhensuu.month == 2 &&
                                    currentGhensuu.day == 25) ...[
                                  const Text(
                                    "あなただけの駅伝大会が開かれます！\n駅伝界に新たな風を吹かせましょう！",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                  const Text(
                                    "\nまずは一次エントリーに登録する選手を決定し、その後、一次エントリーに登録した選手で区間エントリーを行い、最後に当日変更を行えます。(現実世界だとそれぞれ期間を空けますが、この世界ではタップ一つで時間が進むものとご想像いただければ幸いです)",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ] else ...[
                                  const Text(
                                    "今日は特に何もありませんでした",
                                    style: TextStyle(color: HENSUU.textcolor),
                                  ),
                                ],
                              ],
                            ),
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
    );
  }
}
