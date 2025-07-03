import 'package:flutter/material.dart';
import '../models/analyte.dart';

/// A StatefulWidget that displays a sortable and filterable table of [Analyte] objects.
///
/// This widget allows users to view a list of analytes, sort them by different
/// columns, filter them using a search bar, and select multiple analytes.
class AnalyteTable extends StatefulWidget {
  /// The list of [Analyte] objects to be displayed in the table.
  final List<Analyte>? analytes;

  /// A callback function that is invoked when the selection of analytes changes.
  /// It provides the updated list of selected [Analyte] objects.
  final void Function(List<Analyte>)? onSelectionChanged;

  /// Creates an [AnalyteTable].
  ///
  /// The [key] is used to control how one widget replaces another in the widget tree.
  /// The [analytes] parameter is required and represents the data to be displayed.
  /// The [onSelectionChanged] is an optional callback.
  const AnalyteTable({
    super.key,
    required this.analytes,
    this.onSelectionChanged,
  });

  @override
  State<AnalyteTable> createState() => _AnalyteTableState();
}

/// The private State class for [AnalyteTable].
class _AnalyteTableState extends State<AnalyteTable> {
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

  /// The list of currently selected analytes.
  final List<Analyte> _selectedAnalytes = [];

  @override
  void initState() {
    super.initState();
    // Initialize _sortedAnalytes with a copy of the provided analytes.
    _sortedAnalytes = List.from(widget.analytes ?? []);
    // Add a listener to the search controller to update _searchText when its value changes.
    _searchController.addListener(_updateSearchText);
  }

  /// Updates the [_searchText] based on the current value of the [_searchController].
  void _updateSearchText() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
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
    });
  }

  /// Returns a filtered list of analytes based on the [_searchText].
  ///
  /// If [_searchText] is empty, the entire [_sortedAnalytes] list is returned.
  /// Otherwise, it filters analytes whose name, quantity, value, uncertainty,
  /// unit, or type contains the [_searchText] (case-insensitive).
  List<Analyte> get _filteredAnalytes {
    if (_searchText.isEmpty) return _sortedAnalytes;
    return _sortedAnalytes.where((a) {
      return a.name.toLowerCase().contains(_searchText) ||
          a.quantity.toLowerCase().contains(_searchText) ||
          a.value.toLowerCase().contains(_searchText) ||
          a.uncertainty.toLowerCase().contains(_searchText) ||
          a.unit.toLowerCase().contains(_searchText) ||
          a.type.toLowerCase().contains(_searchText);
    }).toList();
  }

  /// Toggles the selection status of an [analyte].
  ///
  /// If the analyte is already selected, it is removed from [_selectedAnalytes].
  /// Otherwise, it is added. After modifying the selection, the [onSelectionChanged]
  /// callback is invoked with the updated list of selected analytes.
  ///
  /// [analyte] The [Analyte] object whose selection status is to be toggled.
  void _toggleSelection(Analyte analyte) {
    setState(() {
      if (_selectedAnalytes.contains(analyte)) {
        _selectedAnalytes.remove(analyte);
      } else {
        _selectedAnalytes.add(analyte);
      }
      widget.onSelectionChanged?.call(List.from(_selectedAnalytes));
    });
  }

  /// Checks if an [analyte] is currently selected.
  ///
  /// [analyte] The [Analyte] object to check.
  /// Returns `true` if the analyte is selected, `false` otherwise.
  bool _isSelected(Analyte analyte) {
    return _selectedAnalytes.contains(analyte);
  }

  @override
  Widget build(BuildContext context) {
    // If there are no analytes, return an empty SizedBox to occupy no space.
    if (_sortedAnalytes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Analyte Composition:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Search text field for filtering analytes.
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Filter analytes',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        // A SingleChildScrollView allows the DataTable to be scrollable horizontally
        // if its content exceeds the screen width.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(
                label: const Text('Analyte'),
                onSort: (i, asc) => _sort((a) => a.name, i, asc),
              ),
              DataColumn(
                label: const Text('Quantity'),
                onSort: (i, asc) => _sort((a) => a.quantity, i, asc),
              ),
              DataColumn(
                label: const Text('Value'),
                onSort: (i, asc) => _sort((a) => a.value, i, asc),
              ),
              DataColumn(
                label: const Text('Uncertainty'),
                onSort: (i, asc) => _sort((a) => a.uncertainty, i, asc),
              ),
              DataColumn(
                label: const Text('Unit'),
                onSort: (i, asc) => _sort((a) => a.unit, i, asc),
              ),
              DataColumn(
                label: const Text('Type'),
                onSort: (i, asc) => _sort((a) => a.type, i, asc),
              ),
            ],
            rows: _filteredAnalytes.map((analyte) {
              final isSelected = _isSelected(analyte);
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => _toggleSelection(analyte),
                cells: [
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
        const SizedBox(height: 16),
        // Displays the number of selected items.
        Text(
          'Selected: ${_selectedAnalytes.length} item(s)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Displays chips for selected analytes, allowing them to be deselected.
        _selectedAnalytes.isNotEmpty
            ? Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedAnalytes.map((analyte) {
                  return Chip(
                    label: Text(analyte.name),
                    onDeleted: () => _toggleSelection(analyte),
                  );
                }).toList(),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}