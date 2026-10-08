import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ekiden/kansuu/kiji/kiji.dart';
import 'package:ekiden/screens/ai_copy_matome.dart';

// ------------------------------------------------------------
// ニュース記事(箱庭スポーツ)の画面(1.9.2)
// ・ゲームの画面と同じく黒い背景(目が疲れにくいように)で、ニュースサイト風に見せる
// ・一覧の画面: トップ記事を大きく、ほかの記事を見出しの並びで出す
// ・記事の画面: カテゴリ・見出し・配信日時と記者・リード・本文・成績欄・関連記事。
//   最後に、生成AIに渡すテキスト(依頼文つきの記事のコピーと、いつものまとめボタン)
// ------------------------------------------------------------

// 色(黒い背景に合わせた落ち着いた色)
const Color _haikei = Colors.black;
const Color _waku = Color(0xFF161616);
const Color _sen = Color(0xFF333333);
const Color _honbunIro = Color(0xFFDDDDDD);
const Color _usui = Color(0xFF9E9E9E);
const Color _aka = Color(0xFFE53935); // サイトの印の色
const Color _jibunIro = Color(0xFFFFB300); // 自分の大学の印
const Color _commentIro = Color(0xFF4FC3F7);

/// 結果の記事の一覧を開く(結果画面から)
void kijiKekkaHiraku(BuildContext context) {
  final List<Kiji> list = kijiKekkaIchiran();
  // 対校戦の記事は駅伝ではないので、サイト名の横を「陸上ニュース・対校戦」にする(1.9.2)
  final bool taikousen = list.isNotEmpty && list.first.category == '対校戦';
  _hiraku(context, list, kekka: true, sub: taikousen ? '陸上ニュース・対校戦' : null);
}

/// 展望の記事の一覧を開く(直前順位予想の画面から)
void kijiTenbouHiraku(BuildContext context, List<KijiYosouJin> yosou) {
  _hiraku(context, kijiTenbouIchiran(yosou), kekka: false);
}

/// スタート直前号の一覧を開く(目標順位の確認の画面から。1.9.2)
void kijiChokuzenHiraku(BuildContext context) {
  _hiraku(
    context,
    kijiChokuzenIchiran(),
    kekka: false,
    sub: '駅伝ニュース・スタート直前号',
  );
}

void _hiraku(
  BuildContext context,
  List<Kiji> list, {
  required bool kekka,
  String? sub,
}) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    barrierDismissible: true,
    barrierLabel: kijiSiteMei,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return KijiIchiranGamen(list: list, kekka: kekka, sub: sub);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// 記事の一覧を開くカード(結果画面・直前順位予想・目標順位の確認の画面に置く。1.9.2)
/// ・ほかのリンクに紛れないよう、記事の画面と同じ黒地と赤い印のカードにして、
///   一番上の記事の見出しを予告する
/// ・記事は画面を出したあとで1回だけ作る(画面が出るのを遅らせず、描き直しのたびにも作らない)。
///   大会が変わったら作り直すよう、置く側で大会ごとの key を付ける
/// ・高さは文字に合わせて伸びる(文字を大きくしても横にはみ出さない)。見出しは2行まで
class KijiLinkCard extends StatefulWidget {
  /// 一番上の行の名前(「ニュース記事(箱庭スポーツ)」など。説明書の呼び方と合わせる)
  final String namae;

  /// 記事を作る(見出しの予告に使う)
  final List<Kiji> Function() tsukuru;

  /// 記事の一覧を開く
  final void Function(BuildContext context) hiraku;

  const KijiLinkCard({
    super.key,
    required this.namae,
    required this.tsukuru,
    required this.hiraku,
  });

  @override
  State<KijiLinkCard> createState() => _KijiLinkCardState();
}

class _KijiLinkCardState extends State<KijiLinkCard> {
  /// 一番上の記事の見出し(作る前や、記事がないときはnull)
  String? _midashi;

