import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/kantoku_data.dart'; //
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート (DEFAULTTIME, DEFAULTJUNIなど)
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/qr_r_modal.dart';
//import 'package:ekiden/qr_scanner_screen.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/riji_data.dart';

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  //final int milliseconds = ((time % 1) * 100)
  //    .toInt(); // 秒以下の部分をミリ秒として扱う (小数点2桁まで)
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

//---------------------------------------------------------

class Senshu_R_Screen extends StatefulWidget {
  const Senshu_R_Screen({super.key});

  @override
  State<Senshu_R_Screen> createState() => _Senshu_R_ScreenState();
}

class _Senshu_R_ScreenState extends State<Senshu_R_Screen> {
  // Ghensuu BoxとUnivData Boxは現役画面と共通で使用
  late Box<Ghensuu> _ghensuuBox;
  late Box<UnivData> _univBox;

  // 卒業選手専用のBox
  late Box<Senshu_R_Data> _retiredSenshuBox;
  late Box<Album> _albumBox;

  // ★追加: 検索機能用の状態
  final TextEditingController _searchController = TextEditingController();
  List<int> _searchResults =
      []; // 検索にマッチした選手のインデックス (myAlbumSenshuList内のインデックス)
  int _currentSearchResultIndex =
      -1; // 現在表示している検索結果のインデックス (_searchResults内のインデックス)

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _univBox = Hive.box<UnivData>('univBox');
    // 卒業選手用のBoxを開く
    _retiredSenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
    _albumBox = Hive.box<Album>('albumBox');
  }

  @override
  void dispose() {
    _searchController.dispose(); // ★追加: コントローラーを破棄
    super.dispose();
  }

  // ★追加: 検索を実行し、結果を_searchResultsに保存する関数
  void _performSearch(String query) async {
    // 検索語が空の場合はリセット
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchResultIndex = -1;
      });
      return;
    }

    // 最新の選手リストを取得するロジック (_changeSenshu や build内のロジックを流用)
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final Album? album = _albumBox.get('AlbumData');
    if (album == null) return;

    List<Senshu_R_Data> myAlbumSenshuList;
    if (album.yobiint3 != 0) {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where((senshu) => senshu.id == album.yobiint3)
          .toList();
    } else {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where(
            (senshu) =>
                senshu.univid == ghensuu.MYunivid &&
                senshu.sijiseikouflag == 100,
          )
          .toList();
    }

    // sijiflag（卒業年）降順、name昇順でソート (ロジックを統一)
    myAlbumSenshuList.sort((a, b) {
      int yearCompare = b.sijiflag.compareTo(a.sijiflag);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return a.name.compareTo(b.name);
    });

    // 検索処理 (部分一致, 大文字・小文字を区別しない)
    final List<int> results = [];
    final String lowerCaseQuery = query.toLowerCase();

    for (int i = 0; i < myAlbumSenshuList.length; i++) {
      if (myAlbumSenshuList[i].name.toLowerCase().contains(lowerCaseQuery)) {
        results.add(i);
      }
    }

    if (results.isEmpty) {
      // 検索結果がない場合
      setState(() {
        _searchResults = [];
        _currentSearchResultIndex = -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('該当する選手はいませんでした。')));
      }
      return;
    }

    // 検索結果を更新し、最初の結果にジャンプ
    setState(() {
      _searchResults = results;
      _currentSearchResultIndex = 0;
    });

    album.hyojisenshunum = results.first;
    await album.save();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${results.length}件見つかりました。')));
    }
  }

  // ★追加: 検索結果内を移動する関数
  void _navigateSearchResults(int delta) async {
    if (_searchResults.isEmpty) return;

    final Album? album = _albumBox.get('AlbumData');
    if (album == null) return;

    int newIndex = _currentSearchResultIndex + delta;

    if (newIndex < 0) {
      newIndex = _searchResults.length - 1; // 循環
    } else if (newIndex >= _searchResults.length) {
      newIndex = 0; // 循環
    }

    final int targetSenshuIndex = _searchResults[newIndex];

    setState(() {
      _currentSearchResultIndex = newIndex;
    });

    album.hyojisenshunum = targetSenshuIndex;
    await album.save();
  }

  // 新規追加: 指定された卒業年（sijiflag）に該当する最初の選手のインデックスにジャンプする
  void _jumpToGraduationYear(int targetYear) async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final Album? album = _albumBox.get('AlbumData');
    if (album == null) return;

    List<Senshu_R_Data> myAlbumSenshuList;
    // Boxからデータを読み込む (ValueListenableBuilder内のロジックと一致させる)
    if (album.yobiint3 != 0) {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where((senshu) => senshu.id == album.yobiint3)
          .toList();
    } else {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where(
            (senshu) =>
                senshu.univid == ghensuu.MYunivid &&
                senshu.sijiseikouflag == 100,
          )
          .toList();
    }

    // sijiflag（卒業年）降順、name昇順でソート (ロジックを統一)
    myAlbumSenshuList.sort((a, b) {
      int yearCompare = b.sijiflag.compareTo(a.sijiflag);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return a.name.compareTo(b.name);
    });

    if (myAlbumSenshuList.isEmpty) return;

    // targetYear (卒業年) を持つ最初の選手を探す
    int targetIndex = myAlbumSenshuList.indexWhere(
      (senshu) => senshu.sijiflag == targetYear,
    );

    String snackBarMessage;

    if (targetIndex == -1) {
      // 該当する卒業年がない場合、最も近い卒業年を見つける

      // 既存の卒業年リストを取得
      final List<int> distinctYears = myAlbumSenshuList
          .map((senshu) => senshu.sijiflag)
          .where((year) => year != 0)
          .toSet()
          .toList();

      if (distinctYears.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ジャンプできる卒業年データがありません。'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      int minDiff = 9999;
      int closestYear = distinctYears.first; // 初期値として任意の年を設定

      for (final year in distinctYears) {
        final int diff = (year - targetYear).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestYear = year;
        } else if (diff == minDiff) {
          // 差が同じ場合、より新しい年（sijiflagが大きい方）を優先する
          if (year > closestYear) {
            closestYear = year;
          }
        }
      }

      // 最も近い年が見つかったら、その年に該当する最初の選手のインデックスを探す
      targetIndex = myAlbumSenshuList.indexWhere(
        (senshu) => senshu.sijiflag == closestYear,
      );

      snackBarMessage =
          '$targetYear年卒業の選手は見つかりませんでした。\n最も近い${closestYear}年卒業の選手にジャンプします。';
    } else {
      // 該当する卒業年が見つかった場合
      snackBarMessage = '$targetYear年卒業の選手にジャンプしました。';
    }

    if (targetIndex != -1) {
      // インデックスを更新して保存
      album.hyojisenshunum = targetIndex;
      await album.save();
    }

    // SnackBarを表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 新規追加: 卒業年を選択するダイアログを表示する
  void _showGraduationYearJumpDialog(BuildContext context) {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final List<int> distinctYears = _retiredSenshuBox.values
        .where(
          (senshu) =>
              senshu.sijiseikouflag == 100 && senshu.univid == ghensuu.MYunivid,
        ) // ★この行を追加
        .map((senshu) => senshu.sijiflag)
        .where((year) => year != 0)
        .toSet()
        .toList();

    // 卒業年を降順でソート
    distinctYears.sort((a, b) => b.compareTo(a));

    if (distinctYears.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ジャンプできる卒業年データがありません。')));
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('卒業年でジャンプ'),
          content: SingleChildScrollView(
            child: ListBody(
              children: distinctYears.map((year) {
                return ListTile(
                  title: Text('$year年卒業'),
                  onTap: () {
                    Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                    _jumpToGraduationYear(year); // ジャンプ実行
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 表示する選手を更新する関数 (卒業選手用)
  void _changeSenshu(int delta) async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    // Boxからデータを読み込む
    final Album? album = _albumBox.get('AlbumData');
    if (album == null) {
      print('AlbumDataデータが見つかりません');
      return;
    }
    List<Senshu_R_Data> myAlbumSenshuList;
    // 卒業選手リストを取得
    if (album.yobiint3 != 0) {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where((senshu) => senshu.id == album.yobiint3)
          .toList();
    } else {
      myAlbumSenshuList = _retiredSenshuBox.values
          .where(
            (senshu) =>
                senshu.univid == ghensuu.MYunivid &&
                senshu.sijiseikouflag == 100,
          )
          .toList();
    }

    // sijiflag（卒業年）降順、name昇順でソート
    myAlbumSenshuList.sort((a, b) {
      // 卒業年（sijiflag）降順
      int yearCompare = b.sijiflag.compareTo(a.sijiflag);
      if (yearCompare != 0) {
        return yearCompare;
      }
      // 同一卒業年の場合は名前昇順
      return a.name.compareTo(b.name);
    });
    if (myAlbumSenshuList.isEmpty) {
      // 該当する選手がいない場合は何もしない
      return;
    }
    int newSenshuNum = album!.hyojisenshunum + delta;
    if (newSenshuNum < 0) {
      newSenshuNum = myAlbumSenshuList.length - 1;
    } else if (newSenshuNum >= myAlbumSenshuList.length) {
      newSenshuNum = 0;
    }
    album.hyojisenshunum = newSenshuNum;
    await album.save(); // Hiveに保存
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Album>>(
      valueListenable: _albumBox.listenable(),
      builder: (context, albumBox, _) {
        final Album? album = albumBox.get('AlbumData');
        if (album == null) {
          print('AlbumDataデータが見つかりません');
          return Scaffold(
            // ★ データを表示できない場合もScaffoldを返す
            appBar: AppBar(
              title: const Text('アルバム'),
              backgroundColor: Colors.grey[900],
            ),
            backgroundColor: HENSUU.backgroundcolor,
            body: Center(
              child: Text(
                'アルバムにデータがありません。(アルバムのデータ)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),
          );
        }
        final int currentSenshuNum = album.hyojisenshunum; // 現在表示する選手の番号
        List<UnivData> sortedUnivData = _univBox.values.toList();
        sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
        final Ghensuu ghensuu = _ghensuuBox.get(
          'global_ghensuu',
          defaultValue: Ghensuu.initial(),
        )!;
        return ValueListenableBuilder<Box<Senshu_R_Data>>(
          valueListenable: _retiredSenshuBox.listenable(),
          builder: (context, retiredSenshuBox, _) {
            // Boxからデータを読み込む
            final Album album = _albumBox.get('AlbumData')!;
            List<Senshu_R_Data> myAlbumSenshuList;
            // 卒業選手リストを取得
            if (album.yobiint3 != 0) {
              myAlbumSenshuList = retiredSenshuBox.values
                  .where((senshu) => senshu.id == album.yobiint3)
                  .toList();
            } else {
              myAlbumSenshuList = retiredSenshuBox.values
                  .where(
                    (senshu) =>
                        senshu.univid == ghensuu.MYunivid &&
                        senshu.sijiseikouflag == 100,
                  )
                  .toList();
            }

            // sijiflag（卒業年）降順、name昇順でソート (ChangeSenshuと同じロジックを再実行)
            myAlbumSenshuList.sort((a, b) {
              int yearCompare = b.sijiflag.compareTo(a.sijiflag);
              if (yearCompare != 0) {
                return yearCompare;
              }
              return a.name.compareTo(b.name);
            });

            // 選手がいなければメッセージを表示
            if (myAlbumSenshuList.isEmpty) {
              return Scaffold(
                // ★ データを表示できない場合もScaffoldを返す
                appBar: AppBar(
                  title: const Text('アルバム'),
                  backgroundColor: Colors.grey[900],
                ),
                backgroundColor: HENSUU.backgroundcolor,
                body: Center(
                  child: Text(
                    'アルバムにデータがありません。(選手のデータ)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                  ),
                ),
              );
            }

            // hyojisenshunumがリストの範囲外になった場合を考慮
            Senshu_R_Data currentSenshu;
            if (currentSenshuNum >= 0 &&
                currentSenshuNum < myAlbumSenshuList.length) {
              currentSenshu = myAlbumSenshuList[currentSenshuNum];
            } else {
              // 範囲外の場合は最初の選手を表示し、hyojisenshunumを0にリセット
              currentSenshu = myAlbumSenshuList[0];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (album.hyojisenshunum != 0) {
                  album.hyojisenshunum = 0;
                  //album.save(); // 現役画面でのリセットと異なり、ここでは保存処理は不要または別の制御が必要
                }
              });
            }
            String yakushokustr = "";
            final rijiBox = Hive.box<RijiData>('rijiBox');
            final RijiData riji = rijiBox.get('RijiData')!;
            for (int i_riji = 0; i_riji < 10; i_riji++) {
              if (riji.rid_riji[i_riji] == currentSenshu.id) {
                yakushokustr = "【陸連】${riji.meishou[i_riji]}\n";
                break;
              }
            }
            final kantokuBox = Hive.box<KantokuData>('kantokuBox');
            // Boxからデータを読み込む
            final KantokuData kantoku = kantokuBox.get('KantokuData')!;
            for (
              int i_kantoku = 0;
              i_kantoku < TEISUU.UNIVSUU * 3;
              i_kantoku++
            ) {
              if (kantoku.rid[i_kantoku] == currentSenshu.id) {
                if (i_kantoku < TEISUU.UNIVSUU) {
                  yakushokustr +=
                      "${sortedUnivData[currentSenshu.univid].name}大学監督\n";
                } else if (i_kantoku < TEISUU.UNIVSUU * 2) {
                  yakushokustr +=
                      "${sortedUnivData[currentSenshu.univid].name}大学コーチ(トラック)\n";
                } else {
                  yakushokustr +=
                      "${sortedUnivData[currentSenshu.univid].name}大学コーチ(長距離)\n";
                }
                break;
              }
            }

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
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.grey[900],
                centerTitle: false,
                titleSpacing: 0.0,
                toolbarHeight: HENSUU.appbar_height,
                title: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1行目に卒業選手表示であることを示すテキスト
                      if (album.yobiint3 == 0)
                        const Text(
                          '卒業選手アルバム',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          '現役時成績',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      // 2行目に現在の表示選手数
                      if (album.yobiint3 == 0)
                        GestureDetector(
                          // ★ GestureDetectorでラップ
                          onTap: () => _showGraduationYearJumpDialog(
                            context,
                          ), // ★ タップでダイアログ表示
                          child: Text(
                            '${currentSenshuNum + 1} / ${myAlbumSenshuList.length} 人 (卒業年Jump)', // ★ 表示を修正
                            style: const TextStyle(color: HENSUU.LinkColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              body: Column(
                children: [
                  // ★★★ 検索機能の追加部分 ★★★
                  if (album.yobiint3 == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: '選手名で検索',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    hintText: '例: 山田',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        _performSearch(_searchController.text);
                                      },
                                    ),
                                  ),
                                  onSubmitted: _performSearch, // エンターキーで検索実行
                                ),
                              ),
                            ],
                          ),
                          if (_searchResults.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _navigateSearchResults(-1),
                                      child: const Text('前検索'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_currentSearchResultIndex + 1} / ${_searchResults.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: HENSUU.fontsize_honbun,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _navigateSearchResults(1),
                                      child: const Text('次検索'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // ★★★ 検索機能の追加部分ここまで ★★★
                  const SizedBox(height: 8),
                  // 大学名と選手名
                  Text(
                    '${sortedUnivData[currentSenshu.univid].name}大学卒業',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ★ 卒業年（sijiflag）を表示
                      if (ghensuu.year - currentSenshu.sijiflag + 22 >= 100)
                        Expanded(
                          // ⬅️ ここでExpandedを追加
                          child: Text(
                            '${currentSenshu.name} (卒業: ${currentSenshu.sijiflag}年3月) ${ghensuu.year - currentSenshu.sijiflag + 22}歳(存命なら)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Expanded(
                          // ⬅️ ここでExpandedを追加
                          child: Text(
                            '${currentSenshu.name} (卒業: ${currentSenshu.sijiflag}年3月) ${ghensuu.year - currentSenshu.sijiflag + 22}歳',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  //const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        // ⬅️ ここでExpandedを追加
                        child: Text(
                          yakushokustr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  //const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        // ******* ここから下のListView内のコンテンツはSenshuScreenのものをそのまま使用 *******
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
                        // ... (現役画面の _buildBestRecordRow などの呼び出しをそのままコピー) ...
                        _buildBestRecordRowr(
                          '5千best',
                          currentSenshu.time_bestkiroku[0],
                          currentSenshu.gakunaijuni_bestkiroku[0],
                          currentSenshu.zentaijuni_bestkiroku[0],
                        ),
                        _buildBestRecordRowr(
                          '1万best',
                          currentSenshu.time_bestkiroku[1],
                          currentSenshu.gakunaijuni_bestkiroku[1],
                          currentSenshu.zentaijuni_bestkiroku[1],
                        ),
                        _buildBestRecordRowr(
                          'ハーフbest',
                          currentSenshu.time_bestkiroku[2],
                          currentSenshu.gakunaijuni_bestkiroku[2],
                          currentSenshu.zentaijuni_bestkiroku[2],
                        ),
                        _buildBestRecordRow_fullr(
                          'フルbest',
                          currentSenshu.time_bestkiroku[3],
                          currentSenshu.gakunaijuni_bestkiroku[3],
                          currentSenshu.zentaijuni_bestkiroku[3],
                        ),
                        _buildBestRecordRowr(
                          '登り1万best',
                          currentSenshu.time_bestkiroku[4],
                          currentSenshu.gakunaijuni_bestkiroku[4],
                          null,
                        ),
                        _buildBestRecordRowr(
                          '下り1万best',
                          currentSenshu.time_bestkiroku[5],
                          currentSenshu.gakunaijuni_bestkiroku[5],
                          null,
                        ),
                        _buildBestRecordRowr(
                          'ロード1万best',
                          currentSenshu.time_bestkiroku[6],
                          currentSenshu.gakunaijuni_bestkiroku[6],
                          null,
                        ),
                        _buildBestRecordRowr(
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
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 各種能力値
                        if (kantoku.yobiint2[17] == 1)
                          _buildAbilityRowr('基本走力', 1, aInt + 300),
                        if (kantoku.yobiint2[17] == 1)
                          _buildAbilityRowr(
                            '素質',
                            1,
                            currentSenshu.sositu - 1500,
                          ),
                        // 卒業選手は全ての能力値が見えるものとして、flagは全て1を使用します
                        _buildAbilityRowr('安定感', 1, currentSenshu.anteikan),
                        _buildAbilityRowr('駅伝男', 1, currentSenshu.konjou),
                        _buildAbilityRowr('平常心', 1, currentSenshu.heijousin),
                        _buildAbilityRowr(
                          '長距離粘り',
                          1,
                          currentSenshu.choukyorinebari,
                        ),
                        _buildAbilityRowr('スパート力', 1, currentSenshu.spurtryoku),
                        _buildAbilityRowr('カリスマ', 1, currentSenshu.karisuma),
                        _buildAbilityRowr(
                          '登り適性',
                          1,
                          currentSenshu.noboritekisei,
                        ),
                        _buildAbilityRowr(
                          '下り適性',
                          1,
                          currentSenshu.kudaritekisei,
                        ),
                        _buildAbilityRowr(
                          'アップダウン対応力',
                          1,
                          currentSenshu.noborikudarikirikaenouryoku,
                        ),
                        _buildAbilityRowr('ロード適性', 1, currentSenshu.tandokusou),
                        _buildAbilityRowr(
                          'ペース変動対応力',
                          1,
                          currentSenshu.paceagesagetaiouryoku,
                        ),
                        _buildAbilityRowr(
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
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 駅伝・対校戦成績 (学年ループ)
                        // 卒業時は4年分のデータが残っているため、固定で4年分を表示するのが妥当
                        ...List.generate(4, (gakunenIndex) {
                          // 卒業選手は4年で固定
                          // ただし、gakunenIndexが現在の選手のデータ範囲内であることを確認（念のため）
                          // Senshu_R_Dataは全データを持っているはずなので、ここでは4年固定とします。
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${gakunenIndex + 1}年時成績',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              // ... (現役画面の _buildRaceRecordRowWithKumi などの呼び出しをそのままコピー) ...
                              _buildRaceRecordRowr(
                                '対校戦5千',
                                currentSenshu.kukanjuni_race[6][gakunenIndex],
                                currentSenshu.kukantime_race[6][gakunenIndex],
                              ),
                              _buildRaceRecordRowr(
                                '対校戦1万',
                                currentSenshu.kukanjuni_race[7][gakunenIndex],
                                currentSenshu.kukantime_race[7][gakunenIndex],
                              ),
                              _buildRaceRecordRowr(
                                '対校戦ハーフ',
                                currentSenshu.kukanjuni_race[8][gakunenIndex],
                                currentSenshu.kukantime_race[8][gakunenIndex],
                              ),
                              _buildRaceRecordRowWithKumir(
                                '11月駅伝予選',
                                currentSenshu.entrykukan_race[3][gakunenIndex],
                                currentSenshu.kukanjuni_race[3][gakunenIndex],
                                currentSenshu.kukantime_race[3][gakunenIndex],
                                3,
                              ),
                              _buildRaceRecordRowWithKumir(
                                '10月駅伝',
                                currentSenshu.entrykukan_race[0][gakunenIndex],
                                currentSenshu.kukanjuni_race[0][gakunenIndex],
                                currentSenshu.kukantime_race[0][gakunenIndex],
                                0,
                              ),
                              _buildRaceRecordRowr(
                                '正月駅伝予選',
                                currentSenshu.kukanjuni_race[4][gakunenIndex],
                                currentSenshu.kukantime_race[4][gakunenIndex],
                              ),
                              _buildRaceRecordRowWithKumir(
                                '11月駅伝',
                                currentSenshu.entrykukan_race[1][gakunenIndex],
                                currentSenshu.kukanjuni_race[1][gakunenIndex],
                                currentSenshu.kukantime_race[1][gakunenIndex],
                                1,
                              ),

                              _buildRaceRecordRowWithKumir(
                                '正月駅伝',
                                currentSenshu.entrykukan_race[2][gakunenIndex],
                                currentSenshu.kukanjuni_race[2][gakunenIndex],
                                currentSenshu.kukantime_race[2][gakunenIndex],
                                2,
                              ),

                              _buildRaceRecordRowWithKumir(
                                sortedUnivData[0]?.name_tanshuku ??
                                    'カスタム駅伝', // 大学名を取得できなかった場合は代替テキスト
                                currentSenshu.entrykukan_race[5][gakunenIndex],
                                currentSenshu.kukanjuni_race[5][gakunenIndex],
                                currentSenshu.kukantime_race[5][gakunenIndex],
                                2,
                              ),

                              _buildRaceRecordRowr(
                                '秋記録会5千',
                                currentSenshu.kukanjuni_race[10][gakunenIndex],
                                currentSenshu.kukantime_race[10][gakunenIndex],
                              ),
                              _buildRaceRecordRowr(
                                '秋記録会1万',
                                currentSenshu.kukanjuni_race[11][gakunenIndex],
                                currentSenshu.kukantime_race[11][gakunenIndex],
                              ),
                              _buildRaceRecordRowr(
                                '秋市民ハーフ',
                                currentSenshu.kukanjuni_race[12][gakunenIndex],
                                currentSenshu.kukantime_race[12][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunair(
                                '登り10km',
                                currentSenshu.kukanjuni_race[13][gakunenIndex],
                                currentSenshu.kukantime_race[13][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunair(
                                '下り10km',
                                currentSenshu.kukanjuni_race[14][gakunenIndex],
                                currentSenshu.kukantime_race[14][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunair(
                                'ロード10km',
                                currentSenshu.kukanjuni_race[15][gakunenIndex],
                                currentSenshu.kukantime_race[15][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunair(
                                'クロカン10km',
                                currentSenshu.kukanjuni_race[16][gakunenIndex],
                                currentSenshu.kukantime_race[16][gakunenIndex],
                              ),

                              _buildRaceRecordRow_fullr(
                                'フルマラソン',
                                currentSenshu.kukanjuni_race[17][gakunenIndex],
                                currentSenshu.kukantime_race[17][gakunenIndex],
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        // ******* ListView内のコンテンツ終わり *******
                        const Divider(color: Colors.white54),
                        const SizedBox(height: 16),
                        if (currentSenshu.string_racesetumei != "")
                          Text(
                            '【監督・コーチ就任退任履歴】\n${currentSenshu.string_racesetumei}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          )
                        else
                          Text(
                            '【監督・コーチ就任退任履歴】\nなし',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white54),
                        // LinkButtonsはアルバム画面では不要かと思われますが、
                        // もし必要なら現役画面と同様に、ヘルパー関数を含めて移植してください。
                        // LinkButtons(context, ghensuu),
                        TextButton(
                          onPressed: () async {
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
                                    return Qr_R_Modal(
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
                        const SizedBox(height: 40),
                        if (currentSenshu.sijiseikouflag != 100 &&
                            currentSenshu.univid == ghensuu.MYunivid)
                          TextButton(
                            onPressed: () async {
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('アルバムへの追加確認'),
                                    content: Text(
                                      '本当に ${currentSenshu.name} をアルバムに追加しますか？',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          context,
                                        ).pop(false), // キャンセル: falseを返す
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          context,
                                        ).pop(true), // はい: trueを返す
                                        child: const Text('はい、追加します'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              //
                              if (confirmed == true) {
                                currentSenshu.sijiseikouflag = 100;
                                await currentSenshu.save();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${currentSenshu.name} をアルバムに追加しました',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "この人物をアルバムに追加",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 255, 0),
                                decoration: TextDecoration.underline,
                                decorationColor: HENSUU.textcolor,
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                        if (currentSenshu.univid == ghensuu.MYunivid)
                          TextButton(
                            // 🔽 onPressedの中に関数呼び出しとif文を記述します 🔽
                            onPressed: () {
                              String yakushoku_str = "";
                              int kantokuid = 0;
                              bool okflag = true;
                              // Hive.box() を使って、既に開いているBoxを取得
                              final kantokuBox = Hive.box<KantokuData>(
                                'kantokuBox',
                              );
                              // Boxからデータを読み込む
                              final KantokuData kantoku = kantokuBox.get(
                                'KantokuData',
                              )!;
                              for (int i = 0; i < TEISUU.UNIVSUU; i++) {
                                if (currentSenshu.id == kantoku.rid[i]) {
                                  okflag = false;

                                  yakushoku_str = "監督";

                                  break;
                                }
                              }
                              // 1. まず条件をチェック
                              if (okflag) {
                                kantokuid = currentSenshu.univid;
                                // 2. 条件が成就している（true）の場合のみ、ダイアログを表示
                                _showshuuninConfirmationDialog(
                                  context,
                                  currentSenshu,
                                  kantokuid,
                                );
                              } else {
                                // 3. 条件が成就していない場合の処理（オプション）：
                                //    例えば、削除できない理由をユーザーに伝えるSnackBarを表示するなど
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'この人物は、現在、すでに${yakushoku_str}をしています。',
                                    ),
                                  ),
                                );
                              }
                            },
                            // スタイルや子ウィジェットは変更なし
                            style: TextButton.styleFrom(
                              foregroundColor: HENSUU.LinkColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flag,
                                  size: HENSUU.fontsize_honbun + 2,
                                ),
                                const SizedBox(width: 8),
                                // 修正: TextウィジェットをExpandedでラップし、残りの幅をすべて与える
                                Expanded(
                                  child: const Text(
                                    'この人物が監督に就任するよう進言',
                                    textAlign: TextAlign.center, // ★ 中央寄せ
                                    softWrap:
                                        true, // ★ 折り返しを有効にする（デフォルトで有効なことが多いですが明示的に）
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: HENSUU.fontsize_honbun,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (currentSenshu.univid == ghensuu.MYunivid)
                          TextButton(
                            // 🔽 onPressedの中に関数呼び出しとif文を記述します 🔽
                            onPressed: () {
                              String yakushoku_str = "";
                              int kantokuid = 0;
                              bool okflag = true;
                              // Hive.box() を使って、既に開いているBoxを取得
                              final kantokuBox = Hive.box<KantokuData>(
                                'kantokuBox',
                              );
                              // Boxからデータを読み込む
                              final KantokuData kantoku = kantokuBox.get(
                                'KantokuData',
                              )!;
                              for (
                                int i = TEISUU.UNIVSUU;
                                i < TEISUU.UNIVSUU * 2;
                                i++
                              ) {
                                if (currentSenshu.id == kantoku.rid[i]) {
                                  okflag = false;

                                  yakushoku_str = "コーチ(トラック)";

                                  break;
                                }
                              }
                              // 1. まず条件をチェック
                              if (okflag) {
                                kantokuid =
                                    currentSenshu.univid + TEISUU.UNIVSUU;
                                // 2. 条件が成就している（true）の場合のみ、ダイアログを表示
                                _showshuuninConfirmationDialog(
                                  context,
                                  currentSenshu,
                                  kantokuid,
                                );
                              } else {
                                // 3. 条件が成就していない場合の処理（オプション）：
                                //    例えば、削除できない理由をユーザーに伝えるSnackBarを表示するなど
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'この人物は、現在、すでに${yakushoku_str}をしています。',
                                    ),
                                  ),
                                );
                              }
                            },
                            // スタイルや子ウィジェットは変更なし
                            style: TextButton.styleFrom(
                              foregroundColor: HENSUU.LinkColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.campaign,
                                  size: HENSUU.fontsize_honbun + 2,
                                ),
                                const SizedBox(width: 8),
                                // 修正: TextウィジェットをExpandedでラップし、残りの幅をすべて与える
                                Expanded(
                                  child: const Text(
                                    'この人物がコーチ(トラック)に就任するよう進言',
                                    textAlign: TextAlign.center, // ★ 中央寄せ
                                    softWrap:
                                        true, // ★ 折り返しを有効にする（デフォルトで有効なことが多いですが明示的に）
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: HENSUU.fontsize_honbun,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (currentSenshu.univid == ghensuu.MYunivid)
                          TextButton(
                            // 🔽 onPressedの中に関数呼び出しとif文を記述します 🔽
                            onPressed: () {
                              String yakushoku_str = "";
                              int kantokuid = 0;
                              bool okflag = true;
                              // Hive.box() を使って、既に開いているBoxを取得
                              final kantokuBox = Hive.box<KantokuData>(
                                'kantokuBox',
                              );
                              // Boxからデータを読み込む
                              final KantokuData kantoku = kantokuBox.get(
                                'KantokuData',
                              )!;
                              for (
                                int i = TEISUU.UNIVSUU * 2;
                                i < TEISUU.UNIVSUU * 3;
                                i++
                              ) {
                                if (currentSenshu.id == kantoku.rid[i]) {
                                  okflag = false;

                                  yakushoku_str = "監督(長距離)";

                                  break;
                                }
                              }
                              // 1. まず条件をチェック
                              if (okflag) {
                                kantokuid =
                                    currentSenshu.univid + TEISUU.UNIVSUU * 2;
                                // 2. 条件が成就している（true）の場合のみ、ダイアログを表示
                                _showshuuninConfirmationDialog(
                                  context,
                                  currentSenshu,
                                  kantokuid,
                                );
                              } else {
                                // 3. 条件が成就していない場合の処理（オプション）：
                                //    例えば、削除できない理由をユーザーに伝えるSnackBarを表示するなど
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'この人物は、現在、すでに${yakushoku_str}をしています。',
                                    ),
                                  ),
                                );
                              }
                            },
                            // スタイルや子ウィジェットは変更なし
                            style: TextButton.styleFrom(
                              foregroundColor: HENSUU.LinkColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.campaign,
                                  size: HENSUU.fontsize_honbun + 2,
                                ),
                                const SizedBox(width: 8),
                                // 修正: TextウィジェットをExpandedでラップし、残りの幅をすべて与える
                                Expanded(
                                  child: const Text(
                                    'この人物がコーチ(長距離)に就任するよう進言',
                                    textAlign: TextAlign.center, // ★ 中央寄せ
                                    softWrap:
                                        true, // ★ 折り返しを有効にする（デフォルトで有効なことが多いですが明示的に）
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: HENSUU.fontsize_honbun,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                        if (currentSenshu.univid == ghensuu.MYunivid)
                          TextButton(
                            // 🔽 onPressedの中に関数呼び出しとif文を記述します 🔽
                            onPressed: () {
                              int kantokuid = 0;
                              bool okflag = false;
                              // Hive.box() を使って、既に開いているBoxを取得
                              final kantokuBox = Hive.box<KantokuData>(
                                'kantokuBox',
                              );
                              // Boxからデータを読み込む
                              final KantokuData kantoku = kantokuBox.get(
                                'KantokuData',
                              )!;
                              for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
                                if (currentSenshu.id == kantoku.rid[i]) {
                                  okflag = true;
                                  kantokuid = i;
                                  break;
                                }
                              }
                              // 1. まず条件をチェック
                              if (okflag) {
                                // 2. 条件が成就している（true）の場合のみ、ダイアログを表示
                                _showDeleteConfirmationDialog_kantokukainin(
                                  context,
                                  currentSenshu,
                                  kantokuid,
                                );
                              } else {
                                // 3. 条件が成就していない場合の処理（オプション）：
                                //    例えば、削除できない理由をユーザーに伝えるSnackBarを表示するなど
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('この人物は、現在、監督やコーチをしていません。'),
                                  ),
                                );
                              }
                            },
                            // スタイルや子ウィジェットは変更なし
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.clear,
                                  size: HENSUU.fontsize_honbun + 2,
                                ),
                                //const SizedBox(width: 8),
                                // 修正: TextウィジェットをExpandedでラップし、残りの幅をすべて与える
                                Expanded(
                                  child: const Text(
                                    'この人物が監督・コーチから退任するよう進言',
                                    textAlign: TextAlign.center, // ★ 中央寄せ
                                    softWrap:
                                        true, // ★ 折り返しを有効にする（デフォルトで有効なことが多いですが明示的に）
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: HENSUU.fontsize_honbun,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                        // ★ 選手削除ボタンを控えめなTextButtonに変更
                        if (album.yobiint3 == 0)
                          TextButton(
                            // 🔽 onPressedの中に関数呼び出しとif文を記述します 🔽
                            onPressed: () {
                              bool okflag = true;
                              // Hive.box() を使って、既に開いているBoxを取得
                              final kantokuBox = Hive.box<KantokuData>(
                                'kantokuBox',
                              );
                              // Boxからデータを読み込む
                              final KantokuData kantoku = kantokuBox.get(
                                'KantokuData',
                              )!;
                              for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
                                if (currentSenshu.id == kantoku.rid[i]) {
                                  okflag = false;
                                  break;
                                }
                              }
                              final rijiBox = Hive.box<RijiData>('rijiBox');
                              final RijiData riji = rijiBox.get('RijiData')!;
                              for (int i = 0; i < 10; i++) {
                                if (currentSenshu.id == riji.rid_riji[i]) {
                                  okflag = false;
                                  break;
                                }
                              }
                              // 1. まず条件をチェック
                              if (okflag) {
                                // 2. 条件が成就している（true）の場合のみ、ダイアログを表示
                                _showDeleteConfirmationDialog(
                                  context,
                                  currentSenshu,
                                );
                              } else {
                                // 3. 条件が成就していない場合の処理（オプション）：
                                //    例えば、削除できない理由をユーザーに伝えるSnackBarを表示するなど
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'この選手は、現在、陸連役員か監督かコーチをしているので削除できません。',
                                    ),
                                  ),
                                );
                              }
                            },
                            // スタイルや子ウィジェットは変更なし
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_forever,
                                  size: HENSUU.fontsize_honbun + 2,
                                ),
                                const SizedBox(width: 8),
                                // 修正: TextウィジェットをExpandedでラップし、残りの幅をすべて与える
                                Expanded(
                                  child: const Text(
                                    'この選手をアルバムから削除',
                                    textAlign: TextAlign.center, // ★ 中央寄せ
                                    softWrap:
                                        true, // ★ 折り返しを有効にする（デフォルトで有効なことが多いですが明示的に）
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: HENSUU.fontsize_honbun,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // 画面下部のナビゲーションボタンは現役画面と同じ
                  const Divider(color: Colors.white54),
                  if (album.yobiint3 == 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ★ Expanded でラップして均等幅にする
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ), // Expanded間の微調整
                              child: ElevatedButton(
                                onPressed: () => _changeSenshu(-10),
                                // ... (style設定はそのまま) ...
                                child: const Text('10前'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () => _changeSenshu(-1),
                                // ...
                                child: const Text('前'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () => _changeSenshu(1),
                                // ...
                                child: const Text('次'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () => _changeSenshu(10),
                                // ...
                                child: const Text('10次'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ベスト記録表示用のヘルパーウィジェット
  Widget _buildBestRecordRow_fullr(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    if (time == TEISUU.DEFAULTTIME) {
      return Text(
        '$label 記録無',
        style: const TextStyle(
          color: Colors.white,
          fontSize: HENSUU.fontsize_honbun,
        ), // 白色に変更
      );
    }
    return Wrap(
      children: [
        Text(
          '$label: ${TimeDate.timeToJikanFunByouString(time)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
        const SizedBox(width: 8),
        if (gakunaiJuni != TEISUU.DEFAULTJUNI)
          Text(
            '学内${gakunaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          ),
        if (zentaiJuni != null) ...[
          const SizedBox(width: 8),
          Text(
            '全体${zentaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          ),
        ],
      ],
    );
  }

  Widget _buildBestRecordRowr(
    String label,
    double time,
    int gakunaiJuni,
    int? zentaiJuni,
  ) {
    if (time == TEISUU.DEFAULTTIME) {
      return Text(
        '$label 記録無',
        style: const TextStyle(
          color: Colors.white,
          fontSize: HENSUU.fontsize_honbun,
        ), // 白色に変更
      );
    }
    return Wrap(
      children: [
        Text(
          '$label: ${_timeToMinuteSecondString(time)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
        const SizedBox(width: 8),
        if (gakunaiJuni != TEISUU.DEFAULTJUNI)
          Text(
            '学内${gakunaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          ),
        if (zentaiJuni != null) ...[
          const SizedBox(width: 8),
          Text(
            '全体${zentaiJuni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          ),
        ],
      ],
    );
  }

  // 能力値表示用のヘルパーウィジェット
  Widget _buildAbilityRowr(String label, int flag, int value) {
    return Text(
      '$label: ${flag == 1 ? value.toString() : '??'}',
      style: TextStyle(
        color: flag == 1 ? Colors.white : Colors.grey, // ここは変更なし（条件によって色を変えるため）
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組なし)
  Widget _buildRaceRecordRow_fullr(String label, int juni, double time) {
    if (juni == TEISUU.DEFAULTJUNI) {
      return const SizedBox.shrink(); // 表示しない
    }
    return Wrap(
      children: [
        Text(
          '$label: ${juni + 1}位',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
        const SizedBox(width: 8),
        Text(
          TimeDate.timeToJikanFunByouString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
      ],
    );
  }

  Widget _buildRaceRecordRow_gakunair(String label, int juni, double time) {
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

  Widget _buildRaceRecordRowr(String label, int juni, double time) {
    if (juni == TEISUU.DEFAULTJUNI) {
      return const SizedBox.shrink(); // 表示しない
    }
    return Wrap(
      children: [
        Text(
          '$label: ${juni + 1}位',
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
        const SizedBox(width: 8),
        Text(
          _timeToMinuteSecondString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
      ],
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組あり)
  Widget _buildRaceRecordRowWithKumir(
    String label,
    int kumi,
    int juni,
    double time,
    int racebangou,
  ) {
    String kumistring = "";
    if (kumi <= -1) {
      // Swiftの entrykukan_race が -1 の場合に対応
      return const SizedBox.shrink(); // 表示しない
    }
    if (racebangou == 3) {
      kumistring = "組";
    } else {
      kumistring = "区";
    }
    return Wrap(
      children: [
        if (juni < 100)
          Text(
            '$label: ${kumi + 1}' + kumistring + '${juni + 1}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          )
        else
          Text(
            '$label: ${kumi + 1}' + kumistring + '${juni + 1 - 100}位相当',
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
            ), // 白色に変更
          ),
        const SizedBox(width: 8),
        Text(
          _timeToMinuteSecondString(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ), // 白色に変更
        ),
      ],
    );
  }

  // 選手の削除を実行する関数
  void _deleteSenshu(Senshu_R_Data senshuToDelete) async {
    // 1. Hiveから対象の選手を削除（これだけで ValueListenableBuilderが再構築されます）
    await _retiredSenshuBox.delete(senshuToDelete.id);

    // 2. 削除後、hyojisenshunum を強制的にリセットする処理
    // 削除後、buildメソッド内のロジックで hyojisenshunum の調整が行われるため、
    // ここでは hyojisenshunum を強制的に0に戻す操作のみを行います。
    // これにより、リストが空になった場合でも、次に選手が追加されたときに表示が崩れるのを防げます。
    final Album? album = _albumBox.get('AlbumData');
    if (album != null) {
      // 削除後のリストが空になる可能性を考慮し、表示番号を0に設定
      album.hyojisenshunum = 0;
      await album.save();
    }
  }

  // 削除確認ダイアログを表示する関数
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    Senshu_R_Data senshu,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '選手データの削除確認',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            '${senshu.name} (ID: ${senshu.id}) のアルバムデータを本当に削除してもよろしいですか？\nこの操作は元に戻せません。',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // キャンセル
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 削除実行
              child: const Text('削除する', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // ユーザーが「削除する」を選択した場合
      _deleteSenshu(senshu);
    }
  }

  // 解任進言確認ダイアログを表示する関数
  Future<void> _showDeleteConfirmationDialog_kantokukainin(
    BuildContext context,
    Senshu_R_Data senshu,
    int kantokuid,
  ) async {
    String str = "";
    if (kantokuid < TEISUU.UNIVSUU) {
      str = "監督";
    } else if (kantokuid < TEISUU.UNIVSUU * 2) {
      str = "コーチ(トラック)";
    } else {
      str = "コーチ(長距離)";
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退任進言確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '${senshu.name} が ${str} を退任するよう進言しますか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // キャンセル
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 削除実行
              child: const Text('進言する', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      // ユーザーが「進言する」を選択した場合
      // Hive.box() を使って、既に開いているBoxを取得
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      // Boxからデータを読み込む
      final KantokuData kantoku = kantokuBox.get('KantokuData')!;
      final Ghensuu ghensuu = _ghensuuBox.get(
        'global_ghensuu',
        defaultValue: Ghensuu.initial(),
      )!;
      List<UnivData> sortedUnivData = _univBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      int lastrid = kantoku.rid[kantokuid];
      kantoku.rid[kantokuid] = 0;
      kantoku.yobiint0[kantokuid] = 0;
      await kantoku.save();
      senshu.string_racesetumei +=
          "${ghensuu.year}年${ghensuu.month}月 ${sortedUnivData[senshu.univid].name}大学${str}を総監督からの進言により退任\n";
      await senshu.save();
    }
  }

  // 就任進言確認ダイアログを表示する関数
  Future<void> _showshuuninConfirmationDialog(
    BuildContext context,
    Senshu_R_Data senshu,
    int kantokuid,
  ) async {
    String str = "";
    if (kantokuid < TEISUU.UNIVSUU) {
      str = "監督";
    } else if (kantokuid < TEISUU.UNIVSUU * 2) {
      str = "コーチ(トラック)";
    } else {
      str = "コーチ(長距離)";
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('就任進言確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '${str} に ${senshu.name} が就任するよう進言しますか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // キャンセル
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 削除実行
              child: const Text('進言する', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      // ユーザーが「進言する」を選択した場合
      // Hive.box() を使って、既に開いているBoxを取得
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      // Boxからデータを読み込む
      final KantokuData kantoku = kantokuBox.get('KantokuData')!;
      final Ghensuu ghensuu = _ghensuuBox.get(
        'global_ghensuu',
        defaultValue: Ghensuu.initial(),
      )!;
      List<UnivData> sortedUnivData = _univBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

      for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
        if (i != kantokuid && kantoku.rid[i] == senshu.id) {
          String tempstr = "";
          kantoku.rid[i] = 0;
          kantoku.yobiint0[i] = 0;
          await kantoku.save();
          if (i < TEISUU.UNIVSUU) {
            tempstr = "監督";
          } else if (i < TEISUU.UNIVSUU * 2) {
            tempstr = "コーチ(トラック)";
          } else {
            tempstr = "コーチ(長距離)";
          }
          senshu.string_racesetumei +=
              "${ghensuu.year}年${ghensuu.month}月 ${sortedUnivData[senshu.univid].name}大学${tempstr}を総監督からの進言により退任\n";
          await senshu.save();
        }
      }

      int lastrid = kantoku.rid[kantokuid];
      kantoku.rid[kantokuid] = senshu.id;
      kantoku.yobiint0[kantokuid] = 1;
      await kantoku.save();
      senshu.string_racesetumei +=
          "${ghensuu.year}年${ghensuu.month}月 ${sortedUnivData[senshu.univid].name}大学${str}に総監督からの進言により就任\n";
      await senshu.save();
      final rsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
      // Box内の全ての値をリストとして取得します
      final allRetiredSenshu = rsenshuBox.values.toList();
      // 取得した全ての選手データをループ処理します
      for (var rsenshu in allRetiredSenshu) {
        if (rsenshu.id == lastrid) {
          rsenshu.string_racesetumei +=
              "${ghensuu.year}年${ghensuu.month}月 ${sortedUnivData[rsenshu.univid].name}大学${str}を総監督からの進言により退任\n";
          await rsenshu.save();
          break;
        }
      }
    }
  }
}
