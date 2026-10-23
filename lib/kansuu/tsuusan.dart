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
// 記録と選手は、通算の番号(枠の番号+卒業する年×1000。rekidai_kiroku.dart の senshuTsuusanBangou)だけで
// 結びつける(2.1.4)。記録に枠の番号を残すのは2.1.4からなので、それより前に出た記録は結びつけず、表に出さない。
// 番号のない記録が記録の並びに残っているあいだは、表の下にそのことを1行で書く(押し出されれば自然に消える)
//  ・個人記録: 選手の番号と同じ番号の記録が、並びの何番目にあるか(一人1件なので1件だけ)
//  ・区間記録: その選手が学年ごとに走った区間で、選手の番号と学年が同じ記録が、並びの何番目にあるか
//  ・現役の選手の番号は、今の年月と学年から出す。卒業生は、卒業のときに付いた番号(Senshu_R_Data.id)そのもの。
//    アルバムに自分で足した選手(sijiseikouflag が100)は、番号が「枠の番号+足した年×1000」なので、
//    足した年と学年から卒業する年を出す。足した月が分からず1年ずれることがあるので、2つの候補で見る
//    (同じ枠の前後の選手は卒業する年が4年ずつ違うので、どちらかにしか当たらない)
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
    required this.waku,
    required this.motoGakunen,
    this.sotsugyousei = false,
    this.rid = 0,
    this.sijiflag = 0,
    this.jibunTsuika = false,
  });

  final int univid;

  /// 枠の番号(現役の選手の SenshuData.id。卒業生は番号の1000の位より下)
  final int waku;

  /// 選手の今の学年(卒業生は卒業したときの学年。アルバムに自分で足した選手は足したときの学年)
  final int motoGakunen;

  /// 卒業生か(番号 [rid] を持っている)
  final bool sotsugyousei;

  /// 卒業生の番号(Senshu_R_Data.id)と、卒業した年(アルバムに自分で足した選手は足した年)
  final int rid;
  final int sijiflag;

  /// アルバムに自分で足した選手か(sijiseikouflag が100)
  final bool jibunTsuika;

  /// 通算の番号の候補(現役の選手と卒業生は1つ。アルバムに自分で足した選手は2つ)
  List<int> bangouKouho(Ghensuu gh) {
    if (!sotsugyousei) {
      return [tsuusanBangou(waku, sotsugyouNenKeisan(gh.year, gh.month, motoGakunen))];
    }
    if (!jibunTsuika) return [rid];
    // 足した年が1月〜3月なら「足した年+(4−学年)」、4月〜12月なら「足した年+(5−学年)」に卒業する
    final int a = tsuusanBangou(waku, sijiflag + 4 - motoGakunen);
    final int b = tsuusanBangou(waku, sijiflag + 5 - motoGakunen);
    return a == b ? [a] : [a, b];
  }

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
    waku: s.id,
    motoGakunen: s.gakunen,
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
    waku: s.id % 1000,
    motoGakunen: s.gakunen,
    sotsugyousei: true,
    rid: s.id,
    sijiflag: s.sijiflag,
    jibunTsuika: s.sijiseikouflag == 100,
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

