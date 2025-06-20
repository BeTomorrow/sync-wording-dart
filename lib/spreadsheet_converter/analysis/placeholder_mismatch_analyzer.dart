import 'package:sync_wording/analysis/analysis_manager.dart';
import 'package:sync_wording/wording.dart';

class PlaceholderMismatchAnalyzer extends Analyzer {
  PlaceholderMismatchAnalyzer(super.logger);

  @override
  void analyze(Wordings wordings) {
    if (wordings.keys.length < 2) {
      return;
    }

    final allKeys = wordings.values.expand((e) => e.keys).toSet();

    for (final key in allKeys) {
      final Iterable<WordingEntry> wordingsEntries =
          wordings.values.map((lw) => lw[key]).nonNulls;

      final Iterable<Iterable<PlaceholderCharac>?> placeholderCharacs =
          wordingsEntries.map((w) => w.placeholderCharacs);

      _analyzeWordingPlaceholders(key, placeholderCharacs);
    }
  }

  void _analyzeWordingPlaceholders(
      String key, Iterable<Iterable<PlaceholderCharac>?> placeholderCharacs) {
    final placeholderCounts =
        placeholderCharacs.map((placeholders) => placeholders?.length ?? 0);

    if (placeholderCounts.any((count) => count != placeholderCounts.first)) {
      print("⚠️ Placeholder mismatch for $key");
      return;
    }

    final firstLanguagePlaceholders = placeholderCharacs.first!;
    for (int i = 0; i < firstLanguagePlaceholders.length; i++) {
      final placeholderCharac = firstLanguagePlaceholders.elementAt(i);
      final placeholder = placeholderCharac.placeholder;
      final placeholderType = placeholderCharac.type;

      final otherLanguageCharacs = placeholderCharacs.skip(1);
      if (otherLanguageCharacs.any((languageCharacs) =>
          languageCharacs?.any((p) =>
              p.placeholder == placeholder && p.type == placeholderType) ??
          false)) {
        print("⚠️ Placeholder mismatch for $key");
        return;
      }
    }
  }
}
