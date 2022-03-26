uses unitscan,rgscan,sysutils;

var
  ms:pointer;
{
function DoProcess(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
begin
end;
}
function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lms:pointer;
begin
  result:=1;
  if (UpCase(ExtractFileExt(aname))='.MOD') then
  begin
    Prepare(adir+'/'+aname,lms);
  end
  else if (UpCase(aname)='MOD.DAT') then
  begin
    Prepare(adir,lms);
  end
  else
    exit(0);

  ScanClasses(lms);
  Finish(lms);
end;


begin
  MakeRGScan(ParamStr(1),'',['.MOD'],nil{@DoProcess},nil{param},@DoCheck);
  
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
