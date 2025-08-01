import 'package:flutter/material.dart';
import 'package:flutter_rme/ui_elements/glass_card.dart';

/// A StatelessWidget that displays instructions and information about
/// various pages within the application.
///
/// This page serves as a guide for users, explaining the functionality
/// of the 'Search Page', 'Properties Page', 'Spectrum Page', and
/// 'Polarity-MW Plot Page'.
class InstructionsPage extends StatelessWidget {
  /// Constructs an [InstructionsPage].
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The app bar at the top of the page, displaying the title "Instructions".
      appBar: AppBar(title: const Text('Instructions')),

      /// The main body of the page, wrapped in a [SingleChildScrollView]
      /// to allow for vertical scrolling if the content exceeds the screen height.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            /// A [Column] widget used to arrange various sections of instructions vertically.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCard(
                  title: 'SEARCH PAGE',
                  content: Column(
                    children: [
                      const Text(
                        'This page allows you to search for specific analytes in the CRM database. CRMs containing the analyte will show up in the dropdown. You can select a CRM from the dropdown to view its details.',
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'If the CRM has analytes listed, there will be a table below the dropdown that shows the analytes. Selecting an analyte will add it to the Polarity-MW plot page. You can view the properties and spectrum of the first selected analyte by clicking the buttons below the table.',
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
                GlassCard(
                  title: 'PROPERTIES PAGE',
                  content: const Text(
                    'This page display the properties of the first selected analyte. Here you can view a picture of the molecule, IUPAC name, molecular formula, molecular weight, polarity and other available data. The PubChem link will take you to the PubChem page for the molecule on an external browser, where you can find more information.',
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
                GlassCard(
                  title: 'SPECTRUM PAGE',
                  content: const Text(
                    'This page displays the spectrum of the first selected analyte (if it\'s available). The spectrum is displayed as a graph, with the x-axis representing the retention time and the y-axis representing the intensity. Below the graph there is a table with the peaks detected in the spectrum, which can be sorted by retention time or intensity.',
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
                GlassCard(
                  title: 'POLARITY-MW PLOT PAGE',
                  content: const Text(
                    'This page displays the Polarity-MW plot for the selected analytes. Analytes from multiple CRMs can be selected, and the plot will update accordingly. Below the plot there is a table, where the analytes can be sorted by polarity, molecular weight, or name.',
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
                GlassCard(
                  title: 'FAIR DATA PRINCIPLES',
                  content: const Text(
                    'This app uses data from the NRC Digital Repository and open-source compound identifiers (InChI / InChIKey) from PubChem to retrieve information.',
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
