import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/seichou_type.dart' show seichouTypeWariai, seichouTypeWariaiIreru;
import 'package:ekiden/kansuu/mokuhyou_kimekata.dart' show mokuhyouKimekataTaikousen;
import 'package:ekiden/kansuu/koukou.dart'
    show koukouKaisuuUnivId, koukouOkiniiriMojiKaraYomu, koukouOkiniiriMojiNiIreru; // 高校のお気に入り(2.0.3)

// ------------------------------------------------------------
// リセットで残すもの・戻すものの一覧(2.0.3)
//
// 説明画面の設定タブの2つのリセットで、何を残し、何を初期値に戻すかを、この一覧だけで決める。
// ・「名声・育成力と設定を残してやり直す」(main.dart の _runMode101010Processing。おすすめ)
// ・「全てリセットしてやり直す」(main.dart の _runMode0010Processing。新しいゲームを始めるときも同じ処理)
// 2.0.2までは、設定の保存場所によって、たまたま残ったり消えたりしていた
// (監督データの予備の配列は両方のリセットで0に戻り、進行データ・大学データ・アルバムの設定は残っていた)。
//
// ・分類ごとの扱い(resetNokosu):
//   ・進み具合(選手・記録・年月日など): どちらのリセットでも消す
//   ・勢力図(名声・育成力・名声の横並び): 全てリセットでは初期値、設定を残すリセットでは残す
//   ・ルール(レースや育成などの設定): 全てリセットでは初期値、設定を残すリセットでは残す
//   ・作ったもの・表示(大学名・メモ・カスタム駅伝の名前とコース・表示の好みなど): どちらのリセットでも残す
//   ・始めに選ぶ(難易度・総監督をする大学): リセットのあとの画面で選び直す
// ・リセットの流れ(main.dart):
//   1. 残すことになっている設定の値を、先に取っておく(resetMaeniToru)
//   2. 今まで通りのリセット(予備の配列を0にする・初期化する)を行う
//   3. 戻すことになっている設定を、ここに書いた初期値にする(shokika。nullなら2.で初期値になる)
//   4. 取っておいた値を書き戻して保存する(3.と4.は resetAtoDeModosu。新しい選手を作る前に行う)
// ・セーブデータを読み込んだとき(save_load_screen.dart の _importFromSlot)は、ゲームのデータを丸ごとセーブの値で
//   置き換える(世界とそのルールはセーブしたときに戻る)。ただし、この一覧で yomikomiNokosu の行(表示の好み・
//   フリーメモ・高校名鑑のお気に入り)は、読み込む前の今の値を取っておき、読み込んだあとに書き戻す
//   (yomikomiMaeniToru・yomikomiAtoDeModosu。2.0.3。データ共有で受け取った世界を読み込んだときも同じ)
// ・QRコードを読み込んだときにどうなるかの印(qr。2.0.3)は、説明用。QRコードの中身は qr_processor.dart に
//   手で書いたもので決まり、この印を変えてもQRコードの中身は変わらない。印は、一覧表の画面と、
//   QRコードの画面(settings_qr_page.dart)の内容一覧に出す。QRコードに項目を足したり減らしたりしたら、印も合わせる。
//   食い違いは、開発中のビルドで一覧表の画面に赤字で出る(resetQrZure。監督データの予備の配列の分だけ)
// ・説明画面の設定タブの一番上の「リセット・ロード・QRで残るもの・変わるもの」(reset_ichiran_gamen.dart)は、
//   この一覧から作る
// ・設定を追加したら、この一覧に1行足し、分類とQRコードの印を決める(CLAUDE.md)。監督データの予備の配列を使ったら、
//   その番号を一覧の hozon か、下の resetSusumiBangou に書く。書き忘れると、開発中のビルドで、
//   一覧表の画面とリセットのときに警告が出る(resetMitourokuBangou)
// ------------------------------------------------------------

/// 分類
enum ResetBunrui {
  /// ゲームの進み具合(どちらのリセットでも消す)
  susumi,

  /// 勢力図(全てリセットでは初期値、設定を残すリセットでは残す)
  seiryoku,

  /// 遊び方のルール(全てリセットでは初期値、設定を残すリセットでは残す)
  rule,

  /// 作ったもの・表示の好み(どちらのリセットでも残す)
  tsukutta,

  /// 始めに選ぶもの(リセットのあとの画面で選び直す)
  erabinaoshi,
}

