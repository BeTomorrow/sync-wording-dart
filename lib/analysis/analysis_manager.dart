import 'package:sync_wording/analysis/missing_wording_analyzer.dart';
import 'package:sync_wording/analysis/placeholder_mismatch_analyzer.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/wording.dart';

abstract class Analyzer {
  final Logger logger;

  Analyzer(this.logger);

  void analyze(Wordings wordings);
}

class AnalysisManager {
  final Wordings wordings;

  final List<Analyzer> analyzers;

  AnalysisManager(this.wordings, Logger logger)
      : analyzers = [
          MissingWordingAnalyzer(logger),
          PlaceholderMismatchAnalyzer(logger),
        ];

  void analyze() {
    for (final analyzer in analyzers) {
      analyzer.analyze(wordings);
    }
  }
}
