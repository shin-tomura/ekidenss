import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // 大会の名前(courseRaceTitle)
import 'package:ekiden/kansuu/custom_seigen.dart'; // カスタム駅伝の出場制限(1年生だけか)

// ------------------------------------------------------------
// ニュース記事(箱庭スポーツ)の共通の部品(1.9.2)
//
// 記事は次の3段で作る(大会の結果は kiji_kekka.dart・kiji_yosen.dart、展望は kiji_tenbou.dart)
//  1. 事実を集める: 順位・タイム差・首位交代・連覇・区間賞などを、データから先に全部出す
//  2. 切り口を選ぶ: 事実ごとにニュース価値の点を付け、一番高いものを見出しとリードにする
//  3. 文を組み立てる: 場面ごとの言い回しを数通りずつ持ち、年・大会・記事で決まる乱数で選ぶ
//     (何度開いても同じ記事になる。同じ記事の中では同じ言い回しを重ねない)
//
// 型っぽさを減らす仕組み(1.9.4。まず駅伝の結果の記事(kiji_kekka.dart)で使う)
//  ・因縁(senshuInnen): 選手ごとの年別のデータから、「昨年は当日変更で外れた」「3年連続の同じ区間」
//    「昨年の同じ区間から順位を上げた」「入学時の記録からの伸び」などを点数つきで見つける
//  ・事実入りのコメント(kiji_comment.dart の senshuCommentJijitsu): 気持ちの言葉に、その選手の
//    因縁やその日の数字(抜いた人数・差・相手)を話し言葉で足す
//  ・文のリズム(KijiKakite): 直前の2つの文末が同じ形(「〜した。」が続くなど)なら、言い回しの候補から
//    違う文末のものを選ぶ
//  ・記者の型(KishaKata): 署名の記者名から「数字で語る」「情景で語る」「辛口」の型が決まり、
//    リードの入り方と「記者の目」の欄に効く(同じ記者はいつも同じ型)
//
// 守る決まり
//  ・能力値は書かない(見抜く力の仕組みを壊さないため)。勝因・敗因は、区間順位・タイム差・
//    当日変更・1区のペースなど、結果から言えることだけにする
//  ・趣味は、趣味非表示設定(KantokuData.yobiint2[15]=1)のときは書かない
//  ・総監督(プレイヤー)の言葉は作らない。コメントは選手と、大学の監督(OB)のものだけ
//  ・文体はニュース記事らしく常体(〜した。)。コメントの中は話し言葉
// ------------------------------------------------------------

/// サイト名
const String kijiSiteMei = '箱庭スポーツ';

/// 種目の名前(time_bestkiroku の番号)
const List<String> kijiShumokuMei = [
  '5000m',
  '1万m',
  'ハーフ',
  'フル',
  '登り1万',
  '下り1万',
  'ロード1万',
  'クロカン1万',
];

// ------------------------------------------------------------
// 記事の形
// ------------------------------------------------------------

/// 記事の本文の1かたまりの種類
enum KijiBlockShurui {
  /// ふつうの段落
  danraku,

  /// コメント(「」の発言。画面では左に線を引いて目立たせる)
  comment,

  /// 小見出し
  koMidashi,
}

/// 記事の本文の1かたまり
class KijiBlock {
  final KijiBlockShurui shurui;
  final String bun;

  const KijiBlock(this.shurui, this.bun);
}

/// 記事に付ける表(成績欄)
class KijiHyou {
  final String title;

  /// 列の見出し
  final List<String> retsu;

  /// 行(列の数は retsu と同じ)
  final List<List<String>> gyou;

  const KijiHyou(this.title, this.retsu, this.gyou);
}

/// ニュース記事1本
class Kiji {
  /// カテゴリ(「駅伝」「駅伝・展望」など)
  final String category;

  /// 見出し
  final String midashi;

  /// リード(最初の段落)
  final String lead;

  /// 本文
  final List<KijiBlock> honbun;

  /// 成績欄
  final List<KijiHyou> hyou;

  /// 配信日時の文
  final String haishin;

  /// 記者名
  final String kisha;

  /// 自分の大学の記事か(一覧で印を付ける)
  final bool jibun;

  /// 結果の記事か(false なら展望の記事。生成AIに渡すテキストの依頼文を変える)
  final bool kekka;

  /// サイトの名前(1.9.3。学内メディアの記事は「○○スポーツ」。それ以外は箱庭スポーツ)
  final String site;

  /// 学内メディア(自分の大学の○○スポーツ)の記事か(1.9.3。kiji_gakunai.dart)
  final bool gakunai;

  const Kiji({
    required this.category,
    required this.midashi,
    required this.lead,
    required this.honbun,
    required this.hyou,
    required this.haishin,
    required this.kisha,
    required this.jibun,
    required this.kekka,
    this.site = kijiSiteMei,
    this.gakunai = false,
  });

  /// 記事の全文(生成AIに渡すテキストと、デバッグのログに使う)
  String zenbun() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('【$site】$category');
    sb.writeln('■ $midashi');
    sb.writeln('$haishin $kisha');
    sb.writeln();
    sb.writeln(lead);
    for (final KijiBlock b in honbun) {
      switch (b.shurui) {
        case KijiBlockShurui.koMidashi:
          sb.writeln();
          sb.writeln('◆${b.bun}');
          break;
        case KijiBlockShurui.comment:
        case KijiBlockShurui.danraku:
          sb.writeln(b.bun);
          break;
      }
    }
    for (final KijiHyou h in hyou) {
      sb.writeln();
      sb.writeln('【${h.title}】');
      sb.writeln(h.retsu.join(' / '));
      for (final List<String> g in h.gyou) {
        sb.writeln(g.join(' / '));
      }
    }
    return sb.toString();
  }
}

// ------------------------------------------------------------
// 言い回しを選ぶ乱数(年・大会・記事で決まる。何度開いても同じ記事になる)
// ------------------------------------------------------------

class KijiRand {
  static const int _m = 2147483647;
  int _x;

  /// [tane] 年・大会・記事の番号などから作った数
  KijiRand(int tane) : _x = (tane.abs() % (_m - 1)) + 1 {
    for (int i = 0; i < 3; i++) {
      _tsugi();
    }
  }

