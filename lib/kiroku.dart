import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'kiroku.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 3) // ユニークなtypeIdを指定
class Kiroku extends HiveObject {
  //→駅伝及び駅伝予選のみ
  //[大会(レース)種類番号][保存順位数、0→1位、9→10位]、レース番号の0〜4と9しか保存しないつもり
  //レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  //5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  //10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  //
  //[大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  @HiveField(0)
  List<List<List<double>>> time_zentai_ryuugakusei_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) =>
          List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
    ),
  );
  @HiveField(1)
  List<List<List<int>>> year_zentai_ryuugakusei_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(2)
  List<List<List<int>>> month_zentai_ryuugakusei_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  //var day_zentaikukankiroku: [[[Int]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_MAXKUKANSUU), count: TEISUU.SUU_MAXRACESUU_1YEAR)
  @HiveField(3)
  List<List<List<String>>> univname_zentai_ryuugakusei_kukankiroku =
      List.generate(
        TEISUU.SUU_MAXRACESUU_1YEAR,
        (_) => List.generate(
          TEISUU.SUU_MAXKUKANSUU,
          (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
        ),
      );
  @HiveField(4)
  List<List<List<String>>> name_zentai_ryuugakusei_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(5)
  List<List<List<int>>> gakunen_zentai_ryuugakusei_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );

  //[記録種類番号][保存順位数、0→1位、9→10位]
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(6)
  List<List<double>> time_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
  );
  @HiveField(7)
  List<List<int>> year_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  @HiveField(8)
  List<List<int>> month_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  @HiveField(9)
  List<List<String>> univname_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(10)
  List<List<String>> name_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(11)
  List<List<int>> gakunen_zentai_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  //
  //[大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  @HiveField(12)
  List<List<List<double>>> time_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) =>
          List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
    ),
  );
  @HiveField(13)
  List<List<List<int>>> year_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(14)
  List<List<List<int>>> month_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(15)
  List<List<List<String>>> univname_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(16)
  List<List<List<String>>> name_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(17)
  List<List<List<int>>> gakunen_zentai_jap_kukankiroku = List.generate(
    TEISUU.SUU_MAXRACESUU_1YEAR,
    (_) => List.generate(
      TEISUU.SUU_MAXKUKANSUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  //[記録種類番号][保存順位数、0→1位、9→10位]
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(18)
  List<List<double>> time_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
  );
  @HiveField(19)
  List<List<int>> year_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  @HiveField(20)
  List<List<int>> month_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );
  //var day_zentaikojinkiroku: [[Int]] = Array(repeating: Array(repeating: 0, count: TEISUU.SUU_BESTKIROKUHOZONJUNISUU), count: TEISUU.SUU_KOJINBESTKIROKUSHURUISUU)
  @HiveField(21)
  List<List<String>> univname_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(22)
  List<List<String>> name_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
  );
  @HiveField(23)
  List<List<int>> gakunen_zentai_jap_kojinkiroku = List.generate(
    TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
    (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
  );

  /////////////////////////////////////////////////////////////////////////////////
  ///
  ///
  //[UNIVID][大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  //
  @HiveField(24)
  List<List<List<List<double>>>> time_univ_ryuugakusei_kukankiroku =
      List.generate(
        TEISUU.UNIVSUU,
        (_) => List.generate(
          TEISUU.SUU_MAXRACESUU_1YEAR,
          (__) => List.generate(
            TEISUU.SUU_MAXKUKANSUU,
            (___) => List.filled(
              TEISUU.SUU_BESTKIROKUHOZONJUNISUU,
              TEISUU.DEFAULTTIME,
            ),
          ),
        ),
      );
  @HiveField(25)
  List<List<List<List<int>>>> year_univ_ryuugakusei_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
    ),
  );
  @HiveField(26)
  List<List<List<List<int>>>> month_univ_ryuugakusei_kukankiroku =
      List.generate(
        TEISUU.UNIVSUU,
        (_) => List.generate(
          TEISUU.SUU_MAXRACESUU_1YEAR,
          (__) => List.generate(
            TEISUU.SUU_MAXKUKANSUU,
            (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
          ),
        ),
      );
  @HiveField(27)
  List<List<List<List<String>>>> name_univ_ryuugakusei_kukankiroku =
      List.generate(
        TEISUU.UNIVSUU,
        (_) => List.generate(
          TEISUU.SUU_MAXRACESUU_1YEAR,
          (__) => List.generate(
            TEISUU.SUU_MAXKUKANSUU,
            (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
          ),
        ),
      );
  @HiveField(28)
  List<List<List<List<int>>>> gakunen_univ_ryuugakusei_kukankiroku =
      List.generate(
        TEISUU.UNIVSUU,
        (_) => List.generate(
          TEISUU.SUU_MAXRACESUU_1YEAR,
          (__) => List.generate(
            TEISUU.SUU_MAXKUKANSUU,
            (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
          ),
        ),
      );
  //[UNIVID][記録種類番号][保存順位数、0→1位、9→10位]
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(29)
  List<List<List<double>>> time_univ_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) =>
          List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
    ),
  );
  @HiveField(30)
  List<List<List<int>>> year_univ_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(31)
  List<List<List<int>>> month_univ_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(32)
  List<List<List<String>>> name_univ_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(33)
  List<List<List<int>>> gakunen_univ_ryuugakusei_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );

  ///
  //[UNIVID][大会(レース)種類番号][区間、0→1区、9→10区][保存順位数、0→1位、9→10位]
  //
  @HiveField(34)
  List<List<List<List<double>>>> time_univ_jap_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) =>
            List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
      ),
    ),
  );
  @HiveField(35)
  List<List<List<List<int>>>> year_univ_jap_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
    ),
  );
  @HiveField(36)
  List<List<List<List<int>>>> month_univ_jap_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
    ),
  );
  @HiveField(37)
  List<List<List<List<String>>>> name_univ_jap_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
      ),
    ),
  );
  @HiveField(38)
  List<List<List<List<int>>>> gakunen_univ_jap_kukankiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_MAXRACESUU_1YEAR,
      (__) => List.generate(
        TEISUU.SUU_MAXKUKANSUU,
        (___) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
      ),
    ),
  );
  //[UNIVID][記録種類番号][保存順位数、0→1位、9→10位]
  //0→5000、1→10000、2→half、3→full、4→登り10000、5→下り10000、6→ロード10000、7→クロカン10000、8〜9→予備
  @HiveField(39)
  List<List<List<double>>> time_univ_jap_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) =>
          List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME),
    ),
  );
  @HiveField(40)
  List<List<List<int>>> year_univ_jap_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(41)
  List<List<List<int>>> month_univ_jap_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );
  @HiveField(42)
  List<List<List<String>>> name_univ_jap_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, ""),
    ),
  );
  @HiveField(43)
  List<List<List<int>>> gakunen_univ_jap_kojinkiroku = List.generate(
    TEISUU.UNIVSUU,
    (_) => List.generate(
      TEISUU.SUU_KOJINBESTKIROKUSHURUISUU,
      (__) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, 0),
    ),
  );

  // コンストラクタ (Swiftのinit()に対応)
  Kiroku(); // 引数なしのコンストラクタ

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
  // Kiroku クラス内 (修正後の toJson() のみ)

  // ★★★ 修正: toJson() - すべてのフィールドをMapにシリアライズ (Double型の丸め処理を追加) ★★★
  Map<String, dynamic> toJson() {
    // 3階層のリスト（List<List<List<double>>>）を丸めるためのローカル関数
    List<List<List<double>>> round3DList(List<List<List<double>>> list) {
      return list.map((e) => _roundDoubleNestedList(e)).toList();
    }

    // 4階層のリスト（List<List<List<List<double>>>>）を丸めるためのローカル関数
    List<List<List<List<double>>>> round4DList(
      List<List<List<List<double>>>> list,
    ) {
      return list.map((e) => round3DList(e)).toList();
    }

    return {
      // 3階層 (全体・区間記録)
      'time_zentai_ryuugakusei_kukankiroku': round3DList(
        time_zentai_ryuugakusei_kukankiroku,
      ), // ★修正★
      'year_zentai_ryuugakusei_kukankiroku':
          year_zentai_ryuugakusei_kukankiroku,
      'month_zentai_ryuugakusei_kukankiroku':
          month_zentai_ryuugakusei_kukankiroku,
      'univname_zentai_ryuugakusei_kukankiroku':
          univname_zentai_ryuugakusei_kukankiroku,
      'name_zentai_ryuugakusei_kukankiroku':
          name_zentai_ryuugakusei_kukankiroku,
      'gakunen_zentai_ryuugakusei_kukankiroku':
          gakunen_zentai_ryuugakusei_kukankiroku,

      // 2階層 (全体・個人記録)
      'time_zentai_ryuugakusei_kojinkiroku': _roundDoubleNestedList(
        time_zentai_ryuugakusei_kojinkiroku,
      ), // ★修正★
      'year_zentai_ryuugakusei_kojinkiroku':
          year_zentai_ryuugakusei_kojinkiroku,
      'month_zentai_ryuugakusei_kojinkiroku':
          month_zentai_ryuugakusei_kojinkiroku,
      'univname_zentai_ryuugakusei_kojinkiroku':
          univname_zentai_ryuugakusei_kojinkiroku,
      'name_zentai_ryuugakusei_kojinkiroku':
          name_zentai_ryuugakusei_kojinkiroku,
      'gakunen_zentai_ryuugakusei_kojinkiroku':
          gakunen_zentai_ryuugakusei_kojinkiroku,

      // 3階層 (全体・日本人・区間記録)
      'time_zentai_jap_kukankiroku': round3DList(
        time_zentai_jap_kukankiroku,
      ), // ★修正★
      'year_zentai_jap_kukankiroku': year_zentai_jap_kukankiroku,
      'month_zentai_jap_kukankiroku': month_zentai_jap_kukankiroku,
      'univname_zentai_jap_kukankiroku': univname_zentai_jap_kukankiroku,
      'name_zentai_jap_kukankiroku': name_zentai_jap_kukankiroku,
      'gakunen_zentai_jap_kukankiroku': gakunen_zentai_jap_kukankiroku,

      // 2階層 (全体・日本人・個人記録)
      'time_zentai_jap_kojinkiroku': _roundDoubleNestedList(
        time_zentai_jap_kojinkiroku,
      ), // ★修正★
      'year_zentai_jap_kojinkiroku': year_zentai_jap_kojinkiroku,
      'month_zentai_jap_kojinkiroku': month_zentai_jap_kojinkiroku,
      'univname_zentai_jap_kojinkiroku': univname_zentai_jap_kojinkiroku,
      'name_zentai_jap_kojinkiroku': name_zentai_jap_kojinkiroku,
      'gakunen_zentai_jap_kojinkiroku': gakunen_zentai_jap_kojinkiroku,

      // 4階層 (大学別・留学生・区間記録)
      'time_univ_ryuugakusei_kukankiroku': round4DList(
        time_univ_ryuugakusei_kukankiroku,
      ), // ★修正★
      'year_univ_ryuugakusei_kukankiroku': year_univ_ryuugakusei_kukankiroku,
      'month_univ_ryuugakusei_kukankiroku': month_univ_ryuugakusei_kukankiroku,
      'name_univ_ryuugakusei_kukankiroku': name_univ_ryuugakusei_kukankiroku,
      'gakunen_univ_ryuugakusei_kukankiroku':
          gakunen_univ_ryuugakusei_kukankiroku,

      // 3階層 (大学別・留学生・個人記録)
      'time_univ_ryuugakusei_kojinkiroku': round3DList(
        time_univ_ryuugakusei_kojinkiroku,
      ), // ★修正★
      'year_univ_ryuugakusei_kojinkiroku': year_univ_ryuugakusei_kojinkiroku,
      'month_univ_ryuugakusei_kojinkiroku': month_univ_ryuugakusei_kojinkiroku,
      'name_univ_ryuugakusei_kojinkiroku': name_univ_ryuugakusei_kojinkiroku,
      'gakunen_univ_ryuugakusei_kojinkiroku':
          gakunen_univ_ryuugakusei_kojinkiroku,

      // 4階層 (大学別・日本人・区間記録)
      'time_univ_jap_kukankiroku': round4DList(
        time_univ_jap_kukankiroku,
      ), // ★修正★
      'year_univ_jap_kukankiroku': year_univ_jap_kukankiroku,
      'month_univ_jap_kukankiroku': month_univ_jap_kukankiroku,
      'name_univ_jap_kukankiroku': name_univ_jap_kukankiroku,
      'gakunen_univ_jap_kukankiroku': gakunen_univ_jap_kukankiroku,

      // 3階層 (大学別・日本人・個人記録)
      'time_univ_jap_kojinkiroku': round3DList(
        time_univ_jap_kojinkiroku,
      ), // ★修正★
      'year_univ_jap_kojinkiroku': year_univ_jap_kojinkiroku,
      'month_univ_jap_kojinkiroku': month_univ_jap_kojinkiroku,
      'name_univ_jap_kojinkiroku': name_univ_jap_kojinkiroku,
      'gakunen_univ_jap_kojinkiroku': gakunen_univ_jap_kojinkiroku,
    };
  }
  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  /*Map<String, dynamic> toJson() {
    return {
      'time_zentai_ryuugakusei_kukankiroku':
          time_zentai_ryuugakusei_kukankiroku,
      'year_zentai_ryuugakusei_kukankiroku':
          year_zentai_ryuugakusei_kukankiroku,
      'month_zentai_ryuugakusei_kukankiroku':
          month_zentai_ryuugakusei_kukankiroku,
      'univname_zentai_ryuugakusei_kukankiroku':
          univname_zentai_ryuugakusei_kukankiroku,
      'name_zentai_ryuugakusei_kukankiroku':
          name_zentai_ryuugakusei_kukankiroku,
      'gakunen_zentai_ryuugakusei_kukankiroku':
          gakunen_zentai_ryuugakusei_kukankiroku,

      'time_zentai_ryuugakusei_kojinkiroku':
          time_zentai_ryuugakusei_kojinkiroku,
      'year_zentai_ryuugakusei_kojinkiroku':
          year_zentai_ryuugakusei_kojinkiroku,
      'month_zentai_ryuugakusei_kojinkiroku':
          month_zentai_ryuugakusei_kojinkiroku,
      'univname_zentai_ryuugakusei_kojinkiroku':
          univname_zentai_ryuugakusei_kojinkiroku,
      'name_zentai_ryuugakusei_kojinkiroku':
          name_zentai_ryuugakusei_kojinkiroku,
      'gakunen_zentai_ryuugakusei_kojinkiroku':
          gakunen_zentai_ryuugakusei_kojinkiroku,

      'time_zentai_jap_kukankiroku': time_zentai_jap_kukankiroku,
      'year_zentai_jap_kukankiroku': year_zentai_jap_kukankiroku,
      'month_zentai_jap_kukankiroku': month_zentai_jap_kukankiroku,
      'univname_zentai_jap_kukankiroku': univname_zentai_jap_kukankiroku,
      'name_zentai_jap_kukankiroku': name_zentai_jap_kukankiroku,
      'gakunen_zentai_jap_kukankiroku': gakunen_zentai_jap_kukankiroku,

      'time_zentai_jap_kojinkiroku': time_zentai_jap_kojinkiroku,
      'year_zentai_jap_kojinkiroku': year_zentai_jap_kojinkiroku,
      'month_zentai_jap_kojinkiroku': month_zentai_jap_kojinkiroku,
      'univname_zentai_jap_kojinkiroku': univname_zentai_jap_kojinkiroku,
      'name_zentai_jap_kojinkiroku': name_zentai_jap_kojinkiroku,
      'gakunen_zentai_jap_kojinkiroku': gakunen_zentai_jap_kojinkiroku,

      // 4階層のリスト
      'time_univ_ryuugakusei_kukankiroku': time_univ_ryuugakusei_kukankiroku,
      'year_univ_ryuugakusei_kukankiroku': year_univ_ryuugakusei_kukankiroku,
      'month_univ_ryuugakusei_kukankiroku': month_univ_ryuugakusei_kukankiroku,
      'name_univ_ryuugakusei_kukankiroku': name_univ_ryuugakusei_kukankiroku,
      'gakunen_univ_ryuugakusei_kukankiroku':
          gakunen_univ_ryuugakusei_kukankiroku,

      // 3階層のリスト
      'time_univ_ryuugakusei_kojinkiroku': time_univ_ryuugakusei_kojinkiroku,
      'year_univ_ryuugakusei_kojinkiroku': year_univ_ryuugakusei_kojinkiroku,
      'month_univ_ryuugakusei_kojinkiroku': month_univ_ryuugakusei_kojinkiroku,
      'name_univ_ryuugakusei_kojinkiroku': name_univ_ryuugakusei_kojinkiroku,
      'gakunen_univ_ryuugakusei_kojinkiroku':
          gakunen_univ_ryuugakusei_kojinkiroku,

      // 4階層のリスト
      'time_univ_jap_kukankiroku': time_univ_jap_kukankiroku,
      'year_univ_jap_kukankiroku': year_univ_jap_kukankiroku,
      'month_univ_jap_kukankiroku': month_univ_jap_kukankiroku,
      'name_univ_jap_kukankiroku': name_univ_jap_kukankiroku,
      'gakunen_univ_jap_kukankiroku': gakunen_univ_jap_kukankiroku,

      // 3階層のリスト
      'time_univ_jap_kojinkiroku': time_univ_jap_kojinkiroku,
      'year_univ_jap_kojinkiroku': year_univ_jap_kojinkiroku,
      'month_univ_jap_kojinkiroku': month_univ_jap_kojinkiroku,
      'name_univ_jap_kojinkiroku': name_univ_jap_kojinkiroku,
      'gakunen_univ_jap_kojinkiroku': gakunen_univ_jap_kojinkiroku,
    };
  }*/

  // --- List<List<T>>をデシリアライズするヘルパー関数（2階層） ---
  static List<List<T>> _deserialize2DList<T>(
    dynamic data,
    T Function(dynamic) cast,
  ) {
    if (data is List) {
      return data
          .map((outer) {
            if (outer is List) {
              return outer.map((inner) => cast(inner)).toList();
            }
            return <T>[];
          })
          .toList()
          .cast<List<T>>();
    }
    return <List<T>>[];
  }

  // --- List<List<List<T>>>をデシリアライズするヘルパー関数（3階層） ---
  static List<List<List<T>>> _deserialize3DList<T>(
    dynamic data,
    T Function(dynamic) cast,
  ) {
    if (data is List) {
      return data
          .map((outer) {
            if (outer is List) {
              return outer
                  .map((middle) {
                    if (middle is List) {
                      return middle.map((inner) => cast(inner)).toList();
                    }
                    return <T>[];
                  })
                  .toList()
                  .cast<List<T>>();
            }
            return <List<T>>[];
          })
          .toList()
          .cast<List<List<T>>>();
    }
    return <List<List<T>>>[];
  }

  // --- List<List<List<List<T>>>>をデシリアライズするヘルパー関数（4階層） ---
  static List<List<List<List<T>>>> _deserialize4DList<T>(
    dynamic data,
    T Function(dynamic) cast,
  ) {
    if (data is List) {
      return data
          .map((level1) {
            if (level1 is List) {
              return level1
                  .map((level2) {
                    if (level2 is List) {
                      return level2
                          .map((level3) {
                            if (level3 is List) {
                              return level3
                                  .map((inner) => cast(inner))
                                  .toList();
                            }
                            return <T>[];
                          })
                          .toList()
                          .cast<List<T>>();
                    }
                    return <List<T>>[];
                  })
                  .toList()
                  .cast<List<List<T>>>();
            }
            return <List<List<T>>>[];
          })
          .toList()
          .cast<List<List<List<T>>>>();
    }
    return <List<List<List<T>>>>[];
  }

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory Kiroku.fromJson(Map<String, dynamic> json) {
    // キャストヘルパー
    double castDouble(dynamic e) => (e as num).toDouble();
    int castInt(dynamic e) => e as int;
    String castString(dynamic e) => e as String;

    Kiroku kiroku = Kiroku();

    // 3階層のリストのデシリアライズ (全体・区間記録)
    kiroku.time_zentai_ryuugakusei_kukankiroku = _deserialize3DList<double>(
      json['time_zentai_ryuugakusei_kukankiroku'],
      castDouble,
    );
    kiroku.year_zentai_ryuugakusei_kukankiroku = _deserialize3DList<int>(
      json['year_zentai_ryuugakusei_kukankiroku'],
      castInt,
    );
    kiroku.month_zentai_ryuugakusei_kukankiroku = _deserialize3DList<int>(
      json['month_zentai_ryuugakusei_kukankiroku'],
      castInt,
    );
    kiroku.univname_zentai_ryuugakusei_kukankiroku = _deserialize3DList<String>(
      json['univname_zentai_ryuugakusei_kukankiroku'],
      castString,
    );
    kiroku.name_zentai_ryuugakusei_kukankiroku = _deserialize3DList<String>(
      json['name_zentai_ryuugakusei_kukankiroku'],
      castString,
    );
    kiroku.gakunen_zentai_ryuugakusei_kukankiroku = _deserialize3DList<int>(
      json['gakunen_zentai_ryuugakusei_kukankiroku'],
      castInt,
    );

    // 2階層のリストのデシリアライズ (全体・個人記録)
    kiroku.time_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<double>(
      json['time_zentai_ryuugakusei_kojinkiroku'],
      castDouble,
    );
    kiroku.year_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<int>(
      json['year_zentai_ryuugakusei_kojinkiroku'],
      castInt,
    );
    kiroku.month_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<int>(
      json['month_zentai_ryuugakusei_kojinkiroku'],
      castInt,
    );
    kiroku.univname_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<String>(
      json['univname_zentai_ryuugakusei_kojinkiroku'],
      castString,
    );
    kiroku.name_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<String>(
      json['name_zentai_ryuugakusei_kojinkiroku'],
      castString,
    );
    kiroku.gakunen_zentai_ryuugakusei_kojinkiroku = _deserialize2DList<int>(
      json['gakunen_zentai_ryuugakusei_kojinkiroku'],
      castInt,
    );

    // 3階層のリストのデシリアライズ (全体・日本人・区間記録)
    kiroku.time_zentai_jap_kukankiroku = _deserialize3DList<double>(
      json['time_zentai_jap_kukankiroku'],
      castDouble,
    );
    kiroku.year_zentai_jap_kukankiroku = _deserialize3DList<int>(
      json['year_zentai_jap_kukankiroku'],
      castInt,
    );
    kiroku.month_zentai_jap_kukankiroku = _deserialize3DList<int>(
      json['month_zentai_jap_kukankiroku'],
      castInt,
    );
    kiroku.univname_zentai_jap_kukankiroku = _deserialize3DList<String>(
      json['univname_zentai_jap_kukankiroku'],
      castString,
    );
    kiroku.name_zentai_jap_kukankiroku = _deserialize3DList<String>(
      json['name_zentai_jap_kukankiroku'],
      castString,
    );
    kiroku.gakunen_zentai_jap_kukankiroku = _deserialize3DList<int>(
      json['gakunen_zentai_jap_kukankiroku'],
      castInt,
    );

    // 2階層のリストのデシリアライズ (全体・日本人・個人記録)
    kiroku.time_zentai_jap_kojinkiroku = _deserialize2DList<double>(
      json['time_zentai_jap_kojinkiroku'],
      castDouble,
    );
    kiroku.year_zentai_jap_kojinkiroku = _deserialize2DList<int>(
      json['year_zentai_jap_kojinkiroku'],
      castInt,
    );
    kiroku.month_zentai_jap_kojinkiroku = _deserialize2DList<int>(
      json['month_zentai_jap_kojinkiroku'],
      castInt,
    );
    kiroku.univname_zentai_jap_kojinkiroku = _deserialize2DList<String>(
      json['univname_zentai_jap_kojinkiroku'],
      castString,
    );
    kiroku.name_zentai_jap_kojinkiroku = _deserialize2DList<String>(
      json['name_zentai_jap_kojinkiroku'],
      castString,
    );
    kiroku.gakunen_zentai_jap_kojinkiroku = _deserialize2DList<int>(
      json['gakunen_zentai_jap_kojinkiroku'],
      castInt,
    );

    // 4階層のリストのデシリアライズ (大学別・留学生・区間記録)
    kiroku.time_univ_ryuugakusei_kukankiroku = _deserialize4DList<double>(
      json['time_univ_ryuugakusei_kukankiroku'],
      castDouble,
    );
    kiroku.year_univ_ryuugakusei_kukankiroku = _deserialize4DList<int>(
      json['year_univ_ryuugakusei_kukankiroku'],
      castInt,
    );
    kiroku.month_univ_ryuugakusei_kukankiroku = _deserialize4DList<int>(
      json['month_univ_ryuugakusei_kukankiroku'],
      castInt,
    );
    kiroku.name_univ_ryuugakusei_kukankiroku = _deserialize4DList<String>(
      json['name_univ_ryuugakusei_kukankiroku'],
      castString,
    );
    kiroku.gakunen_univ_ryuugakusei_kukankiroku = _deserialize4DList<int>(
      json['gakunen_univ_ryuugakusei_kukankiroku'],
      castInt,
    );

    // 3階層のリストのデシリアライズ (大学別・留学生・個人記録)
    kiroku.time_univ_ryuugakusei_kojinkiroku = _deserialize3DList<double>(
      json['time_univ_ryuugakusei_kojinkiroku'],
      castDouble,
    );
    kiroku.year_univ_ryuugakusei_kojinkiroku = _deserialize3DList<int>(
      json['year_univ_ryuugakusei_kojinkiroku'],
      castInt,
    );
    kiroku.month_univ_ryuugakusei_kojinkiroku = _deserialize3DList<int>(
      json['month_univ_ryuugakusei_kojinkiroku'],
      castInt,
    );
    kiroku.name_univ_ryuugakusei_kojinkiroku = _deserialize3DList<String>(
      json['name_univ_ryuugakusei_kojinkiroku'],
      castString,
    );
    kiroku.gakunen_univ_ryuugakusei_kojinkiroku = _deserialize3DList<int>(
      json['gakunen_univ_ryuugakusei_kojinkiroku'],
      castInt,
    );

    // 4階層のリストのデシリアライズ (大学別・日本人・区間記録)
    kiroku.time_univ_jap_kukankiroku = _deserialize4DList<double>(
      json['time_univ_jap_kukankiroku'],
      castDouble,
    );
    kiroku.year_univ_jap_kukankiroku = _deserialize4DList<int>(
      json['year_univ_jap_kukankiroku'],
      castInt,
    );
    kiroku.month_univ_jap_kukankiroku = _deserialize4DList<int>(
      json['month_univ_jap_kukankiroku'],
      castInt,
    );
    kiroku.name_univ_jap_kukankiroku = _deserialize4DList<String>(
      json['name_univ_jap_kukankiroku'],
      castString,
    );
    kiroku.gakunen_univ_jap_kukankiroku = _deserialize4DList<int>(
      json['gakunen_univ_jap_kukankiroku'],
      castInt,
    );

    // 3階層のリストのデシリアライズ (大学別・日本人・個人記録)
    kiroku.time_univ_jap_kojinkiroku = _deserialize3DList<double>(
      json['time_univ_jap_kojinkiroku'],
      castDouble,
    );
    kiroku.year_univ_jap_kojinkiroku = _deserialize3DList<int>(
      json['year_univ_jap_kojinkiroku'],
      castInt,
    );
    kiroku.month_univ_jap_kojinkiroku = _deserialize3DList<int>(
      json['month_univ_jap_kojinkiroku'],
      castInt,
    );
    kiroku.name_univ_jap_kojinkiroku = _deserialize3DList<String>(
      json['name_univ_jap_kojinkiroku'],
      castString,
    );
    kiroku.gakunen_univ_jap_kojinkiroku = _deserialize3DList<int>(
      json['gakunen_univ_jap_kojinkiroku'],
      castInt,
    );

    return kiroku;
  }
}
