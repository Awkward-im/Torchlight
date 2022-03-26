{%REGION Stats}

function AddStatToBase(ams:pointer; const aname:string; aId:int64; const atitle:string; asaves:boolean):boolean;
var
  lmodid,lSQL,sid,ssaves:string;
begin
  result:=false;

  Str(aid,sid);
  lmodid:=CheckForMod(ams,'stats', sid, PModScanner(ams)^.FModId);
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
  result:=0;

  p:=ParseTextMem(abuf);
  if p=nil then
    p:=ParseDatMem(abuf);
  
  if p<>nil then
  begin
    if not AddStatNode(aparam,p) then
      RGLog.Add('can''t update '+aname);

    DeleteNode(p);
  end;
end;

function ScanStats(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/STATS', @ProcessStats);
end;

function CreateStatsTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'stats') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE stats ('+
      '    id    INTEGER     PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT,'+
      '    saves INTEGER (1) );');
end;

{%ENDREGION}