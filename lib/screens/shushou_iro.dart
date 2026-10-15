import 'package:flutter/material.dart';

// ------------------------------------------------------------
// 主将を示す色(2.0.1。仕組みは lib/kansuu/shushou.dart)
// ・列の幅が決まっている表(今季タイム一覧表・駅伝成績一覧)は、文字を増やさずに名前の欄をこの色にする
// ・カード(区間配置確認)は、この色の枠にする
// ・表のほかの色付け(1位の金・2位の水色・3位の橙、駅伝男のピンク・平常心の水色)で使っていない緑
// ------------------------------------------------------------

/// 主将の名前の欄・カードの背景(緑(Colors.green.shade800)の30%)
const Color shushouIroHaikei = Color(0x4D2E7D32);

/// 主将の名前の欄の左端の線・カードの枠(Colors.greenAccent)
const Color shushouIroSen = Color(0xFF69F0AE);

/// 表の名前の欄の飾り(背景と左端の線)
const BoxDecoration shushouKazari = BoxDecoration(
  color: shushouIroHaikei,
  border: Border(left: BorderSide(color: shushouIroSen, width: 4)),
);
