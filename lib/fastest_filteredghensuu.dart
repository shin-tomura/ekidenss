import 'package:ekiden/ghensuu.dart';

class FilteredGhensuu {
  final int hyojiracebangou; // 必要なフィールドのみ（Hive参照なし）

  FilteredGhensuu({required this.hyojiracebangou});

  // from Ghensuu 変換用ファクトリ
  factory FilteredGhensuu.fromGhensuu(Ghensuu data) {
    return FilteredGhensuu(hyojiracebangou: data.hyojiracebangou);
  }

  // デバッグ用
  @override
  String toString() => 'Ghensuu(race: $hyojiracebangou)';
}
