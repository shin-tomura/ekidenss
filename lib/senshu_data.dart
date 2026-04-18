import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/shareable_senshu_data.dart'; // 追記
part 'senshu_data.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 0) // ユニークなtypeIdを指定 (SenshuDataは0、UnivDataは1、Ghensuuは2)
class SenshuData extends HiveObject {
  @HiveField(0)
  int id; // @Attribute(.unique)に対応。Hiveはキーでユニーク性を担保するため、ここではフィールドに設定

  @HiveField(1)
  int univid;
  @HiveField(2)
  int gakunen;
  @HiveField(3)
  String name;
  @HiveField(4)
  String name_tanshuku;
  @HiveField(5)
  double magicnumber;
  @HiveField(6)
  double a;
  @HiveField(7)
  double b;
  @HiveField(8)
  int sositu;
  @HiveField(9)
  int sositu_bonus;
  @HiveField(10)
  int seichoutype;
  @HiveField(11)
  int genkaitoppakaisuu;
  @HiveField(12)
  int seichoukaisuu;
  @HiveField(13)
  int genkaichokumenkaisuu;
  @HiveField(14)
  int mokuhyo_b;
  @HiveField(15)
  double rirontime5000;
  @HiveField(16)
  double rirontime10000;
  @HiveField(17)
  double rirontimehalf;
  @HiveField(18)
  double kiroku_nyuugakuji_5000;
  @HiveField(19)
  List<double> time_bestkiroku;
  @HiveField(20)
  List<int> year_bestkiroku;
  @HiveField(21)
  List<int> month_bestkiroku;
  //var day_bestkiroku:[Int]=Array(repeating:0, count:TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  @HiveField(22)
  List<int> zentaijuni_bestkiroku;
  @HiveField(23)
  List<int> gakunaijuni_bestkiroku;
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(24)
  int konjou; //0
  @HiveField(25)
  int heijousin; //1
  @HiveField(26)
  int choukyorinebari; //2
  @HiveField(27)
  int spurtryoku; //3
  @HiveField(28)
  int kegaflag; //交渉成功確率として使用している
  @HiveField(29)
  int hirou; //留学生フラグとして使用している
  @HiveField(30)
  int kaifukuryoku; //練習メニュー
  @HiveField(31)
  int anteikan;
  @HiveField(32)
  int chousi;
  @HiveField(33)
  int karisuma; //4
  @HiveField(34)
  int kazetaisei; //これを当日変更を前提にした区間配置ロジックで使用する圧縮・解凍用の格納場所として流用
  @HiveField(35)
  int atusataisei; //レーダーチャート表示用各指標格納用
  @HiveField(36)
  int samusataisei; //出身地と趣味
  @HiveField(37)
  int noboritekisei; //5
  @HiveField(38)
  int kudaritekisei; //6
  @HiveField(39)
  int noborikudarikirikaenouryoku; //7
  @HiveField(40)
  int tandokusou; //8
  @HiveField(41)
  int paceagesagetaiouryoku; //9
  @HiveField(42)
  List<List<int>> entrykukan_race;
  @HiveField(43)
  List<List<int>> kukanjuni_race;
  @HiveField(44)
  List<List<double>> kukantime_race;
  //[レース番号][学年(0→1年、3→4年)]
  //レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  //5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  //10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  //var time_taikai_1km:[Double]=Array(repeating:0.0, count:TEISUU.SUU_MAXKYORI)
  @HiveField(45)
  double time_taikai_total;
  @HiveField(46)
  double speed;

  @HiveField(47)
  int sijiflag;
  @HiveField(48)
  int sijiseikouflag;
  @HiveField(49)
  int startchokugotobidasiflag;
  @HiveField(50)
  int startchokugotobidasiseikouflag;

  @HiveField(51)
  int racechuukakuseiflag;

