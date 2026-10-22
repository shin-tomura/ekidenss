import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hive/hive.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart'; // 年間強化練習の効果の大きさ(1.8.4)
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/kansuu/shushou.dart'
    show shushouIdUniv, shushouShirushiMoji; // 主将(2.0.1)
import 'package:ekiden/screens/shushou_iro.dart'; // 主将を示す色(2.0.1)
import 'package:ekiden/kansuu/konki_memo.dart'; // 名前の右のメモの列(2.1.0)
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';

// 今季タイム一覧表の右端に追加する列（年間強化・能力）の定義
class _ExtraColDef {
  final String label;
  final int flagIndex; // nouryokumieruflag の添字。-1 は常に表示
  final int Function(SenshuData)? getValue; // 数値列（70・80・90で色付け）
  final String Function(SenshuData)? getText; // 文字列（色付けなし）
  final double width;
  const _ExtraColDef(
    this.label,
    this.flagIndex, {
    this.getValue,
    this.getText,
    this.width = 70,
  });
}

const List<String> _eventLabels = [
  '選手名',
  '駅伝男',
  '平常心',
  '対校5千',
  '対校1万',
  '対校ハーフ',
  '記録5千',
  '記録1万',
  '市民ハーフ',
  '登り10k',
  '下り10k',
  'ロード10k',
  'クロカン10k',
];

const List<int> _raceIndices = [6, 7, 8, 10, 11, 12, 13, 14, 15, 16];

// ------------------------------------------------------------
// 表示する列を選ぶ(1.9.7。画面の表だけ。画像・テキストのコピー・CSVはいつも全部の列)
// ・KantokuData.yobiint3[74] に、隠す列の印をビットで保存する(0なら全部表示。初期値)
// ・ビットは列ごとに決めた番号: 1駅伝男・2平常心・3〜12の10種目(_eventLabels の3〜12)・
//   13〜22の年間強化と能力(_extraCols)・23所属大学・24正月駅伝予選(23と24は学連選抜の表だけ)・
//   25メモ(2.1.0。どの表にも出す)
//   (学連選抜の表と大学の表で列の並びがずれても取り違えないように、画面の列の番号では持たない)
// ・どの画面から開いても同じ選び方になる。各種設定のQRコードには入れない(表示の好みのため)
// ・画面の列は「列の記号」で持つ: 0選手名・1〜22は上の番号と同じ・-1所属大学・-2正月駅伝予選・-3メモ
// ・メモの列(2.1.0。konki_memo.dart)は、表示するときは選手名のすぐ右に置く(固定はしない。ほかの列と
//   一緒に横にスクロールする)。「すべて外す」では外さず、「何も選んでいない」の判定にも数えない
// ------------------------------------------------------------

/// 隠す列の印を保存する番号(KantokuData.yobiint3)
const int konkiRetsuIndex = 74;

/// メモの列の記号(2.1.0)
const int _memoRetsu = -3;

/// 列の記号[code]の、保存するビットの番号
int _retsuBit(int code) =>
    code == -1 ? 23 : (code == -2 ? 24 : (code == _memoRetsu ? 25 : code));

/// 隠す列の印を読む(なければ0=全部表示)
int _kakushiYomu() {
  final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (kantoku == null || kantoku.yobiint3.length <= konkiRetsuIndex) return 0;
  return kantoku.yobiint3[konkiRetsuIndex];
}

/// 隠す列の印を保存する(変更をHiveに保存するために、List全体を更新)
Future<void> _kakushiHozon(int atai) async {
  final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (kantoku == null || kantoku.yobiint3.length <= konkiRetsuIndex) return;
  final List<int> updated = List.from(kantoku.yobiint3);
  updated[konkiRetsuIndex] = atai;
  kantoku.yobiint3 = updated;
  await kantoku.save();
}

// 追加列（表の右端に追加。画像出力には含めない）
final List<_ExtraColDef> _extraCols = [
  _ExtraColDef(
    '年間強化',
    -1,
    getText: (s) => TrainingMenu.getMenuString(s.kaifukuryoku),
    width: 90,
  ),
  _ExtraColDef('安定感', -1, getValue: (s) => s.anteikan),
  _ExtraColDef('長距離粘り', 2, getValue: (s) => s.choukyorinebari),
  _ExtraColDef('スパート力', 3, getValue: (s) => s.spurtryoku),
  _ExtraColDef('カリスマ', 4, getValue: (s) => s.karisuma),
  _ExtraColDef('登り適性', 5, getValue: (s) => s.noboritekisei),
  _ExtraColDef('下り適性', 6, getValue: (s) => s.kudaritekisei),
  _ExtraColDef(
    'アップダウン対応力',
    7,
    getValue: (s) => s.noborikudarikirikaenouryoku,
  ),
  _ExtraColDef('ロード適性', 8, getValue: (s) => s.tandokusou),
  _ExtraColDef('ペース変動対応力', 9, getValue: (s) => s.paceagesagetaiouryoku),
];

// 今季タイム一覧表のデータ(1.8.2で画面の外に出した)
// 画面の表と、テキストのコピー・CSVの共有で使う。生成AIに渡すテキストのまとめボタンからも使う
class _KonkiSeisekiHyou {
  /// trueなら学連選抜のメンバーの表
  final bool gakuren;
  String univName = "";
  List<SenshuData> senshuList = [];

  // 大学のidから名前を引く表(学連選抜の表で、選手の所属大学を出すのに使う)
  Map<int, String> _shozokuMei = {};

  // 能力の見える化フラグ（読み取り専用のコピー）
  List<int> _mieruflag = [];

  // 種目(レース番号)ごとの、この表の選手の中での順位(選手id → 順位)
  final Map<int, Map<int, int>> rankMap = {};

  // この大学の主将の選手id(学連選抜の表と、いないときはnull。2.0.1。shushou.dart)
  int? shushouId;

  _KonkiSeisekiHyou({required int univId, this.gakuren = false}) {
    _junbi(univId);
  }

  void _junbi(int univId) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');
    final Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');

    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
    if (currentGhensuu == null) return;

    // 能力の見える化フラグを読み取る（コピーを持つだけで書き換えはしない）
    _mieruflag = List<int>.from(currentGhensuu.nouryokumieruflag);

    _shozokuMei = {for (final u in univBox.values) u.id: u.name};