/// 分類の名前
String resetBunruiMei(ResetBunrui b) {
  switch (b) {
    case ResetBunrui.susumi:
      return '進み具合';
    case ResetBunrui.seiryoku:
      return '勢力図';
    case ResetBunrui.rule:
      return 'ルール';
    case ResetBunrui.tsukutta:
      return '作ったもの・表示';
    case ResetBunrui.erabinaoshi:
      return '始めに選ぶ';
  }
}

/// リセットで残すか([zenbu] が true なら「全てリセットしてやり直す」、false なら「名声・育成力と設定を残してやり直す」)
bool resetNokosu(ResetBunrui b, {required bool zenbu}) {
  switch (b) {
    case ResetBunrui.susumi:
      return false;
    case ResetBunrui.seiryoku:
      return !zenbu;
    case ResetBunrui.rule:
      return !zenbu;
    case ResetBunrui.tsukutta:
      return true;
    case ResetBunrui.erabinaoshi:
      return false;
  }
}

/// リセットのときに読み書きするデータ(リセットの前に読み、同じものをリセットのあとにも使う)
class ResetDougu {
  ResetDougu._(this.kantoku, this.gh, this.univ, this.album);

  final KantokuData kantoku;
  final Ghensuu gh;

  /// 大学(大学idの順)
  final List<UnivData> univ;
  final Album? album;

