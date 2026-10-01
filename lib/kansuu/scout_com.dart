import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // TEISUU
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// コンピュータ大学の新入生スカウト(1.7.9)
//
// ・ON(初期値)のとき、新入生スカウトはラウンド制の勧誘合戦になる
//   プレイヤーが1回交渉するたびに、コンピュータの各大学も同じラウンドで1人ずつ交渉し、
//   結果を一斉に判定する(プレイヤーの大学の新入生も狙われる)
//   ラウンド数は設定の回数(1〜5回、初期値3回)。プレイヤーがスカウトを終えたら、
//   残りのラウンドはコンピュータだけで行う
//   スキップ中(スカウト画面が出ないとき)は、4月5日の処理の最後にコンピュータだけで
//   全ラウンドを行う
// ・OFFのときは今まで通り(プレイヤーだけが3回交渉でき、結果はすぐに出る)
// ・成功率はプレイヤーと同じ式
//     名声の比 = 交渉する大学の名声 ÷ (交渉する大学の名声 + 今の所属校の名声) (0.1%〜90%)
//     タイム順位による上限 = 交渉する大学以外の新入生の中での5000m持ちタイムの順位で、
//       1位10%〜87位以下75%
//     成功率 = 小さいほう(1%単位に丸め、1%未満は0.1%)
// ・同じ選手に複数の大学が成功した場合は、名声の重みを付けた抽選で1校に決める(名声0は重み1)
//   今の所属校はこの抽選に入らない(1校も成功しなければ、そのまま残る)
// ・留学生は狙わず、放出もしない
// ・コンピュータの判断(見るのは5000m持ちタイムと能力の値そのもの。個性の設定や、
//   プレイヤーにも見えない成長タイプなどは使わない)
//     点数 = タイム点(新入生の中での持ちタイムの順位を0〜100点にしたもの)×0.5
//            + 能力点(スカウト方針で重視する能力の重み付き平均)×0.5
//       (タイム重視はタイム点だけ)
//     スカウト方針(大学ごと、yobiint2[59]・[60]に1大学1桁)
//       0自動: 長距離粘り・ロード適性(重み2)、ペース変動対応力(重み1)と、チーム事情による
//         補強ポイント(重み2)。来年も残る1〜3年生に、登り適性・下り適性・アップダウン対応力が
//         70以上の選手が2人いなければ、その能力を補強ポイントにする
//       1スピード重視(スパート力・ペース変動対応力)、2距離重視(長距離粘り・ロード適性)、
//       3登り重視、4下り重視、5アップダウン重視、6メンタル重視(駅伝男・平常心・安定感)、
//       7タイム重視
//       (1〜5は年間強化練習メニュー・銀の使い道と同じ番号)
//     自校の新入生(留学生を除く)のいちばん低い点数より点数が高い選手だけを狙う
//     (取れたら、いちばん点数の低い新入生を放出することになるため、得をする場合だけ動く)
//     性格(大学ごと、yobiint2[61]・[62]に1大学1桁)で、上積み(点数の差)と成功率から狙う
//       1大物狙い: 上積み×上積み×成功率、2バランス: 上積み×成功率、
//       3堅実: 上積み×成功率×成功率
//       0自動: 名声順位1〜5位は大物狙い、6〜15位はバランス、16位以下は堅実
//       全大学が同じ選手に集中しないように、上位3人から値の重みを付けた抽選で選ぶ
//     積極性(全体): 各大学が1ラウンドで動く確率
// ・スカウトが終わったら、新入生が5人を超えたコンピュータの大学は、自校の方針での点数が
//   いちばん低い選手から放出し、欠員のある大学(プレイヤーの大学も含む)にランダムに入れる
//   プレイヤーの大学が5人を超えた場合は、今まで通り放出の画面で選ぶ
// ・デバッグ実行時は、VS Codeのデバッグコンソールに「[COMスカウト]」で始まるログを出す
// ------------------------------------------------------------

/// KantokuData.yobiint2 の使用番号: コンピュータスカウトの設定
/// ラウンド回数のコード×10000 + OFFなら1000 + (100−積極性)
///   ラウンド回数のコード: 0なら3回(初期値)、1〜5ならその回数
///   OFF: 0=ON(初期値)、1=OFF
///   積極性: 0〜100(%)。100から引いた値を入れるので、0が100%(初期値)
const int comScoutSetteiIndex = 58;

