import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:flutter_rme/models/spectrum_point.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs

class SpectrumPlot extends StatefulWidget {
  final String csvData;
  final bool isMassSpectrum;

  const SpectrumPlot({
    super.key,
    required this.csvData,
    this.isMassSpectrum = true,
  });

  @override
  _SpectrumPlotState createState() => _SpectrumPlotState();
}

class _SpectrumPlotState extends State<SpectrumPlot> {
  List<SpectrumPoint> _spectralData = [];
  double _maxIntensity = 0;
  double _minXValue = 0;
  double _maxXValue = 0;
  List<FlSpot> _peaks = [];
  final Map<String, String> _metadata = {};

  @override
  void initState() {
    super.initState();
    _parseCsvData();
  }

  void _parseCsvData() {
    final csvRows = const CsvToListConverter().convert(widget.csvData);

    // Parse metadata
    for (int i = 0; i < min(20, csvRows.length); i++) {
      final row = csvRows[i];
      if (row.length >= 2 && row[0] is String) {
        _metadata[row[0].toString()] = row[1].toString();
      }
    }

    // Find data start
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

    print('Data starts at index: $dataStartIndex');
    if (dataStartIndex > 0 && dataStartIndex < csvRows.length) {
      final spectralData = csvRows
          .sublist(dataStartIndex)
          .where((row) => row.length >= 2)
          .map((row) => SpectrumPoint.fromCsv(row))
          .toList();

      if (spectralData.isNotEmpty) {
        final intensities = spectralData
            .map((e) => e.relativeIntensity)
            .toList();
        final xValues = spectralData.map((e) => e.massToCharge).toList();

        setState(() {
          _spectralData = spectralData;
          _maxIntensity = intensities.reduce((a, b) => a > b ? a : b);
          _minXValue = xValues.reduce((a, b) => a < b ? a : b);
          _maxXValue = xValues.reduce((a, b) => a > b ? a : b);
          _peaks = _findSignificantPeaks(spectralData);
        });
      }
    }
  }

  List<FlSpot> _findSignificantPeaks(List<SpectrumPoint> data) {
    if (data.isEmpty) return [];

    List<FlSpot> peaks = [];
    final threshold = _maxIntensity * 0.1; // 10% threshold
    final minPeakDistance =
        (_maxXValue - _minXValue) / 50; // Minimum distance between peaks

    // Find local maxima
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

    // Limit to top 20 peaks to prevent memory issues
    if (peaks.length > 20) {
      peaks.sort((a, b) => b.y.compareTo(a.y));
      peaks = peaks.sublist(0, 20);
      peaks.sort((a, b) => a.x.compareTo(b.x));
    }

    return peaks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNMR = !widget.isMassSpectrum;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNMR ? 'NMR Spectrum' : 'Mass Spectrum'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_metadata.isNotEmpty) ...[
              _buildMetadataSection(),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _spectralData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          minX: _minXValue,
                          maxX: _maxXValue,
                          minY: 0,
                          maxY: _maxIntensity * 1.1,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final xValue = isNMR
                                      ? '${spot.x.toStringAsFixed(2)} ppm'
                                      : '${spot.x.toStringAsFixed(4)} m/z';
                                  return LineTooltipItem(
                                    '$xValue\n${spot.y.toStringAsFixed(2)}%',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _spectralData
                                  .map(
                                    (point) => FlSpot(
                                      point.massToCharge,
                                      point.relativeIntensity,
                                    ),
                                  )
                                  .toList(),
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
                            rightTitles: AxisTitles(),
                            topTitles: AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: _calculateInterval(
                                  _maxXValue - _minXValue,
                                ),
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      value.toStringAsFixed(isNMR ? 2 : 1),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: _calculateInterval(_maxIntensity),
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(0),
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: _calculateInterval(
                              _maxIntensity,
                            ),
                            verticalInterval: _calculateInterval(
                              _maxXValue - _minXValue,
                            ),
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
                          // Only show the most intense peak by default
                          showingTooltipIndicators: _peaks.isNotEmpty
                              ? [
                                  ShowingTooltipIndicators([
                                    LineBarSpot(
                                      LineChartBarData(
                                        spots: _spectralData
                                            .map(
                                              (point) => FlSpot(
                                                point.massToCharge,
                                                point.relativeIntensity,
                                              ),
                                            )
                                            .toList(),
                                        isCurved: false,
                                        color: Colors.blue,
                                        barWidth: 1.5,
                                        isStrokeCapRound: true,
                                        belowBarData: BarAreaData(show: false),
                                        dotData: FlDotData(show: false),
                                      ),
                                      _spectralData.indexWhere(
                                        (p) =>
                                            p.massToCharge ==
                                            _peaks
                                                .firstWhere(
                                                  (peak) =>
                                                      peak.y ==
                                                      _peaks
                                                          .map((p) => p.y)
                                                          .reduce(max),
                                                )
                                                .x,
                                      ),
                                      _peaks.firstWhere(
                                        (peak) =>
                                            peak.y ==
                                            _peaks.map((p) => p.y).reduce(max),
                                      ),
                                    ),
                                  ]),
                                ]
                              : [],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              isNMR
                  ? 'Chemical Shift (ppm) vs Intensity'
                  : 'Mass-to-Charge (m/z) vs Relative Intensity',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              'Range: ${_minXValue.toStringAsFixed(isNMR ? 2 : 4)} to '
              '${_maxXValue.toStringAsFixed(isNMR ? 2 : 4)} '
              '${isNMR ? 'ppm' : 'm/z'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

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
        color: Colors.grey[100],
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
                    // Attempt to launch the URL. If it fails, show a SnackBar.
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      print('Could not launch $url with externalApplication mode.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open DOI link.')),
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

  double _calculateInterval(double range) {
    if (range <= 0) return 1;
    final exponent = (log(range) / ln10).floor();
    final fraction = range / pow(10, exponent);

    if (fraction < 2) return 0.2 * pow(10, exponent);
    if (fraction < 5) return 0.5 * pow(10, exponent);
    return 1 * pow(10, exponent).toDouble();
  }
}
