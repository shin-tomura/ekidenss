import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:ekiden/constants.dart'; // TrainingMenu
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/kingin_wariai.dart'; // 難易度ごとの金銀支給量の割合(1.9.1)
import 'package:hive_flutter/hive_flutter.dart';

// ------------------------------------------------------------
// コンピュータ大学の金銀使用
//
// ・支給量はプレイヤーと同じ式(金銀支給量倍率yobiint2[12]も共通)
// ・支給レベルは大学ごとに設定できる(yobiint2[38]・[39]に1大学1桁で格納)
//     0鬼(初期値)・1難・2普・3易: その難易度の支給量
//     4極鬼・5極難・6極普・7極易: 春の定期支給のみ(目標達成時はなし)
//     8天: 支給なし
//     9プレイヤーと同じ: プレイヤーの難易度(鬼・難・普・易)の支給量。「極」「天」は適用しない
// ・春の定期支給はプレイヤーと同じ4月5日(年度替わりの処理)、目標順位達成時は大会の後
// ・支給のたびに10%で金、90%で銀(プレイヤーと同じ)
// ・支給された金銀はすぐには使わず、大学ごとに保有しておき、
//   夏合宿(7月15日、夏の成長の直後)にまとめて使う(プレイヤーと同じ時期)
//   (秋以降に獲得した分は翌年の夏合宿で使う)
//   保有量は1の位まで持つ(yobiint2[42]〜[57])ので、支給量の10未満の端数も捨てない
// ・夏合宿の時点でOFFの場合と、プレイヤーの大学(移籍先)の保有分は、使わずに0にする
// ・振り分け先は留学生を除く10人(基本走力はa、小さいほど良い)
//     主力枠7人: 基本走力の上位7人(全学年)
//     下級生枠3人: 主力枠に入らなかった1・2年生のうち基本走力の上位3人
//       (1・2年生が足りない分は、主力枠の続きの選手で埋める)
//   「主力2人→下級生1人」の順番で並べ、上から順番に+10ずつ配る
//   (配る量が少ないときでも下級生に届くように)。
//   能力が上限の選手は飛ばして次の選手へ回す。
// ・金: 駅伝男(konjou)優先、次に平常心(heijousin)
// ・銀: 銀の使い道(大学ごとに設定、yobiint2[40]・[41]に1大学1桁で格納)に従う
//     0個人の練習メニュー通り(初期値): 各選手の年間強化練習メニュー(kaifukuryoku)
//       に対応する能力。バランスの選手は順番が回ってくるたびに、能力が上限でない
//       メニュー(1〜5)からランダムに選ぶ
//       (kaifukuryoku自体は変えない)
//     1〜5(大学方針): 10人全員がその練習メニューに対応する能力
//   練習メニューに対応する能力
//     1スピード→スパート力・ペース変動対応力
//     2距離走→長距離粘り・ロード適性
//       (スピード・距離走は、夏合宿ごとに選手ごとにどちらかをランダムに重点に決め、
//        重点の能力から上げて、上限ならもう一方を上げる。1.9.1。1.9.0までは低いほうから)
//     3登り→登り適性、4下り→下り適性、5アップダウン→アップダウン対応力
// ・カリスマ・安定感には使わない
// ・能力値が89以下の場合のみ+10(プレイヤーの金銀特訓と同じ上限)
// ・金: 10人全員の対象の能力が上限で使い切れなかった分は、銀に交換する
//   (金1→銀2、プレイヤーの金銀交換と同じ)。10未満の端数は金のまま翌年に持ち越す
// ・銀: 10人全員のメニュー(大学方針)の能力が上限で使い切れない場合は、10人の先頭から、
//   メニュー外の能力(カリスマ・安定感を除く7つのうち上限でないもの)から
//   ランダムに1つずつ上げる
// ・それでも使い切れない分は捨てる。銀の10未満の端数は翌年に持ち越す
// ------------------------------------------------------------

/// KantokuData.yobiint2 の使用番号: コンピュータ大学の金銀使用フラグ(0=ON(初期値)、1=OFF)
const int comGoldSilverFlagIndex = 33;

/// コンピュータ大学の金銀使用がONかどうか
bool isComGoldSilverOn(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= comGoldSilverFlagIndex) {
    return true;
  }
  return kantoku.yobiint2[comGoldSilverFlagIndex] == 0;
}

/// KantokuData.yobiint2 の使用番号: 大学ごとの金銀支給レベル
/// 1大学1桁(0〜9)で、[38]に大学0〜14、[39]に大学15〜29を格納する
/// 大学idを15で割った余りが桁の位置(0なら一の位、1なら十の位…)。
/// Hiveは整数をdoubleで保存するため、正確に残せる2の53乗(約9000兆)未満に
/// 収まるよう、1つあたり15桁までにしている
const int comGoldSilverLevelIndex0 = 38;
const int comGoldSilverLevelIndex1 = 39;
const int comGoldSilverLevelKetasuu = 15; // 1つに格納する大学数

/// 支給レベルの名前(0〜9)。0(鬼)が初期値
const List<String> comGoldSilverLevelMei = [
  '鬼',
  '難',
  '普',
  '易',
  '極鬼',
  '極難',
  '極普',
  '極易',
  '天',
  'プレイヤーと同じ',
];
const int _levelPlayerToOnaji = 9; // プレイヤーと同じ

/// 難易度(kazeflag 0〜3)の名前
const List<String> _kazeflagMei = ['鬼', '難', '普', '易'];

int _juu(int n) {
  int p = 1;
  for (int i = 0; i < n; i++) {
    p *= 10;
  }
  return p;
}

