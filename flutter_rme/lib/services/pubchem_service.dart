import 'dart:convert';
import 'package:flutter_rme/models/analyte.dart';
import 'package:http/http.dart' as http;
import '../models/pubchem_data.dart';

/// A service class for interacting with the PubChem PUG REST API.
class PubChemService {
  static const String _baseUrl = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug';

  /// Fetches chemical compound data from PubChem based on an identifier (e.g., name).
  ///
  /// This method first attempts to retrieve the Compound ID (CID) for the given identifier.
  /// Once the CID is obtained, it fetches various properties of the compound
  /// such as IUPAC name, molecular formula, molecular weight, SMILES, InChIKey,
  /// exact mass, TPSA, and XLogP. It also fetches a list of synonyms.
  ///
  /// The [identifier] is pre-processed to handle special characters and formatting
  /// before being used in the PubChem API request.
  ///
  /// [identifier] The name or other identifier of the chemical compound.
  /// Throws an [Exception] if fetching compound data fails at any stage.
  /// Returns a [Future] that resolves to a [PubChemData] object containing the compound's information.
  Future<PubChemData> getCompoundData(String identifier) async {
    // Parse the identifier to work with pubchem by replacing special characters and formatting.
    identifier = identifier.replaceAll('Δ', 'delta');
    identifier = identifier.replaceAllMapped(RegExp(r'[⁰¹²³⁴⁵⁶⁷⁸⁹]'), (match) {
      const superscripts = {
        '⁰': '0',
        '¹': '1',
        '²': '2',
        '³': '3',
        '⁴': '4',
        '⁵': '5',
        '⁶': '6',
        '⁷': '7',
        '⁸': '8',
        '⁹': '9',
      };
      return superscripts[match.group(0)] ?? '';
    });
    identifier = identifier.replaceAll(RegExp(r'\s*\([^)]*\)$'), '');
    identifier = identifier.replaceAll(' ', '-').toLowerCase();

    try {
      // First try to get CID (Compound ID)
      final cidResponse = await http.get(
        Uri.parse('$_baseUrl/compound/name/$identifier/cids/JSON'),
      );

      final cidJson = jsonDecode(cidResponse.body);
      final cid = cidJson['IdentifierList']['CID'][0];

      // Get compound properties
      final propertiesResponse = await http.get(
        Uri.parse(
          '$_baseUrl/compound/cid/$cid/property/'
          'Title,IUPACName,MolecularFormula,MolecularWeight,InChIKey,SMILES,'
          'ExactMass,TPSA,XLogP/JSON',
        ),
      );

      final propertiesJson = jsonDecode(propertiesResponse.body);
      final properties = propertiesJson['PropertyTable']['Properties'][0];

      // Helper function to parse numeric values safely from dynamic types.
      double? parseNumeric(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) {
          return double.tryParse(value);
        }
        return null;
      }

      // Get synonyms
      List<String> synonyms = [];
      try {
        final synonymsResponse = await http.get(
          Uri.parse('$_baseUrl/compound/cid/$cid/synonyms/JSON'),
        );
        final synonymsJson = jsonDecode(synonymsResponse.body);
        synonyms = List<String>.from(
          synonymsJson['InformationList']['Information'][0]['Synonym'] ?? [],
        ).take(10).toList(); // Take first 10 synonyms for brevity.
      } catch (e) {
        print('Error fetching synonyms: $e');
      }

      return PubChemData(
        name: properties['Title'] ?? identifier,
        iupacName: properties['IUPACName'] ?? identifier,
        molecularFormula: properties['MolecularFormula'] ?? '',
        molecularWeight: parseNumeric(properties['MolecularWeight']),
        smiles: properties['SMILES'] ?? '',
        inchiKey: properties['InChIKey'] ?? '',
        exactMass: parseNumeric(properties['ExactMass']),
        tpsa: parseNumeric(properties['TPSA']),
        pKow: properties['XLogP'] != null
            ? parseNumeric(-(properties['XLogP'] as num))
            : null,
        cid: cid,
        synonyms: synonyms.isNotEmpty ? synonyms : [identifier],
        imageUrl: '$_baseUrl/compound/cid/$cid/PNG',
      );
    } catch (e) {
      throw Exception('Failed to fetch compound data: $e');
    }
  }

  /// Fetches PubChem data for a list of [Analyte] objects in parallel.
  ///
  /// This method iterates through the provided list of [analytes],
  /// calls [getCompoundData] for each analyte's name, and waits for all
  /// the asynchronous operations to complete using `Future.wait`.
  ///
  /// [analytes] A list of [Analyte] objects for which to fetch PubChem data.
  /// Returns a [Future] that resolves to a [List] of [PubChemData] objects.
  Future<List<PubChemData>> getPubChemData(List<Analyte> analytes) {
    // Map each analyte to a Future<PubChemData>, then wait for them all to complete.
    return Future.wait(analytes.map((a) => getCompoundData(a.name)));
  }
}