  // 掛け算が2の53乗を超えないので、Web版でも同じ値になる
  int _tsugi() {
    _x = (_x * 48271) % _m;
    return _x;
  }

  /// 0以上[n]未満の整数
  int ikutsu(int n) {
    if (n <= 1) return 0;
    return _tsugi() % n;
  }

  /// [pct]%の確率でtrue
  bool kakuritsu(int pct) => ikutsu(100) < pct;

  /// 並びから1つ選ぶ
  T erabu<T>(List<T> narabi) => narabi[ikutsu(narabi.length)];
}

/// 乱数の種(年・大会・記事の番号・つけたし)
int kijiTane(Ghensuu gh, int race, int kijiBangou, [int tsuika = 0]) =>
    gh.year * 7919 + race * 104729 + kijiBangou * 1299709 + tsuika * 15485863;

// ------------------------------------------------------------
// 記者の型(1.9.4)。署名の記者名から決めるので、同じ記者はいつも同じ型
// ------------------------------------------------------------

enum KishaKata {
  /// 数字で語る(タイム差・順位の数字から入る)
  suuji,

  /// 情景で語る(選手の因縁や場面から入る)
  joukei,

  /// 辛口(課題を指摘する。自分の大学には、目標に届かなかったときだけ辛口)
  karakuchi,
}

/// 記者名の文字から型を決める
KishaKata kishaKataKara(String kishaMei) {
  int h = 0;
  for (final int c in kishaMei.codeUnits) {
    h = (h * 31 + c) % 1000003;
  }
  return KishaKata.values[h % KishaKata.values.length];
}

// ------------------------------------------------------------
// 選手の因縁(1.9.4)。年別のデータから、記事の切り口になる事実を見つける
// ------------------------------------------------------------

/// 因縁の種類
enum InnenShurui {
  /// 昨年は当日変更で区間から外れた
  hazureta,

  /// 昨年は補欠のまま出番がなかった
  hoketsu,

  /// 同じ区間を何年も続けて走っている
  onajiKukan,

  /// 昨年の同じ区間から順位を上げた
  juniUe,

  /// 昨年の同じ区間の順位に届かなかった
  juniShita,

  /// 昨年は別の区間を走った
  betsuKukan,

  /// 初めての駅伝
  debut,

  /// 4年生の最後の大会
  saigo,

  /// 入学時の記録から大きく伸びた
  nyuugakuNobi,

  /// 区間賞を何度も取っている
  kukanshouTsuusan,
}

/// 選手の因縁1つ
class Innen {
  final InnenShurui shurui;

  /// ニュース価値(大きいほど見出しやリードに使う)
  final int ten;

  /// 地の文(常体。「。」で終わる。選手の呼び方は呼ぶ側で前に付ける)
  final String bun;

  /// 選手の話し言葉(「」の中に入れる。「。」なし)
  final String kotoba;

  /// 見出しに使う短い句(「1年前は走れなかった」など。見出し向きでなければ空)
  final String midashiKu;

  const Innen(this.shurui, this.ten, this.bun, this.kotoba, [this.midashiKu = '']);
}

/// 年度の中の大会の順(11月駅伝予選・10月駅伝・正月駅伝予選・11月駅伝・正月駅伝・カスタム駅伝)
const List<int> _innenRaceJun = [3, 0, 4, 1, 2, 5];

/// 選手[s]が、記事にする大会より前に駅伝(本戦。予選は除く)の区間を走った回数と、
/// そのうち区間賞の回数(今の学年の、記事にする大会とそれより後の大会は除く)
({int kaisuu, int kukanshou}) ekidenShussouKaisuu(KijiKankyou k, SenshuData s) {
  int kaisuu = 0;
  int kukanshou = 0;
  final int imaJun = _innenRaceJun.indexOf(k.race);
  for (int g = 1; g <= s.gakunen; g++) {
    for (int ji = 0; ji < _innenRaceJun.length; ji++) {
      final int race = _innenRaceJun[ji];
      if (race == 3 || race == 4) continue;
      if (g == s.gakunen && imaJun >= 0 && ji >= imaJun) continue;
      if (s.entrykukan_race.length <= race) continue;
      if (s.entrykukan_race[race].length < g) continue;
      if (s.entrykukan_race[race][g - 1] < 0) continue;
      kaisuu++;
      if (s.kukanjuni_race.length > race &&
          s.kukanjuni_race[race].length >= g &&
          s.kukanjuni_race[race][g - 1] == 0) {
        kukanshou++;
      }
    }
  }
  return (kaisuu: kaisuu, kukanshou: kukanshou);
}

