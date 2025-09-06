{%REGION Adds}
{TODO: add "dontcreate" flag to common data}
function AddFileToBase(ams:pointer; const afile:AnsiString):integer;
var
  lfile:AnsiString;
  i:integer;
begin
  if afile='' then exit(-1);

  lfile:=LowerCase(afile);
  for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
  result:=ReturnInt(PModScanner(ams)^.db,
    'SELECT id FROM dicfiles WHERE (file=?1)',PAnsiChar(lfile));
  if result<0 then
    result:=ReturnInt(PModScanner(ams)^.db,
      'INSERT INTO dicfiles (file) VALUES (?1) RETURNING id;',PAnsiChar(lfile));
end;

function CreateFilesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'files') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicfiles ('+
      '  id   INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  file TEXT);')
  else
    result:=true;
end;

type
  PBaseUnitInfo = ^TBaseUnitInfo;
  TBaseUnitInfo = object
    name    :string;
    title   :string;
    fname   :string;
    base    :string;
    unittype:string;
    meshfile:string;
    resdir  :string;
    id      :string;
    scale   :string;
    modid   :string;
  end;

const
  DefUnitColumns = 'id, modid, name, title, file, base, unittype, scale, mesh, resdir';
  DefUnitDDL =
      '    id       INTEGER PRIMARY KEY,'+
      '    name     TEXT,'+
      '    title    TEXT,'+
      '    modid    TEXT,'+
      '    file     TEXT,'+
      '    base     INTEGER,'+
      '    unittype TEXT,'+
      '    scale    REAL,'+
      '    mesh     TEXT,'+
      '    resdir   TEXT,';


function GetDefUnitValues(ams:pointer; aunit:PBaseUnitInfo):string;
var
  ldir:string;
  lfile,lbase:string;
  i:integer;
begin
  if aunit^.scale='' then aunit^.scale:='1.0';

  if aunit^.resdir<>'' then
  begin
    ldir:=LowerCase(aunit^.resdir);
    for i:=1 to Length(ldir) do if ldir[i]='\' then ldir[i]:='/';
  end
  else
    ldir:='';

  lfile:=LowerCase(aunit^.fname);
  for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';

  if aunit^.base<>'' then
  begin
    i:=AddFileToBase(ams,aunit^.base);
    if i<0 then
      lbase:=''
    else
      Str(i,lbase);
  end
  else
    lbase:='';

  with aunit^ do
    result:=id+', '+modid+', '+FixedText(name)+', '+FixedText(title)+
      ', '''+lfile+''', '''+lbase+''', '''+unittype+''', '+scale+
      ', '''+meshfile+''', '''+ldir+'''';
end;

function SetUnitInfo(anode:pointer; aunit:PBaseUnitInfo):integer;
var
  pcw:PUnicodeChar;
begin
  pcw:=GetNodeName(anode);
  if      CompareWide(pcw,'NAME'             )=0 then aunit^.name    :=AsString(anode)
  // for case when it comes 2+ times
  else if CompareWide(pcw,'DISPLAYNAME'      )=0 then begin if aunit^.title='' then aunit^.title:=AsString(anode) end
  else if CompareWide(pcw,'BASEFILE'         )=0 then aunit^.base    :=AsString(anode)
  else if CompareWide(pcw,'UNITTYPE'         )=0 then aunit^.unittype:=AsString(anode)
  else if CompareWide(pcw,'MESHFILE'         )=0 then aunit^.meshfile:=AsString(anode)
  else if CompareWide(pcw,'RESOURCEDIRECTORY')=0 then aunit^.resdir  :=AsString(anode)
  else if CompareWide(pcw,'SCALE'            )=0 then Str(AsFloat(anode):0:2,aunit^.scale)
  else if CompareWide(pcw,'UNIT_GUID'        )=0 then
  begin
    aunit^.id:=AsString(anode);
    exit(-1);
  end
  else exit(0);

  result:=1;
end;

{$i scan_graph.inc}
{$i scan_effects.inc}
{$i scan_affixes.inc}
{$i scan_sets.inc}
{$i scan_themes.inc}

function ScanAdds(ams:pointer):integer;
begin
  result:=ScanEffects(ams);
  result:=ScanAffixes(ams);
  result:=ScanSets(ams);
  result:=ScanUThemes(ams);
  result:=ScanLevelsets(ams);
  //?? not modded only
  result:=ScanLThemes(ams);
end;

function CreateAddsTable(adb:PSQLite3; aver:integer):boolean;
begin
  result:=CreateEffectsTable  (adb,aver);
  result:=CreateAffixesTable  (adb,aver);
  result:=CreateSetsTable     (adb,aver);
  result:=CreateUThemesTable  (adb,aver);
  result:=CreateLevelSetsTable(adb,aver);
  result:=CreateLThemesTable  (adb,aver);

  result:=CreateFilesTable(adb,aver);
end;

{%ENDREGION Adds}
