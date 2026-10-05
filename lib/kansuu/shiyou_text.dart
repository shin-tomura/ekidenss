import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // カスタム駅伝の名前(courseRaceTitle)
import 'package:ekiden/kansuu/gakuren_kantoku.dart'; // 学連選抜の報酬がもらえる目標順位(1.8.4)
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
// ・計算式や内部の係数は書かない。仕組みそのものがなくなる・減る設定のときだけ、その部分の文を書き換える
//   (能力のタイムへの影響度・目標順位と指示の補正設定・調子のタイムへの影響度が0%、
//    年間強化練習の効果が0、難易度モードの「極」「天」、コンピュータの大学の金銀使用がオフ。1.8.4で後ろの3つを足した)。
//   学連選抜モチベーション低下補正は、初期値が「補正なし」なので、補正をかけているときだけ文を足す。
// ・獲得名声は、このデータでの量(倍率を掛けた量)を一覧で書く(目標順位相談セットの金銀と同じ考え方。1.8.4)。
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
  // 一般的な育成ゲームの感覚で「基本走力を鍛える」などと答えないように(1.8.4)
  sb.writeln(
    '総監督(プレイヤー)ができることは、エントリー・区間配置・目標順位・レース中の指示・新入生スカウト・年間強化練習の選択・夏合宿の金特訓と銀特訓などに限られます。選手の基本走力は自動で成長します。',
  );
  sb.writeln('設定で変わる部分は、このデータの今の設定に合わせて書いています。');
  sb.writeln('');
  for (final ShiyouSetsu setsu in [
    shiyouSuuchi(),
    shiyouTaikai(),
    shiyouNouryoku(),
    shiyouMochiTime(),
    shiyouKeiken(),
    shiyouShuudansou(),
    shiyouMokuhyou(),
    shiyouSiji(),
    shiyouIkusei(),
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
    '　・例: 「指示(前半抑え)補正:+19.3秒」は、前半抑えの指示が失敗して19.3秒遅くなったことを表します。',
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
    ..._yosen11Gyou,
    ..._yosenShougatsuGyou,
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
    '・基本走力は、選手の能力を見抜く力がついても見えません。金銀の特訓でも上げられません。',
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
    // 一番高い選手が複数いるとき(説明書だけ。生成AI向けでは集団走の見出しにあるので重ねない。1.8.4)
    if (setsumeisho) _karisumaDouchiGyou,
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
      '・ロード適性: 駅伝の4区以降でよく効きます。1区では効きません。',
      '・ロード適性は、ハーフ・ロード1万の持ちタイムにも関係します。',
    ]),
    ..._nouryokuGyou(kantoku, setsumeisho, nouryokuEikyodoPaceIndex, 'ペース変動対応力', [
      '・ペース変動対応力: 駅伝の1区と11月駅伝予選でよく効きます。駅伝の4区以降では効きません。',
      '・ペース変動対応力は、5千・1万(トラック)の持ちタイムに関係し、クロカン1万にも少し関係します。',
    ]),
    ..._roadPaceRyouhouGyou(kantoku),
    // 「金銀を使えない」「能力値は不動」と読み違えないように書く(1.8.4)
    _nanidoMode(kantoku) == 2
        ? '・駅伝男からペース変動対応力までの能力は自然には変わりません。${_konoData(setsumeisho)}、金銀が支給されないので、入学から卒業まで変わりません。'
        : '・駅伝男からペース変動対応力までの能力は自然には変わりませんが、夏合宿の金特訓・銀特訓で上げられます。',
    _kouseiGyou(kantoku, setsumeisho),
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
    _keikenYosenGyou,
  ]);
}

