// lib/qr_processor.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
// 既存のデータモデルをインポート (パスはプロジェクト構造に合わせて修正してください)
import 'kantoku_data.dart'; // KantokuData
import 'album.dart'; // Album
import 'univ_data.dart'; // UnivData
import 'ghensuu.dart'; // Ghensuu
import 'qr_data_model.dart';

// 読み込み時に複数枚のデータを一時的に保持する状態管理クラス
class QrReceiveState {
  // Key: '部門Index_パーツIndex', Value: Base64データの一部
  final Map<String, String> receivedParts = {};

  // 受信データをリセット
  void reset() => receivedParts.clear();
}

// QRコードで設定を扱うためのコアロジック
class SettingsQrProcessor {
  final BuildContext context;
  // QRコードのデータ量制約を考慮し、1枚あたり約1500バイト（Base64エンコード後）に設定
  //static const int _maxQrDataSize = 1500;
  static const int _maxQrDataSize = 1000;

  SettingsQrProcessor(this.context);

  // --- ヘルパー関数 ---

  String _getDepartmentName(SettingsDepartment department) {
    switch (department) {
      case SettingsDepartment.generalSettings:
        return '各種設定';
      case SettingsDepartment.octoberEkiden:
        return '10月駅伝コース';
      case SettingsDepartment.novemberEkiden:
        return '11月駅伝コース';
      case SettingsDepartment.shogatsuEkiden:
        return '正月駅伝コース';
      case SettingsDepartment.customEkiden:
        return 'カスタム駅伝コース';
      case SettingsDepartment.octoberTime:
        return '10月タイム調整';
      case SettingsDepartment.novemberTime:
        return '11月タイム調整';
      case SettingsDepartment.shogatsuTime:
        return '正月タイム調整';
      case SettingsDepartment.customTime:
        return 'カスタムタイム調整';
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  // --- 1. データ抽出/シリアライズ (エクスポート用) ---

  // 指定された部門のデータをJSON Mapとして抽出
  Map<String, dynamic> _extractDepartmentData(SettingsDepartment department) {
    final kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData')!;
    final album = Hive.box<Album>('albumBox').get('AlbumData')!;
    List<UnivData> sortedUnivData = Hive.box<UnivData>(
      'univBox',
    ).values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    final currentGhensuu = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;

    final Map<String, dynamic> data = {};

    // ★★★ 各種設定部門の抽出 ★★★
    if (department == SettingsDepartment.generalSettings) {
      // 実力発揮度設定(int)
      data['k_yobiint5_0_29'] = kantoku.yobiint5.sublist(0, 30);
      // 難易度「極」「天」設定(int)
      data['k_yobiint2_0'] = kantoku.yobiint2[0];
      // 難易度(int)
      data['cg_kazeflag'] = currentGhensuu.kazeflag;
      // 難易度変更2(int)
      data['cg_ondoflag'] = currentGhensuu.ondoflag;
      // 育成力(int) & 名声(int) (UnivData 0から29)
      data['ud_ikuseiryoku'] = sortedUnivData
          .sublist(0, 30)
          .map((u) => u.ikuseiryoku)
          .toList();
      data['ud_meisei_total'] = sortedUnivData
          .sublist(0, 30)
          .map((u) => u.meisei_total)
          .toList();
      // 入学時名声影響度設定(int)
      data['cg_spurtryokuseichousisuu3'] =
          currentGhensuu.spurtryokuseichousisuu3;
      // 目標順位決め方設定(int)
      data['cg_spurtryokuseichousisuu2'] =
          currentGhensuu.spurtryokuseichousisuu2;
      // カスタム駅伝開催するしない(int)
      data['cg_spurtryokuseichousisuu1'] =
          currentGhensuu.spurtryokuseichousisuu1;
      // カスタム駅伝獲得名声倍率(int)
      data['cg_spurtryokuseichousisuu4'] =
          currentGhensuu.spurtryokuseichousisuu4;
      data['cg_spurtryokuseichousisuu5'] =
          currentGhensuu.spurtryokuseichousisuu5;
      // 駅伝名声設定(String) (UnivData 1から6)
      data['ud_name_tanshuku_1_6'] = sortedUnivData
          .sublist(1, 7)
          .map((u) => u.name_tanshuku)
          .toList();
      // 留学生受け入れ設定(int)
      data['ud_r'] = sortedUnivData.sublist(0, 30).map((u) => u.r).toList();
      // 学連選抜モチベーション設定(int)
      data['a_yobiint4'] = album.yobiint4;
      // 最適解区間配置確率設定(int)
      data['a_tourokusuu_total'] = album.tourokusuu_total;
      // 全体・区間ごとタイム調整(int)
      data['k_yobiint5_30_60'] = kantoku.yobiint5.sublist(30, 61);
      data['k_yobiint5_80_89'] = kantoku.yobiint5.sublist(80, 90);
      // 長距離タイム抑制設定
      data['k_yobiint2_13'] = kantoku.yobiint2[13];
      data['ud_name_tanshuku_9'] = sortedUnivData[9].name_tanshuku;
      // 調子関連設定(int)
      data['k_yobiint2_2_11'] = kantoku.yobiint2.sublist(2, 12);
      // 金銀支給量倍率設定(int)
      data['k_yobiint2_12'] = kantoku.yobiint2[12];
      // 記録会時期設定(int)
      data['k_yobiint2_14'] = kantoku.yobiint2[14];
      // 年間強化練習効果設定(int)
      data['k_yobiint2_16'] = kantoku.yobiint2[16];
    } else if (department == SettingsDepartment.octoberTime) {
      //区間ごとタイム調整(int)
      data['k_yobiint5_30_39_time'] = kantoku.yobiint5.sublist(30, 40);
    } else if (department == SettingsDepartment.novemberTime) {
      //区間ごとタイム調整(int)
      data['k_yobiint5_40_49_time'] = kantoku.yobiint5.sublist(40, 50);
    } else if (department == SettingsDepartment.shogatsuTime) {
      //区間ごとタイム調整(int)
      data['k_yobiint5_50_59_time'] = kantoku.yobiint5.sublist(50, 60);
    } else if (department == SettingsDepartment.customTime) {
      //区間ごとタイム調整(int)
      data['k_yobiint5_80_89_time'] = kantoku.yobiint5.sublist(80, 90);
    }
    // ★★★ 駅伝コース部門の抽出 ★★★
    else {
      int idx = -1;
      if (department == SettingsDepartment.octoberEkiden) idx = 0;
      if (department == SettingsDepartment.novemberEkiden) idx = 1;
      if (department == SettingsDepartment.shogatsuEkiden) idx = 2;
      if (department == SettingsDepartment.customEkiden) idx = 5;

      if (idx != -1) {
        data['kukansuu'] = currentGhensuu.kukansuu_taikaigoto[idx];
        data['kyori'] = currentGhensuu.kyori_taikai_kukangoto[idx];
        data['kyoriwariainobori'] =
            currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx];
        data['heikinkoubainobori'] =
            currentGhensuu.heikinkoubainobori_taikai_kukangoto[idx];
        data['kyoriwariaikudari'] =
            currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx];
        data['heikinkoubaikudari'] =
            currentGhensuu.heikinkoubaikudari_taikai_kukangoto[idx];
        data['noborikudarikirikaekaisuu'] =
            currentGhensuu.noborikudarikirikaekaisuu_taikai_kukangoto[idx];
      }
    }

    return data;
  }

