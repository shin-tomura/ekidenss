import 'package:ekiden/kansuu/shiyou_text.dart';

// ------------------------------------------------------------
// 説明書タブの本文(1.8.4)
// ・仕様の部分は shiyou_text.dart の文を使う(生成AI向けの「ゲームの仕様」と共通)。
//   ここには、説明書だけの部分(はじめに・生成AIと遊ぶ・学内記録・プライバシーポリシーなど)と、
//   見出しのグループと並び、見出しの中に出す参考資料の図を書く。
// ・書き方の決まりはCLAUDE.md(1行に1つのことを「・」で始めて書く、など)。
//   「・」で始まらない行は、そのままの文として出す(はじめに・最後に・プライバシーポリシー)。
// ・表示(折りたたみ・検索)は lib/screens/setsumeisho_tab.dart。
// ------------------------------------------------------------

/// 説明書の見出し1つ分と、その中の最後に出す参考資料の図(説明書だけ)
class SetsumeishoKoumoku {
  const SetsumeishoKoumoku(
    this.setsu, {
    this.zuSetsumei = '',
    this.zu = const [],
  });
  final ShiyouSetsu setsu;

  /// 図の説明(図の上に出す)
  final String zuSetsumei;

  /// 図の画像のパス
  final List<String> zu;
}

/// 説明書のグループ(区切りの名前と、その中の見出し)
class SetsumeishoGroup {
  const SetsumeishoGroup(this.namae, this.koumoku);

  /// 区切りの名前。見出しが1つだけのグループは空にして、区切りの線だけを出す
  final String namae;
  final List<SetsumeishoKoumoku> koumoku;
}

