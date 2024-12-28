{%REGION Quests}

function AddQuestToBase(ams:pointer; const aname:string; aId:int64; const atitle:string):integer;
var
  lmodid,lSQL,sid:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'quests', sid);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO quests (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddQuestNode(ams:pointer; anode:pointer):int64;
var
  lnode:pointer;
  pcw:PWideChar;
  name,title:string;
  lid:int64;
  i:integer;
begin
  title:='';
  lid:=-1;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    if GetNodeType(lnode)<>rgGroup then
    begin
      pcw:=GetNodeName(lnode);
      if      CompareWide(pcw,'NAME'       )=0 then name :=AsString   (lnode)
      else if CompareWide(pcw,'QUEST_GUID' )=0 then lid  :=AsInteger64(lnode)
      else if CompareWide(pcw,'DISPLAYNAME')=0 then title:=AsString   (lnode);
    end;
  end;

  if lid<>-1 then
    lid:=AddQuestToBase(ams,name,lid,title);

  result:=lid;
end;

function ProcessQuests(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
  i:int64;
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
      i:=AddQuestNode(aparam,p);

           if i>0 then result:=1
      else if i=0 then
      begin
        if RGDebugLevel=dlDetailed then
          RGLog.Add('can''t update '+aname)
      end
      else if i=-1 then
      begin
        if RGDebugLevel=dlDetailed then
          RGLog.Add('don''t added ' +aname);
      end;
      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanQuests(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning quests');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/QUESTS', @ProcessQuests);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateQuestsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'quests') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE quests ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
