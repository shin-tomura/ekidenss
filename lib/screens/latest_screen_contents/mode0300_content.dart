// lib/screens/mode0300_content.dart
//import 'package:path_provider/path_provider.dart';
//import 'package:flutter/foundation.dart';
//import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuモデルのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataモデルのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataモデルのインポート
import 'package:ekiden/constants.dart'; // 定数のインポート

//import 'package:ekiden/kansuu/FindFastestTeam.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/kansuu/time_date.dart'; // 時間・日付ユーティリティのインポート
import 'package:ekiden/kansuu/EntryCalc.dart';
//import 'package:ekiden/kansuu/TimeDesugiHoseiHoseitime.dart';
//import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';
//import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';

import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_koteisaitekikai.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:ekiden/screens/Modal_matrix2.dart';
import 'package:ekiden/screens/Modal_matrix3.dart';
import 'package:ekiden/screens/All0300.dart';
import 'package:ekiden/screens/Modal_Taichoufuryou.dart';

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

int dameunivid = 0;

String _formatDoubleToFixed(double value, int fractionDigits) {
  return value.toStringAsFixed(fractionDigits);
}

class ModalCourseEditView extends StatefulWidget {
  const ModalCourseEditView({super.key});

  @override
  State<ModalCourseEditView> createState() => _ModalCourseEditViewState();
}

