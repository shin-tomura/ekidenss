// lib/qr_gallery_scanner_modal.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qr_processor.dart';

class QrGalleryScannerModal extends StatefulWidget {
  final QrReceiveState receiveState;

  const QrGalleryScannerModal({super.key, required this.receiveState});

  @override
  _QrGalleryScannerModalState createState() => _QrGalleryScannerModalState();
}

class _QrGalleryScannerModalState extends State<QrGalleryScannerModal> {
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController();
  late SettingsQrProcessor _processor;
  bool _isProcessing = false;
  bool _scanAttempted = false; // 最初のスキャン試行が完了したか

  @override
  void initState() {
    super.initState();
    _processor = SettingsQrProcessor(context);
    if (widget.receiveState.receivedParts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanFromGallery();
      });
    } else {
      // 既に受信中のデータがある場合は、すぐに再選択ボタンを表示
      _scanAttempted = true;
    }
  }

  void _showErrorAndReset(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      // エラー発生時は状態をリセット
      setState(() {
        _isProcessing = false;
        widget.receiveState.reset();
      });
    }
  }

  void _scanFromGallery() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _scanAttempted = true;
    });

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final BarcodeCapture? capture = await _controller.analyzeImage(
          pickedFile.path,
        );

        if (mounted && capture != null && capture.barcodes.isNotEmpty) {
          final String? qrData = capture.barcodes.first.rawValue;

          if (qrData != null) {
            final bool isUpdateComplete = await _processor.processQrData(
              qrData,
              widget.receiveState,
            );

            if (mounted) {
              if (isUpdateComplete) {
                Navigator.pop(context);
              } else {
                // 途中または失敗/キャンセルの場合、再選択ボタンを表示
                // SnackBarはprocessor側で表示されるため、ここでは処理フラグのみリセット
                setState(() => _isProcessing = false);
              }
            }
          } else {
            _showErrorAndReset('画像からQRコードを検出できませんでした。');
          }
        } else {
          _showErrorAndReset('画像からQRコードを検出できませんでした。');
        }
      } catch (e) {
        debugPrint('画像解析エラー: $e');
        _showErrorAndReset('画像解析中にエラーが発生しました。');
      }
    } else {
      // ユーザーがギャラリーをキャンセルした場合
      if (mounted && widget.receiveState.receivedParts.isEmpty) {
        Navigator.pop(context); // 受信データがない場合は閉じる
      }
    }
    // 処理が成功またはキャンセルで終了しなかった場合のリセット
    if (_isProcessing && mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 既に受信中のデータがあるか
    final bool isReceiving = widget.receiveState.receivedParts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('写真から読み込む')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isReceiving ? '次のQRコードを解析中です...' : 'QRコードを解析中です...',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : _scanAttempted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isReceiving)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        '現在 ${widget.receiveState.receivedParts.length} 枚のデータを読込済みです。\n'
                        '続きのQRコード画像を選択してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueGrey[700]),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _scanFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(isReceiving ? '続きのQRコードを選択' : '写真ライブラリから選択'),
                  ),
                  if (isReceiving)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          widget.receiveState.reset();
                        });
                        Navigator.pop(context);
                        // 親画面でSnackBarを表示させるために pop の後に setState はしない
                      },
                      child: const Text('読み込みを中止してリセット'),
                    ),
                ],
              )
            : const SizedBox.shrink(), // 最初の自動起動待ち
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
