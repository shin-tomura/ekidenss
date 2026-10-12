import 'package:ekiden/kansuu/ikku_pace.dart';
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// 駅伝男・平常心の持ち味の文(1.9.7)
//
// 駅伝男と平常心は最初から見える能力なので、値は書かずに言葉で書く(80以上で書き、90以上は特筆する)。
// レース中の効果(RaceCalc.dart・mokuhyou_hosei.dart)に合わせて、どの場面で生きるかを書く
//  ・駅伝の1区と11月駅伝予選: スタート直後飛び出し(成功確率は駅伝男。平常心は関係しない)。
//    飛び出した選手は集団に入らないので、集団のペースの損得も受けない。
//    駅伝男が85以上の選手は指示なしでも自分から飛び出すことがあるが、85という境目が
//    読めないように、そのことは90以上の選手だけに書く
//  ・駅伝の2区以降: 前半突っ込み(駅伝男)・前半抑え(平常心)。指示を出すと、目標順位を下回って
//    襷を受けたときの焦りと、上回ったときのほっと一息がかからない(正月駅伝の6区は判定しない)。
//    初期設定の強さでは、駅伝男が80あれば前半突っ込みが一番得になるので、両方高い選手は駅伝男だけ書く。
//    指示がなければどちらも効かないので「指示が出れば」と書き、総監督の判断は決めつけない。
//    「目標順位・指示の補正設定」で効果や悪化が0%なら、その部分を書かない
//  ・正月駅伝予選: フリー走の前半突っ込み(駅伝男)と、集団走で集団を落ち着かせる平常心。
//    生きる場面が別なので、両方高い選手は両方書く
//  ・学連選抜でコンピュータが監督のときは指示が出ないので、1区で自分から飛び出すことだけを書く
//
// 飽きさせない工夫
//  ・入り方を回す(資質から入って、できることを続ける形と、資質を織り込んだ1文の形)
//  ・記者の型で添える文を変える(数字で語る記者は人数、情景で語る記者は情景、辛口の記者は注意)
//  ・名鑑では置き場所を選手ごとに回す(独立した段落・特徴の段落に続ける・本人のコメントで語らせる)
//  ・速報は、目標順位と比べて襷を受ける位置(後ろ・ちょうど・前)で言い方を変える
// ------------------------------------------------------------

/// 駅伝男・平常心の持ち味を書く境目
const int kimochiKijun = 80;

/// 特筆する境目(箱庭スポーツの展望で取り上げ、名鑑でも言い方を強める)
const int kimochiTokuhitsu = 90;

/// 選手が襷を受ける位置(目標順位と比べて。速報で使う)
enum UkeIchi {
  /// 分からない・書かない
  shiranai,

  /// 目標順位より後ろ
  ushiro,

  /// 目標順位ちょうど
  choudo,

  /// 目標順位より前
  mae,
}

/// 名鑑で使う持ち味の文
class KimochiBun {
  /// 記者の地の文(書かないときは空)
  final String bun;

  /// 選手の特徴の段落に続けて書くか(falseなら独立した段落)
  final bool tsuzukeru;

  /// 本人のコメントに入れる話し言葉(「。」で終わらない。入れないときは空)
  final String kotoba;

  const KimochiBun({this.bun = '', this.tsuzukeru = false, this.kotoba = ''});

  /// 書くことがないとき
  static const KimochiBun nashi = KimochiBun();
}

/// 目標順位の判定がない区間か(1区と、正月駅伝の6区)
bool _hanteiNashi(int race, int kk) => kk <= 0 || (race == 2 && kk == 5);

/// 速報・実況・結果号で、目標順位を下回って襷を受けたときの焦りを書くか
/// (「目標順位・指示の補正設定」で悪化を0%にしているときは、補正の説明に+0.0秒の行が残っても書かない。1.9.8)
bool aseriWoKaku(KijiKankyou k) => HoseiTsuyosa.fromKantoku(k.kantoku).shitamawari > 0;

