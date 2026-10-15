// freshman_scout_view.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのパスを適宜修正
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのパスを適宜修正
import 'package:ekiden/constants.dart'; // HENSUUクラスのパスを適宜修正
import 'dart:math';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/scout_com.dart';
import 'package:ekiden/kansuu/kyouka_project.dart'; // 強化プロジェクト(2.0.1)
import 'package:ekiden/kansuu/bokou_pipe.dart'; // 監督の母校パイプ(2.0.1)
import 'package:ekiden/kansuu/koukou.dart'; // 出身校と高校時代の実績(1.9.5)
import 'package:ekiden/screens/Modal_koukouMeikan.dart'; // 高校名鑑(1.9.5)
import 'package:ekiden/kansuu/ShoriGuard.dart';
import 'package:ekiden/screens/ScoutRoundKekka_screen.dart';
import 'package:ekiden/screens/Modal_shinnyuuseiShingakusaki.dart';
//import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';

enum SortCriterion {
  time,
  konjou,
  heijousin,
  choukyorinebari,
  spurtryoku,
  karisuma,
  noboritekisei,
  kudaritekisei,
  noborikudarikirikaenouryoku,
  tandokusou,
  paceagesagetaiouryoku,
  successRate, // ★追加
  anteikan,
  univid,
}

class FreshmanScoutView extends StatefulWidget {
  const FreshmanScoutView({super.key});

  @override
  State<FreshmanScoutView> createState() => _FreshmanScoutViewState();
}

class _FreshmanScoutViewState extends State<FreshmanScoutView> {
  late Box<Ghensuu> _ghensuuBox;
  late Box<SenshuData> _senshuBox;
  late Box<UnivData> _univBox;

  Ghensuu? _ghensuu;
  List<SenshuData> _targetFreshmen = []; // 獲得候補の新入生リスト
  List<SenshuData> _playersToTrade = []; // 交換候補の自大学の選手リスト
  late List<SenshuData> _myFreshmen; // 自分の大学に入学予定の新入生リスト

  SortCriterion _currentSortCriterion = SortCriterion.time;
  bool _isTimeAscending = true;
  bool _isAbilityDescending = true;

  // ★変更・追加: フィルターの最小値を保持するマップと、持ちタイムのフィルター（秒）
  Map<SortCriterion, int> _abilityFilters = {};
  int _timeFilterSeconds = TEISUU.DEFAULTTIME.toInt(); // 初期値は設定なし（デフォルトタイム）
  // ★追加: 成功率の最小パーセント値を保持 (0はフィルターなし)
  int _successRateFilter = 0;
  int _anteikanFilter = 0;
  // 高校時代(直近の大会)のフィルター(1.9.5。空や0はフィルターなし)
  // 高校名(校名か都道府県の部分一致)、所属高校の全国高校駅伝の順位、全国高校駅伝の区間順位、
  // 高校総体の決勝の順位(0=1500m・1=5000m・2=3000m障害)。どれも「○位以内」
  String _koukouMeiFilter = '';
  int _ekidenTeamJuniFilter = 0;
  int _ekidenKukanJuniFilter = 0;
  List<int> _soutaiJuniFilter = [0, 0, 0];
  KoukouSaishinSeiseki? _koukouSeiseki; // 直近の大会の成績(初めて使うときに読む)
  // お気に入りの高校の出身だけにするか(1.9.5。お気に入りは高校名鑑の高校のページの☆で付ける)
  bool _okiniiriFilter = false;
  // 監督の母校の出身だけにするか(2.0.1。あなたの大学の監督の母校・ほかの大学の監督の母校。
  // 両方なら、どちらかに当てはまる選手。bokou_pipe.dart)
  bool _bokouJibunFilter = false;
  bool _bokouHokaFilter = false;
  Set<int>? _okiniiriKou; // お気に入りの高校(名簿の番号。初めて使うときに読む。高校名鑑から戻ったら読み直す)

  // ★追加: フィルタリング/並び替え可能な能力値の定義
  final Map<SortCriterion, String> _abilityLabels = {
    SortCriterion.konjou: '駅伝男',
    SortCriterion.heijousin: '平常心',
    SortCriterion.choukyorinebari: '長距離粘り',
    SortCriterion.spurtryoku: 'スパート力',
    SortCriterion.karisuma: 'カリスマ',
    SortCriterion.noboritekisei: '登り適性',
    SortCriterion.kudaritekisei: '下り適性',
    SortCriterion.noborikudarikirikaenouryoku: 'アップダウン対応力',
    SortCriterion.tandokusou: 'ロード適性',
    SortCriterion.paceagesagetaiouryoku: 'ペース変動対応力',
  };

  bool _isLoading = true; // ★追加：ローディング状態管理用
  String _loadingMessage = 'スカウト名簿を作成中...'; // 読み込み中に出す文
  bool _comScoutOn = false; // コンピュータスカウトがONなら、ラウンド制で交渉する
  int _roundSuu = 3; // ラウンド回数(ONのとき。何ラウンド目かの表示用)
  int _waku = TEISUU.NINZUU_1GAKUNEN_INUNIV; // 自大学の日本人の新入生の枠(ONのとき)
  int _ryuugakuseiSuu = 0; // 自大学に入学する留学生の新入生の人数(ONのとき)
  int _kakuteiSuu = 0; // 自大学に確定した新入生の人数(ONのとき)
  // ラウンドごとの全大学の行動の記録(ラウンドの番号 → 行動)。「ラウンドの結果」の画面で出す
  // (スカウト画面を開いている間だけ持つ。アプリを開き直すと、それより前の記録は消える)
  final List<MapEntry<int, List<ComScoutKoudou>>> _roundKiroku = [];

  // 地区めぐり(1.9.6。コンピュータスカウトONで、今年のスカウトを地区めぐりで始めたとき。scout_com.dart)
  // 地区ごとに1ラウンド。何地区目かは、今までのラウンドと同じく scoutChances(残りの地区の数)で数える
  bool _chikuMeguri = false;
  // 地区めぐり(声かけ)か(1.9.6。falseなら地区めぐり(交渉))。声かけには成功率がなく、失敗(保留)もない
  bool _koekake = false;
  // 地区めぐり(声かけ)の今年の周回数(1.9.6。ほかの形は1)。ラウンドの数は地区の数×周回数
  int _shuukai = 1;
  List<int> _chikuJunban = []; // その年の地区の順番(新入生のいない地区を除く)
  Map<int, int> _chikuBetsu = {}; // 選手id → 地区
  Map<int, int> _zenkokuJuni = {}; // 選手id → 新入生(留学生を除く)全体の中での持ちタイムの順位
  Map<int, int> _miteiJuni = {}; // 選手id → 進路未定の中での持ちタイムの順位
  // 表示する地区(-2=今の地区(初期値。地区が進むと次の地区になる)・-1=全地区・0〜10=その地区)
  int _hyoujiSentaku = -2;
  bool _junbanDialogZumi = false; // 地区の順番のダイアログを、この画面で出したか
  // 今年の高校の大会の画面を出した年(1.9.9。アプリを開いている間だけ覚える。ほかの画面に移って戻っても、
  // もう一度は出さない。アプリを開き直したときは、1ラウンド目の前ならもう一度出す)
  static int _kotoshiKoukouTaikaiNen = -1;
  bool _wakuIppaiKiitaZumi = false; // 自校の枠が埋まったときに、残りを進めるかをこの画面で聞いたか(1.9.6)

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _univBox = Hive.box<UnivData>('univBox');
    _ghensuu = _ghensuuBox.getAt(0);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (kantoku != null) {
      _comScoutOn = isComScoutOn(kantoku);
      _roundSuu = comScoutKaisuu(kantoku);
      // スカウトの途中でラウンド回数の設定を減らした場合も、ラウンドの番号が1より小さくならないように
      // (1ラウンド目では、コンピュータの大学の断られた記憶を忘れるため)
      if (_ghensuu != null && _ghensuu!.scoutChances > _roundSuu) {
        _roundSuu = _ghensuu!.scoutChances;
      }
      // 地区めぐり(1.9.6。スカウトを始めたときの形で決まる。途中で設定を変えても、今年はそのまま)
      if (_comScoutOn && _ghensuu != null) {
        final int katachi = comScoutKotoshiKatachi(kantoku, _ghensuu!.year);
        if (katachi != comScoutKatachiZenkoku) {
          _chikuMeguri = true;
          _koekake = katachi == comScoutKatachiKoekake;
          _chikuJunban = comScoutChikuJunban(_ghensuu!.year);
          _shuukai = comScoutKotoshiShuukai(kantoku, _ghensuu!.year);
          _roundSuu = _chikuJunban.length * _shuukai;
        }
      }
    }

