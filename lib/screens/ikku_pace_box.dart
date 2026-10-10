import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';

// ------------------------------------------------------------
// 駅伝の1区の集団のペースの予想と結果の枠(1.9.2。計算は lib/kansuu/ikku_pace.dart)
// ・IkkuPaceYosouBox: 予想(目標順位の確認(当日変更のあと)と、1区の指示の画面)
// ・IkkuPaceKekkaBox: 結果(2区の指示の画面)
// ------------------------------------------------------------

/// 枠の見た目(予想と結果で共通)
class _IkkuPaceWaku extends StatelessWidget {
  final String midashi;
  final List<String> gyou;
  final Color iro;

  const _IkkuPaceWaku({
    required this.midashi,
    required this.gyou,
    required this.iro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iro.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            midashi,
            style: TextStyle(
              color: iro,
              fontSize: HENSUU.fontsize_honbun + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          for (final String g in gyou)
            Text(
              g,
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun - 2,
              ),
            ),
        ],
      ),
    );
  }
}

/// 選手の名前・学年・大学(「山田太郎(3年・○○)」の形)
/// [tsuika]を渡すと、かっこの中の最後に「。」でつないで足す
String _senshuMei(
  String name,
  int gakunen,
  List<UnivData> sortedUniv,
  int univid, {
  String tsuika = '',
}) {
  final String univ = (univid >= 0 && univid < sortedUniv.length)
      ? sortedUniv[univid].name
      : '';
  final String naka = univ.isEmpty ? '$gakunen年' : '$gakunen年・$univ';
  return tsuika.isEmpty ? '$name($naka)' : '$name($naka。$tsuika)';
}

/// ほかに引っ張るかもしれない選手の並び(「○○(3年・○○。引っ張ればスローペース)、…」。いなければ空)
String _taikouMoji(IkkuPaceYosou yosou, List<UnivData> sortedUniv) {
  return yosou.taikou
      .map((t) {
        return _senshuMei(
          t.senshu.name,
          t.senshu.gakunen,
          sortedUniv,
          t.senshu.univid,
          tsuika: '引っ張れば${ikkuPaceMidashiMoji[t.midashi]}',
        );
      })
      .join('、');
}

