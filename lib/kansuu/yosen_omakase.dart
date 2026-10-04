// ------------------------------------------------------------
// 正月駅伝予選の「おまかせで組む」(1.8.8)
//
// 正月駅伝予選のレース画面で、自分の大学の選手の指示(フリー走・前半突っ込み・前半抑え・集団走A〜F)と
// 集団ごとの設定タイムを、まとめて入れる。入れたあとにプレイヤーが直してから、今まで通り確定する。
//
// 計算(RaceCalc.dartの正月駅伝予選)の決まり(ハーフ約63分で、1%≒38秒)
// ・集団走のペースの効果(本来のタイムと設定タイムの差): 設定タイムより速い選手は差の1/4の損、
//   0〜1%遅い選手は差の1/4の得、1〜3%遅い選手は損得なし、3%以上遅い選手は2.5%の大失速
// ・集団の落ち着き: 集団で一番高い平常心の確率で、集団の全員が0.2%速くなる
// ・フリー走の前半突っ込み: 駅伝男の確率で0.8%得、失敗すると1.4%損
// ・フリー走の前半抑え: 平常心の確率で0.2%得、失敗すると0.3%損
// ・画面の試走タイムには±0.5%の誤差がある(予選には調子と経験補正はない)
//
// 組み方
// 1. 駅伝男が90以上の選手は、フリー走の前半突っ込み(失敗の損が大きいので、成功しやすい選手だけ)
// 2. 残りを試走タイム順に並べ、速い選手から集団を作る
//    (集団の一番速い選手との差が試走タイムの0.8%以内。試走タイムの誤差を見込んで、得になる1%より内側)
//    集団は最大6つ、1集団は2人以上
// 3. 1人だけ余った選手は、その選手より速い集団の一番速い選手との差が2%以内なら、その集団に入れる
//    (ペースの得はないが損もなく、落ち着きの効果を受けられる。誤差を見込んで、大失速の3%より内側)。
//    入れられない選手どうしも、2%以内なら2人以上で集団にする(集団の数が残っているとき)
// 4. 平常心の高い選手を集団に散らす(隣り合う集団の境目の選手を入れ替えても、両方の集団が
//    2と3の差の条件を満たすときだけ。落ち着きの効果の合計(人数×一番高い平常心)が増えるときだけ)
// 5. 集団に入れなかった選手はフリー走。平常心が90以上なら前半抑え(失敗しても損が小さい)
// 6. 設定タイムは、集団で一番速い選手の試走タイム(小数まで)以上で一番近い5秒刻みの値
//    (それより速いと確定のときに弾かれる)。選べる55分00秒〜90分55秒に収まらない集団は作らない
// ------------------------------------------------------------

/// おまかせで組む選手1人分
class YosenOmakaseSenshu {
  /// 呼び出す側で選手を区別する番号(レース画面では、指示の欄の番号)
  final int bangou;

  /// 試走タイム(秒。画面に出している値)
  final double sisou;

  /// 駅伝男
  final int konjou;

  /// 平常心
  final int heijousin;

  const YosenOmakaseSenshu({
    required this.bangou,
    required this.sisou,
    required this.konjou,
    required this.heijousin,
  });
}

/// おまかせで組んだ結果
class YosenOmakaseKekka {
  /// 選手ごとの指示(0フリー走・1前半突っ込み・2前半抑え・3〜8集団走A〜F)。キーは[YosenOmakaseSenshu.bangou]
  final Map<int, int> sentaku;

  /// 集団A〜Fの設定タイム(秒。5秒刻み)。使わない集団はnull
  final List<int?> setteiByou;

  const YosenOmakaseKekka(this.sentaku, this.setteiByou);
}

/// 正月駅伝予選の指示の番号(レース画面の選択肢の並び)
const int _free = 0;
const int _tsukkomi = 1;
const int _osae = 2;
const int _shuudanA = 3;

/// 集団の数の上限
const int _shuudanSuuMax = 6;

