import 'package:flutter/material.dart';
import 'package:flutter_rme/global_state.dart'; // Import GlobalState
import 'package:provider/provider.dart'; // Import provider
import '../ui_elements/animated_gradient_widget.dart'; // Ensure this path is correct

/// A StatelessWidget that represents the home page of the Reference Material Explorer application.
///
/// This page provides an introduction to the application, its purpose,
/// and highlights its adherence to FAIR data principles. It displays
/// an application title, a brief description of the app, and
/// details about its FAIR compliance.
class HomePage extends StatefulWidget {
  /// Constructs a [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the current theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold( // Scaffold is necessary for a page to have a background
      // The body of the home page, which contains the main content.
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
                      // Adjust border color based on theme
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.0, // Thin border
                    ),
                    borderRadius: BorderRadius.circular(8.0), // Slightly rounded corners
                  ),
                  /// Arranges children vertically.
                  /// [mainAxisAlignment: MainAxisAlignment.center] centers children vertically within the column.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centers the column's children vertically
                    children: [
                      // Toggle Switch for Dark Mode
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        value: isDarkMode, // The current value of the switch
                        onChanged: (bool value) {
                          // Toggle the theme using GlobalState
                          Provider.of<GlobalState>(context, listen: false).toggleTheme();
                        },
                        secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                      ),
                      const SizedBox(height: 24.0), // Spacing between elements

                      // The animated "uiverse" text, now imported from its own file
                      AnimatedUiverseText(controller: _controller),
                      const SizedBox(height: 24.0), // Spacing between elements

                      /// A detailed description of the Reference Material Explorer application.
                      Text(
                        'This is an application built upon the NRC Digital Repository external Application Programming Interfaces (APIs) that allows users to visualise, analyse and display useful information about the Reference Materials produced by the National Research Council of Canada. This application relies upon and complies with FAIR data principles and showcases multiple uses of machine-readable information in digital CRM certificates.',
                        textAlign: TextAlign.justify, // Justifies the paragraph text
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          // Adjust text color based on theme
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
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