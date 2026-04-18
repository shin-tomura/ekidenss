import 'package:ekiden/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';

Future<void> GhensuuShokika(Box<Ghensuu> ghensuuBox) async {
  //ここでKirokuも初期化しちゃう
  // 1. Boxにアクセス
  final kirokubox = await Hive.openBox<Kiroku>('kirokuBox');
  // 2. 新しいインスタンスを作成（初期値を持つ）
  final initialKiroku = Kiroku();
  // 3. 既存のデータを新しい初期データで上書き
  await kirokubox.put('KirokuData', initialKiroku);
  // Boxを閉じる（任意）
  //await kirokubox.close();

  final Ghensuu ghensuu = ghensuuBox.get(
    'global_ghensuu',
    defaultValue: Ghensuu.initial(),
  )!;
  //10月駅伝
  ghensuu.kukansuu_taikaigoto[0] = 6;
  ghensuu.kyori_taikai_kukangoto[0][0] = 8000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][0] = 0.1;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][0] = -0.1;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][0] = 0.05;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][0] = 0.08;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][0] = 4;
  ghensuu.kyori_taikai_kukangoto[0][1] = 5800;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][1] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][1] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][1] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][1] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][1] = 0;
  ghensuu.kyori_taikai_kukangoto[0][2] = 8500;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][2] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][2] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][2] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][2] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][2] = 0;
  ghensuu.kyori_taikai_kukangoto[0][3] = 6200;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][3] = 0.005;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][3] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][3] = 0.5;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][3] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][3] = 0;
  ghensuu.kyori_taikai_kukangoto[0][4] = 6400;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][4] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][4] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][4] = 0.4;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][4] = 0.4;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][4] = 50;
  ghensuu.kyori_taikai_kukangoto[0][5] = 10200;
  ghensuu.heikinkoubainobori_taikai_kukangoto[0][5] = 0.1;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[0][5] = -0.1;
  ghensuu.kyoriwariainobori_taikai_kukangoto[0][5] = 0.05;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[0][5] = 0.05;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[0][5] = 4;

  //11月駅伝
  ghensuu.kukansuu_taikaigoto[1] = 8;
  ghensuu.kyori_taikai_kukangoto[1][0] = 9500;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][0] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][0] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][0] = 0.07;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][0] = 0.1;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][0] = 30;
  ghensuu.kyori_taikai_kukangoto[1][1] = 11100;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][1] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][1] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][1] = 0.02;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][1] = 0.02;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][1] = 4;
  ghensuu.kyori_taikai_kukangoto[1][2] = 11900;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][2] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][2] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][2] = 0.02;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][2] = 0.02;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][2] = 40;
  ghensuu.kyori_taikai_kukangoto[1][3] = 11800;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][3] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][3] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][3] = 0.03;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][3] = 0.02;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][3] = 10;
  ghensuu.kyori_taikai_kukangoto[1][4] = 12400;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][4] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][4] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][4] = 0.01;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][4] = 0.03;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][4] = 7;
  ghensuu.kyori_taikai_kukangoto[1][5] = 12800;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][5] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][5] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][5] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][5] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][5] = 2;
  ghensuu.kyori_taikai_kukangoto[1][6] = 17600;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][6] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][6] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][6] = 0.02;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][6] = 0.01;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][6] = 8;
  ghensuu.kyori_taikai_kukangoto[1][7] = 19700;
  ghensuu.heikinkoubainobori_taikai_kukangoto[1][7] = 0.02;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[1][7] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[1][7] = 0.01;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[1][7] = 0.015;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[1][7] = 8;

  //正月駅伝
  ghensuu.kukansuu_taikaigoto[2] = 10;
  ghensuu.kyori_taikai_kukangoto[2][0] = 21300;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][0] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][0] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][0] = 0.01;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][0] = 0.01;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][0] = 4;
  ghensuu.kyori_taikai_kukangoto[2][1] = 23100;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][1] = 0.02;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][1] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][1] = 0.2;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][1] = 0.05;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][1] = 10;
  ghensuu.kyori_taikai_kukangoto[2][2] = 21400;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][2] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][2] = -0.0375;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][2] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][2] = 0.04;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][2] = 4;
  ghensuu.kyori_taikai_kukangoto[2][3] = 20900;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][3] = 0.02;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][3] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][3] = 0.1;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][3] = 0.01;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][3] = 100;
  ghensuu.kyori_taikai_kukangoto[2][4] = 20800;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][4] = 0.06;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][4] = -0.06;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][4] = 0.8;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][4] = 0.1;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][4] = 4;
  ghensuu.kyori_taikai_kukangoto[2][5] = 20800;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][5] = 0.06;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][5] = -0.06;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][5] = 0.1;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][5] = 0.8;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][5] = 4;
  ghensuu.kyori_taikai_kukangoto[2][6] = 21300;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][6] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][6] = -0.02;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][6] = 0.01;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][6] = 0.1;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][6] = 100;
  ghensuu.kyori_taikai_kukangoto[2][7] = 21400;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][7] = 0.0375;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][7] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][7] = 0.04;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][7] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][7] = 4;
  ghensuu.kyori_taikai_kukangoto[2][8] = 23100;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][8] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][8] = -0.02;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][8] = 0.05;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][8] = 0.2;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][8] = 10;
  ghensuu.kyori_taikai_kukangoto[2][9] = 23000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[2][9] = 0.01;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[2][9] = -0.01;
  ghensuu.kyoriwariainobori_taikai_kukangoto[2][9] = 0.01;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[2][9] = 0.01;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[2][9] = 4;

  //11月駅伝予選
  ghensuu.kukansuu_taikaigoto[3] = 4;
  ghensuu.kyori_taikai_kukangoto[3][0] = 10000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[3][0] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[3][0] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[3][0] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[3][0] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[3][0] = 0;
  ghensuu.kyori_taikai_kukangoto[3][1] = 10000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[3][1] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[3][1] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[3][1] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[3][1] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[3][1] = 0;
  ghensuu.kyori_taikai_kukangoto[3][2] = 10000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[3][2] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[3][2] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[3][2] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[3][2] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[3][2] = 0;
  ghensuu.kyori_taikai_kukangoto[3][3] = 10000;
  ghensuu.heikinkoubainobori_taikai_kukangoto[3][3] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[3][3] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[3][3] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[3][3] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[3][3] = 0;

  //正月駅伝予選
  ghensuu.kukansuu_taikaigoto[4] = 1;
  ghensuu.kyori_taikai_kukangoto[4][0] = 42195.0 / 2.0;
  ghensuu.heikinkoubainobori_taikai_kukangoto[4][0] = 0.0;
  ghensuu.heikinkoubaikudari_taikai_kukangoto[4][0] = 0.0;
  ghensuu.kyoriwariainobori_taikai_kukangoto[4][0] = 0.0;
  ghensuu.kyoriwariaikudari_taikai_kukangoto[4][0] = 0.0;
  ghensuu.noborikudarikirikaekaisuu_taikai_kukangoto[4][0] = 0;

  ghensuu.seichouryoku_type_sentakuritu[0] = 1;
  ghensuu.seichouryoku_type_gakunen[0][0] = 100;
  ghensuu.seichouryoku_type_gakunen[0][1] = 100;
  ghensuu.seichouryoku_type_gakunen[0][2] = 100;
  ghensuu.seichouryoku_type_gakunen[0][3] = 100;
  ghensuu.seichouryoku_type_sentakuritu[1] = 75;
  ghensuu.seichouryoku_type_gakunen[1][0] = 310;
  ghensuu.seichouryoku_type_gakunen[1][1] = 30;
  ghensuu.seichouryoku_type_gakunen[1][2] = 30;
  ghensuu.seichouryoku_type_gakunen[1][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[2] = 7;
  ghensuu.seichouryoku_type_gakunen[2][0] = 30;
  ghensuu.seichouryoku_type_gakunen[2][1] = 310;
  ghensuu.seichouryoku_type_gakunen[2][2] = 30;
  ghensuu.seichouryoku_type_gakunen[2][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[3] = 1;
  ghensuu.seichouryoku_type_gakunen[3][0] = 30;
  ghensuu.seichouryoku_type_gakunen[3][1] = 30;
  ghensuu.seichouryoku_type_gakunen[3][2] = 310;
  ghensuu.seichouryoku_type_gakunen[3][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[4] = 1;
  ghensuu.seichouryoku_type_gakunen[4][0] = 30;
  ghensuu.seichouryoku_type_gakunen[4][1] = 30;
  ghensuu.seichouryoku_type_gakunen[4][2] = 30;
  ghensuu.seichouryoku_type_gakunen[4][3] = 310;
  ghensuu.seichouryoku_type_sentakuritu[5] = 10;
  ghensuu.seichouryoku_type_gakunen[5][0] = 170;
  ghensuu.seichouryoku_type_gakunen[5][1] = 170;
  ghensuu.seichouryoku_type_gakunen[5][2] = 30;
  ghensuu.seichouryoku_type_gakunen[5][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[6] = 1;
  ghensuu.seichouryoku_type_gakunen[6][0] = 30;
  ghensuu.seichouryoku_type_gakunen[6][1] = 170;
  ghensuu.seichouryoku_type_gakunen[6][2] = 170;
  ghensuu.seichouryoku_type_gakunen[6][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[7] = 1;
  ghensuu.seichouryoku_type_gakunen[7][0] = 30;
  ghensuu.seichouryoku_type_gakunen[7][1] = 30;
  ghensuu.seichouryoku_type_gakunen[7][2] = 170;
  ghensuu.seichouryoku_type_gakunen[7][3] = 170;
  ghensuu.seichouryoku_type_sentakuritu[8] = 1;
  ghensuu.seichouryoku_type_gakunen[8][0] = 170;
  ghensuu.seichouryoku_type_gakunen[8][1] = 30;
  ghensuu.seichouryoku_type_gakunen[8][2] = 170;
  ghensuu.seichouryoku_type_gakunen[8][3] = 30;
  ghensuu.seichouryoku_type_sentakuritu[9] = 1;
  ghensuu.seichouryoku_type_gakunen[9][0] = 170;
  ghensuu.seichouryoku_type_gakunen[9][1] = 30;
  ghensuu.seichouryoku_type_gakunen[9][2] = 30;
  ghensuu.seichouryoku_type_gakunen[9][3] = 170;
  ghensuu.seichouryoku_type_sentakuritu[10] = 1;
  ghensuu.seichouryoku_type_gakunen[10][0] = 30;
  ghensuu.seichouryoku_type_gakunen[10][1] = 170;
  ghensuu.seichouryoku_type_gakunen[10][2] = 30;
  ghensuu.seichouryoku_type_gakunen[10][3] = 170;
  for (int i = 0; i < TEISUU.SUU_MAXRACESUU_1YEAR; i++) {
    for (int ii = 0; ii < TEISUU.SUU_BESTKIROKUHOZONJUNISUU; ii++) {
      ghensuu.time_zentaitaikaikiroku[i][ii] = TEISUU.DEFAULTTIME;
      ghensuu.year_zentaitaikaikiroku[i][ii] = 0;
      ghensuu.month_zentaitaikaikiroku[i][ii] = 0;
      //ghensuu.day_zentaitaikaikiroku[i][ii] = 0;
      ghensuu.univname_zentaitaikaikiroku[i][ii] = "";
    }
    for (int ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
      for (int iii = 0; iii < TEISUU.SUU_BESTKIROKUHOZONJUNISUU; iii++) {
        ghensuu.time_zentaikukankiroku[i][ii][iii] = TEISUU.DEFAULTTIME;
        ghensuu.year_zentaikukankiroku[i][ii][iii] = 0;
        ghensuu.month_zentaikukankiroku[i][ii][iii] = 0;

        ghensuu.univname_zentaikukankiroku[i][ii][iii] = "";
        ghensuu.name_zentaikukankiroku[i][ii][iii] = "";
        ghensuu.gakunen_zentaikukankiroku[i][ii][iii] = 0;
      }
    }
  }
  for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
    for (int ii = 0; ii < TEISUU.SUU_BESTKIROKUHOZONJUNISUU; ii++) {
      ghensuu.time_zentaikojinkiroku[i][ii] = TEISUU.DEFAULTTIME;
      ghensuu.year_zentaikojinkiroku[i][ii] = 0;
      ghensuu.month_zentaikojinkiroku[i][ii] = 0;

      ghensuu.univname_zentaikojinkiroku[i][ii] = "";
      ghensuu.name_zentaikojinkiroku[i][ii] = "";
      ghensuu.gakunen_zentaikojinkiroku[i][ii] = 0;
    }
  }
  ghensuu.year = 1;
  ghensuu.month = 4;
  ghensuu.day = 5;
  ghensuu.ondoflag = 0;
  ghensuu.kazeflag = 0;
  for (int i = 0; i < 20; i++) {
    ghensuu.nouryokumieruflag[i] = 0;
  }
  //駅伝男と平常心は最初から見えるようにしてみた
  ghensuu.nouryokumieruflag[0] = 1;
  ghensuu.nouryokumieruflag[1] = 1;
  /*ghensuu.nouryokumieruflag[0] = 0;
  ghensuu.nouryokumieruflag[1] = 0;
  ghensuu.nouryokumieruflag[2] = 0;
  ghensuu.nouryokumieruflag[3] = 0;
  ghensuu.nouryokumieruflag[4] = 0;
  ghensuu.nouryokumieruflag[5] = 0;
  ghensuu.nouryokumieruflag[6] = 0;
  ghensuu.nouryokumieruflag[7] = 0;
  ghensuu.nouryokumieruflag[8] = 0;
  ghensuu.nouryokumieruflag[9] = 0;
  ghensuu.nouryokumieruflag[10] = 0;
  ghensuu.nouryokumieruflag[11] = 0;
  ghensuu.nouryokumieruflag[12] = 0;
  ghensuu.nouryokumieruflag[13] = 0;
  ghensuu.nouryokumieruflag[14] = 0;
  ghensuu.nouryokumieruflag[15] = 0;
  ghensuu.nouryokumieruflag[16] = 0;
  ghensuu.nouryokumieruflag[17] = 0;
  ghensuu.nouryokumieruflag[18] = 0;
  ghensuu.nouryokumieruflag[19] = 0;*/
  ghensuu.goldenballsuu = 0;
  ghensuu.last_goldenballkakutokusuu = 0;
  ghensuu.silverballsuu = 0;
  ghensuu.last_silverballkakutokusuu = 0;
  // 処理を適用したデータをBoxに保存（上書き）
  await ghensuuBox.put('global_ghensuu', ghensuu);
}
