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
//   走りの特徴: 実力発揮度(KantokuData.yobiint5[大学id]。univkosei.dart)
//   育て方: 育成力(UnivData.ikuseiryoku)と、金銀の支給レベル・銀の使い道(goldsilver_com.dart)
//   スカウト: 方針・性格(yobiint2)と、評価の割合・積極性(yobiint3。scout_com.dart)
//   レース: 区間配置の方針(kukan_haichi.dart)
//   留学生: 受け入れと優秀度(UnivData.r。0は受け入れない、1最高優秀〜4)
// 全大学を並べて比べたり一括で変えたりする画面(大学画面の「全大学の一覧で設定」)も、
// 今まで通り使える。
// 大学の切り替えは、大学画面の表示(Ghensuu.hyojiunivnum)も一緒に切り替える。
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

/// 留学生の優秀度の名前(UnivData.r。ModalRyugakuseiNinzu と同じ)
String _ryuugakuseiYuushuudo(int r) {
  switch (r) {
    case 1:
      return '最高優秀';
    case 2:
      return '優秀';
    case 3:
      return '普通';
    case 4:
      return 'やや優秀でない';
    default:
      return '受け入れない';
  }
}

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
  // スライダーを動かしている間の値(離したときに保存する)
  Map<AbilityType, int> _hakki = {};
  int _ikuseiryoku = 10;
  int _ryuugakuseiR = 0;

  @override
  void initState() {
    super.initState();
    final Ghensuu? gh = _ghensuuBox.getAt(0);
    _univid = (gh?.hyojiunivnum ?? 0).clamp(0, TEISUU.UNIVSUU - 1);
    _yomikomi();
  }

  // 表示している大学の、スライダーで動かす値を読み込む
  void _yomikomi() {
    _hakki = getAbilitySettingsForUniv(_univid);
    final UnivData? univ = _univBox.get(_univid);
    _ikuseiryoku = univ?.ikuseiryoku ?? 10;
    _ryuugakuseiR = univ?.r ?? 0;
  }

  // 大学を切り替える(大学画面の表示も一緒に切り替える)
  Future<void> _kirikae(int atarashii) async {
    int id = atarashii;
    if (id < 0) id = TEISUU.UNIVSUU - 1;
    if (id >= TEISUU.UNIVSUU) id = 0;
    setState(() {
      _univid = id;
      _yomikomi();
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
  Future<void> _hakkiHozon(KantokuData kantoku) async {
    if (_univid >= kantoku.yobiint5.length) return;
    int atai = 0;
    for (int i = 0; i < AbilityType.values.length; i++) {
      final int v = (_hakki[AbilityType.values[i]] ?? 5).clamp(0, 9);
      atai |= (v << (i * 4));
    }
    final List<int> y = List.from(kantoku.yobiint5);
    y[_univid] = atai;
    setState(() {
      kantoku.yobiint5 = y;
    });
    await kantoku.save();
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
    final int v = atai.clamp(10, 150);
    setState(() {
      _ikuseiryoku = v;
      univ.ikuseiryoku = v;
    });
    await univ.save();
  }

  // 留学生の受け入れと優秀度(0は受け入れない、1最高優秀〜4)
  Future<void> _ryuugakuseiHozon(UnivData univ, int r) async {
    setState(() {
      _ryuugakuseiR = r;
      univ.r = r;
    });
    await univ.save();
  }

  // ------------------------------------------------
  // 画面の部品
  // ------------------------------------------------

  // 見出し(走りの特徴など)
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

  // プルダウンの前に付ける小さな見出し
  Widget _komidashi(String text) {
    return Text(
      text,
      style: TextStyle(
        color: HENSUU.textcolor.withOpacity(0.7),
        fontSize: HENSUU.fontsize_honbun - 2,
      ),
    );
  }

  // 見出しとプルダウンの組(画面が狭いときは、プルダウンを縮めて文字を「…」で省略する)
  Widget _kumi(String midashi, Widget dropdown) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _komidashi(midashi),
        const SizedBox(width: 6),
        Flexible(child: dropdown),
      ],
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
        style: TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
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

  // 実力発揮度の1行(能力の名前と今の値、スライダー)
  Widget _hakkiGyou(KantokuData kantoku, AbilityType type) {
    final int v = (_hakki[type] ?? 5).clamp(0, 9);
    // 0が最も有利なので、緑から赤へ
    final Color iro = Color.lerp(Colors.green, Colors.red.shade700, v / 9)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_nouryokuMei[type] ?? ''}  実力${150 - v * 10}%発揮($v)',
          style: TextStyle(
            color: v == 5 ? HENSUU.textcolor : iro,
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: v.toDouble(),
          min: 0,
          max: 9,
          divisions: 9,
          label: '$v',
          onChanged: (double atai) {
            // 動かしている間は表示だけ変える
            setState(() {
              _hakki[type] = atai.toInt();
            });
          },
          onChangeEnd: (double atai) {
            _hakki[type] = atai.toInt();
            _hakkiHozon(kantoku);
          },
          activeColor: iro,
          inactiveColor: Colors.grey.withOpacity(0.5),
        ),
      ],
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
    final TextStyle honbun = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun,
    );

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('大学の個性', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 大学の切り替え
              Row(
                children: [
                  _kirikaeBotan('前の大学', () => _kirikae(_univid - 1)),
                  _kirikaeBotan('自分の大学', () => _kirikae(myUnivid)),
                  _kirikaeBotan('次の大学', () => _kirikae(_univid + 1)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                jibun ? '${univ.name}(自分の大学)' : univ.name,
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun + 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
                  style: honbun,
                ),
              ),

              // 走りの特徴(実力発揮度)
              _midashi('走りの特徴(実力発揮度)'),
              _setsumei(
                'レースで、能力ごとに実力をどれだけ発揮できるかです。'
                '0が実力150%発揮(有利)、5が100%、9が60%(不利)です。'
                '留学生には適用されません。',
              ),
              for (final AbilityType type in _hakkiNouryoku)
                _hakkiGyou(kantoku, type),
              const Divider(color: Colors.grey),

              // 育て方(育成力と金銀)
              _midashi('育て方'),
              _setsumei('育成力は、選手の基本走力の伸びやすさです(10〜150)。'),
              Row(
                children: [
                  Expanded(child: Text('育成力 $_ikuseiryoku', style: honbun)),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    color: HENSUU.textcolor,
                    onPressed: () => _ikuseiHozon(univ, _ikuseiryoku - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: HENSUU.textcolor,
                    onPressed: () => _ikuseiHozon(univ, _ikuseiryoku + 1),
                  ),
                ],
              ),
              Slider(
                value: _ikuseiryoku.clamp(10, 150).toDouble(),
                min: 10,
                max: 150,
                divisions: 140,
                label: '$_ikuseiryoku',
                onChanged: (double atai) {
                  setState(() {
                    _ikuseiryoku = atai.toInt();
                  });
                },
                onChangeEnd: (double atai) {
                  _ikuseiHozon(univ, atai.toInt());
                },
              ),
              const SizedBox(height: 8),
              _setsumei(
                jibun
                    ? '金銀の支給レベルと銀の使い道は、コンピュータの大学のときだけ効きます(総監督をする大学を変えたときにそなえて設定できます)。'
                    : '金銀の支給レベルと銀の使い道は、コンピュータの大学が夏合宿で使う金銀の量と使い道です。',
              ),
              if (!isComGoldSilverOn(kantoku))
                _setsumei('今は大学画面の「コンピュータ金銀使用」がOFFなので、どの大学も金銀を使いません。'),
              _komidashi(
                '保有 金${comKinHoyuu(kantoku, _univid)} '
                '銀${comGinHoyuu(kantoku, _univid)}',
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  _kumi(
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
                  _kumi(
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
                ],
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
                _setsumei('今は大学画面の「コンピュータスカウト」がOFFなので、スカウトの設定は使われません。'),
              _kumi(
                '方針',
                _hamidasanaiDropdown(
                  value: scoutHoushin,
                  atai: List.generate(comScoutHoushinMei.length, (i) => i),
                  hyoujiMei: comScoutHoushinMei,
                  onChanged: (v) => _hozon2(
                    kantoku,
                    comScoutHoushinIndex1,
                    (y) => comScoutHoushinSettei(y, _univid, v),
                  ),
                ),
              ),
              _kumi(
                '性格',
                _hamidasanaiDropdown(
                  value: comScoutSeikaku(kantoku, _univid),
                  atai: List.generate(comScoutSeikakuMei.length, (i) => i),
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
                      child: _komidashi('評価の割合 タイム重視のため、持ちタイムだけで評価'),
                    )
                  : _kumi(
                      '評価の割合(タイム:能力)',
                      _hamidasanaiDropdown(
                        value:
                            comScoutTimeWariaiUnivSettei(kantoku, _univid) ??
                            -1,
                        atai: [-1, for (int w = 100; w >= 0; w -= 10) w],
                        hyoujiMei: [
                          '共通($timeWariai:${100 - timeWariai})',
                          for (int w = 100; w >= 0; w -= 10) '$w:${100 - w}',
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
              _kumi(
                '積極性',
                _hamidasanaiDropdown(
                  value: comScoutSekkyokuseiUnivSettei(kantoku, _univid) ?? -1,
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
              _kumi(
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('留学生を受け入れる', style: honbun),
                subtitle: Text(
                  _ryuugakuseiR > 0
                      ? '受け入れ中(${_ryuugakuseiYuushuudo(_ryuugakuseiR)})'
                      : '受け入れない',
                  style: TextStyle(
                    color: _ryuugakuseiR > 0 ? Colors.lightGreen : Colors.grey,
                  ),
                ),
                value: _ryuugakuseiR > 0,
                // 受け入れに変えたときは、最も優秀な1にする(ModalRyugakuseiNinzu と同じ)
                onChanged: (bool ukeireru) =>
                    _ryuugakuseiHozon(univ, ukeireru ? 1 : 0),
                activeColor: Colors.blue,
              ),
              if (_ryuugakuseiR > 0) ...[
                // 優秀度のスライダー(右端が最高優秀のr=1、左端がr=4)
                Slider(
                  value: (5 - _ryuugakuseiR.clamp(1, 4)).toDouble(),
                  min: 1,
                  max: 4,
                  divisions: 3,
                  label: _ryuugakuseiYuushuudo(_ryuugakuseiR),
                  onChanged: (double atai) {
                    setState(() {
                      _ryuugakuseiR = 5 - atai.toInt();
                    });
                  },
                  onChangeEnd: (double atai) {
                    _ryuugakuseiHozon(univ, 5 - atai.toInt());
                  },
                  activeColor: Colors.teal,
                  inactiveColor: Colors.grey.withOpacity(0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _komidashi('最低優秀'),
                    _komidashi('最高優秀'),
                  ],
                ),
              ],
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
