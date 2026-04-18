import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
// ModalSenshuDetailView を使用するため、インポートを有効にします
import 'package:ekiden/screens/Modal_senshu.dart';

// ------------------------------------------------
// 能力値の定義と対応する日本語名
// ------------------------------------------------
enum SortAbility {
  konjou, // 駅伝男
  heijousin, // 平常心
  choukyorinebari, // 長距離粘り
  spurtryoku, // スパート力
  karisuma, // カリスマ
  noboritekisei, // 登り適正
  kudaritekisei, // 下り適正
  noborikudarikirikaenouryoku, // アップダウン対応力
  tandokusou, // ロード適正
  paceagesagetaiouryoku, // ペース上げ下げ対応力
  anteikan, // 安定感 (常に表示可能)
}

// ------------------------------------------------
// 選手の能力値とソートに必要な情報を保持する構造体
// ------------------------------------------------
class SenshuAbility {
  final SenshuData senshu;
  final SortAbility ability;
  final int value;

  SenshuAbility(this.senshu, this.ability, this.value);

  // 能力値は値が大きいほど上位
  int get sortableValue => value;
}

// ------------------------------------------------
// 大学内選手能力値ランキング画面
// ------------------------------------------------
class ModalUnivSenshuAbilityRankingView extends StatefulWidget {
  const ModalUnivSenshuAbilityRankingView({super.key});

  @override
  State<ModalUnivSenshuAbilityRankingView> createState() =>
      _ModalUnivSenshuAbilityRankingViewState();
}

