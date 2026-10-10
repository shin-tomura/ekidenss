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
//   「都道府県別」(全校の名門度・タイプ・留学生・優勝回数)と、
//   「大会の記録」(直近10回の全国高校駅伝と高校総体。koukou.dart の koukouTaikaiKirokuYomu)を、タブで切り替える
// ・名簿(koukou_meibo.dart)から作るので、校名を変えても自動で合う
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
List<int> _chikuJun() {
  final List<int> jun = [];
  for (int c = 0; c < koukouChikuMei.length; c++) {
    for (int ken = 0; ken < koukouKenChiku.length; ken++) {
      if (koukouKenChiku[ken] != c) continue;
      for (int i = 0; i < koukouMeibo.length; i++) {
        if (koukouMeibo[i].ken == ken) jun.add(i);
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

class ModalKoukouMeikan extends StatelessWidget {
  const ModalKoukouMeikan({super.key});

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
        body: const TabBarView(
          children: [_MeimonShoukai(), _KenBetsu(), _TaikaiKiroku()],
        ),
      ),
    );
  }
}

/// 名門校の紹介
class _MeimonShoukai extends StatelessWidget {
  const _MeimonShoukai();

  @override
  Widget build(BuildContext context) {
    final List<int> meimon = [
      for (final int i in _chikuJun())
        if (koukouMeibo[i].meimon == 3) i,
    ];
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '全国高校駅伝の常連で、県外からも選手が集まる名門${meimon.length}校です。'
          'タイプによって、入ってくる選手の傾向が変わります。',
          style: _honbun,
        ),
        const SizedBox(height: 12),
        for (final int i in meimon)
          _kaadoWidget(
            koukouMeibo[i],
            i < kai.zenkoku.length ? kai.zenkoku[i] : 0,
            i < kai.ken.length ? kai.ken[i] : 0,
          ),
        const SizedBox(height: 8),
        const _Chuuki(),
      ],
    );
  }

  Widget _kaadoWidget(KoukouMei m, int zenkokuKai, int kenKai) {
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
          Text(
            '優勝回数: 全国高校駅伝 $zenkokuKai回・都道府県予選 $kenKai回',
            style: _hosoku,
          ),
        ],
      ),
    );
  }
}

/// 都道府県別の一覧
class _KenBetsu extends StatelessWidget {
  const _KenBetsu();

  @override
  Widget build(BuildContext context) {
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    final List<Widget> l = [
      const Text(
        '都道府県ごとに5校あります。名門度は名門・強豪・中堅・一般の4段階で、'
        '名門度が高い高校ほど、名前のない部員も強くなります。'
        '優勝回数は、記録を残し始めてからの回数です。',
        style: _honbun,
      ),
    ];
    for (int c = 0; c < koukouChikuMei.length; c++) {
      l.add(
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 2),
          child: Text(
            '■${koukouChikuMei[c]}',
            style: const TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (int ken = 0; ken < koukouKenChiku.length; ken++) {
        if (koukouKenChiku[ken] != c) continue;
        // 名門度の高い順(同じなら名簿の順)
        final List<int> kou = [
          for (int i = 0; i < koukouMeibo.length; i++)
            if (koukouMeibo[i].ken == ken) i,
        ];
        kou.sort((a, b) {
          final int s = koukouMeibo[b].meimon.compareTo(koukouMeibo[a].meimon);
          return s != 0 ? s : a.compareTo(b);
        });
        if (kou.isEmpty) continue;
        l.add(
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
        for (final int i in kou) {
          l.add(
            _gyou(
              koukouMeibo[i],
              i < kai.zenkoku.length ? kai.zenkoku[i] : 0,
              i < kai.ken.length ? kai.ken[i] : 0,
            ),
          );
        }
      }
    }
    l.add(const SizedBox(height: 20));
    l.add(const _Chuuki());
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }

  Widget _gyou(KoukouMei m, int zenkokuKai, int kenKai) {
    final bool meimon = m.meimon == 3;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
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
            ),
          ),
          _iroFuda(m.iro),
          if (m.ryuugakusei) _fuda('留学生あり', HENSUU.textcolor),
          // 優勝回数(1回以上のときだけ)
          if (zenkokuKai > 0) Text('全国優勝$zenkokuKai回', style: const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun - 2)),
          if (kenKai > 0) Text('予選優勝$kenKai回', style: _hosoku),
        ],
      ),
    );
  }
}

