import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/rekidai_kiroku.dart'; // 歴代10位までの記録
import 'package:ekiden/kansuu/custom_seigen.dart' show customRaceBangou;
import 'package:ekiden/kansuu/taikai_chouki.dart' show ouroRace, fukuroRace;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show jikanMoji;

// ------------------------------------------------------------
// 大学画面の歴代記録(2.1.4)
//
// ・大学画面はどの大学でも開けるが、学内記録は総監督をしている大学の分しかないので、どの大学でも出せる
//   全体の歴代10位以内の記録を、記録に残っている大学名で探す(記録には大学の番号がないため。
//   大学名を変えた大学は、変える前の記録が出ない。記録は出したときの名前で残す)
// ・各駅伝の欄の1行(univTaikaiKirokuGyou): その大学の一番良い総合記録(正月駅伝の往路・復路も)
//   ・全体の歴代10位以内にあれば、その順位とタイム(「大会記録 歴代2位 10時間41分07秒(2031年)」)
//   ・なければ、学内記録の1位(「学内記録 …(2029年)」)と直近10回の中で一番速いタイム
//     (「直近10回の最高 …(3回前)」)の速い方。チームの学内記録は2.1.4から全大学で付けるが、2.1.3までの
//     セーブデータのほかの大学は付け始めたばかりなので、直近10回の中にもっと速いタイムがあることがある。
//     学内記録がない(リセットした・付け始めたばかり)ときも直近10回の最高。直近10回のタイムには年が
//     残っていないので、何回前かで書く。11回より前のタイムは残っていないので「大学最高」とは書かない
//   ・大会記録の並びがない予選と対校戦には出さない
// ・「この大学の歴代記録」の表(univRekidaiIchiran): 全体の歴代10位以内(日本人と留学生を合わせた並び。
//   個人記録は一人1件。記録画面の「すべて」の行と同じ)に入っている、この大学の個人記録と区間記録(個人記録が先)。
//   1つの並びに何件もあるときは、一番上の1件を出し、ほかの件数を添える
// ・同じ窓の学内記録の表(univGakunaiIchiran): 種目・区間ごとの学内記録の1位(2.1.4から全大学で付ける。個人記録が先)。
//   1位が留学生のときは、日本人の1位の行も添える
// ・思わぬデータに当たっても画面が止まらないよう、失敗したら何も出さない
// ------------------------------------------------------------

/// 大学画面の欄に大会記録の1行を出す大会(10月・11月・正月・カスタム駅伝と、正月駅伝の往路・復路)
const List<int> univTaikaiKirokuRace = [0, 1, 2, customRaceBangou, ouroRace, fukuroRace];

bool _timeAri(double t) => t > 0 && t < TEISUU.DEFAULTTIME;

/// 大学[u]の大会[race]の一番良い総合記録の1行(出せなければnull)
String? univTaikaiKirokuGyou(Ghensuu gh, UnivData u, int race) {
  if (!univTaikaiKirokuRace.contains(race)) return null;
  try {
    // 全体の歴代10位以内
    final List<RekidaiKiroku> zentai = gh.time_zentaitaikaikiroku.length > race
        ? rekidaiZentaiTaikai(gh, race).yomu()
        : const <RekidaiKiroku>[];
    final int zIchi = zentai.indexWhere((x) => x.univname == u.name && _timeAri(x.time));
    if (zIchi >= 0) {
      final RekidaiKiroku x = zentai[zIchi];
      final String mei = race == ouroRace
          ? '往路記録'
          : race == fukuroRace
          ? '復路記録'
          : '大会記録';
      return '$mei 歴代${zIchi + 1}位 ${jikanMoji(x.time)}(${x.year}年)';
    }
    // 学内記録の1位(2.1.4から全大学で付ける)
    RekidaiKiroku? gakunai1;
    if (u.time_univtaikaikiroku.length > race) {
      final List<RekidaiKiroku> gakunai = rekidaiUnivTaikai(u, race).yomu();
      if (gakunai.isNotEmpty && _timeAri(gakunai.first.time)) gakunai1 = gakunai.first;
    }
    // 直近10回の中で一番速いタイム(0が前回)
    int saisoku = -1;
    final List<double> l = u.time_race.length > race ? u.time_race[race] : const <double>[];
    for (int i = 0; i < l.length && i < TEISUU.KIROKUHOZONNENSUU; i++) {
      if (!_timeAri(l[i])) continue;
      if (saisoku < 0 || l[i] < l[saisoku]) saisoku = i;
    }
    // 速い方(同じなら学内記録)
    if (gakunai1 != null && (saisoku < 0 || gakunai1.time <= l[saisoku])) {
      return '学内記録 ${jikanMoji(gakunai1.time)}(${gakunai1.year}年)';
    }
    if (saisoku < 0) return null;
    final String itsu = saisoku == 0 ? '前回' : '${saisoku + 1}回前';
    return '直近10回の最高 ${jikanMoji(l[saisoku])}($itsu)';
  } catch (_) {
    return null;
  }
}