/// 説明書タブに出すグループと見出しの並び
List<SetsumeishoGroup> setsumeishoGroupList() {
  return [
    const SetsumeishoGroup('', [SetsumeishoKoumoku(_hajimeni)]),
    SetsumeishoGroup('レースの決まり', [
      SetsumeishoKoumoku(shiyouTaikai(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouMokuhyou(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouSiji(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouIchiku(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouKeiken(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouGakuren(setsumeisho: true)),
    ]),
    SetsumeishoGroup('選手と能力', [
      SetsumeishoKoumoku(
        shiyouNouryoku(setsumeisho: true),
        zuSetsumei:
            '参考資料: ロード適性・ペース変動対応力と各競技との関係性(○はよく効く、△は少し効く)',
        zu: const ['lib/assets/gazou/nouryoku.png'],
      ),
      SetsumeishoKoumoku(shiyouMochiTime(setsumeisho: true)),
      SetsumeishoKoumoku(shiyouSuuchi(setsumeisho: true)),
    ]),
    SetsumeishoGroup('金銀と名声', [
      SetsumeishoKoumoku(shiyouKinGin(setsumeisho: true)),
      SetsumeishoKoumoku(
        shiyouMeisei(setsumeisho: true),
        zuSetsumei: '参考資料: 各大会での獲得名声初期値一覧(目標順位1位の場合)',
        zu: const [
          'lib/assets/gazou/meisei_10.png',
          'lib/assets/gazou/meisei_11.png',
          'lib/assets/gazou/meisei_01.png',
          'lib/assets/gazou/meisei_custom.png',
          'lib/assets/gazou/meisei_taikousen.png',
        ],
      ),
    ]),
    const SetsumeishoGroup('', [SetsumeishoKoumoku(_seiseiAI)]),
    const SetsumeishoGroup('その他', [
      SetsumeishoKoumoku(_gakunaiKiroku),
      SetsumeishoKoumoku(_kantokuCoach),
      SetsumeishoKoumoku(_pcBan),
      SetsumeishoKoumoku(_saigoni),
      SetsumeishoKoumoku(_privacy),
    ]),
  ];
}

const ShiyouSetsu _hajimeni = ShiyouSetsu('はじめに', [
  '箱庭小駅伝SSをダウンロードしていただき誠にありがとうございます。',
  'このゲームは文字情報だけの駅伝シミュレーションゲームです。',
  '総監督(あなた)ができることは、選手の区間配置とレース中の指示、新入生スカウト、練習メニューの選択、金特訓・銀特訓など、限られたことだけです。',
  '選手は基本的に勝手に成長します。',
  '肩の力を抜いて、ご自身のペースでお付き合いいただければ幸いです。',
  'なお、このゲームに登場する団体名・個人名は実在する団体・個人とは一切関係ありません。',
  '各種設定やデータのセーブ・ロード、コースの紹介・編集などは、画面の上の「設定」タブにあります。',
]);

const ShiyouSetsu _seiseiAI = ShiyouSetsu('生成AIと遊ぶ(テキストのコピー)', [
  '・各画面のコピーのボタンでテキストをコピーして生成AIに貼り付けると、レースの実況や、エントリー・区間配置・指示の相談を楽しめます。',
  '・コピーしたテキストには、生成AIが読み違えないように、数値の意味などの注意書きも入っています。',
  '・「生成AIに渡すテキスト」ボタンを押すと、その場面で役に立つテキストの一覧が出て、1回押すだけでコピーできます。',
  '・一覧のそれぞれの中身は、一覧の説明をご覧ください。',
  '・このボタンは、一次エントリー・学連選抜編成・区間エントリー・当日変更・目標順位の決定・レース中・レース結果の画面にあります。',
  '・会話の最初に「ゲームの仕様(生成AI向け)」を一度渡しておくと、能力の名前だけから推測した誤った判断が減り、相談の精度が上がります。',
  '　・どの場面の一覧にもあります。中身は、この説明書の「レースの決まり」「選手と能力」「金銀と名声」とほぼ同じです。',
  '・場面ごとのおすすめは次のとおりです。',
  '　・エントリー・区間配置の相談: エントリーの画面の「相談セット」(学連選抜の監督をするときは「学連選抜の相談セット」)',
  '　・当日変更の相談: 当日変更の画面の「当日変更相談セット」',
  '　・目標順位の相談: 目標順位を決める画面の「目標順位相談セット」',
  '　・レース前の展開予想: レース画面(スタート前)の「レース前セット」',
  '　・レース中の実況: 区間ごとの「直近区間結果セット」や「自分の大学のレース経過」(最後の区間の分は、レース結果の画面から)',
  '　・次の区間の展開予想: 区間ごとの「次区間予想セット」',
  '　・指示の相談: 「自分の大学のレース経過」と「全区間・全大学詳細リスト」',
  '　・レース後の振り返り: レース結果の画面の「振り返りセット」や「全区間の個人成績」(正月駅伝では「学連選抜の振り返りセット」も)',
  '・エントリーの画面では、ほかの大学の区間エントリーが分かってしまうもの(全区間・全大学詳細リストなど)は出ません。',
  '・今季タイム一覧表と駅伝出場履歴一覧(選手ごと)は、それぞれの画面の右上のコピーのボタンでもコピーできます。',
  '・学連選抜区間配置の画面などからは、学連選抜の区間配置・レース経過・今季タイム一覧表もコピーできます。',
  '・正月駅伝の個人順位速報・通過順位速報には、学連選抜も「OP」として入ります(順位は大学の中に入れた場合の「○位相当」)。',
  '・「全区間の個人成績」が長すぎるときは、区間を選んで1つずつコピーできます。',
  '・生成AIによっては、一度に貼り付けられる文字数に限りがあります。長すぎるときは、まとめたものではなく1つずつ渡してください。',
]);

const ShiyouSetsu _gakunaiKiroku = ShiyouSetsu('学内記録・学内順位', [
  '・学内記録と学内順位は、処理を軽くするため、あなたが総監督をしている大学だけ計算・記録しています。',
  '・別の大学の総監督になった場合は、移った大学の学内記録・学内順位を、就任したときから記録し始めます。',
]);

const ShiyouSetsu _kantokuCoach = ShiyouSetsu('監督とコーチ', [
  '・監督とコーチは、ゲーム内の計算には一切影響しません。',
  '・OBが就任します。30歳以上でないと就任しないので、最初の10年くらいは不在が続きます。',
  '・はじめのうちは、若い監督・コーチばかりになります。',
]);

const ShiyouSetsu _pcBan = ShiyouSetsu('PC版(箱庭小駅伝・箱庭小駅伝2)のプレイ経験のある方へ', [
  '・似ている部分もありますが、異なる部分もあります。全く別のゲームだと思って遊んでいただいた方が、混乱しないかもしれません。',
  '・天候や疲労・怪我はありません。',
  '・距離適性は自動で合わせるので、ゲーム中に意識する必要はありません。',
  '・チームの目標順位をクリアすると、ポイントのようなもの(金銀)を獲得でき、そのポイントで選手の能力を上げられます。',
  '・初期状態では選手の能力は見えず、タイムから推測するしかありません。',
  '・駅伝の経験補正は、同じ駅伝の同じ区間を走ったことがある場合だけです。',
  '・2までは100m単位で計算していたので、区間の途中の集団走もあり、そのペースをカリスマが一番高い選手が決めていました。',
  '・今作は1区間まるごとを1つの計算で行うので、カリスマが影響するのは、駅伝の1区と11月駅伝予選の全組だけです。',
]);

const ShiyouSetsu _saigoni = ShiyouSetsu('最後に', [
  '攻略法がどうのこうのというより、ただの運ゲーかもしれません。',
  '電車での移動時間などのちょっとした暇つぶしにでもなれば幸いです。',
]);

// プライバシーポリシー(文はそのまま。空の行は段落の区切り)
const ShiyouSetsu _privacy = ShiyouSetsu('プライバシーポリシー', [
  '1. 利用者情報の取り扱いについて',
  '情報の取得・利用: 当アプリは、ユーザーの氏名、連絡先、位置情報などの個人情報を取得・利用することはありません。',
  '',
  '第三者への提供: 当アプリが、ユーザーの許可なく情報を第三者に提供することはありません。',
  '',
  '2. カメラおよび写真へのアクセスについて',
  'カメラ機能: QRコードを読み取るために、ユーザーの許可を得てカメラ機能を使用します。',
  '',
  '写真ライブラリ: 画像ファイルからQRコードを読み取るために、ユーザーの許可を得て端末内の写真へのアクセスを行います。',
  '',
  '取得データの扱い: 読み取った画像およびデータは、QRコードの解析処理にのみ使用され、アプリ外部のサーバーへ送信・保存されることはありません。',
  '',
  '3. データの共有（CSV/画像出力）機能について',
  '外部出力: ユーザー自身の操作により、選手データ等をCSV/画像ファイルとして書き出し、外部（メール、SNS、ストレージサービス等）へ共有する機能を提供しています。',
  '',
  '一時ファイルの保存: CSV/画像作成時、共有のために端末内の一時フォルダにファイルを保存しますが、このファイルは共有処理以外の目的で使用されることはありません。',
  '',
  '共有先管理: データの送信先（共有先）はユーザー自身が選択・管理するものとし、アプリが自動的に情報を外部送信することはありません。',
]);
