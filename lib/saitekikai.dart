import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスがあるはずのインポート
import 'package:ekiden/album.dart';

class ModalComputerTeamProb extends StatefulWidget {
  const ModalComputerTeamProb({super.key});

  @override
  State<ModalComputerTeamProb> createState() => _ModalComputerTeamProbState();
}

class _ModalComputerTeamProbState extends State<ModalComputerTeamProb> {
  late Box<Album> _albumBox;

  @override
  void initState() {
    super.initState();
    // 適切なBox名に変更してください
    _albumBox = Hive.box<Album>('albumBox');
  }

  // 「最適解区間配置確率」の値を変更し、Hiveに保存する関数
  void _updateProbabilityValue(Album album, double sliderValue) async {
    // スライダーの値(0.0-100.0)をそのままint型(0-100)に変換してtourokusuu_totalに保存
    final int newProbability = sliderValue.toInt();

    setState(() {
      // tourokusuu_total はコンピュータチームの最適解区間配置確率 (0-100)
      album.tourokusuu_total = newProbability;
    });
    // 保存前に念のため0-100の範囲に収める (スライダーで制御されるが保険として)
    album.tourokusuu_total = album.tourokusuu_total.clamp(0, 100);
    await album.save();
  }

  // 確率表示用のテキストを生成
  String _getProbabilityText(int probabilityValue) {
    return '現在の確率: $probabilityValue%';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Album>>(
      valueListenable: _albumBox.listenable(),
      builder: (context, albumBox, _) {
        final List<Album> allAlbums = albumBox.values.toList();

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '最適解区間配置確率編集', // タイトル変更
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
                  // 確率設定についての説明
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "この設定は、コンピュータが操作するチームが、試走タイムから判断して理想的な区間配置を行う確率を設定します(初期値は30％)\n\n0%：最適解配置をしない（すべてのチームが区間の重要度順に決定していく配置方法になる）\n100%：必ず最適解区間配置を行う\n\nなお、コンピュータチームの区間配置に重複や空白がたびたび発生する場合には、この設定を0％にすると不具合を回避できるかもしれません。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // データがない場合の表示
                  if (allAlbums.isEmpty)
                    Center(
                      child: Text(
                        'アルバムデータがありません',
                        style: TextStyle(color: HENSUU.textcolor),
                      ),
                    )
                  else
                    // データがある場合のリスト表示（今回は最初のAlbumのみを想定）
                    ...allAlbums.take(1).map((album) {
                      // tourokusuu_total の値をそのままスライダー値として使う (0-100)
                      final double currentSliderValue = album.tourokusuu_total
                          .toDouble();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 確率の現在の値表示
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              _getProbabilityText(album.tourokusuu_total),
                              style: TextStyle(
                                color: album.tourokusuu_total < 50
                                    ? Colors.greenAccent
                                    : (album.tourokusuu_total < 80
                                          ? Colors.yellow
                                          : Colors.redAccent),
                                fontSize: HENSUU.fontsize_honbun,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 確率設定のスライダー
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Slider(
                                  // tourokusuu_totalの値をそのままスライダー値として使う
                                  value: currentSliderValue,
                                  min: 0, // 左端は 0%
                                  max: 100, // 右端は 100%
                                  divisions: 100, // 0から100の101段階 (1%刻み)
                                  // スライダーのラベルは現在の値を表示
                                  label: '${album.tourokusuu_total}%',
                                  onChanged: (double newValue) {
                                    // スライダー操作中はsetStateで一時的に表示を更新
                                    final int newProbability = newValue.toInt();
                                    setState(() {
                                      album.tourokusuu_total = newProbability;
                                    });
                                  },
                                  onChangeEnd: (double newValue) {
                                    // 操作終了時にHiveに保存
                                    _updateProbabilityValue(album, newValue);
                                  },
                                  activeColor: Colors.purple, // 色を変更
                                  inactiveColor: Colors.grey.withOpacity(0.5),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '0% (ランダム配置)', // 左端: 0%
                                      style: TextStyle(
                                        color: HENSUU.textcolor.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '100% (最適解配置)', // 右端: 100%
                                      style: TextStyle(
                                        color: HENSUU.textcolor.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Divider(color: Colors.grey),
                        ],
                      );
                    }).toList(),

                  const SizedBox(height: 16),
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
                      "戻る",
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