    if (gakuren) {
      // 学連選抜のメンバーの表(学連選抜の選手のidは元の選手と同じ)
      // 正月駅伝予選の順位の良い順に並べる
      univName = "学連選抜";
      final Map<int, Senshu_Gakuren_Data> gakurenMap = {
        for (final g in Hive.box<Senshu_Gakuren_Data>(
          'gakurenSenshuBox',
        ).values)
          g.id: g,
      };
      senshuList = senshuBox.values
          .where((s) => gakurenMap[s.id]?.univid == s.univid)
          .toList();
      int yosenJuni(SenshuData s) => s.kukanjuni_race[4][s.gakunen - 1];
      senshuList.sort((a, b) {
        final int juniComp = yosenJuni(a).compareTo(yosenJuni(b));
        return juniComp != 0 ? juniComp : a.id.compareTo(b.id);
      });
    } else {
      univName = univBox.get(univId)?.name ?? "";

      senshuList = senshuBox.values.where((s) => s.univid == univId).toList();
      // 主将(2.0.1)。名前の欄の色と「(4年・主将)」に使う
      shushouId = shushouIdUniv(
        Hive.box<KantokuData>('kantokuBox').get('KantokuData'),
        currentGhensuu,
        senshuList,
        univId,
      );
      senshuList.sort((a, b) {
        int gradeComp = b.gakunen.compareTo(a.gakunen);
        return gradeComp != 0 ? gradeComp : a.id.compareTo(b.id);
      });
    }

    for (int raceIdx in _raceIndices) {
      List<SenshuData> rankList = senshuList.where((s) {
        double t = s.kukantime_race[raceIdx][s.gakunen - 1];
        return t > 0 && t < TEISUU.DEFAULTTIME;
      }).toList();
      rankList.sort(
        (a, b) => a.kukantime_race[raceIdx][a.gakunen - 1].compareTo(
          b.kukantime_race[raceIdx][b.gakunen - 1],
        ),
      );
      rankMap[raceIdx] = {};
      for (int i = 0; i < rankList.length; i++) {
        rankMap[raceIdx]![rankList[i].id] = i + 1;
      }
    }
  }

  String shozoku(SenshuData senshu) => _shozokuMei[senshu.univid] ?? '---';

  /// 主将か(2.0.1)
  bool shushouKa(SenshuData senshu) => senshu.id == shushouId;

  /// 名前の後ろのかっこの中の学年(主将なら「4年・主将」。2.0.1)
  String gakunenMoji(SenshuData senshu) =>
      '${senshu.gakunen}年${shushouKa(senshu) ? shushouShirushiMoji : ''}';

  // 正月駅伝予選の個人順位(1始まり)(学連選抜の表で使う。走っていなければnull)
  int? yosenJuni(SenshuData senshu) {
    final double time = senshu.kukantime_race[4][senshu.gakunen - 1];
    if (time <= 0 || time >= TEISUU.DEFAULTTIME) return null;
    return senshu.kukanjuni_race[4][senshu.gakunen - 1] + 1;
  }

  // 学連選抜の表の画像で、選手名の下に出す所属大学と予選の順位
  String shozokuToYosen(SenshuData senshu) {
    final int? juni = yosenJuni(senshu);
    return juni == null ? shozoku(senshu) : '${shozoku(senshu)} 予選$juni位';
  }

  bool isExtraVisible(_ExtraColDef def) {
    if (def.flagIndex < 0) return true;
    if (def.flagIndex >= _mieruflag.length) return false;
    return _mieruflag[def.flagIndex] == 1;
  }

  String extraText(_ExtraColDef def, SenshuData senshu) {
    if (!isExtraVisible(def)) return '??';
    if (def.getText != null) return def.getText!(senshu);
    return '${def.getValue?.call(senshu) ?? ''}';
  }

  // CSVの行(見出しの行と選手ごとの行)。共有とテキストのコピーで使う
  // 学連選抜の表では、選手名の後ろに所属大学と正月駅伝予選の列を入れる(1.8.2)
  List<List<dynamic>> csvGyou() {
    List<dynamic> header = ['選手名'];
    if (gakuren) {
      header.addAll(['所属大学', '正月駅伝予選(順位)', '正月駅伝予選']);
    }
    header.addAll(['駅伝男', '平常心']);
    for (int i = 3; i < _eventLabels.length; i++) {
      header.add('${_eventLabels[i]}(順位)');
      header.add(_eventLabels[i]);
    }
    for (final def in _extraCols) {
      header.add(def.label);
    }

    List<List<dynamic>> rows = [header];

    for (var senshu in senshuList) {
      List<dynamic> row = ['${senshu.name}(${gakunenMoji(senshu)})'];
      if (gakuren) {
        row.add(shozoku(senshu));
        final int? yosen = yosenJuni(senshu);
        if (yosen == null) {
          row.add("");
          row.add("---");
        } else {
          final double time = senshu.kukantime_race[4][senshu.gakunen - 1];
          final int m = (time / 60).floor();
          final int s = (time % 60).floor();
          row.add(yosen);
          row.add("$m:${s.toString().padLeft(2, '0')}");
        }
      }
      row.addAll([senshu.konjou, senshu.heijousin]);
      for (int raceIdx in _raceIndices) {
        final double time = senshu.kukantime_race[raceIdx][senshu.gakunen - 1];
        final int? rank = rankMap[raceIdx]?[senshu.id];
        if (time <= 0 || time >= TEISUU.DEFAULTTIME) {
          row.add("");
          row.add("---");
        } else {
          final int m = (time / 60).floor();
          final int s = (time % 60).floor();
          row.add(rank ?? "");
          row.add("$m:${s.toString().padLeft(2, '0')}");
        }
      }
      for (final def in _extraCols) {
        row.add(extraText(def, senshu));
      }
      rows.add(row);
    }
    return rows;
  }

  // 共有やコピーのときに付ける注意書き
  String chuuiBun() {
    // 年間強化練習の効果の大きさ(KantokuData.yobiint2[16]。0は効果なし。1.8.4)
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final bool kyoukaNashi =
        kantoku != null &&
        kantoku.yobiint2.length > 16 &&
        kantoku.yobiint2[16] == 0;
    String bun =
        '※能力値は1〜99で、数値が大きいほど優れています。「??」はまだ判明していない能力のため、値を推測しないでください。\n'
        '${kyoukaNashi ? '※年間強化は、このデータでは効果がありません(表の能力値にもレースにも影響しません)。\n' : '※年間強化は、レース時に対応する能力を一時的に上乗せするもので、表の能力値そのものは変わりません（バランス：平均的に上乗せ、スピード：スパート力とペース変動対応力、距離走：長距離粘りとロード適性、登り：登り適性、下り：下り適性、アップダウン：アップダウン対応力）。上乗せが表れるのは、その能力が効く区間・種目だけです(例: 登りは登りの多い区間でだけ効きます)。\n'}'
        '※安定感は、調子を決めるときの最低保証値になる能力です(当日の突発的な体調不良は除く)。\n'
        '※タイムは「分:秒」です(例: 60:43は1時間0分43秒)。\n'
        '※タイムが「---」で順位が空欄の種目は、今季まだ走っていないことを表します(遅いという意味ではありません)。\n'
        '※種目の「対校」は対校戦、「記録」は記録会のレースです。「登り10k」「下り10k」「ロード10k」「クロカン10k」は、それぞれ登り・下り・ロード・クロスカントリーのコースの1万mのレースです。';
    if (gakuren) {
      bun +=
          '\n※学連選抜は、正月駅伝に出場できなかった大学の選手で作るオープン参加のチームです。今季の成績は所属大学の選手として出したものです。\n'
          '※「正月駅伝予選(順位)」は、正月駅伝予選に出た選手全体の中での個人順位です。表は予選の順位の良い順に並んでいます。\n'
          '※ほかの「(順位)」の列は、この表の選手の中での順位です。';
    } else {
      bun += '\n※「(順位)」の列は、この表の選手の中での順位です。';
    }
    return bun;
  }

  // テキストでコピーするときの文(注意書きとCSV形式の表)
  String copyText() {
    final String csvData = const ListToCsvConverter()
        .convert(csvGyou())
        .replaceAll('\r\n', '\n');
    // 大学の表は「〇〇大学」と書く(駅伝出場履歴などのコピーと揃える。学連選抜はそのまま)
    final String hyoMei = gakuren ? univName : '$univName大学';
    return '【$hyoMei 今季成績表(CSV形式)】\n'
        '${chuuiBun()}\n'
        '$csvData\n'
        '#箱庭小駅伝SS';
  }
}

