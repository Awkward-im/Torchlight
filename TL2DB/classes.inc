{$IFDEF Interface}

function GetTL2Class(const aid:TL2ID; out amods:string;
                     out aname:string                 ):string; overload;
function GetTL2Class(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Class(const aid:TL2ID                  ):string; overload;
function GetTL2Class(const aname:string; out aid:TL2ID):string; overload;

function GetClassInfo(const aid:TL2ID; out aicon:string; out astr, adex, aint, avit:integer):string;

procedure GetClassGraphStat (const aid:TL2ID; out agraph_hp,agraph_mp:string; out agraph_stat:integer);
procedure GetClassGraphSkill(const aid:TL2ID; out agraph_skill,agraph_fame:integer);

{$ELSE}

const
  DefaultClasses: array [0..7] of record
    id   :TL2ID;
    name :string;
    title:string;
    str  :integer;
    dex  :integer;
    int  :integer;
    vit  :integer;
  end = (
    (id:122405618255168235  ; name:'Hum_Berserker_F'; title:'Berserker'; str:15; dex:15; int: 5; vit: 5),
    (id:220725756816796566  ; name:'Hum_Berserker_M'; title:'Berserker'; str:15; dex:15; int: 5; vit: 5),
    (id:808006122135163359  ; name:'Hum_Engineer_F' ; title:'Engineer' ; str:15; dex: 5; int: 5; vit:15),
    (id:808006126430130655  ; name:'Hum_Engineer_M' ; title:'Engineer' ; str:15; dex: 5; int: 5; vit:15),
    (id:808006130725097951  ; name:'Hum_Wanderer_F' ; title:'Outlander'; str:10; dex:15; int:10; vit: 5),
    (id:808006135020065247  ; name:'Hum_Wanderer_M' ; title:'Outlander'; str:10; dex:15; int:10; vit: 5),
    (id:-7248916694918249446; name:'Hum_Arbiter_F'  ; title:'Embermage'; str: 5; dex:10; int:15; vit:10),
    (id:3691889278338232797 ; name:'Hum_Arbiter_M'  ; title:'Embermage'; str: 5; dex:10; int:15; vit:10)
  );

function GetTL2Class(const aid:TL2ID; out amods:string; out aname:string):string;
var
  i:integer;
begin
  if db=nil then
  begin
    amods:='';
    for i:=0 to High(DefaultClasses) do
    begin
      if aid=DefaultClasses[i].id then
      begin
        aname :=DefaultClasses[i].name;
        result:=DefaultClasses[i].title;
        exit;
      end;
    end;
    aname :='';
    result:='';
  end
  else
    result:=GetById(aid,'classes','',amods,aname);
end;

function GetTL2Class(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetTL2Class(aid,amods,lname);
end;

function GetTL2Class(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Class(aid,lmods);
end;

function GetTL2Class(const aname:string; out aid:TL2ID):string;
var
  i:integer;
begin
  if db=nil then
  begin
    for i:=0 to High(DefaultClasses) do
    begin
      if aname=DefaultClasses[i].name then
      begin
        aid   :=DefaultClasses[i].id;
        result:=DefaultClasses[i].title;
        exit;
      end;
    end;
    aid   :=TL2IdEmpty;
    result:='';
  end
  else
    result:=GetByName(aname,'classes',aid);
end;

//----- Info -----

function GetClassInfo(const aid:TL2ID; out aicon:string; out astr, adex, aint, avit:integer):string;
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  result:='';
  aicon :='';
  astr  :=0;
  adex  :=0;
  aint  :=0;
  avit  :=0;

  if db=nil then
  begin
    for i:=0 to High(DefaultClasses) do
    begin
      if aid=DefaultClasses[i].id then
      begin
        astr:=DefaultClasses[i].str;
        adex:=DefaultClasses[i].dex;
        aint:=DefaultClasses[i].int;
        avit:=DefaultClasses[i].vit;
        break;
      end;
    end;
  end
  else
  begin
    Str(aid,lSQL);
    lSQL:='SELECT icon, descr, strengh, dexterity, magic, defense FROM classes WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        aicon :=sqlite3_column_text(vm,0);
        result:=sqlite3_column_text(vm,1);
        astr  :=sqlite3_column_int (vm,2);
        adex  :=sqlite3_column_int (vm,3);
        aint  :=sqlite3_column_int (vm,4);
        avit  :=sqlite3_column_int (vm,5);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure GetClassGraphStat(const aid:TL2ID; out agraph_hp,agraph_mp:string; out agraph_stat:integer);
var
  lSQL:string;
  vm:pointer;
begin
  agraph_hp  :='';
  agraph_mp  :='';
  agraph_stat:=DefStatPerLvl;

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT graph_hp, graph_mp, graph_stat FROM classes WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        agraph_hp  :=sqlite3_column_text(vm,0);
        agraph_mp  :=sqlite3_column_text(vm,1);
        agraph_stat:=StrToIntDef(GetGraph(sqlite3_column_text(vm,2)),DefStatPerLvl);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure GetClassGraphSkill(const aid:TL2ID; out agraph_skill,agraph_fame:integer);
var
  lSQL:string;
  vm:pointer;
begin
  agraph_skill:=DefSkillPerLvl;
  agraph_fame :=DefSkillPerFame;

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT graph_skill, graph_fame FROM classes WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        agraph_skill:=StrToIntDef(GetGraph(sqlite3_column_text(vm,0)),DefSkillPerLvl);
        agraph_fame :=StrToIntDef(GetGraph(sqlite3_column_text(vm,1)),DefSkillPerFame);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

{$ENDIF}