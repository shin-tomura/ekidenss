import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/ToujituHenkou_com.dart' show senryakuEntryKakuritu;

// ------------------------------------------------------------
// 設定の紹介(2.1.3)
//
// 説明画面の設定タブのボタンごとの紹介文を、ここにまとめる。次の2か所で使う。
// ・設定タブ: 「設定の説明を出す」がオンのとき、各ボタンのすぐ下に紹介文を小さく出す
//   (setting_screen.dart の _setteiTab。ボタンの名前で紹介文を引く。押せないときの理由の文の下にも出す)
// ・ホームの画面の札: 1月中旬〜2月の、行事のない日(「今日は特に何もありませんでした」の日)に、
//   設定を1つ紹介する(mode0100_content.dart。札は screens/settei_shoukai_fuda.dart)
//
// ・名前(mei)は、設定タブのボタンの文字と同じにする(違うと紹介文が出ない)。
//   設定タブにボタンを足したら、ここにも1行足す(CLAUDE.md)
// ・紹介文は説明書と同じ書き方(です・ます。現実の世界と比べない。温情の支給・隠れた逸材に触れない。
//   「極」は「春の定期支給だけ」と言い切らない)。初期値を書いたものは、初期値を変えたら直す
// ・札で紹介するのは fuda が true のもの(ルールと表示の設定)。データやリセット、見る・調べるの項目は、
//   設定タブの紹介文だけにする
// ・札の選び方: 戦略的エントリー確率が0%(初期値)のあいだは、毎年1月中旬に戦略的エントリー確率設定を出す。
//   ほかの日は、設定タブの見出しを1つずつ順に回した並び(_fudaJunban)から、年と日付で決まるものを出す
//   (同じ日は何度開いても同じ。セーブデータは使わない)。0%以外のときは、戦略的エントリー確率設定も
//   ほかの設定と同じく並びに入る
//   ・番号は、1月中旬〜2月中旬の4日(0%のあいだは1月中旬を除く3日)で1つずつ進める。2月下旬の札は
//     カスタム駅伝を開催しない年だけなので、番号は進めず、並びの反対側から出す
//     (どの設定も、並びの数÷1年の日数の年で、すき間なく一回りする。36個なら9年。2.1.3の開発中に、
//      1年に5つずつ進めていたのを直した。2月下旬の分が毎年飛ばされ、出る間隔がばらついていたため)
// ・「設定の説明を出す」は KantokuData.yobiint5[77](0=出す(初期値)、1=出さない)。表示の好みなので、
//   リセットでもセーブデータの読み込みでも今の値を残し、QRコードには入れない(reset_ichiran.dart)
// ------------------------------------------------------------

/// 「設定の説明を出す」の保存場所(KantokuData.yobiint5 の番号)
const int setteiSetsumeiIndex = 77;

/// 設定タブで設定の説明を出すか(初期値は出す)
bool setteiSetsumeiDasu(KantokuData? kantoku) {
  if (kantoku == null || kantoku.yobiint5.length <= setteiSetsumeiIndex) {
    return true;
  }
  return kantoku.yobiint5[setteiSetsumeiIndex] == 0;
}

/// 設定タブで設定の説明を出すかを変える(保存は呼び出し側で行う)
void setteiSetsumeiSettei(KantokuData kantoku, bool dasu) {
  if (kantoku.yobiint5.length <= setteiSetsumeiIndex) return;
  kantoku.yobiint5[setteiSetsumeiIndex] = dasu ? 0 : 1;
}

/// 次に説明画面を開いたときに設定タブを開くか(ホームの画面の札の「設定タブで見る」。
/// setting_screen.dart の initState で読んで false に戻す。セーブデータには保存しない)
bool setteiTabYoyaku = false;

/// 設定1つ分の紹介
class SetteiShoukai {
  /// 設定タブのボタンの名前
  final String mei;

  /// 設定タブの見出し(札を回す順に使う)
  final String midashi;

  /// 紹介文
  final String bun;

  /// ホームの画面の札で紹介するか
  final bool fuda;

  /// 押せないときの理由の文に含まれる名前(ボタンの名前と違うときだけ書く)
  final String? riyuuMei;

  const SetteiShoukai(
    this.mei,
    this.midashi,
    this.bun, {
    this.fuda = true,
    this.riyuuMei,
  });
}

