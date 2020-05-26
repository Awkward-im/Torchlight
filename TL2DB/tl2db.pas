unit tl2db;

interface

uses
  tl2types;

{$DEFINE Interface}

{$Include skills.inc}

{$Include movies.inc}

function GetTL2Quest(const id:TL2ID; out amod:string; out aname:string):string; overload;
function GetTL2Quest(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Quest(const id:TL2ID                   ):string; overload;

function GetTL2Recipes(const id:TL2ID; out amod:string):string; overload;
function GetTL2Recipes(const id:TL2ID                 ):string; overload;

function GetTL2Stat (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Stat (const id:TL2ID                   ):string; overload;

{$Include items.inc}

{$Include classes.inc}

{$Include pets.inc}

function GetTL2Mobs (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Mobs (const id:TL2ID                   ):string; overload;

function GetTL2Mod  (const id:TL2ID; out aver:integer ):string; overload;
function GetTL2Mod  (const id:TL2ID                   ):string; overload;
function GetTL2Mod  (const id:string                  ):string; overload;

function GetTL2KeyType(acode:integer):string;

procedure SetFilter(amods:TTL2ModList);
procedure SetFilter(amods:TL2IdList);

function LoadBases:boolean;
procedure FreeBases;

//======================================

{$UNDEF Interface}

implementation

uses
  sysutils,
  sqlite3;

var
  db:PSQLite3;
  filter:string;

const
  TL2DataBase = 'tl2db2.db';

resourcestring
  rsSet = 'Set';
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

//-------------------

type
 TIntArray   = array of integer;
 TInt64Array = array of int64;

function splitInt(const astr:string; asep:char):TIntArray;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  p:=pointer(astr);
  if p^=asep then inc(p);
  lcnt:=0;
  while p^<>#0 do
  begin
    if p^=asep then inc(lcnt);
    inc(p);
  end;
  if (p-1)^<>asep then inc(lcnt);
  SetLength(result,lcnt);

  // fill array

  p:=pointer(astr);
  if p^=asep then inc(p);

  isminus:=false;
  result[0]:=0;
  i:=0;
  while p^<>#0 do
  begin
    if p^='-' then isminus:=true
    else if p^<>asep then result[i]:=result[i]*10+ORD(p^)-ORD('0')
    else
    begin
      if isminus then
      begin
        result[i]:=-result[i];
        isminus:=false;
      end;
      inc(i);
      if i<lcnt then result[i]:=0;
    end;
    inc(p);
  end;
end;

function splitInt64(const astr:string; asep:char):TInt64Array;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  p:=pointer(astr);
  if p^=asep then inc(p);
  lcnt:=0;
  while p^<>#0 do
  begin
    if p^=asep then inc(lcnt);
    inc(p);
  end;
  if (p-1)^<>asep then inc(lcnt);
  SetLength(result,lcnt);

  // fill array

  p:=pointer(astr);
  if p^=asep then inc(p);

  isminus:=false;
  result[0]:=0;
  i:=0;
  while p^<>#0 do
  begin
    if p^='-' then isminus:=true
    else if p^<>asep then result[i]:=result[i]*10+ORD(p^)-ORD('0')
    else
    begin
      if isminus then
      begin
        result[i]:=-result[i];
        isminus:=false;
      end;
      inc(i);
      if i<lcnt then result[i]:=0;
    end;
    inc(p);
  end;
end;

//-------------------
function GetModAndTitle(const id:TL2ID; const abase:string; const awhere:string;
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

//----- Movie Info -----

{$Include movies.inc}


//----- Quests -----

function GetTL2Quest(const id:TL2ID; out amod:string; out aname:string):string;
begin
  result:=GetModAndTitle(id,'quests','',amod,aname);
end;

function GetTL2Quest(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetTL2Quest(id,amod,lname);
end;

function GetTL2Quest(const id:TL2ID):string;
var
  lmodid:string;
begin
  result:=GetTL2Quest(id,lmodid);
end;

//----- Recipes -----

function GetTL2Recipes(const id:TL2ID; out amod:string):string; overload;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'recipes','',amod,lname);
end;

function GetTL2Recipes(const id:TL2ID):string; overload;
var
  lmodid:string;
begin
  result:=GetTL2Recipes(id,lmodid);
end;

//----- Skill info -----

{$Include skills.inc}

//----- Stat info -----

function GetTL2Stat(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'stats','',amod,lname);
end;

function GetTL2Stat(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Stat(id,lmod);
end;

//----- Item info -----

{$Include items.inc}

//----- Class info -----

{$Include classes.inc}

//----- Pet info -----

{$Include pets.inc}

//----- Mob info -----

function GetTL2Mobs(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'mobs','',amod,lname);
end;

function GetTL2Mobs(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Mobs(id,lmod);
end;

//----- Mod info -----

function GetTL2Mod(const id:TL2ID; out aver:integer):string;
var
  aSQL:string;
  vm:pointer;
  i:integer;
begin
  aver  :=0;
  result:=HexStr(id,16);

  if db<>nil then
  begin
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
  end
  else if id=0 then
    result:='Torchlight 2';

end;

function GetTL2Mod(const id:TL2ID):string;
var
  lver:integer;
begin
  result:=GetTL2Mod(id,lver);
end;

function GetTL2Mod(const id:string):string;
var
  ls:string;
  lid:TL2ID;
  lpos:integer;
begin
  ls:=id;
  if ls='' then
    lid:=0
  else
  begin
    if ls[1]=' ' then ls:=Copy(ls,1);
    if ls[Length(ls)]=' ' then SetLength(ls,High(ls));
    lpos:=pos(' ',ls);
    if lpos=0 then
      Val(ls,lid)
    else
      Val(Copy(ls,1,lpos-1),lid);
  end;
  result:=GetTL2Mod(lid);
end;

//----- Icon -----

function GetTL2Icon(const id:TL2ID; const abase:string):pointer;
var
  aSQL:string;
  vm:pointer;
  lptr:pbyte;
  lsize:integer;
begin
  result:=nil;

  if db<>nil then
  begin
    Str(id,aSQL);
    aSQL:='SELECT icon FROM '+abase+' WHERE id='''+aSQL+'''';

    lsize:=0;

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        lsize:=sqlite3_column_bytes(vm,0);
        if lsize>0 then
        begin
          GetMem(result,lsize);
          lptr:=sqlite3_column_blob(vm,0);
          move(lptr^,result^,lsize);
        end;
      end;
      sqlite3_finalize(vm);
    end;

    if lsize=0 then
    begin
    end;
  end;
end;

//===== Key binding =====

function GetTL2KeyType(acode:integer):string;
begin
  case acode of
    0..99: begin // just for 3 hotbars atm
      if acode>=10 then
      begin
        Str(acode div 10,result);
        result:=rsSet+' '+result+': ';
      end
      else
        result:='';

      case (acode mod 10) of
        0: result:=result+rsQK1;
        1: result:=result+rsQK2;
        2: result:=result+rsQK3;
        3: result:=result+rsQK4;
        4: result:=result+rsQK5;
        5: result:=result+rsQK6;
        6: result:=result+rsQK7;
        7: result:=result+rsQK8;
        8: result:=result+rsQK9;
        9: result:=result+rsQK0;
      end;
    end;

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

function CopyFromFile(db:PSQLite3; afname:PChar):integer;
var
  pFile  :PSQLite3;        // Database connection opened on zFilename
  pBackup:PSQLite3Backup;  // Backup object used to copy data
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

function LoadBases:boolean;
begin
  result:=false;
  db:=nil;

  if sqlite3_open(':memory:',@db)=SQLITE_OK then
  begin
    try
      result:=CopyFromFile(db,TL2DataBase)=SQLITE_OK;
    except
      sqlite3_close(db);
      db:=nil;
    end;
  end;
end;

procedure FreeBases;
begin
  if db<>nil then sqlite3_close(db);
end;


procedure SetFilter(amods:TTL2ModList);
var
  ls:string;
  i:integer;
begin
  filter:='(instr(modid,'' 0 '')>0';
  if amods<>nil then
  begin
    for i:=0 to High(amods) do
    begin
      Str(amods[i].id,ls);
      filter:=filter+') OR (instr(modid,'' '+ls+' '')>0';
    end;
  end;
  filter:=filter+')';
end;

procedure SetFilter(amods:TL2IdList);
var
  ls:string;
  i:integer;
begin
  filter:='(instr(modid,'' 0 '')>0';
  if amods<>nil then
  begin
    for i:=0 to High(amods) do
    begin
      Str(amods[i],ls);
      filter:=filter+') OR (instr(modid,'' '+ls+' '')>0';
    end;
  end;
  filter:=filter+')';
end;

end.
