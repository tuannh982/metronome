import 'dart:convert';
import 'package:petitparser/petitparser.dart';
import '../models/track.dart';
import '../models/time_signature.dart';
import '../constants.dart';

/// Parser error with line information
class ParseError {
  final int line;
  final String message;

  const ParseError(this.line, this.message);

  @override
  String toString() => 'Line $line: $message';
}

/// Result of parsing a track
class ParseResult {
  final Track? track;
  final List<ParseError> errors;

  const ParseResult({this.track, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => track != null && errors.isEmpty;

  @override
  String toString() {
    if (isSuccess) {
      final jsonStr = const JsonEncoder.withIndent(
        '  ',
      ).convert(track?.toJson());
      return 'ParseResult: Success (${track?.directives.length ?? 0} directives)\n$jsonStr';
    } else {
      return 'ParseResult: Failure (${errors.length} errors)\n${errors.map((e) => '  - $e').join('\n')}';
    }
  }
}

/// Parser for the track DSL using PetitParser and state machine
///
/// DSL Syntax:
/// ```
/// // Comments start with //
/// /* Multi-line comments */
///
/// tempo 120           // Set track tempo (once at top or can change later)
///
/// time 4/4, 8 bars    // Time signature with bar count
/// time 3/4            // Time signature without bar count
///
/// tempo 140           // Can change tempo between time directives
/// time 7/8, 16 bars
/// ```
class TrackParser {
  late final Parser<List<dynamic>> _fullParser;

  TrackParser() {
    _buildParser();
  }

  void _buildParser() {
    // Basic parsers
    final ws = char(' ').or(char('\t')).star();
    final newline = char('\n').or(string('\r\n'));
    final number = digit().plus().flatten().map(int.parse);
    final float = (digit().plus() & (char('.') & digit().plus()).optional())
        .flatten()
        .map(double.parse);

    // Comments
    final singleLineComment =
        string('//') & any().starLazy(newline).flatten() & newline.optional();
    final multiLineComment =
        string('/*') & any().starLazy(string('*/')).flatten() & string('*/');
    final comment = singleLineComment | multiLineComment;

    // Ignored whitespace and comments
    final ignored = (whitespace() | comment).star();

    // Keywords
    final tempoKw = string('tempo');
    final timeKw = string('time');
    final delayKw = string('delay');
    final barKw = string('bars') | string('bar');

    // Time signature: N/N
    final timeSignature = (number & char('/') & number).map((values) {
      return TimeSignature(
        numerator: values[0] as int,
        denominator: values[2] as int,
      );
    });

    // "tempo N"
    final tempoParser = (tempoKw & ws & number).token().map((token) {
      final values = token.value;
      return _TempoChange(values[2] as int, token.line);
    });

    // "N bars" or "N bar" part (optional)
    final barsPart = (number & ws & barKw).map((values) {
      return values[0] as int;
    });

    // "time N/N[, N bars]"
    final timeParser =
        (timeKw &
                ws &
                timeSignature &
                (ws & char(',') & ws & barsPart).optional())
            .token()
            .map((token) {
              final values = token.value;
              final timeSig = values[2] as TimeSignature;
              int bars = 1;
              if (values[3] != null) {
                final barsList = values[3] as List;
                bars = barsList[3] as int;
              }
              return _TimePart(
                timeSignature: timeSig,
                bars: bars,
                line: token.line,
              );
            });

    // "delay N"
    final delayParser = (delayKw & ws & float).token().map((token) {
      final values = token.value;
      return _DelayPart(seconds: values[2] as double, line: token.line);
    });

    // Combine all parsers
    final itemParser = tempoParser | timeParser | delayParser;

    // The full parser consumes all items separated by ignored whitespace
    _fullParser = (ignored & itemParser).star() & ignored & endOfInput();
  }

  /// Parse DSL text into a Track
  ParseResult parse(String input) {
    final result = _fullParser.parse(input);

    if (result is Failure) {
      final lineAndColumn = Token.lineAndColumnOf(
        result.buffer,
        result.position,
      );
      return ParseResult(
        errors: [ParseError(lineAndColumn[0], result.message)],
      );
    }

    final List<dynamic> rawItems = result.value[0] as List<dynamic>;
    final parsedItems = rawItems.map((e) => e[1]).toList();
    final errors = <ParseError>[];
    final directives = <TrackDirective>[];
    int currentTempo = 120; // Default tempo

    for (final item in parsedItems) {
      if (item is _TempoChange) {
        if (item.tempo < AppConstants.minBpm ||
            item.tempo > AppConstants.maxBpm) {
          errors.add(
            ParseError(
              item.line,
              'Tempo must be between ${AppConstants.minBpm} and ${AppConstants.maxBpm}',
            ),
          );
        } else {
          currentTempo = item.tempo;
        }
      } else if (item is _TimePart) {
        final ts = item.timeSignature;
        if (ts.numerator <= 0 || ts.denominator <= 0) {
          errors.add(
            ParseError(
              item.line,
              'Time signature numerator and denominator must be positive',
            ),
          );
          continue;
        }
        if ((ts.denominator & (ts.denominator - 1)) != 0) {
          errors.add(ParseError(item.line, 'Denominator must be a power of 2'));
          continue;
        }
        if (item.bars != null && item.bars! <= 0) {
          errors.add(ParseError(item.line, 'Bar count must be positive'));
          continue;
        }

        directives.add(
          TimeDirective(
            timeSignature: ts,
            tempo: currentTempo,
            bars: item.bars,
            lineNumber: item.line,
          ),
        );
      } else if (item is _DelayPart) {
        if (item.seconds < 0) {
          errors.add(ParseError(item.line, 'Delay cannot be negative'));
          continue;
        }
        directives.add(
          DelayDirective(seconds: item.seconds, lineNumber: item.line),
        );
      }
    }

    return ParseResult(
      track: errors.isEmpty ? Track(directives: directives) : null,
      errors: errors,
    );
  }

  /// Validate DSL text and return errors
  List<ParseError> validate(String input) {
    return parse(input).errors;
  }
}

/// Helper class for internal tempo change
class _TempoChange {
  final int tempo;
  final int line;
  _TempoChange(this.tempo, this.line);
}

/// Helper class for time parsing result
class _TimePart {
  final TimeSignature timeSignature;
  final int? bars;
  final int line;

  _TimePart({required this.timeSignature, this.bars, required this.line});
}

/// Helper class for delay parsing result
class _DelayPart {
  final double seconds;
  final int line;

  _DelayPart({required this.seconds, required this.line});
}
