import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 若いOBの監督・コーチ(2.0.1)
//
// 年度替わり(RetireNew)で自動で選ぶ監督・コーチには年齢の条件がある(監督は35+(id%10)歳以上、
// コーチは30+(id%10)歳以上。どちらも65+(id%10)歳まで)。新しいゲームではOBが22歳から始まるので、
// 監督は最初の十数年いなかった。監督の母校パイプ(bokou_pipe.dart)が長く効かないので、
// 今まで通りに選んでも席が空いたままなら、年齢に関係なく、その大学のOBから就任させる。
// ・ゲームの2年目(最初の卒業生が出た年度替わり)から。新しいゲームでは、最初に卒業する4年生は
//   全員日本人(留学生は1年生)なので、どの大学にもOBが5人いて、3つの席が埋まる
// ・全大学が対象(自分の大学も。気に入らなければ進言で代えられる。進言した席は印(KantokuData.yobiint0)が
//   付いていて毎年空けないので、ここでは埋めない(空いている席だけを埋める))
// ・選ぶ順番は、今の選び方と同じ(監督は記録の全体順位の合計、トラックのコーチは5000m・10000m、
//   長距離のコーチはハーフ・フルの記録)。同じ人を、その大学のほかの席と重ねない
// ・今の選び方と同じく、毎年選び直す(据え置きはしない。開発中は据え置きにしていたが、今の選び方と
//   同じ動きのほうが分かりやすいので、選び直しにした)。代わるのは、記録のより良いOBが卒業した年など。
//   年齢の条件に合うOBが出てくれば、その席は今まで通りの選び方になる
// ・監督の席は、コーチの年齢の条件(30+(id%10)歳以上)に合うOBを先に候補にする(いなければ若いOBから)。
//   監督の条件に合うOBがいない数年の間に、年上のコーチを若い監督が率いる形が全大学でそろって起きないように。
//   そのため、去年のコーチが監督になる「昇格」や、記録のより良いOBが30歳になった年に前の監督がコーチに回る
//   「降格」も起きる(35歳を過ぎてからの今の選び方と同じ動き)
// ・年齢の上限(65+(id%10)歳)は今まで通り守る(加齢で退任した人を、ここで戻さない)
// ・RetireNew の監督・トラックのコーチ・長距離のコーチを選んだそれぞれの直後に呼ぶ(席ごとに呼ぶので、
//   監督が先に席を押さえ、コーチの選考で監督と同じ人が選ばれることがない)
// ・就任・退任の記録(選手画面の監督・コーチ就任退任履歴)と、席が代わった印(KantokuData.yobiint1。
//   4月5日の「監督・コーチ陣に変更があったようです」)は、今の処理と同じ形で書く。
//   年齢の条件に合うOBに代わったときは、今の処理が若い人の退任を書かないので、ここで書く
// ------------------------------------------------------------

/// 席の名前(0=監督・1=コーチ(トラック)・2=コーチ(長距離))
const List<String> _sekiMei = ['監督', 'コーチ(トラック)', 'コーチ(長距離)'];

/// 席[seki]の、自動で選ぶときの年齢の下限(RetireNew と同じ)
int _nenreiKagen(int seki, Senshu_R_Data o) => (seki == 0 ? 35 : 30) + (o.id % 10);

/// 自動で選ぶときの年齢の上限(RetireNew と同じ。これを過ぎると加齢で退任する)
int _nenreiJougen(Senshu_R_Data o) => 65 + (o.id % 10);

int _nenrei(Ghensuu gh, Senshu_R_Data o) => gh.year - o.sijiflag + 22;

/// 席[seki]の選ぶ順番の値(小さいほど先。RetireNew と同じ)
double _jun(int seki, Senshu_R_Data o) {
  switch (seki) {
    case 0:
      return (o.zentaijuni_bestkiroku[0] +
              o.zentaijuni_bestkiroku[1] +
              o.zentaijuni_bestkiroku[2] +
              o.zentaijuni_bestkiroku[3])
          .toDouble();
    case 1:
      return o.time_bestkiroku[0] * 2 + o.time_bestkiroku[1];
    default:
      return o.time_bestkiroku[2] * 2 + o.time_bestkiroku[3];
  }
}

