class CrmItem {
  /// The title of the Certified Reference Material (CRM). This might be a more
  /// descriptive name for display purposes.
  final String title;

  /// The primary name or identifier of the CRM. This is often used for
  /// selection or search.
  final String name;

  /// A brief summary or description of the CRM.
  final String summary;

  /// A unique identifier for the CRM.
  final String id;

  /// Creates a [CrmItem] instance.
  ///
  /// All parameters are required and define the essential properties of a CRM item.
  CrmItem({
    required this.title,
    required this.name,
    required this.summary,
    required this.id,
  });
}