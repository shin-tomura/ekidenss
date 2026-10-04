import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/jibun_keika_text.dart';
import 'package:ekiden/kansuu/rireki_text.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_kukanresult350.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
// 結果画面の「個人順位タイム表示」の文(ViewModeの名前が個人順位速報と同じなので、名前を付けて読み込む)
import 'package:ekiden/screens/Modal_kukanresult.dart' as kekka;
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/shiyou_text.dart'; // ゲームの仕様(1.8.3)
import 'package:ekiden/kansuu/mokuhyou_kingin.dart'; // 目標達成時の金銀(1.8.3)

// ------------------------------------------------------------
// 生成AIに渡すテキストのまとめボタン(1.8.2)
// 押すと、その場面で生成AIに渡すと便利なテキストの一覧が出て、
// 1回押すだけでコピーできる。いつもいっしょに渡すものはセットでコピーできる。
// ・レース前セット: コース情報+全区間・全大学詳細リスト(展開予想に)
// ・直近区間結果セット: 直近の区間の個人順位速報(説明文つき)+通過順位速報(実況に)
//   (1.8.2では「区間ごとセット」という名前だった。1.8.3で次区間予想セットと区別しやすい名前にした。
//    最後の区間の分は結果画面の一番上に出す。1.8.3)
// ・次区間予想セット: 直近の通過順位速報+次の区間のコース情報+次の区間の全大学詳細リスト
//   (次の区間の展開予想や指示の相談に。1区のスタート前は通過順位速報なし。1.8.3)
// ・直近区間結果セットと次区間予想セットの先頭には、レースの名前と何区か(最終区間か)の見出しを付ける(1.8.3)
// ・振り返りセット: 総合成績+自分の大学のレース経過(結果画面で、レース後の振り返りに)
// ・学連選抜の振り返りセット: 総合成績+学連選抜のレース経過+学連選抜の区間配置(結果画面で)
// ・相談セット: エントリーの状況+コース情報+自分の大学の今季タイム一覧表+駅伝出場履歴
//   (エントリーの画面で。駅伝予選では、先頭に「この大会の決まり」(経験補正がないこと、
//    11月駅伝予選の組と集団走、正月駅伝予選のフリー走と集団走)を入れる。1.8.4)
// ・学連選抜の相談セット: コース情報+学連選抜の区間配置+今季タイム一覧表+駅伝出場履歴
//   (学連選抜編成・区間エントリーの画面で)
// ・目標順位相談セット: 選べる目標順位と目標順位ごとの金銀+目標順位と指示の仕様+コースや全大学詳細リストなど
//   (目標順位を決める画面で、一番上に出す。1.8.3)
// ・ゲームの仕様(生成AI向け): どの場面でも一番上に出す(結果画面の直近区間結果セットと、
//   目標順位相談セットだけは、その上。1.8.3)
// 結果画面では、個人成績を区間を選んで1つずつコピーすることもできる
// 文はそれぞれの画面のコピーと同じもの(画面の外に出した関数で作る)
// ------------------------------------------------------------

// コピーできるもの1つ分
class _AiCopyKoumoku {
  final String title;
  final String setsumei;
  final IconData icon;
  final String Function()? tsukuru; // コピーする文を作る
  // 区間を選んでコピーするもの(区間の番号(0が1区)から文を作る)
  final String Function(int)? kukanTsukuru;
  final int kukanKazu; // 選べる区間の数
  final String kukanTani; // 区間の呼び方(「区」か「組」)
  const _AiCopyKoumoku(this.title, this.setsumei, this.icon, this.tsukuru)
    : kukanTsukuru = null,
      kukanKazu = 0,
      kukanTani = '区';
  const _AiCopyKoumoku.kukanSentaku(
    this.title,
    this.setsumei,
    this.icon,
    this.kukanTsukuru,
    this.kukanKazu,
    this.kukanTani,
  ) : tsukuru = null;
}

