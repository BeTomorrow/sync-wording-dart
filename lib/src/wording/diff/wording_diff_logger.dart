import 'package:sync_wording/src/logger/logger.dart';

class WordingDiffLogger {
  final Logger logger;

  WordingDiffLogger(this.logger);

  void log(
    Set<String> addedKeys,
    Set<String> modifiedKeys,
    Set<String> removedKeys,
  ) {
    for (final key in addedKeys) {
      logger.log('[ADDED]  $key', color: LogColor.green);
    }

    for (final key in modifiedKeys) {
      logger.log('[CHANGED]  $key', color: LogColor.orange);
    }

    for (final key in removedKeys) {
      logger.log('[REMOVED]  $key', color: LogColor.red);
    }

    if (addedKeys.isEmpty && modifiedKeys.isEmpty && removedKeys.isEmpty) {
      logger.log('==== No changes detected ====', color: LogColor.blue);
    }
  }
}
