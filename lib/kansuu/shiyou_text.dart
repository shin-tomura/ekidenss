import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart';
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';

// ------------------------------------------------------------
// 生成AIに渡すゲームの仕様のテキスト(1.8.3)
// 「生成AIに渡すテキスト」の「ゲームの仕様(生成AI向け)」と、目標順位相談セットで使う。
// ・説明書画面(setting_screen.dart)と目標順位を決める画面の説明と同じ範囲(公開済みの仕様)だけを、
//   生成AI向けに整理して書く。計算式や内部の係数は書かない。
// ・設定の値は書かない。仕組みそのものがなくなる設定(0%)のときだけ、その部分の文を書き換える
//   (能力のタイムへの影響度、目標順位・指示の補正設定、調子のタイムへの影響度)。
//   学連選抜モチベーション低下補正は、初期値が「補正なし」なので、補正をかけているときだけ文を足す。
// ・説明書の仕様を変えたら、ここも直す(CLAUDE.mdにも書いてある)
// ------------------------------------------------------------

/// ゲームの仕様の全文(生成AIに会話の最初に一度渡す用)
String gameShiyouText() {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  final StringBuffer sb = StringBuffer();
  sb.writeln('【箱庭小駅伝SS ゲームの仕様(生成AI向け)】');
  sb.writeln(
    'このゲームは、大学駅伝の総監督になって、エントリー・区間配置・目標順位・レース中の指示を決めるシミュレーションゲームです。'
    '以下は説明書に書かれている仕様を、相談のためにまとめたものです。計算式の細部はここには書いていないので、'
    'ここにないことを推測で答えるときは、推測であることを伝えてください。',
  );
  sb.writeln('');

  // ■数値の読み方
  sb.writeln('■数値の読み方');
  sb.writeln('・タイムは小さいほど良く、能力値は大きいほど良い。');
  sb.writeln('・基本走力(すべてのタイムのもとになる能力)は見えない。持ちタイム(記録会や大会での自己ベスト)が実力の目安になる。');
  sb.writeln('・能力値の「??」は、総監督に選手の能力を見抜く力がまだなく、見えていない能力。');
  sb.writeln('・補正の秒数は、マイナスがタイム良化、プラスがタイム悪化。');
  sb.writeln('');

  // ■大会と人数
  sb.writeln('■大会と人数');
  if (gh != null) {
    final List<String> ekiden = [];
    for (final int race in [0, 1, 2]) {
      if (gh.kukansuu_taikaigoto.length <= race) continue;
      final int k = gh.kukansuu_taikaigoto[race];
      String mei = race == 0 ? '10月駅伝' : (race == 1 ? '11月駅伝' : '正月駅伝');
      String bun = '$mei(全$k区';
      if (race == 2 && k == 10) bun += '。1〜5区が往路、6〜10区が復路';
      bun += '。一次エントリー${_ichijiEntrySuu(k)}人)';
      ekiden.add(bun);
    }
    if (ekiden.isNotEmpty) sb.writeln('・駅伝: ${ekiden.join('、')}。');
  }
  sb.writeln('・11月駅伝予選: 組ごとに1万mを走り、全組の合計タイムで争う。');
  sb.writeln('・正月駅伝予選: 完全にフラットなコースのハーフマラソンを全員で走り、各大学の上位10名のタイムの合計で争う(エントリー12人)。');
  sb.writeln('・一次エントリーで選んだ選手の中から、区間エントリーで各区間に1人ずつ配置し、残りは補欠になる。');
  sb.writeln(
    '・当日変更: スタート前に、区間を走る予定の選手を補欠と入れ替えられる。最大人数は、全6区以下の駅伝は2人、全8区以下は3人、それより多い駅伝は6人。'
    '正月駅伝は、往路のスタート前と復路のスタート前に、それぞれ最大4人。入れ替えで外れた選手は、その大会では走れない。',
  );
  sb.writeln('');

  // ■選手の能力
  sb.writeln('■選手の能力(どの場面で効くか)');
  sb.writeln(_chousiBun(kantoku));
  sb.writeln('・安定感: 調子の最低保証値(当日の突発的な体調不良を除く)。');
  sb.writeln('・駅伝男: スタート直後の飛び出しと前半突っ込みの指示の成功確率に直結する。値が低い選手が多い。');
  sb.writeln('・平常心: 前半抑えの指示の成功確率に直結する。');
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoNebariIndex,
      '長距離粘り',
      '長い距離で効く能力。15km以上の距離から影響が出る。',
    ),
  );
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoSpurtIndex,
      'スパート力',
      'フィニッシュ直前の走力。高いと短い距離の方が得意になる傾向。',
    ),
  );
  sb.writeln(
    '・カリスマ: 駅伝の1区と11月駅伝予選の全組で、走る選手の中で一番高い選手がペースメーカーになる(集団のペースを作る)。',
  );
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoNoboriIndex,
      '登り適性',
      '登り坂の走力。コース情報の登り指数が大きい区間で効く。登り1万・クロカン1万の持ちタイムにも関係。',
    ),
  );
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoKudariIndex,
      '下り適性',
      '下り坂の走力。コース情報の下り指数が大きい区間で効く。下り1万・クロカン1万の持ちタイムにも関係。',
    ),
  );
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoUpdownIndex,
      'アップダウン対応力',
      'アップダウンの多い道の走力。コース情報のアップダウン回数が多い区間で効く。クロカン1万の持ちタイムにも関係。',
    ),
  );
  sb.writeln('  (登り適性・下り適性・アップダウン対応力は、互いに無関係に決まっている)');
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoRoadIndex,
      'ロード適性',
      '駅伝の4区以降でよく効き、2区と3区では少し効く。1区では効かない。正月駅伝予選では少し効く。ハーフ・ロード1万の持ちタイムにも関係。',
    ),
  );
  sb.writeln(
    _nouryokuBun(
      kantoku,
      nouryokuEikyodoPaceIndex,
      'ペース変動対応力',
      '駅伝の1区と11月駅伝予選でよく効き、駅伝の2区と3区と正月駅伝予選では少し効く。駅伝の4区以降では効かない。5000m・10000m(トラック)の持ちタイムに関係し、クロカン1万にも少し関係。',
    ),
  );
  sb.writeln('・基本走力と調子以外の能力は、金銀を使った特訓をしない限り、入学から卒業まで変わらない。');
  sb.writeln('・選手ごとの練習メニュー(年間強化練習)と、大学の個性(実力発揮度)によって、レースでの能力の効き方が変わる。');
  sb.writeln('');

  // ■持ちタイムの種目
  sb.writeln('■持ちタイムの種目');
  sb.writeln('・5000m・10000m: トラックのレース。ペース変動対応力がよく効く。');
  sb.writeln('・ハーフ: ロードのハーフマラソン。ロード適性がよく効き、15km以上なので長距離粘りも効く。');
  sb.writeln('・ロード1万: ロード適性。登り1万: 登り適性。下り1万: 下り適性。');
  sb.writeln('・クロカン1万: 登り適性・下り適性・アップダウン対応力に関係し、ペース変動対応力も少し関係する。');
  sb.writeln('');

  // ■経験と1区
  sb.writeln('■経験補正と1区');
  sb.writeln('・同じ駅伝の同じ区間を前の学年までに走ったことがあると、経験からタイムが少し良くなる。回数が多いほど良くなる。');
  sb.writeln(
    '・駅伝の1区は集団で走り、集団のペースはカリスマが一番高い選手が作る。集団のペースが自分の本来のペースより遅いとタイム損、'
    '少し速いとタイム得になるが、速すぎると無理して付いていって後半に大失速し、大きくタイム損をすることがある。',
  );
  sb.writeln('');

  // ■目標順位と指示
  sb.write(shiyouMokuhyouSijiText());
  sb.writeln('');

  // ■学連選抜
  sb.writeln('■学連選抜(正月駅伝)');
  sb.writeln(
    '・正月駅伝に出場できなかった大学から1人ずつ選ばれた10人のチーム(補欠なし)。オープン参加で、順位は大学の中に入れた場合の「○位相当」(OP)で表す。',
  );
  sb.writeln('・学連選抜の選手は体調不良にならない。1区の集団のペースは作らない(大学の選手だけで決まる)。');
  sb.writeln(
    '・プレイヤーの大学が正月駅伝に出場できない年は、プレイヤーが学連選抜の監督として、区間配置・目標順位・指示を決められる(目標順位の仕組みは大学と同じ。学連選抜には金銀や名声はない)。'
    'コンピュータが監督のときの学連選抜は、目標がいつも10位で、ほっと一息はない。',
  );
  final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
  if (album != null && album.yobiint4 > 0) {
    sb.writeln('・このデータでは、学連選抜の選手は2区以降、モチベーションの低下で少しタイムが悪くなる。');
  }
  sb.writeln('');
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}

