import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';

// ------------------------------------------------------------
// 駅伝(10月・11月・正月・カスタム)の結果の記事(1.9.2。結果画面の「ニュース記事」)
//
// 記事(出せるものだけ並べる)
//  1. トップ記事(優勝校): 連覇・初優勝・○年ぶり・三冠・大会新・逆転・独走・僅差などから
//     一番ニュース価値の高い切り口を見出しにする
//  2. 自分の大学の記事: 目標順位・シード権・過去最高・区間賞・大きく順位を上げた区間・
//     ブレーキ・当日変更・1年生・4年生など
//  3. 区間賞・新記録の記事: 区間新・2位との差が一番大きい区間賞・連続区間賞・1年生や留学生
//  4. シード権争いの記事(11月駅伝・正月駅伝)
//  5. 往路・復路の記事(正月駅伝)
//  6. 学連選抜の記事(正月駅伝で学連選抜が走ったとき)
//  7. 三大駅伝の振り返り(正月駅伝のあと。今季の三大駅伝と、過去5季の優勝校・三冠。1.9.3)
// 三大駅伝(1.9.3): トップ記事で三冠の連続、三冠・二冠を阻んだこと、優勝校が分かれた季を書き、
// 11月駅伝・正月駅伝のトップ記事には今季の三大駅伝の優勝校の表を付ける(kiji_kihon.dart の SandaiEkiden)
// ------------------------------------------------------------

/// 駅伝の結果の、大学1校分
class EkidenUnivKekka {
  final UnivData u;

  /// 区間ごとの累計タイム
  final List<double> ruikei;

  /// 区間ごとの区間タイム
  final List<double> kukanTime;

  /// 区間ごとの走った選手
  final List<SenshuData?> senshu;

  /// 区間ごとの通過順位(出場校の中。0が1位)
  final List<int> tuuka;

  /// 区間ごとの区間順位(出場校の中。0が1位)
  final List<int> kukanJuni;

  /// 最終順位(0が1位)
  int juni = 0;

  EkidenUnivKekka(this.u, this.ruikei, this.kukanTime, this.senshu)
    : tuuka = List<int>.filled(ruikei.length, 0),
      kukanJuni = List<int>.filled(ruikei.length, 0);

  double get time => ruikei.last;

  String get mei => daigakuMei(u);
}

/// 駅伝の結果(出場校全部)
class EkidenKekka {
  final KijiKankyou k;

  /// 最終順位の順
  final List<EkidenUnivKekka> jun;

  /// 区間ごとの、区間タイムの順
  final List<List<EkidenUnivKekka>> kukanJun;

  EkidenKekka._(this.k, this.jun, this.kukanJun);

