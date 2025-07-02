import 'package:equatable/equatable.dart';

/// Represents a Certified Reference Material (CRM) item with basic information.
///
/// This class is used to model the entries fetched from the NRC Digital Repository
/// search results. It includes details like title, name, summary, and a unique ID.
///
/// [Equatable] is used to simplify equality comparisons for objects of this class.
/// By extending [Equatable], we automatically get `==` and `hashCode` overrides
/// based on the properties defined in `props`. This ensures that two `CrmItem`
/// instances are considered equal if all their properties are equal, which is
/// crucial for correct behavior when using sets or comparing lists of these objects.
class CrmItem extends Equatable {
  final String title;
  final String name;
  final String summary;
  final String id;

  /// Constructs a [CrmItem] with the given details.
  const CrmItem({
    required this.title,
    required this.name,
    required this.summary,
    required this.id,
  });

  /// The list of properties that define the equality of two [CrmItem] objects.
  ///
  /// This is used by [Equatable] to generate the `==` operator and `hashCode`.
  @override
  List<Object?> get props => [id, name, title, summary];
}
