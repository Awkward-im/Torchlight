{%REGION Items}

{TODO: Search unittype and icon by one function (avoid double scan)}
{TODO: Add effects to items}

type
  tItemInfo = object(TBaseUnitInfo)
    descr        :string;
    icon         :string;
    usable       :string;
    itemset      :string;
    quest        :string;
    stack        :string;

    level        :integer;
    sockets      :integer;
    speed        :integer;
    arm_electric :integer;
    arm_fire     :integer;
    arm_ice      :integer;
    arm_physical :integer;
    arm_poison   :integer;
    armormax     :integer;
    armormin     :integer;

    dmg_electric :integer;
    dmg_fire     :integer;
    dmg_ice      :integer;
    dmg_physical :integer;
    dmg_poison   :integer;
    maxdamage    :integer;
    mindamage    :integer;

    req_defense  :integer;
    req_dexterity:integer;
    req_level    :integer;
    req_magic    :integer;
    req_strength :integer;
  end;

function AddItemToBase(ams:pointer; const aitem:tItemInfo):integer;
var
  lSQL:string;
begin
  lSQL:='REPLACE INTO items ('+DefUnitColumns+
        ', descr, itemset, icon, usable, quest, stack, level, sockets, speed, '+
        'arm_electric, arm_fire, arm_ice, arm_physical, arm_poison, armormax, armormin, '+
        'dmg_electric, dmg_fire, dmg_ice, dmg_physical, dmg_poison, maxdamage, mindamage, '+
        'req_defense, req_dexterity, req_level, req_magic, req_strength) VALUES ('+
      GetDefUnitValues(ams,@aitem)+
      ', '+FixedText(aitem.descr)+', '+FixedText(aitem.itemset)+
      ', '+FixedText(aitem.icon)+', '+aitem.usable+', '+aitem.quest+', '+aitem.stack+
      ', '+IntToStr(aitem.level)+', '+IntToStr(aitem.sockets)+', '+IntToStr(aitem.speed)+
      ', '+IntToStr(aitem.arm_electric)+', '+IntToStr(aitem.arm_fire)+', '+IntToStr(aitem.arm_ice)+
      ', '+IntToStr(aitem.arm_physical)+', '+IntToStr(aitem.arm_poison)+
      ', '+IntToStr(aitem.armormax)+', '+IntToStr(aitem.armormin)+
      ', '+IntToStr(aitem.dmg_electric)+', '+IntToStr(aitem.dmg_fire)+', '+IntToStr(aitem.dmg_ice)+
      ', '+IntToStr(aitem.dmg_physical)+', '+IntToStr(aitem.dmg_poison)+', '+IntToStr(aitem.maxdamage)+
      ', '+IntToStr(aitem.mindamage)+', '+IntToStr(aitem.req_defense)+', '+IntToStr(aitem.req_dexterity)+
      ', '+IntToStr(aitem.req_level)+', '+IntToStr(aitem.req_magic)+', '+IntToStr(aitem.req_strength)+')';

  if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
    result:=1
  else
    result:=0;
end;

function GetBaseUnitType(ams:pointer; const fname:string):string;
var
  p,lnode:pointer;
  pcw:PWideChar;
  lbase:string;
  i:integer;
begin
  result:=GetTextValue(PModScanner(ams)^.db,'items','unittype','file='+FixedText(fname));
  if result<>'' then exit;
  
  lbase :='';

  RGLog.Reserve('Check for unittype '+fname);
  LoadFile(ams,fname,p);
  if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
    LoadFile(ams,fname+'.ADM',p);

  if p=nil then
  begin
    if RGDebugLevel=dlDetailed then
      RGLog.Add('can''t load: '+fname);
    exit;
  end;

  for i:=0 to GetChildCount(p)-1 do
  begin
    lnode:=GetChild(p,i);
    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'UNITTYPE')=0 then
    begin
      result:=AsString(lnode);
      break;
    end
    else if CompareWide(pcw,'BASEFILE')=0 then
    begin
      lbase:=AsString(lnode);
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseUnitType(ams,lbase);

  DeleteNode(p);
