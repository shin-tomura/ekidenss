import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ------------------------------------------------------------
// コンピュータ大学の区間エントリー後処理と当日変更
//
// ・区間エントリー時: 体調不良(調子0)の選手を区間から外し、補欠と入れ替える
// ・区間エントリー時: 当て馬エントリー(設定の確率で実施)
//     エース(基本走力aの上位)を補欠に隠し、空いた区間に補欠を当て馬として入れる
//     隠した人数: 10月駅伝1人、11月駅伝2人、正月駅伝3人、
//                 カスタム駅伝は区間数6以下1人、8以下2人、それ以上3人
//     隠したエースの本来の区間は kazetaisei に(区間番号+1)で保存する
// ・当日変更: プレイヤーの当日変更確定後(当日変更画面を通らない場合はレース計算開始時)
//     優先度1: 体調不良の走者を補欠と交代(補欠のほうが速い見込みの場合)
//     優先度2: 当て馬で隠したエースを本来の区間に戻す
//     優先度3: 調子が100未満の走者で、補欠のほうが明らかに速い見込み(0.3%以上)の場合に交代
//     見込みタイムは試走タイム(TrialTime)に当日の調子補正を加えたもの
//     交代人数の上限はプレイヤーと同じ(区間数6以下2人、8以下3人、それ以上6人、
//     正月駅伝は往路4人・復路4人、合計6人)
// ・箱庭モードの「他大学変更」で確定した大学は、その日の自動当日変更をしない
// ・区間エントリーの整合性チェックと自動修復(全大学、学連選抜は除く)
//     区間エントリー決定後とレース計算開始時に、1区間に走者がちょうど1人になるよう直す
//
// KantokuData.yobiint2 の使用番号
//   [34] 当て馬エントリー確率(0〜100、初期値0)
//   [35] コンピュータ当日変更の実行済みコード(年*100+大会番号*10+日)
//   [36] 手動当日変更マスクのコード(年*100+大会番号*10+日)
//   [37] 手動当日変更した大学のビットマスク
// 日: 0=1日開催、1=正月駅伝往路、2=正月駅伝復路
// ------------------------------------------------------------

const int atemaKakurituIndex = 34;
const int comToujituDoneIndex = 35;
const int manualToujituCodeIndex = 36;
const int manualToujituMaskIndex = 37;

bool _isEkiden(int racebangou) =>
    (racebangou >= 0 && racebangou <= 2) || racebangou == 5;

int _toujituCode(int year, int racebangou, int day) =>
    year * 100 + racebangou * 10 + day;

int _entry(SenshuData s, int racebangou) =>
    s.entrykukan_race[racebangou][s.gakunen - 1];

void _setEntry(SenshuData s, int racebangou, int value) {
  s.entrykukan_race[racebangou][s.gakunen - 1] = value;
}

/// 正月駅伝の往路(day1)・復路(day2)の対象区間か
bool _isTaishouKukan(int racebangou, int day, int kukan) {
  if (racebangou == 2) {
    if (day == 1) return kukan < 5;
    if (day == 2) return kukan >= 5;
  }
  return true;
}

/// その日の交代可能人数(プレイヤーの当日変更画面と同じ)
int _hiGotoJougen(int racebangou, int kukansuu) {
  if (racebangou == 2) return 4;
  if (kukansuu <= 6) return 2;
  if (kukansuu <= 8) return 3;
  return 6;
}

/// 大会を通しての交代可能人数
int _goukeiJougen(int racebangou, int kukansuu) {
  if (racebangou == 2) return 6;
  return _hiGotoJougen(racebangou, kukansuu);
}

/// 当て馬で隠す人数
int _atemaNinzuu(int racebangou, int kukansuu) {
  if (racebangou == 0) return 1;
  if (racebangou == 1) return 2;
  if (racebangou == 2) return 3;
  if (kukansuu <= 6) return 1;
  if (kukansuu <= 8) return 2;
  return 3;
}

