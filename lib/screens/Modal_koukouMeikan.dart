import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/koukou.dart';
import 'package:ekiden/kansuu/koukou_meibo.dart';
import 'package:ekiden/kansuu/time_date.dart';

// ------------------------------------------------------------
// 高校名鑑(1.9.5。説明画面の設定タブの「高校名鑑」から開く)
// ・「名門校」(名門校のタイプ・留学生・紹介文・集まりやすい選手・優勝回数)と、
//   「都道府県別」(全校の名門度・タイプ・留学生・優勝回数。地区ごとに折りたたみ。高校を押すと編集)と、
//   「大会の記録」(直近10回の全国高校駅伝と高校総体。koukou.dart の koukouTaikaiKirokuYomu。見出しごとに折りたたみ)を、
//   タブで切り替える
// ・名簿は koukouMeibo(初期値に、この画面で変えた分を重ねたもの)から作る
// ・高校の情報を表示しない設定のときも開ける(自分で開く画面なので)
// ・文字を大きくしている人がいるので、横並びは Wrap にし、高さは固定しない
// ------------------------------------------------------------

const Color _kin = Color(0xFFE3B95C); // 名門・都道府県名
const Color _usui = Color(0xFFB0B8B3); // 補足の文字
const Color _waku = Color(0xFF2C3430); // カードの枠
const Color _kaado = Color(0xFF151917); // カードの地
const List<Color> _iroNoIro = [
  Color(0xFFFF8A70), // スピード型
  Color(0xFF72C4A2), // 駅伝型
  Color(0xFFD9C27A), // 起伏型
];

const TextStyle _honbun = TextStyle(
  color: HENSUU.textcolor,
  fontSize: HENSUU.fontsize_honbun,
);
const TextStyle _hosoku = TextStyle(
  color: _usui,
  fontSize: HENSUU.fontsize_honbun - 2,
);

int _iroBan(int iro) => iro.clamp(0, koukouIroMei.length - 1).toInt();

/// 地区の順(全国高校駅伝の地区代表の区切り)、地区の中は都道府県の順、都道府県の中は名簿の順の、高校の番号
List<int> _chikuJun(List<KoukouMei> meibo) {
  final List<int> jun = [];
  for (int c = 0; c < koukouChikuMei.length; c++) {
    for (int ken = 0; ken < koukouKenChiku.length; ken++) {
      if (koukouKenChiku[ken] != c) continue;
      for (int i = 0; i < meibo.length; i++) {
        if (meibo[i].ken == ken) jun.add(i);
      }
    }
  }
  return jun;
}

/// 枠で囲んだ小さな札(タイプ・留学生)
Widget _fuda(String text, Color iro) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: iro),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: iro,
        fontSize: HENSUU.fontsize_honbun - 3,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _iroFuda(int iro) => _fuda(koukouIroMei[_iroBan(iro)], _iroNoIro[_iroBan(iro)]);

/// 折りたたみの見出しと中身(説明書タブと同じ見た目)
class _Oritatami extends StatefulWidget {
  const _Oritatami({
    super.key,
    required this.midashi,
    required this.naka,
    this.hajimeHiraku = false,
    this.kin = false,
    this.futoi = true,
  });

  final String midashi;
  final List<Widget> naka;

  /// 最初から開いておくか
  final bool hajimeHiraku;

  /// 見出しを金色にするか(中の見出し)
  final bool kin;

  /// 見出しを太字にするか
  final bool futoi;

  @override
  State<_Oritatami> createState() => _OritatamiState();
}

class _OritatamiState extends State<_Oritatami> {
  late bool _hiraki = widget.hajimeHiraku;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _hiraki = !_hiraki),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _hiraki ? Icons.expand_more : Icons.chevron_right,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.midashi,
                    style: TextStyle(
                      color: widget.kin ? _kin : HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: widget.futoi ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hiraki)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.naka,
            ),
          ),
      ],
    );
  }
}

class ModalKoukouMeikan extends StatefulWidget {
  const ModalKoukouMeikan({super.key});

  @override
  State<ModalKoukouMeikan> createState() => _ModalKoukouMeikanState();
}

class _ModalKoukouMeikanState extends State<ModalKoukouMeikan> {
  int _kousinBan = 0; // 高校を編集したら増やして、名門校のタブも作り直す

  void _kousin() => setState(() => _kousinBan++);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text('高校名鑑', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: '名門校'),
              Tab(text: '都道府県別'),
              Tab(text: '大会の記録'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _MeimonShoukai(key: ValueKey<int>(_kousinBan)),
            _KenBetsu(onHenkou: _kousin),
            const _TaikaiKiroku(),
          ],
        ),
      ),
    );
  }
}