/// 速報・実況・結果号で、目標順位を上回って襷を受けたときのほっと一息を書くか(0%なら書かない。1.9.8)
bool hitoikiWoKaku(KijiKankyou k) => HoseiTsuyosa.fromKantoku(k.kantoku).hitoiki > 0;

/// 駅伝男・平常心の持ち味の文を作る道具(記事1本につき1つ。置き場所と入り方を選手ごとに回す)
class KimochiKaki {
  final KijiKakite w;

  /// 記者の型(学内メディアは辛口にしないので、呼ぶ側で情景に直して渡す)
  final KishaKata kata;

  /// 目標順位・指示の補正の強さ(設定)
  final HoseiTsuyosa tsuyosa;

  /// 何人目か(置き場所を回す)
  int _ban;

  KimochiKaki(this.w, {required this.kata, int hajime = 0})
    : tsuyosa = HoseiTsuyosa.fromKantoku(w.k.kantoku),
      _ban = hajime;

  /// 指示が成功したときの効果があるか
  bool get _seikouAri => tsuyosa.seikou > 0;

  /// この区間で、目標順位を下回って襷を受けたときの焦りがあるか
  bool _aseriAri(int race, int kk) =>
      !_hanteiNashi(race, kk) && tsuyosa.shitamawari > 0;

  /// この区間で、目標順位を上回って襷を受けたときのほっと一息があるか
  bool _hitoikiAri(int race, int kk) =>
      !_hanteiNashi(race, kk) && tsuyosa.hitoiki > 0;

  /// 2区以降で、駅伝男の持ち味(前半突っ込み)を書くか
  bool _otokoAri(int konjou) => konjou >= kimochiKijun && _seikouAri;

  /// 2区以降で、平常心の持ち味(前半抑え)を書くか(駅伝男を書く選手は書かない)
  bool _heijouAri(int konjou, int heijousin, int race, int kk) =>
      heijousin >= kimochiKijun &&
      !_otokoAri(konjou) &&
      (_seikouAri || _aseriAri(race, kk) || _hitoikiAri(race, kk));

  // ---- 名鑑 ----

