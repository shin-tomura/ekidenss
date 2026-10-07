import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // TEISUU・HENSUUクラス
import 'package:ekiden/kansuu/univkosei.dart'; // 実力発揮度(AbilityType)
import 'package:ekiden/kansuu/goldsilver_com.dart'; // 金銀の支給レベル・銀の使い道
import 'package:ekiden/kansuu/scout_com.dart'; // スカウト方針・性格・評価の割合・積極性
import 'package:ekiden/kansuu/kukan_haichi.dart'; // 区間配置の方針

// ------------------------------------------------------------
// 大学の個性(1.9.1)
// 大学画面で表示している大学1校の、大学ごとの設定を1画面にまとめて変える。
// 値の保存場所は、それぞれの設定の画面と同じ(新しく保存する値はない)。
//   育成力: UnivData.ikuseiryoku(10〜150)
//   金銀: 支給レベル・銀の使い道(goldsilver_com.dart)
//   スカウト: 方針・性格(yobiint2)と、評価の割合・積極性(yobiint3。scout_com.dart)
//   レース: 区間配置の方針(kukan_haichi.dart)
//   留学生: 受け入れと優秀度(UnivData.r。0は受け入れない、1最高優秀〜4)
//   走りの特徴: 実力発揮度(KantokuData.yobiint5[大学id]。univkosei.dart)。
//     あまり使われないので一番下に置く
// ・大学の型(画面の一番上): 押すと、実力発揮度・銀の使い道・スカウト方針をまとめてその型にそろえる。
//   型そのものは保存しない(そろえたあとに個別に直せる。今の設定がどの型と同じかは値から判断する)。
//   強さ(弱め・普通・強め)で、得意な能力の実力発揮度を4・3・2(110%・120%・130%)、
//   苦手な能力を6・7・8(90%・80%・70%)にし、それ以外の能力は5(100%)に戻す。
//   130%より上げないのは、アップダウンのあるコースのほうが平らなコースより速くなるといった、
//   不自然なことが起きうるため。銀の使い道とスカウト方針は、型と同じ練習メニューの番号にする
// ・スクロールの指で値が変わらないように、スライダーは使わず、プルダウンとボタンにしている
// ・大学名は画面の上に、大学の切り替えボタンは画面の下に固定する(大学画面と同じ配置)。
//   切り替えは、大学画面の表示(Ghensuu.hyojiunivnum)も一緒に切り替える
// ・全大学を並べて比べたり一括で変えたりする画面(大学画面の「全大学の一覧で設定」)も、
//   今まで通り使える
// ------------------------------------------------------------

/// 実力発揮度を設定する能力(カリスマはレースの計算で使っていないので出さない。
/// Modal_univkosei.dart と同じ)
const List<AbilityType> _hakkiNouryoku = [
  AbilityType.nagakyoriNebari,
  AbilityType.spurtPower,
  AbilityType.noboriTekisei,
  AbilityType.kudariTekisei,
  AbilityType.upDownTaiouryoku,
  AbilityType.roadTekisei,
  AbilityType.paceHendoTaiouryoku,
];

/// 能力の名前
const Map<AbilityType, String> _nouryokuMei = {
  AbilityType.nagakyoriNebari: '長距離粘り',
  AbilityType.spurtPower: 'スパート力',
  AbilityType.charisma: 'カリスマ',
  AbilityType.noboriTekisei: '登り適性',
  AbilityType.kudariTekisei: '下り適性',
  AbilityType.upDownTaiouryoku: 'アップダウン対応力',
  AbilityType.roadTekisei: 'ロード適性',
  AbilityType.paceHendoTaiouryoku: 'ペース変動対応力',
};

/// 留学生の受け入れと優秀度の名前(UnivData.r の0〜4。ModalRyugakuseiNinzu と同じ言葉)
const List<String> _ryuugakuseiMei = [
  '受け入れない',
  '最高優秀',
  '優秀',
  '普通',
  'やや優秀でない',
];