/// 戦略的エントリー確率設定の名前(0%のあいだは毎年1月中旬に紹介する)
const String _senryakuMei = '戦略的エントリー確率設定';

/// 紹介文の一覧(設定タブの並び)
const List<SetteiShoukai> setteiShoukaiList = [
  SetteiShoukai(
    'リセット・ロード・QRで残るもの・変わるもの',
    '',
    'リセットやセーブデータ・QRコードの読み込みで、設定ごとに何が残り、何が変わるかを一覧で見られます。',
    fuda: false,
  ),
  // ---- メモとデータ ----
  SetteiShoukai(
    'フリーメモ',
    'メモとデータ',
    'ゲームの中で自由に書けるメモです。作戦や気づいたことを書き留めておけます。',
    fuda: false,
  ),
  SetteiShoukai(
    'データセーブ・ロード',
    'メモとデータ',
    '今のゲームのデータをセーブしたり、セーブしたデータを読み込んだりできます。',
    fuda: false,
  ),
  SetteiShoukai(
    'データ共有(世界を共有)',
    'メモとデータ',
    'セーブしたデータを世界データとして書き出し、ほかの人と共有できます。受け取った世界データを読み込むこともできます。',
    fuda: false,
  ),
  SetteiShoukai(
    'QRコードで設定入出力',
    'メモとデータ',
    'レースや育成などの設定を、QRコードで書き出したり読み込んだりできます。',
    fuda: false,
    riyuuMei: 'QRコード設定入出力',
  ),
  SetteiShoukai(
    '選手トレード',
    'メモとデータ',
    '同じ学年の選手どうしで、大学をまたいでトレードできます。',
    fuda: false,
  ),
  SetteiShoukai(
    '名声・育成力と設定を残してやり直す(おすすめ)',
    'メモとデータ',
    '名声・育成力と設定を残したまま、1年目からやり直します。',
    fuda: false,
  ),
  SetteiShoukai(
    '全てリセットしてやり直す',
    'メモとデータ',
    '名声・育成力と設定も初期値に戻して、1年目からやり直します。',
    fuda: false,
  ),
  // ---- モードと大会 ----
  SetteiShoukai(
    '箱庭モード/通常モード切替',
    'モードと大会',
    '箱庭モードでは、選手の能力や基本走力を自由に編集でき、全大学のエントリー・当日変更・レース中の指示まで決められます。思い描いた展開を、自分の手で作れます。',
  ),
  SetteiShoukai(
    'カスタム駅伝設定',
    'モードと大会',
    '2月下旬のカスタム駅伝の名前と区間数(2〜10区)を、この設定で決めます。出場できる学年や留学生の出場、獲得名声の倍率も選べ、開催しないこともできます。区間ごとの距離や坂は、「駅伝コース編集」で変えられます。',
  ),
  SetteiShoukai(
    '記録会時期設定',
    'モードと大会',
    '市民ハーフ・1万m・5千mの記録会を、11月〜12月(初期値)と9月のどちらに行うかを選べます。',
  ),
  SetteiShoukai(
    '駅伝コース紹介',
    'モードと大会',
    '各駅伝の、区間ごとの距離や坂のようすを見られます。',
    fuda: false,
  ),
  SetteiShoukai(
    '駅伝コース編集',
    'モードと大会',
    '10月・11月・正月・カスタム駅伝の、区間ごとの距離や、登り・下りの割合と勾配、アップダウンの回数を変えられます。カスタム駅伝の区間数は、「カスタム駅伝設定」で決めます。',
  ),
  // ---- 総監督と難易度 ----
  SetteiShoukai(
    '総監督をする大学を変更',
    '総監督と難易度',
    '途中から、別の大学の総監督に移れます。名声の低い大学から出直したいときや、ライバル校を率いてみたいときに使えます。',
  ),
  SetteiShoukai(
    '選手の能力を見抜く総監督の能力をリセット',
    '総監督と難易度',
    '総監督が身につけた、選手の能力を見抜く力をなくし、能力値の「??」をもう一度隠します。',
    fuda: false,
  ),
  SetteiShoukai(
    '難易度変更',
    '総監督と難易度',
    '鬼・難しい・普通・易しいから選べ、金銀の支給量が変わります。',
  ),
  SetteiShoukai(
    '難易度変更2',
    '総監督と難易度',
    '自分の大学以外の全大学の強さのレベルを変えられます。すぐには変わらず、春か夏の成長で少しずつ効いてきます。',
  ),
  SetteiShoukai(
    '難易度「極」「天」設定',
    '総監督と難易度',
    '「極」では目標順位を達成しても金銀がもらえず、「天」では金銀が支給されません。今いる選手の力で勝負する、腕試しの遊び方です。',
  ),
  // ---- レースのタイム ----
  SetteiShoukai(
    '全体・区間ごとタイム調整',
    'レースのタイム',
    'レースのタイム全体や、駅伝の区間ごとのタイムを、−10%〜+10%の範囲で速くしたり遅くしたりできます。今の値を長距離タイム抑制設定と一緒に1本の行で写したり、写した行を貼り付けて同じ設定にしたりもできます。作者のおすすめの値を入れることもできます。',
  ),
  SetteiShoukai(
    '長距離タイム抑制設定',
    'レースのタイム',
    '長い距離で飛び抜けて速いタイムが出すぎないように抑える強さを変えられます。',
  ),
  SetteiShoukai(
    '能力のタイムへの影響度設定',
    'レースのタイム',
    '長距離粘りや登り適性などの能力の差が駅伝のタイムにどれだけ効くかを、能力ごとに0%〜200%で変えられます。初期値は100%です。',
  ),
  SetteiShoukai(
    '調子関連設定',
    'レースのタイム',
    '調子の良し悪しがタイムに与える影響の大きさや、調子が変わる確率を変えられます。コンピュータの大学をいつも調子100で走らせて、手ごわくすることもできます。',
  ),
  SetteiShoukai(
    '目標順位・指示の補正設定',
    'レースのタイム',
    '目標順位を下回ったときの焦りや、「前半突っ込み」「前半抑え」の成否によるタイムの変わり方の強さを、0%〜200%で変えられます。',
  ),
  SetteiShoukai(
    '集団走設定',
    'レースのタイム',
    '駅伝の1区と11月駅伝予選で、誰が集団を引っ張るかを左右する「その日の勢い」の大きさを選べます。大きいほど、引っ張る選手が入れ替わりやすくなります。',
  ),
  SetteiShoukai(
    '学連選抜モチベーション設定',
    'レースのタイム',
    '学連選抜の1区以外の選手のタイムを少し悪くする補正を、10段階で付けられます。初期値は「補正なし」です。',
  ),
  SetteiShoukai(
    '実力発揮度全大学一斉変更',
    'レースのタイム',
    '能力ごとの実力の発揮しやすさ(大学の個性)を、全大学まとめて変えられます。大学ごとには、大学画面の「大学の個性」で変えられます。',
  ),
  // ---- コンピュータの大学の作戦 ----
  SetteiShoukai(
    '最適解区間配置確率設定',
    'コンピュータの大学の作戦',
    'コンピュータの大学が、試走タイムから一番速くなる区間配置を組む確率です。初期値は30%で、上げるほど相手の配置が手ごわくなります。',
  ),
  SetteiShoukai(
    _senryakuMei,
    'コンピュータの大学の作戦',
    'コンピュータの大学が、主力選手を補欠に温存し、当日変更で起用する作戦をとる確率です。初期値は0%で、この作戦は行われません。上げると、大会当日に相手の顔ぶれが変わります。',
  ),
  SetteiShoukai(
    '目標順位決め方設定(コンピュータの大学)',
    'コンピュータの大学の作戦',
    'コンピュータの大学の目標順位の決め方を、対校戦の順位を重く見る形(初期値)・前年の成績から上を目指す形・シード権を意識する形から選べます。',
  ),
  SetteiShoukai(
    'コンピュータ金銀使用',
    'コンピュータの大学の作戦',
    'コンピュータの大学も金銀を受け取り、夏合宿で選手を鍛えます(初期値はON)。大学ごとの支給レベルも決められます。',
  ),
  SetteiShoukai(
    'コンピュータスカウト',
    'コンピュータの大学の作戦',
    '新入生のスカウトが、コンピュータの大学との取り合いになります(初期値はON)。地区ごとに声をかけ合う形と全国一斉に交渉する形を選べ、OFFにするとプレイヤーだけが交渉できます。',
  ),
  SetteiShoukai(
    '区間配置の方針',
    'コンピュータの大学の作戦',
    'コンピュータの大学が区間配置で前の区間をどれだけ重く見るかや、最適解区間配置を使うかを、大学ごとに選べます。',
  ),
  SetteiShoukai(
    '正月駅伝予選の指示と集団走',
    'コンピュータの大学の作戦',
    'コンピュータの大学が、正月駅伝予選で集団走や指示を使うかを選べます。使う(初期値)と、予選の通過が難しくなります。',
  ),
  SetteiShoukai(
    '強化プロジェクト設定',
    'コンピュータの大学の作戦',
    '正月駅伝の優勝から遠ざかっている大学が、数年間スカウトに本腰を入れることがあります。スカウトでどのくらい有利になるかや、自分の大学も選ばれるようにするかを決められます。',
  ),
  SetteiShoukai(
    '監督の母校パイプ設定',
    'コンピュータの大学の作戦',
    'コンピュータスカウトがONのとき、大学の監督の母校の新入生が、その大学を選びやすくなります。その強さや、母校の後輩に優先して声をかける度合いを選べます。',
  ),
  // ---- 育成と名声 ----
  SetteiShoukai(
    '育成力変更',
    '育成と名声',
    '大学ごとの選手の伸びやすさ(10〜150)を変えられます。初期値は全大学が最大の150です。',
  ),
  SetteiShoukai(
    '金銀支給量設定',
    '育成と名声',
    '金銀の支給量を2倍にするかや、難易度ごとの支給量の割合(10%〜500%)を変えられます。',
  ),
  SetteiShoukai(
    '年間強化練習効果設定',
    '育成と名声',
    '年間強化練習で能力が上がる効果の大きさを、0(なし)〜5(最大)から選べます。',
  ),
  SetteiShoukai(
    '成長タイプ設定',
    '育成と名声',
    '選手の成長タイプの割合や、限界突破の起こり方を変えられます。',
  ),
  SetteiShoukai(
    '名声変更',
    '育成と名声',
    '大学ごとの名声を編集したり、全大学の名声を初期値に戻したりできます。',
  ),
  SetteiShoukai(
    '駅伝名声設定',
    '育成と名声',
    '駅伝ごとに、得られる名声の倍率を変えられます。',
  ),
  SetteiShoukai(
    '入学時名声影響度設定',
    '育成と名声',
    '新入生が進学先を選ぶとき、大学の名声をどれだけ重く見るかのレベルを変えられます。下げるほど、名声の低い大学にも有力な新入生が来やすくなります。',
  ),
  SetteiShoukai(
    '名声の横並び設定',
    '育成と名声',
    '名声の順位のブロックや決めた大学のグループを、スカウトでは同じ名声として扱えます。名門のグループを長く強いままにするなど、勢力図を作れます。',
  ),
  // ---- 留学生 ----
  SetteiShoukai(
    '留学生受け入れ設定',
    '留学生',
    '大学ごとに、留学生を受け入れるかと、その優秀度(1〜4)を決められます。',
  ),
  // ---- 表示 ----
  SetteiShoukai(
    '持ちタイムの表示設定',
    '表示',
    'ランキングや区間配置の確認などの画面で、持ちタイムを自己ベストと今季ベストのどちらで出すかを選べます。',
  ),
  SetteiShoukai(
    '趣味・高校時代の表示設定',
    '表示',
    '選手の趣味や、出身校・高校時代の実績を、画面に出さないようにできます。',
  ),
  // ---- 見る・調べる ----
  SetteiShoukai(
    '自分のチームの歩み',
    '見る・調べる',
    '自分の大学のこれまでの戦績を読めます。文字で検索することもできます。',
    fuda: false,
  ),
  SetteiShoukai(
    '高校名鑑',
    '見る・調べる',
    '架空の高校の紹介や、高校の大会の記録を見られます。',
    fuda: false,
  ),
  SetteiShoukai(
    'スキップして統計データ取得',
    '見る・調べる',
    '年数を決めて自動で進め、その間の選手の記録などの統計を取れます。',
    fuda: false,
  ),
  SetteiShoukai(
    '新入生の進学先(全大学)',
    '見る・調べる',
    '全大学の新入生が、どの大学に進んだかを見られます。',
    fuda: false,
  ),
  SetteiShoukai(
    'アルバム表示',
    '見る・調べる',
    'アルバムに追加した卒業生を見られます。',
    fuda: false,
  ),
  SetteiShoukai(
    '箱庭長距離陸上競技連盟',
    '見る・調べる',
    '箱庭長距離陸上競技連盟の役員の一覧を見られます。',
    fuda: false,
  ),
];

