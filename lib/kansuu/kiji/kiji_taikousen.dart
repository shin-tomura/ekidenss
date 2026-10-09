import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';

// ------------------------------------------------------------
// 対校戦(5月。5000m・1万m・ハーフ)の結果の記事(1.9.2。結果画面の「ニュース記事」)
//
// 対校戦は種目ごとに結果画面が出るので、種目ごとに記事を作る
//  5000mのあと: 1.種目の記事(個人) 2.総合の途中経過 3.自分の大学
//  1万mのあと:  1.総合の途中経過 2.種目の記事(個人) 3.自分の大学
//  ハーフのあと: 1.総合優勝 2.自分の大学 3.種目の記事(個人) 4.総合8位争い
//  (対校戦の総合は、8位まででも名声が大きいので、総合の争いを前に出す。1.9.3。
//   総合優勝・8位のライン・8位争いの記事では、名声の大きさを正月駅伝と比べて書く)
//
// データ
//  ・選手: SenshuData.kukanjuni_race[6〜8][学年-1] がその種目の全体の順位(0が1位。
//    走っていなければ TEISUU.DEFAULTJUNI)、kukantime_race がタイム。学年ごとに残るので、
//    去年の同じ種目の順位も分かる(個人の連覇)
//  ・大学: UnivData.inkarepoint[0〜2] が今年の種目ごとのポイント(5000mの前に0に戻る)。
//    ポイントは、その種目の出場人数をNとして、1位N点・2位N-1点…を大学ごとに合計する
//  ・総合順位: UnivData.juni_race[9][0](同点は抽選で決まった順。5000mと1万mのあとは途中の順位)。
//    [1]が去年。優勝回数などの数(taikaibetujunibetukaisuu[9])はハーフのあとに足される
//  ・総合の目標順位は全大学とも8位(mokuhyojuni[9])。名声も個人・総合とも8位まで
//
// 記録(歴代記録・自己ベスト)には触れない。5000m・1万m・ハーフの記録は記録会などほかの大会と
// 共通で、対校戦の前の記録も控えていないため(ゲームを始めたばかりのころに、誤って新記録と書かないように)
//
// 1.9.4: 対校戦用の因縁(kiji_kihon.dart の taikousenInnen。昨年の同じ種目との比べ・駅伝の本戦の出走歴・
//  初めての対校戦・最後の対校戦・入学時の記録からの伸び)を、個人優勝の記事と自分の大学の記事に入れ、
//  自分の大学の記事の最後に、記者の型で見方が変わる「記者の目」を付ける
// ------------------------------------------------------------

/// 対校戦の総合の記録の番号(UnivData.juni_race・taikaibetujunibetukaisuu の番号)
const int _sougouBangou = 9;

/// 名声のかかる順位の数(個人・総合とも8位まで)
const int _meiseiJuniSuu = 8;

/// 対校戦の総合の順位ごとの名声(KirokuKousin.dart と同じ。目標順位で割らず、駅伝名声設定の倍率もない。1.9.3)
const List<int> taikousenSougouMeisei = [1000, 500, 400, 180, 160, 140, 120, 100];

/// 対校戦の種目ごとの個人の順位ごとの名声(KirokuKousin.dart と同じ。1.9.3)
const List<int> taikousenKojinMeisei = [100, 50, 40, 18, 16, 14, 12, 10];

/// 正月駅伝の順位ごとの基本の名声(8位まで。KirokuKousin.dart・shiyou_text.dart と同じ。
/// 実際は「駅伝名声設定」の倍率をかけて、目標順位で割る)
const List<int> _shougatsuMeiseiKihon = [2000, 1000, 800, 360, 320, 280, 240, 200];

/// 対校戦の総合[juni]位(0が1位。8位まで)の名声の大きさを、正月駅伝で目標順位どおりに同じ順位に
/// 入ったときの名声と比べる文(「正月駅伝を目標1位で制したときの半分にあたる」など。文末の「。」はなし。
/// 比べられなければnull。1.9.3)
/// 正月駅伝の名声は「駅伝名声設定」の倍率で変わるので、このデータの倍率で比べる
String? taikousenMeiseiHikaku(KijiKankyou k, int juni) {
  if (juni < 0 ||
      juni >= taikousenSougouMeisei.length ||
      juni >= _shougatsuMeiseiKihon.length) {
    return null;
  }
  // 正月駅伝の「駅伝名声設定」の倍率(大学id 5・6 の name_tanshuku。KirokuKousin.dart と同じ読み方)
  int yomu(int id) {
    if (id >= k.univ.length) return 1;
    final int? v = int.tryParse(k.univ[id].name_tanshuku);
    return (v == null || v < 1 || v > 10) ? 1 : v;
  }

  final double bairitu = yomu(5).toDouble() / yomu(6).toDouble();
  // 目標順位どおりに入ったときの量(KirokuKousin.dart と同じく、小数を切り捨てて最低1)
  int shougatsu =
      (_shougatsuMeiseiKihon[juni].toDouble() * bairitu * (1.0 / (juni + 1)))
          .toInt();
  if (shougatsu < 1) shougatsu = 1;
  final double hi = taikousenSougouMeisei[juni] / shougatsu;
  final String moto = juni == 0
      ? '正月駅伝を目標1位で制したとき'
      : '正月駅伝で目標${juni + 1}位どおりに${juni + 1}位に入ったとき';
  if (hi >= 0.95 && hi < 1.05) return '$motoと同じ大きさだ';
  if (hi >= 1.05) {
    final double b = (hi * 10).round() / 10;
    final String bs = b == b.roundToDouble()
        ? '${b.toInt()}'
        : b.toStringAsFixed(1);
    return '$motoの$bs倍にあたる';
  }
  if (hi >= 0.45 && hi < 0.55) return '$motoの半分にあたる';
  final int wari = (hi * 10).round();
  return wari < 1 ? '$motoの1割に満たない' : '$motoの約$wari割にあたる';
}

/// 対校戦の選手1人の、表示中の種目の結果
class TaikousenSenshuKekka {
  final SenshuData s;
  final double time;

  /// 全体の順位(0が1位)
  final int juni;

  /// 大学にもたらしたポイント
  final int point;

  const TaikousenSenshuKekka(this.s, this.time, this.juni, this.point);
}

