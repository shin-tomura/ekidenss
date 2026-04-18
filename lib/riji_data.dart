import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'riji_data.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 9) // ユニークなtypeIdを指定
class RijiData extends HiveObject {
  //[0~29監督、30~59コーチ1、60~89コーチ2]
  @HiveField(0)
  List<int> rid_riji = List.filled(10, 0); //Senshu_R_Dataのidを格納、0なら不在
  @HiveField(1)
  List<String> meishou = [
    "会長",
    "副会長",
    "駅伝世界化推進委員長",
    "オリンピック対策強化委員長",
    "世界選手権対策強化委員長",
    "競技会開催運営委員長",
    "科学的トレーニング研究室長",
    "健康維持管理対策室長",
    "陸上用具研究開発室長",
    "ドーピング対策兼安全管理委員長",
  ]; // 理事の名称

  // コンストラクタ (Swiftのinit()に対応)
  RijiData(); // 引数なしのコンストラクタ

  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  Map<String, dynamic> toJson() {
    // meishouは定数として扱うか、保存対象に含めます。
    // HiveType(typeId: 9)が付いているので、HiveはHiveField(0)のみを扱う可能性もありますが、
    // toJson/fromJsonはJSONシリアライズのために全フィールドを含めるのが一般的です。
    return {
      'rid_riji': rid_riji,
      'meishou': meishou, // 念のため保存
    };
  }

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory RijiData.fromJson(Map<String, dynamic> json) {
    // meishouは定数リストであるため、ロードされたデータで上書きする必要はないが、
    // JSONに含まれている場合はロードされたデータで初期化します。
    // ただし、DartのList.filled()で初期化されたフィールドに対するfromJsonでは、
    // fromJsonで代入処理を明示的に行う必要があります。
    return RijiData()
      ..rid_riji = (json['rid_riji'] as List).cast<int>()
      ..meishou = (json['meishou'] as List).cast<String>();
    // meishouは固定値なので、実際には上記の行は省略し、
    // `RijiData()`が返すデフォルト値に頼ることもできますが、
    // JSONの形式が完璧であることを前提に、ロードされたデータで上書きします。
  }
}
