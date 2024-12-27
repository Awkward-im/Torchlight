{%REGION Adds}

function AddFileToBase(ams:pointer; const afile:string):integer;
var
  lfile:string;
  i:integer;
begin
  if afile='' then exit(-1);

  lfile:=LowerCase(afile);
  for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
  result:=ReturnInt(PModScanner(ams)^.db,
    'SELECT id FROM dicfiles WHERE (file='''+lfile+''')');
  if result<0 then
    result:=ReturnInt(PModScanner(ams)^.db,
      'REPLACE INTO dicfiles (file) VALUES ('''+lfile+''') RETURNING id;');
end;

function CreateFilesTable(adb:PSQLite3):boolean;
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
  end;

const
  DefUnitColumns = 'id, name, title, file, base, unittype, scale, mesh, resdir';
  DefUnitDDL =
      '    id       INTEGER PRIMARY KEY,'+
      '    name     TEXT,'+
      '    title    TEXT,'+
      '    modid    TEXT,'+
      '    file     TEXT,'+
//      '    base     TEXT,'+
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
{
    lbase:=LowerCase(aunit^.base);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';
}
  end
  else
    lbase:='';

  with aunit^ do
    result:=id+', '+FixedText(name)+', '+FixedText(title)+
      ', '''+lfile+''', '''+lbase+''', '''+unittype+''', '+scale+
      ', '''+meshfile+''', '''+ldir+'''';
end;

function SetUnitInfo(anode:pointer; aunit:PBaseUnitInfo):boolean;
var
  pcw:PUnicodeChar;
begin
  pcw:=GetNodeName(anode);
  if      CompareWide(pcw,'NAME'             )=0 then aunit^.name    :=AsString(anode)
  else if CompareWide(pcw,'DISPLAYNAME'      )=0 then aunit^.title   :=AsString(anode)
  else if CompareWide(pcw,'BASEFILE'         )=0 then aunit^.base    :=AsString(anode)
  else if CompareWide(pcw,'UNIT_GUID'        )=0 then aunit^.id      :=AsString(anode)
  else if CompareWide(pcw,'UNITTYPE'         )=0 then aunit^.unittype:=AsString(anode)
  else if CompareWide(pcw,'MESHFILE'         )=0 then aunit^.meshfile:=AsString(anode)
  else if CompareWide(pcw,'RESOURCEDIRECTORY')=0 then aunit^.resdir  :=AsString(anode)
  else if CompareWide(pcw,'SCALE'            )=0 then Str(AsFloat(anode):0:2,aunit^.scale)
  else exit(false);

  result:=true;
end;

{$i scan_graph.inc}
{$i scan_effects.inc}
{$i scan_affixes.inc}
{$i scan_sets.inc}

{
  add files:
    if abaseadd base, return idx
      if found, get index. if not, add and return
    add file, return idx
      if exists and no base, and with argument=base, then update
      add with base and return
}
{
WITH ins AS (
  INSERT INTO files (file, base)
  VALUES ('your_file_value', your_base_value)
  ON CONFLICT(file) DO NOTHING
  RETURNING id
)
SELECT id FROM ins
UNION ALL
SELECT id FROM files WHERE file = 'your_file_value'
LIMIT 1;
}
(*
function AddFilesToBase(ams:pointer; const afile,abase:string):integer;
var
  lSQL, lfile, lbase:string;
  lidx,i:integer;
begin
  // Get BASE index
  if abase<>'' then
  begin
    lbase:=LowerCase(abase);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';

    lidx:=ReturnInt(PModScanner(ams)^.db,
      'SELECT id FROM files WHERE (file='''+lbase+''')');
  end
  else
    lidx:=-1;

  // if no BASE in DB, add it and return index
  if (lidx=-1) and (abase<>'') then
  begin
    lidx:=ReturnInt(PModScanner(ams)^.db,
      'REPLACE INTO files (file) VALUES ('''+lbase+''') RETURNING id;');
  end;

  lfile:=LowerCase(afile);
  for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';

  // if afile exists...
  result:=ReturnInt(PModScanner(ams)^.db,
    'SELECT id FROM files WHERE (file='''+lfile+''')');
  // it looks like base for other, so, need to update base for it only
  if result>=0 then
  begin
    if lidx<>-1 then
      ExecuteDirect(PModScanner(ams)^.db,
        'UPDATE files SET base='+IntToStr(lidx)+' WHERE id='+IntToStr(result));
    exit;
  end;

  if lidx=-1 then
  begin
    // Add without base
    lSQL:='REPLACE INTO files (file) VALUES ('''+lfile+''') RETURNING id;';
  end
  else
  begin
    // Add with base
    lSQL:='REPLACE INTO files (file, base) VALUES ('''+lfile+''', '+IntToStr(lidx)+') RETURNING id;';
  end;
  result:=ReturnInt(PModScanner(ams)^.db,lSQL);
end;

function CreateFilesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'files') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE files ('+
      '  id   INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  file TEXT,'+
      '  base INTEGER);')
  else
    result:=true;
end;
*)

function ScanAdds(ams:pointer):integer;
begin
  result:=ScanEffects(ams);
  result:=ScanAffixes(ams);
  result:=ScanSets(ams);
end;

function CreateAddsTable(adb:PSQLite3):boolean;
begin
  result:=CreateEffectsTable(adb);
  result:=CreateAffixesTable(adb);
  result:=CreateSetsTable(adb);

  result:=CreateFilesTable(adb);
end;

{%ENDREGION Adds}
