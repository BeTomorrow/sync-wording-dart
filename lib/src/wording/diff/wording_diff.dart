import 'package:sync_wording/src/wording/wording.dart';

enum WordingDiffType {
  missing,
  added,
  modified,
}

class WordingDiff {
  final Wordings oldWordings;
  final Wordings newWordings;

  WordingDiff(this.oldWordings, this.newWordings);

  (
    Set<String> addedKeys,
    Set<String> modifiedKeys,
    Set<String> removedKeys,
  ) getDifferences() {
    final allKeys = <String>{};

    for (final locale in oldWordings.keys) {
      allKeys.addAll(oldWordings[locale]!.keys);
    }
    for (final locale in newWordings.keys) {
      allKeys.addAll(newWordings[locale]!.keys);
    }

    final addedKeys = <String>{};
    final modifiedKeys = <String>{};
    final removedKeys = <String>{};

    for (final key in allKeys) {
      final isInOld = _isKeyInWordings(key, oldWordings);
      final isInNew = _isKeyInWordings(key, newWordings);

      if (!isInOld && isInNew) {
        addedKeys.add(key);
      } else if (isInOld && !isInNew) {
        removedKeys.add(key);
      } else if (isInOld && isInNew) {
        if (_isKeyModified(key, oldWordings, newWordings)) {
          modifiedKeys.add(key);
        }
      }
    }

    return (addedKeys, modifiedKeys, removedKeys);
  }

  bool _isKeyInWordings(String key, Wordings wordings) {
    for (final locale in wordings.keys) {
      if (wordings[locale]!.containsKey(key)) {
        return true;
      }
    }
    return false;
  }

  bool _isKeyModified(String key, Wordings oldWordings, Wordings newWordings) {
    for (final locale in oldWordings.keys) {
      if (!newWordings.containsKey(locale)) continue;

      final oldEntry = oldWordings[locale]![key];
      final newEntry = newWordings[locale]![key];

      if (oldEntry != null && newEntry != null) {
        if (oldEntry.value != newEntry.value) {
          return true;
        }

        if (!_arePlaceholdersEqual(
            oldEntry.placeholderCharacs, newEntry.placeholderCharacs)) {
          return true;
        }
      } else if (oldEntry != null || newEntry != null) {
        return true;
      }
    }

    for (final locale in newWordings.keys) {
      if (!oldWordings.containsKey(locale)) continue;

      final oldEntry = oldWordings[locale]![key];
      final newEntry = newWordings[locale]![key];

      if (oldEntry != null && newEntry != null) {
        if (oldEntry.value != newEntry.value) {
          return true;
        }

        if (!_arePlaceholdersEqual(
            oldEntry.placeholderCharacs, newEntry.placeholderCharacs)) {
          return true;
        }
      } else if (oldEntry != null || newEntry != null) {
        return true;
      }
    }

    return false;
  }

  bool _arePlaceholdersEqual(List<PlaceholderCharac>? oldPlaceholders,
      List<PlaceholderCharac>? newPlaceholders) {
    if (oldPlaceholders == null && newPlaceholders == null) return true;
    if (oldPlaceholders == null || newPlaceholders == null) return false;
    if (oldPlaceholders.length != newPlaceholders.length) return false;

    for (int i = 0; i < oldPlaceholders.length; i++) {
      final oldCharac = oldPlaceholders[i];
      final newCharac = newPlaceholders[i];

      if (oldCharac.placeholder != newCharac.placeholder ||
          oldCharac.type != newCharac.type ||
          oldCharac.format != newCharac.format) {
        return false;
      }
    }

    return true;
  }
}
