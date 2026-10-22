import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kansuu/settei_shoukai.dart';
import 'package:ekiden/saitekikai.dart' show ModalComputerTeamProb;
import 'package:ekiden/screens/55fromNormal.dart' show SimulationModeSelectScreen;
import 'package:ekiden/screens/Modal_custom.dart' show ModalCustomEkidenSettings;
import 'package:ekiden/screens/Modal_racejiki.dart' show ModalRaceTimeSettings;
import 'package:ekiden/screens/Modal_courseedit_kiten.dart' show RaceCourseEditSelectionView;
import 'package:ekiden/screens/univ_screen.dart'
    show
        ModalKantokuUnivHenkou,
        ModalNanidoHenkou,
        ModalOndoHenkou,
        ModalKiwameHosei,
        ModalGakurenHosei,
        ModalSpurtryokuseichousisuu2,
        ModalSpurtryokuseichousisuu3,
        ModalIkuseiryokuHenkou,
        ModalMeiseiHenkou,
        ModalEkidenFameSettings,
        ModalRyugakuseiNinzu;
import 'package:ekiden/screens/Modal_TimeChousei.dart' show ModalTimeAdjustmentSettings;
import 'package:ekiden/screens/Modal_choukyoritimehosei.dart' show ModalPaceAdjustment;
import 'package:ekiden/screens/Modal_nouryokuEikyodo.dart' show ModalNouryokuEikyodo;
import 'package:ekiden/screens/Modal_chousi.dart' show ModalConditionSettings;
import 'package:ekiden/screens/Modal_hoseiTsuyosa.dart' show ModalHoseiTsuyosa;
import 'package:ekiden/screens/shuudan_settei.dart' show ModalShuudanSettei;
import 'package:ekiden/screens/Modal_univkoseiall.dart' show ModalAllUnivAbilityBulkSettingView;
import 'package:ekiden/screens/senryaku_entry_settei.dart' show ModalSenryakuEntrySettei;
import 'package:ekiden/screens/Modal_comGoldSilver.dart' show ModalComGoldSilver;
import 'package:ekiden/screens/Modal_comScout.dart' show ModalComScout;
import 'package:ekiden/screens/Modal_kukanHaichiHoushin.dart' show ModalKukanHaichiHoushin;
import 'package:ekiden/screens/yosen_com_siji_settei.dart' show ModalYosenComSijiSettei;
import 'package:ekiden/screens/kyouka_project_settei.dart' show ModalKyoukaProjectSettei;
import 'package:ekiden/screens/bokou_pipe_settei.dart' show ModalBokouPipeSettei;
import 'package:ekiden/screens/Modal_bairitu_goldsilver.dart' show ModalMoneySettings;
import 'package:ekiden/screens/Modal_TrainingEffect.dart' show ModalTrainingEffectSettings;
import 'package:ekiden/screens/seichou_type_settei.dart' show ModalSeichouTypeSettei;
import 'package:ekiden/screens/konki_best_parts.dart' show ModalKonkiBestSettei;
import 'package:ekiden/screens/Modal_shumihihyouji.dart' show ModalHobbyDisplaySettings;
import 'package:ekiden/screens/meisei_yokonarabi_settei.dart' show meiseiYokonarabiSetteiHiraku;

// ------------------------------------------------------------
// 設定の紹介の画面の部品(2.1.3。紹介文と札の選び方は kansuu/settei_shoukai.dart)
// ・setteiSetsumeiIreru: 設定タブのボタンの並びに、紹介文を差し込む(setting_screen.dart)
// ・SetteiFuda: ホームの画面の、1月中旬〜2月の行事のない日の札(mode0100_content.dart)
// ・setteiShoukaiHiraku: 札の「この設定を開く」。設定タブのボタンと同じ画面を同じ開き方で開く
//   (札で紹介する設定(fuda が true)の分だけ。設定タブで開き方を変えたら、ここも直す)
// ------------------------------------------------------------

/// 札で紹介する設定の画面(名声の横並び設定は、専用の開き方なので setteiShoukaiHiraku の中で開く)
final Map<String, Widget Function()> _gamen = {
  '箱庭モード/通常モード切替': () => const SimulationModeSelectScreen(),
  'カスタム駅伝設定': () => const ModalCustomEkidenSettings(),
  '記録会時期設定': () => const ModalRaceTimeSettings(),
  '駅伝コース編集': () => const RaceCourseEditSelectionView(),
  '総監督をする大学を変更': () => const ModalKantokuUnivHenkou(),
  '難易度変更': () => const ModalNanidoHenkou(),
  '難易度変更2': () => const ModalOndoHenkou(),
  '難易度「極」「天」設定': () => const ModalKiwameHosei(),
  '全体・区間ごとタイム調整': () => const ModalTimeAdjustmentSettings(),
  '長距離タイム抑制設定': () => const ModalPaceAdjustment(),
  '能力のタイムへの影響度設定': () => const ModalNouryokuEikyodo(),
  '調子関連設定': () => const ModalConditionSettings(),
  '目標順位・指示の補正設定': () => const ModalHoseiTsuyosa(),
  '集団走設定': () => const ModalShuudanSettei(),
  '学連選抜モチベーション設定': () => const ModalGakurenHosei(),
  '実力発揮度全大学一斉変更': () => const ModalAllUnivAbilityBulkSettingView(),
  '最適解区間配置確率設定': () => const ModalComputerTeamProb(),
  '戦略的エントリー確率設定': () => const ModalSenryakuEntrySettei(),
  '目標順位決め方設定(コンピュータの大学)': () => const ModalSpurtryokuseichousisuu2(),
  'コンピュータ金銀使用': () => const ModalComGoldSilver(),
  'コンピュータスカウト': () => const ModalComScout(),
  '区間配置の方針': () => const ModalKukanHaichiHoushin(),
  '正月駅伝予選の指示と集団走': () => const ModalYosenComSijiSettei(),
  '強化プロジェクト設定': () => const ModalKyoukaProjectSettei(),
  '監督の母校パイプ設定': () => const ModalBokouPipeSettei(),
  '育成力変更': () => const ModalIkuseiryokuHenkou(),
  '金銀支給量設定': () => const ModalMoneySettings(),
  '年間強化練習効果設定': () => const ModalTrainingEffectSettings(),
  '成長タイプ設定': () => const ModalSeichouTypeSettei(),
  '名声変更': () => const ModalMeiseiHenkou(),
  '駅伝名声設定': () => const ModalEkidenFameSettings(),
  '入学時名声影響度設定': () => const ModalSpurtryokuseichousisuu3(),
  '留学生受け入れ設定': () => const ModalRyugakuseiNinzu(),
  '持ちタイムの表示設定': () => const ModalKonkiBestSettei(),
  '趣味・高校時代の表示設定': () => const ModalHobbyDisplaySettings(),
};

