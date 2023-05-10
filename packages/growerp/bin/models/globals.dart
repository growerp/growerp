import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

String growerpPath = '$HOME/growerpTest';

final logger = Logger(
    printer: PrettyPrinter(
        methodCount: 0, // number of method calls to be displayed
        lineLength: 80, // width of the output
        printEmojis: false, // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ),
    filter: MyFilter());

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
