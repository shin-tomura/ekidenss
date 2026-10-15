import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/bokou_pipe.dart';

// ------------------------------------------------------------
// 説明画面の設定タブの「監督の母校パイプ設定」(2.0.1)
// 大学の監督(OB)の母校の新入生が、スカウトでその大学をどれくらい選びやすくなるかと、
// あなたの大学にも効くかと、コンピュータの大学が母校の後輩にどれくらい優先して声をかけるかを選ぶ
// (保存先は KantokuData.yobiint3[84]。仕組みは lib/kansuu/bokou_pipe.dart)
// ------------------------------------------------------------

class ModalBokouPipeSettei extends StatefulWidget {
  const ModalBokouPipeSettei({super.key});

  @override
  State<ModalBokouPipeSettei> createState() => _ModalBokouPipeSetteiState();
}

class _ModalBokouPipeSetteiState extends State<ModalBokouPipeSettei> {
  final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');

  Future<void> _hozon(int code, bool jibunKiku, int koekake) async {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    if (k == null) return;
    bokouPipeSetteiIreru(k, code, jibunKiku, koekake);
    await k.save();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final KantokuData? k = _kantokuBox.get('KantokuData');
    final int code = k == null ? 0 : bokouPipeCode(k);
    final bool jibunKiku = k == null || bokouPipeJibunKiku(k);
    final int koekake = k == null ? 0 : bokouPipeKoekakeCode(k);

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '監督の母校パイプ設定',
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
                child: const Text(
                  'コンピュータスカウトがONのとき、大学の監督(OB)の母校の新入生は、'
                  'その大学を選びやすくなります。\n\n'
                  '・争奪戦や、最後に自ら進学先を選ぶとき、交渉の成功率で、'
                  '監督の大学を、下で選んだ順位の名声の大学と同じくらいに扱います。'
                  'もともとそれより名声の高い大学は、そのままです。\n'
                  '・コンピュータの大学は、地区めぐり(声かけ)で、母校の後輩に優先して声をかけます。'
                  'どれくらい優先するかは、下の「コンピュータの声かけ」で選べます。\n'
                  '　・強い: 上位半分に入る後輩なら、必ず優先します。\n'
                  '　・ふつう: その大学のスカウトの性格の基準に入る後輩なら、必ず優先します'
                  '(大物狙いの大学は、大物の後輩だけ)。\n'
                  '　・弱い: ふつうと同じ後輩を、半分の確率で優先します。\n'
                  '　・しない: 優先しません。\n'
                  '・あなたの大学の監督の母校の新入生にも効きます(下の「あなたの大学」で、効かなくもできます)。\n'
                  '・監督が代わると、母校も代わります。\n'
                  '・監督のいない大学には効きません(ゲームを始めた年は、どの大学にも監督がいません)。\n'
                  '・あなたの大学は、OBの選手画面から、年齢に関係なく監督を進言できます。\n'
                  '・スカウトの画面の選手に「○○大学の監督の母校」と出ます。'
                  '監督の出身校は、大学画面と高校名鑑でも分かります。\n'
                  '・スカウトの画面の絞り込みで、監督の母校の出身の選手だけを出せます。\n'
                  '・コンピュータスカウトがOFFのときは効きません。\n'
                  '・初期値は「名声1位並み」で、あなたの大学にも「効く」、コンピュータの声かけは「ふつう」です。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                child: Text(
                  '母校の新入生の選ばれやすさ',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final int c in bokouPipeNarabi)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: ChoiceChip(
                        label: Text(bokouPipeMei[c]),
                        selected: code == c,
                        onSelected: (selected) {
                          if (!selected || code == c) return;
                          _hozon(c, jibunKiku, koekake);
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
                  'あなたの大学',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final bool kiku in const [true, false])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: ChoiceChip(
                        label: Text(kiku ? '効く' : '効かない'),
                        selected: jibunKiku == kiku,
                        onSelected: (selected) {
                          if (!selected || jibunKiku == kiku) return;
                          _hozon(code, kiku, koekake);
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
                  'コンピュータの声かけ',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final int c in bokouPipeKoekakeNarabi)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: ChoiceChip(
                        label: Text(bokouPipeKoekakeMei[c]),
                        selected: koekake == c,
                        onSelected: (selected) {
                          if (!selected || koekake == c) return;
                          _hozon(code, jibunKiku, c);
                        },
                        selectedColor: Colors.teal.shade700,
                        backgroundColor: Colors.grey.shade800,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
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