  @HiveField(52)
  List<int> kukannaijuni;
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(53)
  int temp_juni;
  @HiveField(54)
  int chokuzentaikai_pbflag;
  @HiveField(55)
  int chokuzentaikai_kojinrekidaisinflag;
  @HiveField(56)
  int chokuzentaikai_kojinunivsinflag;
  @HiveField(57)
  int chokuzentaikai_zentaikukansinflag;
  //var chokuzentaikai_zentai1nenseikukansinflag:Int=0
  @HiveField(58)
  int chokuzentaikai_univkukansinflag;
  //var chokuzentaikai_univ1nenseikukansinflag:Int=0
  @HiveField(59)
  String string_racesetumei;

  // Swiftのinit(id:Int,univid:Int,gakunen:Int)に対応するDartコンストラクタ
  // Hiveがアダプタ生成に使用するため、すべての@HiveFieldに対応するフィールドの初期化が必要です。
  // Dartの必須引数`required`を使って、id, univid, gakunenの初期化を強制します。
  SenshuData({
    required this.id,
    required this.univid,
    required this.gakunen,
    this.name = "ダミー選手", // デフォルト値を持つプロパティはオプション引数に
    this.name_tanshuku = "短縮",
    this.magicnumber = TEISUU.MAGICNUMBER,
    this.a = 0.0,
    this.b = 0.0,
    this.sositu = 0,
    this.sositu_bonus = 0,
    this.seichoutype = 0,
    this.genkaitoppakaisuu = 0,
    this.seichoukaisuu = 0,
    this.genkaichokumenkaisuu = 0,
    this.mokuhyo_b = 0,
    this.rirontime5000 = 0.0,
    this.rirontime10000 = 0.0,
    this.rirontimehalf = 0.0,
    this.kiroku_nyuugakuji_5000 = 0.0,
    // List型のプロパティはコンストラクタで初期化するか、factoryコンストラクタで初期化する必要があります
    // ここではfactoryコンストラクタで一括初期化するため、一旦空のリストを渡せるようにします
    List<double>? time_bestkiroku,
    List<int>? year_bestkiroku,
    List<int>? month_bestkiroku,
    List<int>? zentaijuni_bestkiroku,
    List<int>? gakunaijuni_bestkiroku,
    this.konjou = 0,
    this.heijousin = 0,
    this.choukyorinebari = 0,
    this.spurtryoku = 0,
    this.kegaflag = 0, //交渉成功率に流用
    this.hirou = 0, //留学生フラグに流用
    this.kaifukuryoku = 0,
    this.anteikan = 0,
    this.chousi = 0,
    this.karisuma = 0,
    this.kazetaisei = 0,
    this.atusataisei = 0,
    this.samusataisei = 0,
    this.noboritekisei = 0,
    this.kudaritekisei = 0,
    this.noborikudarikirikaenouryoku = 0,
    this.tandokusou = 0,
    this.paceagesagetaiouryoku = 0,
    List<List<int>>? entrykukan_race,
    List<List<int>>? kukanjuni_race,
    List<List<double>>? kukantime_race,
    this.time_taikai_total = 0.0,
    this.speed = 0.0,
    this.sijiflag = 0,
    this.sijiseikouflag = 0,
    this.startchokugotobidasiflag = 0,
    this.startchokugotobidasiseikouflag = 0,
    this.racechuukakuseiflag = 0,
    List<int>? kukannaijuni,
    this.temp_juni = 0,
    this.chokuzentaikai_pbflag = 0,
    this.chokuzentaikai_kojinrekidaisinflag = 0,
    this.chokuzentaikai_kojinunivsinflag = 0,
    this.chokuzentaikai_zentaikukansinflag = 0,
    this.chokuzentaikai_univkukansinflag = 0,
    this.string_racesetumei = "",
  }) : this.time_bestkiroku = time_bestkiroku ?? [],
       this.year_bestkiroku = year_bestkiroku ?? [],
       this.month_bestkiroku = month_bestkiroku ?? [],
       this.zentaijuni_bestkiroku = zentaijuni_bestkiroku ?? [],
       this.gakunaijuni_bestkiroku = gakunaijuni_bestkiroku ?? [],
       this.entrykukan_race = entrykukan_race ?? [],
       this.kukanjuni_race = kukanjuni_race ?? [],
       this.kukantime_race = kukantime_race ?? [],
       this.kukannaijuni = kukannaijuni ?? [];

