{%REGION Quests}

function AddQuestToBase(ams:pointer; const aname:string; aId:int64; const atitle:string):boolean;
var
  lmodid,lSQL,sid:string;
begin
  result:=false;

  Str(aid,sid);
  lmodid:=CheckForMod(ams,'quests', sid, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO quests (id, name, title, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
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
    if not AddQuestToBase(ams,name,lid,title) then lid:=0;

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
  result:=0;

  p:=ParseTextMem(abuf);
  if p=nil then
    p:=ParseDatMem(abuf);
  
  if p<>nil then
  begin
    i:=AddQuestNode(aparam,p);

    if      i=0 then RGLog.Add('can''t update '+aname)
    else if i<0 then RGLog.Add(' don''t added '+aname);

    DeleteNode(p);
  end;
end;

function ScanQuests(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/QUESTS', @ProcessQuests);
end;

function CreateQuestsTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'quests') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE quests ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );');
end;

{%ENDREGION}