/// 前半突っ込み・前半抑えにする駅伝男・平常心の下限
const int _sijiKijun = 90;

/// 集団の幅(一番速い選手との差。試走タイムに対する割合)
const double _haba = 0.008;

/// 1人余った選手を集団に入れるときの幅
const double _tsuikaHaba = 0.02;

/// 設定タイムに選べる範囲(秒。55分00秒〜90分55秒、5秒刻み)
const int _setteiMin = 55 * 60;
const int _setteiMax = 90 * 60 + 55;
const int _setteiKizami = 5;

class _Member {
  final YosenOmakaseSenshu s;

  /// 1人余って2%の幅で入れた選手か
  final bool tsuika;
  const _Member(this.s, this.tsuika);
}

class _Shuudan {
  final List<_Member> members;
  _Shuudan(this.members);

  double get hayai =>
      members.map((m) => m.s.sisou).reduce((a, b) => a < b ? a : b);

  int get maxHeijousin =>
      members.map((m) => m.s.heijousin).reduce((a, b) => a > b ? a : b);

  /// 全員が、一番速い選手との差の条件(2%で入れた選手は2%、ほかは0.8%)を満たすか
  bool get tadashii {
    if (members.length < 2) return false;
    final double h = hayai;
    for (final _Member m in members) {
      final double haba = m.tsuika ? _tsuikaHaba : _haba;
      if (m.s.sisou > h * (1.0 + haba)) return false;
    }
    return true;
  }
}

/// 集団の落ち着きの効果の大きさ(人数×一番高い平常心)の合計
int _ochitsukiGoukei(List<_Shuudan> shuudan) {
  int goukei = 0;
  for (final _Shuudan g in shuudan) {
    goukei += g.members.length * g.maxHeijousin;
  }
  return goukei;
}

/// 設定タイム(秒)。[hayai]以上で一番近い5秒刻みの値。選べる範囲に収まらなければnull
int? _setteiTime(double hayai) {
  final int t = (hayai / _setteiKizami).ceil() * _setteiKizami;
  if (t < _setteiMin || t > _setteiMax) return null;
  return t;
}

