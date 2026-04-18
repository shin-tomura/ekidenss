import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート

class ModalCourseEditView2 extends StatefulWidget {
  final int racebangou;
  const ModalCourseEditView2({super.key, required this.racebangou});

  @override
  State<ModalCourseEditView2> createState() => _ModalCourseEditView2State();
}

class _ModalCourseEditView2State extends State<ModalCourseEditView2> {
  final _formKey = GlobalKey<FormState>();
  final List<List<TextEditingController>> _controllers = [];
  final List<List<FocusNode>> _focusNodes = [];

  // 初期化完了フラグ (UI描画前にコントローラーが準備できていることを保証)
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Hiveデータにアクセスするためにlistenableはbuildメソッドで行い、
    // ここでは初期化フラグのみ設定し、buildメソッドでデータを取得した後に
    // コントローラーの初期化を呼び出すのがFlutterの一般的なパターンです。
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

  String _formatDoubleToFixed(double value, int fractionDigits) {
    final String result = value.toStringAsFixed(fractionDigits);
    // 末尾の不要なゼロを削除する処理は残しておく
    if (result.contains('.') && result.endsWith('0' * fractionDigits)) {
      final base = result.substring(0, result.length - fractionDigits);
      if (base.endsWith('.')) {
        return base.substring(0, base.length - 1); // .も削除
      }
      return base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final int raceBangou = widget.racebangou;

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, box, _) {
        final Ghensuu? currentGhensuu = box.getAt(0);

        if (currentGhensuu == null) {
          return const Scaffold(body: Center(child: Text('データがありません')));
        }

        // 予選 (3, 4) および範囲外 ( > 5) のチェック
        if (raceBangou == 3 || raceBangou == 4 || raceBangou > 5) {
          return _buildErrorView(context);
        }

        // 💡 修正: 初期化ロジックの改善
        // raceBangouが変わらない限り、一度だけ初期化する
        if (!_isInitialized) {
          // コントローラーの初期化は、GhensuuデータとraceBangouに依存するため、
          // build内（またはbuildから呼ばれるメソッド）で行うのが安全です。
          _initializeControllers(currentGhensuu, raceBangou);
          // 初期化完了フラグを立てる
          // setStateは使わずフラグを立てることで、初回ビルド時にのみ実行される
          Future.microtask(
            () => setState(() {
              _isInitialized = true;
            }),
          );
        }

        // 初期化が完了するまでローディング表示 (または単に描画スキップ)
        if (!_isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 区間数チェック (念のため)
        final kukanCount = currentGhensuu.kukansuu_taikaigoto[raceBangou];
        if (kukanCount > _controllers.length) {
          // データが途中で変わった場合など、再初期化
          Future.microtask(
            () => setState(() {
              _initializeControllers(currentGhensuu, raceBangou);
              _isInitialized = true; // 再度初期化フラグを立てる
            }),
          );
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(value: null)),
          );
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
                    ..._buildRaceTitle(raceBangou),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    for (
                      int i_kukan = 0;
                      // 💡 修正: ループ条件を widget.racebangou (raceBangou) に変更
                      i_kukan < currentGhensuu.kukansuu_taikaigoto[raceBangou];
                      i_kukan++
                    )
                      // 💡 修正: _buildKukanEditor に raceBangou を渡す
                      _buildKukanEditor(currentGhensuu, i_kukan, raceBangou),
                    const Divider(color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 💡 修正: _buildResetButton に raceBangou を渡す
                        _buildResetButton(currentGhensuu, raceBangou),
                        // 💡 修正: _buildSaveButton に raceBangou を渡す
                        _buildSaveButton(currentGhensuu, raceBangou),
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

  // 💡 修正: raceBangou の引数を追加
  void _initializeControllers(Ghensuu currentGhensuu, int raceBangou) {
    // コントローラーがすでに存在する場合はdisposeしてからクリア
    if (_controllers.isNotEmpty) {
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
    }
    _controllers.clear();
    _focusNodes.clear();

    final raceIndex = raceBangou;
    final kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];

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
            // マイナスを外して表示
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

  // raceIndex は build メソッドから渡される widget.racebangou
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
          fontWeight: FontWeight.bold, // 強調
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
      const SizedBox(height: 8),
    ];
  }

  Widget _buildKukanEditor(
    Ghensuu currentGhensuu,
    int i_kukan,
    int raceBangou, // 💡 修正: raceBangou を引数として受け取る
  ) {
    final controllers = _controllers[i_kukan];
    final focusNodes = _focusNodes[i_kukan];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "${i_kukan + 1}区",
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
          // 以下、他のTextFieldも同様に raceBangou に依存しないため修正は不要
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

  // 💡 修正: raceBangou の引数を追加
  Widget _buildResetButton(Ghensuu currentGhensuu, int raceBangou) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () {
            _resetToDefaults(
              currentGhensuu,
              raceBangou,
            ); // 💡 修正: raceBangou を渡す
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

  // 💡 修正: raceBangou の引数を追加
  Widget _buildSaveButton(Ghensuu currentGhensuu, int raceBangou) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final raceIndex = raceBangou; // 💡 修正: raceBangou を利用
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
                _saveChanges(
                  currentGhensuu,
                  raceBangou,
                ); // 💡 修正: raceBangou を渡す
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

  // 💡 修正: raceBangou の引数を追加
  void _saveChanges(Ghensuu currentGhensuu, int raceBangou) async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final raceIndex = raceBangou; // 💡 修正: raceBangou を利用
    final int kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIndex];

    for (int i_kukan = 0; i_kukan < kukanCount; i_kukan++) {
      final controllers = _controllers[i_kukan];

      currentGhensuu.kyori_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[0].text) ?? 0.0;
      currentGhensuu.heikinkoubainobori_taikai_kukangoto[raceIndex][i_kukan] =
          double.tryParse(controllers[1].text) ?? 0.0;
      // 下り勾配はマイナス値で保存
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

    // ローディングダイアログを閉じるための Navigator.pop(context) が必要
    // 成功/失敗のスナックバー表示前に、ローディングを閉じる
    Navigator.of(context).pop();

    try {
      await currentGhensuu.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('コース情報を保存しました。'), backgroundColor: Colors.green),
      );

      // モーダル画面全体を閉じる
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
      // エラー発生時は、モーダル画面全体を閉じるかどうかはアプリケーションの要件によるが、ここでは閉じる
      Navigator.of(context).pop();
    }
  }

  // 💡 修正: raceBangou の引数を追加
  void _resetToDefaults(Ghensuu currentGhensuu, int raceBangou) async {
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

    // ローディングダイアログを表示 (新しい context を使う)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final raceIndex = raceBangou; // 💡 修正: raceBangou を利用
    final List<double> defaultKyori = [];
    final List<double> defaultNoboriKoubai = [];
    final List<double> defaultKudariKoubai = [];
    final List<double> defaultNoboriWariai = [];
    final List<double> defaultKudariWariai = [];
    final List<int> defaultKirikaesiKaisuu = [];

    // ... (既定値の割り当てロジックは既存のものを維持) ...
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
        // ロードダイアログを閉じる
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

    // コントローラーを再初期化 (UI更新のため)
    _initializeControllers(currentGhensuu, raceBangou);

    try {
      await currentGhensuu.save();

      // ローディングダイアログを閉じる
      // 注意: _resetToDefaultsが呼ばれたコンテキストではなく、loadingContext を pop する必要があります。
      // しかし、ここは loadingContext への参照がないため、ここでは外側の Navigator.of(context).pop() を使用します。
      // 確認ダイアログの時点で context を使って pop しているため、ここでは二重 pop に注意が必要です。
      // 適切なコンテキスト管理のために、ローディングダイアログ表示時にコンテキストを保持する必要がありますが、
      // 簡略化のため、ここでは外部の Navigator.of(context).pop() を使用します。
      Navigator.of(context).pop(); // ローディングダイアログを閉じる

      // setState を呼び出してUIを更新
      setState(() {
        // UI描画更新のためにsetStateを呼ぶ
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('コース情報を既定値に戻しました。'),
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