/// 大学の型
class _Kata {
  final String mei; // 型の名前
  // 銀の使い道とスカウト方針の番号(1スピード・2距離走・3登り・4下り・5アップダウン。
  // 年間強化練習メニューと同じ番号。0は標準で、個人の練習メニュー通り・自動)
  final int menu;
  final List<AbilityType> tokui; // 得意な能力(強さに合わせて上げる)
  final List<AbilityType> nigate; // 苦手な能力(強さに合わせて下げる)
  const _Kata(this.mei, this.menu, this.tokui, this.nigate);
}

/// 大学の型の一覧(先頭は標準に戻すもの)
const List<_Kata> _kataList = [
  _Kata('標準', 0, [], []),
  _Kata(
    'スピード型',
    1,
    [AbilityType.spurtPower, AbilityType.paceHendoTaiouryoku],
    [AbilityType.nagakyoriNebari, AbilityType.roadTekisei],
  ),
  _Kata(
    '距離型',
    2,
    [AbilityType.nagakyoriNebari, AbilityType.roadTekisei],
    [AbilityType.spurtPower, AbilityType.paceHendoTaiouryoku],
  ),
  // 山の3つの型は、坂の適性を上げると切れ味が落ちるイメージで、スパート力を苦手にする
  _Kata(
    '山登り型',
    3,
    [AbilityType.noboriTekisei],
    [AbilityType.spurtPower],
  ),
  _Kata(
    '山下り型',
    4,
    [AbilityType.kudariTekisei],
    [AbilityType.spurtPower],
  ),
  _Kata(
    'アップダウン型',
    5,
    [AbilityType.upDownTaiouryoku],
    [AbilityType.spurtPower],
  ),
];

/// 型の強さの名前(0弱め・1普通・2強め)。得意は 5−(強さ+1)、苦手は 5+(強さ+1) にする
const List<String> _tsuyosaMei = ['弱め', '普通', '強め'];

/// 型と強さで決まる実力発揮度(表示する7つの能力)
Map<AbilityType, int> _kataNoHakki(_Kata kata, int tsuyosa) {
  final Map<AbilityType, int> hakki = {
    for (final AbilityType type in _hakkiNouryoku) type: 5,
  };
  for (final AbilityType type in kata.tokui) {
    hakki[type] = 5 - (tsuyosa + 1);
  }
  for (final AbilityType type in kata.nigate) {
    hakki[type] = 5 + (tsuyosa + 1);
  }
  return hakki;
}

/// 実力発揮度の値(0〜9)を、%の文字にする
String _hakkiPercent(int v) => '${150 - v * 10}%';

class ModalDaigakuKosei extends StatefulWidget {
  const ModalDaigakuKosei({super.key});

  @override
  State<ModalDaigakuKosei> createState() => _ModalDaigakuKoseiState();
}

class _ModalDaigakuKoseiState extends State<ModalDaigakuKosei> {
  final Box<Ghensuu> _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final Box<UnivData> _univBox = Hive.box<UnivData>('univBox');

  int _univid = 0; // 表示している大学
  int _tsuyosa = 1; // 大学の型をそろえるときの強さ(0弱め・1普通・2強め)

  @override
  void initState() {
    super.initState();
    final Ghensuu? gh = _ghensuuBox.getAt(0);
    _univid = (gh?.hyojiunivnum ?? 0).clamp(0, TEISUU.UNIVSUU - 1);
  }

  // 大学を切り替える(大学画面の表示も一緒に切り替える)
  Future<void> _kirikae(int atarashii) async {
    int id = atarashii;
    if (id < 0) id = TEISUU.UNIVSUU - 1;
    if (id >= TEISUU.UNIVSUU) id = 0;
    setState(() {
      _univid = id;
    });
    final Ghensuu? gh = _ghensuuBox.getAt(0);
    if (gh != null) {
      gh.hyojiunivnum = id;
      await gh.save();
    }
  }

  // ------------------------------------------------
  // 保存
  // ------------------------------------------------

  // 実力発揮度(8つの能力を4ビットずつ詰めて yobiint5[大学id] に入れる。Modal_univkosei.dart と同じ形)
  int _tsumeru(Map<AbilityType, int> hakki) {
    int tsumeta = 0;
    for (int i = 0; i < AbilityType.values.length; i++) {
      final int v = (hakki[AbilityType.values[i]] ?? 5).clamp(0, 9);
      tsumeta |= (v << (i * 4));
    }
    return tsumeta;
  }

