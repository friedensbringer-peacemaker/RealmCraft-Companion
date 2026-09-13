import Foundation

@main struct OreModelsTests {
    static func check(_ value:Bool,_ message:String) { if !value {fatalError(message)} }
    static func rejects(_ action:() throws -> Void) {do {try action();fatalError("Expected rejection")} catch {}}
    static func main() throws {
        let resourcePath = CommandLine.arguments.dropFirst().first ?? "Resources"
        let resources=URL(fileURLWithPath:resourcePath)
        let modern=try OreReference.load(resources.appendingPathComponent("OreReference.json"))
        let legacy=try OreReference.load(resources.appendingPathComponent("OreReferenceLegacy.json"))
        check(modern.entries.count==11 && legacy.entries.count==11,"catalog completeness")
        let gold=modern.entries.first{$0.id=="gold"}!
        let batch=gold.batches.first{$0.id=="ore_gold"}!
        check(abs((-64...32).reduce(0.0){$0+batch.weight(at:$1)}-4)<1e-9,"discrete distribution mass")
        check(batch.weight(at:-16)>batch.weight(at:0),"gold mode")
        let mapping=OreHeightMapping()
        check(mapping.map(-64,dimension:"o")==0 && mapping.map(319,dimension:"o")==255,"mapping anchors")
        check(mapping.map(16,dimension:"n")==16,"Nether never receives Overworld shift")
        check(OreHeightMapping(mode:"offset",offset:-500).band(batch,dimension:"o")==nil,"outside never clamped to fake floor peak")
        check(OreHeightMapping(legacy:true).map(15,dimension:"o")==15,"legacy identity")
        var p=OrePlan();p.x = -1;p.y=10;p.z=5;p.length=20;p.direction="-x";p.width=2
        try p.validate();check(p.bounds == [-20,-1,10,11,5,6] && p.volume==80,"negative tunnel geometry")
        var q=p;q.x = -21;check(!p.overlaps(q),"adjacent independent volumes")
        q.x = -20;check(p.overlaps(q),"one-block overlap detected")
        q=p;q.height=256;rejects{try q.validate()}
        p.biome="forest";p.gameVersion="synthetic-1"
        let levels=[OreLevel(y:5,blocks:100,nonAir:10,unknown:0,ores:["gold":2]),OreLevel(y:8,blocks:100,nonAir:100,unknown:0,ores:["gold":2]),OreLevel(y:9,blocks:100,nonAir:100,unknown:0,ores:["gold":0])]
        let ranks=OreRanking.topThree(levels,ore:"gold",nonAirOnly:false)
        check(ranks.count==2 && ranks[0].tiedHeights==[5,8],"ties and no fake zero-find ranks")
        check(OreRanking.topThree(levels,ore:"emerald",nonAirOnly:false).isEmpty,"no observed rank")
        check(OreLayerNavigation.next(current:8,available:[5,8,12],direction:1)==12,"normal layer navigation moves through all available heights")
        check(OreLayerNavigation.next(current:8,available:[5,12],direction:1)==12 && OreLayerNavigation.next(current:12,available:[5,12],direction:1)==5,"interesting-only navigation filters and wraps")
        check(OreLayerNavigation.next(current:5,available:[],direction:1)==nil,"empty filter has no synthetic target")
        var a=OreTrial(world:"synthetic-world",saveID:"snapshot-after",beforeSaveID:nil,plan:p,tested:80,counts:["gold":4],method:"manual-blocks",accepted:true,evidenceFile:nil,chestID:nil)
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:dir)}
        try OreJournal.save(a,directory:dir)
        var b=a;b.id=UUID().uuidString;rejects{try OreJournal.save(b,directory:dir)}
        b.plan.x = -21;b.tested=40;b.counts=["gold":0];try OreJournal.save(b,directory:dir)
        var revision=a;revision.id=UUID().uuidString;revision.supersedes=a.id;revision.counts=["gold":8];try OreJournal.save(revision,directory:dir)
        let loaded=try OreJournal.load(dir);check(loaded.count==2,"immutable revisions")
        let summary=OreTrialSummary.make(loaded,ore:"gold")[0]
        check(summary.runs==2 && summary.hits==8 && summary.tested==120 && abs(summary.probability-8.0/120)<1e-10,"weighted aggregation keeps zero trials")
        a.tested=3;rejects{try a.validate()}
        let old=ChestRecord(id:"o:0,10,0",dimension:"o",x:0,y:10,z:0,file:"o.0,0",items:[.init(slot:1,itemID:3157,quantity:10,extraData:false)],readable:true,error:"")
        let new=ChestRecord(id:old.id,dimension:"o",x:0,y:10,z:0,file:"o.0,0",items:[.init(slot:1,itemID:3157,quantity:7,extraData:false)],readable:true,error:"")
        check(try OreJournal.delta(before:old,after:new)==["3157":-3],"negative chest delta preserved")
        let spatial=OreSpatial(encoding:"u16le-yzx-v1",data:Data([31,0,32,0,255,255,0,0,155,0,0,0]))
        let region=[-2,0,10,10,5,6]
        check(spatial.cell(x:-2,y:10,z:5,bounds:region)==31,"little endian negative coordinate origin")
        check(spatial.cell(x:-1,y:10,z:6,bounds:region)==155,"Z then X axis order")
        check(spatial.cell(x:0,y:10,z:5,bounds:region)==nil,"missing sentinel is not air")
        check(spatial.cell(x:-2,y:10,z:6,bounds:region)==0,"air is an observed zero block ID")
        check(spatial.cell(x:1,y:10,z:5,bounds:region)==nil,"outside region cannot alias next row")
        check(spatial.connectedCount(x:-2,y:10,z:5,bounds:region,blockIDs:[31,32])==2,"four-neighbor cluster joins ore variants")
        check(spatial.connectedCount(x:-2,y:10,z:5,bounds:region,blockIDs:[31,155])==1,"diagonal cells do not connect")
        let areas=[OreArea(x0:-16,x1:-1,z0:0,z1:15,blocks:256,materials:["gold":2]),OreArea(x0:0,x1:15,z0:0,z1:15,blocks:256,materials:["gold":5]),OreArea(x0:16,x1:31,z0:0,z1:15,blocks:256,materials:["gold":3])]
        let grouped=OreArea.grouped(areas,size:64)
        check(grouped.count==2 && grouped.first(where:{$0.x0==0})?.materials["gold"]==8,"floor grouping at negative boundary")
        check(grouped.reduce(0){$0+$1.blocks}==768,"area denominator conserves coverage")
        let sparse=[OreArea(x0:0,x1:15,z0:0,z1:15,blocks:256,materials:["gold":2]),OreArea(x0:32,x1:47,z0:0,z1:15,blocks:256,materials:["gold":3])]
        let bounded=OreArea.grouped(sparse,size:64,bounds:[0,63,0,0,0,63])
        check(bounded.count==1 && bounded[0].x0==0 && bounded[0].x1==63 && bounded[0].z1==63,"group retains full clipped tile around missing chunks")
        check(bounded[0].blocks==512 && bounded[0].materials["gold"]==5,"missing chunks do not inflate aggregate denominator")
        print("Ore model tests passed: references, mappings, geometry, journal revisions, overlap rejection, weighted rates and chest deltas")
    }
}