/// 1大学1桁で詰めた値(大学0〜14は[idx0]、15〜29は[idx1])から、大学の桁(0〜9)を取り出す
int _univKetaYomu(List<int> yobiint2, int idx0, int idx1, int univid) {
  if (univid < 0 || univid >= comGoldSilverLevelKetasuu * 2) return 0;
  final int idx = univid < comGoldSilverLevelKetasuu ? idx0 : idx1;
  if (yobiint2.length <= idx) return 0;
  final int v = yobiint2[idx];
  if (v < 0) return 0;
  return (v ~/ _juu(univid % comGoldSilverLevelKetasuu)) % 10;
}

/// 1大学1桁で詰めた値に、大学の桁(0〜9)を書き込む(保存は呼び出し側で行う)
void _univKetaKaku(
  List<int> yobiint2,
  int idx0,
  int idx1,
  int univid,
  int keta,
) {
  if (univid < 0 || univid >= comGoldSilverLevelKetasuu * 2) return;
  if (keta < 0 || keta > 9) return;
  final int idx = univid < comGoldSilverLevelKetasuu ? idx0 : idx1;
  if (yobiint2.length <= idx) return;
  final int p = _juu(univid % comGoldSilverLevelKetasuu);
  final int v = yobiint2[idx] < 0 ? 0 : yobiint2[idx];
  final int mae = (v ~/ p) % 10;
  yobiint2[idx] = v + (keta - mae) * p;
}

/// 大学の金銀支給レベル(0〜9)を取り出す
int comGoldSilverLevel(KantokuData kantoku, int univid) {
  return _univKetaYomu(
    kantoku.yobiint2,
    comGoldSilverLevelIndex0,
    comGoldSilverLevelIndex1,
    univid,
  );
}

/// 大学の金銀支給レベル(0〜9)をyobiint2のリストに書き込む(保存は呼び出し側で行う)
void comGoldSilverLevelSettei(List<int> yobiint2, int univid, int level) {
  _univKetaKaku(
    yobiint2,
    comGoldSilverLevelIndex0,
    comGoldSilverLevelIndex1,
    univid,
    level,
  );
}

/// KantokuData.yobiint2 の使用番号: 大学ごとの銀の使い道
/// 支給レベルと同じく1大学1桁で、[40]に大学0〜14、[41]に大学15〜29を格納する
///   0: 個人の練習メニュー通り(初期値)
///   1スピード・2距離走・3登り・4下り・5アップダウン: 10人全員がその能力に使う
///   (番号は年間強化練習メニュー(kaifukuryoku)と同じ)
const int comGinHoushinIndex0 = 40;
const int comGinHoushinIndex1 = 41;
const int comGinHoushinMax = 5; // 選べる番号の最大

/// 大学の銀の使い道(0〜5)を取り出す(範囲外の値は0=個人の練習メニュー通り)
int comGinHoushin(KantokuData kantoku, int univid) {
  final int h = _univKetaYomu(
    kantoku.yobiint2,
    comGinHoushinIndex0,
    comGinHoushinIndex1,
    univid,
  );
  return (h >= 1 && h <= comGinHoushinMax) ? h : 0;
}

/// 大学の銀の使い道(0〜5)をyobiint2のリストに書き込む(保存は呼び出し側で行う)
void comGinHoushinSettei(List<int> yobiint2, int univid, int houshin) {
  if (houshin < 0 || houshin > comGinHoushinMax) return;
  _univKetaKaku(
    yobiint2,
    comGinHoushinIndex0,
    comGinHoushinIndex1,
    univid,
    houshin,
  );
}

/// 銀の使い道の表示名
String comGinHoushinMei(int houshin) {
  if (houshin >= 1 && houshin <= comGinHoushinMax) {
    return TrainingMenu.getMenuString(houshin);
  }
  return '個人の練習メニュー通り';
}

/// KantokuData.yobiint2 の使用番号: 大学ごとの金銀の保有量(夏合宿で使うまで保有する)
/// 保有量は「10単位の回数」と「10未満の端数」に分けて格納する
///   [42]〜[47] 銀の回数(1大学3桁、1つの番号に5大学。[42]に大学0〜4、[43]に大学5〜9…)
///   [48]〜[53] 金の回数(同じ形式)
///   [54]・[55] 銀の端数(1大学1桁、[54]に大学0〜14、[55]に大学15〜29)
///   [56]・[57] 金の端数(同じ形式)
/// 保有量 = 回数×10+端数(上限9999)。どの番号も15桁以内に収まる
const int comGinHoyuuKaisuuIndex = 42;
const int comKinHoyuuKaisuuIndex = 48;
const int comGinHoyuuHasuuIndex = 54;
const int comKinHoyuuHasuuIndex = 56;
const int _hoyuuKaisuuHaba = 3; // 回数の1大学あたりの桁数
const int _hoyuuKaisuuKosuu = 5; // 回数を1つの番号に格納する大学数
const int _hoyuuHasuuKosuu = 15; // 端数を1つの番号に格納する大学数
const int comHoyuuMax = 9999; // 保有量の上限(回数999・端数9)

/// 1大学haba桁で詰めた値から、大学の値を取り出す
/// [idxHajime]から順に、1つの番号にkosuu大学分を格納している
/// (大学idをkosuuで割った商が番号のずれ、余りが桁の位置)
int _tsumetaAtaiYomu(
  List<int> yobiint2,
  int idxHajime,
  int kosuu,
  int haba,
  int univid,
) {
  if (univid < 0 || univid >= TEISUU.UNIVSUU) return 0;
  final int idx = idxHajime + univid ~/ kosuu;
  if (yobiint2.length <= idx) return 0;
  final int v = yobiint2[idx];
  if (v < 0) return 0;
  return (v ~/ _juu(haba * (univid % kosuu))) % _juu(haba);
}

