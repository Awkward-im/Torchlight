{%REGION Classes}
type
  TClassInfo = object(TBaseUnitInfo)
    descr    :string;
    skill    :string;
    icon     :string;
    gr_hp    :string;
    gr_mp    :string;
    gr_st    :string;
    gr_sk    :string;
    gr_fm    :string;
    strength :string;
    dexterity:string;
    magic    :string;
    defense  :string;
    gender   :string;
    wardrobe :string;
    sh_scale :string;
    wpn_scale:string;
    armor    :string;
  end;

function AddClassToBase(ams:pointer; const aclass:TClassInfo):integer;
var
  lSQL:string;
begin
  lSQL:='REPLACE INTO classes ('+DefUnitColumns+
        ', descr, skills, icon,'+
        ' graph_hp, graph_mp, graph_stat, graph_skill, graph_fame,'+
        ' gender, strength, dexterity, magic, defense,'+
        ' wardrobe, armor, shld_scale, wpn_scale) VALUES ('+
      GetDefUnitValues(ams,@aclass)+', '+
      FixedText(aclass.descr)+', '+FixedText(aclass.skill)+', '+FixedText(aclass.icon)+
        ', '''+aclass.gr_hp+''', '''+aclass.gr_mp+''', '''+aclass.gr_st+
      ''', '''+aclass.gr_sk+''', '''+aclass.gr_fm+''', '''+aclass.gender+
      ''', '+aclass.strength+', '+aclass.dexterity+', '+aclass.magic+', '+aclass.defense+
      ', '+FixedText(aclass.wardrobe)+
      ', '+aclass.armor+', '+aclass.sh_scale+', '+aclass.wpn_scale+')';
  
  if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
    result:=1
  else
    result:=0;
end;

procedure GetGender(ams:pointer; const aclass,autype:string; out agender:string);
var
  p:pointer;
  pcw:PWideChar;
  ls:string;
  i:integer;
  c:AnsiChar;
begin
  agender:='';
  // 1 - from Database
  if autype<>'' then
  begin
    ls:=GetTextValue(PModScanner(ams)^.db,'unittypes','child','name='''+autype+'''');
    if ls<>'' then
    begin
           if Pos(',PLAYER_MALE,'  ,ls)>0 then agender:='M'
      else if Pos(',PLAYER_FEMALE,',ls)>0 then agender:='F';
      exit;
    end;
  end;

  // 2 - Fast way (by name)
  i:=Length(aclass);
  if aclass[i-1]='_' then
  begin
    c:=aclass[i];
    if (c='M') or (c='m') then begin agender:='M'; exit; end;
    if (c='F') or (c='f') then begin agender:='F'; exit; end;
  end;

  // 3 - Slow way (by UNITTYPE)
  if autype<>'' then
  begin
    RGLog.Reserve('Check for gender unittype '+autype);
    LoadFile(ams,'MEDIA/UNITTYPES/'+autype+'.DAT',p);
    if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
      LoadFile(ams,'MEDIA/UNITTYPES/'+autype+'.DAT.ADM',p);

    if p<>nil then
    begin
      for i:=0 to GetChildCount(p)-1 do
      begin
        pcw:=AsString(GetChild(p,i));
        if CompareWide(pcw,'PLAYER_FEMALE')=0 then
        begin
          agender:='F';
          break;
        end
        else if CompareWide(pcw,'PLAYER_MALE')=0 then
        begin
          agender:='M';
          break;
        end
      end;
      DeleteNode(p);
    end;
  end;

end;

function GetBaseTitle(ams:pointer; const fname:string):string;
var
  p,lnode:pointer;
  pcw:PWideChar;
  lbase:string;
  i:integer;
begin
  result:=GetTextValue(PModScanner(ams)^.db,'classes','title','file='+FixedText(fname));
  if result<>'' then exit;

  lbase :='';

  RGLog.Reserve('Check for title '+fname);
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
    if CompareWide(pcw,'DISPLAYNAME')=0 then
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
    result:=GetBaseTitle(ams,lbase);

  DeleteNode(p);
end;

function AddClassNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  pp,lnode:pointer;
  pcw:PWideChar;
  lclass:tclassinfo;
  lsname,lslevel:string;
  i,j:integer;
  lbasic:boolean;
begin
  FillChar(lclass,SizeOf(lclass),0);
  lclass.wardrobe :=',';
  lclass.strength :='0';
  lclass.dexterity:='0';
  lclass.magic    :='0';
  lclass.defense  :='0';
  lclass.armor    :='0';
  lclass.sh_scale :='1.0';
  lclass.wpn_scale:='1.0';

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    if GetNodeType(lnode)=rgGroup then
    begin
      pcw:=GetNodeName(lnode);

      if CompareWide(pcw,'SKILL')=0 then
      begin
        lsname :='';
        lslevel:='';
        for j:=0 to GetChildCount(lnode)-1 do
        begin
          pp:=GetChild(lnode,j);
          pcw:=GetNodeName(pp);
          if      CompareWide(pcw,'NAME' )=0 then lsname:=AsString(pp)
          else if CompareWide(pcw,'LEVEL')=0 then Str(AsInteger(pp),lslevel);
        end;

        if lsname<>'' then
        begin
          if lslevel<>'' then lsname:=lsname+'#'+lslevel;
          lclass.skill:=lclass.skill+lsname+',';
        end;
      end;
      if CompareWide(pcw,'WARDROBE_FEATUREOPTIONS')=0 then
      begin
        // cycle through "FEATUREOPTION"
        for j:=0 to GetChildCount(lnode)-1 do
        begin
          pp:=FindNode(GetChild(lnode,j),'VALUE');
          if pp<>nil then
            lclass.wardrobe:=lclass.wardrobe+IntToStr(AsInteger64(pp))+',';
        end;
      end;
    end
    else
    begin
      j:=SetUnitInfo(lnode,@lclass);
      if j<0 then
      begin
        lclass.modid:=CheckIdForMod(ams,'classes', lclass.id);
        if lclass.modid='' then exit(-1);
      end
      else if j=0 then
      begin
        pcw:=GetNodeName(lnode);

        if      CompareWide(pcw,'DESCRIPTION' )=0 then lclass.descr:=AsString(lnode)
        else if CompareWide(pcw,'ICON'        )=0 then lclass.icon:=ExtractNameOnly(AsString(lnode))
        else if CompareWide(pcw,'STRENGTH'    )=0 then Str(AsInteger(lnode),lclass.strength)
        else if CompareWide(pcw,'DEXTERITY'   )=0 then Str(AsInteger(lnode),lclass.dexterity)
        else if CompareWide(pcw,'MAGIC'       )=0 then Str(AsInteger(lnode),lclass.magic)
        else if CompareWide(pcw,'DEFENSE'     )=0 then Str(AsInteger(lnode),lclass.defense)
        else if CompareWide(pcw,'ARMOR'	      )=0 then Str(AsInteger(lnode),lclass.armor)
        else if CompareWide(pcw,'SHIELD_SCALE')=0 then Str(AsFloat(lnode):0:2,lclass.sh_scale)
        else if CompareWide(pcw,'WEAPON_SCALE')=0 then Str(AsFloat(lnode):0:2,lclass.wpn_scale)

        else if CompareWide(pcw,'MANA_GRAPH')=0 then
        begin
          lclass.gr_mp:=AsString(lnode);
          if UpCase(lclass.gr_mp)<>'MANA_PLAYER_GENERIC' then
          begin
            ScanGraph(ams,lclass.gr_mp,10);
            if RGDebugLevel=dlDetailed then
              RGLog.Add('Mana graph is '+lclass.gr_mp);
          end
        end

        else if CompareWide(pcw,'HEALTH_GRAPH')=0 then
        begin
          lclass.gr_hp:=AsString(lnode);
          if UpCase(lclass.gr_hp)<>'HEALTH_PLAYER_GENERIC' then
          begin
            ScanGraph(ams,lclass.gr_hp,10);
            if RGDebugLevel=dlDetailed then
              RGLog.Add('Health graph is '+lclass.gr_hp);
          end
        end

        else if CompareWide(pcw,'STAT_POINTS_PER_LEVEL')=0 then
        begin
          lclass.gr_st:=AsString(lnode);
          if UpCase(lclass.gr_st)<>'STAT_POINTS_PER_LEVEL' then
          begin
            ScanGraph(ams,lclass.gr_st,1);
            if RGDebugLevel=dlDetailed then
              RGLog.Add('Stat point per level graph is '+lclass.gr_st);
          end
        end

        else if CompareWide(pcw,'SKILL_POINTS_PER_LEVEL')=0 then
        begin
          lclass.gr_sk:=AsString(lnode);
          if UpCase(lclass.gr_sk)<>'SKILL_POINTS_PER_LEVEL' then
          begin
            ScanGraph(ams,lclass.gr_sk,1);
            if RGDebugLevel=dlDetailed then
              RGLog.Add('Skill points per level graph is '+lclass.gr_sk);
          end
        end

        else if CompareWide(pcw,'SKILL_POINTS_PER_FAME_LEVEL')=0 then
        begin
          lclass.gr_fm:=AsString(lnode);
          if UpCase(lclass.gr_fm)<>'SKILL_POINTS_PER_FAME_LEVEL' then
          begin
            ScanGraph(ams,lclass.gr_fm,1);
            if RGDebugLevel=dlDetailed then
              RGLog.Add('Skill points per fame level graph is '+lclass.gr_fm);
          end
        end;
      end;
    end;

  end;

  if lclass.title='' then
    lclass.title:=GetBaseTitle(ams,lclass.base);
  
  // no gender info in TL1
  if (PModScanner(ams)^.gamever=verTL1) then
    lclass.gender:='U'
  else
  begin
    GetGender(ams, lclass.name, lclass.unittype, lclass.gender);
//    if lclass.gender='' then lclass.gender:='U';
  end;

  if lclass.skill=',' then lclass.skill:='';
  lclass.fname:=FixFileExt(fname);

  // some optimization
  if (lclass.gender='') or (lclass.icon='') then
    lbasic:=IsBase(lclass.name,fname);

  if (lclass.gender='') and (not lbasic) then
      RGLog.Add('Unknown gender for '+lclass.name);

  if (lclass.icon='') and (not lbasic) {and (PModScanner(ams)^.gamever=verTL1)} then
  begin
    lclass.icon:=LowerCase(lclass.name+'icon');
    RGLog.Add('No icon name for '+lclass.name+'. Set it as '+lclass.icon);
  end;

  result:=AddClassToBase(ams, lclass);
end;

function ProcessClasses(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  ldir:string;
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
{      if PModScanner(aparam)^.FRootLen>0 then
        ldir:=Copy(adir,PModScanner(aparam)^.FRootLen+2)
      else
}        ldir:=adir;
      lres:=AddClassNode(aparam,p,ldir+aname);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanClasses(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning classes');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/PLAYERS', @ProcessClasses);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateClassesTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'classes') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE classes ('+
      DefUnitDDL+
      '    descr       TEXT,'+
      '    skills      TEXT,'+
      '    gender      CHAR,'+
      '    icon        TEXT,'+
      '    rating      INTEGER DEFAULT 0,'+
      '    graph_hp    TEXT,'+
      '    graph_mp    TEXT,'+
      '    graph_stat  TEXT,'+
      '    graph_skill TEXT,'+
      '    graph_fame  TEXT,'+
      '    strength    INTEGER,'+
      '    dexterity   INTEGER,'+
      '    magic       INTEGER,'+
      '    defense     INTEGER,'+
      '    wardrobe    TEXT,'+
      '    armor       INTEGER,'+
      '    shld_scale  REAL,'+
      '    wpn_Scale   REAL);')
  else
    result:=true;
end;

{%ENDREGION}
