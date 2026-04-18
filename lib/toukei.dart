/// 駅伝の統計データを保持するクラスです。（シングルトン）
class EkidenStatistics {
  // 1. staticなプライベート変数で唯一のインスタンスを保持
  static final EkidenStatistics _instance = EkidenStatistics._internal();

  // 2. staticなゲッターでどこからでもインスタンスにアクセスできるようにする
  static EkidenStatistics get instance => _instance;

  // 駅伝の定数定義
  static const int EKIDEN_OCTOBER = 0; // 10月駅伝
  static const int EKIDEN_NOVEMBER = 1; // 11月駅伝
  static const int EKIDEN_NEW_YEAR = 2; // 正月駅伝
  static const int EKIDEN_NOVEMBER_YOSEN = 3; // 11月駅伝予選
  static const int EKIDEN_NEW_YEAR_YOSEN = 4; // 正月駅伝予選
  static const int EKIDEN_CUSTOM = 5; // カスタム駅伝
  static const List<String> _ekidenNames = [
    '10月駅伝',
    '11月駅伝',
    '正月駅伝',
    '11月駅伝予選',
    '正月駅伝予選',
    'カスタム駅伝',
  ];

  // 各駅伝の区間数を定義 (インデックスはEKIDEN_XXXに対応)
  static const List<int> _sectionCounts = [
    6,
    8,
    10,
    4,
    1,
    10,
  ]; // 10月:6, 11月:8, 正月:10

  /// 統計データを保持する二次元リスト。
  /// _stats[駅伝番号][区間番号] でアクセスします。
  /// 駅伝番号: 0=10月, 1=11月, 2=正月
  /// 区間番号: 0=1区, 1=2区, ...
  final List<List<SectionStats>> _stats;

  /// プライベートコンストラクタで外部からの自由なインスタンス生成を禁止
  EkidenStatistics._internal() : _stats = [] {
    // コンストラクタ内で、全ての駅伝の区間に対する統計データを初期化
    for (int i = 0; i < _ekidenNames.length; i++) {
      final sectionCount = _sectionCounts[i];
      final List<SectionStats> ekidenStats = [];
      for (int j = 0; j < sectionCount; j++) {
        ekidenStats.add(SectionStats());
      }
      _stats.add(ekidenStats);
    }
  }

  /// 特定の駅伝・区間の統計データにアクセスするためのゲッター（プロパティ）です。
  /// 例: stats[0][0] は 10月駅伝の1区の統計
  List<List<SectionStats>> get stats => _stats;

  /// 駅伝番号に対応する区間数を取得します。
  static int getSectionCount(int ekidenIndex) {
    if (ekidenIndex < 0 || ekidenIndex >= _sectionCounts.length) {
      throw RangeError('無効な駅伝番号です: $ekidenIndex');
    }
    return _sectionCounts[ekidenIndex];
  }

  /// 統計データを更新（追加）します。
  void updateStats({
    required int ekidenIndex,
    required int sectionIndex,
    required double fastestTime,
    required double worstTime,
    required double averageTime,
  }) {
    if (ekidenIndex < 0 || ekidenIndex >= _stats.length) {
      throw RangeError('無効な駅伝番号です: $ekidenIndex');
    }
    if (sectionIndex < 0 || sectionIndex >= _stats[ekidenIndex].length) {
      throw RangeError('無効な区間番号です: $sectionIndex (駅伝番号: $ekidenIndex)');
    }

    final stats = _stats[ekidenIndex][sectionIndex];
    stats.addResult(fastestTime, worstTime, averageTime);
  }

  /// 全ての統計データをリセットし、初期状態に戻します。
  void resetAllStats() {
    for (int i = 0; i < _stats.length; i++) {
      final sectionCount = _sectionCounts[i];
      // 各駅伝のリストをクリアして、新しいSectionStatsで埋め直す
      _stats[i].clear();
      for (int j = 0; j < sectionCount; j++) {
        _stats[i].add(SectionStats());
      }
    }
  }

  // デバッグや保存のために統計全体をMapとして取得するメソッド
  Map<String, Map<String, List<Map<String, dynamic>>>> toMap() {
    final Map<String, List<Map<String, dynamic>>> result = {};

    for (int i = 0; i < _ekidenNames.length; i++) {
      final ekidenName = _ekidenNames[i];
      final List<Map<String, dynamic>> sectionList = _stats[i]
          .asMap()
          .entries
          .map(
            (entry) => {
              'section': entry.key + 1, // 1区、2区として表示
              ...entry.value.toMap(),
            },
          )
          .toList();
      result[ekidenName] = sectionList;
    }
    return {'ekiden_data': result};
  }
}

/// 各区間ごとの統計データを保持するクラスです。
class SectionStats {
  /// 最速タイムの合計（平均算出用）
  double _totalFastestTime = 0.0;

  /// ワーストタイムの合計（平均算出用）
  double _totalWorstTime = 0.0;

  /// 平均タイムの合計（平均算出用）
  double _totalAverageTime = 0.0;

  /// データが追加された回数（平均算出用）
  int _runCount = 0;

  /// 平均最速タイム（秒）
  double get averageFastestTime {
    return _runCount > 0 ? _totalFastestTime / _runCount : 0.0;
  }

  /// 平均ワーストタイム（秒）
  double get averageWorstTime {
    return _runCount > 0 ? _totalWorstTime / _runCount : 0.0;
  }

  /// 平均平均タイム（秒）
  double get averageAverageTime {
    return _runCount > 0 ? _totalAverageTime / _runCount : 0.0;
  }

  /// データが追加された回数
  int get runCount => _runCount;

  /// 今回のレース結果を統計に追加します。
  void addResult(double fastestTime, double worstTime, double averageTime) {
    if (fastestTime < 0 || worstTime < 0) {
      throw ArgumentError('タイムは負の値にできません。');
    }
    _totalFastestTime += fastestTime;
    _totalWorstTime += worstTime;
    _totalAverageTime += averageTime;
    _runCount++;
  }

  // デバッグや保存のために統計をMapとして取得するメソッド
  Map<String, dynamic> toMap() {
    return {
      'averageFastestTime': averageFastestTime,
      'averageWorstTime': averageWorstTime,
      'averageAvarageTime': averageAverageTime,
      'runCount': _runCount,
    };
  }
}