  // --- 初期値を設定するためのファクトリコンストラクタ ---
  // main.dartからこのコンストラクタを呼び出すことで、すべてのプロパティが適切に初期化されます。
  factory SenshuData.initial({
    required int id,
    int univid = 0,
    int gakunen = 0,
  }) {
    return SenshuData(
      id: id,
      univid: univid, // デフォルト値
      gakunen: gakunen, // デフォルト値
      name: "ダミー選手",
      name_tanshuku: "短縮",
      magicnumber: TEISUU.MAGICNUMBER,
      a: 0.0,
      b: 0.0,
      sositu: 0,
      sositu_bonus: 0,
      seichoutype: 0,
      genkaitoppakaisuu: 0,
      seichoukaisuu: 0,
      genkaichokumenkaisuu: 0,
      mokuhyo_b: 0,
      rirontime5000: 0.0,
      rirontime10000: 0.0,
      rirontimehalf: 0.0,
      kiroku_nyuugakuji_5000: 0.0,
      time_bestkiroku: List.filled(TEISUU.SUU_KOJINBESTKIROKUSHURUISUU, 0.0),
      year_bestkiroku: List.filled(TEISUU.SUU_KOJINBESTKIROKUSHURUISUU, 0),
      month_bestkiroku: List.filled(TEISUU.SUU_KOJINBESTKIROKUSHURUISUU, 0),
      zentaijuni_bestkiroku: List.filled(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        0,
      ),
      gakunaijuni_bestkiroku: List.filled(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        0,
      ),
      konjou: 0,
      heijousin: 0,
      choukyorinebari: 0,
      spurtryoku: 0,
      kegaflag: 0,
      hirou: 0,
      kaifukuryoku: 0,
      anteikan: 0,
      chousi: 0,
      karisuma: 0,
      kazetaisei: 0,
      atusataisei: 0,
      samusataisei: 0,
      noboritekisei: 0,
      kudaritekisei: 0,
      noborikudarikirikaenouryoku: 0,
      tandokusou: 0,
      paceagesagetaiouryoku: 0,
      entrykukan_race: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.GAKUNENSUU, 0),
      ),
      kukanjuni_race: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.GAKUNENSUU, 0),
      ),
      kukantime_race: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.GAKUNENSUU, 0.0),
      ),
      time_taikai_total: 0.0,
      speed: 0.0,
      sijiflag: 0,
      sijiseikouflag: 0,
      startchokugotobidasiflag: 0,
      startchokugotobidasiseikouflag: 0,
      racechuukakuseiflag: 0,
      kukannaijuni: List.filled(TEISUU.SUU_KOJINBESTKIROKUSHURUISUU, 0),
      temp_juni: 0,
      chokuzentaikai_pbflag: 0,
      chokuzentaikai_kojinrekidaisinflag: 0,
      chokuzentaikai_kojinunivsinflag: 0,
      chokuzentaikai_zentaikukansinflag: 0,
      chokuzentaikai_univkukansinflag: 0,
      string_racesetumei: "",
    );
  }

  // このメソッドを追記します
  // 共有可能な選手データを生成する
  ShareableSenshuData toShareableData() {
    return ShareableSenshuData(
      gakunen: this.gakunen,
      name: this.name,
      magicnumber: this.magicnumber,
      a: this.a,
      b: this.b,
      sositu: this.sositu,
      sositu_bonus: this.sositu_bonus,
      seichoutype: this.seichoutype,
      genkaitoppakaisuu: this.genkaitoppakaisuu,
      seichoukaisuu: this.seichoukaisuu,
      genkaichokumenkaisuu: this.genkaichokumenkaisuu,
      mokuhyo_b: this.mokuhyo_b,
      rirontime5000: this.rirontime5000,
      rirontime10000: this.rirontime10000,
      rirontimehalf: this.rirontimehalf,
      kiroku_nyuugakuji_5000: this.kiroku_nyuugakuji_5000,
      time_bestkiroku: this.time_bestkiroku,
      year_bestkiroku: this.year_bestkiroku,
      month_bestkiroku: this.month_bestkiroku,
      konjou: this.konjou,
      heijousin: this.heijousin,
      choukyorinebari: this.choukyorinebari,
      spurtryoku: this.spurtryoku,
      kegaflag: this.kegaflag,
      hirou: this.hirou,
      kaifukuryoku: this.kaifukuryoku,
      anteikan: this.anteikan,
      chousi: this.chousi,
      karisuma: this.karisuma,
      kazetaisei: this.kazetaisei,
      atusataisei: this.atusataisei,
      samusataisei: this.samusataisei,
      noboritekisei: this.noboritekisei,
      kudaritekisei: this.kudaritekisei,
      noborikudarikirikaenouryoku: this.noborikudarikirikaenouryoku,
      tandokusou: this.tandokusou,
      paceagesagetaiouryoku: this.paceagesagetaiouryoku,
    );
  }

  // 小数点以下 10 桁で丸めるヘルパー関数
  double _roundDouble(double value) {
    // 10 桁を指定して丸め処理を実行
    return double.parse(value.toStringAsFixed(15)); // ★ここを 10 に修正★
  }

  // List<double> のすべての要素を丸めるヘルパー関数 (変更なし)
  List<double> _roundDoubleList(List<double> list) {
    return list.map((e) => _roundDouble(e)).toList();
  }

  // List<List<double>> のすべての要素を丸めるヘルパー関数 (変更なし)
  List<List<double>> _roundDoubleNestedList(List<List<double>> nestedList) {
    return nestedList.map((list) => _roundDoubleList(list)).toList();
  }

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (Double型の丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'univid': univid,
      'gakunen': gakunen,
      'name': name,
      'name_tanshuku': name_tanshuku,
      'magicnumber': _roundDouble(magicnumber), // ★修正★
      'a': _roundDouble(a), // ★修正★
      'b': _roundDouble(b), // ★修正★
      'sositu': sositu,
      'sositu_bonus': sositu_bonus,
      'seichoutype': seichoutype,
      'genkaitoppakaisuu': genkaitoppakaisuu,
      'seichoukaisuu': seichoukaisuu,
      'genkaichokumenkaisuu': genkaichokumenkaisuu,
      'mokuhyo_b': mokuhyo_b,
      'rirontime5000': _roundDouble(rirontime5000), // ★修正★
      'rirontime10000': _roundDouble(rirontime10000), // ★修正★
      'rirontimehalf': _roundDouble(rirontimehalf), // ★修正★
      'kiroku_nyuugakuji_5000': _roundDouble(kiroku_nyuugakuji_5000), // ★修正★
      'time_bestkiroku': _roundDoubleList(time_bestkiroku), // ★修正: リスト全体を丸める★
      'year_bestkiroku': year_bestkiroku,
      'month_bestkiroku': month_bestkiroku,
      'zentaijuni_bestkiroku': zentaijuni_bestkiroku,
      'gakunaijuni_bestkiroku': gakunaijuni_bestkiroku,
      'konjou': konjou,
      'heijousin': heijousin,
      'choukyorinebari': choukyorinebari,
      'spurtryoku': spurtryoku,
      'kegaflag': kegaflag,
      'hirou': hirou,
      'kaifukuryoku': kaifukuryoku,
      'anteikan': anteikan,
      'chousi': chousi,
      'karisuma': karisuma,
      'kazetaisei': kazetaisei,
      'atusataisei': atusataisei,
      'samusataisei': samusataisei,
      'noboritekisei': noboritekisei,
      'kudaritekisei': kudaritekisei,
      'noborikudarikirikaenouryoku': noborikudarikirikaenouryoku,
      'tandokusou': tandokusou,
      'paceagesagetaiouryoku': paceagesagetaiouryoku,
      'entrykukan_race': entrykukan_race,
      'kukanjuni_race': kukanjuni_race,
      'kukantime_race': _roundDoubleNestedList(
        kukantime_race,
      ), // ★修正: 2次元リスト全体を丸める★
      'time_taikai_total': _roundDouble(time_taikai_total), // ★修正★
      'speed': _roundDouble(speed), // ★修正★
      'sijiflag': sijiflag,
      'sijiseikouflag': sijiseikouflag,
      'startchokugotobidasiflag': startchokugotobidasiflag,
      'startchokugotobidasiseikouflag': startchokugotobidasiseikouflag,
      'racechuukakuseiflag': racechuukakuseiflag,
      'kukannaijuni': kukannaijuni,
      'temp_juni': temp_juni,
      'chokuzentaikai_pbflag': chokuzentaikai_pbflag,
      'chokuzentaikai_kojinrekidaisinflag': chokuzentaikai_kojinrekidaisinflag,
      'chokuzentaikai_kojinunivsinflag': chokuzentaikai_kojinunivsinflag,
      'chokuzentaikai_zentaikukansinflag': chokuzentaikai_zentaikukansinflag,
      'chokuzentaikai_univkukansinflag': chokuzentaikai_univkukansinflag,
      'string_racesetumei': string_racesetumei,
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'id': id,
      'univid': univid,
      'gakunen': gakunen,
      'name': name,
      'name_tanshuku': name_tanshuku,
      'magicnumber': magicnumber,
      'a': a,
      'b': b,
      'sositu': sositu,
      'sositu_bonus': sositu_bonus,
      'seichoutype': seichoutype,
      'genkaitoppakaisuu': genkaitoppakaisuu,
      'seichoukaisuu': seichoukaisuu,
      'genkaichokumenkaisuu': genkaichokumenkaisuu,
      'mokuhyo_b': mokuhyo_b,
      'rirontime5000': rirontime5000,
      'rirontime10000': rirontime10000,
      'rirontimehalf': rirontimehalf,
      'kiroku_nyuugakuji_5000': kiroku_nyuugakuji_5000,
      'time_bestkiroku': time_bestkiroku,
      'year_bestkiroku': year_bestkiroku,
      'month_bestkiroku': month_bestkiroku,
      'zentaijuni_bestkiroku': zentaijuni_bestkiroku,
      'gakunaijuni_bestkiroku': gakunaijuni_bestkiroku,
      'konjou': konjou,
      'heijousin': heijousin,
      'choukyorinebari': choukyorinebari,
      'spurtryoku': spurtryoku,
      'kegaflag': kegaflag,
      'hirou': hirou,
      'kaifukuryoku': kaifukuryoku,
      'anteikan': anteikan,
      'chousi': chousi,
      'karisuma': karisuma,
      'kazetaisei': kazetaisei,
      'atusataisei': atusataisei,
      'samusataisei': samusataisei,
      'noboritekisei': noboritekisei,
      'kudaritekisei': kudaritekisei,
      'noborikudarikirikaenouryoku': noborikudarikirikaenouryoku,
      'tandokusou': tandokusou,
      'paceagesagetaiouryoku': paceagesagetaiouryoku,
      'entrykukan_race': entrykukan_race,
      'kukanjuni_race': kukanjuni_race,
      'kukantime_race': kukantime_race,
      'time_taikai_total': time_taikai_total,
      'speed': speed,
      'sijiflag': sijiflag,
      'sijiseikouflag': sijiseikouflag,
      'startchokugotobidasiflag': startchokugotobidasiflag,
      'startchokugotobidasiseikouflag': startchokugotobidasiseikouflag,
      'racechuukakuseiflag': racechuukakuseiflag,
      'kukannaijuni': kukannaijuni,
      'temp_juni': temp_juni,
      'chokuzentaikai_pbflag': chokuzentaikai_pbflag,
      'chokuzentaikai_kojinrekidaisinflag': chokuzentaikai_kojinrekidaisinflag,
      'chokuzentaikai_kojinunivsinflag': chokuzentaikai_kojinunivsinflag,
      'chokuzentaikai_zentaikukansinflag': chokuzentaikai_zentaikukansinflag,
      'chokuzentaikai_univkukansinflag': chokuzentaikai_univkukansinflag,
      'string_racesetumei': string_racesetumei,
    };
  }*/

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory SenshuData.fromJson(Map<String, dynamic> json) {
    return SenshuData(
      id: json['id'] as int,
      univid: json['univid'] as int,
      gakunen: json['gakunen'] as int,
      name: json['name'] as String,
      name_tanshuku: json['name_tanshuku'] as String,
      magicnumber: json['magicnumber'] as double,
      a: json['a'] as double,
      b: json['b'] as double,
      sositu: json['sositu'] as int,
      sositu_bonus: json['sositu_bonus'] as int,
      seichoutype: json['seichoutype'] as int,
      genkaitoppakaisuu: json['genkaitoppakaisuu'] as int,
      seichoukaisuu: json['seichoukaisuu'] as int,
      genkaichokumenkaisuu: json['genkaichokumenkaisuu'] as int,
      mokuhyo_b: json['mokuhyo_b'] as int,
      rirontime5000: json['rirontime5000'] as double,
      rirontime10000: json['rirontime10000'] as double,
      rirontimehalf: json['rirontimehalf'] as double,
      kiroku_nyuugakuji_5000: json['kiroku_nyuugakuji_5000'] as double,
      time_bestkiroku: (json['time_bestkiroku'] as List).cast<double>(),
      year_bestkiroku: (json['year_bestkiroku'] as List).cast<int>(),
      month_bestkiroku: (json['month_bestkiroku'] as List).cast<int>(),
      zentaijuni_bestkiroku: (json['zentaijuni_bestkiroku'] as List)
          .cast<int>(),
      gakunaijuni_bestkiroku: (json['gakunaijuni_bestkiroku'] as List)
          .cast<int>(),
      konjou: json['konjou'] as int,
      heijousin: json['heijousin'] as int,
      choukyorinebari: json['choukyorinebari'] as int,
      spurtryoku: json['spurtryoku'] as int,
      kegaflag: json['kegaflag'] as int,
      hirou: json['hirou'] as int,
      kaifukuryoku: json['kaifukuryoku'] as int,
      anteikan: json['anteikan'] as int,
      chousi: json['chousi'] as int,
      karisuma: json['karisuma'] as int,
      kazetaisei: json['kazetaisei'] as int,
      atusataisei: json['atusataisei'] as int,
      samusataisei: json['samusataisei'] as int,
      noboritekisei: json['noboritekisei'] as int,
      kudaritekisei: json['kudaritekisei'] as int,
      noborikudarikirikaenouryoku: json['noborikudarikirikaenouryoku'] as int,
      tandokusou: json['tandokusou'] as int,
      paceagesagetaiouryoku: json['paceagesagetaiouryoku'] as int,

      // List<List<int>> のデシリアライズ
      entrykukan_race: (json['entrykukan_race'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      kukanjuni_race: (json['kukanjuni_race'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      // List<List<double>> のデシリアライズ
      kukantime_race: (json['kukantime_race'] as List)
          .map((e) => (e as List).cast<double>())
          .toList(),

      time_taikai_total: json['time_taikai_total'] as double,
      speed: json['speed'] as double,
      sijiflag: json['sijiflag'] as int,
      sijiseikouflag: json['sijiseikouflag'] as int,
      startchokugotobidasiflag: json['startchokugotobidasiflag'] as int,
      startchokugotobidasiseikouflag:
          json['startchokugotobidasiseikouflag'] as int,
      racechuukakuseiflag: json['racechuukakuseiflag'] as int,
      kukannaijuni: (json['kukannaijuni'] as List).cast<int>(),
      temp_juni: json['temp_juni'] as int,
      chokuzentaikai_pbflag: json['chokuzentaikai_pbflag'] as int,
      chokuzentaikai_kojinrekidaisinflag:
          json['chokuzentaikai_kojinrekidaisinflag'] as int,
      chokuzentaikai_kojinunivsinflag:
          json['chokuzentaikai_kojinunivsinflag'] as int,
      chokuzentaikai_zentaikukansinflag:
          json['chokuzentaikai_zentaikukansinflag'] as int,
      chokuzentaikai_univkukansinflag:
          json['chokuzentaikai_univkukansinflag'] as int,
      string_racesetumei: json['string_racesetumei'] as String,
    );
  }
}