/// デバッグログ用の大会名(正月駅伝は往路・復路も付ける)
String _taikaiMei(int racebangou, [int day = 0]) {
  String mei;
  switch (racebangou) {
    case 0:
      mei = '10月駅伝';
      break;
    case 1:
      mei = '11月駅伝';
      break;
    case 2:
      mei = '正月駅伝';
      break;
    case 5:
      mei = 'カスタム駅伝';
      break;
    default:
      mei = '大会$racebangou';
  }
  if (day == 1) mei += '(往路)';
  if (day == 2) mei += '(復路)';
  return mei;
}

/// デバッグ実行時のみログを出す(ストア版では出さない)
void _debugLog(String message) {
  if (kDebugMode) print(message);
}

/// 調子によるタイム補正の倍率(RaceCalcの調子補正と同じ式)
double _chousiKeisuu(SenshuData s, KantokuData kantoku) {
  if (s.chousi == 0) {
    return 1.0 + kantoku.yobiint2[11].toDouble() / 100.0;
  }
  return 1.0 +
      (100 - s.chousi).toDouble() *
          0.001 *
          (kantoku.yobiint2[2].toDouble() / 100.0);
}

Future<void> _yasumi() async {
  final now = DateTime.now();
  if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
    await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
    Chousa.lastGapTime = DateTime.now();
  }
}

/// 見込みタイム(試走タイム×調子補正)をキャッシュしながら計算する
class _Mitumori {
  final Ghensuu gh;
  final List<SenshuData> sortedSenshuData;
  final List<UnivData> sortedUnivData;
  final KantokuData kantoku;
  final Map<int, double> _cache = {};

  _Mitumori(this.gh, this.sortedSenshuData, this.sortedUnivData, this.kantoku);

  Future<double> time(SenshuData s, int kukan) async {
    final int key = s.id * 100 + kukan;
    final double? cached = _cache[key];
    if (cached != null) return cached;
    await _yasumi(); // フリーズ対策
    double t = await runTrialCalculation(
      s.id,
      kukan,
      gh,
      sortedSenshuData,
      sortedUnivData,
      kantoku,
    );
    t *= _chousiKeisuu(s, kantoku);
    _cache[key] = t;
    return t;
  }

  /// 候補の中から、その区間の見込みタイムが最も速い選手
  Future<SenshuData?> fastest(List<SenshuData> candidates, int kukan) async {
    SenshuData? best;
    double bestTime = double.infinity;
    for (final s in candidates) {
      final double t = await time(s, kukan);
      if (t < bestTime) {
        bestTime = t;
        best = s;
      }
    }
    return best;
  }
}

/// 当日変更で入った選手の指示フラグを設定し直す(EntryCalcのCOMチーム選手指示確定と同じ)
void _shijiFlagSettei(SenshuData s, int kukan, Random random) {
  s.startchokugotobidasiflag = 0;
  s.startchokugotobidasiseikouflag = 0;
  s.sijiflag = 0;
  s.sijiseikouflag = 0;
  if (kukan == 0) {
    if (s.konjou >= 85 &&
        random.nextInt(100) < TEISUU.STARTTOBIDASIKAKURITU) {
      s.startchokugotobidasiflag = 1;
    }
  } else {
    if (s.konjou >= 85 && random.nextInt(100) < s.konjou) {
      s.sijiflag = 1;
    }
    if (s.sijiflag == 0 &&
        s.heijousin >= 80 &&
        random.nextInt(100) < s.heijousin) {
      s.sijiflag = 2;
    }
  }
}

void _shijiFlagClear(SenshuData s) {
  s.startchokugotobidasiflag = 0;
  s.startchokugotobidasiseikouflag = 0;
  s.sijiflag = 0;
  s.sijiseikouflag = 0;
}

