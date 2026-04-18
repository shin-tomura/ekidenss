import 'package:ekiden/senshu_data.dart';

class FilteredPlayer {
  final int id;
  final int gakunen; // 学年
  final int univid; // 大学ID（念のため）

  // 必要なプロパティのみ（Hive参照なし）。entrykukan_raceはフィルタ用にメインで使うのでここでは不要
  FilteredPlayer({
    required this.id,
    required this.gakunen,
    required this.univid,
  });

  // from SenshuData 変換用ファクトリ
  factory FilteredPlayer.fromSenshuData(SenshuData data) {
    return FilteredPlayer(
      id: data.id,
      gakunen: data.gakunen,
      univid: data.univid,
    );
  }

  // デバッグ用
  @override
  String toString() => 'Player(id: $id, gakunen: $gakunen, univ: $univid)';
}