  /// 結果を集める(出場校が2校より少ないときなどはnull)
  static EkidenKekka? tsukuru(KijiKankyou k) {
    final int ks = k.kukansuu;
    if (ks <= 0) return null;
    final List<EkidenUnivKekka> list = [];
    for (final UnivData u in k.univ) {
      if (!k.shutsujou(u)) continue;
      if (u.time_taikai_total.length < ks) continue;
      final List<double> ruikei = [
        for (int i = 0; i < ks; i++) u.time_taikai_total[i],
      ];
      if (ruikei.last <= 0 || ruikei.last >= TEISUU.DEFAULTTIME) continue;
      final List<double> kt = [
        for (int i = 0; i < ks; i++) i == 0 ? ruikei[0] : ruikei[i] - ruikei[i - 1],
      ];
      list.add(
        EkidenUnivKekka(u, ruikei, kt, List<SenshuData?>.filled(ks, null)),
      );
    }
    if (list.length < 2) return null;
    final Map<int, EkidenUnivKekka> byId = {for (final x in list) x.u.id: x};
    for (final SenshuData s in k.senshu) {
      final EkidenUnivKekka? x = byId[s.univid];
      if (x == null) continue;
      final int e = k.entry(s);
      if (e >= 0 && e < ks) x.senshu[e] = s;
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    for (int i = 0; i < list.length; i++) {
      list[i].juni = i;
    }
    final List<List<EkidenUnivKekka>> kukanJun = [];
    for (int kk = 0; kk < ks; kk++) {
      final List<EkidenUnivKekka> t = List<EkidenUnivKekka>.of(list)
        ..sort((a, b) => a.ruikei[kk].compareTo(b.ruikei[kk]));
      for (int i = 0; i < t.length; i++) {
        t[i].tuuka[kk] = i;
      }
      final List<EkidenUnivKekka> kj = List<EkidenUnivKekka>.of(list)
        ..sort((a, b) => a.kukanTime[kk].compareTo(b.kukanTime[kk]));
      for (int i = 0; i < kj.length; i++) {
        kj[i].kukanJuni[kk] = i;
      }
      kukanJun.add(kj);
    }
    return EkidenKekka._(k, list, kukanJun);
  }

  int get ks => k.kukansuu;

  int get n => jun.length;

  /// 自分の大学(出場していなければnull)
  EkidenUnivKekka? get jibun {
    for (final EkidenUnivKekka x in jun) {
      if (x.u.id == k.gh.MYunivid) return x;
    }
    return null;
  }

  /// 区間[kk]の終了時点で首位だった大学
  EkidenUnivKekka shui(int kk) {
    for (final EkidenUnivKekka x in jun) {
      if (x.tuuka[kk] == 0) return x;
    }
    return jun.first;
  }

  /// 区間[kk]の終了時点で[juni]番目(0が1位)だった大学
  EkidenUnivKekka tsuukaJuni(int kk, int juni) {
    for (final EkidenUnivKekka x in jun) {
      if (x.tuuka[kk] == juni) return x;
    }
    return jun.first;
  }

  /// 首位が入れ替わった回数
  int shuiKoutai() {
    int c = 0;
    for (int kk = 1; kk < ks; kk++) {
      if (shui(kk).u.id != shui(kk - 1).u.id) c++;
    }
    return c;
  }

  /// 最後に首位に立った区間(そこから最後まで首位。0なら1区からずっと首位)
  int shuiNiTattaKukan(EkidenUnivKekka x) {
    int k0 = ks - 1;
    while (k0 > 0 && x.tuuka[k0 - 1] == 0) {
      k0--;
    }
    return k0;
  }

  /// 区間[made]より前で、首位から一番離れていたときの差(秒)
  int saidaiBehind(EkidenUnivKekka x, int made) {
    int m = 0;
    for (int kk = 0; kk < made && kk < ks; kk++) {
      final int sa = saByou(x.ruikei[kk], shui(kk).ruikei[kk]);
      if (sa > m) m = sa;
    }
    return m;
  }

  /// 区間[kk]の区間賞と2位の差(秒)
  int kukanshouSa(int kk) {
    if (kukanJun[kk].length < 2) return 0;
    return saByou(kukanJun[kk][1].kukanTime[kk], kukanJun[kk][0].kukanTime[kk]);
  }

  /// シード権の数(11月駅伝8校・正月駅伝10校。ほかの大会はなし)
  int? get seedSuu {
    if (k.race == 1) return 8;
    if (k.race == 2) return 10;
    return null;
  }

  /// 往路の区間数(正月駅伝で6区間以上あるときだけ5区まで。それ以外はnull)
  int? get ouroKukansuu => (k.race == 2 && ks >= 6) ? 5 : null;

  /// 区間の呼び方
  String kukanMei(int kk) => kukanYobikata(k.gh, k.race, kk, ks);
}

// ------------------------------------------------------------
// 記事の入口
// ------------------------------------------------------------

/// 駅伝の結果の記事の一覧(並べる順)
List<Kiji> ekidenKekkaKiji(KijiKankyou k) {
  final EkidenKekka? e = EkidenKekka.tsukuru(k);
  if (e == null) return [];
  final List<Kiji> list = [];
  list.add(_topKiji(e));
  final Kiji? jibun = _jibunKiji(e);
  final Kiji? gakuren = _gakurenKiji(e);
  // 自分の大学が出ていないときは、学連選抜の監督をしていれば学連選抜の記事を上に
  if (jibun != null) {
    list.add(jibun);
  } else if (gakuren != null && _gakurenKantokuShita(k)) {
    list.add(gakuren);
  }
  final Kiji? kukanshou = _kukanshouKiji(e);
  if (kukanshou != null) list.add(kukanshou);
  final Kiji? seed = _seedKiji(e);
  if (seed != null) list.add(seed);
  final Kiji? ouro = _ouroFukuroKiji(e);
  if (ouro != null) list.add(ouro);
  if (gakuren != null && !list.contains(gakuren)) list.add(gakuren);
  final Kiji? sandai = _sandaiKiji(e);
  if (sandai != null) list.add(sandai);
  return list;
}

bool _gakurenKantokuShita(KijiKankyou k) {
  final UnivData? my = k.jibunUniv;
  if (my == null) return false;
  return gakurenKantokuChuu(k.kantoku, my);
}

/// 記事を作るときの共通の仕上げ
Kiji _kansei(
  KijiKankyou k,
  int no,
  KijiKakite w, {
  required String category,
  required String midashi,
  required String lead,
  List<KijiHyou> hyou = const [],
  bool jibun = false,
}) {
  return Kiji(
    category: category,
    midashi: midashi,
    lead: lead,
    honbun: w.honbun,
    hyou: hyou,
    haishin: k.haishinMei(no, asa: false),
    kisha: k.kishaMei(no),
    jibun: jibun,
    kekka: true,
  );
}

/// 総合成績の表
KijiHyou _sougouHyou(EkidenKekka e) {
  final int? ouro = e.ouroKukansuu;
  final double top = e.jun.first.time;
  final List<List<String>> gyou = [];
  for (final EkidenUnivKekka x in e.jun) {
    gyou.add([
      juniMoji(x.juni),
      x.mei,
      jikanMoji(x.time),
      x.juni == 0 ? '-' : '+${saMoji(saByou(x.time, top))}',
      if (ouro != null) juniMoji(x.tuuka[ouro - 1]),
    ]);
  }
  return KijiHyou(
    '総合成績',
    ['順位', '大学', 'タイム', 'トップ差', if (ouro != null) '往路'],
    gyou,
  );
}

// ------------------------------------------------------------
// 1. トップ記事(優勝校)
// ------------------------------------------------------------

Kiji _topKiji(EkidenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 1;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final EkidenUnivKekka win = e.jun[0];
  final EkidenUnivKekka ni = e.jun[1];
  final int sa = saByou(ni.time, win.time);
  // 1位と2位の差を、1人あたり(区間数で割った値)で見る(1.9.2)
  // 僅差は1人あたり3秒以内、大差は1人あたり20秒以上
  final bool kinsa = sa <= ks * 3;
  final bool taisa = !kinsa && sa >= ks * 20;

  // 事実を集める
  final int kaisuu = juniKaisuu(win.u, race, 0);
  final ({int kaisuu, bool kakutei}) rz = renzokuKakutei(
    win.u,
    race,
    0,
    (j) => j == 0,
    kaisuu,
  );
  final int renzoku = rz.kaisuu;
  // 連覇の数を言い切れないとき(残っている記録が全部優勝で、それより前にも優勝がある)は数を出さない
  final bool renzokuFumei = !rz.kakutei;
  final int? maeYuushou = saigoNoKai(win.u, race, 1, (j) => j == 0);
  final bool hatsu = kaisuu <= 1;
  // 今回が初めての開催(ゲームを始めた年など)なら、全校が初出場なので「初代王者」として書く
  final bool hatsuKaisai = hatsuKaisaiKekka(k, race);
  final String yuushouGo = race == 2 ? '総合優勝' : '優勝';
  final String kaisuuGo = hatsuKaisai
      ? yuushouGo
      : renzokuFumei
      ? '$kaisuu度目の$yuushouGo'
      : (hatsu
            ? (race == 2 ? '初の総合優勝' : '初優勝')
            : '${renzokuMoji(renzoku: renzoku, buri: maeYuushou, kaisuu: kaisuu)}$yuushouGo');
  final int juraiTaikai = k.kantoku.yobiint4.length > 20
      ? k.kantoku.yobiint4[20]
      : 0;
  final int koushin = juraiTaikai - byou(win.time);
  final bool taikaiShin =
      win.u.chokuzentaikai_zentaitaikaisinflag == 1 &&
      juraiTaikai > 0 &&
      juraiTaikai < 360000 &&
      koushin > 0;
  final int k0 = e.shuiNiTattaKukan(win);
  final bool kanzen = k0 == 0;
  final int behind = k0 > 0 ? e.saidaiBehind(win, k0) : 0;
  final int maeTuuka = k0 > 0 ? win.tuuka[k0 - 1] : 0;
  final bool sankan =
      race == 2 &&
      juniRace(win.u, 0, 0) == 0 &&
      juniRace(win.u, 1, 0) == 0;
  final bool nikan =
      !sankan &&
      ((race == 1 && juniRace(win.u, 0, 0) == 0) ||
          (race == 2 &&
              (juniRace(win.u, 0, 0) == 0 || juniRace(win.u, 1, 0) == 0)));
  final int kukanshouKazu = [
    for (int kk = 0; kk < ks; kk++)
      if (win.kukanJuni[kk] == 0) kk,
  ].length;
  // 三大駅伝(1.9.3): 三冠の連続、三冠・二冠を阻んだか、今季の優勝校
  final SandaiEkiden? sd = SandaiEkiden.tsukuru(k, kekka: true);
  final ({int kaisuu, bool kakutei})? sankanRz =
      (sankan && sd != null) ? sd.sankanRenzoku(win.u, 0) : null;
  final int sankanKai = win.u.sankankaisuu;
  final UnivData? y10 = sd?.yuushou(0, 0);
  final UnivData? y11 = sd?.yuushou(1, 0);
  // 三冠を狙った大学(10月駅伝・11月駅伝を制して、正月駅伝で敗れた)
  final UnivData? sankanNogashi =
      (race == 2 && y10 != null && y11 != null && y10.id == y11.id && y10.id != win.u.id)
      ? y10
      : null;
  // 二冠を狙った大学(10月駅伝を制して、11月駅伝で敗れた)
  final UnivData? nikanNogashi =
      (race == 1 && y10 != null && y10.id != win.u.id) ? y10 : null;
  EkidenUnivKekka? kekkaOf(UnivData u) {
    for (final EkidenUnivKekka x in e.jun) {
      if (x.u.id == u.id) return x;
    }
    return null;
  }

  // 見出し(一番ニュース価値の高い切り口)
  String midashi1;
  if (sankan) {
    if (sankanRz != null && sankanRz.kakutei && sankanRz.kaisuu >= 2) {
      midashi1 = w.erabu([
        '${win.mei}が${sankanRz.kaisuu}年連続の三冠',
        '${win.mei}、${sankanRz.kaisuu}年連続で三大駅伝制覇',
      ]);
    } else if (sankanKai >= 2) {
      midashi1 = '${win.mei}、$sankanKai度目の三冠';
    } else {
      midashi1 = w.erabu(['${win.mei}が三冠達成', '${win.mei}、三大駅伝完全制覇']);
    }
  } else if (hatsuKaisai) {
    midashi1 = w.erabu([
      '${win.mei}が初代王者に',
      '初開催の${k.raceMei}、${win.mei}が制す',
    ]);
  } else if (hatsu) {
    midashi1 = w.erabu([
      '${win.mei}が初優勝',
      '${win.mei}、悲願の初V',
      '${win.mei}が初の頂点',
    ]);
  } else if (renzokuFumei) {
    midashi1 = w.erabu([
      '${win.mei}、連覇続く$kaisuu度目V',
      '連覇を続ける${win.mei}が$kaisuu度目のV',
    ]);
  } else if (renzoku >= 2) {
    midashi1 = w.erabu([
      '${win.mei}が$renzoku連覇',
      '${win.mei}、$renzoku年連続$kaisuu度目V',
    ]);
  } else if (maeYuushou != null && maeYuushou >= 2) {
    midashi1 = w.erabu([
      '${win.mei}、$maeYuushou年ぶり$kaisuu度目V',
      '${win.mei}が$maeYuushou年ぶりの頂点',
    ]);
  } else {
    midashi1 = w.erabu(['${win.mei}が$kaisuu度目のV', '${win.mei}、$kaisuu度目の優勝']);
  }
  String midashi2 = '';
  if (sankanNogashi != null) {
    midashi2 = '${daigakuMei(sankanNogashi)}の三冠阻む';
  } else if (taikaiShin) {
    midashi2 = '大会新記録';
  } else if (behind >= 120) {
    midashi2 = '最大${saMoji(behind)}差を逆転';
  } else if (k0 == ks - 1 && ks >= 2) {
    midashi2 = w.erabu(['アンカー勝負で逆転', '最終区で逆転']);
  } else if (kinsa) {
    midashi2 = '${kinsaMoji(sa)}の激戦制す';
  } else if (taisa) {
    midashi2 = '2位に${saMoji(sa)}差の圧勝';
  } else if (kanzen && ks >= 3) {
    midashi2 = w.erabu(['1区から首位譲らず', '序盤から独走']);
  } else if (k0 > 0) {
    midashi2 = '${k0 + 1}区で首位奪う';
  }
  final String midashi = midashi2.isEmpty ? midashi1 : '$midashi1　$midashi2';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    race == 2 ? '${k.taikaiMei}は復路が行われ、' : '${k.taikaiMei}が行われ、',
  );
  lead.write('${win.mei}が${jikanMoji(win.time)}で$kaisuuGoを果たした。');
  if (hatsuKaisai) {
    lead.write('初めて開催された大会で、初代王者に輝いた。');
  }
  if (renzokuFumei) {
    lead.write('長く続く連覇を、さらに伸ばした。');
  }
  if (k.ichinenDake) {
    lead.write('今大会は、1年生だけが出場できる大会として行われた。');
  }
  if (sankan) {
    lead.write('10月駅伝、11月駅伝に続き、今季の三大駅伝をすべて制した。');
    if (sankanRz != null && sankanRz.kakutei && sankanRz.kaisuu >= 2) {
      lead.write(
        '三冠は${sankanRz.kaisuu}年連続${sankanKai > sankanRz.kaisuu ? 'で、通算$sankanKai度目' : ''}となった。',
      );
    } else if (sankanRz != null && !sankanRz.kakutei) {
      lead.write('三冠の連続をさらに伸ばし、通算$sankanKai度目の三冠となった。');
    } else if (sankanKai >= 2) {
      lead.write('$sankanKai度目の三冠となった。');
    }
    // 三冠がまだ珍しいデータのときだけ(全大学の通算が今回を含めて3回まで)
    if (sd != null && sd.sankanGoukei <= 3) lead.write('史上まれな偉業だ。');
  } else if (nikan) {
    if (race == 1) {
      lead.write('10月駅伝に続く今季二冠目となった。');
    } else {
      // 正月駅伝: どちらの大会に続く二冠目か(もう1つの大会の優勝校も書く)
      final bool juu = y10 != null && y10.id == win.u.id;
      final UnivData? hoka = juu ? y11 : y10;
      lead.write('${juu ? '10月駅伝' : '11月駅伝'}に続く今季二冠目となった。');
      if (hoka != null) {
        lead.write('${juu ? '11月駅伝' : '10月駅伝'}は${daigakuMei(hoka)}が制していた。');
      }
    }
  } else if (race == 2 && sankanNogashi == null && y10 != null && y11 != null) {
    // 10月駅伝と11月駅伝の優勝校が違い、どちらも正月駅伝で敗れた
    lead.write(
      '今季の三大駅伝は、10月駅伝を${daigakuMei(y10)}、11月駅伝を${daigakuMei(y11)}、'
      '正月駅伝を${win.mei}が制し、3校が1つずつ分け合った。',
    );
  }
  if (sankanNogashi != null) {
    final EkidenUnivKekka? x = kekkaOf(sankanNogashi);
    lead.write(
      x != null
          ? '10月駅伝、11月駅伝を制して三冠を狙った${daigakuMei(sankanNogashi)}は'
                '${juniMoji(x.juni)}に終わり、三冠はならなかった。'
          : '10月駅伝、11月駅伝を制した${daigakuMei(sankanNogashi)}の三冠はならなかった。',
    );
  } else if (nikanNogashi != null) {
    final EkidenUnivKekka? x = kekkaOf(nikanNogashi);
    lead.write(
      x != null
          ? '10月駅伝を制した${daigakuMei(nikanNogashi)}は${juniMoji(x.juni)}に終わり、'
                '今季の三大駅伝は優勝校が分かれた。'
          : '10月駅伝は${daigakuMei(nikanNogashi)}が制しており、今季の三大駅伝は優勝校が分かれた。',
    );
  }
  if (taikaiShin) {
    lead.write('従来の大会記録を${saMoji(koushin)}更新する大会新記録だった。');
  }
  if (kanzen) {
    lead.write(
      w.erabu([
        '1区から一度も首位を譲らない完勝だった。',
        '序盤から主導権を握り、そのまま押し切った。',
      ]),
    );
  } else {
    final SenshuData? r0 = win.senshu[k0];
    if (r0 != null) {
      lead.write(
        '${maeTuuka + 1}位でたすきを受けた${e.kukanMei(k0)}の${w.senshu(r0)}が首位を奪い、'
        '${k0 == ks - 1 ? 'そのままゴールに飛び込んだ' : 'そのまま逃げ切った'}。',
      );
    }
  }
  if (kinsa) {
    lead.write(
      ks >= 2
          ? '2位の${ni.mei}とは${kinsaMoji(sa)}。$ks人でつないで、${hitoriAtariMoji(sa, ks)}という大接戦だった。'
          : '2位の${ni.mei}とは${kinsaMoji(sa)}の大接戦だった。',
    );
  } else if (taisa) {
    lead.write(
      ks >= 2
          ? '2位の${ni.mei}には${saMoji(sa)}差をつけた。$ks人でつないで${hitoriAtariMoji(sa, ks)}をつける圧勝だった。'
          : '2位の${ni.mei}に${saMoji(sa)}差をつける圧勝だった。',
    );
  } else {
    lead.write(
      w.erabu([
        '2位の${ni.mei}とは${saMoji(sa)}差だった。',
        '${ni.mei}が${saMoji(sa)}差の2位に入った。',
      ]),
    );
  }

