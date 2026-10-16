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
import 'package:ekiden/kansuu/koukou.dart'; // 出身校と高校時代の実績(1.9.5)
import 'package:ekiden/kansuu/taikai_chouki.dart'; // 大会の長い記録(2.0.0)
import 'package:ekiden/kansuu/shushou.dart'
    show shushouIchiran, shushouShirushiMoji; // 選手名の「・主将」の印(2.0.2)

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
//  ・当日変更の事情(ToujituJijou): 外れた選手の調子(0なら体調不良、100未満なら調子が上がらない)と、
//    入った選手が温存していたエースか(コンピュータの大学の戦略的エントリーの印)、持ちタイムの比べから、
//    「体調不良で外れた穴に急きょ入った」「温存していたエースを投入した」などの事情を書く。
//    総監督(プレイヤー)の作戦の意図は書かない(調子に問題がない入れ替えは「入れ替えた」とだけ書く)
//
// 守る決まり
//  ・能力値は書かない(見抜く力の仕組みを壊さないため)。勝因・敗因は、区間順位・タイム差・
//    当日変更・1区のペースなど、結果から言えることだけにする
//  ・趣味は、趣味非表示設定(KantokuData.yobiint2[15]=1)のときは書かない
//  ・出身校と高校時代の実績(1.9.5。koukou.dart)は、表示しない設定(KantokuData.yobiint2[86]=1)のときは書かない。
//    出身地と趣味の一言(shusshinShumiBun)の後ろに付け、駅伝の因縁(senshuInnen)にも入れる
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

  /// 表(本文の途中に置く表。選手の三大駅伝の成績など。1.9.7)
  hyou,
}

/// 記事の本文の1かたまり
class KijiBlock {
  final KijiBlockShurui shurui;
  final String bun;

  /// 表(種類が hyou のときだけ。1.9.7)
  final KijiHyou? hyou;

  const KijiBlock(this.shurui, this.bun, {this.hyou});
}

/// 記事に付ける表(成績欄)
class KijiHyou {
  final String title;

  /// 列の見出し
  final List<String> retsu;

  /// 行(列の数は retsu と同じ)
  final List<List<String>> gyou;

  /// 生成AIに渡すテキストで、マスの中の改行の代わりに入れる文字(1.9.7)
  final String masuTsunagi;

  const KijiHyou(this.title, this.retsu, this.gyou, {this.masuTsunagi = '、'});
}