  /// 今のデータを読む(読めなければnull)
  static ResetDougu? yomu() {
    if (!Hive.isBoxOpen('kantokuBox') || !Hive.isBoxOpen('ghensuuBox') || !Hive.isBoxOpen('univBox')) {
      return null;
    }
    final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
    if (k == null || gh == null) return null;
    final List<UnivData> univ = Hive.box<UnivData>('univBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final Album? album = Hive.isBoxOpen('albumBox') ? Hive.box<Album>('albumBox').get('AlbumData') : null;
    return ResetDougu._(k, gh, univ, album);
  }

  /// 大学id[id]の大学(なければnull)
  UnivData? daigaku(int id) {
    for (final UnivData u in univ) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// 全部を保存する
  Future<void> hozon() async {
    await kantoku.save();
    await Hive.box<Ghensuu>('ghensuuBox').put('global_ghensuu', gh);
    for (final UnivData u in univ) {
      await u.save();
    }
    final Album? a = album;
    if (a != null) await a.save();
  }
}

/// 設定の保存場所1つ分の読み書き
class ResetHozon {
  ResetHozon({required this.toru, required this.modosu, this.shokika, this.bangou = const []});

  /// 今の値を取る(残すときに、リセットの前に読む)
  final Object? Function(ResetDougu d) toru;

  /// 取っておいた値を書き戻す
  final void Function(ResetDougu d, Object? atai) modosu;

  /// 初期値にする(戻すときに、リセットのあとに呼ぶ)。nullなら、今までのリセットの処理で初期値になる
  final void Function(ResetDougu d)? shokika;

  /// 使っている監督データの予備の配列の番号((配列, はじめ, おわり)。書き忘れの見張り用)
  final List<(int, int, int)> bangou;
}

/// QRコード(説明画面の設定タブの「各種設定のQRコード」など)を読み込んだときにどうなるか(2.0.3)
/// 説明用の印。一覧表の画面と、QRコードの画面の内容一覧に出すためだけに使う。
/// QRコードの中身は qr_processor.dart に手で書いたもので決まり、この印を変えてもQRコードの中身は変わらない
/// (QRコードの形を変えると、古いQRコードが読めなくなるおそれがあるため)。
/// 食い違いは、開発中のビルドで一覧表の画面に赤字で出る(resetQrZure)
enum ResetQr {
  /// QRコードの値になる(QRコードに入る)
  atai,

  /// 一部だけQRコードの値になる(どこが入るかを qrHosoku に書く)
  ichibu,

  /// QRコードに入らない(読み込んでも今のまま)
  imanomama,
}

/// 一覧の1行
class ResetKoumoku {
  ResetKoumoku(
    this.mei,
    this.midashi,
    this.bunrui,
    this.hozon, {
    required this.qr,
    this.qrHosoku = '',
    this.hosoku = '',
    this.yomikomiNokosu = false,
  });

  /// 名前(一覧表の画面に出す)
  final String mei;

  /// 一覧表の画面の見出し(resetMidashiJun のどれか)
  final String midashi;
  final ResetBunrui bunrui;

  /// 保存場所(空なら、今までの処理だけで分類どおりになるもの)
  final List<ResetHozon> hozon;

  /// 一覧表の画面に添える補足(空なら出さない)
  final String hosoku;

  /// セーブデータを読み込んだときに、セーブの値ではなく今の値を残すか(2.0.3。表示の好み・フリーメモ・
  /// 高校名鑑のお気に入り。trueにするときは、hozon に保存場所を書く)
  final bool yomikomiNokosu;

  /// QRコードを読み込んだときにどうなるか(説明用。省略できない。行を足すたびに、QRコードに入れるかを決める)
  final ResetQr qr;

  /// QRコードについての補足(一部だけ入るときは、どこが入るか。一覧表の画面とQRコードの画面に出す。空なら出さない)
  final String qrHosoku;
}

/// 一覧表の画面の見出しの並び(設定タブの見出しの順)
const List<String> resetMidashiJun = [
  'モードと大会',
  '総監督と難易度',
  'レースのタイム',
  'コンピュータの大学の作戦',
  '育成と名声',
  '留学生',
  '大学画面などの設定',
  '表示',
  '作ったもの',
  'ゲームの進み具合',
];

/// 監督データの予備の配列
List<int> _hairetsu(KantokuData k, int h) {
  switch (h) {
    case 2:
      return k.yobiint2;
    case 3:
      return k.yobiint3;
    case 4:
      return k.yobiint4;
    default:
      return k.yobiint5;
  }
}

/// 監督データの予備の配列 yobiint[h] の [kara]〜[made](初期値は今までのリセットの処理で入る)
ResetHozon _kantoku(int h, int kara, int made) => ResetHozon(
  toru: (ResetDougu d) {
    final List<int> l = _hairetsu(d.kantoku, h);
    return <int>[for (int i = kara; i <= made && i < l.length; i++) l[i]];
  },
  modosu: (ResetDougu d, Object? atai) {
    final List<int> l = _hairetsu(d.kantoku, h);
    final List<int> a = atai as List<int>;
    for (int j = 0; j < a.length && kara + j < l.length; j++) {
      l[kara + j] = a[j];
    }
  },
  bangou: [(h, kara, made)],
);

/// 大学[id]の name_tanshuku(文字の欄。[shokichi] がnullなら、今までのリセットの処理で初期値になる)
ResetHozon _tanshuku(int id, {String? shokichi}) => ResetHozon(
  toru: (ResetDougu d) => d.daigaku(id)?.name_tanshuku,
  modosu: (ResetDougu d, Object? atai) {
    final UnivData? u = d.daigaku(id);
    if (u != null && atai is String) u.name_tanshuku = atai;
  },
  shokika: shokichi == null
      ? null
      : (ResetDougu d) {
          final UnivData? u = d.daigaku(id);
          if (u != null) u.name_tanshuku = shokichi;
        },
);

/// 駅伝コース([race] の大会番号。区間数・距離・登り下りなど。初期値は GhensuuShokika で入る。カスタム駅伝は入らない)
ResetHozon _course(List<int> race) => ResetHozon(
  toru: (ResetDougu d) {
    final Ghensuu g = d.gh;
    return <List<Object>>[
      for (final int r in race)
        [
          g.kukansuu_taikaigoto[r],
          List<double>.of(g.kyori_taikai_kukangoto[r]),
          List<double>.of(g.heikinkoubainobori_taikai_kukangoto[r]),
          List<double>.of(g.heikinkoubaikudari_taikai_kukangoto[r]),
          List<double>.of(g.kyoriwariainobori_taikai_kukangoto[r]),
          List<double>.of(g.kyoriwariaikudari_taikai_kukangoto[r]),
          List<int>.of(g.noborikudarikirikaekaisuu_taikai_kukangoto[r]),
        ],
    ];
  },
  modosu: (ResetDougu d, Object? atai) {
    final Ghensuu g = d.gh;
    final List<List<Object>> a = atai as List<List<Object>>;
    void utsusu<T>(List<T> moto, List<T> saki) {
      for (int j = 0; j < moto.length && j < saki.length; j++) {
        saki[j] = moto[j];
      }
    }

    for (int n = 0; n < race.length && n < a.length; n++) {
      final int r = race[n];
      g.kukansuu_taikaigoto[r] = a[n][0] as int;
      utsusu<double>(a[n][1] as List<double>, g.kyori_taikai_kukangoto[r]);
      utsusu<double>(a[n][2] as List<double>, g.heikinkoubainobori_taikai_kukangoto[r]);
      utsusu<double>(a[n][3] as List<double>, g.heikinkoubaikudari_taikai_kukangoto[r]);
      utsusu<double>(a[n][4] as List<double>, g.kyoriwariainobori_taikai_kukangoto[r]);
      utsusu<double>(a[n][5] as List<double>, g.kyoriwariaikudari_taikai_kukangoto[r]);
      utsusu<int>(a[n][6] as List<int>, g.noborikudarikirikaekaisuu_taikai_kukangoto[r]);
    }
  },
);

/// 一覧(設定を追加したら、ここに1行足す。並びは一覧表の画面の並び)
List<ResetKoumoku> resetIchiran() {
  return [
    // ---- モードと大会 ----
    ResetKoumoku('箱庭モード/通常モード', 'モードと大会', ResetBunrui.rule, [_kantoku(2, 17, 17)], qr: ResetQr.imanomama),
    ResetKoumoku('カスタム駅伝(開催するか・獲得名声倍率)', 'モードと大会', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => <int>[
          d.gh.spurtryokuseichousisuu1,
          d.gh.spurtryokuseichousisuu4,
          d.gh.spurtryokuseichousisuu5,
        ],
        modosu: (ResetDougu d, Object? atai) {
          final List<int> a = atai as List<int>;
          d.gh.spurtryokuseichousisuu1 = a[0];
          d.gh.spurtryokuseichousisuu4 = a[1];
          d.gh.spurtryokuseichousisuu5 = a[2];
        },
        // 初期値は、開催する・倍率1/10(ghensuu.dart の Ghensuu.initial と同じ)
        shokika: (ResetDougu d) {
          d.gh.spurtryokuseichousisuu1 = 1;
          d.gh.spurtryokuseichousisuu4 = 1;
          d.gh.spurtryokuseichousisuu5 = 10;
        },
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('カスタム駅伝(出場制限)', 'モードと大会', ResetBunrui.rule, [_kantoku(2, 78, 79)], qr: ResetQr.atai),
    ResetKoumoku('カスタム駅伝(名前・コース)', 'モードと大会', ResetBunrui.tsukutta, [
      _tanshuku(0),
      _course([5]),
    ], qr: ResetQr.ichibu, qrHosoku: 'コースだけ入ります(カスタム駅伝コースのQRコード)。名前は入りません。'),
    ResetKoumoku('記録会時期設定', 'モードと大会', ResetBunrui.rule, [_kantoku(2, 14, 14)], qr: ResetQr.atai),
    ResetKoumoku('駅伝コース編集(10月・11月・正月・予選2つ)', 'モードと大会', ResetBunrui.rule, [
      _course([0, 1, 2, 3, 4]),
    ], qr: ResetQr.atai, qrHosoku: '駅伝ごとのコースのQRコードで入ります(予選のコースは編集できません)。'),
    // ---- 総監督と難易度 ----
    ResetKoumoku('総監督をする大学', '総監督と難易度', ResetBunrui.erabinaoshi, [], qr: ResetQr.imanomama),
    ResetKoumoku('難易度(鬼・難しい・普通・易しい)', '総監督と難易度', ResetBunrui.erabinaoshi, [], qr: ResetQr.atai),
    ResetKoumoku('難易度変更2', '総監督と難易度', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => d.gh.ondoflag,
        modosu: (ResetDougu d, Object? atai) => d.gh.ondoflag = atai as int,
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('難易度「極」「天」', '総監督と難易度', ResetBunrui.rule, [_kantoku(2, 0, 0)], qr: ResetQr.atai),
    ResetKoumoku('選手の能力を見抜く総監督の能力', '総監督と難易度', ResetBunrui.susumi, [], qr: ResetQr.imanomama),
    // ---- レースのタイム ----
    ResetKoumoku('全体・区間ごとタイム調整(カスタム駅伝も)', 'レースのタイム', ResetBunrui.rule, [
      _kantoku(5, 30, 60),
      _kantoku(5, 80, 89),
    ], qr: ResetQr.atai, qrHosoku: '全体は各種設定のQRコード、区間ごとは駅伝ごとのタイム調整のQRコードで入ります。'),
    ResetKoumoku('長距離タイム抑制設定', 'レースのタイム', ResetBunrui.rule, [
      _kantoku(2, 13, 13),
      // ON/OFF(大学id 9 の文字の欄。初期値はON)
      _tanshuku(9, shokichi: '1'),
    ], qr: ResetQr.atai),
    ResetKoumoku('能力のタイムへの影響度設定', 'レースのタイム', ResetBunrui.rule, [_kantoku(2, 68, 74)], qr: ResetQr.atai),
    ResetKoumoku('調子関連設定(コンピュータの大学の体調不良も)', 'レースのタイム', ResetBunrui.rule, [
      _kantoku(2, 2, 11),
      _kantoku(2, 21, 21),
    ], qr: ResetQr.atai),
    ResetKoumoku('目標順位・指示の補正設定(主将の特典も)', 'レースのタイム', ResetBunrui.rule, [
      _kantoku(2, 64, 67),
      _kantoku(4, 74, 74),
    ], qr: ResetQr.atai),
    ResetKoumoku('集団走設定', 'レースのタイム', ResetBunrui.rule, [_kantoku(2, 84, 84)], qr: ResetQr.atai),
    ResetKoumoku('学連選抜モチベーション設定', 'レースのタイム', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => d.album?.yobiint4,
        modosu: (ResetDougu d, Object? atai) {
          final Album? a = d.album;
          if (a != null && atai is int) a.yobiint4 = atai;
        },
        // 初期値は補正なし(1.8.2から)
        shokika: (ResetDougu d) => d.album?.yobiint4 = 0,
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('実力発揮度(大学の個性)', 'レースのタイム', ResetBunrui.rule, [_kantoku(5, 0, 29)], qr: ResetQr.atai),
    // ---- コンピュータの大学の作戦 ----
    ResetKoumoku('最適解区間配置確率設定', 'コンピュータの大学の作戦', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => d.album?.tourokusuu_total,
        modosu: (ResetDougu d, Object? atai) {
          final Album? a = d.album;
          if (a != null && atai is int) a.tourokusuu_total = atai;
        },
        // 初期値は30%
        shokika: (ResetDougu d) => d.album?.tourokusuu_total = 30,
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('戦略的エントリー確率設定', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(2, 34, 34)], qr: ResetQr.atai),
    ResetKoumoku('目標順位決め方設定(コンピュータの大学)', 'コンピュータの大学の作戦', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => d.gh.spurtryokuseichousisuu2,
        modosu: (ResetDougu d, Object? atai) => d.gh.spurtryokuseichousisuu2 = atai as int,
        // 初期値は対校戦順位追従(2.0.1から)
        shokika: (ResetDougu d) => d.gh.spurtryokuseichousisuu2 = mokuhyouKimekataTaikousen,
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('コンピュータ金銀使用', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(2, 33, 33)], qr: ResetQr.atai),
    ResetKoumoku('コンピュータスカウト(大学ごとの方針・性格・評価の割合も)', 'コンピュータの大学の作戦', ResetBunrui.rule, [
      _kantoku(2, 58, 63),
      _kantoku(2, 87, 87),
      _kantoku(3, 40, 69),
    ], qr: ResetQr.atai),
    ResetKoumoku('区間配置の方針(最適解の使い方も)', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(2, 80, 83)], qr: ResetQr.atai),
    ResetKoumoku('正月駅伝予選の指示と集団走', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(2, 89, 89)], qr: ResetQr.atai),
    ResetKoumoku('強化プロジェクト設定', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(3, 80, 80)], qr: ResetQr.atai),
    ResetKoumoku('監督の母校パイプ設定', 'コンピュータの大学の作戦', ResetBunrui.rule, [_kantoku(3, 84, 84)], qr: ResetQr.atai),
    // ---- 育成と名声 ----
    // 育成力と名声は、ShokitiUnivdata の維持の印で残すか決める(main.dart で resetNokosu から渡す)
    ResetKoumoku('育成力', '育成と名声', ResetBunrui.seiryoku, [], qr: ResetQr.atai),
    ResetKoumoku('金銀支給量設定', '育成と名声', ResetBunrui.rule, [
      _kantoku(2, 12, 12),
      _kantoku(3, 70, 73),
    ], qr: ResetQr.atai),
    ResetKoumoku('年間強化練習効果設定', '育成と名声', ResetBunrui.rule, [_kantoku(2, 16, 16)], qr: ResetQr.atai),
    ResetKoumoku('成長タイプ設定(割合・限界突破・13分台の優遇)', '育成と名声', ResetBunrui.rule, [
      // 割合(初期値は GhensuuShokika で入る)
      ResetHozon(
        toru: (ResetDougu d) => seichouTypeWariai(d.gh),
        modosu: (ResetDougu d, Object? atai) => seichouTypeWariaiIreru(d.gh, atai as List<int>),
      ),
      _kantoku(3, 75, 75),
      _kantoku(2, 85, 85),
    ], qr: ResetQr.atai),
    ResetKoumoku('名声・名声の履歴', '育成と名声', ResetBunrui.seiryoku, [], qr: ResetQr.ichibu, qrHosoku: '名声だけ入ります。読み込むと、年ごとの名声を均して作り直し、名声の履歴に読み込んだことが残ります。'),
    ResetKoumoku('駅伝名声設定', '育成と名声', ResetBunrui.rule, [
      // 大学id 1〜6 の文字の欄(10月・11月・正月駅伝の名声倍率の分子と分母。初期値はどれも1)
      for (int id = 1; id <= 6; id++) _tanshuku(id, shokichi: '1'),
    ], qr: ResetQr.atai),
    ResetKoumoku('入学時名声影響度設定', '育成と名声', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => d.gh.spurtryokuseichousisuu3,
        modosu: (ResetDougu d, Object? atai) => d.gh.spurtryokuseichousisuu3 = atai as int,
        // 初期値はレベル9
        shokika: (ResetDougu d) => d.gh.spurtryokuseichousisuu3 = 9,
      ),
    ], qr: ResetQr.atai),
    ResetKoumoku('名声の横並び設定(ブロック・グループ・名声の固定)', '育成と名声', ResetBunrui.seiryoku, [
      _kantoku(3, 86, 89),
    ], qr: ResetQr.atai),
    // ---- 留学生 ----
    ResetKoumoku('留学生受け入れ設定', '留学生', ResetBunrui.rule, [
      ResetHozon(
        toru: (ResetDougu d) => <int>[for (final UnivData u in d.univ) u.r],
        modosu: (ResetDougu d, Object? atai) {
          final List<int> a = atai as List<int>;
          for (int i = 0; i < d.univ.length && i < a.length; i++) {
            d.univ[i].r = a[i];
          }
        },
        // 初期値は、どの大学も受け入れない
        shokika: (ResetDougu d) {
          for (final UnivData u in d.univ) {
            u.r = 0;
          }
        },
      ),
    ], qr: ResetQr.atai),
    // ---- 大学画面などの設定 ----
    ResetKoumoku('大学ごとの金銀支給レベル・銀の使い道', '大学画面などの設定', ResetBunrui.rule, [_kantoku(2, 38, 41)], qr: ResetQr.atai),
    ResetKoumoku('学連選抜の監督をするか', '大学画面などの設定', ResetBunrui.rule, [_kantoku(2, 75, 75)], qr: ResetQr.atai),
    // ---- 表示 ----
    ResetKoumoku('持ちタイムの表示(自己ベスト/今季ベスト)', '表示', ResetBunrui.tsukutta, [_kantoku(2, 77, 77)], yomikomiNokosu: true, qr: ResetQr.imanomama),
    ResetKoumoku('趣味・高校時代の表示', '表示', ResetBunrui.tsukutta, [
      _kantoku(2, 15, 15),
      _kantoku(2, 86, 86),
    ], yomikomiNokosu: true, qr: ResetQr.imanomama),
    ResetKoumoku('レーダーチャートのパネル(選手画面・大学画面)', '表示', ResetBunrui.tsukutta, [_kantoku(2, 20, 20)], yomikomiNokosu: true, qr: ResetQr.imanomama),
    ResetKoumoku('今季タイム一覧表で隠す列', '表示', ResetBunrui.tsukutta, [_kantoku(3, 74, 74)], yomikomiNokosu: true, qr: ResetQr.imanomama),
    ResetKoumoku('レース分析の選択・フリーメモの最初に開くメモ', '表示', ResetBunrui.tsukutta, [_kantoku(2, 23, 32)], yomikomiNokosu: true, qr: ResetQr.imanomama),
    // ---- 作ったもの(どのリセットでも触らない) ----
    ResetKoumoku('大学名', '作ったもの', ResetBunrui.tsukutta, [], qr: ResetQr.imanomama, qrHosoku: '個人情報に配慮して、入れていません。'),
    // フリーメモ(大学id 13〜17 の文字の欄)はアプリ全体で1つ。読み込んでも今のまま(2.0.3)。
    // データ共有で書き出すときと取り込むときも空にする(share_exporter.dart の _memoKesu)
    ResetKoumoku('フリーメモの中身', '作ったもの', ResetBunrui.tsukutta, [
      for (int id = 13; id <= 17; id++) _tanshuku(id),
    ], yomikomiNokosu: true, qr: ResetQr.imanomama),
    ResetKoumoku('高校名鑑の編集', '作ったもの', ResetBunrui.tsukutta, [], qr: ResetQr.imanomama),
    // お気に入りは、優勝回数・名簿の編集と同じ大学id 29 の文字の欄のJSONの f。f だけを書き戻す(koukou.dart)
    ResetKoumoku('高校名鑑のお気に入り', '作ったもの', ResetBunrui.tsukutta, [
      ResetHozon(
        toru: (ResetDougu d) =>
            koukouOkiniiriMojiKaraYomu(d.daigaku(koukouKaisuuUnivId)?.name_tanshuku ?? ''),
        modosu: (ResetDougu d, Object? atai) {
          final UnivData? u = d.daigaku(koukouKaisuuUnivId);
          if (u != null && atai is List<int>) {
            u.name_tanshuku = koukouOkiniiriMojiNiIreru(u.name_tanshuku, atai);
          }
        },
      ),
    ], yomikomiNokosu: true, qr: ResetQr.imanomama),
    // ---- ゲームの進み具合 ----
    ResetKoumoku('選手・OB(アルバム)・理事・監督とコーチ・主将', 'ゲームの進み具合', ResetBunrui.susumi, [], qr: ResetQr.imanomama),
    ResetKoumoku('大会・大学・学内の記録、年月日、金銀', 'ゲームの進み具合', ResetBunrui.susumi, [], qr: ResetQr.imanomama),
    ResetKoumoku('強化プロジェクトの実行中・スカウトの記録など', 'ゲームの進み具合', ResetBunrui.susumi, [], qr: ResetQr.imanomama),
    ResetKoumoku('高校の大会の記録と回数', 'ゲームの進み具合', ResetBunrui.susumi, [],
        // 今の高校3年生の世代の回(2.0.4。7月下旬に計算し、次の4月の新入生はこの世代から作る。koukou.dart)
        hosoku: '7月下旬から次の4月までは、今の高校3年生(次の4月に大学に入る世代)の大会の結果も入ります。',
        qr: ResetQr.imanomama),
    ResetKoumoku('スキップして統計データ取得の結果', 'ゲームの進み具合', ResetBunrui.susumi, [
      // 表示用の文(大学id 12 の文字の欄)。人数の集計(yobiint5[61]〜[76])は予備の配列なので0に戻る
      _tanshuku(12, shokichi: ''),
    ], qr: ResetQr.imanomama),
  ];
}