/// 1大学haba桁で詰めた値に、大学の値を書き込む(保存は呼び出し側で行う)
/// 桁に入らない値は、0〜(haba桁の最大)に収める
void _tsumetaAtaiKaku(
  List<int> yobiint2,
  int idxHajime,
  int kosuu,
  int haba,
  int univid,
  int atai,
) {
  if (univid < 0 || univid >= TEISUU.UNIVSUU) return;
  final int idx = idxHajime + univid ~/ kosuu;
  if (yobiint2.length <= idx) return;
  final int a = atai.clamp(0, _juu(haba) - 1);
  final int p = _juu(haba * (univid % kosuu));
  final int v = yobiint2[idx] < 0 ? 0 : yobiint2[idx];
  final int mae = (v ~/ p) % _juu(haba);
  yobiint2[idx] = v + (a - mae) * p;
}

/// 保有量(回数×10+端数)を取り出す
int _hoyuuYomu(List<int> yobiint2, int kaisuuIdx, int hasuuIdx, int univid) {
  final int kaisuu = _tsumetaAtaiYomu(
    yobiint2,
    kaisuuIdx,
    _hoyuuKaisuuKosuu,
    _hoyuuKaisuuHaba,
    univid,
  );
  final int hasuu = _tsumetaAtaiYomu(
    yobiint2,
    hasuuIdx,
    _hoyuuHasuuKosuu,
    1,
    univid,
  );
  return kaisuu * 10 + hasuu;
}

/// 保有量を回数と端数に分けて書き込む(0〜9999に収める。保存は呼び出し側で行う)
void _hoyuuKaku(
  List<int> yobiint2,
  int kaisuuIdx,
  int hasuuIdx,
  int univid,
  int ryou,
) {
  final int r = ryou.clamp(0, comHoyuuMax);
  _tsumetaAtaiKaku(
    yobiint2,
    kaisuuIdx,
    _hoyuuKaisuuKosuu,
    _hoyuuKaisuuHaba,
    univid,
    r ~/ 10,
  );
  _tsumetaAtaiKaku(yobiint2, hasuuIdx, _hoyuuHasuuKosuu, 1, univid, r % 10);
}

/// 大学が保有している金の量
int comKinHoyuu(KantokuData kantoku, int univid) {
  return _hoyuuYomu(
    kantoku.yobiint2,
    comKinHoyuuKaisuuIndex,
    comKinHoyuuHasuuIndex,
    univid,
  );
}

/// 大学が保有している銀の量
int comGinHoyuu(KantokuData kantoku, int univid) {
  return _hoyuuYomu(
    kantoku.yobiint2,
    comGinHoyuuKaisuuIndex,
    comGinHoyuuHasuuIndex,
    univid,
  );
}

/// 大学が保有している金の量を書き込む(保存は呼び出し側で行う)
void _kinHoyuuSettei(List<int> yobiint2, int univid, int ryou) {
  _hoyuuKaku(
    yobiint2,
    comKinHoyuuKaisuuIndex,
    comKinHoyuuHasuuIndex,
    univid,
    ryou,
  );
}

/// 大学が保有している銀の量を書き込む(保存は呼び出し側で行う)
void _ginHoyuuSettei(List<int> yobiint2, int univid, int ryou) {
  _hoyuuKaku(
    yobiint2,
    comGinHoyuuKaisuuIndex,
    comGinHoyuuHasuuIndex,
    univid,
    ryou,
  );
}

/// 支給レベルの表示名(プレイヤーと同じは今のプレイヤーの難易度も付ける 例: プレイヤーと同じ(今は易))
String comGoldSilverLevelHyouji(int level, int playerKazeflag) {
  if (level < 0 || level > 9) return '';
  if (level == _levelPlayerToOnaji) {
    final String mei = (playerKazeflag >= 0 && playerKazeflag <= 3)
        ? _kazeflagMei[playerKazeflag]
        : '';
    return 'プレイヤーと同じ(今は$mei)';
  }
  return comGoldSilverLevelMei[level];
}

/// 支給レベルから支給量の計算に使う難易度(kazeflag 0鬼〜3易)
int _levelKazeflag(int level, int playerKazeflag) {
  if (level >= 0 && level <= 3) return level;
  if (level >= 4 && level <= 7) return level - 4;
  return playerKazeflag; // プレイヤーと同じ(天は支給しないので使わない)
}

/// 支給レベルから難易度モード(0通常、1極=定期支給のみ、2天=支給なし)
int _levelMode(int level) {
  if (level >= 4 && level <= 7) return 1;
  if (level == 8) return 2;
  return 0;
}

/// 春の定期支給分(4月5日の年度替わりの処理で、プレイヤーの定期支給の直後に呼ぶ)
/// 獲得した金銀は保有しておき、夏合宿で使う
/// (1.7.8までは、銀を使うときに年間強化練習メニューが要るため4月15日に支給していた)
Future<void> comGoldSilverTeiki({
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
}) async {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null || !isComGoldSilverOn(kantoku)) {
    return;
  }
  final random = Random();
  for (final univ in sortedUnivData) {
    if (univ.id == gh[0].MYunivid) continue;
    final int level = comGoldSilverLevel(kantoku, univ.id);
    final String univName =
        '${univ.name}(${comGoldSilverLevelHyouji(level, gh[0].kazeflag)})';
    if (_levelMode(level) == 2) {
      if (kDebugMode) print('[COM金銀] 春の定期支給 $univName → 支給なし');
      continue;
    }
    // 難易度ごとの割合(1.9.1。kingin_wariai.dart)は、支給レベルの難易度の割合
    final int levelKazeflag = _levelKazeflag(level, gh[0].kazeflag);
    final int ryou =
        kinginWariaiKakeru(
          _teikiKakutokusuu(univ, levelKazeflag),
          kantoku,
          levelKazeflag,
        ) *
        kantoku.yobiint2[12];
    _comKinGinKakutoku(
      kantoku: kantoku,
      univid: univ.id,
      univName: univName,
      eventLabel: '春の定期支給',
      ryou: ryou,
      random: random,
    );
  }
  await kantoku.save();
}

