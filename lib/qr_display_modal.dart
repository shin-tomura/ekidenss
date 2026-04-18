// lib/qr_display_modal.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_processor.dart';
import 'qr_data_model.dart';

class QrDisplayModal extends StatefulWidget {
  final SettingsDepartment department;
  final String memo; // メモ用のプロパティを追加

  // コンストラクタを更新
  const QrDisplayModal({super.key, required this.department, this.memo = ''});

  @override
  _QrDisplayModalState createState() => _QrDisplayModalState();
}

class _QrDisplayModalState extends State<QrDisplayModal> {
  List<String> _qrStrings = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQrStrings();
  }

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

  // データをシリアライズしてQRコード文字列のリストを作成
  void _loadQrStrings() async {
    // 描画が完了する前にcontextを使わないように確認
    if (!mounted) return;

    final processor = SettingsQrProcessor(context);
    final strings = processor.serializeAndSplit(widget.department);

    if (mounted) {
      setState(() {
        _qrStrings = strings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final currentQrData = _qrStrings[_currentIndex];
    final total = _qrStrings.length;
    final current = _currentIndex + 1;
    final departmentName = _getDepartmentName(widget.department);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ゲーム名と部門名
              Text(
                '箱庭小駅伝SS - $departmentName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              // 【追加機能】 メモ表示エリア
              if (widget.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    'メモ: ${widget.memo}',
                    style: const TextStyle(
                      fontSize: 16,
                      //fontWeight: FontWeight.bold,
                      // メモが目立つように緑色を設定
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ページング表示
              if (total > 1)
                Text(
                  '$current/$total', // 「1/4」のように表示
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              const SizedBox(height: 15),

              // QRコード本体
              QrImageView(
                data: currentQrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                // データ量が多い場合、少し大きめに表示するため、サイズを固定
              ),
              const SizedBox(height: 20),

              // ナビゲーションボタン
              if (total > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('前へ'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _currentIndex < total - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('次へ'),
                    ),
                  ],
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
