import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
//import 'package:ekiden/kantoku_data.dart'; //
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/screens/senshu_r_screen.dart';
import 'package:ekiden/album.dart';

class RijiIchiranScreen extends StatefulWidget {
  const RijiIchiranScreen({super.key});

  @override
  State<RijiIchiranScreen> createState() => _RijiIchiranScreenState();
}

class _RijiIchiranScreenState extends State<RijiIchiranScreen> {
  // RijiDataのインスタンスを作成（この時点ではデータ取得は行わず、
  // meishouリストの初期値を使用します）
  final rijiBox = Hive.box<RijiData>('rijiBox');
  final rsenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
  final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
  final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final albumBox = Hive.box<Album>('albumBox');

  @override
  Widget build(BuildContext context) {
    // Boxからデータを読み込む
    final RijiData riji = rijiBox.get('RijiData')!;
    final allRetiredSenshu = rsenshuBox.values.toList();
    final List<UnivData> allUnivData = univdataBox.values.toList();
    final List<UnivData> sortedUnivData = allUnivData
      ..sort((a, b) => a.id.compareTo(b.id));
    final Ghensuu currentGhensuu = ghensuuBox.getAt(0)!;
    final Album album = albumBox.get('AlbumData')!;
    // Scaffoldのレイアウトは、ご提示いただいたコードを参考にします。
    return Scaffold(
      appBar: AppBar(
        // 色と高さは参考コードに合わせます
        backgroundColor: Colors.grey[900],
        centerTitle: false,
        titleSpacing: 0.0,
        toolbarHeight: HENSUU.appbar_height,
        title: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // タイトルとして「理事会役職一覧」を表示
              Text(
                '箱庭陸連役員一覧',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ],
          ),
        ),
      ),

      // ボディ
      body: Container(
        // 全体の背景を少し暗くする（任意）
        color: Colors.grey[850],
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: riji.meishou.length,
          itemBuilder: (context, index) {
            final String yakushokumei = riji.meishou[index];
            String name = "不在";
            int age = 0;
            String univname = "？？？？";
            int rid = 0;
            for (var rsenshu in allRetiredSenshu) {
              if (riji.rid_riji[index] == rsenshu.id) {
                name = rsenshu.name;
                age = currentGhensuu.year - rsenshu.sijiflag + 22;
                univname = sortedUnivData[rsenshu.univid].name;
                rid = rsenshu.id;
                break;
              }
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 8.0,
              ),
              child: Card(
                color: Colors.black, // カードの背景色
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // Rowを使って、インデックスと役職名を横に並べる
                  child: Row(
                    children: [
                      // No.を表示 (左端)
                      Container(
                        width: 30, // 幅を固定
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${index + 1}.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: HENSUU.fontsize_honbun,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8.0),

                      // 役職名 (中央寄せで、複数行対応)
                      if (rid == 0)
                        Expanded(
                          child: Text(
                            "${yakushokumei}\n"
                            "${name} ${age}歳\n"
                            "${univname}大学出身",
                            // 長いテキストが複数行にわたることを許可
                            softWrap: true,
                            // 中央寄せ
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: HENSUU.fontsize_honbun + 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          // ⬅️ Expanded を TextButton の外に移動
                          child: TextButton(
                            onPressed: () async {
                              album.yobiint3 = rid;
                              await album.save();
                              // Navigator.push を使用して Senshu_R_Screen へ遷移
                              Navigator.push(
                                context,
                                // MaterialPageRoute を使用して新しい画面を定義
                                MaterialPageRoute(
                                  builder: (context) => const Senshu_R_Screen(),
                                ),
                              );
                            },
                            // TextButton の子ウィジェットとして Text を指定する
                            child: Text(
                              // ⬅️ TextButton の child: を追加
                              "${yakushokumei}\n"
                              "${name} ${age}歳\n"
                              "${univname}大学出身",
                              // 長いテキストが複数行にわたることを許可
                              softWrap: true,
                              // 中央寄せ
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HENSUU.LinkColor,
                                fontSize: HENSUU.fontsize_honbun + 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
