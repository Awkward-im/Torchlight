unit tl2db;

interface

uses
  tl2types;

type
  TTL2ModInfo = record
    modid      :TL2ID;
    gamever    :QWord;
    title      :string;
    author     :string;
    descr      :string;
    website    :string;
    download   :string;
    modver     :Word;
  end;

function ReadModInfo(const fname:string; var amod:TTL2ModInfo):boolean;

function GetTL2Skill(const id:TL2ID; var aclass:TL2ID; var atype:integer):string; overload;
function GetTL2Skill(const id:TL2ID; var aclass:TL2ID):string; overload;
function GetTL2Skill(const id:TL2ID                  ):string; overload;
function GetTL2Item (const id:TL2ID; var amod:TL2ID  ):string; overload;
function GetTL2Item (const id:TL2ID                  ):string; overload;
function GetTL2Class(const id:TL2ID; var amod:TL2ID  ):string; overload;
function GetTL2Class(const id:TL2ID                  ):string; overload;
function GetTL2Pet  (const id:TL2ID; var amod:TL2ID  ):string; overload;
function GetTL2Pet  (const id:TL2ID                  ):string; overload;
function GetTL2Mod  (const id:TL2ID; var aver:integer):string; overload;
function GetTL2Mod  (const id:TL2ID                  ):string; overload;

function GetTL2KeyType(acode:integer):string;

procedure LoadBases;
procedure FreeBases;

//======================================

implementation

uses
  classes,
  sysutils;

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

type
  TTL2DBBaseInfo = record
    id   : QWord;
    title: string;
  end;

type
  TTL2DBPetInfo = record
    id   : QWord;
    title: string;
  end;
  TTL2DBSkillInfo = record
    id    :QWord;
    fclass:QWord;
    title :string;
  end;
  TTL2DBQuestInfo = record
    id   :QWord;
    title:string;
  end;
  TTL2DBModInfo = record
    id   :QWord;
    title:string;
    ver  :integer;
  end;
  TTL2DBItemInfo = record
    id   :QWord;
    title:string;
  end;

var
  TL2DBPetInfo  :array of TTL2DBPetInfo;
  TL2DBSkillInfo:array of TTL2DBSkillInfo;
  TL2DBQuestInfo:array of TTL2DBQuestInfo;
  TL2DBModInfo  :array of TTL2DBModInfo;
  TL2DBItemInfo :array of TTL2DBItemInfo;


//----- Skill info -----

function GetTL2Skill(const id:TL2ID; var aclass:TL2ID; var atype:integer):string;
begin
  aclass:=TL2IdEmpty;
  atype :=-1;
  result:=IntToHex(id,16);
end;

function GetTL2Skill(const id:TL2ID; var aclass:TL2ID):string;
var
  ltype:integer;
begin
  result:=GetTL2Skill(id,aclass,ltype);
end;

function GetTL2Skill(const id:TL2ID):string;
var
  lclass:TL2ID;
  ltype :integer;
begin
  result:=GetTL2Skill(id,lclass,ltype);
end;

//----- Item info -----

function GetTL2Item(const id:TL2ID; var amod:TL2ID):string;
begin
  amod  :=TL2IdEmpty;
  result:=IntToHex(id,16);
end;

function GetTL2Item(const id:TL2ID):string;
var
  lmod:TL2ID;
begin
  result:=GetTL2Item(id,lmod);
end;

//----- Class info -----

function GetTL2Class(const id:TL2ID; var amod:TL2ID):string;
begin
  amod  :=TL2IdEmpty;
  result:=IntToHex(id,16);
end;

function GetTL2Class(const id:TL2ID):string;
var
  lmod:TL2ID;
begin
  result:=GetTL2Class(id,lmod);
end;

//----- Pet info -----

function GetTL2Pet(const id:TL2ID; var amod:TL2ID):string;
var
  i:integer;
begin
  amod  :=TL2IdEmpty;
  result:=IntToHex(id,16);

  for i:=0 to High(TL2DBPetInfo) do
  begin
    if TL2DBPetInfo[i].id=id then
    begin
      result:=TL2DBPetInfo[i].title;
      break;
    end;
  end;
end;

function GetTL2Pet(const id:TL2ID):string;
var
  lmod:TL2ID;
begin
  result:=GetTL2Pet(id,lmod);
end;

//----- Mod info -----

function GetTL2Mod(const id:TL2ID; var aver:integer):string;
var
  i:integer;
