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

  /// A list of [CrmItem] objects representing the CRMs fetched
  /// either initially or via a search query.
  List<CrmItem> _crmItems = [];

  /// A list of CRM names extracted from [_crmItems], used to populate
  /// the dropdown menu for CRM selection.
  List<String> _crmNames = [];

  /// The name of the currently selected CRM from the dropdown.
  String? _selectedCrm;

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
  /// error handling, and updates [_crmItems] and [_crmNames].
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      _crmItems = await _crmService.loadInitialData();
      _crmNames = _crmItems.map((item) => item.name).toSet().toList()..sort();

      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      _handleError(e.toString());
    } finally {
      // Ensure the loading state is reset regardless of success or failure.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Searches for CRMs based on the provided [query].
  ///
  /// This method is triggered when the user enters text in the search field
  /// and presses the "Submit" button. It updates the [_crmItems] and
  /// [_crmNames] with the search results. It also handles loading states
  /// and displays messages if no results are found or if an error occurs.
  Future<void> _searchCrm(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _selectedCrm = null; // Clear previous selection
      _selectedDetail = null; // Clear previous detail
    });

    try {
      _crmItems = await _crmService.searchCrm(query);
      _crmNames = _crmItems.map((item) => item.name).toSet().toList()..sort();

      if (_crmNames.isEmpty) {
        _handleError('No results found', isWarning: true);
      }
    } catch (e) {
      _handleError(e.toString());
    } finally {
      // Ensure the loading state is reset regardless of success or failure.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetches the detailed information ([CrmDetail]) for a selected CRM.
  ///
  /// This method is called when a user selects a CRM name from the dropdown.
  /// It retrieves the full CRM details using [CrmService.loadCrmDetail]
  /// and updates the [_selectedDetail] state variable.
  ///
  /// [crmName]: The name of the CRM for which to load details.
  Future<void> _loadCrmDetail(String crmName) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _selectedDetail = null; // Clear previous detail
    });

    try {
      // Find the CrmItem corresponding to the selected name.
      final crmItem = _crmItems.firstWhere(
        (item) => item.name == crmName,
        orElse: () => throw Exception('CRM not found'),
      );

      final crmDetail = await _crmService.loadCrmDetail(crmItem);

      setState(() {
        _selectedCrm = crmName;
        _selectedDetail = crmDetail;
      });
    } catch (e) {
      _handleError('Error fetching CRM details: ${e.toString()}');
    } finally {
      // Ensure the loading state is reset regardless of success or failure.
      if (mounted) {
        setState(() {
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
                  // Dropdown to select a CRM from the loaded or searched list.
                  if (_crmNames.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedCrm,
                      hint: const Text('Select a CRM'),
                      items: _crmNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value != 'No results') {
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