  /// 名鑑の持ち味の文(書くことがなければ KimochiBun.nashi)
  /// [race] レース番号、[kk] 区間(11月駅伝予選は組)、[yobi] 選手の呼び方(名字)
  /// [ikku] 1区の集団のペースの予想との相性(自分の大学の1区の選手だけ)
  /// [sijiAri] 指示が出るか(学連選抜でコンピュータが監督のときはfalse)
  /// [tokuhitsuSuu]・[hani] 数字で語る記者が使う、駅伝男が特筆する選手の人数とその範囲(「チーム」など)
  KimochiBun meikan({
    required int konjou,
    required int heijousin,
    required int race,
    required int kk,
    required String yobi,
    IkkuAishou? ikku,
    bool sijiAri = true,
    int tokuhitsuSuu = 0,
    String hani = '',
  }) {
    final List<String> bun = [];
    final List<String> kotoba = [];
    bool tokuhitsu = false;
    if (race == 4) {
      // 正月駅伝予選(フリー走の前半突っ込みと、集団走の平常心)
      final bool otoko = konjou >= kimochiKijun;
      final bool heijou = heijousin >= kimochiKijun;
      if (!otoko && !heijou) return KimochiBun.nashi;
      if (otoko && heijou && w.r.kakuritsu(50)) {
        bun.add(w.erabu([
          '$yobiは、フリー走でも集団走でも持ち味が生きる。',
          'フリー走か集団走か、どちらに置いても$yobiの持ち味は生きる。',
        ]));
      }
      if (otoko) {
        tokuhitsu = konjou >= kimochiTokuhitsu;
        bun.add(
          tokuhitsu
              ? w.erabu([
                  '「駅伝男」の資質が際立ち、フリー走で前半から攻めれば、高い確率で決めてくれるだろう。',
                  'フリー走での前半突っ込みは、高い確率で決まりそうな「駅伝男」だ。',
                ])
              : w.erabu([
                  'フリー走なら、前半から突っ込む指示が生きる「駅伝男」タイプだ。',
                  '「駅伝男」の資質を持ち、フリー走での前半突っ込みが似合う。',
                ]),
        );
        kotoba.add('フリーで行かせてもらえるなら、前半から攻めたい');
      }
      if (heijou) {
        bun.add(
          heijousin >= kimochiTokuhitsu
              ? w.erabu([
                  '平常心の高さは際立っており、集団走に入れば、集団全体を落ち着かせる存在になりそうだ。',
                  '集団走なら、際立つ平常心で集団全体を落ち着かせる役が期待できる。',
                ])
              : w.erabu([
                  '集団走に入れば、平常心の高さで集団を落ち着かせる役も期待できる。',
                  '平常心が高く、集団走では集団の重しになれそうだ。',
                ]),
        );
        kotoba.add('集団走なら、周りを落ち着かせる走りをしたい');
      }
      _soeru(bun, 'yosen');
    } else if (race == 3 || kk == 0) {
      // 駅伝の1区と11月駅伝予選(スタート直後飛び出し。平常心は関係しない)
      if (konjou < kimochiKijun) return KimochiBun.nashi;
      tokuhitsu = konjou >= kimochiTokuhitsu;
      if (!sijiAri) {
        // 指示が出ない(コンピュータが監督の学連選抜)ので、自分から飛び出すことだけ(特筆する選手だけ)
        if (!tokuhitsu) return KimochiBun.nashi;
        bun.add(_iriOtoko(yobi, true, tokuhitsuSuu, hani));
        bun.add(w.erabu([
          '号砲と同時に、自分から前に出ていく場面があるかもしれない。',
          '指示がなくても、スタート直後に自分から飛び出すことがありそうだ。',
        ]));
        kotoba.add('スタートから前に出るのは得意。行けると思ったら行きます');
      } else {
        final bool oriKomi = w.r.kakuritsu(40);
        if (oriKomi) {
          bun.add(
            tokuhitsu
                ? w.erabu([
                    '「駅伝男」の資質が際立つ$yobiなら、スタート直後の飛び出しは高い確率で決まりそうだ。',
                    '号砲と同時に前へ。際立つ「駅伝男」の資質を持つ$yobiには、それができる。',
                  ])
                : w.erabu([
                    '「駅伝男」の資質を持つ$yobiなら、スタート直後に飛び出す策も成り立つ。',
                    'スタート直後の飛び出しも、「駅伝男」の資質を持つ$yobiには選択肢になる。',
                  ]),
          );
        } else {
          bun.add(_iriOtoko(yobi, tokuhitsu, tokuhitsuSuu, hani));
          bun.add(w.erabu([
            'スタート直後に飛び出し、集団のペースに左右されずに押していく手もある。',
            '号砲と同時に前へ出る、スタート直後の飛び出しも選択肢に入る。',
            '集団に付き合わず、スタート直後に飛び出して主導権を握る策も成り立つ。',
          ]));
        }
        if (tokuhitsu) {
          bun.add(w.erabu([
            if (!oriKomi) '飛び出しの指示が出れば、高い確率で決めてくれるはずだ。',
            '指示がなくても、自分から前に出ていく場面があるかもしれない。',
          ]));
        }
        // 1区の集団のペースの予想と合わせる(自分の大学の1区の選手だけ)
        final String? p = _ikkuBun(ikku, yobi);
        if (p != null) bun.add(p);
        kotoba.addAll([
          'スタートから前に出るのは得意。飛び出せと言われたら、迷わず行きます',
          '集団のペースに合わせるより、自分のペースで行くほうが性に合っている',
          'スタートで前に出る準備はできています',
        ]);
      }
      _soeru(bun, 'tobidashi');
    } else {
      // 駅伝の2区以降(駅伝男は前半突っ込み、平常心は前半抑え)
      if (!sijiAri) return KimochiBun.nashi;
      final bool aseri = _aseriAri(race, kk);
      if (_otokoAri(konjou)) {
        tokuhitsu = konjou >= kimochiTokuhitsu;
        final bool oriKomi = w.r.kakuritsu(40);
        if (oriKomi) {
          bun.add(
            tokuhitsu
                ? w.erabu([
                    '「駅伝男」の資質が際立つ$yobiなら、前半突っ込みの指示は高い確率で決まるはずだ。',
                    '前半から攻める指示が出れば、$yobiの際立つ「駅伝男」の資質が、そのまま走りになるだろう。',
                  ])
                : w.erabu([
                    '「駅伝男」の資質を持つ$yobiなら、前半から突っ込む指示にも応えられる。',
                    '前半突っ込みの指示が出れば、「駅伝男」の資質を持つ$yobiの持ち味が生きる。',
                  ]),
          );
        } else {
          bun.add(_iriOtoko(yobi, tokuhitsu, tokuhitsuSuu, hani));
          bun.add(
            tokuhitsu
                ? w.erabu([
                    '前半突っ込みの指示が出れば、高い確率で決めてくれるだろう。',
                    '前半から攻める指示なら、期待を裏切ることは少なそうだ。',
                    '前半から攻める指示が出れば、その資質がそのまま走りになるはずだ。',
                  ])
                : w.erabu([
                    '前半から突っ込む指示が出れば、それに応える力がある。',
                    '前半突っ込みの指示が生きるタイプだ。',
                    '前半から攻める走りが似合う。',
                  ]),
          );
        }
        if (aseri && (tokuhitsu || w.r.kakuritsu(50))) {
          bun.add(w.erabu([
            '目標より後ろで襷を受けても、焦りで崩れるのではなく、前半からの攻めに変えられる。',
            '目標順位より後ろで襷を受ける展開になっても、焦りを攻めの力に変えられるはずだ。',
            '後ろで襷を受けて焦りが出やすい場面こそ、持ち味が生きる。',
          ]));
        } else if (tokuhitsu && _hitoikiAri(race, kk) && w.r.kakuritsu(50)) {
          bun.add(w.erabu([
            '目標より前で襷を受けても、攻めの指示があれば気が緩む心配はない。',
            '前で襷を受けたときの気の緩みとも、無縁でいられそうだ。',
          ]));
        }
        kotoba.addAll([
          '前半から行けと言われたら、しっかり行けます',
          '前半から攻めるのは得意なので、任せてほしい',
          if (aseri) '後ろで襷を受けても、焦るより攻めるタイプなので',
        ]);
        _soeru(bun, 'tsukkomi');
      } else if (_heijouAri(konjou, heijousin, race, kk)) {
        final bool takai = heijousin >= kimochiTokuhitsu;
        final bool oriKomi = w.r.kakuritsu(40);
        if (oriKomi) {
          bun.add(_osaeBun(yobi, race, kk, oriKomi: true));
        } else {
          bun.add(
            takai
                ? w.erabu([
                    '平常心の高さは折り紙付きだ。',
                    'どんな位置で襷を受けても動じない平常心が、$yobiの武器だ。',
                    '何があっても動じない平常心は、際立っている。',
                  ])
                : w.erabu([
                    '落ち着いた平常心も$yobiの持ち味だ。',
                    '周りに流されない平常心を持つ。',
                    '平常心の高さも持ち味の一つ。',
                  ]),
          );
          bun.add(_osaeBun(yobi, race, kk, oriKomi: false));
        }
        kotoba.addAll([
          if (aseri) '後ろで受けても慌てない自信はあります',
          'どこで襷を受けても、自分のペースは崩さない',
          '前半を抑えて入るのは得意です',
        ]);
        _soeru(bun, 'osae');
      } else {
        return KimochiBun.nashi;
      }
    }
    if (bun.isEmpty) return KimochiBun.nashi;
    final int ban = _ban++;
    final int oki = ban % 3;
    final String b = bun.join();
    if (oki == 2 && kotoba.isNotEmpty) {
      // 本人のコメントで語らせる(駅伝男が特筆する選手は、記者の文も残す)
      return KimochiBun(bun: tokuhitsu ? b : '', kotoba: w.erabu(kotoba));
    }
    return KimochiBun(bun: b, tsuzukeru: oki == 1);
  }

