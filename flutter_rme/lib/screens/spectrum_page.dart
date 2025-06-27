import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rme/widgets/spectrum_plot.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class SpectrumPage extends StatefulWidget {
  final String selectedAnalyte;
  const SpectrumPage({super.key, required this.selectedAnalyte});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

class _SpectrumPageState extends State<SpectrumPage> {
  String? _errorMessage;
  String? _csvData;
  bool _isLoading = true;
  List<Map<String, String>> _availableSpectra = [];
  String? _selectedSpectrumUrl;
  bool _isMassSpectrum = true;

  @override
  void initState() {
    super.initState();
    _fetchSpectrumData();
  }

  Future<void> _fetchSpectrumData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _csvData = null;
    });

    try {
      final uri = Uri.parse(
        'https://nrc-digital-repository.canada.ca/eng/search/atom/?q=${widget.selectedAnalyte.replaceAll(' ', '+')}',
      );

      print('Fetching Atom feed from: $uri');

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load Atom feed');
      }

      final document = xml.XmlDocument.parse(response.body);
      _availableSpectra = _findAllDatasetUrls(document);

      if (_availableSpectra.isEmpty) {
        throw Exception('No spectral data found for ${widget.selectedAnalyte}');
      }

      // Set the first spectrum as selected by default
      _selectedSpectrumUrl = _availableSpectra.first['href'];
      _updatePlotType(_availableSpectra.first['title'] ?? '');

      await _downloadCsvData(_selectedSpectrumUrl!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCsvData(String url) async {
    setState(() {
      _isLoading = true;
      _csvData = null;
    });
    try {
      print('Downloading CSV from: $url');
      final csvResponse = await http.get(Uri.parse(url));
      if (csvResponse.statusCode != 200) {
        throw Exception('Failed to download CSV data from $url');
      }

      setState(() {
        _csvData = csvResponse.body;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error downloading CSV: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _findAllDatasetUrls(xml.XmlDocument document) {
    final List<Map<String, String>> datasets = [];
    document.findAllElements('link').forEach((link) {
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

  void _updatePlotType(String title) {
    setState(() {
      _isMassSpectrum = !title.toLowerCase().contains('nmr');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedAnalyte)),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_isLoading || _availableSpectra.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedAnalyte)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                isExpanded: true, // Allow dropdown to take available width
                value: _selectedSpectrumUrl,
                icon: const Icon(Icons.arrow_drop_down), // Explicitly set a standard dropdown icon
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSpectrumUrl = newValue;
                      final selectedTitle = _availableSpectra
                          .firstWhere((element) => element['href'] == newValue)['title'];
                      _updatePlotType(selectedTitle ?? '');
                    });
                    _downloadCsvData(newValue);
                  }
                },
                items: _availableSpectra.map<DropdownMenuItem<String>>(
                  (Map<String, String> spectrum) {
                    return DropdownMenuItem<String>(
                      value: spectrum['href'],
                      child: Text(
                        spectrum['title']!,
                        overflow: TextOverflow.ellipsis, // Handle long text
                        maxLines: 1,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
          Expanded(
            child: _csvData == null
                ? const Center(child: Text('No spectral data available for selection'))
                : SpectrumPlot(
                    csvData: _csvData!,
                    isMassSpectrum: _isMassSpectrum,
                  ),
          ),
        ],
      ),
    );
  }
}