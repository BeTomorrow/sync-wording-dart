import 'package:sync_wording/wording.dart';
import 'package:sync_wording/wording_processor/wording_processor_manager.dart';

/// A processor that checks for placeholder mismatches in the wordings
/// It will log a warning for each placeholder mismatch (name or type) between languages
class PlaceholderMismatchProcessor extends WordingProcessor {
  PlaceholderMismatchProcessor(super.logger);

  @override
  void process(Wordings wordings) {
    if (wordings.keys.length < 2) {
      return;
    }

    final allKeys = wordings.values.expand((e) => e.keys).toSet();

    for (final key in allKeys) {
      final Iterable<WordingEntry> wordingsEntries =
          wordings.values.map((lw) => lw[key]).whereType<WordingEntry>();

      final Iterable<Iterable<PlaceholderCharac>?> placeholderCharacs =
          wordingsEntries.map((w) => w.placeholderCharacs);

      _processWordingPlaceholders(key, placeholderCharacs);
    }
  }

  void _processWordingPlaceholders(
      String key, Iterable<Iterable<PlaceholderCharac>?> placeholderCharacs) {
    final placeholderCounts =
        placeholderCharacs.map((placeholders) => placeholders?.length ?? 0);

    if (placeholderCounts.any((count) => count != placeholderCounts.first)) {
      logger.log(
          "⚠️ Placeholder mismatch for '$key': placeholders count mismatch");
      return;
    }

    if (placeholderCounts.first > 0) {
      final firstLanguagePlaceholders = placeholderCharacs.first!;

      for (int i = 0; i < firstLanguagePlaceholders.length; i++) {
        final placeholderCharac = firstLanguagePlaceholders.elementAt(i);
        final placeholder = placeholderCharac.placeholder;
        final placeholderType = placeholderCharac.type;

        final otherLanguageCharacs = placeholderCharacs.skip(1);

        for (var languageCharac in otherLanguageCharacs) {
          final hasMatch = languageCharac?.any((c) =>
                  c.placeholder == placeholder &&
                  (c.type == placeholderType ||
                      (c.type == null && placeholderType == null))) ??
              false;
          if (!hasMatch) {
            logger.log(
                "⚠️ Placeholder mismatch for '$key': placeholder type mismatch");
            return;
          }
        }
      }
    }
  }
}
