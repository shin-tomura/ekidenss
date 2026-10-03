import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/gakuren_copy_button.dart';

/// 学連選抜の区間配置を決める画面(1.8.2)
/// プレイヤーの大学が正月駅伝に出場できない年に、学連選抜の監督として区間配置を決める
/// (学連選抜編成の画面(mode0290.dart)から開く。最初はコンピュータが決めた配置になっている)
/// ・区間ごとに走る選手を選ぶ。ほかの区間の選手を選ぶと、2人の区間が入れ替わる
/// ・試走は、元の選手データで大学の選手と同じ試走タイムの計算をする
///   (±0.5%の濁しあり。1区の集団のペースと、2区以降のモチベーション低下補正は入らない)
class ModalGakurenKukanHenshuu extends StatefulWidget {
  const ModalGakurenKukanHenshuu({super.key});

  @override
  State<ModalGakurenKukanHenshuu> createState() =>
      _ModalGakurenKukanHenshuuState();
}

class _ModalGakurenKukanHenshuuState extends State<ModalGakurenKukanHenshuu> {
  static const int _raceIndex = 2; // 正月駅伝
  static const int _yosenIndex = 4; // 正月駅伝予選

  /// 区間ごとの試走タイム(区間 → 秒)
  final Map<int, double> _shisouKekka = {};

  /// 試走を計算している区間
  final Set<int> _keisanChuu = {};

  int _entry(Senshu_Gakuren_Data s) =>
      s.entrykukan_race[_raceIndex][s.gakunen - 1];

  /// 区間[kukan]を走る選手(いなければnull)
  Senshu_Gakuren_Data? _kukanNoSenshu(List<Senshu_Gakuren_Data> senshu, int kukan) {
    for (final s in senshu) {
      if (_entry(s) == kukan) return s;
    }
    return null;
  }

  /// 区間[kukan]を走る選手を[senshuId]の選手にする
  /// その選手がほかの区間を走る予定だった場合は、2人の区間を入れ替える
  Future<void> _erabu(int kukan, int senshuId) async {
    final Box<Senshu_Gakuren_Data> box = Hive.box<Senshu_Gakuren_Data>(
      'gakurenSenshuBox',
    );
    final List<Senshu_Gakuren_Data> senshu = box.values.toList();
    Senshu_Gakuren_Data? atarashii;
    for (final s in senshu) {
      if (s.id == senshuId) atarashii = s;
    }
    if (atarashii == null) return;
    final int motoKukan = _entry(atarashii);
    if (motoKukan == kukan) return;
    Senshu_Gakuren_Data? imano;
    for (final s in senshu) {
      if (s.id != senshuId && _entry(s) == kukan) imano = s;
    }
    atarashii.entrykukan_race[_raceIndex][atarashii.gakunen - 1] = kukan;
    if (imano != null) {
      imano.entrykukan_race[_raceIndex][imano.gakunen - 1] = motoKukan;
    }
    // 2人分をまとめて保存する(途中で終了しても、区間が重ならないように)
    await box.putAll({
      atarashii.id: atarashii,
      if (imano != null) imano.id: imano,
    });
    if (!mounted) return;
    setState(() {
      // 走る選手が変わった区間の試走タイムは消す
      _shisouKekka.remove(kukan);
      if (motoKukan >= 0) _shisouKekka.remove(motoKukan);
    });
  }

  /// 区間[kukan]を[senshuId]の選手が試走する
  Future<void> _shisou(int kukan, int senshuId) async {
    setState(() => _keisanChuu.add(kukan));
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final List<SenshuData> sortedSenshu =
        Hive.box<SenshuData>('senshuBox').values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final List<UnivData> sortedUniv = Hive.box<UnivData>('univBox').values
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final KantokuData kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData')!;
    double? kekka;
    // 試走タイムの計算は、選手idと並びの番号が同じ前提
    if (senshuId >= 0 &&
        senshuId < sortedSenshu.length &&
        sortedSenshu[senshuId].id == senshuId) {
      kekka = await runTrialCalculation(
        senshuId,
        kukan,
        gh,
        sortedSenshu,
        sortedUniv,
        kantoku,
      );
    }
    if (!mounted) return;
    setState(() {
      _keisanChuu.remove(kukan);
      if (kekka != null) _shisouKekka[kukan] = kekka;
    });
  }

