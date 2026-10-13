import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/oufuku_kiroku.dart'; // 往路・復路の成績(2.0.0)
import 'package:ekiden/kansuu/taikai_chouki.dart' show ouroRace, choukiNendo;

// ------------------------------------------------------------
// 正月駅伝の往路の記事(箱庭スポーツ。2.0.0)
//
// 正月駅伝の5区が終わったあと(往路のゴール)に、往路優勝を大きく取り上げる記事。
// ・レース画面の5区のあと(実況のカードの下)と、6区のスタート前の目標順位の確認の画面のカードから読める。
//   結果画面の記事でも読み返せる(結果の記事の一覧に入れる。kiji_kekka.dart)
// ・見出しは往路優勝(「○○が2年ぶり3度目の往路優勝」「○○、往路3連覇」)。往路優勝の回数・連覇・
//   「○年ぶり」は、往路・復路の成績(oufuku_kiroku.dart)で数える(2.0.0より前から遊んでいるデータは、
//   記録を始める前の分がないので「初」「○度目」と言い切らない)
// ・本文は、往路のゴールの場面・5区の区間賞・上位の差・シード圏・自分の大学・復路への見通し。往路の成績の表を付ける
// ・現実の新聞にならい、往路優勝は大きく、復路優勝は総合の記事の中で小さく扱う(復路優勝は kiji_kekka.dart)
// ・往路新記録なら見出しに書く(従来の往路記録は、正月駅伝のスタートのときに保存したもの。oufukuShinkiroku)
// ------------------------------------------------------------

/// 往路記録・復路記録の新記録か([race] 18・19、[time] 今回のタイム)と、従来の記録を何秒更新したか(2.0.0)
/// 従来の記録は、正月駅伝のスタートのときに保存したもの(oufuku_kiroku.dart の oufukuJurai)なので、
/// 大会のあとに記録を書き換えたあとでも比べられる。
/// 従来の記録がない(記録を始めた最初の正月駅伝など)ときは、新記録と書かない
({bool shin, int koushin}) oufukuShinkiroku(KijiKankyou k, int race, double time) {
  final int? jurai = oufukuJurai(k.kantoku, race);
  if (jurai == null) return (shin: false, koushin: 0);
  final int koushin = jurai - byou(time);
  return (shin: koushin > 0, koushin: koushin);
}

/// 記事の番号(乱数の種と、記者・配信時刻を決める。結果の記事の1〜7と重ならないように)
const int _no = 8;

/// 往路の大学1校分の結果
class _OuroUniv {
  final UnivData u;

  /// 1〜5区の各区間終了時点の累計タイム
  final List<double> ruikei;

  /// 往路の順位(0が1位)
  int juni = 0;

  _OuroUniv(this.u, this.ruikei);

  double get time => ruikei[ouroKukansuu - 1];

  double kukanTime(int kk) => kk == 0 ? ruikei[0] : ruikei[kk] - ruikei[kk - 1];

  String get mei => daigakuMei(u);
}

/// 正月駅伝の往路の記事(往路が終わっていなければ空)
/// [kirokuZumi] 今年の正月駅伝がもう記録されているか(結果画面。レース中の往路のあとはfalse)
List<Kiji> ouroKekkaKiji(KijiKankyou k, {required bool kirokuZumi}) {
  if (k.race != 2 || k.kukansuu != shougatsuKukansuu) return [];
  // レース中は、5区まで走り終えてから(それまでは往路の累計タイムがない)
  if (!kirokuZumi && k.gh.nowracecalckukan < ouroKukansuu) return [];
  final List<_OuroUniv> jun = [];
  for (final UnivData u in k.univ) {
    if (!k.shutsujou(u)) continue;
    if (u.time_taikai_total.length < ouroKukansuu) continue;
    final List<double> r = [
      for (int kk = 0; kk < ouroKukansuu; kk++) u.time_taikai_total[kk],
    ];
    if (r.any((t) => t <= 0 || t >= TEISUU.DEFAULTTIME)) continue;
    jun.add(_OuroUniv(u, r));
  }
  if (jun.length < 2) return [];
  jun.sort((a, b) {
    final int c = a.time.compareTo(b.time);
    return c != 0 ? c : a.u.id.compareTo(b.u.id);
  });
  for (int i = 0; i < jun.length; i++) {
    jun[i].juni = i;
  }
  return [_ouroKiji(k, jun, kirokuZumi: kirokuZumi)];
}

