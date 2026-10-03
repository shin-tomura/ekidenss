import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';

// ------------------------------------------------------------
// 学連選抜のテキスト(1.8.2)
// 学連選抜の選手は個人順位速報などの表に出ないので、生成AIに渡して実況や相談を
// 楽しめるように、コピー用の文を作る。
// ・学連選抜のレース経過(レース画面・結果画面の学連選抜の欄からコピー)
// ・学連選抜の区間配置(学連選抜の区間配置の画面からコピー)
// ・個人順位速報・通過順位速報・区間配置確認のコピーに学連選抜を混ぜるための部品
// 学連選抜はオープン参加なので、順位は大学の中に入れた場合の「○位相当」で表す。
// ------------------------------------------------------------

const int _raceIndex = 2; // 正月駅伝
const int _yosenIndex = 4; // 正月駅伝予選

/// コピーの最初に付ける、学連選抜(OP)の説明
const String gakurenOpChuui =
    '※「OP」は学連選抜(正月駅伝に出場できなかった大学の選手で作るオープン参加のチーム)です。順位には数えず、「○位相当」は大学の中に入れた場合の順位を表します。\n';

/// 補正の説明の秒数などについての注意書き(ほかの画面のコピーと同じ文)
const String _suutiChuui =
    '※※※陸上競技のタイム計算に関係することなので、【数値が小さいほど優秀】と捉えてください。(「プラス」は悪い数値、「マイナス」は良い数値。ただし、項目によっては仕様上「プラスの数値」しか出ないものもあります。その場合は「いかにプラスの数値を小さく（0に近く）抑えられたか」を高く評価してください。)※※※\n';

/// 表示中のレースに、今年の学連選抜がいるか
/// (正月駅伝のときだけ。1月5日の学連選抜を作る処理(モード200)より前は、
///  去年の学連選抜が残っているので含めない)
bool gakurenKonnenAri(Ghensuu gh) {
  if (gh.hyojiracebangou != _raceIndex) return false;
  if (gh.month == 1 && gh.day == 5 && gh.mode <= 200) return false;
  return Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox').isNotEmpty &&
      Hive.box<UnivGakurenData>('gakurenUnivBox').isNotEmpty;
}

/// 学連選抜の選手が正月駅伝で走る区間(0が1区。補欠は-1)
int gakurenEntry(Senshu_Gakuren_Data s) {
  if (s.gakunen < 1 ||
      s.entrykukan_race.length <= _raceIndex ||
      s.entrykukan_race[_raceIndex].length < s.gakunen) {
    return -1;
  }
  return s.entrykukan_race[_raceIndex][s.gakunen - 1];
}

/// 正月駅伝の区間[kukan]を走る学連選抜の選手(いなければnull)
Senshu_Gakuren_Data? gakurenKukanSenshu(int kukan) {
  for (final s in Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox').values) {
    if (gakurenEntry(s) == kukan) return s;
  }
  return null;
}

/// 大学のidから名前を引く表
Map<int, String> _univMei() {
  return {
    for (final u in Hive.box<UnivData>('univBox').values) u.id: u.name,
  };
}

/// 学連選抜の区間1つ分の結果
class GakurenKukanKekka {
  final Senshu_Gakuren_Data senshu;
  final String shozoku; // 所属大学の名前
  final int kukanJuni; // 区間順位相当(0が1位相当)
  final double kukanTime;
  final int tuukaJuni; // 通過順位相当(0が1位相当)
  final double tuukaTime;
  final int? maeTuukaJuni; // 1つ前の区間の通過順位相当(1区はnull)

  const GakurenKukanKekka({
    required this.senshu,
    required this.shozoku,
    required this.kukanJuni,
    required this.kukanTime,
    required this.tuukaJuni,
    required this.tuukaTime,
    required this.maeTuukaJuni,
  });
}

