// File: all_analytes_table.dart
import 'package:flutter/material.dart';
import '../models/analyte.dart'; // Import the Analyte model

/// A StatefulWidget that displays a table of all analytes across CRMs.
/// This widget allows users to view a list of analytes and sort them by
/// different columns.
class AllAnalytesTable extends StatefulWidget {
  /// The list of [Analyte] objects to display in the table.
  final List<Analyte> analytes;

  /// Constructs an [AllAnalytesTable].
  const AllAnalytesTable({super.key, required this.analytes});

  @override
  State<AllAnalytesTable> createState() => _AllAnalytesTableState();
}

/// The private State class for [AllAnalytesTable].
class _AllAnalytesTableState extends State<AllAnalytesTable> {
  /// The index of the currently sorted column. Null if no column is sorted.
  int? _sortColumnIndex;

  /// Indicates whether the current sort order is ascending.
  bool _sortAscending = true;

  /// The list of analytes, potentially sorted based on user interaction.
  late List<Analyte> _sortedAnalytes;

  /// The current text entered in the search bar, converted to lowercase.
  String _searchText = ''; //

  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController(); //

  @override
  void initState() {
    super.initState();
    // Initialize _sortedAnalytes with a copy of the provided analytes.
    _sortedAnalytes = List.from(widget.analytes);
    // Add a listener to the search controller to update _searchText when its value changes.
    _searchController.addListener(_updateSearchText); //
  }

  /// Updates the [_searchText] based on the current value of the [_searchController].
  void _updateSearchText() {
    setState(() {
      _searchText = _searchController.text.toLowerCase(); //
    });
  }

  @override
  void dispose() {
    // Remove the listener and dispose the search controller to prevent memory leaks.
    _searchController.removeListener(_updateSearchText); //
    _searchController.dispose(); //
    super.dispose();
  }

  /// Sorts the [_sortedAnalytes] list based on the specified [getField] function,
  /// [columnIndex], and [ascending] order.
  ///
  /// [getField] A function that extracts a comparable value from an [Analyte] object.
  /// [columnIndex] The index of the column that is being sorted.
  /// [ascending] A boolean indicating whether the sort order should be ascending.
  void _sort<T>(
    Comparable<T> Function(Analyte analyte) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortedAnalytes.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });

      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// Returns a generic sort icon if the column is not sorted.
  /// This icon will be displayed alongside the column's text.
  Widget _getUnsortedIcon(int columnIndex) {
    if (_sortColumnIndex != columnIndex) {
      return const Icon(Icons.unfold_more, size: 16.0); // Not sorted
    }
    return const SizedBox.shrink(); // Hide the icon if sorted, as DataTable provides its own
  }

  /// Returns a filtered list of analytes based on the [_searchText].
  ///
  /// If [_searchText] is empty, the entire [_sortedAnalytes] list is returned.
  /// Otherwise, it filters analytes whose name, quantity, value, uncertainty,
  /// unit, or type contains the [_searchText] (case-insensitive).
  List<Analyte> get _filteredAnalytes {
    if (_searchText.isEmpty) return _sortedAnalytes; //
    return _sortedAnalytes.where((a) {
      return a.crmName?.toLowerCase().contains(_searchText) == true || // Added CRM name to filter
          a.name.toLowerCase().contains(_searchText) ||
          a.quantity.toLowerCase().contains(_searchText) ||
          a.value.toLowerCase().contains(_searchText) ||
          a.uncertainty.toLowerCase().contains(_searchText) ||
          a.unit.toLowerCase().contains(_searchText) ||
          a.type.toLowerCase().contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Analytes Across CRMs:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Search text field for filtering analytes.
        TextField(
          controller: _searchController, //
          decoration: const InputDecoration(
            labelText: 'Filter analytes', //
            prefixIcon: Icon(Icons.search), //
            border: OutlineInputBorder(), //
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(
                label: Row(
                  children: [
                    const Text('CRM'),
                    _getUnsortedIcon(0), // Index for CRM column
                  ],
                ),
                onSort: (i, asc) => _sort((a) => a.crmName ?? 'N/A', i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Analyte'),
                    _getUnsortedIcon(1), // Index for Analyte column
                  ],
                ),
                onSort: (i, asc) => _sort((a) => a.name, i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Quantity'),
                    _getUnsortedIcon(2), // Index for Quantity column
                  ],
                ),
                onSort: (i, asc) => _sort((a) => a.quantity, i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Value'),
                    _getUnsortedIcon(3), // Index for Value column
                  ],
                ),
                // Sort by numerical value, treating unparseable values as negative infinity
                onSort: (i, asc) => _sort((a) => double.tryParse(a.value) ?? double.negativeInfinity, i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Uncertainty'),
                    _getUnsortedIcon(4), // Index for Uncertainty column
                  ],
                ),
                // Sort by numerical value, treating unparseable values as negative infinity
                onSort: (i, asc) => _sort((a) => double.tryParse(a.uncertainty) ?? double.negativeInfinity, i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Unit'),
                    _getUnsortedIcon(5), // Index for Unit column
                  ],
                ),
                onSort: (i, asc) => _sort((a) => a.unit, i, asc),
              ),
              DataColumn(
                label: Row(
                  children: [
                    const Text('Type'),
                    _getUnsortedIcon(6), // Index for Type column
                  ],
                ),
                onSort: (i, asc) => _sort((a) => a.type, i, asc),
              ),
            ],
            rows: _filteredAnalytes.map((analyte) { // Use _filteredAnalytes here
              return DataRow(
                cells: [
                  DataCell(Text(analyte.crmName?.substring(0, 6) ?? 'N/A')),
                  DataCell(Text(analyte.name)),
                  DataCell(Text(analyte.quantity)),
                  DataCell(Text(analyte.value)),
                  DataCell(Text(analyte.uncertainty)),
                  DataCell(Text(analyte.unit)),
                  DataCell(Text(analyte.type)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}