begin
  aver  :=0;
  result:=IntToHex(id,16);

  for i:=0 to High(TL2DBModInfo) do
  begin
    if TL2DBModInfo[i].id=id then
    begin
      result:=TL2DBModInfo[i].title;
      aver  :=TL2DBModInfo[i].ver;
      break;
    end;
  end;
end;

function GetTL2Mod(const id:TL2ID):string;
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

//===== Mod files info =====

function ReadShortString(var aptr:pbyte):string;
var
  ws:WideString;
  lsize:cardinal;
begin
  lsize:=pword(aptr)^; inc(aptr,2);
  if lsize>0 then
  begin
    SetLength(ws,lsize);
    move(aptr^,ws[1],lsize*SizeOf(WideChar));
    inc (aptr       ,lsize*SizeOf(WideChar));
    result:=UTF8Encode(ws);
  end
  else
    result:='';
end;

function ReadModInfo(const fname:string; var amod:TTL2ModInfo):boolean;
type
  PTL2ID = ^TL2ID;
var
  buf:array [0..16383] of byte;
  f:file of byte;
  p:pbyte;
  i:integer;
begin
  result:=false;

  AssignFile(f,fname);
  try
    Reset(f);
    i:=FileSize(f);
    if i>SizeOf(buf) then i:=SizeOf(buf);
    BlockRead(f,buf[0],i);
  except
    i:=0;
  end;
  CloseFile(f);

  if i<(2+2+8+4+4+2*5+8) then exit; // minimal size of used header data

  p:=@buf[0];

  // wrong signature
  if pword(p)^<>4 then
  begin
    amod.modid:=TL2IdEmpty;
    amod.title:='';
    exit;
  end;
  inc(p,2);

  result:=true;

  amod.modver  :=pWord (p)^; inc(p,2);
  amod.gamever :=pQWord(p)^; inc(p,8);
  inc(p,4+4); // skip offset_data and offset_dir
  amod.title   :=ReadShortString(p);
  amod.author  :=ReadShortString(p);
  amod.descr   :=ReadShortString(p);
  amod.website :=ReadShortString(p);
  amod.download:=ReadShortString(p);
  amod.modid   :=PTL2ID(p)^;
end;

//===== Database load =====

procedure LoadMods;
var
  sl:TStringList;
  ls:string;
  i,loldpos,ltabpos:integer;
begin
  sl:=TStringList.Create;
  try
    try
      sl.LoadFromFile('modlist.csv');
      SetLength(TL2DBModInfo,sl.Count);
      for i:=0 to sl.Count-1 do
      begin
        ls:=sl[i];
        TL2DBModInfo[i].id:=StrToQWord('$'+Copy(ls,1,16));
        // mod title
        loldpos:=18;
        ltabpos:=18;
        while (ltabpos<length(ls)) and (ls[ltabpos]<>#9) do inc(ltabpos);
        TL2DBModInfo[i].title:=Copy(ls,loldpos,ltabpos-loldpos);
        // mod version
        loldpos:=ltabpos; inc(ltabpos);
        while (ltabpos<length(ls)) and (ls[ltabpos]<>#9) do inc(ltabpos);
        TL2DBModInfo[i].ver  :=StrToInt(Copy(sl[i],loldpos,ltabpos-loldpos));
        // game version
{
        loldpos:=ltabpos+1; inc(ltabpos);
        while (ltabpos<length(ls)) and (ls[ltabpos]<>#9) do inc(ltabpos);
}
      end;
    except
    end;
  finally
    sl.Free;
  end;
end;

procedure LoadItems;
begin
end;

procedure LoadPets;
var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
  try
    try
      sl.LoadFromFile('petlist.csv');
      SetLength(TL2DBPetInfo,sl.Count);
      for i:=0 to sl.Count-1 do
      begin
        TL2DBPetInfo[i].id   :=StrToQWord('$'+Copy(sl[i],1,16));
        TL2DBPetInfo[i].title:=Copy(sl[i],18);
      end;
    except
    end;
  finally
    sl.Free;
  end;
end;

procedure LoadQuests;
begin
end;

procedure LoadBases;
begin
  LoadMods;
  LoadItems;
  LoadPets;
  LoadQuests;
end;

procedure FreeBases;
begin
  SetLength(TL2DBPetInfo  ,0);
  SetLength(TL2DBSkillInfo,0);
  SetLength(TL2DBQuestInfo,0);
  SetLength(TL2DBModInfo  ,0);
  SetLength(TL2DBItemInfo ,0);
end;


end.
