import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';

// ------------------------------------------------------------
// 予選(11月駅伝予選・正月駅伝予選)の結果の記事(1.9.2。結果画面の「ニュース記事」)
//
// 記事(出せるものだけ並べる)
//  1. トップ記事: 通過校の顔ぶれ。連続出場が途切れた大学・初の本戦・通過ラインの僅差・
//     トップ通過などから、一番ニュース価値の高い切り口を見出しにする
//  2. 自分の大学の記事: 通過か落選か、通過ラインとの差、組ごと(個人ごと)の走り
//  3. 次点の記事: 通過ラインとの差が1人あたり3秒以内(11月駅伝予選)・5秒以内(正月駅伝予選)の
//     ときだけ。何秒差で涙をのんだか、どこで差がついたか(組ごと・番手ごと)を書く(1.9.2)
//  4. 個人の記事: 11月駅伝予選は各組のトップ、正月駅伝予選は個人トップと日本人トップ
//
// 予選のあとなので、本戦(11月駅伝・正月駅伝)の順位の記録の[0]は前回(去年)の本戦
// ------------------------------------------------------------

/// 予選の選手1人の結果
class YosenSenshuKekka {
  final SenshuData s;

  /// 組(0が1組。正月駅伝予選は0)
  final int kumi;

  final double time;

  /// 組の中の順位(正月駅伝予選は全体の順位。0が1位)
  int juni = 0;

  /// 大学の中の順位(0が1番手)
  int univJuni = 0;

  YosenSenshuKekka(this.s, this.kumi, this.time);
}

/// 予選の結果の、大学1校分
class YosenUnivKekka {
  final UnivData u;

  /// 組ごとの累計タイム(正月駅伝予選は上位10人の合計の1つだけ)
  final List<double> ruikei;

  /// 組ごとの通過順位(0が1位)
  final List<int> tuuka;

  /// 走った選手(タイム順)
  final List<YosenSenshuKekka> senshu = [];

  /// 最終順位(0が1位)
  int juni = 0;

  YosenUnivKekka(this.u, this.ruikei)
    : tuuka = List<int>.filled(ruikei.length, 0);

  double get time => ruikei.last;

  String get mei => daigakuMei(u);
}

/// 予選の結果(出場校全部)
class YosenKekka {
  final KijiKankyou k;

  /// 最終順位の順
  final List<YosenUnivKekka> jun;

  /// 走った選手全員(タイム順)
  final List<YosenSenshuKekka> kojin;

  YosenKekka._(this.k, this.jun, this.kojin);

  /// 結果を集める(予選でないときや、出場校が2校より少ないときなどはnull)
  static YosenKekka? tsukuru(KijiKankyou k) {
    if (k.race != 3 && k.race != 4) return null;
    final int ks = k.kukansuu;
    if (ks <= 0) return null;
    final List<YosenUnivKekka> list = [];
    for (final UnivData u in k.univ) {
      if (!k.shutsujou(u)) continue;
      if (u.time_taikai_total.length < ks) continue;
      final List<double> ruikei = [
        for (int i = 0; i < ks; i++) u.time_taikai_total[i],
      ];
      if (ruikei.last <= 0 || ruikei.last >= TEISUU.DEFAULTTIME) continue;
      list.add(YosenUnivKekka(u, ruikei));
    }
    if (list.length < 2) return null;
    final Map<int, YosenUnivKekka> byId = {for (final x in list) x.u.id: x};
    final List<YosenSenshuKekka> kojin = [];
    for (final SenshuData s in k.senshu) {
      final YosenUnivKekka? x = byId[s.univid];
      if (x == null) continue;
      final int e = k.entry(s);
      if (e < 0 || e >= ks) continue;
      final double? t = _kojinTime(k, s);
      if (t == null) continue;
      final YosenSenshuKekka y = YosenSenshuKekka(s, e, t);
      kojin.add(y);
      x.senshu.add(y);
    }
    kojin.sort((a, b) => a.time.compareTo(b.time));
    // 組の中の順位
    for (int kumi = 0; kumi < ks; kumi++) {
      int j = 0;
      for (final YosenSenshuKekka y in kojin) {
        if (y.kumi != kumi) continue;
        y.juni = j;
        j++;
      }
    }
    for (final YosenUnivKekka x in list) {
      x.senshu.sort((a, b) => a.time.compareTo(b.time));
      for (int i = 0; i < x.senshu.length; i++) {
        x.senshu[i].univJuni = i;
      }
    }
    // 順位は大会の記録(通過の判定に使ったもの)の順。同じならタイム順
    list.sort((a, b) {
      final int c = juniRace(a.u, k.race, 0).compareTo(juniRace(b.u, k.race, 0));
      return c != 0 ? c : a.time.compareTo(b.time);
    });
    for (int i = 0; i < list.length; i++) {
      list[i].juni = i;
    }
    for (int kk = 0; kk < ks; kk++) {
      final List<YosenUnivKekka> t = List<YosenUnivKekka>.of(list)
        ..sort((a, b) => a.ruikei[kk].compareTo(b.ruikei[kk]));
      for (int i = 0; i < t.length; i++) {
        t[i].tuuka[kk] = i;
      }
    }
    return YosenKekka._(k, list, kojin);
  }

  int get ks => k.kukansuu;

  int get n => jun.length;

  /// 通過する大学の数(11月駅伝予選7校・正月駅伝予選10校)
  int get tsuukaSuu => k.race == 3 ? 7 : 10;

  /// 本戦の大会番号
  int get honsen => k.race == 3 ? 1 : 2;

  /// 本戦の名前
  String get honsenMei => k.race == 3 ? '11月駅伝' : '正月駅伝';

  /// 通過したか
  bool tsuuka(YosenUnivKekka x) => x.juni < tsuukaSuu;

  /// 本戦がまだ一度も行われていないか(ゲームを始めた年など。通過校は全部初出場になるので、
  /// 初出場を並べたり見出しにしたりしない)
  bool get honsenMikaisai => mikaisai(k, honsen);

  /// 通過ラインの争いがあるか(出場校が通過校の数より多い)
  bool get borderAri => n > tsuukaSuu;

  /// チームの合計に入る人数(11月駅伝予選は走る8人全員、正月駅伝予選は上位10人)
  int get keisanNinzuu => k.race == 3 ? 8 : 10;

