import 'dart:math'; // Randomクラスを使用するため
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/GakunenZurasi.dart';
//import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
import 'package:ekiden/kansuu/ShozokusakiKettei_By_Univmeisei.dart';
import 'package:ekiden/kansuu/SenshuShokiti.dart';

/// 年度替わりの選手引退、新入生入学、データ更新処理をまとめて実行します。
///
/// [ghensuu]: 現在のゲーム状態を表すGhensuuオブジェクト。このオブジェクトが更新されます。
/// [sortedUnivData]: ID順にソートされた大学データのリスト。大学名声が更新されます。
/// [sortedSenshuData]: ID順にソートされた全選手データのリスト。学年やその他のデータが更新されます。
/// [nyuugakuji5000_senshudata]: 入学時の5000m記録でソートされた選手データのリスト。
///                              新入生の大学配属に使用されます。

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  //final int milliseconds = ((time % 1) * 100)
  //    .toInt(); // 秒以下の部分をミリ秒として扱う (小数点2桁まで)
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

Future<void> RetireNew({
  required Ghensuu ghensuu, // gh:[Ghensuu] ではなく Ghensuu を直接受け取る
  required List<UnivData> sortedUnivData, // sortedunivdata
  required List<SenshuData> sortedSenshuData, // sortedsenshudata
  //required List<SenshuData>
  //nyuugakuji5000_senshudata, // nyuugakuji5000_senshudata
  //required Box<SenshuData> senshuBox, // SenshuBoxをRetireNewの引数に追加
}) async {
  final startTime = DateTime.now();
  print("RetireNewに入った");

  final rijiBox = Hive.box<RijiData>('rijiBox');
  final RijiData riji = rijiBox.get('RijiData')!;

  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  // Boxからデータを読み込む
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  //監督・コーチ用のストックとして引退選手アルバムに選手を追加
  final Box<Senshu_R_Data> retiredSenshuBox = Hive.box<Senshu_R_Data>(
    'retiredSenshuBox',
  );
  for (int i = 0; i < TEISUU.UNIVSUU * 3; i++) {
    kantoku.yobiint1[i] = 0;
  }
  await kantoku.save();
  final allRetiredSenshu = retiredSenshuBox.values.toList();
  for (int i = 0; i < sortedSenshuData.length; i++) {
    if (sortedSenshuData[i].gakunen == 4 && sortedSenshuData[i].hirou != 1) {
      bool okflag = true;
      int temprid = sortedSenshuData[i].id + ghensuu.year * 1000;
      // 取得した全ての選手データをループ処理します
      for (var rsenshu in allRetiredSenshu) {
        if (rsenshu.id == temprid) {
          //sijiseikouflagを上書きされたくないから
          okflag = false;
          break;
        }
      }
      if (okflag) {
        //いったん全員追加しちゃう(留学生除いて)
        // 現役選手データを卒業選手データに変換 (fromSenshuDataファクトリを使用)
        final Senshu_R_Data retiredSenshu = Senshu_R_Data.fromSenshuData(
          sortedSenshuData[i],
        );
        // sijiflag（卒業年）idを設定
        final int currentYear = ghensuu.year;
        retiredSenshu.sijiflag = currentYear;
        retiredSenshu.id += currentYear * 1000;
        retiredSenshu.string_racesetumei = "";
        // Hive Boxに保存
        await retiredSenshuBox.put(retiredSenshu.id, retiredSenshu);
      }
    }
  }
  for (int i_univid = 0; i_univid < sortedUnivData.length; i_univid++) {
    //if (i_univid != ghensuu.MYunivid) {

    //}
    List<Senshu_R_Data> univagenotryuugakuseiFilteredrSenshuData =
        retiredSenshuBox.values
            .where(
              (s) =>
                  s.univid == i_univid &&
                  (ghensuu.year - s.sijiflag + 22) >= 30 + (s.id % 10) &&
                  s.hirou != 1,
            ) // 👈 Boxの最新データからフィルタ
            .toList();

    //ここから監督・コーチ陣更新処理
    List<Senshu_R_Data> kantokunareruJunUnivFilteredrSenshuData =
        univagenotryuugakuseiFilteredrSenshuData
            .toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            // a の合計値を計算
            final int sumA =
                a.zentaijuni_bestkiroku[0] +
                a.zentaijuni_bestkiroku[1] +
                a.zentaijuni_bestkiroku[2] +
                a.zentaijuni_bestkiroku[3];
            // b の合計値を計算
            final int sumB =
                b.zentaijuni_bestkiroku[0] +
                b.zentaijuni_bestkiroku[1] +
                b.zentaijuni_bestkiroku[2] +
                b.zentaijuni_bestkiroku[3];
            // 2. 合計値を昇順で比較
            int sumCompare = sumA.compareTo(sumB);
            if (sumCompare != 0) {
              // 合計値が異なる場合は、その結果（昇順）を返す
              return sumCompare;
            }
            // 3. 合計値が同じ場合は、sijiflagを昇順で比較
            return a.id.compareTo(b.id);
          });
    //まず、定年退職(監督コーチフラグリセットしてからデータ削除)、自分でアルバムに追加した選手は除く(sijiseikouflag==100)
    int lastrid0 = kantoku.rid[i_univid];
    int lastrid1 = kantoku.rid[i_univid + TEISUU.UNIVSUU];
    int lastrid2 = kantoku.rid[i_univid + TEISUU.UNIVSUU * 2];
    //if (i_univid != ghensuu.MYunivid) {
    for (
      int i = kantokunareruJunUnivFilteredrSenshuData.length - 1;
      i >= 0;
      i--
    ) {
      print("i=${i}");
      final currentSenshu = kantokunareruJunUnivFilteredrSenshuData[i];
      int age = ghensuu.year - currentSenshu.sijiflag + 22;
      if ((age > 65 + (currentSenshu.id % 10))) {
        bool ninmeiflag = false;
        for (int i_kantoku = 0; i_kantoku < TEISUU.UNIVSUU * 3; i_kantoku++) {
          //プレイヤーが任命してなければ
          if (kantoku.rid[i_kantoku] == currentSenshu.id) {
            if (kantoku.yobiint0[i_kantoku] == 0) {
              kantoku.rid[i_kantoku] = 0;
              await kantoku.save();
              if (i_kantoku < TEISUU.UNIVSUU) {
                currentSenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - currentSenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学監督を加齢を理由に退任\n";
              } else if (i_kantoku < TEISUU.UNIVSUU * 2) {
                currentSenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - currentSenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(トラック)を加齢を理由に退任\n";
              } else {
                currentSenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - currentSenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(長距離)を加齢を理由に退任\n";
              }

              await currentSenshu.save();
            } else {
              ninmeiflag = true;
            }
          }
        }
        if (ninmeiflag == false && currentSenshu.sijiseikouflag != 100) {
          bool iruflag = false;
          for (int i_riji = 0; i_riji < 10; i_riji++) {
            if (riji.rid_riji[i_riji] == currentSenshu.id) {
              iruflag = true;
              break;
            }
          }

          if (iruflag == false) {
            print(
              "削除前kantokunareruJunUnivFilteredrSenshuData.length=${kantokunareruJunUnivFilteredrSenshuData.length}",
            );
            await retiredSenshuBox.delete(currentSenshu.id);
            print(
              "削除後kantokunareruJunUnivFilteredrSenshuData.length=${kantokunareruJunUnivFilteredrSenshuData.length}",
            );
            // 💡 注意: List自体を操作している場合
            kantokunareruJunUnivFilteredrSenshuData.removeAt(i);
            // もしこのリストが削除操作で変わる必要があれば、この行も追加
          }
        }
      }
    }
    //}
    //削除処理の後なので、念のためもう一度取得
    univagenotryuugakuseiFilteredrSenshuData = retiredSenshuBox.values
        .where(
          (s) =>
              s.univid == i_univid &&
              (ghensuu.year - s.sijiflag + 22) >= 35 + (s.id % 10) &&
              (ghensuu.year - s.sijiflag + 22) <= 65 + (s.id % 10) &&
              s.hirou != 1,
        ) // 👈 Boxの最新データからフィルタ
        .toList();
    kantokunareruJunUnivFilteredrSenshuData =
        univagenotryuugakuseiFilteredrSenshuData
            .toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            // a の合計値を計算
            final int sumA =
                a.zentaijuni_bestkiroku[0] +
                a.zentaijuni_bestkiroku[1] +
                a.zentaijuni_bestkiroku[2] +
                a.zentaijuni_bestkiroku[3];
            // b の合計値を計算
            final int sumB =
                b.zentaijuni_bestkiroku[0] +
                b.zentaijuni_bestkiroku[1] +
                b.zentaijuni_bestkiroku[2] +
                b.zentaijuni_bestkiroku[3];
            // 2. 合計値を昇順で比較
            int sumCompare = sumA.compareTo(sumB);
            if (sumCompare != 0) {
              // 合計値が異なる場合は、その結果（昇順）を返す
              return sumCompare;
            }
            // 3. 合計値が同じ場合は、sijiflagを昇順で比較
            return a.id.compareTo(b.id);
          });
    //監督・コーチ陣更新
    //まずはいったん全員退任処理
    if (kantoku.yobiint0[i_univid] == 0) {
      //プレイヤーが任命していなければ
      kantoku.rid[i_univid] = 0;
    }
    if (kantoku.yobiint0[i_univid + TEISUU.UNIVSUU] == 0) {
      kantoku.rid[i_univid + TEISUU.UNIVSUU] = 0;
    }
    if (kantoku.yobiint0[i_univid + TEISUU.UNIVSUU * 2] == 0) {
      kantoku.rid[i_univid + TEISUU.UNIVSUU * 2] = 0;
    }
    await kantoku.save();

    //監督就任
    //int nowsuu = 0;
    if (kantokunareruJunUnivFilteredrSenshuData.length > 0) {
      for (
        int iii = 0;
        iii < kantokunareruJunUnivFilteredrSenshuData.length;
        iii++
      ) {
        if (kantoku.rid[i_univid + TEISUU.UNIVSUU] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid + TEISUU.UNIVSUU * 2] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid] == 0) {
          kantoku.rid[i_univid] =
              kantokunareruJunUnivFilteredrSenshuData[iii].id;
          await kantoku.save();
          if (lastrid0 != kantoku.rid[i_univid]) {
            kantoku.yobiint1[i_univid] = 1; //異動あったフラグ
            await kantoku.save();
            //退任記録
            for (var rsenshu in kantokunareruJunUnivFilteredrSenshuData) {
              if (rsenshu.id == lastrid0) {
                rsenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - rsenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学監督を退任\n";
                await rsenshu.save();
                break;
              }
            }
            //就任記録
            kantokunareruJunUnivFilteredrSenshuData[iii].string_racesetumei +=
                "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - kantokunareruJunUnivFilteredrSenshuData[iii].sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学監督に就任\n";
            await kantokunareruJunUnivFilteredrSenshuData[iii].save();
          }
          break;
        }
      }
    }

    //トラックコーチ就任
    univagenotryuugakuseiFilteredrSenshuData = retiredSenshuBox.values
        .where(
          (s) =>
              s.univid == i_univid &&
              (ghensuu.year - s.sijiflag + 22) >= 30 + (s.id % 10) &&
              (ghensuu.year - s.sijiflag + 22) <= 65 + (s.id % 10) &&
              s.hirou != 1,
        ) // 👈 Boxの最新データからフィルタ
        .toList();
    kantokunareruJunUnivFilteredrSenshuData =
        univagenotryuugakuseiFilteredrSenshuData
            .toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            // a の合計値を計算
            final double sumA = a.time_bestkiroku[0] * 2 + a.time_bestkiroku[1];
            // b の合計値を計算
            final double sumB = b.time_bestkiroku[0] * 2 + b.time_bestkiroku[1];
            // 2. 合計値を昇順で比較
            int sumCompare = sumA.compareTo(sumB);
            if (sumCompare != 0) {
              // 合計値が異なる場合は、その結果（昇順）を返す
              return sumCompare;
            }
            // 3. 合計値が同じ場合は、sijiflagを昇順で比較
            return a.id.compareTo(b.id);
          });
    if (kantokunareruJunUnivFilteredrSenshuData.length > 0) {
      for (
        int iii = 0;
        iii < kantokunareruJunUnivFilteredrSenshuData.length;
        iii++
      ) {
        if (kantoku.rid[i_univid] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid + TEISUU.UNIVSUU * 2] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid + TEISUU.UNIVSUU] == 0) {
          kantoku.rid[i_univid + TEISUU.UNIVSUU] =
              kantokunareruJunUnivFilteredrSenshuData[iii].id;
          await kantoku.save();
          if (lastrid1 != kantoku.rid[i_univid + TEISUU.UNIVSUU]) {
            kantoku.yobiint1[i_univid + TEISUU.UNIVSUU] = 1; //異動あったフラグ
            await kantoku.save();
            //退任記録
            for (var rsenshu in kantokunareruJunUnivFilteredrSenshuData) {
              if (rsenshu.id == lastrid1) {
                rsenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - rsenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(トラック)を退任\n";
                await rsenshu.save();
                break;
              }
            }
            //就任記録
            kantokunareruJunUnivFilteredrSenshuData[iii].string_racesetumei +=
                "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - kantokunareruJunUnivFilteredrSenshuData[iii].sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(トラック)に就任\n";
            await kantokunareruJunUnivFilteredrSenshuData[iii].save();
          }
          break;
        }
      }
    }

    //長距離コーチ就任
    univagenotryuugakuseiFilteredrSenshuData = retiredSenshuBox.values
        .where(
          (s) =>
              s.univid == i_univid &&
              (ghensuu.year - s.sijiflag + 22) >= 30 + (s.id % 10) &&
              (ghensuu.year - s.sijiflag + 22) <= 65 + (s.id % 10) &&
              s.hirou != 1,
        ) // 👈 Boxの最新データからフィルタ
        .toList();
    kantokunareruJunUnivFilteredrSenshuData =
        univagenotryuugakuseiFilteredrSenshuData
            .toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            // a の合計値を計算
            final double sumA = a.time_bestkiroku[2] * 2 + a.time_bestkiroku[3];
            // b の合計値を計算
            final double sumB = b.time_bestkiroku[2] * 2 + b.time_bestkiroku[3];
            // 2. 合計値を昇順で比較
            int sumCompare = sumA.compareTo(sumB);
            if (sumCompare != 0) {
              // 合計値が異なる場合は、その結果（昇順）を返す
              return sumCompare;
            }
            // 3. 合計値が同じ場合は、sijiflagを昇順で比較
            return a.id.compareTo(b.id);
          });
    if (kantokunareruJunUnivFilteredrSenshuData.length > 0) {
      for (
        int iii = 0;
        iii < kantokunareruJunUnivFilteredrSenshuData.length;
        iii++
      ) {
        if (kantoku.rid[i_univid] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid + TEISUU.UNIVSUU] !=
                kantokunareruJunUnivFilteredrSenshuData[iii].id &&
            kantoku.rid[i_univid + TEISUU.UNIVSUU * 2] == 0) {
          kantoku.rid[i_univid + TEISUU.UNIVSUU * 2] =
              kantokunareruJunUnivFilteredrSenshuData[iii].id;
          await kantoku.save();
          if (lastrid2 != kantoku.rid[i_univid + TEISUU.UNIVSUU * 2]) {
            kantoku.yobiint1[i_univid + TEISUU.UNIVSUU * 2] = 1; //異動あったフラグ
            await kantoku.save();
            //退任記録
            for (var rsenshu in kantokunareruJunUnivFilteredrSenshuData) {
              if (rsenshu.id == lastrid2) {
                rsenshu.string_racesetumei +=
                    "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - rsenshu.sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(長距離)を退任\n";
                await rsenshu.save();
                break;
              }
            }
            //就任記録
            kantokunareruJunUnivFilteredrSenshuData[iii].string_racesetumei +=
                "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - kantokunareruJunUnivFilteredrSenshuData[iii].sijiflag + 22}歳) ${sortedUnivData[i_univid].name}大学コーチ(長距離)に就任\n";
            await kantokunareruJunUnivFilteredrSenshuData[iii].save();
          }
          break;
        }
      }
    }

    //ここから、もしデータが10人を超えていて、自分で追加した選手(sijiseikouflag==100)でなくて、監督・コーチになっていなくて順位の合計が大きい引退選手は削除処理
    //if (i_univid != ghensuu.MYunivid) {
    final Box<Senshu_R_Data> retiredSenshuBox2 = Hive.box<Senshu_R_Data>(
      'retiredSenshuBox',
    );
    final List<Senshu_R_Data> univFilteredrSenshuData2 = retiredSenshuBox2
        .values
        .where(
          (s) =>
              s.univid == i_univid &&
              //(ghensuu.year - s.sijiflag + 22) >= 30 &&
              s.sijiseikouflag != 100,
        ) // 👈 Boxの最新データからフィルタ
        .toList();
    final List<Senshu_R_Data> juniyoiJunUnivFilteredrSenshuData =
        univFilteredrSenshuData2
            .toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            final int sumA =
                a.zentaijuni_bestkiroku[0] +
                a.zentaijuni_bestkiroku[1] +
                a.zentaijuni_bestkiroku[2] +
                a.zentaijuni_bestkiroku[3];
            final int sumB =
                b.zentaijuni_bestkiroku[0] +
                b.zentaijuni_bestkiroku[1] +
                b.zentaijuni_bestkiroku[2] +
                b.zentaijuni_bestkiroku[3];

            // 2. 合計値を昇順で比較 (成績の良い順)
            int sumCompare = sumA.compareTo(
              sumB,
            ); // 👈 sumA.compareTo(sumB) に変更
            if (sumCompare != 0) {
              return sumCompare; // 合計値が異なる場合はその結果（昇順）を返す
            }

            // 3. 合計値が同じ場合は、sijiflagを降順で比較
            return b.id.compareTo(a.id);
          });

    if (juniyoiJunUnivFilteredrSenshuData.length > 10) {
      // 残す人数は 10人+理事の数
      int count_riji = 0;
      for (var rsenshu in juniyoiJunUnivFilteredrSenshuData) {
        for (int i_riji = 0; i_riji < 10; i_riji++) {
          if (rsenshu.id == riji.rid_riji[i_riji]) {
            count_riji++;
            break;
          }
        }
      }
      int kizokusubekisuu = 10 + count_riji;
      // 削除すべき人数
      int sakujosubekisuu =
          juniyoiJunUnivFilteredrSenshuData.length - kizokusubekisuu;

      // 削除に成功した数をカウント
      int sakujoCount = 0;
      int sakujosinakattaCount = 0;
      // 現在チェックしているインデックス（リストの末尾からスタート）
      int i_sakujo = juniyoiJunUnivFilteredrSenshuData.length - 1;
      print("ループ前i_sakujo ${i_sakujo}");
      print("ループ前kizokusubekisuu ${kizokusubekisuu}");
      int testcount = 0;
      // 削除すべき人数を達成するまで、またはリストの先頭 (インデックス 10) に達するまで繰り返す
      // i_sakujo >= kizokusubekisuu (10) は、残すべき10人(0-9)の手前まで処理することを示す
      while (sakujoCount < sakujosubekisuu &&
          i_sakujo >= kizokusubekisuu - sakujosinakattaCount &&
          i_sakujo >= 0) {
        testcount++;
        print("testcount=${testcount}  i_sakujo= ${i_sakujo}");
        print(
          "juniyoiJunUnivFilteredrSenshuData.length=${juniyoiJunUnivFilteredrSenshuData.length}",
        );
        final currentSenshu = juniyoiJunUnivFilteredrSenshuData[i_sakujo];
        bool dameflag = false; // false = 削除OK（監督でない）

        // 監督・コーチフラグのチェック
        for (int i_kantoku = 0; i_kantoku < TEISUU.UNIVSUU * 3; i_kantoku++) {
          if (kantoku.rid[i_kantoku] == currentSenshu.id) {
            dameflag = true; // 監督なので削除NG
            break;
          }
        }
        //理事に就任してないかチェック
        for (int i_riji = 0; i_riji < 10; i_riji++) {
          if (riji.rid_riji[i_riji] == currentSenshu.id) {
            dameflag = true;
            break;
          }
        }
        if (dameflag == false) {
          // ✅ 監督でない (削除OK) 場合：削除を実行し、カウントを進める
          print("削除する処理内");
          await retiredSenshuBox.delete(currentSenshu.id);
          juniyoiJunUnivFilteredrSenshuData.removeAt(i_sakujo); // リストからも削除

          i_sakujo--;
          sakujoCount++; // 削除成功数をカウント
          // リストから削除したので、i_sakujo は次の候補をチェックするために据え置く (自動的に次の要素がi_sakujoの位置に来る)
        } else {
          // ❌ 監督である (削除NG) 場合：この選手は残す
          print("削除しない処理内");
          // 削除しなかったので、次の候補（さらに成績の悪い選手）を見るためにインデックスを減らす
          i_sakujo--;
          sakujosinakattaCount++;
          //sakujosubekisuu--;
        }
      }

      // ループ終了後、リストの長さは最大10人になっています。
      // (削除できなかった監督がいた場合、sakujoCount < sakujosubekisuu でループを抜け、
      // 最終的なリストの長さは 10人 + (残した監督の数) になります。
      // 完全に10人にしたい場合は、次の補足を参照してください)
    }
    //}
  }

  //ここから理事就任退任処理(4年に一度)
  if (ghensuu.year % 4 == 0) {
    final Box<Senshu_R_Data> retiredSenshuBox3 = Hive.box<Senshu_R_Data>(
      'retiredSenshuBox',
    );
    final List<Senshu_R_Data> FilteredrSenshuData = retiredSenshuBox3.values
        .where(
          (s) =>
              //s.univid == i_univid &&
              (ghensuu.year - s.sijiflag + 22) >= 40 &&
              (ghensuu.year - s.sijiflag + 22) <= 75 &&
              s.hirou != 1,
          //s.sijiseikouflag != 100,
        ) // 👈 Boxの最新データからフィルタ
        .toList();
    final List<Senshu_R_Data> juniyoiJunFilteredrSenshuData =
        FilteredrSenshuData.toList() // 新しいリストを作成してソート
          ..sort((a, b) {
            // 1. 比較用の合計値を計算
            final int sumA =
                a.zentaijuni_bestkiroku[0] +
                a.zentaijuni_bestkiroku[1] +
                a.zentaijuni_bestkiroku[2] +
                a.zentaijuni_bestkiroku[3];
            final int sumB =
                b.zentaijuni_bestkiroku[0] +
                b.zentaijuni_bestkiroku[1] +
                b.zentaijuni_bestkiroku[2] +
                b.zentaijuni_bestkiroku[3];
            // 2. 合計値を昇順で比較 (成績の良い順)
            int sumCompare = sumA.compareTo(
              sumB,
            ); // 👈 sumA.compareTo(sumB) に変更
            if (sumCompare != 0) {
              return sumCompare; // 合計値が異なる場合はその結果（昇順）を返す
            }
            // 3. タイム順で比較
            final double sumA2 =
                a.time_bestkiroku[0] * 8.0 +
                a.time_bestkiroku[1] * 4.0 +
                a.time_bestkiroku[2] * 2.0 +
                a.time_bestkiroku[3];
            final double sumB2 =
                b.time_bestkiroku[0] * 8.0 +
                b.time_bestkiroku[1] * 4.0 +
                b.time_bestkiroku[2] * 2.0 +
                b.time_bestkiroku[3];
            // 2. 合計値を昇順で比較 (成績の良い順)
            int sumCompare2 = sumA2.compareTo(sumB2);
            if (sumCompare2 != 0) {
              return sumCompare2; // 合計値が異なる場合はその結果（昇順）を返す
            }
            // 4. 合計値が同じ場合は、sijiflagを降順で比較
            return b.id.compareTo(a.id);
          });
    List<int> lastrid_riji = List.filled(10, 0);
    for (int i = 0; i < 10; i++) {
      lastrid_riji[i] = riji.rid_riji[i];
    }
    //いったん全て退任
    for (int i = 0; i < 10; i++) {
      riji.rid_riji[i] = 0;
    }
    //就任
    for (int i = 0; i < 10; i++) {
      if (i >= juniyoiJunFilteredrSenshuData.length) {
        break;
      }
      riji.rid_riji[i] = juniyoiJunFilteredrSenshuData[i].id;
    }
    await riji.save();
    //履歴に記録
    final List<Senshu_R_Data> allretiredSenshuData = retiredSenshuBox3.values
        .toList();
    for (int i = 0; i < 10; i++) {
      if (lastrid_riji[i] != riji.rid_riji[i]) {
        //退任記録
        for (var rsenshu in allretiredSenshuData) {
          if (rsenshu.id == lastrid_riji[i]) {
            rsenshu.string_racesetumei +=
                "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - rsenshu.sijiflag + 22}歳) 【陸連】${riji.meishou[i]}を退任\n";
            await rsenshu.save();
            break;
          }
        }
        //就任記録
        for (var rsenshu in allretiredSenshuData) {
          if (rsenshu.id == riji.rid_riji[i]) {
            rsenshu.string_racesetumei +=
                "${ghensuu.year}年${ghensuu.month}月(${ghensuu.year - rsenshu.sijiflag + 22}歳) 【陸連】${riji.meishou[i]}に就任\n";
            await rsenshu.save();
            break;
          }
        }
      }
    }
  }

  /////わざと一旦閉じる
  //var close_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
  //close_rsenshubox.close();
  // --- 学年をずらす ---
  // GakunenZurasi関数は内部でHive保存を行うため、ここでは個別のsaveは不要
  await GakunenZurasi(
    sortedsenshudata: sortedSenshuData,
    gakunenfrom: 4,
    gakunento: 0,
  ); // 4年生は0年生（引退）に
  await GakunenZurasi(
    sortedsenshudata: sortedSenshuData,
    gakunenfrom: 3,
    gakunento: 4,
  );
  await GakunenZurasi(
    sortedsenshudata: sortedSenshuData,
    gakunenfrom: 2,
    gakunento: 3,
  );
  await GakunenZurasi(
    sortedsenshudata: sortedSenshuData,
    gakunenfrom: 1,
    gakunento: 2,
  );
  await GakunenZurasi(
    sortedsenshudata: sortedSenshuData,
    gakunenfrom: 0,
    gakunento: 1,
  ); // 0年生（引退した4年生）は1年生に再初期化されるはず

  // --- 大学1年生初期化 ---
  // SenshuShokitiSetteiByGakunen の元の定義に合わせて呼び出しを修正
  const int gakunenForNewStudents = 1;
  await SenshuShokitiSetteiByGakunen(
    //senshuBox, // Box<SenshuData> を1つ目の引数として渡す
    gakunenForNewStudents, // 名前付き引数として渡す
  );

  //ここでnyuugakuji5000_senshudataを5000m記録でソート

  // 3. 入学時5000m順でソートしたリストを作成
  List<SenshuData> nyuugakuji5000SenshuData = sortedSenshuData.toList()
    ..sort(
      (a, b) => a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000),
    );

  // --- 大学1年生の所属先決定 ---
  // nyuugakuji5000_senshudata は、この時点で既に新しい1年生（旧0年生）が含まれ、
  // かつ5000m記録でソートされている必要があります。
  // このリストは RetireNew に外部から渡されるか、ここで再構築されるべきです。
  // Swift版のコメントから「nyuugakuji5000_senshudata」が既にその役割を果たすものと仮定します。
  await ShozokusakiKettei_By_Univmeisei(
    sortedunivdata: sortedUnivData,
    nyuugakuji5000_senshudata: nyuugakuji5000SenshuData,
    gakunen: gakunenForNewStudents,
    ghensuu: ghensuu,
  );

  // --- 個人ベスト記録の全体順位・学内順位更新 ---
  // TEISUU.SUU_KOJINBESTKIROKUSHURUISUU は定数として定義されていると仮定
  /*for (
    int kirokubangou = 0;
    kirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
    kirokubangou++
  ) {
    kojinBestKirokuJuniKettei(
      kirokubangou,
      [ghensuu], // ghensuu オブジェクトをリストに格納して渡す
      sortedSenshuData,
    );
    // kojinBestKirokuJuniKettei内で SenshuData が更新される場合は、
    // その中で .save() が呼ばれるべきか、このループの後にまとめて保存するロジックが必要です。
    // 今回の kojinBestKirokuJuniKettei の仮定義では `void` で保存処理を含まないので注意。
    // 実際に選手データが更新されるなら、その中で save() を呼び出すのがベストです。
  }
  // kojinBestKirokuJuniKettei 処理後に、変更された SenshuData をまとめてHiveに保存
  // sortedSenshuData の各要素は HiveObject であるため、個別に save() を呼び出す必要があります
  for (final senshu in sortedSenshuData) {
    await senshu.save();
  }*/

  // --- 名声を更新 ---
  for (int i = 0; i < sortedUnivData.length; i++) {
    // 過去の名声データをずらす
    // Swiftの stride(from:to:by:) は Dartの通常のforループで実装
    for (int ii = TEISUU.MEISEIHOZONNENSUU - 1; ii > 0; ii--) {
      sortedUnivData[i].meisei_yeargoto[ii] =
          sortedUnivData[i].meisei_yeargoto[ii - 1];
    }
    sortedUnivData[i].meisei_yeargoto[0] = 1; // 最新の年度の名声は1に初期化？（要確認）
    sortedUnivData[i].meisei_total = 0; // 合計名声をリセット

    // 新しい合計名声を計算
    for (int ii = 0; ii < TEISUU.MEISEIHOZONNENSUU; ii++) {
      sortedUnivData[i].meisei_total += sortedUnivData[i].meisei_yeargoto[ii];
    }
    // UnivDataオブジェクトの変更をHiveに保存
    await sortedUnivData[i].save();
  }

  // --- 名声順位更新 ---
  // sortedByは新しいリストを返すため、元のリストを直接変更する前にコピーを作成
  // Dartではリストが参照渡しなので、新しいリストを作成して順位を更新し、
  // それを元のリストに反映させるか、直接元のリストの要素の順位プロパティを更新する必要があります。
  // ここでは、ソートしたリストを元に meiseijuni を更新し、その変更を元のオブジェクトに反映させます。
  List<UnivData> meiseijununivdata = List.from(sortedUnivData); // コピーを作成
  meiseijununivdata.sort((a, b) {
    // meisei_totalが高い順、同じならidが高い順（Swiftの$0.id > $1.idに対応）
    final int result = (b.meisei_total * 100 + b.id).compareTo(
      a.meisei_total * 100 + a.id,
    );
    return result;
  });

  for (int i = 0; i < meiseijununivdata.length; i++) {
    // ソートされたリストの要素のmeiseijuniを更新
    meiseijununivdata[i].meiseijuni = i;
    // そして、その変更を元の sortedUnivData 内の対応するオブジェクトにも適用するために保存
    // sortedUnivData の要素は Hive オブジェクトなので、直接 save() を呼び出せるはず
    await meiseijununivdata[i].save();
  }

  //もう一回開ける
  //var open_rsenshubox2 = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("RetireNew処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}
