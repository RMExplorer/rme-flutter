import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import for ThemeMode
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
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
      if (!_selectedAnalytes.any((a) => a.name == analyte.name)) {
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
    for (var analyte in analytesToRemove) {
      _selectedAnalytes.removeWhere((a) => a.name == analyte.name);
      _pubChemData.removeWhere((d) => d.name == analyte.name); // Match by name or ID
    }
    notifyListeners();
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