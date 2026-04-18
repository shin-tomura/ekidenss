import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/kantoku_data.dart';

// 補欠固定のドロップダウン値として -1 を定義
const int KUKAN_HOKETSU_FIXED = -1;

class KukanHaitiScreen extends StatefulWidget {
  const KukanHaitiScreen({super.key});

  @override
  State<KukanHaitiScreen> createState() => _KukanHaitiScreenState();
}

class _KukanHaitiScreenState extends State<KukanHaitiScreen> {
  // キー: 選手ID (int)、値: 選択された区間番号 (int, 試走なら0, 補欠固定なら-1, 1区なら1)
  // 初期値は「試走で決める」= 0 とする
  Map<int, int> _fixedKukanSelections = {};

  // 区間設定のドロップダウンの項目
  // -1: 補欠として固定 (NEW)
  // 0: 試走で決める
  // 1〜N: N区で固定
  List<DropdownMenuItem<int>> _kukanDropdownItems = [];
  int _numberOfKukan = 0;
  List<SenshuData> _sortedUnivSenshu = [];
  Map<int, double> _optimalKukanAssignment =
      {}; // 区間 (1-indexed) -> 選手ID (Optimal)
  bool _isCalculating = false;

  // --- 【追加】計算ボタンが押されたかどうかを追跡するフラグ ---
  bool _hasCalculated = false;
  // --------------------------------------------------------

  // ドロップダウンのカスタムカラー定義
  static const Color _dropdownTextColor = HENSUU.LinkColor;

  final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
  final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

  @override
  void initState() {
    super.initState();
    // 初期化時に計算フラグは false のまま
    _loadDataAndPrepareUI(calculateInitialOptimal: false);
  }

  // calculateInitialOptimal フラグを追加
  Future<void> _loadDataAndPrepareUI({
    bool calculateInitialOptimal = true,
  }) async {
    // データの取得と準備
    final Ghensuu currentGhensuu = ghensuuBox.get('global_ghensuu')!;
    _numberOfKukan =
        currentGhensuu.kukansuu_taikaigoto[currentGhensuu.hyojiracebangou];
    int targetUnivid = currentGhensuu.MYunivid;

    List<SenshuData> sortedSenshuData = senshudataBox.values.toList();

    // 自分の大学の選手にフィルタリング
    final List<SenshuData> univFilteredSenshuData = sortedSenshuData
        .where(
          (s) =>
              (s.univid == targetUnivid &&
              s.entrykukan_race[currentGhensuu.hyojiracebangou][s.gakunen -
                      1] >=
                  -1),
        )
        .toList();

    // 学年降順、ID昇順にソート
    univFilteredSenshuData.sort((a, b) {
      // 学年降順 (4, 3, 2, 1)
      final gakunenCompare = b.gakunen.compareTo(a.gakunen);
      if (gakunenCompare != 0) return gakunenCompare;
      // 学年が同じならID昇順
      return a.id.compareTo(b.id);
    });

    // 最適配置結果の初期化 (Ghensuu.SenshuSelectedOption から)
    final Map<int, double> initialOptimalAssignment = {};
    final List<int> selectedOption = currentGhensuu.SenshuSelectedOption;

    for (int i = 0; i < _numberOfKukan; i++) {
      final int senshuIndex = selectedOption[i];
      if (senshuIndex >= 0 && senshuIndex < univFilteredSenshuData.length) {
        // 区間 (1-indexed) -> 選手ID
        final int senshuId = univFilteredSenshuData[senshuIndex].id;
        initialOptimalAssignment[i + 1] = senshuId.toDouble();
      }
    }

    setState(() {
      _sortedUnivSenshu = univFilteredSenshuData;
      _optimalKukanAssignment = initialOptimalAssignment; // 最適配置結果を初期値として設定

      // ドロップダウンアイテムの準備:
      // 1. 補欠として固定 (-1) を追加
      _kukanDropdownItems.add(
        const DropdownMenuItem(
          value: KUKAN_HOKETSU_FIXED,
          //child: Text('補欠で固定', style: TextStyle(color: Colors.grey)), // 灰色
          child: Text('補欠で固定', style: TextStyle(color: Colors.green)), //
          //child: Text('補欠で固定', style: TextStyle(color: _dropdownTextColor)), //
        ),
      );
      // 2. 試走で決める (0) を追加
      _kukanDropdownItems.add(
        const DropdownMenuItem(
          value: 0,
          child: Text('試走で決める', style: TextStyle(color: _dropdownTextColor)),
        ),
      );
      // 3. N区で固定 (1〜N) を追加
      for (int i = 1; i <= _numberOfKukan; i++) {
        _kukanDropdownItems.add(
          DropdownMenuItem(
            value: i,
            child: Text('$i区で固定', style: TextStyle(color: _dropdownTextColor)),
          ),
        );
      }

      // 初期状態の fixedKukanSelections を設定 (全て「試走で決める」= 0)
      for (var senshu in _sortedUnivSenshu) {
        _fixedKukanSelections[senshu.id] ??= 0;
      }
    });

    // 初期配置の最適解を計算 (ボタン押下を待つ場合はスキップ)
    if (calculateInitialOptimal) {
      await _calculateOptimalAssignment();
    }
  }

