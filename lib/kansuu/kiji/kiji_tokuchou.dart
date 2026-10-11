import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/konki_best.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// 選手の特徴の文(1.9.7)
// 持ちタイムと順位という見えている事実だけから、その選手がこれから走る区間に合うかを書く。
// 学内メディアの展望号の選手名鑑、学連選抜通信の展望号の選手名鑑、実況・速報の次の走者で使う
//
// 見る観点(説明書の仕様と同じ見方。能力値は見ない)
//  A 距離適性: 5000m・1万m・ハーフの全体順位(学生全体)を比べ、一番良い種目から
//    スピード型・長い距離向きなどと見て、区間の距離と合うかを書く
//  B 区間の型: 1万m(トラック)とロード1万の全体順位を比べる。トラックが良ければ1区向き
//    (ペース変動対応力が効き、ロード適性は効かない)、同じくらいなら2・3区向き(両方が効く)、
//    ロードが良ければ4区以降向き(ロード適性が効き、ペース変動対応力は効かない)
//  C 区間内順位の善戦・苦戦: 区間の距離と型に合った種目の、その区間を走る選手の中での順位
//    (15km以上の1区ならハーフと1万m、7.5km未満の後半区間なら5000mとロード1万、など)。
//    上位3分の1なら善戦、下位3分の1なら苦戦、間は言い切らない
//  D 坂とアップダウン: 登り・下りがきつい区間は登り1万・下り1万、アップダウンの多い区間は
//    クロカン1万の区間内順位。登り基調・下り基調の区間では、登り1万と下り1万の順位の比べも添える
//
// 持ちタイムは今季ベスト(ない種目は自己ベスト。コンピュータの大学の判断と同じ hikakuMochiTime)。
// 区間内順位は、区間エントリーが公開されたあとの場面だけ書く(kukannaiKoukai)。
// 夏の4種目の区間内順位は、その区間を走る全員に記録があるときだけ出す(区間配置確認と同じ決まり)
//
// 飽きさせない工夫: 観点ごとに言い回しを数通り持ち(同じ記事では重ねない)、選手ごとに入り方を
// 回し、文の数も書けることの多さで1〜3文に変える。記者の型で、数字で語る(順位をそのまま出す)か
// 情景で語る(上位・下位などの言葉にする)かを変える
// ------------------------------------------------------------

/// 区間内順位を書いてよい場面か(区間エントリーが公開されたあと。学連選抜編成(290)と
/// 区間エントリー(300)の画面では、ほかの大学の区間配置を伏せているので書かない)
bool kukannaiKoukai(Ghensuu gh) => const {280, 330, 340, 343, 350, 700}.contains(gh.mode);

/// レース[k.race]の区間[kk]を走る大学の選手(学連選抜は入らない)
List<SenshuData> kukanHashiru(KijiKankyou k, int kk) {
  return [
    for (final SenshuData x in k.senshu)
      if (x.gakunen >= 1 &&
          x.gakunen <= 4 &&
          k.entry(x) == kk &&
          x.univid >= 0 &&
          x.univid < k.univ.length &&
          k.shutsujou(k.univ[x.univid]))
        x,
  ];
}

/// 種目の数(time_bestkiroku の0〜7)
const int _shumokuSuu = 8;

/// 全選手の比較用持ちタイム(今季ベスト。なければ自己ベスト)と、学生全体の順位の表
/// (記事1本につき1回作って使い回す)
class MochiHyou {
  final Map<int, List<double>> _t = {};
  final List<List<double>> _zentai = List.generate(_shumokuSuu, (_) => <double>[]);

  MochiHyou(KijiKankyou k) {
    for (final SenshuData s in k.senshu) {
      if (s.gakunen < 1 || s.gakunen > 4) continue;
      final List<double> t = _yomu(s);
      _t[s.id] = t;
      for (int idx = 0; idx < _shumokuSuu; idx++) {
        if (t[idx] < TEISUU.DEFAULTTIME) _zentai[idx].add(t[idx]);
      }
    }
    for (final List<double> l in _zentai) {
      l.sort();
    }
  }

  static List<double> _yomu(SenshuData s) => [
    for (int idx = 0; idx < _shumokuSuu; idx++) hikakuMochiTime(s, idx),
  ];

