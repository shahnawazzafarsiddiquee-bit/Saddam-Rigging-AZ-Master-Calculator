part of 'rigging_pro.dart';

class CraneFinderScreen extends StatefulWidget {
  const CraneFinderScreen({super.key});
  @override
  State<CraneFinderScreen> createState()=>_CraneFinderScreenState();
}
class _CraneFinderScreenState extends State<CraneFinderScreen>{
  final fields=<String,TextEditingController>{};
  bool setupVerified=false,busy=false;
  int revision=0;
  List<_R> out=[];
  TextEditingController c(String key)=>fields.putIfAbsent(key,TextEditingController.new);
  double number(String key){final v=double.tryParse(c(key).text.trim().replaceAll(',','.'));if(v==null||!v.isFinite)throw ArgumentError('$key requires a finite value.');return v;}
  @override
  void dispose(){for(final v in fields.values){v.dispose();}super.dispose();}
  Widget field(String key,{String? unit})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c(key),decoration:InputDecoration(labelText:key,suffixText:unit,border:const OutlineInputBorder()),keyboardType:unit==null?TextInputType.text:const TextInputType.numberWithOptions(decimal:true),onChanged:(_)=>setState((){out=[];setupVerified=false;revision++;})));
  Future<void> find()async{
    final request=++revision;
    setState(()=>busy=true);
    try{
      final payload=number('Payload'),accessories=number('All rigging accessories'),block=number('Hook block');
      final gross=CalculationEngine.grossLoadKg(payload*1000,[accessories*1000,block*1000]);
      final radii=[number('Pick radius'),number('Maximum path radius'),number('Set radius')];
      for(final r in radii){CalculationEngine.finite(r,'Radius',positive:true);}
      if(radii[1]<radii[0]||radii[1]<radii[2])throw ArgumentError('Maximum path radius cannot be below pick/set radius.');
      final boom=number('Required exact boom length');CalculationEngine.finite(boom,'Boom length',positive:true);
      if(!setupVerified)throw ArgumentError('Confirm field radius and the required manufacturer configuration before requesting recommendations.');
      for(final k in ['Required configuration','Pick location','Set location']){if(c(k).text.trim().isEmpty)throw ArgumentError('$k required.');}
      final configuration=c('Required configuration').text.trim();
      final eligible={for(final a in await LiftEquipmentService.eligible())if(a.type=='Crane')a.equipmentId:a};
      final results=<_R>[_R('Gross hook load: ${_f(gross/1000)} t. Recommendations only; no lifting authorization.',2)];
      var found=0;
      for(final name in await ProDb.cranes()){
        final rows=await ProDb.allRows(name);if(rows.isEmpty)continue;
        final capacity=CraneChartRules.limitingCapacity(rows,boom:boom,radii:radii,configuration:configuration,eligibleAssetIds:eligible.keys.toSet());
        if(capacity==null)continue;
        final meta=CraneChartRules.verifiedRows(rows)!;
        final check=CalculationEngine.craneUtilization(grossKg:gross,capacityKg:capacity*1000,chartSource:'${meta['source']} revision ${meta['revision']}',configurationVerified:true);
        if(check.status==CheckStatus.notAcceptable)continue;
        found++;results.add(_R('${meta['assetId']} | $name | boom ${_f(boom)} m | limiting capacity ${_f(capacity)} t | utilization ${_f(check.values['utilizationPercent']!)}%\n${meta['configuration']} | chart revision ${meta['revision']} | page ${meta['page']} table ${meta['table']}',2));
      }
      if(found==0)results.add(const _R('No eligible exact-match recommendation. Check registered crane inspection/certificate, verified chart metadata, configuration and all three radii. Missing data is not proof that a lift is possible.',2));
      if(mounted&&request==revision)setState(()=>out=results);
    }catch(e){if(mounted&&request==revision)setState(()=>out=[_R(e.toString(),3)]);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>_page('Crane Finder (auto)',[
    const Text('Enter actual weights; no default rigging weight or universal utilization threshold is assumed.'),
    field('Payload',unit:'t'),field('All rigging accessories',unit:'t'),field('Hook block',unit:'t'),
    const Text('Include every sling, shackle, beam, chain block and accessory. Explicitly enter zero only if absent.'),
    field('Pick radius',unit:'m'),field('Maximum path radius',unit:'m'),field('Set radius',unit:'m'),field('Required exact boom length',unit:'m'),
    field('Required configuration'),field('Pick location'),field('Set location'),
    CheckboxListTile(value:setupVerified,onChanged:(v)=>setState((){setupVerified=v??false;out=[];revision++;}),title:const Text('Field radii and exact crane configuration checked; competent-person final selection is still required')),
    ElevatedButton(onPressed:busy?null:find,child:const Text('Crane dhundo')),_results(out),
    _note('Only current registered crane assets with valid inspection/certificate and verified matching charts are recommended. No interpolation or next-radius assumption. Review deductions, height/clearance, full load path, parts of line and actual setup separately.'),_note(_disclaimer)
  ]);
}