// ------------------------------------------------------------
// 区間エントリー後処理(EntryCalcの区間内順位算出の直前に呼ぶ)
// ------------------------------------------------------------
Future<void> comEntryAtoshori({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  if (!_isEkiden(racebangou)) return;
  if (gh[0].hyojiracebangou != racebangou) return; // 試走タイムのコースが違うため
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null) return;

  final random = Random();
  final int kukansuu = gh[0].kukansuu_taikaigoto[racebangou];
  final int atemaKakuritu = kantoku.yobiint2.length > atemaKakurituIndex
      ? kantoku.yobiint2[atemaKakurituIndex]
      : 0;
  final mitumori = _Mitumori(gh[0], sortedSenshuData, sortedUnivData, kantoku);

  for (final univ in sortedUnivData) {
    if (univ.id == gh[0].MYunivid) continue;
    if (univ.taikaientryflag[racebangou] != 1) continue;
    await _yasumi();

    final List<SenshuData> team = sortedSenshuData
        .where((s) => s.univid == univ.id && _entry(s, racebangou) >= -1)
        .toList();
    final Set<SenshuData> henkouari = {};

    // 当て馬用の「本来の区間」をクリア
    for (final s in team) {
      if (s.kazetaisei != 0) {
        s.kazetaisei = 0;
        henkouari.add(s);
      }
    }

    // ① 体調不良の選手を区間から外す
    for (int k = 0; k < kukansuu; k++) {
      SenshuData? runner;
      for (final s in team) {
        if (_entry(s, racebangou) == k) {
          runner = s;
          break;
        }
      }
      if (runner == null || runner.chousi != 0) continue;
      final List<SenshuData> subs = team
          .where((s) => _entry(s, racebangou) == -1 && s.chousi != 0)
          .toList();
      final SenshuData? sub = await mitumori.fastest(subs, k);
      if (sub == null) continue;
      _setEntry(runner, racebangou, -1);
      _setEntry(sub, racebangou, k);
      henkouari.add(runner);
      henkouari.add(sub);
      _debugLog(
        '[COM区間エントリー] ${_taikaiMei(racebangou)} ${univ.name} ${k + 1}区 '
        '${runner.name}(${runner.gakunen}年)→${sub.name}(${sub.gakunen}年)(体調不良のため)',
      );
    }

    // ③ 当て馬エントリー
    if (atemaKakuritu > 0 && random.nextInt(100) < atemaKakuritu) {
      final List<SenshuData> runners =
          team
              .where(
                (s) =>
                    _entry(s, racebangou) >= 0 &&
                    _entry(s, racebangou) < kukansuu &&
                    s.chousi != 0,
              )
              .toList()
            ..sort((x, y) {
              final int c = x.a.compareTo(y.a); // 基本走力は小さいほど良い
              return c != 0 ? c : x.id.compareTo(y.id);
            });
      final List<SenshuData> aces = runners
          .take(_atemaNinzuu(racebangou, kukansuu))
          .toList();
      for (final ace in aces) {
        final int k = _entry(ace, racebangou);
        final List<SenshuData> subs = team
            .where(
              (s) =>
                  _entry(s, racebangou) == -1 &&
                  s.chousi != 0 &&
                  s.kazetaisei == 0, // 隠したエースは当て馬にしない
            )
            .toList();
        final SenshuData? atema = await mitumori.fastest(subs, k);
        if (atema == null) break;
        _setEntry(ace, racebangou, -1);
        ace.kazetaisei = k + 1; // 本来の区間
        _setEntry(atema, racebangou, k);
        henkouari.add(ace);
        henkouari.add(atema);
        _debugLog(
          '[COM当て馬] ${_taikaiMei(racebangou)} ${univ.name} ${k + 1}区 '
          'エース${ace.name}(${ace.gakunen}年)を補欠に隠し、当て馬${atema.name}(${atema.gakunen}年)を登録',
        );
      }
    }

    for (final s in henkouari) {
      await s.save();
    }
  }
}

// ------------------------------------------------------------
// 当日変更
// ------------------------------------------------------------
class _Kouho {
  final int kukan;
  final SenshuData runner;
  final SenshuData sub;
  final double gain;
  final int yuusen; // 大きいほど優先
  _Kouho(this.kukan, this.runner, this.sub, this.gain, this.yuusen);
}

