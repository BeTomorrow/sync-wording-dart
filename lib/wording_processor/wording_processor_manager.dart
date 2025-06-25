import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/wording.dart';
import 'package:sync_wording/wording_processor/missing_wording_processor.dart';
import 'package:sync_wording/wording_processor/placeholder_mismatch_processor.dart';

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
