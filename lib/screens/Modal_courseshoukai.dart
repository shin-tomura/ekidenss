import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

// 小数点以下の桁数を指定して文字列に変換するヘルパー関数
String _formatDoubleToFixed(double value, int fractionDigits) {
  return value.toStringAsFixed(fractionDigits);
}

class ModalCourseshoukaiView extends StatefulWidget {
  final int racebangou;
  const ModalCourseshoukaiView({super.key, required this.racebangou});

  @override
  State<ModalCourseshoukaiView> createState() => _ModalCourseshoukaiViewState();
}

class _ModalCourseshoukaiViewState extends State<ModalCourseshoukaiView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  // 表示モードの切り替えフラグ (true: グラフ, false: 詳細数値)
  bool _showGraphMode = true;

  // 明るい色の定義
  final Color upColor = const Color.fromARGB(255, 255, 82, 238); // 明るい赤
  final Color downColor = const Color(0xFF00E5FF); // 明るい水色

  String _getRaceTitle(int racebangou, List<UnivData> sortedUnivData) {
    switch (racebangou) {
      case 0:
        return "10月駅伝";
      case 1:
        return "11月駅伝";
      case 2:
        return "正月駅伝";
      case 3:
        return "11月駅伝予選";
      case 4:
        return "正月駅伝予選";
      case 5:
        if (sortedUnivData.isNotEmpty) return sortedUnivData[0].name_tanshuku;
        return "特別レース";
      default:
        return "区間コース確認";
    }
  }

  // 【追加】特定の区間の情報をクリップボードへコピーする処理
  Future<void> _copySingleSectionToClipboard(
    String raceTitle,
    Ghensuu currentGhensuu,
    int index,
  ) async {
    final StringBuffer buffer = StringBuffer();

    // データの取得
    final double dist =
        currentGhensuu.kyori_taikai_kukangoto[widget.racebangou][index];
    final double nDist = currentGhensuu
        .kyoriwariainobori_taikai_kukangoto[widget.racebangou][index];
    final double kDist = currentGhensuu
        .kyoriwariaikudari_taikai_kukangoto[widget.racebangou][index];
    final double nKoubai = currentGhensuu
        .heikinkoubainobori_taikai_kukangoto[widget.racebangou][index];
    final double kKoubai = currentGhensuu
        .heikinkoubaikudari_taikai_kukangoto[widget.racebangou][index];
    final int updown = currentGhensuu
        .noborikudarikirikaekaisuu_taikai_kukangoto[widget.racebangou][index];

    // 指数の計算
    int nIndexInt = (nDist * nKoubai.abs() * 10000).round();
    int kIndexInt = (kDist * kKoubai.abs() * 10000).round();

    // テキスト生成
    buffer.writeln("【$raceTitle ${index + 1}区 データ】");
    buffer.writeln("距離: ${_formatDoubleToFixed(dist, 0)}m");
    buffer.writeln(
      "登り距離割合: ${_formatDoubleToFixed(nDist * 100, 1)}% (平均勾配 ${_formatDoubleToFixed(nKoubai.abs(), 3)}) [登り指数:$nIndexInt]",
    );
    buffer.writeln(
      "下り距離割合: ${_formatDoubleToFixed(kDist * 100, 1)}% (平均勾配 ${_formatDoubleToFixed(kKoubai.abs(), 3)}) [下り指数:$kIndexInt]",
    );
    buffer.writeln("UD: $updown回");

    // 指数に関する説明文を追加
    buffer.writeln("----------------");
    buffer.writeln("※数値の意味");
    buffer.writeln("・登り指数＝ 登り距離割合 × 平均勾配(絶対値) × 10000");
    buffer.writeln("・下り指数＝ 下り距離割合 × 平均勾配(絶対値) × 10000");

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${index + 1}区の情報をコピーしました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 全区間の情報をまとめてクリップボードへコピーする処理
  Future<void> _copyAllSectionsToClipboard(
    String raceTitle,
    Ghensuu currentGhensuu,
  ) async {
    int kukanCount =
        (widget.racebangou >= 0 && widget.racebangou <= 3) ||
            widget.racebangou == 5
        ? currentGhensuu.kukansuu_taikaigoto[widget.racebangou]
        : (widget.racebangou == 4 ? 1 : 0);

    if (kukanCount == 0) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("【$raceTitle コース詳細データ】");
    buffer.writeln("");

    for (int i = 0; i < kukanCount; i++) {
      final double dist =
          currentGhensuu.kyori_taikai_kukangoto[widget.racebangou][i];
      final double nDist = currentGhensuu
          .kyoriwariainobori_taikai_kukangoto[widget.racebangou][i];
      final double kDist = currentGhensuu
          .kyoriwariaikudari_taikai_kukangoto[widget.racebangou][i];
      final double nKoubai = currentGhensuu
          .heikinkoubainobori_taikai_kukangoto[widget.racebangou][i];
      final double kKoubai = currentGhensuu
          .heikinkoubaikudari_taikai_kukangoto[widget.racebangou][i];
      final int updown = currentGhensuu
          .noborikudarikirikaekaisuu_taikai_kukangoto[widget.racebangou][i];

      // 指数の計算
      int nIndexInt = (nDist * nKoubai.abs() * 10000).round();
      int kIndexInt = (kDist * kKoubai.abs() * 10000).round();
      if (widget.racebangou == 3) {
        buffer.writeln("[${i + 1}組]");
      } else if (widget.racebangou == 4) {
        buffer.writeln("[全員が同じコースを一斉に走る]");
      } else {
        buffer.writeln("[${i + 1}区]");
      }

      buffer.writeln("距離: ${_formatDoubleToFixed(dist, 0)}m");
      buffer.writeln(
        "登り距離割合: ${_formatDoubleToFixed(nDist * 100, 1)}% (平均勾配 ${_formatDoubleToFixed(nKoubai.abs(), 3)}) [登り指数:$nIndexInt]",
      );
      buffer.writeln(
        "下り距離割合: ${_formatDoubleToFixed(kDist * 100, 1)}% (平均勾配 ${_formatDoubleToFixed(kKoubai.abs(), 3)}) [下り指数:$kIndexInt]",
      );
      buffer.writeln("アップダウン回数: $updown回");
      buffer.writeln("");
    }

    // 指数に関する説明文を追加
    buffer.writeln("----------------");
    buffer.writeln("※数値の意味");
    buffer.writeln("・登り指数＝ 登り距離割合 × 平均勾配(絶対値) × 10000");
    buffer.writeln("・下り指数＝ 下り距離割合 × 平均勾配(絶対値) × 10000");

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('全区間のコース情報をコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportAsImage(String raceTitle, Ghensuu currentGhensuu) async {
    setState(() => _isExporting = true);
    try {
      int kukanCount = (widget.racebangou == 3 || widget.racebangou == 4)
          ? 1
          : currentGhensuu.kukansuu_taikaigoto[widget.racebangou];

      int rows = (kukanCount + 3) ~/ 4;
      if (rows == 0) rows = 1;

      double canvasWidth = 1150.0;
      double headerHeight = 160.0;
      double rowHeight = _showGraphMode ? 170.0 : 250.0;
      double footerHeight = 160.0;
      double finalImageHeight =
          headerHeight + (rows * rowHeight) + footerHeight;

      Widget captureWidget = Container(
        width: canvasWidth,
        height: finalImageHeight,
        padding: const EdgeInsets.all(40),
        color: HENSUU.backgroundcolor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Profile: $raceTitle (${_showGraphMode ? "グラフ表示" : "数値表示"})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white54, thickness: 2),
            const SizedBox(height: 20),
            _buildMainContent(currentGhensuu, raceTitle, isForImage: true),
            const Spacer(),
            Text(
              _showGraphMode
                  ? '※登り下り指数：距離割合 × 平均勾配(絶対値) × 10000。太いバーほど勾配がきついことを示します。UDはアップダウン回数です。'
                  : '※アップダウン：コース内の主な起伏の回数です。',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '----- Generated by 箱庭小駅伝SS -----',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      );

      final image = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(child: captureWidget),
          ),
        ),
        targetSize: Size(canvasWidth, finalImageHeight),
        delay: const Duration(milliseconds: 300),
      );

      final directory = await getTemporaryDirectory();
      final File file = File(
        '${directory.path}/course_profile_${widget.racebangou}.png',
      );
      await file.writeAsBytes(image!);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$raceTitle コース詳細 #箱庭小駅伝SS',
        ),
      );
    } catch (e) {
      debugPrint('画像出力エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- グラフ表示ウィジェット (最大勾配0.1基準) ---
  Widget _buildIndexGraph(
    double nDist,
    double kDist,
    double nKoubai,
    double kKoubai,
    int updown,
    bool isForImage,
  ) {
    double heitanDist = (1.0 - nDist - kDist).clamp(0.0, 1.0);
    double absNKoubai = nKoubai.abs();
    double absKKoubai = kKoubai.abs();

    int nIndexInt = (nDist * absNKoubai * 10000).round();
    int kIndexInt = (kDist * absKKoubai * 10000).round();

    // 最大勾配 0.1 で最大太さ 18.0
    double nThickness = (math.sqrt(absNKoubai / 0.1) * 18.0).clamp(2.0, 18.0);
    double kThickness = (math.sqrt(absKKoubai / 0.1) * 18.0).clamp(2.0, 18.0);

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          height: isForImage ? 36 : 30,
          alignment: Alignment.center,
          child: Row(
            children: [
              if (nDist > 0)
                Expanded(
                  flex: (nDist * 100).toInt(),
                  child: Container(
                    height: nThickness,
                    decoration: BoxDecoration(
                      color: upColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              if (heitanDist > 0)
                Expanded(
                  flex: (heitanDist * 100).toInt(),
                  child: Container(
                    height: 2,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              if (kDist > 0)
                Expanded(
                  flex: (kDist * 100).toInt(),
                  child: Container(
                    height: kThickness,
                    decoration: BoxDecoration(
                      color: downColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "登り指: $nIndexInt",
              style: TextStyle(
                color: upColor,
                fontSize: isForImage ? 13 : 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              "UD: $updown回",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              "下り指: $kIndexInt",
              style: TextStyle(
                color: downColor,
                fontSize: isForImage ? 13 : 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 数値詳細表示ウィジェット ---
  Widget _buildNumericDetail(
    double nDist,
    double kDist,
    double nKoubai,
    double kKoubai,
    int updown,
    TextStyle baseStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _row(
          "登り割合",
          "${_formatDoubleToFixed(nDist * 100, 1)}%",
          baseStyle.copyWith(color: upColor),
        ),
        _row(
          "登り勾配",
          _formatDoubleToFixed(nKoubai.abs(), 3),
          baseStyle.copyWith(color: upColor),
        ),
        const SizedBox(height: 4),
        _row(
          "下り割合",
          "${_formatDoubleToFixed(kDist * 100, 1)}%",
          baseStyle.copyWith(color: downColor),
        ),
        _row(
          "下り勾配",
          _formatDoubleToFixed(kKoubai.abs(), 3),
          baseStyle.copyWith(color: downColor),
        ),
        const SizedBox(height: 4),
        _row(
          "アップダウン",
          "$updown 回",
          baseStyle.copyWith(color: Colors.yellowAccent),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univDataBox = Hive.box<UnivData>('univBox');
    final List<UnivData> sortedUnivData = univDataBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, box, _) {
        final Ghensuu? currentGhensuu = box.getAt(0);
        final String raceTitle = _getRaceTitle(
          widget.racebangou,
          sortedUnivData,
        );
        if (currentGhensuu == null)
          return const Scaffold(body: Center(child: Text('Data Error')));

        return Stack(
          children: [
            Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text(
                  '区間コース確認',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
                actions: [
                  // コピーボタン（全区間一括）
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "全区間の情報をコピー",
                    onPressed: _isExporting
                        ? null
                        : () => _copyAllSectionsToClipboard(
                            raceTitle,
                            currentGhensuu,
                          ),
                  ),
                  // 画像保存ボタン
                  IconButton(
                    icon: const Icon(Icons.image),
                    tooltip: "画像として保存/共有",
                    onPressed: _isExporting
                        ? null
                        : () => _exportAsImage(raceTitle, currentGhensuu),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text("グラフ"),
                          icon: Icon(Icons.bar_chart),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text("詳細数値"),
                          icon: Icon(Icons.list_alt),
                        ),
                      ],
                      selected: {_showGraphMode},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _showGraphMode = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        selectedBackgroundColor: Colors.blue,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMainContent(currentGhensuu, raceTitle),
                          const SizedBox(height: 20),
                          if (_showGraphMode &&
                              (widget.racebangou <= 2 ||
                                  widget.racebangou == 5))
                            _buildInformationCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBackButton(context),
                ],
              ),
            ),
            if (_isExporting)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "表示の解説",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "・グラフの太さは勾配を表し、最大10%を基準に描画しています。",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Text(
            "・登り指とは登り指数を表し、登り距離割合✖︎平均勾配✖︎10000で求められます。下り指も同様です。",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Text(
            "・UDはアップダウン回数を表します。",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    Ghensuu currentGhensuu,
    String raceTitle, {
    bool isForImage = false,
  }) {
    final textStyle = TextStyle(
      color: HENSUU.textcolor,
      fontSize: isForImage ? 18 : HENSUU.fontsize_honbun,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    );

    // 予選判定
    if (widget.racebangou == 3 || widget.racebangou == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(raceTitle, style: textStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            widget.racebangou == 3
                ? "1万mトラックレースを4組に分けて行います。なお、ゲームの仕様上、1万mの記録としては残りません。"
                : "完全フラットなハーフマラソンのコースで行われます。なお、ゲームの仕様上、ハーフマラソンの記録としては残りません。",
            style: textStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      );
    }

    final kukanCount =
        (widget.racebangou >= 0 && widget.racebangou <= 2) ||
            widget.racebangou == 5
        ? currentGhensuu.kukansuu_taikaigoto[widget.racebangou]
        : 0;

    if (isForImage && kukanCount > 0) {
      // 画像出力用レイアウト
      return Wrap(
        spacing: 20,
        runSpacing: 25,
        children: List.generate(kukanCount, (i) {
          final nD = currentGhensuu
              .kyoriwariainobori_taikai_kukangoto[widget.racebangou][i];
          final kD = currentGhensuu
              .kyoriwariaikudari_taikai_kukangoto[widget.racebangou][i];
          final nK = currentGhensuu
              .heikinkoubainobori_taikai_kukangoto[widget.racebangou][i];
          final kK = currentGhensuu
              .heikinkoubaikudari_taikai_kukangoto[widget.racebangou][i];
          final ud = currentGhensuu
              .noborikudarikirikaekaisuu_taikai_kukangoto[widget.racebangou][i];

          return Container(
            width: 245,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${i + 1}区",
                  style: textStyle.copyWith(
                    fontSize: 22,
                    color: Colors.blueAccent,
                  ),
                ),
                const Divider(color: Colors.white24),
                _row(
                  "距離",
                  "${_formatDoubleToFixed(currentGhensuu.kyori_taikai_kukangoto[widget.racebangou][i], 0)}m",
                  textStyle,
                ),
                if (_showGraphMode)
                  _buildIndexGraph(nD, kD, nK, kK, ud, true)
                else
                  _buildNumericDetail(nD, kD, nK, kK, ud, textStyle),
              ],
            ),
          );
        }),
      );
    } else {
      // 画面表示用レイアウト
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(raceTitle, style: textStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          if (kukanCount > 0)
            for (int i = 0; i < kukanCount; i++)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 【変更箇所】 区間名とコピーボタンを横並びにする ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${i + 1}区",
                          style: textStyle.copyWith(
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                        // 個別コピーボタン
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 20,
                            color: Colors.grey,
                          ),
                          tooltip: "${i + 1}区のデータをコピー",
                          onPressed: () => _copySingleSectionToClipboard(
                            raceTitle,
                            currentGhensuu,
                            i,
                          ),
                        ),
                      ],
                    ),
                    // ----
                    _row(
                      "距離: ${_formatDoubleToFixed(currentGhensuu.kyori_taikai_kukangoto[widget.racebangou][i], 0)}m",
                      "",
                      textStyle,
                    ),
                    if (_showGraphMode)
                      _buildIndexGraph(
                        currentGhensuu.kyoriwariainobori_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu.kyoriwariaikudari_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .heikinkoubainobori_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .heikinkoubaikudari_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .noborikudarikirikaekaisuu_taikai_kukangoto[widget
                            .racebangou][i],
                        false,
                      )
                    else
                      _buildNumericDetail(
                        currentGhensuu.kyoriwariainobori_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu.kyoriwariaikudari_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .heikinkoubainobori_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .heikinkoubaikudari_taikai_kukangoto[widget
                            .racebangou][i],
                        currentGhensuu
                            .noborikudarikirikaekaisuu_taikai_kukangoto[widget
                            .racebangou][i],
                        textStyle,
                      ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.grey),
                  ],
                ),
              ),
        ],
      );
    }
  }

  Widget _row(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        "$label $value",
        style: style.copyWith(fontSize: style.fontSize! - 2),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(
          "戻る",
          style: TextStyle(
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
