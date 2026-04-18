import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
// 以下のファイルパスは元のプロジェクト構造に合わせて調整してください
import 'senshu_data.dart';
import 'shareable_senshu_data.dart';
import 'ghensuu.dart';
import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';

// データ更新処理の共通インターフェースを定義
class SenshuQrProcessor {
  final int senshuIdToUpdate;
  final BuildContext context;

  SenshuQrProcessor({required this.senshuIdToUpdate, required this.context});

  // データ処理の中核ロジック
  Future<bool> processScannedData(String qrData) async {
    try {
      final senshuBox = Hive.box<SenshuData>('senshuBox');
      final targetSenshu = senshuBox.get(senshuIdToUpdate);

      if (targetSenshu == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('更新対象の選手が見つかりません。')));
        }
        return false;
      }

      final Map<String, dynamic> senshuMap = jsonDecode(qrData);
      final ShareableSenshuData newShareableData = ShareableSenshuData.fromJson(
        senshuMap,
      );

      final bool confirmUpdate =
          await showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('データの更新確認'),
                content: Text(
                  '選手「${newShareableData.name}」のQRコードのデータで上書きしますか？\n'
                  '※一度更新すると元に戻せません。',
                  style: const TextStyle(color: Colors.black),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('キャンセル'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('はい'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;

      if (confirmUpdate) {
        // 選手データの更新
        targetSenshu.name = newShareableData.name;
        targetSenshu.magicnumber = newShareableData.magicnumber;
        targetSenshu.a = newShareableData.a;
        targetSenshu.b = newShareableData.b;
        targetSenshu.sositu = newShareableData.sositu;
        targetSenshu.sositu_bonus = newShareableData.sositu_bonus;
        targetSenshu.seichoutype = newShareableData.seichoutype;
        targetSenshu.genkaitoppakaisuu = newShareableData.genkaitoppakaisuu;
        targetSenshu.seichoukaisuu = newShareableData.seichoukaisuu;
        targetSenshu.genkaichokumenkaisuu =
            newShareableData.genkaichokumenkaisuu;
        targetSenshu.mokuhyo_b = newShareableData.mokuhyo_b;
        targetSenshu.rirontime5000 = newShareableData.rirontime5000;
        targetSenshu.rirontime10000 = newShareableData.rirontime10000;
        targetSenshu.rirontimehalf = newShareableData.rirontimehalf;
        targetSenshu.kiroku_nyuugakuji_5000 =
            newShareableData.kiroku_nyuugakuji_5000;
        targetSenshu.time_bestkiroku = newShareableData.time_bestkiroku;
        targetSenshu.year_bestkiroku = newShareableData.year_bestkiroku;
        targetSenshu.month_bestkiroku = newShareableData.month_bestkiroku;
        targetSenshu.konjou = newShareableData.konjou;
        targetSenshu.heijousin = newShareableData.heijousin;
        targetSenshu.choukyorinebari = newShareableData.choukyorinebari;
        targetSenshu.spurtryoku = newShareableData.spurtryoku;
        targetSenshu.kegaflag = newShareableData.kegaflag;
        targetSenshu.hirou = newShareableData.hirou;
        targetSenshu.kaifukuryoku = newShareableData.kaifukuryoku;
        targetSenshu.anteikan = newShareableData.anteikan;
        targetSenshu.chousi = newShareableData.chousi;
        targetSenshu.karisuma = newShareableData.karisuma;
        targetSenshu.kazetaisei = newShareableData.kazetaisei;
        targetSenshu.atusataisei = newShareableData.atusataisei;
        targetSenshu.samusataisei = newShareableData.samusataisei;
        targetSenshu.noboritekisei = newShareableData.noboritekisei;
        targetSenshu.kudaritekisei = newShareableData.kudaritekisei;
        targetSenshu.noborikudarikirikaenouryoku =
            newShareableData.noborikudarikirikaenouryoku;
        targetSenshu.tandokusou = newShareableData.tandokusou;
        targetSenshu.paceagesagetaiouryoku =
            newShareableData.paceagesagetaiouryoku;

        if (targetSenshu.kaifukuryoku < 0 || targetSenshu.kaifukuryoku > 5) {
          targetSenshu.kaifukuryoku = 0;
        }

        await targetSenshu.save();

        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final List<Ghensuu> gh = [ghensuuBox.getAt(0)!];
        List<SenshuData> sortedsenshudata = senshuBox.values.toList();
        sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));

        for (int kirokubangou = 0; kirokubangou < 8; kirokubangou++) {
          // 既存の関数を呼び出す
          kojinBestKirokuJuniKettei(kirokubangou, gh, sortedsenshudata);
        }

        for (var senshu in sortedsenshudata) {
          await senshu.save();
        }

        await updateAllSenshuChartdata_atusataisei();
        await refreshAllUnivAnalysisData();

        if (context.mounted) {
          // Navigator.pop(context); // 画面遷移は呼び出し元で制御
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${targetSenshu.name}のデータに更新されました！')),
          );
        }
        return true; // 成功
      } else {
        return false; // キャンセル
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無効なQRコードです。')));
      }
      return false; // 失敗
    }
  }
}
