{%REGION Mobs}

{TODO: TL1: MEDIA/UNITS/MONSTERS/ UNITTYPE:PET}

function AddMobToBase(ams:pointer; const anid,aname,atitle:string):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckIdForMod(ams,'mobs', anid);
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
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    lnode:=FindNode(anode,'UNITTYPE');
    if lnode<>nil then
    begin
      if CompareWide(AsString(lnode),'PET')=0 then
      begin
        result:=AddPetNode(ams,anode);
        if result then
          RGLog.Add('Added as pet');
        exit;
      end;
    end;
  end;

  lmask :=0;
  lname :='';
  ltitle:='';
  lid   :='';

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
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if AddMobNode(aparam,p) then
        result:=1
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function CheckNameMobs(const adir,aname:string; aparam:pointer):integer;
begin
  // no need to check content and don't increase count
  if PModScanner(aparam)^.gamever<>verTL1 then
  begin
    result:=sres_nocheck+sres_fail;

    if Pos('MEDIA/UNITS/MONSTERS/PETS/'           ,adir)>0 then exit;
    if Pos('MEDIA/UNITS/MONSTERS/WARBOUNDS/'      ,adir)>0 then exit;
    if Pos('MEDIA/UNITS/MONSTERS/BROTHER-IN-ARMS/',adir)>0 then exit;
  end;

	result:=1;
end;

function ScanMobs(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning mobs');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS', @ProcessMobs, @CheckNameMobs);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateMobsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'mobs') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE mobs ('+
      '    id    INTEGER PRIMARY KEY,'+
      '    name  TEXT,'+
      '    title TEXT,'+
      '    modid TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
