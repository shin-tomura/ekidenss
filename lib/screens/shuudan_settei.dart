import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';

// ------------------------------------------------------------
// 説明画面の設定タブの「集団走設定」(1.9.2)
// 駅伝の1区と11月駅伝予選の各組で、集団を引っ張る選手を決めるときの「その日の勢い」の大きさを選ぶ
// (保存先と決め方は lib/kansuu/ikku_pace.dart の「集団を引っ張る選手の決め方」)
// ------------------------------------------------------------

class ModalShuudanSettei extends StatefulWidget {
  const ModalShuudanSettei({super.key});

  @override
  State<ModalShuudanSettei> createState() => _ModalShuudanSetteiState();
}

class _ModalShuudanSetteiState extends State<ModalShuudanSettei> {
  @override
  Widget build(BuildContext context) {
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final int ima = kantoku == null ? 0 : shuudanIkioiSettei(kantoku);

    Widget chip(int atai) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(
            atai == 0
                ? '${shuudanIkioiMei[atai]}(初期値)'
                : shuudanIkioiMei[atai],
          ),
          selected: ima == atai,
          onSelected: (selected) async {
            if (!selected || ima == atai || kantoku == null) return;
            await shuudanIkioiHozon(kantoku, atai);
            if (mounted) setState(() {});
          },
          selectedColor: Colors.orange.shade700,
          backgroundColor: Colors.grey.shade800,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('集団走設定', style: TextStyle(color: Colors.white)),
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
                  color: Colors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
                ),
                child: const Text(
                  '駅伝の1区と11月駅伝予選の各組では、カリスマの高い選手が集団を引っ張り、'
                  '集団のペースを作ります。\n\n'
                  'カリスマが一番高い選手が引っ張ることが多いですが、カリスマの近い選手がいると、'
                  'その日の勢いで別の選手が引っ張ることがあります。'
                  'その日の勢いの大きさを選べます。大きいほど、入れ替わりやすくなります。\n\n'
                  '「なし」にすると、いつもカリスマが一番高い選手が引っ張ります'
                  '(一番高い選手が複数いるときは、同じ顔ぶれなら、いつも同じ選手)。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const Text(
                'その日の勢い',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                children: [for (final int atai in shuudanIkioiNarabi) chip(atai)],
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
