import 'package:flutter/material.dart';
import 'package:flutter_rme/screens/home_page.dart';
import 'package:flutter_rme/screens/instructions_page.dart';
import 'package:flutter_rme/screens/polarity_mw_plot_page.dart';
import 'screens/crm_search_page.dart';
import 'dart:io'; // Import for HttpOverrides and HttpClient.
import 'package:flutter_rme/global_state.dart';
import 'package:provider/provider.dart';

/// Custom HttpOverrides to allow connections to servers with self-signed certificates.
/// This is typically used in development or controlled environments where
/// certificates might not be globally recognized.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Call the superclass method to create the default HttpClient.
    return super.createHttpClient(context)
      // Override badCertificateCallback to always return true,
      // effectively trusting all certificates (including self-signed ones).
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// The entry point of the Flutter application.
void main() {
  // Set the global HttpOverrides to MyHttpOverrides to handle self-signed certificates.
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    // ChangeNotifierProvider is used to provide an instance of GlobalState
    // to its descendants in the widget tree. GlobalState manages the application's
    // shared state.
    ChangeNotifierProvider(
      create: (context) => GlobalState(), // Create an instance of GlobalState.
      child: const NrcCrmApp(), // The root widget of the application.
    ),
  );
}

/// The main application widget.
///
/// This is a StatelessWidget as it doesn't manage any mutable state itself,
/// but rather defines the application's visual structure and theme.
class NrcCrmApp extends StatelessWidget {
  /// Creates an [NrcCrmApp] instance.
  const NrcCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NRC CRM Digital Repository', // The title of the application shown in the task switcher.
      theme: ThemeData(
        primarySwatch: Colors.blue, // Defines the primary color palette for the app.
        // Determines how the UI should adapt to different screen densities.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainNavigationWrapper(), // The initial screen of the application.
    );
  }
}

/// A StatefulWidget that acts as a wrapper for handling main application navigation.
///
/// It uses a [BottomNavigationBar] to switch between different main pages
/// of the application.
class MainNavigationWrapper extends StatefulWidget {
  /// Creates a [MainNavigationWrapper] instance.
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

/// The state for [MainNavigationWrapper].
class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0; // The index of the currently selected tab in the BottomNavigationBar.

  /// A list of widgets (pages) that can be displayed in the [IndexedStack].
  /// Each page corresponds to a tab in the [BottomNavigationBar].
  final List<Widget> _pages = [
    const HomePage(),
    const CrmSearchPage(),
    const PolarityMwPlotPage(),
    const InstructionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack only builds the child corresponding to the current index,
      // preserving the state of inactive children.
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurple, // Color of the icon and label for the selected item.
        unselectedItemColor: Colors.grey, // Color for unselected items.
        currentIndex: _currentIndex, // The index of the currently active item.
        onTap: (index) {
          // Callback when a tab is tapped. Updates the current index to switch pages.
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          // Defines the items (tabs) in the bottom navigation bar.
          BottomNavigationBarItem(icon: Icon(Icons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Polarity MW Plot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Instructions',
          ),
        ],
      ),
    );
  }
}