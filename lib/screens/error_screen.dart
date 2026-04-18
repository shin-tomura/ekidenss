import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              // ここを追加
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'エラーが発生しました',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'アプリの起動中に予期せぬエラーが発生しました。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'お手数ですが、以下の手順でアプリを再起動してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. ホーム画面に戻り、タスクマネージャー（最近使ったアプリ）を開きます。\n'
                    '2. このアプリを上にスワイプして閉じます。\n'
                    '3. もう一度アプリのアイコンをタップして起動してください。',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '上記を試しても正常に起動できない場合は、申し訳ありませんが、再インストールをお願いします。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Androidで再インストールをしてもこの画面が表示されてしまう場合は、以下をお試しいただけませんでしょうか？',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '再インストールしても起動できない場合\n'
                    'データが完全には削除できていないのが原因と思われますので、お手数をおかけしますが、以下をお試しください。\n\n'
                    '設定→アプリ→アプリ情報→箱庭小駅伝S→ストレージとキャッシュからデータとキャッシュの削除\n\n'
                    'その後にアンインストール、再インストールをお願いいたします。',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ), // ここを追加
          ),
        ),
      ),
    );
  }
}
