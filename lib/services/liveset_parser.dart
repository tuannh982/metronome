import 'package:petitparser/petitparser.dart';
import '../models/liveset.dart';
import '../models/time_signature.dart';

/// Parser error with line information
class ParseError {
  final int line;
  final String message;

  const ParseError(this.line, this.message);

  @override
  String toString() => 'Line $line: $message';
}

/// Result of parsing a liveset
class ParseResult {
  final Liveset? liveset;
  final List<ParseError> errors;

  const ParseResult({this.liveset, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => liveset != null && errors.isEmpty;
}

/// State machine states for parsing
enum _ParseState {
  initial,       // Start of file, expecting tempo or time
  afterTempo,    // After tempo line, expecting time 
  afterTime,     // After time line, expecting time or tempo or EOF
}

/// Parser for the liveset DSL using PetitParser and state machine
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
class LivesetParser {
  late final Parser<int> _tempoValueParser;
  late final Parser<_TimePart> _timeParser;

  LivesetParser() {
    _buildParser();
  }

  void _buildParser() {
    // Whitespace
    final ws = char(' ').or(char('\t')).star();

    // Numbers
    final number = digit().plus().flatten().map(int.parse);

    // Time signature: N/N
    final timeSignature = (number & char('/') & number).map((values) {
      return TimeSignature(
        numerator: values[0] as int,
        denominator: values[2] as int,
      );
    });

    // "tempo N" - just extracts the number (must consume entire line)
    _tempoValueParser = (string('tempo').trim() & number & ws.end()).map((values) {
      return values[1] as int;
    });

    // Optional comma separator
    final comma = (ws & char(',') & ws);

    // "N bars" or "N bar" part (optional)
    final barsPart = (number & ws & (string('bars') | string('bar'))).map((values) {
      return values[0] as int;
    });

    // "time N/N[, N bars]" line (must consume entire line)
    _timeParser = (string('time').trim() & timeSignature & (comma & barsPart).optional() & ws.end())
        .map((values) {
      final timeSig = values[1] as TimeSignature;
      int? bars;
      if (values[2] != null) {
        final barsList = values[2] as List;
        // barsList structure: [ws, ',', ws, N] where comma produces 3 elements
        // and barsPart (the number) is the 4th element (index 3)
        bars = barsList[3] as int;
      }
      return _TimePart(timeSignature: timeSig, bars: bars);
    });
  }

  /// Remove comments from input
  String _removeComments(String input) {
    // Remove multi-line comments
    var result = input.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Remove single-line comments
    final lines = result.split('\n');
    final cleanedLines = lines.map((line) {
      final commentIndex = line.indexOf('//');
      if (commentIndex >= 0) {
        return line.substring(0, commentIndex);
      }
      return line;
    }).toList();

    return cleanedLines.join('\n');
  }

  /// Parse DSL text into a Liveset using state machine
  ParseResult parse(String input) {
    final cleanedInput = _removeComments(input);
    final lines = cleanedInput.split('\n');
    final errors = <ParseError>[];
    final directives = <LivesetDirective>[];

    // State machine
    var state = _ParseState.initial;
    int currentTempo = 120; // Default tempo

    for (int i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      final parseResult = _parseLine(line, lineNum, state, currentTempo);
      
      if (parseResult.error != null) {
        errors.add(parseResult.error!);
        continue;
      }

      // Update state based on what we parsed
      if (parseResult.newTempo != null) {
        currentTempo = parseResult.newTempo!;
        state = _ParseState.afterTempo;
      }

      if (parseResult.directive != null) {
        directives.add(parseResult.directive!);
        state = _ParseState.afterTime;
      }
    }

    return ParseResult(
      liveset: Liveset(directives: directives),
      errors: errors,
    );
  }

  /// Parse a single line and return result
  _LineParseResult _parseLine(String line, int lineNum, _ParseState state, int currentTempo) {
    // Try tempo
    if (line.startsWith('tempo')) {
      final result = _tempoValueParser.parse(line);
      if (result is Success) {
        return _LineParseResult(newTempo: result.value);
      } else {
        return _LineParseResult(
          error: ParseError(lineNum, 'Invalid tempo syntax'),
        );
      }
    }

    // Try time
    if (line.startsWith('time')) {
      final result = _timeParser.parse(line);
      if (result is Success) {
        final timePart = result.value;
        return _LineParseResult(
          directive: LivesetDirective(
            timeSignature: timePart.timeSignature,
            tempo: currentTempo,
            bars: timePart.bars,
            lineNumber: lineNum,
          ),
        );
      } else {
        return _LineParseResult(
          error: ParseError(lineNum, 'Invalid time signature syntax'),
        );
      }
    }

    // Unknown line
    return _LineParseResult(
      error: ParseError(lineNum, 'Unknown directive: $line'),
    );
  }

  /// Validate DSL text and return errors
  List<ParseError> validate(String input) {
    return parse(input).errors;
  }
}

/// Helper class for time parsing result
class _TimePart {
  final TimeSignature timeSignature;
  final int? bars;

  _TimePart({required this.timeSignature, this.bars});
}

/// Result of parsing a single line
class _LineParseResult {
  final int? newTempo;
  final LivesetDirective? directive;
  final ParseError? error;

  _LineParseResult({this.newTempo, this.directive, this.error});
}
