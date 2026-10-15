import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // 大会の名前(courseRaceTitle)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_gakunai.dart' show gakunaiSiteMeiJibun, gakunaiKishaMei;

// ------------------------------------------------------------
// 夏のタイムトライアル特集(2.0.0。8月25日のロード10kmの結果画面のカードから。読めるのはその日だけ)
// ・箱庭スポーツの「夏のTT特集」: 全大学の夏のTT(クロカン10km・登り10km・下り10km・ロード10km)の好タイムの選手
// ・学内メディアの「学内TT特集」: 自分の大学の、種目ごとの学内上位・昨夏からの伸び・1年生
// (大会に関係ない記事なので、年間表彰と同じく正月駅伝を記事にする大会として読む。KijiKankyou.yomuRace(2))
//
// ・夏のTTは、どの大学も同じコース・同じ条件で走る(現実では大学ごとに違うが、このゲームでは同じ)。
//   記事では「箱庭長距離陸上競技連盟が定めた共通のコースと条件」と、ゲームの世界の言葉で断る
// ・TTには調子が効かず、乱数もごくわずかなので、タイムがほぼそのまま実力の目安になる
//
// 箱庭スポーツは2本(点を付けて見出しと段落の順を決める。新入生の記事と同じ作り方)
//  1本目「夏のTT特集」(種目編): 4種目の段落を毎年必ず入れる(見出しの種目を先頭に、残りは日程の順。
//    クロカン7/25・登り8/5・下り8/15・ロード8/25)。どの段落も、コースの紹介・好タイムの選手(タイムで)・
//    上位が留学生なら日本人の好タイム・ロードでは目立たなかったのにその種目で光った選手・関係する区間の候補
//    (クロカンはアップダウンの続く区間、登りは山登り、下りは山下り。区間はコースのデータから探す)を書く
//  2本目「夏のTTを読み解く」(観点編): 4種目そろって好タイムの選手、昨夏からの伸び、1年生、大学ごとの層
//    (種目ごとに、その年のタイムから決めた○分を切った人数。本文はロードを中心に、登り・下り・クロカンも1文ずつ)、
//    自分の大学を、記録がある限り毎年全部入れる
//  ・現実の報道では、ロードの次に登り(山登り)が大きく扱われ、クロカンはあまり取り上げられないので、
//    見出しの重みはロード・登り・下り・クロカンの順にし、表と学内TT特集の種目もこの順に並べる
// ・前の年と同じ型の見出しは避ける(1本目は KantokuData.yobiint3[78]、2本目は[79]。kiji_kihon.dart の KijiMidashiKiroku)
//
// 守る決まり
//  ・全体順位は、選ぶのと並べるのにだけ使い、記事の言葉には「1位」「全体○位」「最速」「トップ」を書かない。
//    「目を引いたのは」「好タイム」のように、タイムで書く(表も順位の列を付けない)。
//    学内メディアは結果画面に出ている学内順位なので「学内1位」と書いてよい
//  ・TTの歴代記録と自己ベストは画面に出していないので書かない(TTは年に1度なので、自己ベストの更新も
//    ほとんどの選手に付いてしまう)。昨夏との比べは、選手画面の学年ごとの成績で確かめられるので書いてよい
//  ・能力の名前(アップダウン対応力・安定感・粘りなど)や性質の言葉(勝負強いなど)は書かない。区間との関係は、
//    仕様に書いてあること(クロカン1万は起伏に関係する)の範囲で「アップダウンの続く区間の候補」と書く
//  ・総監督(プレイヤー)の言葉は作らない。箱庭スポーツでは、自分の大学の監督のコメントも出さない
// ------------------------------------------------------------

/// 箱庭スポーツの夏のTT特集のカテゴリ
const String kijiTtCategory = '夏のTT';

/// 学内メディアの学内TT特集のカテゴリ
const String kijiTtGakunaiCategory = '学内TT';

/// 夏のTT特集の記事か(生成AIに渡すときの依頼文を変える)
bool kijiTtKa(Kiji kiji) => kiji.category == kijiTtCategory || kiji.category == kijiTtGakunaiCategory;

/// 夏のTTの最終日のレースの番号(8月25日のロード10km)。この日の結果画面にカードを置く
const int ttSaishuuRace = 15;

/// 前の年の見出しの型を残す場所(KantokuData.yobiint3の番号。KijiMidashiKiroku。1本目と2本目)
const int ttMidashiIndex = 78;
const int ttKantenMidashiIndex = 79;

/// 記事の番号(乱数と記者の名前に使う。1本目・学内・2本目)
const int _no = 193;
const int _noGakunai = 194;
const int _noKanten = 195;

/// TTの種目(レースの番号)。表や学内TT特集で並べる順(ロード・登り・下り・クロカン。現実の報道にならい、
/// 駅伝に一番近いロードの次に、山登りにつながる登りを置く)
const int _road = 15;
const int _kurokan = 16;
const int _nobori = 13;
const int _kudari = 14;
const List<int> _shumoku = [_road, _nobori, _kudari, _kurokan];

/// 種目の名前(結果画面・選手画面と同じ呼び方)
String _mei(int race) {
  switch (race) {
    case _nobori:
      return '登り10km';
    case _kudari:
      return '下り10km';
    case _kurokan:
      return 'クロカン10km';
    default:
      return 'ロード10km';
  }
}

/// 選手[s]の、[maeNen]年前の夏のTTの種目[race]のタイム(秒。なければnull)
double? _ttTime(SenshuData s, int race, {int maeNen = 0}) {
  if (s.kukantime_race.length <= race) return null;
  final int g = s.gakunen - 1 - maeNen;
  if (g < 0 || g >= s.kukantime_race[race].length) return null;
  final double t = s.kukantime_race[race][g];
  if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
  return t;
}

/// 記事の材料
class _TtShiryou {
  final KijiKankyou k;

  /// 種目ごとの、今夏のタイムの順の選手
  final Map<int, List<SenshuData>> jun = {};

  /// 種目ごとの、選手id → 今夏のタイムの順(0が一番速い。選ぶのと並べるのにだけ使う)
  final Map<int, Map<int, int>> juni = {};

