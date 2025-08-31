{TODO: TL1 don't have gender info. need to fix GetList code}

{$IFDEF Interface}

type
  tClassArray  = array of record
    id    :TRGID;
    name  :string;
    title :string;
    icon  :string;
    gender:char;
  end;

function RGDBGetClass(const aid:TRGID; out amods:string;
                      out aname:string                 ):string; overload;
function RGDBGetClass(const aid:TRGID; out amods:string):string; overload;
function RGDBGetClass(const aid:TRGID                  ):string; overload;
function RGDBGetClass(const aname:string; out aid:TRGID):string; overload;

function RGDBGetClassName(const aid:TRGID):string;
function RGDBGetClassMods(const aid:TRGID):string;
function RGDBGetClassIcon(const aid:TRGID):string;
function RGDBGetClassInfo(const aid:TRGID; out aicon:string; out astr, adex, aint, avit:integer):string;

function RGDBGetClassWardrobe(const aid:TRGID):string;

procedure RGDBGetClassGraphStat (const aid:TRGID; out agraph_hp,agraph_mp:string; out agraph_stat:integer);
procedure RGDBGetClassGraphSkill(const aid:TRGID; out agraph_skill,agraph_fame:integer);

function RGDBGetClassList(out alist:tClassArray):integer;

{$ELSE}

const
  dbClassTable = 'classes';

type
  TDefClassInfo = record
    id    :TRGID;
    name  :string;
    title :string;
    icon  :string;
    gender:char;
    str   :integer;
    dex   :integer;
    int   :integer;
    vit   :integer;

  end;
const
  tl1classstart = 8;
  tl1classlen   = 3;
  tl2classstart = 0;
  tl2classlen   = 8;
  DefaultClasses: array [0..10] of TDefClassInfo = (
    // TL2 classes
    (id:122405618255168235  ; name:'Hum_Berserker_F'; title:'Berserker' ; icon:'berserkericonfemale';
     gender:'F'; str:15; dex:15; int: 5; vit: 5),
    (id:220725756816796566  ; name:'Hum_Berserker_M'; title:'Berserker' ; icon:'berserkericonmale'  ;
     gender:'M'; str:15; dex:15; int: 5; vit: 5),
    (id:808006122135163359  ; name:'Hum_Engineer_F' ; title:'Engineer'  ; icon:'engineericonfemale' ;
     gender:'F'; str:15; dex: 5; int: 5; vit:15),
    (id:808006126430130655  ; name:'Hum_Engineer_M' ; title:'Engineer'  ; icon:'engineericonmale'   ;
     gender:'M'; str:15; dex: 5; int: 5; vit:15),
    (id:808006130725097951  ; name:'Hum_Wanderer_F' ; title:'Outlander' ; icon:'wanderericonfemale' ;
     gender:'F'; str:10; dex:15; int:10; vit: 5),
    (id:808006135020065247  ; name:'Hum_Wanderer_M' ; title:'Outlander' ; icon:'wanderericonmale'   ;
     gender:'M'; str:10; dex:15; int:10; vit: 5),
    (id:-7248916694918249446; name:'Hum_Arbiter_F'  ; title:'Embermage' ; icon:'arbitericonfemale'  ;
     gender:'F'; str: 5; dex:10; int:15; vit:10),
    (id:3691889278338232797 ; name:'Hum_Arbiter_M'  ; title:'Embermage' ; icon:'arbitericonmale'    ;
     gender:'M'; str: 5; dex:10; int:15; vit:10),
    // TL1 classes
    (id:-8268919844649954850; name:'Alchemist'      ; title:'Alchemist' ; icon:'alchemisticon'      ;
     gender:'U'; str: 6; dex: 7; int:10; vit: 5),
    (id:-3195029503589936674; name:'Destroyer'      ; title:'Destroyer' ; icon:'destroyericon'      ;
     gender:'U'; str:10; dex: 4; int: 3; vit:10),
    (id:-6176919150526066210; name:'Vanquisher'     ; title:'Vanquisher'; icon:'vanquishericon'     ;
     gender:'U'; str: 5; dex:10; int: 7; vit: 6)
  );

function RGDBGetClassName(const aid:TRGID):string;
var
  lmod:string;
begin
  RGDBGetClass(aid,lmod,result);
end;

function RGDBGetClass(const aid:TRGID; out amods:string; out aname:string):string;
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
    result:=GetById(aid,dbClassTable,'',amods,aname);
end;

function RGDBGetClass(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=RGDBGetClass(aid,amods,lname);
end;

function RGDBGetClass(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetClass(aid,lmods);
end;

function RGDBGetClass(const aname:string; out aid:TRGID):string;
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
    aid   :=RGIdEmpty;
    result:='';
  end
  else
    result:=GetByName(aname,dbClassTable,aid);
end;

function RGDBGetClassMods(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbClassTable,'modid');
end;

function RGDBGetClassWardrobe(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbClassTable,'wardrobe');
end;

function RGDBGetClassIcon(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,dbClassTable,'icon');
end;

//----- Info -----

function RGDBGetClassInfo(const aid:TRGID; out aicon:string; out astr, adex, aint, avit:integer):string;
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
    lSQL:='SELECT icon, descr, strength, dexterity, magic, defense FROM '+dbClassTable+
          ' WHERE id='+lSQL;
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

procedure RGDBGetClassGraphStat(const aid:TRGID; out agraph_hp,agraph_mp:string; out agraph_stat:integer);
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
    lSQL:='SELECT graph_hp, graph_mp, graph_stat FROM '+dbClassTable+
          ' WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        agraph_hp  :=sqlite3_column_text(vm,0);
        agraph_mp  :=sqlite3_column_text(vm,1);
        Val(RGDBGetGraph(sqlite3_column_text(vm,2)),agraph_stat,i);
        if i>0 then agraph_stat:=DefStatPerLvl;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure RGDBGetClassGraphSkill(const aid:TRGID; out agraph_skill,agraph_fame:integer);
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
    lSQL:='SELECT graph_skill, graph_fame FROM '+dbClassTable+
          ' WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        Val(RGDBGetGraph(sqlite3_column_text(vm,0)),agraph_skill,i); if i>0 then agraph_skill:=DefSkillPerLvl;
        Val(RGDBGetGraph(sqlite3_column_text(vm,1)),agraph_fame ,i); if i>0 then agraph_fame :=DefSkillPerFame;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;


//----- List -----

function RGDBGetClassList(out alist:tClassArray):integer;
var
  lwhere,lSQL:string;
  vm:pointer;
  i,lfrom:integer;
begin
  if db<>nil then
  begin
    // no gender support for TL1 so check by name only
    if GameVersion=verTL1 then
      lwhere:=' WHERE NOT (file LIKE ''%base.dat'')'
    else
    begin
      lwhere:=' WHERE (gender<>'''')';
      if ModFilter<>'' then
        lwhere:=lwhere+' AND '+ModFilter;
    end;

    result:=ReturnInt(db,'SELECT count(*) FROM '+dbClassTable+lwhere);

    if result>0 then
    begin
      SetLength(alist,result);
      lSQL:='SELECT id, name, title, icon, gender FROM '+dbClassTable+lwhere;

      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while {(i<result) and} (sqlite3_step(vm)=SQLITE_ROW) do
        begin
          alist[i].id    :=sqlite3_column_int64(vm,0);
          alist[i].name  :=sqlite3_column_text (vm,1);
          alist[i].title :=sqlite3_column_text (vm,2);
          alist[i].icon  :=sqlite3_column_text (vm,3);
          if GameVersion=verTL1 then
            alist[i].gender:='?'
          else
            alist[i].gender:=sqlite3_column_text(vm,4)^;
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end
  else
  begin
    if GameVersion=verTL1 then
    begin
      lfrom :=tl1classstart;
      result:=tl1classlen;
    end
    else
    begin
      lfrom :=tl2classstart;
      result:=tl2classlen;
    end;

    SetLength(alist,result);
    for i:=0 to result-1 do
    begin
      alist[i].id    :=DefaultClasses[lfrom+i].id;
      alist[i].name  :=DefaultClasses[lfrom+i].name;
      alist[i].title :=DefaultClasses[lfrom+i].title;
      alist[i].icon  :=DefaultClasses[lfrom+i].icon;
      alist[i].gender:=DefaultClasses[lfrom+i].gender;
    end;
  end;
end;

{$ENDIF}
