class Analyte {
  /// The name of the analyte.
  final String name;

  /// The quantity of the analyte.
  final String quantity;

  /// The numerical value of the analyte.
  final String value;

  /// The uncertainty associated with the analyte's value.
  final String uncertainty;

  /// The unit of measurement for the analyte's quantity/value.
  final String unit;

  /// The type or category of the analyte.
  final String type;

  /// Creates an [Analyte] instance.
  ///
  /// All parameters are required and define the properties of the analyte.
  Analyte({
    required this.name,
    required this.quantity,
    required this.value,
    required this.uncertainty,
    required this.unit,
    required this.type,
  });
}