  /// 最後の通過校と次点の差(秒。通過ラインの争いがなければnull)
  int? get borderSaByou => borderAri
      ? saByou(jun[tsuukaSuu].time, jun[tsuukaSuu - 1].time)
      : null;

  /// 次点の記事を立てる差の上限(秒。1人あたり11月駅伝予選は3秒、正月駅伝予選は5秒)
  int get jitenSaJougen => keisanNinzuu * (k.race == 3 ? 3 : 5);

  /// 新記録と書いてよいか(予選は従来の記録を控えていないので、初めての開催では、
  /// 全員が「記録なし」より速く新記録の印が付く。そのときは新記録と書かない。1.9.2)
  bool get shinkirokuKa => !hatsuKaisaiKekka(k, k.race);

  /// 選手が新記録(11月駅伝予選は組の新記録、正月駅伝予選は大会新記録)を出したか
  bool shinkiroku(SenshuData s) =>
      shinkirokuKa && s.chokuzentaikai_zentaikukansinflag == 1;

  /// 次点の記事を立てるか
  bool get jitenKijiAri {
    final int? sa = borderSaByou;
    return sa != null && sa <= jitenSaJougen;
  }

  /// 自分の大学(出場していなければnull)
  YosenUnivKekka? get jibun {
    for (final YosenUnivKekka x in jun) {
      if (x.u.id == k.gh.MYunivid) return x;
    }
    return null;
  }

  /// 組[kumi]の個人1位(いなければnull)
  YosenSenshuKekka? kumiTop(int kumi) {
    for (final YosenSenshuKekka y in kojin) {
      if (y.kumi == kumi && y.juni == 0) return y;
    }
    return null;
  }

  /// 組[kumi]の個人[juni]位のタイム(いなければnull)
  double? kumiTime(int kumi, int juni) {
    for (final YosenSenshuKekka y in kojin) {
      if (y.kumi == kumi && y.juni == juni) return y.time;
    }
    return null;
  }

  /// 大学の呼び方(id から)
  String univMei(int univid) => (univid >= 0 && univid < k.univ.length)
      ? daigakuMei(k.univ[univid])
      : '';

  /// 「1組」(11月駅伝予選)・空(正月駅伝予選)
  String kumiMei(int kumi) => k.race == 3 ? '${kumi + 1}組' : '';
}

/// 選手の予選のタイム(なければnull)
double? _kojinTime(KijiKankyou k, SenshuData s) {
  if (s.kukantime_race.length <= k.race) return null;
  final int g = s.gakunen - 1;
  if (g < 0 || g >= s.kukantime_race[k.race].length) return null;
  final double t = s.kukantime_race[k.race][g];
  if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
  return t;
}

/// 本戦の出場の言い方(「3年連続5度目の」「2年ぶり4度目の」「初の」)
/// 予選のあとなので、本戦の記録の[0]が前回(去年)の本戦
/// (本戦がまだ一度も行われていないときは空)
String _honsenKaisuuMoji(YosenKekka e, UnivData u) {
  if (e.honsenMikaisai) return '';
  final int kaisuu = shutsujouKaisuu(u, e.honsen) + 1;
  if (kaisuu <= 1) return '初の';
  // 連続出場の数を言い切れないとき(残っている記録が全部出場で、それより前にも出場がある)は、
  // 連続の数を出さず、全期間の回数だけにする
  final ({int kaisuu, bool kakutei}) rz = renzokuKakutei(
    u,
    e.honsen,
    0,
    shutsujouJuni,
    shutsujouKaisuu(u, e.honsen),
  );
  if (!rz.kakutei) return '$kaisuu度目の';
  final int renzoku = rz.kaisuu + 1;
  final int? mae = saigoNoKai(u, e.honsen, 0, shutsujouJuni);
  return renzokuMoji(
    renzoku: renzoku,
    buri: mae == null ? null : mae + 1,
    kaisuu: kaisuu,
  );
}

/// 本戦の出場の短い言い方(表や並びで使う。「3年連続5度目」「初出場」)
String _honsenKaisuuMijikai(YosenKekka e, UnivData u) {
  final String m = _honsenKaisuuMoji(e, u);
  if (m.isEmpty) return '';
  if (m == '初の') return '初出場';
  return m.endsWith('の') ? m.substring(0, m.length - 1) : m;
}

// ------------------------------------------------------------
// 記事の入口
// ------------------------------------------------------------

