import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';

// ------------------------------------------------------------
// 名声の履歴(1.8.8)
//
// 全大学の名声の獲得を、名声と同じく過去10年分記録する。記録するのは、
// 駅伝(10月・11月・正月・カスタム)の総合順位と区間賞、正月駅伝の学連選抜の区間1位相当、
// 対校戦の総合と個人。名声を直接変えたとき(箱庭モードの名声の編集、QRコードの読み込み)は、
// 量0で「名声を編集」の行を足す。
// ・保存場所は、大学id 18〜27 の UnivData.name_tanshuku(短縮名は使っておらず、
//   id 0〜17 は設定やメモの置き場、18〜29 はどこからも読み書きされていないことを確かめた)。
//   id 18 が今年度、19 が1年前、…、27 が9年前(meisei_yeargoto[0]〜[9] と同じ並び)
// ・年度替わり(RetireNew で meisei_yeargoto をずらすところ)で、同じように1つずつずらす
// ・1行目は見出し(_midashi)、2行目からは1行1件で「大学id<TAB>量<TAB>内容」。
//   見出しのない文字列(初期値の「短縮」など)は、記録なしとみなす
// ・新規ゲーム開始時は消す。名声と育成力を維持したリセットのときは、名声と一緒に残す
// ・年度の初めに全大学に入る1など、ここに記録しない分は、表示のときに
//   その年の名声(meisei_yeargoto)との差として出す(Modal_meiseiRireki.dart)
// ------------------------------------------------------------

/// 名声の履歴を置く大学idの先頭(ここから名声の保存年数ぶん使う)
const int meiseiRirekiSlotHajime = 18;

/// 名声の履歴の見出し(この文字列で始まるものだけを履歴とみなす)
const String _midashi = '#名声の履歴';

/// 名声の履歴の1件
class MeiseiRirekiGyou {
  final int univid;
  final int ryou;
  final String naiyou;
  const MeiseiRirekiGyou(this.univid, this.ryou, this.naiyou);
}

/// [nenmae]年前(0が今年度)の履歴を置いている大学(見つからなければnull)
UnivData? _slot(int nenmae) {
  if (nenmae < 0 || nenmae >= TEISUU.MEISEIHOZONNENSUU) return null;
  final int id = meiseiRirekiSlotHajime + nenmae;
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == id) return u;
  }
  return null;
}

/// 今年度の名声の履歴に1件足して保存する
/// ([naiyou]のタブと改行は空白にする)
Future<void> meiseiRirekiTsuika(int univid, String naiyou, int ryou) async {
  final UnivData? s = _slot(0);
  if (s == null) return;
  String text = s.name_tanshuku;
  if (!text.startsWith(_midashi)) text = '$_midashi\n';
  final String bun = naiyou.replaceAll('\t', ' ').replaceAll('\n', ' ');
  text += '$univid\t$ryou\t$bun\n';
  s.name_tanshuku = text;
  await s.save();
}

/// 年度替わりに、名声の履歴を1年ずつずらし、今年度を空にする
/// (RetireNew で meisei_yeargoto をずらすところで呼ぶ)
Future<void> meiseiRirekiNenKawari() async {
  for (int nenmae = TEISUU.MEISEIHOZONNENSUU - 1; nenmae > 0; nenmae--) {
    final UnivData? ato = _slot(nenmae);
    final UnivData? mae = _slot(nenmae - 1);
    if (ato == null || mae == null) continue;
    ato.name_tanshuku = mae.name_tanshuku;
    await ato.save();
  }
  final UnivData? konnendo = _slot(0);
  if (konnendo != null) {
    konnendo.name_tanshuku = '$_midashi\n';
    await konnendo.save();
  }
}

/// 名声の履歴をすべて消す(新規ゲーム開始時)
Future<void> meiseiRirekiZenbuKesu() async {
  for (int nenmae = 0; nenmae < TEISUU.MEISEIHOZONNENSUU; nenmae++) {
    final UnivData? s = _slot(nenmae);
    if (s == null) continue;
    s.name_tanshuku = '$_midashi\n';
    await s.save();
  }
}

/// [nenmae]年前(0が今年度)の、大学[univid]の名声の履歴(記録した順)
List<MeiseiRirekiGyou> meiseiRirekiYomu(int nenmae, int univid) {
  final UnivData? s = _slot(nenmae);
  if (s == null || !s.name_tanshuku.startsWith(_midashi)) return [];
  final List<MeiseiRirekiGyou> list = [];
  for (final String gyou in s.name_tanshuku.split('\n').skip(1)) {
    final List<String> p = gyou.split('\t');
    if (p.length < 3) continue;
    final int? id = int.tryParse(p[0]);
    final int? ryou = int.tryParse(p[1]);
    if (id == null || ryou == null) continue;
    if (id != univid && id != -1) continue;
    list.add(MeiseiRirekiGyou(id, ryou, p.sublist(2).join(' ')));
  }
  return list;
}

/// 駅伝の名前(履歴の文に使う。カスタム駅伝は設定した名前)
String meiseiRirekiEkidenMei(int racebangou) {
  switch (racebangou) {
    case 0:
      return '10月駅伝';
    case 1:
      return '11月駅伝';
    case 2:
      return '正月駅伝';
    case 5:
      for (final UnivData u in Hive.box<UnivData>('univBox').values) {
        if (u.id == 0 && u.name_tanshuku.isNotEmpty) return u.name_tanshuku;
      }
      return 'カスタム駅伝';
    default:
      return '駅伝';
  }
}

/// 大学[univid]で、駅伝[racebangou]の区間[kukan]を走った選手の名前(見つからなければ空)
String meiseiRirekiKukanSenshuMei(
  List<SenshuData> senshu,
  int univid,
  int racebangou,
  int kukan,
) {
  for (final SenshuData s in senshu) {
    if (s.univid != univid || s.gakunen < 1 || s.gakunen > 4) continue;
    if (s.entrykukan_race.length <= racebangou) continue;
    if (s.entrykukan_race[racebangou][s.gakunen - 1] == kukan) return s.name;
  }
  return '';
}

/// 駅伝の総合順位で得た名声を履歴に足す
/// ([mae]は、その大学の総合順位の名声を足す前の今年度の名声。増えた分を記録する)
Future<void> meiseiRirekiSougou(UnivData univ, int racebangou, int mae) async {
  final int ryou = univ.meisei_yeargoto[0] - mae;
  if (ryou <= 0) return;
  final int juni = univ.juni_race[racebangou][0] + 1;
  final int mokuhyou = univ.mokuhyojuni[racebangou] + 1;
  await meiseiRirekiTsuika(
    univ.id,
    '${meiseiRirekiEkidenMei(racebangou)} 総合$juni位(目標$mokuhyou位)',
    ryou,
  );
}

/// 駅伝の区間賞で得た名声を履歴に足す
Future<void> meiseiRirekiKukanshou(
  UnivData univ,
  List<SenshuData> senshu,
  int racebangou,
  int kukan,
  int ryou,
) async {
  if (ryou <= 0) return;
  final String mei = meiseiRirekiKukanSenshuMei(
    senshu,
    univ.id,
    racebangou,
    kukan,
  );
  await meiseiRirekiTsuika(
    univ.id,
    '${meiseiRirekiEkidenMei(racebangou)} ${kukan + 1}区 区間賞${mei.isEmpty ? '' : '($mei)'}',
    ryou,
  );
}
