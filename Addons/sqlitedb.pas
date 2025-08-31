unit sqlitedb;

interface

uses
  sqlite3dyn;

function IsTableExists (db:PSQLite3; const aTable:AnsiString):boolean;
function IsColumnExists(db:PSQLite3; const aTable,aColumn:AnsiString):boolean;

function ExecSQLQuery (db:PSQLite3; const aSQL:AnsiString):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString                               ):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString;        aparam :PAnsiChar     ):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString;        aparam :PUnicodeChar  ):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; aparam,aparam2:PUnicodeChar  ):boolean;
function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; const  aparams:array of const):boolean;

function GetLastId(db:PSQLite3):integer; overload;
function GetLastId(db:PSQLite3; const atable,anid:AnsiString):integer; overload;

function CopyToFile  (db:PSQLite3; afname:PAnsiChar):integer;
function CopyFromFile(db:PSQLite3; afname:PAnsiChar):integer;

function  OpenDatabase(var db:PSQLite3; const aname:AnsiString):boolean;
procedure CloseDatabase(db:PSQLite3);

function BeginTransaction(db:PSQLite3):boolean;
function EndTransaction  (db:PSQLite3):boolean;

function GetTextValue(db:PSQLite3; const atable, afield, acond:string):string;
function ReturnText  (db:PSQLite3; const aSQL:AnsiString):string;

function GetIntValue(db:PSQLite3; const atable, afield, acond:string):integer;
function ReturnInt  (db:PSQLite3; const aSQL:AnsiString                               ):integer;
function ReturnInt  (db:PSQLite3; const aSQL:AnsiString;        aparam :PAnsiChar     ):integer;
function ReturnInt  (db:PSQLite3; const aSQL:AnsiString;        aparam :PUnicodeChar  ):integer;
function ReturnInt  (db:PSQLite3; const aSQL:AnsiString; aparam,aparam2:PUnicodeChar  ):integer;
function ReturnInt  (db:PSQLite3; const aSQL:AnsiString; const  aparams:array of const):integer;

const
  errNoDBFile  = -1000;
  errCantMemDB = -1001;
  errCantMapDB = -1002;

{
  if inmemory then trying to copy existing base to memory, or create new one
}
function LoadBase(var db:PSQLite3; const fname:AnsiString; inmemory:boolean=false):integer;
function SaveBase(    db:PSQLite3; const fname:AnsiString):integer;
function FreeBase(var db:PSQLite3):boolean;
function BaseInMemory(db:PSQLite3):boolean;

//======================================

implementation

function ProcessParameters(vm:pointer; const aparams:array of const):boolean;
var
  i,res:integer;
begin
  res:=SQLITE_OK;
  for i:=0 to High(aparams) do
  begin
    case aparams[i].VType of
      vtInteger      : res:=sqlite3_bind_int   (vm,i+1,aparams[i].VInteger);
      vtBoolean      : res:=sqlite3_bind_int   (vm,i+1,ORD(aparams[i].VBoolean));
      vtChar         : res:=sqlite3_bind_text  (vm,i+1,@aparams[i].VChar        , 1,SQLITE_STATIC);
      vtWideChar     : res:=sqlite3_bind_text16(vm,i+1,@aparams[i].VWideChar    , 2,SQLITE_STATIC);
      vtInt64,
      vtQWord        : res:=sqlite3_bind_int64 (vm,i+1,aparams[i].VInt64^);
      vtExtended     : res:=sqlite3_bind_double(vm,i+1,aparams[i].VExtended^);

      vtString       : res:=sqlite3_bind_text  (vm,i+1,PAnsiChar(aparams[i].VString)+1,
                                                Length(aparams[i].VString^)        ,SQLITE_STATIC);
      vtAnsiString   : res:=sqlite3_bind_text  (vm,i+1,aparams[i].VAnsiString   ,-1,SQLITE_STATIC);
      vtPChar        : res:=sqlite3_bind_text  (vm,i+1,aparams[i].VPChar        ,-1,SQLITE_STATIC);
      vtWideString   : res:=sqlite3_bind_text16(vm,i+1,aparams[i].VWideString   ,-1,SQLITE_STATIC);
      vtUnicodeString: res:=sqlite3_bind_text16(vm,i+1,aparams[i].VUnicodeString,-1,SQLITE_STATIC);
      vtPWideChar    : res:=sqlite3_bind_text16(vm,i+1,aparams[i].VPWideChar    ,-1,SQLITE_STATIC);
    end;
    if res<>SQLITE_OK then break;
  end;
  result:=res=SQLITE_OK;
end;

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

function ReturnInt(db:PSQLite3; const aSQL:AnsiString; aparam:PAnsiChar):integer;
var
  vm:pointer;
begin
  result:=-1;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_bind_text(vm,1,aparam,-1,SQLITE_STATIC)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int(vm,0);
    end;
    sqlite3_finalize(vm);
  end;
end;

function ReturnInt(db:PSQLite3; const aSQL:AnsiString; aparam:PUnicodeChar):integer;
var
  vm:pointer;
