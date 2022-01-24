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
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'AFFIX');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddInteger(lnode,'MinSpawnRange',memReadInteger(abuf));
      AddInteger(lnode,'MaxSpawnRange',memReadInteger(abuf));
      AddInteger(lnode,'Weight',memReadInteger(abuf));
      AddInteger(lnode,'DifficultiesAllowed',memReadInteger(abuf));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'UNITTYPES');
//        AddInteger(lnode1,'COUNT',lcnt1);
        for j:=0 to lcnt1-1 do
        begin
          AddString(lnode1,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
        end;
      end;

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NOTUNITTYPES');
//        AddInteger(lnode1,'COUNT',lcnt1);
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
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'MISSILE');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));

      lcnt1:=memReadByte(abuf);
      if lcnt1>0 then
      begin
        lnode1:=AddGroup(lnode,'NAMES');
//        AddInteger(lnode1,'COUNT',lcnt1);
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
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'LEVELSET');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
{
      pcw:=memReadShortString(abuf);
      AddString(lnode,'File',pcw);
      FreeMem(pcw);
}
    end;
    for i:=1 to lcnt do
    begin
      lcnt1:=memReadInteger(abuf);
      if lcnt1>0 then
      begin
        lnode:=AddGroup(GetChild(result,i),'GUIDS');
//        AddInteger(lnode,'COUNT',lcnt1);
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
  lpc:PWideChar;
  lnode:pointer;
  i,lcnt:integer;
begin
  lcnt:=memReadInteger(abuf);
  if lcnt>0 then
  begin
    result:=AddGroup(nil,'USERINTERFACES');
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'USERINTERFACE');

      AddString(lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));

      AddInteger(lnode,'Unknown1',memReadInteger(abuf));
      AddInteger(lnode,'Unknown2',memReadInteger(abuf));
      AddInteger(lnode,'Unknown3',memReadWord   (abuf));
      AddBool   (lnode,'Unknown4',memReadByte   (abuf)<>0);
      lpc:=memReadShortString(abuf);
      AddString(lnode,'Unknown5',lpc);
      FreeMem(lpc);
{
      pcw:=memReadShortString(abuf);
      AddString(lnode,'Name',pcw);
      FreeMem(pcw);
      pcw:=memReadShortString(abuf);
      AddString(lnode,'File',pcw);
      FreeMem(pcw);
}
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
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'TRIGGERABLE');

      AddString(lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString(lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
{
      pcw:=memReadShortString(abuf);
      AddString(lnode,'Name',pcw);
      FreeMem(pcw);
      pcw:=memReadShortString(abuf);
      AddString(lnode,'File',pcw);
      FreeMem(pcw);
}
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
//    AddInteger(result,'COUNT',lcnt);
    for i:=0 to lcnt-1 do
    begin
      lnode:=AddGroup(result,'SKILL');

      AddString   (lnode,'Name',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddString   (lnode,'File',memReadShortStringBuf(abuf,@pcw,MAXLEN));
      AddInteger64(lnode,'GUID',memReadInteger64(abuf));
{
      pcw:=memReadShortString(abuf);
      AddString(lnode,'Name',pcw);
      FreeMem(pcw);
      pcw:=memReadShortString(abuf);
      AddString(lnode,'File',pcw);
      FreeMem(pcw);
      AddInteger64(lnode,'GUID',memReadInteger64(abuf));
}
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
