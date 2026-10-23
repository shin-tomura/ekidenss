import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/album_tsuika.dart';

// ------------------------------------------------------------
// 学内メディアの卒業生特集の、選手ごとの「この選手をアルバムに追加」(2.1.4)
// ・各選手の小見出しのすぐ下に置く(紹介の最後だと、次の選手の小見出しのすぐ上になり、どちらの選手のボタンか紛らわしいため)
// ・処理は選手画面の「この選手をアルバムに追加」と同じ(kansuu/album_tsuika.dart)。足せるのは3月25日の、
//   自分の大学の4年生だけ(それ以外のときは何も出さない)
// ・何人も続けて足せるように、確認を出さずにすぐ足し、「アルバムに追加済み(取り消す)」に変える。
//   もう一度押すと取り消す(足さなかったときと同じになる)。選手画面で先に足した選手は、最初から追加済みにする
// ・文字を大きくしていても折り返せるように、1つの Text にする
// ------------------------------------------------------------

class AlbumTsuikaBotan extends StatefulWidget {
  const AlbumTsuikaBotan({super.key, required this.senshuId});

  /// 選手の番号(枠の番号)
  final int senshuId;

  @override
  State<AlbumTsuikaBotan> createState() => _AlbumTsuikaBotanState();
}

class _AlbumTsuikaBotanState extends State<AlbumTsuikaBotan> {
  /// 足している・取り消している途中(続けて押されないように)
  bool _shorichuu = false;

  Ghensuu? _gh() => Hive.isBoxOpen('ghensuuBox')
      ? Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu')
      : null;

  SenshuData? _senshu() {
    if (!Hive.isBoxOpen('senshuBox')) return null;
    for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
      if (s.id == widget.senshuId) return s;
    }
    return null;
  }

  Future<void> _osu(Ghensuu gh, SenshuData s, bool zumi) async {
    if (_shorichuu) return;
    setState(() => _shorichuu = true);
    String moji;
    try {
      if (zumi) {
        await albumKaraTorikesu(gh, s);
        moji = '${s.name} のアルバムへの追加を取り消しました。';
      } else {
        final r = await albumNiTsuika(gh, s);
        moji = '${r.name} をアルバムに追加しました (${r.sijiflag}年卒)。';
      }
    } catch (_) {
      moji = 'アルバムに追加できませんでした。';
    }
    if (!mounted) return;
    setState(() => _shorichuu = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(moji)));
  }

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = _gh();
    final SenshuData? s = _senshu();
    if (gh == null || s == null || !albumTsuikaDekiru(gh, s)) {
      return const SizedBox.shrink();
    }
    final bool zumi = albumTsuikaZumi(gh, s);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        onPressed: _shorichuu ? null : () => _osu(gh, s, zumi),
        child: Text(
          zumi ? '✓ アルバムに追加済み(取り消す)' : 'この選手をアルバムに追加',
          style: TextStyle(
            color: zumi ? HENSUU.textcolor : HENSUU.LinkColor,
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: zumi ? HENSUU.textcolor : HENSUU.LinkColor,
          ),
        ),
      ),
    );
  }
}