/// 学連選抜の区間[kukan]の結果(今年の学連選抜がいないときや、まだ走っていない区間はnull)
GakurenKukanKekka? gakurenKukanKekka(Ghensuu gh, int kukan) {
  if (!gakurenKonnenAri(gh)) return null;
  if (kukan < 0 || kukan >= gh.nowracecalckukan) return null;
  final UnivGakurenData u = Hive.box<UnivGakurenData>(
    'gakurenUnivBox',
  ).values.first;
  if (u.time_taikai_total.length <= kukan ||
      u.kukanjuni_taikai.length <= kukan ||
      u.tuukajuni_taikai.length <= kukan) {
    return null;
  }
  final double tuukaTime = u.time_taikai_total[kukan];
  if (tuukaTime <= 0 || tuukaTime >= TEISUU.DEFAULTTIME) return null;
  final double kukanTime = kukan == 0
      ? tuukaTime
      : tuukaTime - u.time_taikai_total[kukan - 1];
  final Senshu_Gakuren_Data? s = gakurenKukanSenshu(kukan);
  if (s == null) return null;
  return GakurenKukanKekka(
    senshu: s,
    shozoku: _univMei()[s.univid] ?? '---',
    kukanJuni: u.kukanjuni_taikai[kukan],
    kukanTime: kukanTime,
    tuukaJuni: u.tuukajuni_taikai[kukan],
    tuukaTime: tuukaTime,
    maeTuukaJuni: kukan == 0 ? null : u.tuukajuni_taikai[kukan - 1],
  );
}

/// 順位の良い順に並んだ大学の順位(0が1位)[juniList]の中で、学連選抜(順位相当[gakurenJuni])を
/// 差し込む位置(順位の数字が学連選抜と同じか大きい、最初の大学の前。なければ最後)
/// 個人順位速報・通過順位速報などの画面の表で使う(コピーの文と同じ位置になる)
int gakurenSounyuuIchi(List<int> juniList, int gakurenJuni) {
  for (int i = 0; i < juniList.length; i++) {
    if (juniList[i] >= gakurenJuni) return i;
  }
  return juniList.length;
}

/// 個人順位速報のコピーに差し込む学連選抜の行
/// (例: OP(8位相当) 62分33秒 山田太郎(3年) 学連選抜(所属:〇〇))
String gakurenKojinSokuhouGyou(GakurenKukanKekka k) {
  return 'OP(${k.kukanJuni + 1}位相当) '
      '${TimeDate.timeToFunByouString(k.kukanTime)} '
      '${k.senshu.name}(${k.senshu.gakunen}年) 学連選抜(所属:${k.shozoku})';
}

/// 学連選抜の監督をしている場合の、監督の行(していなければ空)
String _kantokuGyou() {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (gh == null || kantoku == null) return '';
  UnivData? myUniv;
  for (final u in Hive.box<UnivData>('univBox').values) {
    if (u.id == gh.MYunivid) myUniv = u;
  }
  if (myUniv == null || !gakurenKantokuChuu(kantoku, myUniv)) return '';
  return '監督:プレイヤー(${myUniv.name}大学の監督。${myUniv.name}大学が正月駅伝に出場できなかったため、学連選抜の監督を務める)\n';
}

/// タイム差の文(例: +12秒、-1分5秒)
String _saBun(double sa) {
  final String fugou = sa.isNegative ? '-' : '+';
  final int byou = sa.abs().round();
  if (byou < 60) return '$fugou$byou秒';
  return '$fugou${byou ~/ 60}分${byou % 60}秒';
}

/// 学連選抜の選手の予選の結果(例: 正月駅伝予選12位 63分21秒)
String _yosenBun(Senshu_Gakuren_Data s) {
  if (s.kukanjuni_race.length <= _yosenIndex ||
      s.kukanjuni_race[_yosenIndex].length < s.gakunen) {
    return '';
  }
  final int juni = s.kukanjuni_race[_yosenIndex][s.gakunen - 1] + 1;
  final double time = s.kukantime_race[_yosenIndex][s.gakunen - 1];
  if (time <= 0 || time >= TEISUU.DEFAULTTIME) return '正月駅伝予選$juni位';
  return '正月駅伝予選$juni位 ${TimeDate.timeToFunByouString(time)}';
}

/// 区間[kukan]を走る大学の選手(区間配置確認の「区」の順位と同じ選び方)
List<SenshuData> _kukanDaigakuSenshu(int kukan) {
  return Hive.box<SenshuData>('senshuBox').values.where((s) {
    return s.gakunen >= 1 &&
        s.gakunen <= 4 &&
        s.entrykukan_race.length > _raceIndex &&
        s.entrykukan_race[_raceIndex][s.gakunen - 1] == kukan;
  }).toList();
}