/// 今季タイム一覧表のテキスト(画面の「テキストでコピー」と同じ文)を、画面を開かずに作る(1.8.2)
/// [gakuren]がtrueなら学連選抜のメンバーの表([univId]は使わない)
String konkiSeisekiHyouText({required int univId, bool gakuren = false}) {
  return _KonkiSeisekiHyou(univId: univId, gakuren: gakuren).copyText();
}

class ModalUnivSenshuMatrixView extends StatefulWidget {
  final int targetUnivId;

  /// trueなら学連選抜のメンバーの表にする(targetUnivIdは使わない。1.8.2)
  final bool gakuren;

  /// 区間エントリーの画面から開いたか(2.1.2。自分の大学を表示しているときは、見出しの「メモ」を押すと
  /// 「メモどおり配置する」も選べる。konki_memo.dart の memoHaichiKeikaku)
  final bool kukanEntry;
  const ModalUnivSenshuMatrixView({
    super.key,
    required this.targetUnivId,
    this.gakuren = false,
    this.kukanEntry = false,
  });

  @override
  State<ModalUnivSenshuMatrixView> createState() =>
      _ModalUnivSenshuMatrixViewState();
}

class _ModalUnivSenshuMatrixViewState extends State<ModalUnivSenshuMatrixView> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // 表のデータ(選手の並び・順位・能力が見えるか・所属大学など)。中身は _KonkiSeisekiHyou を参照
  // (上のバーの大学名を押して大学を切り替えたときに作り直すので final にしない。1.9.9)
  late _KonkiSeisekiHyou _hyou;
  List<SenshuData> get _sortedSenshu => _hyou.senshuList;
  String get _univName => _hyou.univName;
  Map<int, Map<int, int>> get _rankMap => _hyou.rankMap;
  String _shozoku(SenshuData senshu) => _hyou.shozoku(senshu);
  int? _yosenJuni(SenshuData senshu) => _hyou.yosenJuni(senshu);
  String _shozokuToYosen(SenshuData senshu) => _hyou.shozokuToYosen(senshu);
  bool _isExtraVisible(_ExtraColDef def) => _hyou.isExtraVisible(def);
  List<List<dynamic>> _csvGyou() => _hyou.csvGyou();
  String _chuuiBun() => _hyou.chuuiBun();

  bool _isInitialized = false;
  bool _isExporting = false;

  // 表示している大学(1.9.9。上のバーの大学名を押して切り替えられる。学連選抜の表では使わない)
  int _univId = 0;

  /// 表示する大学を選ぶ(1.9.9。自分の大学を先頭に、ほかは大学のidの順。全部の大学を出す)
  Future<void> _univErabu() async {
    if (widget.gakuren || _isExporting) return;
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final int myUnivId = gh?.MYunivid ?? -1;
    final List<UnivData> univs = Hive.box<UnivData>('univBox').values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final List<UnivData> narabi = [
      ...univs.where((u) => u.id == myUnivId),
      ...univs.where((u) => u.id != myUnivId),
    ];
    final int? erabi = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            '表示する大学',
            style: TextStyle(color: Colors.black),
          ),
          children: [
            for (final UnivData u in narabi)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(u.id),
                child: Text(
                  '${u.name}大学${u.id == myUnivId ? '(自分の大学)' : ''}',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: u.id == _univId
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (erabi == null || erabi == _univId || !mounted) return;
    setState(() {
      _univId = erabi;
      _hyou = _KonkiSeisekiHyou(univId: erabi);
    });
  }

  final double _rowHeight = 75.0;

  // 表示する列(1.9.7)。隠す列の印と、画面に出す列の記号の並び、右に区切り線を引く列の記号
  int _kakushi = 0;
  List<int> _retsu = [];
  Set<int> _migiSenRetsu = {};

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  // シリーズの境界線（右側）を引くべきカラムインデックスを定義
  // (画像の表で使う。画像はいつも全部の列なので、列の番号で決めたまま。画面の表は _migiSen)
  bool _shouldHasSeriesBorder(int colIdx) {
    return colIdx == 2 || colIdx == 5 || colIdx == 8;
  }

  // ---- 表示する列(1.9.7) ----

  /// この表で選べる列の記号(表の並び順。選手名は選べない。メモは先頭)
  List<int> get _sentakuKouho => [
    _memoRetsu,
    if (widget.gakuren) ...[-1, -2],
    for (int c = 1; c < _eventLabels.length + _extraCols.length; c++) c,
  ];

  /// 列の記号[code]を、今の印で表示するか
  bool _mieru(int code, int kakushi) => (kakushi & (1 << _retsuBit(code))) == 0;

  /// 列のまとまり(右の区切り線は、次に表示する列とまとまりが違うときに引く)
  /// 0選手名・1駅伝男と平常心・2対校戦・3記録会・4夏のタイムトライアル・5年間強化と能力・6学連選抜の2列
  int _matomari(int code) {
    if (code == _memoRetsu) return 7; // メモ(2.1.0)
    if (code < 0) return 6;
    if (code == 0) return 0;
    if (code <= 2) return 1;
    if (code <= 5) return 2;
    if (code <= 8) return 3;
    if (code < _eventLabels.length) return 4;
    return 5;
  }

  /// 画面に出す列の並びと、右に区切り線を引く列を作る
  void _retsuTsukuru() {
    // メモの列は別に扱う(選手名のすぐ右。2.1.0)
    final List<int> kouho = [
      for (final int c in _sentakuKouho)
        if (c != _memoRetsu) c,
    ];
    List<int> mieru = [
      for (final int c in kouho)
        if (_mieru(c, _kakushi)) c,
    ];
    // 何も選んでいないとき(「すべて外す」のあとや、学連選抜の表だけの列しか選んでいないときの
    // 大学の表)は、選手名だけの表にせず、全部の列を出す
    if (mieru.isEmpty) mieru = kouho;
    _retsu = [0, if (_mieru(_memoRetsu, _kakushi)) _memoRetsu, ...mieru];
    _migiSenRetsu = {
      for (int i = 1; i + 1 < _retsu.length; i++)
        if (_matomari(_retsu[i]) != _matomari(_retsu[i + 1])) _retsu[i],
    };
  }

  /// 画面の表で、列の記号[code]の右に区切り線を引くか
  bool _migiSen(int code) => _migiSenRetsu.contains(code);

  /// 列の記号[code]の名前
  String _retsuMei(int code) {
    if (code == _memoRetsu) return 'メモ';
    if (code == -1) return '所属大学';
    if (code == -2) return '正月駅伝予選';
    if (code < _eventLabels.length) return _eventLabels[code];
    return _extraCols[code - _eventLabels.length].label;
  }

  /// 表示する列を選ぶ画面(チップで選ぶ。アプリのほかの部分に合わせた暗い背景。1.9.7)
  /// 「すべて外す」で全部外してから、比べたい列だけを選べる(何も選んでいないときは、表には全部の列を出す)
  Future<void> _retsuSentaku() async {
    const Color haikei = Color.fromARGB(255, 30, 30, 30);
    final ButtonStyle botan = TextButton.styleFrom(
      foregroundColor: HENSUU.LinkColor,
      disabledForegroundColor: Colors.white38,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialog) {
            final List<int> kouho = _sentakuKouho;
            // この表で選べる列を全部隠す印(ほかの表だけの列の印はそのまま残す。
            // メモの列は「すべて外す」では外さない。2.1.0)
            final int zenbu = kouho
                .where((c) => c != _memoRetsu)
                .fold<int>(0, (m, c) => m | (1 << _retsuBit(c)));
            final bool zenbuHazushita = (_kakushi & zenbu) == zenbu;
            Future<void> kaeru(int atai) async {
              setState(() {
                _kakushi = atai;
                _retsuTsukuru();
              });
              setDialog(() {});
              await _kakushiHozon(atai);
            }

            return AlertDialog(
              backgroundColor: haikei,
              title: const Text(
                '表示する列を選ぶ',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選んだ列を、表の並び順で詰めて表示します。何も選んでいないときは、全部の列を表示します。'
                      'どの画面から開いても同じ選び方になります。'
                      '画像・テキストのコピー・CSVは、いつも全部の列です(メモは入りません)。'
                      'メモの列は「すべて外す」では外れません。',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final int c in kouho)
                          FilterChip(
                            label: Text(_retsuMei(c)),
                            selected: _mieru(c, _kakushi),
                            onSelected: (bool v) {
                              final int bit = 1 << _retsuBit(c);
                              kaeru(v ? (_kakushi & ~bit) : (_kakushi | bit));
                            },
                            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            selectedColor: Colors.blue.shade700,
                            backgroundColor: Colors.grey.shade800,
                            checkmarkColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: botan,
                  onPressed: zenbuHazushita ? null : () => kaeru(_kakushi | zenbu),
                  child: const Text('すべて外す'),
                ),
                TextButton(
                  style: botan,
                  onPressed: _kakushi == 0 ? null : () => kaeru(0),
                  child: const Text('すべて表示に戻す'),
                ),
                TextButton(
                  style: botan,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final Color _seriesBorderColor = Colors.white.withOpacity(0.5);
  final double _seriesBorderWidth = 2.0;

  // --- テキストでコピー(生成AIに渡して区間配置などを相談するとき用。1.8.2) ---
  Future<void> _copyAsText() async {
    await Clipboard.setData(ClipboardData(text: _hyou.copyText()));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$_univName の今季成績表をコピーしました')));
    }
  }

  // --- CSV出力機能 ---
  Future<void> _exportAndShareCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final List<List<dynamic>> rows = _csvGyou();

      String csvData = const ListToCsvConverter().convert(rows);
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      final List<int> csvBytes = utf8.encode(csvData);
      final Uint8List combinedBytes = Uint8List.fromList([...bom, ...csvBytes]);
      final directory = await getTemporaryDirectory();
      final String path = "${directory.path}/${_univName}_records.csv";
      final File file = File(path);
      await file.writeAsBytes(combinedBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: '$_univName 選手記録データ',
          text: '$_univName の今季成績表(CSV)を共有します。\n${_chuuiBun()}',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      debugPrint('CSV出力エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- 画像出力機能 ---
  Future<void> _shareFullTableImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    Widget captureWidget = Container(
      color: HENSUU.backgroundcolor,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_univName 今季成績一覧',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.0,
            ),
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(50),
              2: FixedColumnWidth(50),
            },
            defaultColumnWidth: const FixedColumnWidth(80),
            children: [
              TableRow(
                children: _eventLabels.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String label = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(4),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: _shouldHasSeriesBorder(idx)
                          ? Border(
                              right: BorderSide(
                                color: _seriesBorderColor,
                                width: _seriesBorderWidth,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
              ..._sortedSenshu.map((senshu) {
                final int rowIndex = _sortedSenshu.indexOf(senshu) + 1;
                final Color rowBg = rowIndex.isEven
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.02);

                return TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minHeight: 65),
                      alignment: Alignment.centerLeft,
                      // 主将は、名前の欄の背景を薄い緑にし、左端に緑の線を引く(2.0.1)
                      decoration: _hyou.shushouKa(senshu)
                          ? shushouKazari
                          : null,
                      child: Text(
                        widget.gakuren
                            ? '${senshu.name}(${senshu.gakunen}年)\n${_shozokuToYosen(senshu)}'
                            : '${senshu.name}\n(${_hyou.gakunenMoji(senshu)})',
                        style: TextStyle(
                          color: HENSUU.LinkColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    _buildStatCellForImage(senshu.konjou, true, rowBg, 1),
                    _buildStatCellForImage(senshu.heijousin, false, rowBg, 2),
                    ..._raceIndices.asMap().entries.map((entry) {
                      int localIdx = entry.key;
                      int raceIdx = entry.value;
                      int totalColIdx = localIdx + 3; // レース開始列は3から

                      final double time =
                          senshu.kukantime_race[raceIdx][senshu.gakunen - 1];
                      final int? rank = _rankMap[raceIdx]?[senshu.id];

                      Color borderColor = Colors.transparent;
                      Color cellBgColor = rowBg;
                      Color textColor = HENSUU.textcolor;
                      double borderWidth = 1.0;

                      if (rank == 1) {
                        borderColor = Colors.amberAccent;
                        cellBgColor = Colors.amber.withOpacity(0.15);
                        textColor = Colors.amberAccent;
                        borderWidth = 2.0;
                      } else if (rank == 2) {
                        borderColor = const Color(0xFFE0F7FA);
                        cellBgColor = Colors.white.withOpacity(0.1);
                        textColor = const Color(0xFFB2EBF2);
                        borderWidth = 1.5;
                      } else if (rank == 3) {
                        borderColor = Colors.orange.shade800;
                        textColor = Colors.orange.shade200;
                        borderWidth = 1.0;
                      }

                      bool hasRankBorder = rank != null && rank <= 3;
                      bool hasSeriesBorder = _shouldHasSeriesBorder(
                        totalColIdx,
                      );

                      return Container(
                        constraints: const BoxConstraints(minHeight: 65),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: cellBgColor,
                          border: Border(
                            top: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            bottom: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            left: hasRankBorder
                                ? BorderSide(
                                    color: borderColor,
                                    width: borderWidth,
                                  )
                                : BorderSide.none,
                            right: hasSeriesBorder
                                ? BorderSide(
                                    color: _seriesBorderColor,
                                    width: _seriesBorderWidth,
                                  )
                                : (hasRankBorder
                                      ? BorderSide(
                                          color: borderColor,
                                          width: borderWidth,
                                        )
                                      : BorderSide.none),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (time <= 0 || time >= TEISUU.DEFAULTTIME)
                              const Text(
                                "---",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  decoration: TextDecoration.none,
                                ),
                              )
                            else ...[
                              Text(
                                "${(time / 60).floor()}:${(time % 60).floor().toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: hasRankBorder
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                "${rank}位",
                                style: TextStyle(
                                  color: hasRankBorder
                                      ? borderColor
                                      : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '----- Generated by 箱庭小駅伝SS -----',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );

    try {
      const double targetWidth = 1050;
      final double targetHeight = (_sortedSenshu.length * 70.0) + 200.0;

      final Uint8List? image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              width: targetWidth,
              height: targetHeight,
              color: HENSUU.backgroundcolor,
              child: captureWidget,
            ),
          ),
        ),
        context: context,
        targetSize: Size(targetWidth, targetHeight),
        delay: const Duration(milliseconds: 300),
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final String path = '${directory.path}/full_table_image.png';
        final File file = File(path);
        await file.writeAsBytes(image);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: '$_univName の今季成績表を共有します！ #箱庭小駅伝SS',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('画像共有エラー: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // 画像用のステータスセル構築ヘルパー
  Widget _buildStatCellForImage(
    int value,
    bool isKonjou,
    Color rowBg,
    int colIdx,
  ) {
    Color? bgColor = rowBg;
    Border? border;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    final Color baseColor = isKonjou
        ? Colors.pinkAccent
        : Colors.lightBlueAccent;
    final bool hasSeriesBorder = _shouldHasSeriesBorder(colIdx);

    if (value >= 90) {
      bgColor = baseColor.withOpacity(0.35);
      border = Border(
        top: BorderSide(color: baseColor, width: 3.0),
        left: BorderSide(color: baseColor, width: 3.0),
        bottom: BorderSide(color: baseColor, width: 3.0),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 3.0),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 80) {
      bgColor = baseColor.withOpacity(0.15);
      border = Border(
        top: BorderSide(color: baseColor, width: 1.5),
        left: BorderSide(color: baseColor, width: 1.5),
        bottom: BorderSide(color: baseColor, width: 1.5),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 1.5),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 70) {
      bgColor = baseColor.withOpacity(0.07);
      if (hasSeriesBorder) {
        border = Border(
          right: BorderSide(
            color: _seriesBorderColor,
            width: _seriesBorderWidth,
          ),
        );
      }
      textColor = baseColor.withOpacity(0.9);
      fontWeight = FontWeight.bold;
    } else if (hasSeriesBorder) {
      border = Border(
        right: BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 65),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, border: border),
      child: Text(
        "$value",
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: fontWeight,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  void _prepareData() {
    // 表のデータは _KonkiSeisekiHyou で作る(テキストのコピーを画面の外からも作れるように。1.8.2)
    _univId = widget.targetUnivId;
    _hyou = _KonkiSeisekiHyou(
      univId: _univId,
      gakuren: widget.gakuren,
    );
    // 表示する列(1.9.7)
    _kakushi = _kakushiYomu();
    _retsuTsukuru();
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            // 大学名を押すと、表示する大学を選べる(1.9.9。学連選抜の表は10人の決まったメンバーなので切り替えない)。
            // 右のボタンの分だけ狭いので、2行までにして、入りきらなければ「…」で省く
            title: widget.gakuren
                ? Text(
                    '$_univName 今季成績',
                    style: const TextStyle(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : InkWell(
                    onTap: _univErabu,
                    child: Text(
                      '$_univName 今季成績 ▼',
                      style: const TextStyle(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // 表示する列を選ぶ(画面の表だけ。1.9.7)
              IconButton(
                icon: const Icon(Icons.view_column),
                tooltip: '列を選ぶ',
                onPressed: _isExporting ? null : _retsuSentaku,
              ),
              // 書き出し(テキストでコピー・画像・CSV)は、1つのボタンにまとめた(1.9.9。
              // 上のバーの大学名の場所を広げるため。押すと3つから選ぶ)
              PopupMenuButton<int>(
                icon: const Icon(Icons.share),
                tooltip: '書き出し',
                enabled: !_isExporting,
                onSelected: (int erabi) {
                  if (erabi == 0) {
                    // テキストでコピー(CSV形式の文をクリップボードに入れる。1.8.2)
                    _copyAsText();
                  } else if (erabi == 1) {
                    _shareFullTableImage();
                  } else {
                    _exportAndShareCsv();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<int>(
                    value: 0,
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('テキストでコピー'),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.image),
                      title: Text('画像で共有'),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: ListTile(
                      leading: Icon(Icons.table_view),
                      title: Text('CSVファイルで共有'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: TableView.builder(
              pinnedColumnCount: 1,
              pinnedRowCount: 1,
              // 表示する列だけを出す(1.9.7。_retsu の記号の並び)
              columnCount: _retsu.length,
              rowCount: _sortedSenshu.length + 1,
              columnBuilder: (index) {
                final int code = _retsu[index];
                // メモの列(2.1.0)
                if (code == _memoRetsu) {
                  return TableSpan(extent: FixedTableSpanExtent(44));
                }
                // 学連選抜の表の所属大学と正月駅伝予選の列
                if (code == -1) {
                  return TableSpan(extent: FixedTableSpanExtent(100));
                }
                if (code == -2) {
                  return TableSpan(extent: FixedTableSpanExtent(80));
                }
                final int col = code;
                return TableSpan(
                  extent: FixedTableSpanExtent(
                    col >= _eventLabels.length
                        ? _extraCols[col - _eventLabels.length].width
                        : (col == 0 ? 100 : (col == 1 || col == 2 ? 60 : 90)),
                  ),
                );
              },
              rowBuilder: (index) => TableSpan(
                extent: FixedTableSpanExtent(index == 0 ? 55 : _rowHeight),
              ),
              cellBuilder: (context, vicinity) {
                final int code = _retsu[vicinity.column];
                // メモの列(2.1.0)
                if (code == _memoRetsu) {
                  if (vicinity.row == 0) return _buildMemoHeaderCell();
                  return _buildMemoCell(
                    _sortedSenshu[vicinity.row - 1],
                    vicinity.row,
                  );
                }
                // 学連選抜の表の所属大学と正月駅伝予選の列(1.8.2)
                if (code < 0) {
                  if (vicinity.row == 0) {
                    return _buildGakurenHeaderCell(
                      code == -1 ? '所属大学' : '正月駅伝予選',
                      _migiSen(code),
                    );
                  }
                  final senshu = _sortedSenshu[vicinity.row - 1];
                  return code == -1
                      ? _buildShozokuCell(senshu, vicinity.row, _migiSen(code))
                      : _buildYosenCell(senshu, vicinity.row, _migiSen(code));
                }
                // ここから下は、学連選抜の列を除いた列の番号(列の記号と同じ)で作る
                final int col = code;
                if (vicinity.row == 0)
                  return _buildHeaderCell(
                    col < _eventLabels.length
                        ? _eventLabels[col]
                        : _extraCols[col - _eventLabels.length].label,
                    col,
                  );
                final senshu = _sortedSenshu[vicinity.row - 1];

                if (col >= _eventLabels.length)
                  return _buildExtraCell(
                    senshu,
                    _extraCols[col - _eventLabels.length],
                    vicinity.row,
                    col,
                  );

                if (col == 0) return _buildNameCell(senshu, vicinity.row);
                if (col == 1)
                  return _buildStatCell(senshu.konjou, true, vicinity.row, 1);
                if (col == 2)
                  return _buildStatCell(
                    senshu.heijousin,
                    false,
                    vicinity.row,
                    2,
                  );
                return _buildDataCell(
                  senshu,
                  _raceIndices[col - 3],
                  vicinity.row,
                  col,
                );
              },
            ),
          ),
        ),
        if (_isExporting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'データを生成中...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- メモの列(2.1.0。konki_memo.dart) ----

  /// メモの文字の色(×は外す候補なので赤、ほかは黄色)
  Color _memoIro(String memo) =>
      memo == '×' ? Colors.redAccent : Colors.amber.shade300;

  /// 選手[s]のメモを[memo]にして保存する(空ならメモを消す)
  Future<void> _memoKaku(SenshuData s, String memo) async {
    final String ato = konkiMemoIreru(s.name_tanshuku, memo);
    if (ato == s.name_tanshuku) return;
    s.name_tanshuku = ato;
    await s.save();
    if (mounted) setState(() {});
  }

  /// この表の選手のメモを全部消す(確かめてから。見出しの「メモ」を押したとき)
  Future<void> _memoZenbuKesu() async {
    final List<SenshuData> ari = [
      for (final SenshuData s in _sortedSenshu)
        if (konkiMemoYomu(s.name_tanshuku).isNotEmpty) s,
    ];
    if (ari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この表にはメモがありません')),
      );
      return;
    }
    final bool? kesu = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(
            'この表の選手のメモ(${ari.length}人分)を全部消しますか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('消す'),
            ),
          ],
        );
      },
    );
    if (kesu != true) return;
    for (final SenshuData s in ari) {
      s.name_tanshuku = konkiMemoIreru(s.name_tanshuku, '');
      await s.save();
    }
    if (mounted) setState(() {});
  }

  /// メモどおり配置できる表か(2.1.2。区間エントリーの画面から開いて、自分の大学を表示しているとき)
  bool _memoHaichiDekiru(Ghensuu? gh) =>
      widget.kukanEntry && !widget.gakuren && gh != null && _univId == gh.MYunivid;

  /// メモの列の見出しを押したとき(2.1.2)。区間エントリーの画面から開いて自分の大学を表示しているときは、
  /// 「メモどおり配置する」「メモを全部消す」から選ぶ。ほかは今まで通り、全部消すかを聞く
  Future<void> _memoMidashiOsu() async {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null || !_memoHaichiDekiru(gh)) {
      await _memoZenbuKesu();
      return;
    }
    final int? erabi = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('メモ', style: TextStyle(color: Colors.black)),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(1),
              child: const Text('メモどおり配置する', style: TextStyle(color: Colors.black)),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(2),
              child: const Text('メモを全部消す', style: TextStyle(color: Colors.black)),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル', style: TextStyle(color: Colors.black54)),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (erabi == 1) {
      await _memoDooriHaichi(gh);
    } else if (erabi == 2) {
      await _memoZenbuKesu();
    }
  }

  /// メモどおり配置する(2.1.2。konki_memo.dart の memoHaichiKeikaku)。変わる区間などを確かめてから、
  /// 区間エントリーの画面の選択(SenshuSelectedOption)を書き換えて保存し、表を閉じて区間エントリーの画面に戻る
  /// (区間エントリーの画面は、保存すると書き換わる)
  Future<void> _memoDooriHaichi(Ghensuu gh) async {
    final int race = gh.hyojiracebangou;
    // 区間エントリーの画面で選べる大会(10月・11月・正月・カスタム駅伝)だけ
    if (!(race == 0 || race == 1 || race == 2 || race == 5) ||
        race >= gh.kukansuu_taikaigoto.length) {
      return;
    }
    final int kukansuu = gh.kukansuu_taikaigoto[race] < gh.SenshuSelectedOption.length
        ? gh.kukansuu_taikaigoto[race]
        : gh.SenshuSelectedOption.length;
    final List<SenshuData> narabi = kukanEntryNarabi(
      Hive.box<SenshuData>('senshuBox').values,
      gh.MYunivid,
      race,
    );
    final MemoHaichiKeikaku k = memoHaichiKeikaku(
      narabi: narabi,
      jibun: _sortedSenshu,
      ima: gh.SenshuSelectedOption,
      kukansuu: kukansuu,
    );
    if (k.henkou.isEmpty && k.sudeni.isEmpty && k.chuui.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この表には、区間の番号のメモがありません')),
      );
      return;
    }
    final bool kaeru = k.henkou.isNotEmpty;
    final bool? haichi = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            kaeru ? 'メモどおり配置しますか？' : '配置を変える区間はありません',
            style: const TextStyle(color: Colors.black, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final String s in k.henkou)
                  Text(s, style: const TextStyle(color: Colors.black)),
                for (final String s in k.sudeni)
                  Text(s, style: const TextStyle(color: Colors.black54)),
                for (final String s in k.chuui)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(s, style: TextStyle(color: Colors.red.shade800)),
                  ),
                if (k.nashi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(k.nashi, style: const TextStyle(color: Colors.black54)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(kaeru ? 'キャンセル' : '閉じる'),
            ),
            if (kaeru)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('配置する'),
              ),
          ],
        );
      },
    );
    if (haichi != true || !mounted) return;
    for (int kk = 0; kk < kukansuu; kk++) {
      gh.SenshuSelectedOption[kk] = k.atarashii[kk];
    }
    await gh.save();
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('メモどおり${k.henkou.length}区間を配置しました')),
    );
  }

  /// メモの列の見出し(押すと、この表のメモを全部消すかを聞く。区間エントリーの画面から開いた自分の大学の表では、
  /// 「メモどおり配置する」も選べる。2.1.2。_memoMidashiOsu)
  /// 配置できる表では、押したくなるように、メモの印と同じ黄色の枠と文字で「メモ/配置▾」の2行にする(2.1.2)。
  /// 欄の幅(44)と見出しの行の高さ(55)は決まった数なので変わらない。文字を大きくしている人の画面でも
  /// はみ出さないように、2行をまとめて欄に入る大きさまで縮める(FittedBox)
  TableViewCell _buildMemoHeaderCell() {
    final bool migiSen = _migiSen(_memoRetsu);
    if (_memoHaichiDekiru(Hive.box<Ghensuu>('ghensuuBox').getAt(0))) {
      final Color kiiro = Colors.amber.shade300;
      final TextStyle style = TextStyle(
        color: kiiro,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.2,
      );
      return TableViewCell(
        child: GestureDetector(
          onTap: _isExporting ? null : _memoMidashiOsu,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3D2F00),
              border: migiSen
                  ? Border(
                      right: BorderSide(
                        color: _seriesBorderColor,
                        width: _seriesBorderWidth,
                      ),
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: kiiro, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('メモ', style: style),
                    Text('配置▾', style: style),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return TableViewCell(
      child: GestureDetector(
        onTap: _isExporting ? null : _memoMidashiOsu,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            border: migiSen
                ? Border(
                    right: BorderSide(
                      color: _seriesBorderColor,
                      width: _seriesBorderWidth,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: const AutoSizeText(
            'メモ',
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: 8,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  /// メモのセル(押すと、空白・✓・○・△・×・1〜10から選ぶ一覧が出る)
  TableViewCell _buildMemoCell(SenshuData p, int rowIdx) {
    final String memo = konkiMemoYomu(p.name_tanshuku);
    final bool migiSen = _migiSen(_memoRetsu);
    return TableViewCell(
      child: PopupMenuButton<String>(
        tooltip: 'メモ',
        enabled: !_isExporting,
        initialValue: memo,
        color: const Color.fromARGB(255, 30, 30, 30),
        onSelected: (String erabi) => _memoKaku(p, erabi),
        itemBuilder: (context) => [
          for (final String m in konkiMemoSentakushi)
            PopupMenuItem<String>(
              value: m,
              height: 36,
              child: Text(
                m.isEmpty ? '(空白)' : m,
                style: TextStyle(
                  color: m.isEmpty ? Colors.white70 : _memoIro(m),
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ),
        ],
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // 入力できる欄だと分かるように、薄い青にする
            color: Colors.blue.withOpacity(rowIdx.isEven ? 0.10 : 0.14),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: migiSen
                  ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
                  : BorderSide.none,
            ),
          ),
          child: AutoSizeText(
            memo,
            maxLines: 1,
            minFontSize: 8,
            style: TextStyle(
              color: _memoIro(memo),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 学連選抜の表では、選手名の右に所属大学と正月駅伝予選の2列を入れる(1.8.2)
  // (1.9.7から、列の並びは _retsu の記号で持つ。-1所属大学・-2正月駅伝予選)

  // 学連選抜の列の見出し([migiSen]がtrueなら右に区切り線を引く)
  TableViewCell _buildGakurenHeaderCell(String label, bool migiSen) {
    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          border: migiSen
              ? Border(
                  right: BorderSide(
                    color: _seriesBorderColor,
                    width: _seriesBorderWidth,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: AutoSizeText(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 8,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 学連選抜の選手の所属大学のセル([migiSen] 右に区切り線を引くか。1.9.7)
  TableViewCell _buildShozokuCell(SenshuData senshu, int rowIdx, bool migiSen) {
    return TableViewCell(
      child: Container(
        padding: const EdgeInsets.all(6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: rowIdx.isEven
              ? Colors.transparent
              : Colors.white.withOpacity(0.02),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            right: migiSen
                ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
                : BorderSide.none,
          ),
        ),
        child: AutoSizeText(
          _shozoku(senshu),
          maxLines: 2,
          minFontSize: 8,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  // 学連選抜の選手の正月駅伝予選のセル(タイムと、予選に出た選手全体の中での個人順位)
  // [migiSen] 右に区切り線を引くか(1.9.7。それまではいつも引いていた)
  TableViewCell _buildYosenCell(SenshuData senshu, int rowIdx, bool migiSen) {
    final int? juni = _yosenJuni(senshu);
    final Border border = Border(
      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
      right: migiSen
          ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
          : BorderSide.none,
    );
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    if (juni == null) {
      return TableViewCell(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: rowBg, border: border),
          child: const Text(
            "---",
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      );
    }
    final double time = senshu.kukantime_race[4][senshu.gakunen - 1];
    final int m = (time / 60).floor();
    final int s = (time % 60).floor();
    return TableViewCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(color: rowBg, border: border),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AutoSizeText(
                  "$m'${s.toString().padLeft(2, '0')}\"",
                  maxLines: 1,
                  minFontSize: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: AutoSizeText(
                  "$juni位",
                  maxLines: 1,
                  minFontSize: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableViewCell _buildHeaderCell(String label, int colIdx) {
    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          color: colIdx == 0
              ? Colors.white24
              : (colIdx % 2 == 0
                    ? Colors.white12
                    : Colors.white.withOpacity(0.07)),
          // 区切り線は、次に表示する列とまとまりが違うときに右に引く(1.9.7。それまでは決まった列の右と、
          // 年間強化の列の左に引いていた)
          border: _migiSen(colIdx)
              ? Border(
                  right: BorderSide(
                    color: _seriesBorderColor,
                    width: _seriesBorderWidth,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: AutoSizeText(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 8,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  TableViewCell _buildNameCell(SenshuData p, int rowIdx) {
    // 主将は、名前の欄の背景を薄い緑にし、左端に緑の線を引く(2.0.1。ほかの色付けと見分けられる色)
    final bool shushou = _hyou.shushouKa(p);
    return TableViewCell(
      child: GestureDetector(
        onTap: () => _showSenshuDetail(context, p.id),
        child: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: shushou
                ? shushouIroHaikei
                : (rowIdx.isEven
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.03)),
            border: Border(
              left: shushou
                  ? const BorderSide(color: shushouIroSen, width: 4)
                  : BorderSide.none,
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: AutoSizeText(
            '${p.name}\n(${_hyou.gakunenMoji(p)})',
            maxLines: 2,
            minFontSize: 8,
            style: TextStyle(
              color: HENSUU.LinkColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ステータスセル (シリーズ境界線対応)
  TableViewCell _buildStatCell(
    int value,
    bool isKonjou,
    int rowIdx,
    int colIdx,
  ) {
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    Color? bgColor = rowBg;
    Border? border;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    final Color baseColor = isKonjou
        ? Colors.pinkAccent
        : Colors.lightBlueAccent;
    final bool hasSeriesBorder = _migiSen(colIdx); // 画面の表は、表示する列で決める(1.9.7)

    if (value >= 90) {
      bgColor = baseColor.withOpacity(0.35);
      border = Border(
        top: BorderSide(color: baseColor, width: 3.0),
        left: BorderSide(color: baseColor, width: 3.0),
        bottom: BorderSide(color: baseColor, width: 3.0),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 3.0),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 80) {
      bgColor = baseColor.withOpacity(0.15);
      border = Border(
        top: BorderSide(color: baseColor, width: 1.5),
        left: BorderSide(color: baseColor, width: 1.5),
        bottom: BorderSide(color: baseColor, width: 1.5),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide(color: baseColor, width: 1.5),
      );
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 70) {
      bgColor = baseColor.withOpacity(0.07);
      textColor = baseColor.withOpacity(0.9);
      fontWeight = FontWeight.bold;
      if (hasSeriesBorder) {
        border = Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          right: BorderSide(
            color: _seriesBorderColor,
            width: _seriesBorderWidth,
          ),
        );
      }
    }

    if (border == null) {
      border = Border(
        bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        right: hasSeriesBorder
            ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
            : BorderSide.none,
      );
    }

    return TableViewCell(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgColor, border: border),
        child: Text(
          "$value",
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  TableViewCell _buildDataCell(
    SenshuData p,
    int raceIdx,
    int rowIdx,
    int colIdx,
  ) {
    final double time = p.kukantime_race[raceIdx][p.gakunen - 1];
    final int? rank = _rankMap[raceIdx]?[p.id];
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    final bool hasSeriesBorder = _migiSen(colIdx); // 画面の表は、表示する列で決める(1.9.7)

    if (time <= 0 || time >= TEISUU.DEFAULTTIME) {
      return TableViewCell(
        child: Container(
          decoration: BoxDecoration(
            color: rowBg,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              right: hasSeriesBorder
                  ? BorderSide(
                      color: _seriesBorderColor,
                      width: _seriesBorderWidth,
                    )
                  : BorderSide.none,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            "---",
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      );
    }

    final int m = (time / 60).floor();
    final int s = (time % 60).floor();
    final String timeStr = "$m'${s.toString().padLeft(2, '0')}\"";

    Color borderColor = Colors.transparent;
    Color cellBgColor = rowBg;
    Color textColor = HENSUU.textcolor;
    double borderWidth = 2.0;

    if (rank == 1) {
      borderColor = Colors.amberAccent;
      cellBgColor = Colors.amber.withOpacity(0.15);
      textColor = Colors.amberAccent;
      borderWidth = 3.0;
    } else if (rank == 2) {
      borderColor = const Color(0xFFE0F7FA);
      cellBgColor = Colors.white.withOpacity(0.1);
      textColor = const Color(0xFFB2EBF2);
      borderWidth = 2.5;
    } else if (rank == 3) {
      borderColor = Colors.orange.shade800;
      textColor = Colors.orange.shade200;
      borderWidth = 2.0;
    }

    bool hasRankBorder = rank != null && rank <= 3;

    return TableViewCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: cellBgColor,
          border: Border(
            top: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide.none,
            bottom: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide(color: Colors.white.withOpacity(0.05)),
            left: hasRankBorder
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide.none,
            right: hasSeriesBorder
                ? BorderSide(
                    color: _seriesBorderColor,
                    width: _seriesBorderWidth,
                  )
                : (hasRankBorder
                      ? BorderSide(color: borderColor, width: borderWidth)
                      : BorderSide.none),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AutoSizeText(
                  timeStr,
                  maxLines: 1,
                  minFontSize: 6,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: hasRankBorder
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: AutoSizeText(
                  "$rank位",
                  maxLines: 1,
                  minFontSize: 6,
                  style: TextStyle(
                    color: hasRankBorder ? borderColor : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 追加列のセル（見えない能力は「??」で表示し、色付けもしない）
  TableViewCell _buildExtraCell(
    SenshuData senshu,
    _ExtraColDef def,
    int rowIdx,
    int colIdx,
  ) {
    final Color rowBg = rowIdx.isEven
        ? Colors.transparent
        : Colors.white.withOpacity(0.02);
    // 区切り線は、次に表示する列とまとまりが違うときに右に引く(1.9.7。それまでは年間強化の列の左に引いていた。
    // 年間強化と能力の列は一番右のまとまりなので、ふつうは引かない)
    final Border border = Border(
      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
      right: _migiSen(colIdx)
          ? BorderSide(color: _seriesBorderColor, width: _seriesBorderWidth)
          : BorderSide.none,
    );

    // 見えない能力
    if (!_isExtraVisible(def)) {
      return TableViewCell(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: rowBg, border: border),
          child: const Text(
            '??',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    // 文字列の列（年間強化など）
    if (def.getText != null) {
      return TableViewCell(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: rowBg, border: border),
          child: AutoSizeText(
            def.getText!(senshu),
            maxLines: 1,
            minFontSize: 8,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }

    // 数値の列（能力値）
    final int value = def.getValue?.call(senshu) ?? 0;
    const Color baseColor = Colors.lightGreenAccent;
    Color bgColor = rowBg;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    if (value >= 90) {
      bgColor = baseColor.withOpacity(0.35);
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 80) {
      bgColor = baseColor.withOpacity(0.15);
      textColor = baseColor;
      fontWeight = FontWeight.bold;
    } else if (value >= 70) {
      bgColor = baseColor.withOpacity(0.07);
      textColor = baseColor.withOpacity(0.9);
      fontWeight = FontWeight.bold;
    }

    return TableViewCell(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgColor, border: border),
        child: Text(
          "$value",
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  void _showSenshuDetail(BuildContext context, int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, __) =>
          ModalSenshuDetailView(senshuId: senshuId),
    );
  }
}
