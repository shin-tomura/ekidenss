import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ------------------------------------------------------------
// コンピュータ大学の金銀使用
//
// ・支給量はプレイヤーと同じ式(難易度・金銀支給量倍率yobiint2[12]も共通)
// ・「極」「天」モードでもコンピュータ大学への支給は絞らない
// ・支給のたびに10%で金、90%で銀(プレイヤーと同じ)
// ・振り分け先は留学生を除く基本走力(a、小さいほど良い)上位10人。
//   主力の上から順番に+10ずつ配る。10未満の端数と、配りきれない余りは捨てる。
// ・金: 駅伝男(konjou)優先、次に平常心(heijousin)
// ・銀: 年間強化練習メニュー(kaifukuryoku)に対応する能力
//     1スピード→スパート力・ペース変動対応力(低いほうから)
//     2距離走→長距離粘り・ロード適性(低いほうから)
//     3登り→登り適性、4下り→下り適性、5アップダウン→アップダウン対応力
//     0バランス→支給のたびに1〜5からランダムに選ぶ(kaifukuryoku自体は変えない)
// ・カリスマには使わない
// ・能力値が89以下の場合のみ+10(プレイヤーの金銀特訓と同じ上限)
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

/// 春の定期支給分(4月15日の年間強化メニュー決定直後に呼ぶ)
Future<void> comGoldSilverTeiki({
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
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
    final int ryou =
        _teikiKakutokusuu(univ, gh[0].kazeflag) * kantoku.yobiint2[12];
    await _comKinGinShiyou(
      univid: univ.id,
      ryou: ryou,
      sortedSenshuData: sortedSenshuData,
      random: random,
    );
  }
}

/// 目標順位達成分(KirokuKousinから呼ぶ)
/// [mokuhyouBangou] 0〜5: 各駅伝・予選の番号(racebangou)、9: 対校戦総合
Future<void> comGoldSilverMokuhyouTassei({
  required int mokuhyouBangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
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
    final int ryou =
        _mokuhyouTasseiRyou(univ, mokuhyouBangou, gh[0].kazeflag) *
        kantoku.yobiint2[12];
    await _comKinGinShiyou(
      univid: univ.id,
      ryou: ryou,
      sortedSenshuData: sortedSenshuData,
      random: random,
    );
  }
}

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
int _mokuhyouTasseiRyou(UnivData univ, int mokuhyouBangou, int kazeflag) {
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
    return (juni == 0) ? rYuushou : rSeed;
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
    // 優勝目標で優勝したら2倍
    if (juni == 0 && targetrank == 0) {
      r *= 2;
    }
  } else {
    // 予選突破は最低量
    r = 10;
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

/// 1大学分の金銀使用(10%で金、90%で銀)
Future<void> _comKinGinShiyou({
  required int univid,
  required int ryou,
  required List<SenshuData> sortedSenshuData,
  required Random random,
}) async {
  final int kaisuu = ryou ~/ 10; // 10未満の端数は捨てる
  if (kaisuu <= 0) return;
  final bool kin = random.nextInt(100) < 10;

  // 主力: 留学生を除き、基本走力(a)が小さい順に上位10人
  final List<SenshuData> shuryoku =
      sortedSenshuData
          .where((s) => s.univid == univid && s.hirou != 1)
          .toList()
        ..sort((x, y) {
          final int c = x.a.compareTo(y.a);
          return c != 0 ? c : x.id.compareTo(y.id);
        });
  if (shuryoku.length > 10) {
    shuryoku.removeRange(10, shuryoku.length);
  }
  if (shuryoku.isEmpty) return;

  final Set<SenshuData> henkouari = {};
  if (kin) {
    _junbanniKubaru(shuryoku, kaisuu, _kinTokkun, henkouari);
  } else {
    // バランスの選手は、この支給で使うメニューをランダムに決める
    final Map<int, int> menuMap = {};
    for (final s in shuryoku) {
      int menu = s.kaifukuryoku;
      if (menu < 1 || menu > 5) {
        menu = random.nextInt(5) + 1;
      }
      menuMap[s.id] = menu;
    }
    _junbanniKubaru(
      shuryoku,
      kaisuu,
      (s) => _ginTokkun(s, menuMap[s.id]!),
      henkouari,
    );
  }
  for (final s in henkouari) {
    await s.save();
  }
}

/// 主力の上から順番に1回(+10)ずつ配る。
/// 上限で使えない選手は飛ばし、全員使えなくなったら残りは捨てる。
void _junbanniKubaru(
  List<SenshuData> shuryoku,
  int kaisuu,
  bool Function(SenshuData) tokkun,
  Set<SenshuData> henkouari,
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
    }
    idx = (idx + 1) % shuryoku.length;
  }
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

/// 銀特訓: 年間強化メニューに対応する能力
bool _ginTokkun(SenshuData s, int menu) {
  switch (menu) {
    case 1: // スピード: スパート力、ペース変動対応力(低いほうから、同じならスパート力)
      if (s.spurtryoku <= 89 &&
          (s.spurtryoku <= s.paceagesagetaiouryoku ||
              s.paceagesagetaiouryoku > 89)) {
        s.spurtryoku += 10;
        return true;
      }
      if (s.paceagesagetaiouryoku <= 89) {
        s.paceagesagetaiouryoku += 10;
        return true;
      }
      return false;
    case 2: // 距離走: 長距離粘り、ロード適性(低いほうから、同じなら長距離粘り)
      if (s.choukyorinebari <= 89 &&
          (s.choukyorinebari <= s.tandokusou || s.tandokusou > 89)) {
        s.choukyorinebari += 10;
        return true;
      }
      if (s.tandokusou <= 89) {
        s.tandokusou += 10;
        return true;
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
