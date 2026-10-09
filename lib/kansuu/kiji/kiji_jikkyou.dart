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
