import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';

/// 目標順位・指示の補正設定の画面(1.8.2)
/// 駅伝の2区以降の、目標順位による補正と、前半突っ込み・前半抑えの指示の成否による補正の強さ(全大学共通)
/// KantokuData.yobiint2[64]〜[67](0なら100%(初期値)、1〜31なら(値−1)×10%)。式は mokuhyou_hosei.dart
class ModalHoseiTsuyosa extends StatefulWidget {
  const ModalHoseiTsuyosa({super.key});

  @override
  State<ModalHoseiTsuyosa> createState() => _ModalHoseiTsuyosaState();
}

class _ModalHoseiTsuyosaState extends State<ModalHoseiTsuyosa> {
  late Box<KantokuData> _kantokuBox;

  /// スライダーを動かしている間の表示(番号 → %)。離したら保存して消す
  final Map<int, double> _ugokashiChuu = {};

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // yobiint2を書き換えてHiveに保存する(変更をHiveに保存するために、List全体を更新)
  Future<void> _hozon(KantokuData kantoku, Map<int, int> atai) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    for (final MapEntry<int, int> e in atai.entries) {
      if (updatedYobiint2.length <= e.key) return;
      updatedYobiint2[e.key] = e.value;
    }
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 4つとも初期値(100%)に戻す
  Future<void> _shokitiNiModosu(KantokuData kantoku) async {
    _ugokashiChuu.clear();
    await _hozon(kantoku, {
      hoseiTsuyosaShitamawariIndex: 0,
      hoseiTsuyosaHitoikiIndex: 0,
      hoseiTsuyosaSeikouIndex: 0,
      hoseiTsuyosaShippaiIndex: 0,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('補正の強さを初期値(100%)に戻しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: _kantokuBox.listenable(keys: ['KantokuData']),
      builder: (context, box, _) {
        if (!box.containsKey('KantokuData')) {
          return Scaffold(
            appBar: AppBar(title: const Text('目標順位・指示の補正設定')),
            body: const Center(child: Text('設定データがありません')),
          );
        }
        final KantokuData kantoku = box.get('KantokuData')!;

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '目標順位・指示の補正設定',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "この画面では、駅伝の2区以降での、目標順位による補正(下回ったときの悪化と、上回ったときのほっと一息)と、「前半突っ込み」「前半抑え」の指示の成否による補正の強さを設定します(全大学共通)。\n\n"
                      "100%が初期値(今まで通り)です。0%にするとその補正はなくなり、200%にすると2倍の大きさになります。設定した強さは、レース中の指示の欄の下にある「指示ごとの損得予測」にも反映されます。\n\n"
                      "コンピュータの大学がどの選手に指示を出すか(駅伝男や平常心の高い選手に出します)は、この設定では変わりません。1区のスタート直後飛び出しや、駅伝予選での指示にも関係しません。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  _tsuyosaSlider(
                    kantoku: kantoku,
                    index: hoseiTsuyosaShitamawariIndex,
                    title: '目標順位を下回ったときの悪化の強さ',
                    description:
                        '指示なしの選手が、目標順位を下回った順位で襷を受けたときに、前半無理に突っ込んでしまうことによるタイム悪化の大きさです。目標順位の大学とのタイム差が大きいほど悪化が大きくなる仕組みはそのままで、全体の大きさが変わります。学連選抜の選手にもかかります。',
                    minLabel: '0% (悪化なし)',
                    activeColor: Colors.redAccent,
                  ),
                  _tsuyosaSlider(
                    kantoku: kantoku,
                    index: hoseiTsuyosaHitoikiIndex,
                    title: 'ほっと一息の強さ',
                    description:
                        '指示なしの選手が、目標順位を上回った順位で襷を受けたときに、ほっと一息ついてしまうことによるタイム悪化の大きさです。0%にすると、ほっと一息はなくなります。',
                    minLabel: '0% (ほっと一息なし)',
                    activeColor: Colors.orange,
                  ),
                  _tsuyosaSlider(
                    kantoku: kantoku,
                    index: hoseiTsuyosaSeikouIndex,
                    title: '指示が成功したときの効果の強さ',
                    description:
                        '「前半突っ込み」「前半抑え」の指示が成功したときに、タイムが良くなる大きさです。成功する確率(前半突っ込みは駅伝男、前半抑えは平常心の値)は変わりません。',
                    minLabel: '0% (効果なし)',
                    activeColor: Colors.lightBlueAccent,
                  ),
                  _tsuyosaSlider(
                    kantoku: kantoku,
                    index: hoseiTsuyosaShippaiIndex,
                    title: '指示が失敗したときの損の強さ',
                    description:
                        '「前半突っ込み」「前半抑え」の指示が失敗したときに、タイムが悪くなる大きさです。0%にすると、指示に失敗してもタイムは悪くなりません。前半抑えの失敗による損は、目標順位による補正(上の2つ)の強さも反映した大きさに、この強さを掛けたものになります。',
                    minLabel: '0% (損なし)',
                    activeColor: Colors.purpleAccent,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _shokitiNiModosu(kantoku),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(200, 48),
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: Text(
                      '初期値に戻す',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    child: Text(
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
      },
    );
  }

  /// 強さ1つ分のスライダー(0%〜300%、10%刻み)
  Widget _tsuyosaSlider({
    required KantokuData kantoku,
    required int index,
    required String title,
    required String description,
    required String minLabel,
    required Color activeColor,
  }) {
    final double atai =
        _ugokashiChuu[index] ?? hoseiTsuyosaPercent(kantoku, index).toDouble();
    final int percent = atai.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            description,
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.8),
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            percent == 100 ? '現在の設定値: 100% (初期値)' : '現在の設定値: $percent%',
            style: TextStyle(
              color: percent == 100 ? Colors.greenAccent : Colors.yellow,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: atai.clamp(0.0, hoseiTsuyosaSaidai.toDouble()),
                min: 0,
                max: hoseiTsuyosaSaidai.toDouble(),
                divisions: hoseiTsuyosaSaidai ~/ 10,
                label: '$percent%',
                onChanged: (v) {
                  setState(() => _ugokashiChuu[index] = v);
                },
                onChangeEnd: (v) async {
                  await _hozon(kantoku, {index: hoseiTsuyosaAtai(v.round())});
                  if (!mounted) return;
                  setState(() => _ugokashiChuu.remove(index));
                },
                activeColor: activeColor,
                inactiveColor: Colors.grey.withOpacity(0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        minLabel,
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$hoseiTsuyosaSaidai% (3倍)',
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
  }
}
