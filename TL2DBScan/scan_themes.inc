{%REGION UnitThemes}


function AddPieceToBase(ams:pointer; const aname:string; aId:int64; const atags:string):boolean;
var
  lSQL,sid:string;
begin
  Str(aid,sid);
  lSQL:='REPLACE INTO dicpieces (id, name, tags) VALUES ('+
      sid+', '''+aname+''', '''+atags+''')';

  result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
end;

// Skip levelset name
function AddLevelSetNode(ams:pointer; anode:pointer):integer;
var
  lnode,ltnode:pointer;
  pcw:PWideChar;
  lname,ltags:string;
  lid:int64;
  i,j:integer;
begin
  result:=$10000;

  lname:='';
  lid  :=-1;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    // check pieces only
    if GetNodeType(lnode)=rgGroup then
    begin
      lname:='';
      ltags:='';
      lid  :=-1;
      for j:=0 to GetChildCount(lnode)-1 do
      begin
        ltnode:=GetChild(lnode,j);
        pcw:=GetNodeName(ltnode);
        if      CompareWide(pcw,'NAME')=0 then lname:=AsString   (ltnode)
        else if CompareWide(pcw,'GUID')=0 then lid  :=AsInteger64(ltnode)
        else if CompareWide(pcw,'TAG' )=0 then ltags:=ltags+','+AnsiString(AsString(ltnode));
      end;
      if (lname<>'') and (lid<>-1) then
      begin
        if AddPieceToBase(ams,lname,lid,ltags) then
          inc(result);
      end;
    end;
  end;
  if (lname='') or (lid=-1) then
    result:=0;
end;

function ProcessLevelSets(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      result:=AddLevelSetNode(aparam,p);
      if result=0 then
        if RGDebugLevel=dlDetailed then
          RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanLevelSets(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning LevelSets');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/LEVELSETS', @ProcessLevelSets);
  if RGDebugLevel<>dlNone then
    RGLog.Add('Checked '+IntToStr(result shr 16)+
        ' set records. Added '+IntToStr(result and $FFFF)+' set elements');
end;


function AddLThemeToBase(ams:pointer; const aname:string; aId:int64):boolean;
var
  lSQL,sid:string;
begin
  Str(aid,sid);
  lSQL:='REPLACE INTO diclthemes (id, name) VALUES ('+
      sid+', '''+aname+''')';

  result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
end;

function AddLThemeNode(ams:pointer; anode:pointer):boolean;
var
  lnode,ltnode:pointer;
  pcw:PWideChar;
  lname:string;
  lid:int64;
  i,j:integer;
begin
  result:=true;
  lname:='';
  lid  :=-1;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    if GetNodeType(lnode)=rgGroup then
    begin
      lname:='';
      lid  :=-1;
      for j:=0 to GetChildCount(lnode)-1 do
      begin
        ltnode:=GetChild(lnode,j);
        pcw:=GetNodeName(ltnode);
        if      CompareWide(pcw,'THEME')=0 then lname:=AsString   (ltnode)
        else if CompareWide(pcw,'ID'   )=0 then lid  :=AsInteger64(ltnode);
      end;
      if (lname<>'') and (lid<>-1) then
        result:=result and AddLThemeToBase(ams,lname,lid);
    end;
  end;
  if (lname='') or (lid=-1) then
    result:=false;
end;

function ProcessLThemes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if AddLThemeNode(aparam,p) then result:=1
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanLThemes(ams:pointer):integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    if RGDebugLevel<>dlNone then RGLog.Add('TL1 don''t support Level themes');
    exit(0);
  end;
  if PModScanner(ams)^.FModId[1]<>'0' then
  begin
    if RGDebugLevel<>dlNone then RGLog.Add('Support Level themes for vanilla game now only');
    exit(0);
  end;

  if RGDebugLevel<>dlNone then RGLog.Add('Scanning LevelThemes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/LEVELTHEMES', @ProcessLThemes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;


function AddUThemeToBase(ams:pointer; aname:PUnicodeChar; aId:int64):integer;
var
  lmodid,sid:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'dicuthemes', sid);
  if lmodid<>'' then
  begin
    if ExecuteDirect(PModScanner(ams)^.db,
      'REPLACE INTO dicuthemes (id, name, modid) VALUES ('+
        sid+', ?1, '+lmodid+')',aname) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddUThemeNode(ams:pointer; anode:pointer):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lname:PUnicodeChar;
  lid:int64;
  i:integer;
begin
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME')=0 then lname:=AsString   (lnode)
    else if CompareWide(pcw,'GUID')=0 then lid  :=AsInteger64(lnode);
  end;

  result:=AddUThemeToBase(ams,lname,lid);
end;

function ProcessUThemes(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  lres:integer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lres:=AddUThemeNode(aparam,p);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanUThemes(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning UnitThemes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITTHEMES', @ProcessUThemes);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;


function CreateLevelsetsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'dicpieces') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicpieces ('+
      '    id   INTEGER PRIMARY KEY,'+
      '    name TEXT,'+
      '    tags TEXT);')
  else
    result:=true;
end;

function CreateLThemesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if aver=verTL1 then exit(false);

  if not IsTableExists(adb,'diclthemes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE diclthemes ('+
      '    id   INTEGER PRIMARY KEY,'+
      '    name TEXT);')
  else
    result:=true;
end;

function CreateUThemesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'dictuthemes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicuthemes ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
