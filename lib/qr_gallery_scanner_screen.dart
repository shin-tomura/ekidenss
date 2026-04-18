// lib/qr_gallery_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// 共通ロジックをインポート
import 'senshu_qr_processor.dart';
// 以下のファイルパスは元のプロジェクト構造に合わせて調整してください
//import 'senshu_data.dart';
//import 'shareable_senshu_data.dart';
//import 'ghensuu.dart';
//import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';

class QrGalleryScannerScreen extends StatefulWidget {
  final int senshuIdToUpdate;

  const QrGalleryScannerScreen({super.key, required this.senshuIdToUpdate});

  @override
  _QrGalleryScannerScreenState createState() => _QrGalleryScannerScreenState();
}

class _QrGalleryScannerScreenState extends State<QrGalleryScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController();
  late SenshuQrProcessor _processor;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processor = SenshuQrProcessor(
      senshuIdToUpdate: widget.senshuIdToUpdate,
      context: context,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanFromGallery();
    });
  }

  void _showErrorAndReset(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _scanFromGallery() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // ⬅️ ここから try-catch を適用
        final BarcodeCapture? capture = await _controller.analyzeImage(
          pickedFile.path,
        );

        if (mounted) {
          if (capture != null && capture.barcodes.isNotEmpty) {
            final String? qrData = capture.barcodes.first.rawValue;

            if (qrData != null) {
              final bool success = await _processor.processScannedData(qrData);
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                } else {
                  setState(() => _isProcessing = false);
                }
              }
            } else {
              _showErrorAndReset('画像からQRコードを検出できませんでした。');
            }
          } else {
            // QRコードでない画像や、解析できない画像の場合
            _showErrorAndReset('画像からQRコードを検出できませんでした。');
          }
        }
      } catch (e) {
        // ⬅️ 例外を捕捉する
        String errorMessage = '画像解析中にエラーが発生しました。';
        // iOS Simulator の特定のエラーメッセージをユーザーに分かりやすくする
        if (e.toString().contains(
          'Unsupported operation: Analyzing an image',
        )) {
          errorMessage = '画像解析はお使いの環境ではサポートされていません。';
        }
        _showErrorAndReset(errorMessage);
        // ログに出力
        debugPrint('画像解析エラー: $e');
      }
    } else {
      // ユーザーがギャラリーをキャンセルした場合
      if (mounted) {
        Navigator.pop(context);
      }
    }
    // 処理が完了しなかった場合は、ここで _isProcessing がリセットされることを確認
    if (_isProcessing && mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('写真から読み込む')),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('QRコードを解析中です...'),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: _scanFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('写真ライブラリから再度選択'),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