  // 本文: 序盤(1区のペースと1区の区間賞)
  w.koMidashi('序盤');
  final IkkuPaceKekka? pace = ikkuPaceKekkaYomu(k.kantoku, k.gh);
  final EkidenUnivKekka t1 = e.kukanJun[0][0];
  final SenshuData? s1 = t1.senshu[0];
  final StringBuffer joban = StringBuffer();
  if (pace != null &&
      pace.pacemakerId != null &&
      pace.pacemakerId! >= 0 &&
      pace.pacemakerId! < k.senshu.length) {
    final SenshuData pm = k.senshu[pace.pacemakerId!];
    joban.write(
      '1区は${w.senshu(pm, daigaku: true)}が集団を引っ張る'
      '${ikkuPaceMidashiMoji[pace.midashi]}で幕を開けた。',
    );
    // 予想と違う展開になったとき
    final int? yosouM = pace.yosouMidashi;
    if (yosouM != null && (yosouM - pace.midashi).abs() >= 2) {
      joban.write(
        '戦前の${ikkuPaceMidashiMoji[yosouM]}という予想とは違う流れになった。',
      );
    }
    if (pace.midashi >= 3 && pace.kazu[3] >= 2) {
      joban.write('速い流れについていけず、${pace.kazu[3]}人が後半に大きく失速した。');
    } else if (pace.midashi <= 1 && e.n >= 5) {
      final int sa5 = saByou(e.jun.firstWhere((x) => x.tuuka[0] == 4).ruikei[0], e.shui(0).ruikei[0]);
      if (sa5 <= 20) {
        joban.write('互いに出方をうかがう展開で、5位までが${saMoji(sa5)}差の中でたすきをつないだ。');
      }
    }
  }
  if (s1 != null) {
    final int sa1 = e.kukanshouSa(0);
    // 呼び方は先に決める(言い回しの候補を作るたびに呼ぶと、2回目から名字だけになるため)
    final String yobi1 = w.senshu(s1, daigaku: true);
    joban.write(
      w.erabu([
        sa1 <= 0
            ? '1区の区間賞は$yobi1で、2位とは1秒に満たない差の競り合いだった。'
            : '1区の区間賞は$yobi1で、2位に${saMoji(sa1)}差をつけた。',
        '1区は$yobi1が${jikanMoji(t1.kukanTime[0])}で区間賞を獲得した。',
      ]),
    );
  }
  w.danraku(joban.toString());

  // 本文: 勝負所
  w.koMidashi('勝負所');
  if (kanzen) {
    final StringBuffer sb = StringBuffer();
    sb.write('${win.mei}は1区から最後まで首位を守り抜いた。');
    if (kukanshouKazu >= 3) {
      sb.write('$ks区間中$kukanshouKazu区間で区間賞を獲得する圧倒的な強さだった。');
    } else if (kukanshouKazu >= 1) {
      sb.write('区間賞は$kukanshouKazu区間だったが、全員が大きく崩れなかった。');
    } else {
      sb.write('区間賞こそなかったが、全員が安定した走りでつないだ。');
    }
    w.danraku(sb.toString());
  } else {
    final SenshuData? r0 = win.senshu[k0];
    final EkidenUnivKekka maeShui = e.shui(k0 - 1);
    if (r0 != null) {
      final String yobi = w.senshu(r0);
      final StringBuffer sb = StringBuffer();
      sb.write(
        '勝負が動いたのは${e.kukanMei(k0)}だった。'
        '${maeShui.mei}から${saMoji(saByou(win.ruikei[k0 - 1], maeShui.ruikei[k0 - 1]))}差の'
        '${maeTuuka + 1}位でたすきを受けた$yobiが、区間${win.kukanJuni[k0] + 1}位の走りで首位に浮上した。',
      );
      if (behind >= 120) {
        sb.write('一時は首位から${saMoji(behind)}離されていたが、大逆転につなげた。');
      }
      w.danraku(sb.toString());
      w.comment(
        senshuComment(
          w,
          k0 == ks - 1
              ? CommentBamen.yuushouKetteiSenshu
              : (win.kukanJuni[k0] == 0
                    ? CommentBamen.kukanshou
                    : CommentBamen.oinuki),
          myouji(r0.name),
        ),
      );
      w.danraku(shusshinShumiBun(k, r0, w.r, myouji(r0.name)));
    }
  }
  final int koutai = e.shuiKoutai();
  if (koutai >= 3) {
    w.danraku(
      w.erabu([
        '首位は目まぐるしく入れ替わり、$koutai度の首位交代があった。',
        '最後まで目の離せない展開で、首位は$koutai度入れ替わった。',
      ]),
    );
  }
  // 優勝校の区間賞(勝負所で書いた選手以外)
  final List<String> hoka = [];
  for (int kk = 0; kk < ks; kk++) {
    if (win.kukanJuni[kk] != 0) continue;
    if (!kanzen && kk == k0) continue;
    final SenshuData? s = win.senshu[kk];
    if (s == null) continue;
    hoka.add('${kk + 1}区の${w.senshu(s)}');
    if (hoka.length >= 3) break;
  }
  if (hoka.isNotEmpty) {
    w.danraku('${win.mei}はほかにも${hoka.join('、')}が区間賞を獲得した。');
  }
  // アンカーのコメント(勝負所の選手と別のとき)
  final SenshuData? anchor = win.senshu[ks - 1];
  if (anchor != null && (kanzen || k0 != ks - 1) && ks >= 2) {
    w.comment(
      senshuComment(
        w,
        CommentBamen.yuushouKetteiSenshu,
        w.senshu(anchor),
      ),
    );
  }
  w.comment(kantokuComment(w, KantokuBamen.yuushou, win.u.id));

  // 本文: 1位と2位の差(僅差なら攻防、大差なら独走。1.9.2)
  if (kinsa) {
    _kinsaKoubou(e, w, sa, k0);
  } else if (taisa) {
    _dokusou(e, w, k0);
  }

  // 本文: 2位以下
  final StringBuffer ika = StringBuffer();
  bool sanKakizumi = false;
  if (kinsa) {
    // 2位の大学は「◯秒差の攻防」で書いたので、ここでは書かない
  } else if (taisa) {
    ika.write('2位には${ni.mei}が入った。');
    // 2位争いが僅差なら、その差も書く
    if (e.n >= 3) {
      final EkidenUnivKekka san = e.jun[2];
      final int sa23 = saByou(san.time, ni.time);
      if (sa23 <= ks * 3) {
        ika.write('3位の${san.mei}とは${kinsaMoji(sa23)}で、2位争いは最後までもつれた。');
        sanKakizumi = true;
      }
    }
  } else {
    ika.write('2位の${ni.mei}は');
    if (ni.tuuka.contains(0)) {
      ika.write('一時は首位に立ったが、最後は${saMoji(sa)}及ばなかった。');
    } else {
      ika.write('最後まで食い下がったが、${saMoji(sa)}届かなかった。');
    }
  }
  if (e.n >= 3 && !sanKakizumi) {
    final EkidenUnivKekka san = e.jun[2];
    ika.write('3位には${san.mei}が入った。');
  }
  // 前回王者
  for (final EkidenUnivKekka x in e.jun) {
    if (x.juni == 0) continue;
    if (juniRace(x.u, race, 1) == 0) {
      // 今回は優勝していないので、全期間の優勝回数は前回までの分
      final ({int kaisuu, bool kakutei}) mr = renzokuKakutei(
        x.u,
        race,
        1,
        (j) => j == 0,
        juniKaisuu(x.u, race, 0),
      );
      final int maeRenzoku = mr.kaisuu;
      ika.write(
        !mr.kakutei
            ? '前回王者の${x.mei}は${juniMoji(x.juni)}に終わり、長く続いた連覇が止まった。'
            : maeRenzoku >= 2
            ? '${maeRenzoku + 1}連覇を狙った前回王者の${x.mei}は${juniMoji(x.juni)}に終わった。'
            : '前回王者の${x.mei}は${juniMoji(x.juni)}で、連覇を逃した。',
      );
      break;
    }
  }
  // 初出場の大学
  final List<String> hatsuShutsujou = [
    for (final EkidenUnivKekka x in e.jun)
      if (shutsujouKaisuu(x.u, race) == 1) '${x.mei}(${juniMoji(x.juni)})',
  ];
  if (!hatsuKaisai && hatsuShutsujou.isNotEmpty && hatsuShutsujou.length <= 3) {
    ika.write('初出場の${hatsuShutsujou.join('、')}も力走した。');
  }
  // 区間新の数
  int kukanShin = 0;
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = e.kukanJun[kk][0].senshu[kk];
    if (s != null && s.chokuzentaikai_zentaikukansinflag == 1 && _juraiKukan(k, kk) != null) {
      kukanShin++;
    }
  }
  // 書くことがあるときだけ小見出しを出す(僅差のときは2位の大学を上で書いたので、空になることがある)
  if (ika.isNotEmpty || kukanShin >= 1) w.koMidashi('2位以下');
  w.danraku(ika.toString());
  if (kukanShin >= 1) {
    w.danraku(
      kukanShin >= 3
          ? '高速レースとなり、$kukanShin区間で区間新記録が生まれた。'
          : '区間新記録は$kukanShin区間で生まれた。',
    );
  }

  return _kansei(
    k,
    no,
    w,
    category: '駅伝',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      _sougouHyou(e),
      if (kinsa || taisa) _saSuiiHyou(e),
      // 今季の三大駅伝の優勝校(11月駅伝・正月駅伝。1.9.3)
      if (sd != null && race >= 1) sd.konkiHyou(),
    ],
    jibun: win.u.id == k.gh.MYunivid,
  );
}

/// 優勝の記事の「◯秒差の攻防」(1位と2位の差が1人あたり3秒以内のとき。1.9.2)
/// [sa] 1位と2位の差(秒)、[k0] 優勝校が最後に首位に立った区間
void _kinsaKoubou(EkidenKekka e, KijiKakite w, int sa, int k0) {
  final int ks = e.ks;
  final EkidenUnivKekka win = e.jun[0];
  final EkidenUnivKekka ni = e.jun[1];
  w.koMidashi('${kinsaMoji(sa)}の攻防');

  // アンカーにたすきが渡った時点の差と、最終区の攻防
  // (勝負所で、2位の大学から最終区で首位を奪ったことを書いたときは書かない)
  final StringBuffer sb = StringBuffer();
  final bool kakizumi = ks >= 2 && k0 == ks - 1 && e.shui(ks - 2).u.id == ni.u.id;
  final SenshuData? aw = win.senshu[ks - 1];
  final SenshuData? an = ni.senshu[ks - 1];
  if (ks >= 2 && !kakizumi && aw != null && an != null) {
    // 正なら優勝校が先行
    final int d = saByou(ni.ruikei[ks - 2], win.ruikei[ks - 2]);
    // 正なら優勝校のアンカーが速い
    final int ad = saByou(ni.kukanTime[ks - 1], win.kukanTime[ks - 1]);
    if (d > 0) {
      sb.write('アンカーにたすきが渡った時点で、${win.mei}は${ni.mei}に${saMoji(d)}先行していた。');
      if (ad < 0) {
        final String yn = w.senshu(an);
        final String yw = w.senshu(aw);
        sb.write('${ni.mei}の$ynが${saMoji(ad)}詰め寄ったが、$ywが逃げ切った。');
      } else {
        sb.write('アンカーの${w.senshu(aw)}は、そのリードを守り切ってゴールした。');
      }
    } else if (d < 0) {
      sb.write('アンカーにたすきが渡った時点では、${ni.mei}が${saMoji(d)}先行していた。');
      sb.write('${win.mei}の${w.senshu(aw)}が追い上げ、最終区で逆転した。');
    } else {
      sb.write('アンカーにたすきが渡った時点で、両校の差は1秒に満たなかった。');
      sb.write('最終区の勝負を制したのは、${win.mei}の${w.senshu(aw)}だった。');
    }
  }
  w.danraku(sb.toString());

  // 区間ごとの勝ち負けと、差が最も開いた区間
  int katchi = 0;
  int make = 0;
  int hiraki = -1;
  int hirakiSa = 0;
  for (int kk = 0; kk < ks; kk++) {
    // 正なら優勝校が速い
    final int s = saByou(ni.kukanTime[kk], win.kukanTime[kk]);
    if (s > 0) katchi++;
    if (s < 0) make++;
    if (s > hirakiSa) {
      hirakiSa = s;
      hiraki = kk;
    }
  }
  final StringBuffer sb2 = StringBuffer();
  if (ks >= 3) {
    sb2.write(
      make > katchi
          ? '区間ごとに比べると、${ni.mei}が速かったのは$make区間で、${win.mei}の$katchi区間を上回っていた。'
                'それでも、総合ではわずかに及ばなかった。'
          : '区間ごとに比べると、${win.mei}が速かったのは$katchi区間、${ni.mei}が速かったのは$make区間だった。',
    );
  }
  if (hiraki >= 0) {
    final SenshuData? sw = win.senshu[hiraki];
    final SenshuData? sn = ni.senshu[hiraki];
    if (sw != null && sn != null) {
      final String yw = w.senshu(sw);
      final String yn = w.senshu(sn);
      sb2.write(
        '2校の差が最も開いたのは${e.kukanMei(hiraki)}で、${win.mei}の$ywが区間${win.kukanJuni[hiraki] + 1}位、'
        '${ni.mei}の$ynが区間${ni.kukanJuni[hiraki] + 1}位と、${saMoji(hirakiSa)}の差がついた。',
      );
      // その区間を互角に走っていれば、2位の大学が逆転していた
      if (hirakiSa > sa) {
        sb2.write('この区間を互角に走っていれば、${ni.mei}が逆転していた計算になる。');
      }
    }
  }
  w.danraku(sb2.toString());
  w.comment(kantokuComment(w, KantokuBamen.kinsaJunyuushou, ni.u.id, kuyashii: true));
}

