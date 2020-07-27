unit tl2db;

interface

uses
  tl2types;

{$DEFINE Interface}

{$Include tl2db_skills.inc}

{$Include tl2db_movies.inc}

{$Include tl2db_items.inc}

{$Include tl2db_classes.inc}

{$Include tl2db_pets.inc}

{$Include tl2db_settings.inc}

{$Include tl2db_recipes.inc}

{$Include tl2db_mods.inc}

{$Include tl2db_stats.inc}

{$Include tl2db_keys.inc}

function GetTL2Quest(const aid:TL2ID; out amods:string; out aname:string):string; overload;
function GetTL2Quest(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Quest(const aid:TL2ID                  ):string; overload;

function GetTL2Mob  (const aid:TL2ID; out amods:string):string; overload;
function GetTL2Mob  (const aid:TL2ID                  ):string; overload;
function GetMobMods (const aid:TL2ID):string;

function GetTextValue(const aid:TL2ID; const abase, afield:string):string;
function GetIntValue (const aid:TL2ID; const abase, afield:string):integer;

procedure SetFilter(amods:TTL2ModList);
procedure SetFilter(amods:TL2IdList);
procedure RestFilter;
function  IsInModList(const alist:string; aid:TL2ID        ):boolean; overload;
function  IsInModList(const alist:string; amods:TTL2ModList):TL2ID  ; overload;
function  IsInModList(aid:TL2ID         ; amods:TTL2ModList):boolean; overload;

function  LoadBases(const fname:string=''):integer;
procedure FreeBases;

//======================================

{$UNDEF Interface}

implementation

uses
//  sysutils,
  sqlite3dyn;

var
  db:PSQLite3=nil;
  ModFilter:string='';

const
  TL2DataBase = 'tl2db2.db';

//----- Support functions -----

{$Include tl2db_split.inc}

//----- Core functions -----

function GetById(const id:TL2ID; const abase:string; const awhere:string;
                 out amod:string; out aname:string):string;
var
  aSQL,lwhere:string;
  vm:pointer;
begin
  amod  :='';
  aname :='';
  result:=HexStr(id,16);

  if db<>nil then
  begin
    Str(id,aSQL);
    if awhere<>'' then
      lwhere:=' AND '+awhere
    else
      lwhere:='';
    aSQL:='SELECT title,modid,name FROM '+abase+' WHERE id='+aSQL+lwhere+' LIMIT 1';

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
        amod  :=sqlite3_column_text(vm,1);
        aname :=sqlite3_column_text(vm,2);
        if result='' then
          result:=aname;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetByName(const aname:string; const abase:string; out id:TL2ID):string;
var
  aSQL:string;
  vm:pointer;
begin
  id    :=TL2IdEmpty;
  result:=aname;

  if db<>nil then
  begin
    aSQL:='SELECT id,title FROM '+abase+' WHERE name LIKE '''+aname+'''';

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        id    :=sqlite3_column_int64(vm,0);
        result:=sqlite3_column_text (vm,1);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetTextValue(const aid:TL2ID; const abase, afield:string):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';
  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT '+afield+' FROM '+abase+' WHERE id='+lSQL;
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

function GetIntValue(const aid:TL2ID; const abase, afield:string):integer;
var
  lSQL:string;
  vm:pointer;
begin
  result:=-1;

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT '+afield+' FROM '+abase+' WHERE id='+lSQL;
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

//----- Movie Info -----

{$Include tl2db_movies.inc}

//----- Skill info -----

{$Include tl2db_skills.inc}

//----- Item info -----

{$Include tl2db_items.inc}

//----- Class info -----

{$Include tl2db_classes.inc}

//----- Pet info -----

{$Include tl2db_pets.inc}

//----- Recipes -----

{$Include tl2db_recipes.inc}

//----- Stat info -----

{$Include tl2db_stats.inc}

//----- Mod info -----

{$Include tl2db_mods.inc}

//===== Key binding =====

{$Include tl2db_keys.inc}


{$Include tl2db_settings.inc}

//----- Quests -----

function GetTL2Quest(const aid:TL2ID; out amods:string; out aname:string):string;
begin
  result:=GetById(aid,'quests','',amods,aname);
end;

function GetTL2Quest(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetTL2Quest(aid,amods,lname);
end;

function GetTL2Quest(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Quest(aid,lmods);
end;

//----- Mob info -----

function GetTL2Mob(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'mobs','',amods,lname);
end;

function GetTL2Mob(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Mob(aid,lmods);
end;

function GetMobMods(const aid:TL2ID):string;
begin
  result:=GetTextValue(aid,'mobs','modid');
end;

//===== Database load =====

function CopyToFile(db:PSQLite3; afname:PChar):integer;
var
  pFile  :PSQLite3;
  pBackup:PSQLite3Backup;
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
  pFile  :PSQLite3;
  pBackup:PSQLite3Backup;
begin
  result:=sqlite3_open(afname, @pFile);
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

function LoadBases(const fname:string=''):integer;
var
  f:file of byte;
  lfname:string;
begin
  result:=-1;
  db:=nil;

  try
    InitializeSQlite();
  except
    exit;
  end;

  if fname='' then lfname:=TL2DataBase else lfname:=fname;

{$I-}
  AssignFile(f,lfname);
  Reset(f);
  if IOResult=0 then
//  if FileExists(lfname) then
  begin
    CloseFile(f);
    if sqlite3_open(':memory:',@db)=SQLITE_OK then
    begin
      try
        result:=CopyFromFile(db,PChar(lfname));
      except
        sqlite3_close(db);
        db:=nil;
        result:=-1002;
      end;
    end
    else
      result:=-1001;
  end
  else
    result:=-1000;
end;

procedure FreeBases;
begin
  if db<>nil then sqlite3_close(db);
  ReleaseSqlite;
end;


procedure SetFilter(amods:TTL2ModList);
var
  ls:string;
  i:integer;
begin
  ModFilter:='((modid='' 0 '')';
  if amods<>nil then
  begin
    for i:=0 to High(amods) do
    begin
      Str(amods[i].id,ls);
      ModFilter:=ModFilter+' OR (instr(modid,'' '+ls+' '')>0)';
    end;
  end;
  ModFilter:=ModFilter+')';
end;

procedure SetFilter(amods:TL2IdList);
var
  ls:string;
  i:integer;
begin
  ModFilter:='((modid='' 0 '')';
  if amods<>nil then
  begin
    for i:=0 to High(amods) do
    begin
      Str(amods[i],ls);
      ModFilter:=ModFilter+' OR (instr(modid,'' '+ls+' '')>0)';
    end;
  end;
  ModFilter:=ModFilter+')';
end;

procedure RestFilter;
begin
  ModFilter:='';
end;

function IsInModList(const alist:string; aid:TL2ID):boolean;
var
  ls:string;
begin
  result:=true;

  if alist=TL2GameID then exit;

  Str(aid,ls);
  if Pos(' '+ls+' ',alist)<=0 then
    result:=false;
end;

function IsInModList(const alist:string; amods:TTL2ModList):TL2ID;
var
  ls:string;
  i:integer;
begin
  if alist=TL2GameID then
  begin
    result:=0;
    exit;
  end;

  for i:=0 to High(amods) do
  begin
    Str(amods[i].id,ls);
    if Pos(' '+ls+' ',alist)>0 then
    begin
      result:=amods[i].id;
      exit;
    end;
  end;

  result:=TL2IdEmpty;
end;

function IsInModList(aid:TL2ID; amods:TTL2ModList):boolean;
var
  i:integer;
begin
  for i:=0 to High(amods) do
  begin
    if aid=amods[i].id then
    begin
      result:=true;
      exit;
    end;
  end;
  result:=false;
end;

finalization
//  ReleaseSqlite;

end.
