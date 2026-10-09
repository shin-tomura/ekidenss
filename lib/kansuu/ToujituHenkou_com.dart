import 'dart:math'; // Randomクラスを使用するため
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/kansuu/chousi_keiken_hosei.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ------------------------------------------------------------
// コンピュータ大学の区間エントリー後処理と当日変更
//
// ・区間エントリー時: 体調不良(調子0)の選手を区間から外し、補欠と入れ替える
// ・区間エントリー時: 戦略的エントリー(設定の確率で実施)
//     エース(基本走力aの上位)をいったん補欠に登録して温存し、空いた区間には補欠の選手を登録する
//     温存する人数: 10月駅伝1人、11月駅伝2人、正月駅伝3人、
//                   カスタム駅伝は区間数6以下1人、8以下2人、それ以上3人
//     温存する選手は、基本走力の上位5人のうち「どの区間でも走れる」選手を優先する
//       (元の区間の日の区間のうち、チーム内で見込みタイムが3番以内の区間の数が多い順。
//        同じなら基本走力順)
//     温存した選手には kazetaisei に使う日の印を負の値で付ける(-1=1日開催・正月駅伝往路、-2=正月駅伝復路)
//     (kazetaiseiは新入生の作成時に1〜99の乱数が入る(風耐性の名残)ため、取り違えないよう負の値にしている)
// ・当日変更: プレイヤーの当日変更確定後(当日変更画面を通らない場合はレース計算開始時)
//     優先度1: 体調不良の走者を補欠と交代(補欠のほうが速い見込みの場合)
//     優先度2: 温存したエースを、その日の区間のうち見込みタイムが最も縮まる区間に起用する(戦略的変更)
//              どの区間でも縮まらなければ起用しない。正月駅伝の往路で起用しなかった選手は復路でも候補にする
//     優先度3: 調子が100未満の走者で、補欠のほうが明らかに速い見込み(0.3%以上)の場合に交代
//     見込みタイムは試走タイム(TrialTime)に当日の調子補正を加えたもの
//     交代人数の上限はプレイヤーと同じ(区間数6以下2人、8以下3人、それ以上6人、
//     正月駅伝は往路4人・復路4人、合計6人)
// ・箱庭モードの「他大学変更」で確定した大学は、その日の自動当日変更をしない
// ・区間エントリーの整合性チェックと自動修復(全大学、学連選抜は除く)
//     区間エントリー決定後とレース計算開始時に、1区間に走者がちょうど1人になるよう直す
//
// KantokuData.yobiint2 の使用番号
//   [34] 戦略的エントリー確率(0〜100、初期値0)
//   [35] コンピュータ当日変更の実行済みコード(年*100+大会番号*10+日)
//   [36] 手動当日変更マスクのコード(年*100+大会番号*10+日)
//   [37] 手動当日変更した大学のビットマスク
// 日: 0=1日開催、1=正月駅伝往路、2=正月駅伝復路
// ------------------------------------------------------------

const int senryakuKakurituIndex = 34;
const int comToujituDoneIndex = 35;
const int manualToujituCodeIndex = 36;
const int manualToujituMaskIndex = 37;

/// 戦略的エントリー確率(0〜100。0なら戦略的エントリーをしない。初期値は0)
/// 設定タブの「戦略的エントリー確率設定」(screens/senryaku_entry_settei.dart)で変える。
/// 説明書と生成AI向けの文(shiyou_text.dart・ai_copy_matome.dart)で、書くかどうかを決めるのに使う(1.9.4)
int senryakuEntryKakuritu(KantokuData? kantoku) {
  if (kantoku == null || kantoku.yobiint2.length <= senryakuKakurituIndex) {
    return 0;
  }
  return kantoku.yobiint2[senryakuKakurituIndex].clamp(0, 100);
}

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

/// 戦略的エントリーで温存する選手の候補数(基本走力の上位何人から選ぶか)
const int _senryakuKouhoSuu = 5;

/// 温存した選手に付ける使う日の印(kazetaisei)
/// -1=1日開催・正月駅伝往路、-2=正月駅伝復路
/// kazetaiseiには新入生の作成時に1〜99の乱数が入る(風耐性の名残)ので、
/// それと取り違えないよう負の値にしている
int _onzonHi(int racebangou, int kukan) =>
    (racebangou == 2 && kukan >= 5) ? -2 : -1;

/// 戦略的エントリーで温存した選手か(負の値の印が付いている)
bool _isOnzon(SenshuData s) => s.kazetaisei < 0;

