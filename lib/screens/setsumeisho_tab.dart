// lib/screens/setsumeisho_tab.dart
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/setsumeisho_text.dart'; // 説明書のグループと本文

// ------------------------------------------------------------
// 説明画面の説明書タブ(1.8.4)
// ・見出しは折りたたみ。最初はどの見出しも閉じていて、閉じた見出しの並びが目次になる。
// ・開いている見出しは、アプリを起動している間だけ覚える(セーブデータには保存しない)。
// ・上の検索欄に言葉を入れると、その言葉を含む行だけを見出しごとに出す(1段下げた行が当たったときは、上の行も出す)。
//   見出しを押すと、検索を消してその見出しを開き、そこまでスクロールする。検索の言葉は覚えない。
// ・下の方までスクロールすると、右下に一番上に戻る「↑」ボタンを出す。
// ・本文は lib/kansuu/setsumeisho_text.dart(仕様の部分は lib/kansuu/shiyou_text.dart)。
// ------------------------------------------------------------

class SetsumeishoTab extends StatefulWidget {
  const SetsumeishoTab({
    super.key,
    required this.ueWidget,
    required this.licenseWidget,
  });

  /// 一番上に出すもの(版・変更履歴・アップデートの確認)
  final Widget ueWidget;

  /// 「その他」の一番下に出すもの(ライセンス)
  final Widget licenseWidget;

  @override
  State<SetsumeishoTab> createState() => _SetsumeishoTabState();
}

class _SetsumeishoTabState extends State<SetsumeishoTab> {
  // 開いている見出し(アプリを起動している間だけ覚える)
  static final Set<String> _hirakiMidashi = <String>{};

  final TextEditingController _kensakuController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // 検索結果から見出しへ移るときに使う(見出しごと)
  final Map<String, GlobalKey> _midashiKey = <String, GlobalKey>{};
  String _kensaku = ''; // 検索の言葉
  bool _ueBotan = false; // 「↑」ボタンを出すか

