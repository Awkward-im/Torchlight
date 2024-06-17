{%REGION Stats}

function AddStatToBase(ams:pointer; const aname:string; aId:int64; const atitle:string; asaves:boolean):boolean;
var
  lmodid,lSQL,sid,ssaves:string;
begin
  result:=false;

  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'stats', sid);
  if lmodid<>'' then
  begin
    if asaves then ssaves:='1' else ssaves:='0';

    lSQL:='REPLACE INTO stats (id, name, title, saves, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+ssaves+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddStatNode(ams:pointer; anode:pointer):boolean;
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
          aparam:pointer):integer;
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
      if AddStatNode(aparam,p) then
        result:=1
      else if PModScanner(aparam)^.FLogLevel>1 then
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

  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add('Scanning stats');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/STATS', @ProcessStats);
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateStatsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'stats') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE stats ('+
      '    id    INTEGER     PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT,'+
      '    saves INTEGER (1) );')
  else
    result:=true;
end;

{%ENDREGION}