/// 名門校の紹介
class _MeimonShoukai extends StatelessWidget {
  const _MeimonShoukai({super.key});

  @override
  Widget build(BuildContext context) {
    final List<KoukouMei> meibo = koukouMeiboGenzai();
    final List<int> meimon = [
      for (final int i in _chikuJun(meibo))
        if (meibo[i].meimon == 3) i,
    ];
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '全国高校駅伝の常連で、県外からも選手が集まる名門${meimon.length}校です。'
          'タイプによって、入ってくる選手の傾向が変わります。'
          '出場回数と優勝回数は、毎年4月上旬に新入生が入るときに増えます。',
          style: _honbun,
        ),
        const SizedBox(height: 12),
        for (final int i in meimon)
          _kaadoWidget(
            meibo[i],
            i < kai.zenkoku.length ? kai.zenkoku[i] : 0,
            kai.chikuDaihyou(i),
            i < kai.shutsujou.length ? kai.shutsujou[i] : 0,
          ),
        const SizedBox(height: 8),
        const _Chuuki(),
      ],
    );
  }

  Widget _kaadoWidget(KoukouMei m, int zenkokuKai, int chikuKai, int shutsujouKai) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kaado,
        border: Border.all(color: _waku),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                koukouKenMijikai(m.ken),
                style: const TextStyle(
                  color: _kin,
                  fontSize: HENSUU.fontsize_honbun - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _iroFuda(m.iro),
              if (m.ryuugakusei) _fuda('留学生あり', HENSUU.textcolor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            m.mei,
            style: const TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun + 6,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (m.shoukai.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(m.shoukai, style: _honbun),
          ],
          const SizedBox(height: 6),
          Text(
            '集まりやすい選手: ${koukouIroKeikou[_iroBan(m.iro)]}',
            style: _hosoku,
          ),
          // 都道府県予選の優勝回数は出さず、地区代表での出場回数だけを添える(1.9.5)
          Text(
            '全国高校駅伝: 出場$shutsujouKai回${chikuKai > 0 ? '(うち地区代表$chikuKai回)' : ''}・優勝$zenkokuKai回',
            style: _hosoku,
          ),
        ],
      ),
    );
  }
}

/// 都道府県別の一覧(地区ごとに折りたたみ。高校を押すと編集)
class _KenBetsu extends StatelessWidget {
  const _KenBetsu({required this.onHenkou});

  /// 高校を編集したとき(名鑑の全部のタブを作り直す)
  final VoidCallback onHenkou;

  @override
  Widget build(BuildContext context) {
    final List<KoukouMei> meibo = koukouMeiboGenzai();
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    // 変えた高校(初期値のままの高校は、初期値と同じものが入っている)
    final Set<int> henkou = {
      for (int i = 0; i < meibo.length && i < koukouMeiboShoki.length; i++)
        if (!identical(meibo[i], koukouMeiboShoki[i])) i,
    };
    final List<Widget> l = [
      const Text(
        '名門度は名門・強豪・中堅・一般の4段階で、名門度が高い高校ほど、名前のない部員も強くなります。'
        '出場回数と優勝回数は、記録を残し始めてからの回数で、毎年4月上旬に新入生が入るときに増えます。',
        style: _honbun,
      ),
      const SizedBox(height: 6),
      const Text(
        '高校を押すと、校名・都道府県・名門度・タイプ・留学生の有無・紹介文を変えられます。',
        style: _hosoku,
      ),
      const SizedBox(height: 8),
    ];
    for (int c = 0; c < koukouChikuMei.length; c++) {
      final List<Widget> naka = [];
      for (int ken = 0; ken < koukouKenChiku.length; ken++) {
        if (koukouKenChiku[ken] != c) continue;
        // 名門度の高い順(同じなら名簿の順)
        final List<int> kou = [
          for (int i = 0; i < meibo.length; i++)
            if (meibo[i].ken == ken) i,
        ];
        kou.sort((a, b) {
          final int s = meibo[b].meimon.compareTo(meibo[a].meimon);
          return s != 0 ? s : a.compareTo(b);
        });
        naka.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text(
              koukouKenMijikai(ken),
              style: const TextStyle(
                color: _kin,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        if (kou.isEmpty) {
          naka.add(const Padding(
            padding: EdgeInsets.only(left: 16, top: 4),
            child: Text('名簿の高校はありません', style: _hosoku),
          ));
        }
        for (final int i in kou) {
          naka.add(
            _gyou(
              context,
              i,
              meibo[i],
              i < kai.zenkoku.length ? kai.zenkoku[i] : 0,
              i < kai.shutsujou.length ? kai.shutsujou[i] : 0,
              henkou.contains(i),
            ),
          );
        }
      }
      l.add(_Oritatami(midashi: koukouChikuMei[c], naka: naka));
    }
    if (henkou.isNotEmpty) {
      l.add(const SizedBox(height: 16));
      l.add(
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => _zenbuModosu(context),
            child: Text('すべての高校を元に戻す(${henkou.length}校を変更中)', style: _honbun),
          ),
        ),
      );
    }
    l.add(const SizedBox(height: 20));
    l.add(const _Chuuki());
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }

  Future<void> _zenbuModosu(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('すべての高校を元に戻しますか?', style: TextStyle(color: Colors.white)),
        content: const Text(
          '校名・都道府県・名門度・タイプ・留学生の有無・紹介文の変更を、すべて初期の名簿に戻します。',
          style: _honbun,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('やめる')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('元に戻す')),
        ],
      ),
    );
    if (ok != true) return;
    await koukouHenkouZenbuModosu();
    onHenkou();
  }

  Future<void> _henshuu(BuildContext context, int i) async {
    final bool? kawatta = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => _KoukouHenshuu(ban: i)),
    );
    if (kawatta == true) onHenkou();
  }

  Widget _gyou(BuildContext context, int i, KoukouMei m, int zenkokuKai, int shutsujouKai, bool henkouAri) {
    final bool meimon = m.meimon == 3;
    return InkWell(
      onTap: () => _henshuu(context, i),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              koukouMeimonMei[m.meimon.clamp(0, koukouMeimonMei.length - 1).toInt()],
              style: TextStyle(
                color: meimon ? _kin : _usui,
                fontSize: HENSUU.fontsize_honbun - 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              m.mei,
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: meimon ? FontWeight.bold : FontWeight.normal,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
            ),
            _iroFuda(m.iro),
            if (m.ryuugakusei) _fuda('留学生あり', HENSUU.textcolor),
            if (henkouAri) _fuda('変更', Colors.lightBlueAccent),
            // 出場回数と優勝回数(1回以上のときだけ)
            if (shutsujouKai > 0) Text('全国出場$shutsujouKai回', style: _hosoku),
            if (zenkokuKai > 0)
              Text('全国優勝$zenkokuKai回', style: const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun - 2)),
          ],
        ),
      ),
    );
  }
}

/// 高校1校の編集(校名・都道府県・名門度・タイプ・留学生の有無・紹介文。1.9.5)
class _KoukouHenshuu extends StatefulWidget {
  const _KoukouHenshuu({required this.ban});

  /// 名簿の番号
  final int ban;

  @override
  State<_KoukouHenshuu> createState() => _KoukouHenshuuState();
}

class _KoukouHenshuuState extends State<_KoukouHenshuu> {
  late final TextEditingController _mei;
  late final TextEditingController _shoukai;
  late int _ken;
  late int _meimon;
  late int _iro;
  late bool _ryuu;
  bool _hozonChuu = false;

  @override
  void initState() {
    super.initState();
    final KoukouMei m = koukouMeiboGenzai()[widget.ban];
    _mei = TextEditingController(text: m.mei);
    _shoukai = TextEditingController(text: m.shoukai);
    _ken = m.ken.clamp(0, LocationDatabase.allPrefectures.length - 1).toInt();
    _meimon = m.meimon.clamp(0, 3).toInt();
    _iro = _iroBan(m.iro);
    _ryuu = m.ryuugakusei;
  }

  @override
  void dispose() {
    _mei.dispose();
    _shoukai.dispose();
    super.dispose();
  }

  /// 校名を整える(前後の空白と、最後の「高等学校」「高校」を除く。「高」は表示のときに付く)
  String _seiri(String s) {
    String t = s.trim();
    for (final String suffix in const ['高等学校', '高校']) {
      if (t.endsWith(suffix) && t.length > suffix.length) {
        t = t.substring(0, t.length - suffix.length).trim();
        break;
      }
    }
    return t;
  }

