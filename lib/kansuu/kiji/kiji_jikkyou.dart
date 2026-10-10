import 'dart:math' as math; // 持ちタイムの換算(距離の比の1.06乗。1.9.5)
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';
import 'package:ekiden/kansuu/koukou.dart'; // 出身校(高校の同期対決。1.9.5)

// ------------------------------------------------------------
// 駅伝の実況「箱庭スポーツ中継」(1.9.4。レース画面の「実況」のカードと、結果画面の記事の画面)
//
// ・レースは区間ごとに進むので、区間が終わるたびに、その区間を中継風に語る記事を1本作る。
//   記事の画面では、終わったばかりの区間を一番上にして、1区からの実況が並ぶ
// ・実況アナと解説者の掛け合い。実況は「〜です！」の話し言葉の段落、解説はコメントの枠(左に線)。
//   解説者は大会ごとに1人(名前から記者の型が決まり、数字で語る・情景で語る・辛口の違いがある)
// ・書くのは、その時点で画面で見えていることだけ
//   ・たすきを受けた順位と差、抜いた相手、首位交代、区間賞、1区の集団のペースと飛び出し
//     (飛び出した選手は他大学も名前を出し、最初の段落でクローズアップする。成否は補正の説明の印、
//     逃げ切ったか飲み込まれたかは区間タイムと集団のペースの比べ)、
//     自分の大学の指示とその成否、目標順位を下回っての焦り・ほっと一息、学連選抜、因縁
//   ・能力は、選手ごとの補正の説明(string_racesetumei。見抜く力のついた能力だけ書かれている)に
//     出ている分と、分析(racechuukakuseiflag。区間順位の画面の「分析」で、見抜く力に関係なく
//     全部の能力が出ている)で際立っていた分(絶対値5以上。1人1つ)だけ、数字なしで触れる。
//     分析はその区間を走った選手の中の相対値なので、「この区間の選手の中で」の言い方にする。
//     能力の値そのものは見ない
// ・記事と同じく、年・大会・区間で決まる乱数を使うので、何度開いても同じ実況になる
// ・最終区は、ゴールの瞬間までを語る。総括は結果の記事(kiji_kekka.dart)に任せる
// ・シード権(11月駅伝8校・正月駅伝10校)は、優勝争いと同じ重さで伝える。最終区は「シード権争い」の
//   段落と表(ラインの前後2校ずつ)、その前の2区間は「当落線上」の段落(ライン前後の順位と差、出入り)。
//   自分の大学がラインの前後2校以内でゴールしたときは、まずシード権の決着を伝える
// ・1.9.5: 次の区間の見どころに、区間記録・前回の区間賞・持ちタイムの顔ぶれ・首位争いの読みなどと、
//   持ちタイム上位5人の表を足した。次の区間が最後の3区間のときは、シード権の行方
//   (ライン前後の大学の次の走者の比べと表。アンカーの前は「最後の1枠へ」)も書く
// ------------------------------------------------------------

/// 中継の名前
const String jikkyouSiteMei = '箱庭スポーツ中継';

/// 区間[kk]の、大学1校分の途中経過
class _Koma {
  final UnivData u;

  /// この区間を走った選手(見つからなければnull)
  final SenshuData? s;

  /// 区間終了時点の累計タイム
  final double ruikei;

  /// 区間タイム
  final double kukanTime;

  /// 区間終了時点の順位(0が1位)
  int tuuka = 0;

  /// 前の区間の終了時点の順位(1区は0)
  int tuukaMae = 0;

  /// 区間順位(0が1位)
  int kukanJuni = 0;

  _Koma(this.u, this.s, this.ruikei, this.kukanTime);

  String get mei => daigakuMei(u);
}

/// 区間[kk]の途中経過(累計タイムの順。出場校が2校より少ないときなどは空)
List<_Koma> _kukanKoma(KijiKankyou k, int kk) {
  final List<_Koma> list = [];
  for (final UnivData u in k.univ) {
    if (!k.shutsujou(u)) continue;
    if (u.time_taikai_total.length <= kk) continue;
    final double t = u.time_taikai_total[kk];
    if (t <= 0 || t >= TEISUU.DEFAULTTIME) continue;
    final double mae = kk == 0 ? 0 : u.time_taikai_total[kk - 1];
    if (kk > 0 && (mae <= 0 || mae >= TEISUU.DEFAULTTIME)) continue;
    SenshuData? s;
    for (final SenshuData x in k.senshu) {
      if (x.univid == u.id && k.entry(x) == kk) {
        s = x;
        break;
      }
    }
    list.add(_Koma(u, s, t, t - mae));
  }
  if (list.length < 2) return [];
  list.sort((a, b) => a.ruikei.compareTo(b.ruikei));
  for (int i = 0; i < list.length; i++) {
    list[i].tuuka = i;
  }
  if (kk > 0) {
    final List<_Koma> maeJun = List<_Koma>.of(list)
      ..sort((a, b) => a.u.time_taikai_total[kk - 1].compareTo(b.u.time_taikai_total[kk - 1]));
    for (int i = 0; i < maeJun.length; i++) {
      maeJun[i].tuukaMae = i;
    }
  }
  final List<_Koma> kj = List<_Koma>.of(list)
    ..sort((a, b) => a.kukanTime.compareTo(b.kukanTime));
  for (int i = 0; i < kj.length; i++) {
    kj[i].kukanJuni = i;
  }
  return list;
}

/// 駅伝の実況の一覧(終わったばかりの区間が先頭。[owatta] 大会が終わって結果画面にいるとき)
List<Kiji> jikkyouKiji(KijiKankyou k, {required bool owatta}) {
  if (!k.ekiden) return [];
  final int ks = k.kukansuu;
  final int done = k.gh.nowracecalckukan < ks ? k.gh.nowracecalckukan : ks;
  if (done <= 0) return [];
  // 実況アナと解説者(大会ごとに決める)
  final String ana = _hitoMei(k, 201);
  final String kaisetsu = _hitoMei(k, 202);
  final KishaKata kata = kishaKataKara(kaisetsu);
  final List<Kiji> list = [];
  for (int kk = done - 1; kk >= 0; kk--) {
    final Kiji? kiji = _kukanJikkyou(k, kk, ana: ana, kaisetsu: kaisetsu, kata: kata, owatta: owatta);
    if (kiji != null) list.add(kiji);
  }
  return list;
}

/// 実況アナ・解説者の名前(年・大会で決まる)
String _hitoMei(KijiKankyou k, int tsuika) {
  final KijiRand r = KijiRand(kijiTane(k.gh, k.race, 0, tsuika));
  final List<String> mae = [
    for (final String n in k.gh.name_mae)
      if (n.isNotEmpty) n,
  ];
  final List<String> ato = [
    for (final String n in k.gh.name_ato)
      if (n.isNotEmpty) n,
  ];
  if (mae.isEmpty || ato.isEmpty) return tsuika == 201 ? '実況席' : '解説席';
  return '${r.erabu(mae)}${r.erabu(ato)}';
}

/// 大学名つきの選手の呼び方(初めては「南北大・山田太郎(3年)」、2回目からは「南北大・山田」)
String _yobi(KijiKakite w, _Koma x) {
  final SenshuData? s = x.s;
  if (s == null) return '${x.mei}の走者';
  return '${x.mei}・${w.senshu(s)}';
}

/// 補正の説明(string_racesetumei)から読める、その区間の走りの事情
class _Hashiri {
  /// 指示(0なし、1前半突っ込み(1区はスタート直後飛び出し)、2前半抑え(1区は飛び出さない))
  int siji = 0;

  /// 指示の結果(nullなら判定なし。trueなら成功)
  bool? seikou;

  /// 目標順位を下回っていて焦った(突っ込み)
  bool aseri = false;

  /// 目標順位を上回っていてほっと一息
  bool hitoiki = false;

  /// 1区の集団のペースとの関係(ikkuSetsumeiGyou の行。なければ空)
  String shuudan = '';

  /// 見えている能力の補正のうち、区間で一番良かったもの(名前と順位。なければnull)
  ({String mei, int juni})? tsuyomi;

  /// 見えている能力の補正のうち、区間で一番悪かったもの(名前と順位。なければnull)
  ({String mei, int juni})? yowami;

  /// 分析(区間順位の画面の「分析」。見抜く力に関係なく全部の能力が出る)で、
  /// 良い方に際立っていた能力の呼び方(なければnull。1.9.4)
  String? kiwaYoi;

  /// 分析で、悪い方に際立っていた能力の呼び方(なければnull)
  String? kiwaWarui;
}

/// 分析の値(その区間を走った選手の中の相対値。-7〜+7。マイナスが良い)の項目の呼び方
/// (項目の番号は RaceCalc.dart の tensuu の並び。0調子・1指示・2集団走は別の文で書くので使わない)
const Map<int, String> _bunsekiYobikata = {
  3: '走力そのもの',
  4: '登りの強さ',
  5: '下りの巧みさ',
  6: 'アップダウンへの対応',
  7: '経験',
  8: 'ロードへの適性',
  9: 'ペースの変化への対応',
  10: '長い距離での粘り',
  11: 'スパートの切れ味',
};

/// 「際立っている」の線引き(分析の値の絶対値がこれ以上)
const int _kiwadachiSen = 5;

/// 分析の値から、良い方・悪い方それぞれで一番際立っていた能力を読む(数字は使わず、名前だけ)
void _kiwadachiYomu(_Hashiri h, SenshuData s) {
  final int flag = s.racechuukakuseiflag;
  if (flag == 0) return;
  int yoiTen = 0;
  int waruiTen = 0;
  for (final MapEntry<int, String> e in _bunsekiYobikata.entries) {
    final int ten = ((flag >> (e.key * 4)) & 0xF) - 7;
    if (ten <= -_kiwadachiSen && ten < yoiTen) {
      yoiTen = ten;
      h.kiwaYoi = e.value;
    }
    if (ten >= _kiwadachiSen && ten > waruiTen) {
      waruiTen = ten;
      h.kiwaWarui = e.value;
    }
  }
}

/// 補正の説明の読み取り(数字は読まず、何があったかだけを拾う)
_Hashiri _hashiriYomu(SenshuData s, int kk) {
  final _Hashiri h = _Hashiri();
  _kiwadachiYomu(h, s);
  h.siji = s.sijiflag.clamp(0, 2).toInt();
  if (kk == 0) {
    if (s.startchokugotobidasiflag == 1) {
      h.siji = 1;
      h.seikou = s.startchokugotobidasiseikouflag == 1;
    }
  } else if (h.siji >= 1) {
    h.seikou = s.sijiseikouflag == 1;
  }
  const List<String> nouryoku = [
    '登り補正',
    '下り補正',
    'アップダウン対応力補正',
    'ロード適性補正',
    'ペース変動対応力補正',
    '長距離粘り補正',
    'スパート力補正',
  ];
  const Map<String, String> yobikata = {
    '登り補正': '登りの強さ',
    '下り補正': '下りの巧みさ',
    'アップダウン対応力補正': 'アップダウンへの対応',
    'ロード適性補正': 'ロードへの適性',
    'ペース変動対応力補正': 'ペースの変化への対応',
    '長距離粘り補正': '長い距離での粘り',
    'スパート力補正': 'スパート',
  };
  int? bestJuni;
  int? worstJuni;
  for (final String gyou in s.string_racesetumei.split('\n')) {
    final String g = gyou.trim();
    if (g.isEmpty) continue;
    if (g.startsWith('目標順位下回って')) h.aseri = true;
    if (g.startsWith('目標順位上回って')) h.hitoiki = true;
    if (g.contains('集団のペース') || g.contains('飛び出し補正')) {
      if (h.shuudan.isEmpty && g.contains('集団のペース')) h.shuudan = g;
    }
    for (final String n in nouryoku) {
      if (!g.startsWith('$n ')) continue;
      // 「登り補正 3位:-12.3秒」の順位を読む(「無」は関係のない能力)
      final RegExpMatch? m = RegExp(r'^\S+ (\d+)位:').firstMatch(g);
      if (m == null) continue;
      final int juni = int.tryParse(m.group(1) ?? '') ?? 0;
      if (juni <= 0) continue;
      if (bestJuni == null || juni < bestJuni) {
        bestJuni = juni;
        h.tsuyomi = (mei: yobikata[n] ?? n, juni: juni);
      }
      if (worstJuni == null || juni > worstJuni) {
        worstJuni = juni;
        h.yowami = (mei: yobikata[n] ?? n, juni: juni);
      }
    }
  }
  return h;
}

/// 種目(time_bestkiroku の0〜2)の距離(m。持ちタイムの換算に使う。展望記事・直前順位予想の王太郎と同じ。1.9.5)
const List<double> _kansanShumokuKyori = [5000.0, 10000.0, 21097.5];

/// 選手[s]の種目[idx]の持ちタイムを、区間の距離[kyori]に換算した秒(1.9.5)
/// 距離の比の1.06乗を掛ける(展望記事・王太郎の予想と同じ)。5000m・1万m・ハーフのときだけで、
/// 登り1万などの種目のときや、記録がないときはnull
double? _kansanTime(KijiKankyou k, SenshuData s, int idx, double kyori) {
  if (idx < 0 || idx > 2 || kyori <= 0) return null;
  final double t = k.jikoBest(s, idx);
  if (t >= TEISUU.DEFAULTTIME) return null;
  return t * math.pow(kyori / _kansanShumokuKyori[idx], 1.06).toDouble();
}

