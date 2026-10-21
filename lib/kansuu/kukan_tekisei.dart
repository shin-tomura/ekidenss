import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_tokuchou.dart';

// ------------------------------------------------------------
// 区間適性の見立て(2.1.1)
// 区間エントリー・当日変更・学連選抜編成(監督をしている年)の画面の「区間適性の見立て」
// (Modal_kukanTekisei.dart)の中身。ニュース記事の選手の特徴の文(kiji_tokuchou.dart)と同じ見方で、
// 見えている記録だけから見る(能力値は見ないので、能力を見抜く仕組みは変わらない)
//  ・距離: 5000m・1万m・ハーフの学生全体の順位で一番良い種目と、区間の距離(大会の中で長めか短めかも)
//  ・型: トラックの1万mとロード1万の学生全体の順位(1区向き・2区3区向き・後半向き)
//  ・坂: 登り・下り・アップダウンの区間だけ。登り1万・下り1万・クロカン1万の学生全体の順位
//  ・経験: 同じ大会の同じ区間を前の学年までに走った回数と、前回の区間順位
// ほかの大学の区間配置とは比べない(区間内順位は使わない)。どの画面でも同じ見立てになる。
// 印は ◎(合う)・○(問題なし)・△(課題あり)・−(記録が足りない)
// ------------------------------------------------------------

/// 見立ての印
enum TekiseiShirushi {
  au('◎'),
  mondaiNashi('○'),
  kadai('△'),
  fumei('−');

  const TekiseiShirushi(this.moji);

  /// 画面に出す印
  final String moji;
}

/// 見立てる選手1人(大学の選手と学連選抜の選手をまとめて扱う)
class TekiseiSenshu {
  final int id;

  /// 一覧に出す名前(「山田太郎 (3年)」。学連選抜の選手は所属大学も)
  final String hyoujiMei;

  final int gakunen;

  /// 比較用の持ちタイム(種目ごと。MochiHyou と同じ今季ベスト(なければ自己ベスト))
  final List<double> times;

  /// 大会ごと・学年ごとの区間エントリーと区間順位(経験に使う)
  final List<List<int>> entrykukanRace;
  final List<List<int>> kukanjuniRace;

  /// 体調不良か(当日変更・区間エントリーの画面の【体調不良】と同じ)
  final bool taichouFuryou;

  const TekiseiSenshu({
    required this.id,
    required this.hyoujiMei,
    required this.gakunen,
    required this.times,
    required this.entrykukanRace,
    required this.kukanjuniRace,
    required this.taichouFuryou,
  });

  /// 大学の選手から作る([soe] 名前のかっこの中の学年の後ろに付ける文。主将の印など)
  factory TekiseiSenshu.senshu(SenshuData s, MochiHyou hyou, {String soe = ''}) => TekiseiSenshu(
    id: s.id,
    hyoujiMei: '${s.name} (${s.gakunen}年$soe)',
    gakunen: s.gakunen,
    times: hyou.times(s),
    entrykukanRace: s.entrykukan_race,
    kukanjuniRace: s.kukanjuni_race,
    taichouFuryou: s.chousi == 0,
  );

  /// 学連選抜の選手から作る([univMei] 所属大学の名前)
  /// 体調不良の印は付けない(学連選抜編成の画面でも、調子の数字だけを出しているため)
  factory TekiseiSenshu.gakuren(Senshu_Gakuren_Data g, String univMei) => TekiseiSenshu(
    id: g.id,
    hyoujiMei: univMei.isEmpty ? '${g.name} (${g.gakunen}年)' : '${g.name} (${g.gakunen}年・$univMei)',
    gakunen: g.gakunen,
    times: MochiHyou.timesGakuren(g),
    entrykukanRace: g.entrykukan_race,
    kukanjuniRace: g.kukanjuni_race,
    taichouFuryou: false,
  );
}

/// 選手1人が区間1つを走るときの見立て
class KukanTekisei {
  /// 距離の印と型の呼び方(「スピード型」など。記録が足りなければ空)
  final TekiseiShirushi kyori;
  final String kyoriMei;

  /// 区間の型の印と呼び方(「1区向き」など。記録が足りなければ空)
  final TekiseiShirushi kata;
  final String kataMei;

  /// 坂の印(坂を見ない平坦な区間はnull)と呼び方(「登り」「下り」「起伏」)
  final TekiseiShirushi? saka;
  final String sakaMei;

