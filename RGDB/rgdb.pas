{TODO: put code into class to use gamever and db fields in several bases at same time}

unit rgdb;

interface

uses
  sqlite3dyn,
  rgglobal;

{$DEFINE Interface}

{$Include rgdb_fixes.inc}

{$Include rgdb_skills.inc}

{$Include rgdb_movies.inc}

{$Include rgdb_items.inc}

{$Include rgdb_classes.inc}

{$Include rgdb_pets.inc}

{$Include rgdb_settings.inc}

{$Include rgdb_recipes.inc}

{$Include rgdb_mods.inc}

{$Include rgdb_stats.inc}

{$Include rgdb_keys.inc}

{$Include rgdb_effects.inc}

{$Include rgdb_other.inc}

function RGDBGetTextValue(const aid:TRGID; const atable, afield:string):string;
function RGDBGetIntValue (const aid:TRGID; const atable, afield:string):integer;

function RGDBGetBase(const aid:TRGID; const atable:string):TRGID;
procedure RGDBSetFilter(amods:TTL2ModList);
procedure RGDBSetFilter(amods:TL2IdList);
procedure RGDBResetFilter;
function  RGDBIsInModList(const alist:string; aid:TRGID        ):boolean; overload;
function  RGDBIsInModList(const alist:string; amods:TTL2ModList):TRGID  ; overload;
function  RGDBIsInModList(aid:TRGID         ; amods:TTL2ModList):boolean; overload;

const
  errRGDBNoDBFile  = -1000;
  errRGDBCantMemDB = -1001;
  errRGDBCantMapDB = -1002;

function  RGDBLoadBase(const fname:string=''):integer;
procedure RGDBFreeBase;
procedure RGDBUseBase(adb:pointer);

var
  GameVersion:integer;

//======================================

{$UNDEF Interface}

implementation

uses
  sqlitedb;

var
  db:PSQLite3=nil;
  ModFilter:string='';


//----- Core functions -----

function RGDBGetBase(const aid:TRGID; const atable:string):TRGID;
var
  vm:pointer;
  ls:string;
begin
  result:=-1;

  Str(aid,ls);
  ls:='SELECT t.id FROM '+atable+' s'+
           ' INNER JOIN '+atable+' t ON t.file=f.file'+
           ' INNER JOIN   dicfiles f ON f.id  =s.base'+
           ' WHERE s.id='+ls;
  if sqlite3_prepare_v2(db, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      result:=sqlite3_column_int64(vm,0);
    sqlite3_finalize(vm);
  end;
end;

function GetById(const id:TRGID; const atable:string; const awhere:string;
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
    aSQL:='SELECT title,modid,name FROM '+atable+' WHERE id='+aSQL+lwhere+' LIMIT 1';

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

function GetByName(const aname:string; const atable:string; out id:TRGID):string;
var
  aSQL:string;
  vm:pointer;
begin
  id    :=RGIdEmpty;
  result:=aname;

  if db<>nil then
  begin
    aSQL:='SELECT id,title FROM '+atable+' WHERE name LIKE '''+aname+'''';

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

function RGDBGetTextValue(const aid:TRGID; const atable, afield:string):string;
var
  ls:string;
begin
  Str(aid,ls);
  result:=GetTextValue(db,atable,afield,'id='+ls);
end;

function RGDBGetIntValue(const aid:TRGID; const atable, afield:string):integer;
var
  ls:string;
begin
  Str(aid,ls);
  result:=GetIntValue(db,atable,afield,'id='+ls);
end;

//---- Database fixes ----

{$Include rgdb_fixes.inc}

//----- Movie Info -----

{$Include rgdb_movies.inc}

//----- Skill info -----

{$Include rgdb_skills.inc}

//----- Item info -----

{$Include rgdb_items.inc}

//----- Class info -----

{$Include rgdb_classes.inc}

//----- Pet info -----

{$Include rgdb_pets.inc}

//----- Recipes -----

{$Include rgdb_recipes.inc}

//----- Stat info -----

{$Include rgdb_stats.inc}

//----- Mod info -----

{$Include rgdb_mods.inc}

//===== Key binding =====

{$Include rgdb_keys.inc}

//----- Effects -----

{$Include rgdb_effects.inc}

{$Include rgdb_settings.inc}

{$Include rgdb_other.inc}

//-----  -----

procedure RGDBSetFilter(amods:TTL2ModList);
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

procedure RGDBSetFilter(amods:TL2IdList);
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

procedure RGDBResetFilter;
begin
  ModFilter:='';
end;

function RGDBIsInModList(const alist:string; aid:TRGID):boolean;
var
  ls:string;
begin
  result:=true;

  if alist=TL2GameID then exit;

  Str(aid,ls);
  if Pos(' '+ls+' ',alist)<=0 then
    result:=false;
end;

function RGDBIsInModList(const alist:string; amods:TTL2ModList):TRGID;
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

  result:=RGIdEmpty;
end;

function RGDBIsInModList(aid:TRGID; amods:TTL2ModList):boolean;
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

//===== Database load =====

procedure SetupGameVer;
var
  lSQL:string;
  vm:pointer;
begin
  GameVersion:=verUnk;

  if db<>nil then
  begin
    lSQL:='SELECT version FROM mods WHERE (id=0)';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        case sqlite3_column_int(vm,0) of
          1: GameVersion:=verTL1;
          2: GameVersion:=verTL2;
        else
          GameVersion:=verUnk;
        end;
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function RGDBLoadBase(const fname:string=''):integer;
begin
  if fname='' then result:=LoadBase(db,TL2DataBase) else result:=LoadBase(db,fname);
  if result=SQLITE_OK then SetupGameVer;
end;

procedure RGDBUseBase(adb:pointer);
begin
  if db<>nil then sqlite3_close(db);
  db:=adb;
  SetupGameVer;
end;

procedure RGDBFreeBase;
begin
  FreeBase(db);
  GameVersion:=verUnk;
end;


initialization

  GameVersion:=verUnk;

finalization
//  ReleaseSqlite;

end.