/// 情景型の解説が、次の区間のコースを語るひと言(1.9.5)
String _courseNoKotoba(KukanTokuchou t, {required bool anchor, required bool nagai}) {
  switch (t) {
    case KukanTokuchou.yamaNobori:
      return '山に入ると、景色も走りもがらりと変わります。上りでは、持ちタイムより坂への強さが物を言いますよ';
    case KukanTokuchou.yamaKudari:
      return '山下りは、スピードと怖さとの戦いです。勢いに乗れるかどうかで、大きく差がつきます';
    case KukanTokuchou.updown:
      return 'アップダウンが続くと、リズムを保つのが難しい。持ちタイムどおりにはいかない区間です';
    case KukanTokuchou.nobori:
      return 'じわじわと上っていく区間です。前半で脚を使いすぎると、後半に響きますよ';
    case KukanTokuchou.kudari:
      return '下り基調の区間は、スピードに乗れる分、後半に脚がどれだけ残っているかが鍵です';
    case KukanTokuchou.heitan:
      if (anchor) return 'アンカーは、たすきの重みが一番かかる区間。沿道の声援が背中を押してくれますよ';
      if (nagai) return '長い区間は、後半にどれだけ余力を残せるか。前半の入り方に注目です';
      return 'たすきが渡るたびに、沿道の声援が大きくなってきましたね';
  }
}