/// 目標順位達成分(KirokuKousinから呼ぶ)
/// [mokuhyouBangou] 0〜5: 各駅伝・予選の番号(racebangou)、9: 対校戦総合
/// 獲得した金銀は保有しておき、夏合宿で使う(夏合宿より後に獲得した分は翌年の夏合宿)
Future<void> comGoldSilverMokuhyouTassei({
  required int mokuhyouBangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
}) async {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null || !isComGoldSilverOn(kantoku)) {
    return;
  }
  final random = Random();
  for (final univ in sortedUnivData) {
    if (univ.id == gh[0].MYunivid) continue;
    if (mokuhyouBangou != 9 &&
        univ.taikaientryflag[mokuhyouBangou] != 1) {
      continue;
    }
    if (univ.juni_race[mokuhyouBangou][0] >
        univ.mokuhyojuni[mokuhyouBangou]) {
      continue;
    }
    final int level = comGoldSilverLevel(kantoku, univ.id);
    final String univName =
        '${univ.name}(${comGoldSilverLevelHyouji(level, gh[0].kazeflag)})';
    if (_levelMode(level) != 0) {
      // 極・天は目標達成時の支給なし
      if (kDebugMode) {
        print(
          '[COM金銀] 目標達成(${_taikaiMei(mokuhyouBangou)}) $univName → 支給なし',
        );
      }
      continue;
    }
    final int ryou =
        _mokuhyouTasseiRyou(
          univ,
          mokuhyouBangou,
          _levelKazeflag(level, gh[0].kazeflag),
          kantoku,
        ) *
        kantoku.yobiint2[12];
    _comKinGinKakutoku(
      kantoku: kantoku,
      univid: univ.id,
      univName: univName,
      eventLabel: '目標達成(${_taikaiMei(mokuhyouBangou)})',
      ryou: ryou,
      random: random,
    );
  }
  await kantoku.save();
}

/// 1大学分の金銀の獲得(10%で金、90%で銀)
/// すぐには使わず、保有量に加える(保存は呼び出し側で行う)
void _comKinGinKakutoku({
  required KantokuData kantoku,
  required int univid,
  required String univName, // デバッグログ用
  required String eventLabel, // デバッグログ用
  required int ryou,
  required Random random,
}) {
  if (ryou <= 0) return;
  final bool kin = random.nextInt(100) < 10;
  if (kin) {
    _kinHoyuuSettei(
      kantoku.yobiint2,
      univid,
      comKinHoyuu(kantoku, univid) + ryou,
    );
  } else {
    _ginHoyuuSettei(
      kantoku.yobiint2,
      univid,
      comGinHoyuu(kantoku, univid) + ryou,
    );
  }
  // デバッグ実行時のみ、VS Codeのデバッグコンソールに獲得結果を出す
  if (kDebugMode) {
    print(
      '[COM金銀] $eventLabel $univName ${kin ? '金' : '銀'}$ryou獲得 → '
      '保有 金${comKinHoyuu(kantoku, univid)} 銀${comGinHoyuu(kantoku, univid)}',
    );
  }
}

/// 夏合宿分(7月15日の夏の成長の直後に呼ぶ)
/// 保有している金銀をまとめて使い、10未満の端数だけを翌年に持ち越す
/// OFFの場合と、プレイヤーの大学(移籍先)の保有分は、使わずに0にする
Future<void> comGoldSilverNatsuGasshuku({
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null) return;
  final bool on = isComGoldSilverOn(kantoku);
  final random = Random();
  for (final univ in sortedUnivData) {
    final int kin = comKinHoyuu(kantoku, univ.id);
    final int gin = comGinHoyuu(kantoku, univ.id);
    if (kin == 0 && gin == 0) continue;
    if (!on || univ.id == gh[0].MYunivid) {
      _kinHoyuuSettei(kantoku.yobiint2, univ.id, 0);
      _ginHoyuuSettei(kantoku.yobiint2, univ.id, 0);
      if (kDebugMode) {
        print(
          '[COM金銀] 夏合宿 ${univ.name} 保有 金$kin 銀$gin → '
          '${on ? 'プレイヤーの大学' : 'OFF'}のため使わずに0にする',
        );
      }
      continue;
    }
    final int level = comGoldSilverLevel(kantoku, univ.id);
    final String univName =
        '${univ.name}(${comGoldSilverLevelHyouji(level, gh[0].kazeflag)})';
    final List<int> mochikoshi = await _comKinGinShiyou(
      univid: univ.id,
      univName: univName,
      kinRyou: kin,
      ginRyou: gin,
      ginHoushin: comGinHoushin(kantoku, univ.id),
      sortedSenshuData: sortedSenshuData,
      random: random,
    );
    _kinHoyuuSettei(kantoku.yobiint2, univ.id, mochikoshi[0]);
    _ginHoyuuSettei(kantoku.yobiint2, univ.id, mochikoshi[1]);
  }
  await kantoku.save();
}

/// デバッグログ用の大会名
String _taikaiMei(int bangou) {
  switch (bangou) {
    case 0:
      return '10月駅伝';
    case 1:
      return '11月駅伝';
    case 2:
      return '正月駅伝';
    case 3:
      return '11月駅伝予選';
    case 4:
      return '正月駅伝予選';
    case 5:
      return 'カスタム駅伝';
    case 9:
      return '対校戦総合';
    default:
      return '大会$bangou';
  }
}