/// 「この大学の歴代記録」の表の1行
class UnivRekidaiGyou {
  const UnivRekidaiGyou({
    required this.shumoku,
    required this.time,
    required this.senshu,
    required this.bangou,
    required this.juni,
    required this.hoka,
  });

  /// 種目・区間(「正月駅伝5区」「5000m」)
  final String shumoku;

  /// タイム
  final String time;

  /// 選手(「山本 翔(4年)」。学年は記録を出したとき)
  final String senshu;

  /// 選手の通算の番号(2.1.4より前の記録はnull。選手名のリンクに使う)
  final int? bangou;

  /// 全体の歴代の順位(0が1位)
  final int juni;

  /// 同じ並びに入っている、この大学のほかの記録の数
  final int hoka;

  /// 順位のマスの文字(「4位 他1件」)
  String get juniMoji => '${juni + 1}位${hoka > 0 ? ' 他$hoka件' : ''}';
}

/// 個人記録の種目の並び(記録画面と同じく、夏のTTはロード・登り・下り・クロカンの順)
const List<int> _kojinJun = [0, 1, 2, 3, 6, 4, 5, 7];
const Map<int, String> _kojinMei = {
  0: '5000m',
  1: '1万m',
  2: 'ハーフ',
  3: 'フル',
  4: '登り1万',
  5: '下り1万',
  6: 'ロード1万',
  7: 'クロカン1万',
};

/// 大学[u]の、全体の歴代10位以内に入っている個人記録と区間記録(なければ空。個人記録が先)
List<UnivRekidaiGyou> univRekidaiIchiran(Ghensuu gh, UnivData u) {
  try {
    if (!Hive.isBoxOpen('kirokuBox') || !Hive.isBoxOpen('univBox')) return const [];
    final Kiroku? kiroku = Hive.box<Kiroku>('kirokuBox').get('KirokuData');
    if (kiroku == null) return const [];
    final List<UnivRekidaiGyou> gyou = [];
    // 並び[l]の中の、この大学の一番上の記録の行
    void ireru(String shumoku, List<RekidaiKiroku> l) {
      final List<int> ichi = [
        for (int i = 0; i < l.length; i++)
          if (l[i].univname == u.name && _timeAri(l[i].time)) i,
      ];
      if (ichi.isEmpty) return;
      final RekidaiKiroku x = l[ichi.first];
      gyou.add(
        UnivRekidaiGyou(
          shumoku: shumoku,
          time: jikanMoji(x.time),
          senshu: '${x.name}(${x.gakunen}年)',
          bangou: x.bangou,
          juni: ichi.first,
          hoka: ichi.length - 1,
        ),
      );
    }

    // 個人記録(一人1件。選手画面の歴代記録の表と同じく、個人記録を先にする)
    for (final int k in _kojinJun) {
      ireru(
        _kojinMei[k] ?? '',
        rekidaiAwaseru(
          ichii: ichiiZentaiKojin(gh, k).yomu(),
          nihonjin: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, false, k).yomu()),
          ryuugakusei: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, true, k).yomu()),
          hitoriIkken: true,
        ),
      );
    }
    // 駅伝の区間記録(記録画面と同じ区間の数)
    final UnivData? custom = Hive.box<UnivData>('univBox').get(0);
    for (final int race in const [0, 1, 2, customRaceBangou]) {
      final int kukansuu = race == customRaceBangou
          ? (gh.kukansuu_taikaigoto.length > race ? gh.kukansuu_taikaigoto[race] : 0)
          : const [6, 8, 10][race];
      for (int kk = 0; kk < kukansuu && kk < TEISUU.SUU_MAXKUKANSUU; kk++) {
        ireru(
          '${_raceMei(race, custom)}${kk + 1}区',
          rekidaiAwaseru(
            ichii: ichiiZentaiKukan(gh, race, kk).yomu(),
            nihonjin: rekidaiZentaiKukan(kiroku, false, race, kk).yomu(),
            ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, kk).yomu(),
          ),
        );
      }
    }
    return gyou;
  } catch (_) {
    return const [];
  }
}