  /// 前の学年までに同じ大会の同じ区間を走った回数と、前回の区間順位の文(「区間4位」。分からなければnull)
  final int keiken;
  final String? zenkai;

  /// 一言(です・ます)
  final String hitokoto;

  const KukanTekisei({
    required this.kyori,
    required this.kyoriMei,
    required this.kata,
    required this.kataMei,
    required this.saka,
    required this.sakaMei,
    required this.keiken,
    required this.zenkai,
    required this.hitokoto,
  });
}

/// 距離の型の呼び方(一番良い種目 0: 5000m、1: 1万m、2: ハーフ)
const List<String> _kyoriKataMei = ['スピード型', '1万m型', '距離型'];

/// 距離の種目の呼び方
const List<String> _kyoriShumokuMei = ['5000m', '1万m', 'ハーフ'];

/// 区間の型の呼び方(0: 1区向き、1: 2・3区向き、2: 後半向き)
const List<String> _mukiMei = ['1区向き', '2・3区向き', '後半向き'];

/// 持ちタイムの種目の呼び方(time_bestkiroku の0〜7。並びの説明に使う)
const List<String> tekiseiShumokuMei = ['5000m', '1万m', 'ハーフ', 'フル', '登り1万', '下り1万', 'ロード1万', 'クロカン1万'];

/// 区間[kk]の起伏の呼び方(区間の見出しに使う。「山登り」「平坦」など)
String kukanKifukuMei(Ghensuu gh, int race, int kk) {
  switch (kukanTokuchou(gh, race, kk)) {
    case KukanTokuchou.yamaNobori:
      return '山登り';
    case KukanTokuchou.yamaKudari:
      return '山下り';
    case KukanTokuchou.nobori:
      return '上り基調';
    case KukanTokuchou.kudari:
      return '下り基調';
    case KukanTokuchou.updown:
      return 'アップダウン';
    case KukanTokuchou.heitan:
      return updownKaru(gh, race, kk) ? '平坦・細かな起伏あり' : '平坦';
  }
}

/// 選手[s]の、大会[race]の区間[kk]の経験(前の学年までに走った回数と、前回の区間順位の文)
/// 区間順位は、学連選抜(オープン参加)で走ったときは「区間○位相当」
({int kaisuu, String? zenkai}) tekiseiKeiken(TekiseiSenshu s, int race, int kk) {
  if (race < 0 || race >= s.entrykukanRace.length) return (kaisuu: 0, zenkai: null);
  final List<int> e = s.entrykukanRace[race];
  final List<int>? j = race < s.kukanjuniRace.length ? s.kukanjuniRace[race] : null;
  int kaisuu = 0;
  String? zenkai;
  for (int i = 0; i < s.gakunen - 1 && i < e.length; i++) {
    if (e[i] != kk) continue;
    kaisuu++;
    // 学年の順に見るので、最後に入るのが一番近い年(前回)
    zenkai = null;
    if (j != null && i < j.length) {
      final int juni = j[i];
      if (gakurenShussouJuni(race, juni)) {
        zenkai = '区間${juni - 100 + 1}位相当';
      } else if (juni >= 0 && juni < TEISUU.DEFAULTJUNI) {
        zenkai = '区間${juni + 1}位';
      }
    }
  }
  return (kaisuu: kaisuu, zenkai: zenkai);
}

/// 一言の材料(印・文・並べる順。順の小さいものを先に見る)
class _Bun {
  final TekiseiShirushi shirushi;
  final String bun;
  final int jun;

  /// 山の区間・アップダウンの区間の坂で、記録がないとき(課題と同じく必ず触れる)
  final bool fumeiKadai;

  const _Bun(this.shirushi, this.bun, this.jun, {this.fumeiKadai = false});
}

