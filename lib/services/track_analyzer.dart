import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'track_parser.dart';

class TrackAnalyzer extends AbstractAnalyzer {
  final TrackParser _parser = TrackParser();

  @override
  Future<AnalysisResult> analyze(Code code) async {
    final result = _parser.parse(code.text);
    final issues = result.errors.map((error) {
      return Issue(
        line: error.line - 1,
        message: error.message,
        type: IssueType.error,
      );
    }).toList();

    return AnalysisResult(issues: issues);
  }
}