/// 集団走(駅伝の1区と11月駅伝予選。1.8.4で11月駅伝予選のことを書き足した)
ShiyouSetsu shiyouShuudansou({bool setsumeisho = false}) {
  return const ShiyouSetsu('集団走(駅伝の1区と11月駅伝予選)', [
    '・駅伝の1区と、11月駅伝予選の各組は、全大学の選手が1つの集団で走ります。',
    '・集団のペースは、その区間(組)を走る選手の中で、カリスマが一番高い選手が作ります。',
    _karisumaDouchiGyou,
    '・集団のペースが自分の本来のペースより遅いとタイム損、少し速いとタイム得になります。',
    '・集団のペースが自分の本来のペースよりも速すぎると、後半に大失速して大きくタイム損をすることがあります。',
    '・コンピュータの大学は、11月駅伝予選で、1万mの持ちタイムが速い順に2人ずつ、4組・3組・1組・2組に配置します。',
    '　・速い選手が集まる4組は集団のペースが速くなりやすく、遅い選手を入れると大失速するおそれがあります。',
    '　・逆に、速い選手を遅い選手の多い組に入れると、ペースが遅くてタイム損をすることがあります。',
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
    // 難易度モードの「極」「天」では、目標順位を達成しても金銀はもらえない(1.8.4)
    if (_nanidoMode(kantoku) == 0) ...[
      '・目標順位を達成すると金銀がもらえ、総監督の能力が覚醒して、選手の能力を見抜く力がつくことがあります。',
      '・目標順位が高いほど、達成したときにもらえる金銀は多くなります。',
    ] else ...[
      '・目標順位を達成すると、総監督の能力が覚醒して、選手の能力を見抜く力がつくことがあります。',
      '・$kd、目標順位を達成しても金銀はもらえません。',
    ],
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
      '　・その画面の「この指示にする」で、指示を選ぶこともできます。',
      '・前半突っ込み・前半抑えの効果や損の強さは、設定タブの「目標順位・指示の補正設定」で変えられます(全大学共通)。',
      '　・コンピュータの大学がどの選手に指示を出すかは変わりません。',
    ]);
  }
  gyou.addAll([
    ..._shougatsuYosenSijiGyou,
    // 「おまかせで組む」(説明書だけ。1.8.8。組み方は yosen_omakase.dart)
    if (setsumeisho) ...[
      '・正月駅伝予選のレース画面の「おまかせで組む」で、指示と設定タイムをまとめて入れられます(入れたあとに直してから確定できます)。',
      '　・試走タイムの近い選手どうしで集団を作り、駅伝男が90以上の選手は前半突っ込みにします。',
    ],
    '・コンピュータの大学も、駅伝男や平常心の高い選手には指示を出すことがあります。',
  ]);
  return ShiyouSetsu('レース中の指示', gyou);
}

