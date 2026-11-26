import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/similar_compound.dart';

/// Finds PubChem-similar compounds that also exist in the NRC repository.
class SimilarCompoundsService {
  static const _pug = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug';
  static const _repo =
      'https://nrc-digital-repository.canada.ca/eng/search/atom/';

  final http.Client _client;
  SimilarCompoundsService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<SimilarCompound>> findInRepository({
    required int cid,
    required String ownInchiKey,
    int maxRecords = 100,
    int concurrency = 10,
  }) async {
    // 1. Similar CIDs (excluding the compound itself)
    final cids = await _similarCids(cid, maxRecords);
    if (cids.isEmpty) return [];

    // 2. CID -> InChIKey in one request, dropping the current compound
    final keys = await _inchiKeys(cids);
    keys.removeWhere((_, key) => key == ownInchiKey);

    // 3. Repository checks, in parallel batches
    final entries = keys.entries.toList();
    final hits = <MapEntry<int, String>>[];
    for (var i = 0; i < entries.length; i += concurrency) {
      final batch = entries.skip(i).take(concurrency).toList();
      final found = await Future.wait(batch.map((e) => _inRepository(e.value)));
      for (var j = 0; j < batch.length; j++) {
        if (found[j]) hits.add(batch[j]);
      }
    }
    if (hits.isEmpty) return [];

    // 4. First synonym (name) for every hit, in one request
    final names = await _firstSynonyms(hits.map((e) => e.key).toList());

    return [
      for (final h in hits)
        if (names[h.key] != null)
          SimilarCompound(cid: h.key, inchiKey: h.value, name: names[h.key]!),
    ];
  }

  Future<List<int>> _similarCids(int cid, int maxRecords) async {
    final res = await _client.get(Uri.parse(
        '$_pug/compound/fastsimilarity_2d/cid/$cid/cids/JSON'
        '?MaxRecords=$maxRecords'));
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body)['IdentifierList']?['CID'] as List?;
    return (list ?? []).cast<int>().where((c) => c != cid).toList();
  }

  Future<Map<int, String>> _inchiKeys(List<int> cids) async {
    final res = await _client.get(Uri.parse(
        '$_pug/compound/cid/${cids.join(",")}/property/InChIKey/JSON'));
    if (res.statusCode != 200) return {};
    final props = jsonDecode(res.body)['PropertyTable']['Properties'] as List;
    return {
      for (final p in props)
        if (p['InChIKey'] != null) p['CID'] as int: p['InChIKey'] as String,
    };
  }

  Future<bool> _inRepository(String inchiKey) async {
    try {
      final res = await _client.get(Uri.parse(
          '$_repo?q=&q=${Uri.encodeQueryComponent(inchiKey)}+&q=&y1=&y2='
          '&ps=10&s=sc&av=1'));
      if (res.statusCode != 200) return false;
      return XmlDocument.parse(res.body)
          .findAllElements('id')
          .any((e) => e.innerText.contains('urn:uuid:'));
    } catch (_) {
      return false; // a failed check counts as "not in repository"
    }
  }

  Future<Map<int, String>> _firstSynonyms(List<int> cids) async {
    try {
      final res = await _client.get(
          Uri.parse('$_pug/compound/cid/${cids.join(",")}/synonyms/JSON'));
      if (res.statusCode != 200) return {};
      final info =
          jsonDecode(res.body)['InformationList']['Information'] as List;
      return {
        for (final i in info)
          if ((i['Synonym'] as List?)?.isNotEmpty ?? false)
            i['CID'] as int: (i['Synonym'] as List).first as String,
      };
    } catch (_) {
      return {};
    }
  }
}