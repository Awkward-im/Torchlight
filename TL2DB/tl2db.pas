unit tl2db;

interface

uses
  tl2types;

{$DEFINE Interface}

function GetTL2Skill(const id:TL2ID; out amod:string; out atype:integer):string; overload;
function GetTL2Skill(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Skill(const id:TL2ID                   ):string; overload;
function GetTL2Skill(const aname:string; out id:TL2ID ):string; overload;
{$Include skills.inc}

// can be nice to add list of modids for filtering
function GetTL2Movie(const id   :TL2ID ; out amod :string; out aviews:integer;
                     out   aname:string; out apath:string):string; overload;
function GetTL2Movie(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Movie(const id:TL2ID                   ):string; overload;

function GetTL2Quest(const id:TL2ID; out amod:string; out aname:string):string; overload;
function GetTL2Quest(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Quest(const id:TL2ID                   ):string; overload;

function GetTL2Recipes(const id:TL2ID; out amod:string):string; overload;
function GetTL2Recipes(const id:TL2ID                 ):string; overload;

function GetTL2Stat (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Stat (const id:TL2ID                   ):string; overload;

function GetTL2Item (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Item (const id:TL2ID                   ):string; overload;

function GetTL2Class(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Class(const id:TL2ID                   ):string; overload;

function GetTL2Pet  (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Pet  (const id:TL2ID                   ):string; overload;

function GetTL2Mobs (const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Mobs (const id:TL2ID                   ):string; overload;

function GetTL2Mod  (const id:TL2ID; out aver:integer ):string; overload;
function GetTL2Mod  (const id:TL2ID                   ):string; overload;
function GetTL2Mod  (const id:string                  ):string; overload;

function GetTL2KeyType(acode:integer):string;

function LoadBases:boolean;
procedure FreeBases;

//======================================

{$UNDEF Interface}

implementation

uses
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

function GetTL2Movie(const id   :TL2ID ; out amod :string; out aviews:integer;
                     out   aname:string; out apath:string ):string;
var
  aSQL:string;
  vm:pointer;
begin
  amod  :='';
  result:=HexStr(id,16);
  aviews:=1;
  aname :='';
  apath :='';

  if db<>nil then
  begin
    Str(id,aSQL);
    aSQL:='SELECT title,modid,views,name,path FROM movies WHERE id='+aSQL+' LIMIT 1';

    if sqlite3_prepare_v2(db, PAnsiChar(aSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text (vm,0);
        amod  :=sqlite3_column_text (vm,1);
        aviews:=sqlite3_column_int64(vm,2);
        aname :=sqlite3_column_text (vm,3);
        apath :=sqlite3_column_text (vm,4);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetTL2Movie(const id:TL2ID; out amod:string):string; overload;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'movies','',amod,lname);
end;

function GetTL2Movie(const id:TL2ID):string; overload;
var
  lmodid:string;
begin
  result:=GetTL2Movie(id,lmodid);
end;

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

function GetTL2Skill(const id:TL2ID; out amod:string; out atype:integer):string;
var
  lname:string;
begin
//  amod  :='';
  atype :=-1;
//  result:=HexStr(id,16);
  result:=GetModAndTitle(id,'skills','',amod,lname);
end;

function GetTL2Skill(const id:TL2ID; out amod:string):string;
var
  ltype:integer;
begin
  result:=GetTL2Skill(id,amod,ltype);
end;

function GetTL2Skill(const id:TL2ID):string;
var
  lmod  :string;
  ltype :integer;
begin
  result:=GetTL2Skill(id,lmod,ltype);
end;

function GetTL2Skill(const aname:string; out id:TL2ID):string;
var
  aSQL:string;
  vm:pointer;
begin
  id    :=TL2IdEmpty;
  result:=aname;

  if db<>nil then
  begin
    aSQL:='SELECT id,title FROM skills WHERE name LIKE '''+aname+'''';

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

function GetTL2Item(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'items','',amod,lname);
end;

function GetTL2Item(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Item(id,lmod);
end;

//----- Class info -----

function GetTL2Class(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'classes','',amod,lname);
end;

function GetTL2Class(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Class(id,lmod);
end;

//----- Pet info -----

function GetTL2Pet(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'pets','',amod,lname);
end;

function GetTL2Pet(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Pet(id,lmod);
end;

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

procedure SetFilter(const afilter:string);
begin
  if pos(',',afilter)>0 then
    filter:='(modid IN ('+afilter+'))'
  else
    filter:='(modid='+afilter+')';
//  'GLOB ''*,'+filter+',*''';
end;

end.
