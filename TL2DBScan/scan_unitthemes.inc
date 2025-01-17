{%REGION UnitThemes}

function AddUThemeToBase(ams:pointer; const aname:string; aId:int64):integer;
var
  lmodid,lSQL,sid:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'dicuthemes', sid);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO dicuthemes (id, name, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
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
  name:string;
  lid:int64;
  i:integer;
begin
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME')=0 then name :=AsString   (lnode)
    else if CompareWide(pcw,'GUID')=0 then lid  :=AsInteger64(lnode);
  end;

  result:=AddUThemeToBase(ams,name,lid);
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

function CreateUThemesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'stats') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicuthemes ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
