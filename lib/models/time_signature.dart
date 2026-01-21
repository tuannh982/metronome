/// Represents a musical time signature (e.g., 4/4, 3/4, 6/8)
class TimeSignature {
  /// Number of beats per measure
  final int numerator;

  /// Note value that represents one beat (4 = quarter note, 8 = eighth note)
  final int denominator;

  const TimeSignature({
    required this.numerator,
    required this.denominator,
  });

  /// Common time signatures
  static const TimeSignature common = TimeSignature(numerator: 4, denominator: 4);
  static const TimeSignature waltz = TimeSignature(numerator: 3, denominator: 4);
  static const TimeSignature sixEight = TimeSignature(numerator: 6, denominator: 8);
  static const TimeSignature fiveFour = TimeSignature(numerator: 5, denominator: 4);
  static const TimeSignature sevenEight = TimeSignature(numerator: 7, denominator: 8);
  static const TimeSignature twoFour = TimeSignature(numerator: 2, denominator: 4);

  /// List of common presets
  static const List<TimeSignature> presets = [
    common,
    waltz,
    twoFour,
    fiveFour,
    sixEight,
    sevenEight,
  ];

  /// Display string (e.g., "4/4")
  String get display => '$numerator/$denominator';

  /// Calculate the duration multiplier relative to a quarter note
  /// For 4/4: 1.0, for 6/8: 0.5 (eighth note is the beat)
  double get beatDurationMultiplier => 4.0 / denominator;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSignature &&
        other.numerator == numerator &&
        other.denominator == denominator;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => 'TimeSignature($display)';

  /// Parse from string like "4/4" or "6/8"
  static TimeSignature? parse(String input) {
    final parts = input.trim().split('/');
    if (parts.length != 2) return null;
    final num = int.tryParse(parts[0]);
    final den = int.tryParse(parts[1]);
    if (num == null || den == null || num <= 0 || den <= 0) return null;
    // Denominator must be a power of 2
    if ((den & (den - 1)) != 0) return null;
    return TimeSignature(numerator: num, denominator: den);
  }
}
