import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'ghensuu.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 2) // ユニークなtypeIdを指定 (SenshuDataが0, UnivDataが1なので2)
class Ghensuu extends HiveObject {
  @HiveField(0)
  int goldenballsuu = 0;
  @HiveField(1)
  int last_goldenballkakutokusuu = 0;
  @HiveField(2)
  int silverballsuu = 0;
  @HiveField(3)
  int last_silverballkakutokusuu = 0;
  @HiveField(4)
  List<int> nouryokumieruflag = List.filled(20, 0);
  @HiveField(5)
  List<int> SijiSelectedOption = List.filled(TEISUU.SENSHUSUU_UNIV, 0);
  @HiveField(6)
  List<int> SenshuSelectedOption = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
  @HiveField(7)
  List<int> SenshuSelectedOption2 = List.filled(TEISUU.SUU_MAXKUKANSUU, 0);
  @HiveField(8)
  int hyojisenshunum = 0; //選手画面でgakunenjununivfilteredsenshudataで表示する選手
  @HiveField(9)
  int hyojiunivnum = 0; //大学画面で表示する大学
  @HiveField(10)
  int hyojiracebangou = 0;
  @HiveField(11)
  int mode = 0;
  @HiveField(12)
  int gamenflag = 0; //0→最新、1→選手、2→大学、3→記録、4→設定
  @HiveField(13)
  int year = 0;
  @HiveField(14)
  int month = 0;
  @HiveField(15)
  int day = 0;
  @HiveField(16)
  int MYunivid = 0;
  @HiveField(17)
  int ondoflag = 0;
  @HiveField(18)
  int kazeflag = 0; //難易度にする、0→鬼、1→難、2→普、3→易

  @HiveField(19)
  List<String> name_mae = List.filled(TEISUU.SUU_NAMEMAE, "");
  @HiveField(20)
  List<String> name_ato = List.filled(TEISUU.SUU_NAMEATO, "");

  @HiveField(21)
  int spurtryokuseichousisuu1 = 1; //カスタム駅伝やるフラグ
  @HiveField(22)
  int spurtryokuseichousisuu2 = 93; //目標順位設定方法フラグ
  @HiveField(23)
  int spurtryokuseichousisuu3 = 9; //新入生所属先決定名声影響度指数
  @HiveField(24)
  int spurtryokuseichousisuu4 = 1; //カスタム駅伝名声倍率ｙ/ｘのｙ
  @HiveField(25)
  int spurtryokuseichousisuu5 = 10; //カスタム駅伝名声倍率ｙ/ｘのｘ

  @HiveField(26)
  List<List<int>> seichouryoku_type_gakunen = List.generate(
    TEISUU.SEICHOUTYPESUU,
    (_) => List.filled(TEISUU.GAKUNENSUU, 0),
  );
  @HiveField(27)
  List<int> seichouryoku_type_sentakuritu = List.filled(
    TEISUU.SEICHOUTYPESUU,
    0,
  );

