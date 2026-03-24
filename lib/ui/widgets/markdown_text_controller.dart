import 'package:flutter/material.dart';

/// A custom TextEditingController that provides live syntax highlighting
/// for plain-text markdown-like formatting without altering the underlying text.
class MarkdownTextController extends TextEditingController {
  double baseFontSize;
  Color textColor;
  Color highlightColor;
  Color mutedColor;
  String? searchQuery;

  MarkdownTextController({
    super.text,
    required this.baseFontSize,
    required this.textColor,
    required this.highlightColor,
    required this.mutedColor,
    this.searchQuery,
  });

  // Regex for parsing line-by-line formatting
  static final RegExp _heading1 = RegExp(r'^#\s+(.*)$');
  static final RegExp _heading2 = RegExp(r'^##\s+(.*)$');
  static final RegExp _heading3 = RegExp(r'^###\s+(.*)$');
  static final RegExp _checkboxUnchecked = RegExp(r'^- \[ \]\s+(.*)$');
  static final RegExp _checkboxChecked = RegExp(r'^- \[x\]\s+(.*)$');
  static final RegExp _boldPattern = RegExp(r'\*\*(.*?)\*\*');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_heading1.hasMatch(line)) {
        // H1
        _parseInlineFormatting(line, style?.copyWith(
          fontSize: baseFontSize * 1.6,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.4,
        ), spans);
      } else if (_heading2.hasMatch(line)) {
        // H2
        _parseInlineFormatting(line, style?.copyWith(
          fontSize: baseFontSize * 1.35,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.4,
        ), spans);
      } else if (_heading3.hasMatch(line)) {
        // H3
        _parseInlineFormatting(line, style?.copyWith(
          fontSize: baseFontSize * 1.15,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.4,
        ), spans);
      } else if (_checkboxUnchecked.hasMatch(line)) {
        // Unchecked Box
        _parseInlineFormatting(
          line,
          style?.copyWith(color: textColor),
          spans,
          isCheckbox: true,
          isChecked: false,
        );
      } else if (_checkboxChecked.hasMatch(line)) {
        // Checked Box
        _parseInlineFormatting(
          line,
          style?.copyWith(
            color: mutedColor,
            decoration: TextDecoration.lineThrough,
          ),
          spans,
          isCheckbox: true,
          isChecked: true,
        );
      } else {
        // Normal paragraph (may contain bold)
        _parseInlineFormatting(line, style, spans);
      }

      // Add newline except for the last line
      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: style));
      }
    }

    return TextSpan(style: style, children: spans);
  }

  /// Parses inline formatting like **bold** alongside any line-level styles.
  void _parseInlineFormatting(
    String line,
    TextStyle? defaultStyle,
    List<TextSpan> spans, {
    bool isCheckbox = false,
    bool isChecked = false,
  }) {
    // If it's a checkbox, style the prefix slightly differently
    if (isCheckbox) {
      final prefixEnd = isChecked ? 6 : 6; // '- [ ] ' or '- [x] '
      if (line.length >= prefixEnd) {
        final prefix = line.substring(0, prefixEnd);
        _addTextSpanWithSearchHighlight(prefix, defaultStyle?.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none, // Never strike out the prefix box
        ), spans);
        line = line.substring(prefixEnd);
      }
    }

    if (line.isEmpty) return;

    // Find bold matches
    final matches = _boldPattern.allMatches(line);
    if (matches.isEmpty) {
      _addTextSpanWithSearchHighlight(line, defaultStyle, spans);
      return;
    }

    int cursor = 0;
    for (final match in matches) {
      // Add text before the bold segment
      if (match.start > cursor) {
        _addTextSpanWithSearchHighlight(
          line.substring(cursor, match.start),
          defaultStyle,
          spans
        );
      }

      // Add the bold segment (including the ** markers)
      _addTextSpanWithSearchHighlight(
        match.group(0)!,
        defaultStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: isChecked ? mutedColor : textColor,
        ),
        spans
      );

      cursor = match.end;
    }

    // Add remaining text
    if (cursor < line.length) {
      _addTextSpanWithSearchHighlight(
        line.substring(cursor),
        defaultStyle,
        spans
      );
    }
  }

  /// Highlights search query if present, otherwise adds normal span
  void _addTextSpanWithSearchHighlight(String text, TextStyle? style, List<TextSpan> spans) {
    final query = searchQuery;
    if (query == null || query.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch), style: style));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: style?.copyWith(
          backgroundColor: Colors.orange.withOpacity(0.5),
          color: Colors.white,
        ) ?? TextStyle(
          backgroundColor: Colors.orange.withOpacity(0.5),
          color: Colors.white,
        ),
      ));

      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
  }
}