List<SenshuData> _sortedSenshu() =>
    Hive.box<SenshuData>('senshuBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

List<UnivData> _sortedUniv() =>
    Hive.box<UnivData>('univBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

/// 1区の集団のペースの予想の枠
class IkkuPaceYosouBox extends StatelessWidget {
  /// 自分の大学の1区の選手のid(いなければnull)
  final int? jibunSenshuId;

  /// 自分の大学の選手が「スタート直後に飛び出す」を選んでいるか
  final bool jibunTobidasu;

  /// 自分の大学の選手が「指示なし」を選んでいるか(飛び出すことがあると添える)
  final bool jibunShijiNashi;

  /// 学連選抜の監督をしているときの、学連選抜の1区の選手
  final Senshu_Gakuren_Data? gakurenSenshu;

  /// 他大学の1区の当日変更を添えるか(目標順位の確認の画面)
  final bool toujitsuHenkou;

  /// 1区の区間エントリーの選手のid→代わりに走らせる選手のid(当日変更の画面で選んでいる交代)
  final Map<int, int> irekae;

  /// 調子を入れるか(直前順位予想では入れない)
  final bool chousiIreru;

  /// 他大学の当日変更の前の予想か(直前順位予想と当日変更の画面。注意書きを添え、
  /// 当日変更で1区に入れば集団を引っ張りそうな他大学の補欠も出す(1.9.5))
  final bool kakuteiMae;

  const IkkuPaceYosouBox({
    super.key,
    this.jibunSenshuId,
    this.jibunTobidasu = false,
    this.jibunShijiNashi = false,
    this.gakurenSenshu,
    this.toujitsuHenkou = false,
    this.irekae = const {},
    this.chousiIreru = true,
    this.kakuteiMae = false,
  });

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (gh == null || kantoku == null) return const SizedBox.shrink();
    final int race = gh.hyojiracebangou;
    if (!ikkuPaceTaishou(race) || gh.nowracecalckukan != 0) {
      return const SizedBox.shrink();
    }
    final List<SenshuData> sortedSenshu = _sortedSenshu();
    final List<UnivData> sortedUniv = _sortedUniv();
    final int? jibunId = jibunSenshuId;
    final Set<int> tobidasu = (jibunTobidasu && jibunId != null)
        ? <int>{jibunId}
        : <int>{};
    final IkkuPaceYosou? yosou = ikkuPaceYosou(
      gh: gh,
      racebangou: race,
      sortedSenshu: sortedSenshu,
      sortedUniv: sortedUniv,
      kantoku: kantoku,
      chousiIreru: chousiIreru,
      tobidasuSenshu: tobidasu,
      irekae: irekae,
    );
    if (yosou == null) return const SizedBox.shrink();

    final SenshuData pm = yosou.pacemaker;
    final List<String> gyou = [
      '集団を引っ張りそうな選手: ${_senshuMei(pm.name, pm.gakunen, sortedUniv, pm.univid)}',
      '予想ペース: ${ikkuPaceMoji(gh, race, yosou.pace, atoMoji: '前後')}',
    ];
    final String taikou = _taikouMoji(yosou, sortedUniv);
    if (taikou.isNotEmpty) gyou.add('ほかに引っ張るかもしれない選手: $taikou');

    // 当日変更で1区に入れば集団を引っ張りそうな他大学の補欠(他大学の当日変更の前だけ。1.9.5)
    final List<IkkuHoketsuKouho> hoketsu = kakuteiMae
        ? ikkuHoketsuKouho(
            gh: gh,
            racebangou: race,
            sortedSenshu: sortedSenshu,
            sortedUniv: sortedUniv,
            kantoku: kantoku,
            yosou: yosou,
            chousiIreru: chousiIreru,
            tobidasuSenshu: tobidasu,
            irekae: irekae,
            jibunSenshuId: jibunId,
          )
        : const <IkkuHoketsuKouho>[];
    if (hoketsu.isNotEmpty) {
      final String hoketsuMoji = hoketsu
          .map((h) {
            final String midashiMoji = ikkuPaceMidashiMoji[h.midashi];
            return _senshuMei(
              h.senshu.name,
              h.senshu.gakunen,
              sortedUniv,
              h.senshu.univid,
              tsuika: [
                if (h.soegaki.isNotEmpty) h.soegaki,
                h.honmei ? '入れば$midashiMoji' : '入って引っ張れば$midashiMoji',
              ].join('。'),
            );
          })
          .join('、');
      gyou.add('当日変更で1区に入れば引っ張りそうな補欠: $hoketsuMoji');
    }

    // 自分の大学の選手
    if (jibunId != null && jibunId >= 0 && jibunId < sortedSenshu.length) {
      final SenshuData s = sortedSenshu[jibunId];
      final IkkuAishou jibunAishou = yosou.aishou(s.id);
      gyou.add(
        '自分の大学の${s.name}(${s.gakunen}年): ${ikkuAishouYosouMoji(jibunAishou)}',
      );
      if (jibunShijiNashi && s.konjou >= 85) {
        gyou.add('・指示なしでも、スタート直後に飛び出すことがあります');
      }
      // 他大学の補欠が入って引っ張ると、大失速しそうになるとき(1.9.5)
      if (jibunAishou != IkkuAishou.daiShissoku) {
        for (final IkkuHoketsuKouho h in hoketsu) {
          if (h.jibunAishou != IkkuAishou.daiShissoku) continue;
          gyou.add(
            '・補欠の${_senshuMei(h.senshu.name, h.senshu.gakunen, sortedUniv, h.senshu.univid)}'
            'が入って引っ張ると、大失速のおそれがあります',
          );
        }
      }
    }

    // 学連選抜の監督をしているときの学連選抜の選手(ペースは作らないが、影響は受ける)
    final Senshu_Gakuren_Data? g = gakurenSenshu;
    if (g != null && g.id >= 0 && g.id < sortedSenshu.length) {
      final IkkuAishou a;
      if (g.sijiflag == 1) {
        a = IkkuAishou.tobidashi;
      } else {
        final double t = ikkuMikomiTime(
          senshuId: g.id,
          chousi: g.chousi,
          gh: gh,
          racebangou: race,
          sortedSenshu: sortedSenshu,
          sortedUniv: sortedUniv,
          kantoku: kantoku,
          chousiIreru: chousiIreru,
        );
        a = ikkuAishou(t, yosou.pace);
      }
      gyou.add('学連選抜の${g.name}(${g.gakunen}年): ${ikkuAishouYosouMoji(a)}');
      if (g.sijiflag == 0 && g.konjou >= 85) {
        gyou.add('・指示なしでも、スタート直後に飛び出すことがあります');
      }
    }

    // 他大学の1区の当日変更
    if (toujitsuHenkou) {
      final List<String> henkou = ikkuToujitsuHenkouMoji(
        gh: gh,
        racebangou: race,
        sortedSenshu: sortedSenshu,
        sortedUniv: sortedUniv,
      );
      if (henkou.isNotEmpty) {
        gyou.add('1区の当日変更: ${henkou.join('、')}');
      }
    }

    if (!chousiIreru) gyou.add('・当日の調子は、まだ予想に入っていません');
    if (kakuteiMae) {
      gyou.add('・他大学が当日変更で1区の選手を入れ替えると、ペースが変わることがあります');
    }
    gyou.add('・他大学の選手が飛び出すと、集団を引っ張る選手が変わり、ペースが変わることがあります');

    return _IkkuPaceWaku(
      midashi: '1区のペース予想: ${ikkuPaceMidashiMoji[yosou.midashi]}',
      gyou: gyou,
      iro: Colors.lightBlueAccent,
    );
  }
}

/// 当日変更の画面の「1区の候補を比べる」の画面
/// 1区の区間エントリーの選手と補欠のそれぞれを1区に置いたときの予想を並べる(1.9.2)
class IkkuPaceKouhoView extends StatelessWidget {
  /// 1区の区間エントリーの選手のid
  final int motoSenshuId;

  /// 比べる選手のid(1区の区間エントリーの選手と補欠)
  final List<int> kouhoIds;

  /// 今選んでいる選手のid
  final int sentakuchuuId;

  const IkkuPaceKouhoView({
    super.key,
    required this.motoSenshuId,
    required this.kouhoIds,
    required this.sentakuchuuId,
  });

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final List<SenshuData> sortedSenshu = _sortedSenshu();
    final List<UnivData> sortedUniv = _sortedUniv();

    final List<Widget> naiyou = [];
    if (gh != null && kantoku != null && ikkuPaceTaishou(gh.hyojiracebangou)) {
      final int race = gh.hyojiracebangou;
      for (final int id in kouhoIds) {
        if (id < 0 || id >= sortedSenshu.length) continue;
        final SenshuData s = sortedSenshu[id];
        final IkkuPaceYosou? yosou = ikkuPaceYosou(
          gh: gh,
          racebangou: race,
          sortedSenshu: sortedSenshu,
          sortedUniv: sortedUniv,
          kantoku: kantoku,
          irekae: {motoSenshuId: id},
        );
        if (yosou == null) continue;
        final List<String> gyou = [];
        final IkkuAishou a = yosou.aishou(s.id);
        if (a == IkkuAishou.hipparu) {
          gyou.add(
            '${ikkuPaceMidashiMoji[yosou.midashi]}(自分で集団を引っ張る見込み。'
            '${ikkuTimeMoji(yosou.pace)}前後)',
          );
        } else {
          final SenshuData pm = yosou.pacemaker;
          gyou.add(
            '${ikkuPaceMidashiMoji[yosou.midashi]}'
            '(${_senshuMei(pm.name, pm.gakunen, sortedUniv, pm.univid)}が引っ張る見込み。'
            '${ikkuTimeMoji(yosou.pace)}前後)',
          );
          gyou.add(ikkuAishouYosouMoji(a));
        }
        final String taikou = _taikouMoji(yosou, sortedUniv);
        if (taikou.isNotEmpty) gyou.add('ほかに引っ張るかもしれない選手: $taikou');
        final String chousi = s.chousi == 0 ? '【体調不良】' : '調子${s.chousi}';
        final String shirushi = [
          if (id == motoSenshuId) '区間エントリーどおり',
          if (id == sentakuchuuId) '選択中',
        ].join('・');
        naiyou.add(
          _IkkuPaceWaku(
            midashi:
                '${s.name}(${s.gakunen}年) $chousi${shirushi.isEmpty ? '' : '($shirushi)'}',
            gyou: gyou,
            iro: id == sentakuchuuId
                ? Colors.lightBlueAccent
                : Colors.white70,
          ),
        );
      }
    }
    if (naiyou.isEmpty) {
      naiyou.add(
        const Text(
          '予想を出せませんでした',
          style: TextStyle(color: HENSUU.textcolor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('1区の候補を比べる', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 集団走設定でその日の勢いがあるとき(「なし」以外)は、カリスマが一番高くても、
          // カリスマの近い選手が引っ張ることがあるので言い切らない(1.9.3)
          Text(
            '1区の選手だけを入れ替えたときの、1区の集団のペースの予想です。'
            '${(kantoku != null && shuudanIkioiHaba(kantoku) == 0) ? '入れる選手のカリスマが一番高ければ、その選手が集団を引っ張ります。' : '入れる選手のカリスマが一番高ければ、その選手が集団を引っ張る見込みです。ただし、カリスマの近い選手がいると、その日の勢いで別の選手が引っ張ることがあります(「ほかに引っ張るかもしれない選手」に出ます)。'}',
            style: const TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),
          ...naiyou,
          const SizedBox(height: 8),
          const Text(
            '・他大学が当日変更で1区の選手を入れ替えたり、他大学の選手が飛び出したりすると、ペースが変わることがあります',
            style: TextStyle(
              color: Colors.white70,
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1区の集団のペースの結果の枠(2区の指示の画面)
class IkkuPaceKekkaBox extends StatelessWidget {
  /// 学連選抜の監督をしているときはtrue(学連選抜の選手の結果を出す)
  final bool gakurenKantoku;

  const IkkuPaceKekkaBox({super.key, this.gakurenKantoku = false});

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (gh == null || kantoku == null) return const SizedBox.shrink();
    final int race = gh.hyojiracebangou;
    if (!ikkuPaceTaishou(race) || gh.nowracecalckukan != 1) {
      return const SizedBox.shrink();
    }
    final IkkuPaceKekka? kekka = ikkuPaceKekkaYomu(kantoku, gh);
    if (kekka == null) return const SizedBox.shrink();
    final List<SenshuData> sortedSenshu = _sortedSenshu();
    final List<UnivData> sortedUniv = _sortedUniv();

    String senshuMeiId(int? id) {
      if (id == null || id < 0 || id >= sortedSenshu.length) return '';
      final SenshuData s = sortedSenshu[id];
      return _senshuMei(s.name, s.gakunen, sortedUniv, s.univid);
    }

    final List<String> gyou = [];
    // 答え合わせ(1区の指示の画面と同じ予想)
    final int? yosou = kekka.yosouMidashi;
    if (yosou != null) {
      gyou.add(
        yosou == kekka.midashi
            ? '予想どおりでした(予想: ${ikkuPaceMidashiMoji[yosou]})'
            : '予想(${ikkuPaceMidashiMoji[yosou]})とちがいました',
      );
      if (kekka.yosouPacemakerId != null &&
          kekka.yosouPacemakerId != kekka.pacemakerId) {
        gyou.add('・予想では、${senshuMeiId(kekka.yosouPacemakerId)}が引っ張る見込みでした');
      }
    }
    final String pm = senshuMeiId(kekka.pacemakerId);
    if (pm.isNotEmpty) gyou.add('集団を引っ張った選手: $pm');
    gyou.add('ペース: ${ikkuPaceMoji(gh, race, kekka.pace)}');
    final List<int> k = kekka.kazu;
    gyou.add(
      '1区の選手: 集団のペースが遅くタイム損${k[0]}人・少しタイム得${k[1]}人・'
      '損得なし${k[2]}人・大失速${k[3]}人・飛び出し${k[4]}人',
    );

    // 自分の大学の選手(学連選抜の監督をしているときは、学連選抜の選手)
    if (gakurenKantoku) {
      for (final Senshu_Gakuren_Data s in Hive.box<Senshu_Gakuren_Data>(
        'gakurenSenshuBox',
      ).values) {
        if (race >= s.entrykukan_race.length) continue;
        final int gi = s.gakunen - 1;
        if (gi < 0 || gi >= s.entrykukan_race[race].length) continue;
        if (s.entrykukan_race[race][gi] != 0) continue;
        for (final String setsumei in ikkuSetsumeiGyou(s.string_racesetumei)) {
          gyou.add('学連選抜の${s.name}(${s.gakunen}年): $setsumei');
        }
      }
    } else {
      for (final SenshuData s in sortedSenshu) {
        if (s.univid != gh.MYunivid) continue;
        if (race >= s.entrykukan_race.length) continue;
        final int gi = s.gakunen - 1;
        if (gi < 0 || gi >= s.entrykukan_race[race].length) continue;
        if (s.entrykukan_race[race][gi] != 0) continue;
        for (final String setsumei in ikkuSetsumeiGyou(s.string_racesetumei)) {
          gyou.add('自分の大学の${s.name}(${s.gakunen}年): $setsumei');
        }
      }
    }

    return _IkkuPaceWaku(
      midashi: '1区は${ikkuPaceMidashiMoji[kekka.midashi]}でした',
      gyou: gyou,
      iro: Colors.amberAccent,
    );
  }
}
