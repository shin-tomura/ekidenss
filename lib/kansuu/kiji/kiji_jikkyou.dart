import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// 駅伝の実況「箱庭スポーツ中継」(1.9.4。レース画面の「実況」のカードと、結果画面の記事の画面)
//
// ・レースは区間ごとに進むので、区間が終わるたびに、その区間を中継風に語る記事を1本作る。
//   記事の画面では、終わったばかりの区間を一番上にして、1区からの実況が並ぶ
// ・実況アナと解説者の掛け合い。実況は「〜です！」の話し言葉の段落、解説はコメントの枠(左に線)。
//   解説者は大会ごとに1人(名前から記者の型が決まり、数字で語る・情景で語る・辛口の違いがある)
// ・書くのは、その時点で画面で見えていることだけ
//   ・たすきを受けた順位と差、抜いた相手、首位交代、区間賞、1区の集団のペースと飛び出し、
//     自分の大学の指示とその成否、目標順位を下回っての焦り・ほっと一息、学連選抜、因縁
//   ・能力は、選手ごとの補正の説明(string_racesetumei。見抜く力のついた能力だけ書かれている)に
//     出ている分だけ、数字なしで触れる。隠れている能力は見ない(解説も知らない体にする)
// ・記事と同じく、年・大会・区間で決まる乱数を使うので、何度開いても同じ実況になる
// ・最終区は、ゴールの瞬間までを語る。総括は結果の記事(kiji_kekka.dart)に任せる
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
}

