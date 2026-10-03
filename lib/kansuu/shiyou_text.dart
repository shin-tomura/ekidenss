import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart';
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';

// ------------------------------------------------------------
// ゲームの仕様の文(1.8.3で生成AI向けに作り、1.8.4から説明書と共通にした)
// ・ここの文から、次の両方を作る。
//   ・説明書タブ(setting_screen.dart。説明書だけの部分は setsumeisho_text.dart)
//   ・「生成AIに渡すテキスト」の「ゲームの仕様(生成AI向け)」と、目標順位相談セット
// ・見出しごとに関数を分け、1行に1つのことを「・」で始めて書く(書き方の決まりはCLAUDE.md)。
// ・setsumeisho: true のときだけ出す行は、プレイヤーへの案内(設定タブの設定や画面の場所など)。
//   生成AI向けには、設定の名前や値は書かない。
//   また、生成AIが自分のことと読み違えないように、生成AI向けでは「あなた」を「プレイヤー」と書く。
// ・計算式や内部の係数は書かない。仕組みそのものがなくなる設定(0%)のときだけ、その部分の文を書き換える
//   (能力のタイムへの影響度、目標順位・指示の補正設定、調子のタイムへの影響度)。
//   学連選抜モチベーション低下補正は、初期値が「補正なし」なので、補正をかけているときだけ文を足す。
// ・目標順位を決める画面の説明で仕様を変えたら、ここも直す(CLAUDE.mdにも書いてある)
// ------------------------------------------------------------

/// 仕様の見出し1つ分
class ShiyouSetsu {
  const ShiyouSetsu(this.midashi, this.gyou);

  /// 見出し(説明書では前に⭐️、生成AI向けでは■を付ける)
  final String midashi;

  /// 本文。1行に1つのことを書き、「・」で始める(「　・」で始まる行は1段下げた行)
  final List<String> gyou;
}

/// ゲームの仕様の全文(生成AIに会話の最初に一度渡す用)
String gameShiyouText() {
  final StringBuffer sb = StringBuffer();
  sb.writeln('【箱庭小駅伝SS ゲームの仕様(生成AI向け)】');
  sb.writeln(
    'このゲームは、大学駅伝の総監督になって、エントリー・区間配置・目標順位・レース中の指示を決めるシミュレーションゲームです。'
    '以下は説明書に書かれている仕様を、相談のためにまとめたものです。計算式の細部はここには書いていないので、'
    'ここにないことを推測で答えるときは、推測であることを伝えてください。',
  );
  sb.writeln('');
  for (final ShiyouSetsu setsu in [
    shiyouSuuchi(),
    shiyouTaikai(),
    shiyouNouryoku(),
    shiyouMochiTime(),
    shiyouKeiken(),
    shiyouIchiku(),
    shiyouMokuhyou(),
    shiyouSiji(),
    shiyouKinGin(),
    shiyouMeisei(),
    shiyouGakuren(),
  ]) {
    _kakuSetsu(sb, setsu);
  }
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}

/// 仕様のうち「目標順位」と「レース中の指示」の部分(目標順位相談セットでも使う)
String shiyouMokuhyouSijiText() {
  final StringBuffer sb = StringBuffer();
  _kakuSetsu(sb, shiyouMokuhyou());
  _kakuSetsu(sb, shiyouSiji());
  return '${sb.toString().trimRight()}\n';
}

// 生成AI向けのテキストに見出し1つ分を書く
void _kakuSetsu(StringBuffer sb, ShiyouSetsu setsu) {
  sb.writeln('■${setsu.midashi}');
  for (final String gyou in setsu.gyou) {
    sb.writeln(gyou);
  }
  sb.writeln('');
}

// 総監督(プレイヤー)の呼び方。説明書では「あなた」
String _anata(bool setsumeisho) => setsumeisho ? 'あなた' : 'プレイヤー';

// 0%の設定で仕組みがないときの書き出し
String _konoData(bool setsumeisho) => setsumeisho ? '今の設定では' : 'このデータでは';

KantokuData? _kantoku() =>
    Hive.box<KantokuData>('kantokuBox').get('KantokuData');

