import '../wording.dart';

/// Generic class used to create a file that will contain the translations
abstract class WordingExporter {
  /// Generic method to call to create the translation file used by the project
  Future<void> export(String locale, Map<String, WordingEntry> wordingEntries,
      String outputFile);
}
