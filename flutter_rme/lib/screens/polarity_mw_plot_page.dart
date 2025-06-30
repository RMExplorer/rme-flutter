import 'package:flutter/material.dart';
import 'package:flutter_rme/models/pubchem_data.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../global_state.dart';

/// A StatefulWidget that displays a scatter plot of Polarity (pKow) vs. Molecular Weight.
///
/// This page visualizes chemical analyte data, allowing users to understand the
/// relationship between a compound's polarity and its molecular weight.
/// It also includes a data table displaying the analytes and their properties,
/// with sorting capabilities.
class PolarityMwPlotPage extends StatefulWidget {
  /// Creates a [PolarityMwPlotPage].
  const PolarityMwPlotPage({super.key});

  @override
  State<PolarityMwPlotPage> createState() => _PolarityMwPlotPageState();
}

/// The state for [PolarityMwPlotPage].
class _PolarityMwPlotPageState extends State<PolarityMwPlotPage> {
  // Sorting variables for the data table.
  bool _sortAscending = true;
  int? _sortColumnIndex;

  /// Helper widget for creating quadrant labels to avoid repeating code.
  ///
  /// [text] is the content of the label.
  /// [backgroundColor] is the background color of the label container.
  Widget _buildQuadrantLabel(String text, {required Color backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the global state using Provider to get selected analytes.
    final globalState = Provider.of<GlobalState>(context);
    final selectedAnalytes = globalState.selectedAnalytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polarity vs. Molecular Weight'),
        actions: [
          // Button to clear all selected analytes.
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => globalState.clearAllAnalytes(),
          ),
        ],
      ),
      // Display a message if no analytes are selected, otherwise build the chart.
      body: selectedAnalytes.isEmpty
          ? const Center(child: Text('No analytes selected'))
          : _buildChartWithData(globalState),
    );
  }

  /// Builds the scatter chart and the data table with the provided global state data.
  ///
  /// [state] is the [GlobalState] object containing the PubChem data.
  Widget _buildChartWithData(GlobalState state) {
    final dataList = state.pubChemData;
    // Filter out data points that do not have both molecular weight and pKow.
    List<PubChemData> validData = dataList
        .where((data) => data.molecularWeight != null && data.pKow != null)
        .toList();

    // Display a message if no valid data is available after filtering.
    if (validData.isEmpty) {
      return const Center(child: Text('No valid data available'));
    }

    // Apply sorting to the valid data based on the current sort column and order.
    if (_sortColumnIndex != null) {
      validData.sort((a, b) {
        // Determine which value to sort by (molecular weight or pKow).
        final aValue = _sortColumnIndex == 1 ? a.molecularWeight : a.pKow;
        final bValue = _sortColumnIndex == 1 ? b.molecularWeight : b.pKow;

        // Handle null values during sorting.
        if (aValue == null || bValue == null) return 0;

        // Apply ascending or descending sort order.
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    }

    // Convert valid PubChemData into FlSpot objects for the scatter chart.
    // pKow is clamped between -10 and 10, Molecular Weight between 0 and 2500.
    final spots = validData
        .map(
          (data) => FlSpot(
            data.pKow!.clamp(-10.0, 10.0),
            data.molecularWeight!.clamp(0.0, 2500.0),
          ),
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // Stack is used to overlay the quadrant labels on top of the chart.
            child: Stack(
              children: [
                ScatterChart(
                  ScatterChartData(
                    // Map FlSpot objects to ScatterSpot objects for the chart.
                    scatterSpots: spots.asMap().entries.map((entry) {
                      final spot = entry.value;
                      return ScatterSpot(spot.x, spot.y);
                    }).toList(),
                    minX: -10, // Minimum value for the X-axis (pKow).
                    maxX: 10, // Maximum value for the X-axis (pKow).
                    minY: 0, // Minimum value for the Y-axis (Molecular Weight).
                    maxY: 2500, // Maximum value for the Y-axis (Molecular Weight).
                    borderData: FlBorderData(show: true), // Show chart borders.
                    scatterTouchData: ScatterTouchData(
                      enabled: true, // Enable touch interactions on scatter spots.
                      touchTooltipData: ScatterTouchTooltipData(
                        // Define how tooltips are displayed when a spot is touched.
                        getTooltipItems: (ScatterSpot touchedSpot) {
                          // Find the index of the touched spot in the original data.
                          final index = spots.indexWhere(
                            (spot) =>
                                spot.x == touchedSpot.x && spot.y == touchedSpot.y,
                          );
                          // Get the compound name for the tooltip.
                          final name = index >= 0 && index < validData.length
                              ? validData[index].name
                              : '';
                          return ScatterTooltipItem(
                            name,
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            bottomMargin: 6,
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true, // Show grid lines.
                      drawVerticalLine: true, // Draw vertical grid lines.
                      drawHorizontalLine: true, // Draw horizontal grid lines.
                      horizontalInterval: 500, // Interval for horizontal grid lines.
                      verticalInterval: 2, // Interval for vertical grid lines.
                      getDrawingHorizontalLine: (value) {
                        // Customize the horizontal grid line at Y=500.
                        if (value == 500) {
                          return const FlLine(color: Colors.red, strokeWidth: 2);
                        }
                        return FlLine(
                          color: Colors.grey.withOpacity(0.5),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        // Customize the vertical grid line at X=-2.
                        if (value == -2) {
                          return const FlLine(
                            color: Colors.blueAccent,
                            strokeWidth: 2,
                          );
                        }
                        return FlLine(
                          color: Colors.grey.withOpacity(0.5),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, // Show titles on the left axis.
                          reservedSize: 35, // Space reserved for titles.
                          interval: 500, // Interval for left axis titles.
                          getTitlesWidget: (value, meta) {
                            // Custom widget for left axis titles (Molecular Weight).
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                        axisNameWidget: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            'Molecular Weight (g/mol)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, // Show titles on the bottom axis.
                          reservedSize: 40, // Space reserved for titles.
                          interval: 2, // Interval for bottom axis titles.
                          getTitlesWidget: (value, meta) {
                            // Custom widget for bottom axis titles (pKow).
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                        axisNameWidget: const Padding(
                          padding: EdgeInsets.only(top: 0.0),
                          child: Text('pKow', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Hide right axis titles.
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Hide top axis titles.
                      ),
                    ),
                  ),
                ),
                // Positioned labels for each quadrant of the scatter plot.
                Positioned(
                  top: 20,
                  left: 65,
                  child: _buildQuadrantLabel(
                    'Low Polarity\nHigh MW',
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildQuadrantLabel(
                    'High Polarity\nHigh MW',
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 65,
                  child: _buildQuadrantLabel(
                    'Low Polarity\nLow MW',
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  right: 20,
                  child: _buildQuadrantLabel(
                    'High Polarity\nLow MW',
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16), // Spacer between chart and table.
        SizedBox(
          height: 200, // Fixed height for the data table container.
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Enable vertical scrolling for the table.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scrolling for the table.
              child: DataTable(
                columnSpacing: 20, // Spacing between columns.
                sortColumnIndex: _sortColumnIndex, // Current sorted column.
                sortAscending: _sortAscending, // Current sort order.
                columns: [
                  // DataColumn for Compound Name, with sorting enabled.
                  DataColumn(
                    label: const Text(
                      'Compound',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onSort: (columnIndex, ascending) {
                      // Update sort state when column header is tapped.
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  // DataColumn for Molecular Weight, with sorting enabled.
                  DataColumn(
                    label: const Text(
                      'MW (g/mol)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true, // Indicates a numeric column for right alignment.
                    onSort: (columnIndex, ascending) {
                      // Update sort state when column header is tapped.
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  // DataColumn for pKow, with sorting enabled.
                  DataColumn(
                    label: const Text(
                      'pKow',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true, // Indicates a numeric column for right alignment.
                    onSort: (columnIndex, ascending) {
                      // Update sort state when column header is tapped.
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                ],
                // Generate DataRows from the validData list.
                rows: validData
                    .map(
                      (data) => DataRow(
                        cells: [
                          // DataCell for compound name, with overflow handling.
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                data.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // DataCell for Molecular Weight, formatted to two decimal places.
                          DataCell(
                            Text(
                              data.molecularWeight?.toStringAsFixed(2) ?? 'N/A',
                              style: const TextStyle(fontFamily: 'RobotoMono'),
                            ),
                          ),
                          // DataCell for pKow, formatted to two decimal places.
                          DataCell(
                            Text(
                              data.pKow?.toStringAsFixed(2) ?? 'N/A',
                              style: const TextStyle(fontFamily: 'RobotoMono'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}