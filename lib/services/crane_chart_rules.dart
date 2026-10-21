import 'dart:convert';
import 'calculation_engine.dart';

class CraneChartRules {
  static const prefix='RIGSAFE_CHART_V1:';
  static const fields=['assetId','manufacturer','model','configuration','jib','counterweight','outriggers','partsOfLine','hookBlock','revision','source','document','page','table','verifiedBy'];
  static Map<String,dynamic>? metadata(String note){
    if(!note.startsWith(prefix))return null;
    try{final d=jsonDecode(note.substring(prefix.length));return d is Map<String,dynamic>?d:null;}catch(_){return null;}
  }
  static String? incomplete(Map<String,dynamic>? d){
    if(d==null||d['version']!=1)return 'Legacy chart has no verified configuration/source metadata.';
    for(final k in fields){if('${d[k]??''}'.trim().isEmpty)return 'Missing chart $k.';}
    if(d['verified']!=true||DateTime.tryParse('${d['verifiedAt']}')==null)return 'Each chart value and configuration must be verified against the original.';
    if((int.tryParse('${d['partsOfLine']}')??0)<1)return 'Parts of line must be a positive integer.';
    return null;
  }
  static Map<String,dynamic>? verifiedRows(List<Map<String,Object?>> rows){
    if(rows.isEmpty)return null;
    final note=rows.first['note'];
    if(note is! String || rows.any((r)=>r['note']!=note))return null;
    final meta=metadata(note);
    if(incomplete(meta)!=null)return null;
    try { validateRows([for(final row in rows)[for(final k in ['boom','radius','capacity'])(row[k] as num).toDouble()]]); } catch(_) { return null; }
    return meta;
  }
  static double? limitingCapacity(List<Map<String,Object?>> rows,{required double boom,required List<double> radii,required String configuration,required Set<String> eligibleAssetIds}){
    if(radii.length!=3)throw ArgumentError('Pick, maximum and set radii required.');
    for(final r in radii){CalculationEngine.finite(r,'Radius',positive:true);}
    if(radii[1]<radii[0]||radii[1]<radii[2])throw ArgumentError('Maximum path radius below pick/set.');
    final meta=verifiedRows(rows);
    if(meta==null||!eligibleAssetIds.contains(meta['assetId'])||meta['configuration']!=configuration)return null;
    final hits=[for(final r in radii)exactRow(rows,boom,r)];
    if(hits.any((r)=>r==null))return null;
    return hits.map((r)=>(r!['capacity'] as num).toDouble()).reduce((a,b)=>a<b?a:b);
  }
  static String encode(Map<String,Object?> data)=>prefix+jsonEncode({'version':1,...data});
  static void validateRows(List<List<double>> rows){
    if(rows.isEmpty)throw ArgumentError('At least one chart row is required.');
    final seen=<String>{};
    for(final row in rows){
      if(row.length!=3)throw ArgumentError('Each row needs boom, radius and capacity.');
      for(final v in row){CalculationEngine.finite(v,'Chart value',positive:true);}
      if(!seen.add('${row[0]}|${row[1]}'))throw ArgumentError('Duplicate boom/radius rows require correction; do not guess which capacity applies.');
    }
  }
  static Map<String,Object?>? exactRow(List<Map<String,Object?>> rows,double boom,double radius){
    CalculationEngine.finite(boom,'Boom',positive:true);CalculationEngine.finite(radius,'Radius',positive:true);
    final hits=rows.where((r)=>r['boom']==boom&&r['radius']==radius).toList();
    if(hits.length!=1)return null;
    final cap=hits.single['capacity'];if(cap is! num||!cap.isFinite||cap<=0)return null;
    return hits.single;
  }
  static String describe(String note){
    final d=metadata(note);if(d==null)return '$note\nUNVERIFIED LEGACY CHART - review original document.';
    return fields.map((k)=>'$k: ${d[k]??'unknown'}').join('\n')+'\n'+(incomplete(d)??'Source values attested; actual crane setup and final approval still require competent-person confirmation.');
  }
}
