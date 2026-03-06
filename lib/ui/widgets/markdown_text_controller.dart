import 'package:flutter/material.dart';

/// A custom TextEditingController that provides live syntax highlighting
/// for plain-text markdown-like formatting without altering the underlying text.
class MarkdownTextController extends TextEditingController {
  double baseFontSize;
  Color textColor;
  Color highlightColor;
  Color mutedColor;

  MarkdownTextController({
    super.text,
    required this.baseFontSize,
    required this.textColor,
    required this.highlightColor,
    required this.mutedColor,
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
        spans.add(TextSpan(
          text: line,
          style: style?.copyWith(
            fontSize: baseFontSize * 1.6,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.4,
          ),
        ));
      } else if (_heading2.hasMatch(line)) {
        // H2
        spans.add(TextSpan(
          text: line,
          style: style?.copyWith(
            fontSize: baseFontSize * 1.35,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.4,
          ),
        ));
      } else if (_heading3.hasMatch(line)) {
        // H3
        spans.add(TextSpan(
          text: line,
          style: style?.copyWith(
            fontSize: baseFontSize * 1.15,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.4,
          ),
        ));
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
        spans.add(TextSpan(
          text: prefix,
          style: defaultStyle?.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none, // Never strike out the prefix box
          ),
        ));
        line = line.substring(prefixEnd);
      }
    }

    if (line.isEmpty) return;

    // Find bold matches
    final matches = _boldPattern.allMatches(line);
    if (matches.isEmpty) {
      spans.add(TextSpan(text: line, style: defaultStyle));
      return;
    }

    int cursor = 0;
    for (final match in matches) {
      // Add text before the bold segment
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: line.substring(cursor, match.start),
          style: defaultStyle,
        ));
      }

      // Add the bold segment (including the ** markers)
      spans.add(TextSpan(
        text: match.group(0),
        style: defaultStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: isChecked ? mutedColor : textColor,
        ),
      ));

      cursor = match.end;
    }

    // Add remaining text
    if (cursor < line.length) {
      spans.add(TextSpan(
        text: line.substring(cursor),
        style: defaultStyle,
      ));
    }
  }
}
