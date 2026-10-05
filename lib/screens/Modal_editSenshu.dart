import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 数値入力制御のために追加
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/joukai.dart';
import 'package:ekiden/kansuu/riron_kirokukai_time.dart';
import 'package:ekiden/kansuu/gakuren_utsushi.dart'; // 学連選抜用の写しへの反映(1.8.8)
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/kansuu/TrialTime.dart'; // 区間の見込みタイム(1.8.8)
import 'package:ekiden/kansuu/chousi_keiken_hosei.dart'; // 区間の見込みタイムの調子補正(1.8.8)

class SenshuEditView extends StatefulWidget {
  final int senshuId;

  const SenshuEditView({super.key, required this.senshuId});

  @override
  State<SenshuEditView> createState() => _SenshuEditViewState();
}

class _SenshuEditViewState extends State<SenshuEditView> {
  late Box<SenshuData> _senshuBox;
  SenshuData? _editingSenshu;

  // 編集用のコントローラーと変数
  int? _selectedMenu;
  final TextEditingController _chousiController = TextEditingController();
  final TextEditingController _anteikanController = TextEditingController();
  final TextEditingController _konjouController = TextEditingController();
  final TextEditingController _heijousinController = TextEditingController();
  final TextEditingController _choukyorinebariController =
      TextEditingController();
  final TextEditingController _spurtryokuController = TextEditingController();
  final TextEditingController _karisumaController = TextEditingController();
  final TextEditingController _noboritekiseiController =
      TextEditingController();
  final TextEditingController _kudaritekiseiController =
      TextEditingController();
  final TextEditingController _noborikudarikirikaenouryokuController =
      TextEditingController();
  final TextEditingController _tandokusouController = TextEditingController();
  final TextEditingController _paceagesagetaiouryokuController =
      TextEditingController();
  final TextEditingController _baseAbilityAController = TextEditingController();
  // 基本走力の上限(1.8.5で素質の代わりに編集できるようにした。基本走力と同じ目盛り)
  final TextEditingController _joukaiController = TextEditingController();
  // 開いたときの基本走力と上限の値(欄を変えたかどうかを見るため。1.8.5)
  int? _kihonShokiti;
  int? _joukaiShokiti;
  // 区間の見込みタイムを出す大会と区間(0が1区。1.8.8)
  int _mikomiRace = 2;
  int _mikomiKukan = 0;

  @override
  void initState() {
    super.initState();
    _senshuBox = Hive.box<SenshuData>('senshuBox');
    _loadSenshuData();
    // 理論値の欄を、入力に合わせてその場で計算し直す(1.8.5)
    // (区間の見込みタイムに効く調子・登り・下り・アップダウンも。1.8.8)
    for (final TextEditingController c in [
      _baseAbilityAController,
      _joukaiController,
      _choukyorinebariController,
      _spurtryokuController,
      _tandokusouController,
      _paceagesagetaiouryokuController,
      _chousiController,
      _noboritekiseiController,
      _kudaritekiseiController,
      _noborikudarikirikaenouryokuController,
    ]) {
      c.addListener(_rironchiKoushin);
    }
  }