/// 選手[s]の因縁(点の高い順)。駅伝の結果の記事で、区間[kk]を区間順位[kj](0が1位)で走ったとき
/// ([kj]がnullなら、今の走りと比べる因縁は出さない。大学の順位の記録の[1]を昨年として見るので、
/// 結果の記事(大会のあと)で使う)
List<Innen> senshuInnen(KijiKankyou k, SenshuData s, int kk, {int? kj}) {
  final List<Innen> list = [];
  final int race = k.race;
  final String raceMei = k.raceMei;
  // 昨年のこの大会(大学が昨年出場していなければ、昨年の区間エントリーの値は意味を持たない)
  final UnivData? u = (s.univid >= 0 && s.univid < k.univ.length)
      ? k.univ[s.univid]
      : null;
  final bool kyonenShutsujou = u != null && shutsujouJuni(juniRace(u, race, 1));
  final int maeE = kyonenShutsujou ? k.entryMae(s, race, 1) : -2;
  final int? maeJ = kyonenShutsujou ? k.kukanJuniMae(s, race, 1) : null;
  if (maeE <= -100) {
    list.add(
      const Innen(
        InnenShurui.hazureta,
        90,
        '昨年は当日変更で区間から外れ、たすきを受けられなかった。',
        '去年は当日に外れて、何もできないまま終わった。だから今年は、走るところを見せたかった',
        '1年前は走れなかった',
      ),
    );
  } else if (maeE == -1) {
    list.add(
      const Innen(
        InnenShurui.hoketsu,
        60,
        '昨年は補欠のまま、出番が回ってこなかった。',
        '去年は補欠で、仲間の走りを見ているだけだった。その悔しさをずっと持っていた',
        '昨年は補欠だった',
      ),
    );
  } else if (maeE == kk) {
    // 同じ区間を何年続けて走っているか(今回を含む)
    int renzoku = 1;
    for (int n = 1; n <= 3; n++) {
      if (k.entryMae(s, race, n) == kk) {
        renzoku++;
      } else {
        break;
      }
    }
    if (maeJ != null && kj != null && maeJ - kj >= 3) {
      list.add(
        Innen(
          InnenShurui.juniUe,
          70 + (maeJ - kj >= 6 ? 10 : 0),
          '昨年の同じ区間は区間${maeJ + 1}位。${maeJ - kj}つ順位を上げた。',
          '去年は区間${maeJ + 1}位で終わっていたので、今年は絶対に上げたかった',
          '昨年区間${maeJ + 1}位からの',
        ),
      );
    } else if (maeJ != null && kj != null && kj - maeJ >= 3) {
      list.add(
        Innen(
          InnenShurui.juniShita,
          40,
          '昨年は同じ区間で区間${maeJ + 1}位。今年は、その走りには届かなかった。',
          '去年の自分を超えられなかった。それが一番悔しい',
        ),
      );
    }
    if (renzoku >= 2) {
      list.add(
        Innen(
          InnenShurui.onajiKukan,
          45 + (renzoku - 2) * 15,
          '$renzoku年連続で${kk + 1}区を任された${maeJ != null ? '(昨年は区間${maeJ + 1}位)' : ''}。',
          '$renzoku年続けてこの区間を走らせてもらっている。コースは体が覚えている',
          '$renzoku年連続の${kk + 1}区で',
        ),
      );
    }
  } else if (maeE >= 0) {
    list.add(
      Innen(
        InnenShurui.betsuKukan,
        30,
        '昨年は${maeE + 1}区${maeJ != null ? '(区間${maeJ + 1}位)' : ''}を走った。',
        '去年とは違う区間で、新しい挑戦だった',
      ),
    );
  }
  // 初めての駅伝(1年生だけの大会では、全員が初めてなので出さない)
  final ({int kaisuu, int kukanshou}) reki = ekidenShussouKaisuu(k, s);
  if (reki.kaisuu == 0 && !k.ichinenDake) {
    list.add(
      s.gakunen == 1
          ? const Innen(
              InnenShurui.debut,
              45,
              'これが大学駅伝のデビュー戦だった。',
              '初めての駅伝で、たすきの重さが分かった',
              'デビュー戦の',
            )
          : Innen(
              InnenShurui.debut,
              55,
              '${s.gakunen}年目で初めてつかんだ駅伝の舞台だった。',
              '${s.gakunen}年目でやっとこの舞台に立てた。走れない時間が長かった分、うれしかった',
              '${s.gakunen}年目で初出走の',
            ),
    );
  }
  // 区間賞を何度も取っている(今回も区間賞のとき)
  if (kj == 0 && reki.kukanshou >= 1) {
    list.add(
      Innen(
        InnenShurui.kukanshouTsuusan,
        45,
        '区間賞は通算${reki.kukanshou + 1}度目となった。',
        '区間賞は${reki.kukanshou + 1}度目になるけど、毎回違う苦しさがある',
      ),
    );
  }
  // 4年生の最後の大会
  if (s.gakunen == 4) {
    list.add(
      race == 2
          ? const Innen(
              InnenShurui.saigo,
              50,
              'これが最後の正月駅伝だった。',
              '4年間の最後に、この区間を走れて幸せだった',
              '最後の正月駅伝で',
            )
          : Innen(
              InnenShurui.saigo,
              25,
              '4年生にとっては、これが最後の$raceMeiだった。',
              '最後の$raceMeiなので、悔いだけは残したくなかった',
            ),
    );
  }
  // 入学時の記録からの伸び(5000m。留学生は除く)
  if (s.hirou != 1 && s.gakunen >= 2) {
    final double ny = s.kiroku_nyuugakuji_5000;
    final double best = k.jikoBest(s, 0);
    if (ny > 0 && ny < TEISUU.DEFAULTTIME && best < TEISUU.DEFAULTTIME) {
      final int nyFun = byou(ny) ~/ 60;
      final int bestFun = byou(best) ~/ 60;
      if (nyFun - bestFun >= 1) {
        list.add(
          Innen(
            InnenShurui.nyuugakuNobi,
            35 + (nyFun - bestFun >= 2 ? 15 : 0),
            '入学時の5000mは$nyFun分台。今は${jikanMoji(best)}まで記録を伸ばしてきた。',
            '入学したときは5000mが$nyFun分台の選手だった。ここまで来られたのは、積み上げてきた練習のおかげ',
            '入学時$nyFun分台からの',
          ),
        );
      }
    }
  }
  list.sort((a, b) => b.ten.compareTo(a.ten));
  return list;
}

// ------------------------------------------------------------
// 記事を書くときに使うデータのまとめ
// ------------------------------------------------------------

class KijiKankyou {
  final Ghensuu gh;
  final KantokuData kantoku;

  /// id順(並びの番号=大学id)
  final List<UnivData> univ;

  /// id順(並びの番号=選手id)
  final List<SenshuData> senshu;

  /// 記事にする大会
  final int race;

  /// 結果の記事か(大会のあとか。カスタム駅伝の開催回数を数えるときに、今回を含めるかを決める。1.9.3)
  final bool kekka;

  KijiKankyou._(
    this.gh,
    this.kantoku,
    this.univ,
    this.senshu,
    this.race,
    this.kekka,
  );

