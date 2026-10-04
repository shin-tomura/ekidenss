import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/siji_sontoku.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';

// ------------------------------------------------------------
// 「指示ごとの損得予測」の文(1.8.8)
// 画面(Modal_sijiSontoku.dart)と、生成AIに渡すテキスト(次区間予想セットと、単体の
// 「指示ごとの損得予測」)で同じ文を使う。計算は siji_sontoku.dart
// 生成AIに渡すテキストには、画面と同じ内容だけを入れる
// (期待値は入れない。今選んでいる指示も入れない)
// ------------------------------------------------------------

/// 襷を受けた時点の状況の文
/// [gakuren] 学連選抜の選手か(学連選抜の監督をしているとき)
String sijiSontokuJoukyouBun(SijiSontoku s, {bool gakuren = false}) {
  final int juni = s.juni + 1;
  final int mokuhyou = s.mokuhyou + 1;
  if (s.joukyou == SijiSontokuJoukyou.gakurenMokuhyouNai) {
    return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位以内。学連選抜にはほっと一息はありません)';
  }
  if (gakuren && s.joukyou == SijiSontokuJoukyou.shitamawari) {
    final double? sa = s.timeSa;
    final String saBun = sa == null
        ? ''
        : '・$mokuhyou位と${sa.toStringAsFixed(1)}秒差';
    return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位を下回っています$saBun)';
  }
  if (gakuren && s.joukyou == SijiSontokuJoukyou.uwamawari) {
    return '襷を受けた時点で$juni位相当(学連選抜の目標の$mokuhyou位を${mokuhyou - juni}つ上回っています)';
  }
  if (gakuren && s.joukyou == SijiSontokuJoukyou.choudo) {
    return '襷を受けた時点で$juni位相当(学連選抜の目標順位ちょうど)';
  }
  if (s.joukyou == SijiSontokuJoukyou.fukuroStart) {
    return '6区は復路のスタートなので、往路の順位による目標順位の補正はありません';
  }
  if (s.joukyou == SijiSontokuJoukyou.shitamawari) {
    final double? sa = s.timeSa;
    final String saBun = sa == null
        ? ''
        : '・$mokuhyou位と${sa.toStringAsFixed(1)}秒差';
    return '襷を受けた時点で$juni位(目標$mokuhyou位を下回っています$saBun)';
  }
  if (s.joukyou == SijiSontokuJoukyou.uwamawari) {
    return '襷を受けた時点で$juni位(目標$mokuhyou位を${mokuhyou - juni}つ上回っています)';
  }
  return '襷を受けた時点で$juni位(目標順位ちょうど)';
}

/// 指示なしの損得の理由(補正の強さが0%などで損得がないときと、理由がないときは空)
String sijiSontokuNashiRiyuu(SijiSontoku s) {
  if (s.nashi == 0.0) return '';
  if (s.joukyou == SijiSontokuJoukyou.shitamawari) {
    return '目標順位を下回ったため、前半無理に突っ込んでしまう分';
  }
  if (s.joukyou == SijiSontokuJoukyou.uwamawari) {
    return '目標順位を上回ったため、ほっと一息ついてしまう分';
  }
  return '';
}

/// 損得の言い方(「約38秒の得」「1秒未満の損」「損得なし」。正の秒数が損、負の秒数が得)
String sijiSontokuAtai(double byou) {
  if (byou == 0.0) return '損得なし';
  if (byou.abs() < 0.5) return byou > 0 ? '1秒未満の損' : '1秒未満の得';
  final int maru = byou.abs().round();
  return byou > 0 ? '約$maru秒の損' : '約$maru秒の得';
}

/// 注意書き(画面の下と、生成AIに渡すテキストの最後に出す)
const String sijiSontokuChuuiByousuu =
    '・秒数は、この選手のこの区間の見込みタイムから計算したものです。実際の補正とは1秒ほどずれることがあります。';
const String sijiSontokuChuuiSeikouritsu =
    '・成功率は、前半突っ込みは駅伝男、前半抑えは平常心の値と同じです。';
const String sijiSontokuChuuiHosei =
    '・前半突っ込みか前半抑えの指示を出すと、目標順位による補正(下回ったときの前半の突っ込み、上回ったときのほっと一息)はかからず、代わりに指示の成否による補正がかかります。';

/// 学連選抜の選手には、指示の補正のあとにモチベーション低下補正がかかる(1.8.2)
const String sijiSontokuChuuiMotivation =
    '・学連選抜の選手には、2区以降で「学連選抜モチベーション設定」のモチベーション低下補正もかかります。この補正は指示の補正のあとにかかるので、ここの秒数には入っていません。走ったあとの補正の説明では、指示の補正の秒数とは別に「モチベーション低下補正」として出ます(区間タイムはその分さらに遅くなります)。';

