import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_kukanentry.dart';
import 'package:ekiden/screens/ModalAverageTimeRankingView.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_kukanresult350.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_TodayChangeList.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';
import 'package:ekiden/screens/AllToujitu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_Taichoufuryou.dart';

// --- 当日変更画面ウィジェット ---

class ToujitsuBHenkouScreen extends StatefulWidget {
  const ToujitsuBHenkouScreen({super.key});

  @override
  State<ToujitsuBHenkouScreen> createState() => _ToujitsuBHenkouScreenState();
}

class _ToujitsuBHenkouScreenState extends State<ToujitsuBHenkouScreen> {
  // 初期化データ
  late final Box<Ghensuu> ghensuuBox;
  late final Ghensuu currentGhensuu;
  late final Box<SenshuData> senshudataBox;
  late List<SenshuData> myTeamSenshu;

  // 当日変更用ステート
  late Map<int, int> changeMap;

  // 補欠選手リスト
  late List<SenshuData> hokenSenshu;

  // 区間数
  int kukansuu = 0;
  int koutaikanouninzuu = 0;

  // ✨ 追加: 処理中かどうかを示すフラグ
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Hiveデータのロードと初期化 (変更なし)
  void _initializeData() {
    try {
      ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      senshudataBox = Hive.box<SenshuData>('senshuBox');

      currentGhensuu = ghensuuBox.getAt(0)!;

      if (currentGhensuu == null) {
        myTeamSenshu = [];
        hokenSenshu = [];
        changeMap = {};
        return;
      }

      final int myUnivId = currentGhensuu!.MYunivid;
      final int raceIndex = currentGhensuu!.hyojiracebangou;
      kukansuu = 5;

      List<SenshuData> allSenshu = senshudataBox.values.toList();
      allSenshu.sort((a, b) => a.id.compareTo(b.id));

      myTeamSenshu = allSenshu
          .where(
            (s) =>
                s.univid == myUnivId &&
                (s.entrykukan_race[currentGhensuu!.hyojiracebangou][s.gakunen -
                            1] ==
                        -1 ||
                    (s.entrykukan_race[currentGhensuu!
                                .hyojiracebangou][s.gakunen - 1] >=
                            5 &&
                        s.entrykukan_race[currentGhensuu!
                                .hyojiracebangou][s.gakunen - 1] <=
                            9)),
          )
          .toList();

      int maxkoutaikanouninzuu = 4;

      koutaikanouninzuu = maxkoutaikanouninzuu;

      // 学年降順、ID昇順でソート
      myTeamSenshu.sort((a, b) {
        int gakunenCompare = b.gakunen.compareTo(a.gakunen);
        if (gakunenCompare != 0) {
          return gakunenCompare;
        }
        return a.id.compareTo(b.id);
      });

      List<SenshuData> entrySenshu = [];
      hokenSenshu = [];

      for (var senshu in myTeamSenshu) {
        final int kukan = senshu.entrykukan_race.length > raceIndex
            ? senshu.entrykukan_race[raceIndex][senshu.gakunen - 1]
            : -1;

        if (kukan != -1) {
          entrySenshu.add(senshu);
        } else {
          hokenSenshu.add(senshu);
        }
      }

      entrySenshu.sort((a, b) {
        final int aKukan = a.entrykukan_race[raceIndex][a.gakunen - 1];
        final int bKukan = b.entrykukan_race[raceIndex][b.gakunen - 1];
        return aKukan.compareTo(bKukan);
      });

      myTeamSenshu = entrySenshu;
      changeMap = {for (var senshu in myTeamSenshu) senshu.id: senshu.id};
    } catch (e) {
      myTeamSenshu = [];
      hokenSenshu = [];
      changeMap = {};
      debugPrint('データの初期化中にエラーが発生しました: $e');
    }
  }

  // ドロップダウンリストの変更時の処理 (変更なし)
  void _onDropdownChanged(int entrySenshuId, int? newSenshuId) {
    if (newSenshuId == null) return;

    setState(() {
      changeMap[entrySenshuId] = newSenshuId;
    });
  }

