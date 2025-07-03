import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/analyte.dart';
import '../models/crm_item.dart';
import '../models/crm_detail.dart';
import '../screens/properties_page.dart';
import '../screens/spectrum_page.dart';
import '../services/crm_service.dart';
import '../services/pubchem_service.dart';
import '../widgets/analyte_table.dart';
import '../global_state.dart';
import '../models/pubchem_data.dart'; // Import PubChemData

/// A StatefulWidget that provides a user interface for searching and
/// interacting with Certified Reference Materials (CRMs).
///
/// This page allows users to search for CRMs by name, view their detailed
/// information, select individual analytes within a CRM, and navigate to
/// detailed properties or spectrum pages for the selected analytes. It
/// integrates with [CrmService] to fetch CRM data and [PubChemService]
/// to enrich analyte data.
class CrmSearchPage extends StatefulWidget {
  /// Constructs a [CrmSearchPage].
  const CrmSearchPage({super.key});

  @override
  _CrmSearchPageState createState() => _CrmSearchPageState();
}

/// The private State class for [CrmSearchPage].
///
/// Manages the state and logic for CRM searching, selection,
/// detail loading, and analyte management. It handles user input
/// for searching CRMs, displays CRM details, and allows users to
/// select analytes from a CRM. It interacts with [CrmService] to
/// fetch CRM data, [PubChemService] to retrieve PubChem data
/// for analytes, and updates the [GlobalState] with selected analytes.
class _CrmSearchPageState extends State<CrmSearchPage> {
  /// Controller for the CRM search input field.
  final TextEditingController _searchController = TextEditingController();

  /// Service for interacting with the CRM data API.
  /// Used to fetch lists of CRMs and their detailed information.
  final CrmService _crmService = CrmService();

  /// Service for interacting with the PubChem data API.
  /// Used to fetch compound information and synonyms.
  final PubChemService _pubChemService = PubChemService();

  /// A list of [CrmItem] objects representing the CRMs fetched
  /// either initially or via a search query.
  List<CrmItem> _crmItems = [];

  /// The ID of the currently selected CRM from the dropdown.
  /// This will be used as the unique value for the DropdownMenuItem.
  String? _selectedCrmId;

  /// The detailed information ([CrmDetail]) for the currently selected CRM.
  /// This object contains the summary, DOI, publication date, and analyte data.
  CrmDetail? _selectedDetail;

  /// A flag indicating whether data is currently being loaded from the services.
  bool _isLoading = false;

  /// A flag indicating whether the initial loading of CRMs has completed.
  /// Used to display a loading indicator only during the initial fetch.
  bool _initialLoadComplete = false;

  /// Stores any error message encountered during data loading or processing.
  /// This message is displayed to the user.
  String? _errorMessage;

  /// A flag indicating whether a severe error has occurred that should
  /// be displayed prominently (e.g., in red text).
  bool _hasError = false;

  /// A list of [Analyte] objects that are currently selected by the user
  /// in the [AnalyteTable]. These analytes are then added to the [GlobalState].
  List<Analyte> _selectedAnalytes = [];

  @override
  void initState() {
    super.initState();
    // Load the initial list of CRMs when the page is first initialized.
    _loadInitialData();
  }

