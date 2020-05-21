{$IFDEF Interface}

function GetSkillList(aclass:TL2ID):string;

{$ELSE}

procedure GetNextSkill(const abase:string; var askill:string);
var
  aSQL,lskill,lbase:string;
  vm:pointer;
begin
  if db<>nil then
  begin
    aSQL:='SELECT skills, base FROM classes WHERE file='''+abase+'''';

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        lskill:=sqlite3_column_text(vm,0);
        lbase :=sqlite3_column_text(vm,1);
        if askill='' then askill:=lskill else askill:=askill+Copy(lskill,2);
      end;
      sqlite3_finalize(vm);
      if lbase<>'' then GetNextSkill(lbase,askill);
    end;
  end;

end;

function GetSkillList(aclass:TL2ID):string;
var
  aSQL,lskill,lbase:string;
  vm:pointer;
begin
  result:='';
  lbase :='';

  if db<>nil then
  begin
    Str(aclass,lbase);
    aSQL:='SELECT skills, base FROM classes WHERE id='''+lbase+'''';
    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        lbase :=sqlite3_column_text(vm,1);
      end;
      sqlite3_finalize(vm);
      if lbase<>'' then GetNextSkill(lbase,result);
    end;
  end;
end;

{$ENDIF}
