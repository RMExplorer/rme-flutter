class SpectrumPoint {
  /// The mass-to-charge ratio (m/z) of the ion. This is the x-axis value in a mass spectrum.
  final double massToCharge;

  /// The relative intensity of the ion signal. This is the y-axis value in a mass spectrum.
  final double relativeIntensity;

  /// Creates a [SpectrumPoint] instance.
  ///
  /// Both [massToCharge] and [relativeIntensity] are required.
  SpectrumPoint({
    required this.massToCharge,
    required this.relativeIntensity,
  });

  /// Factory constructor to create a [SpectrumPoint] instance from a row of CSV data.
  ///
  /// It expects a list of dynamic values where the first element is the
  /// mass-to-charge ratio and the second is the relative intensity.
  /// It parses these values to doubles.
  factory SpectrumPoint.fromCsv(List<dynamic> csvRow) {
    return SpectrumPoint(
      massToCharge: double.parse(csvRow[0].toString()),
      relativeIntensity: double.parse(csvRow[1].toString()),
    );
  }
}