    // ★追加: フィルターマップの初期化 (全て0で初期化)
    _abilityFilters = Map.fromIterable(
      _abilityLabels.keys,
      key: (k) => k as SortCriterion,
      value: (_) => 0,
    );
    _initializeScoutingData();
  }

  /// 獲得候補の新入生リストを初期化し、交渉成功確率を計算・格納する
  void _initializeScoutingData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'スカウト名簿を作成中...';
    });

    final myUnivId = _ghensuu?.MYunivid;

    if (myUnivId == null) {
      return;
    }

    // コンピュータスカウトONなら、全員「進路未定」の名簿にする
    if (_comScoutOn) {
      await _initializeScoutingDataOn(myUnivId);
      return;
    }

    _myFreshmen = _senshuBox.values
        .where((s) => s.gakunen == 1 && s.univid == myUnivId)
        .toList();

    _targetFreshmen = _senshuBox.values
        .where((s) => s.gakunen == 1 && s.univid != myUnivId)
        .toList();

    // 交渉成功確率を計算し、kegaflagに格納する
    _targetFreshmen.sort((a, b) {
      // タイムを比較
      final timeComparison = a.kiroku_nyuugakuji_5000.compareTo(
        b.kiroku_nyuugakuji_5000,
      );
      // タイムが異なる場合は、その比較結果を返す
      if (timeComparison != 0) {
        return timeComparison;
      }
      // タイムが同じ場合は、IDで比較して順序を安定化
      return a.id.compareTo(b.id);
    });
    for (var freshman in _targetFreshmen) {
      _calculateAndStoreSuccessRate(freshman);
      await freshman.save();
    }
    for (var freshman in _myFreshmen) {
      if (freshman.hirou == 1) {
        freshman.kegaflag = -2; //0%
      } else {
        freshman.kegaflag = -1; //0.1%(1.8.7までの「1%未満」の値。scoutSeikouritsuFromKegaflagで0.1%)
      }

      await freshman.save();
    }

    _sortFreshmenLists();

    // データの更新を画面に反映させる
    if (mounted) {
      setState(() => _isLoading = false); // ★読み込み完了
    }
    /*if (mounted) {
      setState(() {});
    }*/
  }

  /// コンピュータスカウトONのときの名簿
  /// 新入生は全員「進路未定」として出し、仮の振り分けの大学は見せない(自大学の分も)
  /// 交渉で確定した選手だけ、確定した大学を出す。留学生は交渉の対象外なので出さない
  Future<void> _initializeScoutingDataOn(int myUnivId) async {
    // 地区めぐりで、全員の進路が決まっていれば終わりにし、周回の2周目からは進路未定の選手が
    // いない地区を飛ばす(1.9.6)
    if (_chikuMeguri) {
      await _karaChikuTobasu();
    }
    final List<SenshuData> shinnyuusei = _senshuBox.values
        .where((s) => s.gakunen == 1)
        .toList();
    _ryuugakuseiSuu = shinnyuusei
        .where((s) => s.univid == myUnivId && s.hirou == 1)
        .length;
    _waku = comScoutWaku(shinnyuusei, myUnivId);
    _myFreshmen = shinnyuusei
        .where(
          (s) => s.hirou != 1 && comScoutKettei(s) && s.univid == myUnivId,
        )
        .toList();
    _targetFreshmen = shinnyuusei
        .where(
          (s) => s.hirou != 1 && !(comScoutKettei(s) && s.univid == myUnivId),
        )
        .toList();
    _kakuteiSuu = _myFreshmen.length;

    // 進路未定の選手の成功率をkegaflagに入れる(決まった選手と、あなたの大学に断った選手は目印のまま)
    // (地区めぐりでは、成功率に下限を入れる。1.9.6)
    // (地区めぐり(声かけ)は成功率がないので計算しない。kegaflagには100%を入れておき、
    //  成功率の絞り込みで外れないようにする。画面には成功率を出さない。1.9.6)
    final Map<int, double> seikouritsu = _koekake
        ? const <int, double>{}
        : comScoutSeikouritsuIchiran(
            univid: myUnivId,
            nen: _ghensuu!.year, // 変わり者を決めるのに使う(1.9.0)
            chikuMeguriGh: _chikuMeguri ? _ghensuu : null,
          );
    // 地区めぐりの地区と順位(1.9.6)
    if (_chikuMeguri) {
      _chikuBetsu = comScoutChikuBetsu(shinnyuusei);
      _zenkokuJuni = comScoutTimeJuni(shinnyuusei);
      _miteiJuni = comScoutMiteiJuni(shinnyuusei);
    }
    for (final SenshuData s in _targetFreshmen) {
      if (comScoutKettei(s)) continue;
      if (comScoutKotowarareta(s)) continue;
      final double r = _koekake ? 1.0 : (seikouritsu[s.id] ?? 0.001);
      // 0.1%単位で入れる(1%未満も0.1%単位。1.8.8。scout_com.dart)
      s.kegaflag = scoutSeikouritsuKegaflag(r);
      await s.save();
    }

    _sortFreshmenLists();

    if (mounted) {
      setState(() => _isLoading = false);
      // 1ラウンド目の前なら、今年の高校の大会の画面を先に出す(1.9.9。閉じると地区の順番のダイアログに続く)
      final bool koukouGamen = _kotoshiKoukouTaikaiDasu();
      // 地区めぐりでは、最初の地区のときと、初めての地区めぐりのときに、地区の順番を出す(1.9.6)
      bool junban = false;
      bool hajimete = false;
      if (_chikuMeguri && !_junbanDialogZumi) {
        _junbanDialogZumi = true;
        final KantokuData? kantoku = Hive.box<KantokuData>(
          'kantokuBox',
        ).get('KantokuData');
        hajimete = kantoku != null && !comScoutOshiraseZumi(kantoku);
        junban = hajimete || _ghensuu!.scoutChances >= _roundSuu;
      }
      if (koukouGamen || junban) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (koukouGamen) await _kotoshiKoukouTaikaiHiraku();
          if (mounted && junban) _showChikuJunbanDialog(hajimete: hajimete);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // 地区めぐり(1.9.6)
  // ------------------------------------------------------------

  static const List<String> _maruSuuji = [
    '①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫',
  ];

  /// 地区の順番の番号(①など。順番にない地区は空)
  String _junbanMoji(int chiku) {
    final int i = _chikuJunban.indexOf(chiku);
    if (i < 0) return '';
    return i < _maruSuuji.length ? _maruSuuji[i] : '${i + 1}.';
  }

  /// 今の地区(地区めぐりで、まだ地区が残っているとき。なければnull)
  /// (周回するときは、地区の順番を何周もする。1.9.6)
  int? get _imaChiku {
    if (!_chikuMeguri || _ghensuu == null || _chikuJunban.isEmpty) return null;
    if (_ghensuu!.scoutChances <= 0) return null;
    final int i = (_roundBangou() - 1).clamp(0, _roundSuu - 1).toInt();
    return _chikuJunban[i % _chikuJunban.length];
  }

  /// 今が何周目か(1から。周回は地区めぐり(声かけ)だけ。1.9.6)
  int get _imaShuu {
    if (_chikuJunban.isEmpty) return 1;
    return (_roundBangou() - 1).clamp(0, _roundSuu - 1).toInt() ~/
            _chikuJunban.length +
        1;
  }

  /// 全員の進路が決まっていれば終わりにし、周回の2周目からは、進路未定の選手がいない地区を飛ばす(1.9.6)
  /// (その地区には、どの大学も声をかけられないので、ラウンドを行わずに次へ進める)
  Future<void> _karaChikuTobasu() async {
    final List<SenshuData> shinnyuusei = comScoutShinnyuusei();
    bool kawatta = false;
    if (_ghensuu!.scoutChances > 0 && !comScoutMiteiAri(shinnyuusei)) {
      _ghensuu!.scoutChances = 0;
      kawatta = true;
    }
    while (_ghensuu!.scoutChances > 0 && _imaShuu >= 2) {
      final int? ima = _imaChiku;
      if (ima == null || comScoutChikuMiteiAri(shinnyuusei, ima)) break;
      _ghensuu!.scoutChances--;
      kawatta = true;
    }
    if (kawatta) await _ghensuu!.save();
  }

  /// 地区めぐりで自校の枠が埋まったら、残りをコンピュータの大学だけで進めるか聞く(1.9.6)
  Future<void> _wakuIppaiNaraKiku() async {
    if (!_chikuMeguri || _ghensuu!.scoutChances <= 0) return;
    if (_wakuIppaiKiitaZumi) return; // 「このまま見る」を選んだら、もう聞かない
    final List<SenshuData> shinnyuusei = comScoutShinnyuusei();
    final int myUnivid = _ghensuu!.MYunivid;
    if (comScoutKetteiSuu(shinnyuusei, myUnivid) <
        comScoutWaku(shinnyuusei, myUnivid)) {
      return;
    }
    _wakuIppaiKiitaZumi = true;
    final bool? susumeru = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('枠が埋まりました', style: TextStyle(color: Colors.black)),
          content: const Text(
            'あなたの大学の日本人の新入生の枠が埋まりました。\n'
            '残りの地区は、コンピュータの大学だけで進めますか？\n'
            '(このまま残りの地区の動きを見ることもできます)',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('このまま見る'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('残りを進める'),
            ),
          ],
        );
      },
    );
    if (susumeru == true && mounted) {
      await _scoutShuuryou();
    }
  }

  /// 表示している地区(nullなら全地区)
  int? get _hyoujiChiku {
    if (!_chikuMeguri) return null;
    if (_hyoujiSentaku == -2) return _imaChiku;
    if (_hyoujiSentaku < 0) return null;
    return _hyoujiSentaku;
  }

  /// 地区の日本人の新入生の人数
  int _chikuNinzuu(int chiku) =>
      _chikuBetsu.values.where((c) => c == chiku).length;

  /// カードに出す地区と順位(例: 近畿・全国12位(未定で5位))
  String _chikuJuniMoji(SenshuData s) {
    final int? c = _chikuBetsu[s.id];
    final int? zen = _zenkokuJuni[s.id];
    final int? mitei = _miteiJuni[s.id];
    final List<String> bubun = [
      if (c != null) comScoutChikuMei(c),
      if (zen != null)
        '全国$zen位${mitei != null && !comScoutKettei(s) ? '(未定で$mitei位)' : ''}',
    ];
    return bubun.join('・');
  }

  /// 今年の周回数を、周回数のコード[code]に変える(1.9.9。地区の順番のダイアログから。
  /// 1ラウンドも進める前だけ。設定タブの「コンピュータスカウト」の周回数も変わる。scout_com.dart)
  Future<void> _shuukaiHenkou(int code) async {
    final Ghensuu? gh = _ghensuu;
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (gh == null || kantoku == null || _chikuJunban.isEmpty) return;
    if (gh.scoutChances < _roundSuu) return; // もう始めていたら変えない
    await comScoutKotoshiShuukaiHenkou(
      kantoku: kantoku,
      nen: gh.year,
      code: code,
    );
    final int shuukai = comScoutKotoshiShuukai(kantoku, gh.year);
    // 残りのラウンドの数(地区の数×周回数)も直す(まだ1ラウンドも進めていないので、全部残っている)
    gh.scoutChances = _chikuJunban.length * shuukai;
    await gh.save();
    if (!mounted) return;
    setState(() {
      _shuukai = shuukai;
      _roundSuu = _chikuJunban.length * shuukai;
    });
  }

  /// 地区の順番のダイアログ(初めての地区めぐりなら、地区めぐりになったことのお知らせも出す)
  /// 地区めぐり(声かけ)で、まだ1ラウンドも進めていなければ、今年の周回数も選べる(1.9.9)
  Future<void> _showChikuJunbanDialog({required bool hajimete}) async {
    final List<String> narabi = [
      for (final int c in _chikuJunban)
        '${_junbanMoji(c)}${comScoutChikuMei(c)}(${_chikuNinzuu(c)}人)',
    ];
    // 周回数を選べるか(設定で変えられることを知らない人もいるので、ここでも選べるようにする。1.9.9)
    final bool shuukaiEraberu =
        _koekake && _ghensuu != null && _ghensuu!.scoutChances >= _roundSuu;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int imaCode = comScoutShuukaiSuu.indexOf(_shuukai);
            return AlertDialog(
              title: Text(
                _koekake ? '地区めぐり(声かけ)' : '地区めぐり(交渉)',
                style: const TextStyle(color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hajimete ? '今年から、コンピュータスカウトONの新入生スカウトが「地区めぐり」になりました。'
                                '説明画面の設定タブの「コンピュータスカウト」で、今までの「全国一斉」に変えられます。\n\n' : ''}'
                      '${_koekake ? '新入生は出身校の地区ごとに分かれていて、地区ごとに1ラウンドずつ声をかけます。'
                                'どの大学も、今の地区の選手に1人まで声をかけられます(見送ることもできます)。'
                                'ほかに声をかけた大学がなければ確定し、重なれば争奪戦になります。' : '新入生は出身校の地区ごとに分かれていて、地区ごとに1ラウンドずつ交渉します。'
                                'どの大学も、今の地区の選手に1人まで交渉できます(見送ることもできます)。'}'
                      'ほかの地区の選手は、上の地区の切り替え(左右の矢印か、地区の名前を押す)で見られます。',
                      style: const TextStyle(color: Colors.black),
                    ),
                    // 今年の周回数(1.9.9。選ぶと、設定タブの「コンピュータスカウト」の周回数も変わる)
                    if (shuukaiEraberu) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '今年の周回数(この地区の順番で何周するか)',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (int c = 0; c < comScoutShuukaiSuu.length; c++)
                            ChoiceChip(
                              label: Text('${comScoutShuukaiSuu[c]}周'),
                              // ダイアログは白い背景なので、文字と色を決めておく
                              labelStyle: const TextStyle(color: Colors.black),
                              selectedColor: Colors.lightBlue.shade200,
                              backgroundColor: Colors.grey.shade300,
                              selected: c == imaCode,
                              onSelected: (bool erabu) async {
                                if (!erabu || c == imaCode) return;
                                await _shuukaiHenkou(c);
                                if (context.mounted) setDialogState(() {});
                              },
                            ),
                        ],
                      ),
                      const Text(
                        '周回するときは、全員の進学先が決まれば、そこで終わります。'
                        'ここで選んだ周回数は、説明画面の設定タブの「コンピュータスカウト」の周回数にもなり、'
                        '次の年からもこの周回数で始まります。',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '${!shuukaiEraberu && _shuukai > 1 ? '今年は、この順番で最大$_shuukai周します(全員の進学先が決まれば、そこで終わります)。\n\n' : ''}'
                      '今年の地区の順番\n${narabi.join('\n')}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    if (hajimete) {
      final KantokuData? kantoku = Hive.box<KantokuData>(
        'kantokuBox',
      ).get('KantokuData');
      if (kantoku != null) {
        comScoutOshiraseKaku(kantoku);
        await kantoku.save();
      }
    }
  }

  /// 地区めぐりの結果のダイアログに足す、この地区のほかの大学の確定の人数
  String _chikuKakuteiBun(List<ComScoutKekka> kekka) {
    final int myUnivid = _ghensuu!.MYunivid;
    final Set<int> hoka = {
      for (final ComScoutKekka k in kekka)
        if (k.kimariUnivid >= 0 && k.kimariUnivid != myUnivid) k.senshuId,
    };
    return hoka.isEmpty
        ? 'この地区で、ほかの大学に確定した選手はいませんでした。'
        : 'この地区では、ほかの大学が${hoka.length}人を確定しました。';
  }

  /// 今の地区を見送る(交渉せずに、この地区のラウンドを進める。1.9.6)
  void _showMiokuriDialog() {
    final int? chiku = _imaChiku;
    if (chiku == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('見送りの確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '${comScoutChikuMei(chiku)}では交渉せずに、次の地区へ進みますか？\n'
            '(この地区のラウンドは、コンピュータの大学だけで行います)',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _chikuRound(null);
              },
              child: const Text('見送る'),
            ),
          ],
        );
      },
    );
  }

  /// 地区めぐりの1ラウンド([freshman] がnullなら見送り。1.9.6)
  Future<void> _chikuRound(SenshuData? freshman) async {
    final int? chiku = _imaChiku;
    if (chiku == null || _ghensuu!.scoutChances <= 0) return;
    // (声かけでは成功率を使わない。1.9.6)
    final double successRate = freshman == null
        ? 0.0
        : scoutSeikouritsuFromKegaflag(freshman.kegaflag);
    final int roundBangou = _roundBangou();
    final String chikuMei = comScoutChikuMei(chiku);
    setState(() {
      _isLoading = true;
      _loadingMessage = '$chikuMeiの結果を判定中...';
    });
    List<ComScoutKekka> kekka = [];
    final List<ComScoutKoudou> koudou = [];
    try {
      // 処理前スナップショット(途中で終了しても処理前の状態に戻せるように)
      await ShoriGuard.begin('新入生スカウト');
      kekka = await comScoutRound(
        gh: _ghensuu!,
        roundBangou: roundBangou,
        playerTarget: freshman,
        playerSeikouritsu: successRate,
        koudou: koudou,
        chiku: chiku,
        koekake: _koekake,
      );
      _ghensuu!.scoutChances--;
      await _ghensuu!.save();
      await ShoriGuard.end();
    } catch (e) {
      ShoriGuard.reportError('新入生スカウト', e);
      return;
    }
    _roundKiroku.add(MapEntry(roundBangou, koudou));
    _hyoujiSentaku = -2; // 次の地区を出す
    // リストの再初期化
    _initializeScoutingData();
    if (!mounted) return;
    // ダイアログは自大学の結果と、この地区のほかの大学の確定の人数(全大学の動きは「全大学の動きを見る」から)
    await _showKekkaDialog(
      '$chikuMeiの結果',
      [
        if (freshman == null)
          _koekake ? '$chikuMeiでは声をかけませんでした。' : '$chikuMeiでは交渉しませんでした。',
        ...comScoutKekkaBun(
          kekka,
          _ghensuu!.MYunivid,
          jibunNomi: true,
          horyuu: !_koekake,
          koekake: _koekake,
        ),
        _chikuKakuteiBun(kekka),
      ],
      hajimeRound: roundBangou,
    );
    if (!mounted) return;
    // 自校の枠が埋まったら、残りを進めるか聞く(1.9.6)
    await _wakuIppaiNaraKiku();
  }

  /// 地区の状態の文(今の地区・終わった地区・これからの地区)
  /// (周回するときは、今の周で終わった地区は、次の周があれば「次の周」。1.9.6)
  String _chikuJoutaiMoji(int chiku) {
    final int i = _chikuJunban.indexOf(chiku);
    final int? ima = _imaChiku;
    if (ima == null) return '終了';
    if (chiku == ima) return '今の地区';
    final int imaIdx = _chikuJunban.indexOf(ima);
    if (i > imaIdx) return '${i + 1}地区目';
    return _imaShuu < _shuukai ? '次の周' : '終了';
  }

  /// 表示する地区を、地区の順番(先頭は全地区)で前後に動かす([idou] は -1 か 1)
  void _hyoujiChikuIdou(int idou) {
    final List<int> narabi = [-1, ..._chikuJunban]; // -1は全地区
    final int ima = _hyoujiChiku ?? -1;
    final int i = narabi.indexOf(ima);
    final int saki = ((i < 0 ? 0 : i) + idou).clamp(0, narabi.length - 1).toInt();
    _hyoujiChikuErabu(narabi[saki]);
  }

  /// 表示する地区を選ぶ(-1は全地区。今の地区なら、地区が進んだときに次の地区へ付いていく)
  void _hyoujiChikuErabu(int chiku) {
    setState(() {
      _hyoujiSentaku = (chiku >= 0 && chiku == _imaChiku) ? -2 : chiku;
    });
  }

  /// 地区の一覧(下から出す。押した地区を表示する)
  Future<void> _showChikuIchiran() async {
    final int? hyouji = _hyoujiChiku;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        Widget gyou(String midashi, String sub, bool erabi, int chiku) {
          return ListTile(
            title: Text(
              midashi,
              style: TextStyle(
                color: erabi ? Colors.lightBlueAccent : Colors.white,
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: erabi ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: sub.isEmpty
                ? null
                : Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: HENSUU.fontsize_honbun - 3,
                    ),
                  ),
            onTap: () {
              Navigator.of(context).pop();
              _hyoujiChikuErabu(chiku);
            },
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              gyou('全地区', '', hyouji == null, -1),
              for (final int c in _chikuJunban)
                gyou(
                  '${_junbanMoji(c)}${comScoutChikuMei(c)}(${_chikuNinzuu(c)}人)',
                  _chikuJoutaiMoji(c),
                  hyouji == c,
                  c,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 地区の切り替え(上部の1行。1.9.6)
  /// 左右の矢印で地区の順番に1つずつ動かし、真ん中を押すと地区の一覧から選べる
  /// (文字を大きくしていても、真ん中の文が折り返すだけで、はみ出さない)
  Widget _buildChikuPanel() {
    final int? ima = _imaChiku;
    final int? hyouji = _hyoujiChiku;
    final List<int> narabi = [-1, ..._chikuJunban];
    final int pos = narabi.indexOf(hyouji ?? -1);
    final String midashi = hyouji == null
        ? '全地区'
        : '${_junbanMoji(hyouji)}${comScoutChikuMei(hyouji)}(${_chikuNinzuu(hyouji)}人)';
    final String sub;
    if (hyouji == null) {
      sub = ima == null ? '全部の地区の交渉が終わりました' : '今の地区は${comScoutChikuMei(ima)}';
    } else if (hyouji == ima) {
      sub = '${_shuukai > 1 ? '$_imaShuu周目・' : ''}'
          '今の地区(${_chikuJunban.indexOf(ima!) + 1}/${_chikuJunban.length})・'
          '${_koekake ? '声かけ' : '交渉'}は1人まで';
    } else {
      sub = ima == null
          ? 'この地区は終わりました'
          : '${_chikuJoutaiMoji(hyouji)}(今の地区は${comScoutChikuMei(ima)})';
    }
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
            disabledColor: Colors.white24,
            tooltip: '前の地区',
            onPressed: pos > 0 ? () => _hyoujiChikuIdou(-1) : null,
          ),
          Expanded(
            child: InkWell(
              onTap: _showChikuIchiran,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(
                      '$midashi ▼',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: hyouji != null && hyouji == ima
                            ? Colors.lightBlueAccent
                            : Colors.white,
                        fontSize: HENSUU.fontsize_honbun - 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: HENSUU.fontsize_honbun - 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
            disabledColor: Colors.white24,
            tooltip: '次の地区',
            onPressed: pos < narabi.length - 1
                ? () => _hyoujiChikuIdou(1)
                : null,
          ),
        ],
      ),
    );
  }

  /// 選手の状態の表示(ONのとき。進路未定・○○大学に確定など)
  /// 新入生の出身校と高校時代の実績の文(1.9.5。koukou.dart。表示しない設定のときと留学生は空)
  String _koukouMoji(SenshuData s) {
    if (s.hirou == 1) return '';
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (kantoku == null || koukouHyoujiNashi(kantoku)) return '';
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (j.mei == null) return '';
    final List<String> jisseki = koukouJissekiList(j);
    return '${koukouMeiKenMoji(j)}${jisseki.isEmpty ? '' : '　${jisseki.join('、')}'}';
  }

  /// 大学ごとの監督の母校と大学の名前(2.0.1。スカウトの画面を開いている間は監督が代わらないので、一度だけ読む)
  Map<int, int>? _bokouCache;
  Map<int, String>? _univMeiCache;

  /// 監督の母校の印に使う設定(2.0.1。コンピュータスカウトONで、監督の母校パイプの設定がなしでなく、
  /// 高校の情報を表示する設定のときだけ。出せないときはnull)
  KantokuData? _bokouSettei() {
    if (!_comScoutOn) return null;
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (kantoku == null ||
        koukouHyoujiNashi(kantoku) ||
        bokouPipeNashi(kantoku)) {
      return null;
    }
    return kantoku;
  }

  /// 新入生[s]が監督の母校の後輩になる大学(印に出す大学。2.0.1。bokou_pipe.dart)
  /// 自分の大学に効かない設定なら、自分の大学は入れない。印を出せないときと留学生は空
  List<int> _bokouUnivs(SenshuData s) {
    if (s.hirou == 1) return const [];
    final KantokuData? kantoku = _bokouSettei();
    if (kantoku == null) return const [];
    final Map<int, int> bokou = _bokouCache ??= bokouPipeBokou(kantoku);
    final int my = _ghensuu?.MYunivid ?? -1;
    final bool jibunKiku = bokouPipeJibunKiku(kantoku);
    return [
      for (final int u in bokouPipeUnivs(bokou, s))
        if (u != my || jibunKiku) u,
    ];
  }

  /// 絞り込みに「監督の母校の出身だけ」のチェックを出すか(2.0.1。[jibun] はあなたの大学の分、[hoka] はほかの大学の分)
  /// あなたの大学の分は、自分の大学に効く設定で、自分の大学に母校の分かる監督がいるときだけ。
  /// ほかの大学の分は、ほかの大学に母校の分かる監督がいるときだけ(だれも当てはまらないチェックは出さない)
  ({bool jibun, bool hoka}) _bokouFilterDasu() {
    final KantokuData? kantoku = _bokouSettei();
    if (kantoku == null) return (jibun: false, hoka: false);
    final Map<int, int> bokou = _bokouCache ??= bokouPipeBokou(kantoku);
    final int my = _ghensuu?.MYunivid ?? -1;
    return (
      jibun: bokouPipeJibunKiku(kantoku) && bokou.containsKey(my),
      hoka: bokou.keys.any((int u) => u != my),
    );
  }

  /// 監督の母校の後輩の印の文(2.0.1。bokou_pipe.dart。「○○大学の監督の母校」。なければnull)
  /// コンピュータスカウトONで、監督の母校パイプの設定がなしでなく、高校の情報を表示する設定のときだけ出す。
  /// 自分の大学に効かない設定なら、自分の大学の分は出さない。[jibun] は、あなたの大学の監督の母校か(色を変える)
  ({String moji, bool jibun})? _bokouMoji(SenshuData s) {
    final List<int> univs = _bokouUnivs(s);
    if (univs.isEmpty) return null;
    final int my = _ghensuu?.MYunivid ?? -1;
    final Map<int, String> meiMap = _univMeiCache ??= {
      for (final UnivData u in _univBox.values) u.id: u.name,
    };
    final bool jibun = univs.contains(my);
    final List<String> mei = [
      if (jibun) 'あなたの大学',
      for (final int u in univs)
        if (u != my) '${meiMap[u] ?? ''}大学',
    ];
    return (moji: '${mei.join('・')}の監督の母校', jibun: jibun);
  }

  /// 高校の情報を出すか(1.9.5。表示しない設定のときは、高校時代のフィルターと高校名鑑のボタンを出さない)
  bool _koukouHyouji() {
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    return kantoku != null && !koukouHyoujiNashi(kantoku);
  }

  /// 高校時代(直近の大会)のフィルターが入っているか(1.9.5)
  bool get _koukouFilterAri =>
      _okiniiriFilter ||
      _bokouJibunFilter ||
      _bokouHokaFilter ||
      _koukouMeiFilter.trim().isNotEmpty ||
      _ekidenTeamJuniFilter > 0 ||
      _ekidenKukanJuniFilter > 0 ||
      _soutaiJuniFilter.any((v) => v > 0);

  /// 高校時代(直近の大会)のフィルターを満たすか(1.9.5)
  /// 留学生と、高校の情報がない選手は外す(カードに出身校と実績が出ない選手)。
  /// 順位は、今年の新入生の世代の大会の記録から読む(koukou.dart の KoukouSaishinSeiseki)
  bool _koukouJoukenOk(SenshuData s) {
    if (s.hirou == 1) return false;
    final KoukouJouhou j = KoukouJouhou.yomu(s.samusataisei);
    if (j.mei == null) return false;
    if (!koukouMeiAtaru(j, _koukouMeiFilter)) return false;
    // お気に入りの高校の出身だけ(1.9.5)
    if (_okiniiriFilter && !(_okiniiriKou ??= koukouOkiniiriYomu().toSet()).contains(j.koukou - 1)) return false;
    // 監督の母校の出身だけ(2.0.1。両方にチェックしたら、どちらかに当てはまれば出す)
    if (_bokouJibunFilter || _bokouHokaFilter) {
      final List<int> us = _bokouUnivs(s);
      final int my = _ghensuu?.MYunivid ?? -1;
      final bool ok =
          (_bokouJibunFilter && us.contains(my)) ||
          (_bokouHokaFilter && us.any((int u) => u != my));
      if (!ok) return false;
    }
    final KoukouSaishinSeiseki seiseki = _koukouSeiseki ??= koukouSaishinSeisekiYomu();
    // 「○位以内」(0は条件なし。順位が0の選手は、出ていない・走っていない)
    bool inai(int juni, int joukan) => joukan <= 0 || (juni >= 1 && juni <= joukan);
    if (!inai(seiseki.teamJuni(s), _ekidenTeamJuniFilter)) return false;
    if (!inai(seiseki.kukanJuni(s), _ekidenKukanJuniFilter)) return false;
    for (int sh = 0; sh < _soutaiJuniFilter.length; sh++) {
      if (!inai(seiseki.soutaiJuni(s, sh), _soutaiJuniFilter[sh])) return false;
    }
    return true;
  }

  /// 高校名鑑を「大会の記録」のタブから開く(1.9.5。Modal_koukouMeikan.dart。一番新しい回が今年の新入生の世代)
  /// 大会の記録の進学先はカードと同じ出し方にする(コンピュータスカウトONのときは、仮の振り分けの大学を見せず、
  /// 「進路未定」「○○大学に確定」などにする。自分の大学の色も、進学先が決まった選手だけ)
  /// 戻ったら、お気に入りと校名の変更を反映するために作り直す
  Future<void> _koukouMeikanHiraku() async {
    final ({
      String? Function(KoukouKirokuSousha) shingakuMoji,
      bool Function(KoukouKirokuSousha) jibunHantei,
    }) f = _shingakuKansuu();
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ModalKoukouMeikan(
          shokiTab: 2,
          scoutKara: true,
          shingakuMoji: f.shingakuMoji,
          jibunHantei: f.jibunHantei,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _okiniiriKou = null);
  }

  /// 高校の大会の記録の選手の進学先の文字と、自分の大学の選手として色を変えるかの関数
  /// (高校名鑑と今年の高校の大会の画面で使う。1.9.9で _koukouMeikanHiraku から切り出した)
  ({
    String? Function(KoukouKirokuSousha) shingakuMoji,
    bool Function(KoukouKirokuSousha) jibunHantei,
  }) _shingakuKansuu() {
    final Map<int, SenshuData> shinnyuusei = {
      for (final SenshuData s in _senshuBox.values)
        if (s.gakunen == 1) s.id: s,
    };
    final int myUnivId = _ghensuu?.MYunivid ?? -1;
    final bool comScoutOn = _comScoutOn;
    SenshuData? sagasu(KoukouKirokuSousha k) {
      final SenshuData? s = shinnyuusei[k.id];
      return (s != null && s.name == k.name) ? s : null;
    }

    return (
      shingakuMoji: (KoukouKirokuSousha k) {
        final SenshuData? s = sagasu(k);
        if (s == null) return null;
        if (comScoutOn && s.hirou != 1) return _jyoutaiMoji(s);
        final String mei = _univBox.get(s.univid)?.name ?? '';
        return mei.isEmpty ? '' : '→ $mei大学';
      },
      jibunHantei: (KoukouKirokuSousha k) {
        final SenshuData? s = sagasu(k);
        if (s == null || s.univid != myUnivId) return false;
        if (comScoutOn && s.hirou != 1) return comScoutKettei(s);
        return true;
      },
    );
  }

  /// 今年の高校の大会の画面を出すか(1.9.9)
  /// 1ラウンド目の前で、アプリを開いてからこの年にまだ出しておらず、高校の情報を表示する設定で、
  /// 今年の新入生の世代の記録があるとき(スキップ中はこの画面に来ない)
  bool _kotoshiKoukouTaikaiDasu() {
    final Ghensuu? g = _ghensuu;
    if (g == null || _kotoshiKoukouTaikaiNen == g.year) return false;
    // 1ラウンド目の前か(残りの回数が、始めたときの回数のまま。コンピュータスカウトOFFは3回)
    final int hajime = _comScoutOn ? _roundSuu : 3;
    if (g.scoutChances < hajime) return false;
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (kantoku == null || koukouHyoujiNashi(kantoku)) return false;
    return kotoshiKoukouTaikaiKirokuAri();
  }

  /// 今年の高校の大会の画面を開く(1.9.9。Modal_koukouMeikan.dart の KotoshiKoukouTaikaiGamen)
  Future<void> _kotoshiKoukouTaikaiHiraku() async {
    _kotoshiKoukouTaikaiNen = _ghensuu?.year ?? -1;
    final ({
      String? Function(KoukouKirokuSousha) shingakuMoji,
      bool Function(KoukouKirokuSousha) jibunHantei,
    }) f = _shingakuKansuu();
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => KotoshiKoukouTaikaiGamen(
          shingakuMoji: f.shingakuMoji,
          jibunHantei: f.jibunHantei,
        ),
      ),
    );
  }

  String _jyoutaiMoji(SenshuData s) {
    if (comScoutKotowarareta(s)) {
      // 地区めぐりでは「保留」と呼ぶ(1.9.6。最後の志望であなたの大学を選ぶこともある)
      return _chikuMeguri ? '進路未定(あなたの大学には返事を保留)' : '進路未定(あなたの大学は断った)';
    }
    if (!comScoutKettei(s)) return '進路未定';
    final String mei = _univBox.get(s.univid)?.name ?? '不明';
    if (s.univid == _ghensuu!.MYunivid) {
      return comScoutKakutei(s) ? 'あなたの大学に確定' : 'あなたの大学に入学(志望)';
    }
    return comScoutKakutei(s) ? '$mei大学に確定' : '$mei大学に入学(志望)';
  }

  /// 選手リストを現在の並び替え条件に基づいてソートする
  void _sortFreshmenLists() {
    int Function(SenshuData a, SenshuData b) compareFunction;

    switch (_currentSortCriterion) {
      case SortCriterion.time:
        compareFunction = (a, b) {
          final timeComparison = a.kiroku_nyuugakuji_5000.compareTo(
            b.kiroku_nyuugakuji_5000,
          );
          if (timeComparison != 0) {
            return _isTimeAscending ? timeComparison : -timeComparison;
          } else {
            // タイムが同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.konjou:
        compareFunction = (a, b) {
          final abilityComparison = b.konjou.compareTo(a.konjou);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.heijousin:
        compareFunction = (a, b) {
          final abilityComparison = b.heijousin.compareTo(a.heijousin);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.choukyorinebari:
        compareFunction = (a, b) {
          final abilityComparison = b.choukyorinebari.compareTo(
            a.choukyorinebari,
          );
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.spurtryoku:
        compareFunction = (a, b) {
          final abilityComparison = b.spurtryoku.compareTo(a.spurtryoku);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.karisuma:
        compareFunction = (a, b) {
          final abilityComparison = b.karisuma.compareTo(a.karisuma);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.noboritekisei:
        compareFunction = (a, b) {
          final abilityComparison = b.noboritekisei.compareTo(a.noboritekisei);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.kudaritekisei:
        compareFunction = (a, b) {
          final abilityComparison = b.kudaritekisei.compareTo(a.kudaritekisei);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.noborikudarikirikaenouryoku:
        compareFunction = (a, b) {
          final abilityComparison = b.noborikudarikirikaenouryoku.compareTo(
            a.noborikudarikirikaenouryoku,
          );
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.tandokusou:
        compareFunction = (a, b) {
          final abilityComparison = b.tandokusou.compareTo(a.tandokusou);
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.paceagesagetaiouryoku:
        compareFunction = (a, b) {
          final abilityComparison = b.paceagesagetaiouryoku.compareTo(
            a.paceagesagetaiouryoku,
          );
          if (abilityComparison != 0) {
            return _isAbilityDescending
                ? abilityComparison
                : -abilityComparison;
          } else {
            // 能力値が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      // ★交渉成功確率でのソートを追加
      case SortCriterion.successRate:
        compareFunction = (a, b) {
          // kegaflag は成功率(0.1%単位。1.8.8)なので、そのまま比較すると降順になる
          // 成功確率が高いほど値が大きいので、b.kegaflag.compareTo(a.kegaflag) で降順ソート
          // (「決定」「断られた」などの印は負の値なので、一番下になる)
          final successRateComparison = b.kegaflag.compareTo(a.kegaflag);
          if (successRateComparison != 0) {
            return successRateComparison;
          } else {
            // 成功確率が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.anteikan:
        compareFunction = (a, b) {
          // そのまま比較すると降順になる
          // 降順ソート
          final anteikanComparison = b.anteikan.compareTo(a.anteikan);
          if (anteikanComparison != 0) {
            return anteikanComparison;
          } else {
            // 成功確率が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
      case SortCriterion.univid:
        compareFunction = (a, b) {
          // 昇順ソート
          // (コンピュータスカウトONのときは、決まった大学の順。進路未定は先頭。
          //  仮の振り分けの大学が分からないように)
          final int ka = !_comScoutOn || comScoutKettei(a) ? a.univid : -1;
          final int kb = !_comScoutOn || comScoutKettei(b) ? b.univid : -1;
          final unividComparison = ka.compareTo(kb);
          if (unividComparison != 0) {
            return unividComparison;
          } else {
            // 成功確率が同じ場合は、選手IDでソートして安定化
            return a.id.compareTo(b.id);
          }
        };
        break;
    }

    _myFreshmen.sort(compareFunction);
    _targetFreshmen.sort(compareFunction);
    // コンピュータスカウトONのときは、進路未定の選手を先に並べる(並べ替えの順は保つ)
    if (_comScoutOn) {
      _targetFreshmen = [
        ..._targetFreshmen.where((s) => !comScoutKettei(s)),
        ..._targetFreshmen.where(comScoutKettei),
      ];
    }
  }

  /// 交渉成功確率を計算し、選手の`kegaflag`に格納する
  void _calculateAndStoreSuccessRate(SenshuData freshman) {
    final myUnivId = _ghensuu!.MYunivid;
    final myUniv = _univBox.get(myUnivId)!;
    final targetUniv = _univBox.get(freshman.univid)!;

    // 1. 大学の名声値に基づく基本成功確率の計算
    double universityPrestigeRate;
    // 分母がゼロになるのを防ぐ
    if (myUniv.meisei_total + targetUniv.meisei_total > 0) {
      universityPrestigeRate =
          myUniv.meisei_total / (myUniv.meisei_total + targetUniv.meisei_total);
    } else {
      universityPrestigeRate = 0.5; // 分母がゼロの場合は基本値を設定
    }
    universityPrestigeRate = universityPrestigeRate.clamp(
      0.001,
      0.9,
    ); //0.1％から90％の範囲にする

    // 2. タイム順位に基づく最大成功確率の計算
    // _targetFreshmen は既にタイム順でソートされていることを前提とする
    int rank = _targetFreshmen.indexOf(freshman) + 1; // 1-based index
    double maxSuccessRateBasedOnTime =
        0.10 + (rank - 1) * (0.75 - 0.10) / (87.0 - 1.0);
    maxSuccessRateBasedOnTime = maxSuccessRateBasedOnTime.clamp(
      0.10,
      0.75,
    ); // 10%～75% の範囲に収める

    // 3. 最終的な成功確率の決定
    double finalSuccessRate = universityPrestigeRate;
    // 大学名声に基づく確率が、タイム順位に基づく最大確率を超える場合は、最大確率に丸める
    if (finalSuccessRate > maxSuccessRateBasedOnTime) {
      finalSuccessRate = maxSuccessRateBasedOnTime;
    }
    // kegaflag に確率を0.1%単位の整数で格納する
    // (1%以上は1%単位、1%未満は0.1%単位(下限0.1%)に丸める。1.8.8。scout_com.dart。
    //  1.8.7までは1%単位で、1%未満は-1(一律0.1%)だった)
    if (freshman.hirou == 1) {
      freshman.kegaflag = -2;
    } else {
      freshman.kegaflag = scoutSeikouritsuKegaflag(
        scoutSeikouritsuMarume(finalSuccessRate),
      );
    }
  }

  /// 交渉ボタンが押された時の処理
  void _negotiate(SenshuData freshman) async {
    if (_ghensuu!.scoutChances <= 0) {
      return;
    }
    // コンピュータスカウトONでは、断られた選手とはその年はもう交渉できない
    if (_comScoutOn && comScoutKotowarareta(freshman)) {
      return;
    }
    // コンピュータスカウトがONなら、コンピュータの大学と同じラウンドで一斉に判定する
    if (_comScoutOn) {
      if (_chikuMeguri) {
        // 地区めぐりは、今の地区の選手とだけ交渉できる(1.9.6)
        if (_chikuBetsu[freshman.id] != _imaChiku) return;
        await _chikuRound(freshman);
        return;
      }
      await _negotiateRound(freshman);
      return;
    }

    // 成功確率を取得(画面に出している値と同じ。1.8.8)
    final double successRate = scoutSeikouritsuFromKegaflag(freshman.kegaflag);

    final random = Random();
    final isSuccess = random.nextDouble() < successRate;

    setState(() {
      _ghensuu!.scoutChances--;
    });

    await _ghensuu!.save(); // awaitを使って非同期的にデータを保存

    if (isSuccess) {
      setState(() {
        freshman.univid = _ghensuu!.MYunivid;
      });
      await freshman.save();
      // リストの再初期化
      _initializeScoutingData();
      _showAcquireSeikouDialog(freshman);
      //_showAcquireSuccessDialog(freshman);
    } else {
      _showAcquireFailureDialog(freshman);
    }
  }

  /// 今が何ラウンド目か(1から)
  int _roundBangou() {
    final int bangou = _roundSuu - _ghensuu!.scoutChances + 1;
    return bangou < 1 ? 1 : bangou;
  }

  /// コンピュータスカウトONのときの交渉(プレイヤーとコンピュータの大学が同じラウンドで交渉する)
  Future<void> _negotiateRound(SenshuData freshman) async {
    // 成功率(画面に出している値と同じ。1.8.8)
    final double successRate = scoutSeikouritsuFromKegaflag(freshman.kegaflag);
    final int roundBangou = _roundBangou();
    setState(() {
      _isLoading = true;
      _loadingMessage = 'ラウンド$roundBangouの結果を判定中...';
    });
    List<ComScoutKekka> kekka = [];
    final List<ComScoutKoudou> koudou = [];
    try {
      // 処理前スナップショット(途中で終了しても処理前の状態に戻せるように)
      await ShoriGuard.begin('新入生スカウト');
      kekka = await comScoutRound(
        gh: _ghensuu!,
        roundBangou: roundBangou,
        playerTarget: freshman,
        playerSeikouritsu: successRate,
        koudou: koudou,
      );
      _ghensuu!.scoutChances--;
      await _ghensuu!.save();
      await ShoriGuard.end();
    } catch (e) {
      ShoriGuard.reportError('新入生スカウト', e);
      return;
    }
    _roundKiroku.add(MapEntry(roundBangou, koudou));
    // リストの再初期化
    _initializeScoutingData();
    if (!mounted) return;
    // ダイアログは自大学の結果だけ(全大学の動きは「全大学の動きを見る」から)
    await _showKekkaDialog(
      'ラウンド$roundBangouの結果',
      comScoutKekkaBun(kekka, _ghensuu!.MYunivid, jibunNomi: true),
      hajimeRound: roundBangou,
    );
  }

  /// 「ラウンドの結果」の画面(全大学のラウンドごとの行動)を開く
  /// 地区めぐりでは、ラウンドに地区の名前を添え、まとまらなかった交渉を「保留」と出す(1.9.6)
  Future<void> _openRoundKekka({int? hajimeRound}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScoutRoundKekkaScreen(
          kiroku: _roundKiroku,
          myUnivid: _ghensuu!.MYunivid,
          hajimeRound: hajimeRound,
          roundMei: _chikuMeguri
              ? {
                  for (int i = 0; i < _roundSuu; i++)
                    i + 1:
                        '${_shuukai > 1 ? '${i ~/ _chikuJunban.length + 1}周目・' : ''}'
                        '${comScoutChikuMei(_chikuJunban[i % _chikuJunban.length])}',
                }
              : const <int, String>{},
          horyuu: _chikuMeguri && !_koekake,
          koekake: _koekake,
        ),
      ),
    );
  }

  /// 「新入生の進学先(全大学)」の画面を開く(スカウト終了時のダイアログから)
  Future<void> _openShingakusaki() {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModalShinnyuuseiShingakusaki()),
    );
  }

  /// コンピュータスカウトONで、地区めぐり(声かけ)のときの説明(1.9.6)
  String _koekakeSetsumei() {
    return 'コンピュータスカウトONは、コンピュータの大学との真剣勝負です'
        '(説明画面の設定タブの「コンピュータスカウト」で、スカウトの形を変えたり、OFFにしたりできます)。\n\n'
        '新入生は全員「進路未定」です(あなたの大学も含め、どの大学にも分かりません)。\n\n'
        '今年のスカウトは「地区めぐり(声かけ)」です。新入生は出身校の地区(北海道・東北など11地区)ごとに分かれていて、'
        '地区ごとに1ラウンドずつ声をかけます。地区の順番は毎年変わります。'
        'どの大学も、今の地区の選手に1人まで声をかけられ、見送ることもできます。'
        'ほかの地区の選手は、上の地区の切り替え(左右の矢印か、地区の名前を押す)で見られます。'
        '声をかけられるのは、その地区の番のときだけです。'
        '${_shuukai > 1 ? '今年は、この順番で最大$_shuukai周します(全員の進学先が決まれば、そこで終わり、進路未定の選手がいない地区は飛ばします)。' : ''}\n\n'
        '声かけに成功率はありません。ほかに声をかけた大学がなければ、その大学に確定します。'
        '同じ選手に複数の大学が声をかけた場合は争奪戦になり、選手が進学先を選びます'
        '(名声の高い大学ほど選ばれやすく、設定タブの「入学時名声影響度設定」で強さが変わります)。'
        'まれに、大学の名声をあまり気にしない新入生もいます。'
        'コンピュータの大学は、自校の基準を満たす選手の中で、評価の高い選手に声をかけます'
        '(毎回動きますが、基準を満たす選手が今の地区にいなければ見送ります)。\n\n'
        'カードの「全国12位(未定で5位)」は、新入生全体と、まだ進路未定の選手の中での、持ちタイムの順位です。\n\n'
        '確定できるのは、日本人の新入生の枠(5人。留学生が入学する大学は4人)までです。'
        'あなたの大学の枠は$_waku人で、確定しているのは$_kakuteiSuu人です。'
        '${_ryuugakuseiSuu > 0 ? 'あなたの大学には留学生が$_ryuugakuseiSuu人入学します。' : ''}\n\n'
        '全部の地区が終わってスカウトを終えると(途中で終えたときは、残りの地区をコンピュータの大学だけで行います)、'
        '確定しなかった選手が自ら志望して進学先を選びます'
        '(名声の高い大学ほど選ばれやすく、どの大学も枠がちょうど埋まります)。\n\n'
        '「ラウンドの結果」では、全大学の地区ごとの動きを見られます(スカウト画面を開いている間だけ記録しています)。\n\n'
        'スカウトを終えると、全大学の新入生の進学先(声かけ・志望・留学生)を見られます'
        '(説明画面の設定タブの「新入生の進学先(全大学)」からも、翌年のスカウトまで見られます)。';
  }

  /// コンピュータスカウトONで、地区めぐり(交渉)のときの説明(1.9.6)
  String _chikuMeguriSetsumei() {
    return 'コンピュータスカウトONは、コンピュータの大学との真剣勝負です。名声の低い大学ほど成功率は低くなります'
        '(説明画面の設定タブの「コンピュータスカウト」で、スカウトの形を変えたり、OFFにしたりできます)。\n\n'
        '新入生は全員「進路未定」です(あなたの大学も含め、どの大学にも分かりません)。\n\n'
        '今年のスカウトは「地区めぐり(交渉)」です。新入生は出身校の地区(北海道・東北など11地区)ごとに分かれていて、'
        '地区ごとに1ラウンドずつ交渉します。地区の順番は毎年変わります。'
        'どの大学も、今の地区の選手に1人まで交渉でき、見送ることもできます。'
        'ほかの地区の選手は、上の地区の切り替え(左右の矢印か、地区の名前を押す)で見られます。交渉できるのは、その地区の番のときだけです。\n\n'
        '同じ選手に複数の大学が成功した場合は争奪戦になり、選手が進学先を選びます(名声の高い大学ほど選ばれやすくなります)。'
        'まれに、大学の名声をあまり気にしない新入生もいます。'
        '確定した選手は、その年はもう交渉に応じません。'
        '交渉がまとまらなかった選手は返事を保留し、その年はもう交渉できません(コンピュータの大学も同じです)。\n\n'
        '成功率は、新入生全体の中での持ちタイムの順位と、大学の名声で決まります。'
        '名声の高い大学ほど、持ちタイムの良い選手の成功率も上がります。'
        'カードの「全国12位(未定で5位)」は、新入生全体と、まだ進路未定の選手の中での、持ちタイムの順位です。\n\n'
        '確定できるのは、日本人の新入生の枠(5人。留学生が入学する大学は4人)までです。'
        'あなたの大学の枠は$_waku人で、確定しているのは$_kakuteiSuu人です。'
        '${_ryuugakuseiSuu > 0 ? 'あなたの大学には留学生が$_ryuugakuseiSuu人入学します。' : ''}\n\n'
        '全部の地区が終わってスカウトを終えると(途中で終えたときは、残りの地区をコンピュータの大学だけで行います)、'
        '確定しなかった選手が自ら志望して進学先を選びます'
        '(名声の高い大学ほど選ばれやすく、返事を保留した大学を選ぶこともあります。どの大学も枠がちょうど埋まります)。\n\n'
        '「ラウンドの結果」では、全大学の地区ごとの動きを見られます(スカウト画面を開いている間だけ記録しています)。\n\n'
        'スカウトを終えると、全大学の新入生の進学先(交渉・志望・留学生)を見られます'
        '(説明画面の設定タブの「新入生の進学先(全大学)」からも、翌年のスカウトまで見られます)。';
  }

  /// 強化プロジェクト中の大学の案内(なければnull。2.0.1。kyouka_project.dart)
  String? _kyoukaMoji() {
    final Ghensuu? gh = _ghensuu;
    if (gh == null) return null;
    final KyoukaProject? p = kyoukaProjectIma(gh);
    if (p == null) return null;
    String mei = '';
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == p.univid) mei = u.name;
    }
    if (mei.isEmpty) return null;
    // 自分の大学のときは「あなたの大学」(設定で自分の大学も選ばれるようにしたとき。2.0.1)
    final String dare = p.univid == gh.MYunivid ? 'あなたの大学' : '$mei大学';
    return '強化プロジェクト中: $dare(${p.owari}年度まで)。'
        'スカウトに力を入れていて、名声の高い大学と同じくらい選ばれやすくなっています';
  }

  /// コンピュータスカウトONのときの説明
  void _showSetsumeiDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _koekake
                ? 'コンピュータスカウトON・地区めぐり(声かけ)'
                : _chikuMeguri
                ? 'コンピュータスカウトON・地区めぐり(交渉)'
                : 'コンピュータスカウトON',
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Text(
              _koekake
                  ? _koekakeSetsumei()
                  : _chikuMeguri
                  ? _chikuMeguriSetsumei()
                  : 'コンピュータスカウトONは、コンピュータの大学との真剣勝負です。名声の低い大学ほど成功率は低くなります'
              '(説明画面の設定タブの「コンピュータスカウト」でOFFにすると、今まで通りのスカウトになります)。\n\n'
              '新入生は全員「進路未定」です(あなたの大学も含め、どの大学にも分かりません)。\n\n'
              '交渉するたびに、コンピュータの大学も同じラウンドで1人ずつ交渉し、成功した大学に確定します。'
              '同じ選手に複数の大学が成功した場合は争奪戦になり、選手が進学先を選びます(名声の高い大学ほど選ばれやすくなります)。'
              'まれに、大学の名声をあまり気にしない新入生もいます。'
              '確定した選手は、その年はもう交渉に応じません。'
              '交渉に失敗した選手とは、その年はもう交渉できません(コンピュータの大学も同じです)。\n\n'
              '確定できるのは、日本人の新入生の枠(5人。留学生が入学する大学は4人)までです。'
              'あなたの大学の枠は$_waku人で、確定しているのは$_kakuteiSuu人です。'
              '${_ryuugakuseiSuu > 0 ? 'あなたの大学には留学生が$_ryuugakuseiSuu人入学します。' : ''}\n\n'
              'スカウトを終えると、残りのラウンドはコンピュータの大学だけで行います。'
              'そのあと、確定しなかった選手が自ら志望して進学先を選びます(名声の高い大学ほど選ばれやすく、どの大学も枠がちょうど埋まります)。\n\n'
              '「ラウンドの結果」では、全大学のラウンドごとの動きを見られます(スカウト画面を開いている間だけ記録しています)。\n\n'
              'スカウトを終えると、全大学の新入生の進学先(交渉・志望・留学生)を見られます'
              '(説明画面の設定タブの「新入生の進学先(全大学)」からも、翌年のスカウトまで見られます)。',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// スカウトを終える(コンピュータスカウトONなら、残りのラウンドと最後の志望を先に済ませる)
  /// そのあと、自大学の新入生が5人を超えていれば放出の画面へ(ONでは、1.7.8から引き継いだ
  /// 途中のスカウトで5人を超えた場合だけ)
  Future<void> _scoutShuuryou() async {
    if (_comScoutOn) {
      final int nokori = _ghensuu!.scoutChances;
      final int hajime = _roundBangou();
      setState(() {
        _isLoading = true;
        _loadingMessage = nokori > 0
            ? (_chikuMeguri ? '残りの地区を判定中...' : '残りのラウンドを判定中...')
            : '進学先を決めています...';
      });
      final List<String> bun = [];
      try {
        // 処理前スナップショット(途中で終了しても処理前の状態に戻せるように)
        await ShoriGuard.begin('新入生スカウト');
        // 残りのラウンドはコンピュータの大学だけで行う(全大学の動きは「全大学の動きを見る」から)
        // (地区めぐりでは、残りの地区を順番に1ラウンドずつ。1.9.6)
        final List<MapEntry<int, List<ComScoutKoudou>>> nokoriKiroku = [];
        for (int i = 0; i < nokori; i++) {
          final List<ComScoutKoudou> koudou = [];
          final int idx = hajime + i - 1;
          int? chiku;
          if (_chikuMeguri) {
            if (idx < 0 || idx >= _roundSuu || _chikuJunban.isEmpty) {
              continue; // ラウンドの数を超えた分(通常は起こらない)
            }
            // 周回では、全員の進路が決まれば終わり、2周目からは進路未定の選手がいない地区を飛ばす(1.9.6)
            final List<SenshuData> shinnyuusei = comScoutShinnyuusei();
            if (!comScoutMiteiAri(shinnyuusei)) break;
            chiku = _chikuJunban[idx % _chikuJunban.length];
            if (idx >= _chikuJunban.length &&
                !comScoutChikuMiteiAri(shinnyuusei, chiku)) {
              continue;
            }
          }
          await comScoutRound(
            gh: _ghensuu!,
            roundBangou: hajime + i,
            koudou: koudou,
            chiku: chiku,
            koekake: _koekake,
          );
          nokoriKiroku.add(MapEntry(hajime + i, koudou));
        }
        _ghensuu!.scoutChances = 0;
        await _ghensuu!.save();
        // 確定しなかった選手が、自ら志望して進学先を選ぶ
        // (地区めぐりでは、返事を保留していてあなたの大学を選んだ選手を、そのように書く。1.9.6)
        final Set<int> horyuu = {};
        final Map<int, int> shigan = await comScoutShigan(
          gh: _ghensuu!,
          horyuuJiko: _chikuMeguri && !_koekake ? horyuu : null,
        );
        bun.addAll(
          comScoutNyuugakuBun(
            myUnivid: _ghensuu!.MYunivid,
            shigan: shigan,
            horyuu: horyuu,
            koekake: _koekake,
          ),
        );
        await ShoriGuard.end();
        _roundKiroku.addAll(nokoriKiroku);
      } catch (e) {
        ShoriGuard.reportError('新入生スカウト', e);
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showKekkaDialog(
        'あなたの大学に入学する新入生',
        bun,
        hajimeRound: nokori > 0 ? hajime : null,
        shingakusakiBotan: true,
      );
      if (!mounted) return;
    }

    // 自大学の新入生を抽出
    final myFreshmen = _senshuBox.values
        .where((s) => s.univid == _ghensuu!.MYunivid && s.gakunen == 1)
        .toList();

    if (myFreshmen.length > TEISUU.NINZUU_1GAKUNEN_INUNIV) {
      setState(() => _ghensuu!.mode = 9003);
    } else {
      setState(() => _ghensuu!.mode = 9005);
    }

    await _ghensuu!.save();
  }

  /// ラウンドの結果を表示するダイアログ(閉じるまで待つ)
  /// ラウンドの記録があれば「全大学の動きを見る」ボタンを付ける([hajimeRound] のラウンドから開く)
  /// [shingakusakiBotan] がtrueなら「全大学の新入生を見る」ボタンを付ける(スカウト終了時)
  Future<void> _showKekkaDialog(
    String title,
    List<String> lines, {
    int? hajimeRound,
    bool shingakusakiBotan = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lines.isEmpty)
                  const Text(
                    '(確定した選手はいませんでした)',
                    style: TextStyle(color: Colors.black),
                  ),
                for (final String line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: line.startsWith('【')
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            if (_roundKiroku.isNotEmpty)
              TextButton(
                onPressed: () => _openRoundKekka(hajimeRound: hajimeRound),
                child: const Text('全大学の動きを見る'),
              ),
            if (shingakusakiBotan)
              TextButton(
                onPressed: () => _openShingakusaki(),
                child: const Text('全大学の新入生を見る'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// 下部の1行に置くリンク(押せる範囲を少し広めにとる。押せないときは薄く出す)
  Widget _footerLink(String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: onTap == null ? Colors.white38 : Colors.lightBlueAccent,
            fontSize: HENSUU.fontsize_honbun - 2,
            decoration: onTap == null
                ? TextDecoration.none
                : TextDecoration.underline,
            decorationColor: Colors.lightBlueAccent,
          ),
        ),
      ),
    );
  }

  /// 強奪失敗時のダイアログを表示する
  void _showAcquireSeikouDialog(SenshuData freshman) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('交渉成功！！', style: TextStyle(color: Colors.black)),
          content: Text(
            '${freshman.name}選手の獲得に成功しました！！',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// 強奪失敗時のダイアログを表示する
  void _showAcquireFailureDialog(SenshuData freshman) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('交渉失敗...', style: TextStyle(color: Colors.black)),
          content: Text(
            '${freshman.name}選手の獲得に失敗しました。',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// 選手が現在のフィルター条件を満たしているかを確認する
  bool _meetsFilterCriteria(SenshuData freshman) {
    // 0. 高校時代(直近の大会)のフィルター(1.9.5。高校の情報を表示しない設定のときは見ない)
    if (_koukouFilterAri && _koukouHyouji() && !_koukouJoukenOk(freshman)) {
      return false;
    }

    // 1. ★持ちタイムフィルターチェック
    // 持ちタイムが設定値より大きい（悪いタイム）であれば false
    if (_timeFilterSeconds != TEISUU.DEFAULTTIME &&
        freshman.kiroku_nyuugakuji_5000 > _timeFilterSeconds) {
      return false;
    }

    // 2. ★追加: 成功率フィルターチェック
    if (_successRateFilter > 0) {
      // freshman.kegaflag が格納している成功率(0.1%単位。1.8.8)を%にする(印は0%)
      final double successRate =
          scoutSeikouritsuFromKegaflag(freshman.kegaflag) * 100.0;

      // 設定された最低成功率（_successRateFilter）を下回る場合は false
      // 例: フィルターが60%の場合、59%以下(1%未満や印も含む)は除外
      if (successRate < _successRateFilter - 0.0001) {
        return false;
      }
    }
    if (_anteikanFilter > 0) {
      // freshman.kegaflag が格納している成功率（-2, -1, 1-100）
      final int anteikanRate = freshman.anteikan;
      if (anteikanRate < _anteikanFilter) {
        return false;
      }
    }

    // 2. 能力値フィルターチェック
    // フィルタリング対象の能力値についてチェック
    for (var entry in _abilityFilters.entries) {
      final criterion = entry.key;
      final requiredMin = entry.value;

      if (requiredMin > 0) {
        int abilityValue = 0;
        bool isVisible = false;

        // 該当する能力値を取得
        switch (criterion) {
          case SortCriterion.konjou:
            abilityValue = freshman.konjou;
            isVisible = _ghensuu!.nouryokumieruflag[0] == 1;
            break;
          case SortCriterion.heijousin:
            abilityValue = freshman.heijousin;
            isVisible = _ghensuu!.nouryokumieruflag[1] == 1;
            break;
          case SortCriterion.choukyorinebari:
            abilityValue = freshman.choukyorinebari;
            isVisible = _ghensuu!.nouryokumieruflag[2] == 1;
            break;
          case SortCriterion.spurtryoku:
            abilityValue = freshman.spurtryoku;
            isVisible = _ghensuu!.nouryokumieruflag[3] == 1;
            break;
          case SortCriterion.karisuma:
            abilityValue = freshman.karisuma;
            isVisible = _ghensuu!.nouryokumieruflag[4] == 1;
            break;
          case SortCriterion.noboritekisei:
            abilityValue = freshman.noboritekisei;
            isVisible = _ghensuu!.nouryokumieruflag[5] == 1;
            break;
          case SortCriterion.kudaritekisei:
            abilityValue = freshman.kudaritekisei;
            isVisible = _ghensuu!.nouryokumieruflag[6] == 1;
            break;
          case SortCriterion.noborikudarikirikaenouryoku:
            abilityValue = freshman.noborikudarikirikaenouryoku;
            isVisible = _ghensuu!.nouryokumieruflag[7] == 1;
            break;
          case SortCriterion.tandokusou:
            abilityValue = freshman.tandokusou;
            isVisible = _ghensuu!.nouryokumieruflag[8] == 1;
            break;
          case SortCriterion.paceagesagetaiouryoku:
            abilityValue = freshman.paceagesagetaiouryoku;
            isVisible = _ghensuu!.nouryokumieruflag[9] == 1;
            break;
          default:
            continue;
        }

        // フィルタリング対象の能力（nouryokumieruflagが1）で、
        // かつ要求される最小値（requiredMin）を満たさない場合は false
        if (isVisible && abilityValue < requiredMin) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // 読み込み中、またはデータが不十分な場合のローディング画面
    if (_isLoading || _ghensuu == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                _loadingMessage,
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 地区めぐりでは、表示している地区の選手だけ(1.9.6。自大学に確定した選手はいつも出す)
    final int? hyoujiChiku = _hyoujiChiku;
    final List<SenshuData> filteredTargetFreshmen = _targetFreshmen
        .where(_meetsFilterCriteria)
        .where((s) => hyoujiChiku == null || _chikuBetsu[s.id] == hyoujiChiku)
        .toList();
    final List<SenshuData> filteredMyFreshmen = _myFreshmen
        .where(_meetsFilterCriteria)
        .toList();

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '新入生スカウト',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                _chikuMeguri
                    ? '残り${_ghensuu!.scoutChances}地区'
                    : 'チャンス: ${_ghensuu!.scoutChances}回',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部：操作パネル
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey[900],
            child: _buildFilterAndSortButtons(),
          ),
          // 地区めぐりの地区の切り替え(1.9.6)
          if (_chikuMeguri) _buildChikuPanel(),
          // 強化プロジェクト中の大学(2.0.1。kyouka_project.dart)
          if (_kyoukaMoji() != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.orange.withOpacity(0.15),
              child: Text(
                _kyoukaMoji()!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ),

          // 選手リスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount:
                  filteredMyFreshmen.length + filteredTargetFreshmen.length,
              itemBuilder: (context, index) {
                if (index < filteredMyFreshmen.length) {
                  return _buildFreshmanCard(
                    filteredMyFreshmen[index],
                    isMyUniv: true,
                  );
                } else {
                  return _buildFreshmanCard(
                    filteredTargetFreshmen[index - filteredMyFreshmen.length],
                    isMyUniv: false,
                  );
                }
              },
            ),
          ),

          // 下部：イベント終了エリア
          _buildStickyFooter(),
        ],
      ),
    );
  }

  /// 選手カードのビルド（タイムサイズ調整 ＆ 自校デザイン強化版）
  Widget _buildFreshmanCard(SenshuData freshman, {required bool isMyUniv}) {
    final targetUniv = _univBox.get(freshman.univid);

    // タイム文字列の生成
    String timeStr = "記録なし";
    if (freshman.kiroku_nyuugakuji_5000 != TEISUU.DEFAULTTIME) {
      int m = (freshman.kiroku_nyuugakuji_5000 / 60).floor();
      int s = (freshman.kiroku_nyuugakuji_5000 % 60).floor();
      timeStr = "${m}分${s.toString().padLeft(2, '0')}秒";
    }

    // 成功率テキスト
    // (1%未満も0.1%単位で出す。1.8.8。scout_com.dart)
    String rateStr = scoutSeikouritsuBun(freshman.kegaflag);
    // コンピュータスカウトONで進学先が決まった選手は、成功率の代わりに「決定」
    final bool kettei = _comScoutOn && comScoutKettei(freshman);
    if (kettei) rateStr = '決定';
    // コンピュータスカウトONであなたの大学との交渉を断った選手は「断られた」(もう交渉できない)
    // (地区めぐりでは「保留」。1.9.6)
    final bool kotowari = _comScoutOn && comScoutKotowarareta(freshman);
    if (kotowari) rateStr = _chikuMeguri ? '保留' : '断られた';
    // 地区めぐり(声かけ)には成功率がないので、進路未定の選手は「未定」(1.9.6)
    if (_koekake && !kettei) rateStr = '未定';
    // 出身校と高校時代の実績(1.9.5)
    final String koukouMoji = _koukouMoji(freshman);
    // 監督の母校の後輩の印(2.0.1。bokou_pipe.dart)
    final ({String moji, bool jibun})? bokouMoji = _bokouMoji(freshman);
    // 地区めぐりの地区と順位、交渉できる地区か(1.9.6)
    final String chikuJuniMoji = _chikuMeguri && freshman.hirou != 1
        ? _chikuJuniMoji(freshman)
        : '';
    final int? senshuChiku = _chikuBetsu[freshman.id];
    final bool chikuOk = !_chikuMeguri || senshuChiku == _imaChiku;
    String kousyouLabel = _koekake ? '声をかける' : '交渉';
    if (!chikuOk && senshuChiku != null) {
      // 「3地区目」「次の周」「終了」(1.9.6)
      kousyouLabel = _chikuJoutaiMoji(senshuChiku);
    }

    return Card(
      // 自校なら濃い紺色、他校なら深いグレー
      color: isMyUniv ? const Color(0xFF1A1F26) : const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          // 自校ならゴールド、他校なら落ち着いた青の枠線
          color: isMyUniv ? Colors.amber : Colors.blueAccent.withOpacity(0.3),
          width: isMyUniv ? 2.0 : 1.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          // 上段：タイム・成功率/自校ラベル
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 5000mタイム（サイズを少し抑えて上品に）
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5000m TIME',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: HENSUU.fontsize_honbun - 2,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMyUniv
                              ? Colors.amberAccent
                              : Colors.cyanAccent,
                          fontSize:
                              HENSUU.fontsize_honbun + 2, // 22 -> 18 にサイズダウン
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                      // 地区めぐりの地区と順位(1.9.6。例: 近畿・全国12位(未定で5位))
                      if (chikuJuniMoji.isNotEmpty)
                        Text(
                          chikuJuniMoji,
                          style: TextStyle(
                            color: isMyUniv
                                ? Colors.amber.withOpacity(0.8)
                                : Colors.white70,
                            fontSize: HENSUU.fontsize_honbun - 2,
                          ),
                        ),
                    ],
                  ),
                ),
                // 右側エリア：成功率 または 自校ラベル
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isMyUniv) ...[
                        const Text(
                          'STATUS',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: HENSUU.fontsize_honbun - 2,
                          ),
                        ),
                        const Text(
                          '自大学',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          kettei || kotowari || _koekake ? '状態' : '成功率',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: HENSUU.fontsize_honbun - 2,
                          ),
                        ),
                        Text(
                          rateStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: HENSUU.fontsize_honbun + 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 中段：能力バッジエリア
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            // 自校ならゴールド系の透過背景、他校なら黒透過背景
            color: isMyUniv ? Colors.amber.withOpacity(0.1) : Colors.black26,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _buildAbilityBadges(freshman, isMyUniv: isMyUniv),
            ),
          ),

          // 下段：名前とアクション
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        freshman.name,
                        style: TextStyle(
                          color: isMyUniv ? Colors.amber[100] : Colors.white70,
                          fontSize: HENSUU.fontsize_honbun - 2,
                          fontWeight: isMyUniv
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 出身校と高校時代の実績(1.9.5。長いときは折り返す)
                      if (koukouMoji.isNotEmpty)
                        Text(
                          koukouMoji,
                          style: TextStyle(
                            color: isMyUniv
                                ? Colors.amber.withOpacity(0.8)
                                : Colors.white60,
                            fontSize: HENSUU.fontsize_honbun - 2,
                          ),
                        ),
                      // 監督の母校の後輩の印(2.0.1。横に並べず1行の文にして、長いときは折り返す)
                      if (bokouMoji != null)
                        Text(
                          bokouMoji.moji,
                          style: TextStyle(
                            color: bokouMoji.jibun
                                ? Colors.amber
                                : Colors.orangeAccent,
                            fontSize: HENSUU.fontsize_honbun - 2,
                          ),
                        ),
                      Text(
                        _comScoutOn
                            ? _jyoutaiMoji(freshman)
                            : (isMyUniv
                                  ? 'あなたの大学に入学予定'
                                  : '本来の進路: ${targetUniv?.name ?? "不明"}'),
                        style: TextStyle(
                          color: isMyUniv
                              ? Colors.amber.withOpacity(0.5)
                              : Colors.white38,
                          fontSize: HENSUU.fontsize_honbun - 2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMyUniv && freshman.hirou != 1 && !kettei)
                  SizedBox(
                    height: 36,
                    width: 90,
                    child: ElevatedButton(
                      // コンピュータスカウトONのときは、日本人の新入生の枠がいっぱいなら交渉できない
                      // (断られた選手とも交渉できない。地区めぐりでは、今の地区の選手とだけ。1.9.6)
                      onPressed:
                          _ghensuu!.scoutChances > 0 &&
                              !kotowari &&
                              chikuOk &&
                              (!_comScoutOn || _kakuteiSuu < _waku)
                          ? () => _showConfirmationDialog(freshman)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // 地区めぐりで今の地区でない選手は「3地区目」「終了」(1.9.6。入りきらなければ縮める)
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          kousyouLabel,
                          style: const TextStyle(
                            fontSize: HENSUU.fontsize_honbun - 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBadge(String label, int value, bool isMyUniv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMyUniv
            ? Colors.amber.withOpacity(0.15)
            : Colors.blueAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isMyUniv
              ? Colors.amber.withOpacity(0.5)
              : Colors.blueAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isMyUniv ? Colors.amber[50] : Colors.white,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: isMyUniv ? Colors.amberAccent : Colors.cyanAccent,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 能力値を個別のバッジとして構築する（自校なら色をゴールドに）
  List<Widget> _buildAbilityBadges(
    SenshuData freshman, {
    required bool isMyUniv,
  }) {
    List<Widget> badges = [];

    final abilities = {
      SortCriterion.konjou: '駅伝男',
      SortCriterion.heijousin: '平常心',
      SortCriterion.choukyorinebari: '長距離粘り',
      SortCriterion.spurtryoku: 'スパート',
      SortCriterion.karisuma: 'カリスマ',
      SortCriterion.noboritekisei: '登り',
      SortCriterion.kudaritekisei: '下り',
      SortCriterion.noborikudarikirikaenouryoku: 'アップダウン',
      SortCriterion.tandokusou: 'ロード',
      SortCriterion.paceagesagetaiouryoku: 'ペース変動',
    };

    abilities.forEach((criterion, label) {
      int index = _getAbilityIndex(criterion);
      if (index != -1 && _ghensuu!.nouryokumieruflag[index] == 1) {
        int value = _getAbilityValue(freshman, criterion);
        if (value > 0) {
          badges.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // 自校ならゴールド系、他校ならブルー系のバッジ
                color: isMyUniv
                    ? Colors.amber.withOpacity(0.15)
                    : Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isMyUniv
                      ? Colors.amber.withOpacity(0.5)
                      : Colors.blueAccent.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isMyUniv ? Colors.amber[50] : Colors.white,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      color: isMyUniv ? Colors.amberAccent : Colors.cyanAccent,
                      fontSize: HENSUU.fontsize_honbun,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    if (freshman.anteikan > 0) {
      badges.add(_buildSingleBadge('安定感', freshman.anteikan, isMyUniv));
    }

    if (badges.isEmpty) {
      badges.add(
        Text(
          '特殊能力なし',
          style: TextStyle(
            color: isMyUniv ? Colors.amber.withOpacity(0.3) : Colors.white24,
            fontSize: 11,
          ),
        ),
      );
    }

    return badges;
  }

  /// 補助：freshmanから特定の能力値を取り出す（既存のロジックに合わせて実装してください）
  int _getAbilityValue(SenshuData s, SortCriterion c) {
    switch (c) {
      case SortCriterion.konjou:
        return s.konjou;
      case SortCriterion.heijousin:
        return s.heijousin;
      case SortCriterion.choukyorinebari:
        return s.choukyorinebari;
      case SortCriterion.spurtryoku:
        return s.spurtryoku;
      case SortCriterion.karisuma:
        return s.karisuma;
      case SortCriterion.noboritekisei:
        return s.noboritekisei;
      case SortCriterion.kudaritekisei:
        return s.kudaritekisei;
      case SortCriterion.noborikudarikirikaenouryoku:
        return s.noborikudarikirikaenouryoku;
      case SortCriterion.tandokusou:
        return s.tandokusou;
      case SortCriterion.paceagesagetaiouryoku:
        return s.paceagesagetaiouryoku;
      default:
        return 0;
    }
  }

  /// 画面下部に固定されるボタンエリア
  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // コンピュータスカウトONのときのお知らせ
            // コンピュータスカウトONのとき: 枠の表示と「説明」「ラウンドの結果」のリンクを1行に
            // (入りきらなければ部品ごとに次の行へ送る。文字は省略しない)
            if (_comScoutOn)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '枠 確定$_kakuteiSuu/$_waku'
                        '${_ryuugakuseiSuu > 0 ? '・留学生$_ryuugakuseiSuu' : ''}'
                        '${_kakuteiSuu >= _waku ? '(いっぱい)' : ''}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: HENSUU.fontsize_honbun - 2,
                        ),
                      ),
                      _footerLink('説明', _showSetsumeiDialog),
                      _footerLink(
                        'ラウンドの結果',
                        _roundKiroku.isEmpty ? null : () => _openRoundKekka(),
                      ),
                    ],
                  ),
                ),
              ),
            // 地区めぐりで地区が残っているときは、「見送る」と「スカウト終了」を横に並べる
            // (1.9.6。上下に並べると選手の一覧が狭くなるため。文字が大きいときはボタンの中で折り返す)
            // (高さはIntrinsicHeightで2つのボタンにそろえる。下の一覧の外なので、高さが決まっていないため)
            if (_chikuMeguri && _imaChiku != null)
              IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showMiokuriDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.blueAccent),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${comScoutChikuMei(_imaChiku!)}は見送る',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _scoutShuuryouButton(const Size(0, 50))),
                ],
                ),
              )
            else
              _scoutShuuryouButton(const Size(double.infinity, 50)),
          ],
        ),
      ),
    );
  }

  /// 「スカウト終了」のボタン([saishou] はボタンの最小の大きさ。地区めぐりでは見送りと横に並べる。1.9.6)
  Widget _scoutShuuryouButton(Size saishou) {
    return ElevatedButton(
      onPressed: _ghensuu!.scoutChances > 0
          ? () => _showExitConfirmationDialog()
          : () => _scoutShuuryou(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        minimumSize: saishou,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        "スカウト終了",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// フィルターボタンと並び替えボタンを生成するウィジェット
  Widget _buildFilterAndSortButtons() {
    bool isFilterActive =
        _abilityFilters.values.any((v) => v > 0) ||
        _timeFilterSeconds != TEISUU.DEFAULTTIME ||
        _successRateFilter > 0 ||
        _anteikanFilter > 0 ||
        (_koukouFilterAri && _koukouHyouji());
    final bool koukouHyouji = _koukouHyouji();

    return Column(
      children: [
        // フィルター設定ボタンと、高校名鑑のボタン(1.9.5。文字を大きくしていても並ぶように Wrap)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton.icon(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),
                label: Text(isFilterActive ? 'フィルター設定 (適用中)' : 'フィルター設定'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFilterActive ? Colors.red[800] : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              if (koukouHyouji)
                ElevatedButton.icon(
                  onPressed: _koukouMeikanHiraku,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('高校名鑑'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // 並び替えボタン
        _buildSortButtons(),
      ],
    );
  }

  /// 並び替えボタンを生成するウィジェット（_buildFilterAndSortButtonsから呼び出される）
  Widget _buildSortButtons() {
    final currentGhensuu = _ghensuu!;
    final List<Widget> sortButtons = [
      _buildSortButton('タイム', SortCriterion.time),
    ];

    if (currentGhensuu.nouryokumieruflag[0] == 1) {
      sortButtons.add(_buildSortButton('駅伝男', SortCriterion.konjou));
    }
    if (currentGhensuu.nouryokumieruflag[1] == 1) {
      sortButtons.add(_buildSortButton('平常心', SortCriterion.heijousin));
    }
    if (currentGhensuu.nouryokumieruflag[2] == 1) {
      sortButtons.add(_buildSortButton('粘り', SortCriterion.choukyorinebari));
    }
    if (currentGhensuu.nouryokumieruflag[3] == 1) {
      sortButtons.add(_buildSortButton('スパート', SortCriterion.spurtryoku));
    }
    if (currentGhensuu.nouryokumieruflag[4] == 1) {
      sortButtons.add(_buildSortButton('カリスマ', SortCriterion.karisuma));
    }
    if (currentGhensuu.nouryokumieruflag[5] == 1) {
      sortButtons.add(_buildSortButton('登り', SortCriterion.noboritekisei));
    }
    if (currentGhensuu.nouryokumieruflag[6] == 1) {
      sortButtons.add(_buildSortButton('下り', SortCriterion.kudaritekisei));
    }
    if (currentGhensuu.nouryokumieruflag[7] == 1) {
      sortButtons.add(
        _buildSortButton('アップダウン', SortCriterion.noborikudarikirikaenouryoku),
      );
    }
    if (currentGhensuu.nouryokumieruflag[8] == 1) {
      sortButtons.add(_buildSortButton('ロード', SortCriterion.tandokusou));
    }
    if (currentGhensuu.nouryokumieruflag[9] == 1) {
      sortButtons.add(
        _buildSortButton('ペース変動', SortCriterion.paceagesagetaiouryoku),
      );
    }
    // ★交渉成功確率のボタンを追加(地区めぐり(声かけ)は成功率がないので出さない。1.9.6)
    if (!_koekake) {
      sortButtons.add(_buildSortButton('成功率', SortCriterion.successRate));
    }
    sortButtons.add(_buildSortButton('安定感', SortCriterion.anteikan));
    sortButtons.add(_buildSortButton('大学ID', SortCriterion.univid));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sortButtons,
      ),
    );
  }

  /// 並び替えボタンを生成する共通メソッド
  Widget _buildSortButton(String text, SortCriterion criterion) {
    bool isSelected = _currentSortCriterion == criterion;
    IconData? icon;

    if (isSelected) {
      if (criterion == SortCriterion.time) {
        icon = _isTimeAscending ? Icons.arrow_upward : Icons.arrow_downward;
      } else {
        icon = _isAbilityDescending ? Icons.arrow_downward : Icons.arrow_upward;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (_currentSortCriterion == criterion) {
              if (criterion == SortCriterion.time) {
                _isTimeAscending = !_isTimeAscending;
              } else {
                _isAbilityDescending = !_isAbilityDescending;
              }
            } else {
              _currentSortCriterion = criterion;
              if (criterion == SortCriterion.time) {
                _isTimeAscending = true;
                _isAbilityDescending = true;
              } else {
                _isTimeAscending = true;
                _isAbilityDescending = true;
              }
            }
            _sortFreshmenLists();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            if (icon != null) const SizedBox(width: 4),
            if (icon != null) Icon(icon, size: 16),
          ],
        ),
      ),
    );
  }

  /// フィルター設定シートを表示する
  void _showFilterDialog() {
    final Map<SortCriterion, int> tempAbilityFilters = Map.from(
      _abilityFilters,
    );
    int tempTimeFilterSeconds = _timeFilterSeconds;
    int tempSuccessRateFilter = _successRateFilter;
    int tempanteikanFilter = _anteikanFilter;
    // 高校時代(直近の大会)のフィルター(1.9.5)
    final bool koukouHyouji = _koukouHyouji();
    String tempKoukouMei = _koukouMeiFilter;
    bool tempOkiniiri = _okiniiriFilter;
    // 監督の母校の出身だけ(2.0.1)
    final ({bool jibun, bool hoka}) bokouDasu = _bokouFilterDasu();
    bool tempBokouJibun = _bokouJibunFilter;
    bool tempBokouHoka = _bokouHokaFilter;
    int tempTeamJuni = _ekidenTeamJuniFilter;
    int tempKukanJuni = _ekidenKukanJuniFilter;
    final List<int> tempSoutaiJuni = List<int>.of(_soutaiJuniFilter);
    final TextEditingController koukouMeiController = TextEditingController(
      text: _koukouMeiFilter,
    );

    int currentMin = (_timeFilterSeconds == TEISUU.DEFAULTTIME)
        ? 0
        : (_timeFilterSeconds / 60).floor();
    int currentSec = (_timeFilterSeconds == TEISUU.DEFAULTTIME)
        ? 0
        : _timeFilterSeconds % 60;

    final TextEditingController minController = TextEditingController(
      text: currentMin > 0 ? currentMin.toString() : '',
    );
    final TextEditingController secController = TextEditingController(
      text: currentSec > 0 || currentMin > 0 ? currentSec.toString() : '',
    );

    // ボトムシートを表示
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 画面高さをフルに使えるようにする
      backgroundColor: Colors.transparent, // 背景を透明にして角丸を活かす
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateTime() {
              final int min = int.tryParse(minController.text) ?? 0;
              final int sec = int.tryParse(secController.text) ?? 0;
              setDialogState(() {
                tempTimeFilterSeconds = (min == 0 && sec == 0)
                    ? TEISUU.DEFAULTTIME.toInt()
                    : (min * 60) + sec;
              });
            }

            // 高校時代の「○位以内」の欄(1.9.5。空や0は条件なし)
            Widget juniGyou(String label, int atai, void Function(int) kaku) {
              return _buildInputRow(
                icon: Icons.emoji_events_outlined,
                label: label,
                child: _buildNumberField(
                  TextEditingController(text: atai > 0 ? atai.toString() : ''),
                  '位以内',
                  (v) => kaku(int.tryParse(v) ?? 0),
                  width: 80,
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85, // 画面の85%を使用
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7), // 清潔感のある薄グレー
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // ヘッダー部分（つまみバーとタイトル）
                  _buildSheetHeader(context),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom +
                            20, // キーボードを避ける
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('5000m持ちタイム'),
                          _buildCard([
                            _buildInputRow(
                              icon: Icons.timer_outlined,
                              label: 'タイム',
                              child: Row(
                                children: [
                                  _buildNumberField(
                                    minController,
                                    '分',
                                    (v) => updateTime(),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildNumberField(
                                    secController,
                                    '秒',
                                    (v) => updateTime(),
                                  ),
                                ],
                              ),
                            ),
                          ]),

                          _buildSectionLabel(
                            _koekake ? 'メンタル条件' : '交渉・メンタル条件',
                          ),
                          _buildCard([
                            // 地区めぐり(声かけ)は成功率がないので出さない(1.9.6)
                            if (!_koekake)
                            _buildInputRow(
                              icon: Icons.handshake_outlined,
                              label: '最低成功率',
                              child: _buildNumberField(
                                TextEditingController(
                                  text: tempSuccessRateFilter > 0
                                      ? tempSuccessRateFilter.toString()
                                      : '',
                                ),
                                '％',
                                (v) => tempSuccessRateFilter =
                                    int.tryParse(v) ?? 0,
                                width: 80,
                              ),
                            ),
                            if (!_koekake) const Divider(height: 1),
                            _buildInputRow(
                              icon: Icons.trending_up,
                              label: '最低安定感',
                              child: _buildNumberField(
                                TextEditingController(
                                  text: tempanteikanFilter > 0
                                      ? tempanteikanFilter.toString()
                                      : '',
                                ),
                                '',
                                (v) =>
                                    tempanteikanFilter = int.tryParse(v) ?? 0,
                                width: 80,
                              ),
                            ),
                          ]),

                          // 高校時代(直近の大会)(1.9.5。高校の情報を表示しない設定のときは出さない)
                          if (koukouHyouji) ...[
                            _buildSectionLabel('高校時代（直近の大会）'),
                            _buildCard([
                              _buildInputRow(
                                icon: Icons.school_outlined,
                                label: '高校名',
                                child: SizedBox(
                                  width: 150,
                                  height: 40,
                                  child: TextField(
                                    controller: koukouMeiController,
                                    textAlign: TextAlign.center,
                                    onChanged: (v) => tempKoukouMei = v,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '校名か都道府県',
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              // お気に入りの高校の出身だけ(1.9.5)
                              CheckboxListTile(
                                value: tempOkiniiri,
                                onChanged: (v) => setDialogState(() => tempOkiniiri = v ?? false),
                                title: const Text(
                                  'お気に入りの高校の出身だけ',
                                  style: TextStyle(fontSize: 15, color: Colors.black87),
                                ),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Colors.blueAccent,
                                side: const BorderSide(color: Colors.black54, width: 1.5),
                              ),
                              const Divider(height: 1),
                              // 監督の母校の出身だけ(2.0.1。両方にチェックすると、どちらかに当てはまる選手)
                              if (bokouDasu.jibun) ...[
                                CheckboxListTile(
                                  value: tempBokouJibun,
                                  onChanged: (v) => setDialogState(() => tempBokouJibun = v ?? false),
                                  title: const Text(
                                    'あなたの大学の監督の母校の出身だけ',
                                    style: TextStyle(fontSize: 15, color: Colors.black87),
                                  ),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: Colors.blueAccent,
                                  side: const BorderSide(color: Colors.black54, width: 1.5),
                                ),
                                const Divider(height: 1),
                              ],
                              if (bokouDasu.hoka) ...[
                                CheckboxListTile(
                                  value: tempBokouHoka,
                                  onChanged: (v) => setDialogState(() => tempBokouHoka = v ?? false),
                                  title: const Text(
                                    'ほかの大学の監督の母校の出身だけ',
                                    style: TextStyle(fontSize: 15, color: Colors.black87),
                                  ),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: Colors.blueAccent,
                                  side: const BorderSide(color: Colors.black54, width: 1.5),
                                ),
                                const Divider(height: 1),
                              ],
                              juniGyou(
                                '全国高校駅伝 高校の順位',
                                tempTeamJuni,
                                (v) => tempTeamJuni = v,
                              ),
                              const Divider(height: 1),
                              juniGyou(
                                '全国高校駅伝 区間順位',
                                tempKukanJuni,
                                (v) => tempKukanJuni = v,
                              ),
                              for (int sh = 0; sh < tempSoutaiJuni.length; sh++) ...[
                                const Divider(height: 1),
                                juniGyou(
                                  '高校総体 ${koukouShumokuMei[sh + 1]} 決勝',
                                  tempSoutaiJuni[sh],
                                  (v) => tempSoutaiJuni[sh] = v,
                                ),
                              ],
                            ]),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 6),
                              child: Text(
                                '高校名は、校名か都道府県の一部で絞ります。'
                                'お気に入りの高校は、高校名鑑の高校のページの☆で付けます。'
                                '順位は、今年の新入生が高校3年だった年度の大会のものです。'
                                '高校の順位は所属高校のチームの順位で、走っていない部員も入ります。'
                                '高校総体は決勝の順位(1〜15位)です。'
                                '高校の条件を入れると、留学生と、高校の情報がない選手は外れます。',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey[600],
                                ),
                              ),
                            ),
                          ],

                          _buildSectionLabel('特殊能力（最低値）'),
                          _buildCard(
                            _abilityLabels.entries.map((entry) {
                              final criterion = entry.key;
                              final label = entry.value;
                              int index = _getAbilityIndex(criterion);
                              if (index == -1 ||
                                  _ghensuu!.nouryokumieruflag[index] != 1)
                                return const SizedBox.shrink();

                              return Column(
                                children: [
                                  _buildInputRow(
                                    icon: Icons.star_outline,
                                    label: label,
                                    child: _buildNumberField(
                                      TextEditingController(
                                        text: tempAbilityFilters[criterion]! > 0
                                            ? tempAbilityFilters[criterion]
                                                  .toString()
                                            : '',
                                      ),
                                      '',
                                      (v) => tempAbilityFilters[criterion] =
                                          int.tryParse(v) ?? 0,
                                      width: 80,
                                    ),
                                  ),
                                  if (entry.key != _abilityLabels.keys.last)
                                    const Divider(height: 1),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 50), // 下部のボタンとの余白
                          // 下部アクションボタン
                          _buildBottomActions(
                            onReset: () {
                              setState(() {
                                _abilityFilters.updateAll((key, value) => 0);
                                _timeFilterSeconds = TEISUU.DEFAULTTIME.toInt();
                                _successRateFilter = 0;
                                _anteikanFilter = 0;
                                // 高校時代(1.9.5)
                                _okiniiriFilter = false;
                                _bokouJibunFilter = false; // 監督の母校(2.0.1)
                                _bokouHokaFilter = false;
                                _koukouMeiFilter = '';
                                _ekidenTeamJuniFilter = 0;
                                _ekidenKukanJuniFilter = 0;
                                _soutaiJuniFilter = [0, 0, 0];
                              });
                              Navigator.pop(context);
                            },
                            onApply: () {
                              setState(() {
                                _abilityFilters = Map.from(tempAbilityFilters);
                                _timeFilterSeconds = tempTimeFilterSeconds;
                                _successRateFilter = tempSuccessRateFilter;
                                _anteikanFilter = tempanteikanFilter;
                                // 高校時代(1.9.5)
                                _okiniiriFilter = tempOkiniiri;
                                _okiniiriKou = null;
                                // 監督の母校(2.0.1。チェックを出していないほうは外す)
                                _bokouJibunFilter = tempBokouJibun && bokouDasu.jibun;
                                _bokouHokaFilter = tempBokouHoka && bokouDasu.hoka;
                                _koukouMeiFilter = tempKoukouMei.trim();
                                _ekidenTeamJuniFilter = tempTeamJuni;
                                _ekidenKukanJuniFilter = tempKukanJuni;
                                _soutaiJuniFilter = List<int>.of(tempSoutaiJuni);
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 下部アクションボタン
                  /*_buildBottomActions(
                    onReset: () {
                      setState(() {
                        _abilityFilters.updateAll((key, value) => 0);
                        _timeFilterSeconds = TEISUU.DEFAULTTIME.toInt();
                        _successRateFilter = 0;
                        _anteikanFilter = 0;
                      });
                      Navigator.pop(context);
                    },
                    onApply: () {
                      setState(() {
                        _abilityFilters = Map.from(tempAbilityFilters);
                        _timeFilterSeconds = tempTimeFilterSeconds;
                        _successRateFilter = tempSuccessRateFilter;
                        _anteikanFilter = tempanteikanFilter;
                      });
                      Navigator.pop(context);
                    },
                  ),*/
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 部品化されたUIコンポーネント ---

  Widget _buildSheetHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            '絞り込みフィルター',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[700],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String hint,
    Function(String) onChanged, {
    double width = 60,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions({
    required VoidCallback onReset,
    required VoidCallback onApply,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onReset,
              child: const Text(
                'リセット',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '条件を適用する',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(SenshuData freshman) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _koekake ? '声かけの確認' : '交渉確認',
            style: const TextStyle(color: Colors.black),
          ),
          content: Text(
            _koekake
                ? '本当に${freshman.name}選手に声をかけますか？\n'
                      '(ほかの大学も声をかけたら争奪戦になり、名声の高い大学ほど選ばれやすくなります)'
                : '本当に${freshman.name}選手と交渉しますか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _negotiate(freshman);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // 注: ここでは _isLoading は使用しないため、StatefulBuilder も不要です。
        return AlertDialog(
          title: const Text(
            'イベント終了の確認',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            _chikuMeguri
                ? '本当にイベントを終了しますか？\n\n残りの地区は、コンピュータの大学だけで行います。そのあと、確定しなかった選手が自ら志望して進学先を選びます。'
                : _comScoutOn
                ? '本当にイベントを終了しますか？\n\n残りのラウンドは、コンピュータの大学だけで行います。そのあと、確定しなかった選手が自ら志望して進学先を選びます。'
                : '本当にイベントを終了しますか？',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              // ボタンの無効化ロジック（_isLoading関連）を削除し、常に有効にする
              onPressed: () async {
                // async関数として定義

                // ここでダイアログを閉じる（重要）
                // この pop() が実行されるまで、次の行には進まない。
                Navigator.of(context).pop();

                // 放出の画面か次の処理へ(コンピュータスカウトONなら、残りのラウンドと最後の志望を先に済ませる)
                await _scoutShuuryou();
              },
              child: const Text('OK'), // ローディング表示のロジックを削除
            ),
          ],
        );
      },
    );
  }

  /// 判定用：能力の列挙型からインデックス番号を取得する
  int _getAbilityIndex(SortCriterion criterion) {
    switch (criterion) {
      case SortCriterion.konjou:
        return 0;
      case SortCriterion.heijousin:
        return 1;
      case SortCriterion.choukyorinebari:
        return 2;
      case SortCriterion.spurtryoku:
        return 3;
      case SortCriterion.karisuma:
        return 4;
      case SortCriterion.noboritekisei:
        return 5;
      case SortCriterion.kudaritekisei:
        return 6;
      case SortCriterion.noborikudarikirikaenouryoku:
        return 7;
      case SortCriterion.tandokusou:
        return 8;
      case SortCriterion.paceagesagetaiouryoku:
        return 9;
      default:
        return -1;
    }
  }
}
