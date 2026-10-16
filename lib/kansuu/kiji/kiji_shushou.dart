import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart' show EkidenKekka, EkidenUnivKekka;

// ------------------------------------------------------------
// 主将のコメント(2.0.2。shushou.dart)
//
// 記事の監督のコメントに続けて、主将のチームとしてのコメントを入れる
// ・入れる記事: 学内メディアの駅伝の結果号(チームの記事)と展望号(選手名鑑)、
//   箱庭スポーツの駅伝の結果のトップ記事(優勝校。主将が走者として話したあとは入れない)
// ・何年も読んでも飽きないように:
//   ・口調: 主将ごとに、熱い・冷静・仲間思い・謙虚のどれか(選手idから決める。同じ主将はいつも同じ口調。
//     能力とは関係なく決めるので、能力の手がかりにはならない)
//   ・部品の組み合わせ: 気持ち(場面と口調で選ぶ)+その日の事実(0〜1つ)+次への言葉(主将の立場で選ぶ)
//   ・立場: 4年生の主将の正月駅伝は「最後の駅伝」、3年生の主将の正月駅伝は「来年」、それ以外はふつうの言葉
//   ・締め(「と胸を張った」など)も口調で変える
// ・書かないこと(ほかの記事と同じ): 総監督の采配・区間配置・当日変更の意図、能力の名前や特徴の言葉、
//   主将の特典(目標順位による補正)、主将が走らなかった理由
// ・名前は、初めては「主将の山田太郎(4年)」(文で主将と書くので、かっこに「・主将」は付けない)、2回目からは「主将の山田」
// ------------------------------------------------------------

/// 主将のコメントの場面
enum ShushouBamen {
  /// 駅伝の結果: 優勝
  yuushou,

  /// 駅伝の結果: 目標達成(シード権の獲得も)
  tassei,

  /// 駅伝の結果: 目標に届かなかった(シード権を失ったときも)
  mitassei,

  /// 駅伝の展望: 前回優勝の大学
  tenbouHonmei,

  /// 駅伝の展望: そのほか
  tenbouChousen,
}

/// 主将の口調
enum _Kuchou { atsui, reisei, nakama, kenkyo }

/// 主将[c]の口調(選手idから決める。年や大会では変わらない)
_Kuchou _kuchou(SenshuData c) =>
    _Kuchou.values[KijiRand(c.id * 7919 + 104729).ikutsu(_Kuchou.values.length)];

/// 結果の場面か
bool _kekkaBamen(ShushouBamen b) =>
    b == ShushouBamen.yuushou ||
    b == ShushouBamen.tassei ||
    b == ShushouBamen.mitassei;

