import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';

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
  Future<void> _exportAsText(
    String title,
    List<UnivData> filteredData,
    int lastKukanIndex,
    String kustring,
  ) async {
    String shareText = '【$title 順位推移表】\n\n';

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

    // 各大学のデータ行の作成
    for (var univ in filteredData) {
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
                                      itemCount: filteredUnivData.length,
                                      itemBuilder: (context, index) {
                                        final UnivData univ =
                                            filteredUnivData[index];

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