/// 予選の結果の記事の一覧(並べる順)
List<Kiji> yosenKekkaKiji(KijiKankyou k) {
  final YosenKekka? e = YosenKekka.tsukuru(k);
  if (e == null) return [];
  final List<Kiji> list = [_yosenTopKiji(e)];
  final Kiji? jibun = _yosenJibunKiji(e);
  if (jibun != null) list.add(jibun);
  final Kiji? jiten = _yosenJitenKiji(e);
  if (jiten != null) list.add(jiten);
  final Kiji? kojin = _yosenKojinKiji(e);
  if (kojin != null) list.add(kojin);
  return list;
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

// ------------------------------------------------------------
// 1. トップ記事
// ------------------------------------------------------------

Kiji _yosenTopKiji(YosenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 1;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int ts = e.tsuukaSuu;
  final YosenUnivKekka top = e.jun[0];
  final YosenUnivKekka ni = e.jun[1];
  final int sa = saByou(ni.time, top.time);
  final YosenUnivKekka? saigo = e.borderAri ? e.jun[ts - 1] : null; // 最後の通過校
  final YosenUnivKekka? morashi = e.borderAri ? e.jun[ts] : null; // 最初に逃した大学
  final int borderSa = (saigo != null && morashi != null)
      ? saByou(morashi.time, saigo.time)
      : 0;

  // 事実を集める
  final List<YosenUnivKekka> hatsu = [
    for (final YosenUnivKekka x in e.jun)
      if (!e.honsenMikaisai &&
          e.tsuuka(x) &&
          shutsujouKaisuu(x.u, e.honsen) == 0)
        x,
  ];
  // 前回の本戦に出ていて落選した大学(連続出場の長い順)
  final List<YosenUnivKekka> togireta = [
    for (final YosenUnivKekka x in e.jun)
      if (!e.tsuuka(x) && shutsujouJuni(juniRace(x.u, e.honsen, 0))) x,
  ];
  int renzokuHonsen(YosenUnivKekka x) =>
      renzokuKaisuu(x.u, e.honsen, 0, shutsujouJuni);
  // 連続出場の数を言い切れるか(言い切れないときは数を出さない)
  bool renzokuHonsenKakutei(YosenUnivKekka x) => renzokuKakutei(
    x.u,
    e.honsen,
    0,
    shutsujouJuni,
    shutsujouKaisuu(x.u, e.honsen),
  ).kakutei;
  togireta.sort((a, b) => renzokuHonsen(b).compareTo(renzokuHonsen(a)));
  final YosenUnivKekka? togire = togireta.isEmpty ? null : togireta.first;
  final bool topRenzoku = juniRace(top.u, race, 1) == 0;
  // 最後の組での逆転(11月駅伝予選)
  final bool saigoGyakuten =
      race == 3 && ks >= 2 && saigo != null && saigo.tuuka[ks - 2] >= ts;

  // 見出し
  String midashi;
  if (togire != null &&
      renzokuHonsen(togire) >= 5 &&
      !renzokuHonsenKakutei(togire)) {
    midashi = w.erabu([
      '${togire.mei}が予選敗退　長く続いた${e.honsenMei}出場途切れる',
      '${togire.mei}、まさかの予選落ち　長く続いた連続出場が途切れる',
    ]);
  } else if (togire != null && renzokuHonsen(togire) >= 5) {
    midashi = w.erabu([
      '${togire.mei}が予選敗退　連続出場${renzokuHonsen(togire)}年で途切れる',
      '${togire.mei}、まさかの予選落ち　${renzokuHonsen(togire)}年続いた${e.honsenMei}出場途切れる',
    ]);
  } else if (saigo != null && borderSa <= 10) {
    midashi = '${saigo.mei}が${kinsaMoji(borderSa)}で滑り込み';
    midashi += '　トップ通過は${top.mei}';
  } else if (hatsu.isNotEmpty) {
    midashi = w.erabu([
      '${hatsu.first.mei}が初の${e.honsenMei}切符',
      '${hatsu.first.mei}、悲願の${e.honsenMei}初出場決める',
    ]);
    midashi += '　トップ通過は${top.mei}';
  } else if (saigoGyakuten && saigo != null) {
    midashi = '${saigo.mei}が最終組で逆転通過';
    midashi += '　トップは${top.mei}';
  } else {
    midashi = w.erabu([
      '${top.mei}がトップ通過',
      '${top.mei}、${topRenzoku ? '2年連続の' : ''}トップ通過',
    ]);
    midashi += '　$ts校が${e.honsenMei}へ';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}が行われ、上位$ts校が${e.honsenMei}の出場権を獲得した。',
  );
  lead.write(
    w.erabu([
      '${top.mei}が${jikanMoji(top.time)}でトップ通過を果たした。',
      'トップ通過は${jikanMoji(top.time)}の${top.mei}だった。',
    ]),
  );
  if (topRenzoku) lead.write('2年連続のトップ通過となった。');
  if (sa >= 60) {
    lead.write('2位の${ni.mei}に${saMoji(sa)}差をつける力の差を見せた。');
  }
  if (saigo != null && morashi != null) {
    lead.write(
      '最後の$ts枠目には${saigo.mei}が入り、${(ts + 1)}位の${morashi.mei}とは'
      '${borderSa <= 0 ? '合計タイムが秒まで同じで、1秒に満たない差' : '${saMoji(borderSa)}差'}だった。',
    );
  }

  // 本文: レースの流れ
  if (race == 3) {
    w.koMidashi('各組');
    int maeShuiId = -1;
    for (int kk = 0; kk < ks; kk++) {
      final StringBuffer sb = StringBuffer();
      final YosenSenshuKekka? kt = e.kumiTop(kk);
      if (kt != null) {
        sb.write(
          '${e.kumiMei(kk)}は${w.senshu(kt.s, daigaku: true)}が${jikanMoji(kt.time)}でトップ。',
        );
      }
      // その組のあとの首位と通過ライン
      YosenUnivKekka? shui;
      YosenUnivKekka? nana;
      YosenUnivKekka? hachi;
      for (final YosenUnivKekka x in e.jun) {
        if (x.tuuka[kk] == 0) shui = x;
        if (x.tuuka[kk] == ts - 1) nana = x;
        if (x.tuuka[kk] == ts) hachi = x;
      }
      if (kk < ks - 1) {
        if (shui != null) {
          sb.write(
            shui.u.id == maeShuiId
                ? '首位は${shui.mei}が守った。'
                : 'この組を終えて${shui.mei}が首位に立った。',
          );
          maeShuiId = shui.u.id;
        }
        if (nana != null && hachi != null) {
          sb.write(
            '通過圏の$ts位${nana.mei}と${ts + 1}位${hachi.mei}の差は'
            '${saByou(hachi.ruikei[kk], nana.ruikei[kk]) <= 0 ? '1秒に満たない' : saMoji(saByou(hachi.ruikei[kk], nana.ruikei[kk]))}。',
          );
        }
      } else if (saigo != null && morashi != null) {
        if (saigo.tuuka[ks - 2] >= ts) {
          sb.write(
            '最終組で${saigo.mei}が${juniMoji(saigo.tuuka[ks - 2])}から通過圏に浮上し、'
            '逆転で${e.honsenMei}への切符をつかんだ。',
          );
        } else if (morashi.tuuka[ks - 2] < ts) {
          sb.write('${morashi.mei}は最終組で通過圏から押し出された。');
        } else {
          sb.write('最終組でも通過圏の顔ぶれは変わらなかった。');
        }
      }
      w.danraku(sb.toString());
    }
  } else if (e.kojin.isNotEmpty) {
    w.koMidashi('レース');
    final StringBuffer sb = StringBuffer();
    final YosenSenshuKekka k1 = e.kojin.first;
    sb.write(
      '個人トップは${w.senshu(k1.s, daigaku: true)}で、${jikanMoji(k1.time)}だった。',
    );
    if (k1.s.hirou == 1) {
      for (final YosenSenshuKekka y in e.kojin) {
        if (y.s.hirou == 1) continue;
        sb.write(
          '日本人トップは${juniMoji(y.juni)}の${w.senshu(y.s, daigaku: true)}だった。',
        );
        break;
      }
    }
    // トップ通過校の10番手
    final int juu = top.senshu.length >= 10 ? 9 : top.senshu.length - 1;
    if (juu >= 0) {
      final YosenSenshuKekka y = top.senshu[juu];
      sb.write(
        '${top.mei}は${juu + 1}番手の選手も個人${juniMoji(y.juni)}でゴールし、'
        '${y.juni < e.kojin.length ~/ 3 ? '層の厚さを見せつけた' : '全員で粘り抜いた'}。',
      );
    }
    w.danraku(sb.toString());
  }

  // 本文: 明暗
  if (saigo != null && morashi != null) {
    w.koMidashi('明暗');
    w.danraku(
      w.erabu([
        '通過ラインの$ts位争いは、${saigo.mei}が${morashi.mei}を${kinsaMoji(borderSa)}でかわした。',
        '${saigo.mei}と${morashi.mei}の明暗を分けたのは、'
            '${borderSa <= 0 ? '1秒に満たない差' : 'わずか${saMoji(borderSa)}'}だった。',
      ]),
    );
    // 次点の記事を立てるときは、選手と監督の話はそちらで書く
    if (e.jitenKijiAri) {
      w.danraku('${e.keisanNinzuu}人で走って、${hitoriAtariMoji(borderSa, e.keisanNinzuu)}だった。'
          '涙をのんだ${morashi.mei}の戦いは、別稿で伝える。');
    } else if (morashi.senshu.isNotEmpty) {
      final SenshuData s = morashi.senshu.first.s;
      w.danraku(
        '${morashi.mei}はチームトップの${w.senshu(s)}が'
        '${race == 3 ? '${e.kumiMei(morashi.senshu.first.kumi)}で' : ''}'
        '個人${juniMoji(morashi.senshu.first.juni)}と奮闘したが、あと一歩届かなかった。',
      );
      w.comment(
        senshuComment(w, CommentBamen.yosenRakusen, myouji(s.name), kuyashii: true),
      );
    }
    if (!e.jitenKijiAri) {
      w.comment(
        kantokuComment(w, KantokuBamen.yosenRakusen, morashi.u.id, kuyashii: true),
      );
    }
    w.comment(kantokuComment(w, KantokuBamen.yosenTsuuka, saigo.u.id));
  }

  // 本文: 通過校の顔ぶれ
  w.koMidashi('通過校');
  final List<String> kaisuu = [
    for (final YosenUnivKekka x in e.jun)
      if (e.tsuuka(x))
        _honsenKaisuuMijikai(e, x.u).isEmpty
            ? x.mei
            : '${x.mei}(${_honsenKaisuuMijikai(e, x.u)})',
  ];
  w.danraku('${e.honsenMei}への出場を決めたのは、${kaisuu.join('、')}。');
  if (e.honsenMikaisai) {
    w.danraku('${e.honsenMei}は今回が初めての開催となる。初代王者の座を懸けた戦いが待っている。');
  }
  if (hatsu.isNotEmpty) {
    w.danraku(
      '${hatsu.map((x) => x.mei).join('、')}は初めて${e.honsenMei}の舞台に立つ。'
      '${w.erabu(['新たな歴史の始まりだ。', '大学にとって記念すべき一日となった。'])}',
    );
  }
  for (final YosenUnivKekka x in togireta.take(2)) {
    final int r = renzokuHonsen(x);
    final int mae = juniRace(x.u, e.honsen, 0);
    w.danraku(
      '前回${e.honsenMei}で${juniMoji(mae)}だった${x.mei}は${juniMoji(x.juni)}で予選敗退。'
      '${!renzokuHonsenKakutei(x) ? '長く続いた連続出場が途切れた。' : (r >= 2 ? '連続出場は$r年で途切れた。' : '2年連続の出場はならなかった。')}',
    );
  }
  if (race == 4) {
    w.danraku('通過を逃した大学の選手からは、正月駅伝にオープン参加する学連選抜が編成される。');
  }

  // 総合成績の表
  final List<List<String>> gyou = [
    for (final YosenUnivKekka x in e.jun)
      [
        juniMoji(x.juni),
        x.mei,
        jikanMoji(x.time),
        x.juni == 0 ? '-' : '+${saMoji(saByou(x.time, top.time))}',
        e.tsuuka(x) ? '通過' : '',
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    category: '駅伝予選',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        race == 4 ? '総合成績(上位10人の合計)' : '総合成績',
        ['順位', '大学', 'タイム', 'トップ差', '本戦'],
        gyou,
      ),
    ],
    jibun: top.u.id == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 2. 自分の大学の記事
// ------------------------------------------------------------

Kiji? _yosenJibunKiji(YosenKekka e) {
  final YosenUnivKekka? m = e.jibun;
  if (m == null) return null;
  final KijiKankyou k = e.k;
  const int no = 2;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int ts = e.tsuukaSuu;
  final bool ok = e.tsuuka(m);
  final String mm = m.mei;
  // 通過ラインとの差(通過なら次点との差、落選なら最後の通過校との差)
  int lineSa = 0;
  YosenUnivKekka? aite;
  if (e.borderAri) {
    aite = ok ? e.jun[ts] : e.jun[ts - 1];
    lineSa = ok ? saByou(aite.time, m.time) : saByou(m.time, aite.time);
  }
  final String kaisuu = _honsenKaisuuMoji(e, m.u);
  final int mae = juniRace(m.u, race, 1);
  // 通過ラインちょうどの2校(最後の通過校と次点)の差が小さいときは、1人あたりの差も書く
  final bool kyousou =
      aite != null &&
      (m.juni == ts - 1 || m.juni == ts) &&
      lineSa <= e.jitenSaJougen;

  // 見出し
  String midashi;
  if (ok && m.juni == 0) {
    midashi = w.erabu(['$mmがトップ通過', '$mm、堂々のトップ通過']);
  } else if (ok && kaisuu == '初の') {
    midashi = '$mm、悲願の${e.honsenMei}初出場';
  } else if (ok && aite != null && lineSa <= 30) {
    midashi = '$mmが${juniMoji(m.juni)}で通過　次点と${kinsaMoji(lineSa)}';
  } else if (ok) {
    midashi = w.erabu([
      '$mmが${juniMoji(m.juni)}で${e.honsenMei}へ',
      '$mm、${kaisuu}${e.honsenMei}出場決める',
    ]);
  } else if (aite != null && lineSa <= 30) {
    midashi = lineSa <= 0
        ? '$mm、1秒に満たない差で通過逃す'
        : '$mm、通過まで${saMoji(lineSa)}届かず';
  } else {
    midashi = w.erabu(['$mmは${juniMoji(m.juni)}で予選敗退', '$mm、${e.honsenMei}出場ならず']);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}で、$mmは${jikanMoji(m.time)}の${juniMoji(m.juni)}だった。');
  if (ok) {
    lead.write('上位$ts校に入り、${kaisuu}${e.honsenMei}出場を決めた。');
    if (aite != null) {
      lead.write('次点の${aite.mei}とは${kinsaMoji(lineSa)}だった。');
      if (kyousou) {
        lead.write('${e.keisanNinzuu}人の合計で、${hitoriAtariMoji(lineSa, e.keisanNinzuu)}だった。');
      }
    }
  } else if (aite != null) {
    lead.write(
      '通過ラインの$ts位${aite.mei}とは${kinsaMoji(lineSa)}で、${e.honsenMei}への出場はかなわなかった。',
    );
    if (kyousou) {
      lead.write('${e.keisanNinzuu}人が走って、${hitoriAtariMoji(lineSa, e.keisanNinzuu)}だった。');
    }
  }
  if (shutsujouJuni(mae)) {
    if (mae > m.juni) {
      lead.write('前回の${juniMoji(mae)}から順位を上げた。');
    } else if (mae < m.juni) {
      lead.write('前回の${juniMoji(mae)}からは順位を落とした。');
    }
  }

  // 本文
  w.koMidashi('レース');
  if (race == 3) {
    for (int kk = 0; kk < ks; kk++) {
      final List<YosenSenshuKekka> kumi = [
        for (final YosenSenshuKekka y in m.senshu)
          if (y.kumi == kk) y,
      ];
      if (kumi.isEmpty) continue;
      final String hito = kumi
          .map((y) => '${w.senshu(y.s)}は組${juniMoji(y.juni)}')
          .join('、');
      final StringBuffer sb = StringBuffer('${e.kumiMei(kk)}の$hito。');
      sb.write('この組を終えて${juniMoji(m.tuuka[kk])}');
      if (kk > 0) {
        final int g = m.tuuka[kk - 1] - m.tuuka[kk];
        if (g >= 3) {
          sb.write('に浮上した');
        } else if (g <= -3) {
          sb.write('に後退した');
        } else {
          sb.write('となった');
        }
      } else {
        sb.write('で滑り出した');
      }
      sb.write('。');
      w.danraku(sb.toString());
    }
    // 通過圏に入った・出た組
    if (ks >= 2) {
      for (int kk = 1; kk < ks; kk++) {
        final bool maeOk = m.tuuka[kk - 1] < ts;
        final bool imaOk = m.tuuka[kk] < ts;
        if (!maeOk && imaOk && kk == ks - 1) {
          w.danraku('最終組で通過圏に滑り込む、劇的な逆転だった。');
        } else if (maeOk && !imaOk && kk == ks - 1) {
          w.danraku('最終組で通過圏から押し出され、悔しい結末となった。');
        }
      }
    }
  } else if (m.senshu.isNotEmpty) {
    final YosenSenshuKekka ichi = m.senshu.first;
    final StringBuffer sb = StringBuffer();
    sb.write(
      'チームトップは${w.senshu(ichi.s)}で、個人${juniMoji(ichi.juni)}の${jikanMoji(ichi.time)}だった。',
    );
    final int juu = m.senshu.length >= 10 ? 9 : m.senshu.length - 1;
    if (juu >= 1) {
      final YosenSenshuKekka y = m.senshu[juu];
      sb.write(
        'チームの合計に入る${juu + 1}番手は${w.senshu(y.s)}で、個人${juniMoji(y.juni)}。',
      );
    }
    if (m.senshu.length > 10) {
      sb.write('${m.senshu.length - 10}人は合計に入らなかった。');
    }
    w.danraku(sb.toString());
  }
  // チームトップのコメント
  if (m.senshu.isNotEmpty) {
    final SenshuData s = m.senshu.first.s;
    w.comment(
      senshuComment(
        w,
        ok ? CommentBamen.yosenTsuuka : CommentBamen.yosenRakusen,
        w.senshu(s),
        kuyashii: !ok,
      ),
    );
    w.danraku(shusshinShumiBun(k, s, w.r, myouji(s.name)));
  }
  // 1年生
  for (final YosenSenshuKekka y in m.senshu) {
    if (y.s.gakunen != 1 || y.univJuni == 0) continue;
    if (y.univJuni <= 2) {
      w.danraku('1年生の${w.senshu(y.s)}もチーム${y.univJuni + 1}番手と存在感を示した。');
    }
    break;
  }
  w.comment(
    kantokuComment(
      w,
      ok ? KantokuBamen.yosenTsuuka : KantokuBamen.yosenRakusen,
      m.u.id,
      kuyashii: !ok,
    ),
  );
  w.danraku(
    ok
        ? (race == 3 ? '本戦の11月駅伝で、どこまで順位を上げられるか。' : '正月の大舞台へ、新たな戦いが始まる。')
        : (race == 3 ? '気持ちを切り替え、次の戦いに向かう。' : '悔しさを胸に、チームは来季へ再出発する。'),
  );

  // 個人成績の表
  final List<List<String>> gyou = [
    for (final YosenSenshuKekka y in m.senshu)
      [
        if (race == 3) e.kumiMei(y.kumi),
        '${fullMei(y.s.name)}(${y.s.gakunen})',
        race == 3 ? '組${juniMoji(y.juni)}' : juniMoji(y.juni),
        jikanMoji(y.time),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    category: '駅伝予選・$mm',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '$mmの個人成績',
        [if (race == 3) '組', '選手', '順位', 'タイム'],
        gyou,
      ),
    ],
    jibun: true,
  );
}