/// 選手[s]が大会[race]の区間[kk]を走るときの見立て([hyou] 学生全体の順位の表)
KukanTekisei kukanTekiseiMiru(Ghensuu gh, int race, MochiHyou hyou, TekiseiSenshu s, int kk) {
  final List<double> t = s.times;
  final String km = kmMoji(gh.kyori_taikai_kukangoto[race][kk]);
  final List<_Bun> bunList = [];

  // 距離(kiji_tokuchou.dart の _kyori と同じ型の決め方。区間の基本の種目との差で印を決める)
  TekiseiShirushi kyori = TekiseiShirushi.fumei;
  String kyoriMei = '';
  final ({int best, bool anteishita, List<int> z})? kd = kyoriKata(hyou, t);
  if (kd != null) {
    if (kd.anteishita) {
      kyori = TekiseiShirushi.mondaiNashi;
      kyoriMei = '安定型';
      bunList.add(_Bun(kyori, 'どの距離でも順位が大きく変わらない型で、$kmでも持ちタイムどおりの走りが見込めます。', 1));
    } else {
      final int best = kd.best;
      final int kihon = kukanKihonShumoku(gh, race, kk);
      final int nagasa = taikaiNoNagasa(gh, race, kk);
      kyoriMei = _kyoriKataMei[best];
      final String tokui = '${_kyoriShumokuMei[best]}が一番の型で、';
      final String bun;
      if (best == kihon) {
        // 持ち味の距離の範囲でも、距離に強い型で大会の中では短め、スピード型で長めなら○
        if ((best == 2 && nagasa == -1) || (best == 0 && nagasa == 1)) {
          kyori = TekiseiShirushi.mondaiNashi;
          bun = '$tokui$kmは持ち味の距離ですが、この大会では${nagasa == 1 ? '長め' : '短め'}の区間です。';
        } else {
          kyori = TekiseiShirushi.au;
          bun = '$tokui$kmは持ち味の距離です。';
        }
      } else {
        // 区間のほうが長い(nagai)か短いか。1つ違いなら○、大会の中でも離れる向きなら△、2つ違いは△
        final bool nagai = best < kihon;
        final bool hanareru = nagai ? nagasa == 1 : nagasa == -1;
        final bool sukui = nagai ? nagasa == -1 : nagasa == 1;
        final bool futatsu = (best - kihon).abs() >= 2;
        kyori = (futatsu || hanareru) ? TekiseiShirushi.kadai : TekiseiShirushi.mondaiNashi;
        final String nagasaMoji = nagai ? '長' : '短';
        if (futatsu) {
          bun = '$tokui$kmは持ち味の距離より${nagasaMoji}いです。';
        } else if (sukui) {
          bun = '$tokui$kmは持ち味の距離より${nagasaMoji}いですが、この大会では${nagai ? '短め' : '長め'}の区間です。';
        } else if (hanareru) {
          bun = '$tokui$kmはこの大会でも${nagasaMoji}めの区間で、持ち味の距離から離れています。';
        } else {
          bun = '$tokui$kmは持ち味の距離よりやや${nagasaMoji}いです。';
        }
      }
      bunList.add(_Bun(kyori, bun, 1));
    }
  }

  // 区間の型(kiji_tokuchou.dart の _kukanKata と同じ。向きと区間の型の差で印を決める)
  TekiseiShirushi kata = TekiseiShirushi.fumei;
  String kataMei = '';
  final ({int muki, int zTrack, int zRoad})? km2 = kukanMuki(hyou, t);
  if (km2 != null) {
    final int muki = km2.muki;
    final int ima = kukanIma(kk);
    final int sa = (muki - ima).abs();
    kata = sa == 0 ? TekiseiShirushi.au : (sa == 1 ? TekiseiShirushi.mondaiNashi : TekiseiShirushi.kadai);
    kataMei = _mukiMei[muki];
    final String bun;
    if (sa == 0) {
      bun = const [
        'トラックの1万mのほうが順位が良く、ペースの変化に強い1区向きの型です。',
        'トラックとロードの順位が同じくらいで、2区・3区向きの型です。',
        'ロード1万のほうが順位が良く、後半区間向きの型です。',
      ][muki];
    } else if (ima == 0) {
      bun = muki == 1
          ? 'トラックとロードの順位が同じくらいの型で、1区では集団のペースの変化についていけるかが鍵です。'
          : 'ロードで力を出す型で、1区ではペースの変化への対応が課題です。';
    } else if (ima == 1) {
      bun = muki == 0
          ? 'トラック寄りの型で、${kk + 1}区ではロードへの対応も問われます。'
          : 'ロード寄りの型で、${kk + 1}区ではペースの変化への対応も問われます。';
    } else {
      bun = muki == 1
          ? 'トラックとロードの順位が同じくらいの型で、${kk + 1}区では単独走でロードを押す力が問われます。'
          : 'トラックで力を出す型で、${kk + 1}区ではロードで一人で押す力が課題です。';
    }
    bunList.add(_Bun(kata, bun, 2));
  }

  // 坂(登り・下り・アップダウンの区間と、平坦でも細かなアップダウンが続く区間だけ)
  TekiseiShirushi? saka;
  String sakaMei = '';
  final KukanTokuchou tok = kukanTokuchou(gh, race, kk);
  final bool karu = tok == KukanTokuchou.heitan && updownKaru(gh, race, kk);
  if (tok != KukanTokuchou.heitan || karu) {
    final bool nobori = tok == KukanTokuchou.yamaNobori || tok == KukanTokuchou.nobori;
    final bool kudari = tok == KukanTokuchou.yamaKudari || tok == KukanTokuchou.kudari;
    final int ev = nobori ? 4 : (kudari ? 5 : 7);
    sakaMei = nobori ? '登り' : (kudari ? '下り' : '起伏');
    final String evMei = tekiseiShumokuMei[ev];
    final String basho = tok == KukanTokuchou.yamaNobori
        ? '山登り'
        : (tok == KukanTokuchou.yamaKudari ? '山下り' : (nobori ? '登り' : (kudari ? '下り' : 'アップダウン')));
    // 山の区間とアップダウンが50回以上の区間は、坂を一番に見る
    final bool omoi =
        tok == KukanTokuchou.yamaNobori || tok == KukanTokuchou.yamaKudari || tok == KukanTokuchou.updown;
    final int jun = omoi ? 0 : 3;
    final int z = hyou.zentai(t[ev], ev);
    if (z > 0) {
      final int d = sanbunDan(z, hyou.zentaiSuu(ev));
      saka = const [TekiseiShirushi.au, TekiseiShirushi.mondaiNashi, TekiseiShirushi.kadai][d];
      final String bun = d == 0
          ? '$evMeiの順位が良く、$bashoに強みがあります。'
          : (d == 2 ? '$evMeiの順位が低く、$bashoが課題です。' : '$evMeiの順位は学生全体の中ほどです。');
      bunList.add(_Bun(saka, bun, jun));
    } else {
      saka = TekiseiShirushi.fumei;
      bunList.add(_Bun(saka, '$evMeiの記録がなく、$bashoへの適性は見立てられません。', jun, fumeiKadai: omoi));
    }
  }

  final ({int kaisuu, String? zenkai}) kei = tekiseiKeiken(s, race, kk);
  return KukanTekisei(
    kyori: kyori,
    kyoriMei: kyoriMei,
    kata: kata,
    kataMei: kataMei,
    saka: saka,
    sakaMei: sakaMei,
    keiken: kei.kaisuu,
    zenkai: kei.zenkai,
    hitokoto: _hitokoto(bunList),
  );
}

