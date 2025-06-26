class PubChemData {
  /// The common name of the compound.
  final String name;

  /// The IUPAC (International Union of Pure and Applied Chemistry) name of the compound.
  final String iupacName;

  /// The molecular formula of the compound (e.g., "C6H6").
  final String molecularFormula;

  /// The molecular weight of the compound, if available.
  final double? molecularWeight;

  /// The SMILES (Simplified Molecular-Input Line-Entry System) string for the compound.
  final String smiles;

  /// The InChIKey (International Chemical Identifier Key) for the compound.
  final String inchiKey;

  /// The exact mass of the compound, if available.
  final double? exactMass;

  /// The Topological Polar Surface Area (TPSA) of the compound, if available.
  final double? tpsa;

  /// The logarithm of the octanol-water partition coefficient (log P or pKow), if available.
  final double? pKow;

  /// The PubChem Compound ID (CID), a unique identifier for the compound in PubChem, if available.
  final int? cid;

  /// A list of common synonyms for the compound.
  final List<String> synonyms;

  /// The URL for an image of the compound's chemical structure, if available.
  final String? imageUrl;

  /// Creates a [PubChemData] instance.
  ///
  /// [name], [iupacName], [molecularFormula], [smiles], [inchiKey], and [synonyms] are required.
  /// Other properties are optional and can be null.
  PubChemData({
    required this.name,
    required this.iupacName,
    required this.molecularFormula,
    this.molecularWeight,
    required this.smiles,
    required this.inchiKey,
    this.exactMass,
    this.tpsa,
    this.pKow,
    this.cid,
    required this.synonyms,
    this.imageUrl,
  });

  /// Factory constructor to create a [PubChemData] instance from a JSON map.
  ///
  /// It safely parses values from the JSON, handling potential nulls and
  /// type conversions for numerical fields.
  factory PubChemData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PubChemData(
      name: json['name']?.toString() ?? 'Unknown',
      iupacName: json['iupacName']?.toString() ?? 'Unknown',
      molecularFormula: json['molecularFormula']?.toString() ?? '',
      molecularWeight: parseDouble(json['molecularWeight']),
      smiles: json['smiles']?.toString() ?? '',
      inchiKey: json['inchiKey']?.toString() ?? '',
      exactMass: parseDouble(json['exactMass']),
      tpsa: parseDouble(json['tpsa']),
      pKow: parseDouble(json['pKow']),
      cid: parseInt(json['cid']),
      synonyms:
          List<String>.from(json['synonyms']?.map((x) => x.toString()) ?? []),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}