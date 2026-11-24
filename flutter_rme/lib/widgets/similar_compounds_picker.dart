import 'package:flutter/material.dart';
import '../models/similar_compound.dart';
import '../services/similar_compounds_service.dart';

class SimilarCompoundsPicker extends StatefulWidget {
  final int cid;
  final String inchiKey;

  /// InChIKeys already in the results; these entries are shown but disabled.
  final Set<String> existingInchiKeys;

  final ValueChanged<SimilarCompound> onAdd;

  const SimilarCompoundsPicker({
    super.key,
    required this.cid,
    required this.inchiKey,
    required this.onAdd,
    this.existingInchiKeys = const {},
  });

  @override
  State<SimilarCompoundsPicker> createState() => _SimilarCompoundsPickerState();
}

class _SimilarCompoundsPickerState extends State<SimilarCompoundsPicker> {
  final _service = SimilarCompoundsService();
  late Future<List<SimilarCompound>> _similar;
  SimilarCompound? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _similar = _service.findInRepository(
      cid: widget.cid,
      ownInchiKey: widget.inchiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SimilarCompound>>(
      future: _similar,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Flexible(child: Text('Searching for similar compounds…')),
            ]),
          );
        }

        final items = snap.data ?? [];
        if (snap.hasError || items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No similar compounds found in the repository.'),
          );
        }

        final menuWidth =
            (MediaQuery.of(context).size.width - 32).clamp(200.0, 320.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Text('Similar Compounds',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 5),
                Tooltip(
                  message:
                      'Compounds similar to this one that are in our repository. '
                      'Pick one to add it to your search results. Compounds '
                      'already in your results are not selectable.',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ]),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownMenu<SimilarCompound>(
                    width: menuWidth,
                    hintText: 'Select a compound',
                    enableFilter: true,
                    onSelected: (c) => setState(() => _selected = c),
                    dropdownMenuEntries: [
                      for (final c in items)
                        DropdownMenuEntry(
                          value: c,
                          label: c.name,
                          enabled:
                              !widget.existingInchiKeys.contains(c.inchiKey),
                        ),
                    ],
                  ),
                  FilledButton.tonal(
                    onPressed: _selected == null
                        ? null
                        : () => widget.onAdd(_selected!),
                    child: const Text('Add Compound'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}