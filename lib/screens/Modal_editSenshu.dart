import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 数値入力制御のために追加
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/joukai.dart';
import 'package:ekiden/kansuu/riron_kirokukai_time.dart';
import 'package:ekiden/kansuu/gakuren_utsushi.dart'; // 学連選抜用の写しへの反映(1.8.8)

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
  // 基本走力の上限(1.8.5で素質の代わりに編集できるようにした。基本走力と同じ目盛り)
  final TextEditingController _joukaiController = TextEditingController();
  // 開いたときの基本走力と上限の値(欄を変えたかどうかを見るため。1.8.5)
  int? _kihonShokiti;
  int? _joukaiShokiti;

  @override
  void initState() {
    super.initState();
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _loadSenshuData();
    // 理論値の欄を、入力に合わせてその場で計算し直す(1.8.5)
    for (final TextEditingController c in [
      _baseAbilityAController,
      _joukaiController,
      _choukyorinebariController,
      _spurtryokuController,
      _tandokusouController,
      _paceagesagetaiouryokuController,
    ]) {
      c.addListener(_rironchiKoushin);
    }
  }

  void _rironchiKoushin() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final TextEditingController c in [
      _chousiController,
      _anteikanController,
      _konjouController,
      _heijousinController,
      _choukyorinebariController,
      _spurtryokuController,
      _karisumaController,
      _noboritekiseiController,
      _kudaritekiseiController,
      _noborikudarikirikaenouryokuController,
      _tandokusouController,
      _paceagesagetaiouryokuController,
      _baseAbilityAController,
      _joukaiController,
    ]) {
      c.dispose();
    }
    super.dispose();
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
      _kihonShokiti = aInt + 300;
      _joukaiShokiti = joukaiHyouji(senshu.magicnumber);
      _joukaiController.text = _joukaiShokiti.toString();
    }
  }

  /// 保存したときの基本走力の上限(magicnumber)(1.8.5)
  /// [joukai]は上限の欄の値(小さいほど速い目盛り)
  /// ・上限の欄を変えたとき: 入力した上限
  /// ・上限の欄を変えていないとき: 今の上限のまま(目盛りの値に直すときの端数で、保存のたびにずれないように)
  /// (基本走力が上限より速い入力は、_kihonJoukaiMujun で保存の前に止める。
  /// 1.8.4までは、基本走力を上限より速くすると上限を黙って基本走力−25に動かしていたが、
  /// 入力と違う値で保存されて分かりにくいので、やめた)
  double _hozonJoukaiMagicnumber(int joukai) {
    if (joukai == _joukaiShokiti) return _editingSenshu!.magicnumber;
    return magicnumberFromJoukaiHyouji(joukai);
  }

  /// 基本走力が上限より小さい(速い)入力になっているか(1.8.5)
  /// 上限は基本走力が伸びていく先なので、基本走力が上限より速いことは本来ない(同じ値はよい)。
  /// 基本走力と上限の欄をどちらも変えていないときは見ない
  /// (開いたままの値は、目盛りの値に直すときの端数で1だけずれることがあるため)
  bool _kihonJoukaiMujun(int kihon, int joukai) {
    if (kihon == _kihonShokiti && joukai == _joukaiShokiti) return false;
    return kihon < joukai;
  }

  /// 基本走力が上限より小さい(速い)入力のあいだ、上限の欄の下に出す注意(1.8.5)
  Widget _buildMujunChuui() {
    final int? kihon = int.tryParse(_baseAbilityAController.text.trim());
    final int? joukai = int.tryParse(_joukaiController.text.trim());
    if (kihon == null || joukai == null || !_kihonJoukaiMujun(kihon, joukai)) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        '基本走力が上限より小さく(速く)なっています。このままでは保存できません。',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: HENSUU.fontsize_honbun - 2,
        ),
      ),
    );
  }

  /// 説明書きの行(1.8.5)
  Widget _buildSetsumei(List<String> gyou) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final String g in gyou)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              g,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: HENSUU.fontsize_honbun - 2,
              ),
            ),
          ),
      ],
    );
  }

  /// 理論値の時間の書き方(選手画面の持ちタイムと同じ「分秒」)(1.8.5)
  String _rironTimeString(double time) {
    final int minutes = time ~/ 60;
    final int seconds = (time % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
  }

  /// 理論値の欄(1.8.5)
  /// 入力中の値から、今の基本走力と上限に届いたときの、平地の記録会の理論値を出す
  /// (計算は riron_kirokukai_time.dart。入力が数値でない欄があるときは「−」)
  Widget _buildRironchi(List<UnivData> sortedUnivData) {
    final int? kihon = int.tryParse(_baseAbilityAController.text.trim());
    final int? joukai = int.tryParse(_joukaiController.text.trim());
    final int? nebari = int.tryParse(_choukyorinebariController.text.trim());
    final int? spurt = int.tryParse(_spurtryokuController.text.trim());
    final int? road = int.tryParse(_tandokusouController.text.trim());
    final int? pace = int.tryParse(
      _paceagesagetaiouryokuController.text.trim(),
    );
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final SenshuData senshu = _editingSenshu!;
    // 上限に届いたときの基本走力(保存したときの上限)
    // (基本走力が上限より速い入力のあいだは保存できないので「−」にする)
    final int? joukaiKihon =
        (kihon == null || joukai == null || _kihonJoukaiMujun(kihon, joukai))
        ? null
        : joukaiHyouji(_hozonJoukaiMagicnumber(joukai));

    String timeMojiretsu(int? kihonHyouji, double kyori) {
      if (kihonHyouji == null ||
          nebari == null ||
          spurt == null ||
          road == null ||
          pace == null ||
          kantoku == null) {
        return '−';
      }
      final double time = rironKirokukaiTime(
        kyori: kyori,
        kihonSouryokuHyouji: kihonHyouji,
        choukyorinebari: nebari,
        spurtryoku: spurt,
        tandokusou: road,
        paceagesagetaiouryoku: pace,
        univid: senshu.univid,
        ryuugakusei: senshu.hirou == 1,
        trainingNum: _selectedMenu ?? senshu.kaifukuryoku,
        kantoku: kantoku,
        choukyoriTimeHosei: sortedUnivData[9].name_tanshuku == "1",
      );
      return _rironTimeString(time);
    }

    const TextStyle midasiStyle = TextStyle(
      color: Colors.white70,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    // スマホの幅でも「62分40秒」が1行に収まるように、少し小さい字にする
    const TextStyle atai = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    TableRow gyou(String label, int? kihonHyouji) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(label, style: midasiStyle),
          ),
          for (final double kyori in rironKirokukaiKyori)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(timeMojiretsu(kihonHyouji, kyori), style: atai),
            ),
        ],
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      children: [
        const TableRow(
          children: [
            Text('', style: midasiStyle),
            Text('5000m', style: midasiStyle),
            Text('1万m', style: midasiStyle),
            Text('ハーフ', style: midasiStyle),
          ],
        ),
        gyou('今の基本走力', kihon),
        gyou('上限に届いたとき', joukaiKihon),
      ],
    );
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
      {'label': '上限', 'ctrl': _joukaiController, 'min': 0, 'max': 6000},
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

    // 基本走力は上限より小さく(速く)できない(1.8.5)
    if (_kihonJoukaiMujun(
      int.parse(_baseAbilityAController.text.trim()),
      int.parse(_joukaiController.text.trim()),
    )) {
      _showErrorSnackBar('基本走力は上限と同じか、それより大きい値にしてください(上限より速くはなれません)');
      return false;
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

    // 基本走力の上限(1.8.5で、素質の代わりに上限を編集できるようにした)
    double newMagicNumber = _hozonJoukaiMagicnumber(
      int.parse(_joukaiController.text.trim()),
    );

    double originalA = aIntInput * 0.000000001;
    double originalB = b_int / 10000;

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
      ..magicnumber = newMagicNumber;

    try {
      await _senshuBox.put(widget.senshuId, updatedSenshu);
      // 学連選抜の選手なら、学連選抜用の写しにも書く(写しで走るため。1.8.8)
      await gakurenUtsushiNiHanei(updatedSenshu);
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
              _buildNumberInputField('上限', _joukaiController, 0, 6000),
              _buildMujunChuui(),
              _buildSetsumei(const [
                '・上限: 基本走力が伸びていく先の値です(小さいほど速い)。',
                '・基本走力が上限に届くと、育成のたびに限界突破の判定があり、成功すると上限が少し小さくなります。',
                '・基本走力は上限より小さく(速く)できません。もっと速くしたいときは、上限も小さくしてください。',
                '・選手を遅くしたいときは、基本走力と上限の両方を大きくしてください。',
              ]),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "理論値",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRironchi(sortedUnivData),
              const SizedBox(height: 8),
              _buildSetsumei(const [
                '・理論値: 平地の記録会で、運に左右されずに走ったときのタイムです。',
                '・大学の個性・年間強化練習・タイム調整など、記録会のタイムにかかる設定を含めて計算しています。',
                '・調子と、能力のタイムへの影響度(駅伝と駅伝予選だけにかかる設定)は含みません。',
                '・「上限に届いたとき」は、今の能力値のまま上限まで伸びたときのタイムです。',
              ]),
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
