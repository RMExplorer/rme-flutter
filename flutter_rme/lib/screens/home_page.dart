import 'package:flutter/material.dart';

/// A StatelessWidget that represents the home page of the Reference Material Explorer application.
///
/// This page provides an introduction to the application, its purpose,
/// and highlights its adherence to FAIR data principles. It displays
/// an application icon, title, a brief description of the app, and
/// details about its FAIR compliance.
class HomePage extends StatelessWidget {
  /// Constructs a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The app bar at the top of the page, displaying the application title.
      appBar: AppBar(title: const Text('Reference Material Explorer')),
      /// The main body of the page, wrapped in a [SingleChildScrollView]
      /// to allow scrolling if content exceeds screen height.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            /// Arranges children vertically in the center of the screen.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Displays the application icon from the assets folder.
                Image.asset('assets/rme_icon.png', width: 200, height: 200),
                const SizedBox(height: 24),
                /// The main title of the application.
                const Text(
                  'Reference Material Explorer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                /// A detailed description of the Reference Material Explorer application.
                const Text(
                  'The RM Explorer is an application built upon the NRC Digital Repository external Application Programming Interfaces (APIs) that allows users to visualise, analyse and display useful information about the Reference Materials produced by the National Research Council of Canada. This application relies upon and complies with FAIR data principles and showcases multiple uses of machine-readable information in digital CRM certificates.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                /// A horizontal divider to visually separate sections.
                const Divider(
                  height: 40,
                  thickness: 1,
                  color: Colors.grey,
                  indent: 15, // Left margin of the divider
                  endIndent: 15, // Right margin of the divider
                ),
                /// Heading for the FAIR Compliance section.
                const Text(
                  'FAIR Compliance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                /// Explanation of how the application adheres to FAIR data principles.
                const Text(
                  'The RM Explorer uses data from the digital certificates of reference materials and open-source compound identifiers (InChI / InChIKeys) to calculate information and present it in a user-friendly way. It also creates an integrated data structure by fetching information from external sources such as PubChem and comparing the information presented in these external sources to its calculated values.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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