import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/kansuu/yosen_omakase.dart';

// ------------------------------------------------------------
// 正月駅伝予選の、コンピュータの大学の指示と集団走(1.9.9)
//
// ・コンピュータの大学は、レース画面の「おまかせで組む」(yosen_omakase.dart)と同じ組み方で、
//   フリー走(前半突っ込み・前半抑え)・集団走A〜Fと、集団ごとの設定タイムを決める
// ・組むのに使う試走タイムは、区間エントリーのときに保存した値(Shuudansou.sisoutime)。
//   プレイヤーの画面に出ているのと同じ、±0.5%の濁しが入った値で、本当のタイムは使わない
//   (プレイヤーと同じ情報で組むため)。同じ値からは毎回同じ組み方になるので、
//   設定タイムは保存せず、レースの計算(RaceCalc.dart)のときに作る
// ・スキップ中は指示の画面を通らないので、プレイヤーの大学も同じ組み方で組む
// ・前半突っ込み・前半抑えの成否は、プレイヤーの大学と同じ決まり(駅伝男・平常心の確率)で引く
// ・KantokuData.yobiint2[89] 0=組む(初期値)・1=組まない(1.9.8までと同じく、コンピュータの大学と
//   スキップ中のプレイヤーの大学は、全員フリー走で指示なし)。
//   設定タブの「正月駅伝予選の指示と集団走」(screens/yosen_com_siji_settei.dart)で変え、
//   各種設定のQRコードにも含める
// ------------------------------------------------------------

const int yosenComSijiIndex = 89;

/// 正月駅伝予選の大会番号
const int _yosenRace = 4;

/// コンピュータの大学も正月駅伝予選で指示と集団走を使うか(0=使う(初期値)・1=使わない)
bool yosenComSijiAri(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= yosenComSijiIndex) return true;
  return kantoku.yobiint2[yosenComSijiIndex] != 1;
}

/// yobiint2に保存する値として正しいか(QRコードの読み込みで使う)
bool yosenComSijiAtaiTadashii(int atai) => atai == 0 || atai == 1;

/// 設定を保存する([ari]がtrueなら使う)
Future<void> yosenComSijiHozon(KantokuData kantoku, bool ari) async {
  if (kantoku.yobiint2.length <= yosenComSijiIndex) return;
  kantoku.yobiint2[yosenComSijiIndex] = ari ? 0 : 1;
  await kantoku.save();
}

/// 正月駅伝予選で、おまかせで組む大学のid
/// (出場するコンピュータの大学と、スキップ中ならプレイヤーの大学。設定が「使わない」なら空)
Set<int> yosenOmakaseUniv({
  required KantokuData kantoku,
  required List<UnivData> univs,
  required int myUnivid,
}) {
  final Set<int> kekka = {};
  if (!yosenComSijiAri(kantoku)) return kekka;
  final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
  final bool skipChuu = skip != null && skip.skipflag != 0;
  for (final UnivData u in univs) {
    if (u.taikaientryflag.length <= _yosenRace ||
        u.taikaientryflag[_yosenRace] != 1) {
      continue;
    }
    if (u.id == myUnivid && !skipChuu) continue;
    kekka.add(u.id);
  }
  return kekka;
}

/// [univid]の大学の正月駅伝予選の指示と集団を、おまかせで組む
/// ・走る選手の sijiflag(0フリー走・1前半突っ込み・2前半抑え・3〜8集団走A〜F)と、
///   sijiseikouflag(前半突っ込み・前半抑えの成否)を書く(保存はしない。レースの計算のあとにまとめて保存される)
/// ・試走タイムがない選手(0以下)は、フリー走のままにする
/// ・集団A〜Fの設定タイム(秒。使わない集団は TEISUU.DEFAULTTIME)を返す
List<double> yosenOmakaseKumu({
  required int univid,
  required List<SenshuData> senshu,
  required Shuudansou shuudansou,
  required Random random,
}) {
  final List<SenshuData> hashiru = senshu.where((s) {
    return s.univid == univid &&
        s.gakunen >= 1 &&
        s.entrykukan_race.length > _yosenRace &&
        s.entrykukan_race[_yosenRace].length >= s.gakunen &&
        s.entrykukan_race[_yosenRace][s.gakunen - 1] == 0;
  }).toList();
  final List<YosenOmakaseSenshu> taishou = [];
  for (final SenshuData s in hashiru) {
    if (s.id < 0 || s.id >= shuudansou.sisoutime.length) continue;
    final double sisou = shuudansou.sisoutime[s.id];
    if (sisou <= 0) continue;
    taishou.add(
      YosenOmakaseSenshu(
        bangou: s.id,
        sisou: sisou,
        konjou: s.konjou,
        heijousin: s.heijousin,
      ),
    );
  }
  final YosenOmakaseKekka kekka = yosenOmakase(taishou);
  for (final SenshuData s in hashiru) {
    s.sijiflag = kekka.sentaku[s.id] ?? 0;
    s.sijiseikouflag = 0;
    // 前半突っ込み・前半抑えの成否(プレイヤーの大学は、レース画面で確定したときに引いている)
    if (s.sijiflag == 1 && random.nextInt(100) < s.konjou) {
      s.sijiseikouflag = 1;
    }
    if (s.sijiflag == 2 && random.nextInt(100) < s.heijousin) {
      s.sijiseikouflag = 1;
    }
  }
  final List<double> setteitime = List.filled(6, TEISUU.DEFAULTTIME);
  for (int g = 0; g < setteitime.length && g < kekka.setteiByou.length; g++) {
    final int? t = kekka.setteiByou[g];
    if (t != null) setteitime[g] = t.toDouble();
  }
  return setteitime;
}
