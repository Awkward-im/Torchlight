{TODO: scan mod for info}
unit RGIO.RAW;

interface

uses
  Classes;

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

function ParseRawMem   (abuf   :PByte  ; const afname:string):pointer;
function ParseRawStream(astream:TStream; const afname:string):pointer;
function ParseRawFile  (                 const afname:string):pointer;

function DecodeUnitData  (abuf:PByte):pointer;
function DecodeSkills    (abuf:PByte):pointer;
function DecodeAffixes   (abuf:PByte):pointer;
function DecodeMissiles  (abuf:PByte):pointer;
function DecodeRoomPieces(abuf:PByte):pointer;
function DecodeTriggers  (abuf:PByte):pointer;
function DecodeUI        (abuf:PByte):pointer;

function EncodeUnitData  (astream:TStream; anode:pointer):integer;
function EncodeSkills    (astream:TStream; anode:pointer):integer;
function EncodeAffixes   (astream:TStream; anode:pointer):integer;
function EncodeMissiles  (astream:TStream; anode:pointer):integer;
function EncodeRoomPieces(astream:TStream; anode:pointer):integer;
function EncodeTriggers  (astream:TStream; anode:pointer):integer;
function EncodeUI        (astream:TStream; anode:pointer):integer;

function BuildRawMem   (data:pointer; out bin    :pByte  ; const fname:string):integer;
function BuildRawStream(data:pointer;     astream:TStream; const fname:string):integer;
function BuildRawFile  (data:pointer;                      const fname:string):integer;


implementation

uses
  rgglobal,
  rgstream,
  rgmemory,
  rgnode;