/// 数値の読み方と能力を見抜く力
ShiyouSetsu shiyouSuuchi({bool setsumeisho = false}) {
  return const ShiyouSetsu('数値の読み方と能力を見抜く力', [
    '・タイムは小さいほど良く、能力値は大きいほど良いです。',
    '・基本走力(すべてのタイムのもとになる能力)は見えません。持ちタイム(記録会や大会での自己ベスト)が実力の目安になります。',
    '・能力値の「??」は、総監督に選手の能力を見抜く力がまだなく、見えていない能力です。',
    '・見抜く力は、目標順位を達成するとつくことがあります。',
    '・見抜く力がつくと、駅伝や11月駅伝予選の選手ごとの結果に、能力ごとのタイム補正値も出ます。',
    '・補正の秒数は、マイナスがタイム良化、プラスがタイム悪化です。',
  ]);
}

/// 大会と人数
ShiyouSetsu shiyouTaikai({bool setsumeisho = false}) {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  final List<String> gyou = [];
  if (gh != null) {
    for (final int race in [0, 1, 2]) {
      if (gh.kukansuu_taikaigoto.length <= race) continue;
      final int k = gh.kukansuu_taikaigoto[race];
      final String mei = race == 0
          ? '10月駅伝'
          : (race == 1 ? '11月駅伝' : '正月駅伝');
      final String oufuku = (race == 2 && k == 10) ? '(1〜5区が往路、6〜10区が復路)' : '';
      gyou.add('・$mei: 全$k区$oufuku。一次エントリーは${_ichijiEntrySuu(k)}人です。');
    }
  }
  gyou.addAll([
    '・11月駅伝予選: 組ごとに1万mを走り、全組の合計タイムで争います。',
    '・正月駅伝予選: 完全にフラットなコースのハーフマラソンを全員で走り、各大学の上位10人のタイムの合計で争います(エントリー12人)。',
    '・一次エントリーで選んだ選手の中から、区間エントリーで各区間に1人ずつ配置します。残りは補欠になります。',
    '・当日変更: スタート前に、区間を走る予定の選手を補欠と入れ替えられます。',
    '・当日変更の最大人数は、全6区以下の駅伝は2人、全8区以下は3人、それより多い駅伝は6人です。',
    '・正月駅伝の当日変更は、往路のスタート前と復路のスタート前に、それぞれ最大4人です。',
    '・入れ替えで外れた選手は、その大会では走れません。',
  ]);
  return ShiyouSetsu('大会と人数', gyou);
}