  // 部門のデータをBase64エンコードされた文字列のリストに変換
  List<String> serializeAndSplit(SettingsDepartment department) {
    final dataMap = _extractDepartmentData(department);
    final jsonString = jsonEncode(dataMap);
    final dataBytes = utf8.encode(jsonString);
    final base64String = base64Encode(dataBytes);

    // データ分割ロジック
    List<String> parts = [];
    for (int i = 0; i < base64String.length; i += _maxQrDataSize) {
      final end = (i + _maxQrDataSize < base64String.length)
          ? i + _maxQrDataSize
          : base64String.length;
      parts.add(base64String.substring(i, end));
    }

    // QrPayloadを構築し、最終的なQRコード文字列のリストを作成
    List<String> qrStrings = [];
    for (int i = 0; i < parts.length; i++) {
      final payload = QrPayload(
        header: QrHeader(
          department: department,
          totalParts: parts.length,
          currentPart: i, // 0-indexed
        ),
        data: parts[i],
      );
      qrStrings.add(payload.toQrString());
    }

    return qrStrings;
  }

  // --- 2. データ格納/デシリアライズ (インポート用) ---

  // QRコード文字列を受け取り、結合してデータモデルを更新
  // isUpdateComplete: 全データが揃い、Hiveが更新された場合にtrueを返す
  Future<bool> processQrData(
    String qrString,
    QrReceiveState receiveState,
  ) async {
    try {
      final payload = QrPayload.fromQrString(qrString);
      final header = payload.header;
      final department = header.department;
      final totalParts = header.totalParts;
      final partKey = '${department.index}_${header.currentPart}';

      // 受信したデータを保存
      receiveState.receivedParts[partKey] = payload.data;

      // データの完全性をチェック
      if (receiveState.receivedParts.length < totalParts) {
        // まだデータが揃っていない
        _showSnackbar(
          'QRコード ${header.currentPart + 1}/$totalParts '
          '(${_getDepartmentName(department)})を読み込みました。'
          '次のQRコードを読み込んでください。',
        );
        return false;
      }

      // すべてのパーツが揃ったことを確認（キーのチェック）
      final allPartsReceived = List.generate(
        totalParts,
        (i) => '${department.index}_$i',
      ).every((key) => receiveState.receivedParts.containsKey(key));

      if (!allPartsReceived) {
        _showSnackbar(
          'データのパーツが不足しているか、順番が間違っています。リセットして最初から読み込んでください。',
          isError: true,
        );
        receiveState.reset(); // エラー時はリセット
        return false;
      }

      // データの結合とデコード
      final combinedBase64 = List.generate(
        totalParts,
        (i) => receiveState.receivedParts['${department.index}_$i']!,
      ).join();
      final decodedBytes = base64Decode(combinedBase64);
      final jsonString = utf8.decode(decodedBytes);
      final Map<String, dynamic> dataMap = jsonDecode(jsonString);

      // ユーザー確認ダイアログ
      final bool confirmUpdate = await _showUpdateConfirmation(
        department,
        totalParts,
      );

      if (confirmUpdate) {
        // Hiveデータモデルの更新
        await _updateHiveData(department, dataMap);
        receiveState.reset(); // 処理完了
        _showSnackbar('${_getDepartmentName(department)} の設定が更新されました！');
        return true;
      } else {
        receiveState.reset(); // キャンセル時はリセット
        return false;
      }
    } catch (e) {
      debugPrint('QRコード処理エラー: $e');
      _showSnackbar('無効なQRコード、または処理中に予期せぬエラーが発生しました。', isError: true);
      receiveState.reset(); // エラー時はリセット
      return false;
    }
  }

