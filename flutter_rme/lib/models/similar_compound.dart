class SimilarCompound {
  /// The PubChem compound identifier of the compound.
  final int cid;

  /// The InChIKey of the compound.
  final String inchiKey;

  /// The name of the compound.
  final String name;

  /// Creates a [SimilarCompound] instance.
  /// 
  /// All parameters are required.
  const SimilarCompound({
    required this.cid,
    required this.inchiKey,
    required this.name,
  });
}