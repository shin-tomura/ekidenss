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
import 'package:ekiden/kansuu/koukou.dart'; // 出身校と高校時代の実績(1.9.5)
import 'package:ekiden/screens/Modal_koukouMeikan.dart'; // 高校の大会の結果(1.9.5)
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
    final Map<int, double> seikouritsu = comScoutSeikouritsuIchiran(
      univid: myUnivId,
      nen: _ghensuu!.year, // 変わり者を決めるのに使う(1.9.0)
    );
    for (final SenshuData s in _targetFreshmen) {
      if (comScoutKettei(s)) continue;
      if (comScoutKotowarareta(s)) continue;
      final double r = seikouritsu[s.id] ?? 0.001;
      // 0.1%単位で入れる(1%未満も0.1%単位。1.8.8。scout_com.dart)
      s.kegaflag = scoutSeikouritsuKegaflag(r);
      await s.save();
    }

    _sortFreshmenLists();

    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  /// 高校の情報を出すか(1.9.5。表示しない設定のときは、高校時代のフィルターと大会の結果のボタンを出さない)
  bool _koukouHyouji() {
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    return kantoku != null && !koukouHyoujiNashi(kantoku);
  }

  /// 高校時代(直近の大会)のフィルターが入っているか(1.9.5)
  bool get _koukouFilterAri =>
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

  /// 今年の新入生(スカウトの候補)が高校3年だったときの大会の結果を開く(1.9.5。Modal_koukouMeikan.dart)
  /// 進学先はカードと同じ出し方にする(コンピュータスカウトONのときは、仮の振り分けの大学を見せず、
  /// 「進路未定」「○○大学に確定」などにする。自分の大学の色も、進学先が決まった選手だけ)
  void _koukouKekkaHiraku() {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KoukouScoutKekka(
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
        ),
      ),
    );
  }

  String _jyoutaiMoji(SenshuData s) {
    if (comScoutKotowarareta(s)) return '進路未定(あなたの大学は断った)';
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
  Future<void> _openRoundKekka({int? hajimeRound}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScoutRoundKekkaScreen(
          kiroku: _roundKiroku,
          myUnivid: _ghensuu!.MYunivid,
          hajimeRound: hajimeRound,
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

  /// コンピュータスカウトONのときの説明
  void _showSetsumeiDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'コンピュータスカウトON',
            style: TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Text(
              'コンピュータスカウトONは、コンピュータの大学との真剣勝負です。名声の低い大学ほど成功率は低くなります'
              '(大学画面の「コンピュータスカウト」でOFFにすると、今まで通りのスカウトになります)。\n\n'
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
              '(大学画面の「新入生の進学先(全大学)」からも、翌年のスカウトまで見られます)。',
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
        _loadingMessage = nokori > 0 ? '残りのラウンドを判定中...' : '進学先を決めています...';
      });
      final List<String> bun = [];
      try {
        // 処理前スナップショット(途中で終了しても処理前の状態に戻せるように)
        await ShoriGuard.begin('新入生スカウト');
        // 残りのラウンドはコンピュータの大学だけで行う(全大学の動きは「全大学の動きを見る」から)
        final List<MapEntry<int, List<ComScoutKoudou>>> nokoriKiroku = [];
        for (int i = 0; i < nokori; i++) {
          final List<ComScoutKoudou> koudou = [];
          await comScoutRound(
            gh: _ghensuu!,
            roundBangou: hajime + i,
            koudou: koudou,
          );
          nokoriKiroku.add(MapEntry(hajime + i, koudou));
        }
        _ghensuu!.scoutChances = 0;
        await _ghensuu!.save();
        // 確定しなかった選手が、自ら志望して進学先を選ぶ
        final Map<int, int> shigan = await comScoutShigan(gh: _ghensuu!);
        bun.addAll(
          comScoutNyuugakuBun(myUnivid: _ghensuu!.MYunivid, shigan: shigan),
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

    final List<SenshuData> filteredTargetFreshmen = _targetFreshmen
        .where(_meetsFilterCriteria)
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
                'チャンス: ${_ghensuu!.scoutChances}回',
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
    final bool kotowari = _comScoutOn && comScoutKotowarareta(freshman);
    if (kotowari) rateStr = '断られた';
    // 出身校と高校時代の実績(1.9.5)
    final String koukouMoji = _koukouMoji(freshman);

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
                          kettei || kotowari ? '状態' : '成功率',
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
                      // (断られた選手とも交渉できない)
                      onPressed:
                          _ghensuu!.scoutChances > 0 &&
                              !kotowari &&
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
                      child: const Text(
                        '交渉',
                        style: TextStyle(
                          fontSize: HENSUU.fontsize_honbun - 2,
                          fontWeight: FontWeight.bold,
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
            ElevatedButton(
              onPressed: _ghensuu!.scoutChances > 0
                  ? () => _showExitConfirmationDialog()
                  : () => _scoutShuuryou(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "スカウト終了",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
        // フィルター設定ボタンと、高校の大会の結果のボタン(1.9.5。文字を大きくしていても並ぶように Wrap)
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
                  onPressed: _koukouKekkaHiraku,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('高校の大会の結果'),
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
    // ★交渉成功確率のボタンを追加
    sortButtons.add(_buildSortButton('成功率', SortCriterion.successRate));
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

                          _buildSectionLabel('交渉・メンタル条件'),
                          _buildCard([
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
                            const Divider(height: 1),
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
          title: const Text('交渉確認', style: TextStyle(color: Colors.black)),
          content: Text(
            '本当に${freshman.name}選手と交渉しますか？',
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
            _comScoutOn
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