  // Hiveデータの更新ロジック（デシリアライズ）
  Future<void> _updateHiveData(
    SettingsDepartment department,
    Map<String, dynamic> dataMap,
  ) async {
    final kantokuBox = Hive.box<KantokuData>('kantokuBox');
    final kantoku = kantokuBox.get('KantokuData')!;
    final albumBox = Hive.box<Album>('albumBox');
    final album = albumBox.get('AlbumData')!;
    final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final currentGhensuu = ghensuuBox.getAt(0)!;
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    // ★★★ 各種設定部門の格納 ★★★
    if (department == SettingsDepartment.generalSettings) {
      // 実力発揮度設定(int) k_yobiint5[0から29]
      final List<dynamic> yobiint5_0_29 = dataMap['k_yobiint5_0_29'] ?? [];
      for (int i = 0; i <= 29; i++) {
        if (i < yobiint5_0_29.length) {
          kantoku.yobiint5[i] = yobiint5_0_29[i] as int;
          //ここはもともと圧縮されて格納されているし、取り出す時に範囲限定の安全策も講じているのでここでは何も安全策は取らない
        }
      }
      // 難易度「極」「天」設定(int) k_yobiint2[0]
      kantoku.yobiint2[0] = dataMap['k_yobiint2_0'] as int;
      if (kantoku.yobiint2[0] < 0 || kantoku.yobiint2[0] > 2) {
        kantoku.yobiint2[0] = 0;
      }
      // 難易度(int) cg_kazeflag
      currentGhensuu.kazeflag = dataMap['cg_kazeflag'] as int;
      if (currentGhensuu.kazeflag < 0 || currentGhensuu.kazeflag > 3) {
        currentGhensuu.kazeflag = 0;
      }
      // 難易度変更2(int) cg_ondoflag
      currentGhensuu.ondoflag = dataMap['cg_ondoflag'] as int;
      if (currentGhensuu.ondoflag < 0 || currentGhensuu.ondoflag > 9) {
        currentGhensuu.ondoflag = 0;
      }
      // 入学時名声影響度設定(int)
      currentGhensuu.spurtryokuseichousisuu3 =
          dataMap['cg_spurtryokuseichousisuu3'] as int;
      if (currentGhensuu.spurtryokuseichousisuu3 < 0 ||
          currentGhensuu.spurtryokuseichousisuu3 > 9) {
        currentGhensuu.spurtryokuseichousisuu3 = 0;
      }
      // 目標順位決め方設定(int)
      currentGhensuu.spurtryokuseichousisuu2 =
          dataMap['cg_spurtryokuseichousisuu2'] as int;
      if (currentGhensuu.spurtryokuseichousisuu2 != 93 &&
          currentGhensuu.spurtryokuseichousisuu2 != 1 &&
          currentGhensuu.spurtryokuseichousisuu2 != 2) {
        currentGhensuu.spurtryokuseichousisuu2 = 93;
      }
      // カスタム駅伝開催するしない(int)
      currentGhensuu.spurtryokuseichousisuu1 =
          dataMap['cg_spurtryokuseichousisuu1'] as int;
      if (currentGhensuu.spurtryokuseichousisuu1 < 0 ||
          currentGhensuu.spurtryokuseichousisuu1 > 1) {
        currentGhensuu.spurtryokuseichousisuu1 = 1;
      }
      // カスタム駅伝獲得名声倍率(int)
      currentGhensuu.spurtryokuseichousisuu4 =
          dataMap['cg_spurtryokuseichousisuu4'] as int;
      if (currentGhensuu.spurtryokuseichousisuu4 < 1 ||
          currentGhensuu.spurtryokuseichousisuu4 > 10) {
        currentGhensuu.spurtryokuseichousisuu4 = 1;
      }
      currentGhensuu.spurtryokuseichousisuu5 =
          dataMap['cg_spurtryokuseichousisuu5'] as int;
      if (currentGhensuu.spurtryokuseichousisuu5 < 1 ||
          currentGhensuu.spurtryokuseichousisuu5 > 10) {
        currentGhensuu.spurtryokuseichousisuu5 = 10;
      }
      // 学連選抜モチベーション設定(int)
      album.yobiint4 = dataMap['a_yobiint4'] as int;
      if (album.yobiint4 < 0 || album.yobiint4 > 10) {
        album.yobiint4 = 5;
      }
      // 最適解区間配置確率設定(int)
      album.tourokusuu_total = dataMap['a_tourokusuu_total'] as int;
      if (album.tourokusuu_total < 0 || album.tourokusuu_total > 100) {
        album.tourokusuu_total = 30;
      }
      // 全体・区間ごとタイム調整(int) kantoku.yobiint5[30から60]
      final List<dynamic> yobiint5_30_60 = dataMap['k_yobiint5_30_60'] ?? [];
      kantoku.yobiint5[60] = yobiint5_30_60[60 - 30] as int;
      if (kantoku.yobiint5[60] < -20 || kantoku.yobiint5[60] > 20) {
        kantoku.yobiint5[60] = 0;
      }
      /*
      for (int i = 30; i <= 60; i++) {
        if ((i - 30) < yobiint5_30_60.length) {
          kantoku.yobiint5[i] = yobiint5_30_60[i - 30] as int;
          if (kantoku.yobiint5[i] < -10 || kantoku.yobiint5[i] > 10) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      // 全体・区間ごとタイム調整(int) kantoku.yobiint5[80から89]
      final List<dynamic> yobiint5_80_89 = dataMap['k_yobiint5_80_89'] ?? [];
      for (int i = 80; i <= 89; i++) {
        if ((i - 80) < yobiint5_80_89.length) {
          kantoku.yobiint5[i] = yobiint5_80_89[i - 80] as int;
          if (kantoku.yobiint5[i] < -10 || kantoku.yobiint5[i] > 10) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      */
      // 長距離タイム抑制設定 kantoku.yobiint2[13](int)
      kantoku.yobiint2[13] = dataMap['k_yobiint2_13'] as int;
      if (kantoku.yobiint2[13] < -18 || kantoku.yobiint2[13] > 50) {
        kantoku.yobiint2[13] = 0;
      }
      // 調子関連設定(int) kantoku.yobiint2[2から11]
      final List<dynamic> yobiint2_2_11 = dataMap['k_yobiint2_2_11'] ?? [];
      for (int i = 2; i <= 11; i++) {
        if ((i - 2) < yobiint2_2_11.length) {
          kantoku.yobiint2[i] = yobiint2_2_11[i - 2] as int;
        }
        if (kantoku.yobiint2[2] < 0 || kantoku.yobiint2[2] > 100) {
          kantoku.yobiint2[13] = 25;
        }
        if (kantoku.yobiint2[3] < 0 || kantoku.yobiint2[3] > 100) {
          kantoku.yobiint2[3] = 70;
        }
        if (kantoku.yobiint2[4] < 0 || kantoku.yobiint2[4] > 99) {
          kantoku.yobiint2[4] = 50;
        }
        if (kantoku.yobiint2[5] < 0 || kantoku.yobiint2[5] > 20) {
          kantoku.yobiint2[5] = 1;
        }
        if (kantoku.yobiint2[6] < 0 || kantoku.yobiint2[6] > 20) {
          kantoku.yobiint2[6] = 1;
        }
        if (kantoku.yobiint2[7] < 1 || kantoku.yobiint2[7] > 90) {
          kantoku.yobiint2[7] = 90;
        }
        if (kantoku.yobiint2[8] < 1 || kantoku.yobiint2[8] > 90) {
          kantoku.yobiint2[8] = 50;
        }
        if (kantoku.yobiint2[9] < 1 || kantoku.yobiint2[9] > 90) {
          kantoku.yobiint2[9] = 30;
        }
        if (kantoku.yobiint2[10] < 0 || kantoku.yobiint2[10] > 1) {
          kantoku.yobiint2[10] = 0;
        }
        if (kantoku.yobiint2[11] < 0 || kantoku.yobiint2[11] > 10) {
          kantoku.yobiint2[11] = 10;
        }
      }

      // 金銀支給量倍率設定(int)
      kantoku.yobiint2[12] = dataMap['k_yobiint2_12'] as int;
      if (kantoku.yobiint2[12] < 1 || kantoku.yobiint2[12] > 2) {
        kantoku.yobiint2[12] = 2;
      }
      // 記録会時期設定(int)
      kantoku.yobiint2[14] = dataMap['k_yobiint2_14'] as int;
      if (kantoku.yobiint2[14] < 0 || kantoku.yobiint2[14] > 1) {
        kantoku.yobiint2[14] = 0;
      }
      // 年間強化練習効果設定(int)
      kantoku.yobiint2[16] = dataMap['k_yobiint2_16'] as int;
      if (kantoku.yobiint2[16] < 0 || kantoku.yobiint2[16] > 5) {
        kantoku.yobiint2[16] = 4;
      }
      // 育成力(int) & 名声(int) & 留学生受け入れ設定(int) (UnivData 0から29)
      final List<dynamic> ikuseiryokuList = dataMap['ud_ikuseiryoku'] ?? [];
      final List<dynamic> meiseiList = dataMap['ud_meisei_total'] ?? [];
      final List<dynamic> rList = dataMap['ud_r'] ?? [];
      for (int i = 0; i <= 29; i++) {
        if (i < sortedUnivData.length) {
          if (i < ikuseiryokuList.length) {
            sortedUnivData[i].ikuseiryoku = ikuseiryokuList[i] as int;
            if (sortedUnivData[i].ikuseiryoku < 10 ||
                sortedUnivData[i].ikuseiryoku > 150) {
              sortedUnivData[i].ikuseiryoku = 150;
            }
          }
          if (i < meiseiList.length) {
            sortedUnivData[i].meisei_total = meiseiList[i] as int;
            if (sortedUnivData[i].meisei_total < 9 ||
                sortedUnivData[i].meisei_total > 100000000) {
              sortedUnivData[i].meisei_total = 100;
            }
            int yeargoto = sortedUnivData[i].meisei_total ~/ 9;
            int amari = sortedUnivData[i].meisei_total % 9;
            for (int ii = 0; ii < 9; ii++) {
              sortedUnivData[i].meisei_yeargoto[ii] = yeargoto;
            }
            sortedUnivData[i].meisei_yeargoto[9] = amari;
          }
          if (i < rList.length) {
            sortedUnivData[i].r = rList[i] as int;
            if (sortedUnivData[i].r < 0 || sortedUnivData[i].r > 4) {
              sortedUnivData[i].r = 0;
            }
          }
          await sortedUnivData[i].save();
        }
      }
      // 駅伝名声設定(String) (UnivData 1から6)
      final List<dynamic> nameTanshuku1_6 =
          dataMap['ud_name_tanshuku_1_6'] ?? [];
      for (int i = 1; i <= 6; i++) {
        if (i < sortedUnivData.length && (i - 1) < nameTanshuku1_6.length) {
          sortedUnivData[i].name_tanshuku = nameTanshuku1_6[i - 1] as String;
          final parsedValue = int.tryParse(sortedUnivData[i].name_tanshuku);
          if (parsedValue == null || parsedValue < 1 || parsedValue > 10) {
            sortedUnivData[i].name_tanshuku = "1";
          }
          await sortedUnivData[i].save();
        }
      }
      // 長距離タイム抑制設定 sortedUnivData[9].name_tanshuku(String)
      if (9 < sortedUnivData.length) {
        sortedUnivData[9].name_tanshuku =
            dataMap['ud_name_tanshuku_9'] as String;
        final parsedValue = int.tryParse(sortedUnivData[9].name_tanshuku);
        if (parsedValue == null || parsedValue < 0 || parsedValue > 1) {
          sortedUnivData[9].name_tanshuku = "1";
        }
        await sortedUnivData[9].save();
      }
      await kantoku.save();
      await album.save();
      await currentGhensuu.save();
    } else if (department == SettingsDepartment.octoberTime) {
      //区間ごとタイム調整(int)
      final List<dynamic> yobiint5_time =
          dataMap['k_yobiint5_30_39_time'] ?? [];
      for (int i = 30; i <= 39; i++) {
        if ((i - 30) < yobiint5_time.length) {
          kantoku.yobiint5[i] = yobiint5_time[i - 30] as int;
          if (kantoku.yobiint5[i] < -20 || kantoku.yobiint5[i] > 20) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      await kantoku.save();
    } else if (department == SettingsDepartment.novemberTime) {
      //区間ごとタイム調整(int)
      final List<dynamic> yobiint5_time =
          dataMap['k_yobiint5_40_49_time'] ?? [];
      for (int i = 40; i <= 49; i++) {
        if ((i - 40) < yobiint5_time.length) {
          kantoku.yobiint5[i] = yobiint5_time[i - 40] as int;
          if (kantoku.yobiint5[i] < -20 || kantoku.yobiint5[i] > 20) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      await kantoku.save();
    } else if (department == SettingsDepartment.shogatsuTime) {
      //区間ごとタイム調整(int)
      final List<dynamic> yobiint5_time =
          dataMap['k_yobiint5_50_59_time'] ?? [];
      for (int i = 50; i <= 59; i++) {
        if ((i - 50) < yobiint5_time.length) {
          kantoku.yobiint5[i] = yobiint5_time[i - 50] as int;
          if (kantoku.yobiint5[i] < -20 || kantoku.yobiint5[i] > 20) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      await kantoku.save();
    } else if (department == SettingsDepartment.customTime) {
      //区間ごとタイム調整(int)
      final List<dynamic> yobiint5_time =
          dataMap['k_yobiint5_80_89_time'] ?? [];
      for (int i = 80; i <= 89; i++) {
        if ((i - 80) < yobiint5_time.length) {
          kantoku.yobiint5[i] = yobiint5_time[i - 80] as int;
          if (kantoku.yobiint5[i] < -20 || kantoku.yobiint5[i] > 20) {
            kantoku.yobiint5[i] = 0;
          }
        }
      }
      await kantoku.save();
    }
    // ★★★ 駅伝コース部門の格納 ★★★
    else {
      int idx = -1;
      if (department == SettingsDepartment.octoberEkiden) idx = 0;
      if (department == SettingsDepartment.novemberEkiden) idx = 1;
      if (department == SettingsDepartment.shogatsuEkiden) idx = 2;
      if (department == SettingsDepartment.customEkiden) idx = 5;

      if (idx != -1) {
        if (dataMap.containsKey('kukansuu')) {
          currentGhensuu.kukansuu_taikaigoto[idx] = dataMap['kukansuu'] as int;
          if (currentGhensuu.kukansuu_taikaigoto[0] != 6) {
            currentGhensuu.kukansuu_taikaigoto[0] = 6;
          }
          if (currentGhensuu.kukansuu_taikaigoto[1] != 8) {
            currentGhensuu.kukansuu_taikaigoto[1] = 8;
          }
          if (currentGhensuu.kukansuu_taikaigoto[2] != 10) {
            currentGhensuu.kukansuu_taikaigoto[2] = 10;
          }
          if (currentGhensuu.kukansuu_taikaigoto[5] < 2 ||
              currentGhensuu.kukansuu_taikaigoto[5] > 10) {
            currentGhensuu.kukansuu_taikaigoto[5] = 5;
          }
        }

        // double型のリストの格納
        List<dynamic> kyoriList = dataMap['kyori'] ?? [];
        List<dynamic> kyoriwariainoboriList =
            dataMap['kyoriwariainobori'] ?? [];
        List<dynamic> heikinkoubainoboriList =
            dataMap['heikinkoubainobori'] ?? [];
        List<dynamic> kyoriwariaikudariList =
            dataMap['kyoriwariaikudari'] ?? [];
        List<dynamic> heikinkoubaikudariList =
            dataMap['heikinkoubaikudari'] ?? [];
        List<dynamic> kirikaekaisuuList =
            dataMap['noborikudarikirikaekaisuu'] ?? [];

        for (int i = 0; i <= 9; i++) {
          if (i < kyoriList.length) {
            currentGhensuu.kyori_taikai_kukangoto[idx][i] =
                kyoriList[i] as double;
            if (currentGhensuu.kyori_taikai_kukangoto[idx][i] < 5000.0 ||
                currentGhensuu.kyori_taikai_kukangoto[idx][i] > 25000.0) {
              currentGhensuu.kyori_taikai_kukangoto[idx][i] = 10000.0;
            }
          }
          if (i < kyoriwariainoboriList.length) {
            currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] =
                kyoriwariainoboriList[i] as double;
            if (currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] <
                    0.0 ||
                currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] >
                    1.0001) {
              currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] = 0.0;
            }
          }
          if (i < heikinkoubainoboriList.length) {
            currentGhensuu.heikinkoubainobori_taikai_kukangoto[idx][i] =
                heikinkoubainoboriList[i] as double;
            if (currentGhensuu.heikinkoubainobori_taikai_kukangoto[idx][i] <
                    0.0 ||
                currentGhensuu.heikinkoubainobori_taikai_kukangoto[idx][i] >
                    0.10001) {
              currentGhensuu.heikinkoubainobori_taikai_kukangoto[idx][i] = 0.0;
            }
          }
          if (i < kyoriwariaikudariList.length) {
            currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] =
                kyoriwariaikudariList[i] as double;
            if (currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] <
                    0.0 ||
                currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] >
                    1.0001) {
              currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] = 0.0;
            }
            if (currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] +
                    currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] >
                1.0001) {
              currentGhensuu.kyoriwariainobori_taikai_kukangoto[idx][i] = 0.0;
              currentGhensuu.kyoriwariaikudari_taikai_kukangoto[idx][i] = 0.0;
            }
          }
          if (i < heikinkoubaikudariList.length) {
            currentGhensuu.heikinkoubaikudari_taikai_kukangoto[idx][i] =
                heikinkoubaikudariList[i] as double;
            if (currentGhensuu.heikinkoubaikudari_taikai_kukangoto[idx][i] >
                    0.0 ||
                currentGhensuu.heikinkoubaikudari_taikai_kukangoto[idx][i] <
                    -0.10001) {
              currentGhensuu.heikinkoubaikudari_taikai_kukangoto[idx][i] = 0.0;
            }
          }
          if (i < kirikaekaisuuList.length) {
            currentGhensuu.noborikudarikirikaekaisuu_taikai_kukangoto[idx][i] =
                kirikaekaisuuList[i] as int;
            if (currentGhensuu
                        .noborikudarikirikaekaisuu_taikai_kukangoto[idx][i] <
                    0 ||
                currentGhensuu
                        .noborikudarikirikaekaisuu_taikai_kukangoto[idx][i] >
                    200) {
              currentGhensuu
                      .noborikudarikirikaekaisuu_taikai_kukangoto[idx][i] =
                  0;
            }
          }
        }
        await currentGhensuu.save();
      }
    }
  }

  Future<bool> _showUpdateConfirmation(
    SettingsDepartment department,
    int totalParts,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('設定の更新確認'),
              content: Text(
                '${_getDepartmentName(department)}（全$totalParts枚）のデータで'
                '現在の設定を上書きしますか？\n※一度更新すると元に戻せません。',
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
  }
}
