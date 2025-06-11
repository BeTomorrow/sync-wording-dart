import 'dart:io';

import 'package:sync_wording/wording.dart';

const _placeholderRegex = r'\{([a-zA-Z]+)([|]{1}[a-zA-Z]+([|]{1}[^}]+){0,1}){1}\}';
const _separator = "|";

/// Main parser class that coordinates the parsing process
class WordingParser {
  final PlaceholderExtractor _placeholderExtractor;
  final PlaceholderFormatter _placeholderFormatter;

  WordingParser({
    PlaceholderExtractor? placeholderExtractor,
    PlaceholderFormatter? placeholderFormatter,
  })  : _placeholderExtractor = placeholderExtractor ?? PlaceholderExtractor(),
        _placeholderFormatter = placeholderFormatter ?? PlaceholderFormatter();

  WordingEntry parse(String rawText) {
    try {
      final placeholders = _placeholderExtractor.extractPlaceholders(rawText);
      if (placeholders.isEmpty) {
        return WordingEntry(rawText, null);
      }

      final formattedText = _placeholderFormatter.formatText(rawText, placeholders);
      final characteristics = _placeholderFormatter.createCharacteristics(placeholders);

      return WordingEntry(formattedText, characteristics);
    } catch (e) {
      stdout.writeln("Error parsing placeholders from '$rawText' -> Skip");
      return WordingEntry(rawText, null);
    }
  }
}

/// Class responsible for extracting placeholders from text
class PlaceholderExtractor {
  List<PlaceholderMatch> extractPlaceholders(String text) {
    final matches = RegExp(_placeholderRegex).allMatches(text).toList();
    return matches.map((match) {
      final matchedStr = text.substring(match.start, match.end);
      final content = matchedStr.substring(1, matchedStr.length - 1);
      return PlaceholderMatch(match.start, match.end, content);
    }).toList();
  }
}

/// Class responsible for formatting text and creating placeholder characteristics
class PlaceholderFormatter {
  String formatText(String originalText, List<PlaceholderMatch> placeholders) {
    var formattedText = originalText;
    for (var i = placeholders.length - 1; i >= 0; i--) {
      final placeholder = placeholders[i];
      final name = _extractPlaceholderName(placeholder.content);
      formattedText = formattedText.replaceRange(
        placeholder.start,
        placeholder.end,
        "{$name}",
      );
    }
    return formattedText;
  }

  List<PlaceholderCharac>? createCharacteristics(List<PlaceholderMatch> placeholders) {
    if (placeholders.isEmpty) return null;

    final characteristics = <PlaceholderCharac>[];
    for (final placeholder in placeholders) {
      final name = _extractPlaceholderName(placeholder.content);
      final typeAndFormat = _extractTypeAndFormat(placeholder.content);

      if (typeAndFormat != null) {
        characteristics.add(PlaceholderCharac(
          name,
          typeAndFormat.type,
          typeAndFormat.format,
        ));
      }
    }
    return characteristics;
  }

  String _extractPlaceholderName(String content) {
    final pipeIndex = content.indexOf(_separator);
    return pipeIndex == -1 ? content : content.substring(0, pipeIndex);
  }

  TypeAndFormat? _extractTypeAndFormat(String content) {
    final pipeIndex = content.indexOf(_separator);
    if (pipeIndex == -1) return null;

    final typeAndFormat = content.substring(pipeIndex + 1);
    final secondPipeIndex = typeAndFormat.indexOf(_separator);

    if (secondPipeIndex == -1) {
      return TypeAndFormat(typeAndFormat, null);
    }

    final type = typeAndFormat.substring(0, secondPipeIndex);
    final format = typeAndFormat.substring(secondPipeIndex + 1);

    if (type.isEmpty || format.isEmpty) {
      return null;
    }

    return TypeAndFormat(type, format);
  }
}

/// Class representing a placeholder match in the text
class PlaceholderMatch {
  final int start;
  final int end;
  final String content;

  PlaceholderMatch(this.start, this.end, this.content);
}

/// Class representing type and format information for a placeholder
class TypeAndFormat {
  final String type;
  final String? format;

  TypeAndFormat(this.type, this.format);
}