/// 育成(年間強化練習と金銀)
/// 1.8.3までの「金と銀」を広げた(1.8.4)。基本走力は直接上げられないこと、
/// 年間強化練習は見た目の能力値を変えないこと、金特訓・銀特訓で上がる能力を書く
ShiyouSetsu shiyouIkusei({bool setsumeisho = false}) {
  final KantokuData? kantoku = _kantoku();
  final String kd = _konoData(setsumeisho);
  final int mode = _nanidoMode(kantoku);
  final List<String> gyou = [
    '・基本走力は、春と夏の2回、自動で成長します。総監督が直接上げる方法はありません。',
    // 1.8.5で、入学時5000mの記録で基本走力の上限が決まるようにした(joukai.dart)
    // (1.8.8からの隠れた逸材はサプライズなので書かない。上限が入学時の記録だけで決まるとは言い切らず「傾向」のままにする)
    '・入学時の5000mの記録が良い選手ほど、基本走力が最終的に高くなりやすい傾向があります。',
    // 限界突破(Ikusei_Com.dart)。急に伸びた選手を説明できるように書く。回数や大きさの数字は書かない(1.8.8)
    '・伸び悩んでいるように見える選手も、限界突破で再び伸びることがあります。',
  ];
  // 年間強化練習(効果が0のときは、効果がないことを書く)
  if (_kyoukaKyoudo(kantoku) == 0) {
    gyou.add('・年間強化練習: 選手ごとに1年間の練習メニューを決めます。$kd、年間強化練習の効果はありません。');
  } else {
    gyou.addAll([
      '・年間強化練習: 選手ごとに1年間の練習メニューを決めます。見た目の能力値は変わらず、レースのときだけ、メニューに対応する能力に上乗せされます。',
      '　・メニュー: バランス(全体に平均的)・スピード(スパート力とペース変動対応力)・距離走(長距離粘りとロード適性)・登り・下り・アップダウン',
      '　・上乗せが表れるのは、その能力が効く区間・種目だけです(例: 登りのメニューは、登りの多い区間でだけ効きます)。',
    ]);
  }
  // 全員を同じメニューにするボタン(説明書だけ。1.8.8)
  if (setsumeisho) {
    gyou.add('　・年間強化メニュー決定の画面の「全員を同じメニューにする」で、全選手のメニューをまとめて決めることもできます。');
  }
  // 金特訓・銀特訓(画面に出ている決まり)
  gyou.addAll([
    '・夏合宿の金特訓・銀特訓: 金銀を10使うごとに、能力値が10上がります(90以上になった能力は、それ以上上げられません。カリスマは除く)。',
    '　・金特訓: 駅伝男・平常心・安定感',
    '　・銀特訓: 長距離粘り・スパート力・カリスマ・登り適性・下り適性・アップダウン対応力・ロード適性・ペース変動対応力',
  ]);
  // 金銀の支給(難易度モードの「極」は春の定期支給だけ、「天」は支給なし)
  if (mode == 2) {
    gyou.add('・$kd、金銀は支給されないので、金特訓・銀特訓はできません。');
  } else {
    // 「極」の文に「春の定期支給だけ」とは書かない
    // (大学当局の温情の支給は「極」でもあり、サプライズなので説明書・仕様には書かない。1.8.4)
    gyou.add(
      mode == 1
          ? '・$kd、目標順位を達成しても金銀はもらえません(春の定期支給はあります)。'
          : '・金銀は、春の定期支給と、チームの目標順位を達成したときにもらえます。',
    );
    if (mode == 0) {
      gyou.add(
        '　・学連選抜の監督として、目標を${gakurenHoushuuMokuhyouSaikai + 1}位以内にして達成したときも、予選突破と同じ量をもらえます。',
      );
    }
    gyou.addAll([
      '・春の定期支給の額は、次の成績で決まります(上ほど多い)。',
      '　・三冠',
      '　・駅伝か対校戦で優勝',
      '　・駅伝すべてで3位以内',
      '　・駅伝か対校戦のどれかで3位以内',
      '　・対校戦8位以内、10月駅伝5位以内、11月駅伝8位以内、正月駅伝10位以内のどれか',
      '　・11月駅伝予選突破か正月駅伝予選突破',
      '　・上のどれも達成していない(最低額)',
    ]);
  }
  // コンピュータの大学の金銀使用(オフのときは使わない)
  gyou.add(
    _comKinginOff(kantoku)
        ? '・$kd、コンピュータの大学は金銀を使いません。'
        : '・コンピュータの大学も金銀を獲得し、夏合宿で選手の能力強化に使います。',
  );
  if (setsumeisho) {
    gyou.addAll([
      '・金銀の支給量は、大学画面の「難易度変更」「難易度「極」「天」設定」と、設定タブの「金銀支給量倍率設定」で変えられます。',
      '・年間強化練習の効果の大きさは、設定タブの「年間強化練習効果設定」で変えられます。',
      '・コンピュータの大学の金銀の使い方は、大学画面の「コンピュータ金銀使用」で設定できます。',
    ]);
  }
  return ShiyouSetsu('育成(年間強化練習と金銀)', gyou);
}