/// 気持ちの言葉(場面 → 口調 → 候補。「。」で終えない)
const Map<ShushouBamen, Map<_Kuchou, List<String>>> _kimochi = {
  ShushouBamen.yuushou: {
    _Kuchou.atsui: [
      '最高です！　全員でつかんだ優勝です',
      'この瞬間のために、みんなで走ってきた。最高のチームです',
      '絶対に勝つと決めていた。仲間を信じてよかった',
    ],
    _Kuchou.reisei: [
      '一人ひとりが自分の役割を果たした結果だと思います',
      '流れが来るまで我慢できたのが大きかった',
      '準備してきたことを、そのまま出せました',
    ],
    _Kuchou.nakama: [
      '走った選手も、支えてくれた部員も、全員でつかんだ優勝です',
      '走れなかった仲間の思いも背負って戦いました。みんなに感謝したい',
      'ゴールの瞬間、チーム全員の顔が浮かびました。このチームでよかった',
    ],
    _Kuchou.kenkyo: [
      '主将として何かできたわけではありません。仲間が強かった',
      'まだ実感がありません。みんなに助けられてばかりでした',
      '自分はみんなの背中についていっただけです',
    ],
  },
  ShushouBamen.tassei: {
    _Kuchou.atsui: [
      '全員が最後まで攻めてくれた。熱い駅伝でした',
      '手応えのある駅伝でした。ここからもっと上を狙う',
      'たすきに込めた思いが、結果につながった',
    ],
    _Kuchou.reisei: [
      'やるべきことはできました。課題も見えたので、次に生かします',
      '思い描いていた流れで、レースを進められました',
      '一人ひとりが崩れなかった。それが一番の収穫です',
    ],
    _Kuchou.nakama: [
      'みんなが本当によく走ってくれた。誇らしいです',
      'つないでくれた仲間に、感謝しかありません',
      '走った選手も、支えた部員も、全員の力です',
    ],
    _Kuchou.kenkyo: [
      'みんなのおかげです。自分ももっと引っ張れるようになりたい',
      '仲間に助けられました。主将としてはまだまだです',
      'ほっとしています。みんなが頑張ってくれました',
    ],
  },
  ShushouBamen.mitassei: {
    _Kuchou.atsui: [
      '悔しい。この悔しさは絶対に忘れない',
      'このままでは終われない。必ずやり返します',
      '悔しさしかない。でも、下を向いている暇はない',
    ],
    _Kuchou.reisei: [
      '足りなかったものは、はっきりしています。一つずつ埋めていきます',
      '流れをつかみきれなかった。原因をしっかり見直します',
      '結果は受け止めます。次に向けて切り替えます',
    ],
    _Kuchou.nakama: [
      'みんな最後まで粘ってくれた。結果で報いてあげられなくて悔しい',
      '誰か一人のせいではありません。チームで受け止めます',
      '苦しい中でも、たすきをつないでくれた仲間を誇りに思います',
    ],
    _Kuchou.kenkyo: [
      '主将として、チームを引っ張りきれませんでした',
      '自分に、もっとできることがあったと思います',
      'みんなに申し訳ない気持ちです。もう一度チームを作り直します',
    ],
  },
  ShushouBamen.tenbouHonmei: {
    _Kuchou.atsui: [
      '狙うのは優勝だけです。全員で攻めます',
      '追われる立場でも、攻める気持ちは変わらない',
    ],
    _Kuchou.reisei: [
      'やるべきことをやれば、結果はついてくると思います',
      '周りは気にせず、自分たちのレースをするだけです',
    ],
    _Kuchou.nakama: [
      'このメンバーなら大丈夫。みんなを信じています',
      '走る選手も、支える部員も、全員で戦います',
    ],
    _Kuchou.kenkyo: [
      '期待されているのは分かっています。一つずつ積み重ねるだけです',
      '自分たちは、まだ挑戦者のつもりです',
    ],
  },
  ShushouBamen.tenbouChousen: {
    _Kuchou.atsui: [
      '上のチームを、一つでも多く倒してやる',
      '思い切って攻めます。何が起きるか分からないのが駅伝です',
    ],
    _Kuchou.reisei: [
      '準備はできています。あとは当日、力を出し切るだけ',
      '自分たちの力を出せれば、十分に戦えると思っています',
    ],
    _Kuchou.nakama: [
      'このチームでたすきをつなげるのが楽しみです',
      'みんなで練習してきたことを信じて走ります',
    ],
    _Kuchou.kenkyo: [
      '挑戦する立場です。一つでも上を目指します',
      '自分たちにできることを、一つずつやるだけです',
    ],
  },
};

