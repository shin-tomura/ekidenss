import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 歴代10位までの記録(1.8.8)
//
// 記録画面の記録を、1位だけでなく歴代10位(TEISUU.SUU_REKIDAIKIROKUJUNISUU)まで残す。
// セーブデータの型やフィールドは変えず、今ある記録の配列の一番内側(順位の次元)の長さを伸ばして使う。
// ・伸ばすのは、次の配列だけ(どれもレースの後にしか保存しないものか、小さいもの)
//   - Kiroku の日本人・留学生の区間記録・個人記録(全体と、総監督をしている大学の学内)
//   - Ghensuu の全体の大会記録と、総監督をしている大学の UnivData の学内大会記録
// ・日本人+留学生の区間記録・個人記録(Ghensuu の全体、UnivData の学内)は、毎日保存する Ghensuu などにあるため、
//   今までどおり1位だけを持つ(区間新などの判定にも使う)。
//   記録画面の全体の2位以下は、日本人と留学生の歴代を合わせて作る(rekidaiAwaseru)。
// ・伸ばすのは記録画面に出す記録だけ
//   (駅伝は10月・11月・正月・カスタム駅伝、個人記録は5000m・10000m・ハーフ・フル)。
//   予選会や夏のタイムトライアルなどの記録は、今までどおり1位だけ。
// ・前の版のセーブデータは長さ1のままで、これからの記録で2位以下が貯まる(移行処理はしない)。
// ・配列は List.filled の固定長のこともあるため、要素を足さず、書き込むときに配列ごと作り直す。
// ・[0]は今までどおり1位なので、[0]だけを読む処理(区間新の判定など)はそのままでよい。
// ------------------------------------------------------------

/// 歴代の記録の1件
class RekidaiKiroku {
  const RekidaiKiroku({
    required this.time,
    required this.year,
    required this.month,
    this.univname = '',
    this.name = '',
    this.gakunen = 0,
  });

  final double time;
  final int year;
  final int month;
  final String univname; // 大学名(学内記録では空)
  final String name; // 選手名(大会記録では空)
  final int gakunen;

  /// 同じ記録か(保存のときの丸めの違いを見込んで、タイムは少しの差を許す)
  bool onaji(RekidaiKiroku b) =>
      (time - b.time).abs() < 0.05 &&
      year == b.year &&
      month == b.month &&
      name == b.name;
}

/// 記録があるか(リセット後や初期値は DEFAULTTIME)
bool rekidaiKirokuAri(double time) => time > 0 && time < TEISUU.DEFAULTTIME;

/// 歴代10位まで残す大会か(記録画面に出す、10月・11月・正月・カスタム駅伝)
bool rekidaiTaishouRace(int racebangou) =>
    (racebangou >= 0 && racebangou <= 2) || racebangou == 5;

/// 歴代10位まで残す個人記録か(記録画面に出す、5000m・10000m・ハーフ・フル)
bool rekidaiTaishouKojin(int kirokubangou) =>
    kirokubangou >= 0 && kirokubangou <= 3;

/// 記録の置き場所(順位の配列を要素に持つ配列と、その添字)
class RekidaiOkiba {
  RekidaiOkiba({
    required this.time,
    required this.year,
    required this.month,
    this.univname,
    this.name,
    this.gakunen,
    required this.i,
  });

  final List<List<double>> time;
  final List<List<int>> year;
  final List<List<int>> month;
  final List<List<String>>? univname;
  final List<List<String>>? name;
  final List<List<int>>? gakunen;
  final int i;

  static T _yomu1<T>(List<List<T>>? l, int i, int r, T nashi) {
    if (l == null || i >= l.length || r >= l[i].length) return nashi;
    return l[i][r];
  }

  /// 記録のあるものだけを、並んでいる順(速い順)に読む
  List<RekidaiKiroku> yomu() {
    final List<RekidaiKiroku> l = [];
    if (i >= time.length) return l;
    for (int r = 0; r < time[i].length; r++) {
      final double t = time[i][r];
      if (!rekidaiKirokuAri(t)) continue;
      l.add(
        RekidaiKiroku(
          time: t,
          year: _yomu1<int>(year, i, r, 0),
          month: _yomu1<int>(month, i, r, 0),
          univname: _yomu1<String>(univname, i, r, ''),
          name: _yomu1<String>(name, i, r, ''),
          gakunen: _yomu1<int>(gakunen, i, r, 0),
        ),
      );
    }
    return l;
  }

