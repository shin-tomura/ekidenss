import 'dart:convert'; // LineSplitter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ekiden/constants.dart';

/// 変更履歴画面
/// ToDo.txt(pubspec.yamlのassetsに登録)のうち、箱庭小駅伝SSの部分を表示する
/// ・先頭の「****箱庭小駅伝SS****」の行は表示しない
/// ・「********S*******」の行から後ろは前作(箱庭小駅伝S)の履歴なので表示しない
/// ・「1.7.8　21780」のように行頭が「数字.数字.数字」の行を版の見出しにする
/// ・「概要」と「詳細」を切り替えられる(1.8.2)
///   概要: 各項目のかっこの中(「」の中のかっこは残す)と、最初の「。」より後ろを省いて表示する。
///         省いた部分がある項目には▼を付け、押すとその項目だけ全文を表示する
///   詳細: 今まで通り、すべての文を表示する
///   初期表示は概要(選んだ表示は保存しない)
class HenkouRirekiScreen extends StatefulWidget {
  const HenkouRirekiScreen({super.key});

  @override
  State<HenkouRirekiScreen> createState() => _HenkouRirekiScreenState();
}

/// 変更履歴の1行
class _RirekiGyou {
  /// 元の行
  final String text;

  /// 版の見出しか
  final bool han;

  /// 概要(省いた部分がない行や、空行・見出しはnull)
  final String? gaiyou;

  const _RirekiGyou(this.text, {this.han = false, this.gaiyou});

  bool get kuuhaku => text.trim().isEmpty;
}

class _HenkouRirekiScreenState extends State<HenkouRirekiScreen> {
  static final RegExp _hanGyou = RegExp(r'^\d+\.\d+\.\d+');

  late final Future<List<_RirekiGyou>> _yomikomiFuture;

  /// 概要を表示しているか(初期表示は概要)
  bool _gaiyouHyouji = true;

  /// 概要の表示で、全文を開いている行の番号
  final Set<int> _hiraitaGyou = {};

  @override
  void initState() {
    super.initState();
    // 切り替えのたびに読み直さないよう、最初に1回だけ読み込む
    _yomikomiFuture = _yomikomi();
  }

  Future<List<_RirekiGyou>> _yomikomi() async {
    final String text = await rootBundle.loadString('ToDo.txt');
    final List<String> kekka = [];
    for (final String line in const LineSplitter().convert(text)) {
      final String t = line.trim();
      if (t == '********S*******') break; // ここから前作の履歴
      if (t.startsWith('*')) continue; // 先頭のタイトル行
      kekka.add(line);
    }
    // 前後の空行を削る
    while (kekka.isNotEmpty && kekka.first.trim().isEmpty) {
      kekka.removeAt(0);
    }
    while (kekka.isNotEmpty && kekka.last.trim().isEmpty) {
      kekka.removeLast();
    }
    return [
      for (final String line in kekka)
        if (line.trim().isEmpty)
          _RirekiGyou(line)
        else if (_hanGyou.hasMatch(line.trim()))
          _RirekiGyou(line, han: true)
        else
          _RirekiGyou(line, gaiyou: _gaiyouTsukuru(line)),
    ];
  }

  /// 項目の概要を作る。省いた部分がなければnull
  /// ・かっこ「()」「（）」の中を省く(「」の中のかっこは、画面の名前などなので残す)
  /// ・かっこと「」の外にある最初の「。」より後ろを省く
  static String? _gaiyouTsukuru(String line) {
    final String moto = line.trim();
    final StringBuffer buf = StringBuffer();
    int kakko = 0; // かっこの深さ
    int kagi = 0; // 「」の深さ
    for (final int rune in moto.runes) {
      final String c = String.fromCharCode(rune);
      if (c == '「') kagi++;
      if (c == '」' && kagi > 0) kagi--;
      if (kagi == 0) {
        if (c == '(' || c == '（') {
          kakko++;
          continue;
        }
        if (c == ')' || c == '）') {
          if (kakko > 0) kakko--;
          continue;
        }
        if (kakko == 0 && c == '。') break;
      }
      if (kakko == 0) buf.write(c);
    }
    final String gaiyou = buf.toString().trim();
    // 中身がなくなってしまう場合は、全文を出す
    if (gaiyou.replaceAll('・', '').trim().isEmpty) return null;
    // 最後の「。」だけの違いなら、省いた部分はないとみなす
    final String motoMaruNashi = moto.endsWith('。')
        ? moto.substring(0, moto.length - 1)
        : moto;
    if (gaiyou == motoMaruNashi) return null;
    return gaiyou;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('変更履歴', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<List<_RirekiGyou>>(
        future: _yomikomiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                '変更履歴を読み込めませんでした',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            );
          }
          final List<_RirekiGyou> gyouList = snapshot.data!;
          return Column(
            children: [
              _kirikae(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: gyouList.length,
                  itemBuilder: (context, index) =>
                      _gyouWidget(gyouList[index], index),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 概要・詳細の切り替え
  Widget _kirikae() {
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip('概要', _gaiyouHyouji, () {
                setState(() => _gaiyouHyouji = true);
              }),
              _chip('詳細', !_gaiyouHyouji, () {
                setState(() => _gaiyouHyouji = false);
              }),
            ],
          ),
          if (_gaiyouHyouji)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '▼の付いた項目を押すと、その項目の全文を表示します。',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool erabi, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: erabi,
      onSelected: (selected) {
        if (selected) onTap();
      },
      selectedColor: Colors.orange.shade700,
      backgroundColor: Colors.grey.shade800,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  /// 1行分の表示
  Widget _gyouWidget(_RirekiGyou gyou, int index) {
    if (gyou.kuuhaku) {
      return const SizedBox(height: 8);
    }
    if (gyou.han) {
      // 版の見出し
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          gyou.text.trim(),
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: HENSUU.fontsize_honbun + 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    const TextStyle honbunStyle = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun,
      height: 1.4,
    );
    final String? gaiyou = gyou.gaiyou;
    if (!_gaiyouHyouji || gaiyou == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(gyou.text, style: honbunStyle),
      );
    }
    // 概要の表示で、省いた部分がある項目(押すと全文を開く・閉じる)
    final bool hiraita = _hiraitaGyou.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (hiraita) {
            _hiraitaGyou.remove(index);
          } else {
            _hiraitaGyou.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: hiraita ? gyou.text : gaiyou),
              TextSpan(
                text: hiraita ? ' ▲' : ' ▼',
                style: const TextStyle(color: Colors.cyanAccent),
              ),
            ],
          ),
          style: honbunStyle,
        ),
      ),
    );
  }
}