  _TtShiryou(this.k) {
    for (final int race in _shumoku) {
      final List<SenshuData> l = [
        for (final SenshuData s in k.senshu)
          if (s.gakunen >= 1 && s.gakunen <= 4 && s.univid >= 0 && s.univid < k.univ.length && _ttTime(s, race) != null) s,
      ]..sort((a, b) {
          final int c = _ttTime(a, race)!.compareTo(_ttTime(b, race)!);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      jun[race] = l;
      juni[race] = {for (int i = 0; i < l.length; i++) l[i].id: i};
    }
  }

  List<SenshuData> l(int race) => jun[race] ?? const [];

  double t(SenshuData s, int race) => _ttTime(s, race) ?? TEISUU.DEFAULTTIME;

  /// 種目[race]の順(なければ大きな数)
  int j(SenshuData s, int race) => juni[race]?[s.id] ?? 9999;

  String univMei(SenshuData s) => daigakuMei(k.univ[s.univid]);

  /// 日本人の選手で一番タイムの良い選手(いなければnull)
  SenshuData? nihonjin(int race) {
    for (final SenshuData s in l(race)) {
      if (s.hirou != 1) return s;
    }
    return null;
  }

  /// 層を数えるタイムの区切り(分。種目[race]で、この分を切った選手が20人以上になる一番小さい分。
  /// 種目ごとにその年のタイムから決める)
  late final Map<int, int> _kugiri = {for (final int race in _shumoku) race: _kugiriTsukuru(race)};

  int kugiri(int race) => _kugiri[race] ?? 30;

  int _kugiriTsukuru(int race) {
    final List<SenshuData> r = l(race);
    if (r.isEmpty) return 30;
    int m = t(r.first, race) ~/ 60 + 1;
    while (m < 90 && r.where((s) => t(s, race) < m * 60).length < 20) {
      m++;
    }
    return m;
  }

  /// 種目[race]で区切りを切った人数(大学ごと。多い順。同じなら大学id順)
  late final Map<int, List<MapEntry<int, int>>> _sou = {for (final int race in _shumoku) race: _souTsukuru(race)};

  List<MapEntry<int, int>> souOf(int race) => _sou[race] ?? const [];

  List<MapEntry<int, int>> _souTsukuru(int race) {
    final Map<int, int> m = {};
    for (final SenshuData s in l(race)) {
      if (t(s, race) >= kugiri(race) * 60) break;
      m[s.univid] = (m[s.univid] ?? 0) + 1;
    }
    return m.entries.toList()
      ..sort((a, b) {
        final int c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
  }

  /// 種目[race]で区切りを切った人数(全体)
  int kugiriNinzuuOf(int race) => souOf(race).fold<int>(0, (a, e) => a + e.value);

  /// 大学[univid]の、種目[race]で区切りを切った人数
  int kugiriKazu(int race, int univid) => souOf(race).where((e) => e.key == univid).fold<int>(0, (a, e) => a + e.value);

  /// ロード10kmの区切り・層・人数(本文の中心はロード)
  int get kugiriFun => kugiri(_road);
  List<MapEntry<int, int>> get sou => souOf(_road);
  int get kugiriNinzuu => kugiriNinzuuOf(_road);

  /// 4種目そろって好タイムの選手(4種目の順のうち一番悪いものが一番良い選手と、その順。なければnull)
  late final ({SenshuData s, int warui})? zenshu = _zenshuTsukuru();

  ({SenshuData s, int warui})? _zenshuTsukuru() {
    SenshuData? best;
    int bestWarui = 9999;
    for (final SenshuData s in l(_road)) {
      int warui = 0;
      for (final int race in _shumoku) {
        final int x = j(s, race);
        if (x > warui) warui = x;
      }
      if (warui < bestWarui) {
        bestWarui = warui;
        best = s;
      }
    }
    if (best == null || bestWarui >= 30) return null;
    return (s: best, warui: bestWarui);
  }

  /// 昨夏から大きく縮めた選手(秒の大きい順に2人まで。30秒以上。選手ごとに一番縮めた種目)
  late final List<({SenshuData s, int race, int sa})> nobi = _nobiTsukuru();

  List<({SenshuData s, int race, int sa})> _nobiTsukuru() {
    final List<({SenshuData s, int race, int sa})> l2 = [];
    for (final SenshuData s in k.senshu) {
      if (s.gakunen < 2 || s.gakunen > 4 || s.univid < 0 || s.univid >= k.univ.length) continue;
      ({SenshuData s, int race, int sa})? b;
      for (final int race in _shumoku) {
        final double? kon = _ttTime(s, race);
        final double? mae = _ttTime(s, race, maeNen: 1);
        if (kon == null || mae == null) continue;
        final int sa = saByou(mae, kon);
        if (sa >= 30 && (b == null || sa > b.sa)) b = (s: s, race: race, sa: sa);
      }
      if (b != null) l2.add(b);
    }
    l2.sort((a, b) {
      final int c = b.sa.compareTo(a.sa);
      return c != 0 ? c : a.s.id.compareTo(b.s.id);
    });
    return l2.take(2).toList();
  }

  /// ロード10kmの1年生で一番タイムの良い選手(いなければnull)
  SenshuData? get ichinen {
    for (final SenshuData s in l(_road)) {
      if (s.gakunen == 1) return s;
    }
    return null;
  }

  /// 入学時の5000mが世代トップだった1年生(留学生は除く。いなければnull)
  SenshuData? get sedaiTop {
    SenshuData? best;
    for (final SenshuData s in k.senshu) {
      if (s.gakunen != 1 || s.hirou == 1 || s.univid < 0 || s.univid >= k.univ.length) continue;
      final double t5 = s.kiroku_nyuugakuji_5000;
      if (t5 <= 0 || t5 >= TEISUU.DEFAULTTIME) continue;
      if (best == null || t5 < best.kiroku_nyuugakuji_5000) best = s;
    }
    return best;
  }

  /// 正月駅伝・10月駅伝・11月駅伝で、特徴が[toku]の区間(「正月駅伝の4区・7区、10月駅伝の5区」。なければ空)
  String kukanMoji(KukanTokuchou toku) {
    final List<String> l2 = [];
    for (final int race in const [2, 0, 1]) {
      if (k.gh.kukansuu_taikaigoto.length <= race) continue;
      final int n = k.gh.kukansuu_taikaigoto[race];
      final List<String> ku = [];
      for (int kk = 0; kk < n; kk++) {
        if (kukanTokuchou(k.gh, race, kk) == toku) ku.add('${kk + 1}区');
      }
      if (ku.isNotEmpty) l2.add('${courseRaceTitle(race)}の${ku.join('・')}');
    }
    return l2.join('、');
  }
}

// ------------------------------------------------------------
// 言い回し
// ------------------------------------------------------------

const List<String> _ttKotoba = [
  '夏の練習の成果を確かめられた。秋の駅伝につなげたい',
  'まだ夏の途中。ここからもう一段上げていきたい',
  '設定どおりに走れたことが一番の収穫です',
  'チームのみんなと高め合えている。秋が楽しみです',
];

const List<String> _kurokanKotoba = [
  '起伏の多いコースは苦しかった。でも、秋の駅伝に生きる練習になった',
  'クロカンは脚にくる。それでも最後まで走り切れたのはよかった',
  'アップダウンの続くコースで走れたのは自信になる',
];

const List<String> _nobiKotoba = [
  '1年間積み上げてきたことが、タイムに出てうれしい',
  '去年の自分を超えることを目標にしてきた。少しは成長できたと思う',
];

const List<String> _ichinenKotoba = [
  '大学の練習にも慣れてきた。先輩たちに少しでも近づきたい',
  '初めての夏合宿はきつかったけど、手応えはある',
];

const List<String> _senshuShime = ['話した', '汗をぬぐった', '前を向いた', '笑顔を見せた'];

const List<String> _kantokuShime = ['語った', '話した', 'うなずいた'];

/// 大学の監督の言葉(箱庭スポーツ。自分の大学の監督は出さない)
const List<String> _kantokuKotoba = [
  '夏の仕上がりは順調。秋はこの状態を本番につなげたい',
  'タイムはあくまで目安。駅伝のメンバーはこれから決めていく',
  '選手たちがよく練習を積んでくれた',
];

/// 学内メディア・自分の大学の監督の言葉
const List<String> _jibunKantokuKotoba = [
  '夏の取り組みが形になってきた。秋に向けて、ここからが勝負',
  'タイムはあくまで目安。メンバーはこれから見極めていく',
  '上級生も下級生も、いい競争ができている',
];

// ------------------------------------------------------------
// 箱庭スポーツ「夏のTT特集」(1本目・種目編)と「夏のTTを読み解く」(2本目・観点編)
// ------------------------------------------------------------

/// 登り10kmの好タイムの選手の言葉
const List<String> _noboriKotoba = [
  '登りは苦しいけれど、走っていて楽しい',
  '山登りの区間を任されたら、しっかり走りたい',
  '最後まで脚を動かし続けることだけを考えた',
];

/// 下り10kmの好タイムの選手の言葉
const List<String> _kudariKotoba = [
  '下りは怖さもあるけれど、思い切って行けた',
  '山下りの区間を任されたら、しっかり走りたい',
  '脚へのダメージは大きかった。ケアをして秋に備えたい',
];

/// 1本目の見出しの型(種目。前の年と同じ型を避けるために番号で残すので、番号を変えない)
const int _gRoad = 1;
const int _gKurokan = 2;
const int _gNobori = 3;
const int _gKudari = 4;

/// 2本目の見出しの型(観点。同じく番号を変えない)
const int _gZenshu = 1;
const int _gNobi = 2;
const int _gIchinen = 3;
const int _gSou = 4;

/// 2本目の段落の種類
enum _Kanten { zenshu, nobi, ichinen, sou }

/// 見出しの型 → 種目
int _gRace(int g) => g == _gKurokan ? _kurokan : (g == _gNobori ? _nobori : (g == _gKudari ? _kudari : _road));

/// 日程の順(クロカン7/25・登り8/5・下り8/15・ロード8/25)
const List<int> _nittei = [_kurokan, _nobori, _kudari, _road];

class _Tt {
  final _TtShiryou d;
  final KijiKakite w;
  final Set<int> _commentZumi = {};

  /// 見出しで取り上げた大学
  int? midashiUnivId;

  _Tt(this.d, this.w);

  KijiKankyou get k => d.k;

  /// 選手の呼び方(初めては「東西大の山田太郎(3年)」、2回目からは「山田」)
  String yobu(SenshuData s) => w.senshu(s, daigaku: true);

  /// 選手の言葉(同じ選手は1度だけ)
  void kotoba(SenshuData s, List<String> kouho) {
    if (_commentZumi.contains(s.id)) return;
    _commentZumi.add(s.id);
    w.comment('「${w.erabu(kouho)}」と${yobu(s)}は${w.erabu(_senshuShime)}。');
  }

  /// 大学の監督の言葉(自分の大学と、監督がいない大学は出さない)
  void kantoku(SenshuData s) {
    final int uid = s.univid;
    if (uid == k.gh.MYunivid) return;
    final ({String name, int nenrei})? kt = k.kantokuMei(uid);
    if (kt == null) return;
    final String kagi = 'K$uid';
    final bool hajimete = !w.deta(kagi);
    final String yobi = w.hito(kagi, kt.name, '', '');
    final String kata = hajimete ? '${d.univMei(s)}の$yobi監督(${kt.nenrei})' : '$yobi監督';
    w.comment('「${w.erabu(_kantokuKotoba)}」と$kataは${w.erabu(_kantokuShime)}。');
  }

  /// 種目[race]で一番タイムの良い選手(いなければnull)
  SenshuData? saki(int race) => d.l(race).isEmpty ? null : d.l(race).first;

  /// 種目[race]で目立ち、ロードでは目立たなかった選手(その種目の上位(クロカンは10人、登り・下りは5人)にいて、
  /// ロードが30番目より後ろ。ロードは対象外。いなければnull)
  SenshuData? tokui(int race) {
    if (race == _road) return null;
    for (final SenshuData s in d.l(race).take(race == _kurokan ? 10 : 5)) {
      if (d.j(s, _road) >= 30) return s;
    }
    return null;
  }

  /// 種目[race]に関係する区間(「正月駅伝の5区」など。なければ空)
  String kukan(int race) {
    switch (race) {
      case _kurokan:
        return d.kukanMoji(KukanTokuchou.updown);
      case _nobori:
        return d.kukanMoji(KukanTokuchou.yamaNobori);
      case _kudari:
        return d.kukanMoji(KukanTokuchou.yamaKudari);
      default:
        return '';
    }
  }

  // ---- 点 ----

  /// 1本目の見出しの点(現実の報道にならい、ロード・登り・下り・クロカンの順に重く。目立った選手がいれば少し足す)
  int shumokuTen(int race) {
    if (d.l(race).isEmpty) return 0;
    switch (race) {
      case _road:
        return 75;
      case _nobori:
        return 70 + (tokui(race) != null ? 5 : 0);
      default:
        return 65 + (tokui(race) != null ? 5 : 0);
    }
  }

  int get zenshuTen {
    final ({SenshuData s, int warui})? z = d.zenshu;
    if (z == null) return 0;
    return z.warui < 15 ? 70 : 50;
  }

  int get nobiTen {
    if (d.nobi.isEmpty) return 0;
    return d.nobi.first.sa >= 60 ? 65 : 55;
  }

  int get ichinenTen {
    final SenshuData? s = d.ichinen;
    if (s == null) return 0;
    return d.j(s, _road) < 10 ? 65 : 50;
  }

  int get souTen {
    if (d.sou.isEmpty) return 0;
    return d.sou.first.value >= 6 ? 60 : 45;
  }

  // ---- 1本目の見出し・リード ----

  String shumokuMidashi(int race) {
    final SenshuData? s = saki(race);
    if (s == null) return '夏のタイムトライアル特集';
    String mei(SenshuData x) => fullMei(x.name);
    final String t = jikanMoji(d.t(s, race));
    final String u = d.univMei(s);
    midashiUnivId = s.univid;
    switch (race) {
      case _kurokan:
        return w.erabu([
          '起伏の難コースで$t　クロカン10kmは${mei(s)}($u)',
          'クロカン10kmで光った${mei(s)}　アップダウンの区間の候補に',
          '$uの${mei(s)}、クロカン10kmで$t',
        ]);
      case _nobori:
        return w.erabu([
          '山の候補が見えた　登り10kmは${mei(s)}($u)',
          '登り10kmで$t　$uの${mei(s)}に山登りの期待',
        ]);
      case _kudari:
        return w.erabu([
          '下り10kmで$t　$uの${mei(s)}に山下りの期待',
          '駆け下りる夏　下り10kmは${mei(s)}($u)が$t',
        ]);
      default:
        return w.erabu([
          'ロード10kmで$t　${mei(s)}($u)が好タイム',
          '夏の仕上がりはロードに表れた　$uの${mei(s)}、$t',
          '$u・${mei(s)}、ロード10kmで$t',
        ]);
    }
  }

  /// 1本目のリード(記者の型の書き出し・断り書き・見出しの事実)
  String shumokuLead(int race, KishaKata kata) {
    final StringBuffer b = StringBuffer();
    final int nobe = _shumoku.fold<int>(0, (a, r) => a + d.l(r).length);
    switch (kata) {
      case KishaKata.suuji:
        b.write('4種目、のべ$nobe人。各大学の夏のタイムトライアルが、8月25日のロード10kmで締めくくられた。');
      case KishaKata.joukei:
        b.write(w.erabu([
          '8月25日、夏のタイムトライアルの最後を飾るロード10kmが行われた。夏の間に積み上げた成果が、タイムになって表れた。',
          '夏のタイムトライアルが、8月25日のロード10kmで幕を閉じた。秋の駅伝へ向けた、夏の答え合わせだ。',
        ]));
      case KishaKata.karakuchi:
        b.write('夏のタイムトライアルが終わった。好タイムに沸く大学がある一方で、層の薄さが見えた大学もある。');
    }
    // 断り書き(ゲームでは、どの大学も同じコース・同じ条件で走る)
    b.write(w.erabu([
      '夏のタイムトライアルは、箱庭長距離陸上競技連盟が定めた共通のコースと条件で、各大学が行う。大学をまたいでタイムを比べられるのは、そのためだ。',
      '各大学のタイムトライアルは、箱庭長距離陸上競技連盟の定めた共通のコースと条件で行われるため、大学をまたいで比べることができる。',
    ]));
    final SenshuData? s = saki(race);
    if (s != null) {
      final String t = jikanMoji(d.t(s, race));
      switch (race) {
        case _kurokan:
          b.write('起伏の激しいクロカン10kmでは、${yobu(s)}が$tをマークした。');
        case _nobori:
          b.write('登り10kmでは${yobu(s)}が$tをマークし、山登りの区間の候補に名乗りを上げた。');
        case _kudari:
          b.write('下り10kmでは${yobu(s)}が$tをマークし、山下りの区間の候補に名乗りを上げた。');
        default:
          b.write('駅伝に一番近いロード10kmでは、${yobu(s)}の$tが目を引いた。');
      }
    }
    b.write('4種目の結果を振り返る。');
    return b.toString();
  }

  // ---- 1本目の段落(種目ごと。毎年4つとも入れる) ----

  /// 好タイムの選手を並べる文(「東西大の山田太郎(3年)が28分31秒、…」。[nin]人まで。[nozoku]の選手は除く)
  String _narabe(int race, int nin, {Set<int> nozoku = const {}}) {
    final List<String> l = [];
    for (final SenshuData s in d.l(race)) {
      if (nozoku.contains(s.id)) continue;
      l.add('${yobu(s)}が${jikanMoji(d.t(s, race))}');
      if (l.length >= nin) break;
    }
    return l.join('、');
  }

  /// 種目[race]の段落([midashi] 見出しの種目なら、監督の言葉も添えやすくする)
  void shumokuDan(int race, {required bool midashi}) {
    final SenshuData? s = saki(race);
    if (s == null) return;
    final String ku = kukan(race);
    final StringBuffer b = StringBuffer();
    // コースの紹介
    switch (race) {
      case _kurokan:
        b.write(w.erabu([
          '7月25日のクロカン10kmは、登りと下りが絶え間なく続く、4種目で一番過酷なコースだ。',
          '登りと下りが休みなく続くクロカン10kmは、夏のタイムトライアルの中でも過酷な種目だ。',
        ]));
        if (ku.isNotEmpty) {
          b.write(w.erabu([
            'アップダウンの続く区間($ku)を占う種目として、各大学の首脳陣も注目する。',
            '$kuのような、アップダウンの続く区間の候補選びにもつながる。',
          ]));
        }
      case _nobori:
        b.write(w.erabu([
          '8月5日の登り10kmは、ひたすら上り坂が続くコースだ。',
          '上り坂が延々と続く登り10kmは、脚にも心肺にもこたえる種目だ。',
        ]));
        if (ku.isNotEmpty) b.write('山登りの区間($ku)の候補を探る種目でもある。');
      case _kudari:
        b.write(w.erabu([
          '8月15日の下り10kmは、下り坂を駆け下りるコースだ。',
          '下り坂が続く下り10kmは、スピードに乗る怖さとの戦いでもある。',
        ]));
        if (ku.isNotEmpty) b.write('山下りの区間($ku)の候補を探る種目でもある。');
      default:
        b.write(w.erabu([
          '8月25日のロード10kmは、駅伝に一番近い平坦なコースだ。',
          '最終日のロード10kmは、駅伝の舞台と同じロードの平坦なコースで行われた。',
        ]));
    }
    // 好タイムの選手(名前は候補を並べる前に1度だけ作る。候補ごとに呼ぶと、2つ目の候補が名字だけになるため。2.0.2)
    final String ys = yobu(s);
    b.write(w.erabu([
      '目を引いたのは$ysの${jikanMoji(d.t(s, race))}だ。',
      'ここで$ysが${jikanMoji(d.t(s, race))}をマークした。',
    ]));
    final String hoka = _narabe(race, race == _road ? 3 : 2, nozoku: {s.id});
    if (hoka.isNotEmpty) b.write('$hokaと好タイムが続いた。');
    // 上位が留学生なら、日本人の好タイムも書く
    final SenshuData? nj = d.nihonjin(race);
    if (s.hirou == 1 && nj != null && d.j(nj, race) >= (race == _road ? 4 : 3)) {
      b.write('日本人では、${yobu(nj)}の${jikanMoji(d.t(nj, race))}が光った。');
    }
    // ロードでは目立たなかったのに、この種目で光った選手
    final SenshuData? tk = tokui(race);
    if (tk != null) {
      final String basho = switch (race) {
        _kurokan => ku.isNotEmpty ? 'アップダウンの区間で、名前が挙がりそうだ。' : '起伏のある区間で、名前が挙がりそうだ。',
        _nobori => '山登りの区間で、名前が挙がりそうだ。',
        _ => '山下りの区間で、名前が挙がりそうだ。',
      };
      b.write('ロード10kmでは目立たなかった${yobu(tk)}も、${_mei(race)}では${jikanMoji(d.t(tk, race))}と好タイム。$basho');
    }
    if (race == _road && d.kugiriNinzuu > 0) {
      b.write('${d.kugiriFun}分を切った選手は、全体で${d.kugiriNinzuu}人だった。');
    }
    w.danraku(b.toString());
    // 言葉(目立った選手がいればその選手、いなければ好タイムの選手)
    final SenshuData c = tk ?? s;
    kotoba(
      c,
      switch (race) {
        _kurokan => _kurokanKotoba,
        _nobori => _noboriKotoba,
        _kudari => _kudariKotoba,
        _ => _ttKotoba,
      },
    );
    if (midashi && w.r.kakuritsu(60)) kantoku(s);
  }

  /// 1本目の記者の目
  void shumokuKishaNoMe(KishaKata kata) {
    switch (kata) {
      case KishaKata.suuji:
        w.kishaNoMe(
          '4種目、のべ${_shumoku.fold<int>(0, (a, r) => a + d.l(r).length)}人のタイムがそろった。数字は夏の到達点にすぎない。'
          '秋の駅伝で、この数字がどう生きるかを見たい。',
        );
      case KishaKata.joukei:
        w.kishaNoMe(w.erabu([
          '夏に流した汗は、秋のたすきにつながる。クロカンの起伏も、坂道の苦しさも、いつか駅伝の一歩になる。',
          '暑さの中で積み上げた夏が終わった。秋、たすきを手にするのは誰か。',
        ]));
      case KishaKata.karakuchi:
        w.kishaNoMe(
          'TTのタイムは夏の物差しだ。駅伝の本番で同じように走れるとは限らない。好タイムに浮かれず、秋に答えを出してほしい。',
        );
    }
  }

  /// 種目ごとの好タイムの表(順位の列は付けない)
  KijiHyou? hyou(int race) {
    final List<SenshuData> l = d.l(race);
    if (l.isEmpty) return null;
    return KijiHyou(
      '${_mei(race)}の好タイム(10人)',
      ['選手', '大学', '学年', 'タイム'],
      [
        for (final SenshuData s in l.take(10))
          [fullMei(s.name), d.univMei(s), '${s.gakunen}年', jikanMoji(d.t(s, race))],
      ],
    );
  }

  // ---- 2本目の見出し・リード ----

  String kantenMidashi(int g) {
    String mei(SenshuData x) => fullMei(x.name);
    switch (g) {
      case _gZenshu:
        {
          final ({SenshuData s, int warui})? z = d.zenshu;
          if (z == null) return kantenMidashi(_gSou);
          midashiUnivId = z.s.univid;
          return w.erabu([
            '4種目そろって好タイム　${d.univMei(z.s)}の${mei(z.s)}',
            '${mei(z.s)}(${d.univMei(z.s)})、夏のTTは4種目すべてで好タイム',
          ]);
        }
      case _gNobi:
        {
          if (d.nobi.isEmpty) return kantenMidashi(_gSou);
          final ({SenshuData s, int race, int sa}) n = d.nobi.first;
          midashiUnivId = n.s.univid;
          return w.erabu([
            '昨夏から${saMoji(n.sa)}短縮　${d.univMei(n.s)}の${mei(n.s)}が急成長',
            '${mei(n.s)}、${_mei(n.race)}で昨夏から${saMoji(n.sa)}縮める',
          ]);
        }
      case _gIchinen:
        {
          final SenshuData? s = d.ichinen;
          if (s == null) return kantenMidashi(_gSou);
          midashiUnivId = s.univid;
          return w.erabu([
            '1年生の${mei(s)}がロード10kmで${jikanMoji(d.t(s, _road))}　${d.univMei(s)}に新星',
            '上級生に交じって好タイム　${d.univMei(s)}の1年生${mei(s)}',
          ]);
        }
      default:
        {
          if (d.sou.isEmpty) return '夏のTTを読み解く';
          final MapEntry<int, int> e = d.sou.first;
          midashiUnivId = e.key;
          final String u = daigakuMei(k.univ[e.key]);
          return w.erabu([
            '${d.kugiriFun}分切り${e.value}人　$uが層の厚さ',
            '$u、ロード10kmで${d.kugiriFun}分切り${e.value}人',
            '夏のTTを読み解く　層の厚さは$u',
          ]);
        }
    }
  }

  /// 2本目のリード
  String kantenLead(int g, KishaKata kata) {
    final StringBuffer b = StringBuffer();
    switch (kata) {
      case KishaKata.suuji:
        b.write('ロード10kmで${d.kugiriFun}分を切った選手は${d.kugiriNinzuu}人、${d.sou.length}校に分かれた。');
      case KishaKata.joukei:
        b.write(w.erabu([
          'タイムの数字の向こうに、それぞれの夏が見える。',
          '4種目のタイムを並べると、選手とチームの夏の歩みが浮かび上がる。',
        ]));
      case KishaKata.karakuchi:
        b.write('好タイムを並べた大学と、そうでない大学。夏のタイムトライアルは、チームの力の差を隠さない。');
    }
    b.write('連盟の共通の条件で行われた夏のタイムトライアルの結果を、選手の伸びやチームの層から読み解く。');
    switch (g) {
      case _gZenshu:
        final ({SenshuData s, int warui})? z = d.zenshu;
        if (z != null) b.write('${yobu(z.s)}は、4種目すべてで好タイムを並べた。');
      case _gNobi:
        if (d.nobi.isNotEmpty) {
          final ({SenshuData s, int race, int sa}) n = d.nobi.first;
          b.write('${yobu(n.s)}は${_mei(n.race)}で、昨夏から${saMoji(n.sa)}縮めた。');
        }
      case _gIchinen:
        final SenshuData? s = d.ichinen;
        if (s != null) b.write('1年生の${yobu(s)}は、ロード10kmで${jikanMoji(d.t(s, _road))}をマークし、上級生に交じって存在感を示した。');
      default:
        if (d.sou.isNotEmpty) {
          final MapEntry<int, int> e = d.sou.first;
          b.write('ロード10kmで${d.kugiriFun}分を切った選手は、${daigakuMei(k.univ[e.key])}が${e.value}人をそろえた。');
        }
    }
    return b.toString();
  }

  // ---- 2本目の段落(記録がある限り毎年全部入れる) ----

  void kantenDan(_Kanten kn) {
    switch (kn) {
      case _Kanten.zenshu:
        zenshuDan();
      case _Kanten.nobi:
        nobiDan();
      case _Kanten.ichinen:
        ichinenDan();
      case _Kanten.sou:
        souDan();
    }
  }

  /// 4種目そろって好タイムの段落
  void zenshuDan() {
    final ({SenshuData s, int warui})? z = d.zenshu;
    if (z == null) return;
    final SenshuData s = z.s;
    final List<String> t = [
      for (final int race in _nittei) '${_mei(race)}${jikanMoji(d.t(s, race))}',
    ];
    w.koMidashi('4種目そろって');
    final String ys = yobu(s); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    w.danraku(w.erabu([
      '4種目そろって好タイムを並べたのが、$ysだ。${t.join('、')}と、どの種目でも上位に顔を出した。',
      '$ysは、${t.join('、')}。どの種目でも好タイムを並べた。',
    ]));
    kotoba(s, _ttKotoba);
  }

  /// 昨夏からの伸びの段落
  void nobiDan() {
    if (d.nobi.isEmpty) return;
    final StringBuffer b = StringBuffer();
    final ({SenshuData s, int race, int sa}) n = d.nobi.first;
    w.koMidashi('昨夏からの伸び');
    final String ys = yobu(n.s); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    b.write(w.erabu([
      '昨夏からの伸びが目立ったのは$ys。${_mei(n.race)}は${jikanMoji(d.t(n.s, n.race))}で、昨夏から${saMoji(n.sa)}縮めた。',
      '$ysは${_mei(n.race)}で${jikanMoji(d.t(n.s, n.race))}。昨夏の記録から${saMoji(n.sa)}縮め、大きく成長した姿を見せた。',
    ]));
    if (d.nobi.length >= 2) {
      final ({SenshuData s, int race, int sa}) n2 = d.nobi[1];
      b.write('${yobu(n2.s)}も${_mei(n2.race)}で昨夏から${saMoji(n2.sa)}縮めた。');
    }
    w.danraku(b.toString());
    kotoba(n.s, _nobiKotoba);
  }

  /// 1年生の段落
  void ichinenDan() {
    final SenshuData? s = d.ichinen;
    if (s == null) return;
    final StringBuffer b = StringBuffer();
    w.koMidashi('1年生');
    final String ys = yobu(s); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    b.write(w.erabu([
      '1年生では、$ysがロード10kmで${jikanMoji(d.t(s, _road))}をマークした。',
      '初めての夏を迎えた1年生の中で、ロード10kmの$ysの${jikanMoji(d.t(s, _road))}が光った。',
    ]));
    // 入学時の持ちタイムが世代トップだった1年生(期待のルーキーで取り上げた選手)の今夏
    final SenshuData? top = d.sedaiTop;
    if (top != null && top.id != s.id) {
      final double? t = _ttTime(top, _road);
      if (t != null) {
        b.write('入学時の持ちタイムが世代トップだった${yobu(top)}は、ロード10kmで${jikanMoji(t)}だった。');
      }
    } else if (top != null && top.id == s.id) {
      b.write('入学時の持ちタイムが世代トップだった選手が、大学の夏でも好タイムを出した。');
    }
    w.danraku(b.toString());
    kotoba(s, _ichinenKotoba);
  }

  /// 大学ごとの層の段落(ロード10kmを中心に、登り・下り・クロカンも1文ずつ。区切りは種目ごとに決める)
  void souDan() {
    if (d.sou.isEmpty) return;
    final StringBuffer b = StringBuffer();
    final MapEntry<int, int> e = d.sou.first;
    final String u = daigakuMei(k.univ[e.key]);
    w.koMidashi('大学ごとの層');
    b.write(w.erabu([
      'ロード10kmで${d.kugiriFun}分を切った選手を、$uは${e.value}人そろえた。',
      'ロード10kmの${d.kugiriFun}分切りは、$uが${e.value}人。チームとしての層の厚さを見せた。',
    ]));
    if (d.sou.length >= 2 && d.sou[1].value >= 3) {
      b.write('${daigakuMei(k.univ[d.sou[1].key])}も${d.sou[1].value}人が続いた。');
    }
    b.write('${d.kugiriFun}分を切った選手がいた大学は、${d.sou.length}校だった。');
    // 登り・下り・クロカン(区切りはその種目のタイムから決める)
    for (final int race in const [_nobori, _kudari, _kurokan]) {
      final List<MapEntry<int, int>> so = d.souOf(race);
      if (so.isEmpty || so.first.value < 2) continue;
      final String un = daigakuMei(k.univ[so.first.key]);
      final String mei = '${_mei(race)}の${d.kugiri(race)}分切り';
      final String soeru = switch (race) {
        _nobori => '山登りの区間の候補を多く抱える。',
        _kudari => '山下りの区間の候補も厚い。',
        _ => 'アップダウンの区間に向けた駒もそろう。',
      };
      b.write(w.erabu(['$meiは、$unが${so.first.value}人。$soeru', '$meiでは、$unの${so.first.value}人が目を引く。']));
    }
    w.danraku(b.toString());
  }

  /// 自分の大学の段落
  void jibunDan() {
    final UnivData? u = k.jibunUniv;
    if (u == null) return;
    SenshuData? best;
    for (final SenshuData s in d.l(_road)) {
      if (s.univid == u.id) {
        best = s;
        break;
      }
    }
    if (best == null) return;
    final int kugiri = d.sou.where((e) => e.key == u.id).fold<int>(0, (a, e) => a + e.value);
    final StringBuffer b = StringBuffer();
    w.koMidashi(daigakuMei(u));
    final String yb = yobu(best); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    b.write(w.erabu([
      '${daigakuMei(u)}は、ロード10kmで$ybの${jikanMoji(d.t(best, _road))}がチームの先頭だった。',
      '${daigakuMei(u)}のロード10kmは、$ybが${jikanMoji(d.t(best, _road))}でチームを引っ張った。',
    ]));
    b.write(kugiri > 0 ? '${d.kugiriFun}分を切った選手は$kugiri人。' : '${d.kugiriFun}分を切った選手は出なかった。');
    // 登り・下り・クロカンの区切りを切った人数(いた種目だけ)
    final List<String> hoka = [
      for (final int race in const [_nobori, _kudari, _kurokan])
        if (d.kugiriKazu(race, u.id) > 0) '${_mei(race)}の${d.kugiri(race)}分切りは${d.kugiriKazu(race, u.id)}人',
    ];
    if (hoka.isNotEmpty) b.write('${hoka.join('、')}。');
    w.danraku(b.toString());
  }

  /// 2本目の記者の目
  void kantenKishaNoMe(KishaKata kata) {
    switch (kata) {
      case KishaKata.suuji:
        w.kishaNoMe(
          '${d.kugiriFun}分切り${d.kugiriNinzuu}人の分布は、そのまま秋の勢力図の下書きになる。ただし、下書きは書き換えられるものだ。',
        );
      case KishaKata.joukei:
        w.kishaNoMe(w.erabu([
          '昨夏の自分を超えた選手がいて、初めての夏を走り抜いた1年生がいる。秋のたすきは、この夏の続きだ。',
          'チームの層は、一人ひとりの夏の積み重ねでできている。秋の駅伝で、その厚みが試される。',
        ]));
      case KishaKata.karakuchi:
        w.kishaNoMe(
          '層の厚さは夏に決まり、秋に問われる。好タイムの選手が数人いても、駅伝はそれだけでは戦えない。',
        );
    }
  }

  /// 大学ごとの層の表(種目ごとに、その年の区切りの分を切った人数。ロードの人数の多い順)
  KijiHyou? souHyou() {
    final Set<int> univ = {
      for (final int race in _shumoku)
        for (final MapEntry<int, int> e in d.souOf(race)) e.key,
    };
    if (univ.isEmpty) return null;
    final List<int> jun = univ.toList()
      ..sort((a, b) {
        for (final int race in _shumoku) {
          final int c = d.kugiriKazu(race, b).compareTo(d.kugiriKazu(race, a));
          if (c != 0) return c;
        }
        return a.compareTo(b);
      });
    return KijiHyou(
      '大学ごとの層(種目ごとに、その分を切った人数)',
      ['大学', for (final int race in _shumoku) '${_mei(race)}(${d.kugiri(race)}分切り)'],
      [
        for (final int u in jun)
          [
            daigakuMei(k.univ[u]),
            for (final int race in _shumoku) '${d.kugiriKazu(race, u)}',
          ],
      ],
    );
  }
}

/// 箱庭スポーツの「夏のTT特集」(種目編)と「夏のTTを読み解く」(観点編)(8月25日。今夏のTTの記録がなければ空)
List<Kiji> ttKiji(KijiKankyou k) {
  final _TtShiryou d = _TtShiryou(k);
  if (d.l(_road).isEmpty) return [];
  final int nendo = k.gh.month >= 4 ? k.gh.year : k.gh.year - 1;
  return [
    _shumokuKiji(k, d, nendo),
    ..._kantenKiji(k, d, nendo),
  ];
}

/// 1本目「夏のTT特集」(種目編。4種目の段落を毎年必ず入れる)
Kiji _shumokuKiji(KijiKankyou k, _TtShiryou d, int nendo) {
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _no));
  final KishaKata kata = k.kishaKata(_no);
  final _Tt r = _Tt(d, w);

  // 見出しの種目(点に少しだけ乱数を足す。前の年と同じ種目なら、2番目の種目にする)
  final List<({int g, int ten})> kouho = [
    for (final int g in const [_gRoad, _gKurokan, _gNobori, _gKudari])
      if (r.shumokuTen(_gRace(g)) > 0) (g: g, ten: r.shumokuTen(_gRace(g)) + w.r.ikutsu(10)),
  ]..sort((a, b) => b.ten.compareTo(a.ten));
  final int? mae = KijiMidashiKiroku.maeNoKata(k, ttMidashiIndex, nendo);
  int g = kouho.isEmpty ? _gRoad : kouho.first.g;
  if (g == mae && kouho.length >= 2) g = kouho[1].g;
  KijiMidashiKiroku.nokosu(k, ttMidashiIndex, nendo, mae, g);
  final int atama = _gRace(g);

  final String midashi = r.shumokuMidashi(atama);
  final String lead = r.shumokuLead(atama, kata);
  // 見出しの種目を先頭に、残りは日程の順
  for (final int race in [atama, ..._nittei.where((x) => x != atama)]) {
    r.shumokuDan(race, midashi: race == atama);
  }
  r.shumokuKishaNoMe(kata);
  return Kiji(
    category: kijiTtCategory,
    midashi: midashi,
    lead: lead,
    honbun: w.honbun,
    hyou: [
      for (final int race in _shumoku)
        if (r.hyou(race) != null) r.hyou(race)!,
    ],
    haishin: k.haishinMei(_no, asa: false),
    kisha: k.kishaMei(_no),
    jibun: r.midashiUnivId != null && r.midashiUnivId == k.gh.MYunivid,
    kekka: true,
  );
}

/// 2本目「夏のTTを読み解く」(観点編。記録がある限り、観点を毎年全部入れる。書けることがなければ空)
List<Kiji> _kantenKiji(KijiKankyou k, _TtShiryou d, int nendo) {
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _noKanten));
  final KishaKata kata = k.kishaKata(_noKanten);
  final _Tt r = _Tt(d, w);
  final Map<_Kanten, int> ten = {
    if (r.zenshuTen > 0) _Kanten.zenshu: r.zenshuTen,
    if (r.nobiTen > 0) _Kanten.nobi: r.nobiTen,
    if (r.ichinenTen > 0) _Kanten.ichinen: r.ichinenTen,
    if (r.souTen > 0) _Kanten.sou: r.souTen,
  };
  if (ten.isEmpty) return [];
  int gOf(_Kanten kn) => switch (kn) {
    _Kanten.zenshu => _gZenshu,
    _Kanten.nobi => _gNobi,
    _Kanten.ichinen => _gIchinen,
    _Kanten.sou => _gSou,
  };
  // 見出しの観点(点に少しだけ乱数を足す。前の年と同じ観点なら、2番目の観点にする)
  final Map<_Kanten, int> jun = {for (final MapEntry<_Kanten, int> e in ten.entries) e.key: e.value + w.r.ikutsu(10)};
  final List<_Kanten> narabi = ten.keys.toList()..sort((a, b) => jun[b]!.compareTo(jun[a]!));
  final int? mae = KijiMidashiKiroku.maeNoKata(k, ttKantenMidashiIndex, nendo);
  _Kanten atama = narabi.first;
  if (gOf(atama) == mae && narabi.length >= 2) atama = narabi[1];
  KijiMidashiKiroku.nokosu(k, ttKantenMidashiIndex, nendo, mae, gOf(atama));

