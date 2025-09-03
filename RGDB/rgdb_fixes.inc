{$IFDEF Interface}

function RGDBFixAll:integer;

function RGDBFixEmptyClassTitles():integer;

{$ELSE}

function RGDBFixEmptyClassTitles():integer;
var
  vm:pointer;
  ltitle:PAnsiChar;
  lmodc,lmods:TInt64DynArray;
  ls:string;
  i,j:integer;
  lfound:boolean;
begin
  result:=0;
  ls:='SELECT c.id, s.title, c.modid, s.modid FROM classes c'+
    '  INNER JOIN classes s ON s.file=f.file'+
    '  INNER JOIN dicfiles f ON f.id=c.base'+
    '  WHERE (c.title='''')';// and c.modid=s.modid'; // don't work, must cross, not equal
  if sqlite3_prepare_v2(db, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      ltitle:=sqlite3_column_text(vm,1);
      if (ltitle<>nil) and (ltitle^<>#0) then
      begin
        // trying to get cross between two mods strings
        lmodc:=splitInt64(sqlite3_column_text(vm,2),' ');
        lmods:=splitInt64(sqlite3_column_text(vm,3),' ');
        lfound:=false;
        for i:=0 to High(lmodc) do
        begin
          for j:=0 to High(lmods) do
          begin
            lfound:=lmodc[i]=lmods[j];
            if lfound then break;
          end;
          if lfound then break;
        end;
        if lfound then
        begin
          Str(sqlite3_column_int64(vm,0),ls);
          if ExecuteDirect(db,
            'UPDATE classes SET title=?1'+
            ' WHERE id='+ls,ltitle) then inc(result);
        end;
      end;
    end;
    sqlite3_finalize(vm);
  end;

end;

function RGDBFixAll:integer;
begin
  result:=RGDBFixEmptyClassTitles();
end;

{$ENDIF}