// デバッグログ用: 金銀で上がる能力の名前と値
const List<String> _nouryokuMei = [
  '駅伝男',
  '平常心',
  '長距離粘り',
  'スパート力',
  '登り適性',
  '下り適性',
  'アップダウン対応力',
  'ロード適性',
  'ペース変動対応力',
];
List<int> _nouryokuList(SenshuData s) => [
  s.konjou,
  s.heijousin,
  s.choukyorinebari,
  s.spurtryoku,
  s.noboritekisei,
  s.kudaritekisei,
  s.noborikudarikirikaenouryoku,
  s.tandokusou,
  s.paceagesagetaiouryoku,
];

/// 春の定期支給量(goldsilverTeikiKakutokuと同じ式)
int _teikiKakutokusuu(UnivData univ, int kazeflag) {
  const List<List<int>> table = [
    [50, 45, 40, 35, 30, 20, 10], // kazeflag 0
    [100, 90, 85, 80, 75, 65, 50], // kazeflag 1
    [200, 180, 170, 160, 150, 125, 100], // kazeflag 2
    [300, 280, 270, 260, 250, 225, 200], // kazeflag 3
  ];
  if (kazeflag < 0 || kazeflag >= table.length) return 0;
  final List<int> t = table[kazeflag];
  final List<List<int>> j = univ.juni_race;
  // 三冠
  if (j[0][0] == 0 && j[1][0] == 0 && j[2][0] == 0) return t[0];
  // 駅伝か対校戦優勝
  if (j[0][0] == 0 || j[1][0] == 0 || j[2][0] == 0 || j[9][0] == 0) {
    return t[1];
  }
  // 駅伝すべて3位以内
  if (j[0][0] < 3 && j[1][0] < 3 && j[2][0] < 3) return t[2];
  // 駅伝か対校戦どれか3位以内
  if (j[0][0] < 3 || j[1][0] < 3 || j[2][0] < 3 || j[9][0] < 3) return t[3];
  // 10月駅伝5位以内・11月駅伝8位以内・正月駅伝10位以内・対校戦8位以内のどれか
  if (j[0][0] < 5 || j[1][0] < 8 || j[2][0] < 10 || j[9][0] < 8) return t[4];
  // 11月駅伝予選か正月駅伝予選を突破
  if (j[3][0] < 7 || j[4][0] < 10) return t[5];
  return t[6];
}

/// 目標順位達成時の支給量(KirokuKousinのプレイヤー向けご褒美と同じ式)
/// 難易度ごとの割合(1.9.1。kingin_wariai.dart)も、プレイヤーと同じく優勝の2倍の前に掛ける
int _mokuhyouTasseiRyou(
  UnivData univ,
  int mokuhyouBangou,
  int kazeflag,
  KantokuData kantoku,
) {
  int rSeed = 0;
  int rYuushou = 0;
  if (kazeflag == 0) {
    rSeed = 30;
    rYuushou = 50;
  } else if (kazeflag == 1) {
    rSeed = 50;
    rYuushou = 100;
  } else if (kazeflag == 2) {
    rSeed = 100;
    rYuushou = 200;
  } else if (kazeflag == 3) {
    rSeed = 200;
    rYuushou = 300;
  }
  final int juni = univ.juni_race[mokuhyouBangou][0];

  // 対校戦総合
  if (mokuhyouBangou == 9) {
    return kinginWariaiKakeru(
      (juni == 0) ? rYuushou : rSeed,
      kantoku,
      kazeflag,
    );
  }

  int r = 0;
  final bool ekiden =
      (mokuhyouBangou >= 0 && mokuhyouBangou <= 2) || mokuhyouBangou == 5;
  if (ekiden) {
    final int maxrank = _getMaxRank(mokuhyouBangou);
    final int seedrank = _getSeedRank(mokuhyouBangou);
    final int targetrank = univ.mokuhyojuni[mokuhyouBangou];
    if (targetrank == 0) {
      r = rYuushou;
    } else if (targetrank == maxrank) {
      r = 10;
    } else if (targetrank <= seedrank) {
      final double persa = (rYuushou - rSeed) / (seedrank - 0);
      r = rSeed + (persa * (seedrank - targetrank)).toInt();
    } else {
      final double persa = (rSeed - 10) / (maxrank - seedrank);
      r = 10 + (persa * (maxrank - targetrank)).toInt();
    }
    r = kinginWariaiKakeru(r, kantoku, kazeflag);
    // 優勝目標で優勝したら2倍
    if (juni == 0 && targetrank == 0) {
      r *= 2;
    }
  } else {
    // 予選突破は最低量
    r = kinginWariaiKakeru(10, kantoku, kazeflag);
  }
  return r;
}

int _getMaxRank(int raceIdx) {
  switch (raceIdx) {
    case 0:
      return 8;
    case 1:
      return 13;
    case 2:
      return 18;
    case 5:
      return 28;
    default:
      return 19;
  }
}

int _getSeedRank(int raceIdx) {
  switch (raceIdx) {
    case 0:
      return 4;
    case 1:
      return 7;
    case 2:
      return 9;
    case 5:
      return 9;
    default:
      return 4;
  }
}