  final String midashi = r.kantenMidashi(gOf(atama));
  final String lead = r.kantenLead(gOf(atama), kata);
  for (final _Kanten kn in [atama, ...narabi.where((x) => x != atama)]) {
    r.kantenDan(kn);
  }
  r.jibunDan();
  r.kantenKishaNoMe(kata);
  final KijiHyou? souHyou = r.souHyou();
  return [
    Kiji(
      category: kijiTtCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [if (souHyou != null) souHyou],
      haishin: k.haishinMei(_noKanten, asa: false),
      kisha: k.kishaMei(_noKanten),
      jibun: r.midashiUnivId != null && r.midashiUnivId == k.gh.MYunivid,
      kekka: true,
    ),
  ];
}

// ------------------------------------------------------------
// 学内メディア「学内TT特集」
// ・種目ごとに学内の上位3人(結果画面に出ている学内順位なので「学内1位」と書く)
// ・昨夏から一番縮めた部員、1年生で一番の部員
// ------------------------------------------------------------

/// 学内メディアの「学内TT特集」(8月25日。自分の大学に今夏のTTの記録がなければ空)
List<Kiji> ttGakunaiKiji(KijiKankyou k) {
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null) return [];
  final _TtShiryou d = _TtShiryou(k);
  List<SenshuData> buin(int race) => [
    for (final SenshuData s in d.l(race))
      if (s.univid == u.id) s,
  ];
  if (buin(_road).isEmpty) return [];
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _noGakunai));
  final String kisha = gakunaiKishaMei(k, site, _noGakunai);
  final KishaKata kata0 = kishaKataKara(kisha);
  final KishaKata kata = kata0 == KishaKata.karakuchi ? KishaKata.joukei : kata0;
  final SenshuData top = buin(_road).first;

  final String midashi = w.erabu([
    '夏のTT特集　ロード10kmの学内トップは${fullMei(top.name)}',
    '学内タイムトライアル特集　夏の成果を振り返る',
    '夏の4種目を終えて　学内TT特集',
  ]);
  final StringBuffer lead = StringBuffer();
  lead.write(w.erabu([
    '夏のタイムトライアルが、8月25日のロード10kmで締めくくられた。',
    '7月25日のクロカン10kmから始まった夏のタイムトライアルが、ロード10kmで幕を閉じた。',
  ]));
  lead.write('ロード10kmの学内1位は${fullMei(top.name)}(${top.gakunen}年)で${jikanMoji(d.t(top, _road))}。');
  lead.write('4種目の結果を振り返る。');

  // 種目ごとの学内の上位3人
  for (final int race in _shumoku) {
    final List<SenshuData> l = buin(race);
    if (l.isEmpty) continue;
    w.koMidashi(_mei(race));
    final StringBuffer b = StringBuffer();
    final List<String> joui = [
      for (int i = 0; i < l.length && i < 3; i++) '学内${i + 1}位は${w.senshu(l[i])}で${jikanMoji(d.t(l[i], race))}',
    ];
    b.write('${joui.join('、')}。');
    if (race == _kurokan) {
      final String ku = d.kukanMoji(KukanTokuchou.updown);
      b.write(
        ku.isNotEmpty
            ? '登りと下りが絶え間なく続く過酷なコース。アップダウンの続く区間($ku)の候補選びにもつながる。'
            : '登りと下りが絶え間なく続く、4種目で一番過酷なコースだ。',
      );
    } else if (race == _nobori) {
      final String ku = d.kukanMoji(KukanTokuchou.yamaNobori);
      if (ku.isNotEmpty) b.write('山登りの区間($ku)を占う種目だ。');
    } else if (race == _kudari) {
      final String ku = d.kukanMoji(KukanTokuchou.yamaKudari);
      if (ku.isNotEmpty) b.write('山下りの区間($ku)を占う種目だ。');
    }
    // その種目の区切り(全大学のタイムから決めた分)を切った部員の人数
    final int kugiri = l.where((s) => d.t(s, race) < d.kugiri(race) * 60).length;
    if (kugiri > 0) b.write('${d.kugiri(race)}分を切った部員は$kugiri人。');
    w.danraku(b.toString());
  }

  // 昨夏から一番縮めた部員
  ({SenshuData s, int race, int sa})? nobi;
  for (final SenshuData s in k.senshu) {
    if (s.univid != u.id || s.gakunen < 2 || s.gakunen > 4) continue;
    for (final int race in _shumoku) {
      final double? kon = _ttTime(s, race);
      final double? mae = _ttTime(s, race, maeNen: 1);
      if (kon == null || mae == null) continue;
      final int sa = saByou(mae, kon);
      if (sa >= 10 && (nobi == null || sa > nobi.sa)) nobi = (s: s, race: race, sa: sa);
    }
  }
  final ({SenshuData s, int race, int sa})? nb = nobi;
  if (nb != null) {
    w.koMidashi('昨夏からの伸び');
    final String ys = w.senshu(nb.s); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    w.danraku(w.erabu([
      '昨夏から一番伸びたのは$ys。${_mei(nb.race)}で昨夏から${saMoji(nb.sa)}縮めた。',
      '$ysは${_mei(nb.race)}で、昨夏の記録から${saMoji(nb.sa)}縮めた。1年間の積み重ねが、タイムに表れた。',
    ]));
    w.comment('「${w.erabu(_nobiKotoba)}」と${myouji(nb.s.name)}は${w.erabu(_senshuShime)}。');
  }
  // 1年生で一番の部員(ロード10km)
  SenshuData? ichi;
  for (final SenshuData s in buin(_road)) {
    if (s.gakunen == 1) {
      ichi = s;
      break;
    }
  }
  final SenshuData? ic = ichi;
  if (ic != null) {
    final int jj = buin(_road).indexWhere((x) => x.id == ic.id) + 1;
    w.koMidashi('1年生');
    final String yi = w.senshu(ic); // 名前は候補を並べる前に1度だけ作る(2.0.2)
    w.danraku(w.erabu([
      '1年生では、$yiがロード10kmで${jikanMoji(d.t(ic, _road))}。学内$jj位に入った。',
      '初めての夏を迎えた1年生の中では、$yiのロード10km${jikanMoji(d.t(ic, _road))}(学内$jj位)が光った。',
    ]));
    w.comment('「${w.erabu(_ichinenKotoba)}」と${myouji(ic.name)}は${w.erabu(_senshuShime)}。');
  }
  // 監督の言葉(自分の大学の監督。総監督の言葉は作らない)
  final ({String name, int nenrei})? kt = k.kantokuMei(u.id);
  if (kt != null) {
    w.comment('「${w.erabu(_jibunKantokuKotoba)}」と${w.hito('K${u.id}', kt.name, '', '')}監督(${kt.nenrei})は${w.erabu(_kantokuShime)}。');
  }
  // 編集部の目
  if (kata == KishaKata.suuji) {
    final int nin = buin(_road).length;
    w.kishaNoMe(
      'ロード10kmを走った部員は$nin人。夏のタイムは、秋の駅伝メンバー争いの大事な材料になる。',
      midashi: '編集部の目',
    );
  } else {
    w.kishaNoMe(
      w.erabu([
        '夏の間、グラウンドにも坂道にも、部員たちの足音が響き続けた。その成果が、秋のたすきにつながる。',
        '暑い夏を走り抜いた部員たちに、まずは拍手を送りたい。秋の駅伝シーズンは、もうすぐだ。',
      ]),
      midashi: '編集部の目',
    );
  }

  // 表(部員の4種目。ロード10kmの順)
  final List<SenshuData> roadJun = buin(_road);
  return [
    Kiji(
      category: kijiTtGakunaiCategory,
      midashi: midashi,
      lead: lead.toString(),
      honbun: w.honbun,
      hyou: [
        KijiHyou(
          '部員の夏のTT(ロード10kmの順)',
          ['選手', '学年', for (final int race in _shumoku) _mei(race)],
          [
            for (final SenshuData s in roadJun)
              [
                fullMei(s.name),
                '${s.gakunen}年',
                for (final int race in _shumoku)
                  _ttTime(s, race) == null ? '－' : jikanMoji(_ttTime(s, race)!),
              ],
          ],
        ),
      ],
      haishin: k.haishinMei(_noGakunai, asa: false),
      kisha: kisha,
      jibun: true,
      kekka: true,
      site: site,
      gakunai: true,
    ),
  ];
}