// ------------------------------------------------------------
// 3. 次点の記事(通過ラインとの差が1人あたり3秒以内(11月駅伝予選)・5秒以内(正月駅伝予選)のとき)
// ------------------------------------------------------------

/// 差の文(次点から見た遅れ。「+12秒」「-9秒」「0秒」)
String _jitenSaMoji(int sa) =>
    sa > 0 ? '+${saMoji(sa)}' : (sa < 0 ? '-${saMoji(-sa)}' : '0秒');

Kiji? _yosenJitenKiji(YosenKekka e) {
  if (!e.jitenKijiAri) return null;
  final KijiKankyou k = e.k;
  const int no = 4;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int ts = e.tsuukaSuu;
  final int nin = e.keisanNinzuu;
  final YosenUnivKekka saigo = e.jun[ts - 1]; // 最後の通過校
  final YosenUnivKekka morashi = e.jun[ts]; // 次点
  final int sa = saByou(morashi.time, saigo.time);
  final String hitori = hitoriAtariMoji(sa, nin);

  // 事実を集める
  final bool nenRenzokuJiten = juniRace(morashi.u, race, 1) == ts; // 前回も次点
  final int maeHonsen = juniRace(morashi.u, e.honsen, 0); // 前回の本戦の順位
  final bool hatsuNogashi =
      !e.honsenMikaisai && shutsujouKaisuu(morashi.u, e.honsen) == 0;
  // どこで差がついたか(正なら次点のほうが遅い)
  // 11月駅伝予選は組ごとの2人の合計、正月駅伝予選は番手ごと(1番手同士、2番手同士…)
  final List<int> kumiSa = [];
  if (race == 3) {
    for (int kk = 0; kk < ks; kk++) {
      final double mt =
          morashi.ruikei[kk] - (kk > 0 ? morashi.ruikei[kk - 1] : 0.0);
      final double st = saigo.ruikei[kk] - (kk > 0 ? saigo.ruikei[kk - 1] : 0.0);
      kumiSa.add((mt - st).round());
    }
  }
  final List<int> banteSa = [];
  if (race == 4) {
    for (int i = 0;
        i < nin && i < morashi.senshu.length && i < saigo.senshu.length;
        i++) {
      banteSa.add((morashi.senshu[i].time - saigo.senshu[i].time).round());
    }
  }

  // 見出し
  String midashi;
  if (sa <= 0) {
    midashi = w.erabu([
      '${morashi.mei}、1秒に満たない差で涙',
      '${morashi.mei}、秒まで同タイムで涙　${e.honsenMei}逃す',
    ]);
  } else {
    midashi = w.erabu([
      '${morashi.mei}、わずか${saMoji(sa)}差で涙',
      '${morashi.mei}、${saMoji(sa)}差の次点　$hitori',
    ]);
  }
  if (nenRenzokuJiten) midashi += '　2年連続の次点';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}で、${morashi.mei}は${juniMoji(morashi.juni)}に終わり、'
    '${e.honsenMei}への出場をあと一歩で逃した。',
  );
  if (sa <= 0) {
    lead.write(
      '$nin人の合計タイムは、$ts位で通過した${saigo.mei}と秒まで同じ${jikanMoji(morashi.time)}。'
      '1秒に満たない差で明暗が分かれた。',
    );
  } else {
    lead.write(
      '$nin人が走って、$ts位で通過した${saigo.mei}との差はわずか${saMoji(sa)}。$hitoriだった。',
    );
  }
  if (nenRenzokuJiten) lead.write('前回に続く、2年連続の次点となった。');

  // 本文: どこで差がついたか
  w.koMidashi('差がついたところ');
  YosenSenshuKekka? kotoba; // コメントをもらう選手
  if (race == 3) {
    int make = -1; // 一番離された組
    int kachi = -1; // 一番詰めた組
    for (int kk = 0; kk < kumiSa.length; kk++) {
      if (kumiSa[kk] > 0 && (make < 0 || kumiSa[kk] > kumiSa[make])) make = kk;
      if (kumiSa[kk] < 0 && (kachi < 0 || kumiSa[kk] < kumiSa[kachi])) {
        kachi = kk;
      }
    }
    final StringBuffer sb = StringBuffer('${saigo.mei}と組ごとに比べると、');
    if (make >= 0 && kachi >= 0) {
      sb.write(
        '${make + 1}組で${saMoji(kumiSa[make])}離されたが、${kachi + 1}組では${saMoji(-kumiSa[kachi])}詰めた。',
      );
    } else if (make >= 0) {
      sb.write('${make + 1}組で${saMoji(kumiSa[make])}の差がついた。');
    } else {
      sb.write('どの組の差もわずかだった。');
    }
    // 途中までは前にいた
    int maeniIta = -1;
    for (int kk = 0; kk < ks - 1; kk++) {
      if (morashi.ruikei[kk] < saigo.ruikei[kk]) maeniIta = kk;
    }
    if (maeniIta >= 0) {
      final int d = saByou(saigo.ruikei[maeniIta], morashi.ruikei[maeniIta]);
      sb.write(
        '${maeniIta + 1}組を終えた時点では、${morashi.mei}が${d > 0 ? '${saMoji(d)}' : 'わずかに'}前にいた。',
      );
    }
    w.danraku(sb.toString());
    // 一番離された組(なければ最終組)で、組の順位が悪かったほうの選手
    final int kumi = make >= 0 ? make : ks - 1;
    for (final YosenSenshuKekka y in morashi.senshu) {
      if (y.kumi != kumi) continue;
      if (kotoba == null || y.juni > kotoba.juni) kotoba = y;
    }
    if (kotoba != null) {
      w.danraku('${kumi + 1}組の${w.senshu(kotoba.s)}は組${juniMoji(kotoba.juni)}だった。');
    }
  } else {
    final int han = (nin + 1) ~/ 2; // 前半の人数(10人なら5人)
    int mae = 0;
    int ato = 0;
    for (int i = 0; i < banteSa.length; i++) {
      if (i < han) {
        mae += banteSa[i];
      } else {
        ato += banteSa[i];
      }
    }
    final StringBuffer sb = StringBuffer(
      '${saigo.mei}と1番手同士、2番手同士…と比べると、',
    );
    if (mae < 0 && ato > 0) {
      sb.write(
        '上位$han人の合計では${morashi.mei}が${saMoji(-mae)}上回っていたが、'
        '${han + 1}番手から$nin番手で${saMoji(ato)}の差をつけられた。',
      );
    } else if (mae > 0 && ato < 0) {
      sb.write(
        '${han + 1}番手から$nin番手では${morashi.mei}が${saMoji(-ato)}上回ったが、'
        '上位$han人で${saMoji(mae)}の差をつけられた。',
      );
    } else {
      sb.write(
        '上位$han人で${_jitenSaMoji(mae)}、${han + 1}番手から$nin番手で${_jitenSaMoji(ato)}の差だった。',
      );
    }
    w.danraku(sb.toString());
    // 合計に入る最後の選手
    if (morashi.senshu.length >= nin && saigo.senshu.length >= nin) {
      final YosenSenshuKekka juu = morashi.senshu[nin - 1];
      final YosenSenshuKekka sJuu = saigo.senshu[nin - 1];
      final int d = saByou(juu.time, sJuu.time);
      w.danraku(
        '合計に入る最後の$nin番手は${w.senshu(juu.s)}で、個人${juniMoji(juu.juni)}。'
        '${d > 0 ? '${saigo.mei}の$nin番手より${saMoji(d)}遅かった。' : (d < 0 ? '${saigo.mei}の$nin番手には${saMoji(-d)}先着していた。' : '${saigo.mei}の$nin番手とほぼ同じタイムだった。')}',
      );
      kotoba = juu;
    }
  }
  if (kotoba != null) {
    w.comment(
      senshuComment(
        w,
        CommentBamen.yosenJiten,
        myouji(kotoba.s.name),
        kuyashii: true,
      ),
    );
  }
  w.comment(
    kantokuComment(w, KantokuBamen.yosenJiten, morashi.u.id, kuyashii: true),
  );

  // 本文: 逃したもの
  final StringBuffer nogashi = StringBuffer();
  if (shutsujouJuni(maeHonsen)) {
    final ({int kaisuu, bool kakutei}) rz = renzokuKakutei(
      morashi.u,
      e.honsen,
      0,
      shutsujouJuni,
      shutsujouKaisuu(morashi.u, e.honsen),
    );
    nogashi.write(
      '前回の${e.honsenMei}で${juniMoji(maeHonsen)}だった${morashi.mei}は、'
      '${!rz.kakutei ? '長く続いた連続出場が途切れた。' : (rz.kaisuu >= 2 ? '連続出場が${rz.kaisuu}年で途切れた。' : '2年連続の出場はならなかった。')}',
    );
  } else if (hatsuNogashi) {
    nogashi.write('初の${e.honsenMei}出場には、あと一歩届かなかった。');
  }
  nogashi.write(w.erabu(['この悔しさを、来年への力に変える。', 'わずかな差を埋める戦いが、ここから始まる。']));
  w.danraku(nogashi.toString());
  w.comment(kantokuComment(w, KantokuBamen.yosenTsuuka, saigo.u.id));

  // 2校の比べの表(差は次点から見た遅れ)
  final List<List<String>> gyou = [];
  if (race == 3) {
    for (int kk = 0; kk < ks; kk++) {
      final double mt =
          morashi.ruikei[kk] - (kk > 0 ? morashi.ruikei[kk - 1] : 0.0);
      final double st = saigo.ruikei[kk] - (kk > 0 ? saigo.ruikei[kk - 1] : 0.0);
      gyou.add([
        '${kk + 1}組',
        jikanMoji(mt),
        jikanMoji(st),
        _jitenSaMoji(kumiSa[kk]),
      ]);
    }
  } else {
    for (int i = 0; i < banteSa.length; i++) {
      gyou.add([
        '${i + 1}番手',
        jikanMoji(morashi.senshu[i].time),
        jikanMoji(saigo.senshu[i].time),
        _jitenSaMoji(banteSa[i]),
      ]);
    }
  }
  gyou.add([
    '合計',
    jikanMoji(morashi.time),
    jikanMoji(saigo.time),
    sa <= 0 ? '1秒未満' : '+${saMoji(sa)}',
  ]);
  return _kansei(
    k,
    no,
    w,
    category: '駅伝予選・次点',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '${morashi.mei}と${saigo.mei}の比べ(差は${morashi.mei}の遅れ)',
        [race == 3 ? '組' : '番手', morashi.mei, saigo.mei, '差'],
        gyou,
      ),
    ],
    jibun:
        morashi.u.id == k.gh.MYunivid || saigo.u.id == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 4. 個人の記事
