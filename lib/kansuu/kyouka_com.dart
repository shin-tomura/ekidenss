import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart'; // 能力のタイムへの影響度
import 'package:hive_flutter/hive_flutter.dart';

// ------------------------------------------------------------
// コンピュータの大学の年間強化練習のメニュー決め(4月15日。1.9.1で決め方を変えた)
//
// 1.9.0までは、選手の能力の得意不得意だけで、決まった人数(下り・アップダウン・登り2人ずつ、
// スピード最大4人、距離走最大8人、残りはバランス)にしていた。
// 1.9.1からは、その大学が今年走る駅伝・駅伝予選のコースと、大会の大きさ(名声)を見て決める。
//
// ・大会の重み: 1位の名声(10月駅伝500・11月駅伝500・正月駅伝2000)×「駅伝名声設定」の倍率。
//   カスタム駅伝は、開催するときに、正月駅伝の量×カスタム駅伝の獲得名声倍率。
//   出場権(4月5日に前年度の順位で決まる taikaientryflag)がない駅伝は、
//   予選に出る大学なら予選の重みを本戦と同じにし、本戦は半分にする(予選に通れば走るため)
// ・区間ごとに、能力が1上がったときに縮まるタイムを、レースの計算(RaceCalc.dart)と同じ式で出し、
//   メニューごとの上乗せ(強度4のときの量)を掛けて、その区間で一番得なメニューを決める
//   (能力の効き方は式の上で選手の能力の値によらないので、区間ごとに決まる)。
//   能力のタイムへの影響度の設定も掛ける
// ・区間ごとの一番得なメニューを、大会の重み(一番重い大会を1)×その区間を走る人数で足して、
//   メニューごとの必要度にする(駅伝は1区間1人、11月駅伝予選は1組2人、正月駅伝予選は12人)
// ・走りそうな選手(基本走力の上位。人数は一番多く走る大会の人数+4)に割り当てる
//   登り・下り・アップダウン: 必要度が0なら0人、1未満なら1人、それ以上は「切り捨て+1人」(控え1人分)。
//     必要度の大きいメニューから、その適性の高い選手に割り当てる(4人まで)
//   残りの選手: スピード・距離走・バランスの必要度の割合で人数を分け、
//     (長距離粘り+ロード適性)−(スパート力+ペース変動対応力)の大きい順に距離走、小さい順にスピード、
//     間の選手をバランスにする
// ・走りそうにない選手(控え): 得意を伸ばす方向(スパート力+ペース変動対応力が長距離粘り+ロード適性より
//   高ければスピード、低ければ距離走、同じならバランス)。
//   夏合宿の銀を「個人の練習メニュー通り」に使う大学では、この選手たちの銀の使い道にもなる
// ・大学ごとのスカウト方針や銀の使い道(大学方針)は、メニュー決めには使わない
// ・保存する値はない(その場で計算する)
// ------------------------------------------------------------

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  //final int milliseconds = ((time % 1) * 100)
  //    .toInt(); // 秒以下の部分をミリ秒として扱う (小数点2桁まで)
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

// メニューの番号(SenshuData.kaifukuryoku。TrainingMenu と同じ)
const int _balance = 0;
const int _speed = 1;
const int _kyorisou = 2;
const int _nobori = 3;
const int _kudari = 4;
const int _updown = 5;

/// メニューの名前(デバッグログ用)
const List<String> _menuMei = ['バランス', 'スピード', '距離走', '登り', '下り', 'アップダウン'];

/// メニューを決めるときに使う強化練習の強度(上乗せの割合だけが大事なので、初期値の4で計算する)
const int _kyoudoKijun = 4;

/// 1区間(1組)を走る、1大学の人数
int _hashiruNinzuu(int racebangou) {
  if (racebangou == 3) return 2; // 11月駅伝予選は1組2人
  if (racebangou == 4) return 12; // 正月駅伝予選は12人
  return 1;
}

/// 「駅伝名声設定」の倍率(分子と分母は1〜10。範囲外は1。KirokuKousin.dart と同じ読み方)
double _meiseiBairitu(Map<int, UnivData> univ, int bunsiId, int bunboId) {
  int yomu(int id) {
    final int? v = int.tryParse(univ[id]?.name_tanshuku ?? '');
    return (v == null || v < 1 || v > 10) ? 1 : v;
  }

  return yomu(bunsiId).toDouble() / yomu(bunboId).toDouble();
}

