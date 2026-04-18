// lib/screens/senshu_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート (DEFAULTTIME, DEFAULTJUNIなど)
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/qr_modal.dart';
//import 'package:ekiden/qr_scanner_screen.dart';
import 'package:ekiden/qr_camera_scanner_screen.dart';
import 'package:ekiden/qr_gallery_scanner_screen.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_editSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/screens/Modal_ChartHyojiHijyojiKirikae.dart';

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

// SwiftのKANSUUのような時間変換ヘルパー関数
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

class ModalBallExchange extends StatefulWidget {
  const ModalBallExchange({super.key});

  @override
  State<ModalBallExchange> createState() => _ModalBallExchangeState();
}

class _ModalBallExchangeState extends State<ModalBallExchange> {
  // テキストフィールドのコントローラー
  final TextEditingController _goldToSilverController = TextEditingController();
  final TextEditingController _silverToGoldController = TextEditingController();

  // エラーメッセージ用
  String _goldErrorText = '';
  String _silverErrorText = '';

  @override
  void dispose() {
    _goldToSilverController.dispose();
    _silverToGoldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('金銀交換', style: TextStyle(color: Colors.white)),
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

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text('金銀交換', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "金: ${currentGhensuu.goldenballsuu} 銀: ${currentGhensuu.silverballsuu}",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Divider(color: Colors.grey),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // 金→銀 交換セクション
                        Text(
                          "金を銀に交換 (金1 → 銀2)",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _goldToSilverController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: HENSUU.textcolor),
                          decoration: InputDecoration(
                            labelText: '交換する金の数',
                            labelStyle: TextStyle(color: HENSUU.textcolor),
                            hintText: '1以上の整数を入力',
                            hintStyle: TextStyle(color: Colors.grey),
                            errorText: _goldErrorText.isNotEmpty
                                ? _goldErrorText
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: HENSUU.textcolor,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.yellow[700]!,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final int? amount = int.tryParse(
                              _goldToSilverController.text,
                            );
                            if (amount == null || amount <= 0) {
                              setState(() {
                                _goldErrorText = '1以上の整数を入力してください';
                              });
                            } else if (amount > currentGhensuu.goldenballsuu) {
                              setState(() {
                                _goldErrorText = '所持金ボールが不足しています';
                              });
                            } else {
                              setState(() {
                                _goldErrorText = '';
                                currentGhensuu.goldenballsuu -= amount;
                                currentGhensuu.silverballsuu += amount * 2;
                              });
                              await currentGhensuu.save();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(
                            "交換",
                            style: TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 銀→金 交換セクション
                        Text(
                          "銀を金に交換 (銀10 → 金1)",
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _silverToGoldController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: HENSUU.textcolor),
                          decoration: InputDecoration(
                            labelText: '交換する銀の数',
                            labelStyle: TextStyle(color: HENSUU.textcolor),
                            hintText: '10以上の整数を入力',
                            hintStyle: TextStyle(color: Colors.grey),
                            errorText: _silverErrorText.isNotEmpty
                                ? _silverErrorText
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: HENSUU.textcolor,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey[400]!,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final int? amount = int.tryParse(
                              _silverToGoldController.text,
                            );
                            if (amount == null || amount < 10) {
                              setState(() {
                                _silverErrorText = '10以上の整数を入力してください';
                              });
                            } else if (amount > currentGhensuu.silverballsuu) {
                              setState(() {
                                _silverErrorText = '所持銀ボールが不足しています';
                              });
                            } else if (amount % 10 != 0) {
                              setState(() {
                                _silverErrorText = '10の倍数を入力してください';
                              });
                            } else {
                              setState(() {
                                _silverErrorText = '';
                                currentGhensuu.silverballsuu -= amount;
                                currentGhensuu.goldenballsuu += amount ~/ 10;
                              });
                              await currentGhensuu.save();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(
                            "交換",
                            style: TextStyle(
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),

                // 戻るボタン
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 48),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModalSenshuNameHenkou extends StatefulWidget {
  const ModalSenshuNameHenkou({super.key});

  @override
  State<ModalSenshuNameHenkou> createState() => _ModalSenshuNameHenkouState();
}

class _ModalSenshuNameHenkouState extends State<ModalSenshuNameHenkou> {
  // Swiftの @State private var text = "" に相当
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

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
              title: const Text('選手名変更', style: TextStyle(color: Colors.white)),
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

                // unividが特定のものだけ抽出 (univfilteredsenshudata)
                final List<SenshuData> univFilteredSenshuData = allSenshuData
                    .where((s) => s.univid == currentGhensuu.MYunivid)
                    .toList();

                // gakunenjununivfilteredsenshudata
                final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                    univFilteredSenshuData
                        .toList() // 新しいリストを作成してソート
                      ..sort((a, b) {
                        // 学年を降順で比較 (b.gakunen と a.gakunen を比較)
                        int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                        if (gakunenCompare != 0) {
                          return gakunenCompare; // 学年が異なる場合はその結果を返す
                        }
                        // 学年が同じ場合は、IDを昇順で比較 (a.id と b.id を比較)
                        return a.id.compareTo(b.id);
                      });

                // 編集対象の選手
                SenshuData? targetSenshu;
                if (currentGhensuu.hyojisenshunum >= 0 &&
                    currentGhensuu.hyojisenshunum <
                        gakunenJunUnivFilteredSenshuData.length) {
                  targetSenshu =
                      gakunenJunUnivFilteredSenshuData[currentGhensuu
                          .hyojisenshunum];
                }

                // targetSenshu が null の場合も考慮
                if (targetSenshu == null) {
                  return Scaffold(
                    backgroundColor: HENSUU.backgroundcolor,
                    appBar: AppBar(
                      title: const Text(
                        '選手名変更',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: HENSUU.backgroundcolor,
                      foregroundColor: Colors.white,
                    ),
                    body: Center(
                      child: Text(
                        '選手データが見つかりません',
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    ),
                  );
                }

                // TextFieldの初期値を設定（初回のみ）
                if (_firstNameController.text.isEmpty &&
                    _lastNameController.text.isEmpty) {
                  final parts = targetSenshu.name.split(' ');
                  _firstNameController.text = parts.isNotEmpty ? parts[0] : '';
                  _lastNameController.text = parts.length > 1 ? parts[1] : '';
                }

                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor,
                  appBar: AppBar(
                    title: const Text(
                      '選手名変更',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: HENSUU.backgroundcolor,
                    foregroundColor: Colors.white,
                  ),
                  body: Column(
                    children: <Widget>[
                      // Spacer() の代わりに Expanded を使ってスペースを確保
                      // Expanded(child: SizedBox.shrink()), // 上部のSpacer
                      const Divider(color: Colors.grey),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              /*Text(
                                "targetSenshu.univid=${targetSenshu.univid}",
                              ),
                              Text("targetSenshu.id=${targetSenshu.id}"),*/
                              Text(
                                "${targetSenshu.name}の名称を変更",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize:
                                      HENSUU.fontsize_honbun! *
                                      1.5, // .font(.title) に相当
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "苗字(上の名前)を入力してください",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              Text(
                                "最大3文字までの入力を推奨",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              TextField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  hintText: "ここに入力",
                                  filled: true,
                                  fillColor: Colors.white, // TextFieldの背景色を白に
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ), // 角丸
                                  ),
                                  contentPadding: const EdgeInsets.all(12.0),
                                ),
                                keyboardType: TextInputType.text,
                                style: const TextStyle(
                                  color: Colors.black,
                                ), // 入力文字色を黒に
                                onChanged: (value) {
                                  if (value.length > 20) {
                                    _firstNameController.text = value.substring(
                                      0,
                                      20,
                                    );
                                    // カーソルを末尾に移動
                                    _firstNameController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset:
                                            _firstNameController.text.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "下の名前を入力してください",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              Text(
                                "最大3文字までの入力を推奨",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              TextField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  hintText: "ここに入力",
                                  filled: true,
                                  fillColor: Colors.white, // TextFieldの背景色を白に
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ), // 角丸
                                  ),
                                  contentPadding: const EdgeInsets.all(12.0),
                                ),
                                keyboardType: TextInputType.text,
                                style: const TextStyle(
                                  color: Colors.black,
                                ), // 入力文字色を黒に
                                onChanged: (value) {
                                  if (value.length > 20) {
                                    _lastNameController.text = value.substring(
                                      0,
                                      20,
                                    );
                                    // カーソルを末尾に移動
                                    _lastNameController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _lastNameController.text.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 24), // ボタンとのスペース
                              Center(
                                // SwiftUIの.frame(maxWidth: .infinity, alignment: .center)に相当
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // 選手名を更新
                                    targetSenshu!.name =
                                        "${_firstNameController.text} ${_lastNameController.text}";
                                    await targetSenshu.save(); // Hiveに保存

                                    Navigator.pop(context); // モーダルを閉じる
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .green, // Swiftの.background(.green)
                                    foregroundColor: Colors
                                        .black, // Swiftの.foregroundColor(.black)
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // Swiftの.cornerRadius(8)
                                    ),
                                    minimumSize: const Size(
                                      200,
                                      48,
                                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                                    padding: const EdgeInsets.all(12.0),
                                  ),
                                  child: Text(
                                    "決定",
                                    style: TextStyle(
                                      fontSize:
                                          HENSUU.fontsize_honbun! *
                                          1.5, // .font(.largeTitle)に相当
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(color: Colors.grey),

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

class ModalTokkunGold extends StatefulWidget {
  const ModalTokkunGold({super.key});

  @override
  State<ModalTokkunGold> createState() => _ModalTokkunGoldState();
}

class _ModalTokkunGoldState extends State<ModalTokkunGold> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('金特訓', style: TextStyle(color: Colors.white)),
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

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            final List<SenshuData> allSenshuData = senshudataBox.values
                .toList();

            // unividが特定のものだけ抽出 (univfilteredsenshudata)
            final List<SenshuData> univFilteredSenshuData = allSenshuData
                .where((s) => s.univid == currentGhensuu.MYunivid)
                .toList();

            // gakunenjununivfilteredsenshudata
            final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                univFilteredSenshuData
                    .toList() // 新しいリストを作成してソート
                  ..sort((a, b) {
                    // 学年を降順で比較 (b.gakunen と a.gakunen を比較)
                    int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                    if (gakunenCompare != 0) {
                      return gakunenCompare; // 学年が異なる場合はその結果を返す
                    }
                    // 学年が同じ場合は、IDを昇順で比較 (a.id と b.id を比較)
                    return a.id.compareTo(b.id);
                  });
            // 編集対象の選手
            SenshuData? targetSenshu;
            if (currentGhensuu.hyojisenshunum >= 0 &&
                currentGhensuu.hyojisenshunum <
                    gakunenJunUnivFilteredSenshuData.length) {
              targetSenshu =
                  gakunenJunUnivFilteredSenshuData[currentGhensuu
                      .hyojisenshunum];
            }

            // targetSenshu が null の場合も考慮
            if (targetSenshu == null) {
              return Scaffold(
                backgroundColor: HENSUU.backgroundcolor,
                appBar: AppBar(
                  title: const Text(
                    '金特訓',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Text(
                    '選手データが見つかりません',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text('金特訓', style: TextStyle(color: Colors.white)),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  Text(
                    "${targetSenshu.name}(${targetSenshu.gakunen}) に金特訓をする 残${currentGhensuu.goldenballsuu}",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Spacer() の代わりに Expanded を使ってスペースを確保
                  // Expanded(child: SizedBox.shrink()), // 上部のSpacer
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          // 安定感 (anteikan)
                          /*Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "安定感 ${targetSenshu.anteikan}",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.anteikan <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.anteikan += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.anteikan <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),*/
                          const SizedBox(height: 16), // 要素間のスペース
                          // 駅伝男 (Konjou)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[0] == 1)
                                Text(
                                  "駅伝男 ${targetSenshu.konjou}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "駅伝男",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.konjou <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.konjou += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.konjou <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 平常心 (Heijousin)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[1] == 1)
                                Text(
                                  "平常心 ${targetSenshu.heijousin}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "平常心",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.heijousin <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.heijousin += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.heijousin <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 注意書きテキスト
                          Text(
                            "※能力値が90以上の場合には、それ以上は能力値を上げられない仕様です。",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun! * 0.8, // 少し小さめに
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SwiftのSpacer() に相当するが、ここでは画面下部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey),

                  // 戻るボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Swiftのコメントアウトされた部分のロジックをDartで実装する場合
                        // if (targetSenshu.konjou > 99) {
                        //   targetSenshu.konjou = 99;
                        // }
                        // if (targetSenshu.heijousin > 99) {
                        //   targetSenshu.heijousin = 99;
                        // }
                        // await targetSenshu.save(); // 変更を保存

                        // try? modelContext.save() に相当
                        // Hiveは変更をすぐに保存するため、明示的なsaveは不要な場合もありますが、
                        // 念のためここでも保存を呼び出します。
                        await currentGhensuu.save();
                        await targetSenshu!.save();

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
  }
}

class ModalTokkunSilver extends StatefulWidget {
  const ModalTokkunSilver({super.key});

  @override
  State<ModalTokkunSilver> createState() => _ModalTokkunSilverState();
}

class _ModalTokkunSilverState extends State<ModalTokkunSilver> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('銀特訓', style: TextStyle(color: Colors.white)),
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

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            final List<SenshuData> allSenshuData = senshudataBox.values
                .toList();

            // unividが特定のものだけ抽出 (univfilteredsenshudata)
            final List<SenshuData> univFilteredSenshuData = allSenshuData
                .where((s) => s.univid == currentGhensuu.MYunivid)
                .toList();

            // gakunenjununivfilteredsenshudata
            final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                univFilteredSenshuData
                    .toList() // 新しいリストを作成してソート
                  ..sort((a, b) {
                    // 学年を降順で比較 (b.gakunen と a.gakunen を比較)
                    int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                    if (gakunenCompare != 0) {
                      return gakunenCompare; // 学年が異なる場合はその結果を返す
                    }
                    // 学年が同じ場合は、IDを昇順で比較 (a.id と b.id を比較)
                    return a.id.compareTo(b.id);
                  });

            // 編集対象の選手
            SenshuData? targetSenshu;
            if (currentGhensuu.hyojisenshunum >= 0 &&
                currentGhensuu.hyojisenshunum <
                    gakunenJunUnivFilteredSenshuData.length) {
              targetSenshu =
                  gakunenJunUnivFilteredSenshuData[currentGhensuu
                      .hyojisenshunum];
            }

            // targetSenshu が null の場合も考慮
            if (targetSenshu == null) {
              return Scaffold(
                backgroundColor: HENSUU.backgroundcolor,
                appBar: AppBar(
                  title: const Text(
                    '銀特訓',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Text(
                    '選手データが見つかりません',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text('銀特訓', style: TextStyle(color: Colors.white)),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  Text(
                    "${targetSenshu.name}(${targetSenshu.gakunen}) に銀特訓をする 残${currentGhensuu.silverballsuu}",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          // 長距離粘り (choukyorinebari)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[2] == 1)
                                Text(
                                  "長距離粘り ${targetSenshu.choukyorinebari}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "長距離粘り",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.choukyorinebari <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.choukyorinebari += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.choukyorinebari <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // スパート力 (spurtryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[3] == 1)
                                Text(
                                  "スパート力 ${targetSenshu.spurtryoku}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "スパート力",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.spurtryoku <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.spurtryoku += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.spurtryoku <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // カリスマ (karisuma)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[4] == 1)
                                Text(
                                  "カリスマ ${targetSenshu.karisuma}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "カリスマ",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.karisuma <= 99)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.karisuma += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.karisuma <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 登り適性 (noboritekisei)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[5] == 1)
                                Text(
                                  "登り適性 ${targetSenshu.noboritekisei}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "登り適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.noboritekisei <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.noboritekisei += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.noboritekisei <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 下り適性 (kudaritekisei)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[6] == 1)
                                Text(
                                  "下り適性 ${targetSenshu.kudaritekisei}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "下り適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.kudaritekisei <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.kudaritekisei += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.kudaritekisei <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // アップダウン対応力 (noborikudarikirikaenouryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // テキストをExpandedで囲むことで、残りのスペースを柔軟に利用させる
                              Expanded(
                                child:
                                    // ★ここを三項演算子に変更します
                                    currentGhensuu.nouryokumieruflag[7] == 1
                                    ? Text(
                                        "アップダウン対応力 ${targetSenshu.noborikudarikirikaenouryoku}",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      )
                                    : Text(
                                        "アップダウン対応力",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      ),
                              ), // Expandedの閉じタグ
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu
                                                .noborikudarikirikaenouryoku <=
                                            89)
                                    ? () async {
                                        // ここは元のコードのまま
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!
                                                  .noborikudarikirikaenouryoku +=
                                              10;
                                        });
                                        await currentGhensuu.save();
                                        await targetSenshu!.save();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu
                                                  .noborikudarikirikaenouryoku <=
                                              89)
                                      ? Colors.green
                                      : Colors.grey,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // ロード適性 (tandokusou)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[8] == 1)
                                Text(
                                  "ロード適性 ${targetSenshu.tandokusou}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "ロード適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.tandokusou <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.tandokusou += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.tandokusou <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // ペース変動対応力 (paceagesagetaiouryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // テキストをExpandedで囲むことで、残りのスペースを柔軟に利用させる
                              Expanded(
                                child: // ★ここが変更点：if文で直接ウィジェットを返す
                                currentGhensuu.nouryokumieruflag[9] == 1
                                    ? Text(
                                        "ペース変動対応力 ${targetSenshu.paceagesagetaiouryoku}",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      )
                                    : Text(
                                        "ペース変動対応力",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      ),
                              ), // Expandedの閉じタグ
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.paceagesagetaiouryoku <=
                                            89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.paceagesagetaiouryoku +=
                                              10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.paceagesagetaiouryoku <=
                                              89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // ボタンの最小サイズを保持
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 注意書きテキスト
                          Text(
                            "※能力値が90以上の場合には、それ以上は能力値を上げられない仕様です。（カリスマは除く）",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun! * 0.8, // 少し小さめに
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Colors.grey),

                  // 戻るボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Swiftのコメントアウトされた部分のロジックをDartで実装する場合
                        // if (targetSenshu.choukyorinebari > 99) {
                        //   targetSenshu.choukyorinebari = 99;
                        // }
                        // if (targetSenshu.spurtryoku > 99) {
                        //   targetSenshu.spurtryoku = 99;
                        // }
                        // if (targetSenshu.karisuma > 99) {
                        //   targetSenshu.karisuma = 99;
                        // }
                        // if (targetSenshu.noboritekisei > 99) {
                        //   targetSenshu.noboritekisei = 99;
                        // }
                        // if (targetSenshu.kudaritekisei > 99) {
                        //   targetSenshu.kudaritekisei = 99;
                        // }
                        // if (targetSenshu.noborikudarikirikaenouryoku > 99) {
                        //   targetSenshu.noborikudarikirikaenouryoku = 99;
                        // }
                        // if (targetSenshu.tandokusou > 99) {
                        //   targetSenshu.tandokusou = 99;
                        // }
                        // if (targetSenshu.paceagesagetaiouryoku > 99) {
                        //   targetSenshu.paceagesagetaiouryoku = 99;
                        // }
                        // await targetSenshu.save(); // 変更を保存

                        await currentGhensuu.save();
                        await targetSenshu!.save();

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
  }
}

class SenshuScreen extends StatefulWidget {
  const SenshuScreen({super.key});

  @override
  State<SenshuScreen> createState() => _SenshuScreenState();
}

class _SenshuScreenState extends State<SenshuScreen> {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox; // UnivData Boxの参照を追加

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox'); // UnivData Boxを開く
  }

  // 表示する選手を更新する関数
  void _changeSenshu(int delta) async {
    final Ghensuu ghensuu = _ghensuuBox.get(
      'global_ghensuu',
      defaultValue: Ghensuu.initial(),
    )!;
    final int myUnivId = ghensuu.MYunivid;

    final List<SenshuData> myUnivSenshuList = _senshuBox.values
        .where((senshu) => senshu.univid == myUnivId)
        .toList();

    // 学年降順、ID昇順でソート
    myUnivSenshuList.sort((a, b) {
      int gakunenCompare = b.gakunen.compareTo(a.gakunen);
      if (gakunenCompare != 0) {
        return gakunenCompare;
      }
      return a.id.compareTo(b.id);
    });

    if (myUnivSenshuList.isEmpty) {
      // 該当する選手がいない場合は何もしない
      return;
    }

    int newSenshuNum = ghensuu.hyojisenshunum + delta;

    if (newSenshuNum < 0) {
      //newSenshuNum = myUnivSenshuList.length - 1;
      newSenshuNum = myUnivSenshuList.length - (-newSenshuNum);
    } else if (newSenshuNum >= myUnivSenshuList.length) {
      //newSenshuNum = 0;
      newSenshuNum = newSenshuNum - myUnivSenshuList.length;
    }

    ghensuu.hyojisenshunum = newSenshuNum;
    await ghensuu.save(); // Hiveに保存
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
        final int myUnivId = ghensuu.MYunivid;
        final int currentSenshuNum = ghensuu.hyojisenshunum; // 現在表示する選手の番号
        final univDataBox = Hive.box<UnivData>('univBox');
        List<UnivData> sortedUnivData = univDataBox.values.toList();
        sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: _senshuBox.listenable(),
          builder: (context, senshuBox, _) {
            final List<SenshuData> myUnivSenshuList = senshuBox.values
                .where((senshu) => senshu.univid == myUnivId)
                .toList();

            // 学年降順、ID昇順でソート
            myUnivSenshuList.sort((a, b) {
              int gakunenCompare = b.gakunen.compareTo(a.gakunen);
              if (gakunenCompare != 0) {
                return gakunenCompare;
              }
              return a.id.compareTo(b.id);
            });

            // 選手がいなければメッセージを表示
            if (myUnivSenshuList.isEmpty) {
              return const Center(
                child: Text(
                  '選手データがありません。',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                ),
              );
            }

            // hyojisenshunumがリストの範囲外になった場合を考慮
            SenshuData currentSenshu;
            if (currentSenshuNum >= 0 &&
                currentSenshuNum < myUnivSenshuList.length) {
              currentSenshu = myUnivSenshuList[currentSenshuNum];
            } else {
              // 範囲外の場合は最初の選手を表示し、hyojisenshunumを0にリセット
              currentSenshu = myUnivSenshuList[0];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ghensuu.hyojisenshunum != 0) {
                  ghensuu.hyojisenshunum = 0;
                  //ghensuu.save();ここには来ないはずなのでコメントアウトした
                }
              });
            }

            // 大学名を取得
            final UnivData? currentUnivData = _univBox.get(
              currentSenshu.univid,
            );
            final String univName = currentUnivData?.name ?? '大学名不明';
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

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.grey[900], // AppBarの背景色
                centerTitle: false, // leadingとtitleの配置を調整するためfalseに
                titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
                toolbarHeight: HENSUU.appbar_height, // 例: 高さを80ピクセルに増やす
                // ★ ステータスバーのアイコンが見えるように調整
                //systemOverlayStyle: //SystemUiOverlayStyle.light, // 白いアイコンにする場合
                //  SystemUiOverlayStyle.dark, // 黒いアイコンにする場合
                // 左側に2つの文字列を縦に並べる
                title: Padding(
                  padding: const EdgeInsets.only(left: 16.0), // 左側に少し余白
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.center, // 縦方向の中央揃え
                    //crossAxisAlignment: CrossAxisAlignment.start, // 横方向の左揃え
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
              ),
              backgroundColor: HENSUU.backgroundcolor,
              body: Column(
                children: [
                  const SizedBox(height: 8), // スペースを確保
                  // 大学名と選手名
                  Text(
                    '$univName 大学選手データ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Text("id=${currentSenshu.id}"),
                      Text(
                        currentSenshu.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: HENSUU.fontsize_honbun,
                          //fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 学年表示は引き続き `Colors.white70` を維持し、少し目立たなくします
                      Text(
                        '(${currentSenshu.gakunen}年)',
                        //'(${currentSenshu.gakunen}年 ID${currentSenshu.id})',
                        style: const TextStyle(
                          color: Colors.white,
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
                              final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>(
                                'ghensuuBox',
                              );
                              final Box<SenshuData> senshuBox =
                                  Hive.box<SenshuData>('senshuBox');
                              final Ghensuu ghensuu = ghensuuBox.get(
                                'global_ghensuu',
                                defaultValue: Ghensuu.initial(),
                              )!;
                              final int myUnivId = ghensuu.MYunivid;
                              final int currentSenshuNum =
                                  ghensuu.hyojisenshunum; // 現在表示する選手の番号
                              final univDataBox = Hive.box<UnivData>('univBox');
                              List<UnivData> sortedUnivData = univDataBox.values
                                  .toList();
                              sortedUnivData.sort(
                                (a, b) => a.id.compareTo(b.id),
                              );
                              /*final List<SenshuData> myUnivSenshuList = senshuBox.values
                .where((senshu) => senshu.univid == myUnivId)
                .toList();

            // 学年降順、ID昇順でソート
            myUnivSenshuList.sort((a, b) {
              int gakunenCompare = b.gakunen.compareTo(a.gakunen);
              if (gakunenCompare != 0) {
                return gakunenCompare;
              }
              return a.id.compareTo(b.id);
            });*/
                              SenshuData currentSenshu;
                              if (currentSenshuNum >= 0 &&
                                  currentSenshuNum < myUnivSenshuList.length) {
                                currentSenshu =
                                    myUnivSenshuList[currentSenshuNum];
                              } else {
                                // 範囲外の場合は最初の選手を表示し、hyojisenshunumを0にリセット
                                currentSenshu = myUnivSenshuList[0];
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) async {
                                  if (ghensuu.hyojisenshunum != 0) {
                                    ghensuu.hyojisenshunum = 0;
                                    await ghensuu.save();
                                  }
                                });
                              }

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
                                        senshuId: currentSenshu.id,
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
                                      return const ModalSenshuNameHenkou(); // const を追加
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
                            color: Colors.white, // 白色に変更
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
                          null, // Swiftコードで全体順位が表示されていないためnull
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
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        /*Text(
                          '限界突破回数 ${currentSenshu.genkaitoppakaisuu}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),*/

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
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 駅伝・対校戦成績 (学年ループ)
                        ...List.generate(currentSenshu.gakunen, (gakunenIndex) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 年時成績の見出しは `Colors.white` に変更
                              Text(
                                '${gakunenIndex + 1}年時成績',
                                style: const TextStyle(
                                  color: Colors.white, // 白色に変更
                                  fontSize: HENSUU.fontsize_honbun,
                                  //fontWeight: FontWeight.bold,
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
                                currentSenshu.entrykukan_race[3][gakunenIndex],
                                currentSenshu.kukanjuni_race[3][gakunenIndex],
                                currentSenshu.kukantime_race[3][gakunenIndex],
                                3,
                              ),
                              _buildRaceRecordRowWithKumi(
                                '10月駅伝',
                                currentSenshu.entrykukan_race[0][gakunenIndex],
                                currentSenshu.kukanjuni_race[0][gakunenIndex],
                                currentSenshu.kukantime_race[0][gakunenIndex],
                                0,
                              ),
                              _buildRaceRecordRow(
                                '正月駅伝予選',
                                currentSenshu.kukanjuni_race[4][gakunenIndex],
                                currentSenshu.kukantime_race[4][gakunenIndex],
                              ),
                              _buildRaceRecordRowWithKumi(
                                '11月駅伝',
                                currentSenshu.entrykukan_race[1][gakunenIndex],
                                currentSenshu.kukanjuni_race[1][gakunenIndex],
                                currentSenshu.kukantime_race[1][gakunenIndex],
                                1,
                              ),

                              _buildRaceRecordRowWithKumi(
                                '正月駅伝',
                                currentSenshu.entrykukan_race[2][gakunenIndex],
                                currentSenshu.kukanjuni_race[2][gakunenIndex],
                                currentSenshu.kukantime_race[2][gakunenIndex],
                                2,
                              ),

                              _buildRaceRecordRowWithKumi(
                                sortedUnivData[0].name_tanshuku,
                                currentSenshu.entrykukan_race[5][gakunenIndex],
                                currentSenshu.kukanjuni_race[5][gakunenIndex],
                                currentSenshu.kukantime_race[5][gakunenIndex],
                                2,
                              ),

                              _buildRaceRecordRow(
                                '秋記録会5千',
                                currentSenshu.kukanjuni_race[10][gakunenIndex],
                                currentSenshu.kukantime_race[10][gakunenIndex],
                              ),
                              _buildRaceRecordRow(
                                '秋記録会1万',
                                currentSenshu.kukanjuni_race[11][gakunenIndex],
                                currentSenshu.kukantime_race[11][gakunenIndex],
                              ),
                              _buildRaceRecordRow(
                                '秋市民ハーフ',
                                currentSenshu.kukanjuni_race[12][gakunenIndex],
                                currentSenshu.kukantime_race[12][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunai(
                                '登り10km',
                                currentSenshu.kukanjuni_race[13][gakunenIndex],
                                currentSenshu.kukantime_race[13][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunai(
                                '下り10km',
                                currentSenshu.kukanjuni_race[14][gakunenIndex],
                                currentSenshu.kukantime_race[14][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunai(
                                'ロード10km',
                                currentSenshu.kukanjuni_race[15][gakunenIndex],
                                currentSenshu.kukantime_race[15][gakunenIndex],
                              ),
                              _buildRaceRecordRow_gakunai(
                                'クロカン10km',
                                currentSenshu.kukanjuni_race[16][gakunenIndex],
                                currentSenshu.kukantime_race[16][gakunenIndex],
                              ),

                              _buildRaceRecordRow_full(
                                'フルマラソン',
                                currentSenshu.kukanjuni_race[17][gakunenIndex],
                                currentSenshu.kukantime_race[17][gakunenIndex],
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),
                        // リンクボタン
                        LinkButtons(context, ghensuu),

                        const SizedBox(height: 20), // 下部ボタンとのマージン
                      ],
                    ),
                  ),

                  // 画面下部のナビゲーションボタン
                  const Divider(color: Colors.white54),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _changeSenshu(-5),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('<<'),
                        ),
                        ElevatedButton(
                          onPressed: () => _changeSenshu(-1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('＜'),
                        ),
                        ElevatedButton(
                          onPressed: () => _changeSenshu(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('＞'),
                        ),
                        ElevatedButton(
                          onPressed: () => _changeSenshu(5),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('>>'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // bottomNavigationBar の高さの分を確保
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ベスト記録表示用のヘルパーウィジェット
  Widget _buildBestRecordRow_full(
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

  Widget _buildBestRecordRow(
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
  Widget _buildAbilityRow(String label, int flag, int value) {
    return Text(
      '$label: ${flag == 1 ? value.toString() : '??'}',
      style: TextStyle(
        color: flag == 1 ? Colors.white : Colors.grey, // ここは変更なし（条件によって色を変えるため）
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  // 駅伝・対校戦成績表示用のヘルパーウィジェット (組なし)
  Widget _buildRaceRecordRow_full(String label, int juni, double time) {
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

  Widget _buildRaceRecordRow(String label, int juni, double time) {
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
  Widget _buildRaceRecordRowWithKumi(
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

  // リンクボタン用のヘルパーウィジェット
  // リンクボタンをWidgetに分離
  // currentGhensuu を引数として受け取るように変更
  Widget LinkButtons(BuildContext context, Ghensuu currentGhensuu) {
    final int myUnivId = currentGhensuu.MYunivid;

    final List<SenshuData> myUnivSenshuList = _senshuBox.values
        .where((senshu) => senshu.univid == myUnivId)
        .toList();

    // 学年降順、ID昇順でソート
    myUnivSenshuList.sort((a, b) {
      int gakunenCompare = b.gakunen.compareTo(a.gakunen);
      if (gakunenCompare != 0) {
        return gakunenCompare;
      }
      return a.id.compareTo(b.id);
    });
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;
    return Column(
      children: [
        // ModalZenhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        //if (currentGhensuu.hyojiracebangou == 2)
        TextButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '選手名変更', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalSenshuNameHenkou(); // const を追加
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
            "選手名変更",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),

        // ModalKouhanKekkaView は currentGhensuu.hyojiracebangou が 2 の時だけ表示
        //if (currentGhensuu.hyojiracebangou == 2)
        if ((currentGhensuu.month == 7 && currentGhensuu.day == 15) &&
            (currentGhensuu.goldenballsuu >= 10 ||
                currentGhensuu.silverballsuu >= 10) &&
            myUnivSenshuList[currentGhensuu.hyojisenshunum].hirou != 1)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '金特訓をする', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalTokkunGold(); // const を追加
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
              "金特訓をする",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        // ModalKukanshouView は currentGhensuu.hyojiracebangou が 2 以下の時だけ表示
        //if (currentGhensuu.hyojiracebangou <= 2)
        if ((currentGhensuu.month == 7 && currentGhensuu.day == 15) &&
            (currentGhensuu.goldenballsuu >= 10 ||
                currentGhensuu.silverballsuu >= 10) &&
            myUnivSenshuList[currentGhensuu.hyojisenshunum].hirou != 1)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '銀特訓をする', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalTokkunSilver(); // const を追加
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
              "銀特訓をする",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        if ((currentGhensuu.month == 7 && currentGhensuu.day == 15) &&
            (currentGhensuu.goldenballsuu >= 10 ||
                currentGhensuu.silverballsuu >= 10) &&
            myUnivSenshuList[currentGhensuu.hyojisenshunum].hirou != 1)
          TextButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '金銀交換をする', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const ModalBallExchange(); // const を追加
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
              "金銀交換をする",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
        TextButton(
          onPressed: () async {
            final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
            final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
            final Ghensuu ghensuu = ghensuuBox.get(
              'global_ghensuu',
              defaultValue: Ghensuu.initial(),
            )!;
            final int myUnivId = ghensuu.MYunivid;
            final int currentSenshuNum = ghensuu.hyojisenshunum; // 現在表示する選手の番号
            final univDataBox = Hive.box<UnivData>('univBox');
            List<UnivData> sortedUnivData = univDataBox.values.toList();
            sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
            /*final List<SenshuData> myUnivSenshuList = senshuBox.values
                .where((senshu) => senshu.univid == myUnivId)
                .toList();

            // 学年降順、ID昇順でソート
            myUnivSenshuList.sort((a, b) {
              int gakunenCompare = b.gakunen.compareTo(a.gakunen);
              if (gakunenCompare != 0) {
                return gakunenCompare;
              }
              return a.id.compareTo(b.id);
            });*/
            SenshuData currentSenshu;
            if (currentSenshuNum >= 0 &&
                currentSenshuNum < myUnivSenshuList.length) {
              currentSenshu = myUnivSenshuList[currentSenshuNum];
            } else {
              // 範囲外の場合は最初の選手を表示し、hyojisenshunumを0にリセット
              currentSenshu = myUnivSenshuList[0];
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (ghensuu.hyojisenshunum != 0) {
                  ghensuu.hyojisenshunum = 0;
                  await ghensuu.save();
                }
              });
            }

            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: 'この選手のQRコードを表示', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return QrModal(senshu: currentSenshu); // const を追加
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
            // async を追加
            final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
            //final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
            final Ghensuu? ghensuu = ghensuuBox.get(
              'global_ghensuu',
              defaultValue: Ghensuu.initial(),
            );
            if (ghensuu == null) {
              // エラー処理：ghensuuが取得できない場合
              // SnackBarなどでユーザーに通知すると良いでしょう
              return;
            }
            //final int myUnivId = ghensuu.MYunivid;
            final int currentSenshuNum = ghensuu.hyojisenshunum;
            SenshuData? currentSenshu;
            if (currentSenshuNum >= 0 &&
                currentSenshuNum < myUnivSenshuList.length) {
              currentSenshu = myUnivSenshuList[currentSenshuNum];
            } else if (myUnivSenshuList.isNotEmpty) {
              // 範囲外の場合、最初の選手を選択
              currentSenshu = myUnivSenshuList[0];
              if (ghensuu.hyojisenshunum != 0) {
                ghensuu.hyojisenshunum = 0;
                await ghensuu.save(); // 非同期で保存
              }
            } else {
              // 選手が一人もいない場合のエラー処理
              // 例: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('表示する選手がいません。')));
              return;
            }
            // 選手が確定してから画面遷移
            if (currentSenshu != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QrGalleryScannerScreen(
                    senshuIdToUpdate: currentSenshu!.id,
                  ),
                ),
              );
            }
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
            // async を追加
            final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
            //final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
            final Ghensuu? ghensuu = ghensuuBox.get(
              'global_ghensuu',
              defaultValue: Ghensuu.initial(),
            );
            if (ghensuu == null) {
              // エラー処理：ghensuuが取得できない場合
              // SnackBarなどでユーザーに通知すると良いでしょう
              return;
            }
            //final int myUnivId = ghensuu.MYunivid;
            final int currentSenshuNum = ghensuu.hyojisenshunum;
            SenshuData? currentSenshu;
            if (currentSenshuNum >= 0 &&
                currentSenshuNum < myUnivSenshuList.length) {
              currentSenshu = myUnivSenshuList[currentSenshuNum];
            } else if (myUnivSenshuList.isNotEmpty) {
              // 範囲外の場合、最初の選手を選択
              currentSenshu = myUnivSenshuList[0];
              if (ghensuu.hyojisenshunum != 0) {
                ghensuu.hyojisenshunum = 0;
                await ghensuu.save(); // 非同期で保存
              }
            } else {
              // 選手が一人もいない場合のエラー処理
              // 例: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('表示する選手がいません。')));
              return;
            }
            // 選手が確定してから画面遷移
            if (currentSenshu != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QrCameraScannerScreen(
                    senshuIdToUpdate: currentSenshu!.id,
                  ),
                ),
              );
            }
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

        if ((currentGhensuu.month == 3 && currentGhensuu.day == 25) &&
            myUnivSenshuList[currentGhensuu.hyojisenshunum].gakunen == 4)
          TextButton(
            onPressed: () async {
              // 1. 必要なBoxを定義（Stateクラスの initState で初期化済みと仮定）
              //final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
              final Box<Senshu_R_Data> retiredSenshuBox =
                  Hive.box<Senshu_R_Data>('retiredSenshuBox');
              //final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

              //final Ghensuu ghensuu = ghensuuBox.get(
              //  'global_ghensuu',
              //  defaultValue: Ghensuu.initial(),
              //)!;

              // 2. 現在表示中の選手データ（現役）を取得
              //inal int myUnivId = currentGhensuu.MYunivid;

              //final List<SenshuData> myUnivSenshuList = senshuBox.values
              //    .where((senshu) => senshu.univid == myUnivId)
              //    .toList();

              /*myUnivSenshuList.sort((a, b) {
                int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                if (gakunenCompare != 0) return gakunenCompare;
                return a.id.compareTo(b.id);
              });*/

              if (myUnivSenshuList.isEmpty ||
                  currentGhensuu.hyojisenshunum >= myUnivSenshuList.length) {
                // 選手が見つからない場合
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('選手データが見つかりません。')));
                return;
              }

              final SenshuData currentSenshu =
                  myUnivSenshuList[currentGhensuu.hyojisenshunum];

              // ----------------------------------------------------
              // ★ 3. 確認ダイアログを表示し、ユーザーの選択を待つ
              // ----------------------------------------------------
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('アルバムへの追加確認'),
                    content: Text(
                      '本当に ${currentSenshu.name} 選手をアルバムに追加しますか？\n（既にアルバムにいる場合は上書きされます）',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false), // キャンセル: falseを返す
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true), // はい: trueを返す
                        child: const Text('はい、追加します'),
                      ),
                    ],
                  );
                },
              );

              // 4. ユーザーがキャンセルした場合、ここで処理を終了
              if (confirmed != true) {
                return;
              }

              // ----------------------------------------------------
              // ★ 5. 保存処理（確認が取れた場合のみ実行）
              // ----------------------------------------------------

              //print("処理前ID ${currentSenshu.id}");
              // 現役選手データを卒業選手データに変換 (fromSenshuDataファクトリを使用)
              final Senshu_R_Data retiredSenshu = Senshu_R_Data.fromSenshuData(
                currentSenshu,
              );

              // sijiflag（卒業年）idを設定
              final int currentYear = currentGhensuu.year;
              retiredSenshu.sijiflag = currentYear;
              retiredSenshu.id += currentYear * 1000;
              retiredSenshu.string_racesetumei = "";
              retiredSenshu.sijiseikouflag = 100; //プレイヤーが自分でアルバムに追加した印

              //print("処理後ID ${currentSenshu.id}");

              // Hive Boxに保存
              await retiredSenshuBox.put(retiredSenshu.id, retiredSenshu);

              // 完了メッセージを表示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${retiredSenshu.name} をアルバムに追加しました (${retiredSenshu.sijiflag}年卒)。',
                  ),
                ),
              );
            },
            child: Text(
              "この選手をアルバムに追加",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          )
        else
          Text(
            "(3月下旬に卒業直前の選手をアルバムに追加できます)",
            style: TextStyle(color: HENSUU.textcolor),
          ),
      ],
    );
  }
}
