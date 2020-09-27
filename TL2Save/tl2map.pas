unit TL2Map;

interface

uses
  Classes,
  rgglobal,
  tl2base,
  rgstream,
  tl2char,
  tl2common,
  tl2item;

type
  TTL2Map     = class;
  TTL2MapList = array of TTL2Map;

type
  TTL2Trigger     = array [0..135] of byte;
  TTL2TriggerList = array of TTL2Trigger;

type
  TTL2LayData = packed record
    id   : TRGID;       // example: Unit Trigger in MEDIA\LAYOUTS\ACT1\1X1_CLIFF_S0E1W1_LANDMARK_BANDITCAMP\1X1_CLIFF_S0E1W1_PB_LANDMARK_BANDITCAMP.LAYOUT
    value: TRGInteger;
    unkn : TRGID; //??
  end;
  TTL2LayDataList = array of TTL2LayData;

type
  TTL2Map = class(TL2BaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream); override;
    procedure SaveToStream  (AStream: TStream); override;

  private
    FName :string;
    FIsTown:Boolean;
    FMobInfos:TTL2CharArray;

    FTime,               // total time on location?
    FCurrentTime:Single; // current time on location?
    FFoW_X,
    FFoW_Y: integer;
    FFoW  : PByte;

    Unkn0:DWord;
    Unkn1:Byte;
    Unkn2:DWord;
    Unkn3:DWord;
    UnknF:TRGFloat;

    FUnknList  : TL2IdList;
    FLayoutList: TL2StringList;
    FTriggers  : TTL2TriggerList;
    FPropList  : TTL2ItemList;
    FQuestItems: TTL2ItemList;
    FLayData   : TTL2LayDataList;

    procedure ReadPropList   (AStream: TStream);
    procedure WritePropList  (AStream: TStream);
    procedure ReadQuestItems (AStream: TStream);
    procedure WriteQuestItems(AStream: TStream);

  public
    property Time       : Single read FTime;
    property CurrentTime: Single read FCurrentTime;

    property FoW_X : integer read FFoW_X;
    property FoW_Y : integer read FFoW_Y;
    property FoW   : PByte   read FFoW;
    property Name  : string  read FName;
    property Number: dword   read Unkn0;

    property MobInfos  : TTL2CharArray   read FMobInfos;
    property UnknList  : TL2IdList       read FUnknList;
    property LayoutList: TL2StringList   read FLayoutList;
    property Triggers  : TTL2TriggerList read FTriggers;
    property PropList  : TTL2ItemList    read FPropList;
    property QuestItems: TTL2ItemList    read FQuestItems;
    property LayData   : TTL2LayDataList read FLayData;
  end;

function  ReadMapList (AStream:TStream):TTL2MapList;
procedure WriteMapList(AStream:TStream; amaplist:TTL2MapList);


implementation

constructor TTL2Map.Create;
begin
  inherited;

  DataType:=dtMap;
end;

destructor TTL2Map.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTL2Map.InternalClear;
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
    FPropList[i].Free;
  SetLength(FPropList,0);

  for i:=0 to High(FQuestItems) do
    FQuestItems[i].Free;
  SetLength(FQuestItems,0);

  SetLength(FTriggers,0);

  SetLength(FLayoutList,0);
end;

procedure TTL2Map.Clear;
begin
  InternalClear;
    
  inherited;
end;

procedure TTL2Map.ReadPropList(AStream: TStream);
var
  lcnt1,lpos,lcnt,i:integer;
begin
  lcnt:=AStream.ReadDWord;
  SetLength(FPropList,lcnt);

  for i:=0 to lcnt-1 do
  begin
    lcnt1:=AStream.ReadDWord(); // size
    lpos:=AStream.Position;
    FPropList[i]:=TTL2Item.Create;
//!!    FPropList[i].IsProp:=true;
    try
      FPropList[i].LoadFromStream(AStream);
    except
      if IsConsole then writeln('prop exception ',i,' at ',HexStr(lpos,8));
      AStream.Position:=lpos+lcnt1;
    end;

    if FPropList[i].DataSize<>lcnt1 then
      if IsConsole then writeln('predefined size ',lcnt1,
         ' is not as real ',FPropList[i].DataSize,
         ' at ',HexStr(lpos,8));
  end;
end;

procedure TTL2Map.WritePropList(AStream: TStream);
var
  i:integer;
begin
  AStream.WriteDWord(Length(FPropList));
  for i:=0 to High(FPropList) do
  begin
    AStream.WriteDWord(FPropList[i].DataSize);
    FPropList[i].SaveToStream(AStream);
  end;
end;

procedure TTL2Map.ReadQuestItems(AStream: TStream);
var
  i,lcnt,lcnt1,lpos:integer;
begin
  lcnt:=AStream.ReadDWord;
  SetLength(FQuestItems,lcnt);

  for i:=0 to lcnt-1 do
  begin
    lcnt1:=AStream.ReadDWord(); // size
    lpos:=AStream.Position;
    FQuestItems[i]:=TTL2Item.Create;
//!!    FPropList[i].IsProp:=false; //!!!!!!!!!
    try
      FQuestItems[i].LoadFromStream(AStream);
    except
      if IsConsole then writeln('quest item exception ',i,' at ',HexStr(lpos,8));
      AStream.Position:=lpos+lcnt1;
    end;

    if FQuestItems[i].DataSize<>lcnt1 then
      if IsConsole then writeln('predefined size ',lcnt1,
         ' is not as real ',FQuestItems[i].DataSize,
         ' at ',HexStr(lpos,8));
  end;
