import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kansuu/asset_loader.dart';

// ------------------------------------------------------------
// 選手の下の名前リストの置き換え(1.7.8)
//
// 下の名前のリストは、新規ゲーム開始時にアセット(name_ato.txt)から
// セーブデータ(Ghensuu.name_ato)へコピーされ、その後はセーブデータ側が使われる。
// そのため、既存のセーブデータのリストが1.7.7以前の古いリストのままなら、
// 新しいリストに置き換える(起動時と保存ゲームの読み込み時に呼ぶ)。
// リストの中身で判定するので、1回置き換えた後は何もしない。
// 置き換わるのはこれから作られる選手の名前だけで、今いる選手・引退選手・記録の名前は変わらない。
// ------------------------------------------------------------

/// 古いリスト(1.7.7以前)の先頭の名前
const List<String> _furuiListSentou = ['晃', '昭', '明', '昌', '彰', '章', '朗', '歩', '歩夢', '旭'];

bool _isFuruiList(List<String> nameAto) {
  if (nameAto.length < _furuiListSentou.length) return false;
  for (int i = 0; i < _furuiListSentou.length; i++) {
    if (nameAto[i] != _furuiListSentou[i]) return false;
  }
  return true;
}

/// 下の名前リストが古いままなら、新しいリストに置き換える
Future<void> nameAtoListKoushin() async {
  final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  if (ghensuuBox.isEmpty) return;
  final Ghensuu? gh = ghensuuBox.getAt(0);
  if (gh == null || !_isFuruiList(gh.name_ato)) return;

  final List<String> atarashii = await loadLinesFromAsset(
    'lib/assets/data/name_ato.txt',
  );
  if (atarashii.isEmpty) return; // 読み込めなかった場合は古いリストのまま

  // 件数は今のリストと同じにそろえる(足りない場合は古いリストの名前が残る)
  final List<String> nameAto = List<String>.from(gh.name_ato);
  for (int i = 0; i < nameAto.length && i < atarashii.length; i++) {
    nameAto[i] = atarashii[i].trim();
  }
  gh.name_ato = nameAto;
  await gh.save();
  print('下の名前のリストを新しいリストに置き換えました(${atarashii.length}件)');
}
