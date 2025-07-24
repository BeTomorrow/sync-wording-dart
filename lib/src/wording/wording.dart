/// Class defining a placeholder specificity
class PlaceholderCharac {
  final String placeholder;
  final String? type;
  final String? format;

  PlaceholderCharac(this.placeholder, this.type, this.format);
}

/// Class defining a translation value, with its placeholder specificities
class WordingEntry {
  final String value;
  final List<PlaceholderCharac>? placeholderCharacs;

  WordingEntry(this.value, this.placeholderCharacs);
}

typedef LanguageWordings = Map<String, WordingEntry>;
typedef Wordings = Map<String, LanguageWordings>;

extension WordingsExtension on Wordings {
  List<String> get keys => keys.toList();

  String value(String key, String locale) => this[locale]![key]!.value;
}
