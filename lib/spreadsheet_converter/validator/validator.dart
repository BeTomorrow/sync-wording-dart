import 'package:sync_wording/config/wording_config.dart';

sealed class Validator {
  static final _alwaysTrueValidator = _AlwaysTrueValidator();
  static final List<_CheckValueValidator> _checkValueValidators = [];

  bool isValid(List<String> row);

  Validator._();

  factory Validator.get(ValidationConfig config) {
    final column = config.column;
    final expected = config.expected;
    if (column == null || expected == null) {
      return _alwaysTrueValidator;
    }

    return _checkValueValidators.firstWhere(
      (v) => v._column == column && v._expected == expected,
      orElse: () {
        final validator = _CheckValueValidator(column, expected);
        _checkValueValidators.add(validator);
        return validator;
      },
    );
  }
}

class _AlwaysTrueValidator implements Validator {
  @override
  bool isValid(List<String> row) => true;
}

class _CheckValueValidator implements Validator {
  final int _column;
  final String _expected;

  _CheckValueValidator(this._column, this._expected);

  @override
  bool isValid(List<String> row) {
    if (row.length >= _column) {
      return row[_column - 1] == _expected;
    }
    return false;
  }
}
