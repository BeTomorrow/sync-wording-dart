import '../wording.dart';

abstract class WordingExporter {
  Future<void> export(String locale, Map<String, WordingEntry> wordingEntries,
      String outputFile);
}