/// 仕様のうち「目標順位」と「レース中の指示」の部分(目標順位相談セットでも使う)
String shiyouMokuhyouSijiText() {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  // 0%(仕組みがない)かどうか。設定がないときは初期値(100%)とみなす
  bool nashi(int index) =>
      kantoku != null && hoseiTsuyosaPercent(kantoku, index) == 0;
  final bool shitamawariNashi = nashi(hoseiTsuyosaShitamawariIndex);
  final bool hitoikiNashi = nashi(hoseiTsuyosaHitoikiIndex);
  final bool seikouNashi = nashi(hoseiTsuyosaSeikouIndex);
  final bool shippaiNashi = nashi(hoseiTsuyosaShippaiIndex);

  final StringBuffer sb = StringBuffer();
  sb.writeln('■目標順位');
  sb.writeln(
    '・駅伝の目標順位は総監督が決める(対校戦は常に8位、11月駅伝予選は常に7位、正月駅伝予選は常に10位)。'
    '正月駅伝では、復路のスタート前に目標順位を決め直せる。',
  );
  if (shitamawariNashi) {
    sb.writeln('・このデータでは、目標順位を下回った順位で襷を受けても、タイムは悪化しない。');
  } else {
    sb.writeln(
      '・駅伝の2区以降で、目標順位を下回った順位で襷を受けると、前半無理に突っ込んでタイムが悪化する。'
      '悪化の大きさは、下回った順位の数ではなく、襷を受けた時点の目標順位の大学とのタイム差で決まり、'
      '差が大きいほど大きく、これから走る区間の距離1kmあたり3秒以上の差で最大になる(例: 20kmの区間なら60秒差以上)。',
    );
  }
  if (hitoikiNashi) {
    sb.writeln('・このデータでは、目標順位を上回った順位で襷を受けても、タイムは悪化しない(ほっと一息はない)。');
  } else {
    sb.writeln('・目標順位を上回った順位で襷を受けると、ほっと一息ついてタイムが少しだけ悪化する(上回っている順位の数が多いほど少し大きくなる)。');
  }
  sb.writeln(
    '・判定は、その選手が襷を受けた時点(前の区間が終わった時点)の通過順位(総合順位)で行う。'
    '1区と、正月駅伝の6区は判定しない。目標順位ちょうどで襷を受けたときは悪化しない。',
  );
  sb.writeln('・前半突っ込み・前半抑えの指示を出した選手には、この悪化はかからず、代わりに指示の成否による補正がかかる。');
  sb.writeln('・コンピュータの大学にも目標順位があり、同じ仕組みがかかる。');
  sb.writeln(
    '・目標順位を達成すると、金銀(夏合宿で選手の能力を伸ばす特訓に使う)がもらえ、総監督が選手の能力を見抜く力がつくことがある。'
    '目標順位が高いほど、達成したときにもらえる金銀は多い。',
  );
  sb.writeln(
    '・目標順位が低いほど、駅伝の結果順位で得られる名声は小さくなる(目標1位のときを100とすると、目標2位は50、目標3位は33のように、目標順位で割った量になる)。'
    '区間賞で得られる名声は目標順位と関係ない。名声が高いほど、有力な新入生が入学しやすい。',
  );
  sb.writeln('');
  sb.writeln('■レース中の指示');
  sb.writeln(
    '・駅伝の1区と11月駅伝予選では「スタート直後飛び出し」を指示できる(成功確率は駅伝男)。成功するとタイムが良くなり、失敗すると悪くなる。',
  );
  sb.writeln('・駅伝の2区以降では「前半突っ込み」か「前半抑え」を指示できる。調子は指示の成否に関係しない。');
  if (seikouNashi && shippaiNashi) {
    sb.writeln('・このデータでは、前半突っ込み・前半抑えは、成功してもタイムは良くならず、失敗しても悪くならない。');
  } else {
    sb.writeln(
      '・前半突っ込み(成功確率は駅伝男): 前半抑えより効果が大きいが、失敗したときのタイム損も大きい。'
      '${seikouNashi ? 'ただし、このデータでは成功してもタイムは良くならない。' : ''}'
      '${shippaiNashi ? 'ただし、このデータでは失敗してもタイムは悪くならない。' : ''}',
    );
  }
  sb.writeln(
    '・前半抑え(成功確率は平常心): 目標順位を下回ったときの悪化や、ほっと一息を防ぐための指示。'
    '${seikouNashi ? '成功するとこれらの悪化がなくなる(このデータでは、それ以上タイムは良くならない)。' : '成功するとこれらの悪化がなくなり、少しタイムが良くなる。'}'
    '${shippaiNashi ? 'このデータでは、失敗してもタイムは悪くならない。' : '失敗すると指示を出さなかった場合よりタイムが悪くなる(目標順位を下回って襷を受けたときは、目標順位の大学とのタイム差が大きいほど失敗の損も大きい)。'}',
  );
  sb.writeln('・コンピュータの大学も、駅伝男や平常心の高い選手には指示を出すことがある。');
  return sb.toString();
}

