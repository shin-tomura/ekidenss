import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 調整値のコピーと貼り付け(2.1.4)
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // 💡 HENSUUなどの定数用
import 'package:ekiden/kantoku_data.dart'; // 💡 KantokuDataクラス用
import 'package:ekiden/ghensuu.dart'; // 💡 Ghensuuクラス用 (区間数取得用)
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/time_chousei_moji.dart'; // 調整値を1本の行で写す・読む(2.1.4)

class ModalTimeAdjustmentSettings extends StatefulWidget {
  const ModalTimeAdjustmentSettings({super.key});

  @override
  State<ModalTimeAdjustmentSettings> createState() =>
      _ModalTimeAdjustmentSettingsState();
}

class _ModalTimeAdjustmentSettingsState
    extends State<ModalTimeAdjustmentSettings> {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

  late KantokuData kantoku;
  Ghensuu? currentGhensuu;

  final univDataBox = Hive.box<UnivData>('univBox');

  // 💡 初期化完了フラグ
  bool _isInitialized = false;

  // 区間タイム調整データのインデックスを格納するリスト (racebangou順)
  // [30-39]:10月, [40-49]:11月, [50-59]:正月, [80-89]:カスタム
  // racebangou 0, 1, 2, 5 に対応
  final List<int> _raceBaseIndices = [30, 40, 50, 80];
  final List<String> _raceNames = ['10月駅伝', '11月駅伝', '正月駅伝', 'カスタム駅伝'];
  final List<int> _raceBangou = [0, 1, 2, 5]; // racebangou

  @override
  void initState() {
    super.initState();
    // Hiveデータの初期化は同期的に行う
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();
    currentGhensuu = ghensuuBox.getAt(0);
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    _raceNames[3] = sortedUnivData[0].name_tanshuku;

    // 非同期の初期化処理を呼び出す
    _initializeSettings();
  }

  /// 非同期の初期化処理 (initStateから分離)
  void _initializeSettings() async {
    // データがない場合のチェック
    if (currentGhensuu == null) {
      setState(() {
        _isInitialized = true; // エラーだが初期化完了扱いにして画面表示へ
      });
      return;
    }

    setState(() {
      _isInitialized = true; // 初期化完了
    });
  }

  /// タイム調整値 (`yobiint5`の特定インデックス) の値を変更し、Hiveに保存する関数
  ///
  /// @param index yobiint5のインデックス (例: 60 for 全体, 30-39 for 10月区間)
  /// @param newDoubleValue スライダーから渡される値 (-10.0 to +10.0)
  void _updateTimeAdjustmentValue(int index, double newDoubleValue) async {
    // スライダーの値はdoubleで来るため、最も近い整数に丸める
    final int newValue = newDoubleValue.round();

    // 調整範囲外への設定を防ぐ (-10から+10)
    if (newValue < -20 || newValue > 20) return;

    // setStateで値を更新し、Hiveにも保存
    setState(() {
      kantoku.yobiint5[index] = newValue;
    });

    await kantoku.save();
  }

  // ---- 調整値のコピーと貼り付け(2.1.4。行の形は kansuu/time_chousei_moji.dart) ----
  // ・「今の調整値をコピー」: 全体・区間ごとタイム調整と長距離タイム抑制設定を1本の行で写す
  // ・「貼り付けて設定」: コピーしてきた文の中の行を読み、変わる値を確かめてから変える
  //   (区間の数が違う駅伝は変えない。読み取れなければ何も変えない。長距離タイム抑制は行にあるときだけ変える)
  // ・「作者のおすすめの値を入れる」: 貼り付けと同じ確かめ方で、作者のおすすめの値を入れる(カスタム駅伝は変えない)

  /// 駅伝ごと(10月・11月・正月・カスタム)の今の区間数(画面と同じ。0〜10)
  List<int> _kukansuuIchiran() {
    return [
      for (final int racebangou in _raceBangou)
        () {
          int n = 0;
          try {
            n = currentGhensuu?.kukansuu_taikaigoto[racebangou] ?? 0;
          } catch (_) {
            n = 0;
          }
          return n < 0 ? 0 : (n > 10 ? 10 : n);
        }(),
    ];
  }

  /// 長距離タイム抑制設定のオン・オフを持つ大学データ(大学id 9。なければnull)
  UnivData? _univ9() {
    for (final UnivData u in univDataBox.values) {
      if (u.id == 9) return u;
    }
    return null;
  }

  void _shiraseru(String moji) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(moji)));
  }

  /// 今の調整値を1本の行でコピーする
  Future<void> _kopiSuru() async {
    final String moji = timeChouseiMoji(
      kantoku,
      _kukansuuIchiran(),
      _univ9()?.name_tanshuku == '1',
    );
    await Clipboard.setData(ClipboardData(text: moji));
    _shiraseru('今の調整値をコピーしました');
  }

  /// コピーしてきた文の中の行を読み、確かめてから設定する
  Future<void> _haritsukeru() async {
    // クリップボードを読めなかったときも、読み取れなかったとして扱う
    String text = '';
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text ?? '';
    } catch (_) {
      text = '';
    }
    final TimeChouseiYomi? y = timeChouseiYomu(text);
    if (y == null) {
      _shiraseru('読み取れませんでした(「$timeChouseiAtama」の行がないか、値が範囲の外です)');
      return;
    }
    await _kakuninShiteKaeru(
      y,
      motoMoji: '行',
      toi: '貼り付けた値に変えますか？',
      onajiMoji: '貼り付けた行と今の設定は同じなので、変わる値はありません',
      kaetaMoji: '貼り付けた値に変えました',
    );
  }

  /// 作者のおすすめの値(kansuu/time_chousei_moji.dart の timeChouseiOsusume)を、確かめてから入れる(2.1.4)
  Future<void> _osusumeIreru() async {
    await _kakuninShiteKaeru(
      timeChouseiOsusume,
      motoMoji: 'おすすめの値',
      toi: '作者のおすすめの値に変えますか？',
      onajiMoji: '今の設定は、作者のおすすめの値と同じです',
      kaetaMoji: '作者のおすすめの値に変えました',
      chuui: '区間ごとの値は、初期のコースの距離に合わせた値です(コースの距離を変えている駅伝には合わないことがあります)。カスタム駅伝の値は変えません。',
    );
  }

  /// 読み取った値[y]と今の設定を比べ、変わる値を確かめてから変える(貼り付けと作者のおすすめの値で共通)
  /// ([motoMoji] は区間の数が違うときの知らせの「行は6区間」の「行」。[chuui] は確認の窓に添える文)
  Future<void> _kakuninShiteKaeru(
    TimeChouseiYomi y, {
    required String motoMoji,
    required String toi,
    required String onajiMoji,
    required String kaetaMoji,
    String? chuui,
  }) async {
    final List<int> kukansuu = _kukansuuIchiran();
    final UnivData? u9 = _univ9();
    final bool imaOn = u9?.name_tanshuku == '1';
    final List<String> naiyou = [];
    int kawaruKazu = 0;
    // 全体
    final int imaZentai = kantoku.yobiint5[timeChouseiZentaiBangou];
    if (imaZentai != y.zentai) {
      kawaruKazu++;
      naiyou.add('全体: ${timeChouseiAtaiMoji(imaZentai)}% → ${timeChouseiAtaiMoji(y.zentai)}%');
    } else {
      naiyou.add('全体: ${timeChouseiAtaiMoji(imaZentai)}%(変わりません)');
    }
    // 駅伝ごと(値のない駅伝と、区間の数が違う駅伝は変えない)
    final List<bool> kaeru = [];
    for (int r = 0; r < timeChouseiRaceMidashi.length; r++) {
      final String mei = _raceNames[r];
      final List<int>? l = r < y.race.length ? y.race[r] : null;
      if (l == null) {
        kaeru.add(false);
        naiyou.add('$mei: 変えません');
        continue;
      }
      if (l.length != kukansuu[r]) {
        kaeru.add(false);
        naiyou.add('$mei: 区間の数が違うので変えません($motoMojiは${l.length}区間、今は${kukansuu[r]}区間)');
        continue;
      }
      int n = 0;
      for (int i = 0; i < kukansuu[r]; i++) {
        if (kantoku.yobiint5[timeChouseiRaceHajime[r] + i] != l[i]) n++;
      }
      kaeru.add(n > 0);
      kawaruKazu += n;
      naiyou.add(n > 0 ? '$mei: ${kukansuu[r]}区間のうち$n区間が変わります' : '$mei: 変わりません');
    }
    // 長距離タイム抑制設定(行にあるときだけ)
    bool yokuseiKawaru = false;
    final bool? on = y.yokuseiOn;
    if (on != null && u9 != null && on != imaOn) {
      yokuseiKawaru = true;
      naiyou.add('長距離タイム抑制補正: ${imaOn ? 'オン' : 'オフ'} → ${on ? 'オン' : 'オフ'}');
    }
    final int? atai = y.yokuseiAtai;
    if (atai != null && atai != kantoku.yobiint2[13]) {
      yokuseiKawaru = true;
      naiyou.add('長距離全体タイム抑制値: ${kantoku.yobiint2[13]} → $atai');
    }
    if (on == null && atai == null) {
      naiyou.add('長距離タイム抑制設定: 行にないので変えません');
    } else if (!yokuseiKawaru) {
      naiyou.add('長距離タイム抑制設定: 変わりません');
    }
    if (kawaruKazu == 0 && !yokuseiKawaru) {
      _shiraseru(onajiMoji);
      return;
    }
    if (!mounted) return;
    final bool? hai = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: HENSUU.backgroundcolor,
        title: Text(
          toi,
          style: const TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final String g in naiyou)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    g,
                    style: const TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun - 2),
                  ),
                ),
              if (yokuseiKawaru)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '長距離タイム抑制設定(別の画面の設定)も変わります。',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: HENSUU.fontsize_honbun - 2),
                  ),
                ),
              if (chuui != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chuui,
                    style: const TextStyle(color: Colors.white70, fontSize: HENSUU.fontsize_honbun - 2),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('やめる', style: TextStyle(color: HENSUU.LinkColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('変える', style: TextStyle(color: HENSUU.LinkColor)),
          ),
        ],
      ),
    );
    if (hai != true) return;
    setState(() {
      kantoku.yobiint5[timeChouseiZentaiBangou] = y.zentai;
      for (int r = 0; r < timeChouseiRaceMidashi.length; r++) {
        final List<int>? l = r < y.race.length ? y.race[r] : null;
        if (!kaeru[r] || l == null) continue;
        for (int i = 0; i < kukansuu[r]; i++) {
          kantoku.yobiint5[timeChouseiRaceHajime[r] + i] = l[i];
        }
      }
      if (atai != null) kantoku.yobiint2[13] = atai;
      if (on != null && u9 != null) u9.name_tanshuku = on ? '1' : '0';
    });
    await kantoku.save();
    if (on != null && u9 != null) await u9.save();
    _shiraseru(kaetaMoji);
  }

  /// タイム調整設定項目のスライダーウィジェットを生成
  Widget _buildTimeAdjustmentSlider({
    required String title,
    required int index, // kantoku.yobiint5のインデックス
  }) {
    // 現在の値を取得 (-10から+10)
    final int currentValue = kantoku.yobiint5[index];
    // 実際のパーセント調整値 (0.5%刻み)
    final double percentValue = currentValue.toDouble() / 2.0;

    // 値に応じた説明テキスト
    String effectDescription =
        '現在の調整: ${percentValue >= 0 ? '+' : ''}${percentValue.toStringAsFixed(1)}%';

    // 値に応じた色 (例: マイナス=赤, プラス=緑, 0=青)
    Color sliderColor;
    if (currentValue < 0) {
      sliderColor =
          Color.lerp(
            Colors.green[900],
            Colors.green[400],
            currentValue.abs() / 20.0,
          ) ??
          Colors.red;
    } else if (currentValue > 0) {
      sliderColor =
          Color.lerp(
            Colors.red[400],
            Colors.red[900],
            currentValue.abs() / 20.0,
          ) ??
          Colors.green;
    } else {
      sliderColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. タイトル行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 2. 現在の調整率行 (改行後の表示)
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            effectDescription,
            // 💡 ここでは左寄せ (start) にして、画面幅いっぱいに使います
            textAlign: TextAlign.left,
            style: TextStyle(
              color: sliderColor,
              fontSize: HENSUU.fontsize_honbun - 2, // タイトルより少し小さく
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 3. スライダー
        Slider(
          value: currentValue.toDouble(), // スライダーはdoubleを使用 (-10.0 to 10.0)
          min: -20,
          max: 20,
          divisions: 40, // -10から10まで21段階
          label: percentValue >= 0
              ? '+${percentValue.toStringAsFixed(1)}%'
              : '${percentValue.toStringAsFixed(1)}%',
          onChanged: (newValue) => _updateTimeAdjustmentValue(index, newValue),
          activeColor: sliderColor,
          inactiveColor: sliderColor.withOpacity(0.3),
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }

  /// 駅伝ごとの区間別スライダーリストを生成
  List<Widget> _buildRaceSectionSliders() {
    if (currentGhensuu == null) return []; // データがない場合は空リストを返す

    List<Widget> widgets = [];
    int raceIndex = 0;

    // 10月(0), 11月(1), 正月(2), カスタム(5) の順に処理
    for (int racebangou in _raceBangou) {
      final String raceName = _raceNames[raceIndex];
      final int baseIndex = _raceBaseIndices[raceIndex];

      // 区間数の取得 (racebangouに対応するkukansuu_taikaigotoのインデックス)
      int kukanCount = 0;
      try {
        kukanCount = currentGhensuu!.kukansuu_taikaigoto[racebangou];
      } catch (e) {
        // インデックスエラー等の場合のフォールバック (例えば10区間とする)
        kukanCount = 10;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            '⏱️ ${raceName} 区間別タイム調整 (全${kukanCount}区間)',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun + 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

      for (int kukan = 0; kukan < kukanCount; kukan++) {
        final int index = baseIndex + kukan; // 例: 10月1区は30+0=30
        widgets.add(
          _buildTimeAdjustmentSlider(title: '第${kukan + 1}区 調整', index: index),
        );
      }
      widgets.add(const SizedBox(height: 24));
      raceIndex++;
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // 💡 初期化が完了するまでローディング表示、またはデータがない場合のエラー表示
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '⏱️ タイム調整設定',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentGhensuu == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '⏱️ タイム調整設定',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('データがありません', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // ValueListenableBuilderでHiveの変更を監視し、画面に反映
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: kantokuBox.listenable(),
      builder: (context, box, _) {
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '⏱️ タイム調整設定',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // 💡 説明文
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      "全てのタイムや、各駅伝の区間ごとのタイムを調整できます。調整値は -10.0%から+10.0%(0.5%刻み)で、マイナスがタイム良化、プラスがタイム悪化となります。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 今の調整値のコピーと、貼り付けて設定(2.1.4。文字を大きくしても入るように折り返して並べる)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _kopiSuru,
                          icon: const Icon(Icons.copy, size: 18, color: HENSUU.LinkColor),
                          label: Text(
                            '今の調整値をコピー',
                            style: TextStyle(color: HENSUU.LinkColor, fontSize: HENSUU.fontsize_honbun - 2),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _haritsukeru,
                          icon: const Icon(Icons.content_paste, size: 18, color: HENSUU.LinkColor),
                          label: Text(
                            '貼り付けて設定',
                            style: TextStyle(color: HENSUU.LinkColor, fontSize: HENSUU.fontsize_honbun - 2),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _osusumeIreru,
                          icon: const Icon(Icons.star_border, size: 18, color: HENSUU.LinkColor),
                          label: Text(
                            '作者のおすすめの値を入れる',
                            style: TextStyle(color: HENSUU.LinkColor, fontSize: HENSUU.fontsize_honbun - 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      '全体・区間ごとタイム調整と長距離タイム抑制設定を、1本の行で写せます。写した行(前後に文が付いていてもかまいません)をコピーしてから「貼り付けて設定」を押すと、確かめてから同じ設定にできます。区間の数が違う駅伝は変わりません。\n「作者のおすすめの値を入れる」を押すと、確かめてから、作者が初期のコースで30年進めて、個人の種目と各区間の最速タイムの水準を整えた値にできます(長距離タイム抑制設定も、オン・抑制値0にします)。カスタム駅伝の値は変わりません。',
                      style: TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun - 2),
                    ),
                  ),

                  // 1. 全体タイム調整 (yobiint5[60])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '🌎 全体タイム調整',
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun + 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _buildTimeAdjustmentSlider(title: '全体タイム調整', index: 60),

                  const SizedBox(height: 32),

                  // 2. 駅伝ごとの区間タイム調整
                  ..._buildRaceSectionSliders(),

                  const SizedBox(height: 32),
                  // 💡 補足文
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      "※駅伝の各区間のタイム調整は、全体タイム調整+各区間のタイム調整になります。例えば、全体タイム調整が+3.0%で区間の調整が-2.0%の場合には+1.0%のタイム調整となります。\n\n長距離タイム抑制の補正よりも前に、このタイム調整による補正がかかります。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(200, 48),
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: Text(
                      "閉じる",
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