  // ドロップダウン値の変更時 (計算はボタン押下時に行うため、ここでは状態更新のみ)
  void _onKukanSelectionChanged(SenshuData selectedSenshu, int? newValue) {
    if (newValue == null) return;

    setState(() {
      _fixedKukanSelections[selectedSenshu.id] = newValue;
    });

    // 3. 最適解の再計算は行わない (ボタン押下を待つ)
  }

  // --- 新しい機能: 固定区間重複チェック、補欠固定数チェック、最適解計算のトリガー ---
  void _checkConflictsAndCalculate() {
    if (_isCalculating) return;

    // 区間固定の重複チェックと補欠固定数のカウント
    final Map<int, int> fixedKukans = {}; // 区間 -> 選手ID
    int? conflictingKukan;
    int fixedHoketsuCount = 0; // 補欠固定の選手数をカウント

    for (final entry in _fixedKukanSelections.entries) {
      final int playerId = entry.key;
      final int fixedKukan = entry.value;

      if (fixedKukan == KUKAN_HOKETSU_FIXED) {
        fixedHoketsuCount++;
      } else if (fixedKukan > 0) {
        // 区間固定 (1〜N) のチェック
        if (fixedKukans.containsKey(fixedKukan)) {
          // 重複を発見
          conflictingKukan = fixedKukan;
          break;
        }
        fixedKukans[fixedKukan] = playerId;
      }
    }

    // 1. 区間固定の重複がある場合
    if (conflictingKukan != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${conflictingKukan}区に複数の選手が固定されています。固定区間設定を確認してください。',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 2. 補欠固定数が多すぎる場合のチェック (区間数 + 補欠選手数 > 総選手数 になっているか)
    final int totalSenshuCount = _sortedUnivSenshu.length;
    final int maxHoketsuAllowed = totalSenshuCount - _numberOfKukan;

    if (maxHoketsuAllowed < 0) {
      // そもそも選手数が区間数未満の場合
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '選手数が区間数より少ないため、計算できません。',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (fixedHoketsuCount > maxHoketsuAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '補欠として固定されている選手が多すぎます。（最大で${maxHoketsuAllowed}人まで）設定を確認してください。',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 3. 問題がない場合、最適解の計算を実行
    // --- 【追加】計算実行前にフラグを立てる ---
    setState(() {
      _hasCalculated = true;
    });
    // ------------------------------------
    _calculateOptimalAssignment();
  }
  // -----------------------------------------------------------------

  // 最適区間配置を計算する関数 (既存のDPロジックを修正)
  Future<void> _calculateOptimalAssignment() async {
    if (_isCalculating || _sortedUnivSenshu.isEmpty) return;

    setState(() {
      _isCalculating = true; // 計算フラグを立てる
      _optimalKukanAssignment = {}; // 結果をクリア
    });

    try {
      final int totalSenshuCount = _sortedUnivSenshu.length;
      final int totalKukans = _numberOfKukan;

      // --- 1. DP計算の対象となる選手をフィルタリング ---
      // 補欠固定 (-1) 以外の選手を抽出
      final List<SenshuData> dpTargetSenshu = _sortedUnivSenshu
          .where((s) => _fixedKukanSelections[s.id] != KUKAN_HOKETSU_FIXED)
          .toList();

      final List<int> dpTargetPlayerIds = dpTargetSenshu
          .map((s) => s.id)
          .toList();
      final int dpTargetPlayerCount = dpTargetPlayerIds.length;

      if (dpTargetPlayerCount < totalKukans) {
        throw Exception('区間配置の対象となる選手数が区間数より少ないです。');
      }

      // --- 2. 試走タイムの計算とキャッシュ (DP対象選手のみ) ---
      final Map<int, Map<int, double>> trialTimesCache = {};

      final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
      final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
      List<SenshuData> sortedsenshudata = senshudataBox.values.toList();
      sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));
      final Box<UnivData> univDataBox = Hive.box<UnivData>('univBox');
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      final KantokuData kantoku = kantokuBox.get('KantokuData')!;

      for (final SenshuData senshu in dpTargetSenshu) {
        final int playerId = senshu.id;
        trialTimesCache[playerId] = {};
        for (int kukanIndex = 0; kukanIndex < totalKukans; kukanIndex++) {
          final double time = await runTrialCalculation(
            playerId,
            kukanIndex,
            currentGhensuu,
            sortedsenshudata,
            sortedUnivData,
            kantoku,
          );
          trialTimesCache[playerId]![kukanIndex] = time;
        }
      }

      // --- 3. 固定区間と除外選手の特定 (DP対象選手の中から) ---
      // 固定区間: 区間 (1-indexed) -> 選手ID
      final Map<int, int> fixedKukanToPlayerId = {};
      // 既に固定で使われている選手の dpTargetPlayerIds リスト内でのインデックス
      final Set<int> fixedPlayerIndices = {};

      _fixedKukanSelections.forEach((playerId, fixedKukan) {
        // 区間固定が設定されている選手のみを処理 (補欠固定は上記で既に除外されている)
        if (fixedKukan > 0) {
          fixedKukanToPlayerId[fixedKukan] = playerId;
          // DP対象リスト内でのインデックスを探す
          final int playerIndex = dpTargetPlayerIds.indexOf(playerId);
          if (playerIndex != -1) {
            fixedPlayerIndices.add(playerIndex);
          }
        }
      });

      // --- 4. 動的計画法による最適配置の探索 ---

      List<int> fastestPlayerIdsResult = List.filled(
        totalKukans,
        0,
      ); // 最終結果 (区間 1〜N の選手ID)
      double fastestTotalTime = 0.0;

      // DPで処理する区間（非固定区間）のインデックス (0-indexed)
      List<int> nonFixedKukanIndices = [];

      // 固定区間の配置と初期タイムの計算
      for (int i = 0; i < totalKukans; i++) {
        final int kukan = i + 1; // 区間番号 (1-indexed)
        final int? fixedId = fixedKukanToPlayerId[kukan];

        if (fixedId != null) {
          // 選手が固定されている場合
          fastestPlayerIdsResult[i] = fixedId;
          // 固定選手のタイムを合計に加算
          fastestTotalTime += trialTimesCache[fixedId]![i]!;
        } else {
          // 選手が固定されていない場合、DPの対象区間とする
          nonFixedKukanIndices.add(i);
        }
      }

      // DPで処理する区間数
      final int numDPKukans = nonFixedKukanIndices.length;

      if (numDPKukans > 0) {
        // 2. DPの初期化と実行

        // dp[k][mask]: DPで処理するk番目の非固定区間までで、非固定選手集合maskを使用したときの最小追加タイム
        final List<Map<int, double>> dp = List.generate(
          numDPKukans + 1,
          (_) => {},
        );
        // parent[k][mask]: DPで処理するk番目の非固定区間で配置した選手の dpTargetPlayerIds リスト内でのインデックス
        final List<Map<int, int>> parent = List.generate(
          numDPKukans + 1,
          (_) => {},
        );

        // 初期化: 0区間目、固定選手を使用済みのマスク (非固定選手は未使用)
        // 固定選手に対応するビットを1にした初期マスク
        final int initialMask = fixedPlayerIndices.fold<int>(
          0,
          (prev, index) => prev | (1 << index),
        );

        dp[0][initialMask] = 0.0; // 追加タイムは0

        // ループでDPテーブルを埋めていく
        for (
          int kukanDPIndex = 1;
          kukanDPIndex <= numDPKukans;
          kukanDPIndex++
        ) {
          final int prevKukanDPIndex = kukanDPIndex - 1;
          // 実際に配置する区間（0-indexed）
          final int actualKukanIndex = nonFixedKukanIndices[kukanDPIndex - 1];

          for (final prevMask in dp[prevKukanDPIndex].keys) {
            // 過去に使用した選手を特定
            for (
              int currentPlayerIdx = 0;
              currentPlayerIdx < dpTargetPlayerCount;
              currentPlayerIdx++
            ) {
              // currentPlayerIdx (DP対象選手リスト内でのインデックス)に対応するビット
              final int currentMaskBit = 1 << currentPlayerIdx;

              // 選手が既に固定で使われているか、またはDPで既に使用されているかチェック
              if ((prevMask & currentMaskBit) == 0) {
                // 未使用の場合、選手を配置可能
                final int newMask = prevMask | currentMaskBit;

                final int currentPlayerId = dpTargetPlayerIds[currentPlayerIdx];
                final double currentTime =
                    trialTimesCache[currentPlayerId]![actualKukanIndex]!;
                final double totalTime =
                    dp[prevKukanDPIndex][prevMask]! + currentTime;

                // 新しいマスクでの最小タイムを更新
                if (totalTime <
                    (dp[kukanDPIndex][newMask] ?? double.infinity)) {
                  dp[kukanDPIndex][newMask] = totalTime;
                  parent[kukanDPIndex][newMask] = currentPlayerIdx;
                }
              }
            }
          }
        }

        // 3. 最後の区間までの最適な合計タイムと組み合わせを逆順でたどる (非固定区間のみ)

        double fastestAdditionalTime = double.infinity;
        int finalMask = -1;
        final int finalKukanDPIndex = numDPKukans;

        // 最終的な選手マスクの中から最小タイムを探す
        for (final mask in dp[finalKukanDPIndex].keys) {
          if (dp[finalKukanDPIndex][mask]! < fastestAdditionalTime) {
            fastestAdditionalTime = dp[finalKukanDPIndex][mask]!;
            finalMask = mask;
          }
        }

        // 3-1. 最終合計タイムの計算
        fastestTotalTime += fastestAdditionalTime;

        // 3-2. DPの結果から配置を逆順でたどり、fastestPlayerIdsResultを埋める
        int currentMask = finalMask;
        for (
          int kukanDPIndex = numDPKukans;
          kukanDPIndex >= 1;
          kukanDPIndex--
        ) {
          final int currentPlayerIdx = parent[kukanDPIndex][currentMask]!;
          final int currentPlayerId = dpTargetPlayerIds[currentPlayerIdx];
          // 実際に配置する区間（0-indexed）
          final int actualKukanIndex = nonFixedKukanIndices[kukanDPIndex - 1];

          // 非固定区間の最適配置を結果リストに格納
          fastestPlayerIdsResult[actualKukanIndex] = currentPlayerId;

          // 現在の選手をマスクから外して、前の状態のマスクを計算
          currentMask = currentMask ^ (1 << currentPlayerIdx);
        }
      }
      // else: numDPKukans が 0 の場合（全区間が固定の場合）

      // 5. 結果の変換と保存 (すべての選手リスト _sortedUnivSenshu を使用)

      // 取得した結果を _optimalKukanAssignment に変換 (UI表示用)
      setState(() {
        _optimalKukanAssignment = {};

        // 区間配置の結果を格納
        for (int i = 0; i < totalKukans; i++) {
          _optimalKukanAssignment[i + 1] = fastestPlayerIdsResult[i].toDouble();
        }

        // 補欠固定の選手を格納する必要はない (UI側で isFixedHoketsu を確認するため)
      });

      // 結果を保存 (Ghensuu.SenshuSelectedOption の更新)
      //final Ghensuu currentGhensuu = ghensuuBox.get('global_ghensuu')!;
      for (int i = 0; i < totalKukans; i++) {
        final int playerId = fastestPlayerIdsResult[i];
        final int playerIndex = _sortedUnivSenshu.indexWhere(
          (s) => s.id == playerId,
        );
        if (playerIndex != -1) {
          // Ghensuu.SenshuSelectedOptionには、_sortedUnivSenshuリストのインデックスを格納
          currentGhensuu.SenshuSelectedOption[i] = playerIndex;
        }
      }

      await currentGhensuu.save();
    } catch (e) {
      // エラー処理
      print('最適配置計算エラー: $e');
      // UIでエラー表示を行う
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '最適配置計算中にエラーが発生しました: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false; // 計算フラグを下ろす
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle whiteTextStyle = TextStyle(color: Colors.white);

    // 最適配置区間が強調される際のカスタムカラー (例: Light Blue)
    const Color optimalColor = Color.fromARGB(255, 173, 216, 230); // 薄い青
    // 固定区間が強調される際のカスタムカラー (例: Light Green)
    const Color fixedColor = Color.fromARGB(255, 144, 238, 144); // 薄い緑
    // 競合・警告色
    const Color conflictColor = Colors.redAccent;
    // 補欠固定時のテキストカラー
    const Color hoketsuColor = Colors.grey;
    // ドロップダウンテキストのカスタムカラー
    const Color dropdownTextColor = _dropdownTextColor;

    // --- 【変更点2】ヘッダーテキストの動的切り替え ---
    final String assignmentHeader = _hasCalculated ? '最適配置区間' : '現在の区間';
    // --------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !_isCalculating,
        leading: _isCalculating
            ? null
            : (ModalRoute.of(context)?.canPop ?? false)
            ? const BackButton(color: Colors.white)
            : null,
        title: const Text('最適解区間配置', style: whiteTextStyle),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('固定区間設定', style: whiteTextStyle),
                  ),
                  Expanded(
                    flex: 1,
                    // --- 【変更点3】ヘッダーテキストの動的表示 ---
                    child: Text(assignmentHeader, style: whiteTextStyle),
                    // ----------------------------------------
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white54),

            // --- 選手ごとのデータ (2段構成) ---
            ..._sortedUnivSenshu.map((senshu) {
              // 現在の選手の固定区間選択 (0: 試走, -1: 補欠固定, 1〜N: N区で固定)
              final int selectedKukan = _fixedKukanSelections[senshu.id] ?? 0;

              // この選手が最適配置された区間 (1-indexed, なければ 0) または補欠かどうか
              final int assignedKukan = _optimalKukanAssignment.entries
                  .firstWhere(
                    (entry) => entry.value.toInt() == senshu.id,
                    orElse: () => const MapEntry(0, 0.0),
                  )
                  .key;

              // 補欠として固定されているか
              final bool isFixedHoketsu = selectedKukan == KUKAN_HOKETSU_FIXED;
              // 最適配置で使われていない（つまり補欠）かどうか
              final bool isHoketsu = assignedKukan == 0;

              // 競合チェック (表示用: 複数の選手が同じ区間を固定しているか)
              final bool isConflicting =
                  selectedKukan > 0 && // 区間固定の場合のみチェック
                  _fixedKukanSelections.entries.any(
                    (entry) =>
                        entry.key != senshu.id && entry.value == selectedKukan,
                  );

              // 氏名テキストの色を決定
              Color nameTextColor = Colors.white;
              FontWeight nameFontWeight = FontWeight.normal;
              if (!isHoketsu && !isFixedHoketsu) {
                // 最適配置されていて、補欠固定ではない
                nameTextColor = optimalColor;
                nameFontWeight = FontWeight.bold;
              } else if (isFixedHoketsu) {
                // 補欠固定の場合
                nameTextColor = hoketsuColor;
              }

              // 最適配置区間表示のテキストを決定
              String assignedText = '-';
              Color assignedTextColor = Colors.white;
              FontWeight assignedFontWeight = FontWeight.normal;

              if (isFixedHoketsu) {
                assignedText = '補欠 (固定)';
                assignedTextColor = hoketsuColor;
              } else if (assignedKukan > 0) {
                assignedText = '${assignedKukan}区';
                if (selectedKukan > 0) {
                  // 区間固定されており、かつ最適配置もその区間である場合
                  assignedTextColor = fixedColor;
                  assignedFontWeight = FontWeight.bold;
                } else {
                  // 試走または補欠で決める設定で、最適配置された場合
                  assignedTextColor = optimalColor;
                }
              } else if (isHoketsu && selectedKukan == 0) {
                assignedText = '補欠'; // 最適配置されず、試走で決める設定の場合
                assignedTextColor = Colors.white;
              } else if (_hasCalculated && isHoketsu && selectedKukan > 0) {
                // 区間固定設定されているが、計算結果で配置されなかった場合 (このケースは通常発生しないはず)
                assignedText = 'エラー？';
                assignedTextColor = conflictColor;
              }

              return Column(
                key: ValueKey(senshu.id),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 8.0,
                      bottom: 4.0,
                    ),
                    // 1段目: 氏名と学年
                    child: Row(
                      children: [
                        Expanded(
                          // 氏名テキストの色調整
                          child: Text(
                            '${senshu.name} (${senshu.gakunen}年)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: nameTextColor,
                              fontWeight: nameFontWeight,
                            ),
                          ),
                        ),
                        // 詳細ボタン
                        TextButton(
                          // 計算中は詳細ボタンも無効化
                          onPressed: _isCalculating
                              ? null
                              : () {
                                  showGeneralDialog(
                                    context: context,
                                    barrierColor: Colors.black.withOpacity(0.8),
                                    barrierDismissible: true,
                                    barrierLabel: '詳細',
                                    transitionDuration: const Duration(
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
                              // 計算中はリンクカラーを薄くする
                              color: _isCalculating
                                  ? HENSUU.LinkColor.withOpacity(0.5)
                                  : HENSUU.LinkColor,
                              fontSize: HENSUU.fontsize_honbun,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    // 2段目: ドロップダウンと最適配置区間
                    child: Row(
                      children: [
                        // 区間設定ドロップダウンリスト
                        Expanded(
                          flex: 1,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedKukan,
                              items: _kukanDropdownItems,
                              onChanged: _isCalculating
                                  ? null
                                  : (newValue) => _onKukanSelectionChanged(
                                      senshu,
                                      newValue,
                                    ),
                              // ドロップダウンの現在の値の表示色を決定
                              style: TextStyle(
                                color: isConflicting
                                    ? conflictColor
                                    : (isFixedHoketsu
                                          ? hoketsuColor
                                          : dropdownTextColor),
                                fontWeight: isConflicting || isFixedHoketsu
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              isExpanded: true,
                              // 計算中はドロップダウンを無効にする
                              disabledHint: _isCalculating
                                  ? Text(
                                      selectedKukan == KUKAN_HOKETSU_FIXED
                                          ? '補欠で固定'
                                          : selectedKukan == 0
                                          ? '試走で決める'
                                          : '$selectedKukan区で固定',
                                      style: whiteTextStyle.copyWith(
                                        color:
                                            (isFixedHoketsu
                                                    ? hoketsuColor
                                                    : dropdownTextColor)
                                                .withOpacity(0.5),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        // 最適配置区間の表示
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                assignedText,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  color: assignedTextColor,
                                  fontWeight: assignedFontWeight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24), // 区切り線
                ],
              );
            }).toList(),

            // --- 補足説明文 (スクロール領域の最下部) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '【補足説明】',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '・「固定区間設定」で特定の選手の区間を固定（または補欠に固定）して最適解計算を行えます。',
                    style: whiteTextStyle.copyWith(fontSize: 12),
                  ),
                  Text(
                    '・試走は行うたびにわざとタイムに振れ幅を設けているため、ボタンを押すたびに結果は異なる可能性があります。',
                    style: whiteTextStyle.copyWith(fontSize: 12),
                  ),
                  Text(
                    '・経験補正は考慮されませんし、1区の展開も読めません。目標順位を下回った場合のタイム損も考慮されません。調子も考慮されず、全選手調子100として計算しています。',
                    style: whiteTextStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            // 画面最下部でボタンに隠れないようにパディングを追加
            const SizedBox(height: 80),
          ],
        ),
      ),
      // --- 画面下部の計算ボタン ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isCalculating ? null : _checkConflictsAndCalculate,
          icon: _isCalculating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.calculate, color: Colors.white),
          label: Text(
            _isCalculating ? '計算中...' : '最適解を計算',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: _isCalculating
                ? Colors.grey
                : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
