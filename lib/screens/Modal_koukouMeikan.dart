import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/koukou.dart';
import 'package:ekiden/kansuu/koukou_meibo.dart';

// ------------------------------------------------------------
// 高校名鑑(1.9.5。説明画面の設定タブの「高校名鑑」から開く)
// ・「名門校の紹介」(名門校のタイプ・留学生・紹介文・集まりやすい選手)と、
//   「都道府県別」(全校の名門度・タイプ・留学生)を、タブで切り替える
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
      length: 2,
      child: Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text('高校名鑑', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: '名門校の紹介'),
              Tab(text: '都道府県別'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [_MeimonShoukai(), _KenBetsu()],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '全国高校駅伝の常連で、県外からも選手が集まる名門${meimon.length}校です。'
          'タイプによって、入ってくる選手の傾向が変わります。',
          style: _honbun,
        ),
        const SizedBox(height: 12),
        for (final int i in meimon) _kaadoWidget(koukouMeibo[i]),
        const SizedBox(height: 8),
        const _Chuuki(),
      ],
    );
  }

  Widget _kaadoWidget(KoukouMei m) {
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
    final List<Widget> l = [
      const Text(
        '都道府県ごとに5校あります。名門度は名門・強豪・中堅・一般の4段階で、'
        '名門度が高い高校ほど、名前のない部員も強くなります。',
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
          l.add(_gyou(koukouMeibo[i]));
        }
      }
    }
    l.add(const SizedBox(height: 20));
    l.add(const _Chuuki());
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }

  Widget _gyou(KoukouMei m) {
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
        ],
      ),
    );
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