/// その日に戦略的変更で起用できる温存選手か
/// (正月駅伝の往路で起用しなかった選手は復路でも候補にする)
bool _onzonKiyouKanou(SenshuData s, int racebangou, int day) {
  if (!_isOnzon(s)) return false;
  if (racebangou == 2 && day == 1) return s.kazetaisei == -1;
  return true;
}

/// 戦略的エントリーで温存する人数
int _senryakuNinzuu(int racebangou, int kukansuu) {
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

/// 調子によるタイム補正の倍率(RaceCalcの調子補正と共通の式。chousi_keiken_hosei.dart)
double _chousiKeisuu(SenshuData s, KantokuData kantoku) {
  return chousiHoseiBairitsu(s, kantoku);
}

Future<void> _yasumi() async {
  final now = DateTime.now();
  if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
    await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
    Chousa.lastGapTime = DateTime.now();
  }
}

/// 区間エントリー時に EntryCalc が計算した試走タイム(調子補正なし・乱数なし)
/// キーは 選手ID*100+区間。EntryCalcの開始時と区間エントリー後処理の後に消す
/// (区間エントリー後処理で同じ計算をやり直さないための使い回し用)
final Map<int, double> entryShisouTimeCache = {};

/// 見込みタイム(試走タイム×調子補正)をキャッシュしながら計算する
class _Mitumori {
  final Ghensuu gh;
  final List<SenshuData> sortedSenshuData;
  final List<UnivData> sortedUnivData;
  final KantokuData kantoku;
  final Map<int, double>? shisouTime; // 使い回せる試走タイム(なければnull)
  final Map<int, double> _cache = {};

  _Mitumori(
    this.gh,
    this.sortedSenshuData,
    this.sortedUnivData,
    this.kantoku, {
    this.shisouTime,
  });