/// 歴代記録の表(全体か学内の歴代10位以内に入っている記録がなければ hyou はnull)と、
/// 番号のない記録(2.1.4より前に出た記録)が並びに残っているか(furuiAri。表の下に1行書く)
({KijiHyou? hyou, bool furuiAri}) rekidaiHyou(TsuusanSozai s) {
  try {
    if (!Hive.isBoxOpen('ghensuuBox') || !Hive.isBoxOpen('univBox') || !Hive.isBoxOpen('kirokuBox')) {
      return (hyou: null, furuiAri: false);
    }
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
    final Kiroku? kiroku = Hive.box<Kiroku>('kirokuBox').get('KirokuData');
    if (gh == null || kiroku == null) return (hyou: null, furuiAri: false);
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    // 学内の列は、自分の大学の選手と卒業生だけ
    final UnivData? u = s.univid == gh.MYunivid ? univBox.get(gh.MYunivid) : null;
    final List<int> kouho = s.bangouKouho(gh);
    bool furuiAri = false;
    // 並びに番号のない選手の記録が残っているかも見る
    void miru(List<RekidaiKiroku> l) {
      if (!furuiAri && l.any((x) => x.bangou == null)) furuiAri = true;
    }

    final List<List<String>> gyou = [];

    // 個人記録(番号が同じ記録。一人1件なので1件だけ)
    for (final int k in _rekidaiShumoku) {
      final List<RekidaiKiroku> zentai = rekidaiAwaseru(
        ichii: ichiiZentaiKojin(gh, k).yomu(),
        nihonjin: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, false, k).yomu()),
        ryuugakusei: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, true, k).yomu()),
        hitoriIkken: true,
      );
      final List<RekidaiKiroku> gakunai = u == null
          ? const <RekidaiKiroku>[]
          : rekidaiAwaseru(
              ichii: ichiiUnivKojin(u, k).yomu(),
              nihonjin: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, false, u.id, k).yomu()),
              ryuugakusei: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, true, u.id, k).yomu()),
              hitoriIkken: true,
            );
      miru(zentai);
      miru(gakunai);
      int ichi(List<RekidaiKiroku> l) => l.indexWhere((x) {
        final int? b = x.bangou;
        return b != null && kouho.contains(b);
      });
      final int z = ichi(zentai);
      final int g = ichi(gakunai);
      if (z < 0 && g < 0) continue;
      final RekidaiKiroku kiroku1 = z >= 0 ? zentai[z] : gakunai[g];
      gyou.add([
        _shumokuMei[k] ?? '',
        jikanMoji(kiroku1.time),
        _juniMasu(z),
        if (u != null) _juniMasu(g),
      ]);
    }

    // 駅伝の区間記録(番号と学年が同じ記録。走った学年ごと)
    final UnivData? custom = univBox.get(0);
    for (final int race in const [0, 1, 2, customRaceBangou]) {
      for (int kk = 0; kk < TEISUU.SUU_MAXKUKANSUU; kk++) {
        final List<RekidaiKiroku> zentai = rekidaiAwaseru(
          ichii: ichiiZentaiKukan(gh, race, kk).yomu(),
          nihonjin: rekidaiZentaiKukan(kiroku, false, race, kk).yomu(),
          ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, kk).yomu(),
        );
        final List<RekidaiKiroku> gakunai = (u == null || u.time_univkukankiroku.length <= race)
            ? const <RekidaiKiroku>[]
            : rekidaiAwaseru(
                ichii: ichiiUnivKukan(u, race, kk).yomu(),
                nihonjin: rekidaiUnivKukan(kiroku, false, u.id, race, kk).yomu(),
                ryuugakusei: rekidaiUnivKukan(kiroku, true, u.id, race, kk).yomu(),
              );
        miru(zentai);
        miru(gakunai);
        for (int gk = 1; gk <= 4; gk++) {
          int ichi(List<RekidaiKiroku> l) => l.indexWhere((x) {
            final int? b = x.bangou;
            return b != null && kouho.contains(b) && x.gakunen == gk;
          });
          final int z = ichi(zentai);
          final int g = ichi(gakunai);
          if (z < 0 && g < 0) continue;
          final RekidaiKiroku kiroku1 = z >= 0 ? zentai[z] : gakunai[g];
          gyou.add([
            '${_raceMei(race, custom)}${kk + 1}区($gk年)',
            jikanMoji(kiroku1.time),
            _juniMasu(z),
            if (u != null) _juniMasu(g),
          ]);
        }
      }
    }
    if (gyou.isEmpty) return (hyou: null, furuiAri: furuiAri);
    return (
      hyou: KijiHyou('歴代記録(10位以内)', ['種目・区間', 'タイム', '全体', if (u != null) '学内'], gyou),
      furuiAri: furuiAri,
    );
  } catch (_) {
    return (hyou: null, furuiAri: false);
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
