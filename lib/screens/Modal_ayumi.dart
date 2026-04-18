import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// constants.dartとuniv_data.dartは既存コードのimportを流用
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';

// --------------------------------------------------------------------------
// Isolate (バックグラウンド処理) 用のデータ構造
// --------------------------------------------------------------------------

/// 検索結果を格納するクラス（ヒットしたブロックとブロック内の文字インデックス）
class BlockMatchLocation {
  final int blockIndex; // ヒットしたブロックのインデックス
  final int charIndexInBlock; // ブロック内での文字開始インデックス
  BlockMatchLocation(this.blockIndex, this.charIndexInBlock);
}

class FullSearchResult {
  final List<BlockMatchLocation> foundMatches;
  FullSearchResult(this.foundMatches);
}

/// 全ブロックのリストを受け取り、全ブロックを検索するバックグラウンド関数
Future<FullSearchResult> _findAllIndices(Map<String, dynamic> data) async {
  final List<String> dataBlocks = data['dataBlocks'] as List<String>;
  final String query = data['query'] as String;
  final List<BlockMatchLocation> foundMatches = [];

  // ここでは、呼び出し元で既にクエリの妥当性がチェックされていることを前提とする
  if (query.isNotEmpty) {
    final String lowerQuery = query.toLowerCase();

    for (int blockIndex = 0; blockIndex < dataBlocks.length; blockIndex++) {
      final String blockText = dataBlocks[blockIndex].toLowerCase();

      int searchStartIndex = 0;
      while (searchStartIndex < blockText.length) {
        final int matchIndex = blockText.indexOf(lowerQuery, searchStartIndex);
        if (matchIndex == -1) break;

        // ヒット位置をブロックインデックスとブロック内インデックスとして記録
        foundMatches.add(BlockMatchLocation(blockIndex, matchIndex));
        searchStartIndex = matchIndex + lowerQuery.length;
      }
    }
  }
  return FullSearchResult(foundMatches);
}

// --------------------------------------------------------------------------
// メインウィジェット：ModalTeamHistoryView
// --------------------------------------------------------------------------

class ModalTeamHistoryView extends StatefulWidget {
  const ModalTeamHistoryView({super.key});

  @override
  State<ModalTeamHistoryView> createState() => _ModalTeamHistoryViewState();
}

class _ModalTeamHistoryViewState extends State<ModalTeamHistoryView> {
  List<String> _dataBlocks = [];
  String _currentBlockText = '';
  int _currentBlockIndex = 0;

  static const int _linesPerBlock = 1000;
  static const int _overlapLinesCount = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<BlockMatchLocation> _allFoundMatches = [];
  List<double> _currentBlockScrollOffsets = [];
  int _currentFoundIndex = -1; // _allFoundMatchesに対するインデックス

  bool _isSearching = false;

  final GlobalKey _scrollableKey = GlobalKey();
  final GlobalKey _richTextKey = GlobalKey();

  static const double _baseFontSize = 16.0;
  static const double _paddingVertical = 12.0;
  static const double _searchBarHeightOffset = 60.0;

  List<String> _allLines = [];

  @override
  void initState() {
    super.initState();
    _loadTeamHistory();
  }

  void _loadTeamHistory() {
    final univDataBox = Hive.box<UnivData>('univBox');
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    String fullText;
    if (sortedUnivData.length > 8) {
      fullText = sortedUnivData[8].name_tanshuku;
    } else {
      fullText = '戦績データ（sortedUnivData[8]）が見つかりません。';
    }

    _allLines = fullText.split('\n');
    if (_allLines.last.isEmpty) {
      _allLines.removeLast();
    }

    _dataBlocks.clear();
    for (
      int i = 0;
      i < _allLines.length;
      i += (_linesPerBlock - _overlapLinesCount)
    ) {
      final int start = i;
      int end = start + _linesPerBlock;
      if (end > _allLines.length) {
        end = _allLines.length;
      }

      _dataBlocks.add(_allLines.sublist(start, end).join('\n'));

      if (end == _allLines.length) break;
    }

    _updateCurrentBlock(0, isInitialLoad: true);
  }