/// 名声
ShiyouSetsu shiyouMeisei({bool setsumeisho = false}) {
  final List<String> gyou = [
    '・各大学の名声は、過去10年に得た名声の合計です。',
    '・名声が高いほど、有力な新入生が入学しやすくなります。',
    '・コンピュータスカウトがONのときは、名声は新入生スカウトの次のことにも影響します。',
    '　・交渉の成功率',
    '　・同じ選手に複数の大学が交渉に成功したときの抽選',
    '　・交渉で決まらなかった選手が、自ら志望して進学先を選ぶときの選ばれやすさ',
    ..._kakutokuMeiseiGyou(setsumeisho),
    '・目標順位と名声の関係は、「チームの目標順位」に書いています。',
  ];
  if (setsumeisho) {
    gyou.addAll([
      '・駅伝で得られる名声の倍率は、大学画面の「駅伝名声設定」で変えられます(カスタム駅伝は、設定タブの「カスタム駅伝設定」)。',
      '・コンピュータスカウトの詳しいことは、大学画面の「コンピュータスカウト」の説明をご覧ください。',
      // 名声の履歴(1.8.8。Modal_meiseiRireki.dart)
      '・大学画面の「全大学名声一覧」で大学をタップすると、過去10年の名声の内訳を見られます。',
      '・下の参考資料の表は、倍率を変えていないとき(初期値)の量です。',
    ]);
  }
  return ShiyouSetsu('名声', gyou);
}

/// 学連選抜(正月駅伝)
ShiyouSetsu shiyouGakuren({bool setsumeisho = false}) {
  final String anata = _anata(setsumeisho);
  final KantokuData? kantoku = _kantoku();
  final bool kinginAri = _nanidoMode(kantoku) == 0;
  // 学連選抜の監督として目標を達成したときに報酬がもらえる、一番下の目標順位(1が1位。1.8.4)
  final int saikai = gakurenHoushuuMokuhyouSaikai + 1;
  final List<String> gyou = [
    '・正月駅伝に出られなかった大学から1人ずつ選ばれた、10人のチームです(補欠なし)。',
    '・オープン参加なので、順位は大学の中に入れた場合の「○位相当」(OP)で表します。',
    '・学連選抜の選手は体調不良になりません。',
    '・1区の集団のペースは大学の選手だけで決まり、学連選抜の選手が集団のペースを作ることはありません。',
    '・$anataの大学が正月駅伝に出られない年は、$anataが学連選抜の監督として、区間配置・目標順位・レース中の指示を決めます。',
    '・監督をするかどうかは、学連選抜編成の画面の「学連選抜の監督をする」で切り替えられます(初期値はオン)。',
    '・学連選抜の目標順位は毎年10位から始まります。学連選抜編成の画面と、正月駅伝の6区のスタート前に決め直せます。',
    '・目標順位を下回ったときの悪化とほっと一息は、大学と同じです。',
    // 目標を10位以内にして達成したときの報酬(1.8.4)
    kinginAri
        ? '・目標を$saikai位以内にして達成すると、予選突破と同じ量の金銀がもらえ、選手の能力を見抜く力がつくことがあります。'
        : '・目標を$saikai位以内にして達成すると、選手の能力を見抜く力がつくことがあります(${_konoData(setsumeisho)}、金銀はもらえません)。',
    '　・1〜${saikai - 1}位にしても${kinginAri ? '金銀' : '報酬'}は増えません。実力に近い目標にすると、ほっと一息のタイム悪化は防げます。',
    // 開き直りの一文は説明書だけ(生成AIが隠れた数値があると思い込まないように)
    if (setsumeisho) '　・1〜${saikai - 1}位を目標にするのは、選手たちの幸福度が上がるという脳内補完でお願いします。',
    '・判定は最後に決めた目標順位で行います。6区のスタート前に$saikai位より下にすると、達成しても報酬はもらえません。',
    // 学連選抜の選手の区間1位相当で、その選手の大学に名声が入る(1.8.8。量は「名声」の一覧に書く)
    // 目標1位で総合1位相当に導いたときの監督の大学の名声(KirokuKousin.dart)はサプライズなので書かない。
    // 「名声は得られません」と言い切らず、「順位ごとの名声はない」と書く(1.8.8)
    '・学連選抜には、大学のような総合の順位ごとの名声はありません。',
    '・学連選抜の選手が区間1位相当で走ると、その選手の大学に名声が入ります。',
    '・コンピュータが監督のときの学連選抜は、目標がいつも10位で、ほっと一息も報酬もありません。',
    '・コンピュータが監督の学連選抜の選手には、指示は出ません(1区で飛び出すことはあります)。',
  ];
  final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
  if (album != null && album.yobiint4 > 0) {
    gyou.add('・${_konoData(setsumeisho)}、学連選抜の選手は2区以降、モチベーションの低下で少しタイムが悪くなります。');
  }
  return ShiyouSetsu('学連選抜(正月駅伝)', gyou);
}

