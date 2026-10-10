import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/screens/ModalAverageTimeRankingView.dart';
import 'package:ekiden/kansuu/ikku_pace.dart'; // 1区の集団のペース(1.9.2)
import 'package:ekiden/screens/ikku_pace_box.dart'; // 1区のペース予想の枠(1.9.2)
import 'package:ekiden/kansuu/kiji/kiji.dart'; // 展望記事(1.9.2)
import 'package:ekiden/screens/kiji_screen.dart'; // 展望記事の画面(1.9.2)
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/TrialTime.dart'; // オッシーの予想(基本走力だけの見込みタイム。1.9.4)

// 予想結果を保持するためのクラス
class Prediction {
  final int id;
  final String name;
  final double score;

  Prediction(this.id, this.name, this.score);
}

// 予想陣の予想(1.9.4で、オッシーと王太郎の計算を区間ごとの見込みタイムに変えた)
// 1.9.5で、3人の予想が似すぎないよう、それぞれに見方の癖を付けた(父ちゃんが一番当たる役)
// ・オッシー(基本走力・エース重視): 区間の距離を基本走力だけで走ったときの見込みタイム(試走の計算の、
//   能力の補正の前)で、区間(組)ごとに全選手の中の順位を出し、順位(0から)の平方根の合計が小さい順。
//   区間の上位どうしの差を大きく、下位どうしの差を小さく見るので、区間上位の選手がいる大学を高く見る
//   (1.9.4は見込みタイムの合計)
// ・父ちゃん(総合評価・層の厚さ重視): 区間の距離に合った種目の持ちタイムに、登り・下り・アップダウンの
//   能力をコースで重み付けした点の合計(1.9.3まで通り)から、その区間の最高点との差が一番大きい選手の差を引く
//   (ブレーキになりそうな区間を2回数える)
// ・王太郎(夏のタイムトライアル重視): 夏の学内タイムトライアル(登り1万・下り1万・ロード1万・クロカン1万)の
//   持ちタイムを、区間の登り・下り・平らの距離の割合で混ぜ、区間の距離に換算したタイムの合計(_otaroTTMikomiTime)。
//   秋以降の伸びを見ないので、正月駅伝では秋に伸びた大学を低く見がち
//   (1.9.3までは入学時の5000mの合計、1.9.4は自己ベストを区間の距離に換算したタイムの合計)
List<double> kukanshou_bestscore_osshi = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  TEISUU.DEFAULTTIME,
);
List<int> kukanshou_id_osshi = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
List<double> kukanshou_bestscore_tochan = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  -999999999.0,
);
List<int> kukanshou_id_tochan = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
List<double> kukanshou_bestscore_otaro = List.filled(
  TEISUU.SUU_MAXKUKANSUU,
  TEISUU.DEFAULTTIME,
);
List<int> kukanshou_id_otaro = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
double temp_osshi_score = 0.0;
double temp_tochan_score = 0.0;
double temp_otaro_score = 0.0;

/// 種目(time_bestkiroku の0〜2)の距離(m。持ちタイムの換算に使う。展望記事の戦力分析と同じ)
const List<double> _shumokuKyori = [5000.0, 10000.0, 21097.5];

