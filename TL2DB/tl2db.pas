unit tl2db;

interface

function GetTL2Skill(const id:Int64; out aclass:Int64; out atype:integer):string; overload;
function GetTL2Skill(const id:Int64; out aclass:Int64):string; overload;
function GetTL2Skill(const id:Int64                  ):string; overload;
function GetTL2Item (const id:Int64; out amod:Int64  ):string; overload;
function GetTL2Item (const id:Int64                  ):string; overload;
function GetTL2Class(const id:Int64; out amod:Int64  ):string; overload;
function GetTL2Class(const id:Int64                  ):string; overload;
function GetTL2Pet  (const id:Int64; out amod:Int64  ):string; overload;
function GetTL2Pet  (const id:Int64                  ):string; overload;
function GetTL2Mod  (const id:Int64; out aver:integer):string; overload;
function GetTL2Mod  (const id:Int64                  ):string; overload;

function GetTL2KeyType(acode:integer):string;

procedure LoadBases;
procedure FreeBases;

//======================================

implementation

uses
//  classes,
//  sysutils,
  sqlite3,
  awksqlite3
  ;

var
  db:PSQLite3;

const
  TL2DataBase = 'tl2db.db';

resourcestring
  rsQK1 = 'Quckslot 1';
  rsQK2 = 'Quckslot 2';
  rsQK3 = 'Quckslot 3';
  rsQK4 = 'Quckslot 4';
  rsQK5 = 'Quckslot 5';
  rsQK6 = 'Quckslot 6';
  rsQK7 = 'Quckslot 7';
  rsQK8 = 'Quckslot 8';
  rsQK9 = 'Quckslot 9';
  rsQK0 = 'Quckslot 0';
  rsLMB    = 'Left mouse button';
  rsRMB    = 'Right mouse button';
  rsRMBAlt = 'Right mouse button (alternative)';
  rsHP     = 'Best Health Potion';
  rsMP     = 'Best Mana Potion';
  rsPetHP  = 'Best Pet Health Potion';
  rsPetMP  = 'Best Pet Mana Potion';
  rsSpell1    = 'Spell 1';
  rsSpell2    = 'Spell 2';
  rsSpell3    = 'Spell 3';
  rsSpell4    = 'Spell 4';
  rsPetSpell1 = 'Pet spell 1';
  rsPetSpell2 = 'Pet spell 2';
  rsPetSpell3 = 'Pet spell 3';
  rsPetSpell4 = 'Pet spell 4';

//----- Skill info -----

function GetTL2Skill(const id:Int64; out aclass:Int64; out atype:integer):string;
begin
  aclass:=-1;
  atype :=-1;
  result:=HexStr(id,16);
end;

function GetTL2Skill(const id:Int64; out aclass:Int64):string;
var
  ltype:integer;
begin
  result:=GetTL2Skill(id,aclass,ltype);
end;

function GetTL2Skill(const id:Int64):string;
var
  lclass:Int64;
  ltype :integer;
begin
  result:=GetTL2Skill(id,lclass,ltype);
end;

//-------------------

function GetModAndTitle(const id:Int64; const abase:string; out amod:Int64):string;
var
  aSQL:string;
  vm:pointer;
begin
  amod  :=-1;
  result:=HexStr(id,16);

  Str(id,aSQL);
  aSQL:='SELECT title,modid FROM '+abase+' WHERE id='+aSQL+' LIMIT 1';

  if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      result:=sqlite3_column_text (vm,0);
      amod  :=sqlite3_column_int64(vm,1);
    end;
    sqlite3_finalize(vm);
  end;
end;

//----- Item info -----

function GetTL2Item(const id:Int64; out amod:Int64):string;
begin
  result:=GetModAndTitle(id,'items',amod);
end;

function GetTL2Item(const id:Int64):string;
var
  lmod:Int64;
begin
  result:=GetTL2Item(id,lmod);
end;

//----- Class info -----

function GetTL2Class(const id:Int64; out amod:Int64):string;
begin
  result:=GetModAndTitle(id,'classes',amod);
end;

function GetTL2Class(const id:Int64):string;
var
  lmod:Int64;
begin
  result:=GetTL2Class(id,lmod);
end;

//----- Pet info -----

function GetTL2Pet(const id:Int64; out amod:Int64):string;
begin
  result:=GetModAndTitle(id,'pets',amod);
end;

function GetTL2Pet(const id:Int64):string;
var
  lmod:Int64;
begin
  result:=GetTL2Pet(id,lmod);
end;

//----- Mod info -----

function GetTL2Mod(const id:Int64; out aver:integer):string;
var
  aSQL:string;
  vm:pointer;
  i:integer;
begin
  aver  :=0;
  result:=HexStr(id,16);

  Str(id,aSQL);
  aSQL:='SELECT title,version FROM mods WHERE id='+aSQL;

  i:=sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil);
  if i=SQLITE_OK then
  begin
    i:=sqlite3_step(vm);
    if i=SQLITE_ROW then
    begin
      result:=sqlite3_column_text(vm,0);
      aver  :=sqlite3_column_int (vm,1);
    end;
    sqlite3_finalize(vm);
  end;
end;

function GetTL2Mod(const id:Int64):string;
var
  lver:integer;
begin
  result:=GetTL2Mod(id,lver);
end;

//===== Key binding =====

function GetTL2KeyType(acode:integer):string;
begin
  case acode of
    0: result:=rsQK1;
    1: result:=rsQK2;
    2: result:=rsQK3;
    3: result:=rsQK4;
    4: result:=rsQK5;
    5: result:=rsQK6;
    6: result:=rsQK7;
    7: result:=rsQK8;
    8: result:=rsQK9;
    9: result:=rsQK0;
    $3E8: result:=rsLMB;
    $3E9: result:=rsRMB;
    $3EA: result:=rsRMBAlt;
    $3EB: result:=rsSpell1;
    $3EC: result:=rsSpell2;
    $3ED: result:=rsSpell3;
    $3EE: result:=rsSpell4;
    $3EF: result:=rsPetSpell1;
    $3F0: result:=rsPetSpell2;
    $3F1: result:=rsPetSpell3;
    $3F2: result:=rsPetSpell4;
    $3F3: result:=rsHP;
    $3F4: result:=rsMP;
    $3F5: result:=rsPetHP;
    $3F6: result:=rsPetMP;
  else
    result:='';
  end;
end;

//===== Database load =====

procedure LoadBases;
{
var
  lb:PSQLite3;
  vm:pointer;
}
begin
{
  if sqlite3_open('file:memdb?mode=memory',@db)=SQLITE_OK then
  begin
    sqlite3_open('tl2db.db',@lb);
    if sqlite3_prepare_v2(lb, 'VACUUM INTO "file:memdb?mode=memory"',-1, @vm, nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
    end;
    sqlite3_close(lb);
  end;
}

  if sqlite3_open(':memory:',@db)=SQLITE_OK then
    try
      if loadOrSaveDb(db,TL2DataBase,false)=SQLITE_OK then
      begin
      end;
    except
    end;

end;

procedure FreeBases;
begin
  sqlite3_close(db);
end;


end.