/// 一言(合うところを1つと、課題を1つ。どちらもなければ問題なしのところを1つ)
String _hitokoto(List<_Bun> bunList) {
  final List<_Bun> jun = List<_Bun>.of(bunList)..sort((a, b) => a.jun.compareTo(b.jun));
  final _Bun? tsuyomi = jun.where((b) => b.shirushi == TekiseiShirushi.au).firstOrNull;
  final _Bun? kadai = jun.where((b) => b.shirushi == TekiseiShirushi.kadai || b.fumeiKadai).firstOrNull;
  if (tsuyomi != null && kadai != null) return '${tsuyomi.bun}ただ、${kadai.bun}';
  if (tsuyomi != null) return tsuyomi.bun;
  if (kadai != null) return kadai.bun;
  final _Bun? futsuu = jun.where((b) => b.shirushi == TekiseiShirushi.mondaiNashi).firstOrNull;
  if (futsuu != null) return futsuu.bun;
  return '記録が足りず、まだ見立てられません。';
}

/// 見立てを言う人の呼び方(自分の大学[univid]のコーチ(長距離)→コーチ(トラック)→監督の順に、いる人。
/// 誰もいなければ「スタッフ」。監督とコーチは計算に影響しないので、言葉を言うだけ)
String tekiseiKataribe(KijiKankyou k, int univid) {
  // kantokuMei は KantokuData.rid の番号をそのまま見るので、コーチ(大学id+UNIVSUU・+UNIVSUU*2)にも使える
  final String? choukyori = k.kantokuMei(univid + TEISUU.UNIVSUU * 2)?.name;
  if (choukyori != null) return 'コーチ(長距離)$choukyori';
  final String? track = k.kantokuMei(univid + TEISUU.UNIVSUU)?.name;
  if (track != null) return 'コーチ(トラック)$track';
  final String? kantoku = k.kantokuMei(univid)?.name;
  if (kantoku != null) return '監督$kantoku';
  return 'スタッフ';
}
