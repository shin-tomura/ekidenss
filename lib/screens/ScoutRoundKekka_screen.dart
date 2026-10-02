import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスをインポート
import 'package:ekiden/kansuu/scout_com.dart';

/// 新入生スカウト(コンピュータスカウトON)の「ラウンドの結果」画面
/// 全大学のそのラウンドの行動を、大学ごとに一覧で出す(ラウンドは上部で切り替える)
/// 記録はスカウト画面を開いている間だけ持っている(アプリを開き直すと、それより前の記録は消える)
class ScoutRoundKekkaScreen extends StatefulWidget {
  /// ラウンドごとの記録(ラウンドの番号 → 全大学の行動)
  final List<MapEntry<int, List<ComScoutKoudou>>> kiroku;
  final int myUnivid;

  /// 最初に出すラウンドの番号(nullなら最後のラウンド)
  final int? hajimeRound;

  const ScoutRoundKekkaScreen({
    super.key,
    required this.kiroku,
    required this.myUnivid,
    this.hajimeRound,
  });

  @override
  State<ScoutRoundKekkaScreen> createState() => _ScoutRoundKekkaScreenState();
}

class _ScoutRoundKekkaScreenState extends State<ScoutRoundKekkaScreen> {
  int _erabi = 0; // 選んでいるラウンド(kirokuの何番目か)

  @override
  void initState() {
    super.initState();
    _erabi = widget.kiroku.isEmpty ? 0 : widget.kiroku.length - 1;
    if (widget.hajimeRound != null) {
      final int i = widget.kiroku.indexWhere(
        (e) => e.key == widget.hajimeRound,
      );
      if (i >= 0) _erabi = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, UnivData> univs = {
      for (final UnivData u in Hive.box<UnivData>('univBox').values) u.id: u,
    };
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('ラウンドの結果', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: widget.kiroku.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ラウンドの記録がありません。\n(記録はスカウト画面を開いている間だけ残ります。アプリを開き直すと、それより前のラウンドの記録は消えます)',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            )
          : Column(
              children: [
                // ラウンドの切り替え(← ラウンド7 → の1行。ラウンドが多くても場所をとらないように)
                Container(
                  width: double.infinity,
                  color: Colors.grey[900],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: Colors.white,
                        disabledColor: Colors.white24,
                        tooltip: '前のラウンド',
                        onPressed: _erabi > 0
                            ? () => setState(() => _erabi--)
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          'ラウンド${widget.kiroku[_erabi].key}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: Colors.white,
                        disabledColor: Colors.white24,
                        tooltip: '次のラウンド',
                        onPressed: _erabi < widget.kiroku.length - 1
                            ? () => setState(() => _erabi++)
                            : null,
                      ),
                    ],
                  ),
                ),
                Expanded(child: _ichiran(widget.kiroku[_erabi].value, univs)),
              ],
            ),
    );
  }

  /// 大学ごとの一覧(あなたの大学を先頭に、そのあとは大学の順)
  Widget _ichiran(List<ComScoutKoudou> koudou, Map<int, UnivData> univs) {
    final List<ComScoutKoudou> narabi = [
      ...koudou.where((k) => k.univid == widget.myUnivid),
      ...koudou.where((k) => k.univid != widget.myUnivid),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: narabi.length,
      itemBuilder: (context, index) {
        final ComScoutKoudou k = narabi[index];
        final bool jibun = k.univid == widget.myUnivid;
        final bool kakutei =
            k.shurui == comScoutKoudouKousyou &&
            k.seikou &&
            k.kimariUnivid == k.univid;
        final String mei = univs[k.univid]?.name ?? '不明';
        return Card(
          color: jibun ? const Color(0xFF1A1F26) : const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: jibun ? Colors.amber : Colors.white12,
              width: jibun ? 2.0 : 1.0,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 大学名と確定人数(入りきらなければ折り返す)
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      jibun ? '$mei大学(あなたの大学)' : '$mei大学',
                      style: TextStyle(
                        color: jibun ? Colors.amber : HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '確定 ${k.ketteiSuu}/${k.waku}',
                      style: TextStyle(
                        color: HENSUU.textcolor.withOpacity(0.7),
                        fontSize: HENSUU.fontsize_honbun - 2,
                      ),
                    ),
                  ],
                ),
                if (k.riyuu.isNotEmpty)
                  Text(
                    k.riyuu,
                    style: TextStyle(
                      color: HENSUU.textcolor.withOpacity(0.6),
                      fontSize: HENSUU.fontsize_honbun - 2,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  comScoutKoudouBun(k),
                  style: TextStyle(
                    color: kakutei ? Colors.cyanAccent : HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: kakutei ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