  /// 今の表示中の大会でデータを読む(データがなければnull)
  /// [kekka] 結果の記事(大会のあと)のとき
  static KijiKankyou? yomu({bool kekka = false}) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return null;
    return yomuRace(gh.hyojiracebangou, kekka: kekka);
  }

  /// 大会[race]を記事にする大会としてデータを読む(データがなければnull)
  /// (1.9.3。表示中の大会と関係のない記事(学内メディアの卒業生特集)でも使う)
  static KijiKankyou? yomuRace(int race, {bool kekka = false}) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (gh == null || kantoku == null) return null;
    final List<UnivData> univ = Hive.box<UnivData>('univBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final List<SenshuData> senshu =
        Hive.box<SenshuData>('senshuBox').values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    // 駅伝・駅伝予選(0〜5)と、対校戦の3種目(6: 5000m、7: 1万m、8: ハーフ。1.9.2)
    if (race < 0 || race > 8) return null;
    if (gh.kukansuu_taikaigoto.length <= race) return null;
    return KijiKankyou._(gh, kantoku, univ, senshu, race, kekka);
  }

  /// 区間(組)の数
  int get kukansuu => gh.kukansuu_taikaigoto[race];

  /// 大会の名前(対校戦は種目に分かれているが、大会の名前は「対校戦」)
  String get raceMei => taikousen ? '対校戦' : courseRaceTitle(race);

  /// 「第○回正月駅伝」(回の数がそろわないカスタム駅伝は「カスタム駅伝」とだけ。1.9.3)
  String get taikaiMei {
    final int? kai = kaiNoKazu(gh.year);
    return kai == null ? raceMei : '第$kai回$raceMei';
  }

  /// 年[nen]に行われたこの大会の回の数(1.9.3。年度で数える。分からなければnull)
  /// ・年は1月に変わるので、1〜3月に行う正月駅伝とカスタム駅伝は「年の数−1」にする
  ///   (1.9.2までは年の数をそのまま使っていて、最初の正月駅伝が「第2回」になっていた)
  /// ・カスタム駅伝は開催しない年を設定で作れるので、年度で数えた回の数が開催の回数と
  ///   合わないとき(途中から開催したデータなど)はnull。開催の回数は、毎回全大学が出場するので、
  ///   出場回数の一番多い大学の回数で分かる(結果の記事では今回を含む)
  int? kaiNoKazu(int nen) {
    final bool ichigatsuIkou = race == 2 || race == customRaceBangou;
    final int kai = ichigatsuIkou ? nen - 1 : nen;
    if (kai < 1) return null;
    if (race == customRaceBangou) {
      int kaisai = 0;
      for (final UnivData u in univ) {
        final int c = shutsujouKaisuu(u, race);
        if (c > kaisai) kaisai = c;
      }
      if (!kekka) kaisai += 1;
      // 今回の大会の回の数が開催の回数と合わなければ、どの年の回の数も信用しない
      final int imaKai = gh.year - 1;
      if (kaisai != imaKai) return null;
    }
    return kai;
  }

  /// 駅伝(予選ではない)か
  bool get ekiden => race <= 2 || race == 5;

  /// 対校戦(5000m・1万m・ハーフの3種目のどれか)か(1.9.2)
  bool get taikousen => race >= 6 && race <= 8;

  /// 1年生だけのカスタム駅伝か(全員1年生なので、1年生を特別扱いする言い回しを出さない)
  bool get ichinenDake => race == customRaceBangou && customIchinenDake();

  /// 趣味を書かないか(趣味非表示設定)
  bool get shumiNashi =>
      kantoku.yobiint2.length > 15 && kantoku.yobiint2[15] == 1;

  /// 自分の大学
  UnivData? get jibunUniv =>
      (gh.MYunivid >= 0 && gh.MYunivid < univ.length) ? univ[gh.MYunivid] : null;

  /// 大学[u]がこの大会に出場しているか
  bool shutsujou(UnivData u) =>
      u.taikaientryflag.length > race && u.taikaientryflag[race] == 1;

  /// 選手[s]のこの大会の区間エントリー(範囲外なら-2)
  int entry(SenshuData s) {
    if (s.entrykukan_race.length <= race) return -2;
    final int g = s.gakunen - 1;
    if (g < 0 || g >= s.entrykukan_race[race].length) return -2;
    return s.entrykukan_race[race][g];
  }

  /// 選手[s]の、ほかの大会[r]の、[maeNen]年前の学年での区間エントリー(なければ-2)
  int entryMae(SenshuData s, int r, int maeNen) {
    if (s.entrykukan_race.length <= r) return -2;
    final int g = s.gakunen - 1 - maeNen;
    if (g < 0 || g >= s.entrykukan_race[r].length) return -2;
    return s.entrykukan_race[r][g];
  }

  /// 選手[s]の、大会[r]の、[maeNen]年前の学年での区間順位(なければnull。0が1位)
  int? kukanJuniMae(SenshuData s, int r, int maeNen) {
    if (s.kukanjuni_race.length <= r) return null;
    final int g = s.gakunen - 1 - maeNen;
    if (g < 0 || g >= s.kukanjuni_race[r].length) return null;
    final int j = s.kukanjuni_race[r][g];
    if (j < 0 || j >= TEISUU.DEFAULTJUNI) return null;
    return j;
  }

  /// 自己ベスト(なければ TEISUU.DEFAULTTIME)
  double jikoBest(SenshuData s, int idx) {
    if (idx < 0 || s.time_bestkiroku.length <= idx) return TEISUU.DEFAULTTIME;
    final double t = s.time_bestkiroku[idx];
    return t > 0 ? t : TEISUU.DEFAULTTIME;
  }

  /// 大学の監督(OB)の名前(不在ならnull)と年齢
  ({String name, int nenrei})? kantokuMei(int univid) {
    if (univid < 0 || univid >= kantoku.rid.length) return null;
    final int rid = kantoku.rid[univid];
    if (rid <= 0) return null;
    if (!Hive.isBoxOpen('retiredSenshuBox')) return null;
    for (final Senshu_R_Data r in Hive.box<Senshu_R_Data>(
      'retiredSenshuBox',
    ).values) {
      if (r.id == rid) {
        return (name: r.name, nenrei: gh.year - r.sijiflag + 22);
      }
    }
    return null;
  }

  /// 出身地(留学生や、分からないときはnull)
  String? shusshin(SenshuData s) {
    if (s.hirou == 1) return null;
    final Map<String, int> m = PackedIndexHelper.unpackIndices(s.samusataisei);
    final int p = m['prefectureIndex'] ?? -1;
    if (p < 0 || p >= LocationDatabase.allPrefectures.length) return null;
    return LocationDatabase.allPrefectures[p];
  }

  /// 趣味(趣味非表示設定のときや、分からないときはnull)
  String? shumi(SenshuData s) {
    if (shumiNashi) return null;
    final Map<String, int> m = PackedIndexHelper.unpackIndices(s.samusataisei);
    final int h = m['hobbyIndex'] ?? -1;
    if (h < 0 || h >= HobbyDatabase.allHobbies.length) return null;
    return HobbyDatabase.allHobbies[h];
  }

  /// 記者の名前(年・大会・記事で決まる)
  String kishaMei(int kijiBangou) {
    final KijiRand r = KijiRand(kijiTane(gh, race, kijiBangou, 77));
    final List<String> mae = [
      for (final String n in gh.name_mae)
        if (n.isNotEmpty) n,
    ];
    final List<String> ato = [
      for (final String n in gh.name_ato)
        if (n.isNotEmpty) n,
    ];
    if (mae.isEmpty || ato.isEmpty) return '$kijiSiteMei 駅伝取材班';
    return '$kijiSiteMei ${r.erabu(mae)}${r.erabu(ato)}';
  }

  /// 記者の型(1.9.4。記者名から決まるので、同じ記者はいつも同じ型)
  KishaKata kishaKata(int kijiBangou) => kishaKataKara(kishaMei(kijiBangou));

  /// 配信日時の文([asa]なら朝、そうでなければ午後の時刻)
  String haishinMei(int kijiBangou, {required bool asa}) {
    final KijiRand r = KijiRand(kijiTane(gh, race, kijiBangou, 31));
    final int ji = asa ? 6 + r.ikutsu(4) : 14 + r.ikutsu(6);
    final int fun = r.ikutsu(60);
    return '${gh.year}年${gh.month}月${gh.day}日 '
        '$ji:${fun.toString().padLeft(2, '0')} 配信';
  }
}