  void _rironchiKoushin() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final TextEditingController c in [
      _chousiController,
      _anteikanController,
      _konjouController,
      _heijousinController,
      _choukyorinebariController,
      _spurtryokuController,
      _karisumaController,
      _noboritekiseiController,
      _kudaritekiseiController,
      _noborikudarikirikaenouryokuController,
      _tandokusouController,
      _paceagesagetaiouryokuController,
      _baseAbilityAController,
      _joukaiController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadSenshuData() {
    final senshu = _senshuBox.get(widget.senshuId);
    if (senshu != null) {
      _editingSenshu = senshu;
      _selectedMenu = senshu.kaifukuryoku;
      _chousiController.text = senshu.chousi.toString();
      _anteikanController.text = senshu.anteikan.toString();
      _konjouController.text = senshu.konjou.toString();
      _heijousinController.text = senshu.heijousin.toString();
      _choukyorinebariController.text = senshu.choukyorinebari.toString();
      _spurtryokuController.text = senshu.spurtryoku.toString();
      _karisumaController.text = senshu.karisuma.toString();
      _noboritekiseiController.text = senshu.noboritekisei.toString();
      _kudaritekiseiController.text = senshu.kudaritekisei.toString();
      _noborikudarikirikaenouryokuController.text = senshu
          .noborikudarikirikaenouryoku
          .toString();
      _tandokusouController.text = senshu.tandokusou.toString();
      _paceagesagetaiouryokuController.text = senshu.paceagesagetaiouryoku
          .toString();

      int newbint = 1550;
      int b_int = (senshu.b * 10000.0).round();
      int a_int = (senshu.a * 1000000000.0).round();
      int a_min_int =
          (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER)
              .round();
      int sa = a_int - a_min_int;
      int new_a_min_int =
          (newbint * newbint * 0.0333 - newbint * 114.25 + TEISUU.MAGICNUMBER)
              .round();

      int aInt = new_a_min_int + sa;
      _baseAbilityAController.text = (aInt + 300).toString();
      _kihonShokiti = aInt + 300;
      _joukaiShokiti = joukaiHyouji(senshu.magicnumber);
      _joukaiController.text = _joukaiShokiti.toString();
    }
  }

  /// 保存したときの基本走力の上限(magicnumber)(1.8.5)
  /// [joukai]は上限の欄の値(小さいほど速い目盛り)
  /// ・上限の欄を変えたとき: 入力した上限
  /// ・上限の欄を変えていないとき: 今の上限のまま(目盛りの値に直すときの端数で、保存のたびにずれないように)
  /// (基本走力が上限より速い入力は、_kihonJoukaiMujun で保存の前に止める。
  /// 1.8.4までは、基本走力を上限より速くすると上限を黙って基本走力−25に動かしていたが、
  /// 入力と違う値で保存されて分かりにくいので、やめた)
  double _hozonJoukaiMagicnumber(int joukai) {
    if (joukai == _joukaiShokiti) return _editingSenshu!.magicnumber;
    return magicnumberFromJoukaiHyouji(joukai);
  }

  /// 基本走力が上限より小さい(速い)入力になっているか(1.8.5)
  /// 上限は基本走力が伸びていく先なので、基本走力が上限より速いことは本来ない(同じ値はよい)。
  /// 基本走力と上限の欄をどちらも変えていないときは見ない
  /// (開いたままの値は、目盛りの値に直すときの端数で1だけずれることがあるため)
  bool _kihonJoukaiMujun(int kihon, int joukai) {
    if (kihon == _kihonShokiti && joukai == _joukaiShokiti) return false;
    return kihon < joukai;
  }

  /// 基本走力が上限より小さい(速い)入力のあいだ、上限の欄の下に出す注意(1.8.5)
  Widget _buildMujunChuui() {
    final int? kihon = int.tryParse(_baseAbilityAController.text.trim());
    final int? joukai = int.tryParse(_joukaiController.text.trim());
    if (kihon == null || joukai == null || !_kihonJoukaiMujun(kihon, joukai)) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        '基本走力が上限より小さく(速く)なっています。このままでは保存できません。',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: HENSUU.fontsize_honbun - 2,
        ),
      ),
    );
  }

  /// 説明書きの行(1.8.5)
  Widget _buildSetsumei(List<String> gyou) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final String g in gyou)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              g,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: HENSUU.fontsize_honbun - 2,
              ),
            ),
          ),
      ],
    );
  }

  /// 理論値の時間の書き方(選手画面の持ちタイムと同じ「分秒」)(1.8.5)
  String _rironTimeString(double time) {
    final int minutes = time ~/ 60;
    final int seconds = (time % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
  }

  /// 理論値の欄(1.8.5)
  /// 入力中の値から、今の基本走力と上限に届いたときの、平地の記録会の理論値を出す
  /// (計算は riron_kirokukai_time.dart。入力が数値でない欄があるときは「−」)
  Widget _buildRironchi(List<UnivData> sortedUnivData) {
    final int? kihon = int.tryParse(_baseAbilityAController.text.trim());
    final int? joukai = int.tryParse(_joukaiController.text.trim());
    final int? nebari = int.tryParse(_choukyorinebariController.text.trim());
    final int? spurt = int.tryParse(_spurtryokuController.text.trim());
    final int? road = int.tryParse(_tandokusouController.text.trim());
    final int? pace = int.tryParse(
      _paceagesagetaiouryokuController.text.trim(),
    );
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    final SenshuData senshu = _editingSenshu!;
    // 上限に届いたときの基本走力(保存したときの上限)
    // (基本走力が上限より速い入力のあいだは保存できないので「−」にする)
    final int? joukaiKihon =
        (kihon == null || joukai == null || _kihonJoukaiMujun(kihon, joukai))
        ? null
        : joukaiHyouji(_hozonJoukaiMagicnumber(joukai));

    String timeMojiretsu(int? kihonHyouji, double kyori) {
      if (kihonHyouji == null ||
          nebari == null ||
          spurt == null ||
          road == null ||
          pace == null ||
          kantoku == null) {
        return '−';
      }
      final double time = rironKirokukaiTime(
        kyori: kyori,
        kihonSouryokuHyouji: kihonHyouji,
        choukyorinebari: nebari,
        spurtryoku: spurt,
        tandokusou: road,
        paceagesagetaiouryoku: pace,
        univid: senshu.univid,
        ryuugakusei: senshu.hirou == 1,
        trainingNum: _selectedMenu ?? senshu.kaifukuryoku,
        kantoku: kantoku,
        choukyoriTimeHosei: sortedUnivData[9].name_tanshuku == "1",
      );
      return _rironTimeString(time);
    }

    const TextStyle midasiStyle = TextStyle(
      color: Colors.white70,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    // スマホの幅でも「62分40秒」が1行に収まるように、少し小さい字にする
    const TextStyle atai = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    TableRow gyou(String label, int? kihonHyouji) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(label, style: midasiStyle),
          ),
          for (final double kyori in rironKirokukaiKyori)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(timeMojiretsu(kihonHyouji, kyori), style: atai),
            ),
        ],
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      children: [
        const TableRow(
          children: [
            Text('', style: midasiStyle),
            Text('5000m', style: midasiStyle),
            Text('1万m', style: midasiStyle),
            Text('ハーフ', style: midasiStyle),
          ],
        ),
        gyou('今の基本走力', kihon),
        gyou('上限に届いたとき', joukaiKihon),
      ],
    );
  }

  // ------------------------------------------------------------
  // 区間の見込みタイム(1.8.8)
  // 好きな駅伝(予選も)の区間を、入力中の値で走ったときの見込みタイムを出す。
  // 計算は「指示ごとの損得予測」の見込みタイムと同じ(TrialTime.dart の試走タイムの計算に、
  // 駅伝では経験補正と調子補正を足す。乱数で濁さない)。
  // 指示の成否・目標順位による悪化・1区と予選の集団走は、本番でその場で決まるので含めない。
  // 参考に、全大学の区間記録(と、記録を持っているのが留学生なら日本人最高記録)との差も出す
  // (区間記録は1位だけ保存している)
  // ------------------------------------------------------------

  /// 見込みタイムを出せる大会(カスタム駅伝は開催する設定のときだけ)
  List<int> _mikomiRaceList(Ghensuu gh) => [
    0,
    1,
    2,
    if (gh.spurtryokuseichousisuu1 == 1) 5,
    3,
    4,
  ];

  /// 大会の名前(カスタム駅伝は設定した名前)
  String _mikomiRaceMei(int race, List<UnivData> sortedUnivData) {
    switch (race) {
      case 0:
        return '10月駅伝';
      case 1:
        return '11月駅伝';
      case 2:
        return '正月駅伝';
      case 3:
        return '11月駅伝予選';
      case 4:
        return '正月駅伝予選';
      case 5:
        return sortedUnivData.isNotEmpty && sortedUnivData[0].name_tanshuku.isNotEmpty
            ? sortedUnivData[0].name_tanshuku
            : 'カスタム駅伝';
      default:
        return '駅伝';
    }
  }

  /// 見込みタイムの計算に使う、入力中の値を入れた選手の写し(保存はしない)
  /// [kihonHyouji]は基本走力の目盛りの値。数値でない欄があるときはnull
  SenshuData? _mikomiSenshu(int? kihonHyouji) {
    if (kihonHyouji == null) return null;
    final int? chousi = int.tryParse(_chousiController.text.trim());
    final int? nebari = int.tryParse(_choukyorinebariController.text.trim());
    final int? spurt = int.tryParse(_spurtryokuController.text.trim());
    final int? nobori = int.tryParse(_noboritekiseiController.text.trim());
    final int? kudari = int.tryParse(_kudaritekiseiController.text.trim());
    final int? updown = int.tryParse(
      _noborikudarikirikaenouryokuController.text.trim(),
    );
    final int? road = int.tryParse(_tandokusouController.text.trim());
    final int? pace = int.tryParse(
      _paceagesagetaiouryokuController.text.trim(),
    );
    if (chousi == null ||
        nebari == null ||
        spurt == null ||
        nobori == null ||
        kudari == null ||
        updown == null ||
        road == null ||
        pace == null) {
      return null;
    }
    final SenshuData t = SenshuData.fromJson(_editingSenshu!.toJson());
    t
      ..kaifukuryoku = _selectedMenu ?? t.kaifukuryoku
      ..chousi = chousi
      ..choukyorinebari = nebari
      ..spurtryoku = spurt
      ..noboritekisei = nobori
      ..kudaritekisei = kudari
      ..noborikudarikirikaenouryoku = updown
      ..tandokusou = road
      ..paceagesagetaiouryoku = pace
      // 保存するときと同じ書き方(b=1550の目盛り。上限は計算の中で打ち消し合うので元のまま)
      ..a = (kihonHyouji - 300) * 0.000000001
      ..b = 1550 / 10000;
    return t;
  }

  /// タイム差の書き方(例: +1分02秒、-12秒)
  String _saMojiretsu(double sa) {
    final String fugou = sa < 0 ? '-' : '+';
    final int byou = sa.abs().round();
    if (byou < 60) return '$fugou$byou秒';
    return '$fugou${byou ~/ 60}分${(byou % 60).toString().padLeft(2, '0')}秒';
  }

  Widget _buildMikomi(List<UnivData> sortedUnivData) {
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Ghensuu? gh =
        ghensuuBox.get('global_ghensuu') ??
        (ghensuuBox.isNotEmpty ? ghensuuBox.getAt(0) : null);
    final KantokuData? kantoku = Hive.box<KantokuData>(
      'kantokuBox',
    ).get('KantokuData');
    if (gh == null || kantoku == null) return const SizedBox.shrink();

    final List<int> raceList = _mikomiRaceList(gh);
    final int race = raceList.contains(_mikomiRace) ? _mikomiRace : 2;
    final int kukansuu = gh.kukansuu_taikaigoto[race];
    if (kukansuu <= 0) return const SizedBox.shrink();
    final int kukan = _mikomiKukan < kukansuu ? _mikomiKukan : 0;
    final String kuMei = race == 3 ? '組' : '区';

    // 見込みタイム([kihonHyouji]の基本走力で走ったとき)
    double? mikomi(int? kihonHyouji) {
      final SenshuData? t = _mikomiSenshu(kihonHyouji);
      if (t == null) return null;
      double time = trialTimeKeisan(
        0,
        kukan,
        gh,
        [t],
        sortedUnivData,
        kantoku,
        nigosu: false,
        keikenHosei: true,
        racebangou: race,
      );
      // 調子補正は駅伝だけ(本番と同じ。予選にはない)
      if (race <= 2 || race == 5) time *= chousiHoseiBairitsu(t, kantoku);
      return time;
    }

    final int? kihon = int.tryParse(_baseAbilityAController.text.trim());
    final int? joukai = int.tryParse(_joukaiController.text.trim());
    final int? joukaiKihon =
        (kihon == null || joukai == null || _kihonJoukaiMujun(kihon, joukai))
        ? null
        : joukaiHyouji(_hozonJoukaiMagicnumber(joukai));
    final double? imaTime = mikomi(kihon);
    final double? joukaiTime = mikomi(joukaiKihon);

    // 区間記録(全体)と、日本人最高記録(全体の記録を持っているのが留学生のときだけ出す)
    double? kirokuTime;
    String kirokuHito = '';
    if (gh.time_zentaikukankiroku.length > race &&
        gh.time_zentaikukankiroku[race].length > kukan &&
        gh.time_zentaikukankiroku[race][kukan].isNotEmpty) {
      final double t = gh.time_zentaikukankiroku[race][kukan][0];
      if (t > 0 && t < TEISUU.DEFAULTTIME) {
        kirokuTime = t;
        kirokuHito =
            '${gh.name_zentaikukankiroku[race][kukan][0]}(${gh.univname_zentaikukankiroku[race][kukan][0]}大 ${gh.gakunen_zentaikukankiroku[race][kukan][0]}年)';
      }
    }
    double? japTime;
    String japHito = '';
    final Kiroku? kiroku = Hive.box<Kiroku>('kirokuBox').get('KirokuData');
    if (kiroku != null &&
        kiroku.time_zentai_jap_kukankiroku.length > race &&
        kiroku.time_zentai_jap_kukankiroku[race].length > kukan &&
        kiroku.time_zentai_jap_kukankiroku[race][kukan].isNotEmpty) {
      final double t = kiroku.time_zentai_jap_kukankiroku[race][kukan][0];
      if (t > 0 &&
          t < TEISUU.DEFAULTTIME &&
          kirokuTime != null &&
          t > kirokuTime) {
        japTime = t;
        japHito =
            '${kiroku.name_zentai_jap_kukankiroku[race][kukan][0]}(${kiroku.univname_zentai_jap_kukankiroku[race][kukan][0]}大 ${kiroku.gakunen_zentai_jap_kukankiroku[race][kukan][0]}年)';
      }
    }

    // 下の文の組み立て(関数の中)で型が絞り込まれるように、final に入れ直す
    final double? kirokuT = kirokuTime;
    final double? japT = japTime;

    const TextStyle midasiStyle = TextStyle(
      color: Colors.white70,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    const TextStyle atai = TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    const TextStyle dropStyle = TextStyle(
      color: HENSUU.LinkColor,
      fontSize: HENSUU.fontsize_honbun,
    );

    Widget gyou(String label, double? time) {
      String bun = time == null ? '−' : _rironTimeString(time);
      if (time != null) {
        final List<String> sa = [
          if (kirokuT != null) '区間記録${_saMojiretsu(time - kirokuT)}',
          if (japT != null) '日本人最高${_saMojiretsu(time - japT)}',
        ];
        if (sa.isNotEmpty) bun += '(${sa.join('、')})';
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: midasiStyle),
            Text(bun, style: atai),
          ],
        ),
      );
    }

    // 選んだ区間のコースの特徴(コース詳細と同じ指標。登り指数=登り距離割合×平均勾配(絶対値)×10000)
    final int noboriSisuu =
        (gh.kyoriwariainobori_taikai_kukangoto[race][kukan] *
                gh.heikinkoubainobori_taikai_kukangoto[race][kukan].abs() *
                10000)
            .round();
    final int kudariSisuu =
        (gh.kyoriwariaikudari_taikai_kukangoto[race][kukan] *
                gh.heikinkoubaikudari_taikai_kukangoto[race][kukan].abs() *
                10000)
            .round();
    final String courseBun =
        '距離${gh.kyori_taikai_kukangoto[race][kukan].round()}m '
        '登り指数$noboriSisuu 下り指数$kudariSisuu '
        'アップダウン${gh.noborikudarikirikaekaisuu_taikai_kukangoto[race][kukan]}回';

    // 大会と区間のドロップダウンは、文字を大きくしていても距離まで入るように、縦に並べて横幅いっぱいにする
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<int>(
          value: race,
          isExpanded: true,
          dropdownColor: HENSUU.backgroundcolor,
          style: dropStyle,
          items: [
            for (final int r in raceList)
              DropdownMenuItem<int>(
                value: r,
                child: Text(_mikomiRaceMei(r, sortedUnivData)),
              ),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _mikomiRace = val;
              if (_mikomiKukan >= gh.kukansuu_taikaigoto[val]) {
                _mikomiKukan = 0;
              }
            });
          },
        ),
        DropdownButton<int>(
          value: kukan,
          isExpanded: true,
          dropdownColor: HENSUU.backgroundcolor,
          style: dropStyle,
          items: [
            for (int k = 0; k < kukansuu; k++)
              DropdownMenuItem<int>(
                value: k,
                child: Text(
                  '${k + 1}$kuMei(${gh.kyori_taikai_kukangoto[race][k].round()}m)',
                ),
              ),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() => _mikomiKukan = val);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: Text(courseBun, style: midasiStyle),
        ),
        gyou('今の基本走力', imaTime),
        gyou('上限に届いたとき', joukaiTime),
        const SizedBox(height: 4),
        Text(
          kirokuT == null
              ? '区間記録: 記録なし'
              : '区間記録: ${_rironTimeString(kirokuT)} $kirokuHito',
          style: midasiStyle,
        ),
        if (japT != null)
          Text(
            '日本人最高: ${_rironTimeString(japT)} $japHito',
            style: midasiStyle,
          ),
      ],
    );
  }

  /// 数値入力専用のフィールド（キーボードを数字に限定）
  Widget _buildNumberInputField(
    String label,
    TextEditingController controller,
    int min,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        // keyboardTypeをnumberにし、マイナス値を許容するためにsignedをtrueにする
        keyboardType: TextInputType.number,
        //keyboardType: const TextInputType.numberWithOptions(
        //  signed: true,
        //  decimal: false,
        //),
        inputFormatters: [
          // 数字とマイナス記号（1つ目のみ）を許可する正規表現
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        ],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: '$label ($min～$max)',
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    final fields = [
      {'label': '調子', 'ctrl': _chousiController, 'min': 0, 'max': 100},
      {'label': '安定感', 'ctrl': _anteikanController, 'min': 1, 'max': 99},
      {'label': '駅伝男', 'ctrl': _konjouController, 'min': 1, 'max': 99},
      {'label': '平常心', 'ctrl': _heijousinController, 'min': 1, 'max': 99},
      {
        'label': '長距離粘り',
        'ctrl': _choukyorinebariController,
        'min': 1,
        'max': 99,
      },
      {'label': 'スパート力', 'ctrl': _spurtryokuController, 'min': 1, 'max': 99},
      {'label': 'カリスマ', 'ctrl': _karisumaController, 'min': 1, 'max': 110},
      {'label': '登り適性', 'ctrl': _noboritekiseiController, 'min': 1, 'max': 99},
      {'label': '下り適性', 'ctrl': _kudaritekiseiController, 'min': 1, 'max': 99},
      {
        'label': 'アップダウン対応力',
        'ctrl': _noborikudarikirikaenouryokuController,
        'min': 1,
        'max': 99,
      },
      {'label': 'ロード適性', 'ctrl': _tandokusouController, 'min': 1, 'max': 99},
      {
        'label': 'ペース変動対応力',
        'ctrl': _paceagesagetaiouryokuController,
        'min': 1,
        'max': 99,
      },
      {'label': '基本走力', 'ctrl': _baseAbilityAController, 'min': 0, 'max': 6000},
      {'label': '上限', 'ctrl': _joukaiController, 'min': 0, 'max': 6000},
    ];

    for (var field in fields) {
      final String label = field['label'] as String;
      final TextEditingController ctrl = field['ctrl'] as TextEditingController;
      final int min = field['min'] as int;
      final int max = field['max'] as int;

      final String text = ctrl.text.trim();
      if (text.isEmpty) {
        _showErrorSnackBar('$labelを入力してください');
        return false;
      }

      final int? value = int.tryParse(text);
      if (value == null) {
        _showErrorSnackBar('$labelに正しい数値を入力してください');
        return false;
      }

      if (value < min || value > max) {
        _showErrorSnackBar('$labelは $min～$max の範囲で入力してください');
        return false;
      }
    }

    // 基本走力は上限より小さく(速く)できない(1.8.5)
    if (_kihonJoukaiMujun(
      int.parse(_baseAbilityAController.text.trim()),
      int.parse(_joukaiController.text.trim()),
    )) {
      _showErrorSnackBar('基本走力は上限と同じか、それより大きい値にしてください(上限より速くはなれません)');
      return false;
    }

    if (_selectedMenu == null) {
      _showErrorSnackBar('年間強化練習メニューを選択してください');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveData() async {
    if (_editingSenshu == null) return;
    if (!_validateFields()) return;

    int aIntInput = int.parse(_baseAbilityAController.text) - 300;
    int b_int = 1550;

    // 基本走力の上限(1.8.5で、素質の代わりに上限を編集できるようにした)
    double newMagicNumber = _hozonJoukaiMagicnumber(
      int.parse(_joukaiController.text.trim()),
    );

    double originalA = aIntInput * 0.000000001;
    double originalB = b_int / 10000;

    final updatedSenshu = _editingSenshu!
      ..kaifukuryoku = _selectedMenu!
      ..chousi = int.parse(_chousiController.text)
      ..anteikan = int.parse(_anteikanController.text)
      ..konjou = int.parse(_konjouController.text)
      ..heijousin = int.parse(_heijousinController.text)
      ..choukyorinebari = int.parse(_choukyorinebariController.text)
      ..spurtryoku = int.parse(_spurtryokuController.text)
      ..karisuma = int.parse(_karisumaController.text)
      ..noboritekisei = int.parse(_noboritekiseiController.text)
      ..kudaritekisei = int.parse(_kudaritekiseiController.text)
      ..noborikudarikirikaenouryoku = int.parse(
        _noborikudarikirikaenouryokuController.text,
      )
      ..tandokusou = int.parse(_tandokusouController.text)
      ..paceagesagetaiouryoku = int.parse(_paceagesagetaiouryokuController.text)
      ..a = originalA
      ..b = originalB
      ..magicnumber = newMagicNumber;

    try {
      await _senshuBox.put(widget.senshuId, updatedSenshu);
      // 学連選抜の選手なら、学連選抜用の写しにも書く(写しで走るため。1.8.8)
      await gakurenUtsushiNiHanei(updatedSenshu);
      if (!mounted) return;
      // 1. 念のため現在出ているスナックバーをすべてクリア
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選手能力を更新しました'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500), // ここで表示時間を短縮（0.8秒）
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('保存に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editingSenshu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          '${_editingSenshu!.name} の能力編集\n${sortedUnivData[_editingSenshu!.univid].name}大学 ${_editingSenshu!.gakunen}年',
          style: const TextStyle(fontSize: HENSUU.fontsize_honbun),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveData),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "年間強化練習",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _selectedMenu,
                dropdownColor: HENSUU.backgroundcolor,
                isExpanded: true,
                style: const TextStyle(
                  color: HENSUU.LinkColor,
                  fontSize: HENSUU.fontsize_honbun + 2,
                ),
                items: TrainingMenu.menuOptions.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedMenu = val);
                },
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "能力値関係",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildNumberInputField('調子', _chousiController, 0, 100),
              _buildNumberInputField('安定感', _anteikanController, 1, 99),
              _buildNumberInputField('駅伝男', _konjouController, 1, 99),
              _buildNumberInputField('平常心', _heijousinController, 1, 99),
              _buildNumberInputField(
                '長距離粘り',
                _choukyorinebariController,
                1,
                99,
              ),
              _buildNumberInputField('スパート力', _spurtryokuController, 1, 99),
              _buildNumberInputField('カリスマ', _karisumaController, 1, 110),
              _buildNumberInputField('登り適性', _noboritekiseiController, 1, 99),
              _buildNumberInputField('下り適性', _kudaritekiseiController, 1, 99),
              _buildNumberInputField(
                'アップダウン対応力',
                _noborikudarikirikaenouryokuController,
                1,
                99,
              ),
              _buildNumberInputField('ロード適性', _tandokusouController, 1, 99),
              _buildNumberInputField(
                'ペース変動対応力',
                _paceagesagetaiouryokuController,
                1,
                99,
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "基本走力関係\n(いずれも小さいほうが良い)",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildNumberInputField('基本走力', _baseAbilityAController, 0, 6000),
              _buildNumberInputField('上限', _joukaiController, 0, 6000),
              _buildMujunChuui(),
              _buildSetsumei(const [
                '・上限: 基本走力が伸びていく先の値です(小さいほど速い)。',
                '・基本走力が上限に届くと、育成のたびに限界突破の判定があり、成功すると上限が少し小さくなります。',
                '・基本走力は上限より小さく(速く)できません。もっと速くしたいときは、上限も小さくしてください。',
                '・選手を遅くしたいときは、基本走力と上限の両方を大きくしてください。',
              ]),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "理論値",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRironchi(sortedUnivData),
              const SizedBox(height: 8),
              _buildSetsumei(const [
                '・理論値: 平地の記録会で、運に左右されずに走ったときのタイムです。',
                '・大学の個性・年間強化練習・タイム調整など、記録会のタイムにかかる設定を含めて計算しています。',
                '・調子と、能力のタイムへの影響度(駅伝と駅伝予選だけにかかる設定)は含みません。',
                '・「上限に届いたとき」は、今の能力値のまま上限まで伸びたときのタイムです。',
              ]),
              // 区間の見込みタイム(1.8.8)
              const Divider(color: Colors.white24, height: 32),
              const Text(
                "区間の見込みタイム",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildMikomi(sortedUnivData),
              const SizedBox(height: 8),
              _buildSetsumei(const [
                '・選んだ区間を、指示なしで、目標順位ちょうどの位置で襷を受けて走ったときの見込みタイムです。',
                '・コースと能力、大学の個性・年間強化練習・能力のタイムへの影響度・タイム調整を含めて計算しています。',
                '・駅伝では、調子と、その区間を走った回数による経験補正も含みます(予選にはありません)。',
                '・指示の成否、目標順位による悪化、1区と予選の集団走の効果は含みません。',
                '・区間記録との差は、マイナスなら区間記録より速いことを表します。',
              ]),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('設定を保存する'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