begin
  result:=-1;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_bind_text16(vm,1,aparam,-1,SQLITE_STATIC)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int(vm,0);
    end;
    sqlite3_finalize(vm);
  end;
end;

function ReturnInt(db:PSQLite3; const aSQL:AnsiString; aparam, aparam2:PUnicodeChar):integer;
var
  vm:pointer;
begin
  result:=-1;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if (sqlite3_bind_text16(vm,1,aparam ,-1,SQLITE_STATIC)=SQLITE_OK) and
       (sqlite3_bind_text16(vm,1,aparam2,-1,SQLITE_STATIC)=SQLITE_OK) then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int(vm,0);
    end;
    sqlite3_finalize(vm);
  end;
end;

function ReturnInt(db:PSQLite3; const aSQL:AnsiString; const aparams:array of const):integer;
var
  vm:pointer;
begin
  result:=-1;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if ProcessParameters(vm, aparams) then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
        result:=sqlite3_column_int(vm,0);
    end;
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
  result:=sqlite3_exec(db,PAnsiChar(aSQL),nil,nil,nil)=SQLITE_OK;
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

function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; aparam:PAnsiChar):boolean;
var
  vm: Pointer;
begin
  result:=false;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_bind_text(vm,1,aparam,-1,SQLITE_STATIC)=SQLITE_OK then
      result:=sqlite3_step(vm)=SQLITE_DONE;
    sqlite3_finalize(vm);
  end;
end;

function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; aparam:PUnicodeChar):boolean;
var
  vm: Pointer;
begin
  result:=false;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_bind_text16(vm,1,aparam,-1,SQLITE_STATIC)=SQLITE_OK then
      result:=sqlite3_step(vm)=SQLITE_DONE;
    sqlite3_finalize(vm);
  end;
end;

function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; aparam,aparam2:PUnicodeChar):boolean;
var
  vm: Pointer;
begin
  result:=false;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if (sqlite3_bind_text16(vm,1,aparam ,-1,SQLITE_STATIC)=SQLITE_OK) and
       (sqlite3_bind_text16(vm,1,aparam2,-1,SQLITE_STATIC)=SQLITE_OK) then
      result:=sqlite3_step(vm)=SQLITE_DONE;
    sqlite3_finalize(vm);
  end;
end;

function ExecuteDirect(db:PSQLite3; const aSQL:AnsiString; const aparams:array of const):boolean;
var
  vm: Pointer;
begin
  result:=false;
  if sqlite3_prepare_v2(db, PAnsiChar(aSQL), -1, @vm, nil)=SQLITE_OK then
  begin
    if ProcessParameters(vm,aparams) then
      result:=sqlite3_step(vm)=SQLITE_DONE;
    sqlite3_finalize(vm);
  end;
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

function CopyToFile(db:PSQLite3; afname:PAnsiChar):integer;
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

function CopyFromFile(db:PSQLite3; afname:PAnsiChar):integer;
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

function LoadBase(var db:PSQLite3; const fname:AnsiString; inmemory:boolean=false):integer;
var
  f:file of byte;
begin
  result:=-1;
  db:=nil;

  try
    InitializeSQlite();
    // avoid FPC package bug
    if pointer(sqlite3_db_filename)=nil then
    begin
      pointer(sqlite3_db_filename) := GetProcedureAddress(SQLiteLibraryHandle,'sqlite3_db_filename');
      pointer(sqlite3_db_readonly) := GetProcedureAddress(SQLiteLibraryHandle,'sqlite3_db_readonly');
    end;
  except
    exit;
  end;

  result:=SQLITE_OK;
  if inmemory then
  begin
    if sqlite3_open(':memory:',@db)=SQLITE_OK then
    begin
      {$I-}
      AssignFile(f,fname);
      Reset(f);
      if IOResult=0 then
    //  if FileExists(fname) then
      begin
        CloseFile(f);
        if db<>nil then
        begin
          try
            result:=CopyFromFile(db,PAnsiChar(fname));
          except
            result:=errCantMapDB;
          end;
        end;
      end
      else
        result:=errNoDBFile;
    end
    else
      result:=errCantMemDB
  end;

  if db=nil then
    sqlite3_open(PAnsiChar(fname),@db);
end;

function FreeBase(var db:PSQLite3):boolean;
begin
  if db<>nil then
  begin
    result:=sqlite3_close(db)=SQLITE_OK;
    db:=nil;
    ReleaseSqlite();
  end
  else
    result:=true;
end;

function SaveBase(db:PSQLite3; const fname:AnsiString):integer;
begin
  if BaseInMemory(db) then
    result:=CopyToFile(db,PAnsiChar(fname))
  else
    result:=SQLITE_OK;
end;

function BaseInMemory(db:PSQLite3):boolean; inline;
var
  pc:PAnsiChar;
begin
  pc:=sqlite3_db_filename(db,'main');
  result:=(pc=nil) or (pc^=#0);
end;

end.
