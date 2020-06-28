uses
  lazfileutils,
  awksqlite3,
  sysutils,
  sqlite3;

var
  db:PSQLite3;

procedure FixIcons(const abase:string);
var
  lSQL1,lSQL,licon:string;
  vm,vm1:pointer;
  id:int64;
begin
  lSQL:='SELECT id, icon FROM '+abase+
    ' WHERE instr(icon,''.'')<>0 OR instr(icon,''\'')<>0 OR instr(icon,''/'')<>0';
  
  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      id   :=sqlite3_column_int64(vm,0);
      licon:=sqlite3_column_text (vm,1);

      licon:=ExtractFilenameOnly(licon);

      LSQL1:='UPDATE '+abase+' SET base='''+licon+''', file='''++''' WHERE id='+IntToStr(id);
      if sqlite3_prepare_v2(db,PChar(lSQL1),-1,@vm1,nil)=SQLITE_OK then
      begin
        sqlite3_step(vm1);
        sqlite3_finalize(vm1);
      end;
    end;
    
    sqlite3_finalize(vm);
  end;
end;


begin
  sqlite3_open(':memory:',@db);
  if CopyFromFile(db,'tl2db2.db')<>SQLITE_OK then
  begin
    writeln('can''t open');
    exit;
  end;
  FixItems('items');


  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
