import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 数値入力制御のために追加
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';

class SenshuEditView extends StatefulWidget {
  final int senshuId;

  const SenshuEditView({super.key, required this.senshuId});

  @override
  State<SenshuEditView> createState() => _SenshuEditViewState();
}

class _SenshuEditViewState extends State<SenshuEditView> {
  late Box<SenshuData> _senshuBox;
  SenshuData? _editingSenshu;

  // 編集用のコントローラーと変数
  int? _selectedMenu;
  final TextEditingController _chousiController = TextEditingController();
  final TextEditingController _anteikanController = TextEditingController();
  final TextEditingController _konjouController = TextEditingController();
  final TextEditingController _heijousinController = TextEditingController();
  final TextEditingController _choukyorinebariController =
      TextEditingController();
  final TextEditingController _spurtryokuController = TextEditingController();
  final TextEditingController _karisumaController = TextEditingController();
  final TextEditingController _noboritekiseiController =
      TextEditingController();
  final TextEditingController _kudaritekiseiController =
      TextEditingController();
  final TextEditingController _noborikudarikirikaenouryokuController =
      TextEditingController();
  final TextEditingController _tandokusouController = TextEditingController();
  final TextEditingController _paceagesagetaiouryokuController =
      TextEditingController();
  final TextEditingController _baseAbilityAController = TextEditingController();
  final TextEditingController _sosituController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _loadSenshuData();
  }

  void _loadSenshuData() {
    final senshu = _senshuBox.get(widget.senshuId);
    if (senshu != null) {
      _editingSenshu = senshu;
      _selectedMenu = senshu.kaifukuryoku;
      _chousiController.text = senshu.chousi.toString();
      _anteikanController.text = senshu.anteikan.toString();
      _konjouController.text = senshu.konjou.toString();
      _heijousinController.text = senshu.heijousin.toString();
      _choukyorinebariController.text = senshu.choukyorinebari.toString();
      _spurtryokuController.text = senshu.spurtryoku.toString();
      _karisumaController.text = senshu.karisuma.toString();
      _noboritekiseiController.text = senshu.noboritekisei.toString();
      _kudaritekiseiController.text = senshu.kudaritekisei.toString();
      _noborikudarikirikaenouryokuController.text = senshu
          .noborikudarikirikaenouryoku
          .toString();
      _tandokusouController.text = senshu.tandokusou.toString();
      _paceagesagetaiouryokuController.text = senshu.paceagesagetaiouryoku
          .toString();

      int newbint = 1550;
      int b_int = (senshu.b * 10000.0).round();
      int a_int = (senshu.a * 1000000000.0).round();
      int a_min_int =
          (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER)
              .round();
      int sa = a_int - a_min_int;
      int new_a_min_int =
          (newbint * newbint * 0.0333 - newbint * 114.25 + TEISUU.MAGICNUMBER)
              .round();

      int aInt = new_a_min_int + sa;
      _baseAbilityAController.text = (aInt + 300).toString();
      _sosituController.text = (senshu.sositu - 1500).toString();
    }
  }

  /// 数値入力専用のフィールド（キーボードを数字に限定）
  Widget _buildNumberInputField(
    String label,
    TextEditingController controller,
    int min,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        // keyboardTypeをnumberにし、マイナス値を許容するためにsignedをtrueにする
        keyboardType: TextInputType.number,
        //keyboardType: const TextInputType.numberWithOptions(
        //  signed: true,
        //  decimal: false,
        //),
        inputFormatters: [
          // 数字とマイナス記号（1つ目のみ）を許可する正規表現
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        ],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: '$label ($min～$max)',
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    final fields = [
      {'label': '調子', 'ctrl': _chousiController, 'min': 0, 'max': 100},
      {'label': '安定感', 'ctrl': _anteikanController, 'min': 1, 'max': 99},
      {'label': '駅伝男', 'ctrl': _konjouController, 'min': 1, 'max': 99},
      {'label': '平常心', 'ctrl': _heijousinController, 'min': 1, 'max': 99},
      {
        'label': '長距離粘り',
        'ctrl': _choukyorinebariController,
        'min': 1,
        'max': 99,
      },
      {'label': 'スパート力', 'ctrl': _spurtryokuController, 'min': 1, 'max': 99},
      {'label': 'カリスマ', 'ctrl': _karisumaController, 'min': 1, 'max': 110},
      {'label': '登り適性', 'ctrl': _noboritekiseiController, 'min': 1, 'max': 99},
      {'label': '下り適性', 'ctrl': _kudaritekiseiController, 'min': 1, 'max': 99},
      {
        'label': 'アップダウン対応力',
        'ctrl': _noborikudarikirikaenouryokuController,
        'min': 1,
        'max': 99,
      },
      {'label': 'ロード適性', 'ctrl': _tandokusouController, 'min': 1, 'max': 99},
      {
        'label': 'ペース変動対応力',
        'ctrl': _paceagesagetaiouryokuController,
        'min': 1,
        'max': 99,
      },
      {'label': '基本走力', 'ctrl': _baseAbilityAController, 'min': 0, 'max': 6000},
      {'label': '素質', 'ctrl': _sosituController, 'min': 0, 'max': 180},
    ];

    for (var field in fields) {
      final String label = field['label'] as String;
      final TextEditingController ctrl = field['ctrl'] as TextEditingController;
      final int min = field['min'] as int;
      final int max = field['max'] as int;

      final String text = ctrl.text.trim();
      if (text.isEmpty) {
        _showErrorSnackBar('$labelを入力してください');
        return false;
      }

      final int? value = int.tryParse(text);
      if (value == null) {
        _showErrorSnackBar('$labelに正しい数値を入力してください');
        return false;
      }

      if (value < min || value > max) {
        _showErrorSnackBar('$labelは $min～$max の範囲で入力してください');
        return false;
      }
    }

    if (_selectedMenu == null) {
      _showErrorSnackBar('年間強化練習メニューを選択してください');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveData() async {
    if (_editingSenshu == null) return;
    if (!_validateFields()) return;

    int aIntInput = int.parse(_baseAbilityAController.text) - 300;
    int b_int = 1550;

    double term1 = b_int * b_int * 0.0333;
    double term2 = b_int * 114.25;

    double oldMagicNumber = _editingSenshu!.magicnumber;
    double newMagicNumber = aIntInput - (term1 - term2);
    if (oldMagicNumber > newMagicNumber) {
      newMagicNumber -= 25.0;
    } else {
      newMagicNumber = oldMagicNumber;
    }

    double originalA = aIntInput * 0.000000001;
    double originalB = b_int / 10000;

    int newSositu = int.parse(_sosituController.text) + 1500;

    final updatedSenshu = _editingSenshu!
      ..kaifukuryoku = _selectedMenu!
      ..chousi = int.parse(_chousiController.text)
      ..anteikan = int.parse(_anteikanController.text)
      ..konjou = int.parse(_konjouController.text)
      ..heijousin = int.parse(_heijousinController.text)
      ..choukyorinebari = int.parse(_choukyorinebariController.text)
      ..spurtryoku = int.parse(_spurtryokuController.text)
      ..karisuma = int.parse(_karisumaController.text)
      ..noboritekisei = int.parse(_noboritekiseiController.text)
      ..kudaritekisei = int.parse(_kudaritekiseiController.text)
      ..noborikudarikirikaenouryoku = int.parse(
        _noborikudarikirikaenouryokuController.text,
      )
      ..tandokusou = int.parse(_tandokusouController.text)
      ..paceagesagetaiouryoku = int.parse(_paceagesagetaiouryokuController.text)
      ..a = originalA
      ..b = originalB
      ..magicnumber = newMagicNumber
      ..sositu = newSositu;

    try {
      await _senshuBox.put(widget.senshuId, updatedSenshu);
      if (!mounted) return;
      // 1. 念のため現在出ているスナックバーをすべてクリア
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選手能力を更新しました'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500), // ここで表示時間を短縮（0.8秒）
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('保存に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editingSenshu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          '${_editingSenshu!.name} の能力編集\n${sortedUnivData[_editingSenshu!.univid].name}大学 ${_editingSenshu!.gakunen}年',
          style: const TextStyle(fontSize: HENSUU.fontsize_honbun),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveData),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "年間強化練習",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _selectedMenu,
                dropdownColor: HENSUU.backgroundcolor,
                isExpanded: true,
                style: const TextStyle(
                  color: HENSUU.LinkColor,
                  fontSize: HENSUU.fontsize_honbun + 2,
                ),
                items: TrainingMenu.menuOptions.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedMenu = val);
                },
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "能力値関係",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildNumberInputField('調子', _chousiController, 0, 100),
              _buildNumberInputField('安定感', _anteikanController, 1, 99),
              _buildNumberInputField('駅伝男', _konjouController, 1, 99),
              _buildNumberInputField('平常心', _heijousinController, 1, 99),
              _buildNumberInputField(
                '長距離粘り',
                _choukyorinebariController,
                1,
                99,
              ),
              _buildNumberInputField('スパート力', _spurtryokuController, 1, 99),
              _buildNumberInputField('カリスマ', _karisumaController, 1, 110),
              _buildNumberInputField('登り適性', _noboritekiseiController, 1, 99),
              _buildNumberInputField('下り適性', _kudaritekiseiController, 1, 99),
              _buildNumberInputField(
                'アップダウン対応力',
                _noborikudarikirikaenouryokuController,
                1,
                99,
              ),
              _buildNumberInputField('ロード適性', _tandokusouController, 1, 99),
              _buildNumberInputField(
                'ペース変動対応力',
                _paceagesagetaiouryokuController,
                1,
                99,
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "基本走力関係\n(いずれも小さいほうが良い)",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildNumberInputField('基本走力', _baseAbilityAController, 0, 6000),
              _buildNumberInputField('素質', _sosituController, 0, 180),
              Text("※素質は基本走力の成長を促進させる能力"),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('設定を保存する'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