/// 大会の記録(直近10回の全国高校駅伝と高校総体。1.9.5)
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
  String _kaiMei(KoukouTaikaiKiroku k) {
    final String sedai = k.nyuugakuNendo >= 1 ? '${k.nyuugakuNendo}年入学の世代' : 'ゲーム開始時の在学生の世代';
    return '第${k.nyuugakuNendo + 75}回($sedai)';
  }

  /// 選手の今の大学(在学中で名前が合えば今の大学、そうでなければ保存したときの大学)
  int _univId(KoukouKirokuSousha s) {
    final SenshuData? z = _zaigaku[s.id];
    if (z != null && z.name == s.name) return z.univid;
    return s.univid;
  }

  /// 選手の行(名前と高校、大学に入った選手は進学先。自分の大学に来た選手は色を変える)
  Widget _soushaGyou(String juni, KoukouKirokuSousha s, String time) {
    final String kou = koukouCodeMei(s.kouCode);
    String mei;
    String sub = '';
    bool jibun = false;
    if (s.namaeAri) {
      mei = s.name;
      final int u = _univId(s);
      final String um = _univMei[u] ?? '';
      sub = um.isEmpty ? kou : '$kou → $um大学';
      jibun = u == _myUnivId;
    } else {
      mei = s.shurui == 3 ? '$kouの留学生' : '$kouの${s.gakunen}年生';
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
              fontSize: HENSUU.fontsize_honbun,
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

  Widget _midashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        '■$text',
        style: const TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
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

  String _teamMei(KoukouKirokuTeam t) => koukouCodeMei(t.kouCode);

  String _kukanKyori(int kk) {
    final double m = koukouZenkokuKukanKyori(kk);
    final String km = (m / 1000).toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return '${kk + 1}区(${km}km)';
  }

  @override
  Widget build(BuildContext context) {
    if (_kiroku.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'まだ記録がありません。毎年4月に新入生が入るときに、その世代の全国高校駅伝と高校総体の結果が残ります(直近10回分)。',
            style: _honbun,
          ),
        ],
      );
    }
    final int erabu = _erabu.clamp(0, _kiroku.length - 1).toInt();
    final KoukouTaikaiKiroku k = _kiroku[erabu];
    final List<Widget> l = [
      const Text(
        '新入生の世代ごとに、高校3年のときの全国高校駅伝と高校総体の結果を、直近10回分残しています。'
        '大学に入った選手には進学先を、自分の大学に来た選手は色を変えて出します。',
        style: _honbun,
      ),
      // ---- 直近の優勝 ----
      _midashi('直近の上位校と優勝者'),
    ];
    for (final KoukouTaikaiKiroku r in _kiroku) {
      l.add(_koMidashi(_kaiMei(r)));
      final List<String> jouiKou = [];
      for (int j = 0; j < r.zenkoku.length && j < 3; j++) {
        jouiKou.add('${j + 1}位 ${_teamMei(r.zenkoku[j])}');
      }
      l.add(
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 2),
          child: Text('全国高校駅伝: ${jouiKou.join('　')}', style: _honbun),
        ),
      );
      for (int sh = 0; sh < r.soutai.length && sh < _shumokuMei.length; sh++) {
        if (r.soutai[sh].isEmpty) continue;
        l.add(_soushaGyou('総体${_shumokuMei[sh]} 優勝', r.soutai[sh].first, ''));
      }
    }
    // ---- 優勝回数の多い高校 ----
    final List<int> tsuyoi = [
      for (int i = 0; i < _kai.zenkoku.length; i++)
        if (_kai.zenkoku[i] > 0) i,
    ]..sort((a, b) {
        final int s = _kai.zenkoku[b].compareTo(_kai.zenkoku[a]);
        if (s != 0) return s;
        final int s2 = _kai.ken[b].compareTo(_kai.ken[a]);
        return s2 != 0 ? s2 : a.compareTo(b);
      });
    if (tsuyoi.isNotEmpty) {
      l.add(_midashi('全国高校駅伝の優勝回数'));
      l.add(const Text('記録を残し始めてからの回数です。', style: _hosoku));
      for (final int i in tsuyoi.take(10)) {
        l.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              '${koukouCodeMei(i)}　${_kai.zenkoku[i]}回(都道府県予選 ${_kai.ken[i]}回)',
              style: _honbun,
            ),
          ),
        );
      }
    }
    // ---- 選んだ回の結果 ----
    l.add(_midashi('大会の結果'));
    l.add(
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
    );
    // 全国高校駅伝
    l.add(_koMidashi('全国高校駅伝(${k.zenkoku.length}校)'));
    for (int j = 0; j < k.zenkoku.length; j++) {
      final KoukouKirokuTeam t = k.zenkoku[j];
      final int c = t.daihyou - 1;
      final String daihyou = (t.daihyou >= 1 && c < koukouChikuMei.length) ? '地区代表(${koukouChikuMei[c]})' : '';
      l.add(
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${j + 1}位', style: _hosoku),
              Text(
                _teamMei(t),
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: j == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(TimeDate.timeToJikanFunByouString(t.time), style: _hosoku),
              if (daihyou.isNotEmpty) Text(daihyou, style: _hosoku),
            ],
          ),
        ),
      );
    }
    // 区間の上位3人
    l.add(_koMidashi('全国高校駅伝 区間の上位3人'));
    for (int kk = 0; kk < k.kukan.length; kk++) {
      l.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8),
          child: Text(_kukanKyori(kk), style: const TextStyle(color: HENSUU.textcolor, fontWeight: FontWeight.bold)),
        ),
      );
      for (int j = 0; j < k.kukan[kk].length; j++) {
        final KoukouKirokuSousha s = k.kukan[kk][j];
        l.add(_soushaGyou(j == 0 ? '区間賞' : '${j + 1}位', s, TimeDate.timeToFunByouString(s.time)));
      }
    }
    // 高校総体の決勝
    for (int sh = 0; sh < k.soutai.length && sh < _shumokuMei.length; sh++) {
      l.add(_koMidashi('高校総体 ${_shumokuMei[sh]} 決勝'));
      for (int j = 0; j < k.soutai[sh].length; j++) {
        final KoukouKirokuSousha s = k.soutai[sh][j];
        l.add(_soushaGyou('${j + 1}位', s, TimeDate.timeToFunByouString(s.time)));
      }
    }
    l.add(const SizedBox(height: 24));
    l.add(const Text('架空の高校の大会です。大学のレースや育成には影響しません。', style: _hosoku));
    l.add(const SizedBox(height: 24));
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }
}

/// 下の注意書き(タイプの見方・留学生の進学・架空の高校)
class _Chuuki extends StatelessWidget {
  const _Chuuki();

  @override
  Widget build(BuildContext context) {
    final int ryuuSuu = koukouMeibo.where((m) => m.ryuugakusei).length;
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