/// コンピュータ大学の当日変更
/// [day] 0=1日開催、1=正月駅伝往路、2=正月駅伝復路
Future<void> comToujituHenkou({
  required int racebangou,
  required int day,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  if (!_isEkiden(racebangou)) return;
  if (gh[0].hyojiracebangou != racebangou) return; // 試走タイムのコースが違うため
  final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData? kantoku = kantokuBox.get('KantokuData');
  if (kantoku == null || kantoku.yobiint2.length <= manualToujituMaskIndex) {
    return;
  }

  // 同じ日に二重に実行しない
  final int code = _toujituCode(gh[0].year, racebangou, day);
  if (kantoku.yobiint2[comToujituDoneIndex] == code) return;
  kantoku.yobiint2[comToujituDoneIndex] = code;
  await kantoku.save();

  final int manualMask = kantoku.yobiint2[manualToujituCodeIndex] == code
      ? kantoku.yobiint2[manualToujituMaskIndex]
      : 0;
  final int kukansuu = gh[0].kukansuu_taikaigoto[racebangou];
  final int hiGotoJougen = _hiGotoJougen(racebangou, kukansuu);
  final int goukeiJougen = _goukeiJougen(racebangou, kukansuu);
  final random = Random();
  final mitumori = _Mitumori(gh[0], sortedSenshuData, sortedUnivData, kantoku);
  bool henkouAri = false;

  for (final univ in sortedUnivData) {
    if (univ.id == gh[0].MYunivid) continue;
    if (univ.taikaientryflag[racebangou] != 1) continue;
    if ((manualMask >> univ.id) & 1 == 1) {
      // 手動で当日変更した大学
      _debugLog(
        '[COM当日変更] ${_taikaiMei(racebangou, day)} ${univ.name} '
        'は他大学変更で確定済みのため、自動の当日変更なし',
      );
      continue;
    }
    await _yasumi();

    final List<SenshuData> team = sortedSenshuData
        .where((s) => s.univid == univ.id)
        .toList();
    final int sudeniHenkou = team
        .where((s) => _entry(s, racebangou) <= -100)
        .length;
    int nokori = min(hiGotoJougen, goukeiJougen - sudeniHenkou);
    if (nokori <= 0) continue;

    final List<SenshuData> runners = team.where((s) {
      final int k = _entry(s, racebangou);
      return k >= 0 && k < kukansuu && _isTaishouKukan(racebangou, day, k);
    }).toList();
    final List<SenshuData> subs = team
        .where((s) => _entry(s, racebangou) == -1 && s.chousi != 0)
        .toList();
    if (runners.isEmpty || subs.isEmpty) continue;

    // 交代候補を作る
    final List<_Kouho> kouho = [];
    for (final runner in runners) {
      final int k = _entry(runner, racebangou);
      // 調子100の走者は、当て馬で隠したエースを戻す場合のみ交代を検討する
      final List<SenshuData> kentouSubs = runner.chousi < 100
          ? subs
          : subs.where((s) => s.kazetaisei == k + 1).toList();
      if (kentouSubs.isEmpty) continue;
      final double genzai = await mitumori.time(runner, k);
      for (final sub in kentouSubs) {
        final double gain = genzai - await mitumori.time(sub, k);
        if (gain <= 0) continue;
        int yuusen;
        if (runner.chousi == 0) {
          yuusen = 2; // 体調不良の走者の交代
        } else if (sub.kazetaisei == k + 1) {
          yuusen = 1; // 当て馬で隠したエースを本来の区間に戻す
        } else if (gain >= genzai * 0.003) {
          yuusen = 0; // 調子の悪い走者より補欠のほうが明らかに速い
        } else {
          continue;
        }
        kouho.add(_Kouho(k, runner, sub, gain, yuusen));
      }
    }
    kouho.sort((x, y) {
      if (x.yuusen != y.yuusen) return y.yuusen.compareTo(x.yuusen);
      return y.gain.compareTo(x.gain);
    });

    // 上限の範囲で交代を適用
    final Set<int> kakuteiKukan = {};
    final Set<int> kakuteiSub = {};
    for (final c in kouho) {
      if (nokori <= 0) break;
      if (kakuteiKukan.contains(c.kukan) || kakuteiSub.contains(c.sub.id)) {
        continue;
      }
      _setEntry(c.runner, racebangou, -(100 + c.kukan));
      _shijiFlagClear(c.runner);
      _setEntry(c.sub, racebangou, c.kukan);
      _shijiFlagSettei(c.sub, c.kukan, random);
      await c.runner.save();
      await c.sub.save();
      kakuteiKukan.add(c.kukan);
      kakuteiSub.add(c.sub.id);
      nokori--;
      henkouAri = true;
      final String riyuu = c.yuusen == 2
          ? '体調不良のため'
          : (c.yuusen == 1
                ? '当て馬から本来の選手へ'
                : '調子${c.runner.chousi}のため');
      _debugLog(
        '[COM当日変更] ${_taikaiMei(racebangou, day)} ${univ.name} ${c.kukan + 1}区 '
        '${c.runner.name}(${c.runner.gakunen}年)→${c.sub.name}(${c.sub.gakunen}年)'
        '($riyuu 見込み-${c.gain.toStringAsFixed(1)}秒)',
      );
    }
  }

  if (henkouAri) {
    await _kukannaiJunSaikeisan(racebangou, kukansuu, sortedSenshuData);
  }
}

/// 区間内順位の再計算(当日変更画面の _kukannaiJunSaikeisan と同じ内容)
/// 値が変わった選手だけ保存して、保存回数を減らしている
Future<void> _kukannaiJunSaikeisan(
  int racebangou,
  int kukansuu,
  List<SenshuData> sortedSenshuData,
) async {
  final Map<int, List<int>> maeNoJuni = {
    for (final s in sortedSenshuData) s.id: List<int>.from(s.kukannaijuni),
  };
  for (final s in sortedSenshuData) {
    for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
      s.kukannaijuni[i] = TEISUU.DEFAULTJUNI;
    }
  }
  for (int k = 0; k < kukansuu; k++) {
    final List<SenshuData> entryList = sortedSenshuData
        .where((s) => _entry(s, racebangou) == k)
        .toList();
    for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
      final List<SenshuData> timeJun =
          entryList.where((s) => s.time_bestkiroku.length > i).toList()
            ..sort((x, y) => x.time_bestkiroku[i].compareTo(y.time_bestkiroku[i]));
      for (int juni = 0; juni < timeJun.length; juni++) {
        timeJun[juni].kukannaijuni[i] = juni;
      }
    }
  }
  for (final s in sortedSenshuData) {
    final List<int> mae = maeNoJuni[s.id]!;
    bool kawatta = mae.length != s.kukannaijuni.length;
    for (int i = 0; !kawatta && i < mae.length; i++) {
      if (mae[i] != s.kukannaijuni[i]) kawatta = true;
    }
    if (kawatta) {
      await _yasumi(); // フリーズ対策
      await s.save();
    }
  }
}

