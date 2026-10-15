import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart'; // スカウトの途中か(高校のページの卒業生。1.9.5)
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/koukou.dart';
import 'package:ekiden/kansuu/koukou_meibo.dart';
import 'package:ekiden/kansuu/scout_com.dart'; // スカウトの途中か(高校のページの卒業生。1.9.5)
import 'package:ekiden/kansuu/bokou_pipe.dart'; // この高校出身の監督(2.0.1。監督の母校パイプ)
import 'package:ekiden/kansuu/time_date.dart';

// ------------------------------------------------------------
// 高校名鑑(1.9.5。説明画面の設定タブの「高校名鑑」から開く)
// ・「名門校」(名門校のタイプ・留学生・紹介文・集まりやすい選手・優勝回数)と、
//   「都道府県別」(全校の名門度・タイプ・留学生・優勝回数・直近の勝ち上がり。地区ごとに折りたたみ。
//   お気に入りの高校は一番上)と、
//   「大会の記録」(直近10回の全国高校駅伝と高校総体、都道府県予選と地区大会のチームの順位とタイム。
//   koukou.dart の koukouTaikaiKirokuYomu。見出しごとに折りたたみ)を、タブで切り替える
// ・名門校のカードと都道府県別の高校を押すと、高校のページ(_KoukouPage)を開く。年度ごとの都道府県予選・
//   地区大会・全国高校駅伝の成績、お気に入りの付け外し、今大学にいる卒業生。編集はその中から(1.9.5)。
//   この高校出身の大学の監督も出す(2.0.1。監督の母校パイプ。bokou_pipe.dart)
// ・新入生のスカウトの画面の「高校名鑑」からも開く(1.9.5。「大会の記録」のタブから。進学先はスカウトの画面と
//   同じ出し方で、一番新しい回(今年の新入生の世代)の全国高校駅伝を開いておく)
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
  const ModalKoukouMeikan({
    super.key,
    this.shokiTab = 0,
    this.scoutKara = false,
    this.shingakuMoji,
    this.jibunHantei,
  });

  /// 最初に開くタブ(0名門校・1都道府県別・2大会の記録。1.9.5)
  final int shokiTab;

  /// 新入生のスカウトの画面から開いたか(1.9.5。大会の記録で、一番新しい回の全国高校駅伝を開いておき、
  /// 在学生の世代の欄は閉じておく)
  final bool scoutKara;

  /// 大会の記録の選手の後ろに出す進学先(スカウトの画面から渡す。「○○大学に確定」「進路未定」など。
  /// nullを返した選手は、名鑑の出し方。1.9.5)
  final String? Function(KoukouKirokuSousha s)? shingakuMoji;

  /// 自分の大学の選手として色を変えるか(shingakuMoji がnullでない選手だけ使う。1.9.5)
  final bool Function(KoukouKirokuSousha s)? jibunHantei;

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
      initialIndex: widget.shokiTab.clamp(0, 2).toInt(),
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
            _MeimonShoukai(key: ValueKey<int>(_kousinBan), onHenkou: _kousin),
            _KenBetsu(onHenkou: _kousin),
            _TaikaiKiroku(
              scoutKara: widget.scoutKara,
              shingakuMoji: widget.shingakuMoji,
              jibunHantei: widget.jibunHantei,
            ),
          ],
        ),
      ),
    );
  }
}

/// 今年の新入生(スカウトの候補)の世代の、高校の大会の記録があるか(1.9.9。今年の高校の大会の画面を出すか)
bool kotoshiKoukouTaikaiKirokuAri() {
  final List<KoukouTaikaiKiroku> l = koukouTaikaiKirokuYomu();
  return l.isNotEmpty && l.first.nyuugakuNendo == koukouImaNoNendo();
}

/// 今年の高校の大会(1.9.9。新入生のスカウトの画面を開いたとき、1ラウンド目の前に出す)
/// 一番新しい回(今年の新入生の世代)の全国高校駅伝・区間の上位3人・高校総体の決勝を開いて出し、
/// 下の「スカウトへ進む」で閉じる。進学先の文字と色は、高校名鑑と同じくスカウトの画面に決めてもらう
class KotoshiKoukouTaikaiGamen extends StatelessWidget {
  const KotoshiKoukouTaikaiGamen({
    super.key,
    this.shingakuMoji,
    this.jibunHantei,
    this.modoruMoji = 'スカウトへ進む',
  });

  final String? Function(KoukouKirokuSousha s)? shingakuMoji;
  final bool Function(KoukouKirokuSousha s)? jibunHantei;

  /// 一番下の戻るボタンの文字(2.0.1。スカウト解禁の記事から開いたときは「記事に戻る」)
  final String modoruMoji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('今年の高校の大会', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _TaikaiKiroku(
        scoutKara: true,
        kotoshiNomi: true,
        shingakuMoji: shingakuMoji,
        jibunHantei: jibunHantei,
        modoruMoji: modoruMoji,
      ),
    );
  }
}

/// 名門校の紹介
class _MeimonShoukai extends StatelessWidget {
  const _MeimonShoukai({super.key, required this.onHenkou});