/// 優勝の記事の「独走」(1位と2位の差が1人あたり20秒以上のとき。1.9.2)
/// [k0] 優勝校が最後に首位に立った区間(そこから最後まで首位)
void _dokusou(EkidenKekka e, KijiKakite w, int k0) {
  final int ks = e.ks;
  final EkidenUnivKekka win = e.jun[0];
  final EkidenUnivKekka ni = e.jun[1];
  w.koMidashi('独走');
  final StringBuffer sb = StringBuffer();
  // 首位に立ってから、2番手との差が初めて1分を超えた区間(最終区は除く)
  int k60 = -1;
  int sa60 = 0;
  for (int kk = k0; kk < ks - 1; kk++) {
    final int d = saByou(e.tsuukaJuni(kk, 1).ruikei[kk], win.ruikei[kk]);
    if (d >= 60) {
      k60 = kk;
      sa60 = d;
      break;
    }
  }
  if (k60 >= 0) {
    sb.write('${win.mei}は${k60 + 1}区を終えた時点で2位に${saMoji(sa60)}差をつけ、独走態勢に入った。');
    // そのあとも、区間ごとに差が広がり続けたか
    bool hirogaru = true;
    int mae = sa60;
    for (int kk = k60 + 1; kk < ks; kk++) {
      final int d = saByou(e.tsuukaJuni(kk, 1).ruikei[kk], win.ruikei[kk]);
      if (d < mae) hirogaru = false;
      mae = d;
    }
    sb.write(hirogaru ? 'その後も差は広がる一方だった。' : 'その後も後続を寄せつけなかった。');
  }
  // 2位の大学との差が最も開いた区間
  int hiraki = -1;
  int hirakiSa = 0;
  for (int kk = 0; kk < ks; kk++) {
    final int s = saByou(ni.kukanTime[kk], win.kukanTime[kk]);
    if (s > hirakiSa) {
      hirakiSa = s;
      hiraki = kk;
    }
  }
  if (hiraki >= 0) {
    final SenshuData? sw = win.senshu[hiraki];
    if (sw != null) {
      sb.write(
        '2位の${ni.mei}との差が最も開いたのは${e.kukanMei(hiraki)}で、'
        '${w.senshu(sw)}が区間${win.kukanJuni[hiraki] + 1}位の走りで${saMoji(hirakiSa)}の差をつけた。',
      );
    }
  }
  w.danraku(sb.toString());
}

/// 1位と2位の差の推移の表(僅差・大差のとき。1.9.2)
KijiHyou _saSuiiHyou(EkidenKekka e) {
  final EkidenUnivKekka win = e.jun[0];
  final EkidenUnivKekka ni = e.jun[1];
  final List<List<String>> gyou = [];
  for (int kk = 0; kk < e.ks; kk++) {
    // 正なら優勝校が先行
    final int d = saByou(ni.ruikei[kk], win.ruikei[kk]);
    gyou.add([
      '${kk + 1}区',
      juniMoji(win.tuuka[kk]),
      juniMoji(ni.tuuka[kk]),
      d > 0
          ? '${win.mei}が${saMoji(d)}先行'
          : (d < 0 ? '${ni.mei}が${saMoji(d)}先行' : '1秒未満'),
    ]);
  }
  return KijiHyou(
    '1位と2位の差の推移(各区間の終了時点の順位と差)',
    ['区間', win.mei, ni.mei, '2校の差'],
    gyou,
  );
}

/// 区間[kk]の従来の学内区間記録(秒。エントリーの時点で控えたもの。なければnull)
int? _juraiGakunaiKukan(KijiKankyou k, int kk) {
  final int i = kk + 10;
  if (kk < 0 || kk >= 10 || k.kantoku.yobiint4.length <= i) return null;
  final int t = k.kantoku.yobiint4[i];
  if (t <= 0 || t >= 360000) return null;
  return t;
}

/// 区間[kk]の従来の区間記録(秒。エントリーの時点で控えたもの。なければnull)
int? _juraiKukan(KijiKankyou k, int kk) {
  if (kk < 0 || kk >= 10 || k.kantoku.yobiint4.length <= kk) return null;
  final int t = k.kantoku.yobiint4[kk];
  if (t <= 0 || t >= 360000) return null;
  return t;
}

// ------------------------------------------------------------
// 2. 自分の大学の記事
// ------------------------------------------------------------

