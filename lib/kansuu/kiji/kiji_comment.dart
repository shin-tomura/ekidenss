import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// ニュース記事のコメント(選手と大学の監督の言葉。1.9.2)
// 総監督(プレイヤー)の言葉は作らない。場面ごとに数通りの言い回しを持ち、記事の乱数で選ぶ
// ------------------------------------------------------------

/// コメントの場面
enum CommentBamen {
  /// 優勝を決めた(アンカーや逆転した選手)
  yuushouKetteiSenshu,

  /// 区間賞
  kukanshou,

  /// 区間新記録
  kukanshin,

  /// 大きく順位を上げた
  oinuki,

  /// ブレーキ(区間下位)
  brake,

  /// 1年生の好走
  ichinenKousou,

  /// 4年生の最後の大会
  yonenSaigo,

  /// 当日変更で起用されて好走
  toujitsuKiyou,

  /// 留学生の好走
  ryuugakusei,

  /// 予選で通過を決めた
  yosenTsuuka,

  /// 予選で落選
  yosenRakusen,

  /// 予選の個人トップ
  yosenKojinTop,

  /// 展望(意気込み)
  ikigomi,
}

/// 監督のコメントの場面
enum KantokuBamen {
  yuushou,
  mokuhyouTassei,
  mokuhyouMitassei,
  seedKakutoku,
  seedSoushitsu,
  taihai,
  yosenTsuuka,
  yosenRakusen,
  tenbouHonmei,
  tenbouChousen,
}

const Map<CommentBamen, List<String>> _senshuComment = {
  CommentBamen.yuushouKetteiSenshu: [
    '前の背中が見えてから、絶対に抜くと決めていた',
    'みんながつないでくれたたすきなので、最後は気持ちだけでした',
    'ゴールテープを切る瞬間は、今までの練習が全部頭に浮かびました',
    '自分が決めるんだと思って走りました。最高の景色でした',
    '苦しかったけど、仲間の顔を思い浮かべたら足が前に出ました',
  ],
  CommentBamen.kukanshou: [
    '自分の走りができた。区間賞は素直にうれしい',
    '区間賞は狙っていた。練習どおりに走れました',
    '後半もしっかり体が動いた。チームに勢いを渡せてよかった',
    '最初から攻めると決めていた。それが結果につながった',
    'まだ課題もある。次はもっといいタイムを出したい',
  ],
  CommentBamen.kukanshin: [
    '記録は意識していなかったが、後半まで体が動いた',
    '沿道の声援に背中を押された。記録は後からついてきた',
    '設定より速く入ったが、最後まで押し切れた。自分でも驚いている',
    '区間記録を出せたのは、支えてくれた人たちのおかげです',
  ],
  CommentBamen.oinuki: [
    '前が見えるたびに、一人ずつ拾っていこうと思っていた',
    '順位を上げることだけを考えた。前を追う展開は得意なので',
    '後ろを気にせず、とにかく前だけを見て走った',
    'チームのために一つでも順位を上げたかった',
  ],
  CommentBamen.brake: [
    'チームに迷惑をかけてしまった。この悔しさは次で返したい',
    '途中から体が動かなくなった。自分の力不足です',
    '期待に応えられず申し訳ない。もう一度鍛え直します',
    '何もできなかった。この経験を絶対に無駄にしない',
  ],
  CommentBamen.ichinenKousou: [
    '先輩たちが前で戦ってくれたので、思い切って行けた',
    '緊張したけど、楽しんで走れました。来年はもっと上を狙いたい',
    '1年生らしく、怖がらずに攻めることだけを考えていた',
    '高校時代から憧れていた舞台。走れてうれしかった',
  ],
  CommentBamen.yonenSaigo: [
    '4年間の全部をぶつけた。悔いはありません',
    '最後の大会で、自分らしく走れた。後輩たちに思いを託したい',
    'このチームで走れたことが一番の財産です',
    '苦しい時期もあったけど、最後に走れて本当によかった',
  ],
  CommentBamen.toujitsuKiyou: [
    '当日の朝に起用を伝えられた。準備はしていたので落ち着いて走れた',
    'いつでも行けるように準備していた。チャンスをもらえてよかった',
    '補欠に回っても気持ちは切らさなかった。それが報われた',
  ],
  CommentBamen.ryuugakusei: [
    'チームのために走った。みんなと一緒に喜べてうれしい',
    '日本での駅伝は特別。仲間の声が力になった',
    'もっと速く走れると思う。次も頑張りたい',
  ],
  CommentBamen.yosenTsuuka: [
    'ほっとしました。本戦では、もっと上を目指したい',
    '本戦への切符を取れて一安心。ここからが本番です',
    '全員で粘った結果だと思う。本戦でも暴れたい',
  ],
  CommentBamen.yosenRakusen: [
    '言葉が見つからない。本当に悔しい',
    'あと一歩が届かなかった。この悔しさを忘れずに練習したい',
    '自分がもう少し粘れていれば。来年は必ず戻ってくる',
  ],
  CommentBamen.yosenKojinTop: [
    '自分の役割は、チームのために一つでも前でゴールすること。それができてよかった',
    'トップは狙っていた。最後まで集中を切らさずに走れた',
    'チームの順位につながる走りができてうれしい',
  ],
  CommentBamen.ikigomi: [
    'チームの目標のために、自分の区間で役割を果たしたい',
    '調子は上がってきている。自分の走りをするだけです',
    '任された区間で、一つでも前に順位を上げたい',
    'ずっとこの舞台を目標にしてきた。思い切り走りたい',
  ],
};