class _ModalUnivSenshuAbilityRankingViewState
    extends State<ModalUnivSenshuAbilityRankingView> {
  // ★ 表示する能力値を保持するローカル状態変数 ★
  // デフォルトは安定感 (anteikan) に設定
  SortAbility _displayAbility = SortAbility.anteikan;

  // 能力値に対応する日本語名を取得
  String _getAbilityLabel(SortAbility ability) {
    switch (ability) {
      case SortAbility.konjou:
        return '駅伝男';
      case SortAbility.heijousin:
        return '平常心';
      case SortAbility.choukyorinebari:
        return '粘り';
      case SortAbility.spurtryoku:
        return 'スパート';
      case SortAbility.karisuma:
        return 'カリスマ';
      case SortAbility.noboritekisei:
        return '登り適正';
      case SortAbility.kudaritekisei:
        return '下り適正';
      case SortAbility.noborikudarikirikaenouryoku:
        return 'アップダウン';
      case SortAbility.tandokusou:
        return 'ロード適正';
      case SortAbility.paceagesagetaiouryoku:
        return 'ペース変動';
      case SortAbility.anteikan:
        return '安定感';
    }
  }

  // SenshuDataから指定された能力値を取得
  int _getSenshuAbilityValue(SenshuData senshu, SortAbility ability) {
    switch (ability) {
      case SortAbility.konjou:
        return senshu.konjou;
      case SortAbility.heijousin:
        return senshu.heijousin;
      case SortAbility.choukyorinebari:
        return senshu.choukyorinebari;
      case SortAbility.spurtryoku:
        return senshu.spurtryoku;
      case SortAbility.karisuma:
        return senshu.karisuma;
      case SortAbility.noboritekisei:
        return senshu.noboritekisei;
      case SortAbility.kudaritekisei:
        return senshu.kudaritekisei;
      case SortAbility.noborikudarikirikaenouryoku:
        return senshu.noborikudarikirikaenouryoku;
      case SortAbility.tandokusou:
        return senshu.tandokusou;
      case SortAbility.paceagesagetaiouryoku:
        return senshu.paceagesagetaiouryoku;
      case SortAbility.anteikan:
        // 安定感は見える化フラグが存在しないため、常に値を返す
        return senshu.anteikan;
    }
  }

  // 見える化フラグに基づき、利用可能な能力値のリストを取得
  List<SortAbility> _getAvailableAbilities(Ghensuu currentGhensuu) {
    List<SortAbility> abilities = [];
    final flag = currentGhensuu.nouryokumieruflag;

    // 見える化フラグが1の場合にのみ追加 (anteikan以外)
    if (flag[0] == 1) abilities.add(SortAbility.konjou);
    if (flag[1] == 1) abilities.add(SortAbility.heijousin);
    if (flag[2] == 1) abilities.add(SortAbility.choukyorinebari);
    if (flag[3] == 1) abilities.add(SortAbility.spurtryoku);
    if (flag[4] == 1) abilities.add(SortAbility.karisuma);
    if (flag[5] == 1) abilities.add(SortAbility.noboritekisei);
    if (flag[6] == 1) abilities.add(SortAbility.kudaritekisei);
    if (flag[7] == 1) abilities.add(SortAbility.noborikudarikirikaenouryoku);
    if (flag[8] == 1) abilities.add(SortAbility.tandokusou);
    if (flag[9] == 1) abilities.add(SortAbility.paceagesagetaiouryoku);

    // 安定感は見える化フラグに関係なく常に表示
    abilities.add(SortAbility.anteikan);

    // anteikanをリストの最後に移動させる
    abilities.remove(SortAbility.anteikan);
    abilities.add(SortAbility.anteikan);

    return abilities;
  }

  // 大学内の選手能力値ランキングリストを作成
  List<SenshuAbility> _createUnivSenshuAbilityRanking(
    List<SenshuData> allSenshuData,
    int targetUnivId,
    SortAbility ability,
  ) {
    List<SenshuAbility> rankingList = [];

    for (final senshu in allSenshuData) {
      // --- currentGhensuu.hyojiunivnum==senshu.univid の選手のみを対象とする ---
      if (senshu.univid != targetUnivId) {
        continue;
      }

      final int senshuValue = _getSenshuAbilityValue(senshu, ability);

      // 能力値が0の場合（初期値など）はランキング対象外とする
      if (senshuValue > 0) {
        rankingList.add(SenshuAbility(senshu, ability, senshuValue));
      }
    }

    // ------------------------------------------------
    // 能力値の**高い順**に並べ替え（ソートロジック）
    // ------------------------------------------------
    rankingList.sort((a, b) {
      // 1. 能力値降順 (高い方が上)
      final int valueCompare = b.sortableValue.compareTo(a.sortableValue);
      if (valueCompare != 0) return valueCompare;

      // 2. 学年降順 (高学年が上)
      final int gakunenCompare = b.senshu.gakunen.compareTo(a.senshu.gakunen);
      if (gakunenCompare != 0) return gakunenCompare;

      // 3. senshu.id昇順 (idが小さい方が上)
      return a.senshu.id.compareTo(b.senshu.id);
    });

    return rankingList;
  }

  @override
  Widget build(BuildContext context) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return const Center(child: Text('データがありません'));
        }

        // --- 現在表示対象の大学IDと大学データ ---
        final int targetUnivId = currentGhensuu.hyojiunivnum;
        final UnivData? targetUniv = univdataBox.get(targetUnivId);
        final String univName = targetUniv?.name ?? '不明な大学';

        // --- 表示可能な能力値のリストを取得し、状態変数_displayAbilityがリストに含まれるか確認 ---
        final List<SortAbility> availableAbilities = _getAvailableAbilities(
          currentGhensuu,
        );

        // 現在選択中の能力値が利用不可になった場合、利用可能な最初の能力値に変更
        if (!availableAbilities.contains(_displayAbility)) {
          if (availableAbilities.isNotEmpty) {
            _displayAbility = availableAbilities.first;
          }
        }

        final String currentAbilityLabel = _getAbilityLabel(_displayAbility);

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            final List<SenshuData> allSenshuData = senshudataBox.values
                .toList();

            // 1. 大学内の選手能力値ランキングを計算
            final List<SenshuAbility> ranking = _createUnivSenshuAbilityRanking(
              allSenshuData,
              targetUnivId,
              _displayAbility,
            );

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: Text(
                  '$univName 選手別 ${currentAbilityLabel}ランキング',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                children: <Widget>[
                  // --- 修正箇所: 能力値切り替えボタンをColumnの先頭に配置 ---
                  _buildAbilityNavigation(availableAbilities),

                  // --- ランキング一覧リスト ---
                  Expanded(
                    child: ranking.isEmpty
                        ? Center(
                            child: Text(
                              'ランキング対象の選手がいません',
                              style: TextStyle(color: HENSUU.textcolor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: ranking.length,
                            itemBuilder: (context, index) {
                              final SenshuAbility senshuAbility =
                                  ranking[index];
                              final SenshuData senshu = senshuAbility.senshu;
                              final String abilityValueString = senshuAbility
                                  .value
                                  .toString();

                              // ★★★ 1行おきに背景色を切り替えるロジック ★★★
                              final Color bgColor = index.isEven
                                  ? Colors
                                        .transparent // 偶数行は透明
                                  : Colors.white.withOpacity(0.05); // 奇数行は少し濃い色

                              final Color rankColor = HENSUU.textcolor;

                              return Container(
                                // 背景色を設定
                                color: bgColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1行目: ランキング、選手名(学年)、詳細ボタン
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ランキングと選手名(学年)
                                        Flexible(
                                          child: Text(
                                            // 選手名 (学年) の形式
                                            '${index + 1}位 ${senshu.name} (${senshu.gakunen})',
                                            style: TextStyle(
                                              color: rankColor,
                                              fontSize:
                                                  HENSUU.fontsize_honbun *
                                                  1.1, // 選手名を強調
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        // 詳細ボタン
                                        TextButton(
                                          onPressed: () {
                                            showGeneralDialog(
                                              context: context,
                                              barrierColor: Colors.black
                                                  .withOpacity(0.8),
                                              barrierDismissible: true,
                                              barrierLabel: '詳細',
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 300,
                                                  ),
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) {
                                                    return ModalSenshuDetailView(
                                                      senshuId: senshu.id,
                                                    );
                                                  },
                                              transitionBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    return FadeTransition(
                                                      opacity: CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeOut,
                                                      ),
                                                      child: child,
                                                    );
                                                  },
                                            );
                                          },
                                          child: Text(
                                            '詳細',
                                            style: TextStyle(
                                              color: HENSUU.LinkColor,
                                              fontSize: HENSUU.fontsize_honbun,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // 2行目: 能力値名と値
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 能力値名
                                        Text(
                                          currentAbilityLabel,
                                          style: TextStyle(
                                            color: rankColor.withOpacity(0.7),
                                            fontSize: HENSUU.fontsize_honbun,
                                          ),
                                        ),
                                        // 能力値
                                        Text(
                                          abilityValueString,
                                          style: TextStyle(
                                            color: rankColor,
                                            fontSize:
                                                HENSUU.fontsize_honbun *
                                                1.1, // 能力値を強調
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // 区切り線
                                    const Divider(
                                      color: Color.fromARGB(76, 255, 255, 255),
                                      height: 8,
                                    ),
                                  ],
                                ),
                              );
                            },
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

  // ★ 修正箇所：ボタン群のパディングと罫線を上部配置に合わせて調整
  Widget _buildAbilityNavigation(List<SortAbility> availableAbilities) {
    // 利用可能な能力値のボタンリストを作成
    final List<Widget> buttons = availableAbilities
        .map((ability) => _buildAbilityButton(ability))
        .toList();

    return Container(
      padding: const EdgeInsets.only(
        top: 12.0,
        left: 12.0,
        right: 12.0,
        bottom: 12.0, // 下部のパディングを固定値に変更
      ),
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        border: Border(
          // 下部に罫線を引くように修正 (元は上部でした)
          bottom: BorderSide(color: Colors.grey.shade800, width: 1.0),
        ),
      ),
      // SingleChildScrollView で Row をラップし、横スクロールを有効化
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // スクロール時は左寄せ
          children: buttons,
        ),
      ),
    );
  }

  // ボタンウィジェット (変更なし)
  Widget _buildAbilityButton(SortAbility ability) {
    final bool isSelected = _displayAbility == ability;
    final String label = _getAbilityLabel(ability);

    // ラベルが長すぎる場合は調整 ('適正'などを削除)
    final String shortLabel = label.contains('適正') || label.contains('対応力')
        ? label.replaceAll('適正', '').replaceAll('対応力', '')
        : label;

    return Padding(
      // ボタン間のスペースを確保
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _displayAbility = ability;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.lightBlue.shade700
              : Colors.grey.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ), // 左右パディングを調整
          minimumSize: const Size(80, 40), // ボタンの最小幅を確保
        ),
        child: Text(
          shortLabel,
          style: TextStyle(fontSize: HENSUU.fontsize_honbun * 0.7),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}
