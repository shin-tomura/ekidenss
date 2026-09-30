import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:ekiden/constants.dart'; // TrainingMenu
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
// ・振り分け先は留学生を除く10人(基本走力はa、小さいほど良い)
//     主力枠7人: 基本走力の上位7人(全学年)
//     下級生枠3人: 主力枠に入らなかった1・2年生のうち基本走力の上位3人
//       (1・2年生が足りない分は、主力枠の続きの選手で埋める)
//   「主力2人→下級生1人」の順番で並べ、上から順番に+10ずつ配る
//   (配る量が少ないときでも下級生に届くように)。
//   10未満の端数と、配りきれない余りは捨てる。
// ・夏合宿(7月15日)より後の支給では4年生を除く
//   (プレイヤーは秋以降に獲得した金銀を翌年の夏合宿でしか使えず、
//    今の4年生には使えないため)
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
      univName: univ.name,
      eventLabel: '春の定期支給',
      ryou: ryou,
      yonenseiNozoku: false,
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
  final bool yonenseiNozoku = _natsuGasshukuYoriAto(gh[0]);
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
      univName: univ.name,
      eventLabel: '目標達成(${_taikaiMei(mokuhyouBangou)})',
      ryou: ryou,
      yonenseiNozoku: yonenseiNozoku,
      sortedSenshuData: sortedSenshuData,
      random: random,
    );
  }
}

/// 今日が夏合宿(7月15日)より後かどうか(年度は4月始まり)
bool _natsuGasshukuYoriAto(Ghensuu gh) {
  if (gh.month >= 8 || gh.month <= 3) return true;
  return gh.month == 7 && gh.day > 15;
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
  required String univName, // デバッグログ用
  required String eventLabel, // デバッグログ用
  required int ryou,
  required bool yonenseiNozoku, // trueなら4年生を振り分け先から除く
  required List<SenshuData> sortedSenshuData,
  required Random random,
}) async {
  final int kaisuu = ryou ~/ 10; // 10未満の端数は捨てる
  if (kaisuu <= 0) return;
  final bool kin = random.nextInt(100) < 10;

  final Set<int> kakyuuseiWakuIds = {}; // デバッグログ用
  final List<SenshuData> shuryoku = _furiwakeSaki(
    univid,
    yonenseiNozoku,
    sortedSenshuData,
    kakyuuseiWakuIds,
  );
  if (shuryoku.isEmpty) return;

  // デバッグログ用に変化前の能力値を控えておく
  final Map<int, List<int>> maeNouryoku = {
    for (final s in shuryoku) s.id: _nouryokuList(s),
  };

  final Set<SenshuData> henkouari = {};
  final Set<SenshuData> jougen = {}; // 順番が回ってきたが上限で使えなかった選手(デバッグログ用)
  final Map<int, int> menuMap = {};
  int tsukatta = 0;
  if (kin) {
    tsukatta = _junbanniKubaru(
      shuryoku,
      kaisuu,
      _kinTokkun,
      henkouari,
      jougen,
    );
  } else {
    // バランスの選手は、この支給で使うメニューをランダムに決める
    for (final s in shuryoku) {
      int menu = s.kaifukuryoku;
      if (menu < 1 || menu > 5) {
        menu = random.nextInt(5) + 1;
      }
      menuMap[s.id] = menu;
    }
    tsukatta = _junbanniKubaru(
      shuryoku,
      kaisuu,
      (s) => _ginTokkun(s, menuMap[s.id]!),
      henkouari,
      jougen,
    );
  }
  for (final s in henkouari) {
    await s.save();
  }

  // デバッグ実行時のみ、VS Codeのデバッグコンソールに使用結果を出す
  // (デバッグコンソールの絞り込み欄に「COM金銀」と入れると、この行だけ表示できる)
  if (kDebugMode) {
    print(
      '[COM金銀] $eventLabel $univName ${kin ? '金' : '銀'}$ryou → '
      '$tsukatta回使用(捨て${ryou - tsukatta * 10})',
    );
    for (final s in shuryoku) {
      final List<int> mae = maeNouryoku[s.id]!;
      final List<int> ato = _nouryokuList(s);
      final List<String> henka = [];
      for (int i = 0; i < mae.length; i++) {
        if (mae[i] != ato[i]) {
          henka.add('${_nouryokuMei[i]} ${mae[i]}→${ato[i]}');
        }
      }
      // 能力が上がらず、順番も回ってこなかった選手は出さない
      if (henka.isEmpty && !jougen.contains(s)) continue;
      String menuStr = '';
      if (!kin) {
        final bool balance = s.kaifukuryoku < 1 || s.kaifukuryoku > 5;
        menuStr = balance
            ? '年間強化:バランス→抽選で${TrainingMenu.getMenuString(menuMap[s.id]!)}  '
            : '年間強化:${TrainingMenu.getMenuString(s.kaifukuryoku)}  ';
      }
      final String waku = kakyuuseiWakuIds.contains(s.id) ? '[下級生枠]' : '';
      final String kekka = henka.isEmpty ? '（上限のため使えず）' : henka.join(' / ');
      print('[COM金銀]   $waku${s.name}(${s.gakunen}年) $menuStr$kekka');
    }
  }
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
  bool yonenseiNozoku,
  List<SenshuData> sortedSenshuData,
  Set<int> kakyuuseiWakuIds,
) {
  final List<SenshuData> kouho =
      sortedSenshuData
          .where(
            (s) =>
                s.univid == univid &&
                s.hirou != 1 &&
                !(yonenseiNozoku && s.gakunen >= 4),
          )
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