Kiji? _jibunKiji(EkidenKekka e) {
  final EkidenUnivKekka? m = e.jibun;
  if (m == null) return null;
  final KijiKankyou k = e.k;
  const int no = 2;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int r = m.juni;
  final int mokuhyou = m.u.mokuhyojuni.length > race
      ? m.u.mokuhyojuni[race]
      : TEISUU.DEFAULTJUNI;
  final bool mokuhyouAri = mokuhyou >= 0 && mokuhyou < e.n;
  final bool tassei = mokuhyouAri && r <= mokuhyou;
  final int mae = juniRace(m.u, race, 1);
  final bool maeAri = shutsujouJuni(mae);
  final int? seed = e.seedSuu;
  final bool seedNow = seed != null && r < seed;
  final bool seedMae = seed != null && maeAri && mae < seed;
  final bool hatsuShutsujou = shutsujouKaisuu(m.u, race) <= 1;
  // 今回が初めての開催なら、全校が初出場なので「初出場」とは書かない
  final bool hatsuKaisai = hatsuKaisaiKekka(k, race);
  bool kakoSaikou = !hatsuShutsujou && juniKaisuu(m.u, race, r) == 1;
  for (int j = 0; j < r && kakoSaikou; j++) {
    if (juniKaisuu(m.u, race, j) > 0) kakoSaikou = false;
  }
  final int top = 0;
  final int saTop = saByou(m.time, e.jun[top].time);

  // 区間ごとの事実
  int jouGain = 0;
  int jouKukan = -1;
  for (int kk = 1; kk < ks; kk++) {
    final int g = m.tuuka[kk - 1] - m.tuuka[kk];
    if (g > jouGain) {
      jouGain = g;
      jouKukan = kk;
    }
  }
  int brakeKukan = -1;
  int brakeJuni = -1;
  for (int kk = 0; kk < ks; kk++) {
    if (m.kukanJuni[kk] > brakeJuni) {
      brakeJuni = m.kukanJuni[kk];
      brakeKukan = kk;
    }
  }
  final bool brake = e.n >= 6 && brakeJuni >= (e.n * 3) ~/ 4;
  final List<int> kukanshou = [
    for (int kk = 0; kk < ks; kk++)
      if (m.kukanJuni[kk] == 0) kk,
  ];

  // 見出し
  final String mm = m.mei;
  String midashi;
  if (r == 0) {
    final int kaisuu = juniKaisuu(m.u, race, 0);
    midashi = hatsuKaisai
        ? w.erabu(['$mmが初代王者に', '$mm、初開催の大会を制す'])
        : kaisuu <= 1
        ? w.erabu(['$mm、悲願の初優勝', '$mmが初の頂点に'])
        : w.erabu(['$mmが優勝　${kaisuu}度目の頂点', '$mm、栄冠つかむ']);
  } else if (kakoSaikou && r <= 4) {
    midashi = '$mmが過去最高の${juniMoji(r)}';
  } else if (seed != null && seedNow && !seedMae) {
    midashi = w.erabu(['$mm、${juniMoji(r)}でシード権獲得', '$mmがシード権つかむ　${juniMoji(r)}']);
  } else if (seed != null && !seedNow && seedMae) {
    midashi = w.erabu(['$mm、シード権失う　${juniMoji(r)}', '$mmは${juniMoji(r)}　シード権を逃す']);
  } else if (tassei && r <= 2) {
    midashi = '$mmが${juniMoji(r)}　目標の${juniMoji(mokuhyou)}以内を達成';
  } else if (maeAri && mae - r >= 5) {
    midashi = '$mmが躍進　前回${juniMoji(mae)}から${juniMoji(r)}';
  } else if (tassei) {
    midashi = w.erabu(['$mmは${juniMoji(r)}　目標クリア', '$mm、${juniMoji(r)}で目標達成']);
  } else if (mokuhyouAri) {
    midashi = w.erabu([
      '$mmは${juniMoji(r)}　目標の${juniMoji(mokuhyou)}に届かず',
      '$mm、${juniMoji(r)}に終わる',
    ]);
  } else {
    midashi = '$mmは${juniMoji(r)}';
  }
  if (kukanshou.isNotEmpty) {
    final SenshuData? s = m.senshu[kukanshou.first];
    if (s != null) midashi += '　${kukanshou.first + 1}区${myouji(s.name)}が区間賞';
  } else if (jouKukan >= 0 && jouGain >= 4) {
    final SenshuData? s = m.senshu[jouKukan];
    if (s != null) midashi += '　${jouKukan + 1}区${myouji(s.name)}が$jouGain人抜き';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}で、$mmは${jikanMoji(m.time)}の${juniMoji(r)}でゴールした。',
  );
  if (r > 0) lead.write('トップの${e.jun[0].mei}とは${kinsaMoji(saTop)}だった。');
  // 1位か2位で、1位と2位の差が僅差(1人あたり3秒以内)か大差(1人あたり20秒以上)なら、
  // 1人あたりの差も書く(1.9.2)
  if (r <= 1 && e.n >= 2 && ks >= 2) {
    final int sa12 = saByou(e.jun[1].time, e.jun[0].time);
    final bool kinsa12 = sa12 <= ks * 3;
    if (kinsa12 || sa12 >= ks * 20) {
      if (r == 0) {
        lead.write(
          kinsa12
              ? '2位の${e.jun[1].mei}とは${kinsaMoji(sa12)}、$ks人でつないで${hitoriAtariMoji(sa12, ks)}で競り勝った。'
              : '2位の${e.jun[1].mei}には${saMoji(sa12)}差、$ks人でつないで${hitoriAtariMoji(sa12, ks)}をつけた。',
        );
      } else {
        lead.write(
          kinsa12
              ? '$ks人でつないで${hitoriAtariMoji(sa12, ks)}で、優勝を逃した。'
              : '$ks人でつないで${hitoriAtariMoji(sa12, ks)}をつけられた。',
        );
      }
    }
  }
  if (mokuhyouAri) {
    if (tassei) {
      lead.write(
        r < mokuhyou
            ? '目標の${juniMoji(mokuhyou)}を上回る結果となった。'
            : '目標としていた${juniMoji(mokuhyou)}をきっちり達成した。',
      );
    } else {
      lead.write('目標の${juniMoji(mokuhyou)}には${r - mokuhyou}つ届かなかった。');
    }
  }
  if (hatsuKaisai) {
    if (r == 0) lead.write('初めて開催された大会で、初代王者に輝いた。');
  } else if (hatsuShutsujou) {
    lead.write('初出場で${juniMoji(r)}と健闘した。');
  } else if (maeAri) {
    if (mae > r) {
      lead.write('前回の${juniMoji(mae)}から順位を${mae - r}つ上げた。');
    } else if (mae < r) {
      lead.write('前回の${juniMoji(mae)}からは順位を落とした。');
    } else {
      lead.write('前回と同じ${juniMoji(mae)}だった。');
    }
  }
  if (seed != null) {
    if (seedNow && !seedMae) {
      lead.write('上位$seed校に与えられるシード権を獲得し、来季は予選会を免れる。');
    } else if (seedNow && seedMae) {
      lead.write('シード権も守った。');
    } else if (!seedNow && seedMae) {
      lead.write('シード権を失い、来季は予選会からの出直しとなる。');
    }
    // シード権ラインちょうどの2校のどちらかで、1人あたり5秒以内の差なら、その差も書く(1.9.2)
    if (e.n > seed && (r == seed - 1 || r == seed)) {
      final EkidenUnivKekka aite = r == seed - 1 ? e.jun[seed] : e.jun[seed - 1];
      final int sa2 = r == seed - 1
          ? saByou(aite.time, m.time)
          : saByou(m.time, aite.time);
      if (sa2 <= ks * 5) {
        lead.write(
          '${r == seed - 1 ? 'シード権を逃した' : 'シード権を取った'}${aite.mei}とは${kinsaMoji(sa2)}、'
          '$ks人でつないで${hitoriAtariMoji(sa2, ks)}だった。',
        );
      }
    }
  }
  if (kakoSaikou && r > 0) lead.write('大学としては過去最高の順位となった。');

  // 本文: 区間ごとの流れ
  w.koMidashi('レース');
  // 1区
  final SenshuData? s1 = m.senshu[0];
  if (s1 != null) {
    final StringBuffer sb = StringBuffer();
    sb.write('1区の${w.senshu(s1)}は区間${m.kukanJuni[0] + 1}位');
    if (m.kukanJuni[0] == 0) {
      sb.write('の走りで、トップでたすきをつないだ。');
    } else if (m.tuuka[0] <= 2) {
      sb.write('と好発進した。');
    } else if (m.tuuka[0] >= (e.n * 2) ~/ 3) {
      sb.write('と出遅れ、苦しいスタートとなった。');
    } else {
      sb.write('でまずまずの滑り出しを見せた。');
    }
    final String pace = _jibunIkkuPace(k, s1);
    if (pace.isNotEmpty) sb.write(pace);
    w.danraku(sb.toString());
  }
  // 大きく順位を上げた区間
  if (jouKukan >= 1 && jouGain >= 3) {
    final SenshuData? s = m.senshu[jouKukan];
    if (s != null) {
      final String yobi = w.senshu(s);
      w.danraku(
        w.erabu([
          '圧巻だったのは${e.kukanMei(jouKukan)}の$yobiだ。'
              '${juniMoji(m.tuuka[jouKukan - 1])}でたすきを受けると、$jouGain人を抜いて${juniMoji(m.tuuka[jouKukan])}に浮上した。',
          '${e.kukanMei(jouKukan)}の$yobiは、${juniMoji(m.tuuka[jouKukan - 1])}から一気に$jouGain人を抜き去り、'
              'チームを${juniMoji(m.tuuka[jouKukan])}に押し上げた。',
        ]),
      );
      w.comment(senshuComment(w, CommentBamen.oinuki, myouji(s.name)));
      w.danraku(shusshinShumiBun(k, s, w.r, myouji(s.name)));
    }
  }
  // 区間賞
  for (final int kk in kukanshou) {
    if (kk == 0) continue; // 1区は上で書いた
    final SenshuData? s = m.senshu[kk];
    if (s == null) continue;
    final bool shin =
        s.chokuzentaikai_zentaikukansinflag == 1 && _juraiKukan(k, kk) != null;
    w.danraku(
      '${e.kukanMei(kk)}では${w.senshu(s)}が${jikanMoji(m.kukanTime[kk])}で区間賞を獲得した'
      '${shin ? '。区間新記録のおまけつきだった' : ''}。',
    );
    w.comment(
      senshuComment(
        w,
        shin ? CommentBamen.kukanshin : CommentBamen.kukanshou,
        myouji(s.name),
      ),
    );
    break; // 区間賞のコメントは1人まで
  }
  // 学内区間新
  final List<String> gakunaiShin = [];
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    // 従来の学内区間記録がない(その区間を初めて走った)ときは、新記録と書かない(1.9.2)
    if (s != null &&
        s.chokuzentaikai_univkukansinflag == 1 &&
        _juraiGakunaiKukan(k, kk) != null) {
      gakunaiShin.add('${kk + 1}区の${w.senshu(s)}');
    }
  }
  if (gakunaiShin.isNotEmpty) {
    w.danraku('${gakunaiShin.join('、')}は学内の区間記録を塗り替えた。');
  }
  if (m.u.chokuzentaikai_univtaikaisinflag == 1) {
    final int jurai = k.kantoku.yobiint4.length > 21 ? k.kantoku.yobiint4[21] : 0;
    if (jurai > 0 && jurai < 360000 && jurai > byou(m.time)) {
      w.danraku('チームとしても、学内の大会記録を${saMoji(jurai - byou(m.time))}更新した。');
    }
  }
  // 当日変更で起用した選手
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    if (s == null) continue;
    bool kawatta = false;
    for (final SenshuData t in k.senshu) {
      if (t.univid == m.u.id && k.entry(t) == -(100 + kk)) kawatta = true;
    }
    if (!kawatta) continue;
    final int kj = m.kukanJuni[kk];
    if (kj <= e.n ~/ 3) {
      w.danraku(
        '当日変更で${e.kukanMei(kk)}に起用された${w.senshu(s)}は区間${kj + 1}位と好走し、起用に応えた。',
      );
      w.comment(senshuComment(w, CommentBamen.toujitsuKiyou, myouji(s.name)));
    } else {
      w.danraku('当日変更で${e.kukanMei(kk)}に起用された${w.senshu(s)}は区間${kj + 1}位だった。');
    }
    break;
  }
  // ブレーキ
  if (brake && brakeKukan >= 0 && !kukanshou.contains(brakeKukan)) {
    final SenshuData? s = m.senshu[brakeKukan];
    if (s != null) {
      // 呼び方は先に決める(言い回しの候補を作るたびに呼ぶと、2回目から名字だけになるため)
      final String yobi = w.senshu(s);
      w.danraku(
        w.erabu([
          '誤算は${e.kukanMei(brakeKukan)}だった。$yobiが区間${brakeJuni + 1}位と苦しみ、流れを手放した。',
          '${e.kukanMei(brakeKukan)}の$yobiは区間${brakeJuni + 1}位とブレーキになった。',
        ]),
      );
      w.comment(senshuComment(w, CommentBamen.brake, myouji(s.name), kuyashii: true));
    }
  }
  // 1年生
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    if (k.ichinenDake) break; // 1年生だけの大会では、1年生を特別扱いしない
    if (s == null || s.gakunen != 1) continue;
    if (m.kukanJuni[kk] <= 2 && !kukanshou.contains(kk)) {
      w.danraku('ルーキーの${w.senshu(s)}も${e.kukanMei(kk)}で区間${m.kukanJuni[kk] + 1}位と存在感を示した。');
      w.comment(senshuComment(w, CommentBamen.ichinenKousou, myouji(s.name)));
      break;
    }
  }
  // 4年生(正月駅伝は最後の大会)
  if (race == 2) {
    final List<String> yonen = [];
    for (int kk = 0; kk < ks; kk++) {
      final SenshuData? s = m.senshu[kk];
      if (s != null && s.gakunen == 4) yonen.add(w.senshu(s));
    }
    if (yonen.isNotEmpty) {
      w.danraku(
        '${yonen.length >= 3 ? '${yonen.length}人の4年生' : '4年生の${yonen.join('、')}'}は、これが最後の正月駅伝だった。',
      );
      // 一番後ろの区間を走った4年生にコメントをもらう
      SenshuData? saigo;
      for (int kk = ks - 1; kk >= 0; kk--) {
        final SenshuData? s = m.senshu[kk];
        if (s != null && s.gakunen == 4) {
          saigo = s;
          break;
        }
      }
      if (saigo != null) {
        w.comment(senshuComment(w, CommentBamen.yonenSaigo, myouji(saigo.name)));
      }
    }
  }
  // 監督のコメント
  KantokuBamen kb;
  bool kuyashii = false;
  if (r == 0) {
    kb = KantokuBamen.yuushou;
  } else if (seed != null && !seedNow && seedMae) {
    kb = KantokuBamen.seedSoushitsu;
    kuyashii = true;
  } else if (seed != null && seedNow && !seedMae) {
    kb = KantokuBamen.seedKakutoku;
  } else if (tassei) {
    kb = KantokuBamen.mokuhyouTassei;
  } else if (r >= (e.n * 4) ~/ 5) {
    kb = KantokuBamen.taihai;
    kuyashii = true;
  } else {
    kb = KantokuBamen.mokuhyouMitassei;
    kuyashii = true;
  }
  w.comment(kantokuComment(w, kb, m.u.id, kuyashii: kuyashii));
  // 次の大会
  final String tsugi = race == 0
      ? '次は11月駅伝に挑む。'
      : (race == 1 ? '次はいよいよ正月駅伝だ。' : (race == 2 ? '戦いの舞台は来季へと移る。' : ''));
  if (tsugi.isNotEmpty) w.danraku(tsugi);

  // 区間成績の表
  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    gyou.add([
      '${kk + 1}区',
      s == null ? '-' : '${fullMei(s.name)}(${s.gakunen})',
      juniMoji(m.kukanJuni[kk]),
      jikanMoji(m.kukanTime[kk]),
      juniMoji(m.tuuka[kk]),
    ]);
  }
  return _kansei(
    k,
    no,
    w,
    category: '駅伝・$mm',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('$mmの区間成績', ['区間', '選手', '区間順位', 'タイム', '通過'], gyou),
    ],
    jibun: true,
  );
}

