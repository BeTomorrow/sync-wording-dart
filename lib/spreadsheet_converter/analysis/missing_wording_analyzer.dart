import 'package:sync_wording/analysis/analysis_manager.dart';
import 'package:sync_wording/wording.dart';

class MissingWordingAnalyzer extends Analyzer {
  MissingWordingAnalyzer(super.logger);

  @override
  void analyze(Wordings wordings) {
    for (final language in wordings.keys) {
      for (final key in wordings[language]!.keys) {
        final wordingEntry = wordings[language]![key];
        if (wordingEntry == null || wordingEntry.value.isEmpty) {
          print("⚠️ Missing wording for $key in $language");
        }
      }
    }
  }
}
