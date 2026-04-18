import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'univ_data.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 1) // ユニークなtypeIdを指定 (SenshuDataが0なのでUnivDataは1)
class UnivData extends HiveObject {
  @HiveField(0)
  int id; // @Attribute(.unique)に対応。Hiveはキーでユニーク性を担保するため、ここではフィールドに設定

  @HiveField(1)
  int r; // ランダム値も考慮した並べ替え用→留学生受け入れフラグ兼人数用にした(0は受け入れない、1は1人、2は2人、3は3人受け入れる大学)
  @HiveField(2)
  String name;
  @HiveField(3)
  String name_tanshuku; //[12]統計データ表示用、[13]メモ1~[17]メモ5
  @HiveField(4)
  int meisei_total;
  @HiveField(5)
  List<int> meisei_yeargoto;
  @HiveField(6)
  int meiseijuni;
  @HiveField(7)
  int ikuseiryoku;
  @HiveField(8)
  List<int> mokuhyojuni;
  @HiveField(9)
  List<int> inkarepoint; // [0→インカレ5000、1→インカレ10000、2→インカレハーフ]
  //var time_taikai_1km: [[Double]] = Array(repeating: Array(repeating: 0.0, count: TEISUU.SUU_MAXKYORI), count: TEISUU.SUU_MAXKUKANSUU)//[区間][距離]
  @HiveField(10)
  List<double> time_taikai_total; // [区間]
  @HiveField(11)
  List<int> kukanjuni_taikai; // [区間]
  @HiveField(12)
  List<int> tuukajuni_taikai; // [区間]
  @HiveField(13)
  List<int> mokuhyojuniwositamawatteruflag; // [区間]
  @HiveField(14)
  List<List<int>> juni_race;
  @HiveField(15)
  List<List<double>> time_race;
  // [レース番号][過去10年、0→直近、9→一番昔]
  // レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  // 5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  // 10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  @HiveField(16)
  List<List<double>> time_univtaikaikiroku;
  @HiveField(17)
  List<List<int>> year_univtaikaikiroku;
  @HiveField(18)
  List<List<int>> month_univtaikaikiroku;
  //var day_univtaikaikiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  // →駅伝及び駅伝予選のみ
  // [大会(レース)種類番号][保存順位数、0→1位、9→10位]、レース番号の0〜4と9しか保存しないつもり
  // レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  // 5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  // 10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  @HiveField(19)
  List<List<List<double>>> time_univkukankiroku;
  @HiveField(20)
  List<List<List<int>>> year_univkukankiroku;
  @HiveField(21)
  List<List<List<int>>> month_univkukankiroku;
  @HiveField(22)
  List<List<List<String>>> name_univkukankiroku;
  @HiveField(23)
  List<List<List<int>>> gakunen_univkukankiroku;
  // [大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  //var time_1nenseiunivkukankiroku: [[[Double]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var year_1nenseiunivkukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var month_1nenseiunivkukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var day_1nenseiunivkukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var name_1nenseiunivkukankiroku: [[[String]]] = Array(repeating: Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  // [大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  @HiveField(24)
  List<int> taikaientryflag;
  @HiveField(25)
  List<int> taikaiseedflag;
  @HiveField(26)
  List<int> taikaibetusaikoujuni;
  // [大会(レース)種類番号]
  @HiveField(27)
  List<int> taikaibetushutujoukaisuu;
  // [大会(レース)種類番号]
  @HiveField(28)
  List<List<int>> taikaibetujunibetukaisuu;
  // [大会(レース)種類番号][保存順位数、0→1位、29→30位]

