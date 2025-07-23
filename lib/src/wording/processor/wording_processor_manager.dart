import 'package:sync_wording/src/config/wording_config.dart';
import 'package:sync_wording/src/logger/logger.dart';
import 'package:sync_wording/src/wording/processor/missing_wording_processor.dart';
import 'package:sync_wording/src/wording/processor/placeholder_mismatch_processor.dart';
import 'package:sync_wording/src/wording/wording.dart';

/// A processor that validates and processes wordings
abstract class WordingProcessor {
  final Logger logger;

  WordingProcessor(this.logger);

  void process(Wordings wordings);
}

/// Manages the processing and validation of wordings by running them through
/// a series of [WordingProcessor]s like checking for missing translations and placeholder mismatches
class WordingProcessorManager {
  final Wordings wordings;
  final FallbackConfig fallbackConfig;

  final List<WordingProcessor> processors;

  WordingProcessorManager(this.wordings, Logger logger, this.fallbackConfig)
      : processors = [
          MissingWordingProcessor(logger, fallbackConfig),
          PlaceholderMismatchProcessor(logger),
        ];

  void process() {
    for (final processor in processors) {
      processor.process(wordings);
    }
  }
}