/// 自分の大学の1区の選手の、集団のペースとの関係の一言(説明文から作る。なければ空)
String _jibunIkkuPace(KijiKankyou k, SenshuData s) {
  // (「後半の大失速は免れた」の行もあるので、大失速は「速すぎた」で見分ける)
  final List<String> gyou = ikkuSetsumeiGyou(s.string_racesetumei);
  for (final String g in gyou) {
    if (g.contains('自分で作った')) return '自ら集団を引っ張った。';
    if (g.contains('速すぎた')) return '速い集団のペースについていき、後半に失速した。';
    if (g.contains('遅かった')) return '集団のペースが遅く、持ち味を出し切れなかった。';
    if (g.contains('少しタイム得')) return '集団の流れにうまく乗った。';
    if (g.contains('免れた')) return '速い流れにも最後まで食らいついた。';
    if (g.contains('飛び出し')) return 'スタート直後から果敢に飛び出した。';
  }
  return '';
}

// ------------------------------------------------------------
// 3. 区間賞・新記録の記事
// ------------------------------------------------------------

Kiji? _kukanshouKiji(EkidenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 3;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = e.ks;
  if (ks < 2) return null;

  // 区間ごとの区間賞
  int mvp = -1;
  int mvpTen = -1;
  final List<bool> shin = List<bool>.filled(ks, false);
  final List<int> shinSa = List<int>.filled(ks, 0);
  for (int kk = 0; kk < ks; kk++) {
    final EkidenUnivKekka x = e.kukanJun[kk][0];
    final SenshuData? s = x.senshu[kk];
    if (s == null) continue;
    final int? jurai = _juraiKukan(k, kk);
    if (s.chokuzentaikai_zentaikukansinflag == 1 && jurai != null) {
      shin[kk] = true;
      shinSa[kk] = jurai - byou(x.kukanTime[kk]);
    }
    // MVPの点(区間新は大きく、2位との差も足す)
    final int ten = (shin[kk] ? 1000 + shinSa[kk] * 10 : 0) + e.kukanshouSa(kk);
    if (ten > mvpTen) {
      mvpTen = ten;
      mvp = kk;
    }
  }
  if (mvp < 0) return null;
  final int shinKazu = shin.where((b) => b).length;
  final EkidenUnivKekka mx = e.kukanJun[mvp][0];
  final SenshuData ms = mx.senshu[mvp]!;

  // 見出し
  String midashi;
  if (shin[mvp]) {
    midashi = w.erabu([
      '${myouji(ms.name)}(${mx.mei})が${mvp + 1}区で区間新',
      '${mx.mei}・${myouji(ms.name)}、${mvp + 1}区の区間記録を${saMoji(shinSa[mvp])}更新',
    ]);
    if (shinKazu >= 2) midashi += '　$shinKazu区間で新記録';
  } else {
    midashi = w.erabu([
      '${myouji(ms.name)}(${mx.mei})、${mvp + 1}区で${saMoji(e.kukanshouSa(mvp))}差の区間賞',
      '${mvp + 1}区${myouji(ms.name)}が独走の区間賞　${mx.mei}',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}で、');
  if (shin[mvp]) {
    lead.write(
      '${e.kukanMei(mvp)}の${w.senshu(ms, daigaku: true)}が${jikanMoji(mx.kukanTime[mvp])}をマークし、'
      '従来の区間記録を${saMoji(shinSa[mvp])}更新した。',
    );
  } else {
    lead.write(
      '${e.kukanMei(mvp)}の${w.senshu(ms, daigaku: true)}が${jikanMoji(mx.kukanTime[mvp])}で区間賞を獲得した。'
      '2位に${saMoji(e.kukanshouSa(mvp))}差をつける、この日一番の快走だった。',
    );
  }
  if (shinKazu >= 2) lead.write('区間新記録は全部で$shinKazu区間で生まれた。');

  // 本文: MVPの選手
  final StringBuffer sb = StringBuffer();
  final int maeKj = k.kukanJuniMae(ms, k.race, 1) ?? -1;
  final int maeEntry = k.entryMae(ms, k.race, 1);
  if (maeKj == 0 && maeEntry == mvp) {
    sb.write('${myouji(ms.name)}は前回も同じ区間で区間賞を獲得しており、2年連続の区間賞となった。');
  } else if (maeKj >= 0 && maeEntry >= 0) {
    sb.write('前回は${maeEntry + 1}区で区間${maeKj + 1}位だった${myouji(ms.name)}が、大きく成長した姿を見せた。');
  } else if (ms.gakunen == 1 && !k.ichinenDake) {
    sb.write('${myouji(ms.name)}はこれが初めての駅伝出場となる1年生だった。');
  }
  if (ms.hirou == 1) sb.write('留学生らしいダイナミックな走りで、他を寄せつけなかった。');
  w.danraku(sb.toString());
  w.comment(
    senshuComment(
      w,
      shin[mvp] ? CommentBamen.kukanshin : CommentBamen.kukanshou,
      myouji(ms.name),
    ),
  );
  w.danraku(shusshinShumiBun(k, ms, w.r, myouji(ms.name)));

  // 本文: ほかの区間
  w.koMidashi('各区間');
  for (int kk = 0; kk < ks; kk++) {
    if (kk == mvp) continue;
    final EkidenUnivKekka x = e.kukanJun[kk][0];
    final SenshuData? s = x.senshu[kk];
    if (s == null) continue;
    final StringBuffer b = StringBuffer();
    b.write('${e.kukanMei(kk)}は${w.senshu(s, daigaku: true)}が${jikanMoji(x.kukanTime[kk])}で区間賞');
    if (shin[kk]) {
      b.write('(区間新記録)');
    }
    final int sa = e.kukanshouSa(kk);
    if (sa <= 1) {
      b.write('。2位とはわずか${kinsaMoji(sa)}の競り合いを制した');
    } else if (sa >= 30) {
      b.write('。2位に${saMoji(sa)}差をつけた');
    }
    final int mKj = k.kukanJuniMae(s, k.race, 1) ?? -1;
    if (mKj == 0 && k.entryMae(s, k.race, 1) == kk) b.write('。2年連続の区間賞');
    if (s.gakunen == 1 && !k.ichinenDake) b.write('。1年生での快挙');
    b.write('。');
    w.danraku(b.toString());
  }
  // 学連選抜の区間トップ相当
  if (gakurenKonnenAri(k.gh)) {
    for (int kk = 0; kk < ks; kk++) {
      final GakurenKukanKekka? g = gakurenKukanKekka(k.gh, kk);
      if (g == null || g.kukanJuni != 0) continue;
      w.danraku(
        'オープン参加の学連選抜では、${e.kukanMei(kk)}の${w.hito('G${g.senshu.id}', g.senshu.name, '${g.senshu.gakunen}年', '')}'
        '(${daigakuMeiMoji(g.shozoku)})が区間トップ相当の走りを見せた。',
      );
    }
  }

  // 区間賞の表
  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final EkidenUnivKekka x = e.kukanJun[kk][0];
    final SenshuData? s = x.senshu[kk];
    gyou.add([
      '${kk + 1}区',
      kmMoji(k.gh.kyori_taikai_kukangoto[k.race][kk]),
      s == null ? '-' : '${fullMei(s.name)}(${s.gakunen})',
      x.mei,
      '${jikanMoji(x.kukanTime[kk])}${shin[kk] ? '※' : ''}',
      '+${saMoji(e.kukanshouSa(kk))}',
    ]);
  }
  return _kansei(
    k,
    no,
    w,
    category: '駅伝・区間賞',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '区間賞(※は区間新記録)',
        ['区間', '距離', '選手', '大学', 'タイム', '2位との差'],
        gyou,
      ),
    ],
    jibun: ms.univid == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 4. シード権争いの記事(11月駅伝・正月駅伝)
// ------------------------------------------------------------

Kiji? _seedKiji(EkidenKekka e) {
  final int? seed = e.seedSuu;
  if (seed == null || e.n <= seed) return null;
  final KijiKankyou k = e.k;
  const int no = 4;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  // 今年の予選(結果の記事なので、本戦の記録の[0]は今回、予選の記録の[0]は今年の予選)
  final int yosenRace = race == 1 ? 3 : 4;
  final String yosenMei = race == 1 ? '11月駅伝予選' : '正月駅伝予選';
  final EkidenUnivKekka nokori = e.jun[seed - 1]; // 最後にシード権を取った大学
  final EkidenUnivKekka morashi = e.jun[seed]; // 最初に逃した大学
  final int sa = saByou(morashi.time, nokori.time);
  // 最終区の前の順位(逆転があったか)
  final bool nokoriGyakuten = ks >= 2 && nokori.tuuka[ks - 2] >= seed;
  final bool morashiGyakuten = ks >= 2 && morashi.tuuka[ks - 2] < seed;
  // 前回シード権を持っていて逃した大学、新しく取った大学
  final List<EkidenUnivKekka> ushinatta = [];
  final List<EkidenUnivKekka> kakutoku = [];
  for (final EkidenUnivKekka x in e.jun) {
    final int mae = juniRace(x.u, race, 1);
    final bool maeSeed = shutsujouJuni(mae) && mae < seed;
    final bool imaSeed = x.juni < seed;
    if (maeSeed && !imaSeed) ushinatta.add(x);
    if (!maeSeed && imaSeed) kakutoku.add(x);
  }
  // 前回までの連続シード(今回の前まで)と、今回を含めた連続シード
  // 数を言い切れないとき(残っている記録が全部シードで、それより前にもシードがある)は数を出さない
  // (前回までの連続シードは、今回シード権を逃した大学に使うので、全期間のシードの回数は前回までの分)
  ({int kaisuu, bool kakutei}) maeRenzokuK(EkidenUnivKekka x) => renzokuKakutei(
    x.u,
    race,
    1,
    (j) => j < seed,
    seedKaisuu(x.u, race, seed),
  );
  ({int kaisuu, bool kakutei}) imaRenzokuK(EkidenUnivKekka x) => renzokuKakutei(
    x.u,
    race,
    0,
    (j) => j < seed,
    seedKaisuu(x.u, race, seed),
  );
  int maeRenzoku(EkidenUnivKekka x) => maeRenzokuK(x).kaisuu;
  int imaRenzoku(EkidenUnivKekka x) => imaRenzokuK(x).kaisuu;
  ushinatta.sort((a, b) => maeRenzoku(b).compareTo(maeRenzoku(a)));
  // 今年の予選を勝ち上がってきた大学と、その中でシード権を取った大学
  final List<EkidenUnivKekka> yosenGumi = [
    for (final EkidenUnivKekka x in e.jun)
      if (shutsujouJuni(juniRace(x.u, yosenRace, 0))) x,
  ];
  final List<EkidenUnivKekka> yosenKara = [
    for (final EkidenUnivKekka x in yosenGumi)
      if (x.juni < seed) x,
  ];
  // 連続シードが一番長い大学(今回もシード)
  EkidenUnivKekka? nagai;
  int nagaiNen = 0;
  for (final EkidenUnivKekka x in e.jun) {
    if (x.juni >= seed) continue;
    final int n = imaRenzoku(x);
    if (n > nagaiNen) {
      nagaiNen = n;
      nagai = x;
    }
  }
  // 後半にシード圏外から圏内に入って、そのまま守った大学(一番遅く入った大学)
  EkidenUnivKekka? makikaeshi;
  int makikaeshiKukan = -1;
  for (final EkidenUnivKekka x in e.jun) {
    if (x.juni >= seed) continue;
    int h = ks - 1; // 最後に続けてシード圏内にいた最初の区間
    while (h > 0 && x.tuuka[h - 1] < seed) {
      h--;
    }
    if (h == 0 || h < ks ~/ 2) continue;
    if (x.u.id == nokori.u.id && h == ks - 1 && nokoriGyakuten) continue; // リードで書く
    if (h > makikaeshiKukan) {
      makikaeshiKukan = h;
      makikaeshi = x;
    }
  }
  // 後半までシード圏内にいたのに、圏外で終わった大学(一番遅くまで圏内にいた大学)
  EkidenUnivKekka? tenraku;
  int tenrakuKukan = -1;
  for (final EkidenUnivKekka x in e.jun) {
    if (x.juni < seed) continue;
    int h = -1; // 最後にシード圏内にいた区間
    for (int kk = ks - 2; kk >= 0; kk--) {
      if (x.tuuka[kk] < seed) {
        h = kk;
        break;
      }
    }
    if (h < 0 || h < ks ~/ 2) continue;
    if (x.u.id == morashi.u.id && h == ks - 2 && morashiGyakuten) continue; // リードで書く
    if (h > tenrakuKukan) {
      tenrakuKukan = h;
      tenraku = x;
    }
  }
  final EkidenUnivKekka? togire = ushinatta.isEmpty ? null : ushinatta.first;

  // 見出し
  String midashi;
  if (sa <= 10) {
    midashi = w.erabu([
      'シード権争い、${nokori.mei}が${kinsaMoji(sa)}で滑り込み',
      '${morashi.mei}、${kinsaMoji(sa)}でシード権逃す',
    ]);
  } else if (togire != null && maeRenzoku(togire) >= 5) {
    midashi = maeRenzokuK(togire).kakutei
        ? '${togire.mei}、連続シード${maeRenzoku(togire)}年で途切れる　${juniMoji(togire.juni)}'
        : '${togire.mei}、長く続いた連続シードが途切れる　${juniMoji(togire.juni)}';
  } else if (nokoriGyakuten) {
    midashi = '${nokori.mei}が最終区で逆転シード';
  } else if (togire != null) {
    midashi = '${togire.mei}がシード落ち　${juniMoji(togire.juni)}';
  } else if (yosenKara.isNotEmpty) {
    midashi = '予選組の${yosenKara.first.mei}がシード権獲得　${juniMoji(yosenKara.first.juni)}';
  } else {
    midashi = 'シード権争い　${nokori.mei}が${juniMoji(nokori.juni)}で確保';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    sa <= 60
        ? '${k.taikaiMei}は、上位$seed校に与えられるシード権の行方も最後までもつれた。'
        : '${k.taikaiMei}は、上位$seed校に与えられるシード権争いも注目を集めた。',
  );
  lead.write(
    sa <= 0
        ? '${juniMoji(nokori.juni)}の${nokori.mei}と${juniMoji(morashi.juni)}の${morashi.mei}は、'
              '総合タイムが秒まで同じで、1秒に満たない差だった。'
        : '${juniMoji(nokori.juni)}の${nokori.mei}と${juniMoji(morashi.juni)}の${morashi.mei}の差は${saMoji(sa)}。',
  );
  // 1人あたり5秒以内の差なら、1人あたりの差も書く(1.9.2)
  if (sa <= ks * 5) {
    lead.write('$ks人でつないで、${hitoriAtariMoji(sa, ks)}だった。');
  }
  if (nokoriGyakuten) {
    lead.write('${nokori.mei}は最終区でシード圏内に浮上し、来年のシード権を手にした。');
  } else if (morashiGyakuten) {
    lead.write('${morashi.mei}は最終区でシード圏外に押し出された。');
  } else {
    lead.write(w.erabu(['わずかな差が明暗を分けた。', 'たすきの重みが勝負を決めた。']));
  }
  lead.write('シード権を逃した大学は、来年は$yosenMeiから出直す。');

  // 本文: 最終区
  w.koMidashi('明暗');
  final SenshuData? nAnchor = nokori.senshu[ks - 1];
  final SenshuData? mAnchor = morashi.senshu[ks - 1];
  if (nAnchor != null && mAnchor != null) {
    w.danraku(
      '最終区は${w.senshu(nAnchor, daigaku: true)}と${w.senshu(mAnchor, daigaku: true)}の争いとなった。'
      '${myouji(nAnchor.name)}は区間${nokori.kukanJuni[ks - 1] + 1}位、'
      '${myouji(mAnchor.name)}は区間${morashi.kukanJuni[ks - 1] + 1}位だった。',
    );
    w.comment(senshuComment(w, CommentBamen.yosenRakusen, myouji(mAnchor.name), kuyashii: true));
  }
  w.comment(kantokuComment(w, KantokuBamen.seedKakutoku, nokori.u.id));
  w.comment(
    kantokuComment(w, KantokuBamen.seedSoushitsu, morashi.u.id, kuyashii: true),
  );

  // 本文: 後半の出入り
  if (makikaeshi != null || tenraku != null) {
    w.koMidashi('後半の攻防');
    if (makikaeshi != null) {
      final int h = makikaeshiKukan;
      final SenshuData? r = makikaeshi.senshu[h];
      final String ugoki =
          '${juniMoji(makikaeshi.tuuka[h - 1])}からシード圏内の${juniMoji(makikaeshi.tuuka[h])}に浮上';
      w.danraku(
        r == null
            ? '${makikaeshi.mei}は${e.kukanMei(h)}で$ugokiし、そのまま${juniMoji(makikaeshi.juni)}でゴールした。'
            : '${makikaeshi.mei}は${e.kukanMei(h)}の${w.senshu(r)}が区間${makikaeshi.kukanJuni[h] + 1}位と踏ん張り、'
                  '$ugoki。そのまま${juniMoji(makikaeshi.juni)}でゴールした。',
      );
    }
    if (tenraku != null) {
      final int h = tenrakuKukan;
      w.danraku(
        '${tenraku.mei}は${e.kukanMei(h)}を終えた時点で${juniMoji(tenraku.tuuka[h])}とシード圏内にいたが、'
        'その後に順位を落とし、${juniMoji(tenraku.juni)}に終わった。',
      );
    }
  }

  // 本文: 顔ぶれ
  w.koMidashi('シード校の顔ぶれ');
  if (ushinatta.isNotEmpty) {
    final StringBuffer sb = StringBuffer(
      '前回シード権を持っていた${ushinatta.map((x) => '${x.mei}(${juniMoji(x.juni)})').join('、')}は'
      'シード権を失った。',
    );
    if (togire != null && maeRenzoku(togire) >= 2) {
      sb.write(
        maeRenzokuK(togire).kakutei
            ? '${togire.mei}の連続シードは${maeRenzoku(togire)}年で途切れた。'
            : '${togire.mei}の長く続いた連続シードが途切れた。',
      );
    }
    w.danraku(sb.toString());
  }
  final List<EkidenUnivKekka> atarashii = [
    for (final EkidenUnivKekka x in kakutoku)
      if (x.juni != 0) x,
  ];
  if (hatsuKaisaiKekka(k, race)) {
    // 初めての開催では、シード校は全部「新たに」なので並べない
    w.danraku('今回が初めての開催で、上位$seed校が初めてのシード権を手にした。');
  } else if (atarashii.isNotEmpty) {
    String naiyou(EkidenUnivKekka x) {
      final int yj = juniRace(x.u, yosenRace, 0);
      return shutsujouJuni(yj)
          ? '${x.mei}(${juniMoji(x.juni)}・予選${juniMoji(yj)}から)'
          : '${x.mei}(${juniMoji(x.juni)})';
    }

    w.danraku(
      '${ushinatta.isEmpty ? '' : '一方、'}${atarashii.map(naiyou).join('、')}が新たにシード権を手にした。',
    );
  }
  if (yosenGumi.isNotEmpty) {
    w.danraku(
      '$yosenMeiを勝ち上がった${yosenGumi.length}校のうち、'
      '${yosenKara.isEmpty ? 'シード権に届いた大学はなかった。' : '${yosenKara.length}校がシード権をつかんだ。'}',
    );
  }
  if (nagai != null && nagaiNen >= 5) {
    w.danraku(
      imaRenzokuK(nagai).kakutei
          ? '${nagai.mei}は$nagaiNen年連続のシード権確保となった。'
          : '${nagai.mei}は、長く続く連続シードをさらに伸ばした。',
    );
  }

  // シード権ライン前後の表(シード権ラインの区切りの行を入れる)
  bool jibunAri = false;
  final List<List<String>> gyou = [];
  for (int i = seed - 3; i <= seed + 2; i++) {
    if (i < 0 || i >= e.n) continue;
    final EkidenUnivKekka x = e.jun[i];
    if (x.u.id == k.gh.MYunivid) jibunAri = true;
    final int s = saByou(x.time, nokori.time);
    final int mae = juniRace(x.u, race, 1);
    gyou.add([
      juniMoji(x.juni),
      x.mei,
      jikanMoji(x.time),
      i < seed ? 'シード' : '+${saMoji(s)}',
      shutsujouJuni(mae) ? juniMoji(mae) : '-',
    ]);
    if (i == seed - 1) {
      gyou.add(['', '― シード権ライン ―', '', '', '']);
    }
  }
  return _kansei(
    k,
    no,
    w,
    category: '駅伝・シード権',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        'シード権ライン付近(上位$seed校がシード権)',
        ['順位', '大学', 'タイム', 'シードまで', '前回'],
        gyou,
      ),
    ],
    jibun: jibunAri,
  );
}