  /// [l]を書く(空のときは、記録なしの1件にする)
  void kaku(List<RekidaiKiroku> l) {
    final int n = l.isEmpty ? 1 : l.length;
    time[i] = List<double>.generate(
      n,
      (r) => r < l.length ? l[r].time : TEISUU.DEFAULTTIME,
    );
    year[i] = List<int>.generate(n, (r) => r < l.length ? l[r].year : 0);
    month[i] = List<int>.generate(n, (r) => r < l.length ? l[r].month : 0);
    univname?[i] = List<String>.generate(
      n,
      (r) => r < l.length ? l[r].univname : '',
    );
    name?[i] = List<String>.generate(n, (r) => r < l.length ? l[r].name : '');
    gakunen?[i] = List<int>.generate(
      n,
      (r) => r < l.length ? l[r].gakunen : 0,
    );
  }
}

// ---- 置き場所 ----

/// 全体の日本人・留学生の区間記録(Kiroku)
RekidaiOkiba rekidaiZentaiKukan(
  Kiroku k,
  bool ryuugakusei,
  int race,
  int kukan,
) {
  if (ryuugakusei) {
    return RekidaiOkiba(
      time: k.time_zentai_ryuugakusei_kukankiroku[race],
      year: k.year_zentai_ryuugakusei_kukankiroku[race],
      month: k.month_zentai_ryuugakusei_kukankiroku[race],
      univname: k.univname_zentai_ryuugakusei_kukankiroku[race],
      name: k.name_zentai_ryuugakusei_kukankiroku[race],
      gakunen: k.gakunen_zentai_ryuugakusei_kukankiroku[race],
      i: kukan,
    );
  }
  return RekidaiOkiba(
    time: k.time_zentai_jap_kukankiroku[race],
    year: k.year_zentai_jap_kukankiroku[race],
    month: k.month_zentai_jap_kukankiroku[race],
    univname: k.univname_zentai_jap_kukankiroku[race],
    name: k.name_zentai_jap_kukankiroku[race],
    gakunen: k.gakunen_zentai_jap_kukankiroku[race],
    i: kukan,
  );
}

/// 全体の日本人・留学生の個人記録(Kiroku)
RekidaiOkiba rekidaiZentaiKojin(Kiroku k, bool ryuugakusei, int kirokubangou) {
  if (ryuugakusei) {
    return RekidaiOkiba(
      time: k.time_zentai_ryuugakusei_kojinkiroku,
      year: k.year_zentai_ryuugakusei_kojinkiroku,
      month: k.month_zentai_ryuugakusei_kojinkiroku,
      univname: k.univname_zentai_ryuugakusei_kojinkiroku,
      name: k.name_zentai_ryuugakusei_kojinkiroku,
      gakunen: k.gakunen_zentai_ryuugakusei_kojinkiroku,
      i: kirokubangou,
    );
  }
  return RekidaiOkiba(
    time: k.time_zentai_jap_kojinkiroku,
    year: k.year_zentai_jap_kojinkiroku,
    month: k.month_zentai_jap_kojinkiroku,
    univname: k.univname_zentai_jap_kojinkiroku,
    name: k.name_zentai_jap_kojinkiroku,
    gakunen: k.gakunen_zentai_jap_kojinkiroku,
    i: kirokubangou,
  );
}

/// 学内の日本人・留学生の区間記録(Kiroku)
RekidaiOkiba rekidaiUnivKukan(
  Kiroku k,
  bool ryuugakusei,
  int univid,
  int race,
  int kukan,
) {
  if (ryuugakusei) {
    return RekidaiOkiba(
      time: k.time_univ_ryuugakusei_kukankiroku[univid][race],
      year: k.year_univ_ryuugakusei_kukankiroku[univid][race],
      month: k.month_univ_ryuugakusei_kukankiroku[univid][race],
      name: k.name_univ_ryuugakusei_kukankiroku[univid][race],
      gakunen: k.gakunen_univ_ryuugakusei_kukankiroku[univid][race],
      i: kukan,
    );
  }
  return RekidaiOkiba(
    time: k.time_univ_jap_kukankiroku[univid][race],
    year: k.year_univ_jap_kukankiroku[univid][race],
    month: k.month_univ_jap_kukankiroku[univid][race],
    name: k.name_univ_jap_kukankiroku[univid][race],
    gakunen: k.gakunen_univ_jap_kukankiroku[univid][race],
    i: kukan,
  );
}