/// 大学[univid]の席[seki](0=監督・1=コーチ(トラック)・2=コーチ(長距離))が、今まで通りに選んでも
/// 空いたままなら、年齢の下限に関係なく、その大学のOBから就任させる(保存もする)。
/// 監督の席は、コーチの年齢の条件に合うOBを先に候補にする。
/// [lastrid] は去年この席にいた人(0はいない。RetireNew の lastrid0〜2。就任・退任の記録に使う)。
/// RetireNew で、その席を選んだ直後に呼ぶ
Future<void> wakateShuunin({
  required KantokuData kantoku,
  required Ghensuu ghensuu,
  required List<UnivData> sortedUnivData,
  required int univid,
  required int seki,
  required int lastrid,
}) async {
  if (seki < 0 || seki > 2 || univid < 0 || univid >= TEISUU.UNIVSUU) return;
  final int idx = univid + seki * TEISUU.UNIVSUU;
  if (kantoku.rid.length <= univid + 2 * TEISUU.UNIVSUU) return;
  if (!Hive.isBoxOpen('retiredSenshuBox')) return;
  final Box<Senshu_R_Data> box = Hive.box<Senshu_R_Data>('retiredSenshuBox');
  final String univMei = univid < sortedUnivData.length ? sortedUnivData[univid].name : '';
  final String yakushoku = _sekiMei[seki];

  Senshu_R_Data? mae; // 去年この席にいた人
  if (lastrid > 0) {
    for (final Senshu_R_Data o in box.values) {
      if (o.id == lastrid) {
        mae = o;
        break;
      }
    }
  }

  Future<void> taininKaku(Senshu_R_Data o) async {
    o.string_racesetumei +=
        "${ghensuu.year}年${ghensuu.month}月(${_nenrei(ghensuu, o)}歳) $univMei大学$yakushokuを退任\n";
    await o.save();
  }

  // 今まで通りに選んで席が埋まったとき: 去年の若い人(年齢の条件に合わない人)が代わったなら、
  // 今の処理はその人の退任を書かないので、ここで書く
  if (kantoku.rid[idx] != 0) {
    final Senshu_R_Data? m = mae;
    if (m != null &&
        kantoku.rid[idx] != m.id &&
        _nenrei(ghensuu, m) < _nenreiKagen(seki, m)) {
      // (年齢の条件の下限より若い人だけ。条件に合う人の退任は、今の処理が書く)
      await taininKaku(m);
    }
    return;
  }

  // 空いたまま: その大学のOB(留学生を除く。ほかの席の人を除く)から選ぶ
  final Set<int> hokaNoSeki = {
    for (int k = 0; k < 3; k++)
      if (k != seki && kantoku.rid[univid + k * TEISUU.UNIVSUU] != 0)
        kantoku.rid[univid + k * TEISUU.UNIVSUU],
  };
  // (年齢の上限を過ぎた人は除く。加齢で退任した人を戻さないように)
  final List<Senshu_R_Data> kouho = [
    for (final Senshu_R_Data o in box.values)
      if (o.univid == univid &&
          o.hirou != 1 &&
          !hokaNoSeki.contains(o.id) &&
          _nenrei(ghensuu, o) <= _nenreiJougen(o))
        o,
  ];
  if (kouho.isEmpty) return;
  // 監督の席は、コーチの年齢の条件(30+(id%10)歳以上)に合うOBを先に候補にする(いなければ若いOBから)
  List<Senshu_R_Data> narabe = kouho;
  if (seki == 0) {
    final List<Senshu_R_Data> nenchou = [
      for (final Senshu_R_Data o in kouho)
        if (_nenrei(ghensuu, o) >= _nenreiKagen(1, o)) o,
    ];
    if (nenchou.isNotEmpty) narabe = nenchou;
  }
  // 記録の順(今の選び方と同じ)で一番の人
  narabe.sort((a, b) {
    final int c = _jun(seki, a).compareTo(_jun(seki, b));
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  final Senshu_R_Data erabu = narabe.first;
  kantoku.rid[idx] = erabu.id;
  if (erabu.id != lastrid) {
    kantoku.yobiint1[idx] = 1; // 異動あったフラグ(今の処理と同じ)
    // 去年の人の退任(今の処理は、だれも選べなかったときは書かないので、ここで書く。
    // 加齢で退任した人は、今の処理が「加齢を理由に退任」と書いているので書かない)
    final Senshu_R_Data? m = mae;
    if (m != null && _nenrei(ghensuu, m) <= _nenreiJougen(m)) await taininKaku(m);
    erabu.string_racesetumei +=
        "${ghensuu.year}年${ghensuu.month}月(${_nenrei(ghensuu, erabu)}歳) $univMei大学$yakushokuに就任\n";
    await erabu.save();
  }
  await kantoku.save();
}
