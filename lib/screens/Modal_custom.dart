import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート

import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート

class ModalCustomEkidenSettings extends StatefulWidget {
  const ModalCustomEkidenSettings({super.key});

  @override
  State<ModalCustomEkidenSettings> createState() =>
      _ModalCustomEkidenSettingsState();
}

class _ModalCustomEkidenSettingsState extends State<ModalCustomEkidenSettings> {
  final TextEditingController _ekidenNameController = TextEditingController();
  final TextEditingController _fameNumeratorController =
      TextEditingController();
  final TextEditingController _fameDenominatorController =
      TextEditingController();
  final TextEditingController _sectionsController =
      TextEditingController(); // 区間数用のコントローラー

  late bool _isEkidenHeld;

  @override
  void initState() {
    super.initState();
    _sectionsController;
  }

  @override
  void dispose() {
    _ekidenNameController.dispose();
    _fameNumeratorController.dispose();
    _fameDenominatorController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  // 入力された文字列を1から10の範囲に補正するヘルパー関数
  int _clampValue(String value) {
    int parsedValue = int.tryParse(value) ?? 1;
    return parsedValue.clamp(1, 10);
  }

  // 区間数の入力値を2から10の範囲に補正するヘルパー関数
  int _clampSectionsValue(String value) {
    int parsedValue = int.tryParse(value) ?? 5; // 初期値として5を設定
    return parsedValue.clamp(2, 10);
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? gh = ghensuuBox.getAt(0);

        if (gh == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                'カスタム駅伝設定',
                style: TextStyle(color: Colors.white),
              ),
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
            final List<UnivData> allUnivData = univdataBox.values.toList();
            final List<UnivData> sortedUnivData = allUnivData
              ..sort((a, b) => a.id.compareTo(b.id));

            // 初期値を設定（初回のみ）
            if (_ekidenNameController.text.isEmpty &&
                _fameNumeratorController.text.isEmpty &&
                _fameDenominatorController.text.isEmpty &&
                _sectionsController.text.isEmpty) {
              _ekidenNameController.text = sortedUnivData[0].name_tanshuku;
              _isEkidenHeld = gh.spurtryokuseichousisuu1 == 1;

              int sections = gh.kukansuu_taikaigoto[5];
              if (sections < 2 || sections > 10) {
                sections = 5;
              }
              _sectionsController.text = sections.toString();

              _fameNumeratorController.text = gh.spurtryokuseichousisuu4
                  .clamp(1, 10)
                  .toString();
              _fameDenominatorController.text = gh.spurtryokuseichousisuu5
                  .clamp(1, 10)
                  .toString();
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  'カスタム駅伝設定',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: SafeArea(
                child: Column(
                  children: <Widget>[
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "カスタム駅伝を開催する",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _isEkidenHeld,
                                  onChanged: (value) {
                                    setState(() {
                                      _isEkidenHeld = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // _isEkidenHeldがtrueの場合のみ表示
                            if (_isEkidenHeld) ...[
                              Text(
                                "カスタム駅伝の名称",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "「駅伝」も含めて入力してください",
                                style: TextStyle(color: HENSUU.textcolor),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _ekidenNameController,
                                maxLength: 50,
                                decoration: InputDecoration(
                                  hintText: "名称を入力",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(12.0),
                                  counterText: "",
                                ),
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "区間数 (2～10の整数)",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 100, // 幅を固定
                                child: TextField(
                                  controller: _sectionsController,
                                  decoration: const InputDecoration(
                                    labelText: "区間数",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    if (value.isEmpty) {
                                      return;
                                    }
                                    final int parsedValue =
                                        int.tryParse(value) ?? 0;
                                    if (parsedValue > 10) {
                                      _sectionsController.text = '10';
                                      _sectionsController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _sectionsController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    }
                                  },
                                  onSubmitted: (value) {
                                    final int clampedValue =
                                        _clampSectionsValue(value);
                                    _sectionsController.text = clampedValue
                                        .toString();
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "獲得名声倍率 (1～10の整数)",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "正月駅伝での獲得名声と比較して何倍になるのかを、ｙ/ｘの形で入力願います。\nyがxより大きければ正月駅伝より多い名声を獲得し、yがxより小さければ正月駅伝より少ない名声を獲得するようになります。",
                                style: TextStyle(color: HENSUU.textcolor),
                              ),
                              Text(
                                "1/2で対校戦相当、1/4で10月駅伝や11月駅伝相当になります。",
                                style: TextStyle(color: HENSUU.textcolor),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100, // 幅を固定
                                    child: TextField(
                                      controller: _fameNumeratorController,
                                      decoration: const InputDecoration(
                                        labelText: '分子',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        if (value.isEmpty) {
                                          return;
                                        }
                                        final int parsedValue =
                                            int.tryParse(value) ?? 0;
                                        if (parsedValue > 10) {
                                          _fameNumeratorController.text = '10';
                                          _fameNumeratorController.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset:
                                                      _fameNumeratorController
                                                          .text
                                                          .length,
                                                ),
                                              );
                                        }
                                      },
                                      onSubmitted: (value) {
                                        final int clampedValue = _clampValue(
                                          value,
                                        );
                                        _fameNumeratorController.text =
                                            clampedValue.toString();
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      '/',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100, // 幅を固定
                                    child: TextField(
                                      controller: _fameDenominatorController,
                                      decoration: const InputDecoration(
                                        labelText: '分母',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        if (value.isEmpty) {
                                          return;
                                        }
                                        final int parsedValue =
                                            int.tryParse(value) ?? 0;
                                        if (parsedValue > 10) {
                                          _fameDenominatorController.text =
                                              '10';
                                          _fameDenominatorController.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset:
                                                      _fameDenominatorController
                                                          .text
                                                          .length,
                                                ),
                                              );
                                        }
                                      },
                                      onSubmitted: (value) {
                                        final int clampedValue = _clampValue(
                                          value,
                                        );
                                        _fameDenominatorController.text =
                                            clampedValue.toString();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final Ghensuu? ghToUpdate = ghensuuBox.getAt(0);
                                if (ghToUpdate != null) {
                                  // 開催しない場合は他の設定を保存しない
                                  if (!_isEkidenHeld) {
                                    // 開催フラグのみを更新して終了
                                    ghToUpdate.spurtryokuseichousisuu1 = 0;
                                    await ghToUpdate.save();
                                    Navigator.pop(context);
                                    return;
                                  }

                                  // 入力確定時に再度補正
                                  final int clampedSections =
                                      _clampSectionsValue(
                                        _sectionsController.text,
                                      );
                                  _sectionsController.text = clampedSections
                                      .toString();

                                  final int clampedNumerator = _clampValue(
                                    _fameNumeratorController.text,
                                  );
                                  _fameNumeratorController.text =
                                      clampedNumerator.toString();

                                  final int clampedDenominator = _clampValue(
                                    _fameDenominatorController.text,
                                  );
                                  _fameDenominatorController.text =
                                      clampedDenominator.toString();

                                  // カスタム駅伝名を更新
                                  sortedUnivData[0].name_tanshuku =
                                      _ekidenNameController.text;
                                  await sortedUnivData[0].save();

                                  // 開催フラグを更新
                                  ghToUpdate.spurtryokuseichousisuu1 =
                                      _isEkidenHeld ? 1 : 0;

                                  // 区間数を更新
                                  ghToUpdate.kukansuu_taikaigoto[5] =
                                      clampedSections;

                                  // 獲得名声倍率を更新
                                  ghToUpdate.spurtryokuseichousisuu4 =
                                      clampedNumerator;
                                  ghToUpdate.spurtryokuseichousisuu5 =
                                      clampedDenominator;

                                  await ghToUpdate.save();
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12.0),
                              ),
                              child: Text(
                                "決定",
                                style: TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
