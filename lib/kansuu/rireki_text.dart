import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart';

// ------------------------------------------------------------
// 駅伝出場履歴(選手ごと)のテキスト(1.8.2)
// エントリーや区間配置の相談で生成AIに渡せるように、選手ごとに出場した大会だけを1行に並べる。
// ・自分の大学など(駅伝出場履歴一覧(選手ごと)の画面のコピー、生成AIに渡すテキスト)
// ・学連選抜のメンバー(元の大学で出場した履歴。生成AIに渡すテキスト)
// ------------------------------------------------------------

// 1年の中で大会が行われる順
// (11月駅伝予選(6月)→10月駅伝→正月駅伝予選→11月駅伝→正月駅伝→カスタム駅伝)
const List<int> _raceJun = [3, 0, 4, 1, 2, 5];

const String _rirekiChuui =
    '※出場した大会だけを、選手ごとに1行で並べています。「(○年)」は出場したときの学年、順位は区間順位(予選は予選での順位)、タイムはその区間(組・予選)のタイムです。\n'
    '※「学連選抜で○位相当」は、正月駅伝に学連選抜(オープン参加)として走ったときの区間順位相当(大学の中に入れた場合の順位)です。「○区→当日変更で補員」は、区間にエントリーされたものの当日変更で走らなかったことを表します。\n'
    '※今年これから走る大会(まだ結果が出ていないもの)は入っていません。\n';

/// 大会の名前(0〜5。カスタム駅伝は設定した名前)
List<String> _raceMei() => [for (int r = 0; r < 6; r++) courseRaceTitle(r)];

/// 選手1人の駅伝出場履歴(出場した大会だけを「 / 」でつなぐ。なければ「出場なし」)
/// まだ走っていない大会(今年これから走る大会や、エントリーの途中のもの)は入れない
String _rirekiNaiyou({
  required int gakunen,
  required List<List<int>> entry,
  required List<List<int>> juni,
  required List<List<double>> time,
  required List<String> raceMei,
}) {
  final List<String> list = [];
  for (int g = 0; g < gakunen && g < 4; g++) {
    for (final int race in _raceJun) {
      if (entry.length <= race ||
          juni.length <= race ||
          time.length <= race ||
          entry[race].length <= g ||
          juni[race].length <= g ||
          time[race].length <= g) {
        continue;
      }
      final int kukan = entry[race][g];
      final String taikai = '${raceMei[race]}(${g + 1}年)';
      if (kukan >= 0) {
        final double t = time[race][g];
        if (!(t > 0 && t < TEISUU.DEFAULTTIME)) continue;
        final int j = juni[race][g];
        final String juniBun = (race == 2 && j >= 100)
            ? '学連選抜で${j - 100 + 1}位相当'
            : '${j + 1}位';
        final String basho = race == 3
            ? '${kukan + 1}組 '
            : (race == 4 ? '' : '${kukan + 1}区 ');
        list.add('$taikai $basho$juniBun ${TimeDate.timeToFunByouString(t)}');
      } else if (kukan <= -100) {
        // 当日変更で外れた(-(100+区間))
        final int moto = kukan.abs() - 100 + 1;
        list.add(
          race == 4
              ? '$taikai 当日変更で補員'
              : '$taikai $moto${race == 3 ? '組' : '区'}→当日変更で補員',
        );
      }
    }
  }
  return list.isEmpty ? '出場なし' : list.join(' / ');
}

/// 大学[univId]の選手の駅伝出場履歴(選手ごと)のテキスト
/// (駅伝出場履歴一覧(選手ごと)の画面と同じく、学年の高い順)
String ekidenRirekiText({required int univId}) {
  final List<String> raceMei = _raceMei();
  String univName = '';
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == univId) univName = u.name;
  }
  final List<SenshuData> senshuList =
      Hive.box<SenshuData>('senshuBox').values
          .where((s) => s.univid == univId)
          .toList()
        ..sort((a, b) {
          final int gakunenHikaku = b.gakunen.compareTo(a.gakunen);
          return gakunenHikaku != 0 ? gakunenHikaku : a.id.compareTo(b.id);
        });

  final StringBuffer sb = StringBuffer();
  sb.write(_rirekiChuui);
  sb.writeln('【$univName大学 駅伝出場履歴(選手ごと)】');
  for (final SenshuData s in senshuList) {
    final String naiyou = _rirekiNaiyou(
      gakunen: s.gakunen,
      entry: s.entrykukan_race,
      juni: s.kukanjuni_race,
      time: s.kukantime_race,
      raceMei: raceMei,
    );
    sb.writeln('${s.name}(${s.gakunen}年):$naiyou');
  }
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}

/// 学連選抜のメンバーの駅伝出場履歴(選手ごと)のテキスト(今年の学連選抜がいないときは空)
/// 元の大学で出場した履歴を、走る区間の順(補欠は最後)に、所属大学つきで並べる
String gakurenEkidenRirekiText(Ghensuu gh) {
  if (!gakurenKonnenAri(gh)) return '';
  final List<String> raceMei = _raceMei();
  final Map<int, String> univMei = {
    for (final u in Hive.box<UnivData>('univBox').values) u.id: u.name,
  };
  // 履歴は元の選手のデータを使う(学連選抜で走った結果も、レースの後はこちらに入る)
  final Map<int, SenshuData> motoSenshu = {
    for (final s in Hive.box<SenshuData>('senshuBox').values) s.id: s,
  };
  final int kukansuu = gh.kukansuu_taikaigoto[2];
  int narabi(Senshu_Gakuren_Data s) {
    final int e = gakurenEntry(s);
    return (e >= 0 && e < kukansuu) ? e : 100;
  }

  final List<Senshu_Gakuren_Data> member =
      Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox').values.toList()
        ..sort((a, b) {
          final int kukanHikaku = narabi(a).compareTo(narabi(b));
          if (kukanHikaku != 0) return kukanHikaku;
          final int gakunenHikaku = b.gakunen.compareTo(a.gakunen);
          return gakunenHikaku != 0 ? gakunenHikaku : a.id.compareTo(b.id);
        });

  final StringBuffer sb = StringBuffer();
  sb.writeln(
    '※学連選抜は、正月駅伝に出場できなかった大学の選手で作るオープン参加のチームです。ここに並べるのは、メンバーが元の大学などで出場した駅伝の履歴です。',
  );
  sb.write(_rirekiChuui);
  sb.writeln('【正月駅伝 学連選抜(オープン参加) メンバーの駅伝出場履歴(選手ごと)】');
  for (final Senshu_Gakuren_Data s in member) {
    final int n = narabi(s);
    final String kukanMei = n < 100 ? '${n + 1}区' : '補欠';
    final SenshuData? moto = motoSenshu[s.id];
    final String naiyou = moto != null
        ? _rirekiNaiyou(
            gakunen: moto.gakunen,
            entry: moto.entrykukan_race,
            juni: moto.kukanjuni_race,
            time: moto.kukantime_race,
            raceMei: raceMei,
          )
        : _rirekiNaiyou(
            gakunen: s.gakunen,
            entry: s.entrykukan_race,
            juni: s.kukanjuni_race,
            time: s.kukantime_race,
            raceMei: raceMei,
          );
    sb.writeln(
      '$kukanMei ${s.name}(${s.gakunen}年・${univMei[s.univid] ?? '---'}大学):$naiyou',
    );
  }
  sb.writeln('#箱庭小駅伝SS');
  return sb.toString();
}