end;

function GetBaseIcon(ams:pointer; const fname:string):string;
var
  p,lnode:pointer;
  pcw:PWideChar;
  lbase:string;
  i:integer;
begin
  result:=GetTextValue(PModScanner(ams)^.db,'items','icon','file='+FixedText(fname));
  if result<>'' then exit;

  lbase :='';

  RGLog.Reserve('Check for icon '+fname);
  LoadFile(ams,fname,p);
  if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
    LoadFile(ams,fname+'.ADM',p);

  if p=nil then
  begin
    if RGDebugLevel=dlDetailed then
      RGLog.Add('can''t load: '+fname);
    exit;
  end;

  for i:=0 to GetChildCount(p)-1 do
  begin
    lnode:=GetChild(p,i);
    pcw:=GetNodeName(lnode);
    if CompareWide(pcw,'ICON')=0 then
    begin
      result:=AsString(lnode);
      break;
    end
    else if CompareWide(pcw,'BASEFILE')=0 then
    begin
      lbase:=AsString(lnode);
    end
    else if (result='') and (CompareWide(pcw,'GAMBLER_ICON')=0) then
    begin
      result:=AsString(lnode);
      break;
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseIcon(ams,lbase);

  DeleteNode(p);
end;

function AddItemNode(ams:pointer; anode:pointer; const fname:string; aquest:boolean):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  litem:tItemInfo;
  ls:string;
  i,ltmp:integer;
begin
  result:=0;

  FillChar(litem,SizeOf(litem),0);

  ls          :='';
  litem.usable:='0';
  litem.fname :=FixFileExt(fname);
  litem.stack :='1';

  if aquest then litem.quest:='1' else litem.quest:='0';

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    ltmp:=SetUnitInfo(lnode,@litem);
    if ltmp<0 then
    begin
      litem.modid:=CheckIdForMod(ams,'items', litem.id);
      if litem.modid='' then exit(4);
    end
    else if ltmp=0 then
    begin
      pcw:=GetNodeName(lnode);

           if CompareWide(pcw,'DESCRIPTION' )=0 then litem.descr  :=AsString(lnode)
      else if CompareWide(pcw,'USES'        )=0 then litem.usable :=AsString(lnode)
      else if CompareWide(pcw,'SET'         )=0 then litem.itemset:=AsString(lnode)
      else if CompareWide(pcw,'MAXSTACKSIZE')=0 then Str(AsInteger(lnode),litem.stack)
      else if CompareWide(pcw,'ICON'        )=0 then litem.icon:=ExtractNameOnly(AsString(lnode))
      else if CompareWide(pcw,'GAMBLER_ICON')=0 then ls        :=ExtractNameOnly(AsString(lnode))

      else if CompareWide(pcw,'ARMOR_ELECTRIC'    )=0 then litem.arm_electric :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_FIRE'        )=0 then litem.arm_fire     :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_ICE'         )=0 then litem.arm_ice      :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_PHYSICAL'    )=0 then litem.arm_physical :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_POISON'      )=0 then litem.arm_poison   :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMORMAX'          )=0 then litem.armormax     :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMORMIN'          )=0 then litem.armormin     :=AsInteger(lnode)
                                                                                               
      else if CompareWide(pcw,'DAMAGE_ELECTRIC'   )=0 then litem.dmg_electric :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_FIRE'       )=0 then litem.dmg_fire     :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_ICE'        )=0 then litem.dmg_ice      :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_PHYSICAL'   )=0 then litem.dmg_physical :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_POISON'     )=0 then litem.dmg_poison   :=AsInteger(lnode)
      else if CompareWide(pcw,'MAXDAMAGE'         )=0 then litem.maxdamage    :=AsInteger(lnode)
      else if CompareWide(pcw,'MINDAMAGE'         )=0 then litem.mindamage    :=AsInteger(lnode)
                                                                                               
      else if CompareWide(pcw,'DEFENSE_REQUIRED'  )=0 then litem.req_defense  :=AsInteger(lnode)
      else if CompareWide(pcw,'DEXTERITY_REQUIRED')=0 then litem.req_dexterity:=AsInteger(lnode)
      else if CompareWide(pcw,'LEVEL_REQUIRED'    )=0 then litem.req_level    :=AsInteger(lnode)
      else if CompareWide(pcw,'MAGIC_REQUIRED'    )=0 then litem.req_magic    :=AsInteger(lnode)
      else if CompareWide(pcw,'STRENGTH_REQUIRED' )=0 then litem.req_strength :=AsInteger(lnode)
                                                                              
      else if CompareWide(pcw,'LEVEL'             )=0 then litem.level        :=AsInteger(lnode)
      else if CompareWide(pcw,'SOCKETS'           )=0 then litem.sockets      :=AsInteger(lnode)
      else if CompareWide(pcw,'SPEED'             )=0 then litem.speed        :=AsInteger(lnode)
    end;

  end;
  if (litem.icon='') and (ls<>'') then litem.icon:=ls;

  if (litem.base<>'') then
  begin
    if (litem.unittype='') then litem.unittype:=GetBaseUnitType(ams,litem.base);
    if (litem.icon    ='') then litem.icon    :=ExtractNameOnly(GetBaseIcon(ams,litem.base));
  end;
  if litem.icon='' then result:=result or 1;

  if (litem.quest='0') and (
     (litem.unittype='LEVEL ITEM') or 
     (litem.unittype='QUESTITEM')) then
      litem.quest:='1';

  i:=AddItemToBase(ams,litem);
  if i=0 then result:=result or 2;
