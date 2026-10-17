// lib/settings_qr_page.dart

import 'package:flutter/material.dart';
import 'qr_data_model.dart';
import 'qr_processor.dart';
import 'qr_display_modal.dart';
//import 'qr_camera_scanner_modal.dart';
import 'qr_gallery_scanner_modal.dart';
import 'package:ekiden/kansuu/reset_ichiran.dart'
    show ResetKoumoku, ResetQr, resetIchiran, resetMidashiJun; // 内容の一覧(2.0.3)
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku; // リセット・ロード・QRで残るもの・変わるもの(2.0.3)

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

  /// QRコードで入出力する設定の一覧の文(2.0.3)
  /// reset_ichiran.dart の一覧の、QRの値・一部QRの値の行を、見出しの順に並べる(補足があれば次の行に添える)
  String _qrNaiyouIchiran() {
    final List<ResetKoumoku> ichiran = resetIchiran();
    final StringBuffer b = StringBuffer();
    for (final String midashi in resetMidashiJun) {
      for (final ResetKoumoku k in ichiran) {
        if (k.midashi != midashi || k.qr == ResetQr.imanomama) continue;
        b.write('・${k.mei}\n');
        if (k.qrHosoku.isNotEmpty) b.write('　${k.qrHosoku}\n');
      }
    }
    return b.toString().trimRight();
  }

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
            'QRコードで入出力するのは、以下の設定です。駅伝コースと区間ごとのタイム調整は駅伝ごとのQRコードで、そのほかは各種設定のQRコードで入出力します。'
            'ただし、意図せず個人情報が含まれてしまう可能性を考慮し、大学名とカスタム駅伝名称については入出力されません。',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          // 内容の一覧は、lib/kansuu/reset_ichiran.dart の一覧の QR の印から作る(2.0.3。2.0.2までは手書きのリスト)。
          // 印は説明用で、QRコードの中身は qr_processor.dart で決まる。QRコードに項目を足したら、印も合わせる
          Text(
            _qrNaiyouIchiran(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          // リセット・ロード・QRで残るもの・変わるものの一覧表(reset_ichiran_gamen.dart)
          TextButton(
            onPressed: () => resetIchiranGamenHiraku(context),
            child: const Text(
              'リセット・ロード・QRで残るもの・変わるもの',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 255, 0),
                decoration: TextDecoration.underline,
                decorationColor: Color.fromARGB(255, 0, 255, 0),
              ),
            ),
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
