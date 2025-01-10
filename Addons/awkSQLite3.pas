unit awkSQLite3;

interface

uses
  SQLite3Dyn;

{$DEFINE Interface}

function IsTableExists (db:PSQLite3; const aTable:AnsiString):boolean;
function IsColumnExists(db:PSQLite3; const aTable,aColumn:AnsiString):boolean;

function ExecSQLQuery (db:PSQLite3; const aSQL:AnsiString):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString):boolean;

function GetLastId(db:PSQLite3):integer; overload;
function GetLastId(db:PSQLite3; const atable,anid:AnsiString):integer; overload;

function CopyToFile  (db:PSQLite3; afname:PChar):integer;
function CopyFromFile(db:PSQLite3; afname:PChar):integer;

function  OpenDatabase(var db:PSQLite3; const aname:AnsiString):boolean;
procedure CloseDatabase(db:PSQLite3);

function BeginTransaction(db:PSQLite3):boolean;
function EndTransaction  (db:PSQLite3):boolean;

function GetTextValue(db:PSQLite3; const atable, afield, acond:string):string;
function ReturnText  (db:PSQLite3; const aSQL:AnsiString):string;
function GetIntValue (db:PSQLite3; const atable, afield, acond:string):integer;
function ReturnInt   (db:PSQLite3; const aSQL:AnsiString):integer;

{$UNDEF Interface}

implementation


function GetTextValue(db:PSQLite3; const atable, afield, acond:string):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';
  if db<>nil then
  begin
    lSQL:='SELECT '+afield+' FROM '+atable+' WHERE '+acond;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function ReturnText(db:PSQLite3; const aSQL:AnsiString):string;
var
  vm:pointer;
begin
  result:='';
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result:=sqlite3_column_text(vm,0);
    sqlite3_finalize(vm);
  end;
end;

function GetIntValue(db:PSQLite3; const atable, afield, acond:string):integer;
var
  lSQL:string;
  vm:pointer;
begin
  result:=-1;

  if db<>nil then
  begin
    lSQL:='SELECT '+afield+' FROM '+atable+' WHERE '+acond;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function ReturnInt(db:PSQLite3; const aSQL:AnsiString):integer;
var
  vm:pointer;
begin
  result:=-1;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result:=sqlite3_column_int(vm,0);
    sqlite3_finalize(vm);
  end;
end;

function IsTableExists(db:PSQLite3; const aTable:AnsiString):boolean;
begin
  result:=ReturnInt(db,
    'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' AND name = '''+aTable+'''')>0;
end;

function IsColumnExists(db:PSQLite3; const aTable,aColumn:AnsiString):boolean;
begin
  result:=ReturnInt(db,
    'SELECT COUNT(*) FROM pragma_table_info('''+aTable+''') WHERE name='''+aColumn+'''')>0;
end;

//----- Retrieve Last ID -----

function GetLastId(db:PSQLite3; const atable, anid:AnsiString):integer;
begin
  result:=ReturnInt(db,
    'SELECT '+anid+' FROM '+atable+' ORDER BY '+anid+' DESC LIMIT 1');
end;

function GetLastId(db:PSQLite3):integer;
begin
  result:=sqlite3_last_insert_rowid(db);
end;

//----- Execute SQL -----

function ExecSQLQuery(db:PSQLite3; const aSQL:AnsiString):boolean;
begin
  result:=sqlite3_exec(db,PChar(aSQL),nil,nil,nil)=SQLITE_OK;
end;

function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString):boolean;
var
  vm: Pointer;
begin
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    result:=sqlite3_step(vm)=SQLITE_DONE;
    sqlite3_finalize(vm);
  end
  else
    result:=false;
end;

//----- Transaction -----

function BeginTransaction(db:PSQLite3):boolean;
begin
  result:=ExecuteDirect(db, 'Begin Transaction');
end;

function EndTransaction(db:PSQLite3):boolean;
begin
  result:=ExecuteDirect(db, 'End Transaction');
end;

//----- Backup (copy) -----

function CopyToFile(db:PSQLite3; afname:PChar):integer;
var
  pFile  :PSQLite3;        // Database connection opened on zFilename
  pBackup:PSQLite3Backup;  // Backup object used to copy data
begin
  result:=sqlite3_open(afname, @pFile);
  if result=SQLITE_OK then
  begin
    pBackup:=sqlite3_backup_init(pFile, 'main', db, 'main');
    if pBackup<>nil then
    begin
      sqlite3_backup_step  (pBackup, -1);
      sqlite3_backup_finish(pBackup);
    end;
    result:=sqlite3_errcode(pFile);
  end;
  sqlite3_close(pFile);
end;

function CopyFromFile(db:PSQLite3; afname:PChar):integer;
var
  pFile  :PSQLite3;        // Database connection opened on zFilename
  pBackup:PSQLite3Backup;  // Backup object used to copy data
begin
  result:=sqlite3_open_v2(afname, @pFile, SQLITE_OPEN_READONLY, nil);
  if result=SQLITE_OK then
  begin
    pBackup:=sqlite3_backup_init(db, 'main', pFile, 'main');
    if pBackup<>nil then
    begin
      sqlite3_backup_step  (pBackup, -1);
      sqlite3_backup_finish(pBackup);
    end;
    result:=sqlite3_errcode(db);
  end;
  sqlite3_close(pFile);
end;

//----- Init/Free -----

procedure CloseDatabase(db:PSQLite3);
begin
  sqlite3_close(db);
end;

function OpenDatabase(var db:PSQLite3; const aname:AnsiString):boolean;
begin
  result:=sqlite3_open(pointer(aname),@db)=SQLITE_OK;
end;


procedure InitDatabase;
begin
end;

procedure FreeDatabase;
begin
end;

initialization

  InitDatabase;

finalization

  FreeDatabase;

end.