// セットでコピーするときの区切り
const String _setKugiri = '\n\n==============================\n\n';

// 直近区間結果セット・次区間予想セットの先頭に付ける見出し(1.8.3)
// 速報の文にはレースの名前や全部で何区かが入っていないので、生成AIがレースのどこなのか
// (最終区間かどうか)を分かるように、セットの先頭に付ける
// 例: 【正月駅伝 5区(全10区) 直近区間結果】
//     【正月駅伝 10区(最終区間・全10区) 直近区間結果】
//     ※この区間でゴール。通過順位がそのまま最終順位です(シード権は10位まで)
// [kukan] 区間の番号(0が1区)、[shurui] セットの種類(「直近区間結果」「次区間予想」)
// [goalBun] trueなら、最終区間のときにゴールしたことの一文を付ける(直近区間結果セットで使う)
String _setMidashi(
  Ghensuu gh,
  int race,
  int kukan,
  String shurui, {
  bool goalBun = false,
}) {
  final int kukansuu = gh.kukansuu_taikaigoto[race];
  final bool kumi = race == 3; // 11月駅伝予選は「組」
  final String tani = kumi ? '組' : '区';
  final bool saigo = kukan == kukansuu - 1;
  final String ichi = saigo
      ? '最終${kumi ? '組' : '区間'}・全$kukansuu$tani'
      : '全$kukansuu$tani';
  String midashi =
      '【${courseRaceTitle(race)} ${kukan + 1}$tani($ichi) $shurui】';
  if (goalBun && saigo) {
    // シード権(11月駅伝は8位まで、正月駅伝は10位まで。KirokuKousin.dartと同じ)
    String seed = '';
    if (race == 1) seed = '(シード権は8位まで)';
    if (race == 2) seed = '(シード権は10位まで)';
    midashi += kumi
        ? '\n※この組でレースが終了。通過順位がそのまま最終順位です'
        : '\n※この区間でゴール。通過順位がそのまま最終順位です$seed';
  }
  return midashi;
}

// 目標順位相談セットの文(目標順位を決める画面で使う。1.8.3)
// スタート前: 見出し(選べる目標順位・目標順位ごとの金銀)+目標順位と指示の仕様+コース情報+全区間・全大学詳細リスト
// 正月駅伝の復路のスタート前: 見出し+目標順位と指示の仕様+自分の大学のレース経過+直近の通過順位速報
//   +残りの区間のコース情報と全大学詳細リスト
String _mokuhyouSoudanSet(Ghensuu gh, int race, bool shutsujou) {
  final int kukansuu = gh.kukansuu_taikaigoto[race];
  final int jikai = gh.nowracecalckukan;
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');

  // 見出し
  final StringBuffer sb = StringBuffer();
  if (jikai > 0) {
    int? juni;
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == gh.MYunivid && u.tuukajuni_taikai.length >= jikai) {
        juni = u.tuukajuni_taikai[jikai - 1];
      }
    }
    sb.writeln(
      '【${courseRaceTitle(race)} 目標順位の相談(${jikai + 1}区のスタート前・$jikai区終了時点${juni == null ? '' : 'で${juni + 1}位'})】',
    );
    if (race == 2 && jikai == 5) {
      sb.writeln('・ここで決め直した目標順位は、7区から効く(6区は判定しない)。');
    }
  } else {
    sb.writeln('【${courseRaceTitle(race)} 目標順位の相談(スタート前)】');
  }
  final int saikai = mokuhyouSentakuSaikai(race);
  String seed = '';
  if (race == 1) seed = '(シード権は8位まで)';
  if (race == 2) seed = '(シード権は10位まで)';
  sb.writeln('・選べる目標順位: 1位〜$saikai位$seed');
  if (kantoku != null) {
    final List<int> kingin = [
      for (int t = 0; t < saikai; t++) mokuhyouKakutokuKingin(gh, kantoku, t),
    ];
    if (kingin.every((k) => k == 0)) {
      sb.writeln('・このデータでは、目標順位を達成しても金銀はもらえない。');
    } else {
      sb.writeln('・目標順位を達成したときにもらえる金銀の量(目標順位ごと):');
      sb.writeln(
        '  ${[for (int t = 0; t < saikai; t++) '${t + 1}位:${kingin[t]}'].join('、')}',
      );
    }
  }

  final List<String> bun = [sb.toString(), shiyouMokuhyouSijiText()];
  if (jikai <= 0) {
    bun.add(courseZenKukanText(gh, race));
    bun.add(zenKukanZenDaigakuText());
  } else {
    if (shutsujou) bun.add(jibunRaceKeikaText(gh));
    bun.add(tuukaJuniSokuhouText(gh, jikai - 1));
    bun.add(
      [
        for (int k = jikai; k < kukansuu; k++) courseKukanText(gh, race, k),
      ].where((t) => t.isNotEmpty).join('\n'),
    );
    for (int k = jikai; k < kukansuu; k++) {
      bun.add(kukanZenDaigakuText(k));
    }
  }
  return bun.where((t) => t.trim().isNotEmpty).join(_setKugiri);
}

