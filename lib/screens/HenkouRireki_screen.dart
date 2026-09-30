import 'dart:convert'; // LineSplitter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ekiden/constants.dart';

/// 変更履歴画面
/// ToDo.txt(pubspec.yamlのassetsに登録)のうち、箱庭小駅伝SSの部分を表示する
/// ・先頭の「****箱庭小駅伝SS****」の行は表示しない
/// ・「********S*******」の行から後ろは前作(箱庭小駅伝S)の履歴なので表示しない
/// ・「1.7.8　21780」のように行頭が「数字.数字.数字」の行を版の見出しにする
class HenkouRirekiScreen extends StatelessWidget {
  const HenkouRirekiScreen({super.key});

  static final RegExp _hanGyou = RegExp(r'^\d+\.\d+\.\d+');

  Future<List<String>> _yomikomi() async {
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
    return kekka;
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
      body: FutureBuilder<List<String>>(
        future: _yomikomi(),
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
          final List<String> lines = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final String line = lines[index];
              if (line.trim().isEmpty) {
                return const SizedBox(height: 8);
              }
              if (_hanGyou.hasMatch(line.trim())) {
                // 版の見出し
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    line.trim(),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: HENSUU.fontsize_honbun + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    height: 1.4,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
