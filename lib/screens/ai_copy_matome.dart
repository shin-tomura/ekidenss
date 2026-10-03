import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/jibun_keika_text.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_kukanresult350.dart';
import 'package:ekiden/screens/Modal_tuukajuni.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
// 結果画面の「個人順位タイム表示」の文(ViewModeの名前が個人順位速報と同じなので、名前を付けて読み込む)
import 'package:ekiden/screens/Modal_kukanresult.dart' as kekka;

// ------------------------------------------------------------
// 生成AIに渡すテキストのまとめボタン(1.8.2)
// 押すと、その場面で生成AIに渡すと便利なテキストの一覧が出て、
// 1回押すだけでコピーできる。いつもいっしょに渡すものはセットでコピーできる。
// ・レース前セット: コース情報+全区間・全大学詳細リスト(展開予想に)
// ・区間ごとセット: 直近の区間の個人順位速報+通過順位速報(実況に)
// ・振り返りセット: 総合成績+自分の大学のレース経過(結果画面で、レース後の振り返りに)
// 文はそれぞれの画面のコピーと同じもの(画面の外に出した関数で作る)
// ------------------------------------------------------------

// コピーできるもの1つ分
class _AiCopyKoumoku {
  final String title;
  final String setsumei;
  final IconData icon;
  final String Function() tsukuru; // コピーする文を作る
  const _AiCopyKoumoku(this.title, this.setsumei, this.icon, this.tsukuru);
}

// セットでコピーするときの区切り
const String _setKugiri = '\n\n==============================\n\n';

/// 生成AIに渡すテキストのまとめボタン
/// [entryAri] 区間エントリーが済んでいる場面か(一次エントリーの画面ではfalse。
///   falseのときは、全区間・全大学詳細リストとレース経過を出さない)
/// [kekkaGamen] レースの結果画面か(trueのときは、レース中の速報の代わりに
///   振り返りセット・総合成績・全区間の個人成績を出す。文は結果画面のコピーと同じ)
class AiCopyMatomeButton extends StatelessWidget {
  final bool entryAri;
  final bool kekkaGamen;
  const AiCopyMatomeButton({
    super.key,
    this.entryAri = true,
    this.kekkaGamen = false,
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

    final List<_AiCopyKoumoku> list = [];
    // 結果画面(レース後の振り返り)
    if (kekkaGamen && ekiden && chokkin >= 0) {
      final bool jibunAri = shutsujou && race != 4;
      list.add(
        _AiCopyKoumoku(
          '振り返りセット',
          jibunAri
              ? '総合成績と自分の大学のレース経過をまとめてコピー。振り返りに'
              : '総合成績をコピー。振り返りに',
          Icons.library_books,
          () => [
            tuukaJuniSokuhouText(gh, chokkin),
            if (jibunAri) jibunRaceKeikaText(gh),
          ].join(_setKugiri),
        ),
      );
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
    }
    if (sokuhouAri) {
      list.add(
        _AiCopyKoumoku(
          '区間ごとセット($kukanMei)',
          '${kukanMei}の個人順位速報と通過順位速報をまとめてコピー。実況に',
          Icons.library_books,
          () =>
              kojinJuniSokuhouText(gh, chokkin) +
              _setKugiri +
              tuukaJuniSokuhouText(gh, chokkin),
        ),
      );
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
    }
    return list;
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
                ListTile(
                  leading: Icon(k.icon, color: Colors.cyanAccent),
                  title: Text(
                    k.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    k.setsumei,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  onTap: () async {
                    final String text = k.tsukuru();
                    await Clipboard.setData(ClipboardData(text: text));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    messenger.showSnackBar(
                      SnackBar(content: Text('「${k.title}」をコピーしました')),
                    );
                  },
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
