// lib/qr_camera_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// 共通ロジックをインポート
import 'senshu_qr_processor.dart';
// 以下のファイルパスは元のプロジェクト構造に合わせて調整してください
//import 'senshu_data.dart';
//import 'shareable_senshu_data.dart';
//import 'ghensuu.dart';
//import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';

class QrCameraScannerScreen extends StatefulWidget {
  final int senshuIdToUpdate;

  const QrCameraScannerScreen({super.key, required this.senshuIdToUpdate});

  @override
  _QrCameraScannerScreenState createState() => _QrCameraScannerScreenState();
}

class _QrCameraScannerScreenState extends State<QrCameraScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  late SenshuQrProcessor _processor;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // プロセッサを初期化
    _processor = SenshuQrProcessor(
      senshuIdToUpdate: widget.senshuIdToUpdate,
      context: context,
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _controller.stop(); // 検出後はスキャンを一時停止

    try {
      // ⬅️ try-catchの追加
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        final String qrData = barcodes.first.rawValue!;

        final bool success = await _processor.processScannedData(qrData);

        if (mounted) {
          if (success) {
            // 処理成功時は画面を閉じる（元のコードの挙動を再現）
            Navigator.pop(context);
          } else {
            // 失敗またはキャンセルの場合、スキャンを再開
            _isProcessing = false;
            _controller.start();
          }
        }
      } else {
        // バーコードが見つからない場合、スキャンを再開
        _isProcessing = false;
        _controller.start();
      }
    } catch (e) {
      debugPrint('QRコード処理中に予期せぬエラーが発生しました: $e');
      if (mounted) {
        // ユーザーにエラーを通知
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データの処理中に予期せぬエラーが発生しました。スキャンを再開します。')),
        );
        // エラー発生後、フリーズを防ぐためにフラグをリセットし、スキャンを再開
        _isProcessing = false;
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カメラでQRコードをスキャン')),
      body: Stack(
        children: [
          // MobileScanner: カメラからのライブスキャン
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              // CameraUnavailableExceptionなどによりカメラが使えない場合
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    'ライブスキャン機能に問題が発生しました。'
                    'カメラが利用できないか、権限が許可されていません。\n'
                    '別の方法（写真ライブラリ）で読み込んでください。',
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