String _raceMei(int race, UnivData? custom) {
  switch (race) {
    case 0:
      return '10月駅伝';
    case 1:
      return '11月駅伝';
    case 2:
      return '正月駅伝';
    default:
      final String mei = custom?.name_tanshuku.trim() ?? '';
      return mei.isEmpty ? 'カスタム駅伝' : mei;
  }
}

/// 「この大学の歴代記録」の窓の、学内記録(1位)の表の1行
class UnivGakunaiGyou {
  const UnivGakunaiGyou({
    required this.shumoku,
    required this.time,
    required this.senshu,
    required this.bangou,
    required this.nen,
  });

  /// 種目・区間(「正月駅伝5区」「5000m」。日本人の1位の行は「5000m(日本人)」)
  final String shumoku;

  /// タイム
  final String time;

  /// 選手(「山本 翔(4年)」。学年は記録を出したとき)
  final String senshu;

  /// 選手の通算の番号(2.1.4より前の記録はnull。選手名のリンクに使う)
  final int? bangou;

  /// 記録を出した年(「2031年」)
  final String nen;
}

/// 大学[u]の、種目・区間ごとの学内記録の1位(記録がなければ空。個人記録が先。1位が留学生なら、日本人の1位の行も添える)
List<UnivGakunaiGyou> univGakunaiIchiran(Ghensuu gh, UnivData u) {
  try {
    if (!Hive.isBoxOpen('kirokuBox') || !Hive.isBoxOpen('univBox')) return const [];
    final Kiroku? kiroku = Hive.box<Kiroku>('kirokuBox').get('KirokuData');
    if (kiroku == null) return const [];
    if (u.id < 0 ||
        u.id >= kiroku.time_univ_jap_kukankiroku.length ||
        u.id >= kiroku.time_univ_jap_kojinkiroku.length) {
      return const [];
    }
    final List<UnivGakunaiGyou> gyou = [];
    UnivGakunaiGyou gyouNi(String shumoku, RekidaiKiroku x) => UnivGakunaiGyou(
      shumoku: shumoku,
      time: jikanMoji(x.time),
      senshu: '${x.name}(${x.gakunen}年)',
      bangou: x.bangou,
      nen: '${x.year}年',
    );
    // [subete] すべての並び、[nihonjin] 日本人の並び
    void ireru(String shumoku, List<RekidaiKiroku> subete, List<RekidaiKiroku> nihonjin) {
      if (subete.isEmpty || !_timeAri(subete.first.time)) return;
      final RekidaiKiroku ichii = subete.first;
      gyou.add(gyouNi(shumoku, ichii));
      if (nihonjin.isEmpty || !_timeAri(nihonjin.first.time)) return;
      final RekidaiKiroku n = nihonjin.first;
      // 1位が日本人の1位と同じ記録なら、日本人の行は添えない
      if (n.time == ichii.time && n.onajiHito(ichii)) return;
      gyou.add(gyouNi('$shumoku(日本人)', n));
    }

    // 個人記録(一人1件。選手画面の歴代記録の表と同じく、個人記録を先にする)
    for (final int k in _kojinJun) {
      if (u.time_univkojinkiroku.length <= k) continue;
      final List<RekidaiKiroku> nihonjin =
          rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, false, u.id, k).yomu());
      ireru(
        _kojinMei[k] ?? '',
        rekidaiAwaseru(
          ichii: ichiiUnivKojin(u, k).yomu(),
          nihonjin: nihonjin,
          ryuugakusei: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, true, u.id, k).yomu()),
          hitoriIkken: true,
        ),
        nihonjin,
      );
    }
    // 駅伝の区間記録(記録画面と同じ区間の数)
    final UnivData? custom = Hive.box<UnivData>('univBox').get(0);
    for (final int race in const [0, 1, 2, customRaceBangou]) {
      if (u.time_univkukankiroku.length <= race) continue;
      final int kukansuu = race == customRaceBangou
          ? (gh.kukansuu_taikaigoto.length > race ? gh.kukansuu_taikaigoto[race] : 0)
          : const [6, 8, 10][race];
      for (int kk = 0; kk < kukansuu && kk < TEISUU.SUU_MAXKUKANSUU; kk++) {
        final List<RekidaiKiroku> nihonjin =
            rekidaiUnivKukan(kiroku, false, u.id, race, kk).yomu();
        ireru(
          '${_raceMei(race, custom)}${kk + 1}区',
          rekidaiAwaseru(
            ichii: ichiiUnivKukan(u, race, kk).yomu(),
            nihonjin: nihonjin,
            ryuugakusei: rekidaiUnivKukan(kiroku, true, u.id, race, kk).yomu(),
          ),
          nihonjin,
        );
      }
    }
    return gyou;
  } catch (_) {
    return const [];
  }
}
