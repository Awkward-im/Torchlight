{%REGION Skills}

type
  tSkillInfo = record
    id     :string;
    name   :string;
    title  :string;
    descr  :string;
    graph  :string;
    icon   :string;
    minlvl :string;
    maxlvl :string;
    passive:char;
    shared :char;
  end;

function AddSkillToBase(ams:pointer; const askill:tSkillInfo):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckIdForMod(ams,'skills', askill.id);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO skills (id, name, title, descr, tier, icon,'+
          ' minlevel, maxlevel, passive, shared, modid) VALUES ('+
        askill.id+', '+FixedText(askill.name)+', '+FixedText(askill.title)+', '+FixedText(askill.descr)+
        ', '''+askill.graph+''', '+FixedText(askill.icon)+', '+
        askill.minlvl+', '+askill.maxlvl+', '+askill.passive+', '+askill.shared+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddSkillNode(ams:pointer; anode:pointer; ashared:boolean):boolean;
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
      if AddSkillNode(aparam,p,Pos('MEDIA/SKILLS/SHARED',adir)>0) then
        result:=1
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

function CreateSkillsTable(adb:PSQLite3):boolean;
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
      '    tier     TEXT,'+
      '    icon     TEXT,'+
      '    passive  INTEGER (1),'+
      '    shared   INTEGER (1) );')
  else
    result:=true;
end;

{%ENDREGION}
