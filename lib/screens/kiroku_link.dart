import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/kansuu/rekidai_kiroku.dart' show senshuTsuusanBangou;
import 'package:ekiden/kansuu/tsuusan.dart' show TsuusanSozai;
import 'package:ekiden/screens/Modal_senshu.dart' show ModalSenshuDetailView;
import 'package:ekiden/screens/senshu_r_screen.dart' show Senshu_R_Screen;

// ------------------------------------------------------------
// 記録の選手名のリンク(2.1.4)
//
// 記録画面の選手名と、結果画面の一言の選手名(走った選手・前の記録の持ち主)を押すと、その選手を開く。
// 記録と選手は通算の番号(rekidai_kiroku.dart の senshuTsuusanBangou)だけで結びつける。
// ・現役の選手(どの大学でも): 選手の詳細の小窓(ModalSenshuDetailView。ランキングの「詳細」と同じ開き方)
// ・残っている卒業生(卒業生の箱に残っている選手と、アルバムに自分で足した選手): 1人だけを出す卒業生の画面
//   (監督・コーチの名前を押したときと同じく、アルバムの yobiint3 に番号を入れて Senshu_R_Screen を開く)
// ・番号のない記録(2.1.4より前に出た記録)・残っていない卒業生(留学生も)は、リンクにしない
// ・アルバムに自分で足した選手の番号は「枠の番号+足した年×1000」なので、選手画面の歴代記録の表と同じく
//   候補から卒業する年の番号を出す(TsuusanSozai.bangouKouho)。本当の卒業生の番号を先に入れる
// 画面を描くたびに、現役の選手と卒業生の番号の一覧を作る(どちらも数百人なので軽い)
// ------------------------------------------------------------

/// 通算の番号から、開く選手を引く一覧
class KirokuLinkJisho {
  /// 現役の選手(通算の番号 → 枠の番号)
  final Map<int, int> _genneki = {};

  /// 残っている卒業生(通算の番号 → 卒業生の番号)
  final Map<int, int> _sotsugyou = {};

  KirokuLinkJisho() {
    try {
      if (!Hive.isBoxOpen('ghensuuBox')) return;
      final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
      if (gh == null) return;
      if (Hive.isBoxOpen('senshuBox')) {
        for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
          _genneki[senshuTsuusanBangou(gh, s)] = s.id;
        }
      }
      if (Hive.isBoxOpen('retiredSenshuBox')) {
        final List<Senshu_R_Data> r = Hive.box<Senshu_R_Data>('retiredSenshuBox').values.toList();
        // 本当の卒業生を先に入れ、アルバムに自分で足した選手は、空いている番号にだけ入れる
        for (final bool jibun in [false, true]) {
          for (final Senshu_R_Data x in r) {
            if ((x.sijiseikouflag == 100) != jibun) continue;
            for (final int b in TsuusanSozai.sotsugyou(x).bangouKouho(gh)) {
              _sotsugyou.putIfAbsent(b, () => x.id);
            }
          }
        }
      }
    } catch (_) {
      // 一覧が作れなければ、リンクにしない
    }
  }

  /// 番号[bangou]の選手を開けるか(番号がない記録・残っていない卒業生は false)
  bool aru(int? bangou) =>
      bangou != null && (_genneki.containsKey(bangou) || _sotsugyou.containsKey(bangou));

  /// 番号[bangou]の選手を開く(現役は小窓、卒業生は卒業生の画面)
  Future<void> hiraku(BuildContext context, int bangou) async {
    final int? senshuId = _genneki[bangou];
    if (senshuId != null) {
      showGeneralDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.8),
        barrierDismissible: true,
        barrierLabel: '詳細',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, __) => ModalSenshuDetailView(senshuId: senshuId),
      );
      return;
    }
    final int? rid = _sotsugyou[bangou];
    if (rid == null || !Hive.isBoxOpen('albumBox')) return;
    final Album? album = Hive.box<Album>('albumBox').get('AlbumData');
    if (album == null) return;
    album.yobiint3 = rid;
    await album.save();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Senshu_R_Screen()),
    );
  }

  /// 選手名[name]を、開けるならリンクにした文字(開けなければふつうの文字)
  Widget namae(BuildContext context, String name, int? bangou, TextStyle style) {
    if (!aru(bangou)) return Text(name, style: style);
    final int b = bangou!;
    return GestureDetector(
      onTap: () => hiraku(context, b),
      child: Text(
        name,
        style: style.copyWith(
          color: HENSUU.LinkColor,
          decoration: TextDecoration.underline,
          decorationColor: HENSUU.LinkColor,
        ),
      ),
    );
  }
}
