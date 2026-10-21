import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/screens/Modal_senshu.dart';
import 'package:ekiden/screens/gakuren_copy_button.dart';
import 'package:ekiden/screens/Modal_kukanTekisei.dart'; // 区間適性の見立て(2.1.1)

/// 学連選抜の区間配置を決める部分(1.8.2。2.1.0から学連選抜編成の画面(mode0290.dart)に直接並べる)
/// プレイヤーの大学が正月駅伝に出場できない年に、学連選抜の監督として区間配置を決める
/// (最初はコンピュータが決めた配置になっている)
/// ・大学の区間エントリーの画面と同じく、区間ごとに走る選手を選ぶ。2.0.9までは、ほかの区間の
///   選手を選ぶと2人の区間が入れ替わったが、2.1.0から入れ替えず、同じ選手を2つの区間に選べる
///   (重なった区間は赤字で出す)
/// ・重なりも空いた区間もないときは、選ぶたびに学連選抜の選手のデータに保存する(展望号や
///   生成AIに渡すコピーにすぐ出る)。重なっているあいだは画面の中だけで持ち、保存は直す前の
///   配置のまま(アプリを閉じると直す前に戻る)。学連選抜編成の画面の「進む」で mondaiAri を見て、
///   重なりがあれば進ませない。重なりがなければ、区間配置(kakuninGyou)と目標順位を出して、
///   確定してよいかを必ず確かめる
/// ・試走は、元の選手データで大学の選手と同じ試走タイムの計算をする
///   (±0.5%の濁しあり。1区の集団のペースと、2区以降のモチベーション低下補正は入らない)
class GakurenKukanHenshuu extends StatefulWidget {
  const GakurenKukanHenshuu({super.key});

  @override
  State<GakurenKukanHenshuu> createState() => GakurenKukanHenshuuState();
}

/// 学連選抜編成の画面から GlobalKey で mondaiAri と hozon を呼ぶので、外に出す
class GakurenKukanHenshuuState extends State<GakurenKukanHenshuu> {
  static const int _raceIndex = 2; // 正月駅伝
  static const int _yosenIndex = 4; // 正月駅伝予選

  /// 区間ごとに選んでいる選手のid(いなければnull)
  List<int?> _sentaku = [];

  /// 区間ごとの試走タイム(区間 → 秒)
  final Map<int, double> _shisouKekka = {};

  /// 試走を計算している区間
  final Set<int> _keisanChuu = {};

  int _entry(Senshu_Gakuren_Data s) =>
      s.entrykukan_race[_raceIndex][s.gakunen - 1];

  Box<Senshu_Gakuren_Data> get _box =>
      Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');