/// 王太郎の予想に使う、選手の区間の見込みタイム(自己ベストから。1.9.4)
/// 区間の距離に合った種目(7.5km以下は5000m、15km以下は1万m、それより長いとハーフ)の自己ベストを、
/// 距離の比の1.06乗で区間の距離に換算する。その種目の記録がなければ、距離の近いほかの種目から換算する。
/// どの種目の記録もなければ、入学時の5000mから換算し、それもなければnull
double? _otaroMikomiTime(SenshuData s, double kyori) {
  if (kyori <= 0) return null;
  final int idx = kyori <= 7500 ? 0 : (kyori <= 15000 ? 1 : 2);
  double? moto;
  double motoKyori = _shumokuKyori[idx];
  if (s.time_bestkiroku.length > idx && s.time_bestkiroku[idx] > 0 && s.time_bestkiroku[idx] < TEISUU.DEFAULTTIME) {
    moto = s.time_bestkiroku[idx];
  } else {
    final List<int> kouho = [0, 1, 2]
      ..remove(idx)
      ..sort((a, b) => (_shumokuKyori[a] - _shumokuKyori[idx]).abs().compareTo((_shumokuKyori[b] - _shumokuKyori[idx]).abs()));
    for (final int c in kouho) {
      if (s.time_bestkiroku.length > c && s.time_bestkiroku[c] > 0 && s.time_bestkiroku[c] < TEISUU.DEFAULTTIME) {
        moto = s.time_bestkiroku[c];
        motoKyori = _shumokuKyori[c];
        break;
      }
    }
  }
  if (moto == null && s.kiroku_nyuugakuji_5000 > 0 && s.kiroku_nyuugakuji_5000 < TEISUU.DEFAULTTIME) {
    moto = s.kiroku_nyuugakuji_5000;
    motoKyori = _shumokuKyori[0];
  }
  if (moto == null) return null;
  return moto * pow(kyori / motoKyori, 1.06).toDouble();
}

/// 夏の学内タイムトライアルの持ちタイム(time_bestkiroku の4=登り1万・5=下り1万・6=ロード1万・7=クロカン1万。なければnull)
double? _natsuTTBest(SenshuData s, int idx) {
  if (s.time_bestkiroku.length <= idx) return null;
  final double t = s.time_bestkiroku[idx];
  return (t > 0 && t < TEISUU.DEFAULTTIME) ? t : null;
}

/// 王太郎の予想に使う、選手の区間の見込みタイム(夏の学内タイムトライアルの持ちタイムから。1.9.5)
/// 区間の登り([nobori])・下り([kudari])・平らの距離の割合で、登り1万・下り1万・平らの部分の記録を混ぜた
/// 1万mのタイムを、距離の比の1.06乗で区間の距離に換算する。
/// 平らの部分は、試走の計算のロード適性とペース変動対応力の効き方に合わせて、1区(正月駅伝予選は除く)と
/// 11月駅伝予選はクロカン1万、2・3区と正月駅伝予選はロード1万とクロカン1万の平均、ほかはロード1万。
/// その記録がない(1年生の最初の夏より前など)ときは、トラックの持ちタイムを1万mに換算した値で代用し、
/// それもなければnull
double? _otaroTTMikomiTime(
  SenshuData s,
  double kyori,
  double nobori,
  double kudari,
  int race,
  int kukan,
) {
  if (kyori <= 0) return null;
  final double? track = _otaroMikomiTime(s, 10000.0);
  double? kiroku(int idx) => _natsuTTBest(s, idx) ?? track;
  double n = nobori.isNaN ? 0.0 : nobori.abs().clamp(0.0, 1.0).toDouble();
  double k = kudari.isNaN ? 0.0 : kudari.abs().clamp(0.0, 1.0).toDouble();
  if (n + k > 1.0) {
    final double g = n + k;
    n /= g;
    k /= g;
  }
  final double f = 1.0 - n - k;
  double ichiman = 0.0; // 1万mのタイム
  if (n > 0) {
    final double? t = kiroku(4);
    if (t == null) return null;
    ichiman += n * t;
  }
  if (k > 0) {
    final double? t = kiroku(5);
    if (t == null) return null;
    ichiman += k * t;
  }
  if (f > 0) {
    final double? road = kiroku(6);
    final double? kurokan = kiroku(7);
    double? t;
    if ((race != 4 && kukan == 0) || race == 3) {
      t = kurokan;
    } else if (race == 4 || kukan == 1 || kukan == 2) {
      t = (road != null && kurokan != null) ? (road + kurokan) / 2.0 : null;
    } else {
      t = road;
    }
    if (t == null) return null;
    ichiman += f * t;
  }
  return ichiman * pow(kyori / 10000.0, 1.06).toDouble();
}

