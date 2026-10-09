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

  /// 予選で、わずかの差で通過を逃した(次点)
  yosenJiten,

  /// 展望(意気込み)
  ikigomi,

  /// 対校戦の種目で個人優勝
  taikousenKojinYuushou,

  // ここから学内メディア(○○スポーツ。1.9.3。kiji_gakunai.dart)の場面。学内らしく温かい言葉にする

  /// 学内・駅伝を走ったあと(特に目立つことがないとき)
  gakunaiKekka,

  /// 学内・エントリーされながら走れなかった
  gakunaiHoketsu,

  /// 学内・当日変更で区間に入る(レース前)
  gakunaiIri,

  /// 学内・当日変更で区間から外れた(レース前)
  gakunaiHazureta,

  /// 学内・展望の意気込み
  gakunaiIkigomi,

  /// 学内・4年生の意気込み
  gakunaiYonenIkigomi,

  /// 学内・初めての駅伝を走る選手の意気込み
  gakunaiDebutIkigomi,

  /// 学内・卒業する4年生
  sotsugyou,

  /// 学内・当日の朝に体調を崩し、走れなかった(レース後。1.9.4)
  gakunaiTaichouHazureta,

  /// 学内・駅伝予選を走ったあと
  gakunaiYosen,

  /// 学内・駅伝予選の意気込み
  gakunaiYosenIkigomi,

  /// 学内・対校戦の種目で8位以内に入賞(優勝のときは taikousenKojinYuushou)
  gakunaiNyuushou,

  /// 学内・対校戦の種目を走ったあと(入賞しなかったとき)
  gakunaiTaikousen,

  /// 学内・対校戦の種目で、昨年の同じ種目から大きく順位を上げた(伸び盛り)
  gakunaiNobi,
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

  /// 展望(シード権争い)
  tenbouSeed,

  /// 予選で、わずかの差で通過を逃した(次点)
  yosenJiten,

  /// 駅伝で、わずかの差で優勝を逃した(僅差の2位)
  kinsaJunyuushou,

  /// 対校戦の総合優勝
  taikousenYuushou,

  /// 対校戦の総合で、目標の8位以内に入った(8位争いを制した)
  taikousenHachii,

  /// 対校戦の総合で、8位以内をわずかに逃した
  taikousenHachiiNogasu,

  /// 対校戦の総合で、目標順位に届かなかった
  taikousenMitassei,

  /// 学内・卒業する4年生への送る言葉(1.9.3)
  sotsugyou,
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
  CommentBamen.yosenJiten: [
    'あと1秒、自分が削れていれば。悔しくてたまらない',
    '最後に粘り切れなかった。自分の1秒が足りなかった',
    '一人ひとりがあと少しずつ速ければ届いた。この差は一生忘れない',
    '結果を見て言葉が出なかった。来年は必ずこの悔しさを晴らす',
  ],
  CommentBamen.yosenKojinTop: [
    '自分の役割は、チームのために一つでも前でゴールすること。それができてよかった',
    'トップは狙っていた。最後まで集中を切らさずに走れた',
    'チームの順位につながる走りができてうれしい',
  ],
  CommentBamen.taikousenKojinYuushou: [
    'チームのポイントのために、1つでも前でゴールすることだけを考えた',
    'ラストの勝負になると思っていた。最後まで脚が残っていてよかった',
    '大学の名前を背負って走った。勝ててうれしい',
    'この種目で勝つことを目標にしてきた。大きな自信になります',
  ],
  CommentBamen.ikigomi: [
    'チームの目標のために、自分の区間で役割を果たしたい',
    '調子は上がってきている。自分の走りをするだけです',
    '任された区間で、一つでも前に順位を上げたい',
    'ずっとこの舞台を目標にしてきた。思い切り走りたい',
  ],
  CommentBamen.gakunaiKekka: [
    '自分の役割は果たせたと思う。次はもっと前で勝負したい',
    '応援の声がずっと聞こえていた。最後まで力になった',
    'たすきの重みを感じながら走った。チームのみんなに感謝したい',
    '収穫と課題の両方が見えた。また一から積み上げます',
    '思っていたより体が動いた。練習してきてよかった',
    '前を追う気持ちだけは切らさなかった。それは自分をほめたい',
    '仲間の顔を思い浮かべたら、苦しいところでも粘れた',
    'この区間を走れたことが、自分の財産になった',
  ],
  CommentBamen.gakunaiHoketsu: [
    '走れない悔しさはあるけど、みんなの走りが誇らしかった',
    '給水や付き添いで、自分にできることをやり切った',
    'この悔しさを、次は自分が走ってぶつけたい',
    'チームの一員として、最後まで一緒に戦えた',
  ],
  CommentBamen.gakunaiIri: [
    '準備はしてきた。任された区間で、思い切って走るだけです',
    'チャンスをもらえた。仲間の思いも背負って走ります',
    'いつでも行けるように整えてきた。落ち着いて入りたい',
    '名前を呼ばれて身が引き締まった。チームのために走ります',
  ],
  CommentBamen.gakunaiHazureta: [
    '悔しいけど、仲間に思いを託します。沿道から全力で応援する',
    '自分の分まで走ってくれると信じている',
    'チームが勝つことが一番。できることを全力でやります',
    'この悔しさは必ず次に生かす。今日はみんなの背中を押したい',
  ],
  CommentBamen.gakunaiIkigomi: [
    'チームの目標のために、自分の区間で役割を果たしたい',
    '調子は上がってきている。自分の走りをするだけです',
    '任された区間で、一つでも前に順位を上げたい',
    'ずっとこの舞台を目標にしてきた。思い切り走りたい',
    '練習は積めている。あとは自分を信じて走るだけ',
    '応援してくれる人たちに、いい報告ができるように走ります',
    'この区間を走りたいとずっと思っていた。楽しみです',
    '前半から自分のリズムを大切にしたい',
    '緊張よりも、楽しみな気持ちのほうが大きい',
    '最後まで粘って、1秒でも削り出したい',
    '仲間からもらったたすきを、責任を持って運びます',
  ],
  CommentBamen.gakunaiYonenIkigomi: [
    '4年生として、最後は笑って終わりたい',
    '後輩たちに、背中で伝える走りをしたい',
    'このチームで走れる最後の大会。悔いなく走り切ります',
    '4年間で一番の走りを、この舞台で見せたい',
  ],
  CommentBamen.gakunaiDebutIkigomi: [
    '初めての駅伝。怖がらずに攻めたい',
    '先輩たちに少しでも楽をさせられる走りをしたい',
    'ずっと憧れていた舞台。思い切り楽しみたい',
    'たすきをもらうのが楽しみです。自分らしく走ります',
  ],
  CommentBamen.gakunaiYosen: [
    '1秒でも削ることだけを考えて走った',
    'チームの合計のために、最後まで粘れた',
    '大きな集団の中でも、落ち着いて自分のリズムで走れた',
    '苦しいところで、仲間の顔が浮かんで踏ん張れた',
    'まだまだ力が足りない。次はもっと前でゴールしたい',
    '応援の声が聞こえて、最後にもう一段ギアを上げられた',
    '自分の役割は果たせたと思う。この経験を次につなげたい',
    '予選会の緊張感は特別。いい経験になった',
  ],
  CommentBamen.gakunaiYosenIkigomi: [
    'チームの合計のために、1秒でも削り出したい',
    '本戦への切符を、みんなでつかみたい',
    '自分の役割を果たして、チームを本戦へ連れていきたい',
    '集団の中で落ち着いて走り、最後に勝負したい',
    '予選は全員で戦うレース。自分も必ず力になります',
    '練習してきたことを信じて、粘り強く走ります',
  ],
  CommentBamen.gakunaiNyuushou: [
    '入賞は目標にしていた。チームのポイントにも貢献できてうれしい',
    '最後まで前の選手に食らいついた。それが入賞につながった',
    '大学の名前を背負って走った。入賞できてほっとしている',
    '上位の選手と走れて、自分の力も分かった。もっと上を目指したい',
    '応援の声が力になった。この入賞を自信にしたい',
  ],
  CommentBamen.gakunaiTaikousen: [
    'チームのポイントのために、1つでも前でゴールしようと走った',
    '前の選手を1人でも多く抜くことだけを考えた',
    '大きな大会の雰囲気の中で、自分の走りを試せた',
    'まだ上の選手との差は大きい。夏にしっかり鍛えたい',
    '収穫と課題の両方が見えた。駅伝シーズンにつなげたい',
    '最後まで粘れたのは、練習の成果だと思う',
    '応援の声が聞こえて、苦しいところで踏ん張れた',
  ],
  CommentBamen.gakunaiNobi: [
    '1年間、地道に積み上げてきたことが形になった',
    '去年の自分を超えることを目標にしてきた。少しは成長できたと思う',
    '練習の手応えはあった。結果につながってうれしい',
  ],
  CommentBamen.gakunaiTaichouHazureta: [
    '朝に走れないと分かったときは、言葉が出なかった。でも仲間が走ってくれた',
    '走れなかった悔しさより、代わりに走ってくれた仲間への感謝のほうが大きい',
    '自分の区間を仲間が走るのを、ただ見ているしかなかった。来年は必ず自分が走る',
    '体調を崩したのは自分の責任。この悔しさは忘れない',
  ],
  CommentBamen.sotsugyou: [
    '4年間、このチームで走れて本当に幸せでした',
    '苦しい時期も、仲間がいたから乗り越えられた。後輩たちに思いを託します',
    '最後まで走り切れたのは、支えてくれた人たちのおかげです',
    '思うような結果ばかりではなかったけど、悔いはありません',
    'この4年間は一生の宝物です。後輩たちには、もっと上の景色を見てほしい',
    '仲間と過ごした毎日が、一番の思い出です',
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
  KantokuBamen.yosenJiten: [
    '1秒の重みを思い知らされた。選手たちに申し訳ない',
    'これだけの僅差で届かないのは、私の力不足。来年、必ず取り返す',
    '紙一重だった。この経験を、チーム全員で次につなげたい',
  ],
  KantokuBamen.kinsaJunyuushou: [
    'わずかの差だった。選手たちはよく戦ってくれたが、勝たせてあげられなかった',
    'あと少しが届かなかった。この差を埋めるのが、来年への宿題です',
    '最後まで優勝を争えたのは収穫。ただ、この負けは本当に悔しい',
  ],
  KantokuBamen.taikousenYuushou: [
    '全員が1つでも前でゴールしようと粘ってくれた。総合力でつかんだ優勝です',
    '5000mから最後のハーフまで、チーム全員で積み上げた結果だと思う',
    '層の厚さを見せられた。選手たちを誇りに思う',
  ],
  KantokuBamen.taikousenHachii: [
    '最後までどうなるか分からなかった。一人ひとりの1つの順位が効いた',
    '8位以内は最低限の目標。まずはほっとしています',
  ],
  KantokuBamen.taikousenHachiiNogasu: [
    '一人ひとりの順位の重みを思い知らされた。もう一度鍛え直したい',
    'あと少しだった。この悔しさを夏の練習にぶつけたい',
  ],
  KantokuBamen.taikousenMitassei: [
    '目標には届かなかった。チーム全体の底上げが課題です',
    '上位の選手は頑張ったが、層の薄さが出た。夏に鍛え直したい',
    '悔しい結果だが、課題ははっきりした。駅伝シーズンにつなげたい',
  ],
  KantokuBamen.sotsugyou: [
    '4年間よく頑張ってくれた。彼らが残したものは、後輩たちに必ず受け継がれる',
    'この学年がチームの土台を作ってくれた。新しい場所での活躍を期待している',
    '苦しい時期も前を向いてくれた。胸を張って卒業してほしい',
  ],
  KantokuBamen.tenbouSeed: [
    'まずはシード権を確実に取る。そこから一つでも上を目指したい',
    'シード権争いは毎年最後までもつれる。1秒を削り出す走りをしてほしい',
    '来年を予選会から始めるかどうかが決まる大事なレース。選手もよく分かっている',
    'シード権は来年のチームへの最高の贈り物になる。全員で取りにいく',
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

// 事実入りのコメント(1.9.4)。気持ちの言葉に、その選手の因縁やその日の数字を話し言葉で足す

/// 次へ向かう言葉(事実入りのコメントの最後に、ときどき足す)
const List<String> _tsugiKotoba = [
  '次はもっと上で勝負したい',
  'まだ終わりじゃない。ここからです',
  'この走りを、次につなげたい',
  '支えてくれた仲間に感謝したい',
  'まだ満足はしていない',
];

const List<String> _tsugiKuyashiKotoba = [
  'この悔しさは、次で必ず返します',
  'もう一度、一から積み上げます',
  '言い訳はしない。やるだけです',
];

/// 事実入りのコメントの締め(「」のあとに続く文。[yobi]を選手の呼び方に置き換える)
const List<String> _jijitsuShime = [
  '。[yobi]は、一つずつ言葉を選びながら話した。',
  '。そう言って[yobi]は、ようやく表情を緩めた。',
  '。[yobi]の言葉には、実感がこもっていた。',
  '。[yobi]は、1年分の思いを一気に吐き出した。',
];

const List<String> _jijitsuKuyashiShime = [
  '。[yobi]は、それ以上は言葉にしなかった。',
  '。[yobi]は、最後まで顔を上げなかった。',
  '。[yobi]は、言葉を絞り出すように話した。',
];

/// 選手のコメント(事実入り。1.9.4)
/// [jijitsu] その選手の事実の話し言葉(因縁の kotoba や、その日の数字。「。」なし)。
/// 空なら今まで通りの気持ちだけのコメントにする
String senshuCommentJijitsu(
  KijiKakite w,
  CommentBamen bamen,
  String yobi, {
  List<String> jijitsu = const [],
  bool kuyashii = false,
}) {
  final List<String> j = [
    for (final String x in jijitsu)
      if (x.trim().isNotEmpty) x.trim(),
  ];
  if (j.isEmpty) return senshuComment(w, bamen, yobi, kuyashii: kuyashii);
  final List<String> kouho = _senshuComment[bamen] ?? const ['よかった'];
  final String kimochi = w.erabu(kouho);
  // 気持ちの言葉が2文なら事実は1つ、1文なら2つまで(長くなりすぎないように)
  final List<String> tsukau = j.take(kimochi.contains('。') ? 1 : 2).toList();
  final List<String> bu = [];
  if (w.r.kakuritsu(50)) {
    bu.addAll(tsukau);
    bu.add(kimochi);
  } else {
    bu.add(kimochi);
    bu.addAll(tsukau);
  }
  // 気持ちの言葉が1文で事実も1つなら、ときどき次へ向かう言葉を足す(長くなりすぎないように)
  if (tsukau.length == 1 && !kimochi.contains('。') && w.r.kakuritsu(50)) {
    bu.add(w.erabu(kuyashii ? _tsugiKuyashiKotoba : _tsugiKotoba));
  }
  final String naka = bu.join('。');
  if (w.r.kakuritsu(50)) {
    final String shime = w.erabu(
      kuyashii ? _kuyashiShimeKotoba : _senshuShimeKotoba,
    );
    return '「$naka」と$yobiは${shime.substring(1)}。';
  }
  final String shime = w.erabu(kuyashii ? _jijitsuKuyashiShime : _jijitsuShime);
  return '「$naka」${shime.replaceAll('[yobi]', yobi)}';
}

/// 監督のコメント(事実入り。1.9.4。監督がいなければ空)
/// [jijitsu] 監督の事実の話し言葉(目標との差や、流れを変えた区間など。「。」なし)
String kantokuCommentJijitsu(
  KijiKakite w,
  KantokuBamen bamen,
  int univid, {
  List<String> jijitsu = const [],
  bool kuyashii = false,
}) {
  final List<String> j = [
    for (final String x in jijitsu)
      if (x.trim().isNotEmpty) x.trim(),
  ];
  if (j.isEmpty) return kantokuComment(w, bamen, univid, kuyashii: kuyashii);
  final ({String name, int nenrei})? kt = w.k.kantokuMei(univid);
  if (kt == null) return '';
  final List<String> kouho = _kantokuComment[bamen] ?? const ['よくやってくれた'];
  final String kimochi = w.erabu(kouho);
  final List<String> tsukau = j.take(kimochi.contains('。') ? 1 : 2).toList();
  final List<String> bu = w.r.kakuritsu(50)
      ? [...tsukau, kimochi]
      : [kimochi, ...tsukau];
  final String naka = bu.join('。');
  final String shime = w.erabu(
    kuyashii ? _kantokuKuyashiShimeKotoba : _kantokuShimeKotoba,
  );
  final String kagi = 'K$univid';
  final bool hajimete = !w.deta(kagi);
  final String yobi = w.hito(kagi, kt.name, '', '');
  final String kata = hajimete ? '$yobi監督(${kt.nenrei})' : '$yobi監督';
  return '「$naka」と$kataは${shime.substring(1)}。';
}

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
