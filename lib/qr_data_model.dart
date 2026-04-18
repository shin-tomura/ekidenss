// lib/qr_data_model.dart

import 'dart:convert';

// 部門を識別するためのEnum
enum SettingsDepartment {
  generalSettings, // 各種設定部門
  octoberEkiden, // 10月駅伝コース部門
  novemberEkiden, // 11月駅伝コース部門
  shogatsuEkiden, // 正月駅伝コース部門
  customEkiden, // カスタム駅伝コース部門
  octoberTime, // 10月駅伝タイム部門
  novemberTime, // 11月駅伝タイム部門
  shogatsuTime, // 正月駅伝タイム部門
  customTime, // カスタム駅伝タイム部門
}

// 複数のQRコードに分割する際の共通ヘッダー
class QrHeader {
  final SettingsDepartment department;
  final int totalParts;
  final int currentPart; // 0-indexed

  QrHeader({
    required this.department,
    required this.totalParts,
    required this.currentPart,
  });

  Map<String, dynamic> toJson() => {
    // 'dept': 部門のインデックス (0-4)
    'd': department.index,
    // 'total': 全パーツ数
    't': totalParts,
    // 'part': 現在のパーツインデックス
    'p': currentPart,
  };

  factory QrHeader.fromJson(Map<String, dynamic> json) => QrHeader(
    department: SettingsDepartment.values[json['d'] as int],
    totalParts: json['t'] as int,
    currentPart: json['p'] as int,
  );
}

// QRコードのペイロード全体
class QrPayload {
  final QrHeader header;
  final String data; // Base64エンコードされた設定データの一部

  QrPayload({required this.header, required this.data});

  Map<String, dynamic> toJson() => {
    // 'h': ヘッダー情報
    'h': header.toJson(),
    // 'data': Base64エンコードされたデータ
    'data': data,
  };

  factory QrPayload.fromJson(Map<String, dynamic> json) => QrPayload(
    header: QrHeader.fromJson(json['h'] as Map<String, dynamic>),
    data: json['data'] as String,
  );

  // QRコードに格納する最終的な文字列
  String toQrString() => jsonEncode(toJson());

  factory QrPayload.fromQrString(String qrString) {
    final Map<String, dynamic> json = jsonDecode(qrString);
    return QrPayload.fromJson(json);
  }
}
