import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/meisei_henshuu.dart' show meiseiJuniTsukeNaoshi;

// ------------------------------------------------------------
// コンピュータの大学の名声を固定する(2.0.3。説明画面の設定タブの「名声の横並び設定」の画面で選ぶ)
//
// 作った勢力図(名声の編集や名声の横並び)を、コンピュータの大学の成績で崩さないための設定。
// ・名声は「年ごとの名声(meisei_yeargoto。10年分)」と「その合計(meisei_total)」の2段で持っていて、
//   スカウト・大学画面・名声一覧・記事・名声の順位は、どれも合計を読んでいる
// ・固定するときは、合計を計算し直す3か所(KirokuKousin.dart の駅伝のあと・インカレのあと、
//   RetireNew.dart の年度替わり)で、コンピュータの大学の合計だけを計算し直さない。
//   駅伝などで得た名声は今まで通り年ごとの名声に足し、年度替わりのずらしも今まで通り行う(実際の記録は残る)
// ・名声を足すところ(駅伝・インカレ・学連選抜など)には触らない。固定した値は合計そのものなので、置き場所は要らない
// ・名声設定や名声の横並び設定の画面で名声を変えると、その値が固定の値になる
// ・あなたの大学は今まで通り動く(自分の大学を別の大学に変えると、前の大学はその時点の名声で固定され、
//   新しい大学は次に合計を計算し直すときに本当の名声に戻る)
// ・固定をやめたときは、すぐに年ごとの名声から合計を計算し直し、名声の順位も付け直す(meiseiGoukeiKeisanNaoshi)
// ・保存: KantokuData.yobiint3[89](0=固定しない(初期値)・1=固定する)。名声・育成力と設定を残すリセットで残し(reset_ichiran.dart)、
//   各種設定のQRコードに含める
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: コンピュータの大学の名声を固定するか
const int meiseiKoteiIndex = 89;

/// 保存する値として正しいか(QRコードの読み込みで使う)
bool meiseiKoteiTadashii(int v) => v == 0 || v == 1;

/// 保存してある値(正しくなければ0)
int meiseiKoteiAtai(KantokuData? k) {
  if (k == null || k.yobiint3.length <= meiseiKoteiIndex) return 0;
  final int v = k.yobiint3[meiseiKoteiIndex];
  return meiseiKoteiTadashii(v) ? v : 0;
}

/// 保存する値を入れる(正しくない値は0。保存(save)は呼び出し側で行う)
void meiseiKoteiAtaiIreru(KantokuData k, int v) {
  if (k.yobiint3.length <= meiseiKoteiIndex) return;
  k.yobiint3[meiseiKoteiIndex] = meiseiKoteiTadashii(v) ? v : 0;
}

/// コンピュータの大学の名声を固定しているか
bool meiseiKotei(KantokuData? k) => meiseiKoteiAtai(k) == 1;

/// 名声の合計を計算し直すときに、大学[univid]の合計をそのままにするか
/// (固定していて、あなたの大学でないとき)
bool meiseiGoukeiNokosu(KantokuData? k, int univid, int myUnivId) =>
    meiseiKotei(k) && univid != myUnivId;

/// 全大学の名声の合計を、年ごとの名声(10年分)から計算し直し、名声の順位も付け直す
/// (固定をやめたときに使う。保存もする)
Future<void> meiseiGoukeiKeisanNaoshi() async {
  final Box<UnivData> box = Hive.box<UnivData>('univBox');
  for (final UnivData u in box.values) {
    int goukei = 0;
    for (int ii = 0; ii < TEISUU.MEISEIHOZONNENSUU && ii < u.meisei_yeargoto.length; ii++) {
      goukei += u.meisei_yeargoto[ii];
    }
    if (u.meisei_total != goukei) {
      u.meisei_total = goukei;
      await u.save();
    }
  }
  await meiseiJuniTsukeNaoshi();
}