Kiji? _kukanJikkyou(
  KijiKankyou k,
  int kk, {
  required String ana,
  required String kaisetsu,
  required KishaKata kata,
  required bool owatta,
}) {
  final List<_Koma> jun = _kukanKoma(k, kk);
  if (jun.isEmpty) return null;
  final int ks = k.kukansuu;
  final int n = jun.length;
  final int race = k.race;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, race, 200 + kk));
  final String kukanMei = kukanYobikata(k.gh, race, kk, ks);
  final String kyori = kmMoji(k.gh.kyori_taikai_kukangoto[race][kk]);
  final bool saigo = kk == ks - 1;
  final bool ouroOwari = race == 2 && ks >= 6 && kk == 4;
  final List<_Koma> kjJun = List<_Koma>.of(jun)..sort((a, b) => a.kukanJuni.compareTo(b.kukanJuni));
  final _Koma shui = jun[0];
  final _Koma ni = jun[1];
  final _Koma kukanshou = kjJun[0];
  final int sa12 = saByou(ni.ruikei, shui.ruikei);
  _Koma? shuiMae;
  int saMae12 = 0;
  if (kk > 0) {
    for (final _Koma x in jun) {
      if (x.tuukaMae == 0) shuiMae = x;
    }
    _Koma? niMae;
    for (final _Koma x in jun) {
      if (x.tuukaMae == 1) niMae = x;
    }
    if (shuiMae != null && niMae != null) {
      saMae12 = saByou(niMae.u.time_taikai_total[kk - 1], shuiMae.u.time_taikai_total[kk - 1]);
    }
  }
  // 一番順位を上げた・下げた大学
  _Koma? ue;
  _Koma? shita;
  int ueKazu = 0;
  int shitaKazu = 0;
  if (kk > 0) {
    for (final _Koma x in jun) {
      final int d = x.tuukaMae - x.tuuka;
      if (d > ueKazu) {
        ueKazu = d;
        ue = x;
      }
      if (-d > shitaKazu) {
        shitaKazu = -d;
        shita = x;
      }
    }
  }
  // 自分の大学
  _Koma? my;
  for (final _Koma x in jun) {
    if (x.u.id == k.gh.MYunivid) my = x;
  }
  // シード権のライン(11月駅伝8校・正月駅伝10校。出場校がそれより少なければ争いなし)
  final int seedSuu = race == 1 ? 8 : (race == 2 ? 10 : 0);
  final bool seedAri = seedSuu > 0 && n > seedSuu;
  final _Koma? nokori = seedAri ? jun[seedSuu - 1] : null; // 最後にシード権を取っている大学
  final _Koma? morashi = seedAri ? jun[seedSuu] : null; // 最初に逃している大学
  final int saSeed = (nokori != null && morashi != null) ? saByou(morashi.ruikei, nokori.ruikei) : 0;
  // 前の区間の終了時点で[i]位だった大学
  _Koma? maeKoma(int i) {
    for (final _Koma x in jun) {
      if (x.tuukaMae == i) return x;
    }
    return null;
  }
  // この区間でシード権の圏内に入った・圏外に下がった大学
  final List<_Koma> seedIri = [
    for (final _Koma x in jun)
      if (seedAri && kk > 0 && x.tuuka < seedSuu && x.tuukaMae >= seedSuu) x,
  ];
  final List<_Koma> seedDe = [
    for (final _Koma x in jun)
      if (seedAri && kk > 0 && x.tuuka >= seedSuu && x.tuukaMae < seedSuu) x,
  ];
  // 当落線上を伝える区間(最終区の前の2区間。残り3区間以内)
  final bool touraku = seedAri && !saigo && kk > 0 && kk >= ks - 3;
  final int mokuhyou = (my != null && my.u.mokuhyojuni.length > race) ? my.u.mokuhyojuni[race] : -1;
  final bool mokuhyouAri = my != null && mokuhyou >= 0 && mokuhyou < n;
  // 解説のコメント(左に線の枠で出す)
  void kai(String bun) => w.comment('解説・$kaisetsu「$bun」');
  // 1区でスタート直後に飛び出した選手(区間順位の良い順。他大学の選手も、区間順位の画面の説明に
  // 「スタート直後飛び出し補正」が出ているので名前を出せる)と、1区の集団のペースの結果
  final List<_Koma> tobidashi = kk == 0
      ? ([
          for (final _Koma x in jun)
            if (x.s != null && x.s!.startchokugotobidasiflag == 1) x,
        ]..sort((a, b) => a.kukanJuni.compareTo(b.kukanJuni)))
      : <_Koma>[];
  final IkkuPaceKekka? pace = kk == 0 ? ikkuPaceKekkaYomu(k.kantoku, k.gh) : null;
  // 集団のペース(1区のタイムに換算した秒。引っ張った選手がいなければnull)
  final double? shuudanPace = (pace != null && pace.pacemakerId != null && pace.pace > 0) ? pace.pace : null;

  // 見出し
  String midashi;
  if (saigo) {
    midashi = w.erabu(['${shui.mei}が優勝のゴール！', '${shui.mei}、歓喜のフィニッシュ']);
    if (sa12 <= ks * 3) midashi += '　2位と${kinsaMoji(sa12)}';
    // シード権争いがもつれたときは、見出しにも
    if (nokori != null && (saSeed <= ks * 3 || saSeed <= 30)) {
      midashi += '　シード権は${nokori.mei}が${kinsaMoji(saSeed)}で確保';
    }
  } else if (shuiMae != null && shuiMae.u.id != shui.u.id) {
    midashi = '${kk + 1}区で首位交代　${shui.mei}が${shuiMae.mei}をかわす';
  } else if (ue != null && ueKazu >= 3 && ue.s != null) {
    midashi = '${kk + 1}区　${shui.mei}が首位守る　${ue.mei}・${myouji(ue.s!.name)}が$ueKazu人抜き';
  } else if (kk == 0 && tobidashi.isNotEmpty && tobidashi.first.tuuka == 0) {
    // 飛び出した選手が先頭でたすきを渡した(1区は区間順位と通過順位が同じ)
    final _Koma t = tobidashi.first;
    midashi = '1区　${t.mei}・${myouji(t.s!.name)}が飛び出して逃げ切る　2位と${kinsaMoji(sa12)}';
  } else if (kukanshou.s != null) {
    midashi = '${kk + 1}区　${shui.mei}が首位　区間トップは${kukanshou.mei}・${myouji(kukanshou.s!.name)}';
  } else {
    midashi = '${kk + 1}区を終えて${shui.mei}が首位';
  }

  // リード(実況の入り)
  final StringBuffer lead = StringBuffer();
  if (kk == 0) {
    lead.write(
      w.erabu([
        '${k.taikaiMei}、$n校が一斉にスタートしました！',
        'さあ、${k.taikaiMei}の号砲です！ $n校の1区が走り出しました！',
      ]),
    );
    // 飛び出した選手は、人数ではなく名前で(テレビで一番目立つ場面なので、先に伝える)
    if (tobidashi.isNotEmpty) {
      lead.write('スタート直後、${_yobi(w, tobidashi.first)}が集団から飛び出しました！');
      if (tobidashi.length >= 2) lead.write('${_yobi(w, tobidashi[1])}も続きます。');
      if (tobidashi.length >= 3) lead.write('飛び出したのは全部で${tobidashi.length}人です。');
    }
    if (pace != null && pace.pacemakerId != null && pace.pacemakerId! >= 0 && pace.pacemakerId! < k.senshu.length) {
      final SenshuData pm = k.senshu[pace.pacemakerId!];
      final String pmDaigaku = (pm.univid >= 0 && pm.univid < k.univ.length) ? '${daigakuMeiMoji(k.univ[pm.univid].name)}・' : '';
      lead.write('集団を引っ張るのは$pmDaigaku${w.senshu(pm)}。${ikkuPaceMidashiMoji[pace.midashi]}の展開です。');
      final int tobidashiKazu = pace.kazu.length > 4 ? pace.kazu[4] : 0;
      if (tobidashi.isEmpty && tobidashiKazu >= 1) lead.write('スタート直後から$tobidashiKazu人が飛び出しました！');
    }
  } else {
    lead.write('$kukanMei、$kyoriです。');
    if (shuiMae != null) {
      final SenshuData? ss = shuiMae.s == null ? null : shuiMae.s;
      lead.write(
        saMae12 <= 0
            ? '${shuiMae.mei}が先頭でたすきを受けましたが、2位とはほぼ同時です。'
            : '首位でたすきを受けたのは${shuiMae.mei}${ss != null ? '・${w.senshu(ss)}' : ''}、2位との差は${saMoji(saMae12)}。',
      );
    }
    if (my != null && my.u.id != (shuiMae?.u.id ?? -1) && my.s != null) {
      lead.write('${my.mei}は${juniMoji(my.tuukaMae)}で${w.senshu(my.s!)}にたすきが渡りました。');
    }
    if (saigo && nokori != null && morashi != null && (saSeed <= ks * 3 || saSeed <= 30)) {
      lead.write('優勝争いと並んで、上位$seedSuu校のシード権の最後の1枠も、${nokori.mei}と${morashi.mei}の${kinsaMoji(saSeed)}の争いになりました。');
    }
  }

  // 本文: スタート直後の飛び出し(1区。勇気を持って前に出た選手を、最初にクローズアップする)
  if (kk == 0 && tobidashi.isNotEmpty) {
    w.koMidashi('スタート直後の飛び出し');
    final StringBuffer tbb = StringBuffer();
    final int kazu = tobidashi.length;
    tbb.write(kazu == 1 ? '集団の安心を捨てて、1人が前に出ました。' : '集団の安心を捨てて、$kazu人が前に出ました。');
    // 飛び出した選手ごと(最大3人。成否は補正の説明に出ている印、逃げ切りは集団のペースとの比べ)
    int kaita = 0;
    for (final _Koma x in tobidashi) {
      if (kaita >= 3) break;
      final SenshuData s = x.s!;
      final bool seikou = s.startchokugotobidasiseikouflag == 1;
      final bool? nige = shuudanPace == null ? null : x.kukanTime < shuudanPace;
      final List<Innen> xi = senshuInnen(k, s, 0, kj: x.kukanJuni, kekka: owatta);
      final String ku = (xi.isNotEmpty && xi.first.ten >= 45) ? xi.first.midashiKu : '';
      tbb.write(kaita == 0 ? '$ku${_yobi(w, x)}が、勇気を持って飛び出しました。' : '$ku${_yobi(w, x)}も続きました。');
      // 集団のペースより速かったのに何人かに抜かれたときは、「粘った」の成功のニュアンスで書く
      // (1区は通過順位と区間順位が同じなので、抜かれた人数は通過順位から分かる)
      final bool sentou = x.tuuka == 0;
      if (nige == null) {
        tbb.write(seikou ? '狙いどおりの展開に持ち込みました。' : '後半に代償を払いました。');
      } else if (seikou && nige) {
        tbb.write(sentou ? '集団を最後まで寄せ付けず、逃げ切りました！' : '${x.tuuka}人に先を行かれましたが、集団のペースには飲み込まれず、粘り切りました。');
      } else if (seikou) {
        tbb.write('飛び出しそのものは決まりましたが、集団のペースが速く、後半に飲み込まれました。');
      } else if (nige) {
        tbb.write(sentou ? '後半に苦しみながらも、逃げ切りました！' : '後半に代償を払いましたが、集団のペースには飲み込まれず、粘りました。');
      } else {
        tbb.write('勇気ある飛び出しは実らず、後半に集団に飲み込まれました。');
      }
      tbb.write(
        x.tuuka == 0
            ? '区間賞、そのまま先頭でたすきを渡しました！'
            : '区間${juniMoji(x.kukanJuni)}、${juniMoji(x.tuuka)}でたすきリレー。トップとは${kinsaMoji(saByou(x.ruikei, shui.ruikei))}です。',
      );
      kaita++;
    }
    if (kazu > kaita) tbb.write('ほかに${kazu - kaita}人が飛び出しています。');
    w.danraku(tbb.toString());
    // 解説(一番良かった飛び出しの選手について、型ごと)
    final _Koma t = tobidashi.first;
    final SenshuData ts = t.s!;
    final bool tSeikou = ts.startchokugotobidasiseikouflag == 1;
    final bool tNige = shuudanPace == null || t.kukanTime < shuudanPace;
    final List<Innen> ti = senshuInnen(k, ts, 0, kj: t.kukanJuni, kekka: owatta);
    final _Hashiri th = _hashiriYomu(ts, 0);
    switch (kata) {
      case KishaKata.suuji:
        if (shuudanPace != null) {
          final int sa = saByou(t.kukanTime, shuudanPace);
          kai(
            sa < 0
                ? '${myouji(ts.name)}の区間タイムは、集団のペースより${saMoji(sa)}速い。飛び出した分が、そのまま数字に出ています${th.kiwaYoi != null ? '。${th.kiwaYoi}も際立っていました' : ''}'
                : '${myouji(ts.name)}の区間タイムは、集団のペースより${saMoji(sa)}遅い。飛び出しの代償が数字に出てしまいました',
          );
        } else {
          kai('飛び出しは、決まればタイムが縮み、外れれば後半に跳ね返ってきます。今日は${tSeikou ? '前者' : '後者'}でした');
        }
      case KishaKata.joukei:
        if (ti.isNotEmpty && ti.first.ten >= 45) {
          kai('${myouji(ts.name)}、${ti.first.kotoba}。その思いが、スタート直後の一歩に出ましたね');
        } else if (tSeikou && th.kiwaYoi != null) {
          kai('${myouji(ts.name)}は${th.kiwaYoi}が、この区間の選手の中で際立っていました。前に出る勇気を、力が支えましたね');
        } else {
          kai('集団の安心を捨てて前に出るのは、勇気のいることです。${tSeikou ? 'その勇気が報われました' : '結果は出ませんでしたが、あの一歩は忘れられません'}');
        }
      case KishaKata.karakuchi:
        if (tSeikou && tNige) {
          kai('飛び出して${t.tuuka == 0 ? '逃げ切る' : '粘り切る'}のは、力がなければできません。${myouji(ts.name)}は今日、それを証明しました${th.kiwaYoi != null ? '。${th.kiwaYoi}が際立っていました' : ''}');
        } else if (tSeikou) {
          kai('飛び出しは決まりましたが、集団のほうが速かった。飛び出すなら、逃げ切る力まで要ります');
        } else {
          kai('勝負に出た以上、結果は受け止めるしかありません。ただ、飛び出さなければ見えなかった景色もあったはずです');
        }
    }
  }

  // 本文: 首位の攻防
  w.koMidashi('首位の攻防');
  final StringBuffer sb = StringBuffer();
  if (kk == 0) {
    sb.write(
      w.erabu([
        '1区を制したのは${_yobi(w, shui)}！ 2位の${ni.mei}に${kinsaMoji(sa12)}をつけて、先頭でたすきを渡しました！',
        '${_yobi(w, shui)}がトップでたすきリレー！ ${ni.mei}が${kinsaMoji(sa12)}で続きます。',
      ]),
    );
  } else if (shuiMae != null && shuiMae.u.id != shui.u.id) {
    sb.write(
      w.erabu([
        '首位交代です！ ${_yobi(w, shui)}が${shuiMae.mei}を捉えて先頭に立ちました！',
        '${_yobi(w, shui)}、前を行く${shuiMae.mei}をかわしてトップへ！',
      ]),
    );
    sb.write(saigo ? '' : '2位の${ni.mei}との差は${kinsaMoji(sa12)}。');
    if (shuiMae.tuuka >= 2) sb.write('${shuiMae.mei}は${juniMoji(shuiMae.tuuka)}まで後退しました。');
  } else {
    sb.write(
      w.erabu([
        '${_yobi(w, shui)}、首位を守りました！',
        '先頭は変わらず${shui.mei}。${shui.s != null ? '${w.senshu(shui.s!)}が' : ''}区間${juniMoji(shui.kukanJuni)}の走りで押し切りました。',
      ]),
    );
    if (!saigo) {
      if (sa12 > saMae12 + 5) {
        sb.write('2位の${ni.mei}との差は${saMoji(saMae12)}から${saMoji(sa12)}に広がりました。');
      } else if (sa12 + 5 < saMae12) {
        sb.write('2位の${ni.mei}が${saMoji(saMae12)}差から${kinsaMoji(sa12)}まで詰めてきました！');
      } else {
        sb.write('2位の${ni.mei}との差は${kinsaMoji(sa12)}、ほぼ変わりません。');
      }
    }
  }
  if (saigo) {
    sb.write('${shui.mei}、${jikanMoji(shui.ruikei)}で優勝のゴールです！ 2位の${ni.mei}とは${kinsaMoji(sa12)}でした。');
  }
  w.danraku(sb.toString());
  // 解説(首位について)
  if (kk > 0 && shuiMae != null && shuiMae.u.id != shui.u.id && shui.s != null) {
    final List<Innen> si = senshuInnen(k, shui.s!, kk, kj: shui.kukanJuni, kekka: owatta);
    final _Hashiri sh = _hashiriYomu(shui.s!, kk);
    if (si.isNotEmpty && si.first.ten >= 45) {
      kai('${myouji(shui.s!.name)}、${si.first.kotoba}、という思いがあったはずです。それを形にしましたね');
    } else if (sh.kiwaYoi != null) {
      kai('${myouji(shui.s!.name)}は${sh.kiwaYoi}が、この区間の選手の中で際立っていました。${saMoji(saMae12)}差を埋めたのは、そこです');
    } else {
      kai('${saMoji(saMae12)}差を一人で埋めるのは簡単ではありません。${myouji(shui.s!.name)}は前が見えてから、しっかりギアを上げましたね');
    }
  } else if (kk > 0 && !saigo && sa12 > saMae12 + 5 && shui.s != null) {
    final _Hashiri sh = _hashiriYomu(shui.s!, kk);
    kai(
      sh.kiwaYoi != null
          ? '${myouji(shui.s!.name)}は${sh.kiwaYoi}が際立っていましたね。差が広がったのは、その分です'
          : '${myouji(shui.s!.name)}は後ろを気にせず、自分の走りに徹しましたね。差が広がったのは、その落ち着きです',
    );
  }

  // 本文: シード権争い(最終区。優勝争いと同じ重さで伝える)
  if (saigo && nokori != null && morashi != null) {
    final _Koma nk = nokori;
    final _Koma mr = morashi;
    final bool nkGyakuten = nk.tuukaMae >= seedSuu; // 圏外からの逆転で滑り込んだ
    final bool mrOshidasare = mr.tuukaMae < seedSuu; // 圏内からの押し出された
    w.koMidashi('シード権争い');
    final StringBuffer sdb = StringBuffer();
    sdb.write(
      w.erabu([
        '上位$seedSuu校に与えられるシード権、最後の1枠は${nk.mei}です！',
        'そしてシード権争い！ $seedSuu校目の切符を手にしたのは${nk.mei}！',
      ]),
    );
    if (nkGyakuten) {
      sdb.write('${juniMoji(nk.tuukaMae)}でたすきを受けた${_yobi(w, nk)}が前を捉え、逆転でシード圏内に滑り込みました！');
    } else {
      sdb.write('${_yobi(w, nk)}は${juniMoji(nk.tuukaMae)}でたすきを受け、リードを守り切りました。');
    }
    if (mrOshidasare) {
      sdb.write('一方、シード圏内の${juniMoji(mr.tuukaMae)}でたすきを受けていた${_yobi(w, mr)}は、${juniMoji(mr.tuuka)}に押し出されました。');
    } else {
      sdb.write('${juniMoji(mr.tuukaMae)}でたすきを受けた${_yobi(w, mr)}の追い上げも、届きませんでした。');
    }
    sdb.write('明暗を分けたのは${kinsaMoji(saSeed)}、${hitoriAtariMoji(saSeed, ks)}です。');
    if (nk.s != null && mr.s != null) {
      sdb.write(
        'アンカーの区間順位は、${nk.mei}・${myouji(nk.s!.name)}が${juniMoji(nk.kukanJuni)}、'
        '${mr.mei}・${myouji(mr.s!.name)}が${juniMoji(mr.kukanJuni)}でした。',
      );
    }
    // この区間で圏内に入った・圏外に下がったほかの大学
    final List<String> hokaIri = [
      for (final _Koma x in seedIri)
        if (x.u.id != nk.u.id) x.mei,
    ];
    final List<String> hokaDe = [
      for (final _Koma x in seedDe)
        if (x.u.id != mr.u.id) x.mei,
    ];
    if (hokaIri.isNotEmpty) sdb.write('最終区で${hokaIri.join('、')}も圏外から圏内に入りました。');
    if (hokaDe.isNotEmpty) sdb.write('${hokaDe.join('、')}は圏内から押し出されました。');
    w.danraku(sdb.toString());
    // 顔ぶれ(前回シード校・予選会から・初のシード権)
    final int maeIdx = owatta ? 1 : 0; // 前回の順位の記録の位置(大会が終わると今回の順位が[0]に入る)
    final int yosenRace = race == 1 ? 3 : 4;
    bool maeSeed(_Koma x) {
      final int j = juniRace(x.u, race, maeIdx);
      return shutsujouJuni(j) && j < seedSuu;
    }
    final StringBuffer kb = StringBuffer();
    final List<_Koma> ushinatta = [
      for (final _Koma x in jun)
        if (x.tuuka >= seedSuu && maeSeed(x)) x,
    ];
    final List<_Koma> atarashii = [
      for (final _Koma x in jun)
        if (x.tuuka < seedSuu && !maeSeed(x)) x,
    ];
    if (ushinatta.isNotEmpty) {
      kb.write('前回シード校の${ushinatta.map((x) => '${x.mei}(${juniMoji(x.tuuka)})').join('、')}はシード権を失い、来年は予選会からの出直しです。');
      // 連続シードが一番長かった大学(数を言い切れないときは数を出さない)
      _Koma? togire;
      int togireNen = 0;
      bool togireKakutei = true;
      for (final _Koma x in ushinatta) {
        final ({int kaisuu, bool kakutei}) r = renzokuKakutei(x.u, race, maeIdx, (j) => j < seedSuu, seedKaisuu(x.u, race, seedSuu));
        if (r.kaisuu > togireNen) {
          togireNen = r.kaisuu;
          togireKakutei = r.kakutei;
          togire = x;
        }
      }
      if (togire != null && togireNen >= 2) {
        kb.write(togireKakutei ? '${togire.mei}の連続シードは$togireNen年で途切れました。' : '${togire.mei}の長く続いた連続シードが途切れました。');
      }
    }
    if (atarashii.length >= seedSuu) {
      kb.write('シード権を持っていた大学はなく、上位$seedSuu校すべてが新たにシード権を手にしました！');
    } else if (atarashii.isNotEmpty) {
      String naiyou(_Koma x) {
        final bool yosen = shutsujouJuni(juniRace(x.u, yosenRace, 0));
        final bool hatsu = seedKaisuu(x.u, race, seedSuu) <= (owatta ? 1 : 0);
        return '${x.mei}(${juniMoji(x.tuuka)}${yosen ? '・予選会から' : ''}${hatsu ? '・初のシード権' : ''})';
      }
      kb.write('${ushinatta.isEmpty ? '' : '代わって、'}${atarashii.map(naiyou).join('、')}が新たにシード権を手にしました！');
    }
    if (kb.isNotEmpty) w.danraku(kb.toString());
    // 解説(型ごと)
    switch (kata) {
      case KishaKata.suuji:
        kai(
          saSeed <= ks * 5
              ? 'シード権を分けた${kinsaMoji(saSeed)}は、${hitoriAtariMoji(saSeed, ks)}。$ks区間のどこか一つで変わっていた数字です'
              : '${nk.mei}と${mr.mei}の${saMoji(saSeed)}差。最終区で生まれた差というより、$ks区間の積み重ねの差ですね',
        );
      case KishaKata.joukei:
        // 滑り込んだアンカー(守り切ったときは、逃したアンカー)の因縁
        final _Koma jx = nkGyakuten ? nk : mr;
        final SenshuData? js = jx.s;
        final List<Innen> ji = js == null ? [] : senshuInnen(k, js, kk, kj: jx.kukanJuni, kekka: owatta);
        final _Hashiri? jh = js == null ? null : _hashiriYomu(js, kk);
        if (js != null && ji.isNotEmpty && ji.first.ten >= 45) {
          kai(
            nkGyakuten
                ? '${myouji(js.name)}、${ji.first.kotoba}。その思いが、最後の1枠を引き寄せましたね'
                : '${myouji(js.name)}は${ji.first.bun.replaceAll('。', '')}。今日は届きませんでしたが、この悔しさは必ず次につながります',
          );
        } else if (js != null && jh != null && nkGyakuten && jh.kiwaYoi != null) {
          kai('${myouji(js.name)}の${jh.kiwaYoi}が、この区間の選手の中で際立っていました。最後の1枠を引き寄せたのは、そこです');
        } else if (js != null && jh != null && !nkGyakuten && jh.kiwaWarui != null) {
          kai('${myouji(js.name)}は${jh.kiwaWarui}で差をつけられました。それでも、たすきを運び切った走りは次につながります');
        } else {
          kai('優勝のテープと同じくらい、この1枠には重みがあります。${nk.mei}は来年、予選会を走らずに済むんです');
        }
      case KishaKata.karakuchi:
        // 逃した大学の、一番悪かった区間
        int warukuKk = -1;
        int warukuJuni = -1;
        for (int i = 0; i < ks; i++) {
          final List<_Koma> ki = i == kk ? jun : _kukanKoma(k, i);
          for (final _Koma x in ki) {
            if (x.u.id == mr.u.id && x.kukanJuni > warukuJuni) {
              warukuJuni = x.kukanJuni;
              warukuKk = i;
            }
          }
        }
        if (warukuKk >= 0 && warukuKk < kk) {
          kai('${mr.mei}は${kukanYobikata(k.gh, race, warukuKk, ks)}の区間${juniMoji(warukuJuni)}が響きました。シード権は最終区で失ったのではなく、あそこで失っていたんです');
        } else {
          kai('${mr.mei}はアンカーに差を詰める力が残っていませんでした。シード権は$ks人で取るものだ、ということですね');
        }
    }
  }

  // 本文: 区間賞
  if (kukanshou.s != null) {
    final int ksa = kjJun.length >= 2 ? saByou(kjJun[1].kukanTime, kukanshou.kukanTime) : 0;
    final StringBuffer kb = StringBuffer();
    kb.write(
      w.erabu([
        'この区間を一番速く走ったのは${_yobi(w, kukanshou)}、${jikanMoji(kukanshou.kukanTime)}！',
        '区間トップは${_yobi(w, kukanshou)}。タイムは${jikanMoji(kukanshou.kukanTime)}です！',
      ]),
    );
    kb.write(ksa >= 20 ? '2位に${saMoji(ksa)}差をつける快走です。' : '2位とは${kinsaMoji(ksa)}の争いでした。');
    if (kukanshou.u.id != shui.u.id && kukanshou.tuukaMae > kukanshou.tuuka) {
      kb.write('${kukanshou.mei}は${juniMoji(kukanshou.tuukaMae)}から${juniMoji(kukanshou.tuuka)}に浮上しました。');
    }
    w.danraku(kb.toString());
    final _Hashiri kh = _hashiriYomu(kukanshou.s!, kk);
    if (kh.tsuyomi != null && kh.tsuyomi!.juni <= 2) {
      kai('${myouji(kukanshou.s!.name)}の${kh.tsuyomi!.mei}は、この区間の選手の中で${kh.tsuyomi!.juni == 1 ? '一番' : '2番目'}でした。コースに合った走りでしたね');
    } else if (kh.kiwaYoi != null) {
      kai('${myouji(kukanshou.s!.name)}は${kh.kiwaYoi}が、この区間の選手の中で際立っていました。区間賞は、そこから生まれましたね');
    } else if (kata == KishaKata.suuji && ksa >= 20) {
      kai('2位と${saMoji(ksa)}。$kyoriでこの差は、数字以上に大きいですよ');
    }
  }

  // 本文: 順位の動き(一番順位を上げた・下げた大学。自分の大学はあとで書く)
  if (kk > 0) {
    final StringBuffer ub = StringBuffer();
    if (ue != null && ueKazu >= 3 && ue.s != null && (my == null || ue.u.id != my.u.id)) {
      ub.write(
        '${_yobi(w, ue)}が$ueKazu人抜き！ ${juniMoji(ue.tuukaMae)}から${juniMoji(ue.tuuka)}に順位を上げました。',
      );
    }
    if (shita != null && shitaKazu >= 3 && shita.s != null && (my == null || shita.u.id != my.u.id)) {
      ub.write(
        '一方、${_yobi(w, shita)}は区間${juniMoji(shita.kukanJuni)}と苦しみ、${juniMoji(shita.tuukaMae)}から${juniMoji(shita.tuuka)}に後退。',
      );
    }
    // シード権のラインの出入り(当落線上の区間と最終区は、シード権の段落で書く)
    if (seedAri && !touraku && !saigo) {
      final List<String> iri = [for (final _Koma x in seedIri) x.mei];
      final List<String> de = [for (final _Koma x in seedDe) x.mei];
      if (iri.isNotEmpty) ub.write('シード権の${juniMoji(seedSuu - 1)}以内に${iri.join('、')}が入り、');
      if (de.isNotEmpty) ub.write('${iri.isEmpty ? 'シード権の${juniMoji(seedSuu - 1)}以内から' : ''}${de.join('、')}が圏外に下がりました。');
      if (iri.isNotEmpty && de.isEmpty) ub.write('圏外に下がった大学はありません。');
    }
    if (ub.isNotEmpty) {
      w.koMidashi('順位の動き');
      w.danraku(ub.toString());
      // 解説(大きく順位を上げた・下げた選手の、際立った能力)
      final _Koma? ueK = (ue != null && ueKazu >= 3 && ue.s != null && (my == null || ue.u.id != my.u.id)) ? ue : null;
      final _Koma? shitaK = (shita != null && shitaKazu >= 3 && shita.s != null && (my == null || shita.u.id != my.u.id)) ? shita : null;
      bool ugokiKaita = false;
      if (ueK != null && ueK.s != null) {
        final _Hashiri uh = _hashiriYomu(ueK.s!, kk);
        if (uh.kiwaYoi != null) {
          kai('${myouji(ueK.s!.name)}は${uh.kiwaYoi}が、この区間の選手の中で際立っていました。$ueKazu人抜きは、そこから来ています');
          ugokiKaita = true;
        }
      }
      if (!ugokiKaita && shitaK != null && shitaK.s != null && kata != KishaKata.joukei) {
        final _Hashiri sh = _hashiriYomu(shitaK.s!, kk);
        if (sh.kiwaWarui != null) {
          kai('${myouji(shitaK.s!.name)}は${sh.kiwaWarui}で差をつけられました。区間の相性は、配置の時点で決まっている部分もあります');
        }
      }
    }
  }

  // 本文: 当落線上(最終区の前の2区間。シード権のライン前後の順位と差、出入り)
  if (touraku && nokori != null && morashi != null) {
    final _Koma nk = nokori;
    final _Koma mr = morashi;
    w.koMidashi('当落線上');
    final StringBuffer tb = StringBuffer();
    tb.write('上位$seedSuu校のシード権争いです。圏内の最後、${juniMoji(seedSuu - 1)}は${nk.mei}。');
    if (seedSuu >= 2) {
      tb.write('${juniMoji(seedSuu - 2)}の${jun[seedSuu - 2].mei}とは${kinsaMoji(saByou(nk.ruikei, jun[seedSuu - 2].ruikei))}。');
    }
    final List<String> soto = [
      for (int i = seedSuu; i < n && i <= seedSuu + 1; i++)
        '${juniMoji(i)}の${jun[i].mei}が${kinsaMoji(saByou(jun[i].ruikei, nk.ruikei))}',
    ];
    tb.write('圏外からは${soto.join('、')}で追っています。');
    // 前の区間からの、ライン前後の差の変化
    final _Koma? nkMae = maeKoma(seedSuu - 1);
    final _Koma? mrMae = maeKoma(seedSuu);
    if (nkMae != null && mrMae != null) {
      final int saMae = saByou(mrMae.u.time_taikai_total[kk - 1], nkMae.u.time_taikai_total[kk - 1]);
      if (saSeed > saMae + 5) {
        tb.write('ライン前後の差は${saMoji(saMae)}から${saMoji(saSeed)}に広がりました。');
      } else if (saSeed + 5 < saMae) {
        tb.write('ライン前後の差は${saMoji(saMae)}から${kinsaMoji(saSeed)}に縮まりました！');
      }
    }
    // 出入り
    if (seedIri.isNotEmpty) tb.write('この区間で${seedIri.map((x) => x.mei).join('、')}が圏内に入り、');
    if (seedDe.isNotEmpty) tb.write('${seedIri.isEmpty ? 'この区間で' : ''}${seedDe.map((x) => x.mei).join('、')}が圏外に下がりました。');
    if (seedIri.isNotEmpty && seedDe.isEmpty) tb.write('圏外に下がった大学はありません。');
    w.danraku(tb.toString());
    // 解説(残りの区間で詰められる差か)
    final int nokoriKukan = ks - kk - 1;
    if (saSeed <= nokoriKukan * 30) {
      switch (kata) {
        case KishaKata.suuji:
          kai('ラインの${kinsaMoji(saSeed)}を残り$nokoriKukan区間で割ると、1区間あたり${(saSeed / nokoriKukan).toStringAsFixed(0)}秒。まだどちらに転んでもおかしくありません');
        case KishaKata.joukei:
          kai('ここからの${mr.mei}は、前の背中だけを見て走ることになります。シード権は、こういう区間で決まるんです');
        case KishaKata.karakuchi:
          kai('${nk.mei}は守りに入ると危ないですね。${kinsaMoji(saSeed)}は、残り$nokoriKukan区間なら簡単にひっくり返る差です');
      }
    } else {
      kai('${saMoji(saSeed)}差は、残り$nokoriKukan区間では簡単ではありません。圏外の大学は、一つでも順位を上げる走りに切り替える場面ですね');
    }
  }

  // 本文: 高校の同期対決・先輩と後輩(同じ高校の出身者が、別々の大学からこの区間を走ったとき。1.9.5)
  // 同じ学年(高校の同期)を先に選び、その中では区間順位の合計が良い組を1組だけ
  if (!koukouHyoujiNashi(k.kantoku)) {
    _Koma? koA;
    _Koma? koB;
    int koTen = 1 << 30;
    for (int i = 0; i < jun.length; i++) {
      final SenshuData? senA = jun[i].s;
      if (senA == null) continue;
      // 留学生も、日本の高校の出身なら入る(1.9.5)
      final KoukouJouhou? jA = koukouHyoujiJouhou(senA.samusataisei, senA.hirou, k.kantoku);
      if (jA == null) continue;
      final int kouNo = jA.koukou;
      for (int i2 = i + 1; i2 < jun.length; i2++) {
        final SenshuData? senB = jun[i2].s;
        if (senB == null) continue;
        final KoukouJouhou? jB = koukouHyoujiJouhou(senB.samusataisei, senB.hirou, k.kantoku);
        if (jB == null || jB.koukou != kouNo) continue;
        final int ten = jun[i].kukanJuni + jun[i2].kukanJuni + (senA.gakunen == senB.gakunen ? 0 : 1000);
        if (ten < koTen) {
          koTen = ten;
          koA = jun[i];
          koB = jun[i2];
        }
      }
    }
    final _Koma? ka = koA;
    final _Koma? kb = koB;
    if (ka != null && kb != null && ka.s != null && kb.s != null) {
      final SenshuData senA = ka.s!;
      final SenshuData senB = kb.s!;
      final String kou = koukouMeiMoji(KoukouJouhou.yomu(senA.samusataisei));
      final bool douki = senA.gakunen == senB.gakunen;
      // 区間順位の良い方を先に書く
      final _Koma yoi = ka.kukanJuni <= kb.kukanJuni ? ka : kb;
      final _Koma ato = identical(yoi, ka) ? kb : ka;
      final String juniBun =
          '区間順位は${myouji(yoi.s!.name)}が${juniMoji(yoi.kukanJuni)}、${myouji(ato.s!.name)}が${juniMoji(ato.kukanJuni)}です。';
      if (douki) {
        w.koMidashi('高校の同期対決');
        w.danraku(
          '$kouで同じ学年だった${_yobi(w, yoi)}と${_yobi(w, ato)}が、別々のたすきを背負ってこの区間を走りました。$juniBun',
        );
        if (kata == KishaKata.joukei) {
          kai('高校のころは、同じたすきをつないでいた2人です。今日はお互いが一番意識する相手だったでしょうね');
        }
      } else {
        final _Koma senpai = senA.gakunen > senB.gakunen ? ka : kb;
        final _Koma kouhai = identical(senpai, ka) ? kb : ka;
        w.koMidashi('母校の先輩と後輩');
        w.danraku(
          '$kouの先輩と後輩が、この区間で顔を合わせました。先輩の${_yobi(w, senpai)}と、後輩の${_yobi(w, kouhai)}です。$juniBun',
        );
      }
    }
  }

  // 本文: 自分の大学
  if (my != null && my.s != null) {
    final SenshuData s = my.s!;
    final _Hashiri h = _hashiriYomu(s, kk);
    w.koMidashi('${my.mei}の${kk + 1}区');
    final String yobi = w.senshu(s);
    final StringBuffer mb = StringBuffer();
    // 最終区で、シード権のラインの前後2校以内なら、まずシード権の決着を伝える
    bool seedKaita = false;
    if (saigo && nokori != null && morashi != null && my.tuuka >= seedSuu - 2 && my.tuuka <= seedSuu + 1) {
      seedKaita = true;
      if (my.tuuka < seedSuu) {
        mb.write('${my.mei}、シード権確保です！ ${juniMoji(my.tuuka)}でゴール、圏外の${juniMoji(seedSuu)}の${morashi.mei}とは${kinsaMoji(saByou(morashi.ruikei, my.ruikei))}でした。');
        if (my.tuukaMae >= seedSuu) mb.write('${juniMoji(my.tuukaMae)}でたすきを受けてからの逆転です！');
      } else {
        mb.write('${my.mei}はシード権に届きませんでした。${juniMoji(my.tuuka)}でゴール、シード権の${juniMoji(seedSuu - 1)}の${nokori.mei}とは${kinsaMoji(saByou(my.ruikei, nokori.ruikei))}でした。');
        if (my.tuukaMae < seedSuu) mb.write('${juniMoji(my.tuukaMae)}でたすきを受けていましたが、圏外に押し出されました。');
      }
    }
    // 指示
    if (kk == 0) {
      if (h.siji == 1 && h.seikou != null) {
        // 飛び出しの様子は上の段落で書いたので、ここは指示と成否だけ
        mb.write(h.seikou! ? '飛び出しの指示どおり前に出た$yobi、狙いは当たりました。' : '飛び出しの指示どおり前に出た$yobiでしたが、狙いは外れました。');
      } else if (h.shuudan.isNotEmpty) {
        if (h.shuudan.contains('速すぎた')) {
          mb.write('$yobiは速い集団のペースについていき、後半に大きく失速してしまいました。');
        } else if (h.shuudan.contains('遅かった')) {
          mb.write('$yobiにとって集団のペースは遅く、持ち味を出し切れませんでした。');
        } else if (h.shuudan.contains('少しタイム得')) {
          mb.write('$yobiは集団の流れにうまく乗りました。');
        } else if (h.shuudan.contains('免れた')) {
          mb.write('$yobiは速い流れに最後まで食らいつきました。');
        } else if (h.shuudan.contains('自分で作った')) {
          mb.write('$yobiが自ら集団を引っ張りました。');
        }
      }
    } else {
      if (h.siji == 1 && h.seikou != null) {
        mb.write(h.seikou! ? '前半から突っ込む指示に、$yobiはしっかり応えました。' : '前半から突っ込む指示でしたが、$yobiは後半に苦しみました。');
      } else if (h.siji == 2 && h.seikou != null) {
        mb.write(h.seikou! ? '前半を抑える指示どおり、$yobiは後半に伸びました。' : '前半を抑える指示でしたが、$yobiは思うように上げられませんでした。');
      } else if (h.aseri) {
        mb.write('目標順位を下回ってたすきを受けた$yobi、焦りからか前半から突っ込み、後半に代償を払いました。');
      } else if (h.hitoiki) {
        mb.write('目標順位を上回る位置でたすきを受けた$yobi、少し気持ちが緩んだでしょうか。');
      }
    }
    // 結果
    final int d = kk == 0 ? 0 : my.tuukaMae - my.tuuka;
    if (seedKaita) {
      mb.write('アンカーの$yobiは区間${juniMoji(my.kukanJuni)}${d >= 3 ? '、$d人抜きの走り' : ''}でした。');
    } else if (kk == 0) {
      mb.write('${my.mei}は$yobiが区間${juniMoji(my.kukanJuni)}、${juniMoji(my.tuuka)}でたすきを渡しました。');
    } else if (d >= 3) {
      mb.write('$yobiは$d人を抜いて${juniMoji(my.tuuka)}に浮上！ 区間${juniMoji(my.kukanJuni)}の走りです！');
    } else if (d > 0) {
      mb.write('$yobiは${juniMoji(my.tuukaMae)}から${juniMoji(my.tuuka)}に順位を上げました。区間${juniMoji(my.kukanJuni)}。');
    } else if (d == 0) {
      mb.write('$yobiは${juniMoji(my.tuuka)}を守って${saigo ? 'ゴール' : 'たすきをつなぎました'}。区間${juniMoji(my.kukanJuni)}。');
    } else {
      mb.write('$yobiは区間${juniMoji(my.kukanJuni)}。${juniMoji(my.tuukaMae)}から${juniMoji(my.tuuka)}に順位を落としました。');
    }
    // トップ・目標・シードとの差
    final List<String> saList = [];
    if (my.tuuka > 0) saList.add('トップとは${kinsaMoji(saByou(my.ruikei, shui.ruikei))}');
    if (mokuhyouAri && my.tuuka != mokuhyou) {
      final _Koma line = jun[mokuhyou];
      saList.add(
        my.tuuka < mokuhyou
            ? '目標の${juniMoji(mokuhyou)}の${line.mei}に${saMoji(saByou(line.ruikei, my.ruikei))}先行'
            : '目標の${juniMoji(mokuhyou)}の${line.mei}まで${kinsaMoji(saByou(my.ruikei, line.ruikei))}',
      );
    }
    if (seedAri && !seedKaita && my.tuuka >= seedSuu) {
      saList.add('シード権の${juniMoji(seedSuu - 1)}まで${kinsaMoji(saByou(my.ruikei, jun[seedSuu - 1].ruikei))}');
    } else if (seedAri && !saigo && morashi != null && my.tuuka < seedSuu && my.tuuka >= seedSuu - 2) {
      saList.add('シード圏外の${juniMoji(seedSuu)}の${morashi.mei}とは${kinsaMoji(saByou(morashi.ruikei, my.ruikei))}');
    }
    if (saList.isNotEmpty) mb.write('${saList.join('、')}です。');
    w.danraku(mb.toString());
    // 解説(シード権の決着・見えている能力・因縁)
    final List<Innen> mi = senshuInnen(k, s, kk, kj: my.kukanJuni, kekka: owatta);
    final bool yoi = my.kukanJuni <= n ~/ 3;
    final bool warui = n >= 6 && my.kukanJuni >= (n * 3) ~/ 4;
    if (seedKaita && nokori != null && morashi != null) {
      // 監督の目線で、シード権の重さを語る(辛口は目標を下回ったときだけ)
      final bool totta = my.tuuka < seedSuu;
      final int sa = totta ? saByou(morashi.ruikei, my.ruikei) : saByou(my.ruikei, nokori.ruikei);
      final bool karakuchi = kata == KishaKata.karakuchi && mokuhyouAri && my.tuuka > mokuhyou;
      if (karakuchi) {
        kai(
          totta
              ? '取ったのは事実ですが、${kinsaMoji(sa)}は紙一重です。監督は、この差を来年の課題として受け止めるべきでしょう'
              : '届かなかった原因を最終区に求めるのは酷です。$ks区間のどこで差がついたのか、監督は目を背けずに見直す必要がありますね',
        );
      } else if (kata == KishaKata.suuji) {
        kai(
          totta
              ? '相手との${kinsaMoji(sa)}は、${hitoriAtariMoji(sa, ks)}。$ks人全員で取ったシード権ですね'
              : '${kinsaMoji(sa)}、${hitoriAtariMoji(sa, ks)}。どこか一つの区間で詰められた差だけに、監督としては悔やんでも悔やみきれないでしょう',
        );
      } else {
        kai(
          totta
              ? '監督の立場で言えば、シード権は来年の夏の過ごし方を変えます。予選会を走らずに済む、この差は数字以上に大きいですよ'
              : '監督にとって一番つらいのは、この差でしょう。来年は予選会からですが、この悔しさを知った選手は強くなりますよ',
        );
      }
    } else if (yoi && h.tsuyomi != null && h.tsuyomi!.juni <= 3) {
      kai('${myouji(s.name)}は${h.tsuyomi!.mei}がこの区間の選手の中で${h.tsuyomi!.juni}番目。それが順位に出ましたね');
    } else if (warui && h.yowami != null && h.yowami!.juni >= n - 2) {
      kai('${myouji(s.name)}は${h.yowami!.mei}で差をつけられました。この区間との相性が出てしまいましたね');
    } else if (yoi && h.kiwaYoi != null) {
      // 分析で際立っていた能力(見抜く力がついていなくても、区間順位の画面の「分析」で見えている)
      kai('${myouji(s.name)}は${h.kiwaYoi}が、この区間の選手の中で際立っていましたね。それが順位に出ました');
    } else if (warui && h.kiwaWarui != null) {
      kai('${myouji(s.name)}は${h.kiwaWarui}で差をつけられました。この区間との相性が出てしまいましたね');
    } else if (mi.isNotEmpty && mi.first.ten >= 45) {
      kai(yoi ? '${myouji(s.name)}、${mi.first.kotoba}、という走りでしたね' : '${myouji(s.name)}は${mi.first.bun.replaceAll('。', '')}。今日は苦しみましたが、この経験は次につながります');
    } else if (kata == KishaKata.karakuchi && warui && mokuhyouAri && my.tuuka > mokuhyou) {
      kai('区間${juniMoji(my.kukanJuni)}は厳しいですね。目標の${juniMoji(mokuhyou)}まで、残りの区間で取り返せる差かどうか');
    } else if (yoi) {
      kai(w.erabu(['落ち着いた走りでしたね。たすきを受けたときの位置より前で渡せたのは大きいです', '区間${juniMoji(my.kukanJuni)}。チームに流れを持ってきましたね']));
    }
  }

  // 本文: 学連選抜(走っていれば)
  if (gakurenKonnenAri(k.gh)) {
    final GakurenKukanKekka? g = gakurenKukanKekka(k.gh, kk);
    if (g != null) {
      final bool kantoku = k.jibunUniv != null && gakurenKantokuChuu(k.kantoku, k.jibunUniv!);
      w.koMidashi('学連選抜');
      final String gy = w.hito('G${g.senshu.id}', g.senshu.name, '${g.senshu.gakunen}年', '');
      // 1区でスタート直後に飛び出していれば、そのことも
      final String gTobidashi = (kk == 0 && g.senshu.startchokugotobidasiflag == 1)
          ? (g.senshu.startchokugotobidasiseikouflag == 1 ? 'スタート直後に飛び出し、狙いどおりの展開に持ち込みました。' : 'スタート直後に飛び出しましたが、後半に苦しみました。')
          : '';
      w.danraku(
        'オープン参加の学連選抜は$gy(${daigakuMeiMoji(g.shozoku)})が区間${juniMoji(g.kukanJuni)}相当。'
        '$gTobidashi'
        '通過は${juniMoji(g.tuukaJuni)}相当です。'
        '${kantoku && g.kukanJuni == 0 ? '監督の采配が光りました！' : ''}',
      );
    }
  }

  // 本文: 次の区間の見どころ(最終区のあとは、総括を記事に任せる)
  // 1.9.5: コースと区間記録・前回の区間賞、持ちタイムの顔ぶれ、当日変更で温存していたエースの投入、
  //  首位争いの読み、追い上げ候補、自分の大学の前後との比べ、型ごとの解説と、持ちタイム上位5人の表を足した。
  //  持ちタイムは展望記事の「各区間」と同じ種目で比べる(kukanHikakuShumoku)。
  //  終盤(次の区間が最後の3区間)は「シード権の行方」(アンカーの前は「最後の1枠へ」)も書く
  final List<KijiHyou> tsugiHyou = []; // 次の区間の表(順位の表のあとに付ける)
  if (!saigo) {
    final int tsugi = kk + 1;
    final double tsugiKyoriM = k.gh.kyori_taikai_kukangoto[race][tsugi];
    // 正月駅伝の往路を終えた直後のレース画面は、まだ復路の当日変更の前
    // (当日変更のあとや結果画面で読み直すときは、実際に走る選手で書く)
    final bool fukuroMae = ouroOwari && !owatta && k.gh.nowracecalckukan == kk + 1;
    w.koMidashi(ouroOwari ? '往路を終えて' : '次の${tsugi + 1}区へ');
    final StringBuffer nb = StringBuffer();
    if (ouroOwari) {
      nb.write('往路はここまで。${shui.mei}が往路優勝、2位の${ni.mei}とは${kinsaMoji(sa12)}です。復路のスタートは往路の差のままです。');
      // シード圏の状況(1文だけ。走者の比べは、復路の当日変更の前なのでしない)
      if (nokori != null && morashi != null) {
        nb.write('シード権争いは、往路の時点で${juniMoji(seedSuu - 1)}が${nokori.mei}、${juniMoji(seedSuu)}の${morashi.mei}とは${kinsaMoji(saSeed)}です。');
      }
    }
    // コースと区間記録
    final String tsugiMei = kukanYobikata(k.gh, race, tsugi, ks);
    nb.write('${ouroOwari ? '復路の' : ''}$tsugiMeiは${kmMoji(tsugiKyoriM)}。');
    bool saichou = ks >= 3;
    for (int i = 0; i < ks; i++) {
      if (i != tsugi && k.gh.kyori_taikai_kukangoto[race][i] >= tsugiKyoriM) saichou = false;
    }
    if (saichou) nb.write('この大会で一番長い区間です。');
    // 区間記録(結果画面で読み直すときは、今回出た記録を除く)
    final tsugiKiroku = kukanKiroku(k, tsugi, konkaiNozoku: true);
    if (tsugiKiroku != null) {
      final int? kaiSuu = tsugiKiroku.year > 0 ? k.kaiNoKazu(tsugiKiroku.year) : null;
      nb.write(
        '区間記録は${kaiSuu != null ? '第$kaiSuu回大会で' : ''}'
        '${fullMei(tsugiKiroku.name)}${tsugiKiroku.univ.isEmpty ? '' : '(${daigakuMeiMoji(tsugiKiroku.univ)})'}が'
        'マークした${jikanMoji(tsugiKiroku.time)}です。',
      );
    }
    // 次の区間を走る選手と、比べる種目
    final List<SenshuData> tsugiHashiru = [
      for (final SenshuData x in k.senshu)
        if (k.entry(x) == tsugi && x.univid >= 0 && x.univid < k.univ.length && k.shutsujou(k.univ[x.univid])) x,
    ];
    final int idx = kukanHikakuShumoku(k, tsugi, tsugiHashiru);
    // 参考に表に出す種目(区間で見る種目のうち、比べた種目のほかの最初のもの。なければ-1)
    int sankouIdx = -1;
    for (final int c in kukanShumoku(k.gh, race, tsugi)) {
      if (c != idx) {
        sankouIdx = c;
        break;
      }
    }
    final List<SenshuData> mochiJun = [
      for (final SenshuData x in tsugiHashiru)
        if (k.jikoBest(x, idx) < TEISUU.DEFAULTTIME) x,
    ]..sort((a, b) {
        final int c = k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx));
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    // 持ちタイムの区間内の順番(0から。記録がなければnull)
    int? mochiBan(SenshuData s) {
      final int i = mochiJun.indexWhere((x) => x.id == s.id);
      return i >= 0 ? i : null;
    }

    // 大学[x]の次の走者(見つからなければnull)
    SenshuData? tsugiNo(_Koma x) {
      for (final SenshuData s in tsugiHashiru) {
        if (s.univid == x.u.id) return s;
      }
      return null;
    }

    // 選手[s]の大学の、今の区間の終了時点の途中経過(たすきを受ける位置)
    _Koma? komaNo(SenshuData s) {
      for (final _Koma x in jun) {
        if (x.u.id == s.univid) return x;
      }
      return null;
    }

    // 持ちタイムを区間の距離に換算した差(秒。正なら[ato]のほうが速い。換算できなければnull)
    int? kansanSa(SenshuData mae, SenshuData ato) {
      final double? tm = _kansanTime(k, mae, idx, tsugiKyoriM);
      final double? ta = _kansanTime(k, ato, idx, tsugiKyoriM);
      if (tm == null || ta == null) return null;
      return (tm - ta).round();
    }

    // 前回の区間賞の選手(2人まで)
    int maeKukanshouKazu = 0;
    for (final SenshuData s in tsugiHashiru) {
      if (maeKukanshouKazu >= 2) break;
      if (k.kukanJuniMae(s, race, 1) != 0) continue;
      final int mk = k.entryMae(s, race, 1);
      if (mk < 0) continue;
      maeKukanshouKazu++;
      final String d = daigakuMeiMoji(k.univ[s.univid].name);
      nb.write(
        mk == tsugi
            ? '前回この区間で区間賞の$d・${w.senshu(s)}は、2年連続の区間賞を狙います。'
            : '前回${mk + 1}区で区間賞の$d・${w.senshu(s)}が、今回はこの区間を任されました。',
      );
    }
    w.danraku(nb.toString());

    // 持ちタイムの顔ぶれ
    final StringBuffer fb = StringBuffer();
    if (fukuroMae) {
      fb.write('${tsugi + 1}区の区間エントリーで見ていきます。復路のスタート前の当日変更で、走る選手が変わることもあります。');
    }
    if (mochiJun.isNotEmpty) {
      final SenshuData top = mochiJun.first;
      fb.write(
        '${kijiShumokuMei[idx]}の持ちタイムトップは、${jikanMoji(k.jikoBest(top, idx))}の'
        '${daigakuMeiMoji(k.univ[top.univid].name)}・${w.senshu(top)}です。',
      );
      // 持ちタイムトップの選手の因縁(点の高いものだけ)
      final List<Innen> ai = senshuInnen(k, top, tsugi, kekka: false);
      if (ai.isNotEmpty && ai.first.ten >= 55) fb.write(ai.first.bun);
      final List<String> tsuzuku = [
        for (final SenshuData s in mochiJun.skip(1).take(2))
          '${daigakuMeiMoji(k.univ[s.univid].name)}・${w.senshu(s)}',
      ];
      if (tsuzuku.isNotEmpty) fb.write('${tsuzuku.join('、')}が続きます。');
    }
    // 当日変更で、補欠に温存していたエースを投入した大学(2校まで)
    int aceKazu = 0;
    for (final _Koma x in jun) {
      if (aceKazu >= 2) break;
      final SenshuData? h = tsugiNo(x);
      if (h == null) continue;
      final List<SenshuData?> kukanSenshu = List<SenshuData?>.filled(ks, null);
      kukanSenshu[tsugi] = h;
      final ToujituJijou? tj = toujituJijou(k, x.u, kukanSenshu)[tsugi];
      if (tj == null || !tj.onzonAce) continue;
      aceKazu++;
      final int? ban = mochiBan(h);
      fb.write('${x.mei}は、補欠に温存していたエースの${w.senshu(h)}を、${tj.fukuro ? '復路のスタート前の' : ''}当日変更でこの区間に投入しました！');
      if (ban != null) fb.write('持ちタイムは区間${ban + 1}番目です。');
    }
    if (fb.isNotEmpty) w.danraku(fb.toString());

    // 首位争いの読みと、追い上げ候補
    final StringBuffer yb = StringBuffer();
    final SenshuData? shuiTsugi = tsugiNo(shui);
    final SenshuData? niTsugi = tsugiNo(ni);
    final int? shuiBan = shuiTsugi == null ? null : mochiBan(shuiTsugi);
    final int? niBan = niTsugi == null ? null : mochiBan(niTsugi);
    int? shuiKansanSa; // 首位と2位の走者の、換算した持ちタイムの差(正なら2位の走者が速い)
    if (shuiTsugi != null && niTsugi != null && shuiBan != null && niBan != null) {
      shuiKansanSa = kansanSa(shuiTsugi, niTsugi);
      yb.write(
        '首位でたすきを受ける${shui.mei}は${w.senshu(shuiTsugi)}、持ちタイムは区間${shuiBan + 1}番目。'
        '${kinsaMoji(sa12)}で追う${ni.mei}は${w.senshu(niTsugi)}、${niBan + 1}番目です。',
      );
      if (niBan < shuiBan) {
        final int? ksa = shuiKansanSa;
        if (ksa != null && ksa >= sa12) {
          yb.write('持ちタイムどおりなら、首位が入れ替わる計算です。');
        } else if (sa12 <= 30) {
          yb.write('持ちタイムでは${ni.mei}が上。首位が入れ替わる可能性もあります。');
        } else {
          yb.write('持ちタイムでは${ni.mei}が上。どこまで差を詰めるか注目です。');
        }
      } else {
        yb.write('持ちタイムでも${shui.mei}が上回り、リードを広げる展開も見えます。');
      }
    }
    // 追い上げ候補(持ちタイム上位3人のうち、5位以下か、トップから1分以上離れてたすきを受ける選手。
    // 首位・2位の大学と自分の大学は、ほかの段落で書くので除く)
    for (final SenshuData s in mochiJun.take(3)) {
      final _Koma? x = komaNo(s);
      if (x == null || x.tuuka <= 1) continue;
      if (my != null && x.u.id == my.u.id) continue;
      if (x.tuuka < 4 && saByou(x.ruikei, shui.ruikei) < 60) continue;
      final int ban = mochiBan(s) ?? 0;
      yb.write(
        '${juniMoji(x.tuuka)}でたすきを受ける${x.mei}の${w.senshu(s)}は、持ちタイム区間${ban + 1}番目。'
        '${w.erabu(['どこまで順位を上げてくるか、注目です。', '前を行く大学には怖い存在です。'])}',
      );
      break;
    }
    if (yb.isNotEmpty) w.danraku(yb.toString());

    // 自分の大学(前後の大学との差と、次の走者どうしの持ちタイムの比べ)
    if (my != null) {
      final _Koma me = my;
      final SenshuData? myTsugi = tsugiNo(me);
      if (myTsugi != null) {
        final StringBuffer mb = StringBuffer();
        final int? mj = mochiBan(myTsugi);
        final String mochiKakko = mj != null ? '(持ちタイムは区間内${mj + 1}番目)' : '';
        mb.write(
          fukuroMae
              ? '${me.mei}の${tsugi + 1}区には、${w.senshu(myTsugi)}$mochiKakkoがエントリーされています。'
              : '${me.mei}は${w.senshu(myTsugi)}$mochiKakkoにたすきが渡ります。',
        );
        final List<Innen> ti = senshuInnen(k, myTsugi, tsugi, kekka: false);
        if (ti.isNotEmpty && ti.first.ten >= 45) mb.write(ti.first.bun);
        // 前を行く大学(2位なら、首位争いの段落で書いたので書かない)
        if (me.tuuka >= 2) {
          final _Koma mae = jun[me.tuuka - 1];
          final SenshuData? maeS = tsugiNo(mae);
          final int sa = saByou(me.ruikei, mae.ruikei);
          final int? maeBan = maeS == null ? null : mochiBan(maeS);
          mb.write('前を行く${mae.mei}とは${kinsaMoji(sa)}。');
          if (maeS != null && mj != null && maeBan != null) {
            if (mj < maeBan) {
              final int? ksa = kansanSa(maeS, myTsugi);
              mb.write(
                ksa != null && ksa >= sa
                    ? '持ちタイムどおりなら、追いつける計算です。'
                    : '持ちタイムでは${myouji(myTsugi.name)}が上です。',
              );
            } else {
              mb.write('持ちタイムでは${mae.mei}の${myouji(maeS.name)}が上。食らいついていきたいところです。');
            }
          }
        }
        // 後ろの大学(首位のときは、首位争いの段落で書いたので書かない。30秒以内のときだけ)
        if (me.tuuka >= 1 && me.tuuka + 1 < n) {
          final _Koma ato = jun[me.tuuka + 1];
          final SenshuData? atoS = tsugiNo(ato);
          final int sa = saByou(ato.ruikei, me.ruikei);
          final int? atoBan = atoS == null ? null : mochiBan(atoS);
          if (sa <= 30) {
            mb.write('後ろの${ato.mei}とは${kinsaMoji(sa)}。');
            if (atoS != null && atoBan != null && (mj == null || atoBan < mj)) {
              mb.write('持ちタイムでは${ato.mei}の${myouji(atoS.name)}が上で、背後にも気を配りたい場面です。');
            }
          }
        }
        w.danraku(mb.toString());
      }
    }

    // 解説(型ごと)
    final KukanTokuchou tsugiTokuchou = kukanTokuchou(k.gh, race, tsugi);
    if (kata == KishaKata.suuji && my != null && mokuhyouAri && my.tuuka > mokuhyou) {
      final int nokoriKukansuu = ks - tsugi;
      final int sa = saByou(my.ruikei, jun[mokuhyou].ruikei);
      kai('目標の${juniMoji(mokuhyou)}まで${kinsaMoji(sa)}。残り$nokoriKukansuu区間ですから、1区間あたり${(sa / nokoriKukansuu).toStringAsFixed(0)}秒ずつ詰めれば届く計算です');
    } else if (kata == KishaKata.joukei && my != null && my.tuuka <= 2 && !saigo) {
      kai('${my.mei}は${juniMoji(my.tuuka)}。ここからは、たすきの重さが変わってきますよ');
    } else if (kata == KishaKata.suuji && shuiTsugi != null && niTsugi != null && shuiKansanSa != null) {
      // 首位と2位の走者の持ちタイムを、区間の距離に換算して比べる
      final int ksa = shuiKansanSa;
      final String hikaku = '${kijiShumokuMei[idx]}の持ちタイムを区間の距離に直すと';
      if (ksa > 0) {
        kai(
          '$hikaku、${myouji(niTsugi.name)}が${myouji(shuiTsugi.name)}よりおよそ$ksa秒速い。'
          '${kinsaMoji(sa12)}なら、${ksa >= sa12 ? '持ちタイムどおりで逆転の計算です' : 'まだ首位が逃げ切る計算です'}',
        );
      } else if (ksa < 0) {
        kai('$hikaku、${myouji(shuiTsugi.name)}のほうがおよそ${-ksa}秒速い。${ni.mei}には、持ちタイム以上の走りが要ります');
      } else {
        kai('$hikaku、${myouji(shuiTsugi.name)}と${myouji(niTsugi.name)}はほぼ互角。${kinsaMoji(sa12)}が、そのまま勝負になります');
      }
    } else if (kata == KishaKata.joukei) {
      kai(_courseNoKotoba(tsugiTokuchou, anchor: tsugi == ks - 1 && ks >= 3, nagai: tsugiKyoriM > 15000));
    } else if (kata == KishaKata.karakuchi && mochiJun.length >= 2) {
      kai('持ちタイムの順番どおりにいかないのが駅伝です。表の上にいる選手ほど、重圧もかかりますからね');
    }

    // 表: 次の区間の持ちタイム上位5人(自分の大学の選手が入っていなければ、最後に1行足す)
    if (mochiJun.isNotEmpty) {
      String timeMoji(SenshuData s, int c) => k.jikoBest(s, c) < TEISUU.DEFAULTTIME ? jikanMoji(k.jikoBest(s, c)) : '-';
      String ukeMoji(SenshuData s) {
        final _Koma? x = komaNo(s);
        if (x == null) return '-';
        return x.tuuka == 0 ? juniMoji(0) : '${juniMoji(x.tuuka)} +${saMoji(saByou(x.ruikei, shui.ruikei))}';
      }

      List<String> gyouNo(String ban, SenshuData s) => [
            ban,
            '${fullMei(s.name)}(${s.gakunen})',
            daigakuMeiMoji(k.univ[s.univid].name),
            timeMoji(s, idx),
            if (sankouIdx >= 0) timeMoji(s, sankouIdx),
            ukeMoji(s),
          ];
      final List<SenshuData> top5 = mochiJun.take(5).toList();
      final List<List<String>> mg = [
        for (int i = 0; i < top5.length; i++) gyouNo('${i + 1}', top5[i]),
      ];
      if (my != null) {
        final SenshuData? myTsugi = tsugiNo(my);
        if (myTsugi != null && !top5.any((x) => x.id == myTsugi.id)) {
          final int? mj = mochiBan(myTsugi);
          mg.add(gyouNo(mj == null ? '-' : '${mj + 1}', myTsugi));
        }
      }
      tsugiHyou.add(
        KijiHyou(
          '${tsugi + 1}区の持ちタイム上位${top5.length}人${fukuroMae ? '(復路の当日変更の前)' : ''}',
          [
            '順',
            '選手',
            '大学',
            kijiShumokuMei[idx],
            if (sankouIdx >= 0) kijiShumokuMei[sankouIdx],
            'たすき受け',
          ],
          mg,
        ),
      );
    }

    // シード権の行方(次の区間が最後の3区間のとき。11月駅伝は6〜8区、正月駅伝は8〜10区の展望。1.9.5)
    // ライン前後2校ずつと、自分の大学(その外でもラインから1分以内なら)の次の走者を比べる。
    // 差が大きいときは1文だけにし(当落線上の段落で書いた区間では書かない)、表も付けない
    if (nokori != null && morashi != null && tsugi >= ks - 3 && !fukuroMae) {
      final _Koma nk = nokori;
      final _Koma mr = morashi;
      final bool anchorMae = tsugi == ks - 1;
      final int nokoriKukansuu = ks - tsugi; // 次の区間を含めた、残りの区間の数
      final bool ookii = saSeed > nokoriKukansuu * 30;
      if (ookii && !touraku) {
        w.koMidashi('シード権の行方');
        w.danraku(
          '${juniMoji(seedSuu - 1)}の${nk.mei}と${juniMoji(seedSuu)}の${mr.mei}の差は${saMoji(saSeed)}。'
          '残り$nokoriKukansuu区間で、圏外の大学には大きな巻き返しが必要です。',
        );
      } else if (!ookii) {
        w.koMidashi(anchorMae ? '最後の1枠へ' : 'シード権の行方');
        final StringBuffer sdb = StringBuffer();
        if (anchorMae) sdb.write('上位$seedSuu校のシード権、最後の1枠はアンカー勝負に持ち込まれました。');
        if (touraku) {
          sdb.write('ラインをはさんだ${kinsaMoji(saSeed)}の攻防、${tsugi + 1}区の顔ぶれです。');
        } else {
          sdb.write('上位$seedSuu校のシード権争いです。${juniMoji(seedSuu - 1)}の${nk.mei}と、${juniMoji(seedSuu)}の${mr.mei}の差は${kinsaMoji(saSeed)}。');
        }
        // ラインの内と外の走者の比べ
        final SenshuData? nkS = tsugiNo(nk);
        final SenshuData? mrS = tsugiNo(mr);
        final int? nkBan = nkS == null ? null : mochiBan(nkS);
        final int? mrBan = mrS == null ? null : mochiBan(mrS);
        String banMoji(int? b) => b == null ? '持ちタイムの記録はありません' : '持ちタイムは区間${b + 1}番目';
        if (nkS != null && mrS != null) {
          sdb.write('${nk.mei}は${w.senshu(nkS)}、${banMoji(nkBan)}。${mr.mei}は${w.senshu(mrS)}、${banMoji(mrBan)}。');
          if (nkBan != null && mrBan != null) {
            if (mrBan < nkBan) {
              final int? ksa = kansanSa(nkS, mrS);
              sdb.write(
                ksa != null && ksa >= saSeed
                    ? '持ちタイムどおりなら、ラインの内と外が入れ替わる計算です。'
                    : '持ちタイムでは${mr.mei}が上。差を詰めてきそうです。',
              );
            } else {
              sdb.write('持ちタイムでは${nk.mei}が上回ります。${mr.mei}には、持ちタイム以上の走りが要ります。');
            }
          }
        }
        // ライン前後のもう1校ずつ(1分以内のときだけ)
        if (seedSuu >= 2) {
          final _Koma x = jun[seedSuu - 2];
          final int sa = saByou(mr.ruikei, x.ruikei);
          if (sa <= 60) sdb.write('${juniMoji(seedSuu - 2)}の${x.mei}も、圏外の${mr.mei}とは${kinsaMoji(sa)}で、安全圏とは言えません。');
        }
        if (seedSuu + 1 < n) {
          final _Koma x = jun[seedSuu + 1];
          final int sa = saByou(x.ruikei, nk.ruikei);
          if (sa <= 60) sdb.write('${juniMoji(seedSuu + 1)}の${x.mei}も、ラインまで${kinsaMoji(sa)}で逆転を狙います。');
        }
        // 自分の大学(ライン前後2校の外で、ラインから1分以内のとき)
        bool myKuwaeru = false;
        if (my != null && (my.tuuka < seedSuu - 2 || my.tuuka > seedSuu + 1)) {
          if (my.tuuka < seedSuu) {
            final int sa = saByou(mr.ruikei, my.ruikei);
            if (sa <= 60) {
              myKuwaeru = true;
              sdb.write('${my.mei}も、圏外の${mr.mei}とは${kinsaMoji(sa)}です。');
            }
          } else {
            final int sa = saByou(my.ruikei, nk.ruikei);
            if (sa <= 60) {
              myKuwaeru = true;
              sdb.write('${my.mei}も、ラインまで${kinsaMoji(sa)}。まだ射程圏です。');
            }
          }
        }
        // 顔ぶれ(前回シード校が圏外に・予選会から来た大学が圏内に)
        final List<_Koma> mado = [
          for (int i = seedSuu - 2; i <= seedSuu + 1; i++)
            if (i >= 0 && i < n) jun[i],
        ];
        final int maeIdx = owatta ? 1 : 0; // 前回の順位の記録の位置(大会が終わると今回の順位が[0]に入る)
        final int yosenRace = race == 1 ? 3 : 4;
        final List<String> maeSeedSoto = [
          for (final _Koma x in mado)
            if (x.tuuka >= seedSuu && shutsujouJuni(juniRace(x.u, race, maeIdx)) && juniRace(x.u, race, maeIdx) < seedSuu) x.mei,
        ];
        final List<String> yosenUchi = [
          for (final _Koma x in mado)
            if (x.tuuka < seedSuu && shutsujouJuni(juniRace(x.u, yosenRace, 0))) x.mei,
        ];
        if (maeSeedSoto.isNotEmpty) sdb.write('前回シード校の${maeSeedSoto.join('、')}は、いま圏外です。');
        if (yosenUchi.isNotEmpty) sdb.write('予選会から勝ち上がった${yosenUchi.join('、')}は、圏内でたすきをつなぎます。');
        // アンカーの前は、ラインの内と外のアンカーの因縁も(点の高い方を1つ)
        if (anchorMae && nkS != null && mrS != null) {
          final List<Innen> nkI = senshuInnen(k, nkS, tsugi, kekka: false);
          final List<Innen> mrI = senshuInnen(k, mrS, tsugi, kekka: false);
          final int nkTen = nkI.isEmpty ? 0 : nkI.first.ten;
          final int mrTen = mrI.isEmpty ? 0 : mrI.first.ten;
          if (nkTen >= 45 || mrTen >= 45) {
            final bool nkHou = nkTen >= mrTen;
            final _Koma ix = nkHou ? nk : mr;
            final SenshuData isn = nkHou ? nkS : mrS;
            final Innen ii = nkHou ? nkI.first : mrI.first;
            sdb.write('${ix.mei}のアンカーは${myouji(isn.name)}。${ii.bun}');
          }
        }
        w.danraku(sdb.toString());
        // 解説(型ごと。当落線上の解説と同じことを言わないように)
        switch (kata) {
          case KishaKata.suuji:
            final int? ksa = (nkS != null && mrS != null) ? kansanSa(nkS, mrS) : null;
            if (ksa != null && nkS != null && mrS != null) {
              final String hikaku = '${kijiShumokuMei[idx]}の持ちタイムを区間の距離に直すと';
              if (ksa > 0) {
                kai(
                  '$hikaku、${myouji(mrS.name)}が${myouji(nkS.name)}よりおよそ$ksa秒速い。'
                  'ラインの${kinsaMoji(saSeed)}は、${ksa >= saSeed ? '持ちタイムどおりなら埋まる計算です' : 'それでもまだ残る計算です'}',
                );
              } else if (ksa < 0) {
                kai('$hikaku、${myouji(nkS.name)}のほうがおよそ${-ksa}秒速い。${mr.mei}には、持ちタイム以上の走りが要ります');
              } else {
                kai('$hikaku、2人はほぼ互角。ラインの${kinsaMoji(saSeed)}が、そのまま勝負になります');
              }
            } else if (saSeed > 0) {
              kai('ラインの${kinsaMoji(saSeed)}を${tsugi + 1}区だけで詰めるなら、1kmあたり${(saSeed / (tsugiKyoriM / 1000)).toStringAsFixed(1)}秒です');
            }
          case KishaKata.joukei:
            kai(
              anchorMae
                  ? 'アンカー同士の勝負は、前の背中が見えるかどうか。見えれば、脚は最後まで動きます'
                  : 'シード権のラインの前後は、沿道の声援も一段と大きくなります。その声が背中を押しますよ',
            );
          case KishaKata.karakuchi:
            kai(
              (nkBan != null && mrBan != null && mrBan < nkBan)
                  ? '${nk.mei}は、持ちタイムで劣る走者でラインを守ることになります。序盤の入り方次第ですね'
                  : '持ちタイムで勝っていても、ラインを背負って走る重圧は別物です。${nk.mei}も安心はできません',
            );
        }
        // 表: シード権争いの、次の区間の走者(ライン前後2校ずつと自分の大学)
        final List<_Koma> hyouKoma = List<_Koma>.of(mado);
        if (myKuwaeru && my != null) hyouKoma.add(my);
        hyouKoma.sort((a, b) => a.tuuka.compareTo(b.tuuka));
        final List<List<String>> sg = [];
        for (final _Koma x in hyouKoma) {
          final int sa = saByou(x.ruikei, nk.ruikei);
          final SenshuData? s = tsugiNo(x);
          final int? b = s == null ? null : mochiBan(s);
          sg.add([
            juniMoji(x.tuuka),
            x.mei,
            x.tuuka == seedSuu - 1 ? 'ライン' : (sa == 0 ? '0秒' : (x.tuuka < seedSuu ? '-${saMoji(sa)}' : '+${saMoji(sa)}')),
            s == null ? '-' : '${fullMei(s.name)}(${s.gakunen})',
            (s == null || b == null) ? '-' : '${jikanMoji(k.jikoBest(s, idx))}(${b + 1}番目)',
          ]);
          if (x.tuuka == seedSuu - 1) sg.add(['', '― シード権ライン ―', '', '', '']);
        }
        tsugiHyou.add(
          KijiHyou(
            'シード権争い・${tsugi + 1}区の走者',
            ['順位', '大学', 'ラインとの差', '${tsugi + 1}区の走者', '持ちタイム(${kijiShumokuMei[idx]})'],
            sg,
          ),
        );
      }
    }
  } else {
    w.koMidashi('ゴール');
    w.danraku(
      w.erabu([
        '$n校がそれぞれの思いを乗せてゴールに飛び込みました。${k.taikaiMei}、全$ks区間のたすきがつながりました。',
        '全$ks区間、$n校のたすきが無事につながりました。詳しい結果は、記事でお伝えします。',
      ]),
    );
    kai(kata == KishaKata.karakuchi ? '勝負の分かれ目は、派手な区間賞より、崩れなかった区間にありましたね' : '最後まで目が離せないレースでした。選手のみなさん、お疲れさまでした');
    // 中継席が選ぶ三賞とヒーローインタビュー(1.9.4)
    _sanshouToInterview(k, w, jun, my: my, kata: kata, owatta: owatta, kai: kai);
    w.danraku('${k.taikaiMei}の中継は、以上です。');
  }

  // 表: 区間終了時点の順位(上位10校と自分の大学)
  final List<List<String>> gyou = [];
  for (final _Koma x in jun) {
    if (x.tuuka >= 10 && (my == null || x.u.id != my.u.id)) continue;
    gyou.add([
      juniMoji(x.tuuka),
      x.mei,
      x.s == null ? '-' : '${fullMei(x.s!.name)}(${x.s!.gakunen})',
      juniMoji(x.kukanJuni),
      x.tuuka == 0 ? '-' : '+${saMoji(saByou(x.ruikei, shui.ruikei))}',
    ]);
  }
  final List<KijiHyou> hyou = [
    KijiHyou('${kk + 1}区終了時点の順位', ['順位', '大学', '${kk + 1}区の選手', '区間順位', 'トップ差'], gyou),
  ];
  // 表: シード権争い(最終区。ラインの前後2校ずつ)
  if (saigo && nokori != null) {
    final List<List<String>> sg = [];
    for (int i = seedSuu - 2; i <= seedSuu + 1; i++) {
      if (i < 0 || i >= n) continue;
      final _Koma x = jun[i];
      final int sa = saByou(x.ruikei, nokori.ruikei);
      sg.add([
        juniMoji(i),
        x.mei,
        i == seedSuu - 1 ? 'ライン' : (sa == 0 ? '0秒' : (i < seedSuu ? '-${saMoji(sa)}' : '+${saMoji(sa)}')),
        juniMoji(x.tuukaMae),
        juniMoji(x.kukanJuni),
      ]);
      if (i == seedSuu - 1) sg.add(['', '― シード権ライン ―', '', '', '']);
    }
    hyou.add(KijiHyou('シード権争い(上位$seedSuu校がシード権)', ['順位', '大学', 'ラインとの差', '最終区たすき受け', 'アンカー区間順位'], sg));
  }
  // 表: 次の区間の持ちタイム上位5人と、シード権争いの次の走者(1.9.5)
  hyou.addAll(tsugiHyou);
  return Kiji(
    category: '駅伝・実況',
    midashi: midashi,
    lead: lead.toString(),
    honbun: w.honbun,
    hyou: hyou,
    haishin: '${k.gh.year}年${k.gh.month}月${k.gh.day}日 ${kk + 1}区終了時点',
    kisha: '実況・$ana　解説・$kaisetsu',
    jibun: my != null,
    kekka: true,
    site: jikkyouSiteMei,
  );
}

