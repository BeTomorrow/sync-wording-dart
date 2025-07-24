import 'package:sync_wording/src/logger/logger.dart';

class MockLogger implements Logger {
  final List<String> messages = [];

  @override
  void log(String message, {LogColor color = LogColor.none}) {
    messages.add(message);
  }
}
