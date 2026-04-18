// lib/qr_camera_scanner_modal.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qr_processor.dart';

class QrCameraScannerModal extends StatefulWidget {
  final QrReceiveState receiveState; // 受信状態を親から受け取る

  const QrCameraScannerModal({super.key, required this.receiveState});

  @override
  _QrCameraScannerModalState createState() => _QrCameraScannerModalState();
}

class _QrCameraScannerModalState extends State<QrCameraScannerModal> {
  final MobileScannerController _controller = MobileScannerController();
  late SettingsQrProcessor _processor;
  bool _isProcessing = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _processor = SettingsQrProcessor(context);
    // 既存のデータがあれば、読み込みを継続できる
    if (widget.receiveState.receivedParts.isEmpty) {
      _processor.context; // 初期化
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || !_isScanning) return;
    _isProcessing = true;
    _controller.stop();

    try {
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        final String qrData = barcodes.first.rawValue!;

        // processQrDataは、処理成功（全データ更新完了）の場合にtrueを返します
        final bool isUpdateComplete = await _processor.processQrData(
          qrData,
          widget.receiveState,
        );

        if (mounted) {
          if (isUpdateComplete) {
            // 全データが揃い、Hiveが更新された場合
            Navigator.pop(context);
          } else {
            // データが分割されている途中、またはキャンセル/エラーの場合
            // スキャンを再開
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
      debugPrint('QRコード処理エラー: $e');
      if (mounted) {
        _processor.context; // エラーメッセージを表示（プロセッサ内でSnackbarが表示されることを想定）
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
              _isScanning = false; // スキャン停止
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
              child: Center(
                child: Text(
                  widget.receiveState.receivedParts.isEmpty
                      ? 'QRコードをスキャン'
                      : '次のQRコードをスキャン中',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // 処理中のオーバーレイ
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
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
