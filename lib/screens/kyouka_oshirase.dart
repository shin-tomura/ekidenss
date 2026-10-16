import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kyouka_project.dart'
    show
        KyoukaProject,
        KyoukaShidouOshirase,
        kyoukaProjectHyouji,
        kyoukaKikanMoji;
import 'package:ekiden/kansuu/taikai_chouki.dart' show choukiNendo;
import 'package:ekiden/kansuu/kiji/kiji_kyouka.dart' show kyoukaMokuhyou;

// ------------------------------------------------------------
// 強化プロジェクトの始動のお知らせ(2.0.2。kyouka_project.dart)
//
// ・年度替わりの抽選(kyoukaProjectChuusen)で始まったときに印(KyoukaShidouOshirase.dasu。メモリだけ)を立て、
//   そのすぐあとのスカウトの画面(9000Freshmankakutoku.dart)の最初に、スカウト解禁の記事より先に一度だけ出す
//   (始まった年のスカウトから効くので、スカウトの帯などより先に知らせる)
// ・目標は記事と同じ決め方(kiji_kyouka.dart の kyoukaMokuhyou)
// ・スキップ中はスカウトの画面が出ないので出ない。印は出したら下ろす
//   (次の年のスカウトまで残っていても、始まった年でなければ出さずに下ろす)
// ------------------------------------------------------------

/// スカウトの画面の最初に呼ぶ。今年度に強化プロジェクトが始まっていれば、お知らせのダイアログを一度だけ出し、
/// 閉じるまで待つ(出すものがなければすぐ戻る)
Future<void> kyoukaShidouOshiraseDasu(BuildContext context, Ghensuu gh) async {
  if (!KyoukaShidouOshirase.dasu) return;
  KyoukaShidouOshirase.dasu = false;
  final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (k == null) return;
  final int nendo = choukiNendo(gh);
  final KyoukaProject? p = kyoukaProjectHyouji(k, gh);
  if (p == null || p.hajime != nendo) return;
  UnivData? u;
  for (final UnivData x in Hive.box<UnivData>('univBox').values) {
    if (x.id == p.univid) u = x;
  }
  if (u == null) return;
  final String mokuhyou = kyoukaMokuhyou(u, nendo).mokuhyou;
  // 目標に「正月駅伝」が入っていなければ足す(「悲願の初優勝」→「正月駅伝での悲願の初優勝」)
  final String mezasu = mokuhyou.contains('正月駅伝') ? mokuhyou : '正月駅伝での$mokuhyou';
  final bool jibun = p.univid == gh.MYunivid;
  final String dare = jibun ? 'あなたの大学' : '${u.name}大学';
  final String bun =
      '$dareが、$mezasuを目指して、強化プロジェクトを始めました(${kyoukaKikanMoji(p, gh)})。\n\n'
      '期間中は、新入生のスカウトで、名声の高い大学と同じくらい選ばれやすくなります。今回のスカウトから効きます。\n\n'
      'くわしくは、スカウトのあとの最新画面の「期待のルーキー(箱庭スポーツ)」から、強化プロジェクトの記事を読めます。';
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                jibun ? '強化プロジェクト始動(あなたの大学)' : '強化プロジェクト始動',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            bun,
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
