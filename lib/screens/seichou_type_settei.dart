import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kansuu/seichou_type.dart';

// ------------------------------------------------------------
// 説明画面の設定タブの「成長タイプ設定」(1.9.3)
// 新入生の成長タイプの割合(全大学共通)を、型ごとにプルダウンで決める
// (保存先と決まりは lib/kansuu/seichou_type.dart)
// ・合計が100%のときだけ保存できる。画面の上に、合計とあと何%かをいつも出す
// ・「初期値に戻す」「以前の割合にする」は、画面の値を入れ替えるだけで、保存ボタンで確定する
// ・保存していない変更があるまま閉じようとしたら、確認を出す
// ・スマホの文字を大きくしていてもはみ出さないように、型ごとに名前・説明・割合を縦に積む
// ------------------------------------------------------------

class ModalSeichouTypeSettei extends StatefulWidget {
  const ModalSeichouTypeSettei({super.key});

  @override
  State<ModalSeichouTypeSettei> createState() => _ModalSeichouTypeSetteiState();
}

class _ModalSeichouTypeSetteiState extends State<ModalSeichouTypeSettei> {
  // 保存されている割合
  List<int> _hozonZumi = List<int>.from(seichouTypeShokiti);
  // 画面で選んでいる割合
  List<int> _wariai = List<int>.from(seichouTypeShokiti);

  @override
  void initState() {
    super.initState();
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh != null) {
      _hozonZumi = seichouTypeWariai(gh);
      // プルダウンの項目にない値にならないように、0〜100にしておく(ふつうは範囲内)
      _wariai = [for (final int v in _hozonZumi) v.clamp(0, 100)];
    }
  }

  TextStyle get _honbun =>
      const TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);

  TextStyle get _chiisai => const TextStyle(
    color: Colors.white70,
    fontSize: HENSUU.fontsize_honbun - 2,
  );

  // 保存していない変更があるか
  bool get _henkouAri => !seichouTypeWariaiOnaji(_wariai, _hozonZumi);

  int get _goukei => seichouTypeGoukei(_wariai);

  Future<void> _hozon() async {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null || !seichouTypeWariaiTadashii(_wariai)) return;
    await seichouTypeWariaiHozon(gh, _wariai);
    if (!mounted) return;
    setState(() {
      _hozonZumi = List<int>.from(_wariai);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('成長タイプの割合を保存しました')),
    );
  }

  // 保存していない変更を捨てて閉じてよいか
  Future<bool> _sutetemoYoika() async {
    final bool? yoi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '保存していない変更があります',
            style: TextStyle(color: Colors.black),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '変えた割合を保存せずに閉じますか?',
              style: TextStyle(color: Colors.black),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('戻る'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存せずに閉じる'),
            ),
          ],
        );
      },
    );
    return yoi == true;
  }

  // 上に固定する、合計と保存ボタンの欄
  Widget _goukeiRan() {
    final int goukei = _goukei;
    final bool choudo = goukei == 100;
    final String moji = choudo
        ? '合計 100%'
        : (goukei < 100
              ? '合計 $goukei%(あと${100 - goukei}%)'
              : '合計 $goukei%(${goukei - 100}%多い)');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(bottom: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            moji,
            style: TextStyle(
              color: choudo ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: (choudo && _henkouAri) ? _hozon : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
              disabledForegroundColor: Colors.white38,
            ),
            child: const Text('保存'),
          ),
          if (!choudo)
            Text('合計を100%にすると保存できます。', style: _chiisai)
          else if (_henkouAri)
            Text('保存していない変更があります。', style: _chiisai),
        ],
      ),
    );
  }

  // 初期化ボタン(画面の値を入れ替えるだけ。保存は保存ボタンで)
  Widget _shokikaButton(String mei, String setsumei, List<int> atai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: () {
              setState(() {
                _wariai = List<int>.from(atai);
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.all(12.0),
            ),
            child: Text(mei, style: _honbun, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          Text(setsumei, style: _chiisai),
        ],
      ),
    );
  }

  // 割合のプルダウン(0〜100%、1%刻み)
  Widget _wariaiDropdown(int type) {
    return IntrinsicWidth(
      child: DropdownButton<int>(
        value: _wariai[type],
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: _honbun,
        items: [
          for (int v = 0; v <= 100; v++)
            DropdownMenuItem<int>(value: v, child: Text('$v%')),
        ],
        onChanged: (int? v) {
          if (v == null) return;
          setState(() {
            _wariai[type] = v;
          });
        },
      ),
    );
  }

  // 型1つ分(名前・説明・初期値と以前の割合・プルダウンを縦に積む)
  Widget _typeRan(int type) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seichouTypeMei[type],
            style: _honbun.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(seichouTypeSetsumei[type], style: _honbun),
          Text(
            '初期値 ${seichouTypeShokiti[type]}%・以前 ${seichouTypeIzen[type]}%',
            style: _chiisai,
          ),
          _wariaiDropdown(type),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_henkouAri,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool yoi = await _sutetemoYoika();
        if (yoi && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text('成長タイプ設定', style: TextStyle(color: Colors.white)),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _goukeiRan(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.lightBlue.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '選手には成長タイプがあり、基本走力が大きく伸びる学年が、選手ごとに違います。'
                          '成長タイプは画面には出ません。'
                          '新入生の成長タイプを、ここで決めた割合で選びます(全大学共通)。\n\n'
                          '1年に伸びる型が少ないほど、2年以降に伸びる選手が増えます。'
                          'ただ、すぐに使える選手は減り、名声の低い大学ほど選手層が薄くなります。\n\n'
                          '入学時の記録が良い選手は、どの型でも1年のうちに大きく伸びることが多いです。\n\n'
                          '変えた割合は、次の4月の新入生から使います(新規ゲームの1年生を含む)。'
                          '在学中の選手の成長タイプは変わりません。留学生は、この割合を使いません。\n\n'
                          '合計が100%のときに、上の「保存」で保存できます。',
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      _shokikaButton(
                        '初期値に戻す',
                        '1年で伸びきる選手が約4割で、残りは2年以降のどこかで伸びます。',
                        seichouTypeShokiti,
                      ),
                      _shokikaButton(
                        '以前の割合にする',
                        '1年で伸びきる選手が約9割です(1.9.2までの割合)。',
                        seichouTypeIzen,
                      ),
                      const SizedBox(height: 8),
                      for (final int type in seichouTypeNarabi) _typeRan(type),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(200, 48),
                            padding: const EdgeInsets.all(12.0),
                          ),
                          child: const Text(
                            "閉じる",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