  Future<void> _hakkiHozon(
    KantokuData kantoku,
    AbilityType type,
    int atai,
  ) async {
    if (_univid >= kantoku.yobiint5.length) return;
    final Map<AbilityType, int> hakki = getAbilitySettingsForUniv(_univid);
    hakki[type] = atai;
    final List<int> y = List.from(kantoku.yobiint5);
    y[_univid] = _tsumeru(hakki);
    setState(() {
      kantoku.yobiint5 = y;
    });
    await kantoku.save();
  }

  // 大学の型にそろえる(実力発揮度・銀の使い道・スカウト方針。カリスマの実力発揮度は今のまま)
  Future<void> _kataSoroeru(KantokuData kantoku, _Kata kata, int tsuyosa) async {
    final List<int> y5 = List.from(kantoku.yobiint5);
    final List<int> y2 = List.from(kantoku.yobiint2);
    if (_univid >= y5.length ||
        y2.length <= comGinHoushinIndex1 ||
        y2.length <= comScoutHoushinIndex1) {
      return;
    }
    final Map<AbilityType, int> hakki = getAbilitySettingsForUniv(_univid);
    hakki.addAll(_kataNoHakki(kata, tsuyosa));
    y5[_univid] = _tsumeru(hakki);
    comGinHoushinSettei(y2, _univid, kata.menu);
    comScoutHoushinSettei(y2, _univid, kata.menu);
    setState(() {
      kantoku.yobiint5 = y5;
      kantoku.yobiint2 = y2;
    });
    await kantoku.save();
  }

  // 今の設定と同じ型(と強さ)の名前。どの型とも違えばnull
  String? _imaNoKata(KantokuData kantoku) {
    final Map<AbilityType, int> hakki = getAbilitySettingsForUniv(_univid);
    final int gin = comGinHoushin(kantoku, _univid);
    final int scout = comScoutHoushin(kantoku, _univid);
    for (final _Kata kata in _kataList) {
      if (gin != kata.menu || scout != kata.menu) continue;
      for (int tsuyosa = 0; tsuyosa < _tsuyosaMei.length; tsuyosa++) {
        final Map<AbilityType, int> kataHakki = _kataNoHakki(kata, tsuyosa);
        final bool onaji = _hakkiNouryoku.every(
          (type) => (hakki[type] ?? 5) == kataHakki[type],
        );
        if (onaji) {
          return kata.menu == 0
              ? kata.mei
              : '${kata.mei}(${_tsuyosaMei[tsuyosa]})';
        }
      }
    }
    return null;
  }

