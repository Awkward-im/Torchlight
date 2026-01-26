{$IFDEF Interface}

function GetTL2Skill(const aid:TRGID; out amods:string; out aname:string):string; overload;
function GetTL2Skill(const aid:TRGID; out amods:string):string; overload;
function GetTL2Skill(const aid:TRGID                  ):string; overload;
function GetTL2Skill(const aname:string; out aid:TRGID):string; overload;

function GetSkillInfo(const aid:TRGID; out atier:string; out aicon:string):string;

//----- Skill list -----

// Get skill names list for class name separated by commas
// Recursion through base files
function GetSkillNames(const aclass:TRGID):string;

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

function  GetSkillListPoints(const aclass:TRGID):integer;
procedure CreateSkillList   (const aclass:TRGID; out askills:tSkillArray);
procedure CreateSpellList   (out askills:tSkillArray);

{$ELSE}

//----- Base Skill Info -----

function GetTL2Skill(const aid:TRGID; out amods:string; out aname:string):string;
begin
  result:=GetById(aid,'skills','',amods,aname);
end;

function GetTL2Skill(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetTL2Skill(aid,amods,lname);
end;

function GetTL2Skill(const aid:TRGID):string;
var
  lmods :string;
  lname :string;
begin
  result:=GetTL2Skill(aid,lmods,lname);
end;

function GetTL2Skill(const aname:string; out aid:TRGID):string;
begin
  result:=GetByName(aname,'skills',aid);
end;

function GetSkillInfo(const aid:TRGID; out atier:string; out aicon:string):string;
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

procedure GetNextSkill(const abase:string; var askill:string);
var
  lSQL,lskill,lbase:string;
  vm:pointer;
begin
  lSQL:='SELECT skills, base FROM classes WHERE file='''+abase+'''';

  if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lskill:=sqlite3_column_text(vm,0);
      lbase :=sqlite3_column_text(vm,1);
      if askill='' then askill:=lskill else askill:=askill+Copy(lskill,2);
    end
    else
      lbase:='';
    sqlite3_finalize(vm);
    if lbase<>'' then GetNextSkill(lbase,askill);
  end;
end;

function GetSkillNames(const aclass:TRGID):string;
var
  lSQL,lbase:string;
  vm:pointer;
begin
  result:='';

  if db<>nil then
  begin
    Str(aclass,lbase);
    lSQL:='SELECT skills, base FROM classes WHERE id='+lbase;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        lbase :=sqlite3_column_text(vm,1);
      end
      else
        lbase :='';
      sqlite3_finalize(vm);
      if lbase<>'' then GetNextSkill(lbase,result);

      if result<>'' then result:=Copy(result,2,Length(result)-2);
    end;
  end;
end;

function GetSkillListPoints(const aclass:TRGID):integer;
var
//  sl:TStringArray;
  ls:string;
  pc:PChar;
  i{,ltmp}:integer;
begin
  result:=0;
  ls:=GetSkillNames(aclass);
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
{  
    sl:=ls.Split(',');

    for i:=0 to High(sl) do
    begin
      ltmp:=Pos('#',sl[i]);
      if ltmp>0 then
      begin
        Val(PChar(sl[i])+ltmp,ltmp);
        inc(result,ltmp);
      end;
    end;
}
  end;
end;

procedure CreateSkillList(const aclass:TRGID; out askills:tSkillArray);
var
  lSQL,ls:string;
  ltmp:string[127];
  pc:PChar;
//  sl:TStringArray;
  vm:pointer;
  i,lvl{,lpos}:integer;
begin
  ls:=GetSkillNames(aclass);
  if ls<>'' then
  begin
    i:=SplitCountA(pointer(ls),',');
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
    SetLength(askills,i);

    if i>0 then
    begin
      pc:=pointer(ls);
      if pc^=',' then inc(pc); // must be always
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
                  ' WHERE name LIKE '''+ltmp+'''';
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
      if i<Length(askills) then
        SetLength(askills,i);
    end;
{
    sl:=ls.Split(',');

    SetLength(askills,Length(sl));
    for i:=0 to High(sl) do
    begin
      ls:=sl[i];
      lpos:=Pos('#',ls);
      if lpos=0 then
      begin
        lvl:=0;
      end
      else
      begin
        Val(Copy(ls,  lpos+1),lvl);
        ls:=Copy(ls,1,lpos-1);
      end;
      
      lSQL:='SELECT id, title, maxlevel, tier, icon, passive FROM skills'+
            ' WHERE name LIKE '''+ls+'''';
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
        end;
        sqlite3_finalize(vm);
      end;
    end;
}
  end
  else
    SetLength(askills,0);
end;

procedure CreateSpellList(out askills:tSkillArray);
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    i:=0;
    lSQL:='SELECT count(*) FROM skills WHERE shared<>0 AND title<>''''';
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
      SetLength(askills,i);
      lSQL:='SELECT id, name, title, maxlevel, icon FROM skills'+
            ' WHERE shared<>0 AND title<>''''';
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
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
end;

{$ENDIF}