  /// インデックスを循環させるロジックを追加
  void _updateCurrentBlock(
    int newIndex, {
    bool isInitialLoad = false,
    int? scrollTargetCharIndex,
  }) {
    if (_dataBlocks.isEmpty) return;

    // 循環ロジック
    int effectiveIndex = newIndex % _dataBlocks.length;
    if (effectiveIndex < 0) {
      effectiveIndex += _dataBlocks.length;
    }

    // 現在のブロックと同じなら何もしない（スクロールターゲットが指定されている場合を除く）
    if (effectiveIndex == _currentBlockIndex &&
        !isInitialLoad &&
        scrollTargetCharIndex == null) {
      return;
    }

    _currentBlockIndex = effectiveIndex;
    _currentBlockText = _dataBlocks[_currentBlockIndex];

    // ブロックが切り替わった場合、スクロール位置をリセット
    if (!isInitialLoad) {
      // 検索結果のオフセットを再計算
      _calculateOffsets(scrollTargetCharIndex: scrollTargetCharIndex);
    }

    // UIを更新
    setState(() {
      // _currentFoundIndex は検索ロジック側で更新されるため、ここではリセットしない
    });
  }

  /// 💡 修正点: 検索ボタンのメインアクションに文字数制限チェックを追加
  void _startFullSearch() async {
    final String query = _searchController.text;

    // --- 💡 追加した文字数・スペースチェック ---
    if (query.isEmpty || query.length < 2 || query.trim().isEmpty) {
      // 検索結果をクリア
      setState(() {
        _allFoundMatches.clear();
        _currentFoundIndex = -1;
      });

      // ユーザーへのフィードバック
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('検索文字は2文字以上にしてください。空白文字のみでの検索はできません。'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    // ----------------------------------------

    setState(() {
      _isSearching = true; // ローディング開始
      _allFoundMatches.clear();
      _currentFoundIndex = -1;
      _currentBlockScrollOffsets.clear();
    });

    // Isolateで全ブロックを検索
    final FullSearchResult result = await compute(_findAllIndices, {
      'dataBlocks': _dataBlocks,
      'query': query,
    });

    _allFoundMatches = result.foundMatches;

    // 検索完了後、ローディング終了
    setState(() {
      _isSearching = false;
    });

    // 最初のヒット位置へ移動
    if (_allFoundMatches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 最初のヒット位置のブロックに切り替えてスクロール
        _jumpToFoundText(0);
      });
    }
  }

  /// 検索結果に基づいてブロック切り替えとスクロールを実行
  void _jumpToFoundText(int globalIndex) {
    if (_allFoundMatches.isEmpty || !_scrollController.hasClients) return;

    // 循環ロジックを適用
    int nextIndex = globalIndex % _allFoundMatches.length;
    if (nextIndex < 0) {
      nextIndex += _allFoundMatches.length;
    }

    final BlockMatchLocation target = _allFoundMatches[nextIndex];

    setState(() {
      _currentFoundIndex = nextIndex;
    });

    // ターゲットのブロックが現在表示されているブロックと異なる場合
    if (target.blockIndex != _currentBlockIndex) {
      // ブロックを切り替え、切り替え後にターゲット位置へスクロールさせるよう指示
      _updateCurrentBlock(
        target.blockIndex,
        scrollTargetCharIndex: target.charIndexInBlock,
      );
    } else {
      // 同じブロック内の移動の場合、すぐにオフセットを計算してスクロール
      _calculateOffsets(scrollTargetCharIndex: target.charIndexInBlock);
    }
  }

  /// 現在の_allFoundMatchesと_currentFoundIndexから、
  /// 現在のブロック内でハイライトすべき位置を特定する
  List<int> _getCurrentBlockMatchStarts() {
    return _allFoundMatches
        .where((match) => match.blockIndex == _currentBlockIndex)
        .map((match) => match.charIndexInBlock)
        .toList();
  }

