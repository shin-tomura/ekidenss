import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ★追加: Clipboardを利用するため
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';

/// 特定の選手の分析グラフを単独で表示するモーダル画面
class ModalSenshuAnalysisView extends StatelessWidget {
  final int senshuId;

  const ModalSenshuAnalysisView({super.key, required this.senshuId});

  // ★追加: テキストコピー用のメソッド
  Future<void> _copyToClipboard(
    BuildContext context,
    SenshuData senshu,
    UnivData? univ,
  ) async {
    final List<String> parameterNames = [
      '調子',
      'メンタル',
      '集団走(1区)',
      '基本走力',
      '登り',
      '下り',
      'アップダウン',
      '経験',
      'ロード適性',
      'ペース変動',
      '長距離粘り',
      'スパート力',
    ];
    String shareText = "\n※分析データの補足：マイナスは平均よりもタイム短縮の好影響、プラスはタイム悪化の悪影響を表します。\n";
    shareText +=
        '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n';

    StringBuffer sb = StringBuffer();

    sb.writeln(shareText);

    sb.writeln('【レース分析詳細】');
    sb.writeln('${senshu.name}(${senshu.gakunen}年) ${univ?.name ?? '不明'}');

    if (senshu.racechuukakuseiflag == 0) {
      sb.writeln('[分析] データなし');
    } else {
      sb.write('[分析] ');
      for (int i = 0; i < 12; i++) {
        int shift = i * 4;
        int storedValue = (senshu.racechuukakuseiflag >> shift) & 0xF;
        int score = storedValue - 7;
        String sign = score > 0 ? '+' : '';
        sb.write('${parameterNames[i]}:$sign$score ');
      }
      sb.writeln('');
    }

    sb.writeln('#箱庭小駅伝SS');

    await Clipboard.setData(ClipboardData(text: sb.toString()));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分析データをコピーしました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // データボックスの取得
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    // IDから選手データを検索
    SenshuData? senshu;
    try {
      senshu = senshudataBox.values.firstWhere((s) => s.id == senshuId);
    } catch (e) {
      senshu = null;
    }

    if (senshu == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text('データエラー', style: TextStyle(color: Colors.white)),
          backgroundColor: HENSUU.backgroundcolor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            '選手データが見つかりませんでした。',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // 大学データを検索
    UnivData? univ;
    try {
      univ = univdataBox.values.firstWhere((u) => u.id == senshu!.univid);
    } catch (e) {
      univ = null;
    }

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          'レース分析詳細',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        // ★追加: コピーボタンのアクション
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () => _copyToClipboard(context, senshu!, univ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 選手情報ヘッダー（1行表示 ＆ 縦の余白をさらに削減） ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ), // 余白を減らす
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: const Border(
                bottom: BorderSide(color: Colors.white24, width: 1.0),
              ),
            ),
            // 文字サイズ設定が大きくてもエラーにならない安全装置
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    senshu.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // 標準サイズを少し下げてスッキリさせる
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${univ?.name ?? '不明'} (${senshu.gakunen}年)',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- グラフ表示エリア ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ), // 上下余白を詰める
              child: Column(
                children: [
                  // グラフ本体の呼び出し
                  AnalysisGraphLargeWidget(
                    compressedFlag: senshu.racechuukakuseiflag,
                  ),

                  const SizedBox(height: 16), // スペースを削る
                  // 説明文
                  Container(
                    padding: const EdgeInsets.all(10.0), // 内側の余白も少し詰める
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      '【分析データの見方】\n'
                      'マイナス（緑）は平均よりもタイム短縮の好影響、'
                      'プラス（赤）はタイム悪化の悪影響を表します。\n'
                      '※直前のレースでの相対的な影響度です。±7に達している項目は、他と比べて極めて際立った結果を出したことを意味します。\n'
                      '※見える化していない能力に関する補正も可視化されます。また、正月駅伝予選のメンタル(指示補正)や集団走補正は可視化されません。',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11, // フォントを少しだけ小さく
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // スクロール最下部のための少しの余白
                ],
              ),
            ),
          ),
          // ※「閉じる」ボタンのブロックはまるごと削除しました
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// ★ 単独画面用の大型グラフWidget（StatelessWidgetとして独立）
// -------------------------------------------------------------------
class AnalysisGraphLargeWidget extends StatelessWidget {
  final int compressedFlag;

  const AnalysisGraphLargeWidget({super.key, required this.compressedFlag});

  // 4ビット圧縮の解凍メソッド (-7〜+7)
  int _getImpactScore(int flag, int type) {
    if (flag == 0) return 0;
    int shift = type * 4;
    int storedValue = (flag >> shift) & 0xF;
    return storedValue - 7;
  }

  @override
  Widget build(BuildContext context) {
    if (compressedFlag == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text(
          '分析データがありません',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    final List<String> parameterNames = [
      '調子',
      'メンタル',
      '集団走(1区)',
      '基本走力',
      '登り',
      '下り',
      'アップダウン',
      '経験',
      'ロード適性',
      'ペース変動',
      '長距離粘り',
      'スパート力',
    ];

    return Column(
      children: List.generate(12, (index) {
        int score = _getImpactScore(compressedFlag, index);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0), // ★ 行間を大幅に詰める
          child: Row(
            children: [
              // 項目名
              SizedBox(
                width: 85, // 少し狭める
                child: Text(
                  parameterNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // フォントサイズを少し小さく
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // グラフ描画エリア
              Expanded(
                child: Row(
                  children: [
                    // マイナス側 (左に伸びる緑のバー)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: score < 0
                            ? FractionallySizedBox(
                                widthFactor: (score.abs() / 7.0).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Container(
                                  height: 8, // ★ バーの太さを細くする（12 → 8）
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),

                    // センターライン
                    Container(
                      width: 2,
                      height: 14, // センターラインも短くする
                      color: Colors.white54,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                    ),

                    // プラス側 (右に伸びる赤のバー)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: score > 0
                            ? FractionallySizedBox(
                                widthFactor: (score / 7.0).clamp(0.0, 1.0),
                                child: Container(
                                  height: 8, // ★ バーの太さを細くする（12 → 8）
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),

              // スコア数値表示
              SizedBox(
                width: 35, // 少し狭める
                child: Text(
                  score > 0 ? '+$score' : '$score',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: score < 0
                        ? Colors.greenAccent
                        : (score > 0 ? Colors.redAccent : Colors.white),
                    fontSize: 14, // フォントサイズを少し小さく
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
