import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/constants.dart';

// ------------------------------------------------------------
// 持ちタイムの区間内順位(区間配置確認の画面と、生成AIに渡すテキストで使う。1.8.8)
//
// ・5000m・1万m・ハーフは、区間エントリーのときに出した区間内順位(SenshuData.kukannaijuni)
// ・登り1万・下り1万・ロード1万・クロカン1万(夏の学内タイムトライアルの記録)は、
//   その区間を走る選手全員にその種目の記録があるときだけ、その場で比べて出す
//   (記録のない選手がいると、記録のある選手どうしだけの順位になって誤解のもとになるため。
//    1.8.8から夏の学内タイムトライアルはいつも全大学で行うので、駅伝のころには、ほぼいつも全員そろう)
// ・学連選抜(OP)の選手は、区間を走る大学の選手と比べた順位相当(gakuren_text.dart)
// ------------------------------------------------------------

/// 夏の学内タイムトライアルの種目か
/// (time_bestkirokuの4登り1万・5下り1万・6ロード1万・7クロカン1万)
bool ttShumoku(int idx) => idx >= 4 && idx <= 7;

/// レース[race]の区間(組)[kukan]を走る大学の選手(学連選抜は入らない)
List<SenshuData> kukanHashiruSenshu(int race, int kukan) {
  return Hive.box<SenshuData>('senshuBox').values.where((s) {
    return s.gakunen >= 1 &&
        s.gakunen <= 4 &&
        s.entrykukan_race.length > race &&
        s.entrykukan_race[race].length >= s.gakunen &&
        s.entrykukan_race[race][s.gakunen - 1] == kukan;
  }).toList();
}

/// 種目[idx]の持ちタイム[time]を、区間を走る大学の選手[kukanSenshu]と比べた順位(1が1位)
/// [time]がないときと、区間を走る選手の誰か一人でもその種目の記録がないときは0
/// (タイムトライアルの4種目で使う。[kukanSenshu]に本人が入っていても、同じタイムは数えないので同じ順位になる)
int ttKukannaiJuni(double time, int idx, List<SenshuData> kukanSenshu) {
  if (time >= TEISUU.DEFAULTTIME) return 0;
  int juni = 1;
  for (final SenshuData d in kukanSenshu) {
    if (d.time_bestkiroku.length <= idx ||
        d.time_bestkiroku[idx] >= TEISUU.DEFAULTTIME) {
      return 0;
    }
    if (d.time_bestkiroku[idx] < time) juni++;
  }
  return juni;
}

/// 大学の選手[s]の、レース[race]での種目[idx]の区間内順位(1が1位。出さないときは0)
int kukannaiJuni(SenshuData s, int idx, int race) {
  if (!ttShumoku(idx)) {
    return s.kukannaijuni.length > idx ? s.kukannaijuni[idx] + 1 : 0;
  }
  if (s.gakunen < 1 ||
      s.entrykukan_race.length <= race ||
      s.entrykukan_race[race].length < s.gakunen ||
      s.time_bestkiroku.length <= idx) {
    return 0;
  }
  final int kukan = s.entrykukan_race[race][s.gakunen - 1];
  if (kukan < 0) return 0;
  return ttKukannaiJuni(
    s.time_bestkiroku[idx],
    idx,
    kukanHashiruSenshu(race, kukan),
  );
}

/// 持ちタイムの順位の説明(生成AIに渡すテキストでは、順位を「区間内」「学内」「全体」と言葉で書く。1.8.8)
const String mochiTimeJuniChuui =
    '※「区間内」はその区間にエントリーされている選手の中でのその種目の持ちタイムの順位、「学内」はその種目の所属大学学内での持ちタイムの順位、「全体」はその種目の学生全体での持ちタイムの順位です。';

/// 夏の学内タイムトライアルの4種目の説明(1.8.8)
const String ttKirokuChuui =
    '※登り1万・下り1万・ロード1万・クロカン1万は、各大学の夏の学内タイムトライアルの記録です。区間内順位がないのは、その区間に記録のない選手がいるときです。';