/// 選手の能力(どの場面で効くか)
ShiyouSetsu shiyouNouryoku({bool setsumeisho = false}) {
  final KantokuData? kantoku = _kantoku();
  final List<String> gyou = [
    '・基本走力: 走力の基本となる能力で、すべてのタイムのもとになります。春と夏の2回成長します。',
    '・基本走力は、選手の能力を見抜く力がついても見えず、金銀も使えません。',
    ..._chousiGyou(kantoku, setsumeisho),
    '・安定感: 調子を決めるときの最低保証値です(当日の突発的な体調不良を除く)。',
    '・駅伝男: スタート直後の飛び出しと前半突っ込みの指示の成功確率に直結します。',
    '・駅伝男は、値が低い選手が多くなるように調整しています。',
    '・平常心: 前半抑えの指示の成功確率に直結します。',
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoNebariIndex, '長距離粘り', [
      '・長距離粘り: 長い距離で効きます。15km以上の距離から影響が出ます。',
    ]),
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoSpurtIndex, 'スパート力', [
      '・スパート力: フィニッシュ直前の走力です。高いと短い距離の方が得意になる傾向があります。',
    ]),
    '・カリスマ: 駅伝の1区と11月駅伝予選の全組で、走る選手の中で一番高い選手がペースメーカーになり、集団のペースを作ります。',
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoNoboriIndex, '登り適性', [
      '・登り適性: 登り坂の走力です。コース情報の登り指数が大きい区間で効きます。登り1万・クロカン1万の持ちタイムにも関係します。',
    ]),
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoKudariIndex, '下り適性', [
      '・下り適性: 下り坂の走力です。コース情報の下り指数が大きい区間で効きます。下り1万・クロカン1万の持ちタイムにも関係します。',
    ]),
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoUpdownIndex, 'アップダウン対応力', [
      '・アップダウン対応力: アップダウンの多い道の走力です。コース情報のアップダウン回数が多い区間で効きます。クロカン1万の持ちタイムにも関係します。',
    ]),
    '・登り適性・下り適性・アップダウン対応力は、互いに無関係に値を決めています(クロカンが強くても、登りが強いとは限りません)。',
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoRoadIndex, 'ロード適性', [
      '・ロード適性: 駅伝の4区以降でよく効き、2区と3区では少し効きます。1区では効きません。',
      '・ロード適性は、正月駅伝予選でも少し効きます。ハーフ・ロード1万の持ちタイムにも関係します。',
    ]),
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoPaceIndex, 'ペース変動対応力', [
      '・ペース変動対応力: 駅伝の1区と11月駅伝予選でよく効きます。駅伝の2区と3区、正月駅伝予選では少し効き、駅伝の4区以降では効きません。',
      '・ペース変動対応力は、5千・1万(トラック)の持ちタイムに関係し、クロカン1万にも少し関係します。',
    ]),
    '・駅伝男からペース変動対応力までの能力は、金銀を使った特訓をしない限り、入学から卒業まで変わりません。',
    setsumeisho
        ? '・選手ごとの練習メニュー(年間強化練習)と、大学画面の「大学の個性(実力発揮度)設定」によって、レースでの能力の効き方が変わります。'
        : '・選手ごとの練習メニュー(年間強化練習)と、大学の個性(実力発揮度)によって、レースでの能力の効き方が変わります。',
  ];
  if (setsumeisho) {
    gyou.addAll([
      '・次の7つの能力が駅伝と駅伝予選のタイムにどのくらい効くかは、設定タブの「能力のタイムへの影響度設定」で変えられます(全大学共通)。',
      '　・長距離粘り・スパート力・登り適性・下り適性・アップダウン対応力・ロード適性・ペース変動対応力',
      '・この設定は、記録会などのタイムには関係しません。',
    ]);
  }
  return ShiyouSetsu('選手の能力(どの場面で効くか)', gyou);
}

/// 持ちタイムの種目
ShiyouSetsu shiyouMochiTime({bool setsumeisho = false}) {
  return const ShiyouSetsu('持ちタイムの種目', [
    '・持ちタイムは、記録会や大会での自己ベストです。種目ごとに効く能力が違います。',
    '・5千・1万: トラックのレースです。ペース変動対応力がよく効きます。',
    '・ハーフ: ロードのハーフマラソン(市民ハーフ・対校戦ハーフ)です。ロード適性がよく効き、15km以上なので長距離粘りも効きます。',
    '・ロード1万はロード適性、登り1万は登り適性、下り1万は下り適性が効きます。',
    '・クロカン1万: 登り適性・下り適性・アップダウン対応力が効き、ペース変動対応力も少し効きます。',
  ]);
}

/// 経験補正
ShiyouSetsu shiyouKeiken({bool setsumeisho = false}) {
  return const ShiyouSetsu('経験補正', [
    '・同じ駅伝の同じ区間を過去に走ったことがあると、経験からタイムが少し良くなります。',
    '・走った回数が多いほど良くなります。',
  ]);
}

/// 駅伝の1区(集団走)
ShiyouSetsu shiyouIchiku({bool setsumeisho = false}) {
  return const ShiyouSetsu('駅伝の1区(集団走)', [
    '・駅伝の1区は集団で走り、集団のペースはカリスマが一番高い選手が作ります。',
    '・集団のペースが自分の本来のペースより遅いとタイム損、少し速いとタイム得になります。',
    '・速すぎると無理して付いていき、後半に大失速して大きくタイム損をすることがあります。',
  ]);
}

