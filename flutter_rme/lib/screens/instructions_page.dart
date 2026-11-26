import 'package:flutter/material.dart';
// import 'package:flutter_rme/ui_elements/glass_card.dart';

/// A StatelessWidget that displays instructions and information about
/// various pages within the application.
///
/// This page serves as a guide for users, explaining the functionality
/// of the 'Search Page', 'Properties Page', and 'CRM Details Page'.
class InstructionsPage extends StatelessWidget {
  /// Constructs an [InstructionsPage].
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InstructionSection(
            icon: Icons.search,
            title: 'Search Page',
            initiallyExpanded: true,
            items: [
              _Item(
                heading: 'Searching for analytes',
                body:
                    'Use the first search bar to find analytes. Analytes that match your search will appear in a table below the search bars along with the number of CRMs in the NRC repository that feature them (e.g., domoic acid, 5 CRMs).',
              ),
              _Item(
                heading: 'Viewing CRMs for an analyte',
                body:
                    'Tap the dropdown button on an analyte row to see the CRMs that feature it. Tap a CRM to open its details page.',
              ),
              _Item(
                heading: 'Searching for CRMs',
                body:
                    'Use the second search bar to search the NRC digital repository for CRMs. Matching CRMs appear in a dropdown list; tap one to open its details page.',
              ),
              _Item(
                heading: 'Filtering by analyte',
                body:
                    'If you search for an analyte before searching for a CRM, the CRM dropdown will only show CRMs that contain that analyte.',
              ),
              _Item(
                heading: 'Opening properties',
                body:
                    'Tap an analyte row to reveal a "View Properties" button in the bottom right corner of the screen. Tap it to open the analyte\'s properties page.',
              ),
            ],
          ),
          _InstructionSection(
            icon: Icons.science,
            title: 'Properties Page',
            items: [
              _Item(
                heading: 'Analyte properties',
                body:
                    'View the IUPAC name, synonyms, molecular formula, molecular weight, and other properties of the selected analyte.',
              ),
              _Item(
                heading: 'PubChem link',
                body:
                    'Tap the PubChem link to open the molecule\'s PubChem page in your external browser for more information.',
              ),
              _Item(
                heading: 'Similar compounds',
                body:
                    'Use the dropdown at the bottom of the page to view similar compounds and add them to the analyte table on the Search Page. Only compounds found in the NRC repository are listed. If none exist, you\'ll see "No similar compounds found in the repository."',
              ),
            ],
          ),
          _InstructionSection(
            icon: Icons.description,
            title: 'CRM Details Page',
            items: [
              _Item(
                heading: 'CRM information',
                body:
                    'Shows the CRM\'s name, summary, analyte table, and other information.',
              ),
              _Item(
                heading: 'How to get here',
                body:
                    'Tap a CRM from an analyte\'s dropdown list on the Search Page, or select one from the CRM search bar\'s results.',
              ),
            ],
          ),
          _InstructionSection(
            icon: Icons.policy,
            title: 'FAIR Data Principles',
            items: [
              _Item(
                heading: 'This app complies with FAIR principles',
                body:
                  'This app uses data from the NRC Digital Repository and open-source compound identifiers (InChI / InChIKey) from PubChem to retrieve information.',
              ),
            ],
          ),
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     /// The app bar at the top of the page, displaying the title "Instructions".
  //     appBar: AppBar(title: const Text('Instructions')),

  //     /// The main body of the page, wrapped in a [SingleChildScrollView]
  //     /// to allow for vertical scrolling if the content exceeds the screen height.
  //     body: SingleChildScrollView(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
  //         child: Center(
  //           /// A [Column] widget used to arrange various sections of instructions vertically.
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               GlassCard(
  //                 title: 'SEARCH PAGE',
  //                 content: Column(
  //                   children: [
  //                     const Text(
  //                       'This page allows you to search for specific analytes in the CRM database. CRMs containing the analyte will show up in the dropdown. You can select a CRM from the dropdown to view its details.',
  //                       textAlign: TextAlign.justify,
  //                     ),
  //                     const SizedBox(height: 10),
  //                     const Text(
  //                       'If the CRM has analytes listed, there will be a table below the dropdown that shows the analytes. Selecting an analyte will add it to the Polarity-MW plot page. You can view the properties and spectrum of the first selected analyte by clicking the buttons below the table.',
  //                       textAlign: TextAlign.justify,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
  //               GlassCard(
  //                 title: 'PROPERTIES PAGE',
  //                 content: const Text(
  //                   'This page display the properties of the first selected analyte. Here you can view a picture of the molecule, IUPAC name, molecular formula, molecular weight, polarity and other available data. The PubChem link will take you to the PubChem page for the molecule on an external browser, where you can find more information.',
  //                   textAlign: TextAlign.justify,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
  //               GlassCard(
  //                 title: 'SPECTRUM PAGE',
  //                 content: const Text(
  //                   'This page displays the spectrum of the first selected analyte (if it\'s available). The spectrum is displayed as a graph, with the x-axis representing the retention time and the y-axis representing the intensity. Below the graph there is a table with the peaks detected in the spectrum, which can be sorted by retention time or intensity.',
  //                   textAlign: TextAlign.justify,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
  //               GlassCard(
  //                 title: 'POLARITY-MW PLOT PAGE',
  //                 content: const Text(
  //                   'This page displays the Polarity-MW plot for the selected analytes. Analytes from multiple CRMs can be selected, and the plot will update accordingly. Below the plot there is a table, where the analytes can be sorted by polarity, molecular weight, or name.',
  //                   textAlign: TextAlign.justify,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               const Divider(height: 40, thickness: 1, color: Colors.grey, indent: 15, endIndent: 15),
  //               GlassCard(
  //                 title: 'FAIR DATA PRINCIPLES',
  //                 content: const Text(
  //                   'This app uses data from the NRC Digital Repository and open-source compound identifiers (InChI / InChIKey) from PubChem to retrieve information.',
  //                   textAlign: TextAlign.justify,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class _Item {
  final String heading;
  final String body;
  const _Item({required this.heading, required this.body});
}

class _InstructionSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_Item> items;
  final bool initiallyExpanded;

  const _InstructionSection({
    required this.icon,
    required this.title,
    required this.items,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.heading,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(item.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
