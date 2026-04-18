import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
// import 'dart:math'; // Int.random の代わりに Math.Random を使う場合、必要になるかもしれません。

/// 大学のレース成績と風フラグに基づいて、金ボールまたは銀ボールの獲得数を計算し更新します。
///
/// [ghensuu]: 現在のゲーム状態を表すGhensuuオブジェクト。このオブジェクトが更新されます。
/// [sortedUnivData]: ID順にソートされた大学データのリスト。
Future<void> goldsilverTeikiKakutoku(
  Ghensuu ghensuu,
  List<UnivData> sortedUnivData,
) async {
  int kakutokusuu = 0; // 獲得数

  // gh[0].kazeflag の代わりに ghensuu.kazeflag を使用
  final int kazeflag = ghensuu.kazeflag;
  final int myUnivId = ghensuu.MYunivid;

  // sortedunivdata が gh[0].MYunivid にアクセスできることを保証するために範囲チェック
  if (myUnivId < 0 || myUnivId >= sortedUnivData.length) {
    print('エラー: MYunividがsortedUnivDataの範囲外です。');
    return; // または適切なエラーハンドリング
  }

  final UnivData myUniv = sortedUnivData[myUnivId];

  // Wind Flag (kazeflag) に応じた獲得数の計算
  // SwiftのInt.random(in: min...max) は DartのRandomクラスか、
  // あるいは単純な確率分岐で代替します。
  // コメントアウトされている部分は元のコードに合わせ、固定値で実装します。

  if (kazeflag == 0) {
    // kakutokusuu = (Random().nextInt(5) + 1) * 10; // 1から50までの10刻み
    // 三冠50
    if (myUniv.juni_race[0][0] == 0 &&
        myUniv.juni_race[1][0] == 0 &&
        myUniv.juni_race[2][0] == 0) {
      kakutokusuu = 50;
      // 駅伝か対校戦優勝したら45
    } else if (myUniv.juni_race[0][0] == 0 ||
        myUniv.juni_race[1][0] == 0 ||
        myUniv.juni_race[2][0] == 0 ||
        myUniv.juni_race[9][0] == 0) {
      kakutokusuu = 45;
      // 駅伝すべて3位以内→40
    } else if (myUniv.juni_race[0][0] < 3 &&
        myUniv.juni_race[1][0] < 3 &&
        myUniv.juni_race[2][0] < 3) {
      kakutokusuu = 40;
      // 駅伝か対校戦どれか３位以内35
    } else if (myUniv.juni_race[0][0] < 3 ||
        myUniv.juni_race[1][0] < 3 ||
        myUniv.juni_race[2][0] < 3 ||
        myUniv.juni_race[9][0] < 3) {
      kakutokusuu = 35;
      // 対校戦8位以内もしくは10月駅伝5位以内もしくは11月駅伝8位以内もしくは正月駅伝10位以内→30
    } else if (myUniv.juni_race[0][0] < 5 ||
        myUniv.juni_race[1][0] < 8 ||
        myUniv.juni_race[2][0] < 10 ||
        myUniv.juni_race[9][0] < 8) {
      kakutokusuu = 30;
      // 11月駅伝予選か正月駅伝予選を突破
    } else if (myUniv.juni_race[3][0] < 7 || myUniv.juni_race[4][0] < 10) {
      kakutokusuu = 20;
      // 上記以外10
    } else {
      kakutokusuu = 10;
    }
  } else if (kazeflag == 1) {
    // kakutokusuu = (Random().nextInt(6) + 5) * 10; // 5から100までの10刻み
    // 三冠100
    if (myUniv.juni_race[0][0] == 0 &&
        myUniv.juni_race[1][0] == 0 &&
        myUniv.juni_race[2][0] == 0) {
      kakutokusuu = 100;
      // 駅伝か対校戦優勝したら90
    } else if (myUniv.juni_race[0][0] == 0 ||
        myUniv.juni_race[1][0] == 0 ||
        myUniv.juni_race[2][0] == 0 ||
        myUniv.juni_race[9][0] == 0) {
      kakutokusuu = 90;
      // 駅伝すべて3位以内→85
    } else if (myUniv.juni_race[0][0] < 3 &&
        myUniv.juni_race[1][0] < 3 &&
        myUniv.juni_race[2][0] < 3) {
      kakutokusuu = 85;
      // 駅伝か対校戦どれか３位以内80
    } else if (myUniv.juni_race[0][0] < 3 ||
        myUniv.juni_race[1][0] < 3 ||
        myUniv.juni_race[2][0] < 3 ||
        myUniv.juni_race[9][0] < 3) {
      kakutokusuu = 80;
      // 対校戦8位以内もしくは10月駅伝5位以内もしくは11月駅伝8位以内もしくは正月駅伝10位以内→75
    } else if (myUniv.juni_race[0][0] < 5 ||
        myUniv.juni_race[1][0] < 8 ||
        myUniv.juni_race[2][0] < 10 ||
        myUniv.juni_race[9][0] < 8) {
      kakutokusuu = 75;
      // 11月駅伝予選か正月駅伝予選を突破
    } else if (myUniv.juni_race[3][0] < 7 || myUniv.juni_race[4][0] < 10) {
      kakutokusuu = 65;
      // 上記以外50
    } else {
      kakutokusuu = 50;
    }
  } else if (kazeflag == 2) {
    // kakutokusuu = (Random().nextInt(11) + 10) * 10; // 10から200までの10刻み
    // 三冠200
    if (myUniv.juni_race[0][0] == 0 &&
        myUniv.juni_race[1][0] == 0 &&
        myUniv.juni_race[2][0] == 0) {
      kakutokusuu = 200;
      // 駅伝か対校戦優勝したら180
    } else if (myUniv.juni_race[0][0] == 0 ||
        myUniv.juni_race[1][0] == 0 ||
        myUniv.juni_race[2][0] == 0 ||
        myUniv.juni_race[9][0] == 0) {
      kakutokusuu = 180;
      // 駅伝すべて3位以内→170
    } else if (myUniv.juni_race[0][0] < 3 &&
        myUniv.juni_race[1][0] < 3 &&
        myUniv.juni_race[2][0] < 3) {
      kakutokusuu = 170;
      // 駅伝か対校戦どれか３位以内160
    } else if (myUniv.juni_race[0][0] < 3 ||
        myUniv.juni_race[1][0] < 3 ||
        myUniv.juni_race[2][0] < 3 ||
        myUniv.juni_race[9][0] < 3) {
      kakutokusuu = 160;
      // 対校戦8位以内もしくは10月駅伝5位以内もしくは11月駅伝8位以内もしくは正月駅伝10位以内→150
    } else if (myUniv.juni_race[0][0] < 5 ||
        myUniv.juni_race[1][0] < 8 ||
        myUniv.juni_race[2][0] < 10 ||
        myUniv.juni_race[9][0] < 8) {
      kakutokusuu = 150;
      // 11月駅伝予選か正月駅伝予選を突破
    } else if (myUniv.juni_race[3][0] < 7 || myUniv.juni_race[4][0] < 10) {
      kakutokusuu = 125;
      // 上記以外100
    } else {
      kakutokusuu = 100;
    }
  } else if (kazeflag == 3) {
    // kakutokusuu = (Random().nextInt(11) + 20) * 10; // 20から300までの10刻み
    // 三冠300
    if (myUniv.juni_race[0][0] == 0 &&
        myUniv.juni_race[1][0] == 0 &&
        myUniv.juni_race[2][0] == 0) {
      kakutokusuu = 300;
      // 駅伝か対校戦優勝したら280
    } else if (myUniv.juni_race[0][0] == 0 ||
        myUniv.juni_race[1][0] == 0 ||
        myUniv.juni_race[2][0] == 0 ||
        myUniv.juni_race[9][0] == 0) {
      kakutokusuu = 280;
      // 駅伝すべて3位以内→270
    } else if (myUniv.juni_race[0][0] < 3 &&
        myUniv.juni_race[1][0] < 3 &&
        myUniv.juni_race[2][0] < 3) {
      kakutokusuu = 270;
      // 駅伝か対校戦どれか３位以内260
    } else if (myUniv.juni_race[0][0] < 3 ||
        myUniv.juni_race[1][0] < 3 ||
        myUniv.juni_race[2][0] < 3 ||
        myUniv.juni_race[9][0] < 3) {
      kakutokusuu = 260;
      // 対校戦8位以内もしくは10月駅伝5位以内もしくは11月駅伝8位以内もしくは正月駅伝10位以内→250
    } else if (myUniv.juni_race[0][0] < 5 ||
        myUniv.juni_race[1][0] < 8 ||
        myUniv.juni_race[2][0] < 10 ||
        myUniv.juni_race[9][0] < 8) {
      kakutokusuu = 250;
      // 11月駅伝予選か正月駅伝予選を突破
    } else if (myUniv.juni_race[3][0] < 7 || myUniv.juni_race[4][0] < 10) {
      kakutokusuu = 225;
      // 上記以外200
    } else {
      kakutokusuu = 200;
    }
  }

  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData? kantoku = kantokuBox.get('KantokuData');
  kakutokusuu *= kantoku!.yobiint2[12];

  // 10%の確率で金ボール、90%の確率で銀ボール
  // DartのRandom().nextInt(100) は0から99の整数を返す
  final random = Random();
  if (random.nextInt(100) < 10) {
    // 0から9が金ボール、つまり10%
    ghensuu.last_goldenballkakutokusuu = kakutokusuu;
    ghensuu.goldenballsuu += kakutokusuu;
  } else {
    ghensuu.last_silverballkakutokusuu = kakutokusuu;
    ghensuu.silverballsuu += kakutokusuu;
  }
  if (ghensuu.goldenballsuu > 9999) {
    ghensuu.goldenballsuu = 9999;
  }
  if (ghensuu.silverballsuu > 9999) {
    ghensuu.silverballsuu = 9999;
  }
  // Ghensuuオブジェクトの変更をHiveに保存
  await ghensuu.save();
}