  /// 記事の本数(作る前は0)
  int _honsuu = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final List<Kiji> list = widget.tsukuru();
      if (!mounted) return;
      setState(() {
        _honsuu = list.length;
        _midashi = list.isEmpty ? null : list.first.midashi;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? midashi = _midashi;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: _waku,
          child: InkWell(
            onTap: () => widget.hiraku(context),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: _aka, width: 5),
                  top: BorderSide(color: _sen),
                  right: BorderSide(color: _sen),
                  bottom: BorderSide(color: _sen),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📰 ${widget.namae}${_honsuu > 0 ? '・$_honsuu本' : ''}',
                    style: const TextStyle(
                      color: _aka,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (midashi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      midashi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    '記事を読む ›',
                    style: TextStyle(color: _usui, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// サイトの名前の帯(一覧と記事の画面の上に出す)
class _SiteMei extends StatelessWidget {
  final String sub;

  const _SiteMei({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 22, color: _aka),
        const SizedBox(width: 8),
        const Text(
          kijiSiteMei,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            sub,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _usui, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// カテゴリの札
class _Fuda extends StatelessWidget {
  final String moji;
  final Color iro;

  const _Fuda(this.moji, this.iro);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: iro),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(moji, style: TextStyle(color: iro, fontSize: 12)),
    );
  }
}

/// 記事の札の並び(カテゴリと、自分の大学の印)
Widget _fudaNarabi(Kiji kiji) {
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      _Fuda(kiji.category, _aka),
      if (kiji.jibun) const _Fuda('自分の大学', _jibunIro),
      if (!kiji.kekka) const _Fuda('展望', _commentIro),
    ],
  );
}

/// 記事の画面を開く
void _kijiWoHiraku(
  BuildContext context,
  List<Kiji> list,
  int bangou, {
  bool okikae = false,
}) {
  final MaterialPageRoute<void> route = MaterialPageRoute<void>(
    builder: (context) => KijiGamen(list: list, bangou: bangou),
  );
  if (okikae) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

/// 生成AIに渡すテキスト(依頼文つき)をコピーする
Future<void> _copy(BuildContext context, String moji, String naiyou) async {
  await Clipboard.setData(ClipboardData(text: moji));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$naiyouをコピーしました。生成AIに貼り付けて使えます')),
  );
}

// ------------------------------------------------------------
// 一覧の画面
// ------------------------------------------------------------

class KijiIchiranGamen extends StatelessWidget {
  final List<Kiji> list;

  /// 結果の記事か(false なら展望の記事)
  final bool kekka;

  /// サイト名の横に出す文(なければ「駅伝ニュース」「駅伝ニュース・展望」)
  final String? sub;

  const KijiIchiranGamen({
    super.key,
    required this.list,
    required this.kekka,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _haikei,
      appBar: AppBar(
        title: const Text(
          kijiSiteMei,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: _haikei,
        foregroundColor: Colors.white,
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'この大会の記事はまだありません',
                  style: TextStyle(color: _honbunIro),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SiteMei(
                  sub: sub ?? (kekka ? '駅伝ニュース' : '駅伝ニュース・展望'),
                ),
                const SizedBox(height: 12),
                const Divider(color: _sen, height: 1),
                const SizedBox(height: 16),
                _topKiji(context),
                const SizedBox(height: 20),
                if (list.length > 1) ...[
                  const Text(
                    'ほかの記事',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (int i = 1; i < list.length; i++) _gyou(context, i),
                ],
                const SizedBox(height: 24),
                _matomeCopy(context),
                const SizedBox(height: 16),
                const Text(
                  '※記事は、ゲームの今のデータから作った架空のニュースです。',
                  style: TextStyle(color: _usui, fontSize: 12),
                ),
              ],
            ),
    );
  }

  // トップ記事(大きく)
  Widget _topKiji(BuildContext context) {
    final Kiji kiji = list.first;
    return InkWell(
      onTap: () => _kijiWoHiraku(context, list, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _waku,
          border: Border(left: BorderSide(color: _aka, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fudaNarabi(kiji),
            const SizedBox(height: 10),
            Text(
              kiji.midashi,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              kiji.lead,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _honbunIro, fontSize: 14, height: 1.7),
            ),
            const SizedBox(height: 8),
            Text(kiji.haishin, style: const TextStyle(color: _usui, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ほかの記事(見出しの行)
  Widget _gyou(BuildContext context, int i) {
    final Kiji kiji = list[i];
    return InkWell(
      onTap: () => _kijiWoHiraku(context, list, i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _sen)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fudaNarabi(kiji),
            const SizedBox(height: 6),
            Text(
              kiji.midashi,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(kiji.haishin, style: const TextStyle(color: _usui, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // すべての記事をまとめてコピー
  Widget _matomeCopy(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _copy(
        context,
        kijiIraibun(kekka) + list.map((k) => k.zenbun()).join('\n\n'),
        'すべての記事(依頼文つき)',
      ),
      icon: const Icon(Icons.copy_all, color: Colors.cyanAccent),
      label: const Text(
        'すべての記事を生成AI向けにコピー',
        style: TextStyle(color: Colors.cyanAccent),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}

// ------------------------------------------------------------
// 記事の画面
// ------------------------------------------------------------

class KijiGamen extends StatelessWidget {
  final List<Kiji> list;
  final int bangou;

  const KijiGamen({super.key, required this.list, required this.bangou});

  @override
  Widget build(BuildContext context) {
    final Kiji kiji = list[bangou];
    return Scaffold(
      backgroundColor: _haikei,
      appBar: AppBar(
        title: const Text(
          kijiSiteMei,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: _haikei,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _fudaNarabi(kiji),
          const SizedBox(height: 12),
          Text(
            kiji.midashi,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${kiji.haishin}　${kiji.kisha}',
            style: const TextStyle(color: _usui, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(color: _sen, height: 1),
          const SizedBox(height: 16),
          Text(
            kiji.lead,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.85,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          for (final KijiBlock b in kiji.honbun) _block(b),
          for (final KijiHyou h in kiji.hyou) _hyou(h),
          const SizedBox(height: 28),
          _aiWaku(context, kiji),
          if (list.length > 1) ...[
            const SizedBox(height: 28),
            const Text(
              '関連記事',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < list.length; i++)
              if (i != bangou) _kanren(context, i),
          ],
          const SizedBox(height: 20),
          const Text(
            '※この記事は、ゲームの今のデータから作った架空のニュースです。',
            style: TextStyle(color: _usui, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 本文の1かたまり
  Widget _block(KijiBlock b) {
    switch (b.shurui) {
      case KijiBlockShurui.koMidashi:
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Row(
            children: [
              Container(width: 4, height: 18, color: _aka),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.bun,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      case KijiBlockShurui.comment:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: _waku,
            border: Border(left: BorderSide(color: _commentIro, width: 3)),
          ),
          child: Text(
            b.bun,
            style: const TextStyle(
              color: Color(0xFFE8E8E8),
              fontSize: 15,
              height: 1.8,
            ),
          ),
        );
      case KijiBlockShurui.danraku:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            b.bun,
            style: const TextStyle(color: _honbunIro, fontSize: 15, height: 1.85),
          ),
        );
    }
  }

  // 成績欄(横に長いときは横にスクロール)
  Widget _hyou(KijiHyou h) {
    const TextStyle midashiStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );
    const TextStyle mojiStyle = TextStyle(color: _honbunIro, fontSize: 13);
    Widget masu(String s, TextStyle st) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(s, style: st, softWrap: false),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '【${h.title}】',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: const TableBorder(
                horizontalInside: BorderSide(color: _sen),
                top: BorderSide(color: _sen),
                bottom: BorderSide(color: _sen),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: _waku),
                  children: [for (final String s in h.retsu) masu(s, midashiStyle)],
                ),
                for (final List<String> g in h.gyou)
                  TableRow(
                    children: [
                      for (int i = 0; i < h.retsu.length; i++)
                        masu(i < g.length ? g[i] : '', mojiStyle),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 生成AIに渡すテキストの枠
  Widget _aiWaku(BuildContext context, Kiji kiji) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生成AIで、もっと詳しい記事に',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kiji.kekka
                ? 'この記事を依頼文つきでコピーして生成AIに貼り付けると、記者になりきって書き直してくれます。'
                    '結果の詳しいデータは「生成AIに渡すテキスト」の振り返りセットなどで渡せます。'
                : 'この記事を依頼文つきでコピーして生成AIに貼り付けると、展望記事に書き直してくれます。'
                    'コースや区間配置のデータは「生成AIに渡すテキスト」で渡せます。',
            style: const TextStyle(color: _honbunIro, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy(
                  context,
                  kijiIraibun(kiji.kekka) + kiji.zenbun(),
                  'この記事(依頼文つき)',
                ),
                icon: const Icon(Icons.copy, color: Colors.cyanAccent),
                label: const Text(
                  'この記事をコピー',
                  style: TextStyle(color: Colors.cyanAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
              AiCopyMatomeButton(kekkaGamen: kiji.kekka),
            ],
          ),
        ],
      ),
    );
  }

  // 関連記事の行
  Widget _kanren(BuildContext context, int i) {
    final Kiji kiji = list[i];
    return InkWell(
      onTap: () => _kijiWoHiraku(context, list, i, okikae: true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _sen)),
        ),
        child: Row(
          children: [
            const Icon(Icons.article_outlined, color: _usui, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                kiji.midashi,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
