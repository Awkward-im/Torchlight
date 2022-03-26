{$I-}
unit unitscan;

interface

uses
  sqlite3
  ,TL2Mod
  ,RGGlobal
  ;

function ScanGraph   (ams:pointer; const aname:string; amul:integer):integer;
procedure LoadDefaultGraphs(ams:pointer);


function ScanClasses  (ams:pointer):integer;
function ScanInventory(ams:pointer):integer;
function ScanItems    (ams:pointer):integer;
function ScanMobs     (ams:pointer):integer;
function ScanMovies   (ams:pointer):integer;
function ScanPets     (ams:pointer):integer;
function ScanProps    (ams:pointer):integer;
function ScanQuests   (ams:pointer):integer;
function ScanRecipes  (ams:pointer):integer;
function ScanSkills   (ams:pointer):integer;
function ScanStats    (ams:pointer):integer;
function ScanWardrobe (ams:pointer):integer;


function Prepare(const apath:string; out ams:pointer;
         aupdateall:boolean=false):boolean;
procedure Finish(ams:pointer);


implementation

uses
  awkSQLite3
  ,sysutils
  ,RGLogging
  ,RGScan
  ,rgPAK
  ,rgio.DAT
  ,rgio.Text
  ,RGDict
  ,RGNode
  ;

{$R dict.rc}

type
  PModScanner = ^TModScanner;
  TModScanner = object
    FDoUpdate:boolean;  // update data or not if it was found | CheckForMod only
    FModId   :string;   // current mod id                     | Add*ToBase, AddTheMod
    FModMask :string;   // mod id mask (optimization)         | ' '+FModId+' '
    scan     :pointer;  // PScanObj from RGScan
    db       :PSQLite3;
    FRootLen :integer;  // Root dir name length
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
{$i scan_inventory.inc}
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
//  ScanAdds    (ams);
  ScanClasses  (ams);
  ScanInventory(ams);
  ScanItems    (ams);
  ScanMobs     (ams);
  ScanMovies   (ams);
  ScanPets     (ams);
  ScanProps    (ams);
  ScanQuests   (ams);
  ScanRecipes  (ams);
  ScanSkills   (ams);
  ScanStats    (ams);
  ScanWardrobe (ams);
end;

function CreateTables(ams:pointer):boolean;
begin
  result:=CreateModTable      (ams);

  result:=CreateAddsTable     (ams);
  result:=CreateClassesTable  (ams);
  result:=CreateGraphTable    (ams);
  result:=CreateInventoryTable(ams);
  result:=CreateItemsTable    (ams);
  result:=CreateMobsTable     (ams);
  result:=CreateMoviesTable   (ams);
  result:=CreatePetsTable     (ams);
  result:=CreatePropsTable    (ams);
  result:=CreateQuestsTable   (ams);
  result:=CreateRecipesTable  (ams);
  result:=CreateSkillsTable   (ams);
  result:=CreateStatsTable    (ams);
  result:=CreateWardrobeTable (ams);
end;

function Prepare(
    const apath:string;
    out ams:pointer;
    aupdateall:boolean=false):boolean;
var
  lmod:TTL2ModInfo;
  lscan:pointer;
begin
  result:=false;
  ams:=nil;

  if (apath[Length(apath)] in ['/','\']) or DirectoryExists(apath) then
    result:=LoadModConfiguration(PChar(apath+'\MOD.DAT'),lmod)
  else if FileExists(apath) then
  begin
    result:=ReadModInfo(PChar(apath),lmod);
    RGTags.Import('RGDICT','TEXT');
  end;

  if result then
  begin
    GetMem  (ams ,SizeOf(TModScanner));
    FillChar(ams^,SizeOf(TModScanner),0);

    PModScanner(ams)^.FRootLen:=PrepareRGScan(lscan, apath, ['.DAT'], ams);
    if lscan<>nil then
    begin

      with PModScanner(ams)^ do
      begin
        scan     :=lscan;
        FDoUpdate:=aupdateall;

        result:=sqlite3_open(':memory:',@db)=SQLITE_OK;
        if result then
        begin
          if CopyFromFile(db,TL2DataBase)<>SQLITE_OK then
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

procedure Finish(ams:pointer);
begin
  if ams<>nil then
  begin
    with PModScanner(ams)^ do
    begin
      EndRGScan(scan);

      CopyToFile(db,TL2DataBase);
      sqlite3_close(db);
{
      FModId  :='';
      FModMask:='';
}
    end;
    Finalize(PModScanner(ams)^);

    FreeMem(ams);
  end;
end;

{%ENDREGION}

end.
