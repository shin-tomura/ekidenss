// 駅伝の区間終了時点の位置関係(2.0.6)
// レースの途中の区間ごとの画面(mode 350)と、結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の、
// 区間ごとのタイム分布と1枚にまとめたカード(KukanBunsekiCard。右半分の「位置関係」)から開く。
// ・幅のある道の帯に、大学名を四角で囲んで並べ、1位からの距離を縮尺どおりの間隔で出す。
//   四角の中の大学名は、最後の「大」を省く(下の帯の文は省かない)。学連選抜は四角の中では「OP学連」。
//   大学名の後ろに、前の区間の終了時点からの順位の変化を「↑2」(緑)「↓3」(赤)「→」(灰色)で付ける
//   (1区は付けない。学連選抜は通過順位相当で比べる。下の帯にも「5位(↑3)」の形で出す)。
// ・画面の上で、隣どうしの間が四角1つ分の高さより狭い大学をつなげて集団にし、先頭から最後尾までが
//   四角1つ分より長い集団は、その中で一番大きく空いた間で分ける(並走の大学どうしが別の集団にならないように)。
//   集団は
//   1行に3校まで横に並べる(4校目から次の行に折り返す。拡大すると集団がばらける)。
//   集団の一番上の行は、前の大学(前が集団なら、その一番下の行)から、間の距離ぶん下に置き、
//   集団のあとの大学は、集団の一番下の行を起点にして、集団の最後の大学との間の距離ぶん下に置く。
//   (集団で行を折り返したぶん、そのあとの道は下にずれる。隣どうしの間は縮尺どおり)
//   2校以上の集団は、四角にぴったり合わせた薄い枠で囲む。集団どうしは、枠がくっつかないよう10px以上空ける。
// ・画面の説明の文は短くし(「○区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です」
//   と、括弧・色・押したときのこと)、おまかせと集団の説明は説明書に書く。
// ・道の右に、前の大学(集団)との間を示す括弧を引き、その真ん中に間の距離と秒差(「90m 16秒」)を出す。
//   括弧は、前の集団の一番下の行の真ん中から、次の集団の一番上の行の真ん中まで。集団の中の間は出さない。
//   (1位との差を出していたが、隣どうしの間が縮尺どおりなので、間を出すほうが分かりやすいため、2.0.6の開発中に変えた)
// ・四角と間の文は折り返さず、道と四角と間の文の部分だけを横にもスクロールできるようにする
//   (文字を大きくしても、文の長さで行がずれて、距離と位置が合わなくならないように)。
// ・大学の四角を押すと、その大学の順位・1位との差・前の大学(1位は次の大学)との差を、
//   画面の下(「戻る」の上)に固定した帯に出す。
//   もう一度押すと、帯の中に、その区間を走った選手の説明文(個人順位速報の「説明文」と同じ文)も出し、
//   3回目で、説明文の代わりに次の区間を走る選手(区間配置確認のカードを開いたときと同じ中身。
//   senshu_haichi_panel.dart の部品)を出し、4回目で閉じる。最終区など次の区間の選手がいなければ3回目で閉じる。
//   開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。
//   説明文と次の区間の選手の部分は画面の高さの3割までにし、長いときはその中だけでスクロールする。
//   帯が伸びて押した四角が隠れるときは、道を動かして見えるようにする(2.0.7)。
// ・区間の切り替えと、表示の倍率のボタン・縮尺の棒は、画面の上に固定する(どちらも折り返す)。
//   固定の部分は画面の高さの4割までで、超えるときは固定の部分の中だけでスクロールする。
// ・距離は「1位が区間を走り終えたとき、ほかの大学がどれだけ後ろにいるか」を、その区間の出場校の
//   区間タイムの平均から出した速さ(全員で同じ。学連選抜は平均に入れない)で、タイム差から換算したもの。
//   速さを全員で1つにするので、距離はタイム差に比例し、順位と位置の並びが逆にならない
//   (ゲームとしての見せ方。1位が着いた時点か最後の大学が着いた時点か、などは考えない)。
// ・1区から終わった区間まで切り替えられる(覚えない。開くたびに一番あとの区間)。
// ・前の大学との間のうち、飛び抜けて大きい間(その区間の間の中央値の4倍以上。大きい順に多くて3か所。
//   _tobinukeAida)だけを詰めて、道に切れ目の点線を引き、右の括弧を点線にして「(詰めています)」を添える。
//   倍率ではなくデータで決めるので、
//   だいたい同じくらい空いているときは詰めない。手動で倍率を選んでいるときは、1つの間が
//   画面の高さを超えるところも詰める(拡大しすぎて、何もない道を延々とスクロールしないように)。
//   (最初は「画面で144pxを超えたら」詰めていたが、おまかせの倍率とぶつかり、出場校の少ない大会や
//   差の開いた区間で、ほとんどの間が詰められて位置関係がつかめなかったので、2.0.6の開発中に変えた)
// ・表示の倍率(1mあたりの高さ)は「−」「＋」で6段階に変えられる(文字の大きさは変わらない)。
//   開いたときは「おまかせ」(区間ごとに、詰めた間を除いた1位から最後尾までの長さが、画面の高さの
//   およそ2つ分に収まる一番大きい倍率。大きく遅れた大学に引っぱられて先頭のほうが縮こまらないように)。
//   「−」「＋」を押すとおまかせが外れ、区間を切り替えてもその倍率のまま。
//   覚えない(画面を閉じたらおまかせに戻る)。倍率のボタンの横に縮尺の棒を出す。
// ・11月駅伝は8位、正月駅伝は10位の下にシード権ラインを引く(10月駅伝とカスタム駅伝はなし)。
//   ラインをまたいでは集団にしない。詰めた間のあとも新しい集団にする。
// ・四角の見た目: 自分の大学はオレンジの枠(文字と塗りはほかの大学と同じ)、1位は太い白の枠、学連選抜(正月駅伝のオープン参加)は
//   点線の枠(学連選抜の監督をした年はオレンジの点線)。学連選抜は順位とシード権ラインに数えない。
// ・距離は1kmまでは10m単位、1km以上は「1.2km」。秒は画面と同じく切り捨ててから引き(saByou)、
//   距離はその秒から出す。間が0秒なら「並走」。四角を押したときの下の帯では、1位との差
//   (「180m +33秒」。0秒なら「トップと並走」)と前の大学との差を出す。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。レースの途中は1区から終わった区間まで。
//   新しく保存するものはない。作れなければカードを出さない。
// ・2.0.6の開発中に、点と名前の行の形から四角の形に変え、2枚あったカード(タイム分布と位置関係)を
//   見出しだけの1枚にした。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/shushou.dart'
    show shushouShirushi, shushouKaIma; // 主将の印(個人順位速報・区間配置確認と同じ。2.0.7)
import 'package:ekiden/kansuu/konki_best.dart'; // 今季ベスト(区間配置確認と同じ設定。2.0.7)
import 'package:ekiden/screens/shushou_iro.dart'; // 主将を示す色(区間配置確認と同じ。2.0.7)
import 'package:ekiden/screens/senshu_haichi_panel.dart'; // 区間配置確認のカードの部品(2.0.7)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/screens/Modal_kukanTimeBunpu.dart'
    show KukanBunpuYomikomi, kukanBunpuYomu, kukanBunpuGamenHiraku;

/// 表示の倍率の段階(1mあたりの高さ(px))と名前(×1は、最初に作ったときの決め打ちの倍率)
const List<double> _bairitsu = [0.1, 0.2, 0.4, 0.8, 1.6, 3.2];
const List<String> _bairitsuMei = ['×1/4', '×1/2', '×1', '×2', '×4', '×8'];