/// 駅伝予選の相談セットの先頭に入れる「この大会の決まり」(1.8.4)
/// メンバーを選ぶ相談で、生成AIが駅伝と同じ決まり(経験補正など)だと思い込まないように入れる。
/// 文は仕様の文と同じもの(11月駅伝予選・正月駅伝予選以外では空)
String yosenKimariText(int race) {
  final List<String> gyou;
  if (race == 3) {
    gyou = [..._yosen11Gyou, ...shiyouShuudansou().gyou, _keikenYosenGyou];
  } else if (race == 4) {
    gyou = [
      ..._yosenShougatsuGyou,
      ..._shougatsuYosenSijiGyou,
      _keikenYosenGyou,
    ];
  } else {
    return '';
  }
  final StringBuffer sb = StringBuffer();
  sb.writeln('【${race == 3 ? '11月駅伝予選' : '正月駅伝予選'} この大会の決まり】');
  for (final String g in gyou) {
    sb.writeln(g);
  }
  return sb.toString();
}

// 11月駅伝予選の決まり(大会と人数と、駅伝予選の決まりで使う)
const List<String> _yosen11Gyou = [
  '・11月駅伝予選: 4組に分かれて1万mを走り、全組の合計タイムで争います。',
  '・11月駅伝予選は、各大学が1組に2人ずつ、合わせて8人が走ります。',
  '・11月駅伝予選では、一次エントリーの8人が全員走るので、補欠はありません。',
];

// 正月駅伝予選の決まり(大会と人数と、駅伝予選の決まりで使う)
const List<String> _yosenShougatsuGyou = [
  '・正月駅伝予選: 完全にフラットなコースのハーフマラソンを全員で走り、各大学の上位10人のタイムの合計で争います(エントリー12人)。',
];

// 正月駅伝予選のフリー走と集団走(レース中の指示と、駅伝予選の決まりで使う。
// 設定タイムの注意は、レース画面の説明と同じ内容)
const List<String> _shougatsuYosenSijiGyou = [
  '・正月駅伝予選では、選手ごとにフリー走か集団走を選べます。',
  '・フリー走では、前半突っ込みか前半抑えも指示できます。',
  '・集団走では最大6つの集団を作れ、集団ごとに設定タイムを指示します。',
  '・設定タイムは、その集団で一番速い選手の試走タイムより速くはできません。',
  '・設定タイムが速すぎると、集団の中で実力が足りない選手が大失速するおそれがあります。',
  '・設定タイムが遅すぎると、実力よりタイムが出ない選手が出ます。',
  '　・実力が飛び抜けた選手や大きく足りない選手は、別の集団にするかフリー走にすると良いかもしれません。',
];

// カリスマが一番高い選手が複数いるとき(集団走と、説明書の選手の能力のカリスマで使う。
// 計算では選手の内部の番号の小さい方になるので、同じ顔ぶれならいつも同じ選手になる)
const String _karisumaDouchiGyou =
    '　・一番高い選手が複数いるときは、そのうちの1人が作ります(同じ顔ぶれなら、いつも同じ選手)。';

// 駅伝予選には経験補正と調子がないこと(経験補正と、駅伝予選の決まりで使う)
const String _keikenYosenGyou =
    '・駅伝予選(11月駅伝予選・正月駅伝予選)には、経験補正はありません。調子も関係しません。';

// 難易度モード(0: 通常、1: 極(春の定期支給だけ)、2: 天(金銀の支給なし))。KantokuData.yobiint2[0]
int _nanidoMode(KantokuData? kantoku) {
  if (kantoku == null || kantoku.yobiint2.isEmpty) return 0;
  final int mode = kantoku.yobiint2[0];
  return (mode == 1 || mode == 2) ? mode : 0;
}