/// 対校戦の大学1校の結果
class TaikousenUnivKekka {
  final UnivData u;

  /// 種目ごとのポイント(5000m・1万m・ハーフ。まだ行われていない種目は0)
  final List<int> point;

  /// 種目ごとの出場人数
  final List<int> ninzuu;

  /// 総合順位(0が1位。5000mと1万mのあとは途中の順位)
  int juni = 0;

  TaikousenUnivKekka(this.u, this.point, this.ninzuu);

  /// ここまでの合計のポイント
  int get goukei => point[0] + point[1] + point[2];

  /// ここまでの延べ出場人数
  int get nobe => ninzuu[0] + ninzuu[1] + ninzuu[2];

  String get mei => daigakuMei(u);
}

/// 対校戦の結果(表示中の種目まで)
class TaikousenKekka {
  final KijiKankyou k;

  /// 表示中の種目(0: 5000m、1: 1万m、2: ハーフ)
  final int shumoku;

  /// 表示中の種目の個人の結果(順位順)
  final List<TaikousenSenshuKekka> kojin;

  /// 総合順位の順
  final List<TaikousenUnivKekka> jun;

  /// 種目ごとの出場人数(全体)
  final List<int> zenin;

  TaikousenKekka._(this.k, this.shumoku, this.kojin, this.jun, this.zenin);

  /// 結果を集める(対校戦でないときや、結果がないときはnull)
  static TaikousenKekka? tsukuru(KijiKankyou k) {
    if (!k.taikousen) return null;
    final int sh = k.race - 6;
    final List<int> zenin = [0, 0, 0];
    final Map<int, List<int>> univNinzuu = {};
    for (final SenshuData s in k.senshu) {
      for (int ev = 0; ev <= sh; ev++) {
        if (_juni(s, 6 + ev) < 0) continue;
        zenin[ev]++;
        final List<int> nz = univNinzuu.putIfAbsent(s.univid, () => [0, 0, 0]);
        nz[ev]++;
      }
    }
    final List<TaikousenSenshuKekka> kojin = [];
    for (final SenshuData s in k.senshu) {
      final int j = _juni(s, k.race);
      if (j < 0) continue;
      kojin.add(TaikousenSenshuKekka(s, _time(s, k.race), j, zenin[sh] - j));
    }
    if (kojin.isEmpty) return null;
    kojin.sort((a, b) => a.juni.compareTo(b.juni));
    final List<TaikousenUnivKekka> jun = [
      for (final UnivData u in k.univ)
        TaikousenUnivKekka(
          u,
          [
            for (int ev = 0; ev < 3; ev++)
              (ev <= sh && u.inkarepoint.length > ev) ? u.inkarepoint[ev] : 0,
          ],
          univNinzuu[u.id] ?? [0, 0, 0],
        ),
    ];
    if (jun.length < 2) return null;
    // 総合順位は、ゲームが決めた順位(同点は抽選)。分からなければ合計の多い順
    jun.sort((a, b) {
      final int ja = juniRace(a.u, _sougouBangou, 0);
      final int jb = juniRace(b.u, _sougouBangou, 0);
      if (ja != jb) return ja.compareTo(jb);
      final int c = b.goukei.compareTo(a.goukei);
      return c != 0 ? c : a.u.id.compareTo(b.u.id);
    });
    for (int i = 0; i < jun.length; i++) {
      jun[i].juni = i;
    }
    return TaikousenKekka._(k, sh, kojin, jun, zenin);
  }

  /// 選手[s]の大会[race]での全体の順位(走っていなければ-1)
  static int _juni(SenshuData s, int race) {
    if (s.kukanjuni_race.length <= race) return -1;
    final int g = s.gakunen - 1;
    if (g < 0 || g >= s.kukanjuni_race[race].length) return -1;
    final int j = s.kukanjuni_race[race][g];
    if (j < 0 || j >= TEISUU.DEFAULTJUNI) return -1;
    return j;
  }

  /// 選手[s]の大会[race]でのタイム
  static double _time(SenshuData s, int race) {
    if (s.kukantime_race.length <= race) return TEISUU.DEFAULTTIME;
    final int g = s.gakunen - 1;
    if (g < 0 || g >= s.kukantime_race[race].length) return TEISUU.DEFAULTTIME;
    return s.kukantime_race[race][g];
  }

  /// 最後の種目(ハーフ)のあとか
  bool get saigo => shumoku == 2;

  int get n => jun.length;

  /// 今回が初めての開催か(ゲームを始めた年など。優勝回数などはハーフのあとに足されるので、
  /// 5000m・1万mのあとは、まだ一度も行われていないかで見る)
  bool get hatsuKaisai =>
      saigo ? hatsuKaisaiKekka(k, _sougouBangou) : mikaisai(k, _sougouBangou);

  /// 自分の大学(いなければnull)
  TaikousenUnivKekka? get jibun {
    for (final TaikousenUnivKekka x in jun) {
      if (x.u.id == k.gh.MYunivid) return x;
    }
    return null;
  }

  /// 大学の呼び方
  String univMei(int univid) =>
      (univid >= 0 && univid < k.univ.length) ? daigakuMei(k.univ[univid]) : '';

  /// 大学[x]の、種目[ev]のポイントの順位(0が1位。同点は同じ順位)
  int shumokuJuni(TaikousenUnivKekka x, int ev) {
    int c = 0;
    for (final TaikousenUnivKekka y in jun) {
      if (y.point[ev] > x.point[ev]) c++;
    }
    return c;
  }

  /// [made]種目目(0が5000m)までの合計で並べた順(前の種目のあとの途中経過。同点は今の順位の順)
  List<TaikousenUnivKekka> madeJun(int made) {
    int g(TaikousenUnivKekka x) {
      int t = 0;
      for (int ev = 0; ev <= made && ev < 3; ev++) {
        t += x.point[ev];
      }
      return t;
    }

    return List<TaikousenUnivKekka>.of(jun)..sort((a, b) {
      final int c = g(b).compareTo(g(a));
      return c != 0 ? c : a.juni.compareTo(b.juni);
    });
  }