  /// 駅伝男の資質の言い方(入りの1文)
  String _iriOtoko(String yobi, bool tokuhitsu, int suu, String hani) {
    if (tokuhitsu && kata == KishaKata.suuji && suu >= 1 && hani.isNotEmpty) {
      return suu == 1
          ? '$haniで「駅伝男」の資質が際立つのは、$yobiただ1人だ。'
          : '$haniには「駅伝男」の資質が際立つ選手が$suu人いる。$yobiはその1人だ。';
    }
    return tokuhitsu
        ? w.erabu([
            '$yobiの「駅伝男」としての資質は際立っている。',
            '「駅伝男」の名がこれほど似合う選手は多くない。',
            '何より光るのは、「駅伝男」としての資質だ。',
          ])
        : w.erabu([
            '$yobiは「駅伝男」の資質も備える。',
            '大舞台で力を出す「駅伝男」の一面も持つ。',
            '勝負強さを秘めた「駅伝男」タイプでもある。',
          ]);
  }

  /// 前半抑えでできること(襷を受ける位置で焦り・ほっと一息があるかで変える)
  /// [oriKomi] 平常心の高さを織り込んだ1文にするか
  String _osaeBun(String yobi, int race, int kk, {required bool oriKomi}) {
    final bool a = _aseriAri(race, kk);
    final bool h = _hitoikiAri(race, kk);
    if (oriKomi) {
      if (a && h) {
        return w.erabu([
          '平常心の高い$yobiなら、前半を抑える指示で、目標より後ろで襷を受けても焦らず、前で受けても気を緩めずに入れそうだ。',
          '前半を抑える指示が出れば、平常心の高い$yobiは、襷を受ける位置に気持ちを揺さぶられずに走れそうだ。',
        ]);
      }
      if (a) {
        return w.erabu([
          '平常心の高い$yobiなら、目標より後ろで襷を受けても、前半を抑える指示で焦らずに入れそうだ。',
          '目標順位より後ろで襷を受ける展開でも、平常心の高い$yobiなら、前半を抑えて落ち着いて走れるはずだ。',
        ]);
      }
      if (h) {
        return '平常心の高い$yobiなら、前半を抑える指示で、前で襷を受けても気を緩めずに走れそうだ。';
      }
      return w.erabu([
        '平常心の高い$yobiなら、前半を抑える指示で、自分のペースを守る走りができそうだ。',
        '前半を抑える指示が出れば、平常心の高い$yobiは落ち着いて自分のリズムを刻めるはずだ。',
      ]);
    }
    if (a && h) {
      return w.erabu([
        '前半を抑える指示なら、目標より後ろで襷を受けても焦らず、前で受けても気を緩めずに入れそうだ。',
        '前半を抑える指示が出れば、襷を受ける位置に気持ちを揺さぶられることはなさそうだ。',
      ]);
    }
    if (a) {
      return w.erabu([
        '前半を抑える指示なら、目標より後ろで襷を受けても焦らずに入れそうだ。',
        '目標順位より後ろで襷を受ける展開でも、前半を抑える指示で落ち着いて走れそうだ。',
      ]);
    }
    if (h) {
      return '前半を抑える指示が出れば、前で襷を受けても気を緩めずに走れそうだ。';
    }
    return w.erabu([
      '前半を抑える指示で、自分のペースを守る走りができそうだ。',
      '前半を抑える指示なら、落ち着いて自分のリズムを刻めるはずだ。',
    ]);
  }

