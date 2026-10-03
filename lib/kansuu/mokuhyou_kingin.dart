import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 目標順位を達成したときにもらえる金銀の量(1.8.3で目標順位を決める画面の外に出した。計算は今までと同じ)
// 目標順位を決める画面(mode0280_content.dart)の「目標達成時獲得金銀」と、
// 生成AIに渡すテキストの「目標順位相談セット」(ai_copy_matome.dart)で使う
// ------------------------------------------------------------

/// 目標順位を決める画面で選べる一番下の順位(1位が1)
int mokuhyouSentakuSaikai(int raceIdx) {
  switch (raceIdx) {
    case 0:
      return 9;
    case 1:
      return 14;
    case 2:
      return 19;
    case 5:
      return 29;
    default:
      return 20;
  }
}

/// 目標順位[targetrank](0が1位)を達成したときにもらえる金銀の量
int mokuhyouKakutokuKingin(
  Ghensuu ghensuu,
  KantokuData kantoku,
  int targetrank,
) {
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

  int kotae = 0;
  int r = 0;
  int racebangou = ghensuu.hyojiracebangou;
  int maxrank = _getMaxRank(racebangou);
  int seedrank = _getSeedRank(racebangou);
  if (kantoku.yobiint2[0] == 0) {
    int rYuushou = 0;
    int rSeed = 0;
    if (ghensuu.kazeflag == 0) {
      //r = 30;
      rSeed = 30;
      rYuushou = 50;
    }
    if (ghensuu.kazeflag == 1) {
      //r = 50;
      rSeed = 50;
      rYuushou = 100;
    }
    if (ghensuu.kazeflag == 2) {
      //r = 100;
      rSeed = 100;
      rYuushou = 200;
    }
    if (ghensuu.kazeflag == 3) {
      //r = 200;
      rSeed = 200;
      rYuushou = 300;
    }

    if (targetrank == 0) {
      r = rYuushou;
      //何もしない
    } else if (targetrank == maxrank) {
      r = 10;
    } else {
      int sa = 0;
      double persa = 0.0;
      int ryou_koujousin = 0;
      int plusryou = 0;
      if (targetrank <= seedrank) {
        sa = rYuushou - rSeed;
        persa = sa / (seedrank - 0);
        ryou_koujousin = seedrank - targetrank;
        plusryou = (persa * ryou_koujousin).toInt();
        r = rSeed + plusryou;
      } else {
        sa = rSeed - 10;
        persa = sa / (maxrank - seedrank);
        ryou_koujousin = maxrank - targetrank;
        plusryou = (persa * ryou_koujousin).toInt();
        r = 10 + plusryou;
      }
    }
  }
  r *= kantoku.yobiint2[12];
  if (targetrank == 0) {
    r *= 2;
  }
  kotae = r;
  return kotae;
}