/// 一覧に載せていない、監督データの予備の配列の番号((配列, はじめ, おわり, 用途))
/// ゲームの進み具合と内部の印(どちらのリセットでも0に戻す)と、空き番号
const List<(int, int, int, String)> resetSusumiBangou = [
  (2, 1, 1, '目標達成フラグ'),
  (2, 18, 19, '最初の画面のモード・使わなくなった番号'),
  (2, 22, 22, '区間配置をやり直した印'),
  (2, 35, 37, '当日変更の記録'),
  (2, 42, 57, 'コンピュータの大学の金銀の保有'),
  (2, 76, 76, '学連選抜の目標順位(毎年0に戻す)'),
  (2, 88, 88, 'その年のスカウトの形の記録'),
  (3, 0, 39, '大会記録の比較用・大学分析のスコア'),
  (3, 76, 79, '成長タイプの移行の印・記事の見出しの型'),
  (3, 81, 83, '強化プロジェクトの実行中と前回の型'),
  (3, 85, 85, '記事の見出しの型'),
  (4, 0, 73, '記録・1区の集団・主将など'),
  (4, 75, 75, '前の年度の主将の年度'),
  (4, 76, 78, '高校の大会の記事の見出しの型'),
  (4, 79, 79, '空き'),
  (4, 80, 89, 'カスタム駅伝の大会記録の経過タイム'),
  (5, 61, 76, 'スキップして統計データ取得の人数'),
  (5, 77, 79, '空き'),
];