/// 当日変更画面(プレイヤーの確定後)から呼ぶ用
Future<void> comToujituHenkouAfterPlayer(
  Ghensuu currentGhensuu, {
  required int day,
}) async {
  final List<SenshuData> sortedSenshuData =
      Hive.box<SenshuData>('senshuBox').values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final List<UnivData> sortedUnivData =
      Hive.box<UnivData>('univBox').values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  await comToujituHenkou(
    racebangou: currentGhensuu.hyojiracebangou,
    day: day,
    gh: [currentGhensuu],
    sortedUnivData: sortedUnivData,
    sortedSenshuData: sortedSenshuData,
  );
}

/// 箱庭モードの「他大学変更」で確定した大学を記録する
/// [targetGroup] 0=通常または正月駅伝往路、1=正月駅伝復路
Future<void> markManualToujituHenkou({
  required Ghensuu currentGhensuu,
  required int univid,
  required int targetGroup,
}) async {
  final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData? kantoku = kantokuBox.get('KantokuData');
  if (kantoku == null || kantoku.yobiint2.length <= manualToujituMaskIndex) {
    return;
  }
  final int racebangou = currentGhensuu.hyojiracebangou;
  final int day = racebangou == 2 ? (targetGroup == 0 ? 1 : 2) : 0;
  final int code = _toujituCode(currentGhensuu.year, racebangou, day);
  if (kantoku.yobiint2[manualToujituCodeIndex] != code) {
    kantoku.yobiint2[manualToujituCodeIndex] = code;
    kantoku.yobiint2[manualToujituMaskIndex] = 0;
  }
  kantoku.yobiint2[manualToujituMaskIndex] |= (1 << univid);
  await kantoku.save();
}

