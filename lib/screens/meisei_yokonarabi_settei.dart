import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/meisei_yokonarabi.dart';
import 'package:ekiden/kansuu/meisei_henshuu.dart'; // グループの編集で名声も変える(2.0.3)

// ------------------------------------------------------------
// 説明画面の設定タブの「名声の横並び設定」(2.0.3)
// 名声の順位のブロックや、決めた大学のグループごとに、新入生のスカウトでは同じ名声として扱う設定
// (仕組みと保存先は lib/kansuu/meisei_yokonarabi.dart)。
// ・2.0.2は「名声上位の横並び」として入学時名声影響度設定の画面の中にあった。2.0.3でブロック・グループ・
//   名声の編集まで広がったので、独立した画面にした(入学時名声影響度設定の画面には、案内と開くボタンを残す)
// ・1画面にまとめる: 上から説明・決め方・今のブロック(グループ)・そろえ方、その下に、選んでいる決め方の編集
//   ・名声の順位で区切る: 2位〜30位の行ごとに「上の順位と同じブロック」のチェック(重なりやすき間が起きない)と、
//     よく使う形(なし・5校ずつ・10校ずつ・上位何校)。行に大学名は出さない(大学で決まると読み違えないように)。
//     30校を1つのブロックにはできない
//   ・大学を決めてまとめる: 大学ごとにグループ(なし・1〜9)と名声を決める。グループの強さは入れた大学の名声で
//     決まるので、名声も変えられる(名声設定の画面と同じ変え方。meisei_henshuu.dart)。開いている間は行の並びを
//     変えず、名声と「名声○位」だけをすぐ変える(続けて変えるときに行が飛ばないように)。「名声の順に並べ直す」で
//     並べ直せる。今のグループには、スカウトでの名声(そろえたあとの値)を添える
// ・変えるたびに保存する
// ------------------------------------------------------------