  /// 予選の順位の良い順に並べた学連選抜の選手(選ぶときの一覧と、下の選手の一覧)
  List<Senshu_Gakuren_Data> _senshuNarabi() => _box.values.toList()
    ..sort((a, b) {
      final int c = a.kukanjuni_race[_yosenIndex][a.gakunen - 1].compareTo(
        b.kukanjuni_race[_yosenIndex][b.gakunen - 1],
      );
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  @override
  void initState() {
    super.initState();
    // 保存している配置(最初はコンピュータが決めた配置)から始める
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final int kukansuu = gh.kukansuu_taikaigoto[_raceIndex];
    _sentaku = List<int?>.filled(kukansuu, null);
    for (final Senshu_Gakuren_Data s in _senshuNarabi()) {
      final int e = _entry(s);
      if (e >= 0 && e < kukansuu && _sentaku[e] == null) _sentaku[e] = s.id;
    }
  }

  /// 選手[id]を選んでいる区間(0始まり。並びは区間の順)
  List<int> _erandaKukan(int id) => [
    for (int k = 0; k < _sentaku.length; k++)
      if (_sentaku[k] == id) k,
  ];

  /// 区間適性の見立てに渡すもの(2.1.1。選んでいる区間を「配置中」として出す)
  KukanTekiseiNaiyou _kukanTekiseiNaiyou() {
    final Map<int, List<int>> kukanOf = {};
    for (int kk = 0; kk < _sentaku.length; kk++) {
      final int? id = _sentaku[kk];
      if (id != null) kukanOf.putIfAbsent(id, () => <int>[]).add(kk);
    }
    return KukanTekiseiNaiyou(
      race: _raceIndex,
      gakuren: _senshuNarabi(),
      kukanOf: kukanOf,
      kukanList: [for (int kk = 0; kk < _sentaku.length; kk++) kk],
      kukanKotoba: '配置中',
    );
  }

  /// 区間の重なりか、空いた区間があるか(あれば保存せず、進ませない)
  /// 空いた区間は、区間の数だけ選手がいるのに選んでいない区間(選手が区間の数より少ないときは数えない)
  bool get mondaiAri {
    final Set<int> mita = {};
    int umatta = 0;
    for (final int? id in _sentaku) {
      if (id == null) continue;
      if (!mita.add(id)) return true; // 重なり
      umatta++;
    }
    final int ninzuu = _box.length;
    final int hitsuyou = ninzuu < _sentaku.length ? ninzuu : _sentaku.length;
    return umatta < hitsuyou;
  }

  /// 選んでいる配置を学連選抜の選手のデータに保存する(重なりや空いた区間があるときは保存しない)
  /// 選ばれなかった選手は、走る予定だったなら補欠(-1)にし、もともと走らない選手はそのまま
  Future<void> hozon() async {
    if (mondaiAri) return;
    final Map<dynamic, Senshu_Gakuren_Data> kakikae = {};
    for (final dynamic key in _box.keys) {
      final Senshu_Gakuren_Data? s = _box.get(key);
      if (s == null) continue;
      final int mae = _entry(s);
      final int k = _sentaku.indexOf(s.id);
      final int ato = k >= 0 ? k : (mae >= 0 ? -1 : mae);
      if (ato == mae) continue;
      s.entrykukan_race[_raceIndex][s.gakunen - 1] = ato;
      kakikae[key] = s;
    }
    // まとめて保存する(途中で終了しても、区間が重ならないように)
    if (kakikae.isNotEmpty) await _box.putAll(kakikae);
  }

  /// 「進む」の確認に出す区間配置の文(例: 「1区 山田太郎(〇〇)」。かっこの中は所属大学。
  /// 選んでいない区間は「(未定)」)
  List<String> kakuninGyou() {
    final Map<int, Senshu_Gakuren_Data> senshuMap = {
      for (final Senshu_Gakuren_Data s in _box.values) s.id: s,
    };
    final Map<int, UnivData> univMap = {
      for (final u in Hive.box<UnivData>('univBox').values) u.id: u,
    };
    return [
      for (int k = 0; k < _sentaku.length; k++)
        '${k + 1}区 ${_kakuninSenshu(senshuMap[_sentaku[k]], univMap)}',
    ];
  }

  String _kakuninSenshu(Senshu_Gakuren_Data? s, Map<int, UnivData> univMap) {
    if (s == null) return '(未定)';
    return '${s.name}(${univMap[s.univid]?.name ?? '---'})';
  }

  /// 区間[kukan]を走る選手を[senshuId]の選手にする(ほかの区間はそのまま)
  Future<void> _erabu(int kukan, int senshuId) async {
    if (kukan < 0 || kukan >= _sentaku.length) return;
    if (_sentaku[kukan] == senshuId) return;
    setState(() {
      _sentaku[kukan] = senshuId;
      // 走る選手が変わった区間の試走タイムは消す
      _shisouKekka.remove(kukan);
    });
    await hozon();
  }

  /// 区間[kukan]を[senshuId]の選手が試走する
  Future<void> _shisou(int kukan, int senshuId) async {
    setState(() => _keisanChuu.add(kukan));
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final List<SenshuData> sortedSenshu =
        Hive.box<SenshuData>('senshuBox').values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final List<UnivData> sortedUniv = Hive.box<UnivData>('univBox').values
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final KantokuData kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData')!;
    double? kekka;
    // 試走タイムの計算は、選手idと並びの番号が同じ前提
    if (senshuId >= 0 &&
        senshuId < sortedSenshu.length &&
        sortedSenshu[senshuId].id == senshuId) {
      kekka = await runTrialCalculation(
        senshuId,
        kukan,
        gh,
        sortedSenshu,
        sortedUniv,
        kantoku,
      );
    }
    if (!mounted) return;
    setState(() {
      _keisanChuu.remove(kukan);
      // 試走のあいだに選手を変えていたら、結果は出さない
      if (kekka != null && _sentaku[kukan] == senshuId) {
        _shisouKekka[kukan] = kekka;
      }
    });
  }

  void _shousai(int senshuId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: '詳細',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ModalSenshuDetailView(senshuId: senshuId);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Ghensuu gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0)!;
    final Map<int, UnivData> univMap = {
      for (final u in Hive.box<UnivData>('univBox').values) u.id: u,
    };
    final List<Senshu_Gakuren_Data> senshu = _senshuNarabi();
    if (senshu.isEmpty) {
      return const Text(
        '学連選抜の選手がいません',
        style: TextStyle(color: HENSUU.textcolor),
      );
    }
    final bool mondai = mondaiAri;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '学連選抜の区間配置',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: HENSUU.fontsize_honbun,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '区間ごとに走る選手を選んでください。最初はコンピュータが決めた配置になっています。'
          '同じ選手を2つの区間に選ぶと、区間の横に赤字で出ます。重なりがあるあいだは配置が保存されず、「進む」を押しても先に進めません'
          '(コピーや区間配置の一覧には、直す前の配置が出ます)。\n'
          '試走は大学の選手と同じ計算です(走るたびに多少タイムが違います)。1区の集団のペースや、2区以降のモチベーション低下補正、経験補正、調子は入っていません。\n'
          '選手の名前の後ろの調子は、学連選抜で走るときの調子です。「詳細」に出る調子は元の大学の選手のもので、違うことがあります。',
          style: TextStyle(
            color: HENSUU.textcolor.withOpacity(0.85),
            fontSize: HENSUU.fontsize_honbun - 2,
          ),
        ),
        const SizedBox(height: 8),
        // 1区の集団のペースは大学の選手だけで決まる(RaceCalc_gakuren.dartの1区の補正を参照)
        const Text(
          '※1区の集団のペースは大学の選手だけで決まります。どんなにカリスマが高くても、学連選抜の選手が集団のペースを作ることはありません。',
          style: TextStyle(
            color: Colors.amber,
            fontSize: HENSUU.fontsize_honbun - 2,
          ),
        ),
        // 区間配置と選手の詳しい情報をコピーする(生成AIとの相談用)と、今季タイム一覧表と、
        // 区間適性の見立て(2.1.1。Modal_kukanTekisei.dart)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const GakurenCopyButton(kukanHaiti: true),
            const GakurenKonkiTimeLink(),
            KukanTekiseiLink(naiyou: _kukanTekiseiNaiyou),
          ],
        ),
        if (mondai)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '区間配置に重複か空白区間があります',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: HENSUU.fontsize_honbun - 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        for (int kukan = 0; kukan < _sentaku.length; kukan++)
          _kukanGyou(
            kukan: kukan,
            kyori: gh.kyori_taikai_kukangoto[_raceIndex][kukan],
            senshu: senshu,
            univMap: univMap,
            myUnivid: gh.MYunivid,
          ),
        const SizedBox(height: 12),
        const Divider(color: Colors.white),
        // 学連選抜の選手の一覧(大学の区間エントリーの画面の選手調子一覧と同じ形。選んでいない選手は「未定」)
        const Text(
          '学連選抜の選手一覧',
          style: TextStyle(
            color: Colors.white,
            fontSize: HENSUU.fontsize_honbun,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            for (final Senshu_Gakuren_Data s in senshu) _senshuChip(s),
          ],
        ),
      ],
    );
  }

  /// 選手の一覧に出す文の1行目(例: 山田太郎(3) 調子85 (今は3区))
  /// 調子は学連選抜の選手の調子(元の大学の選手の「詳細」の調子とは別。1.9.9)。
  /// [kukan]とは別の区間にも選んでいる選手には、その区間を付ける
  String _senshuBun1(Senshu_Gakuren_Data s, int kukan) {
    final List<int> betsu = [
      for (final int k in _erandaKukan(s.id))
        if (k != kukan) k,
    ];
    final String betsuKukan = betsu.isEmpty
        ? ''
        : ' (今は${betsu.map((k) => '${k + 1}区').join('・')})';
    return '${s.name}(${s.gakunen}) 調子${s.chousi}$betsuKukan';
  }

  /// 選手の一覧に出す文の2行目(例: 〇〇大 予選12位)
  /// 文字を大きくしていても予選の成績が切れないように、1行目と分けて、省略せずに折り返す(1.9.9)
  String _senshuBun2(Senshu_Gakuren_Data s, Map<int, UnivData> univMap) {
    final String univ = univMap[s.univid]?.name ?? '---';
    final int yosenJuni = s.kukanjuni_race[_yosenIndex][s.gakunen - 1] + 1;
    return '$univ 予選$yosenJuni位';
  }

  /// 区間1つ分(1行目に区間と距離、2行目に選手を選ぶドロップダウン、3行目に試走と詳細)
  Widget _kukanGyou({
    required int kukan,
    required double kyori,
    required List<Senshu_Gakuren_Data> senshu,
    required Map<int, UnivData> univMap,
    required int myUnivid,
  }) {
    final int? imaId = _sentaku[kukan];
    final double? shisou = _shisouKekka[kukan];
    final bool keisanChuu = _keisanChuu.contains(kukan);
    // 同じ選手を選んでいるほかの区間
    final List<int> kasanari = imaId == null
        ? const []
        : [
            for (final int k in _erandaKukan(imaId))
              if (k != kukan) k,
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${kukan + 1}区　${kyori.toStringAsFixed(0)}m'),
                if (kasanari.isNotEmpty)
                  TextSpan(
                    text:
                        '　${kasanari.map((k) => '${k + 1}区').join('・')}と重複',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(color: HENSUU.textcolor),
          ),
          DropdownButton<int>(
            value: imaId,
            hint: const Text(
              '(選手が決まっていません)',
              style: TextStyle(color: Colors.redAccent),
            ),
            isExpanded: true,
            // 選手の文は2行(折り返せばそれ以上)なので、高さを決めずに中身に合わせる
            // (決まった高さのままだと、文字を大きくしたときに2行目がはみ出すため。1.9.9)
            itemHeight: null,
            dropdownColor: const Color.fromARGB(255, 30, 30, 30),
            iconEnabledColor: HENSUU.textcolor,
            items: [
              for (final s in senshu)
                DropdownMenuItem<int>(
                  value: s.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // 選んでいる選手に印(大学の区間エントリーの画面と同じ)
                        if (s.id == imaId) ...[
                          const Icon(
                            Icons.check,
                            color: HENSUU.LinkColor,
                            size: HENSUU.fontsize_honbun,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _senshuBun1(s, kukan),
                                style: TextStyle(
                                  color: s.univid == myUnivid
                                      ? Colors.amber
                                      : HENSUU.LinkColor,
                                  fontSize: HENSUU.fontsize_honbun - 2,
                                ),
                              ),
                              Text(
                                _senshuBun2(s, univMap),
                                style: TextStyle(
                                  color: s.univid == myUnivid
                                      ? Colors.amber
                                      : HENSUU.LinkColor,
                                  fontSize: HENSUU.fontsize_honbun - 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            onChanged: (int? id) {
              if (id != null) _erabu(kukan, id);
            },
          ),
          if (imaId != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: keisanChuu ? null : () => _shisou(kukan, imaId),
                  child: const Text(
                    '試走',
                    style: TextStyle(color: HENSUU.LinkColor),
                  ),
                ),
                TextButton(
                  onPressed: () => _shousai(imaId),
                  child: const Text(
                    '詳細',
                    style: TextStyle(color: HENSUU.LinkColor),
                  ),
                ),
                const SizedBox(width: 8),
                if (keisanChuu)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (shisou != null)
                  Text(
                    '試走 ${TimeDate.timeToFunByouString(shisou)}',
                    style: const TextStyle(color: HENSUU.textcolor),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 下の一覧の選手1人分(例: 「3区 山田太郎(3年) 調子85 詳細」。選んでいない選手は赤字の「未定」)
  Widget _senshuChip(Senshu_Gakuren_Data s) {
    final List<int> kukan = _erandaKukan(s.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  kukan.isEmpty
                      ? const TextSpan(
                          text: '未定 ',
                          style: TextStyle(color: Colors.redAccent),
                        )
                      : TextSpan(
                          text:
                              '${kukan.map((k) => '${k + 1}区').join('・')} ',
                          style: TextStyle(
                            color: kukan.length > 1
                                ? Colors.redAccent
                                : Colors.white,
                          ),
                        ),
                  TextSpan(text: '${s.name} (${s.gakunen}年) 調子${s.chousi}'),
                ],
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _shousai(s.id),
            child: const Text(
              '詳細',
              style: TextStyle(
                color: HENSUU.LinkColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