  Future<void> _hozon() async {
    final String mei = _seiri(_mei.text);
    if (mei.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('校名を入れてください')));
      return;
    }
    setState(() => _hozonChuu = true);
    await koukouHenkouHozon(
      widget.ban,
      KoukouMei(mei, _ken, _meimon, _ryuu, _iro, shoukai: _shoukai.text.trim()),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _modosu() async {
    setState(() => _hozonChuu = true);
    await koukouHenkouHozon(widget.ban, null);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// この高校の回数を0に戻す(確認してから。1.9.5)
  Future<void> _kaisuuReset() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('この高校の回数を0に戻しますか?', style: TextStyle(color: Colors.white)),
        content: const Text(
          '全国高校駅伝の出場回数・優勝回数・連続出場を0に戻します。過去の大会の記録はそのまま残ります。',
          style: _honbun,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('やめる')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('0に戻す')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _hozonChuu = true);
    await koukouKaisuuReset(widget.ban);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _usui),
      counterStyle: const TextStyle(color: _usui),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text, style: _hosoku),
    );
  }

  @override
  Widget build(BuildContext context) {
    final KoukouMei shoki = koukouMeiboShoki[widget.ban];
    final bool henkouAri = koukouHenkouAri(widget.ban);
    // その都道府県の名簿の高校が1校だけなら、都道府県は変えられない(名簿の高校が0校の県を作らないように。1.9.5)
    final List<KoukouMei> meibo = koukouMeiboGenzai();
    final int imaKen = meibo[widget.ban].ken;
    final bool kenKotei = meibo.where((KoukouMei m) => m.ken == imaKen).length <= 1;
    final String imaKenMei =
        (imaKen >= 0 && imaKen < LocationDatabase.allPrefectures.length) ? LocationDatabase.allPrefectures[imaKen] : '';
    // 元に戻すと都道府県が変わり、今の都道府県の名簿の高校が0校になるなら、元に戻せない
    final bool modosenai = kenKotei && shoki.ken != imaKen;
    // この高校の回数(1回以上あれば、0に戻すボタンを出す)
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    final int b = widget.ban;
    final bool kaisuuAri = (b < kai.zenkoku.length && kai.zenkoku[b] > 0) ||
        (b < kai.ken.length && kai.ken[b] > 0) ||
        (b < kai.shutsujou.length && kai.shutsujou[b] > 0);
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('高校の編集', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (henkouAri) ...[
            Text('初期の名簿: ${shoki.mei}高(${koukouKenMijikai(shoki.ken)})', style: _hosoku),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _mei,
            maxLength: 12,
            style: _honbun,
            decoration: _deco('校名(「高」は表示のときに付きます)'),
          ),
          _label('都道府県'),
          DropdownButton<int>(
            value: _ken,
            isExpanded: true,
            dropdownColor: Colors.grey[900],
            style: _honbun,
            items: [
              for (int k = 0; k < LocationDatabase.allPrefectures.length; k++)
                DropdownMenuItem<int>(value: k, child: Text(LocationDatabase.allPrefectures[k], style: _honbun)),
            ],
            onChanged: (_hozonChuu || kenKotei) ? null : (int? v) => setState(() => _ken = v ?? _ken),
          ),
          if (kenKotei)
            Text(
              '$imaKenMeiの名簿の高校はこの1校だけなので、都道府県は変えられません'
              '(ほかの高校を$imaKenMeiに移すと、変えられるようになります)。',
              style: _hosoku,
            ),
          _label('名門度(高いほど、名前のない部員が強く、速い新入生が集まりやすい。名門は県外からも集まる)'),
          DropdownButton<int>(
            value: _meimon,
            isExpanded: true,
            dropdownColor: Colors.grey[900],
            style: _honbun,
            items: [
              for (final int v in const [3, 2, 1, 0])
                DropdownMenuItem<int>(value: v, child: Text(koukouMeimonMei[v], style: _honbun)),
            ],
            onChanged: _hozonChuu ? null : (int? v) => setState(() => _meimon = v ?? _meimon),
          ),
          _label('タイプ'),
          DropdownButton<int>(
            value: _iro,
            isExpanded: true,
            dropdownColor: Colors.grey[900],
            style: _honbun,
            items: [
              for (int i = 0; i < koukouIroMei.length; i++)
                DropdownMenuItem<int>(value: i, child: Text(koukouIroMei[i], style: _honbun)),
            ],
            onChanged: _hozonChuu ? null : (int? v) => setState(() => _iro = v ?? _iro),
          ),
          Text('${koukouIroKeikou[_iroBan(_iro)]}が集まりやすい', style: _hosoku),
          SwitchListTile(
            value: _ryuu,
            onChanged: _hozonChuu ? null : (bool v) => setState(() => _ryuu = v),
            title: const Text('留学生がいる', style: _honbun),
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.amber,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _shoukai,
            maxLength: 100,
            maxLines: null,
            style: _honbun,
            decoration: _deco('紹介文(名門校のタブに出ます。空でもよい)'),
          ),
          const SizedBox(height: 8),
          const Text(
            '都道府県・名門度・タイプ・留学生の変更は、次の新入生の計算から効きます。今の選手の高校時代の実績は変わりません。'
            '校名の変更は、今の選手の出身校にもそのまま出ます。過去の大会の記録は、そのときの校名で出ます。'
            '全国高校駅伝の出場回数と優勝回数は、校名を変えてもこの高校に残ります(0に戻すこともできます)。',
            style: _hosoku,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _hozonChuu ? null : _hozon,
                child: const Text('保存'),
              ),
              if (henkouAri)
                OutlinedButton(
                  onPressed: (_hozonChuu || modosenai) ? null : _modosu,
                  child: const Text('この高校を元に戻す', style: _honbun),
                ),
              if (kaisuuAri)
                OutlinedButton(
                  onPressed: _hozonChuu ? null : _kaisuuReset,
                  child: const Text('この高校の回数を0に戻す', style: _honbun),
                ),
            ],
          ),
          if (henkouAri && modosenai)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '元に戻すと$imaKenMeiの名簿の高校がなくなるので、この高校は元に戻せません'
                '(ほかの高校を$imaKenMeiに移すか、「すべての高校を元に戻す」を使ってください)。',
                style: _hosoku,
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// 大会の記録(直近10回の全国高校駅伝と高校総体。見出しごとに折りたたみ。1.9.5)
class _TaikaiKiroku extends StatefulWidget {
  const _TaikaiKiroku();

