import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/rekidai_kiroku.dart'; // 歴代10位までの記録
import 'package:ekiden/kansuu/custom_seigen.dart' show customRaceBangou;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show gakurenShussouJuni, jikanMoji, KijiHyou;

// ------------------------------------------------------------
// 選手画面の「通算」の行と「歴代記録」の表(2.1.4)
//
// 選手画面(自分の大学・他大学)・選手の詳細の小窓・卒業生の画面の、三大駅伝と対校戦の成績の表のすぐ上に、
// その選手のこれまでをまとめて出す。
//  ・通算(1行): 三大駅伝の出走回数(区間賞の回数)・学連選抜での出走回数・対校戦の入賞(8位以内)の回数
//  ・歴代記録(表): 記録画面に出ている範囲(全体・学内の歴代10位まで)に入っている記録と、その順位
//    ・個人記録(5000m・1万m・ハーフ・フルと夏のTTの4種目): 自己ベストの、全体と学内の歴代の順位
//      (記録画面の一番上の行と同じ、日本人+留学生を合わせた一人1件の並び)
//    ・駅伝の区間記録(10月・11月・正月・カスタム): 走った学年ごとの、全体と学内の区間の歴代の順位
//      (日本人+留学生を合わせた並び。区間記録は同じ選手の記録も何件も残る)
//  学内の記録は総監督をしている大学しか残していないので、学内の列は、自分の大学の選手と卒業生だけに出す
//  (他大学の選手は全体の列だけ)
//
// 記録には選手の番号がない(番号は卒業後に使い回す)ので、記録の側で本人を探さず、選手の側に残っている
// 本人のタイムを記録と比べる(名前は使わないので、選手名変更をしていても出せる)
//  ・個人記録: 自己ベストのタイム(と、分かれば出した年月)と同じ記録が、並びの何番目にあるか。
//    自己ベストと個人記録は同じ大会(駅伝予選を除く)から作るので、並びにあれば本人の記録
//  ・区間記録: その選手が学年ごとに走った区間のタイムと学年が同じ記録が、並びの何番目にあるか
// セーブ済みのデータから画面を描くたびに作る(セーブデータは増やさない)。失敗したら何も出さない
// (2.1.4の開発中は、学内歴代と、今の学内区間記録を持っている区間を1行ずつで出していたが、表にまとめた)
// ------------------------------------------------------------

/// 通算の行を作る材料(現役の選手と卒業生の両方から作る)
class TsuusanSozai {
  const TsuusanSozai({
    required this.univid,
    required this.gakunen,
    required this.entry,
    required this.juni,
    required this.time,
    required this.best,
    required this.bestYear,
    required this.bestMonth,
  });

  final int univid;

  /// 今の学年(卒業生は4)
  final int gakunen;

  /// [大会][学年(0が1年)]の区間エントリー・区間順位・タイム
  final List<List<int>> entry;
  final List<List<int>> juni;
  final List<List<double>> time;

  /// 種目ごとの自己ベストと、出した年・月(年月は分からなければ0)
  final List<double> best;
  final List<int> bestYear;
  final List<int> bestMonth;

  factory TsuusanSozai.genneki(SenshuData s) => TsuusanSozai(
    univid: s.univid,
    gakunen: s.gakunen,
    entry: s.entrykukan_race,
    juni: s.kukanjuni_race,
    time: s.kukantime_race,
    best: s.time_bestkiroku,
    bestYear: s.year_bestkiroku,
    bestMonth: s.month_bestkiroku,
  );

  /// 卒業生(卒業生は4年分がそろっているので、4年として見る。成績の表と同じ)
  factory TsuusanSozai.sotsugyou(Senshu_R_Data s) => TsuusanSozai(
    univid: s.univid,
    gakunen: 4,
    entry: s.entrykukan_race,
    juni: s.kukanjuni_race,
    time: s.kukantime_race,
    best: s.time_bestkiroku,
    bestYear: s.year_bestkiroku,
    bestMonth: s.month_bestkiroku,
  );

  int entryAt(int race, int g) {
    if (g < 1 || entry.length <= race || entry[race].length < g) return -1;
    return entry[race][g - 1];
  }

  int juniAt(int race, int g) {
    if (g < 1 || juni.length <= race || juni[race].length < g) return TEISUU.DEFAULTJUNI;
    return juni[race][g - 1];
  }

  double timeAt(int race, int g) {
    if (g < 1 || time.length <= race || time[race].length < g) return TEISUU.DEFAULTTIME;
    return time[race][g - 1];
  }
}

/// 歴代記録の表に出す個人記録の番号と名前(記録画面の並び。個人記録のあとに夏のTT)
const List<int> _rekidaiShumoku = [0, 1, 2, 3, 6, 4, 5, 7];
const Map<int, String> _shumokuMei = {
  0: '5000m',
  1: '1万m',
  2: 'ハーフ',
  3: 'フル',
  4: '登り1万',
  5: '下り1万',
  6: 'ロード1万',
  7: 'クロカン1万',
};

/// 通算の行(出すことがなければ空)
List<String> tsuusanGyou(TsuusanSozai s) {
  try {
    final String? tsuusan = _tsuusan(s);
    return tsuusan == null ? [] : [tsuusan];
  } catch (_) {
    return [];
  }
}