// ------------------------------------------------------------
// 文の部品(数字・名前の書き方)
// ------------------------------------------------------------

/// 大学の呼び方(「東西大」。名前が「大」「大学」で終わるときはそのまま)
String daigakuMei(UnivData u) => daigakuMeiMoji(u.name);

/// 大学の名前の文字から呼び方を作る(学連選抜の選手の所属など、名前しか分からないとき)
String daigakuMeiMoji(String name) {
  final String n = name.trim();
  if (n.endsWith('大学')) return n.substring(0, n.length - 1);
  if (n.endsWith('大')) return n;
  return '$n大';
}

/// 名前の空白を除いた形(初めて出すとき)
String fullMei(String name) => name.replaceAll(' ', '').replaceAll('　', '');

/// 名字(2回目からの呼び方)
String myouji(String name) {
  final List<String> p = name.trim().split(RegExp(r'[ 　]+'));
  return p.isEmpty ? name : p.first;
}

/// タイムの秒(画面と同じく小数を切り捨て)
int byou(double t) => t.floor();

/// タイムの文(1時間以上は「1時間02分33秒」、それより短いと「28分31秒」)
String jikanMoji(double t) {
  if (t >= 3600) return TimeDate.timeToJikanFunByouString(t);
  return TimeDate.timeToFunByouString(t);
}

/// タイム差の文(秒。「12秒」「1分05秒」。マイナスは絶対値で書く)
String saMoji(int sa) {
  final int s = sa.abs();
  if (s < 60) return '$s秒';
  return '${s ~/ 60}分${(s % 60).toString().padLeft(2, '0')}秒';
}

/// 僅差の言い方(「3秒差」。0秒なら、画面では秒まで同じタイムなので「1秒に満たない差」。1.9.2)
String kinsaMoji(int sa) => sa <= 0 ? '1秒に満たない差' : '${saMoji(sa)}差';

/// 1人あたりの差の言い方(「1人あたり0.3秒」。[ninzuu]人の合計の差[sa]秒から。1.9.2)
/// 0秒(1秒に満たない差)なら「1人あたりにすれば、まばたきほどの差」
String hitoriAtariMoji(int sa, int ninzuu) {
  if (ninzuu <= 0) return '';
  if (sa <= 0) return '1人あたりにすれば、まばたきほどの差';
  return '1人あたり${(sa / ninzuu).toStringAsFixed(1)}秒の差';
}

/// 2つのタイムの差の秒(画面と同じく、それぞれ切り捨ててから引く)
int saByou(double osoi, double hayai) => byou(osoi) - byou(hayai);

/// 順位の文(0が1位)
String juniMoji(int juni0) => '${juni0 + 1}位';

/// 距離の文(「21.3km」)
String kmMoji(double meter) => '${(meter / 1000.0).toStringAsFixed(1)}km';

/// 「2年連続5度目の」「3年ぶり4度目の」などの言い方(初めてのときは空。呼ぶ側で「初」を書く)
/// [renzoku] 今回を含めた連続の年数、[buri] 前回から何年ぶりか(分からなければnull)、[kaisuu] 今回を含めた回数
String renzokuMoji({
  required int renzoku,
  required int? buri,
  required int kaisuu,
}) {
  if (kaisuu <= 1) return '';
  if (renzoku >= 2) return '$renzoku年連続$kaisuu度目の';
  if (buri != null && buri >= 2) return '$buri年ぶり$kaisuu度目の';
  return '$kaisuu度目の';
}

// ------------------------------------------------------------
// 大学の過去の成績(範囲外は「出場なし」として扱う)
// ------------------------------------------------------------

/// 大会[race]の[nenMae]回前の順位(0が今回または直近。出場していなければ TEISUU.DEFAULTJUNI)
int juniRace(UnivData u, int race, int nenMae) {
  if (u.juni_race.length <= race) return TEISUU.DEFAULTJUNI;
  if (nenMae < 0 || u.juni_race[race].length <= nenMae) {
    return TEISUU.DEFAULTJUNI;
  }
  return u.juni_race[race][nenMae];
}

/// 大会[race]で順位[juni]になった回数
int juniKaisuu(UnivData u, int race, int juni) {
  if (u.taikaibetujunibetukaisuu.length <= race) return 0;
  if (juni < 0 || u.taikaibetujunibetukaisuu[race].length <= juni) return 0;
  return u.taikaibetujunibetukaisuu[race][juni];
}