  @HiveField(28)
  int nowracecalckukan = 0;
  @HiveField(29)
  List<int> kukansuu_taikaigoto = List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 1);
  //[大会(レース)種類番号]
  @HiveField(30)
  List<List<double>> kyori_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
  );
  @HiveField(31)
  List<List<double>> heikinkoubainobori_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
  );
  @HiveField(32)
  List<List<double>> heikinkoubaikudari_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
  );
  @HiveField(33)
  List<List<double>> kyoriwariainobori_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
  );
  @HiveField(34)
  List<List<double>> kyoriwariaikudari_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
  );
  @HiveField(35)
  List<List<int>> noborikudarikirikaekaisuu_taikai_kukangoto = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
  );
  //[大会(レース)種類番号][区間、0→1区、9→10区]
  @HiveField(36)
  List<List<double>> time_zentaitaikaikiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
  );
  @HiveField(37)
  List<List<int>> year_zentaitaikaikiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  @HiveField(38)
  List<List<int>> month_zentaitaikaikiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  //var day_zentaitaikaikiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  @HiveField(39)
  List<List<String>> univname_zentaitaikaikiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  //→駅伝及び駅伝予選のみ
  //[大会(レース)種類番号][保存順位数、0→1位、9→10位]、レース番号の0〜4と9しか保存しないつもり
  //レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  //5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  //10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  @HiveField(40)
  List<List<List<double>>> time_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
    ),
  );
  @HiveField(41)
  List<List<List<int>>> year_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(42)
  List<List<List<int>>> month_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  //var day_zentaikukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  @HiveField(43)
  List<List<List<String>>> univname_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(44)
  List<List<List<String>>> name_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(45)
  List<List<List<int>>> gakunen_zentaikukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  //[大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  //var time_1nenseizentaikukankiroku: [[[Double]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var year_1nenseizentaikukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var month_1nenseizentaikukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var day_1nenseizentaikukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var univname_1nenseizentaikukankiroku: [[[String]]] = Array(repeating: Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //var name_1nenseizentaikukankiroku: [[[String]]] = Array(repeating: Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  //[大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  @HiveField(46)
  List<List<double>> time_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
  );
  @HiveField(47)
  List<List<int>> year_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  @HiveField(48)
  List<List<int>> month_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  //var day_zentaikojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  @HiveField(49)
  List<List<String>> univname_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(50)
  List<List<String>> name_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(51)
  List<List<int>> gakunen_zentaikojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  //var time_1nenseizentaikojinkiroku: [[Double]] = Array(repeating: Array(repeating: 0.0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var year_1nenseizentaikojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var month_1nenseizentaikojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var day_1nenseizentaikojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var univname_1nenseizentaikojinkiroku: [[String]] = Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //var name_1nenseizentaikojinkiroku: [[String]] = Array(repeating: Array(repeating: "", count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  //[記録種類番号][保存順位数、0→1位、9→10位]
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(52) // 新しいフィールドを追加
  int scoutChances = 3;

  // コンストラクタ (Swiftのinit()に対応)
  Ghensuu(); // 引数なしのコンストラクタ

  // 必要に応じて、初期値を設定するファクトリコンストラクタを追加することもできます
  factory Ghensuu.initial() {
    return Ghensuu()
      ..goldenballsuu = 0
      ..last_goldenballkakutokusuu = 0
      ..silverballsuu = 0
      ..last_silverballkakutokusuu = 0
      ..nouryokumieruflag = List.filled(20, 0)
      ..SijiSelectedOption = List.filled(TEISUU.SENSHUSUU_UNIV, 0)
      ..SenshuSelectedOption = List.filled(TEISUU.SUU_MAXKUKANSUU, 0)
      ..SenshuSelectedOption2 = List.filled(TEISUU.SUU_MAXKUKANSUU, 0)
      ..hyojisenshunum = 0
      ..hyojiunivnum = 0
      ..hyojiracebangou = 0
      ..mode = 0
      ..gamenflag = 0
      ..year = 0
      ..month = 0
      ..day = 0
      ..MYunivid = 0
      ..ondoflag = 0
      ..kazeflag = 0
      ..name_mae = List.filled(TEISUU.SUU_NAMEMAE, "")
      ..name_ato = List.filled(TEISUU.SUU_NAMEATO, "")
      ..spurtryokuseichousisuu1 = 1
      ..spurtryokuseichousisuu2 = 93
      ..spurtryokuseichousisuu3 = 9
      ..spurtryokuseichousisuu4 = 1
      ..spurtryokuseichousisuu5 = 10
      ..seichouryoku_type_gakunen = List.generate(
        TEISUU.SEICHOUTYPESUU,
        (_) => List.filled(TEISUU.GAKUNENSUU, 0),
      )
      ..seichouryoku_type_sentakuritu = List.filled(TEISUU.SEICHOUTYPESUU, 0)
      ..nowracecalckukan = 0
      ..kukansuu_taikaigoto = List.filled(TEISUU.SUU_MAXRACESUU_1YEAR, 1)
      ..kyori_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      )
      ..heikinkoubainobori_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      )
      ..heikinkoubaikudari_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      )
      ..kyoriwariainobori_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      )
      ..kyoriwariaikudari_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0.0),
      )
      ..noborikudarikirikaekaisuu_taikai_kukangoto = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_MAXKUKANSUU, 0),
      )
      ..time_zentaitaikaikiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
      )
      ..year_zentaitaikaikiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      )
      ..month_zentaitaikaikiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      )
      ..univname_zentaitaikaikiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
      )
      ..time_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
        ),
      )
      ..year_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      )
      ..month_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      )
      ..univname_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
        ),
      )
      ..name_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
        ),
      )
      ..gakunen_zentaikukankiroku = List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
        ),
      )
      ..time_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0.0),
      )
      ..year_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      )
      ..month_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      )
      ..univname_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
      )
      ..name_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
      )
      ..gakunen_zentaikojinkiroku = List.generate(
        TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
        (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      )
      ..scoutChances = 3;
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
  // Ghensuu クラス内 (修正後の toJson() のみ)

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (Double型の丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    // 3階層のリスト（List<List<List<double>>>）を丸めるためのローカル関数
    List<List<List<double>>> round3DList(List<List<List<double>>> list) {
      return list.map((e) => _roundDoubleNestedList(e)).toList();
    }

    return {
      'goldenballsuu': goldenballsuu,
      'last_goldenballkakutokusuu': last_goldenballkakutokusuu,
      'silverballsuu': silverballsuu,
      'last_silverballkakutokusuu': last_silverballkakutokusuu,
      'nouryokumieruflag': nouryokumieruflag,
      'SijiSelectedOption': SijiSelectedOption,
      'SenshuSelectedOption': SenshuSelectedOption,
      'SenshuSelectedOption2': SenshuSelectedOption2,
      'hyojisenshunum': hyojisenshunum,
      'hyojiunivnum': hyojiunivnum,
      'hyojiracebangou': hyojiracebangou,
      'mode': mode,
      'gamenflag': gamenflag,
      'year': year,
      'month': month,
      'day': day,
      'MYunivid': MYunivid,
      'ondoflag': ondoflag,
      'kazeflag': kazeflag,
      'name_mae': name_mae,
      'name_ato': name_ato,
      'spurtryokuseichousisuu1': spurtryokuseichousisuu1,
      'spurtryokuseichousisuu2': spurtryokuseichousisuu2,
      'spurtryokuseichousisuu3': spurtryokuseichousisuu3,
      'spurtryokuseichousisuu4': spurtryokuseichousisuu4,
      'spurtryokuseichousisuu5': spurtryokuseichousisuu5,
      'seichouryoku_type_gakunen': seichouryoku_type_gakunen,
      'seichouryoku_type_sentakuritu': seichouryoku_type_sentakuritu,
      'nowracecalckukan': nowracecalckukan,
      'kukansuu_taikaigoto': kukansuu_taikaigoto,

      // ★修正: List<List<double>> に _roundDoubleNestedList を適用 (コース情報)
      'kyori_taikai_kukangoto': _roundDoubleNestedList(kyori_taikai_kukangoto),
      'heikinkoubainobori_taikai_kukangoto': _roundDoubleNestedList(
        heikinkoubainobori_taikai_kukangoto,
      ),
      'heikinkoubaikudari_taikai_kukangoto': _roundDoubleNestedList(
        heikinkoubaikudari_taikai_kukangoto,
      ),
      'kyoriwariainobori_taikai_kukangoto': _roundDoubleNestedList(
        kyoriwariainobori_taikai_kukangoto,
      ),
      'kyoriwariaikudari_taikai_kukangoto': _roundDoubleNestedList(
        kyoriwariaikudari_taikai_kukangoto,
      ),

      'noborikudarikirikaekaisuu_taikai_kukangoto':
          noborikudarikirikaekaisuu_taikai_kukangoto,

      // ★修正: List<List<double>> に _roundDoubleNestedList を適用 (大会記録)
      'time_zentaitaikaikiroku': _roundDoubleNestedList(
        time_zentaitaikaikiroku,
      ),
      'year_zentaitaikaikiroku': year_zentaitaikaikiroku,
      'month_zentaitaikaikiroku': month_zentaitaikaikiroku,
      'univname_zentaitaikaikiroku': univname_zentaitaikaikiroku,

      // ★修正: List<List<List<double>>> に round3DList を適用 (区間記録)
      'time_zentaikukankiroku': round3DList(time_zentaikukankiroku),
      'year_zentaikukankiroku': year_zentaikukankiroku,
      'month_zentaikukankiroku': month_zentaikukankiroku,
      'univname_zentaikukankiroku': univname_zentaikukankiroku,
      'name_zentaikukankiroku': name_zentaikukankiroku,
      'gakunen_zentaikukankiroku': gakunen_zentaikukankiroku,

      // ★修正: List<List<double>> に _roundDoubleNestedList を適用 (個人記録)
      'time_zentaikojinkiroku': _roundDoubleNestedList(time_zentaikojinkiroku),
      'year_zentaikojinkiroku': year_zentaikojinkiroku,
      'month_zentaikojinkiroku': month_zentaikojinkiroku,
      'univname_zentaikojinkiroku': univname_zentaikojinkiroku,
      'name_zentaikojinkiroku': name_zentaikojinkiroku,
      'gakunen_zentaikojinkiroku': gakunen_zentaikojinkiroku,
      'scoutChances': scoutChances,
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'goldenballsuu': goldenballsuu,
      'last_goldenballkakutokusuu': last_goldenballkakutokusuu,
      'silverballsuu': silverballsuu,
      'last_silverballkakutokusuu': last_silverballkakutokusuu,
      'nouryokumieruflag': nouryokumieruflag,
      'SijiSelectedOption': SijiSelectedOption,
      'SenshuSelectedOption': SenshuSelectedOption,
      'SenshuSelectedOption2': SenshuSelectedOption2,
      'hyojisenshunum': hyojisenshunum,
      'hyojiunivnum': hyojiunivnum,
      'hyojiracebangou': hyojiracebangou,
      'mode': mode,
      'gamenflag': gamenflag,
      'year': year,
      'month': month,
      'day': day,
      'MYunivid': MYunivid,
      'ondoflag': ondoflag,
      'kazeflag': kazeflag,
      'name_mae': name_mae,
      'name_ato': name_ato,
      'spurtryokuseichousisuu1': spurtryokuseichousisuu1,
      'spurtryokuseichousisuu2': spurtryokuseichousisuu2,
      'spurtryokuseichousisuu3': spurtryokuseichousisuu3,
      'spurtryokuseichousisuu4': spurtryokuseichousisuu4,
      'spurtryokuseichousisuu5': spurtryokuseichousisuu5,
      'seichouryoku_type_gakunen': seichouryoku_type_gakunen,
      'seichouryoku_type_sentakuritu': seichouryoku_type_sentakuritu,
      'nowracecalckukan': nowracecalckukan,
      'kukansuu_taikaigoto': kukansuu_taikaigoto,
      'kyori_taikai_kukangoto': kyori_taikai_kukangoto,
      'heikinkoubainobori_taikai_kukangoto':
          heikinkoubainobori_taikai_kukangoto,
      'heikinkoubaikudari_taikai_kukangoto':
          heikinkoubaikudari_taikai_kukangoto,
      'kyoriwariainobori_taikai_kukangoto': kyoriwariainobori_taikai_kukangoto,
      'kyoriwariaikudari_taikai_kukangoto': kyoriwariaikudari_taikai_kukangoto,
      'noborikudarikirikaekaisuu_taikai_kukangoto':
          noborikudarikirikaekaisuu_taikai_kukangoto,
      'time_zentaitaikaikiroku': time_zentaitaikaikiroku,
      'year_zentaitaikaikiroku': year_zentaitaikaikiroku,
      'month_zentaitaikaikiroku': month_zentaitaikaikiroku,
      'univname_zentaitaikaikiroku': univname_zentaitaikaikiroku,
      'time_zentaikukankiroku': time_zentaikukankiroku,
      'year_zentaikukankiroku': year_zentaikukankiroku,
      'month_zentaikukankiroku': month_zentaikukankiroku,
      'univname_zentaikukankiroku': univname_zentaikukankiroku,
      'name_zentaikukankiroku': name_zentaikukankiroku,
      'gakunen_zentaikukankiroku': gakunen_zentaikukankiroku,
      'time_zentaikojinkiroku': time_zentaikojinkiroku,
      'year_zentaikojinkiroku': year_zentaikojinkiroku,
      'month_zentaikojinkiroku': month_zentaikojinkiroku,
      'univname_zentaikojinkiroku': univname_zentaikojinkiroku,
      'name_zentaikojinkiroku': name_zentaikojinkiroku,
      'gakunen_zentaikojinkiroku': gakunen_zentaikojinkiroku,
      'scoutChances': scoutChances,
    };
  }*/

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory Ghensuu.fromJson(Map<String, dynamic> json) {
    return Ghensuu()
      ..goldenballsuu = json['goldenballsuu'] as int
      ..last_goldenballkakutokusuu = json['last_goldenballkakutokusuu'] as int
      ..silverballsuu = json['silverballsuu'] as int
      ..last_silverballkakutokusuu = json['last_silverballkakutokusuu'] as int
      ..nouryokumieruflag = json['nouryokumieruflag'] as List<int>
      ..SijiSelectedOption = json['SijiSelectedOption'] as List<int>
      ..SenshuSelectedOption = json['SenshuSelectedOption'] as List<int>
      ..SenshuSelectedOption2 = json['SenshuSelectedOption2'] as List<int>
      ..hyojisenshunum = json['hyojisenshunum'] as int
      ..hyojiunivnum = json['hyojiunivnum'] as int
      ..hyojiracebangou = json['hyojiracebangou'] as int
      ..mode = json['mode'] as int
      ..gamenflag = json['gamenflag'] as int
      ..year = json['year'] as int
      ..month = json['month'] as int
      ..day = json['day'] as int
      ..MYunivid = json['MYunivid'] as int
      ..ondoflag = json['ondoflag'] as int
      ..kazeflag = json['kazeflag'] as int
      ..name_mae = json['name_mae'] as List<String>
      ..name_ato = json['name_ato'] as List<String>
      ..spurtryokuseichousisuu1 = json['spurtryokuseichousisuu1'] as int
      ..spurtryokuseichousisuu2 = json['spurtryokuseichousisuu2'] as int
      ..spurtryokuseichousisuu3 = json['spurtryokuseichousisuu3'] as int
      ..spurtryokuseichousisuu4 = json['spurtryokuseichousisuu4'] as int
      ..spurtryokuseichousisuu5 = json['spurtryokuseichousisuu5'] as int
      ..seichouryoku_type_gakunen = (json['seichouryoku_type_gakunen'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..seichouryoku_type_sentakuritu =
          json['seichouryoku_type_sentakuritu'] as List<int>
      ..nowracecalckukan = json['nowracecalckukan'] as int
      ..kukansuu_taikaigoto = json['kukansuu_taikaigoto'] as List<int>
      ..kyori_taikai_kukangoto = (json['kyori_taikai_kukangoto'] as List)
          .map((e) => (e as List).cast<double>())
          .toList()
      ..heikinkoubainobori_taikai_kukangoto =
          (json['heikinkoubainobori_taikai_kukangoto'] as List)
              .map((e) => (e as List).cast<double>())
              .toList()
      ..heikinkoubaikudari_taikai_kukangoto =
          (json['heikinkoubaikudari_taikai_kukangoto'] as List)
              .map((e) => (e as List).cast<double>())
              .toList()
      ..kyoriwariainobori_taikai_kukangoto =
          (json['kyoriwariainobori_taikai_kukangoto'] as List)
              .map((e) => (e as List).cast<double>())
              .toList()
      ..kyoriwariaikudari_taikai_kukangoto =
          (json['kyoriwariaikudari_taikai_kukangoto'] as List)
              .map((e) => (e as List).cast<double>())
              .toList()
      ..noborikudarikirikaekaisuu_taikai_kukangoto =
          (json['noborikudarikirikaekaisuu_taikai_kukangoto'] as List)
              .map((e) => (e as List).cast<int>())
              .toList()
      ..time_zentaitaikaikiroku = (json['time_zentaitaikaikiroku'] as List)
          .map((e) => (e as List).cast<double>())
          .toList()
      ..year_zentaitaikaikiroku = (json['year_zentaitaikaikiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..month_zentaitaikaikiroku = (json['month_zentaitaikaikiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..univname_zentaitaikaikiroku =
          (json['univname_zentaitaikaikiroku'] as List)
              .map((e) => (e as List).cast<String>())
              .toList()
      ..time_zentaikukankiroku = (json['time_zentaikukankiroku'] as List)
          .map(
            (e) => (e as List).map((f) => (f as List).cast<double>()).toList(),
          )
          .toList()
      ..year_zentaikukankiroku = (json['year_zentaikukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList()
      ..month_zentaikukankiroku = (json['month_zentaikukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList()
      ..univname_zentaikukankiroku =
          (json['univname_zentaikukankiroku'] as List)
              .map(
                (e) =>
                    (e as List).map((f) => (f as List).cast<String>()).toList(),
              )
              .toList()
      ..name_zentaikukankiroku = (json['name_zentaikukankiroku'] as List)
          .map(
            (e) => (e as List).map((f) => (f as List).cast<String>()).toList(),
          )
          .toList()
      ..gakunen_zentaikukankiroku = (json['gakunen_zentaikukankiroku'] as List)
          .map((e) => (e as List).map((f) => (f as List).cast<int>()).toList())
          .toList()
      ..time_zentaikojinkiroku = (json['time_zentaikojinkiroku'] as List)
          .map((e) => (e as List).cast<double>())
          .toList()
      ..year_zentaikojinkiroku = (json['year_zentaikojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..month_zentaikojinkiroku = (json['month_zentaikojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..univname_zentaikojinkiroku =
          (json['univname_zentaikojinkiroku'] as List)
              .map((e) => (e as List).cast<String>())
              .toList()
      ..name_zentaikojinkiroku = (json['name_zentaikojinkiroku'] as List)
          .map((e) => (e as List).cast<String>())
          .toList()
      ..gakunen_zentaikojinkiroku = (json['gakunen_zentaikojinkiroku'] as List)
          .map((e) => (e as List).cast<int>())
          .toList()
      ..scoutChances = json['scoutChances'] as int;
  }
}
