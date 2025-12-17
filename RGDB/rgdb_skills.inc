{$IFDEF Interface}

function RGDBGetSkill(const aid:TRGID; out amods:string; out aname:string):string; overload;
function RGDBGetSkill(const aid:TRGID; out amods:string):string; overload;
function RGDBGetSkill(const aid:TRGID                  ):string; overload;
function RGDBGetSkill(const aname:string; out aid:TRGID):string; overload;

function RGDBGetSkillInfo(const aid:TRGID; out atier:string; out aicon:string):string;

//----- Skill list -----

// Get skill names list for class name separated by commas
// Recursion through base files
function RGDBGetSkillNames(const aclass:TRGID):string;

type
  tSkillArray = array of record
    id     : TRGID;
    name   : string;
    title  : string;
    tier   : string;
    icon   : string;
    level  : integer;
    learn  : integer;
    passive: char;
  end;

function RGDBGetSkillListPoints(const aclass:TRGID):integer;
function RGDBCreateSkillList   (const aclass:TRGID; out askills:tSkillArray):integer;
function RGDBCreateSpellList   (out askills:tSkillArray):integer;

{$ELSE}

//----- Base Skill Info -----

function RGDBGetSkill(const aid:TRGID; out amods:string; out aname:string):string;
begin
  result:=GetById(aid,'skills','',amods,aname);
end;

function RGDBGetSkill(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=RGDBGetSkill(aid,amods,lname);
end;

function RGDBGetSkill(const aid:TRGID):string;
var
  lmods :string;
  lname :string;
begin
  result:=RGDBGetSkill(aid,lmods,lname);
end;

function RGDBGetSkill(const aname:string; out aid:TRGID):string;
begin
  result:=GetByName(aname,'skills',aid);
end;

function RGDBGetSkillInfo(const aid:TRGID; out atier:string; out aicon:string):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';
  atier :='';
  aicon :='';

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT descr, tier, icon FROM skills WHERE id='''+lSQL+'''';

    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result :=sqlite3_column_text(vm,0);
        atier  :=sqlite3_column_text(vm,1);
        aicon  :=sqlite3_column_text(vm,2);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

//----- Skill List -----

procedure GetNextSkill(abase:integer; var askill:string);
var
  lSQL,lskill,lbase:string;
  vm:pointer;
begin
  Str(abase,lbase);
  lSQL:='SELECT c.skills, c.base FROM classes c, dicfiles f '+
        'WHERE f.id='+lbase+' AND f.file=c.file';

  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lskill:=sqlite3_column_text(vm,0);
      abase :=sqlite3_column_int (vm,1);
      if askill='' then askill:=lskill else askill:=askill+Copy(lskill,2);
    end
    else
      abase:=0;
    sqlite3_finalize(vm);
    if abase>0 then GetNextSkill(abase,askill);
  end;
end;

function RGDBGetSkillNames(const aclass:TRGID):string;
var
  lSQL,lid:string;
  lbase:integer;
  vm:pointer;
begin
  result:='';

  if db<>nil then
  begin
    Str(aclass,lid);
    lSQL:='SELECT skills, base FROM classes WHERE id='+lid;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        lbase :=sqlite3_column_int (vm,1);
      end
      else
        lbase :=0;
      sqlite3_finalize(vm);
      if lbase>0 then GetNextSkill(lbase,result);
      // not so necessary
      if (result<>'') and (result[1]=',') then result:=Copy(result,2);
    end;
  end;
end;

function RGDBGetSkillListPoints(const aclass:TRGID):integer;
var
  ls:string;
  pc:PChar;
  i:integer;
begin
  result:=0;
  ls:=RGDBGetSkillNames(aclass);
  if ls<>'' then
  begin
    pc:=pointer(ls);
    while pc^<>#0 do
    begin
      if pc^='#' then
      begin
        inc(pc);
        i:=0;
        while pc^ in ['0'..'9'] do
        begin
          i:=i*10+ORD(pc^)-ORD('0');
          inc(pc);
        end;
        inc(result,i);
        continue;
      end;
      inc(pc);
    end;
  end;
end;

function RGDBCreateSkillList(const aclass:TRGID; out askills:tSkillArray):integer;
var
  lwhere, lSQL,ls:string;
  ltmp:string[127];
  pc:PChar;
//  sl:TStringArray;
  vm:pointer;
  i,lvl{,lpos}:integer;
begin
  ls:=RGDBGetSkillNames(aclass);
  if ls<>'' then
  begin
    result:=SplitCountA(pointer(ls),',');
{    
    pc:=pointer(ls);
    if pc^=',' then inc(pc); // must be always
    i:=0;
    while pc^<>#0 do
    begin
      if pc^=',' then inc(i);
      inc(pc);
    end;
}
    SetLength(askills,result);

    if result>0 then
    begin
      if ModFilter<>'' then
        lwhere:=' AND '+ModFilter
      else
        lwhere:='';

      pc:=pointer(ls);
      if pc^=',' then inc(pc);
      ltmp:='';
      lvl :=0;
      i:=0;
      while pc^<>#0 do
      begin
        case pc^ of
          '#': begin
            inc(pc);
            while pc^ in ['0'..'9'] do
            begin
              lvl:=lvl*10+ORD(pc^)-ORD('0');
              inc(pc);
            end;
            continue;
          end;

          ',': begin
            lSQL:='SELECT id, title, maxlevel, tier, icon, passive FROM skills'+
                  ' WHERE (name LIKE '''+ltmp+''')'+lwhere;
            if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
            begin
              if sqlite3_step(vm)=SQLITE_ROW then
              begin
                askills[i].id     :=sqlite3_column_int64(vm,0);
                askills[i].title  :=sqlite3_column_text (vm,1);
                askills[i].level  :=sqlite3_column_int  (vm,2);
                askills[i].tier   :=sqlite3_column_text (vm,3);
                askills[i].icon   :=sqlite3_column_text (vm,4);
                askills[i].passive:=CHR(sqlite3_column_int(vm,5)+ORD('0'));
                askills[i].learn  :=lvl;
                inc(i);
              end;
              sqlite3_finalize(vm);
            end;
            ltmp:='';
            lvl :=0;
          end;
        else
          ltmp:=ltmp+pc^;
        end;
        inc(pc);
      end;
      if i<result then
      begin
        SetLength(askills,i);
        result:=i;
      end;
    end;
  end
  else
  begin
    SetLength(askills,0);
    result:=0;
  end;
end;

function RGDBCreateSpellList(out askills:tSkillArray):integer;
var
  lwhere, lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    if ModFilter<>'' then
      lwhere:=' AND '+ModFilter
    else
      lwhere:='';

    result:=ReturnInt(db,'SELECT count(*) FROM skills WHERE (shared<>0) AND (title<>'''')'+lwhere);

    if result>0 then
    begin
      SetLength(askills,result);
      lSQL:='SELECT id, name, title, maxlevel, icon FROM skills'+
            ' WHERE (shared<>0) AND (title<>'''')'+lwhere;
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while {(i<result) and} (sqlite3_step(vm)=SQLITE_ROW) do
        begin
          askills[i].id   :=sqlite3_column_int64(vm,0);
          askills[i].name :=sqlite3_column_text (vm,1);
          askills[i].title:=sqlite3_column_text (vm,2);
          askills[i].level:=sqlite3_column_int  (vm,3);
          askills[i].icon :=sqlite3_column_text (vm,4);
          inc(i);
        end;
        sqlite3_finalize(vm);
        exit;
      end;
    end;
  end;

  SetLength(askills,0);
  result:=0;
end;

{$ENDIF}