end;

procedure TTL2Map.WriteQuestItems(AStream: TStream);
var
  i:integer;
begin
  AStream.WriteDWord(Length(FQuestItems));
  for i:=0 to High(FQuestItems) do
  begin
    AStream.WriteDWord(FQuestItems[i].DataSize);
    FQuestItems[i].SaveToStream(AStream);
  end;
end;

procedure TTL2Map.LoadFromStream(AStream: TStream);
var
  i,lcnt:integer;
begin
  DataOffset:=AStream.Position;
DbgLn('start map');

  //??
  Unkn0:=Check(AStream.ReadDword,'map 0_'+HexStr(AStream.Position,8),0); // 0, 2, 1 - for repeated

  FCurrentTime:=AStream.ReadFloat;
  FTime       :=AStream.ReadFloat;

  //??
  UnknF:=Check(AStream.ReadFloat,'map pre-name '+HexStr(AStream.Position,8),1.0);
  {
    0.001 - looks like NOT for towns
    but slaversden = 1
  }
  // 1.0 3A83126F for Zorro  0,00100000004749745

  FName:=AStream.ReadShortString;
DbgLn('map name: '+FName);

  FIsTown:=AStream.ReadByte<>0;
  //??
  Unkn1:=Check(AStream.ReadByte,'pre-matrix of '+UTF8Encode(FName),0);   // 0 (1 for Lesya)
  {  
    1 for Sawmill - quest boss?
  }

  //----- i guess, this is Fog of War setings (what else?)

  FFoW_X:=AStream.ReadDWord;
  FFoW_Y:=AStream.ReadDWord;
  FFoW  :=AStream.ReadBytes(FFoW_X*FFoW_Y*SizeOf(TRGFloat));

  //??
  Unkn2:=Check(AStream.ReadDWord,'pre-layouts_'+HexStr(AStream.Position,8),0); // 0

  //----- Layout data -----

  lcnt:=AStream.ReadDword;
  SetLength(FLayData,lcnt);
  if lcnt>0 then
    AStream.Read(FLayData[0],lcnt*SizeOf(TTL2LayData));

  //??
  FUnknList:=AStream.ReadIdList;

  //----- Units: Mobs and NPCs -----

  lcnt:=AStream.ReadDWord;
  SetLength(FMobInfos,lcnt);
  for i:=0 to lcnt-1 do
  begin
    FMobInfos[i]:=ReadCharData(AStream);
  end;

  //----- Props (Items) -----

  ReadPropList(AStream);

  //----- Quest items -----

  ReadQuestItems(AStream);

  //----- Triggers and other -----

  lcnt:=AStream.ReadDWord;
  SetLength(FTriggers,lcnt);
  if lcnt>0 then
    AStream.Read(FTriggers[0],lcnt*SizeOf(TTL2Trigger));
  
  //----- LAYOUT -----

  FLayoutList:=AStream.ReadShortStringList;

  //??
  Unkn3:=Check(AStream.ReadDWord,'map-end_'+HexStr(AStream.Position,8),0); // 0

DbgLn('end map'#13#10'---------');
  LoadBlock(AStream);
end;

procedure TTL2Map.SaveToStream(AStream: TStream);
var
  i:integer;
begin
  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;
  
  //??
  AStream.WriteDWord(Unkn0);

  AStream.WriteFloat(FCurrentTime);
  AStream.WriteFloat(FTime);

  //??
  AStream.WriteFloat(UnknF);

  AStream.WriteShortString(FName);

  AStream.WriteByte(ord(FIsTown));
  //??
  AStream.WriteByte(Unkn1);

  //----- i guess, this is Fog of War setings (what else?)

  AStream.WriteDWord(FFoW_X);
  AStream.WriteDWord(FFoW_Y);
  AStream.Write(FFoW^,FFoW_X*FFoW_Y*SizeOf(TRGFloat));

  //??
  AStream.WriteDWord(Unkn2);

  //----- Layout data -----

  AStream.WriteDword(Length(FLayData));
  if Length(FLayData)>0 then
    AStream.Write(FLayData[0],Length(FLayData)*SizeOf(TTL2LayData));

  //??
  AStream.WriteIdList(FUnknList);

  //----- units: Mobs and similar? -----

  AStream.WriteDWord(Length(FMobInfos));
  for i:=0 to High(FMobInfos) do
    FMobInfos[i].SaveToStream(AStream);

  //----- Props (Items) -----

  WritePropList(AStream);

  //----- Quest items -----

  WriteQuestItems(AStream);

  //----- Triggers and other -----

  AStream.WriteDWord(Length(FTriggers));
  if Length(FTriggers)>0 then
    AStream.Write(FTriggers[0],Length(FTriggers)*SizeOf(TTL2Trigger));
  
  //----- LAYOUT -----

  AStream.WriteShortStringList(FLayoutList);

  //??
  AStream.WriteDWord(Unkn3);

  LoadBlock(AStream);
end;

function ReadMapList(AStream:TStream):TTL2MapList;
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

procedure WriteMapList(AStream:TStream; amaplist:TTL2MapList);
var
  i:integer;
begin
  AStream.WriteDWord(Length(amaplist));
  for i:=0 to High(amaplist) do
    amaplist[i].SaveToStream(AStream);
end;

end.
