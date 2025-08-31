{%REGION Skills}

type
  tSkillInfo = record
    id     :string;
    name   :PUnicodeChar;
    title  :PUnicodeChar;
    descr  :PUnicodeChar;
    tier1  :PUnicodeChar;
    tier2  :PUnicodeChar;
    tier3  :PUnicodeChar;
    icon   :PUnicodeChar;
    graph  :string;
//    fname  :string;
    minlvl :string;
    maxlvl :string;
    passive:char;
    shared :char;
  end;

function AddSkillToBase(ams:pointer; const askill:tSkillInfo):integer;
var
  lmodid:string;
begin
  lmodid:=CheckIdForMod(ams,'skills', askill.id);
  if lmodid<>'' then
  begin
    if ExecuteDirect(PModScanner(ams)^.db,
        'REPLACE INTO skills (id, name, title, descr, graph, icon,'+
        ' minlevel, maxlevel, passive, shared, modid'+
        ', tier1, tier2, tier3'+
        ') VALUES ('+
        askill.id+', ?1, ?2, ?3, '''+askill.graph+''', ?4, '+
        askill.minlvl+', '+askill.maxlvl+', '+askill.passive+', '+askill.shared+', '+lmodid+
        ', ?5, ?6, ?7'+
        ')',
        [askill.name , askill.title, askill.descr, askill.icon
        ,askill.tier1, askill.tier2, askill.tier3
        ]) then
      result:=1
    else
      result:=0;
  end
  else
  begin
    result:=-1;
    if RGDebugLevel=dlDetailed then RGLog.Add('Looks like ID '+askill.id+' used already');
  end;
end;

function AddSkillNode(ams:pointer; anode:pointer; ashared:boolean):integer;
var
  pp,ppp:pointer;
  pcw:PWideChar;
  lskill:TSkillInfo;
  levels:array [0..63] of integer;
  ls:string;
  minlevel,i,j,lcnt:integer;
  haslevels:boolean;
begin
  fillchar(levels,SizeOf(levels),0);
  fillchar(lskill,sizeof(lskill),0);

  lskill.passive:='0';
  lskill.minlvl :='0';

  lcnt:=0;
  haslevels:=false;
  minlevel:=0;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    pp:=GetChild(anode,i);
    pcw:=GetNodeName(pp);

    if (GetNodeType(pp)=rgGroup) then
    begin
      if CompareWide('LEVEL',pcw,5)=0 then
//      if Pos('LEVEL',WideString(pcw))=1 then
      begin
        for j:=0 to GetChildCount(pp)-1 do
        begin
          ppp:=GetChild(pp,j);
          if CompareWide(GetNodeName(ppp),'LEVEL_REQUIRED')=0 then
          begin
            levels[lcnt]:=asInteger(ppp);
            if minlevel>levels[lcnt] then minlevel:=levels[lcnt];
            if levels[lcnt]>0 then
              haslevels:=true;
          end;
        end;
        inc(lcnt);
      end;
    end
    else if CompareWide(pcw,'NAME'             )=0 then lskill.name :=AsString(pp)
    else if CompareWide(pcw,'DISPLAYNAME'      )=0 then lskill.title:=AsString(pp)
    else if CompareWide(pcw,'DESCRIPTION'      )=0 then lskill.descr:=AsString(pp)
    else if CompareWide(pcw,'TIER1'            )=0 then lskill.tier1:=AsString(pp)
    else if CompareWide(pcw,'TIER2'            )=0 then lskill.tier2:=AsString(pp)
    else if CompareWide(pcw,'TIER3'            )=0 then lskill.tier3:=AsString(pp)
    else if CompareWide(pcw,'BASE_DESCRIPTION' )=0 then lskill.descr:=AsString(pp)
    else if CompareWide(pcw,'REQUIREMENT_GRAPH')=0 then lskill.graph:=AsString(pp)
    else if CompareWide(pcw,'SKILL_ICON'       )=0 then lskill.icon :=AsString(pp)
    else if CompareWide(pcw,'LEVEL_REQUIRED'   )=0 then Str(AsInteger  (pp),lskill.minlvl)
    else if CompareWide(pcw,'UNIQUE_GUID'      )=0 then Str(AsInteger64(pp),lskill.id)
    else if CompareWide(pcw,'ACTIVATION_TYPE'  )=0 then
    begin
      if CompareWide(AsString(pp),'PASSIVE')=0 then
        lskill.passive:='1';
    end;
  end;

  if lskill.minlvl='0' then
  begin
    if minlevel=0 then
    begin
      pp:=FindNode(anode,'LEVEL1/EVENT_TRIGGER/AFFIXES/AFFIXLEVEL');
      if pp<>nil then
        minlevel:=AsInteger(pp);
    end;
    if minlevel<0 then minlevel:=0;
    Str(minlevel,lskill.minlvl);
  end;

  if lcnt=0 then
    lcnt:=1;
  Str(lcnt,lskill.maxlvl);

  if (lskill.graph='') and haslevels then
  begin
    lskill.graph:=',';
    for i:=0 to lcnt-1 do
    begin
      Str(levels[i],ls);
      lskill.graph:=lskill.graph+ls+',';
    end;
  end;

  if ashared then lskill.shared:='1' else lskill.shared:='0';

  result:=AddSkillToBase(ams,lskill);
end;

function ProcessSkills(
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
      lres:=AddSkillNode(aparam,p,Pos('MEDIA/SKILLS/SHARED',adir)>0);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanSkills(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning skills');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/SKILLS', @ProcessSkills);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateSkillsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'skills') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE skills ('+
      '    id       INTEGER PRIMARY KEY,'+
      '    name     TEXT,'+
      '    title    TEXT,'+
      '    modid    TEXT,'+
      '    descr    TEXT,'+
      '    minlevel INTEGER,'+
      '    maxlevel INTEGER,'+
      '    graph    TEXT,'+
      '    icon     TEXT,'+
      '    tier1    TEXT,'+
      '    tier2    TEXT,'+
      '    tier3    TEXT,'+
//      '    file     TEXT,'+
      '    passive  INTEGER (1),'+
      '    shared   INTEGER (1) );')
  else
    result:=true;
end;

{%ENDREGION}