// ------------------------------------------------------------
// 当日変更の表示用(確定直後の画面・当日変更選手一覧)
// ------------------------------------------------------------

/// コンピュータ大学の当日変更の理由(表示用)。プレイヤーの大学ならnullを返す
/// 理由は今のデータから判断する
///   他大学変更で確定した大学 → 他大学変更
///   外れた選手の調子が0 → 体調不良のため
///   入った選手が当て馬で隠したエース → 当て馬から本来の選手へ
///   それ以外 → 調子○○のため
/// [kukan] 区間(0始まり)
String? comToujituHenkouRiyuu({
  required Ghensuu gh,
  required int racebangou,
  required int univid,
  required int kukan,
  required SenshuData outPlayer,
  required SenshuData inPlayer,
}) {
  if (univid == gh.MYunivid) return null;
  final int day = racebangou == 2 ? (kukan < 5 ? 1 : 2) : 0;
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku != null &&
      kantoku.yobiint2.length > manualToujituMaskIndex &&
      kantoku.yobiint2[manualToujituCodeIndex] ==
          _toujituCode(gh.year, racebangou, day) &&
      (kantoku.yobiint2[manualToujituMaskIndex] >> univid) & 1 == 1) {
    return '他大学変更';
  }
  if (outPlayer.chousi == 0) return '体調不良のため';
  if (inPlayer.kazetaisei == kukan + 1) return '当て馬から本来の選手へ';
  return '調子${outPlayer.chousi}のため';
}

/// その日のコンピュータ大学の当日変更を、表示用の文字列の一覧にする
/// [day] 0=1日開催、1=正月駅伝往路、2=正月駅伝復路
List<String> comToujituHenkouHyouji({
  required Ghensuu gh,
  required int racebangou,
  required int day,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> senshuList,
}) {
  final List<String> lines = [];
  for (final univ in sortedUnivData) {
    if (univ.id == gh.MYunivid) continue;
    if (univ.taikaientryflag[racebangou] != 1) continue;
    final List<SenshuData> team = senshuList
        .where((s) => s.univid == univ.id)
        .toList();
    final List<SenshuData> outs =
        team.where((s) {
          final int e = _entry(s, racebangou);
          return e <= -100 && _isTaishouKukan(racebangou, day, -e - 100);
        }).toList()..sort(
          (x, y) =>
              _entry(y, racebangou).compareTo(_entry(x, racebangou)),
        ); // 区間順(-100, -101, ...)
    for (final out in outs) {
      final int k = -_entry(out, racebangou) - 100;
      SenshuData? inPlayer;
      for (final s in team) {
        if (_entry(s, racebangou) == k) {
          inPlayer = s;
          break;
        }
      }
      if (inPlayer == null) continue;
      final String? riyuu = comToujituHenkouRiyuu(
        gh: gh,
        racebangou: racebangou,
        univid: univ.id,
        kukan: k,
        outPlayer: out,
        inPlayer: inPlayer,
      );
      lines.add(
        '${univ.name} ${k + 1}区 ${out.name}(${out.gakunen}年)→'
        '${inPlayer.name}(${inPlayer.gakunen}年)${riyuu != null ? '（$riyuu）' : ''}',
      );
    }
  }
  return lines;
}

// ------------------------------------------------------------
// 区間エントリーの整合性チェックと自動修復
// ------------------------------------------------------------