/// 学内の日本人・留学生の個人記録(Kiroku)
RekidaiOkiba rekidaiUnivKojin(
  Kiroku k,
  bool ryuugakusei,
  int univid,
  int kirokubangou,
) {
  if (ryuugakusei) {
    return RekidaiOkiba(
      time: k.time_univ_ryuugakusei_kojinkiroku[univid],
      year: k.year_univ_ryuugakusei_kojinkiroku[univid],
      month: k.month_univ_ryuugakusei_kojinkiroku[univid],
      name: k.name_univ_ryuugakusei_kojinkiroku[univid],
      gakunen: k.gakunen_univ_ryuugakusei_kojinkiroku[univid],
      i: kirokubangou,
    );
  }
  return RekidaiOkiba(
    time: k.time_univ_jap_kojinkiroku[univid],
    year: k.year_univ_jap_kojinkiroku[univid],
    month: k.month_univ_jap_kojinkiroku[univid],
    name: k.name_univ_jap_kojinkiroku[univid],
    gakunen: k.gakunen_univ_jap_kojinkiroku[univid],
    i: kirokubangou,
  );
}

/// 全体の大会記録(Ghensuu。歴代10位まで)
RekidaiOkiba rekidaiZentaiTaikai(Ghensuu gh, int race) => RekidaiOkiba(
  time: gh.time_zentaitaikaikiroku,
  year: gh.year_zentaitaikaikiroku,
  month: gh.month_zentaitaikaikiroku,
  univname: gh.univname_zentaitaikaikiroku,
  i: race,
);

/// 学内の大会記録(UnivData。歴代10位まで)
RekidaiOkiba rekidaiUnivTaikai(UnivData u, int race) => RekidaiOkiba(
  time: u.time_univtaikaikiroku,
  year: u.year_univtaikaikiroku,
  month: u.month_univtaikaikiroku,
  i: race,
);

/// 全体の日本人+留学生の区間記録(Ghensuu。1位だけ)
RekidaiOkiba ichiiZentaiKukan(Ghensuu gh, int race, int kukan) =>
    RekidaiOkiba(
      time: gh.time_zentaikukankiroku[race],
      year: gh.year_zentaikukankiroku[race],
      month: gh.month_zentaikukankiroku[race],
      univname: gh.univname_zentaikukankiroku[race],
      name: gh.name_zentaikukankiroku[race],
      gakunen: gh.gakunen_zentaikukankiroku[race],
      i: kukan,
    );

/// 全体の日本人+留学生の個人記録(Ghensuu。1位だけ)
RekidaiOkiba ichiiZentaiKojin(Ghensuu gh, int kirokubangou) => RekidaiOkiba(
  time: gh.time_zentaikojinkiroku,
  year: gh.year_zentaikojinkiroku,
  month: gh.month_zentaikojinkiroku,
  univname: gh.univname_zentaikojinkiroku,
  name: gh.name_zentaikojinkiroku,
  gakunen: gh.gakunen_zentaikojinkiroku,
  i: kirokubangou,
);

/// 学内の日本人+留学生の区間記録(UnivData。1位だけ)
RekidaiOkiba ichiiUnivKukan(UnivData u, int race, int kukan) => RekidaiOkiba(
  time: u.time_univkukankiroku[race],
  year: u.year_univkukankiroku[race],
  month: u.month_univkukankiroku[race],
  name: u.name_univkukankiroku[race],
  gakunen: u.gakunen_univkukankiroku[race],
  i: kukan,
);

/// 学内の日本人+留学生の個人記録(UnivData。1位だけ)
RekidaiOkiba ichiiUnivKojin(UnivData u, int kirokubangou) => RekidaiOkiba(
  time: u.time_univkojinkiroku,
  year: u.year_univkojinkiroku,
  month: u.month_univkojinkiroku,
  name: u.name_univkojinkiroku,
  gakunen: u.gakunen_univkojinkiroku,
  i: kirokubangou,
);