/// 1大学分の金銀使用(夏合宿で、保有している金と銀をまとめて使う)
/// 戻り値は翌年に持ち越す量 [金, 銀](ふつうは10未満の端数)
Future<List<int>> _comKinGinShiyou({
  required int univid,
  required String univName, // デバッグログ用
  required int kinRyou, // 保有している金
  required int ginRyou, // 保有している銀
  required int ginHoushin, // 銀の使い道(0個人の練習メニュー通り、1〜5大学方針)
  required List<SenshuData> sortedSenshuData,
  required Random random,
}) async {
  final int kinKaisuu = kinRyou ~/ 10;
  final int kinHasuu = kinRyou % 10; // 金の10未満の端数は金のまま持ち越す
  // 金も銀も10未満なら、使わずにそのまま持ち越す
  if (kinKaisuu == 0 && ginRyou < 10) return [kinRyou, ginRyou];

  final Set<int> kakyuuseiWakuIds = {}; // デバッグログ用
  final List<SenshuData> shuryoku = _furiwakeSaki(
    univid,
    sortedSenshuData,
    kakyuuseiWakuIds,
  );
  // 振り分け先の選手がいなければ、使わずにそのまま持ち越す
  if (shuryoku.isEmpty) return [kinRyou, ginRyou];

  // デバッグログ用に変化前の能力値を控えておく
  final Map<int, List<int>> maeNouryoku = {
    for (final s in shuryoku) s.id: _nouryokuList(s),
  };

  final Set<SenshuData> henkouari = {};
  final Set<SenshuData> jougen = {}; // 順番が回ってきたが上限で使えなかった選手(デバッグログ用)
  final Map<int, Set<int>> menugai = {}; // メニュー外で上げた能力の番号(デバッグログ用)
  final Map<int, int> menuMap = {}; // 銀で使うメニュー(大学方針、なければ個人の練習メニュー。バランスの選手は0)
  final Map<int, List<int>> balanceChuusen = {}; // バランスの選手が抽選で選んだメニュー(デバッグログ用)
  // スピード・距離走で、この夏合宿に重点的に上げる能力(選手ごと・メニューごとにランダム。1.9.1)
  final Map<int, int> natsuJuuten = {};
  final bool daigakuHoushin =
      ginHoushin >= 1 && ginHoushin <= comGinHoushinMax;

  // 金
  int kinTsukatta = 0;
  if (kinKaisuu > 0) {
    kinTsukatta = _junbanniKubaru(
      shuryoku,
      kinKaisuu,
      _kinTokkun,
      henkouari,
      jougen,
    );
  }
  // 使えなかった金は銀に交換する(金1→銀2)
  final int koukanKin = (kinKaisuu - kinTsukatta) * 10;
  final int ginGoukei = ginRyou + koukanKin * 2;

  // 銀(交換した銀も含む)
  final int ginKaisuu = ginGoukei ~/ 10;
  final int ginHasuu = ginGoukei % 10; // 銀の10未満の端数は持ち越す
  int ginTsukatta = 0;
  int menugaiTsukatta = 0;
  if (ginKaisuu > 0) {
    // 大学方針があれば10人全員その能力に使う
    // なければ個人の練習メニュー通り(バランスの選手は0にしておき、順番が回ってくるたびに抽選する)
    for (final s in shuryoku) {
      int menu = daigakuHoushin ? ginHoushin : s.kaifukuryoku;
      if (menu < 1 || menu > 5) {
        menu = 0;
      }
      menuMap[s.id] = menu;
    }
    // まずメニューの能力に使う
    ginTsukatta = _junbanniKubaru(
      shuryoku,
      ginKaisuu,
      (s) => menuMap[s.id] == 0
          ? _balanceGinTokkun(s, random, balanceChuusen, natsuJuuten)
          : _ginTokkun(s, menuMap[s.id]!, random, natsuJuuten),
      henkouari,
      jougen,
    );
    // 10人全員がメニューの能力で上限なら、先頭からメニュー外の能力に使う
    final int nokori = ginKaisuu - ginTsukatta;
    if (nokori > 0) {
      menugaiTsukatta = _junbanniKubaru(
        shuryoku,
        nokori,
        (s) => _menugaiTokkun(s, random, menugai),
        henkouari,
        jougen,
      );
    }
  }
  for (final s in henkouari) {
    await s.save();
  }

  // デバッグ実行時のみ、VS Codeのデバッグコンソールに使用結果を出す
  // (デバッグコンソールの絞り込み欄に「COM金銀」と入れると、この行だけ表示できる)
  if (kDebugMode) {
    final List<String> naiyou = [];
    if (kinKaisuu > 0) {
      naiyou.add('金$kinTsukatta回使用');
      if (koukanKin > 0) {
        naiyou.add('使えなかった金$koukanKinを銀${koukanKin * 2}に交換');
      }
    }
    if (ginKaisuu > 0) {
      final int ginShiyouKaisuu = ginTsukatta + menugaiTsukatta;
      naiyou.add(
        '銀$ginShiyouKaisuu回使用'
        '${menugaiTsukatta > 0 ? '(うちメニュー外$menugaiTsukatta回)' : ''}'
        '(捨て${(ginKaisuu - ginShiyouKaisuu) * 10})',
      );
    }
    naiyou.add('持ち越し 金$kinHasuu 銀$ginHasuu');
    print(
      '[COM金銀] 夏合宿 $univName 保有 金$kinRyou 銀$ginRyou → '
      '${naiyou.join('、')}',
    );
    for (final s in shuryoku) {
      final List<int> mae = maeNouryoku[s.id]!;
      final List<int> ato = _nouryokuList(s);
      final Set<int> menugaiBangou = menugai[s.id] ?? {};
      final List<String> henka = [];
      for (int i = 0; i < mae.length; i++) {
        if (mae[i] != ato[i]) {
          henka.add(
            '${_nouryokuMei[i]} ${mae[i]}→${ato[i]}'
            '${menugaiBangou.contains(i) ? '(メニュー外)' : ''}',
          );
        }
      }
      // 能力が上がらず、順番も回ってこなかった選手は出さない
      if (henka.isEmpty && !jougen.contains(s)) continue;
      String menuStr = '';
      if (menuMap.containsKey(s.id)) {
        final bool balance = s.kaifukuryoku < 1 || s.kaifukuryoku > 5;
        if (daigakuHoushin) {
          menuStr = '大学方針:${TrainingMenu.getMenuString(ginHoushin)}  ';
        } else if (balance) {
          final List<int> chuusen = balanceChuusen[s.id] ?? [];
          menuStr = chuusen.isEmpty
              ? '年間強化:バランス  '
              : '年間強化:バランス→抽選で'
                    '${chuusen.map(TrainingMenu.getMenuString).join('・')}  ';
        } else {
          menuStr = '年間強化:${TrainingMenu.getMenuString(s.kaifukuryoku)}  ';
        }
      }
      final String waku = kakyuuseiWakuIds.contains(s.id) ? '[下級生枠]' : '';
      final String kekka = henka.isEmpty ? '（上限のため使えず）' : henka.join(' / ');
      // スピード・距離走の、この夏合宿の重点の能力(1.9.1)
      final List<String> juuten = [
        if (natsuJuuten.containsKey(s.id * 10 + 1))
          natsuJuuten[s.id * 10 + 1] == 1 ? 'ペース変動対応力' : 'スパート力',
        if (natsuJuuten.containsKey(s.id * 10 + 2))
          natsuJuuten[s.id * 10 + 2] == 1 ? 'ロード適性' : '長距離粘り',
      ];
      final String juutenStr = juuten.isEmpty
          ? ''
          : '重点:${juuten.join('・')}  ';
      print('[COM金銀]   $waku${s.name}(${s.gakunen}年) $menuStr$juutenStr$kekka');
    }
  }
  return [kinHasuu, ginHasuu];
}