  /// 種目[ev]の個人優勝の選手(いなければnull)
  SenshuData? shumokuYuushou(int ev) {
    for (final SenshuData s in k.senshu) {
      if (_juni(s, 6 + ev) == 0) return s;
    }
    return null;
  }

  /// 大学[x]の、種目[ev]で8位以内に入った人数
  int nyuushouSuu(TaikousenUnivKekka x, int ev) {
    int c = 0;
    for (final SenshuData s in k.senshu) {
      if (s.univid != x.u.id) continue;
      final int j = _juni(s, 6 + ev);
      if (j >= 0 && j < _meiseiJuniSuu) c++;
    }
    return c;
  }
}

// ------------------------------------------------------------
// 記事の入口
// ------------------------------------------------------------

/// 対校戦の結果の記事の一覧(並べる順)
List<Kiji> taikousenKekkaKiji(KijiKankyou k) {
  final TaikousenKekka? e = TaikousenKekka.tsukuru(k);
  if (e == null) return [];
  final List<Kiji> list = [];
  final Kiji? kojin = _kojinKiji(e);
  final Kiji? jibun = _jibunKiji(e);
  if (e.saigo) {
    list.add(_sougouKiji(e));
    if (jibun != null) list.add(jibun);
    if (kojin != null) list.add(kojin);
    final Kiji? hachii = _hachiiKiji(e);
    if (hachii != null) list.add(hachii);
  } else {
    // 総合は最終種目のハーフで決まるので、1万mのあとは総合の途中経過をトップ記事にする。
    // 5000mのあとも、自分の大学の記事より前に置く(1.9.3)
    final Kiji tochuu = _tochuuKiji(e);
    if (e.shumoku == 1) list.add(tochuu);
    if (kojin != null) list.add(kojin);
    if (e.shumoku == 0) list.add(tochuu);
    if (jibun != null) list.add(jibun);
  }
  return list;
}