/// チームの目標順位
ShiyouSetsu shiyouMokuhyou({bool setsumeisho = false}) {
  final KantokuData? kantoku = _kantoku();
  // 0%(仕組みがない)かどうか。設定がないときは初期値(100%)とみなす
  bool nashi(int index) =>
      kantoku != null && hoseiTsuyosaPercent(kantoku, index) == 0;
  final String kd = _konoData(setsumeisho);
  final List<String> gyou = [
    '・駅伝の目標順位は総監督(${_anata(setsumeisho)})が決めます。',
    '・対校戦は常に8位、11月駅伝予選は常に7位、正月駅伝予選は常に10位が目標順位です。',
    '・正月駅伝では、復路のスタート前に目標順位を決め直せます。',
    '・目標順位を達成すると金銀がもらえ、総監督の能力が覚醒して、選手の能力を見抜く力がつくことがあります。',
    '・目標順位が高いほど、達成したときにもらえる金銀は多くなります。',
  ];
  if (nashi(hoseiTsuyosaShitamawariIndex)) {
    gyou.add('・$kd、目標順位を下回った順位で襷を受けても、タイムは悪化しません。');
  } else {
    gyou.addAll([
      '・駅伝の2区以降で、目標順位を下回った順位で襷を受けると、前半無理に突っ込んでタイムが悪化します。',
      '・悪化の大きさは、下回った順位の数ではなく、襷を受けた時点の目標順位の大学とのタイム差で決まります。',
      '・タイム差が大きいほど悪化も大きく、これから走る区間の距離1kmあたり3秒以上の差で最大になります(例: 20kmの区間なら60秒差以上)。',
    ]);
  }
  if (nashi(hoseiTsuyosaHitoikiIndex)) {
    gyou.add('・$kd、目標順位を上回った順位で襷を受けても、タイムは悪化しません(ほっと一息はありません)。');
  } else {
    gyou.add(
      '・目標順位を上回った順位で襷を受けると、ほっと一息ついてタイムが少しだけ悪化します。上回っている順位の数が多いほど、少し大きくなります。',
    );
  }
  gyou.addAll([
    '・判定は、その選手が襷を受けた時点(前の区間が終わった時点)の通過順位で行います。',
    '・1区と、正月駅伝の6区は判定しません。目標順位ちょうどで襷を受けたときは悪化しません。',
    '・前半突っ込み・前半抑えの指示を出した選手には、この悪化はかからず、代わりに指示の成否による補正がかかります。',
    '・コンピュータの大学にも目標順位があり、同じ仕組みがかかります。',
    '・目標順位が低いほど、駅伝の結果順位で得られる名声は小さくなります。',
    '　・目標1位のときを100とすると、目標2位は50、目標3位は33のように、目標順位で割った量になります。',
    '・区間賞で得られる名声は、目標順位と関係ありません。',
  ]);
  if (setsumeisho) {
    gyou.add(
      '・目標順位を下回ったときの悪化とほっと一息の強さは、設定タブの「目標順位・指示の補正設定」で変えたり、なくしたりできます(全大学共通)。',
    );
  }
  return ShiyouSetsu('チームの目標順位', gyou);
}