  /// 1区の集団のペースの予想との相性の文(書かないときはnull)
  String? _ikkuBun(IkkuAishou? a, String yobi) {
    if (a == null) return null;
    switch (a) {
      case IkkuAishou.osokuSon:
        return w.erabu([
          '予想される1区の流れは$yobiには遅く、集団に付き合えば持ち味を出し切れないおそれがある。飛び出しの価値は大きい。',
          '1区の集団は$yobiには物足りないペースになりそうで、飛び出して自分のペースを刻むのが得策かもしれない。',
        ]);
      case IkkuAishou.daiShissoku:
        return w.erabu([
          '予想される1区の流れは$yobiには速すぎるだけに、無理について行くより、飛び出して自分のペースで押す手もある。',
          '速い集団について行けば後半の失速が心配で、飛び出して自分のペースを守る手も考えられる。',
        ]);
      case IkkuAishou.sukoshiToku:
        return 'もっとも、予想される1区の流れは$yobiにちょうどよく、集団に乗る手堅さも捨てがたい。';
      case IkkuAishou.sonTokuNashi:
        return '予想される1区の流れでは、集団に入っても得は少なそうだ。';
      case IkkuAishou.hipparu:
        return 'ただ、$yobiは集団を引っ張る役回りになりそうで、飛び出すかどうかで1区の流れそのものが変わる。';
      case IkkuAishou.tobidashi:
        return null;
    }
  }

