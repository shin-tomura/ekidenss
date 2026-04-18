// lib/settings_qr_page.dart

import 'package:flutter/material.dart';
import 'qr_data_model.dart';
import 'qr_processor.dart';
import 'qr_display_modal.dart';
//import 'qr_camera_scanner_modal.dart';
import 'qr_gallery_scanner_modal.dart';

class SettingsQrPage extends StatefulWidget {
  const SettingsQrPage({super.key});

  @override
  _SettingsQrPageState createState() => _SettingsQrPageState();
}

class _SettingsQrPageState extends State<SettingsQrPage> {
  // 選択された部門を保持
  SettingsDepartment _selectedDepartment = SettingsDepartment.generalSettings;

  // 受信中の複数枚のQRコードデータを保持する状態
  final QrReceiveState _receiveState = QrReceiveState();

  final Map<SettingsDepartment, String> _departmentNames = {
    SettingsDepartment.generalSettings: '各種設定',
    SettingsDepartment.octoberEkiden: '10月駅伝コース',
    SettingsDepartment.novemberEkiden: '11月駅伝コース',
    SettingsDepartment.shogatsuEkiden: '正月駅伝コース',
    SettingsDepartment.customEkiden: 'カスタム駅伝コース',
    SettingsDepartment.octoberTime: '10月タイム調整',
    SettingsDepartment.novemberTime: '11月タイム調整',
    SettingsDepartment.shogatsuTime: '正月タイム調整',
    SettingsDepartment.customTime: 'カスタムタイム調整',
  };