/// 大会[race]に出場した回数
int shutsujouKaisuu(UnivData u, int race) {
  if (u.taikaibetushutujoukaisuu.length <= race) return 0;
  return u.taikaibetushutujoukaisuu[race];
}

/// [hajime]回前から続けて条件[jouken]に合う回数(順位で判定)
int renzokuKaisuu(
  UnivData u,
  int race,
  int hajime,
  bool Function(int juni) jouken,
) {
  int c = 0;
  for (int i = hajime; i < TEISUU.KIROKUHOZONNENSUU; i++) {
    if (!jouken(juniRace(u, race, i))) break;
    c++;
  }
  return c;
}

/// 続けて条件[jouken]に合った回数と、その数を言い切れるか(1.9.2)
/// 大学の順位の記録は直近 TEISUU.KIROKUHOZONNENSUU 回分しか残らないので、残っている記録が
/// [hajime]回前から全部条件に合っていたときは、もっと前から続いているかもしれない。
/// そのときは、全期間で条件に合った回数[tsuusan]([hajime]回前までの分)が数えた回数と同じなら
/// (それより前に条件に合ったことがないので)言い切れる。言い切れないときは、記事で数を出さない
({int kaisuu, bool kakutei}) renzokuKakutei(
  UnivData u,
  int race,
  int hajime,
  bool Function(int juni) jouken,
  int tsuusan,
) {
  final int c = renzokuKaisuu(u, race, hajime, jouken);
  if (c < TEISUU.KIROKUHOZONNENSUU - hajime) return (kaisuu: c, kakutei: true);
  return (kaisuu: c, kakutei: tsuusan <= c);
}

/// 全期間で大会[race]の順位が[seed]位より上(シード権)だった回数
int seedKaisuu(UnivData u, int race, int seed) {
  int n = 0;
  for (int j = 0; j < seed; j++) {
    n += juniKaisuu(u, race, j);
  }
  return n;
}

/// [hajime]回前より前で、最後に条件[jouken]に合ったのは何回前か(なければnull)
int? saigoNoKai(
  UnivData u,
  int race,
  int hajime,
  bool Function(int juni) jouken,
) {
  for (int i = hajime; i < TEISUU.KIROKUHOZONNENSUU; i++) {
    if (jouken(juniRace(u, race, i))) return i;
  }
  return null;
}

/// 出場していた順位か
bool shutsujouJuni(int juni) => juni >= 0 && juni < TEISUU.DEFAULTJUNI;

/// 大会[race]がまだ一度も行われていないか(どの大学も出場したことがない。ゲームを始めた年など)
/// 大会の前(展望)と、予選の結果の記事での本戦に使う。全校が「初出場」になるので、
/// 初出場を並べたり見出しにしたりせず、初めての開催として書く
bool mikaisai(KijiKankyou k, int race) {
  for (final UnivData u in k.univ) {
    if (shutsujouKaisuu(u, race) > 0) return false;
  }
  return true;
}

/// 今回が大会[race]の初めての開催だったか(結果の記事。今回の出場はもう数えてあるので、
/// どの大学も出場が1回以下なら初めての開催)
bool hatsuKaisaiKekka(KijiKankyou k, int race) {
  for (final UnivData u in k.univ) {
    if (shutsujouKaisuu(u, race) > 1) return false;
  }
  return true;
}

// ------------------------------------------------------------
// 三大駅伝(10月駅伝・11月駅伝・正月駅伝)の優勝校と三冠(1.9.3)
// ・10月駅伝から正月駅伝までを1つの季として見る。年は1月に変わるので、季は10月駅伝の年で
//   「○年度」と呼ぶ(正月駅伝の「第○回」とは数が1つずれる)
// ・大学の順位の記録の[0]は、その大会の直近の回。今の季にまだ行われていない大会は、[0]が前の季
// ・三冠の通算回数は UnivData.sankankaisuu(正月駅伝の記録の更新で、その季の三大駅伝を
//   すべて制した大学に1回足す。KirokuKousin.dart)
// ------------------------------------------------------------

/// 三大駅伝の大会の番号(10月駅伝・11月駅伝・正月駅伝)
const List<int> sandaiEkidenRace = [0, 1, 2];

/// 三大駅伝の優勝校を、季ごとに見る道具
class SandaiEkiden {
  final KijiKankyou k;

  /// 今の季に行われた、最後の三大駅伝の番号(-1なら、今の季はまだどれも行われていない)
  final int owari;

  SandaiEkiden._(this.k, this.owari);

  /// 記事にしている大会が三大駅伝でなければnull
  /// [kekka] 結果の記事なら、記事にしている大会も行われたものとする(展望の記事なら、まだ)
  static SandaiEkiden? tsukuru(KijiKankyou k, {required bool kekka}) {
    if (k.race < 0 || k.race > 2) return null;
    return SandaiEkiden._(k, kekka ? k.race : k.race - 1);
  }

  /// 今の季の大会[race]が、もう行われたか
  bool owatta(int race) => race <= owari;

  /// [kiMae]季前(0が今の季)の大会[race]の優勝校(まだ行われていない・記録がなければnull)
  UnivData? yuushou(int race, int kiMae) {
    final int idx = owatta(race) ? kiMae : kiMae - 1;
    if (idx < 0 || idx >= TEISUU.KIROKUHOZONNENSUU) return null;
    for (final UnivData u in k.univ) {
      if (juniRace(u, race, idx) == 0) return u;
    }
    return null;
  }

  /// 大学[u]が、[kiMae]季前に三冠を達成したか(その季の三大駅伝がすべて終わっていないときはfalse)
  bool sankan(UnivData u, int kiMae) {
    for (final int race in sandaiEkidenRace) {
      final UnivData? y = yuushou(race, kiMae);
      if (y == null || y.id != u.id) return false;
    }
    return true;
  }

  /// 大学[u]が[hajime]季前から続けて三冠を達成した季の数と、その数を言い切れるか
  /// (順位の記録は TEISUU.KIROKUHOZONNENSUU 回分しか残らないので、残っている季が全部三冠のときは、
  /// 通算の三冠の回数と比べる。renzokuKakutei と同じ考え方)
  ({int kaisuu, bool kakutei}) sankanRenzoku(UnivData u, int hajime) {
    int c = 0;
    for (int i = hajime; i < TEISUU.KIROKUHOZONNENSUU; i++) {
      if (!sankan(u, i)) break;
      c++;
    }
    final int saidai = TEISUU.KIROKUHOZONNENSUU - hajime;
    return (kaisuu: c, kakutei: c < saidai || u.sankankaisuu <= c);
  }

