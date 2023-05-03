import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

String growerpPath = '$HOME/growerpTest';

final logger = Logger(
    printer: PrettyPrinter(
        methodCount: 0, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 80, // width of the output
        colors: true, // Colorful log messages
        printEmojis: false, // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ),
    filter: MyFilter());

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
