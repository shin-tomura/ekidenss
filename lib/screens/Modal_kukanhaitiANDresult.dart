import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard用
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:share_plus/share_plus.dart';

// --------------------------------------------------
// ★ 追加: 表示モードを管理する列挙型 ★
// --------------------------------------------------
enum ViewMode { time, description, analysis }

class ModalKukanHaitiResultView extends StatefulWidget {
  const ModalKukanHaitiResultView({super.key});

  @override
  State<ModalKukanHaitiResultView> createState() =>
      _ModalKukanHaitiResultView();
}

class _ModalKukanHaitiResultView extends State<ModalKukanHaitiResultView> {
  int? _selectedUnivId;

  // ★ 変更: bool _showFullDetail から列挙型に変更 ★
  ViewMode _viewMode = ViewMode.time;

  // ★ 追加: 分析項目の名称リスト ★
  final List<String> _parameterNames = [
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

  // ★ 追加: 圧縮フラグから影響度（-7〜+7）を取り出すメソッド（4ビット版） ★
  int _getImpactScore(int compressedFlag, int type) {
    if (compressedFlag == 0) return 0;
    int shift = type * 4;
    int storedValue = (compressedFlag >> shift) & 0xF;
    return storedValue - 7;
  }

  String _formatDoubleToFixed(double value, int fractionDigits) {
    return value.toStringAsFixed(fractionDigits);
  }

  // --- ★ 変更: テキスト情報生成ロジック（3モード対応） ---
  String _generateResultText({required ViewMode mode}) {
    final gBox = Hive.box<Ghensuu>('ghensuuBox');
    final sBox = Hive.box<SenshuData>('senshuBox');
    final uBox = Hive.box<UnivData>('univBox');
    final kBox = Hive.box<KantokuData>('kantokuBox');

    final currentGhensuu = gBox.getAt(0)!;
    final univ = uBox.values.firstWhere((u) => u.id == _selectedUnivId);
    final kantoku = kBox.get('KantokuData');
    final raceIdx = currentGhensuu.hyojiracebangou;
    final kukanCount = currentGhensuu.kukansuu_taikaigoto[raceIdx];
    final allSenshus = sBox.values
        .where((s) => s.univid == _selectedUnivId)
        .toList();

    StringBuffer sb = StringBuffer();
    String modeStr = mode == ViewMode.analysis
        ? "分析版"
        : (mode == ViewMode.description ? "詳細版" : "簡易版");
    String shareText = "";
    if (mode == ViewMode.analysis) {
      shareText +=
          '※分析データの補足：各項目が走破タイムに与えた影響度を相対値で示しています。マイナスの数値は平均よりタイムを短縮させた好影響、プラスの数値はタイムを悪化させた悪影響を表します。\n※区間記録比や学内記録比のタイムがプラスの場合は新記録に届かなかったことを表し。マイナスの場合には新記録を表します。ただし、速報値なので誤差がありますことをご了承ください\n';
    } else {
      shareText +=
          '※区間記録比や学内記録比のタイムがプラスの場合は新記録に届かなかったことを表し、マイナスの場合には新記録を表します。ただし、速報値なので誤差がありますことをご了承ください\n';
    }
    shareText +=
        '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n';

    sb.writeln(shareText);
    sb.writeln('【${univ.name}】区間成績（$modeStr）');
    sb.writeln('-----------------------------------');

    for (int i = 0; i < kukanCount; i++) {
      final target = allSenshus
          .where((s) => s.entrykukan_race[raceIdx][s.gakunen - 1] == i)
          .toList();

      // ★ 追加: 正月駅伝予選(raceIdx == 4)の場合のみ順位昇順でソート
      if (raceIdx == 4) {
        target.sort(
          (a, b) => a.kukanjuni_race[raceIdx][a.gakunen - 1].compareTo(
            b.kukanjuni_race[raceIdx][b.gakunen - 1],
          ),
        );
      }

      for (var s in target) {
        final int gIdx = s.gakunen - 1;
        final double time = s.kukantime_race[raceIdx][gIdx];
        final int rank = s.kukanjuni_race[raceIdx][gIdx] + 1;
        String kukanLabel = "${i + 1}${raceIdx == 3 ? "組" : "区"}";
        if (currentGhensuu.hyojiracebangou == 4) {
          kukanLabel = "";
        }

        sb.writeln('$kukanLabel ${s.name} (${s.gakunen}年)');

        sb.writeln('  タイム: ${TimeDate.timeToFunByouString(time)} ($rank位)');

        // 記録比の追加
        if (currentGhensuu.hyojiracebangou != 3 &&
            currentGhensuu.hyojiracebangou != 4) {
          if (kantoku != null && time < TEISUU.DEFAULTTIME) {
            if (i < 10) {
              double d = time - kantoku.yobiint4[i].toDouble();
              if ((d <= 0 || rank == 1) && d > -36000)
                sb.writeln('  区間記録比: ${_formatTimeDiff(d)}');
            }
            if (s.univid == currentGhensuu.MYunivid && i + 10 < 20) {
              double d = time - kantoku.yobiint4[i + 10].toDouble();
              if (d > -36000) sb.writeln('  学内記録比: ${_formatTimeDiff(d)}');
            }
          }

          // 新記録フラグ
          if (s.chokuzentaikai_zentaikukansinflag == 1) sb.writeln('  *区間新記録');
          if (s.chokuzentaikai_zentaikukansinflag == 0 &&
              s.chokuzentaikai_univkukansinflag == 1)
            sb.writeln('  *学内新記録');
        }

        // ★ 追加: モード別の出力
        if (mode == ViewMode.description && s.string_racesetumei.isNotEmpty) {
          sb.writeln('  備考: ${s.string_racesetumei}');
        } else if (mode == ViewMode.analysis) {
          if (s.racechuukakuseiflag == 0) {
            sb.writeln('  分析: データなし');
          } else {
            sb.write('  分析: ');
            for (int j = 0; j < 12; j++) {
              int score = _getImpactScore(s.racechuukakuseiflag, j);
              String sign = score > 0 ? '+' : '';
              sb.write('${_parameterNames[j]}:$sign$score ');
            }
            sb.writeln('');
          }
        }
        sb.writeln('');
      }
    }

    sb.writeln('#箱庭小駅伝SS');

    return sb.toString();
  }

  String _formatTimeDiff(double d) {
    int s = d.abs().round();
    return "${d < 0 ? "-" : "+"}${s < 60 ? "${s}秒" : "${(s / 60).floor()}分${s % 60}秒"}";
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
    final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final KantokuData? kantoku = kantokuBox.get('KantokuData');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, gBox, _) {
        final Ghensuu? currentGhensuu = gBox.getAt(0);
        if (currentGhensuu == null)
          return const Scaffold(body: Center(child: Text("データエラー")));
        if (_selectedUnivId == null) _selectedUnivId = currentGhensuu.MYunivid;

        final List<UnivData> idjunAllUnivs = univdataBox.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        if (idjunAllUnivs[_selectedUnivId!].taikaientryflag[currentGhensuu
                .hyojiracebangou] !=
            1) {
          for (int i = 0; i < idjunAllUnivs.length; i++) {
            if (idjunAllUnivs[i].taikaientryflag[currentGhensuu
                    .hyojiracebangou] ==
                1) {
              _selectedUnivId = i;
              break;
            }
          }
        }
        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, uBox, _) {
            final List<UnivData> entryUnivs =
                uBox.values
                    .where(
                      (u) =>
                          u.taikaientryflag[currentGhensuu.hyojiracebangou] ==
                          1,
                    )
                    .toList()
                  ..sort((a, b) => a.id.compareTo(b.id));

            return ValueListenableBuilder<Box<SenshuData>>(
              valueListenable: senshudataBox.listenable(),
              builder: (context, sBox, _) {
                final displaySenshuData = sBox.values
                    .where((s) => s.univid == _selectedUnivId)
                    .toList();

                return Scaffold(
                  backgroundColor: HENSUU.backgroundcolor,
                  appBar: AppBar(
                    title: const Text(
                      '区間成績確認',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () => _showExportMenu(context),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      _buildUnivSelector(entryUnivs),
                      _buildDisplayModeToggle(),
                      const Divider(color: Colors.white24, height: 1),
                      Expanded(
                        child: _buildMainList(
                          currentGhensuu,
                          displaySenshuData,
                          kantoku,
                        ),
                      ),
                      _buildBottomBar(context),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- UI Parts ---

  // ★ 変更: 3つのボタンが並ぶUIに変更 ★
  Widget _buildDisplayModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _viewMode = ViewMode.time),
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == ViewMode.time
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('簡易表示', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _viewMode = ViewMode.description),
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == ViewMode.description
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('詳細表示', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => _viewMode = ViewMode.analysis),
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == ViewMode.analysis
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('分析', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnivSelector(List<UnivData> entryUnivs) {
    if (entryUnivs.isEmpty) return const SizedBox.shrink();
    if (!entryUnivs.any((u) => u.id == _selectedUnivId)) {
      _selectedUnivId = entryUnivs.first.id;
    }
    final idx = entryUnivs.indexWhere((u) => u.id == _selectedUnivId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.cyanAccent,
              size: 20,
            ),
            onPressed: () => setState(
              () => _selectedUnivId =
                  entryUnivs[idx > 0 ? idx - 1 : entryUnivs.length - 1].id,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedUnivId,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  items: entryUnivs
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedUnivId = val),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.cyanAccent,
              size: 20,
            ),
            onPressed: () => setState(
              () => _selectedUnivId =
                  entryUnivs[idx < entryUnivs.length - 1 ? idx + 1 : 0].id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainList(
    Ghensuu gh,
    List<SenshuData> senshus,
    KantokuData? kantoku,
  ) {
    final int raceIdx = gh.hyojiracebangou;
    final int kukanCount = gh.kukansuu_taikaigoto[raceIdx];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      // ★ 変更: 分析モードの時は末尾に説明文を追加するため要素数を+1
      itemCount: kukanCount + (_viewMode == ViewMode.analysis ? 1 : 0),
      itemBuilder: (context, i) {
        // ★ 追加: リストの末尾に分析データの見方を表示
        if (_viewMode == ViewMode.analysis && i == kukanCount) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: const Text(
              '【分析データの見方】\nマイナスの数値（緑）は平均よりタイムを短縮させた好影響を、プラスの数値（赤）はタイムを悪化させた悪影響を表しています。',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          );
        }

        final target = senshus
            .where((s) => s.entrykukan_race[raceIdx][s.gakunen - 1] == i)
            .toList();

        // ★ 追加: 正月駅伝予選(raceIdx == 4)の場合のみ順位昇順でソート
        if (raceIdx == 4) {
          target.sort(
            (a, b) => a.kukanjuni_race[raceIdx][a.gakunen - 1].compareTo(
              b.kukanjuni_race[raceIdx][b.gakunen - 1],
            ),
          );
        }

        if (target.isEmpty) return const SizedBox.shrink();
        return Column(
          children: target
              .map((s) => _buildSenshuCard(gh, i, s, kantoku))
              .toList(),
        );
      },
    );
  }

  Widget _buildSenshuCard(
    Ghensuu gh,
    int kIdx,
    SenshuData s,
    KantokuData? kantoku,
  ) {
    return Card(
      color: Colors.white.withOpacity(0.09),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true, // パネルを開いた状態で表示
        title: Row(
          children: [
            if (gh.hyojiracebangou != 4)
              Text(
                "${kIdx + 1}${gh.hyojiracebangou == 3 ? "組" : "区"}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "${s.gakunen}年",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white24),
          // ★ 変更: _viewMode をそのまま渡す
          _buildResultSection(gh, s, kIdx, kantoku, mode: _viewMode),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showSenshuDetail(s.id),
              child: Text(
                "詳細プロフ",
                style: TextStyle(color: HENSUU.LinkColor, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(
    Ghensuu gh,
    SenshuData s,
    int kIdx,
    KantokuData? kantoku, {
    required ViewMode mode,
  }) {
    final int gIdx = s.gakunen - 1;
    final double time = s.kukantime_race[gh.hyojiracebangou][gIdx];
    final int rank = s.kukanjuni_race[gh.hyojiracebangou][gIdx] + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$rank位",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              TimeDate.timeToFunByouString(time),
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (kantoku != null)
          ..._buildDiffWidgets(time, kIdx, rank - 1, s.univid, gh, kantoku),
        if (gh.hyojiracebangou != 3 && gh.hyojiracebangou != 4)
          if (s.chokuzentaikai_zentaikukansinflag == 1)
            const Text(
              "*区間新記録",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        if (gh.hyojiracebangou != 3 && gh.hyojiracebangou != 4)
          if (s.chokuzentaikai_zentaikukansinflag == 0 &&
              s.chokuzentaikai_univkukansinflag == 1)
            const Text(
              "*学内新記録",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

        // ★ 変更: モード別の表示切り替え
        if (mode == ViewMode.description && s.string_racesetumei.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.string_racesetumei,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          )
        else if (mode == ViewMode.analysis)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildAnalysisGraph(s.racechuukakuseiflag),
          ),
      ],
    );
  }

  // ★ 追加: 分析用のグラフを描画するウィジェット ★
  Widget _buildAnalysisGraph(int compressedFlag) {
    if (compressedFlag == 0) {
      return const Text(
        '分析データがありません',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return Column(
      children: List.generate(12, (index) {
        int score = _getImpactScore(compressedFlag, index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              // 項目名
              SizedBox(
                width: 75,
                child: Text(
                  _parameterNames[index],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11, // パネル内に収まるように小さめ
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
                                  height: 6,
                                  color: Colors.greenAccent,
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),
                    // センターライン
                    Container(width: 2, height: 14, color: Colors.white38),
                    // プラス側 (右に伸びる赤のバー)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: score > 0
                            ? FractionallySizedBox(
                                widthFactor: (score / 7.0).clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  color: Colors.redAccent,
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
                width: 40,
                child: Text(
                  score > 0 ? '+$score' : '$score',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: score < 0
                        ? Colors.greenAccent
                        : (score > 0 ? Colors.redAccent : Colors.white70),
                    fontSize: 12,
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

  List<Widget> _buildDiffWidgets(
    double time,
    int kIdx,
    int rIdx,
    int uId,
    Ghensuu gh,
    KantokuData kantoku,
  ) {
    List<Widget> list = [];
    if (time >= TEISUU.DEFAULTTIME) return list;
    if (gh.hyojiracebangou != 3 && gh.hyojiracebangou != 4) {
      if (kIdx < 10) {
        double d = time - kantoku.yobiint4[kIdx].toDouble();
        if ((d <= 0 || rIdx == 0) && d > -36000)
          list.add(
            Text(
              "区間記録比: ${_formatTimeDiff(d)}",
              style: TextStyle(
                color: d < 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          );
      }
      if (uId == gh.MYunivid && kIdx + 10 < 20) {
        double d = time - kantoku.yobiint4[kIdx + 10].toDouble();
        if (d > -36000)
          list.add(
            Text(
              "学内記録比: ${_formatTimeDiff(d)}",
              style: TextStyle(
                color: d < 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          );
      }
    }
    return list;
  }

  void _showSenshuDetail(int id) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '詳細',
      pageBuilder: (_, __, ___) => ModalSenshuDetailView(senshuId: id),
    );
  }

  // --- ★ 変更: メニュー表示（エラー防止対策済み） ---
  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ★ 【重要】画面半分の高さ制限を解除
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          // ★ 【重要】ColumnではなくListViewを使うことで、はみ出してもスクロールで安全に表示
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: [
              const Center(
                child: Text(
                  "成績データの出力",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _exportListTile(context, Icons.copy, "簡易版をコピー", () {
                Clipboard.setData(
                  ClipboardData(text: _generateResultText(mode: ViewMode.time)),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("簡易版をコピーしました")));
              }),
              _exportListTile(context, Icons.share, "簡易版を共有", () {
                Share.share(_generateResultText(mode: ViewMode.time));
              }),
              const Divider(color: Colors.white12),
              _exportListTile(context, Icons.content_copy, "詳細版をコピー", () {
                Clipboard.setData(
                  ClipboardData(
                    text: _generateResultText(mode: ViewMode.description),
                  ),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("詳細版をコピーしました")));
              }),
              _exportListTile(context, Icons.description, "詳細版を共有", () {
                Share.share(_generateResultText(mode: ViewMode.description));
              }),
              // ★ 追加: 分析版のコピー・共有メニュー
              const Divider(color: Colors.white12),
              _exportListTile(context, Icons.analytics, "分析版をコピー", () {
                Clipboard.setData(
                  ClipboardData(
                    text: _generateResultText(mode: ViewMode.analysis),
                  ),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("分析版をコピーしました")));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("閉じる"),
      ),
    );
  }
}