  void _shousai(int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ModalSenshuDetailView(senshuId: senshuId);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final int kukansuu = gh.kukansuu_taikaigoto[_raceIndex];
    final Map<int, UnivData> univMap = {
      for (final u in Hive.box<UnivData>('univBox').values) u.id: u,
    };
    final Box<Senshu_Gakuren_Data> gakurenBox = Hive.box<Senshu_Gakuren_Data>(
      'gakurenSenshuBox',
    );

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '学連選抜の区間配置',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: gakurenBox.listenable(),
        builder: (context, Box<Senshu_Gakuren_Data> box, _) {
          // 予選の順位の良い順に並べた選手(選ぶときの一覧)
          final List<Senshu_Gakuren_Data> senshu = box.values.toList()
            ..sort(
              (a, b) => a.kukanjuni_race[_yosenIndex][a.gakunen - 1].compareTo(
                b.kukanjuni_race[_yosenIndex][b.gakunen - 1],
              ),
            );
          if (senshu.isEmpty) {
            return const Center(
              child: Text(
                '学連選抜の選手がいません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                '区間ごとに走る選手を選んでください。ほかの区間を走る予定の選手を選ぶと、2人の区間が入れ替わります。最初はコンピュータが決めた配置になっています。\n'
                '試走は大学の選手と同じ計算です(走るたびに多少タイムが違います)。1区の集団のペースや、2区以降のモチベーション低下補正、経験補正、調子は入っていません。',
                style: TextStyle(
                  color: HENSUU.textcolor.withOpacity(0.85),
                  fontSize: HENSUU.fontsize_honbun - 2,
                ),
              ),
              const SizedBox(height: 8),
              // 1区の集団のペースは大学の選手だけで決まる(RaceCalc_gakuren.dartの1区の補正を参照)
              Text(
                '※1区の集団のペースは大学の選手だけで決まります。どんなにカリスマが高くても、学連選抜の選手が集団のペースを作ることはありません。',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: HENSUU.fontsize_honbun - 2,
                ),
              ),
              // 区間配置と選手の詳しい情報をコピーする(生成AIとの相談用)
              const Align(
                alignment: Alignment.centerLeft,
                child: GakurenCopyButton(kukanHaiti: true),
              ),
              const SizedBox(height: 4),
              for (int kukan = 0; kukan < kukansuu; kukan++)
                _kukanGyou(
                  kukan: kukan,
                  kyori: gh.kyori_taikai_kukangoto[_raceIndex][kukan],
                  senshu: senshu,
                  univMap: univMap,
                  myUnivid: gh.MYunivid,
                ),
            ],
          );
        },
      ),
    );
  }

  /// 選手の一覧に出す文(例: 山田太郎(3) 〇〇大 予選12位)
  String _senshuBun(Senshu_Gakuren_Data s, Map<int, UnivData> univMap) {
    final String univ = univMap[s.univid]?.name ?? '---';
    final int yosenJuni = s.kukanjuni_race[_yosenIndex][s.gakunen - 1] + 1;
    return '${s.name}(${s.gakunen}) $univ 予選$yosenJuni位';
  }

  /// 区間1つ分の行
  Widget _kukanGyou({
    required int kukan,
    required double kyori,
    required List<Senshu_Gakuren_Data> senshu,
    required Map<int, UnivData> univMap,
    required int myUnivid,
  }) {
    final Senshu_Gakuren_Data? ima = _kukanNoSenshu(senshu, kukan);
    final double? shisou = _shisouKekka[kukan];
    final bool keisanChuu = _keisanChuu.contains(kukan);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kukan + 1}区 ${(kyori / 1000).toStringAsFixed(1)}km',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
          DropdownButton<int>(
            value: ima?.id,
            hint: const Text(
              '(選手が決まっていません)',
              style: TextStyle(color: Colors.white54),
            ),
            isExpanded: true,
            dropdownColor: const Color.fromARGB(255, 30, 30, 30),
            items: [
              for (final s in senshu)
                DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(
                    '${_senshuBun(s, univMap)}'
                    '${_entry(s) >= 0 && _entry(s) != kukan ? '(${_entry(s) + 1}区)' : ''}',
                    style: TextStyle(
                      color: s.univid == myUnivid
                          ? Colors.amber
                          : HENSUU.LinkColor,
                      fontSize: HENSUU.fontsize_honbun - 2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (int? id) {
              if (id != null) _erabu(kukan, id);
            },
          ),
          if (ima != null)
            Row(
              children: [
                TextButton(
                  onPressed: keisanChuu ? null : () => _shisou(kukan, ima.id),
                  child: const Text(
                    '試走',
                    style: TextStyle(color: HENSUU.LinkColor),
                  ),
                ),
                TextButton(
                  onPressed: () => _shousai(ima.id),
                  child: const Text(
                    '詳細',
                    style: TextStyle(color: HENSUU.LinkColor),
                  ),
                ),
                const SizedBox(width: 8),
                if (keisanChuu)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (shisou != null)
                  Text(
                    '試走 ${TimeDate.timeToFunByouString(shisou)}',
                    style: const TextStyle(color: HENSUU.textcolor),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