// 年間強化練習の効果の大きさ(0〜5。0は効果なし)。KantokuData.yobiint2[16]
int _kyoukaKyoudo(KantokuData? kantoku) {
  if (kantoku == null || kantoku.yobiint2.length <= 16) return 4;
  return kantoku.yobiint2[16];
}

// コンピュータの大学の金銀使用がオフか(KantokuData.yobiint2[33]。0=オン(初期値)、1=オフ)
bool _comKinginOff(KantokuData? kantoku) =>
    kantoku != null &&
    kantoku.yobiint2.length > 33 &&
    kantoku.yobiint2[33] == 1;

// 練習メニューと大学の個性の行(年間強化練習の効果が0のときは、大学の個性だけ)
String _kouseiGyou(KantokuData? kantoku, bool setsumeisho) {
  final String kosei = setsumeisho
      ? '大学画面の「大学の個性(実力発揮度)設定」'
      : '大学の個性(実力発揮度)';
  if (_kyoukaKyoudo(kantoku) == 0) {
    return '・$koseiによって、レースでの能力の効き方が変わります。';
  }
  return '・選手ごとの練習メニュー(年間強化練習)と、$koseiによって、レースでの能力の効き方が変わります。';
}

// 獲得名声の一覧(このデータでの量。目標順位1位のとき)。1.8.4
// 順位ごとの基本の量と計算は、KirokuKousin.dart の名声加算と同じ
// (駅伝: 基本の量×「駅伝名声設定」の倍率÷目標順位。区間賞: 1位の量×0.2×倍率で、目標順位で割らない。
//  カスタム駅伝: 正月駅伝の量×正月駅伝の倍率×カスタム駅伝の倍率。対校戦は倍率なし・目標順位で割らない。駅伝予選はなし)
const List<int> _meisei10gatsu = [500, 250, 200, 90, 80, 24, 23, 22, 21, 20];
const List<int> _meisei11gatsu = [
  500, 250, 200, 90, 80, 70, 60, 50, 20, 20, 20, 20, 20, 20, 20, //
];
const List<int> _meiseiShougatsu = [
  2000, 1000, 800, 360, 320, 280, 240, 200, 160, 120, //
  50, 50, 50, 50, 50, 50, 50, 50, 50, 50, //
];
const List<int> _meiseiTaikousenSougou = [1000, 500, 400, 180, 160, 140, 120, 100];
const List<int> _meiseiTaikousenKojin = [100, 50, 40, 18, 16, 14, 12, 10];