// ---- 記録の更新 ----

/// 速い順の歴代[l]に[k]を入れる(同じタイムは先に出した記録を上にする)。
/// [saidai]位より後ろになるときは入れない。入れたら true
bool rekidaiIreru(List<RekidaiKiroku> l, RekidaiKiroku k, int saidai) {
  if (!rekidaiKirokuAri(k.time)) return false;
  int ichi = l.length;
  for (int r = 0; r < l.length; r++) {
    if (l[r].time > k.time) {
      ichi = r;
      break;
    }
  }
  if (ichi >= saidai) return false;
  l.insert(ichi, k);
  if (l.length > saidai) l.removeRange(saidai, l.length);
  return true;
}

/// 選手[junban]のうち、[ryuugakusei](true:留学生、false:日本人)に合う選手の記録を、
/// [okiba]の歴代([saidai]位まで)に入れる。変わったら true(保存は呼び出し側で行う)
/// (タイム順に並んでいなくてもよい)
bool rekidaiKousin({
  required RekidaiOkiba okiba,
  required List<SenshuData> junban,
  required bool ryuugakusei,
  required int saidai,
  required Ghensuu gh,
  required List<UnivData> sortedunivdata,
}) {
  final List<RekidaiKiroku> l = okiba.yomu();
  bool kawatta = false;
  for (final SenshuData s in junban) {
    if ((s.hirou == 1) != ryuugakusei) continue;
    final RekidaiKiroku k = RekidaiKiroku(
      time: s.time_taikai_total,
      year: gh.year,
      month: gh.month,
      univname: (s.univid >= 0 && s.univid < sortedunivdata.length)
          ? sortedunivdata[s.univid].name
          : '',
      name: s.name,
      gakunen: s.gakunen,
    );
    if (rekidaiIreru(l, k, saidai)) kawatta = true;
  }
  if (kawatta) okiba.kaku(l);
  return kawatta;
}

// ---- 記録画面の表示 ----

/// 記録画面の、日本人+留学生(全体・学内)の歴代。
/// 1位は[ichii](今の日本人+留学生の記録。区間新などの判定に使うもの)をそのまま1位にし、
/// 2位以下は、日本人と留学生の歴代のうち、1位より速くないものを合わせて速い順に並べる
/// (前の版で、全体・日本人・留学生の一部の行だけをリセットしていたデータでも、1位が変わらないように)
List<RekidaiKiroku> rekidaiAwaseru({
  required List<RekidaiKiroku> ichii,
  required List<RekidaiKiroku> nihonjin,
  required List<RekidaiKiroku> ryuugakusei,
}) {
  if (ichii.isEmpty) return [];
  final RekidaiKiroku ichiban = ichii.first;
  // 日本人と留学生を、速い順(同じタイムは年月の早い順)に合わせる
  final List<RekidaiKiroku> awase = [];
  int a = 0;
  int b = 0;
  while (a < nihonjin.length || b < ryuugakusei.length) {
    bool nihonjinWo;
    if (a >= nihonjin.length) {
      nihonjinWo = false;
    } else if (b >= ryuugakusei.length) {
      nihonjinWo = true;
    } else {
      final RekidaiKiroku x = nihonjin[a];
      final RekidaiKiroku y = ryuugakusei[b];
      if (x.time != y.time) {
        nihonjinWo = x.time < y.time;
      } else {
        nihonjinWo = (x.year * 100 + x.month) <= (y.year * 100 + y.month);
      }
    }
    if (nihonjinWo) {
      awase.add(nihonjin[a]);
      a++;
    } else {
      awase.add(ryuugakusei[b]);
      b++;
    }
  }
  final List<RekidaiKiroku> l = [ichiban];
  bool ichibanWoTobashita = false;
  for (final RekidaiKiroku k in awase) {
    if (l.length >= TEISUU.SUU_REKIDAIKIROKUJUNISUU) break;
    if (!ichibanWoTobashita && k.onaji(ichiban)) {
      ichibanWoTobashita = true;
      continue;
    }
    if (k.time < ichiban.time) continue;
    l.add(k);
  }
  return l;
}
