import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

/// Program mode of an agent as the backend returns it.
void main() {
  test('an agent in program mode keeps its run mode and program', () {
    final cfg = AdkAgentConfig.fromJson({
      'adkAgentConfigId': '100100',
      'agentName': 'Morning report',
      'runMode': 'program',
      'programText': '<actions><set field="report" value="hi"/></actions>',
    });
    expect(cfg.runMode, 'program');
    expect(cfg.programText, startsWith('<actions>'));
    expect(cfg.copyWith(agentName: 'Renamed').programText, cfg.programText);
    expect(AdkAgentConfig.fromJson(cfg.toJson()).runMode, 'program');
  });

  test('an agent saved before program mode has no run mode', () {
    final cfg = AdkAgentConfig.fromJson({'adkAgentConfigId': '1'});
    expect(cfg.runMode, isNull);
    expect(cfg.programText, isNull);
  });

  test('a generated program parses with its problems', () {
    final program = AdkAgentProgram.fromJson({
      'programText': '<actions/>',
      'issues': [
        {
          'level': 'error',
          'field': 'programText',
          'message': 'The program calls no service.',
        },
      ],
    });
    expect(program.programText, '<actions/>');
    expect(program.issues.single.message, 'The program calls no service.');
    expect(AdkAgentProgram.fromJson({}).issues, isEmpty);
  });
}
