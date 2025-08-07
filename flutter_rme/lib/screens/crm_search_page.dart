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
import '../widgets/all_analytes_table.dart';
import '../ui_elements/animated_loader.dart';

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

  /// A flag indicating whether a search has been initiated and is currently loading.
  bool _isSearching = false;

  /// A flag indicating whether the initial loading of CRMs has completed.
  /// Used to display a loading indicator only during the initial fetch.
  bool _initialLoadComplete = false;

  /// Stores any error message encountered during data loading or processing.
  /// This message is displayed to the user.
  String? _errorMessage;

  /// A flag indicating whether a severe error has occurred that should
  /// be displayed prominently (e.g., in red text).
  bool _hasError = false;

  // The local _selectedAnalytes state variable is no longer needed,
  // as selection is now managed by GlobalState.
  // List<Analyte> _selectedAnalytes = [];

  /// A list to hold all analytes from all fetched CRMs.
  List<Analyte> _allAnalytes = [];

  /// A flag to indicate if a search has been performed.
  bool _hasSearched = false;

  // New state variables for "Did you mean?" functionality
  String? _canonicalNameSuggestion;
  String _lastSearchQuery = ''; // Store the last query to compare
  bool _showDidYouMean = false;

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
      _allAnalytes = []; // Clear all analytes on initial load
      _hasSearched = false; // Reset search flag
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
      _isSearching = true; // Set to true when search starts
      _hasError = false;
      _errorMessage = null;
      _selectedCrmId = null; // Clear previous selection
      _selectedDetail = null; // Clear previous detail
      _crmItems = []; // Explicitly clear items at the start
      _allAnalytes = []; // Clear all analytes when starting a new search
      _hasSearched = true; // Set to true after a search is initiated
      _canonicalNameSuggestion = null; // Clear previous suggestion
      _showDidYouMean = false; // Reset "Did you mean?" flag
      _lastSearchQuery = query; // Store the current query
    });

    try {
      Set<String> searchTerms = {query}; // Start with the original query
      PubChemData? pubChemResult;
      String? actualCanonicalName; // Variable to hold the canonical name found

      try {
        // Attempt to get PubChem data for the query
        pubChemResult = await _pubChemService.getCompoundData(query);
        actualCanonicalName = pubChemResult.name; // Get the canonical name
        searchTerms.add(actualCanonicalName); // Add canonical name
        searchTerms.addAll(pubChemResult.synonyms); // Add synonyms
      } catch (e) {
        // If PubChem lookup fails (e.g., query not found in PubChem),
        // we'll just proceed with the original query for the NRC search.
        debugPrint('PubChem lookup failed for "$query": $e');
      }

      // Check if a canonical name was found and it's different from the original query
      if (actualCanonicalName != null &&
          actualCanonicalName.toLowerCase() != query.toLowerCase()) {
        _canonicalNameSuggestion = actualCanonicalName;
        _showDidYouMean = true;
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

      // Fetch details for all items to populate _allAnalytes from search results
      List<Analyte> tempAllAnalytes = [];
      for (var item in combinedResults) {
        try {
          final detail = await _crmService.loadCrmDetail(item);
          for (var analyte in detail.analyteData ?? []) {
            // Null-aware operator to prevent errors
            tempAllAnalytes.add(
              Analyte(
                name: analyte.name,
                quantity: analyte.quantity,
                value: analyte.value,
                uncertainty: analyte.uncertainty,
                unit: analyte.unit,
                type: analyte.type,
                crmName: detail.title, // Add CRM name to analyte
                materialType: detail.materialType, // Pass materialType to Analyte
              ),
            );
          }
        } catch (detailError) {
          debugPrint(
            'Failed to load detail for CRM ${item.name}: $detailError',
          );
        }
      }

      // Update state after all asynchronous operations are complete
      if (mounted) {
        setState(() {
          _crmItems = combinedResults.toList();
          // Ensure _crmItems contains only unique CrmItem objects based on their ID
          _crmItems = _crmItems
              .toSet()
              .toList(); // Requires CrmItem to override == and hashCode
          _crmItems.sort(
            (a, b) => a.name.compareTo(b.name),
          ); // Sort by name for display
          _allAnalytes =
              tempAllAnalytes; // Populate _allAnalytes here, after search

          if (_crmItems.isEmpty) {
            if (pubChemResult != null) {
              _handleError(
                'No CRMs found matching "$query" or its synonyms.',
                isWarning: true,
              );
            } else {
              _handleError('No results found for "$query".', isWarning: true);
            }
          } else if (!foundAnyNrcResults && pubChemResult != null) {
            // This case means PubChem found something, but NRC didn't return any CRMs for any of the terms.
            _handleError(
              'No CRMs found matching "$query" or its synonyms.',
              isWarning: true,
            );
          }
          _isLoading = false; // Set loading to false here
          _isSearching = false; // Set to false when search ends
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _handleError(e.toString());
          _isLoading = false; // Also set loading to false on error
          _isSearching = false; // Also set to false on error
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
    final selectedAnalytes = context.read<GlobalState>().selectedAnalytes;
    if (selectedAnalytes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PropertiesPage(selectedAnalyte: selectedAnalytes[0].name),
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
    final selectedAnalytes = context.read<GlobalState>().selectedAnalytes;
    if (selectedAnalytes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SpectrumPage(selectedAnalyte: selectedAnalytes[0].name),
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

  /// Resets the CRM search page to its initial state,
  /// clearing selected CRM details and showing the all analytes table.
  void _resetToAllAnalytes() {
    setState(() {
      _selectedCrmId = null; // Clear the selected CRM ID
      _selectedDetail = null; // Clear the detailed view
      _errorMessage = null; // Clear any error messages
      _hasError = false; // Clear error flag
      // We don't clear _selectedAnalytes here as it's now managed by GlobalState.
      // Do NOT clear _crmItems or _allAnalytes here.
      // These lists should retain the results of the last search or initial load.
    });
  }

  /// Handles the action when the "Did you mean?" suggestion is tapped.
  /// It updates the search controller with the canonical name and triggers
  /// a re-filtering of the analytes table.
  void _onDidYouMeanTapped() {
    if (_canonicalNameSuggestion != null) {
      // Create a temporary controller and set its text to the canonical name.
      // We'll pass this text directly to AllAnalytesTable.
      // The AllAnalytesTable will handle its own _searchController initialization.
      setState(() {
        _showDidYouMean = false; // Hide the suggestion after it's used
        _lastSearchQuery =
            _canonicalNameSuggestion!; // Update last search query to apply the new filter
      });
      // The AllAnalytesTable will be rebuilt with this new initialSearchText
      // when _selectedCrmId is null (meaning we're showing all analytes).
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a watch to trigger a rebuild when GlobalState.selectedAnalytes changes
    final globalState = context.watch<GlobalState>();

    return Scaffold(
      appBar: AppBar(title: const Text('NRC CRM Digital Repository')),
      body: _isLoading && !_initialLoadComplete && !_isSearching
          // Display the AnimatedLoader while initial data is loading.
          ? const Center(child: AnimatedLoader())
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
                      labelText: 'Search Analytes',
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
                  // Display "Did you mean?" suggestion
                  if (_showDidYouMean && _canonicalNameSuggestion != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Text(
                            'Did you mean: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: _onDidYouMeanTapped,
                            child: Text(
                              _canonicalNameSuggestion!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            '?',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  // Conditional rendering for the dropdown or loading indicator
                  if (_isSearching) // Show AnimatedLoader specifically for search
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: AnimatedLoader(), // Replaced CircularProgressIndicator
                      ),
                    )
                  // Display all analytes table when search results are available and no CRM is selected
                  else if (_hasSearched && _selectedCrmId == null) // Show AllAnalytesTable only if a search has been performed and no specific CRM is selected
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_allAnalytes.isNotEmpty) ...[
                          // Only show table if there are analytes
                          const SizedBox(height: 16),
                          // Use the new AllAnalytesTable widget
                          AllAnalytesTable(
                            analytes: _allAnalytes,
                            initialSearchText: _showDidYouMean &&
                                    _canonicalNameSuggestion != null
                                ? _canonicalNameSuggestion!
                                : _lastSearchQuery,
                            selectedAnalytes: globalState.selectedAnalytes,
                            onSelectionChanged: (newSelection) {
                              final previousSelection = globalState.selectedAnalytes;

                              // Find added analytes
                              final addedAnalytes = newSelection.where(
                                (a) => !previousSelection.any((b) => b.name == a.name),
                              ).toList();
                              
                              // Find removed analytes
                              final removedAnalytes = previousSelection.where(
                                (a) => !newSelection.any((b) => b.name == a.name),
                              ).toList();

                              if (addedAnalytes.isNotEmpty) {
                                _handleNewlySelectedAnalytes(addedAnalytes, context);
                              }

                              if (removedAnalytes.isNotEmpty) {
                                globalState.removeAnalytes(removedAnalytes);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_crmItems.isNotEmpty) // Only show dropdown if there are CRMs
                          DropdownButtonFormField<String>(
                            value: _selectedCrmId, // Use the ID as the value
                            hint: const Text('Select a CRM'),
                            items: _crmItems.map((item) {
                              // Iterate over CrmItem objects
                              return DropdownMenuItem<String>(
                                value: item.id, // Use item.id as the unique value
                                child: Text(item.name), // Display item.name
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                // value is now the crmId
                                _loadCrmDetail(value);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        if (_crmItems.isEmpty && _initialLoadComplete && !_isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: Text(
                                'No CRMs found. Try a different search.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                      ],
                    )
                  else if (!_hasSearched && _crmItems.isNotEmpty) // Show dropdown on initial load if no search yet and CRMs are available
                    DropdownButtonFormField<String>(
                      value: _selectedCrmId, // Use the ID as the value
                      hint: const Text('Select a CRM'),
                      items: _crmItems.map((item) {
                        // Iterate over CrmItem objects
                        return DropdownMenuItem<String>(
                          value: item.id, // Use item.id as the unique value
                          child: Text(item.name), // Display item.name
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          // value is now the crmId
                          _loadCrmDetail(value);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  else if (_selectedCrmId != null) // Display dropdown if items are available and a CRM is selected
                    DropdownButtonFormField<String>(
                      value: _selectedCrmId, // Use the ID as the value
                      hint: const Text('Select a CRM'),
                      items: _crmItems.map((item) {
                        // Iterate over CrmItem objects
                        return DropdownMenuItem<String>(
                          value: item.id, // Use item.id as the unique value
                          child: Text(item.name), // Display item.name
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          // value is now the crmId
                          _loadCrmDetail(value);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Display selected CRM details if available.
                  if (_selectedDetail != null) ...[
                    // "Back to All Analytes" button
                    ElevatedButton(
                      onPressed: _resetToAllAnalytes,
                      child: const Text('Back to All Analytes'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDetail!.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    // Render HTML summary using FlutterHtml widget.
                    Html(data: _selectedDetail!.summary),
                    const SizedBox(height: 8),
                    // Display material type of the CRM.
                    Text(
                      'Material Type: ${_selectedDetail!.materialType}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                        final previousSelection = globalState.selectedAnalytes;

                        // Calculate newly added items to fetch PubChem data only for new selections.
                        final newlySelected = selected
                            .where((item) => !previousSelection.any((a) => a.name == item.name))
                            .toList();

                        // Calculate removed items to remove them from global state
                        final removedAnalytes = previousSelection
                            .where((item) => !selected.any((a) => a.name == item.name))
                            .toList();

                        if (newlySelected.isNotEmpty) {
                          _handleNewlySelectedAnalytes(newlySelected, context);
                        }

                        if (removedAnalytes.isNotEmpty) {
                          globalState.removeAnalytes(removedAnalytes);
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    // Button to navigate to the properties page for selected analytes.
                    ElevatedButton(
                      onPressed: globalState.selectedAnalytes.isNotEmpty
                          ? _navigateToPropertiesPage
                          : null, // Button is disabled if no analytes are selected.
                      child: const Text('View Selected Properties'),
                    ),

                    const SizedBox(height: 8),
                    // Button to navigate to the spectrum page for selected analytes.
                    ElevatedButton(
                      onPressed: globalState.selectedAnalytes.isNotEmpty
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