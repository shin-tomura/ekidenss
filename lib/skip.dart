import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'skip.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 5) // ユニークなtypeIdを指定
class Skip extends HiveObject {
  @HiveField(0)
  int skipflag = 0; //1→個人記録取るだけスキップ、2→全てやるスキップ、3→リリース用スキップ(わざとdelayで負荷軽減)
  @HiveField(1)
  int skipyear = 100;
  @HiveField(2)
  int skipmonth = 3;
  @HiveField(3)
  int skipday = 25;

  //[0→5000、1→10000、2→half、3→full]
  @HiveField(4)
  List<double> totaltime_jap_all = List.filled(4, 0.0);
  @HiveField(5)
  List<double> totaltime_jap_13pundai = List.filled(4, 0.0);
  @HiveField(6)
  List<double> totaltime_jap_14pun00dai = List.filled(4, 0.0);
  @HiveField(7)
  List<double> totaltime_jap_14pun10dai = List.filled(4, 0.0);
  @HiveField(8)
  List<double> totaltime_jap_14pun20dai = List.filled(4, 0.0);
  @HiveField(9)
  List<double> totaltime_jap_14pun30dai = List.filled(4, 0.0);
  @HiveField(10)
  List<double> totaltime_jap_14pun40dai = List.filled(4, 0.0);
  @HiveField(11)
  List<double> totaltime_jap_14pun50dai = List.filled(4, 0.0);
  @HiveField(12)
  List<double> totaltime_jap_15pundai = List.filled(4, 0.0);
  @HiveField(13)
  List<int> count_jap_all = List.filled(4, 0);
  @HiveField(14)
  List<int> count_jap_13pundai = List.filled(4, 0);
  @HiveField(15)
  List<int> count_jap_14pun00dai = List.filled(4, 0);
  @HiveField(16)
  List<int> count_jap_14pun10dai = List.filled(4, 0);
  @HiveField(17)
  List<int> count_jap_14pun20dai = List.filled(4, 0);
  @HiveField(18)
  List<int> count_jap_14pun30dai = List.filled(4, 0);
  @HiveField(19)
  List<int> count_jap_14pun40dai = List.filled(4, 0);
  @HiveField(20)
  List<int> count_jap_14pun50dai = List.filled(4, 0);
  @HiveField(21)
  List<int> count_jap_15pundai = List.filled(4, 0);
  @HiveField(22)
  List<double> totaltime_ryuugakusei = List.filled(4, 0.0);
  @HiveField(23)
  List<int> count_ryuugakusei = List.filled(4, 0);

  @HiveField(24)
  List<double> besttime_ryuugakusei = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(25)
  List<double> besttime_jap_all = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(26)
  List<double> besttime_jap_13pundai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(27)
  List<double> besttime_jap_14pun00dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(28)
  List<double> besttime_jap_14pun10dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(29)
  List<double> besttime_jap_14pun20dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(30)
  List<double> besttime_jap_14pun30dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(31)
  List<double> besttime_jap_14pun40dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(32)
  List<double> besttime_jap_14pun50dai = List.filled(4, TEISUU.DEFAULTTIME);
  @HiveField(33)
  List<double> besttime_jap_15pundai = List.filled(4, TEISUU.DEFAULTTIME);

  // コンストラクタ (Swiftのinit()に対応)
  Skip(); // 引数なしのコンストラクタ

  // 小数点以下 15 桁で丸めるヘルパー関数
  double _roundDouble(double value) {
    // 15 桁を指定して丸め処理を実行
    return double.parse(value.toStringAsFixed(15));
  }

  // List<double> のすべての要素を丸めるヘルパー関数
  List<double> _roundDoubleList(List<double> list) {
    return list.map((e) => _roundDouble(e)).toList();
  }