// ------------------------------------------------------------
// 中継席が選ぶ三賞とヒーローインタビュー(最終区の実況の最後。1.9.4)
// ・殊勲賞: 優勝校の選手の中で、最後に首位に立った区間の選手。1区から首位を守り切ったときは
//   区間賞の選手、それもなければ2位との差を一番広げた区間の選手
// ・敢闘賞: 人抜きの数が最多の選手(同点なら区間順位)。1区で飛び出して逃げ切った(粘り切った)選手と、
//   急きょ区間に入って区間3位以内だった選手は加点して競わせる
// ・技能賞: 区間賞の中で、2位との差が距離あたりで一番大きかった選手。際立った能力があれば加点
// ・3人は別々の選手。学連選抜は対象外
// ・ヒーローインタビューは殊勲賞の選手にQ&A形式で3問。自分の大学の選手が三賞のどれかを取ったときは、
//   その選手にも2問(殊勲賞なら、ヒーローインタビューがその選手になる)
// ------------------------------------------------------------

/// 三賞の1つ
class _Shou {
  final String mei;

  /// 受賞者(その区間の途中経過)
  final _Koma x;

  /// 走った区間(0が1区)
  final int kukan;

  /// 理由の文(「。」なし)
  final String riyuu;

  const _Shou(this.mei, this.x, this.kukan, this.riyuu);
}