const Map<KantokuBamen, List<String>> _kantokuComment = {
  KantokuBamen.yuushou: [
    '選手たちが本当によく頑張ってくれた。今日は彼らをほめてあげたい',
    '一人ひとりが自分の役割を果たしてくれた。チーム全員でつかんだ優勝です',
    '苦しい場面もあったが、最後まで諦めずにたすきをつないでくれた',
    'この一年、積み上げてきたものが形になった。選手に感謝したい',
  ],
  KantokuBamen.mokuhyouTassei: [
    '目標は達成できた。選手たちは力を出し切ってくれた',
    'よく粘ってくれた。次はもう一つ上を目指したい',
    '想定どおりのレースができた。収穫の多い大会になった',
  ],
  KantokuBamen.mokuhyouMitassei: [
    '目標には届かなかった。私の配置も含めて、もう一度見直したい',
    '悔しい結果だが、選手たちは最後まで戦ってくれた。課題ははっきりした',
    '力はあるチームなので、次は必ず巻き返したい',
  ],
  KantokuBamen.seedKakutoku: [
    'シード権を取れたことは大きい。来年につながる',
    '最後まで気の抜けない展開だったが、選手がよく粘ってくれた',
  ],
  KantokuBamen.seedSoushitsu: [
    'シード権を失ったのは本当に悔しい。予選から出直します',
    'あと一歩だった。この悔しさを来年にぶつけたい',
  ],
  KantokuBamen.taihai: [
    '完敗です。一から鍛え直さないといけない',
    '流れをつかめないまま終わってしまった。立て直したい',
  ],
  KantokuBamen.yosenTsuuka: [
    'まずはほっとしている。本戦では、この悔しさも喜びも力に変えたい',
    '選手たちがよく粘ってくれた。本戦に向けてしっかり準備したい',
  ],
  KantokuBamen.yosenRakusen: [
    '選手たちは力を出してくれた。届かなかったのは私の責任です',
    'この悔しさを、来年に必ずつなげたい',
  ],
  KantokuBamen.tenbouHonmei: [
    '追われる立場だが、いつもどおりのレースをすればいい',
    '選手の状態はいい。自分たちの走りに集中したい',
    '本命と言われるのはありがたいこと。重圧も力に変えたい',
  ],
  KantokuBamen.tenbouChousen: [
    '失うものは何もない。思い切ってぶつかっていきたい',
    'チャレンジャーとして、一つでも上の順位を目指す',
    '上位校の背中は見えている。選手たちを信じて送り出したい',
  ],
};

const List<String> _senshuShimeKotoba = [
  'と振り返った',
  'と笑顔を見せた',
  'と胸を張った',
  'と息を弾ませた',
  'と汗をぬぐった',
  'と話した',
];

const List<String> _kuyashiShimeKotoba = [
  'と唇をかんだ',
  'と悔しさをにじませた',
  'と言葉を絞り出した',
  'とうつむいた',
];

const List<String> _kantokuShimeKotoba = [
  'と目を細めた',
  'とうなずいた',
  'と語った',
  'と話した',
];

const List<String> _kantokuKuyashiShimeKotoba = [
  'と厳しい表情で語った',
  'と前を向いた',
  'と悔しさをかみしめた',
];

/// 選手のコメントの文(「「……」と山田は振り返った。」の形)
/// [kuyashii] 悔しい場面なら、締めの言葉を悔しいほうにする
String senshuComment(
  KijiKakite w,
  CommentBamen bamen,
  String yobi, {
  bool kuyashii = false,
}) {
  final List<String> kouho = _senshuComment[bamen] ?? const ['よかった'];
  final String naka = w.erabu(kouho);
  // 締めの言葉はどれも「と」で始まる(「と振り返った」→「と山田は振り返った」)
  final String shime = w.erabu(
    kuyashii ? _kuyashiShimeKotoba : _senshuShimeKotoba,
  );
  return '「$naka」と$yobiは${shime.substring(1)}。';
}

/// 監督のコメントの文(監督がいなければ空)
String kantokuComment(
  KijiKakite w,
  KantokuBamen bamen,
  int univid, {
  bool kuyashii = false,
}) {
  final ({String name, int nenrei})? kt = w.k.kantokuMei(univid);
  if (kt == null) return '';
  final List<String> kouho = _kantokuComment[bamen] ?? const ['よくやってくれた'];
  final String naka = w.erabu(kouho);
  final String shime = w.erabu(
    kuyashii ? _kantokuKuyashiShimeKotoba : _kantokuShimeKotoba,
  );
  // 初めて出すときは「山田太郎監督(45)」、2回目からは「山田監督」
  final String kagi = 'K$univid';
  final bool hajimete = !w.deta(kagi);
  final String yobi = w.hito(kagi, kt.name, '', '');
  final String kata = hajimete ? '$yobi監督(${kt.nenrei})' : '$yobi監督';
  return '「$naka」と$kataは${shime.substring(1)}。';
}