/// 大会ごと(大会番号0〜5)の、1位の名声にもとづく基本の重み(出場するかは見ない)
List<double> _kihonOmomi(Ghensuu gh, Map<int, UnivData> univ) {
  final double b10 = _meiseiBairitu(univ, 1, 2);
  final double b11 = _meiseiBairitu(univ, 3, 4);
  final double b01 = _meiseiBairitu(univ, 5, 6);
  final List<double> omomi = List.filled(6, 0.0);
  omomi[0] = 500.0 * b10;
  omomi[1] = 500.0 * b11;
  omomi[2] = 2000.0 * b01;
  // カスタム駅伝(開催する設定のときだけ。shiyou_text.dart の獲得名声の一覧と同じ条件)
  if (gh.spurtryokuseichousisuu1 == 1 && gh.spurtryokuseichousisuu5 >= 1) {
    omomi[5] =
        2000.0 *
        b01 *
        gh.spurtryokuseichousisuu4.toDouble() /
        gh.spurtryokuseichousisuu5.toDouble();
  }
  return omomi;
}

/// その大学にとっての大会ごとの重み(出場権がない本戦は半分、予選は本戦と同じ重み)
List<double> _daigakuOmomi(UnivData u, List<double> kihon) {
  bool de(int r) => u.taikaientryflag.length > r && u.taikaientryflag[r] == 1;
  final List<double> w = List.filled(6, 0.0);
  if (de(0)) w[0] = kihon[0];
  if (de(1)) {
    w[1] = kihon[1];
  } else if (de(3)) {
    w[1] = kihon[1] * 0.5;
    w[3] = kihon[1];
  }
  if (de(2)) {
    w[2] = kihon[2];
  } else if (de(4)) {
    w[2] = kihon[2] * 0.5;
    w[4] = kihon[2];
  }
  if (de(5)) w[5] = kihon[5];
  return w;
}

/// 区間で、能力が1上がったときに縮まるタイム(秒)。RaceCalc.dart と同じ式から出す
/// 並びは [長距離粘り, スパート力, 登り適性, 下り適性, アップダウン対応力, ロード適性, ペース変動対応力]
List<double> _ichiAtariGain(Ghensuu gh, int r, int k, NouryokuEikyodo e) {
  double atai(List<List<double>> list) =>
      (r < list.length && k < list[r].length) ? list[r][k] : 0.0;
  final double kyori = atai(gh.kyori_taikai_kukangoto);
  // 区間のタイムの目安(1kmおよそ3分)
  final double t = kyori * 0.18;
  // 長距離粘り(15kmを超える分だけ)
  final double nebari = kyori > 15000.0
      ? (kyori - 14999.999) /
            100.0 *
            (TEISUU.MAXTIMEHOSEI_CHOUKYORINEBARI_PER100m / 98.0) *
            e.nebari
      : 0.0;
  // スパート力(距離によらない)
  final double spurt =
      8.0 * (-TEISUU.MAXTIMEHOSEI_SPURTRYOKU_PER100m / 98.0) * e.spurt;
  // 登り・下り(坂の割合×勾配)
  final double hNobori =
      atai(gh.kyoriwariainobori_taikai_kukangoto) *
      atai(gh.heikinkoubainobori_taikai_kukangoto) /
      0.01;
  final double nobori = hNobori > 0.0
      ? t * 0.00017 * TEISUU.CHOUSEI_NOBORI * hNobori * e.nobori
      : 0.0;
  final double hKudari =
      -atai(gh.kyoriwariaikudari_taikai_kukangoto) *
      atai(gh.heikinkoubaikudari_taikai_kukangoto) /
      0.01;
  final double kudari = hKudari > 0.0
      ? t * 0.00018 * TEISUU.CHOUSEI_KUDARI * hKudari * e.kudari
      : 0.0;
  // アップダウン(登り下りの切り替えの回数)
  final List<List<int>> kirikaeList =
      gh.noborikudarikirikaekaisuu_taikai_kukangoto;
  final int kirikae = (r < kirikaeList.length && k < kirikaeList[r].length)
      ? kirikaeList[r][k]
      : 0;
  final double updown = t * TEISUU.CHOUSEI_KIRIKAE * kirikae * e.updown;
  // ロード適性・ペース変動対応力(効く区間と割合はRaceCalc.dartと同じ)
  double roadWariai = 1.0;
  double paceWariai = 0.0;
  if ((r != 4 && k == 0) || r == 3) {
    roadWariai = 0.0;
    paceWariai = 1.0;
  } else if (r == 4 || (k >= 1 && k <= 2)) {
    roadWariai = 0.5;
    paceWariai = 0.5;
  }
  final double road = t * 0.0003 * roadWariai * e.road;
  final double pace = t * 0.0003 * paceWariai * e.pace;
  return [nebari, spurt, nobori, kudari, updown, road, pace];
}