/// おまかせで組む
YosenOmakaseKekka yosenOmakase(List<YosenOmakaseSenshu> senshu) {
  final Map<int, int> sentaku = {};

  // 1. 駅伝男が90以上の選手は前半突っ込み
  final List<YosenOmakaseSenshu> nokori = [];
  for (final YosenOmakaseSenshu s in senshu) {
    if (s.konjou >= _sijiKijun) {
      sentaku[s.bangou] = _tsukkomi;
    } else {
      nokori.add(s);
    }
  }
  nokori.sort((a, b) {
    final int c = a.sisou.compareTo(b.sisou);
    return c != 0 ? c : a.bangou.compareTo(b.bangou);
  });

  // 2. 速い選手から、0.8%の幅で集団を作る
  final List<_Shuudan> shuudan = [];
  final List<YosenOmakaseSenshu> hitori = [];
  int i = 0;
  while (i < nokori.length) {
    final double hayai = nokori[i].sisou;
    int j = i + 1;
    while (j < nokori.length && nokori[j].sisou <= hayai * (1.0 + _haba)) {
      j++;
    }
    final List<YosenOmakaseSenshu> kumi = nokori.sublist(i, j);
    if (kumi.length >= 2 &&
        shuudan.length < _shuudanSuuMax &&
        _setteiTime(hayai) != null) {
      shuudan.add(_Shuudan([for (final s in kumi) _Member(s, false)]));
    } else {
      hitori.addAll(kumi);
    }
    i = j;
  }

  // 3. 1人余った選手は、その選手より速い集団のうち一番近い集団に、2%以内なら入れる
  final List<YosenOmakaseSenshu> amari = [];
  for (final YosenOmakaseSenshu s in hitori) {
    _Shuudan? ireru;
    for (final _Shuudan g in shuudan) {
      final double h = g.hayai;
      if (h <= s.sisou && s.sisou <= h * (1.0 + _tsuikaHaba)) {
        if (ireru == null || h > ireru.hayai) ireru = g;
      }
    }
    if (ireru != null) {
      ireru.members.add(_Member(s, true));
    } else {
      amari.add(s);
    }
  }
  //    入れられなかった選手どうしも、2%以内なら集団にする(集団の数が残っているとき)
  amari.sort((a, b) {
    final int c = a.sisou.compareTo(b.sisou);
    return c != 0 ? c : a.bangou.compareTo(b.bangou);
  });
  final List<YosenOmakaseSenshu> free = [];
  int k = 0;
  while (k < amari.length) {
    final double hayai = amari[k].sisou;
    int j = k + 1;
    while (j < amari.length && amari[j].sisou <= hayai * (1.0 + _tsuikaHaba)) {
      j++;
    }
    final List<YosenOmakaseSenshu> kumi = amari.sublist(k, j);
    if (kumi.length >= 2 &&
        shuudan.length < _shuudanSuuMax &&
        _setteiTime(hayai) != null) {
      shuudan.add(
        _Shuudan([
          for (int x = 0; x < kumi.length; x++) _Member(kumi[x], x > 0),
        ]),
      );
    } else {
      free.addAll(kumi);
    }
    k = j;
  }

  // 集団を速い順に並べる(A〜Fの順)
  shuudan.sort((a, b) => a.hayai.compareTo(b.hayai));

  // 4. 平常心の高い選手を集団に散らす(隣り合う集団の境目の選手の入れ替え)
  for (int kaisuu = 0; kaisuu < 50; kaisuu++) {
    bool kawatta = false;
    for (int g = 0; g + 1 < shuudan.length; g++) {
      final _Shuudan a = shuudan[g];
      final _Shuudan b = shuudan[g + 1];
      final int mae = _ochitsukiGoukei(shuudan);
      // (1) 速い集団の一番遅い選手を、遅い集団に移す
      final _Member osoi = a.members.reduce(
        (x, y) => x.s.sisou >= y.s.sisou ? x : y,
      );
      a.members.remove(osoi);
      b.members.add(_Member(osoi.s, false));
      if (a.tadashii && b.tadashii && _ochitsukiGoukei(shuudan) > mae) {
        kawatta = true;
        continue;
      }
      b.members.removeLast();
      a.members.add(osoi);
      // (2) 遅い集団の一番速い選手を、速い集団に移す
      final _Member hayaiM = b.members.reduce(
        (x, y) => x.s.sisou <= y.s.sisou ? x : y,
      );
      b.members.remove(hayaiM);
      a.members.add(_Member(hayaiM.s, false));
      if (a.tadashii && b.tadashii && _ochitsukiGoukei(shuudan) > mae) {
        kawatta = true;
        continue;
      }
      a.members.removeLast();
      b.members.add(hayaiM);
    }
    if (!kawatta) break;
  }
  shuudan.sort((a, b) => a.hayai.compareTo(b.hayai));
  // 入れ替えで設定タイムが選べる範囲から外れた集団(通常は起こらない)は、フリー走にする
  for (final _Shuudan g in shuudan.toList()) {
    if (_setteiTime(g.hayai) == null) {
      shuudan.remove(g);
      free.addAll(g.members.map((m) => m.s));
    }
  }

  // 5. 集団に入らなかった選手はフリー走(平常心が90以上なら前半抑え)
  for (final YosenOmakaseSenshu s in free) {
    sentaku[s.bangou] = s.heijousin >= _sijiKijun ? _osae : _free;
  }

  // 6. 集団の指示と設定タイム
  final List<int?> setteiByou = List.filled(_shuudanSuuMax, null);
  for (int g = 0; g < shuudan.length; g++) {
    setteiByou[g] = _setteiTime(shuudan[g].hayai);
    for (final _Member m in shuudan[g].members) {
      sentaku[m.s.bangou] = _shuudanA + g;
    }
  }
  return YosenOmakaseKekka(sentaku, setteiByou);
}
