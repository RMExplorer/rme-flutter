import 'package:flutter/material.dart';
import 'package:flutter_rme/models/pubchem_data.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../global_state.dart';

class PolarityMwPlotPage extends StatefulWidget {
  const PolarityMwPlotPage({super.key});

  @override
  State<PolarityMwPlotPage> createState() => _PolarityMwPlotPageState();
}

class _PolarityMwPlotPageState extends State<PolarityMwPlotPage> {
  // Sorting variables
  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);
    final selectedAnalytes = globalState.selectedAnalytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polarity vs. Molecular Weight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => globalState.clearAllAnalytes(),
          ),
        ],
      ),
      body: selectedAnalytes.isEmpty
          ? const Center(child: Text('No analytes selected'))
          : _buildChartWithData(globalState),
    );
  }

  Widget _buildChartWithData(GlobalState state) {
    final dataList = state.pubChemData;
    List<PubChemData> validData = dataList
        .where((data) => data.molecularWeight != null && data.pKow != null)
        .toList();

    if (validData.isEmpty) {
      return const Center(child: Text('No valid data available'));
    }

    // Sorting
    if (_sortColumnIndex != null) {
      validData.sort((a, b) {
        final aValue = _sortColumnIndex == 1 ? a.molecularWeight : a.pKow;
        final bValue = _sortColumnIndex == 1 ? b.molecularWeight : b.pKow;

        if (aValue == null || bValue == null) return 0;

        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    }

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
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots.asMap().entries.map((entry) {
                  final spot = entry.value;
                  return ScatterSpot(spot.x, spot.y);
                }).toList(),
                minX: -10,
                maxX: 10,
                minY: 0,
                maxY: 2500,
                borderData: FlBorderData(show: true),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipItems: (ScatterSpot touchedSpot) {
                      // Find the index of the touched spot
                      final index = spots.indexWhere(
                        (spot) =>
                            spot.x == touchedSpot.x && spot.y == touchedSpot.y,
                      );

                      // Get the name from validData using the index
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
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 500, // Match with Y-axis titles interval
                  verticalInterval: 2, // Match with X-axis titles interval
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.withValues(), strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: Colors.grey.withValues(), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
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
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(
                    label: const Text(
                      'Compound',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: const Text(
                      'MW (g/mol)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                  DataColumn(
                    label: const Text(
                      'pKow',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                ],
                rows: validData
                    .map(
                      (data) => DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                data.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              data.molecularWeight?.toStringAsFixed(2) ?? 'N/A',
                              style: const TextStyle(fontFamily: 'RobotoMono'),
                            ),
                          ),
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