  /// 高校のページから戻ったとき(編集やお気に入りを、名鑑の全部のタブに反映する。1.9.5)
  final VoidCallback onHenkou;

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
        const SizedBox(height: 4),
        const Text('高校を押すと、年度ごとの成績を見られます。', style: _hosoku),
        const SizedBox(height: 12),
        for (final int i in meimon)
          _kaadoWidget(
            context,
            i,
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

  Widget _kaadoWidget(BuildContext context, int i, KoukouMei m, int zenkokuKai, int chikuKai, int shutsujouKai) {
    return InkWell(
      // 高校のページ(1.9.5)
      onTap: () => _koukouPageHiraku(context, i, onHenkou),
      child: _kaadoNaka(m, zenkokuKai, chikuKai, shutsujouKai),
    );
  }

  Widget _kaadoNaka(KoukouMei m, int zenkokuKai, int chikuKai, int shutsujouKai) {
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

/// 都道府県別の一覧(地区ごとに折りたたみ。お気に入りの高校は一番上。高校を押すと高校のページ)
class _KenBetsu extends StatelessWidget {
  const _KenBetsu({required this.onHenkou});

  /// 高校のページから戻ったとき(編集やお気に入りを、名鑑の全部のタブに反映する)
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
    // お気に入りの高校と、直近の回(各高校の勝ち上がりを1行で添える。1.9.5)
    final List<int> okiniiri = [
      for (final int i in koukouOkiniiriYomu())
        if (i < meibo.length) i,
    ];
    final List<KoukouTaikaiKiroku> kiroku = koukouTaikaiKirokuYomu();
    final KoukouTaikaiKiroku? saishin = kiroku.isEmpty ? null : kiroku.first;
    String chokkin(int i) => saishin == null ? '' : _chokkinMoji(koukouKaiSeisekiYomu(saishin, i));
    Widget gyou(int i, {bool kenAri = false}) => _gyou(
          context,
          i,
          meibo[i],
          i < kai.zenkoku.length ? kai.zenkoku[i] : 0,
          i < kai.shutsujou.length ? kai.shutsujou[i] : 0,
          henkou.contains(i),
          okiniiri.contains(i),
          chokkin(i),
          kenAri: kenAri,
        );
    final List<Widget> l = [
      const Text(
        '名門度は名門・強豪・中堅・一般の4段階で、名門度が高い高校ほど、名前のない部員も強くなります。'
        '出場回数と優勝回数は、記録を残し始めてからの回数で、毎年4月上旬に新入生が入るときに増えます。',
        style: _honbun,
      ),
      const SizedBox(height: 6),
      const Text(
        '高校を押すと、年度ごとの都道府県予選・地区大会・全国高校駅伝の成績を見られます。'
        '校名・名門度などは、その画面の「編集」で変えられます(都道府県は変えられません)。',
        style: _hosoku,
      ),
      const SizedBox(height: 4),
      const Text(
        '高校のページで☆を付けると、お気に入りとしてこの一番上に並びます。'
        '高校の下には、直近の回の勝ち上がりを出しています。',
        style: _hosoku,
      ),
      const SizedBox(height: 8),
    ];
    // お気に入りの高校(1.9.5)
    if (okiniiri.isNotEmpty) {
      l.add(
        const Padding(
          padding: EdgeInsets.only(top: 4, left: 4),
          child: Text(
            '★お気に入りの高校',
            style: TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun, fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final int i in okiniiri) {
        l.add(gyou(i, kenAri: true));
      }
      l.add(const SizedBox(height: 8));
    }
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
          naka.add(gyou(i));
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
          '校名・名門度・タイプ・留学生の有無・紹介文の変更を、すべて初期の名簿に戻します。',
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

  /// 高校の行(押すと高校のページ。1.9.5)
  /// [okiniiri] はお気に入りの高校か(★を出す)、[chokkin] は直近の回の勝ち上がり(空なら出さない)、
  /// [kenAri] は校名の後ろに都道府県を出すか(お気に入りの一覧のとき)
  Widget _gyou(
    BuildContext context,
    int i,
    KoukouMei m,
    int zenkokuKai,
    int shutsujouKai,
    bool henkouAri,
    bool okiniiri,
    String chokkin, {
    bool kenAri = false,
  }) {
    final bool meimon = m.meimon == 3;
    return InkWell(
      onTap: () => _koukouPageHiraku(context, i, onHenkou),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (okiniiri) const Text('★', style: TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun)),
                Text(
                  koukouMeimonMei[m.meimon.clamp(0, koukouMeimonMei.length - 1).toInt()],
                  style: TextStyle(
                    color: meimon ? _kin : _usui,
                    fontSize: HENSUU.fontsize_honbun - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  kenAri ? '${m.mei}(${koukouKenMijikai(m.ken)})' : m.mei,
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
            // 直近の回の勝ち上がり(1.9.5)
            if (chokkin.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(chokkin, style: _hosoku),
              ),
          ],
        ),
      ),
    );
  }
}

/// 高校のページを開き、戻ったら名鑑のタブを作り直す(編集やお気に入りを反映する。1.9.5)
Future<void> _koukouPageHiraku(BuildContext context, int ban, VoidCallback onHenkou) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => _KoukouPage(ban: ban)),
  );
  onHenkou();
}

/// 回の名前(「第2回 2年12月(3年入学の世代)」。1.9.5)
/// 全国高校駅伝は、その世代が大学に入る前の年の12月。大学の駅伝と同じく、1年目の大会を第1回にする
/// (N年12月の大会が第N回。同じ年度の大学の駅伝と回の数がそろう)。
/// ゲーム開始前の大会(0年12月より前。開始時の在学生4学年分)は「プレ大会」にして、開始時の学年で見分ける
/// (「プレ大会(ゲーム開始時の4年生の世代)」)。
/// [imaGakunen] が1以上なら、かっこの中を今の学年にする(「(今の1年生の世代)」。在学生の世代の欄のとき)
String _kaiMei(KoukouTaikaiKiroku k, {int imaGakunen = 0}) {
  final int taikaiNen = k.nyuugakuNendo - 1;
  if (taikaiNen >= 1) {
    final String sedai = imaGakunen >= 1 ? '今の$imaGakunen年生の世代' : '${k.nyuugakuNendo}年入学の世代';
    return '第$taikaiNen回 $taikaiNen年12月($sedai)';
  }
  // 1年入学の世代が開始時の1年生、0年入学が2年生…
  final int kaishiGakunen = 2 - k.nyuugakuNendo;
  final String sedai = imaGakunen >= 1 ? '今の$imaGakunen年生の世代' : 'ゲーム開始時の$kaishiGakunen年生の世代';
  return 'プレ大会($sedai)';
}

/// 回の短い名前(「第2回」「プレ大会」。都道府県別の一覧の勝ち上がり。1.9.5)
String _kaiMeiMijikai(KoukouTaikaiKiroku k) {
  final int taikaiNen = k.nyuugakuNendo - 1;
  return taikaiNen >= 1 ? '第$taikaiNen回' : 'プレ大会';
}

/// 1回分の勝ち上がりの短い文(「第5回: 予選2位 → 北関東大会3位 → 全国12位」。1.9.5)
/// 予選と地区大会の記録がない回は、全国高校駅伝に出たときだけ。何もなければ空
String _chokkinMoji(KoukouKaiSeiseki s) {
  final List<String> l = [];
  final KoukouYosenTeam? yo = s.yosen;
  if (yo != null) l.add('予選${yo.juni}位');
  if (s.chiku != null && s.chikuBan >= 0 && s.chikuBan < koukouChikuMei.length) {
    l.add('${koukouChikuMei[s.chikuBan]}大会${s.chikuJuni}位');
  }
  if (s.zenkoku != null) l.add('全国${s.zenkokuJuni}位');
  if (l.isEmpty) return '';
  return '${_kaiMeiMijikai(s.kiroku)}: ${l.join(' → ')}';
}

/// 走者の区間と区間順位(「3区(区間賞)」「3区(区間5位)」。補欠は「補欠」。1.9.5)
/// 区間順位を残す前の記録では、各区間の上位3人の記録に、そのチームの高校があれば順位を出す
/// (1校1チームなので、高校と区間で決まる)
String _kukanJuniMoji(KoukouTaikaiKiroku kiroku, KoukouKirokuTeam t, KoukouKirokuSousha s) {
  if (s.kukan < 1) return '補欠';
  int juni = s.kukanJuni;
  if (juni < 1) {
    final int kk = s.kukan - 1;
    if (kk < kiroku.kukan.length) {
      final List<KoukouKirokuSousha> ue = kiroku.kukan[kk];
      for (int i = 0; i < ue.length; i++) {
        if (ue[i].kouCode == t.kouCode) {
          juni = i + 1;
          break;
        }
      }
    }
  }
  if (juni == 1) return '${s.kukan}区(区間賞)';
  if (juni >= 2) return '${s.kukan}区(区間$juni位)';
  return '${s.kukan}区';
}