/// 名声の横並び設定の画面を開く(設定タブと、入学時名声影響度設定の画面の案内から)
Future<void> meiseiYokonarabiSetteiHiraku(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: '名声の横並び設定', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const ModalMeiseiYokonarabiSettei();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class ModalMeiseiYokonarabiSettei extends StatefulWidget {
  const ModalMeiseiYokonarabiSettei({super.key});

  @override
  State<ModalMeiseiYokonarabiSettei> createState() => _ModalMeiseiYokonarabiSetteiState();
}

class _ModalMeiseiYokonarabiSetteiState extends State<ModalMeiseiYokonarabiSettei> {
  /// グループごとの行の色(グループ1〜9。なしは色なし)
  static const List<Color> _groupIro = [
    Color(0xFF004D40),
    Color(0xFF1A237E),
    Color(0xFF4A148C),
    Color(0xFF3E2723),
    Color(0xFF263238),
    Color(0xFF33691E),
    Color(0xFF880E4F),
    Color(0xFF01579B),
    Color(0xFF5D4037),
  ];

  /// 大学のグループの行の並び(大学id。開いたときと「名声の順に並べ直す」を押したときの名声の順)
  List<int> _narabi = [];

  /// 名声の入力欄(大学idごと)
  final Map<int, TextEditingController> _meiseiCtrl = {};
  final Map<int, FocusNode> _meiseiFocus = {};

  /// 名声を保存している途中か
  bool _hozonChuu = false;

  @override
  void initState() {
    super.initState();
    _narabiNaoshi();
  }

  @override
  void dispose() {
    for (final TextEditingController c in _meiseiCtrl.values) {
      c.dispose();
    }
    for (final FocusNode f in _meiseiFocus.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// 大学(id 0〜29)
  List<UnivData> _univs() => [
    for (final UnivData u in Hive.box<UnivData>('univBox').values)
      if (u.id >= 0 && u.id < yokonarabiJuniSuu) u,
  ];

  /// 名声の高い順(同じなら大学idの小さい順)
  List<UnivData> _meiseiJun(List<UnivData> univs) => List<UnivData>.of(univs)
    ..sort((a, b) {
      final int c = b.meisei_total.compareTo(a.meisei_total);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  /// 大学のグループの行の並びを、今の名声の順にする
  void _narabiNaoshi() {
    _narabi = [for (final UnivData u in _meiseiJun(_univs())) u.id];
  }

  Future<void> _hozon(KantokuData k) async {
    await k.save();
    if (mounted) setState(() {});
  }

  /// 名声の順位のつなぎを変える(30校が1つのブロックになるときは変えずにお知らせ)
  Future<void> _tsunagiIreru(KantokuData k, int tsunagi) async {
    if (yokonarabiTsunagiZenbu(tsunagi)) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('30校すべてを1つのブロックにはできません(名声の影響がなくなるため)。')),
        );
      return;
    }
    yokonarabiTsunagiIreru(k, tsunagi);
    await _hozon(k);
  }

  /// 大学[u]の名声の入力欄(なければ作る。入力欄から離れたら確定する)
  TextEditingController _ctrl(UnivData u) {
    return _meiseiCtrl.putIfAbsent(u.id, () {
      final FocusNode f = FocusNode();
      f.addListener(() {
        if (!f.hasFocus) _meiseiKakutei(u.id);
      });
      _meiseiFocus[u.id] = f;
      return TextEditingController(text: '${u.meisei_total}');
    });
  }

  /// 入力した名声を確定する(範囲の外や数字でなければ、もとの名声に戻す)
  /// (画面を閉じたあとに入力欄から離れたときは何もしない。入力欄は閉じるときに片付けるため)
  Future<void> _meiseiKakutei(int univid) async {
    if (!mounted) return;
    final TextEditingController? c = _meiseiCtrl[univid];
    final UnivData? u = Hive.box<UnivData>('univBox').get(univid);
    if (c == null || u == null || _hozonChuu) return;
    final int? atai = int.tryParse(c.text.trim());
    final int saidai = meiseiHenshuuSaidai(_univs());
    if (atai == null || atai < meiseiHenshuuSaishou || atai > saidai) {
      c.text = '${u.meisei_total}';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('名声は${meiseiHenshuuSaishou}から${saidai}の間で入れてください。')),
        );
      return;
    }
    if (atai == u.meisei_total) return;
    _hozonChuu = true;
    await meiseiHenshuu(u, atai);
    _hozonChuu = false;
    if (mounted) setState(() {});
  }

  TextStyle get _honbun => const TextStyle(
    color: HENSUU.textcolor,
    fontSize: HENSUU.fontsize_honbun,
  );

  TextStyle get _hosoku => TextStyle(
    color: HENSUU.textcolor.withOpacity(0.7),
    fontSize: HENSUU.fontsize_honbun - 2,
  );

  /// 選択チップ(監督の母校パイプ設定と同じ形。選んでいるほうに✓を付け、色を変える。
  /// 表示の設定で✓が出なくならないように、✓は必ず出す)
  Widget _chip(String label, bool selected, Future<void> Function() onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: Colors.white,
      onSelected: (bool s) async {
        if (!s || selected) return;
        await onSelected();
      },
      selectedColor: Colors.teal.shade700,
      backgroundColor: Colors.grey.shade800,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: HENSUU.fontsize_honbun,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    final AppBar appBar = AppBar(
      title: const Text('名声の横並び設定', style: TextStyle(color: Colors.white)),
      backgroundColor: HENSUU.backgroundcolor,
      foregroundColor: Colors.white,
    );
    if (k == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: appBar,
        body: const SizedBox.shrink(),
      );
    }
    final int tsunagi = yokonarabiTsunagi(k);
    final int houhou = yokonarabiHouhou(k);
    final bool daigaku = yokonarabiKata(k) == yokonarabiKataDaigaku;
    final bool kiku = YokonarabiSettei.yomu(k).kiku;
    final List<UnivData> univs = _univs();
    final List<int> group = yokonarabiGroupRetsu(k);
    final List<({int group, List<UnivData> univs})> ichiran =
        daigaku ? yokonarabiGroupIchiran(group, univs) : const [];
    // スカウトでの名声(そろえたあとの値。名声やグループを変えるとすぐ変わる)
    final Map<int, int> scoutMeisei = daigaku
        ? scoutMeiseiMap(univs, YokonarabiSettei(0, houhou == yokonarabiIchii, group: group))
        : const {};
    final String matomari = daigaku ? 'グループ' : 'ブロック';
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: appBar,
      body: SafeArea(
        child: GestureDetector(
          // 入力欄の外を押したら、キーボードを閉じて名声を確定する
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '名声の順位のブロック(例えば1〜3位・4〜8位)や、決めた大学のグループごとに、新入生のスカウトでは同じ名声として扱います。'
                '名声1位の大学をスカウトで抜け出しにくくしたり、名門のグループを長く強いままにしたりできます。'
                '名声の表示や、目標順位・獲得名声などには影響しません。\n'
                '入学時名声影響度設定のレベルと組み合わせて効きます。この設定は次の新入生スカウトから影響します。',
                style: _honbun,
              ),
              const SizedBox(height: 16),
              // 決め方(名声の順位で区切る(初期値)・大学を決めてまとめる。どちらか一方だけが効く)
              Text('決め方', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('名声の順位で区切る(初期値)', !daigaku, () async {
                    yokonarabiKataIreru(k, yokonarabiKataJuni);
                    await _hozon(k);
                  }),
                  _chip('大学を決めてまとめる', daigaku, () async {
                    yokonarabiKataIreru(k, yokonarabiKataDaigaku);
                    await _hozon(k);
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                daigaku
                    ? '大学を決めてまとめる: グループに入れた大学は、名声の順位が変わっても同じ顔ぶれのままです。'
                    : '名声の順位で区切る: 名声の順が入れ替わると、ブロックに入る大学も入れ替わります。',
                style: _hosoku,
              ),
              const SizedBox(height: 16),
              // 今のブロックかグループ
              if (!daigaku)
                Text(
                  '今のブロック: ${tsunagi == 0 ? 'なし(初期値)' : yokonarabiBlockMoji(tsunagi)}',
                  style: _honbun.copyWith(fontWeight: FontWeight.bold),
                )
              else if (ichiran.isEmpty)
                Text('今のグループ: なし', style: _honbun.copyWith(fontWeight: FontWeight.bold))
              else
                for (final ({int group, List<UnivData> univs}) g in ichiran)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'グループ${g.group}: ${g.univs.map((UnivData u) => '${u.name}大学').join('・')}'
                      '${g.univs.length < 2 ? '(1校だけなので効きません)' : '(スカウトでの名声 ${scoutMeisei[g.univs.first.id] ?? g.univs.first.meisei_total})'}',
                      style: _honbun.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
              const SizedBox(height: 16),
              // そろえ方(平均(初期値)・一番上。全部のブロック・グループで共通)
              Text('そろえ方(全部の$matomariで共通)', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('${yokonarabiHouhouMei(yokonarabiHeikin)}(初期値)', houhou == yokonarabiHeikin, () async {
                    yokonarabiHouhouIreru(k, yokonarabiHeikin);
                    await _hozon(k);
                  }),
                  _chip(yokonarabiHouhouMei(yokonarabiIchii), houhou == yokonarabiIchii, () async {
                    yokonarabiHouhouIreru(k, yokonarabiIchii);
                    await _hozon(k);
                  }),
                ],
              ),
              // ブロック(グループ)が効かないときは、そろえ方も効かない
              if (!kiku) ...[
                const SizedBox(height: 8),
                Text(
                  daigaku ? 'そろえ方は、2校以上のグループを作ると効きます。' : 'そろえ方は、ブロックを決めると効きます。',
                  style: _hosoku,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                houhou == yokonarabiIchii
                    ? '一番上にそろえる: $matomariの大学がみな、その中で名声が一番高い大学と同じくらい選ばれやすくなり、その分、ほかの大学は選ばれにくくなります。'
                    : '平均にそろえる: $matomariの大学の名声の平均にそろえます。まとめた選ばれやすさは今のままで、ほかの大学の選ばれやすさは変わりません。',
                style: _hosoku,
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              // 選んでいる決め方の編集
              if (daigaku)
                ..._groupHenshuu(k, univs, group)
              else
                ..._blockHenshuu(k, tsunagi),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
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
                    '閉じる',
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

  /// 名声の順位のブロックの編集(2位〜30位の行ごとのチェックと、よく使う形)
  List<Widget> _blockHenshuu(KantokuData k, int tsunagi) {
    // 順位ごとのブロックの番号(2校以上のブロックだけ。上から0,1,2…。ブロックでない順位は-1)。行の色分けに使う
    final List<int> blockBan = List<int>.filled(yokonarabiJuniSuu + 1, -1);
    final List<({int kara, int made})> block = yokonarabiBlock(tsunagi);
    for (int i = 0; i < block.length; i++) {
      for (int juni = block[i].kara; juni <= block[i].made; juni++) {
        blockBan[juni] = i;
      }
    }
    Color? gyouIro(int juni) {
      final int b = blockBan[juni];
      if (b < 0) return null;
      return b.isEven ? Colors.teal.shade900 : Colors.indigo.shade900;
    }

    // 今のつなぎが上位何校の形なら、その校数(プルダウンに出す)
    int? jouiSuu;
    for (int n = yokonarabiSaishou; n <= yokonarabiSaidai; n++) {
      if (yokonarabiJouiTsunagi(n) == tsunagi) jouiSuu = n;
    }
    return [
      Text('ブロックの編集', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(
        'ブロックは名声の順位で決まります。大学を決めてまとめたいときは、上の決め方で「大学を決めてまとめる」を選んでください。',
        style: _hosoku,
      ),
      const SizedBox(height: 12),
      // よく使う形
      Text('よく使う形', style: _honbun),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => _tsunagiIreru(k, 0),
            child: Text('なし', style: _honbun),
          ),
          OutlinedButton(
            onPressed: () => _tsunagiIreru(k, yokonarabiZutsuTsunagi(5)),
            child: Text('5校ずつ', style: _honbun),
          ),
          OutlinedButton(
            onPressed: () => _tsunagiIreru(k, yokonarabiZutsuTsunagi(10)),
            child: Text('10校ずつ', style: _honbun),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // 上位何校を1つのブロックにする(2.0.2の形。プルダウン。文字が大きくてもメニューはスクロールできる)
      Text('上位の何校を1つのブロックにする', style: _honbun),
      DropdownButton<int>(
        value: jouiSuu,
        hint: Text('選ぶ', style: _honbun),
        dropdownColor: Colors.grey[900],
        style: _honbun.copyWith(fontWeight: FontWeight.bold),
        items: [
          for (int n = yokonarabiSaishou; n <= yokonarabiSaidai; n++)
            DropdownMenuItem<int>(value: n, child: Text(yokonarabiMei(n))),
        ],
        onChanged: (int? n) {
          if (n == null) return;
          _tsunagiIreru(k, yokonarabiJouiTsunagi(n));
        },
      ),
      const SizedBox(height: 16),
      // 順位ごと
      Text('順位ごとに決める', style: _honbun),
      const SizedBox(height: 4),
      Text(
        '「上の順位と同じブロック」にチェックを付けると、その順位は上の順位と同じブロックになります。'
        '同じブロックの順位は、同じ色で並びます。',
        style: _hosoku,
      ),
      const SizedBox(height: 8),
      for (int juni = 1; juni <= yokonarabiJuniSuu; juni++)
        if (juni == 1)
          ListTile(
            tileColor: gyouIro(juni),
            title: Text('1位', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
          )
        else
          CheckboxListTile(
            tileColor: gyouIro(juni),
            value: yokonarabiTsunagaru(tsunagi, juni - 1),
            onChanged: (bool? v) {
              if (v == null) return;
              _tsunagiIreru(k, yokonarabiTsunagiKae(tsunagi, juni - 1, v));
            },
            title: Text('$juni位', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('上の順位(${juni - 1}位)と同じブロック', style: _hosoku),
            activeColor: Colors.teal,
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white70, width: 2),
          ),
    ];
  }

  /// 大学のグループの編集(大学ごとのグループと名声)
  List<Widget> _groupHenshuu(KantokuData k, List<UnivData> univs, List<int> group) {
    final Map<int, UnivData> univMap = {for (final UnivData u in univs) u.id: u};
    final bool groupAri = group.any((int g) => g > 0);
    // 今の名声の順位(大学id → 1位から)
    final List<UnivData> imaJun = _meiseiJun(univs);
    final Map<int, int> juni = {
      for (int i = 0; i < imaJun.length; i++) imaJun[i].id: i + 1,
    };
    final Box<Ghensuu> gb = Hive.box<Ghensuu>('ghensuuBox');
    final int myUnivId = gb.isNotEmpty ? (gb.getAt(0)?.MYunivid ?? -1) : -1;
    int groupBan(int id) => (id >= 0 && id < group.length) ? group[id] : 0;
    return [
      Text('グループの編集', style: _honbun.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(
        'グループは1〜9の9個まで作れ、1校だけのグループは効きません。あなたの大学も入れられます。'
        'グループの強さは、入れた大学の名声で決まります(平均か一番上にそろえます)。'
        'ここで変えた名声は、名声設定で変えたのと同じく、名声の表示や目標順位などにも効きます。',
        style: _hosoku,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: !groupAri
                ? null
                : () async {
                    yokonarabiGroupZenbuNashi(k);
                    await _hozon(k);
                  },
            child: Text('すべてなしにする', style: _honbun),
          ),
          OutlinedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(_narabiNaoshi);
            },
            child: Text('名声の順に並べ直す', style: _honbun),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '大学は、この画面を開いたときの名声の高い順に並んでいます(名声を変えても並びは変わりません)。'
        '同じグループの大学は、同じ色で並びます。名声は、数字を入れて入力欄の外を押すと変わります。',
        style: _hosoku,
      ),
      const SizedBox(height: 8),
      for (final int id in _narabi)
        if (univMap[id] != null)
          Container(
            color: groupBan(id) >= 1 && groupBan(id) <= _groupIro.length ? _groupIro[groupBan(id) - 1] : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('名声${juni[id] ?? 0}位', style: _hosoku),
                Text(
                  '${univMap[id]!.name}大学${id == myUnivId ? '(あなたの大学)' : ''}',
                  style: _honbun.copyWith(
                    fontWeight: FontWeight.bold,
                    color: id == myUnivId ? Colors.amber : HENSUU.textcolor,
                  ),
                ),
                // 名声(数字を入れて、完了か入力欄の外を押すと確定)
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _ctrl(univMap[id]!),
                    focusNode: _meiseiFocus[id],
                    keyboardType: TextInputType.number,
                    style: _honbun,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: '名声',
                      labelStyle: _hosoku,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                DropdownButton<int>(
                  value: groupBan(id),
                  dropdownColor: Colors.grey[900],
                  style: _honbun.copyWith(fontWeight: FontWeight.bold),
                  items: [
                    for (int g = 0; g <= yokonarabiGroupSaidai; g++)
                      DropdownMenuItem<int>(value: g, child: Text(g == 0 ? 'なし' : 'グループ$g')),
                  ],
                  onChanged: (int? g) async {
                    if (g == null) return;
                    yokonarabiGroupIreru(k, id, g);
                    await _hozon(k);
                  },
                ),
              ],
            ),
          ),
    ];
  }
}