  /// 選手[s]の比較用持ちタイム(種目ごと。なければ TEISUU.DEFAULTTIME)
  List<double> times(SenshuData s) => _t[s.id] ?? _yomu(s);

  /// 学連選抜の選手[g]の比較用持ちタイム
  static List<double> timesGakuren(Senshu_Gakuren_Data g) => [
    for (int idx = 0; idx < _shumokuSuu; idx++) hikakuMochiTimeGakuren(g, idx),
  ];

  /// 種目[idx]の記録を持つ選手の数(学生全体)
  int zentaiSuu(int idx) => _zentai[idx].length;

  /// タイム[t]の、学生全体の中での順位(1始まり。自分より速い人の数+1。記録がなければ0)
  int zentai(double t, int idx) {
    if (t >= TEISUU.DEFAULTTIME) return 0;
    final List<double> l = _zentai[idx];
    int lo = 0;
    int hi = l.length;
    while (lo < hi) {
      final int mid = (lo + hi) ~/ 2;
      if (l[mid] < t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo + 1;
  }

  /// タイム[t]の、区間を走る選手[hashiru]の中での順位(1始まり。自分より速い人の数+1。
  /// 自分が入っていても同じ順位になる。記録がなければ0。
  /// 夏の4種目(登り・下り・ロード・クロカン1万)は、全員に記録があるときだけ出す)
  int kukannai(double t, int idx, List<SenshuData> hashiru) {
    if (t >= TEISUU.DEFAULTTIME || hashiru.isEmpty) return 0;
    int mae = 0;
    for (final SenshuData x in hashiru) {
      final double xt = times(x)[idx];
      if (xt >= TEISUU.DEFAULTTIME) {
        if (idx >= 4) return 0;
        continue;
      }
      if (xt < t) mae++;
    }
    return mae + 1;
  }
}

/// 順位[r](1始まり)が[n]人の中でどの段か(0: 上位3分の1、1: 中ほど、2: 下位3分の1。人数が少なければ1)
int _dan(int r, int n) {
  if (r <= 0 || n < 3) return 1;
  if (r * 3 <= n) return 0;
  if (r * 3 > n * 2) return 2;
  return 1;
}

/// 種目の短い呼び方(文の中で使う)
const List<String> _shumoku = ['5000m', '1万m', 'ハーフ', 'フル', '登り1万', '下り1万', 'ロード1万', 'クロカン1万'];

/// 観点の文1つ
class _Kansatsu {
  /// 観点(0: 距離適性、1: 区間の型、2: 区間内順位、3: 坂)
  final int kanten;
  final String bun;

  const _Kansatsu(this.kanten, this.bun);
}

/// 選手の特徴の文を作る道具(記事1本につき1つ。入り方を選手ごとに回す)
class TokuchouKaki {
  final KijiKankyou k;
  final KijiKakite w;
  final MochiHyou hyou;

  /// 数字で語る記者か(順位をそのまま出す。falseなら上位・下位などの言葉にする)
  final bool suuji;

  /// です・ますで書くか(実況の中で使うとき。記事は常体)
  final bool teinei;

  /// 何人目か(入り方を回す。[hajime] 速報のように区間ごとに作るときは、区間の番号を渡して入り方をずらす)
  int _ban;

  TokuchouKaki(this.k, this.w, this.hyou, {required this.suuji, this.teinei = false, int hajime = 0}) : _ban = hajime;

  /// 常体の文を、です・ますに直す(この道具が作る文の文末だけを見る)
  static String _teineiNi(String bun) {
    const List<(String, String)> okikae = [
      ('かもしれない。', 'かもしれません。'),
      ('ない。', 'ありません。'),
      ('ます。', 'ます。'),
      ('です。', 'です。'),
      ('だ。', 'です。'),
      ('ある。', 'あります。'),
      ('いる。', 'います。'),
      ('なる。', 'なります。'),
      ('わる。', 'わります。'),
      ('める。', 'めます。'),
      ('ける。', 'けます。'),
      ('せる。', 'せます。'),
      ('れる。', 'れます。'),
      ('える。', 'えます。'),
      ('きる。', 'きます。'),
      ('する。', 'します。'),
      ('う。', 'います。'),
      ('く。', 'きます。'),
      ('い。', 'いです。'),
    ];
    final StringBuffer sb = StringBuffer();
    for (final String b in bun.split('。')) {
      if (b.isEmpty) continue;
      final String moto = '$b。';
      String? naoshi;
      for (final (String mae, String ato) in okikae) {
        if (moto.endsWith(mae)) {
          naoshi = '${moto.substring(0, moto.length - mae.length)}$ato';
          break;
        }
      }
      sb.write(naoshi ?? '${b}です。');
    }
    return sb.toString();
  }

  /// 選手[s]が区間[kk]を走るときの特徴の文(書けることがなければ空)
  /// [hashiru] その区間を走る大学の選手(区間内順位に使う。nullなら区間内順位は書かない)
  String bun(SenshuData s, int kk, {List<SenshuData>? hashiru}) =>
      _bun(hyou.times(s), kk, hashiru: hashiru, soutou: false);

  /// 学連選抜の選手[g]の特徴の文(区間内順位は、区間を走る大学の選手と比べた「○番目相当」)
  String bunGakuren(Senshu_Gakuren_Data g, int kk, {List<SenshuData>? hashiru}) =>
      _bun(MochiHyou.timesGakuren(g), kk, hashiru: hashiru, soutou: true);

  // ---- 順位の言い方 ----

  /// 学生全体の順位を名詞として使う言い方(「全体42位」「上位の順位」)
  String _zentaiMei(int z, int idx) {
    if (suuji) return '全体$z位';
    switch (_dan(z, hyou.zentaiSuu(idx))) {
      case 0:
        return '上位の順位';
      case 2:
        return '下位の順位';
      default:
        return '中ほどの順位';
    }
  }

  /// 学生全体の順位の言い方(数字で語るなら「全体42位」、情景なら「学生全体でも上位」)
  String _zentaiMoji(int z, int idx) {
    if (suuji) return '全体$z位';
    switch (_dan(z, hyou.zentaiSuu(idx))) {
      case 0:
        return '学生全体でも上位';
      case 2:
        return '学生全体では下位';
      default:
        return '学生全体では中ほど';
    }
  }

  /// 区間内順位の言い方(「区間内3番目」「区間内3番目相当」。情景なら「区間の顔ぶれの中で上位」)
  String _kukannaiMoji(int r, int n, bool soutou) {
    if (suuji) return '区間内$r番目${soutou ? '相当' : ''}';
    switch (_dan(r, n)) {
      case 0:
        return '区間の顔ぶれの中で上位';
      case 2:
        return '区間の顔ぶれの中では下位';
      default:
        return '区間の顔ぶれの中で中ほど';
    }
  }

  // ---- 観点 ----

  /// 全体順位の比べで「はっきり良い」と言える差
  int _sa(int idx) {
    final int n = hyou.zentaiSuu(idx);
    return n ~/ 10 < 3 ? 3 : n ~/ 10;
  }

  /// A 距離適性(5000m・1万m・ハーフの全体順位を比べる)
  _Kansatsu? _kyori(List<double> t, int kk) {
    final List<int> z = [for (int idx = 0; idx < 3; idx++) hyou.zentai(t[idx], idx)];
    final List<int> ari = [for (int idx = 0; idx < 3; idx++) if (z[idx] > 0) idx];
    if (ari.length < 2) return null;
    int best = ari.first;
    for (final int idx in ari) {
      if (z[idx] < z[best]) best = idx;
    }
    int niban = -1;
    for (final int idx in ari) {
      if (idx != best && (niban < 0 || z[idx] < z[niban])) niban = idx;
    }
    final bool anteishita = niban >= 0 && z[niban] - z[best] < _sa(best);
    final int kihon = kukanKihonShumoku(k.gh, k.race, kk);
    final String kyoriMoji = kmMoji(k.gh.kyori_taikai_kukangoto[k.race][kk]);
    // 型の言い方
    final String kata;
    if (anteishita) {
      kata = w.erabu([
        '持ちタイムの順位は種目による差が小さく、距離を問わないタイプ',
        'どの距離でも順位が大きく変わらない、安定したタイプ',
        '5000mからハーフまで、順位にばらつきがないタイプ',
      ]);
    } else if (best == 0) {
      kata = w.erabu([
        '持ちタイムの順位は5000mが一番良く、スピードで押すタイプ',
        '長い種目ほど順位が下がる、スピード型',
        '5000mの${_zentaiMei(z[0], 0)}が光る、短い距離に強いタイプ',
      ]);
    } else if (best == 1) {
      kata = w.erabu([
        '持ちタイムの順位は1万mが一番良く、中くらいの距離に強いタイプ',
        '5000mでもハーフでもなく、1万mで一番順位が上がるタイプ',
        '1万mの${_zentaiMei(z[1], 1)}が持ち味の、中距離寄りのタイプ',
      ]);
    } else {
      kata = w.erabu([
        '持ちタイムの順位はハーフが一番良く、距離が延びるほど力を出すタイプ',
        '5000mより1万m、1万mよりハーフ。長い距離に強いタイプ',
        'ハーフの${_zentaiMei(z[2], 2)}が示すとおり、距離に強いタイプ',
      ]);
    }
    // 区間の距離との合い
    final String ai;
    if (anteishita) {
      ai = w.erabu(['$kyoriMojiのこの区間でも、持ちタイムどおりの走りが見込める。', '$kyoriMojiという距離に、不安はない。']);
    } else if (best == kihon) {
      ai = w.erabu([
        '$kyoriMojiのこの区間は、まさに持ち味の距離だ。',
        '$kyoriMojiという区間の距離は、得意な種目と重なる。',
        '区間の距離($kyoriMoji)は、持ち味に合っている。',
      ]);
    } else if (best < kihon) {
      ai = w.erabu([
        '$kyoriMojiのこの区間は、持ち味の距離よりやや長い。',
        '$kyoriMojiという距離を、スピードで押し切れるかが鍵になる。',
      ]);
    } else {
      ai = w.erabu([
        '$kyoriMojiのこの区間は、持ち味の距離よりやや短い。',
        '$kyoriMojiという距離では、持ち味を出し切る前に終わるかもしれない。',
      ]);
    }
    return _Kansatsu(0, '$kataだ。$ai');
  }

  /// B 区間の型(1万m(トラック)とロード1万の全体順位を比べる)
  _Kansatsu? _kukanKata(List<double> t, int kk) {
    final int zTrack = hyou.zentai(t[1], 1);
    final int zRoad = hyou.zentai(t[6], 6);
    if (zTrack <= 0 || zRoad <= 0) return null;
    final int sa = zRoad - zTrack; // 正ならトラックのほうが良い
    final int margin = _sa(1);
    // 0: 1区向き、1: 2・3区向き、2: 後半向き
    final int muki = sa >= margin ? 0 : (-sa >= margin ? 2 : 1);
    final int ima = kk == 0 ? 0 : (kk <= 2 ? 1 : 2);
    final String hikaku;
    if (muki == 0) {
      hikaku = w.erabu([
        'トラックの1万m(${_zentaiMoji(zTrack, 1)})のほうがロード1万(${_zentaiMoji(zRoad, 6)})より順位が良く、ペースの変化に強い1区向きの脚だ。',
        'ロードよりトラックで順位が上がるタイプで、集団の揺さぶりがある1区に向く。',
      ]);
    } else if (muki == 2) {
      hikaku = w.erabu([
        'ロード1万(${_zentaiMoji(zRoad, 6)})のほうがトラックの1万m(${_zentaiMoji(zTrack, 1)})より順位が良く、ロードで力を出す後半区間向きの脚だ。',
        'トラックよりロードで順位が上がるタイプで、単独走になりやすい4区以降に向く。',
      ]);
    } else {
      hikaku = w.erabu([
        'トラックの1万mとロード1万の順位が同じくらいで、ペースの変化とロードの両方が求められる2区・3区向きの脚だ。',
        'トラックとロードで順位に差がなく、2区・3区のような両方の力がいる区間に向く。',
      ]);
    }
    final String ai;
    if (muki == ima) {
      ai = w.erabu(['今回の${kk + 1}区は、その持ち味に合う。', '${kk + 1}区という起用は、理にかなっている。', '${kk + 1}区は、まさに適性どおりの区間だ。']);
    } else if (ima == 1) {
      ai = w.erabu(['今回の${kk + 1}区では、${muki == 0 ? 'ロード' : 'ペースの変化'}への対応も問われる。', '${kk + 1}区は両方の力がいるだけに、${muki == 0 ? 'ロード' : 'ペースの変化'}が課題になる。']);
    } else if (ima == 0) {
      ai = w.erabu(['今回の1区は、集団のペースの変化にどこまでついていけるかが鍵だ。', '1区では、持ち味のロードの強さより、ペースの変化への対応が問われる。']);
    } else {
      ai = w.erabu(['今回の${kk + 1}区は単独走になりやすく、ロードでどこまで押せるかが鍵だ。', '${kk + 1}区では、トラックのスピードより、ロードで一人で押す力が問われる。']);
    }
    return _Kansatsu(1, '$hikaku$ai');
  }

  /// C 区間内順位の善戦・苦戦(区間の距離と型に合った種目で見る)
  _Kansatsu? _kukannai(List<double> t, int kk, List<SenshuData> hashiru, bool soutou) {
    final double kyori = k.gh.kyori_taikai_kukangoto[k.race][kk];
    final bool ikku = kk == 0;
    final bool nisan = kk == 1 || kk == 2;
    final List<int> evs;
    if (kyori >= 15000) {
      evs = ikku ? [2, 1] : (nisan ? [2, 1, 6] : [2]);
    } else if (kyori >= 7500) {
      evs = ikku ? [1] : (nisan ? [1, 6] : [6]);
    } else {
      evs = ikku ? [0] : (nisan ? [0, 6] : [0, 6]);
    }
    // 種目ごとに、その区間で問われるもの
    String motome(int ev) {
      if (ev == 2) return '距離';
      if (ev == 6) return 'ロード';
      return kk <= 2 ? 'ペースの変化' : '距離';
    }

    final int n = hashiru.length;
    final List<String> moji = [];
    final List<String> tsuyoi = [];
    final List<String> yowai = [];
    for (final int ev in evs) {
      final int r = hyou.kukannai(t[ev], ev, hashiru);
      if (r <= 0) continue;
      // 2つ目からは短く(「区間内3番目、1万mは5番目」「区間の顔ぶれの中で上位、1万mは中ほど」)
      final String jm = moji.isEmpty
          ? _kukannaiMoji(r, n, soutou)
          : (suuji ? '$r番目${soutou ? '相当' : ''}' : const ['上位', '中ほど', '下位'][_dan(r, n)]);
      moji.add('${_shumoku[ev]}は$jm');
      final int d = _dan(r, n);
      if (d == 0) tsuyoi.add(motome(ev));
      if (d == 2) yowai.add(motome(ev));
    }
    if (moji.isEmpty) return null;
    final String junbun = '${moji.join('、')}。';
    final String handan;
    if (tsuyoi.isNotEmpty && yowai.isEmpty) {
      handan = w.erabu([
        '善戦が期待できる。',
        'この区間では上位の走りが見込める。',
        '区間上位を狙える数字だ。',
        '持ちタイムどおりなら、前で勝負できる。',
      ]);
    } else if (yowai.isNotEmpty && tsuyoi.isEmpty) {
      handan = w.erabu([
        '苦戦も覚悟の区間になる。',
        '持ちタイムの上では厳しい戦いだ。',
        '数字の上では分が悪く、粘りが問われる。',
        '周りが強いだけに、どこまで食らいつけるかだ。',
      ]);
    } else if (tsuyoi.isNotEmpty) {
      handan = w.erabu([
        '${tsuyoi.join('と')}は心強いが、${yowai.join('と')}が鍵になる。',
        '${tsuyoi.join('と')}では上位だけに、${yowai.join('と')}への対応次第で順位が変わる。',
      ]);
    } else {
      handan = w.erabu([
        '展開次第で上も狙える位置だ。',
        '区間の中では中ほどで、流れをつかめるかどうかだ。',
      ]);
    }
    return _Kansatsu(2, '$junbun$handan');
  }

  /// D 坂とアップダウン(登り1万・下り1万・クロカン1万)
  _Kansatsu? _saka(List<double> t, int kk, List<SenshuData>? hashiru, bool soutou) {
    final KukanTokuchou tok = kukanTokuchou(k.gh, k.race, kk);
    if (tok == KukanTokuchou.heitan) return null;
    final bool nobori = tok == KukanTokuchou.yamaNobori || tok == KukanTokuchou.nobori;
    final bool kudari = tok == KukanTokuchou.yamaKudari || tok == KukanTokuchou.kudari;
    final int ev = nobori ? 4 : (kudari ? 5 : 7);
    final String evMoji = _shumoku[ev];
    final String michi = nobori ? '登り' : (kudari ? '下り' : 'アップダウン');
    final StringBuffer sb = StringBuffer();
    // 区間内(公開されていれば)か、学生全体の順位
    int d = 1;
    bool kaita = false;
    if (hashiru != null) {
      final int r = hyou.kukannai(t[ev], ev, hashiru);
      final int n = hashiru.length;
      if (r > 0) {
        d = _dan(r, n);
        sb.write('${michi}が続くこの区間で頼りになる$evMojiは、${_kukannaiMoji(r, n, soutou)}。');
        kaita = true;
      }
    }
    if (!kaita) {
      final int z = hyou.zentai(t[ev], ev);
      if (z > 0) {
        d = _dan(z, hyou.zentaiSuu(ev));
        sb.write('${michi}が続くこの区間で頼りになる$evMojiは、${_zentaiMoji(z, ev)}。');
        kaita = true;
      }
    }
    // 登り基調・下り基調では、登りと下りのどちらが得意かも添える
    if (nobori || kudari) {
      final int z4 = hyou.zentai(t[4], 4);
      final int z5 = hyou.zentai(t[5], 5);
      if (z4 > 0 && z5 > 0 && (z4 - z5).abs() >= _sa(4)) {
        final bool noboriTokui = z4 < z5;
        final bool au = noboriTokui == nobori;
        sb.write(
          au
              ? w.erabu(['下りより${michi}のほうが得意で、区間の起伏とかみ合う。', '登りと下りでは${michi}で順位が上がるタイプで、この区間向きだ。'])
              : w.erabu(['ただ、登りと下りでは${noboriTokui ? '登り' : '下り'}のほうが得意で、${michi}基調のこのコースは本来の得意とは違う。', '登りと下りでは${noboriTokui ? '登り' : '下り'}で順位が上がるタイプなので、${michi}の多いこの区間は持ち味と少しずれる。']),
        );
        kaita = true;
      }
    }
    if (!kaita) return null;
    if (d == 0) {
      sb.write(w.erabu(['起伏は味方になりそうだ。', '坂で差をつける走りに期待したい。', 'コースの起伏が、むしろ追い風になる。']));
    } else if (d == 2) {
      sb.write(w.erabu(['起伏でどこまで粘れるかが課題だ。', '坂で脚を使いすぎないことが鍵になる。', 'このコースの起伏は、正直に言えば不安材料だ。']));
    }
    return _Kansatsu(3, sb.toString());
  }

  /// 特徴の文(入り方を選手ごとに回し、最大3文。区間内順位の観点は書けるときは必ず入れる)
  String _bun(List<double> t, int kk, {required List<SenshuData>? hashiru, required bool soutou}) {
    if (k.gh.kyori_taikai_kukangoto.length <= k.race || k.gh.kyori_taikai_kukangoto[k.race].length <= kk) {
      return '';
    }
    final List<_Kansatsu> all = [
      for (final _Kansatsu? x in [
        _kyori(t, kk),
        _kukanKata(t, kk),
        if (hashiru != null) _kukannai(t, kk, hashiru, soutou),
        _saka(t, kk, hashiru, soutou),
      ])
        if (x != null) x,
    ];
    final int ban = _ban++;
    if (all.isEmpty) return '';
    // 入り方を回す(何人目かで最初に置く観点を変える)
    final int start = ban % all.length;
    final List<_Kansatsu> jun = [...all.sublist(start), ...all.sublist(0, start)];
    // 長さも変える(書けることが多い選手は3文、少ない選手は1〜2文)
    final int kazu = all.length >= 3 ? (ban % 3 == 2 ? 2 : 3) : all.length;
    List<_Kansatsu> erabi = jun.take(kazu).toList();
    // 区間内順位の観点は、書けるときは必ず入れる
    final _Kansatsu? kukannai = all.where((x) => x.kanten == 2).firstOrNull;
    if (kukannai != null && !erabi.contains(kukannai)) {
      erabi = [...erabi.sublist(0, erabi.length - 1), kukannai];
    }
    final String bun = erabi.map((x) => x.bun).join();
    return teinei ? _teineiNi(bun) : bun;
  }
}