/// レース中の指示
ShiyouSetsu shiyouSiji({bool setsumeisho = false}) {
  final KantokuData? kantoku = _kantoku();
  bool nashi(int index) =>
      kantoku != null && hoseiTsuyosaPercent(kantoku, index) == 0;
  final bool seikouNashi = nashi(hoseiTsuyosaSeikouIndex);
  final bool shippaiNashi = nashi(hoseiTsuyosaShippaiIndex);
  final String kd = _konoData(setsumeisho);
  final List<String> gyou = [
    '・駅伝と11月駅伝予選では、選手が走り出す直前に指示を出せます。',
    '・駅伝の1区と11月駅伝予選では「スタート直後飛び出し」を指示できます(成功確率は駅伝男)。',
    '・飛び出しに成功するとタイムが良くなり、失敗すると悪くなります。',
    '・駅伝の2区以降では「前半突っ込み」か「前半抑え」を指示できます。調子は指示の成否に関係しません。',
  ];
  if (seikouNashi && shippaiNashi) {
    gyou.add('・$kd、前半突っ込み・前半抑えは、成功してもタイムは良くならず、失敗しても悪くなりません。');
  } else {
    gyou.add(
      '・前半突っ込み(成功確率は駅伝男): 前半抑えより効果が大きいですが、失敗したときのタイム損も大きくなります。'
      '${seikouNashi ? 'ただし、$kd成功してもタイムは良くなりません。' : ''}'
      '${shippaiNashi ? 'ただし、$kd失敗してもタイムは悪くなりません。' : ''}',
    );
  }
  gyou.add('・前半抑え(成功確率は平常心): 目標順位を下回ったときの悪化や、ほっと一息を防ぐための指示です。');
  gyou.add(
    seikouNashi
        ? '・前半抑えに成功すると、これらの悪化がなくなります($kd、それ以上タイムは良くなりません)。'
        : '・前半抑えに成功すると、これらの悪化がなくなり、少しタイムが良くなります。',
  );
  if (shippaiNashi) {
    gyou.add('・$kd、前半抑えに失敗してもタイムは悪くなりません。');
  } else {
    gyou.add('・前半抑えに失敗すると、指示を出さなかった場合よりタイムが悪くなります。');
    gyou.add('・目標順位を下回って襷を受けたときは、目標順位の大学とのタイム差が大きいほど、前半抑えの失敗の損も大きくなります。');
    if (setsumeisho) {
      gyou.add('　・初期設定では、最大でも前半突っ込みに失敗したときより小さくなります。');
    }
  }
  if (setsumeisho) {
    gyou.addAll([
      '・駅伝の2区以降では、指示を選ぶ欄の下の「指示ごとの損得予測」で、指示ごとに成功・失敗したときの損得の見込みを確かめられます。',
      '・前半突っ込み・前半抑えの効果や損の強さは、設定タブの「目標順位・指示の補正設定」で変えられます(全大学共通)。',
      '　・コンピュータの大学がどの選手に指示を出すかは変わりません。',
    ]);
  }
  gyou.addAll([
    '・正月駅伝予選では、選手ごとにフリー走か集団走を選べます。',
    '・フリー走では、前半突っ込みか前半抑えも指示できます。',
    '・集団走では最大6つの集団を作れ、集団ごとに設定タイムを指示します。',
    '・コンピュータの大学も、駅伝男や平常心の高い選手には指示を出すことがあります。',
  ]);
  return ShiyouSetsu('レース中の指示', gyou);
}

/// 金と銀
ShiyouSetsu shiyouKinGin({bool setsumeisho = false}) {
  final List<String> gyou = [
    '・金銀は、夏合宿で選手の能力を伸ばす金特訓・銀特訓に使います。',
    '・春の定期支給と、チームの目標順位を達成したときの支給があります。',
    '・春の定期支給の額は、次の成績で決まります(上ほど多い)。',
    '　・三冠',
    '　・駅伝か対校戦で優勝',
    '　・駅伝すべてで3位以内',
    '　・駅伝か対校戦のどれかで3位以内',
    '　・対校戦8位以内、10月駅伝5位以内、11月駅伝8位以内、正月駅伝10位以内のどれか',
    '　・11月駅伝予選突破か正月駅伝予選突破',
    '　・上のどれも達成していない(最低額)',
    '・コンピュータの大学も金銀を獲得し、夏合宿で選手の能力強化に使います。',
  ];
  if (setsumeisho) {
    gyou.add('・コンピュータの大学の金銀の使い方は、大学画面の「コンピュータ金銀使用」で設定できます。');
  }
  return ShiyouSetsu('金と銀', gyou);
}

/// 名声
ShiyouSetsu shiyouMeisei({bool setsumeisho = false}) {
  final List<String> gyou = [
    '・各大学は、過去10年の成績から決まる名声を持っています。',
    '・名声が高いほど、有力な新入生が入学しやすくなります。',
    '・コンピュータスカウトがONのときは、名声は新入生スカウトの次のことにも影響します。',
    '　・交渉の成功率',
    '　・同じ選手に複数の大学が交渉に成功したときの抽選',
    '　・交渉で決まらなかった選手が、自ら志望して進学先を選ぶときの選ばれやすさ',
    '・目標順位と名声の関係は、「チームの目標順位」に書いています。',
  ];
  if (setsumeisho) {
    gyou.addAll([
      '・コンピュータスカウトの詳しいことは、大学画面の「コンピュータスカウト」の説明をご覧ください。',
      '・各大会で得られる名声の初期値は、下の参考資料の表をご覧ください。',
    ]);
  }
  return ShiyouSetsu('名声', gyou);
}

