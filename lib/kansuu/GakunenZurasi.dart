import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
// import 'package:ekiden/constants.dart'; // TEISUU.SENSHUSUU_TOTAL が定義されている場合

/// 指定された学年の選手を新しい学年にずらします。
///
/// この関数は、`sortedsenshudata` リスト内の選手データの中から、
/// `gakunenfrom` に合致する選手の学年を `gakunento` に変更し、
/// その変更をHiveに永続化します。
///
/// [sortedsenshudata]: ID順にソートされた選手データのリスト。変更されたデータはHiveに保存されます。
/// [gakunenfrom]: 学年を変更したい現在の学年。
/// [gakunento]: 学年を変更したい新しい学年。
Future<void> GakunenZurasi({
  required List<SenshuData> sortedsenshudata,
  required int gakunenfrom,
  required int gakunento,
}) async {
  // Swiftの TEISUU.SENSHUSUU_TOTAL に相当する部分。
  // Dartでは、リストの長さを直接使うのが一般的です。
  // もし TEISUU.SENSHUSUU_TOTAL がリストの最大サイズを表す場合は、
  // for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) となります。
  // ここではリストの現在の要素数を使用します。
  for (int i = 0; i < sortedsenshudata.length; i++) {
    // Dartでは 'switch' 文は通常、より複雑な条件やEnum値に使われます。
    // このような単純な比較の場合は 'if' 文がより一般的で読みやすいです。
    if (sortedsenshudata[i].gakunen == gakunenfrom) {
      sortedsenshudata[i].gakunen = gakunento;
      // 変更をHiveに保存します
      // HiveのKeyをIDとして持っている SenshuData の場合、
      // put(key, value) で更新できます。
      await sortedsenshudata[i].save();
    }
  }
}
