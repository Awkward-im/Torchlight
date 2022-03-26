{%REGION Mobs}

function AddMobToBase(ams:pointer; const anid,aname,atitle:string):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckForMod(ams,'mobs', anid, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO mobs (id, name, title, modid) VALUES ('+
        anid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddMobNode(ams:pointer; anode:pointer):boolean;
var
  lnode:pointer;
  pcw:PWideChar;
  lid,lname,ltitle:string;
  i,lmask:integer;
begin
  lmask:=0;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'NAME')=0 then
    begin
      lmask:=lmask or 1;
      lname:=AsString(lnode);
    end
    else if CompareWide(pcw,'DISPLAYNAME')=0 then
    begin
      lmask:=lmask or 2;
      ltitle:=AsString(lnode);
    end
    else if CompareWide(pcw,'UNIT_GUID')=0 then
    begin
      lmask:=lmask or 4;
      lid:=AsString(lnode);
    end;
    if lmask=7 then break;
  end;

  result:=AddMobToBase(ams,lid,lname,ltitle);
end;

function ProcessMobs(
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
    if AddMobNode(aparam,p) then
      result:=1
    else
      RGLog.Add('can''t update '+aname);

    DeleteNode(p);
  end;
end;

function CheckNameMobs(const adir,aname:string; aparam:pointer):integer;
begin
  result:=0;

  if Pos('MEDIA/UNITS/MONSTERS/PETS'           ,adir)>0 then exit;
  if Pos('MEDIA/UNITS/MONSTERS/WARBOUNDS'      ,adir)>0 then exit;
  if Pos('MEDIA/UNITS/MONSTERS/BROTHER-IN-ARMS',adir)>0 then exit;

	result:=1;
end;

function ScanMobs(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS', @ProcessMobs, @CheckNameMobs);
end;

function CreateMobsTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'mobs') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE mobs ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );');
end;

{%ENDREGION}
