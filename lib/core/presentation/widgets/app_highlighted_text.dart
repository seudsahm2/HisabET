import 'package:flutter/material.dart';

/// Text with the part that matches [query] emphasised — the way a good search
/// shows *why* a row matched. Case-insensitive; highlights every occurrence.
class AppHighlightedText extends StatelessWidget {
  const AppHighlightedText(
    this.text, {
    super.key,
    required this.query,
    required this.style,
    this.highlightStyle,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle style;
  final TextStyle? highlightStyle;
  final int maxLines;

  /// Splits [text] into (segment, isMatch) runs. Exposed for tests.
  static List<(String, bool)> segments(String text, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [(text, false)];
    final lower = text.toLowerCase();
    final runs = <(String, bool)>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) break;
      if (index > start) runs.add((text.substring(start, index), false));
      runs.add((text.substring(index, index + q.length), true));
      start = index + q.length;
    }
    if (start < text.length) runs.add((text.substring(start), false));
    return runs.isEmpty ? [(text, false)] : runs;
  }

  @override
  Widget build(BuildContext context) {
    final emphasis = highlightStyle ??
        style.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        );
    return Text.rich(
      TextSpan(
        children: [
          for (final (segment, isMatch) in segments(text, query))
            TextSpan(text: segment, style: isMatch ? emphasis : style),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
