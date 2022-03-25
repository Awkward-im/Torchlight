{%REGION Classes}

type
  tclassinfo = record
    id       :string;
    name     :string;
    title    :string;
    descr    :string;
    afile    :string;
    base     :string;
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
  end;

function AddClassToBase(ams:pointer; const aclass:tclassinfo):boolean;
var
  lmodid,lSQL,lfile,lbase:string;
  i:integer;
begin
  result:=false;

  lmodid:=CheckForMod(ams,'classes', aclass.id, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lfile:=LowerCase(aclass.afile);
    for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
    lbase:=LowerCase(aclass.base);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';

    lSQL:='REPLACE INTO classes (id, name, title, descr,'+
          ' file, base, skills, icon,'+
          ' graph_hp, graph_mp, graph_stat, graph_skill, graph_fame,'+
          ' gender, strength, dexterity, magic, defense,'+
          ' modid) VALUES ('+
        aclass.id+', '+FixedText(aclass.name)+', '+FixedText(aclass.title)+', '+FixedText(aclass.descr)+
        ', '''+lfile+''', '''+lbase+''', '+FixedText(aclass.skill)+', '+FixedText(aclass.icon)+
        ', '''+aclass.gr_hp+''', '''+aclass.gr_mp+''', '''+aclass.gr_st+
        ''', '''+aclass.gr_sk+''', '''+aclass.gr_fm+''', '''+aclass.gender+
        ''', '+aclass.strength+', '+aclass.dexterity+', '+aclass.magic+', '+aclass.defense+
        ', '+lmodid+')';
    
    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

procedure GetGender(ams:pointer; const aclass,autype:string; out agender:string);
var
  p:pointer;
  pcw:PWideChar;
  i:integer;
begin
  agender:='';
  if autype<>'' then
  begin
    LoadFile(ams,'MEDIA/UNITTYPES/'+autype+'.DAT',p);
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

  if agender='' then
  begin
    i:=Length(aclass);
    if aclass[i-1]='_' then
    begin
      if UpCase(aclass[i])='M' then agender:='M';
      if UpCase(aclass[i])='F' then agender:='F';
    end;
  end;
end;

function AddClassNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  pp,lnode:pointer;
  pcw:PWideChar;
  lclass:tclassinfo;
  lunittype,lsname,lslevel:string;
  i,j:integer;
begin
  result:=0;
  lclass.afile:=fname;
  lclass.title:='';
  lclass.skill:=',';
  lclass.strength :='0';
  lclass.dexterity:='0';
  lclass.magic    :='0';
  lclass.defense  :='0';
  lunittype:='';

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    pcw:=GetNodeName(lnode);
    if GetNodeType(lnode)=rgGroup then
    begin
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
    end
    else if CompareWide(pcw,'BASEFILE'   )=0 then lclass.base :=AsString(lnode)
    else if CompareWide(pcw,'NAME'       )=0 then lclass.name :=AsString(lnode)
    else if CompareWide(pcw,'DISPLAYNAME')=0 then lclass.title:=AsString(lnode)
    else if CompareWide(pcw,'DESCRIPTION')=0 then lclass.descr:=AsString(lnode)
    else if CompareWide(pcw,'UNITTYPE'   )=0 then lunittype   :=AsString(lnode)
    else if CompareWide(pcw,'UNIT_GUID'  )=0 then lclass.id   :=AsString(lnode)
    else if CompareWide(pcw,'STRENGTH'   )=0 then Str(AsInteger(lnode),lclass.strength)
    else if CompareWide(pcw,'DEXTERITY'  )=0 then Str(AsInteger(lnode),lclass.dexterity)
    else if CompareWide(pcw,'MAGIC'      )=0 then Str(AsInteger(lnode),lclass.magic)
    else if CompareWide(pcw,'DEFENSE'    )=0 then Str(AsInteger(lnode),lclass.defense)
    else if CompareWide(pcw,'ICON'       )=0 then lclass.icon:=ExtractFileNameOnly(AsString(lnode))
    {TODO: Add files by name (from MEDIA/GRAPHS/STATS)}
    else if CompareWide(pcw,'MANA_GRAPH')=0 then
    begin
      lclass.gr_mp:=AsString(lnode);
      if UpCase(lclass.gr_mp)<>'MANA_PLAYER_GENERIC' then
        RGLog.Add('Add '+lclass.gr_mp+' for class MP please');
    end
    else if CompareWide(pcw,'HEALTH_GRAPH')=0 then
    begin
      lclass.gr_hp:=AsString(lnode);
      if UpCase(lclass.gr_hp)<>'HEALTH_PLAYER_GENERIC' then
        RGLog.Add('Add '+lclass.gr_hp+' for class HP please');
    end
    else if CompareWide(pcw,'STAT_POINTS_PER_LEVEL')=0 then
    begin
      lclass.gr_st:=AsString(lnode);
      if UpCase(lclass.gr_st)<>'STAT_POINTS_PER_LEVEL' then
        RGLog.Add('Add '+lclass.gr_st+' for class STAT please');
    end
    else if CompareWide(pcw,'SKILL_POINTS_PER_LEVEL')=0 then
    begin
      lclass.gr_sk:=AsString(lnode);
      if UpCase(lclass.gr_sk)<>'SKILL_POINTS_PER_LEVEL' then
        RGLog.Add('Add '+lclass.gr_sk+' for class SKILL please');
    end
    else if CompareWide(pcw,'SKILL_POINTS_PER_FAME_LEVEL')=0 then
    begin
      lclass.gr_fm:=AsString(lnode);
      if UpCase(lclass.gr_fm)<>'SKILL_POINTS_PER_FAME_LEVEL' then
        RGLog.Add('Add '+lclass.gr_fm+' for class FAME please');
    end;

  end;

  {TODO: search for base unittype if not found}
  // Search class gender
  GetGender(ams, lclass.name, lunittype, lclass.gender);
  if lclass.skill=',' then lclass.skill:='';
  if AddClassToBase(ams,lclass) then
    result:=1;
end;

function ProcessClasses(
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
    {TODO: remove root dir from 'adir'}
    if AddClassNode(aparam,p,adir+'/'+aname)<>0 then
      result:=1
    else
      RGLog.Add('can''t update '+aname);

    DeleteNode(p);
  end;
end;

function ScanClasses(ams:pointer):integer;
begin
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/PLAYERS', @ProcessClasses);
end;

function CreateClassesTable(ams:pointer):boolean;
begin
  if not IsTableExists(PModScanner(ams)^.db,'classes') then
    result:=ExecuteDirect(PModScanner(ams)^.db,
      'CREATE TABLE classes ('+
      '    id          INTEGER PRIMARY KEY,'+
      '    name        TEXT,'+
      '    title       TEXT,'+
      '    modid       TEXT,'+
      '    descr       TEXT,'+
      '    file        TEXT,'+
      '    base        TEXT,'+
      '    skills      TEXT,'+
      '    gender      CHAR,'+
      '    icon        TEXT,'+
      '    graph_hp    TEXT,'+
      '    graph_mp    TEXT,'+
      '    graph_stat  TEXT,'+
      '    graph_skill TEXT,'+
      '    graph_fame  TEXT,'+
      '    strength    INTEGER,'+
      '    dexterity   INTEGER,'+
      '    magic       INTEGER,'+
      '    defense     INTEGER );');
end;

{%ENDREGION}