// ------------------------------------------------------------

Kiji? _yosenKojinKiji(YosenKekka e) {
  if (e.kojin.length < 3) return null;
  final KijiKankyou k = e.k;
  const int no = 3;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;

  if (race == 3) {
    // 2位との差が一番大きい組のトップ(新記録があればそちらを先に)
    YosenSenshuKekka? mvp;
    int mvpTen = -1;
    for (int kk = 0; kk < ks; kk++) {
      final YosenSenshuKekka? t = e.kumiTop(kk);
      final double? niTime = e.kumiTime(kk, 1);
      if (t == null || niTime == null) continue;
      final int sa = saByou(niTime, t.time);
      final int ten = (e.shinkiroku(t.s) ? 1000 : 0) + sa;
      if (ten > mvpTen) {
        mvpTen = ten;
        mvp = t;
      }
    }
    if (mvp == null) return null;
    final double mvpNi = e.kumiTime(mvp.kumi, 1) ?? mvp.time;
    final int mvpSa = saByou(mvpNi, mvp.time);
    final bool mvpShin = e.shinkiroku(mvp.s);
    final String um = e.univMei(mvp.s.univid);
    final String midashi = mvpShin
        ? '${myouji(mvp.s.name)}($um)が${e.kumiMei(mvp.kumi)}で組の新記録'
        : w.erabu([
            '${e.kumiMei(mvp.kumi)}は${myouji(mvp.s.name)}($um)が${saMoji(mvpSa)}差の独走',
            '${myouji(mvp.s.name)}($um)、${e.kumiMei(mvp.kumi)}トップ',
          ]);
    final StringBuffer lead = StringBuffer();
    lead.write(
      '${k.taikaiMei}の${e.kumiMei(mvp.kumi)}は、${w.senshu(mvp.s, daigaku: true)}が'
      '${jikanMoji(mvp.time)}でトップを取った。',
    );
    if (mvpShin) {
      lead.write('この組の新記録となった。');
    } else if (mvpSa >= 5) {
      lead.write('2位に${saMoji(mvpSa)}差をつける快走だった。');
    } else {
      lead.write('最後まで続いた競り合いを制した。');
    }
    final StringBuffer sb = StringBuffer();
    if (mvp.s.hirou == 1) sb.write('留学生らしい力強い走りで、集団を引き離した。');
    if (mvp.s.gakunen == 1) sb.write('1年生ながら、上級生を相手に堂々の走りだった。');
    w.danraku(sb.toString());
    w.comment(senshuComment(w, CommentBamen.yosenKojinTop, myouji(mvp.s.name)));
    w.danraku(shusshinShumiBun(k, mvp.s, w.r, myouji(mvp.s.name)));
    w.koMidashi('各組のトップ');
    for (int kk = 0; kk < ks; kk++) {
      if (kk == mvp.kumi) continue;
      final YosenSenshuKekka? t = e.kumiTop(kk);
      if (t == null) continue;
      final double? niTime = e.kumiTime(kk, 1);
      final int sa = niTime == null ? 0 : saByou(niTime, t.time);
      w.danraku(
        '${e.kumiMei(kk)}は${w.senshu(t.s, daigaku: true)}が${jikanMoji(t.time)}でトップ'
        '${e.shinkiroku(t.s) ? '(組の新記録)' : ''}。'
        '${sa <= 1 ? '2位とはわずか${saMoji(sa)}差だった。' : '2位に${saMoji(sa)}差をつけた。'}',
      );
    }
    // 各組の上位3人の表
    final List<List<String>> gyou = [];
    for (int kk = 0; kk < ks; kk++) {
      for (final YosenSenshuKekka y in e.kojin) {
        if (y.kumi != kk || y.juni > 2) continue;
        gyou.add([
          e.kumiMei(kk),
          juniMoji(y.juni),
          '${fullMei(y.s.name)}(${y.s.gakunen})',
          e.univMei(y.s.univid),
          jikanMoji(y.time),
        ]);
      }
    }
    return _kansei(
      k,
      no,
      w,
      category: '駅伝予選・個人',
      midashi: midashi,
      lead: lead.toString(),
      hyou: [
        KijiHyou('各組の上位3人', ['組', '順位', '選手', '大学', 'タイム'], gyou),
      ],
      jibun: mvp.s.univid == k.gh.MYunivid,
    );
  }

  // 正月駅伝予選: 個人トップと日本人トップ
  final YosenSenshuKekka t = e.kojin[0];
  final int sa = saByou(e.kojin[1].time, t.time);
  final bool shin = e.shinkiroku(t.s);
  YosenSenshuKekka? nihon;
  if (t.s.hirou == 1) {
    for (final YosenSenshuKekka y in e.kojin) {
      if (y.s.hirou != 1) {
        nihon = y;
        break;
      }
    }
  }
  final String um = e.univMei(t.s.univid);
  String midashi = shin
      ? '${myouji(t.s.name)}($um)が大会新で個人トップ'
      : w.erabu([
          '個人トップは${myouji(t.s.name)}($um)',
          '${myouji(t.s.name)}($um)が個人トップ　${jikanMoji(t.time)}',
        ]);
  if (nihon != null) {
    midashi += '　日本人トップは${myouji(nihon.s.name)}(${e.univMei(nihon.s.univid)})';
  }
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}の個人の部は、${w.senshu(t.s, daigaku: true)}が${jikanMoji(t.time)}でトップだった。',
  );
  if (shin) {
    lead.write('大会新記録のおまけつきだった。');
  } else if (sa >= 10) {
    lead.write('2位に${saMoji(sa)}差をつけた。');
  } else {
    lead.write('2位とは${saMoji(sa)}差の接戦を制した。');
  }
  if (nihon != null) {
    lead.write(
      '日本人トップは個人${juniMoji(nihon.juni)}の${w.senshu(nihon.s, daigaku: true)}で、'
      '${jikanMoji(nihon.time)}だった。',
    );
  }
  // 前回もトップか
  final int? maeJ = k.kukanJuniMae(t.s, race, 1);
  if (maeJ == 0) {
    w.danraku('${myouji(t.s.name)}は前回も個人トップで、2年連続の快挙となった。');
  } else if (maeJ != null) {
    w.danraku('前回は個人${juniMoji(maeJ)}だった${myouji(t.s.name)}が、大きく順位を上げた。');
  } else if (t.s.gakunen == 1) {
    w.danraku('${myouji(t.s.name)}は1年生。初めての予選で、いきなり頂点に立った。');
  }
  w.comment(senshuComment(w, CommentBamen.yosenKojinTop, myouji(t.s.name)));
  w.danraku(shusshinShumiBun(k, t.s, w.r, myouji(t.s.name)));
  if (nihon != null) {
    w.comment(senshuComment(w, CommentBamen.yosenKojinTop, myouji(nihon.s.name)));
  }
  // 1年生トップ
  for (final YosenSenshuKekka y in e.kojin) {
    if (y.s.gakunen != 1 || y.s.id == t.s.id) continue;
    if (nihon != null && y.s.id == nihon.s.id) break;
    if (y.juni >= 30) break;
    w.danraku(
      '1年生トップは個人${juniMoji(y.juni)}の${w.senshu(y.s, daigaku: true)}だった。',
    );
    break;
  }
  // 通過を逃した大学の上位の選手
  for (final YosenSenshuKekka y in e.kojin) {
    if (y.juni >= 10) break;
    YosenUnivKekka? x;
    for (final YosenUnivKekka u in e.jun) {
      if (u.u.id == y.s.univid) x = u;
    }
    if (x == null || e.tsuuka(x)) continue;
    w.danraku(
      '${x.mei}の${w.senshu(y.s)}は個人${juniMoji(y.juni)}と好走したが、チームは${juniMoji(x.juni)}で通過を逃した。',
    );
    break;
  }
  final List<List<String>> gyou = [
    for (final YosenSenshuKekka y in e.kojin.take(20))
      [
        juniMoji(y.juni),
        '${fullMei(y.s.name)}(${y.s.gakunen})',
        e.univMei(y.s.univid),
        jikanMoji(y.time),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    category: '駅伝予選・個人',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('個人成績(上位20人)', ['順位', '選手', '大学', 'タイム'], gyou),
    ],
    jibun: t.s.univid == k.gh.MYunivid,
  );
}