// ------------------------------------------------------------
// 5. 往路・復路の記事(正月駅伝)
// ------------------------------------------------------------

Kiji? _ouroFukuroKiji(EkidenKekka e) {
  final int? ouroKs = e.ouroKukansuu;
  if (ouroKs == null) return null;
  final KijiKankyou k = e.k;
  const int no = 5;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = e.ks;
  final int ou = ouroKs - 1; // 往路の最後の区間
  final List<EkidenUnivKekka> ouroJun = List<EkidenUnivKekka>.of(e.jun)
    ..sort((a, b) => a.ruikei[ou].compareTo(b.ruikei[ou]));
  double fukuro(EkidenUnivKekka x) => x.time - x.ruikei[ou];
  final List<EkidenUnivKekka> fukuroJun = List<EkidenUnivKekka>.of(e.jun)
    ..sort((a, b) => fukuro(a).compareTo(fukuro(b)));
  final EkidenUnivKekka oW = ouroJun[0];
  final EkidenUnivKekka fW = fukuroJun[0];
  final EkidenUnivKekka sW = e.jun[0];
  final bool kanzen = oW.u.id == sW.u.id && fW.u.id == sW.u.id;
  final int ouroSa = saByou(ouroJun[1].ruikei[ou], oW.ruikei[ou]);
  final int fukuroSa = saByou(fukuro(fukuroJun[1]), fukuro(fW));

  String midashi;
  if (kanzen) {
    midashi = w.erabu([
      '${sW.mei}、往路・復路とも制す完全優勝',
      '${sW.mei}が往復完全V',
    ]);
  } else {
    midashi = '往路は${oW.mei}、復路は${fW.mei}がV';
  }

  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}の往路(1〜$ouroKs区)は${oW.mei}が${jikanMoji(oW.ruikei[ou])}で制し、'
    '${ouroSa <= 0 ? '2位とは1秒に満たない差だった' : '2位に${saMoji(ouroSa)}差をつけた'}。',
  );
  lead.write(
    '復路(${ouroKs + 1}〜$ks区)は${fW.mei}が${jikanMoji(fukuro(fW))}で最速だった。',
  );
  if (kanzen) {
    lead.write('${sW.mei}は往路・復路ともに1位の完全優勝となった。');
  } else if (oW.u.id != sW.u.id) {
    lead.write('往路を制した${oW.mei}は、総合では${juniMoji(oW.juni)}だった。');
  }

  // 往路の山・復路の山
  for (int kk = 0; kk < ks; kk++) {
    final KukanTokuchou t = kukanTokuchou(k.gh, k.race, kk);
    if (t != KukanTokuchou.yamaNobori && t != KukanTokuchou.yamaKudari) continue;
    final EkidenUnivKekka x = e.kukanJun[kk][0];
    final SenshuData? s = x.senshu[kk];
    if (s == null) continue;
    w.danraku(
      '${e.kukanMei(kk)}は${w.senshu(s, daigaku: true)}が${jikanMoji(x.kukanTime[kk])}で区間賞。'
      '${t == KukanTokuchou.yamaNobori ? '険しい上り坂で' : '急な下り坂で'}'
      '${e.kukanshouSa(kk) <= 0 ? '、2位との1秒に満たない差の競り合いを制した。' : '${saMoji(e.kukanshouSa(kk))}の差をつけた。'}',
    );
  }
  // 復路の巻き返し
  final List<EkidenUnivKekka> makikaeshi = [
    for (final EkidenUnivKekka x in e.jun)
      if (x.tuuka[ou] - x.juni >= 4) x,
  ];
  if (makikaeshi.isNotEmpty) {
    final EkidenUnivKekka x = makikaeshi.first;
    w.danraku(
      '復路で大きく順位を上げたのは${x.mei}。往路${juniMoji(x.tuuka[ou])}から総合${juniMoji(x.juni)}まで巻き返した。',
    );
  }
  w.danraku('復路の2位とは${kinsaMoji(fukuroSa)}だった。');

  final List<List<String>> gyou = [];
  for (int i = 0; i < e.n; i++) {
    gyou.add([
      juniMoji(i),
      ouroJun[i].mei,
      jikanMoji(ouroJun[i].ruikei[ou]),
      fukuroJun[i].mei,
      jikanMoji(fukuro(fukuroJun[i])),
    ]);
  }
  return _kansei(
    k,
    no,
    w,
    category: '駅伝・往路復路',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('往路・復路の成績', ['順位', '往路', 'タイム', '復路', 'タイム'], gyou),
    ],
  );
}

