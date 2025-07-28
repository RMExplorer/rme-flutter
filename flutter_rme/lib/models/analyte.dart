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

  /// The name of the CRM this analyte came from.
  final String? crmName; // New field for CRM name

  /// The material type of the CRM this analyte came from.
  final String? materialType; // New field for material type

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
    this.crmName, // Initialize the new field
    this.materialType, // Initialize the new field
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Analyte &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          value == other.value &&
          uncertainty == other.uncertainty &&
          unit == other.unit &&
          type == other.type &&
          crmName == other.crmName && // Include crmName in equality check
          materialType == other.materialType; // Include materialType in equality check

  @override
  int get hashCode =>
      name.hashCode ^
      quantity.hashCode ^
      value.hashCode ^
      uncertainty.hashCode ^
      unit.hashCode ^
      type.hashCode ^
      crmName.hashCode ^ // Include crmName in hash code
      materialType.hashCode; // Include materialType in hash code
}