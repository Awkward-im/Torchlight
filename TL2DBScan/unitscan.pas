{$I-}
{TODO: Check current dir/mod data version (Prepare) and DB version (RGOpenBase)}
unit unitscan;

interface

uses
  sqlite3dyn
  ,RGMod
  ,RGGlobal
  ;

{not necessary to call them manually}
// amul is scale (which value must be multiplied to get integer with required precision)
function ScanGraph   (ams:pointer; const aname:string; amul:integer):integer;
procedure LoadDefaultGraphs(ams:pointer);

{scanning type}
function ScanPath(adb:PSQLite3; const apath:string):integer;

procedure ScanAll(ams:pointer);

function ScanUnitTypes(ams:pointer):integer;
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

function ScanAdds(ams:pointer):integer;

{main single mod scanning}
// prepare SINGLE mod file/unpacked directory
function Prepare(
         adb:PSQLite3;
         const apath:string;
         out ams:pointer;
         aupdateall:boolean=false;
         aver:integer=verUnk):boolean;

procedure Finish(ams:pointer);

{Load DB to memory/save back to disk}
function RGOpenBase (out adb:PSQLite3; const fname:string=TL2DataBase; createas:integer=verTL2):boolean;
function RGSaveBase (    adb:PSQLite3; const fname:string=TL2DataBase):integer;
function RGCloseBase(var adb:PSQLite3; const fname:string=''):boolean;


implementation

uses
  sysutils
  ,Logging
  ,rgdb
  ,RGScan
  ,rgPAK
  ,rgio.DAT
  ,rgio.Text
  ,RGDict
  ,RGNode
  ;

{$R ..\TL2Lib\dicttag.rc}

type
  PModScanner = ^TModScanner;
  TModScanner = object
    FDoUpdate:boolean;  // update data or not if it was found | CheckForMod only
    FModId   :string;   // current mod id                     | Add*ToBase, AddTheMod
    FModMask :string;   // mod id mask (optimization)         | ' '+FModId+' '
    scan     :pointer;  // PScanObj from RGScan
    db       :PSQLite3;
    gamever  :integer;
    FRootLen :integer;  // Root dir name length
  end;
type
  PScanDir = ^TScanDir;
  TScanDir = record
    db  :PSQLite3;
    path:string;
  end;
{
const
  h_NAME        = 6688229;
  h_DISPLAYNAME = 2200927350;
  h_DESCRIPTION = 330554530;
  h_BASEFILE    = 3799132101;
  h_UNIT_GUID   = 3990071814;
  h_UNITTYPE    = 392914174;
  h_ICON        = 6653358;
}

//!! not used atm: Return node name index in list
type
  TNameList = array of PWideChar;

function GetNameIdx(anode:pointer; const alist:TNameList):integer;
var
  lname:PWideChar;
  i:integer;
begin
  lname:=GetNodeName(anode);
  for i:=0 to High(alist) do
    if CompareWide(lname,alist[i])=0 then exit(i);
  result:=-1;
end;


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

function IsBase(const aclass, fname:string):boolean;
var
  lname:string;
  lpos:integer;
begin
  // check by class name
  lpos:=Length(aclass)-3;
  if lpos>0 then
  begin
    if ((aclass[lpos  ]='b') or (aclass[lpos  ]='B')) and
       ((aclass[lpos+1]='a') or (aclass[lpos+1]='A')) and
       ((aclass[lpos+2]='s') or (aclass[lpos+2]='S')) and
       ((aclass[lpos+3]='e') or (aclass[lpos+3]='E')) then
      exit(true);
  end;
  // check by file name
  if fname<>'' then
  begin
    lname:=ExtractNameOnly(fname);
    lpos:=Length(lname)-3;
    if lpos>0 then
    begin
    if ((lname[lpos  ]='b') or (lname[lpos  ]='B')) and
       ((lname[lpos+1]='a') or (lname[lpos+1]='A')) and
       ((lname[lpos+2]='s') or (lname[lpos+2]='S')) and
       ((lname[lpos+3]='e') or (lname[lpos+3]='E')) then
      exit(true);
    end;
  end;
  result:=false;
