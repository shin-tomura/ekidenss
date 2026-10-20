// lib/screens/setsumeisho_tab.dart
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/setsumeisho_text.dart'; // 説明書のグループと本文

// ------------------------------------------------------------
// 説明画面の説明書タブ(1.8.4)
// ・見出しは折りたたみ。最初はどの見出しも閉じていて、閉じた見出しの並びが目次になる。
// ・開いている見出しは、アプリを起動している間だけ覚える(セーブデータには保存しない)。
// ・下の方までスクロールすると、右下に一番上に戻る「↑」ボタンを出す。
// ・本文は lib/kansuu/setsumeisho_text.dart(仕様の部分は lib/kansuu/shiyou_text.dart)。
// ・2.1.1から、要点のある見出しは、開くと要点だけを出し、本文と図はその下の「くわしく」を開くと出す。
//   「くわしく」を開いているかも、アプリを起動している間だけ覚える。「すべて開く」は見出しだけを開く
//   (要点が並び、全体のあらましになる)。「すべて閉じる」は「くわしく」も閉じる。
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
  // 「くわしく」を開いている見出し(アプリを起動している間だけ覚える。2.1.1)
  static final Set<String> _hirakiKuwashiku = <String>{};

  final ScrollController _scrollController = ScrollController();
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
              const SizedBox(height: 8),
              _subeteBotan(groupList),
              ..._mokujiWidgets(groupList),
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
              _hirakiKuwashiku.clear();
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
              // 要点のない見出しは、今まで通り本文と図をそのまま出す(2.1.1)
              children: k.youten.isEmpty
                  ? _honbunWidgets(k)
                  : [
                      for (final String gyou in k.youten) _gyouWidget(gyou),
                      _kuwashikuBotan(k),
                      if (_hirakiKuwashiku.contains(midashi))
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.white24, width: 2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _honbunWidgets(k),
                          ),
                        ),
                    ],
            ),
          ),
      ],
    );
  }

  // 見出しの本文と図(要点のある見出しでは「くわしく」の中に出す。2.1.1)
  List<Widget> _honbunWidgets(SetsumeishoKoumoku k) {
    return [
      for (final String gyou in k.setsu.gyou) _gyouWidget(gyou),
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
            child: Center(child: Image.asset(gazou, fit: BoxFit.contain)),
          ),
      ],
    ];
  }

  // 「くわしく」の開け閉め(行数を添える。2.1.1)
  Widget _kuwashikuBotan(SetsumeishoKoumoku k) {
    final String midashi = k.setsu.midashi;
    final bool hiraki = _hirakiKuwashiku.contains(midashi);
    return InkWell(
      onTap: () {
        setState(() {
          if (hiraki) {
            _hirakiKuwashiku.remove(midashi);
          } else {
            _hirakiKuwashiku.add(midashi);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hiraki ? Icons.expand_more : Icons.chevron_right,
              color: HENSUU.LinkColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'くわしく(${k.setsu.gyou.length}行)',
                style: const TextStyle(
                  color: HENSUU.LinkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: HENSUU.textcolor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 本文の1行
  // 「・」で始まる行は、折り返した2行目以降が「・」の後ろにそろうようにする。
  // 「　・」で始まる行は1段下げる。「・」で始まらない行は、そのままの文として出す
  Widget _gyouWidget(String gyou) {
    double sage = 0;
    String bun = gyou;
    if (bun.startsWith('　・')) {
      sage = 16;
      bun = bun.substring(1);
    }
    if (!bun.startsWith('・')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(bun, style: _honbunStyle),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: sage, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・', style: _honbunStyle),
          Expanded(child: Text(bun.substring(1), style: _honbunStyle)),
        ],
      ),
    );
  }
}