  @HiveField(29)
  List<List<double>> time_univkojinkiroku;
  @HiveField(30)
  List<List<int>> year_univkojinkiroku;
  @HiveField(31)
  List<List<int>> month_univkojinkiroku;
  //var day_univkojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  @HiveField(32)
  List<List<String>> name_univkojinkiroku;
  @HiveField(33)
  List<List<int>> gakunen_univkojinkiroku;
  //var time_1nenseiunivkojinkiroku: [[Double]] = Array(repeating: Array(repeating: 0.0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var year_1nenseiunivkojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var month_1nenseiunivkojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var day_1nenseiunivkojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var name_1nenseiunivkojinkiroku: [[String]] = Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  // [記録種類番号][保存順位数、0→1位、9→10位]
  // 0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7クロカン10000、8〜9→予備
  @HiveField(34)
  int chokuzentaikai_zentaitaikaisinflag;
  @HiveField(35)
  int chokuzentaikai_univtaikaisinflag;
  @HiveField(36)
  int sankankaisuu;

  // Swiftのinit(id:Int)に対応するDartコンストラクタ
  // Hiveがアダプタ生成に使用するため、すべての@HiveFieldに対応するフィールドの初期化が必要です。
  UnivData({
    required this.id,
    this.r = 0,
    this.name = "ダミー大学",
    this.name_tanshuku = "短縮",
    this.meisei_total = 0,
    List<int>? meisei_yeargoto,
    this.meiseijuni = 0,
    this.ikuseiryoku = 0,
    List<int>? mokuhyojuni,
    List<int>? inkarepoint,
    List<double>? time_taikai_total,
    List<int>? kukanjuni_taikai,
    List<int>? tuukajuni_taikai,
    List<int>? mokuhyojuniwositamawatteruflag,
    List<List<int>>? juni_race,
    List<List<double>>? time_race,
    List<List<double>>? time_univtaikaikiroku,
    List<List<int>>? year_univtaikaikiroku,
    List<List<int>>? month_univtaikaikiroku,
    List<List<List<double>>>? time_univkukankiroku,
    List<List<List<int>>>? year_univkukankiroku,
    List<List<List<int>>>? month_univkukankiroku,
    List<List<List<String>>>? name_univkukankiroku,
    List<List<List<int>>>? gakunen_univkukankiroku,
    List<int>? taikaientryflag,
    List<int>? taikaiseedflag,
    List<int>? taikaibetusaikoujuni,
    List<int>? taikaibetushutujoukaisuu,
    List<List<int>>? taikaibetujunibetukaisuu,
    List<List<double>>? time_univkojinkiroku,
    List<List<int>>? year_univkojinkiroku,
    List<List<int>>? month_univkojinkiroku,
    List<List<String>>? name_univkojinkiroku,
    List<List<int>>? gakunen_univkojinkiroku,
    this.chokuzentaikai_zentaitaikaisinflag = 0,
    this.chokuzentaikai_univtaikaisinflag = 0,
    this.sankankaisuu = 0,
  }) : this.meisei_yeargoto = meisei_yeargoto ?? [],
       this.mokuhyojuni = mokuhyojuni ?? [],
       this.inkarepoint = inkarepoint ?? [],
       this.time_taikai_total = time_taikai_total ?? [],
       this.kukanjuni_taikai = kukanjuni_taikai ?? [],
       this.tuukajuni_taikai = tuukajuni_taikai ?? [],
       this.mokuhyojuniwositamawatteruflag =
           mokuhyojuniwositamawatteruflag ?? [],
       this.juni_race = juni_race ?? [],
       this.time_race = time_race ?? [],
       this.time_univtaikaikiroku = time_univtaikaikiroku ?? [],
       this.year_univtaikaikiroku = year_univtaikaikiroku ?? [],
       this.month_univtaikaikiroku = month_univtaikaikiroku ?? [],
       this.time_univkukankiroku = time_univkukankiroku ?? [],
       this.year_univkukankiroku = year_univkukankiroku ?? [],
       this.month_univkukankiroku = month_univkukankiroku ?? [],
       this.name_univkukankiroku = name_univkukankiroku ?? [],
       this.gakunen_univkukankiroku = gakunen_univkukankiroku ?? [],
       this.taikaientryflag = taikaientryflag ?? [],
       this.taikaiseedflag = taikaiseedflag ?? [],
       this.taikaibetusaikoujuni = taikaibetusaikoujuni ?? [],
       this.taikaibetushutujoukaisuu = taikaibetushutujoukaisuu ?? [],
       this.taikaibetujunibetukaisuu = taikaibetujunibetukaisuu ?? [],
       this.time_univkojinkiroku = time_univkojinkiroku ?? [],
       this.year_univkojinkiroku = year_univkojinkiroku ?? [],
       this.month_univkojinkiroku = month_univkojinkiroku ?? [],
       this.name_univkojinkiroku = name_univkojinkiroku ?? [],
       this.gakunen_univkojinkiroku = gakunen_univkojinkiroku ?? [];

