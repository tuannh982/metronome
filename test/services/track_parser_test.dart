import 'package:flutter_test/flutter_test.dart';
import 'package:metronome/services/track_parser.dart';
import 'package:metronome/models/track.dart';

void main() {
  group('TrackParser', () {
    late TrackParser parser;

    setUp(() {
      parser = TrackParser();
    });

    test('parses basic directives correctly', () {
      const input = '''
tempo 120
time 4/4, 4 bars
delay 1.5
''';
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.track!.directives.length, 2);

      final time = result.track!.directives[0] as TimeDirective;
      expect(time.tempo, 120);
      expect(time.timeSignature.numerator, 4);
      expect(time.timeSignature.denominator, 4);
      expect(time.bars, 4);

      final delay = result.track!.directives[1] as DelayDirective;
      expect(delay.seconds, 1.5);
    });

    test('ignores single-line and multi-line comments', () {
      const input = '''
// Start with a comment
tempo 140
/* Multi-line
   comment block */
time 3/4
''';
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.track!.directives.length, 1);

      final time = result.track!.directives[0] as TimeDirective;
      expect(time.timeSignature.numerator, 3);
      expect(time.lineNumber, 5);
    });

    test('tempo changes persist across time directives', () {
      const input = '''
tempo 180
time 4/4
time 2/4
tempo 100
time 3/4
''';
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      final directives = result.track!.directives
          .whereType<TimeDirective>()
          .toList();

      expect(directives[0].tempo, 180);
      expect(directives[1].tempo, 180);
      expect(directives[2].tempo, 100);
    });

    group('Validation', () {
      test('reports error for invalid tempo', () {
        final result = parser.parse('tempo 10\ntempo 600');
        expect(result.hasErrors, isTrue);
        expect(result.errors.length, 2);
        expect(result.errors[0].message, contains('Tempo must be between'));
        expect(result.errors[0].line, 1);
        expect(result.errors[1].line, 2);
      });

      test('reports error for invalid time signature denominator', () {
        final result = parser.parse('time 4/5');
        expect(result.hasErrors, isTrue);
        expect(result.errors[0].message, contains('power of 2'));
      });

      test('reports error for negative values', () {
        expect(parser.parse('time 4/4, -1 bars').hasErrors, isTrue);
        expect(parser.parse('delay -1').hasErrors, isTrue);
      });

      test('reports error for unknown directives', () {
        final result = parser.parse('invalid 123');
        expect(result.hasErrors, isTrue);
        expect(result.errors[0].message, contains('end of input expected'));
      });
    });
  });
}
