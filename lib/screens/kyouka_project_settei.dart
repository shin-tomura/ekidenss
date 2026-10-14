import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/kyouka_project.dart';

// ------------------------------------------------------------
// 説明画面の設定タブの「強化プロジェクト設定」(2.0.1)
// 強化プロジェクト(正月駅伝の優勝から遠ざかっているコンピュータの大学が、数年間だけスカウトに本腰を入れる出来事)の
// 起こりやすさ・スカウトでの重み(名声何位並み)・期間と、あなたの大学も選ばれるかを選ぶ
// (保存先は KantokuData.yobiint3[80]。仕組みは lib/kansuu/kyouka_project.dart)
// ------------------------------------------------------------

class ModalKyoukaProjectSettei extends StatefulWidget {
  const ModalKyoukaProjectSettei({super.key});

  @override
  State<ModalKyoukaProjectSettei> createState() =>
      _ModalKyoukaProjectSetteiState();
}

class _ModalKyoukaProjectSetteiState extends State<ModalKyoukaProjectSettei> {
  final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');

  Future<void> _hozon(int okoriyasusa, int omomi, int kikan, bool jibun) async {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    if (k == null) return;
    kyoukaSetteiIreru(k, okoriyasusa, omomi, kikan, jibun);
    await k.save();
    if (!mounted) return;
    setState(() {});
  }

  Widget _midashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chip(String label, bool erabareta, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ChoiceChip(
        label: Text(label),
        selected: erabareta,
        onSelected: (selected) {
          if (!selected || erabareta) return;
          onTap();
        },
        selectedColor: Colors.teal.shade700,
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    final int okoriyasusa = k == null ? 0 : kyoukaOkoriyasusaCode(k);
    final int omomi = k == null ? 0 : kyoukaOmomiCode(k);
    final int kikan = k == null ? 0 : kyoukaKikanCode(k);
    final bool jibun = k != null && kyoukaJibunEraberu(k);
    final bool nashi = okoriyasusa == kyoukaOkoriyasusaNashi;

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '強化プロジェクト設定',
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
                  '正月駅伝の優勝から遠ざかっている大学が、数年間だけスカウトに本腰を入れる'
                  '「強化プロジェクト」を始めることがあります。\n\n'
                  '・名声の上位の大学と、正月駅伝の優勝から間もない大学は選ばれません。'
                  '名声が低い大学も選ばれます。\n'
                  '・あなたの大学は、下の「あなたの大学」で「選ばれる」にしたときだけ選ばれます'
                  '(選ばれやすさはほかの大学と同じで、めったに起きません)。\n'
                  '・始まるのは毎年4月の年度替わりで、同時に1校までです。'
                  '始まった年は、4月5日の箱庭スポーツの記事(期待のルーキーと一緒に読めます)で伝えられます。\n'
                  '・期間中は、新入生スカウトの争奪戦や、新入生が自ら志望して進学先を選ぶときなどに、'
                  '下で選んだ順位の名声の大学と同じくらい選ばれやすくなります。'
                  'スカウトの性格が「自動」なら、大物狙いになります。\n'
                  '・期間中の大学は、大学画面とスカウトの画面に出ます。\n'
                  '・「なし」にすると、新しく始まらず、実行中のものも効かなくなります。\n'
                  '・初期値は、起こりやすさ「ふつう(毎年10%)」、重み「名声2位並み」、期間「4年」、'
                  'あなたの大学は「選ばれない」です。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              _midashi('起こりやすさ'),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final int c in kyoukaOkoriyasusaNarabi)
                    _chip(
                      kyoukaOkoriyasusaHyouji(c),
                      okoriyasusa == c,
                      () => _hozon(c, omomi, kikan, jibun),
                    ),
                ],
              ),
              _midashi('スカウトでの重み'),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final int c in kyoukaOmomiNarabi)
                    _chip(
                      kyoukaOmomiHyouji(c),
                      omomi == c,
                      () => _hozon(okoriyasusa, c, kikan, jibun),
                    ),
                ],
              ),
              _midashi('期間'),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final int c in kyoukaKikanNarabi)
                    _chip(
                      kyoukaKikanHyouji(c),
                      kikan == c,
                      () => _hozon(okoriyasusa, omomi, c, jibun),
                    ),
                ],
              ),
              _midashi('あなたの大学'),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _chip(
                    '選ばれない',
                    !jibun,
                    () => _hozon(okoriyasusa, omomi, kikan, false),
                  ),
                  _chip(
                    '選ばれる',
                    jibun,
                    () => _hozon(okoriyasusa, omomi, kikan, true),
                  ),
                ],
              ),
              if (nashi)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '今は「なし」なので、重みと期間は使われません。',
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  '期間は、次に始まるプロジェクトから変わります(実行中のものは、始めたときの期間のままです)。',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
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