const int _shuryokuWakuSuu = 7; // 主力枠の人数
const int _kakyuuseiWakuSuu = 3; // 下級生枠の人数

/// 金銀の振り分け先(配る順番に並べたもの)
///   主力枠7人: 留学生を除き、基本走力(a)が小さい順
///   下級生枠3人: 主力枠に入らなかった1・2年生を基本走力が小さい順
///     (1・2年生が足りない分は、主力枠の続きの選手で埋める)
///   並び順は「主力2人→下級生1人」の繰り返し
/// [kakyuuseiWakuIds] 下級生枠に入った1・2年生のIDを入れて返す(デバッグログ用)
List<SenshuData> _furiwakeSaki(
  int univid,
  List<SenshuData> sortedSenshuData,
  Set<int> kakyuuseiWakuIds,
) {
  final List<SenshuData> kouho =
      sortedSenshuData
          .where((s) => s.univid == univid && s.hirou != 1)
          .toList()
        ..sort((x, y) {
          final int c = x.a.compareTo(y.a);
          return c != 0 ? c : x.id.compareTo(y.id);
        });

  final List<SenshuData> shuryokuWaku = kouho.take(_shuryokuWakuSuu).toList();
  final List<SenshuData> nokori = kouho.skip(_shuryokuWakuSuu).toList();
  final List<SenshuData> kakyuuseiWaku = nokori
      .where((s) => s.gakunen <= 2)
      .take(_kakyuuseiWakuSuu)
      .toList();
  // 1・2年生が足りない分は、主力枠の続きの選手で埋める
  if (kakyuuseiWaku.length < _kakyuuseiWakuSuu) {
    kakyuuseiWaku.addAll(
      nokori
          .where((s) => !kakyuuseiWaku.contains(s))
          .take(_kakyuuseiWakuSuu - kakyuuseiWaku.length)
          .toList(),
    );
  }
  kakyuuseiWakuIds.addAll(
    kakyuuseiWaku.where((s) => s.gakunen <= 2).map((s) => s.id),
  );

  // 「主力2人→下級生1人」の順番に並べる
  final List<SenshuData> narabi = [];
  int si = 0;
  int ki = 0;
  while (si < shuryokuWaku.length || ki < kakyuuseiWaku.length) {
    for (int n = 0; n < 2 && si < shuryokuWaku.length; n++) {
      narabi.add(shuryokuWaku[si++]);
    }
    if (ki < kakyuuseiWaku.length) {
      narabi.add(kakyuuseiWaku[ki++]);
    }
  }
  return narabi;
}

/// 振り分け先の上から順番に1回(+10)ずつ配る。
/// 上限で使えない選手は飛ばし、全員使えなくなったら残りは捨てる。
/// 戻り値は実際に使った回数
int _junbanniKubaru(
  List<SenshuData> shuryoku,
  int kaisuu,
  bool Function(SenshuData) tokkun,
  Set<SenshuData> henkouari,
  Set<SenshuData> jougen, // 上限で使えなかった選手を入れて返す(デバッグログ用)
) {
  int idx = 0;
  int nokori = kaisuu;
  int renzokuShippai = 0;
  while (nokori > 0 && renzokuShippai < shuryoku.length) {
    final SenshuData s = shuryoku[idx];
    if (tokkun(s)) {
      nokori--;
      renzokuShippai = 0;
      henkouari.add(s);
    } else {
      renzokuShippai++;
      jougen.add(s);
    }
    idx = (idx + 1) % shuryoku.length;
  }
  return kaisuu - nokori;
}

/// 金特訓: 駅伝男優先、次に平常心
bool _kinTokkun(SenshuData s) {
  if (s.konjou <= 89) {
    s.konjou += 10;
    return true;
  }
  if (s.heijousin <= 89) {
    s.heijousin += 10;
    return true;
  }
  return false;
}