/// 補正の強さを初期値から変えているとき(1.8.2)
const String sijiSontokuChuuiTsuyosa =
    '・補正の強さを設定で変更しています(説明画面の設定タブの「目標順位・指示の補正設定」)。';

/// 学連選抜のモチベーション低下補正をかける設定か(Album.yobiint4が1以上)
bool sijiSontokuMotivationHoseiAri() {
  final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
  return album != null && album.yobiint4 > 0;
}

/// 生成AIに渡すテキストに入れる選手(今から走る区間の、自分の大学の選手か、
/// 学連選抜の監督をしているときの学連選抜の選手)
class _AiTaishou {
  final SenshuData? senshu;
  final Senshu_Gakuren_Data? gakurenSenshu;
  const _AiTaishou({this.senshu, this.gakurenSenshu});
}

_AiTaishou? _aiTaishou(Ghensuu gh) {
  final int race = gh.hyojiracebangou;
  final int kukan = gh.nowracecalckukan;
  if (!sijiSontokuTaishou(race, kukan)) return null;
  UnivData? my;
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == gh.MYunivid) my = u;
  }
  if (my == null) return null;
  // 自分の大学が出場しているときは、自分の大学の選手(レース画面の指示の欄と同じ選び方)
  if (my.taikaientryflag.length > race && my.taikaientryflag[race] == 1) {
    for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
      if (s.univid == gh.MYunivid &&
          s.gakunen >= 1 &&
          s.entrykukan_race.length > race &&
          s.entrykukan_race[race].length >= s.gakunen &&
          s.entrykukan_race[race][s.gakunen - 1] == kukan) {
        return _AiTaishou(senshu: s);
      }
    }
    return null;
  }
  // 学連選抜の監督をしているときは、学連選抜の選手
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku != null &&
      gakurenKonnenAri(gh) &&
      gakurenKantokuChuu(kantoku, my)) {
    final Senshu_Gakuren_Data? g = gakurenKukanSenshu(kukan);
    if (g != null) return _AiTaishou(gakurenSenshu: g);
  }
  return null;
}

/// 生成AIに渡すテキストに「指示ごとの損得予測」を入れられる場面か
/// (損得予測の画面を開ける場面で、損得を出す選手がいるとき。一覧に出すかどうかに使う)
bool sijiSontokuAiAri(Ghensuu gh) => _aiTaishou(gh) != null;

/// 生成AIに渡す「指示ごとの損得予測」の文(画面と同じ内容)
/// 出せない場面や計算できないときは空文字
Future<String> sijiSontokuAiText(Ghensuu gh) async {
  final _AiTaishou? taishou = _aiTaishou(gh);
  if (taishou == null) return '';
  final int kukan = gh.nowracecalckukan;
  final bool gakuren = taishou.gakurenSenshu != null;
  final SijiSontoku? s = gakuren
      ? await sijiSontokuKeisanGakuren(taishou.gakurenSenshu!.id)
      : await sijiSontokuKeisan(taishou.senshu!.id);
  if (s == null) return '';

  final String senshuMei = gakuren
      ? '学連選抜 ${taishou.gakurenSenshu!.name}(${taishou.gakurenSenshu!.gakunen}年・所属:${gakurenShozoku(taishou.gakurenSenshu!)})'
      : '${taishou.senshu!.name}(${taishou.senshu!.gakunen}年)';
  final String nashiRiyuu = sijiSontokuNashiRiyuu(s);
  final List<String> gyou = [
    '【指示ごとの損得予測(${kukan + 1}区・$senshuMei)】',
    sijiSontokuJoukyouBun(s, gakuren: gakuren),
    '・指示なし: ${sijiSontokuAtai(s.nashi)}${nashiRiyuu.isEmpty ? '' : '($nashiRiyuu)'}',
    '・前半から突っ込む(成功率${s.tsukkomiSeikouritsu}%・駅伝男): 成功なら${sijiSontokuAtai(s.tsukkomiSeikou)}、失敗なら${sijiSontokuAtai(s.tsukkomiShippai)}',
    '・前半は抑える(成功率${s.osaeSeikouritsu}%・平常心): 成功なら${sijiSontokuAtai(s.osaeSeikou)}、失敗なら${sijiSontokuAtai(s.osaeShippai)}',
    sijiSontokuChuuiByousuu,
    sijiSontokuChuuiSeikouritsu,
    sijiSontokuChuuiHosei,
    if (gakuren && sijiSontokuMotivationHoseiAri()) sijiSontokuChuuiMotivation,
    if (s.tsuyosaHenkouChuu) sijiSontokuChuuiTsuyosa,
  ];
  return gyou.join('\n');
}
