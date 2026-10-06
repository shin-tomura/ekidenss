import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/konki_best.dart';

// ------------------------------------------------------------
// カスタム駅伝の出場制限(1.9.1)
// ・KantokuData.yobiint2[78] 学年(0=全学年(初期値)・1=3年生以下・2=2年生以下)
// ・KantokuData.yobiint2[79] 留学生(0=制限なし(初期値)・1=出場できない)
// ・設定は説明画面の設定タブの「カスタム駅伝設定」で変える。カスタム駅伝の日は、一次エントリーが
//   始まると(モード110の後)その画面を開けないので、レースの途中で制限が変わることはない
// ・一次エントリーの段階で、出場できない選手を選べないようにする
//   (区間配置・当日変更・戦略的エントリーは一次エントリーの選手の中だけで行うので、制限が守られる)
// ・一次エントリーの定員(区間数が6以下なら8人、8以下なら13人、それより多いと16人)より
//   出場できる選手が少ない大学は、出場できる人数が定員
// ・走る選手が区間数に足りない大学は、足りない人数だけ補う。補う順番は
//   1つ上の学年の選手→さらに上の学年の選手→留学生(留学生が出場できないときだけ。学年の若い順)
//   (留学生が出場できないときは、上の学年の留学生も最後に回す。留学生の制限がないときは、学年の中で同じに扱う)
//   コンピュータの大学(と自分の大学の最初の仮の一次エントリー)は、同じ段の中では今季ベスト(なければ自己ベスト)の速い順。
//   自分の大学は、一次エントリーの画面で、補える段の中から入れ替えられる
// ・補ったかどうかは保存しない(出場制限に合わないのに一次エントリーに入っている選手が、補った選手)。
//   補った大学があれば、一次エントリー・全大学確認・区間エントリーの画面の一番上に知らせる
//   (スキップ中はこれらの画面を出さないので、知らせない)
// ------------------------------------------------------------

/// カスタム駅伝のレース番号
const int customRaceBangou = 5;

KantokuData? _kantoku() =>
    Hive.box<KantokuData>('kantokuBox').get('KantokuData');

int _yobi(int index) {
  final KantokuData? kantoku = _kantoku();
  if (kantoku == null || kantoku.yobiint2.length <= index) return 0;
  return kantoku.yobiint2[index];
}

/// 学年の設定(0=全学年・1=3年生以下・2=2年生以下)
int customGakunenSettei() {
  final int v = _yobi(78);
  return (v == 1 || v == 2) ? v : 0;
}

/// 留学生の設定(0=制限なし・1=出場できない)
int customRyuugakuseiSettei() => _yobi(79) == 1 ? 1 : 0;

/// カスタム駅伝に出場できる学年の上限(4=全学年・3=3年生以下・2=2年生以下)
int customGakunenJougen() => 4 - customGakunenSettei();

/// カスタム駅伝に留学生が出場できないか
bool customRyuugakuseiFuka() => customRyuugakuseiSettei() == 1;

/// カスタム駅伝の出場制限をかけているか
bool customSeigenAri() =>
    customGakunenSettei() != 0 || customRyuugakuseiFuka();

/// 出場制限を保存する([gakunen]は0〜2、[ryuugakusei]は0〜1)
Future<void> customSeigenHozon(int gakunen, int ryuugakusei) async {
  final KantokuData? kantoku = _kantoku();
  if (kantoku == null || kantoku.yobiint2.length <= 79) return;
  kantoku.yobiint2[78] = (gakunen == 1 || gakunen == 2) ? gakunen : 0;
  kantoku.yobiint2[79] = ryuugakusei == 1 ? 1 : 0;
  await kantoku.save();
}

/// 学年の設定の名前
String customGakunenMei(int settei) =>
    settei == 1 ? '3年生以下' : (settei == 2 ? '2年生以下' : '全学年');

/// 選手[s]がカスタム駅伝の出場制限で出場できるか(制限をかけていなければいつもtrue)
bool customShutsujouKa(SenshuData s) {
  if (s.gakunen > customGakunenJougen()) return false;
  if (customRyuugakuseiFuka() && s.hirou == 1) return false;
  return true;
}