/// おまかせの倍率: 1位から最後尾までが、画面の高さのこの倍に収まる一番大きい倍率
const double _omakaseGamen = 2.0;

/// 飛び抜けて大きい間: その区間の間の中央値の、この倍以上
const double _tobinukeBai = 4;

/// 飛び抜けて大きい間として詰めるのは、大きい順に多くてこの数まで
const int _tobinukeSaidai = 3;

/// 飛び抜けて大きい間の下限(m。並走が多くて中央値が0に近いときに、小さな間を詰めないように)
const double _tobinukeSaitei = 50;

/// 詰めたところの高さ(px)
const double _tsumePx = 52;

/// 道の帯の幅(画面の幅に対する割合。四角が広いときは、四角が入るまで広げ、はみ出したぶんは横にスクロールする)
const double _michiWariai = 0.6;

/// 集団の1行に並べる大学の数の上限
const int _gyouSaidai = 3;

/// 詰めた間の括弧の文に添える言葉
const String _tsumeMoji = '(詰めています)';

/// 四角どうし・行どうしのすきま
const double _sukima = 4;

/// 集団(1校だけのときも)どうしの最小のすきま(枠どうしがくっつかないように)
const double _shuudanSukima = 10;

/// 四角の左端(集団の枠の内側の余白のぶん、道の端から空ける)
const double _hakoHidari = 8;

/// 集団の枠の、四角のまわりの余白
const double _wakuYohaku = 4;

/// 四角の中の余白(横・縦)
const double _hakoYoko = 6;
const double _hakoTate = 3;

/// 四角の枠の太さの最大(四角の大きさを決めるときに、これだけ見込む)
const double _wakuSaidai = 2;

/// 道の帯の色
const Color _michiIro = Color(0xFF1C1C1C);

/// カードと位置関係の色
const Color _iro = Colors.lightBlueAccent;

/// 自分の大学の色(区間ごとのタイム分布と同じ)
const Color _jibunIro = Colors.orangeAccent;

/// 道の中の四角に出す大学名(最後の「大」を省く。「東湊大」→「東湊」。省くと空になるときはそのまま)
String _michiMei(String mei) =>
    (mei.length > 1 && mei.endsWith('大')) ? mei.substring(0, mei.length - 1) : mei;

/// 距離の文(「180m」「1.2km」。1kmまでは10m単位)
String _kyoriMoji(double m) {
  final int r = (m / 10).round() * 10;
  if (r < 1000) return '${r}m';
  return '${(m / 1000).toStringAsFixed(1)}km';
}

/// 区間順位(個人順位速報と同じく大学データの区間順位。なければ結果から数えた順位。2.0.7)
int _kukanJuniYomu(EkidenUnivKekka x, int kk) {
  final List<int> kj = x.u.kukanjuni_taikai;
  if (kj.length > kk && kj[kk] >= 0 && kj[kk] != TEISUU.DEFAULTJUNI) return kj[kk];
  return x.kukanJuni[kk];
}

/// 大学1校分(学連選抜も)
class _IchiDaigaku {
  final String mei;

  /// 区間終了時点の累計タイム
  final double ruikei;

  /// 区間終了時点の順位(0が1位。学連選抜は-1)
  final int juni;

  /// 自分の大学か
  final bool jibun;

  /// 学連選抜(オープン参加)か
  final bool op;

  /// 前の区間の終了時点からの順位の変化(上げた数がプラス、下げた数がマイナス、同じなら0。
  /// 1区はnull。学連選抜は通過順位相当で比べる。2.0.6)
  final int? hendou;

  /// 学連選抜の通過順位相当(0が1位相当。大学はnull)
  final int? soutouJuni;

  /// その区間を走った選手(大学は senshu、学連選抜は gSenshu。分からなければnull。
  /// 四角を2回押したときの説明文に使う。2.0.7)
  final SenshuData? senshu;
  final Senshu_Gakuren_Data? gSenshu;

  /// 学連選抜の選手の所属大学の名前(大学はnull)
  final String? shozoku;

  /// 区間順位(0が1位。学連選抜は区間順位相当)
  final int? kukanJuni;

  /// 区間タイム
  final double? kukanTime;

  /// 次の区間を走る選手(大学は tsugiSenshu、学連選抜は tsugiGSenshu。最終区などはnull。
  /// 四角を3回押したときに、区間配置確認のカードを開いたときと同じ中身を出す。2.0.7)
  final SenshuData? tsugiSenshu;
  final Senshu_Gakuren_Data? tsugiGSenshu;

  const _IchiDaigaku(
    this.mei,
    this.ruikei,
    this.juni,
    this.jibun,
    this.op, {
    this.hendou,
    this.soutouJuni,
    this.senshu,
    this.gSenshu,
    this.shozoku,
    this.kukanJuni,
    this.kukanTime,
    this.tsugiSenshu,
    this.tsugiGSenshu,
  });

  /// 次の区間を走る選手がいるか
  bool get tsugiAri => tsugiSenshu != null || tsugiGSenshu != null;

  /// 走った選手の説明文(個人順位速報の「説明文」と同じ。末尾の改行は省く。なければnull。2.0.7)
  String? get setsumei {
    final String? s = senshu?.string_racesetumei ?? gSenshu?.string_racesetumei;
    if (s == null) return null;
    final String t = s.trimRight();
    return t.isEmpty ? null : t;
  }

  /// 順位の変化の文(「↑2」「↓3」「→」。1区はnull)
  String? get hendouMoji {
    final int? h = hendou;
    if (h == null) return null;
    if (h > 0) return '↑$h';
    if (h < 0) return '↓${-h}';
    return '→';
  }
}

/// 区間1つ分の位置関係
class _IchiKukan {
  /// 区間(0が1区)
  final int kk;

  /// 区間の平均の速さ(m/秒)
  final double hayasa;

  /// 累計タイムの順(学連選抜も入る)
  final List<_IchiDaigaku> narabi;

  _IchiKukan(this.kk, this.hayasa, this.narabi);

  /// 1位(学連選抜を除く)
  _IchiDaigaku get top => narabi.firstWhere((x) => !x.op, orElse: () => narabi.first);

  /// [x]の、1位との差(秒。画面と同じく切り捨ててから引く。1位より前の学連選抜はマイナス)
  int sa(_IchiDaigaku x) => saByou(x.ruikei, top.ruikei);

  /// 1kmあたりのタイム(秒)
  int get pace => hayasa > 0 ? (1000 / hayasa).round() : 0;

  /// 1位との差の文(距離が先。「トップ」「180m +33秒」「トップと並走」「トップより30m前 5秒」)
  String saBun(_IchiDaigaku x) {
    if (identical(x, top)) return 'トップ';
    final int s = sa(x);
    if (s == 0) return 'トップと並走';
    if (s < 0) return 'トップより${_kyoriMoji(-s * hayasa)}前 ${saMoji(s)}';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// 2つの大学の間の文(道の右の括弧に出す。間なので「+」を付けない。「90m 16秒」。0秒は「並走」)
  String aidaBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)} ${saMoji(s)}';
  }

  /// 2つの大学の差の文(距離が先。「30m +5秒」。0秒は「並走」)
  String futatsuBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// 名前の行を押したときの、前の大学(1位は次の大学)との差の文
  String maeBun(int i) {
    if (i == 0) {
      if (narabi.length < 2) return '';
      final _IchiDaigaku tsugi = narabi[1];
      final String s = futatsuBun(tsugi, narabi[0]);
      return s == '並走'
          ? '次の${_yobi(tsugi)}と並走'
          : '次の${_yobi(tsugi)}とは$s';
    }
    final _IchiDaigaku mae = narabi[i - 1];
    final String s = futatsuBun(narabi[i], mae);
    return s == '並走' ? '前の${_yobi(mae)}と並走' : '前の${_yobi(mae)}とは$s';
  }

  String _yobi(_IchiDaigaku x) => x.op ? '学連選抜' : x.mei;
}

