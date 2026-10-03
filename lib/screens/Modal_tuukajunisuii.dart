import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';

class ModalRankTransitionView extends StatefulWidget {
  const ModalRankTransitionView({super.key});

  @override
  State<ModalRankTransitionView> createState() =>
      _ModalRankTransitionViewState();
}

class _ModalRankTransitionViewState extends State<ModalRankTransitionView> {
  // 最終区間（最新区間）の順位を基準に大学リストをソートする関数
  List<UnivData> _sortUnivListByLatestJuni(
    List<UnivData> list,
    int lastKukanIndex,
  ) {
    list.sort((a, b) {
      final bool isAValid = a.tuukajuni_taikai.length > lastKukanIndex;
      final bool isBValid = b.tuukajuni_taikai.length > lastKukanIndex;

      final int junibA = isAValid
          ? a.tuukajuni_taikai[lastKukanIndex]
          : TEISUU.DEFAULTJUNI;
      final int junibB = isBValid
          ? b.tuukajuni_taikai[lastKukanIndex]
          : TEISUU.DEFAULTJUNI;

      if (junibA == TEISUU.DEFAULTJUNI && junibB == TEISUU.DEFAULTJUNI) {
        return 0;
      }
      if (junibA == TEISUU.DEFAULTJUNI) return 1;
      if (junibB == TEISUU.DEFAULTJUNI) return -1;

      return junibA.compareTo(junibB);
    });
    return list;
  }

