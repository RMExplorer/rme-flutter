// File: all_analytes_table.dart
import 'package:flutter/material.dart';
import '../models/analyte.dart'; // Import the Analyte model

/// A StatefulWidget that displays a table of all analytes across CRMs.
/// This widget allows users to view a list of analytes and sort them by
/// different columns.
class AllAnalytesTable extends StatefulWidget {
  /// The list of [Analyte] objects to display in the table.
  final List<Analyte> analytes;

  /// An optional initial search text to pre-populate the filter field.
  final String initialSearchText; //

  /// Constructs an [AllAnalytesTable].
  const AllAnalytesTable({
    super.key,
    required this.analytes,
    this.initialSearchText = '', //
  });

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
  String _searchText = '';

  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  // Pagination related state variables
  int _currentPage = 0; // The current page index
  int _itemsPerPage = 20; // Number of items to display per page, now dynamic
  final List<int> _availableItemsPerPage = [
    1,
    5,
    20,
    50,
    100,
  ]; // Options for items per page

  @override
  void initState() {
    super.initState();
    // Initialize _sortedAnalytes with a copy of the provided analytes.
    _sortedAnalytes = List.from(widget.analytes);
    _searchController.text =
        widget.initialSearchText; // Initialize with passed search text
    _searchController.addListener(_updateSearchText);
    _updateSearchText(); // Apply initial filter based on initialSearchText
  }

  /// Updates the [_searchText] based on the current value of the [_searchController].
  void _updateSearchText() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _currentPage = 0; // Reset to the first page when search text changes
    });
  }

  @override
  void dispose() {
    // Remove the listener and dispose the search controller to prevent memory leaks.
    _searchController.removeListener(_updateSearchText);
    _searchController.dispose();
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
      _currentPage = 0; // Reset to the first page after sorting
    });
  }

  /// Returns a filtered list of analytes based on the [_searchText].
  List<Analyte> get _filteredAnalytes {
    return _sortedAnalytes.where((a) {
      if (_searchText.isEmpty) return true;
      return a.crmName?.toLowerCase().contains(_searchText) == true ||
          a.name.toLowerCase().contains(_searchText) ||
          a.quantity.toLowerCase().contains(_searchText) ||
          a.value.toLowerCase().contains(_searchText) ||
          a.uncertainty.toLowerCase().contains(_searchText) ||
          a.unit.toLowerCase().contains(_searchText) ||
          a.type.toLowerCase().contains(_searchText) ||
          a.materialType?.toLowerCase().contains(_searchText) ==
              true; // Add materialType to search
    }).toList();
  }

  /// Returns a filtered and paginated list of analytes based on the [_searchText] and [_currentPage].
  List<Analyte> get _paginatedAnalytes {
    final filtered = _filteredAnalytes; // Use the already filtered list
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  /// Returns the total number of pages based on the filtered analytes.
  int get _totalPages {
    final filteredCount =
        _filteredAnalytes.length; // Use the count of the filtered list
    return (filteredCount / _itemsPerPage).ceil();
  }

  /// A helper function to parse the value string into a double for sorting.
  /// It removes '<' and '+' signs before attempting to parse.
  double _parseValue(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'[<+]'), '');
    return double.tryParse(cleanedValue) ?? double.negativeInfinity;
  }

  /// Builds a sortable column header with the correct sorting icon.
  Widget _buildSortableHeader(String title, int columnIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(width: 4),
        // Show icon only if the column is not sorted
        if (_sortColumnIndex != columnIndex)
          Icon(
            Icons.unfold_more,
            size: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Analytes Across CRMs:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Filter analytes',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Items/page:'), // Title for the dropdown
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _itemsPerPage,
              items: _availableItemsPerPage.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _itemsPerPage = newValue;
                    _currentPage =
                        0; // Reset to first page when items per page changes
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(
                label: _buildSortableHeader('CRM', 0),
                onSort: (i, asc) => _sort((a) => a.crmName ?? 'N/A', i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Analyte', 1),
                onSort: (i, asc) => _sort((a) => a.name, i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Material Type', 2),
                onSort: (i, asc) =>
                    _sort((a) => a.materialType ?? 'N/A', i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Quantity', 3),
                onSort: (i, asc) => _sort((a) => a.quantity, i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Value', 4),
                onSort: (i, asc) => _sort((a) => _parseValue(a.value), i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Uncertainty', 5),
                onSort: (i, asc) => _sort(
                  (a) =>
                      double.tryParse(a.uncertainty) ?? double.negativeInfinity,
                  i,
                  asc,
                ),
              ),
              DataColumn(
                label: _buildSortableHeader('Unit', 6),
                onSort: (i, asc) => _sort((a) => a.unit, i, asc),
              ),
              DataColumn(
                label: _buildSortableHeader('Type', 7),
                onSort: (i, asc) => _sort((a) => a.type, i, asc),
              ),
            ],
            rows: _paginatedAnalytes.map((analyte) {
              return DataRow(
                cells: [
                  DataCell(Text(getCrmNameUntilColon(analyte.crmName))),
                  DataCell(Text(analyte.name)),
                  DataCell(Text(analyte.materialType ?? 'N/A')),
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
        const SizedBox(height: 8),
        _buildPaginationControls(),
      ],
    );
  }

  /// Builds the pagination controls (Previous, Next, and page number).
  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPage > 0
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
              : null,
        ),
        Text('Page ${_currentPage + 1} of $_totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < _totalPages - 1
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
              : null,
        ),
      ],
    );
  }
}

/// Extracts the CRM name from the given [crmName] string until the first colon.
String getCrmNameUntilColon(String? crmName) {
  if (crmName == null) {
    return 'N/A';
  }
  final indexOfColon = crmName.indexOf(':');
  if (indexOfColon != -1) {
    return crmName.substring(0, indexOfColon);
  } else {
    return crmName;
  }
}