/// 学連選抜(正月駅伝)
ShiyouSetsu shiyouGakuren({bool setsumeisho = false}) {
  final String anata = _anata(setsumeisho);
  final List<String> gyou = [
    '・正月駅伝に出られなかった大学から1人ずつ選ばれた、10人のチームです(補欠なし)。',
    '・オープン参加なので、順位は大学の中に入れた場合の「○位相当」(OP)で表します。',
    '・学連選抜の選手は体調不良になりません。',
    '・1区の集団のペースは大学の選手だけで決まり、学連選抜の選手が集団のペースを作ることはありません。',
    '・$anataの大学が正月駅伝に出られない年は、$anataが学連選抜の監督として、区間配置・目標順位・レース中の指示を決めます。',
    '・監督をするかどうかは、学連選抜編成の画面の「学連選抜の監督をする」で切り替えられます(初期値はオン)。',
    '・学連選抜の目標順位は毎年10位から始まります。学連選抜編成の画面と、正月駅伝の6区のスタート前に決め直せます。',
    '・目標順位を下回ったときの悪化とほっと一息は、大学と同じです。',
    '・学連選抜には金銀や名声はないので、実力に見合った目標を選ぶのがおすすめです。',
    '・コンピュータが監督のときの学連選抜は、目標がいつも10位で、ほっと一息はありません。',
    '・コンピュータが監督の学連選抜の選手には、指示は出ません(1区で飛び出すことはあります)。',
  ];
  final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
  if (album != null && album.yobiint4 > 0) {
    gyou.add('・${_konoData(setsumeisho)}、学連選抜の選手は2区以降、モチベーションの低下で少しタイムが悪くなります。');
  }
  return ShiyouSetsu('学連選抜(正月駅伝)', gyou);
}

// 一次エントリーの人数(区間数が6以下なら8人、8以下なら13人、それより多いと16人。
// 一次エントリーの画面(mode0150_content.dart)と同じ決まり)
int _ichijiEntrySuu(int kukansuu) {
  if (kukansuu <= 6) return 8;
  if (kukansuu <= 8) return 13;
  return 16;
}

// 調子の説明(調子のタイムへの影響度が0%のときは、効かないことを書く)
List<String> _chousiGyou(KantokuData? kantoku, bool setsumeisho) {
  final List<String> gyou = [];
  if (kantoku != null &&
      kantoku.yobiint2.length > 2 &&
      kantoku.yobiint2[2] == 0) {
    gyou.add('・調子: ${_konoData(setsumeisho)}、調子(体調不良も含む)はタイムに影響しません。');
  } else {
    gyou.addAll([
      '・調子: 駅伝(駅伝予選は除く)で効きます。100が最高で、低いほどタイムが悪くなります。0は体調不良で、タイムが大きく悪くなります。',
      '・調子は区間エントリーのときに決まり、当日に体調不良になったり持ち直したりすることがあります。',
      '・調子は駅伝男と平常心には影響しないので、指示の成否には関係しません。',
      '・コース編集画面の試走と、コンピュータが区間配置を決めるときのタイムの見積もりには、調子は入っていません。',
    ]);
  }
  if (setsumeisho) {
    gyou.add('・調子のタイムへの影響度などは、設定タブの「調子関連設定」で変えられます。');
  }
  return gyou;
}

// 能力の説明(能力のタイムへの影響度が0%のときは、駅伝と駅伝予選のタイムに効かないことを書く)
List<String> _nouryokuGyou(
  KantokuData? kantoku,
  bool setsumeisho,
  int index,
  String namae,
  List<String> setsumei,
) {
  if (kantoku != null && nouryokuEikyodoPercent(kantoku, index) == 0) {
    return [
      '・$namae: ${_konoData(setsumeisho)}、駅伝と駅伝予選のタイムに影響しません(記録会などの持ちタイムには影響しています)。',
    ];
  }
  return setsumei;
}