/// 区間[kk]の終了時点の順位(0が1位)
int _tuuka(List<_OuroUniv> jun, _OuroUniv x, int kk) {
  int n = 0;
  for (final _OuroUniv y in jun) {
    if (y.ruikei[kk] < x.ruikei[kk]) n++;
  }
  return n;
}

/// 区間[kk]を大学[u]で走った選手(見つからなければnull)
SenshuData? _sousha(KijiKankyou k, UnivData u, int kk) {
  for (final SenshuData s in k.senshu) {
    if (s.univid == u.id && k.entry(s) == kk) return s;
  }
  return null;
}

Kiji _ouroKiji(KijiKankyou k, List<_OuroUniv> jun, {required bool kirokuZumi}) {
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _no));
  const int ou = ouroKukansuu - 1; // 5区
  final _OuroUniv win = jun[0];
  final _OuroUniv ni = jun[1];
  final int sa = saByou(ni.time, win.time);
  // 1人あたり3秒以内を僅差、1人あたり20秒以上を大差(総合の記事と同じ考え方)
  final bool kinsa = sa <= ouroKukansuu * 3;
  final bool taisa = !kinsa && sa >= ouroKukansuu * 20;
  // 4区の終了時点の首位と、往路優勝の大学が首位に立った区間
  final int maeTuuka = _tuuka(jun, win, ou - 1);
  final bool gyakuten = maeTuuka > 0; // 5区で首位に立った
  int shuiKukan = 0; // 最後に首位に立った区間
  for (int kk = ou; kk >= 0; kk--) {
    if (_tuuka(jun, win, kk) != 0) {
      shuiKukan = kk + 1;
      break;
    }
  }
  final bool kanzen = shuiKukan == 0; // 1区から首位を譲らなかった
  final String go5 = kukanYobikata(k.gh, k.race, ou, k.kukansuu);
  final bool yama5 = kukanTokuchou(k.gh, k.race, ou) == KukanTokuchou.yamaNobori;
  // 往路優勝の回数・連覇・何年ぶり
  final OufukuYuushou y = oufukuYuushou(
    win.u,
    ouroRace,
    kirokuZumi: kirokuZumi,
    nendo: choukiNendo(k.gh),
  );
  final String yMoji = oufukuYuushouMoji(y);
  // 往路新記録か
  final ({bool shin, int koushin}) shin = oufukuShinkiroku(k, ouroRace, win.time);

  // 見出し
  String midashi1;
  if (y.hatsu) {
    midashi1 = w.erabu(['${win.mei}が初の往路優勝', '${win.mei}、悲願の往路初V']);
  } else if (y.renzoku >= 2) {
    midashi1 = w.erabu(['${win.mei}、往路${y.renzoku}連覇', '${win.mei}が往路${y.renzoku}連覇']);
  } else if (y.renzokuFumei) {
    midashi1 = '${win.mei}、往路の連覇続く';
  } else if (y.renzoku == 1 && y.buri != null && y.buri! >= 2) {
    midashi1 = '${win.mei}、${y.buri}年ぶり往路V';
  } else {
    midashi1 = w.erabu(['${win.mei}が往路優勝', '${win.mei}、往路を制す']);
  }
  String midashi2 = '';
  if (shin.shin) {
    midashi2 = '往路新記録';
  } else if (gyakuten) {
    midashi2 = yama5 ? '山登りで逆転' : '5区で逆転';
  } else if (kinsa) {
    midashi2 = '${kinsaMoji(sa)}の激戦制す';
  } else if (taisa) {
    midashi2 = '2位に${saMoji(sa)}差';
  } else if (kanzen) {
    midashi2 = '1区から首位譲らず';
  }
  final String midashi = midashi2.isEmpty ? midashi1 : '$midashi1　$midashi2';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は往路(1〜$ouroKukansuu区)が行われ、'
    '${win.mei}が${jikanMoji(win.time)}で$yMoji往路優勝を果たした。',
  );
  if (y.renzokuFumei) lead.write('往路の連覇を、さらに伸ばした。');
  if (shin.shin) {
    lead.write('従来の往路記録を${saMoji(shin.koushin)}更新する往路新記録だった。');
  }
  final SenshuData? s5 = _sousha(k, win.u, ou);
  if (gyakuten && s5 != null) {
    lead.write(
      '${maeTuuka + 1}位でたすきを受けた$go5の${w.senshu(s5)}が首位を奪い、往路のゴールに飛び込んだ。',
    );
  } else if (kanzen) {
    lead.write('1区から一度も首位を譲らなかった。');
  }
  lead.write(
    kinsa
        ? '2位の${ni.mei}とは${kinsaMoji(sa)}の大接戦だった。'
        : (taisa ? '2位の${ni.mei}に${saMoji(sa)}差をつけた。' : '2位は${ni.mei}で、その差は${saMoji(sa)}。'),
  );

  // 本文: 5区
  w.koMidashi(yama5 ? '山登り' : '5区');
  {
    final List<_OuroUniv> kj = List<_OuroUniv>.of(jun)
      ..sort((a, b) => a.kukanTime(ou).compareTo(b.kukanTime(ou)));
    final _OuroUniv t5 = kj[0];
    final SenshuData? r5 = _sousha(k, t5.u, ou);
    final StringBuffer sb = StringBuffer();
    if (r5 != null) {
      final int sa5 = saByou(kj[1].kukanTime(ou), t5.kukanTime(ou));
      sb.write(
        '$go5の区間賞は${w.senshu(r5, daigaku: true)}で、${jikanMoji(t5.kukanTime(ou))}。'
        '${sa5 <= 0 ? '2位とは1秒に満たない差だった。' : '区間2位に${saMoji(sa5)}差をつけた。'}',
      );
      final int mae = _tuuka(jun, t5, ou - 1);
      if (mae - t5.juni >= 3) {
        sb.write('${t5.mei}は${mae + 1}位から${t5.juni + 1}位まで順位を上げた。');
      }
    }
    if (s5 != null && t5.u.id != win.u.id && !gyakuten) {
      sb.write('${win.mei}は$go5の${w.senshu(s5)}が首位を守り切った。');
    }
    w.danraku(sb.toString());
  }

  // 本文: 上位の差
  w.koMidashi('上位');
  {
    final StringBuffer sb = StringBuffer();
    final List<String> ue = [
      for (int i = 2; i < jun.length && i < 5; i++)
        '${jun[i].juni + 1}位${jun[i].mei}(${saMoji(saByou(jun[i].time, win.time))}差)',
    ];
    if (ue.isNotEmpty) sb.write('3位以下は${ue.join('、')}と続いた。');
    // シード圏(10位以内)の境目
    const int seed = 10;
    if (jun.length > seed) {
      final _OuroUniv nokori = jun[seed - 1];
      final _OuroUniv soto = jun[seed];
      sb.write(
        'シード権のかかる10位には${nokori.mei}がつけ、11位の${soto.mei}とは'
        '${kinsaMoji(saByou(soto.time, nokori.time))}だった。',
      );
    }
    w.danraku(sb.toString());
  }

  // 本文: 自分の大学
  final UnivData? my = k.jibunUniv;
  _OuroUniv? myX;
  for (final _OuroUniv x in jun) {
    if (my != null && x.u.id == my.id) myX = x;
  }
  if (myX != null && myX.juni > 0) {
    w.danraku(
      '${myX.mei}は往路${myX.juni + 1}位で、トップの${win.mei}とは${saMoji(saByou(myX.time, win.time))}差だった。',
    );
  }

  // 本文: 復路へ
  w.koMidashi('復路へ');
  w.danraku(
    w.erabu([
      '復路は往路の差のままスタートする。${win.mei}を、${saMoji(sa)}差で${ni.mei}が追う。',
      '翌日の復路は、往路の差のままスタートする。${ni.mei}は${saMoji(sa)}差を追って、${win.mei}を捉えにいく。',
    ]),
  );

  // 往路の成績の表
  final double top = win.time;
  final List<List<String>> gyou = [
    for (final _OuroUniv x in jun)
      [
        juniMoji(x.juni),
        x.mei,
        jikanMoji(x.time),
        x.juni == 0 ? '-' : '+${saMoji(saByou(x.time, top))}',
      ],
  ];
  return Kiji(
    category: '駅伝・往路',
    midashi: midashi,
    lead: lead.toString(),
    honbun: w.honbun,
    hyou: [
      KijiHyou('往路の成績', ['順位', '大学', 'タイム', 'トップ差'], gyou),
    ],
    haishin: k.haishinMei(_no, asa: false),
    kisha: k.kishaMei(_no),
    jibun: false,
    kekka: true,
  );
}