  /// _currentBlockScrollOffsetsを計算し、必要であればターゲットにスクロール
  void _calculateOffsets({int? scrollTargetCharIndex}) {
    _currentBlockScrollOffsets.clear();

    final List<int> currentBlockMatches = _getCurrentBlockMatchStarts();
    if (currentBlockMatches.isEmpty) {
      // 現在のブロックに検索結果がない場合はスクロールしない
      return;
    }

    final RenderBox? richTextRenderBox =
        _richTextKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? scrollBox =
        _scrollableKey.currentContext?.findRenderObject() as RenderBox?;

    if (richTextRenderBox == null || scrollBox == null) return;

    final double scaleFactor = MediaQuery.of(
      context,
    ).textScaler.textScaleFactor;
    final double dynamicFontSize = _baseFontSize * scaleFactor;

    final TextSpan fullTextSpan = TextSpan(
      style: TextStyle(color: Colors.white, fontSize: dynamicFontSize),
      text: _currentBlockText,
    );

    final TextPainter textPainter = TextPainter(
      text: fullTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: null,
    );

    final double richTextWidth = richTextRenderBox.size.width;
    textPainter.layout(maxWidth: richTextWidth);

    final double offsetFromScrollViewStart = _paddingVertical;

    for (final index in currentBlockMatches) {
      final TextPosition textPosition = TextPosition(offset: index);
      final Offset textOffset = textPainter.getOffsetForCaret(
        textPosition,
        Rect.zero,
      );

      final double targetY = textOffset.dy + offsetFromScrollViewStart;
      _currentBlockScrollOffsets.add(targetY);
    }

    if (scrollTargetCharIndex != null) {
      // ブロックが切り替わった場合、ターゲットの文字インデックスに対応するオフセットを探す
      final int localIndex = currentBlockMatches.indexOf(scrollTargetCharIndex);
      if (localIndex != -1) {
        final double targetY = _currentBlockScrollOffsets[localIndex];
        _animateScrollToY(targetY);
      }
    } else if (_currentFoundIndex != -1) {
      // _allFoundMatches全体での_currentFoundIndexが、現在のブロック内で何番目のマッチかを特定
      final int localIndex = _allFoundMatches
          .where((match) => match.blockIndex == _currentBlockIndex)
          .toList()
          .indexWhere(
            (match) =>
                match.blockIndex ==
                    _allFoundMatches[_currentFoundIndex].blockIndex &&
                match.charIndexInBlock ==
                    _allFoundMatches[_currentFoundIndex].charIndexInBlock,
          );

      if (localIndex != -1) {
        final double targetY = _currentBlockScrollOffsets[localIndex];
        _animateScrollToY(targetY);
      }
    }

    setState(() {}); // RichTextの再描画のため
  }