  /// 全大学の三冠の通算回数
  int get sankanGoukei => k.univ.fold<int>(0, (t, u) => t + u.sankankaisuu);

  /// [kiMae]季前の季の年度(10月駅伝の年。1〜3月は、前の年の10月駅伝からの季)
  int nendo(int kiMae) =>
      (k.gh.month <= 3 ? k.gh.year - 1 : k.gh.year) - kiMae;

  /// 今の季の三大駅伝の優勝校の表(まだ行われていない大会は「これから」)
  KijiHyou konkiHyou() {
    String mei(int race) {
      if (!owatta(race)) return 'これから';
      final UnivData? u = yuushou(race, 0);
      return u == null ? '-' : daigakuMei(u);
    }

    return KijiHyou('今季の三大駅伝', ['大会', '優勝校'], [
      for (final int race in sandaiEkidenRace) [courseRaceTitle(race), mei(race)],
    ]);
  }

  /// 三大駅伝の歴代優勝校の表(今の季の三大駅伝がすべて終わっていれば今の季から、[kisuu]季分。
  /// 記録のない季は出さない。三冠の季は、正月駅伝の欄に「(三冠)」を付ける)
  KijiHyou rekidaiHyou(int kisuu) {
    final int hajime = owari >= 2 ? 0 : 1;
    final List<List<String>> gyou = [];
    for (int i = hajime; i < hajime + kisuu; i++) {
      if (nendo(i) < 1) break;
      final List<UnivData?> y = [
        for (final int race in sandaiEkidenRace) yuushou(race, i),
      ];
      if (y.every((u) => u == null)) continue;
      final bool sk = y.every((u) => u != null && u.id == y[0]!.id);
      gyou.add([
        '${nendo(i)}年度',
        for (int j = 0; j < y.length; j++)
          (y[j] == null ? '-' : daigakuMei(y[j]!)) +
              (sk && j == y.length - 1 ? '(三冠)' : ''),
      ]);
    }
    return KijiHyou('三大駅伝の歴代優勝校', [
      '年度',
      for (final int race in sandaiEkidenRace) courseRaceTitle(race),
    ], gyou);
  }
}

// ------------------------------------------------------------
// 区間の特徴(展望・結果の記事で、区間の呼び方と見る種目を決める)
// ------------------------------------------------------------

enum KukanTokuchou { yamaNobori, yamaKudari, nobori, kudari, updown, heitan }

/// 登り指数(登り距離割合×平均勾配×10000。コース紹介の画面と同じ)
double noboriShisuu(Ghensuu gh, int race, int k) =>
    gh.kyoriwariainobori_taikai_kukangoto[race][k] *
    gh.heikinkoubainobori_taikai_kukangoto[race][k].abs() *
    10000.0;

/// 下り指数
double kudariShisuu(Ghensuu gh, int race, int k) =>
    gh.kyoriwariaikudari_taikai_kukangoto[race][k] *
    gh.heikinkoubaikudari_taikai_kukangoto[race][k].abs() *
    10000.0;

/// 区間の特徴
KukanTokuchou kukanTokuchou(Ghensuu gh, int race, int k) {
  final double nobori = noboriShisuu(gh, race, k);
  final double kudari = kudariShisuu(gh, race, k);
  final int ud = gh.noborikudarikirikaekaisuu_taikai_kukangoto[race][k];
  if (nobori >= 150 && nobori >= kudari) return KukanTokuchou.yamaNobori;
  if (kudari >= 150) return KukanTokuchou.yamaKudari;
  if (ud >= 50) return KukanTokuchou.updown;
  if (nobori >= 30 && nobori >= kudari) return KukanTokuchou.nobori;
  if (kudari >= 30) return KukanTokuchou.kudari;
  return KukanTokuchou.heitan;
}

/// 区間の呼び方(「山登りの5区」「アップダウンの続く4区」など。特徴がなければ「5区」)
String kukanYobikata(Ghensuu gh, int race, int k, int kukansuu) {
  final String mei = race == 3 ? '${k + 1}組' : '${k + 1}区';
  if (race == 3 || race == 4) return mei;
  switch (kukanTokuchou(gh, race, k)) {
    case KukanTokuchou.yamaNobori:
      return '山登りの$mei';
    case KukanTokuchou.yamaKudari:
      return '山下りの$mei';
    case KukanTokuchou.updown:
      return 'アップダウンの続く$mei';
    case KukanTokuchou.nobori:
      return '上り基調の$mei';
    case KukanTokuchou.kudari:
      return '下り基調の$mei';
    case KukanTokuchou.heitan:
      if (k == kukansuu - 1 && kukansuu >= 3) return 'アンカーの$mei';
      return mei;
  }
}

/// 区間の距離に合った持ちタイムの種目(7.5km以下は5000m、15km以下は1万m、それより長いとハーフ。1.9.2)
int kukanKihonShumoku(Ghensuu gh, int race, int k) {
  final double kyori = gh.kyori_taikai_kukangoto[race][k];
  return kyori <= 7500 ? 0 : (kyori <= 15000 ? 1 : 2);
}

/// 区間で見る持ちタイムの種目(time_bestkiroku の番号。最初が一番大事な種目)
/// 距離で決める基本(7.5km以下は5000m、15km以下は1万m、それより長いとハーフ)に、
/// 山登り・山下り・アップダウンの区間は登り1万・下り1万・クロカン1万を先に足す
List<int> kukanShumoku(Ghensuu gh, int race, int k) {
  final double kyori = gh.kyori_taikai_kukangoto[race][k];
  final int kihon = kukanKihonShumoku(gh, race, k);
  if (race == 3 || race == 4) return [kihon];
  switch (kukanTokuchou(gh, race, k)) {
    case KukanTokuchou.yamaNobori:
      return [4, kihon];
    case KukanTokuchou.yamaKudari:
      return [5, kihon];
    case KukanTokuchou.updown:
      return [7, kihon];
    case KukanTokuchou.nobori:
    case KukanTokuchou.kudari:
    case KukanTokuchou.heitan:
      // 1区のあとの長い平坦な区間は、単独走になりやすいのでロード1万も添える
      if (k >= 1 && kyori > 15000) return [kihon, 6];
      return [kihon];
  }
}