/// 各大学で「1区間に走者がちょうど1人」になるように直す(区間空白・区間重複の防止)
/// ・区間番号が区間数以上の選手は補欠に戻す
/// ・重複している区間は、一番速い見込みの選手を残して他を補欠に戻す
/// ・空白の区間は、補欠(体調不良でない選手→体調不良の選手→エントリー外の選手の順)から
///   一番速い見込みの選手で埋める。当日変更で外れた選手は使わない
/// [kaishiKukan] この区間以降だけを対象にする(正月駅伝の復路開始時は5)
/// [kukannaiJuniSaikeisan] 修復した場合に区間内順位を再計算するか
Future<void> kukanSeigouseiShuufuku({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
  int kaishiKukan = 0,
  bool kukannaiJuniSaikeisan = false,
}) async {
  if (!_isEkiden(racebangou)) return;
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (kantoku == null) return;

  final int kukansuu = gh[0].kukansuu_taikaigoto[racebangou];
  // 試走タイムは表示中の大会のコースで計算されるので、違う場合は基本走力で代用する
  final bool shisouTimeOk = gh[0].hyojiracebangou == racebangou;
  final mitumori = _Mitumori(gh[0], sortedSenshuData, sortedUnivData, kantoku);
  Future<double> hyouka(SenshuData s, int k) async =>
      shisouTimeOk ? await mitumori.time(s, k) : s.a;
  Future<SenshuData?> ichibanHayai(List<SenshuData> kouho, int k) async {
    SenshuData? best;
    double bestAtai = double.infinity;
    for (final s in kouho) {
      final double atai = await hyouka(s, k);
      if (atai < bestAtai) {
        bestAtai = atai;
        best = s;
      }
    }
    return best;
  }

  bool shuufukuAri = false;
  for (final univ in sortedUnivData) {
    if (univ.taikaientryflag[racebangou] != 1) continue;
    await _yasumi();
    final List<SenshuData> team = sortedSenshuData
        .where((s) => s.univid == univ.id)
        .toList();
    final Set<SenshuData> henkouari = {};

    // 区間番号が範囲外の選手は補欠に戻す
    for (final s in team) {
      final int e = _entry(s, racebangou);
      if (e >= kukansuu) {
        _debugLog('[区間修復] ${univ.name} ${s.name} 区間番号${e + 1}が範囲外のため補欠に戻す');
        _setEntry(s, racebangou, -1);
        henkouari.add(s);
      }
    }

    for (int k = kaishiKukan; k < kukansuu; k++) {
      final List<SenshuData> runners = team
          .where((s) => _entry(s, racebangou) == k)
          .toList();
      if (runners.length > 1) {
        // 区間重複: 一番速い見込みの選手を残す
        final SenshuData? nokosu = await ichibanHayai(runners, k);
        for (final s in runners) {
          if (s == nokosu) continue;
          _debugLog('[区間修復] ${univ.name} ${k + 1}区の重複 ${s.name} を補欠に戻す');
          _setEntry(s, racebangou, -1);
          henkouari.add(s);
        }
      } else if (runners.isEmpty) {
        // 区間空白: 補欠で埋める
        List<SenshuData> kouho = team
            .where((s) => _entry(s, racebangou) == -1 && s.chousi != 0)
            .toList();
        if (kouho.isEmpty) {
          kouho = team.where((s) => _entry(s, racebangou) == -1).toList();
        }
        if (kouho.isEmpty) {
          kouho = team.where((s) => _entry(s, racebangou) == -2).toList();
        }
        final SenshuData? umeru = await ichibanHayai(kouho, k);
        if (umeru != null) {
          _debugLog('[区間修復] ${univ.name} ${k + 1}区の空白に ${umeru.name} を配置');
          _setEntry(umeru, racebangou, k);
          henkouari.add(umeru);
        } else {
          _debugLog('[区間修復] ${univ.name} ${k + 1}区の空白を埋められる選手がいない');
        }
      }
    }

    for (final s in henkouari) {
      await s.save();
    }
    if (henkouari.isNotEmpty) shuufukuAri = true;
  }

  if (shuufukuAri && kukannaiJuniSaikeisan) {
    await _kukannaiJunSaikeisan(racebangou, kukansuu, sortedSenshuData);
  }
}
