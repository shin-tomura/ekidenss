// lib/qr_modal.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'senshu_r_data.dart'; // SenshuDataクラスをインポート

class Qr_R_Modal extends StatelessWidget {
  final Senshu_R_Data senshu;

  const Qr_R_Modal({super.key, required this.senshu});

  @override
  Widget build(BuildContext context) {
    final shareableData = senshu.toShareableData();
    final jsonString = jsonEncode(shareableData.toJson());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // ここにSingleChildScrollViewを追加
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${senshu.name}(${senshu.sijiflag}年卒業)のQRコード',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center, // テキストが長い場合に備えて中央寄せ
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: jsonString,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                '選手画面のQRコード読込で読み込めます\nなお、学年は書き込み先選手の学年になります',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