/// 位置関係のもとになる結果(位置関係の画面と、カードで使う)
class _IchiKankei {
  /// 1区から順
  final List<_IchiKukan> kukan;

  /// シード権の数(11月駅伝8・正月駅伝10。ほかの大会はnull)
  final int? seed;

  /// 学連選抜の監督をした年か(学連選抜をオレンジの白抜きにする)
  final bool gakurenJibun;

  /// 大会の区間数
  final int zenKukansuu;

  /// 大会番号
  final int race;

  _IchiKankei._(this.kukan, this.seed, this.gakurenJibun, this.zenKukansuu, this.race);

  /// 大会[race]の結果から作る([made] を渡すと、レースの途中の1区から[made]区まで)
  /// (思わぬデータで画面が止まらないよう、作れなければnull)
  static _IchiKankei? yomu(int race, {int? made}) {
    try {
      return _yomuHontai(race, made);
    } catch (e, st) {
      debugPrint('[区間終了時点の位置関係] 作れませんでした: $e\n$st');
      return null;
    }
  }

  static _IchiKankei? _yomuHontai(int race, int? made) {
    // レースの途中は、実況(kiji_jikkyou.dart)と同じく結果の記事ではない形で読む
    final KijiKankyou? k = KijiKankyou.yomuRace(race, kekka: made == null);
    if (k == null || !k.ekiden) return null;
    if (made != null && made <= 0) return null;
    final EkidenKekka? e = EkidenKekka.tsukuru(k, made: made);
    if (e == null) return null;
    final UnivData? my = k.jibunUniv;
    final bool gakurenAri = race == 2 && gakurenKonnenAri(k.gh);
    final bool gakurenJibun =
        gakurenAri && e.jibun == null && my != null && gakurenKantokuChuu(k.kantoku, my);
    final List<double> kyoriIchiran = k.gh.kyori_taikai_kukangoto.length > race
        ? k.gh.kyori_taikai_kukangoto[race]
        : const <double>[];
    // 区間ごとの、区間エントリーの選手(区間 → 大学id → 選手。次の区間を走る選手に使う。2.0.7)
    final Map<int, Map<int, SenshuData>> entryHyou = {};
    for (final SenshuData s in k.senshu) {
      final int en = k.entry(s);
      if (en >= 0) (entryHyou[en] ??= <int, SenshuData>{})[s.univid] = s;
    }
    final List<_IchiKukan> kukan = [];
    for (int kk = 0; kk < e.ks; kk++) {
      final double kyori = kyoriIchiran.length > kk ? kyoriIchiran[kk] : 0.0;
      // 次の区間(最終区のあとはなし)
      final bool tsugiKukanAri = kk + 1 < k.kukansuu;
      final Map<int, SenshuData>? tsugiHyou = tsugiKukanAri ? entryHyou[kk + 1] : null;
      if (kyori <= 0) continue;
      // 区間終了時点の順(通過順位。記事と同じ並び)
      final List<EkidenUnivKekka> l = [
        for (final EkidenUnivKekka x in e.jun)
          if (x.ruikei[kk] > 0 &&
              x.ruikei[kk] < TEISUU.DEFAULTTIME &&
              x.kukanTime[kk] > 0 &&
              x.kukanTime[kk] < TEISUU.DEFAULTTIME)
            x,
      ]..sort((a, b) => a.tuuka[kk].compareTo(b.tuuka[kk]));
      if (l.length < 2) continue;
      // 区間の平均の速さ(出場校の区間タイムの平均から。学連選抜は入れない)
      double goukei = 0;
      for (final EkidenUnivKekka x in l) {
        goukei += x.kukanTime[kk];
      }
      final double heikin = goukei / l.length;
      if (heikin <= 0) continue;
      final List<_IchiDaigaku> narabi = [
        for (int i = 0; i < l.length; i++)
          _IchiDaigaku(
            l[i].mei,
            l[i].ruikei[kk],
            i,
            l[i].u.id == k.gh.MYunivid,
            false,
            // 前の区間の終了時点の通過順位から、いくつ上げたか(1区はなし)
            hendou: kk > 0 ? l[i].tuuka[kk - 1] - l[i].tuuka[kk] : null,
            // 走った選手と区間順位・区間タイム(四角を2回押したときの説明文に使う。2.0.7)
            senshu: l[i].senshu[kk],
            kukanJuni: _kukanJuniYomu(l[i], kk),
            kukanTime: l[i].kukanTime[kk],
            tsugiSenshu: tsugiHyou?[l[i].u.id],
          ),
      ];
      final GakurenKukanKekka? g = gakurenAri ? gakurenKukanKekka(k.gh, kk) : null;
      if (g != null && g.tuukaTime > 0 && g.tuukaTime < TEISUU.DEFAULTTIME) {
        // 学連選抜は、同じタイムの大学より後ろに入れる
        int basho = narabi.length;
        for (int i = 0; i < narabi.length; i++) {
          if (g.tuukaTime < narabi[i].ruikei) {
            basho = i;
            break;
          }
        }
        // 学連選抜の順位の変化は、通過順位相当で比べる(1区はなし)
        final int? gMae = g.maeTuukaJuni;
        narabi.insert(
          basho,
          _IchiDaigaku(
            '学連選抜',
            g.tuukaTime,
            -1,
            false,
            true,
            hendou: gMae == null ? null : gMae - g.tuukaJuni,
            soutouJuni: g.tuukaJuni,
            gSenshu: g.senshu,
            shozoku: g.shozoku,
            kukanJuni: g.kukanJuni,
            kukanTime: g.kukanTime,
            tsugiGSenshu: tsugiKukanAri ? gakurenKukanSenshu(kk + 1) : null,
          ),
        );
      }
      kukan.add(_IchiKukan(kk, kyori / heikin, narabi));
    }
    if (kukan.isEmpty) return null;
    return _IchiKankei._(kukan, e.seedSuu, gakurenJibun, k.kukansuu, race);
  }

  /// 学連選抜が走っている区間があるか
  bool get opAri => kukan.any((r) => r.narabi.any((x) => x.op));
}

/// 位置関係の画面を開く
void _ichiGamenHiraku(BuildContext context, int race, int? made) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: '区間終了時点の位置関係', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ModalIchiKankeiView(race: race, made: made),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}


/// 区間ごとのタイム分布と、区間終了時点の位置関係を1枚にまとめたカード(2.0.6)
/// ・左が「タイム分布」(Modal_kukanTimeBunpu.dart)、右が「位置関係」の2つのボタンで、それぞれ別に押せる。
///   中身はアイコンと見出しだけ(区間の帯のグラフなどは、開いた画面で見る)。
///   ほかのカードより目立つよう、それぞれの色(青緑・水色)の線で角を丸めて囲み、同じ色でうっすら塗る。
///   いつも左右に並べ、文字をとても大きくしたときは、ボタンの中で折り返す(左右の高さはそろえる)
/// ・片方が作れないときは、作れたほうだけでカードの幅を使う。両方とも作れなければ出さない
/// ・区間が終わるたびの画面(mode 350。[made] に終わった区間の数)の実況のカードのすぐ下と、
///   結果画面([made] はnull)のニュース記事のカードのすぐ下に置く
/// ・結果は画面を出したあとで1回だけ作る。区間や大会が変わったら作り直すよう、置く側で key を付ける
class KukanBunsekiCard extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面ではnull)
  final int? made;
  const KukanBunsekiCard({super.key, required this.race, this.made});

  @override
  State<KukanBunsekiCard> createState() => _KukanBunsekiCardState();
}