/// 区間配置確認の「全大学詳細リスト」と同じ形で、学連選抜の選手の詳しい情報を書く
/// 持ちタイムの「区」は、その区間を走る大学の選手と比べた順位(○位相当)。補欠は「区」を書かない
void gakurenSenshuShousaiKaku(
  StringBuffer sb,
  Senshu_Gakuren_Data s,
  Ghensuu gh,
) {
  final int kukan = gakurenEntry(s);
  final bool hashiru =
      kukan >= 0 && kukan < gh.kukansuu_taikaigoto[_raceIndex];
  final List<SenshuData> daigaku = hashiru
      ? _kukanDaigakuSenshu(kukan)
      : const <SenshuData>[];
  final String shozoku = _univMei()[s.univid] ?? '---';

  sb.writeln('【学連選抜(OP)】  ${s.name} (${s.gakunen}年) 所属:$shozoku');
  sb.write('  駅伝男:${gh.nouryokumieruflag[0] == 1 ? s.konjou : "??"} ');
  sb.write('平常心:${gh.nouryokumieruflag[1] == 1 ? s.heijousin : "??"} ');
  sb.writeln('調子:${s.chousi}');
  if (hashiru) {
    // 前の学年までに正月駅伝の同じ区間を走った回数(所属大学で走ったもの)
    int keikenkaisuu = 0;
    for (int i_gakunen = 0; i_gakunen < s.gakunen - 1; i_gakunen++) {
      if (s.entrykukan_race[_raceIndex][i_gakunen] == kukan) keikenkaisuu++;
    }
    sb.writeln('  この区間の経験回数:$keikenkaisuu回');
  }
  final String yosen = _yosenBun(s);
  if (yosen.isNotEmpty) sb.writeln('  $yosen');

  String getRec(int idx, bool showRank) {
    if (s.time_bestkiroku.length <= idx ||
        s.time_bestkiroku[idx] == TEISUU.DEFAULTTIME) {
      return "記録無";
    }
    final double time = s.time_bestkiroku[idx];
    String base = TimeDate.timeToFunByouString(time);
    final String gaku = '学:${s.gakunaijuni_bestkiroku[idx] + 1}位';
    if (showRank) {
      final String zen = '全:${s.zentaijuni_bestkiroku[idx] + 1}位';
      if (hashiru) {
        int juni = 1;
        for (final d in daigaku) {
          if (d.time_bestkiroku.length > idx && d.time_bestkiroku[idx] < time) {
            juni++;
          }
        }
        base += " [区:$juni位相当 $gaku $zen]";
      } else {
        base += " [$gaku $zen]";
      }
    } else {
      base += " [$gaku]";
    }
    return base;
  }

  sb.writeln('  5000m: ${getRec(0, true)}');
  sb.writeln('  10000m: ${getRec(1, true)}');
  sb.writeln('  ハーフ: ${getRec(2, true)}');
  sb.writeln('  登り1万: ${getRec(4, false)}');
  sb.writeln('  下り1万: ${getRec(5, false)}');
  sb.writeln('  ロード1万: ${getRec(6, false)}');
  sb.writeln('  クロカン1万: ${getRec(7, false)}');
  sb.writeln("-----------------------------------");
}

/// 区間配置確認の「区」「学」「全」の説明(学連選抜の「区」は○位相当)
const String gakurenKukanJuniChuui =
    '※学連選抜(OP)の選手の「区」は、その区間にエントリーされている大学の選手と比べた場合の、その種目の持ちタイムの順位(○位相当)です。';

