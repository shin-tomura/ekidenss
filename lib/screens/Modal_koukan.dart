import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUUク

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