/// 名前[mei]の設定を、設定タブのボタンと同じ開き方で開く(開けないものは何もしない)
Future<void> setteiShoukaiHiraku(BuildContext context, String mei) async {
  if (mei == '名声の横並び設定') {
    await meiseiYokonarabiSetteiHiraku(context);
    return;
  }
  final Widget Function()? gamen = _gamen[mei];
  if (gamen == null) return;
  await showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: mei, // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300), // アニメーション時間
    pageBuilder: (context, animation, secondaryAnimation) => gamen(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// 札で開ける設定か(開き方を書き忘れたものは、札に「この設定を開く」を出さない)
bool setteiShoukaiHirakeru(String mei) =>
    mei == '名声の横並び設定' || _gamen.containsKey(mei);

/// 設定タブの紹介文(ボタンのすぐ下に小さく出す。高さは決めず、長ければ折り返す)
class SetteiSetsumeiBun extends StatelessWidget {
  final String bun;
  const SetteiSetsumeiBun(this.bun, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // TextButton の文字の位置にそろえる
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
      child: Text(
        bun,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: HENSUU.fontsize_honbun - 3,
        ),
      ),
    );
  }
}

/// 設定タブのボタンの並び[children]の、ボタン(と押せないときの理由の文)のすぐ下に紹介文を差し込む
/// ([dasu] が false なら、そのまま返す。ボタンの文字で紹介文を引くので、ボタンの作りは変えない)
List<Widget> setteiSetsumeiIreru(List<Widget> children, {required bool dasu}) {
  if (!dasu) return children;
  final List<Widget> kekka = [];
  for (final Widget w in children) {
    kekka.add(w);
    final String? bun = _setsumeiBun(w);
    if (bun != null) kekka.add(SetteiSetsumeiBun(bun));
  }
  return kekka;
}

/// 並びの1つ[w]の紹介文(ボタンでも理由の文でもなければnull)
String? _setsumeiBun(Widget w) {
  if (w is TextButton) {
    final Widget? c = w.child;
    if (c is Text && c.data != null) return setteiShoukaiYomu(c.data!)?.bun;
    return null;
  }
  Text? t;
  if (w is Text) {
    t = w;
  } else if (w is Padding && w.child is Text) {
    t = w.child as Text;
  }
  final String? data = t?.data;
  if (data == null) return null;
  return setteiShoukaiRiyuu(data)?.bun;
}

/// ホームの画面の、設定を1つ紹介する札(1月中旬〜2月の行事のない日)
class SetteiFuda extends StatelessWidget {
  /// ボックスから読んだ進行データ(「設定タブで見る」で、下のバーの切り替えを書き換えて保存する)
  final Ghensuu gh;
  final SetteiShoukai shoukai;
  const SetteiFuda({super.key, required this.gh, required this.shoukai});

  @override
  Widget build(BuildContext context) {
    const Color iro = Colors.amberAccent;
    final ButtonStyle botanStyle = OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.lightBlueAccent, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
    const TextStyle botanMoji = TextStyle(color: Colors.lightBlueAccent);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: iro.withOpacity(0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline, color: iro, size: 18),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  '設定の紹介',
                  style: TextStyle(color: iro, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            shoukai.mei,
            style: const TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(shoukai.bun, style: const TextStyle(color: HENSUU.textcolor)),
          const SizedBox(height: 10),
          // 文字を大きくしても収まるように、横に並ばなければ折り返す
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (setteiShoukaiHirakeru(shoukai.mei))
                OutlinedButton.icon(
                  onPressed: () => setteiShoukaiHiraku(context, shoukai.mei),
                  icon: const Icon(Icons.tune, color: Colors.lightBlueAccent, size: 18),
                  label: const Text('この設定を開く', style: botanMoji),
                  style: botanStyle,
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  // 下のバーを説明画面にし、設定タブを開く(ほかの画面から最新の画面に戻すのと同じ仕組み)
                  setteiTabYoyaku = true;
                  gh.gamenflag = 4;
                  await gh.save();
                },
                icon: const Icon(Icons.list_alt, color: Colors.lightBlueAccent, size: 18),
                label: const Text('設定タブで見る', style: botanMoji),
                style: botanStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '説明画面の設定タブの「${shoukai.mei}」でも変えられます。',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: HENSUU.fontsize_honbun - 3,
            ),
          ),
        ],
      ),
    );
  }
}
