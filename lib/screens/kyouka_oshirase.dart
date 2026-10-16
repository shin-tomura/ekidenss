import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/kansuu/kyouka_project.dart'
    show KyoukaProject, KyoukaShidouOshirase, kyoukaProjectChuu;
import 'package:ekiden/kansuu/taikai_chouki.dart' show choukiNendo;
import 'package:ekiden/kansuu/kiji/kiji_kyouka.dart' show kyoukaMokuhyou;

// ------------------------------------------------------------
// 強化プロジェクトの始動のお知らせ(2.0.2。kyouka_project.dart)
//
// ・年度替わりの抽選(kyoukaProjectChuusen)で始まったときに印(KyoukaShidouOshirase.dasu。メモリだけ)を立て、
//   4月5日の最新画面(mode0100_content.dart)で一度だけダイアログを出す
// ・目標は記事と同じ決め方(kiji_kyouka.dart の kyoukaMokuhyou)
// ・スキップ中は出さない(止まって進めなくなるため)。印は画面を作るときに見たら下ろす
//   (その日の画面を見る前にアプリを閉じると出ないが、記事・大学画面・スカウト解禁の記事の上の表示で分かる)
// ------------------------------------------------------------

/// 4月5日の最新画面を作るときに呼ぶ。今年度に強化プロジェクトが始まっていれば、
/// 画面を出したあとにお知らせのダイアログを一度だけ出す
void kyoukaShidouOshiraseYoyaku(BuildContext context, Ghensuu gh) {
  if (!KyoukaShidouOshirase.dasu) return;
  // スキップ中と、4月5日を過ぎたあとは出さない(印も下ろす)
  final Skip? skip = Hive.box<Skip>('skipBox').get('SkipData');
  if (skip == null || skip.skipflag != 0 || gh.month != 4 || gh.day != 5) {
    KyoukaShidouOshirase.dasu = false;
    return;
  }
  // 記事のカードが出る画面(モード100)になるまで待つ(この画面はモード110でも使うため。印は下ろさない)
  if (gh.mode != 100) return;
  KyoukaShidouOshirase.dasu = false;
  final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (k == null) return;
  final int nendo = choukiNendo(gh);
  final KyoukaProject? p = kyoukaProjectChuu(k, nendo);
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
      '$dareが、$mezasuを目指して、強化プロジェクトを始めました(${p.owari}年度まで)。\n\n'
      '期間中は、新入生のスカウトで、名声の高い大学と同じくらい選ばれやすくなります。\n\n'
      'くわしくは、この画面の「期待のルーキー(箱庭スポーツ)」から、強化プロジェクトの記事を読めます。'
      '読めるのは今日だけです。';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    showDialog<void>(
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
  });
}