// 当日変更相談セットの文(当日変更の画面で使う。1.8.3)
// 見出しとこの場面の当日変更のルール+自分の大学のエントリーの状況(当日の調子つき)
// +(正月駅伝の復路の前は)自分の大学のレース経過と5区の通過順位速報
// +変えられる区間のコース情報+自分の大学の今季タイム一覧表+駅伝出場履歴
// 当日変更のルールは、当日変更の画面(Toujituhenkou.dart・ToujitsuAhenkou.dart・ToujitsuBhenkou.dart)と同じ
String _toujitsuSoudanSet(Ghensuu gh, int race) {
  final int kukansuu = gh.kukansuu_taikaigoto[race];
  final int jikai = gh.nowracecalckukan;
  final bool shougatsu = race == 2;
  // 変えられる区間(正月駅伝は、往路の前は1〜5区、復路の前は6〜10区)
  int kara = 0;
  int made = kukansuu - 1;
  String jiten = 'スタート前';
  if (shougatsu) {
    if (jikai >= 5) {
      kara = 5;
      jiten = '復路のスタート前・5区終了時点';
    } else {
      made = kukansuu < 5 ? kukansuu - 1 : 4;
      jiten = '往路のスタート前';
    }
  }
  // 今の補欠の人数(区間の値が-1の選手)
  int hoketsuSuu = 0;
  for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
    if (s.univid != gh.MYunivid || s.gakunen < 1) continue;
    if (s.entrykukan_race.length <= race ||
        s.entrykukan_race[race].length < s.gakunen) {
      continue;
    }
    if (s.entrykukan_race[race][s.gakunen - 1] == -1) hoketsuSuu++;
  }
  // 入れ替えられる最大人数(当日変更の画面と同じ決まり)
  int saidai;
  if (shougatsu) {
    saidai = 4;
  } else {
    saidai = kukansuu <= 6 ? 2 : (kukansuu <= 8 ? 3 : 6);
    if (saidai > hoketsuSuu) saidai = hoketsuSuu;
  }

  final StringBuffer sb = StringBuffer();
  sb.writeln('【${courseRaceTitle(race)} 当日変更の相談($jiten)】');
  sb.writeln(
    '・入れ替えられるのは、${kara + 1}〜${made + 1}区を走る予定の選手と補欠の間だけ。補欠を区間に入れると、その区間を走る予定だった選手が外れる'
    '(区間を走る予定の選手どうしの入れ替えや、区間の並べ替えはできない)。',
  );
  sb.writeln('・入れ替えられるのは最大$saidai人まで(今の補欠は$hoketsuSuu人)。');
  if (shougatsu && jikai < 5) {
    sb.writeln('・外れた選手は、この大会ではもう走れない(復路にも出られない)。往路で使わなかった補欠は、復路のスタート前の当日変更でも使える(復路も最大4人)。');
  } else {
    sb.writeln('・外れた選手は、この大会ではもう走れない。');
  }
  sb.writeln(
    '・このあと、コンピュータの大学も当日変更をする(主力を補欠に温存し、当日変更で起用する「戦略的エントリー」もある)。'
    'そのため、ほかの大学の区間配置は変わることがある。',
  );
  sb.writeln(
    '・調子は当日の値(100が最高、0は体調不良)。経験補正は、同じ駅伝の同じ区間を前の学年までに走った回数で決まる(駅伝出場履歴で分かる)。',
  );

  final List<String> bun = [
    sb.toString(),
    entryJoukyouText(gh, univId: gh.MYunivid, toujitsu: true),
  ];
  if (jikai > 0) {
    bun.add(jibunRaceKeikaText(gh));
    bun.add(tuukaJuniSokuhouText(gh, jikai - 1));
  }
  bun.add(
    [
      for (int k = kara; k <= made; k++) courseKukanText(gh, race, k),
    ].where((t) => t.isNotEmpty).join('\n'),
  );
  bun.add(konkiSeisekiHyouText(univId: gh.MYunivid));
  bun.add(ekidenRirekiText(univId: gh.MYunivid));
  return bun.where((t) => t.trim().isNotEmpty).join(_setKugiri);
}

