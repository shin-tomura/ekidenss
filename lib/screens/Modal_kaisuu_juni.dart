import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:ekiden/ghensuu.dart'; // 今回の要件では未使用
import 'package:ekiden/constants.dart'; // TEISUUやHENSUUが定義されていると仮定
// import 'package:ekiden/senshu_data.dart'; // 今回の要件では未使用
import 'package:ekiden/univ_data.dart'; // UnivDataが定義されていると仮定

// TimeDate.timeToJikanFunByouString の代わりに使用するヘルパー関数
// 参照コードのTimeDateクラスが不明なため、同様の機能をここで実装
// 秒数を「X時間YY分ZZ秒」形式の文字列に変換する
String _timeToJikanFunByouString(double time) {
  if (time >= TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int totalSeconds = time.toInt();
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;

  String result = '';
  if (hours > 0) {
    result += '${hours}時間';
  }
  result += '${minutes.toString().padLeft(2, '0')}分';
  result += '${seconds.toString().padLeft(2, '0')}秒';

  return result;
}

// racebangouに応じて順位ごとの回数で表示する最大順位を決定するヘルパー関数
int _getMaxJuniCount(int racebangou) {
  switch (racebangou) {
    case 0:
      return 10; // 1位から10位まで (配列インデックス0-9)
    case 1:
      return 15; // 1位から15位まで (配列インデックス0-14)
    case 2:
      return 20; // 1位から20位まで (配列インデックス0-19)
    case 3:
      return 22; // 1位から22位まで (配列インデックス0-21)
    case 4:
      return 20; // 1位から20位まで (配列インデックス0-19)
    case 5:
      return 30; // 1位から30位まで (配列インデックス0-29)
    case 9:
      return 30; // 1位から30位まで (配列インデックス0-29)
    default:
      return 10; // デフォルト (例として10位まで)
  }
}

// 大学成績詳細を表示するモーダルウィジェット
class ModalUnivDetailView extends StatelessWidget {
  final int univid; // 大学ID
  final int racebangou; // 大会番号

  const ModalUnivDetailView({
    super.key,
    required this.univid,
    required this.racebangou,
  });

  @override
  Widget build(BuildContext context) {
    // UnivDataのBoxを取得
    final univDataBox = Hive.box<UnivData>('univBox');

    // sortedUnivDataを取得（提供されたアクセス方法に合わせる）
    // ListenしないためValueListenableBuilderは使用しないが、データの最新性を保つなら考慮が必要
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    // 対象の大学データを取得
    // unividが配列のインデックスとして機能すると仮定
    if (univid < 0 || univid >= sortedUnivData.length) {
      return const Center(
        child: Text('大学データが見つかりません', style: TextStyle(color: Colors.white)),
      );
    }
    final UnivData univData = sortedUnivData[univid];

    // racebangouの配列境界チェック
    if (racebangou < 0 || racebangou >= univData.juni_race.length) {
      return const Center(
        child: Text('大会データが見つかりません', style: TextStyle(color: Colors.white)),
      );
    }

    String name_race = "";
    if (racebangou == 0) {
      name_race = "10月駅伝";
    }
    if (racebangou == 1) {
      name_race = "11月駅伝";
    }
    if (racebangou == 2) {
      name_race = "正月駅伝";
    }
    if (racebangou == 3) {
      name_race = "11月駅伝予選";
    }
    if (racebangou == 4) {
      name_race = "正月駅伝予選";
    }
    if (racebangou == 5) {
      name_race = sortedUnivData[0].name_tanshuku;
    }
    if (racebangou == 9) {
      name_race = "対校戦";
    }
    final List<int> recentJunis = univData.juni_race[racebangou];
    final List<double> recentTimes = univData.time_race[racebangou];
    final List<int> juniCounts = univData
        .taikaibetujunibetukaisuu[racebangou]; // 順位ごとの回数も同じ配列を使用すると仮定 (データ構造の記載に基づく)

    // 順位ごとの回数で表示する最大順位
    final int maxJuniCount = _getMaxJuniCount(racebangou);

    return Container(
      // 画面の90%を占める
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor, // 背景色 (constants.dartで定義と仮定)
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Containerの背景色を活かす
        appBar: AppBar(
          title: Text(
            '${univData.name} 大学成績',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
          //automaticallyImplyLeading: false,
          /*actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // モーダルを閉じる
              child: const Text(
                '閉じる',
                style: TextStyle(
                  color: HENSUU.LinkColor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),
          ],*/
        ),
        // セーフエリアとスクロール可能な本体
        body: SafeArea(
          child: Padding(
            // 画面の端に少し余裕を持たせる
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              children: <Widget>[
                Text(name_race + "\n"),
                // --- 直近10回の順位とタイム ---
                if (racebangou != 9) _buildSectionTitle('直近10回の順位とタイム 🏃‍♂️'),
                if (racebangou == 9) _buildSectionTitle('直近10回の順位 🏃‍♂️'),
                const SizedBox(height: 8),
                _buildRecentRecordsTable(
                  recentJunis.take(10).toList(),
                  recentTimes.take(10).toList(),
                ),

                const SizedBox(height: 24),
                // --- 順位ごとの回数 ---
                _buildSectionTitle('順位ごとの通算回数 🏆'),
                const SizedBox(height: 8),
                _buildJuniCountTable(juniCounts, maxJuniCount),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // セクションタイトルのヘルパーウィジェット
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: HENSUU.fontsize_honbun + 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 直近10回の順位とタイムのテーブルを構築するウィジェット
  Widget _buildRecentRecordsTable(List<int> junis, List<double> times) {
    return Table(
      border: TableBorder.all(color: Colors.white24, width: 1.0),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.5),
      },
      children: [
        // ヘッダー行
        TableRow(
          children: [
            _buildTableCell('回', isHeader: true),
            _buildTableCell('順位', isHeader: true),
            if (racebangou != 9) _buildTableCell('タイム', isHeader: true),
          ],
        ),
        // データ行
        ...List.generate(10, (index) {
          if (index >= junis.length || index >= times.length) {
            // データが10回分ない場合
            return TableRow(
              children: [
                _buildTableCell('${index + 1}回前'),
                _buildTableCell('---'),
                if (racebangou != 9) _buildTableCell('---'),
              ],
            );
          }

          final int juniCode = junis[index];
          final double time = times[index];

          String juniText;
          if (juniCode == TEISUU.DEFAULTJUNI) {
            juniText = '不出場';
          } else {
            // 0は1位、1は2位...
            juniText = '${juniCode + 1}位';
          }

          final timeText = _timeToJikanFunByouString(time);

          return TableRow(
            children: [
              _buildTableCell('${index + 1}回前'),
              _buildTableCell(
                juniText,
                isAttention: juniCode != -1 && juniCode < 3,
              ), // 3位以内を強調
              if (racebangou != 9) _buildTableCell(timeText),
            ],
          );
        }),
      ],
    );
  }

  // 順位ごとの回数のテーブルを構築するウィジェット
  Widget _buildJuniCountTable(List<int> juniCounts, int maxJuni) {
    // 1位からmaxJuni位までのデータのみを抽出
    final List<TableRow> rows = [];

    // ヘッダー行
    rows.add(
      TableRow(
        children: [
          _buildTableCell('順位', isHeader: true),
          _buildTableCell('回数', isHeader: true),
        ],
      ),
    );

    for (int i = 0; i < maxJuni; i++) {
      // iは配列インデックス (0が1位)
      final int rank = i + 1; // 順位 (1が1位)
      int count = 0;

      // 配列の境界チェック
      if (i < juniCounts.length) {
        // sortedUnivData[univid].juni_race[racebangou][順位] で回数を保存 (順位は0が1位, 29が30位)
        count = juniCounts[i];
      }

      rows.add(
        TableRow(
          children: [
            _buildTableCell('${rank}位'),
            _buildTableCell(
              '${count}回',
              isAttention: rank <= 3 && count > 0,
            ), // 3位以内かつ回数がある場合を強調
          ],
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.white24, width: 1.0),
      columnWidths: const {0: FlexColumnWidth(1.0), 1: FlexColumnWidth(1.0)},
      children: rows,
    );
  }

  // テーブルセルのヘルパーウィジェット
  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isAttention = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHeader
              ? Colors.yellow
              : isAttention
              ? Colors.lightGreenAccent
              : Colors.white,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }
}
