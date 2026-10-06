import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/konki_best.dart';

// ------------------------------------------------------------
// 今季ベストの画面の部品(1.9.1。今季ベストの決め方は lib/kansuu/konki_best.dart)
// ・持ちタイムの「自己ベスト/今季ベスト」の切り替え(ランキング・区間配置確認・説明画面の設定タブ)
// ・選手画面の、自己ベストの行の下に出す今季ベストの行
// ------------------------------------------------------------

/// 持ちタイムの「自己ベスト/今季ベスト」の切り替え
/// 選んだほうは保存して、ほかの画面の切り替えや生成AIに渡すテキストと共有する
/// 切り替えたら[onChanged]を呼ぶ(呼んだ画面で setState して描き直す)
class KonkiBestKirikae extends StatelessWidget {
  final VoidCallback onChanged;
  const KonkiBestKirikae({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool konki = konkiBestHyoujiChuu();
    Widget chip(String label, bool value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: konki == value,
          onSelected: (selected) async {
            if (!selected || konki == value) return;
            await konkiBestHyoujiSettei(value);
            onChanged();
          },
          selectedColor: Colors.orange.shade700,
          backgroundColor: Colors.grey.shade800,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text(
              '持ちタイム',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          chip('自己ベスト', false),
          chip('今季ベスト', true),
        ],
      ),
    );
  }
}

/// 選手画面の、自己ベストの行の下に出す今季ベストの行(切り替えに関係なく出す)
/// [zentaiAri]がfalseなら全体順位を出さない(自己ベストの行と揃える)
Widget konkiBestGyou(
  SenshuData s,
  int idx,
  KonkiBestJuni juni, {
  bool zentaiAri = true,
}) {
  const TextStyle style = TextStyle(
    color: Colors.white70,
    fontSize: HENSUU.fontsize_honbun,
  );
  final double time = juni.best(s, idx);
  if (time >= TEISUU.DEFAULTTIME) {
    return const Text('　今季 記録無', style: style);
  }
  return Wrap(
    children: [
      Text('　今季: ${konkiBestTimeBun(time, idx)}', style: style),
      const SizedBox(width: 8),
      Text('学内${juni.gakunai(time, idx, s.univid)}位', style: style),
      if (zentaiAri) ...[
        const SizedBox(width: 8),
        Text('全体${juni.zentai(time, idx)}位', style: style),
      ],
    ],
  );
}

/// 説明画面の設定タブの「持ちタイムの表示設定」(ランキングなどの画面の切り替えと同じもの)
class ModalKonkiBestSettei extends StatefulWidget {
  const ModalKonkiBestSettei({super.key});

  @override
  State<ModalKonkiBestSettei> createState() => _ModalKonkiBestSetteiState();
}

class _ModalKonkiBestSetteiState extends State<ModalKonkiBestSettei> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '持ちタイムの表示設定',
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
                  color: Colors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
                ),
                child: const Text(
                  'ランキング・区間配置確認などの画面と、生成AIに渡すテキストで、'
                  '持ちタイムを自己ベストで出すか、今季ベストで出すかを選べます。\n\n'
                  '今季ベストは、今年度のレースでの最高記録です。'
                  '年間強化練習は年度ごとに変わるので、今の実力を比べるときに便利です。\n\n'
                  '選手画面では、どちらを選んでも両方出します。'
                  'それぞれの画面の上にある切り替えでも変えられます(どこで変えても同じ設定です)。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              KonkiBestKirikae(onChanged: () => setState(() {})),
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