class _ModalCourseEditViewState extends State<ModalCourseEditView> {
  final _formKey = GlobalKey<FormState>();
  final List<List<TextEditingController>> _controllers = [];
  final List<List<FocusNode>> _focusNodes = [];
  List<double?> _kukanTrialTimes = [];
  List<bool> _isCalculating = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var kukanControllers in _controllers) {
      for (var controller in kukanControllers) {
        controller.dispose();
      }
    }
    for (var kukanFocusNodes in _focusNodes) {
      for (var focusNode in kukanFocusNodes) {
        focusNode.dispose();
      }
    }
    super.dispose();
  }

  // TODO: この処理の中身を実装してください
  // このメソッドは、各区間の走破タイム（秒単位のdouble型）を計算します。
  Future<double> _runTrialCalculation(
    int i_kukan,
    Ghensuu currentGhensuu,
  ) async {
    double kotaetime = 0.0;
    List<SenshuData> _getUnivFilteredSenshuData(
      List<SenshuData> allSenshuData,
      int myUnivId,
    ) {
      return allSenshuData
          .where(
            (s) =>
                s.univid == myUnivId &&
                s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                        1] !=
                    -2,
          )
          .toList();
    }

    List<SenshuData> _getGakunenJunUnivFilteredSenshuData(
      List<SenshuData> univFilteredSenshuData,
    ) {
      return univFilteredSenshuData.toList()..sort((a, b) {
        // gakunen (学年) を降順で比較
        final gakunenComparison = b.gakunen.compareTo(a.gakunen);

        // gakunen が同じ場合は id を昇順で比較
        if (gakunenComparison == 0) {
          return a.id.compareTo(b.id); // id は昇順
        }

        return gakunenComparison; // gakunen が異なる場合はその比較結果を返す
      });
    }

    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    List<SenshuData> sortedsenshudata = senshudataBox.values.toList();
    sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));
    final List<SenshuData> univFilteredSenshuData = _getUnivFilteredSenshuData(
      sortedsenshudata,
      currentGhensuu.MYunivid,
    );
    final List<SenshuData> gakunenJunUnivFilteredSenshuData =
        _getGakunenJunUnivFilteredSenshuData(univFilteredSenshuData);

    int senshuid =
        gakunenJunUnivFilteredSenshuData[currentGhensuu
                .SenshuSelectedOption[i_kukan]]
            .id;
    if (senshuid < 0 || senshuid >= sortedsenshudata.length) {
      senshuid = 0;
    }

    final Box<UnivData> univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    kotaetime = await runTrialCalculation(
      senshuid,
      i_kukan,
      currentGhensuu,
      sortedsenshudata,
      sortedUnivData,
      kantoku,
    );
    await Future.delayed(const Duration(milliseconds: 500)); //わざと渦巻き表示させるため
    return kotaetime;
  }

  String _formatDoubleToFixed(double value, int fractionDigits) {
    final String result = value.toStringAsFixed(fractionDigits);
    if (result.endsWith('.0' + '0' * (fractionDigits - 1))) {
      return result.substring(0, result.length - fractionDigits - 1);
    }
    return result;
  }

  String _formatTime(double totalSeconds) {
    //final int hours = (totalSeconds / 3600).floor();
    final int hours = 0;
    final int minutes = (totalSeconds / 60).floor();
    final int seconds = (totalSeconds % 60).floor();
    return '${hours > 0 ? '$hours:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, box, _) {
        final Ghensuu? currentGhensuu = box.getAt(0);

        if (currentGhensuu == null) {
          return const Scaffold(body: Center(child: Text('データがありません')));
        }

        if (currentGhensuu.hyojiracebangou == 3 ||
            currentGhensuu.hyojiracebangou == 4 ||
            currentGhensuu.hyojiracebangou > 5) {
          return _buildErrorView(context);
        }

        if (_controllers.isEmpty) {
          _initializeControllers(currentGhensuu);
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(
                '区間コース編集',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildRaceTitle(currentGhensuu.hyojiracebangou),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    for (
                      int i_kukan = 0;
                      i_kukan <
                          currentGhensuu.kukansuu_taikaigoto[currentGhensuu
                              .hyojiracebangou];
                      i_kukan++
                    )
                      _buildKukanEditor(currentGhensuu, i_kukan),
                    const Divider(color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResetButton(currentGhensuu),
                        _buildSaveButton(currentGhensuu),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _initializeControllers(Ghensuu currentGhensuu) {
    _controllers.clear();
    _focusNodes.clear();
    final raceIndex = currentGhensuu.hyojiracebangou;
    final kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];
    _kukanTrialTimes = List.generate(kukanCount, (index) => null);
    _isCalculating = List.generate(kukanCount, (index) => false);
    for (int i_kukan = 0; i_kukan < kukanCount; i_kukan++) {
      _controllers.add([
        TextEditingController(
          text: currentGhensuu.kyori_taikai_kukangoto[raceIndex][i_kukan]
              .toInt()
              .toString(),
        ),
        TextEditingController(
          text: _formatDoubleToFixed(
            currentGhensuu
                .heikinkoubainobori_taikai_kukangoto[raceIndex][i_kukan],
            4,
          ),
        ),
        TextEditingController(
          text: _formatDoubleToFixed(
            -currentGhensuu
                .heikinkoubaikudari_taikai_kukangoto[raceIndex][i_kukan],
            4,
          ),
        ),
        TextEditingController(
          text: _formatDoubleToFixed(
            currentGhensuu
                .kyoriwariainobori_taikai_kukangoto[raceIndex][i_kukan],
            4,
          ),
        ),
        TextEditingController(
          text: _formatDoubleToFixed(
            currentGhensuu
                .kyoriwariaikudari_taikai_kukangoto[raceIndex][i_kukan],
            4,
          ),
        ),
        TextEditingController(
          text: currentGhensuu
              .noborikudarikirikaekaisuu_taikai_kukangoto[raceIndex][i_kukan]
              .toString(),
        ),
      ]);
      _focusNodes.add(List.generate(6, (_) => FocusNode()));
    }
  }

  Widget _buildErrorView(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('区間コース編集', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '申し訳ありません。このレースは編集できません。',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                ),
                child: const Text(
                  '戻る',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRaceTitle(int raceIndex) {
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    String raceTitle;
    switch (raceIndex) {
      case 0:
        raceTitle = "10月駅伝";
        break;
      case 1:
        raceTitle = "11月駅伝";
        break;
      case 2:
        raceTitle = "正月駅伝";
        break;
      case 5:
        raceTitle = sortedUnivData.isNotEmpty
            ? sortedUnivData[0].name_tanshuku
            : "カスタム駅伝";
        break;
      default:
        raceTitle = "不明な駅伝";
    }
    return [
      Text(
        raceTitle,
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        "コース編集",
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        "※試走は、現在あなたのチームの区間エントリーされている選手が走るものです。\n距離などコース内容の変更を試走に反映させるには、いったん保存する必要があります。\n走るたびに多少タイムは異なってきます。\n経験補正や調子・体調不良による補正は含まれません。1区の本番でのタイムは試走とは異なり集団走のペースに大きく左右されます。\n試走の有無は本番でのタイムに影響しません。",
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildKukanEditor(Ghensuu currentGhensuu, int i_kukan) {
    List<SenshuData> _getUnivFilteredSenshuData(
      List<SenshuData> allSenshuData,
      int myUnivId,
    ) {
      return allSenshuData
          .where(
            (s) =>
                s.univid == myUnivId &&
                s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                        1] !=
                    -2,
          )
          .toList();
    }

    List<SenshuData> _getGakunenJunUnivFilteredSenshuData(
      List<SenshuData> univFilteredSenshuData,
    ) {
      return univFilteredSenshuData.toList()..sort((a, b) {
        // gakunen (学年) を降順で比較
        final gakunenComparison = b.gakunen.compareTo(a.gakunen);

        // gakunen が同じ場合は id を昇順で比較
        if (gakunenComparison == 0) {
          return a.id.compareTo(b.id); // id は昇順
        }

        return gakunenComparison; // gakunen が異なる場合はその比較結果を返す
      });
    }

    final controllers = _controllers[i_kukan];
    final focusNodes = _focusNodes[i_kukan];
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    List<SenshuData> sortedsenshudata = senshudataBox.values.toList();
    sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));

    final List<SenshuData> univFilteredSenshuData = _getUnivFilteredSenshuData(
      sortedsenshudata,
      currentGhensuu.MYunivid,
    );
    final List<SenshuData> gakunenJunUnivFilteredSenshuData =
        _getGakunenJunUnivFilteredSenshuData(univFilteredSenshuData);

    int senshuid =
        gakunenJunUnivFilteredSenshuData[currentGhensuu
                .SenshuSelectedOption[i_kukan]]
            .id;
    if (senshuid < 0 || senshuid >= sortedsenshudata.length) {
      senshuid = 0;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "${i_kukan + 1}区",
                // ... スタイル ...
              ),
              const SizedBox(width: 8),
              Flexible(
                // テキストが長くなった場合に省略表示させる
                child: Text(
                  sortedsenshudata[senshuid].name +
                      "(" +
                      sortedsenshudata[senshuid].gakunen.toString() +
                      ")",
                  overflow: TextOverflow.ellipsis, // はみ出した部分を...で表示
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _isCalculating[i_kukan] = true;
                  });
                  final double estimatedTime = await _runTrialCalculation(
                    i_kukan,
                    currentGhensuu,
                  );
                  setState(() {
                    _kukanTrialTimes[i_kukan] = estimatedTime;
                    _isCalculating[i_kukan] = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('試走', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              if (_isCalculating[i_kukan])
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_kukanTrialTimes[i_kukan] != null)
                Text(
                  _formatTime(_kukanTrialTimes[i_kukan]!),
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          _buildTextField(
            label: "距離(m) 5000〜25000",
            controller: controllers[0],
            focusNode: focusNodes[0],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final intValue = int.tryParse(value ?? '');
              if (intValue == null || intValue < 5000 || intValue > 25000) {
                return '5000から25000の整数を入力してください';
              }
              return null;
            },
          ),
          _buildTextField(
            label: "登り距離割合 0.0〜1.0",
            controller: controllers[3],
            focusNode: focusNodes[3],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              final doubleValue = double.tryParse(value ?? '');
              if (doubleValue == null ||
                  doubleValue < 0.0 ||
                  doubleValue > 1.0) {
                return '0.0から1.0の間で入力してください';
              }
              return null;
            },
          ),
          _buildTextField(
            label: "登り平均勾配 0.0〜0.1",
            controller: controllers[1],
            focusNode: focusNodes[1],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              final doubleValue = double.tryParse(value ?? '');
              if (doubleValue == null ||
                  doubleValue < 0.0 ||
                  doubleValue > 0.1) {
                return '0.0から0.1の間で入力してください';
              }
              return null;
            },
          ),
          _buildTextField(
            label: "下り距離割合 0.0〜1.0",
            controller: controllers[4],
            focusNode: focusNodes[4],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              final doubleValue = double.tryParse(value ?? '');
              if (doubleValue == null ||
                  doubleValue < 0.0 ||
                  doubleValue > 1.0) {
                return '0.0から1.0の間で入力してください';
              }
              return null;
            },
          ),
          _buildTextField(
            label: "下り平均勾配  0.0〜0.1(マイナス不要)",
            controller: controllers[2],
            focusNode: focusNodes[2],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
            ],
            validator: (value) {
              final doubleValue = double.tryParse(value ?? '');
              if (doubleValue == null ||
                  doubleValue < 0.0 ||
                  doubleValue > 0.1) {
                return '0.0から0.1の間で入力してください';
              }
              return null;
            },
          ),
          _buildTextField(
            label: "アップダウン回数 0〜200",
            controller: controllers[5],
            focusNode: focusNodes[5],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final intValue = int.tryParse(value ?? '');
              if (intValue == null || intValue < 0 || intValue > 200) {
                return '0から200の整数を入力してください';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: HENSUU.textcolor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: HENSUU.textcolor.withOpacity(0.7)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildResetButton(Ghensuu currentGhensuu) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () {
            _resetToDefaults(currentGhensuu);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12.0),
          ),
          child: Text(
            "既定値に戻す",
            style: TextStyle(
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Ghensuu currentGhensuu) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final raceIndex = currentGhensuu.hyojiracebangou;
              bool hasCustomError = false;

              for (
                int i_kukan = 0;
                i_kukan < currentGhensuu.kukansuu_taikaigoto[raceIndex];
                i_kukan++
              ) {
                final controllers = _controllers[i_kukan];
                final double noboriWariai =
                    double.tryParse(controllers[3].text) ?? 0.0;
                final double kudariWariai =
                    double.tryParse(controllers[4].text) ?? 0.0;

                if (noboriWariai + kudariWariai > 1.0) {
                  hasCustomError = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${i_kukan + 1}区: 登り距離割合と下り距離割合の合計が1.0を超えています。',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  break;
                }
              }

              if (!hasCustomError) {
                _saveChanges(currentGhensuu);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('制限値を超えている項目があります。各項目を確認してください。'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12.0),
          ),
          child: Text(
            "保存",
            style: TextStyle(
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _saveChanges(Ghensuu currentGhensuu) async {
    // ローディングダイアログを表示
    // この `context` は `_saveChanges` メソッドのコンテキスト
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final raceIndex = currentGhensuu.hyojiracebangou;
    final int kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];

    for (int i_kukan = 0; i_kukan < kukanCount; i_kukan++) {
      final controllers = _controllers[i_kukan];

      currentGhensuu.kyori_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[0].text) ?? 0.0;
      currentGhensuu.heikinkoubainobori_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[1].text) ?? 0.0;
      currentGhensuu.heikinkoubaikudari_taikai_kukangoto[raceIndex][i_kukan] =
          -(double.tryParse(controllers[2].text) ?? 0.0);
      currentGhensuu.kyoriwariainobori_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[3].text) ?? 0.0;
      currentGhensuu.kyoriwariaikudari_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[4].text) ?? 0.0;
      currentGhensuu
              .noborikudarikirikaekaisuu_taikai_kukangoto[raceIndex][i_kukan] =
          int.tryParse(controllers[5].text) ?? 0;
    }

    try {
      await currentGhensuu.save();

      final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final univDataBox = Hive.box<UnivData>('univBox');
      final senshuDataBox = Hive.box<SenshuData>('senshuBox');
      final List<Ghensuu> gh = [ghensuuBox.getAt(0)!];
      List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
      sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

      List<int> kukanIDs = await EntryCalc(
        racebangou: raceIndex,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
      String kukanstring = "区間配置の検討順は\n";
      for (int i = 0; i < kukanIDs.length; i++) {
        kukanstring = kukanstring + "${kukanIDs[i] + 1}区 ";
      }
      // ローディングダイアログを閉じる
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('コース情報を保存し、区間配置をし直しました。\n$kukanstring'),
          backgroundColor: Colors.green,
        ),
      );

      // モーダル画面全体を閉じる
      Navigator.of(context).pop();
    } catch (e) {
      // エラー発生時もローディングダイアログを閉じる
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
      // エラー発生時もモーダル画面全体を閉じる
      Navigator.of(context).pop();
    }
  }

  void _resetToDefaults(Ghensuu currentGhensuu) async {
    // ------------------------------------
    // 確認ダイアログを表示
    final bool? shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認'),
          content: const Text(
            'コース情報を既定値に戻しますか？',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop(false); // falseを返して処理を中断
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true); // trueを返して処理を続行
              },
            ),
          ],
        );
      },
    );

    // ユーザーが「キャンセル」を選択した場合、処理を終了
    if (shouldProceed != true) {
      return;
    }
    // ------------------------------------

    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final raceIndex = currentGhensuu.hyojiracebangou;
    final List<double> defaultKyori = [];
    final List<double> defaultNoboriKoubai = [];
    final List<double> defaultKudariKoubai = [];
    final List<double> defaultNoboriWariai = [];
    final List<double> defaultKudariWariai = [];
    final List<int> defaultKirikaesiKaisuu = [];

    switch (raceIndex) {
      case 0:
        defaultKyori.addAll([8000, 5800, 8500, 6200, 6400, 10200]);
        defaultNoboriKoubai.addAll([0.1, 0.0, 0.0, 0.005, 0.01, 0.1]);
        defaultKudariKoubai.addAll([-0.1, 0.0, 0.0, 0.0, -0.01, -0.1]);
        defaultNoboriWariai.addAll([0.05, 0.0, 0.0, 0.5, 0.4, 0.05]);
        defaultKudariWariai.addAll([0.08, 0.0, 0.0, 0.0, 0.4, 0.05]);
        defaultKirikaesiKaisuu.addAll([4, 0, 0, 0, 50, 4]);
        break;
      case 1:
        defaultKyori.addAll([
          9500,
          11100,
          11900,
          11800,
          12400,
          12800,
          17600,
          19700,
        ]);
        defaultNoboriKoubai.addAll([
          0.01,
          0.01,
          0.01,
          0.01,
          0.01,
          0.0,
          0.01,
          0.02,
        ]);
        defaultKudariKoubai.addAll([
          -0.01,
          -0.01,
          -0.01,
          -0.01,
          -0.01,
          0.0,
          -0.01,
          -0.01,
        ]);
        defaultNoboriWariai.addAll([
          0.07,
          0.02,
          0.02,
          0.03,
          0.01,
          0.0,
          0.02,
          0.01,
        ]);
        defaultKudariWariai.addAll([
          0.1,
          0.02,
          0.02,
          0.02,
          0.03,
          0.0,
          0.01,
          0.015,
        ]);
        defaultKirikaesiKaisuu.addAll([30, 4, 40, 10, 7, 2, 8, 8]);
        break;
      case 2:
        defaultKyori.addAll([
          21300,
          23100,
          21400,
          20900,
          20800,
          20800,
          21300,
          21400,
          23100,
          23000,
        ]);
        defaultNoboriKoubai.addAll([
          0.01,
          0.02,
          0.0,
          0.02,
          0.06,
          0.06,
          0.01,
          0.0375,
          0.01,
          0.01,
        ]);
        defaultKudariKoubai.addAll([
          -0.01,
          -0.01,
          -0.0375,
          -0.01,
          -0.06,
          -0.06,
          -0.02,
          0.0,
          -0.02,
          -0.01,
        ]);
        defaultNoboriWariai.addAll([
          0.01,
          0.2,
          0.0,
          0.1,
          0.8,
          0.1,
          0.01,
          0.04,
          0.05,
          0.01,
        ]);
        defaultKudariWariai.addAll([
          0.01,
          0.05,
          0.04,
          0.01,
          0.1,
          0.8,
          0.1,
          0.0,
          0.2,
          0.01,
        ]);
        defaultKirikaesiKaisuu.addAll([4, 10, 4, 100, 4, 4, 100, 4, 10, 4]);
        break;
      case 5:
        // カスタム駅伝の既定値は現在の区間数に合わせて生成
        final kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];
        defaultKyori.addAll(List.generate(kukanCount, (_) => 10000.0));
        defaultNoboriKoubai.addAll(List.generate(kukanCount, (_) => 0.0));
        defaultKudariKoubai.addAll(List.generate(kukanCount, (_) => 0.0));
        defaultNoboriWariai.addAll(List.generate(kukanCount, (_) => 0.0));
        defaultKudariWariai.addAll(List.generate(kukanCount, (_) => 0.0));
        defaultKirikaesiKaisuu.addAll(List.generate(kukanCount, (_) => 0));
        break;
      default:
        Navigator.of(context).pop();
        return;
    }

    currentGhensuu.kyori_taikai_kukangoto[raceIndex] = defaultKyori;
    currentGhensuu.heikinkoubainobori_taikai_kukangoto[raceIndex] =
        defaultNoboriKoubai;
    currentGhensuu.heikinkoubaikudari_taikai_kukangoto[raceIndex] =
        defaultKudariKoubai;
    currentGhensuu.kyoriwariainobori_taikai_kukangoto[raceIndex] =
        defaultNoboriWariai;
    currentGhensuu.kyoriwariaikudari_taikai_kukangoto[raceIndex] =
        defaultKudariWariai;
    currentGhensuu.noborikudarikirikaekaisuu_taikai_kukangoto[raceIndex] =
        defaultKirikaesiKaisuu;

    // コントローラーを再初期化
    _initializeControllers(currentGhensuu);

    // setState を呼び出してUIを更新
    setState(() {});

    try {
      await currentGhensuu.save();

      final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final univDataBox = Hive.box<UnivData>('univBox');
      final senshuDataBox = Hive.box<SenshuData>('senshuBox');
      final List<Ghensuu> gh = [ghensuuBox.getAt(0)!];
      List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
      sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

      List<int> kukanIDs = await EntryCalc(
        racebangou: raceIndex,
        gh: gh,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
      String kukanstring = "区間配置の検討順は\n";
      for (int i = 0; i < kukanIDs.length; i++) {
        kukanstring = kukanstring + "${kukanIDs[i] + 1}区 ";
      }

      // ローディングダイアログを閉じる
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('コース情報を既定値に戻し保存し区間配置をし直しました。\n$kukanstring'),
          backgroundColor: Colors.green,
        ),
      );

      // モーダル画面全体を閉じる
      Navigator.of(context).pop();
    } catch (e) {
      // ローディングダイアログを閉じる
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );

      // モーダル画面全体を閉じる
      Navigator.of(context).pop();
    }
  }
}

