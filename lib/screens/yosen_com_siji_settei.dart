import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/yosen_com_siji.dart';

// ------------------------------------------------------------
// 説明画面の設定タブの「正月駅伝予選の指示と集団走」(1.9.9)
// コンピュータの大学(とスキップ中のプレイヤーの大学)が、正月駅伝予選で
// 「おまかせで組む」と同じ組み方で指示と集団走を使うかを選ぶ
// (保存先は KantokuData.yobiint2[89]。0=使う(初期値)・1=使わない。組み方は lib/kansuu/yosen_com_siji.dart)
// ------------------------------------------------------------

class ModalYosenComSijiSettei extends StatefulWidget {
  const ModalYosenComSijiSettei({super.key});

  @override
  State<ModalYosenComSijiSettei> createState() =>
      _ModalYosenComSijiSetteiState();
}

class _ModalYosenComSijiSetteiState extends State<ModalYosenComSijiSettei> {
  final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');

  Future<void> _erabu(bool ari) async {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    if (k == null) return;
    await yosenComSijiHozon(k, ari);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    final bool ari = k == null ? true : yosenComSijiAri(k);
    Widget chip(String label, bool value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: ari == value,
          onSelected: (selected) {
            if (!selected || ari == value) return;
            _erabu(value);
          },
          selectedColor: Colors.teal.shade700,
          backgroundColor: Colors.grey.shade800,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '正月駅伝予選の指示と集団走',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: const Text(
                  'コンピュータの大学が、正月駅伝予選でフリー走・集団走と指示を使うかを選びます。\n\n'
                  '・使うときは、レース画面の「おまかせで組む」と同じ組み方で組みます'
                  '(試走タイムの近い選手どうしで集団を作り、駅伝男の高い選手は前半突っ込みにするなど)。\n'
                  '・組むのに使う試走タイムは、あなたの画面に出ているのと同じ、多少ばらつきのある値です。\n'
                  '・スキップ中は指示の画面を通らないので、あなたの大学も同じ組み方で組みます。\n'
                  '・使うと、コンピュータの大学のタイムが良くなるので、予選の通過は難しくなります。\n'
                  '・使わないときは、コンピュータの大学(とスキップ中のあなたの大学)の選手は、'
                  '全員が指示なしのフリー走で走ります。\n'
                  '・初期値は「使う」です。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [chip('使う', true), chip('使わない', false)],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
            ],
          ),
        ),
      ),
    );
  }
}
