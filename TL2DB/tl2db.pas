unit tl2db;

interface

uses
  sqlite3dyn,
  rgglobal;

{$DEFINE Interface}

{$Include db_common.inc}

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

{$Include tl2db_effects.inc}

function GetUnitTheme(const aid:TRGID):string;

function GetTL2Quest(const aid:TRGID; out amods:string; out aname:string):string; overload;
function GetTL2Quest(const aid:TRGID; out amods:string):string; overload;
function GetTL2Quest(const aid:TRGID                  ):string; overload;

function GetTL2Mob  (const aid:TRGID; out amods:string):string; overload;
function GetTL2Mob  (const aid:TRGID                  ):string; overload;
function GetMobMods (const aid:TRGID):string;

type
  TWardrobeData = array of record
    id:integer;
    _type:string; // integer;
    name:string;
  end;

procedure GetWardrobe(var award:TWardrobeData);

function GetTextValue(const aid:TRGID; const atable, afield:string):string;
function GetIntValue (const aid:TRGID; const atable, afield:string):integer;

procedure SetFilter(amods:TTL2ModList);
procedure SetFilter(amods:TL2IdList);
procedure ResetFilter;
function  IsInModList(const alist:string; aid:TRGID        ):boolean; overload;
function  IsInModList(const alist:string; amods:TTL2ModList):TRGID  ; overload;
function  IsInModList(aid:TRGID         ; amods:TTL2ModList):boolean; overload;

const
  errRGDBNoDBFile  = -1000;
  errRGDBCantMemDB = -1001;
  errRGDBCantMapDB = -1002;

function  LoadBases(const fname:string=''):integer;
procedure FreeBases;
procedure UseBase(adb:pointer);

var
  GameVersion:integer;

//======================================

{$UNDEF Interface}

implementation

{$Include db_common.inc}

var
  db:PSQLite3=nil;
  ModFilter:string='';


//----- Core functions -----

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

function GetTextValue(const aid:TRGID; const atable, afield:string):string;
var
  ls:string;
{
  lSQL:string;
  vm:pointer;
}
begin
  Str(aid,ls);
  result:=GetTextValue(db,atable,afield,'id='+ls);
{
  result:='';
  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT '+afield+' FROM '+atable+' WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
}
end;

function GetIntValue(const aid:TRGID; const atable, afield:string):integer;
var
  ls:string;
{
  lSQL:string;
  vm:pointer;
}
begin
  Str(aid,ls);
  result:=GetIntValue(db,atable,afield,'id='+ls);
{
  result:=-1;

  if db<>nil then
  begin
    Str(aid,lSQL);
    lSQL:='SELECT '+afield+' FROM '+atable+' WHERE id='+lSQL;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
}
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

//----- Effects -----

{$Include tl2db_effects.inc}

{$Include tl2db_settings.inc}

//----- Unit theme -----

function GetUnitTheme(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,'dicuthemes','name');
  if result='' then
    result:='0x'+HexStr(aid,16)
end;

//----- Quests -----

function GetTL2Quest(const aid:TRGID; out amods:string; out aname:string):string;
begin
  result:=GetById(aid,'quests','',amods,aname);
end;

function GetTL2Quest(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetTL2Quest(aid,amods,lname);
end;

function GetTL2Quest(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=GetTL2Quest(aid,lmods);
end;

//----- Mob info -----

function GetTL2Mob(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'mobs','',amods,lname);
  if amods='' then result:=GetById(aid,'pets'   ,'',amods,lname);
  if amods='' then result:=GetById(aid,'classes','',amods,lname);
end;

function GetTL2Mob(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=GetTL2Mob(aid,lmods);
end;

function GetMobMods(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,'mobs','modid');
end;

//----- Wardrobe -----

procedure GetWardrobe(var award:TWardrobeData);
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin

    lSQL:='SELECT count(*) FROM wardrobe';
    i:=0;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;

    SetLength(award,i);

    if i>0 then
    begin
      lSQL:='SELECT id, type, name FROM wardrobe';
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          award[i].id   :=sqlite3_column_int (vm,0);
          award[i]._type:=sqlite3_column_text(vm,1);
          award[i].name :=sqlite3_column_text(vm,2);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end;
end;

//-----  -----

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

procedure ResetFilter;
begin
  ModFilter:='';
end;

function IsInModList(const alist:string; aid:TRGID):boolean;
var
  ls:string;
begin
  result:=true;

  if alist=TL2GameID then exit;

  Str(aid,ls);
  if Pos(' '+ls+' ',alist)<=0 then
    result:=false;
end;

function IsInModList(const alist:string; amods:TTL2ModList):TRGID;
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

function IsInModList(aid:TRGID; amods:TTL2ModList):boolean;
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
{
    lSQL:='SELECT COUNT(*) FROM mods WHERE (id=0) AND (title=''''Torchlight'''')';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        if sqlite3_column_int(vm,0)=0 then gamever:=verTL2 else gamever:=verTL1;
      end;
      sqlite3_finalize(vm);
    end;
}
  end;
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
        SetupGameVer;
      except
        sqlite3_close(db);
        db:=nil;
        result:=errRGDBCantMapDB;
      end;
    end
    else
      result:=errRGDBCantMemDB;
  end
  else
    result:=errRGDBNoDBFile;
end;

procedure UseBase(adb:pointer);
begin
  if db<>nil then sqlite3_close(db);
  db:=adb;
  SetupGameVer;
end;

procedure FreeBases;
begin
  if db<>nil then
  begin
    sqlite3_close(db);
    db:=nil;
    ReleaseSqlite;
    GameVersion:=verUnk;
  end;
end;


initialization

  GameVersion:=verUnk;

finalization
//  ReleaseSqlite;

end.