/// メニューごとの上乗せ(RaceCalc.dart と同じ量)。並びは _ichiAtariGain と同じ
List<int> _uwanose(int menu, int kyoudo) {
  final List<int> u = List.filled(7, 0);
  switch (menu) {
    case _balance:
      for (int i = 0; i < 7; i++) {
        u[i] = kyoudo;
      }
      break;
    case _speed:
      u[1] = kyoudo * 7 ~/ 2;
      u[6] = kyoudo * 7 ~/ 2;
      break;
    case _kyorisou:
      u[0] = kyoudo * 4 ~/ 2;
      u[5] = kyoudo * 4 ~/ 2;
      break;
    case _nobori:
      u[2] = kyoudo * 7;
      break;
    case _kudari:
      u[3] = kyoudo * 7;
      break;
    case _updown:
      u[4] = kyoudo * 7;
      break;
  }
  return u;
}

/// 区間で一番得なメニュー(同じならバランスを優先)
int _ichibanTokunaMenu(List<double> gain) {
  int best = _balance;
  double bestAtai = -1.0;
  for (int menu = _balance; menu <= _updown; menu++) {
    final List<int> u = _uwanose(menu, _kyoudoKijun);
    double atai = 0.0;
    for (int i = 0; i < 7; i++) {
      atai += u[i] * gain[i];
    }
    if (atai > bestAtai + 0.000001) {
      best = menu;
      bestAtai = atai;
    }
  }
  return best;
}

/// (長距離粘り+ロード適性)−(スパート力+ペース変動対応力)。大きいほど距離走向き
int _kyoriMuki(SenshuData s) =>
    (s.choukyorinebari + s.tandokusou) - (s.spurtryoku + s.paceagesagetaiouryoku);

/// 登り・下り・アップダウンのメニューの適性
int _tekisei(SenshuData s, int menu) {
  switch (menu) {
    case _nobori:
      return s.noboritekisei;
    case _kudari:
      return s.kudaritekisei;
    case _updown:
      return s.noborikudarikirikaenouryoku;
    default:
      return 0;
  }
}

/// 控えの選手のメニュー(得意を伸ばす方向)
int _hikaeMenu(SenshuData s) {
  final int muki = _kyoriMuki(s);
  if (muki > 0) return _kyorisou;
  if (muki < 0) return _speed;
  return _balance;
}