/// 一次エントリーの定員の基本(正月駅伝予選は12人、ほかは区間数が6以下なら8人、8以下なら13人、それより多いと16人)
int ichijiEntryTeiinKihon(int racebangou, int kukansuu) {
  if (racebangou == 4) return 12;
  if (kukansuu <= 6) return 8;
  if (kukansuu <= 8) return 13;
  return 16;
}

/// 大学のカスタム駅伝の一次エントリーの状況(出場制限をかけているときに使う)
class CustomEntryJoukyou {
  /// 出場制限で出場できる選手
  final List<SenshuData> shutsujouKa;

  /// 補う候補を順番の段ごとに並べたもの(1つ上の学年→さらに上の学年→留学生)
  final List<List<SenshuData>> hojuuDan;

  /// 走る選手が区間数に足りない人数(0なら補わない)
  final int fusoku;

  /// 一次エントリーの定員
  final int teiin;

  /// 補う選手として選んでよい選手のid(足りない人数を、前の段から順に満たすまでの段の選手)
  final Set<int> hojuuKouhoIds;

  /// 補う選手として必ず入れる選手のid(段の全員を使っても足りないときの、その段の選手)
  final Set<int> hojuuHitsuyouIds;

  const CustomEntryJoukyou({
    required this.shutsujouKa,
    required this.hojuuDan,
    required this.fusoku,
    required this.teiin,
    required this.hojuuKouhoIds,
    required this.hojuuHitsuyouIds,
  });

  /// 一次エントリーで選べる選手か(出場できる選手か、補う候補)
  bool erabeRu(SenshuData s) =>
      shutsujouKa.any((d) => d.id == s.id) || hojuuKouhoIds.contains(s.id);

  /// 補う候補か
  bool hojuuKouho(SenshuData s) => hojuuKouhoIds.contains(s.id);
}