/// 優勝校の、その時点の優勝の回数目(「初優勝」「3年連続5回目の優勝」「4年ぶり2回目の優勝」「5回目の優勝」。1.9.5)
/// 記録を残し始めてからの回数(回数を残す前の記録は空)
String _yuushouMoji(KoukouKirokuTeam t) {
  if (t.yuushouKaime < 1) return '';
  if (t.yuushouKaime == 1) return '初優勝';
  if (t.yuushouRenzoku >= 2) return '${t.yuushouRenzoku}年連続${t.yuushouKaime}回目の優勝';
  if (t.yuushouBuri >= 2) return '${t.yuushouBuri}年ぶり${t.yuushouKaime}回目の優勝';
  return '${t.yuushouKaime}回目の優勝';
}

/// 全国高校駅伝の出場の回数目(「初出場」「3年連続5回目」「5年ぶり3回目」「5回目」。1.9.5)
/// 記録を残し始めてからの回数(回数を0に戻した高校は、次に出たときが「初出場」)。
/// 何年ぶりを残す前の記録では、あいだがあいた出場も「5回目」。回数を残す前の記録は空
String _shutsujouMoji(KoukouKirokuTeam t) {
  if (t.kaime < 1) return '';
  if (t.kaime == 1) return '初出場';
  if (t.renzoku >= 2) return '${t.renzoku}年連続${t.kaime}回目';
  if (t.shutsujouBuri >= 2) return '${t.shutsujouBuri}年ぶり${t.kaime}回目';
  return '${t.kaime}回目';
}

/// 出場の回数目と、[yuushou](1位)なら優勝の回数目をつないだ文(1.9.5)
/// 「初出場初優勝」「5年ぶり3回目の出場・初優勝」「3年連続5回目の出場・2年連続3回目の優勝」
String _shutsujouYuushouMoji(KoukouKirokuTeam t, bool yuushou) {
  final String s = _shutsujouMoji(t);
  if (!yuushou) return s;
  if (t.kaime == 1 && t.yuushouKaime == 1) return '初出場初優勝';
  final String y = _yuushouMoji(t);
  if (s.isEmpty) return y;
  if (y.isEmpty) return s;
  return '$sの出場・$y';
}