class Mode0330Content extends StatelessWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode;

  const Mode0330Content({super.key, required this.ghensuu, this.onAdvanceMode});

  // ゲームを進めるボタンのアクション
  void _advanceGameMode() {
    onAdvanceMode?.call();
  }

  /// 自分の大学の1区の選手のid(1区のペース予想用。いなければnull。1.9.2)
  int? _ikkuJibunSenshuId(Ghensuu gh, List<SenshuData> sortedSenshuData) {
    final int race = gh.hyojiracebangou;
    for (final SenshuData s in sortedSenshuData) {
      if (s.univid != gh.MYunivid) continue;
      if (race >= s.entrykukan_race.length) continue;
      final int g = s.gakunen - 1;
      if (g < 0 || g >= s.entrykukan_race[race].length) continue;
      if (s.entrykukan_race[race][g] == 0) return s.id;
    }
    return null;
  }

  // 複数の大学の予想結果から順位を決定する関数
  List<Prediction> _getRankedPredictions(
    List<Prediction> predictions,
    bool isAscending, // trueなら昇順、falseなら降順
  ) {
    // スコアでソート
    final sortedPredictions = predictions.toList()
      ..sort((a, b) {
        final comparison = a.score.compareTo(b.score);
        return isAscending ? comparison : -comparison;
      });

    // 順位を計算して新しいリストを作成
    final rankedList = <Prediction>[];
    int currentRank = 1;
    for (int i = 0; i < sortedPredictions.length; i++) {
      final current = sortedPredictions[i];
      if (i > 0 && current.score != sortedPredictions[i - 1].score) {
        currentRank = i + 1;
      }
      rankedList.add(
        Prediction(
          current.id,
          '${currentRank}位 ${current.name}',
          current.score,
        ),
      );
    }
    return rankedList;
  }

  // 各大学の合計スコアを計算する関数
  Map<String, List<Prediction>> _calculateAllPredictions(
    int raceNumber,
    List<UnivData> sortedUnivData,
    List<SenshuData> sortedSenshuData,
  ) {
    // 予想結果を格納するためのマップ
    final Map<String, List<Prediction>> allPredictions = {
      'osshi': [],
      'tochan': [],
      'otaro': [],
    };
    final gh = Hive.box<Ghensuu>('ghensuuBox').values.toList();
    if (gh.isEmpty) {
      return allPredictions;
    }
    // オッシーの予想(基本走力だけの見込みタイム)の計算に使う(1.9.4)
    final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    for (int i = 0; i < TEISUU.SUU_MAXKUKANSUU; i++) {
      kukanshou_bestscore_osshi[i] = TEISUU.DEFAULTTIME;
      kukanshou_bestscore_otaro[i] = TEISUU.DEFAULTTIME;
      kukanshou_bestscore_tochan[i] = -999999999.0;
    }
    // オッシーと父ちゃんは、全大学の選手を見てから点を決めるので、選手ごとの値を残しておく(1.9.5)
    final List<({int u, int k, double t})> osshiSenshu = [];
    final List<({int u, int k, double t})> tochanSenshu = [];
    // 出場選手のいる大学(並びは大学id順)と、父ちゃんの今までの合計点
    final List<({int id, String name, double tochan})> shutsujou = [];
    // 各大学について計算
    for (final univ in sortedUnivData) {
      if (univ.taikaientryflag.length > raceNumber &&
          univ.taikaientryflag[raceNumber] == 1) {
        // 出場大学のみを対象とする
        double osshiScore = 0.0;
        double tochanScore = 0.0;
        double otaroScore = 0.0;
        int entryCount = 0;
        double max1_osshiscore = -999999999.0;
        double max2_osshiscore = -999999999.0;
        double max1_otaroscore = -999999999.0;
        double max2_otaroscore = -999999999.0;
        double min1_tochanscore = 999999999.0;
        double min2_tochanscore = 999999999.0;

        // 出場選手を合計する(iSenshu は id順の並びの番号。試走の計算に渡す)
        for (int iSenshu = 0; iSenshu < sortedSenshuData.length; iSenshu++) {
          final senshu = sortedSenshuData[iSenshu];
          if (senshu.univid == univ.id) {
            // entrykukan_raceが定義されており、かつレース番号に対応する区間情報があるかを確認
            if (senshu.entrykukan_race.length > raceNumber &&
                senshu.entrykukan_race[raceNumber][senshu.gakunen - 1] >= 0) {
              entryCount++;
              final int osshiKukan = senshu.entrykukan_race[raceNumber][senshu.gakunen - 1];
              final double osshiKyori =
                  (gh[0].kyori_taikai_kukangoto.length > raceNumber && gh[0].kyori_taikai_kukangoto[raceNumber].length > osshiKukan)
                  ? gh[0].kyori_taikai_kukangoto[raceNumber][osshiKukan]
                  : 0.0;
              // オッシー：区間の距離を基本走力だけで走ったときの見込みタイム(秒。小さい方が良い。1.9.4)
              if (kantoku != null && osshiKyori > 0) {
                temp_osshi_score = trialTimeKeisan(
                  iSenshu,
                  osshiKukan,
                  gh[0],
                  sortedSenshuData,
                  sortedUnivData,
                  kantoku,
                  nigosu: false,
                  racebangou: raceNumber,
                  kihonDake: true,
                );
              } else {
                temp_osshi_score = _NEWaintFromNewbint(1580, senshu).toDouble();
              }
              osshiScore += temp_osshi_score;
              osshiSenshu.add((u: univ.id, k: osshiKukan, t: temp_osshi_score));
              if (raceNumber == 4) {
                if (temp_osshi_score > max1_osshiscore) {
                  max2_osshiscore = max1_osshiscore;
                  max1_osshiscore = temp_osshi_score;
                } else if (temp_osshi_score > max2_osshiscore) {
                  max2_osshiscore = temp_osshi_score;
                }
              }
              if (temp_osshi_score <
                  kukanshou_bestscore_osshi[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_osshi[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_osshi_score;
                kukanshou_id_osshi[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }
              // 王太郎：夏の学内タイムトライアルの持ちタイムを、区間のコースに合わせて混ぜ、
              // 区間の距離に換算した見込みタイム(秒。小さい方が良い。1.9.5)
              // (どの記録もない選手は、オッシーの見込みタイムで代用する)
              final double otaroNobori =
                  (gh[0].kyoriwariainobori_taikai_kukangoto.length > raceNumber &&
                      gh[0].kyoriwariainobori_taikai_kukangoto[raceNumber].length > osshiKukan)
                  ? gh[0].kyoriwariainobori_taikai_kukangoto[raceNumber][osshiKukan]
                  : 0.0;
              final double otaroKudari =
                  (gh[0].kyoriwariaikudari_taikai_kukangoto.length > raceNumber &&
                      gh[0].kyoriwariaikudari_taikai_kukangoto[raceNumber].length > osshiKukan)
                  ? gh[0].kyoriwariaikudari_taikai_kukangoto[raceNumber][osshiKukan]
                  : 0.0;
              temp_otaro_score = _otaroTTMikomiTime(
                    senshu,
                    osshiKyori,
                    otaroNobori,
                    otaroKudari,
                    raceNumber,
                    osshiKukan,
                  ) ??
                  temp_osshi_score;
              otaroScore += temp_otaro_score;
              if (raceNumber == 4) {
                if (temp_otaro_score > max1_otaroscore) {
                  max2_otaroscore = max1_otaroscore;
                  max1_otaroscore = temp_otaro_score;
                } else if (temp_otaro_score > max2_otaroscore) {
                  max2_otaroscore = temp_otaro_score;
                }
              }
              if (temp_otaro_score <
                  kukanshou_bestscore_otaro[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_otaro[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_otaro_score;
                kukanshou_id_otaro[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }

              // 父ちゃん：合計値（大きい方が良い）
              // --- 父ちゃんの予測精度を向上させるための新しい計算ロジック ---
              // ※ここではgh[0].kyori_taikai_kukangotoなどのデータが
              //   正しく存在することを前提とします。
              // 各区間の合計スコアを計算
              int kukanIndex =
                  senshu.entrykukan_race[raceNumber][senshu.gakunen - 1];
              double kukanKyoriScore =
                  0.01 * gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanNoboriScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariainobori_taikai_kukangoto[raceNumber][kukanIndex] *
                  gh[0]
                      .heikinkoubainobori_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanKudariScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariaikudari_taikai_kukangoto[raceNumber][kukanIndex] *
                  gh[0]
                      .heikinkoubaikudari_taikai_kukangoto[raceNumber][kukanIndex];
              double kukanKirikaeScore =
                  4.0 *
                  gh[0]
                      .noborikudarikirikaekaisuu_taikai_kukangoto[raceNumber][kukanIndex]
                      .toDouble();
              kukanKudariScore = kukanKudariScore.abs();
              double senshuKyoriScore = 0;
              double kukanbetuhosei = 0.0;
              double hosei_tani = 0.0;
              double hosei_time = 0.0;
              double temp_time = 0.0;
              if (senshu.time_bestkiroku.length > 2 &&
                  gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex] >
                      15000) {
                temp_time = senshu.time_bestkiroku[2];
                //temp_time = 1.0;
                hosei_tani = 105.4875 / 100.0;
                if ((kukanIndex == 0 && raceNumber != 4) || raceNumber == 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time + hosei_time;
                }
                if (((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) ||
                    raceNumber == 4) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time + hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  //補正なし
                }
                senshuKyoriScore = (-5 / 12) * temp_time + 1625;
              } else if (senshu.time_bestkiroku.length > 1 &&
                  gh[0].kyori_taikai_kukangoto[raceNumber][kukanIndex] > 7500) {
                temp_time = senshu.time_bestkiroku[1];
                //temp_time = 1.0;
                hosei_tani = 50.0 / 100.0;
                if (kukanIndex == 0 || raceNumber == 3) {
                  //補正なし
                }
                if ((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
              } else if (senshu.time_bestkiroku.length > 0) {
                temp_time = senshu.time_bestkiroku[0];
                //temp_time = 1.0;
                hosei_tani = 25.0 / 100.0;
                if (kukanIndex == 0 || raceNumber == 3) {
                  //補正なし
                }
                if ((kukanIndex == 1 || kukanIndex == 2) && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2 && raceNumber != 3) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 3) * temp_time + 2850;
              }
              senshuKyoriScore *= 7;
              double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
              double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
              double senshuKirikaeScore =
                  3 * senshu.noborikudarikirikaenouryoku.toDouble();
              double specialScore = 0;
              specialScore = 0;
              double totalScore =
                  (kukanKyoriScore * senshuKyoriScore) +
                  (kukanNoboriScore * senshuNoboriScore) +
                  (kukanKudariScore * senshuKudariScore) +
                  (kukanKirikaeScore * senshuKirikaeScore) +
                  specialScore;
              if (totalScore.isNaN) {
                totalScore = -99999.0;
              }
              temp_tochan_score = totalScore;
              if (temp_tochan_score >
                  kukanshou_bestscore_tochan[senshu
                      .entrykukan_race[raceNumber][senshu.gakunen - 1]]) {
                kukanshou_bestscore_tochan[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    temp_tochan_score;
                kukanshou_id_tochan[senshu
                        .entrykukan_race[raceNumber][senshu.gakunen - 1]] =
                    senshu.id;
              }
              // 各選手の合計スコアを父ちゃんのスコアに加算
              tochanScore += totalScore;
              tochanSenshu.add((u: univ.id, k: kukanIndex, t: totalScore));
              if (raceNumber == 4) {
                if (temp_tochan_score < min1_tochanscore) {
                  //min2_tochanscore = min1_tochanscore;
                  min1_tochanscore = temp_tochan_score;
                  //} else if (temp_tochan_score < min2_tochanscore) {
                  //  min2_tochanscore = temp_tochan_score;
                }
              }
            }
          }
        }
        if (raceNumber == 4) {
          osshiScore -= (max1_osshiscore + max2_osshiscore);
          otaroScore -= (max1_otaroscore + max2_otaroscore);
          //tochanScore -= (min1_tochanscore + min2_tochanscore);
          tochanScore -= min1_tochanscore;
        }

        // 選手が1人以上エントリーしている場合のみ結果に追加
        // (オッシーと父ちゃんは、全大学を見てから下で決める。1.9.5)
        if (entryCount > 0) {
          //print("${entryCount}人エントリー");
          shutsujou.add((id: univ.id, name: univ.name, tochan: tochanScore));
          allPredictions['otaro']!.add(
            Prediction(univ.id, univ.name, otaroScore),
          );
        }
      }
    }

    // オッシー(エース重視。1.9.5): 区間(組)ごとに全選手の中の見込みタイムの順位(0から)を出し、
    // その平方根を大学ごとに合計する(小さい方が良い)。正月駅伝予選は、点の悪い2人を除く(これまでと同じ)
    final Map<int, List<double>> osshiTen = {}; // 大学id→選手ごとの点
    final Map<int, List<({int u, int k, double t})>> osshiKukanGoto = {};
    for (final x in osshiSenshu) {
      (osshiKukanGoto[x.k] ??= []).add(x);
    }
    for (final List<({int u, int k, double t})> l in osshiKukanGoto.values) {
      l.sort((a, b) => a.t.compareTo(b.t));
      for (int r = 0; r < l.length; r++) {
        // 同じ見込みタイムなら同じ順位
        int juni = r;
        while (juni > 0 && l[juni - 1].t == l[r].t) {
          juni--;
        }
        (osshiTen[l[r].u] ??= []).add(sqrt(juni.toDouble()));
      }
    }
    // 父ちゃん(層の厚さ重視。1.9.5): 区間(組)の最高点との差が一番大きい選手の差を、合計点から引く。
    // 正月駅伝予選は、合計から除いた一番点の低い選手を除いて見る(これまでと同じ)
    final Map<int, List<double>> tochanSa = {}; // 大学id→選手ごとの最高点との差
    for (final x in tochanSenshu) {
      final double saikou = (x.k >= 0 && x.k < kukanshou_bestscore_tochan.length)
          ? kukanshou_bestscore_tochan[x.k]
          : x.t;
      (tochanSa[x.u] ??= []).add(max(0.0, saikou - x.t));
    }
    for (final x in shutsujou) {
      final List<double> ten = List<double>.of(osshiTen[x.id] ?? const <double>[])
        ..sort((a, b) => b.compareTo(a)); // 悪い順
      final int nozoku = raceNumber == 4 ? min(2, ten.length) : 0;
      double osshi = 0.0;
      for (int i = nozoku; i < ten.length; i++) {
        osshi += ten[i];
      }
      allPredictions['osshi']!.add(Prediction(x.id, x.name, osshi));

      final List<double> sa = List<double>.of(tochanSa[x.id] ?? const <double>[])
        ..sort((a, b) => b.compareTo(a)); // 差の大きい順
      final int nozokuSa = raceNumber == 4 ? min(1, sa.length) : 0;
      final double brake = sa.length > nozokuSa ? sa[nozokuSa] : 0.0;
      allPredictions['tochan']!.add(Prediction(x.id, x.name, x.tochan - brake));
    }
    return allPredictions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      body: ValueListenableBuilder<Box<Ghensuu>>(
        valueListenable: Hive.box<Ghensuu>('ghensuuBox').listenable(),
        builder: (context, ghensuuBox, _) {
          final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');
          if (currentGhensuu == null) {
            return const Center(
              child: CircularProgressIndicator(color: HENSUU.textcolor),
            );
          }
          String racestring = "";
          if (currentGhensuu.hyojiracebangou == 0) {
            racestring = "10月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 1) {
            racestring = "11月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 2) {
            racestring = "正月駅伝";
          }
          if (currentGhensuu.hyojiracebangou == 3) {
            racestring = "11月駅伝予選";
          }
          if (currentGhensuu.hyojiracebangou == 4) {
            racestring = "正月駅伝予選";
          }

          return ValueListenableBuilder<Box<UnivData>>(
            valueListenable: Hive.box<UnivData>('univBox').listenable(),
            builder: (context, univdataBox, _) {
              //final List<UnivData> allUnivData = univdataBox.values.toList();
              List<UnivData> sortedUnivData = univdataBox.values.toList();
              sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
              if (currentGhensuu.hyojiracebangou == 5) {
                racestring = sortedUnivData[0].name_tanshuku;
              }
              return ValueListenableBuilder<Box<SenshuData>>(
                valueListenable: Hive.box<SenshuData>('senshuBox').listenable(),
                builder: (context, senshudataBox, _) {
                  //final List<SenshuData> allSenshuData = senshudataBox.values
                  //    .toList();
                  List<SenshuData> sortedSenshuData = senshudataBox.values
                      .toList();
                  sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));

                  // 予想を計算
                  final Map<String, List<Prediction>> allPredictions =
                      _calculateAllPredictions(
                        currentGhensuu.hyojiracebangou,
                        sortedUnivData,
                        sortedSenshuData,
                      );

                  // 順位付け
                  final List<Prediction> osshiRanked = _getRankedPredictions(
                    allPredictions['osshi']!,
                    true,
                  );
                  final List<Prediction> tochanRanked = _getRankedPredictions(
                    allPredictions['tochan']!,
                    false,
                  );
                  final List<Prediction> otaroRanked = _getRankedPredictions(
                    allPredictions['otaro']!,
                    true,
                  );
                  // 展望記事に使う予想陣の3人の予想(1.9.2)
                  final List<KijiYosouJin> kijiYosou = [
                    KijiYosouJin(
                      'オッシー',
                      '基本走力・エース重視',
                      [for (final p in osshiRanked) p.id],
                      List<int>.of(kukanshou_id_osshi),
                    ),
                    KijiYosouJin(
                      '父ちゃん',
                      '総合評価・層の厚さ重視',
                      [for (final p in tochanRanked) p.id],
                      List<int>.of(kukanshou_id_tochan),
                    ),
                    KijiYosouJin(
                      '王太郎',
                      '夏のタイムトライアル重視',
                      [for (final p in otaroRanked) p.id],
                      List<int>.of(kukanshou_id_otaro),
                    ),
                  ];

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentGhensuu.hyojiracebangou != 4)
                              ElevatedButton(
                                onPressed: () async {
                                  currentGhensuu.mode = 300;
                                  await currentGhensuu.save();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HENSUU.buttonColor,
                                  foregroundColor: HENSUU.buttonTextColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("戻る"),
                              ),
                            Expanded(
                              child: Text(
                                "  ${racestring}直前順位予想!!",
                                style: const TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: onAdvanceMode != null
                                  ? _advanceGameMode
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HENSUU.buttonColor,
                                foregroundColor: HENSUU.buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: HENSUU.fontsize_honbun,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("進む＞＞"),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: HENSUU.textcolor),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                // 展望記事(箱庭スポーツ。予想陣の3人の予想も記事に使う。1.9.2)
                                // 目立つように、優勝争いの記事の見出しを予告するカードにして、一番上に置いた
                                KijiLinkCard(
                                  key: ValueKey(
                                    'kijiTenbou_${currentGhensuu.year}_${currentGhensuu.hyojiracebangou}',
                                  ),
                                  namae: '展望記事(箱庭スポーツ)',
                                  tsukuru: () => kijiTenbouIchiran(kijiYosou),
                                  hiraku: (c) => kijiTenbouHiraku(c, kijiYosou),
                                  // 学内メディアの展望号も、記事の画面で切り替えて読める(1.9.3)
                                  annai: kijiGakunaiAnnai(),
                                ),
                                TextButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.8,
                                      ),
                                      barrierDismissible: true,
                                      barrierLabel: '区間エントリー選手持ちタイム大学ランキング',
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) {
                                            // ModalKukanEntryListViewはimportされていると仮定
                                            // ignore: unnecessary_cast
                                            return (const ModalAverageTimeRankingView())
                                                as Widget;
                                          },
                                      transitionBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOut,
                                              ),
                                              child: child,
                                            );
                                          },
                                    );
                                  },
                                  child: Text(
                                    "区間エントリー選手持ちタイム大学ランキング",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        0,
                                        255,
                                        0,
                                      ),
                                      decoration: TextDecoration.underline,
                                      decorationColor: HENSUU.textcolor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // 1区の集団のペースの予想(駅伝だけ。区間エントリーどおりの選手で予想し、
                                // 当日の調子はまだ入れない。1.9.2)
                                if (ikkuPaceTaishou(
                                  currentGhensuu.hyojiracebangou,
                                )) ...[
                                  IkkuPaceYosouBox(
                                    jibunSenshuId: _ikkuJibunSenshuId(
                                      currentGhensuu,
                                      sortedSenshuData,
                                    ),
                                    chousiIreru: false,
                                    kakuteiMae: true,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // オッシーの予想
                                const Text(
                                  "■ オッシーの予想 (基本走力・エース重視)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in osshiRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 父ちゃんの予想
                                const Text(
                                  "■ 父ちゃんの予想 (持ちタイム+各能力の総合評価・層の厚さ重視)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in tochanRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 王太郎の予想
                                const Text(
                                  "■ 王太郎の予想 (夏のタイムトライアル重視)",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final prediction in otaroRanked)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      prediction.name,
                                      style: const TextStyle(
                                        color: HENSUU.textcolor,
                                        fontSize: HENSUU.fontsize_honbun,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // 区間賞予想
                                if (currentGhensuu.hyojiracebangou <= 2 ||
                                    currentGhensuu.hyojiracebangou == 5)
                                  const Text(
                                    "■ 区間賞予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (currentGhensuu.hyojiracebangou == 3)
                                  const Text(
                                    "■ 各組個人1位予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (currentGhensuu.hyojiracebangou == 4)
                                  const Text(
                                    "■ 個人1位予想",
                                    style: TextStyle(
                                      color: HENSUU.textcolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                if (currentGhensuu.hyojiracebangou <= 2 ||
                                    currentGhensuu.hyojiracebangou == 5)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        "${i_kukan + 1}区\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                                if (currentGhensuu.hyojiracebangou == 3)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        "${i_kukan + 1}組\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                                if (currentGhensuu.hyojiracebangou == 4)
                                  for (
                                    int i_kukan = 0;
                                    i_kukan <
                                        currentGhensuu
                                            .kukansuu_taikaigoto[currentGhensuu
                                            .hyojiracebangou];
                                    i_kukan++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        //"${i_kukan + 1}組\n"
                                        "オ   ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].name} ${sortedSenshuData[kukanshou_id_osshi[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_osshi[i_kukan]].univid].name})\n"
                                        "父   ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].name} ${sortedSenshuData[kukanshou_id_tochan[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_tochan[i_kukan]].univid].name})\n"
                                        "王   ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].name} ${sortedSenshuData[kukanshou_id_otaro[i_kukan]].gakunen}年 (${sortedUnivData[sortedSenshuData[kukanshou_id_otaro[i_kukan]].univid].name})",
                                        style: const TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  int _NEWaintFromNewbint(int Newbint, SenshuData senshu) {
    // 変数名はSwiftコードの指示通りにしています。
    int b_int = 0;
    int a_int = 0;
    int a_min_int = 0;
    int new_a_int = 0;
    int new_a_min_int = 0;
    int sa = 0;

    // 現在のaとbを整数に変換
    a_int = (senshu.a * 1000000000.0).toInt();
    b_int = (senshu.b * 10000.0).toInt();

    // 既存のb_intに基づいたa_min_intの計算
    a_min_int = (b_int * b_int * 0.0333 - b_int * 114.25 + senshu.magicnumber)
        .toInt();

    // aの差分を計算
    sa = a_int - a_min_int;

    // 新しいNewbintに基づいたnew_a_min_intの計算
    new_a_min_int =
        (Newbint * Newbint * 0.0333 - Newbint * 114.25 + senshu.magicnumber)
            .toInt();

    // 新しいa_intを計算
    new_a_int = new_a_min_int + sa;

    return new_a_int;
  }
}