/// 一覧にも resetSusumiBangou にも載っていない、監督データの予備の配列の番号(「yobiint2[19]」の形。開発用)
List<String> resetMitourokuBangou() {
  final Set<String> notteru = {};
  void tsuika(int h, int kara, int made) {
    for (int i = kara; i <= made; i++) {
      notteru.add('$h:$i');
    }
  }

  for (final ResetKoumoku k in resetIchiran()) {
    for (final ResetHozon h in k.hozon) {
      for (final (int, int, int) b in h.bangou) {
        tsuika(b.$1, b.$2, b.$3);
      }
    }
  }
  for (final (int, int, int, String) b in resetSusumiBangou) {
    tsuika(b.$1, b.$2, b.$3);
  }
  final KantokuData moto = KantokuData();
  return [
    for (final int h in const [2, 3, 4, 5])
      for (int i = 0; i < _hairetsu(moto, h).length; i++)
        if (!notteru.contains('$h:$i')) 'yobiint$h[$i]',
  ];
}

/// 一覧のQRコードの印と、QRコードに実際に書き出している監督データの予備の配列の番号の食い違い(開発用。2.0.3)
/// [kakidashi] は、qr_processor.dart の qrKakidashiYobiBangou で作った「配列:番号」(「2:58」など)の集まり。
/// ・「QRの値」の行の番号が、書き出されていない
/// ・「今のまま」の行の番号が、書き出されている
/// ・書き出している番号が、一覧のどの行にもない(一覧の書き忘れ)
/// (「一部」の行の番号は、書き出していてもいなくてもよい。予備の配列の外の設定は見張れない。
///  見るのは書き出す側だけで、読み込む側は見ない)
List<String> resetQrZure(Set<String> kakidashi) {
  final List<String> zure = [];
  final Set<String> ichiranNoBan = {};
  for (final ResetKoumoku k in resetIchiran()) {
    for (final ResetHozon h in k.hozon) {
      for (final (int, int, int) b in h.bangou) {
        for (int i = b.$2; i <= b.$3; i++) {
          final String ban = '${b.$1}:$i';
          final bool aru = kakidashi.contains(ban);
          ichiranNoBan.add(ban);
          if (k.qr == ResetQr.atai && !aru) {
            zure.add('「${k.mei}」のyobiint${b.$1}[$i]がQRコードにない');
          }
          if (k.qr == ResetQr.imanomama && aru) {
            zure.add('「${k.mei}」のyobiint${b.$1}[$i]がQRコードにある');
          }
        }
      }
    }
  }
  for (final String ban in kakidashi) {
    if (ichiranNoBan.contains(ban)) continue;
    final List<String> p = ban.split(':');
    zure.add('yobiint${p[0]}[${p[1]}]をQRコードに書き出しているが、一覧のどの行にもない');
  }
  return zure;
}