// ------------------------------------------------------------
// 6. 学連選抜の記事(正月駅伝)
// ------------------------------------------------------------

Kiji? _gakurenKiji(EkidenKekka e) {
  final KijiKankyou k = e.k;
  if (k.race != 2 || !gakurenKonnenAri(k.gh)) return null;
  final int ks = e.ks;
  final GakurenKukanKekka? saigo = gakurenKukanKekka(k.gh, ks - 1);
  if (saigo == null) return null;
  const int no = 6;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final List<GakurenKukanKekka> kukan = [
    for (int kk = 0; kk < ks; kk++)
      if (gakurenKukanKekka(k.gh, kk) != null) gakurenKukanKekka(k.gh, kk)!,
  ];
  GakurenKukanKekka? best;
  int bestKukan = -1;
  for (int kk = 0; kk < ks; kk++) {
    final GakurenKukanKekka? g = gakurenKukanKekka(k.gh, kk);
    if (g == null) continue;
    if (best == null || g.kukanJuni < best.kukanJuni) {
      best = g;
      bestKukan = kk;
    }
  }
  final int sougou = saigo.tuukaJuni;
  final bool kantoku = _gakurenKantokuShita(k);

  String midashi = '学連選抜は${sougou + 1}位相当';
  if (best != null && best.kukanJuni <= 2) {
    midashi += '　${bestKukan + 1}区${myouji(best.senshu.name)}が区間${best.kukanJuni + 1}位相当';
  }
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}にオープン参加した学連選抜は、${jikanMoji(saigo.tuukaTime)}で'
    '総合${sougou + 1}位相当だった。',
  );
  if (sougou < 10) {
    lead.write('大学の中に入ればシード権圏内にあたる好成績を残した。');
  }
  if (kantoku && k.jibunUniv != null) {
    lead.write('今回は${daigakuMei(k.jibunUniv!)}の総監督が指揮を執った。');
  }
  if (best != null) {
    final String yobi = w.hito(
      'G${best.senshu.id}',
      best.senshu.name,
      '${best.senshu.gakunen}年',
      '${daigakuMeiMoji(best.shozoku)}の',
    );
    w.danraku(
      '光ったのは${e.kukanMei(bestKukan)}の$yobiだ。'
      '${jikanMoji(best.kukanTime)}で区間${best.kukanJuni + 1}位相当の走りを見せ、'
      '予選会で敗れた大学の選手の意地を示した。',
    );
    w.comment(
      senshuComment(
        w,
        best.kukanJuni == 0 ? CommentBamen.kukanshou : CommentBamen.oinuki,
        myouji(best.senshu.name),
      ),
    );
  }
  w.danraku(
    '学連選抜は予選会で本戦への出場を逃した大学の選手で編成されるチームで、順位はつかない。'
    '選手たちはそれぞれの大学の代表として、この舞台に立った。',
  );
  final List<List<String>> gyou = [
    for (final GakurenKukanKekka g in kukan)
      [
        g.senshu.name.isEmpty ? '-' : '${fullMei(g.senshu.name)}(${g.senshu.gakunen})',
        daigakuMeiMoji(g.shozoku),
        '${g.kukanJuni + 1}位相当',
        jikanMoji(g.kukanTime),
        '${g.tuukaJuni + 1}位相当',
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    category: '駅伝・学連選抜',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('学連選抜の区間成績', ['選手', '所属', '区間', 'タイム', '通過'], gyou),
    ],
    jibun: kantoku,
  );
}

// ------------------------------------------------------------
// 7. 三大駅伝の振り返り(正月駅伝のあと。1.9.3)
// 今季の三大駅伝の優勝校と、過去の季の優勝校・三冠の表。前の季の記録がないとき
// (ゲームを始めた年など)は、今季の優勝校の表がトップ記事にあるので出さない
// ------------------------------------------------------------

/// 三大駅伝の歴代優勝校の表に出す季の数
const int _sandaiRekidaiKisuu = 5;

Kiji? _sandaiKiji(EkidenKekka e) {
  final KijiKankyou k = e.k;
  if (k.race != 2) return null;
  final SandaiEkiden? sd = SandaiEkiden.tsukuru(k, kekka: true);
  if (sd == null) return null;
  final KijiHyou rekidai = sd.rekidaiHyou(_sandaiRekidaiKisuu);
  if (rekidai.gyou.length < 2) return null;
  const int no = 7;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final UnivData win = e.jun[0].u;
  final UnivData? y10 = sd.yuushou(0, 0);
  final UnivData? y11 = sd.yuushou(1, 0);
  final bool sankanIma = sd.sankan(win, 0);
  final bool wakeai = y10 != null &&
      y11 != null &&
      y10.id != y11.id &&
      win.id != y10.id &&
      win.id != y11.id;
  // 表に出した季の、大学ごとの優勝回数と、三冠の季(表と同じ季を見る)
  final Map<int, int> kazu = {};
  final List<String> sankanKi = [];
  int kisuu = 0;
  for (int i = 0; i < _sandaiRekidaiKisuu; i++) {
    if (sd.nendo(i) < 1) break;
    bool ari = false;
    for (final int race in sandaiEkidenRace) {
      final UnivData? u = sd.yuushou(race, i);
      if (u == null) continue;
      ari = true;
      kazu[u.id] = (kazu[u.id] ?? 0) + 1;
    }
    if (ari) kisuu++;
    final UnivData? u0 = sd.yuushou(0, i);
    if (u0 != null && sd.sankan(u0, i)) {
      sankanKi.add('${sd.nendo(i)}年度の${daigakuMei(u0)}');
    }
  }
  final int taikaisuu = kazu.values.fold<int>(0, (t, v) => t + v);
  int saita = 0;
  kazu.forEach((id, c) {
    if (c > saita) saita = c;
  });
  final List<String> saitaMei = [
    for (final MapEntry<int, int> x in kazu.entries)
      if (x.value == saita && x.key >= 0 && x.key < k.univ.length)
        daigakuMei(k.univ[x.key]),
  ];

  // 見出し
  String midashi;
  if (sankanIma) {
    midashi = '${daigakuMei(win)}の三冠で幕　三大駅伝の歴代優勝校';
  } else if (wakeai) {
    midashi = '今季の三大駅伝は3校が分け合う　歴代優勝校を振り返る';
  } else {
    midashi = w.erabu([
      '今季の三大駅伝を振り返る　歴代優勝校',
      '三大駅伝の頂点はどこに　歴代優勝校を振り返る',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}が終わり、今季の三大駅伝が幕を閉じた。');
  final List<String> konki = [
    if (y10 != null) '10月駅伝は${daigakuMei(y10)}',
    if (y11 != null) '11月駅伝は${daigakuMei(y11)}',
    '正月駅伝は${daigakuMei(win)}',
  ];
  lead.write('${konki.join('、')}が制した。');
  if (sankanIma) {
    lead.write('${daigakuMei(win)}が三冠を果たした季となった。');
  } else if (wakeai) {
    lead.write('3つの大会を3校が1つずつ分け合った。');
  }

  // 本文: この○季の三大駅伝
  w.koMidashi('直近$kisuu季の三大駅伝');
  final StringBuffer sb = StringBuffer();
  if (saitaMei.isNotEmpty && saita >= 2) {
    sb.write(
      '直近$kisuu季の三大駅伝($taikaisuu大会)で最も多く優勝したのは、'
      '${saitaMei.take(3).join('、')}の$saita回だった。',
    );
  }
  sb.write(
    sankanKi.isEmpty
        ? 'この間に三冠を達成した大学はなかった。'
        : 'この間の三冠は、${sankanKi.join('、')}。',
  );
  w.danraku(sb.toString());

  // 本文: 三冠の通算
  final List<UnivData> sankanUniv =
      [
        for (final UnivData u in k.univ)
          if (u.sankankaisuu > 0) u,
      ]..sort((a, b) {
        final int c = b.sankankaisuu.compareTo(a.sankankaisuu);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  w.koMidashi('三冠の歴史');
  w.danraku(
    sankanUniv.isEmpty
        ? '三大駅伝をすべて制する三冠を達成した大学は、まだない。'
        : '三冠の通算回数は、'
              '${[for (final UnivData u in sankanUniv.take(3)) '${daigakuMei(u)}が${u.sankankaisuu}回'].join('、')}'
              '${sankanUniv.length > 3 ? 'などとなっている' : 'となっている'}。',
  );

  final int my = k.gh.MYunivid;
  return _kansei(
    k,
    no,
    w,
    category: '駅伝',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [rekidai],
    jibun: win.id == my || y10?.id == my || y11?.id == my,
  );
}