/// 表を、生成AIに渡すテキストに書く(マスの中の改行は masuTsunagi にして1行に並べる。1.9.7)
void _hyouMoji(StringBuffer sb, KijiHyou h) {
  sb.writeln();
  sb.writeln('【${h.title}】');
  sb.writeln(h.retsu.join(' / '));
  for (final List<String> g in h.gyou) {
    sb.writeln(g.map((x) => x.replaceAll('\n', h.masuTsunagi)).join(' / '));
  }
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
        case KijiBlockShurui.hyou:
          if (b.hyou != null) _hyouMoji(sb, b.hyou!);
          break;
      }
    }
    for (final KijiHyou h in hyou) {
      _hyouMoji(sb, h);
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
// 見出しの型を前の年と重ねないための記録(2.0.0。年に1度の記事で使う。新入生の記事・夏のTT特集)
// KantokuData.yobiint3[index] に、年度×10000 + 前の年の型×100 + 今年の型 を残す(型は1〜98。前の年がなければ99)。
// 同じ年度に何度記事を作っても同じ見出しになるように、同じ年度ではもう書き換えない
// ------------------------------------------------------------

class KijiMidashiKiroku {
  const KijiMidashiKiroku._();

  /// 残っている値(年度・前の年の型・今年の型。なければnull)
  static ({int nendo, int mae, int kon})? _yomu(KijiKankyou k, int index) {
    if (k.kantoku.yobiint3.length <= index) return null;
    final int v = k.kantoku.yobiint3[index];
    if (v <= 0) return null;
    return (nendo: v ~/ 10000, mae: (v ~/ 100) % 100, kon: v % 100);
  }

  /// 今年度[nendo]の記事を作るときの、前の年の見出しの型(分からなければnull)
  static int? maeNoKata(KijiKankyou k, int index, int nendo) {
    final ({int nendo, int mae, int kon})? m = _yomu(k, index);
    if (m == null) return null;
    if (m.nendo == nendo) return m.mae >= 1 && m.mae <= 98 ? m.mae : null;
    if (m.nendo == nendo - 1) return m.kon >= 1 && m.kon <= 98 ? m.kon : null;
    return null;
  }

  /// 今年度の見出しの型[kon]を残す(同じ年度でもう残していれば何もしない。保存は待たない)
  static void nokosu(KijiKankyou k, int index, int nendo, int? mae, int kon) {
    if (k.kantoku.yobiint3.length <= index) return;
    final ({int nendo, int mae, int kon})? m = _yomu(k, index);
    if (m != null && m.nendo == nendo) return;
    k.kantoku.yobiint3[index] = nendo * 10000 + (mae ?? 99) * 100 + kon;
    k.kantoku.save();
  }
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

  /// 駅伝予選: 昨年の予選との比べ(順位・タイム。1.9.4)
  yosenKyonen,

  /// 駅伝予選: 駅伝の本戦を走った経験がある(1.9.4)
  honsenKeiken,

  /// 高校時代の実績や経歴(全国高校駅伝の区間賞、ほかの競技の出身など。1.9.5)
  koukou,
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

/// 選手[s]の前の学年に、記録の残っていない学年があるか(1.9.7)
/// ゲームを始めた年の2〜4年生(2年目の3・4年生、3年目の4年生)や、QRコードでほかのデータから
/// 迎えた選手は、ゲームを始める前の学年の出走の記録がない。そのような選手に「初めての駅伝」
/// 「初めての予選」「○年目でやっと」と言い切ったり、駅伝を走った回数を少なく書いたりしないために使う。
/// 対校戦(5000m・1万m・ハーフ)は毎年、全大学の全員が走るので、前の学年に対校戦の順位が
/// 1つも残っていなければ、その学年の記録はないと見る(1年生は前の学年がないのでfalse)
bool kirokuKaketeiru(SenshuData s) {
  for (int g = 1; g < s.gakunen; g++) {
    bool ari = false;
    for (int race = 6; race <= 8; race++) {
      if (s.kukanjuni_race.length <= race) continue;
      if (s.kukanjuni_race[race].length < g) continue;
      final int j = s.kukanjuni_race[race][g - 1];
      if (j >= 0 && j < TEISUU.DEFAULTJUNI) {
        ari = true;
        break;
      }
    }
    if (!ari) return true;
  }
  return false;
}

/// 選手[s]が、記事にする大会より前に駅伝(本戦。予選は除く)の区間を走った回数と、
/// そのうち区間賞の回数(今の学年の、記事にする大会とそれより後の大会は除く)
/// 学連選抜(オープン参加)で走った正月駅伝は、大学のチームの出走ではないので数えない(1.9.5)
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
      if (s.kukanjuni_race.length > race &&
          s.kukanjuni_race[race].length >= g &&
          gakurenShussouJuni(race, s.kukanjuni_race[race][g - 1])) {
        continue; // 学連選抜で走った(1.9.5)
      }
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

/// 選手[s]の因縁(点の高い順)。駅伝の記事で、区間[kk]を走る(走った)とき
/// [kj] 結果の記事では区間順位(0が1位)。レース前の記事ではnull(今の走りと比べる因縁は出さない)
/// [kekka] 結果の記事(大会のあと)ならtrue。大学の順位の記録の、昨年の見方(結果なら[1]、レース前なら[0])と、
/// 文の時制(「〜だった」か「〜になる」か)が変わる
List<Innen> senshuInnen(
  KijiKankyou k,
  SenshuData s,
  int kk, {
  int? kj,
  bool kekka = true,
}) {
  final List<Innen> list = [];
  final int race = k.race;
  final String raceMei = k.raceMei;
  // 昨年のこの大会(大学が昨年出場していなければ、昨年の区間エントリーの値は意味を持たない)
  final UnivData? u = (s.univid >= 0 && s.univid < k.univ.length)
      ? k.univ[s.univid]
      : null;
  final bool kyonenShutsujou =
      u != null && shutsujouJuni(juniRace(u, race, kekka ? 1 : 0));
  final int maeE = kyonenShutsujou ? k.entryMae(s, race, 1) : -2;
  final int? maeJ = kyonenShutsujou ? k.kukanJuniMae(s, race, 1) : null;
  if (maeE <= -100) {
    list.add(
      Innen(
        InnenShurui.hazureta,
        90,
        '昨年は当日変更で区間から外れ、たすきを受けられなかった。',
        kekka
            ? '去年は当日に外れて、何もできないまま終わった。だから今年は、走るところを見せたかった'
            : '去年は当日に外れて、何もできないまま終わった。今年は、走るところを見せたい',
        '1年前は走れなかった',
      ),
    );
  } else if (maeE == -1) {
    list.add(
      Innen(
        InnenShurui.hoketsu,
        60,
        '昨年は補欠のまま、出番が回ってこなかった。',
        kekka
            ? '去年は補欠で、仲間の走りを見ているだけだった。その悔しさをずっと持っていた'
            : '去年は補欠で、仲間の走りを見ているだけだった。今年は自分が走る番です',
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
        kekka ? '去年とは違う区間で、新しい挑戦だった' : '去年とは違う区間。新しい挑戦だと思っている',
      ),
    );
  }
  // 初めての駅伝(1年生だけの大会では、全員が初めてなので出さない)
  // 前の学年の記録が欠けている選手(ゲームを始めた年の2〜4年生など)は、初めてか分からないので出さない(1.9.7)
  final ({int kaisuu, int kukanshou}) reki = ekidenShussouKaisuu(k, s);
  final bool kaketeiru = kirokuKaketeiru(s);
  if (reki.kaisuu == 0 && !k.ichinenDake && !kaketeiru) {
    list.add(
      s.gakunen == 1
          ? Innen(
              InnenShurui.debut,
              45,
              kekka ? 'これが大学駅伝のデビュー戦だった。' : 'これが大学駅伝のデビュー戦になる。',
              kekka ? '初めての駅伝で、たすきの重さが分かった' : '初めての駅伝。たすきの重さを感じながら、思い切って走りたい',
              'デビュー戦の',
            )
          : Innen(
              InnenShurui.debut,
              55,
              kekka
                  ? '${s.gakunen}年目で初めてつかんだ駅伝の舞台だった。'
                  : '${s.gakunen}年目で初めてつかんだ駅伝の舞台になる。',
              kekka
                  ? '${s.gakunen}年目でやっとこの舞台に立てた。走れない時間が長かった分、うれしかった'
                  : '${s.gakunen}年目でやっとこの舞台に立てる。走れなかった時間の分まで走りたい',
              '${s.gakunen}年目で初出走の',
            ),
    );
  }
  // 区間賞を何度も取っている(今回も区間賞のとき)
  // 前の学年の記録が欠けている選手は、回数が少なく出るので数を書かない(1.9.7)
  if (kj == 0 && reki.kukanshou >= 1) {
    list.add(
      kaketeiru
          ? const Innen(
              InnenShurui.kukanshouTsuusan,
              45,
              'これまでにも区間賞を取っており、また区間の頂点に立った。',
              '区間賞は前にも取ったけど、毎回違う苦しさがある',
            )
          : Innen(
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
          ? Innen(
              InnenShurui.saigo,
              50,
              kekka ? 'これが最後の正月駅伝だった。' : 'これが最後の正月駅伝になる。',
              kekka ? '4年間の最後に、この区間を走れて幸せだった' : '4年間の最後の区間。悔いなく走り切りたい',
              '最後の正月駅伝で',
            )
          : Innen(
              InnenShurui.saigo,
              25,
              kekka ? '4年生にとっては、これが最後の$raceMeiだった。' : '4年生にとっては、これが最後の$raceMeiだ。',
              kekka ? '最後の$raceMeiなので、悔いだけは残したくなかった' : '最後の$raceMei。悔いだけは残したくない',
            ),
    );
  }
  // 入学時の記録からの伸び(5000m。留学生は除く)
  final Innen? nobi = nyuugakuNobiInnen(k, s);
  if (nobi != null) list.add(nobi);
  // 高校時代の実績や経歴(1.9.5)
  final Innen? kou = koukouInnen(k, s, kj: kj, kekka: kekka);
  if (kou != null) list.add(kou);
  list.sort((a, b) => b.ten.compareTo(a.ten));
  return list;
}

/// 高校時代の因縁(1.9.5。koukou.dart)
/// ・全国高校駅伝で区間3位以内(またはチーム3位以内)だった1年生: 40点(上級生は20点)
/// ・高校までほかの競技をしていた選手: 30点。結果の記事で区間3位以内なら50点(見出しにも使える)
/// ・高校総体で入賞(8位以内)した1年生: 30点
/// 表示しない設定のときと、出身校がない・分からないときはnull(留学生は日本の高校の出身のときだけ)
Innen? koukouInnen(KijiKankyou k, SenshuData s, {int? kj, bool kekka = true}) {
  final KoukouJouhou? j = koukouHyoujiJouhou(s.samusataisei, s.hirou, k.kantoku);
  if (j == null) return null;
  final String kou = koukouMeiMoji(j);
  // ほかの競技の出身
  if (j.keireki == 2) {
    final String bu = koukouHokaKyougi(j);
    final bool kakuyaku = kekka && kj != null && kj <= 2;
    return Innen(
      InnenShurui.koukou,
      kakuyaku ? 50 : 30,
      '$kou時代は$buで、陸上の大会の実績はなかった。',
      kekka
          ? '高校までは$buだった。陸上でこの舞台に立てるとは、思っていなかった'
          : '高校までは$buだった。陸上でこの舞台に立てるなんて、思っていなかった',
      kakuyaku ? '元$buの' : '',
    );
  }
  final int ku = j.ekidenKukan;
  final int kjK = j.ekidenKukanJuni;
  final int tj = j.ekidenJuni;
  // 全国高校駅伝で目立った選手
  if (j.ekidenZenkoku && ku > 0 && ((kjK >= 1 && kjK <= 3) || (tj >= 1 && tj <= 3))) {
    final String jisseki = koukouJissekiBun(j);
    return Innen(
      InnenShurui.koukou,
      s.gakunen == 1 ? 40 : 20,
      '$kou時代は、$jisseki。',
      kekka
          ? '高校の駅伝とは距離も重みも違う。一から挑戦するつもりで走った'
          : '高校の駅伝とは距離も重みも違う。一から挑戦するつもりで走りたい',
      kjK == 1 ? '高校駅伝区間賞の' : '',
    );
  }
  // 高校総体で入賞した1年生
  if (s.gakunen == 1 && j.soutaiDankai == 3 && j.soutaiJuni >= 1 && j.soutaiJuni <= 8) {
    return Innen(
      InnenShurui.koukou,
      30,
      '$kou時代は、${koukouJissekiBun(j)}。',
      kekka ? 'トラックとは違うロードの難しさを、身をもって知った' : 'トラックとは違う。ロードでどこまでやれるか試したい',
    );
  }
  return null;
}

/// 出身校と高校時代の一言(1.9.5。「雷鳥館高時代は、全国高校駅伝の1区で区間賞を取った。」など)
/// 表示しない設定のときと、出身校がない・分からないときは空(留学生は日本の高校の出身のときだけ)
String koukouJidaiBun(KijiKankyou k, SenshuData s, KijiRand r, String yobi) {
  final KoukouJouhou? j = koukouHyoujiJouhou(s.samusataisei, s.hirou, k.kantoku);
  if (j == null) return '';
  final String jisseki = koukouJissekiBun(j);
  if (jisseki.isEmpty) {
    return r.erabu([
      '高校は${koukouMeiKenMoji(j)}。',
      '$yobiの母校は${koukouMeiKenMoji(j)}。',
    ]);
  }
  return r.erabu([
    '${koukouMeiMoji(j)}時代は、$jisseki。',
    '高校は${koukouMeiKenMoji(j)}。$jisseki。',
  ]);
}

/// 入学時の5000mの記録からの伸びの因縁(留学生と1年生は除く。伸びていなければnull)
Innen? nyuugakuNobiInnen(KijiKankyou k, SenshuData s) {
  if (s.hirou == 1 || s.gakunen < 2) return null;
  final double ny = s.kiroku_nyuugakuji_5000;
  final double best = k.jikoBest(s, 0);
  if (ny <= 0 || ny >= TEISUU.DEFAULTTIME || best >= TEISUU.DEFAULTTIME) return null;
  final int nyFun = byou(ny) ~/ 60;
  final int bestFun = byou(best) ~/ 60;
  if (nyFun - bestFun < 1) return null;
  return Innen(
    InnenShurui.nyuugakuNobi,
    35 + (nyFun - bestFun >= 2 ? 15 : 0),
    '入学時の5000mは$nyFun分台。今は${jikanMoji(best)}まで記録を伸ばしてきた。',
    '入学したときは5000mが$nyFun分台の選手だった。ここまで来られたのは、積み上げてきた練習のおかげ',
    '入学時$nyFun分台からの',
  );
}

/// 選手[s]が、記事にする大会より前に駅伝予選(11月駅伝予選・正月駅伝予選)を走った回数
/// (今の学年の、記事にする大会とそれより後の大会は除く)
int yosenShussouKaisuu(KijiKankyou k, SenshuData s) {
  int kaisuu = 0;
  final int imaJun = _innenRaceJun.indexOf(k.race);
  for (int g = 1; g <= s.gakunen; g++) {
    for (int ji = 0; ji < _innenRaceJun.length; ji++) {
      final int race = _innenRaceJun[ji];
      if (race != 3 && race != 4) continue;
      if (g == s.gakunen && imaJun >= 0 && ji >= imaJun) continue;
      if (s.entrykukan_race.length <= race) continue;
      if (s.entrykukan_race[race].length < g) continue;
      if (s.entrykukan_race[race][g - 1] < 0) continue;
      kaisuu++;
    }
  }
  return kaisuu;
}

/// 駅伝予選(11月駅伝予選・正月駅伝予選)の選手[s]の因縁(点の高い順。1.9.4)
/// [juni] 結果の記事では、組の中の順位(正月駅伝予選は全体の順位。0が1位)。レース前ならnull
/// [time] 結果の記事ではタイム。レース前ならnull
/// [kekka] 結果の記事ならtrue(大学の順位の記録の昨年の見方と、文の時制が変わる)
List<Innen> yosenInnen(
  KijiKankyou k,
  SenshuData s, {
  int? juni,
  double? time,
  bool kekka = true,
}) {
  final List<Innen> list = [];
  final int race = k.race;
  if (race != 3 && race != 4) return list;
  final bool kumi = race == 3;
  final String raceMei = k.raceMei;
  final UnivData? u = (s.univid >= 0 && s.univid < k.univ.length)
      ? k.univ[s.univid]
      : null;
  final bool kyonenShutsujou =
      u != null && shutsujouJuni(juniRace(u, race, kekka ? 1 : 0));
  // 昨年の予選(順位とタイム)
  final int maeE = kyonenShutsujou ? k.entryMae(s, race, 1) : -2;
  final int? maeJ = kyonenShutsujou ? k.kukanJuniMae(s, race, 1) : null;
  double? maeT;
  final int g = s.gakunen - 2;
  if (kyonenShutsujou && g >= 0 && s.kukantime_race.length > race && s.kukantime_race[race].length > g) {
    final double t = s.kukantime_race[race][g];
    if (t > 0 && t < TEISUU.DEFAULTTIME) maeT = t;
  }
  if (maeE >= 0 && maeJ != null) {
    final String maeMoji = kumi ? '組${maeJ + 1}位' : '全体${maeJ + 1}位';
    if (juni != null && maeJ - juni >= 5) {
      list.add(
        Innen(
          InnenShurui.yosenKyonen,
          70,
          '昨年の予選は$maeMoji。今年は${kumi ? '組' : '全体'}${juni + 1}位まで順位を上げた。',
          '去年の予選は$maeMojiで終わっていた。今年は絶対に上げたかった',
          '昨年$maeMojiからの',
        ),
      );
    } else if (juni != null && time != null && maeT != null && saByou(maeT, time) >= 10) {
      list.add(
        Innen(
          InnenShurui.yosenKyonen,
          60,
          '昨年の予選より${saMoji(saByou(maeT, time))}速いタイムで走った。',
          '去年の予選より${saMoji(saByou(maeT, time))}速く走れた。1年間の積み上げを感じる',
        ),
      );
    } else if (juni != null && juni - maeJ >= 5) {
      list.add(
        Innen(
          InnenShurui.yosenKyonen,
          35,
          '昨年の予選は$maeMojiだったが、今年はその走りに届かなかった。',
          '去年の自分を超えられなかった。それが一番悔しい',
        ),
      );
    } else {
      list.add(
        Innen(
          InnenShurui.yosenKyonen,
          30,
          '昨年の予選も走り、$maeMojiだった。',
          kekka ? '去年の予選も走った。あの緊張感を知っていたのは大きかった' : '去年の予選も走った。あの緊張感は分かっている',
        ),
      );
    }
  }
  // 駅伝の本戦の出走歴
  // 前の学年の記録が欠けている選手(ゲームを始めた年の2〜4年生など)は、回数が少なく出るので数を書かない(1.9.7)
  final bool kaketeiru = kirokuKaketeiru(s);
  final ({int kaisuu, int kukanshou}) reki = ekidenShussouKaisuu(k, s);
  if (reki.kaisuu >= 1) {
    list.add(
      Innen(
        InnenShurui.honsenKeiken,
        40 + (reki.kukanshou >= 1 ? 10 : 0),
        kaketeiru
            ? '駅伝の本戦も走っている${reki.kukanshou >= 1 ? '(区間賞も獲得)' : ''}。'
            : '駅伝の本戦は${reki.kaisuu}度走っている${reki.kukanshou >= 1 ? '(区間賞${reki.kukanshou}度)' : ''}。',
        kekka ? '本戦の舞台を知っている分、予選で終わるわけにはいかなかった' : '本戦の舞台を知っている分、予選で終わるわけにはいかない',
      ),
    );
  }
  // 初めての予選
  // 前の学年の記録が欠けている選手は、初めてか分からないので出さない。2年生以上は、前の年にチームが
  // 予選に出ていなかった(シード校だった)だけのこともあるので、選ばれなかったことを前提にしない言い方にする(1.9.7)
  if (yosenShussouKaisuu(k, s) == 0 && !kaketeiru) {
    list.add(
      s.gakunen == 1
          ? Innen(
              InnenShurui.debut,
              40,
              kekka ? 'これが初めての駅伝予選だった。' : 'これが初めての駅伝予選になる。',
              kekka ? '初めての予選。集団の大きさに驚いたけど、落ち着いて走れた' : '初めての予選。集団の中で落ち着いて走りたい',
              '初めての予選で',
            )
          : Innen(
              InnenShurui.debut,
              50,
              kekka ? '${s.gakunen}年目で初めて走った駅伝予選だった。' : '${s.gakunen}年目で初めて走る駅伝予選になる。',
              kekka ? '初めての予選だったけど、本戦への切符のことだけを考えて走った' : '初めての予選。本戦への切符を、自分の走りでつかみたい',
              '${s.gakunen}年目で初めての予選で',
            ),
    );
  }
  // 4年生の最後の予選
  if (s.gakunen == 4) {
    list.add(
      race == 4
          ? Innen(
              InnenShurui.saigo,
              45,
              kekka ? 'これが最後の駅伝予選だった。' : 'これが最後の駅伝予選になる。',
              kekka ? '最後の予選。チームを本戦に連れていくことだけを考えて走った' : '最後の予選。チームを本戦に連れていくことだけを考えて走る',
              '最後の予選で',
            )
          : Innen(
              InnenShurui.saigo,
              20,
              kekka ? '4年生にとっては、これが最後の$raceMeiだった。' : '4年生にとっては、これが最後の$raceMeiだ。',
              kekka ? '最後の$raceMeiなので、悔いだけは残したくなかった' : '最後の$raceMei。悔いだけは残したくない',
            ),
    );
  }
  final Innen? nobi = nyuugakuNobiInnen(k, s);
  if (nobi != null) list.add(nobi);
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

  /// 大学ごとの主将の選手id(大学id → 選手id。記事を作るときの主将。2.0.2。shushou.dart)
  /// (初めて使うときに一度だけ求める)
  late final Map<int, int> shushouId = shushouIchiran(kantoku, gh, senshu);

  /// 選手[s]が今の主将か(2.0.2)
  bool shushou(SenshuData s) => shushouId[s.univid] == s.id;

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
  /// 学連選抜(オープン参加)で走った年は、大学のチームでは走っていないので-2(1.9.5)
  int entryMae(SenshuData s, int r, int maeNen) {
    if (s.entrykukan_race.length <= r) return -2;
    final int g = s.gakunen - 1 - maeNen;
    if (g < 0 || g >= s.entrykukan_race[r].length) return -2;
    if (gakurenMae(s, r, maeNen)) return -2;
    return s.entrykukan_race[r][g];
  }

  /// 選手[s]の、大会[r]の、[maeNen]年前の学年での区間順位(なければnull。0が1位)
  /// 学連選抜(オープン参加)で走った年は、区間順位相当なので比べずにnull(1.9.5)
  int? kukanJuniMae(SenshuData s, int r, int maeNen) {
    if (s.kukanjuni_race.length <= r) return null;
    final int g = s.gakunen - 1 - maeNen;
    if (g < 0 || g >= s.kukanjuni_race[r].length) return null;
    final int j = s.kukanjuni_race[r][g];
    if (j < 0 || j >= TEISUU.DEFAULTJUNI) return null;
    if (gakurenShussouJuni(r, j)) return null;
    return j;
  }

  /// 選手[s]の、大会[r]の、[maeNen]年前の学年での出走が、学連選抜(オープン参加)だったか(1.9.5)
  bool gakurenMae(SenshuData s, int r, int maeNen) {
    if (s.kukanjuni_race.length <= r) return false;
    final int g = s.gakunen - 1 - maeNen;
    if (g < 0 || g >= s.kukanjuni_race[r].length) return false;
    return gakurenShussouJuni(r, s.kukanjuni_race[r][g]);
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
/// [hisabisa] 前回の年が分からないが、記録より前にあった(今までのセーブデータ。2.0.0。「久々となる5度目の」)
String renzokuMoji({
  required int renzoku,
  required int? buri,
  required int kaisuu,
  bool hisabisa = false,
}) {
  if (kaisuu <= 1) return '';
  if (renzoku >= 2) return '$renzoku年連続$kaisuu度目の';
  if (buri != null && buri >= 2) return '$buri年ぶり$kaisuu度目の';
  if (buri == null && hisabisa) return '久々となる$kaisuu度目の';
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

// ------------------------------------------------------------
// 大会の長い記録(2.0.0。taikai_chouki.dart)
// 順位の記録は直近 TEISUU.KIROKUHOZONNENSUU 回分しか残らないので、「○年ぶり」と連続の回数は、
// 出来事(優勝 choukiYuushou・本戦出場 choukiShutsujou・シード権 choukiSeed)ごとに覚えている
// 最後の年度と連続の回数で数える。覚えていない大会や、記録と合わないときは、今までどおり直近の記録で数える
// ------------------------------------------------------------

/// [hajime]回前(0か1)より前で、最後に出来事[dekigoto]があったのは何年前か(saigoNoKai の代わり)
/// 順位の記録の[0]の大会の年度からの差で数える(毎年開かれる大会では saigoNoKai と同じ数になる。
/// 開かれない年のあるカスタム駅伝でも年で数える)。なければ nen は null。
/// 記録を始める前(今までのセーブデータで直近の記録より前)にあって年が分からないときは、hisabisa を true にする
({int? nen, bool hisabisa}) saigoNoNen(
  UnivData u,
  int race,
  int hajime,
  int dekigoto,
) {
  bool jouken(int j) => choukiAtta(race, dekigoto, j);
  final int? kai = saigoNoKai(u, race, hajime, jouken);
  final ChoukiKiroku? c = choukiYomu(u, race, dekigoto);
  final int g = choukiKaisaiNendo(u, race);
  if (c == null || g <= 0 || hajime < 0 || hajime > 1) {
    return (nen: kai, hisabisa: false);
  }
  // 今回([0])にあったか。あったなら、覚えている最後の年度は[0]の年度のはず(合わなければ直近の記録で数える)
  final bool ima = jouken(juniRace(u, race, 0));
  if (ima && c.saigo != g) return (nen: kai, hisabisa: false);
  final int nendo = (hajime == 1 && ima) ? c.mae : c.saigo;
  if (nendo > 0 && nendo <= g) return (nen: g - nendo, hisabisa: false);
  if (kai != null) return (nen: kai, hisabisa: false);
  // 全期間の回数から、[hajime]回前より前にもあったか(年は分からない)
  final int maeNoKaisuu =
      choukiTsuusan(u, race, dekigoto) - ((hajime == 1 && ima) ? 1 : 0);
  return (nen: null, hisabisa: maeNoKaisuu > 0);
}

/// [hajime]回前(0か1)から続けて出来事[dekigoto]があった回数と、その数を言い切れるか
/// (renzokuKakutei の代わり。直近の記録で言い切れないときは、覚えている連続の回数で数える)
/// [tsuusan] 全期間で出来事があった回数([hajime]回前までの分。renzokuKakutei と同じ)
({int kaisuu, bool kakutei}) renzokuChouki(
  UnivData u,
  int race,
  int hajime,
  int dekigoto,
  int tsuusan,
) {
  bool jouken(int j) => choukiAtta(race, dekigoto, j);
  final ({int kaisuu, bool kakutei}) r = renzokuKakutei(
    u,
    race,
    hajime,
    jouken,
    tsuusan,
  );
  if (r.kakutei || hajime < 0 || hajime > 1) return r;
  final ChoukiKiroku? c = choukiYomu(u, race, dekigoto);
  if (c == null || c.renzoku <= 0) return r;
  // 今回([0])にあったなら、覚えている連続の回数は[0]の大会で終わる分(合わなければ直近の記録の数のまま)
  final bool ima = jouken(juniRace(u, race, 0));
  if (ima && c.saigo != choukiKaisaiNendo(u, race)) return r;
  final int n = (hajime == 1 && ima) ? c.renzoku - 1 : c.renzoku;
  if (n < r.kaisuu) return r;
  return (kaisuu: n, kakutei: true);
}

/// 選手の区間順位[juni]が、正月駅伝を学連選抜(オープン参加)で走ったときのものか(1.9.5)
/// 学連選抜で走った区間・区間順位・タイムは、正月駅伝のあとで元の選手のデータに書き戻され、
/// 区間順位には区間順位相当に100を足した値が入る(RaceCalc_gakuren.dart・KirokuKousin.dart。
/// 生成AI向けの履歴(rireki_text.dart)と同じ見分け方)。
/// 記事では、大学のチームの出走とは分けて数え(回数・駅伝デビュー・区間賞・年間表彰の点に入れない)、
/// 書くときは「学連選抜に選ばれて○区を走った(区間○位相当)」のように別に書く
bool gakurenShussouJuni(int race, int juni) =>
    race == 2 && juni >= 100 && juni < TEISUU.DEFAULTJUNI;

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

/// 三大駅伝の表(今季と過去の季。1.9.7から3位まで)に出す季の数(今季を含む。1.9.4)
const int sandaiKonkiKisuu = 5;

/// 三大駅伝の表(今季と過去の季)に出す順位の数(1.9.7)
const int sandaiKonkiJuniSuu = 3;

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

  /// [kiMae]季前(0が今の季)の大会[race]で、順位[juni](0が1位)だった大学
  /// (まだ行われていない・記録がなければnull。1.9.7)
  UnivData? juniNoUniv(int race, int kiMae, int juni) {
    final int idx = owatta(race) ? kiMae : kiMae - 1;
    if (idx < 0 || idx >= TEISUU.KIROKUHOZONNENSUU) return null;
    for (final UnivData u in k.univ) {
      if (juniRace(u, race, idx) == juni) return u;
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

  /// 三大駅伝の表(今季と過去の季。1.9.4で、今季だけの表から過去の季も並べる表にした)
  /// 1.9.7から、テレビの表のように、各大会の欄に1位から3位までを縦に並べる(1つのマスに3行)
  /// ・1行目は今季。まだ行われていない大会は「これから」
  /// ・2行目から過去の季を、新しい順に[kisuu]季分(今季を含む)まで。記録のない季は出さない
  /// ・年度の欄の2行目に「今季」と「三冠」を書く(大会の欄に付けるより幅が狭く、スマホの縦画面に収まりやすい)
  /// 優勝の記事・展望の記事・年間表彰で使う
  KijiHyou konkiHyou({int kisuu = sandaiKonkiKisuu}) {
    final List<List<String>> gyou = [];
    for (int i = 0; i < kisuu; i++) {
      if (nendo(i) < 1) break;
      final List<UnivData?> y = [
        for (final int race in sandaiEkidenRace) yuushou(race, i),
      ];
      if (i > 0 && y.every((u) => u == null)) continue;
      final bool sk = y.every((u) => u != null && u.id == y[0]!.id);
      final String soe = [if (i == 0) '今季', if (sk) '三冠'].join('・');
      gyou.add([
        soe.isEmpty ? '${nendo(i)}年度' : '${nendo(i)}年度\n$soe',
        for (final int race in sandaiEkidenRace)
          (i == 0 && !owatta(race)) ? 'これから' : _sandaiJuniMasu(race, i),
      ]);
    }
    return KijiHyou('三大駅伝の上位3校(今季と過去の季)', [
      '年度',
      for (final int race in sandaiEkidenRace) courseRaceTitle(race),
    ], gyou);
  }

  /// 三大駅伝の表の、大会[race]の[kiMae]季前のマス(「1 東西大」から3位までを改行で並べる。記録がなければ「-」)
  String _sandaiJuniMasu(int race, int kiMae) {
    final List<String> l = [];
    for (int j = 0; j < sandaiKonkiJuniSuu; j++) {
      final UnivData? u = juniNoUniv(race, kiMae, j);
      if (u != null) l.add('${j + 1} ${daigakuMei(u)}');
    }
    return l.isEmpty ? '-' : l.join('\n');
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
// 選手の三大駅伝の成績の表(1.9.7)
// テレビの表のように、10月駅伝・11月駅伝・正月駅伝を横に並べ、学年を上から新しい順に並べる。
// マスは2行(「3区」「区間2位」。区間賞は「区間賞」)。本戦を走っていない年は、予選を走っていれば
// 予選の結果(11月駅伝の欄は11月駅伝予選の組と組の順位、正月駅伝の欄は正月駅伝予選の個人順位)、
// 補欠は「補欠」、当日変更で外れた選手は「当日変更」「3区OUT」(1.9.8)、
// 学連選抜で走った正月駅伝は「学連 7区」「区間5位相当」。
// その学年の記録が残っていない(ゲームを始めた年の2〜4年生など)ときは「記録なし」。
// レース前の記事では、記事にしている大会を「今回」、今の学年でそれより後の大会を「これから」にする。
// 卒業生特集・年間最優秀選手と、選手名鑑(学内メディアの三大駅伝の展望号・学連選抜通信・駅伝予選)で使う。
// 選手名鑑では、走った・予選・学連選抜・補欠のどれも載らない選手は表を省く(shouryaku)
// ------------------------------------------------------------

/// 大会の、季の中での順(11月駅伝予選・10月駅伝・正月駅伝予選・11月駅伝・正月駅伝)
const List<int> _kiNoJun = [3, 0, 4, 1, 2];

/// 対校戦の大会の番号(5000m・1万m・ハーフ)
const List<int> _taikousenRace = [6, 7, 8];

/// 成績の表を作るのに使う、選手のレースの記録(現役の選手・卒業生のどちらからでも作れるように。1.9.8)
class SeisekiKiroku {
  final String name;
  final int gakunen;

  /// [大会][学年(0が1年)]の区間エントリー・区間順位・タイム
  final List<List<int>> entry;
  final List<List<int>> juni;
  final List<List<double>> time;

  const SeisekiKiroku(this.name, this.gakunen, this.entry, this.juni, this.time);

  factory SeisekiKiroku.senshu(SenshuData s) =>
      SeisekiKiroku(s.name, s.gakunen, s.entrykukan_race, s.kukanjuni_race, s.kukantime_race);
}

/// 選手[s]の[g]年の、大会[race]の区間(記録がなければ-2)
int _entryAt(SeisekiKiroku s, int race, int g) {
  if (g < 1 || s.entry.length <= race || s.entry[race].length < g) return -2;
  return s.entry[race][g - 1];
}

/// 選手[s]の[g]年の、大会[race]の区間順位(記録がなければ TEISUU.DEFAULTJUNI)
int _juniAt(SeisekiKiroku s, int race, int g) {
  if (g < 1 || s.juni.length <= race || s.juni[race].length < g) {
    return TEISUU.DEFAULTJUNI;
  }
  return s.juni[race][g - 1];
}

/// 選手[s]の[g]年の、大会[race]のタイム(記録がなければ TEISUU.DEFAULTTIME。1.9.8)
double _timeAt(SeisekiKiroku s, int race, int g) {
  if (g < 1 || s.time.length <= race || s.time[race].length < g) return TEISUU.DEFAULTTIME;
  final double t = s.time[race][g - 1];
  return t > 0 ? t : TEISUU.DEFAULTTIME;
}

/// 選手[s]の[g]年の記録が残っていないか(対校戦の順位で見る。kirokuKaketeiru と同じ見方)
bool _gakunenKirokuNashi(SeisekiKiroku s, int g) {
  for (final int race in _taikousenRace) {
    if (shutsujouJuni(_juniAt(s, race, g))) return false;
  }
  return true;
}

/// マスの最後に足す、走破タイムの行(1.9.9。[taimuAri]がfalseか、タイムがなければ空。
/// 対校戦の表と同じく分と秒で書く(1時間を超えても「65分30秒」))
String _taimuGyou(SeisekiKiroku s, int race, int g, bool taimuAri) {
  if (!taimuAri) return '';
  final double t = _timeAt(s, race, g);
  return t < TEISUU.DEFAULTTIME ? '\n${TimeDate.timeToFunByouString(t)}' : '';
}

/// 三大駅伝の成績の表の、大会[race]の[g]年のマス(載せることがなければnull)
/// [taimuAri]がtrueなら、区間順位の下に走破タイムも書く(1.9.9。選手画面・卒業生の画面)
String? _sandaiSeisekiMasu(
  SeisekiKiroku s,
  int race,
  int g, {
  bool taimuAri = false,
}) {
  final int e = _entryAt(s, race, g);
  final int j = _juniAt(s, race, g);
  if (e >= 0) {
    final String taimu = _taimuGyou(s, race, g, taimuAri);
    if (gakurenShussouJuni(race, j)) return '学連 ${e + 1}区\n区間${j - 100 + 1}位相当$taimu';
    if (shutsujouJuni(j)) {
      return j == 0 ? '${e + 1}区\n区間賞$taimu' : '${e + 1}区\n区間${j + 1}位$taimu';
    }
    return '${e + 1}区';
  }
  // 本戦を走っていなければ、予選の結果
  final String? y = _yosenMasu(s, race, g, taimuAri: taimuAri);
  if (y != null) return y;
  // 当日変更で外れた選手(-(100+区間)。1.9.8から補欠と分け、どの区間から外れたかを書く。
  // 区間の補正の説明の「当日変更OUT」と同じ書き方にして、短く収める)
  if (e <= -100) return '当日変更\n${-e - 100 + 1}区OUT';
  // 補欠(-1)
  if (e == -1) return '補欠';
  return null;
}

/// 三大駅伝の成績の表の、本戦の欄に出す予選の結果(11月駅伝は11月駅伝予選、正月駅伝は正月駅伝予選。
/// 予選を走っていなければnull)
/// [taimuAri]がtrueなら、順位の下に走破タイムも書く(1.9.9。11月駅伝予選は1万m、正月駅伝予選はハーフ)
String? _yosenMasu(SeisekiKiroku s, int race, int g, {bool taimuAri = false}) {
  final int yosen = race == 1 ? 3 : (race == 2 ? 4 : -1);
  if (yosen < 0) return null;
  final int ye = _entryAt(s, yosen, g);
  if (ye < 0) return null;
  final int yj = _juniAt(s, yosen, g);
  final bool ari = shutsujouJuni(yj);
  final String taimu = ari ? _taimuGyou(s, yosen, g, taimuAri) : '';
  return yosen == 3
      ? '予選 ${ye + 1}組${ari ? '\n組${yj + 1}位' : ''}$taimu'
      : '予選会${ari ? '\n個人${yj + 1}位' : ''}$taimu';
}

/// 選手[s]の三大駅伝の成績の表(学年は今の学年から1年まで、上から新しい順)
/// [imaRace] レース前の記事なら、記事にしている大会(その大会は「今回」、今の学年でそれより後の
/// 大会は「これから」。駅伝予選の記事なら、その予選の本戦の欄を「今回」にする)。
/// 季が終わったあとの記事(卒業生特集・年間表彰)ならnull
/// [shouryaku] 走った・予選・学連選抜・補欠のどれも載らないときにnullを返すか(選手名鑑)
KijiHyou? sandaiSeisekiHyou(SenshuData s, {int? imaRace, bool shouryaku = false}) =>
    sandaiSeisekiHyouKiroku(SeisekiKiroku.senshu(s), imaRace: imaRace, shouryaku: shouryaku);

/// 三大駅伝の成績の表(sandaiSeisekiHyou の中身。卒業生の画面からも使えるように記録で受け取る。1.9.8)
/// [kaisai] 季の途中で見る選手画面なら、今季もう開かれた大会(konkiKaisaiZumi)。今の学年でまだ開かれて
/// いない大会は「これから」にする(予選だけ終わっていれば予選の結果)。記事ではnull
/// [taimuAri] 区間順位(予選の順位)の下に走破タイムも書くか(1.9.9。選手画面・他大学の選手の詳細・
/// 卒業生の画面はtrue。記事は、表が縦に長くなり生成AI向けのテキストも長くなるのでfalseのまま)
KijiHyou? sandaiSeisekiHyouKiroku(
  SeisekiKiroku s, {
  int? imaRace,
  bool shouryaku = false,
  Set<int>? kaisai,
  bool taimuAri = false,
}) {
  if (s.gakunen < 1 || s.gakunen > 4) return null;
  final int imaJun = imaRace == null ? -1 : _kiNoJun.indexOf(imaRace);
  final List<List<String>> gyou = [];
  bool nanika = false;
  for (int g = s.gakunen; g >= 1; g--) {
    final bool nashi = g < s.gakunen && _gakunenKirokuNashi(s, g);
    final bool ima = g == s.gakunen && imaJun >= 0;
    final List<String> masu = [];
    for (final int race in sandaiEkidenRace) {
      String m;
      if (nashi) {
        m = '記録なし';
      } else if (ima && race == imaRace) {
        m = '今回';
      } else if (ima && imaRace == 3 && race == 1) {
        m = '予選\n今回';
      } else if (ima && imaRace == 4 && race == 2) {
        m = '予選会\n今回';
      } else if (ima && _kiNoJun.indexOf(race) > imaJun) {
        m = 'これから';
      } else if (kaisai != null && g == s.gakunen && !kaisai.contains(race)) {
        // 季の途中で、今の学年でまだ開かれていない大会(エントリーは選手を作ったときの補欠の値のままなので、
        // そのまま出すと「補欠」になる。1.9.8)
        final String? y = _yosenMasu(s, race, g, taimuAri: taimuAri);
        if (y != null) nanika = true;
        m = y ?? 'これから';
      } else {
        final String? d = _sandaiSeisekiMasu(s, race, g, taimuAri: taimuAri);
        if (d != null) nanika = true;
        m = d ?? '-';
      }
      masu.add(m);
    }
    gyou.add(['$g年', ...masu]);
  }
  if (shouryaku && !nanika) return null;
  return KijiHyou(
    '${fullMei(s.name)}の三大駅伝',
    ['学年', for (final int race in sandaiEkidenRace) courseRaceTitle(race)],
    gyou,
    masuTsunagi: ' ',
  );
}

// ------------------------------------------------------------
// 選手の対校戦の成績の表(1.9.8。選手画面で使う)
// 三大駅伝の表と同じく、5000m・1万m・ハーフを横に並べ、学年を上から新しい順に並べる。
// マスは2行(「3位」「14分10秒」。1位は「優勝」。ハーフも「62分10秒」と分で書く)。走っていなければ「-」、
// その学年の記録が残っていなければ
// 「記録なし」、季の途中でまだ開かれていなければ「これから」
// ------------------------------------------------------------

/// 選手[s]の対校戦の成績の表([kaisai] は三大駅伝の表と同じ)
KijiHyou? taikousenSeisekiHyou(SeisekiKiroku s, {Set<int>? kaisai}) {
  if (s.gakunen < 1 || s.gakunen > 4) return null;
  final List<List<String>> gyou = [];
  for (int g = s.gakunen; g >= 1; g--) {
    final bool nashi = g < s.gakunen && _gakunenKirokuNashi(s, g);
    final List<String> masu = [];
    for (final int race in _taikousenRace) {
      String m;
      if (nashi) {
        m = '記録なし';
      } else if (kaisai != null && g == s.gakunen && !kaisai.contains(race)) {
        m = 'これから';
      } else {
        final int j = _juniAt(s, race, g);
        if (shutsujouJuni(j)) {
          final double t = _timeAt(s, race, g);
          // タイムは分と秒で書く(ハーフも「62分10秒」。幅を節約し、選手画面の学年ごとの一覧とそろえる)
          m = '${j == 0 ? '優勝' : '${j + 1}位'}${t < TEISUU.DEFAULTTIME ? '\n${TimeDate.timeToFunByouString(t)}' : ''}';
        } else {
          m = '-';
        }
      }
      masu.add(m);
    }
    gyou.add(['$g年', ...masu]);
  }
  return KijiHyou(
    '${fullMei(s.name)}の対校戦',
    ['学年', for (final int race in _taikousenRace) kijiShumokuMei[race - 6]],
    gyou,
    masuTsunagi: ' ',
  );
}

/// 今季(それぞれの選手の今の学年)にもう開かれた大会(三大駅伝・駅伝予選・対校戦)
/// 誰か1人でも今の学年の順位を持っていれば開かれたと見る(選手画面の成績の表で使う。1.9.8)
Set<int> konkiKaisaiZumi(Iterable<SenshuData> senshu) {
  const List<int> races = [0, 1, 2, 3, 4, 6, 7, 8];
  final Set<int> kaisai = {};
  for (final SenshuData s in senshu) {
    if (s.gakunen < 1 || s.gakunen > 4) continue;
    final SeisekiKiroku k = SeisekiKiroku.senshu(s);
    for (final int race in races) {
      if (!kaisai.contains(race) && shutsujouJuni(_juniAt(k, race, s.gakunen))) kaisai.add(race);
    }
    if (kaisai.length == races.length) break;
  }
  return kaisai;
}

// ------------------------------------------------------------
// 大学の三大駅伝の成績の表(1.9.8。大学画面で使う)
// 年度を上から新しい順に(今季と過去5季)、10月駅伝・11月駅伝・正月駅伝を横に並べる。
// マスは本戦の順位(「優勝」「3位」)。本戦に出ていない季は予選の順位(「予選12位」。11月駅伝の欄は
// 11月駅伝予選、正月駅伝の欄は正月駅伝予選)。どちらもなければ「-」、今季まだなら「これから」。
// 年度の欄の2行目に「今季」と「三冠」を書く(記事の三大駅伝の表と同じ)。
// 大学の順位は大会ごとに「何回前か」で持っているので、今季の大会がもう開かれたか(konkiKaisaiZumi)で
// 季にそろえる。ゲームを始める前の季(どの大学にも順位がない季)は出さない
// 2.0.0から、一番右に正月駅伝の往路・復路の列も足した(大会番号18・19。oufuku_kiroku.dart)。
// 往路・復路は正月駅伝と一緒に記録するので、季のそろえ方は正月駅伝と同じ。予選はないので、
// 正月駅伝に出ていない季は「-」。2.0.0より前から遊んでいるデータで、記録を始める前の季は空欄にする
// (「-」と見分けるため)。三冠は今までどおり三大駅伝の3つで見る
// ------------------------------------------------------------

/// 大学の三大駅伝の表に出す季の数(今季を含む。今季と過去5季)
const int univSandaiKisuu = 6;

/// 大学[u]の三大駅伝の成績の表([univs] 全大学、[kaisai] 今季もう開かれた大会、[year]・[month] 今の年月)
KijiHyou univSandaiHyou(
  UnivData u,
  List<UnivData> univs,
  Set<int> kaisai,
  int year,
  int month, {
  int kisuu = univSandaiKisuu,
}) {
  // [kiMae]季前(0が今季)の大会[race]の、順位の記録の番号(まだ開かれていない今季はマイナス)
  int idx(int race, int kiMae) => kaisai.contains(race) ? kiMae : kiMae - 1;
  // その季に大会[race]の順位を持つ大学があるか(ゲームを始める前の季は、どの大学にもない)
  bool kiroku(int race, int kiMae) {
    final int i = idx(race, kiMae);
    if (i < 0) return false;
    for (final UnivData x in univs) {
      if (shutsujouJuni(juniRace(x, race, i))) return true;
    }
    return false;
  }

  final int nendo0 = month <= 3 ? year - 1 : year;
  final List<List<String>> gyou = [];
  for (int kiMae = 0; kiMae < kisuu; kiMae++) {
    if (kiMae > 0 && !const [0, 1, 2, 3, 4].any((r) => kiroku(r, kiMae))) continue;
    final List<String> masu = [];
    int yuushou = 0;
    for (final int race in sandaiEkidenRace) {
      final int yosen = race == 1 ? 3 : (race == 2 ? 4 : -1);
      final int i = idx(race, kiMae);
      final int j = i < 0 ? TEISUU.DEFAULTJUNI : juniRace(u, race, i);
      String m;
      if (shutsujouJuni(j)) {
        if (j == 0) yuushou++;
        m = j == 0 ? '優勝' : '${j + 1}位';
      } else {
        final int yi = yosen < 0 ? -1 : idx(yosen, kiMae);
        final int yj = yi < 0 ? TEISUU.DEFAULTJUNI : juniRace(u, yosen, yi);
        if (shutsujouJuni(yj)) {
          m = '予選${yj + 1}位';
        } else {
          m = i < 0 ? 'これから' : '-';
        }
      }
      masu.add(m);
    }
    final String soe = [if (kiMae == 0) '今季', if (yuushou == sandaiEkidenRace.length) '三冠'].join('・');
    final int nendo = nendo0 - kiMae;
    // 正月駅伝の往路・復路(2.0.0)
    final int oi = idx(2, kiMae);
    final int kaishi = choukiOufukuKaishi(u);
    for (final int race in const [ouroRace, fukuroRace]) {
      if (oi < 0) {
        masu.add('これから');
      } else if (kaishi > 1 && nendo < kaishi) {
        masu.add('');
      } else {
        final int j = juniRace(u, race, oi);
        masu.add(shutsujouJuni(j) ? (j == 0 ? '優勝' : '${j + 1}位') : '-');
      }
    }
    gyou.add([soe.isEmpty ? '$nendo年度' : '$nendo年度\n$soe', ...masu]);
  }
  return KijiHyou(
    '${daigakuMei(u)}の三大駅伝(今季と過去の季)',
    [
      '年度',
      for (final int race in sandaiEkidenRace) courseRaceTitle(race),
      '往路',
      '復路',
    ],
    gyou,
    masuTsunagi: ' ',
  );
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

/// 区間[kk]の持ちタイムを比べる種目(time_bestkiroku の番号。展望記事の「各区間」と実況の次の区間で使う。1.9.5)
/// 区間で見る種目(kukanShumoku)の順に、1万m・5000mを後ろに足した候補から、
/// その区間を走る選手[hashiru]の半分以上が記録を持っている最初の種目にする(どれもなければ最後の候補)
/// (1.9.2から展望記事の中にあった選び方を、実況でも使えるようにここへ移した)
int kukanHikakuShumoku(KijiKankyou k, int kk, List<SenshuData> hashiru) {
  final List<int> kouho = List<int>.of(kukanShumoku(k.gh, k.race, kk));
  for (final int c in const [1, 0]) {
    if (!kouho.contains(c)) kouho.add(c);
  }
  // 走る選手の半分以上が記録を持っている種目で比べる
  int idx = kouho.last;
  for (final int c in kouho) {
    int ari = 0;
    for (final SenshuData s in hashiru) {
      if (k.jikoBest(s, c) < TEISUU.DEFAULTTIME) ari++;
    }
    if (ari > 0 && ari * 2 >= hashiru.length) {
      idx = c;
      break;
    }
  }
  return idx;
}

/// 区間[kk]の区間記録(なければnull。1.9.2から展望記事の中にあったものを、実況でも使えるようにここへ移した。1.9.5)
/// [konkaiNozoku] 今回の大会(今の年と月)で出た記録を除いた最高記録にする。大会が終わると区間記録が
/// 更新されるので、結果画面で実況を読み直したときに、走る前の区間記録を出すため
({String name, String univ, double time, int year})? kukanKiroku(
  KijiKankyou k,
  int kk, {
  bool konkaiNozoku = false,
}) {
  final gh = k.gh;
  final int r = k.race;
  if (gh.time_zentaikukankiroku.length <= r) return null;
  if (gh.time_zentaikukankiroku[r].length <= kk) return null;
  final List<double> times = gh.time_zentaikukankiroku[r][kk];
  for (int i = 0; i < times.length; i++) {
    final double t = times[i];
    if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
    String name = '';
    String univ = '';
    int year = 0;
    int month = 0;
    if (gh.name_zentaikukankiroku.length > r &&
        gh.name_zentaikukankiroku[r].length > kk &&
        gh.name_zentaikukankiroku[r][kk].length > i) {
      name = gh.name_zentaikukankiroku[r][kk][i];
    }
    if (gh.univname_zentaikukankiroku.length > r &&
        gh.univname_zentaikukankiroku[r].length > kk &&
        gh.univname_zentaikukankiroku[r][kk].length > i) {
      univ = gh.univname_zentaikukankiroku[r][kk][i];
    }
    if (gh.year_zentaikukankiroku.length > r &&
        gh.year_zentaikukankiroku[r].length > kk &&
        gh.year_zentaikukankiroku[r][kk].length > i) {
      year = gh.year_zentaikukankiroku[r][kk][i];
    }
    if (gh.month_zentaikukankiroku.length > r &&
        gh.month_zentaikukankiroku[r].length > kk &&
        gh.month_zentaikukankiroku[r][kk].length > i) {
      month = gh.month_zentaikukankiroku[r][kk][i];
    }
    // 今回の大会の記録は飛ばして、次の記録を見る
    if (konkaiNozoku && year == gh.year && month == gh.month) continue;
    if (name.isEmpty) return null;
    return (name: name, univ: univ, time: t, year: year);
  }
  return null;
}

/// 対校戦(5000m・1万m・ハーフ)の選手[s]の因縁(点の高い順。1.9.4)
/// [juni] この種目の全体の順位(0が1位)。[kekka] 結果の記事ならtrue(文の時制が変わる)
/// 対校戦は全大学の全員が毎年走るので、「初めての対校戦」は因縁にしない(1年生はみな初めてで、
/// 2年生以上で初めてになるのは、ゲームを始める前の学年の記録がないときだけのため。1.9.7)
List<Innen> taikousenInnen(KijiKankyou k, SenshuData s, {int? juni, bool kekka = true}) {
  final List<Innen> list = [];
  final int race = k.race;
  if (race < 6 || race > 8) return list;
  final String sm = kijiShumokuMei[race - 6];
  // 昨年の同じ種目
  final int? maeJ = k.kukanJuniMae(s, race, 1);
  if (maeJ != null) {
    if (juni != null && maeJ - juni >= 5) {
      list.add(
        Innen(
          InnenShurui.juniUe,
          70,
          '昨年の$smは${juniMoji(maeJ)}。1年で${maeJ - juni}つ順位を上げた。',
          '去年は${juniMoji(maeJ)}で終わっていた。1年間、この種目で上に行くことを考えてきた',
          '昨年${juniMoji(maeJ)}からの',
        ),
      );
    } else if (juni != null && juni - maeJ >= 5) {
      list.add(
        Innen(
          InnenShurui.juniShita,
          35,
          '昨年の$smは${juniMoji(maeJ)}だったが、今年はその順位に届かなかった。',
          '去年の自分を超えられなかった。それが一番悔しい',
        ),
      );
    } else {
      list.add(
        Innen(
          InnenShurui.juniUe,
          30,
          '昨年も$smを走り、${juniMoji(maeJ)}だった。',
          kekka ? '去年もこの種目を走った。コースも展開も分かっていたのは大きかった' : '去年もこの種目を走った。展開は分かっている',
        ),
      );
    }
  }
  // 駅伝の本戦の出走歴
  // 前の学年の記録が欠けている選手(ゲームを始めた年の2〜4年生など)は、回数が少なく出るので数を書かない(1.9.7)
  final ({int kaisuu, int kukanshou}) reki = ekidenShussouKaisuu(k, s);
  if (reki.kaisuu >= 1) {
    list.add(
      Innen(
        InnenShurui.honsenKeiken,
        35 + (reki.kukanshou >= 1 ? 10 : 0),
        kirokuKaketeiru(s)
            ? '駅伝では本戦を走った経験がある${reki.kukanshou >= 1 ? '(区間賞も獲得)' : ''}。'
            : '駅伝では${reki.kaisuu}度の本戦出走${reki.kukanshou >= 1 ? '(区間賞${reki.kukanshou}度)' : ''}がある。',
        kekka ? '駅伝とは違うトラックの勝負。個人の戦いも楽しめた' : '駅伝とは違う個人の勝負。楽しみたい',
      ),
    );
  }
  // 4年生の最後の対校戦
  if (s.gakunen == 4) {
    list.add(
      Innen(
        InnenShurui.saigo,
        40,
        kekka ? 'これが最後の対校戦だった。' : 'これが最後の対校戦になる。',
        kekka ? '最後の対校戦。大学の名前を背負って走れるのも、あと少しだと感じた' : '最後の対校戦。大学の名前を背負って走れるうちに、いい走りをしたい',
        '最後の対校戦で',
      ),
    );
  }
  final Innen? nobi = nyuugakuNobiInnen(k, s);
  if (nobi != null) list.add(nobi);
  list.sort((a, b) => b.ten.compareTo(a.ten));
  return list;
}

// ------------------------------------------------------------
// 当日変更の事情(1.9.4)。結果の記事で、当日変更で入った選手と外れた選手の事情を書く
// ・外れた選手には区間の値に -(100+区間) の印が残り、調子は次の区間エントリーまで当日の値のまま
// ・温存の印(SenshuData.kazetaisei の負の値)は、コンピュータの大学の戦略的エントリーで付き、
//   次の区間エントリーまで残る(-1=1日開催・正月駅伝往路で使う、-2=正月駅伝復路で使う)
// ------------------------------------------------------------

/// 当日変更で外れた理由
enum HazuretaRiyuu {
  /// 体調不良(調子0)
  taichouFuryou,

  /// 調子が上がらなかった(調子1〜99)
  chousi,

  /// 調子には問題がなく、入れ替えた(理由は書かない)
  irekae,
}

/// 区間1つ分の当日変更の事情
class ToujituJijou {
  final int kukan;

  /// 入った選手
  final SenshuData hairi;

  /// 外れた選手
  final SenshuData hazureta;

  final HazuretaRiyuu riyuu;

  /// 入った選手が、補欠に温存していたエースか(コンピュータの大学の戦略的エントリー)
  final bool onzonAce;

  /// 復路用に温存していたエースを往路で使ったか(正月駅伝。体調不良の穴を埋めるときだけ起きる)
  final bool fukuroAceOuro;

  /// 復路のスタート前の当日変更か(正月駅伝の6区以降)
  final bool fukuro;

  /// 区間の距離に合った種目の持ちタイムの差(秒。正なら入った選手が速い。比べられなければnull)
  final int? mochiSa;

  const ToujituJijou({
    required this.kukan,
    required this.hairi,
    required this.hazureta,
    required this.riyuu,
    required this.onzonAce,
    required this.fukuroAceOuro,
    required this.fukuro,
    required this.mochiSa,
  });

  /// 急きょの起用か(体調不良か調子が上がらなかった穴を埋めた)
  bool get kyuukyo => riyuu != HazuretaRiyuu.irekae;
}

/// 大学[u]の、この大会の当日変更の事情(区間ごと。当日変更がなければ空)
/// [kukanSenshu] 区間ごとに走った選手(EkidenUnivKekka.senshu)
Map<int, ToujituJijou> toujituJijou(
  KijiKankyou k,
  UnivData u,
  List<SenshuData?> kukanSenshu,
) {
  final Map<int, ToujituJijou> map = {};
  for (final SenshuData t in k.senshu) {
    if (t.univid != u.id) continue;
    final int en = k.entry(t);
    if (en > -100) continue;
    final int kk = -en - 100;
    if (kk < 0 || kk >= kukanSenshu.length) continue;
    final SenshuData? h = kukanSenshu[kk];
    if (h == null || h.id == t.id) continue;
    final HazuretaRiyuu riyuu = t.chousi <= 0
        ? HazuretaRiyuu.taichouFuryou
        : (t.chousi < 100 ? HazuretaRiyuu.chousi : HazuretaRiyuu.irekae);
    final bool onzon = h.kazetaisei < 0;
    final int shumoku = kukanKihonShumoku(k.gh, k.race, kk);
    final double th = k.jikoBest(h, shumoku);
    final double tt = k.jikoBest(t, shumoku);
    final int? mochiSa = (th < TEISUU.DEFAULTTIME && tt < TEISUU.DEFAULTTIME)
        ? byou(tt) - byou(th)
        : null;
    map[kk] = ToujituJijou(
      kukan: kk,
      hairi: h,
      hazureta: t,
      riyuu: riyuu,
      onzonAce: onzon,
      fukuroAceOuro: k.race == 2 && onzon && h.kazetaisei == -2 && kk < 5,
      fukuro: k.race == 2 && kk >= 5,
      mochiSa: mochiSa,
    );
  }
  return map;
}

/// 当日変更の事情の地の文(「当日の朝、4区を走る予定だった田中が体調不良で走れなくなり、
/// 佐藤が急きょ区間に入った。」など。選手の呼び方は[w]で決める。[daigakuMei]は、
/// 自分の大学以外のときに大学名を入れる(空なら入れない))
String toujituJijouBun(ToujituJijou j, KijiKakite w, {String daigakuMei = ''}) {
  final String asa = j.fukuro ? '復路のスタート前' : '当日の朝';
  final String kukan = '${j.kukan + 1}区';
  final String d = daigakuMei.isEmpty ? '' : '$daigakuMeiは';
  final String out = w.senshu(j.hazureta);
  final String inn = w.senshu(j.hairi);
  final StringBuffer sb = StringBuffer();
  switch (j.riyuu) {
    case HazuretaRiyuu.taichouFuryou:
      if (j.onzonAce) {
        sb.write(
          j.fukuroAceOuro
              ? '$asa、$kukanを走る予定だった$outが体調不良で走れなくなり、$d復路に温存していたエース$innを往路に前倒しで投入した。'
              : '$asa、$kukanを走る予定だった$outが体調不良で走れなくなり、$d補欠に温存していたエース$innを急きょその穴に投入した。',
        );
      } else {
        sb.write(
          w.erabu([
            '$asa、$kukanを走る予定だった$outが体調不良で走れなくなり、$d$innが急きょ区間に入った。',
            '$kukanは$asaに動いた。$outが体調不良で外れ、$d$innを急きょ起用した。',
          ]),
        );
      }
      break;
    case HazuretaRiyuu.chousi:
      sb.write(
        j.onzonAce
            ? '$asa、調子の上がらなかった$kukanの$outに代えて、$d補欠に温存していたエース$innを投入した。'
            : '$asa、$d調子の上がらなかった$kukanの$outに代えて、$innを起用した。',
      );
      break;
    case HazuretaRiyuu.irekae:
      sb.write(
        j.onzonAce
            ? '$asa、$d補欠に温存していたエース$innを$kukanに投入し、$outが外れた。'
            : '$asa、$d$kukanの$outに代えて$innを起用した。',
      );
      break;
  }
  final int? ms = j.mochiSa;
  if (ms != null && !j.onzonAce) {
    if (ms >= 10) {
      sb.write('持ちタイムでは$innのほうが${saMoji(ms)}速い。');
    } else if (ms <= -10) {
      sb.write('持ちタイムでは$outに${saMoji(ms)}及ばない。');
    }
  }
  return sb.toString();
}

/// 当日変更で入った選手の、事情を含めたひと言(コメントの事実の部分。「。」なし)
/// [yoi] 結果が良かったか。[mae] レース前(スタート直前号)なら、これから走る言い方にする
String toujituJijouKotoba(
  ToujituJijou j,
  KijiRand r, {
  required bool yoi,
  bool mae = false,
}) {
  final String out = myouji(j.hazureta.name);
  if (mae) {
    if (j.riyuu == HazuretaRiyuu.taichouFuryou) {
      return r.erabu([
        '朝に$outさんが走れないと聞いた。$outさんの分まで走ります',
        '急に名前を呼ばれて驚いたけど、準備はしてきた。落ち着いて入りたい',
      ]);
    }
    if (j.riyuu == HazuretaRiyuu.chousi) {
      return '朝に起用を聞いた。チャンスをもらえた以上、結果で返したい';
    }
    return 'いつでも行けるように準備していた。任された区間で、思い切って走るだけです';
  }
  if (j.riyuu == HazuretaRiyuu.taichouFuryou) {
    return r.erabu(
      yoi
          ? [
              '朝に$outさんが走れないと聞いた。$outさんの分まで、と思って走った',
              '朝に名前を呼ばれた。驚いたけど、準備はしてきたので落ち着いて入れた',
            ]
          : [
              '朝に言われて準備が足りなかった、とは言いたくない。力が足りなかった',
              '$outさんの穴を埋めるつもりだった。それができなかったのが悔しい',
            ],
    );
  }
  if (j.riyuu == HazuretaRiyuu.chousi) {
    return yoi
        ? '朝に起用を聞いた。チャンスをもらえた以上、結果で返したかった'
        : '朝に起用を聞いて、気持ちは入っていた。体がついてこなかった';
  }
  return yoi
      ? 'いつでも行けるように準備していた。チャンスをもらえてよかった'
      : '起用してもらったのに応えられなかった。この悔しさは次で返したい';
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

  /// 選手を初めて出すときのかっこの中の学年(「3年」。主将なら、画面と同じく「4年・主将」。2.0.2)
  String gakunenKakko(SenshuData s) =>
      '${s.gakunen}年${k.shushou(s) ? shushouShirushiMoji : ''}';

  /// 選手の呼び方。初めては「山田太郎(3年)」(主将は「山田太郎(4年・主将)」。2.0.2)、2回目からは「山田」
  /// [daigaku] 初めて出すときに「東西大の」を前に付けるか
  String senshu(SenshuData s, {bool daigaku = false}) {
    return hito(
      'S${s.id}',
      s.name,
      gakunenKakko(s),
      daigaku && s.univid >= 0 && s.univid < k.univ.length
          ? '${daigakuMei(k.univ[s.univid])}の'
          : '',
    );
  }

  /// 選手の呼び方に、かっこの補足[soe]を添える
  /// (初めては「山田太郎(2年・区間5位)」、2回目からは「山田(区間5位)」。学年のかっこのすぐ後ろに
  /// 別のかっこが続かないように1つにまとめる。[soe]が空なら senshu と同じ。1.9.8)
  String senshuSoe(SenshuData s, String soe, {bool daigaku = false}) {
    return hitoSoe(
      'S${s.id}',
      s.name,
      gakunenKakko(s),
      daigaku && s.univid >= 0 && s.univid < k.univ.length
          ? '${daigakuMei(k.univ[s.univid])}の'
          : '',
      soe,
    );
  }

  /// 人の呼び方に、かっこの補足[soe]を添える(hito と同じ決まりで、初めてなら[kakko]と1つのかっこにまとめる。1.9.8)
  String hitoSoe(String kagi, String name, String kakko, String atama, String soe) {
    if (soe.isEmpty) return hito(kagi, name, kakko, atama);
    if (_deta.contains(kagi)) return '${hito(kagi, name, kakko, atama)}($soe)';
    return hito(kagi, name, kakko.isEmpty ? soe : '$kakko・$soe', atama);
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
  /// [midashi] 欄の名前(展望は「本紙の見立て」、学内メディアは「編集部の目」)
  void kishaNoMe(String bun, {String midashi = '記者の目'}) {
    if (bun.trim().isEmpty) return;
    koMidashi(midashi);
    danraku(bun);
  }

  void koMidashi(String bun) {
    honbun.add(KijiBlock(KijiBlockShurui.koMidashi, bun));
  }

  /// 本文の途中に表を置く(選手の三大駅伝の成績など。1.9.7)
  void hyou(KijiHyou h) {
    honbun.add(KijiBlock(KijiBlockShurui.hyou, '', hyou: h));
  }
}

/// 出身地と趣味の一言(「福岡県出身。趣味は○○という」など。書けることがなければ空)
/// 1.9.5から、出身校と高校時代の一言(koukouJidaiBun)を後ろに付ける
String shusshinShumiBun(KijiKankyou k, SenshuData s, KijiRand r, String yobi) {
  final String moto = _shusshinShumiBunMoto(k, s, r, yobi);
  return '$moto${koukouJidaiBun(k, s, r, yobi)}';
}

/// 出身地と趣味の一言(1.9.4までの shusshinShumiBun の中身)
String _shusshinShumiBunMoto(KijiKankyou k, SenshuData s, KijiRand r, String yobi) {
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
