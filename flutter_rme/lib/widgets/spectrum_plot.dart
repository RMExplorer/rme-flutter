// spectrum_plot.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter_rme/models/spectrum_point.dart';
import 'package:url_launcher/url_launcher.dart';

/// A StatefulWidget that displays a spectrum plot from CSV data.
/// It can render either a Mass Spectrum or an NMR Spectrum.
class SpectrumPlot extends StatefulWidget {
  /// The CSV data as a string, containing the spectral points and potentially metadata.
  final String csvData;

  /// A boolean flag indicating whether the spectrum is a mass spectrum (true)
  /// or an NMR spectrum (false). Defaults to true.
  final bool isMassSpectrum;

  // New properties for axis reversal
  final bool reverseXAxis;
  final bool reverseYAxis;

  // Callbacks for axis reversal
  final ValueChanged<bool> onToggleReverseXAxis;
  final ValueChanged<bool> onToggleReverseYAxis;

  /// Creates a [SpectrumPlot] widget.
  ///
  /// The [key] is used to control how one widget replaces another in the widget tree.
  /// The [csvData] is required and must contain the spectrum data.
  /// The [isMassSpectrum] flag determines the labeling and interpretation of the plot.
  const SpectrumPlot({
    super.key,
    required this.csvData,
    this.isMassSpectrum = true,
    this.reverseXAxis = false, // Initialize to false
    this.reverseYAxis = false, // Initialize to false
    required this.onToggleReverseXAxis,
    required this.onToggleReverseYAxis,
  });

  @override
  _SpectrumPlotState createState() => _SpectrumPlotState();
}

/// The private State class for [SpectrumPlot].
class _SpectrumPlotState extends State<SpectrumPlot> {
  /// List of [SpectrumPoint] objects parsed from the CSV data.
  List<SpectrumPoint> _spectralData = [];

  /// The maximum intensity value found in the spectral data.
  double _maxIntensity = 0;

  /// The minimum X-axis value (mass-to-charge or chemical shift).
  double _minXValue = 0;

  /// The maximum X-axis value (mass-to-charge or chemical shift).
  double _maxXValue = 0;

  /// A list of [FlSpot] objects representing significant peaks in the spectrum.
  List<FlSpot> _peaks = [];

  /// A map to store metadata extracted from the CSV data.
  final Map<String, String> _metadata = {};

  // Define a small epsilon value to prevent lines from going below the axis.
  static const double _minPlottingIntensity = 0.001;