/// KantokuData.yobiint2 の使用番号: 大学ごとのスカウト方針
/// 1大学1桁で、[59]に大学0〜14、[60]に大学15〜29(大学id%15の位)
const int comScoutHoushinIndex0 = 59;
const int comScoutHoushinIndex1 = 60;

/// KantokuData.yobiint2 の使用番号: 大学ごとの性格(同じ形式)
const int comScoutSeikakuIndex0 = 61;
const int comScoutSeikakuIndex1 = 62;

const int _ketasuu = 15; // 1つの番号に格納する大学数

/// スカウト方針の名前(0〜7)。0(自動)が初期値
const List<String> comScoutHoushinMei = [
  '自動',
  'スピード重視',
  '距離重視',
  '登り重視',
  '下り重視',
  'アップダウン重視',
  'メンタル重視',
  'タイム重視',
];

/// 性格の名前(0〜3)。0(自動)が初期値
const List<String> comScoutSeikakuMei = ['自動', '大物狙い', 'バランス', '堅実'];

const int _seikakuOomono = 1; // 大物狙い
const int _seikakuBalance = 2; // バランス
const int _seikakuKenjitsu = 3; // 堅実

const int _houshinJidou = 0; // 自動
const int _houshinTime = 7; // タイム重視

const int _tokuiSakaime = 70; // 補強ポイントの判定で「得意」とみなす能力値
const int _tokuiNinzuu = 2; // 得意な選手がこの人数に届かなければ補強ポイント

int _juu(int n) {
  int p = 1;
  for (int i = 0; i < n; i++) {
    p *= 10;
  }
  return p;
}

// ------------------------------------------------------------
// 設定の読み書き
// ------------------------------------------------------------

int _settei(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= comScoutSetteiIndex) return 0;
  final int v = kantoku.yobiint2[comScoutSetteiIndex];
  return v < 0 ? 0 : v;
}

/// コンピュータスカウトがONかどうか
bool isComScoutOn(KantokuData kantoku) {
  return (_settei(kantoku) ~/ 1000) % 10 != 1;
}

/// 積極性(0〜100%)
int comScoutSekkyokusei(KantokuData kantoku) {
  return (100 - _settei(kantoku) % 1000).clamp(0, 100);
}

/// ラウンド回数(1〜5回)
int comScoutKaisuu(KantokuData kantoku) {
  final int code = (_settei(kantoku) ~/ 10000) % 10;
  return (code >= 1 && code <= 5) ? code : 3;
}

/// 新入生スカウトの回数(ONなら設定のラウンド回数、OFFなら今まで通り3回)
int comScoutChances(KantokuData kantoku) {
  return isComScoutOn(kantoku) ? comScoutKaisuu(kantoku) : 3;
}

/// ON/OFF・積極性・ラウンド回数をyobiint2のリストに書き込む(保存は呼び出し側で行う)
void comScoutSetteiKaku(
  List<int> yobiint2, {
  required bool on,
  required int sekkyokusei,
  required int kaisuu,
}) {
  if (yobiint2.length <= comScoutSetteiIndex) return;
  final int s = sekkyokusei.clamp(0, 100);
  final int code = (kaisuu >= 1 && kaisuu <= 5 && kaisuu != 3) ? kaisuu : 0;
  yobiint2[comScoutSetteiIndex] = code * 10000 + (on ? 0 : 1000) + (100 - s);
}

/// 各種設定のQRコードから読んだ値が、正しい形かどうか
bool comScoutSetteiTadashii(int v) {
  if (v < 0 || v >= 100000) return false;
  final int code = v ~/ 10000;
  final int off = (v ~/ 1000) % 10;
  final int gyaku = v % 1000;
  return code <= 5 && off <= 1 && gyaku <= 100;
}

/// 1大学1桁で詰めた値(大学0〜14は[idx0]、15〜29は[idx1])から、大学の桁(0〜9)を取り出す
int _univKetaYomu(List<int> yobiint2, int idx0, int idx1, int univid) {
  if (univid < 0 || univid >= _ketasuu * 2) return 0;
  final int idx = univid < _ketasuu ? idx0 : idx1;
  if (yobiint2.length <= idx) return 0;
  final int v = yobiint2[idx];
  if (v < 0) return 0;
  return (v ~/ _juu(univid % _ketasuu)) % 10;
}

