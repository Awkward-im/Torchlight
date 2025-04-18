{%REGION Pet}

type
  TPetInfo = object(TBaseUnitInfo)
    icon    :string;
    gr_hp   :string;
    gr_armor:string;
    gr_dmg  :string;
    skins   :integer;
  end;


function AddPetToBase(ams:pointer; var apet:TPetInfo):integer;
var
  lSQL:string;
begin
  lSQL:='REPLACE INTO pets ('+DefUnitColumns+', skins, icon, '+
        'graph_hp, graph_armor, graph_dmg) VALUES ('+
      GetDefUnitValues(ams,@apet)+', '+IntToStr(apet.skins)+', '+FixedText(apet.icon)+
      ', '''+apet.gr_hp+''', '''+apet.gr_armor+''', '''+apet.gr_dmg+''')';

  if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
    result:=1
  else
    result:=0;
end;

function AddPetNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lpet:tpetinfo;
  i,ltmp:integer;
begin
  FillChar(lpet,sizeOf(lpet),0);

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    ltmp:=SetUnitInfo(lnode,@lpet);
    if ltmp<0 then
    begin
      lpet.modid:=CheckIdForMod(ams,'pets', lpet.id);
      if lpet.modid='' then exit(-1);
    end
    else if ltmp=0 then
    begin
      pcw:=GetNodeName(lnode);
      if      CompareWide(pcw,'ICON'                 )=0 then lpet.icon :=AsString(lnode)
      // just as reserve
      else if CompareWide(pcw,'PORTRAIT'             )=0 then lpet.icon :=AsString(lnode)
      else if CompareWide(pcw,'TEXTURE_OVERRIDE_LIST')=0 then lpet.skins:=GetChildCount(lnode)
      else if CompareWide(pcw,'ARMOR_GRAPH')=0 then
      begin
        lpet.gr_armor:=AsString(lnode);
        if UpCase(lpet.gr_armor)<>'ARMOR_MINION_BYLEVEL' then
        begin
          ScanGraph(ams,lpet.gr_armor,1);
          if RGDebugLevel=dlDetailed then
            RGLog.Add('Pet armor graph is '+lpet.gr_armor);
        end
      end
      else if CompareWide(pcw,'DAMAGE_GRAPH')=0 then
      begin
        lpet.gr_dmg:=AsString(lnode);
        if UpCase(lpet.gr_dmg)<>'DAMAGE_MINION_BYLEVEL' then
        begin
          ScanGraph(ams,lpet.gr_dmg,1);
          if RGDebugLevel=dlDetailed then
            RGLog.Add('Pet damage graph is '+lpet.gr_dmg);
        end
      end
      else if CompareWide(pcw,'HEALTH_GRAPH')=0 then
      begin
        lpet.gr_hp:=AsString(lnode);
        if UpCase(lpet.gr_hp)<>'HEALTH_MINION_BYLEVEL' then
        begin
          ScanGraph(ams,lpet.gr_hp,1);
          if RGDebugLevel=dlDetailed then
            RGLog.Add('Pet health graph is '+lpet.gr_hp);
        end
      end
    end;
  end;
  lpet.fname:=FixFileExt(fname);

  result:=AddPetToBase(ams,lpet);
end;

function ProcessPets(
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
      lres:=AddPetNode(aparam,p, adir+aname);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then 
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanPets(ams:pointer):integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    RGLog.Add('TL1 don''t separate mobs and pets. Cycle on mob scan.');
    exit(0);
  end;

  if RGDebugLevel<>dlNone then RGLog.Add('Scanning pets');
  result:=       DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/PETS/'           , @ProcessPets);
  result:=result+DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/WARBOUNDS/'      , @ProcessPets);
  result:=result+DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/MONSTERS/BROTHER-IN-ARMS/', @ProcessPets);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreatePetsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'pets') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE pets ('+
      DefUnitDDL+
      '    skins       INTEGER,'+
      '    icon        TEXT,'+
      '    graph_hp    TEXT,'+
      '    graph_armor TEXT,'+
      '    graph_dmg   TEXT);')
  else
    result:=true;
end;

{%ENDREGION}