  // 大学の型にそろえる前の確認
  Future<void> _kataKakunin(
    KantokuData kantoku,
    UnivData univ,
    _Kata kata,
  ) async {
    final int tsuyosa = _tsuyosa;
    String naiyou;
    if (kata.menu == 0) {
      naiyou =
          '${univ.name}の実力発揮度・銀の使い道・スカウト方針を、標準に戻します。\n\n'
          '・実力発揮度: すべて5(100%)\n'
          '・銀の使い道: 個人の練習メニュー通り\n'
          '・スカウト方針: 自動\n\n'
          'よろしいですか？';
    } else {
      String nouryoku(List<AbilityType> list) =>
          list.map((type) => _nouryokuMei[type] ?? '').join('・');
      naiyou =
          '${univ.name}の実力発揮度・銀の使い道・スカウト方針を、'
          '${kata.mei}(${_tsuyosaMei[tsuyosa]})にそろえます。\n\n'
          '・得意: ${nouryoku(kata.tokui)}を${_hakkiPercent(5 - (tsuyosa + 1))}\n'
          '・苦手: ${nouryoku(kata.nigate)}を${_hakkiPercent(5 + (tsuyosa + 1))}\n'
          '・ほかの能力: 100%\n'
          '・銀の使い道: ${comGinHoushinMei(kata.menu)}\n'
          '・スカウト方針: ${comScoutHoushinMei[kata.menu]}\n\n'
          'よろしいですか？';
    }
    final bool? soroeru = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            kata.menu == 0 ? '標準に戻す' : '${kata.mei}にそろえる',
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Text(naiyou, style: const TextStyle(color: Colors.black)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('やめる'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(kata.menu == 0 ? '戻す' : 'そろえる'),
            ),
          ],
        );
      },
    );
    if (soroeru == true && mounted) {
      await _kataSoroeru(kantoku, kata, tsuyosa);
    }
  }

  // yobiint2 を書き換えて保存する(saidaiIdx まで要素がなければ何もしない)
  Future<void> _hozon2(
    KantokuData kantoku,
    int saidaiIdx,
    void Function(List<int> yobiint2) kakikae,
  ) async {
    final List<int> y = List.from(kantoku.yobiint2);
    if (y.length <= saidaiIdx) return;
    kakikae(y);
    setState(() {
      kantoku.yobiint2 = y;
    });
    await kantoku.save();
  }

  // yobiint3(スカウトの評価の割合と積極性)を書き換えて保存する
  Future<void> _hozon3(
    KantokuData kantoku,
    void Function(List<int> yobiint3) kakikae,
  ) async {
    final List<int> y = List.from(kantoku.yobiint3);
    if (y.length <= comScoutUnivSetteiIndex + TEISUU.UNIVSUU - 1) return;
    kakikae(y);
    setState(() {
      kantoku.yobiint3 = y;
    });
    await kantoku.save();
  }

  // 育成力(10〜150)
  Future<void> _ikuseiHozon(UnivData univ, int atai) async {
    setState(() {
      univ.ikuseiryoku = atai.clamp(10, 150);
    });
    await univ.save();
  }

  // 留学生の受け入れと優秀度(0は受け入れない、1最高優秀〜4)
  Future<void> _ryuugakuseiHozon(UnivData univ, int r) async {
    setState(() {
      univ.r = r;
    });
    await univ.save();
  }

  // ------------------------------------------------
  // 画面の部品
  // ------------------------------------------------

  TextStyle get _honbun =>
      TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);

  // 見出し(育成力・金銀など)
  Widget _midashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.yellowAccent,
          fontSize: HENSUU.fontsize_honbun + 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 見出しの下の説明
  Widget _setsumei(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: HENSUU.textcolor.withOpacity(0.8),
          fontSize: HENSUU.fontsize_honbun - 2,
        ),
      ),
    );
  }

  // 小さな補足(保有量など)
  Widget _hosoku(String text) {
    return Text(
      text,
      style: TextStyle(
        color: HENSUU.textcolor.withOpacity(0.7),
        fontSize: HENSUU.fontsize_honbun - 2,
      ),
    );
  }

  // 項目の1行(項目名は本文と同じ大きさ。入らないときは、プルダウンを次の行に折り返す)
  Widget _koumoku(String mei, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text(mei, style: _honbun),
          control,
        ],
      ),
    );
  }

  // 画面からはみ出さないプルダウン(Modal_comScout.dart と同じ作り)
  // ・入る幅があれば、いちばん長い項目に合わせた幅にする
  // ・スマホの文字を大きくしていて入らない場合は、入る幅まで縮め、
  //   選んでいる項目の文字は「…」で省略する(開いた一覧の項目は折り返して全部表示)
  Widget _hamidasanaiDropdown({
    required int value,
    required List<int> atai,
    required List<String> hyoujiMei,
    required ValueChanged<int> onChanged,
  }) {
    return IntrinsicWidth(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: _honbun,
        items: [
          for (int i = 0; i < atai.length; i++)
            DropdownMenuItem<int>(value: atai[i], child: Text(hyoujiMei[i])),
        ],
        // 選んでいる項目の表示(縦は中央、入らなければ「…」で省略)
        selectedItemBuilder: (context) => [
          for (final String mei in hyoujiMei)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                mei,
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

  // 育成力を増減するボタン
  Widget _zougenBotan(UnivData univ, int sa) {
    return OutlinedButton(
      onPressed: () => _ikuseiHozon(univ, univ.ikuseiryoku + sa),
      style: OutlinedButton.styleFrom(
        foregroundColor: HENSUU.textcolor,
        side: const BorderSide(color: Colors.grey),
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(sa > 0 ? '+$sa' : '−${-sa}'),
    );
  }

  // 前の大学・自分の大学・次の大学のボタン
  Widget _kirikaeBotan(String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final KantokuData? kantoku = _kantokuBox.get('KantokuData');
    final UnivData? univ = _univBox.get(_univid);
    if (kantoku == null || univ == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text('大学の個性', style: TextStyle(color: Colors.white)),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            '設定データがありません',
            style: TextStyle(color: HENSUU.textcolor),
          ),
        ),
      );
    }

    final Ghensuu? gh = _ghensuuBox.getAt(0);
    final int myUnivid = gh?.MYunivid ?? -1;
    final int playerKazeflag = gh?.kazeflag ?? 0;
    final bool jibun = _univid == myUnivid;
    final int scoutHoushin = comScoutHoushin(kantoku, _univid);
    final int timeWariai = comScoutTimeWariai(kantoku);
    final int sekkyokusei = comScoutSekkyokusei(kantoku);
    final Map<AbilityType, int> hakki = getAbilitySettingsForUniv(_univid);
    final String? imaNoKata = _imaNoKata(kantoku);

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('大学の個性', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 大学名(スクロールしない)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              jibun ? '${univ.name}(自分の大学)' : univ.name,
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun + 4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.grey, height: 1),

          // 設定(ここだけスクロールする)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "この大学の個性に関わる設定を、まとめて変えられます。\n"
                      "全大学を並べて比べたり、一括で変えたりするときは、大学画面の「全大学の一覧で設定」の各画面を使ってください。",
                      style: _honbun,
                    ),
                  ),

                  // 大学の型(実力発揮度・銀の使い道・スカウト方針をまとめてそろえる)
                  _midashi('大学の型'),
                  _setsumei(
                    '型を押すと、実力発揮度・銀の使い道・スカウト方針を、その型にまとめてそろえます。'
                    '得意な能力の実力発揮度を上げ、苦手な能力を下げます。'
                    '型は保存しないので、そろえたあとに下の項目で個別に直せます。',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '今の設定: ${imaNoKata ?? '型にそろえていない(個別の設定)'}',
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _koumoku(
                    '強さ',
                    _hamidasanaiDropdown(
                      value: _tsuyosa,
                      atai: List.generate(_tsuyosaMei.length, (i) => i),
                      hyoujiMei: [
                        for (int t = 0; t < _tsuyosaMei.length; t++)
                          '${_tsuyosaMei[t]}(得意${_hakkiPercent(5 - (t + 1))}・'
                              '苦手${_hakkiPercent(5 + (t + 1))})',
                      ],
                      onChanged: (v) => setState(() => _tsuyosa = v),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final _Kata kata in _kataList)
                        OutlinedButton(
                          onPressed: () => _kataKakunin(kantoku, univ, kata),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kata.menu == 0
                                ? HENSUU.textcolor
                                : Colors.lightGreenAccent,
                            side: const BorderSide(color: Colors.grey),
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          child: Text(kata.menu == 0 ? '標準に戻す' : kata.mei),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.grey),

                  // 育成力
                  _midashi('育成力'),
                  _setsumei('選手の基本走力の伸びやすさです(10〜150)。'),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text('育成力 ${univ.ikuseiryoku}', style: _honbun),
                      _zougenBotan(univ, -10),
                      _zougenBotan(univ, -1),
                      _zougenBotan(univ, 1),
                      _zougenBotan(univ, 10),
                    ],
                  ),
                  const Divider(color: Colors.grey),

                  // 金銀
                  _midashi('金銀'),
                  _setsumei(
                    jibun
                        ? '支給レベルと銀の使い道は、コンピュータの大学のときだけ効きます(総監督をする大学を変えたときにそなえて設定できます)。'
                        : 'コンピュータの大学が受け取る金銀の量と、夏合宿での銀の使い道です。',
                  ),
                  if (!isComGoldSilverOn(kantoku))
                    _setsumei(
                      '今は大学画面の「コンピュータ金銀使用」がOFFなので、どの大学も金銀を使いません。',
                    ),
                  _koumoku(
                    '支給レベル',
                    _hamidasanaiDropdown(
                      value: comGoldSilverLevel(kantoku, _univid),
                      atai: List.generate(
                        comGoldSilverLevelMei.length,
                        (i) => i,
                      ),
                      hyoujiMei: List.generate(
                        comGoldSilverLevelMei.length,
                        (level) =>
                            comGoldSilverLevelHyouji(level, playerKazeflag),
                      ),
                      onChanged: (v) => _hozon2(
                        kantoku,
                        comGoldSilverLevelIndex1,
                        (y) => comGoldSilverLevelSettei(y, _univid, v),
                      ),
                    ),
                  ),
                  _koumoku(
                    '銀の使い道',
                    _hamidasanaiDropdown(
                      value: comGinHoushin(kantoku, _univid),
                      atai: List.generate(comGinHoushinMax + 1, (i) => i),
                      hyoujiMei: List.generate(
                        comGinHoushinMax + 1,
                        comGinHoushinMei,
                      ),
                      onChanged: (v) => _hozon2(
                        kantoku,
                        comGinHoushinIndex1,
                        (y) => comGinHoushinSettei(y, _univid, v),
                      ),
                    ),
                  ),
                  _hosoku(
                    '保有 金${comKinHoyuu(kantoku, _univid)} '
                    '銀${comGinHoyuu(kantoku, _univid)}(夏合宿で使います)',
                  ),
                  const Divider(color: Colors.grey),

                  // スカウト
                  _midashi('スカウト'),
                  _setsumei(
                    jibun
                        ? 'スカウトの設定は、コンピュータの大学のときだけ効きます(総監督をする大学を変えたときにそなえて設定できます)。'
                        : 'コンピュータの大学が新入生スカウトで重視する能力や、欲しい選手の基準です。'
                              '詳しいことは、大学画面の「コンピュータスカウト」の説明をご覧ください。',
                  ),
                  if (!isComScoutOn(kantoku))
                    _setsumei(
                      '今は大学画面の「コンピュータスカウト」がOFFなので、スカウトの設定は使われません。',
                    ),
                  _koumoku(
                    '方針',
                    _hamidasanaiDropdown(
                      value: scoutHoushin,
                      atai: List.generate(
                        comScoutHoushinMei.length,
                        (i) => i,
                      ),
                      hyoujiMei: comScoutHoushinMei,
                      onChanged: (v) => _hozon2(
                        kantoku,
                        comScoutHoushinIndex1,
                        (y) => comScoutHoushinSettei(y, _univid, v),
                      ),
                    ),
                  ),
                  _koumoku(
                    '性格',
                    _hamidasanaiDropdown(
                      value: comScoutSeikaku(kantoku, _univid),
                      atai: List.generate(
                        comScoutSeikakuMei.length,
                        (i) => i,
                      ),
                      hyoujiMei: comScoutSeikakuMei,
                      onChanged: (v) => _hozon2(
                        kantoku,
                        comScoutSeikakuIndex1,
                        (y) => comScoutSeikakuSettei(y, _univid, v),
                      ),
                    ),
                  ),
                  // 評価の割合(タイム重視の大学は持ちタイムだけで評価するので選べない)
                  scoutHoushin == comScoutHoushinMei.indexOf('タイム重視')
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '評価の割合(タイム:能力) タイム重視のため、持ちタイムだけで評価',
                            style: _honbun,
                          ),
                        )
                      : _koumoku(
                          '評価の割合(タイム:能力)',
                          _hamidasanaiDropdown(
                            value:
                                comScoutTimeWariaiUnivSettei(
                                  kantoku,
                                  _univid,
                                ) ??
                                -1,
                            atai: [-1, for (int w = 100; w >= 0; w -= 10) w],
                            hyoujiMei: [
                              '共通($timeWariai:${100 - timeWariai})',
                              for (int w = 100; w >= 0; w -= 10)
                                '$w:${100 - w}',
                            ],
                            onChanged: (v) => _hozon3(
                              kantoku,
                              (y) => comScoutTimeWariaiUnivKaku(
                                y,
                                _univid,
                                v < 0 ? null : v,
                              ),
                            ),
                          ),
                        ),
                  _koumoku(
                    '積極性',
                    _hamidasanaiDropdown(
                      value:
                          comScoutSekkyokuseiUnivSettei(kantoku, _univid) ??
                          -1,
                      atai: [-1, for (int p = 0; p <= 100; p += 10) p],
                      hyoujiMei: [
                        '共通($sekkyokusei%)',
                        for (int p = 0; p <= 100; p += 10) '$p%',
                      ],
                      onChanged: (v) => _hozon3(
                        kantoku,
                        (y) => comScoutSekkyokuseiUnivKaku(
                          y,
                          _univid,
                          v < 0 ? null : v,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.grey),

                  // レース(区間配置の方針)
                  _midashi('レース'),
                  _setsumei(
                    jibun
                        ? '区間配置の方針は、自分の大学では区間エントリーの最初の案に使います。'
                        : '区間配置で、前の区間をどのくらい重く見るか(前半重視の強さ)です。'
                              '詳しいことは、大学画面の「区間配置の方針」の説明をご覧ください。',
                  ),
                  _koumoku(
                    '前半重視の強さ',
                    // 前半重視の弱い順に並べる(値は保存する番号のまま。kukanHaichiHoushinNarabi)
                    _hamidasanaiDropdown(
                      value: kukanHaichiHoushin(kantoku, _univid),
                      atai: kukanHaichiHoushinNarabi,
                      hyoujiMei: [
                        for (final int code in kukanHaichiHoushinNarabi)
                          kukanHaichiHoushinMei[code],
                      ],
                      onChanged: (v) => _hozon2(
                        kantoku,
                        kukanHaichiHoushinIndex1,
                        (y) => kukanHaichiHoushinSettei(y, _univid, v),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.grey),

                  // 留学生
                  _midashi('留学生'),
                  _setsumei(
                    '入学の決まりなどは、大学画面の「留学生受け入れ設定」の説明をご覧ください。',
                  ),
                  _koumoku(
                    '受け入れ',
                    // 受け入れない(0)と、受け入れるときの優秀度(1最高優秀〜4)を1つのプルダウンで選ぶ
                    _hamidasanaiDropdown(
                      value: univ.r.clamp(0, 4),
                      atai: List.generate(_ryuugakuseiMei.length, (i) => i),
                      hyoujiMei: _ryuugakuseiMei,
                      onChanged: (v) => _ryuugakuseiHozon(univ, v),
                    ),
                  ),
                  const Divider(color: Colors.grey),

                  // 走りの特徴(実力発揮度。あまり使われないので一番下)
                  _midashi('走りの特徴(実力発揮度)'),
                  _setsumei(
                    'レースで、能力ごとに実力をどれだけ発揮できるかです。'
                    '0が実力150%発揮(有利)、5が100%、9が60%(不利)です。'
                    '留学生には適用されません。',
                  ),
                  for (final AbilityType type in _hakkiNouryoku)
                    _koumoku(
                      _nouryokuMei[type] ?? '',
                      _hamidasanaiDropdown(
                        value: (hakki[type] ?? 5).clamp(0, 9),
                        atai: List.generate(10, (i) => i),
                        hyoujiMei: [
                          for (int v = 0; v <= 9; v++)
                            '$v(${150 - v * 10}%)',
                        ],
                        onChanged: (v) => _hakkiHozon(kantoku, type, v),
                      ),
                    ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 24),

                  Center(
                    child: ElevatedButton(
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 大学の切り替え(スクロールしない。大学画面と同じく画面の下)
          const Divider(color: Colors.grey, height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _kirikaeBotan('前の大学', () => _kirikae(_univid - 1)),
                  _kirikaeBotan('自分の大学', () => _kirikae(myUnivid)),
                  _kirikaeBotan('次の大学', () => _kirikae(_univid + 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