/// 生成AIに渡すテキストのまとめボタン
/// [entryAri] 区間エントリーが済んでいる場面か(一次エントリー・学連選抜編成・区間エントリーの
///   画面ではfalse。falseのときは、ほかの大学の区間エントリーが分かってしまう全区間・全大学詳細リストと
///   レース前セット、レース経過を出さず、代わりに相談セットを出す)
/// [kekkaGamen] レースの結果画面か(trueのときは、レース中の速報の代わりに
///   振り返りセット・総合成績・全区間の個人成績を出す。文は結果画面のコピーと同じ)
/// [mokuhyouGamen] 目標順位を決める画面か(trueのときは、一番上に目標順位相談セットを出す。1.8.3)
/// [toujitsuGamen] 当日変更の画面か(trueのときは、一番上に当日変更相談セットを出す。1.8.3)
class AiCopyMatomeButton extends StatelessWidget {
  final bool entryAri;
  final bool kekkaGamen;
  final bool mokuhyouGamen;
  final bool toujitsuGamen;
  const AiCopyMatomeButton({
    super.key,
    this.entryAri = true,
    this.kekkaGamen = false,
    this.mokuhyouGamen = false,
    this.toujitsuGamen = false,
  });

  // 今の場面でコピーできるものの一覧
  List<_AiCopyKoumoku> _koumokuList(Ghensuu gh) {
    final int race = gh.hyojiracebangou;
    final bool ekiden = race >= 0 && race <= 5; // 駅伝と駅伝予選
    UnivData? my;
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == gh.MYunivid) my = u;
    }
    final bool shutsujou =
        my != null &&
        my.taikaientryflag.length > race &&
        my.taikaientryflag[race] == 1;
    final bool gakuren = race == 2 && gakurenKonnenAri(gh);
    // 直近の区間(レース中で、1区以上走り終えているとき)
    final int kukansuu = ekiden ? gh.kukansuu_taikaigoto[race] : 0;
    final int chokkin = gh.nowracecalckukan > kukansuu
        ? kukansuu - 1
        : gh.nowracecalckukan - 1;
    final bool sokuhouAri = ekiden && entryAri && chokkin >= 0 && !kekkaGamen;
    final String kukanMei = race == 3 ? '${chokkin + 1}組' : '${chokkin + 1}区';
    // これから走る次の区間(1区のスタート前から最後の区間のスタート前まで。
    // 全員が一斉に走る正月駅伝予選では出さない。1.8.3)
    final int jikai = gh.nowracecalckukan;
    final bool jikaiAri =
        ekiden &&
        entryAri &&
        !kekkaGamen &&
        race != 4 &&
        jikai >= 0 &&
        jikai < kukansuu;
    final String jikaiMei = race == 3 ? '${jikai + 1}組' : '${jikai + 1}区';
    // 直近区間結果セットの文(レース中と結果画面で共通)
    // 実況が面白くなるように、個人順位速報は補正の説明まで入った説明文つきにする
    // 先頭には、レースの名前と何区か(最終区間ならゴールしたこと)の見出しを付ける(1.8.3)
    String chokkinKekkaSet() =>
        '${_setMidashi(gh, race, chokkin, '直近区間結果', goalBun: true)}\n\n' +
        kojinJuniSokuhouText(gh, chokkin, viewMode: ViewMode.description) +
        _setKugiri +
        tuukaJuniSokuhouText(gh, chokkin);

    final List<_AiCopyKoumoku> list = [];
    // 目標順位を決める画面では、目標順位相談セットを一番上に出す(1.8.3)
    // (目標順位を決める駅伝(10月・11月・正月・カスタム)だけ。当日変更のあとの画面なので、
    //  コンピュータの大学の当日変更も済んでいて、全大学の区間配置を出してよい)
    if (mokuhyouGamen && [0, 1, 2, 5].contains(race)) {
      list.add(
        _AiCopyKoumoku(
          '目標順位相談セット',
          jikai > 0
              ? '目標順位ごとの金銀・目標順位と指示の仕様・自分の大学のレース経過・${kukanMei}の通過順位速報と、残りの区間のコース情報・全大学詳細リストをまとめてコピー。目標順位の決め直しの相談に'
              : '目標順位ごとの金銀・目標順位と指示の仕様・コース情報・全区間・全大学詳細リストをまとめてコピー。目標順位の相談に',
          Icons.flag_circle,
          () => _mokuhyouSoudanSet(gh, race, shutsujou),
        ),
      );
    }
    // 当日変更の画面では、当日変更相談セットを一番上に出す(1.8.3)
    // (当日変更がある駅伝(10月・11月・正月・カスタム)だけ。コンピュータの大学の当日変更は
    //  プレイヤーの確定のあとなので、ここで全大学の区間配置を出しても先の情報は漏れない)
    if (toujitsuGamen && [0, 1, 2, 5].contains(race) && shutsujou) {
      list.add(
        _AiCopyKoumoku(
          '当日変更相談セット',
          jikai > 0
              ? '当日変更のルール・自分の大学の区間配置と補欠(当日の調子つき)・レース経過と${kukanMei}の通過順位速報・変えられる区間のコース情報・今季タイム一覧表・駅伝出場履歴をまとめてコピー。当日変更の相談に'
              : '当日変更のルール・自分の大学の区間配置と補欠(当日の調子つき)・変えられる区間のコース情報・今季タイム一覧表・駅伝出場履歴をまとめてコピー。当日変更の相談に',
          Icons.swap_horiz,
          () => _toujitsuSoudanSet(gh, race),
        ),
      );
    }
    // 結果画面(レース後の振り返り)
    // 最後の区間を走り終えるとレース画面に戻らず結果画面になるので、
    // 最後の区間の直近区間結果セットは結果画面の一番上に出す
    // (文はレース中と同じ。レース中にも出る場面がない正月駅伝予選では出さない。1.8.3)
    if (kekkaGamen && ekiden && chokkin >= 0 && race != 4) {
      list.add(
        _AiCopyKoumoku(
          '直近区間結果セット($kukanMei)',
          '走り終えた最後の区間(${kukanMei})の個人順位速報(説明文つき)と通過順位速報をまとめてコピー。実況の締めくくりに',
          Icons.library_books,
          chokkinKekkaSet,
        ),
      );
    }
    // ゲームの仕様(どの場面でも一番上に出す。ただし、結果画面の直近区間結果セットと、
    // 目標順位を決める画面の目標順位相談セットは、その上に出す。1.8.3)
    list.add(
      _AiCopyKoumoku(
        'ゲームの仕様(生成AI向け)',
        '能力の意味と効く場面・持ちタイムの読み方・目標順位と指示などの決まり。会話の最初に一度渡すと、相談の精度が上がる',
        Icons.menu_book,
        () => gameShiyouText(),
      ),
    );
    if (kekkaGamen && ekiden && chokkin >= 0) {
      if (shutsujou && race != 4) {
        list.add(
          _AiCopyKoumoku(
            '振り返りセット',
            '総合成績と自分の大学のレース経過をまとめてコピー。振り返りに',
            Icons.library_books,
            () => [
              tuukaJuniSokuhouText(gh, chokkin),
              jibunRaceKeikaText(gh),
            ].join(_setKugiri),
          ),
        );
      }
      if (gakuren) {
        list.add(
          _AiCopyKoumoku(
            '学連選抜の振り返りセット',
            '総合成績(学連選抜もOPで入る)・学連選抜のレース経過・学連選抜の区間配置(選手の詳しい情報)をまとめてコピー。学連選抜の物語の振り返りに',
            Icons.library_books_outlined,
            () => [
              tuukaJuniSokuhouText(gh, chokkin),
              gakurenRaceKeikaText(gh),
              gakurenKukanHaitiText(gh),
            ].join(_setKugiri),
          ),
        );
      }
      list.add(
        _AiCopyKoumoku(
          '総合成績',
          '最後の${race == 3 ? '組' : '区'}の通過順位(結果画面の通過順位タイム表示と同じ)',
          Icons.emoji_events,
          () => tuukaJuniSokuhouText(gh, chokkin),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '全区間の個人成績',
          '区間ごとの全選手の順位とタイム(結果画面の個人順位タイム表示と同じ)',
          Icons.directions_run,
          () => [
            for (int k = 0; k <= chokkin; k++) kekka.kojinSeisekiText(gh, k),
          ].join(_setKugiri),
        ),
      );
      list.add(
        _AiCopyKoumoku.kukanSentaku(
          '個人成績(区間を選んでコピー)',
          '選んだ${race == 3 ? '組' : '区間'}の全選手の順位とタイム。全区間では長すぎるときに',
          Icons.format_list_bulleted,
          (int k) => kekka.kojinSeisekiText(gh, k),
          chokkin + 1,
          race == 3 ? '組' : '区',
        ),
      );
    }
    if (sokuhouAri) {
      list.add(
        _AiCopyKoumoku(
          '直近区間結果セット($kukanMei)',
          '走り終えた${kukanMei}の個人順位速報(説明文つき)と通過順位速報をまとめてコピー。補正の説明まで入るので、実況が詳しくなる',
          Icons.library_books,
          chokkinKekkaSet,
        ),
      );
    }
    // 次の区間の展開予想用(直近区間結果セットのすぐ下に出す。1.8.3)
    if (jikaiAri) {
      list.add(
        _AiCopyKoumoku(
          '次区間予想セット($jikaiMei)',
          chokkin >= 0
              ? '${kukanMei}の通過順位速報と、これから走る${jikaiMei}のコース情報・全大学詳細リストをまとめてコピー。次の区間の展開予想や指示の相談に'
              : 'これから走る${jikaiMei}のコース情報と全大学詳細リストをまとめてコピー。${jikaiMei}の展開予想や指示の相談に',
          Icons.insights,
          // 先頭の見出し(レースの名前と何区か)のあと、
          // 今の状況(通過順位と差)→次の区間のコース→次の区間を走る選手の順
          () =>
              '${_setMidashi(gh, race, jikai, '次区間予想')}\n\n' +
              [
                if (chokkin >= 0) tuukaJuniSokuhouText(gh, chokkin),
                courseKukanText(gh, race, jikai),
                kukanZenDaigakuText(jikai),
              ].where((t) => t.isNotEmpty).join(_setKugiri),
        ),
      );
    }
    if (sokuhouAri) {
      list.add(
        _AiCopyKoumoku(
          '個人順位速報($kukanMei)',
          '走破タイムと記録比',
          Icons.directions_run,
          () => kojinJuniSokuhouText(gh, chokkin),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '個人順位速報($kukanMei・説明文つき)',
          '補正の説明も入る(長くなります)',
          Icons.notes,
          () =>
              kojinJuniSokuhouText(gh, chokkin, viewMode: ViewMode.description),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '通過順位速報($kukanMei)',
          '通過順位・順位の上下・1位との差',
          Icons.format_list_numbered,
          () => tuukaJuniSokuhouText(gh, chokkin),
        ),
      );
    }
    if (ekiden && entryAri && shutsujou && race != 4) {
      list.add(
        _AiCopyKoumoku(
          '自分の大学のレース経過',
          '区間ごとの順位・タイム差・指示と結果・補正の説明・これから走る選手',
          Icons.flag,
          () => jibunRaceKeikaText(gh),
        ),
      );
    }
    if (gakuren && entryAri) {
      list.add(
        _AiCopyKoumoku(
          '学連選抜のレース経過',
          '学連選抜の区間ごとの順位相当・指示と結果・補正の説明',
          Icons.flag_outlined,
          () => gakurenRaceKeikaText(gh),
        ),
      );
    }
    if (ekiden && entryAri && !kekkaGamen) {
      list.add(
        _AiCopyKoumoku(
          'レース前セット',
          'コース情報と全区間・全大学詳細リストをまとめてコピー。展開予想に',
          Icons.library_books_outlined,
          () => [
            courseZenKukanText(gh, race),
            zenKukanZenDaigakuText(),
          ].where((t) => t.isNotEmpty).join(_setKugiri),
        ),
      );
    }
    // エントリーの画面(一次エントリー・学連選抜編成・区間エントリー)の相談セット(1.8.2)
    // 駅伝予選では、先頭に「この大会の決まり」を入れる(1.8.4)
    if (!entryAri && ekiden && shutsujou) {
      final bool yosen = race == 3 || race == 4;
      list.add(
        _AiCopyKoumoku(
          '相談セット',
          yosen
              ? 'この大会の決まり(経験補正がないことなど)・エントリーの状況・コース情報・自分の大学の今季タイム一覧表・駅伝出場履歴をまとめてコピー。メンバー選びの相談に'
              : 'エントリーの状況(選んでいる選手・今の区間配置)・コース情報・自分の大学の今季タイム一覧表・駅伝出場履歴をまとめてコピー。エントリーや区間配置の相談に',
          Icons.library_books,
          () => [
            yosenKimariText(race),
            entryJoukyouText(gh, univId: gh.MYunivid),
            courseZenKukanText(gh, race),
            konkiSeisekiHyouText(univId: gh.MYunivid),
            ekidenRirekiText(univId: gh.MYunivid),
          ].where((t) => t.isNotEmpty).join(_setKugiri),
        ),
      );
    }
    if (!entryAri && gakuren) {
      list.add(
        _AiCopyKoumoku(
          '学連選抜の相談セット',
          'コース情報・学連選抜の区間配置(選手の詳しい情報)・今季タイム一覧表・駅伝出場履歴をまとめてコピー。学連選抜の区間配置の相談に',
          Icons.library_books_outlined,
          () => [
            courseZenKukanText(gh, race),
            gakurenKukanHaitiText(gh),
            konkiSeisekiHyouText(univId: -1, gakuren: true),
            gakurenEkidenRirekiText(gh),
          ].where((t) => t.isNotEmpty).join(_setKugiri),
        ),
      );
    }
    if (ekiden) {
      list.add(
        _AiCopyKoumoku(
          'コース情報(全区間)',
          '距離・登り下り・アップダウン',
          Icons.terrain,
          () => courseZenKukanText(gh, race),
        ),
      );
    }
    if (ekiden && entryAri) {
      list.add(
        _AiCopyKoumoku(
          '全区間・全大学詳細リスト',
          '区間ごとの全選手の能力と持ちタイム(学連選抜も入る)',
          Icons.groups,
          () => zenKukanZenDaigakuText(),
        ),
      );
    }
    if (my != null) {
      list.add(
        _AiCopyKoumoku(
          '自分の大学の今季タイム一覧表',
          '選手ごとの今季の成績と能力(CSV形式)。エントリーや区間配置の相談に',
          Icons.table_chart,
          () => konkiSeisekiHyouText(univId: gh.MYunivid),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '自分の大学の駅伝出場履歴',
          '選手ごとに、出場した駅伝の区間・順位・タイム(駅伝出場履歴一覧(選手ごと)と同じ内容)',
          Icons.history,
          () => ekidenRirekiText(univId: gh.MYunivid),
        ),
      );
    }
    if (gakuren) {
      list.add(
        _AiCopyKoumoku(
          '学連選抜の区間配置',
          '補欠も含めた学連選抜の選手の能力と持ちタイム、予選の結果',
          Icons.groups_outlined,
          () => gakurenKukanHaitiText(gh),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '学連選抜の今季タイム一覧表',
          '学連選抜のメンバーの今季の成績と能力(CSV形式)',
          Icons.table_chart_outlined,
          () => konkiSeisekiHyouText(univId: -1, gakuren: true),
        ),
      );
      list.add(
        _AiCopyKoumoku(
          '学連選抜の駅伝出場履歴',
          'メンバーが元の大学などで出場した駅伝の区間・順位・タイム',
          Icons.history_toggle_off,
          () => gakurenEkidenRirekiText(gh),
        ),
      );
    }
    return list;
  }

  // コピーして一覧を閉じ、お知らせを出す
  Future<void> _copy(
    BuildContext sheetContext,
    ScaffoldMessengerState messenger,
    String title,
    String text,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    messenger.showSnackBar(SnackBar(content: Text('「$title」をコピーしました')));
  }

  // 区間を選んでコピーするものの行(区間のボタンを並べる)
  Widget _kukanSentakuTile(
    BuildContext sheetContext,
    ScaffoldMessengerState messenger,
    _AiCopyKoumoku k,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(k.icon, color: Colors.cyanAccent),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.title, style: const TextStyle(color: Colors.white)),
                    Text(
                      k.setsumei,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int kukan = 0; kukan < k.kukanKazu; kukan++)
                  OutlinedButton(
                    onPressed: () => _copy(
                      sheetContext,
                      messenger,
                      '個人成績(${kukan + 1}${k.kukanTani})',
                      k.kukanTsukuru!(kukan),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      side: const BorderSide(color: Colors.cyanAccent),
                      minimumSize: const Size(56, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text('${kukan + 1}${k.kukanTani}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _hiraku(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return;
    final List<_AiCopyKoumoku> list = _koumokuList(gh);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  "生成AIに渡すテキスト",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  "押すとテキストがコピーされます。生成AIに貼り付けると、レースの実況や、区間配置・指示の相談を楽しめます。",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const Divider(color: Colors.white24),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "この場面でコピーできるものはありません",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              for (final _AiCopyKoumoku k in list)
                if (k.kukanTsukuru != null)
                  _kukanSentakuTile(sheetContext, messenger, k)
                else
                  ListTile(
                    leading: Icon(k.icon, color: Colors.cyanAccent),
                    title: Text(
                      k.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      k.setsumei,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _copy(
                      sheetContext,
                      messenger,
                      k.title,
                      k.tsukuru!(),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _hiraku(context),
      icon: const Icon(Icons.smart_toy_outlined, color: Colors.cyanAccent),
      label: const Text(
        "生成AIに渡すテキスト",
        style: TextStyle(color: Colors.cyanAccent),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}
