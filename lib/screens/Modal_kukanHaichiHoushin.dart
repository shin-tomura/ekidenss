import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/kansuu/kukan_haichi.dart';

/// 区間配置の方針 設定画面(1.9.1)
/// KantokuData.yobiint2[80]・[81] 大学ごとの区間配置の方針(1大学1桁。kukan_haichi.dart)
/// プレイヤーの大学の方針は、区間エントリーの初期案に使う
class ModalKukanHaichiHoushin extends StatefulWidget {
  const ModalKukanHaichiHoushin({super.key});

  @override
  State<ModalKukanHaichiHoushin> createState() =>
      _ModalKukanHaichiHoushinState();
}

class _ModalKukanHaichiHoushinState extends State<ModalKukanHaichiHoushin> {
  late Box<KantokuData> _kantokuBox;
  int _ikkatsuHoushin = 0; // 一括設定で選んでいる方針

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // 大学ごとの方針を変更し、Hiveに保存する関数(univids の大学をまとめて変更)
  Future<void> _updateHoushin(
    KantokuData kantoku,
    List<int> univids,
    int houshin,
  ) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    if (updatedYobiint2.length <= kukanHaichiHoushinIndex1) {
      return;
    }
    for (final int id in univids) {
      kukanHaichiHoushinSettei(updatedYobiint2, id, houshin);
    }
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 画面からはみ出さないプルダウン(Modal_comGoldSilver.dart と同じ作り)
  // ・入る幅があれば、いちばん長い項目に合わせた幅にする
  // ・スマホの文字を大きくしていて入らない場合は、入る幅まで縮め、
  //   選んでいる項目の文字は「…」で省略する(開いた一覧の項目は折り返して全部表示)
  Widget _houshinDropdown({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    // 前半重視の弱い順に並べる(値は保存する番号のまま。kukanHaichiHoushinNarabi)
    return IntrinsicWidth(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
        items: [
          for (final int code in kukanHaichiHoushinNarabi)
            DropdownMenuItem<int>(
              value: code,
              child: Text(kukanHaichiHoushinMei[code]),
            ),
        ],
        // 選んでいる項目の表示(itemsと同じ並び)
        selectedItemBuilder: (context) => [
          for (final int code in kukanHaichiHoushinNarabi)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                kukanHaichiHoushinMei[code],
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (int? v) {
          if (v != null) onChanged(v);
        },
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
            appBar: AppBar(title: const Text('区間配置の方針')),
            body: const Center(child: Text('設定データがありません')),
          );
        }

        final KantokuData currentKantoku = box.get('KantokuData')!;
        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final int myUnivid = ghensuuBox.isNotEmpty
            ? (ghensuuBox.getAt(0)?.MYunivid ?? -1)
            : -1;
        // 自分の大学を先頭に、あとは大学の番号順
        final List<UnivData> univs = Hive.box<UnivData>('univBox').values
            .toList()
          ..sort((a, b) {
            if (a.id == myUnivid) return -1;
            if (b.id == myUnivid) return 1;
            return a.id.compareTo(b.id);
          });

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text('区間配置の方針', style: TextStyle(color: Colors.white)),
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
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "【区間配置の方針】\n\n"
                      "駅伝の区間配置で、前の区間をどのくらい重く見るか(前半重視の強さ)を、大学ごとに選べます。\n\n"
                      "区間配置では、持ちタイムと能力(年間強化練習の上乗せと、同じ区間を走った経験も含む)から区間ごとのタイムを見積もり、選手によって差がつく区間から順に選手を決めます。"
                      "前半重視にすると、前の区間ほど差を大きく見るので、前の区間に力のある選手が回りやすくなります。"
                      "襷を受けた時点で目標順位を下回っていると、焦ってタイムが悪くなる仕組みがあるためです。\n\n"
                      "前半重視の強さは、その焦りの仕組みの強さ(説明画面の設定タブの「目標順位・指示の補正設定」の、目標順位を下回ったときの悪化の強さ)に比例し、0%にしていると前半重視はしません。"
                      "後半重視は、焦りの仕組みとは関係なく、最終区ほど重く見ます。\n\n"
                      "1区は集団走になるので、集団より速い選手は差が半分になり、集団のペースより大きく遅い選手は大失速しやすい、という見込みで選びます。\n\n"
                      "自分の大学の方針は、区間エントリーの最初の案に使います。"
                      "コンピュータの大学が最適解区間配置(説明画面の設定タブの「最適解区間配置確率設定」)を使う年は、この方針は使いません。"
                      "学連選抜はいつも標準です。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // 見出し(前半重視の強さを選ぶ一覧だと分かるように)
                  Text(
                    "前半重視の強さ",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 一括設定
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        "全大学の前半重視の強さを",
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: HENSUU.fontsize_honbun,
                        ),
                      ),
                      _houshinDropdown(
                        value: _ikkatsuHoushin,
                        onChanged: (v) => setState(() => _ikkatsuHoushin = v),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _updateHoushin(
                            currentKantoku,
                            univs.map((u) => u.id).toList(),
                            _ikkatsuHoushin,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("にする"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 大学ごとの設定(1行目に大学名、2行目に方針。文字を大きくしていても読めるように1大学1段)
                  for (final UnivData univ in univs)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            univ.id == myUnivid
                                ? '${univ.name}(自分の大学・初期案に使う)'
                                : univ.name,
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _houshinDropdown(
                            value: kukanHaichiHoushin(currentKantoku, univ.id),
                            onChanged: (v) =>
                                _updateHoushin(currentKantoku, [univ.id], v),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
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
                    child: Text(
                      "戻る",
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
}