/// 学連選抜の区間配置のテキスト(学連選抜の区間配置の画面からコピーする)
String gakurenKukanHaitiText(Ghensuu gh) {
  final int kukansuu = gh.kukansuu_taikaigoto[_raceIndex];
  final List<Senshu_Gakuren_Data> senshu = Hive.box<Senshu_Gakuren_Data>(
    'gakurenSenshuBox',
  ).values.toList();
  final StringBuffer sb = StringBuffer();
  sb.writeln(
    '※学連選抜は、正月駅伝に出場できなかった大学の選手で作るオープン参加のチームです。順位には数えません。',
  );
  sb.writeln('【正月駅伝 学連選抜(オープン参加) 区間配置】');
  sb.write(_kantokuGyou());
  sb.writeln('');
  for (int kukan = 0; kukan < kukansuu; kukan++) {
    final int kyori = gh.kyori_taikai_kukangoto[_raceIndex][kukan].round();
    sb.writeln('=== ${kukan + 1}区(${kyori}m) ===');
    final Senshu_Gakuren_Data? s = gakurenKukanSenshu(kukan);
    if (s == null) {
      sb.writeln('(選手が決まっていません)');
      sb.writeln("-----------------------------------");
    } else {
      gakurenSenshuShousaiKaku(sb, s, gh);
    }
  }
  // 補欠(予選の順位の良い順)
  final List<Senshu_Gakuren_Data> hoketsu =
      senshu.where((s) {
        final int e = gakurenEntry(s);
        return e < 0 || e >= kukansuu;
      }).toList()..sort((a, b) {
        int juni(Senshu_Gakuren_Data s) =>
            s.kukanjuni_race.length > _yosenIndex &&
                s.kukanjuni_race[_yosenIndex].length >= s.gakunen
            ? s.kukanjuni_race[_yosenIndex][s.gakunen - 1]
            : TEISUU.DEFAULTJUNI;
        return juni(a).compareTo(juni(b));
      });
  if (hoketsu.isNotEmpty) {
    sb.writeln('=== 補欠 ===');
    for (final s in hoketsu) {
      gakurenSenshuShousaiKaku(sb, s, gh);
    }
  }
  sb.writeln('');
  sb.writeln(gakurenKukanJuniChuui);
  sb.writeln('※「学」はその種目の所属大学学内での持ちタイムの順位、「全」はその種目の学生全体での持ちタイムの順位です。');
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}

/// 学連選抜の選手の指示の内容と結果の文(レース画面の学連選抜の欄と同じ内容)
List<String> _sijiBun(
  Senshu_Gakuren_Data s,
  int kukan,
  UnivGakurenData u,
) {
  const List<String> kekka = ["失敗", "成功"];
  final List<String> options = kukan == 0
      ? ["指示なし", "スタート直後に飛び出す", "スタート直後は飛び出さない"]
      : ["指示なし", "前半から突っ込む", "前半は抑える"];
  final int sijiflag = s.sijiflag.clamp(0, 2).toInt();
  final List<String> bun = ['指示:${options[sijiflag]}'];
  if (kukan == 0) {
    if (s.startchokugotobidasiflag == 1) {
      bun.add(
        'スタート直後飛び出して:${kekka[s.startchokugotobidasiseikouflag.clamp(0, 1).toInt()]}',
      );
    }
  } else if (sijiflag >= 1) {
    bun.add('結果:${kekka[s.sijiseikouflag.clamp(0, 1).toInt()]}');
  } else if (u.mokuhyojuniwositamawatteruflag.length > kukan - 1 &&
      u.mokuhyojuniwositamawatteruflag[kukan - 1] == 1) {
    bun.add('学連選抜の目標順位を下回っていたことによる前半突っ込みでのタイム悪化あり');
  } else if (u.mokuhyojuniwositamawatteruflag.length > kukan - 1 &&
      u.mokuhyojuniwositamawatteruflag[kukan - 1] < 0) {
    // 目標を上回ったときのほっと一息(学連選抜の監督をしているときだけ)
    bun.add('学連選抜の目標順位を上回っていたことによるほっと一息でのタイム悪化あり');
  }
  return bun;
}