// ------------------------------------------------------------
// 記事を書く道具(名前の出し方と、言い回しの重なりを管理する)
// ------------------------------------------------------------

class KijiKakite {
  final KijiKankyou k;
  final KijiRand r;
  final List<KijiBlock> honbun = [];

  // 一度名前を出した人(選手idや「学連選抜の○○」など)
  final Set<String> _deta = {};

  // 名字ごとに、その名字で呼んだ人(同じ名字の別の人がいたら、名字だけで呼ばない)
  final Map<String, String> _myoujiNoHito = {};

  // 使った言い回し(同じ記事で重ねない)
  final Set<String> _tsukatta = {};

  // 直前の2つの段落の文末の種類(文のリズム。1.9.4)
  final List<int> _bunmatsu = [];

  KijiKakite(this.k, int tane) : r = KijiRand(tane);

  /// 文末の種類(0: 「〜た。」、1: 「〜だ。」「〜る。」など、2: 体言止めなど)
  static int bunmatsuShurui(String bun) {
    String t = bun.trim();
    while (t.endsWith('。') || t.endsWith('」')) {
      t = t.substring(0, t.length - 1);
    }
    final int i = t.lastIndexOf('。');
    if (i >= 0) t = t.substring(i + 1);
    if (t.isEmpty) return 2;
    if (t.endsWith('た')) return 0;
    if (t.endsWith('だ') || t.endsWith('る') || t.endsWith('い') || t.endsWith('う')) {
      return 1;
    }
    return 2;
  }

  void _bunmatsuOboeru(String bun) {
    _bunmatsu.add(bunmatsuShurui(bun));
    if (_bunmatsu.length > 2) _bunmatsu.removeAt(0);
  }

  /// 直前の2つの文末が同じ種類なら、その種類(違えばnull)
  int? get _tsuzuitaBunmatsu =>
      (_bunmatsu.length >= 2 && _bunmatsu[0] == _bunmatsu[1]) ? _bunmatsu[0] : null;

  /// 選手の呼び方。初めては「山田太郎(3年)」、2回目からは「山田」
  /// [daigaku] 初めて出すときに「東西大の」を前に付けるか
  String senshu(SenshuData s, {bool daigaku = false}) {
    return hito(
      'S${s.id}',
      s.name,
      '${s.gakunen}年',
      daigaku && s.univid >= 0 && s.univid < k.univ.length
          ? '${daigakuMei(k.univ[s.univid])}の'
          : '',
    );
  }

  /// その人の名前をもう出したか
  bool deta(String kagi) => _deta.contains(kagi);

  /// 人の呼び方(選手以外にも使う)。[kagi] 人を区別する文字、[atama] 初めてのときに前に付ける文
  String hito(String kagi, String name, String kakko, String atama) {
    final String my = myouji(name);
    if (_deta.contains(kagi)) {
      final String? dare = _myoujiNoHito[my];
      if (dare == null || dare == kagi) return my;
      return fullMei(name);
    }
    _deta.add(kagi);
    _myoujiNoHito.putIfAbsent(my, () => kagi);
    final String kk = kakko.isEmpty ? '' : '($kakko)';
    return '$atama${fullMei(name)}$kk';
  }

  /// 言い回しを選ぶ(同じ記事で使ったものは、ほかに候補があれば避ける。
  /// 直前の2つの段落の文末が同じ形なら、違う文末の候補があればそれを選ぶ。1.9.4)
  String erabu(List<String> kouho) {
    List<String> mada = [
      for (final String s in kouho)
        if (!_tsukatta.contains(s)) s,
    ];
    if (mada.isEmpty) mada = kouho;
    final int? tz = _tsuzuitaBunmatsu;
    if (tz != null) {
      final List<String> chigau = [
        for (final String s in mada)
          if (bunmatsuShurui(s) != tz) s,
      ];
      if (chigau.isNotEmpty) mada = chigau;
    }
    final String e = r.erabu(mada);
    _tsukatta.add(e);
    return e;
  }

  void danraku(String bun) {
    if (bun.trim().isEmpty) return;
    honbun.add(KijiBlock(KijiBlockShurui.danraku, bun));
    _bunmatsuOboeru(bun);
  }

  void comment(String bun) {
    if (bun.trim().isEmpty) return;
    honbun.add(KijiBlock(KijiBlockShurui.comment, bun));
    _bunmatsuOboeru(bun);
  }

  /// 「記者の目」の欄(記事の最後に、記者の見方を短く書く。1.9.4)
  void kishaNoMe(String bun) {
    if (bun.trim().isEmpty) return;
    koMidashi('記者の目');
    danraku(bun);
  }

  void koMidashi(String bun) {
    honbun.add(KijiBlock(KijiBlockShurui.koMidashi, bun));
  }
}

/// 出身地と趣味の一言(「福岡県出身。趣味は○○という」など。書けることがなければ空)
String shusshinShumiBun(KijiKankyou k, SenshuData s, KijiRand r, String yobi) {
  final String? ken = k.shusshin(s);
  final String? shumi = k.shumi(s);
  if (ken == null && shumi == null) return '';
  if (ken != null && shumi != null) {
    return r.erabu([
      '$ken出身の$yobiは、趣味が「$shumi」という一面も持つ。',
      '$yobiは$ken出身。オフの日は「$shumi」で気分を切り替えるという。',
      '$ken出身。趣味は「$shumi」と明かす$yobiの、もう一つの顔だ。',
    ]);
  }
  if (ken != null) {
    return r.erabu([
      '$yobiは$ken出身。',
      '$yobiは$ken出身。地元からの声援も届いているはずだ。',
    ]);
  }
  return r.erabu([
    '趣味は「$shumi」。$yobiの意外な素顔だ。',
    '$yobiはオフの日、「$shumi」で気分転換をしているという。',
  ]);
}