/// 高校1校の編集(校名・名門度・タイプ・留学生の有無・紹介文。都道府県は表示だけ。1.9.5)
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
  late final int _ken; // 都道府県は変えられない(今の値のまま保存に渡す。1.9.5)
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
          '全国高校駅伝の出場回数・優勝回数・連続出場と、都道府県予選・地区大会の優勝回数を0に戻します。'
          '過去の大会の記録はそのまま残ります。',
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
    // 都道府県は変えられない(1.9.5。全国高校駅伝の予選を1県5校で走るため)
    final String kenMei =
        (shoki.ken >= 0 && shoki.ken < LocationDatabase.allPrefectures.length) ? LocationDatabase.allPrefectures[shoki.ken] : '';
    // この高校の回数(1回以上あれば、0に戻すボタンを出す)
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    final int b = widget.ban;
    final bool kaisuuAri = (b < kai.zenkoku.length && kai.zenkoku[b] > 0) ||
        (b < kai.ken.length && kai.ken[b] > 0) ||
        (b < kai.chiku.length && kai.chiku[b] > 0) ||
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
          // 都道府県は表示だけ(変えられない。1.9.5)
          _label('都道府県'),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$kenMei(都道府県は変えられません)', style: _honbun),
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
            '名門度・タイプ・留学生の変更は、次の新入生の計算から効きます。今の選手の高校時代の実績は変わりません。'
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
                  onPressed: _hozonChuu ? null : _modosu,
                  child: const Text('この高校を元に戻す', style: _honbun),
                ),
              if (kaisuuAri)
                OutlinedButton(
                  onPressed: _hozonChuu ? null : _kaisuuReset,
                  child: const Text('この高校の回数を0に戻す', style: _honbun),
                ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// 高校のページ(1.9.5。名門校のカードと、都道府県別の高校から開く)
/// ・上に校名・都道府県・名門度・タイプ・紹介文と回数、☆(お気に入り)と「編集」
/// ・年度ごとの都道府県予選・地区大会・全国高校駅伝の成績(大会の記録の直近10回。全国は押すと走者と進学先)
/// ・今、大学にいる卒業生(コンピュータスカウトONでスカウトの途中は、決まっていない新入生の大学を出さない)
class _KoukouPage extends StatefulWidget {
  const _KoukouPage({required this.ban});

  /// 名簿の番号
  final int ban;

  @override
  State<_KoukouPage> createState() => _KoukouPageState();
}

class _KoukouPageState extends State<_KoukouPage> {
  List<KoukouTaikaiKiroku> _kiroku = [];
  final Map<int, String> _univMei = {};
  final Map<int, SenshuData> _zaigaku = {};
  int _myUnivId = -1;

  /// コンピュータスカウトONでスカウトの途中か(新入生の進学先の画面と同じ見分け方)
  bool _scoutChuu = false;
  bool _shoriChuu = false;

  /// この高校出身の今の大学の監督(大学の順。2.0.1。監督の母校パイプ)
  List<BokouKantoku> _kantoku = const [];

  /// 監督の母校パイプが、この高校の新入生に効くか(コンピュータスカウトONで、設定がなしでなく、
  /// 効く大学の監督がいる。自分の大学に効かない設定なら、自分の大学の監督は数えない。説明の文を出すかに使う)
  bool _pipeKiku = false;

  @override
  void initState() {
    super.initState();
    _kiroku = koukouTaikaiKirokuYomu();
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
      final Ghensuu? g = b.isNotEmpty ? b.getAt(0) : null;
      _myUnivId = g?.MYunivid ?? -1;
      if (g != null && g.mode == 9000 && Hive.isBoxOpen('kantokuBox')) {
        final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
        _scoutChuu = kantoku != null && isComScoutOn(kantoku);
      }
      // この高校出身の今の大学の監督(2.0.1。bokou_pipe.dart)
      final KantokuData? kd = Hive.isBoxOpen('kantokuBox')
          ? Hive.box<KantokuData>('kantokuBox').get('KantokuData')
          : null;
      if (g != null && kd != null) {
        _kantoku = [
          for (final BokouKantoku b in bokouPipeKantokuIchiran(kd, g.year))
            if (b.koukou - 1 == widget.ban) b,
        ];
        final bool jibunKiku = bokouPipeJibunKiku(kd);
        _pipeKiku = isComScoutOn(kd) &&
            !bokouPipeNashi(kd) &&
            _kantoku.any((BokouKantoku b) => b.univid != _myUnivId || jibunKiku);
      }
    }
  }

  /// スカウトの途中で、進学先が決まっていない新入生か(仮の振り分けの大学を見せない)
  bool _miteiKa(SenshuData s) => _scoutChuu && s.gakunen == 1 && s.hirou != 1 && !comScoutKettei(s);

  /// 大会の記録の選手の今の大学(在学中で名前が合えば今の大学、そうでなければ保存したときの大学)。
  /// スカウトの途中で決まっていない新入生は「進路未定」。[jibun] は自分の大学か
  String _univMoji(KoukouKirokuSousha s, List<bool> jibun) {
    final SenshuData? z = _zaigaku[s.id];
    int u = s.univid;
    if (z != null && z.name == s.name) {
      if (_miteiKa(z)) return '進路未定';
      u = z.univid;
    }
    if (u == _myUnivId) jibun[0] = true;
    final String? um = _univMei[u];
    return um == null ? '' : '$um大学';
  }

  /// 選手の出身校の名簿の番号(なければ-1。留学生は高校を決めたあとだけ)
  int _kouBan(SenshuData s) {
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (s.hirou == 1 && j.keireki != koukouKeirekiRyuugakusei) return -1;
    return j.koukou - 1;
  }

  Future<void> _okiniiriKae(bool tsukeru) async {
    setState(() => _shoriChuu = true);
    await koukouOkiniiriHozon(widget.ban, tsukeru);
    if (!mounted) return;
    setState(() => _shoriChuu = false);
  }

  Future<void> _henshuu() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => _KoukouHenshuu(ban: widget.ban)),
    );
    if (!mounted) return;
    // 校名を変えると、それまでの回に当時の校名が残るので、記録も読み直す
    setState(() => _kiroku = koukouTaikaiKirokuYomu());
  }

  Widget _midashi(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _gyouMoji(String text, {bool kin = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Text(
        text,
        style: kin ? const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun) : _honbun,
      ),
    );
  }

  Widget _gyouHosoku(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Text(text, style: _hosoku),
    );
  }

  /// 全国高校駅伝の走者(区間の順、補欠は最後。大学に入った選手は進学先も)
  List<Widget> _member(KoukouTaikaiKiroku r, KoukouKirokuTeam t, int juni) {
    final List<KoukouKirokuSousha>? m = t.member;
    if (m == null) return const [Text('この回は走者の記録がありません。', style: _hosoku)];
    final List<KoukouKirokuSousha> jun = List<KoukouKirokuSousha>.of(m)
      ..sort((a, b) => (a.kukan == 0 ? 99 : a.kukan).compareTo(b.kukan == 0 ? 99 : b.kukan));
    return [
      if (juni >= 9) const Text('9位以下の高校は、大学に入った選手だけを残しています。', style: _hosoku),
      if (jun.isEmpty) const Text('大学に入った選手はいません。', style: _hosoku),
      for (final KoukouKirokuSousha s in jun) _soushaGyou(r, t, s),
    ];
  }

  /// 全国高校駅伝の走者1人の行(区間と区間順位、名前、進学先、タイム)
  Widget _soushaGyou(KoukouTaikaiKiroku r, KoukouKirokuTeam t, KoukouKirokuSousha s) {
    final List<bool> jibun = [false];
    String mei;
    String univ = '';
    if (s.namaeAri) {
      // 下級生のときの記録に、あとから名前が付いた選手は、当時の学年を添える(大会の記録と同じ)
      final String touji = (s.gakunen >= 1 && s.gakunen <= 2) ? '(当時${s.gakunen}年)' : '';
      mei = '${s.name}$touji';
      univ = _univMoji(s, jibun);
    } else {
      mei = s.shurui == 3 ? '留学生' : '${s.gakunen}年生';
    }
    final Color iro = jibun[0] ? Colors.amber : HENSUU.textcolor;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(_kukanJuniMoji(r, t, s), style: _hosoku),
          Text(
            mei,
            style: TextStyle(
              color: iro,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: s.namaeAri ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (univ.isNotEmpty)
            Text(
              univ == '進路未定' ? univ : '→ $univ',
              style: TextStyle(color: jibun[0] ? Colors.amber : _usui, fontSize: HENSUU.fontsize_honbun - 2),
            ),
          if (s.kukan >= 1) Text(TimeDate.timeToFunByouString(s.time), style: _hosoku),
        ],
      ),
    );
  }

  /// 1回分の成績(都道府県予選・地区大会・全国高校駅伝。全国は押すと走者)
  List<Widget> _kaiSeiseki(KoukouTaikaiKiroku r) {
    final int ban = widget.ban;
    final KoukouKaiSeiseki s = koukouKaiSeisekiYomu(r, ban);
    final List<Widget> l = [
      Padding(
        padding: const EdgeInsets.only(top: 12, left: 4),
        child: Text(
          _kaiMei(r),
          style: const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun, fontWeight: FontWeight.bold),
        ),
      ),
    ];
    // あとで校名か都道府県を変えた高校は、当時の名前を添える
    final String? touji = r.kyuumei[ban];
    if (touji != null) l.add(_gyouHosoku('当時の校名: $touji'));
    // 都道府県予選と地区大会
    final KoukouYosenTeam? yo = s.yosen;
    if (!s.yosenKirokuAri) {
      l.add(_gyouHosoku('この回は、都道府県予選と地区大会の記録がありません。'));
    } else if (yo == null) {
      l.add(_gyouHosoku('この回は、都道府県予選の記録がありません。'));
    } else {
      final String kenMei =
          (s.ken >= 0 && s.ken < LocationDatabase.allPrefectures.length) ? LocationDatabase.allPrefectures[s.ken] : '';
      l.add(
        _gyouMoji(
          '$kenMei予選　${yo.juni}位(${s.yosenSuu}校)　${TimeDate.timeToJikanFunByouString(yo.time)}'
          '${yo.juni == 1 ? '　優勝(県代表)' : ''}',
          kin: yo.juni == 1,
        ),
      );
      final KoukouChikuTeam? ch = s.chiku;
      if (ch != null && s.chikuBan >= 0 && s.chikuBan < koukouChikuMei.length) {
        l.add(
          _gyouMoji(
            '${koukouChikuMei[s.chikuBan]}大会　${s.chikuJuni}位(${s.chikuSuu}校)　'
            '${TimeDate.timeToJikanFunByouString(ch.time)}'
            '${s.chikuJuni == 1 ? '　優勝' : ''}${ch.daihyou == 2 ? '　地区代表' : ''}',
            kin: ch.daihyou == 2,
          ),
        );
      } else {
        // 地区大会がある地区で、予選の上位に入れなかった(北海道は地区大会がないので出さない)
        final int c = (s.ken >= 0 && s.ken < koukouKenChiku.length) ? koukouKenChiku[s.ken] : -1;
        final List<List<KoukouChikuTeam>>? chiku = r.chiku;
        if (chiku != null && c >= 0 && c < chiku.length && chiku[c].isNotEmpty) {
          l.add(_gyouHosoku('地区大会には進めませんでした(予選の上位3校が進みます)。'));
        }
      }
    }
    // 全国高校駅伝
    final KoukouKirokuTeam? z = s.zenkoku;
    if (z == null) {
      l.add(_gyouHosoku('全国高校駅伝には出ていません。'));
    } else {
      final int c = z.daihyou - 1;
      final String daihyou = (z.daihyou >= 1 && c < koukouChikuMei.length) ? '　地区代表(${koukouChikuMei[c]})' : '';
      // 出場の回数目(「初出場」「5年ぶり3回目」など)。優勝したときは優勝の回数目も(1.9.5)
      final String kaime = _shutsujouYuushouMoji(z, s.zenkokuJuni == 1);
      final String yuushou = (s.zenkokuJuni == 1 && !kaime.contains('優勝')) ? '　優勝' : '';
      l.add(
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _Oritatami(
            key: ValueKey<String>('kp${r.nyuugakuNendo}'),
            midashi: '全国高校駅伝　${s.zenkokuJuni}位(${s.zenkokuSuu}校)　'
                '${TimeDate.timeToJikanFunByouString(z.time)}$yuushou$daihyou${kaime.isEmpty ? '' : '　$kaime'}',
            kin: s.zenkokuJuni == 1,
            futoi: false,
            naka: _member(r, z, s.zenkokuJuni),
          ),
        ),
      );
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final int ban = widget.ban;
    final List<KoukouMei> meibo = koukouMeiboGenzai();
    final KoukouMei m = meibo[ban];
    final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
    final bool okiniiri = koukouOkiniiriYomu().contains(ban);
    int kaisuu(List<int> l) => ban < l.length ? l[ban] : 0;
    final int chikuDaihyou = kai.chikuDaihyou(ban);
    // 地区大会がある地区か(北海道は地区大会がないので、地区大会の優勝回数を出さない)
    final int chikuBan = (m.ken >= 0 && m.ken < koukouKenChiku.length) ? koukouKenChiku[m.ken] : -1;
    final bool chikuAri = chikuBan >= 0 && koukouKenChiku.where((int c) => c == chikuBan).length >= 2;
    // 今、大学にいる卒業生(上の学年から、同じ学年は大学の順)
    final List<SenshuData> sotsugyousei = [
      for (final SenshuData s in _zaigaku.values)
        if (s.gakunen >= 1 && s.gakunen <= 4 && _kouBan(s) == ban) s,
    ]..sort((a, b) {
        final int g = b.gakunen.compareTo(a.gakunen);
        if (g != 0) return g;
        final int u = a.univid.compareTo(b.univid);
        return u != 0 ? u : a.id.compareTo(b.id);
      });
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: Text('${m.mei}高', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: okiniiri ? 'お気に入りから外す' : 'お気に入りに追加',
            icon: Icon(okiniiri ? Icons.star : Icons.star_border, color: okiniiri ? _kin : Colors.white),
            onPressed: _shoriChuu ? null : () => _okiniiriKae(!okiniiri),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                koukouKenMijikai(m.ken),
                style: const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun - 2, fontWeight: FontWeight.bold),
              ),
              Text(koukouMeimonMei[m.meimon.clamp(0, koukouMeimonMei.length - 1).toInt()], style: _hosoku),
              _iroFuda(m.iro),
              if (m.ryuugakusei) _fuda('留学生あり', HENSUU.textcolor),
              if (okiniiri) _fuda('★お気に入り', _kin),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${m.mei}高',
            style: const TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun + 6, fontWeight: FontWeight.bold),
          ),
          if (m.shoukai.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(m.shoukai, style: _honbun),
          ],
          const SizedBox(height: 6),
          Text('集まりやすい選手: ${koukouIroKeikou[_iroBan(m.iro)]}', style: _hosoku),
          const SizedBox(height: 8),
          Text(
            '全国高校駅伝: 出場${kaisuu(kai.shutsujou)}回'
            '${chikuDaihyou > 0 ? '(うち地区代表$chikuDaihyou回)' : ''}・優勝${kaisuu(kai.zenkoku)}回',
            style: _honbun,
          ),
          Text(
            '都道府県予選: 優勝${kaisuu(kai.ken)}回${chikuAri ? '　地区大会: 優勝${kaisuu(kai.chiku)}回' : ''}',
            style: _honbun,
          ),
          const Text(
            '回数は記録を残し始めてからの回数で、毎年4月上旬に新入生が入るときに増えます。',
            style: _hosoku,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _shoriChuu ? null : () => _okiniiriKae(!okiniiri),
                icon: Icon(okiniiri ? Icons.star : Icons.star_border, color: _kin),
                label: Text(okiniiri ? 'お気に入りから外す' : 'お気に入りに追加', style: _honbun),
              ),
              ElevatedButton(
                onPressed: _shoriChuu ? null : _henshuu,
                child: const Text('編集'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'お気に入りの高校は、都道府県別のタブの一番上に並びます。'
            '「編集」では、校名・名門度・タイプ・留学生の有無・紹介文を変えられます(都道府県は変えられません)。',
            style: _hosoku,
          ),
          // ---- 年度ごとの成績 ----
          _midashi('■年度ごとの成績'),
          const Text(
            '新しい回から、大会の記録が残っている直近10回分です。'
            '都道府県予選と地区大会はチームの順位とタイム、全国高校駅伝は押すと走った選手と進学先を見られます。',
            style: _hosoku,
          ),
          if (_kiroku.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('まだ記録がありません。', style: _honbun),
            ),
          for (final KoukouTaikaiKiroku r in _kiroku) ..._kaiSeiseki(r),
          // ---- 今、大学にいる卒業生 ----
          _midashi('■今、大学にいる卒業生'),
          if (sotsugyousei.isEmpty) const Text('今、大学にいる卒業生はいません。', style: _honbun),
          for (final SenshuData s in sotsugyousei) _sotsugyouseiGyou(s),
          // ---- この高校出身の監督(2.0.1。監督の母校パイプ) ----
          _midashi('■この高校出身の大学の監督'),
          if (_kantoku.isEmpty) const Text('今、この高校出身の大学の監督はいません。', style: _honbun),
          for (final BokouKantoku b in _kantoku)
            _gyouMoji(
              '${_univMei[b.univid] ?? ''}大学　${b.mei}監督(${b.nenrei}歳)',
              kin: b.univid == _myUnivId,
            ),
          if (_pipeKiku)
            _gyouHosoku('この高校の新入生は、スカウトで監督の大学を選びやすくなります。'),
          const SizedBox(height: 24),
          const Text('架空の高校です。実在の学校とは関係ありません。大学のレースや育成には影響しません。', style: _hosoku),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 卒業生の行(「3年　山田太郎　→ ○○大学」。自分の大学の選手は色を変える。スカウトの途中で決まっていない新入生は「進路未定」)
  Widget _sotsugyouseiGyou(SenshuData s) {
    final bool mitei = _miteiKa(s);
    final bool jibun = !mitei && s.univid == _myUnivId;
    final String um = mitei ? '進路未定' : (_univMei[s.univid] == null ? '' : '${_univMei[s.univid]}大学');
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${s.gakunen}年', style: _hosoku),
          Text(
            s.name,
            style: TextStyle(
              color: jibun ? Colors.amber : HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (um.isNotEmpty)
            Text(
              mitei ? um : '→ $um',
              style: TextStyle(color: jibun ? Colors.amber : _usui, fontSize: HENSUU.fontsize_honbun - 2),
            ),
        ],
      ),
    );
  }
}