/// 学連選抜のレース経過のテキスト(レース画面・結果画面の学連選抜の欄からコピーする)
/// 走り終えた区間は順位相当・タイム・差・指示と結果・補正の説明、まだの区間は走る選手を書く
String gakurenRaceKeikaText(Ghensuu gh) {
  final int kukansuu = gh.kukansuu_taikaigoto[_raceIndex];
  final bool ari = gakurenKonnenAri(gh);
  final int hashitta = ari ? min(gh.nowracecalckukan, kukansuu) : 0;
  final UnivGakurenData? u = ari
      ? Hive.box<UnivGakurenData>('gakurenUnivBox').values.first
      : null;
  final Map<int, String> univMei = _univMei();
  // 学連選抜の目標順位(0が1位。監督をしているときはプレイヤーが決めた順位、それ以外は10位)
  final int mokuhyou = gakurenMokuhyouGenzai();
  // 正月駅伝に出場している大学(区間ごとのトップと目標順位との差を出すのに使う)
  final List<UnivData> shutsujou = Hive.box<UnivData>('univBox').values
      .where(
        (x) =>
            x.taikaientryflag.length > _raceIndex &&
            x.taikaientryflag[_raceIndex] == 1,
      )
      .toList();

  final StringBuffer sb = StringBuffer();
  sb.write(
    '※学連選抜は、正月駅伝に出場できなかった大学の選手で作るオープン参加のチームです。順位には数えず、「○位相当」は大学の中に入れた場合の順位を表します。\n',
  );
  sb.write(_suutiChuui);
  sb.writeln('【正月駅伝 学連選抜(オープン参加) レース経過】');
  sb.write(_kantokuGyou());
  sb.writeln('学連選抜の目標:${mokuhyou + 1}位相当');
  sb.writeln("-----------------------------------");
  for (int kukan = 0; kukan < kukansuu; kukan++) {
    final int kyori = gh.kyori_taikai_kukangoto[_raceIndex][kukan].round();
    final Senshu_Gakuren_Data? s = gakurenKukanSenshu(kukan);
    if (s == null) {
      sb.writeln('${kukan + 1}区(${kyori}m) (選手が決まっていません)');
      sb.writeln("-----------------------------------");
      continue;
    }
    final String yosen = _yosenBun(s);
    sb.writeln(
      '${kukan + 1}区(${kyori}m) ${s.name}(${s.gakunen}年) '
      '所属:${univMei[s.univid] ?? '---'}${yosen.isEmpty ? '' : ' $yosen'}',
    );
    final GakurenKukanKekka? k = kukan < hashitta
        ? gakurenKukanKekka(gh, kukan)
        : null;
    if (k == null || u == null) {
      sb.writeln('  これから走る');
      sb.writeln("-----------------------------------");
      continue;
    }
    sb.writeln(
      '  区間${k.kukanJuni + 1}位相当 ${TimeDate.timeToFunByouString(k.kukanTime)}',
    );
    String hendou = '';
    if (k.maeTuukaJuni != null) {
      final int sa = k.maeTuukaJuni! - k.tuukaJuni;
      hendou = sa > 0 ? ' ↑$sa' : (sa < 0 ? ' ↓${sa.abs()}' : ' →');
    }
    sb.writeln(
      '  通過${k.tuukaJuni + 1}位相当 '
      '${TimeDate.timeToJikanFunByouString(k.tuukaTime)}$hendou',
    );
    // トップと目標順位(大学の中で)との差
    final List<double> times =
        shutsujou
            .where((x) => x.time_taikai_total.length > kukan)
            .map((x) => x.time_taikai_total[kukan])
            .where((t) => t > 0 && t < TEISUU.DEFAULTTIME)
            .toList()
          ..sort();
    if (times.isNotEmpty) {
      String saGyou = '  (トップとの差:${_saBun(k.tuukaTime - times[0])}';
      if (times.length > mokuhyou) {
        saGyou +=
            '、目標(${mokuhyou + 1}位)との差:${_saBun(k.tuukaTime - times[mokuhyou])}';
      }
      sb.writeln('$saGyou)');
    }
    for (final String bun in _sijiBun(s, kukan, u)) {
      sb.writeln('  $bun');
    }
    if (s.string_racesetumei.trim().isNotEmpty) {
      sb.writeln('  [補正の説明]');
      for (final String gyou in s.string_racesetumei.trimRight().split('\n')) {
        sb.writeln('   $gyou');
      }
    }
    sb.writeln("-----------------------------------");
  }
  if (u != null && hashitta >= kukansuu && kukansuu > 0) {
    final int last = kukansuu - 1;
    sb.writeln(
      '総合:OP ${TimeDate.timeToJikanFunByouString(u.time_taikai_total[last])}'
      '(${u.tuukajuni_taikai[last] + 1}位相当)',
    );
  }
  sb.writeln('');
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}