/// 記事を作るときの共通の仕上げ
Kiji _kansei(
  KijiKankyou k,
  int no,
  KijiKakite w, {
  required String midashi,
  required String lead,
  List<KijiHyou> hyou = const [],
  bool jibun = false,
}) {
  return Kiji(
    category: '対校戦',
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

/// 総合成績の表([kara]位から[made]位まで。0が1位)
KijiHyou _sougouHyou(TaikousenKekka e, String title, {int kara = 0, int? made}) {
  final int owari = (made == null || made >= e.n) ? e.n - 1 : made;
  return KijiHyou(
    title,
    [
      '順位',
      '大学',
      for (int ev = 0; ev <= e.shumoku; ev++) kijiShumokuMei[ev],
      if (e.shumoku >= 1) '合計',
    ],
    [
      for (int i = kara < 0 ? 0 : kara; i <= owari; i++)
        [
          juniMoji(i),
          e.jun[i].mei,
          for (int ev = 0; ev <= e.shumoku; ev++) '${e.jun[i].point[ev]}',
          if (e.shumoku >= 1) '${e.jun[i].goukei}',
        ],
    ],
  );
}

/// 点差の言い方(同点なら「同点」)
String _tensaMoji(int sa) => sa <= 0 ? '同点' : '$sa点差';

/// 下の大学[shita]の延べ人数が、上の大学との差[sa]より多ければ、
/// 「延べ○人が1つずつ順位を上げていれば逆転できた」の文(そうでなければ空)
String _gyakutenKeisanBun(TaikousenUnivKekka shita, int sa) {
  if (sa <= 0 || shita.nobe <= sa) return '';
  return '${shita.mei}の延べ${shita.nobe}人が、それぞれ1つずつ順位を上げていれば'
      '逆転できた計算になる。';
}

// ------------------------------------------------------------
// 1. 種目の記事(個人)
// ------------------------------------------------------------

Kiji? _kojinKiji(TaikousenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 3;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final List<TaikousenSenshuKekka> kj = e.kojin;
  if (kj.isEmpty) return null;
  final int sh = e.shumoku;
  final String sm = kijiShumokuMei[sh];
  final TaikousenSenshuKekka a = kj[0];
  final TaikousenSenshuKekka? b = kj.length >= 2 ? kj[1] : null;
  final int sa = b == null ? 0 : saByou(b.time, a.time);
  // 独走と言える差(5000m・1万m・ハーフで変える)
  const List<int> dokusouSa = [10, 20, 30];

  // 事実を集める
  // 連覇(去年・おととしも同じ種目で1位。在学中の分だけ)
  int renpa = 1;
  for (int mae = 1; mae <= 3; mae++) {
    if (k.kukanJuniMae(a.s, k.race, mae) != 0) break;
    renpa++;
  }
  // 前回王者(在学中で今年も走った、優勝者とは別の選手)
  TaikousenSenshuKekka? maeOuja;
  if (!e.hatsuKaisai) {
    for (final TaikousenSenshuKekka x in kj) {
      if (x.s.id != a.s.id && k.kukanJuniMae(x.s, k.race, 1) == 0) {
        maeOuja = x;
        break;
      }
    }
  }
  // 日本人トップ(優勝者が留学生のとき)
  TaikousenSenshuKekka? nihon;
  if (a.s.hirou == 1) {
    for (final TaikousenSenshuKekka x in kj) {
      if (x.s.hirou != 1) {
        nihon = x;
        break;
      }
    }
  }
  // 名声のかかる8位までの、大学ごとの人数(同じ人数なら、上の順位の選手がいる大学)
  final Map<int, int> nyuushou = {};
  for (final TaikousenSenshuKekka x in kj.take(_meiseiJuniSuu)) {
    nyuushou[x.s.univid] = (nyuushou[x.s.univid] ?? 0) + 1;
  }
  int ooiId = -1;
  int ooi = 0;
  nyuushou.forEach((id, c) {
    if (c > ooi) {
      ooi = c;
      ooiId = id;
    }
  });
  // この種目のポイントが一番多い大学
  TaikousenUnivKekka pTop = e.jun.first;
  for (final TaikousenUnivKekka x in e.jun) {
    if (x.point[sh] > pTop.point[sh]) pTop = x;
  }

  // 見出し
  final String am = myouji(a.s.name);
  final String au = e.univMei(a.s.univid);
  String midashi;
  if (renpa >= 2) {
    midashi = '対校戦$sm、$am($au)が$renpa連覇';
  } else if (a.s.gakunen == 1) {
    midashi = '対校戦$sm、1年生の$am($au)が制す';
  } else if (b != null && sa >= dokusouSa[sh]) {
    midashi = '対校戦$sm、$am($au)が独走V';
  } else if (b != null && sa <= 1) {
    midashi = '対校戦$sm、$am($au)が競り合い制す';
  } else {
    midashi = w.erabu(['対校戦$sm、$am($au)がV', '$am($au)が対校戦$smを制す']);
  }
  if (ooi >= 3) midashi += '　${e.univMei(ooiId)}が$ooi人入賞';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}の$smが行われ、${w.senshu(a.s, daigaku: true)}が'
    '${jikanMoji(a.time)}で優勝した。',
  );
  if (renpa >= 2) {
    lead.write(renpa == 2 ? '去年に続く連覇となった。' : '$renpa年連続の優勝となった。');
  } else if (a.s.gakunen == 1) {
    lead.write('1年生ながら、上級生を抑えての優勝だった。');
  }
  if (b != null) {
    final String yb = w.senshu(b.s, daigaku: true);
    if (sa <= 1) {
      lead.write('2位の$ybとは${kinsaMoji(sa)}の競り合いだった。');
    } else if (sa >= dokusouSa[sh]) {
      lead.write('2位の$ybに${saMoji(sa)}差をつける独走だった。');
    } else {
      lead.write('2位は$ybで、${saMoji(sa)}差だった。');
    }
  }
  if (nihon != null && nihon.juni > 0) {
    lead.write('日本人トップは${juniMoji(nihon.juni)}の${w.senshu(nihon.s, daigaku: true)}だった。');
  }

  // 本文: 上位争い
  w.koMidashi('上位争い');
  final StringBuffer joui = StringBuffer();
  if (kj.length >= 3) {
    joui.write('3位には${w.senshu(kj[2].s, daigaku: true)}が入った。');
  }
  if (maeOuja != null) {
    joui.write(
      '前回王者の${w.senshu(maeOuja.s, daigaku: true)}は${juniMoji(maeOuja.juni)}で、'
      '連覇はならなかった。',
    );
  }
  w.danraku(joui.toString());
  // 優勝した選手の因縁(連覇のときは、昨年の順位の因縁は書かない。1.9.4)
  final List<Innen> ai = [
    for (final Innen i in taikousenInnen(k, a.s, juni: 0))
      if (!(renpa >= 2 && i.shurui == InnenShurui.juniUe)) i,
  ];
  if (ai.isNotEmpty && ai.first.ten >= 40) {
    w.danraku('${w.senshu(a.s)}。${ai.first.bun}');
  }
  w.comment(
    senshuCommentJijitsu(
      w,
      CommentBamen.taikousenKojinYuushou,
      w.senshu(a.s),
      jijitsu: [
        if (ai.isNotEmpty) ai.first.kotoba,
        if (b != null && sa <= 1) '最後は並んでのゴール。勝てたのは気持ちの差だと思う',
        if (b != null && sa >= dokusouSa[sh]) '途中から一人になった。自分との戦いだった',
        if (b != null && sa > 1 && sa < dokusouSa[sh]) '2位と${saMoji(sa)}差。最後まで気は抜けなかった',
        if (b == null) '一人でも集中を切らさずに走れた',
      ],
    ),
  );
  w.danraku(shusshinShumiBun(k, a.s, w.r, myouji(a.s.name)));

  // 本文: 入賞と大学のポイント
  w.koMidashi('入賞と大学のポイント');
  final StringBuffer pt = StringBuffer();
  if (ooi >= 2) {
    pt.write('名声のかかる8位以内には、${e.univMei(ooiId)}が最多の$ooi人を送り込んだ。');
  } else if (kj.length >= _meiseiJuniSuu) {
    pt.write('名声のかかる8位以内の8人は、すべて別々の大学の選手だった。');
  }
  pt.write(
    'ポイントは1位の${e.zenin[sh]}点から、順位が1つ下がるごとに1点ずつ減り、'
    '出場した全員の分を大学ごとに合計する。',
  );
  pt.write('この種目のポイントは、${pTop.mei}が最多の${pTop.point[sh]}点を挙げた。');
  if ((nyuushou[pTop.u.id] ?? 0) == 0) {
    pt.write('8位以内の選手はいなかったが、全員が順位をまとめて層の厚さを示した。');
  }
  w.danraku(pt.toString());

  // 表
  final List<List<String>> gyou = [
    for (final TaikousenSenshuKekka x in kj.take(_meiseiJuniSuu))
      [
        juniMoji(x.juni),
        '${fullMei(x.s.name)}(${x.s.gakunen})',
        e.univMei(x.s.univid),
        jikanMoji(x.time),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('$smの上位8人', ['順位', '選手', '大学', 'タイム'], gyou),
    ],
    jibun: a.s.univid == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 2. 総合の途中経過(5000m・1万mのあと)
// ------------------------------------------------------------

Kiji _tochuuKiji(TaikousenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 4;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int sh = e.shumoku;
  final String sm = kijiShumokuMei[sh];
  final TaikousenUnivKekka t1 = e.jun[0];
  final TaikousenUnivKekka t2 = e.jun[1];
  final int sa = t1.goukei - t2.goukei;
  final String nokori = sh == 0 ? '残る1万mとハーフ' : '最終種目のハーフ';
  // 前の種目のあとの首位(1万mのあとだけ)
  final TaikousenUnivKekka? maeShui = sh >= 1 ? e.madeJun(sh - 1).first : null;
  final bool fujou = maeShui != null && maeShui.u.id != t1.u.id;

  // 見出し
  String midashi;
  if (sa <= 0) {
    midashi = '対校戦総合、${t1.mei}と${t2.mei}が同点で並ぶ';
  } else if (fujou) {
    midashi = '対校戦総合、${t1.mei}が首位に浮上　勝負はハーフへ';
  } else if (sh == 0) {
    midashi = '対校戦総合、${t1.mei}が首位発進';
  } else {
    midashi = '対校戦総合、${t1.mei}が首位守る　勝負はハーフへ';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は$smを終え、総合のポイントでは${t1.mei}が${t1.goukei}点で首位に立った。',
  );
  lead.write(
    sa <= 0
        ? '2位の${t2.mei}も同点で並んでいる(順位は抽選で決めている)。'
        : '2位の${t2.mei}とは$sa点差。',
  );
  lead.write('総合の順位は、$nokoriの結果を加えて決まる。');

  // 本文
  w.koMidashi('首位争い');
  final StringBuffer sb = StringBuffer();
  if (maeShui != null) {
    sb.write(
      fujou
          ? '5000mを終えて首位だった${maeShui.mei}は、${juniMoji(maeShui.juni)}に後退した。'
          : '${t1.mei}は5000mに続いて首位を守った。',
    );
  }
  if (e.n >= 3) {
    final TaikousenUnivKekka t3 = e.jun[2];
    sb.write('3位は${t3.mei}で、首位とは${_tensaMoji(t1.goukei - t3.goukei)}。');
  }
  sb.write('ポイントは出場した全員の順位で決まるため、上位の選手だけでなく、チーム全体の層の厚さが問われる。');
  w.danraku(sb.toString());

  // 本文: 8位のライン
  if (e.n > _meiseiJuniSuu) {
    w.koMidashi('8位のライン');
    final TaikousenUnivKekka h8 = e.jun[_meiseiJuniSuu - 1];
    final TaikousenUnivKekka h9 = e.jun[_meiseiJuniSuu];
    final int sa89 = h8.goukei - h9.goukei;
    w.danraku(
      '全大学が目標に掲げ、名声も与えられる総合8位のラインは、${h8.mei}の${h8.goukei}点。'
      '${sa89 <= 0 ? '9位の${h9.mei}も同点で並んでいる。' : '9位の${h9.mei}が$sa89点差で追う。'}'
      '${w.erabu(['$nokoriで、ラインの攻防はまだ続く。', '8位以内を巡る争いは、$nokoriにもつれ込む。'])}',
    );
    // 名声の大きさ(1.9.3)
    final String? hikaku = taikousenMeiseiHikaku(k, _meiseiJuniSuu - 1);
    if (hikaku != null) {
      w.danraku('総合の名声は8位まで与えられ、8位の名声でも、$hikaku。');
    }
  }

  return _kansei(
    k,
    no,
    w,
    midashi: midashi,
    lead: lead.toString(),
    hyou: [_sougouHyou(e, '総合の途中経過($smまで)')],
  );
}

// ------------------------------------------------------------
// 3. 総合優勝の記事(ハーフのあと)
// ------------------------------------------------------------

Kiji _sougouKiji(TaikousenKekka e) {
  final KijiKankyou k = e.k;
  const int no = 1;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final TaikousenUnivKekka win = e.jun[0];
  final TaikousenUnivKekka ni = e.jun[1];
  final int sa = win.goukei - ni.goukei;
  final bool hatsuKaisai = e.hatsuKaisai;

  // 事実を集める
  final int kaisuu = juniKaisuu(win.u, _sougouBangou, 0);
  final ({int kaisuu, bool kakutei}) rz = renzokuKakutei(
    win.u,
    _sougouBangou,
    0,
    (j) => j == 0,
    kaisuu,
  );
  final int renzoku = rz.kaisuu;
  final bool renzokuFumei = !hatsuKaisai && !rz.kakutei;
  final int? maeYuushou = saigoNoKai(win.u, _sougouBangou, 1, (j) => j == 0);
  final bool hatsu = kaisuu <= 1;
  final String kaisuuGo = hatsuKaisai
      ? '総合優勝'
      : renzokuFumei
      ? '$kaisuu度目の総合優勝'
      : (hatsu
            ? '初の総合優勝'
            : '${renzokuMoji(renzoku: renzoku, buri: maeYuushou, kaisuu: kaisuu)}総合優勝');
  // 1万mのあと・5000mのあとの順位
  final int maeJuni = e.madeJun(1).indexWhere((x) => x.u.id == win.u.id);
  final int maeJuni5 = e.madeJun(0).indexWhere((x) => x.u.id == win.u.id);
  final bool gyakuten = maeJuni > 0;
  final List<int> shJ = [for (int ev = 0; ev < 3; ev++) e.shumokuJuni(win, ev)];
  final bool kanzen = shJ.every((j) => j == 0);

  // 見出し
  String midashi1;
  if (hatsuKaisai) {
    midashi1 = w.erabu(['${win.mei}が対校戦の初代王者に', '初開催の対校戦、${win.mei}が総合V']);
  } else if (hatsu) {
    midashi1 = w.erabu(['${win.mei}が対校戦初の総合優勝', '${win.mei}、対校戦で悲願の初V']);
  } else if (renzokuFumei) {
    midashi1 = '${win.mei}、対校戦の連覇続く$kaisuu度目V';
  } else if (renzoku >= 2) {
    midashi1 = w.erabu(['${win.mei}が対校戦$renzoku連覇', '${win.mei}、対校戦$renzoku年連続V']);
  } else if (maeYuushou != null && maeYuushou >= 2) {
    midashi1 = '${win.mei}、$maeYuushou年ぶりの対校戦総合V';
  } else {
    midashi1 = w.erabu(['${win.mei}が対校戦総合V', '${win.mei}、対校戦の頂点に']);
  }
  String midashi2 = '';
  if (sa <= 0) {
    midashi2 = '同点、抽選で制す';
  } else if (gyakuten) {
    midashi2 = 'ハーフで逆転';
  } else if (sa < ni.nobe) {
    midashi2 = '$sa点差の激戦制す';
  } else if (kanzen) {
    midashi2 = '3種目でポイント1位';
  }
  final String midashi = midashi2.isEmpty ? midashi1 : '$midashi1　$midashi2';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は最終種目のハーフが行われ、5000m・1万mと合わせた総合のポイントで、'
    '${win.mei}が${win.goukei}点を挙げて$kaisuuGoを果たした。',
  );
  if (hatsuKaisai) lead.write('初めて開催された大会で、初代王者に輝いた。');
  if (renzokuFumei) lead.write('長く続く連覇を、さらに伸ばした。');
  if (sa <= 0) {
    lead.write('2位の${ni.mei}とは同点で、抽選で優勝が決まった。');
  } else if (sa < ni.nobe) {
    lead.write('2位の${ni.mei}とは、わずか$sa点差の大接戦だった。');
  } else {
    lead.write('2位の${ni.mei}とは$sa点差だった。');
  }

  // 本文: 種目ごとの戦い
  w.koMidashi('種目ごとの戦い');
  final StringBuffer sb = StringBuffer();
  sb.write(
    '${win.mei}の種目ごとのポイントは、'
    '${[for (int ev = 0; ev < 3; ev++) '${kijiShumokuMei[ev]}が${win.point[ev]}点(${juniMoji(shJ[ev])})'].join('、')}。',
  );
  if (kanzen) {
    sb.write('3種目すべてで大学別のポイント1位という完勝だった。');
  }
  if (gyakuten) {
    sb.write('1万mを終えた時点では${juniMoji(maeJuni)}だったが、最終種目のハーフで逆転した。');
  } else if (maeJuni5 == 0) {
    sb.write('5000mから一度も首位を譲らなかった。');
  } else if (maeJuni == 0) {
    sb.write('1万mで首位に立ち、ハーフでも譲らなかった。');
  }
  // 優勝校の個人優勝と、8位以内の人数
  final List<String> kojinV = [];
  for (int ev = 0; ev < 3; ev++) {
    final SenshuData? s = e.shumokuYuushou(ev);
    if (s != null && s.univid == win.u.id) {
      kojinV.add('${kijiShumokuMei[ev]}の${w.senshu(s)}');
    }
  }
  if (kojinV.isNotEmpty) sb.write('個人でも、${kojinV.join('、')}が優勝した。');
  final int nyuushou = [
    for (int ev = 0; ev < 3; ev++) e.nyuushouSuu(win, ev),
  ].fold<int>(0, (t, v) => t + v);
  if (nyuushou >= 1) sb.write('3種目で延べ$nyuushou人が、名声のかかる8位以内に入った。');
  w.danraku(sb.toString());
  w.comment(kantokuComment(w, KantokuBamen.taikousenYuushou, win.u.id));
  // 名声の大きさ(1.9.3)
  final String? hikaku = taikousenMeiseiHikaku(k, 0);
  if (hikaku != null) {
    w.danraku('対校戦の総合優勝で大学が得る名声は、$hikaku。');
  }

  // 本文: 2位以下
  w.koMidashi('2位以下');
  final StringBuffer ika = StringBuffer();
  ika.write('2位の${ni.mei}は${ni.goukei}点。');
  final int niMae = e.madeJun(1).indexWhere((x) => x.u.id == ni.u.id);
  if (niMae == 0) ika.write('1万mを終えて首位に立っていたが、ハーフで逆転を許した。');
  ika.write(_gyakutenKeisanBun(ni, sa));
  if (e.n >= 3) ika.write('3位には${e.jun[2].mei}が入った。');
  // 前回王者
  if (!hatsuKaisai) {
    for (final TaikousenUnivKekka x in e.jun) {
      if (x.juni == 0) continue;
      if (juniRace(x.u, _sougouBangou, 1) != 0) continue;
      // 今回は優勝していないので、全期間の優勝回数は前回までの分
      final ({int kaisuu, bool kakutei}) mr = renzokuKakutei(
        x.u,
        _sougouBangou,
        1,
        (j) => j == 0,
        juniKaisuu(x.u, _sougouBangou, 0),
      );
      ika.write(
        !mr.kakutei
            ? '前回王者の${x.mei}は${juniMoji(x.juni)}に終わり、長く続いた連覇が止まった。'
            : mr.kaisuu >= 2
            ? '${mr.kaisuu + 1}連覇を狙った前回王者の${x.mei}は${juniMoji(x.juni)}に終わった。'
            : '前回王者の${x.mei}は${juniMoji(x.juni)}で、連覇を逃した。',
      );
      break;
    }
  }
  w.danraku(ika.toString());

  return _kansei(
    k,
    no,
    w,
    midashi: midashi,
    lead: lead.toString(),
    hyou: [_sougouHyou(e, '総合成績')],
    jibun: win.u.id == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 4. 総合8位争いの記事(ハーフのあと)
// ------------------------------------------------------------

Kiji? _hachiiKiji(TaikousenKekka e) {
  if (e.n <= _meiseiJuniSuu) return null;
  final KijiKankyou k = e.k;
  const int no = 5;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final TaikousenUnivKekka h8 = e.jun[_meiseiJuniSuu - 1];
  final TaikousenUnivKekka h9 = e.jun[_meiseiJuniSuu];
  final int sa = h8.goukei - h9.goukei;
  // 1万mのあとの順位
  final List<TaikousenUnivKekka> mae = e.madeJun(1);
  final int m8 = mae.indexWhere((x) => x.u.id == h8.u.id);
  final int m9 = mae.indexWhere((x) => x.u.id == h9.u.id);
  final bool suberikomi = m8 >= _meiseiJuniSuu;
  final bool tenraku = m9 >= 0 && m9 < _meiseiJuniSuu;

  // 見出し
  String midashi;
  if (sa <= 0) {
    midashi = '対校戦の総合8位争い、同点の${h8.mei}が抽選で8位に';
  } else if (suberikomi) {
    midashi = '${h8.mei}、ハーフで逆転し総合8位に滑り込む';
  } else if (tenraku) {
    midashi = '${h9.mei}、ハーフで総合8位から転落';
  } else if (sa < h9.nobe) {
    midashi = '対校戦の総合8位争い、${h8.mei}が$sa点差で逃げ切る';
  } else {
    midashi = '対校戦の総合8位は${h8.mei}　9位${h9.mei}に$sa点差';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}は、全大学が目標に掲げ、名声も与えられる総合8位までの争いも注目を集めた。');
  lead.write(
    '8位の${h8.mei}は${h8.goukei}点、9位の${h9.mei}は${h9.goukei}点で、'
    '${sa <= 0 ? '同点だったため、抽選で順位が決まった。' : '差は$sa点だった。'}',
  );
  lead.write(_gyakutenKeisanBun(h9, sa));
  // 名声の大きさ(1.9.3)
  final String? hikaku = taikousenMeiseiHikaku(k, _meiseiJuniSuu - 1);
  if (hikaku != null) lead.write('総合8位の名声でも、$hikaku。');

  // 本文
  w.koMidashi('最終種目の攻防');
  final StringBuffer sb = StringBuffer();
  if (suberikomi) {
    sb.write(
      '${h8.mei}は1万mを終えて${juniMoji(m8)}だったが、ハーフで巻き返した。'
      'ハーフのポイントは大学別${juniMoji(e.shumokuJuni(h8, 2))}だった。',
    );
  }
  if (tenraku) {
    sb.write('${h9.mei}は1万mを終えて${juniMoji(m9)}と8位以内にいたが、ハーフで逆転を許した。');
  }
  if (!suberikomi && !tenraku && m8 >= 0 && m9 >= 0) {
    sb.write('1万mを終えた時点では、${h8.mei}が${juniMoji(m8)}、${h9.mei}が${juniMoji(m9)}だった。');
  }
  // 前回の順位
  if (!e.hatsuKaisai) {
    final int p8 = juniRace(h8.u, _sougouBangou, 1);
    final int p9 = juniRace(h9.u, _sougouBangou, 1);
    if (shutsujouJuni(p8) && p8 >= _meiseiJuniSuu) {
      sb.write('${h8.mei}は前回の${juniMoji(p8)}から、8位以内に浮上した。');
    }
    if (shutsujouJuni(p9) && p9 < _meiseiJuniSuu) {
      sb.write('${h9.mei}は前回の${juniMoji(p9)}から、8位以内を守れなかった。');
    }
  }
  w.danraku(sb.toString());
  w.comment(kantokuComment(w, KantokuBamen.taikousenHachii, h8.u.id));
  w.comment(
    kantokuComment(w, KantokuBamen.taikousenHachiiNogasu, h9.u.id, kuyashii: true),
  );

  final int my = k.gh.MYunivid;
  return _kansei(
    k,
    no,
    w,
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      _sougouHyou(
        e,
        '総合${_meiseiJuniSuu - 2}位〜${_meiseiJuniSuu + 3}位',
        kara: _meiseiJuniSuu - 3,
        made: _meiseiJuniSuu + 2,
      ),
    ],
    jibun: h8.u.id == my || h9.u.id == my,
  );
}

// ------------------------------------------------------------
// 5. 自分の大学の記事
// ------------------------------------------------------------

Kiji? _jibunKiji(TaikousenKekka e) {
  final TaikousenUnivKekka? m = e.jibun;
  if (m == null) return null;
  final KijiKankyou k = e.k;
  const int no = 2;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int sh = e.shumoku;
  final String sm = kijiShumokuMei[sh];
  final String mm = m.mei;
  final int r = m.juni;
  // 総合の目標順位(0が1位。全大学とも8位)
  final int mk = (m.u.mokuhyojuni.length > _sougouBangou &&
          m.u.mokuhyojuni[_sougouBangou] >= 0 &&
          m.u.mokuhyojuni[_sougouBangou] < e.n)
      ? m.u.mokuhyojuni[_sougouBangou]
      : _meiseiJuniSuu - 1;
  final bool tassei = r <= mk;
  final List<TaikousenSenshuKekka> mine = [
    for (final TaikousenSenshuKekka x in e.kojin)
      if (x.s.univid == m.u.id) x,
  ];
  final int shJ = e.shumokuJuni(m, sh);
  final int nyuushou = mine.where((x) => x.juni < _meiseiJuniSuu).length;
  // 記者の型(1.9.4)
  final KishaKata kata = k.kishaKata(no);

  // 見出し
  String midashi;
  if (e.saigo) {
    if (r == 0) {
      midashi = '$mmが対校戦の総合優勝';
    } else if (tassei) {
      midashi = '$mmは総合${juniMoji(r)}　目標の${juniMoji(mk)}以内を達成';
    } else {
      midashi = '$mmは総合${juniMoji(r)}　目標の${juniMoji(mk)}に届かず';
    }
  } else {
    midashi = '$mm、$smを終えて総合${juniMoji(r)}';
  }
  if (mine.isNotEmpty && mine.first.juni == 0) {
    midashi += '　${myouji(mine.first.s.name)}が$sm優勝';
  } else if (nyuushou >= 1) {
    midashi += '　$smで$nyuushou人が8位以内';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}の$smで、$mmのポイントは${m.point[sh]}点で、大学別${juniMoji(shJ)}だった。',
  );
  if (e.saigo) {
    lead.write('3種目の合計は${m.goukei}点で、総合${juniMoji(r)}となった。');
    lead.write(
      tassei
          ? '目標の${juniMoji(mk)}以内を達成した。'
          : '目標の${juniMoji(mk)}には届かなかった。',
    );
    final int mae = juniRace(m.u, _sougouBangou, 1);
    if (!e.hatsuKaisai && shutsujouJuni(mae)) {
      if (mae > r) {
        lead.write('前回の${juniMoji(mae)}から順位を${mae - r}つ上げた。');
      } else if (mae < r) {
        lead.write('前回の${juniMoji(mae)}からは順位を落とした。');
      } else {
        lead.write('前回と同じ${juniMoji(mae)}だった。');
      }
    }
  } else {
    lead.write('ここまでの合計は${m.goukei}点で、総合${juniMoji(r)}につけている。');
  }
  // 目標順位のラインとの差
  if (tassei && mk + 1 < e.n) {
    final TaikousenUnivKekka soto = e.jun[mk + 1];
    lead.write('${juniMoji(mk + 1)}の${soto.mei}とは${_tensaMoji(m.goukei - soto.goukei)}だった。');
  } else if (!tassei) {
    final TaikousenUnivKekka line = e.jun[mk];
    lead.write('目標の${juniMoji(mk)}の${line.mei}とは${_tensaMoji(line.goukei - m.goukei)}だった。');
  }

  // 本文: 種目の走り
  w.koMidashi('$smの走り');
  final StringBuffer sb = StringBuffer();
  if (mine.isEmpty) {
    sb.write('$mmの選手は、この種目に出場しなかった。');
  } else {
    final TaikousenSenshuKekka top = mine.first;
    sb.write(
      top.juni == 0
          ? '学内トップの${w.senshu(top.s)}は、全体1位の${jikanMoji(top.time)}で$smを制した。'
          : '学内トップは${w.senshu(top.s)}で、全体${juniMoji(top.juni)}の${jikanMoji(top.time)}だった。',
    );
    if (nyuushou >= 2) {
      sb.write('名声のかかる8位以内には$nyuushou人が入った。');
    }
    // 1年生の最高(学内トップでなければ)
    if (!k.ichinenDake) {
      for (final TaikousenSenshuKekka x in mine) {
        if (x.s.gakunen != 1) continue;
        if (x.s.id != top.s.id) {
          sb.write('1年生では${w.senshu(x.s)}の全体${juniMoji(x.juni)}が最高だった。');
        }
        break;
      }
    }
    // 平均順位(層の厚さ)
    final double heikin =
        mine.fold<int>(0, (t, x) => t + x.juni) / mine.length + 1;
    sb.write('出場した${mine.length}人の平均順位は${heikin.toStringAsFixed(1)}位だった。');
  }
  w.danraku(sb.toString());
  // 学内トップの因縁とコメント(1.9.4)
  if (mine.isNotEmpty) {
    final TaikousenSenshuKekka top = mine.first;
    final List<Innen> ti = taikousenInnen(k, top.s, juni: top.juni);
    if (ti.isNotEmpty && ti.first.ten >= 40) {
      w.danraku('${w.senshu(top.s)}。${ti.first.bun}');
    }
    final bool nyuu = top.juni < _meiseiJuniSuu;
    w.comment(
      senshuCommentJijitsu(
        w,
        top.juni == 0
            ? CommentBamen.taikousenKojinYuushou
            : (nyuu ? CommentBamen.gakunaiNyuushou : CommentBamen.gakunaiTaikousen),
        myouji(top.s.name),
        jijitsu: [
          if (ti.isNotEmpty) ti.first.kotoba,
          nyuu
              ? '全体${juniMoji(top.juni)}。チームのポイントに少しは貢献できたと思う'
              : '全体${juniMoji(top.juni)}。8位以内に届かなかったのは悔しい',
        ],
      ),
    );
    w.danraku(shusshinShumiBun(k, top.s, w.r, myouji(top.s.name)));
  }

  // 本文: 3種目を終えて(ハーフのあと)
  if (e.saigo) {
    w.koMidashi('3種目を終えて');
    w.danraku(
      '$mmの種目ごとのポイントは、'
      '${[for (int ev = 0; ev < 3; ev++) '${kijiShumokuMei[ev]}が${m.point[ev]}点(${juniMoji(e.shumokuJuni(m, ev))})'].join('、')}。',
    );
    w.comment(
      kantokuCommentJijitsu(
        w,
        r == 0
            ? KantokuBamen.taikousenYuushou
            : (tassei ? KantokuBamen.mokuhyouTassei : KantokuBamen.taikousenMitassei),
        m.u.id,
        kuyashii: r != 0 && !tassei,
        jijitsu: [
          tassei
              ? '目標の${juniMoji(mk)}に対して総合${juniMoji(r)}。全員の順位が効いた'
              : '目標の${juniMoji(mk)}に${r - mk}つ届かなかった。一人ひとりの順位の重みを思い知った',
          if (nyuushou >= 1) '$smで$nyuushou人が8位以内に入ってくれた',
        ],
      ),
    );
  }

  // 記者の目(記者の型で見方が変わる。自分の大学に辛口なのは、ハーフのあとで目標に届かなかったときだけ。1.9.4)
  final StringBuffer me = StringBuffer();
  KishaKata meKata = kata;
  if (meKata == KishaKata.karakuchi && !(e.saigo && !tassei)) meKata = KishaKata.suuji;
  switch (meKata) {
    case KishaKata.suuji:
      if (mine.isNotEmpty) {
        final double heikin = mine.fold<int>(0, (t, x) => t + x.juni) / mine.length + 1;
        me.write('$smは${mine.length}人が出場し、平均順位${heikin.toStringAsFixed(1)}位、8位以内は$nyuushou人。');
      }
      me.write(
        e.saigo
            ? (tassei ? '総合${juniMoji(r)}で目標の${juniMoji(mk)}以内。数字の上では、全員の順位の積み上げが届かせた。' : '総合${juniMoji(r)}。目標の${juniMoji(mk)}までの差は、一人ひとりが順位を1つ上げれば埋まる大きさだ。')
            : '総合${juniMoji(r)}で次の種目へ。対校戦は全員の順位がポイントになるので、残りの種目で1つずつ順位を上げることが鍵になる。',
      );
      break;
    case KishaKata.joukei:
      if (mine.isNotEmpty) {
        final TaikousenSenshuKekka top = mine.first;
        final List<Innen> ti = taikousenInnen(k, top.s, juni: top.juni);
        me.write('この種目を一人で語るなら、${myouji(top.s.name)}だ。');
        me.write(ti.isNotEmpty ? ti.first.bun : '全体${juniMoji(top.juni)}の走りが、チームの流れを作った。');
        me.write('その走りが、後ろを走る仲間の背中を押した。');
      } else {
        me.write('この種目に出場した選手はいなかった。残りの種目に、全員の力を注ぐ。');
      }
      break;
    case KishaKata.karakuchi:
      if (mine.isNotEmpty) {
        final TaikousenSenshuKekka last = mine.last;
        me.write('総合${juniMoji(r)}という結果より気になるのは、出場した${mine.length}人の中で一番後ろだった${myouji(last.s.name)}の全体${juniMoji(last.juni)}だ。');
        me.write('対校戦は全員の順位で決まる。上位の1人より、後ろの1人を上げるほうが、目標の${juniMoji(mk)}には近い。');
      } else {
        me.write('目標の${juniMoji(mk)}に届かなかったのは、$smに誰も出せなかったことが響いた。層の薄さが、そのまま点差になった。');
      }
      break;
  }
  w.kishaNoMe(me.toString());

  // 表
  final List<List<String>> gyou = [
    for (final TaikousenSenshuKekka x in mine)
      [
        juniMoji(x.juni),
        '${fullMei(x.s.name)}(${x.s.gakunen})',
        jikanMoji(x.time),
        '${x.point}',
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou('$mmの$smの成績', ['全体順位', '選手', 'タイム', 'ポイント'], gyou),
    ],
    jibun: true,
  );
}