  /// 記者の型で添える文(情景で語る記者はときどき情景を、辛口の記者は注意を添える)
  void _soeru(List<String> bun, String shurui) {
    if (kata == KishaKata.suuji) return;
    if (kata == KishaKata.joukei && !w.r.kakuritsu(50)) return;
    final List<String>? kouho = kata == KishaKata.joukei
        ? _joukeiSoe[shurui]
        : _karakuchiSoe[shurui];
    if (kouho != null) bun.add(w.erabu(kouho));
  }

  // ---- 速報(次の走者) ----

  /// 速報の次の走者の持ち味の文(書くことがなければ空。駅伝の2区以降だけ)
  /// [ichi] 目標順位と比べて襷を受ける位置(一番新しい区間の速報だけ。それ以外は shiranai)
  /// [sijiAri] 指示が出るか(学連選抜でコンピュータが監督のときはfalse)
  String sokuhou({
    required int konjou,
    required int heijousin,
    required int race,
    required int kk,
    required String yobi,
    UkeIchi ichi = UkeIchi.shiranai,
    bool sijiAri = true,
  }) {
    if (kk <= 0 || race == 3 || race == 4 || !sijiAri) return '';
    final bool aseri = ichi == UkeIchi.ushiro && _aseriAri(race, kk);
    final bool hitoiki = ichi == UkeIchi.mae && _hitoikiAri(race, kk);
    if (_otokoAri(konjou)) {
      final String otoko = konjou >= kimochiTokuhitsu
          ? '「駅伝男」の資質が際立つ$yobi'
          : '「駅伝男」の$yobi';
      if (aseri) {
        return w.erabu([
          '目標より後ろで襷を受ける。焦りが出やすい場面だが、$otokoなら、前半からの突っ込みで攻めに変えられる。',
          '目標順位より後ろでの襷渡しになる。それでも$otokoには、前半から攻めて取り返す力がある。',
        ]);
      }
      if (hitoiki) {
        return w.erabu([
          '目標より前で襷を受ける。気が緩みやすい場面だが、$otokoなら、前半から攻めて流れを保てる。',
          '目標を上回る位置での襷渡し。ここで攻める指示が出れば、$otokoは気を緩めずに押していけるはずだ。',
        ]);
      }
      return w.erabu([
        '$otokoは、前半から突っ込む指示が出れば応えられる。',
        '前半から攻める指示が出れば、$otokoの持ち味が生きる。',
      ]);
    }
    if (_heijouAri(konjou, heijousin, race, kk)) {
      if (aseri) {
        return w.erabu([
          '目標より後ろで襷を受ける。焦りが出やすい場面だが、平常心の高い$yobiなら、前半を抑えて落ち着いて入れるはずだ。',
          '目標順位より後ろでの襷渡しになるが、平常心の高い$yobiなら、前半を抑える指示で焦りを封じられる。',
        ]);
      }
      if (hitoiki) {
        return w.erabu([
          '目標より前で襷を受ける。気が緩みやすい場面だが、平常心の高い$yobiなら、前半を抑えて引き締めて入れそうだ。',
          '目標を上回る位置での襷渡し。平常心の高い$yobiなら、前半を抑える指示で気持ちを引き締められる。',
        ]);
      }
      if (!_seikouAri) return '';
      return w.erabu([
        '平常心の高い$yobiは、前半を抑える指示が出れば自分のペースを守れそうだ。',
        '前半を抑える指示が出れば、平常心の高い$yobiは落ち着いて入れるはずだ。',
      ]);
    }
    return '';
  }
}