/// セーブデータを読み込む前に、今の値を残すもの(yomikomiNokosu の行)の値を取っておく(2.0.3)
Map<int, List<Object?>> yomikomiMaeniToru(ResetDougu d) {
  final List<ResetKoumoku> l = resetIchiran();
  final Map<int, List<Object?>> m = {};
  for (int i = 0; i < l.length; i++) {
    if (!l[i].yomikomiNokosu) continue;
    m[i] = [for (final ResetHozon h in l[i].hozon) h.toru(d)];
  }
  return m;
}

/// セーブデータを読み込んだあとに、取っておいた値を書き戻して保存する(2.0.3)
/// ([d] は、読み込んだあとのデータで ResetDougu.yomu() し直したもの。読み込みでデータが入れ替わるため)
Future<void> yomikomiAtoDeModosu(ResetDougu d, Map<int, List<Object?>> nokoshi) async {
  final List<ResetKoumoku> l = resetIchiran();
  for (final MapEntry<int, List<Object?>> e in nokoshi.entries) {
    if (e.key < 0 || e.key >= l.length) continue;
    final List<ResetHozon> hozon = l[e.key].hozon;
    for (int j = 0; j < hozon.length && j < e.value.length; j++) {
      hozon[j].modosu(d, e.value[j]);
    }
  }
  await d.hozon();
}