/// 締めの言葉(「と」で始まる。場面の種類 → 口調 → 候補)
const Map<_Kuchou, List<String>> _shimeYoi = {
  _Kuchou.atsui: ['と声を弾ませた', 'と拳を握った', 'と胸を張った'],
  _Kuchou.reisei: ['と冷静に振り返った', 'と淡々と語った', 'と話した'],
  _Kuchou.nakama: ['と仲間を見渡した', 'と笑顔を見せた', 'と話した'],
  _Kuchou.kenkyo: ['と照れくさそうに話した', 'と控えめに語った', 'と振り返った'],
};
const Map<_Kuchou, List<String>> _shimeKuyashii = {
  _Kuchou.atsui: ['と悔しさをあらわにした', 'と語気を強めた', 'と前を向いた'],
  _Kuchou.reisei: ['と静かに語った', 'と前を向いた', 'と話した'],
  _Kuchou.nakama: ['と仲間をねぎらった', 'と前を向いた', 'と話した'],
  _Kuchou.kenkyo: ['と唇をかんだ', 'と声を落とした', 'と前を向いた'],
};
const Map<_Kuchou, List<String>> _shimeTenbou = {
  _Kuchou.atsui: ['と意気込んだ', 'と力を込めた'],
  _Kuchou.reisei: ['と落ち着いた表情で語った', 'と話した'],
  _Kuchou.nakama: ['と仲間への信頼を口にした', 'と笑顔を見せた'],
  _Kuchou.kenkyo: ['と控えめに語った', 'と気を引き締めた'],
};

/// 次への言葉(結果。うまくいったとき・悔しいとき)
const List<String> _tsugiYoi = [
  'ここからチームを、もう一段上げていきます',
  'この勢いを、次につなげます',
  '満足せずに、次に向かいます',
];
const List<String> _tsugiKuyashii = [
  'すぐに切り替えて、次でやり返します',
  'この悔しさを、次につなげます',
  'ここからチームを立て直します',
];

/// 次への言葉(4年生の主将の、最後の正月駅伝のあと)
const List<String> _tsugiSaigo = [
  'このチームで走る駅伝は、これで最後。後輩たちには、この先の景色を見てほしい',
  '最後の駅伝を、このチームで迎えられて幸せでした',
  '主将としての駅伝は、これで終わりです。あとは後輩たちに託します',
];

/// 次への言葉(3年生の主将の、正月駅伝のあと)
const List<String> _tsugiRainen = [
  '来年も、このチームでもう一度ここに挑みたい',
  'この経験を、来年のチームにつなげます',
];

/// 次への言葉(展望。{R}は大会の名前)
const List<String> _tenbouTsugi = [
  '最後まで、全員でたすきをつなぎます',
  '自分たちの駅伝を見せたい',
  '応援してくれる人たちに、いい報告をしたい',
];

/// 次への言葉(展望。4年生の主将。{R}は大会の名前)
const List<String> _tenbouSaigo = [
  '4年生にとっては最後の{R}です。全員で笑って終わりたい',
  '最後の{R}を、このチームで迎えられてうれしい。悔いのない駅伝にします',
];

/// 大学[univid]の主将(いなければnull。記事を作るときの主将)
SenshuData? shushouSenshu(KijiKankyou k, int univid) {
  final int? id = k.shushouId[univid];
  if (id == null) return null;
  for (final SenshuData s in k.senshu) {
    if (s.id == id) return s;
  }
  return null;
}