  Future<double> time(SenshuData s, int kukan) async {
    final int key = s.id * 100 + kukan;
    final double? cached = _cache[key];
    if (cached != null) return cached;
    double? t = shisouTime?[key];
    if (t == null) {
      await _yasumi(); // フリーズ対策
      // 判断がぶれないよう、±0.5%の乱数(濁し)をかけない試走タイムを使う
      t = await runTrialCalculation(
        s.id,
        kukan,
        gh,
        sortedSenshuData,
        sortedUnivData,
        kantoku,
        nigosu: false,
      );
    }
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
  final int senryakuKakuritu = kantoku.yobiint2.length > senryakuKakurituIndex
      ? kantoku.yobiint2[senryakuKakurituIndex]
      : 0;
  final mitumori = _Mitumori(
    gh[0],
    sortedSenshuData,
    sortedUnivData,
    kantoku,
    shisouTime: entryShisouTimeCache, // EntryCalcで計算済みの試走タイムを使い回す
  );

  for (final univ in sortedUnivData) {
    if (univ.taikaientryflag[racebangou] != 1) continue;
    await _yasumi();

    final List<SenshuData> team = sortedSenshuData
        .where((s) => s.univid == univ.id && _entry(s, racebangou) >= -1)
        .toList();
    final Set<SenshuData> henkouari = {};

    // 戦略的エントリー用の「使う日」の印(負の値)をクリア
    // (正の値は風耐性の名残なので触らない)
    // プレイヤーの大学も消す(途中で大学を変えた場合に、コンピュータ時代の印が残らないように)
    for (final s in team) {
      if (_isOnzon(s)) {
        s.kazetaisei = 0;
        henkouari.add(s);
      }
    }
    if (univ.id == gh[0].MYunivid) {
      for (final s in henkouari) {
        await s.save();
      }
      continue;
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

    // ③ 戦略的エントリー
    if (senryakuKakuritu > 0 && random.nextInt(100) < senryakuKakuritu) {
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
      // 候補は基本走力の上位5人。「どの区間でも走れる」選手を優先して温存する
      // 汎用性 = 元の区間の日の区間のうち、チーム内で見込みタイムが3番以内の区間の数
      final List<SenshuData> kouho = runners.take(_senryakuKouhoSuu).toList();
      final List<SenshuData> hikaku = team
          .where((s) => s.chousi != 0)
          .toList();
      final Map<int, int> hanyousei = {};
      final Map<int, int> kukanKazu = {};
      for (final c in kouho) {
        // 正月駅伝は、元の区間の日(1〜5区なら往路、6〜10区なら復路)の区間で数える
        final int day = racebangou == 2
            ? (_entry(c, racebangou) < 5 ? 1 : 2)
            : 0;
        int kazu = 0;
        int taishou = 0;
        for (int k = 0; k < kukansuu; k++) {
          if (!_isTaishouKukan(racebangou, day, k)) continue;
          taishou++;
          final double t = await mitumori.time(c, k);
          int hayai = 0; // cより速い見込みの選手の数
          for (final o in hikaku) {
            if (o.id == c.id) continue;
            if (await mitumori.time(o, k) < t) {
              hayai++;
              if (hayai >= 3) break;
            }
          }
          if (hayai < 3) kazu++;
        }
        hanyousei[c.id] = kazu;
        kukanKazu[c.id] = taishou;
      }
      kouho.sort((x, y) {
        final int c = hanyousei[y.id]!.compareTo(hanyousei[x.id]!);
        if (c != 0) return c;
        final int c2 = x.a.compareTo(y.a); // 基本走力は小さいほど良い
        return c2 != 0 ? c2 : x.id.compareTo(y.id);
      });
      final List<SenshuData> aces = kouho
          .take(_senryakuNinzuu(racebangou, kukansuu))
          .toList();
      for (final ace in aces) {
        final int k = _entry(ace, racebangou);
        final List<SenshuData> subs = team
            .where(
              (s) =>
                  _entry(s, racebangou) == -1 &&
                  s.chousi != 0 &&
                  !_isOnzon(s), // 温存したエースは代わりの選手にしない
            )
            .toList();
        final SenshuData? kawari = await mitumori.fastest(subs, k);
        if (kawari == null) break;
        _setEntry(ace, racebangou, -1);
        ace.kazetaisei = _onzonHi(racebangou, k); // 使う日の印
        _setEntry(kawari, racebangou, k);
        henkouari.add(ace);
        henkouari.add(kawari);
        _debugLog(
          '[COM戦略的エントリー] ${_taikaiMei(racebangou)} ${univ.name} ${k + 1}区 '
          'エース${ace.name}(${ace.gakunen}年、チーム内3番以内の区間${hanyousei[ace.id]}/${kukanKazu[ace.id]})'
          'を補欠に温存し、${kawari.name}(${kawari.gakunen}年)を登録',
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
      // 調子100の走者は、温存したエースを起用する場合のみ交代を検討する
      // (温存したエースは、その日の区間ならどこにでも起用できる)
      final List<SenshuData> kentouSubs = runner.chousi < 100
          ? subs
          : subs
                .where((s) => _onzonKiyouKanou(s, racebangou, day))
                .toList();
      if (kentouSubs.isEmpty) continue;
      final double genzai = await mitumori.time(runner, k);
      for (final sub in kentouSubs) {
        final double gain = genzai - await mitumori.time(sub, k);
        if (gain <= 0) continue;
        final bool onzon = _onzonKiyouKanou(sub, racebangou, day);
        int yuusen;
        if (runner.chousi == 0) {
          yuusen = 2; // 体調不良の走者の交代
        } else if (onzon) {
          yuusen = 1; // 温存したエースを起用する(戦略的変更)
        } else if (_isOnzon(sub)) {
          continue; // 正月駅伝の復路用に温存した選手は、往路では体調不良の交代にだけ使う
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
                ? '戦略的変更'
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
// 当日変更の表示用(当日変更選手一覧)
// ------------------------------------------------------------

/// コンピュータ大学の当日変更の理由(表示用)。プレイヤーの大学ならnullを返す
/// 理由は今のデータから判断する
///   他大学変更で確定した大学 → 他大学変更
///   外れた選手の調子が0 → 体調不良のため
///   入った選手が戦略的エントリーで温存した選手 → 戦略的変更
///   外れた選手の調子が100 → 他大学変更
///     (自動の当日変更は調子100の選手を戦略的変更以外で外さないため。
///      他大学変更の目印は1日分しか覚えていないので、正月駅伝で往路と復路の
///      両方で他大学変更を使った場合の往路分もここで判定される)
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
  if (inPlayer.kazetaisei < 0) return '戦略的変更';
  if (outPlayer.chousi >= 100) return '他大学変更';
  return '調子${outPlayer.chousi}のため';
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
    // 見込みタイムが計算できない場合(区間距離0などで全員NaN)でも、区間を空にしないよう先頭を選ぶ
    return best ?? (kouho.isNotEmpty ? kouho.first : null);
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
