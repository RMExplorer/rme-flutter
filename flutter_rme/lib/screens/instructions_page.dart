import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructions')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Search Page',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This page allows you to search for specific analytes in the CRM database. CRMs containing the analyte will show up in the dropdown. You can select a CRM from the dropdown to view its details.\n\nIf the CRM has analytes listed, there will be a table below the dropdown that shows the analytes. Selecting an analyte will add it to the Polarity-MW plot page. You can view the properties and spectrum of the first selected analyte by clicking the buttons below the table.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey,
                  indent: 15, // Left margin
                  endIndent: 15, // Right margin
                ),
                
                const Text(
                  'Properties Page',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This page display the properties of the first selected analyte. Here you can view a picture of the molecule, IUPAC name, molecular formula, molecular weight, polarity and other available data. The PubChem link will take you to the PubChem page for the molecule on an external browser, where you can find more information.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey,
                  indent: 15, // Left margin
                  endIndent: 15, // Right margin
                ),

                const Text(
                  'Spectrum Page',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This page displays the spectrum of the first selected analyte (if it\'s available). The spectrum is displayed as a graph, with the x-axis representing the retention time and the y-axis representing the intensity. Below the graph there is a table with the peaks detected in the spectrum, which can be sorted by retention time or intensity.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey,
                  indent: 15, // Left margin
                  endIndent: 15, // Right margin
                ),

                const Text(
                  'Polarity-MW Plot Page',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This page displays the Polarity-MW plot for the selected analytes. Analytes from multiple CRMs can be selected, and the plot will update accordingly. Below the plot there is a table, where the analytes can be sorted by polarity, molecular weight, or name.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey,
                  indent: 15, // Left margin
                  endIndent: 15, // Right margin
                ),

                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