/// メニュー外の銀特訓: 上限でない能力の中からランダムに1つ上げる
/// 対象は長距離粘り・スパート力・登り適性・下り適性・アップダウン対応力・
/// ロード適性・ペース変動対応力(カリスマ・安定感は除く)
/// 番号は _nouryokuMei / _nouryokuList と同じ(2〜8)
bool _menugaiTokkun(
  SenshuData s,
  Random random,
  Map<int, Set<int>> menugai,
) {
  final List<int> nouryoku = _nouryokuList(s);
  final List<int> kouho = [
    for (int i = 2; i <= 8; i++)
      if (nouryoku[i] <= 89) i,
  ];
  if (kouho.isEmpty) return false;
  final int bangou = kouho[random.nextInt(kouho.length)];
  switch (bangou) {
    case 2:
      s.choukyorinebari += 10;
      break;
    case 3:
      s.spurtryoku += 10;
      break;
    case 4:
      s.noboritekisei += 10;
      break;
    case 5:
      s.kudaritekisei += 10;
      break;
    case 6:
      s.noborikudarikirikaenouryoku += 10;
      break;
    case 7:
      s.tandokusou += 10;
      break;
    case 8:
      s.paceagesagetaiouryoku += 10;
      break;
  }
  menugai.putIfAbsent(s.id, () => <int>{}).add(bangou);
  return true;
}

/// メニュー(1〜5)に対応する能力が、すべて上限(90以上)かどうか
bool _menuJougen(SenshuData s, int menu) {
  switch (menu) {
    case 1: // スピード
      return s.spurtryoku > 89 && s.paceagesagetaiouryoku > 89;
    case 2: // 距離走
      return s.choukyorinebari > 89 && s.tandokusou > 89;
    case 3: // 登り
      return s.noboritekisei > 89;
    case 4: // 下り
      return s.kudaritekisei > 89;
    case 5: // アップダウン
      return s.noborikudarikirikaenouryoku > 89;
    default:
      return true;
  }
}

/// バランスの選手の銀特訓: 順番が回ってくるたびに、能力が上限でないメニュー(1〜5)から
/// ランダムに1つ選んで上げる(全部上限なら使えない)
/// メニュー1〜5でカリスマ・安定感以外の7つの能力をすべて含むので、メニュー外の能力は残らない
bool _balanceGinTokkun(
  SenshuData s,
  Random random,
  Map<int, List<int>> balanceChuusen, // 抽選で選んだメニュー(デバッグログ用)
  Map<int, int> natsuJuuten, // スピード・距離走の重点の能力(_natsuJuutenNiban)
) {
  final List<int> kouho = [
    for (int menu = 1; menu <= 5; menu++)
      if (!_menuJougen(s, menu)) menu,
  ];
  if (kouho.isEmpty) return false;
  final int menu = kouho[random.nextInt(kouho.length)];
  balanceChuusen.putIfAbsent(s.id, () => <int>[]).add(menu);
  return _ginTokkun(s, menu, random, natsuJuuten);
}

/// スピード・距離走の2つの能力のうち、この夏合宿で重点的に上げるほう(1.9.1)
/// 選手ごと・メニューごとに、初めて順番が回ってきたときにランダムに決め、その夏合宿の間は変えない
/// (1回ごとにランダムだと、年をまたぐと2つの能力がならされて尖らないため)
/// [natsuJuuten] のキーは 選手id*10+メニュー、値は0=1つ目(スパート力・長距離粘り)、
/// 1=2つ目(ペース変動対応力・ロード適性)
bool _natsuJuutenNiban(
  SenshuData s,
  int menu,
  Random random,
  Map<int, int> natsuJuuten,
) {
  return natsuJuuten.putIfAbsent(s.id * 10 + menu, () => random.nextInt(2)) ==
      1;
}

/// 銀特訓: 年間強化メニューに対応する能力
/// スピード・距離走は、この夏合宿の重点の能力から上げ、上限ならもう一方を上げる(1.9.1。
/// 1.9.0までは低いほうから上げていた)
bool _ginTokkun(
  SenshuData s,
  int menu,
  Random random,
  Map<int, int> natsuJuuten,
) {
  switch (menu) {
    case 1: // スピード: スパート力、ペース変動対応力
      if (_natsuJuutenNiban(s, menu, random, natsuJuuten)) {
        if (s.paceagesagetaiouryoku <= 89) {
          s.paceagesagetaiouryoku += 10;
          return true;
        }
        if (s.spurtryoku <= 89) {
          s.spurtryoku += 10;
          return true;
        }
      } else {
        if (s.spurtryoku <= 89) {
          s.spurtryoku += 10;
          return true;
        }
        if (s.paceagesagetaiouryoku <= 89) {
          s.paceagesagetaiouryoku += 10;
          return true;
        }
      }
      return false;
    case 2: // 距離走: 長距離粘り、ロード適性
      if (_natsuJuutenNiban(s, menu, random, natsuJuuten)) {
        if (s.tandokusou <= 89) {
          s.tandokusou += 10;
          return true;
        }
        if (s.choukyorinebari <= 89) {
          s.choukyorinebari += 10;
          return true;
        }
      } else {
        if (s.choukyorinebari <= 89) {
          s.choukyorinebari += 10;
          return true;
        }
        if (s.tandokusou <= 89) {
          s.tandokusou += 10;
          return true;
        }
      }
      return false;
    case 3: // 登り
      if (s.noboritekisei <= 89) {
        s.noboritekisei += 10;
        return true;
      }
      return false;
    case 4: // 下り
      if (s.kudaritekisei <= 89) {
        s.kudaritekisei += 10;
        return true;
      }
      return false;
    case 5: // アップダウン
      if (s.noborikudarikirikaenouryoku <= 89) {
        s.noborikudarikirikaenouryoku += 10;
        return true;
      }
      return false;
    default:
      return false;
  }
}