/// 「通算: 三大駅伝7回出走(区間賞2)・対校戦入賞3回」(何もなければnull)
String? _tsuusan(TsuusanSozai s) {
  int shussou = 0;
  int kukanshou = 0;
  int gakuren = 0;
  int nyuushou = 0;
  for (int g = 1; g <= s.gakunen; g++) {
    for (final int race in const [0, 1, 2]) {
      if (s.entryAt(race, g) < 0) continue;
      final int j = s.juniAt(race, g);
      if (gakurenShussouJuni(race, j)) {
        gakuren++;
      } else {
        shussou++;
        if (j == 0) kukanshou++;
      }
    }
    for (final int race in const [6, 7, 8]) {
      if (s.entryAt(race, g) < 0) continue;
      final int j = s.juniAt(race, g);
      if (j >= 0 && j < 8) nyuushou++;
    }
  }
  final List<String> bubun = [
    if (shussou > 0) '三大駅伝$shussou回出走${kukanshou > 0 ? '(区間賞$kukanshou)' : ''}',
    if (gakuren > 0) '学連選抜$gakuren回',
    if (nyuushou > 0) '対校戦入賞$nyuushou回',
  ];
  if (bubun.isEmpty) return null;
  return '通算: ${bubun.join('・')}';
}

/// 順位のマスの文字(0が1位。並びになければ「-」)
String _juniMasu(int ichi) => ichi >= 0 ? '${ichi + 1}位' : '-';

/// 歴代記録の表(全体か学内の歴代10位以内に入っている記録がなければnull)
KijiHyou? rekidaiHyou(TsuusanSozai s) {
  try {
    if (!Hive.isBoxOpen('ghensuuBox') || !Hive.isBoxOpen('univBox') || !Hive.isBoxOpen('kirokuBox')) {
      return null;
    }
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
    final Kiroku? kiroku = Hive.box<Kiroku>('kirokuBox').get('KirokuData');
    if (gh == null || kiroku == null) return null;
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    // 学内の列は、自分の大学の選手と卒業生だけ
    final UnivData? u = s.univid == gh.MYunivid ? univBox.get(gh.MYunivid) : null;
    final List<List<String>> gyou = [];

    // 個人記録(自己ベスト)
    for (final int k in _rekidaiShumoku) {
      if (s.best.length <= k) continue;
      final double best = s.best[k];
      if (!(best > 0 && best < TEISUU.DEFAULTTIME)) continue;
      final int yb = s.bestYear.length > k ? s.bestYear[k] : 0;
      final int mb = s.bestMonth.length > k ? s.bestMonth[k] : 0;
      // 自己ベストと同じタイム(出した年月が分かれば年月も)の記録の位置
      int ichi(List<RekidaiKiroku> l) => l.indexWhere(
        (x) => (x.time - best).abs() < 0.05 && (yb == 0 || (x.year == yb && x.month == mb)),
      );
      final int z = ichi(
        rekidaiAwaseru(
          ichii: ichiiZentaiKojin(gh, k).yomu(),
          nihonjin: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, false, k).yomu()),
          ryuugakusei: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, true, k).yomu()),
          hitoriIkken: true,
        ),
      );
      final int g = u == null
          ? -1
          : ichi(
              rekidaiAwaseru(
                ichii: ichiiUnivKojin(u, k).yomu(),
                nihonjin: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, false, u.id, k).yomu()),
                ryuugakusei: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, true, u.id, k).yomu()),
                hitoriIkken: true,
              ),
            );
      if (z < 0 && g < 0) continue;
      gyou.add([_shumokuMei[k] ?? '', jikanMoji(best), _juniMasu(z), if (u != null) _juniMasu(g)]);
    }

    // 駅伝の区間記録(走った学年ごと)
    final UnivData? custom = univBox.get(0);
    for (final int race in const [0, 1, 2, customRaceBangou]) {
      for (int gk = 1; gk <= s.gakunen; gk++) {
        final int kk = s.entryAt(race, gk);
        if (kk < 0 || kk >= TEISUU.SUU_MAXKUKANSUU) continue;
        if (gakurenShussouJuni(race, s.juniAt(race, gk))) continue;
        final double t = s.timeAt(race, gk);
        if (!(t > 0 && t < TEISUU.DEFAULTTIME)) continue;
        // 区間のタイムと学年が同じ記録の位置
        int ichi(List<RekidaiKiroku> l) =>
            l.indexWhere((x) => (x.time - t).abs() < 0.05 && x.gakunen == gk);
        final int z = ichi(
          rekidaiAwaseru(
            ichii: ichiiZentaiKukan(gh, race, kk).yomu(),
            nihonjin: rekidaiZentaiKukan(kiroku, false, race, kk).yomu(),
            ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, kk).yomu(),
          ),
        );
        final int g = (u == null || u.time_univkukankiroku.length <= race)
            ? -1
            : ichi(
                rekidaiAwaseru(
                  ichii: ichiiUnivKukan(u, race, kk).yomu(),
                  nihonjin: rekidaiUnivKukan(kiroku, false, u.id, race, kk).yomu(),
                  ryuugakusei: rekidaiUnivKukan(kiroku, true, u.id, race, kk).yomu(),
                ),
              );
        if (z < 0 && g < 0) continue;
        gyou.add([
          '${_raceMei(race, custom)}${kk + 1}区($gk年)',
          jikanMoji(t),
          _juniMasu(z),
          if (u != null) _juniMasu(g),
        ]);
      }
    }
    if (gyou.isEmpty) return null;
    return KijiHyou('歴代記録(10位以内)', ['種目・区間', 'タイム', '全体', if (u != null) '学内'], gyou);
  } catch (_) {
    return null;
  }
}

String _raceMei(int race, UnivData? custom) {
  switch (race) {
    case 0:
      return '10月駅伝';
    case 1:
      return '11月駅伝';
    case 2:
      return '正月駅伝';
    default:
      final String mei = custom?.name_tanshuku.trim() ?? '';
      return mei.isEmpty ? 'カスタム駅伝' : mei;
  }
}