/// 1大学1桁で詰めた値に、大学の桁(0〜9)を書き込む(保存は呼び出し側で行う)
void _univKetaKaku(
  List<int> yobiint2,
  int idx0,
  int idx1,
  int univid,
  int keta,
) {
  if (univid < 0 || univid >= _ketasuu * 2) return;
  if (keta < 0 || keta > 9) return;
  final int idx = univid < _ketasuu ? idx0 : idx1;
  if (yobiint2.length <= idx) return;
  final int p = _juu(univid % _ketasuu);
  final int v = yobiint2[idx] < 0 ? 0 : yobiint2[idx];
  final int mae = (v ~/ p) % 10;
  yobiint2[idx] = v + (keta - mae) * p;
}

/// 大学のスカウト方針(0〜7、範囲外は0=自動)
int comScoutHoushin(KantokuData kantoku, int univid) {
  final int h = _univKetaYomu(
    kantoku.yobiint2,
    comScoutHoushinIndex0,
    comScoutHoushinIndex1,
    univid,
  );
  return h < comScoutHoushinMei.length ? h : 0;
}

/// 大学のスカウト方針(0〜7)をyobiint2のリストに書き込む(保存は呼び出し側で行う)
void comScoutHoushinSettei(List<int> yobiint2, int univid, int houshin) {
  if (houshin < 0 || houshin >= comScoutHoushinMei.length) return;
  _univKetaKaku(
    yobiint2,
    comScoutHoushinIndex0,
    comScoutHoushinIndex1,
    univid,
    houshin,
  );
}

/// 大学の性格(0〜3、範囲外は0=自動)
int comScoutSeikaku(KantokuData kantoku, int univid) {
  final int s = _univKetaYomu(
    kantoku.yobiint2,
    comScoutSeikakuIndex0,
    comScoutSeikakuIndex1,
    univid,
  );
  return s < comScoutSeikakuMei.length ? s : 0;
}

/// 大学の性格(0〜3)をyobiint2のリストに書き込む(保存は呼び出し側で行う)
void comScoutSeikakuSettei(List<int> yobiint2, int univid, int seikaku) {
  if (seikaku < 0 || seikaku >= comScoutSeikakuMei.length) return;
  _univKetaKaku(
    yobiint2,
    comScoutSeikakuIndex0,
    comScoutSeikakuIndex1,
    univid,
    seikaku,
  );
}

// ------------------------------------------------------------
// コンピュータの目利き(選手の点数)
// ------------------------------------------------------------

/// 大学ごとの目利き(その大学が新入生をどう評価するか)
class _Mekiki {
  final int univid;
  final int houshin; // スカウト方針(0〜7)
  final int seikaku; // 性格(1〜3。自動は名声順位で決めたもの)
  final List<int> hokyou; // 自動のときの補強ポイント(3登り・4下り・5アップダウン)

  _Mekiki({
    required this.univid,
    required this.houshin,
    required this.seikaku,
    required this.hokyou,
  });

  /// 能力点(重視する能力の重み付き平均)
  double nouryokuTen(SenshuData s) {
    final List<List<int>> atai = []; // [能力値, 重み]
    switch (houshin) {
      case 1: // スピード重視
        atai.add([s.spurtryoku, 1]);
        atai.add([s.paceagesagetaiouryoku, 1]);
        break;
      case 2: // 距離重視
        atai.add([s.choukyorinebari, 1]);
        atai.add([s.tandokusou, 1]);
        break;
      case 3: // 登り重視
        atai.add([s.noboritekisei, 1]);
        break;
      case 4: // 下り重視
        atai.add([s.kudaritekisei, 1]);
        break;
      case 5: // アップダウン重視
        atai.add([s.noborikudarikirikaenouryoku, 1]);
        break;
      case 6: // メンタル重視
        atai.add([s.konjou, 1]);
        atai.add([s.heijousin, 1]);
        atai.add([s.anteikan, 1]);
        break;
      default: // 自動
        atai.add([s.choukyorinebari, 2]);
        atai.add([s.tandokusou, 2]);
        atai.add([s.paceagesagetaiouryoku, 1]);
        for (final int menu in hokyou) {
          atai.add([_menuNouryoku(s, menu), 2]);
        }
    }
    int goukei = 0;
    int omomi = 0;
    for (final List<int> a in atai) {
      goukei += a[0] * a[1];
      omomi += a[1];
    }
    return omomi == 0 ? 0 : goukei / omomi;
  }

