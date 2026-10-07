import 'package:ekiden/senshu_data.dart';

// ------------------------------------------------------------
// プレイヤーの大学の夏合宿の銀特訓(練習メニュー。1.9.1)
//
// ・1.9.0までは能力を直接選んで+10していたが、コンピュータの大学の銀の使い道
//   (goldsilver_com.dart)と同じように、練習メニューを選ぶ形にした
// ・メニューを1回選ぶごとに銀10を使い、メニューに対応する能力が1つ+10上がる
//     スピード練習: スパート力・ペース変動対応力
//     距離走: 長距離粘り・ロード適性
//     登り練習: 登り適性、下り練習: 下り適性、アップダウン練習: アップダウン対応力
//     リーダーシップ研修: カリスマ(コンピュータの大学は上げないが、プレイヤーは今まで通り上げられる)
// ・能力が2つあるメニューは、年度と選手で決まる「重点」の能力から上げ、上限ならもう一方を上げる
//   (コンピュータの大学と同じく、夏合宿ごと・選手ごとに重点が決まる。
//    年度と選手の番号から計算するので、保存する値はなく、合宿の途中でアプリを閉じても変わらない)
// ・上げられるのは能力値が89以下のとき(カリスマは99以下。1.9.0までと同じ)
// ・能力の番号は Ghensuu.nouryokumieruflag と同じ
//     2長距離粘り 3スパート力 4カリスマ 5登り適性 6下り適性 7アップダウン対応力
//     8ロード適性 9ペース変動対応力
// ------------------------------------------------------------

/// 銀特訓の形の切り替え(1.9.1。ここを書き換えてビルドし直すだけで切り替わる)
///   true: 練習メニューを選ぶ形(1.9.1から)
///   false: 1.9.0までの、能力を直接選んで「10up」を押す形
/// 画面(senshu_screen.dart の ModalTokkunSilver)と説明書(shiyou_text.dart の銀特訓の行)が
/// この値で書き分ける。切り替えたときは、変更履歴(ToDo.txt)だけ書き足す。
/// コンピュータの大学の銀の使い方(goldsilver_com.dart)は、この値と関係ない
/// (1.9.1の開発中に練習メニューの形を試したが、能力の値で考えるヘビーユーザーには、
///  スピード練習・距離走で上げる能力を選べないのが不便なので、リリース前に false に戻した)
const bool ginTokkunMenuShiki = false;

/// 能力を直接選ぶ形(ginTokkunMenuShiki が false のとき)で並べる能力の番号(1.9.0までと同じ並び)
const List<int> ginTokkunChokusetsuNouryoku = [2, 3, 4, 5, 6, 7, 8, 9];

/// 銀特訓のメニュー1つ分
class GinTokkunMenu {
  final String mei; // メニューの名前
  final List<int> nouryoku; // 上がる能力の番号(2つのときは[1つ目, 2つ目])
  const GinTokkunMenu(this.mei, this.nouryoku);
}

/// 銀特訓のメニュー(並び順がメニューの番号)
const List<GinTokkunMenu> ginTokkunMenuList = [
  GinTokkunMenu('スピード練習', [3, 9]),
  GinTokkunMenu('距離走', [2, 8]),
  GinTokkunMenu('登り練習', [5]),
  GinTokkunMenu('下り練習', [6]),
  GinTokkunMenu('アップダウン練習', [7]),
  GinTokkunMenu('リーダーシップ研修', [4]),
];

/// 能力の名前(番号はnouryokumieruflagと同じ)
String ginTokkunNouryokuMei(int bangou) {
  switch (bangou) {
    case 2:
      return '長距離粘り';
    case 3:
      return 'スパート力';
    case 4:
      return 'カリスマ';
    case 5:
      return '登り適性';
    case 6:
      return '下り適性';
    case 7:
      return 'アップダウン対応力';
    case 8:
      return 'ロード適性';
    case 9:
      return 'ペース変動対応力';
    default:
      return '';
  }
}

/// 能力の値
int ginTokkunNouryokuAtai(SenshuData s, int bangou) {
  switch (bangou) {
    case 2:
      return s.choukyorinebari;
    case 3:
      return s.spurtryoku;
    case 4:
      return s.karisuma;
    case 5:
      return s.noboritekisei;
    case 6:
      return s.kudaritekisei;
    case 7:
      return s.noborikudarikirikaenouryoku;
    case 8:
      return s.tandokusou;
    case 9:
      return s.paceagesagetaiouryoku;
    default:
      return 0;
  }
}

/// 能力に+10する(上限の確認は呼び出し側で行う)
void ginTokkunNouryokuAgeru(SenshuData s, int bangou) {
  switch (bangou) {
    case 2:
      s.choukyorinebari += 10;
      break;
    case 3:
      s.spurtryoku += 10;
      break;
    case 4:
      s.karisuma += 10;
      break;
    case 5:
      s.noboritekisei += 10;
      break;
    case 6:
      s.kudaritekisei += 10;
      break;
    case 7:
      s.noborikudarikirikaenouryoku += 10;
      break;
    case 8:
      s.tandokusou += 10;
      break;
    case 9:
      s.paceagesagetaiouryoku += 10;
      break;
  }
}

/// 能力をまだ上げられるか(89以下。カリスマは99以下)
bool ginTokkunAgerareru(SenshuData s, int bangou) {
  final int jougen = (bangou == 4) ? 99 : 89;
  return ginTokkunNouryokuAtai(s, bangou) <= jougen;
}

/// メニューを選べるか(メニューの能力のどれかを上げられるか)
bool ginTokkunMenuEraberu(SenshuData s, int menuBangou) {
  if (menuBangou < 0 || menuBangou >= ginTokkunMenuList.length) return false;
  return ginTokkunMenuList[menuBangou].nouryoku.any(
    (bangou) => ginTokkunAgerareru(s, bangou),
  );
}

/// 重点を決めるためのハッシュ(年度・選手・メニューで決まる)
int _juutenHash(int nen, int senshuId, int menuBangou) {
  int h =
      (nen * 73856093) ^
      (senshuId * 19349663) ^
      (menuBangou * 83492791) ^
      0x1b873593;
  h &= 0x7fffffff;
  h = ((h ^ (h >> 15)) * 0x2c1b3c6d) & 0x7fffffff;
  h = ((h ^ (h >> 12)) * 0x297a2d39) & 0x7fffffff;
  h ^= h >> 15;
  return h;
}

/// メニューの能力を上げる順番(能力が2つのときは、この年度の重点を先にする)
List<int> _ageruJunban(SenshuData s, int menuBangou, int nen) {
  final List<int> nouryoku = ginTokkunMenuList[menuBangou].nouryoku;
  if (nouryoku.length < 2) return nouryoku;
  final bool nibanJuuten = _juutenHash(nen, s.id, menuBangou) % 2 == 1;
  return nibanJuuten ? [nouryoku[1], nouryoku[0]] : [nouryoku[0], nouryoku[1]];
}

/// 銀特訓を1回する(能力を1つ+10する。銀は呼び出し側で減らす)
/// 上げた能力の番号を返す。メニューの能力がすべて上限なら何もせずにnull
int? ginTokkunSuru(SenshuData s, int menuBangou, int nen) {
  if (!ginTokkunMenuEraberu(s, menuBangou)) return null;
  for (final int bangou in _ageruJunban(s, menuBangou, nen)) {
    if (ginTokkunAgerareru(s, bangou)) {
      ginTokkunNouryokuAgeru(s, bangou);
      return bangou;
    }
  }
  return null;
}
