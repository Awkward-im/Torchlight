{%REGION Mobs}

{TODO: TL1: MEDIA/UNITS/MONSTERS/ UNITTYPE:PET}
{
PORTRAIT	STRING
LEVEL	INTEGER

MINDAMAGE	INTEGER
MAXDAMAGE	INTEGER
MINHP	FLOAT
MAXHP	FLOAT
MINLEVEL	INTEGER
MAXLEVEL	INTEGER

MESH	STRING
SHIELD_SCALE	FLOAT
WEAPON_SCALE	FLOAT
}
type
  TMobInfo = object(TBaseUnitInfo)
    armor_graph :string;
    damage_graph:string;
    dmgtype     :string;
    champion    :integer;
    armor       :integer;
    arm_physical:integer;
    arm_electric:integer;
    arm_fire    :integer;
    arm_ice     :integer;
    arm_poison  :integer;
    dmg_physical:integer;
    dmg_electric:integer;
    dmg_fire    :integer;
    dmg_ice     :integer;
    dmg_poison  :integer;
  end;

function AddMobToBase(ams:pointer; const ami:TMobInfo):integer;
var
  lSQL:string;
begin
  lSQL:='REPLACE INTO mobs ('+DefUnitColumns+
  ', armor_graph, damage_graph, dmgtype, champion, armor, '+
  'arm_physical, arm_electric, arm_fire, arm_ice, arm_poison, '+
  'dmg_physical, dmg_electric, dmg_fire, dmg_ice, dmg_poison) VALUES ('+
  GetDefUnitValues(ams,@ami)+', '''+ami.armor_graph+''', '''+ami.damage_graph+''', '''+ami.dmgtype+
  ''', '+IntToStr(ami.champion    )+', '+IntToStr(ami.armor       )+', '+IntToStr(ami.arm_physical)+
  ', '+IntToStr(ami.arm_electric)+', '+IntToStr(ami.arm_fire    )+', '+IntToStr(ami.arm_ice)+
  ', '+IntToStr(ami.arm_poison  )+', '+IntToStr(ami.dmg_physical)+', '+IntToStr(ami.dmg_electric)+
  ', '+IntToStr(ami.dmg_fire    )+', '+IntToStr(ami.dmg_ice     )+', '+IntToStr(ami.dmg_poison)+')';

  if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
    result:=1
  else
    result:=0;
end;

function AddMobNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  lnode:pointer;
  pcw:PWideChar;
  lmi:tmobinfo;
  i,ltmp:integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    lnode:=FindNode(anode,'UNITTYPE');
    if lnode<>nil then
    begin
      if CompareWide(AsString(lnode),'PET')=0 then
      begin
        result:=AddPetNode(ams,anode,fname);
        if result>0 then
          RGLog.Add('Added as pet');
        exit;
      end;
    end;
  end;

  FillChar(lmi,SizeOf(lmi),0);

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    ltmp:=SetUnitInfo(lnode,@lmi);
    if ltmp<0 then
    begin
      lmi.modid:=CheckIdForMod(ams,'mobs', lmi.id);
      if lmi.modid='' then exit(-1);
    end
    else if ltmp=0 then
    begin
      pcw:=GetNodeName(lnode);
           if CompareWide(pcw,'ARMOR_GRAPH'    )=0 then lmi.armor_graph :=AsString(lnode)
      else if CompareWide(pcw,'DAMAGE_GRAPH'   )=0 then lmi.damage_graph:=AsString(lnode)
      else if CompareWide(pcw,'DAMAGETYPE'     )=0 then lmi.dmgtype     :=AsString(lnode)
      else if CompareWide(pcw,'ARMOR'          )=0 then lmi.armor       :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_ELECTRIC' )=0 then lmi.arm_electric:=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_FIRE'     )=0 then lmi.arm_fire    :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_ICE'      )=0 then lmi.arm_ice     :=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_PHYSICAL' )=0 then lmi.arm_physical:=AsInteger(lnode)
      else if CompareWide(pcw,'ARMOR_POISON'   )=0 then lmi.arm_poison  :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_ELECTRIC')=0 then lmi.dmg_electric:=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_FIRE'    )=0 then lmi.dmg_fire    :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_ICE'     )=0 then lmi.dmg_ice     :=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_PHYSICAL')=0 then lmi.dmg_physical:=AsInteger(lnode)
      else if CompareWide(pcw,'DAMAGE_POISON'  )=0 then lmi.dmg_poison  :=AsInteger(lnode)
      else if CompareWide(pcw,'CHAMPION'       )=0 then begin if AsBool(lnode) then lmi.champion:=1 end
      else if CompareWide(pcw,'BOSS_CHAMPION'  )=0 then begin if AsBool(lnode) then lmi.champion:=2 end
    end;
  end;
        	
  lmi.fname:=FixFileExt(fname);
  result:=AddMobToBase(ams,lmi);
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
      result:=AddMobNode(aparam,p,adir+aname);
           if result>0 then result:=1
      else if result<0 then result:=0
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
      DefUnitDDL+
      '    armor_graph  TEXT,'+
      '    damage_graph TEXT,'+
      '    dmgtype      TEXT,'+
      '    champion     INTEGER,'+
      '    armor        INTEGER,'+
      '    arm_physical INTEGER,'+
      '    arm_electric INTEGER,'+
      '    arm_fire     INTEGER,'+
      '    arm_ice      INTEGER,'+
      '    arm_poison   INTEGER,'+
      '    dmg_physical INTEGER,'+
      '    dmg_electric INTEGER,'+
      '    dmg_fire     INTEGER,'+
      '    dmg_ice      INTEGER,'+
      '    dmg_poison   INTEGER );')
  else
    result:=true;
end;

{%ENDREGION}
