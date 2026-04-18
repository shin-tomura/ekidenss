// lib/qr_scanner_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'senshu_data.dart';
import 'shareable_senshu_data.dart';
import 'ghensuu.dart';
import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';

class QrScannerScreen extends StatefulWidget {
  final int senshuIdToUpdate;

  const QrScannerScreen({super.key, required this.senshuIdToUpdate});

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // MobileScannerControllerはインスタンス化を維持します
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    _isProcessing = true;
    _controller.stop();

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrData = barcodes.first.rawValue!;
      _processScannedData(context, qrData);
    } else {
      _isProcessing = false;
      _controller.start();
    }
  }

  void _processScannedData(BuildContext context, String qrData) async {
    try {
      final senshuBox = Hive.box<SenshuData>('senshuBox');
      final targetSenshu = senshuBox.get(widget.senshuIdToUpdate);

      if (targetSenshu == null) {
        _isProcessing = false;
        _controller.start();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('更新対象の選手が見つかりません。')));
        }
        return;
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

        await targetSenshu.save();

        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final List<Ghensuu> gh = [ghensuuBox.getAt(0)!];
        List<SenshuData> sortedsenshudata = senshuBox.values.toList();
        sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));

        for (int kirokubangou = 0; kirokubangou < 8; kirokubangou++) {
          kojinBestKirokuJuniKettei(kirokubangou, gh, sortedsenshudata);
        }

        for (var senshu in sortedsenshudata) {
          await senshu.save();
        }

        await updateAllSenshuChartdata_atusataisei();
        await refreshAllUnivAnalysisData();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${targetSenshu.name}のデータに更新されました！')),
          );
        }
      } else {
        _isProcessing = false;
        _controller.start();
      }
    } catch (e) {
      _isProcessing = false;
      _controller.start();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無効なQRコードです。')));
      }
    }
  }

  void _scanFromGallery() async {
    if (_isProcessing) return;
    _isProcessing = true;

    // カメラのライブスキャンは停止しておく
    _controller.stop();

    // ImagePickerはカメラの権限なしでギャラリーにアクセスできます
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // analyzeImageは、カメラハードウェアに依存せず、画像データのみを解析します
      final BarcodeCapture? capture = await _controller.analyzeImage(
        pickedFile.path,
      );

      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? qrData = capture.barcodes.first.rawValue;

        if (qrData != null) {
          _processScannedData(context, qrData);
        } else {
          _isProcessing = false;
          _controller.start();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('画像からQRコードを検出できませんでした。')),
            );
          }
        }
      } else {
        _isProcessing = false;
        _controller.start();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像からQRコードを検出できませんでした。')),
          );
        }
      }
    } else {
      _isProcessing = false;
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコードをスキャン')),
      body: Stack(
        children: [
          // 【修正箇所】errorBuilderを追加し、カメラ初期化時のクラッシュを防ぎ、代替メッセージを表示
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    'ライブスキャン機能に問題が発生しました。'
                    'カメラが利用できないか、権限が許可されていません。\n'
                    '写真からの読み込みは可能です。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),

          // カメラの映像の上に重ねるスキャン枠とテキスト
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Center(
                child: Text(
                  'QRコードをスキャン',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // 写真から読み取るボタンは、カメラの状態に関わらず常に動作します
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _scanFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('写真から読み取る'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 画面が閉じるときにコントローラーを破棄
    _controller.dispose();
    super.dispose();
  }
}