  @override
  State<_TaikaiKiroku> createState() => _TaikaiKirokuState();
}

class _TaikaiKirokuState extends State<_TaikaiKiroku> {
  late final List<KoukouTaikaiKiroku> _kiroku;
  late final KoukouYuushouKaisuu _kai;
  final Map<int, String> _univMei = {};
  final Map<int, SenshuData> _zaigaku = {};
  int _myUnivId = -1;
  int _erabu = 0; // 詳しく見る回(_kiroku の番号。0が一番新しい)

  static const List<String> _shumokuMei = ['1500m', '5000m', '3000m障害'];

  @override
  void initState() {
    super.initState();
    _kiroku = koukouTaikaiKirokuYomu();
    _kai = koukouYuushouKaisuuYomu();
    if (Hive.isBoxOpen('univBox')) {
      for (final UnivData u in Hive.box<UnivData>('univBox').values) {
        _univMei[u.id] = u.name;
      }
    }
    if (Hive.isBoxOpen('senshuBox')) {
      for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
        _zaigaku[s.id] = s;
      }
    }
    if (Hive.isBoxOpen('ghensuuBox')) {
      final Box<Ghensuu> b = Hive.box<Ghensuu>('ghensuuBox');
      if (b.isNotEmpty) _myUnivId = b.getAt(0)?.MYunivid ?? -1;
    }
  }

  /// 回の名前(「第78回(3年入学の世代)」。年度に75を足した数を回にする)
  /// 回の名前(「第78回 2年12月(3年入学の世代)」。年度に75を足した数を回にする。
  /// 全国高校駅伝は、その世代が大学に入る前の年の12月。ゲーム開始前の大会は「ゲーム開始前の大会」)
  String _kaiMei(KoukouTaikaiKiroku k) {
    final String sedai = k.nyuugakuNendo >= 1 ? '${k.nyuugakuNendo}年入学の世代' : 'ゲーム開始時の在学生の世代';
    final int taikaiNen = k.nyuugakuNendo - 1;
    final String jiki = taikaiNen >= 1 ? '$taikaiNen年12月' : 'ゲーム開始前の大会';
    return '第${k.nyuugakuNendo + 75}回 $jiki($sedai)';
  }

  /// 記録がいつ増えるかの注釈(実在の大会は秋に予選、12月に全国なので、その時期に増えると
  /// 思われないように、増える時期を「4月上旬だけ」と言い切って、目立つ枠で出す。1.9.5)
  static Widget _jikiChuuki() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '高校の大会の記録は、毎年4月上旬に新入生が大学に入るときに、1回分がまとめて増えます。'
        'ほかの時期には増えません。'
        '増えるのは、その新入生たちが高校3年だった年度の、夏の高校総体と12月の全国高校駅伝の結果です。',
        style: TextStyle(color: Colors.orangeAccent, fontSize: HENSUU.fontsize_honbun - 1),
      ),
    );
  }

  /// 選手の今の大学(在学中で名前が合えば今の大学、そうでなければ保存したときの大学)
  int _univId(KoukouKirokuSousha s) {
    final SenshuData? z = _zaigaku[s.id];
    if (z != null && z.name == s.name) return z.univid;
    return s.univid;
  }

  /// 選手の行(名前と高校、大学に入った選手は進学先。自分の大学に来た選手は色を変える)
  /// [kouAri] がfalseなら高校の名前を出さない(チームの走者の一覧のとき)
  /// 高校の名前は、その回の当時の名前([kiroku]。あとで校名を変えた高校は前の名前)
  /// [chiisai] がtrueなら名前を小さめの字にする(直近の上位校の、優勝校の選手のとき)
  Widget _soushaGyou(
    KoukouTaikaiKiroku kiroku,
    String juni,
    KoukouKirokuSousha s,
    String time, {
    bool kouAri = true,
    bool chiisai = false,
  }) {
    final String kou = kiroku.kouMei(s.kouCode);
    String mei;
    String sub = '';
    bool jibun = false;
    if (s.namaeAri) {
      mei = s.name;
      final int u = _univId(s);
      final String um = _univMei[u] ?? '';
      if (kouAri) {
        sub = um.isEmpty ? kou : '$kou → $um大学';
      } else {
        sub = um.isEmpty ? '' : '→ $um大学';
      }
      jibun = u == _myUnivId;
    } else {
      final String gaku = s.shurui == 3 ? '留学生' : '${s.gakunen}年生';
      mei = kouAri ? '$kouの$gaku' : gaku;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(juni, style: _hosoku),
          Text(
            mei,
            style: TextStyle(
              color: jibun ? Colors.amber : HENSUU.textcolor,
              fontSize: chiisai ? HENSUU.fontsize_honbun - 2 : HENSUU.fontsize_honbun,
              fontWeight: s.namaeAri ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (sub.isNotEmpty)
            Text(sub, style: TextStyle(color: jibun ? Colors.amber : _usui, fontSize: HENSUU.fontsize_honbun - 2)),
          if (time.isNotEmpty) Text(time, style: _hosoku),
        ],
      ),
    );
  }

  Widget _koMidashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _kin,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _teamMei(KoukouTaikaiKiroku kiroku, KoukouKirokuTeam t) => kiroku.kouMei(t.kouCode);

  int _kaisuu(List<int> l, int i) => i < l.length ? l[i] : 0;

  String _kukanKyori(int kk) {
    final double m = koukouZenkokuKukanKyori(kk);
    final String km = (m / 1000).toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return '${kk + 1}区(${km}km)';
  }

  /// チームの見出し(「1位 天馬学園高(栃木) 2時間03分12秒 地区代表(北関東)」)
  String _teamMidashi(KoukouTaikaiKiroku kiroku, int j, KoukouKirokuTeam t) {
    final int c = t.daihyou - 1;
    final String daihyou = (t.daihyou >= 1 && c < koukouChikuMei.length) ? '　地区代表(${koukouChikuMei[c]})' : '';
    // 出場の回数目(記録を残し始めてからなので、2回目から出す。「3年連続5回目」「5回目」)
    String kaime = '';
    if (t.kaime >= 2) {
      kaime = t.renzoku >= 2 ? '　${t.renzoku}年連続${t.kaime}回目' : '　${t.kaime}回目';
    }
    return '${j + 1}位　${_teamMei(kiroku, t)}　${TimeDate.timeToJikanFunByouString(t.time)}$daihyou$kaime';
  }

  /// チームの走者(区間の順、補欠は最後)
  List<Widget> _teamMember(KoukouTaikaiKiroku kiroku, int j, KoukouKirokuTeam t) {
    final List<KoukouKirokuSousha>? m = t.member;
    if (m == null) {
      return const [Text('この回は走者の記録がありません。', style: _hosoku)];
    }
    final List<KoukouKirokuSousha> jun = List<KoukouKirokuSousha>.of(m)
      ..sort((a, b) => (a.kukan == 0 ? 99 : a.kukan).compareTo(b.kukan == 0 ? 99 : b.kukan));
    return [
      if (j >= 8) const Text('9位以下の高校は、大学に入った選手だけを残しています。', style: _hosoku),
      if (jun.isEmpty) const Text('大学に入った選手はいません。', style: _hosoku),
      for (final KoukouKirokuSousha s in jun)
        _soushaGyou(
          kiroku,
          s.kukan >= 1 ? '${s.kukan}区' : '補欠',
          s,
          s.kukan >= 1 ? TimeDate.timeToFunByouString(s.time) : '',
          kouAri: false,
        ),
    ];
  }

  /// 直近の上位校の、優勝校の大学に入った選手(区間の順、補欠は最後。1.9.5)
  /// 名前のない選手(1・2年生、大学に入らなかった3年生、高校の留学生)は出さない。
  /// 区間賞は、各区間の上位3人の1人目の高校で見る(1校1チームなので、高校と区間で決まる)。
  /// 走者を残す前の記録では何も出さない
  List<Widget> _yuushouMember(KoukouTaikaiKiroku kiroku, KoukouKirokuTeam t) {
    final List<KoukouKirokuSousha>? m = t.member;
    if (m == null) return const [];
    final List<KoukouKirokuSousha> jun = [
      for (final KoukouKirokuSousha s in m)
        if (s.namaeAri) s,
    ]..sort((a, b) => (a.kukan == 0 ? 99 : a.kukan).compareTo(b.kukan == 0 ? 99 : b.kukan));
    if (jun.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(left: 36, top: 2),
          child: Text('大学に入った選手はいません。', style: _hosoku),
        ),
      ];
    }
    final List<Widget> l = [];
    for (final KoukouKirokuSousha s in jun) {
      String juni = '補欠';
      if (s.kukan >= 1) {
        final int kk = s.kukan - 1;
        final bool kukanShou =
            kk < kiroku.kukan.length && kiroku.kukan[kk].isNotEmpty && kiroku.kukan[kk].first.kouCode == t.kouCode;
        juni = kukanShou ? '${s.kukan}区(区間賞)' : '${s.kukan}区';
      }
      l.add(
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: _soushaGyou(kiroku, juni, s, '', kouAri: false, chiisai: true),
        ),
      );
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    if (_kiroku.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _jikiChuuki(),
          const SizedBox(height: 12),
          const Text(
            'まだ記録がありません。直近10回分まで残ります。',
            style: _honbun,
          ),
        ],
      );
    }
    final int erabu = _erabu.clamp(0, _kiroku.length - 1).toInt();
    final KoukouTaikaiKiroku k = _kiroku[erabu];

    // ---- 直近の上位校と優勝者 ----
    final List<Widget> chokkin = [
      const Text(
        '優勝校の下に、大学に入った選手と進学先を出しています。全員は下の「大会の結果」で見られます。',
        style: _hosoku,
      ),
    ];
    for (final KoukouTaikaiKiroku r in _kiroku) {
      chokkin.add(_koMidashi(_kaiMei(r)));
      chokkin.add(
        const Padding(
          padding: EdgeInsets.only(left: 12, top: 4),
          child: Text('全国高校駅伝', style: _hosoku),
        ),
      );
      for (int j = 0; j < r.zenkoku.length && j < 3; j++) {
        chokkin.add(
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text('${j + 1}位　${_teamMei(r, r.zenkoku[j])}', style: _honbun),
          ),
        );
        // 優勝校は、大学に入った選手と進学先も(1.9.5)
        if (j == 0) chokkin.addAll(_yuushouMember(r, r.zenkoku[0]));
      }
      for (int sh = 0; sh < r.soutai.length && sh < _shumokuMei.length; sh++) {
        if (r.soutai[sh].isEmpty) continue;
        chokkin.add(_soushaGyou(r, '総体${_shumokuMei[sh]} 優勝', r.soutai[sh].first, ''));
      }
    }

    // ---- 優勝回数の多い高校 ----
    final List<int> tsuyoi = [
      for (int i = 0; i < _kai.zenkoku.length; i++)
        if (_kai.zenkoku[i] > 0) i,
    ]..sort((a, b) {
        final int s = _kai.zenkoku[b].compareTo(_kai.zenkoku[a]);
        if (s != 0) return s;
        final int s2 = _kaisuu(_kai.shutsujou, b).compareTo(_kaisuu(_kai.shutsujou, a));
        return s2 != 0 ? s2 : a.compareTo(b);
      });

    // ---- 出場回数の多い高校 ----
    final List<int> ooi = [
      for (int i = 0; i < _kai.zenkoku.length; i++)
        if (_kaisuu(_kai.shutsujou, i) > 0) i,
    ]..sort((a, b) {
        final int s = _kaisuu(_kai.shutsujou, b).compareTo(_kaisuu(_kai.shutsujou, a));
        if (s != 0) return s;
        final int s2 = _kai.zenkoku[b].compareTo(_kai.zenkoku[a]);
        return s2 != 0 ? s2 : a.compareTo(b);
      });

    final List<Widget> l = [
      _jikiChuuki(),
      const SizedBox(height: 12),
      const Text(
        '新入生の世代ごとに、高校3年のときの全国高校駅伝と高校総体の結果を、直近10回分残しています。'
        '大学に入った選手には進学先を、自分の大学に来た選手は色を変えて出します。',
        style: _honbun,
      ),
      const SizedBox(height: 8),
      _Oritatami(midashi: '直近の上位校と優勝者', naka: chokkin, hajimeHiraku: true),
      if (tsuyoi.isNotEmpty)
        _Oritatami(
          midashi: '全国高校駅伝の優勝回数',
          naka: [
            const Text('記録を残し始めてからの回数です。', style: _hosoku),
            for (final int i in tsuyoi.take(10))
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  '${koukouCodeMei(i)}　優勝${_kai.zenkoku[i]}回(出場${_kaisuu(_kai.shutsujou, i)}回)',
                  style: _honbun,
                ),
              ),
          ],
        ),
      if (ooi.isNotEmpty)
        _Oritatami(
          midashi: '全国高校駅伝の出場回数',
          naka: [
            const Text('記録を残し始めてからの回数です。', style: _hosoku),
            for (final int i in ooi.take(10))
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  '${koukouCodeMei(i)}　出場${_kaisuu(_kai.shutsujou, i)}回'
                  '${_kai.chikuDaihyou(i) > 0 ? '(うち地区代表${_kai.chikuDaihyou(i)}回)' : ''}・優勝${_kai.zenkoku[i]}回',
                  style: _honbun,
                ),
              ),
          ],
        ),
      // ---- 選んだ回の結果 ----
      const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          '■大会の結果',
          style: TextStyle(
            color: HENSUU.textcolor,
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      DropdownButton<int>(
        value: erabu,
        isExpanded: true,
        dropdownColor: Colors.grey[900],
        style: _honbun,
        items: [
          for (int i = 0; i < _kiroku.length; i++)
            DropdownMenuItem<int>(
              value: i,
              child: Text(_kaiMei(_kiroku[i]), style: _honbun, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (int? v) {
          if (v == null) return;
          setState(() => _erabu = v);
        },
      ),
      // 全国高校駅伝(高校を開くと走者と進学先)
      _Oritatami(
        key: ValueKey<String>('zenkoku$erabu'),
        midashi: '全国高校駅伝(${k.zenkoku.length}校)',
        naka: [
          const Text('高校を押すと、走った選手と進学先を見られます。', style: _hosoku),
          for (int j = 0; j < k.zenkoku.length; j++)
            _Oritatami(
              key: ValueKey<String>('team$erabu-$j'),
              midashi: _teamMidashi(k, j, k.zenkoku[j]),
              naka: _teamMember(k, j, k.zenkoku[j]),
              futoi: j == 0,
            ),
        ],
      ),
      // 区間の上位3人
      _Oritatami(
        key: ValueKey<String>('kukan$erabu'),
        midashi: '全国高校駅伝 区間の上位3人',
        naka: [
          for (int kk = 0; kk < k.kukan.length; kk++) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8),
              child: Text(
                _kukanKyori(kk),
                style: const TextStyle(color: HENSUU.textcolor, fontWeight: FontWeight.bold),
              ),
            ),
            for (int j = 0; j < k.kukan[kk].length; j++)
              _soushaGyou(
                k,
                j == 0 ? '区間賞' : '${j + 1}位',
                k.kukan[kk][j],
                TimeDate.timeToFunByouString(k.kukan[kk][j].time),
              ),
          ],
        ],
      ),
      // 高校総体の決勝
      for (int sh = 0; sh < k.soutai.length && sh < _shumokuMei.length; sh++)
        _Oritatami(
          key: ValueKey<String>('soutai$erabu-$sh'),
          midashi: '高校総体 ${_shumokuMei[sh]} 決勝',
          naka: [
            for (int j = 0; j < k.soutai[sh].length; j++)
              _soushaGyou(k, '${j + 1}位', k.soutai[sh][j], TimeDate.timeToFunByouString(k.soutai[sh][j].time)),
          ],
        ),
      const SizedBox(height: 24),
      const Text('架空の高校の大会です。大学のレースや育成には影響しません。', style: _hosoku),
      const SizedBox(height: 24),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }
}

