import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'Shuudansou.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 4) // ユニークなtypeIdを指定
class Shuudansou extends HiveObject {
  @HiveField(0)
  List<double> sisoutime = List.filled(TEISUU.SENSHUSUU_TOTAL, 0.0);
  @HiveField(1)
  List<double> setteitime = List.filled(6, 0.0);
  @HiveField(2)
  List<int> sijioption_fun = List.filled(6, 0);
  @HiveField(3)
  List<int> sijioption_byou = List.filled(6, 0);

  // コンストラクタ (Swiftのinit()に対応)
  Shuudansou(); // 引数なしのコンストラクタ

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
  // Shuudansou クラス内 (修正後の toJson() のみ)

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (Double型の丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    return {
      // ★修正: List<double> に _roundDoubleList を適用
      'sisoutime': _roundDoubleList(sisoutime),
      'setteitime': _roundDoubleList(setteitime),
      'sijioption_fun': sijioption_fun,
      'sijioption_byou': sijioption_byou,
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'sisoutime': sisoutime,
      'setteitime': setteitime,
      'sijioption_fun': sijioption_fun,
      'sijioption_byou': sijioption_byou,
    };
  }*/

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory Shuudansou.fromJson(Map<String, dynamic> json) {
    return Shuudansou()
      ..sisoutime = (json['sisoutime'] as List).cast<double>()
      ..setteitime = (json['setteitime'] as List).cast<double>()
      ..sijioption_fun = (json['sijioption_fun'] as List).cast<int>()
      ..sijioption_byou = (json['sijioption_byou'] as List).cast<int>();
  }
}