class _KukanBunsekiCardState extends State<KukanBunsekiCard> {
  /// タイム分布が作れたか
  bool _bunpuAri = false;

  /// 位置関係が作れたか
  bool _ichiAri = false;

  /// 結果を作ったか
  bool _tsukutta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final KukanBunpuYomikomi? bunpu = kukanBunpuYomu(widget.race, made: widget.made);
      final _IchiKankei? ichi = _IchiKankei.yomu(widget.race, made: widget.made);
      if (!mounted) return;
      setState(() {
        _bunpuAri = bunpu != null;
        _ichiAri = ichi != null;
        _tsukutta = true;
      });
    });
  }

  /// ボタン1つ(アイコンと見出し。その色の線で囲み、同じ色でうっすら塗る)
  Widget _botan(IconData icon, Color iro, String moji, VoidCallback onTap) {
    return Material(
      color: iro.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iro, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iro, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$moji ›',
                  style: TextStyle(color: iro, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_tsukutta || (!_bunpuAri && !_ichiAri)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      // 左右の高さをそろえる(文字をとても大きくして片方だけ折り返したときも、同じ高さのボタンにする)
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_bunpuAri)
              Expanded(
                child: _botan(
                  Icons.candlestick_chart,
                  Colors.tealAccent,
                  'タイム分布',
                  () => kukanBunpuGamenHiraku(context, widget.race, widget.made),
                ),
              ),
            if (_bunpuAri && _ichiAri) const SizedBox(width: 8),
            if (_ichiAri)
              Expanded(
                child: _botan(
                  Icons.directions_run,
                  _iro,
                  '位置関係',
                  () => _ichiGamenHiraku(context, widget.race, widget.made),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ModalIchiKankeiView extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面からはnull)
  final int? made;
  const ModalIchiKankeiView({super.key, required this.race, this.made});

  @override
  State<ModalIchiKankeiView> createState() => _ModalIchiKankeiViewState();
}

/// 大学の四角1つ分の置き場所
class _Hako {
  /// narabi の番号
  final int i;
  final double x;
  final double w;
  final double h;
  const _Hako(this.i, this.x, this.w, this.h);
}

/// 四角を並べた行(集団は、1行3校までで折り返して何行かになる)
class _Gyou {
  /// 上端
  final double y;

  /// 高さ
  final double h;

  final List<_Hako> hako;

  /// 行の右端(いちばん右の四角の右のすきままで)
  final double hashi;

  const _Gyou(this.y, this.h, this.hako, this.hashi);
}

/// 前の大学(集団)との間の括弧1つ分
class _Aida {
  /// 括弧の上端(前の集団の一番下の行の真ん中)と下端(次の集団の一番上の行の真ん中)
  final double y0;
  final double y1;

  /// 文(「90m 16秒」)
  final String moji;

  /// 詰めた間か(括弧を点線にし、文の下に「(詰めています)」を添える)
  final bool tsume;

  /// 文の上端と高さ(ほかの文やシード権ラインと重ならないように決める)
  double top = 0;
  double h = 0;

  _Aida(this.y0, this.y1, this.moji, this.tsume);
}

/// 道の上の並べ方
class _Haichi {
  final List<_Gyou> gyou;

  /// 前の大学(集団)との間の括弧
  final List<_Aida> aida;

  /// 道の切れ目(詰めた間の、前の行の下端と次の行の上端)
  final List<({double y0, double y1})> kireme;

  /// 2校以上の集団を囲む枠
  final List<Rect> waku;

  /// シード権ラインの行の上端(引かないときはnull)
  final double? seedTop;

  /// 1位(いちばん前)の位置
  final double sentouY;

  /// 道の帯の上端
  final double michiUe;

  /// 道の帯の幅
  final double michiHaba;

  /// 括弧の左端と、間の文の左端
  final double kakkoX;
  final double mojiX;

  /// 全体の幅(画面より広いときは、横にスクロールする)
  final double haba;

  /// 全体の高さ
  final double takasa;

  _Haichi(
    this.gyou,
    this.aida,
    this.kireme,
    this.waku,
    this.seedTop,
    this.sentouY,
    this.michiUe,
    this.michiHaba,
    this.kakkoX,
    this.mojiX,
    this.haba,
    this.takasa,
  );
}

class _ModalIchiKankeiViewState extends State<ModalIchiKankeiView> {
  _IchiKankei? _b;

  /// 見ている区間(並びの番号)
  int _erabu = 0;

  /// 押した大学(narabi の番号。-1はなし)
  int _oshita = -1;

  /// 押した大学の帯をどこまで開いているか(0: 差だけ、1: 走った選手の説明文、2: 次の区間を走る選手。
  /// 四角を押すたびに進む。2.0.7)
  int _hiraki = 0;

  /// 説明文と次の区間の選手の部分のスクロール(どちらか一方しか出さないので、1つを使い回す)
  final ScrollController _setsumeiScroll = ScrollController();

  /// 今のゲームの変数(次の区間の選手のパネルで使う)
  Ghensuu? _gh;

  /// 持ちタイムを今季ベストで表示しているときの順位表(区間配置確認と同じ設定。初めて使うときに一度だけ作る)
  KonkiBestJuni? _konki;
  bool _konkiYonda = false;

  /// 押した大学の四角(下の帯が伸びて隠れるときに、道を動かして見えるようにする)
  final GlobalKey _oshitaKey = GlobalKey();

  /// 表示の倍率の段階(_bairitsu の番号。おまかせのときは使わない)
  int _dan = 2;

  /// 倍率がおまかせか(「−」「＋」を押すと外れる。覚えない)
  bool _omakase = true;

  static const TextStyle _chiisai = TextStyle(color: Colors.white54, fontSize: 11);
  static const TextStyle _seedMojiStyle = TextStyle(color: Colors.amberAccent, fontSize: 11);
  static const TextStyle _migiStyle = TextStyle(color: Colors.white70, fontSize: 12);

  @override
  void initState() {
    super.initState();
    final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
    _b = b;
    // 一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)を開いておく
    if (b != null) _erabu = b.kukan.length - 1;
    final Box<Ghensuu> gBox = Hive.box<Ghensuu>('ghensuuBox');
    _gh = gBox.isEmpty ? null : gBox.getAt(0);
  }

  /// 今季ベストの順位表(自己ベストで表示しているときはnull)
  KonkiBestJuni? _konkiYomu() {
    if (!_konkiYonda) {
      _konkiYonda = true;
      _konki = konkiBestHyoujiChuu() ? KonkiBestJuni() : null;
    }
    return _konki;
  }

  /// [x]の次の区間を走る選手のパネルを出せるか
  /// (区間配置確認の部品は表示中の大会を見るので、表示中の大会がこの大会のときだけ)
  bool _tsugiDaseru(_IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    return x.tsugiAri && gh != null && gh.hyojiracebangou == widget.race;
  }

  @override
  void dispose() {
    _setsumeiScroll.dispose();
    super.dispose();
  }

  /// 大学の四角を押したとき(1回目で差の帯、2回目で走った選手の説明文、3回目で次の区間を走る選手を出し、
  /// 4回目で閉じる。次の区間の選手がいなければ3回目で閉じる。
  /// 開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。2.0.7)
  void _hakoOsu(_IchiKukan r, int i) {
    final bool tsugi = _tsugiDaseru(r.narabi[i]);
    setState(() {
      if (_oshita == i) {
        if (_hiraki < (tsugi ? 2 : 1)) {
          _hiraki++;
        } else {
          _oshita = -1;
          _hiraki = 0;
        }
      } else {
        _oshita = i;
        // 次の区間の選手を出していて、切り替えた大学にいなければ、説明文まで
        if (_hiraki == 2 && !tsugi) _hiraki = 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 説明文は、いつも先頭から出す
      if (_setsumeiScroll.hasClients) _setsumeiScroll.jumpTo(0);
      // 下の帯が伸びて、押した四角が隠れるときは、道を動かして見えるようにする
      final BuildContext? c = _oshitaKey.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 200),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  /// 説明文と次の区間の選手の部分(画面の高さの3割までにし、長いときはこの中だけでスクロールする。
  /// 下の安全な余白のぶん、スクロールバーが縮まないように外す。
  /// デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める)
  Widget _scrollBako(BuildContext context, double gamenTakasa, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gamenTakasa * 0.3),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Scrollbar(
          controller: _setsumeiScroll,
          thumbVisibility: true,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _setsumeiScroll,
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// 次の区間を走る選手のパネル(区間配置確認のカードを開いたときと同じ。上の行・距離と主将・中身。
  /// 主将はカードと同じく薄い緑にして緑の枠を付ける。学連選抜は所属大学を出す。2.0.7)
  Widget _tsugiPanel(BuildContext context, _IchiKukan r, _IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    if (gh == null) return const SizedBox.shrink();
    final int tk = r.kk + 1;
    final String fuda = '${tk + 1}区';
    final List<double> kyoriIchiran = gh.kyori_taikai_kukangoto.length > widget.race
        ? gh.kyori_taikai_kukangoto[widget.race]
        : const <double>[];
    final String kyori = kyoriIchiran.length > tk ? '${kyoriIchiran[tk].toStringAsFixed(0)}m' : '';
    const TextStyle shita = TextStyle(color: Colors.white70, fontSize: 13);
    final KonkiBestJuni? konki = _konkiYomu();
    final SenshuData? s = x.tsugiSenshu;
    final Senshu_Gakuren_Data? g = x.tsugiGSenshu;
    if (s != null) {
      final bool shushou = shushouKaIma(s);
      final Widget panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: s.name,
            gakunen: s.gakunen,
            shousaiId: s.id,
          ),
          Text([if (kyori.isNotEmpty) kyori, if (shushou) '主将'].join('　'), style: shita),
          const Divider(color: Colors.white24),
          // 中身(区間配置確認のカードと同じく、能力の行は真ん中に寄せる)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              senshuNouryokuRan(gh, s),
              senshuKirokuRan(gh, s, konki),
            ],
          ),
        ],
      );
      if (!shushou) return panel;
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
        decoration: BoxDecoration(
          color: shushouIroHaikei,
          border: Border.all(color: shushouIroSen, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: panel,
      );
    }
    if (g != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: g.name,
            gakunen: g.gakunen,
            shousaiId: g.id,
          ),
          Text('$kyori 所属:${gakurenShozoku(g)}', style: shita),
          const Divider(color: Colors.white24),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              gakurenNouryokuRan(gh, g, tk),
              gakurenKirokuRan(gh, g, konki),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// 説明文の上の行(「3区 佐藤 健太(2年)　区間1位 1:02:41」。
  /// 学連選抜は「3区 OP 田中 翔(3年 所属:西峰大)　区間4位相当 1:03:05」。2.0.7)
  String _senshuGyou(_IchiKukan r, _IchiDaigaku x) {
    final String ku = '${r.kk + 1}区';
    String mei = '';
    final SenshuData? s = x.senshu;
    final Senshu_Gakuren_Data? g = x.gSenshu;
    if (s != null) {
      mei = ' ${s.name}(${s.gakunen}年${shushouShirushi(s)})';
    } else if (g != null) {
      mei = ' OP ${g.name}(${g.gakunen}年 所属:${x.shozoku ?? ''})';
    }
    final int? kj = x.kukanJuni;
    final double? kt = x.kukanTime;
    final String juni = kj == null ? '' : (x.op ? '区間${kj + 1}位相当' : '区間${kj + 1}位');
    final String time = (kt != null && kt > 0 && kt < TEISUU.DEFAULTTIME)
        ? TimeDate.timeToFunByouString(kt)
        : '';
    final String ato = [juni, time].where((e) => e.isNotEmpty).join(' ');
    return ato.isEmpty ? '$ku$mei' : '$ku$mei　$ato';
  }

  /// 四角の中の文(順位と大学名)
  TextSpan _hakoSpan(_IchiKankei b, _IchiKukan r, int i) {
    final _IchiDaigaku x = r.narabi[i];
    return TextSpan(
      children: [
        // 学連選抜は短く「OP学連」(OPは順位と同じ薄い色。下の帯は「学連選抜」のまま)
        TextSpan(
          text: x.op ? 'OP' : '${x.juni + 1} ',
          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
        ),
        TextSpan(
          text: x.op ? '学連' : _michiMei(x.mei),
          // 自分の大学も、文字はほかの大学と同じ(オレンジは枠だけ。読みやすいように)
          style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
        ),
        // 前の区間からの順位の変化(↑は緑、↓は赤、→は灰色。1区は付けない)
        if (x.hendouMoji != null)
          TextSpan(
            text: ' ${x.hendouMoji}',
            style: TextStyle(color: _hendouIro(x.hendou!), fontSize: 12),
          ),
      ],
    );
  }

  /// 順位の変化の色
  Color _hendouIro(int h) =>
      h > 0 ? Colors.lightGreenAccent : (h < 0 ? Colors.redAccent.shade100 : Colors.white54);

  /// 文の大きさ(折り返さない1行のとき)
  Size _ookisa(TextSpan span, TextScaler scaler) {
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final Size s = tp.size;
    tp.dispose();
    return s;
  }

  /// 前の大学との間(m。[i]は narabi[i] と narabi[i+1] の間)
  List<double> _aida(_IchiKukan r) => [
    for (int i = 0; i + 1 < r.narabi.length; i++)
      math.max(0.0, (r.narabi[i + 1].ruikei - r.narabi[i].ruikei) * r.hayasa),
  ];

  /// 飛び抜けて大きい間(_aida の番号。中央値の4倍以上を、大きい順に多くて3か所)
  Set<int> _tobinukeAida(List<double> aida) {
    if (aida.length < 2) return <int>{};
    final List<double> narabe = List<double>.of(aida)..sort();
    final int n = narabe.length;
    final double chuuou = n.isOdd ? narabe[n ~/ 2] : (narabe[n ~/ 2 - 1] + narabe[n ~/ 2]) / 2;
    final double genkai = math.max(chuuou * _tobinukeBai, _tobinukeSaitei);
    final List<int> kouho = [
      for (int i = 0; i < aida.length; i++)
        if (aida[i] >= genkai) i,
    ]..sort((a, b) => aida[b].compareTo(aida[a]));
    return kouho.take(_tobinukeSaidai).toSet();
  }

  /// おまかせの倍率の段階(詰めた間を除いた1位から最後尾までの長さが、
  /// 画面の高さのおよそ2つ分に収まる一番大きい倍率)
  int _omakaseDan(_IchiKukan r, double gamenTakasa) {
    if (r.narabi.length < 2) return 2;
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    double nokori = 0;
    for (int i = 0; i < aida.length; i++) {
      if (!tsume.contains(i)) nokori += aida[i];
    }
    int dan = 0;
    for (int i = 0; i < _bairitsu.length; i++) {
      if (nokori * _bairitsu[i] + tsume.length * _tsumePx <= gamenTakasa * _omakaseGamen) {
        dan = i;
      }
    }
    return dan;
  }

  /// 大学の四角と行の置き場所を決める([px] は1mあたりの高さ。[gamenTakasa] は画面の高さ。
  /// 手動で倍率を選んでいるとき([omakase] がfalse)は、1つの間が画面の高さを超えるところも詰める)
  _Haichi _haichi(
    _IchiKankei b,
    _IchiKukan r,
    double w,
    TextScaler scaler,
    double px,
    double gamenTakasa,
    bool omakase,
  ) {
    final int n = r.narabi.length;
    // 四角の大きさ(折り返さない1行)
    final List<Size> hakoOokisa = [
      for (int i = 0; i < n; i++)
        () {
          final Size s = _ookisa(_hakoSpan(b, r, i), scaler);
          return Size(
            s.width + _hakoYoko * 2 + _wakuSaidai * 2 + 2,
            s.height + _hakoTate * 2 + _wakuSaidai * 2,
          );
        }(),
    ];
    // 行の高さ(四角の高さ。どの行も同じ)
    double gyouTakasa = 0;
    for (final Size s in hakoOokisa) {
      gyouTakasa = math.max(gyouTakasa, s.height);
    }
    // 間の文の高さ(1行目と、詰めた間に添える「(詰めています)」)
    final double aidaMojiTakasa = _ookisa(const TextSpan(text: '0m', style: _migiStyle), scaler).height;
    final double tsumeMojiTakasa = _ookisa(const TextSpan(text: _tsumeMoji, style: _chiisai), scaler).height;
    // 詰めた間の、前の行の真ん中から次の行の真ん中までの長さ(2行の文が入るように)
    final double tsumeNagasa = math.max(
      _tsumePx,
      gyouTakasa + aidaMojiTakasa + tsumeMojiTakasa + _sukima * 2,
    );
    final double seedTakasa = _ookisa(
      const TextSpan(text: 'シード権ライン', style: _seedMojiStyle),
      scaler,
    ).height;
    final int opNozoku = r.narabi.where((x) => !x.op).length;
    final int? seed = (b.seed != null && opNozoku > b.seed!) ? b.seed : null;

    // 詰める間(飛び抜けて大きい間と、手動のときに画面の高さを超える間)
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    if (!omakase) {
      for (int i = 0; i < aida.length; i++) {
        if (aida[i] * px > gamenTakasa) tsume.add(i);
      }
    }

    // 1位(いちばん前)からの距離(m)
    final double base = r.narabi.first.ruikei;
    final List<double> d = [for (final _IchiDaigaku x in r.narabi) (x.ruikei - base) * r.hayasa];

    // 集団に分ける(画面の上で四角1つ分の高さ = genkaiPx)
    // (先頭の大学から近い順に入れていくと、たまたま先頭から遠くなったところで切れて、
    // 並走の大学どうしが別の集団になることがあったので、一番大きく空いた間で分けるようにした。2.0.6)
    final double genkaiPx = gyouTakasa + _sukima;
    // 1) 隣どうしの間が四角1つ分より狭いあいだは、つながった1つの集団にする
    //    (シード権ラインと、詰めた間では必ず分ける)
    final List<List<int>> tsunagari = [];
    for (int i = 0; i < n; i++) {
      final _IchiDaigaku x = r.narabi[i];
      final bool seedMae = seed != null && !x.op && x.juni == seed;
      final bool kiremeAto = i > 0 && tsume.contains(i - 1);
      final bool chikai = i > 0 && (d[i] - d[i - 1]) * px < genkaiPx;
      if (tsunagari.isNotEmpty && chikai && !seedMae && !kiremeAto) {
        tsunagari.last.add(i);
      } else {
        tsunagari.add([i]);
      }
    }
    // 2) 先頭から最後尾までが四角1つ分より長い集団は、その中で一番大きく空いた間で2つに分ける
    //    (まだ長ければ繰り返す。同じ大きさの間があれば前のほうで分ける)
    final List<List<int>> shuudan = [];
    void wakeru(List<int> g) {
      if (g.length < 2 || (d[g.last] - d[g.first]) * px < genkaiPx) {
        shuudan.add(g);
        return;
      }
      int kiru = 1;
      double saidai = -1;
      for (int j = 1; j < g.length; j++) {
        final double a = d[g[j]] - d[g[j - 1]];
        if (a > saidai) {
          saidai = a;
          kiru = j;
        }
      }
      wakeru(g.sublist(0, kiru));
      wakeru(g.sublist(kiru));
    }

    for (final List<int> g in tsunagari) {
      wakeru(g);
    }

    // 集団ごとに置く(一番上の行は前の集団の一番下の行から、間の距離ぶん下。1行3校まで)
    final List<_Gyou> gyou = [];
    final List<_Aida> aidaList = [];
    final List<({double y0, double y1})> kireme = [];
    final List<Rect> waku = [];
    double? seedTop;
    // 道の帯は、いちばん上から始める(2.0.6の開発中まで、上に「○区→○区の中継所」を出していた)
    const double michiUe = 0;
    double shita = michiUe; // いま置いたものの下端
    double sentouY = michiUe + _sukima + gyouTakasa / 2;
    double? maeChuushin; // 前の集団の一番下の行の真ん中
    double maeGyouShita = michiUe; // 前の集団の一番下の行の下端
    int maeSaigo = 0; // 前の集団の最後の大学
    for (int si = 0; si < shuudan.length; si++) {
      final List<int> sh = shuudan[si];
      final int saki = sh.first;
      double top;
      final double? mc = maeChuushin;
      final bool tsumeAto = mc != null && tsume.contains(saki - 1);
      if (mc == null) {
        top = michiUe + _sukima;
      } else if (tsumeAto) {
        // 詰めた間: 決まった長さだけ空ける(道には切れ目の点線、右には点線の括弧)
        top = mc + tsumeNagasa - gyouTakasa / 2;
      } else {
        top = mc + (d[saki] - d[maeSaigo]) * px - gyouTakasa / 2;
      }
      // シード権ライン(シード権の順位の次の大学の前に引く)
      final _IchiDaigaku x0 = r.narabi[saki];
      if (seed != null && !x0.op && x0.juni == seed) {
        final double sTop = shita + _sukima;
        seedTop = sTop;
        shita = sTop + seedTakasa;
      }
      // 2校以上の集団は枠で囲むので、枠の余白のぶんも空ける
      final bool wakuAri = sh.length >= 2;
      top = math.max(
        top,
        si == 0 ? shita + _sukima + (wakuAri ? _wakuYohaku : 0) : shita + _shuudanSukima + (wakuAri ? _wakuYohaku : 0),
      );
      if (si == 0) sentouY = top + gyouTakasa / 2;
      // 前の集団との間の括弧(前の集団の一番下の行の真ん中から、この集団の一番上の行の真ん中まで)
      if (mc != null) {
        aidaList.add(
          _Aida(mc, top + gyouTakasa / 2, r.aidaBun(r.narabi[saki], r.narabi[maeSaigo]), tsumeAto),
        );
        if (tsumeAto) kireme.add((y0: maeGyouShita, y1: top));
      }
      final double shuudanUe = top;
      double shuudanMigi = 0;
      for (int k = 0; k < sh.length; k += _gyouSaidai) {
        final List<_Hako> hako = [];
        double x = _hakoHidari;
        for (int j = k; j < sh.length && j < k + _gyouSaidai; j++) {
          final Size z = hakoOokisa[sh[j]];
          hako.add(_Hako(sh[j], x, z.width, z.height));
          x += z.width + _sukima;
        }
        gyou.add(_Gyou(top, gyouTakasa, hako, x));
        shuudanMigi = math.max(shuudanMigi, x);
        shita = top + gyouTakasa;
        top = shita + _sukima;
      }
      maeChuushin = shita - gyouTakasa / 2;
      maeGyouShita = shita;
      maeSaigo = sh.last;
      // 2校以上の集団を囲む枠(四角にぴったり合わせる。右は最後の四角の右のすきままで)
      if (wakuAri) {
        waku.add(
          Rect.fromLTRB(
            _hakoHidari - _wakuYohaku,
            shuudanUe - _wakuYohaku,
            shuudanMigi - _sukima + _wakuYohaku,
            shita + _wakuYohaku,
          ),
        );
        shita += _wakuYohaku;
      }
    }

    // 間の文の置き場所(括弧の真ん中。前の文やシード権ラインと重なるときは、下にずらす)
    double maeMojiShita = -1;
    for (final _Aida a in aidaList) {
      a.h = aidaMojiTakasa + (a.tsume ? tsumeMojiTakasa : 0);
      double t = math.max((a.y0 + a.y1) / 2 - a.h / 2, maeMojiShita + 2);
      final double? st = seedTop;
      if (st != null && t < st + seedTakasa && t + a.h > st) t = st + seedTakasa + 2;
      a.top = t;
      maeMojiShita = t + a.h;
    }

    // 幅(道の帯は画面の6割か、一番広い行の広いほう。間の文が入りきらなければ横にスクロール)
    double gyouHaba = 0;
    for (final _Gyou g in gyou) {
      gyouHaba = math.max(gyouHaba, g.hashi);
    }
    double mojiHaba = 0;
    for (final _Aida a in aidaList) {
      mojiHaba = math.max(mojiHaba, _ookisa(TextSpan(text: a.moji, style: _migiStyle), scaler).width);
      if (a.tsume) {
        mojiHaba = math.max(
          mojiHaba,
          _ookisa(const TextSpan(text: _tsumeMoji, style: _chiisai), scaler).width,
        );
      }
    }
    final double michiHaba = math.max(w * _michiWariai, gyouHaba + _wakuYohaku);
    final double kakkoX = michiHaba + 6;
    final double mojiX = kakkoX + 14;
    final double haba = math.max(w, mojiX + mojiHaba + 8);
    double takasa = shita;
    for (final _Aida a in aidaList) {
      takasa = math.max(takasa, a.top + a.h);
    }
    takasa += 16;
    return _Haichi(
      gyou,
      aidaList,
      kireme,
      waku,
      seedTop,
      sentouY,
      michiUe,
      michiHaba,
      kakkoX,
      mojiX,
      haba,
      takasa,
    );
  }

  /// 押した大学の帯の文(順位・1位との差・前の大学との差)
  String? _oshitaBun(_IchiKukan r) {
    if (_oshita < 0 || _oshita >= r.narabi.length) return null;
    final _IchiDaigaku x = r.narabi[_oshita];
    final String mae = r.maeBun(_oshita);
    // 順位の後ろに、前の区間からの変化を付ける(「5位(↑3) 青嵐大」「3位相当(↑2) 学連選抜」)
    final String? hm = x.hendouMoji;
    final String henka = hm == null ? '' : '($hm)';
    final int? soutou = x.soutouJuni;
    final String mei = x.op
        ? (soutou == null ? '学連選抜(OP)' : '${soutou + 1}位相当$henka 学連選抜')
        : '${x.juni + 1}位$henka ${x.mei}';
    return mae.isEmpty ? '$mei　${r.saBun(x)}' : '$mei　${r.saBun(x)}　$mae';
  }

  @override
  Widget build(BuildContext context) {
    final _IchiKankei? b = _b;
    final double gamenTakasa = MediaQuery.sizeOf(context).height;
    _IchiKukan? r;
    int dan = 2;
    if (b != null) {
      r = b.kukan[_erabu.clamp(0, b.kukan.length - 1)];
      dan = _omakase ? _omakaseDan(r, gamenTakasa) : _dan.clamp(0, _bairitsu.length - 1);
    }
    final _IchiKukan? r0 = r;
    final String? oshitaBun = r0 == null ? null : _oshitaBun(r0);
    final _IchiDaigaku? x0 = (r0 != null && _oshita >= 0 && _oshita < r0.narabi.length)
        ? r0.narabi[_oshita]
        : null;
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '区間終了時点の位置関係',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: (b == null || r0 == null)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '駅伝の結果がありません。',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              )
            : Column(
                children: [
                  // 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)。
                  // 画面の高さの4割まで(超えるときは、この中だけでスクロールする)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: gamenTakasa * 0.4),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: _buildKotei(b, dan),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: _buildHontai(context, b, r0, dan, gamenTakasa),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: HENSUU.backgroundcolor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 押した大学の差(スクロールしていても見えるように、下に固定する)。
            // もう一度押すと、走った選手の説明文も出す(2.0.7)
            if (oshitaBun != null && r0 != null && x0 != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _iro.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      oshitaBun,
                      style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                    ),
                    if (_hiraki == 1) ...[
                      const Divider(height: 12, color: Colors.white24),
                      Text(
                        _senshuGyou(r0, x0),
                        style: const TextStyle(color: Colors.yellowAccent, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      _scrollBako(
                        context,
                        gamenTakasa,
                        Text(
                          x0.setsumei ?? '説明文はありません',
                          style: TextStyle(
                            color: HENSUU.textcolor.withOpacity(0.9),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    // 次の区間を走る選手(区間配置確認のカードを開いたときと同じ。2.0.7)
                    if (_hiraki == 2) ...[
                      const Divider(height: 12, color: Colors.white24),
                      const Text('次の区間を走る選手', style: _chiisai),
                      const SizedBox(height: 2),
                      _scrollBako(context, gamenTakasa, _tsugiPanel(context, r0, x0)),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _hiraki == 0
                          ? 'もう一度押すと、走った選手の説明文が出ます'
                          : (_hiraki == 1 && _tsugiDaseru(x0)
                                ? 'もう一度押すと、次の区間を走る選手が出ます'
                                : 'もう一度押すと閉じます'),
                      style: _chiisai,
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("戻る", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// 小さなボタン(区間の切り替えと同じ形。[onTap] がnullなら押せない)
  Widget _komaBotan(String moji, bool on, VoidCallback? onTap) {
    final Color iro = onTap == null ? Colors.white24 : (on ? _iro : Colors.white70);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? _iro.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: on ? _iro : Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(moji, style: TextStyle(color: iro, fontSize: 13)),
      ),
    );
  }

  /// 縮尺の棒(棒が短すぎず長すぎない、区切りのよい距離を選ぶ)
  Widget _shukushaku(double px) {
    int m = 2000;
    for (final int c in const [10, 20, 50, 100, 200, 500, 1000, 2000]) {
      if (c * px >= 40) {
        m = c;
        break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: m * px, height: 3, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          m < 1000 ? '${m}m' : '${m ~/ 1000}km',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  /// 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒。どちらも折り返す)
  Widget _buildKotei(_IchiKankei b, int dan) {
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区間の切り替え(覚えない)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < b.kukan.length; i++)
              _komaBotan(
                '${b.kukan[i].kk + 1}区',
                i == erabu,
                () => setState(() {
                  _erabu = i;
                  _oshita = -1;
                  _hiraki = 0;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 表示の倍率(「−」「＋」と、おまかせ。覚えない)と縮尺の棒
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _komaBotan(
              '−',
              false,
              dan > 0
                  ? () => setState(() {
                      _omakase = false;
                      _dan = dan - 1;
                    })
                  : null,
            ),
            Text(
              _bairitsuMei[dan],
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            _komaBotan(
              '＋',
              false,
              dan < _bairitsu.length - 1
                  ? () => setState(() {
                      _omakase = false;
                      _dan = dan + 1;
                    })
                  : null,
            ),
            _komaBotan('おまかせ', _omakase, () => setState(() => _omakase = true)),
            _shukushaku(_bairitsu[dan]),
          ],
        ),
      ],
    );
  }

  /// スクロールする部分(説明の文と、道と大学名の四角。道の部分は横にもスクロールする)
  Widget _buildHontai(
    BuildContext context,
    _IchiKankei b,
    _IchiKukan r,
    int dan,
    double gamenTakasa,
  ) {
    const TextStyle setsumei = TextStyle(color: Colors.white70, fontSize: 12, height: 1.5);
    final double px = _bairitsu[dan];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 説明の文は短くする(おまかせと集団の説明は、説明書に書く)
        Text(
          '${r.kk + 1}区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です。',
          style: setsumei,
        ),
        const Text('右の括弧は前の大学との間です(点線は詰めた間)。', style: setsumei),
        if (r.narabi.any((x) => x.jibun))
          const Text('オレンジの枠: あなたの大学', style: setsumei),
        if (b.opAri)
          Text(
            b.gakurenJibun
                ? 'オレンジの点線の枠: 学連選抜(あなたが監督。順位に数えない)'
                : '点線の枠: 学連選抜(順位に数えない)',
            style: setsumei,
          ),
        Text(
          r.kk + 1 < b.zenKukansuu
              ? '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文、さらに押すと次の区間を走る選手が出ます。'
              : '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文が出ます。',
          style: setsumei,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            final _Haichi h = _haichi(b, r, w, scaler, px, gamenTakasa, _omakase);
            // 道と四角と差の部分は、画面より広いときは横にもスクロールする(文は折り返さない)
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: h.haba,
                height: h.takasa,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MichiPainter(h))),
                    // 前の大学(集団)との間の距離と秒差(括弧の真ん中。詰めた間は「(詰めています)」を添える)
                    for (final _Aida a in h.aida)
                      Positioned(
                        left: h.mojiX,
                        top: a.top,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.moji, style: _migiStyle, softWrap: false),
                            if (a.tsume) const Text(_tsumeMoji, style: _chiisai, softWrap: false),
                          ],
                        ),
                      ),
                    // シード権ライン
                    if (h.seedTop != null)
                      Positioned(
                        left: 0,
                        top: h.seedTop!,
                        width: h.haba,
                        child: Row(
                          children: [
                            const Text('シード権ライン', style: _seedMojiStyle, softWrap: false),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 8,
                                child: CustomPaint(painter: _TensenPainter()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 大学の四角
                    for (final _Gyou g in h.gyou)
                      for (final _Hako hk in g.hako)
                        Positioned(
                          left: hk.x,
                          top: g.y + (g.h - hk.h) / 2,
                          width: hk.w,
                          height: hk.h,
                          child: _hakoWidget(b, r, hk),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 大学の四角(押すと、画面の下に差を出す。押すたびに、走った選手の説明文、次の区間を走る選手と進み、
  /// その次に押すと消す。2.0.7)
  Widget _hakoWidget(_IchiKankei b, _IchiKukan r, _Hako hk) {
    final _IchiDaigaku x = r.narabi[hk.i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    final bool erabareta = _oshita == hk.i;
    final bool ichii = identical(x, r.top);
    final Color wakuIro = erabareta
        ? _iro
        : (orange ? _jibunIro : (ichii ? Colors.white : Colors.white38));
    final double futosa = (erabareta || orange || ichii) ? _wakuSaidai : 1;
    // 学連選抜は点線の枠(押したときは水色の線の枠)
    final bool tensen = x.op && !erabareta;
    Widget naka = Container(
      padding: const EdgeInsets.symmetric(horizontal: _hakoYoko, vertical: _hakoTate),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: tensen ? null : Border.all(color: wakuIro, width: futosa),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Text.rich(_hakoSpan(b, r, hk.i), softWrap: false, maxLines: 1),
    );
    if (tensen) {
      naka = CustomPaint(
        foregroundPainter: _TensenWakuPainter(orange ? _jibunIro : Colors.white),
        child: naka,
      );
    }
    return GestureDetector(
      // 押した四角は、下の帯が伸びて隠れるときに見えるようにするため、印を付けておく
      key: erabareta ? _oshitaKey : null,
      behavior: HitTestBehavior.opaque,
      onTap: () => _hakoOsu(r, hk.i),
      child: naka,
    );
  }
}

/// 点線で線を引く(パスに沿って、4px引いて3px空ける)
void _tensenDeHiku(Canvas canvas, Path path, Paint p) {
  for (final metric in path.computeMetrics()) {
    double d = 0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), p);
      d += 7;
    }
  }
}

/// 道の帯・切れ目の印・いちばん前の線・間の括弧
class _MichiPainter extends CustomPainter {
  final _Haichi h;

  _MichiPainter(this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint michi = Paint()..color = _michiIro;
    final double shita = size.height - 6;
    // 道の帯(詰めた間の真ん中は空ける)
    double y = h.michiUe;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      if (m - 5 > y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, m - 5), const Radius.circular(6)),
          michi,
        );
      }
      y = m + 5;
    }
    if (shita > y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, shita), const Radius.circular(6)),
        michi,
      );
    }
    // 切れ目の印(帯の切れ目の上下に点線)
    final Paint kiremeSen = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      for (double x = 0; x < h.michiHaba; x += 6) {
        final double x2 = math.min(x + 3, h.michiHaba);
        canvas.drawLine(Offset(x, m - 5), Offset(x2, m - 5), kiremeSen);
        canvas.drawLine(Offset(x, m + 5), Offset(x2, m + 5), kiremeSen);
      }
    }
    // 2校以上の集団を囲む枠(薄い線と、ほんの少し明るい塗り)
    final Paint wakuNuri = Paint()..color = const Color(0x12FFFFFF);
    final Paint wakuSen = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final Rect rc in h.waku) {
      final RRect rr = RRect.fromRectAndRadius(rc, const Radius.circular(8));
      canvas.drawRRect(rr, wakuNuri);
      canvas.drawRRect(rr, wakuSen);
    }
    // いちばん前(1位)の線
    canvas.drawLine(
      Offset(0, h.sentouY),
      Offset(h.michiHaba, h.sentouY),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
    // 前の大学(集団)との間の括弧(詰めた間は点線)
    final Paint kakko = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final _Aida a in h.aida) {
      final Path path = Path()
        ..moveTo(h.kakkoX, a.y0)
        ..lineTo(h.kakkoX + 8, a.y0)
        ..lineTo(h.kakkoX + 8, a.y1)
        ..lineTo(h.kakkoX, a.y1);
      if (a.tsume) {
        _tensenDeHiku(canvas, path, kakko);
      } else {
        canvas.drawPath(path, kakko);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MichiPainter old) => old.h != h;
}

/// 学連選抜の四角の点線の枠
class _TensenWakuPainter extends CustomPainter {
  final Color iro;

  _TensenWakuPainter(this.iro);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = iro
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path waku = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(4),
        ),
      );
    _tensenDeHiku(canvas, waku, p);
  }

  @override
  bool shouldRepaint(covariant _TensenWakuPainter old) => old.iro != iro;
}

/// シード権ラインの点線
class _TensenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 1;
    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TensenPainter old) => false;
}