/// 補正の説明の読み取り(数字は読まず、何があったかだけを拾う)
_Hashiri _hashiriYomu(SenshuData s, int kk) {
  final _Hashiri h = _Hashiri();
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
  final int? seed = race == 1 ? 8 : (race == 2 ? 10 : null);
  final int mokuhyou = (my != null && my.u.mokuhyojuni.length > race) ? my.u.mokuhyojuni[race] : -1;
  final bool mokuhyouAri = my != null && mokuhyou >= 0 && mokuhyou < n;
  // 解説のコメント(左に線の枠で出す)
  void kai(String bun) => w.comment('解説・$kaisetsu「$bun」');

  // 見出し
  String midashi;
  if (saigo) {
    midashi = w.erabu(['${shui.mei}が優勝のゴール！', '${shui.mei}、歓喜のフィニッシュ']);
    if (sa12 <= ks * 3) midashi += '　2位と${kinsaMoji(sa12)}';
  } else if (shuiMae != null && shuiMae.u.id != shui.u.id) {
    midashi = '${kk + 1}区で首位交代　${shui.mei}が${shuiMae.mei}をかわす';
  } else if (ue != null && ueKazu >= 3 && ue.s != null) {
    midashi = '${kk + 1}区　${shui.mei}が首位守る　${ue.mei}・${myouji(ue.s!.name)}が$ueKazu人抜き';
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
    final IkkuPaceKekka? pace = ikkuPaceKekkaYomu(k.kantoku, k.gh);
    if (pace != null && pace.pacemakerId != null && pace.pacemakerId! >= 0 && pace.pacemakerId! < k.senshu.length) {
      final SenshuData pm = k.senshu[pace.pacemakerId!];
      final String pmDaigaku = (pm.univid >= 0 && pm.univid < k.univ.length) ? '${daigakuMeiMoji(k.univ[pm.univid].name)}・' : '';
      lead.write('集団を引っ張るのは$pmDaigaku${w.senshu(pm)}。${ikkuPaceMidashiMoji[pace.midashi]}の展開です。');
      final int tobidashi = pace.kazu.length > 4 ? pace.kazu[4] : 0;
      if (tobidashi >= 1) lead.write('スタート直後から$tobidashi人が飛び出しました！');
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
    kai(
      si.isNotEmpty && si.first.ten >= 45
          ? '${myouji(shui.s!.name)}、${si.first.kotoba}、という思いがあったはずです。それを形にしましたね'
          : '${saMoji(saMae12)}差を一人で埋めるのは簡単ではありません。${myouji(shui.s!.name)}は前が見えてから、しっかりギアを上げましたね',
    );
  } else if (kk > 0 && !saigo && sa12 > saMae12 + 5 && shui.s != null) {
    kai('${myouji(shui.s!.name)}は後ろを気にせず、自分の走りに徹しましたね。差が広がったのは、その落ち着きです');
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
    // シード権のラインの出入り
    if (seed != null && n > seed) {
      final List<String> iri = [
        for (final _Koma x in jun)
          if (x.tuuka < seed && x.tuukaMae >= seed) x.mei,
      ];
      final List<String> de = [
        for (final _Koma x in jun)
          if (x.tuuka >= seed && x.tuukaMae < seed) x.mei,
      ];
      if (iri.isNotEmpty) ub.write('シード権の${juniMoji(seed - 1)}以内に${iri.join('、')}が入り、');
      if (de.isNotEmpty) ub.write('${iri.isEmpty ? 'シード権の${juniMoji(seed - 1)}以内から' : ''}${de.join('、')}が圏外に下がりました。');
      if (iri.isNotEmpty && de.isEmpty) ub.write('圏外に下がった大学はありません。');
    }
    if (ub.isNotEmpty) {
      w.koMidashi('順位の動き');
      w.danraku(ub.toString());
    }
  }

  // 本文: 自分の大学
  if (my != null && my.s != null) {
    final SenshuData s = my.s!;
    final _Hashiri h = _hashiriYomu(s, kk);
    w.koMidashi('${my.mei}の${kk + 1}区');
    final String yobi = w.senshu(s);
    final StringBuffer mb = StringBuffer();
    // 指示
    if (kk == 0) {
      if (h.siji == 1 && h.seikou != null) {
        mb.write(h.seikou! ? '$yobiはスタート直後に飛び出し、狙いどおりの展開に持ち込みました。' : '$yobiはスタート直後に飛び出しましたが、後半に苦しみました。');
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
    if (kk == 0) {
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
    if (seed != null && n > seed && my.tuuka >= seed) {
      saList.add('シード権の${juniMoji(seed - 1)}まで${kinsaMoji(saByou(my.ruikei, jun[seed - 1].ruikei))}');
    }
    if (saList.isNotEmpty) mb.write('${saList.join('、')}です。');
    w.danraku(mb.toString());
    // 解説(見えている能力・因縁)
    final List<Innen> mi = senshuInnen(k, s, kk, kj: my.kukanJuni, kekka: owatta);
    final bool yoi = my.kukanJuni <= n ~/ 3;
    final bool warui = n >= 6 && my.kukanJuni >= (n * 3) ~/ 4;
    if (yoi && h.tsuyomi != null && h.tsuyomi!.juni <= 3) {
      kai('${myouji(s.name)}は${h.tsuyomi!.mei}がこの区間の選手の中で${h.tsuyomi!.juni}番目。それが順位に出ましたね');
    } else if (warui && h.yowami != null && h.yowami!.juni >= n - 2) {
      kai('${myouji(s.name)}は${h.yowami!.mei}で差をつけられました。この区間との相性が出てしまいましたね');
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
      w.danraku(
        'オープン参加の学連選抜は$gy(${daigakuMeiMoji(g.shozoku)})が区間${juniMoji(g.kukanJuni)}相当。'
        '通過は${juniMoji(g.tuukaJuni)}相当です。'
        '${kantoku && g.kukanJuni == 0 ? '監督の采配が光りました！' : ''}',
      );
    }
  }

  // 本文: 次の区間の見どころ(最終区のあとは、総括を記事に任せる)
  if (!saigo) {
    final int tsugi = kk + 1;
    w.koMidashi(ouroOwari ? '往路を終えて' : '次の${tsugi + 1}区へ');
    final StringBuffer nb = StringBuffer();
    if (ouroOwari) {
      nb.write('往路はここまで。${shui.mei}が往路優勝、2位の${ni.mei}とは${kinsaMoji(sa12)}です。復路のスタートは往路の差のままです。');
    }
    final String tsugiMei = kukanYobikata(k.gh, race, tsugi, ks);
    final String tsugiKyori = kmMoji(k.gh.kyori_taikai_kukangoto[race][tsugi]);
    nb.write('${ouroOwari ? '復路の' : ''}$tsugiMeiは$tsugiKyori。');
    // 次の区間の持ちタイム上位
    final int idx = kukanShumoku(k.gh, race, tsugi).first;
    final List<SenshuData> tsugiHashiru = [
      for (final SenshuData x in k.senshu)
        if (k.entry(x) == tsugi && x.univid >= 0 && x.univid < k.univ.length && k.shutsujou(k.univ[x.univid])) x,
    ];
    final List<SenshuData> mochiJun = [
      for (final SenshuData x in tsugiHashiru)
        if (k.jikoBest(x, idx) < TEISUU.DEFAULTTIME) x,
    ]..sort((a, b) => k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx)));
    if (mochiJun.isNotEmpty) {
      final SenshuData top = mochiJun.first;
      nb.write('${kijiShumokuMei[idx]}の持ちタイムでは${daigakuMeiMoji(k.univ[top.univid].name)}・${w.senshu(top)}(${jikanMoji(k.jikoBest(top, idx))})がトップです。');
    }
    if (my != null) {
      final int myId = my.u.id;
      final SenshuData? myTsugi = tsugiHashiru.where((x) => x.univid == myId).firstOrNull;
      if (myTsugi != null) {
        final int myTsugiId = myTsugi.id;
        final int mj = mochiJun.indexWhere((x) => x.id == myTsugiId);
        nb.write('${my.mei}は${w.senshu(myTsugi)}${mj >= 0 ? '(持ちタイムは区間内${mj + 1}番目)' : ''}にたすきが渡ります。');
        final List<Innen> ti = senshuInnen(k, myTsugi, tsugi, kekka: false);
        if (ti.isNotEmpty && ti.first.ten >= 45) nb.write(ti.first.bun);
      }
    }
    w.danraku(nb.toString());
    if (kata == KishaKata.suuji && my != null && mokuhyouAri && my.tuuka > mokuhyou) {
      final int nokori = ks - tsugi;
      final int sa = saByou(my.ruikei, jun[mokuhyou].ruikei);
      kai('目標の${juniMoji(mokuhyou)}まで${kinsaMoji(sa)}。残り$nokori区間ですから、1区間あたり${(sa / nokori).toStringAsFixed(0)}秒ずつ詰めれば届く計算です');
    } else if (kata == KishaKata.joukei && my != null && my.tuuka <= 2 && !saigo) {
      kai('${my.mei}は${juniMoji(my.tuuka)}。ここからは、たすきの重さが変わってきますよ');
    }
  } else {
    w.koMidashi('ゴール');
    w.danraku(
      w.erabu([
        '$n校がそれぞれの思いを乗せてゴールに飛び込みました。${k.taikaiMei}、全区間の中継を終わります。',
        '全$ks区間、$n校のたすきが無事につながりました。中継は以上です。詳しい結果は、記事でお伝えします。',
      ]),
    );
    kai(kata == KishaKata.karakuchi ? '勝負の分かれ目は、派手な区間賞より、崩れなかった区間にありましたね' : '最後まで目が離せないレースでした。選手のみなさん、お疲れさまでした');
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
  return Kiji(
    category: '駅伝・実況',
    midashi: midashi,
    lead: lead.toString(),
    honbun: w.honbun,
    hyou: [
      KijiHyou('${kk + 1}区終了時点の順位', ['順位', '大学', '${kk + 1}区の選手', '区間順位', 'トップ差'], gyou),
    ],
    haishin: '${k.gh.year}年${k.gh.month}月${k.gh.day}日 ${kk + 1}区終了時点',
    kisha: '実況・$ana　解説・$kaisetsu',
    jibun: my != null,
    kekka: true,
    site: jikkyouSiteMei,
  );
}