// DartではFutureを返す非同期関数として定義
Future<void> Kyouka_com({
  //required int racebangou,
  required List<Ghensuu> gh,
  //required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  final startTime = DateTime.now();
  print("Kyouka_comに入った");

  final Map<int, UnivData> univ = {
    for (final UnivData u in Hive.box<UnivData>('univBox').values) u.id: u,
  };
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  final NouryokuEikyodo eikyodo = kantoku != null
      ? NouryokuEikyodo.fromKantoku(kantoku)
      : const NouryokuEikyodo();
  final List<double> kihon = _kihonOmomi(gh[0], univ);

  // 区間ごとの一番得なメニュー(大学によらないので先に出しておく)
  final List<List<int>> kukanMenu = [
    for (int r = 0; r < 6; r++)
      [
        for (
          int k = 0;
          r < gh[0].kukansuu_taikaigoto.length &&
              k < gh[0].kukansuu_taikaigoto[r];
          k++
        )
          _ichibanTokunaMenu(_ichiAtariGain(gh[0], r, k, eikyodo)),
      ],
  ];
  if (kDebugMode) {
    for (int r = 0; r < 6; r++) {
      print(
        '[COM強化] 大会$r 区間ごとの一番得なメニュー: '
        '${kukanMenu[r].map((m) => _menuMei[m]).join('・')}',
      );
    }
  }

  for (int targetunivid = 0; targetunivid < TEISUU.UNIVSUU; targetunivid++) {
    if (targetunivid != gh[0].MYunivid) {
      final List<SenshuData> univFilteredSenshuData = sortedSenshuData
          .where((s) => s.univid == targetunivid)
          .toList();
      if (univFilteredSenshuData.isEmpty) continue;
      for (var senshu in univFilteredSenshuData) {
        senshu.kaifukuryoku = _balance;
      }

      // 大会ごとの重み(一番重い大会を1にする)
      final UnivData? u = univ[targetunivid];
      final List<double> w = u != null
          ? _daigakuOmomi(u, kihon)
          : List.filled(6, 0.0);
      double wMax = 0.0;
      for (final double x in w) {
        if (x > wMax) wMax = x;
      }

      // メニューごとの必要度と、一番多く走る大会の人数
      final List<double> hitsuyoudo = List.filled(6, 0.0);
      int saidaiNinzuu = 0;
      if (wMax > 0.0) {
        for (int r = 0; r < 6; r++) {
          if (w[r] <= 0.0) continue;
          final int hito = _hashiruNinzuu(r);
          final int ninzuu = r == 3
              ? kukanMenu[r].length * hito
              : (r == 4 ? hito : kukanMenu[r].length);
          if (ninzuu > saidaiNinzuu) saidaiNinzuu = ninzuu;
          for (final int menu in kukanMenu[r]) {
            hitsuyoudo[menu] += w[r] / wMax * hito;
          }
        }
      }

      // 走りそうな選手(基本走力の上位。aは小さいほど良い)と控え
      final List<SenshuData> narabi = univFilteredSenshuData.toList()
        ..sort((x, y) {
          final int c = x.a.compareTo(y.a);
          return c != 0 ? c : x.id.compareTo(y.id);
        });
      int poolSuu = saidaiNinzuu + 4;
      if (poolSuu > narabi.length) poolSuu = narabi.length;
      final List<SenshuData> pool = narabi.take(poolSuu).toList();
      final List<SenshuData> hikae = narabi.skip(poolSuu).toList();

      // 登り・下り・アップダウン(必要度の大きいメニューから、適性の高い選手に)
      final Set<SenshuData> kimeta = {};
      final List<int> senmon = [_nobori, _kudari, _updown]
        ..sort((x, y) => hitsuyoudo[y].compareTo(hitsuyoudo[x]));
      final Map<int, int> senmonNinzuu = {};
      for (final int menu in senmon) {
        final double d = hitsuyoudo[menu];
        int ninzuu = d <= 0.0 ? 0 : (d < 1.0 ? 1 : d.floor() + 1);
        if (ninzuu > 4) ninzuu = 4;
        senmonNinzuu[menu] = ninzuu;
        final List<SenshuData> kouho =
            pool.where((s) => !kimeta.contains(s)).toList()..sort((x, y) {
              final int c = _tekisei(y, menu).compareTo(_tekisei(x, menu));
              if (c != 0) return c;
              final int ca = x.a.compareTo(y.a);
              return ca != 0 ? ca : x.id.compareTo(y.id);
            });
        for (final SenshuData s in kouho.take(ninzuu)) {
          s.kaifukuryoku = menu;
          kimeta.add(s);
        }
      }

      // 残りの選手を、スピード・距離走・バランスの必要度の割合で分ける
      final List<SenshuData> nokori =
          pool.where((s) => !kimeta.contains(s)).toList()..sort((x, y) {
            final int c = _kyoriMuki(y).compareTo(_kyoriMuki(x));
            if (c != 0) return c;
            final int ca = x.a.compareTo(y.a);
            return ca != 0 ? ca : x.id.compareTo(y.id);
          });
      final double goukei =
          hitsuyoudo[_speed] + hitsuyoudo[_kyorisou] + hitsuyoudo[_balance];
      int kyoriNinzuu = 0;
      int speedNinzuu = 0;
      if (goukei > 0.0) {
        kyoriNinzuu = (nokori.length * hitsuyoudo[_kyorisou] / goukei).round();
        speedNinzuu = (nokori.length * hitsuyoudo[_speed] / goukei).round();
        if (kyoriNinzuu > nokori.length) kyoriNinzuu = nokori.length;
        if (speedNinzuu > nokori.length - kyoriNinzuu) {
          speedNinzuu = nokori.length - kyoriNinzuu;
        }
      }
      for (int i = 0; i < nokori.length; i++) {
        if (i < kyoriNinzuu) {
          nokori[i].kaifukuryoku = _kyorisou;
        } else if (i >= nokori.length - speedNinzuu) {
          nokori[i].kaifukuryoku = _speed;
        } else {
          nokori[i].kaifukuryoku = _balance;
        }
      }

      // 控えの選手は得意を伸ばす方向
      for (final SenshuData s in hikae) {
        s.kaifukuryoku = _hikaeMenu(s);
      }

      if (kDebugMode) {
        final List<int> kazu = List.filled(6, 0);
        for (final SenshuData s in pool) {
          if (s.kaifukuryoku >= 0 && s.kaifukuryoku < 6) {
            kazu[s.kaifukuryoku]++;
          }
        }
        print(
          '[COM強化] ${u?.name ?? targetunivid} 重み:'
          '${[for (final double x in w) x.toStringAsFixed(0)].join('/')} '
          '必要度:${[for (int m = 0; m < 6; m++) '${_menuMei[m]}${hitsuyoudo[m].toStringAsFixed(1)}'].join(' ')} '
          '走りそうな選手$poolSuu人:'
          '${[for (int m = 0; m < 6; m++) if (kazu[m] > 0) '${_menuMei[m]}${kazu[m]}'].join(' ')}'
          '(専門の人数 ${senmon.map((m) => '${_menuMei[m]}${senmonNinzuu[m]}').join(' ')})',
        );
      }

      //
      for (var senshu in univFilteredSenshuData) {
        await senshu.save();
      }
    }
  }

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("Kyouka_com終了 処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}
