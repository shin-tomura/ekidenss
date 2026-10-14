import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/taikai_chouki.dart';
import 'package:ekiden/kansuu/kyouka_project.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// 強化プロジェクトの記事(2.0.1。kyouka_project.dart)
// ・強化プロジェクトが始まった年の4月5日に、箱庭スポーツの「期待のルーキー」と一緒に読める
//   (kiji.dart の kijiShinnyuuseiIchiran で、期待のルーキーの後ろに足す)
// ・理由の型ごとに見出しと段落を変える(創立○周年に向けて・クラウドファンディング・OB会と後援会・名指導者の招へい)
// ・正月駅伝の優勝から遠ざかっていること(最後の優勝の年度、または優勝なし)と、今年の正月駅伝の順位を書く
// ・守る決まり: 能力名・選手の性質の言葉と、総監督の言葉は書かない。名声の数字や、スカウトでの重みの数字も書かない
// ------------------------------------------------------------

/// 記事の番号(乱数と記者の名前に使う)
const int _no = 196;

/// 記事のカテゴリ
const String kijiKyoukaCategory = '強化プロジェクト';

/// 強化プロジェクトが今年度始まっていれば、その記事(なければ空)
List<Kiji> kyoukaProjectKiji(KijiKankyou k) {
  final int nendo = choukiNendo(k.gh);
  final KyoukaProject? p = kyoukaProjectChuu(k.kantoku, nendo);
  if (p == null || p.hajime != nendo) return [];
  UnivData? u;
  for (final UnivData x in k.univ) {
    if (x.id == p.univid) u = x;
  }
  if (u == null) return [];
  final KijiRand r = KijiRand(kijiTane(k.gh, 99, _no));
  final String mei = daigakuMei(u);
  final int nensuu = p.owari - p.hajime + 1;

  // 正月駅伝の優勝から遠ざかっていること
  final int tsuusan = choukiTsuusan(u, 2, choukiYuushou);
  final ChoukiKiroku? c = choukiYomu(u, 2, choukiYuushou);
  final int saigo = c?.saigo ?? 0;
  final String mokuhyou; // 見出しとコメントに使う目標
  final String buriBun;
  if (tsuusan <= 0) {
    mokuhyou = '悲願の初優勝';
    buriBun = '正月駅伝ではまだ優勝がなく、悲願の初優勝を目指す。';
  } else if (saigo > 0) {
    final int buri = nendo - saigo;
    mokuhyou = '$buri年ぶりの優勝';
    buriBun = tsuusan == 1
        ? '正月駅伝では$saigo年度に優勝しているが、それから$buri年、頂点から遠ざかっている。'
        : '正月駅伝では通算$tsuusan回の優勝を誇るが、$saigo年度を最後に$buri年、頂点から遠ざかっている。';
  } else {
    mokuhyou = '久しぶりの優勝';
    buriBun = tsuusan == 1
        ? '正月駅伝では優勝の経験があるが、長く頂点から遠ざかっている。'
        : '正月駅伝では通算$tsuusan回の優勝を誇るが、長く頂点から遠ざかっている。';
  }

  // 今年の正月駅伝の順位
  final int juni = u.juni_race.length > 2 && u.juni_race[2].isNotEmpty
      ? u.juni_race[2][0]
      : TEISUU.DEFAULTJUNI;
  final String kotoshiBun = juni < TEISUU.DEFAULTJUNI
      ? '今年の正月駅伝は${juni + 1}位だった。'
      : '今年の正月駅伝には出場できなかった。';

  // 理由の型ごとの見出しと段落
  String midashi;
  String riyuuBun;
  switch (p.kata) {
    case kyoukaKataShuunen:
      final int y = kyoukaShuunenNendo(u.id, p.hajime, p.owari) ?? p.hajime;
      final int shuunen = y - kyoukaSouritsuNendo(u.id);
      midashi = r.erabu([
        '$mei、創立$shuunen周年へ強化プロジェクト始動',
        '$mei、創立$shuunen周年に向け強化プロジェクト　スカウトに本腰',
      ]);
      riyuuBun = y == p.hajime
          ? '大学は今年度、創立$shuunen周年を迎える。記念事業の柱の一つとして、陸上競技部の強化に乗り出す。'
          : '大学は$y年度に創立$shuunen周年を迎える。記念の年に向けた事業の柱の一つとして、陸上競技部の強化に乗り出す。';
    case kyoukaKataCrowd:
      midashi = r.erabu([
        '$mei、クラウドファンディングで強化費　スカウトに本腰',
        '$mei、ファンの支援で強化プロジェクト　$mokuhyouへ',
      ]);
      riyuuBun =
          '強化費の一部はクラウドファンディングで募り、卒業生や地元のファンから多くの支援が寄せられているという。'
          '集まった資金は、有望な高校生のスカウト活動などに充てる。';
    case kyoukaKataOB:
      midashi = r.erabu([
        '$mei、OB会と後援会が全面支援　強化プロジェクト始動',
        '$mei、強化プロジェクト始動　OB会と後援会が後押し',
      ]);
      riyuuBun =
          'OB会と後援会が、資金と人脈の両面で後押しする。全国の高校の指導者とのつながりを生かし、有望な新入生の獲得を目指す。';
    default:
      midashi = r.erabu([
        '$mei、名指導者を強化責任者に招へい　スカウトに本腰',
        '$mei、強化責任者に名指導者　$mokuhyouへ',
      ]);
      riyuuBun =
          '実業団で長く指導してきた名指導者を強化責任者に迎え、スカウトの陣頭指揮を任せる。'
          '全国の有望な高校生に、積極的に声をかけていく方針だ。';
  }

  final String lead =
      '$meiが、${p.hajime}年度から${p.owari}年度までの$nensuu年間、陸上競技部の強化プロジェクトに取り組むと発表した。'
      '柱は新入生のスカウトで、有望な高校生の獲得に本腰を入れる。';

  final List<KijiBlock> honbun = [
    KijiBlock(KijiBlockShurui.danraku, riyuuBun),
    KijiBlock(KijiBlockShurui.danraku, '$buriBun$kotoshiBun'),
    KijiBlock(
      KijiBlockShurui.comment,
      r.erabu([
        '「$mokuhyouに向けて、大学を挙げて本気で取り組みます」(大学関係者)',
        '「今がチームを変える好機です。$mokuhyouを目指します」(大学関係者)',
        '「有望な選手に来てもらえる大学にしたい。目標は$mokuhyouです」(大学関係者)',
      ]),
    ),
    KijiBlock(
      KijiBlockShurui.danraku,
      r.erabu([
        'ライバル校にとっては、有望な高校生の獲得で手ごわい相手が現れた形だ。今年の新入生の進学先にも、早くも変化が出ている。',
        '名門校にとっても、新入生の争奪戦で無視できない存在になりそうだ。この$nensuu年間でチームがどこまで変わるか、注目したい。',
      ]),
    ),
  ];

  // 正月駅伝の直近5回の順位(順位の記録の[0]が最後に開かれた年度の大会)
  final int saigoKaisai = choukiKaisaiNendo(u, 2);
  final List<List<String>> gyou = [];
  if (u.juni_race.length > 2) {
    for (int i = 0; i < 5 && i < u.juni_race[2].length; i++) {
      final int j = u.juni_race[2][i];
      final String nendoMoji = saigoKaisai > 0 ? '${saigoKaisai - i}年度' : '${i + 1}回前';
      if (saigoKaisai > 0 && saigoKaisai - i < 1) break;
      gyou.add([nendoMoji, j < TEISUU.DEFAULTJUNI ? '${j + 1}位' : '出場なし']);
    }
  }

  return [
    Kiji(
      category: kijiKyoukaCategory,
      midashi: midashi,
      lead: lead,
      honbun: honbun,
      hyou: [
        if (gyou.isNotEmpty)
          KijiHyou('$meiの正月駅伝(直近の成績)', const ['年度', '順位'], gyou),
      ],
      haishin: k.haishinMei(_no, asa: true),
      kisha: k.kishaMei(_no),
      jibun: false,
      kekka: false,
    ),
  ];
}
