// lib/utils/time_date_utils.dart

class TimeDate {
  /// 秒数を「時間分秒」の形式の文字列に変換します。
  /// 例: 3661.0 -> "1時間01分01秒"
  static String timeToJikanFunByouString(double time) {
    // 時間を計算
    int jikanInt = (time / 3600).floor();
    // 残りの秒数から分を計算
    int funInt = ((time - jikanInt * 3600) / 60).floor();
    // 残りの秒数を計算
    int byouInt = (time - (jikanInt * 3600) - (funInt * 60)).floor();

    // Dartの文字列補間とpadLeftを使ってフォーマット
    return '${jikanInt}時間${funInt.toString().padLeft(2, '0')}分${byouInt.toString().padLeft(2, '0')}秒';
  }

  /// 秒数を「分秒」の形式の文字列に変換します。
  /// 例: 61.0 -> "1分01秒"
  static String timeToFunByouString(double time) {
    // 分を計算
    int funInt = (time / 60).floor();
    // 残りの秒数を計算
    int byouInt = (time - (funInt * 60)).floor();

    // Dartの文字列補間とpadLeftを使ってフォーマット
    return '${funInt}分${byouInt.toString().padLeft(2, '0')}秒';
  }

  /// 日付の数値（5, 15, 25）を「上旬、中旬、下旬」の文字列に変換します。
  /// 該当しない場合は"??"を返します。
  static String dayToString(int day) {
    String returnString = "??";
    if (day == 5) {
      returnString = "上旬";
    } else if (day == 15) {
      returnString = "中旬";
    } else if (day == 25) {
      returnString = "下旬";
    }
    return returnString;
  }
}