end;

{$i scan_mod.inc}

{$i scan_adds.inc}
{$i scan_unittypes.inc}
{$i scan_inventory.inc}
{$i scan_wardrobe.inc}
{$i scan_u_classes.inc}
{$i scan_u_items.inc}
{$i scan_u_pet.inc}
{$i scan_u_mobs.inc}
{$i scan_u_props.inc}
{$i scan_movies.inc}
{$i scan_recipes.inc}
{$i scan_quest.inc}
{$i scan_skills.inc}
{$i scan_stat.inc}

{%REGION Scan single mod}

procedure ScanAll(ams:pointer);
begin
  LoadDefaultGraphs(ams);
  ScanAdds     (ams);
  ScanUnitTypes(ams);
  ScanInventory(ams);
  ScanClasses  (ams);
  ScanItems    (ams);
  ScanMobs     (ams);
  ScanPets     (ams);
  ScanProps    (ams);
  ScanQuests   (ams);
  ScanRecipes  (ams);
  ScanSkills   (ams);
  ScanStats    (ams);
  ScanWardrobe (ams);
  ScanMovies   (ams);
end;


function Prepare(
    adb:PSQLite3;
    const apath:string;
    out ams:pointer;
    aupdateall:boolean=false;
    aver:integer=verUnk):boolean;
var
  lmod:TTL2ModInfo;
  lscan:pointer;
  ls:string;
  lmodid:Int64;
  i:integer;