  /// 点数(タイム点×0.5+能力点×0.5。タイム重視はタイム点だけ)
  double ten(SenshuData s, Map<int, double> timeTen) {
    final double t = timeTen[s.id] ?? 0;
    if (houshin == _houshinTime) return t;
    return t * 0.5 + nouryokuTen(s) * 0.5;
  }

  /// 狙いの理由(方針。自動は実際に重視したもの)
  String get houshinRiyuu {
    if (houshin != _houshinJidou) return comScoutHoushinMei[houshin];
    if (hokyou.isEmpty) return '距離・ロード重視';
    return '${hokyou.map(_menuMei).join('・')}の補強';
  }

  /// 狙いの理由(方針・性格) 例: 登り重視・大物狙い
  String get riyuu => '$houshinRiyuu・${comScoutSeikakuMei[seikaku]}';
}

/// 山の能力(3登り・4下り・5アップダウン)の値
int _menuNouryoku(SenshuData s, int menu) {
  switch (menu) {
    case 3:
      return s.noboritekisei;
    case 4:
      return s.kudaritekisei;
    case 5:
      return s.noborikudarikirikaenouryoku;
    default:
      return 0;
  }
}

String _menuMei(int menu) {
  switch (menu) {
    case 3:
      return '登り';
    case 4:
      return '下り';
    case 5:
      return 'アップダウン';
    default:
      return '';
  }
}

/// 大学の目利きを作る(補強ポイントはこの時点の選手で判定する)
_Mekiki _mekikiTsukuru(
  KantokuData kantoku,
  UnivData univ,
  List<SenshuData> zenSenshu,
) {
  final int houshin = comScoutHoushin(kantoku, univ.id);
  int seikaku = comScoutSeikaku(kantoku, univ.id);
  if (seikaku == 0) {
    // 自動: 名声順位(0が1位)で決める
    if (univ.meiseijuni <= 4) {
      seikaku = _seikakuOomono;
    } else if (univ.meiseijuni <= 14) {
      seikaku = _seikakuBalance;
    } else {
      seikaku = _seikakuKenjitsu;
    }
  }
  final List<int> hokyou = [];
  if (houshin == _houshinJidou) {
    // 来年も残る1〜3年生に、得意な選手が2人いない山の能力を補強ポイントにする
    final List<SenshuData> nokoru = zenSenshu
        .where((s) => s.univid == univ.id && s.gakunen >= 1 && s.gakunen <= 3)
        .toList();
    for (final int menu in [3, 4, 5]) {
      final int tokui = nokoru
          .where((s) => _menuNouryoku(s, menu) >= _tokuiSakaime)
          .length;
      if (tokui < _tokuiNinzuu) hokyou.add(menu);
    }
  }
  return _Mekiki(
    univid: univ.id,
    houshin: houshin,
    seikaku: seikaku,
    hokyou: hokyou,
  );
}

