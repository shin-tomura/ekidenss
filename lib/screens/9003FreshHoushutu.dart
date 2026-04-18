import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/constants.dart';

class FreshmanTradeScreen extends StatefulWidget {
  const FreshmanTradeScreen({super.key});

  @override
  State<FreshmanTradeScreen> createState() => _FreshmanTradeScreenState();
}

class _FreshmanTradeScreenState extends State<FreshmanTradeScreen> {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;
  Ghensuu? _ghensuu;

  final List<int> _selectedPlayerIds = [];
  late List<SenshuData> _myFreshmen;
  late int _overflowCount;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _ghensuu = _ghensuuBox.getAt(0);
    _initLogic();
  }

  void _initLogic() {
    _myFreshmen = _senshuBox.values
        .where((s) => s.univid == _ghensuu!.MYunivid && s.gakunen == 1)
        .toList();

    _myFreshmen.sort(
      (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
    );

    _overflowCount = _myFreshmen.length - TEISUU.NINZUU_1GAKUNEN_INUNIV;

    if (_overflowCount <= 0) {
      _finishAdjustment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1F26),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _myFreshmen.length,
                  itemBuilder: (context, index) {
                    final player = _myFreshmen[index];
                    final isSelected = _selectedPlayerIds.contains(player.id);

                    return GestureDetector(
                      onTap: _isProcessing
                          ? null
                          : () => _handlePlayerTap(player.id, isSelected),
                      child: _buildSelectionTradeCard(player, isSelected),
                    );
                  },
                ),
              ),
              _buildBottomActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        border: const Border(
          bottom: BorderSide(color: Colors.orangeAccent, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '放出選手選択',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: HENSUU.fontsize_honbun + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
              ),
              children: [
                const TextSpan(text: '現在 '),
                TextSpan(
                  text: '${_myFreshmen.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: HENSUU.fontsize_honbun,
                    color: Colors.cyanAccent,
                  ),
                ),
                const TextSpan(
                  text: ' 名（定員 ${TEISUU.NINZUU_1GAKUNEN_INUNIV}名）。\n',
                ),
                TextSpan(
                  text: '$_overflowCount 名',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                const TextSpan(text: ' を選択して他校へ放出してください。'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayerTap(int id, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPlayerIds.remove(id);
      } else {
        _selectedPlayerIds.add(id);
      }
    });
  }

  Widget _buildBottomActionArea() {
    final bool isReady = _selectedPlayerIds.length == _overflowCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black45,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '選択済み: ${_selectedPlayerIds.length} / $_overflowCount 名',
            style: TextStyle(
              color: isReady ? Colors.cyanAccent : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady ? Colors.redAccent : Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (isReady && !_isProcessing)
                  ? _showConfirmDialog
                  : null,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '放出選手を確定',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 確認ダイアログの表示
  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252A33),
          title: const Text(
            '選手放出の確認',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '選択した $_overflowCount 名を他校へ放出します。\nよろしいですか？',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(context);
                _onConfirmPressed();
              },
              child: const Text(
                'はい',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onConfirmPressed() async {
    setState(() => _isProcessing = true);
    await _executeTransferLogic();
    bool isValid = await _validateDataIntegrity();

    if (isValid) {
      await _finishAdjustment();
    } else {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('エラー：人数調整に失敗しました。')));
      }
    }
  }

  Future<void> _executeTransferLogic() async {
    final targetPlayers = _myFreshmen
        .where((s) => _selectedPlayerIds.contains(s.id))
        .toList();

    Map<int, int> univCounts = {};
    for (var s in _senshuBox.values.where((s) => s.gakunen == 1)) {
      univCounts[s.univid] = (univCounts[s.univid] ?? 0) + 1;
    }

    // --- 修正ポイント：補充先の「空き枠」を一つずつリスト化する ---
    List<int> emptySlots = [];

    for (var univId in _univBox.keys.cast<int>()) {
      if (univId == _ghensuu!.MYunivid) continue; // 自校は除外

      int currentCount = univCounts[univId] ?? 0;
      int vacancy = TEISUU.NINZUU_1GAKUNEN_INUNIV - currentCount;

      // 欠員がある分だけ、その大学IDをリストに追加
      // 例：ID:1の大学が2人欠けていれば、[1, 1] と追加される
      if (vacancy > 0) {
        for (int i = 0; i < vacancy; i++) {
          emptySlots.add(univId);
        }
      }
    }

    // 欠員が多い大学から順に埋まるように、一応ソート（任意）
    // emptySlots.sort();

    // --- 選手を空き枠に順番に割り当て ---
    for (int i = 0; i < targetPlayers.length; i++) {
      var player = targetPlayers[i];

      if (i < emptySlots.length) {
        // 空き枠がある場合はそこに所属させる
        player.univid = emptySlots[i];
      } else {
        // もし放出選手の方が空き枠より多ければ、(0)へ
        player.univid = 0;
      }
      await player.save();
    }
  }

  Future<bool> _validateDataIntegrity() async {
    Map<int, int> counts = {};
    for (var s in _senshuBox.values.where((s) => s.gakunen == 1)) {
      counts[s.univid] = (counts[s.univid] ?? 0) + 1;
    }
    for (var univId in _univBox.keys.cast<int>()) {
      if ((counts[univId] ?? 0) != TEISUU.NINZUU_1GAKUNEN_INUNIV) {
        return false;
      }
    }
    return true;
  }

  Future<void> _finishAdjustment() async {
    _ghensuu!.mode = 9005;
    await _ghensuu!.save();
  }

  Widget _buildSelectionTradeCard(SenshuData player, bool isSelected) {
    String timeStr = "記録なし";
    if (player.kiroku_nyuugakuji_5000 != TEISUU.DEFAULTTIME) {
      int m = (player.kiroku_nyuugakuji_5000 / 60).floor();
      int s = (player.kiroku_nyuugakuji_5000 % 60).floor();
      timeStr = "${m}分${s.toString().padLeft(2, '0')}秒";
    }

    return Card(
      color: isSelected ? const Color(0xFF2A1A1A) : const Color(0xFF252A33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.redAccent : Colors.white10,
          width: 2.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.redAccent : Colors.white24,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5000m TIME',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: HENSUU.fontsize_honbun - 2,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Text(
                    '放出対象',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: HENSUU.fontsize_honbun - 2,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black26,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _buildAbilityBadges(player),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text(
                  '1年生',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: HENSUU.fontsize_honbun - 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBadge(String label, int value, bool isMyUniv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMyUniv
            ? Colors.amber.withOpacity(0.15)
            : Colors.blueAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isMyUniv
              ? Colors.amber.withOpacity(0.5)
              : Colors.blueAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isMyUniv ? Colors.amber[50] : Colors.white,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: isMyUniv ? Colors.amberAccent : Colors.cyanAccent,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAbilityBadges(SenshuData freshman) {
    List<Widget> badges = [];

    final Map<String, String> abilities = {
      'konjou': '駅伝男',
      'heijousin': '平常心',
      'choukyorinebari': '長距離粘り',
      'spurtryoku': 'スパート',
      'karisuma': 'カリスマ',
      'noboritekisei': '登り',
      'kudaritekisei': '下り',
      'noborikudarikirikaenouryoku': 'アップダウン',
      'tandokusou': 'ロード',
      'paceagesagetaiouryoku': 'ペース変動',
    };

    final List<String> keys = abilities.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      if (_ghensuu!.nouryokumieruflag[i] == 1) {
        int value = _getRawAbilityValue(freshman, key);
        if (value > 0) {
          badges.add(_badgeWidget(abilities[key]!, value));
        }
      }
    }

    if (freshman.anteikan > 0) {
      badges.add(_buildSingleBadge('安定感', freshman.anteikan, true));
    }

    if (badges.isEmpty) {
      badges.add(
        const Text(
          '見える化能力なし',
          style: TextStyle(
            color: Colors.white24,
            fontSize: HENSUU.fontsize_honbun - 2,
          ),
        ),
      );
    }
    return badges;
  }

  Widget _badgeWidget(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getRawAbilityValue(SenshuData s, String key) {
    switch (key) {
      case 'konjou':
        return s.konjou;
      case 'heijousin':
        return s.heijousin;
      case 'choukyorinebari':
        return s.choukyorinebari;
      case 'spurtryoku':
        return s.spurtryoku;
      case 'karisuma':
        return s.karisuma;
      case 'noboritekisei':
        return s.noboritekisei;
      case 'kudaritekisei':
        return s.kudaritekisei;
      case 'noborikudarikirikaenouryoku':
        return s.noborikudarikirikaenouryoku;
      case 'tandokusou':
        return s.tandokusou;
      case 'paceagesagetaiouryoku':
        return s.paceagesagetaiouryoku;
      default:
        return 0;
    }
  }
}