List<String> _kakutokuMeiseiGyou(bool setsumeisho) {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  final Map<int, UnivData> univ = {
    for (final UnivData u in Hive.box<UnivData>('univBox').values) u.id: u,
  };
  // 「駅伝名声設定」の倍率(分子と分母は1〜10。範囲外は1。KirokuKousin.dart と同じ読み方)
  int yomu(int id) {
    final int? v = int.tryParse(univ[id]?.name_tanshuku ?? '');
    return (v == null || v < 1 || v > 10) ? 1 : v;
  }

  double bairitu(int bunsiId, int bunboId) =>
      yomu(bunsiId).toDouble() / yomu(bunboId).toDouble();
  final double b10 = bairitu(1, 2);
  final double b11 = bairitu(3, 4);
  final double b01 = bairitu(5, 6);

  // 目標順位1位のときの量(KirokuKousin.dart と同じく、小数を切り捨てて最低1)
  int ryou(double r) => r.toInt() < 1 ? 1 : r.toInt();
  List<int> kakeru(List<int> kihon, double b) => [
    for (final int k in kihon) ryou(k.toDouble() * b),
  ];

  final List<String> gyou = [
    '・${_konoData(setsumeisho)}、駅伝の総合順位で得られる名声は次のとおりです(目標順位1位のとき。実際は目標順位で割った量になります)。',
    '　・10月駅伝: ${_juniRetsu(kakeru(_meisei10gatsu, b10))}',
    '　・11月駅伝: ${_juniRetsu(kakeru(_meisei11gatsu, b11))}',
    '　・正月駅伝: ${_juniRetsu(kakeru(_meiseiShougatsu, b01))}',
  ];
  final List<String> kukanshou = [
    '10月駅伝${(500.toDouble() * 0.2 * b10).toInt()}',
    '11月駅伝${(500.toDouble() * 0.2 * b11).toInt()}',
    '正月駅伝${(2000.toDouble() * 0.2 * b01).toInt()}',
  ];
  // カスタム駅伝(開催する設定のときだけ。倍率は「カスタム駅伝設定」の獲得名声倍率)
  if (gh != null &&
      gh.spurtryokuseichousisuu1 == 1 &&
      gh.spurtryokuseichousisuu5 >= 1) {
    final double bc =
        gh.spurtryokuseichousisuu4.toDouble() /
        gh.spurtryokuseichousisuu5.toDouble();
    final String mei = courseRaceTitle(5);
    gyou.add(
      '　・$mei: ${_juniRetsu([for (final int k in _meiseiShougatsu) ryou(b01 * k.toDouble() * bc)])}',
    );
    kukanshou.add('$mei${(0.2 * 2000.toDouble() * b01 * bc).toInt()}');
  }
  gyou.addAll([
    '・区間賞は1区間につき、${kukanshou.join('、')}です(目標順位と関係ありません)。',
    // 学連選抜の選手の区間1位相当(正月駅伝の区間賞の1/4。1.8.8)
    '・学連選抜の選手の区間1位相当は1区間につき${gakurenKukanIchiiMeisei(b01)}で、その選手の大学に入ります。',
    '・対校戦で得られる名声は次のとおりです(目標順位と関係ありません)。',
    '　・総合: ${_juniRetsu(_meiseiTaikousenSougou)}',
    '　・種目(5000m・10000m・ハーフ)ごとの個人: ${_juniRetsu(_meiseiTaikousenKojin)}',
    '・駅伝予選の順位では、名声は得られません。',
  ]);
  return gyou;
}

// 順位ごとの量を「1位500、2位250、…、9〜15位20」の形にする(同じ量が続くところはまとめる)
String _juniRetsu(List<int> ryou) {
  final List<String> list = [];
  int i = 0;
  while (i < ryou.length) {
    int j = i;
    while (j + 1 < ryou.length && ryou[j + 1] == ryou[i]) {
      j++;
    }
    list.add(i == j ? '${i + 1}位${ryou[i]}' : '${i + 1}〜${j + 1}位${ryou[i]}');
    i = j + 1;
  }
  return list.join('、');
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

// 駅伝の2区と3区、正月駅伝予選のロード適性とペース変動対応力(1.8.6)
// どちらも、よく効く区間の半分ずつ効き、合わせると能力1つがよく効く区間と同じ重みになる。
// 「少し効く」だと区間として能力の影響が小さいと読めるので、両方が効くと書く。
// 能力のタイムへの影響度でどちらかを0%にしているときは、残ったほうだけを書く
// (そのときはその区間の能力の影響が実際に小さいので、よく効く区間ほどではないと添える)。
List<String> _roadPaceRyouhouGyou(KantokuData? kantoku) {
  final bool road =
      kantoku == null ||
      nouryokuEikyodoPercent(kantoku, nouryokuEikyodoRoadIndex) != 0;
  final bool pace =
      kantoku == null ||
      nouryokuEikyodoPercent(kantoku, nouryokuEikyodoPaceIndex) != 0;
  if (road && pace) {
    return [
      '・駅伝の2区と3区、正月駅伝予選では、ロード適性とペース変動対応力の両方が効きます(両方が高い選手ほど有利です)。',
    ];
  }
  if (road) {
    return [
      '・ロード適性は、駅伝の2区と3区、正月駅伝予選でも効きます(4区以降ほどではありません)。',
    ];
  }
  if (pace) {
    return [
      '・ペース変動対応力は、駅伝の2区と3区、正月駅伝予選でも効きます(1区ほどではありません)。',
    ];
  }
  return [];
}