/// タイム点(留学生を除く新入生の中での5000m持ちタイムの順位を、1位100点〜最下位0点にしたもの)
Map<int, double> _timeTenTsukuru(List<SenshuData> shinnyuusei) {
  final List<SenshuData> narabi =
      shinnyuusei.where((s) => s.hirou != 1).toList()..sort((a, b) {
        final int c = a.kiroku_nyuugakuji_5000.compareTo(
          b.kiroku_nyuugakuji_5000,
        );
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  final int n = narabi.length;
  return {
    for (int i = 0; i < n; i++)
      narabi[i].id: n <= 1 ? 100.0 : 100.0 * (n - 1 - i) / (n - 1),
  };
}

/// 交渉する大学から見た、新入生の5000m持ちタイムの順位(1から)
/// (交渉する大学以外の新入生の中で。プレイヤーのスカウト画面と同じ)
Map<int, int> _timeJuniTsukuru(List<SenshuData> shinnyuusei, int univid) {
  final List<SenshuData> narabi =
      shinnyuusei.where((s) => s.univid != univid).toList()..sort((a, b) {
        final int c = a.kiroku_nyuugakuji_5000.compareTo(
          b.kiroku_nyuugakuji_5000,
        );
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  return {for (int i = 0; i < narabi.length; i++) narabi[i].id: i + 1};
}

/// 交渉の成功率(プレイヤーのスカウト画面と同じ式。1%単位に丸め、1%未満は0.1%)
double _seikouritsu({
  required UnivData kousyouUniv,
  required UnivData motoUniv,
  required int timeJuni,
}) {
  double meiseiHi;
  if (kousyouUniv.meisei_total + motoUniv.meisei_total > 0) {
    meiseiHi =
        kousyouUniv.meisei_total /
        (kousyouUniv.meisei_total + motoUniv.meisei_total);
  } else {
    meiseiHi = 0.5;
  }
  meiseiHi = meiseiHi.clamp(0.001, 0.9);
  final double jougen = (0.10 + (timeJuni - 1) * (0.75 - 0.10) / (87.0 - 1.0))
      .clamp(0.10, 0.75);
  final double p = min(meiseiHi, jougen);
  if (p < 0.01) return 0.001;
  return (p * 100).round() / 100.0;
}

/// 性格に合わせた狙う値
double _neraiAtai(int seikaku, double uwazumi, double p) {
  switch (seikaku) {
    case _seikakuOomono:
      return uwazumi * uwazumi * p;
    case _seikakuKenjitsu:
      return uwazumi * p * p;
    default:
      return uwazumi * p;
  }
}

/// 値の重みを付けて、リストから1つ選ぶ(値がすべて0以下なら先頭)
int _omomiChuusen(List<double> omomi, Random random) {
  double goukei = 0;
  for (final double w in omomi) {
    if (w > 0) goukei += w;
  }
  if (goukei <= 0) return 0;
  double r = random.nextDouble() * goukei;
  for (int i = 0; i < omomi.length; i++) {
    if (omomi[i] <= 0) continue;
    if (r < omomi[i]) return i;
    r -= omomi[i];
  }
  return omomi.length - 1;
}

// ------------------------------------------------------------
// ラウンドと放出
// ------------------------------------------------------------

/// 交渉・放出の結果1件分
class ComScoutKekka {
  final int kousyouUnivid; // 交渉した大学(放出の場合は放出した大学)
  final int senshuId;
  final String senshuName;
  final int motoUnivid; // 交渉のときの所属校(放出の場合は放出した大学)
  final bool seikou; // 交渉が成立したか(放出の場合はtrue)
  final int kimariUnivid; // 最終的に決まった大学(放出の場合は入学先)
  final String riyuu; // 狙いの理由(コンピュータのみ。例: 登り重視・大物狙い)
  final bool houshutsu; // 放出の結果かどうか

  ComScoutKekka({
    required this.kousyouUnivid,
    required this.senshuId,
    required this.senshuName,
    required this.motoUnivid,
    required this.seikou,
    required this.kimariUnivid,
    required this.riyuu,
    this.houshutsu = false,
  });
}

/// 1件分の交渉(判定前)
class _Kousyou {
  final int univid;
  final SenshuData senshu;
  final int motoUnivid;
  final bool seikou;
  final String riyuu;
  _Kousyou({
    required this.univid,
    required this.senshu,
    required this.motoUnivid,
    required this.seikou,
    required this.riyuu,
  });
}

List<UnivData> _sortedUnivData() {
  return Hive.box<UnivData>('univBox').values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

List<SenshuData> _sortedSenshuData() {
  return Hive.box<SenshuData>('senshuBox').values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

/// 1ラウンド分の新入生スカウト
/// プレイヤーの交渉([playerTarget]、nullなら見送り)と、コンピュータの各大学の交渉を
/// 一斉に判定し、選手の所属を書き換えて保存する。戻り値はこのラウンドの交渉の結果
/// (コンピュータの交渉はONのときだけ行う)
Future<List<ComScoutKekka>> comScoutRound({
  required Ghensuu gh,
  required int roundBangou, // デバッグログ用(1から)
  SenshuData? playerTarget,
  double playerSeikouritsu = 0.0,
  Random? random,
}) async {
  final Random rnd = random ?? Random();
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  final List<UnivData> sortedUnivData = _sortedUnivData();
  final List<SenshuData> zenSenshu = _sortedSenshuData();
  final List<SenshuData> shinnyuusei = zenSenshu
      .where((s) => s.gakunen == 1)
      .toList();
  final int myUnivid = gh.MYunivid;
  final List<_Kousyou> kousyouList = [];

  // プレイヤーの交渉
  if (playerTarget != null &&
      playerTarget.hirou != 1 &&
      playerTarget.univid != myUnivid) {
    final bool seikou = rnd.nextDouble() < playerSeikouritsu;
    kousyouList.add(
      _Kousyou(
        univid: myUnivid,
        senshu: playerTarget,
        motoUnivid: playerTarget.univid,
        seikou: seikou,
        riyuu: '',
      ),
    );
    if (kDebugMode) {
      print(
        '[COMスカウト] ラウンド$roundBangou プレイヤー → ${playerTarget.name}'
        '(${sortedUnivData[playerTarget.univid].name}) '
        '成功率${(playerSeikouritsu * 100).toStringAsFixed(1)}% '
        '${seikou ? '成功' : '失敗'}',
      );
    }
  }

  // コンピュータの交渉(このラウンドの始めの状態で、全大学が一斉に決める)
  if (kantoku != null && isComScoutOn(kantoku)) {
    final Map<int, double> timeTen = _timeTenTsukuru(shinnyuusei);
    final int sekkyoku = comScoutSekkyokusei(kantoku);
    for (final UnivData univ in sortedUnivData) {
      if (univ.id == myUnivid) continue;
      if (rnd.nextInt(100) >= sekkyoku) continue; // このラウンドは動かない
      final _Mekiki m = _mekikiTsukuru(kantoku, univ, zenSenshu);
      final Map<int, int> timeJuni = _timeJuniTsukuru(shinnyuusei, univ.id);

      // 自校の新入生(留学生を除く)のいちばん低い点数
      final List<double> jikoTen = shinnyuusei
          .where((s) => s.univid == univ.id && s.hirou != 1)
          .map((s) => m.ten(s, timeTen))
          .toList();
      final double saitei = jikoTen.isEmpty ? -1.0 : jikoTen.reduce(min);

      // 候補(他校の留学生以外で、自校のいちばん低い点数より点数が高い選手)
      final List<_Kouho> kouho = [];
      for (final SenshuData s in shinnyuusei) {
        if (s.univid == univ.id || s.hirou == 1) continue;
        final double uwazumi = m.ten(s, timeTen) - saitei;
        if (uwazumi <= 0) continue;
        final double p = _seikouritsu(
          kousyouUniv: univ,
          motoUniv: sortedUnivData[s.univid],
          timeJuni: timeJuni[s.id] ?? 999,
        );
        kouho.add(
          _Kouho(
            senshu: s,
            uwazumi: uwazumi,
            p: p,
            atai: _neraiAtai(m.seikaku, uwazumi, p),
          ),
        );
      }
      if (kouho.isEmpty) {
        if (kDebugMode) {
          print(
            '[COMスカウト] ラウンド$roundBangou ${univ.name}(${m.riyuu}) → 狙う選手なし(見送り)',
          );
        }
        continue;
      }
      kouho.sort((a, b) => b.atai.compareTo(a.atai));
      final List<_Kouho> jouI = kouho.take(3).toList();
      final _Kouho nerai =
          jouI[_omomiChuusen(jouI.map((k) => k.atai).toList(), rnd)];
      final bool seikou = rnd.nextDouble() < nerai.p;
      kousyouList.add(
        _Kousyou(
          univid: univ.id,
          senshu: nerai.senshu,
          motoUnivid: nerai.senshu.univid,
          seikou: seikou,
          riyuu: m.riyuu,
        ),
      );
      if (kDebugMode) {
        final String kouhoStr = jouI
            .map(
              (k) =>
                  '${k.senshu.name}(上積み${k.uwazumi.toStringAsFixed(1)}・'
                  '成功率${(k.p * 100).toStringAsFixed(1)}%)',
            )
            .join(' / ');
        print(
          '[COMスカウト] ラウンド$roundBangou ${univ.name}(${m.riyuu}) '
          '自校の最低点${saitei.toStringAsFixed(1)} 上位候補: $kouhoStr '
          '→ ${nerai.senshu.name}(${sortedUnivData[nerai.senshu.univid].name})に交渉 '
          '${seikou ? '成功' : '失敗'}',
        );
      }
    }
  }

  // 成功した交渉を選手ごとにまとめ、名声の重みを付けた抽選で1校に決める
  final Map<int, List<_Kousyou>> seikouBetsu = {};
  for (final _Kousyou k in kousyouList) {
    if (!k.seikou) continue;
    seikouBetsu.putIfAbsent(k.senshu.id, () => []).add(k);
  }
  final Map<int, int> kimari = {}; // 選手id → 決まった大学
  for (final MapEntry<int, List<_Kousyou>> e in seikouBetsu.entries) {
    final List<_Kousyou> list = e.value;
    final int idx = list.length == 1
        ? 0
        : _omomiChuusen(
            list
                .map(
                  (k) =>
                      max(1, sortedUnivData[k.univid].meisei_total).toDouble(),
                )
                .toList(),
            rnd,
          );
    final _Kousyou kachi = list[idx];
    kimari[e.key] = kachi.univid;
    kachi.senshu.univid = kachi.univid;
    await kachi.senshu.save();
    if (kDebugMode && list.length > 1) {
      print(
        '[COMスカウト] ラウンド$roundBangou ${kachi.senshu.name}は'
        '${list.map((k) => sortedUnivData[k.univid].name).join('・')}が競合 → '
        '${sortedUnivData[kachi.univid].name}に決定',
      );
    }
  }

  return [
    for (final _Kousyou k in kousyouList)
      ComScoutKekka(
        kousyouUnivid: k.univid,
        senshuId: k.senshu.id,
        senshuName: k.senshu.name,
        motoUnivid: k.motoUnivid,
        seikou: k.seikou,
        kimariUnivid: kimari[k.senshu.id] ?? k.motoUnivid,
        riyuu: k.riyuu,
      ),
  ];
}

/// 候補1人分
class _Kouho {
  final SenshuData senshu;
  final double uwazumi;
  final double p;
  final double atai;
  _Kouho({
    required this.senshu,
    required this.uwazumi,
    required this.p,
    required this.atai,
  });
}

/// スカウトが終わったあと、新入生が5人を超えたコンピュータの大学が放出する
/// (自校の方針での点数がいちばん低い選手から。留学生は放出しない)
/// 放出した選手は、欠員のある大学(プレイヤーの大学も含む)にランダムに入れる
/// プレイヤーの大学が5人を超えた場合は、このあと放出の画面で選ぶ
Future<List<ComScoutKekka>> comScoutHoushutsu({
  required Ghensuu gh,
  Random? random,
}) async {
  final Random rnd = random ?? Random();
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null) return [];
  final List<UnivData> sortedUnivData = _sortedUnivData();
  final List<SenshuData> zenSenshu = _sortedSenshuData();
  final List<SenshuData> shinnyuusei = zenSenshu
      .where((s) => s.gakunen == 1)
      .toList();
  final int myUnivid = gh.MYunivid;

  final Map<int, int> ninzuu = {};
  for (final SenshuData s in shinnyuusei) {
    ninzuu[s.univid] = (ninzuu[s.univid] ?? 0) + 1;
  }
  // 欠員の枠(欠員の数だけ大学idを並べる)
  final List<int> ketsuin = [];
  for (final UnivData univ in sortedUnivData) {
    final int n = ninzuu[univ.id] ?? 0;
    for (int i = n; i < TEISUU.NINZUU_1GAKUNEN_INUNIV; i++) {
      ketsuin.add(univ.id);
    }
  }
  ketsuin.shuffle(rnd);

  final Map<int, double> timeTen = _timeTenTsukuru(shinnyuusei);
  final List<ComScoutKekka> kekka = [];
  for (final UnivData univ in sortedUnivData) {
    if (univ.id == myUnivid) continue;
    final int chouka = (ninzuu[univ.id] ?? 0) - TEISUU.NINZUU_1GAKUNEN_INUNIV;
    if (chouka <= 0) continue;
    final _Mekiki m = _mekikiTsukuru(kantoku, univ, zenSenshu);
    final List<SenshuData> jiko =
        shinnyuusei.where((s) => s.univid == univ.id && s.hirou != 1).toList()
          ..sort((a, b) {
            final int c = m.ten(a, timeTen).compareTo(m.ten(b, timeTen));
            return c != 0 ? c : b.id.compareTo(a.id);
          });
    for (int i = 0; i < chouka && i < jiko.length && ketsuin.isNotEmpty; i++) {
      final SenshuData s = jiko[i];
      final int saki = ketsuin.removeLast();
      s.univid = saki;
      await s.save();
      kekka.add(
        ComScoutKekka(
          kousyouUnivid: univ.id,
          senshuId: s.id,
          senshuName: s.name,
          motoUnivid: univ.id,
          seikou: true,
          kimariUnivid: saki,
          riyuu: m.houshinRiyuu,
          houshutsu: true,
        ),
      );
      if (kDebugMode) {
        print(
          '[COMスカウト] 放出 ${univ.name}(${m.houshinRiyuu}) → ${s.name}'
          '(点数${m.ten(s, timeTen).toStringAsFixed(1)})を${sortedUnivData[saki].name}へ',
        );
      }
    }
  }
  return kekka;
}

/// スキップ中のスカウト(ONなら、コンピュータだけで全ラウンドを行い、放出まで済ませる)
/// 4月5日の処理(年度替わり)の最後に呼ぶ
Future<void> comScoutSkip({required Ghensuu gh}) async {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null || !isComScoutOn(kantoku)) return;
  final Random rnd = Random();
  final int kaisuu = comScoutKaisuu(kantoku);
  for (int r = 1; r <= kaisuu; r++) {
    await comScoutRound(gh: gh, roundBangou: r, random: rnd);
  }
  await comScoutHoushutsu(gh: gh, random: rnd);
}

/// 結果を、画面に出す文にする(プレイヤーに関係するものを先に)
List<String> comScoutKekkaBun(List<ComScoutKekka> kekka, int myUnivid) {
  final List<UnivData> sortedUnivData = _sortedUnivData();
  String mei(int univid) => (univid >= 0 && univid < sortedUnivData.length)
      ? '${sortedUnivData[univid].name}大学'
      : '不明な大学';

  final List<String> jibun = []; // プレイヤーの交渉
  final List<String> jikoSenshu = []; // プレイヤーの新入生への交渉
  final List<String> hoka = []; // ほかの大学の獲得
  final List<String> houshutsuJiko = []; // プレイヤーの大学に入る放出
  final List<String> houshutsuHoka = []; // ほかの放出

  for (final ComScoutKekka k in kekka) {
    if (k.houshutsu) {
      if (k.kimariUnivid == myUnivid) {
        houshutsuJiko.add(
          '【入学】${mei(k.motoUnivid)}が放出した${k.senshuName}選手が、あなたの大学に入学します',
        );
      } else {
        houshutsuHoka.add(
          '${mei(k.motoUnivid)}が${k.senshuName}選手を放出し、${mei(k.kimariUnivid)}に入学',
        );
      }
      continue;
    }
    if (k.kousyouUnivid == myUnivid) {
      if (k.seikou && k.kimariUnivid == myUnivid) {
        jibun.add(
          '【獲得】${k.senshuName}選手(${mei(k.motoUnivid)})の獲得に成功しました！',
        );
      } else if (k.seikou) {
        jibun.add(
          '【競合】${k.senshuName}選手との交渉は成立しましたが、${mei(k.kimariUnivid)}と競合し、'
          '${mei(k.kimariUnivid)}に決まりました',
        );
      } else {
        jibun.add('【失敗】${k.senshuName}選手(${mei(k.motoUnivid)})との交渉は失敗しました');
      }
      continue;
    }
    if (k.motoUnivid == myUnivid) {
      if (k.seikou && k.kimariUnivid == k.kousyouUnivid) {
        jikoSenshu.add(
          '【流出】${mei(k.kousyouUnivid)}(${k.riyuu})が、あなたの${k.senshuName}選手を獲得しました',
        );
      } else if (!k.seikou) {
        jikoSenshu.add(
          '【防衛】${mei(k.kousyouUnivid)}(${k.riyuu})があなたの${k.senshuName}選手に交渉しましたが、失敗しました',
        );
      }
      continue;
    }
    if (k.seikou && k.kimariUnivid == k.kousyouUnivid) {
      hoka.add(
        '${mei(k.kousyouUnivid)}(${k.riyuu})が${k.senshuName}選手(${mei(k.motoUnivid)})を獲得',
      );
    }
  }
  return [...jibun, ...jikoSenshu, ...houshutsuJiko, ...hoka, ...houshutsuHoka];
}