  // --- 初期値を設定するためのファクトリコンストラクタ ---
  // main.dartからこのコンストラクタを呼び出すことで、すべてのプロパティが適切に初期化されます。
  factory UnivData.initial({required int id}) {
    return UnivData(
      id: id,
      r: 0,
      name: "ダミー大学",
      name_tanshuku: "カスタム駅伝",
      meisei_total: 0,
      meisei_yeargoto: List.filled(TEISUU.MEISEIHOZONNENSUU, 0),
      meiseijuni: 0,
      ikuseiryoku: 0,
      mokuhyojuni: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
      inkarepoint: List.filled(3, 0),
      time_taikai_total: List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      kukanjuni_taikai: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
      tuukajuni_taikai: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
      mokuhyojuniwositamawatteruflag: List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
      juni_race: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.KIROKUHOZONNENSUU, 0),
      ),
      time_race: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.KIROKUHOZONNENSUU, 0.0),
      ),
      time_univtaikaikiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
      ),
      year_univtaikaikiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
      month_univtaikaikiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
      time_univkukankiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
        ),
      ),
      year_univkukankiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      ),
      month_univkukankiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      ),
      name_univkukankiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
        ),
      ),
      gakunen_univkukankiroku: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      ),
      taikaientryflag: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
      taikaiseedflag: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
      taikaibetusaikoujuni: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
      taikaibetushutujoukaisuu: List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 0),
      taikaibetujunibetukaisuu: List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.UNIVSUU, 0),
      ),
      time_univkojinkiroku: List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
      ),
      year_univkojinkiroku: List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
      month_univkojinkiroku: List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
      name_univkojinkiroku: List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
      ),
      gakunen_univkojinkiroku: List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
      chokuzentaikai_zentaitaikaisinflag: 0,
      chokuzentaikai_univtaikaisinflag: 0,
      sankankaisuu: 0,
    );
  }

  // 小数点以下 15 桁で丸めるヘルパー関数
  double _roundDouble(double value) {
    // 15 桁を指定して丸め処理を実行
    return double.parse(value.toStringAsFixed(15));
  }

  // List<double> のすべての要素を丸めるヘルパー関数
  List<double> _roundDoubleList(List<double> list) {
    return list.map((e) => _roundDouble(e)).toList();
  }

  // List<List<double>> のすべての要素を丸めるヘルパー関数
  List<List<double>> _roundDoubleNestedList(List<List<double>> nestedList) {
    return nestedList.map((list) => _roundDoubleList(list)).toList();
  }

  // UnivData クラス内 (修正後の toJson() のみ)

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (Double型の丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'r': r,
      'name': name,
      'name_tanshuku': name_tanshuku,
      'meisei_total': meisei_total,
      'meisei_yeargoto': meisei_yeargoto,
      'meiseijuni': meiseijuni,
      'ikuseiryoku': ikuseiryoku,
      'mokuhyojuni': mokuhyojuni,
      'inkarepoint': inkarepoint,
      // ★修正: List<double> に _roundDoubleList を適用
      'time_taikai_total': _roundDoubleList(time_taikai_total),
      'kukanjuni_taikai': kukanjuni_taikai,
      'tuukajuni_taikai': tuukajuni_taikai,
      'mokuhyojuniwositamawatteruflag': mokuhyojuniwositamawatteruflag,
      'juni_race': juni_race,
      // ★修正: List<List<double>> に _roundDoubleNestedList を適用
      'time_race': _roundDoubleNestedList(time_race),
      'time_univtaikaikiroku': _roundDoubleNestedList(time_univtaikaikiroku),
      'year_univtaikaikiroku': year_univtaikaikiroku,
      'month_univtaikaikiroku': month_univtaikaikiroku,
      // ★修正: List<List<List<double>>> の丸め処理
      // List<List<List<double>>> は Dart の標準機能では簡単に丸められないため、
      // ここでは新しいヘルパー関数 _roundDoubleTripleNestedList が必要です。
      // (詳細は次のセクションで説明します)
      'time_univkukankiroku': time_univkukankiroku
          .map((e) => _roundDoubleNestedList(e))
          .toList(),
      'year_univkukankiroku': year_univkukankiroku,
      'month_univkukankiroku': month_univkukankiroku,
      'name_univkukankiroku': name_univkukankiroku,
      'gakunen_univkukankiroku': gakunen_univkukankiroku,
      'taikaientryflag': taikaientryflag,
      'taikaiseedflag': taikaiseedflag,
      'taikaibetusaikoujuni': taikaibetusaikoujuni,
      'taikaibetushutujoukaisuu': taikaibetushutujoukaisuu,
      'taikaibetujunibetukaisuu': taikaibetujunibetukaisuu,
      // ★修正: List<List<double>> に _roundDoubleNestedList を適用
      'time_univkojinkiroku': _roundDoubleNestedList(time_univkojinkiroku),
      'year_univkojinkiroku': year_univkojinkiroku,
      'month_univkojinkiroku': month_univkojinkiroku,
      'name_univkojinkiroku': name_univkojinkiroku,
      'gakunen_univkojinkiroku': gakunen_univkojinkiroku,
      'chokuzentaikai_zentaitaikaisinflag': chokuzentaikai_zentaitaikaisinflag,
      'chokuzentaikai_univtaikaisinflag': chokuzentaikai_univtaikaisinflag,
      'sankankaisuu': sankankaisuu,
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'id': id,
      'r': r,
      'name': name,
      'name_tanshuku': name_tanshuku,
      'meisei_total': meisei_total,
      'meisei_yeargoto': meisei_yeargoto,
      'meiseijuni': meiseijuni,
      'ikuseiryoku': ikuseiryoku,
      'mokuhyojuni': mokuhyojuni,
      'inkarepoint': inkarepoint,
      'time_taikai_total': time_taikai_total,
      'kukanjuni_taikai': kukanjuni_taikai,
      'tuukajuni_taikai': tuukajuni_taikai,
      'mokuhyojuniwositamawatteruflag': mokuhyojuniwositamawatteruflag,
      'juni_race': juni_race,
      'time_race': time_race,
      'time_univtaikaikiroku': time_univtaikaikiroku,
      'year_univtaikaikiroku': year_univtaikaikiroku,
      'month_univtaikaikiroku': month_univtaikaikiroku,
      'time_univkukankiroku': time_univkukankiroku,
      'year_univkukankiroku': year_univkukankiroku,
      'month_univkukankiroku': month_univkukankiroku,
      'name_univkukankiroku': name_univkukankiroku,
      'gakunen_univkukankiroku': gakunen_univkukankiroku,
      'taikaientryflag': taikaientryflag,
      'taikaiseedflag': taikaiseedflag,
      'taikaibetusaikoujuni': taikaibetusaikoujuni,
      'taikaibetushutujoukaisuu': taikaibetushutujoukaisuu,
      'taikaibetujunibetukaisuu': taikaibetujunibetukaisuu,
      'time_univkojinkiroku': time_univkojinkiroku,
      'year_univkojinkiroku': year_univkojinkiroku,
      'month_univkojinkiroku': month_univkojinkiroku,
      'name_univkojinkiroku': name_univkojinkiroku,
      'gakunen_univkojinkiroku': gakunen_univkojinkiroku,
      'chokuzentaikai_zentaitaikaisinflag': chokuzentaikai_zentaitaikaisinflag,
      'chokuzentaikai_univtaikaisinflag': chokuzentaikai_univtaikaisinflag,
      'sankankaisuu': sankankaisuu,
    };
  }*/

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory UnivData.fromJson(Map<String, dynamic> json) {
    return UnivData(
      id: json['id'] as int,
      r: json['r'] as int,
      name: json['name'] as String,
      name_tanshuku: json['name_tanshuku'] as String,
      meisei_total: json['meisei_total'] as int,
      meisei_yeargoto: (json['meisei_yeargoto'] as List).cast<int>(),
      meiseijuni: json['meiseijuni'] as int,
      ikuseiryoku: json['ikuseiryoku'] as int,
      mokuhyojuni: (json['mokuhyojuni'] as List).cast<int>(),
      inkarepoint: (json['inkarepoint'] as List).cast<int>(),
      time_taikai_total: (json['time_taikai_total'] as List).cast<double>(),
      kukanjuni_taikai: (json['kukanjuni_taikai'] as List).cast<int>(),
      tuukajuni_taikai: (json['tuukajuni_taikai'] as List).cast<int>(),
      mokuhyojuniwositamawatteruflag:
          (json['mokuhyojuniwositamawatteruflag'] as List).cast<int>(),
      // List<List<int>> のデシリアライズ
      juni_race: (json['juni_race'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      // List<List<double>> のデシリアライズ
      time_race: (json['time_race'] as List)
          .map((e) => (e as List).cast<double>())
          .toList(),
      time_univtaikaikiroku: (json['time_univtaikaikiroku'] as List)
          .map((e) => (e as List).cast<double>())
          .toList(),
      year_univtaikaikiroku: (json['year_univtaikaikiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      month_univtaikaikiroku: (json['month_univtaikaikiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      // List<List<List<double>>> のデシリアライズ
      time_univkukankiroku: (json['time_univkukankiroku'] as List)
          .map(
            (e) => (e as List).map((f) => (f as List).cast<double>()).toList(),
          )
          .toList(),
      // List<List<List<int>>> のデシリアライズ
      year_univkukankiroku: (json['year_univkukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList(),
      month_univkukankiroku: (json['month_univkukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList(),
      // List<List<List<String>>> のデシリアライズ
      name_univkukankiroku: (json['name_univkukankiroku'] as List)
          .map(
            (e) => (e as List).map((f) => (f as List).cast<String>()).toList(),
          )
          .toList(),
      // List<List<List<int>>> のデシリアライズ
      gakunen_univkukankiroku: (json['gakunen_univkukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList(),
      taikaientryflag: (json['taikaientryflag'] as List).cast<int>(),
      taikaiseedflag: (json['taikaiseedflag'] as List).cast<int>(),
      taikaibetusaikoujuni: (json['taikaibetusaikoujuni'] as List).cast<int>(),
      taikaibetushutujoukaisuu: (json['taikaibetushutujoukaisuu'] as List)
          .cast<int>(),
      // List<List<int>> のデシリアライズ
      taikaibetujunibetukaisuu: (json['taikaibetujunibetukaisuu'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      // List<List<double>> のデシリアライズ
      time_univkojinkiroku: (json['time_univkojinkiroku'] as List)
          .map((e) => (e as List).cast<double>())
          .toList(),
      // List<List<int>> のデシリアライズ
      year_univkojinkiroku: (json['year_univkojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      month_univkojinkiroku: (json['month_univkojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      // List<List<String>> のデシリアライズ
      name_univkojinkiroku: (json['name_univkojinkiroku'] as List)
          .map((e) => (e as List).cast<String>())
          .toList(),
      // List<List<int>> のデシリアライズ
      gakunen_univkojinkiroku: (json['gakunen_univkojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
      chokuzentaikai_zentaitaikaisinflag:
          json['chokuzentaikai_zentaitaikaisinflag'] as int,
      chokuzentaikai_univtaikaisinflag:
          json['chokuzentaikai_univtaikaisinflag'] as int,
      sankankaisuu: json['sankankaisuu'] as int,
    );
  }
}