/// ボタンの名前[mei]の紹介(なければnull)
SetteiShoukai? setteiShoukaiYomu(String mei) {
  for (final SetteiShoukai s in setteiShoukaiList) {
    if (s.mei == mei) return s;
  }
  return null;
}

/// 押せないときの理由の文[bun](「(〜はできません)」)の設定の紹介(なければnull)
SetteiShoukai? setteiShoukaiRiyuu(String bun) {
  if (!bun.contains('できません')) return null;
  SetteiShoukai? erabi;
  for (final SetteiShoukai s in setteiShoukaiList) {
    final String m = s.riyuuMei ?? s.mei;
    // 名前の一部が別の名前になっていることもあるので、長い名前を優先する
    if (bun.contains(m) && (erabi == null || m.length > (erabi.riyuuMei ?? erabi.mei).length)) {
      erabi = s;
    }
  }
  return erabi;
}

/// 札を回す並び(設定タブの見出しを1つずつ順に回す。[nozoku]の名前は入れない)
List<SetteiShoukai> _fudaJunban({String? nozoku}) {
  final List<String> midashiJun = [];
  final Map<String, List<SetteiShoukai>> midashiBetsu = {};
  for (final SetteiShoukai s in setteiShoukaiList) {
    if (!s.fuda || s.mei == nozoku) continue;
    if (!midashiBetsu.containsKey(s.midashi)) {
      midashiJun.add(s.midashi);
      midashiBetsu[s.midashi] = [];
    }
    midashiBetsu[s.midashi]!.add(s);
  }
  final List<SetteiShoukai> junban = [];
  for (int i = 0; ; i++) {
    bool atta = false;
    for (final String m in midashiJun) {
      final List<SetteiShoukai> l = midashiBetsu[m]!;
      if (i < l.length) {
        junban.add(l[i]);
        atta = true;
      }
    }
    if (!atta) break;
  }
  return junban;
}