/// 主将[c]のコメントの文(「「……」と主将の山田太郎(4年)は胸を張った。」の形)
/// [jijitsu] その日の事実の話し言葉(「。」なし。この中から1つまで使う)、
/// [daigaku] 大学の名前(箱庭スポーツで「東西大主将の山田太郎(4年)」と書くとき。学内メディアは空)
String shushouComment(
  KijiKakite w,
  SenshuData c,
  ShushouBamen bamen, {
  List<String> jijitsu = const [],
  String daigaku = '',
}) {
  final _Kuchou kc = _kuchou(c);
  final bool kekka = _kekkaBamen(bamen);
  final bool kuyashii = bamen == ShushouBamen.mitassei;
  final String kimochi = w.erabu(_kimochi[bamen]?[kc] ?? const ['全員で戦います']);
  final List<String> j = [
    for (final String x in jijitsu)
      if (x.trim().isNotEmpty) x.trim(),
  ];
  final String? jitsu = j.isEmpty ? null : w.erabu(j);
  // 次への言葉(主将の立場で選ぶ)
  final bool shougatsu = w.k.race == 2;
  String tsugi;
  bool kanarazu = false; // 最後の駅伝などの大事な言葉は、必ず入れる
  if (kekka) {
    if (shougatsu && c.gakunen == 4) {
      tsugi = w.erabu(_tsugiSaigo);
      kanarazu = true;
    } else if (shougatsu && c.gakunen == 3) {
      tsugi = w.erabu(_tsugiRainen);
    } else {
      tsugi = w.erabu(kuyashii ? _tsugiKuyashii : _tsugiYoi);
    }
  } else {
    if (c.gakunen == 4) {
      tsugi = w.erabu(_tenbouSaigo).replaceAll('{R}', w.k.raceMei);
      kanarazu = shougatsu;
    } else {
      tsugi = w.erabu(_tenbouTsugi);
    }
  }
  // 組み立て(長くなりすぎないように、気持ちが2文なら、事実か次への言葉のどちらか)
  final bool nibun = kimochi.contains('。');
  final List<String> bu = [kimochi];
  if (kanarazu) {
    if (jitsu != null && !nibun) bu.add(jitsu);
    bu.add(tsugi);
  } else {
    if (jitsu != null) bu.add(jitsu);
    if (jitsu == null || (!nibun && w.r.kakuritsu(50))) bu.add(tsugi);
  }
  // ときどき事実から話し始める
  if (jitsu != null && bu.length >= 2 && bu[1] == jitsu && w.r.kakuritsu(40)) {
    bu
      ..removeAt(1)
      ..insert(0, jitsu);
  }
  final String naka = bu.join('。');
  final String shime = w.erabu(
    (kekka ? (kuyashii ? _shimeKuyashii : _shimeYoi) : _shimeTenbou)[kc] ??
        const ['と話した'],
  );
  final String yobi = w.hito('S${c.id}', c.name, '${c.gakunen}年', '');
  return '「$naka」と$daigaku主将の$yobiは${shime.substring(1)}。';
}

/// 駅伝の結果の、主将が話す事実(話し言葉。「。」なし)
/// [mokuhyou] 目標順位(0が1位。なければnull)、[mae] 前回の順位(0が1位。なければnull)、
/// [seedNow]・[seedMae] シード権のある大会で、今回・前回シード権を取ったか(シード権のない大会はnull)
List<String> shushouKekkaJijitsu(
  EkidenKekka e,
  EkidenUnivKekka m,
  SenshuData c, {
  int? mokuhyou,
  int? mae,
  bool? seedNow,
  bool seedMae = false,
}) {
  final int n = e.n;
  final int ks = m.senshu.length;
  final int r = m.juni;
  final List<String> j = [];
  // 自分の走り
  for (int kk = 0; kk < ks; kk++) {
    if (m.senshu[kk]?.id != c.id) continue;
    final int kj = m.kukanJuni[kk];
    if (kj == 0) {
      j.add('自分も区間賞を取れて、主将の役目は果たせた');
    } else if (kj <= n ~/ 3) {
      j.add('自分も区間${kj + 1}位で、役目は果たせた');
    } else if (kj >= (n * 2) ~/ 3) {
      j.add('自分の走りが、一番の反省点です');
    }
  }
  // 区間賞の仲間(1人)
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    if (s == null || s.id == c.id || m.kukanJuni[kk] != 0) continue;
    j.add('${e.kukanMei(kk)}の${myouji(s.name)}が、区間賞で流れをつくってくれた');
    break;
  }
  // 一番順位を上げた仲間(3人以上)
  int saidai = 0;
  int saidaiKukan = -1;
  for (int kk = 1; kk < ks; kk++) {
    final int g = m.tuuka[kk - 1] - m.tuuka[kk];
    if (g > saidai) {
      saidai = g;
      saidaiKukan = kk;
    }
  }
  if (saidaiKukan >= 1 && saidai >= 3) {
    final SenshuData? s = m.senshu[saidaiKukan];
    if (s != null && s.id != c.id) {
      j.add('${e.kukanMei(saidaiKukan)}の${myouji(s.name)}が$saidai人抜いて、チームを勢いづけてくれた');
    }
  }
  // 好走した1年生(区間順位が一番よい1人)
  SenshuData? ichinen;
  int ichinenJuni = n;
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    if (s == null || s.id == c.id || s.gakunen != 1) continue;
    if (m.kukanJuni[kk] <= n ~/ 3 && m.kukanJuni[kk] < ichinenJuni) {
      ichinen = s;
      ichinenJuni = m.kukanJuni[kk];
    }
  }
  if (ichinen != null) {
    j.add('1年生の${myouji(ichinen.name)}が、堂々と走ってくれた');
  }
  // 目標(優勝のときは言わない)
  if (mokuhyou != null && r > 0) {
    if (r < mokuhyou) {
      j.add('目標の${juniMoji(mokuhyou)}を上回れた');
    } else if (r == mokuhyou) {
      j.add('目標の${juniMoji(mokuhyou)}には届いた');
    } else {
      j.add('目標の${juniMoji(mokuhyou)}まで、あと${r - mokuhyou}つだった');
    }
  }
  // シード権
  if (seedNow != null) {
    if (seedNow && !seedMae) {
      j.add('シード権を取れたのは、来年のチームへの大きな贈り物です');
    } else if (!seedNow && seedMae) {
      j.add('シード権を失ったのは、主将として本当に悔しい');
    } else if (seedNow && seedMae) {
      j.add('シード権を守れて、ほっとしています');
    }
  }
  // 前回から順位を上げた
  if (mae != null && mae > r) {
    j.add('前回から${mae - r}つ順位を上げられた');
  }
  return j;
}