const
  strUIGameStates:array of PWideChar = (
    nil, // NONE
    'Testing',
    'All',
    'In Game',
    'Server Only',
    'Loading',
    'Main Menu Mod'
  );

  strUITypes:array of PWideChar = (
    nil,
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

const
  MAXLEN = 299;

procedure ReadUnit(var abuf:PByte; anode:pointer);
var
  pcw:array [0..MAXLEN] of WideChar;
  lnode:pointer;
begin
  lnode:=AddGroup(anode,'UNIT');
  AddInteger64(lnode,'GUID'     ,memReadInteger64(abuf));
  AddString   (lnode,'NAME'     ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
  AddString   (lnode,'FILE'     ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
  AddInteger  (lnode,'EQUIPMENT',memReadByte(abuf)); // 1 = CREATEAS:EQUIPMENT, 2 = Part of a set)
  AddInteger  (lnode,'LEVEL'    ,memReadInteger(abuf));
  AddInteger  (lnode,'MINLEVEL' ,memReadInteger(abuf));
  AddInteger  (lnode,'MAXLEVEL' ,memReadInteger(abuf));
  AddInteger  (lnode,'RARITY'   ,memReadInteger(abuf));
  AddInteger  (lnode,'RARITYHC' ,memReadInteger(abuf));
  AddString   (lnode,'UNITTYPE' ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
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

      AddString (lnode,'FILE'                ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString (lnode,'NAME'                ,memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddInteger(lnode,'MIN_SPAWN_RANGE'     ,memReadInteger(abuf));
      AddInteger(lnode,'MAX_SPAWN_RANGE'     ,memReadInteger(abuf));
      AddInteger(lnode,'WEIGHT'              ,memReadInteger(abuf));
      AddInteger(lnode,'DIFFICULTIES_ALLOWED',memReadInteger(abuf));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'UNITTYPES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'UNITTYPE',memReadShortStringBuf(abuf,@pcw,MAXLEN));
        end;
      end;

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NOT_UNITTYPES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'UNITTYPE',memReadShortStringBuf(abuf,@pcw,MAXLEN));
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

      AddString(lnode,'FILE',memReadShortStringBuf(abuf,@pcw,MAXLEN));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NAMES');
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'NAME',memReadShortStringBuf(abuf,@pcw,MAXLEN));
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

      AddString(lnode,'FILE',memReadShortStringBuf(abuf,@pcw,MAXLEN));
    end;

    for i:=0 to lcnt-1 do
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

function DecodeUI(abuf:PByte):pointer;
var
  pcw:array [0..MAXLEN] of WideChar;
  pc:PWideChar;
  lnode:pointer;
  i,lcnt:integer;
  b:boolean;
begin
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'MENUS');
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'MENU');

      AddString(lnode,'NAME',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'FILE',memReadShortStringBuf(abuf,@pcw,MAXLEN));

      pc:=strUITypes     [memReadInteger(abuf)]; if pc<>nil then AddString(lnode,'TYPE'      ,pc);
      pc:=strUIGameStates[memReadInteger(abuf)]; if pc<>nil then AddString(lnode,'GAME STATE',pc);
      b:=memReadByte(abuf)<>0; if b then AddBool(lnode,'CREATE ON LOAD'   ,b); //!!!! or ALWAYS VISIBLE etc
      b:=memReadByte(abuf)<>0; if b then AddBool(lnode,'MULTIPLAYER ONLY' ,b);
      b:=memReadByte(abuf)<>0; if b then AddBool(lnode,'SINGLEPLAYER ONLY',b);
      pc:=memReadShortStringBuf(abuf,@pcw,MAXLEN); if pc<>nil then AddString(lnode,'KEY BINDING',pc);
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

      AddString(lnode,'FILE',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'NAME',memReadShortStringBuf(abuf,@pcw,MAXLEN));
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

      AddString   (lnode,'NAME',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString   (lnode,'FILE',memReadShortStringBuf(abuf,@pcw,MAXLEN));
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

function ParseRawStream(astream:TStream; const afname:string):pointer;
var
  lbuf:PByte;
begin
  GetMem(lbuf,astream.Size);
  aStream.Read(lbuf^,astream.Size);
  result:=ParseRawMem(lbuf,afname);
  FreeMem(lbuf);
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


procedure WriteUnit(astream:TStream; anode:pointer);
begin
  astream.WriteQWord(qword(AsInteger64(FindNode(anode,'GUID'     ))));
  astream.WriteShortString(AsString   (FindNode(anode,'NAME'     )));
  astream.WriteShortString(AsString   (FindNode(anode,'FILE'     )));
  astream.WriteByte (      AsInteger  (FindNode(anode,'EQUIPMENT')));
  astream.WriteDWord(dword(AsInteger  (FindNode(anode,'LEVEL'    ))));
  astream.WriteDWord(dword(AsInteger  (FindNode(anode,'MINLEVEL' ))));
  astream.WriteDWord(dword(AsInteger  (FindNode(anode,'MAXLEVEL' ))));
  astream.WriteDWord(dword(AsInteger  (FindNode(anode,'RARITY'   ))));
  astream.WriteDWord(dword(AsInteger  (FindNode(anode,'RARITYHC' ))));
  astream.WriteShortString(AsString   (FindNode(anode,'UNITTYPE' )));
end;

function EncodeUnitData(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  i,lcnt:integer;
begin
  lnode:=FindNode(anode,'ITEMS');
  lcnt:=GetGroupCount(lnode);
  result:=lcnt;
  astream.WriteDWord(lcnt);

  for i:=0 to lcnt-1 do WriteUnit(astream,GetChild(lnode,i));

  lnode:=FindNode(anode,'MONSTERS');
  lcnt:=GetGroupCount(lnode);
  inc(result,lcnt);
  astream.WriteDWord(lcnt);

  for i:=0 to lcnt-1 do WriteUnit(astream,GetChild(lnode,i));

  lnode:=FindNode(anode,'PLAYERS');
  lcnt:=GetGroupCount(lnode);
  inc(result,lcnt);
  astream.WriteDWord(lcnt);

  for i:=0 to lcnt-1 do WriteUnit(astream,GetChild(lnode,i));

  lnode:=FindNode(anode,'PROPS');
  lcnt:=GetGroupCount(lnode);
  inc(result,lcnt);
  astream.WriteDWord(lcnt);

  for i:=0 to lcnt-1 do WriteUnit(astream,GetChild(lnode,i));
end;

function EncodeSkills(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  i:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteDWord(result);

  for i:=0 to result-1 do
  begin
    lnode:=GetChild(anode,i);

    astream.WriteShortString(AsString   (FindNode(lnode,'NAME')));
    astream.WriteShortString(AsString   (FindNode(lnode,'FILE')));
    astream.WriteQWord(qword(AsInteger64(FindNode(lnode,'GUID'))));
  end;
end;

function EncodeAffixes(astream:TStream; anode:pointer):integer;
var
  lnode,lunode:pointer;
  i,j,lcnt:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteWord(result);
  for i:=0 to result-1 do
  begin
    lnode:=GetChild(anode,i);

    astream.WriteShortString(AsString (FindNode(lnode,'FILE')));
    astream.WriteShortString(AsString (FindNode(lnode,'NAME')));
    astream.WriteDWord(dword(AsInteger(FindNode(lnode,'MIN_SPAWN_RANGE'))));
    astream.WriteDWord(dword(AsInteger(FindNode(lnode,'MAX_SPAWN_RANGE'))));
    astream.WriteDWord(dword(AsInteger(FindNode(lnode,'WEIGHT'))));
    astream.WriteDWord(dword(AsInteger(FindNode(lnode,'DIFFICULTIES_ALLOWED'))));

    lunode:=FindNode(lnode,'UNITTYPES');
    lcnt:=GetChildCount(lunode);
    astream.WriteByte(lcnt);

    for j:=0 to lcnt-1 do
    begin
      astream.WriteShortString(AsString(GetChild(lunode,j)));
    end;

    lunode:=FindNode(lnode,'NOTUNITTYPES');
    lcnt:=GetChildCount(lunode);
    astream.WriteByte(lcnt);

    for j:=0 to lcnt-1 do
    begin
      astream.WriteShortString(AsString(GetChild(lunode,j)));
    end;
  end;
end;

function EncodeMissiles(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  i,j,lcnt:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteWord(result);
  for i:=0 to result-1 do
  begin
    lnode:=GetChild(anode,i);

    astream.WriteShortString(AsString(FindNode(lnode,'FILE')));

    lnode:=FindNode(lnode,'NAMES');
    lcnt:=GetChildCount(lnode);
    astream.WriteByte(lcnt);

    for j:=0 to lcnt-1 do
    begin
      astream.WriteShortString(AsString(GetChild(lnode,j)));
    end;
  end;
end;

function EncodeRoomPieces(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  i,j,lcnt:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteDWord(result);
  for i:=0 to result-1 do
    astream.WriteShortString(AsString(FindNode(GetChild(anode,i),'FILE')));

  for i:=0 to result-1 do
  begin
    lnode:=FindNode(GetChild(anode,i),'GUIDS');
    lcnt:=GetChildCount(lnode);
    astream.WriteDWord(lcnt);
    
    for j:=0 to lcnt-1 do
      astream.WriteQWord(qword(AsInteger64(GetChild(lnode,j))));
  end;
end;

function EncodeTriggers(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  i:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteWord(result);

  for i:=0 to result-1 do
  begin
    lnode:=GetChild(anode,i);

    astream.WriteShortString(AsString(FindNode(lnode,'FILE')));
    astream.WriteShortString(AsString(FindNode(lnode,'NAME')));
  end;
end;

function EncodeUI(astream:TStream; anode:pointer):integer;
var
  lnode:pointer;
  pc:PWideChar;
  i,j,b:integer;
begin
  result:=GetGroupCount(anode);
  if result=0 then exit;

  astream.WriteDWord(result);

  for i:=0 to result-1 do
  begin
    lnode:=GetChild(anode,i);

    astream.WriteShortString(AsString(FindNode(lnode,'NAME')));
    astream.WriteShortString(AsString(FindNode(lnode,'FILE')));

    pc:=AsString(FindNode(lnode,'TYPE'));
    for j:=0 to High(strUITypes) do
      if CompareWide(pc,strUITypes[j])=0 then
      begin
        astream.WriteDWord(j);
        break;
      end;
      
    pc:=AsString(FindNode(lnode,'GAME STATE'));
    for j:=0 to High(strUIGameStates) do
      if CompareWide(pc,strUIGameStates[j])=0 then
      begin
        astream.WriteDWord(j);
        break;
      end;

    if AsBool(FindNode(lnode,'CREATE ON LOAD'   )) then b:=1 else b:=0; astream.WriteByte(b);
    if AsBool(FindNode(lnode,'MULTIPLAYER ONLY' )) then b:=1 else b:=0; astream.WriteByte(b);
    if AsBool(FindNode(lnode,'SINGLEPLAYER ONLY')) then b:=1 else b:=0; astream.WriteByte(b);
    astream.WriteShortString(AsString(FindNode(lnode,'KEY BINDING')));
  end;
end;

function BuildRawMem(data:pointer; out bin:pByte; const fname:string):integer;
var
  ls:TMemoryStream;
begin
  result:=0;
  ls:=TMemoryStream.Create;
  try
    result:=BuildRawStream(data,ls,fname);
    GetMem(bin,result);
    move(ls.Memory^,bin^,result);
  finally
    ls.Free;
  end;
end;

function BuildRawStream(data:pointer; astream:TStream; const fname:string):integer;
begin
  if      fname=RawNames[nmUNITDATA    ] then result:=EncodeUnitData  (astream,data)
  else if fname=RawNames[nmSKILLS      ] then result:=EncodeSkills    (astream,data)
  else if fname=RawNames[nmAFFIXES     ] then result:=EncodeAffixes   (astream,data)
  else if fname=RawNames[nmMISSILES    ] then result:=EncodeMissiles  (astream,data)
  else if fname=RawNames[nmROOMPIECES  ] then result:=EncodeRoomPieces(astream,data)
  else if fname=RawNames[nmTRIGGERABLES] then result:=EncodeTriggers  (astream,data)
  else if fname=RawNames[nmUI          ] then result:=EncodeUI        (astream,data);
end;

function BuildRawFile(data:pointer; const fname:string):integer;
var
  ls:TMemoryStream;
  lfname:string;
begin
  lfname:=UpCase(ExtractFileNameOnly(fname));
  ls:=TMemoryStream.Create;
  try
    result:=BuildRawStream(data,ls,lfname);
    ls.SaveToFile(fname);
  finally
    ls.Free;
  end;
end;


end.
