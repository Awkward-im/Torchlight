{$I-}
unit unitscan;

interface

uses
  sqlite3
  ,TL2Mod
  ,RGGlobal
  ;

function ScanMovies  (ams:pointer):integer;
function ScanGraph   (ams:pointer; const aname:string; amul:integer):integer;
procedure LoadDefaultGraphs(ams:pointer);


function ScanWardrobe(ams:pointer):integer;
function ScanPets    (ams:pointer):integer;
function ScanQuests  (ams:pointer):integer;
function ScanMobs    (ams:pointer):integer;
function ScanItems   (ams:pointer):integer;
function ScanProps   (ams:pointer):integer;
function ScanRecipes (ams:pointer):integer;
function ScanStats   (ams:pointer):integer;
function ScanSkills  (ams:pointer):integer;
function ScanClasses (ams:pointer):integer;


function PrepareDir(const apath:string; out aptr:pointer;
         aupdateall:boolean=false):boolean;
function PreparePAK(const afile:string; out aptr:pointer;
         aupdateall:boolean=false):boolean;
procedure Finish(aptr:pointer);


implementation

uses
  awkSQLite3
  ,sysutils
  ,RGLogging
  ,RGScan
  ,rgPAK
  ,rgio.DAT
  ,rgio.Text
  ,RGNode
  ;

type
  PModScanner = ^TModScanner;
  TModScanner = object
    FDoUpdate:boolean;  // update data or not if it was found | CheckForMod only
    FModId   :string;   // current mod id                     | Add*ToBase, AddTheMod
    FModMask :string;   // mod id mask (optimization)         | ' '+FModId+' '
    scan     :pointer;  // PScanObj from RGScan
    db       :PSQLite3;
  end;

const
  h_NAME        = 6688229;
  h_DISPLAYNAME = 2200927350;
  h_DESCRIPTION = 330554530;
  h_BASEFILE    = 3799132101;
  h_UNIT_GUID   = 3990071814;
  h_UNITTYPE    = 392914174;
  h_ICON        = 6653358;


const
  GameRoot = 'G:\Games\Torchlight 2\';

type
  tScanProc = procedure (aptr:pointer; fname:PChar);


function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

procedure LoadFile(ams:pointer; const aname:string; out anode:pointer);
var
  lbuf:pointer;
begin
  if GetRGScan(PModScanner(ams)^.scan,aname,lbuf)>0 then
  begin
    anode:=ParseTextMem(lbuf);
    if anode=nil then
      anode:=ParseDatMem(lbuf);
    
    FreeMem(lbuf);
  end
  else
    anode:=nil;
end;

{$i scan_mod.inc}

{$i scan_adds.inc}
{$i scan_classes.inc}
{$i scan_items.inc}
{$i scan_mobs.inc}
{$i scan_movies.inc}
{$i scan_pet.inc}
{$i scan_props.inc}
{$i scan_recipes.inc}
{$i scan_quest.inc}
{$i scan_skills.inc}
{$i scan_stat.inc}
{$i scan_wardrobe.inc}

{%REGION Base}

procedure ScanAll(ams:pointer);
begin
  ScanClasses (ams);
  ScanSkills  (ams);
  ScanItems   (ams);
  ScanMobs    (ams);
  ScanPets    (ams);
  ScanQuests  (ams);
  ScanStats   (ams);
  ScanRecipes (ams);
  ScanProps   (ams);
  ScanWardrobe(ams);
  ScanMovies  (ams);
  ScanAdds    (ams);
end;

function CreateTables(ams:pointer):boolean;
begin
  result:=CreateModTable     (ams);

  result:=CreateAddsTable    (ams);
  result:=CreateClassesTable (ams);
  result:=CreateItemsTable   (ams);
  result:=CreateMobsTable    (ams);
  result:=CreateMoviesTable  (ams);
  result:=CreatePetsTable    (ams);
  result:=CreatePropsTable   (ams);
  result:=CreateQuestsTable  (ams);
  result:=CreateRecipesTable (ams);
  result:=CreateSkillsTable  (ams);
  result:=CreateStatsTable   (ams);
  result:=CreateWardrobeTable(ams);
end;
{
function Prepare(
    ams:pointer;
    const lmod:TTL2ModInfo;
    aupdateall:boolean=false):boolean;
var
  i:integer;
begin
  with PModScanner(ams)^ do
  begin
    FDoUpdate:=aupdateall;

    result:=sqlite3_open(':memory:',@db)=SQLITE_OK;
    if result then
    begin
      i:=CopyFromFile(db,'tl2db2.db');
      if i<>SQLITE_OK then
      begin
        result:=CreateTables(ams);
      end;
      if result then AddTheMod(ams,lmod);
    end;
  end;
end;
}

function PrepareDir(
    const apath:string;
    out ams:pointer;
    aupdateall:boolean=false):boolean;
var
  lmod:TTL2ModInfo;
  lscan:pointer;
begin
  result:=false;
  ams:=nil;

  if (apath[Length(apath)] in ['/','\']) or IsDirectoryExists(apath)
  if LoadModConfiguration(PChar(apath+'\MOD.DAT'),lmod) then
  begin
    GetMem  (ams ,SizeOf(TModScanner));
    FillChar(ams^,SizeOf(TModScanner),0);

    PrepareRGScan(lscan, apath, ['.DAT'], aptr);
    if lscan<>nil then
    begin

      with PModScanner(ams)^ do
      begin
        scan     :=lscan;
        FDoUpdate:=aupdateall;

        result:=sqlite3_open(':memory:',@db)=SQLITE_OK;
        if result then
        begin
          if CopyFromFile(db,RGDBName)<>SQLITE_OK then
            result:=CreateTables(ams);
          if result then AddTheMod(ams,lmod);
        end;
      end;

    end;
    ClearModInfo(lmod);
    if not result then
    begin
      EndRGScan(lscan);
      FreeMem(ams);
      ams:=nil;
    end;
  end;
end;


function PreparePAK(
    const afile:string;
    out aptr:pointer;
    aupdateall:boolean=false):boolean; //??
var
  lmod:TTL2ModInfo;
  lptr:pointer;
begin
  result:=false;
  aptr:=nil;

  if ReadModInfo(PChar(afile),lmod) then
  begin
    GetMem  (aptr ,SizeOf(TModScanner));
    FillChar(aptr^,SizeOf(TModScanner),0);

    PrepareRGScan(lptr, afile, ['.DAT'], aptr);
    if lptr<>nil then
    begin
      PModScanner(aptr)^.scan:=lptr;
      result:=Prepare(aptr,lmod,aupdateall);
    end;

    ClearModInfo(lmod);
    if not result then
    begin
      EndRGScan(PModScanner(aptr)^.scan);
      FreeMem(aptr);
      aptr:=nil;
    end;
  end;

end;

procedure Finish(aptr:pointer);
begin
  if aptr<>nil then
  begin
    with PModScanner(aptr)^ do
    begin
      EndRGScan(scan);

      CopyToFile(db,'tl2db2.db');
      sqlite3_close(db);
    end;

    FreeMem(aptr);
  end;
end;

{%ENDREGION}

end.