  // 区間内順位を再計算する関数 (変更なし)
  Future<void> _kukannaiJunSaikeisan(
    Ghensuu currentGhensuu,
    List<SenshuData> idJunSenshuData,
  ) async {
    // まずすべての選手の区間内順位をリセット
    for (var senshu in idJunSenshuData) {
      for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
        senshu.kukannaijuni[i] = TEISUU.DEFAULTJUNI;
      }
      await senshu.save(); // SenshuDataの変更を保存
    }

    // 各区間について、エントリーされた選手をフィルタリングし、タイムでソートして順位を付ける
    for (
      int iKukan = 0;
      iKukan <
          currentGhensuu.kukansuu_taikaigoto[currentGhensuu.hyojiracebangou];
      iKukan++
    ) {
      List<SenshuData> entryFilteredSenshuData = idJunSenshuData.where((s) {
        // entrykukan_raceのインデックスアクセスには、gakunen-1 と hyojiracebangou を使う
        return s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                1] ==
            iKukan;
      }).toList();

      for (
        int iKirokubangou = 0;
        iKirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
        iKirokubangou++
      ) {
        List<SenshuData> timeJunSenshuData = entryFilteredSenshuData.toList()
          ..sort(
            (a, b) => a.time_bestkiroku[iKirokubangou].compareTo(
              b.time_bestkiroku[iKirokubangou],
            ),
          );

        for (int iJuni = 0; iJuni < timeJunSenshuData.length; iJuni++) {
          timeJunSenshuData[iJuni].kukannaijuni[iKirokubangou] = iJuni;
          await timeJunSenshuData[iJuni].save(); // SenshuDataの変更を保存
        }
      }
    }
  }

  // 確定ボタンの処理 (ローディング表示ロジックを追加)
  void _confirmChanges() async {
    // 1. ローディング開始
    setState(() {
      _isProcessing = true;
    });

    try {
      if (currentGhensuu == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('データが初期化されていません。')));
        }
        return;
      }

      // 1. 変更人数のチェック
      int changeCount = 0;
      changeMap.forEach((entrySenshuId, newSenshuId) {
        if (entrySenshuId != newSenshuId) {
          changeCount++;
        }
      });

      if (changeCount > koutaikanouninzuu) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('当日変更は最大${koutaikanouninzuu}名までです。変更をやり直してください。'),
            ),
          );
        }
        return;
      }

      // 2. 同じ補欠選手が複数の区間にエントリーされていないかチェック
      final List<int> substitutedSenshuList = changeMap.entries
          .where((e) => e.key != e.value)
          .map((e) => e.value)
          .toList();

      final Set<int> uniqueSubstitutedSenshu = substitutedSenshuList.toSet();

      if (substitutedSenshuList.length > uniqueSubstitutedSenshu.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('同じ補欠選手が複数の区間にエントリーされています。変更をやり直してください。'),
            ),
          );
        }
        return;
      }

      // 確定ダイアログを表示
      String confirmstr = "";
      if (changeCount > 0) {
        confirmstr = '当日変更 ${changeCount}件を本当に確定させてもよろしいですか？\nこの操作は元に戻せません。';
      } else {
        confirmstr = '当日変更なしで確定させてもよろしいですか？\nこの操作は元に戻せません。';
      }

      // ✨ ダイアログ表示前にローディングを一度オフにし、ダイアログを閉じた後に再度オンにする必要はない
      // なぜなら、showDialogはそれ自体がawait可能で、ローディングの必要がないため。
      // ただし、ダイアログ表示後にローディング解除が必要な場合は、`_isProcessing`をここで一時的に`false`に戻す。
      // 今回は、ダイアログの表示・操作中も「処理中」と見なすか、あるいはダイアログ表示前に処理を止めるか、という判断になる。
      // ユーザーの意図を汲み、ダイアログはローディングなしで表示し、ダイアログで「確定」した後の重い処理にのみローディングを適用する設計とする。

      // ローディングを解除し、ダイアログを表示
      setState(() {
        _isProcessing = false;
      });

      final bool confirm =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  '変更の確定',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  confirmstr,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black,
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      '確定',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!confirm) {
        return;
      }

      // 2. ダイアログで確定された後、再度ローディングを開始し、重い処理を行う
      setState(() {
        _isProcessing = true;
      });

      // 2. 変更後のデータの永続化
      if (changeCount > 0) {
        final int myUnivId = currentGhensuu!.MYunivid;
        final int raceIndex = currentGhensuu!.hyojiracebangou;

        List<MapEntry<int, int>> changes = changeMap.entries
            .where((e) => e.key != e.value)
            .toList();

        for (var entry in changes) {
          final int entrySenshuId = entry.key;
          final int newSenshuId = entry.value;

          SenshuData? oldSenshuData = senshudataBox.values.firstWhere(
            (s) => s.id == entrySenshuId,
            orElse: () => throw Exception('変更元選手データが見つかりません: $entrySenshuId'),
          );

          SenshuData? newSenshuData = senshudataBox.values.firstWhere(
            (s) => s.id == newSenshuId,
            orElse: () => throw Exception('交代先選手データが見つかりません: $newSenshuId'),
          );

          final int kukan = oldSenshuData
              .entrykukan_race[raceIndex][oldSenshuData.gakunen - 1];
          if (kukan == -1) {
            continue;
          }

          if (oldSenshuData.univid == myUnivId) {
            oldSenshuData.entrykukan_race[raceIndex][oldSenshuData.gakunen -
                    1] =
                -(100 + kukan);
            await oldSenshuData.save(); // ✨ await をつけて保存
          }

          if (newSenshuData.univid == myUnivId) {
            newSenshuData.entrykukan_race[raceIndex][newSenshuData.gakunen -
                    1] =
                kukan;
            await newSenshuData.save(); // ✨ await をつけて保存
          }
        }
        final senshuDataBox = Hive.box<SenshuData>('senshuBox');
        List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
        sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

        // ✨ await をつけて呼び出す
        await _kukannaiJunSaikeisan(currentGhensuu, sortedSenshuData);
      }

      // 3. 成功メッセージ表示と画面遷移
      if (mounted) {
        currentGhensuu!.mode = 343;
        await currentGhensuu!.save();
        // 成功メッセージは不要の場合、コメントアウトしたままでOK
        /*
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当日変更を確定し、データを保存しました。')));
        */
      }
    } catch (e) {
      debugPrint('データの永続化中にエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データの保存中にエラーが発生しました: $e')));
      }
    } finally {
      // 3. ローディング終了
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 選手詳細モーダルを呼び出す共通関数 (変更なし)
  Widget _buildDetailButton(SenshuData senshu) {
    return TextButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '詳細',
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
        '詳細',
        style: TextStyle(
          color: HENSUU.LinkColor, // リンクカラーを維持
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 選手名表示用の基本テキストスタイル
    final baseTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    );

    // 確定ボタンの固定高さ
    const double bottomButtonHeight = 75.0;

    if (currentGhensuu == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('データがありません', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> idjununivdata = univDataBox.values.toList();
    idjununivdata.sort((a, b) => a.id.compareTo(b.id));
    List<UnivData> timejununivdata = idjununivdata.toList()
      ..sort(
        (a, b) =>
            a.time_taikai_total[currentGhensuu.nowracecalckukan - 1].compareTo(
              b.time_taikai_total[currentGhensuu.nowracecalckukan - 1],
            ),
      );

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
        timesastr += "トップとの差:${formatTimeDifference(time_myuniv - time_top)}\n";
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
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('当日変更画面', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: const [],
      ),
      body: Stack(
        children: [
          // 1. スクロール可能なコンテンツ
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                bottomButtonHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (中略: 既存のコンテンツ)
                  Card(
                    elevation: 2,
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '✅ **当日変更ルール**\n'
                        '1. 変更可能な選手は**最大${koutaikanouninzuu}名**までです。\n'
                        '2. **区間エントリー選手**と**補欠選手**の間でのみ交代が可能です。',
                        style: baseTextStyle?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(rankText),
                  const SizedBox(height: 20),
                  Text(timesastr),
                  const SizedBox(height: 20),

                  const SizedBox(height: 20),

                  if (kantoku.yobiint2[17] == 1 &&
                      (currentGhensuu.hyojiracebangou <= 2 ||
                          currentGhensuu.hyojiracebangou == 5))
                    TextButton(
                      onPressed: () {
                        // ★ここを showGeneralDialog に変更★
                        showGeneralDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(
                            0.8,
                          ), // モーダルの背景色
                          barrierDismissible: true, // 背景タップで閉じられるようにする
                          barrierLabel: '他大学変更', // アクセシビリティ用ラベル
                          transitionDuration: const Duration(
                            milliseconds: 300,
                          ), // アニメーション時間
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                                // ここに表示したいモーダルのウィジェットを指定
                                return AllToujitsuHenkouScreen(
                                  targetGroup: 1,
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
                        "他大学変更",
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
                        barrierLabel: '体調不良者一覧', // アクセシビリティ用ラベル
                        transitionDuration: const Duration(
                          milliseconds: 300,
                        ), // アニメーション時間
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ここに表示したいモーダルのウィジェットを指定
                          return ModalIllnessSenshuListView(); // const を追加
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
                      "体調不良者一覧",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 255, 0),
                        decoration: TextDecoration.underline,
                        decorationColor: HENSUU.textcolor,
                      ),
                    ),
                  ),

                  // エントリー選手一覧ボタン
                  TextButton(
                    onPressed: () {
                      showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.8),
                        barrierDismissible: true,
                        barrierLabel: 'エントリー選手一覧',
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ignore: unnecessary_cast
                          return (const ModalKukanEntryListView()) as Widget;
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
                      "エントリー選手一覧",
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
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.8),
                        barrierDismissible: true,
                        barrierLabel: '持ちタイムランキング',
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ignore: unnecessary_cast
                          return (const ModalAverageTimeRankingView())
                              as Widget;
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
                      "持ちタイムランキング",
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
                            racebangou: currentGhensuu.hyojiracebangou,
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
                  TextButton(
                    onPressed: () {
                      showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                        barrierDismissible: true, // 背景タップで閉じられるようにする
                        barrierLabel: '今季タイム一覧表', // アクセシビリティ用ラベル
                        transitionDuration: const Duration(
                          milliseconds: 300,
                        ), // アニメーション時間
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ここに表示したいモーダルのウィジェットを指定
                          return ModalUnivSenshuMatrixView(
                            targetUnivId: currentGhensuu.MYunivid,
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
                      "今季タイム一覧表",
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
                        barrierLabel: '駅伝出場履歴一覧(選手ごと)', // アクセシビリティ用ラベル
                        transitionDuration: const Duration(
                          milliseconds: 300,
                        ), // アニメーション時間
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ここに表示したいモーダルのウィジェットを指定
                          return ModalEkidenHistoryMatrixView(
                            targetUnivId: currentGhensuu.MYunivid,
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
                      "駅伝出場履歴一覧(選手ごと)",
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
                        barrierLabel: '駅伝出場履歴一覧(区間ごと)', // アクセシビリティ用ラベル
                        transitionDuration: const Duration(
                          milliseconds: 300,
                        ), // アニメーション時間
                        pageBuilder: (context, animation, secondaryAnimation) {
                          // ここに表示したいモーダルのウィジェットを指定
                          return ModalEkidenKukanHistoryMatrixView(
                            targetUnivId: currentGhensuu.MYunivid,
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
                      "駅伝出場履歴一覧(区間ごと)",
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
                            targetUnivid: currentGhensuu.MYunivid,
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
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

                  const SizedBox(height: 20),
                  // --- 区間エントリー選手の表示とドロップダウン ---
                  Text(
                    '🏃 区間エントリー選手',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const Divider(color: Colors.white),
                  ...myTeamSenshu.map((entrySenshu) {
                    final int raceIndex = currentGhensuu!.hyojiracebangou;
                    final int kukan = entrySenshu
                        .entrykukan_race[raceIndex][entrySenshu.gakunen - 1];
                    final String kukanName = kukan == -1
                        ? '補欠'
                        : '${kukan + 1}区';

                    // ドロップダウンの選択肢
                    List<DropdownMenuItem<int>> dropdownItems = [
                      DropdownMenuItem(
                        value: entrySenshu.id,
                        child: const Text(
                          '変更しない',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        enabled: false,
                        child: Divider(height: 1, color: Colors.white),
                      ),
                      ...hokenSenshu.map((hoken) {
                        String displayText;

                        if (hoken.chousi == 0) {
                          // hoken.chousiが0の場合の表示
                          displayText =
                              '【体調不良】${hoken.name} (${hoken.gakunen}年)';
                        } else {
                          // hoken.chousiが0以外の場合の従来の表示
                          displayText =
                              '${hoken.name} (${hoken.gakunen}年) 調子${hoken.chousi}';
                        }

                        return DropdownMenuItem(
                          value: hoken.id,
                          child: Text(
                            displayText,
                            maxLines: 2, // 複数行に対応
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ];

                    int currentValue =
                        changeMap[entrySenshu.id] ?? entrySenshu.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1行目: 区間、氏名、学年、詳細ボタン
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 区間、氏名、学年
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kukanName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                    (entrySenshu.chousi > 0)
                                        ? Text(
                                            '${entrySenshu.name} (${entrySenshu.gakunen}年) 調子${entrySenshu.chousi}',
                                            style: baseTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2, // 複数行に対応
                                          )
                                        : Text(
                                            '【体調不良】${entrySenshu.name} (${entrySenshu.gakunen}年)',
                                            style: baseTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2, // 複数行に対応
                                          ),
                                  ],
                                ),
                              ),
                              // 詳細ボタン
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildDetailButton(entrySenshu),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 2行目: ドロップダウンリスト
                          Row(
                            children: [
                              // ドロップダウン
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: currentValue,
                                      isExpanded: true,
                                      dropdownColor: Colors.black,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      onChanged: _isProcessing
                                          ? null
                                          : (int? newValue) => // ✨ ローディング中は無効化
                                            _onDropdownChanged(
                                              entrySenshu.id,
                                              newValue,
                                            ),
                                      items: dropdownItems,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white),
                  // --- 補欠選手の確認リスト ---
                  Text(
                    '補欠選手一覧 (交代候補)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: hokenSenshu.map((hoken) {
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              Colors.grey.shade900, // ChipのbackgroundColorを再現
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ), // Chipの角丸を再現
                        ),
                        // Chipのpaddingを再現し、TextButtonが独立してタップできるように調整
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 氏名、学年
                            (hoken.chousi > 0)
                                ? Flexible(
                                    child: Text(
                                      '${hoken.name} (${hoken.gakunen}年) 調子${hoken.chousi}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2, // 複数行に対応
                                    ),
                                  )
                                : Flexible(
                                    child: Text(
                                      '【体調不良】${hoken.name} (${hoken.gakunen}年)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2, // 複数行に対応
                                    ),
                                  ),
                            const SizedBox(width: 4),
                            // 詳細ボタン (TextButton)
                            _buildDetailButton(hoken),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 2. 画面下部に固定する確定ボタン
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black, // ボタン領域の背景色を黒に
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity, // 幅を最大にする
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : _confirmChanges, // ✨ ローディング中は無効化
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? Colors.grey
                          : Colors.blue, // ✨ ローディング中は色をグレーに
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: Text(
                      '確定して進む',
                      style: TextStyle(
                        fontSize: baseTextStyle?.fontSize ?? 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✨ 追加: ローディングオーバーレイ
          if (_isProcessing)
            ModalBarrier(
              color: Colors.black.withOpacity(0.5), // 暗い背景
              dismissible: false, // タップで閉じられないようにする
            ),
          if (_isProcessing)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white), // 白い渦巻き
                  SizedBox(height: 16),
                  Text(
                    'お待ちください...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
