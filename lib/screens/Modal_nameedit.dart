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

class ModalSenshuNameHenkou_modalsenshugamen extends StatefulWidget {
  final int senshuId;

  // コンストラクタを修正：required this.senshuId を追加
  const ModalSenshuNameHenkou_modalsenshugamen({
    super.key,
    required this.senshuId,
  });

  @override
  State<ModalSenshuNameHenkou_modalsenshugamen> createState() =>
      _ModalSenshuNameHenkou_modalsenshugamen_State();
}

class _ModalSenshuNameHenkou_modalsenshugamen_State
    extends State<ModalSenshuNameHenkou_modalsenshugamen> {
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
            // ignore: unused_local_variable
            final List<UnivData> idJunUnivData = univdataBox.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id));

            return ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),
              builder: (context, senshudataBox, _) {
                List<SenshuData> sortedSenshuData = senshudataBox.values
                    .toList();
                sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

                // 編集対象の選手
                SenshuData? targetSenshu;

                // widget.senshuId を使用してアクセス
                if (widget.senshuId < sortedSenshuData.length) {
                  targetSenshu = sortedSenshuData[widget.senshuId];
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
                      const Divider(color: Colors.grey),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "${targetSenshu.name}の名称を変更",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun! * 1.5,
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
                                decoration: const InputDecoration(
                                  hintText: "ここに入力",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(12.0),
                                ),
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.black),
                                onChanged: (value) {
                                  if (value.length > 20) {
                                    _firstNameController.text = value.substring(
                                      0,
                                      20,
                                    );
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
                                decoration: const InputDecoration(
                                  hintText: "ここに入力",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(12.0),
                                ),
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.black),
                                onChanged: (value) {
                                  if (value.length > 20) {
                                    _lastNameController.text = value.substring(
                                      0,
                                      20,
                                    );
                                    _lastNameController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _lastNameController.text.length,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    targetSenshu!.name =
                                        "${_firstNameController.text} ${_lastNameController.text}";
                                    await targetSenshu.save();
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(200, 48),
                                    padding: const EdgeInsets.all(12.0),
                                  ),
                                  child: Text(
                                    "決定",
                                    style: TextStyle(
                                      fontSize: HENSUU.fontsize_honbun! * 1.5,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