  static const TextStyle _honbunStyle = TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final bool deru = _scrollController.offset > 400;
      if (deru != _ueBotan) {
        setState(() {
          _ueBotan = deru;
        });
      }
    });
  }

  @override
  void dispose() {
    _kensakuController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SetsumeishoGroup> groupList = setsumeishoGroupList();
    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.ueWidget,
              const SizedBox(height: 12),
              _kensakuRan(),
              const SizedBox(height: 8),
              if (_kensaku.isEmpty) ...[
                _subeteBotan(groupList),
                ..._mokujiWidgets(groupList),
              ] else
                ..._kensakuKekka(groupList),
            ],
          ),
        ),
        if (_ueBotan)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: null,
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              tooltip: '一番上に戻る',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }

  // 検索欄
  Widget _kensakuRan() {
    return TextField(
      controller: _kensakuController,
      style: _honbunStyle,
      decoration: InputDecoration(
        hintText: '説明書を検索',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _kensaku.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _kensakuController.clear();
                  setState(() {
                    _kensaku = '';
                  });
                },
              ),
        isDense: true,
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (String s) {
        setState(() {
          _kensaku = s.trim();
        });
      },
    );
  }

  // 「すべて開く」「すべて閉じる」
  Widget _subeteBotan(List<SetsumeishoGroup> groupList) {
    const TextStyle linkStyle = TextStyle(
      color: HENSUU.LinkColor,
      decoration: TextDecoration.underline,
      decorationColor: HENSUU.textcolor,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              for (final SetsumeishoGroup g in groupList) {
                for (final SetsumeishoKoumoku k in g.koumoku) {
                  _hirakiMidashi.add(k.setsu.midashi);
                }
              }
            });
          },
          child: const Text('すべて開く', style: linkStyle),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _hirakiMidashi.clear();
            });
          },
          child: const Text('すべて閉じる', style: linkStyle),
        ),
      ],
    );
  }

  // 見出しの一覧(グループごとに区切る。閉じた見出しの並びが目次になる)
  List<Widget> _mokujiWidgets(List<SetsumeishoGroup> groupList) {
    final List<Widget> list = [];
    for (int i = 0; i < groupList.length; i++) {
      final SetsumeishoGroup g = groupList[i];
      if (g.namae.isNotEmpty) {
        list.add(_groupKugiri(g.namae, saisho: i == 0));
      } else if (i > 0) {
        // 見出しが1つだけのグループは、区切りの線だけ
        list.add(
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Divider(height: 1, color: Colors.white24),
          ),
        );
      }
      for (final SetsumeishoKoumoku k in g.koumoku) {
        list.add(_koumokuWidget(k));
      }
    }
    // 「その他」の一番下(ライセンス)
    list.add(widget.licenseWidget);
    return list;
  }

  // グループの区切り(グループ名と線)
  Widget _groupKugiri(String namae, {required bool saisho}) {
    return Padding(
      padding: EdgeInsets.only(top: saisho ? 0 : 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            namae,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Colors.white24),
        ],
      ),
    );
  }

  // 見出し1つ分(タップで開け閉めする)
  Widget _koumokuWidget(SetsumeishoKoumoku k) {
    final String midashi = k.setsu.midashi;
    final bool hiraki = _hirakiMidashi.contains(midashi);
    return Column(
      key: _midashiKey.putIfAbsent(midashi, () => GlobalKey()),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (hiraki) {
                _hirakiMidashi.remove(midashi);
              } else {
                _hirakiMidashi.add(midashi);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hiraki ? Icons.expand_more : Icons.chevron_right,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    midashi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hiraki)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final String gyou in k.setsu.gyou) _gyouWidget(gyou, ''),
                if (k.zu.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    k.zuSetsumei,
                    style: const TextStyle(
                      color: HENSUU.textcolor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 横長の画像を画面幅に合わせて表示
                  for (final String gazou in k.zu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Image.asset(gazou, fit: BoxFit.contain),
                      ),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // 検索結果(言葉を含む行だけを、見出しごとに出す)
  List<Widget> _kensakuKekka(List<SetsumeishoGroup> groupList) {
    final List<Widget> list = [];
    for (final SetsumeishoGroup g in groupList) {
      for (final SetsumeishoKoumoku k in g.koumoku) {
        final List<String> atari = _atariGyou(k.setsu.gyou, _kensaku);
        final bool midashiAtari = _fukumu(k.setsu.midashi, _kensaku);
        if (atari.isEmpty && !midashiAtari) continue;
        list.add(
          InkWell(
            onTap: () => _midashiHeIdou(k.setsu.midashi),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _hikariText(
                      k.setsu.midashi,
                      _kensaku,
                      const TextStyle(
                        color: Colors.white,
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    '開く',
                    style: TextStyle(
                      color: HENSUU.LinkColor,
                      decoration: TextDecoration.underline,
                      decorationColor: HENSUU.textcolor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        for (final String gyou in atari) {
          list.add(
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _gyouWidget(gyou, _kensaku),
            ),
          );
        }
      }
    }
    if (list.isEmpty) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '「$_kensaku」を含む説明は見つかりませんでした。',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return list;
  }

  // 言葉を含む行を選ぶ(1段下げた行が当たったときは、その上の段の行も出す)
  List<String> _atariGyou(List<String> gyou, String kotoba) {
    final Set<int> bangou = <int>{};
    for (int i = 0; i < gyou.length; i++) {
      if (!_fukumu(gyou[i], kotoba)) continue;
      if (gyou[i].startsWith('　・')) {
        int ue = i - 1;
        while (ue >= 0 && gyou[ue].startsWith('　・')) {
          ue--;
        }
        if (ue >= 0) bangou.add(ue);
      }
      bangou.add(i);
    }
    final List<int> narabi = bangou.toList()..sort();
    return [for (final int i in narabi) gyou[i]];
  }

  // 言葉を含むか(英字の大文字・小文字は区別しない)
  bool _fukumu(String bun, String kotoba) {
    if (kotoba.isEmpty) return false;
    return bun.toLowerCase().contains(kotoba.toLowerCase());
  }

  // 検索結果の見出しを押したとき: 検索を消して、その見出しを開き、そこまでスクロールする
  void _midashiHeIdou(String midashi) {
    FocusScope.of(context).unfocus();
    _kensakuController.clear();
    setState(() {
      _kensaku = '';
      _hirakiMidashi.add(midashi);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _midashiKey[midashi]?.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 本文の1行
  // 「・」で始まる行は、折り返した2行目以降が「・」の後ろにそろうようにする。
  // 「　・」で始まる行は1段下げる。「・」で始まらない行は、そのままの文として出す。
  // kotoba が空でなければ、その言葉に色を付ける
  Widget _gyouWidget(String gyou, String kotoba) {
    double sage = 0;
    String bun = gyou;
    if (bun.startsWith('　・')) {
      sage = 16;
      bun = bun.substring(1);
    }
    if (!bun.startsWith('・')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _hikariText(bun, kotoba, _honbunStyle),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: sage, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・', style: _honbunStyle),
          Expanded(child: _hikariText(bun.substring(1), kotoba, _honbunStyle)),
        ],
      ),
    );
  }

  // 検索の言葉に色を付けた文
  Widget _hikariText(String bun, String kotoba, TextStyle style) {
    if (!_fukumu(bun, kotoba)) {
      return Text(bun, style: style);
    }
    final String bunKomoji = bun.toLowerCase();
    final String kotobaKomoji = kotoba.toLowerCase();
    final List<TextSpan> spans = [];
    int i = 0;
    while (i < bun.length) {
      final int j = bunKomoji.indexOf(kotobaKomoji, i);
      if (j < 0) {
        spans.add(TextSpan(text: bun.substring(i)));
        break;
      }
      if (j > i) spans.add(TextSpan(text: bun.substring(i, j)));
      spans.add(
        TextSpan(
          text: bun.substring(j, j + kotoba.length),
          style: const TextStyle(
            color: Colors.black,
            backgroundColor: Colors.yellow,
          ),
        ),
      );
      i = j + kotoba.length;
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