/// 大会の記録(直近10回の全国高校駅伝と高校総体、都道府県予選と地区大会。見出しごとに折りたたみ。1.9.5)
/// [scoutKara] なら(スカウトの画面から開いたとき)、一番新しい回の全国高校駅伝を開いておき、在学生の世代の欄は閉じる。
/// 進学先の文字と色は、[shingakuMoji] と [jibunHantei] で、スカウトの画面に決めてもらう
class _TaikaiKiroku extends StatefulWidget {
  const _TaikaiKiroku({
    this.scoutKara = false,
    this.kotoshiNomi = false,
    this.shingakuMoji,
    this.jibunHantei,
    this.modoruMoji = 'スカウトへ進む',
  });

  /// 今年の高校の大会の画面の、一番下の戻るボタンの文字(2.0.1)
  final String modoruMoji;

  final bool scoutKara;

  /// 今年の高校の大会の画面(KotoshiKoukouTaikaiGamen)か(1.9.9。一番新しい回だけを出す)
  final bool kotoshiNomi;
  final String? Function(KoukouKirokuSousha s)? shingakuMoji;
  final bool Function(KoukouKirokuSousha s)? jibunHantei;

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

  /// コンピュータスカウトONでスカウトの途中か(決まっていない新入生の大学を出さない。1.9.5)
  bool _scoutChuu = false;

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
      final Ghensuu? g = b.isNotEmpty ? b.getAt(0) : null;
      _myUnivId = g?.MYunivid ?? -1;
      // 新入生の進学先の画面と同じ見分け方(1.9.5)
      if (g != null && g.mode == 9000 && Hive.isBoxOpen('kantokuBox')) {
        final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
        _scoutChuu = kantoku != null && isComScoutOn(kantoku);
      }
    }
  }

  /// 今年の新入生(スカウトの候補)の世代の回を、スカウトの途中に見ているか(1.9.9)
  /// (今年の高校の大会の画面と、スカウトの画面から開いた高校名鑑のとき。名前の出ている3年生はまだ大学に
  /// 入っていないので、「大学に入った選手」「進学先」と言わずに「今年の新入生」と書く)
  bool _kotoshiNoKai(KoukouTaikaiKiroku k) =>
      (widget.kotoshiNomi || widget.scoutKara) &&
      k.nyuugakuNendo == koukouImaNoNendo();

  /// スカウトの途中で、進学先が決まっていない新入生か(仮の振り分けの大学を見せない。1.9.5)
  bool _miteiKa(KoukouKirokuSousha s) {
    if (!_scoutChuu) return false;
    final SenshuData? z = _zaigaku[s.id];
    if (z == null || z.name != s.name) return false;
    return z.gakunen == 1 && z.hirou != 1 && !comScoutKettei(z);
  }

  // 回の名前(_kaiMei)は、高校のページでも使うので外に出した(1.9.5)

  /// 名前のない選手の説明(大会の記録とスカウト画面からの結果の画面。1.9.5)
  static const String _namaeNashiSetsumei =
      '名前のない3年生は、ゲームの大学には進まない選手です(ほかの大学や実業団に進む選手、高校で陸上をやめる選手など)。'
      '名前のない留学生も、ゲームの大学には進まない留学生です。';

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
        '増えるのは、その新入生たちが高校3年だった年度の、夏の高校総体と、秋の都道府県予選・地区大会と、'
        '12月の全国高校駅伝の結果です。',
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
    // スカウト画面から開いたときは、進学先の文字と色をスカウト画面に決めてもらう(1.9.5)
    final String? shingaku = s.namaeAri ? widget.shingakuMoji?.call(s) : null;
    // 下級生のときの記録に、あとから名前が付いた選手は、当時の学年を添える(1.9.5。koukou.dart の引き継ぎ)
    final String touji = (s.namaeAri && s.gakunen >= 1 && s.gakunen <= 2) ? '(当時${s.gakunen}年)' : '';
    if (shingaku != null) {
      mei = '${s.name}$touji';
      if (kouAri) {
        sub = shingaku.isEmpty ? kou : '$kou　$shingaku';
      } else {
        sub = shingaku;
      }
      jibun = widget.jibunHantei?.call(s) ?? false;
    } else if (s.namaeAri && _miteiKa(s)) {
      // コンピュータスカウトONでスカウトの途中の、決まっていない新入生は大学を出さない(1.9.5)
      mei = '${s.name}$touji';
      sub = kouAri ? '$kou　進路未定' : '進路未定';
    } else if (s.namaeAri) {
      mei = '${s.name}$touji';
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

  // 優勝の回数目(_yuushouMoji)と出場の回数目(_shutsujouMoji)は、高校のページでも使うので外に出した(1.9.5)

  /// チームの見出し(「1位 天馬学園高(栃木) 2時間03分12秒 地区代表(北関東) 初出場初優勝」)
  String _teamMidashi(KoukouTaikaiKiroku kiroku, int j, KoukouKirokuTeam t) {
    final int c = t.daihyou - 1;
    final String daihyou = (t.daihyou >= 1 && c < koukouChikuMei.length) ? '　地区代表(${koukouChikuMei[c]})' : '';
    // 出場の回数目(「初出場」「3年連続5回目」「5年ぶり3回目」)。1位は優勝の回数目も(1.9.5)
    final String kaime = _shutsujouYuushouMoji(t, j == 0);
    return '${j + 1}位　${_teamMei(kiroku, t)}　${TimeDate.timeToJikanFunByouString(t.time)}$daihyou'
        '${kaime.isEmpty ? '' : '　$kaime'}';
  }

  // 走者の区間と区間順位(_kukanJuniMoji)は、高校のページでも使うので外に出した(1.9.5)

  /// チームの走者(区間の順、補欠は最後)
  List<Widget> _teamMember(KoukouTaikaiKiroku kiroku, int j, KoukouKirokuTeam t) {
    final List<KoukouKirokuSousha>? m = t.member;
    if (m == null) {
      return const [Text('この回は走者の記録がありません。', style: _hosoku)];
    }
    final List<KoukouKirokuSousha> jun = List<KoukouKirokuSousha>.of(m)
      ..sort((a, b) => (a.kukan == 0 ? 99 : a.kukan).compareTo(b.kukan == 0 ? 99 : b.kukan));
    // 今年の新入生の世代をスカウトの途中に見ているときは「今年の新入生」と書く(1.9.9)
    final bool kotoshi = _kotoshiNoKai(kiroku);
    return [
      if (j >= 8)
        Text(
          kotoshi ? '9位以下の高校は、今年の新入生だけを残しています。' : '9位以下の高校は、大学に入った選手だけを残しています。',
          style: _hosoku,
        ),
      if (jun.isEmpty) Text(kotoshi ? '今年の新入生はいません。' : '大学に入った選手はいません。', style: _hosoku),
      for (final KoukouKirokuSousha s in jun)
        _soushaGyou(
          kiroku,
          _kukanJuniMoji(kiroku, t, s),
          s,
          s.kukan >= 1 ? TimeDate.timeToFunByouString(s.time) : '',
          kouAri: false,
        ),
    ];
  }

  /// 在学生の世代の欄の、全国高校駅伝の優勝校の大学に入った選手(区間の順、補欠は最後。区間と区間順位も。1.9.5)
  /// 名前のない選手(1・2年生、大学に入らなかった3年生、高校の留学生)は出さない。
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
    return [
      for (final KoukouKirokuSousha s in jun)
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: _soushaGyou(kiroku, _kukanJuniMoji(kiroku, t, s), s, '', kouAri: false, chiisai: true),
        ),
    ];
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
    if (widget.kotoshiNomi) return _kotoshiNoKekka(context);
    final int erabu = _erabu.clamp(0, _kiroku.length - 1).toInt();
    final KoukouTaikaiKiroku k = _kiroku[erabu];

    // ---- 在学生の世代の優勝校と優勝者(1.9.5) ----
    // 一番新しい記録を今の1年生の世代として、そこから4回分(記録は新入生が入るときに増え、
    // 同じときに4年生が卒業するので、今の日付を見なくても在学生とずれない。途中の年の記録が
    // 欠けていても、卒業した世代は出さない)
    final int saishinNendo = _kiroku.first.nyuugakuNendo;
    final List<Widget> chokkin = [
      const Text(
        '優勝校の下に、大学に入った選手と進学先を出しています。'
        '全員の走者と、それより前の回は、下の「大会の結果」で見られます。',
        style: _hosoku,
      ),
    ];
    for (final KoukouTaikaiKiroku r in _kiroku) {
      final int imaGakunen = saishinNendo - r.nyuugakuNendo + 1;
      if (imaGakunen < 1 || imaGakunen > 4) continue;
      chokkin.add(_koMidashi(_kaiMei(r, imaGakunen: imaGakunen)));
      // 全国高校駅伝は優勝校だけ(優勝タイムと、その時点の優勝の回数目。下に大学に入った選手と進学先と区間順位)
      if (r.zenkoku.isNotEmpty) {
        final KoukouKirokuTeam yu = r.zenkoku.first;
        // 初出場で優勝した高校は「初出場初優勝」(1.9.5)
        final String yuushou = (yu.kaime == 1 && yu.yuushouKaime == 1) ? '初出場初優勝' : _yuushouMoji(yu);
        chokkin.add(
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4),
            child: Text('全国高校駅伝 優勝', style: _hosoku),
          ),
        );
        chokkin.add(
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              '${_teamMei(r, yu)}　${TimeDate.timeToJikanFunByouString(yu.time)}'
              '${yuushou.isEmpty ? '' : '　$yuushou'}',
              style: _honbun,
            ),
          ),
        );
        chokkin.addAll(_yuushouMember(r, yu));
      }
      // 高校総体の優勝者(タイムも)
      for (int sh = 0; sh < r.soutai.length && sh < _shumokuMei.length; sh++) {
        if (r.soutai[sh].isEmpty) continue;
        final KoukouKirokuSousha s = r.soutai[sh].first;
        chokkin.add(_soushaGyou(r, '総体${_shumokuMei[sh]} 優勝', s, TimeDate.timeToFunByouString(s.time)));
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
      if (widget.scoutKara) ...[
        _scoutSetsumei(),
        const SizedBox(height: 12),
      ],
      _jikiChuuki(),
      const SizedBox(height: 12),
      const Text(
        '新入生の世代ごとに、高校3年のときの全国高校駅伝と高校総体の結果を、直近10回分残しています。'
        '大学に入った選手には進学先を、自分の大学に来た選手は色を変えて出します。'
        '都道府県予選と地区大会は、チームの順位とタイムを残しています。',
        style: _honbun,
      ),
      const SizedBox(height: 4),
      const Text(
        '名前の出ている選手は、ゲームの大学に入った選手です。$_namaeNashiSetsumei'
        '大会の回は、大学の駅伝と同じく1年目の大会を第1回とし、ゲーム開始前の大会はプレ大会として出します。',
        style: _hosoku,
      ),
      const SizedBox(height: 8),
      _Oritatami(midashi: '在学生の世代の優勝校と優勝者', naka: chokkin, hajimeHiraku: !widget.scoutKara),
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
      ..._kekka(k, erabu, zenkokuHiraku: widget.scoutKara && erabu == 0),
      const SizedBox(height: 24),
      const Text('架空の高校の大会です。大学のレースや育成には影響しません。', style: _hosoku),
      const SizedBox(height: 24),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: l);
  }

  /// 地区大会の1チームの行(「1位 天馬学園高(栃木) 2時間05分12秒 地区代表」。1.9.5)
  Widget _chikuGyou(KoukouTaikaiKiroku k, int j, KoukouChikuTeam t) {
    final String daihyou = t.daihyou == 2 ? '　地区代表' : (t.daihyou == 1 ? '　県代表' : '');
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Text(
        '${j + 1}位　${k.kouMei(t.kouCode)}　${TimeDate.timeToJikanFunByouString(t.time)}$daihyou',
        style: t.daihyou == 2 ? const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun) : _honbun,
      ),
    );
  }

  /// 都道府県予選の1都道府県分(見出しと、各チームの行。残していないチームは「ほか○校」。1.9.5)
  List<Widget> _yosenKen(KoukouTaikaiKiroku k, int ken, KoukouYosenKen y) {
    final String kenMei =
        (ken >= 0 && ken < LocationDatabase.allPrefectures.length) ? LocationDatabase.allPrefectures[ken] : '';
    final int nokori = y.shussouSuu - y.teams.length;
    return [
      _koMidashi('$kenMei(${y.shussouSuu}校)'),
      for (final KoukouYosenTeam t in y.teams)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            '${t.juni}位　${k.kouMei(t.kouCode)}　${TimeDate.timeToJikanFunByouString(t.time)}'
            '${t.juni == 1 ? '　県代表' : ''}',
            style: t.juni == 1 ? const TextStyle(color: _kin, fontSize: HENSUU.fontsize_honbun) : _honbun,
          ),
        ),
      if (nokori > 0)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 2),
          child: Text('ほか$nokori校', style: _hosoku),
        ),
    ];
  }

  /// 1回分の大会の結果(全国高校駅伝の全チームと走者、区間の上位3人、地区大会と都道府県予選のチームの順位とタイム、
  /// 高校総体の決勝。見出しごとに折りたたみ)
  /// [erabu] は折りたたみの開け閉めを回ごとに分けるための番号。[zenkokuHiraku] なら全国高校駅伝を開いておく
  /// (名鑑の「大会の結果」と、スカウト画面から開いたときに使う。1.9.5)
  /// [kotoshi] なら(今年の高校の大会の画面。1.9.9)、区間の上位3人と高校総体の決勝も開いておき、
  /// 高校総体を地区大会・都道府県予選より前に出す
  List<Widget> _kekka(
    KoukouTaikaiKiroku k,
    int erabu, {
    bool zenkokuHiraku = false,
    bool kotoshi = false,
  }) {
    final List<List<KoukouChikuTeam>>? ch = k.chiku;
    final List<KoukouYosenKen>? yo = k.yosen;
    // 高校総体の決勝(今年の高校の大会の画面では、開いて全国高校駅伝のすぐ後に出す。1.9.9)
    final List<Widget> soutai = [
      for (int sh = 0; sh < k.soutai.length && sh < _shumokuMei.length; sh++)
        _Oritatami(
          key: ValueKey<String>('soutai$erabu-$sh'),
          midashi: '高校総体 ${_shumokuMei[sh]} 決勝',
          hajimeHiraku: kotoshi,
          naka: [
            for (int j = 0; j < k.soutai[sh].length; j++)
              _soushaGyou(k, '${j + 1}位', k.soutai[sh][j], TimeDate.timeToFunByouString(k.soutai[sh][j].time)),
          ],
        ),
    ];
    return [
      // 全国高校駅伝(高校を開くと走者と進学先)
      _Oritatami(
        key: ValueKey<String>('zenkoku$erabu'),
        midashi: '全国高校駅伝(${k.zenkoku.length}校)',
        hajimeHiraku: zenkokuHiraku,
        naka: [
          Text(
            _kotoshiNoKai(k)
                ? '高校を押すと、走った選手を見られます。名前の出ている3年生が、この春に大学に入る今年の新入生(スカウトの候補)です。'
                : '高校を押すと、走った選手と進学先を見られます。',
            style: _hosoku,
          ),
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
        hajimeHiraku: kotoshi,
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
      if (kotoshi) ...soutai,
      // 地区大会(チームの順位とタイム。1.9.5)
      _Oritatami(
        key: ValueKey<String>('chiku$erabu'),
        midashi: '地区大会',
        naka: ch == null
            ? const [Text('この回は、地区大会の記録がありません。', style: _hosoku)]
            : [
                const Text(
                  '各都道府県の予選の上位3校が走り、県代表を除いた最上位の高校が、地区代表として全国高校駅伝に進みます。'
                  '北海道は地区大会がなく、予選の2位が地区代表です。',
                  style: _hosoku,
                ),
                for (int c = 0; c < ch.length && c < koukouChikuMei.length; c++)
                  if (ch[c].isNotEmpty)
                    _Oritatami(
                      key: ValueKey<String>('chiku$erabu-$c'),
                      midashi: '${koukouChikuMei[c]}大会(${ch[c].length}校)',
                      futoi: false,
                      naka: [
                        for (int j = 0; j < ch[c].length; j++) _chikuGyou(k, j, ch[c][j]),
                      ],
                    ),
              ],
      ),
      // 都道府県予選(チームの順位とタイム。地区ごとに折りたたみ。1.9.5)
      _Oritatami(
        key: ValueKey<String>('yosen$erabu'),
        midashi: '都道府県予選',
        naka: yo == null
            ? const [Text('この回は、都道府県予選の記録がありません。', style: _hosoku)]
            : [
                const Text(
                  '各都道府県の名簿の5校が走り、1位の高校が県代表として全国高校駅伝に、上位3校が地区大会に進みます。'
                  '予選のコースは全国と同じ距離の平らなコースですが、その日の気温や風で、県ごとにタイムの出やすさが違います。',
                  style: _hosoku,
                ),
                for (int c = 0; c < koukouChikuMei.length; c++)
                  _Oritatami(
                    key: ValueKey<String>('yosen$erabu-$c'),
                    midashi: koukouChikuMei[c],
                    futoi: false,
                    naka: [
                      for (int ken = 0; ken < yo.length && ken < koukouKenChiku.length; ken++)
                        if (koukouKenChiku[ken] == c) ..._yosenKen(k, ken, yo[ken]),
                    ],
                  ),
              ],
      ),
      // 高校総体の決勝
      if (!kotoshi) ...soutai,
    ];
  }

  /// 今年の高校の大会の画面の中身(1.9.9。一番新しい回だけ。下に「スカウトへ進む」ボタン)
  Widget _kotoshiNoKekka(BuildContext context) {
    final KoukouTaikaiKiroku k = _kiroku.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '今年の新入生(スカウトの候補)が高校3年だった年度の、${_kaiMei(k)}の結果です。'
          '高校総体は夏、全国高校駅伝は12月に行われました。',
          style: _honbun,
        ),
        const SizedBox(height: 4),
        const Text(
          '選手の後ろには、スカウトの画面と同じく「進路未定」などの今の状況を出します。'
          '$_namaeNashiSetsumei',
          style: _hosoku,
        ),
        const SizedBox(height: 8),
        ..._kekka(k, 0, zenkokuHiraku: true, kotoshi: true),
        const SizedBox(height: 16),
        const Text(
          '前の回の結果や高校のことは、スカウトの画面の「高校名鑑」で見られます。'
          '架空の高校の大会です。大学のレースや育成には影響しません。',
          style: _hosoku,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: HENSUU.buttonColor,
              foregroundColor: HENSUU.buttonTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(
              widget.modoruMoji,
              style: const TextStyle(fontSize: HENSUU.fontsize_honbun, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// スカウトの画面から開いたときの説明(1.9.5)。一番新しい回が今年の新入生の世代か(記録がなければ、そう書く)
  Widget _scoutSetsumei() {
    final bool kotoshi = _kiroku.isNotEmpty && _kiroku.first.nyuugakuNendo == koukouImaNoNendo();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.lightBlueAccent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kotoshi
            ? '一番新しい回が、今年の新入生(スカウトの候補)が高校3年だった世代です。'
                '下の「大会の結果」で、その回の全国高校駅伝を開いてあります。'
                '今年の新入生には、スカウトの画面と同じく「進路未定」などを出します。'
                'お気に入りの高校は、「都道府県別」のタブの一番上に並びます。'
            : '今年の新入生の、高校の大会の記録はまだありません。',
        style: const TextStyle(color: Colors.lightBlueAccent, fontSize: HENSUU.fontsize_honbun - 1),
      ),
    );
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
