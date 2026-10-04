import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/skip.dart';

// ------------------------------------------------------------
// 学連選抜の監督(1.8.2)
//
// プレイヤーの大学が正月駅伝に出場できない年に、プレイヤーが学連選抜の監督になれる。
// ・KantokuData.yobiint2[75] 学連選抜の監督をするか(0=する(初期値)、1=しない)
//   学連選抜編成の画面(mode0290.dart)で切り替えられ、各種設定のQRコードにも含める
// ・監督をする年は、学連選抜編成の画面から区間配置を決められる(Modal_GakurenKukanHenshuu.dart)
// ・レース中は、レース画面(mode0350_content.dart)が自動で進まずに学連選抜の監督の表示になり、
//   走る学連選抜の選手に指示を出せる(選手のsijiflagと、1区はstartchokugotobidasiflagに保存し、
//   RaceCalc_gakuren.dartで大学の選手と同じ倍率で補正する。2区以降は損得予測も見られる)
// ・スキップ中は学連選抜編成の画面もレース画面も通らないので、今まで通りコンピュータが
//   決めた区間配置のままで、指示も出ない
// ・KantokuData.yobiint2[76] 学連選抜の目標順位(0=10位(初期値)、1〜=その順位)
//   監督をする年は、学連選抜編成の画面と正月駅伝の6区のスタート前(レース画面)で決められる。
//   毎年、学連選抜を作るとき(EntryCalc.dart)に10位に戻す。各種設定のQRコードには入れない
//   (その年ごとの作戦なので)。監督をしている年は大学と同じく、目標を上回るとほっと一息があり、
//   正月駅伝の6区は判定しない。コンピュータが監督のときは今まで通りいつも10位で、ほっと一息はない
// ------------------------------------------------------------

const int gakurenKantokuIndex = 75;

/// 学連選抜の監督をする設定か(0=する(初期値)、1=しない)
bool gakurenKantokuSettei(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= gakurenKantokuIndex) return true;
  return kantoku.yobiint2[gakurenKantokuIndex] != 1;
}

/// yobiint2に保存する値として正しいか(QRコードの読み込みで使う)
bool gakurenKantokuAtaiTadashii(int atai) {
  return atai == 0 || atai == 1;
}

/// 1.8.1までのセーブデータを、正月駅伝の日(1月5日)のレースが終わる前に再開したときの移行処理(1.8.2)
/// main.dart と save_load_screen.dart の「checkversionValue < 21820」の処理から呼ぶ。
/// ・まだ走っていない学連選抜の選手の、指示の印と補正の説明を消す
///   (1.8.1までは学連選抜の選手を作るときに、元の選手の正月駅伝予選の補正の説明が残っていた。
///    1.7.9までに作られた学連選抜の選手には、元の選手の11月駅伝の指示の印が残っていることもある。
///    1.8.2からは学連選抜の監督が指示を出し、その内容と補正の説明をレース画面に出すため)
/// ・まだ走っていない体調不良(調子0)の学連選抜の選手の調子を引き直す(gakurenTaichouFuryouNashiを参照)
/// ・すでに走った選手の結果はそのまま
Future<void> gakurenKantokuIkou({required Ghensuu gh}) async {
  if (!(gh.month == 1 && gh.day == 5)) return;
  // まだ走っていない区間の始まり
  final int madaKukan;
  if (gh.mode == 350 || gh.mode == 400) {
    madaKukan = gh.nowracecalckukan; // レース中: 次に計算する区間から
  } else if ([110, 120, 200, 280, 290, 300, 330, 340, 343].contains(gh.mode)) {
    madaKukan = 0; // レースの前
  } else {
    return; // レースが終わった後など
  }
  final Box<Senshu_Gakuren_Data> box = Hive.box<Senshu_Gakuren_Data>(
    'gakurenSenshuBox',
  );
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  final Random random = Random();
  final Map<dynamic, Senshu_Gakuren_Data> kakikae = {};
  for (final dynamic key in box.keys) {
    final Senshu_Gakuren_Data? s = box.get(key);
    if (s == null) continue;
    if (s.entrykukan_race.length <= 2 ||
        s.entrykukan_race[2].length < s.gakunen ||
        s.gakunen < 1) {
      continue;
    }
    final int entry = s.entrykukan_race[2][s.gakunen - 1];
    if (entry >= 0 && entry < madaKukan) continue; // すでに走った選手
    s.sijiflag = 0;
    s.sijiseikouflag = 0;
    s.startchokugotobidasiflag = 0;
    s.startchokugotobidasiseikouflag = 0;
    s.string_racesetumei = "";
    if (kantoku != null) gakurenTaichouFuryouNashi(s, kantoku, random);
    kakikae[key] = s;
  }
  if (kakikae.isNotEmpty) await box.putAll(kakikae);
}