/// リセットの前に、残す設定の値を取っておく(一覧の何行目か → 保存場所ごとの値)
Map<int, List<Object?>> resetMaeniToru(ResetDougu d, {required bool zenbu}) {
  final List<ResetKoumoku> l = resetIchiran();
  final Map<int, List<Object?>> m = {};
  for (int i = 0; i < l.length; i++) {
    if (!resetNokosu(l[i].bunrui, zenbu: zenbu)) continue;
    m[i] = [for (final ResetHozon h in l[i].hozon) h.toru(d)];
  }
  return m;
}

/// リセットのあとに、戻す設定を初期値にし、残す設定を書き戻して、保存する
/// (今までのリセットの処理のあと、新しい選手を作る前に呼ぶ)
Future<void> resetAtoDeModosu(ResetDougu d, Map<int, List<Object?>> nokoshi, {required bool zenbu}) async {
  final List<ResetKoumoku> l = resetIchiran();
  for (int i = 0; i < l.length; i++) {
    final List<Object?>? atai = nokoshi[i];
    if (atai != null) {
      for (int j = 0; j < l[i].hozon.length && j < atai.length; j++) {
        l[i].hozon[j].modosu(d, atai[j]);
      }
    } else {
      for (final ResetHozon h in l[i].hozon) {
        h.shokika?.call(d);
      }
    }
  }
  await d.hozon();
  if (kDebugMode) {
    final List<String> mitouroku = resetMitourokuBangou();
    if (mitouroku.isNotEmpty) {
      debugPrint('【reset_ichiran.dart】一覧に載っていない予備の番号があります: ${mitouroku.join('、')}');
    }
  }
}
