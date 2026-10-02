import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // TEISUU
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/ShozokusakiKettei_By_Univmeisei.dart'; // 振り分けの抽選の重み

// ------------------------------------------------------------
// コンピュータ大学の新入生スカウト(1.7.9)
//
// ・ON(初期値)のとき、新入生スカウトは「進路未定の新入生」を全大学で取り合う
//   ラウンド制の勧誘合戦になる
//   ・新入生は全員「進路未定」として扱う。年度替わりの処理で振り分けた大学(univid)は
//     中の仮の値で、どこにも見せず、最後にも使わない(プレイヤーにも、コンピュータにも)
//   ・プレイヤーが1回交渉するたびに、コンピュータの各大学も同じラウンドで1人ずつ交渉し、
//     結果を一斉に判定する。成功した大学に確定し(univid=その大学、kegaflag=-3)、
//     確定した選手はその年はもう交渉に応じない
//     (kegaflagはスカウト画面の成功率の表示に使っている欄。新入生を作るときに0に戻る)
//   ・交渉に失敗した選手とは、その大学はその年はもう交渉できない(全大学同じ)
//     プレイヤーの大学に断った選手はkegaflag=-5にして保存する(アプリを開き直しても交渉できない)
//     コンピュータの大学に断った選手は、アプリを終了するまで覚えておく(_comKotowari)
//   ・各大学が確定できるのは、日本人の新入生の枠(5人−その大学の留学生の新入生の人数)まで
//   ・ラウンド数は設定の回数(1〜10回、初期値3回)。プレイヤーがスカウトを終えたら、
//     残りのラウンドはコンピュータだけで行う
//   ・最後に、確定しなかった選手が「自ら志望して」進学先を選ぶ(今までの新入生の振り分けと
//     同じ抽選。持ちタイムの良い順に、名声の重みで、枠が残っている大学から選ぶ)。
//     どの大学も枠がちょうど埋まるので、放出は要らない
//   ・スキップ中(スカウト画面が出ないとき)は、4月5日の処理の最後にコンピュータだけで
//     全ラウンドと最後の志望を行う
// ・OFFのときは今まで通り(プレイヤーだけが3回交渉でき、結果はすぐに出る。放出の画面あり)
// ・成功率(ONのとき。仮の振り分けの大学によらないように、全大学の平均の名声と比べる)
//     名声の比 = 交渉する大学の名声 ÷ (交渉する大学の名声 + 全大学の平均の名声) (0.1%〜90%)
//     タイム順位による上限 = 新入生(留学生を除く)全体の中での5000m持ちタイムの順位で、
//       1位10%〜87位以下75%
//     成功率 = タイム順位による上限 × 名声の比 ÷ 75% (名声の比が75%以上なら上限のまま。
//       1%単位に丸め、1%未満は0.1%)
//     (トップ級の大学と、タイム87位以下の選手は「小さいほう」と同じ値になる。名声の高くない
//     大学ほど、持ちタイムの良い選手の成功率が下がる。どの大学も同じ10%で大物に挑めると、
//     成功率の低い大物を後回しにするコンピュータより、粘って大物を狙う人間が有利になるため)
// ・同じ選手に複数の大学が成功した場合は、名声の重みを付けた抽選で1校に決める(名声0は重み1)
// ・留学生は交渉の対象外(年度替わりの処理で決まった大学にそのまま入学する)
// ・コンピュータの判断(見るのは5000m持ちタイムと能力の値そのもの。個性の設定や、
//   プレイヤーにも見えない成長タイプ、仮の振り分けの大学は使わない)
//     点数 = タイム点(新入生の中での持ちタイムの順位を0〜100点にしたもの)×0.5
//            + 能力点(スカウト方針で重視する能力の重み付き平均)×0.5
//       (タイム重視はタイム点だけ)
//     スカウト方針(大学ごと、yobiint2[59]・[60]に1大学1桁)
//       0自動: 長距離粘り・ロード適性(重み2)、ペース変動対応力(重み1)と、チーム事情による
//         補強ポイント(重み2)。来年も残る2・3年生と自校に確定した新入生に、登り適性・
//         下り適性・アップダウン対応力が70以上の選手が2人いなければ、その能力を補強ポイントにする
//       1スピード重視(スパート力・ペース変動対応力)、2距離重視(長距離粘り・ロード適性)、
//       3登り重視、4下り重視、5アップダウン重視、6駅伝男重視(駅伝男だけ)、
//       7タイム重視
//       (1〜5は年間強化練習メニュー・銀の使い道と同じ番号)
//     性格(大学ごと、yobiint2[61]・[62]に1大学1桁)で、欲しい選手の要件を決める
//       要件: まだ進路未定の新入生(留学生を除く。自校に断った選手も除く)の中で、
//         自校の方針での点数が上位何%以内か
//       (人数は切り上げ。大物がいなくなれば、残りの中での上位へ自然に下がる)
//       1大物狙い: 上位5%、2バランス: 上位25%、3堅実: 上位50%
//       0自動: 名声順位1〜5位は大物狙い、6〜15位はバランス、16位以下は堅実
//     要件を満たす選手を成功率の高い順に並べる。同じ成功率なら点数の低い順
//       (要件ぎりぎりで、ほかの大学と取り合いになりにくい選手から。名声の低い大学は
//       ほとんどの選手が同じ成功率になるので、この順番で狙う選手が決まる)
//     全大学が同じ選手に集中しないように、上から3人を3:2:1の重みの抽選で選ぶ
//     積極性(全体): 各大学が1ラウンドで動く確率
// ・デバッグ実行時は、VS Codeのデバッグコンソールに「[COMスカウト]」で始まるログを出す
// ------------------------------------------------------------