/// 下の注意書き(タイプの見方・留学生の進学・架空の高校)
class _Chuuki extends StatelessWidget {
  const _Chuuki();

  @override
  Widget build(BuildContext context) {
    final int ryuuSuu = koukouMeiboGenzai().where((m) => m.ryuugakusei).length;
    const TextStyle midashi = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun - 1,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('タイプの見方', style: midashi),
        const SizedBox(height: 4),
        for (int i = 0; i < koukouIroMei.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '・${koukouIroMei[i]}: ${koukouIroKeikou[i]}が集まりやすい',
              style: _hosoku,
            ),
          ),
        const Text(
          '・タイプは、新入生がどの高校に入るかに少し効くだけです。名門には、入学時の持ちタイムが速い選手ほど集まります。',
          style: _hosoku,
        ),
        const SizedBox(height: 12),
        const Text('留学生の進学について', style: midashi),
        const SizedBox(height: 4),
        const Text(
          '・留学生のいる高校の留学生は、名前のない選手として高校の大会を走ります。',
          style: _hosoku,
        ),
        Text(
          '・大学に入る留学生の約半分は、留学生のいる$ryuuSuu校のどれかの出身で、その年は高校の留学生として走ります。',
          style: _hosoku,
        ),
        const SizedBox(height: 12),
        const Text(
          '架空の高校です。実在の学校とは関係ありません。大学のレースや育成には影響しません。',
          style: _hosoku,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
