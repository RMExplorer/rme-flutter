import 'package:flutter/material.dart';
import 'package:flutter_rme/models/pubchem_data.dart';
import '../models/analyte.dart';

class GlobalState with ChangeNotifier {
  final List<Analyte> _selectedAnalytes = [];
  List<Analyte> get selectedAnalytes => List.unmodifiable(_selectedAnalytes);

  final List<PubChemData> _pubChemData = [];
  List<PubChemData> get pubChemData => List.unmodifiable(_pubChemData);

  // Added for Theme Management
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); // Notify listeners that the theme has changed
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
  // End Theme Management Additions

  void addAnalytes(List<Analyte> newAnalytes, List<PubChemData> newData) {
    bool changed = false;

    for (int i = 0; i < newAnalytes.length; i++) {
      final analyte = newAnalytes[i];
      // New logic to check if any part of the name is already contained
      // This logic is flawed. Let's fix it to check for exact name match
      // instead of a partial name match, as a partial match may not
      // be the same analyte. The original code's check below is what is being
      // replaced:
      //
      // bool nameAlreadyContained = _selectedAnalytes.any(
      //   (existingAnalyte) =>
      //       existingAnalyte.name.contains(analyte.name) ||
      //       analyte.name.contains(existingAnalyte.name),
      // );

      // Updated logic: Check for an exact match of the analyte name.
      bool nameAlreadyContained = _selectedAnalytes.any(
        (existingAnalyte) => existingAnalyte.name.toLowerCase() == analyte.name.toLowerCase(),
      );

      if (!nameAlreadyContained) {
        _selectedAnalytes.add(analyte);
        if (i < newData.length) {
          _pubChemData.add(newData[i]);
        }
        changed = true;
        debugPrint('Added analyte: ${analyte.name}');
      }
    }

    if (changed) {
      debugPrint('Total analytes after add: ${_selectedAnalytes.length}');
      notifyListeners();
    }
  }

  void removeAnalytes(List<Analyte> analytesToRemove) {
    bool changed = false;
    for (var analyte in analytesToRemove) {
      final index = _selectedAnalytes.indexOf(analyte);
      if (index != -1) {
        _selectedAnalytes.removeAt(index);
        _pubChemData.removeAt(index);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void removeAnalyteByName(String name) {
    _selectedAnalytes.removeWhere((a) => a.name == name);
    _pubChemData.removeWhere((d) => d.name == name);
    notifyListeners();
  }

  void clearAllAnalytes() {
    _selectedAnalytes.clear();
    _pubChemData.clear();
    notifyListeners();
  }
}