end;

function ProcessItems(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  ldir:string;
  i:integer;
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
{      if PModScanner(aparam)^.FRootLen>0 then
        ldir:=Copy(adir,PModScanner(aparam)^.FRootLen+2)
      else
}        ldir:=adir;
      i:=AddItemNode(aparam,p,
          ldir+aname,
          Pos('MEDIA/UNITS/ITEMS/QUEST_ITEMS',adir)>0);
      if ((i and 1)<>0) and (RGDebugLevel=dlDetailed) then RGLog.Add('No icon for '  +aname);

           if (i and 4)<>0 then result:=0
      else if (i and 2) =0 then result:=1
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanItems(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning items');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/ITEMS', @ProcessItems);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateItemsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'items') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE items ('+
      DefUnitDDL+
      '    descr         TEXT,'+
      '    itemset       TEXT,'+
      '    usable        INTEGER (1),'+
      '    quest         INTEGER (1),'+
      '    stack         INTEGER DEFAULT (1),'+
      '    icon          TEXT,'+
      '    level         INTEGER,'+
      '    sockets       INTEGER,'+
      '    speed         INTEGER,'+
      '    arm_electric  INTEGER,'+
      '    arm_fire      INTEGER,'+
      '    arm_ice       INTEGER,'+
      '    arm_physical  INTEGER,'+
      '    arm_poison    INTEGER,'+
      '    armormax      INTEGER,'+
      '    armormin      INTEGER,'+

      '    dmg_electric  INTEGER,'+
      '    dmg_fire      INTEGER,'+
      '    dmg_ice       INTEGER,'+
      '    dmg_physical  INTEGER,'+
      '    dmg_poison    INTEGER,'+
      '    maxdamage     INTEGER,'+
      '    mindamage     INTEGER,'+

      '    req_defense   INTEGER,'+
      '    req_dexterity INTEGER,'+
      '    req_level     INTEGER,'+
      '    req_magic     INTEGER,'+
      '    req_strength  INTEGER );')
  else
    result:=true;
end;

{%ENDREGION}