/// 札を出す日の番号(1月中旬=0、1月下旬=1、2月上旬=2、2月中旬=3、2月下旬=4。ほかの日はnull)
/// (呼び出し側で、行事のない日(「今日は特に何もありませんでした」の日)だけに使う。
///  2月下旬はカスタム駅伝を開催しない年だけ、その日になる)
int? _fudaBangou(Ghensuu gh) {
  if (gh.month == 1 && gh.day == 15) return 0;
  if (gh.month == 1 && gh.day == 25) return 1;
  if (gh.month == 2 && gh.day == 5) return 2;
  if (gh.month == 2 && gh.day == 15) return 3;
  if (gh.month == 2 && gh.day == 25) return 4;
  return null;
}

/// 今日のホームの画面の札で紹介する設定(札を出す日でなければnull)
SetteiShoukai? setteiFudaKyou(Ghensuu gh, KantokuData? kantoku) {
  final int? bangou = _fudaBangou(gh);
  if (bangou == null) return null;
  // 戦略的エントリー確率が0%(初期値)のあいだは、毎年1月中旬に紹介する(ほかの日の並びには入れない)
  final bool senryakuMada = senryakuEntryKakuritu(kantoku) == 0;
  if (bangou == 0 && senryakuMada) return setteiShoukaiYomu(_senryakuMei);
  final List<SetteiShoukai> junban = _fudaJunban(nozoku: senryakuMada ? _senryakuMei : null);
  if (junban.isEmpty) return null;
  // 1月中旬〜2月中旬の4日で番号を進める(0%のあいだは、1月中旬が戦略的エントリーなので3日)
  final int hajime = senryakuMada ? 1 : 0;
  final int nissuu = 4 - hajime;
  final int n = bangou <= 3
      ? gh.year * nissuu + (bangou - hajime)
      // 2月下旬(カスタム駅伝を開催しない年だけ): 同じ年のほかの札と重ならないように、並びの反対側から出す
      : gh.year * nissuu + junban.length ~/ 2;
  return junban[((n % junban.length) + junban.length) % junban.length];
}
