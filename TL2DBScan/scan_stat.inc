{%REGION Stats}

function AddStatToBase(ams:pointer; const aname:string; aId:int64;
          const atitle:string; asaves:boolean):integer;
var
  lmodid,lSQL,sid,ssaves:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'stats', sid);
  if lmodid<>'' then
  begin
    if asaves then ssaves:='1' else ssaves:='0';

    lSQL:='REPLACE INTO stats (id, name, title, saves, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+ssaves+', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddStatNode(ams:pointer; anode:pointer):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  name,title:string;
  lid:int64;
  saves:boolean;
  i:integer;
begin
  title:='';
  saves:=false;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME'       )=0 then name :=AsString   (lnode)
    else if CompareWide(pcw,'UNIQUE_GUID')=0 then lid  :=AsInteger64(lnode)
    else if CompareWide(pcw,'SAVES'      )=0 then saves:=AsBool     (lnode)
    else if CompareWide(pcw,'DISPLAYNAME')=0 then title:=AsString   (lnode);
  end;

  result:=AddStatToBase(ams,name,lid,title,saves);
end;

function ProcessStats(
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
      lres:=AddStatNode(aparam,p);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanStats(ams:pointer):integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    RGLog.Add('TL1 don''t support Stats setup');
    exit(0);
  end;

  if RGDebugLevel<>dlNone then RGLog.Add('Scanning stats');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/STATS', @ProcessStats);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateStatsTable(adb:PSQLite3):boolean;
begin
  if PModScanner(ams)^.gamever=verTL1 then exit(false);

  if not IsTableExists(adb,'stats') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE stats ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT,'+
      '    saves INTEGER (1) );')
  else
    result:=true;
end;

{%ENDREGION}