  // List<List<double>> のすべての要素を丸めるヘルパー関数
  List<List<double>> _roundDoubleNestedList(List<List<double>> nestedList) {
    return nestedList.map((list) => _roundDoubleList(list)).toList();
  }
  // Skip クラス内 (修正後の toJson() のみ)

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (List<double>に丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    return {
      'skipflag': skipflag,
      'skipyear': skipyear,
      'skipmonth': skipmonth,
      'skipday': skipday,
      // ★修正: List<double> に _roundDoubleList を適用 (合計タイム)
      'totaltime_jap_all': _roundDoubleList(totaltime_jap_all),
      'totaltime_jap_13pundai': _roundDoubleList(totaltime_jap_13pundai),
      'totaltime_jap_14pun00dai': _roundDoubleList(totaltime_jap_14pun00dai),
      'totaltime_jap_14pun10dai': _roundDoubleList(totaltime_jap_14pun10dai),
      'totaltime_jap_14pun20dai': _roundDoubleList(totaltime_jap_14pun20dai),
      'totaltime_jap_14pun30dai': _roundDoubleList(totaltime_jap_14pun30dai),
      'totaltime_jap_14pun40dai': _roundDoubleList(totaltime_jap_14pun40dai),
      'totaltime_jap_14pun50dai': _roundDoubleList(totaltime_jap_14pun50dai),
      'totaltime_jap_15pundai': _roundDoubleList(totaltime_jap_15pundai),

      'count_jap_all': count_jap_all,
      'count_jap_13pundai': count_jap_13pundai,
      'count_jap_14pun00dai': count_jap_14pun00dai,
      'count_jap_14pun10dai': count_jap_14pun10dai,
      'count_jap_14pun20dai': count_jap_14pun20dai,
      'count_jap_14pun30dai': count_jap_14pun30dai,
      'count_jap_14pun40dai': count_jap_14pun40dai,
      'count_jap_14pun50dai': count_jap_14pun50dai,
      'count_jap_15pundai': count_jap_15pundai,

      // ★修正: List<double> に _roundDoubleList を適用 (留学生)
      'totaltime_ryuugakusei': _roundDoubleList(totaltime_ryuugakusei),
      'count_ryuugakusei': count_ryuugakusei,
      'besttime_ryuugakusei': _roundDoubleList(besttime_ryuugakusei),

      // ★修正: List<double> に _roundDoubleList を適用 (ベストタイム)
      'besttime_jap_all': _roundDoubleList(besttime_jap_all),
      'besttime_jap_13pundai': _roundDoubleList(besttime_jap_13pundai),
      'besttime_jap_14pun00dai': _roundDoubleList(besttime_jap_14pun00dai),
      'besttime_jap_14pun10dai': _roundDoubleList(besttime_jap_14pun10dai),
      'besttime_jap_14pun20dai': _roundDoubleList(besttime_jap_14pun20dai),
      'besttime_jap_14pun30dai': _roundDoubleList(besttime_jap_14pun30dai),
      'besttime_jap_14pun40dai': _roundDoubleList(besttime_jap_14pun40dai),
      'besttime_jap_14pun50dai': _roundDoubleList(besttime_jap_14pun50dai),
      'besttime_jap_15pundai': _roundDoubleList(besttime_jap_15pundai),
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'skipflag': skipflag,
      'skipyear': skipyear,
      'skipmonth': skipmonth,
      'skipday': skipday,
      'totaltime_jap_all': totaltime_jap_all,
      'totaltime_jap_13pundai': totaltime_jap_13pundai,
      'totaltime_jap_14pun00dai': totaltime_jap_14pun00dai,
      'totaltime_jap_14pun10dai': totaltime_jap_14pun10dai,
      'totaltime_jap_14pun20dai': totaltime_jap_14pun20dai,
      'totaltime_jap_14pun30dai': totaltime_jap_14pun30dai,
      'totaltime_jap_14pun40dai': totaltime_jap_14pun40dai,
      'totaltime_jap_14pun50dai': totaltime_jap_14pun50dai,
      'totaltime_jap_15pundai': totaltime_jap_15pundai,
      'count_jap_all': count_jap_all,
      'count_jap_13pundai': count_jap_13pundai,
      'count_jap_14pun00dai': count_jap_14pun00dai,
      'count_jap_14pun10dai': count_jap_14pun10dai,
      'count_jap_14pun20dai': count_jap_14pun20dai,
      'count_jap_14pun30dai': count_jap_14pun30dai,
      'count_jap_14pun40dai': count_jap_14pun40dai,
      'count_jap_14pun50dai': count_jap_14pun50dai,
      'count_jap_15pundai': count_jap_15pundai,
      'totaltime_ryuugakusei': totaltime_ryuugakusei,
      'count_ryuugakusei': count_ryuugakusei,
      'besttime_ryuugakusei': besttime_ryuugakusei,
      'besttime_jap_all': besttime_jap_all,
      'besttime_jap_13pundai': besttime_jap_13pundai,
      'besttime_jap_14pun00dai': besttime_jap_14pun00dai,
      'besttime_jap_14pun10dai': besttime_jap_14pun10dai,
      'besttime_jap_14pun20dai': besttime_jap_14pun20dai,
      'besttime_jap_14pun30dai': besttime_jap_14pun30dai,
      'besttime_jap_14pun40dai': besttime_jap_14pun40dai,
      'besttime_jap_14pun50dai': besttime_jap_14pun50dai,
      'besttime_jap_15pundai': besttime_jap_15pundai,
    };
  }*/

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory Skip.fromJson(Map<String, dynamic> json) {
    return Skip()
      ..skipflag = json['skipflag'] as int
      ..skipyear = json['skipyear'] as int
      ..skipmonth = json['skipmonth'] as int
      ..skipday = json['skipday'] as int
      ..totaltime_jap_all = (json['totaltime_jap_all'] as List).cast<double>()
      ..totaltime_jap_13pundai = (json['totaltime_jap_13pundai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun00dai = (json['totaltime_jap_14pun00dai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun10dai = (json['totaltime_jap_14pun10dai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun20dai = (json['totaltime_jap_14pun20dai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun30dai = (json['totaltime_jap_14pun30dai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun40dai = (json['totaltime_jap_14pun40dai'] as List)
          .cast<double>()
      ..totaltime_jap_14pun50dai = (json['totaltime_jap_14pun50dai'] as List)
          .cast<double>()
      ..totaltime_jap_15pundai = (json['totaltime_jap_15pundai'] as List)
          .cast<double>()
      ..count_jap_all = (json['count_jap_all'] as List).cast<int>()
      ..count_jap_13pundai = (json['count_jap_13pundai'] as List).cast<int>()
      ..count_jap_14pun00dai = (json['count_jap_14pun00dai'] as List)
          .cast<int>()
      ..count_jap_14pun10dai = (json['count_jap_14pun10dai'] as List)
          .cast<int>()
      ..count_jap_14pun20dai = (json['count_jap_14pun20dai'] as List)
          .cast<int>()
      ..count_jap_14pun30dai = (json['count_jap_14pun30dai'] as List)
          .cast<int>()
      ..count_jap_14pun40dai = (json['count_jap_14pun40dai'] as List)
          .cast<int>()
      ..count_jap_14pun50dai = (json['count_jap_14pun50dai'] as List)
          .cast<int>()
      ..count_jap_15pundai = (json['count_jap_15pundai'] as List).cast<int>()
      ..totaltime_ryuugakusei = (json['totaltime_ryuugakusei'] as List)
          .cast<double>()
      ..count_ryuugakusei = (json['count_ryuugakusei'] as List).cast<int>()
      ..besttime_ryuugakusei = (json['besttime_ryuugakusei'] as List)
          .cast<double>()
      ..besttime_jap_all = (json['besttime_jap_all'] as List).cast<double>()
      ..besttime_jap_13pundai = (json['besttime_jap_13pundai'] as List)
          .cast<double>()
      ..besttime_jap_14pun00dai = (json['besttime_jap_14pun00dai'] as List)
          .cast<double>()
      ..besttime_jap_14pun10dai = (json['besttime_jap_14pun10dai'] as List)
          .cast<double>()
      ..besttime_jap_14pun20dai = (json['besttime_jap_14pun20dai'] as List)
          .cast<double>()
      ..besttime_jap_14pun30dai = (json['besttime_jap_14pun30dai'] as List)
          .cast<double>()
      ..besttime_jap_14pun40dai = (json['besttime_jap_14pun40dai'] as List)
          .cast<double>()
      ..besttime_jap_14pun50dai = (json['besttime_jap_14pun50dai'] as List)
          .cast<double>()
      ..besttime_jap_15pundai = (json['besttime_jap_15pundai'] as List)
          .cast<double>();
  }
}