  void _animateScrollToY(double targetY) {
    if (!_scrollController.hasClients) return;

    final double finalOffset = targetY - _searchBarHeightOffset;

    _scrollController.animateTo(
      finalOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 上下矢印ボタンの共通アクション
  void _scrollNext(int direction) {
    if (_allFoundMatches.isEmpty) return;

    _jumpToFoundText(_currentFoundIndex + direction);
  }

  TextSpan _buildSearchableText(BuildContext context) {
    // 現在のブロック内のマッチ位置のみを使用してハイライト
    final String query = _searchController.text.toLowerCase();
    final List<int> currentBlockMatches = _getCurrentBlockMatchStarts();

    final List<InlineSpan> spans = [];

    final double scaleFactor = MediaQuery.of(
      context,
    ).textScaler.textScaleFactor;
    final double dynamicFontSize = _baseFontSize * scaleFactor;

    final TextStyle defaultStyle = TextStyle(
      color: Colors.white,
      fontSize: dynamicFontSize,
    );

    final TextStyle highlightStyle = defaultStyle.copyWith(
      backgroundColor: Colors.yellow,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );
    final TextStyle currentHighlightStyle = defaultStyle.copyWith(
      backgroundColor: Colors.orange,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    String currentText = _currentBlockText;
    int currentMatchIndex = 0;

    // 全体検索結果のうち、現在のハイライトがこのブロック内の何番目のヒットか確認
    final currentMatchGlobal = _currentFoundIndex != -1
        ? _allFoundMatches[_currentFoundIndex]
        : null;

    for (final startIndex in currentBlockMatches) {
      final int endIndex = startIndex + query.length;

      if (startIndex > currentMatchIndex) {
        spans.add(
          TextSpan(text: currentText.substring(currentMatchIndex, startIndex)),
        );
      }

      // ハイライト対象かどうかをチェック
      final bool isCurrentHighlight =
          currentMatchGlobal != null &&
          currentMatchGlobal.blockIndex == _currentBlockIndex &&
          currentMatchGlobal.charIndexInBlock == startIndex;

      spans.add(
        TextSpan(
          text: currentText.substring(startIndex, endIndex),
          style: isCurrentHighlight ? currentHighlightStyle : highlightStyle,
        ),
      );

      currentMatchIndex = endIndex;
    }

    if (currentMatchIndex < currentText.length) {
      spans.add(TextSpan(text: currentText.substring(currentMatchIndex)));
    }

    if (spans.isEmpty && _currentBlockText.isNotEmpty) {
      spans.add(TextSpan(text: _currentBlockText));
    }

    return TextSpan(style: defaultStyle, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle fixedTextStyle = TextStyle(
      color: Colors.white,
      fontSize: _baseFontSize,
    );

    final int totalBlocks = _dataBlocks.length;

    int startLineIndexInAllLines = 0;
    for (int i = 0; i < _currentBlockIndex; i++) {
      startLineIndexInAllLines += (_linesPerBlock - _overlapLinesCount);
    }

    final int startLine = startLineIndexInAllLines + 1;
    final int endLine = startLine + _currentBlockText.split('\n').length - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: HENSUU.backgroundcolor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            '歩み (戦績) ${startLine}行目〜${endLine}行目',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // --- 検索ボックスとボタン ---
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: fixedTextStyle,
                        decoration: InputDecoration(
                          hintText: '全文検索...',
                          hintStyle: fixedTextStyle.copyWith(
                            color: Colors.white70,
                          ),
                          fillColor: Colors.white12,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              // 検索結果クリア
                              setState(() {
                                _allFoundMatches.clear();
                                _currentFoundIndex = -1;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (value) => _startFullSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 検索ボタン
                    IconButton(
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      onPressed: _isSearching ? null : _startFullSearch,
                      tooltip: '全文検索',
                    ),
                    // 上矢印ボタン
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: _allFoundMatches.isNotEmpty
                          ? () => _scrollNext(-1)
                          : null,
                      tooltip: '前の検索結果',
                    ),
                    // 下矢印ボタン
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                      onPressed: _allFoundMatches.isNotEmpty
                          ? () => _scrollNext(1)
                          : null,
                      tooltip: '次の検索結果',
                    ),
                    // 検索結果のカウント表示
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _allFoundMatches.isEmpty
                            ? ''
                            : '${_currentFoundIndex + 1}/${_allFoundMatches.length}',
                        style: fixedTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30, height: 1),

              // --- メイン表示エリア ---
              Expanded(
                child: Stack(
                  // Stackでローディング表示を重ねる
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(_paddingVertical),
                      child: Container(
                        key: _richTextKey,
                        child: SingleChildScrollView(
                          key: _scrollableKey,
                          controller: _scrollController,
                          child: RichText(text: _buildSearchableText(context)),
                        ),
                      ),
                    ),
                    // ローディングオーバーレイ
                    if (_isSearching)
                      Container(
                        color: HENSUU.backgroundcolor.withOpacity(
                          0.9,
                        ), // 背景色を少し暗く
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '検索中です...',
                                style: fixedTextStyle.copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30, height: 1),

              // --- 前/次の領域ボタン ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final String label = constraints.maxWidth < 100
                              ? '前'
                              : '前の領域';
                          return TextButton.icon(
                            onPressed: totalBlocks > 0
                                ? () => _updateCurrentBlock(
                                    _currentBlockIndex - 1,
                                  )
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: Text(label),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    // 中央のインデックス表示
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'ブロック ${_currentBlockIndex + 1} / $totalBlocks',
                        style: fixedTextStyle.copyWith(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final String label = constraints.maxWidth < 100
                              ? '次'
                              : '次の領域';
                          return TextButton.icon(
                            onPressed: totalBlocks > 0
                                ? () => _updateCurrentBlock(
                                    _currentBlockIndex + 1,
                                  )
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(label),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            iconAlignment: IconAlignment.end,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