// ---- 振り返り(結果号) ----

/// 振り返りで、指示の成否を駅伝男・平常心に結びつけて書く文(結びつけないときはnull)
/// [siji] 指示(1区はスタート直後に飛び出していれば1)、[seikou] 成否(判定なしはnull)
/// [jibunKara] 1区で、飛び出しの指示なしに自分から飛び出したか
String? kimochiFurikaeri(
  KijiKakite w, {
  required int konjou,
  required int heijousin,
  required int kk,
  required int siji,
  required bool? seikou,
  required bool jibunKara,
}) {
  if (seikou == null) return null;
  if (siji == 1 && konjou >= kimochiKijun) {
    if (kk == 0) {
      if (jibunKara) {
        return seikou
            ? '「駅伝男」らしく、自らスタート直後に飛び出し、狙いどおりに決めた。'
            : '「駅伝男」らしく自らスタート直後に飛び出したが、後半に代償を払った。';
      }
      return seikou
          ? w.erabu([
              '「駅伝男」の資質どおり、スタート直後の飛び出しを決めた。',
              'スタート直後の飛び出しで、「駅伝男」の資質が生きた。',
            ])
          : w.erabu([
              '「駅伝男」でも、この日はスタート直後の飛び出しが裏目に出た。',
              '「駅伝男」の資質を見込んだ飛び出しだったが、後半に代償を払った。',
            ]);
    }
    return seikou
        ? w.erabu([
            '「駅伝男」らしく、前半から突っ込む指示にしっかり応えた。',
            '「駅伝男」の資質どおり、前半の突っ込みを決めた。',
          ])
        : w.erabu([
            '「駅伝男」でも、この日は前半の突っ込みが裏目に出た。',
            '「駅伝男」の資質を見込んだ前半の突っ込みだったが、後半に失速した。',
          ]);
  }
  if (siji == 2 && kk > 0 && heijousin >= kimochiKijun && konjou < kimochiKijun) {
    return seikou
        ? w.erabu([
            '持ち前の平常心で前半を抑え、後半に伸びた。',
            '平常心の高さどおり、前半を抑える指示を落ち着いて守った。',
          ])
        : '平常心が持ち味でも、この日は前半を抑えた分を取り返せなかった。';
  }
  return null;
}

/// 情景で語る記者が添える文(種類ごと)
const Map<String, List<String>> _joukeiSoe = {
  'tobidashi': [
    '号砲が鳴った瞬間、真っ先に前へ出る姿が目に浮かぶ。',
    'スタートラインに立つ背中から、前へ出る気配が伝わってくる。',
  ],
  'tsukkomi': [
    '襷を受けた瞬間から前を追う姿が、目に浮かぶ。',
    '襷を肩にかけるなり、前の背中を追いかけていくだろう。',
  ],
  'osae': [
    '襷を受ける位置がどこであっても、表情一つ変えずに走り出すだろう。',
    '周りがどれだけ慌ただしくても、自分のリズムで走り出せる。',
  ],
  'yosen': ['号砲のあと、自分の役目を淡々とこなす姿が目に浮かぶ。'],
};

/// 辛口の記者が添える注意(種類ごと)
const Map<String, List<String>> _karakuchiSoe = {
  'tobidashi': ['ただ、飛び出しは決まらなければ後半に跳ね返る。使いどころが問われる。'],
  'tsukkomi': [
    '持ち味が生きるかどうかは、指示次第だ。',
    '指示がなければ、その資質も宝の持ち腐れになる。',
  ],
  'osae': ['攻めの指示に向く型ではないが、抑えの指示なら計算が立つ。'],
  'yosen': ['持ち味が生きるかどうかは、走り方の選び方次第だ。'],
};