class Mode0300Content extends StatefulWidget {
  final VoidCallback? onAdvanceMode; // 親画面へのモード遷移コールバック

  const Mode0300Content({super.key, this.onAdvanceMode});

  @override
  State<Mode0300Content> createState() => _Mode0300ContentState();
}

class _Mode0300ContentState extends State<Mode0300Content> {
  bool _isShowingModalCourseShoukai = false;
  bool _shorichuuFlag = false; // 処理中フラグ
  bool _showingAlert = false; // アラート表示フラグ
  bool _iscomputeLoading = false;

  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;

  // Pickerの選択状態を管理するリスト
  // GhensuuモデルのSenshuSelectedOption, SenshuSelectedOption2に対応
  // Ghensuuモデルのデータが直接更新されるため、_selectedOptionなどは不要

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
  }

  // MARK: - 計算プロパティに相当するヘルパー関数

  List<SenshuData> _getIdJunSenshuData(List<SenshuData> allSenshuData) {
    return allSenshuData.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  List<UnivData> _getIdJunUnivData(List<UnivData> allUnivData) {
    return allUnivData.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  List<SenshuData> _getUnivFilteredSenshuData(
    List<SenshuData> allSenshuData,
    int myUnivId,
  ) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    return allSenshuData
        .where(
          (s) =>
              s.univid == myUnivId &&
              s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                      1] !=
                  -2,
        )
        .toList();
  }

  List<SenshuData> _getGakunenJunUnivFilteredSenshuData(
    List<SenshuData> univFilteredSenshuData,
  ) {
    return univFilteredSenshuData.toList()..sort((a, b) {
      // gakunen (学年) を降順で比較
      final gakunenComparison = b.gakunen.compareTo(a.gakunen);

      // gakunen が同じ場合は id を昇順で比較
      if (gakunenComparison == 0) {
        return a.id.compareTo(b.id); // id は昇順
      }

      return gakunenComparison; // gakunen が異なる場合はその比較結果を返す
    });
  }

  // MARK: - メインロジック関数

  // 区間内順位を再計算する関数
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

  // とりあえず区間代入する関数
  Future<void> _toriaezuKukanDainyuu(
    Ghensuu currentGhensuu,
    List<SenshuData> gakunenJunUnivFilteredSenshuData,
  ) async {
    // まずすべての選手のentrykukan_raceをリセット
    for (var senshu in gakunenJunUnivFilteredSenshuData) {
      senshu.entrykukan_race[currentGhensuu.hyojiracebangou][senshu.gakunen -
              1] =
          -1;
      await senshu.save();
    }

    // `SenshuSelectedOption` と `SenshuSelectedOption2` に基づいて区間を割り当て
    if (currentGhensuu.hyojiracebangou == 3) {
      // 11月駅伝予選 (2人エントリー)
      for (
        int iKukan = 0;
        iKukan <
            currentGhensuu.kukansuu_taikaigoto[currentGhensuu.hyojiracebangou];
        iKukan++
      ) {
        // SenshuSelectedOptionとSenshuSelectedOption2は、gakunenJunUnivFilteredSenshuDataのインデックスを格納している
        final int selectedSenshuIndex1 =
            currentGhensuu.SenshuSelectedOption[iKukan];
        final int selectedSenshuIndex2 =
            currentGhensuu.SenshuSelectedOption2[iKukan];

        if (selectedSenshuIndex1 >= 0 &&
            selectedSenshuIndex1 < gakunenJunUnivFilteredSenshuData.length) {
          final senshu1 =
              gakunenJunUnivFilteredSenshuData[selectedSenshuIndex1];
          senshu1.entrykukan_race[currentGhensuu
                  .hyojiracebangou][senshu1.gakunen - 1] =
              iKukan;
          await senshu1.save();
        }
        if (selectedSenshuIndex2 >= 0 &&
            selectedSenshuIndex2 < gakunenJunUnivFilteredSenshuData.length) {
          final senshu2 =
              gakunenJunUnivFilteredSenshuData[selectedSenshuIndex2];
          senshu2.entrykukan_race[currentGhensuu
                  .hyojiracebangou][senshu2.gakunen - 1] =
              iKukan;
          await senshu2.save();
        }
      }
    } else {
      // その他の大会 (1人エントリー)
      for (
        int iKukan = 0;
        iKukan <
            currentGhensuu.kukansuu_taikaigoto[currentGhensuu.hyojiracebangou];
        iKukan++
      ) {
        final int selectedSenshuIndex =
            currentGhensuu.SenshuSelectedOption[iKukan];
        if (selectedSenshuIndex >= 0 &&
            selectedSenshuIndex < gakunenJunUnivFilteredSenshuData.length) {
          final senshu = gakunenJunUnivFilteredSenshuData[selectedSenshuIndex];
          senshu.entrykukan_race[currentGhensuu
                  .hyojiracebangou][senshu.gakunen - 1] =
              iKukan;
          await senshu.save();
        }
      }
    }
  }

  // 選手詳細モーダルを呼び出す共通関数
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

  // MARK: - ビルドメソッド

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body:
          // ← ここにSafeAreaを追加します
          ValueListenableBuilder<Box<Ghensuu>>(
            valueListenable: _ghensuuBox.listenable(),
            builder: (context, ghensuuBox, _) {
              final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');

              if (currentGhensuu == null) {
                return const Center(
                  child: CircularProgressIndicator(color: HENSUU.textcolor),
                );
              }

              return ValueListenableBuilder<Box<SenshuData>>(
                valueListenable: _senshuBox.listenable(),
                builder: (context, senshuDataBox, _) {
                  final List<SenshuData> allSenshuData = senshuDataBox.values
                      .toList();
                  final List<SenshuData> idJunSenshuData = _getIdJunSenshuData(
                    allSenshuData,
                  );
                  final List<SenshuData> univFilteredSenshuData =
                      _getUnivFilteredSenshuData(
                        allSenshuData,
                        currentGhensuu.MYunivid,
                      );
                  final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                      _getGakunenJunUnivFilteredSenshuData(
                        univFilteredSenshuData,
                      );

                  return ValueListenableBuilder<Box<UnivData>>(
                    valueListenable: _univBox.listenable(),
                    builder: (context, univDataBox, _) {
                      final List<UnivData> allUnivData = univDataBox.values
                          .toList();
                      final List<UnivData> idJunUnivData = _getIdJunUnivData(
                        allUnivData,
                      );

                      // 進むボタンのロジック
                      void advanceAction() async {
                        setState(() {
                          _shorichuuFlag = true; // 処理中フラグを立てる
                        });

                        // 区間代入を実行
                        await _toriaezuKukanDainyuu(
                          currentGhensuu,
                          gakunenJunUnivFilteredSenshuData,
                        );

                        // エントリー区間の重複や空白チェック
                        List<int> entrySuuKukanGoto = List.filled(
                          currentGhensuu.kukansuu_taikaigoto[currentGhensuu
                              .hyojiracebangou],
                          0,
                        );
                        for (var senshu in gakunenJunUnivFilteredSenshuData) {
                          final int entryKukan =
                              senshu.entrykukan_race[currentGhensuu
                                  .hyojiracebangou][senshu.gakunen - 1];
                          if (entryKukan > -1 &&
                              entryKukan < entrySuuKukanGoto.length) {
                            entrySuuKukanGoto[entryKukan]++;
                          }
                        }

                        int ninzuuKukanGoto =
                            (currentGhensuu.hyojiracebangou == 3)
                            ? 2
                            : 1; // 11月駅伝予選は2人、他は1人

                        bool dameFlag = false;
                        for (int count in entrySuuKukanGoto) {
                          if (count != ninzuuKukanGoto) {
                            dameFlag = true;
                            break;
                          }
                        }

                        if (currentGhensuu.hyojiracebangou <= 2 ||
                            currentGhensuu.hyojiracebangou == 5) {
                          int kaeri = checkEkidenEntries(
                            racebangou: currentGhensuu.hyojiracebangou,
                            ghensuu: currentGhensuu,
                            sortedSenshuData: idJunSenshuData,
                            sortedUnivData: idJunUnivData,
                          );
                          if (kaeri >= 0) {
                            dameFlag = true;
                            dameunivid = kaeri;
                          }
                        }

                        if (dameFlag) {
                          setState(() {
                            _shorichuuFlag = false;
                            _showingAlert = true; // アラートを表示
                          });
                        } else {
                          // OKなら区間内順位再計算
                          await _kukannaiJunSaikeisan(
                            currentGhensuu,
                            idJunSenshuData,
                          );

                          // モードを進める
                          //currentGhensuu.mode = 350;
                          //await currentGhensuu.save(); // Ghensuuの変更を保存

                          setState(() {
                            _shorichuuFlag = false;
                          });

                          widget.onAdvanceMode?.call(); // 親画面にモード変更を通知
                        }
                      }

                      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
                      final KantokuData kantoku = kantokuBox.get(
                        'KantokuData',
                      )!;

                      return Column(
                        children: [
                          // MARK: ヘッダー部分
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              // Rowを使って全体を左右に配置
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween, // 両端に配置
                              children: [
                                Expanded(
                                  // Add Expanded to allow the Column to take available space
                                  child: Column(
                                    // テキストを左寄せで2行にまとめる
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start, // 左寄せ
                                    children: [
                                      Row(
                                        // 1行目のテキスト
                                        children: [
                                          Text(
                                            currentGhensuu.kazeflag == 0
                                                ? "鬼"
                                                : currentGhensuu.kazeflag == 1
                                                ? "難"
                                                : currentGhensuu.kazeflag == 2
                                                ? "普"
                                                : "易",
                                            style: const TextStyle(
                                              color: HENSUU.textcolor,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ), // テキスト間のスペース
                                          Expanded(
                                            // Allow the date text to truncate
                                            child: Text(
                                              "${currentGhensuu.year}年${currentGhensuu.month}月${TimeDate.dayToString(currentGhensuu.day)}",
                                              style: const TextStyle(
                                                color: HENSUU.textcolor,
                                              ),
                                              overflow: TextOverflow
                                                  .ellipsis, // Add ellipsis for overflow
                                              maxLines:
                                                  1, // Ensure it's a single line
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
                                _shorichuuFlag || _iscomputeLoading
                                    ? Text("処理中")
                                    : ElevatedButton(
                                        // ボタンを右に配置
                                        onPressed: advanceAction, // アクションを呼び出す
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: HENSUU.buttonColor,
                                          foregroundColor:
                                              HENSUU.buttonTextColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          minimumSize: Size
                                              .zero, // サイズが自動調整されるように最小サイズを0に
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontSize: HENSUU.fontsize_honbun,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: const Text("進む＞＞"),
                                      ),
                              ],
                            ),
                          ),
                          // アラートの表示
                          if (_showingAlert)
                            AlertDialog(
                              /*title: const Text(
                            "ご確認ください",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                            ), // フォントサイズを小さく
                            textAlign: TextAlign.center, // タイトルを中央揃えにすることも検討
                          ),*/
                              // contentPaddingをさらに調整して、全体的にパディングを減らす
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10.0,
                              ), // 上下左右のパディングを均等に減らす
                              content: Text(
                                "${idJunUnivData[dameunivid].name}:区間配置に重複か空白区間があります",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.0,
                                ), // フォントサイズを小さく
                                textAlign:
                                    TextAlign.center, // テキストを中央揃えにすることも検討
                              ),
                              actionsPadding: const EdgeInsets.fromLTRB(
                                8.0,
                                0.0,
                                8.0,
                                8.0,
                              ), // ボタンのパディングを調整
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showingAlert = false;
                                    });
                                    // Navigator.of(context).pop(); // AlertDialogを閉じる場合はこれを使う
                                  },
                                  child: const Text(
                                    "OK",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                    ), // ボタンのフォントサイズも調整
                                  ),
                                ),
                              ],
                            ),
                          const Divider(color: HENSUU.textcolor),

                          // MARK: 処理中表示 または メインコンテンツ
                          _shorichuuFlag || _iscomputeLoading
                              ? Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: HENSUU.buttonColor,
                                        ),
                                        const SizedBox(height: 16),
                                        _iscomputeLoading
                                            ? Text(
                                                "お待ちください\n自分の大学の選手全員が全区間を試走し、その結果から最速となる組み合わせを見つけるものです。\n非常に時間がかかる可能性があります",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              )
                                            : Text(
                                                "選手が所定の位置に向かっています\nお待ちください",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: HENSUU.textcolor,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 大会名表示
                                      _buildRaceName(
                                        currentGhensuu.hyojiracebangou,
                                      ),
                                      const SizedBox(height: 8),
                                      if (currentGhensuu.hyojiracebangou != 3)
                                        const Text(
                                          "区間エントリー決定画面",
                                          style: TextStyle(
                                            color: HENSUU.textcolor,
                                          ),
                                        ),
                                      if (currentGhensuu.hyojiracebangou == 3)
                                        const Text(
                                          "エントリー決定画面",
                                          style: TextStyle(
                                            color: HENSUU.textcolor,
                                          ),
                                        ),
                                      /*Text(
                                        "目標順位:${idJunUnivData[currentGhensuu.MYunivid].mokuhyojuni[currentGhensuu.hyojiracebangou] + 1}位",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                      ),*/
                                      // 区間コース確認ボタン (モーダル表示)
                                      //LinkButtons(),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              //区間配置が失敗し、再配置した場合のメッセージ表示
                                              if (kantoku.yobiint2[22] == 1)
                                                Text(
                                                  "※自動区間配置に一度失敗したので、最適解区間配置を使わないで再配置をしました。区間重複や空白区間がないことをチェック済みです。\n",
                                                ),
                                              if (kantoku.yobiint2[22] == 2)
                                                Text(
                                                  "※自動区間配置に一度失敗したので、最適解区間配置を使わないで再配置を試みましたが。それにも失敗してしまいました。\n",
                                                ),
                                              // LinkButtons()をここに追加
                                              LinkButtons(
                                                currentGhensuu.hyojiracebangou,
                                              ),

                                              /*(currentGhensuu.hyojiracebangou ==
                                                          0 ||
                                                      currentGhensuu
                                                              .hyojiracebangou ==
                                                          1 ||
                                                      currentGhensuu
                                                              .hyojiracebangou ==
                                                          2 ||
                                                      currentGhensuu
                                                              .hyojiracebangou ==
                                                          5)
                                                  ? TextButton(
                                                      onPressed:
                                                          _iscomputeLoading
                                                          ? null // ローディング中はボタンを無効化
                                                          : () async {
                                                              final bool?
                                                              shouldProceed = await showDialog<bool>(
                                                                context:
                                                                    context,
                                                                barrierDismissible:
                                                                    false,
                                                                builder:
                                                                    (
                                                                      BuildContext
                                                                      context,
                                                                    ) {
                                                                      return AlertDialog(
                                                                        title: const Text(
                                                                          '確認',
                                                                        ),
                                                                        content: const Text(
                                                                          '試走はやるたびにタイムが異なるので配置も毎回異なる可能性があります。\n経験補正は考慮されませんし、1区の展開も読めません。目標順位を下回った場合のタイム損も考慮されません。',
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        actions:
                                                                            <
                                                                              Widget
                                                                            >[
                                                                              TextButton(
                                                                                child: const Text(
                                                                                  'キャンセル',
                                                                                ),
                                                                                onPressed: () {
                                                                                  Navigator.of(
                                                                                    context,
                                                                                  ).pop(
                                                                                    false,
                                                                                  ); // falseを返して処理を中断
                                                                                },
                                                                              ),
                                                                              TextButton(
                                                                                child: const Text(
                                                                                  'OK',
                                                                                ),
                                                                                onPressed: () {
                                                                                  Navigator.of(
                                                                                    context,
                                                                                  ).pop(
                                                                                    true,
                                                                                  ); // trueを返して処理を続行
                                                                                },
                                                                              ),
                                                                            ],
                                                                      );
                                                                    },
                                                              );

                                                              // ユーザーが「キャンセル」を選択した場合、処理を終了
                                                              if (shouldProceed !=
                                                                  true) {
                                                              } else {
                                                                // 処理開始: ローディング状態をtrueに
                                                                setState(() {
                                                                  _iscomputeLoading =
                                                                      true;
                                                                });
                                                                // 必要なデータをここで取得し、computeに渡す
                                                                final Box<
                                                                  Ghensuu
                                                                >
                                                                ghensuuBox =
                                                                    Hive.box<
                                                                      Ghensuu
                                                                    >(
                                                                      'ghensuuBox',
                                                                    );
                                                                final Ghensuu
                                                                currentGhensuu =
                                                                    ghensuuBox.get(
                                                                      'global_ghensuu',
                                                                    )!;
                                                                int
                                                                targetunivid =
                                                                    currentGhensuu
                                                                        .MYunivid;
                                                                int
                                                                NUMBER_OF_KUKAN =
                                                                    currentGhensuu
                                                                        .kukansuu_taikaigoto[currentGhensuu
                                                                        .hyojiracebangou];
                                                                //final hivePath =
                                                                //    await getApplicationDocumentsDirectory();
                                                                List<SenshuData>
                                                                sortedSenshuData =
                                                                    senshuDataBox
                                                                        .values
                                                                        .toList();
                                                                sortedSenshuData
                                                                    .sort(
                                                                      (
                                                                        a,
                                                                        b,
                                                                      ) => a.id
                                                                          .compareTo(
                                                                            b.id,
                                                                          ),
                                                                    );

                                                                try {
                                                                  /*print(
                                                                    "findFastestTeam関数呼び出し",
                                                                  );
                                                                  // findFastestTeamに直接引数を渡す
                                                                  final result = await compute(
                                                                    findFastestTeam,
                                                                    [
                                                                      hivePath
                                                                          .path,
                                                                      targetunivid,
                                                                      NUMBER_OF_KUKAN,
                                                                      //playerIds, // ここでplayerIdsを追加
                                                                    ],
                                                                  );
                                                                  print(
                                                                    "findFastestTeam関数から戻ってきた！！",
                                                                  );*/

                                                                  print(
                                                                    "findFastestTeam関数呼び出さない処理",
                                                                  );
                                                                  //targetunividとNUMBER_OF_KUKANが必要
                                                                  final List<
                                                                    SenshuData
                                                                  >
                                                                  univFilteredSenshuData = sortedSenshuData
                                                                      .where(
                                                                        (s) =>
                                                                            s.univid ==
                                                                                targetunivid &&
                                                                            s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                                                                                    1] >=
                                                                                -1,
                                                                      )
                                                                      .toList();
                                                                  if (univFilteredSenshuData
                                                                          .length <
                                                                      NUMBER_OF_KUKAN) {
                                                                    throw Exception(
                                                                      '区間数分の選手がいません。',
                                                                    );
                                                                  }
                                                                  final List<
                                                                    int
                                                                  >
                                                                  playerIds = univFilteredSenshuData
                                                                      .map(
                                                                        (s) => s
                                                                            .id,
                                                                      )
                                                                      .toList();
                                                                  final int
                                                                  playerCount =
                                                                      playerIds
                                                                          .length;
                                                                  // 1. 試走タイムを事前に計算してキャッシュ
                                                                  final Map<
                                                                    int,
                                                                    Map<
                                                                      int,
                                                                      double
                                                                    >
                                                                  >
                                                                  trialTimesCache =
                                                                      {};
                                                                  for (final int
                                                                      playerId
                                                                      in playerIds) {
                                                                    trialTimesCache[playerId] =
                                                                        {};
                                                                    for (
                                                                      int
                                                                      kukanIndex =
                                                                          0;
                                                                      kukanIndex <
                                                                          NUMBER_OF_KUKAN;
                                                                      kukanIndex++
                                                                    ) {
                                                                      final double
                                                                      time = await runTrialCalculation(
                                                                        playerId,
                                                                        kukanIndex,
                                                                      );
                                                                      trialTimesCache[playerId]![kukanIndex] =
                                                                          time;
                                                                    }
                                                                  }
                                                                  // 2. 動的計画法による最適配置の探索（ビットマスクを使用）
                                                                  // dp[k][mask] = k区間目までで、選手集合maskを使用したときの最小タイム
                                                                  final List<
                                                                    Map<
                                                                      int,
                                                                      double
                                                                    >
                                                                  >
                                                                  dp = List.generate(
                                                                    NUMBER_OF_KUKAN +
                                                                        1,
                                                                    (_) => {},
                                                                  );
                                                                  // parent[k][mask] = k区間目で配置した選手インデックス
                                                                  final List<
                                                                    Map<
                                                                      int,
                                                                      int
                                                                    >
                                                                  >
                                                                  parent =
                                                                      List.generate(
                                                                        NUMBER_OF_KUKAN +
                                                                            1,
                                                                        (_) =>
                                                                            {},
                                                                      );
                                                                  // 初期化: 0区間目、選手不使用のマスク
                                                                  dp[0][0] =
                                                                      0.0;
                                                                  // ループでDPテーブルを埋めていく
                                                                  for (
                                                                    int kukan =
                                                                        1;
                                                                    kukan <=
                                                                        NUMBER_OF_KUKAN;
                                                                    kukan++
                                                                  ) {
                                                                    final int
                                                                    prevKukan =
                                                                        kukan -
                                                                        1;
                                                                    for (final prevMask
                                                                        in dp[prevKukan]
                                                                            .keys) {
                                                                      // 過去に使用した選手を特定
                                                                      for (
                                                                        int
                                                                        currentPlayerIdx =
                                                                            0;
                                                                        currentPlayerIdx <
                                                                            playerCount;
                                                                        currentPlayerIdx++
                                                                      ) {
                                                                        // currentPlayerIdx (選手インデックス)に対応するビット
                                                                        final int
                                                                        currentMaskBit =
                                                                            1 <<
                                                                            currentPlayerIdx;
                                                                        // 選手が既に使用されているかチェック
                                                                        if ((prevMask &
                                                                                currentMaskBit) ==
                                                                            0) {
                                                                          // 未使用の場合、選手を配置可能
                                                                          final int
                                                                          newMask =
                                                                              prevMask |
                                                                              currentMaskBit;
                                                                          final double
                                                                          currentTime =
                                                                              trialTimesCache[playerIds[currentPlayerIdx]]![kukan -
                                                                                  1]!;
                                                                          final double
                                                                          totalTime =
                                                                              dp[prevKukan][prevMask]! +
                                                                              currentTime;
                                                                          // 新しいマスクでの最小タイムを更新
                                                                          if (totalTime <
                                                                              (dp[kukan][newMask] ??
                                                                                  double.infinity)) {
                                                                            dp[kukan][newMask] =
                                                                                totalTime;
                                                                            parent[kukan][newMask] =
                                                                                currentPlayerIdx;
                                                                          }
                                                                        }
                                                                      }
                                                                    }
                                                                  }
                                                                  // 3. 最後の区間までの最適な合計タイムと組み合わせを逆順でたどる
                                                                  double
                                                                  fastestTotalTime =
                                                                      double
                                                                          .infinity;
                                                                  int
                                                                  finalMask =
                                                                      -1;
                                                                  final int
                                                                  finalKukan =
                                                                      NUMBER_OF_KUKAN;
                                                                  for (final mask
                                                                      in dp[finalKukan]
                                                                          .keys) {
                                                                    if (dp[finalKukan][mask]! <
                                                                        fastestTotalTime) {
                                                                      fastestTotalTime =
                                                                          dp[finalKukan][mask]!;
                                                                      finalMask =
                                                                          mask;
                                                                    }
                                                                  }
                                                                  final List<
                                                                    int
                                                                  >
                                                                  fastestPlayerIds_notheiretu =
                                                                      [];
                                                                  int
                                                                  currentMask =
                                                                      finalMask;
                                                                  for (
                                                                    int kukan =
                                                                        NUMBER_OF_KUKAN;
                                                                    kukan >= 1;
                                                                    kukan--
                                                                  ) {
                                                                    final int
                                                                    currentPlayerIdx =
                                                                        parent[kukan][currentMask]!;
                                                                    final int
                                                                    currentPlayerId =
                                                                        playerIds[currentPlayerIdx];
                                                                    fastestPlayerIds_notheiretu
                                                                        .insert(
                                                                          0,
                                                                          currentPlayerId,
                                                                        );
                                                                    // 現在の選手をマスクから外して、前の状態のマスクを計算
                                                                    currentMask =
                                                                        currentMask ^
                                                                        (1 <<
                                                                            currentPlayerIdx);
                                                                  }
                                                                  print(
                                                                    "最速の組み合わせ探索終了！！(並列処理じゃない版)",
                                                                  );
                                                                  //return {
                                                                  //  'fastestTotalTime': fastestTotalTime,
                                                                  //  'fastestPlayerIds': fastestPlayerIds,
                                                                  //};
                                                                  print(
                                                                    "findFastestTeam関数呼び出さない処理終了",
                                                                  );

                                                                  // 結果から最適な選手配置リストを取得
                                                                  List<int>
                                                                  fastestPlayerIds =
                                                                      [];
                                                                  fastestPlayerIds =
                                                                      fastestPlayerIds_notheiretu; //並列じゃない処理版
                                                                  //fastestPlayerIds = result['fastestPlayerIds'];//並列処理用版
                                                                  for (
                                                                    int
                                                                    i_kukan = 0;
                                                                    i_kukan <
                                                                        currentGhensuu
                                                                            .kukansuu_taikaigoto[currentGhensuu
                                                                            .hyojiracebangou];
                                                                    i_kukan++
                                                                  ) {
                                                                    for (
                                                                      int i = 0;
                                                                      i <
                                                                          gakunenJunUnivFilteredSenshuData
                                                                              .length;
                                                                      i++
                                                                    ) {
                                                                      if (gakunenJunUnivFilteredSenshuData[i]
                                                                              .id ==
                                                                          fastestPlayerIds[i_kukan]) {
                                                                        currentGhensuu.SenshuSelectedOption[i_kukan] =
                                                                            i;
                                                                        break;
                                                                      }
                                                                    }
                                                                  }
                                                                  await currentGhensuu
                                                                      .save();
                                                                  // 成功メッセージ
                                                                  // ✅ 成功メッセージもmountedチェックで囲む
                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              '最適解区間配置を行いました！',
                                                                            ),
                                                                        duration: Duration(
                                                                          seconds:
                                                                              3,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                } catch (e) {
                                                                  // エラー処理
                                                                  print(
                                                                    'エラーが発生しました: $e',
                                                                  );
                                                                  // ✅ エラーメッセージもmountedチェックで囲む
                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              '最適な選手配置の計算中にエラーが発生しました。',
                                                                            ),
                                                                      ),
                                                                    );
                                                                  }
                                                                } finally {
                                                                  // 処理完了: ローディング状態をfalseに
                                                                  // ⚠️ ウィジェットがまだマウントされているか確認する
                                                                  if (mounted) {
                                                                    setState(() {
                                                                      _iscomputeLoading =
                                                                          false;
                                                                    });

                                                                    // ダイアログもまだ開いていれば閉じる
                                                                    if (Navigator.of(
                                                                      context,
                                                                    ).canPop()) {
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop();
                                                                    }
                                                                  }
                                                                }
                                                              }
                                                            },
                                                      child: Text(
                                                        "最適解区間配置",
                                                        style: TextStyle(
                                                          color:
                                                              _iscomputeLoading
                                                              ? Colors
                                                                    .grey // 無効化されたボタンの色
                                                              : const Color.fromARGB(
                                                                  255,
                                                                  0,
                                                                  255,
                                                                  0,
                                                                ),
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationColor:
                                                              HENSUU.textcolor,
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),*/
                                              ...List.generate(
                                                currentGhensuu
                                                    .kukansuu_taikaigoto[currentGhensuu
                                                    .hyojiracebangou],
                                                (iKukan) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4.0,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // 1行目に「組目/区」と「距離」を配置
                                                        Row(
                                                          children: [
                                                            Text(
                                                              currentGhensuu
                                                                          .hyojiracebangou ==
                                                                      3
                                                                  ? "${iKukan + 1}組目"
                                                                  : "${iKukan + 1}区",
                                                              style: TextStyle(
                                                                color: HENSUU
                                                                    .textcolor,
                                                              ),
                                                              softWrap: false,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              "${currentGhensuu.kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][iKukan].toStringAsFixed(0)}m",
                                                              style: TextStyle(
                                                                color: HENSUU
                                                                    .textcolor,
                                                              ),
                                                              softWrap: false,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                        // 2行目に選手選択ドロップダウン1を配置（単独行）
                                                        Container(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: DropdownButton<int>(
                                                            isExpanded:
                                                                true, // ドロップダウンが横幅いっぱいに広がるように設定
                                                            value: currentGhensuu
                                                                .SenshuSelectedOption[iKukan],
                                                            //dropdownColor: HENSUU
                                                            //    .backgroundcolor,
                                                            dropdownColor:
                                                                Color.fromARGB(
                                                                  255,
                                                                  30,
                                                                  30,
                                                                  30,
                                                                ),
                                                            style: TextStyle(
                                                              color: HENSUU
                                                                  .textcolor,
                                                            ),
                                                            iconEnabledColor:
                                                                HENSUU
                                                                    .textcolor,
                                                            onChanged: (int? newValue) async {
                                                              if (newValue !=
                                                                  null) {
                                                                // 「キャンセル」が選択された場合は何もしない
                                                                if (newValue ==
                                                                    -1) {
                                                                  // キャンセルの値を -1 と仮定
                                                                  return;
                                                                }

                                                                currentGhensuu
                                                                        .SenshuSelectedOption[iKukan] =
                                                                    newValue;
                                                                await currentGhensuu
                                                                    .save();
                                                              }
                                                            },
                                                            items: [
                                                              // --- キャンセルオプションの追加 ---
                                                              DropdownMenuItem<
                                                                int
                                                              >(
                                                                value:
                                                                    -1, // キャンセル用の特別な値
                                                                child: Row(
                                                                  children: [
                                                                    // キャンセルオプションにはチェックマークは表示しない
                                                                    Expanded(
                                                                      child: Text(
                                                                        "キャンセル",
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              HENSUU.fontsize_honbun,
                                                                          color:
                                                                              HENSUU.LinkColor, // 他の項目と同じ色
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              // --- 既存の選手リストの生成 ---
                                                              ...List.generate(
                                                                // スプレッド演算子 (...) を使ってリストを結合
                                                                gakunenJunUnivFilteredSenshuData
                                                                    .length,
                                                                (index) {
                                                                  final senshu =
                                                                      gakunenJunUnivFilteredSenshuData[index];
                                                                  // 現在選択されている選手かどうかを判定
                                                                  final isSelected =
                                                                      currentGhensuu
                                                                          .SenshuSelectedOption[iKukan] ==
                                                                      index;

                                                                  return DropdownMenuItem<
                                                                    int
                                                                  >(
                                                                    value:
                                                                        index,
                                                                    child: Row(
                                                                      children: [
                                                                        // 選択されている場合にチェックマークを表示
                                                                        if (isSelected)
                                                                          Icon(
                                                                            Icons.check, // チェックマークアイコン
                                                                            color:
                                                                                HENSUU.LinkColor, // アイコンの色
                                                                            //.textcolor,
                                                                            size:
                                                                                HENSUU.fontsize_honbun, // アイコンのサイズをテキストに合わせる
                                                                          ),
                                                                        if (isSelected)
                                                                          SizedBox(
                                                                            width:
                                                                                8,
                                                                          ), // アイコンとテキストの間のスペース
                                                                        if (currentGhensuu.hyojiracebangou <=
                                                                                2 ||
                                                                            currentGhensuu.hyojiracebangou ==
                                                                                5)
                                                                          (senshu.chousi >
                                                                                  0)
                                                                              ? Expanded(
                                                                                  child: Text(
                                                                                    "${senshu.name} (${senshu.gakunen}年) 調子${senshu.chousi}",
                                                                                    style: TextStyle(
                                                                                      fontSize: HENSUU.fontsize_honbun,
                                                                                      color: HENSUU.LinkColor,
                                                                                      //.textcolor,
                                                                                    ),
                                                                                    maxLines: 2,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                )
                                                                              : Expanded(
                                                                                  child: Text(
                                                                                    "【体調不良】${senshu.name} (${senshu.gakunen}年)",
                                                                                    style: TextStyle(
                                                                                      fontSize: HENSUU.fontsize_honbun,
                                                                                      color: HENSUU.LinkColor,
                                                                                      //.textcolor,
                                                                                    ),
                                                                                    maxLines: 2,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                )
                                                                        else
                                                                          Expanded(
                                                                            child: Text(
                                                                              "${senshu.name} (${senshu.gakunen}年)",
                                                                              style: TextStyle(
                                                                                fontSize: HENSUU.fontsize_honbun,
                                                                                color: HENSUU.LinkColor,
                                                                                //.textcolor,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (currentGhensuu
                                                                .hyojiracebangou ==
                                                            3)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    currentGhensuu.hyojiracebangou ==
                                                                            3
                                                                        ? "${iKukan + 1}組目"
                                                                        : "${iKukan + 1}区",
                                                                    style: TextStyle(
                                                                      color: HENSUU
                                                                          .textcolor,
                                                                    ),
                                                                    softWrap:
                                                                        false,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    "${currentGhensuu.kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][iKukan].toStringAsFixed(0)}m",
                                                                    style: TextStyle(
                                                                      color: HENSUU
                                                                          .textcolor,
                                                                    ),
                                                                    softWrap:
                                                                        false,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                              // 2行目に選手選択ドロップダウン2を配置（単独行）
                                                              Container(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: DropdownButton<int>(
                                                                  isExpanded:
                                                                      true, // ドロップダウンが横幅いっぱいに広がるように設定
                                                                  value: currentGhensuu
                                                                      .SenshuSelectedOption2[iKukan], // 選手選択オプション2を使用
                                                                  //dropdownColor: HENSUU
                                                                  //    .backgroundcolor,
                                                                  dropdownColor:
                                                                      Color.fromARGB(
                                                                        255,
                                                                        30,
                                                                        30,
                                                                        30,
                                                                      ),
                                                                  style: TextStyle(
                                                                    color: HENSUU
                                                                        .textcolor,
                                                                  ),
                                                                  iconEnabledColor:
                                                                      HENSUU
                                                                          .textcolor,
                                                                  onChanged:
                                                                      (
                                                                        int?
                                                                        newValue,
                                                                      ) async {
                                                                        if (newValue !=
                                                                            null) {
                                                                          // 「キャンセル」が選択された場合は何もしない
                                                                          if (newValue ==
                                                                              -1) {
                                                                            // キャンセルの値を -1 と仮定
                                                                            return;
                                                                          }

                                                                          currentGhensuu.SenshuSelectedOption2[iKukan] =
                                                                              newValue; // 選手選択オプション2を更新
                                                                          await currentGhensuu
                                                                              .save();
                                                                        }
                                                                      },
                                                                  items: [
                                                                    // --- キャンセルオプションの追加 ---
                                                                    DropdownMenuItem<
                                                                      int
                                                                    >(
                                                                      value:
                                                                          -1, // キャンセル用の特別な値
                                                                      child: Row(
                                                                        children: [
                                                                          // キャンセルオプションにはチェックマークは表示しない
                                                                          Expanded(
                                                                            child: Text(
                                                                              "キャンセル",
                                                                              style: TextStyle(
                                                                                fontSize: HENSUU.fontsize_honbun,
                                                                                color: HENSUU.LinkColor, // 他の項目と同じ色
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    // --- 既存の選手リストの生成 ---
                                                                    ...List.generate(
                                                                      // スプレッド演算子 (...) を使ってリストを結合
                                                                      gakunenJunUnivFilteredSenshuData
                                                                          .length,
                                                                      (index) {
                                                                        final senshu =
                                                                            gakunenJunUnivFilteredSenshuData[index];
                                                                        // 現在選択されている選手かどうかを判定 (SenshuSelectedOption2を使用)
                                                                        final isSelected =
                                                                            currentGhensuu.SenshuSelectedOption2[iKukan] ==
                                                                            index;

                                                                        return DropdownMenuItem<
                                                                          int
                                                                        >(
                                                                          value:
                                                                              index,
                                                                          child: Row(
                                                                            // Rowを使ってアイコンとテキストを横並びにする
                                                                            children: [
                                                                              // 選択されている場合にチェックマークを表示
                                                                              if (isSelected)
                                                                                Icon(
                                                                                  Icons.check, // チェックマークアイコン
                                                                                  color: HENSUU.LinkColor, // アイコンの色
                                                                                  size: HENSUU.fontsize_honbun, // アイコンのサイズをテキストに合わせる
                                                                                ),
                                                                              if (isSelected)
                                                                                SizedBox(
                                                                                  width: 8,
                                                                                ), // アイコンとテキストの間のスペース
                                                                              if (currentGhensuu.hyojiracebangou <=
                                                                                      2 ||
                                                                                  currentGhensuu.hyojiracebangou ==
                                                                                      5)
                                                                                (senshu.chousi >
                                                                                        0)
                                                                                    ? Expanded(
                                                                                        // テキストが長くなってもはみ出さないようにExpandedで囲む
                                                                                        child: Text(
                                                                                          "${senshu.name} (${senshu.gakunen}年) 調子${senshu.chousi}",
                                                                                          style: TextStyle(
                                                                                            fontSize: HENSUU.fontsize_honbun,
                                                                                            color: HENSUU.LinkColor,
                                                                                          ),
                                                                                          maxLines: 2,
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                      )
                                                                                    : Expanded(
                                                                                        // テキストが長くなってもはみ出さないようにExpandedで囲む
                                                                                        child: Text(
                                                                                          "【体調不良】${senshu.name} (${senshu.gakunen}年)",
                                                                                          style: TextStyle(
                                                                                            fontSize: HENSUU.fontsize_honbun,
                                                                                            color: HENSUU.LinkColor,
                                                                                          ),
                                                                                          maxLines: 2,
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                      )
                                                                              else
                                                                                Expanded(
                                                                                  // テキストが長くなってもはみ出さないようにExpandedで囲む
                                                                                  child: Text(
                                                                                    "${senshu.name} (${senshu.gakunen}年)",
                                                                                    style: TextStyle(
                                                                                      fontSize: HENSUU.fontsize_honbun,
                                                                                      color: HENSUU.LinkColor,
                                                                                    ),
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),

                                              const SizedBox(height: 20),
                                              const Divider(
                                                color: Colors.white,
                                              ),
                                              if (currentGhensuu
                                                          .hyojiracebangou <=
                                                      2 ||
                                                  currentGhensuu
                                                          .hyojiracebangou ==
                                                      5)
                                                // --- 選手の調子確認リスト ---
                                                Text(
                                                  '選手調子一覧',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              const SizedBox(height: 8),
                                              if (currentGhensuu
                                                          .hyojiracebangou <=
                                                      2 ||
                                                  currentGhensuu
                                                          .hyojiracebangou ==
                                                      5)
                                                Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: gakunenJunUnivFilteredSenshuData.map((
                                                    hoken,
                                                  ) {
                                                    int entrykukannumber = -1;
                                                    String entrykukannumberstr =
                                                        "補 ";
                                                    for (
                                                      int i_kukan = 0;
                                                      i_kukan <
                                                          currentGhensuu
                                                              .kukansuu_taikaigoto[currentGhensuu
                                                              .hyojiracebangou];
                                                      i_kukan++
                                                    ) {
                                                      if (gakunenJunUnivFilteredSenshuData[currentGhensuu
                                                                  .SenshuSelectedOption[i_kukan]]
                                                              .id ==
                                                          hoken.id) {
                                                        entrykukannumber =
                                                            i_kukan;
                                                        entrykukannumberstr =
                                                            "${i_kukan + 1}区 ";
                                                        break;
                                                      }
                                                    }
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade900, // ChipのbackgroundColorを再現
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20.0,
                                                            ), // Chipの角丸を再現
                                                      ),
                                                      // Chipのpaddingを再現し、TextButtonが独立してタップできるように調整
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10.0,
                                                            vertical: 4.0,
                                                          ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          // 氏名、学年
                                                          (hoken.chousi > 0)
                                                              ? Flexible(
                                                                  child: Text(
                                                                    '${entrykukannumberstr}${hoken.name} (${hoken.gakunen}年) 調子${hoken.chousi}',
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          HENSUU
                                                                              .fontsize_honbun,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines:
                                                                        2, // 複数行に対応
                                                                  ),
                                                                )
                                                              : Flexible(
                                                                  child: Text(
                                                                    '${entrykukannumberstr}【体調不良】${hoken.name} (${hoken.gakunen}年)',
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          HENSUU
                                                                              .fontsize_honbun,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines:
                                                                        2, // 複数行に対応
                                                                  ),
                                                                ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          // 詳細ボタン (TextButton)
                                                          _buildDetailButton(
                                                            hoken,
                                                          ),
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
                                      const SizedBox(height: 16),
                                    ],
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

      // MARK: モーダルシート
      // `_isShowingModalCourseShoukai` がtrueの場合にモーダルを表示
      /*bottomSheet: _isShowingModalCourseShoukai
          ? ModalCourseShoukaiView(
              onClose: () {
                setState(() {
                  _isShowingModalCourseShoukai = false;
                });
              },
            )
          : null,*/
    );
  }

  // MARK: - ヘルパーウィジェット

  Widget _buildRaceName(int raceBangou) {
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    String raceName = "";
    switch (raceBangou) {
      case 0:
        raceName = "10月駅伝";
        break;
      case 1:
        raceName = "11月駅伝";
        break;
      case 2:
        raceName = "正月駅伝";
        break;
      case 3:
        raceName = "11月駅伝予選";
        break;
      case 4:
        raceName = "正月駅伝予選";
        break;
      case 5:
        raceName = sortedUnivData[0].name_tanshuku;
        break;
      default:
        raceName = "不明な大会";
    }
    return Text(
      raceName,
      style: TextStyle(
        color: HENSUU.textcolor,
        //fontWeight: FontWeight.bold,
        fontSize: HENSUU.fontsize_honbun,
      ),
    );
  }

  // リンクボタンをWidgetに分離
  Widget LinkButtons(int raceBangou) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData kantoku = kantokuBox.get('KantokuData')!;

    return Column(
      children: [
        if (kantoku.yobiint2[17] == 1 && (raceBangou <= 2 || raceBangou == 5))
          TextButton(
            onPressed: () async {
              await showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8),
                barrierDismissible: true,
                barrierLabel: '全大学確認・変更',
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, _, __) =>
                    All0300(ghensuu: currentGhensuu),
                transitionBuilder: (context, animation, _, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
              );

              final Box<SenshuData> senshudataBox = Hive.box<SenshuData>(
                'senshuBox',
              );
              List<SenshuData> myUnivSenshu = senshudataBox.values.where((s) {
                final int gakunenIdx = s.gakunen - 1;
                return s.univid == currentGhensuu.MYunivid &&
                    s.entrykukan_race[raceBangou][gakunenIdx] >= -1;
              }).toList();
              // 学年降順 > ID昇順でソート
              myUnivSenshu.sort((a, b) {
                int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                return (gakunenCompare != 0)
                    ? gakunenCompare
                    : a.id.compareTo(b.id);
              });
              for (int i = 0; i < TEISUU.SUU_MAXKUKANSUU; i++) {
                currentGhensuu.SenshuSelectedOption[i] = 0;
              }
              for (int i = 0; i < myUnivSenshu.length; i++) {
                var senshu = myUnivSenshu[i];
                if (senshu.entrykukan_race[raceBangou][senshu.gakunen - 1] >=
                    0) {
                  currentGhensuu.SenshuSelectedOption[senshu
                          .entrykukan_race[raceBangou][senshu.gakunen - 1]] =
                      i;
                }
              }
              await currentGhensuu.save();
              setState(() {});
            },
            child: const Text(
              "全大学確認・変更",
              style: TextStyle(
                color: Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
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
                  racebangou: raceBangou,
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
        TextButton(
          onPressed: () {
            // ★ここを showGeneralDialog に変更★
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
              barrierDismissible: true, // 背景タップで閉じられるようにする
              barrierLabel: '区間コース編集(試走)', // アクセシビリティ用ラベル
              transitionDuration: const Duration(
                milliseconds: 300,
              ), // アニメーション時間
              pageBuilder: (context, animation, secondaryAnimation) {
                // ここに表示したいモーダルのウィジェットを指定
                return const ModalCourseEditView(); // const を追加
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
            "区間コース編集(試走)",
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 255, 0),
              decoration: TextDecoration.underline,
              decorationColor: HENSUU.textcolor,
            ),
          ),
        ),
        if (raceBangou <= 2 || raceBangou == 5)
          TextButton(
            onPressed: () {
              // ★ここを showGeneralDialog に変更★
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: '最適解区間配置', // アクセシビリティ用ラベル
                transitionDuration: const Duration(
                  milliseconds: 300,
                ), // アニメーション時間
                pageBuilder: (context, animation, secondaryAnimation) {
                  // ここに表示したいモーダルのウィジェットを指定
                  return const KukanHaitiScreen(); // const を追加
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
              "最適解区間配置",
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: HENSUU.textcolor,
              ),
            ),
          ),
      ],
    );
  }

  // 関数の内部に関数として定義
  int checkEkidenEntries({
    required int racebangou,
    required Ghensuu ghensuu,
    required List<UnivData> sortedUnivData,
    required List<SenshuData> sortedSenshuData,
  }) {
    // 1. sortedSenshuDataをunividごとにグループ化する
    final Map<int, List<SenshuData>> senshuDataByUnivid = {};
    for (var senshuData in sortedSenshuData) {
      if (!senshuDataByUnivid.containsKey(senshuData.univid)) {
        senshuDataByUnivid[senshuData.univid] = [];
      }
      senshuDataByUnivid[senshuData.univid]!.add(senshuData);
    }
    // 2. 出場大学のunividsを取得する
    final List<int> entryUnivids = sortedUnivData
        .where((univData) => univData.taikaientryflag[racebangou] == 1)
        .map((univData) => univData.id)
        .toList();

    // 3. 出場大学ごとにエントリー状況をチェックする
    for (var univid in entryUnivids) {
      // 選手データがなければスキップ
      if (!senshuDataByUnivid.containsKey(univid)) {
        print('univid: $univid には選手データがありません。');
        continue;
      }
      final List<int> entryKukanList = [];
      // 大学ごとの選手リストをループ
      for (var senshuData in senshuDataByUnivid[univid]!) {
        // エントリーされている区間を取得
        if (senshuData.entrykukan_race[racebangou][senshuData.gakunen - 1] >
            -1) {
          entryKukanList.add(
            senshuData.entrykukan_race[racebangou][senshuData.gakunen - 1],
          );
        }
      }
      // 4. ルールチェック
      final Set<int> uniqueEntries = entryKukanList.toSet();
      if (uniqueEntries.length != entryKukanList.length) {
        print('univid: $univid で複数の区間にエントリーしている選手がいます。');
        return univid;
      }
      final int maxKukan =
          ghensuu.kukansuu_taikaigoto[racebangou]; // 区間の最大数に応じて変更
      if (uniqueEntries.length < maxKukan) {
        print('univid: $univid でエントリー不足の区間があります。');
        return univid;
      }
    }
    return -1;
  }
}