/// 大学[univid]のカスタム駅伝の一次エントリーの状況([kukansuu]はカスタム駅伝の区間数)
/// [team]を渡さなければ、選手のデータから大学の選手を集める
CustomEntryJoukyou customEntryJoukyou(
  int univid,
  int kukansuu, {
  List<SenshuData>? team,
}) {
  final List<SenshuData> senshu =
      team ??
      Hive.box<SenshuData>(
        'senshuBox',
      ).values.where((s) => s.univid == univid).toList();
  final int jougen = customGakunenJougen();
  final bool fuka = customRyuugakuseiFuka();
  final List<SenshuData> ka = senshu.where(customShutsujouKa).toList();
  final int fusoku = ka.length < kukansuu ? kukansuu - ka.length : 0;

  // 補う候補の段(1つ上の学年→さらに上の学年→留学生)
  final List<List<SenshuData>> dan = [];
  for (int g = jougen + 1; g <= 4; g++) {
    final List<SenshuData> l = senshu
        .where((s) => s.gakunen == g && !(fuka && s.hirou == 1))
        .toList();
    if (l.isNotEmpty) dan.add(l);
  }
  if (fuka) {
    final List<SenshuData> l = senshu.where((s) => s.hirou == 1).toList()
      ..sort((a, b) {
        final int c = a.gakunen.compareTo(b.gakunen);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    if (l.isNotEmpty) dan.add(l);
  }

  // 足りない人数を、前の段から順に満たす
  final Set<int> kouho = {};
  final Set<int> hitsuyou = {};
  int nokori = fusoku;
  for (final List<SenshuData> l in dan) {
    if (nokori <= 0) break;
    for (final s in l) {
      kouho.add(s.id);
    }
    if (l.length <= nokori) {
      // 段の全員を使っても足りない(ちょうど)ので、全員を入れる
      for (final s in l) {
        hitsuyou.add(s.id);
      }
      nokori -= l.length;
    } else {
      nokori = 0;
    }
  }

  final int kihon = ichijiEntryTeiinKihon(customRaceBangou, kukansuu);
  final int teiin = fusoku > 0
      ? kukansuu
      : (ka.length < kihon ? ka.length : kihon);
  return CustomEntryJoukyou(
    shutsujouKa: ka,
    hojuuDan: dan,
    fusoku: fusoku,
    teiin: teiin,
    hojuuKouhoIds: kouho,
    hojuuHitsuyouIds: hitsuyou,
  );
}

/// コンピュータが補う選手(足りない人数を、前の段から順に。同じ段の中では
/// 種目[shumoku]の今季ベスト(なければ自己ベスト)の速い順)
List<SenshuData> customHojuuJidou(CustomEntryJoukyou j, int shumoku) {
  final List<SenshuData> erabu = [];
  int nokori = j.fusoku;
  for (final List<SenshuData> l in j.hojuuDan) {
    if (nokori <= 0) break;
    final List<SenshuData> jun = List<SenshuData>.from(l)
      ..sort((a, b) {
        final int c = hikakuMochiTime(
          a,
          shumoku,
        ).compareTo(hikakuMochiTime(b, shumoku));
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    for (final s in jun) {
      if (nokori <= 0) break;
      erabu.add(s);
      nokori--;
    }
  }
  return erabu;
}

/// 大学[univid]の一次エントリー(-1の選手)の、出場制限の決まりに合わないところ(合っていればnull)
/// [team]は大学の選手、[race]はレース番号(一次エントリーの状態を読む場所)
String? customEntryMondai(
  CustomEntryJoukyou j,
  List<SenshuData> team,
  int race,
) {
  int hojuuSuu = 0;
  for (final s in team) {
    if (s.gakunen < 1 ||
        s.entrykukan_race.length <= race ||
        s.entrykukan_race[race].length < s.gakunen ||
        s.entrykukan_race[race][s.gakunen - 1] != -1) {
      continue;
    }
    if (j.shutsujouKa.any((d) => d.id == s.id)) continue;
    if (!j.hojuuKouho(s)) {
      return '出場制限で出場できない選手が入っています(${s.name})';
    }
    hojuuSuu++;
  }
  if (hojuuSuu > j.fusoku) {
    return '補える人数(${j.fusoku}人)より多く、出場制限に合わない選手が入っています';
  }
  for (final s in team) {
    if (!j.hojuuHitsuyouIds.contains(s.id)) continue;
    final bool hairu =
        s.gakunen >= 1 &&
        s.entrykukan_race.length > race &&
        s.entrykukan_race[race].length >= s.gakunen &&
        s.entrykukan_race[race][s.gakunen - 1] == -1;
    if (!hairu) {
      return '補う順番に合っていません(${s.name}を先に入れてください)';
    }
  }
  return null;
}

/// 出場制限で補った選手のお知らせの文(補った大学がなければ空)
/// カスタム駅伝に出ている大学の、出場制限に合わないのに一次エントリー(区間エントリーを含む)に入っている選手を並べる
/// [myUnivid]の大学で補う必要があるときは、入れ替えられることも書く([ichijiEntry]がtrueのときだけ)
String customHojuuOshirase({int? myUnivid, bool ichijiEntry = false}) {
  if (!customSeigenAri()) return '';
  final Map<int, String> univMei = {
    for (final u in Hive.box<UnivData>('univBox').values)
      if (u.taikaientryflag.length > customRaceBangou &&
          u.taikaientryflag[customRaceBangou] == 1)
        u.id: u.name,
  };
  final List<SenshuData> hojuu =
      Hive.box<SenshuData>('senshuBox').values.where((s) {
        if (!univMei.containsKey(s.univid)) return false;
        if (s.gakunen < 1 ||
            s.entrykukan_race.length <= customRaceBangou ||
            s.entrykukan_race[customRaceBangou].length < s.gakunen) {
          return false;
        }
        return s.entrykukan_race[customRaceBangou][s.gakunen - 1] >= -1 &&
            !customShutsujouKa(s);
      }).toList()..sort((a, b) {
        final int c = a.univid.compareTo(b.univid);
        if (c != 0) return c;
        final int c2 = a.gakunen.compareTo(b.gakunen);
        return c2 != 0 ? c2 : a.id.compareTo(b.id);
      });
  if (hojuu.isEmpty) return '';
  final StringBuffer sb = StringBuffer();
  sb.writeln('【出場制限のお知らせ】');
  sb.writeln('出場制限で走る選手が区間数に足りないため、次の大学は出場制限に合わない選手で補いました。');
  for (final s in hojuu) {
    sb.writeln(
      '・${univMei[s.univid]}大学 ${s.gakunen}年 ${s.name}${s.hirou == 1 ? '(留学生)' : ''}',
    );
  }
  if (ichijiEntry && myUnivid != null && hojuu.any((s) => s.univid == myUnivid)) {
    sb.writeln('※自分の大学で補う選手は、「補える」と出ている選手の中で入れ替えられます。');
  }
  return sb.toString().trimRight();
}