/// 駅伝の展望の、主将が話す事実(話し言葉。「。」なし)
/// [hashiru] 区間エントリーの選手(区間の順)、[hatsu] 初めて駅伝を走る選手、
/// [mokuhyou] 目標順位(0が1位。なければnull)、[mae] 前回の順位(0が1位。なければnull)
List<String> shushouTenbouJijitsu(
  KijiKankyou k,
  SenshuData c,
  List<SenshuData?> hashiru,
  List<SenshuData> hatsu, {
  int? mokuhyou,
  int? mae,
}) {
  final int ks = hashiru.length;
  final List<String> j = [];
  // 自分の区間
  for (int kk = 0; kk < ks; kk++) {
    if (hashiru[kk]?.id != c.id) continue;
    j.add('自分は${kukanYobikata(k.gh, k.race, kk, ks)}を走ります。いい流れをつくりたい');
  }
  // 目標(優勝が目標のときは、気持ちの言葉と重なりやすいので言わない)
  if (mokuhyou != null && mokuhyou > 0) {
    j.add('目標の${juniMoji(mokuhyou)}は、全員で取りにいきます');
  }
  // 初めて駅伝を走る仲間(自分を除く)
  final List<SenshuData> hatsuHoka = [
    for (final SenshuData s in hatsu)
      if (s.id != c.id) s,
  ];
  if (hatsuHoka.length == 1) {
    j.add('初めて駅伝を走る${myouji(hatsuHoka.first.name)}には、思い切って走ってほしい');
  } else if (hatsuHoka.length >= 2) {
    j.add('初めて駅伝を走る${hatsuHoka.length}人には、思い切って走ってほしい');
  }
  // 4年生の人数
  final int yonen = hashiru.where((s) => s != null && s.gakunen == 4).length;
  if (yonen >= 2) j.add('4年生$yonen人で、チームを引っ張ります');
  // 前回の順位
  if (mae != null) {
    j.add(mae == 0 ? '前回の優勝に続きたい' : '前回の${juniMoji(mae)}より、一つでも上へ');
  }
  return j;
}
