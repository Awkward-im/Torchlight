uses unitscan,rgscan,sysutils;

var
  db:pointer;

function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lms:pointer;
begin
  result:=1;
  if (UpCase(ExtractFileExt(aname))='.MOD') or
     (UpCase(ExtractFileExt(aname))='.PAK') then
  begin
    Prepare(db,ParamStr(1)+'\'+adir+'/'+aname,lms);
  end
  else if (UpCase(aname)='MOD.DAT') then
  begin
    Prepare(db,ParamStr(1)+'\'+adir,lms);
  end
  else
    exit(0);

  if lms<>nil then
  begin
    ScanAll(lms);
    Finish(lms);
  end
  else
    exit(0);

end;

begin
{$if declared(UseHeapTrace)}
  SetHeapTraceOutput('Trace.log');
  HaltOnError := true;
{$endif}

  RGOpenBase(db);
  MakeRGScan(ParamStr(1),'',['.PAK','.MOD','.DAT'],nil,nil,@DoCheck);
  RGCloseBase(db);
{  
  Prepare(ParamStr(1),ms);
//  ScanMovies(ms);
//  ScanRecipes(ms);
//  ScanQuests(ms);
//  ScanStats(ms);
//  ScanWardrobe(ms);
//  ScanSkills(ms);
//  ScanProps(ms);
//  ScanPets(ms);
//  ScanMobs(ms);

  ScanClasses(ms);
//  LoadDefaultGraphs(ms);
//  ScanItems(ms);
//  ScanInventory(ms);

  Finish(ms);
}
end.
