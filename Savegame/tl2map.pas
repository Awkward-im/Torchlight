unit TL2Map;

interface

uses
  sysutils,
  classes,
  tl2types,
  tl2stream,
  tl2char,
  tl2common;

type
  TTL2Map = class;
  TTL2MapList = array of TTL2Map;

type
  TTL2Trigger = array [0..135] of byte;
  TTL2TriggerList = array of TTL2Trigger;
type
  TTL2Prop = array of byte;
  TTL2PropList = array of TTL2Prop;
type
  TTL2LayData = packed record
    id   : TL2ID;
    value: TL2Integer;
    unkn : TL2ID; //??
  end;
  TTL2LayDataList = array of TTL2LayData;

type
  TTL2Map = class
  private
    FName :string;
    FMobInfos:array of TTL2Character;

    FTime,               // total time on location?
    FCurrentTime:Single; // current time on location?
    FFoW_X,
    FFoW_Y: integer;
    FFoW  : PByte;

    FUnknList  : TL2IdList;
    FLayoutList: TL2StringList;
    FTriggers  : TTL2TriggerList;
    FPropList  : TTL2PropList;
    FLayData   : TTL2LayDataList;

    FUnknown1  : array of array of byte;

    procedure ReadProp    (AStream: TTL2Stream; var aProp:TTL2Prop);
    procedure ReadPropList(AStream: TTL2Stream);
  
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

  end;

function  ReadMapList (AStream:TTL2Stream):TTL2MapList;
procedure WriteMapList(AStream:TTL2Stream; amaplist:TTL2MapList);


implementation

constructor TTL2Map.Create;
begin
  inherited;

end;

destructor TTL2Map.Destroy;
var
  i:integer;
begin
  FreeMem(FFoW);

  SetLength(FLayData,0);
  SetLength(FUnknList,0);

  for i:=0 to High(FMobInfos) do
    FMobInfos[i].Free;
  SetLength(FMobInfos,0);

  for i:=0 to High(FPropList) do
    SetLength(FPropList[i],0);
  SetLength(FPropList,0);

  SetLength(FUnknown1,0);

  SetLength(FTriggers,0);

{-- strings
  for i:=0 to High(FLayoutList) do
    SetLength(FLayoutList[i],0);
}
  SetLength(FLayoutList,0);
  
  inherited;
end;

procedure TTL2Map.ReadProp(AStream: TTL2Stream; var aProp:TTL2Prop);
var
  lcnt:integer;
begin
  lcnt:=AStream.ReadDWord;
  SetLength(aProp,lcnt);
  if lcnt>0 then
    AStream.Read(aProp[0],lcnt);
  {
    AStream.ReadByte;
    AStream.ReadQWord; // ID
    FName:=AStream.ReadShortString;
    AStream.ReadDWord; // 0
    AStream.ReadQWord; // 2E3A2D8F.DDC8B8CA
    AStream.ReadQWord; // 2E3A2D8FDDC8B8CA
    AStream.ReadQWord; // 2EE026D98D5FC8C7
    AStream.ReadDWord; // 0
    AStream.ReadByte;  // 0
    AStream.ReadQWord; // FF
    ....

    // 00 01 00 01 01 00 00
    AStream.ReadDWord; // 43062E21  134.18
    AStream.ReadDWord; // 0
    AStream.ReadDWord; // 43A0492F
    .....
  }
end;

procedure TTL2Map.ReadPropList(AStream: TTL2Stream);
var
  lcnt,i:integer;
begin
  lcnt:=AStream.ReadDWord;
  SetLength(FPropList,lcnt);
  for i:=0 to lcnt-1 do
  begin
    ReadProp(AStream, FPropList[i]);
  end;
end;

procedure TTL2Map.LoadFromStream(AStream: TTL2Stream);
var
  lcnt,lcnt1:integer;
  i:integer;
begin

  Check(AStream.ReadDword,'map 0',0); // 0, 2, 1 - for repeated

  FCurrentTime:=AStream.ReadFloat;
  FTime       :=AStream.ReadFloat;

  AStream.ReadFloat; // 1.0 3A83126F for Zorro  0,00100000004749745

  FName:=AStream.ReadShortString;

  Check(AStream.ReadWord,'pre-matrix of '+UTF8Encode(FName),0);   // 0 (1 for Lesya)

  //----- i guess, this is Fog of War setings (what else?)

  FFoW_X:=AStream.ReadDword;
  FFoW_Y:=AStream.ReadDword;
  FFoW  :=AStream.ReadBytes(FFoW_X*FFoW_Y*SizeOf(Single));

  Check(AStream.ReadDWord,'pre-layouts',0); // 0

  //----- Layout data -----

  lcnt:=AStream.ReadDword;
  SetLength(FLayData,lcnt);
  if lcnt>0 then
    AStream.Read(FLayData[0],lcnt*SizeOf(TTL2LayData));

  FUnknList:=AStream.ReadIdList;

  //----- units: Mobs and similar? -----

  lcnt:=AStream.ReadDWord;  // mob count?
  SetLength(FMobInfos,lcnt);
  for i:=0 to lcnt-1 do
    FMobInfos[i]:=ReadCharData(AStream,ptLite,'res\'+FName+'_mobinfo'+HexStr(i,2));

  //----- Props (Items) -----

  ReadPropList(AStream);

  //----- !! -----

  lcnt:=AStream.ReadDWord;
  SetLength(FUnknown1,lcnt);
  for i:=0 to lcnt-1 do
  begin
    lcnt1:=AStream.ReadDWord;
    SetLength   (FUnknown1[i]   ,lcnt1);
    AStream.Read(FUnknown1[i][0],lcnt1);
  end;

  //----- Triggers and other -----

  lcnt:=AStream.ReadDWord;
  SetLength(FTriggers,lcnt);
  if lcnt>0 then
    AStream.Read(FTriggers[0],lcnt*SizeOf(TTL2Trigger));
  
  //----- LAYOUT -----

  FLayoutList:=AStream.ReadShortStringList;

  Check(AStream.ReadDWord,'map-end',0); // 0
end;

procedure TTL2Map.SaveToStream(AStream: TTL2Stream);
begin
end;

function ReadMapList(AStream:TTL2Stream):TTL2MapList;
var
  i,lcnt:integer;
begin
  result:=nil;
  lcnt:=AStream.ReadDWord;
  if lcnt>0 then
  begin
    SetLength(result,lcnt);
    for i:=0 to lcnt-1 do
    begin
      result[i]:=TTL2Map.Create;
      result[i].LoadFromStream(AStream);
    end;
  end;
end;

procedure WriteMapList(AStream:TTL2Stream; amaplist:TTL2MapList);
var
  i:integer;
begin
  for i:=0 to High(amaplist) do
    amaplist[i].SaveToStream(AStream);
end;

end.
