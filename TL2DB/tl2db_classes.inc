{$IFDEF Interface}

type
  tClassArray  = array of record
    id    :TL2ID;
    name  :string;
    title :string;
    icon  :string;
    gender:char;
  end;

function GetTL2Class(const aid:TL2ID; out amods:string;
                     out aname:string                 ):string; overload;
function GetTL2Class(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Class(const aid:TL2ID                  ):string; overload;
function GetTL2Class(const aname:string; out aid:TL2ID):string; overload;

function GetClassMods(const aid:TL2ID):string;

function GetClassIcon(const aid:TL2ID):string;

function GetClassInfo(const aid:TL2ID; out aicon:string; out astr, adex, aint, avit:integer):string;

procedure GetClassGraphStat (const aid:TL2ID; out agraph_hp,agraph_mp:string; out agraph_stat:integer);
procedure GetClassGraphSkill(const aid:TL2ID; out agraph_skill,agraph_fame:integer);

procedure GetClassList(out alist:tClassArray);

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

function GetClassMods(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,'classes','modid');
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

function GetClassIcon(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,'classes','icon');
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
    lSQL:='SELECT icon, descr, strength, dexterity, magic, defense FROM classes WHERE id='+lSQL;
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
  i:integer;
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
        Val(GetGraph(sqlite3_column_text(vm,2)),agraph_stat,i);
        if i>0 then agraph_stat:=DefStatPerLvl;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure GetClassGraphSkill(const aid:TL2ID; out agraph_skill,agraph_fame:integer);
var
  lSQL:string;
  vm:pointer;
  i:integer;
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
        Val(GetGraph(sqlite3_column_text(vm,0)),agraph_skill,i); if i>0 then agraph_skill:=DefSkillPerLvl;
        Val(GetGraph(sqlite3_column_text(vm,1)),agraph_fame ,i); if i>0 then agraph_fame :=DefSkillPerFame;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;


//----- List -----

procedure GetClassList(out alist:tClassArray);
var
  lwhere,lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    if ModFilter<>'' then
      lwhere:=' AND '+ModFilter
    else
      lwhere:='';

    i:=0;
    lSQL:='SELECT count(*) FROM classes WHERE gender<>'''''+lwhere;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;

    if i>0 then
    begin
      SetLength(alist,i);
      lSQL:='SELECT id, name, title, icon, gender FROM classes WHERE gender<>'''''+lwhere;

      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          alist[i].id    :=sqlite3_column_int64(vm,0);
          alist[i].name  :=sqlite3_column_text (vm,1);
          alist[i].title :=sqlite3_column_text (vm,2);
          alist[i].icon  :=sqlite3_column_text (vm,3);
          alist[i].gender:=sqlite3_column_text (vm,4)^;
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end
  else
  begin
    SetLength(alist,Length(DefaultClasses));
    for i:=0 to High(DefaultClasses) do
    begin
      alist[i].id    :=DefaultClasses[i].id;
      alist[i].name  :=DefaultClasses[i].name;
      alist[i].title :=DefaultClasses[i].title;
      alist[i].icon  :='';
      alist[i].gender:=DefaultClasses[i].name[Length(DefaultClasses[i].name)];
    end;
  end;
end;

{$ENDIF}