begin
  result:=false;
  ams:=nil;
  if adb=nil then exit;

  ls:='';

  if (apath[Length(apath)] in ['/','\']) or DirectoryExists(apath) then
  begin
    result:=true;

    if aver=verUnk then
    begin
      FillChar(lmod,SizeOf(lmod),0);
           if FileExists(apath+'media/massfile.dat.adm') then aver:=verTL1
      else if FileExists(apath+'media/tags.dat')         then aver:=verTL2
      else if LoadModConfig(PChar(apath+'\MOD.DAT'),lmod) then
      begin
        // modid can be for TL1 mod too (just ignoring)
        if lmod.modid=0 then aver:=verTL1Mod else aver:=verTL2Mod;
      end
      else
        aver:=verTL1Mod;
    end;

    if (lmod.title=nil) and
      ((aver=verTL1Mod) or (aver=verTL2Mod)) then
    begin
      ls:=ExtractName(apath);
      if ls[Length(ls)] in ['\','/'] then SetLength(ls,Length(ls)-1);
      lmod.title:=CopyWide(PUnicodeChar(UnicodeString(ls)));
    end;
  end
  else if FileExists(apath) then
  begin
    i:=RGPAKGetVersion(apath);
    if aver<>i then
    begin
      if ABS(aver)<>ABS(i) then
        RGLog.Add('Defined version '+GetGameName(aver)+
          ' will be replaced by container version '+GetGameName(i));
      aver:=i;
    end;
         if (aver=verTL2Mod) or (aver=verTL1Mod) then result:=ReadModInfo(PChar(apath),lmod)
    else if (aver=verTL2   ) or (aver=verTL1   ) then result:=true;
  end;

  if result then
  begin
    if (aver=verTL2Mod) or (aver=verTL1Mod) then
    begin
      AddTheMod(adb,lmod);
      lmodid:=lmod.modid;
      ClearModInfo(lmod);
    end
    else
      lmodid:=0;

    GetMem  (ams ,SizeOf(TModScanner));
    FillChar(ams^,SizeOf(TModScanner),0);

    PModScanner(ams)^.FRootLen:=PrepareRGScan(lscan, apath, ['.DAT','.ADM'], ams);
    if lscan<>nil then
    begin

      with PModScanner(ams)^ do
      begin
        db       :=adb;
        scan     :=lscan;
        FDoUpdate:=aupdateall;
        Str(lmodid,FModId);
        FModMask :=' '+FModId+' ';
        gamever  :=ABS(aver);
      end;

    end
    else
    begin
//      EndRGScan(lscan);
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
{
      FModId  :='';
      FModMask:='';
}
    end;
    Finalize(PModScanner(ams)^);

    FreeMem(ams);
    ams:=nil;
  end;
end;

{%ENDREGION Scan single mod}

{%REGION Scan dirs}

procedure ProcessSingleMod(adb:PSQLite3; const aname:string);
var
  lms:pointer;
begin
  if not Prepare(adb,aname,lms) then
  begin
    RGLog.Add('Can''t prepare "'+aname+'" scanning');
    exit;
  end;

  ScanAll(lms);

  Finish(lms);
end;

function DoCheck(const adir,aname:string; aparam:pointer):cardinal;
var
  lext:string;
begin
  result:=1 or sres_nocheck;
  lext:=ExtractExt(aname);
  if (lext='.MOD') or
     (lext='.PAK') or
     (lext='.ZIP') then
  begin
    with PScanDir(aparam)^ do
      ProcessSingleMod(db,path+adir+'\'+aname);
  end
//  else if (UpCase(aname)='MOD.DAT') then
  else if (UpCase(aname)='MEDIA/') then
  begin
    with PScanDir(aparam)^ do
      if (adir='\') or (adir='/') then
        ProcessSingleMod(db,path)
      else
        ProcessSingleMod(db,path+adir);
  end
  else
    exit(0);
end;

function ScanPath(adb:PSQLite3; const apath:string):integer;
var
  lsd:TScanDir;
begin
  result:=0;
  lsd.db  :=adb;
  lsd.path:=apath;
  if not (lsd.path[Length(lsd.path)] in ['/','\']) then
    lsd.path:=lsd.path+'/';
  result:=MakeRGScan(apath,'',['.PAK','.MOD','.ZIP','.DAT','.ADM'],nil,@lsd,@DoCheck);
end;

{%ENDREGION Scan dirs}

{%REGION Base}

function CreateTables(adb:PSQLite3; aver:integer):boolean;
begin
  result:=CreateModTable      (adb,ABS(aver));

  result:=CreateAddsTable     (adb,ABS(aver));
  result:=CreateUnitTypesTable(adb,ABS(aver));
  result:=CreateClassesTable  (adb,ABS(aver));
  result:=CreateGraphTable    (adb,ABS(aver));
  result:=CreateInventoryTable(adb,ABS(aver));
  result:=CreateItemsTable    (adb,ABS(aver));
  result:=CreateMobsTable     (adb,ABS(aver));
  result:=CreateMoviesTable   (adb,ABS(aver));
  result:=CreatePetsTable     (adb,ABS(aver));
  result:=CreatePropsTable    (adb,ABS(aver));
  result:=CreateQuestsTable   (adb,ABS(aver));
  result:=CreateRecipesTable  (adb,ABS(aver));
  result:=CreateSkillsTable   (adb,ABS(aver));
  result:=CreateStatsTable    (adb,ABS(aver));
  result:=CreateWardrobeTable (adb,ABS(aver));
end;

function RGOpenBase(out adb:PSQLite3; const fname:string=TL2DataBase; createas:integer=verTL2):boolean;
begin
  try
    InitializeSQLite();
  except
    exit(false);
  end;

  result:=sqlite3_open(':memory:',@adb)=SQLITE_OK;
  if result then
  begin
    if (fname='') or (CopyFromFile(adb,PChar(fname))<>SQLITE_OK) then
      result:=CreateTables(adb, createas);
  end;
end;

function RGSaveBase(adb:PSQLite3; const fname:string=TL2DataBase):integer;
begin
  result:=CopyToFile(adb,PChar(fname));
end;

function RGCloseBase(var adb:PSQLite3; const fname:string=''):boolean;
begin
  if fname<>'' then
    result:=RGSaveBase(adb,fname)=SQLITE_OK
  else
    result:=true;

  result:=result and (sqlite3_close(adb)=SQLITE_OK);
  adb:=nil;
  ReleaseSQLite();
end;

{%ENDREGION Base}

initialization
  RGTags.Import('RGDICT','TEXT');

end.
