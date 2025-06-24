import 'package:sync_wording/config/wording_config.dart';
import 'package:sync_wording/logger/logger.dart';
import 'package:sync_wording/wording.dart';
import 'package:sync_wording/wording_processor/missing_wording_processor.dart';
import 'package:sync_wording/wording_processor/placeholder_mismatch_processor.dart';

abstract class WordingProcessor {
  final Logger logger;

  WordingProcessor(this.logger);

  void process(Wordings wordings);
}

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
