import 'package:flutter/material.dart';

/// A StatelessWidget that represents the home page of the Reference Material Explorer application.
///
/// This page provides an introduction to the application, its purpose,
/// and highlights its adherence to FAIR data principles. It displays
/// an application title, a brief description of the app, and
/// details about its FAIR compliance.
class HomePage extends StatelessWidget {
  /// Constructs a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// The app bar at the top of the page, displaying the application title.
      appBar: AppBar(
        title: const Text(
          'Reference Material Explorer',
          style: TextStyle(fontWeight: FontWeight.bold), // Modernize app bar title
        ),
        centerTitle: true, // Center the title in the app bar
        elevation: 0,
        backgroundColor: Colors.transparent, // Make app bar background transparent for a cleaner look
        foregroundColor: Colors.black, // Set app bar text color
      ),

      /// The body of the home page, which contains the main content.
      body: Expanded(
        child: SingleChildScrollView(
          /// [Center] widget here ensures the content inside it is centered vertically
          /// within the available space provided by [Expanded].
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Max width for content
                child: Container(
                  padding: const EdgeInsets.all(24.0), // Padding inside the framed box
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!, // Subtle border color
                      width: 1.0, // Thin border
                    ),
                    borderRadius: BorderRadius.circular(8.0), // Slightly rounded corners
                  ),
                  /// Arranges children vertically.
                  /// [mainAxisAlignment: MainAxisAlignment.center] centers children vertically within the column.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centers the column's children vertically
                    children: [

                      /// A detailed description of the Reference Material Explorer application.
                      const Text(
                        'This is an application built upon the NRC Digital Repository external Application Programming Interfaces (APIs) that allows users to visualise, analyse and display useful information about the Reference Materials produced by the National Research Council of Canada. This application relies upon and complies with FAIR data principles and showcases multiple uses of machine-readable information in digital CRM certificates.',
                        textAlign: TextAlign.justify, // Justifies the paragraph text
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}