  // Transformation controller for InteractiveViewer
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _parseCsvData();
  }

  @override
  void didUpdateWidget(covariant SpectrumPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.csvData != oldWidget.csvData ||
        widget.reverseXAxis != oldWidget.reverseXAxis ||
        widget.reverseYAxis != oldWidget.reverseYAxis) {
      _parseCsvData();
    }
  }

  /// Parses the CSV data provided to the widget.
  void _parseCsvData() {
    final csvRows = const CsvToListConverter().convert(widget.csvData);

    for (int i = 0; i < min(20, csvRows.length); i++) {
      final row = csvRows[i];
      if (row.length >= 2 && row[0] is String) {
        _metadata[row[0].toString()] = row[1].toString();
      }
    }

    int dataStartIndex = csvRows.indexWhere((row) {
      if (row.length < 2) return false;
      final x = double.tryParse(row[0].toString().trim());
      final y = double.tryParse(row[1].toString().trim());
      return x != null && y != null;
    });

    if (dataStartIndex == -1) {
      print('Could not find numeric data start row.');
      return;
    }

    if (dataStartIndex > 0 && dataStartIndex < csvRows.length) {
      final spectralData = csvRows
          .sublist(dataStartIndex)
          .where((row) => row.length >= 2)
          .map((row) => SpectrumPoint.fromCsv(row))
          .toList();

      if (spectralData.isNotEmpty) {
        final intensities = spectralData.map((e) => e.relativeIntensity).toList();
        final xValues = spectralData.map((e) => e.massToCharge).toList();

        setState(() {
          _spectralData = spectralData;
          _maxIntensity = intensities.reduce((a, b) => a > b ? a : b);
          _minXValue = xValues.reduce((a, b) => a < b ? a : b);
          _maxXValue = xValues.reduce((a, b) => a > b ? a : b);
          _peaks = _findSignificantPeaks(spectralData);
          _transformationController.value = Matrix4.identity();
        });
      }
    }
  }

  /// Identifies significant peaks in the spectral data.
  List<FlSpot> _findSignificantPeaks(List<SpectrumPoint> data) {
    if (data.isEmpty) return [];

    List<FlSpot> peaks = [];
    final threshold = _maxIntensity * 0.1;
    final minPeakDistance = (_maxXValue - _minXValue) / 50;

    for (int i = 2; i < data.length - 2; i++) {
      final current = data[i].relativeIntensity;
      if (current > threshold &&
          current > data[i - 1].relativeIntensity &&
          current > data[i + 1].relativeIntensity &&
          current > data[i - 2].relativeIntensity &&
          current > data[i + 2].relativeIntensity) {
        if (peaks.isEmpty ||
            (data[i].massToCharge - peaks.last.x).abs() > minPeakDistance) {
          peaks.add(FlSpot(data[i].massToCharge, current));
        }
      }
    }

    if (peaks.length > 20) {
      peaks.sort((a, b) => b.y.compareTo(a.y));
      peaks = peaks.sublist(0, 20);
      peaks.sort((a, b) => a.x.compareTo(b.x));
    }

    return peaks;
  }

  /// Resets the zoom and pan to the initial state (full view).
  void _resetView() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNMR = !widget.isMassSpectrum;

    double chartMinX = _minXValue;
    double chartMaxX = _maxXValue;
    double chartMinY = 0;
    double chartMaxY = _maxIntensity * 1.1;

    List<FlSpot> plotSpots = _spectralData.map((point) {
      double x = point.massToCharge;
      double y = max(_minPlottingIntensity, point.relativeIntensity);

      if (widget.reverseXAxis) {
        x = _maxXValue - (x - _minXValue);
      }
      if (widget.reverseYAxis) {
        y = (_maxIntensity * 1.1) - y + 0;
      }
      return FlSpot(x, y);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_metadata.isNotEmpty) ...[
          _buildMetadataSection(),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: _spectralData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor, // Changed from Colors.white
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 0.1,
                              maxScale: 10.0,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              child: LineChart(
                                LineChartData(
                                  minX: chartMinX,
                                  maxX: chartMaxX,
                                  minY: chartMinY,
                                  maxY: chartMaxY,
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    handleBuiltInTouches: false,
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          double originalX = spot.x;
                                          double originalY = spot.y;
                                          if (widget.reverseXAxis) {
                                            originalX = _minXValue + (_maxXValue - spot.x);
                                          }
                                          if (widget.reverseYAxis) {
                                            originalY = (_maxIntensity * 1.1) - spot.y + 0;
                                          }
                                          final xValue = isNMR
                                              ? '${originalX.toStringAsFixed(2)} ppm'
                                              : '${originalX.toStringAsFixed(4)} m/z';
                                          final yValue = originalY <= _minPlottingIntensity
                                              ? '0.00'
                                              : originalY.toStringAsFixed(2);
                                          return LineTooltipItem(
                                            '$xValue\n$yValue%',
                                            const TextStyle(color: Colors.white),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: plotSpots,
                                      isCurved: false,
                                      color: Colors.blue,
                                      barWidth: 1.5,
                                      isStrokeCapRound: true,
                                      belowBarData: BarAreaData(show: false),
                                      dotData: FlDotData(show: false),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(),
                                    topTitles: const AxisTitles(),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        interval: _calculateInterval(chartMaxX - chartMinX),
                                        getTitlesWidget: (value, meta) {
                                          final textValue = widget.reverseXAxis
                                              ? (_maxXValue - (value - _minXValue)).toStringAsFixed(isNMR ? 2 : 1)
                                              : value.toStringAsFixed(isNMR ? 2 : 1);
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(textValue, style: theme.textTheme.bodySmall),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        interval: _calculateInterval(chartMaxY - chartMinY),
                                        getTitlesWidget: (value, meta) {
                                          String displayedValue;
                                          if (isNMR && value >= 1000000) {
                                            displayedValue = value.toStringAsExponential(1);
                                          } else {
                                            displayedValue = value.toStringAsFixed(0);
                                          }
                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(displayedValue, style: theme.textTheme.bodySmall),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: _calculateInterval(chartMaxY - chartMinY),
                                    verticalInterval: _calculateInterval(chartMaxX - chartMinX),
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withOpacity(0.3),
                                      strokeWidth: 1,
                                    ),
                                    getDrawingVerticalLine: (value) => FlLine(
                                      color: Colors.grey.withOpacity(0.3),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  showingTooltipIndicators: _peaks.isNotEmpty
                                      ? [
                                          ShowingTooltipIndicators([
                                            LineBarSpot(
                                              LineChartBarData(
                                                spots: plotSpots,
                                                isCurved: false,
                                                color: Colors.blue,
                                                barWidth: 1.5,
                                                isStrokeCapRound: true,
                                                belowBarData: BarAreaData(show: false),
                                                dotData: FlDotData(show: false),
                                              ),
                                              _spectralData.indexWhere(
                                                (p) => p.massToCharge == _peaks.firstWhere((peak) => peak.y == _peaks.map((p) => p.y).reduce(max)).x,
                                              ),
                                              (() {
                                                FlSpot originalPeak = _peaks.firstWhere((peak) => peak.y == _peaks.map((p) => p.y).reduce(max));
                                                double peakX = originalPeak.x;
                                                double peakY = originalPeak.y;
                                                if (widget.reverseXAxis) {
                                                  peakX = _maxXValue - (peakX - _minXValue);
                                                }
                                                if (widget.reverseYAxis) {
                                                  peakY = (_maxIntensity * 1.1) - peakY + 0;
                                                }
                                                return FlSpot(peakX, peakY);
                                              })(),
                                            ),
                                          ]),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                          ),
                          // Reset Zoom button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              heroTag: "resetZoomBtn",
                              onPressed: _resetView,
                              child: const Icon(Icons.zoom_out_map),
                            ),
                          ),
                          Positioned(
                            bottom: 4.0,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                isNMR ? 'Chemical Shift (ppm)' : 'Mass-to-Charge (m/z)',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 4.0,
                            top: 0,
                            bottom: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  'Relative Intensity',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Text(
          'Range: ${_minXValue.toStringAsFixed(isNMR ? 2 : 4)} to '
          '${_maxXValue.toStringAsFixed(isNMR ? 2 : 4)} '
          '${isNMR ? 'ppm' : 'm/z'}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                widget.onToggleReverseXAxis(!widget.reverseXAxis);
              },
              child: Text(
                widget.reverseXAxis ? 'Un-reverse X-axis' : 'Reverse X-axis',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onToggleReverseYAxis(!widget.reverseYAxis);
              },
              child: Text(
                widget.reverseYAxis ? 'Un-reverse Y-axis' : 'Reverse Y-axis',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the metadata section.
  Widget _buildMetadataSection() {
    final importantMetadata = [
      if (_metadata.containsKey('Substance')) 'Substance',
      if (_metadata.containsKey('InChIKey')) 'InChIKey',
      if (_metadata.containsKey('Instrument')) 'Instrument',
      if (_metadata.containsKey('Resolution')) 'Resolution',
      if (_metadata.containsKey('Frequency')) 'Frequency',
      if (_metadata.containsKey('Collision Energy')) 'Collision Energy',
      if (_metadata.containsKey('DOI')) 'DOI',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Changed from Colors.grey[100]
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: importantMetadata.map((key) {
          if (key == 'DOI') {
            final doiValue = _metadata[key];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: GestureDetector(
                onTap: () async {
                  if (doiValue != null && doiValue.isNotEmpty) {
                    final url = Uri.parse('https://doi.org/$doiValue');
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      print(
                        'Could not launch $url with externalApplication mode.',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open DOI link.'),
                        ),
                      );
                    } else {
                      print('Successfully launched $url');
                    }
                  }
                },
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '$key: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: doiValue,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: '$key: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: _metadata[key]),
                  ],
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  /// Calculates an appropriate interval for axis titles and grid lines.
  double _calculateInterval(double range) {
    if (range <= 0) return 1;
    final exponent = (log(range) / ln10).floor();
    final fraction = range / pow(10, exponent);

    double interval;
    if (fraction < 2) {
      interval = 0.2 * pow(10, exponent);
    } else if (fraction < 5) {
      interval = 0.5 * pow(10, exponent);
    } else {
      interval = 1 * pow(10, exponent).toDouble();
    }
    return interval;
  }
}