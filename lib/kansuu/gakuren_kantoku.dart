import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';

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
    kakikae[key] = s;
  }
  if (kakikae.isNotEmpty) await box.putAll(kakikae);
}

/// 今年の正月駅伝で、プレイヤーが学連選抜の監督をするか
/// (プレイヤーの大学が正月駅伝に出場できず、設定が「する」のとき)
bool gakurenKantokuChuu(KantokuData kantoku, UnivData myUniv) {
  return gakurenKantokuSettei(kantoku) &&
      myUniv.taikaientryflag.length > 2 &&
      myUniv.taikaientryflag[2] == 0;
}