// 一次エントリーの人数(区間数が6以下なら8人、8以下なら13人、それより多いと16人。
// 一次エントリーの画面(mode0150_content.dart)と同じ決まり)
int _ichijiEntrySuu(int kukansuu) {
  if (kukansuu <= 6) return 8;
  if (kukansuu <= 8) return 13;
  return 16;
}

// 調子の説明(調子のタイムへの影響度が0%のときは、効かないことを書く)
String _chousiBun(KantokuData? kantoku) {
  if (kantoku != null &&
      kantoku.yobiint2.length > 2 &&
      kantoku.yobiint2[2] == 0) {
    return '・調子: このデータでは、調子(体調不良も含む)はタイムに影響しない。';
  }
  return '・調子: 駅伝(駅伝予選は除く)で効く。100が最高で、低いほどタイムが悪くなり、0は体調不良(タイムが大きく悪くなる)。'
      '区間エントリーのときに決まり、当日に体調不良になったり持ち直したりすることがある。指示の成否には関係しない。';
}

// 能力の説明(能力のタイムへの影響度が0%のときは、駅伝と駅伝予選のタイムに効かないことを書く)
String _nouryokuBun(
  KantokuData? kantoku,
  int index,
  String namae,
  String setsumei,
) {
  if (kantoku != null && nouryokuEikyodoPercent(kantoku, index) == 0) {
    return '・$namae: このデータでは、駅伝と駅伝予選のタイムに影響しない(記録会などの持ちタイムには影響している)。';
  }
  return '・$namae: $setsumei';
}
