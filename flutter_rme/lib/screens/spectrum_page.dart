import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rme/widgets/spectrum_plot.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// A StatefulWidget that displays spectral data for a selected analyte.
///
/// This page fetches spectrum data from a remote repository (NRC Digital Repository),
/// parses an Atom feed to find available CSV data, and then displays the spectrum
/// using a `SpectrumPlot` widget. It also allows users to select different
/// available spectra for the analyte.
class SpectrumPage extends StatefulWidget {
  /// The name of the chemical analyte for which to display spectra.
  final String selectedAnalyte;

  /// Creates a [SpectrumPage] with the given [selectedAnalyte].
  const SpectrumPage({super.key, required this.selectedAnalyte});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

/// The state for [SpectrumPage].
class _SpectrumPageState extends State<SpectrumPage> {
  String? _errorMessage; // Stores any error messages encountered during data fetching.
  String? _csvData; // Stores the raw CSV data of the selected spectrum.
  bool _isLoading = true; // Indicates whether data is currently being loaded.
  List<Map<String, String>> _availableSpectra = []; // List of available spectra (title and href).
  String? _selectedSpectrumUrl; // The URL of the currently selected spectrum.
  bool _isMassSpectrum = true; // Determines if the current spectrum is a mass spectrum (vs. NMR).

  @override
  void initState() {
    super.initState();
    _fetchSpectrumData(); // Initiate fetching spectrum data when the widget is initialized.
  }

  /// Fetches the Atom feed from the NRC Digital Repository to find available spectra
  /// for the [selectedAnalyte].
  ///
  /// This method updates the loading state, handles errors, and populates
  /// `_availableSpectra`. It then defaults to selecting and downloading the first
  /// available spectrum.
  Future<void> _fetchSpectrumData() async {
    setState(() {
      _isLoading = true; // Set loading state to true.
      _errorMessage = null; // Clear any previous error messages.
      _csvData = null; // Clear any previous CSV data.
    });

    try {
      // Construct the URI for the Atom feed search.
      final uri = Uri.parse(
        'https://nrc-digital-repository.canada.ca/eng/search/atom/?q=${widget.selectedAnalyte.replaceAll(' ', '+')}',
      );

      print('Fetching Atom feed from: $uri');

      // Make an HTTP GET request to the Atom feed.
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load Atom feed'); // Throw an error if the request was unsuccessful.
      }

      // Parse the XML response body as an Atom feed document.
      final document = xml.XmlDocument.parse(response.body);
      _availableSpectra = _findAllDatasetUrls(document); // Find all relevant dataset URLs within the feed.

      if (_availableSpectra.isEmpty) {
        throw Exception('No spectral data found for ${widget.selectedAnalyte}'); // No spectra found.
      }

      // Set the first spectrum as selected by default.
      _selectedSpectrumUrl = _availableSpectra.first['href'];
      _updatePlotType(_availableSpectra.first['title'] ?? ''); // Determine plot type based on the title.

      // Download the CSV data for the initially selected spectrum.
      await _downloadCsvData(_selectedSpectrumUrl!);
    } catch (e) {
      // Catch and display any errors during the fetching process.
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false; // Set loading to false as an error occurred.
      });
    }
  }

  /// Downloads the CSV data from the given [url].
  ///
  /// This method updates the loading state, handles errors, and populates
  /// `_csvData` with the downloaded content.
  Future<void> _downloadCsvData(String url) async {
    setState(() {
      _isLoading = true; // Set loading state to true.
      _csvData = null; // Clear any previous CSV data.
    });
    try {
      print('Downloading CSV from: $url');
      // Make an HTTP GET request to download the CSV data.
      final csvResponse = await http.get(Uri.parse(url));
      if (csvResponse.statusCode != 200) {
        throw Exception('Failed to download CSV data from $url'); // Throw an error if the download fails.
      }

      // Update state with the downloaded CSV data.
      setState(() {
        _csvData = csvResponse.body;
        _isLoading = false; // Set loading to false as data is downloaded.
      });
    } catch (e) {
      // Catch and display any errors during the CSV download process.
      setState(() {
        _errorMessage = 'Error downloading CSV: ${e.toString()}';
        _isLoading = false; // Set loading to false as an error occurred.
      });
    }
  }

  /// Parses an XML [document] (Atom feed) to find links to spectral CSV datasets.
  ///
  /// It looks for `<link>` elements with `type="text/csv"`, a `title` containing
  /// "spectrum", and an `href` attribute.
  /// Returns a list of maps, where each map contains the 'title' and 'href' of a spectrum.
  List<Map<String, String>> _findAllDatasetUrls(xml.XmlDocument document) {
    final List<Map<String, String>> datasets = [];
    document.findAllElements('link').forEach((link) {
      // Check if the link is for a CSV spectrum file.
      if (link.getAttribute('type') == 'text/csv' &&
          link.getAttribute('title') != null &&
          link.getAttribute('href') != null &&
          link.getAttribute('title')!.toLowerCase().contains('spectrum')) {
        datasets.add({
          'title': link.getAttribute('title')!,
          'href': link.getAttribute('href')!,
        });
      }
    });
    return datasets;
  }

  /// Updates the `_isMassSpectrum` flag based on the spectrum's [title].
  /// If the title contains 'nmr' (case-insensitive), it's considered an NMR spectrum.
  void _updatePlotType(String title) {
    setState(() {
      _isMassSpectrum = !title.toLowerCase().contains('nmr');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Display an error message if one exists.
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedAnalyte)),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // Display a loading indicator if data is being fetched or no spectra are available yet.
    if (_isLoading || _availableSpectra.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedAnalyte)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Main UI for displaying the spectrum page.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedAnalyte),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true, // Allow dropdown to take available width.
                value: _selectedSpectrumUrl, // The currently selected spectrum's URL.
                icon: const Icon(Icons.arrow_drop_down), // Explicitly set a standard dropdown icon.
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSpectrumUrl = newValue; // Update the selected spectrum URL.
                      // Find the title of the newly selected spectrum to update plot type.
                      final selectedTitle = _availableSpectra
                          .firstWhere((element) => element['href'] == newValue)['title'];
                      _updatePlotType(selectedTitle ?? ''); // Update plot type based on title.
                    });
                    _downloadCsvData(newValue); // Download CSV data for the new selection.
                  }
                },
                // Generate dropdown menu items from the list of available spectra.
                items: _availableSpectra.map<DropdownMenuItem<String>>(
                  (Map<String, String> spectrum) {
                    return DropdownMenuItem<String>(
                      value: spectrum['href'], // The value of the dropdown item is the URL.
                      child: Text(
                        spectrum['title']!, // The displayed text is the spectrum title.
                        overflow: TextOverflow.ellipsis, // Handle long text by truncating.
                        maxLines: 1, // Restrict to a single line.
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
          Expanded(
            // Display SpectrumPlot if CSV data is available, otherwise show a message.
            child: _csvData == null
                ? const Center(child: Text('No spectral data available for selection'))
                : SpectrumPlot(
                    csvData: _csvData!, // Pass the CSV data to the SpectrumPlot widget.
                    isMassSpectrum: _isMassSpectrum, // Pass the plot type.
                  ),
          ),
        ],
      ),
    );
  }
}