void _sanshouToInterview(
  KijiKankyou k,
  KijiKakite w,
  List<_Koma> jun, {
  required _Koma? my,
  required KishaKata kata,
  required bool owatta,
  required void Function(String) kai,
}) {
  final int ks = k.kukansuu;
  if (ks < 2 || jun.isEmpty) return;
  // 全区間の途中経過(最終区は渡されたもの)
  final List<List<_Koma>> zen = [
    for (int i = 0; i < ks; i++) i == ks - 1 ? jun : _kukanKoma(k, i),
  ];
  if (zen.any((l) => l.isEmpty)) return;
  _Koma? koma(int i, int univId) {
    for (final _Koma x in zen[i]) {
      if (x.u.id == univId) return x;
    }
    return null;
  }

  final UnivData win = jun[0].u;
  final Set<int> tsukatta = {}; // 受賞した選手のid

  // ---- 殊勲賞 ----
  _Shou? shukun;
  int lastLead = -1; // 優勝校が最後に首位に立った区間(1区から首位なら0)
  for (int i = 0; i < ks; i++) {
    final bool ima = zen[i][0].u.id == win.id;
    final bool mae = i > 0 && zen[i - 1][0].u.id == win.id;
    if (ima && !mae) lastLead = i;
  }
  _Koma? leadMae; // 首位に立った区間で、その前まで首位だった大学
  int saMaeHero = 0; // そのときの差
  if (lastLead > 0) {
    final _Koma? x = koma(lastLead, win.id);
    for (final _Koma y in zen[lastLead]) {
      if (y.tuukaMae == 0) leadMae = y;
    }
    if (x != null && x.s != null && leadMae != null) {
      saMaeHero = saByou(x.u.time_taikai_total[lastLead - 1], leadMae.u.time_taikai_total[lastLead - 1]);
      shukun = _Shou(
        '殊勲賞',
        x,
        lastLead,
        '${lastLead + 1}区で${juniMoji(x.tuukaMae)}から${leadMae.mei}をかわして首位に立ち、チームを優勝に導いた',
      );
    }
  }
  if (shukun == null) {
    // 1区から首位を守り切った: 区間賞の選手 → 2位との差を一番広げた区間の選手
    _Koma? kukanshou;
    int kukanshouKukan = -1;
    _Koma? hiroge;
    int hirogeKukan = -1;
    int hirogeSa = -1;
    for (int i = 0; i < ks; i++) {
      final _Koma? x = koma(i, win.id);
      if (x == null || x.s == null) continue;
      if (x.kukanJuni == 0 && kukanshou == null) {
        kukanshou = x;
        kukanshouKukan = i;
      }
      if (x.tuuka == 0 && (i == 0 || x.tuukaMae == 0) && zen[i].length >= 2) {
        final int ato = saByou(zen[i][1].ruikei, x.ruikei);
        int maeSa = 0;
        if (i > 0) {
          _Koma? niMae;
          for (final _Koma y in zen[i]) {
            if (y.tuukaMae == 1) niMae = y;
          }
          if (niMae != null) maeSa = saByou(niMae.u.time_taikai_total[i - 1], x.u.time_taikai_total[i - 1]);
        }
        if (ato - maeSa > hirogeSa) {
          hirogeSa = ato - maeSa;
          hiroge = x;
          hirogeKukan = i;
        }
      }
    }
    if (kukanshou != null) {
      shukun = _Shou('殊勲賞', kukanshou, kukanshouKukan, '首位を守り切った優勝校で、${kukanshouKukan + 1}区の区間賞');
    } else if (hiroge != null && hirogeSa > 0) {
      shukun = _Shou('殊勲賞', hiroge, hirogeKukan, '${hirogeKukan + 1}区で2位との差を${saMoji(hirogeSa)}広げ、優勝を引き寄せた');
    }
  }
  if (shukun != null) tsukatta.add(shukun.x.s!.id);

  // ---- 敢闘賞 ----
  _Shou? kantou;
  int kantouTen = 0;
  for (final _Koma u0 in jun) {
    final UnivData u = u0.u;
    final List<SenshuData?> kukanSenshu = [for (int i = 0; i < ks; i++) koma(i, u.id)?.s];
    final Map<int, ToujituJijou> jij = toujituJijou(k, u, kukanSenshu);
    for (int i = 0; i < ks; i++) {
      final _Koma? x = koma(i, u.id);
      if (x == null || x.s == null || tsukatta.contains(x.s!.id)) continue;
      final SenshuData s = x.s!;
      int ten = 0;
      String riyuu = '';
      final int nuki = i == 0 ? 0 : x.tuukaMae - x.tuuka;
      if (nuki >= 1) {
        ten += nuki * 10;
        riyuu = '${i + 1}区で$nuki人抜き、${juniMoji(x.tuukaMae)}から${juniMoji(x.tuuka)}に押し上げた';
      }
      if (i == 0 && s.startchokugotobidasiflag == 1 && s.startchokugotobidasiseikouflag == 1 && x.kukanJuni <= 2) {
        ten += 25;
        riyuu = '1区でスタート直後に飛び出し、${x.tuuka == 0 ? '逃げ切った' : '区間${juniMoji(x.kukanJuni)}で粘り切った'}';
      }
      final ToujituJijou? j = jij[i];
      if (j != null && j.kyuukyo && j.hairi.id == s.id && x.kukanJuni <= 2) {
        ten += 20;
        riyuu = '${j.riyuu == HazuretaRiyuu.taichouFuryou ? '体調を崩した仲間の穴を埋めて' : '急きょ区間に入って'}${i + 1}区で区間${juniMoji(x.kukanJuni)}';
      }
      if (ten <= 0) continue;
      // 同点なら区間順位の良いほう
      final int hikaku = ten * 100 - x.kukanJuni;
      if (hikaku > kantouTen) {
        kantouTen = hikaku;
        kantou = _Shou('敢闘賞', x, i, riyuu);
      }
    }
  }
  if (kantou != null) tsukatta.add(kantou.x.s!.id);

  // ---- 技能賞 ----
  _Shou? ginou;
  double ginouTen = -1;
  for (int i = 0; i < ks; i++) {
    final List<_Koma> kj = List<_Koma>.of(zen[i])..sort((a, b) => a.kukanJuni.compareTo(b.kukanJuni));
    if (kj.length < 2) continue;
    final _Koma x = kj[0];
    if (x.s == null || tsukatta.contains(x.s!.id)) continue;
    final int sa = saByou(kj[1].kukanTime, x.kukanTime);
    final double kyoriKm = k.gh.kyori_taikai_kukangoto[k.race].length > i ? k.gh.kyori_taikai_kukangoto[k.race][i] / 1000.0 : 0.0;
    if (kyoriKm <= 0) continue;
    final _Hashiri h = _hashiriYomu(x.s!, i);
    final double ten = sa / kyoriKm + (h.kiwaYoi != null ? 1.0 : 0.0);
    if (ten > ginouTen) {
      ginouTen = ten;
      ginou = _Shou(
        '技能賞',
        x,
        i,
        '${i + 1}区で2位に${kinsaMoji(sa)}をつける区間賞${h.kiwaYoi != null ? '。${h.kiwaYoi}が際立っていた' : ''}',
      );
    }
  }
  if (ginou != null) tsukatta.add(ginou.x.s!.id);

  final List<_Shou> shou = [];
  if (shukun != null) shou.add(shukun);
  if (kantou != null) shou.add(kantou);
  if (ginou != null) shou.add(ginou);
  if (shou.isEmpty) return;

  // ---- 三賞の発表 ----
  w.koMidashi('中継席が選ぶ三賞');
  w.danraku('中継席が選ぶ、今日の三賞です。');
  final int myId = my?.u.id ?? -1;
  _Shou? myShou;
  for (final _Shou x in shou) {
    w.danraku('${x.mei}は、${_yobi(w, x.x)}。${x.riyuu}。');
    if (x.x.u.id == myId) myShou = x;
  }
  if (myShou != null) {
    kai('${myShou.x.mei}の${myouji(myShou.x.s!.name)}が${myShou.mei}。監督にとっても、今日一番の収穫ではないでしょうか');
  } else {
    switch (kata) {
      case KishaKata.suuji:
        kai('三賞は、人抜きの数や2位との差の数字で選びました。数字は、走りの価値を正直に映しますね');
      case KishaKata.joukei:
        kai('3人とも、たすきを受けた瞬間の表情が違いました。賞は、その顔に贈られたものだと思います');
      case KishaKata.karakuchi:
        kai('賞は結果に対して出るものです。この3人は、気持ちではなく走りで選ばれました');
    }
  }

  // ---- ヒーローインタビュー(殊勲賞の選手。いなければ三賞の最初の選手) ----
  final _Shou hero = shukun ?? shou.first;
  final SenshuData hs = hero.x.s!;
  final String hy = myouji(hs.name);
  w.koMidashi('ヒーローインタビュー');
  w.danraku('${hero.mei}の${_yobi(w, hero.x)}に、ゴール地点で話を聞きました。');
  w.danraku('――おめでとうございます。今の気持ちは？');
  w.comment('$hy「${senshuKimochi(w, hero.x.u.id == win.id ? CommentBamen.yuushouKetteiSenshu : (hero.x.kukanJuni == 0 ? CommentBamen.kukanshou : CommentBamen.oinuki))}」');
  // 2問目: その場面を振り返る
  final List<Innen> hi = senshuInnen(k, hs, hero.kukan, kj: hero.x.kukanJuni, kekka: owatta);
  if (hero.x.u.id == win.id && lastLead > 0 && leadMae != null) {
    w.danraku('――${lastLead + 1}区、${leadMae.mei}を捉えた場面を振り返ってください。');
    w.comment(
      '$hy「${w.erabu([
        '${juniMoji(hero.x.tuukaMae)}でたすきを受けたとき、前の背中は見えていました。${saMoji(saMaeHero)}差なら行けると、自分に言い聞かせました',
        '監督からは、前だけを見ろと言われていました。${leadMae.mei}の選手に並んだときは、無心でした',
        '区間${juniMoji(hero.x.kukanJuni)}の走りができたのは、仲間がいい位置でつないでくれたからです。追う展開は得意なので、迷いはありませんでした',
      ])}」',
    );
  } else {
    w.danraku('――${hero.kukan + 1}区の走りを振り返ってください。');
    w.comment(
      '$hy「${w.erabu([
        '後ろは気にせず、自分のペースを守ることだけを考えました。区間${juniMoji(hero.x.kukanJuni)}は、結果としてついてきたものです',
        'たすきを受けた瞬間に、今日は行けると感じました。前で渡すことだけを考えて走りました',
        '苦しくなってからが勝負だと思っていました。最後まで脚が動いてくれて、よかったです',
      ])}」',
    );
  }
  // 3問目: 応援してくれた人へ(因縁があれば、その思いを添える)
  w.danraku('――最後に、応援してくれた人たちへ。');
  w.comment('$hy「${hi.isNotEmpty && hi.first.ten >= 45 ? '${hi.first.kotoba}。' : ''}${tsugiKotoba(w)}」');

  // ---- 自分の大学の受賞者にも(殊勲賞なら上のインタビューがその選手) ----
  if (myShou != null && myShou.x.s!.id != hs.id) {
    final SenshuData ms = myShou.x.s!;
    final String myy = myouji(ms.name);
    w.danraku('${myShou.mei}の${_yobi(w, myShou.x)}にも、話を聞きました。');
    w.danraku('――${myShou.mei}、おめでとうございます。');
    w.comment('$myy「${senshuKimochi(w, myShou.mei == '技能賞' ? CommentBamen.kukanshou : CommentBamen.hyoushou)}」');
    w.danraku('――監督には、どう報告しますか？');
    w.comment(
      '$myy「${w.erabu([
        'まず、ありがとうございましたと伝えます。この区間に置いてくれたのは監督なので',
        '賞よりも、チームの順位の話をされると思います。それでいいんです',
        '次はもっと上の順位で、と言われるはずです。自分もそのつもりです',
      ])}」',
    );
  }
}
