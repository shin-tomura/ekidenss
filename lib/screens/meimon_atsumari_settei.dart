import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/koukou.dart'
    show koukouAtsumari, koukouAtsumariHozon, koukouAtsumariMei, koukouAtsumariMeyasu;
import 'package:ekiden/kansuu/koukou_meibo.dart' show koukouMeimonMei;

// ------------------------------------------------------------
// 説明画面の設定タブの「名門高校への集まりやすさ設定」(2.1.6)
// 大学に入る日本人の新入生の出身校を決めるときに、速い新入生が名門校・強豪校にどれくらい集まるかを、
// 5段階から選ぶ(保存先は大学id 29 のJSONの ma。仕組みは lib/kansuu/koukou.dart の
// 「名門高校への集まりやすさ」)
// ・選んだ段階の目安として、入学時5000mが13分50秒・14分20秒・14分50秒の新入生が、
//   どの名門度の高校に入るかの割合を、今の高校の名簿で計算して出す
// ------------------------------------------------------------

class ModalMeimonAtsumariSettei extends StatefulWidget {
  const ModalMeimonAtsumariSettei({super.key});

  @override
  State<ModalMeimonAtsumariSettei> createState() => _ModalMeimonAtsumariSetteiState();
}

class _ModalMeimonAtsumariSetteiState extends State<ModalMeimonAtsumariSettei> {
  /// 目安を出す入学時5000m(秒)
  static const List<double> _meyasuTime = [830, 860, 890];

  Future<void> _hozon(int a) async {
    await koukouAtsumariHozon(a);
    if (!mounted) return;
    setState(() {});
  }

  /// 「13分50秒」の形
  static String _timeMoji(double t) {
    final int byou = t.round();
    return '${byou ~/ 60}分${(byou % 60).toString().padLeft(2, '0')}秒';
  }

  /// 目安の1行(「名門61%・強豪32%・中堅6%・一般1%」の形。名門度の高い順)
  static String _wariaiMoji(List<double> w) {
    final List<String> l = [];
    for (int m = w.length - 1; m >= 0; m--) {
      final String mei = m < koukouMeimonMei.length ? koukouMeimonMei[m] : '';
      l.add('${mei}${(w[m] * 100).round()}%');
    }
    return l.join('・');
  }

  @override
  Widget build(BuildContext context) {
    final int genzai = koukouAtsumari();
    final TextStyle honbun = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun,
    );

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '名門高校への集まりやすさ設定',
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
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Text(
                  '大学に入る日本人の新入生が、高校時代にどの高校に通っていたかの決まり方を変えられます。\n\n'
                  '・持ちタイムの速い新入生ほど、名門校や強豪校に入りやすくなります。\n'
                  '・名門校には、県外からも速い新入生が集まります。\n'
                  '・「集まる」ほど、速い新入生が名門校や強豪校に集まり、高校の大会で名門校が強くなります。\n'
                  '・「散らばる」ほど、速い新入生がいろいろな高校に散らばります。\n'
                  '・名前のない高校生の強さは変わりません。\n'
                  '・大学のレースや、新入生の能力には効きません。\n'
                  '・次の7月下旬の高校の大会の世代から効きます。高校がもう決まった世代は、今のままです。\n'
                  '・初期値は「ふつう」です。',
                  style: honbun,
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                child: Text(
                  '名門高校への集まりやすさ',
                  style: honbun.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 0; i < koukouAtsumariMei.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: ChoiceChip(
                        label: Text(koukouAtsumariMei[i]),
                        selected: genzai == i - 2,
                        onSelected: (selected) {
                          if (!selected || genzai == i - 2) return;
                          _hozon(i - 2);
                        },
                        selectedColor: Colors.teal.shade700,
                        backgroundColor: Colors.grey.shade800,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                child: Text(
                  '目安(今の高校の名簿で、全国を平均した見込み)',
                  style: honbun.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final double t in _meyasuTime) ...[
                      Text('入学時5000mが${_timeMoji(t)}の新入生', style: honbun),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          _wariaiMoji(koukouAtsumariMeyasu(genzai, t)),
                          style: honbun,
                        ),
                      ),
                    ],
                    Text(
                      '高校名鑑の編集で名門度を変えると、目安も変わります。',
                      style: honbun.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
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
