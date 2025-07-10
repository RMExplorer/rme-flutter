import 'analyte.dart';

/// Represents the detailed information of a Certified Reference Material (CRM).
///
/// This class holds various attributes that describe a specific CRM,
/// including its title, a summary, optional DOI and date, and a list of
/// associated analytes.
class CrmDetail {
  /// The title or name of the Certified Reference Material.
  final String title;

  /// A brief summary or description of the CRM.
  final String summary;

  /// The material type of the CRM
  final String materialType;

  /// The Digital Object Identifier (DOI) for the CRM, if available.
  final String? doi;

  /// The publication or release date of the CRM, if available.
  final String? date;

  /// A list of [Analyte] objects associated with this CRM,
  /// representing the chemical components and their properties.
  final List<Analyte>? analyteData;

  /// Creates a [CrmDetail] instance.
  ///
  /// [title], [summary] and [materialType] are required. [doi], [date], and [analyteData]
  /// are optional.
  CrmDetail({
    required this.title,
    required this.summary,
    required this.materialType,
    this.doi,
    this.date,
    this.analyteData,
  });
}