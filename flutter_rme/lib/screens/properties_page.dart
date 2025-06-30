import 'package:flutter/material.dart';
import 'package:flutter_rme/models/pubchem_data.dart';
import 'package:flutter_rme/services/pubchem_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A StatefulWidget that displays detailed properties of a selected chemical analyte.
///
/// This page fetches and presents information such as IUPAC name, molecular formula,
/// molecular weight, SMILES, InChIKey, exact mass, TPSA, pKow, and a link to PubChem,
/// for a given analyte.
class PropertiesPage extends StatefulWidget {
  /// The name of the chemical analyte to display properties for.
  final String selectedAnalyte;

  /// Creates a [PropertiesPage] with the given [selectedAnalyte].
  const PropertiesPage({super.key, required this.selectedAnalyte});

  @override
  _PropertiesPageState createState() => _PropertiesPageState();
}

/// The state for [PropertiesPage].
class _PropertiesPageState extends State<PropertiesPage> {
  // A Future that will hold the PubChemData for the selected compound.
  late Future<PubChemData> _compoundData;
  // An instance of PubChemService to fetch compound data.
  final PubChemService _pubChemService = PubChemService();

  @override
  void initState() {
    super.initState();
    // Initialize _compoundData by calling the PubChemService to get data for the selected analyte.
    _compoundData = _pubChemService.getCompoundData(widget.selectedAnalyte);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compound Properties')),
      // FutureBuilder is used to asynchronously load compound data.
      body: FutureBuilder<PubChemData>(
        future: _compoundData,
        builder: (context, snapshot) {
          // Display a circular progress indicator while data is loading.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Display an error message if data fetching fails.
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            // Display a message if no data is available for the selected analyte.
            return const Center(child: Text('No data available'));
          }

          // Once data is successfully loaded, extract it from the snapshot.
          final data = snapshot.data!;

          // Build the UI to display the compound properties.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the name of the analyte.
                Center(
                  child: Text(
                    'Showing Information on: ${data.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 20),

                // Display the molecule image if available.
                if (data.imageUrl != null)
                  Center(
                    child: Image.network(
                      data.imageUrl!,
                      width: MediaQuery.of(context).size.width * 0.9,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 20),

                // Property sections for various compound details.
                _buildPropertySection(
                  context,
                  title: 'IUPAC Name',
                  value: data.iupacName,
                ),

                _buildPropertySection(
                  context,
                  title: 'Synonyms',
                  value: data.synonyms.join(', '),
                  tooltip: 'Top synonyms for this compound from PubChem',
                ),

                _buildPropertySection(
                  context,
                  title: 'Molecular Formula',
                  value: data.molecularFormula,
                ),

                _buildPropertySection(
                  context,
                  title: 'Molecular Weight',
                  value: '${data.molecularWeight} g/mol',
                ),

                _buildPropertySection(
                  context,
                  title: 'SMILES',
                  value: data.smiles,
                ),

                _buildPropertySection(
                  context,
                  title: 'InChIKey',
                  value: data.inchiKey,
                ),

                _buildPropertySection(
                  context,
                  title: 'Exact Mass',
                  value: '${data.exactMass} Da',
                  tooltip:
                      'Based on the most abundant isotope of each individual element',
                ),

                // Display Topological Polar Surface Area if available.
                if (data.tpsa != null)
                  _buildPropertySection(
                    context,
                    title: 'Topological Polar Surface Area',
                    value: '${data.tpsa} Å²',
                  ),

                // Display pKow if available.
                if (data.pKow != null)
                  _buildPropertySection(
                    context,
                    title: 'pKow',
                    value: data.pKow.toString(),
                  ),

                // Display PubChem link if CID is available.
                if (data.cid != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PubChem',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          // Make the URL clickable.
                          child: Text(
                            'https://pubchem.ncbi.nlm.nih.gov/compound/${data.cid}',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTap: () async {
                            // Launch the URL in an external application.
                            await launchUrl(
                              Uri.parse(
                                'https://pubchem.ncbi.nlm.nih.gov/compound/${data.cid}',
                              ),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// A helper method to build a consistent property section with a title, value, and optional tooltip.
  ///
  /// [context] The BuildContext.
  /// [title] The title of the property (e.g., 'Molecular Weight').
  /// [value] The actual value of the property.
  /// [tooltip] An optional tooltip message to display on an info icon.
  Widget _buildPropertySection(
    BuildContext context, {
    required String title,
    required String value,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Display a tooltip icon if a tooltip message is provided.
              if (tooltip != null) ...[
                const SizedBox(width: 5),
                Tooltip(
                  message: tooltip,
                  child: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ],
          ),
          // Use SelectableText to allow users to copy the property value.
          SelectableText(value),
        ],
      ),
    );
  }
}