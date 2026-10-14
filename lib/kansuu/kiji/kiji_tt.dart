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
// 箱庭スポーツの観点(点を付けて見出しと段落の順を決める。新入生の記事と同じ作り方)
//  ・ロード10km(駅伝に一番近い。毎年入れる)
//  ・クロカン10km(起伏が激しく、アップダウンの続く区間に関係する。毎年入れる。区間はコースのデータから探す)
//  ・坂(登り10km・下り10km。山の区間の候補)
//  ・4種目そろって好タイムの選手、昨夏からの伸び、1年生、大学ごとの層(○分を切った人数)、自分の大学
// ・前の年と同じ型の見出しは避ける(KantokuData.yobiint3[78]。kiji_kihon.dart の KijiMidashiKiroku)
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

/// 前の年の見出しの型を残す場所(KantokuData.yobiint3の番号。KijiMidashiKiroku)
const int ttMidashiIndex = 78;

/// 記事の番号(乱数と記者の名前に使う)
const int _no = 193;
const int _noGakunai = 194;

/// TTの種目(レースの番号)。紹介する順(ロード・クロカン・登り・下り)
const int _road = 15;
const int _kurokan = 16;
const int _nobori = 13;
const int _kudari = 14;
const List<int> _shumoku = [_road, _kurokan, _nobori, _kudari];

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

  /// 層を数えるタイムの区切り(分。ロード10kmで、この分を切った選手が20人以上になる一番小さい分)
  late final int kugiriFun = _kugiriTsukuru();

  int _kugiriTsukuru() {
    final List<SenshuData> r = l(_road);
    if (r.isEmpty) return 30;
    int m = t(r.first, _road) ~/ 60 + 1;
    while (m < 40 && r.where((s) => t(s, _road) < m * 60).length < 20) {
      m++;
    }
    return m;
  }

  /// ロード10kmで区切りを切った人数(大学ごと。多い順)
  late final List<MapEntry<int, int>> sou = _souTsukuru();

  List<MapEntry<int, int>> _souTsukuru() {
    final Map<int, int> m = {};
    for (final SenshuData s in l(_road)) {
      if (t(s, _road) >= kugiriFun * 60) break;
      m[s.univid] = (m[s.univid] ?? 0) + 1;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// 区切りを切った人数(全体)
  int get kugiriNinzuu => sou.fold<int>(0, (a, e) => a + e.value);

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

const List<String> _sakaKotoba = [
  '坂は苦しいけれど、走っていて楽しい',
  '坂のある区間を任されたら、しっかり走りたい',
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
// 箱庭スポーツ「夏のTT特集」
// ------------------------------------------------------------

/// 見出しの型(前の年と同じ型を避けるために番号で残すので、番号を変えない)
const int _gRoad = 1;
const int _gKurokan = 2;
const int _gSaka = 3;
const int _gZenshu = 4;
const int _gNobi = 5;
const int _gIchinen = 6;
const int _gSou = 7;

/// 段落の種類
enum _Dan { road, kurokan, saka, zenshu, nobi, ichinen, sou }

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

  // ---- 点 ----

  /// 坂の段落で取り上げる選手(登り・下りそれぞれで一番タイムの良い選手)
  SenshuData? get noboriTop => d.l(_nobori).isEmpty ? null : d.l(_nobori).first;
  SenshuData? get kudariTop => d.l(_kudari).isEmpty ? null : d.l(_kudari).first;

  /// 坂で目立ち、ロードでは目立たなかった選手(登りか下りが5番目以内で、ロードが30番目より後ろ。いなければnull)
  SenshuData? get sakaTokui {
    for (final int race in const [_nobori, _kudari]) {
      for (final SenshuData s in d.l(race).take(5)) {
        if (d.j(s, _road) >= 30) return s;
      }
    }
    return null;
  }

  /// クロカンで目立ち、ロードでは目立たなかった選手(クロカンが10番目以内で、ロードが30番目より後ろ。いなければnull)
  SenshuData? get kurokanTokui {
    for (final SenshuData s in d.l(_kurokan).take(10)) {
      if (d.j(s, _road) >= 30) return s;
    }
    return null;
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
    if (d.sou.isEmpty || d.sou.first.value < 3) return 0;
    return d.sou.first.value >= 6 ? 60 : 50;
  }

  int get sakaTen => (noboriTop == null && kudariTop == null) ? 0 : (sakaTokui != null ? 65 : 55);

  /// 見出しの型[g]で、最初に置く段落
  _Dan atamaDan(int g) {
    switch (g) {
      case _gKurokan:
        return _Dan.kurokan;
      case _gSaka:
        return _Dan.saka;
      case _gZenshu:
        return _Dan.zenshu;
      case _gNobi:
        return _Dan.nobi;
      case _gIchinen:
        return _Dan.ichinen;
      case _gSou:
        return _Dan.sou;
      default:
        return _Dan.road;
    }
  }

  // ---- 見出し・リード ----

  String midashiMoji(int g) {
    String mei(SenshuData s) => fullMei(s.name);
    switch (g) {
      case _gKurokan:
        {
          final SenshuData? s = d.l(_kurokan).isEmpty ? null : d.l(_kurokan).first;
          if (s == null) return midashiMoji(_gRoad);
          midashiUnivId = s.univid;
          final String t = jikanMoji(d.t(s, _kurokan));
          return w.erabu([
            '起伏の難コースで$t　クロカン10kmは${mei(s)}(${d.univMei(s)})',
            'クロカン10kmで光った${mei(s)}　アップダウンの区間の候補に',
            '${d.univMei(s)}の${mei(s)}、クロカン10kmで$t',
          ]);
        }
      case _gSaka:
        {
          final SenshuData? s = sakaTokui ?? noboriTop ?? kudariTop;
          if (s == null) return midashiMoji(_gRoad);
          midashiUnivId = s.univid;
          final int race = d.j(s, _nobori) <= d.j(s, _kudari) ? _nobori : _kudari;
          return w.erabu([
            '山の候補が見えた　${_mei(race)}は${mei(s)}(${d.univMei(s)})',
            '${_mei(race)}で${jikanMoji(d.t(s, race))}　${d.univMei(s)}の${mei(s)}に山の期待',
          ]);
        }
      case _gZenshu:
        {
          final ({SenshuData s, int warui})? z = d.zenshu;
          if (z == null) return midashiMoji(_gRoad);
          midashiUnivId = z.s.univid;
          return w.erabu([
            '4種目そろって好タイム　${d.univMei(z.s)}の${mei(z.s)}',
            '${mei(z.s)}(${d.univMei(z.s)})、夏のTTは4種目すべてで好タイム',
          ]);
        }
      case _gNobi:
        {
          if (d.nobi.isEmpty) return midashiMoji(_gRoad);
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
          if (s == null) return midashiMoji(_gRoad);
          midashiUnivId = s.univid;
          return w.erabu([
            '1年生の${mei(s)}がロード10kmで${jikanMoji(d.t(s, _road))}　${d.univMei(s)}に新星',
            '上級生に交じって好タイム　${d.univMei(s)}の1年生${mei(s)}',
          ]);
        }
      case _gSou:
        {
          if (d.sou.isEmpty) return midashiMoji(_gRoad);
          final MapEntry<int, int> e = d.sou.first;
          midashiUnivId = e.key;
          final String u = daigakuMei(k.univ[e.key]);
          return w.erabu([
            '${d.kugiriFun}分切り${e.value}人　$uが層の厚さ',
            '$u、ロード10kmで${d.kugiriFun}分切り${e.value}人',
          ]);
        }
      default:
        {
          final SenshuData? s = d.l(_road).isEmpty ? null : d.l(_road).first;
          if (s == null) return '夏のタイムトライアル特集';
          midashiUnivId = s.univid;
          final String t = jikanMoji(d.t(s, _road));
          return w.erabu([
            'ロード10kmで$t　${mei(s)}(${d.univMei(s)})が好タイム',
            '夏の仕上がりはロードに表れた　${d.univMei(s)}の${mei(s)}、$t',
            '${d.univMei(s)}・${mei(s)}、ロード10kmで$t',
          ]);
        }
    }
  }

  /// リード(記者の型の書き出し・断り書き・見出しの事実)
  String leadMoji(int g, KishaKata kata) {
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
    b.write(_leadJijitsu(g));
    return b.toString();
  }

  String _leadJijitsu(int g) {
    switch (g) {
      case _gKurokan:
        {
          final SenshuData? s = d.l(_kurokan).isEmpty ? null : d.l(_kurokan).first;
          if (s == null) return _leadJijitsu(_gRoad);
          return '起伏の激しいクロカン10kmでは、${yobu(s)}が${jikanMoji(d.t(s, _kurokan))}をマークした。';
        }
      case _gSaka:
        {
          final SenshuData? s = sakaTokui ?? noboriTop ?? kudariTop;
          if (s == null) return _leadJijitsu(_gRoad);
          final int race = d.j(s, _nobori) <= d.j(s, _kudari) ? _nobori : _kudari;
          return '${_mei(race)}では${yobu(s)}が${jikanMoji(d.t(s, race))}をマークし、山の区間の候補に名乗りを上げた。';
        }
      case _gZenshu:
        {
          final ({SenshuData s, int warui})? z = d.zenshu;
          if (z == null) return _leadJijitsu(_gRoad);
          return '${yobu(z.s)}は、4種目すべてで好タイムを並べた。';
        }
      case _gNobi:
        {
          if (d.nobi.isEmpty) return _leadJijitsu(_gRoad);
          final ({SenshuData s, int race, int sa}) n = d.nobi.first;
          return '${yobu(n.s)}は${_mei(n.race)}で、昨夏から${saMoji(n.sa)}縮めた。';
        }
      case _gIchinen:
        {
          final SenshuData? s = d.ichinen;
          if (s == null) return _leadJijitsu(_gRoad);
          return '1年生の${yobu(s)}は、ロード10kmで${jikanMoji(d.t(s, _road))}をマークし、上級生に交じって存在感を示した。';
        }
      case _gSou:
        {
          if (d.sou.isEmpty) return _leadJijitsu(_gRoad);
          final MapEntry<int, int> e = d.sou.first;
          return 'ロード10kmで${d.kugiriFun}分を切った選手は、${daigakuMei(k.univ[e.key])}が${e.value}人をそろえた。';
        }
      default:
        {
          final SenshuData? s = d.l(_road).isEmpty ? null : d.l(_road).first;
          if (s == null) return '';
          return '駅伝に一番近いロード10kmでは、${yobu(s)}の${jikanMoji(d.t(s, _road))}が目を引いた。';
        }
    }
  }

  // ---- 段落 ----

  void dan(_Dan dn) {
    switch (dn) {
      case _Dan.road:
        roadDan();
      case _Dan.kurokan:
        kurokanDan();
      case _Dan.saka:
        sakaDan();
      case _Dan.zenshu:
        zenshuDan();
      case _Dan.nobi:
        nobiDan();
      case _Dan.ichinen:
        ichinenDan();
      case _Dan.sou:
        souDan();
    }
  }

  /// 好タイムの選手を並べる文(「山田太郎(…)が28分31秒、…が28分40秒」。[nin]人まで。[nozoku]の選手は除く)
  String _narabe(int race, int nin, {Set<int> nozoku = const {}}) {
    final List<String> l = [];
    for (final SenshuData s in d.l(race)) {
      if (nozoku.contains(s.id)) continue;
      l.add('${yobu(s)}が${jikanMoji(d.t(s, race))}');
      if (l.length >= nin) break;
    }
    return l.join('、');
  }

  /// ロード10kmの段落(毎年入れる)
  void roadDan() {
    final List<SenshuData> l = d.l(_road);
    if (l.isEmpty) return;
    final SenshuData s = l.first;
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '駅伝に一番近いロード10kmで目を引いたのは、${yobu(s)}の${jikanMoji(d.t(s, _road))}だ。',
      'ロード10kmは、${yobu(s)}が${jikanMoji(d.t(s, _road))}の好タイムを出した。',
    ]));
    final String hoka = _narabe(_road, 3, nozoku: {s.id});
    if (hoka.isNotEmpty) b.write('ほかにも$hokaと、好タイムが続いた。');
    // 留学生が並んだときは、日本人の好タイムも書く
    final SenshuData? nj = d.nihonjin(_road);
    if (s.hirou == 1 && nj != null && d.j(nj, _road) >= 4) {
      b.write('日本人では、${yobu(nj)}の${jikanMoji(d.t(nj, _road))}が光った。');
    }
    if (d.kugiriNinzuu > 0) b.write('${d.kugiriFun}分を切った選手は、全体で${d.kugiriNinzuu}人だった。');
    w.danraku(b.toString());
    kotoba(s, _ttKotoba);
    if (w.r.kakuritsu(50)) kantoku(s);
  }

  /// クロカン10kmの段落(毎年入れる。起伏が激しく、アップダウンの続く区間に関係する)
  void kurokanDan() {
    final List<SenshuData> l = d.l(_kurokan);
    if (l.isEmpty) return;
    final SenshuData s = l.first;
    final StringBuffer b = StringBuffer();
    final String ku = d.kukanMoji(KukanTokuchou.updown);
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
    b.write(w.erabu([
      'ここで${yobu(s)}が${jikanMoji(d.t(s, _kurokan))}をマークした。',
      '目を引いたのは${yobu(s)}の${jikanMoji(d.t(s, _kurokan))}だ。',
    ]));
    final String hoka = _narabe(_kurokan, 2, nozoku: {s.id});
    if (hoka.isNotEmpty) b.write('$hokaと続いた。');
    final SenshuData? nj = d.nihonjin(_kurokan);
    if (s.hirou == 1 && nj != null && d.j(nj, _kurokan) >= 3) {
      b.write('日本人では、${yobu(nj)}の${jikanMoji(d.t(nj, _kurokan))}が光った。');
    }
    // ロードでは目立たなかったが、クロカンで光った選手
    final SenshuData? tk = kurokanTokui;
    if (tk != null) {
      b.write(
        'ロード10kmでは目立たなかった${yobu(tk)}も、クロカン10kmでは${jikanMoji(d.t(tk, _kurokan))}と好タイム。'
        '${ku.isNotEmpty ? 'アップダウンの区間で、名前が挙がりそうだ。' : '起伏のある区間で、名前が挙がりそうだ。'}',
      );
    }
    w.danraku(b.toString());
    kotoba(tk ?? s, _kurokanKotoba);
  }

  /// 坂(登り10km・下り10km)の段落
  void sakaDan() {
    final SenshuData? nb = noboriTop;
    final SenshuData? kd = kudariTop;
    if (nb == null && kd == null) return;
    final StringBuffer b = StringBuffer();
    final String yamaN = d.kukanMoji(KukanTokuchou.yamaNobori);
    final String yamaK = d.kukanMoji(KukanTokuchou.yamaKudari);
    if (nb != null) {
      b.write('登り10kmは${yobu(nb)}が${jikanMoji(d.t(nb, _nobori))}。');
      if (yamaN.isNotEmpty) b.write('山登りの区間($yamaN)の候補として注目される。');
    }
    if (kd != null) {
      b.write('下り10kmは${yobu(kd)}が${jikanMoji(d.t(kd, _kudari))}。');
      if (yamaK.isNotEmpty) b.write('山下りの区間($yamaK)の候補に名乗りを上げた。');
    }
    final SenshuData? tk = sakaTokui;
    if (tk != null && !identical(tk, nb) && !identical(tk, kd)) {
      final int race = d.j(tk, _nobori) <= d.j(tk, _kudari) ? _nobori : _kudari;
      b.write('ロード10kmでは目立たなかった${yobu(tk)}も、${_mei(race)}で${jikanMoji(d.t(tk, race))}をマークした。');
    }
    w.danraku(b.toString());
    final SenshuData? c = tk ?? nb ?? kd;
    if (c != null) kotoba(c, _sakaKotoba);
  }

  /// 4種目そろって好タイムの段落
  void zenshuDan() {
    final ({SenshuData s, int warui})? z = d.zenshu;
    if (z == null) return;
    final SenshuData s = z.s;
    final List<String> t = [
      for (final int race in _shumoku) '${_mei(race)}${jikanMoji(d.t(s, race))}',
    ];
    w.danraku(w.erabu([
      '4種目そろって好タイムを並べたのが、${yobu(s)}だ。${t.join('、')}と、どの種目でも上位に顔を出した。',
      '${yobu(s)}は、${t.join('、')}。どの種目でも好タイムを並べた。',
    ]));
    kotoba(s, _ttKotoba);
  }

  /// 昨夏からの伸びの段落
  void nobiDan() {
    if (d.nobi.isEmpty) return;
    final StringBuffer b = StringBuffer();
    final ({SenshuData s, int race, int sa}) n = d.nobi.first;
    b.write(w.erabu([
      '昨夏からの伸びが目立ったのは${yobu(n.s)}。${_mei(n.race)}は${jikanMoji(d.t(n.s, n.race))}で、昨夏から${saMoji(n.sa)}縮めた。',
      '${yobu(n.s)}は${_mei(n.race)}で${jikanMoji(d.t(n.s, n.race))}。昨夏の記録から${saMoji(n.sa)}縮め、大きく成長した姿を見せた。',
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
    b.write(w.erabu([
      '1年生では、${yobu(s)}がロード10kmで${jikanMoji(d.t(s, _road))}をマークした。',
      '初めての夏を迎えた1年生の中で、ロード10kmの${yobu(s)}の${jikanMoji(d.t(s, _road))}が光った。',
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

  /// 大学ごとの層の段落(ロード10kmで区切りの分を切った人数)
  void souDan() {
    if (d.sou.isEmpty) return;
    final StringBuffer b = StringBuffer();
    final MapEntry<int, int> e = d.sou.first;
    final String u = daigakuMei(k.univ[e.key]);
    b.write(w.erabu([
      '大学ごとの層の厚さも見えた。ロード10kmで${d.kugiriFun}分を切った選手を、$uは${e.value}人そろえた。',
      'ロード10kmの${d.kugiriFun}分切りは、$uが${e.value}人。チームとしての層の厚さを見せた。',
    ]));
    if (d.sou.length >= 2 && d.sou[1].value >= 3) {
      b.write('${daigakuMei(k.univ[d.sou[1].key])}も${d.sou[1].value}人が続いた。');
    }
    b.write('${d.kugiriFun}分を切った選手がいた大学は、${d.sou.length}校だった。');
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
    b.write(w.erabu([
      '${daigakuMei(u)}は、ロード10kmで${yobu(best)}の${jikanMoji(d.t(best, _road))}がチームの先頭だった。',
      '${daigakuMei(u)}のロード10kmは、${yobu(best)}が${jikanMoji(d.t(best, _road))}でチームを引っ張った。',
    ]));
    if (kugiri > 0) b.write('${d.kugiriFun}分を切った選手は$kugiri人。');
    w.danraku(b.toString());
  }

  /// 記者の目
  void kishaNoMe(KishaKata kata) {
    switch (kata) {
      case KishaKata.suuji:
        w.kishaNoMe(
          'ロード10kmの${d.kugiriFun}分切りは全体で${d.kugiriNinzuu}人。数字は夏の到達点にすぎない。'
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
}

/// 箱庭スポーツの「夏のTT特集」(8月25日。今夏のTTの記録がなければ空)
List<Kiji> ttKiji(KijiKankyou k) {
  final _TtShiryou d = _TtShiryou(k);
  if (d.l(_road).isEmpty) return [];
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _no));
  final KishaKata kata = k.kishaKata(_no);
  final _Tt r = _Tt(d, w);
  final int nendo = k.gh.month >= 4 ? k.gh.year : k.gh.year - 1;

  // 見出しの型の候補(点に少しだけ乱数を足す。ロードとクロカンはいつも候補)
  final List<({int g, int ten})> kouho = [];
  void ire(int g, int ten) {
    if (ten > 0) kouho.add((g: g, ten: ten + w.r.ikutsu(10)));
  }

  ire(_gRoad, 75);
  if (d.l(_kurokan).isNotEmpty) ire(_gKurokan, 70);
  ire(_gSaka, r.sakaTen);
  ire(_gZenshu, r.zenshuTen);
  ire(_gNobi, r.nobiTen);
  ire(_gIchinen, r.ichinenTen);
  ire(_gSou, r.souTen);
  kouho.sort((a, b) => b.ten.compareTo(a.ten));
  // 前の年と同じ型なら、2番目の観点を見出しにする
  final int? mae = KijiMidashiKiroku.maeNoKata(k, ttMidashiIndex, nendo);
  int g = kouho.first.g;
  if (g == mae && kouho.length >= 2) g = kouho[1].g;
  KijiMidashiKiroku.nokosu(k, ttMidashiIndex, nendo, mae, g);

  final String midashi = r.midashiMoji(g);
  final String lead = r.leadMoji(g, kata);

  // 段落の順(見出しの段落が先頭。ロードとクロカンはいつも入れる。ほかは点が50以上のものを、点に乱数を足した順に)
  final _Dan atama = r.atamaDan(g);
  final Map<_Dan, int> ten = {
    _Dan.road: 75,
    if (d.l(_kurokan).isNotEmpty) _Dan.kurokan: 70,
    if (r.sakaTen > 0) _Dan.saka: r.sakaTen,
    if (r.zenshuTen > 0) _Dan.zenshu: r.zenshuTen,
    if (r.nobiTen > 0) _Dan.nobi: r.nobiTen,
    if (r.ichinenTen > 0) _Dan.ichinen: r.ichinenTen,
    if (r.souTen > 0) _Dan.sou: r.souTen,
  };
  final Map<_Dan, int> jun = {for (final MapEntry<_Dan, int> e in ten.entries) e.key: e.value + w.r.ikutsu(20)};
  final List<_Dan> nokori = [
    for (final MapEntry<_Dan, int> e in ten.entries)
      if (e.key != atama) e.key,
  ]..sort((a, b) => jun[b]!.compareTo(jun[a]!));
  // 多すぎるときは、後ろ(点の低いもの)から外す(ロードとクロカンは残す)
  while (nokori.length > 5) {
    final int i = nokori.lastIndexWhere((x) => x != _Dan.road && x != _Dan.kurokan);
    if (i < 0) break;
    nokori.removeAt(i);
  }
  // ロードは2番目まで、クロカンは3番目までに入れる
  for (final ({_Dan dn, int saigo}) x in const [(dn: _Dan.road, saigo: 0), (dn: _Dan.kurokan, saigo: 1)]) {
    final int i = nokori.indexOf(x.dn);
    if (i > x.saigo) {
      nokori.removeAt(i);
      nokori.insert(x.saigo, x.dn);
    }
  }
  for (final _Dan dn in [atama, ...nokori]) {
    r.dan(dn);
  }
  r.jibunDan();
  r.kishaNoMe(kata);

  return [
    Kiji(
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
    } else {
      final int kugiri = l.where((s) => d.t(s, _road) < d.kugiriFun * 60).length;
      if (kugiri > 0) b.write('${d.kugiriFun}分を切った部員は$kugiri人。');
    }
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
    w.danraku(w.erabu([
      '昨夏から一番伸びたのは${w.senshu(nb.s)}。${_mei(nb.race)}で昨夏から${saMoji(nb.sa)}縮めた。',
      '${w.senshu(nb.s)}は${_mei(nb.race)}で、昨夏の記録から${saMoji(nb.sa)}縮めた。1年間の積み重ねが、タイムに表れた。',
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
    w.danraku(w.erabu([
      '1年生では、${w.senshu(ic)}がロード10kmで${jikanMoji(d.t(ic, _road))}。学内$jj位に入った。',
      '初めての夏を迎えた1年生の中では、${w.senshu(ic)}のロード10km${jikanMoji(d.t(ic, _road))}(学内$jj位)が光った。',
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