  // クリップボードへマークダウン形式のテキストとしてコピーする関数
  // [gakurenSaishin] 学連選抜の最新区間の結果(いないときはnull)、[gakurenJuni] 学連選抜の区間ごとの
  // 通過順位相当(0が1位相当)、[gakurenIchi] 学連選抜の行を差し込む位置(1.8.2)
  Future<void> _exportAsText(
    String title,
    List<UnivData> filteredData,
    int lastKukanIndex,
    String kustring,
    GakurenKukanKekka? gakurenSaishin,
    List<int?> gakurenJuni,
    int gakurenIchi,
  ) async {
    String shareText = '';
    if (gakurenSaishin != null) shareText += gakurenOpChuui;
    shareText += '【$title 順位推移表】\n\n';

    // ヘッダー部分の作成
    shareText += '| 最新順位 | 大学名 | ';

    for (int i = 0; i <= lastKukanIndex; i++) {
      shareText += '${i + 1}$kustring | ';
    }
    shareText += '\n';

    // 区切り線の作成
    shareText += '| :--- | :--- | ';
    for (int i = 0; i <= lastKukanIndex; i++) {
      shareText += ':---: | ';
    }
    shareText += '\n';

    // 学連選抜(OP)の行(1.8.2)
    String gakurenGyou() {
      String gyou = '| OP(${gakurenSaishin!.tuukaJuni + 1}位相当) | 学連選抜 | ';
      for (int i = 0; i <= lastKukanIndex; i++) {
        final int? juni = i < gakurenJuni.length ? gakurenJuni[i] : null;
        gyou += '${juni == null ? '---' : juni + 1} | ';
      }
      return '$gyou\n';
    }

    // 各大学のデータ行の作成
    for (int index = 0; index < filteredData.length; index++) {
      final UnivData univ = filteredData[index];
      if (gakurenSaishin != null && index == gakurenIchi) {
        shareText += gakurenGyou();
      }
      // 最新の順位を取得
      final int latestJuniRaw = univ.tuukajuni_taikai.length > lastKukanIndex
          ? univ.tuukajuni_taikai[lastKukanIndex]
          : TEISUU.DEFAULTJUNI;
      final String latestJuniStr = latestJuniRaw == TEISUU.DEFAULTJUNI
          ? '---'
          : '${latestJuniRaw + 1}位';

      shareText += '| $latestJuniStr | ${univ.name} | ';

      // 各区間の順位を取得
      for (int i = 0; i <= lastKukanIndex; i++) {
        final int kukanJuniRaw = univ.tuukajuni_taikai.length > i
            ? univ.tuukajuni_taikai[i]
            : TEISUU.DEFAULTJUNI;
        final String kukanJuniStr = kukanJuniRaw == TEISUU.DEFAULTJUNI
            ? '---'
            : '${kukanJuniRaw + 1}';

        shareText += '$kukanJuniStr | ';
      }
      shareText += '\n';
    }
    // 学連選抜がどの大学よりも後ろのときは最後に入れる
    if (gakurenSaishin != null && gakurenIchi >= filteredData.length) {
      shareText += gakurenGyou();
    }

    shareText += '\n#箱庭小駅伝SS';

    // クリップボードにコピー
    await Clipboard.setData(ClipboardData(text: shareText));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('順位推移表をクリップボードにコピーしました')));
    }
  }

  // --- カスタムテーブル用のセル作成ヘルパーメソッド ---
  Widget _buildHeaderCell(String text, double width, Alignment alignment) {
    return Container(
      width: width,
      height: 48.0, // ヘッダーの高さ
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(
          color: HENSUU.textcolor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, Alignment alignment) {
    return Container(
      width: width,
      height: 48.0, // データ行の高さ
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(color: HENSUU.textcolor, fontSize: 14),
      ),
    );
  }

  // 学連選抜(OP)の行(正月駅伝のときだけ、最新の通過順位相当の位置に入れる。1.8.2)
  Widget _buildGakurenRow(
    GakurenKukanKekka saishin,
    List<int?> gakurenJuni,
    int lastKukanIndex,
    double rankColumnWidth,
    double nameColumnWidth,
    double kukanColumnWidth,
  ) {
    const TextStyle opStyle = TextStyle(
      color: Colors.cyanAccent,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return Container(
      color: Colors.cyanAccent.withOpacity(0.08),
      child: Row(
        children: [
          Container(
            width: rankColumnWidth,
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            alignment: Alignment.centerLeft,
            child: Text(
              'OP\n${saishin.tuukaJuni + 1}位相当',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: nameColumnWidth,
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.centerLeft,
            child: const Text('学連選抜', style: opStyle),
          ),
          for (int i = 0; i <= lastKukanIndex; i++)
            Container(
              width: kukanColumnWidth,
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              alignment: Alignment.center,
              child: Text(
                i < gakurenJuni.length && gakurenJuni[i] != null
                    ? '${gakurenJuni[i]! + 1}'
                    : '-',
                style: opStyle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');

    // テーブルの各列の固定幅を定義
    const double rankColumnWidth = 70.0;
    const double nameColumnWidth = 140.0;
    const double kukanColumnWidth = 55.0;

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
        if (currentGhensuu == null) {
          return const Center(child: Text('データがありません'));
        }

        final int raceBangou = currentGhensuu.hyojiracebangou;

        // 現在までに走り終わっている（計算済みの）最新の区間インデックスを取得
        final int lastKukanIndex = currentGhensuu.nowracecalckukan > 0
            ? currentGhensuu.nowracecalckukan - 1
            : -1;

        if (lastKukanIndex < 0) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('順位推移表', style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                '表示可能な区間がありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        // タイトルの作成
        String kukantext = '第${lastKukanIndex + 1}区終了時';
        if (raceBangou == 3) kukantext = '第${lastKukanIndex + 1}組終了時';
        if (raceBangou == 4) kukantext = '予選会';

        String kustring = "";
        if (raceBangou == 3) {
          kustring = "組";
        } else {
          kustring = "区";
        }
        // テーブル全体の幅を計算
        final double totalTableWidth =
            rankColumnWidth +
            nameColumnWidth +
            ((lastKukanIndex + 1) * kukanColumnWidth);

        return ValueListenableBuilder<Box<UnivData>>(
          valueListenable: univdataBox.listenable(),
          builder: (context, univdataBox, _) {
            final List<UnivData> allUnivData = univdataBox.values.toList();

            // 出場している大学のみをフィルタリング
            List<UnivData> filteredUnivData = allUnivData.where((univ) {
              return univ.taikaientryflag.length > raceBangou &&
                  univ.taikaientryflag[raceBangou] == 1;
            }).toList();

            // 最新区間の順位でソート
            filteredUnivData = _sortUnivListByLatestJuni(
              filteredUnivData,
              lastKukanIndex,
            );

            // 学連選抜(正月駅伝のときだけ)を、最新の通過順位相当の位置に「OP」として表に入れる(1.8.2)
            final GakurenKukanKekka? gakurenSaishin = gakurenKukanKekka(
              currentGhensuu,
              lastKukanIndex,
            );
            final List<int?> gakurenJuni = [
              for (int i = 0; i <= lastKukanIndex; i++)
                gakurenSaishin == null
                    ? null
                    : gakurenKukanKekka(currentGhensuu, i)?.tuukaJuni,
            ];
            final int gakurenIchi = gakurenSaishin == null
                ? -1
                : gakurenSounyuuIchi([
                    for (final u in filteredUnivData)
                      u.tuukajuni_taikai.length > lastKukanIndex
                          ? u.tuukajuni_taikai[lastKukanIndex]
                          : TEISUU.DEFAULTJUNI,
                  ], gakurenSaishin.tuukaJuni);
            final int gakurenKazu = gakurenSaishin == null ? 0 : 1;

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: Text(
                  '$kukantext 順位推移',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'テキストをコピー',
                    onPressed: filteredUnivData.isEmpty
                        ? null
                        : () => _exportAsText(
                            kukantext,
                            filteredUnivData,
                            lastKukanIndex,
                            kustring,
                            gakurenSaishin,
                            gakurenJuni,
                            gakurenIchi,
                          ),
                  ),
                ],
              ),
              body: filteredUnivData.isEmpty
                  ? Center(
                      child: Text(
                        '結果がありません',
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    )
                  // 見出しを固定したカスタムテーブル構造
                  : Column(
                      children: [
                        // 学連選抜(OP)の説明(1.8.2)
                        if (gakurenSaishin != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: Text(
                              '※OPは学連選抜(オープン参加)です。順位には数えず、数字は大学の中に入れた場合の順位相当です',
                              style: TextStyle(
                                color: HENSUU.textcolor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalTableWidth,
                              child: Column(
                                children: [
                                  // --- ヘッダー（固定） ---
                                  Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: Row(
                                      children: [
                                        _buildHeaderCell(
                                          '最新',
                                          rankColumnWidth,
                                          Alignment.centerLeft,
                                        ),
                                        _buildHeaderCell(
                                          '大学名',
                                          nameColumnWidth,
                                          Alignment.centerLeft,
                                        ),
                                        for (
                                          int i = 0;
                                          i <= lastKukanIndex;
                                          i++
                                        )
                                          _buildHeaderCell(
                                            '${i + 1}$kustring',
                                            kukanColumnWidth,
                                            Alignment.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                  // --- ヘッダー下の境界線 ---
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.white24,
                                  ),

                                  // --- データ行（縦スクロール） ---
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount:
                                          filteredUnivData.length +
                                          gakurenKazu,
                                      itemBuilder: (context, index) {
                                        // 学連選抜の行(1.8.2)
                                        if (gakurenSaishin != null &&
                                            index == gakurenIchi) {
                                          return _buildGakurenRow(
                                            gakurenSaishin,
                                            gakurenJuni,
                                            lastKukanIndex,
                                            rankColumnWidth,
                                            nameColumnWidth,
                                            kukanColumnWidth,
                                          );
                                        }
                                        final UnivData univ =
                                            filteredUnivData[gakurenSaishin !=
                                                        null &&
                                                    index > gakurenIchi
                                                ? index - 1
                                                : index];

                                        // 最新順位
                                        final int latestJuniRaw =
                                            univ.tuukajuni_taikai.length >
                                                lastKukanIndex
                                            ? univ.tuukajuni_taikai[lastKukanIndex]
                                            : TEISUU.DEFAULTJUNI;
                                        final String latestJuniStr =
                                            latestJuniRaw == TEISUU.DEFAULTJUNI
                                            ? '---'
                                            : '${latestJuniRaw + 1}位';

                                        return Container(
                                          // ゼブラストライプ（一行おきに背景色を変更）
                                          color: index % 2 == 0
                                              ? Colors.transparent
                                              : Colors.white.withOpacity(0.07),
                                          child: Row(
                                            children: [
                                              _buildDataCell(
                                                latestJuniStr,
                                                rankColumnWidth,
                                                Alignment.centerLeft,
                                              ),
                                              _buildDataCell(
                                                univ.name,
                                                nameColumnWidth,
                                                Alignment.centerLeft,
                                              ),
                                              // 各区間の順位を動的に生成
                                              for (
                                                int i = 0;
                                                i <= lastKukanIndex;
                                                i++
                                              )
                                                _buildDataCell(
                                                  univ.tuukajuni_taikai.length >
                                                              i &&
                                                          univ.tuukajuni_taikai[i] !=
                                                              TEISUU.DEFAULTJUNI
                                                      ? '${univ.tuukajuni_taikai[i] + 1}'
                                                      : '-',
                                                  kukanColumnWidth,
                                                  Alignment.center,
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