  /// Fetches the initial list of [CrmItem]s from the [CrmService].
  ///
  /// This method is called once when the widget initializes to populate
  /// the CRM dropdown with available CRMs. It manages the loading state,
  /// error handling, and updates [_crmItems] and [_selectedCrmId].
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _crmItems = []; // Explicitly clear items at the start
      _selectedCrmId = null; // Clear previous selection
      _selectedDetail = null; // Clear previous detail
    });

    try {
      final fetchedItems = await _crmService.loadInitialData();
      final uniqueItems = fetchedItems.toSet().toList();
      uniqueItems.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _crmItems = uniqueItems;
          _initialLoadComplete = true;
          _isLoading = false; // Set loading to false here
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _handleError(e.toString());
          _isLoading = false; // Also set loading to false on error
        });
      }
    }
  }

  /// Searches for CRMs based on the provided [query], incorporating synonym search
  /// using PubChem.
  ///
  /// This method first attempts to resolve the query to a canonical compound name
  /// and its synonyms via PubChem. It then uses these terms to search the NRC
  /// repository. If PubChem lookup fails, it falls back to a direct NRC search
  /// with the original query.
  ///
  /// [query]: The search term entered by the user.
  Future<void> _searchCrm(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _selectedCrmId = null; // Clear previous selection
      _selectedDetail = null; // Clear previous detail
      _crmItems = []; // Explicitly clear items at the start
    });

    try {
      Set<String> searchTerms = {query}; // Start with the original query
      PubChemData? pubChemResult;

      try {
        // Attempt to get PubChem data for the query
        pubChemResult = await _pubChemService.getCompoundData(query);
        searchTerms.add(pubChemResult.name); // Add canonical name
        searchTerms.addAll(pubChemResult.synonyms); // Add synonyms
            } catch (e) {
        // If PubChem lookup fails (e.g., query not found in PubChem),
        // we'll just proceed with the original query for the NRC search.
        debugPrint('PubChem lookup failed for "$query": $e');
      }

      Set<CrmItem> combinedResults = {};
      bool foundAnyNrcResults = false;

      // Perform NRC search for each relevant term (original query, canonical name, synonyms)
      for (String term in searchTerms) {
        if (term.isEmpty) continue; // Skip empty terms
        try {
          final nrcResults = await _crmService.searchCrm(term);
          combinedResults.addAll(nrcResults);
          if (nrcResults.isNotEmpty) {
            foundAnyNrcResults = true;
          }
        } catch (e) {
          debugPrint('NRC search failed for term "$term": $e');
          // Continue to the next term even if one NRC search fails.
        }
      }

      // Update state after all asynchronous operations are complete
      if (mounted) {
        setState(() {
          _crmItems = combinedResults.toList();
          // Ensure _crmItems contains only unique CrmItem objects based on their ID
          _crmItems = _crmItems.toSet().toList(); // Requires CrmItem to override == and hashCode
          _crmItems.sort((a, b) => a.name.compareTo(b.name)); // Sort by name for display

          if (_crmItems.isEmpty) {
            if (pubChemResult != null) {
              _handleError('No CRMs found matching "$query" or its synonyms.', isWarning: true);
            } else {
              _handleError('No results found for "$query".', isWarning: true);
            }
          } else if (!foundAnyNrcResults && pubChemResult != null) {
            // This case means PubChem found something, but NRC didn't return any CRMs for any of the terms.
            _handleError('No CRMs found matching "$query" or its synonyms.', isWarning: true);
          }
          _isLoading = false; // Set loading to false here
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _handleError(e.toString());
          _isLoading = false; // Also set loading to false on error
        });
      }
    }
  }

  /// Fetches the detailed information ([CrmDetail]) for a selected CRM.
  ///
  /// This method is called when a user selects a CRM from the dropdown.
  /// It retrieves the full CRM details using [CrmService.loadCrmDetail]
  /// and updates the [_selectedDetail] state variable.
  ///
  /// [crmId]: The ID of the CRM for which to load details.
  Future<void> _loadCrmDetail(String crmId) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _selectedDetail = null; // Clear previous detail
    });

    try {
      // Find the CrmItem corresponding to the selected ID.
      final crmItem = _crmItems.firstWhere(
        (item) => item.id == crmId,
        orElse: () => throw Exception('CRM not found with ID: $crmId'),
      );

      final crmDetail = await _crmService.loadCrmDetail(crmItem);

      if (mounted) {
        setState(() {
          _selectedCrmId = crmId;
          _selectedDetail = crmDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _handleError('Error fetching CRM details: ${e.toString()}');
          _isLoading = false;
        });
      }
    }
  }

  /// Handles and displays error or warning messages.
  ///
  /// This method updates the [_errorMessage] and [_hasError] state variables
  /// to reflect the status of data operations.
  ///
  /// [message]: The error or warning message to display.
  /// [isWarning]: A boolean flag indicating if the message is a warning (true)
  ///   or a critical error (false). Warnings are typically displayed in orange,
  ///   errors in red.
  void _handleError(String message, {bool isWarning = false}) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _hasError = !isWarning;
      });
    }
  }

  /// Navigates to the [PropertiesPage] for the first selected analyte.
  ///
  /// This method is called when the "View Selected Properties" button is pressed.
  /// It pushes a new route to display the properties of the first analyte
  /// in the [_selectedAnalytes] list.
  void _navigateToPropertiesPage() {
    if (_selectedAnalytes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PropertiesPage(selectedAnalyte: _selectedAnalytes[0].name),
        ),
      );
    }
  }

  /// Navigates to the [SpectrumPage] for the first selected analyte.
  ///
  /// This method is called when the "View Selected Spectrum" button is pressed.
  /// It pushes a new route to display the spectrum of the first analyte
  /// in the [_selectedAnalytes] list.
  void _navigateToSpectrumPage() {
    if (_selectedAnalytes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SpectrumPage(selectedAnalyte: _selectedAnalytes[0].name),
        ),
      );
    }
  }

  /// Processes newly selected analytes by fetching their PubChem data
  /// and adding them to the [GlobalState].
  ///
  /// This method is triggered by the [AnalyteTable]'s `onSelectionChanged`
  /// callback when new analytes are selected. It uses [PubChemService]
  /// to get chemical data for these analytes and then adds them, along
  /// with their PubChem data, to the application's global state.
  ///
  /// [newlySelected]: A list of [Analyte] objects that have just been selected.
  /// [context]: The current build context, used to access the [GlobalState] via `Provider.of`.
  Future<void> _handleNewlySelectedAnalytes(
    List<Analyte> newlySelected,
    BuildContext context,
  ) async {
    // Fetch PubChemData for each newly selected analyte
    final data = await PubChemService().getPubChemData(newlySelected);
    // Add the analytes and their PubChem data to the global state
    context.read<GlobalState>().addAnalytes(newlySelected, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NRC CRM Digital Repository')),
      body: _isLoading && !_initialLoadComplete
          // Display a circular progress indicator while initial data is loading.
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Text field for searching CRMs by name.
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search CRMs',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Button to submit the search query.
                  ElevatedButton(
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchCrm(_searchController.text);
                      }
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 16),
                  // Display error or warning messages if any.
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: _hasError ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  // Conditional rendering for the dropdown or loading indicator
                  if (_isLoading && _crmItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_crmItems.isNotEmpty) // Display dropdown only if items are available
                    DropdownButtonFormField<String>(
                      value: _selectedCrmId, // Use the ID as the value
                      hint: const Text('Select a CRM'),
                      items: _crmItems.map((item) { // Iterate over CrmItem objects
                        return DropdownMenuItem<String>(
                          value: item.id, // Use item.id as the unique value
                          child: Text(item.name), // Display item.name
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) { // value is now the crmId
                          _loadCrmDetail(value);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  else if (!_isLoading && _crmItems.isEmpty && _initialLoadComplete)
                    // Display a message if no items are found after loading/searching
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          'No CRMs found. Try a different search.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Display selected CRM details if available.
                  if (_selectedDetail != null) ...[
                    Text(
                      _selectedDetail!.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    // Render HTML summary using FlutterHtml widget.
                    Html(data: _selectedDetail!.summary),
                    const SizedBox(height: 8),
                    // Display DOI with a clickable link if available.
                    if (_selectedDetail!.doi != null) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('DOI: '),
                          InkWell(
                            onTap: () async {
                              String url = _selectedDetail!.doi!;
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Text(
                              _selectedDetail!.doi!,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Display publication date if available.
                    if (_selectedDetail!.date != null)
                      Text('Publication date: ${_selectedDetail!.date}'),
                    // Table to display analytes within the selected CRM
                    // and allow users to select them.
                    AnalyteTable(
                      analytes: _selectedDetail!.analyteData,
                      onSelectionChanged: (selected) {
                        final previousSelection = _selectedAnalytes;
                        setState(() => _selectedAnalytes = selected);

                        // Calculate newly added items to fetch PubChem data only for new selections.
                        final newlySelected = selected
                            .where((item) => !previousSelection.contains(item))
                            .toList();

                        if (newlySelected.isNotEmpty) {
                          _handleNewlySelectedAnalytes(newlySelected, context);
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    // Button to navigate to the properties page for selected analytes.
                    ElevatedButton(
                      onPressed: _selectedAnalytes.isNotEmpty
                          ? _navigateToPropertiesPage
                          : null, // Button is disabled if no analytes are selected.
                      child: const Text('View Selected Properties'),
                    ),

                    const SizedBox(height: 8),
                    // Button to navigate to the spectrum page for selected analytes.
                    ElevatedButton(
                      onPressed: _selectedAnalytes.isNotEmpty
                          ? _navigateToSpectrumPage
                          : null, // Button is disabled if no analytes are selected.
                      child: const Text('View Selected Spectrum'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
