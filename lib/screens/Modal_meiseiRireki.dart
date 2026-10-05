import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/kansuu/meisei_rireki.dart';

// ------------------------------------------------------------
// 名声の履歴(1.8.8)
// 大学名声一覧で大学をタップすると開く。その大学の過去10年の名声を、年ごとに内訳つきで出す。
// 内訳は lib/kansuu/meisei_rireki.dart で記録したもの。年ごとの名声(meisei_yeargoto)と
// 内訳の合計の差は「そのほか」として出す(年度の初めに入る1、記録を始める前の分、名声の編集など)
// ------------------------------------------------------------

class ModalMeiseiRireki extends StatelessWidget {
  final int univId;
  const ModalMeiseiRireki({super.key, required this.univId});

  @override
  Widget build(BuildContext context) {
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    return ValueListenableBuilder<Box<UnivData>>(
      valueListenable: univBox.listenable(),
      builder: (context, box, _) {
        UnivData? univ;
        for (final UnivData u in box.values) {
          if (u.id == univId) univ = u;
        }
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: Text(
              univ == null ? '名声の履歴' : '${univ.name}大学 名声の履歴',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(
                child: univ == null
                    ? const Center(
                        child: Text(
                          'データがありません',
                          style: TextStyle(color: HENSUU.textcolor),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: _naiyou(univ),
                      ),
              ),
              // 閉じるボタン
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("閉じる"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _naiyou(UnivData univ) {
    const TextStyle futsuu = TextStyle(color: HENSUU.textcolor);
    const TextStyle chuui = TextStyle(color: Colors.grey, fontSize: 13);
    final List<Widget> list = [
      Text('名声(過去10年の合計): ${univ.meisei_total}', style: futsuu),
      const SizedBox(height: 8),
      const Text(
        '・駅伝の総合順位と区間賞、学連選抜の区間1位相当、対校戦で得た名声を記録しています。',
        style: chuui,
      ),
      const Text(
        '・「そのほか」は、年度の初めに入る1や、記録を始める前の分などです。',
        style: chuui,
      ),
      const SizedBox(height: 8),
    ];
    for (int nenmae = 0; nenmae < TEISUU.MEISEIHOZONNENSUU; nenmae++) {
      final int nen = nenmae < univ.meisei_yeargoto.length
          ? univ.meisei_yeargoto[nenmae]
          : 0;
      final List<MeiseiRirekiGyou> rireki = meiseiRirekiYomu(nenmae, univ.id);
      int goukei = 0;
      for (final MeiseiRirekiGyou g in rireki) {
        goukei += g.ryou;
      }
      final int sonohoka = nen - goukei;
      list.add(const Divider(color: Colors.grey));
      list.add(
        Text(
          '${nenmae == 0 ? '今年度' : '$nenmae年前'}  $nen',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      for (final MeiseiRirekiGyou g in rireki) {
        list.add(
          Text(
            g.ryou == 0 ? '・${g.naiyou}' : '・${g.naiyou}  +${g.ryou}',
            style: futsuu,
          ),
        );
      }
      if (sonohoka != 0) {
        list.add(
          Text(
            '・そのほか  ${sonohoka > 0 ? '+' : ''}$sonohoka',
            style: futsuu,
          ),
        );
      }
    }
    return list;
  }
}