/// 学連選抜の選手は体調不良(調子0)にしない(1.8.2)
/// 学連選抜は不出場の大学から1人ずつ選ぶ10人で補欠がいないので、体調不良でもそのまま走るしかない。
/// そのため、学連選抜を作るときに元の選手から写した調子が0なら、体調不良の抽選だけを外した
/// 普通の決め方(区間エントリー時ピーキング成功確率で100、それ以外は安定感〜99)で引き直す。
/// 元の大学の選手のデータは変えない(EntryCalc.dartで学連選抜を作るときと、移行処理で使う)
void gakurenTaichouFuryouNashi(
  Senshu_Gakuren_Data s,
  KantokuData kantoku,
  Random random,
) {
  if (s.chousi != 0) return;
  if (random.nextInt(100) < kantoku.yobiint2[3]) {
    s.chousi = 100;
  } else {
    int randmoto = 100 - s.anteikan;
    if (randmoto < 1) randmoto = 1;
    s.chousi = random.nextInt(randmoto) + s.anteikan;
  }
  // 安定感が0のときに、引き直しても0(体調不良と同じ扱い)にならないようにする
  if (s.chousi < 1) s.chousi = 1;
}

/// 今年の正月駅伝で、プレイヤーが学連選抜の監督をするか
/// (プレイヤーの大学が正月駅伝に出場できず、設定が「する」のとき)
bool gakurenKantokuChuu(KantokuData kantoku, UnivData myUniv) {
  return gakurenKantokuSettei(kantoku) &&
      myUniv.taikaientryflag.length > 2 &&
      myUniv.taikaientryflag[2] == 0;
}

const int gakurenMokuhyouIndex = 76;

/// 学連選抜の監督として目標順位を達成したときに報酬(金銀・見抜く力)がもらえる、一番下の目標順位
/// (0が1位。9は10位。これより下の目標では、達成しても報酬はない。1.8.4)
const int gakurenHoushuuMokuhyouSaikai = 9;

/// プレイヤーが決めた学連選抜の目標順位(0が1位。yobiint2[76]が0なら10位(初期値)、1〜ならその順位)
int gakurenMokuhyouSettei(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= gakurenMokuhyouIndex) return 9;
  final int atai = kantoku.yobiint2[gakurenMokuhyouIndex];
  return atai <= 0 ? 9 : atai - 1;
}

/// 学連選抜の目標順位[juni](0が1位)を保存する
/// (変更をHiveに保存するために、List全体を更新)
Future<void> gakurenMokuhyouHozon(KantokuData kantoku, int juni) async {
  if (kantoku.yobiint2.length <= gakurenMokuhyouIndex) return;
  final List<int> updated = List.from(kantoku.yobiint2);
  updated[gakurenMokuhyouIndex] = juni + 1;
  kantoku.yobiint2 = updated;
  await kantoku.save();
}

/// 学連選抜の目標順位を初期値(10位)に戻す(毎年、学連選抜を作るときに呼ぶ)
Future<void> gakurenMokuhyouShokika(KantokuData kantoku) async {
  if (kantoku.yobiint2.length <= gakurenMokuhyouIndex) return;
  if (kantoku.yobiint2[gakurenMokuhyouIndex] == 0) return;
  final List<int> updated = List.from(kantoku.yobiint2);
  updated[gakurenMokuhyouIndex] = 0;
  kantoku.yobiint2 = updated;
  await kantoku.save();
}

/// 学連選抜に、プレイヤーが決めた目標順位と大学と同じ目標の決まり(ほっと一息あり、
/// 正月駅伝の6区は判定しない)を使うか(学連選抜の監督をしていて、スキップ中でないとき)
bool gakurenKantokuRule(KantokuData kantoku, UnivData myUniv) {
  if (!gakurenKantokuChuu(kantoku, myUniv)) return false;
  final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
  return skip == null || skip.skipflag == 0;
}

/// 今年の学連選抜の目標順位(0が1位)。監督をしているときはプレイヤーが決めた順位、
/// コンピュータが監督のときはいつも10位
int gakurenMokuhyou(KantokuData kantoku, UnivData myUniv) {
  return gakurenKantokuRule(kantoku, myUniv)
      ? gakurenMokuhyouSettei(kantoku)
      : 9;
}

/// [gakurenMokuhyou]を、ボックスから監督と自分の大学を読んで出す(画面やテキストから使う)
int gakurenMokuhyouGenzai() {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  if (kantoku == null || gh == null) return 9;
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == gh.MYunivid) return gakurenMokuhyou(kantoku, u);
  }
  return 9;
}