/// KantokuData.yobiint2 の使用番号: コンピュータスカウトの設定
/// ラウンド回数のコード×10000 + OFFなら1000 + (100−積極性)
///   ラウンド回数のコード: 0なら3回(初期値)、1〜10ならその回数
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
  '駅伝男重視',
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

/// ラウンド回数の上限
const int comScoutKaisuuMax = 10;

/// ラウンド回数(1〜10回)
int comScoutKaisuu(KantokuData kantoku) {
  final int code = _settei(kantoku) ~/ 10000;
  return (code >= 1 && code <= comScoutKaisuuMax) ? code : 3;
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
  final int code = (kaisuu >= 1 && kaisuu <= comScoutKaisuuMax && kaisuu != 3)
      ? kaisuu
      : 0;
  yobiint2[comScoutSetteiIndex] = code * 10000 + (on ? 0 : 1000) + (100 - s);
}

/// 各種設定のQRコードから読んだ値が、正しい形かどうか
bool comScoutSetteiTadashii(int v) {
  if (v < 0) return false;
  final int code = v ~/ 10000;
  final int off = (v ~/ 1000) % 10;
  final int gyaku = v % 1000;
  return code <= comScoutKaisuuMax && off <= 1 && gyaku <= 100;
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
      case 6: // 駅伝男重視(駅伝男だけ)
        atai.add([s.konjou, 1]);
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
/// 補強ポイントの判定には、来年も残る2・3年生と、自校に確定した新入生だけを使う
/// (仮の振り分けの新入生は使わない)
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
    // 来年も残る選手に、得意な選手が2人いない山の能力を補強ポイントにする
    final List<SenshuData> nokoru = zenSenshu
        .where(
          (s) =>
              s.univid == univ.id &&
              ((s.gakunen >= 2 && s.gakunen <= 3) ||
                  (s.gakunen == 1 && s.hirou != 1 && comScoutKakutei(s))),
        )
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

/// 新入生(留学生を除く)全体の中での5000m持ちタイムの順位(1から)
Map<int, int> _timeJuniTsukuru(List<SenshuData> shinnyuusei) {
  final List<SenshuData> narabi =
      shinnyuusei.where((s) => s.hirou != 1).toList()..sort((a, b) {
        final int c = a.kiroku_nyuugakuji_5000.compareTo(
          b.kiroku_nyuugakuji_5000,
        );
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  return {for (int i = 0; i < narabi.length; i++) narabi[i].id: i + 1};
}

/// 全大学の平均の名声
double _heikinMeisei(List<UnivData> sortedUnivData) {
  if (sortedUnivData.isEmpty) return 0;
  int goukei = 0;
  for (final UnivData u in sortedUnivData) {
    goukei += u.meisei_total;
  }
  return goukei / sortedUnivData.length;
}

/// 成功率の計算で、タイム順位による上限のまま使える名声の比(これより低いと比に応じて下がる)
const double _meiseiHiKijun = 0.75;

/// 交渉の成功率(ONのとき。1%単位に丸め、1%未満は0.1%)
/// 名声の比は全大学の平均の名声と比べる(仮の振り分けの大学によらないように)
/// 成功率 = タイム順位による上限 × 名声の比 ÷ 75%(名声の比が75%以上なら上限のまま)
double _seikouritsu({
  required UnivData kousyouUniv,
  required double heikinMeisei,
  required int timeJuni,
}) {
  double meiseiHi;
  if (kousyouUniv.meisei_total + heikinMeisei > 0) {
    meiseiHi =
        kousyouUniv.meisei_total / (kousyouUniv.meisei_total + heikinMeisei);
  } else {
    meiseiHi = 0.5;
  }
  meiseiHi = meiseiHi.clamp(0.001, 0.9);
  final double jougen = (0.10 + (timeJuni - 1) * (0.75 - 0.10) / (87.0 - 1.0))
      .clamp(0.10, 0.75);
  final double p = jougen * min(1.0, meiseiHi / _meiseiHiKijun);
  if (p < 0.01) return 0.001;
  return (p * 100).round() / 100.0;
}

/// 性格ごとの要件(まだ進路未定の新入生の中で、自校の方針での点数が上位何%以内か)
int _youkenPercent(int seikaku) {
  switch (seikaku) {
    case _seikakuOomono:
      return 5;
    case _seikakuKenjitsu:
      return 50;
    default:
      return 25;
  }
}

/// 狙う選手を上から3人の中から選ぶときの重み(1番目3・2番目2・3番目1)
const List<double> _jouiOmomi = [3, 2, 1];

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
// 確定・枠・成功率
// ------------------------------------------------------------

/// スカウトで確定した選手のkegaflagの値(その年はもう交渉に応じない)
/// (kegaflagはスカウト画面の成功率の表示に使っている欄で、新入生を作るときに0に戻る)
const int comScoutKakuteiFlag = -3;

/// 最後の志望で入学が決まった選手のkegaflagの値
/// (アプリを開き直しても、志望の抽選をやり直さないように)
const int comScoutShiganFlag = -4;

/// プレイヤーの大学との交渉を断った選手のkegaflagの値(その年はもうプレイヤーの大学と交渉しない)
/// (進路はまだ決まっていないので、コンピュータの大学とは交渉できる。最後の志望で
/// プレイヤーの大学に入ることもある)
const int comScoutKotowariFlag = -5;

/// 選手が交渉で確定しているか
bool comScoutKakutei(SenshuData s) => s.kegaflag == comScoutKakuteiFlag;

/// 選手がプレイヤーの大学との交渉を断ったか
bool comScoutKotowarareta(SenshuData s) => s.kegaflag == comScoutKotowariFlag;

/// 選手の進学先が決まっているか(交渉で確定、または最後の志望で決定)
bool comScoutKettei(SenshuData s) =>
    s.kegaflag == comScoutKakuteiFlag || s.kegaflag == comScoutShiganFlag;

/// 大学の日本人の新入生の枠(5人−その大学の留学生の新入生の人数)
int comScoutWaku(List<SenshuData> shinnyuusei, int univid) {
  final int ryuugakusei = shinnyuusei
      .where((s) => s.univid == univid && s.hirou == 1)
      .length;
  return max(0, TEISUU.NINZUU_1GAKUNEN_INUNIV - ryuugakusei);
}

/// 大学に進学先が決まった新入生の人数(留学生を除く。交渉で確定した選手と、最後の志望で決まった選手)
int comScoutKetteiSuu(List<SenshuData> shinnyuusei, int univid) {
  return shinnyuusei
      .where((s) => s.univid == univid && s.hirou != 1 && comScoutKettei(s))
      .length;
}

/// 新入生(1年生)の一覧(id順)
List<SenshuData> comScoutShinnyuusei() {
  return _sortedSenshuData().where((s) => s.gakunen == 1).toList();
}

/// プレイヤーのスカウト画面に出す成功率(進路未定の新入生ごと。選手id → 成功率)
Map<int, double> comScoutSeikouritsuIchiran({required int univid}) {
  final List<UnivData> sortedUnivData = _sortedUnivData();
  if (univid < 0 || univid >= sortedUnivData.length) return {};
  final List<SenshuData> shinnyuusei = comScoutShinnyuusei();
  final Map<int, int> timeJuni = _timeJuniTsukuru(shinnyuusei);
  final double heikin = _heikinMeisei(sortedUnivData);
  return {
    for (final SenshuData s in shinnyuusei)
      if (s.hirou != 1 && !comScoutKettei(s) && !comScoutKotowarareta(s))
        s.id: _seikouritsu(
          kousyouUniv: sortedUnivData[univid],
          heikinMeisei: heikin,
          timeJuni: timeJuni[s.id] ?? 999,
        ),
  };
}

// ------------------------------------------------------------
// ラウンドと最後の志望
// ------------------------------------------------------------

/// コンピュータの大学との交渉を断った選手(大学id → 選手idの集まり)
/// 保存はせず、アプリを終了するまで覚えておく。年が変わったときと、
/// その年の1ラウンド目を始めるときに忘れる
final Map<int, Set<int>> _comKotowari = {};
int _comKotowariNen = -1;

/// コンピュータの大学[univid]との交渉を断った選手の集まり(年が変わっていたら忘れてから返す)
Set<int> _comKotowariSet(int nen, int univid) {
  if (_comKotowariNen != nen) {
    _comKotowari.clear();
    _comKotowariNen = nen;
  }
  return _comKotowari.putIfAbsent(univid, () => <int>{});
}

/// 交渉の結果1件分
class ComScoutKekka {
  final int kousyouUnivid; // 交渉した大学
  final int senshuId;
  final String senshuName;
  final bool seikou; // 交渉が成立したか
  final int kimariUnivid; // 確定した大学(成立しなかった場合は-1)
  final String riyuu; // 狙いの理由(コンピュータのみ。例: 登り重視・大物狙い)

  ComScoutKekka({
    required this.kousyouUnivid,
    required this.senshuId,
    required this.senshuName,
    required this.seikou,
    required this.kimariUnivid,
    required this.riyuu,
  });
}

/// 1ラウンドの、大学ごとの行動の種類
const int comScoutKoudouKousyou = 0; // 交渉した
const int comScoutKoudouMiokuri = 1; // 狙う選手なし(見送り)
const int comScoutKoudouUgokazu = 2; // 動かず(積極性)
const int comScoutKoudouWakuIppai = 3; // 枠がいっぱい
const int comScoutKoudouNashi = 4; // 交渉しなかった(プレイヤーがスカウトを終えたあとなど)

/// 1ラウンドの、大学ごとの行動(「ラウンドの結果」の画面で全大学分を出す)
class ComScoutKoudou {
  final int univid;
  final int shurui; // 行動の種類(comScoutKoudou〜)
  final String riyuu; // 方針・性格(コンピュータのみ。例: 登り重視・大物狙い)
  final int senshuId; // 交渉した選手(交渉したときだけ。それ以外は-1)
  final String senshuName;
  final double senshuTime; // 交渉した選手の5000m持ちタイム
  final bool seikou; // 交渉が成立したか
  final int kimariUnivid; // 交渉が成立した選手が確定した大学(成立しなかった場合は-1)
  final int ketteiSuu; // このラウンドのあとの、進学先が決まった新入生の人数
  final int waku; // 日本人の新入生の枠

  ComScoutKoudou({
    required this.univid,
    required this.shurui,
    required this.riyuu,
    required this.senshuId,
    required this.senshuName,
    required this.senshuTime,
    required this.seikou,
    required this.kimariUnivid,
    required this.ketteiSuu,
    required this.waku,
  });
}

/// 行動の記録をまとめるためのメモ(判定前)
class _KoudouMemo {
  final int shurui;
  final String riyuu;
  final SenshuData? senshu;
  final bool seikou;
  _KoudouMemo({
    required this.shurui,
    required this.riyuu,
    this.senshu,
    this.seikou = false,
  });
}

/// 1件分の交渉(判定前)
class _Kousyou {
  final int univid;
  final SenshuData senshu;
  final bool seikou;
  final String riyuu;
  _Kousyou({
    required this.univid,
    required this.senshu,
    required this.seikou,
    required this.riyuu,
  });
}

/// 候補1人分
class _Kouho {
  final SenshuData senshu;
  final double ten; // 自校の方針での点数
  final double p; // 成功率
  _Kouho({required this.senshu, required this.ten, required this.p});
}

List<UnivData> _sortedUnivData() {
  return Hive.box<UnivData>('univBox').values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

List<SenshuData> _sortedSenshuData() {
  return Hive.box<SenshuData>('senshuBox').values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

/// 1ラウンド分の新入生スカウト(ONのとき)
/// プレイヤーの交渉([playerTarget]、nullなら見送り)と、コンピュータの各大学の交渉を
/// 一斉に判定し、成功した選手を確定させて保存する。戻り値はこのラウンドの交渉の結果
/// [koudou] を渡すと、全大学のこのラウンドの行動(見送りなども含む)を大学id順に入れて返す
Future<List<ComScoutKekka>> comScoutRound({
  required Ghensuu gh,
  required int roundBangou, // ラウンドの番号(1から。1ならコンピュータの大学の断られた記憶を忘れてから始める)
  SenshuData? playerTarget,
  double playerSeikouritsu = 0.0,
  Random? random,
  List<ComScoutKoudou>? koudou,
}) async {
  final Random rnd = random ?? Random();
  if (roundBangou <= 1) {
    _comKotowari.clear(); // その年の1ラウンド目
  }
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
  final Map<int, _KoudouMemo> memo = {}; // 大学id → このラウンドの行動

  // プレイヤーの交渉(進路未定の選手だけ。枠がいっぱいなら交渉できない。断られた選手とも交渉できない)
  final bool playerWakuIppai =
      comScoutKetteiSuu(shinnyuusei, myUnivid) >=
      comScoutWaku(shinnyuusei, myUnivid);
  memo[myUnivid] = _KoudouMemo(
    shurui: playerWakuIppai ? comScoutKoudouWakuIppai : comScoutKoudouNashi,
    riyuu: '',
  );
  if (playerTarget != null &&
      playerTarget.hirou != 1 &&
      !comScoutKettei(playerTarget) &&
      !comScoutKotowarareta(playerTarget) &&
      !playerWakuIppai) {
    final bool seikou = rnd.nextDouble() < playerSeikouritsu;
    kousyouList.add(
      _Kousyou(
        univid: myUnivid,
        senshu: playerTarget,
        seikou: seikou,
        riyuu: '',
      ),
    );
    memo[myUnivid] = _KoudouMemo(
      shurui: comScoutKoudouKousyou,
      riyuu: '',
      senshu: playerTarget,
      seikou: seikou,
    );
    if (kDebugMode) {
      print(
        '[COMスカウト] ラウンド$roundBangou プレイヤー → ${playerTarget.name} '
        '成功率${(playerSeikouritsu * 100).toStringAsFixed(1)}% '
        '${seikou ? '成功' : '失敗'}',
      );
    }
  }

  // コンピュータの交渉(このラウンドの始めの状態で、全大学が一斉に決める)
  if (kantoku != null && isComScoutOn(kantoku)) {
    final Map<int, double> timeTen = _timeTenTsukuru(shinnyuusei);
    final Map<int, int> timeJuni = _timeJuniTsukuru(shinnyuusei);
    final double heikin = _heikinMeisei(sortedUnivData);
    final List<SenshuData> nihonjin = shinnyuusei
        .where((s) => s.hirou != 1)
        .toList();
    final int sekkyoku = comScoutSekkyokusei(kantoku);
    for (final UnivData univ in sortedUnivData) {
      if (univ.id == myUnivid) continue;
      final _Mekiki m = _mekikiTsukuru(kantoku, univ, zenSenshu);
      if (comScoutKetteiSuu(shinnyuusei, univ.id) >=
          comScoutWaku(shinnyuusei, univ.id)) {
        memo[univ.id] = _KoudouMemo(
          shurui: comScoutKoudouWakuIppai,
          riyuu: m.riyuu,
        );
        continue; // 枠がいっぱい
      }
      if (rnd.nextInt(100) >= sekkyoku) {
        memo[univ.id] = _KoudouMemo(
          shurui: comScoutKoudouUgokazu,
          riyuu: m.riyuu,
        );
        continue; // このラウンドは動かない
      }

      // まだ進路未定で、自校に断っていない選手を、自校の方針での点数の高い順に並べる
      final Set<int> kotowari = _comKotowariSet(gh.year, univ.id);
      final List<_Kouho> mitei = [];
      for (final SenshuData s in nihonjin) {
        if (comScoutKettei(s)) continue;
        if (kotowari.contains(s.id)) continue;
        mitei.add(
          _Kouho(
            senshu: s,
            ten: m.ten(s, timeTen),
            p: _seikouritsu(
              kousyouUniv: univ,
              heikinMeisei: heikin,
              timeJuni: timeJuni[s.id] ?? 999,
            ),
          ),
        );
      }
      mitei.sort((a, b) {
        final int c = b.ten.compareTo(a.ten);
        return c != 0 ? c : a.senshu.id.compareTo(b.senshu.id);
      });

      // 候補(性格の要件を満たす選手。交渉できる進路未定の選手の中で点数が上位何%以内か、人数は切り上げ)
      final int youkenNinzuu =
          (mitei.length * _youkenPercent(m.seikaku) + 99) ~/ 100;
      final List<_Kouho> kouho = mitei.take(youkenNinzuu).toList();
      if (kouho.isEmpty) {
        memo[univ.id] = _KoudouMemo(
          shurui: comScoutKoudouMiokuri,
          riyuu: m.riyuu,
        );
        if (kDebugMode) {
          print(
            '[COMスカウト] ラウンド$roundBangou ${univ.name}(${m.riyuu}) → 狙う選手なし(見送り)',
          );
        }
        continue;
      }
      // 成功率の高い順。同じ成功率なら点数の低い順(要件ぎりぎりで、取り合いになりにくい選手から)
      kouho.sort((a, b) {
        int c = b.p.compareTo(a.p);
        if (c != 0) return c;
        c = a.ten.compareTo(b.ten);
        return c != 0 ? c : a.senshu.id.compareTo(b.senshu.id);
      });
      // 上から3人を、3:2:1の重みの抽選で選ぶ
      final List<_Kouho> jouI = kouho.take(3).toList();
      final _Kouho nerai =
          jouI[_omomiChuusen(_jouiOmomi.take(jouI.length).toList(), rnd)];
      final bool seikou = rnd.nextDouble() < nerai.p;
      kousyouList.add(
        _Kousyou(
          univid: univ.id,
          senshu: nerai.senshu,
          seikou: seikou,
          riyuu: m.riyuu,
        ),
      );
      memo[univ.id] = _KoudouMemo(
        shurui: comScoutKoudouKousyou,
        riyuu: m.riyuu,
        senshu: nerai.senshu,
        seikou: seikou,
      );
      if (kDebugMode) {
        final String kouhoStr = jouI
            .map(
              (k) =>
                  '${k.senshu.name}(点数${k.ten.toStringAsFixed(1)}・'
                  '成功率${(k.p * 100).toStringAsFixed(1)}%)',
            )
            .join(' / ');
        print(
          '[COMスカウト] ラウンド$roundBangou ${univ.name}(${m.riyuu}) '
          '要件 交渉できる進路未定${mitei.length}人の上位${_youkenPercent(m.seikaku)}%($youkenNinzuu人) '
          '上位候補: $kouhoStr → ${nerai.senshu.name}に交渉 ${seikou ? '成功' : '失敗'}',
        );
      }
    }
  }

  // 成功した交渉を選手ごとにまとめ、名声の重みを付けた抽選で1校に決めて確定させる
  final Map<int, List<_Kousyou>> seikouBetsu = {};
  for (final _Kousyou k in kousyouList) {
    if (!k.seikou) continue;
    seikouBetsu.putIfAbsent(k.senshu.id, () => []).add(k);
  }
  final Map<int, int> kimari = {}; // 選手id → 確定した大学
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
    kachi.senshu.kegaflag = comScoutKakuteiFlag;
    await kachi.senshu.save();
    if (kDebugMode && list.length > 1) {
      print(
        '[COMスカウト] ラウンド$roundBangou ${kachi.senshu.name}は'
        '${list.map((k) => sortedUnivData[k.univid].name).join('・')}が競合 → '
        '${sortedUnivData[kachi.univid].name}に確定',
      );
    }
  }

  // 交渉に失敗した選手とは、その大学はその年はもう交渉しない
  // (プレイヤーの大学は目印を入れて保存し、コンピュータの大学はアプリを終了するまで覚える)
  for (final _Kousyou k in kousyouList) {
    if (k.seikou) continue;
    if (k.univid == myUnivid) {
      if (!comScoutKettei(k.senshu)) {
        // ほかの大学に確定していなければ
        k.senshu.kegaflag = comScoutKotowariFlag;
        await k.senshu.save();
      }
    } else {
      _comKotowariSet(gh.year, k.univid).add(k.senshu.id);
    }
  }

  // 全大学のこのラウンドの行動(確定人数は、このラウンドの確定を反映したあとの人数)
  if (koudou != null) {
    for (final UnivData univ in sortedUnivData) {
      final _KoudouMemo mm =
          memo[univ.id] ??
          _KoudouMemo(shurui: comScoutKoudouNashi, riyuu: '');
      final SenshuData? s = mm.senshu;
      koudou.add(
        ComScoutKoudou(
          univid: univ.id,
          shurui: mm.shurui,
          riyuu: mm.riyuu,
          senshuId: s?.id ?? -1,
          senshuName: s?.name ?? '',
          senshuTime: s?.kiroku_nyuugakuji_5000 ?? TEISUU.DEFAULTTIME,
          seikou: mm.seikou,
          kimariUnivid: s == null ? -1 : (kimari[s.id] ?? -1),
          ketteiSuu: comScoutKetteiSuu(shinnyuusei, univ.id),
          waku: comScoutWaku(shinnyuusei, univ.id),
        ),
      );
    }
  }

  return [
    for (final _Kousyou k in kousyouList)
      ComScoutKekka(
        kousyouUnivid: k.univid,
        senshuId: k.senshu.id,
        senshuName: k.senshu.name,
        seikou: k.seikou,
        kimariUnivid: kimari[k.senshu.id] ?? -1,
        riyuu: k.riyuu,
      ),
  ];
}

/// スカウトの最後に、確定しなかった選手が自ら志望して進学先を選ぶ(ONのとき)
/// 今までの新入生の振り分けと同じ抽選(持ちタイムの良い順に、名声の重みで、
/// 日本人の新入生の枠が残っている大学から選ぶ)。戻り値は 選手id → 入学した大学
Future<Map<int, int>> comScoutShigan({
  required Ghensuu gh,
  Random? random,
}) async {
  final Random rnd = random ?? Random();
  final List<UnivData> sortedUnivData = _sortedUnivData();
  final List<SenshuData> shinnyuusei = comScoutShinnyuusei();
  final List<int> nokoriWaku = [
    for (final UnivData u in sortedUnivData)
      max(
        0,
        comScoutWaku(shinnyuusei, u.id) - comScoutKetteiSuu(shinnyuusei, u.id),
      ),
  ];
  final List<int> omomi = shozokuChuusenOmomi(
    sortedunivdata: sortedUnivData,
    ghensuu: gh,
  );
  final List<SenshuData> mikakutei =
      shinnyuusei.where((s) => s.hirou != 1 && !comScoutKettei(s)).toList()
        ..sort((a, b) {
          final int c = a.kiroku_nyuugakuji_5000.compareTo(
            b.kiroku_nyuugakuji_5000,
          );
          return c != 0 ? c : a.id.compareTo(b.id);
        });

  final Map<int, int> kekka = {};
  for (final SenshuData s in mikakutei) {
    final List<int> kouho = [
      for (int i = 0; i < nokoriWaku.length; i++)
        if (nokoriWaku[i] > 0) i,
    ];
    if (kouho.isEmpty) {
      // 枠が残っていない(通常は起こらない)。仮の振り分けの大学のまま
      if (kDebugMode) {
        print('[COMスカウト] 志望 ${s.name}: 枠の残っている大学がないため、そのまま');
      }
      continue;
    }
    List<double> w = [
      for (final int k in kouho)
        max(0, k < omomi.length ? omomi[k] : 0).toDouble(),
    ];
    if (w.every((x) => x <= 0)) {
      w = [for (int i = 0; i < kouho.length; i++) 1.0];
    }
    final int saki = kouho[_omomiChuusen(w, rnd)];
    s.univid = saki;
    s.kegaflag = comScoutShiganFlag; // 志望で決定(開き直しても抽選し直さない)
    nokoriWaku[saki]--;
    await s.save();
    kekka[s.id] = saki;
    if (kDebugMode) {
      print('[COMスカウト] 志望 ${s.name} → ${sortedUnivData[saki].name}');
    }
  }
  return kekka;
}

/// スキップ中のスカウト(ONなら、コンピュータだけで全ラウンドを行い、最後の志望まで済ませる)
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
  await comScoutShigan(gh: gh, random: rnd);
}

/// 1.7.8でスカウト画面の途中だったセーブデータ用の移行処理
/// プレイヤーの大学の新入生(留学生を除く)を確定扱いにする
/// (1.7.8の交渉で獲得した選手が、最後の志望で入れ替わらないように)
Future<void> comScoutIkouKakutei({required Ghensuu gh}) async {
  for (final SenshuData s in _sortedSenshuData()) {
    if (s.gakunen == 1 && s.univid == gh.MYunivid && s.hirou != 1) {
      s.kegaflag = comScoutKakuteiFlag;
      await s.save();
    }
  }
}

String _univMei(List<UnivData> sortedUnivData, int univid) =>
    (univid >= 0 && univid < sortedUnivData.length)
    ? '${sortedUnivData[univid].name}大学'
    : '不明な大学';

String _timeMoji(double time) {
  if (time == TEISUU.DEFAULTTIME) return '記録なし';
  final int m = (time / 60).floor();
  final int s = (time % 60).floor();
  return '$m分${s.toString().padLeft(2, '0')}秒';
}

/// ラウンドの結果を、画面に出す文にする(プレイヤーの交渉を先に)
/// [jibunNomi] がtrueなら、プレイヤーの交渉の結果だけ
List<String> comScoutKekkaBun(
  List<ComScoutKekka> kekka,
  int myUnivid, {
  bool jibunNomi = false,
}) {
  final List<UnivData> sortedUnivData = _sortedUnivData();
  final List<String> jibun = []; // プレイヤーの交渉
  final List<String> hoka = []; // ほかの大学の確定
  for (final ComScoutKekka k in kekka) {
    if (k.kousyouUnivid == myUnivid) {
      if (k.seikou && k.kimariUnivid == myUnivid) {
        jibun.add('【確定】${k.senshuName}選手があなたの大学に確定しました！');
      } else if (k.seikou) {
        final String mei = _univMei(sortedUnivData, k.kimariUnivid);
        jibun.add(
          '【競合】${k.senshuName}選手との交渉は成立しましたが、$meiと競合し、$meiに確定しました',
        );
      } else {
        jibun.add(
          '【失敗】${k.senshuName}選手との交渉は失敗しました(この選手とは、今年はもう交渉できません)',
        );
      }
      continue;
    }
    if (k.seikou && k.kimariUnivid == k.kousyouUnivid) {
      hoka.add(
        '${_univMei(sortedUnivData, k.kousyouUnivid)}(${k.riyuu})が'
        '${k.senshuName}選手を確定',
      );
    }
  }
  return jibunNomi ? jibun : [...jibun, ...hoka];
}

/// 「ラウンドの結果」の画面に出す、大学の行動の文
String comScoutKoudouBun(ComScoutKoudou k) {
  switch (k.shurui) {
    case comScoutKoudouKousyou:
      final String kekka;
      if (!k.seikou) {
        kekka = '失敗';
      } else if (k.kimariUnivid == k.univid) {
        kekka = '確定';
      } else {
        final String mei = _univMei(_sortedUnivData(), k.kimariUnivid);
        kekka = '成立したが$meiと競合し、確定ならず';
      }
      return '${k.senshuName}選手(5000m ${_timeMoji(k.senshuTime)})に交渉 → $kekka';
    case comScoutKoudouMiokuri:
      return '狙う選手なし(見送り)';
    case comScoutKoudouUgokazu:
      return '動かず';
    case comScoutKoudouWakuIppai:
      return '枠がいっぱい';
    default:
      return '交渉しなかった';
  }
}

/// スカウトの最後に出す、プレイヤーの大学に入学する新入生の一覧
/// [shigan] 最後の志望で決まった選手(選手id → 大学)
List<String> comScoutNyuugakuBun({
  required int myUnivid,
  required Map<int, int> shigan,
}) {
  final List<SenshuData> jiko =
      comScoutShinnyuusei().where((s) => s.univid == myUnivid).toList()
        ..sort((a, b) {
          final int c = a.kiroku_nyuugakuji_5000.compareTo(
            b.kiroku_nyuugakuji_5000,
          );
          return c != 0 ? c : a.id.compareTo(b.id);
        });
  final List<String> kakutei = [];
  final List<String> shiganBun = [];
  final List<String> hoka = [];
  for (final SenshuData s in jiko) {
    final String time = _timeMoji(s.kiroku_nyuugakuji_5000);
    if (s.hirou == 1) {
      hoka.add('【留学生】${s.name}選手が入学します');
    } else if (comScoutKakutei(s)) {
      kakutei.add('【確定】${s.name}選手(5000m $time)');
    } else if (shigan[s.id] == myUnivid || s.kegaflag == comScoutShiganFlag) {
      shiganBun.add('【志望】${s.name}選手が自ら志望して入学します(5000m $time)');
    } else {
      hoka.add('${s.name}選手(5000m $time)');
    }
  }
  return [...kakutei, ...shiganBun, ...hoka];
}
