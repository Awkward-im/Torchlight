{%REGION Pet}

type
  tpetinfo = record
    id      :string;
    title   :string;
    name    :string;
    icon    :string;
    atype   :integer;
    scale   :single;
    textures:integer;
    gr_hp   :string;
    gr_armor:string;
    gr_dmg  :string;
  end;

function AddPetToBase(ams:pointer; var apet:tpetinfo):boolean;
var
  lmodid,lSQL,lscale:string;
begin
  result:=false;

  lmodid:=CheckForMod(ams,'pets', aPet.id, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    Str(aPet.Scale:0:2,lscale);

    lSQL:='REPLACE INTO pets (id, name, title, type, scale, skins, icon, '+
          'graph_hp, graph_armor, graph_dmg, modid) VALUES ('+
        aPet.id+', '+FixedText(apet.name)+', '+FixedText(apet.title)+', '+
        IntToStr(apet.atype)+', '+lscale+', '+IntToStr(apet.textures)+
        ', '+FixedText(apet.icon)+', '''+apet.gr_hp+''', '''+apet.gr_armor+''', '''+apet.gr_dmg+
        ''', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddPetNode(ams:pointer; anode:pointer):boolean;
var
  lnode:pointer;
  pcw:PWideChar;
  lpet:tpetinfo;
  i:integer;
begin
  lpet.scale:=1.0;
  lpet.textures:=0;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);

    pcw:=GetNodeName(lnode);
    if      CompareWide(pcw,'NAME'                 )=0 then lpet.name    :=AsString(lnode)
    else if CompareWide(pcw,'DISPLAYNAME'          )=0 then lpet.title   :=AsString(lnode)
    else if CompareWide(pcw,'UNIT_GUID'            )=0 then lpet.id      :=AsString(lnode)
    else if CompareWide(pcw,'SCALE'                )=0 then lpet.scale   :=AsFloat (lnode)
    else if CompareWide(pcw,'ICON'                 )=0 then lpet.icon    :=ExtractFileNameOnly(AsString(lnode))
    else if CompareWide(pcw,'TEXTURE_OVERRIDE_LIST')=0 then lpet.textures:=GetChildCount(lnode)

    else if CompareWide(pcw,'ARMOR_GRAPH')=0 then
    begin
      lpet.gr_armor:=AsString(lnode);
      if UpCase(lpet.gr_armor)<>'ARMOR_MINION_BYLEVEL' then
      begin
        ScanGraph(ams,lpet.gr_armor,1);
        if PModScanner(ams)^.FLogLevel>2 then
          RGLog.Add('Pet armor graph is '+lpet.gr_armor);
      end
    end
    else if CompareWide(pcw,'DAMAGE_GRAPH')=0 then
    begin
      lpet.gr_dmg:=AsString(lnode);
      if UpCase(lpet.gr_dmg)<>'DAMAGE_MINION_BYLEVEL' then
      begin
        ScanGraph(ams,lpet.gr_dmg,1);
        if PModScanner(ams)^.FLogLevel>2 then
          RGLog.Add('Pet damage graph is '+lpet.gr_dmg);
      end
    end
    else if CompareWide(pcw,'HEALTH_GRAPH')=0 then
    begin
      lpet.gr_hp:=AsString(lnode);
      if UpCase(lpet.gr_hp)<>'HEALTH_MINION_BYLEVEL' then
      begin
        ScanGraph(ams,lpet.gr_hp,1);
        if PModScanner(ams)^.FLogLevel>2 then
          RGLog.Add('Pet health graph is '+lpet.gr_hp);
      end
    end
    else if CompareWide(pcw,'UNITTYPE')=0 then
    begin
      if CompareWide(AsString(lnode),'STARTING PET')=0 then
        lpet.atype:=0
      else
        lpet.atype:=1;
    end;
  end;

  result:=AddPetToBase(ams,lpet);
end;

function ProcessPets(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
begin
  result:=0;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      if AddPetNode(aparam,p) then
        result:=1
      else if PModScanner(aparam)^.FLogLevel>1 then 
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanPets(ams:pointer):integer;
begin
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add('Scanning pets');
  result:=       DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/PETS/'           , @ProcessPets);
  result:=result+DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/WARBOUNDS/'      , @ProcessPets);
  result:=result+DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/BROTHER-IN-ARMS/', @ProcessPets);
  if PModScanner(ams)^.FLogLevel>0 then RGLog.Add(IntToStr(result)+' records added');
end;

function CreatePetsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'pets') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE pets ('+
      '    id          INTEGER PRIMARY KEY,'+
      '    name        TEXT,'+
      '    title       TEXT,'+
      '    modid       TEXT,'+
      '    type        INTEGER,'+
      '    scale       REAL,'+
      '    skins       INTEGER,'+
      '    icon        TEXT,'+
      '    graph_hp    TEXT,'+
      '    graph_armor TEXT,'+
      '    graph_dmg   TEXT );')
  else
    result:=true;
end;

{%ENDREGION}
