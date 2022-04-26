{TODO: scan mod for info}
unit RGIO.RAW;

interface

function ParseRawMem (abuf:PByte; const afname:string):pointer;
function ParseRawFile(const afname:string):pointer;


implementation

uses
  rgglobal,
  rgmemory,
  rgio.text,
  rgnode;

const
  nmUNITDATA     = 0;
  nmSKILLS       = 1;
  nmAFFIXES      = 2;
  nmMISSILES     = 3;
  nmROOMPIECES   = 4;
  nmTRIGGERABLES = 5;
  nmUI           = 6;
const
  RawNames: array [0..6] of string = (
    'UNITDATA',
    'SKILLS',
    'AFFIXES',
    'MISSILES',
    'ROOMPIECES',
    'TRIGGERABLES',
    'UI'
  );

const
  MAXLEN = 299;

procedure ReadUnit(var abuf:PByte; anode:pointer);
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
begin
  lnode:=AddGroup(anode,'UNIT');
  AddInteger64(lnode,'GUID'    ,memReadInteger64(abuf));
  AddString   (lnode,'Name'    ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
  AddString   (lnode,'File'    ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
  AddBool     (lnode,'UNKNOWN' ,memReadByte(abuf)<>0);
  AddInteger  (lnode,'Level'   ,memReadInteger(abuf));
  AddInteger  (lnode,'MinLevel',memReadInteger(abuf));
  AddInteger  (lnode,'MaxLevel',memReadInteger(abuf));
  AddInteger  (lnode,'Rarity'  ,memReadInteger(abuf));
  AddInteger  (lnode,'RarityHC',memReadInteger(abuf));
  AddString   (lnode,'Type'    ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
end;

function DecodeUnitData(abuf:PByte):pointer;
var
  lnode:pointer;
  i,lcnt:integer;
begin
  result:=AddGroup(nil,'UNITDATA');
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    lnode:=AddGroup(result,'ITEMS');
    for i:=0 to lcnt-1 do
    begin
      ReadUnit(abuf,lnode);
    end;
  end;

  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    lnode:=AddGroup(result,'MONSTERS');
    for i:=0 to lcnt-1 do
    begin
      ReadUnit(abuf,lnode);
    end;
  end;

  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    lnode:=AddGroup(result,'PLAYERS');
    for i:=0 to lcnt-1 do
    begin
      ReadUnit(abuf,lnode);
    end;
  end;

  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    lnode:=AddGroup(result,'PROPS');
    for i:=0 to lcnt-1 do
    begin
      ReadUnit(abuf,lnode);
    end;
  end;
end;


function DecodeAffixes(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode,lnode1:pointer;
  i,j,lcnt,lcnt1:integer;
begin
  lcnt:=memReadWord(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'AFFIXES');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'AFFIX');

      AddString (lnode,'File'               ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString (lnode,'Name'               ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddInteger(lnode,'MinSpawnRange'      ,memReadInteger(abuf));
      AddInteger(lnode,'MaxSpawnRange'      ,memReadInteger(abuf));
      AddInteger(lnode,'Weight'             ,memReadInteger(abuf));
      AddInteger(lnode,'DifficultiesAllowed',memReadInteger(abuf));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'UNITTYPES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
        end;
      end;

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NOTUNITTYPES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
        end;
      end;
    end;
  end
  else
    result:=nil;
end;

function DecodeMissiles(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode,lnode1:pointer;
  i,j,lcnt,lcnt1:integer;
begin
  lcnt:=memReadWord(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'MISSILES');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'MISSILE');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NAMES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
        end;
      end;
    end;
  end
  else
    result:=nil;
end;

function DecodeRoomPieces(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
  i,j,lcnt,lcnt1:integer;
begin
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'ROOMPIECES');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'LEVELSET');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
    end;

    for i:=1 to lcnt do
    begin
      lcnt1:=memReadInteger(abuf);
      if lcnt1>0 then
      begin
        lnode:=AddGroup(GetChild(result,i),'GUIDS');
        for j:=0 to lcnt1-1 do
        begin
          AddInteger64(lnode,'GUID',memReadInteger64(abuf));
        end;
      end;
    end;
  end
  else
    result:=nil;
end;

const
  strGameStates:array of PWideChar = (
    '', // NONE
    'Testing',
    'All',
    'In Game',
    'Server Only'
    'Loading',
    'Main Menu Mod'
  );

  strTypes:array of PWideChar = (
    '',
    'TEST MENU',
    'HUD MENU',
    'CHAT MENU',
    'PLAYER STATS MENU',
    'MERCHANT MENU',
    'SKILL MENU',
    'QUEST DIALOG MENU',
    'QUEST MENU',
    'MESSAGE BOX MENU',
    'MAIN MENU',
    'SERVER MENU',
    'CONSOLE MENU',
    'RESURRECTION MENU',
    'TOWNPORTAL MENU',
    'HOTBAR CONTEXT MENU',
    'STANDALONE SERVER MENU',
    'LOGIN MENU',
    'UPSELL MENU',
    'CLIENT OPTIONS'
  );

function DecodeUI(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
  i,lcnt:integer;
begin
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'MENUS');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'MENU');

      AddString(lnode,'Name'             ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'File'             ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'TYPE'             ,strTypes     [memReadInteger(abuf)]);
      AddString(lnode,'GAME STATE'       ,strGameStates[memReadInteger(abuf)]);
      AddBool  (lnode,'CREATE ON LOAD'   ,memReadByte(abuf)<>0); //!!!! not 100%, like ALWAYS VISIBLE
      AddBool  (lnode,'MULTIPLAYER ONLY' ,memReadByte(abuf)<>0);
      AddBool  (lnode,'SINGLEPLAYER ONLY',memReadByte(abuf)<>0);
      AddString(lnode,'KEY BINDING'      ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
    end;
  end
  else
    result:=nil;
end;

function DecodeTriggers(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
  i,lcnt:integer;
begin
  lcnt:=memReadWord(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'TRIGGERABLES');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'TRIGGERABLE');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
    end;
  end
  else
    result:=nil;
end;

function DecodeSkills(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
  i,lcnt:integer;
begin
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'SKILLS');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'SKILL');

      AddString   (lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString   (lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddInteger64(lnode,'GUID',memReadInteger64(abuf));
    end;
  end
  else
    result:=nil;
end;


function ParseRawMem(abuf:PByte; const afname:string):pointer;
var
  lfname:string;
begin
  result:=nil;

  lfname:=UpCase(ExtractFileNameOnly(afname));

  if      lfname=RawNames[nmUNITDATA    ] then result:=DecodeUnitData  (abuf)
  else if lfname=RawNames[nmSKILLS      ] then result:=DecodeSkills    (abuf)
  else if lfname=RawNames[nmAFFIXES     ] then result:=DecodeAffixes   (abuf)
  else if lfname=RawNames[nmMISSILES    ] then result:=DecodeMissiles  (abuf)
  else if lfname=RawNames[nmROOMPIECES  ] then result:=DecodeRoomPieces(abuf)
  else if lfname=RawNames[nmTRIGGERABLES] then result:=DecodeTriggers  (abuf)
  else if lfname=RawNames[nmUI          ] then result:=DecodeUI        (abuf);
end;

function ParseRawFile(const afname:string):pointer;
var
  lfile:file of byte;
  lbuf:PByte;
  lsize:integer;
begin
  Assign(lfile,afname);
  Reset(lfile);
  if IOResult=0 then
  begin
    lsize:=FileSize(lfile);
    GetMem(lbuf,lsize);
    BlockRead(lfile,lbuf^,lsize);
    result:=ParseRawMem(lbuf,afname);
    FreeMem(lbuf);
  end
  else
    result:=nil;
end;

end.