  // QRコード出力の前にメモ入力を促すモーダルを表示する関数
  Future<void> _showMemoInputModal() async {
    // ユーザーからの入力文字列を保持
    String inputMemo = '';

    final memo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // 背景と文字色をテーマに合わせる
          backgroundColor: Colors.grey[850],
          title: const Text(
            '出力データのメモ入力',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            maxLength: 30,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "例: 育成力MAX設定",
              hintStyle: TextStyle(color: Colors.grey),
              counterStyle: TextStyle(color: Colors.white70),
              // テキストフィールドの枠線色を調整
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.lightGreenAccent),
              ),
            ),
            onChanged: (value) {
              inputMemo = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // キャンセル
              },
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // 前後の空白を削除した文字列を返して続行
                Navigator.of(context).pop(inputMemo.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('QRコード表示'),
            ),
          ],
        );
      },
    );

    // memoがnullでない（キャンセルされなかった）場合のみ、QRコード画面へ進む
    if (memo != null) {
      // 出力前に、念のため受信状態をリセット
      _receiveState.reset();
      showDialog(
        context: context,
        builder: (context) => QrDisplayModal(
          department: _selectedDepartment,
          memo: memo, // 入力されたメモを渡す
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景を黒に設定
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('設定のQRコード入出力'),
        backgroundColor: Colors.black, // App Barの背景も黒に
        foregroundColor: Colors.white, // App Barの文字色を白に
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 部門選択ドロップダウン (スクロールさせない領域)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 8.0,
            ),
            child: _buildDepartmentDropdown(),
          ),
          // Dividerの色も白に変更
          const Divider(color: Colors.white70, height: 1),

          // 2. スクロール可能な領域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // QRコード出力ボタン
                  _buildExportButton(context),
                  const SizedBox(height: 20),

                  // QRコード入力ボタン（カメラ）
                  /*_buildImportButton(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'QRコードをカメラで読み込む',
                    onPressed: () => _showImportModal(
                      context,
                      QrCameraScannerModal(receiveState: _receiveState),
                    ),
                  ),
                  const SizedBox(height: 10),*/

                  // QRコード入力ボタン（ギャラリー）
                  _buildImportButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'QRコードを画像ギャラリーから読み込む',
                    onPressed: () => _showImportModal(
                      context,
                      QrGalleryScannerModal(receiveState: _receiveState),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 受信状態の表示
                  _buildReceiveStatusCard(),
                  const SizedBox(height: 30),

                  // 3. 説明書き領域 (スクロール領域の最下部)
                  _buildUserDescriptionArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 既存ウィジェット (色の設定は元のコードのまま維持) ---

  Widget _buildUserDescriptionArea() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blueGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 補足説明',
            style: TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          // ここにユーザーが自由に入力できる説明テキストを表示/編集する想定
          const Text(
            '複数枚のQRコードを読み込む際は、途中で中断しないようにご注意ください。\n\n'
            '駅伝コースのQRコードは、その駅伝の区間数・区間距離・登り具合・下り具合・アップダウン回数の情報を扱います。\n\n'
            '駅伝タイムのQRコードは、全体・区間ごとタイム調整のうち、その駅伝の各区間のタイム調整の情報を格納しています。\n\n'
            '各種設定のQRコードは、以下の内容を含みます。ただし、意図せず個人情報が含まれてしまう可能性を考慮し、大学名とカスタム駅伝名称については入出力されません。\n'
            '・実力発揮度設定\n'
            '・難易度「極」「天」設定\n'
            '・難易度(鬼、難しいなど)\n'
            '・難易度変更2(レベル0から9)\n'
            '・育成力\n'
            '・名声\n'
            '・入学時名声影響度設定\n'
            '・目標順位決め方設定\n'
            '・カスタム駅伝開催するしない\n'
            '・カスタム駅伝獲得名声倍率\n'
            '・駅伝名声設定\n'
            '・留学生受け入れ設定\n'
            '・学連選抜モチベーション設定\n'
            '・最適解区間配置確率設定\n'
            '・全体・区間ごとタイム調整のうちの全体のタイム調整\n'
            '・長距離タイム抑制設定\n'
            '・調子関連設定(コンピュータチームの体調不良発生スイッチは除く)\n'
            '・金銀支給量倍率設定\n'
            '・記録会時期設定\n'
            '・年間強化練習効果設定\n',

            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          // 必要に応じて、ここでTextFieldを配置して編集可能にすることも可能です
        ],
      ),
    );
  }

  // 部門選択ドロップダウンのウィジェット
  Widget _buildDepartmentDropdown() {
    return Row(
      children: [
        // 項目名の文字色を白に
        const Text('対象: ', style: TextStyle(fontSize: 16, color: Colors.white)),
        // ドロップダウンリストの項目名がはみ出さないように間隔調整
        const SizedBox(width: 8.0),
        Expanded(
          child: DropdownButton<SettingsDepartment>(
            value: _selectedDepartment,
            // ドロップダウン全体の背景色と文字色を設定
            dropdownColor: Colors.grey[850], // ドロップダウンのリストの背景
            style: const TextStyle(color: Colors.white), // 現在選択されている項目の文字色
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ), // アイコン色
            underline: Container(height: 1, color: Colors.white70), // 下線の色

            onChanged: (SettingsDepartment? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDepartment = newValue;
                });
              }
            },
            items: SettingsDepartment.values
                .map<DropdownMenuItem<SettingsDepartment>>((
                  SettingsDepartment department,
                ) {
                  return DropdownMenuItem<SettingsDepartment>(
                    value: department,
                    // ドロップダウンリストの文字色を明るい緑色に
                    child: Text(
                      _departmentNames[department] ?? '不明な対象',
                      style: const TextStyle(color: Colors.lightGreenAccent),
                    ),
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }

  // QRコード出力ボタンのウィジェット
  Widget _buildExportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await _showMemoInputModal();
      }, // メモ入力モーダルを表示する
      icon: const Icon(Icons.qr_code, color: Colors.white), // アイコンを白に
      label: Text(
        '「${_departmentNames[_selectedDepartment]}」を出力',
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
        ), // 文字を黒に（元のコードのまま）
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.blue, // 背景色はそのまま
        foregroundColor: Colors.white,
      ),
    );
  }

  // QRコード入力ボタンのウィジェット
  Widget _buildImportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white), // アイコンを白に
      label: Text(
        label,
        style: const TextStyle(color: Colors.black),
      ), // 文字を黒に（元のコードのまま）
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: const BorderSide(color: Colors.white), // 枠線を白に
        backgroundColor: Colors.green, // 背景色を緑に（元のコードのまま）
        foregroundColor: Colors.white,
      ),
    );
  }

  // 受信状態のカード
  Widget _buildReceiveStatusCard() {
    final int receivedCount = _receiveState.receivedParts.length;
    final bool isReceiving = receivedCount > 0;

    String statusMessage = '現在、読込待ちのデータはありません。';
    SettingsDepartment? currentDept;

    if (isReceiving) {
      try {
        // 現在受信中の部門を推定
        final firstKey = _receiveState.receivedParts.keys.first;
        final deptIndex = int.parse(firstKey.split('_')[0]);
        currentDept = SettingsDepartment.values[deptIndex];

        statusMessage =
            '「${_departmentNames[currentDept]}」のデータ読込中: '
            '$receivedCount枚読み込み済み';
      } catch (_) {
        statusMessage = 'データを読込中ですが、対象情報が読み取れません。';
      }
    }

    // Cardの背景色を調整
    return Card(
      color: isReceiving ? Colors.red[900] : Colors.grey[800], // 黒背景に合うよう濃い色に変更
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isReceiving ? '🚨 読込中断中' : '✅ 準備完了',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // 受信中断中は明るい赤、準備完了は明るい緑
                color: isReceiving
                    ? Colors.yellowAccent
                    : Colors.lightGreenAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: const TextStyle(color: Colors.white),
            ), // 白文字
            if (isReceiving)
              TextButton(
                onPressed: () {
                  // リセットする旨をユーザーに通知
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('読込中のデータをリセットしました。')),
                  );
                  setState(() {
                    _receiveState.reset();
                  });
                },
                child: const Text(
                  '読み込みを中止して読込データをリセット',
                  style: TextStyle(color: Colors.white), // 白文字
                ),
              ),
          ],
        ),
      ),
    );
  }

  // モーダル表示の共通ロジック
  void _showImportModal(BuildContext context, Widget modal) async {
    // 画面を閉じたら、受信状態が変化している可能性があるので更新
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => modal,
        fullscreenDialog: true, // 全画面モーダルとして表示
      ),
    );
    // 状態更新
    setState(() {});
  }
}
